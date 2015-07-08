module WowArmory
  module Constants

    BONUS_ACTIONS = {
      1 => :ADJUST_ITEM_LEVEL,
      2 => :MODIFY_STATS,
      3 => :CHANGE_ITEM_QUALITY,
      4 => :ADD_ITEM_TITLES,
      5 => :APPEND_WORDS_TO_ITEM_NAME,
      6 => :ADD_SOCKETS,
      7 => :ADJUST_ITEM_APPEARANCE_ID,
      8 => :ADJUST_EQUIP_LEVEL,
      9 => :UNKNOWN_1,
      10 => :UNKNOWN_2,
    }
  
    ENCHANT_SCALING = 10.0 # for lvl 90 // lvl100 = 80
    
    CLASS_MAP = {
      4 => 'rogue'
    }
    
    POWER_TYPES = [:mana, :rage, :focus, :energy]
    
    RACE_MAP = {
      1 => 'Human',
      2 => 'Orc',
      3 => 'Dwarf',
      4 => 'Night Elf',
      5 => 'Undead',
      6 => 'Tauren',
      7 => 'Gnome',
      8 => 'Troll',
      9 => 'Goblin',
      10 => 'Blood Elf',
      11 => 'Draenei',
      22 => 'Worgen',
      24 => 'Pandaren',
      25 => 'Pandaren',
      26 => 'Pandaren'
    }

    SLOT_MAP = {
      'head' => 0,
      'neck' => 1,
      'shoulder' => 2,
      'back' => 14,
      'chest' => 4,
      'wrist' => 8,
      'hands' => 9,
      'waist' => 5,
      'legs' => 6,
      'feet' => 7,
      'finger1' => 10,
      'finger2' => 11,
      'trinket1' => 12,
      'trinket2' => 13,
      'mainHand' => 15,
      'offHand' => 16,
    }

    
    SOCKET_MAP = {
      1 => 'Meta',
      2 => 'Red',
      8 => 'Blue',
      4 => 'Yellow',
      14 => 'Prismatic',
      16 => 'Hydraulic',
      32 => 'Cogwheel'
    }

    STAT_LOOKUP = {
      1 => :health,
      2 => :mana,
      3 => :agility,
      4 => :strength,
      5 => :intellect,
      6 => :spirit,
      7 => :stamina,
      12 => :defense,
      13 => :dodge,
      14 => :parry,
      15 => :shield_block,
      31 => :hit,
      32 => :crit,
      33 => :hit_avoidance,
      34 => :critical_strike_avoidance,
      35 => :pvp_resilience,
      36 => :haste,
      37 => :expertise,
      38 => :attack_power,
      40 => :versatility,
      41 => :damage_done,
      42 => :healing_done,
      43 => :mana_every_5_seconds,
      44 => :armor_penetration,
      45 => :power,
      46 => :health_every_5_seconds,
      47 => :penetration,
      48 => :block_value,
      49 => :mastery,
      50 => :bonus_armor,
      57 => :pvp_power,
      58 => :amplify,
      59 => :multistrike,
      61 => :speed,
      62 => :leech,
      63 => :avoidance,
      64 => :indestructible,
      67 => :versatility,
      71 => :agility,
      72 => :agility,
      73 => :agility,
    }
    
    WOWHEAD_STAT_MAP = {
      'hitrtng' => 'hit',
      'hastertng' => 'haste',
      'critstrkrtng' => 'crit',
      'mastrtng' => 'mastery',
      'exprtng' => 'expertise',
      'agi' => 'agility',
      'sta' => 'stamina',
      'pvppower' => 'pvp_power',
      'resirtng' => 'pvp_resilience',
      'multistrike' => 'multistrike',
      'versatility' => 'versatility'
    }

    # redundant to character.rb
    PROF_MAP = {
      164 => 'blacksmithing',
      165 => 'leatherworking',
      171 => 'alchemy',
      182 => 'herbalism',
      186 => 'mining',
      197 => 'tailoring',
      202 => 'engineering',
      333 => 'enchanting',
      393 => 'skinning'
      755 => 'jewelcrafting',
      773 => 'inscription',
    }

    ARMOR_CLASS = {
      1 => 'Cloth',
      2 => 'Leather',
      3 => 'Mail',
      4 => 'Plate'
    }

    GEM_SUBCLASS_MAP = {
      0 => 'Red',
      1 => 'Blue',
      2 => 'Yellow',
      3 => 'Purple',
      4 => 'Green',
      5 => 'Orange',
      6 => 'Meta',
      #7 => "Simple",
      8 => 'Prismatic',
      9 => 'Hydraulic',
      10 => 'Cogwheel'
    }

    SCAN_ATTRIBUTES = ['agility', 'strength', 'intellect', 'spirit',
                       'stamina', 'attack power', 'critical strike',
                       'versatility', 'multistrike', 'haste', 'mastery',
                       'pvp resilience', 'pvp power', 'all stats',
                       'dodge', 'block', 'parry'
                      ]
    
    SCAN_OVERRIDE = { 'critical strike' => 'crit',
                      #"hit" => "hit rating",
                      #"expertise" => "expertise rating",
                      #"haste" => "haste rating",
                      #"mastery" => "mastery rating",
                      #"pvp resilience" => "resilience",
                      #"pvp power" => "pvp power rating"
                    }

  end
end
