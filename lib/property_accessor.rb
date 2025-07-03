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
    @path_segments = Path.parse(path).segments
  end

  def get_value(object)
    raise ArgumentError, "object is required" if object.nil?

    value = object

    @path_segments.each_with_index do |segment, idx|
      value =
        case segment.kind
        when :regular
          read_regular_property(value, segment.name)
        when :indexed
          read_indexed_property(value, segment.name, segment.meta[:index])
        end

      if value.nil?
        if @strict && idx + 1 < @path_segments.length
          raise NoSuchPropertyError, "Cannot read property `#{segment.unparse}' while traversing path `#{@path}'"
        end

        break
      end
    end

    value
  end

  private

  def read_regular_property(value, property)
    if value.respond_to?(:to_hash)
      value = value.to_hash
      value[property.to_sym] || value[property]
    elsif value.respond_to?(property)
      value.public_send(property)
    end
  end

  def read_indexed_property(value, property, index)
    val = value
    if property
      val = read_regular_property(value, property)
      return unless val
    end

    return nil unless val.respond_to?(:to_ary)

    val.to_ary[index]
  end
end
