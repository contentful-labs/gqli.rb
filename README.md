# GQLi - GraphQL Client for humans

GQLi is a DSL (Domain Specific Language) to consume GraphQL APIs.

> **DISCLAIMER:**
>
> This gem is in stable state and will be updated with more features.
> You can start using it for your respective projects, although there is no support available from Contentful.
>
> This gem is not covered under the Contentful SLAs.
>
> Users are free to create Github issues and collaborate.

## Installation

Install it via the command line:

```bash
gem install gqli
```

Or add it to your `Gemfile`:

```ruby
gem 'gqli'
```

## Usage

### Creating a GraphQL Client

For the examples throughout this README, we'll be using the Contentful, Github, and GitLab GraphQL APIs,
for which we have factory methods. Therefore, here's the initialization code required for them:

```ruby
require 'gqli'

# Creating a Contentful GraphQL Client
SPACE_ID = 'cfexampleapi'
CF_ACCESS_TOKEN = 'b4c0n73n7fu1'
CONTENTFUL_GQL = GQLi::Contentful.create(SPACE_ID, CF_ACCESS_TOKEN)

# Creating a Github GraphQL Client
GITHUB_ACCESS_TOKEN = ENV['GITHUB_TOKEN']
GITHUB_GQL = GQLi::Github.create(GITHUB_ACCESS_TOKEN)

# Creating a GitLab GraphQL Client
# As an anonymous user to GitLab.com:
GITLAB_GQL = GQLi::GitLab.create
# As an authenticated user (to GitLab.com):
GITLAB_ACCESS_TOKEN = ENV['GITLAB_TOKEN']
GITLAB_GQL = GQLi::GitLab.create(GITLAB_ACCESS_TOKEN)
# To your GitLab self-managed instance:
GITLAB_GQL = GQLi::GitLab.create(GITLAB_ACCESS_TOKEN, api: 'https://myinstance.org/api/graphql')
```

*Note*: Please feel free to contribute factories for your favorite GraphQL services.

For creating a custom GraphQL client:

```ruby
require 'gqli'

# Create a custom client
GQL_CLIENT = GQLi::Client.new(
  "https://graphql.yourservice.com",
  headers: {
    "Authorization" => "Bearer AUTH_TOKEN"
  }
)
```

### Creating a Query

Queries are the way to request data from a GraphQL API.
This gem provides a simple DSL to create your own queries.

The query operator is `GQLi::DSL.query`.

```ruby
# Query to fetch the usernames for the first 10 watchers of the first 10 repositories I belong to
WatchersQuery = GQLi::DSL.query {
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
}
```

### Divide and conquer - using Fragments

In order to reuse parts of queries, we can split chunks of our queries into Fragments.

The fragment operator is `GQLi::DSL.fragment`.

To include fragments within other nodes, use the `___` operator as shown below.

To do type matching, use the `__on` operator as shown below.

```ruby
# Base fragment that will be reused for all Cat queries.
CatBase = GQLi::DSL.fragment('CatBase', 'Cat') {
  name
  likes
  lives
}

CatBestFriend = GQLi::DSL.fragment('CatBestFriend', 'Cat') {
  bestFriend {
    # Here, because `bestFriend` is polimorphic in our GraphQL API,
    # we need to explicitly state for which Type we want to include our fragment.
    # To do a type match, instead of GraphQLs `... on SomeType` we do `__on('SomeType')`.
    __on('Cat') {
      # To include a fragment, instead of GraphQLs `...`, we use `___`.
      ___ CatBase
    }
  }
}

# A fragment reusing multiple fragments
CatImportantFields = GQLi::DSL.fragment('CatImportantFields', 'Cat') {
  ___ CatBase
  ___ CatBestFriend
}

# A fragment used to define a query, alongside other regular fields.
CatQuery = GQLi::DSL.query {
  catCollection(limit: 1) {
    items {
      ___ CatImportantFields
      image {
        url
      }
    }
  }
}
```

### Executing the queries

To execute the queries, you need to pass a `Query` object to the client's `#execute` method.
This will return a `Response` object which contains the `data` and the `query` executed.

For example:

```ruby
response = CONTENTFUL_GQL.execute(CatQuery)

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
```

The output is:

