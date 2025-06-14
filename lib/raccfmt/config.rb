# frozen_string_literal: true

require "psych"

module Raccfmt
  class Config
    DEFAULT_CONFIG = {
      "rules" => {
        "indent" => {
          "enabled" => true,
          "size" => 2,
          "style" => "spaces" # or "tabs"
        },
        "brace_newline" => {
          "enabled" => true,
          "style" => "same_line", # or "new_line"
          "space_before" => true
        },
        "spacing" => {
          "enabled" => true,
          "around_colon" => true,
          "around_pipe" => true,
          "around_equals" => true
        },
        "alignment" => {
          "enabled" => true,
          "align_actions" => true,
          "align_rules" => true
        },
        "empty_line" => {
          "enabled" => true,
          "between_rules" => true,
          "after_header" => true,
          "before_footer" => true
        }
      }
    }.freeze

    attr_reader :rules

    def initialize(config_hash = {})
      @rules = deep_merge(DEFAULT_CONFIG["rules"], config_hash["rules"] || {})
    end

    def self.load(path = "raccfmt.yml")
      return new unless File.exist?(path)

      config_hash = Psych.safe_load_file(path) || {}
      new(config_hash)
    rescue Psych::SyntaxError => e
      raise ConfigError, "Invalid YAML in config file: #{e.message}"
    end

    def self.generate_default(path)
      File.write(path, Psych.dump(DEFAULT_CONFIG))
    end

    def rule_enabled?(rule_name)
      @rules.dig(rule_name, "enabled") || false
    end

    def rule_config(rule_name)
      @rules[rule_name] || {}
    end

    private

    def deep_merge(base, override)
      base.merge(override) do |_key, base_val, override_val|
        if base_val.is_a?(Hash) && override_val.is_a?(Hash)
          deep_merge(base_val, override_val)
        else
          override_val
        end
      end
    end
  end
end
