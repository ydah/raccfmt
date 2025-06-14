# frozen_string_literal: true

module Raccfmt
  module Rules
    class IndentRule < BaseRule
      def apply(ast)
        indent_size = @rule_config["size"] || 2
        indent_char = @rule_config["style"] == "tabs" ? "\t" : " "
        @indent_unit = indent_char * indent_size

        process_node(ast, 0)
      end

      private

      def process_node(node, level)
        case node.type
        when :root
          node.children.each { |child| process_node(child, level) }
        when :rule
          process_rule_node(node, level)
        end

        node
      end

      def process_rule_node(rule, level)
        formatted_productions = []

        rule.productions.each_with_index do |production, index|
          if production.include?("{") && production.include?("}")
            if index == 0
              formatted_productions << production.strip
            else
              if production.strip.start_with?("|")
                formatted_productions << "#{@indent_unit}#{production.strip}"
              else
                formatted_productions << "#{@indent_unit}| #{production.strip}"
              end
            end
          else
            stripped = production.strip
            if index == 0
              formatted_productions << stripped
            else
              if stripped.start_with?("|")
                formatted_productions << "#{@indent_unit}#{stripped}"
              else
                formatted_productions << "#{@indent_unit}| #{stripped}"
              end
            end
          end
        end

        rule.instance_variable_set(:@productions, formatted_productions)

        rule.actions.each do |action|
          format_multiline_action(action, level)
        end

        rule.instance_variable_set(:@semicolon_indent, @indent_unit)
      end

      def format_multiline_action(action, level)
        lines = action.value.lines
        return if lines.empty?

        formatted_lines = []

        lines.each_with_index do |line, idx|
          stripped = line.strip

          if stripped.empty?
            formatted_lines << "\n"
          elsif stripped.match(/^\{/)
            formatted_lines << "#{@indent_unit}{\n"
          elsif stripped.match(/^\}/)
            formatted_lines << "#{@indent_unit}}\n"
          else
            if idx == 0 && line.include?("{")
              content = line.sub(/.*\{/, "").strip
              formatted_lines << "#{@indent_unit}{\n"
              formatted_lines << "#{@indent_unit * 2}#{content}\n" unless content.empty?
            elsif idx == lines.length - 1 && line.include?("}")
              content = line.sub(/\}.*/, "").strip
              formatted_lines << "#{@indent_unit * 2}#{content}\n" unless content.empty?
              formatted_lines << "#{@indent_unit}}\n"
            else
              formatted_lines << "#{@indent_unit * 2}#{stripped}\n"
            end
          end
        end

        action.instance_variable_set(:@value, formatted_lines.join)
      end
    end
  end
end
