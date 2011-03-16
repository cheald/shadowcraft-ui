module WowArmory
  class CurlException < Exception
    attr_accessor :error
    def initialize(msg, error)
      super(msg)
      self.error = error
    end
  end
  class MissingDocument < CurlException; end
  class ArmoryError < CurlException; end

  module Document
    unloadable
    def fetch(region, resource, parse = true)
      host = case region.downcase
      when "us"
        "http://us.battle.net/wow/en/"
      when "eu"
        "http://eu.battle.net/wow/en/"
      else
        "http://us.battle.net/wow/en/"
      end
      url = (host + resource)
      Rails.logger.debug "Reading #{url}"
      result = Curl::Easy.http_get(url) do |curl|
        curl.timeout = 10
        curl.headers["User-Agent"] = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/525.13 (KHTML, like Gecko) Chrome/0.A.B.C Safari/525.13"
      end
      if result.response_code >= 400 and result.response_code < 500
        raise MissingDocument.new "Armory returned #{result.response_code}", result.response_code
      elsif result.response_code >= 500
        raise ArmoryError.new "Armory returned #{result.response_code}", result.response_code
      end
      @content = result.body_str
      if parse
        @document = Nokogiri::HTML @content
      else
        @content
      end
    end

    def normalize_realm(realm)
      realm.downcase.gsub(/[']/, "").gsub(/ /, "-")
    end

    def normalize_character(character)
      character.downcase
    end

    def nodes(path, set = nil)
      if set.nil?
        @document.css(path)
      elsif set.is_a? Array
        set.map {|s| s.css(path)}.flatten
      else
        set.css(path)
      end
    end

    def value(path, set = nil)
      n = nodes(path, set).first
      return nil if n.nil?
      n.text.strip
    end

    def attr(path, attribute, set = nil)
      n = nodes(path, set).first
      return nil if n.nil?
      n.attr(attribute)
    end
  end
end