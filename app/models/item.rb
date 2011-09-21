class Item
  include Mongoid::Document
  include Mongoid::Timestamps

  field :remote_id, :type => Integer, :index => true
  field :random_suffix, :type => Integer
  field :equip_location, :type => Integer, :index => true
  field :item_level, :type => Integer
  field :properties, :type => Hash
  field :info, :type => Hash
  field :stats, :type => HashWithIndifferentAccess
  field :has_stats, :type => Boolean
  field :requires, :type => Hash
  field :is_gem, :type => Boolean, :index => true
  field :is_glyph, :type => Boolean, :index => true
  field :scaling, :type => Integer

  referenced_in :loadout

  attr_accessor :item_name_override

  validates_presence_of :remote_id
  validates_presence_of :properties

  before_validation :update_from_armory_if_necessary
  before_save :write_stats
  EXCLUDE_KEYS = [:stamina, :resilience_rating, :strength, :spirit, :intellect, :dodge_rating, :parry_rating, :health_regen]

  def update_from_armory_if_necessary
    return if remote_id == 0
    if self.properties.nil?
      Rails.logger.debug "Loading item #{remote_id}"
      item = WowArmory::Item.new(remote_id, random_suffix, scaling, item_name_override)
      # return false if item.stats.empty?
      self.properties = item.as_json.with_indifferent_access
      self.equip_location = self.properties["equip_location"]
      self.is_gem = !self.properties["gem_slot"].blank?
    end
    true
  end

  def uid
    if random_suffix?
      remote_id * 1000 + random_suffix.abs
    else
      remote_id
    end
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

    json[:heroic] = "Heroic" if properties["is_heroic"]

    if !properties["speed"].blank?
      json[:speed] = properties["speed"]
      json[:dps] = properties["dps"]
      json[:subclass] = properties["subclass"]
    end

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

  def self.populate_gear(prefix = "www")
    populate_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=346;maxle=358;ub=4;cr=21;crs=1;crv=0"
    populate_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=359;maxle=371;ub=4;cr=21;crs=1;crv=0"
    populate_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=372;maxle=500;ub=4;cr=21;crs=1;crv=0"

    populate_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=3;minle=346;ub=4;cr=21;crs=1;crv=0"
    populate_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=359;cr=13;crs=1;crv=0"
  end

  def self.populate_gems
    populate_from_wowhead "http://www.wowhead.com/items=3?filter=qu=2:3:4;minle=81"
    populate_from_wowhead "http://www.wowhead.com/items=3.10"
  end

  def self.populate_glyphs
    populate_from_wowhead "http://www.wowhead.com/items=16.4", :is_glyph => true
  end

  def self.populate_from_wowhead(url, options = {})
    doc = open(url).read
    gem_ids = doc.scan(/_\[(\d+)\]=\{.*?\}/).flatten.map &:to_i

    gem_ids.each do |id|
      begin
        Item.find_or_create_by options.merge(:remote_id => id)
      rescue WowArmory::MissingDocument => e
        puts e.message
      end
    end
    nil
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
