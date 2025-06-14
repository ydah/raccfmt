# frozen_string_literal: true

RSpec.describe Raccfmt::Rules::IndentRule do
  let(:config) do
    Raccfmt::Config.new(
      "rules" => {
        "indent" => {
          "enabled" => true,
          "size" => indent_size,
          "style" => indent_style
        }
      }
    )
  end
  let(:indent_size) { 2 }
  let(:indent_style) { "spaces" }
  let(:rule) { described_class.new(config) }

  describe "#apply" do
    let(:parser) { Raccfmt::Parser.new }
    let(:ast) { parser.parse(input) }

    context "with spaces indentation" do
      let(:input) do
        <<~RACC
          program: stmt_list
          {
          result = val[0]
          }
          stmt: expr ';' { result = val[0] }
        RACC
      end

      it "indents productions and actions with spaces" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        expect(output).to include "  stmt_list"
        expect(output).to include "  {"
        expect(output).to include "    result = val[0]"
        expect(output).to include "  }"
      end
    end

    context "with tabs indentation" do
      let(:indent_style) { "tabs" }
      let(:indent_size) { 1 }
      let(:input) do
        <<~RACC
          program: stmt_list
          {
          result = val[0]
          }
        RACC
      end

      it "indents with tabs" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        expect(output).to include "stmt_list"
        expect(output).to include "\t{"
      end
    end

    context "with custom indent size" do
      let(:indent_size) { 4 }
      let(:input) do
        <<~RACC
          program: stmt_list
          {
          result = val[0]
          }
        RACC
      end

      it "uses specified indent size" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        expect(output).to include "stmt_list"
        expect(output).to include "        result"  # 8 spaces for nested content
      end
    end

    context "with nested structures" do
      let(:input) do
        <<~RACC
          stmt: 'if' expr 'then' stmt_list 'end' {
            if val[1]
              result = IfStatement.new(val[1], val[3])
            else
              result = nil
            end
          }
        RACC
      end

      it "maintains proper nesting indentation" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        lines = output.lines
        action_start = lines.find_index { |l| l.include?("{") }

        expect(lines[action_start + 1]).to match(/^    if/)
        expect(lines[action_start + 2]).to match(/^    result/)
      end
    end
  end
end
