# frozen_string_literal: true

RSpec.describe CollectPackageFiles do
  let(:expected_included_files) do
    %w[
      LICENSE
      README.md
      app/controllers/tanshuku/urls_controller.rb
      app/models/tanshuku/url.rb
      config/locales/en.yml
      config/locales/ja.yml
      config/routes.rb
      db/migrate/20230220123456_create_tanshuku_urls.rb
      lib/generators/tanshuku/install_generator.rb
      lib/generators/templates/initializer.rb
      lib/tanshuku.rb
      lib/tanshuku/configuration.rb
      lib/tanshuku/engine.rb
      lib/tanshuku/version.rb
      sig/app/controllers/tanshuku/urls_controller.rbs
      sig/app/models/tanshuku/url.rbs
      sig/db/migrate/create_tanshuku_urls.rbs
      sig/lib/generators/tanshuku/install_generator.rbs
      sig/lib/tanshuku.rbs
      sig/lib/tanshuku/configuration.rbs
      sig/lib/tanshuku/engine.rbs
      sig/lib/tanshuku/version.rbs
    ]
  end
  let(:expected_excluded_files) do
    %w[
      .gitattributes
      .github/dependabot.yml
      .github/release.yml
      .github/workflows/bot-auto-merge.yml
      .github/workflows/checks.yml
      .github/workflows/create-release.yml
      .github/workflows/dependabot-autolabeling.yml
      .github/workflows/pages.yml
      .github/workflows/update-rbs-collection.yml
      .gitignore
      .rspec
      .rubocop.yml
      Gemfile
      Gemfile.ci
      Gemfile.lock
      Rakefile
      Steepfile
      bin/rails
      lib/tasks/check_all.rb
      rbs_collection.lock.yaml
      rbs_collection.yaml
      sig/lib/tasks/check_all.rbs
      sig/patch/actionpack.rbs
      sig/patch/activerecord.rbs
      sig/patch/english.rbs
      sig/patch/paint.rbs
      sig/patch/pty.rbs
      sig/patch/rack.rbs
      sig/patch/rails.rbs
      sig/patch/thor.rbs
      spec/config/locales/en_spec.rb
      spec/config/locales/ja_spec.rb
      spec/dummy/Rakefile
      spec/dummy/app/assets/config/manifest.js
      spec/dummy/app/assets/images/.keep
      spec/dummy/app/assets/stylesheets/application.css
      spec/dummy/app/channels/application_cable/channel.rb
      spec/dummy/app/channels/application_cable/connection.rb
      spec/dummy/app/controllers/application_controller.rb
      spec/dummy/app/controllers/concerns/.keep
      spec/dummy/app/helpers/application_helper.rb
      spec/dummy/app/jobs/application_job.rb
      spec/dummy/app/mailers/application_mailer.rb
      spec/dummy/app/models/application_record.rb
      spec/dummy/app/models/concerns/.keep
      spec/dummy/app/views/layouts/application.html.erb
      spec/dummy/app/views/layouts/mailer.html.erb
      spec/dummy/app/views/layouts/mailer.text.erb
      spec/dummy/app/views/pwa/manifest.json.erb
      spec/dummy/app/views/pwa/service-worker.js
      spec/dummy/bin/dev
      spec/dummy/bin/rails
      spec/dummy/bin/rake
      spec/dummy/bin/setup
      spec/dummy/config.ru
      spec/dummy/config/application.rb
      spec/dummy/config/boot.rb
      spec/dummy/config/cable.yml
      spec/dummy/config/database.yml
      spec/dummy/config/environment.rb
      spec/dummy/config/environments/development.rb
      spec/dummy/config/environments/production.rb
      spec/dummy/config/environments/test.rb
      spec/dummy/config/initializers/assets.rb
      spec/dummy/config/initializers/content_security_policy.rb
      spec/dummy/config/initializers/filter_parameter_logging.rb
      spec/dummy/config/initializers/inflections.rb
      spec/dummy/config/initializers/tanshuku.rb
      spec/dummy/config/locales/en.yml
      spec/dummy/config/puma.rb
      spec/dummy/config/routes.rb
      spec/dummy/config/storage.yml
      spec/dummy/lib/assets/.keep
      spec/dummy/log/.keep
      spec/dummy/public/400.html
      spec/dummy/public/404.html
      spec/dummy/public/406-unsupported-browser.html
      spec/dummy/public/422.html
      spec/dummy/public/500.html
      spec/dummy/public/apple-touch-icon-precomposed.png
      spec/dummy/public/apple-touch-icon.png
      spec/dummy/public/favicon.ico
      spec/dummy/public/icon.svg
      spec/generator/tanshuku/install_generator_spec.rb
      spec/lib/tanshuku/configuration_spec.rb
      spec/lib/tanshuku_spec.rb
      spec/models/tanshuku/url_spec.rb
      spec/requests/tanshuku/urls_controller_spec.rb
      spec/spec_helper.rb
      spec/support/spec_utilities.rb
      spec/tools/collect_package_files_spec.rb
      tanshuku.gemspec
      tmp/.keep
      tools/collect_package_files.rb
      tools/reverse_dependencies.rb
    ]
  end
  let(:all_candidate_files) { `git ls-files -z`.split("\x0") }

  example "collects sufficient and necessary files" do
    expect(CollectPackageFiles.call).to match_array(expected_included_files)
    expect(CollectPackageFiles.call & expected_excluded_files).to be_empty
    expect(expected_included_files + expected_excluded_files).to match_array(all_candidate_files)
  end
end