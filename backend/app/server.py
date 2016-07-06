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
        5330: "mark_of_the_thunderlord",
        5331: "mark_of_the_shattered_hand",
        5334: "mark_of_the_frostwolf",
        5337: "mark_of_warsong",
        5384: "mark_of_the_bleeding_hollow",
        5437: "mark_of_the_claw",
        5438: "mark_of_the_distant_army",
        5439: "mark_of_the_hidden_satyr",
        5890: "mark_of_the_trained_soldier",
        0: None
    }

    trinkets = {

        # 6.1
        122601: 'alchemy_stone', # 'stone_of_wind'
        122602: 'alchemy_stone', # 'stone_of_the_earth',
        122603: 'alchemy_stone', # 'stone_of_the_waters',
        122604: 'alchemy_stone', # 'stone_of_fire',

        # 6.2
        128023: 'alchemy_stone', # 'stone_of_the_wilds',
        128024: 'alchemy_stone', # 'stone_of_the_elements',
        124520: 'bleeding_hollow_toxin_vessel',
        124226: 'malicious_censer',
        124225: 'soul_capacitor',
        124224: 'mirror_of_the_blademaster',

        # 6.2.3
        133597: 'infallible_tracking_charm',
    }

    otherProcs = {
        # 6.1
        118302: 'archmages_incandescence',
        118307: 'archmages_greater_incandescence',
        124636: 'maalus',
    }
    
    artifactTraits = {
        # Outlaw/Dreadblades traits
        216230: 'black_powder',
        202507: 'blade_dancer',
        202628: 'blademaster',
        202897: 'blunderbuss',
        202769: 'blurred_time',
        202665: 'curse_of_the_dreadblades',
        202463: 'cursed_edges',
        202521: 'cursed_leather',
        202755: 'deception',
        202524: 'fatebringer',
        202514: 'fates_thirst',
        202907: 'fortunes_boon',
        202530: 'fortune_strikes',
        202533: 'ghostly_shell',
        202820: 'greed',
        202522: 'gunslinger',
        202753: 'hidden_blade',

        # Subtlety/Fangs traits
        209835: 'akarris_soul',
        197241: 'catlike_reflexes',
        197233: 'demons_kiss',
        197604: 'embrace_of_darkness',
        197239: 'energetic_stabbing',
        197256: 'flickering_shadows',
        197406: 'finality',
        197369: 'fortunes_bite',
        197244: 'ghost_armor',
        209782: 'goremaws_bite',
        197234: 'gutripper',
        197235: 'precision_strike',
        197231: 'the_quiet_knife',
        197610: 'second_shuriken',
        221856: 'shadow_fangs',
        209781: 'shadow_nova',
        197386: 'soul_shadows',

        # Assassination/Kingslayers
        214368: 'assassins_blades',
        192657: 'bag_of_tricks',
        192326: 'balanced_blades',
        192923: 'blood_of_the_assassinated',
        192323: 'fade_into_shadows',
        192428: 'from_the_shadows',
        192759: 'kingsbane',
        192329: 'gushing_wounds',
        192318: 'master_alchemist',
        192349: 'master_assassin',
        192376: 'poison_knives',
        192315: 'serrated_edge',
        192422: 'shadow_swiftness',
        192345: 'shadow_walker',
        192424: 'surge_of_toxins',
        192310: 'toxic_blades',
        192384: 'urge_to_kill',
    }

    artifactTraitsReverse = {v: k for k, v in artifactTraits.iteritems()}

    gearProcs = trinkets.copy()
    gearProcs.update(otherProcs)

    # Creates a group of items based on the base ilvls passed in.  For each entry in the
    # base_ilvls array, it will create additional entries stepping by step_size up to
    # num_steps times.
    def createGroup(base_ilvls, num_steps, step_size):
      trinketGroup = []
      subgroup = ()
      for base_ilvl in base_ilvls:
        for i in xrange(base_ilvl,base_ilvl + (num_steps+1)*step_size, step_size):
          subgroup += (i,)
      trinketGroup.extend(list(subgroup))
      return trinketGroup

    # used for rankings
    trinketGroups = {
        # legendary rings
        'archmages_greater_incandescence': [715],
        'archmages_incandescence': [690],
        'maalus': createGroup([735], 20, 3),
        'alchemy_stone': createGroup([640,655,670,685,700,715], 2, 5),
        # 6.2 trinkets
        'bleeding_hollow_toxin_vessel': createGroup(createGroup([705,720,735], 1, 6), 2, 5),
        'malicious_censer': createGroup(createGroup([700,715,730], 1, 6), 2, 5),
        'soul_capacitor': createGroup(createGroup([695,710,725], 1, 6), 2, 5),
        'mirror_of_the_blademaster': createGroup(createGroup([690,705,720], 1, 6), 2, 5),
    }

    gearBoosts = {
    }

    # combines gearProcs and gearBoosts
    trinketMap = dict(gearProcs, **gearBoosts)

    tier17IDS = frozenset([115570, 115571, 115572, 115573, 115574])
    tier17LFRIDS = frozenset([120384, 120383, 120382, 120381, 120380, 120379])
    tier18IDS = frozenset([124248, 124257, 124263, 124269, 124274])
    tier18LFRIDS = frozenset([128130, 128121, 128125, 128054, 128131, 128137])

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
        'flask_legion_agi',
    ]

    buffFoodMap = [
        'food_crit_700',
        'food_haste_700',
        'food_mastery_700',
        'food_versatility_700',
        'food_400_feast',
        'food_high_fire_proc',
    ]

    if __builtin__.shadowcraft_engine_version >= 6.0:
        validCycleKeys = [[
                'min_envenom_size_non_execute',
                'min_envenom_size_execute',
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
        _level = int(input.get("l", 100))

        # Buffs
        buff_list = []
        __max = len(self.buffMap)
        for b in input.get("b", []):
            b = int(b)
            if b >= 0 and b < __max:
                buff_list.append(self.buffMap[b])

        # Buff Food
        buff_list.append(self.buffFoodMap[input.get("bf", 0)])

        _buffs = buffs.Buffs(*buff_list, level=_level)

        # ##################################################################################
        # Weapons
        _mh = self.weapon(input, 'mh')
        _oh = self.weapon(input, 'oh')
        # ##################################################################################

        # ##################################################################################
        # Set up gear buffs.
        buff_list = []

        if len(self.tier17IDS & gear) >= 2:
            buff_list.append('rogue_t17_2pc')

        if len(self.tier17IDS & gear) >= 4:
            buff_list.append('rogue_t17_4pc')

        if len(self.tier17LFRIDS & gear) >= 4:
            buff_list.append('rogue_t17_4pc_lfr')

        if len(self.tier18IDS & gear) >= 2:
            buff_list.append('rogue_t18_2pc')

        if len(self.tier18IDS & gear) >= 4:
            buff_list.append('rogue_t18_4pc')

        if len(self.tier18LFRIDS & gear) >= 4:
            buff_list.append('rogue_t18_4pc_lfr')

        agi_bonus = 0
        if len(self.tier17LFRIDS & gear) >= 2:
            agi_bonus += 100
        if len(self.tier18LFRIDS & gear) >= 2:
            agi_bonus += 115

        for k in self.gearBoosts:
            if k in gear:
                buff_list.append(self.gearBoosts[k])

        # Add enchant procs to the list of gear buffs
        for k in gear_data:
            if k[2] != 0 and k[2] in self.enchantMap:
                buff_list.append(self.enchantMap[k[2]])

        print buff_list
        _gear_buffs = stats.GearBuffs(*buff_list)

        # ##################################################################################
        # Trinket procs
        proclist = []
        for k in self.gearProcs:
            if k in gear:
                for gd in gear_data:
                    if gd[0] == k:
                        proclist.append((self.gearProcs[k],gd[1]))
                        if gd[0] == 133597:
                            proclist.append(('infallible_tracking_charm_mod', gd[1]))
                        break
                    
        if input.get("l", 0) > 90:
            if input.get("prepot", 0) == 1:
                proclist.append('draenic_agi_prepot')
            if input.get("pot", 0) == 1:
                proclist.append('draenic_agi_pot')

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
            s[1] + agi_bonus, # AGI
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
            _level)
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

        rotation_keys = input.get("ro", { 'opener_name': 'default', 'opener_use': 'always'})
        if not rotation_keys["opener_name"] in self.validOpenerKeys[tree]:
            rotation_keys["opener_name"] = "default"
        rotation_options = dict( (key.encode('ascii'), val) for key, val in self.convert_bools(input.get("ro", {})).iteritems() if key in self.validCycleKeys[tree] )
        settings_options = {}
        if __builtin__.shadowcraft_engine_version >= 5.4:
            settings_options['num_boss_adds'] = _opt.get("num_boss_adds", 0)
        if __builtin__.shadowcraft_engine_version >= 6.0:
            settings_options['is_day'] = _opt.get("night_elf_racial", 0) == 1
            settings_options['is_demon'] = _opt.get("demon_enemy", 0) == 1
           
        if tree == 0:
            _cycle = settings.AssassinationCycle(**rotation_options)
        elif tree == 1:
            _cycle = settings.CombatCycle(**rotation_options)
        else:
            _cycle = settings.SubtletyCycle(5, **rotation_options)
        _settings = settings.Settings(_cycle,
            time_in_execute_range = _opt.get("time_in_execute_range", 0.35),
            response_time = _opt.get("response_time", 0.5),
            duration = duration,
            dmg_poison = _opt.get("dmg_poison", 'dp'),
            utl_poison = _opt.get("utl_poison", None),
            opener_name = rotation_keys["opener_name"],
            use_opener = rotation_keys["opener_use"],
            latency = _opt.get("latency", 0.03),
            adv_params = _opt.get("adv_params", ''),
            default_ep_stat = 'ap',
            **settings_options
        )

        artifact = {}
        for k,v in input['art'].iteritems():
            artifact[self.artifactTraits[int(k)]] = v

        calculator = AldrianasRogueDamageCalculator(_stats, _talents, _glyphs, _buffs, _race, _settings, _level)
        return calculator

    def get_all(self, input):
        out = {}
        try:
            calculator = self.setup(input)
            gear_data = input.get("g", [])
            gear = frozenset([x[0] for x in gear_data])

            # Compute DPS Breakdown.
            out["breakdown"] = calculator.get_dps_breakdown()
            out["total_dps"] = sum(entry[1] for entry in out["breakdown"].items())

            # Get EP Values
            default_ep_stats = ['agi', 'haste', 'crit', 'mastery', 'multistrike', 'versatility', 'ap']
            _opt = input.get("settings", {})
            out["ep"] = calculator.get_ep(ep_stats=default_ep_stats)

            out["other_ep"] = calculator.get_other_ep(['rogue_t18_2pc','rogue_t18_4pc','rogue_t18_4pc_lfr','rogue_t17_2pc','rogue_t17_4pc','rogue_t17_4pc_lfr'])

            exclude_items = [item for item in gear if item in self.trinkets]
            exclude_procs = [self.gearProcs[x] for x in exclude_items]
            trinket_rankings = calculator.get_upgrades_ep_fast(self.trinketGroups)

            out["proc_ep"] = trinket_rankings
            out["trinket_map"] = self.trinketMap

            # Compute weapon ep
            out["mh_ep"], out["oh_ep"] = calculator.get_weapon_ep(dps=True, enchants=True)
            out["mh_speed_ep"], out["oh_speed_ep"] = calculator.get_weapon_ep([2.4, 2.6, 1.7, 1.8])
            if input.get("spec", 'a') == "Z":
              out["mh_type_ep"], out["oh_type_ep"] = calculator.get_weapon_type_ep()

            # Talent ranking is slow. This is done last per a note from nextormento.
            out["talent_ranking"] = [] # calculator.get_talents_ranking()

            out["engine_info"] = calculator.get_engine_info()

            # Get the artifact ranking and change the IDs from the engine back to
            # the item IDs using the artifactMap data.
#            artifactRanks = calculator.get_artifact_ranking()
            artifactRanks = {
                'akarris_soul': 0.0,
                'catlike_reflexes': 3.2,
                'demons_kiss': 0.0,
                'embrace_of_darkness': 0.0,
                'energetic_stabbing': 5.1,
                'flickering_shadows': 0.0,
                'finality': 0.0,
                'fortunes_bite': 0.0,
                'ghost_armor': 0.0,
                'goremaws_bite': 7.3,
                'gutripper': 0.0,
                'precision_strike': 0.0,
                'the_quiet_knife': 0.0,
                'second_shuriken': 0.0,
                'shadow_fangs': 4.9,
                'shadow_nova': 0.0,
                'soul_shadows': 0.0
            }
            out["artifact_ranking"] = {}
            for k,v in artifactRanks.iteritems():
                out["artifact_ranking"][self.artifactTraitsReverse[k]] = v

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
        request.setHeader("Access-Control-Allow-Headers", "x-requested-with, content-type")
        return ""

    def render_POST(self, request):
        request.setHeader("Access-Control-Allow-Origin", "*")
        try:
            input = json.loads(request.content.getvalue())
        except ValueError:
            return '{"error": "Invalid input"}'
        else:
            start = clock()
            log.msg("Request: %s" % input)
            response = engine.get_all(input)
            log.msg("Request time: %s sec" % (clock() - start))
            log.msg("Response: %s" % response)
            return json.dumps(response)

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
