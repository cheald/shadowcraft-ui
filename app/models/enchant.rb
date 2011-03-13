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
    "4063" => 15,   # Chest
    "4102" => 20,   # Chest
  }

  def encode_json(options = {})
    as_json(options).to_json
  end

  def as_json(options = {})
    {
      :id => spell_id,
      :stats => stats,
      :icon => icon,
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

  JSON_TO_INTERNAL = {
    "agi" => "agility",
    "atkpwr" => "attack_power",
    "critstrkrtng" => "crit_rating",
    "exprtng" => "expertise_rating",
    "hastertng" => "haste_rating",
    "hitrtng" => "hit_rating",
    "str" => "strength",
    "sta" => "stamina",
    "mastrtng" => "mastery_rating"
  }
  SLOT_MAP = [
    0x1, 0x2, 0x4, 0x8,
    0x10, 0x20, 0x40, 0x80,
    0x100, 0x200, 0x400, 0x800,
    0x1000, 0x2000, 0x4000, 0x8000,
    0x10000, 0x20000, 0x40000, 0x80000,
    0x100000, 0x200000, 0x400000, 0x800000
  ]

  ACCEPTED_ENCHANTS = ["Black Magic", "Berserking", "Mongoose", "Hurricane", "Avalanche", "Landslide"]

  def self.get_slots(k)
    SLOT_MAP.each_with_index do |e, i|
      return i + 1 if e & k == e
    end
    nil
  end

  def self.update_from_json!
    self.destroy_all
    keys = JSON_TO_INTERNAL.keys
    j = JSON::load open(File.join(Rails.root, "app/xml/converted_enchants.json")).read
    j.each do |k, i|
      slots = [i["slots"]].flatten
      used_names = []
      [i["name"]].flatten.each_with_index do |name, index|
        name_match = ACCEPTED_ENCHANTS.detect {|n| name.match(n) }
        if name_match or (x = i["jsonequip"].keys & keys and x.length > 0)
          next if used_names.include? name
          x ||= {}
          puts "Adding #{name}..."
          slot = get_slots(slots[index].to_i)
          Enchant.create({
            :spell_id => k.to_i,
            :stats => Hash[*x.map {|rk| [JSON_TO_INTERNAL[rk], i["jsonequip"][rk].to_i] }.flatten],
            :icon => [i["icon"]].flatten.first.downcase,
            :item_name => name,
            :equip_location => slot
          })
          used_names.push name
        else
          puts "Not adding #{name}"
        end
      end
    end
    nil
  end
end
