# frozen_string_literal: true

require "benchmark"

RSpec.describe "Performance" do
  let(:formatter) { Raccfmt::Formatter.new(Raccfmt::Config.new) }

  context "with large grammar files" do
    let(:large_grammar) do
      rules = 100.times.map do |i|
        <<~RULE
          rule_#{i} : term_#{i} { result = val[0] }
                    | rule_#{i} '+' term_#{i} { result = val[0] + val[2] }
                    | rule_#{i} '-' term_#{i} { result = val[0] - val[2] }
                    ;
        RULE
      end.join("\n")

      <<~RACC
        class LargeParser
        
        rule
        #{rules}
        
        end
      RACC
    end

    it "formats large files within reasonable time" do
      time = Benchmark.realtime do
        formatter.format(large_grammar)
      end

      expect(time).to be < 5.0 # Should complete within 5 seconds
    end

    it "maintains correct formatting for large files" do
      output = formatter.format(large_grammar)

      # Check that all rules are properly formatted
      expect(output.scan(/rule_\d+ :/).size).to eq 100
      expect(output).to include "  rule_0 :"
      expect(output).to include "  rule_99 :"
    end
  end
end
