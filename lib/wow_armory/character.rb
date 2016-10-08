module WowArmory
  class Character
    unloadable

    @artifact_ids = nil

    include Constants
    include Document

    attr_accessor :realm, :region, :name, :active, :gear, :race, :level, :player_class, :talents, :portrait, :artifact

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
        :artifact => artifact,
        :race => race,
        :level => level,
        :active => active,
        :player_class => player_class,
        :talents => self.talents.map do |tree|
          {:spec => tree['calcSpec'], :talents => tree['calcTalent']}
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

      # For talents, make sure to ignore any blank specs. Druids will actually have 4 specs
      # filled in, but rogues will return three good specs and one with a blank calcSpec
      # field.
      self.talents = @json['talents'].reject{|x| x['calcSpec'] == ""}

      self.portrait = 'http://%s.battle.net/static-render/%s/%s' % [ @region.downcase, @region.downcase, @json['thumbnail'] ]

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
          'id' => v['id'],
          'item_level' => v['itemLevel'],
          'enchant' => tooltip['enchant'].nil? ? 0 : tooltip['enchant'],
          'gems' => [],
          'slot' => SLOT_MAP[k],
          'bonuses' => v['bonusLists'],
          'context' => v['context'],
          'quality' => v['quality']
        }
        info['gems'].push(tooltip['gem0'].nil? ? 0 : tooltip['gem0'])
        info['gems'].push(tooltip['gem1'].nil? ? 0 : tooltip['gem1'])
        info['gems'].push(tooltip['gem2'].nil? ? 0 : tooltip['gem2'])

        info['suffix'] = tooltip['suffix'].to_i unless tooltip['suffix'].blank?
        unless tooltip['upgrade'].nil?
          upgrade = tooltip['upgrade']
          info['upgrade_level'] = upgrade['current'] if upgrade['current'] > 0
        end

        if info['context'].start_with?('world-quest-')
          info['context'] = 'world-quest'
        end

        @gear[info['slot'].to_s] = info
      end

      # Artifact data from the API looks like this:
      #            "artifactTraits": [{
      #                "id": 1348,
      #                "rank": 1
      #            }, {
      #                "id": 1061,
      #                "rank": 4
      #            }, {
      #                "id": 1064,
      #                "rank": 3
      #            }, {
      #                "id": 1066,
      #                "rank": 3
      #            }, {
      #                "id": 1060,
      #                "rank": 3
      #            }, {
      #                "id": 1054,
      #                "rank": 1
      #            }],
      #            "relics": [{
      #                "socket": 0,
      #                "itemId": 133008,
      #                "context": 11,
      #                "bonusLists": [768, 1595, 1809]
      #            }, {
      #                "socket": 1,
      #                "itemId": 133057,
      #                "context": 11,
      #                "bonusLists": [1793, 1595, 1809]
      #            }],

      # massage the artifact trait data a little bit
      @artifact = {}
      @artifact['traits'] = []
      @json['items']['mainHand']['artifactTraits'].each do |trait|
        # special casing my way around problems in the DBC data
        if trait['id'] != 859
          trait['id'] = Character.artifact_ids[trait['id']]
        else
          trait['id'] = 197241
        end
        @artifact['traits'].push trait
      end

      @artifact['relics'] = []
      @json['items']['mainHand']['relics'].each do |relic|
        r = {
          'socket' => relic['socket'],
          'id' => relic['itemId'],
          'bonuses' => relic['bonusLists']
        }
        @artifact['relics'].push r
      end
    end

    def self.artifact_ids
      # The header on the ArtifactPowerRank data looks like (as of 7.0.3):
      # id,id_spell,value,id_power,f5,index
      # We're mapping between id_power and id_spell
      @@artifact_ids ||= Hash.new.tap do |hash|
        CSV.foreach(File.join(File.dirname(__FILE__), 'data', 'ArtifactPowerRank.dbc.csv')) do |row|
          hash[row[3].to_i] = row[1].to_i
        end
      end
    end

  end
end
