#!/bin/env ruby
require 'yaml'
h = Hash[*File.open(File.join(Rails.root, "app", "xml", "stats.txt")).map {|l| x = l.strip.split(/[\s]+/, 2) }.flatten]
open("stats.yml", "w") {|f| f.write h.to_yaml }