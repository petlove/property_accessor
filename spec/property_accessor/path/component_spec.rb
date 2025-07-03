# frozen_string_literal: true

require "spec_helper"

RSpec.describe PropertyAccessor::Path::Parser::Component do
  describe "#to_s" do
    it "it returns the correct string representation for an index path component" do
      expect(described_class.new(1, :index).to_s).to eq("[1]")
    end
  end
end
