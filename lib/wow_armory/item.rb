module WowArmory
  class Item
    unloadable

    @item_enchants = nil
    @item_upgrades = nil
    @upgrade_rulesets = nil

    include Constants
    include Document
    ACCESSORS = :stats, :icon, :id, :name, :equip_location, :ilevel, :quality, :requirement, :tag, :socket_bonus, :sockets, :gem_slot, :speed, :dps, :subclass, :armor_class, :upgradable, :bonus_trees, :chance_bonus_lists
    attr_accessor *ACCESSORS
    
    def initialize(id, source = 'wowapi', name = nil, context = '', bonus_trees = [], override_ilvl = nil)
      self.name = name
      self.ilevel = override_ilvl
      self.bonus_trees = bonus_trees

      if id == :empty || id == 0 || id.nil?
        @id = :empty
        return
      else
        @id = id.to_i
      end

      case source
        when 'wowapi'
          url =  if context == ''
            '/wow/item/%d' % id
          else
            '/wow/item/%d/%s' % [id,context]
          end
          params = {
              :bl => bonus_trees.join(',')
          }
          @json = WowArmory::Document.fetch 'us', url, params, :json
          populate_base_data
        when 'wowhead'
          populate_base_data_wowhead
        when 'wowhead_ptr'
          populate_base_data_wowhead('ptr')
        else
          puts 'ERROR: source not valid'
          return
      end

      self.upgradable = WowArmory::Item.check_upgradable(id)
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

    def populate_base_data
      self.name ||= @json['name']
      self.quality = @json['quality']
      self.equip_location = @json['inventoryType']
      self.ilevel ||= @json['itemLevel']
      self.icon = @json['icon']

      if @json['hasSockets']
        self.sockets = []
        sockets = @json['socketInfo']['sockets']
        sockets.each do |socket|
          self.sockets.push socket['type'].capitalize
        end
        unless @json['socketInfo']['socketBonus'].nil?
          self.socket_bonus = scan_str(@json['socketInfo']['socketBonus'])
        end
      end
      unless @json['nameDescription'].nil?
        self.tag = @json['nameDescription']
      end
      if @json['itemClass'] == 3 # gem
        puts 'Gem = True'
        if @json['gemInfo'].nil?
          self.stats = {}
        else
          self.gem_slot = @json['gemInfo']['type']['type'].capitalize
          self.stats = scan_str(@json['gemInfo']['bonus']['name'])
          puts 'stats from api'
          puts self.stats.inspect
        end
      elsif @json['itemClass'] == 4 # armor
        self.armor_class ||= ARMOR_CLASS[@json['itemSubClass']]
      end

      unless @json['bonusStats'].nil?
        self.stats = {}
        @json['bonusStats'].each do |entry|
            unless STAT_LOOKUP.has_key?(entry['stat'])
              puts "STAT ID missing: #{entry['stat']}"
              next
            end
            self.stats[STAT_LOOKUP[entry['stat']]] = entry['amount']
        end
      end

      if @json['bonusSummary']['chanceBonusLists'].nil?
        self.chance_bonus_lists = []
      else
        self.chance_bonus_lists = @json['bonusSummary']['chanceBonusLists']
      end

      @json['bonusSummary']['defaultBonusLists'].each do |bonusId|
        if [486, 487, 488, 489, 490].include? bonusId then
          self.chance_bonus_lists.push(bonusId)
        end
      end

      unless @json['weaponInfo'].nil?
        self.speed = @json['weaponInfo']['weaponSpeed'].to_f
        self.dps = @json['weaponInfo']['dps'].to_f
        self.subclass = @json['itemSubClass']
      end

      self.upgradable = WowArmory::Item.check_upgradable(@json['id'])
      puts "populate_base_data: upgradable = #{self.upgradable}"
    end

    def populate_base_data_wowhead(prefix = 'www')
      doc = Nokogiri::XML open("http://#{prefix}.wowhead.com/item=%d&xml" % @id, 'User-Agent' => 'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:27.0) Gecko/20100101 Firefox/27.0').read
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
      # The header on the ItemUpgrade data looks like (as of 6.2.3):
      # id,upgrade_group,upgrade_ilevel,prev_id,id_currency_type,cost
      # We only care about the prev_id and id_currency_type ones
      @@item_upgrades ||= Hash.new.tap do |hash|
        CSV.foreach(File.join(File.dirname(__FILE__), 'data', 'ItemUpgrade.dbc.csv')) do |row|
          row3 = row[3].to_i
          row4 = row[4].to_i
          if row3 != 0 and row4 != 0
            hash[row3.to_s] = row4
          end
        end
      end
    end

    def self.upgrade_rulesets
      # The header on the RulesetItemUpgrade data looks like (as of 6.2.3):
      # id,upgrade_level,id_upgrade_base,id_item
      # We only care about the last two of these.
      @@upgrade_rulesets ||= Hash.new.tap do |hash|
        CSV.foreach(File.join(File.dirname(__FILE__), 'data', 'RulesetItemUpgrade.dbc.csv')) do |row|
          hash[row[3]] = row[2].to_i
        end
      end
    end

  end
end
