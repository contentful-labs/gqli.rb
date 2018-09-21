require 'hashie/mash'

module GQLi
  class Response
    attr_reader :data, :query

    def initialize(data, query)
      @data = Hashie::Mash.new(data)
      @query = query
    end
  end
end
