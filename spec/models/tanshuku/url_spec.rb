# frozen_string_literal: true

RSpec.describe Tanshuku::Url do
  describe "validations" do
    let!(:record) { Tanshuku::Url.new(valid_attrs) }

    describe "url length" do
      default_max_url_length = 10_000

      context "when max_url_length isn’t configured" do
        before do
          expect(Tanshuku.config).to have_attributes(max_url_length: default_max_url_length)
        end

        [
          { label: "nil", value: nil },
          { label: "an empty string", value: "" },
          { label: "a 1-char string", value: "a" },
          { label: "a 100-char string", value: "a" * 100 },
          { label: "a string with the default max URL length", value: "a" * default_max_url_length },
        ].each do |testcase|
          context "and url is #{testcase[:label]}" do
            before do
              record.url = testcase[:value]
            end

            it "doesn’t have any error for url length" do
              record.valid?
              expect(record.errors).not_to be_of_kind :url, :too_long
            end
          end
        end

        context "and url is a string over the default max URL length" do
          before do
            record.url = "a" * (default_max_url_length + 1)
          end

          it "has a error for url length" do
            record.valid?
            expect(record.errors).to be_of_kind :url, :too_long
          end
        end
      end

      context "when max_url_length is configured" do
        custom_max_url_length = 20_000

        before do
          Tanshuku.configure do |config|
            config.max_url_length = custom_max_url_length
          end
        end

        after do
          Tanshuku.configure do |config|
            config.max_url_length = default_max_url_length
          end
        end

        [
          { label: "nil", value: nil },
          { label: "an empty string", value: "" },
          { label: "a 1-char string", value: "a" },
          { label: "a 100-char string", value: "a" * 100 },
          { label: "a string with the default max URL length", value: "a" * default_max_url_length },
          { label: "a string over the default max URL length", value: "a" * (default_max_url_length + 1) },
          { label: "a string with the custom max URL length", value: "a" * custom_max_url_length },
        ].each do |testcase|
          context "and url is #{testcase[:label]}" do
            before do
              record.url = testcase[:value]
            end

            it "doesn’t have any error for url length" do
              record.valid?
              expect(record.errors).not_to be_of_kind :url, :too_long
            end
          end
        end

        context "and url is a string over the custom max URL length" do
          before do
            record.url = "a" * (custom_max_url_length + 1)
          end

          it "has a error for url length" do
            record.valid?
            expect(record.errors).to be_of_kind :url, :too_long
          end
        end
      end
    end

    describe "url format" do
      default_url_pattern = %r{\A(?:https?://\w+|/)}

      context "when url_pattern isn’t configured" do
        before do
          expect(Tanshuku.config).to have_attributes(url_pattern: default_url_pattern)

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
          context "and url is #{invalid_url_string.inspect}" do
            let(:url) { invalid_url_string }

            it "is invalid" do
              expect(record).not_to be_valid
              expect(record.errors).to be_of_kind :url, :invalid
            end
          end
        end
      end

      context "when url_pattern is configured" do
        custom_url_pattern = %r{\A/}

        before do
          Tanshuku.configure do |config|
            config.url_pattern = custom_url_pattern
          end
        end

        after do
          Tanshuku.configure do |config|
            config.url_pattern = default_url_pattern
          end
        end

        context "and url matches with the custom URL pattern" do
          it "is valid" do
            ["/", "/foo", "/foo/bar/baz", "/foo.bar", "/foo-bar"].each do |valid_url|
              record.url = valid_url
              expect(record).to be_valid, "url: #{valid_url.inspect}"
            end
          end
        end

        context "and url doesn’t match with the custom URL pattern" do
          it "is invalid" do
            ["foo", "foo/bar/baz", "foo.bar", "foo-bar"].each do |invalid_url|
              record.url = invalid_url
              expect(record).not_to be_valid, "url: #{invalid_url.inspect}"
              expect(record.errors).to(be_of_kind(:url, :invalid), "url: #{invalid_url.inspect}")
            end
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

      it "doesn’t create any Tanshuku::Url record, reports ArgumentError, and returns the original_url" do
        result =
          assert_no_difference -> { Tanshuku::Url.count } do
            Tanshuku::Url.shorten(original_url)
          end
        expect(result).to eq original_url

        expect(reported_exceptions).to have_attributes(size: 1)
        expect(reported_exceptions.first).to be_a ArgumentError
      end
    end

    context "when original_url is an empty string" do
      let(:original_url) { "" }

      it "doesn’t create any Tanshuku::Url record, reports ActiveRecord::RecordInvalid, and returns the original_url" do
        result =
          assert_no_difference -> { Tanshuku::Url.count } do
            Tanshuku::Url.shorten(original_url)
          end
        expect(result).to eq original_url

        expect(reported_exceptions).to have_attributes(size: 1)
        expect(reported_exceptions.first).to be_a ActiveRecord::RecordInvalid
        expect(reported_exceptions.first.record.errors).to be_of_kind :url, :blank
      end
    end

    context "when original_url is a non-URL string" do
      let(:original_url) { "invalid" }

      it "doesn’t create any Tanshuku::Url record, reports ActiveRecord::RecordInvalid, and returns the original_url" do
        result =
          assert_no_difference -> { Tanshuku::Url.count } do
            Tanshuku::Url.shorten(original_url)
          end
        expect(result).to eq original_url

        expect(reported_exceptions).to have_attributes(size: 1)
        expect(reported_exceptions.first).to be_a ActiveRecord::RecordInvalid
        expect(reported_exceptions.first.record.errors).to be_of_kind :url, :invalid
      end
    end

    ["https://google.com/", "http://google.com/", "/", "/path"].each do |valid_original_url|
      context "when original_url is #{valid_original_url.inspect}" do
        let(:original_url) { valid_original_url }

        context "and namespace isn’t given" do
          context "and there are no records for the same URL" do
            before do
              expect(Tanshuku::Url.where(url: original_url)).not_to exist
            end

            after do
              expect(Tanshuku::Url.where(url: original_url)).to exist
            end

            it "creates a new record, doesn’t report any exceptions, and returns a shortened URL string" do
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

          context "and there is a record for the same URL" do
            let!(:existing_record) { Tanshuku::Url.shorten(original_url) }

            before do
              expect(Tanshuku::Url.where(url: original_url)).to exist
            end

            it "doesn’t create an additional record" do
              result =
                assert_no_difference -> { Tanshuku::Url.count } do
                  Tanshuku::Url.shorten(original_url)
                end

              expect(result).to eq existing_record
            end
          end
        end

        context "and namespace is given" do
          context "and there are no records with the same namespace for the same URL" do
            let!(:existing_shortened_url_without_namespace) { Tanshuku::Url.shorten(original_url) }
            let!(:existing_shortened_url_with_other_namespace) do
              Tanshuku::Url.shorten(original_url, namespace: "existing")
            end

            before do
              existings = Tanshuku::Url.where(url: original_url)
              expect(existings).to exist
              expect(existings.map(&:shortened_url)).to contain_exactly(
                existing_shortened_url_without_namespace,
                existing_shortened_url_with_other_namespace
              )
            end

            it "creates a new record, doesn’t report any exceptions, and returns a shortened URL string" do
              result =
                assert_difference -> { Tanshuku::Url.count }, 1 do
                  Tanshuku::Url.shorten(original_url, namespace: "new")
                end
              expect(result).not_to eq original_url
              expect(result).to match SpecUtilities::SHORTENED_URL_PATTERN

              expect(reported_exceptions).to be_empty

              created = Tanshuku::Url.last
              expect(created.url).to eq original_url
              expect(created.hashed_url).to match(/\A\w{128}\z/)
              expect(created.key).to match(/\A\w{20}\z/)
            end

            it "doesn’t create an additional record with the same namespace for the same URL" do
              result =
                assert_no_difference -> { Tanshuku::Url.count } do
                  Tanshuku::Url.shorten(original_url, namespace: "existing")
                end

              expect(result).to eq existing_shortened_url_with_other_namespace
            end
          end
        end
      end
    end

    context "when url_options is given" do
      let(:original_url) { "https://google.com/" }

      it "creates a new record and returns a shortened URL string with the given url_options" do
        result =
          assert_difference -> { Tanshuku::Url.count }, 1 do
            Tanshuku::Url.shorten(original_url, url_options: { protocol: :https, host: "example.com", foo: 1 })
          end
        expect(result).not_to eq original_url
        expect(result).not_to match SpecUtilities::SHORTENED_URL_PATTERN
        expect(result).to match(%r{\Ahttps://example\.com/t/\w{20}\?foo=1\z})

        created = Tanshuku::Url.last
        expect(created.url).to eq original_url
        expect(created.hashed_url).to match(/\A\w{128}\z/)
        expect(created.key).to match(/\A\w{20}\z/)
      end
    end

    context "when called multiple times for the same URL" do
      let(:original_url) { "https://google.com/" }

      it "creates only 1 Tanshuku::Url record, doesn’t report any exceptions, and returns same shortened URL string every time" do
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
      let(:original_url1) { "https://google.com/"  }
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

        it "retries generating an other key, so creates a new Tanshuku::Url record, doesn’t report any exceptions, and returns a shortened URL string" do
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

        it "retries generating an other key but finally raises ActiveRecord::RecordNotUnique, so doesn’t create any Tanshuku::Url record, reports ActiveRecord::RecordInvalid, and returns the original_url" do
          result =
            assert_no_difference -> { Tanshuku::Url.count } do
              Tanshuku::Url.shorten(original_url)
            end
          expect(result).to eq original_url

          expect(reported_exceptions).to have_attributes(size: 1)
          expect(reported_exceptions.first).to be_a ActiveRecord::RecordNotFound
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
        expect(reported_exceptions.first).to be_a ArgumentError
        expect(reported_exceptions.first.message).to match(/Missing host to link to!/)
      end
    end

    context "when called simultaneously for a same URL" do
      let(:original_url) { "https://google.com/" }

      it "creates only 1 Tanshuku::Url record, doesn’t report any exceptions, and returns same shortened URL string every time" do
        result1 = result2 = result3 = result4 = nil

        assert_difference -> { Tanshuku::Url.count }, 1 do
          [
            # rubocop:disable ThreadSafety/NewThread
            Thread.new { result1 = Tanshuku::Url.shorten(original_url) },
            Thread.new { result2 = Tanshuku::Url.shorten(original_url) },
            Thread.new { result3 = Tanshuku::Url.shorten(original_url) },
            Thread.new { result4 = Tanshuku::Url.shorten(original_url) },
            # rubocop:enable ThreadSafety/NewThread
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

      context "and namespace isn’t given" do
        it "doesn’t find any record" do
          result = Tanshuku::Url.find_by_url(url)
          expect(result).to be_nil
        end
      end

      context "and namespace is given" do
        it "doesn’t find any record" do
          result = Tanshuku::Url.find_by_url(url, namespace: "test")
          expect(result).to be_nil
        end
      end
    end

    context "when there is only 1 Tanshuku::Url record" do
      let(:url) { "https://google.com/" }

      let(:all_shortened_urls) { [shortened_url] }

      before do
        expect(Tanshuku::Url).to have_attributes(count: all_shortened_urls.size)
      end

      context "without namespace" do
        let!(:shortened_url) { Tanshuku::Url.shorten(url) }

        context "and the very url is given" do
          context "and namespace isn’t given" do
            it "finds the record without namespace" do
              result = Tanshuku::Url.find_by_url(url)
              expect(result.url).to eq url
              expect(result.shortened_url).to eq shortened_url
            end
          end

          context "and a namespace is given" do
            it "doesn’t find any record" do
              result = Tanshuku::Url.find_by_url(url, namespace: "test")
              expect(result).to be_nil
            end
          end
        end

        context "and an essentially same url is given" do
          let(:essentially_same_url) { "https://google.com" }

          context "and namespace isn’t given" do
            it "finds the record without namespace" do
              result = Tanshuku::Url.find_by_url(essentially_same_url)
              expect(result.url).to eq url
              expect(result.shortened_url).to eq shortened_url
            end
          end

          context "and a namespace is given" do
            it "doesn’t find any record" do
              result = Tanshuku::Url.find_by_url(essentially_same_url, namespace: "test")
              expect(result).to be_nil
            end
          end
        end

        context "and an unknown url is given" do
          let(:unknown_url) { "https://google.com/foo" }

          context "and namespace isn’t given" do
            it "doesn’t find any record" do
              result = Tanshuku::Url.find_by_url(unknown_url)
              expect(result).to be_nil
            end
          end

          context "and a namespace is given" do
            it "doesn’t find any record" do
              result = Tanshuku::Url.find_by_url(unknown_url, namespace: "test")
              expect(result).to be_nil
            end
          end
        end
      end

      context "with namespace" do
        let!(:shortened_url) { Tanshuku::Url.shorten(url, namespace: "test") }

        context "and the very url is given" do
          context "and namespace isn’t given" do
            it "doesn’t find any record" do
              result = Tanshuku::Url.find_by_url(url)
              expect(result).to be_nil
            end
          end

          context "and the same namespace is given" do
            it "finds the record with namespace" do
              result = Tanshuku::Url.find_by_url(url, namespace: "test")
              expect(result.url).to eq url
              expect(result.shortened_url).to eq shortened_url
            end
          end

          context "and an unknown namespace is given" do
            it "doesn’t find any record" do
              result = Tanshuku::Url.find_by_url(url, namespace: "unknown")
              expect(result).to be_nil
            end
          end
        end

        context "and an essentially same url is given" do
          let(:essentially_same_url) { "https://google.com" }

          context "and namespace isn’t given" do
            it "doesn’t find any record" do
              result = Tanshuku::Url.find_by_url(essentially_same_url)
              expect(result).to be_nil
            end
          end

          context "and the same namespace is given" do
            it "finds the record with namespace" do
              result = Tanshuku::Url.find_by_url(essentially_same_url, namespace: "test")
              expect(result.url).to eq url
              expect(result.shortened_url).to eq shortened_url
            end
          end

          context "and an unknown namespace is given" do
            it "doesn’t find any record" do
              result = Tanshuku::Url.find_by_url(url, namespace: "unknown")
              expect(result).to be_nil
            end
          end
        end

        context "and an unknown url is given" do
          let(:unknown_url) { "https://google.com/foo" }

          context "and namespace isn’t given" do
            it "doesn’t find any record" do
              result = Tanshuku::Url.find_by_url(unknown_url)
              expect(result).to be_nil
            end
          end

          context "and the same namespace is given" do
            it "doesn’t find any record" do
              result = Tanshuku::Url.find_by_url(unknown_url, namespace: "test")
              expect(result).to be_nil
            end
          end

          context "and an unknown namespace is given" do
            it "doesn’t find any record" do
              result = Tanshuku::Url.find_by_url(unknown_url, namespace: "unknown")
              expect(result).to be_nil
            end
          end
        end
      end
    end

    context "when there are some Tanshuku::Url records" do
      let!(:shortened_url_without_namespace1) { Tanshuku::Url.shorten(url1)                    }
      let!(:shortened_url_without_namespace2) { Tanshuku::Url.shorten(url2)                    }
      let!(:shortened_url_without_namespace3) { Tanshuku::Url.shorten(url3)                    }
      let!(:shortened_url_with_namespace1)    { Tanshuku::Url.shorten(url1, namespace: "test") }
      let!(:shortened_url_with_namespace2)    { Tanshuku::Url.shorten(url2, namespace: "test") }
      let!(:shortened_url_with_namespace3)    { Tanshuku::Url.shorten(url3, namespace: "test") }

      let(:url1) { "https://google.com/" }
      let(:url2) { "https://google.com/foo"       }
      let(:url3) { "https://google.com/bar?baz=1" }

      let(:all_shortened_urls) do
        [
          shortened_url_without_namespace1,
          shortened_url_without_namespace2,
          shortened_url_without_namespace3,
          shortened_url_with_namespace1,
          shortened_url_with_namespace2,
          shortened_url_with_namespace3,
        ]
      end

      before do
        expect(Tanshuku::Url).to have_attributes(count: all_shortened_urls.size)
      end

      context "and the very url is given" do
        context "and namespace isn’t given" do
          it "finds the each corresponding record without namespace" do
            result1 = Tanshuku::Url.find_by_url(url1)
            expect(result1.url).to eq url1
            expect(result1.shortened_url).to eq shortened_url_without_namespace1

            result2 = Tanshuku::Url.find_by_url(url2)
            expect(result2.url).to eq url2
            expect(result2.shortened_url).to eq shortened_url_without_namespace2

            result3 = Tanshuku::Url.find_by_url(url3)
            expect(result3.url).to eq url3
            expect(result3.shortened_url).to eq shortened_url_without_namespace3
          end
        end

        context "and the same namespace is given" do
          it "finds the each corresponding record with namespace" do
            result1 = Tanshuku::Url.find_by_url(url1, namespace: "test")
            expect(result1.url).to eq url1
            expect(result1.shortened_url).to eq shortened_url_with_namespace1

            result2 = Tanshuku::Url.find_by_url(url2, namespace: "test")
            expect(result2.url).to eq url2
            expect(result2.shortened_url).to eq shortened_url_with_namespace2

            result3 = Tanshuku::Url.find_by_url(url3, namespace: "test")
            expect(result3.url).to eq url3
            expect(result3.shortened_url).to eq shortened_url_with_namespace3
          end
        end

        context "and unknown namespace is given" do
          it "doesn’t find any record" do
            result1 = Tanshuku::Url.find_by_url(url1, namespace: "unknown")
            expect(result1).to be_nil

            result2 = Tanshuku::Url.find_by_url(url2, namespace: "unknown")
            expect(result2).to be_nil

            result3 = Tanshuku::Url.find_by_url(url3, namespace: "unknown")
            expect(result3).to be_nil
          end
        end
      end

      context "and an essentially same url is given" do
        let(:essentially_same_url1) { "https://google.com"      }
        let(:essentially_same_url2) { "https://google.com/foo?" }

        context "and namespace isn’t given" do
          it "finds the each corresponding record without namespace" do
            result1 = Tanshuku::Url.find_by_url(essentially_same_url1)
            expect(result1.url).to eq url1
            expect(result1.shortened_url).to eq shortened_url_without_namespace1

            result2 = Tanshuku::Url.find_by_url(essentially_same_url2)
            expect(result2.url).to eq url2
            expect(result2.shortened_url).to eq shortened_url_without_namespace2
          end
        end

        context "and the same namespace is given" do
          it "finds the each corresponding record with namespace" do
            result1 = Tanshuku::Url.find_by_url(essentially_same_url1, namespace: "test")
            expect(result1.url).to eq url1
            expect(result1.shortened_url).to eq shortened_url_with_namespace1

            result2 = Tanshuku::Url.find_by_url(essentially_same_url2, namespace: "test")
            expect(result2.url).to eq url2
            expect(result2.shortened_url).to eq shortened_url_with_namespace2
          end
        end

        context "and an unknown namespace is given" do
          it "doesn’t find any record" do
            result1 = Tanshuku::Url.find_by_url(essentially_same_url1, namespace: "unknown")
            expect(result1).to be_nil

            result2 = Tanshuku::Url.find_by_url(essentially_same_url2, namespace: "unknown")
            expect(result2).to be_nil
          end
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
      { original: "https://google.com/?foo=1&bar=2&a[b][c]=4&a[b][d]=5", normalized: "https://google.com/?a%5Bb%5D%5Bc%5D=4&a%5Bb%5D%5Bd%5D=5&bar=2&foo=1" },
      { original: "https://google.com/?foo=1&bar=2&a[]=4&a[]=5&a[]=6", normalized: "https://google.com/?a%5B%5D=4&a%5B%5D=5&a%5B%5D=6&bar=2&foo=1" },
      { original: "https://google.com/#some-hash", normalized: "https://google.com/#some-hash" },
      { original: "https://google.com#some-hash", normalized: "https://google.com/#some-hash" },
      { original: "https://google.com/?#some-hash", normalized: "https://google.com/#some-hash" },
      { original: "https://google.com?#some-hash", normalized: "https://google.com/#some-hash" },
      { original: "https://google.com/?foo=#{CGI.escape("ほげ")}##{CGI.escape("ふが")}", normalized: "https://google.com/?foo=%E3%81%BB%E3%81%92#%E3%81%B5%E3%81%8C" },
    ].each do |testcase|
      context "when url is #{testcase[:original].inspect}" do
        let(:url) { testcase[:original] }

        it { is_expected.to eq testcase[:normalized] }
      end
    end
  end

  describe ".hash_url" do
    before do
      allow(Digest::SHA512).to receive(:hexdigest).and_call_original
      expect(Digest::SHA512).not_to have_received(:hexdigest)
    end

    context "when url_hasher isn’t configured" do
      before do
        expect(Tanshuku.config).to have_attributes(url_hasher: Tanshuku::Configuration::DefaultUrlHasher)
      end

      context "and namespace isn’t given" do
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
          context "and url is #{testcase[:url].inspect}" do
            let(:url) { testcase[:url] }

            it "returns a hashed URL" do
              result = Tanshuku::Url.hash_url(url)
              expect(result).to eq testcase[:hashed]
              expect(Digest::SHA512).to have_received(:hexdigest).with(url)
            end
          end
        end
      end

      context "and namespace is given" do
        [
          {
            url: "https://google.com/",
            hashed: "dd1831c079c4bd0557da2d47b5b3a57bf789fdd07e4ab7b716e331bd792fb149a24628752cf8337a92d31e7e50d4b70c3cc22838fa1fbdd61c37ad4236994d4d",
          },
          {
            url: "https://google.com/foo",
            hashed: "98c98e6bf6814d314003acc8dc3126ee9ba0f7daa86c91539a079f6e9d463aaaf203ef3b0524c184efa39b3ece2404ce5556f0fc69944e3f7f8d31906efec5b3",
          },
          {
            url: "https://google.com/foo/",
            hashed: "3b94f7b2322f838fa968c7f85a3df6a1a243ac88390d192203db114ccdc4ec2312e684bb06a5d0374608d2904d967326545e9c780aed2f5945b86c7ec36b401a",
          },
          {
            url: "https://google.com/?foo=1",
            hashed: "3716d3606ebbe84135e5f7b421fc86bf3af89c0fc7ad8cbc5c8a00b576448d0f4e43baaa9ddd97db867caa0281e4d34c806e483f7947f40a4e8b7e16d325cdc4",
          },
          {
            url: "https://google.com/?bar=2&foo=1",
            hashed: "ef47adfa8d26da75a7a6b5cd0d5c9cd2b0c4783310d7719bef78f7fb3ee5616576fce0d0415a6a631469150e60f313fca9d28078a55c750c8d41b36741afcba2",
          },
          {
            url: "https://google.com/?bar=2&baz=3&foo=1",
            hashed: "ba25e16a00dd981d6d6235d276bdfde09f257dc57147d8dd64b58d02e90d5a3e1f8cf65a9292e02a9e27bbafd1a9df6c81723cbf0067ec252e317a6e0a4ef602",
          },
          {
            url: "https://google.com/?a%5Bb%5D%5Bc%5D=4&a%5Bb%5D%5Bd%5D=5&bar=2&foo=1",
            hashed: "ea0a5f26f426d5b93641e68050ec8507abb4a6f8615db88959c2e5c9dd1ff0dc3dd1e7a58ae05262156cc718a38e97f495be736425029c6b8818a65e940d58d3",
          },
          {
            url: "https://google.com/?a%5B%5D=4&a%5B%5D=5&a%5B%5D=6&bar=2&foo=1",
            hashed: "5c5aed95cdf91e889ebaf27b3c1c1501c53bd5c9a0ecd0aa75e5534033bc5583823927f74062c8fcc7a01aa56a86fff55cb66d4fcf3e358872f299a7034032b1",
          },
        ].each do |testcase|
          context "and url is #{testcase[:url].inspect}" do
            let(:url) { testcase[:url] }

            it "returns a hashed URL with the namespace" do
              result = Tanshuku::Url.hash_url(url, namespace: "test")
              expect(result).to eq testcase[:hashed]
              expect(Digest::SHA512).to have_received(:hexdigest).with("test#{url}")
            end
          end
        end
      end
    end

    context "when url_hasher is configured" do
      before do
        Tanshuku.configure do |config|
          config.url_hasher = ->(url, namespace:) { "#{namespace}-#{url.upcase}" }
        end
      end

      after do
        Tanshuku.configure do |config|
          config.url_hasher = Tanshuku::Configuration::DefaultUrlHasher
        end
      end

      context "and namespace isn’t given" do
        it "returns a string via the custom URL hasher" do
          result = Tanshuku::Url.hash_url("https://google.com/")
          expect(result).to eq "-HTTPS://GOOGLE.COM/"
          expect(Digest::SHA512).not_to have_received(:hexdigest)
        end
      end

      context "and namespace is given" do
        it "returns a string via the custom URL hasher" do
          result = Tanshuku::Url.hash_url("https://google.com/", namespace: "test")
          expect(result).to eq "test-HTTPS://GOOGLE.COM/"
          expect(Digest::SHA512).not_to have_received(:hexdigest)
        end
      end
    end
  end

  describe ".generate_key" do
    before do
      allow(SecureRandom).to receive(:alphanumeric).and_call_original
      expect(SecureRandom).not_to have_received(:alphanumeric)
    end

    context "when key_generator isn’t configured" do
      let(:default_key_length) { 20 }

      before do
        expect(Tanshuku.config).to have_attributes(key_generator: Tanshuku::Configuration::DefaultKeyGenerator)
      end

      context "and key_length isn’t configured" do
        before do
          expect(Tanshuku.config).to have_attributes(key_length: default_key_length)
        end

        it "returns a random 20-character alphanumeric string via SecureRandom.alphanumeric" do
          results = Array.new(10) { Tanshuku::Url.generate_key }
          expect(results.size).to eq results.uniq.size
          expect(results).to all(match(/\A[a-zA-Z0-9]{#{default_key_length}}\z/))
          expect(SecureRandom).to have_received(:alphanumeric).with(default_key_length).exactly(10).times
        end
      end

      context "and key_length is configured" do
        let(:custom_key_length) { 10 }

        before do
          Tanshuku.configure do |config|
            config.key_length = custom_key_length
          end
        end

        after do
          Tanshuku.configure do |config|
            config.key_length = default_key_length
          end
        end

        it "returns a random alphanumeric string with the custom length via SecureRandom.alphanumeric" do
          results = Array.new(10) { Tanshuku::Url.generate_key }
          expect(results.size).to eq results.uniq.size
          expect(results).to all(match(/\A[a-zA-Z0-9]{#{custom_key_length}}\z/))
          expect(SecureRandom).to have_received(:alphanumeric).with(custom_key_length).exactly(10).times
        end
      end
    end

    context "when key_generator is configured" do
      count = 0

      before do
        Tanshuku.configure do |config|
          config.key_generator = -> { (count += 1).to_s }
        end
      end

      after do
        Tanshuku.configure do |config|
          config.key_generator = Tanshuku::Configuration::DefaultKeyGenerator
        end
      end

      it "returns a string via the custom key generator" do
        results = Array.new(10) { Tanshuku::Url.generate_key }
        expect(results).to eq Array(1..10).map(&:to_s)
        expect(SecureRandom).not_to have_received(:alphanumeric)
      end
    end
  end

  describe ".report_exception" do
    let(:exception)    { RuntimeError.new("This is a test exception.") }
    let(:original_url) { "https://google.com/"                         }

    before do
      allow(Rails.logger).to receive(:warn).and_call_original
      expect(Rails.logger).not_to have_received(:warn)
    end

    context "when exception_reporter isn’t configured" do
      before do
        expect(Tanshuku.config).to have_attributes(
          exception_reporter: Tanshuku::Configuration::DefaultExceptionReporter
        )
      end

      it "reports the given exception and the given original_url via Rails.logger.warn" do
        Tanshuku::Url.report_exception(exception:, original_url:)
        expect(Rails.logger).to have_received(:warn).with(
          "Tanshuku - Failed to shorten a URL: #{exception.inspect} for #{original_url.inspect}"
        )
      end
    end

    context "when exception_reporter is configured" do
      let(:reported_exceptions) { [] }
      let(:reported_original_urls) { [] }

      before do
        Tanshuku.configure do |config|
          config.exception_reporter =
            lambda { |exception:, original_url:|
              reported_exceptions << exception
              reported_original_urls << original_url
            }
        end

        expect(reported_exceptions).to be_empty
        expect(reported_original_urls).to be_empty
      end

      after do
        Tanshuku.configure do |config|
          config.exception_reporter = Tanshuku::Configuration::DefaultExceptionReporter
        end
      end

      it "reports the given exception and the given original_url via the custom reporter" do
        Tanshuku::Url.report_exception(exception:, original_url:)
        expect(Rails.logger).not_to have_received(:warn)
        expect(reported_exceptions).to eq [exception]
        expect(reported_original_urls).to eq [original_url]
      end
    end
  end

  describe "#shortened_url" do
    let!(:tanshuku_url) { Tanshuku::Url.create!(valid_attrs) }
    let(:original_default_url_options) { Tanshuku::Engine.routes.default_url_options }

    before do
      case Gem::Version.new(Rails.version)
      when "7.0"..."8.0"
        # noop
      else
        # Load the routes first as Tanshku depends on them.
        # cf. https://github.com/rails/rails/pull/52353
        Rails.application.reload_routes_unless_loaded
      end

      # Cache the original `default_url_options` value.
      original_default_url_options

      # Don’t clear the original routes.
      Tanshuku::Engine.routes.disable_clear_and_finalize = true

      # Overwrite Tanshuku’s `default_url_options` value.
      forced_value = default_url_options
      Tanshuku::Engine.routes.draw do
        default_url_options forced_value
      end
    end

    after do
      # Restore Tanshuku’s `default_url_options` value.
      original_value = original_default_url_options
      Tanshuku::Engine.routes.draw do
        default_url_options original_value
      end
    end

    context "when Tanshuku::Engine.default_url_options is nil" do
      let(:default_url_options) { nil }

      context "and url_options isn’t given" do
        it "raises NoMethodError due to `nil.merge`" do
          # Error message with Ruby 3.3 or older: undefined method `merge' for nil
          # Error message with Ruby 3.4 or newer: undefined method 'merge' for nil
          expect { tanshuku_url.shortened_url }.to raise_error(NoMethodError, /\bundefined method [`']merge' for nil\b/)
        end
      end

      context "and url_options is given" do
        let(:url_options) { { host: "example.com", protocol: :https } }

        it "raises NoMethodError due to `nil.merge`" do
          # Error message with Ruby 3.3 or older: undefined method `merge' for nil
          # Error message with Ruby 3.4 or newer: undefined method 'merge' for nil
          expect { tanshuku_url.shortened_url(url_options) }.to raise_error(
            NoMethodError,
            /\bundefined method [`']merge' for nil\b/
          )
        end
      end
    end

    context "when Tanshuku::Engine.default_url_options is an empty hash" do
      let(:default_url_options) { {} }

      context "and url_options isn’t given" do
        it "raises ArgumentError due to missing host" do
          expect { tanshuku_url.shortened_url }.to raise_error ArgumentError, /Missing host to link to!/
        end
      end

      context "and url_options is given" do
        let(:url_options) { { host: "example.com", protocol: :https } }

        it "returns a shortened URL with the given url_options" do
          expect(tanshuku_url.shortened_url(url_options)).to eq "https://example.com/t/#{tanshuku_url.key}"
        end
      end
    end

    context "when Tanshuku::Engine.default_url_options has nil host" do
      let(:default_url_options) { { host: nil } }

      context "and url_options isn’t given" do
        it "raises ArgumentError due to missing host" do
          expect { tanshuku_url.shortened_url }.to raise_error ArgumentError, /Missing host to link to!/
        end
      end

      context "and url_options is given" do
        let(:url_options) { { host: "example.com", protocol: :https } }

        it "returns a shortened URL with the given url_options" do
          expect(tanshuku_url.shortened_url(url_options)).to eq "https://example.com/t/#{tanshuku_url.key}"
        end
      end
    end

    context "when Tanshuku::Engine.default_url_options has a string host" do
      let(:default_url_options) { { host: "google.com" } }

      context "and url_options isn’t given" do
        it "returns a shortened URL" do
          expect(tanshuku_url.shortened_url).to eq "http://google.com/t/#{tanshuku_url.key}"
        end
      end

      context "and url_options is given" do
        let(:url_options) { { host: "example.com", protocol: :https } }

        it "returns a shortened URL with the given url_options" do
          expect(tanshuku_url.shortened_url(url_options)).to eq "https://example.com/t/#{tanshuku_url.key}"
        end
      end
    end

    context "when Tanshuku::Engine.default_url_options has a string host and some options" do
      let(:default_url_options) { { host: "google.com", protocol: :https, port: 50_443 } }

      context "and url_options isn’t given" do
        it "returns a shortened URL" do
          expect(tanshuku_url.shortened_url).to eq "https://google.com:50443/t/#{tanshuku_url.key}"
        end
      end

      context "and url_options is given" do
        let(:url_options) { { host: "example.com", protocol: :https } }

        it "returns a shortened URL with the given url_options merged to the default_url_options" do
          expect(tanshuku_url.shortened_url(url_options)).to eq "https://example.com:50443/t/#{tanshuku_url.key}"
        end
      end
    end

    context "when url_options contains :controller, :action, or :key" do
      let(:default_url_options) { {} }
      let(:url_options) do
        {
          host: "example.com",
          protocol: :https,
          controller: "dummy_controller",
          action: :dummy_action,
          key: "dummy_key",
          foo: 1,
        }
      end

      it "ignores :controller, :action, and :key" do
        expect(tanshuku_url.shortened_url(url_options)).to eq "https://example.com/t/#{tanshuku_url.key}?foo=1"
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
