module WowArmory
  class Item
    unloadable

    @item_enchants = nil
    @item_bonus_map = nil
    @item_bonus_trees = nil

    include Constants
    include Document
    ACCESSORS = :stats, :icon, :id, :name, :equip_location, :ilevel, :quality, :requirement, :tag, :socket_bonus, :sockets, :gem_slot, :speed, :dps, :subclass, :armor_class, :upgradable, :bonus_trees, :chance_bonus_lists
    attr_accessor *ACCESSORS
    def initialize(id, source = 'wowapi', name = nil, context = '', bonus_trees = [], override_ilvl = nil, is_upgradable = nil)
      self.name = name
      self.ilevel = override_ilvl
      self.bonus_trees = bonus_trees

      if id == :empty or id == 0 or id.nil?
        @id = :empty
        return
      else
        @id = id.to_i
      end

      case source
        when 'wowapi'
          url =  if context == ''
            '/wow/item/%d' % id
          else
            '/wow/item/%d/%s' % [id,context]
          end
          params = {
              :bl => bonus_trees.join(',')
          }
          @json = WowArmory::Document.fetch 'us', url, params, :json
          populate_base_data
        when 'wowhead'
          populate_base_data_wowhead
        when 'wowhead_ptr'
          populate_base_data_wowhead('ptr')
        else
          puts 'ERROR: source not valid'
          return
      end

      unless is_upgradable.nil?
        self.upgradable = is_upgradable
      end
    end

    def as_json(options = {})
      {}.tap do |r|
        ACCESSORS.map {|key| r[key] = self.send(key) }
      end
    end

    private

    def is_upgradable
      if @json['upgradable'].nil?
        return false
      end
      @json['upgradable']
    end

    def populate_base_data
      self.name ||= @json['name']
      self.quality = @json['quality']
      self.equip_location = @json['inventoryType']
      self.ilevel ||= @json['itemLevel']
      self.icon = @json['icon']

      if @json['hasSockets']
        self.sockets = []
        sockets = @json['socketInfo']['sockets']
        sockets.each do |socket|
          self.sockets.push socket['type'].capitalize
        end
        unless @json['socketInfo']['socketBonus'].nil?
          self.socket_bonus = scan_str(@json['socketInfo']['socketBonus'])
        end
      end
      unless @json['requiredSkill'].nil?
        self.requirement = PROF_MAP[@json['requiredSkill']]
      end
      unless @json['nameDescription'].nil?
        self.tag = @json['nameDescription']
      end
      if @json['itemClass'] == 3 # gem
        puts 'Gem = True'
        if @json['gemInfo'].nil?
          self.stats = {}
        else
          self.gem_slot = @json['gemInfo']['type']['type'].capitalize
          self.stats = scan_str(@json['gemInfo']['bonus']['name'])
          puts 'stats from api'
          puts self.stats.inspect
        end
      elsif @json['itemClass'] == 4 # armor
        self.armor_class ||= ARMOR_CLASS[@json['itemSubClass']]
      end

      unless @json['bonusStats'].nil?
        self.stats = {}
        @json['bonusStats'].each do |entry|
            unless STAT_LOOKUP.has_key?(entry['stat'])
              puts "STAT ID missing: #{entry['stat']}"
              next
            end
            self.stats[STAT_LOOKUP[entry['stat']]] = entry['amount']
        end
      end

      if @json['bonusSummary']['chanceBonusLists'].nil?
        self.chance_bonus_lists = []
      else
        self.chance_bonus_lists = @json['bonusSummary']['chanceBonusLists']
      end

      @json['bonusSummary']['defaultBonusLists'].each do |bonusId|
        if [486, 487, 488, 489, 490].include? bonusId then
          self.chance_bonus_lists.push(bonusId)
        end
      end

      unless @json['weaponInfo'].nil?
        self.speed = @json['weaponInfo']['weaponSpeed'].to_f
        self.dps = @json['weaponInfo']['dps'].to_f
        self.subclass = @json['itemSubClass']
      end

      self.upgradable = is_upgradable
    end

    def populate_base_data_wowhead(prefix = 'www')
      doc = Nokogiri::XML open("http://#{prefix}.wowhead.com/item=%d&xml" % @id, 'User-Agent' => 'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:27.0) Gecko/20100101 Firefox/27.0').read
      eqstats = JSON::load('{%s}' % doc.css('jsonEquip').text)
      stats = JSON::load('{%s}' % doc.css('json').text)
      unless doc.css('error').blank?
        puts prefix
        puts doc.inspect
        puts "Item not found on wowhead id #{@id}"
        return
        #raise Exception.new "Item not found on wowhead id #{@id}"
      end
      self.name ||= doc.css('name').text
      self.quality = doc.xpath('//quality').attr('id').text.to_i
      self.equip_location = doc.xpath('//inventorySlot').attr('id').text.to_i
      self.ilevel ||= doc.css('level').text.to_i
      self.icon = doc.css('icon').text.downcase
      self.tag = ''
      unless stats['namedesc'].nil?
        self.tag = stats['namedesc']
      end
      if stats['classs'] == 3 # gem
        puts 'Gem = True'
        self.gem_slot = GEM_SUBCLASS_MAP[stats['subclass'].to_i]
        self.stats = {}
        eqstats.each do |stat, val|
         stat2 = WOWHEAD_STAT_MAP[stat]
         unless stat2.nil?
           self.stats[stat2] = val
         end
        end
        puts self.stats.inspect
      elsif stats['classs'] == 4
        self.armor_class = ARMOR_CLASS[stats['subclass']]
      end
      unless eqstats['nsockets'].nil?
        self.sockets = []
        (1..eqstats['nsockets'].to_i).each { |num|
          self.sockets.push(SOCKET_MAP[eqstats["socket#{num}"]])
        }
        unless eqstats['socketbonus'].nil?
          self.socket_bonus = {}
          enchant_row = item_enchants[eqstats['socketbonus'].to_s]
          # TODO if socketbonus includes more than 1 stat update this
          stat = enchant_row[14].to_i
          value = enchant_row[17].to_f * ENCHANT_SCALING
          self.socket_bonus[STAT_LOOKUP[stat]] = value.round
        end
      end
      unless eqstats['reqskill'].nil?
        self.requirement = PROF_MAP[eqstats['reqskill']]
      end
      unless eqstats['mlespeed'].blank? and eqstats['speed'].blank?
        self.speed = (eqstats['mlespeed'] || eqstats['speed']).to_f
        self.dps = (eqstats['mledps'] || eqstats['dps']).to_f
        self.subclass = stats['subclass'].to_i
      end
      if not stats["upgrades"].nil? and self.ilevel >= 458
        self.upgradable = true
      else
        self.upgradable = false
      end
    end

    def scan_str(str)
      map = SCAN_ATTRIBUTES.map do |attr|
        if str =~/\+(\d+) (#{attr})/i
          qty = $1.to_i
          [(SCAN_OVERRIDE[attr] || attr).gsub(/ /, '_').to_sym, qty]
        elsif str =~/Equip:.*(#{attr}) by (\d+)/i
          qty = $2.to_i
          [(SCAN_OVERRIDE[attr] || attr).gsub(/ /, '_').to_sym, qty]
        else
          nil
        end
      end.compact
      Hash[*map.flatten]
    end

    def item_enchants
      @@item_enchants ||= Hash.new.tap do |hash|
        FasterCSV.foreach(File.join(File.dirname(__FILE__), 'data', 'SpellItemEnchantments.csv')) do |row|
          hash[row[0].to_s] = row
        end
      end
    end

  end
end
