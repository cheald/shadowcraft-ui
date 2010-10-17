require 'nokogiri'
require 'open-uri'

class ArmoryResource
  unloadable
  
  include HTTParty
  format :xml
  base_uri "http://www.wowarmory.com"
  AGENT = "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.2.10) Gecko/20100914 Firefox/3.6.10"
  headers "User-Agent" => AGENT

  def self.host(region)
    case region.downcase
    when "eu"
      "http://eu.wowarmory.com"
    else
      "http://www.wowarmory.com"
    end
  end  
  
  class Item < ArmoryResource
    def self.fetch(id, region = "us")
      if a = self.get("#{host region}/item-tooltip.xml", :query => {:i => id}) and
        b = a["page"] and c = b["itemTooltips"] and d = c["itemTooltip"]
        return d
      end
      {}
    end
  end  
  
  class ItemInfo < ArmoryResource
    def self.fetch(id, region = "us")
      if a = self.get("#{host region}/item-info.xml", :query => {:i => id}) and
        b = a["page"] and c = b["itemInfo"] and d = c["item"]
          return d
      end
      {}
    end
  end
  
  class Character < ArmoryResource
    def self.fetch(name, realm, region = "us")
      if a = self.get("#{host region}/character-sheet.xml", :query => {:n => name, :r => realm}) and 
        b = a["page"] and c = b["characterInfo"]
        return c        
      end
      {}
    end
  end
  
  class Talents < ArmoryResource
    def self.fetch(name, realm, region = "us")
      if a = self.get("#{host region}/character-talents.xml", :query => {:n => name, :r => realm}) and 
        b = a["page"] and c = b["characterInfo"] and d = c["talents"]
        return d
      end
      {}
    end
  end
  
  class Search
    def self.fetch(search, ilevel = 0)
      Nokogiri::XML(open(search, "User-Agent" => ArmoryResource::AGENT)).css('item').select do |item|
        item.css("filter[name='itemLevel']").first["value"].to_i >= ilevel
      end.map {|i| i["id"].to_i }.compact.uniq
    end
  end
end