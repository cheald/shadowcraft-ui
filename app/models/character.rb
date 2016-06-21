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
  field :uid

  index({uid: 1}, {unique: true})

  REGIONS = ['US', 'EU', 'KR', 'TW', 'CN', 'SEA']
  CLASSES = ['rogue']
  MAX_LEVEL = 100

  validates_inclusion_of :region, :in => REGIONS
  validates_presence_of :name, :message => '%{value} could not be found on the Armory.'
  validates_presence_of :realm
  validates_length_of :name, :maximum => 30
  validates_length_of :realm, :maximum => 30
  validates_uniqueness_of :uid
  validates_presence_of :uid
  validates_presence_of :properties, :message => 'empty: could not load character from the Armory.'
  validate :is_supported_class?
  validate :is_supported_level?

  before_validation :update_from_armory!
  before_validation :write_uid

  def to_param
    normalize_realm(realm)
  end

  # Update the character from armory with new data.
  # Called before validation or the character needs to be saved
  def update_from_armory!(force = false)
    self.realm = self.realm.gsub(/-/, ' ')
    self.region = self.region.upcase
    # if properties are missing or a force update is initiated
    if self.properties.nil? or force
      begin
        char = WowArmory::Character.new(name, realm, region)
      rescue WowArmory::ArmoryError => e
        # thrown if character has no items, or no data could be loaded
        Rails.logger.error e.message
        errors.add :base, e.message
        return false
      rescue WowArmory::MissingDocument => e
        # character does not exist
        Rails.logger.error e.message
        errors.add :base, 'Character not found in the Armory'
        return false
      end

      self.properties = char.as_json

      # if properties are still nil stop proceeding
      if self.properties.nil?
        return
      end
      self.properties.stringify_keys!

      # do not load items or set portrait if character class is not supported or is low-level
      return false unless is_supported_class?
      return false unless is_supported_level?

      self.portrait = char.portrait

      # iterate over the player's gear and import any items or gem that are missing
      properties['gear'].each do |slot, item|
        Item.check_for_import(item['item_id'].to_i, item['item_level'].to_i)
        item['gems'].each do |gemid|
          unless gemid.nil?
            db_item = Item.check_for_import(gemid.to_i, 0, true)
          end
        end
      end
    end
  end

  # Converts character properties to json format
  def as_json(options = {})
    #Rails.logger.debug Character.encode_random_items(properties["gear"]).inspect
    {
      :gear => properties['gear'],
      :talents => properties['talents'],
      :active => if not properties['active'].nil?
                   properties['active']
                 elsif not properties['active_talents'].nil?
                   properties['active_talents']
                 else
                   0
                 end,
      :options => {
        :general => {
          :level => properties['level'],
          :race => properties['race']
        },
      },
      :achievements => properties['achievements'],
      :quests => properties['quests']
    }
  end

  # encode player items to a unique identifier for the frontend
  # TODO subject to change, item handling will definitive change in the future
  def self.encode_items(items)
    items.clone.tap do |copy|
      copy.each do |key, item|
        suffix = item.include?('suffix')
        upgrade_level = item.include?('upgrade_level')
        if suffix
          item['item_id'] = item['item_id'] * 1000 + item['suffix'].to_i.abs
          if upgrade_level and item['upgrade_level'] > 0
            item['item_id'] = item['item_id'] * 1000 + item['upgrade_level'].to_i.abs
          end
        elsif upgrade_level and item['upgrade_level'] > 0
          item['item_id'] = item['item_id'] * 1000000 + item['upgrade_level'].to_i.abs
        end
      end
    end
  end

  # Returns the full name of the Character with realm and region
  def fullname
    '%s @ %s-%s' % [name.titleize, realm.titleize, region.upcase]
  end

  # Write the Unique identifier
  def write_uid
    return if region.blank? or realm.blank? or name.blank?
    region.upcase!
    self.uid = Character.uid(region, realm, name)
  end

  # Creates a Unique identifier for the character
  def self.uid(region, realm, name)
    ('%s-%s-%s' % [region.downcase, normalize_realm(realm), normalize_character(name)]).downcase
  end

  # Return the character based on parameters given
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

  # Checks if the class loaded from armory is supported
  def is_supported_class?
    return false unless properties
    return false unless properties['player_class']
    unless CLASSES.include? properties['player_class'].downcase
      errors.add :character, "class '#{properties['player_class']}' is not supported by Shadowcraft. Only rogues are supported."
      return false
    end
    true
  end

  # Checks if the character has the required level
  def is_supported_level?
    return false unless properties
    return false unless properties['level']
    unless properties['level'] == MAX_LEVEL
      errors.add :character, "must be level #{MAX_LEVEL} to be supported by Shadowcraft."
      return false
    end
    true
  end
end
