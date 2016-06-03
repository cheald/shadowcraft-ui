class Enchant
  include Mongoid::Document
  include WowArmory::Constants

  field :spell_id, :type => Integer
  field :stats, :type => Hash
  field :icon
  field :item_name
  field :equip_location, :type => Integer
  field :requires, :type => Hash
  field :tooltip_spell, :type => Integer

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
      :requires => requires,
      :tooltip_spell => tooltip_spell
    }
  end
  
  def self.update_from_json
    
    # first delete all existing enchants in the database
    Enchant.delete_all

    self.import_wod
  end

  def self.import_wod

    # WOD WEAPON
    Enchant.create({
                     :spell_id => 5330,
                     :stats => {},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Weapon - Mark of the Thunderlord',
                     :equip_location => 13,
                     :tooltip_spell => 110682
                   })
    Enchant.create({
                     :spell_id => 5331,
                     :stats => {},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Weapon - Mark of the Shattered Hand',
                     :equip_location => 13,
                     :tooltip_spell => 112093
                   })
    Enchant.create({
                     :spell_id => 5334,
                     :stats => {},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Weapon - Mark of the Frostwolf',
                     :equip_location => 13,
                     :tooltip_spell => 112165
                   })
    Enchant.create({
                     :spell_id => 5337,
                     :stats => {},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Weapon - Mark of Warsong',
                     :equip_location => 13,
                     :tooltip_spell => 112164
                   })
    Enchant.create({
                     :spell_id => 5384,
                     :stats => {},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Weapon - Mark of Bleeding Hollow',
                     :equip_location => 13,
                     :tooltip_spell => 118015
                   })
    # WOD RING
    Enchant.create({
                     :spell_id => 5303,
                     :stats => {'versatility' => 30},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Ring - Breath of Versatility',
                     :equip_location => 11, # Ring
                     :tooltip_spell => 110621
                   })
    Enchant.create({
                     :spell_id => 5301,
                     :stats => {'multistrike' => 30},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Ring - Breath of Multistrike',
                     :equip_location => 11, # Ring
                     :tooltip_spell => 110620
                   })
    Enchant.create({
                     :spell_id => 5299,
                     :stats => {'mastery' => 30},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Ring - Breath of Mastery',
                     :equip_location => 11, # Ring
                     :tooltip_spell => 110619
                   })
    Enchant.create({
                     :spell_id => 5297,
                     :stats => {'haste' => 30},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Ring - Breath of Haste',
                     :equip_location => 11, # Ring
                     :tooltip_spell => 110618
                   })
    Enchant.create({
                     :spell_id => 5284,
                     :stats => {'crit' => 30},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Ring - Breath of Critical Strike',
                     :equip_location => 11, # Ring
                     :tooltip_spell => 110617
                   })
    Enchant.create({
                     :spell_id => 5328,
                     :stats => {'versatility' => 50},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Ring - Gift of Versatility',
                     :equip_location => 11, # Ring
                     :tooltip_spell => 110642
                   })
    Enchant.create({
                     :spell_id => 5327,
                     :stats => {'multistrike' => 50},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Ring - Gift of Multistrike',
                     :equip_location => 11, # Ring
                     :tooltip_spell => 110641
                   })
    Enchant.create({
                     :spell_id => 5326,
                     :stats => {'mastery' => 50},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Ring - Gift of Mastery',
                     :equip_location => 11, # Ring
                     :tooltip_spell => 110640
                   })
    Enchant.create({
                     :spell_id => 5325,
                     :stats => {'haste' => 50},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Ring - Gift of Haste',
                     :equip_location => 11, # Ring
                     :tooltip_spell => 110639
                   })
    Enchant.create({
                     :spell_id => 5324,
                     :stats => {'crit' => 50},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Ring - Gift of Critical Strike',
                     :equip_location => 11, # Ring
                     :tooltip_spell => 110638
                   })
    # WOD NECK
    Enchant.create({
                     :spell_id => 5295,
                     :stats => {'versatility' => 40},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Neck - Breath of Versatility',
                     :equip_location => 2, # Neck
                     :tooltip_spell => 110628
                   })
    Enchant.create({
                     :spell_id => 5294,
                     :stats => {'multistrike' => 40},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Neck - Breath of Multistrike',
                     :equip_location => 2, # Neck
                     :tooltip_spell => 110627
                   })
    Enchant.create({
                     :spell_id => 5293,
                     :stats => {'mastery' => 40},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Neck - Breath of Mastery',
                     :equip_location => 2, # Neck
                     :tooltip_spell => 110626
                   })
    Enchant.create({
                     :spell_id => 5292,
                     :stats => {'haste' => 40},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Neck - Breath of Haste',
                     :equip_location => 2, # Neck
                     :tooltip_spell => 110625
                   })
    Enchant.create({
                     :spell_id => 5285,
                     :stats => {'crit' => 40},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Neck - Breath of Critical Strike',
                     :equip_location => 2, # Neck
                     :tooltip_spell => 110624
                   })
    Enchant.create({
                     :spell_id => 5321,
                     :stats => {'versatility' => 75},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Neck - Gift of Versatility',
                     :equip_location => 2, # Neck
                     :tooltip_spell => 110649
                   })
    Enchant.create({
                     :spell_id => 5320,
                     :stats => {'multistrike' => 75},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Neck - Gift of Multistrike',
                     :equip_location => 2, # Neck
                     :tooltip_spell => 110648
                   })
    Enchant.create({
                     :spell_id => 5319,
                     :stats => {'mastery' => 75},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Neck - Gift of Mastery',
                     :equip_location => 2, # Neck
                     :tooltip_spell => 110647
                   })
    Enchant.create({
                     :spell_id => 5318,
                     :stats => {'haste' => 75},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Neck - Gift of Haste',
                     :equip_location => 2, # Neck
                     :tooltip_spell => 110646
                   })
    Enchant.create({
                     :spell_id => 5317,
                     :stats => {'crit' => 75},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Neck - Gift of Critical Strike',
                     :equip_location => 2, # Neck
                     :tooltip_spell => 110645
                   })
    # WOD CLOAK
    Enchant.create({
                     :spell_id => 5304,
                     :stats => {'versatility' => 100},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Cloak - Breath of Versatility',
                     :equip_location => 16, # Cloak
                     :tooltip_spell => 110635
                   })
    Enchant.create({
                     :spell_id => 5302,
                     :stats => {'multistrike' => 100},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Cloak - Breath of Multistrike',
                     :equip_location => 16, # Cloak
                     :tooltip_spell => 110634
                   })
    Enchant.create({
                     :spell_id => 5300,
                     :stats => {'mastery' => 100},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Cloak - Breath of Mastery',
                     :equip_location => 16, # Cloak
                     :tooltip_spell => 110633
                   })
    Enchant.create({
                     :spell_id => 5298,
                     :stats => {'haste' => 100},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Cloak - Breath of Haste',
                     :equip_location => 16, # Cloak
                     :tooltip_spell => 110632
                   })
    Enchant.create({
                     :spell_id => 5281,
                     :stats => {'crit' => 100},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Cloak - Breath of Critical Strike',
                     :equip_location => 16, # Cloak
                     :tooltip_spell => 110631
                   })
    Enchant.create({
                     :spell_id => 5314,
                     :stats => {'versatility' => 100},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Cloak - Gift of Versatility',
                     :equip_location => 16, # Cloak
                     :tooltip_spell => 110656
                   })
    Enchant.create({
                     :spell_id => 5313,
                     :stats => {'multistrike' => 100},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Cloak - Gift of Multistrike',
                     :equip_location => 16, # Cloak
                     :tooltip_spell => 110655
                   })
    Enchant.create({
                     :spell_id => 5312,
                     :stats => {'mastery' => 100},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Cloak - Gift of Mastery',
                     :equip_location => 16, # Cloak
                     :tooltip_spell => 110654
                   })
    Enchant.create({
                     :spell_id => 5311,
                     :stats => {'haste' => 100},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Cloak - Gift of Haste',
                     :equip_location => 16, # Cloak
                     :tooltip_spell => 110653
                   })
    Enchant.create({
                     :spell_id => 5310,
                     :stats => {'crit' => 100},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Cloak - Gift of Critical Strike',
                     :equip_location => 16, # Cloak
                     :tooltip_spell => 110652
                   })
    true
  end
end
