require File.expand_path('../boot', __FILE__)

require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie" 
require "action_controller/railtie" 
require "action_mailer/railtie" 
require "action_view/railtie" 
require "sprockets/railtie" 
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Roguesim
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.autoload_paths << File.join(config.root, "lib")

    # Enable the asset pipeline
    config.assets.enabled = true
    config.assets.compress = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Precompile *all* assets, except those that start with underscore
    config.assets.precompile << /(^[^_\/]|\/[^_])[^\/]*$/

    # Need these settings so that the sass gets turned into CSS correctly by
    # 'rake assets:precompile'
    config.sass.preferred_syntax = :sass
    config.sass.line_comments = true
    config.sass.style = :expanded

    # Causes Coffeescript docs to not be wrapped in closures. Necessary because old code is poorly 
    Tilt::CoffeeScriptTemplate.default_bare = true
  end
end
