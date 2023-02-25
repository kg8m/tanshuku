# frozen_string_literal: true

RSpec.describe Tanshuku::UrlsController do
  describe "#show" do
    context "when there are no Tanshuku::Url records and an unknown key is given" do
      let(:unknown_key) { "unknownkey0123456789" }

      before do
        expect(Tanshuku::Url).not_to exist
      end

      it "raises ActiveRecord::RecordNotFound" do
        expect { get "/t/#{unknown_key}" }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when there are some Tanshuku::Url records" do
      let!(:url1) { shorten_and_find_record("https://google.com/?foo=1") }
      let!(:url2) { shorten_and_find_record("https://google.com/?bar=1") }
      let!(:url3) { shorten_and_find_record("https://google.com/?baz=1") }

      let(:all_urls) { [url1, url2, url3] }

      let(:known_key)   { url1.key               }
      let(:unknown_key) { "unknownkey0123456789" }

      before do
        expect(Tanshuku::Url).to have_attributes(count: all_urls.size)
        expect(Tanshuku::Url.where(key: unknown_key)).not_to exist
      end

      context "and an unknown key is given" do
        it "raises ActiveRecord::RecordNotFound" do
          expect { get "/t/#{unknown_key}" }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "and a known key is given" do
        it "redirects to the key's original URL with status code 301" do
          get "/t/#{known_key}"
          expect(response).to redirect_to url1.url
          expect(response).to have_attributes(status: 301)
        end
      end
    end
  end
end
