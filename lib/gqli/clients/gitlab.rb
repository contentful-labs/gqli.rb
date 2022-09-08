# frozen_string_literal: true

module GQLi
  # Module for creating a GitLab GraphQL client
  module GitLab
    # Creates a GitLab GraphQL client
    def self.create(access_token = nil, api: 'https://gitlab.com/api/graphql', validate_query: true, options: {})
      headers = {}
      headers['Authorization'] = "Bearer #{access_token}" if access_token

      GQLi::Client.new(
        api,
        headers: headers,
        validate_query: validate_query,
        options: options
      )
    end
  end
end
