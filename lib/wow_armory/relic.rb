module WowArmory

  class Relic
    unloadable

    include Constants
    include Document

    # This is terrible.
    ARTIFACT_TRAIT_IDS = [202665,202897,202769,202820,202507,202628,202463,202521,202755,202524,202514,202530,202907,202533,202522,202753,216230,214929,192759,192657,192428,192923,192310,192318,192424,192349,192422,192345,192384,192315,192326,192323,192329,192376,214928,214368,209782,209781,209835,197406,197239,197244,197241,197386,197234,197231,197256,197610,197233,197235,197604,197369,214930,221856]

    ACCESSORS = :id, :name, :type, :icon, :quality, :ilvl_increase, :rank_increase, :trait_modified_id, :trait_modified_name
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

    def populate_data_blizzard(data)
    end

    # Scrape relic data from wowhead. This is fragile and depends highly
    # on wowhead not changing the formatting of their pages.
    def populate_data_wowhead(id)
      puts "populating #{id}"
      doc = open('http://legion.wowhead.com/item=%d' % @id, 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36').read

      name_enus = doc.scan(/_\[#{id}\]={"name_enus":"(.*?)","quality":(.*?),"icon":"(.*?)"/)[0]
      if !name_enus.nil?
        @name = name_enus[0]
        @quality = name_enus[1].to_i
        @icon = name_enus[2]
      else
        @name = nil
        @quality = 0
        @icon = nil
      end

      tooltip_data = doc.scan(/tooltip_enus.*?;/)[0]
      type = tooltip_data.scan(/#E6CC80">(.*?) Artifact Relic/)[0]
      ilvl = tooltip_data.scan(/\+(\d*?) Item Levels/)[0]
      rank = tooltip_data.scan(/(\d*?) Rank/)[0]

      @type = RELIC_TYPE_MAP[type[0]]

      if !ilvl.nil?
        @ilvl_increase = ilvl[0].to_i
      else
        @ilvl_increase = -1
      end

      if !rank.nil?
        @rank_increase = rank[0].to_i
      else
        @rank_increase = -1
      end
      
      trait_ids="(" + ARTIFACT_TRAIT_IDS.join("|") + ")"
      name_enus = doc.scan(/_\[#{trait_ids}\]=\{"name_enus":"(.*?)"/)[0]
      if !name_enus.nil?
        @trait_modified_id = name_enus[0].to_i
        @trait_modified_name = name_enus[1]
      else
        @trait_modified_id = -1
        @tratt_modified_name = nil
      end
    end
  end
end
