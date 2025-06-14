# frozen_string_literal: true

module Raccfmt
  module Rules
    class SpacingRule < BaseRule
      def apply(ast)
        process_node(ast)
      end

      private

      def process_node(node)
        case node.type
        when :root
          node.children.each { |child| process_node(child) }
        when :rule
          process_rule(node)
        end

        node
      end

      def process_rule(rule)
        # Process rule name and colon spacing
        if @rule_config["around_colon"]
          # This will be handled in the rule's to_s method
          rule.instance_variable_set(:@colon_spacing, true)
        else
          rule.instance_variable_set(:@colon_spacing, false)
        end

        # Process productions
        rule.productions.map! do |production|
          processed = production

          # Handle pipe spacing
          if production.strip.start_with?("|")
            if @rule_config["around_pipe"]
              processed = production.sub(/^\s*\|\s*/, " | ")
            else
              processed = production.sub(/^\s*\|\s*/, "|")
            end
          end

          # Handle equals spacing in inline actions
          if processed.include?("{") && processed.include?("}")
            processed = process_inline_action_spacing(processed)
          end

          processed
        end

        # Process actions
        rule.actions.each do |action|
          process_action_spacing(action)
        end
      end

      def process_inline_action_spacing(production)
        return production unless @rule_config["around_equals"]

        # Extract action part
        if production =~ /^(.*?)\s*\{(.*?)\}\s*$/
          prefix = $1
          action_content = $2

          # Add spacing around equals
          action_content = add_equals_spacing(action_content)

          "#{prefix} { #{action_content} }"
        else
          production
        end
      end

      def process_action_spacing(action)
        return unless @rule_config["around_equals"]

        lines = action.value.lines.map do |line|
          if line.strip.empty? || line.strip == "{" || line.strip == "}"
            line
          else
            # Preserve indentation
            indent = line[/^\s*/]
            content = line.strip

            # Add spacing around equals
            content = add_equals_spacing(content)

            "#{indent}#{content}\n"
          end
        end

        action.instance_variable_set(:@value, lines.join)
      end

      def add_equals_spacing(content)
        # Handle various assignment operators
        content = content.gsub(/(\w+)\s*=\s*/, '\1 = ')
        content = content.gsub(/(\])\s*=\s*/, '\1 = ')
        content = content.gsub(/(\))\s*=\s*/, '\1 = ')

        # Handle compound assignments
        content = content.gsub(/(\w+)\s*\+=\s*/, '\1 += ')
        content = content.gsub(/(\w+)\s*-=\s*/, '\1 -= ')
        content = content.gsub(/(\w+)\s*\*=\s*/, '\1 *= ')
        content = content.gsub(/(\w+)\s*\/=\s*/, '\1 /= ')
        content = content.gsub(/(\w+)\s*\|\|=\s*/, '\1 ||= ')
        content = content.gsub(/(\w+)\s*&&=\s*/, '\1 &&= ')

        # Handle special cases like array append
        content = content.gsub(/<<\s*/, ' << ')

        # Clean up multiple spaces
        content.gsub(/\s+/, ' ')
      end
    end
  end
end
