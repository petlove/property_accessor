# frozen_string_literal: true

require "strscan"

class PropertyAccessor
  module Path
    class Parser
      Property = Struct.new(:property, :kind, :opts) do
        def to_path
          # :nocov:
          return "#{property}[#{opts[:index]}]" if kind == :indexed
          return "#{property}(#{opts[:key]})" if kind == :mapped

          property
          # :nocov:
        end
      end

      ParsedPath = Struct.new(:properties)

      class InvalidPath < StandardError; end

      NAME = /[a-zA-Z][a-zA-Z0-9?!_]*/
      INT = /-?(?:0|[1-9][0-9]*)/
      KEY = /[^)]*/
      DOT = "."
      LPAREN = "("
      RPAREN = ")"
      LBRACKET = "["
      RBRACKET = "]"

      def initialize(path)
        raise ArgumentError, "path is required" if path.nil? || path.empty?
        raise ArgumentError, "path must not end with a dot" if path.end_with?(DOT)

        @path = path.strip
        # Hack to make parsing a bit easier :)
        @path = ".#{@path}" unless path[0] == LPAREN || path[0] == LBRACKET
        @ss = StringScanner.new(@path)
      end

      def parse
        list = []

        until @ss.eos?
          if @ss.skip(DOT)
            name = parse_name
            # Check if current property is indexed (e.g. foo[0]).
            if @ss.scan(LBRACKET)
              list << Property.new(name, :indexed, {index: parse_index})
              next
            end

            # Check if current property is mapped (e.g. foo(bar))
            if @ss.scan(LPAREN)
              list << Property.new(name, :mapped, {key: parse_key})
              next
            end

            list << Property.new(name, :simple, {})
          elsif @ss.scan(LBRACKET)
            list << Property.new(nil, :indexed, {index: parse_index})
          elsif @ss.scan(LPAREN)
            list << Property.new(nil, :mapped, {key: parse_key})
          else
            raise InvalidPath, "unexpected token `#{@ss.peek(1)}' (#{@ss.rest})"
          end
        end

        ParsedPath.new(list)
      end

      private

      def parse_name
        val = @ss.scan(NAME)
        raise InvalidPath, "expected name at position #{actual_position}" unless val

        val
      end

      def parse_index
        if (val = @ss.scan(INT))
          val = Integer(val)
        else
          @ss.pos -= 1
          raise TypeError, "could not parse index as integer (#{@ss.rest})"
        end

        raise InvalidPath, "missing `#{RBRACKET}' at position #{actual_position}" unless @ss.skip(RBRACKET)

        val
      end

      def parse_key
        val = @ss.scan(KEY)

        raise InvalidPath, "missing `#{RPAREN}' at position #{actual_position}" unless @ss.skip(RPAREN)

        val
      end

      def actual_position
        (@path[0] == DOT) ? @ss.pos - 1 : @ss.pos
      end
    end
  end
end
