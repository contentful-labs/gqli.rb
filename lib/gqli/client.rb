# frozen_string_literal: true

require 'http'
require 'json'
require_relative './response'
require_relative './introspection'

module GQLi
  # GraphQL HTTP Client
  class Client
    attr_reader :url, :params, :headers, :validate_query, :schema

    def initialize(url, params: {}, headers: {}, validate_query: true)
      @url = url
      @params = params
      @headers = headers
      @validate_query = validate_query

      @schema = Introspection.new(self) if validate_query
    end

    def execute(query)
      fail 'Validation Error: query is invalid - HTTP Request not sent' unless valid?(query)

      execute!(query)
    end

    def execute!(query)
      http_response = HTTP.headers(request_headers).post(@url, params: @params, json: { query: query.to_gql })

      fail "Error: #{http_response.reason}\nBody: #{http_response.body}" if http_response.status >= 300

      data = JSON.parse(http_response.to_s)['data']

      Response.new(data, query)
    end

    def request_headers
      {
        accept: 'application/json'
      }.merge(@headers)
    end

    def valid?(query)
      return true unless validate_query

      @schema.valid?(query)
    end
  end
end
