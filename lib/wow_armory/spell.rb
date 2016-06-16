module WowArmory

  class Spell
    unloadable

    include Constants
    include Document

    # This is terrible.
    ACCESSORS = :id, :name, :icon
    attr_accessor *ACCESSORS

    def initialize(id, source = 'wowhead')
      @id = id

      case source
        when 'wowapi'
          populate_data_blizzard(id)
        when 'wowhead'
          populate_data_wowhead(id)
        else
          puts 'ERROR: relic source not valid'
          return
      end
    end

    def as_json(options = {})
      {}.tap do |r|
        ACCESSORS.map {|key| r[key] = self.send(key) }
      end
    end

    private

    def populate_data_blizzard(id)
      @json = WowArmory::Document.fetch region, '/wow/spell/%d' % id, {}
      @name = json['name']
      @icon = json['icon']
    end

    # Scrape relic data from wowhead. This is fragile and depends highly
    # on wowhead not changing the formatting of their pages.
    def populate_data_wowhead(id)
      puts "populating #{id}"
      doc = open('http://legion.wowhead.com/spell=%d' % @id, 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36').read

      name_enus = doc.scan(/_\[#{id}\]={"name_enus":"(.*?)",.*,"icon":"(.*?)"/)[0]
      if !name_enus.nil?
        @name = name_enus[0]
        @icon = name_enus[1]
      else
        @name = nil
        @icon = nil
      end

    end
  end
end
