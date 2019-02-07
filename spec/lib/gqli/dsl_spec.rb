require 'spec_helper'

class MockGQLInterface
  include GQLi::DSL
end

describe GQLi::DSL do
  subject { described_class }

  describe 'module level methods' do
    describe '::query' do
      it 'can create a query without name' do
        query = subject.query {
          someField
        }

        expect(query).to be_a GQLi::Query
        expect(query.to_gql).to eq <<~GRAPHQL
          query {
            someField
          }
        GRAPHQL
        expect(query.to_gql).to eq query.to_s
      end

      it 'can create a query with a name' do
        query = subject.query('FooBar') {
          someOtherField
        }

        expect(query).to be_a GQLi::Query
        expect(query.to_gql).to eq <<~GRAPHQL
          query FooBar {
            someOtherField
          }
        GRAPHQL
      end
    end

    describe '::subscription' do
      it 'can create a subscription without name' do
        subscription = subject.subscription {
          someField
        }

        expect(subscription).to be_a GQLi::Subscription
        expect(subscription.to_gql).to eq <<~GRAPHQL
          subscription {
            someField
          }
        GRAPHQL
        expect(subscription.to_gql).to eq subscription.to_s
      end

      it 'can create a subscription with a name' do
        subscription = subject.subscription('FooBar') {
          someOtherField
        }

        expect(subscription).to be_a GQLi::Subscription
        expect(subscription.to_gql).to eq <<~GRAPHQL
          subscription FooBar {
            someOtherField
          }
        GRAPHQL
      end
    end

    describe '::fragment' do
      it 'can create a fragment' do
        fragment = subject.fragment('FooBar', 'Foo') {
          someFooField
        }

        expect(fragment).to be_a GQLi::Fragment
        expect(fragment.to_gql).to eq <<~GRAPHQL
          fragment FooBar on Foo {
            someFooField
          }
        GRAPHQL
      end
    end

    describe '::enum' do
      it 'can create an enum value' do
        enum_value = subject.enum('foo')

        expect(enum_value).to be_a GQLi::EnumValue
        expect(enum_value.to_s).to eq 'foo'
      end
    end
  end

  describe 'instance level methods' do
    subject { MockGQLInterface.new }

    describe '#query does the same as ::query' do
      it 'can create a query without name' do
        query = subject.query {
          someField
        }

        expect(query).to be_a GQLi::Query
        expect(query.to_gql).to eq <<~GRAPHQL
          query {
            someField
          }
        GRAPHQL
      end

      it 'can create a query with a name' do
        query = subject.query('FooBar') {
          someOtherField
        }

        expect(query).to be_a GQLi::Query
        expect(query.to_gql).to eq <<~GRAPHQL
          query FooBar {
            someOtherField
          }
        GRAPHQL
      end
    end


    describe '#subscription does the same as ::subscription' do

      subject { MockGQLInterface.new }

      it 'can create a subscription without name' do
        subscription = subject.subscription {
          someField
        }

        expect(subscription).to be_a GQLi::Subscription
        expect(subscription.to_gql).to eq <<~GRAPHQL
          subscription {
            someField
          }
        GRAPHQL
        expect(subscription.to_gql).to eq subscription.to_s
      end

      it 'can create a subscription with a name' do
        subscription = subject.subscription('FooBar') {
          someOtherField
        }

        expect(subscription).to be_a GQLi::Subscription
        expect(subscription.to_gql).to eq <<~GRAPHQL
          subscription FooBar {
            someOtherField
          }
        GRAPHQL
      end
    end

    describe '#fragment does the same as ::fragment' do
      it 'can create a fragment' do
        fragment = subject.fragment('FooBar', 'Foo') {
          someFooField
        }

        expect(fragment).to be_a GQLi::Fragment
        expect(fragment.to_gql).to eq <<~GRAPHQL
          fragment FooBar on Foo {
            someFooField
          }
        GRAPHQL
      end
    end

    describe '#enum does the same as ::enum' do
      it 'can create an enum value' do
        enum_value = subject.enum('foo')

        expect(enum_value).to be_a GQLi::EnumValue
        expect(enum_value.to_s).to eq 'foo'
      end
    end
  end

  describe 'node DSL' do
    it 'nodes can have arguments' do
      query = subject.query {
        someNode(arg1: 100)
        otherNode(arg2: 'some_string')
        moreNodes(arg3: { nestedArg: [1, 2] })
      }

      expect(query.to_gql).to eq <<~GRAPHQL
        query {
          someNode(arg1: 100)
          otherNode(arg2: "some_string")
          moreNodes(arg3: {nestedArg: [1, 2]})
        }
      GRAPHQL
    end

    it 'nodes can have directives' do
      query = subject.query {
        someNode(:@include => { if: true })
        otherNode(:@skip => { if: false })
      }

      expect(query.to_gql).to eq <<~GRAPHQL
        query {
          someNode @include(if: true)
          otherNode @skip(if: false)
        }
      GRAPHQL
    end

    it 'nodes can have arbitrarily nested nodes' do
      query = subject.query {
        aNode {
          withChild {
            moreChildren
            andASibiling(someParameterHere: 'just for fun') {
              withEvenMore
            }
          }
          alsoASibiling
        }
        withoutChild
      }

      expect(query.to_gql).to eq <<~GRAPHQL
        query {
          aNode {
            withChild {
              moreChildren
              andASibiling(someParameterHere: "just for fun") {
                withEvenMore
              }
            }
            alsoASibiling
          }
          withoutChild
        }
      GRAPHQL
    end

    it 'queries can have inlined fragments at any level' do
      NameFragment = subject.fragment('NameFragment', 'Foo') {
        name
      }

      AgeFragment = subject.fragment('AgeFragment', 'Foo') {
        age
      }

      query = subject.query {
        peopleCollection {
          ___ NameFragment
          ___ AgeFragment
        }
      }

      expect(query.to_gql).to eq <<~GRAPHQL
        query {
          peopleCollection {
            name
            age
          }
        }
      GRAPHQL
    end

    it 'queries can have type matchers' do
      query = subject.query {
        catCollection {
          items {
            name
            bestFriend {
              __on('Cat') {
                name
              }
            }
          }
        }
      }

      expect(query.to_gql).to eq <<~GRAPHQL
        query {
          catCollection {
            items {
              name
              bestFriend {
                ... on Cat {
                  name
                }
              }
            }
          }
        }
      GRAPHQL
    end

    it 'can use __node to define nodes that would collide otherwise' do
      query = subject.query {
        catCollection {
          items {
            sys {
              __node('id')
            }
          }
        }
      }

      expect(query.to_gql).to eq <<~GRAPHQL
        query {
          catCollection {
            items {
              sys {
                id
              }
            }
          }
        }
      GRAPHQL
    end

    it '__node can receive arguments and children nodes' do
      query = subject.query {
        __node('catCollection', limit: 1) {
          items {
            name
          }
        }
      }

      expect(query.to_gql).to eq <<~GRAPHQL
        query {
          catCollection(limit: 1) {
            items {
              name
            }
          }
        }
      GRAPHQL
    end

    it '__enum can create EnumType values' do
      query = subject.query {
        catCollection(order: __enum('lives_ASC')) {
          items {
            name
          }
        }
      }

      expect(query.to_gql).to eq <<~GRAPHQL
        query {
          catCollection(order: lives_ASC) {
            items {
              name
            }
          }
        }
      GRAPHQL
    end
  end
end
