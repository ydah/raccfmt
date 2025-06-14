# frozen_string_literal: true

require "open3"
require "tempfile"

RSpec.describe "CLI Integration" do
  let(:executable) { File.expand_path("../../exe/raccfmt", __dir__) }

  def run_command(args)
    Open3.capture3("ruby", executable, *args)
  end

  context "format command" do
    let(:test_file) do
      Tempfile.new(["test", ".y"]).tap do |f|
        f.write(<<~RACC)
          program:stmt_list{result=val[0]}
          stmt:expr';'{result=val[0]}
        RACC
        f.rewind
      end
    end

    after { test_file.unlink }

    it "formats file and outputs to stdout" do
      stdout, stderr, status = run_command(["format", test_file.path])

      expect(status.success?).to be true
      expect(stderr).to be_empty
      expect(stdout).to include "program :"
      expect(stdout).to include "stmt :"
      expect(stdout).to include "result = val[0]"
    end

    it "writes formatted content with --write flag" do
      stdout, stderr, status = run_command(["format", test_file.path, "--write"])

      expect(status.success?).to be true
      expect(stdout).to include "Formatted #{test_file.path}"

      content = File.read(test_file.path)
      expect(content).to include "program :"
    end

    it "checks formatting with --check flag" do
      # Unformatted file
      stdout, stderr, status = run_command(["format", test_file.path, "--check"])

      expect(status.success?).to be false
      expect(stdout).to include "needs formatting"

      # Format the file
      run_command(["format", test_file.path, "--write"])

      # Check again
      stdout, stderr, status = run_command(["format", test_file.path, "--check"])

      expect(status.success?).to be true
      expect(stdout).to include "already formatted"
    end
  end

  context "init command" do
    around do |example|
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) { example.run }
      end
    end

    it "generates default config file" do
      stdout, stderr, status = run_command(["init"])

      expect(status.success?).to be true
      expect(stdout).to include "Generated .raccfmt.yml"
      expect(File.exist?(".raccfmt.yml")).to be true

      config = Psych.safe_load_file(".raccfmt.yml")
      expect(config["rules"]).to be_a Hash
    end
  end

  context "version command" do
    it "shows version" do
      stdout, stderr, status = run_command(["version"])

      expect(status.success?).to be true
      expect(stdout).to match(/raccfmt \d+\.\d+\.\d+/)
    end
  end

  context "help command" do
    it "shows help information" do
      stdout, stderr, status = run_command(["help"])

      expect(status.success?).to be true
      expect(stdout).to include "format FILE"
      expect(stdout).to include "init"
      expect(stdout).to include "version"
    end

    it "shows command-specific help" do
      stdout, stderr, status = run_command(["help", "format"])

      expect(status.success?).to be true
      expect(stdout).to include "--config"
      expect(stdout).to include "--write"
      expect(stdout).to include "--check"
    end
  end
end
