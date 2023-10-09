# frozen_string_literal: true

require "digest/sha2"
require "securerandom"

module Tanshuku
  # A class for managing Tanshuku configurations.
  class Configuration
    # The default object to hash a URL. Calls +Digest::SHA512.hexdigest+.
    module DefaultUrlHasher
      # Calls +Digest::SHA512.hexdigest+ with the given URL string and the given namespace.
      #
      # @param url [String] A URL to hash.
      # @param namespace [String] A namespace for the URL’s uniqueness.
      #
      # @return [String] A SHA512 digest string from the given url and namespace.
      def self.call(url, namespace:)
        Digest::SHA512.hexdigest("#{namespace}#{url}")
      end
    end

    # The default unique key generator. Calls +SecureRandom.alphanumeric+ with {Tanshuku::Configuration#key_length}.
    module DefaultKeyGenerator
      # Calls +SecureRandom.alphanumeric+ and returns a string with length of {Tanshuku::Configuration#key_length}.
      #
      # @return [String] An alphanumeric string with length of {Tanshuku::Configuration#key_length}.
      def self.call
        SecureRandom.alphanumeric(Tanshuku.config.key_length)
      end
    end

    # The default error-reporter. Calls +Rails.logger.warn+.
    module DefaultExceptionReporter
      # Calls +Rails.logger.warn+ and logs the exception and the original URL.
      #
      # @param exception [Exception] An error instance at shortening a URL.
      # @param original_url [String] The original URL failed to shorten.
      #
      # @return [void]
      def self.call(exception:, original_url:)
        Rails.logger.warn("Tanshuku - Failed to shorten a URL: #{exception.inspect} for #{original_url.inspect}")
      end
    end

    if defined?(ActiveModel::Attributes)
      include ActiveModel::Attributes
    else
      # https://github.com/rails/rails/blob/v5.2.8.1/activemodel/lib/active_model/attributes.rb
      # https://github.com/rails/rails/blob/v5.2.8.1/activemodel/lib/active_model/type/integer.rb
      concerning :PetitModelAttributes do
        const_set :NO_DEFAULT_PROVIDED, Object.new

        class_methods do
          # rubocop:disable Metrics/MethodLength

          # A petit and limited implementation of `ActiveModel::Attributes`'s `attribute` method for backward
          # compatibility.
          #
          # @param name [Symbol] An attribute name.
          # @param cast_type [Symbol,nil] A type to cast the attribute's value.
          # @param default [Object] A default value of the attribute.
          #
          # @return [void]
          def attribute(name, cast_type = nil, default: NO_DEFAULT_PROVIDED)
            attr_reader name

            case cast_type
            when nil
              attr_writer name
            when :integer
              class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
                def #{name}=(value)          # def max_url_length=(value)
                  @#{name} =                 #   @max_url_length =
                    case value               #     case value
                    when true                #     when true
                      1                      #       1
                    when false               #     when false
                      0                      #       0
                    when nil                 #     when nil
                      nil                    #       nil
                    else                     #     else
                      value.to_i rescue nil  #       value.to_i rescue nil
                    end                      #     end
                end                          # end
              RUBY
            else
              raise ArgumentError, "Non-supported cast type: #{cast_type.inspect}"
            end

            return if default == NO_DEFAULT_PROVIDED

            mod =
              Module.new do
                class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
                  def initialize(*args)                # def initialize(*args)
                    super                              #   super
                    self.#{name} = #{default.inspect}  #   self.max_url_length = 10_000
                  end                                  # end
                RUBY
              end
            prepend mod
          end
          # rubocop:enable Metrics/MethodLength
        end
      end
    end

    # @!attribute [rw] default_url_options
    #   Default URL options for Rails’ +url_for+. Defaults to +{}+.
    #
    #   @return [Hash]
    #   @return [void] If you set an invalid object.
    #
    #   @note
    #     The example below means that the configured host and protocol are used. Shortened URLs will be like
    #     +https://example.com/t/abcdefghij0123456789+.
    #
    #   @example
    #     # config/initializers/tanshuku.rb
    #     Tanshuku.configure do |config|
    #       config.default_url_options = { host: "example.com", protocol: :https }
    #     end
    attribute :default_url_options, default: {}

    # @!attribute [rw] max_url_length
    #   Maximum length of {Tanshuku::Url#url}. Defaults to +10,000+.
    #
    #   @return [Integer]
    #   @return [void] If you set an invalid object.
    #
    #   @note
    #     The example below means that {Tanshuku::Url#url} can have a URL string with less than or equal to 20,000
    #     characters.
    #
    #   @example
    #     # config/initializers/tanshuku.rb
    #     Tanshuku.configure do |config|
    #       config.max_url_length = 20_000
    #     end
    attribute :max_url_length, :integer, default: 10_000

    # @!attribute [rw] url_pattern
    #   Allowed pattern of {Tanshuku::Url#url}. Defaults to <code>%r{\A(?:https?://\w+|/)}</code>. This default value
    #   forces a URL to start with "http://" or "https://", or to be an absolute path without scheme.
    #
    #   @return [Regexp]
    #   @return [void] If you set an invalid object.
    #
    #   @note
    #     The example below means that {Tanshuku::Url#url} should start with a slash +/+.
    #
    #   @example
    #     # config/initializers/tanshuku.rb
    #     Tanshuku.configure do |config|
    #       config.url_pattern = /\A\//
    #     end
    attribute :url_pattern, default: %r{\A(?:https?://\w+|/)}

    # @!attribute [rw] key_length
    #   Length of {Tanshuku::Url#key} when {Tanshuku::Configuration#key_generator} is
    #   {Tanshuku::Configuration::DefaultKeyGenerator}. Defaults to +20+.
    #
    #   @return [Integer]
    #   @return [void] If you set an invalid object.
    #
    #   @note Don’t forget to fix the limit of the +tanshuku_urls.key+ column if you change this value.
    #
    #   @note
    #     The example below means that {Tanshuku::Url#key} has 10-char string.
    #
    #   @example
    #     # config/initializers/tanshuku.rb
    #     Tanshuku.configure do |config|
    #       config.key_length = 10
    #     end
    attribute :key_length, :integer, default: 20

    # @!attribute [rw] url_hasher
    #   A class, module, or object to hash a URL. This should respond to +#call+ with a required positional argument
    #   +url+ and a required keyword argument +namespace:+. Defaults to {Tanshuku::Configuration::DefaultUrlHasher}.
    #
    #   @return [#call]
    #     A class, module, or object that responds to +#call+ with a required positional argument +url+ and a required
    #     keyword argument +namespace:+.
    #   @return [void] If you set an invalid object.
    #
    #   @note The example below means that URLs are hashed with +Digest::SHA256.hexdigest+.
    #
    #   @example
    #     # config/initializers/tanshuku.rb
    #     Tanshuku.configure do |config|
    #       config.url_hasher = ->(url, namespace:) { Digest::SHA256.hexdigest("#{namespace}#{url}") }
    #     end
    attribute :url_hasher, default: DefaultUrlHasher

    # @!attribute [rw] key_generator
    #   A class, module, or object to generate a unique key for shortened URLs. This should respond to +#call+ without
    #   any arguments. Defaults to {Tanshuku::Configuration::DefaultKeyGenerator}.
    #
    #   @return [#call]
    #     A class, module, or object that responds to +#call+ without any arguments.
    #   @return [void] If you set an invalid object.
    #
    #   @note The example below means that unique keys for shortened URLs are generated by +SecureRandom.uuid+.
    #
    #   @example
    #     # config/initializers/tanshuku.rb
    #     Tanshuku.configure do |config|
    #       config.key_generator = -> { SecureRandom.uuid }
    #     end
    attribute :key_generator, default: DefaultKeyGenerator

    # @!attribute [rw] exception_reporter
    #   A error-reporter class, module, or object used when shortening a URL fails. This should respond to +#call+ with
    #   required keyword arguments +exception:+ and +original_url:+. Defaults to
    #   {Tanshuku::Configuration::DefaultExceptionReporter}.
    #
    #   @return [#call]
    #     A class, module, or object that responds to +#call+ with required keyword arguments +exception:+ and
    #     +original_url:+.
    #   @return [void] If you set an invalid object.
    #
    #   @note The example below means that an exception and a URL will be reported to Sentry (https://sentry.io).
    #
    #   @example
    #     # config/initializers/tanshuku.rb
    #     Tanshuku.configure do |config|
    #       config.exception_reporter =
    #         lambda { |exception:, original_url:|
    #           Sentry.capture_exception(exception, tags: { original_url: original_url })
    #         }
    #     end
    attribute :exception_reporter, default: DefaultExceptionReporter

    def initialize(*args)
      super
      @mutex = Mutex.new
    end

    # Configures Tanshuku thread-safely.
    #
    # @yieldparam config [Tanshuku::Configuration] A configuration object that is yielded.
    # @yieldreturn [void]
    #
    # @return [void]
    #
    # @note Use {Tanshuku.configure} as a public API for configuration.
    #
    # @api private
    def configure
      @mutex.synchronize do
        yield self
      end
    end
  end
end
