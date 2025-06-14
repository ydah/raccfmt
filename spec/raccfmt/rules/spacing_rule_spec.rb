# frozen_string_literal: true

RSpec.describe Raccfmt::Rules::SpacingRule do
  let(:config) do
    Raccfmt::Config.new(
      "rules" => {
        "spacing" => {
          "enabled" => true,
          "around_colon" => around_colon,
          "around_pipe" => around_pipe,
          "around_equals" => around_equals
        }
      }
    )
  end
  let(:around_colon) { true }
  let(:around_pipe) { true }
  let(:around_equals) { true }
  let(:rule) { described_class.new(config) }

  describe "#apply" do
    let(:parser) { Raccfmt::Parser.new }
    let(:ast) { parser.parse(input) }

    context "with around_colon enabled" do
      let(:input) do
        <<~RACC
          program:stmt_list
          stmt   :   expr
        RACC
      end

      it "adds proper spacing around colons" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        expect(output).to include "program : "
        expect(output).to include "stmt : "
        expect(output).not_to include "program:"
        expect(output).not_to include "stmt:"
      end
    end

    context "with around_colon disabled" do
      let(:around_colon) { false }
      let(:input) do
        <<~RACC
          program : stmt_list
          stmt   :   expr
        RACC
      end

      it "removes spacing around colons" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        expect(output).to include "program:"
        expect(output).to include "stmt:"
        expect(output).not_to include "program : "
      end
    end

    context "with around_pipe enabled" do
      let(:input) do
        <<~RACC
          stmt_list: stmt
                   |stmt_list stmt
                   |   stmt_list ';'
        RACC
      end

      it "adds proper spacing around pipes" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        expect(output).to include " | stmt_list stmt"
        expect(output).to include " | stmt_list ';'"
        expect(output).not_to include "|stmt"
      end
    end

    context "with around_pipe disabled" do
      let(:around_pipe) { false }
      let(:input) do
        <<~RACC
          stmt_list: stmt
                   | stmt_list stmt
        RACC
      end

      it "removes spacing around pipes" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        expect(output).to include "|stmt_list"
        expect(output).not_to include " | "
      end
    end

    context "with around_equals enabled" do
      let(:input) do
        <<~RACC
          program: stmt_list {result=val[0]}
          stmt: expr {foo=bar;baz=qux}
          assign: ID '=' expr {
            node=AssignNode.new
            node.id=val[0]
            node.value=val[2]
            result=node
          }
        RACC
      end

      it "adds proper spacing around equals" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        # Inline actions
        expect(output).to include "result = val[0]"
        expect(output).to include "foo = bar"
        expect(output).to include "baz = qux"

        # Multi-line actions
        expect(output).to include "node = AssignNode.new"
        expect(output).to include "node.id = val[0]"
        expect(output).to include "node.value = val[2]"
        expect(output).to include "result = node"
      end
    end

    context "with compound assignments" do
      let(:input) do
        <<~RACC
          list: items {
            result||=[]
            result+=val[0]
            result<<val[0]
          }
        RACC
      end

      it "handles compound assignment operators" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        expect(output).to include "result ||= []"
        expect(output).to include "result += val[0]"
        expect(output).to include "result << val[0]"
      end
    end
  end
end
