class ResetLegendaryIlvls < Mongoid::Migration
  def self.up
    olds = Item.where("properties.quality": 5)
    olds.each do |item|
      item.item_level = 910
      item.save!
    end
  end

  def self.down
  end
end
