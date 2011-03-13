module WowArmory::Document
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
    @content = open(url).read
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