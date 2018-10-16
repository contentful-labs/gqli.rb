require_relative './lib/gqli'

SPACE_ID = 'cfexampleapi'
ACCESS_TOKEN = 'b4c0n73n7fu1'
CONTENTFUL_GQL = GQLi::Client.new(
  "https://graphql.contentful.com/content/v1/spaces/#{SPACE_ID}",
  headers: { "Authorization" => "Bearer #{ACCESS_TOKEN}" }
)

CatBase = GQLi::DSL.fragment('CatBase', 'Cat') {
  name
  likes
  lives
}

CatBestFriend = GQLi::DSL.fragment('CatBestFriend', 'Cat') {
  bestFriend {
    __on('Cat') {
      ___ CatBase
    }
  }
}

CatImportantFields = GQLi::DSL.fragment('CatImportantFields', 'Cat') {
  ___ CatBase
  ___ CatBestFriend
}

Query = GQLi::DSL.query {
  catCollection(limit: 1) {
    items {
      ___ CatImportantFields
      image {
        url
      }
    }
  }
}

response = CONTENTFUL_GQL.execute(Query)

puts "Query sent:"
puts response.query.to_gql

puts
puts "Response received"
response.data.catCollection.items.each do |c|
  puts "Name:    #{c.nam}e"
  puts "Likes:   #{c.likes.join(", ")}"
  puts "Lives #: #{c.lives}"
  c.bestFriend.tap do |bf|
    puts "Best Friend:"
    puts "\tName:    #{bf.name}"
    puts "\tLikes:   #{bf.likes.join(", ")}"
    puts "\tLives #: #{bf.lives}"
  end
end

puts "Trying to execute invalid query"

CONTENTFUL_GQL.execute!(GQLi::DSL.query {
  invalidNode
})
