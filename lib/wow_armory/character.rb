module WowArmory
  class Character
    unloadable

    CLASS_MAP = {
      4 => "rogue"
    }

    POWER_TYPES = [:mana, :rage, :focus, :energy]
    PROF_MAP = {
      755 => "jewelcrafting",
      164 => "blacksmithing",
      165 => "leatherworking",
      333 => "enchanting",
      202 => "engineering",
      171 => "alchemy",
      197 => "tailoring",
      773 => "inscription",
      182 => "herbalism",
      186 => "mining",
      393 => "skinning"
    }

    RACE_MAP = {
      1 => 'Human',
      2 => 'Orc',
      3 => 'Dwarf',
      4 => 'Night Elf',
      5 => 'Undead',
      6 => 'Tauren',
      7 => 'Gnome',
      8 => 'Troll',
      9 => 'Goblin',
      10 => 'Blood Elf',
      11 => 'Draenei',
      22 => 'Worgen',
      24 => 'Pandaren',
      25 => 'Pandaren',
      26 => 'Pandaren'
    }

    SLOT_MAP = {
      "head" => 0,
      "neck" => 1,
      "shoulder" => 2,
      "back" => 14,
      "chest" => 4,
      "wrist" => 8,
      "hands" => 9,
      "waist" => 5,
      "legs" => 6,
      "feet" => 7,
      "finger1" => 10,
      "finger2" => 11,
      "trinket1" => 12,
      "trinket2" => 13,
      "mainHand" => 15,
      "offHand" => 16,
    }

    include Document

    attr_accessor :realm, :region, :name, :active_talents, :professions, :gear, :race, :level, :player_class, :talents, :portrait

    def initialize(character, realm, region = 'US')
      @character = character
      @realm = realm
      @region = region
      fetch region, "api/wow/character/%s/%s?fields=talents,items,professions,appearance" % [normalize_realm(realm), normalize_character(character)], :json

      populate!

      @json["talents"].each_with_index do |tree, index|
        self.active_talents = index if tree["selected"]
      end

      self.professions = @json["professions"]["primary"].map do |prof|
        PROF_MAP[prof["id"]]
      end
    end

    def gear
      @gear
    end

    def as_json(options = {})
      {
        :gear => gear,
        :race => race,
        :level => level,
        :active_talents => active_talents,
        :professions => professions,
        :player_class => player_class,
        :talents => self.talents.map do |tree|
          glyphs = tree["glyphs"].map do |glyphset, set|
            set.map {|g| g["item"].to_i }
          end.flatten
          {:spec => tree["calcSpec"], :talents => tree["calcTalent"], :glyphs => glyphs}
        end
      }
    end

    private

    def populate!
      self.name = @json["name"]
      self.level = @json["level"].to_i
      self.realm = @json["realm"].to_i
      self.player_class = CLASS_MAP[@json["class"].to_i] || "unknown"
      self.race = RACE_MAP[@json["race"].to_i]
      self.talents = @json["talents"]

      self.portrait = "http://%s.battle.net/static-render/%s/%s" % [ @region.downcase, @region.downcase, @json["thumbnail"].gsub(/-avatar/, "-card") ]

      populate_gear
    end

    def populate_gear
      @gear = {}
      raise ArmoryError.new("No items found on character", 500) if @json["items"].nil?
      @json["items"].each do |k, v|
        next unless v.is_a? Hash
        next if SLOT_MAP[k].nil?
        tooltip = v["tooltipParams"] || {}
        info = {
          "item_id" => v["id"],
          "name" => v["name"],
          "enchant" => tooltip['enchant'],
          "g0" => tooltip["gem0"],
          "g1" => tooltip["gem1"],
          "g2" => tooltip["gem2"],
          "reforge" => tooltip["reforge"],
          "slot" => SLOT_MAP[k]
        }
        info["suffix"] = tooltip["suffix"].to_i unless tooltip["suffix"].blank?

        @gear[info["slot"].to_s] = info
      end
    end
  end
end
