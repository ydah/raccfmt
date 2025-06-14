# frozen_string_literal: true

require_relative "ast/node"
require_relative "ast/rule_node"
require_relative "ast/action_node"

module Raccfmt
  class Parser
    def parse(content)
      lines = content.lines
      ast = AST::Node.new(:root)
      current_rule = nil
      in_action = false
      action_lines = []
      brace_count = 0

      lines.each_with_index do |line, index|
        stripped = line.strip

        # Skip comments and empty lines for now
        if stripped.empty? || stripped.start_with?("#")
          ast.add_child(AST::Node.new(:comment, line))
          next
        end

        # Detect rule start
        if !in_action && line =~ /^\s*(\w+)\s*:/
          current_rule = AST::RuleNode.new($1)
          ast.add_child(current_rule)

          # Parse the rest of the line
          rest = line.sub(/^\s*\w+\s*:/, "").strip
          if rest && !rest.empty?
            # Check if it has inline action
            if rest.include?("{") && rest.include?("}")
              current_rule.add_production(rest)
            elsif rest.include?("{")
              # Start of multi-line action
              in_action = true
              brace_count = rest.count("{") - rest.count("}")
              action_lines = [rest]
            else
              current_rule.add_production(rest)
            end
          end
        elsif current_rule
          # Check for action block
          if !in_action && line =~ /^\s*\{/
            in_action = true
            brace_count = line.count("{") - line.count("}")
            action_lines = [line]
          elsif in_action
            action_lines << line
            brace_count += line.count("{") - line.count("}")
            if brace_count <= 0
              in_action = false
              current_rule.add_action(AST::ActionNode.new(action_lines.join))
              action_lines = []
              brace_count = 0
            end
          elsif line =~ /^\s*\|/
            # Alternative production
            current_rule.add_production(line.strip)
          elsif line =~ /^\s*;/
            # End of rule
            current_rule = nil
          else
            # Check if line contains inline action
            if line.include?("{") && line.include?("}")
              current_rule.add_production(line.strip)
            elsif line.include?("{")
              # Start of multi-line action in production
              in_action = true
              brace_count = line.count("{") - line.count("}")
              action_lines = [line]
            else
              # Continuation of production
              current_rule.add_production(line.strip) if current_rule
            end
          end
        else
          # Other content (headers, footers, etc.)
          ast.add_child(AST::Node.new(:other, line))
        end
      end

      ast
    end
  end
end
