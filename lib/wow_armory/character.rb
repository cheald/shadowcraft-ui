module WowArmory
  class Character
    unloadable

    POWER_TYPES = [:mana, :rage, :focus, :energy]
    include Document
    attr_accessor :realm, :region, :name, :player_class, :level, :achievement_points, :race, :spec, :battlegroup, :guild, :title, :average_ilvl,
      :agility, :strength, :spirit, :stamina, :intellect, :mastery, :mainhand_dps, :offhand_dps, :mainhand_speed, :offhand_speed,
      :attack_power, :health, :power, :power_type, :haste, :hit, :ranged_dps, :ranged_speed, :ranged_attack_power,
      :spell_power, :spell_hit, :spell_crit, :spell_haste, :mana_regen, :combat_regen, :spell_penetration,
      :dodge, :block, :parry, :resilience, :armor, :warnings, :portrait, :glyphs, :tree1, :tree2, :active_talents, :professions


    def initialize(character, realm, region = 'US')
      @character = character
      @realm = realm
      @region = region
      fetch region, "character/%s/%s/advanced" % [normalize_realm(realm), normalize_character(character)]
      populate!

      self.tree1 = Talents.new character, realm, region, 'primary'
      self.tree2 = Talents.new character, realm, region, 'secondary'
      self.active_talents = @document.css("#summary-talents a.active").attr("href").to_s.match(/primary/) ? 0 : 1
      self.professions = @document.css(".profession-details .name").map {|n| n.text.downcase }
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
        :talents => [
          tree1.as_json,
          tree2.as_json
        ]
      }
    end

    private

    def populate!
      populate_info
      # populate_stats
      populate_gear
      populate_portrait
    end

    def populate_info
      prof = @document.css(".profile-info").first
      self.name = value(".name a", prof)
      self.level = value(".level strong", prof).to_i
      self.realm = value(".realm", prof)
      self.player_class = value(".class", prof)
      self.achievement_points = value(".achievements a").to_i
      self.race = value(".race", prof)
      self.spec = value(".spec", prof)
      self.battlegroup = attr("#profile-info-realm", "data-battlegroup", prof)
      self.guild = value(".guild a", prof)
      self.title = value(".title-guild .title")
      self.average_ilvl = value("#summary-averageilvl-best").to_i
      self.warnings = nodes(".summary-audit-list li").map {|li| li.text.strip}
    end

    def populate_stats
      stats = @document.css(".summary-bottom")
      %w"agility strength stamina intellect spirit".each do |stat|
        self.send(:"#{stat}=", value(".summary-stats-column li[data-id='#{stat}'] .value", stats).to_i)
      end
      power_index              = attr("#summary-power", "data-id", stats).match(/power-(\d)/)[1].to_i
      self.power_type          = POWER_TYPES[power_index]
      self.mastery             = value(".summary-stats-column li[data-id='mastery'] .value", stats).to_f
      self.health              = value(".health .value", stats).to_i
      self.power               = value("#summary-power .value", stats).to_i

      damages                  = value("li[data-id='meleedps'] .value", stats).split(" / ")
      self.mainhand_dps        = damages[0].to_f
      self.offhand_dps         = damages[1].nil? ? nil : damages[1].to_f
      self.ranged_dps          = value("li[data-id='rangeddps'] .value", stats).to_f

      speeds                   = value("li[data-id='meleespeed'] .value", stats).split(" / ")
      self.mainhand_speed      = speeds[0].to_f
      self.offhand_speed       = speeds[1].nil? ? nil : speeds[1].to_f
      self.ranged_speed        = (value("li[data-id='rangedspeed'] .value", stats) || 0).to_f

      self.attack_power        = value("li[data-id='meleeattackpower'] .value", stats).to_i
      self.ranged_attack_power = value("li[data-id='rangedattackpower'] .value", stats).to_i

      self.spell_power         = value("li[data-id='spellpower'] .value", stats).to_i
      self.spell_haste         = value("li[data-id='spellhaste'] .value", stats).to_f
      self.spell_hit           = value("li[data-id='spellhit'] .value", stats).to_f
      self.spell_crit          = value("li[data-id='spellcrit'] .value", stats).to_f
      self.spell_penetration   = value("li[data-id='spellpenetration'] .value", stats).to_i
      self.mana_regen          = value("li[data-id='manaregen'] .value", stats).to_i
      self.combat_regen        = value("li[data-id='combatregen'] .value", stats).to_i

      self.resilience          = value("li[data-id='resilience'] .value", stats).to_i
      self.block               = value("li[data-id='block'] .value", stats).to_f
      self.dodge               = value("li[data-id='dodge'] .value", stats).to_f
      self.parry               = value("li[data-id='parry'] .value", stats).to_f
      self.armor               = value("li[data-id='armor'] .value", stats).to_i
    end

    def populate_gear
      @gear = {}
      nodes("#summary-inventory div.slot").each do |slot|
        item_info = attr(".details .name a[data-item]", "data-item", slot)
        item_name = value(".details .name a[data-item]", slot)
        unless item_info.nil?
          id   = slot.attr("data-id").to_i
          info = Hash[*item_info.split("&").map {|i| v = i.split("=", 2); v[1] = v[1].to_i; v }.flatten]
          info["item_id"] = info.delete "i"
          info["enchant"] = info.delete "e"
          info["reforge"] = info.delete "re"
          info["name"] = item_name
          if info["scaling"] = info.delete("s")
            info["scaling"] = info["scaling"].to_i & 65535
          end

          info["slot"] = id
          %w(g0 g1 g2).each do |gem|
            if !info[gem].blank? and info[gem].to_i != 0
              info[gem] = WowArmory::Gem.new(info[gem]).item_id
            end
          end
          @gear[id.to_s] = info
        end
      end
    end

    def populate_portrait
      self.portrait = @content.match(/(http.*?\/static-render\/.*?)\?/ ).to_a.last.gsub(/profilemain/, "card")
    end
  end
end