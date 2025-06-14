# frozen_string_literal: true

module Raccfmt
  module Rules
    class BaseRule
      def initialize(config)
        @config = config
        @rule_config = config.rule_config(rule_name)
      end

      def apply(ast)
        raise NotImplementedError, "Subclasses must implement #apply"
      end

      private

      def rule_name
        self.class.name.split("::").last.gsub(/Rule$/, "").gsub(/([A-Z])/, '_\1').downcase[1..]
      end
    end
  end
end
