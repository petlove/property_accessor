# frozen_string_literal: true

Person = Struct.new(:name)
Book = Struct.new(:author, :title, :price, :written, :tags)

Store = Struct.new(:owner, :name, :books) do
  def book(title)
    books.find { _1.title == title }
  end
end
