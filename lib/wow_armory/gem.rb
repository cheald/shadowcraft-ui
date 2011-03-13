require 'fastercsv'

module WowArmory
  class Gem
    @gem_to_effect = nil
    unloadable
    attr_accessor :stats, :item_id, :colors

    class << self
      attr_reader :gem_to_effect
    end

    def initialize(gem_id)
      self.class.build_lookups
      @gem_id = gem_id
      effect = self.class.gem_to_effect[gem_id]
      parse_effect! effect
    end

    private

    def parse_effect!(effect)
      self.stats = {}
      self.item_id = effect[17].to_i
      (5..7).each do |id|
        attr_key = effect[id+6].to_i
        next if attr_key == 0
        key = WowArmory::Item::STAT_LOOKUP[attr_key]
        self.stats[key] = effect[id].to_i
      end
    end

    def self.build_lookups
      return unless @gem_to_effect.nil?
      @gem_to_effect = {}
      begin
        spell_lookup = {}
        FasterCSV.foreach(File.join(File.dirname(__FILE__), "data", "SpellItemEnchantment.dbc.csv")) do |row|
          if row[2].to_i == 5
            spell_lookup[row[0]] = row
          end
        end
        FasterCSV.foreach(File.join(File.dirname(__FILE__), "data", "GemProperties.dbc.csv")) do |row|
          @gem_to_effect[row[0].to_i] = spell_lookup[row[1]]
        end
      end
    end
  end
end
