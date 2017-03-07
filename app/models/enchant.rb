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
  field :is_proc, :type => Boolean, :default => false

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
      :tooltip_item => tooltip_spell,
      :is_proc => is_proc
    }
  end
  
  def self.update_from_json
    
    # first delete all existing enchants in the database
    Enchant.delete_all

    self.import_legion
  end

  def self.import_legion

    # Cloak
    Enchant.create({
                     :spell_id => 5432,
                     :stats => {'agility' => 150},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Cloak - Word of Agility',
                     :equip_location => 16,
                     :tooltip_spell => 128546,
                   })

    Enchant.create({
                     :spell_id => 5435,
                     :stats => {'agility' => 200},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Cloak - Binding of Agility',
                     :equip_location => 16,
                     :tooltip_spell => 128549,
                   })

    # Ring
    Enchant.create({
                     :spell_id => 5423,
                     :stats => {'crit' => 150},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Ring - Word of Critical Strike',
                     :equip_location => 11,
                     :tooltip_spell => 128537,
                   })

    Enchant.create({
                     :spell_id => 5424,
                     :stats => {'haste' => 150},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Ring - Word of Haste',
                     :equip_location => 11,
                     :tooltip_spell => 128538,
                   })

    Enchant.create({
                     :spell_id => 5425,
                     :stats => {'mastery' => 150},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Ring - Word of Mastery',
                     :equip_location => 11,
                     :tooltip_spell => 128539,
                   })

    Enchant.create({
                     :spell_id => 5426,
                     :stats => {'versatility' => 150},
                     :icon => 'inv_enchant_formulagood_01',
                     :item_name => 'Enchant Ring - Word of Versatility',
                     :equip_location => 11,
                     :tooltip_spell => 128540,
                   })

    Enchant.create({
                     :spell_id => 5427,
                     :stats => {'crit' => 200},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Ring - Binding of Critical Strike',
                     :equip_location => 11,
                     :tooltip_spell => 128541,
                   })

    Enchant.create({
                     :spell_id => 5428,
                     :stats => {'haste' => 200},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Ring - Binding of Haste',
                     :equip_location => 11,
                     :tooltip_spell => 128542,
                   })

    Enchant.create({
                     :spell_id => 5429,
                     :stats => {'mastery' => 200},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Ring - Binding of Mastery',
                     :equip_location => 11,
                     :tooltip_spell => 128543,
                   })

    Enchant.create({
                     :spell_id => 5430,
                     :stats => {'versatility' => 200},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Ring - Binding of Versatility',
                     :equip_location => 11,
                     :tooltip_spell => 128544,
                   })

    # Neck
    Enchant.create({
                     :spell_id => 5437,
                     :stats => {},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Neck - Mark of the Claw',
                     :equip_location => 2,
                     :tooltip_spell => 128551,
                     :is_proc => true
                   })

    Enchant.create({
                     :spell_id => 5438,
                     :stats => {},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Neck - Mark of the Distant Army',
                     :equip_location => 2,
                     :tooltip_spell => 128552,
                     :is_proc => true
                   })

    Enchant.create({
                     :spell_id => 5439,
                     :stats => {},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Neck - Mark of the Hidden Satyr',
                     :equip_location => 2,
                     :tooltip_spell => 128553,
                     :is_proc => true
                   })

    Enchant.create({
                     :spell_id => 5890,
                     :stats => {'mastery' => 300},
                     :icon => 'inv_enchant_formulasuperior_01',
                     :item_name => 'Enchant Neck - Mark of the Trained Soldier',
                     :equip_location => 2,
                     :tooltip_spell => 141909,
                     :is_proc => false
                   })

    true
  end
end
