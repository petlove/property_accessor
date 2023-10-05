# PropertyAccessor

Utility class to facilitate the extraction of properties from Ruby objects using a dotted path notation that resembles JSONPath.

## Installation

Add the gem to the `Gemfile`:

    $ gem 'property_accessor', github: 'petlove/property_acessor'

If bundler is not being used to manage dependencies, you will need to build the gem manually on your local machine after cloning the repo:

    $ git clone https://github.com/petlove/property_accessor.git
    $ cd property_accessor
    $ gem build property_accessor.gemspec
    $ gem install property_accessor-1.0.0.gem

## Usage

First, let's create some objects:

```ruby
require 'property_acessor'

Person = Struct.new(:name)
Book = Struct.new(:author, :title, :price, :written, :tags)

Store = Struct.new(:owner, :name, :books) do
  def book(title)
    books.find { _1.title == title }
  end
end

store = Store.new(
  Person.new("John Doe"),
  "Foomart",
  [
    Book.new("Nigel Rees", nil, 9, {year: 1996}, %w[asdf asdf2]),
    Book.new("Evelyn Waugh", "Sword of Honour", 13, {year: 1997}, %w[foo bar])
  ]
)
```
A path expression can be specified in the following five formats, with the layout of an identifying expression in parentheses:

**Simple** (`name`)

The specified name identifies an individual property of a particular object (usually, a regular `attr_reader` or `attr_accessor` method). In fact, it can be any method that takes no arguments.

```ruby
getter = PropertyAccessor.new("name")
getter.get_value(store)
# => "Foomart"

# It works with plain hashes too
getter = PropertyAccessor.new("name")
getter.get_value({name: "Foomart"})
# => "Foomart"
```

**Nested** (`name1.name2.name3`)

The first name element is used to select a property, as for simple references above. The object returned for this property is then consulted, using the same approach, for a property named `name2`, and so on. The property value that is ultimately retrieved is the one identified by the last name element.

```ruby
getter = PropertyAccessor.new("owner.name")
getter.get_value(store)
# => "John Doe"

# It works with plain hashes too
getter = PropertyAccessor.new("owner.name")
getter.get_value({owner: {name: "John Doe"}})
# => "John Doe"
```

**Indexed** (`name[index]`)

The underlying property value is assumed to be an array (or array-like). The appropriate (zero-relative) entry in the array is retrieved. It works the same way with plain arrays too.

```ruby
getter = PropertyAccessor.new("books[0].author")
getter.get_value(store)
# => "Nigel Rees"

# You can even specify a negative index!
getter = PropertyAccessor.new("books[-1].tags[1]")
getter.get_value(store)
# => "bar"

# It's also possible to pull values from plain arrays
getter = PropertyAccessor.new("[0]")
getter.get_value(["foo"])
# => "foo"

getter = PropertyAccessor.new("[0][2]")
getter.get_value([%w[foo bar baz]])
# => "baz"
```

**Mapped** (`name(key)`)

The target object is assumed to have a method that takes a single argument (it will receive the key as an argument), or be an actual hash containing a value mapped to the specified key (keys `:foo` and `"foo"` are considered to be the same).

```ruby
getter = PropertyAccessor.new("books[0].written(year)")
getter.get_value(store)
# => 1996

# Retrieve a book by title, then get its price
getter = PropertyAccessor.new("book(Sword of Honour).price")
getter.get_value(store)
# => 13

# It's also possible to pull values from plain hashes using an alternative syntax
getter = PropertyAccessor.new("(foo)(bar)")
getter.get_value({foo: {bar: "baz"}})
# => "baz"
```

**Combined** (`name1.name2[index].name3(key)`)

Combining mapped, nested, and indexed properties is also supported. But I guess you already realized that :)

```ruby
# Pay attention to the last element!
getter = PropertyAccessor.new("book(Sword of Honour).tags[0].upcase")
getter.get_value(store)
# => "FOO"
```

You can also just combine the two lines from the previous examples into one call with the convenient `PropertyAccessor.get_value` method:

```ruby
PropertyAccessor.get_value(store, "owner.name")
# => "John Doe"
```

When pulling values from hashes, use the alternative syntax if the key contains whitespaces:

```ruby
PropertyAccessor.get_value({"foo bar" => "baz"}, "(foo bar)")
# => "baz"
```

**Note**: The path parser is very "finicky", so watch out for extraneous whitespaces and invalid characters. After all, there's no point in using an invalid Ruby identifier anyway.

### Other available options

By default, PropertyAccessor raises an error when a reference to a property in a nested path returns `nil` (except for the last one). This can be changed using the `:raise_on_nilable_property` option:

```ruby
# Raises an error of type NilValueInNestedPathError
PropertyAccessor.new("books[2].title").get_value(store)

# Works fine (nil is returned)
PropertyAccessor.new("books[2].title", raise_on_nilable_property: false).get_value(store)
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/petlove/property_accessor.
