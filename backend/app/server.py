import sys
import json
import __builtin__

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

class ShadowcraftComputation:
    enchantMap = {
        4083: 'hurricane',
        4099: 'landslide',
        4441: 'windsong',
        4443: 'elemental_force',
        4444: 'dancing_steel',
        0: None
    }

    gearProcs = {
        58181: 'fluid_death',
        56295: 'heroic_grace_of_the_herald',
        55266: 'grace_of_the_herald',
        56328: 'heroic_key_to_the_endless_chamber',
        56427: 'heroic_left_eye_of_rajh',
        65026: 'heroic_prestors_talisman_of_machination',
        56394: 'heroic_tias_grace',
        62049: 'darkmoon_card_hurricane',
        62051: 'darkmoon_card_hurricane',
        59473: 'essence_of_the_cyclone',
        65140: 'heroic_essence_of_the_cyclone',
        66969: 'heart_of_the_vile',
        55795: 'key_to_the_endless_chamber',
        56102: 'left_eye_of_rajh',
        59441: 'prestors_talisman_of_machination',
        68163: 'the_twilight_blade',
        55874: 'tias_grace',
        59520: 'unheeded_warning',
        71633: 'aellas_bottle',
        68994: 'matrix_restabilizer',
        69150: 'heroic_matrix_restabilizer',
        71335: 'corens_chilled_chromium_coaster',
        66969: 'heart_of_the_vile',
        65805: 'schnottz_medallion_of_command',
        68927: 'the_hungerer',
        69112: 'heroic_the_hungerer',
        70144: 'rickets_magnetic_fireball_proc',

        # 4.3
        77979: 'lfr_vial_of_shadows',
        77207: 'vial_of_shadows',
        77999: 'heroic_vial_of_shadows',

        77974: 'lfr_wrath_of_unchaining',
        77197: 'wrath_of_unchaining',
        77994: 'heroic_wrath_of_unchaining',

        77993: 'heroic_starcatcher_compass',
        77973: 'lfr_starcatcher_compass',
        77202: 'starcatcher_compass',

        78481 : 'lfr_nokaled_the_elements_of_death',
        77188: 'nokaled_the_elements_of_death',
        78472: 'heroic_nokaled_the_elements_of_death',

        72897: 'arrow_of_time',

        # 5.0
        81125: "windswept_pages",
        79328: "relic_of_xuen",
        86332: "terror_in_the_mists",
        87167: "heroic_terror_in_the_mists",
        86890: "lfr_terror_in_the_mists",
        86132: "bottle_of_infinite_stars",
        87057: "heroic_bottle_of_infinite_stars",
        86791: "lfr_bottle_of_infinite_stars",
        81267: "searing_words",
        87574: "corens_cold_chromium_coaster",
        84072: "braid_of_ten_songs",
        75274: "zen_alchemist_stone"

    }
    
    gearBoosts = {
        56115: 'skardyns_grace',
        56440: 'heroic_skardyns_grace',
        68709: 'unsolvable_riddle',
        62468: 'unsolvable_riddle',
        62463: 'unsolvable_riddle',
        52199: 'demon_panther',
        69199: 'heroic_ancient_petrified_seed',
        69001: 'ancient_petrified_seed',
        70144: 'rickets_magnetic_fireball',
        77113: 'kiroptyric_sigil',
        78004: 'heroic_kiroptyric_sigil',
        77974: 'lfr_kiroptyric_sigil',
        
        #5.0
        87495: "gerps_perfect_arrow",
        81265: "flashing_steel_talisman",
        89082: "hawkmasters_talon",
        87079: "heroic_jade_bandit_figurine",
        86043: "jade_bandit_figurine",
        86772: "lfr_jade_bandit_figurine"
    }
    
    trinketMap = dict(gearProcs, **gearBoosts)
    trinkets = trinketMap.values()

    tier11IDS = frozenset([60298, 65240, 60299, 65241, 60300, 65242, 60302, 65243, 60301, 65239])
    tier12IDS = frozenset([71046, 71538, 71047, 71539, 71048, 71540, 71049, 71541, 71045, 71537])
    tier13IDS = frozenset([78664, 78679, 78699, 78708, 78738, 77023, 77024, 77025, 77026, 77027, 78759, 78774, 78794, 78803, 78833])
    tier14IDS = frozenset([85299, 85300, 85301, 85302, 85303, 86639, 86640, 86641, 86642, 86643, 87124, 87125, 87126, 87127, 87128])

    
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
        'mastery_buff',
        'melee_haste_buff',
        'attack_power_buff',
        'armor_debuff',
        'physical_vulnerability_debuff',
        'spell_damage_debuff',
        'agi_flask_mop',
        'food_300_agi'
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
    elif __builtin__.shadowcraft_engine_version == 5.0: # FIXME what options are avaibly??
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
        gear = frozenset(input.get("g", []))
        professions = input.get("pro", {})
        
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
        buff_list.append('leather_specialization')
        if input.get("pot", 0) == 1:
            buff_list.append('virmens_bite')
        if input.get("prepot", 0) == 1:
            buff_list.append('virmens_bite_prepot')

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
    
        agi_bonus = 0
        if len(self.arenaSeason9SetIds & gear) >= 2:
            agi_bonus += 70
            
        if len(self.arenaSeason9SetIds & gear) >= 4:
            agi_bonus += 90

        # If engineer
        if "engineering" in professions:
            buff_list.append('synapse_springs')

        for k in self.gearBoosts:
            if k in gear:
                buff_list.append(self.gearBoosts[k])
            
        # If alchemist
        if "alchemy" in professions:
            buff_list.append('mixology')

        # If herbalist
        if "herbalism" in professions:
            buff_list.append('lifeblood')

        # If skinner
        if "skinning" in professions:
            buff_list.append('master_of_anatomy')

        _gear_buffs = stats.GearBuffs(*buff_list)

        # ##################################################################################
        # Trinket procs
        proclist = []
        for k in self.gearProcs:
            if k in gear:
                proclist.append(self.gearProcs[k])
        
        if len(self.tier11IDS & gear) >= 4:
            proclist.append('rogue_t11_4pc')

        if len(self.legendary_tier_1 & gear) >= 2:
            proclist.append('jaws_of_retribution')

        if len(self.legendary_tier_2 & gear) >= 2:
            proclist.append('maw_of_oblivion')

        if len(self.legendary_tier_3 & gear) >= 2:
            proclist.append('fangs_of_the_father')

        # if tailor
        if "tailoring" in professions and input.get("se") == 'swordguard_embroidery':
            proclist.append('swordguard_embroidery')

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
            s[4], # Hit
            s[5], # Expertise
            s[6], # Haste
            s[7], # Mastery
            _level,
            s[9], # PvP Power
            s[8]) # Resilience Rating
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
          rotation_keys["opener_name"] = ""
        rotation_options = dict( (key.encode('ascii'), val) for key, val in self.convert_bools(input.get("ro", {})).iteritems() if key in self.validCycleKeys[tree] )

        if tree == 0:
            _cycle = settings.AssassinationCycle(**rotation_options)
        elif tree == 1:
            _cycle = settings.CombatCycle(**rotation_options)
        else:
            _cycle = settings.SubtletyCycle(5, **rotation_options)
        # test_settings = settings.Settings(test_cycle, response_time=.5, duration=360, dmg_poison='dp', utl_poison='lp', is_pvp=charInfo['pvp'],stormlash=charInfo['stormlash'], shiv_interval=charInfo['shiv'])
        _settings = settings.Settings(_cycle,
            time_in_execute_range = _opt.get("time_in_execute_range", 0.35),
            tricks_on_cooldown = _opt.get("tricks", False),
            response_time = _opt.get("response_time", 0.5),
            duration = duration,
            dmg_poison = _opt.get("dmg_poison", 'dp'),
            utl_poison = _opt.get("utl_poison", None),
            opener_name = rotation_keys["opener_name"],
            use_opener = rotation_keys["opener_use"],
            stormlash = _opt.get("stormlash", False),
            is_pvp = _opt.get("pvp", False)
        )
        calculator = AldrianasRogueDamageCalculator(_stats, _talents, _glyphs, _buffs, _race, _settings, _level)
        return calculator
        
    def get_all(self, input):
        out = {}
        try:
            calculator = self.setup(input)
            out["ep"] = calculator.get_ep()

            # Compute DPS Breakdown.
            breakdown = calculator.get_dps_breakdown()
            out["total_dps"] = sum(entry[1] for entry in breakdown.items())

            # Glyph ranking is slow
            out["glyph_ranking"] = calculator.get_glyphs_ranking(input.get("gly", []))
            
            out["meta"] = calculator.get_other_ep(['chaotic_metagem'])
            out["other_ep"] = calculator.get_other_ep(['swordguard_embroidery','rogue_t12_2pc','rogue_t12_4pc'])

            trinket_rankings = calculator.get_other_ep(self.trinkets)
            out["trinket_ranking"] = {}
            for k in trinket_rankings:
                for id in self.trinketMap:
                    if self.trinketMap[id] == k:
                        try:
                            out["trinket_ranking"][id] = floor(float(trinket_rankings[k]) * 10) / 10      
                        except ValueError:
                            pass
            
            # Compute weapon ep
            out["mh_ep"], out["oh_ep"] = calculator.get_weapon_ep(dps=True, enchants=True)
            out["mh_speed_ep"], out["oh_speed_ep"] = calculator.get_weapon_ep([2.9, 2.7, 2.6, 1.8, 1.4, 1.3])

            # Talent ranking is slow. This is done last per a note from nextormento.
            out["talent_ranking_main"] = calculator.get_talents_ranking()      

            # oh weapon modifier, pull only for combat spec
            if input.get("spec", 'a') == "Z":
              out["oh_weapon_modifier"] = calculator.get_oh_weapon_modifier()

            return out
        except (InputNotModeledException, exceptions.InvalidInputException) as e:
            out["error"] = e.error_msg
            return out
        except (KeyError) as e:
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
