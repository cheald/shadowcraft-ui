require 'csv'

class Enchant
  include Mongoid::Document
  field :spell_id, :type => Integer
  field :stats, :type => Hash
  field :icon
  field :item_id, :type => Integer
  field :item_name
  field :equip_location, :type => Integer
  field :requires, :type => Hash

  ALL_STATS = {
      '2931' => 4, # Ring
      '1891' => 4, # Bracer, Chest
      '2661' => 6, # Bracer, Chest
      '866' => 2, # Chest
      '847' => 1, # Chest
      '928' => 3, # Chest
      '3252' => 8, # Chest
      '3832' => 10, # Chest
      '4063' => 15, # Chest
      '4102' => 20, # Chest
      '4419' => 80, # Chest
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
        :name => item_name.gsub(/Scroll.*- /, ''),
        :requires => requires
    }
  end

  JSON_TO_INTERNAL = {
      'agi' => 'agility',
      'atkpwr' => 'attack_power',
      'critstrkrtng' => 'crit',
      'exprtng' => 'expertise',
      'hastertng' => 'haste',
      'hitrtng' => 'hit',
      'str' => 'strength',
      'sta' => 'stamina',
      'mastrtng' => 'mastery'
  }
  SLOT_MAP = [
      0x1, 0x2, 0x4, 0x8,
      0x10, 0x20, 0x40, 0x80,
      0x100, 0x200, 0x400, 0x800,
      0x1000, 0x2000, 0x4000, 0x8000,
      0x10000, 0x20000, 0x40000, 0x80000,
      0x100000, 0x200000, 0x400000, 0x800000
  ]

  ACCEPTED_ENCHANTS = ['Black Magic', 'Berserking', 'Mongoose', 'Hurricane', 'Avalanche', 'Landslide', 'Windsong', 'Elemental Force', 'Dancing Steel']

  def self.get_slots(k)
    SLOT_MAP.each_with_index do |e, i|
      return i + 1 if e & k == e
    end
    nil
  end

  def self.update_from_json!
    self.destroy_all
    keys = JSON_TO_INTERNAL.keys
    j = JSON::load open(File.join(Rails.root, 'app/xml/converted_enchants.json')).read
    j.each do |k, i|
      slots = [i['slots']].flatten
      used_names = []
      [i['name']].flatten.each_with_index do |name, index|
        name_match = ACCEPTED_ENCHANTS.detect { |n| name.match(n) }
        if name_match or (x = i['jsonequip'].keys & keys and x.length > 0)
          next if used_names.include? name
          x ||= {}
          puts "Adding #{name}..."
          slot = get_slots(slots[index].to_i)
          next if slot == 1 # do not import head enchants
          Enchant.create({
                             :spell_id => k.to_i,
                             :stats => Hash[*x.map { |rk| [JSON_TO_INTERNAL[rk], i['jsonequip'][rk].to_i] }.flatten],
                             :icon => [i['icon']].flatten.first.downcase,
                             :item_name => name,
                             :equip_location => slot
                         })
          used_names.push name
        else
          puts "Not adding #{name}"
        end
      end
    end
    self.hardcoded_import
    nil
  end

  def self.hardcoded_import
    # first delete all existing enchants int he database
    Enchant.delete_all

    # WOD WEAPON
    # Enchant.create({
    #                    :spell_id => 5330,
    #                    :stats => {},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Weapon - Mark of the Thunderlord',
    #                    :equip_location => 13
    #                })
    # Enchant.create({
    #                    :spell_id => 5331,
    #                    :stats => {},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Weapon - Mark of the Shattered Hand',
    #                    :equip_location => 13
    #                })
    # Enchant.create({
    #                    :spell_id => 5334,
    #                    :stats => {},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Weapon - Mark of the Frostwolf',
    #                    :equip_location => 13
    #                })
    # Enchant.create({
    #                    :spell_id => 5337,
    #                    :stats => {},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Weapon - Mark of Warsong',
    #                    :equip_location => 13
    #                })
    # Enchant.create({
    #                    :spell_id => 5384,
    #                    :stats => {},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Weapon - Mark of Bleeding Hollow',
    #                    :equip_location => 13
    #                })
    # # WOD RING
    # Enchant.create({
    #                    :spell_id => 5303,
    #                    :stats => {'versatility' => 30},
    #                    :icon => 'inv_enchant_formulagood_01',
    #                    :item_name => 'Enchant Ring - Breath of Versatility',
    #                    :equip_location => 11 # Ring
    #                })
    # Enchant.create({
    #                    :spell_id => 5301,
    #                    :stats => {'multistrike' => 30},
    #                    :icon => 'inv_enchant_formulagood_01',
    #                    :item_name => 'Enchant Ring - Breath of Multistrike',
    #                    :equip_location => 11 # Ring
    #                })
    # Enchant.create({
    #                    :spell_id => 5299,
    #                    :stats => {'mastery' => 30},
    #                    :icon => 'inv_enchant_formulagood_01',
    #                    :item_name => 'Enchant Ring - Breath of Mastery',
    #                    :equip_location => 11 # Ring
    #                })
    # Enchant.create({
    #                    :spell_id => 5297,
    #                    :stats => {'haste' => 30},
    #                    :icon => 'inv_enchant_formulagood_01',
    #                    :item_name => 'Enchant Ring - Breath of Haste',
    #                    :equip_location => 11 # Ring
    #                })
    # Enchant.create({
    #                    :spell_id => 5284,
    #                    :stats => {'crit' => 30},
    #                    :icon => 'inv_enchant_formulagood_01',
    #                    :item_name => 'Enchant Ring - Breath of Critical Strike',
    #                    :equip_location => 11 # Ring
    #                })
    # Enchant.create({
    #                    :spell_id => 5328,
    #                    :stats => {'versatility' => 50},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Ring - Gift of Versatility',
    #                    :equip_location => 11 # Ring
    #                })
    # Enchant.create({
    #                    :spell_id => 5327,
    #                    :stats => {'multistrike' => 50},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Ring - Gift of Multistrike',
    #                    :equip_location => 11 # Ring
    #                })
    # Enchant.create({
    #                    :spell_id => 5326,
    #                    :stats => {'mastery' => 50},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Ring - Gift of Mastery',
    #                    :equip_location => 11 # Ring
    #                })
    # Enchant.create({
    #                    :spell_id => 5325,
    #                    :stats => {'haste' => 50},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Ring - Gift of Haste',
    #                    :equip_location => 11 # Ring
    #                })
    # Enchant.create({
    #                    :spell_id => 5324,
    #                    :stats => {'crit' => 50},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Ring - Gift of Critical Strike',
    #                    :equip_location => 11 # Ring
    #                })
    # # WOD NECK
    # Enchant.create({
    #                    :spell_id => 5295,
    #                    :stats => {'versatility' => 40},
    #                    :icon => 'inv_enchant_formulagood_01',
    #                    :item_name => 'Enchant Neck - Breath of Versatility',
    #                    :equip_location => 2 # Neck
    #                })
    # Enchant.create({
    #                    :spell_id => 5294,
    #                    :stats => {'multistrike' => 40},
    #                    :icon => 'inv_enchant_formulagood_01',
    #                    :item_name => 'Enchant Neck - Breath of Multistrike',
    #                    :equip_location => 2 # Neck
    #                })
    # Enchant.create({
    #                    :spell_id => 5293,
    #                    :stats => {'mastery' => 40},
    #                    :icon => 'inv_enchant_formulagood_01',
    #                    :item_name => 'Enchant Neck - Breath of Mastery',
    #                    :equip_location => 2 # Neck
    #                })
    # Enchant.create({
    #                    :spell_id => 5292,
    #                    :stats => {'haste' => 40},
    #                    :icon => 'inv_enchant_formulagood_01',
    #                    :item_name => 'Enchant Neck - Breath of Haste',
    #                    :equip_location => 2 # Neck
    #                })
    # Enchant.create({
    #                    :spell_id => 5285,
    #                    :stats => {'crit' => 40},
    #                    :icon => 'inv_enchant_formulagood_01',
    #                    :item_name => 'Enchant Neck - Breath of Critical Strike',
    #                    :equip_location => 2 # Neck
    #                })
    # Enchant.create({
    #                    :spell_id => 5321,
    #                    :stats => {'versatility' => 75},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Neck - Gift of Versatility',
    #                    :equip_location => 2 # Neck
    #                })
    # Enchant.create({
    #                    :spell_id => 5320,
    #                    :stats => {'multistrike' => 75},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Neck - Gift of Multistrike',
    #                    :equip_location => 2 # Neck
    #                })
    # Enchant.create({
    #                    :spell_id => 5319,
    #                    :stats => {'mastery' => 75},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Neck - Gift of Mastery',
    #                    :equip_location => 2 # Neck
    #                })
    # Enchant.create({
    #                    :spell_id => 5318,
    #                    :stats => {'haste' => 75},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Neck - Gift of Haste',
    #                    :equip_location => 2 # Neck
    #                })
    # Enchant.create({
    #                    :spell_id => 5317,
    #                    :stats => {'crit' => 75},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Neck - Gift of Critical Strike',
    #                    :equip_location => 2 # Neck
    #                })
    # # WOD CLOAK
    # Enchant.create({
    #                    :spell_id => 5304,
    #                    :stats => {'versatility' => 100},
    #                    :icon => 'inv_enchant_formulagood_01',
    #                    :item_name => 'Enchant Cloak - Breath of Versatility',
    #                    :equip_location => 16 # Cloak
    #                })
    # Enchant.create({
    #                    :spell_id => 5302,
    #                    :stats => {'multistrike' => 100},
    #                    :icon => 'inv_enchant_formulagood_01',
    #                    :item_name => 'Enchant Cloak - Breath of Multistrike',
    #                    :equip_location => 16 # Cloak
    #                })
    # Enchant.create({
    #                    :spell_id => 5300,
    #                    :stats => {'mastery' => 100},
    #                    :icon => 'inv_enchant_formulagood_01',
    #                    :item_name => 'Enchant Cloak - Breath of Mastery',
    #                    :equip_location => 16 # Cloak
    #                })
    # Enchant.create({
    #                    :spell_id => 5298,
    #                    :stats => {'haste' => 100},
    #                    :icon => 'inv_enchant_formulagood_01',
    #                    :item_name => 'Enchant Cloak - Breath of Haste',
    #                    :equip_location => 16 # Cloak
    #                })
    # Enchant.create({
    #                    :spell_id => 5281,
    #                    :stats => {'crit' => 100},
    #                    :icon => 'inv_enchant_formulagood_01',
    #                    :item_name => 'Enchant Cloak - Breath of Critical Strike',
    #                    :equip_location => 16 # Cloak
    #                })
    # Enchant.create({
    #                    :spell_id => 5314,
    #                    :stats => {'versatility' => 100},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Cloak - Gift of Versatility',
    #                    :equip_location => 16 # Cloak
    #                })
    # Enchant.create({
    #                    :spell_id => 5313,
    #                    :stats => {'multistrike' => 100},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Cloak - Gift of Multistrike',
    #                    :equip_location => 16 # Cloak
    #                })
    # Enchant.create({
    #                    :spell_id => 5312,
    #                    :stats => {'mastery' => 100},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Cloak - Gift of Mastery',
    #                    :equip_location => 16 # Cloak
    #                })
    # Enchant.create({
    #                    :spell_id => 5311,
    #                    :stats => {'haste' => 100},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Cloak - Gift of Haste',
    #                    :equip_location => 16 # Cloak
    #                })
    # Enchant.create({
    #                    :spell_id => 5310,
    #                    :stats => {'crit' => 100},
    #                    :icon => 'inv_enchant_formulasuperior_01',
    #                    :item_name => 'Enchant Cloak - Gift of Critical Strike',
    #                    :equip_location => 16 # Cloak
    #                })

    # MOP Enchants
    Enchant.create({
                       :spell_id => 5125,
                       :stats => {},
                       :icon => 'inv_enchant_formulasuperior_01',
                       :item_name => 'Enchant Weapon - Bloody Dancing Steel',
                       :equip_location => 13,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4444,
                       :stats => {},
                       :icon => 'inv_enchant_formulasuperior_01',
                       :item_name => 'Enchant Weapon - Dancing Steel',
                       :equip_location => 13,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4443,
                       :stats => {},
                       :icon => 'inv_enchant_formulasuperior_01',
                       :item_name => 'Enchant Weapon - Elemental Force',
                       :equip_location => 13,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4441,
                       :stats => {},
                       :icon => 'inv_enchant_formulasuperior_01',
                       :item_name => 'Enchant Weapon - Windsong',
                       :equip_location => 13,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4918,
                       :stats => {'crit' => 12},
                       :icon => 'inv_enchant_formulasuperior_01',
                       :item_name => 'Living Steel Weapon Chain',
                       :equip_location => 13,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4433,
                       :stats => {'mastery' => 13},
                       :icon => 'inv_enchant_formulasuperior_01',
                       :item_name => 'Enchant Gloves - Superior Mastery',
                       :equip_location => 10,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4430,
                       :stats => {'haste' => 11},
                       :icon => 'inv_enchant_formulasuperior_01',
                       :item_name => 'Enchant Gloves - Greater Haste',
                       :equip_location => 10,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4431,
                       :stats => {'haste' => 11},
                       :icon => 'inv_enchant_formulasuperior_01',
                       :item_name => 'Enchant Gloves - Superior Haste',
                       :equip_location => 10,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4432,
                       :stats => {'strength' => 11},
                       :icon => 'inv_enchant_formulasuperior_01',
                       :item_name => 'Enchant Gloves - Super Strength',
                       :equip_location => 10,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4908,
                       :stats => {'agility' => 12, 'crit' => 5},
                       :icon => 'inv_inscription_runescrolloffortitude_blue',
                       :item_name => 'Tiger Claw Inscription',
                       :equip_location => 3,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4804,
                       :stats => {'agility' => 15, 'crit' => 5},
                       :icon => 'inv_inscription_runescrolloffortitude_yellow',
                       :item_name => 'Greater Tiger Claw Inscription',
                       :equip_location => 3,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4914,
                       :stats => {'agility' => 20, 'crit' => 5},
                       :icon => 'inv_misc_mastersinscription',
                       :item_name => 'Secret Tiger Claw Inscription',
                       :equip_location => 3,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4419,
                       :stats => {'agility' => 5, 'strength' => 5, 'stamina' => 5},
                       :icon => 'inv_misc_enchantedscroll',
                       :item_name => 'Enchant Chest - Glorious Stats',
                       :equip_location => 5,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4880,
                       :stats => {'agility' => 18, 'crit' => 10},
                       :icon => 'inv_misc_cataclysmarmorkit_12',
                       :item_name => 'Primal Leg Reinforcements',
                       :equip_location => 7,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4822,
                       :stats => {'agility' => 19, 'crit' => 11},
                       :icon => 'inv_misc_cataclysmarmorkit_02',
                       :item_name => 'Shadowleather Leg Armor',
                       :equip_location => 7,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4871,
                       :stats => {'agility' => 11, 'crit' => 7},
                       :icon => 'inv_misc_cataclysmarmorkit_01',
                       :item_name => 'Sha-Touched Leg Armor',
                       :equip_location => 7,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4429,
                       :stats => {'mastery' => 9},
                       :icon => 'inv_misc_enchantedscroll',
                       :item_name => "Enchant Boots - Pandaren's Step",
                       :equip_location => 8,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4428,
                       :stats => {'agility' => 9},
                       :icon => 'inv_misc_enchantedscroll',
                       :item_name => 'Enchant Boots - Blurred Speed',
                       :equip_location => 8,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4426,
                       :stats => {'haste' => 11},
                       :icon => 'inv_misc_enchantedscroll',
                       :item_name => 'Enchant Boots - Greater Haste',
                       :equip_location => 8,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4427,
                       :stats => {'crit' => 11},
                       :icon => 'inv_misc_enchantedscroll',
                       :item_name => 'Enchant Boots - Greater Precision',
                       :equip_location => 8,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4416,
                       :stats => {'agility' => 12},
                       :icon => 'inv_misc_enchantedscroll',
                       :item_name => 'Enchant Bracer - Greater Agility',
                       :equip_location => 9,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4411,
                       :stats => {'mastery' => 11},
                       :icon => 'inv_misc_enchantedscroll',
                       :item_name => 'Enchant Bracer - Mastery',
                       :equip_location => 9,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4421,
                       :stats => {'crit' => 12},
                       :icon => 'inv_misc_enchantedscroll',
                       :item_name => 'Enchant Cloak - Accuracy',
                       :equip_location => 16,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    Enchant.create({
                       :spell_id => 4424,
                       :stats => {'crit' => 12},
                       :icon => 'inv_misc_enchantedscroll',
                       :item_name => 'Enchant Cloak - Superior Critical Strike',
                       :equip_location => 16,
                       :requires => {
                           :max_item_level => 600
                       }
                   })
    true
  end

  def self.populate_from_wowhead
    self.destroy_all
    url = 'http://www.wowhead.com/items=0.6'
    doc = open(url).read
    ids = doc.scan(/_\[(\d+)\]=\{.*?\}/).flatten.map &:to_i
    ids.each do |id|
      puts id
      doc = open('http://www.wowhead.com/item=%d&xml' % id).read
      xml = Nokogiri::XML(doc)
      json = JSON::load('{%s}' % xml.css('json').text)
      puts xml.css('name').text
      #puts json.inspect
      jsonequip = JSON::load('{%s}' % xml.css('jsonEquip').text)
      puts jsonequip.inspect
      name_match = ACCEPTED_ENCHANTS.detect { |n| name.match(n) }
      if name_match or (x = jsonequip.keys & keys and x.length > 0)
        x ||= {}
        puts "Adding #{name}..."
        slot = get_slots(slots[index].to_i)
        Enchant.create({
                           :spell_id => k.to_i,
                           :stats => Hash[*x.map { |rk| [JSON_TO_INTERNAL[rk], jsonequip[rk].to_i] }.flatten],
                           :icon => [i['icon']].flatten.first.downcase,
                           :item_name => name,
                           :equip_location => slot
                       })
      else
        puts "Not adding #{name}"
      end
    end
  end
end
