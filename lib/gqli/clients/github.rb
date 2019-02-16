# frozen_string_literal: true

module GQLi
  # Module for creating a Github GraphQL client
  module Github
    # Creates a Github GraphQL client
    def self.create(access_token, validate_query: true)
      GQLi::Client.new(
        'https://api.github.com/graphql',
        headers: {
          'Authorization' => "Bearer #{access_token}"
        },
        validate_query: validate_query
      )
    end
  end
end
