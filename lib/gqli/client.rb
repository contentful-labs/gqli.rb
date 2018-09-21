require 'http'
require 'json'
require_relative './response'

module GQLi
  class Client
    attr_reader :url

    def initialize(url, params: {}, headers: {})
      @url = url
      @params = params
      @headers = headers
    end

    def execute(query)
      http_response = HTTP.headers(request_headers).post(@url, params: @params, json: { query: query.to_gql })

      raise "Error: #{http_response.reason}\nBody: #{http_response.body}" if http_response.status >= 300

      data = JSON.load(http_response.to_s)['data']

      Response.new(data, query)
    end

    def request_headers
      {
        accept: "application/json"
      }.merge(@headers)
    end
  end
end
