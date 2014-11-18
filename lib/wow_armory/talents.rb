module WowArmory
  class Talents
    unloadable

    # http://us.battle.net/wow/en/talents/class/4?jsonp=foobar
    include Document
    attr_accessor :talent_string, :glyphs

    def initialize(data, tree = 'primary')
      @character = character
      @realm = realm
      @region = region
      #fetch region, "character/%s/%s/talent/%s" % [normalize_realm(realm), normalize_character(character), tree]
      #populate!
    end

    def as_json(options = {})
      {
        :talents => talent_string,
        :glyphs => glyphs
      }
    end

    def populate!
      self.talent_string = attr(".talentcalc-info a", "data-fansite").split("|").last
      self.glyphs = @document.css("#character-glyphs a").map do |glyph|
          glyph.attr("href").split("/").last.to_i
      end
    end
  end
end
