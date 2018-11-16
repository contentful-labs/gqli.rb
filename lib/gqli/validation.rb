# frozen_string_literal: true

module GQLi
  # Validations
  class Validation
    attr_reader :schema, :query, :errors

    def initialize(schema, query)
      @schema = schema
      @query = query
      @errors = []

      validate
    end

    # Returns wether the query is valid or not
    def valid?
      errors.empty?
    end

    protected

    def validate
      fail 'Not a Query object' unless query.is_a?(Query)

      query_type = types.find { |t| t.name.casecmp('query').zero? }
      query.__nodes.each do |node|
        begin
          validate_node(query_type, node)
        rescue StandardError => e
          errors << e
        end
      end

      true
    rescue StandardError => e
      errors << e
    end

    private

    def types
      schema.types
    end

    def validate_node(parent_type, node)
      validate_directives(node)

      return valid_match_node?(parent_type, node) if node.__name.start_with?('... on')

      node_type = parent_type.fetch('fields', []).find { |f| f.name == node.__name }
      fail "Node type not found for '#{node.__name}'" if node_type.nil?

      validate_params(node_type, node)

      resolved_node_type = type_for(node_type)
      fail "Node type not found for '#{node.__name}'" if resolved_node_type.nil?

      validate_nesting_node(resolved_node_type, node)

      node.__nodes.each { |n| validate_node(resolved_node_type, n) }
    end

    def valid_match_node?(parent_type, node)
      return if parent_type.fetch('possibleTypes', []).find { |t| t.name == node.__name.gsub('... on ', '') }
      fail "Match type '#{node.__name.gsub('... on ', '')}' invalid"
    end

    def validate_directives(node)
      return unless node.__params.size == 1
      node.__params.first.tap do |k, v|
        break unless k.to_s.start_with?('@')

        fail "Directive unknown '#{k}'" unless %i[@include @skip].include?(k)
        fail "Missing arguments for directive '#{k}'" if v.nil? || !v.is_a?(::Hash) || v.empty?
        v.each do |arg, value|
          begin
            fail "Invalid argument '#{arg}' for directive '#{k}'" if arg.to_s != 'if'
            fail "Invalid value for 'if`, must be a boolean" if value != !!value
          rescue StandardError => e
            errors << e
          end
        end
      end
    end

    def validate_params(node_type, node)
      node.__params.reject { |p, _| p.to_s.start_with?('@') }.each do |param, value|
        begin
          arg = node_type.fetch('args', []).find { |a| a.name == param.to_s }
          fail "Invalid argument '#{param}'" if arg.nil?

          arg_type = type_for(arg)
          fail "Argument type not found for '#{param}'" if arg_type.nil?

          validate_value_for_type(arg_type, value, param)
        rescue StandardError => e
          errors << e
        end
      end
    end

    def validate_nesting_node(node_type, node)
      fail "Invalid object for node '#{node.__name}'" unless valid_object_node?(node_type, node)
    end

    def valid_object_node?(node_type, node)
      return false if %w[OBJECT INTERFACE].include?(node_type.kind) && node.__nodes.empty?
      true
    end

    def valid_array_node?(node_type, node)
      return false if %w[OBJECT INTERFACE].include?(node_type.kind) && node.__nodes.empty?
      true
    end

    def value_type_error(is_type, should_be, for_arg)
      fail "Value is '#{is_type}', but should be '#{should_be}' for '#{for_arg}'"
    end

    def validate_value_for_type(arg_type, value, for_arg)
      case value
      when ::String
        unless arg_type.name == 'String' || arg_type.kind == 'ENUM' || arg_type.name == 'ID'
          value_type_error('String, Enum or ID', arg_type.name, for_arg)
        end
        if arg_type.kind == 'ENUM' && !arg_type.enumValues.map(&:name).include?(value)
          fail "Invalid value for Enum '#{arg_type.name}' for '#{for_arg}'"
        end
      when ::Integer
        value_type_error('Integer', arg_type.name, for_arg) unless arg_type.name == 'Int'
      when ::Float
        value_type_error('Float', arg_type.name, for_arg) unless arg_type.name == 'Float'
      when ::Hash
        validate_hash_value(arg_type, value, for_arg)
      when true, false
        value_type_error('Boolean', arg_type.name, for_arg) unless arg_type.name == 'Boolean'
      else
        value_type_error(value.class.name, arg_type.name, for_arg)
      end
    end

    def validate_hash_value(arg_type, value, for_arg)
      value_type_error('Object', arg_type.name, for_arg) unless arg_type.kind == 'INPUT_OBJECT'

      type = types.find { |f| f.name == arg_type.name }
      fail "Type not found for '#{arg_type.name}'" if type.nil?

      value.each do |k, v|
        begin
          input_field = type.fetch('inputFields', []).find { |f| f.name == k.to_s }
          fail "Input field definition not found for '#{k}'" if input_field.nil?

          input_field_type = type_for(input_field)
          fail "Input field type not found for '#{k}'" if input_field_type.nil?

          validate_value_for_type(input_field_type, v, k)
        rescue StandardError => e
          errors << e
        end
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
