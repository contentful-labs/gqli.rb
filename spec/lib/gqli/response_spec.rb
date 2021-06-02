require 'spec_helper'

describe GQLi::Response do
  let(:errors) { nil }
  let(:data) { {"testkey" => "test val"} }
  let(:query) { double(:query) }
  subject { described_class.new(data, errors, query) }

  describe "#data" do
    it "returns correct data Hashie" do
      expect(subject.data).to be_kind_of(Hashie::Mash)
      expect(subject.data.testkey).to eq(data["testkey"])
    end
  end

  describe "#query" do
    it "returns correct query" do
      expect(subject.query).to eq(query)
    end
  end

  describe "#errors" do
    context "array errors" do
      let(:errors) { [{"message" => "this is an error"}] }

      it "converts errors to correct Hashie instances" do
        expect(subject.errors).to be_kind_of(Array)
        expect(subject.errors.length).to eq(1)
        expect(subject.errors.first).to be_kind_of(Hashie::Mash)
        expect(subject.errors.first.message).to eq(errors.first["message"])
      end
    end

    context "hash errors" do
      let(:errors) { {"message" => "this is an error"} }

      it "converts errors to correct Hashie instances" do
        expect(subject.errors).to be_kind_of(Hashie::Mash)
        expect(subject.errors.message).to eq(errors["message"])
      end
    end

    context "nil errors" do
      it "does not raise error and returns nil" do
        expect(subject.errors).to be(nil)
      end
    end

  end

end