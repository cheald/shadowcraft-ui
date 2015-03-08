module WowArmory
  class Item
    unloadable

    @item_enchants = nil
    @item_bonus_map = nil
    @item_bonus_trees = nil
    @item_hotfixes = nil
    @rand_prop_points = nil

    STAT_LOOKUP = {
        49=>:mastery,
        38=>:attack_power,
        5=>:intellect,
        44=>:armor_penetration,
        33=>:hit_avoidance,
        6=>:spirit,
        12=>:defense,
        45=>:power,
        34=>:critical_strike_avoidance,
        1=>:health,
        7=>:stamina,
        3=>:agility,
        2=>:mana,
        13=>:dodge,
        46=>:health_every_5_seconds,
        57=>:pvp_power,
        35=>:pvp_resilience,
        41=>:damage_done,
        14=>:parry,
        36=>:haste,
        47=>:penetration,
        31=>:hit,
        42=>:healing_done,
        4=>:strength,
        37=>:expertise,
        15=>:shield_block,
        48=>:block_value,
        32=>:crit,
        43=>:mana_every_5_seconds,
        71=>:agility,
        72=>:agility,
        73=>:agility,
        40=>:versatility,
        59=>:multistrike,
        58=>:amplify,
        50=>:bonus_armor,
        63=>:avoidance,
        67=>:versatility
    }

    WOWHEAD_MAP = {
      'hitrtng' => 'hit',
      'hastertng' => 'haste',
      'critstrkrtng' => 'crit',
      'mastrtng' => 'mastery',
      'exprtng' => 'expertise',
      'agi' => 'agility',
      'sta' => 'stamina',
      'pvppower' => 'pvp_power',
      'resirtng' => 'pvp_resilience',
      'multistrike' => 'multistrike',
      'versatility' => 'versatility'
    }

    # redundant to character.rb
    PROF_MAP = {
      755 => 'jewelcrafting',
      164 => 'blacksmithing',
      165 => 'leatherworking',
      333 => 'enchanting',
      202 => 'engineering',
      171 => 'alchemy',
      197 => 'tailoring',
      773 => 'inscription',
      182 => 'herbalism',
      186 => 'mining',
      393 => 'skinning'
    }

    ARMOR_CLASS = {
      1 => 'Cloth',
      2 => 'Leather',
      3 => 'Mail',
      4 => 'Plate'
    }

    SUFFIX_NAME_MAP = {
      133 => 'of the Stormblast',
      134 => 'of the Galeburst',
      135 => 'of the Windflurry',
      136 => 'of the Zephyr',
      137 => 'of the Windstorm',
      336 => '[Crit]',
      337 => '[Hit]',
      338 => '[Exp]',
      339 => '[Mastery]',
      340 => '[Haste]',
      344 => 'of the Decimator', # 5.3 Barrens
      345 => 'of the Unerring',
      346 => 'of the Adroit',
      347 => 'of the Savant',
      348 => 'of the Impatient', # 5.3 Barrens
      353 => 'of the Stormblast', # 5.3 Stormblast - Agi
      354 => 'of the Galeburst', # 5.3 Galeburst - Agi
      355 => 'of the Windflurry', # 5.3 Windflurry - Agi
      356 => 'of the Windstorm', # 5.3 Windstorm - Agi
      357 => 'of the Zephyr', # 5.3 Zephyr - Agi
    }

    SOCKET_MAP = {
      1 => 'Meta',
      2 => 'Red',
      8 => 'Blue',
      4 => 'Yellow',
      14 => 'Prismatic',
      16 => 'Hydraulic',
      32 => 'Cogwheel'
    }

    GEM_SUBCLASS_MAP = {
      0 => 'Red',
      1 => 'Blue',
      2 => 'Yellow',
      3 => 'Purple',
      4 => 'Green',
      5 => 'Orange',
      6 => 'Meta',
      #7 => "Simple",
      8 => 'Prismatic',
      9 => 'Hydraulic',
      10 => 'Cogwheel'
    }

    EQUIP_LOCATIONS = {
      'head' => 1,
      'neck' => 2,
      'shoulder' => 3,
      'shirt' => 4,
      'chest' => 5,
      'robe' => 5,
      'waist' => 6,
      'legs' => 7,
      'feet' => 8,
      'wrists' => 9,
      'hands' => 10,
      'finger' => 11,
      'trinket' => 12,
      'back' => 16,
      'main-hand' => 21,
      'one-hand' => 21,
      'two-hand' => 17,
      'off-hand' => 22,
      'shield' => 14,
      'held in off hand' => 23,
      'ranged' => 15,
      'relic' => 28,
      'thrown' => 25
    }

    WEAPON_SUBCLASSES = {
      'axe' => 0,
      'sword' => 7,
      'mace' => 4,
      'fist weapon' => 13,
      'dagger' => 15,
    }

    ENCHANT_SCALING = 10.0 # for lvl 90 // lvl100 = 80

    include Document
    ACCESSORS = :stats, :icon, :id, :name, :equip_location, :ilevel, :quality, :requirement, :tag, :socket_bonus, :sockets, :gem_slot, :speed, :dps, :subclass, :armor_class, :upgradable, :bonus_trees, :chance_bonus_lists
    attr_accessor *ACCESSORS
    def initialize(id, source = 'wowapi', name = nil, context = '', bonus_trees = [], override_ilvl = nil, is_upgradable = nil)
      self.name = name
      self.ilevel = override_ilvl
      self.bonus_trees = bonus_trees

      if id == :empty or id == 0 or id.nil?
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

      unless is_upgradable.nil?
        self.upgradable = is_upgradable
      end
    end

    def as_json(options = {})
      {}.tap do |r|
        ACCESSORS.map {|key| r[key] = self.send(key) }
      end
    end

    private

    def is_upgradable
      if @json['upgradable'].nil?
        return false
      end
      @json['upgradable']
    end

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
      unless @json['requiredSkill'].nil?
        self.requirement = PROF_MAP[@json['requiredSkill']]
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

      # check if there is hotfix data available
      # FIXME temporary remove hotfix and base item stats overwrite
      if item_hotfixes.has_key? @id.to_s
        puts 'Stats from wowapi:'
        puts self.stats.inspect
        row = item_hotfixes[@id.to_s]
        unless row.nil?
          write_new_stats(row)
          puts 'Overwritten stats with hotfix data:'
          puts self.stats.inspect
        end
      elsif item_stats.has_key? @id.to_s
        puts 'Stats from wowapi:'
        puts self.stats.inspect
        row = item_stats[@id.to_s]
        unless row.nil?
          write_new_stats(row)
          puts 'Overwritten stats with stats data:'
          puts self.stats.inspect
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

      self.upgradable = is_upgradable
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
         stat2 = WOWHEAD_MAP[stat]
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
      unless eqstats['reqskill'].nil?
        self.requirement = PROF_MAP[eqstats['reqskill']]
      end
      unless eqstats['mlespeed'].blank? and eqstats['speed'].blank?
        self.speed = (eqstats['mlespeed'] || eqstats['speed']).to_f
        self.dps = (eqstats['mledps'] || eqstats['dps']).to_f
        self.subclass = stats['subclass'].to_i
      end
      if not stats["upgrades"].nil? and self.ilevel >= 458
        self.upgradable = true
      else
        self.upgradable = false
      end
    end

    def write_new_stats(row)
      base = rand_prop_points[self.ilevel.to_s]
      if base.nil?
        return
      end
      self.stats = {}
      10.times do |i|
        break if row[5+i] == '-1'
        statid = row[5+i] # more or less stat-id
        multiplier = row[25+i].to_f
        basevalue = base[1 + slot_index(self.equip_location)]
        if statid != '0'
          stat = statid.to_i
          value = ((multiplier / 10000.0) * basevalue.to_f).round
          self.stats[STAT_LOOKUP[stat]] = value
        end
      end
    end

    SCAN_ATTRIBUTES = ['agility', 'strength', 'intellect', 'spirit', 'stamina', 'attack power', 'critical strike',
                       'haste', 'mastery', 'pvp resilience', 'pvp power', 'all stats'
    ]
    SCAN_OVERRIDE = { 'critical strike' => 'crit',
                        #"hit" => "hit rating",
                        #"expertise" => "expertise rating",
                        #"haste" => "haste rating",
                        #"mastery" => "mastery rating",
                        #"pvp resilience" => "resilience",
                        #"pvp power" => "pvp power rating"
                      }

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

    def fix_gem_colors(color)
      return nil if color.nil?
      case color
      when 'Red or Yellow'
        return 'Orange'
      when 'Red or Blue'
        return 'Purple'
      when 'Blue or Yellow', 'Yellow or Blue'
        return 'Green'
      else
        color
      end
    end

    def item_enchants
      @@item_enchants ||= Hash.new.tap do |hash|
        FasterCSV.foreach(File.join(File.dirname(__FILE__), 'data', 'WoD_SpellItemEnchantments.csv')) do |row|
          hash[row[0].to_s] = row
        end
      end
    end

    def item_hotfixes
      @@item_hotfixes ||= Hash.new.tap do |hash|
        FasterCSV.foreach(File.join(File.dirname(__FILE__), 'data', 'WoD_item_hotfixes.csv'), { :col_sep => ';' }) do |row|
          hash[row[0].to_s] = row
        end
      end
    end

    def item_stats
      @@item_stats ||= Hash.new.tap do |hash|
        FasterCSV.foreach(File.join(File.dirname(__FILE__), 'data', 'WoD_item_stats.csv'), { :col_sep => ';' }) do |row|
          hash[row[0].to_s] = row
        end
      end
    end

    def rand_prop_points
      @@rand_prop_points ||= Hash.new.tap do |hash|
        FasterCSV.foreach(File.join(File.dirname(__FILE__), 'data', 'WoD_RandPropPoints.csv'), { :col_sep => ';' }) do |row|
          hash[row[0].to_s] = row
        end
      end
    end

    def slot_index(slot)
      case slot
        when 1, 5, 7
          return 0
        when 3, 6, 8, 10, 12
          return 1
        when 2, 9, 11, 16, 22
          return 2
        when 13, 21
          return 3
        when 15
          return 4
        else
          return 2
      end
    end

  end
end
