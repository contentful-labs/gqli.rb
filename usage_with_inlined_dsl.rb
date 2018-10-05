require_relative './lib/gqli'

class ContentfulClient
  extend GQLi::DSL # Makes DSL available at a class level
  include GQLi::DSL # Makes DSL available at an object level

  SPACE_ID = 'cfexampleapi'
  ACCESS_TOKEN = 'b4c0n73n7fu1'
  CONTENTFUL_GQL = GQLi::Client.new(
    "https://graphql.contentful.com/content/v1/spaces/#{SPACE_ID}",
    headers: { "Authorization" => "Bearer #{ACCESS_TOKEN}" }
  )

  CatBase = fragment('CatBase', 'Cat') {
    name
    likes
    lives
  }

  CatBestFriend = fragment('CatBestFriend', 'Cat') {
    bestFriend {
      __on('Cat') {
        ___ CatBase
      }
    }
  }

  CatImportantFields = fragment('CatImportantFields', 'Cat') {
    ___ CatBase
    ___ CatBestFriend
  }

  def cats
    CONTENTFUL_GQL.execute(
      query {
        catCollection(limit: 10, locale: 'tlh') {
          items {
            ___ CatImportantFields
            image {
              url
            }
          }
        }
      }
    )
  end
end

response = ContentfulClient.new.cats

puts "Query sent:"
puts response.query.to_gql

puts
puts "Response received"
response.data.catCollection.items.each do |c|
  puts "Name:    #{c.name}"
  puts "Likes:   #{c.likes.join(", ")}"
  puts "Lives #: #{c.lives}"
  puts "Image:   #{c.image.url}" if c.image?
  c.bestFriend.tap do |bf|
    next if bf.nil?
    puts "Best Friend:"
    puts "\tName:    #{bf.name}"
    puts "\tLikes:   #{bf.likes.join(", ")}"
    puts "\tLives #: #{bf.lives}"
  end
  puts
end
