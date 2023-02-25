# frozen_string_literal: true

RSpec.describe "locales: en" do
  around do |example|
    I18n.with_locale(:en, &example)
  end

  describe "Tanshuku::Url model name" do
    subject { Tanshuku::Url.model_name.human }

    it { is_expected.to eq "Shortened URL" }
  end

  describe "Tanshuku::Url attributes" do
    describe "url" do
      subject { Tanshuku::Url.human_attribute_name(:url) }

      it { is_expected.to eq "URL" }
    end

    describe "hashed_url" do
      subject { Tanshuku::Url.human_attribute_name(:hashed_url) }

      it { is_expected.to eq "hashed URL" }
    end

    describe "key" do
      subject { Tanshuku::Url.human_attribute_name(:key) }

      it { is_expected.to eq "unique key" }
    end
  end

  describe "Tanshuku::Url errors" do
    let(:tanshuku_url) { Tanshuku::Url.new }

    describe "url.invalid" do
      before do
        tanshuku_url.errors.add(:url, :invalid)
      end

      it "uses a custom error message" do
        expect(tanshuku_url.errors.full_messages_for(:url)).to eq ["URL should start with https://, http://, or /"]
      end
    end
  end
end
