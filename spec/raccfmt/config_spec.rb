# frozen_string_literal: true

require "tempfile"

RSpec.describe Raccfmt::Config do
  describe ".new" do
    it "uses default configuration when no config provided" do
      config = described_class.new
      expect(config.rule_enabled?("indent")).to be true
      expect(config.rule_config("indent")["size"]).to eq 2
    end

    it "merges provided configuration with defaults" do
      custom_config = {
        "rules" => {
          "indent" => {
            "size" => 4
          }
        }
      }
      config = described_class.new(custom_config)

      expect(config.rule_config("indent")["size"]).to eq 4
      expect(config.rule_config("indent")["style"]).to eq "spaces" # default retained
    end
  end

  describe ".load" do
    context "when config file exists" do
      let(:config_file) do
        Tempfile.new(["raccfmt", ".yml"]).tap do |f|
          f.write(<<~YAML)
            rules:
              indent:
                enabled: false
                size: 8
              brace_newline:
                style: new_line
          YAML
          f.rewind
        end
      end

      after { config_file.unlink }

      it "loads configuration from file" do
        config = described_class.load(config_file.path)

        expect(config.rule_enabled?("indent")).to be false
        expect(config.rule_config("indent")["size"]).to eq 8
        expect(config.rule_config("brace_newline")["style"]).to eq "new_line"
      end
    end

    context "when config file doesn't exist" do
      it "returns default configuration" do
        config = described_class.load("non_existent.yml")
        expect(config.rule_enabled?("indent")).to be true
      end
    end

    context "when config file has invalid YAML" do
      let(:invalid_config_file) do
        Tempfile.new(["invalid", ".yml"]).tap do |f|
          f.write("invalid: yaml: content:")
          f.rewind
        end
      end

      after { invalid_config_file.unlink }

      it "raises ConfigError" do
        expect {
          described_class.load(invalid_config_file.path)
        }.to raise_error(Raccfmt::ConfigError, /Invalid YAML/)
      end
    end
  end

  describe ".generate_default" do
    let(:output_path) { Tempfile.new(["default", ".yml"]).path }

    after { File.unlink(output_path) if File.exist?(output_path) }

    it "generates default configuration file" do
      described_class.generate_default(output_path)

      expect(File.exist?(output_path)).to be true

      loaded_config = Psych.safe_load_file(output_path)
      expect(loaded_config["rules"]["indent"]["enabled"]).to be true
      expect(loaded_config["rules"]["indent"]["size"]).to eq 2
    end
  end

  describe "#rule_enabled?" do
    let(:config) { described_class.new(config_hash) }

    context "when rule is explicitly enabled" do
      let(:config_hash) { { "rules" => { "indent" => { "enabled" => true } } } }

      it "returns true" do
        expect(config.rule_enabled?("indent")).to be true
      end
    end

    context "when rule is explicitly disabled" do
      let(:config_hash) { { "rules" => { "indent" => { "enabled" => false } } } }

      it "returns false" do
        expect(config.rule_enabled?("indent")).to be false
      end
    end

    context "when rule doesn't exist in config" do
      let(:config_hash) { { "rules" => {} } }

      it "returns false" do
        expect(config.rule_enabled?("non_existent")).to be false
      end
    end
  end
end
