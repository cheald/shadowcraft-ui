module WowArmory

  require 'csv'

  class Item
    unloadable

    @item_enchants = nil
    @item_upgrades = nil
    @upgrade_rulesets = nil
    @upgrade_multipliers = {}

    include Constants
    include Document
    # TODO: document these with some description of what each one is used for
    ACCESSORS = :stats, :icon, :id, :name, :equip_location, :ilevel, :quality, :socket_bonus, :sockets, :gem_slot, :speed, :dps, :subclass, :armor_class, :upgradable, :upgrade_level, :chance_bonus_lists, :bonus_tree, :tag
    attr_accessor *ACCESSORS

    def initialize(json, json_source='wowapi', upgradable=false, upgrade_level=0)
      self.name = json['name']
      self.ilevel = json['itemLevel'].to_i + upgrade_level*5
      self.upgradable = upgradable
      self.upgrade_level = upgrade_level
      @id = json['id'].to_i

      case json_source
        when 'wowapi'
          populate_base_data_blizzard(json, upgrade_level)
        when 'wowhead', 'wowhead_ptr'
          populate_base_data_wowhead()
        else
          puts 'ERROR: source not valid'
          return
      end
    end

    def as_json(options = {})
      {}.tap do |r|
        ACCESSORS.map {|key| r[key] = self.send(key) }
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
      if @upgrade_multipliers[upgrade_level].nil?
        @upgrade_multipliers[upgrade_level] =  1.0 / (1.15 ** (-(upgrade_level*5.0) / 15.0))
      end
      return @upgrade_multipliers[upgrade_level]
    end

    # Populates the object data based on json data from a Blizzard API query
    # TODO: go through all of these values and verify that all of the are still
    # necessary.
    def populate_base_data_blizzard(json, upgrade_level)
      self.quality = json['quality']
      self.equip_location = json['inventoryType']
      self.icon = json['icon']

      # If the item has sockets, store a bunch of information about the sockets
      # on the item. This includes a list of the colors of each of the sockets
      # as well as information about socket bonus the item has.
      if json['hasSockets']
        self.sockets = []
        sockets = json['socketInfo']['sockets']
        sockets.each do |socket|
          self.sockets.push socket['type'].capitalize
        end
        unless json['socketInfo']['socketBonus'].nil?
          self.socket_bonus = scan_str(json['socketInfo']['socketBonus'])
        end
      end

      # Tag is the header text on an item that has a description, such as
      # 'warforged' or 'heroic'. This field is used in the display of items.
      unless json['nameDescription'].nil?
        self.tag = json['nameDescription']
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

      # json['bonusStats'] contains a list of the stats on the item itself. if
      # the item is upgradable, this is where we will modify the stats on the
      # item to match the proper values for the upgrade level.
      unless json['itemClass'] == 3 || json['bonusStats'].nil?
        self.stats = {}
        json['bonusStats'].each do |entry|
          unless STAT_LOOKUP.has_key?(entry['stat'])
            puts "STAT ID missing: #{entry['stat']}"
            next
          end

          if (self.upgradable)
            multiplier = get_upgrade_multiplier(upgrade_level)
          else
            multiplier = 1.0
          end

          stat = entry['amount'].to_f*multiplier
          self.stats[STAT_LOOKUP[entry['stat']]] = stat.round.to_i
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
  end
end
