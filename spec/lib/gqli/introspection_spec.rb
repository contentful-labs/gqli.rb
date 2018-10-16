require 'spec_helper'

describe GQLi::Introspection do
  let(:dsl) { GQLi::DSL }
  let(:client) do
    vcr('client') {
      space_id = 'cfexampleapi'
      token = 'b4c0n73n7fu1'
      GQLi::Client.new(
        "https://graphql.contentful.com/content/v1/spaces/#{space_id}",
        headers: { "Authorization" => "Bearer #{token}" }
      )
    }
  end

  subject { client.schema }

  describe 'introspection schema' do
    it 'queries the API for the schema' do
      expect(subject.types).not_to be_empty

      expect(subject.types.map(&:name)).to include('Cat', 'CatCollection', 'Human')
    end
  end

  describe 'validations' do
    it 'valid query returns true' do
      query = dsl.query {
        catCollection(
          locale:"en-US",
          limit: 1,
          where: {
            name:"Nyan Cat",
            OR: {
              name:"Happy Cat"
            }
          }
        ) {
          items {
            name
            color
            birthday
            lives
            bestFriend {
              __on('Cat') {
                name
              }
            }
            image {
              url
            }
          }
        }
      }

      expect(subject.valid?(query)).to be_truthy
    end

    it 'wrong node returns false' do
      query = dsl.query {
        foo
      }

      expect(subject.valid?(query)).to be_falsey
    end

    it 'object node that doesnt have proper values returns false' do
      query = dsl.query {
        catCollection
      }

      expect(subject.valid?(query)).to be_falsey
    end

    it 'object list node that doesnt have proper values returns false' do
      query = dsl.query {
        catCollection {
          items
        }
      }

      expect(subject.valid?(query)).to be_falsey
    end

    it 'type matching on invalid type returns false' do
      query = dsl.query {
        catCollection {
          items {
            bestFriend {
              __on('InvalidType') {
                foo
              }
            }
          }
        }
      }

      expect(subject.valid?(query)).to be_falsey
    end

    it 'invalid arguments return false' do
      query = dsl.query {
        catCollection(invalidParam: 1) {
          items {
            name
          }
        }
      }

      expect(subject.valid?(query)).to be_falsey
    end

    it 'invalid argument type returns false' do
      query = dsl.query {
        catCollection(limit: 'foo') {
          items {
            name
          }
        }
      }

      expect(subject.valid?(query)).to be_falsey
    end
  end
end