class Character
  include Mongoid::Document
  include Mongoid::Timestamps
  include WowArmory::Document
  include WowArmory::Constants
  extend WowArmory::Document

  field :name
  field :realm
  field :region
  field :properties, :type => Hash
  field :portrait
  field :uid
  field :data_version

  index({uid: 1}, {unique: true})

  DEFAULT_ARTIFACT_TRAITS = {'a' => 192759, 'Z' => 202665, 'b' => 209782}
  REGIONS = ['US', 'EU', 'KR', 'TW', 'CN', 'SEA']
  CLASSES = ['rogue']
  MAX_LEVEL = 110
  CURRENT_DATA_VERSION = 4

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

  def outdated?
    self.data_version != CURRENT_DATA_VERSION
  end

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

      # iterate over the player's gear and import any items or gems that are missing
      properties['gear'].each do |slot, item|

        # don't do this for artifact weapons. for some reason they come in the character data
        # with a "scenario-normal" context, but the item data doesn't have that context on
        # them.
        if !Item::ARTIFACT_WEAPONS.include? item['id'].to_i
          Item.check_item_for_import(item['id'].to_i, item['context'])
        end

        # Make sure all of the gems exist in the database though.
        item['gems'].each do |gemid|
          unless gemid.nil? or gemid == 0
            db_item = Item.check_gem_for_import(gemid.to_i)
          end
        end

        # Don't do the rest of this bonus ID switching stuff for artifact weapons
        next if Item::ARTIFACT_WEAPONS.include? item['id'].to_i

        # This is dumb, but we have to fix a bunch of bonus IDs on the player's gear
        # too while we're at it. This is because Blizzard's API is broken in a lot of
        # places when it comes to base ilevels and ilevel increases. Unfortunately,
        # we also have to save the original set because otherwise tooltips break.
        db_item = Item.where(:remote_id => item['id'].to_i, :contexts => item['context']).first
        if not db_item.nil?
          base_item_level = db_item.item_level
          Rails.logger.debug "Can't find item %d/%s in database" % [item['id'].to_i,item['context']]
        else
          base_item_level = 0
        end
        item['base_ilvl'] = base_item_level
        item['ttBonuses'] = item['bonuses'].clone

        # Now loop through the bonus IDs on the gear entry and make sure that the math works
        # between the item level increases from bonus IDs and the base item level on the
        # database item.
        increase_id = 0
        increase = 0
        item['bonuses'].each do |bonus_id|
          entries = WowArmory::Item.item_bonuses[bonus_id]
          entries.each do |entry|
            if entry[:type] == ITEM_BONUS_TYPES['ilvl_increase']
              increase_id = bonus_id
              increase = entry[:val1]
            end
          end
        end

        next if increase_id == 0

        if item['item_level'] != (base_item_level+increase)
          actual_increase = item['item_level']-base_item_level
          if actual_increase == 0
            # This means that there shouldn't have been a item level increase here to begin
            # with, and that one should be removed.
            item['bonuses'] -= [increase_id]
          else
            # Otherwise we need to find what the right ID should have been and replace it.
            # The IDs for ilvl increases go from 1372-1672 which mean (-100 to +200).
            correct_id = 1472+actual_increase
            index = item['bonuses'].index(increase_id)
            item['bonuses'][index] = 1472+actual_increase
          end
        end
      end

      # We only get artifact data for the current spec from the armory. Null out all of the
      # artifact data for all of the specs, and then copy the artifact data from the armory
      # into the right spot.
      orig_artifact_data = properties['artifact'].clone
      properties['artifact'] = {
        'a' => {
          :relics => [{},{},{}],
          :traits => []
        },
        'Z' => {
          :relics => [{},{},{}],
          :traits => []
        },
        'b' => {
          :relics => [{},{},{}],
          :traits => []
        },
      }
      active_spec = properties['talents'][properties['active']][:spec]

      # The trait rank values we get from the armory include the relic increases. We handle
      # that ourselves in the javascript so remove those. This is ugly and probably slower
      # than necessary due to having to loop over the entire trait space a few times.
      relic_array = [{},{},{}]
      orig_artifact_data['relics'].each do |relic|
        relic_array[relic['socket']] = relic.clone
        relic_array[relic['socket']].delete("socket")

        # look up the relic in the db
        r = Relic.find_by(:remote_id => relic['id'])
        unless r.nil?
          # get the trait increase for the current spec
          trait_from_relic = r["traits"][active_spec]
          orig_artifact_data["traits"].each do |orig_trait|
            if orig_trait['id'] == trait_from_relic['spell']
              orig_trait['rank'] -= trait_from_relic['rank']
            end
          end
        end
      end
      orig_artifact_data['relics'] = relic_array

      # Default the default trait to on. Each artifact comes with 100AP on it, and the first
      # trait costs 100AP, so there is zero reason for it not to just be turned on.
      default = {
        "id" => DEFAULT_ARTIFACT_TRAITS[active_spec],
        "rank" => 1
      }
      orig_artifact_data['traits'].push(default)
      properties['artifact'][active_spec] = orig_artifact_data
      self.data_version = CURRENT_DATA_VERSION
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
      :artifact => properties['artifact']
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
      errors.add :character, "must be level #{MAX_LEVEL} to be supported by Shadowcraft. Check the Armory for your character, since it may not have updated to level 110 yet."
      return false
    end
    true
  end
end
