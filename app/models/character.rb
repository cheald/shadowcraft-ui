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
        Item.check_item_for_import(item['id'].to_i, item['context'])
        item['gems'].each do |gemid|
          unless gemid.nil? or gemid == 0
            db_item = Item.check_gem_for_import(gemid.to_i)
          end
        end
      end
    end
  end

  # Converts character properties to json format
  def as_json(options = {})
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
      :artifact => {
        'a': {
          :relics => [0,0,0],
          :traits => {'214368':0,'192657':0,'192326':0,'192923':0,'192323':0,'192428':0,'192759':0,'192329':0,'192318':0,'192349':0,'192376':0,'192315':0,'192422':0,'192345':0,'192424':0,'192310':0,'192384':0}
        },
        'Z': {
          :relics => [0,0,0],
          :traits => {'216230':0,'202507':0,'202628':0,'202897':0,'202769':0,'202665':0,'202463':0,'202521':0,'202755':0,'202524':0,'202514':0,'202907':0,'202530':0,'202533':0,'202820':0,'202522':0,'202753':0}
        },
        'b': {
          :relics => [0,0,0],
          :traits => {'209835':0,'197241':0,'197233':0,'197604':0,'197239':0,'197256':0,'197406':0,'197369':0,'197244':0,'209782':0,'197234':0,'197235':0,'197231':0,'197610':0,'221856':0,'209781':0,'197386':0}
        },
      }
    }
  end

  # encode player items to a unique identifier for the frontend
  # TODO subject to change, item handling will definitely change in the future
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
