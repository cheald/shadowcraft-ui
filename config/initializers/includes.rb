require File.join(Rails.root, "lib", "jsmin.rb")
STAT_MAP = {}
map = YAML::load(open(File.join(Rails.root, "app", "xml", "stat_map.yml")).read).each_with_index do |v, i|
  STAT_MAP[v] = i
end