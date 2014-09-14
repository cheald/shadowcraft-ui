import sys
import json
import __builtin__

from collections import defaultdict
from math import floor
from twisted.application import service, internet
from twisted.internet import threads
from twisted.web import server, resource
from twisted.internet import reactor
from twisted.python import log
from time import clock

from vendor.WebSocket import *

from shadowcraft.core import exceptions
from shadowcraft.calcs.rogue.Aldriana import AldrianasRogueDamageCalculator, settings, InputNotModeledException

from shadowcraft.objects import buffs
from shadowcraft.objects import race
from shadowcraft.objects import stats
from shadowcraft.objects import procs
from shadowcraft.objects import proc_data
from shadowcraft.objects import talents
from shadowcraft.objects import glyphs

from shadowcraft.core import i18n

import hotshot
import uuid

class ShadowcraftComputation:
    enchantMap = {
        4083: 'hurricane',
        4099: 'landslide',
        4441: 'windsong',
        4443: 'elemental_force',
        4444: 'dancing_steel',
        5125: 'dancing_steel',
        5330: "mark_of_the_thunderlord",
        5331: "mark_of_the_shattered_hand",
        5334: "mark_of_the_frostwolf",
        5337: "mark_of_warsong",
        5384: "mark_of_bleeding_hollow",
        0: None
    }

    gearProcs = {
        #58181: 'fluid_death',
        #56295: 'heroic_grace_of_the_herald',
        #55266: 'grace_of_the_herald',
        #56328: 'heroic_key_to_the_endless_chamber',
        #56427: 'heroic_left_eye_of_rajh',
        #65026: 'heroic_prestors_talisman_of_machination',
        #56394: 'heroic_tias_grace',
        #62049: 'darkmoon_card_hurricane',
        #62051: 'darkmoon_card_hurricane',
        #59473: 'essence_of_the_cyclone',
        #65140: 'heroic_essence_of_the_cyclone',
        #66969: 'heart_of_the_vile',
        #55795: 'key_to_the_endless_chamber',
        #56102: 'left_eye_of_rajh',
        #59441: 'prestors_talisman_of_machination',
        #68163: 'the_twilight_blade',
        #55874: 'tias_grace',
        #59520: 'unheeded_warning',
        #71633: 'aellas_bottle',
        #68994: 'matrix_restabilizer',
        #69150: 'heroic_matrix_restabilizer',
        #71335: 'corens_chilled_chromium_coaster',
        #66969: 'heart_of_the_vile',
        #65805: 'schnottz_medallion_of_command',
        #68927: 'the_hungerer',
        #69112: 'heroic_the_hungerer',
        #70144: 'rickets_magnetic_fireball_proc',

        # 4.3
        #77979: 'lfr_vial_of_shadows',
        #77207: 'vial_of_shadows',
        #77999: 'heroic_vial_of_shadows',

        #77974: 'lfr_wrath_of_unchaining',
        #77197: 'wrath_of_unchaining',
        #77994: 'heroic_wrath_of_unchaining',

        #77993: 'heroic_starcatcher_compass',
        #77973: 'lfr_starcatcher_compass',
        #77202: 'starcatcher_compass',

        #78481 : 'lfr_nokaled_the_elements_of_death',
        #77188: 'nokaled_the_elements_of_death',
        #78472: 'heroic_nokaled_the_elements_of_death',

        #72897: 'arrow_of_time',

        # 5.0
        #81125: "windswept_pages",
        #79328: "relic_of_xuen",
        #86332: "terror_in_the_mists",
        #87167: "heroic_terror_in_the_mists",
        #86890: "lfr_terror_in_the_mists",
        #86132: "bottle_of_infinite_stars",
        #87057: "heroic_bottle_of_infinite_stars",
        #86791: "lfr_bottle_of_infinite_stars",
        #81267: "searing_words",
        #87574: "corens_cold_chromium_coaster",
        #84072: "braid_of_ten_songs",
        #75274: "zen_alchemist_stone",
        
        # 5.1
        93253: "woundripper_medallion",
        93258: "woundripper_medallion",

        # 5.2
        95665: 'bad_juju',
        94523: 'bad_juju',
        96037: 'bad_juju',
        96409: 'bad_juju',
        96781: 'bad_juju',
        
        95802: 'rune_of_re_origination',
        94532: 'rune_of_re_origination',
        96174: 'rune_of_re_origination',
        96546: 'rune_of_re_origination',
        96918: 'rune_of_re_origination',
        
        95748: 'talisman_of_bloodlust',
        94522: 'talisman_of_bloodlust',
        96120: 'talisman_of_bloodlust',
        96492: 'talisman_of_bloodlust',
        96864: 'talisman_of_bloodlust',
        
        95625: 'renatakis_soul_charm',
        94512: 'renatakis_soul_charm',
        95997: 'renatakis_soul_charm',
        96369: 'renatakis_soul_charm',
        96741: 'renatakis_soul_charm',
        
        94511: 'vicious_talisman_of_the_shado-pan_assault',

        # 5.4
        103686: 'discipline_of_xuen',
        103986: 'discipline_of_xuen',

        105029: 'haromms_talisman',
        104780: 'haromms_talisman',
        102301: 'haromms_talisman',
        105278: 'haromms_talisman',
        104531: 'haromms_talisman',
        105527: 'haromms_talisman',
        
        105082: 'sigil_of_rampage',
        104833: 'sigil_of_rampage',
        102302: 'sigil_of_rampage',
        105331: 'sigil_of_rampage',
        104584: 'sigil_of_rampage',
        105580: 'sigil_of_rampage',
        
        104974: 'assurance_of_consequence',
        104725: 'assurance_of_consequence',
        102292: 'assurance_of_consequence',
        105223: 'assurance_of_consequence',
        104476: 'assurance_of_consequence',
        105472: 'assurance_of_consequence',

        105114: 'ticking_ebon_detonator',
        104865: 'ticking_ebon_detonator',
        102311: 'ticking_ebon_detonator',
        105363: 'ticking_ebon_detonator',
        104616: 'ticking_ebon_detonator',
        105612: 'ticking_ebon_detonator',

        105111: 'thoks_tail_tip',
        104862: 'thoks_tail_tip',
        102305: 'thoks_tail_tip',
        105360: 'thoks_tail_tip',
        104613: 'thoks_tail_tip',
        105609: 'thoks_tail_tip',
    }
    
    def createTrinketGroup(base_ilvls, upgrade_level, upgrade_steps):
      trinketGroup = []
      for base_ilvl in base_ilvls:
        subgroup = ()
        for i in xrange(base_ilvl,base_ilvl + (upgrade_level+1)*upgrade_steps ,upgrade_steps):
          subgroup += (i,)
        trinketGroup.append(subgroup)
      return trinketGroup
    
    # used for rankings
    trinketGroups = {
      'bad_juju': createTrinketGroup((502,522,528,535,541), 4, 4),
      'rune_of_re_origination': createTrinketGroup((502,522,528,535,541), 4, 4),
      'talisman_of_bloodlust': createTrinketGroup((502,522,528,535,541), 4, 4),
      'vicious_talisman_of_the_shado-pan_assault': createTrinketGroup((522,), 4, 4),
      'renatakis_soul_charm': createTrinketGroup((522,), 4, 4),
      'assurance_of_consequence': createTrinketGroup((528,540,553,559,566,572), 4, 4),
      'haromms_talisman': createTrinketGroup((528,540,553,559,566,572), 4, 4),
      'sigil_of_rampage': createTrinketGroup((528,540,553,559,566,572), 4, 4),
      'ticking_ebon_detonator': createTrinketGroup((528,540,553,559,566,572), 4, 4),
      'thoks_tail_tip': createTrinketGroup((528,540,553,559,566,572), 4, 4),
      'discipline_of_xuen': createTrinketGroup((496,535), 4, 4),
      'woundripper_medallion': createTrinketGroup((496,), 4, 4),
    }

    gearBoosts = {
        #56115: 'skardyns_grace',
        #56440: 'heroic_skardyns_grace',
        #68709: 'unsolvable_riddle',
        #62468: 'unsolvable_riddle',
        #62463: 'unsolvable_riddle',
        #52199: 'demon_panther',
        #69199: 'heroic_ancient_petrified_seed',
        #69001: 'ancient_petrified_seed',
        #70144: 'rickets_magnetic_fireball',
        #77113: 'kiroptyric_sigil',
        #78004: 'heroic_kiroptyric_sigil',
        #77974: 'lfr_kiroptyric_sigil',
        
        #5.0
        #87495: "gerps_perfect_arrow",
        81265: "flashing_steel_talisman",
        89082: "hawkmasters_talon",
        #87079: "heroic_jade_bandit_figurine",
        86043: "jade_bandit_figurine",
        #86772: "lfr_jade_bandit_figurine",
    }
    
    # combines gearProcs and gearBoosts
    trinketMap = dict(gearProcs, **gearBoosts)

    tier11IDS = frozenset([60298, 65240, 60299, 65241, 60300, 65242, 60302, 65243, 60301, 65239])
    tier12IDS = frozenset([71046, 71538, 71047, 71539, 71048, 71540, 71049, 71541, 71045, 71537])
    tier13IDS = frozenset([78664, 78679, 78699, 78708, 78738, 77023, 77024, 77025, 77026, 77027, 78759, 78774, 78794, 78803, 78833])
    tier14IDS = frozenset([85299, 85300, 85301, 85302, 85303, 86639, 86640, 86641, 86642, 86643, 87124, 87125, 87126, 87127, 87128])
    tier15IDS = frozenset([95935, 95306, 95307, 95305, 95939, 96683, 95938, 96682, 95937, 96681, 95308, 95936, 95309, 96680, 96679])
    tier16IDS = frozenset([99006, 99007, 99008, 99009, 99010, 99112, 99113, 99114, 99115, 99116, 99348, 99349, 99350, 99355, 99356, 99629, 99630, 99631, 99634, 99635])
    tier17IDS = frozenset([115570, 115571, 115572, 115573, 115574])

    legendary_tier_1 = frozenset([77945, 77946])
    legendary_tier_2 = frozenset([77947, 77948])
    legendary_tier_3 = frozenset([77949, 77950])
    legendary_mainhands = frozenset([77945, 77947, 77949])

    arenaSeason9SetIds = frozenset([60458, 60459, 60460, 60461, 60462, 64769, 64770, 64771, 64772, 64773, 65545, 65546, 65547, 65548, 65549])

    subclassMap = {
    -1: None,
        0: '1h_axe',
        1: '2h_axe',
        2: 'bow',
        3: 'gun',
        4: '1h_mace',
        5: '2h_mace',
        6: 'polearm',
        7: '1h_sword',
        8: '2h_sword',
        10: 'staff',
        13: 'fist',
        15: 'dagger',
        16: 'thrown',
        18: 'crossbow',
        19: 'wand'
    }
    
    buffMap = [
        'short_term_haste_buff',
        'stat_multiplier_buff',
        'crit_chance_buff',
        'haste_buff',
        'multistrike_buff',
        'attack_power_buff',
        'mastery_buff',
        'versatility_buff',
        'agi_flask_mop',
        'food_mop_agi'
    ]
    
    if __builtin__.shadowcraft_engine_version == 4.1:
        validCycleKeys = [[
                'min_envenom_size_mutilate',
                'min_envenom_size_backstab',
                'prioritize_rupture_uptime_mutilate',
                'prioritize_rupture_uptime_backstab'
            ], [
                'use_rupture',
                'use_revealing_strike',
                'ksp_immediately'
            ], [
                'clip_recuperate'
            ]
        ]
    elif __builtin__.shadowcraft_engine_version == 4.2 or __builtin__.shadowcraft_engine_version == 4.3:
        validCycleKeys = [[
                'min_envenom_size_mutilate',
                'min_envenom_size_backstab',
                'prioritize_rupture_uptime_mutilate',
                'prioritize_rupture_uptime_backstab'
            ], [
                'use_rupture',
                'use_revealing_strike',
                'ksp_immediately'
            ], [
                'clip_recuperate',
                'use_hemorrhage'
            ]
        ]
    elif __builtin__.shadowcraft_engine_version == 5.0:
        validCycleKeys = [[
                'min_envenom_size_non_execute',
                'min_envenom_size_execute',
                'prioritize_rupture_uptime_non_execute',
                'prioritize_rupture_uptime_execute'
            ], [
                'use_rupture',
                'revealing_strike_pooling',
                'ksp_immediately',
                'blade_flurry'
            ], [
                'clip_recuperate',
                'use_hemorrhage'
            ]
        ]
    elif __builtin__.shadowcraft_engine_version == 5.2:
        validCycleKeys = [[
                'min_envenom_size_non_execute',
                'min_envenom_size_execute',
                'prioritize_rupture_uptime_non_execute',
                'prioritize_rupture_uptime_execute'
            ], [
                'use_rupture',
                'revealing_strike_pooling',
                'ksp_immediately',
                'blade_flurry',
                'stack_cds',
                'bf_targets'
            ], [
                'use_hemorrhage'
            ]
        ]
    elif __builtin__.shadowcraft_engine_version == 5.4:
        validCycleKeys = [[
                'min_envenom_size_non_execute',
                'min_envenom_size_execute',
                'prioritize_rupture_uptime_non_execute',
                'prioritize_rupture_uptime_execute'
            ], [
                'use_rupture',
                'revealing_strike_pooling',
                'ksp_immediately',
                'blade_flurry',
                'stack_cds'
            ], [
                'use_hemorrhage',
                'sub_sb_timing'
            ]
        ]
    elif __builtin__.shadowcraft_engine_version == 6.0:
        validCycleKeys = [[
                'min_envenom_size_non_execute',
                'min_envenom_size_execute',
                'prioritize_rupture_uptime_non_execute',
                'prioritize_rupture_uptime_execute'
            ], [
                'revealing_strike_pooling',
                'ksp_immediately',
                'blade_flurry',
            ], [
                'use_hemorrhage',
            ]
        ]
    
    validOpenerKeys = [[
        'mutilate',
        'ambush',
        'garrote'
       ], [
        'sinister_strike',
        'revealing_strike',
        'ambush',
        'garrote'
       ], [
        'ambush',
        'garrote'
       ]
    ]

    def sumstring(self, x):
        total=0
        for letter in str(x):
                total += int(letter)
                
        return total

    def weapon(self, input, index):
        i = input.get(index, [])
        if len(i) < 4:
            return stats.Weapon(0.01, 2, None, None)
            
        speed = float(i[0])
        dmg = float(i[1])
        subclass = self.subclassMap.get(i[3], None)
        enchant = self.enchantMap.get( i[2], None )
        return stats.Weapon(dmg, speed, subclass, enchant)
        
    def convert_bools(self, dict):
        for k in dict:
            if dict[k] == "false":
                dict[k] = False
            elif dict[k] == "true":
                dict[k] = True
        return dict

    def setup(self, input):
        gear_data = input.get("g", [])
        gear = frozenset([x[0] for x in gear_data])
        
        i18n.set_language('local')

        # Base
        _level = int(input.get("l", 90))

        # Buffs
        buff_list = []
        __max = len(self.buffMap)
        for b in input.get("b", []):
            b = int(b)
            if b >= 0 and b < __max:
                buff_list.append(self.buffMap[b])

        _buffs = buffs.Buffs(*buff_list, level=_level)

        # ##################################################################################
        # Weapons
        _mh = self.weapon(input, 'mh')
        _oh = self.weapon(input, 'oh')
        # ##################################################################################

        # ##################################################################################
        # Set up gear buffs.
        buff_list = []
        buff_list.append('gear_specialization')
        if input.get("mg") == "chaotic":
            buff_list.append('chaotic_metagem')

        if len(self.tier11IDS & gear) >= 2:
            buff_list.append('rogue_t11_2pc')

        if len(self.tier12IDS & gear) >= 2:
            buff_list.append('rogue_t12_2pc')

        if len(self.tier12IDS & gear) >= 4:
            buff_list.append('rogue_t12_4pc')

        if len(self.tier13IDS & gear) >= 2:
            buff_list.append('rogue_t13_2pc')

        if len(self.tier13IDS & gear) >= 4:
            buff_list.append('rogue_t13_4pc')

        if len(self.legendary_mainhands & gear) >= 1:
            buff_list.append('rogue_t13_legendary')

        if len(self.tier14IDS & gear) >= 2:
            buff_list.append('rogue_t14_2pc')

        if len(self.tier14IDS & gear) >= 4:
            buff_list.append('rogue_t14_4pc')

        if len(self.tier15IDS & gear) >= 2:
            buff_list.append('rogue_t15_2pc')

        if len(self.tier15IDS & gear) >= 4:
            buff_list.append('rogue_t15_4pc')

        if len(self.tier16IDS & gear) >= 2:
            buff_list.append('rogue_t16_2pc')

        if len(self.tier16IDS & gear) >= 4:
            buff_list.append('rogue_t16_4pc')
            
        if len(self.tier17IDS & gear) >= 2:
            buff_list.append('rogue_t17_2pc')

        if len(self.tier17IDS & gear) >= 4:
            buff_list.append('rogue_t17_4pc')
    
        agi_bonus = 0
        if len(self.arenaSeason9SetIds & gear) >= 2:
            agi_bonus += 70
            
        if len(self.arenaSeason9SetIds & gear) >= 4:
            agi_bonus += 90

        for k in self.gearBoosts:
            if k in gear:
                buff_list.append(self.gearBoosts[k])

        _gear_buffs = stats.GearBuffs(*buff_list)

        # ##################################################################################
        # Trinket procs
        proclist = []
        for k in self.gearProcs:
            if k in gear:
                for gd in gear_data:
                    if gd[0] == k:
                        proclist.append((self.gearProcs[k],gd[1]))
                        break
        
        if len(self.tier11IDS & gear) >= 4:
            proclist.append('rogue_t11_4pc')

        if len(self.legendary_tier_1 & gear) >= 2:
            proclist.append('jaws_of_retribution')

        if len(self.legendary_tier_2 & gear) >= 2:
            proclist.append('maw_of_oblivion')

        if len(self.legendary_tier_3 & gear) >= 2:
            proclist.append('fangs_of_the_father')

        if input.get("mg") == "capacitive":
            proclist.append('legendary_capacitive_meta')
            
        if len(frozenset([102248]) & gear) >= 1:
            proclist.append('fury_of_xuen')
        
        _procs = procs.ProcsList(*proclist)

        # ##################################################################################
        # Player stats
        # Need parameter order here
        # str, agi, int, spi, sta, ap, crit, hit, exp, haste, mastery, mh, oh, thrown, procs, gear buffs
        raceStr = input.get("r", 'human').lower().replace(" ", "_")
        _race = race.Race(raceStr, 'rogue', _level)

        s = input.get("sta", {})
        _opt = input.get("settings", {})
        duration = int(_opt.get("duration", 300))
        
        _stats = stats.Stats(
            _mh, _oh, _procs, _gear_buffs,
            s[0], # Str
            s[1]  + agi_bonus, # AGI
            0,
            0,
            0,
            s[2], # AP
            s[3], # Crit
            s[4], # Haste
            s[5], # Mastery
            0,
            s[6], # Multistrike
            s[7], # Versatility
            _level,
            s[9], # PvP Power
            s[8], # Resilience Rating
            pvp_target_armor = _opt.get("pvp_target_armor", 1500))
        # ##################################################################################

        # Talents
        t = input.get("t", '') 	
        _talents = talents.Talents(t , "rogue", _level)

        # Glyphs
        _glyphs = glyphs.Glyphs("rogue", *input.get("gly", []))
	
        _spec = input.get("spec", 'a')
        if _spec == "a":
            tree = 0
        elif _spec == "Z":
            tree = 1
        else:
            tree = 2
        
        rotation_keys = input.get("ro", {})
        if not rotation_keys["opener_name"] in self.validOpenerKeys[tree]: 
          rotation_keys["opener_name"] = "default"
        rotation_options = dict( (key.encode('ascii'), val) for key, val in self.convert_bools(input.get("ro", {})).iteritems() if key in self.validCycleKeys[tree] )
        settings_options = {}
        if __builtin__.shadowcraft_engine_version >= 5.4:
            settings_options['num_boss_adds'] = _opt.get("num_boss_adds", 0)        

        if tree == 0:
            _cycle = settings.AssassinationCycle(**rotation_options)
        elif tree == 1:
            _cycle = settings.CombatCycle(**rotation_options)
        else:
            _cycle = settings.SubtletyCycle(5, **rotation_options)
        # test_settings = settings.Settings(test_cycle, response_time=.5, duration=360, dmg_poison='dp', utl_poison='lp', is_pvp=charInfo['pvp'], shiv_interval=charInfo['shiv'])
        _settings = settings.Settings(_cycle,
            time_in_execute_range = _opt.get("time_in_execute_range", 0.35),
            response_time = _opt.get("response_time", 0.5),
            duration = duration,
            dmg_poison = _opt.get("dmg_poison", 'dp'),
            utl_poison = _opt.get("utl_poison", None),
            opener_name = rotation_keys["opener_name"],
            use_opener = rotation_keys["opener_use"],
            is_pvp = _opt.get("pvp", False),
            latency = _opt.get("latency", 0.03),
            adv_params = _opt.get("adv_params", ''),
            potion = input.get("pot", 0) == 1,
            prepot = input.get("prepot", 0) == 1,
            default_ep_stat = 'ap',
            **settings_options
        )
        calculator = AldrianasRogueDamageCalculator(_stats, _talents, _glyphs, _buffs, _race, _settings, _level)
        return calculator
        
    def get_all(self, input):
        out = {}
        try:
            calculator = self.setup(input)

            # Compute DPS Breakdown.
            out["breakdown"] = calculator.get_dps_breakdown()
            out["total_dps"] = sum(entry[1] for entry in out["breakdown"].items())

            # Get EP Values
            default_ep_stats = ['str', 'agi', 'haste', 'crit', 'mastery', 'multistrike', 'versatility', 'ap']
            _opt = input.get("settings", {})
            is_pvp = _opt.get("pvp", False)
            if is_pvp:
                default_ep_stats.append("pvp_power")
            out["ep"] = calculator.get_ep(ep_stats=default_ep_stats,baseline_dps=out["total_dps"])

            # Glyph ranking is slow
            out["glyph_ranking"] = [] # calculator.get_glyphs_ranking(input.get("gly", []))
            
            out["meta"] = calculator.get_other_ep(['chaotic_metagem','legendary_capacitive_meta'])
            out["other_ep"] = calculator.get_other_ep(['fury_of_xuen','rogue_t14_2pc','rogue_t14_4pc','rogue_t15_2pc','rogue_t15_4pc','rogue_t16_2pc','rogue_t16_4pc'])
            
            trinket_rankings = calculator.get_upgrades_ep_fast(self.trinketGroups)

            out["proc_ep"] = trinket_rankings
            out["trinket_map"] = self.trinketMap
            
            # Compute weapon ep
            out["mh_ep"], out["oh_ep"] = calculator.get_weapon_ep(dps=True, enchants=True)
            out["mh_speed_ep"], out["oh_speed_ep"] = calculator.get_weapon_ep([2.4, 2.6, 1.7, 1.8])

            # oh weapon modifier, pull only for combat spec
            #if input.get("spec", 'a') == "Z":
            #    out["oh_weapon_modifier"] = calculator.get_oh_weapon_modifier()
            
            # Talent ranking is slow. This is done last per a note from nextormento.
            out["talent_ranking"] = [] # calculator.get_talents_ranking()      

            return out
        except (InputNotModeledException, exceptions.InvalidInputException) as e:
            out["error"] = e.error_msg
            return out
        except (KeyError) as e:
            import traceback
            traceback.print_exc()
            out["error"] = "Error: " + e.message
            return out

