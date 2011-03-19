import sys
from math import floor

sys.path.append("engine")

from twisted.application import service, internet
from twisted.web import server, resource
from twisted.internet import reactor
from time import clock

from shadowcraft.calcs.rogue.Aldriana import AldrianasRogueDamageCalculator, settings, InputNotModeledException
from shadowcraft.objects import buffs, race, stats, procs
from shadowcraft.objects.talents import InvalidTalentException
from shadowcraft.objects.rogue import rogue_talents, rogue_glyphs
from websocket import *

import hotshot, hotshot.stats

from shadowcraft.core import i18n

import json

class ShadowcraftComputation:
  enchantMap = {
    4083: 'hurricane',
    4099: 'landslide',
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
    59520: 'unheeded_warning'
  }
  trinkets = gearProcs.values()
  trinkets.remove("the_twilight_blade")

  tier11IDS = frozenset([60298, 65240, 60299, 65241, 60300, 65242, 60302, 65243, 60301, 65239])
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
    'all_damage_buff',
    'melee_haste_buff',
    'attack_power_buff',
    'str_and_agi_buff',
    'armor_debuff',
    'physical_vulnerability_debuff',
    'spell_damage_debuff',
    'spell_crit_debuff',
    'bleed_damage_debuff',
    'agi_flask',
    'guild_feast'
  ]

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

  def sumstring(self, x):
    total=0
    for letter in str(x):
        total+=int(letter)
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

    # Buffs
    buff_list = []
    __max = len(self.buffMap)
    for b in input.get("b", []):
      b = int(b)
      if b >= 0 and b < __max:
        buff_list.append(self.buffMap[b])
      
    _buffs = buffs.Buffs(*buff_list)

    # ##################################################################################
    # Weapons
    _mh = self.weapon(input, 'mh')
    _oh = self.weapon(input, 'oh')
    _th = self.weapon(input, 'th')
    # ##################################################################################

    # ##################################################################################
    # Set up gear buffs.
    buff_list = []
    buff_list.append('leather_specialization')
    if input.get("pot", 0) == 1:
      buff_list.append('potion_of_the_tolvir')

    if input.get("mg") == "chaotic":
      buff_list.append('chaotic_metagem')

    if len(self.tier11IDS & gear) >= 2:
      buff_list.append('rogue_t11_2pc')

    agi_bonus = 0
    if len(self.arenaSeason9SetIds & gear) >= 2:
      agi_bonus += 70
      
    if len(self.arenaSeason9SetIds & gear) >= 4:
      agi_bonus += 90

    # If engineer
    if "engineering" in professions:
      buff_list.append('engineer_glove_enchant')

    # If is equipped
    if 68709 in gear or 62468 in gear or 62463 in gear:
      buff_list.append('unsolvable_riddle')

    # If Jewelcrafter and trinket equipped
    if 52199 in gear:
      buff_list.append('demon_panther')

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
      
    _procs = procs.ProcsList(*proclist)

    # ##################################################################################
    # Player stats
    # Need parameter order here
    # str, agi, ap, crit, hit, exp, haste, mastery, mh, oh, thrown, procs, gear buffs
    _level = int(input.get("l", 85))
    raceStr = input.get("r", 'human').lower().replace(" ", "_")
    _race = race.Race(raceStr, 'rogue', _level)

    s = input.get("sta", {})

    _stats = stats.Stats(
      s[0] + _race.stat_set[_level][0], # Str
      s[1] + _race.stat_set[_level][1] + agi_bonus, # AGI
      s[2], # AP
      s[3], # Crit
      s[4], # Hit
      s[5], # Expertise
      s[6], # Haste
      s[7], # Mastery
      _mh, _oh, _th, _procs, _gear_buffs)
    # ##################################################################################

    # Talents
    t = input.get("t", ['', '', ''])
    _talents = rogue_talents.RogueTalents(t[0], t[1], t[2])

    # Glyphs
    _glyphs = rogue_glyphs.RogueGlyphs(*input.get("gly", []))

    if self.sumstring(t[0]) >= 31:
      tree = 0
    elif self.sumstring(t[1]) >= 31:
      tree = 1
    else:
      tree = 2
      
    rotation_options = dict( (key.encode('ascii'), val) for key, val in self.convert_bools(input.get("ro", {})).iteritems() if key in self.validCycleKeys[tree] )
    
    if tree == 0:
      _cycle = settings.AssassinationCycle(**rotation_options)
    elif tree == 1:
      _cycle = settings.CombatCycle(**rotation_options)
    else:
      _cycle = settings.SubtletyCycle(5, **rotation_options)

    _opt = input.get("settings", {})
    _settings = settings.Settings(_cycle,
      response_time = 0.5,
      tricks_on_cooldown = _opt.get("tricks", True),
      mh_poison = _opt.get("mh_poison", 'ip'),
      oh_poison = _opt.get("oh_poison", 'dp'),
      duration = int(_opt.get("duration", 300)),
    )

    calculator = AldrianasRogueDamageCalculator(_stats, _talents, _glyphs, _buffs, _race, _settings, _level)
    return calculator
    
  def get_all(self, input):
    out = {}
    try:
      calculator = self.setup(input)
      out["ep"] = calculator.get_ep()

      # Talent ranking is slow
      out["talent_ranking_main"], out["talent_ranking_off"] = calculator.get_talents_ranking()      
      
      # Glyph ranking is slow
      out["glyph_ranking"] = calculator.get_glyphs_ranking(rogue_glyphs.RogueGlyphs.allowed_glyphs)
      
      out["meta"] = calculator.get_other_ep(['chaotic_metagem'])

      trinket_rankings = calculator.get_other_ep(self.trinkets)
      out["trinket_ranking"] = {}
      for k in trinket_rankings:
        for id in self.gearProcs:
          if self.gearProcs[id] == k:
            out["trinket_ranking"][id] = floor(trinket_rankings[k] * 10) / 10      
      
      # Compute weapon ep
      out["mh_ep"], out["oh_ep"] = calculator.get_weapon_ep(dps=True, enchants=True)
      out["mh_speed_ep"], out["oh_speed_ep"] = calculator.get_weapon_ep([2.9, 2.7, 2.6, 1.8, 1.4, 1.3])

      # Compute DPS Breakdown.
      breakdown = calculator.get_dps_breakdown()
      out["total_dps"] = sum(entry[1] for entry in breakdown.items())
      return out
    except (InvalidTalentException, InputNotModeledException) as e:
      out["error"] = e.error_msg
      return out

engine = ShadowcraftComputation()

class ShadowcraftSite(resource.Resource):
  isLeaf = True
  allowedMethods = ('POST','OPTIONS', 'GET')  
  
  def render_OPTIONS(self, request):
    request.setHeader("Access-Control-Allow-Origin", "*")
    request.setHeader("Access-Control-Max-Age", "3600")    
    request.setHeader("Access-Control-Allow-Headers", "x-requested-with")
    return ""
    
  def render_POST(self, request):
    request.setHeader("Access-Control-Allow-Origin", "*")
    
    inbound = request.args.get("data", None)
    if not inbound:
      return '{"error": "Invalid input"}'
    
    input = json.loads(inbound[0])
    
    response = engine.get_all(input)
    return json.dumps( response )
  
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
