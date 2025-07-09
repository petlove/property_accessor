# frozen_string_literal: true

require "property_accessor/path"

class PropertyAccessor
  class Error < StandardError; end

  class NoSuchPropertyError < StandardError; end

  def self.get_value(object, path, opts = {})
    new(path, opts).get_value(object)
  end

  def initialize(path, opts = {})
    raise ArgumentError, "path is required" if path.nil? || path.empty?

    @path = path
    @strict = opts.fetch(:strict, true)
    @path_components = Path.parse(path).components
  end

  def get_value(object)
    raise ArgumentError, "object is required" if object.nil?

    @path_components.each_with_index.reduce(object) do |value, (component, idx)|
      value =
        case component.kind
        when :property
          property = component.key

          if value.respond_to?(:to_hash)
            hash = value.to_hash
            hash[property] || hash[property.to_sym]
          elsif value.respond_to?(property)
            value.public_send(property)
          end
        when :index
          value.to_ary[component.key] if value.respond_to?(:to_ary)
        end

      if value.nil?
        if @strict && idx + 1 < @path_components.length
          raise NoSuchPropertyError, "Cannot access property or array index `#{component}' while traversing path `#{@path}'"
        end

        return nil
      end

      value
    end
  end
end
