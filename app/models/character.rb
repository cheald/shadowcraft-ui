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
  CLASSES = ["Rogue"]

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
      self.portrait = char.portrait
    end

    properties["gear"].each do |slot, item|
      Item.find_or_create_by(:remote_id => item["item_id"].to_i)
    end
  end

  def as_json(options = {})
    {
      :gear   => properties["gear"],
      :talents => properties["talents"],
      :active => properties["active_talents"],
      :name   => name,
      :realm  => realm,
      :region => region,
      :options => {
        :general => {
          :level => properties["level"],
          :race => properties["race"]
        },
        :professions => Hash[*properties["professions"].map {|p| [p, true]}.flatten]
      }
    }
  end

  def fullname
    "%s @ %s-%s" % [name.titleize, realm.titleize, region.upcase]
  end

  def write_uid
    return if region.blank? or realm.blank? or name.blank?
    region.upcase!
    self.uid = ("%s-%s-%s" % [region.downcase, realm.downcase.gsub(/ /, "-"), normalize_character(name)]).downcase
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
      self.where(:uid => "%s-%s-%s" % [region.downcase, realm.downcase.gsub(/ /, "-"), normalize_character(character)]).first
    end
  end
end
