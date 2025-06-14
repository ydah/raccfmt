# frozen_string_literal: true

RSpec.describe Raccfmt::Rules::BraceNewlineRule do
  let(:config) do
    Raccfmt::Config.new(
      "rules" => {
        "brace_newline" => {
          "enabled" => true,
          "style" => style,
          "space_before" => space_before
        }
      }
    )
  end
  let(:style) { "same_line" }
  let(:space_before) { true }
  let(:rule) { described_class.new(config) }

  describe "#apply" do
    let(:parser) { Raccfmt::Parser.new }
    let(:ast) { parser.parse(input) }

    context "with same_line style" do
      let(:input) do
        <<~RACC
          program: stmt_list
          {
            result = val[0]
          }
        RACC
      end

      context "with space_before enabled" do
        it "places brace on same line with space" do
          formatted_ast = rule.apply(ast)
          output = formatted_ast.to_s

          expect(output).to include "stmt_list {"
          expect(output).not_to include "stmt_list{"
          expect(output).not_to include "stmt_list\n{"
        end
      end

      context "with space_before disabled" do
        let(:space_before) { false }

        it "places brace on same line without space" do
          formatted_ast = rule.apply(ast)
          output = formatted_ast.to_s

          expect(output).to include "stmt_list{"
          expect(output).not_to include "stmt_list {"
        end
      end
    end

    context "with new_line style" do
      let(:style) { "new_line" }
      let(:input) do
        <<~RACC
          program: stmt_list { result = val[0] }
        RACC
      end

      it "places brace on new line" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        expect(output).to include "stmt_list\n  {"
        expect(output).not_to include "stmt_list {"
      end
    end

    context "with multiple actions" do
      let(:input) do
        <<~RACC
          stmt: expr ';' { result = val[0] }
              | 'return' expr { result = ReturnNode.new(val[1]) }
        RACC
      end

      it "applies style to all actions" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        expect(output.scan(/';' \{/).size).to eq 1
        expect(output.scan(/expr \{/).size).to eq 1
      end
    end
  end
end
