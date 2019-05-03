# frozen_string_literal: true

module GQLi
  # Mutation node
  class Mutation < Base
    # Serializes to a GraphQL string
    def to_gql
      result = <<~GQL
        mutation #{__name ? __name + ' ' : ''}{
        #{__nodes.map(&:to_gql).join("\n")}
        }
      GQL

      result.lstrip
    end

    # Delegates itself to the client to be executed
    def __execute(client)
      client.execute(self)
    end

    # Serializes to a GraphQL string
    def to_s
      to_gql
    end
  end
end
