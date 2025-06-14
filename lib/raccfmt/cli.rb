# frozen_string_literal: true

require "thor"

module Raccfmt
  class CLI < Thor
    desc "format FILE", "Format a Racc grammar file"
    option :config, type: :string, default: ".raccfmt.yml", desc: "Path to config file"
    option :write, type: :boolean, default: false, desc: "Write formatted output to file"
    option :check, type: :boolean, default: false, desc: "Check if file is formatted"
    def format(file)
      config = Config.load(options[:config])
      formatter = Formatter.new(config)

      content = File.read(file)
      formatted = formatter.format(content)

      if options[:check]
        if content == formatted
          puts "#{file} is already formatted"
          exit 0
        else
          puts "#{file} needs formatting"
          exit 1
        end
      elsif options[:write]
        File.write(file, formatted)
        puts "Formatted #{file}"
      else
        puts formatted
      end
    rescue Error => e
      error_message = "Error: #{e.message}"
      $stderr.puts error_message
      exit 1
    end

    desc "init", "Generate a default .raccfmt.yml config file"
    def init
      config_path = ".raccfmt.yml"
      if File.exist?(config_path)
        puts "Config file already exists: #{config_path}"
        exit 1
      end

      Config.generate_default(config_path)
      puts "Generated #{config_path}"
    end

    desc "version", "Show version"
    def version
      puts "raccfmt #{VERSION}"
    end
  end
end
