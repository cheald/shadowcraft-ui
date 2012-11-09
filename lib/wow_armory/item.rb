module WowArmory
  class Item
    unloadable

    @random_suffix_csv = nil
    @item_enchants = nil

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
    ACCESSORS = :stats, :icon, :id, :name, :equip_location, :ilevel, :quality, :requirement, :is_heroic, :socket_bonus, :sockets, :gem_slot, :speed, :subclass, :dps, :armor_class, :random_suffix, :scalar
    attr_accessor *ACCESSORS
    def initialize(id, random_suffix = nil, scalar = nil, name = nil)
      self.stats = {}
      self.random_suffix = random_suffix
      self.random_suffix = nil if self.random_suffix == 0
      self.scalar = scalar > 5000 ? scalar & 65535 : scalar unless scalar.nil?
      self.name = name

      if id == :empty or id == 0 or id.nil?
        @id = :empty
        return
      else
        @id = id.to_i
      end

      Rails.logger.debug "Populating with random suffix: #{random_suffix.inspect}, scalar: #{scalar.inspect}"
      unless random_suffix.nil? or scalar.nil?
        populate_random_suffix_item
      end
      fetch "us", "item/%d/tooltip" % id
      populate_stats
    end

    def as_json(options = {})
      {}.tap do |r|
        ACCESSORS.map {|key| r[key] = self.send(key) }
      end
    end

    private

    def populate_random_suffix_item
      row = random_suffixes[random_suffix.abs.to_s]
      
      self.stats = {}
      4.times do |i|
        enchant = row[3+i]
        scal = row[8+i].to_f / 10000.0
        if enchant != "0"
          stat = item_enchants[enchant][11].to_i
          self.stats[STAT_LOOKUP[stat]] = (scal * self.scalar).floor
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

      self.stats = get_item_stats
      if weapon_type = lis.text.map {|e| e.strip.match(/^(Dagger|Mace|Axe|Thrown|Wand|Bow|Gun|Crossbow|Fist Weapon|Sword)$/)}.compact.first
        populate_weapon_stats!
      end

      if self.stats.nil? or self.stats.blank?
        nodes("ul.item-specs li").each do |spec|
          id = spec.attr("id")
          next if id.nil?
          if attr_type = id.match(/stat-(\d+)/)
            stat = STAT_LOOKUP[attr_type[1].to_i]
            self.stats[stat] = value("span", spec).to_i
          end
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
  end
end
