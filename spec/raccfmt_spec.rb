# frozen_string_literal: true

RSpec.describe Raccfmt do
  it "has a version number" do
    expect(Raccfmt::VERSION).not_to be nil
  end

  it "defines necessary error classes" do
    expect(Raccfmt::Error).to be < StandardError
    expect(Raccfmt::ParseError).to be < Raccfmt::Error
    expect(Raccfmt::ConfigError).to be < Raccfmt::Error
  end
end
