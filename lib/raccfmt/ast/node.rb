# frozen_string_literal: true

module Raccfmt
  module AST
    class Node
      attr_reader :type, :value, :children

      def initialize(type, value = nil)
        @type = type
        @value = value
        @children = []
      end

      def add_child(node)
        @children << node
      end

      def to_s
        case @type
        when :root
          @children.map(&:to_s).join
        when :comment
          @value
        when :empty_line
          @value
        else
          @value.to_s
        end
      end
    end
  end
end
