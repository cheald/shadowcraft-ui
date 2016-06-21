module WowArmory
  class Itemstats
    unloadable
  
    @item_upgrades = nil
    @upgrade_rulesets = nil
    @upgrade_multipliers = {}

    include Constants

    # The mapping for upgrades goes as follows:
    # 1. The RulesetItemUpgrade file contains a list of items that can be
    #    upgraded and maps to a ID of the kind of upgrade.
    # 2. The ItemUpgrade file contains a list of kinds of upgrades and maps
    #    from those IDs to the number of upgrades for that kind (via a
    #    chain of previous IDs) and the currency necessary for the upgrade.
    #
    # For ShC, we only care about valor upgrades so we can skip any other
    # kind of upgrade.
    def self.check_upgradable(id)
      if upgrade_rulesets.key?(id.to_s)
        rule = upgrade_rulesets[id.to_s]
        if item_upgrades.key?(rule.to_s)
          currency = item_upgrades[rule.to_s]
          # valor in 6.2.3 is currency type 1191
          if currency == 1191
            return true
          end
        end
      end
      return false
    end

    def self.get_upgrade_multiplier(upgrade_level=0)
      if @upgrade_multipliers[upgrade_level].nil?
        @upgrade_multipliers[upgrade_level] =  1.0 / (1.15 ** (-(upgrade_level*5.0) / 15.0))
      end
      return @upgrade_multipliers[upgrade_level]
    end

    ACCESSORS = :stats, :name, :dps, :upgrade_level, :bonus_trees
    attr_accessor *ACCESSORS
    def initialize(properties, upgrade_level = nil, bonus_trees = [])
      self.stats = {}
      @properties = properties
      self.upgrade_level = upgrade_level
      self.upgrade_level = nil if self.upgrade_level == 0
      self.name = @properties[:name]
      self.bonus_trees = bonus_trees

      populate_stats
    end

    def as_json(options = {})
      {}.tap do |r|
        ACCESSORS.map {|key| r[key] = self.send(key) }
      end
    end

    private

    def populate_item_upgrade_level
      # multiplier for item upgrades according to navv from simc. for WoD, we're
      # stepping 5 ilvls per upgrade.
      multiplier = get_ugprade_multiplier(self.upgrade_level)
      @properties[:stats].each do |key, stat|
        self.stats[key] = (stat*multiplier).round
        @properties[:stats][key] = self.stats[key]
      end
        
      if not @properties[:dps].nil?
        self.dps = @properties[:dps] * multiplier
      end
    end

    def populate_stats
      # 1. if gem, take data from community api
      # 2. set new ilevel based on upgrade_level and item quality
      # 3. populate item data
      # 4. if weapon update dps
      unless @properties[:gem_slot].nil?
        self.stats = @properties[:stats]
        return
      end
      
      upgd_lvl = 0
      if not self.upgrade_level.nil? and not @properties[:upgradable].nil?
        upgd_lvl = self.upgrade_level
      end

      # upgrade levels in 6.2.3 are 2 steps for 5 ilevels each
      @properties[:ilevel] = @properties[:ilevel] + upgd_lvl * 5
      populate_item_upgrade_level

      puts "#{self.name} #{@properties[:tag]} #{@properties[:ilevel]}"
      puts self.stats.inspect
    end


    # item_upgrades and upgrade_rulesets are used to determine if a piece of gear is
    # eligible for a valor upgrade. They are used in the check_upgradable method.
    def self.item_upgrades
      # The header on the ItemUpgrade data looks like (as of 6.2.3):
      # id,upgrade_group,upgrade_ilevel,prev_id,id_currency_type,cost
      # We only care about the prev_id and id_currency_type ones
      @@item_upgrades ||= Hash.new.tap do |hash|
        CSV.foreach(File.join(File.dirname(__FILE__), 'data', 'ItemUpgrade.dbc.csv')) do |row|
          row3 = row[3].to_i
          row4 = row[4].to_i
          if row3 != 0 and row4 != 0
            hash[row3.to_s] = row4
          end
        end
      end
    end

    def self.upgrade_rulesets
      # The header on the RulesetItemUpgrade data looks like (as of 6.2.3):
      # id,upgrade_level,id_upgrade_base,id_item
      # We only care about the last two of these.
      @@upgrade_rulesets ||= Hash.new.tap do |hash|
        CSV.foreach(File.join(File.dirname(__FILE__), 'data', 'RulesetItemUpgrade.dbc.csv')) do |row|
          hash[row[3]] = row[2].to_i
        end
      end
    end
  end
end
