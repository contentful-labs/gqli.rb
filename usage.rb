require_relative './lib/gqli'

puts GQLi::DSL.query {
  __on('Foo') {
    bar
  }
}.to_gql


puts GQLi::DSL.query {
  viewer {
    login
    repositories(first: 10) {
      edges {
        node {
          nameWithOwner
          watchers(first: 10) {
            edges {
              node {
                login
              }
            }
          }
        }
      }
    }
  }
}.to_gql

FragmentFoo = GQLi::DSL.fragment('Foo', 'Bar') {
  foo
  bar(b: 10)
  baz {
    qux(c: 3)
  }
}

puts FragmentFoo.to_gql

puts GQLi::DSL.query {
  ___ FragmentFoo
}.to_gql

puts "-------------"

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
  puts "Name:    #{c.name}"
  puts "Likes:   #{c.likes.join(", ")}"
  puts "Lives #: #{c.lives}"
  c.bestFriend.tap do |bf|
    puts "Best Friend:"
    puts "\tName:    #{bf.name}"
    puts "\tLikes:   #{bf.likes.join(", ")}"
    puts "\tLives #: #{bf.lives}"
  end
end
