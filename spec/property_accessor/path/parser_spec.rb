# frozen_string_literal: true

require "spec_helper"

RSpec.describe PropertyAccessor::Path::Parser do
  describe "#parse" do
    test "simple path" do
      result = described_class.new("foo.bar").parse

      expect(result.properties).to match_array(
        [
          described_class::Property.new("foo", :simple, {}),
          described_class::Property.new("bar", :simple, {})
        ]
      )
    end

    test "complex path" do
      result = described_class.new("foo.bar(baz)[0].meh.pow(lol)(qux)").parse

      expect(result.properties).to match_array(
        [
          described_class::Property.new("foo", :simple, {}),
          described_class::Property.new("bar", :mapped, {key: "baz"}),
          described_class::Property.new(nil, :indexed, {index: 0}),
          described_class::Property.new("meh", :simple, {}),
          described_class::Property.new("pow", :mapped, {key: "lol"}),
          described_class::Property.new(nil, :mapped, {key: "qux"})
        ]
      )
    end

    test "empty property" do
      expect do
        described_class.new("foo..bar").parse
      end.to raise_error(/expected name/)
    end

    test "missing path" do
      expect do
        described_class.new(nil).parse
      end.to raise_error(ArgumentError, "path is required")
    end

    test "empty path" do
      expect do
        described_class.new("").parse
      end.to raise_error(ArgumentError, "path is required")
    end

    test "path with a starting dot" do
      expect do
        described_class.new(".foo").parse
      end.to raise_error(ArgumentError, "path should not start nor end with a dot")
    end

    test "path with a ending dot" do
      expect do
        described_class.new("foo.").parse
      end.to raise_error(ArgumentError, "path should not start nor end with a dot")
    end

    test "path with invalid character" do
      expect do
        described_class.new("foo.bar$(baz)").parse
      end.to raise_error(/unexpected token `\$'/)
    end

    test "malformed path" do
      expect do
        described_class.new("foo.bar[0").parse
      end.to raise_error(/missing `\]'/)
    end

    test "indexed property with non-integer index" do
      expect do
        described_class.new("foo[bar]").parse
      end.to raise_error(/could not parse index as integer/)
    end

    test "indexed property with no index at all" do
      expect do
        described_class.new("foo[]").parse
      end.to raise_error(/could not parse index as integer/)
    end

    test "mapped property with empty key" do
      result = described_class.new("foo()").parse

      expect(result.properties).to match_array(
        [
          described_class::Property.new("foo", :mapped, {key: ""})
        ]
      )
    end

    test "empty property" do
      expect do
        described_class.new("foo..bar").parse
      end.to raise_error(/expected name/)
    end

    test "path with extraneous whitespace" do
      expect do
        described_class.new("foo .bar").parse
      end.to raise_error(/unexpected token ` '/)
    end
  end
end
