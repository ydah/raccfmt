# frozen_string_literal: true

module Raccfmt
  module Rules
    class BraceNewlineRule < BaseRule
      def apply(ast)
        style = @rule_config["style"] || "same_line"
        space_before = @rule_config["space_before"] != false

        process_node(ast, style, space_before)
      end

      private

      def process_node(node, style, space_before)
        case node.type
        when :root
          node.children.each { |child| process_node(child, style, space_before) }
        when :rule
          node.actions.each do |action|
            format_action_braces(action, style, space_before)
          end
        end

        node
      end

      def format_action_braces(action, style, space_before)
        content = action.value

        case style
        when "same_line"
          # Ensure opening brace is on the same line as the production
          content = content.gsub(/\n\s*\{/, space_before ? " {" : "{")
        when "new_line"
          # Ensure opening brace is on a new line
          unless content =~ /^\s*\{/
            content = content.gsub(/\s*\{/, "\n  {")
          end
        end

        action.instance_variable_set(:@value, content)
      end
    end
  end
end
