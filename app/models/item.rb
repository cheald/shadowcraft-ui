class Item
  include Mongoid::Document
  include Mongoid::Timestamps

  field :remote_id, :type => Integer, :index => true
  field :random_suffix, :type => Integer
  field :upgrade_level, :type => Integer
  field :equip_location, :type => Integer, :index => true
  field :item_level, :type => Integer
  field :properties, :type => Hash
  field :info, :type => Hash
  field :stats, :type => HashWithIndifferentAccess
  field :has_stats, :type => Boolean
  field :requires, :type => Hash
  field :is_gem, :type => Boolean, :index => true
  field :is_glyph, :type => Boolean, :index => true

  referenced_in :loadout

  attr_accessor :item_name_override

  validates_presence_of :remote_id
  validates_presence_of :properties

  before_validation :update_from_armory_if_necessary
  before_save :write_stats
  EXCLUDE_KEYS = [:stamina, :resilience, :strength, :spirit, :intellect, :dodge, :parry, :health_regen]

  def update_from_armory_if_necessary
    return if remote_id == 0
    if self.properties.nil?
      Rails.logger.debug "Loading item #{remote_id}"
      item = WowArmory::Item.new(remote_id, item_name_override)
      # return false if item.stats.empty?
      self.properties = item.as_json.with_indifferent_access
      item_stats = WowArmory::Itemstats.new(self.properties, random_suffix, upgrade_level)
      self.properties = self.properties.merge(item_stats.as_json.with_indifferent_access)
      self.equip_location = self.properties["equip_location"]
      self.is_gem = !self.properties["gem_slot"].blank?
    end
    true
  end

  def uid
    # a bit silly
    uid = remote_id
    if random_suffix?
      uid = remote_id * 1000 + random_suffix.abs
      if not properties["upgrade_level"].nil?
        uid = uid * 1000 + properties["upgrade_level"].to_i
      end
    else
      uid = remote_id
      if not properties["upgrade_level"].nil?
        uid = uid * 1000000 + properties["upgrade_level"].to_i
      end
    end
    uid
  end

  def icon(size = 51)
    return "" if self.properties.nil?
    self.properties["icon"].split("/").last
  end

  def write_stats
    return if properties.nil?
    self.stats = properties["stats"]
    if all = self.stats.delete(:"all_stats")
      [:agility, :stamina, :strength].each do |stat|
        self.stats[stat] = (self.stats[stat] || 0) + all
      end
    end
    self.item_level = properties["ilevel"]
    self.has_stats = !(self.stats.keys - EXCLUDE_KEYS).empty?
    true  # Returning false from a before_save filter causes it to fail.
  end

  def as_json(options={})
    json = {
      :id => uid.to_i,
      :n => properties["name"],
      :i => icon.gsub(/\.(tga|jpg|png)$/i, ""),
      :q => properties["quality"],
      :stats => stats
    }
    if properties["sockets"] and !properties["sockets"].empty?
      json[:so] = properties["sockets"]
    end

    if properties["equip_location"]
      json[:e] = properties["equip_location"]
    end
    json[:ilvl] = properties["ilevel"]

    if properties["socket_bonus"]
      json[:sb] = properties["socket_bonus"]
    end

    if properties["requirement"]
      json[:rq] = {:profession => properties["requirement"].downcase}
    end

    if properties["gem_slot"]
      json[:sl] = properties["gem_slot"]
    end

    json[:tag] = properties["tag"] if properties["tag"]

    if !properties["speed"].blank?
      json[:speed] = properties["speed"]
      json[:dps] = properties["dps"]
      json[:subclass] = properties["subclass"]
    end
    if properties["random_suffix"]
      json[:suffix] = properties["random_suffix"]
    end
    if properties["upgrade_level"]
      json[:upgrade_level] = properties["upgrade_level"]
    end
    if properties["upgradable"]
      json[:upgradable] = properties["upgradable"]
    end

    json
  end

  def self.populate_gear(prefix = "www")
    suffixes = (-137..-133).to_a
    random_item_ids = get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=3;minle=430;ub=4;cr=124;crs=0;crv=zephyr"
    random_item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items=4?filter=na=hozen-speed"
    random_item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items=4?filter=na=Stormcrier"
    
    random_item_ids += (93049..93056).to_a
    puts "importing now #{random_item_ids.length} random items"
    random_item_ids.each do |id|
      import id,[nil,1,2,3,4],suffixes
    end

    # 5.2 random enchantment items
    suffixes = (-340..-336).to_a
    random_item_ids = [ 94979, 95796, 96168, 96540, 96912 ]
    puts "importing now #{random_item_ids.length} random items for 5.2"
    random_item_ids.each do |id|
      import id,[nil,1,2,3,4],suffixes
    end

    # 5.3 random enchantment items
    suffixes = (-348..-344).to_a + (-357..-353).to_a
    random_item_ids = [ 98279, 98275, 98280, 98271, 98272, 98189, 98172, 98190 ]
    random_item_ids += (98173..98180).to_a # tidesplitter ilvl 516
    random_item_ids += [ 97663, 97647, 97682, 97633, 97655, 97639, 97675 ] # disowner ilvl 502
    puts "importing now #{random_item_ids.length} random items for 5.3"
    random_item_ids.each do |id|
      import id,[nil,1,2,3,4],suffixes
    end
    
    item_ids = get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=430;maxle=483;ub=4;cr=21;crs=1;crv=0"
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=484;maxle=500;ub=4;cr=21;crs=1;crv=0"
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=501;maxle=510;ub=4;cr=21;crs=1;crv=0"
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=511;maxle=530;ub=4;cr=21;crs=1;crv=0"
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=531;maxle=550;ub=4;cr=21;crs=1;crv=0"
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=3;minle=430;maxle=500;ub=4;cr=21;crs=1;crv=0"
    #item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=3;minle=501;maxle=550;ub=4;cr=21;crs=1;crv=0"

    item_ids += [ 87057, 86132, 86791, 87574, 81265, 81267, 75274, 87495, 77534, 77530 ] # some extra_items, mostly 5.0 trinkets
    item_ids += [ 94523, 96409, 96037, 95665] #bad juju
    item_ids += [ 96174, 94511] # missing other trinkets
    item_ids += [ 96741, 96781] # heroic thunderforged, rune of reorigination and talisman of bloodlust still missing
    item_ids += [ 98148 ] # ilvl 600 cloak 5.3    
    puts "importing now #{item_ids.length} items"
    pos = 0
    item_ids.each do |id|
      pos = pos + 1
      puts "item #{pos} of #{item_ids.length}"
      import id,[nil,1,2,3,4]
    end
    true
  end

  def self.populate_gems
    populate_from_wowhead "http://www.wowhead.com/items=3?filter=qu=2:3;minle=86;maxle=90"
    populate_from_wowhead "http://www.wowhead.com/items=3?filter=qu=2:3:4;minle=86;maxle=90;cr=99;crs=11;crv=0"

    single_import 89873 # 500agi gem
    single_import 95346 # legendary meta gem
  end

  def self.populate_glyphs
    populate_from_wowhead "http://www.wowhead.com/items=16.4", :is_glyph => true
  end

  def self.import(id, upgrade_levels = [nil], random_suffixes = [nil])
    # options need to be upgrade_level = [nil,1,2,3,4]
    # same for random_suffix
    item = nil
    begin
      random_suffixes.each do |suffix|
        upgrade_levels.each do |level|
          db_item = Item.find_or_initialize_by(:remote_id => id, :upgrade_level => level, :random_suffix => suffix)
          if db_item.properties.nil?
            if item.nil?
              item = WowArmory::Item.new(id)
            end
            db_item.properties = item.as_json.with_indifferent_access
            item_stats = WowArmory::Itemstats.new(db_item.properties, suffix, level)
            db_item.properties = db_item.properties.merge(item_stats.as_json.with_indifferent_access)
            db_item.equip_location = db_item.properties["equip_location"]
            db_item.is_gem = !db_item.properties["gem_slot"].blank?
            if db_item.new_record?
              db_item.save
            end
          end
        end
      end
    rescue WowArmory::MissingDocument => e
      puts id
      puts e.message
    end
  end

  def self.single_import(id, options = {})
    puts id    
    if not options.has_key?(:upgrade_level)
      options[:upgrade_level] = nil
    end
    begin
      Item.find_or_create_by options.merge(:remote_id => id)
    rescue WowArmory::MissingDocument => e
      puts id
      puts e.message
    end
  end

  def self.get_ids_from_wowhead(url)
    doc = open(url).read
    ids = doc.scan(/_\[(\d+)\]=\{.*?\}/).flatten.map &:to_i
    ids
  end

  def self.populate_from_wowhead(url, options = {})
    doc = open(url).read
    gem_ids = doc.scan(/_\[(\d+)\]=\{.*?\}/).flatten.map &:to_i
    gem_ids.each do |id|
      puts id
      begin
        Item.find_or_create_by options.merge(:remote_id => id)
      rescue WowArmory::MissingDocument => e
        puts id
        puts e.message
      end
    end
    nil
  end

  def self.reindex!
    self.all.each {|i| i.save }
  end
end
