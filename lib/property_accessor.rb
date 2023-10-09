# frozen_string_literal: true

require "property_accessor/path"

class PropertyAccessor
  class Error < StandardError; end

  class NilValueInNestedPathError < Error; end

  def self.get_value(object, path, opts = {})
    new(path, opts).get_value(object)
  end

  def initialize(path, opts = {})
    raise ArgumentError, "path is required" if path.nil? || path.empty?

    @path = path
    @raise_on_nilable_property = opts.fetch(:raise_on_nilable_property, true)

    @props = Path.parse(path).properties
  end

  def get_value(object)
    raise ArgumentError, "object is required" if object.nil?

    @props.each_with_index do |p, i|
      nested_object =
        case p.kind
        when :simple
          get_property(object, p.name)
        when :indexed
          get_indexed_property(object, p.name, p.opts[:index])
        else
          get_mapped_property(object, p.name, p.opts[:key])
        end

      if nested_object.nil?
        if @raise_on_nilable_property && i != @props.length - 1
          raise(
            NilValueInNestedPathError,
            "unexpected nil value for property `#{p}' -- #{object.inspect}"
          )
        else
          return nil
        end
      end

      object = nested_object
    end

    object
  end

  private

  def get_indexed_property(object, name, index)
    unless name
      return object.to_ary[index] if object.respond_to?(:to_ary)

      raise ArgumentError, "no property name specified for class `#{object.class}'"
    end

    result = object.public_send(name.to_sym)
    unless result.respond_to?(:to_ary)
      raise TypeError, "property `#{name}' is expected to be an array-like, " \
        "got `#{result.nil? ? "nil" : result.class}' instead"
    end

    result.to_ary[index]
  end

  def get_mapped_property(object, name, key)
    return object[key.to_sym] || object[key] if name.nil? && object.is_a?(Hash)
    raise ArgumentError, "no property name specified for class `#{object.class}'" unless name

    meth = object.public_method(name.to_sym)

    # Call a single-argument method with the same name if there is one.
    return meth.call(key) if meth.parameters.size == 1

    # If we reach here, it's because the value has to be retrieved from
    # a hash (a "real" Hash, for now).
    result = meth.call
    unless result.is_a?(Hash)
      raise TypeError, "property `#{name}' is expected to be a Hash, " \
        "got `#{result.nil? ? "nil" : result.class}' instead"
    end

    result[key.to_sym] || result[key]
  end

  def get_property(object, name)
    raise ArgumentError, "no property name specified for class `#{object.class}'" if name.nil?

    if object.is_a?(Hash)
      object[name.to_sym] || object[name]
    else
      object.public_send(name.to_sym)
    end
  end
end
