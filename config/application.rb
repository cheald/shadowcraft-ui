require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Roguesim
  class Application < Rails::Application

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    
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

  end
end

