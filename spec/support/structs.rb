# frozen_string_literal: true

Person = Struct.new(:name)
Book = Struct.new(:author, :title, :category, :price, :written, :tags, keyword_init: true)

Store = Struct.new(:owner, :name, :books, keyword_init: true)
