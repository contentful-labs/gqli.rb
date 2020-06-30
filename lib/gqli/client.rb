# frozen_string_literal: true

require 'http'
require 'json'
require_relative './response'
require_relative './introspection'
require_relative './version'

module GQLi
  # GraphQL HTTP Client
  class Client
    attr_reader :url, :params, :headers, :validate_query, :schema, :options

    def initialize(url, params: {}, headers: {}, validate_query: true, options: {})
      @url = url
      @params = params
      @headers = headers
      @validate_query = validate_query
      @options = options
      @options[:read_timeout] ||= 60
      @options[:write_timeout] ||= 60
      @options[:connect_timeout] ||= 60

      @schema = Introspection.new(self) if validate_query
    end

    # Executes a query
    # If validations are enabled, will perform validation check before request.
    def execute(query)
      if validate_query
        validation = schema.validate(query)
        fail validation_error_message(validation) unless validation.valid?
      end

      execute!(query)
    end

    # Executres a query
    # Ignores validations
    def execute!(query)
      http_response = HTTP.headers(request_headers)
                          .timeout(timeout_options)
                          .post(@url, params: @params, json: { query: query.to_gql })

      fail "Error: #{http_response.reason}\nBody: #{http_response.body}" if http_response.status >= 300

      data = JSON.parse(http_response.to_s)['data']

      Response.new(data, query)
    end

    # Validates a query against the schema
    def valid?(query)
      return true unless validate_query

      schema.valid?(query)
    end

    protected

    def validation_error_message(validation)
      <<~ERROR
        Validation Error: query is invalid - HTTP Request not sent.

        Errors:
          - #{validation.errors.join("\n  - ")}
      ERROR
    end

    def request_headers
      {
        accept: 'application/json',
        user_agent: "gqli.rb/#{VERSION}; http.rb/#{HTTP::VERSION}"
      }.merge(@headers)
    end

    def timeout_options
      {
        write: options[:write_timeout],
        connect: options[:connect_timeout],
        read: options[:read_timeout]
      }
    end
  end
end
