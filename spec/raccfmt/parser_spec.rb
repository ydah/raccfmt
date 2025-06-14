# frozen_string_literal: true

RSpec.describe Raccfmt::Parser do
  let(:parser) { described_class.new }

  describe "#parse" do
    context "with simple rule" do
      let(:input) do
        <<~RACC
          program: stmt_list { result = val[0] }
        RACC
      end

      it "parses rule name and action" do
        ast = parser.parse(input)

        expect(ast.type).to eq :root
        expect(ast.children.size).to eq 1

        rule = ast.children.first
        expect(rule).to be_a Raccfmt::AST::RuleNode
        expect(rule.name).to eq "program"
        expect(rule.productions.first).to eq "stmt_list { result = val[0] }"
      end
    end

    context "with multiple productions" do
      let(:input) do
        <<~RACC
          stmt_list: stmt
                   | stmt_list stmt
                   ;
        RACC
      end

      it "parses all productions" do
        ast = parser.parse(input)
        rule = ast.children.first

        expect(rule.productions).to eq ["stmt", "| stmt_list stmt"]
      end
    end

    context "with multi-line action" do
      let(:input) do
        <<~RACC
          program: stmt_list {
            result = val[0]
            puts "parsed"
          }
        RACC
      end

      it "parses multi-line action block" do
        ast = parser.parse(input)
        rule = ast.children.first

        expect(rule.actions.size).to eq 1
        action = rule.actions.first
        expect(action).to be_a Raccfmt::AST::ActionNode
        expect(action.value).to include "result = val[0]"
        expect(action.value).to include "puts \"parsed\""
      end
    end

    context "with comments" do
      let(:input) do
        <<~RACC
          # Grammar file
          program: stmt_list
          
          # Statement rule
          stmt: expr ';'
        RACC
      end

      it "preserves comments" do
        ast = parser.parse(input)

        comments = ast.children.select { |n| n.type == :comment }
        expect(comments.size).to eq 2
        expect(comments.first.value).to eq "# Grammar file\n"
      end
    end

    context "with empty lines" do
      let(:input) do
        <<~RACC
          program: stmt_list
          
          stmt: expr
        RACC
      end

      it "preserves empty lines" do
        ast = parser.parse(input)

        empty_lines = ast.children.select { |n| n.type == :comment && n.value.strip.empty? }
        expect(empty_lines).not_to be_empty
      end
    end

    context "with complex grammar" do
      let(:input) do
        <<~RACC
          class Parser
          
          token NUMBER IDENTIFIER
          
          rule
            program : stmt_list { result = Program.new(val[0]) }
            
            stmt_list : stmt { result = [val[0]] }
                      | stmt_list stmt { result = val[0] << val[1] }
                      ;
            
            stmt : expr ';' { result = ExprStatement.new(val[0]) }
                 | 'if' expr 'then' stmt_list 'end' {
                     result = IfStatement.new(val[1], val[3])
                   }
                 ;
          end
        RACC
      end

      it "parses complete grammar structure" do
        ast = parser.parse(input)

        rules = ast.children.select { |n| n.is_a?(Raccfmt::AST::RuleNode) }
        expect(rules.size).to eq 3

        program_rule = rules.find { |r| r.name == "program" }
        expect(program_rule).not_to be_nil
        expect(program_rule.productions.first).to include "stmt_list"
        expect(program_rule.actions.size).to eq 1

        stmt_rule = rules.find { |r| r.name == "stmt" }
        expect(stmt_rule).not_to be_nil
        expect(stmt_rule.productions.size).to eq 2
      end
    end
  end
end
