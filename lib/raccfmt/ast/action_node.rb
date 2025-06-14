# frozen_string_literal: true

module Raccfmt
  module AST
    class ActionNode < Node
      def initialize(content)
        super(:action, content)
      end

      def to_s
        @value
      end
    end
  end
end
