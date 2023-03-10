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
end
