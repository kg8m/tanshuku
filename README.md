# Tanshuku

Tanshuku is a simple and small Rails engine that makes it easier to shorten URLs.

## Key Features

* Generates a unique key for a URL.
    * The uniqueness is ensured at database level.
* Creates no additional shortened URL record if the given URL has already been shortened.
    * You can create an additional record for the same URL with using a different namespace from existing records'.
    * Checks its existence considering the performance.
* Provides a Rails controller and action for finding a shortened URL record and redirecting to its original, i.e., non-shortened, URL.
    * The redirection is done with 301 HTTP status.

## Usage

### 1. Mount `Tanshuku::Engine`

For example, the following code generates a routing `` GET `/t/:key` to `Tanshuku::UrlsController#show` ``. When your Rails app receives a request to `/t/abcdefghij0123456789`, `Tanshuku::UrlsController#show` will be called and a `Tanshuku::Url` record with a key `abcdefghij0123456789` will be found. Then the request will be redirected to the `Tanshuku::Url` record's original URL.

```rb
# config/routes.rb
Rails.application.routes.draw do
  mount Tanshuku::Engine, at: "/t"
end
```

**Note**: You can customize the path `/t` as you like.

### 2. Configure Tanshuku (Optional)

**Note**: This step is optional.

**Note**: An initializer file for configuration can be generated by `bin/rails generate tanshuku:install`. See the "[Installation](#installation)" section below for more information.

**Note**: Mutating a `Tanshuku::Configuration` object is thread-***unsafe***. It is recommended to use `Tanshuku.configure` for configuration.

#### `config.default_url_options`

Tanshuku uses configured `config.default_url_options` when generating shortened URLs.

Default value is `{}`.

The following example means that the configured host and protocol are used. Shortened URLs will be like `https://example.com/t/abcdefghij0123456789`.

```rb
# config/initializers/tanshuku.rb
Tanshuku.configure do |config|
  config.default_url_options = { host: "example.com", protocol: :https }
end
```

#### `config.exception_reporter`

If an exception occurs when shortening a URL, Tanshuku reports it with configured `config.exception_reporter` object.

Default value is [`Tanshuku::Configuration::DefaultExceptionReporter`](https://kg8m.github.io/tanshuku/Tanshuku/Configuration/DefaultExceptionReporter.html). It logs the exception and the original URL with `Rails.logger.warn`.

Value of `config.exception_reporter` should respond to `#call` with keyword arguments `exception:` and `original_url:`.

The following example means that an exception and a URL will be reported to [Sentry](https://sentry.io/).

```rb
# config/initializers/tanshuku.rb
Tanshuku.configure do |config|
  config.exception_reporter =
    lambda { |exception:, original_url:|
      Sentry.capture_exception(exception, tags: { original_url: })
    }
end
```

#### More information

cf. [`Tanshuku::Configuration`'s API documentation](https://kg8m.github.io/tanshuku/Tanshuku/Configuration.html)

### 3. Generate shortened URLs

#### Basic cases

You can generate a shortened URL with `Tanshuku::Url.shorten`. For example:

```rb
Tanshuku::Url.shorten("https://google.com/")  #=> "https://example.com/t/abcdefghij0123456789"
```

[`config.default_url_options`](https://kg8m.github.io/tanshuku/Tanshuku/Configuration.html#default_url_options-instance_method) is used for the shortened URL.

**Note**: If a `Tanshuku::Url` record for the given URL already exists, no additional record will be created and always the existing record is used.

```rb
# When no record exists for "https://google.com/", a new record will be created.
Tanshuku::Url.shorten("https://google.com/")  #=> "https://example.com/t/abcde0123456789fghij"

# When a record already exists for "https://google.com/", no additional record will be created.
Tanshuku::Url.shorten("https://google.com/")  #=> "https://example.com/t/abcde0123456789fghij"
Tanshuku::Url.shorten("https://google.com/")  #=> "https://example.com/t/abcde0123456789fghij"
Tanshuku::Url.shorten("https://google.com/")  #=> "https://example.com/t/abcde0123456789fghij"
```

#### Shortening a URL with ad hoc URL options

You can specify URL options to `Tanshuku::Url.shorten`. For example:

```rb
Tanshuku::Url.shorten("https://google.com/", url_options: { host: "verycool.example.com" })
#=> "https://verycool.example.com/t/0123456789abcdefghij"

Tanshuku::Url.shorten("https://google.com/", url_options: { protocol: :http })
#=> "http://example.com/t/abcde01234fghij56789"
```

#### Shortening a URL with a namespace

You can create additional records for the same URL with specifying a namespace.

```rb
# When no record exists for "https://google.com/", a new record will be created.
Tanshuku::Url.shorten("https://google.com/")  #=> "https://example.com/t/abc012def345ghi678j9"

# Even when a record already exists for "https://google.com/", an additional record will be created if namespace is
# specified.
Tanshuku::Url.shorten("https://google.com/", namespace: "a")  #=> "https://example.com/t/ab01cd23ef45gh67ij89"
Tanshuku::Url.shorten("https://google.com/", namespace: "b")  #=> "https://example.com/t/a0b1c2d3e4f5g6h7i8j9"
Tanshuku::Url.shorten("https://google.com/", namespace: "c")  #=> "https://example.com/t/abcd0123efgh4567ij89"

# When the same URL and the same namespace is specified, no additional record will be created.
Tanshuku::Url.shorten("https://google.com/", namespace: "a")  #=> "https://example.com/t/ab01cd23ef45gh67ij89"
Tanshuku::Url.shorten("https://google.com/", namespace: "a")  #=> "https://example.com/t/ab01cd23ef45gh67ij89"
```

#### More information

cf. [`Tanshuku::Url.shorten`'s API documentation](https://kg8m.github.io/tanshuku/Tanshuku/Url.html#shorten-class_method)

### 4. Share the shortened URLs

You can share the shortened URLs, e.g., `https://example.com/t/abcdefghij0123456789`.

When a user clicks a link with a shortened URL, your Rails app redirects the user to its original URL.

## Installation

### 1. Enable Tanshuku

Add `gem "tanshuku"` to your application's `Gemfile`.

```rb
# Gemfile
gem "tanshuku"
```

### 2. Generate setup files

Execute a shell command as following:

```sh
bin/rails generate tanshuku:install
```

### 3. Apply generated migration files

Execute a shell command as following:

```sh
bin/rails db:migrate
```

## Q&amp;A

### What does "tanshuku" mean?

"Tanshuku" is a Japanese word "短縮." It means "shortening." "短縮URL" in Japanese means "shortened URL" in English.

### \*\* (anything you want) isn't implemented?

Does Tanshuku have some missing features? Please [create an issue](https://github.com/kg8m/tanshuku/issues/new).

## How to develop

1. Fork this repository
1. `git clone` your fork
1. `bundle install`
1. Update sources
1. `rake`
1. Fix `rake` errors if `rake` fails
1. Create a pull request

## How to release

1. Make your repository fresh
1. `bump current` and confirm the current version
1. `bump patch`, `bump minor`, or `bump major`
1. `rake release`
