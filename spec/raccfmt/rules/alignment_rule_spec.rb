# frozen_string_literal: true

RSpec.describe Raccfmt::Rules::AlignmentRule do
  let(:config) do
    Raccfmt::Config.new(
      "rules" => {
        "alignment" => {
          "enabled" => true,
          "align_actions" => align_actions,
          "align_rules" => align_rules
        }
      }
    )
  end
  let(:align_actions) { true }
  let(:align_rules) { true }
  let(:rule) { described_class.new(config) }

  describe "#apply" do
    let(:parser) { Raccfmt::Parser.new }
    let(:ast) { parser.parse(input) }

    context "with align_rules enabled" do
      let(:input) do
        <<~RACC
          program: stmt_list
          stmt: expr
          expression: term
          id: IDENTIFIER
        RACC
      end

      it "aligns rule names and colons" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        lines = output.lines

        # All colons should be aligned
        colon_positions = lines.map { |l| l.index(":") }.compact
        expect(colon_positions.uniq.size).to eq 1
      end
    end

    context "with productions alignment" do
      let(:input) do
        <<~RACC
          expr: term
              | expr '+' term
              | expr '-' term
          stmt: simple_stmt
               | compound_stmt
        RACC
      end

      it "aligns pipe symbols" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        lines = output.lines
        expr_lines = lines.select { |l| l.include?("expr") || l.strip.start_with?("|") }

        # Pipes should be aligned with the start of productions
        pipe_lines = expr_lines.select { |l| l.include?("|") }
        pipe_positions = pipe_lines.map { |l| l.index("|") }

        expect(pipe_positions.uniq.size).to eq 1
      end
    end

    context "with align_actions enabled" do
      let(:input) do
        <<~RACC
          program: stmt_list { result = val[0] }
          stmt: expr ';' { result = ExprStmt.new(val[0]) }
          expr: NUMBER {
              result = Number.new(val[0])
              @count += 1
            }
        RACC
      end

      it "aligns inline actions" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        # Inline actions should have consistent spacing
        expect(output).to include "{ result = val[0] }"
        expect(output).to include "{ result = ExprStmt.new(val[0]) }"
      end

      it "aligns multi-line actions" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        lines = output.lines
        action_lines = lines.select { |l| l.include?("Number.new") || l.include?("@count") }

        # Action content should be properly indented
        indents = action_lines.map { |l| l.index(/\S/) }
        expect(indents.uniq.size).to eq 1
      end
    end

    context "with complex grammar" do
      let(:input) do
        <<~RACC
          program: declarations
          declarations: declaration
                      | declarations declaration
          declaration: var_decl
                     | func_decl
                     | class_decl
          var_decl: 'var' ID '=' expr ';' { result = VarDecl.new(val[1], val[3]) }
          func_decl: 'def' ID '(' params ')' block { 
              result = FuncDecl.new(val[1], val[3], val[5]) 
            }
        RACC
      end

      it "handles complex alignment scenarios" do
        formatted_ast = rule.apply(ast)
        output = formatted_ast.to_s

        # Check rule name alignment
        lines = output.lines
        rule_lines = lines.select { |l| l =~ /^\s*\w+\s*:/ }
        colon_positions = rule_lines.map { |l| l.index(":") }

        # Colons should be aligned within groups
        expect(colon_positions.max - colon_positions.min).to be <= 2

        # Check production alignment
        pipe_lines = lines.select { |l| l.include?("|") }
        expect(pipe_lines).not_to be_empty
      end
    end
  end
end
