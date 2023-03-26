# frozen_string_literal: true

RSpec.describe Tanshuku::Configuration do
  let!(:configuration) { Tanshuku::Configuration.new }

  describe "#default_url_options" do
    it "has an attribute :default_url_options" do
      expect(configuration).to have_attributes(default_url_options: {})

      new_default_url_options = { host: "example.com" }
      configuration.default_url_options = new_default_url_options
      expect(configuration).to have_attributes(default_url_options: new_default_url_options)
    end

    it "has an attribute :exception_reporter" do
      expect(configuration).to have_attributes(exception_reporter: Tanshuku::Configuration::DefaultExceptionReporter)

      new_reporter =
        lambda { |exception:, originla_url:|
          p exception
          p originla_url
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
