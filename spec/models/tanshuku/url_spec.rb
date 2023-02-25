# frozen_string_literal: true

RSpec.describe Tanshuku::Url do
  describe "validations" do
    let!(:record) { Tanshuku::Url.new(valid_attrs) }

    describe "url format" do
      before do
        record.url = url
      end

      ["https://google.com/", "http://google.com", "/", "/path"].each do |valid_url_string|
        context "when url is #{valid_url_string.inspect}" do
          let(:url) { valid_url_string }

          it "is valid" do
            expect(record).to be_valid
          end
        end
      end

      [
        "https",
        "https:",
        "https:/",
        "https://",
        "http",
        "http:",
        "http:/",
        "http://",
        "invalid",
      ].each do |invalid_url_string|
        context "when url is #{invalid_url_string.inspect}" do
          let(:url) { invalid_url_string }

          it "is invalid" do
            expect(record).to be_invalid
            expect(record.errors).to be_of_kind :url, :invalid
          end
        end
      end
    end
  end

  describe ".shorten" do
    let(:reported_exceptions) { [] }

    before do
      allow(Tanshuku::Url).to receive(:report_exception).and_wrap_original do |original_method, exception:, original_url:|
        reported_exceptions << exception
        original_method.call(exception:, original_url:)
      end
    end

    context "when original_url is nil" do
      let(:original_url) { nil }

      it "doesn't create any Tanshuku::Url record, reports ArgumentError, and returns the original_url" do
        result =
          assert_no_difference -> { Tanshuku::Url.count } do
            Tanshuku::Url.shorten(original_url)
          end
        expect(result).to eq original_url

        expect(reported_exceptions).to have_attributes(size: 1)
        expect(reported_exceptions[0]).to be_a ArgumentError
      end
    end

    context "when original_url is an empty string" do
      let(:original_url) { "" }

      it "doesn't create any Tanshuku::Url record, reports ActiveRecord::RecordInvalid, and returns the original_url" do
        result =
          assert_no_difference -> { Tanshuku::Url.count } do
            Tanshuku::Url.shorten(original_url)
          end
        expect(result).to eq original_url

        expect(reported_exceptions).to have_attributes(size: 1)
        expect(reported_exceptions[0]).to be_a ActiveRecord::RecordInvalid
        expect(reported_exceptions[0].record.errors).to be_of_kind :url, :blank
      end
    end

    context "when original_url is a non-URL string" do
      let(:original_url) { "invalid" }

      it "doesn't create any Tanshuku::Url record, reports ActiveRecord::RecordInvalid, and returns the original_url" do
        result =
          assert_no_difference -> { Tanshuku::Url.count } do
            Tanshuku::Url.shorten(original_url)
          end
        expect(result).to eq original_url

        expect(reported_exceptions).to have_attributes(size: 1)
        expect(reported_exceptions[0]).to be_a ActiveRecord::RecordInvalid
        expect(reported_exceptions[0].record.errors).to be_of_kind :url, :invalid
      end
    end

    ["https://google.com/", "http://google.com/", "/", "/path"].each do |valid_original_url|
      let(:original_url) { valid_original_url }

      it "creates a new Tanshuku::Url record, doesn't report any exceptions, and returns a shortened URL string" do
        result =
          assert_difference -> { Tanshuku::Url.count }, 1 do
            Tanshuku::Url.shorten(original_url)
          end
        expect(result).not_to eq original_url
        expect(result).to match SpecUtilities::SHORTENED_URL_PATTERN

        expect(reported_exceptions).to be_empty

        created = Tanshuku::Url.last
        expect(created.url).to eq original_url
        expect(created.hashed_url).to match(/\A\w{128}\z/)
        expect(created.key).to match(/\A\w{20}\z/)
      end
    end

    context "when called multiple times for the same URL" do
      let(:original_url) { "https://google.com/" }

      it "creates only 1 Tanshuku::Url record, doesn't report any exceptions, and returns same shortened URL string every time" do
        result1 =
          assert_difference -> { Tanshuku::Url.count }, 1 do
            Tanshuku::Url.shorten(original_url)
          end
        result2 =
          assert_no_difference -> { Tanshuku::Url.count } do
            Tanshuku::Url.shorten(original_url)
          end
        result3 =
          assert_no_difference -> { Tanshuku::Url.count } do
            Tanshuku::Url.shorten(original_url)
          end

        expect(reported_exceptions).to be_empty

        created = Tanshuku::Url.last
        expect(created.url).to eq original_url
        expect(created.hashed_url).to match(/\A\w{128}\z/)
        expect(created.key).to match(/\A\w{20}\z/)

        expect(result1).to eq created.shortened_url
        expect(result2).to eq created.shortened_url
        expect(result3).to eq created.shortened_url
      end
    end

    context "when original_urls are essentially same" do
      let(:original_url1) { "https://google.com/" }
      let(:original_url2) { "https://google.com"   }
      let(:original_url3) { "https://google.com/?" }
      let(:original_url4) { "https://google.com?"  }

      it "creates only 1 Tanshuku::Url record with a normalized URL" do
        result1 =
          assert_difference -> { Tanshuku::Url.count }, 1 do
            Tanshuku::Url.shorten(original_url1)
          end
        result2 =
          assert_no_difference -> { Tanshuku::Url.count } do
            Tanshuku::Url.shorten(original_url2)
          end
        result3 =
          assert_no_difference -> { Tanshuku::Url.count } do
            Tanshuku::Url.shorten(original_url3)
          end
        result4 =
          assert_no_difference -> { Tanshuku::Url.count } do
            Tanshuku::Url.shorten(original_url4)
          end

        expect(reported_exceptions).to be_empty

        created = Tanshuku::Url.last
        expect(created.url).to eq original_url1
        expect(created.hashed_url).to match(/\A\w{128}\z/)
        expect(created.key).to match(/\A\w{20}\z/)

        expect(result1).to eq created.shortened_url
        expect(result2).to eq created.shortened_url
        expect(result3).to eq created.shortened_url
        expect(result4).to eq created.shortened_url
      end
    end

    context "when generated key is duplicated" do
      let!(:existing) { Tanshuku::Url.create!(valid_attrs.merge(key: "abcdefghij0123456789")) }

      let(:original_url) { "#{existing.url}_" }

      context "some times" do
        let(:forced_retries_count) { 3 }

        before do
          actual_retries_count = 0
          allow(Tanshuku::Url).to receive(:generate_key).and_wrap_original do |original_method|
            actual_retries_count += 1
            actual_retries_count < forced_retries_count ? existing.key : original_method.call
          end

          expect(Tanshuku::Url).not_to have_received(:generate_key)
        end

        it "retries generating an other key, so creates a new Tanshuku::Url record, doesn't report any exceptions, and returns a shortened URL string" do
          result =
            assert_difference -> { Tanshuku::Url.count }, 1 do
              Tanshuku::Url.shorten(original_url)
            end
          expect(result).not_to eq original_url
          expect(result).to match SpecUtilities::SHORTENED_URL_PATTERN

          expect(reported_exceptions).to be_empty

          created = Tanshuku::Url.last
          expect(created.url).to eq original_url
          expect(created.hashed_url).to match(/\A\w{128}\z/)
          expect(created.key).to match(/\A\w{20}\z/)

          expect(Tanshuku::Url).to have_received(:generate_key).exactly(forced_retries_count).times
        end
      end

      context "too many times" do
        before do
          allow(Tanshuku::Url).to receive(:generate_key).and_return(existing.key)
          expect(Tanshuku::Url).not_to have_received(:generate_key)
        end

        it "retries generating an other key but finally raises ActiveRecord::RecordNotUnique, so doesn't create any Tanshuku::Url record, reports ActiveRecord::RecordInvalid, and returns the original_url" do
          result =
            assert_no_difference -> { Tanshuku::Url.count } do
              Tanshuku::Url.shorten(original_url)
            end
          expect(result).to eq original_url

          expect(reported_exceptions).to have_attributes(size: 1)
          expect(reported_exceptions[0]).to be_a ActiveRecord::RecordNotFound
        end
      end
    end

    context "when a new record is created but an exception occurs" do
      let(:original_url) { "https://google.com/" }

      before do
        allow(Tanshuku::Engine.routes).to receive(:default_url_options).and_return({})
      end

      it "rollbacks the created Tanshuku::Url record, reports the exception, and returns the original_url" do
        result =
          assert_no_difference -> { Tanshuku::Url.count } do
            Tanshuku::Url.shorten(original_url)
          end
        expect(result).to eq original_url

        expect(reported_exceptions).to have_attributes(size: 1)
        expect(reported_exceptions[0]).to be_a ArgumentError
        expect(reported_exceptions[0].message).to match(/Missing host to link to!/)
      end
    end

    context "when called simultaneously for a same URL" do
      let(:original_url) { "https://google.com/" }

      it "creates only 1 Tanshuku::Url record, doesn't report any exceptions, and returns same shortened URL string every time" do
        result1 = result2 = result3 = result4 = nil

        assert_difference -> { Tanshuku::Url.count }, 1 do
          [
            Thread.new { result1 = Tanshuku::Url.shorten(original_url) },
            Thread.new { result2 = Tanshuku::Url.shorten(original_url) },
            Thread.new { result3 = Tanshuku::Url.shorten(original_url) },
            Thread.new { result4 = Tanshuku::Url.shorten(original_url) },
          ].each(&:join)
        end

        expect(reported_exceptions).to be_empty

        created = Tanshuku::Url.last
        expect(created.url).to eq original_url
        expect(created.hashed_url).to match(/\A\w{128}\z/)
        expect(created.key).to match(/\A\w{20}\z/)

        expect(result1).to eq created.shortened_url
        expect(result2).to eq created.shortened_url
        expect(result3).to eq created.shortened_url
        expect(result4).to eq created.shortened_url
      end
    end
  end

  describe ".find_by_url" do
    context "when there are no Tanshuku::Url records" do
      let(:url) { "https://google.com/" }

      before do
        expect(Tanshuku::Url).not_to exist
      end

      it "doesn't find any record" do
        result = Tanshuku::Url.find_by_url(url)
        expect(result).to be_nil
      end
    end

    context "when there is only 1 Tanshuku::Url record" do
      let!(:shortened_url) { Tanshuku::Url.shorten(url) }

      let(:url) { "https://google.com/" }

      let(:all_urls) { [url] }

      before do
        expect(Tanshuku::Url).to have_attributes(count: all_urls.size)
      end

      context "and the very url is given" do
        it "finds the record" do
          result = Tanshuku::Url.find_by_url(url)
          expect(result.url).to eq url
          expect(result.shortened_url).to eq shortened_url
        end
      end

      context "and an essentially same url is given" do
        let(:essentially_same_url) { "https://google.com" }

        it "finds the record" do
          result = Tanshuku::Url.find_by_url(essentially_same_url)
          expect(result.url).to eq url
          expect(result.shortened_url).to eq shortened_url
        end
      end
    end

    context "when there are some Tanshuku::Url records" do
      let!(:shortened_url1) { Tanshuku::Url.shorten(url1) }
      let!(:shortened_url2) { Tanshuku::Url.shorten(url2) }
      let!(:shortened_url3) { Tanshuku::Url.shorten(url3) }

      let(:url1) { "https://google.com/" }
      let(:url2) { "https://google.com/foo"       }
      let(:url3) { "https://google.com/bar?baz=1" }

      let(:all_urls) { [url1, url2, url3] }

      before do
        expect(Tanshuku::Url).to have_attributes(count: all_urls.size)
      end

      context "and the very url is given" do
        it "finds the each correspond record" do
          result1 = Tanshuku::Url.find_by_url(url1)
          expect(result1.url).to eq url1
          expect(result1.shortened_url).to eq shortened_url1

          result2 = Tanshuku::Url.find_by_url(url2)
          expect(result2.url).to eq url2
          expect(result2.shortened_url).to eq shortened_url2

          result3 = Tanshuku::Url.find_by_url(url3)
          expect(result3.url).to eq url3
          expect(result3.shortened_url).to eq shortened_url3
        end
      end

      context "and an essentially same url is given" do
        let(:essentially_same_url1) { "https://google.com"      }
        let(:essentially_same_url2) { "https://google.com/foo?" }

        it "finds the each correspond record" do
          result1 = Tanshuku::Url.find_by_url(essentially_same_url1)
          expect(result1.url).to eq url1
          expect(result1.shortened_url).to eq shortened_url1

          result2 = Tanshuku::Url.find_by_url(essentially_same_url2)
          expect(result2.url).to eq url2
          expect(result2.shortened_url).to eq shortened_url2
        end
      end
    end
  end

  describe ".normalize_url" do
    subject { Tanshuku::Url.normalize_url(url) }

    [
      { original: "https://google.com/", normalized: "https://google.com/" },
      { original: "https://google.com", normalized: "https://google.com/" },
      { original: "https://google.com/?", normalized: "https://google.com/" },
      { original: "https://google.com?", normalized: "https://google.com/" },
      { original: "https://google.com/foo", normalized: "https://google.com/foo" },
      { original: "https://google.com/foo?", normalized: "https://google.com/foo" },
      { original: "https://google.com/foo/", normalized: "https://google.com/foo/" },
      { original: "https://google.com/foo/?", normalized: "https://google.com/foo/" },
      { original: "https://google.com/?foo=1", normalized: "https://google.com/?foo=1" },
      { original: "https://google.com/?foo=1&bar=2", normalized: "https://google.com/?bar=2&foo=1" },
      { original: "https://google.com/?bar=2&foo=1", normalized: "https://google.com/?bar=2&foo=1" },
      { original: "https://google.com/?foo=1&bar=2&", normalized: "https://google.com/?bar=2&foo=1" },
      { original: "https://google.com/?foo=1&&bar=2", normalized: "https://google.com/?bar=2&foo=1" },
      { original: "https://google.com/?foo=1&bar=2&baz=3", normalized: "https://google.com/?bar=2&baz=3&foo=1" },
      {
        original: "https://google.com/?foo=1&bar=2&a[b][c]=4&a[b][d]=5",
        normalized: "https://google.com/?a%5Bb%5D%5Bc%5D=4&a%5Bb%5D%5Bd%5D=5&bar=2&foo=1",
      },
      {
        original: "https://google.com/?foo=1&bar=2&a[]=4&a[]=5&a[]=6",
        normalized: "https://google.com/?a%5B%5D=4&a%5B%5D=5&a%5B%5D=6&bar=2&foo=1",
      },
    ].each do |testcase|
      context "when url is #{testcase[:original].inspect}" do
        let(:url) { testcase[:original] }

        it { is_expected.to eq testcase[:normalized] }
      end
    end
  end

  describe ".hash_url" do
    subject { Tanshuku::Url.hash_url(url) }

    [
      {
        url: "https://google.com/",
        hashed: "b5bac6dda08881f53df1535ce71d209e2fcc83cd0a98034116abee9da5ed87969a72811f2b9ec273dbeaa08f29c43ae7be290e67a47bc43ccb88557cd77f2061",
      },
      {
        url: "https://google.com/foo",
        hashed: "98353b81ce549b52e79d1ba37a7dc6493ccd62d9bdef3d0bc78bb677275b74f2c3a15b0b50cbf6045da04e3e21bb4db91d4e6ae7be896eade2c0a8affac01182",
      },
      {
        url: "https://google.com/foo/",
        hashed: "4179fe5b5a5e671b1d6c84a7ae8724d06c507c6e53e9f28b223b8827c3964712c75875ba664e36e3abe312f58eaee7cefe6284ceedb88985d974e0071a513ba4",
      },
      {
        url: "https://google.com/?foo=1",
        hashed: "e2119a6489b149eeb50a4854b6d7f4402df9b939b070a330f1972a31aeeeda51869456e1c30e309b0aed486cba58ef9d88d1360b1b3d5838d3d5421b1624d372",
      },
      {
        url: "https://google.com/?bar=2&foo=1",
        hashed: "220c365881bac0d4cbe8bea7e705c56c29a32d2781e8b6268b783c4d112a4cb3a1cfa7ef24687a64b9aa40e483807c06e116315e11031d4b10aa3e572a9313d8",
      },
      {
        url: "https://google.com/?bar=2&baz=3&foo=1",
        hashed: "6541abae4921ca8f59ddbf521f314da19c3f3e98bad33953f3e891a0ebea4c87d1f125bef4db7ec9b4df3fbafffbc5fefcc323b70a5adcaa321bbe3232fa1f95",
      },
      {
        url: "https://google.com/?a%5Bb%5D%5Bc%5D=4&a%5Bb%5D%5Bd%5D=5&bar=2&foo=1",
        hashed: "1757260d89a53660dc9b90729e067d0c6e07c52ac1058df6529a7966a31d58de7317c5e86b85b5413173438d56f05b117ca2678e38ca66361adffdafa98b27ea",
      },
      {
        url: "https://google.com/?a%5B%5D=4&a%5B%5D=5&a%5B%5D=6&bar=2&foo=1",
        hashed: "c72f59d21137c1ebd71162bdbf0af6448a3c731f40ad1d635b8adb2ebc89fd0da2a72bf140bd607224bc44b138687a999c5a3db607335e2bd7beddfc5506a83a",
      },
    ].each do |testcase|
      context "when url is #{testcase[:url].inspect}" do
        let(:url) { testcase[:url] }

        it { is_expected.to eq testcase[:hashed] }
      end
    end
  end

  describe ".generate_key" do
    it "returns a random 20-character alphanumeric string" do
      results = Array.new(10).map { Tanshuku::Url.generate_key }
      expect(results.size).to eq results.uniq.size
      expect(results).to all(match(/\A[a-zA-Z0-9]{20}\z/))
    end
  end

  describe ".report_exception" do
    let(:exception) { RuntimeError.new("This is a test exception.") }
    let(:original_url) { "https://google.com/" }

    before do
      allow(Rails.logger).to receive(:warn).and_call_original
      expect(Rails.logger).not_to have_received(:warn)
    end

    it "reports the given exception and the given original_url via Rails.logger.warn" do
      Tanshuku::Url.report_exception(exception:, original_url:)
      expect(Rails.logger).to have_received(:warn).with(
        "Tanshuku - Failed to shorten a URL: #{exception.inspect} for #{original_url.inspect}"
      )
    end
  end

  describe "#shortened_url" do
    let!(:tanshuku_url) { Tanshuku::Url.create!(valid_attrs) }
    let!(:original_default_url_options) { Tanshuku::Engine.routes.default_url_options }

    before do
      # Don't clear the original routes.
      Tanshuku::Engine.routes.disable_clear_and_finalize = true

      forced_value = default_url_options
      Tanshuku::Engine.routes.draw do
        default_url_options forced_value
      end
    end

    after do
      original_value = original_default_url_options
      Tanshuku::Engine.routes.draw do
        default_url_options original_value
      end
    end

    context "when Tanshuku::Engine.default_url_options is nil" do
      let(:default_url_options) { nil }

      it "raises NoMethodError due to `nil.merge`" do
        expect { tanshuku_url.shortened_url }.to raise_error NoMethodError, "undefined method `merge' for nil:NilClass"
      end
    end

    context "when Tanshuku::Engine.default_url_options is an empty hash" do
      let(:default_url_options) { {} }

      it "raises ArgumentError due to missing host" do
        expect { tanshuku_url.shortened_url }.to raise_error ArgumentError, /Missing host to link to!/
      end
    end

    context "when Tanshuku::Engine.default_url_options has nil host" do
      let(:default_url_options) { { host: nil } }

      it "raises ArgumentError due to missing host" do
        expect { tanshuku_url.shortened_url }.to raise_error ArgumentError, /Missing host to link to!/
      end
    end

    context "when Tanshuku::Engine.default_url_options has a string host" do
      let(:default_url_options) { { host: "google.com" } }

      it "returns a shortened URL" do
        expect(tanshuku_url.shortened_url).to eq "http://google.com/t/#{tanshuku_url.key}"
      end
    end

    context "when Tanshuku::Engine.default_url_options has a string host and some options" do
      let(:default_url_options) { { host: "google.com", protocol: :https, port: 50_443 } }

      it "returns a shortened URL" do
        expect(tanshuku_url.shortened_url).to eq "https://google.com:50443/t/#{tanshuku_url.key}"
      end
    end
  end

  private

  def valid_attrs
    url = "https://google.com/"

    {
      url:,
      hashed_url: Tanshuku::Url.hash_url(url),
      key: Tanshuku::Url.generate_key,
    }
  end
end
