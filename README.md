# PropertyAccessor

Utility class to facilitate the reading of properties from Ruby objects/Hashes using a dotted path notation that resembles JSONPath. Each "segment" of the path represents a property of a nested object structure (just like `dig`, but for objects of any kind).

## Installation

Add the gem to the `Gemfile`:

    $ gem 'property_accessor', github: 'petlove/property_acessor'

If bundler is not being used to manage dependencies, you will need to build the gem manually on your local machine after cloning the repo:

    $ git clone https://github.com/petlove/property_accessor.git
    $ cd property_accessor
    $ gem build property_accessor.gemspec
    $ gem install property_accessor-2.0.0.gem

## Usage

First, let's create some objects:

```ruby
require 'property_acessor'

Person = Struct.new(:name)
Book = Struct.new(:author, :title, :category, :price, :written, :tags, keyword_init: true)
Store = Struct.new(:owner, :name, :books, keyword_init: true)

store = Store.new(
  owner: Person.new("John Doe"),
  name: "Foomart",
  [
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
      category: "fiction",
      price: 13,
      written: {year: 1997},
      tags: %w[foo bar]
    )
  ]
)
```
A path expression can be specified in the following formats, with the layout of an identifying expression in parentheses:

**Simple** (`name`)

The specified name identifies an simple individual property of a particular object (usually, a regular `attr_reader` or `attr_accessor` method). Actually, it can be any method that takes no arguments.

```ruby
getter = PropertyAccessor.new("name")
getter.get_value(store)
# => "Foomart"

# It works with plain hashes as well
getter = PropertyAccessor.new("books[0].written.year")
getter.get_value(store)
# => 1996

getter = PropertyAccessor.new("name")
getter.get_value({name: "Foomart"})
# => "Foomart"

# Indifferent access is supported by default
getter.get_value({"name" => "Foomart"})
# => "Foomart"
```

> [!NOTE]
> You can also use this same syntax to access values from hash-like objects (those that implement the `to_hash` method).

**Nested** (`name1.name2.name3`)

The first name element is used to select a property, as for simple references above. The object returned for this property is then consulted using the same mechanism, for a property named `name2`, and so on. The property value that is ultimately retrieved is the one identified by the last path segment.

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

The underlying property value is assumed to be an array (or array-like). The appropriate (zero-relative) entry in the array is retrieved.

```ruby
getter = PropertyAccessor.new("books[0].author")
getter.get_value(store)
# => "Nigel Rees"

# You can specify a negative index
getter = PropertyAccessor.new("books[-1].tags[1]")
getter.get_value(store)
# => "bar"

# It works with plain arrays as well
getter = PropertyAccessor.new("[0]")
getter.get_value(["foo"])
# => "foo"

# ... even when they are nested
getter = PropertyAccessor.new("[0][2]")
getter.get_value([%w[foo bar baz]])
# => "baz"
```

**Combined** (`name1.name2[index].name3.name4[0][1]`)

Combining nested, and indexed properties is also supported. But I guess you have already figured that out :)

```ruby
# Pay attention to the last segment (regular string method)
getter = PropertyAccessor.new("books[-1].tags[0].upcase")
getter.get_value(store)
# => "FOO"
```

You can also just combine the two lines from the previous examples into one call with the convenient `PropertyAccessor.get_value` method:

```ruby
PropertyAccessor.get_value(store, "owner.name")
# => "John Doe"
```

> [!NOTE]
> 1. The path parser is very **finicky**, so watch out for any extraneous whitespaces and invalid characters. After all, it makes no sense to use an invalid Ruby identifier anyway.
> 2. The current implementation does not support any notation for specifying hash keys with whitespaces and other special characters.

### Available options

By default, `PropertyAccessor` will raise an error during path traversal when any property except the last one returns `nil`. This can be changed setting the `strict` option to `false`:

```ruby
# Raises NoSuchPropertyError error
PropertyAccessor.new("books[0].category.upcase").get_value(store)

# Works fine (nil is returned instead)
PropertyAccessor.new("books[0].category.upcase", strict: false).get_value(store)
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/petlove/property_accessor.
