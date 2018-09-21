require_relative './base'

module GQLi
  class Node < Base
    attr_reader :__params

    def initialize(name, params = {}, depth = 1, &block)
      super(name, depth, &block)
      @__params = params
    end

    def to_gql
      result = "  " * __depth + __name
      result += "(" + __params_to_s(__params) + ")" unless __params.empty?
      if !__nodes.empty?
        result += " {\n"
        result += "#{__nodes.map(&:to_gql).join("\n")}"
        result += "\n#{"  " * __depth}}"
      end

      result
    end

    private

    def __params_to_s(params)
      case params
      when ::Hash
        params.map do |k, v|
          "#{k.to_s}: #{__params_to_s(v)}"
        end.join(", ")
      when ::Array
        params.map { |p| __params_to_s(p) }.join(", ")
      else
        params.to_s
      end
    end
  end
end
