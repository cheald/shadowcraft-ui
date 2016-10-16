module WowArmory

  class Relic
    unloadable

    include Constants
    include Document

    # This is terrible.
    ARTIFACT_TRAIT_IDS = [214368,192657,192326,192923,192323,192428,192759,192329,192318,192349,192376,192315,192422,192345,192424,192310,192384,216230,202507,202628,202897,202769,202665,202463,202521,202755,202524,202514,202907,202530,202533,202820,202522,202753,209835,197241,197233,197604,197239,197256,197406,197369,197244,209782,197234,197235,197231,197610,221856,209781,197386]

    ACCESSORS = :id, :name, :type, :icon, :quality, :ilvl_increase, :traits
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

      tooltip_data = doc.scan(/_\[#{id}\]\.tooltip_enus.*?;/)[0]
      type = tooltip_data.scan(/#E6CC80">(.*?) Artifact Relic/)[0]
      ilvl = tooltip_data.scan(/(\d*?) Item Levels/)[0]

      @type = type[0]

      if !ilvl.nil?
        @ilvl_increase = ilvl[0].to_i
      else
        @ilvl_increase = -1
      end

      # Each relic contains a list of the traits that it can modify, even if they're not
      # valid (see below). Why wowhead does this, I have no idea, but grab all of them,
      # convert the stupid escaped-xml-in-json-in-html shit to something useful, and pull
      # out just the rogue bits that we actually care about.
      typesdata = doc.scan(/_\[#{id}\]\.affectsArtifactPowerTypesData = .*?};/)[0]
      typesdata = typesdata.scan(/= (\{.*\})/)[0][0]
      specstart = doc.scan(/traitspecstart:(\d+)/)[0][0]
      typesjson = (JSON::load typesdata)[specstart]

      # A relic can modify more than one trait at a time. Wowhead lists the specs that
      # have a trait related to this relic in their "validMenuSpecs" block. We only care
      # for specs 259(assn), 260(outlaw), and 261(sub).
      validMenuSpecs = doc.scan(/_\[#{id}\]\.validMenuSpecs = .*?;/)[0]
      a = validMenuSpecs.scan(/= \[(.*)\]/)[0][0].split(',')

      @traits = {}
      if (a.include? "259")
        spec = typesjson["259"]
        traitdata = spec.scan(/\+(\d+) Rank.*\/spell=(\d+).*?>(.*?)</)
        traits[:a] = {:rank => traitdata[0][0].to_i, :spell => traitdata[0][1].to_i, :name => traitdata[0][2]}
      end

      if (a.include? "260")
        spec = typesjson["260"]
        traitdata = spec.scan(/\+(\d+) Rank.*\/spell=(\d+).*?>(.*?)</)
        traits[:Z] = {:rank => traitdata[0][0].to_i, :spell => traitdata[0][1].to_i, :name => traitdata[0][2]}
      end

      if (a.include? "261")
        spec = typesjson["261"]
        traitdata = spec.scan(/\+(\d+) Rank.*\/spell=(\d+).*?>(.*?)</)
        traits[:b] = {:rank => traitdata[0][0].to_i, :spell => traitdata[0][1].to_i, :name => traitdata[0][2]}
      end
    end
  end
end
