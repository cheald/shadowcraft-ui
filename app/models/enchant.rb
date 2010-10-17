require 'csv'

class Enchant
  include Mongoid::Document
  field :spell_id, :type => Integer
  field :stats, :type => Hash
  field :icon
  field :item_id, :type => Integer
  field :item_name
  field :equip_location, :type => Integer
  
  ALL_STATS = {
    "2931" => 4,    # Ring
    "1891" => 4,    # Bracer, Chest
    "2661" => 6,    # Bracer, Chest
    "866"  => 2,    # Chest
    "847"  => 1,    # Chest
    "928"  => 3,    # Chest
    "3252" => 8,    # Chest
    "3832" => 10,   # Chest    
  }
  
  def as_json(options = {})
    {
      :id => spell_id,
      :stats => stats,
      :icon => icon,
      :item_id => item_id,
      :slot => equip_location,
      :name => item_name.gsub(/Scroll.*- /, "")
    }
  end
  
  def self.update!
    self.destroy_all
    stat_lookup = Hash[*File.open(File.join(Rails.root, "app", "xml", "stats.txt")).map {|l| x = l.strip.split(/[\s]+/, 2) }.flatten]
    permEnchants = {}
    CSV.foreach(File.join(Rails.root, "app", "xml", "SpellItemEnchantment.dbc.csv")) do |row|
      enchantId = row[0].to_i      
      b = {}
      if row[2].to_i == 5 or row[3].to_i == 5
        3.times do |i|
          amt = row[5 + i].to_i
          if amt != 0 and row[11+i] != "0"
            if statType = stat_lookup[row[11+i]]
              key = statType.titleize.gsub(/ /, "").snake_case
              b[key] = amt
            end
          end
        end
      elsif q = ALL_STATS[row[0]]
        b[:agility] = q
        b[:stamina] = q
        b[:strength] = q
      end
      
      permEnchants[enchantId] = b unless b.empty?
    end
    
    Character.all.map {|c| c.properties["characterTab"]["items"]["item"] }.flatten.map do |i|
      h = Hash[*i.keys.grep(/enchant/i).map {|k| [k.to_sym, i[k]] }.flatten]
      i_obj = Item.find_or_create_by(:remote_id => i["id"].to_i)
      h[:slot] = i_obj.equip_location
      
      if i["permanentEnchantItemId"] and i["permanentEnchantItemId"] != "0"
        e_obj = Item.find_or_create_by(:remote_id => i["permanentEnchantItemId"])
        h[:item_name] = e_obj.properties["name"]
      elsif i["permanentEnchantSpellName"]
        h[:item_name] = i["permanentEnchantSpellName"]
      end
      puts "Looking up spell enchant for #{h[:item_name]}"
      if h[:item_name]
        h
      else
        nil
      end
    end.compact.uniq.each do |enchant|
      if Enchant.count(:conditions => {:spell_id => enchant[:permanentenchant].to_i}) == 0
        puts enchant[:item_name]
        puts enchant[:permanentenchant].to_i        
        puts permEnchants[enchant[:permanentenchant].to_i].inspect
        Enchant.create({
          :spell_id => enchant[:permanentenchant].to_i,
          :stats => permEnchants[enchant[:permanentenchant].to_i],
          :icon => enchant[:permanentEnchantIcon],
          :item_id => enchant[:permanentEnchantItemId],
          :item_name => enchant[:item_name],
          :equip_location => enchant[:slot]
        })
      end
    end
  end
end
