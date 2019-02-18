require 'spec_helper'

describe GQLi::Client do
  let(:space_id) { 'cfexampleapi' }
  let(:token) { 'b4c0n73n7fu1' }

  let(:client) do
    vcr('client') {
      GQLi::Contentful.create(space_id, token)
    }
  end

  let(:client_no_validations) do
    vcr('client') {
      GQLi::Contentful.create(
        space_id,
        token,
        validate_query: false
      )
    }
  end

  let(:dsl) { GQLi::DSL }

  describe 'default clients' do
    it 'contentful client' do
      expect(client).to be_a(GQLi::Client)
    end

    it 'github client' do
      client = GQLi::Github.create('foobar', validate_query: false)

      expect(client).to be_a(GQLi::Client)
    end
  end

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
