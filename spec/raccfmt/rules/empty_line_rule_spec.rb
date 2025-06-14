# frozen_string_literal: true

RSpec.describe Raccfmt::Rules::EmptyLineRule do
  let(:config) do
    Raccfmt::Config.new(
      "rules" => {
        "empty_line" => {
          "enabled" => true,
          "between_rules" => between_rules,
          "after_header" => after_header,
          "before_footer" => before_footer
        }
      }
    )
  end
  let(:between_rules) { true }
  let(:after_header) { true }
  let(:before_footer) { true }
  let(:rule) { described_class.new(config) }

  describe "#apply" do
    let(:parser) { Raccfmt::Parser.new }
    let(:ast) { parser.parse(input) }

    context "with between_rules enabled" do
      let(:input) do
        <<~RACC
          program: stmt_list
          stmt: expr
          expr: NUMBER
        RACC
      end

      it "adds empty lines between rules" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s
        lines = output.lines

        program_idx = lines.find_index { |l| l.include?("program") }
        stmt_idx = lines.find_index { |l| l.include?("stmt") }
        expr_idx = lines.find_index { |l| l.include?("expr") }

        # Should have empty lines between rules
        expect(lines[stmt_idx - 1].strip).to be_empty
        expect(lines[expr_idx - 1].strip).to be_empty
      end
    end

    context "with between_rules disabled" do
      let(:between_rules) { false }
      let(:input) do
        <<~RACC
          program: stmt_list
          stmt: expr
        RACC
      end

      it "doesn't add empty lines between rules" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s
        lines = output.lines

        # Should not have excessive empty lines
        empty_line_count = lines.count { |l| l.strip.empty? }
        expect(empty_line_count).to be < 2
      end
    end

    context "with after_header enabled" do
      let(:input) do
        <<~RACC
          class Parser
          token NUMBER IDENTIFIER
          rule
          program: stmt_list
        RACC
      end

      it "adds empty line after header section" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s
        lines = output.lines

        # Find the transition from header to rules
        rule_line = lines.find_index { |l| l.include?("program") }
        expect(lines[rule_line - 1].strip).to be_empty
      end
    end

    context "with before_footer enabled" do
      let(:input) do
        <<~RACC
          program: stmt_list
          ---- header
          require 'parser'
        RACC
      end

      it "adds empty line before footer section" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s
        lines = output.lines

        footer_idx = lines.find_index { |l| l.include?("---- header") }
        expect(lines[footer_idx - 1].strip).to be_empty
      end
    end

    context "with existing empty lines" do
      let(:input) do
        <<~RACC
          program: stmt_list

          stmt: expr
        RACC
      end

      it "doesn't add duplicate empty lines" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        # Should not have consecutive empty lines
        expect(output).not_to match(/\n\n\n/)
      end
    end
  end
end
