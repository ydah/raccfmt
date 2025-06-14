# frozen_string_literal: true

module Raccfmt
  module Rules
    class EmptyLineRule < BaseRule
      def apply(ast)
        return ast unless ast.type == :root

        new_children = []
        previous_node = nil
        in_header = true
        found_rule_section = false

        ast.children.each_with_index do |node, index|
          # Detect transitions between sections
          if node.is_a?(AST::RuleNode)
            found_rule_section = true
            in_header = false
          elsif found_rule_section && node.type == :comment && node.value.strip.start_with?("----")
            # Found footer section (---- header, ---- inner, etc.)
            if @rule_config["before_footer"] && previous_node && !previous_node.type == :empty_line
              new_children << create_empty_line_node
            end
          end

          # Add empty line after header section
          if @rule_config["after_header"] && in_header && node.is_a?(AST::RuleNode)
            if previous_node && previous_node.type != :empty_line
              new_children << create_empty_line_node
            end
          end

          # Add the current node
          new_children << node

          # Add empty line between rules
          if @rule_config["between_rules"] && node.is_a?(AST::RuleNode)
            next_node = ast.children[index + 1]
            if next_node && next_node.is_a?(AST::RuleNode)
              # Check if there's already an empty line
              unless next_node.type == :comment && next_node.value.strip.empty?
                new_children << create_empty_line_node
              end
            end
          end

          previous_node = node
        end

        ast.instance_variable_set(:@children, new_children)
        ast
      end

      private

      def create_empty_line_node
        AST::Node.new(:empty_line, "\n")
      end
    end
  end
end