```
Query sent:
query {
  catCollection(limit: 1) {
    items {
      name
      likes
      lives
      bestFriend {
        ... on Cat {
          name
          likes
          lives
        }
      }
      image {
        url
      }
    }
  }
}

Response received
Name:    Happy Cat
Likes:   cheezburger
Lives #: 1
Best Friend:
	Name:    Nyan Cat
	Likes:   rainbows, fish
	Lives #: 1337
```

### Schema Introspection and Validation

By default this library will fetch and cache a copy of the GraphQL Schema for any API you create a client for.

This schema is used for query validation before running queries against the APIs. In case a query is invalid for the given schema, an exception will be raised.

To disable schema caching completely, when you initialize your client, send `validate_query: false`.

Queries executed using the `#execute` method on the client will be validated before executing the request if the option is set to `true` (which it is by default).

To avoid validating a query, you can use `#execute!` instead.

To validate the query outside of the scope of an HTTP request, you can use `MY_CLIENT.schema.valid?(query)`.

### Embedding the DSL in your classes

If you want to avoid the need for prepending all GQLi DSL's calls with `GQLi::DSL.`, then you can `extend` and/or `include` the module within your own classes.
When using `extend`, you will have access to the DSL at a class level. When using `include` you will have access to the DSL at an object level.

```ruby
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

  def cats(limit)
    CONTENTFUL_GQL.execute(
      query {
        catCollection(limit: limit) {
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

response = ContentfulClient.new.cats(5)
```

### Dealing with name collisions

By defining queries via a DSL, you may sometimes find that the fields you query for are also the names of built-in methods or reserved keywords of the language.

To avoid collisions you can use the `__node` helper, for example:

```ruby
query = GQLi::DSL.query {
  catCollection {
    items {
      sys {
        __node('id')
      }
    }
  }
}
```

The helper method `__node`, can also receive arguments and have children nodes as expected from any other node declaration, for example:

```ruby
query = GQLi::DSL.query {
  __node('catCollection', limit: 5) {
    items {
      name
    }
  }
}
```

### Directives

In GraphQL, nodes can be selectively included or removed by the usage of directives, there are 2 directives available for the querying specification to do this: `@include` and `@skip`.

```ruby
query = GQLi::DSL.query {
  someNode(:@include => {if: object.includes_some_node?})
}
```

This will get transformed to:

```graphql
query {
  someNode @include(if: true) # or false
}
```

This behaviour is equivalent to using native Ruby to include/exclude a field from the query:

```ruby
query = GQLi::DSL.query {
  someNode if object.includes_some_node?
}
```

The difference is that by using the native implementation, in case of the condition not being met, the node will be completely not included in the outgoing query.

### Enums

[Enums](https://graphql.org/learn/schema/#enumeration-types) are a list of predefined values that are defined on the type system level.
Since Ruby doesn't have built-in Enums that can be translated directly into GraphQL Enums, we created the `__enum` helper that you can use within your queries to transform
your values into an Enum value.

```ruby
query = GQLi::DSL.query {
  catCollection(order: __enum('lives_ASC')) {
    items {
      name
    }
  }
}
```

This will render to:

```graphql
query {
  catCollection(order: lives_ASC) {
    items {
      name
    }
  }
}
```

### Aliases

There may be times where it is useful to have parts of the query aliased, for example, when querying for `pinned` and `unpinned` articles for a news site.

This can be accomplished as follows:

```ruby
ArticleFragment = GQLi::DSL.fragment('ArticleFragment', 'ArticleCollection') {
  items {
    title
    description
    heroImage {
      url
    }
  }
}

query = GQLi::DSL.query {
  __node('pinned: articleCollection', where: {
    sys: { id_in: ['articleID'] }
  }) {
    ___ ArticleFragment
  }
  __node('unpinned: articleCollection', where: {
    sys: { id_not_in: ['articleID'] }
  }) {
    ___ ArticleFragment
  }
}
```

## Get involved

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?maxAge=31557600)](http://makeapullrequest.com)

We appreciate any help on our repositories.

## License

This repository is published under the [MIT](LICENSE.txt) license.

## Code of Conduct

We want to provide a safe, inclusive, welcoming, and harassment-free space and experience for all participants, regardless of gender identity and expression, sexual orientation, disability, physical appearance, socioeconomic status, body size, ethnicity, nationality, level of experience, age, religion (or lack thereof), or other identity markers.

[Read our full Code of Conduct](https://github.com/contentful-developer-relations/community-code-of-conduct).
