# frozen_string_literal: true

require "tempfile"

RSpec.describe Raccfmt::CLI do
  let(:cli) { described_class.new }
  let(:test_file) do
    Tempfile.new(["test", ".y"]).tap do |f|
      f.write(<<~RACC)
        program:stmt_list{result=val[0]}
      RACC
      f.rewind
    end
  end

  after { test_file.unlink }

  describe "#format" do
    context "without options" do
      it "outputs formatted content to stdout" do
        expect {
          cli.format(test_file.path)
        }.to output(/program :/).to_stdout
      end
    end

    context "with --write option" do
      it "writes formatted content back to file" do
        expect {
          cli.invoke(:format, [test_file.path], write: true)
        }.to output(/Formatted/).to_stdout

        content = File.read(test_file.path)
        expect(content).to include "program :"
      end
    end

    context "with --check option" do
      context "when file needs formatting" do
        it "exits with status 1" do
          expect {
            cli.invoke(:format, [test_file.path], check: true)
          }.to output(/needs formatting/).to_stdout.and raise_error(SystemExit) { |e|
            expect(e.status).to eq 1
          }
        end
      end

      context "when file is already formatted" do
        before do
          # Format the file first
          formatter = Raccfmt::Formatter.new(Raccfmt::Config.new)
          formatted = formatter.format(File.read(test_file.path))
          File.write(test_file.path, formatted)
        end

        it "exits with status 0" do
          expect {
            cli.invoke(:format, [test_file.path], check: true)
          }.to output(/already formatted/).to_stdout.and raise_error(SystemExit) { |e|
            expect(e.status).to eq 0
          }
        end
      end
    end

    context "with custom config file" do
      let(:config_file) do
        Tempfile.new(["config", ".yml"]).tap do |f|
          f.write(<<~YAML)
            rules:
              indent:
                size: 4
          YAML
          f.rewind
        end
      end

      after { config_file.unlink }

      it "uses specified config" do
        expect {
          cli.invoke(:format, [test_file.path], config: config_file.path)
        }.to output(/    stmt_list/).to_stdout  # 4 spaces instead of 2
      end
    end

    context "with non-existent file" do
      it "outputs error and exits with status 1" do
        expect {
          cli.format("non_existent.y")
        }.to output(/Error:/).to_stderr.and raise_error(SystemExit) { |e|
          expect(e.status).to eq 1
        }
      end
    end
  end

  describe "#init" do
    let(:config_path) { ".raccfmt.yml" }

    after { File.unlink(config_path) if File.exist?(config_path) }

    context "when config doesn't exist" do
      it "generates default config file" do
        expect {
          cli.init
        }.to output(/Generated/).to_stdout

        expect(File.exist?(config_path)).to be true
        config = Psych.safe_load_file(config_path)
        expect(config["rules"]["indent"]["enabled"]).to be true
      end
    end

    context "when config already exists" do
      before { File.write(config_path, "existing: config") }

      it "doesn't overwrite and exits with status 1" do
        expect {
          cli.init
        }.to output(/already exists/).to_stdout.and raise_error(SystemExit) { |e|
          expect(e.status).to eq 1
        }

        expect(File.read(config_path)).to eq "existing: config"
      end
    end
  end

  describe "#version" do
    it "outputs version number" do
      expect {
        cli.version
      }.to output(/raccfmt \d+\.\d+\.\d+/).to_stdout
    end
  end
end
