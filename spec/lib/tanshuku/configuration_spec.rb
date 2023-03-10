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
  end
end
