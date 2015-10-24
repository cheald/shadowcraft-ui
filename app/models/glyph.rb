class Glyph
  include Mongoid::Document

  field :glyph_id, :type => Integer
  field :spell_id, :type => Integer
  field :name
  field :icon
  field :rank, :type => Integer

  def as_json(options = {})
    {
      :name => name,
      :rank => rank,
      :icon => icon.downcase,
      :id   => glyph_id,
      :spell => spell_id,
      :ename => name.downcase.gsub(/glyph of /, "").gsub(/ /, "_")
    }
  end

  def encode_json(options = {})
    as_json(options).to_json
  end

  def self.populate!
    populate_from_wowhead "http://www.wowhead.com/items=16.4"
  end

  def self.populate_from_wowhead(url, options = {})
    self.destroy_all
    doc = open(url, 'User-Agent' => 'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:27.0) Gecko/20100101 Firefox/27.0').read
    ids = doc.scan(/_\[(\d+)\]=\{.*?\}/).flatten.map &:to_i
    ids.each do |id|
      doc = open("http://www.wowhead.com/item=%d&xml" % id, 'User-Agent' => 'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:27.0) Gecko/20100101 Firefox/27.0').read
      xml = Nokogiri::XML(doc)
      json = JSON::load("{%s}" % xml.css("json").text)
      puts json.inspect

      if matches = doc.match(/spell=(\d+)\"/)
        spellDoc = open("http://www.wowhead.com/spell=%d" % matches[1], 'User-Agent' => 'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:27.0) Gecko/20100101 Firefox/27.0').read
        icon = spellDoc.match(/Icon\.create\(\'(.*?)'/)[1]
        rank = if json["sourcemore"][0]["icon"].match(/prime/i)
          3
        elsif json["sourcemore"][0]["icon"].match(/major/i)
          2
        elsif json["sourcemore"][0]["icon"].match(/minor/i)
          1
        else
          0
        end
        rank = json["glyph"]
        Glyph.create :glyph_id => id, :spell_id => matches[1], :name => json["sourcemore"][0]["n"], :icon => icon, :rank => rank
      end
    end
  end
end
