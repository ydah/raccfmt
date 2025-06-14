# frozen_string_literal: true

RSpec.describe Raccfmt::Formatter do
  let(:config) { Raccfmt::Config.new }
  let(:formatter) { described_class.new(config) }

  describe "#format" do
    context "with all rules enabled" do
      let(:input) do
        <<~RACC
          program:stmt_list{result=val[0]}
          stmt_list:stmt{result=[val[0]]}|stmt_list stmt{result=val[0]<<val[1]}
        RACC
      end

      let(:expected_output) do
        <<~RACC
          program:
            stmt_list {
              result = val[0]
            }
            ;
          
          stmt_list:
            stmt {
              result = [val[0]]
            }
            | stmt_list stmt {
              result = val[0] << val[1]
            }
            ;
        RACC
      end

      it "formats the grammar properly" do
        output = formatter.format(input)
        expect(output.strip).to eq expected_output.strip
      end
    end

    context "with specific rules disabled" do
      let(:config) do
        Raccfmt::Config.new(
          "rules" => {
            "spacing" => { "enabled" => false },
            "empty_line" => { "enabled" => false }
          }
        )
      end

      let(:input) do
        <<~RACC
          program:stmt_list{result=val[0]}
        RACC
      end

      it "applies only enabled rules" do
        output = formatter.format(input)

        # Indent and brace rules should apply
        expect(output).to include " stmt_list"
        # But spacing around = should not be added
        expect(output).to include "result=val[0]"
      end
    end
  end
end
