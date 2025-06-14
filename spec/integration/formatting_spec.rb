# frozen_string_literal: true

require "tempfile"

RSpec.describe "Integration: Full formatting" do
  let(:formatter) { Raccfmt::Formatter.new(config) }

  context "with default configuration" do
    let(:config) { Raccfmt::Config.new }

    it "formats complex grammar files correctly" do
      input = read_fixture("complex_grammar.y")
      output = formatter.format(input)

      # Check overall structure
      expect(output).to include "class MyParser"
      expect(output).to include "---- header"
      expect(output).to include "---- inner"

      # Check indentation
      expect(output).to match(/^  program :/)
      expect(output).to match(/^    result = Program\.new/)

      # Check spacing
      expect(output).to include "program : declaration_list"
      expect(output).to include " | declaration_list declaration"

      # Check brace formatting
      expect(output).to include "declaration_list {"
      expect(output).to include "  result = [val[0]]"
      expect(output).to include "}"

      # Check empty lines between rules
      lines = output.lines
      program_index = lines.find_index { |l| l.include?("program :") }
      declaration_index = lines.find_index { |l| l.include?("declaration_list :") }

      expect(declaration_index - program_index).to be > 2 # empty line between
    end
  end

  context "with custom configuration" do
    let(:config) do
      Raccfmt::Config.new(
        "rules" => {
          "indent" => { "size" => 4, "style" => "spaces" },
          "brace_newline" => { "style" => "new_line" },
          "empty_line" => { "between_rules" => false }
        }
      )
    end

    it "applies custom formatting rules" do
      input = <<~RACC
        program: stmt_list { result = val[0] }
        stmt: expr ';' { result = val[0] }
      RACC

      output = formatter.format(input)

      # Check 4-space indentation
      expect(output).to include "    stmt_list"

      # Check new line brace style
      expect(output).to include "stmt_list\n    {"

      # Check no empty lines between rules
      lines = output.lines.reject(&:empty?)
      program_line = lines.find_index { |l| l.include?("program") }
      stmt_line = lines.find_index { |l| l.include?("stmt") }

      # Adjacent rules (considering the semicolon line)
      expect(stmt_line - program_line).to be <= 3
    end
  end

  context "error handling" do
    let(:config) { Raccfmt::Config.new }

    it "handles malformed grammar gracefully" do
      input = <<~RACC
        program: stmt_list {
          result = val[0]
          # Missing closing brace
        
        stmt: expr
      RACC

      expect {
        formatter.format(input)
      }.to raise_error(Raccfmt::ParseError)
    end

    it "handles empty input" do
      input = ""
      output = formatter.format(input)
      expect(output).to eq ""
    end

    it "handles only comments" do
      input = <<~RACC
        # This is a comment
        # Another comment
      RACC

      output = formatter.format(input)
      expect(output).to eq input
    end
  end
end
