import __builtin__
import sys
from os import path

sys.path.append(path.abspath(path.join(path.dirname(__file__), '..', '..', 'engine')))
from shadowcraft.calcs.rogue.Aldriana import AldrianasRogueDamageCalculator, settings, InputNotModeledException
from shadowcraft.objects import buffs
from shadowcraft.objects import race
from shadowcraft.objects import stats
from shadowcraft.objects import procs
from shadowcraft.objects import talents
from shadowcraft.objects import artifact
from shadowcraft.objects import artifact_data
from shadowcraft.core import i18n
from shadowcraft.core import exceptions

class ShadowcraftComputation:
    enchantMap = {
        5437: "mark_of_the_claw",
        5438: "mark_of_the_distant_army",
        5439: "mark_of_the_hidden_satyr",
        0: None
    }

    trinkets = {

        # 6.2.3
        133597: 'infallible_tracking_charm',

        # 7.0
        140794: 'arcanogolem_digit',
        139329: 'bloodthirsty_instinct',
        137459: 'chaos_talisman',
        137419: 'chrono_shard',
        140806: 'convergence_of_fates',
        128705: 'darkmoon_deck_dominion',
        140808: 'draught_of_souls',
        140796: 'entwined_elemental_foci',
        137539: 'faulty_countermeasure',
        137369: 'giant_ornamental_pearl',
        133642: 'horn_of_valor',
        127842: 'infernal_alchemist_stone',
        137357: 'mark_of_dargrul',
        133664: 'memento_of_angerboda',
        139334: 'natures_call',
        140802: 'nightblooming_frond',
        137312: 'nightmare_egg_shell',
        139320: 'ravaged_seed_pod',
        136715: 'spiked_counterweight',
        139325: 'spontaneous_appendages',
        137373: 'tempered_egg_of_serpentrix',
        137406: 'terrorbound_nexus',
        137439: 'tiny_oozeling_in_a_jar',
        137537: 'tirathons_betrayal',
        137486: 'windscar_whetstone',
        144259: 'kiljaedens_burning_wish',

        # Return to Karazhan
        142159: 'bloodstained_handkerchief',
        142167: 'eye_of_command',
        142164: 'toe_knees_promise',

        # 7.2/Tomb of Sargeras
        144477: 'splinters_of_agronax',
    }

    otherProcs = {
    }

    artifactTraits = {
        # Assassination/Kingslayers
        'a': {
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
            214928: 'slayers_precision',
            241152: 'silence_of_the_uncrowned',
            238066: 'strangler',
            238102: 'dense_concoction',
            238138: 'sinister_circulation',
            239042: 'concordance_of_the_legionfall',

        },

        # Outlaw/Dreadblades traits
        'Z': {
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
            214929: 'cursed_steel',
            241153: 'bravado_of_the_uncrowned',
            238067: 'sabermetrics',
            238103: 'dreadblades_vigor',
            238139: 'loaded_dice',
            239042: 'concordance_of_the_legionfall',
        },

        # Subtlety/Fangs traits
        'b': {
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
            214930: 'legionblade',
            241154: 'shadows_of_the_uncrowned',
            238068: 'etched_in_shadow',
            242707: 'shadows_whisper',
            238140: 'feeding_frenzy',
            239042: 'concordance_of_the_legionfall',
        },
    }

    artifactTraitsReverse = {}
    for k,v in artifactTraits.iteritems():
        artifactTraitsReverse[k] = {v2: k2 for k2, v2 in v.iteritems()}

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

    def createGroupMax(base_ilvl, max_ilvl, step_size):
      group = xrange(base_ilvl, max_ilvl, step_size)

    # used for rankings
    trinketGroups = {
        # Alchemist trinket
        'infernal_alchemist_stone': xrange(815, 865, 5),

        # Dungeon trinkets
        'chaos_talisman': xrange(820, 955, 5),
        'chrono_shard': xrange(820, 955, 5),
        'darkmoon_deck_dominion': xrange(815, 955, 5),
        'faulty_countermeasure': xrange(820, 955, 5),
        'giant_ornamental_pearl': xrange(820, 955, 5),
        'horn_of_valor': xrange(820, 955, 5),
        'mark_of_dargrul': xrange(820, 955, 5),
        'memento_of_angerboda': xrange(820, 955, 5),
        'nightmare_egg_shell': xrange(820, 955, 5),
        'spiked_counterweight': xrange(820, 955, 5),
        'tempered_egg_of_serpentrix': xrange(820, 955, 5),
        'terrorbound_nexus': xrange(820, 955, 5),
        'tiny_oozeling_in_a_jar': xrange(820, 955, 5),
        'tirathons_betrayal': xrange(820, 955, 5),
        'windscar_whetstone': xrange(820, 955, 5),

        # Emerald Nightmare
        'ravaged_seed_pod': xrange(850, 955, 5),
        'spontaneous_appendages': xrange(850, 955, 5),
        'natures_call': xrange(850, 955, 5),
        'bloodthirsty_instinct': xrange(850, 955, 5),

        # Return to Karazhan
        'bloodstained_handkerchief': xrange(855, 955, 5),
        'eye_of_command': xrange(860, 955, 5),
        'toe_knees_promise': xrange(855, 955, 5),

        # Nighthold trinkets
        'arcanogolem_digit': xrange(855, 955, 5),
        'convergence_of_fates': xrange(860, 955, 5),
        'entwined_elemental_foci': xrange(860, 955, 5),
        'nightblooming_frond': xrange(860, 955, 5),
        'draught_of_souls': xrange(865, 955, 5),

        # Legendary trinkets
        'kiljaedens_burning_wish': [910, 940],

        # 7.2/Tomb of Sargeras
        'splinters_of_agronax': xrange(845, 955, 5),
    }

    gearBoosts = {
        137049: 'insignia_of_ravenholdt',
        137030: 'duskwalkers_footpads',
        137098: 'zoldyck_family_training_shackles',
        137021: 'the_dreadlords_deceit',
        137031: 'thraxis_tricksy_treads',
        137099: 'greenskins_waterlogged_wristcuffs',
        141321: 'shivarran_symmetry',
        137032: 'shadow_satyrs_walk',
        137100: 'denial_of_the_half_giants',
        133976: 'cinidaria_the_symbiote',
        144236: 'mantle_of_the_master_assassin',
        132452: 'sephuzs_secret',
        134542: 'jeweled_signet_of_melandrus',
        134526: 'gnawed_thumb_ring',
    }

    # combines gearProcs and gearBoosts
    trinketMap = dict(gearProcs, **gearBoosts)

    # Tier + Order Hall sets
    tier18IDs = frozenset([124248, 124257, 124263, 124269, 124274])
    tier18LFRIDs = frozenset([128130, 128121, 128125, 128054, 128131, 128137])
    tier19IDs = frozenset([138326, 138329, 138332, 138335, 138338, 138371])
    orderhallIDs = frozenset([139739, 139740, 139741, 139742, 139743, 139744, 139745, 139746])

    # Legion Dungeon sets
    marchOfTheLegionIDs = frozenset([134529, 134533])
    journeyThroughTimeIDs = frozenset([137419, 137487])
    jacinsRuseIDs = frozenset([137480, 137397])

    # Kara trinket/chest sets
    toeKneesIDs = frozenset([142164, 142203])
    bloodstainedIDs = frozenset([142159, 142203])
    eyeOfCommandIDs = frozenset([142167, 142203])

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
        'flask_wod_agi',
    ]

    buffFoodMap = [
        'food_legion_crit_375',
        'food_legion_haste_375',
        'food_legion_mastery_375',
        'food_legion_versatility_375',
        'food_legion_feast_500',
        'food_legion_damage_3'
    ]

    validCycleKeys = [[
          'kingsbane_with_vendetta',
          'exsang_with_vendetta',
          'cp_builder',
          'lethal_poison'
      ], [
          'blade_flurry',
          'between_the_eyes_policy',
          'jolly_roger_reroll',
          'grand_melee_reroll',
          'shark_reroll',
          'true_bearing_reroll',
          'buried_treasure_reroll',
          'broadsides_reroll',
          'reroll_policy'
      ], [
          'cp_builder',
          'positional_uptime',
          'symbols_policy',
          'dance_finishers_allowed',
      ]]

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
        _level = 110

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
        buff_list = ['gear_specialization']

        if len(self.tier18IDs & gear) >= 2:
            buff_list.append('rogue_t18_2pc')

        if len(self.tier18IDs & gear) >= 4:
            buff_list.append('rogue_t18_4pc')

        if len(self.tier18LFRIDs & gear) >= 4:
            buff_list.append('rogue_t18_4pc_lfr')

        if len(self.tier19IDs & gear) >= 2:
            buff_list.append('rogue_t19_2pc')

        if len(self.tier19IDs & gear) >= 4:
            buff_list.append('rogue_t19_4pc')

        if len(self.orderhallIDs & gear) >= 6:
            buff_list.append('rogue_orderhall_6pc')

        if len(self.orderhallIDs & gear) == 8:
            buff_list.append('rogue_orderhall_8pc')

        if len(self.marchOfTheLegionIDs & gear) == 2:
            buff_list.append('march_of_the_legion_2pc')

        if len(self.journeyThroughTimeIDs & gear) == 2:
            buff_list.append('journey_through_time_2pc')

        if len(self.jacinsRuseIDs & gear) == 2:
            buff_list.append('jacins_ruse_2pc')

        if len(self.toeKneesIDs & gear) == 2 or len(self.bloodstainedIDs & gear) == 2 or len(self.eyeOfCommandIDs & gear) == 2:
            buff_list.append('kara_empowered_2pc')

        for k,v in self.gearBoosts.iteritems():
            if k in gear:
                buff_list.append(v)

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

        if input.get("l", 0) == 110:
            if input.get("prepot", 0) == 0:
                proclist.append('old_war_prepot')
            if input.get("pot", 0) == 0:
                proclist.append('old_war_pot')
            if input.get("prepot", 0) == 1:
                proclist.append('prolonged_power_prepot')
            if input.get("pot", 0) == 1:
                proclist.append('prolonged_power_pot')

        # Add enchant procs to the list of gear buffs
        for k in gear_data:
            if k[2] != 0 and k[2] in self.enchantMap:
                proclist.append(self.enchantMap[k[2]])

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
            mh=_mh, oh=_oh, procs=_procs, gear_buffs=_gear_buffs,
            str=s[0],             # Str
            agi=s[1],             # AGI
            int=0,
            stam=0,
            ap=s[2],              # AP
            crit=s[3],            # Crit
            haste=s[4],           # Haste
            mastery=s[5],         # Mastery
            versatility=s[6],     # Versatility
            level=_level)
        # ##################################################################################

        _spec = input.get("spec", 'a')
        if _spec == "a":
            tree = 0
            spec = "assassination"
        elif _spec == "Z":
            tree = 1
            spec = "outlaw"
        else:
            tree = 2
            spec = "subtlety"

        # Talents
        t = input.get("t", '')
        _talents = talents.Talents(t, spec, "rogue", _level)

        rotation_keys = input.get("ro", {})
        rotation_options = dict( (key.encode('ascii'), val) for key, val in self.convert_bools(input.get("ro", {})).iteritems() if key in self.validCycleKeys[tree] )

        if spec == "outlaw":
            opts = ['jolly_roger_reroll', 'grand_melee_reroll', 'shark_reroll', 'true_bearing_reroll', 'buried_treasure_reroll', 'broadsides_reroll']

            if rotation_options['reroll_policy'] != 'custom':
                value = int(rotation_options['reroll_policy'])
                for opt in opts:
                    rotation_options[opt] = value
            else:
                for opt in opts:
                    rotation_options[opt] = int(rotation_options[opt])
            del rotation_options['reroll_policy']
        elif spec == "subtlety":
            rotation_options['positional_uptime'] = rotation_options['positional_uptime'] / 100.0

        settings_options = {}
        settings_options['num_boss_adds'] = _opt.get("num_boss_adds", 0)
        settings_options['is_day'] = _opt.get("night_elf_racial", 0) == 1
        settings_options['is_demon'] = _opt.get("demon_enemy", 0) == 1
        settings_options['marked_for_death_resets'] = _opt.get("mfd_resets", 0)
        settings_options['finisher_threshold'] = _opt.get("finisher_threshold", 0)

        if tree == 0:
            _cycle = settings.AssassinationCycle(**rotation_options)
        elif tree == 1:
            _cycle = settings.OutlawCycle(**rotation_options)
        else:
            _cycle = settings.SubtletyCycle(**rotation_options)
            _cycle.cp_builder
        _settings = settings.Settings(_cycle,
            response_time = _opt.get("response_time", 0.5),
            duration = duration,
            latency = _opt.get("latency", 0.03),
            adv_params = _opt.get("adv_params", ''),
            default_ep_stat = 'ap',
            **settings_options
        )

        if len(input['art']) == 0:
            # if no artifact data was passed (probably because the user had the wrong
            # weapons equipped), pass a string of zeros as the trait data.
            _traits = artifact.Artifact(spec, "rogue", "0"*len(artifact_data.traits[("rogue",spec)]))
        elif len(input['art']) == len(artifact_data.traits[("rogue",spec)]):
            traitstr = ""
            remap = {}
            for k,v in input['art'].iteritems():
                remap[self.artifactTraits[_spec][int(k)]] = v
            for t in artifact_data.traits[("rogue",spec)]:
                if (t in remap):
                    traitstr += str(remap[t])
                else:
                    traitstr += "0"
            _traits = artifact.Artifact(spec, "rogue", traitstr)
        else:
            _traits = None

        calculator = AldrianasRogueDamageCalculator(_stats, _talents, _traits, _buffs, _race, spec, _settings, _level)
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

            # Get character stats used for calculation (should equal armory)
            out["stats"] = calculator.stats.get_character_stats(calculator.race)
            # Filter interesting stats
            out["stats"]["agility"] = out["stats"]["agi"]
            for key in out["stats"].keys():
                if key not in ['agility', 'crit', 'versatility', 'mastery', 'haste']:
                    del out["stats"][key]

            # Get EP Values
            default_ep_stats = ['agi', 'haste', 'crit', 'mastery', 'versatility', 'ap']
            _opt = input.get("settings", {})
            out["ep"] = calculator.get_ep(ep_stats=default_ep_stats)

            other_buffs = ['rogue_t19_2pc','rogue_t19_4pc','rogue_orderhall_8pc',
                           'rogue_t18_2pc','rogue_t18_4pc','rogue_t18_4pc_lfr',
                           'mark_of_the_hidden_satyr','mark_of_the_distant_army',
                           'mark_of_the_claw','march_of_the_legion_2pc',
                           'journey_through_time_2pc','jacins_ruse_2pc',
                           'kara_empowered_2pc']

            for k,v in self.gearBoosts.iteritems():
                other_buffs.append(v)

            out["other_ep"] = calculator.get_other_ep(other_buffs)

            exclude_items = [item for item in gear if item in self.trinkets]
            exclude_procs = [self.gearProcs[x] for x in exclude_items]
            gear_rankings = calculator.get_upgrades_ep_fast(self.trinketGroups)

            out["proc_ep"] = gear_rankings
            out["trinket_map"] = self.trinketMap

            # Compute weapon ep
            out["mh_ep"], out["oh_ep"] = calculator.get_weapon_ep(dps=True, enchants=True)
            out["mh_speed_ep"], out["oh_speed_ep"] = calculator.get_weapon_ep([2.4, 2.6, 1.7, 1.8])
            _spec = input.get("spec","a")
            if _spec == "Z":
              out["mh_type_ep"], out["oh_type_ep"] = calculator.get_weapon_type_ep()

            # Talent ranking is slow. This is done last per a note from nextormento.
            out["talent_ranking"] = calculator.get_talents_ranking()

            out["engine_info"] = calculator.get_engine_info()

            # Get the artifact ranking and change the IDs from the engine back to
            # the item IDs using the artifactMap data.
            artifactRanks = calculator.get_trait_ranking()
            out["artifact_ranking"] = {}
            for trait,spell_id in self.artifactTraitsReverse[_spec].iteritems():
                if trait in artifactRanks:
                    out['artifact_ranking'][spell_id] = artifactRanks[trait]
                else:
                    out['artifact_ranking'][spell_id] = 0

            return out
        except (InputNotModeledException, exceptions.InvalidInputException) as e:
            out["error"] = e.error_msg
            return out
