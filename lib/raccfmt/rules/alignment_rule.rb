# frozen_string_literal: true

module Raccfmt
  module Rules
    class AlignmentRule < BaseRule
      def apply(ast)
        return ast unless ast.type == :root

        if @rule_config["align_rules"]
          align_rules(ast)
        end

        if @rule_config["align_actions"]
          align_actions(ast)
        end

        ast
      end

      private

      def align_rules(ast)
        rules = ast.children.select { |n| n.is_a?(AST::RuleNode) }
        return if rules.empty?

        # Group consecutive rules
        rule_groups = []
        current_group = []

        ast.children.each do |node|
          if node.is_a?(AST::RuleNode)
            current_group << node
          else
            if current_group.any?
              rule_groups << current_group
              current_group = []
            end
          end
        end
        rule_groups << current_group if current_group.any?

        # Align each group
        rule_groups.each do |group|
          align_rule_group(group)
        end
      end

      def align_rule_group(rules)
        # Find the maximum rule name length
        max_name_length = rules.map { |r| r.name.length }.max

        # Align colons
        rules.each do |rule|
          padding = max_name_length - rule.name.length
          rule.instance_variable_set(:@name_padding, padding)
        end

        # Align productions with pipes
        align_rule_productions(rules)
      end

      def align_rule_productions(rules)
        rules.each do |rule|
          next if rule.productions.empty?

          # Find all productions with pipes
          pipe_productions = rule.productions.select { |p| p.strip.start_with?("|") }
          next if pipe_productions.empty?

          # Calculate alignment for pipe productions
          first_prod = rule.productions.first
          if first_prod && !first_prod.strip.start_with?("|")
            # Align pipes with the start of the first production
            base_indent = first_prod.index(/\S/) || 0

            rule.productions.map!.with_index do |prod, index|
              if index > 0 && prod.strip.start_with?("|")
                stripped = prod.strip
                " " * base_indent + stripped
              else
                prod
              end
            end
          end
        end
      end

      def align_actions(ast)
        ast.children.each do |node|
          next unless node.is_a?(AST::RuleNode)

          align_rule_actions(node)
        end
      end

      def align_rule_actions(rule)
        # Align actions that are on the same line as productions
        rule.productions.map! do |production|
          if production.include?("{") && production.include?("}")
            align_inline_action(production)
          else
            production
          end
        end

        # Align multi-line actions
        rule.actions.each do |action|
          align_multiline_action(action)
        end
      end

      def align_inline_action(production)
        # Extract parts
        if production =~ /^(.*?)\s*\{(.*?)\}\s*$/
          rule_part = $1
          action_part = $2

          # Ensure consistent spacing
          "#{rule_part.rstrip} { #{action_part.strip} }"
        else
          production
        end
      end

      def align_multiline_action(action)
        lines = action.value.lines
        return if lines.empty?

        # Find the base indentation from the opening brace
        opening_brace_line = lines.find { |l| l.include?("{") }
        return unless opening_brace_line

        base_indent = opening_brace_line[/^\s*/].length

        # Align action content
        aligned_lines = lines.map.with_index do |line, index|
          stripped = line.strip

          if stripped == "{"
            " " * base_indent + "{\n"
          elsif stripped == "}"
            " " * base_indent + "}\n"
          elsif stripped.empty?
            "\n"
          else
            # Action content should be indented relative to braces
            " " * (base_indent + 2) + stripped + "\n"
          end
        end

        action.instance_variable_set(:@value, aligned_lines.join)
      end
    end
  end
end
