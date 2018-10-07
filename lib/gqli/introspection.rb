# frozen_string_literal: true

require_relative './dsl'

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
          onOperation
          onFragment
          onField
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

    # Returns wether the query is valid or not
    def valid?(query)
      return false unless query.is_a?(Query)

      query_type = types.find { |t| t.name.casecmp('query').zero? }
      query.__nodes.each do |node|
        return false unless valid_node?(query_type, node)
      end

      true
    end

    private

    def valid_node?(parent_type, node)
      return true if parent_type.kind == 'SCALAR'

      return valid_match_node?(parent_type, node) if node.__name.start_with?('... on')

      node_type = parent_type.fetch('fields', []).find { |f| f.name == node.__name }
      return false if node_type.nil?

      return false unless valid_params?(node_type, node)

      resolved_node_type = type_for(node_type)
      return false if resolved_node_type.nil?

      return false unless valid_nesting_node?(resolved_node_type, node)

      node.__nodes.all? { |n| valid_node?(resolved_node_type, n) }
    end

    def valid_match_node?(parent_type, node)
      return true if parent_type.fetch('possibleTypes', []).find { |t| t.name == node.__name.gsub('... on ', '') }
      false
    end

    def valid_params?(node_type, node)
      node.__params.each do |param, value|
        arg = node_type.fetch('args', []).find { |a| a.name == param.to_s }
        return false if arg.nil?

        arg_type = type_for(arg)
        return false if arg_type.nil?

        return false unless valid_value_for_type?(arg_type, value)
      end

      true
    end

    def valid_nesting_node?(node_type, node)
      return false unless valid_object_node?(node_type, node)
      return false unless valid_array_node?(node_type, node)
      true
    end

    def valid_object_node?(node_type, node)
      return false if %w[OBJECT INTERFACE].include?(node_type.kind) && node.__nodes.empty?
      true
    end

    def valid_array_node?(node_type, node)
      return false if %w[OBJECT INTERFACE].include?(node_type.kind) && node.__nodes.empty?
      true
    end

    def valid_value_for_type?(arg_type, value)
      case value
      when ::String
        return false unless arg_type.name == 'String' || arg_type.name == 'ID'
      when ::Integer
        return false unless arg_type.name == 'Int'
      when ::Float
        return false unless arg_type.name == 'Float'
      when ::Hash
        return valid_hash_value?(arg_type, value)
      when true, false
        return false unless arg_type.name == 'Boolean'
      else
        return false
      end

      true
    end

    def valid_hash_value?(arg_type, value)
      return false unless arg_type.kind == 'INPUT_OBJECT'

      type = types.find { |f| f.name == arg_type.name }
      return false if type.nil?

      value.each do |k, v|
        input_field = type.fetch('inputFields', []).find { |f| f.name == k.to_s }
        return false if input_field.nil?

        input_field_type = type_for(input_field)
        return false if input_field_type.nil?

        return false unless valid_value_for_type?(input_field_type, v)
      end
    end

    def type_for(field_type)
      type = case field_type.type.kind
             when 'NON_NULL'
               non_null_type(field_type.type.ofType)
             when 'LIST'
               field_type.type.ofType
             when 'OBJECT', 'INTERFACE', 'INPUT_OBJECT'
               field_type.type
             when 'SCALAR'
               field_type.type
             end

      types.find { |t| t.name == type.name }
    end

    def non_null_type(non_null)
      case non_null.kind
      when 'LIST'
        non_null.ofType
      else
        non_null
      end
    end
  end
end
