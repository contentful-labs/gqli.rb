# frozen_string_literal: true

require_relative './base'

module GQLi
  # Node wrapper
  class Node < Base
    attr_reader :__params

    def initialize(name, params = {}, depth = 1, &block)
      super(name, depth, &block)
      @__params = params
    end

    # Serializes to a GraphQL string
    def to_gql
      result = '  ' * __depth + __name
      result += __params_to_s(__params, true) unless __params.empty?
      unless __nodes.empty?
        result += " {\n"
        result += __nodes.map(&:to_gql).join("\n")
        result += "\n#{'  ' * __depth}}"
      end

      result
    end

    private

    def __directive?(params)
      params.size == 1 && params.keys.first.to_s.start_with?('@')
    end

    def __directive(params)
      params.first.tap do |directive, directive_params|
        return " #{directive}#{__params_to_s(directive_params, true)}"
      end
    end

    def __params_to_s(params, initial = false)
      case params
      when ::Hash
        return __directive(params) if __directive?(params)

        result = params.map do |k, v|
          "#{k}: #{__params_to_s(v)}"
        end.join(', ')

        return "(#{result})" if initial

        "{#{result}}"
      when ::Array
        "[#{params.map { |p| __params_to_s(p) }.join(', ')}]"
      when ::String
        "\"#{params}\""
      else
        params.to_s
      end
    end
  end
end
