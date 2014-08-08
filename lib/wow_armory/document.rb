require 'hmac-sha1'
require 'digest/sha1'
require 'base64'

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
    def fetch(region, resource, parse = :xml)
      host = case parse
      when :json
        case region.downcase
          when "us"
            "http://us.battle.net/"
          when "eu"
            "http://eu.battle.net/"
          when "kr"
            "http://kr.battle.net/"
          when "tw"
            "http://tw.battle.net/"
          when "cn"
            "http://www.battlenet.com.cn/"
          else
            "http://us.battle.net/"
        end
      when :xml, false
        case region.downcase
          when "us"
            "http://us.battle.net/wow/en/"
          when "eu"
            "http://eu.battle.net/wow/en/"
          when "kr"
            "http://kr.battle.net/wow/ko/"
          when "tw"
            "http://tw.battle.net/wow/zh/"
          when "cn"
            "http://cn.battle.net/wow/zh/"
          else
            "http://us.battle.net/wow/en/"
        end
      end

      url = URI.escape(host + resource)
      tries = 0
      # BLIZZARD_CREDENTIALS
      begin
        result = Curl::Easy.http_get(url) do |curl|
          curl.timeout = 7
          curl.headers["User-Agent"] = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/525.13 (KHTML, like Gecko) Chrome/0.A.B.C Safari/525.13"
          sign_request("GET", curl)
        end

        if result.response_code >= 400 and result.response_code < 500
          raise MissingDocument.new "Armory returned #{result.response_code}", result.response_code
        elsif result.response_code >= 500
          raise ArmoryError.new "Armory returned #{result.response_code}", result.response_code
        end
		
        @content = result.body_str
        if parse == :xml
          @document = Nokogiri::HTML @content
        elsif parse == :json
          @json = JSON::load @content
          if @json.blank?
            raise ArmoryError.new "Armory returned empty data", 404
          end
        else
          @content
        end
        
      rescue Curl::Err::TimeoutError, Curl::Err::ConnectionFailedError, JSON::ParserError => e
        if tries < 3
          tries += 1
          retry
        else
          raise e
        end
      end
    end

    def sign_request(verb, curl)
      return if BLIZZARD_CREDENTIALS["public"].nil?
      path = URI.parse(curl.url).path
      curl.headers["Date"] = Time.now.gmtime.rfc2822.gsub("-0000", "GMT")
      string_to_sign = "%s\n%s\n%s\n" % [verb, curl.headers["Date"], path]
      signature = Base64.encode64(HMAC::SHA1.digest(BLIZZARD_CREDENTIALS["private"], string_to_sign)).strip
      curl.headers["Authorization"] = "BNET %s:%s" % [BLIZZARD_CREDENTIALS["public"], signature]
    end

    def normalize_realm(realm)
      realm.downcase.gsub(/['’]/, "").gsub(/ /, "-").gsub(/[àáâãäå]/, "a").gsub(/[ö]/, "o")
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
