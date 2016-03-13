# This is dead-simple code to load talent data from the armory following
# the model of the other data types.
module WowArmory
  class Talents
    unloadable

    include Constants
    include Document

    attr_accessor :talents

    def initialize(region = 'US', version = "wod")

      # Clear out everything that we have already
      self.talents = {'a': [], 'Z': [], 'b': []}

      if (version == "wod")
        puts "loading wod talents"
        @json = WowArmory::Document.fetch region, '/wow/data/talents', {}

        # Parse the json from the API
        @json['4']['talents'].each do |tier|
          tier.each do |column|
            a = nil
            z = nil
            b = nil
            nospec = nil

            # Loop through each column, looking to see if we have special talents
            # for any of the specs. Also store off the talent that has no spec
            # associated with it.
            column.each do |talent|

              if !talent.key?('spec')
                puts "found talent with no spec"
                nospec = {'tier' => talent['tier'], 'column' => talent['column'], 'spell' => talent['spell']['id'],
                  'name' => talent['spell']['name'], 'icon' => talent['spell']['icon']}
              else
                if talent['spec']['name'] == 'Assassination'
                  puts "found assn talent"
                  a = {'tier' => talent['tier'], 'column' => talent['column'], 'spell' => talent['spell']['id'],
                    'name' => talent['spell']['name'], 'icon' => talent['spec']['icon']}
                elsif talent['spec']['name'] == 'Outlaw'
                  puts "found outlaw talent"
                  z = {'tier' => talent['tier'], 'column' => talent['column'], 'spell' => talent['spell']['id'],
                    'name' => talent['spell']['name'], 'icon' => talent['spec']['icon']}
                elsif talent['spec']['name'] == 'Subtlety'
                  puts "found sub talent"
                  b = {'tier' => talent['tier'], 'column' => talent['column'], 'spell' => talent['spell']['id'],
                    'name' => talent['spell']['name'], 'icon' => talent['spec']['icon']}
                end
              end
            end

            talents[:a] << (if a.nil? then nospec else a end)
            talents[:Z] << (if z.nil? then nospec else z end)
            talents[:b] << (if b.nil? then nospec else b end)
          end
        end

      elsif (version == "legion")
        puts "loading legion talents"
        self.talents[:a] << {tier: 0, column: 0, spell: 196864, name: "Master Poisoner", icon: "ability_creature_poison_06"}
        self.talents[:a] << {tier: 0, column: 1, spell: 193640, name: "Elaborate Planning", icon: "inv_misc_map08"}
        self.talents[:a] << {tier: 0, column: 2, spell: 16511, name: "Hemorrhage", icon: "spell_shadow_lifedrain"}
        self.talents[:a] << {tier: 1, column: 0, spell: 14062, name: "Nightstalker", icon: "ability_stealth"}
        self.talents[:a] << {tier: 1, column: 1, spell: 108208, name: "Subterfuge", icon: "rogue_subterfuge"}
        self.talents[:a] << {tier: 1, column: 2, spell: 108209, name: "Shadow Focus", icon: "rogue_shadowfocus"}
        self.talents[:a] << {tier: 2, column: 0, spell: 193531, name: "Deeper Strategem", icon: "archaeology_5_0_changkiboard"}
        self.talents[:a] << {tier: 2, column: 1, spell: 114015, name: "Anticipation", icon: "ability_rogue_slaughterfromtheshadows"}
        self.talents[:a] << {tier: 2, column: 2, spell: 14983, name: "Vigor", icon: "ability_rogue_vigor"}
        self.talents[:a] << {tier: 3, column: 0, spell: 108211, name: "Leeching Poison", icon: "rogue_leeching_poison"}
        self.talents[:a] << {tier: 3, column: 1, spell: 79008, name: "Elusiveness", icon: "ability_rogue_turnthetables"}
        self.talents[:a] << {tier: 3, column: 2, spell: 31230, name: "Cheat Death", icon: "ability_rogue_cheatdeath"}
        self.talents[:a] << {tier: 4, column: 0, spell: 196861, name: "Thuggee", icon: "inv_misc_bandana_03"}
        self.talents[:a] << {tier: 4, column: 1, spell: 131511, name: "Prey on the Weak", icon: "ability_rogue_preyontheweak"}
        self.talents[:a] << {tier: 4, column: 2, spell: 154904, name: "Internal Bleeding", icon: "ability_rogue_bloodsplatter"}
        self.talents[:a] << {tier: 5, column: 0, spell: 200802, name: "Numbing Poison", icon: "inv_poison_mindnumbing"}
        self.talents[:a] << {tier: 5, column: 1, spell: 193539, name: "Alacrity", icon: "ability_paladin_speedoflight"}
        self.talents[:a] << {tier: 5, column: 2, spell: 200806, name: "Blood Sweat (NYI)", icon: "ability_deathwing_bloodcorruption_earth"}
        self.talents[:a] << {tier: 6, column: 0, spell: 152152, name: "Venom Rush", icon: "rogue_venomzest"}
        self.talents[:a] << {tier: 6, column: 1, spell: 137619, name: "Marked for Death", icon: "achievement_bg_killingblow_berserker"}
        self.talents[:a] << {tier: 6, column: 2, spell: 152150, name: "Death from Above", icon: "spell_rogue_deathfromabove"}
        self.talents[:Z] << {tier: 0, column: 0, spell: 196937, name: "Ghostly Strike", icon: "ability_creature_cursed_02"}
        self.talents[:Z] << {tier: 0, column: 1, spell: 200733, name: "Swordmaster", icon: "inv_sword_97"}
        self.talents[:Z] << {tier: 0, column: 2, spell: 196938, name: "Quick Draw", icon: "inv_weapon_rifle_40"}
        self.talents[:Z] << {tier: 1, column: 0, spell: 195457, name: "Grappling Hook", icon: "inv_archaeology_orcclans_barbedhook"}
        self.talents[:Z] << {tier: 1, column: 1, spell: 196924, name: "Acrobatic Strikes", icon: "spell_warrior_wildstrike"}
        self.talents[:Z] << {tier: 1, column: 2, spell: 196922, name: "Into the Fray ", icon: "ability_warrior_charge"}
        self.talents[:Z] << {tier: 2, column: 0, spell: 193531, name: "Deeper Strategem", icon: "archaeology_5_0_changkiboard"}
        self.talents[:Z] << {tier: 2, column: 1, spell: 114015, name: "Anticipation", icon: "ability_rogue_slaughterfromtheshadows"}
        self.talents[:Z] << {tier: 2, column: 2, spell: 14983, name: "Vigor", icon: "ability_rogue_vigor"}
        self.talents[:Z] << {tier: 3, column: 0, spell: 193546, name: "Iron Stomach", icon: "inv_misc_organ_11"}
        self.talents[:Z] << {tier: 3, column: 1, spell: 79008, name: "Elusiveness", icon: "ability_rogue_turnthetables"}
        self.talents[:Z] << {tier: 3, column: 2, spell: 31230, name: "Cheat Death", icon: "ability_rogue_cheatdeath"}
        self.talents[:Z] << {tier: 4, column: 0, spell: 199743, name: "Parley", icon: "achievement_character_human_male"}
        self.talents[:Z] << {tier: 4, column: 1, spell: 131511, name: "Prey on the Weak", icon: "ability_rogue_preyontheweak"}
        self.talents[:Z] << {tier: 4, column: 2, spell: 108216, name: "Dirty Tricks", icon: "ability_rogue_dirtydeeds"}
        self.talents[:Z] << {tier: 5, column: 0, spell: 185767, name: "Cannonball Barrage", icon: "ability_vehicle_siegeenginecannon"}
        self.talents[:Z] << {tier: 5, column: 1, spell: 193539, name: "Alacrity", icon: "ability_paladin_speedoflight"}
        self.talents[:Z] << {tier: 5, column: 2, spell: 51690, name: "Killing Spree", icon: "ability_rogue_murderspree"}
        self.talents[:Z] << {tier: 6, column: 0, spell: 193316, name: "Roll the Bones", icon: "ability_rogue_rollthebones01"}
        self.talents[:Z] << {tier: 6, column: 1, spell: 137619, name: "Marked for Death", icon: "achievement_bg_killingblow_berserker"}
        self.talents[:Z] << {tier: 6, column: 2, spell: 152150, name: "Death from Above", icon: "spell_rogue_deathfromabove"}

        self.talents[:b] << {tier: 0, column: 0, spell: 31223, name: "Master of Subtlety", icon: "ability_rogue_masterofsubtlety"}
        self.talents[:b] << {tier: 0, column: 1, spell: 193537, name: "Weaponmaster", icon: "ability_ironmaidens_bladerush"}
        self.talents[:b] << {tier: 0, column: 2, spell: 200758, name: "Gloomblade", icon: "ability_ironmaidens_convulsiveshadows"}
        self.talents[:b] << {tier: 1, column: 0, spell: 14062, name: "Nightstalker", icon: "ability_stealth"}
        self.talents[:b] << {tier: 1, column: 1, spell: 108208, name: "Subterfuge", icon: "rogue_subterfuge"}
        self.talents[:b] << {tier: 1, column: 2, spell: 108209, name: "Shadow Focus", icon: "rogue_shadowfocus"}
        self.talents[:b] << {tier: 2, column: 0, spell: 193531, name: "Deeper Strategem", icon: "archaeology_5_0_changkiboard"}
        self.talents[:b] << {tier: 2, column: 1, spell: 114015, name: "Anticipation", icon: "ability_rogue_slaughterfromtheshadows"}
        self.talents[:b] << {tier: 2, column: 2, spell: 14983, name: "Vigor", icon: "ability_rogue_vigor"}
        self.talents[:b] << {tier: 3, column: 0, spell: 200759, name: "Soothing Darkness", icon: "spell_shadow_twilight"}
        self.talents[:b] << {tier: 3, column: 1, spell: 79008, name: "Elusiveness", icon: "ability_rogue_turnthetables"}
        self.talents[:b] << {tier: 3, column: 2, spell: 31230, name: "Cheat Death", icon: "ability_rogue_cheatdeath"}
        self.talents[:b] << {tier: 4, column: 0, spell: 196951, name: "Strike From The Shadows", icon: "ability_rogue_unfairadvantage"}
        self.talents[:b] << {tier: 4, column: 1, spell: 131511, name: "Prey on the Weak", icon: "ability_rogue_preyontheweak"}
        self.talents[:b] << {tier: 4, column: 2, spell: 200778, name: "Tangled Shadow", icon: "inv_misc_volatileshadow"}
        self.talents[:b] << {tier: 5, column: 0, spell: 196979, name: "Premeditation", icon: "spell_shadow_possession"}
        self.talents[:b] << {tier: 5, column: 1, spell: 193539, name: "Alacrity", icon: "ability_paladin_speedoflight"}
        self.talents[:b] << {tier: 5, column: 2, spell: 206237, name: "Enveloping Shadows", icon: "ability_rogue_envelopingshadows"}
        self.talents[:b] << {tier: 6, column: 0, spell: 58423, name: "Relentless Strikes", icon: "ability_warrior_decisivestrike"}
        self.talents[:b] << {tier: 6, column: 1, spell: 137619, name: "Marked for Death", icon: "achievement_bg_killingblow_berserker"}
        self.talents[:b] << {tier: 6, column: 2, spell: 152150, name: "Death from Above", icon: "spell_rogue_deathfromabove"}
      end
    end

    def as_json(options = {})
      {
        :talents => talents
      }
    end
  end
end
