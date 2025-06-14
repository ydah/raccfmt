# frozen_string_literal: true

module Raccfmt
  module AST
    class RuleNode < Node
      attr_reader :name, :productions, :actions

      def initialize(name)
        super(:rule, name)
        @name = name
        @productions = []
        @actions = []
        @colon_spacing = true
        @name_padding = 0
        @semicolon_indent = "  "
        @production_indent = "  " # Indentation for productions
      end

      def add_production(production)
        @productions << production
      end

      def add_action(action)
        @actions << action
      end

      def to_s
        padded_name = @name + (" " * @name_padding)
        colon = @colon_spacing ? " : " : ":"

        result = "#{padded_name}#{colon}"

        @productions.each_with_index do |prod, index|
          if index == 0
            # First production
            result += "\n#{@production_indent}#{prod.strip}"
          else
            # Subsequent productions
            if prod.strip.start_with?("|")
              result += "\n#{prod}"
            else
              result += "\n#{@production_indent}| #{prod.strip}"
            end
          end
        end

        # Multiline actions
        @actions.each do |action|
          result += "\n" + action.to_s.chomp
        end

        # Semicolon at the end
        result += "\n#{@semicolon_indent};"
        result + "\n"
      end
    end
  end
end
