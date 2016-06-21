class Relic
  include Mongoid::Document
  include Mongoid::Timestamps
  include WowArmory::Constants

  field :remote_id, :type => Integer
  field :name, :type => String
  field :type, :type => Integer
  field :quality, :type => Integer
  field :icon, :type => String
  field :trait_modified_id, :type => Integer
  field :trait_modified_name, :type => String
  field :trait_increase, :type => Integer
  field :ilvl_increase, :type => Integer

  index({remote_id: 1, type: 1}, {unique: true})

  def as_json(options={})
    json = { 
      :oid => remote_id,
      :id => remote_id,
      :n => name,
      :type => type,
      :tmi => trait_modified_id,
      :tmn => trait_modified_name,
      :ti => trait_increase,
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
#    item_ids += get_ids_from_wowhead_by_type(-10)
#    item_ids += get_ids_from_wowhead_by_type(-11)
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
          db_item.trait_modified_id = relic.trait_modified_id
          db_item.trait_modified_name = relic.trait_modified_name
          db_item.trait_increase = relic.rank_increase
          db_item.ilvl_increase = relic.ilvl_increase
          db_item.quality = relic.quality
          db_item.icon = relic.icon
          if db_item.new_record? and db_item.trait_modified_id != -1
            db_item.save()
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
    doc = open(url, 'User-Agent' => 'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:27.0) Gecko/20100101 Firefox/27.0').read
    ids = doc.scan(/_\[(\d+)\]=\{.*?\}/).flatten.map &:to_i
    ids
  end
end
