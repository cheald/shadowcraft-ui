module WowArmory
  class Item
    unloadable

    @random_suffix_csv = nil
    @item_enchants = nil
    @rand_prop_points = nil
    @item_data = nil
    @ruleset_item_upgrade = nil
    @item_damage_one_hand = nil

    # STATS = Hash[*STAT_MAP.split(/\n/).map {|line| x = line.strip.split(" ", 2); [x.last.downcase.gsub(" ", "_").to_sym, x.first.to_i]}.flatten]
    STAT_INDEX = {
      :damage_done                      => 41,
      :dodge_rating                     => 13,
      :spirit                           => 6,
      :block_value                      => 48,
      :critical_strike_avoidance_rating => 34,
      :healing_done                     => 42,
      :parry_rating                     => 14,
      :stamina                          => 7,
      :mastery_rating                   => 49,
      :haste_rating                     => 36,
      :mana_every_5_seconds             => 43,
      :shield_block_rating              => 15,
      :intellect                        => 5,
      :attack_power                     => 38,
      :resilience_rating                => 35,
      :pvp_power_rating                 => 57,
      :armor_penetration                => 44,
      :hit_rating                       => 31,
      :expertise_rating                 => 37,
      :agility                          => 3,
      :mana                             => 2,
      :health                           => 1,
      :health_every_5_seconds           => 46,
      :crit_rating                      => 32,
      :feral_attack_power               => 40,
      :power                            => 45,
      :defense_rating                   => 12,
      :strength                         => 4,
      :penetration                      => 47,
      :hit_avoidance_rating             => 33
    }

    WOWHEAD_MAP = {
      "hitrtng" => "hit_rating",
      "hastertng" => "haste_rating",
      "critstrkrtng" => "crit_rating",
      "mastrtng" => "mastery_rating",
      "exprtng" => "expertise_rating",
      "agi" => "agility",
      "sta" => "stamina",
      "pvppower" => "pvp_power_rating",
      "resirtng" => "resilience_rating"
    }

    SUFFIX_NAME_MAP = {
      133 => "of the Stormblast",
      134 => "of the Galeburst",
      135 => "of the Windflurry",
      136 => "of the Zephyr",
      137 => "of the Windstorm"
    }

    ITEM_SOCKET_COST = 160.0 # TODO 160 is for every item from mop but add the socket cost database

    SOCKET_MAP = {
      1 => "Meta",
      2 => "Red",
      8 => "Blue",
      4 => "Yellow",
      14 => "Prismatic",
      16 => "Hydraulic",
      32 => "Cogwheel"
    }

    EQUIP_LOCATIONS = {
      "head" => 1,
      "neck" => 2,
      "shoulder" => 3,
      "shirt" => 4,
      "chest" => 5,
      "robe" => 5,
      "waist" => 6,
      "legs" => 7,
      "feet" => 8,
      "wrists" => 9,
      "hands" => 10,
      "finger" => 11,
      "trinket" => 12,
      "back" => 16,
      "main-hand" => 21,
      "one-hand" => 21,
      "two-hand" => 17,
      "off-hand" => 22,
      "shield" => 14,
      "held in off hand" => 23,
      "ranged" => 15,
      "relic" => 28,
      "thrown" => 25
    }

    STAT_LOOKUP = Hash[*STAT_INDEX.map {|k, v| [v, k]}.flatten]

    include Document
    ACCESSORS = :stats, :icon, :id, :name, :equip_location, :ori_ilevel, :ilevel, :quality, :requirement, :is_heroic, :socket_bonus, :sockets, :gem_slot, :speed, :subclass, :dps, :armor_class, :random_suffix, :upgradeable, :upgrade_level
    attr_accessor *ACCESSORS
    def initialize(id, random_suffix = nil, upgrade_level = nil, name = nil)
      self.stats = {}
      self.random_suffix = random_suffix
      self.random_suffix = nil if self.random_suffix == 0
      self.upgrade_level = upgrade_level
      self.upgrade_level = nil if self.upgrade_level == 0
      self.name = name

      if id == :empty or id == 0 or id.nil?
        @id = :empty
        return
      else
        @id = id.to_i
      end

      fetch "us", "item/%d/tooltip" % id
      populate_stats
    end

    def as_json(options = {})
      {}.tap do |r|
        ACCESSORS.map {|key| r[key] = self.send(key) }
      end
    end
    
    def is_upgradeable
      row = ruleset_item_upgrade[self.id.to_s]
      if row.nil?
        puts "item not upgradeable #{self.id}"
        return false
      end
      true
    end

    private

    def populate_item_upgrade_level_with_random_suffix
      row = random_suffixes[random_suffix.abs.to_s]
      if row.nil?
        puts "suffix not found in db"
        return
      end
      base = rand_prop_points[self.ilevel.to_s]

      self.stats = {}
      4.times do |i|
        enchantid = row[3+i]
        multiplier = row[8+i].to_f / 10000.0
        basevalue = base[1+quality_index(self.quality)*5+slot_index(equip_location)]
        if enchantid != "0"
          stat = item_enchants[enchantid][8].to_i
          self.stats[STAT_LOOKUP[stat]] = (multiplier * basevalue.to_i).round # round think its correct
        end
      end
      # if weapon update dps
      row2 = item_damage_one_hand[self.ilevel.to_s]
      if not self.speed.nil? and not self.speed.blank?
        self.dps = row2[1+self.quality].to_f # TODO validate if we are accessing the correct column
      end
    end

    def populate_item_upgrade_level
      row = item_data[self.id.to_s]
      if row.nil?
        puts "no item data found"
        return
      end
      base = rand_prop_points[self.ilevel.to_s]
      ori_base = rand_prop_points[self.ori_ilevel.to_s]

      self.stats = {}
      10.times do |i|
        break if row[17+i] == "-1"
        enchantid = row[17+i]
        multiplier = row[37+i].to_f
        socket_mult = row[47+i].to_f
        #puts socket_mult
        #puts multiplier
        #puts slot_index(equip_location)
        basevalue = base[1+quality_index(self.quality)*5+slot_index(equip_location)]
        ori_basevalue = ori_base[1+quality_index(self.quality)*5+slot_index(equip_location)]
        #puts basevalue
        #puts ori_basevalue
        if enchantid != "0"
          stat = enchantid.to_i
          value = (multiplier/10000.0) * basevalue.to_f - socket_mult * ITEM_SOCKET_COST * ( basevalue.to_f / ori_basevalue.to_f )
          puts value
          self.stats[STAT_LOOKUP[stat]] = value.round
          puts STAT_LOOKUP[stat]
          puts self.stats[STAT_LOOKUP[stat]]
        end
      end
      # if weapon update dps
      row2 = item_damage_one_hand[self.ilevel.to_s]
      if not self.speed.nil? and not self.speed.blank?
        self.dps = row2[1+self.quality].to_f # TODO validate if we are accessing the correct column
      end
    end

    def populate_item_upgrade_level2
      ori_base = rand_prop_points[self.ori_ilevel.to_s]
      base = rand_prop_points[self.ilevel.to_s]
      ori_basevalue = ori_base[1+quality_index(self.quality)*5+slot_index(equip_location)]
      basevalue = base[1+quality_index(self.quality)*5+slot_index(equip_location)]
      self.stats.each do |stat, val|
        socket_mult = row[47+i].to_f
        new_val = (val * basevalue.to_f) / ori_basevalue.to_f - socket_mult * ITEM_SOCKET_COST * ( basevalue.to_f / ori_basevalue.to_f )
        self.stats[stat] = new_val.round
      end
      # if weapon update dps
      row2 = item_damage_one_hand[self.ilevel.to_s]
      if not self.speed.nil? and not self.speed.blank?
        self.dps = row2[1+self.quality].to_f # TODO validate if we are accessing the correct column
      end
    end

    def populate_random_suffix_item
      row = random_suffixes[random_suffix.abs.to_s]
      base = rand_prop_points[self.ilevel.to_s]

      self.stats = {}
      4.times do |i|
        enchantid = row[3+i]
        multiplier = row[8+i].to_f / 10000.0
        basevalue = base[1+quality_index(self.quality)*5+slot_index(equip_location)]
        if enchantid != "0"
          stat = item_enchants[enchantid][8].to_i
          self.stats[STAT_LOOKUP[stat]] = (multiplier * basevalue.to_i).round # round think its correct
        end
      end
    end

    def random_suffixes
      @@random_suffix_csv ||= Hash.new.tap do |hash|
        FasterCSV.foreach(File.join(File.dirname(__FILE__), "data", "ItemRandomSuffix.dbc.csv")) do |row|
          hash[row[0].to_s] = row
        end
      end
    end

    def item_enchants
      @@item_enchants ||= Hash.new.tap do |hash|
        FasterCSV.foreach(File.join(File.dirname(__FILE__), "data", "SpellItemEnchantment.dbc.csv")) do |row|
          hash[row[0].to_s] = row
        end
      end
    end

    def rand_prop_points
      @@rand_prop_points ||= Hash.new.tap do |hash|
        FasterCSV.foreach(File.join(File.dirname(__FILE__), "data", "RandPropPoints.dbc.csv")) do |row|
          hash[row[0].to_s] = row
        end
      end
    end

    def item_data
      @@item_data ||= Hash.new.tap do |hash|
        FasterCSV.foreach(File.join(File.dirname(__FILE__), "data", "item_data.csv")) do |row|
          hash[row[0].to_s] = row
        end
      end
    end

    def ruleset_item_upgrade
      @@ruleset_item_upgrade ||= Hash.new.tap do |hash|
        FasterCSV.foreach(File.join(File.dirname(__FILE__), "data", "RulesetItemUpgrade.db2.csv")) do |row|
          hash[row[3].to_s] = row
        end
      end
    end

    def item_damage_one_hand
      @@item_damage_one_hand ||= Hash.new.tap do |hash|
        FasterCSV.foreach(File.join(File.dirname(__FILE__), "data", "ItemDamageOneHand.dbc.csv")) do |row|
          hash[row[0].to_s] = row
        end
      end
    end

    def populate_weapon_stats!
      doc = Nokogiri::XML open("http://www.wowhead.com/item=%d&xml" % @id).read
      eqstats = JSON::load("{%s}" % doc.css("jsonEquip").text)
      stats = JSON::load("{%s}" % doc.css("json").text)
      unless eqstats["mlespeed"].blank? and eqstats["speed"].blank?
        self.speed = (eqstats["mlespeed"] || eqstats["speed"]).to_f
        self.dps = (eqstats["mledps"] || eqstats["dps"]).to_f
        self.subclass = stats["subclass"].to_i
      end
    end

    def get_item_stats
      stats = {}
      doc = Nokogiri::XML open("http://www.wowhead.com/item=%d&xml" % @id).read
      eqstats = JSON::load("{%s}" % doc.css("jsonEquip").text)
      stats1 = JSON::load("{%s}" % doc.css("json").text)
      eqstats.each do |stat, val|
        stat2 = WOWHEAD_MAP[stat]
        unless stat2.nil?
          stats[stat2] = val
        end
      end
      stats
    end

    def is_hydraulic_gem
      doc = Nokogiri::XML open("http://www.wowhead.com/item=%d&xml" % @id).read
      eqstats = JSON::load("{%s}" % doc.css("jsonEquip").text)
      stats1 = JSON::load("{%s}" % doc.css("json").text)
      ret = false
      if stats1["classs"] == 3 and stats1["subclass"] == 9
        ret = true
      end
      ret
    end

    def populate_stats
      self.name ||= value("h3")
      lis = @document.css(".item-specs li")
      self.quality = attr("h3", "class").match(/color-q(\d)/).try(:[], 1).try(:to_i)
      self.equip_location = lis.text.map {|e| EQUIP_LOCATIONS[e.strip.downcase] }.compact.first
      self.ilevel = lis.text.map {|e| e.match(/Item Level (\d+)/).try(:[], 1) }.compact.first.try(:to_i)
      self.icon = attr("span.icon-frame", "style").match(/(http.*)"/)[1]
      if bonus = @document.css("li.color-d4").text.detect {|li| li.match(/Socket Bonus:/) }.try(:strip)
        self.socket_bonus = scan_str(bonus)
      end
      self.sockets = @document.css(".icon-socket").map {|span| span.attr("class").match(/socket-(\d+)/).try(:[], 1).try(:to_i) }.compact.map {|s| SOCKET_MAP[s] }
      self.requirement = lis.map {|li| li.text.match(/Requires ([a-z]+) \(/i) }.compact.first.try(:[], 1)
      self.is_heroic = value(".color-tooltip-green").try(:strip) == "Heroic"
      self.gem_slot = fix_gem_colors lis.map {|t| t.text.match(/Matches a ([a-z ]+) socket/i).try(:[], 1) }.compact.first
      self.gem_slot ||= lis.map {|t| t.text.match(/Only fits in a (Cogwheel|Meta) (socket|gem slot)/i).try(:[], 1) }.compact.first.try(:humanize)
      self.gem_slot = "Hydraulic" if is_hydraulic_gem
  
      self.armor_class ||= lis.map {|t| t.text.strip.match(/(^|\s)(Plate|Mail|Leather|Cloth)($|\s)/).try(:[], 2) }.compact.first
      
      if weapon_type = lis.text.map {|e| e.strip.match(/^(Dagger|Mace|Axe|Thrown|Wand|Bow|Gun|Crossbow|Fist Weapon|Sword)$/)}.compact.first
        populate_weapon_stats!
      end

      # this is probably a bit overkill but working quite good
      # 1. if random_suffix found populate stats from random suffix db
      # 2. else load item stats from item_data.csv
      # 3. if nothing found in item_data.csv try wowhead
      # 4. if nothing found on wowhead try battle.net tooltip
      # 5. if upgrade_level and have stats
      # 6.  - if item is upgradeable TODO
      # 7.  - set new ilevel
      # 8.  - if step#2 found nothing use alternative stat calculation which has rounding issues (FIXME need all items in item_data.csv from item-sparse file)
      # 
      self.ori_ilevel = self.ilevel
      unless self.random_suffix.nil?
        puts "populate random items"
        puts self.random_suffix
        populate_random_suffix_item
        puts self.stats.inspect
        if !self.name.include? 'of the'
          self.name += " #{SUFFIX_NAME_MAP[self.random_suffix.abs]}"
        end
      else 
        populate_item_upgrade_level
      end
      found_in_item_data = true
      if self.stats.nil? or self.stats.blank?
        found_in_item_data = false
        self.stats = get_item_stats # wowhead
      end
      if self.stats.nil? or self.stats.blank?
        self.stats = scan_stats # battle.net tooltip
      end
      self.upgradeable = self.is_upgradeable
      if not self.upgrade_level.nil? and not self.stats.blank? and self.upgradeable
        if self.quality == 4
          upgrade_levels = 4
        else
          upgrade_levels = 8
        end
        self.ilevel = self.ilevel + self.upgrade_level * upgrade_levels
        if found_in_item_data and self.random_suffix.nil?
          populate_item_upgrade_level
        elsif found_in_item_data and not self.random_suffix.nil?
          populate_item_upgrade_level_with_random_suffix
          puts self.stats.inspect
        else
          puts "have to use not accurate method for itemid #{self.id}"
          populate_item_upgrade_level2 # FIXME not accurate due to rounding issues, need to get rid of this option
        end
      end
    end

    SCAN_ATTRIBUTES = ["agility", "strength", "intellect", "spirit", "stamina", "attack power", "critical strike", "hit", "expertise",
                       "haste", "mastery", "pvp resilience", "pvp power", "all stats", "dodge", "block", "parry"
    ]
    SCAN_OVERRIDE = { "critical strike" => "crit rating", 
                        "hit" => "hit rating",
                        "expertise" => "expertise rating",
                        "haste" => "haste rating",
                        "mastery" => "mastery rating",
                        "pvp resilience" => "resilience rating",
                        "pvp power" => "pvp power rating"
                      }

    def scan_stats
      stats = {}
      @document.css(".item-specs li").each do  |li|
        if li.attr("id").present? and match = li.attr("id").match(/stat-(\d+)/)
          if value = li.text.strip.match(/(\d+)/)
            stat = STAT_LOOKUP[ match[1].to_i ]
            stats[stat] = value[1].to_i
          end
        end

        li.text.strip.split(" and ").each do |chunk|
          scan_str(chunk.strip).each do |stat, val|
            stats[stat] ||= val
          end
        end
      end
      stats
    end

    def scan_str(str)
      map = SCAN_ATTRIBUTES.map do |attr|
        if str =~/\+(\d+) (#{attr})/i
          qty = $1.to_i
          [(SCAN_OVERRIDE[attr] || attr).gsub(/ /, "_").to_sym, qty]
        elsif str =~/Equip:.*(#{attr}) by (\d+)/i
          qty = $2.to_i
          [(SCAN_OVERRIDE[attr] || attr).gsub(/ /, "_").to_sym, qty]
        else
          nil
        end
      end.compact
      Hash[*map.flatten]
    end

    def fix_gem_colors(color)
      return nil if color.nil?
      case color
      when "Red or Yellow"
        return "Orange"
      when "Red or Blue"
        return "Purple"
      when "Blue or Yellow", "Yellow or Blue"
        return "Green"
      else
        color
      end
    end

    def quality_index(quality)
      case quality
      when 2
        return 2
      when 3
        return 1
      when 4
        return 0
      else
        return 0
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
      when 21
        return 3
      when 15
        return 4
      else
        return 2
      end
    end
  end
end
