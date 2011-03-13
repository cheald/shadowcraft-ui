class Character
  class NotFoundException < Exception; end
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
  validates_presence_of :name
  validates_presence_of :realm
  validates_length_of :name, :maximum => 30
  validates_length_of :realm, :maximum => 30
  validates_uniqueness_of :uid

  before_validation :write_uid

  def to_param
    "%s-%s" % [normalize_realm]
  end

  def update_from_armory!(force = false)
    self.realm = self.realm.gsub(/-/, " ")
    self.region = self.region.upcase
    if self.properties.nil? or force
      char = WowArmory::Character.new(name, realm, region)
      self.properties = char.as_json
      self.properties.stringify_keys!
      self.portrait = char.portrait
    end
    raise NotFoundException if properties.nil?

    properties["gear"].each do |slot, item|
      Item.find_or_create_by(:remote_id => item["i"].to_i)
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
        :professions => properties["professions"]
      }
    }
  end

  def fullname
    "%s @ %s-%s" % [name.titleize, realm.titleize, region.upcase]
  end

  def write_uid
    self.uid = "%s-%s-%s" % [region.downcase, realm.downcase.gsub(/ /, "-"), normalize_character(name)]
  end

  def self.get!(region, realm, character)
    self.where(:uid => "%s-%s-%s" % [region.downcase, realm.downcase.gsub(/ /, "-"), normalize_character(character)]).first
  end
end
