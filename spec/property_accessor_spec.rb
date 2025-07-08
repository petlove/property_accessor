# frozen_string_literal: true

require "spec_helper"

RSpec.describe PropertyAccessor do
  describe ".get_value", aggregate_errors: true do
    subject(:getter) { described_class }

    let(:object) do
      Store.new(
        owner: Person.new("John Doe"),
        name: "Foomart",
        books: [
          Book.new(
            author: "Nigel Rees",
            title: "Sayings of the Century",
            price: 9,
            written: {year: 1996},
            tags: %w[asdf asdf2]
          ),
          Book.new(
            author: "Evelyn Waugh",
            title: "Sword of Honour",
            price: 13,
            written: {year: 1997},
            tags: %w[foo bar]
          )
        ]
      )
    end

    it "raises when object is missing" do
      expect do
        getter.get_value(nil, "name")
      end.to raise_error(ArgumentError)
    end

    it "raises when path is missing" do
      expect do
        getter.get_value(object, nil)
      end.to raise_error(ArgumentError)
    end

    it "can handle a simple property" do
      expect(getter.get_value(object, "name")).to eq("Foomart")
    end

    it "can handle nested properties" do
      expect(getter.get_value(object, "owner.name")).to eq("John Doe")
    end

    it "can handle indexed properties" do
      expect(getter.get_value(object, "books[0].author")).to eq("Nigel Rees")
    end

    it "can handle indexed properties when object is an array" do
      expect(getter.get_value(["foo", ["bar"]], "[0]")).to eq("foo")
      expect(getter.get_value([%w[bar baz]], "[0][1]")).to eq("baz")
      expect(getter.get_value(["foo", %w[bar baz]], "[-1][0]")).to eq("bar")
    end

    it "does not raise when given a path where last segment is an indexed property but object is not array-like" do
      expect(getter.get_value(object, "name[0]")).to be_nil
    end

    it "does not raise when given a path where last segment is an unknown property" do
      expect(getter.get_value(object, "foobar")).to be_nil
    end

    it "raises when given a path where a nested property returns nil and strict option is true or unset" do
      expect do
        getter.get_value(object, "books[0].category.upcase")
      end.to raise_error(described_class::NoSuchPropertyError, /Cannot access property or array index/)
    end

    it "does not raise when given a path where a nested property returns nil and strict option is false" do
      expect do
        expect(getter.get_value(object, "books[0].category.upcase", strict: false)).to be_nil
      end.not_to raise_error
    end

    it "can handle regular properties when object is a Hash" do
      expect(getter.get_value({"foo" => "bar"}, "foo")).to eq("bar")
      expect(getter.get_value({"foo" => ["bar"]}, "foo[0]")).to eq("bar")
    end

    it "can handle regular properties when object is a Hash and the keys are symbols" do
      expect(getter.get_value({foo: "bar"}, "foo")).to eq("bar")
    end
  end
end
