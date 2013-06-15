class Character
  include Mongoid::Document
  include Mongoid::Timestamps
  include WowArmory::Document
  extend WowArmory::Document

  field :name
  field :realm
  field :region
  field :properties, :type => Hash
  field :portrait
  field :uid, :index => true

  RACES = ["Human", "Gnome", "Dwarf", "Night Elf", "Worgen", "Troll", "Orc", "Goblin", "Undead", "Pandaren"]
  REGIONS = ["US", "EU", "KR", "TW", "CN"]
  CLASSES = ["rogue"]

  TALENTS = [:nightstalker, :subterfuge, :shadow_focus, :deadly_throw, :nerve_strike, :combat_readiness, :cheat_death, :leeching_poison, :elusiveness,
    :preparation, :shadowstep, :burst_of_speed, :prey_on_the_weak, :paralytic_poison, :dirty_tricks, :shuriken_toss, :versatility,
    :anticipation]

  validates_inclusion_of :region, :in => REGIONS
  validates_presence_of :name, :message => "%{value} could not be found on the Armory."
  validates_presence_of :realm
  validates_length_of :name, :maximum => 30
  validates_length_of :realm, :maximum => 30
  validates_uniqueness_of :uid
  validates_presence_of :uid
  validates_presence_of :properties, :message => 'empty: could not load character from the Armory.'

  # validate :is_supported_class?

  before_validation :update_from_armory!
  before_validation :write_uid

  def to_param
    "%s-%s" % [normalize_realm]
  end

  def update_from_armory!(force = false)
    self.realm = self.realm.gsub(/-/, " ")
    self.region = self.region.upcase
    if self.properties.nil? or force
      begin
        char = WowArmory::Character.new(name, realm, region)
      rescue WowArmory::ArmoryError => e
        errors.add :base, e.message
        return
      rescue WowArmory::MissingDocument => e
        errors.add :base, "Character not found in the Armory"
        return
      end

      self.properties = char.as_json
      #Rails.logger.debug self.properties.inspect
      #Rails.logger.debug self.properties

      if self.properties.nil?
        return
      end
      self.properties.stringify_keys!

      return unless is_supported_class? and is_supported_level?

      self.portrait = char.portrait

      properties["gear"].each do |slot, item|
        # if its a random item first import the blank item if not yet in db
        # because sometimes its not working correctly if the blank item is not in the db
        #unless item["suffix"].blank?
        #  i = Item.find_or_initialize_by(:remote_id => item["item_id"].to_i)
        #  if i.new_record?
        #    i.save
        # end
        #end
        upgrade_levels = [nil, 1, 2, 3, 4]
        upgrade_levels.each do |level|
          i = Item.find_or_initialize_by(:remote_id => item["item_id"].to_i, :random_suffix => item["suffix"], :upgrade_level => level)
          if i.new_record?
            unless item["suffix"].blank?
              i.item_name_override = item["name"]
            end
            i.save
          end
        end
        [item["g0"],item["g1"],item["g2"]].each do |gemid|
          unless gemid.nil?
            i = Item.find_or_initialize_by(:remote_id => gemid.to_i)
            if i.new_record?
              i.save
            end
          end
        end
      end
    end
  end

  def as_json(options = {})
    #Rails.logger.debug Character.encode_random_items(properties["gear"]).inspect
    {
      :gear   => Character.encode_items(properties["gear"]),
      :talents => properties["talents"],
      :active => if not properties["active"].nil?
                    properties["active"]
                 elsif not properties["active_talents"].nil?
                    properties["active_talents"]
                 else
                    0
                 end,
      :options => {
        :general => {
          :level => properties["level"],
          :race => properties["race"]
        },
        :professions => Hash[*properties["professions"].map {|p| [p, true]}.flatten]
      },
      :achievements => properties["achievements"],
      :quests => properties["quests"]
    }
  end

  def self.encode_items(items)
    items.clone.tap do |copy|
      copy.each do |key, item|
        suffix = item.delete("suffix")
        upgrade_level = item.include?("upgrade_level")
        if suffix
          item["item_id"] = item["item_id"] * 1000 + suffix.to_i.abs
          if upgrade_level and item["upgrade_level"] > 0
            item["item_id"] = item["item_id"] * 1000 + item["upgrade_level"].to_i.abs
          end
        elsif upgrade_level and item["upgrade_level"] > 0
          item["item_id"] = item["item_id"] * 1000000 + item["upgrade_level"].to_i.abs
        end
      end
    end
  end

  def fullname
    "%s @ %s-%s" % [name.titleize, realm.titleize, region.upcase]
  end

  def write_uid
    return if region.blank? or realm.blank? or name.blank?
    region.upcase!
    self.uid = Character.uid(region, realm, name)
  end

  def self.uid(region, realm, name)
    ("%s-%s-%s" % [region.downcase, normalize_realm(realm), normalize_character(name)]).downcase
  end

  def self.get!(region, realm = nil, character = nil)
    if region.is_a? Hash
      realm = region[:realm]
      character = region[:name]
      region = region[:region]
    end
    if region.blank? or realm.blank? or character.blank?
      Character.new :region => region, :realm => realm, :name => character
    else
      self.where(:uid => Character.uid(region, realm, character)).first ||
        Character.create(:region => region, :realm => realm, :name => character)
    end
  rescue BSON::InvalidStringEncoding
    nil
  end

  def is_supported_class?
    #Rails.logger.debug properties.inspect
    unless CLASSES.include? properties["player_class"].downcase
      errors.add :base, "The #{properties["player_class"]} class is not currently supported by Shadowcraft."
      return false
    end
    return true
  end

  def is_supported_level?
    unless properties["level"] >= 90
      errors.add :base, "Rogues under level 90 are not currently supported by Shadowcraft."
      return false
    end
    return true
  end
end
