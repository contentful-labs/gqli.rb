# frozen_string_literal: true

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

    def ___(fragment)
      @__nodes += __clone_nodes(fragment)
    end

    def __on(type_name, &block)
      require_relative './node'
      @__nodes << Node.new("... on #{type_name}", [], __depth + 1, &block)
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
      require_relative './node'
      @__nodes << Node.new(name.to_s, __params_from_args(args), __depth + 1, &block)
    end
  end
end
