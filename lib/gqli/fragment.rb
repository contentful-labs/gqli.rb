require_relative './base'
require_relative './node'

module GQLi
  class Fragment < Base
    attr_reader :__on_type
    def initialize(name, on, &block)
      super(name, 0, &block)
      @__on_type = on
    end

    def to_gql
      result =<<-GQL
fragment #{__name} on #{__on_type} {
#{__nodes.map(&:to_gql).join("\n")}
}
GQL
    end
  end
end
