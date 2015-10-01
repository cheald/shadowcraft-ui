require 'json'
file = File.read('Items.json')
hash = JSON.parse(file)

hash['items'].each do |x|
  if x['id'] == 124545 then
    puts x
  end
end
