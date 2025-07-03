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

    @path_components.each_with_index.reduce(object) do |val, (component, idx)|
      val =
        case component.kind
        when :property
          property = component.key

          if val.respond_to?(:to_hash)
            val = val.to_hash
            val[property] || val[property.to_sym]
          elsif val.respond_to?(property)
            val.public_send(property)
          end
        when :index
          val.to_ary[component.key] if val.respond_to?(:to_ary)
        end

      if val.nil?
        if @strict && idx + 1 < @path_components.length
          raise NoSuchPropertyError, "Cannot read #{component.kind} `#{component}' while traversing path `#{@path}'"
        end

        return nil
      end

      val
    end
  end
end
