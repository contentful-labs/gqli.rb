# frozen_string_literal: true

require 'hashie/mash'

module GQLi
  # Response object wrapper
  class Response
    attr_reader :data, :errors, :query

    def initialize(data, errors, query)
      @data = Hashie::Mash.new(data)
      @errors = parse_errors(errors)
      @query = query
    end

    private

    # Accepts Hash or Array of errors and converts them to Hashie::Mash instances.
    # Recursively calls #parse_errors with items if array.
    # Returns nil if nil is passed.
    def parse_errors(errors)
      return unless errors
      return errors.map { |e| parse_errors(e) } if errors.is_a?(Array)

      Hashie::Mash.new(errors)
    end
  end
end
