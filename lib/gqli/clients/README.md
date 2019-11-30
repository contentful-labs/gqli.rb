
## Example using the Shopify client


```ruby
require 'gqli'

shop = OpenStruct.new(name: "shop1", token: "abc123")

# Create a shop specific api client based on token
GQLi::Shopify.create(shop.name, shop.token) do |api|

	# Get shop info.
	request = Shopify::GQL.shop
	response = api.execute(request)
	puts response.data.shop.to_hash

	# Get some products
	request = Shopify::GQL.products(first: 4, query: "title:*")
	response = api.execute(request)
	response.data.products.edges.each do |edge| 
		edge["node"].tap do |n| 
			puts "id: %s, title: %s" % [ n.id, n.title]
		end
	end

end
```
