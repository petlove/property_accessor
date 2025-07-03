# frozen_string_literal: true

require "spec_helper"

RSpec.describe PropertyAccessor::Path::Parser::Segment do
  describe "#to_s" do
    it "it returns the correct string representation for an indexed path segment" do
      expect(described_class.new("foo", :indexed, {index: 1}).to_s).to eq("foo[1]")
    end
  end
end
