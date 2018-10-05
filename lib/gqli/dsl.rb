# frozen_string_literal: true

require_relative './query'
require_relative './fragment'

module GQLi
  # GraphQL-like DSL methods
  module DSL
    def self.query(name = nil, &block)
      Query.new(name, &block)
    end

    def self.fragment(name, on, &block)
      Fragment.new(name, on, &block)
    end

    def query(name = nil, &block)
      Query.new(name, &block)
    end

    def fragment(name, on, &block)
      Fragment.new(name, on, &block)
    end
  end
end
