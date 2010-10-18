class Character
  class NotFoundException < Exception; end
  include Mongoid::Document
  field :name
  field :realm
  field :region
  field :player_class
  field :level
  field :race
  field :properties, :type => Hash
  field :talents, :type => Hash
  
  # x.css("tree").sort {|a, b| a["order"].to_i <=> b["order"].to_i }.map {|tree| tree.css("talent").map {|t| t["name"].gsub(/ /, "").snake_case.to_sym } }.flatten

  TALENTS = [:deadly_momentum, :coup_de_grace, :lethality, :ruthlessness, :quickening, :puncturing_wounds, :blackjack, :deadly_brew, :cold_blood, 
  :vile_poisons, :deadened_nerves, :seal_fate, :murderous_intent, :overkill, :master_poisoner, :improved_expose_armor, :cut_to_the_chase, 
  :venomous_wounds, :vendetta, :improved_recuperate, :improved_sinister_strike, :precision, :improved_slice_and_dice, :improved_sprint, :aggression, 
  :improved_kick, :lightning_reflexes, :revealing_strike, :reinforced_leather, :improved_gouge, :combat_potency, :blade_twisting, :throwing_specialization, 
  :adrenaline_rush, :savage_combat, :bandits_guile, :restless_blades, :killing_spree, :nightstalker, :improved_ambush, :relentless_strikes, :elusiveness, 
  :waylay, :opportunity, :initiative, :energetic_recovery, :find_weakness, :hemorrhage, :honor_among_thieves, :premeditation, :enveloping_shadows, :cheat_death, 
  :preparation, :sanguinary_vein, :slaughter_from_the_shadows, :serrated_blades, :shadow_dance]

  TREE_ONE_TALENTS = 19
  TREE_TWO_TALENTS = 19  
  
  RACES = ["Human", "Gnome", "Dwarf", "Night Elf", "Worgen", "Troll", "Orc", "Goblin", "Undead"]
  REGIONS = ["us", "eu", "kr", "tw", "cn"]
  CLASSES = ["Rogue"]
  
   #validates_inclusion_of :race, :in => RACES
  #validates_inclusion_of :player_class, :in => CLASSES
  # validates_inclusion_of :region, :in => REGIONS
  validates_length_of :name, :maximum => 30
  validates_length_of :realm, :maximum => 30
  validates_numericality_of :level, :less_than_or_equal_to => 85, :greater_than => 0
  
  embeds_many :loadouts
  
  def first_talent_group
    if talentGroup = self.talents["talentGroup"]    
      talentGroup.is_a?(Array) ? talentGroup.first : talentGroup
    end
  end
  
  def update_from_armory!(force = false)
    if self.properties.nil? or force
      self.properties = ArmoryResource::Character.fetch(name, realm, region)
      self.talents = ArmoryResource::Talents.fetch(name, realm, region)
    end
    if properties.nil? or properties["character"].nil?
      raise NotFoundException
    end
    self.player_class = properties["character"]["class"]
    self.race = properties["character"]["race"]
    self.level = properties["character"]["level"].to_i
    gear = Hash[*properties["characterTab"]["items"]["item"].map do |item|
      i = Item.find_or_create_by(:remote_id => item["id"].to_i)
      Item.find_or_create_by(:remote_id => item["gem0Id"]) unless item["gem0Id"].to_i == 0
      Item.find_or_create_by(:remote_id => item["gem1Id"]) unless item["gem0Id"].to_i == 0
      Item.find_or_create_by(:remote_id => item["gem2Id"]) unless item["gem0Id"].to_i == 0
      [item["slot"].to_s, {:item => i, :slot => item["slot"], :item_id => i.remote_id, :gem0 => item["gem0Id"], :gem1 => item["gem1Id"], :gem2 => item["gem2Id"], :enchant => item["permanentenchant"].to_i} ]
    end.flatten]
    items = gear.map {|k, g| g.delete(:item) }.compact
    puts items.inspect
    puts gear.inspect
    # gear.keys.each {|k| gear[k] = gear[k][:item].remote_id }
    # gear = properties["characterTab"]["items"]["item"]
    
    glyphs = []
    if group = first_talent_group
      glyphs = group["glyphs"]
      raw_talents = group["talentSpec"]["value"]
      talents = Hash[*(0..raw_talents.length-1).map {|l| [TALENTS[l], raw_talents[l].to_i] }.flatten]
    end
    self.loadouts.create(:gear => gear, :items => items, :glyphs => glyphs, :talents => talents)
  end
  
  def as_json(options = {})
    professions = {}
    [properties["characterTab"]["professions"]["skill"]].flatten.each do |skill|
      professions[skill["key"]] = true
    end
    {
      :gear   => loadouts.first.gear,
      :talents => Hash[*[self.talents["talentGroup"]].flatten.map {|g| ["Imported #{g["prim"]}", g["talentSpec"]["value"]] }.flatten],
      :name   => name,
      :race   => race,
      :realm  => realm,      
      :region => region,
      :options => {
        :general => {
          :level => level
        },
        :professions => professions
      }
    }
  end
end
