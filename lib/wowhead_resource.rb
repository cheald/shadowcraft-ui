class WowheadResource
  unloadable

  include HTTParty
  format :xml

  class Item < WowheadResource
    @@base = "http://www.wowhead.com/?item=%d&xml"

    def self.fetch(id)
      if a = self.get(@@base % id) and b = a["wowhead"] and c = b["item"]
        c["jsonEquip"] = JSON::load "{%s}" % c["jsonEquip"]
        c["json"] = JSON::load "{%s}" % c["json"]
        return c
      end
      {}
    end
  end
end