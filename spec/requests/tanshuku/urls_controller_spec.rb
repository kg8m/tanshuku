# frozen_string_literal: true

RSpec.describe Tanshuku::UrlsController do
  describe "#show" do
    context "when there are no Tanshuku::Url records and an unknown key is given" do
      let(:unknown_key) { "unknownkey0123456789" }

      before do
        expect(Tanshuku::Url).not_to exist
      end

      it "responds with status code 404" do
        get "/t/#{unknown_key}"
        expect(response).to have_attributes(status: 404)
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
        it "responds with status code 404" do
          get "/t/#{unknown_key}"
          expect(response).to have_attributes(status: 404)
        end
      end

      context "and a known key is given" do
        it "redirects to the key’s original URL with status code 301" do
          get "/t/#{known_key}"
          expect(response).to redirect_to url1.url
          expect(response).to have_attributes(status: 301)
        end
      end

      context "and a known key with an extension is given" do
        it "redirects to the key’s original URL with status code 301" do
          get "/t/#{known_key}.json"
          expect(response).to redirect_to url1.url
          expect(response).to have_attributes(status: 301)
        end
      end
    end

    # Keys can contain characters other than dots because they are escaped in shortened URLs and unescaped by the
    # routing. Dots aren’t escaped and are treated as separators of the format.
    context "when a Tanshuku::Url record has a key containing special characters" do
      ["a/b", "a?b", "a#b", "a%b", "a b", "a-b_c~d"].each do |special_key|
        context "and the key is #{special_key.inspect}" do
          let!(:url) { Tanshuku::Url.create!(url: "https://google.com/", hashed_url: "hashed", key: special_key) }

          it "redirects to the key’s original URL with status code 301 via the shortened URL" do
            get url.shortened_url
            expect(response).to redirect_to url.url
            expect(response).to have_attributes(status: 301)
          end
        end
      end
    end
  end
end
