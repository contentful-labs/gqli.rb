require_relative './base'

module GQLi
  class Query < Base
    def to_gql
      result =<<-GQL
query #{__name ? " " + __name : ""}{
#{__nodes.map(&:to_gql).join("\n")}
}
GQL

      result.lstrip
    end

    def __execute(client)
      client.execute(self)
    end

    def to_s
      to_gql
    end
  end
end
