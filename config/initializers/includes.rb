require File.join(Rails.root, "lib", "jsmin.rb")

require 'open-uri'
require File.join(Rails.root, "lib", "wow_armory", "document")
require File.join(Rails.root, "lib", "wow_armory", "item")
require File.join(Rails.root, "lib", "wow_armory", "character")

credentials = File.join(Rails.root, "config", "auth_key.yml")
if File.exists?(credentials)
  BLIZZARD_CREDENTIALS = YAML::load open(credentials).read
else
  BLIZZARD_CREDENTIALS = {}
end
