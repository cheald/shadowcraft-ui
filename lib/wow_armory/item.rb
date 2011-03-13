module WowArmory
  class Item
    unloadable
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

    SOCKET_MAP = {
      1 => "Meta",
      2 => "Red",
      8 => "Blue",
      4 => "Yellow",
      14 => "Prismatic",
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
    ACCESSORS = :stats, :icon, :id, :name, :equip_location, :ilevel, :quality, :requirement, :is_heroic, :socket_bonus, :sockets, :gem_slot, :variants, :speed, :subclass, :dps, :armor_class
    attr_accessor *ACCESSORS
    def initialize(id, variant = nil)
      self.stats = {}
      @variant = variant

      if id == :empty or id == 0 or id.nil?
        @id = :empty
        return
      else
        @id = id.to_i
      end
      self.stats = variant[:stats] unless variant.nil?

      fetch "us", "item/%d/tooltip" % id
      populate_stats
    end

    def as_json(options = {})
      {}.tap do |r|
        ACCESSORS.map {|key| r[key] = self.send(key) }
      end
    end

    def get_variants!
      self.variants = []
      doc = Nokogiri::HTML open("http://www.wowhead.com/item=%d" % @id, "User-Agent" => "Mozilla/5.0 (Windows; Windows NT 6.1) AppleWebKit/534.23 (KHTML, like Gecko) Chrome/11.0.686.3 Safari/534.23").read
      # doc = Nokogiri::HTML open("http://us.battle.net/wow/en/item/%d" % @id).read
      random_header = doc.css("h3").detect {|e| e.text.match(/Random Enchantments/) }
      return self.variants if random_header.nil?
      random_header.next_element.css("li").map(&:text).each do |glob|
        bits = glob.split(/[()]/)
        suffix = bits.first.strip.gsub("...", "")
        stats = scan_str bits.last.strip

        self.variants.push(:suffix => suffix, :stats => stats)
      end
      variants
    end

    private

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

    def populate_stats
      self.name = value("h3")
      self.name += " " + @variant[:suffix] unless @variant.nil?
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
      self.armor_class ||= lis.map {|t| t.text.strip.match(/(^|\s)(Plate|Mail|Leather|Cloth)($|\s)/).try(:[], 2) }.compact.first

      if self.gem_slot
        self.stats = scan_stats
      end
      if weapon_type = lis.text.map {|e| e.strip.match(/^(Dagger|Mace|Axe|Thrown|Wand|Bow|Gun|Crossbow|Fist Weapon|Sword)$/)}.compact.first
        populate_weapon_stats!
      end

      nodes("ul.item-specs li").each do |spec|
        id = spec.attr("id")
        next if id.nil?
        if attr_type = id.match(/stat-(\d+)/)
          stat = STAT_LOOKUP[attr_type[1].to_i]
          self.stats[stat] = value("span", spec).to_i
        end
      end
    end

    SCAN_ATTRIBUTES = ["agility", "strength", "intellect", "spirit", "stamina", "attack power", "critical strike rating", "hit rating", "expertise rating", "crit rating",
                       "haste rating", "armor penetration", "mastery rating", "resilience rating", "all stats", "dodge rating", "block rating", "parry rating"
    ]
    SCAN_OVERRIDE = {"critical strike rating" => "crit rating"}

    def scan_stats
      @document.css(".item-specs li").inject({}) do  |stats, li|
        li.text.strip.split(" and ").each do |chunk|
          stats.merge!( scan_str(chunk.strip) )
        end
        stats
      end
    end

    def scan_str(str)
      map = SCAN_ATTRIBUTES.map do |attr|
        if str =~/\+(\d+) (#{attr})/i
          qty = $1.to_i
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
      when "Blue or Yellow"
        return "Green"
      else
        color
      end
    end
  end
end