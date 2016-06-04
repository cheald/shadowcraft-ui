class Relic
  include Mongoid::Document
  include Mongoid::Timestamps
  include WowArmory::Constants

  field :remote_id, :type => Integer
  field :name, :type => String
  field :type, :type => Integer
  field :quality, :type => Integer
  field :icon, :type => String
  field :traits, :type => Hash
  field :ilvl_increase, :type => Integer

  index({remote_id: 1, type: 1}, {unique: true})

  def as_json(options={})
    json = { 
      :id => remote_id,
      :n => name,
      :type => type,
      :ts => traits,
      :ii => ilvl_increase,
      :q => quality,
      :i => icon
    }
  end

  def self.populate()

    item_ids = []

    # In this order: Iron, Blood, Shadow, Fel, Wind
    item_ids += get_ids_from_wowhead_by_type(-8)
    item_ids += get_ids_from_wowhead_by_type(-9)
    item_ids += get_ids_from_wowhead_by_type(-10)
    item_ids += get_ids_from_wowhead_by_type(-11)
    item_ids += get_ids_from_wowhead_by_type(-17)

    pos = 0
    item_ids.each do |id|
      begin
        pos = pos + 1
        puts "item #{pos} of #{item_ids.length}" if pos % 10 == 0
        db_item = Relic.find_or_initialize_by(:remote_id => id)
        if db_item.type.nil?
          relic = WowArmory::Relic.new(id)
          db_item.type = relic.type
          db_item.name = relic.name
          db_item.traits = relic.traits
          db_item.ilvl_increase = relic.ilvl_increase
          db_item.quality = relic.quality
          db_item.icon = relic.icon
          if db_item.new_record? and !db_item.traits.empty?
            db_item.save()
          elsif db_item.traits.empty?
            puts "Failed to load relic #{id}"
          end
        end
      rescue Exception => e
        puts id
        puts e.message
      end
    end
  end

  def self.get_ids_from_wowhead_by_type(type)
    url = "http://legion.wowhead.com/items=3?filter=ty=#{type};cr=166;crs=7;crv=0"
    doc = open(url, 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36').read
    ids = doc.scan(/_\[(\d+)\]=\{.*?\}/).flatten.map &:to_i
    ids
  end
end
