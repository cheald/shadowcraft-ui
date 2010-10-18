class Item
  include Mongoid::Document
  include Mongoid::Timestamps
  
  GEM_CLASS = 3
  
  field :remote_id, :type => Integer, :index => true
  field :equip_location, :type => Integer, :index => true
  field :item_level, :type => Integer
  field :properties, :type => Hash
  field :info, :type => Hash
  field :wowhead, :type => Hash
  field :stats, :type => Hash
  field :has_stats, :type => Boolean
  field :requires, :type => Hash
  
  referenced_in :loadout
  
  validates_presence_of :remote_id
  
  before_save :update_from_armory_if_necessary
  before_save :write_stats
  
  EXCLUDE_KEYS = [:stamina, :resilience_rating, :strength, :spirit, :intellect, :dodge_rating, :parry_rating, :health_regen]
  
  def update_from_armory_if_necessary
    self.properties ||= ArmoryResource::Item.fetch(remote_id)
    if self.properties and self.properties["equipData"]
      self.equip_location = self.properties["equipData"]["inventoryType"].to_i
      if properties["classId"].to_i == GEM_CLASS
        self.info ||= ArmoryResource::ItemInfo.fetch(remote_id)
      end
      
      if self.properties and self.properties["socketData"]
        self.wowhead ||= WowheadResource::Item.fetch(remote_id)
      end
    end
  end
  
  def icon(size = 51)
    return "" if self.properties.nil?
    self.properties["icon"]
  end
  
  def sockets
    ((properties["socketData"] || {})["socket"] || []).map do |s|
      s.is_a?(Hash) ? s["color"] : s.last
    end
  end
  
  SCAN_ATTRIBUTES = ["agility", "stamina", "attack power", "critical strike rating", "hit rating", "expertise rating", "haste rating", "armor penetration", "all stats"]
  SCAN_OVERRIDE = {"critical strike rating" => "crit rating"}
  def get_gem_stats
    s = {}
    scan_attributes properties["gemProperties"]
  end
  
  def socket_bonus
    if wowhead and wowhead["jsonEquip"] and wowhead["jsonEquip"]["socketbonus"] and substr = wowhead["htmlTooltip"].match(/Socket Bonus:([^<]+)/)
      scan_attributes substr[1]
    else
      {}
    end
  end
  
  def scan_attributes(str)
    map = SCAN_ATTRIBUTES.map do |attr|
      if str =~/(\d+) (#{attr})/i
        qty = $1.to_i
        [(SCAN_OVERRIDE[attr] || attr).gsub(/ /, "_").to_sym, qty]
      else
        nil
      end
    end.compact
    Hash[*map.flatten]
  end
  
  def write_stats
    gem_stats = get_gem_stats
    self.stats = properties.keys.grep(/bonus/).map do |bonus|
      key = bonus.gsub(/^bonus/, "").snake_case.to_sym
      [key, properties[bonus].to_i]
    end.reduce(gem_stats) {|p, o|
      p[o.first] ||= 0;
      p[o.first] += o.last.to_i
      p
    }
    if all = self.stats.delete(:"all_stats")
      [:agility, :stamina, :strength].each do |stat|
        self.stats[stat] = (self.stats[stat] || 0) + all
      end
    end
    self.item_level = properties["itemLevel"].to_i
    self.has_stats = !(self.stats.keys - EXCLUDE_KEYS).empty?
    # puts "%s - %s - %s" % [self.properties["name"], self.stats.inspect, self.has_stats.to_s]
  end
  
  def as_json(options={})    
    json = {
      :id => remote_id,
      :name => properties["name"],
      :icon => icon.gsub(/\.(tga|jpg|png)$/i, ""),
      :quality => properties["overallQualityId"],
      :stats => stats
    }
    if sockets = properties["socketData"]
      Rails.logger.debug sockets["socket"].inspect
      json[:sockets] = [sockets["socket"]].flatten.map {|s| s["color"] }
    end
    if equip_location != 0
      json[:equip_location] = equip_location
      json[:ilvl] = properties["itemLevel"]
    end
    
    if wowhead and wowhead["jsonEquip"]
      json[:socketbonus] = socket_bonus
    end
    
    if properties["classId"].to_i == GEM_CLASS
      json[:slot] = info["type"]
      if info["requiredSkill"]
        json[:requires] = {:profession => (info["requiredSkill"] || "").downcase}
      end
    end
    
    json[:heroic] = "Heroic" if properties["heroic"] == "1"
    
    json
  end
  
  def self.populate
    Item.where(:equip_location.gt => 0).all.distinct(:equip_location).map {|i| Item.where(:equip_location => i).first.remote_id }.each do |item_id|
      puts "Populating slot matching item #{item_id}"
      populate_from_search("http://www.wowarmory.com/search.xml?searchType=items&pr=Cenarion+Circle&pn=Adrine&pi=%s" % item_id, 180)
    end
    
    puts "Populating gems..."
    %w"red blue yellow green orange purple prismatic meta".each do |slot|
      populate_from_search "http://www.wowarmory.com/search.xml?fl[source]=all&fl[type]=gems&fl[usbleBy]=4&fl[subTp]=%s&fl[rrt]=all&advOptName=none&fl[andor]=and&searchType=items&fl[advOpt]=none" % slot
    end
  end
  
  def self.populate_from_search(url, item_level = 0)
    ArmoryResource::Search.fetch(url, item_level).each do |id|
      item = Item.find_or_create_by :remote_id => id
      puts item.properties["name"] if item.created_at && item.created_at < 5.seconds.ago
    end
  end
  
  def self.reindex!
    self.all.each {|i| i.save }
  end
end
