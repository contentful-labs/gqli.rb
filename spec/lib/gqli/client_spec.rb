require 'spec_helper'

describe GQLi::Client do
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

  let(:client_no_validations) do
    vcr('client') {
      space_id = 'cfexampleapi'
      token = 'b4c0n73n7fu1'
      GQLi::Client.new(
        "https://graphql.contentful.com/content/v1/spaces/#{space_id}",
        headers: { "Authorization" => "Bearer #{token}" },
        validate_query: false
      )
    }
  end

  let(:dsl) { GQLi::DSL }

  describe 'query can call the client to execute' do
    subject { client }

    it '#__execute' do
      vcr('catCollection') {
        expect(
          dsl.query {
            catCollection {
              items {
                name
              }
            }
          }.__execute(subject).data
        ).not_to be_empty
      }
    end
  end

  context 'validations enabled' do
    subject { client }

    it 'upon instantiation caches the schema' do
      expect(subject.schema.types).not_to be_empty
    end

    it 'when executing a query performs schema validation' do
      vcr('catCollection') {
        expect(subject.execute(
          dsl.query {
            catCollection {
              items {
                name
              }
            }
          }).data
        ).not_to be_empty

        expect { subject.execute(
          dsl.query {
            foobar
          }
        )}.to raise_exception <<~ERROR
          Validation Error: query is invalid - HTTP Request not sent.

          Errors:
            - Node type not found for 'foobar'
        ERROR
      }
    end

    it 'can skip validations when using `#execute!`' do
      vcr('validation_error') {
        expect { subject.execute!(
          dsl.query {
            foobar
          }
        )}.to raise_exception([
          "Error: Bad Request",
          'Body: {"errors":[{"message":"Cannot query field \"foobar\" on type \"Query\".","locations":[{"line":2,"column":3}]}]}'
        ].join("\n"))
      }
    end
  end

  context 'validations disabled' do
    subject { client_no_validations }

    it 'upon instantiation doesnt cache the schema' do
      expect(subject.schema).to be_nil
    end

    it 'when executing a query doesnt perform schema validation' do
      vcr('validation_error') {
        expect { subject.execute(
          dsl.query {
            foobar
          }
        )}.to raise_exception([
          "Error: Bad Request",
          'Body: {"errors":[{"message":"Cannot query field \"foobar\" on type \"Query\".","locations":[{"line":2,"column":3}]}]}'
        ].join("\n"))
      }
    end
  end
end