engine = ShadowcraftComputation()
reactor.suggestThreadPoolSize(16)

class ShadowcraftSite(resource.Resource):
    isLeaf = True
    allowedMethods = ('POST','OPTIONS', 'GET')  
    
    def render_OPTIONS(self, request):
        request.setHeader("Access-Control-Allow-Origin", "*")
        request.setHeader("Access-Control-Max-Age", "3600")    
        request.setHeader("Access-Control-Allow-Headers", "x-requested-with")
        return ""
        
    def _render_post(self, input):
        start = clock()
        log.msg("Request: %s" % input)
        #prof = hotshot.Profile("profile/stones-%s.prof" % uuid.uuid4())
        #response = prof.runcall(engine.get_all, input)
        #prof.close()
        response = engine.get_all(input)
        log.msg("Request time: %s sec" % (clock() - start))
        return json.dumps(response)

    def render_POST(self, request):
        request.setHeader("Access-Control-Allow-Origin", "*")
        
        inbound = request.args.get("data", None)
        if not inbound:
            return '{"error": "Invalid input"}'
        
        input = json.loads(inbound[0])

        # d = threads.deferToThread(self._render_post, input)
        # d.addCallback(request.write)
        # d.addCallback(lambda _: request.finish())
        # return server.NOT_DONE_YET
        return self._render_post(input)
    
    # Because IE is terrible.
    def render_GET(self, request):
        return self.render_POST(request)

    def gzip_response(self, request, content):
        encoding = request.getHeader("accept-encoding")
        if encoding and encoding.find("gzip")>=0:
            import cStringIO,gzip
            zbuf = cStringIO.StringIO()
            zfile = gzip.GzipFile(None, 'wb', 7, zbuf)
            zfile.write(content)
            zfile.close()
            request.setHeader("Content-encoding","gzip")
            return zbuf.getvalue()
        else:
            return content
        

class ShadowcraftSocket(WebSocketHandler):
    def frameReceived(self, frame):
        input = json.loads(frame)
        if input["type"] == "m":
            # prof = hotshot.Profile("stones.prof")
            # prof.runcall(engine.get_dps, input["data"])
            # prof.close()
            # stats = hotshot.stats.load("stones.prof")
            # stats.sort_stats('time', 'calls')
            # stats.print_stats(50)
            
            start = clock()
            response = engine.get_all(input["data"])      
            response["calc_time"] = clock() - start
            self.transport.write(json.dumps({'type': 'response', 'data': response}))
            
if __name__ == "__main__":
    site = WebSocketSite(ShadowcraftSite())
    site.addHandler("/engine", ShadowcraftSocket)
    reactor.listenTCP(8880, site)
    reactor.run()
