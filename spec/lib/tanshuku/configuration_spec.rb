# frozen_string_literal: true

RSpec.describe Tanshuku::Configuration do
  let!(:configuration) { Tanshuku::Configuration.new }

  describe "attributes" do
    it "has an attribute :default_url_options" do
      expect(configuration).to have_attributes(default_url_options: {})

      new_default_url_options = { host: "example.com" }
      configuration.default_url_options = new_default_url_options
      expect(configuration).to have_attributes(default_url_options: new_default_url_options)
    end

    it "has an attribute :max_url_length" do
      expect(configuration).to have_attributes(max_url_length: 10_000)

      new_max_url_length = 20_000
      configuration.max_url_length = new_max_url_length
      expect(configuration).to have_attributes(max_url_length: new_max_url_length)
    end

    it "has an attribute :url_pattern" do
      expect(configuration).to have_attributes(url_pattern: %r{\A(?:https?://\w+|/)})

      new_url_pattern = %r{\A/}
      configuration.url_pattern = new_url_pattern
      expect(configuration).to have_attributes(url_pattern: new_url_pattern)
    end

    it "has an attribute :key_length" do
      expect(configuration).to have_attributes(key_length: 20)

      new_key_length = 10
      configuration.key_length = new_key_length
      expect(configuration).to have_attributes(key_length: new_key_length)
    end

    it "has an attribute :url_hasher" do
      expect(configuration).to have_attributes(url_hasher: Tanshuku::Configuration::DefaultUrlHasher)

      new_hasher = ->(url, namespace:) { "#{namespace}-#{url.upcase}" }
      configuration.url_hasher = new_hasher
      expect(configuration).to have_attributes(url_hasher: new_hasher)
    end

    it "has an attribute :key_generator" do
      expect(configuration).to have_attributes(key_generator: Tanshuku::Configuration::DefaultKeyGenerator)

      new_generator = -> { rand.to_s }
      configuration.key_generator = new_generator
      expect(configuration).to have_attributes(key_generator: new_generator)
    end

    it "has an attribute :exception_reporter" do
      expect(configuration).to have_attributes(exception_reporter: Tanshuku::Configuration::DefaultExceptionReporter)

      new_reporter =
        lambda { |exception:, originla_url:|
          Rails.logger.debug exception
          Rails.logger.debug originla_url
        }
      configuration.exception_reporter = new_reporter
      expect(configuration).to have_attributes(exception_reporter: new_reporter)
    end
  end

  describe "#configure" do
    context "with a block" do
      let!(:original_default_url_options) { {} }

      before do
        expect(configuration).to have_attributes(default_url_options: original_default_url_options)
      end

      after do
        configuration.configure do |config|
          config.default_url_options = original_default_url_options
        end
      end

      it "configures Tanshuku" do
        configuration.configure do |config|
          config.default_url_options = { protocol: :https }
        end

        expect(configuration).not_to have_attributes(default_url_options: original_default_url_options)
        expect(configuration).to have_attributes(default_url_options: { protocol: :https })

        configuration.configure do |config|
          config.default_url_options.update(host: "localhost")
        end

        expect(configuration).to have_attributes(default_url_options: { protocol: :https, host: "localhost" })
      end

      it "is thread-safe" do
        configuration.configure do |config|
          config.default_url_options = {}
          config.default_url_options[:port] = 0
        end

        threads =
          Array.new(10) do
            # rubocop:disable ThreadSafety/NewThread
            Thread.new do
              configuration.configure do |config|
                original_port = config.default_url_options[:port]
                sleep 0.01
                config.default_url_options[:port] = original_port + 1
              end
            end
            # rubocop:enable ThreadSafety/NewThread
          end
        threads.each(&:join)

        expect(configuration.default_url_options[:port]).to eq threads.size
      end
    end

    context "without a block" do
      it "raises a LocalJumpError" do
        expect { configuration.configure }.to raise_error LocalJumpError
      end
    end
  end
end
