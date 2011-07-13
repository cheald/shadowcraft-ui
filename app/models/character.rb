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

  RACES = ["Human", "Gnome", "Dwarf", "Night Elf", "Worgen", "Troll", "Orc", "Goblin", "Undead"]
  REGIONS = ["US", "EU", "KR", "TW", "CN"]
  CLASSES = ["rogue"]

  TALENTS = [:deadly_momentum, :coup_de_grace, :lethality, :ruthlessness, :quickening, :puncturing_wounds, :blackjack, :deadly_brew, :cold_blood,
    :vile_poisons, :deadened_nerves, :seal_fate, :murderous_intent, :overkill, :master_poisoner, :improved_expose_armor, :cut_to_the_chase,
    :venomous_wounds, :vendetta, :improved_recuperate, :improved_sinister_strike, :precision, :improved_slice_and_dice, :improved_sprint, :aggression,
    :improved_kick, :lightning_reflexes, :revealing_strike, :reinforced_leather, :improved_gouge, :combat_potency, :blade_twisting, :throwing_specialization,
    :adrenaline_rush, :savage_combat, :bandits_guile, :restless_blades, :killing_spree, :nightstalker, :improved_ambush, :relentless_strikes, :elusiveness,
    :waylay, :opportunity, :initiative, :energetic_recovery, :find_weakness, :hemorrhage, :honor_among_thieves, :premeditation, :enveloping_shadows, :cheat_death,
    :preparation, :sanguinary_vein, :slaughter_from_the_shadows, :serrated_blades, :shadow_dance]

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

      if self.properties.nil?
        return
      end
      self.properties.stringify_keys!

      return unless is_supported_class? and is_supported_level?

      self.portrait = char.portrait

      properties["gear"].each do |slot, item|
        i = Item.find_or_initialize_by(:remote_id => item["item_id"].to_i, :random_suffix => item["suffix"])
        if i.new_record?
          unless item["suffix"].blank?

            # This is a hack to work around some items not having the proper seeds
            scaling = item["scaling"]
            if scaling.blank?
              scaling = Item.where(:remote_id => item["item_id"].to_i, :scaling.ne => nil).fields(:scaling => true).first.scaling
            end

            i.scaling = scaling
            i.item_name_override = item["name"]
          end
          i.save
        end
      end
    end
  end

  def as_json(options = {})
    Rails.logger.debug Character.encode_random_items(properties["gear"]).inspect
    {
      :gear   => Character.encode_random_items(properties["gear"]),
      :talents => properties["talents"],
      :active => properties["active_talents"],
      :options => {
        :general => {
          :level => properties["level"],
          :race => properties["race"]
        },
        :professions => Hash[*properties["professions"].map {|p| [p, true]}.flatten]
      }
    }
  end

  def self.encode_random_items(items)
    items.clone.tap do |copy|
      copy.each do |key, item|
        if r = item.delete("suffix")
          item.delete "scaling"
          item["item_id"] = item["item_id"] * 1000 + r.to_i.abs
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
    Rails.logger.debug properties.inspect
    unless CLASSES.include? properties["player_class"].downcase
      errors.add :base, "The #{properties["player_class"]} class is not currently supported by Shadowcraft."
      return false
    end
    return true
  end

  def is_supported_level?
    unless properties["level"] >= 85
      errors.add :base, "Rogues under level 85 are not currently supported by Shadowcraft."
      return false
    end
    return true
  end
end
