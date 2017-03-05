module WowArmory

  require 'csv'

  class Item
    unloadable

    @item_enchants = nil
    @item_upgrades = nil
    @upgrade_rulesets = nil

    include Constants
    include Document
    # TODO: document these with some description of what each one is used for
    ACCESSORS = :stats, :icon, :id, :name, :equip_location, :ilevel, :quality, :gem_slot, :speed, :dps, :subclass, :armor_class, :upgradable, :chance_bonus_lists, :bonus_tree, :tag, :context
    attr_accessor *ACCESSORS

    TIER_19_ITEMS = [138326, 138329, 138332, 138335, 138338, 138371]

    def initialize(json, json_source='wowapi')
      self.name = json['name']
      self.ilevel = json['itemLevel'].to_i
      @id = json['id'].to_i

      if TIER_19_ITEMS.include? @id
        self.upgradable = false
      else
        self.upgradable = WowArmory::Item.check_upgradable(@id)
      end

      case json_source
        when 'wowapi'
          populate_base_data_blizzard(json)
        when 'wowhead', 'wowhead_ptr'
          populate_base_data_wowhead()
        else
          puts 'ERROR: source not valid'
          return
      end
    end

    # These fields shouldn't come across in the json data because they end up
    # as duplicates in the mongo records. Also remove a bunch of fields that are
    # meaningless for gems and relics.
    IGNORE_FIELDS = %i{id context ilevel bonus_tree tag}
    IGNORE_FOR_GEMS = %i{speed dps subclass armor_class upgradable chance_bonus_lists equip_location}

    def as_json(options = {})
      if gem_slot
        {}.tap do |r|
          ACCESSORS.map {|key| r[key] = self.send(key) if !IGNORE_FIELDS.include?(key) and !IGNORE_FOR_GEMS.include?(key) }
        end
      else
        {}.tap do |r|
          ACCESSORS.map {|key| r[key] = self.send(key) if !IGNORE_FIELDS.include?(key)}
        end
      end
    end

    # The mapping for upgrades goes as follows:
    # 1. The RulesetItemUpgrade file contains a list of items that can be
    #    upgraded and maps to a ID of the kind of upgrade.
    # 2. The ItemUpgrade file contains a list of kinds of upgrades and maps
    #    from those IDs to the number of upgrades for that kind (via a
    #    chain of previous IDs) and the currency necessary for the upgrade.
    #
    # For ShC, we only care about valor upgrades so we can skip any other
    # kind of upgrade.
    def self.check_upgradable(id)
      if upgrade_rulesets.key?(id.to_s)
        rule = upgrade_rulesets[id.to_s]
        if item_upgrades.key?(rule.to_s)
          currency = item_upgrades[rule.to_s]
          # valor in 6.2.3 is currency type 1191
          if currency == 1191
            return true
          end
        end
      end
      return false
    end

    private

    # Returns a multiplier used for re-calculating stats on an item used in
    # valor upgrades.
    def get_upgrade_multiplier(upgrade_level=0)
      @@upgrade_multipliers ||= []
      if @@upgrade_multipliers[upgrade_level].nil?
        @@upgrade_multipliers[upgrade_level] =  1.0 / (1.15 ** (-(upgrade_level*5.0) / 15.0))
      end
      return @@upgrade_multipliers[upgrade_level]
    end

    # Populates the object data based on json data from a Blizzard API query
    # TODO: go through all of these values and verify that all of the are still
    # necessary.
    def populate_base_data_blizzard(json)
      self.quality = json['quality']
      self.equip_location = json['inventoryType']
      self.icon = json['icon']

      # Special case legendary rings, since they don't come with a context in
      # the item data (but do when you get them with character data!)
      if ([124636, 142469, 139933, 139958].include? json['id'].to_i)
        self.context = "quest-reward"
      else
        self.context = json['context']
      end

      # Tag is the header text on an item that has a description, such as
      # 'warforged' or 'heroic'. This field is used in the display of items.
      unless json['nameDescription'].nil?
        self.tag = json['nameDescription']
      end

      # For some reason tags aren't getting set from the armory data for certain
      # contexts. Make sure that they're set.
      if self.tag.nil?
        if json['context'].end_with? '-mythic'
          self.tag = 'Mythic'
        elsif json['context'].end_with? '-heroic'
          self.tag = 'Heroic'
        elsif json['context'].end_with? '-normal'
          self.tag = ''
        elsif json['context'] == 'raid-finder'
          self.tag = 'Raid Finder'
        end
      end

      if json['itemClass'] == 3 # gem
        if json['gemInfo'].nil?
          self.stats = {}
        else
          self.gem_slot = json['gemInfo']['type']['type'].capitalize
          self.stats = scan_str(json['gemInfo']['bonus']['name'])
        end
      elsif json['itemClass'] == 4 # armor
        # Armor class is the type of item (cloth/leather/mail/plate). It's
        # only set to something if the itemClass is armor.
        self.armor_class ||= ARMOR_CLASS[json['itemSubClass']]
      end

      unless json['itemClass'] == 3 || json['bonusStats'].nil?
        self.stats = {}
        json['bonusStats'].each do |entry|
          unless STAT_LOOKUP.has_key?(entry['stat'])
            puts "STAT ID missing: #{entry['stat']}"
            next
          end
          self.stats[STAT_LOOKUP[entry['stat']]] = entry['amount']
        end
      end

      # If an item has chanceBonusLists, then it's an item that can have
      # various bonuses attached to it like item sockets, random enchantments,
      # etc. Store these with the item if they exist so they can be displayed
      # on the popup for the item.
      if json['bonusSummary']['chanceBonusLists'].nil?
        self.chance_bonus_lists = []
      else
        self.chance_bonus_lists = json['bonusSummary']['chanceBonusLists']
      end

      # Also store the bonusLists for the item, since this will be used for
      # displaying the right tooltips.
      # for tooltips.
      if json['bonusLists'].nil?
        self.bonus_tree = []
      else
        self.bonus_tree = json['bonusLists']
      end

      # TODO: what is this for? These 5 bonus IDs are for the 100% secondary
      # stat bonuses.
      json['bonusSummary']['defaultBonusLists'].each do |bonusId|
        if [486, 487, 488, 489, 490].include? bonusId then
          self.chance_bonus_lists.push(bonusId)
        end
      end

      # If this item is a weapon, we need to store a little bit of information
      # about it.
      unless json['weaponInfo'].nil?
        self.speed = json['weaponInfo']['weaponSpeed'].to_f
        self.dps = json['weaponInfo']['dps'].to_f
        self.subclass = json['itemSubClass']
      end

    end

    # Populates the object data based on json data from a Wowhead query
    def populate_base_data_wowhead(prefix = 'www')
      doc = Nokogiri::XML open("http://#{prefix}.wowhead.com/item=%d&xml" % @id, 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36').read
      eqstats = JSON::load('{%s}' % doc.css('jsonEquip').text)
      stats = JSON::load('{%s}' % doc.css('json').text)
      unless doc.css('error').blank?
        puts prefix
        puts doc.inspect
        puts "Item not found on wowhead id #{@id}"
        return
        #raise Exception.new "Item not found on wowhead id #{@id}"
      end
      self.name ||= doc.css('name').text
      self.quality = doc.xpath('//quality').attr('id').text.to_i
      self.equip_location = doc.xpath('//inventorySlot').attr('id').text.to_i
      self.ilevel ||= doc.css('level').text.to_i
      self.icon = doc.css('icon').text.downcase
      self.tag = ''
      unless stats['namedesc'].nil?
        self.tag = stats['namedesc']
      end
      if stats['classs'] == 3 # gem
        puts 'Gem = True'
        self.gem_slot = GEM_SUBCLASS_MAP[stats['subclass'].to_i]
        self.stats = {}
        eqstats.each do |stat, val|
         stat2 = WOWHEAD_STAT_MAP[stat]
         unless stat2.nil?
           self.stats[stat2] = val
         end
        end
        puts self.stats.inspect
      elsif stats['classs'] == 4
        self.armor_class = ARMOR_CLASS[stats['subclass']]
      end
      unless eqstats['nsockets'].nil?
        self.sockets = []
        (1..eqstats['nsockets'].to_i).each { |num|
          self.sockets.push(SOCKET_MAP[eqstats["socket#{num}"]])
        }
        unless eqstats['socketbonus'].nil?
          self.socket_bonus = {}
          enchant_row = item_enchants[eqstats['socketbonus'].to_s]
          # TODO if socketbonus includes more than 1 stat update this
          stat = enchant_row[14].to_i
          value = enchant_row[17].to_f * ENCHANT_SCALING
          self.socket_bonus[STAT_LOOKUP[stat]] = value.round
        end
      end
      unless eqstats['mlespeed'].blank? && eqstats['speed'].blank?
        self.speed = (eqstats['mlespeed'] || eqstats['speed']).to_f
        self.dps = (eqstats['mledps'] || eqstats['dps']).to_f
        self.subclass = stats['subclass'].to_i
      end
      if not stats["upgrades"].nil? && self.ilevel >= 458
        self.upgradable = true
      else
        self.upgradable = false
      end
    end

    # This method takes a string like "+4 Critical Strike" and turns it into a
    # hash of two values. The values are the attribute being modified and the
    # value of the modifier.
    def scan_str(str)
      map = SCAN_ATTRIBUTES.map do |attr|
        if str =~/\+(\d+) (#{attr})/i
          qty = $1.to_i
          [(SCAN_OVERRIDE[attr] || attr).gsub(/ /, '_').to_sym, qty]
        elsif str =~/Equip:.*(#{attr}) by (\d+)/i
          qty = $2.to_i
          [(SCAN_OVERRIDE[attr] || attr).gsub(/ /, '_').to_sym, qty]
        else
          nil
        end
      end.compact
      Hash[*map.flatten]
    end

    def item_enchants
      @@item_enchants ||= Hash.new.tap do |hash|
        CSV.foreach(File.join(File.dirname(__FILE__), 'data', 'SpellItemEnchantments.dbc.csv')) do |row|
          hash[row[0].to_s] = row
        end
      end
    end

    # item_upgrades and upgrade_rulesets are used to determine if a piece of gear is
    # eligible for a valor upgrade. They are used in the check_upgradable method.
    def self.item_upgrades
      # The header on the ItemUpgrade data looks like (as of 7.0.3):
      # id,cost,prev_id,id_currency_type,upgrade_group,upgrade_ilevel
      # We only care about the prev_id and id_currency_type ones
      @@item_upgrades ||= Hash.new.tap do |hash|
        CSV.foreach(File.join(File.dirname(__FILE__), 'data', 'ItemUpgrade.dbc.csv')) do |row|
          prev_id = row[2].to_i
          currency_type = row[3].to_i
          if prev_id != 0 and currency_type != 0
            hash[prev_id.to_s] = currency_type
          end
        end
      end
    end

    def self.upgrade_rulesets
      # The header on the RulesetItemUpgrade data looks like (as of 7.0.3):
      # id,id_item,id_upgrade_base
      # We only care about the last two of these.
      @@upgrade_rulesets ||= Hash.new.tap do |hash|
        CSV.foreach(File.join(File.dirname(__FILE__), 'data', 'RulesetItemUpgrade.dbc.csv')) do |row|
          hash[row[1]] = row[2].to_i
        end
      end
    end

    def self.item_bonuses
      @@item_bonuses ||= Hash.new.tap do |hash|
        CSV.foreach(File.join(Rails.root, 'lib', 'wow_armory', 'data', 'ItemBonus.dbc.csv')) do |row|
          id_node = row[3].to_i
          unless hash.has_key? id_node
            hash[id_node] = []
          end
          entry = {
            :type => row[4].to_i,
            :val1 => row[1].to_i,
            :val2 => row[2].to_i
          }

          # Bonus Types (value of column 4):
          # 1 = Item level increase.
          # 2 = Stat.  This is for items with random stats.  Take the value of column 4 and
          #     replace it with the stat from the STAT_LOOKUP array in WowArmory::Constants
          # 5 = Name (heroic, stages, etc).  Take the value of column 4 and replace it with
          #     the name from the item from the item_name_description lookup.  This pulls data
          #     from the WoD_ItemNameDescription.csv file.  These entries are used to display
          #     the green text next to items in the list.
          # 6 = Socket.  Take the value of column 4 and replace it with the socket type from
          #     the SOCKET_MAP array in WowArmory::Constants.
          if entry[:type] == ITEM_BONUS_TYPES['random_stat']
            if STAT_LOOKUP[entry[:val1]]
              entry[:val1] = STAT_LOOKUP[entry[:val1]]
            end
          elsif entry[:type] == ITEM_BONUS_TYPES['name']
            entry[:val1] = item_name_description[entry[:val1]]
          elsif entry[:type] == ITEM_BONUS_TYPES['socket']
            entry[:val2] = SOCKET_MAP[entry[:val2].to_i]
          elsif entry[:type] == ITEM_BONUS_TYPES['ilvl_increase']
            entry.delete(:val2)
          elsif entry[:type] == ITEM_BONUS_TYPES['base_ilvl']
            entry.delete(:val2)
          end
          hash[id_node].push entry
        end
      end
    end

    def self.item_name_description
      @@item_name_description ||= Hash.new.tap do |hash|
        CSV.foreach(File.join(Rails.root, 'lib', 'wow_armory', 'data', 'ItemNameDescription.dbc.csv')) do |row|
          # for some reason all of the values in this table have '' around every string. remove
          # those and just store the strings.
          text = row[1]
          if text[0] == '\''
            text = text[1..-1]
          end
          if text[-1,1] == '\''
            text = text.chomp('\'')
          end
          hash[row[0].to_i] = text
        end
      end
    end

  end
end
