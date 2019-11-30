# frozen_string_literal: true

module GQLi
  # Module for creating a Shopify GraphQL client
  module Shopify
    # Creates a Shopify GraphQL client. This is shop specific.
    # shop_name: Shop name as a String
    # access_token: Access_token granted by the shop as part of oauth2 callback process
    # version (optional): String of "YYYY-MM"
    # validate_query:
    def self.create(shop_name, access_token, version: '2019-10', validate_query: false, &block)
      api_url = "https://%s/admin/api/%s/graphql.json" % [shop_name, version]

      cli = GQLi::Client.new(
        api_url,
        headers: {
          'X-Shopify-Access-Token' => access_token
        },
        validate_query: validate_query
      )
      if block_given?
        yield cli 
      else
        cli
      end
    end
  end
end

# Common requests 
module Shopify
  module GQL
  class << self
  
  # Get shop details
  def shop
      GQLi::DSL.query{
      shop { id
      name
      description
      email 
          plan { displayName }
          alerts { description }
      }
  }
  end # shop
  
  # Get simple product info
  def products(first:, query:)
      GQLi::DSL.query{
          products(first: first, query: query) {
              edges {
                  node {
                      productType
                      title
                      id
                  }
              }
          }
      }
  end # product
  end # class
  end # module GQL
  end # Shopify
  