scripts = %w(
  app
  utility
  templates
  backend
  history
  helpers
  options
  talents
  gear
  console
  initialize
)

watch( "(#{scripts.join("|")})\.coffee" ) do |md|
  cmd = "coffee -c -o /tmp #{md[0]}"
  puts "Compiling file: #{cmd}"
  `#{cmd}`
  begin
    File.unlink("/tmp/#{md[1]}.js")
  rescue Errno::ENOENT
  end

  path = File.join(File.dirname(__FILE__), "..", "..", "public", "javascripts")
  cmd = "coffee -c -j -o #{path} #{scripts.map {|s| "#{s}.coffee"}.join " "}"
  puts "Compiling package: #{cmd}"
  `#{cmd}`
end