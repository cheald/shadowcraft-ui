module WowArmory
  class Character
    unloadable

    include Constants
    include Document

    attr_accessor :realm, :region, :name, :active, :gear, :race, :level, :player_class, :talents, :portrait

    def initialize(character, realm, region = 'US')
      @character = character
      @realm = realm
      @region = region
      params = {
          :fields => 'talents,items'
      }
      @json = WowArmory::Document.fetch region, '/wow/character/%s/%s' % [normalize_realm(realm), normalize_character(character)], params

      populate!

      @json['talents'].each_with_index do |tree, index|
        self.active = index if tree['selected']
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
        :active => active,
        :player_class => player_class,
        :talents => self.talents.map do |tree|
          glyphs = tree['glyphs'].map do |glyphset, set|
            set.map {|g| g['item'].to_i }
          end.flatten
          {:spec => tree['calcSpec'], :talents => tree['calcTalent'], :glyphs => glyphs}
        end,
      }
    end

    private

    def populate!
      self.name = @json['name']
      self.level = @json['level'].to_i
      self.realm = @json['realm'].to_i
      self.player_class = CLASS_MAP[@json['class'].to_i] || 'unknown'
      self.race = RACE_MAP[@json['race'].to_i]
      self.talents = @json['talents']

      self.portrait = 'http://%s.battle.net/static-render/%s/%s' % [ @region.downcase, @region.downcase, @json['thumbnail'].gsub(/-avatar/, '-card') ]

      populate_gear
    end

    def populate_gear
      @gear = {}
      raise ArmoryError.new('No items found on character', 500) if @json['items'].nil?
      @json['items'].each do |k, v|
        next unless v.is_a? Hash
        next if SLOT_MAP[k].nil?
        tooltip = v['tooltipParams'] || {}
        info = {
          'item_id' => v['id'],
          'original_id' => v['id'],
          'item_level' => v['itemLevel'],
          'name' => v['name'],
          'enchant' => tooltip['enchant'],
          'gems' => [tooltip['gem0'],tooltip['gem1'],tooltip['gem2']],
          'slot' => SLOT_MAP[k],
        }
        info['suffix'] = tooltip['suffix'].to_i unless tooltip['suffix'].blank?
        unless tooltip['upgrade'].nil?
          upgrade = tooltip['upgrade']
          info['upgrade_level'] = upgrade['current'] if upgrade['current'] > 0
        end
        info['bonuses'] = v['bonusLists']
        info['context'] = v['context']
        @gear[info['slot'].to_s] = info
      end
    end
  end
end
