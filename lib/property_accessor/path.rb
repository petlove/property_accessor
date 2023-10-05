# frozen_string_literal: true

require "property_accessor/path/parser"

class PropertyAccessor
  module Path
    def self.parse(path)
      # :nocov:
      Parser.new(path).parse
      # :nocov:
    end
  end
end
