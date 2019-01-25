# frozen_string_literal: true

require_relative './enum_value'

module GQLi
  # Base class for GraphQL type wrappers
  class Base
    attr_reader :__name, :__depth, :__nodes

    def initialize(name = nil, depth = 0, &block)
      @__name = name
      @__depth = depth
      @__nodes = []
      instance_eval(&block) unless block.nil?
    end

    # Inlines fragment nodes into current node
    def ___(fragment)
      @__nodes += __clone_nodes(fragment)
    end

    # Adds type match node
    def __on(type_name, &block)
      __node("... on #{type_name}", {}, &block)
    end

    # Adds children node into current node
    def __node(name, params = {}, &block)
      require_relative './node'
      @__nodes << Node.new(name, params, __depth + 1, &block)
    end

    # Creates an EnumType value
    def __enum(value)
      EnumValue.new(value)
    end

    protected

    def __clone_nodes(node_container)
      require_relative './node'
      __clone(node_container.__nodes).map do |n|
        node = Node.new(n.__name, n.__params, __depth + 1)
        node.instance_variable_set(
          :@__nodes,
          node.send(:__clone_nodes, n)
        )
        node
      end
    end

    def __clone(obj)
      Marshal.load(Marshal.dump(obj))
    end

    def __params_from_args(args)
      args.empty? ? {} : args[0]
    end

    def method_missing(name, *args, &block)
      __node(name.to_s, __params_from_args(args), &block)
    end
  end
end
