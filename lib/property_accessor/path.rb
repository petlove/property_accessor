# frozen_string_literal: true

require "property_accessor/path/parser"

class PropertyAccessor
  module Path
    def self.parse(path)
      Parser.new(path).parse
    end
  end
end
