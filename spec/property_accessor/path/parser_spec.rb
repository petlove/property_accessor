# frozen_string_literal: true

require "spec_helper"

RSpec.describe PropertyAccessor::Path::Parser do
  describe "#parse" do
    it "can parse a simple path" do
      result = described_class.new("foo.bar").parse

      expect(result.segments).to match_array(
        [
          described_class::Segment.new("foo", :regular, {}),
          described_class::Segment.new("bar", :regular, {})
        ]
      )
    end

    it "can parse a complex path" do
      result = described_class.new("foo.bar[0].meh.pow[0][1]").parse

      expect(result.segments).to match_array(
        [
          described_class::Segment.new("foo", :regular, {}),
          described_class::Segment.new("bar", :indexed, {index: 0}),
          described_class::Segment.new("meh", :regular, {}),
          described_class::Segment.new("pow", :indexed, {index: 0}),
          described_class::Segment.new(nil, :indexed, {index: 1})
        ]
      )
    end

    it "raises when path contains an empty property" do
      expect do
        described_class.new("foo..bar").parse
      end.to raise_error(described_class::ParserError, /expected name at position/)
    end

    it "raises when path is nil" do
      expect do
        described_class.new(nil).parse
      end.to raise_error(ArgumentError, "path is required")
    end

    it "raises when path is empty" do
      expect do
        described_class.new("").parse
      end.to raise_error(ArgumentError, "path is required")
    end

    it "raises when path starts with a dot" do
      expect do
        described_class.new(".foo").parse
      end.to raise_error(ArgumentError, "path should not start nor end with a dot")
    end

    it "raises when path ends with a dot" do
      expect do
        described_class.new("foo.").parse
      end.to raise_error(ArgumentError, "path should not start nor end with a dot")
    end

    it "raises when path contains invalid characters" do
      expect do
        described_class.new("foo.bar$(baz)").parse
      end.to raise_error(described_class::ParserError, /unexpected token `\$'/)
    end

    it "raises when path is malformed" do
      expect do
        described_class.new("foo.bar[0").parse
      end.to raise_error(described_class::ParserError, /missing `\]'/)
    end

    it "raises when given an indexed property with non-integer index" do
      expect do
        described_class.new("foo[bar]").parse
      end.to raise_error(described_class::ParserError, /could not parse index as integer/)
    end

    it "raises when given an indexed property with no index at all" do
      expect do
        described_class.new("foo[]").parse
      end.to raise_error(described_class::ParserError, /could not parse index as integer/)
    end

    it "raises when given a path with extraneous whitespace" do
      expect do
        described_class.new("foo .bar").parse
      end.to raise_error(described_class::ParserError, /unexpected token ` '/)
    end
  end
end
