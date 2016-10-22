class Relic
  include Mongoid::Document
  include Mongoid::Timestamps
  include WowArmory::Constants

  field :remote_id, :type => Integer
  field :type, :type => String
  field :traits, :type => Hash

  index({remote_id: 1, type: 1}, {unique: true})

  def as_json(options={})
    json = { 
      :id => remote_id,
      :type => type,
      :ts => traits
    }
  end

  def self.populate()

    item_ids = []

    # In this order: Iron, Blood, Shadow, Fel, Storm
    item_ids += Item.get_ids_from_wowhead_by_type(-8)
    item_ids += Item.get_ids_from_wowhead_by_type(-9)
    item_ids += Item.get_ids_from_wowhead_by_type(-10)
    item_ids += Item.get_ids_from_wowhead_by_type(-11)
    item_ids += Item.get_ids_from_wowhead_by_type(-17)
    item_ids = item_ids.uniq

    pos = 0
    item_ids.each do |id|
      pos = pos + 1
      puts "item #{pos} of #{item_ids.length}" if pos % 10 == 0
      import(id)
    end
    true
  end

  def self.import(id)
    begin
      db_item = Relic.find_or_initialize_by(:remote_id => id)
      if db_item.type.nil?
        relic = WowArmory::Relic.new(id)
        db_item.type = relic.type
        db_item.traits = relic.traits
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
