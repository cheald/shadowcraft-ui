class Artifact
  include Mongoid::Document
  include Mongoid::Timestamps
  include WowArmory::Constants

  field :remote_id, :type => Integer
  field :name, :type => String

  index({remote_id: 1, type: 1}, {unique: true})

  def as_json(options={})
    json = { 
      :id => remote_id,
      :n => name,
    }
  end

  def self.populate()

    item_ids = get_ids_from_wowhead()

    pos = 0
    item_ids.each do |id|
      begin
        pos = pos + 1
        puts "item #{pos} of #{item_ids.length}" if pos % 10 == 0
        db_item = Artifact.find_or_initialize_by(:remote_id => id)
        if db_item.name.nil?
          spell = WowArmory::Spell.new(id)
          db_item.name = spell.name
          if db_item.new_record?
            db_item.save()
          end
        end
      rescue Exception => e
        puts id
        puts e.message
      end
    end
  end

  def self.get_ids_from_wowhead
    url = "http://legion.wowhead.com/spells/artifact-traits/class:4"
    doc = open(url, 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36').read
    ids = doc.scan(/_\[(\d+)\]=\{.*?\}/).flatten.map &:to_i
    ids
  end
end
