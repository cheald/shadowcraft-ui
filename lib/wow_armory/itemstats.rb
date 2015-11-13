module WowArmory
  class Itemstats
    unloadable
  
    include Constants

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
      multiplier = 1.0 / (1.15 ** (-(self.upgrade_level*5.0) / 15.0))
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
  end
end
