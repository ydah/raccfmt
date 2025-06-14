# frozen_string_literal: true

require_relative "rules/base_rule"
require_relative "rules/indent_rule"
require_relative "rules/brace_newline_rule"
require_relative "rules/spacing_rule"
require_relative "rules/alignment_rule"
require_relative "rules/empty_line_rule"

module Raccfmt
  class Formatter
    def initialize(config)
      @config = config
      @rules = load_rules
    end

    def format(content)
      ast = Parser.new.parse(content)

      @rules.each do |rule|
        ast = rule.apply(ast)
      end

      ast.to_s
    end

    private

    def load_rules
      rules = []

      rules << Rules::IndentRule.new(@config) if @config.rule_enabled?("indent")
      rules << Rules::BraceNewlineRule.new(@config) if @config.rule_enabled?("brace_newline")
      rules << Rules::SpacingRule.new(@config) if @config.rule_enabled?("spacing")
      rules << Rules::AlignmentRule.new(@config) if @config.rule_enabled?("alignment")
      rules << Rules::EmptyLineRule.new(@config) if @config.rule_enabled?("empty_line")

      rules
    end
  end
end
