# frozen_string_literal: true

require_relative './query'
require_relative './fragment'
require_relative './enum_value'

module GQLi
  # GraphQL-like DSL methods
  module DSL
    # Creates a Query object
    #
    # Can be used at a class level
    def self.query(name = nil, &block)
      Query.new(name, &block)
    end

    # Creates a Fragment object
    #
    # Can be used at a class level
    def self.fragment(name, on, &block)
      Fragment.new(name, on, &block)
    end

    # Creates a EnumValue object
    #
    # Can be used at a class level
    def self.enum(value)
      EnumValue.new(value)
    end

    # Creates a Query object
    #
    # Can be used at an instance level
    def query(name = nil, &block)
      Query.new(name, &block)
    end

    # Creates a Fragment object
    #
    # Can be used at an instance level
    def fragment(name, on, &block)
      Fragment.new(name, on, &block)
    end

    # Creates a EnumValue object
    #
    # Can be used at an instance level
    def enum(value)
      EnumValue.new(value)
    end
  end
end
