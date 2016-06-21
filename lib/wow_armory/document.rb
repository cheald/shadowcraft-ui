# coding: utf-8
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

    def self.fetch(region, resource, params)
      host = case region.downcase
             when 'us'
               'us.api.battle.net'
             when 'eu'
               'eu.api.battle.net'
             when 'kr'
               'kr.api.battle.net'
             when 'tw'
               'tw.api.battle.net'
             when 'cn'
               'www.api.battlenet.com.cn'
             when 'sea'
               'sea.api.battle.net'
             else
               'us.api.battle.net'
             end

      params[:apikey] = BLIZZARD_CREDENTIALS['apikey']
      url = 'https://' + host + resource + '?' + params.to_query
      tries = 0
      begin
        result = Curl::Easy.http_get(url) do |curl|
          curl.timeout = 7
          curl.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36'
        end
        if result.response_code >= 400 and result.response_code < 500
          raise MissingDocument.new "Armory returned #{result.response_code}", result.response_code
        elsif result.response_code >= 500
          raise ArmoryError.new "Armory returned #{result.response_code}", result.response_code
        end
        
        @json = JSON::load result.body_str
        if @json.blank?
          raise ArmoryError.new 'Armory returned empty data', 404
        end
        return @json
        
      rescue Curl::Err::TimeoutError, Curl::Err::ConnectionFailedError, JSON::ParserError => e
        if tries < 3
          tries += 1
          retry
        else
          raise e
        end
      end
    end

    def normalize_realm(realm)
      realm.downcase.gsub(/['’]/, '').gsub(/ /, '-').gsub(/[àáâãäå]/, 'a').gsub(/[ö]/, 'o')
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
