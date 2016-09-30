import sys
from os import path
sys.path.append(path.abspath(path.join(path.dirname(__file__), '..')))

import unittest
import json
from app.shadowcraft import ShadowcraftComputation

class TestUtils(unittest.TestCase):
  def test_build_calculator(self):
    payload = '''{"r":"Undead","l":110,"pot":0,"prepot":0,"b":[-1,1,0],"bf":3,"ro":{"kingsbane":"just","exsang":"just","cp_builder":"mutilate","lethal_poison":
              "dp","blade_flurry":false,"between_the_eyes_policy":"always","reroll_policy":"3","jolly_roger_reroll":"2","grand_melee_reroll":"2","shark_reroll":"1",
              "true_bearing_reroll":"1","buried_treasure_reroll":"2","broadsides_reroll":"2","symbols_policy":"just","dance_finishers_allowed":true,"positional_uptime":100},
              "settings":{"duration":360,"response_time":0.5,"num_boss_adds":0,"latency":0.03,"adv_params":"","night_elf_racial":0,"demon_enemy":0,"mfd_resets":0,
              "finisher_threshold":5},"spec":"Z","t":"2112223","sta":[0,11570,0,6423,4218,6076,3057],"art":{"202463":1,"202507":3,"202514":1,"202521":0,"202522":0,"202524":3,
              "202530":3,"202533":4,"202628":0,"202665":1,"202753":1,"202755":0,"202769":0,"202820":1,"202897":0,"202907":1,"216230":1},"mh":[2.6,4793.1467853970125,0,7],
              "oh":[2.6,4793.1467853970125,0,7],"g":[[134240,840,0],[134161,835,5890],[134154,840,5442],[134241,835,0],[136776,845,0],[134370,840,0],[139105,840,0],[134459,845,0],
              [139107,840,0],[134525,840,5429],[134191,830,5429],[137539,830,0],[133644,840,0],[134406,825,5435],[128872,874,0],[134552,874,0]]}'''
    comp = ShadowcraftComputation()
    comp.get_all(json.loads(payload))