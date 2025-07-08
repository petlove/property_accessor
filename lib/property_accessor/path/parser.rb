# frozen_string_literal: true

require "strscan"

class PropertyAccessor
  module Path
    class Parser
      Component = Struct.new(:key, :kind) do
        def to_s
          if kind == :index
            return "[#{key}]"
          end

          key
        end
      end

      ParsedPath = Struct.new(:components)

      class ParserError < StandardError; end

      NAME_RE = /[a-zA-Z_][a-zA-Z0-9_]*!?/
      INTEGER_RE = /(?:0|-?[1-9][0-9]*)/
      DOT = "."
      LBRACKET = "["
      RBRACKET = "]"

      def initialize(path)
        raise ArgumentError, "path is required" if path.nil? || path.empty?
        raise ArgumentError, "path should not start nor end with a dot" if path[0] == DOT || path[-1] == DOT

        @path = path.strip
        # Hack to make parsing a bit easier.
        @path = ".#{@path}" unless path[0] == LBRACKET
        @ss = StringScanner.new(@path)
      end

      def parse
        components = []

        until @ss.eos?
          if @ss.scan(DOT)
            name = @ss.scan(NAME_RE)
            raise ParserError, "expected name at position #{real_position}" unless name

            components << Component.new(name, :property)
          elsif @ss.scan(LBRACKET)
            index = consume_index
            raise ParserError, "missing `#{RBRACKET}' at position #{real_position}" unless @ss.skip(RBRACKET)

            components << Component.new(index, :index)
          else
            raise ParserError, "unexpected token `#{@ss.peek(1)}' (#{@ss.rest})"
          end
        end

        ParsedPath.new(components)
      end

      private

      def consume_index
        if (v = @ss.scan(INTEGER_RE))
          value = Integer(v)
          return value
        end

        @ss.pos -= 1
        raise ParserError, "could not parse index as integer (#{@ss.rest})"
      end

      def real_position
        (@path[0] == DOT) ? @ss.pos - 1 : @ss.pos
      end
    end
  end
end
