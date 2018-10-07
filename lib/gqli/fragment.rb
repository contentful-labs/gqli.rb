# frozen_string_literal: true

require_relative './base'
require_relative './node'

module GQLi
  # Fragment wrapper
  class Fragment < Base
    attr_reader :__on_type

    def initialize(name, on, &block)
      super(name, 0, &block)
      @__on_type = on
    end

    # Serializes to a GraphQL string
    def to_gql
      <<~GQL
        fragment #{__name} on #{__on_type} {
        #{__nodes.map(&:to_gql).join("\n")}
        }
      GQL
    end
  end
end
