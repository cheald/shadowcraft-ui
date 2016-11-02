class RemoveSockets < Mongoid::Migration
  def self.up
    olds = Item.where(is_gem: false)
    olds.each do |item|
      item.unset(:"properties.sockets", :"properties.socket_bonus")
      item.context_map.each do |tag,context|
        context['defaultBonuses'] -= [1808]
      end
      item.save!
    end
  end

  def self.down
  end
end
