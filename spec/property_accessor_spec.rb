# frozen_string_literal: true

require "spec_helper"

RSpec.describe PropertyAccessor do
  describe ".get_value" do
    subject(:getter) { described_class }

    let(:obj) do
      Store.new(
        Person.new("John Doe"),
        "Foomart",
        [
          Book.new("Nigel Rees", nil, 9, {year: 1996}, %w[asdf asdf2]),
          Book.new("Evelyn Waugh", "Sword of Honour", 13, {year: 1997}, %w[foo bar])
        ]
      )
    end

    test "object is missing" do
      expect do
        getter.get_value(nil, "name")
      end.to raise_error(ArgumentError)
    end

    test "path is missing" do
      expect do
        getter.get_value(obj, nil)
      end.to raise_error(ArgumentError)
    end

    test "simple property" do
      expect(getter.get_value(obj, "name")).to eq("Foomart")
    end

    test "nested property" do
      expect(getter.get_value(obj, "owner.name")).to eq("John Doe")
    end

    test "indexed property" do
      expect(getter.get_value(obj, "books[0].author")).to eq("Nigel Rees")
    end

    test "indexed property with no name" do
      expect do
        getter.get_value(obj, "[0].author")
      end.to raise_error(ArgumentError, /no property name specified for/)
    end

    test "indexed property with invalid index" do
      expect do
        getter.get_value(obj, "books[meh].author")
      end.to raise_error(/could not parse index as integer/)
    end

    test "indexed property on array", aggregate_errors: true do
      expect(getter.get_value(["foo", ["bar"]], "[0]")).to eq("foo")
      expect(getter.get_value(["foo", %w[bar baz]], "[1][0]")).to eq("bar")
      expect(getter.get_value(["foo", %w[bar baz]], "[1][-1]")).to eq("baz")
    end

    test "raises when the value of the specified indexed property is not an array-like" do
      expect do
        getter.get_value(obj, "name[0]")
      end.to raise_error(TypeError, /property.*is expected to be an array-like/i)
    end

    test "mapped property", aggregate_errors: true do
      expect(getter.get_value(obj, "books[0].written(year)")).to eq(1996)
      expect(getter.get_value(obj, "book(Sword of Honour).price")).to eq(13)
    end

    test "mapped property with no name" do
      expect do
        getter.get_value(obj, "(Sword of Honour).price")
      end.to raise_error(ArgumentError, /no property name specified for/)
    end

    test "mapped property on hash", aggregate_errors: true do
      expect(getter.get_value({foo: "bar"}, "(foo)")).to eq("bar")
      expect(getter.get_value({foo: {bar: "baz"}}, "(foo)(bar)")).to eq("baz")
      expect(getter.get_value({"foo" => {"bar" => "baz"}}, "foo.bar")).to eq("baz")
      expect(getter.get_value({"" => "foobar"}, "()")).to eq("foobar")
    end

    test "raises when the value of the specified mapped property is not a hash, but it should be" do
      expect do
        getter.get_value(obj, "owner(foobar)")
      end.to raise_error(TypeError, /property.*is expected to be a Hash/i)
    end

    test "unknown property" do
      expect do
        getter.get_value(obj, "foobar")
      end.to raise_error(/undefined method `foobar'/)
    end

    test "raises if a property referenced in a nested path returns nil and :raise_on_nilable_property is true or unset" do
      expect do
        getter.get_value(obj, "books[0].title.upcase")
      end.to raise_error(/unexpected nil value for property referenced in property path `title'/)
    end

    test "does not raise if a property referenced in a nested path returns nil and :raise_on_nilable_property is false" do
      expect do
        expect(getter.get_value(obj, "books[0].title.upcase", raise_on_nilable_property: false)).to be_nil
      end.not_to raise_error
    end
  end
end
