# frozen_string_literal: true

RSpec.describe Tanshuku do
  describe ".config" do
    it "returns a Tanshuku::Configuration instance" do
      expect(Tanshuku.config).to be_instance_of(Tanshuku::Configuration)
    end
  end

  describe ".configure" do
    context "with a block" do
      # cf. spec/dummy/config/initializers/tanshuku.rb
      let!(:original_default_url_options) { { host: "localhost" } }

      before do
        expect(Tanshuku.config).to have_attributes(default_url_options: original_default_url_options)
      end

      after do
        Tanshuku.configure do |config|
          config.default_url_options = original_default_url_options
        end
      end

      it "configures Tanshuku" do
        Tanshuku.configure do |config|
          config.default_url_options = { protocol: :https }
        end

        expect(Tanshuku.config).not_to have_attributes(default_url_options: original_default_url_options)
        expect(Tanshuku.config).to have_attributes(default_url_options: { protocol: :https })

        Tanshuku.configure do |config|
          config.default_url_options.update(host: "localhost")
        end

        expect(Tanshuku.config).to have_attributes(
          default_url_options: original_default_url_options.merge(protocol: :https)
        )
      end
    end

    context "without a block" do
      it "raises a LocalJumpError" do
        expect { Tanshuku.configure }.to raise_error LocalJumpError
      end
    end
  end
end
