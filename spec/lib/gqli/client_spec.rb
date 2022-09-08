require 'spec_helper'

describe GQLi::Client do
  let(:space_id) { 'cfexampleapi' }
  let(:token) { 'b4c0n73n7fu1' }
  let(:default_timeout) { 60 }
  let(:timeout) { 10 }

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

  let(:client_with_timeout) do
    vcr('client') {
      GQLi::Contentful.create(
        space_id,
        token,
        validate_query: false,
        options: {
          connect_timeout: timeout,
          read_timeout: timeout,
          write_timeout: timeout
        }
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

    describe 'gitlab client' do
      it 'can build a client without Authorization headers' do
        client = GQLi::GitLab.create(validate_query: false)

        expect(client).to be_a(GQLi::Client)
        expect(client.headers).to be_empty
        expect(client.url).to eq('https://gitlab.com/api/graphql')
      end

      it 'can build a client with Authorization headers' do
        client = GQLi::GitLab.create('foobar', validate_query: false)

        expect(client).to be_a(GQLi::Client)
        expect(client.headers).to eq({'Authorization' => 'Bearer foobar'})
        expect(client.url).to eq('https://gitlab.com/api/graphql')
      end

      it 'can build a client to a self-managed GitLab instance' do
        client = GQLi::GitLab.create(api: 'https://foo.com', validate_query: false)

        expect(client).to be_a(GQLi::Client)
        expect(client.headers).to be_empty
        expect(client.url).to eq('https://foo.com')
      end
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

  context 'without timeout options' do
    subject { client }

    it 'upon instantiation sets default timeout value' do
      expect(subject.options[:read_timeout]).to eq(default_timeout)
      expect(subject.options[:connect_timeout]).to eq(default_timeout)
      expect(subject.options[:write_timeout]).to eq(default_timeout)
    end

    it 'when executing a request sets default timeout value' do
      expect(subject.request.default_options.timeout_options[:read_timeout]).to eq(default_timeout)
      expect(subject.request.default_options.timeout_options[:connect_timeout]).to eq(default_timeout)
      expect(subject.request.default_options.timeout_options[:write_timeout]).to eq(default_timeout)
    end
  end

  context 'with timeout options' do
    subject { client_with_timeout }

    it 'contentful client' do
      expect(subject).to be_a(GQLi::Client)
    end

    it 'upon instantiation sets provided timeout value' do
      expect(subject.options[:read_timeout]).to eq(timeout)
      expect(subject.options[:connect_timeout]).to eq(timeout)
      expect(subject.options[:write_timeout]).to eq(timeout)
    end

    it 'when executing a request sets provided timeout value' do
      expect(subject.request.default_options.timeout_options[:read_timeout]).to eq(timeout)
      expect(subject.request.default_options.timeout_options[:connect_timeout]).to eq(timeout)
      expect(subject.request.default_options.timeout_options[:write_timeout]).to eq(timeout)
    end
  end
end
