# frozen_string_literal: true

require_relative './dsl'
require_relative './validation'

module GQLi
  # Introspection schema and validator
  class Introspection
    extend DSL

    # Specific type kind introspection fragment
    TypeRef = fragment('TypeRef', '__Type') {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
          }
        }
      }
    }

    # Input value introspection fragment
    InputValue = fragment('InputValue', '__InputValue') {
      name
      description
      type { ___ TypeRef }
      defaultValue
    }

    # Type introspection fragment
    FullType = fragment('FullType', '__Type') {
      kind
      name
      description
      fields(includeDeprecated: true) {
        name
        description
        args { ___ InputValue }
        type { ___ TypeRef }
        isDeprecated
        deprecationReason
      }
      inputFields { ___ InputValue }
      interfaces { ___ TypeRef }
      enumValues(includeDeprecated: true) {
        name
        description
        isDeprecated
        deprecationReason
      }
      possibleTypes { ___ TypeRef }
    }

    # Query for fetching the complete schema
    IntrospectionQuery = query {
      __schema {
        queryType { name }
        mutationType { name }
        subscriptionType { name }
        types { ___ FullType }
        directives {
          name
          description
          args { ___ InputValue }
          locations
        }
      }
    }

    attr_reader :schema, :query_type, :mutation_type, :subscription_type, :types

    def initialize(client)
      @schema = client.execute!(IntrospectionQuery).data.__schema
      @query_type = schema.queryType
      @mutation_type = schema.mutationType
      @subscription_type = schema.subscriptionType
      @types = schema.types
    end

    # Returns the evaluated validation for a query
    def validate(query)
      Validation.new(self, query)
    end

    # Returns if the query is valid
    def valid?(query)
      validate(query).valid?
    end
  end
end
