# frozen_string_literal: true

module GQLi
  # Module for creating a Contentful GraphQL client
  module Contentful
    # Creates a Contentful GraphQL client
    def self.create(space, access_token, environment: nil, validate_query: true)
      api_url = "https://graphql.contentful.com/content/v1/spaces/#{space}"
      api_url += "/environments/#{environment}" unless environment.nil?

      GQLi::Client.new(
        api_url,
        headers: {
          'Authorization' => "Bearer #{access_token}"
        },
        validate_query: validate_query
      )
    end
  end
end
