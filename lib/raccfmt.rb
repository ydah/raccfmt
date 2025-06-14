# frozen_string_literal: true

require_relative "raccfmt/version"
require_relative "raccfmt/cli"
require_relative "raccfmt/config"
require_relative "raccfmt/formatter"
require_relative "raccfmt/parser"

module Raccfmt
  class Error < StandardError; end
  class ParseError < Error; end
  class ConfigError < Error; end
end
