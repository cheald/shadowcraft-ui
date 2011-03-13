class Item
  include Mongoid::Document
  include Mongoid::Timestamps

  field :remote_id, :type => Integer, :index => true
  field :equip_location, :type => Integer, :index => true
  field :item_level, :type => Integer
  field :properties, :type => Hash
  field :info, :type => Hash
  field :stats, :type => HashWithIndifferentAccess
  field :has_stats, :type => Boolean
  field :requires, :type => Hash
  field :is_gem, :type => Boolean, :index => true
  field :variant, :type => String
  field :is_glyph, :type => Boolean, :index => true

  referenced_in :loadout

  attr_accessor :variant_info

  validates_presence_of :remote_id

  before_validation :update_from_armory_if_necessary
  before_save :write_stats

  EXCLUDE_KEYS = [:stamina, :resilience_rating, :strength, :spirit, :intellect, :dodge_rating, :parry_rating, :health_regen]

  def update_from_armory_if_necessary
    return if remote_id == 0
    if self.properties.nil?
      Rails.logger.debug "Loading item #{remote_id}"
      item = WowArmory::Item.new(remote_id, variant_info)
      if item.stats.empty? and item.get_variants!.length > 0
        item.variants.each do |variant|
          unless existing = Item.where(:remote_id => remote_id, :variant => variant[:suffix]).first
            puts "Creating item with variant: #{variant.inspect}"
            Item.create :remote_id => remote_id, :variant_info => variant, :variant => variant[:suffix]
          end
        end
        return false
      else
        self.properties = item.as_json.with_indifferent_access
        self.equip_location = self.properties["equip_location"]
        self.is_gem = !self.properties["gem_slot"].blank?
      end
    end
    true
  end

  def uid
    variant? ? (remote_id + Digest::MD5.hexdigest(properties["name"]).slice(0, 4).to_i(16) * 10000) : remote_id
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
  end

  def as_json(options={})
    json = {
      :id => uid.to_i,
      :name => properties["name"],
      :icon => icon.gsub(/\.(tga|jpg|png)$/i, ""),
      :quality => properties["quality"],
      :stats => stats
    }
    if properties["sockets"] and !properties["sockets"].empty?
      json[:sockets] = properties["sockets"]
    end

    if properties["equip_location"]
      json[:equip_location] = properties["equip_location"]
    end
    json[:ilvl] = properties["ilevel"]

    if properties["socket_bonus"]
      json[:socketbonus] = properties["socket_bonus"]
    end

    if properties["requirement"]
      json[:requires] = {:profession => properties["requirement"].downcase}
    end

    if properties["gem_slot"]
      json[:slot] = properties["gem_slot"]
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

  def self.populate_gear
    populate_from_wowhead "http://www.wowhead.com/items?filter=qu=4;minle=346;ub=4;cr=21;crs=1;crv=0"
    populate_from_wowhead "http://www.wowhead.com/items?filter=qu=3;minle=346;ub=4;cr=21;crs=1;crv=0"
    populate_from_wowhead "http://www.wowhead.com/items?filter=qu=4;minle=359;cr=13;crs=1;crv=0"
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
      Item.find_or_create_by options.merge(:remote_id => id)
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
