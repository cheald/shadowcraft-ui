#!/usr/bin/python

import math
import sys

def getLineInfo(icon1, icon2, height, width):
  # adjust the corner points of each icon down and to the right 40 pixels since the outer div
  # of each icon is 80 pixels wide and tall.
  pos1=(icon1['xpos']+40, icon1['ypos']+40)
  pos2=(icon2['xpos']+40, icon2['ypos']+40)

  (dx,dy) = (pos2[0]-pos1[0],pos2[1]-pos1[1])
  length = int(round(math.sqrt(float(math.pow(math.fabs(dx),2)+(math.pow(math.fabs(dy), 2))))))
  angle = math.degrees(math.atan2(dy,dx))

  # from the midpoint, we need to put the upper left corner of the div half of the length to the left and
  # half of the height from the right (plus a little bit of fine tuning)
  midpoint = ((pos1[0]+pos2[0])/2,(pos1[1]+pos2[1])/2)
  left = (midpoint[0]-(length/2)+5) / float(width) * 100.0
  top = (midpoint[1]+2) / float(height) * 100.0

  return [length, left, top, angle]

DREADBLADE_ICONS = {
  "db_curse": {"icon": "inv_sword_1h_artifactskywall_d_01dual","xpos": 463,"ypos": 320,"style": "thick", "spell_id": "202665", "max_level": 1},
  "db_blunderbuss": {"icon": "inv_weapon_rifle_01","xpos": 161,"ypos": 484,"style": "dragon", "spell_id": "202897", "max_level": 1},
  "db_blurredtime": {"icon": "ability_rogue_quickrecovery","xpos": 253,"ypos": 251,"style": "dragon", "spell_id": "202769", "max_level": 1},
  "db_greed": {"icon": "warrior_skullbanner","xpos": 570,"ypos": 30,"style": "dragon", "spell_id": "202820", "max_level": 1},
  "db_bladedancer": {"icon": "ability_warrior_bladestorm","xpos": 125,"ypos": 309,"style": "thin", "spell_id": "202507", "max_level": 3},
  "db_blademaster": {"icon": "ability_warrior_challange","xpos": 58,"ypos": 571,"style": "thin", "spell_id": "202628", "max_level": 1},
  "db_cursededges": {"icon": "inv_sword_33","xpos": 382,"ypos": 387,"style": "thin", "spell_id": "202463", "max_level": 3},
  "db_cursedleather": {"icon": "ability_rogue_masterofsubtlety","xpos": 470,"ypos": 208,"style": "thin", "spell_id": "202521", "max_level": 3},
  "db_deception": {"icon": "ability_rogue_disguise","xpos": 469,"ypos": 115,"style": "thin", "spell_id": "202755", "max_level": 1},
  "db_fatebringer": {"icon": "ability_rogue_cuttothechase","xpos": -10,"ypos": 372,"style": "thin", "spell_id": "202524", "max_level": 3},
  "db_fatesthirst": {"icon": "ability_rogue_waylay","xpos": 547,"ypos": 266,"style": "thin", "spell_id": "202514", "max_level": 3},
  "db_fortunestrikes": {"icon": "ability_rogue_improvedrecuperate","xpos": 273,"ypos": 359,"style": "thin", "spell_id": "202530", "max_level": 3},
  "db_fortunesboon": {"icon": "ability_rogue_surpriseattack2","xpos": 585,"ypos": 160,"style": "thin", "spell_id": "202907", "max_level": 3},
  "db_ghostlyshell": {"icon": "spell_shadow_nethercloak","xpos": 366,"ypos": 195,"style": "thin", "spell_id": "202533", "max_level": 3},
  "db_gunslinger": {"icon": "inv_weapon_rifle_07","xpos": 230,"ypos": 609,"style": "thin", "spell_id": "202522", "max_level": 3},
  "db_hiddenblade": {"icon": "ability_ironmaidens_bladerush","xpos": 735,"ypos": 175,"style": "thin", "spell_id": "202753", "max_level": 1},
}

DREADBLADE_LINES = [
  { "icon1": "db_curse", "icon2": "db_cursedleather" },
  { "icon1": "db_curse", "icon2": "db_cursededges" },
  { "icon1": "db_blunderbuss", "icon2": "db_fatebringer" },
  { "icon1": "db_blunderbuss", "icon2": "db_blademaster" },
  { "icon1": "db_blunderbuss", "icon2": "db_gunslinger" },
  { "icon1": "db_blurredtime", "icon2": "db_ghostlyshell" },
  { "icon1": "db_blurredtime", "icon2": "db_bladedancer" },
  { "icon1": "db_greed", "icon2": "db_deception" },
  { "icon1": "db_greed", "icon2": "db_hiddenblade" },
  { "icon1": "db_bladedancer", "icon2": "db_fatebringer" },
  { "icon1": "db_bladedancer", "icon2": "db_fortunestrikes" },
  { "icon1": "db_blademaster", "icon2": "db_fatebringer" },
  { "icon1": "db_blademaster", "icon2": "db_gunslinger" },
  { "icon1": "db_cursededges", "icon2": "db_fortunestrikes" },
  { "icon1": "db_cursedleather", "icon2": "db_fatesthirst" },
  { "icon1": "db_deception", "icon2": "db_ghostlyshell" },
  { "icon1": "db_fatesthirst", "icon2": "db_fortunesboon" },
  { "icon1": "db_fortunestrikes", "icon2": "db_ghostlyshell" },
  { "icon1": "db_fortunestrikes", "icon2": "db_gunslinger" },
  { "icon1": "db_fortunesboon", "icon2": "db_greed" },
  { "icon1": "db_fortunesboon", "icon2": "db_hiddenblade" },
]

KINGSLAYER_ICONS = {
  "ks_graspofguldan": {"icon": "ability_rogue_focusedattacks", "xpos": -4, "ypos": 496, "style": "thick", "spell_id": "192759", "max_level": 1},
  "ks_bagoftricks": {"icon": "rogue_paralytic_poison", "xpos": 318, "ypos": 207, "style": "dragon", "spell_id": "192657", "max_level": 1},
  "ks_fromtheshadows": {"icon": "ability_rogue_deadlybrew", "xpos": 436, "ypos": 156, "style": "dragon", "spell_id": "192428", "max_level": 1},
  "ks_blood": {"icon": "ability_deathwing_bloodcorruption_death", "xpos": 602, "ypos": 394, "style": "dragon", "spell_id": "192923", "max_level": 1},
  "ks_toxicblades": {"icon": "trade_brewpoison", "xpos": 28, "ypos": 407, "style": "thin", "spell_id": "192310", "max_level": 3},
  "ks_masteralchemist": {"icon": "trade_alchemy_potionb5", "xpos": 71, "ypos": 347, "style": "thin", "spell_id": "192318", "max_level": 3},
  "ks_surgeoftoxins": {"icon": "ability_rogue_deviouspoisons", "xpos": 196, "ypos": 285, "style": "thin", "spell_id": "192424", "max_level": 1},
  "ks_masterassassin": {"icon": "ability_rogue_deadliness", "xpos": 517, "ypos": 242, "style": "thin", "spell_id": "192349", "max_level": 3},
  "ks_shadowswift": {"icon": "rogue_burstofspeed", "xpos": 399, "ypos": 261, "style": "thin", "spell_id": "192422", "max_level": 1},
  "ks_shadowwalker": {"icon": "ability_rogue_shadowstep", "xpos": 254, "ypos": 335, "style": "thin", "spell_id": "192345", "max_level": 3},
  "ks_urgetokill": {"icon": "ability_rogue_improvedrecuperate", "xpos": 206, "ypos": 434, "style": "thin", "spell_id": "192384", "max_level": 1},
  "ks_serratededge": {"icon": "ability_rogue_shadowstrikes", "xpos": 385, "ypos": 350, "style": "thin", "spell_id": "192315", "max_level": 3},
  "ks_balancedblades": {"icon": "ability_rogue_restlessblades", "xpos": 443, "ypos": 412, "style": "thin", "spell_id": "192326", "max_level": 3},
  "ks_embrace": {"icon": "spell_shadow_skull", "xpos": 528, "ypos": 465, "style": "thin", "spell_id": "192323", "max_level": 3},
  "ks_gushingwound": {"icon": "ability_rogue_bloodsplatter", "xpos": 430, "ypos": 502, "style": "thin", "spell_id": "192329", "max_level": 3},
  "ks_poisonknives": {"icon": "ability_rogue_dualweild", "xpos": 312, "ypos": 516, "style": "thin", "spell_id": "192376", "max_level": 3},
}
KINGSLAYER_LINES = [
  { "icon1": "ks_graspofguldan", "icon2": "ks_toxicblades"},
  { "icon1": "ks_graspofguldan", "icon2": "ks_poisonknives"},
  { "icon1": "ks_gushingwound", "icon2": "ks_poisonknives"},
  { "icon1": "ks_gushingwound", "icon2": "ks_embrace"},
  { "icon1": "ks_gushingwound", "icon2": "ks_urgetokill"},
  { "icon1": "ks_masteralchemist", "icon2": "ks_toxicblades"},
  { "icon1": "ks_masteralchemist", "icon2": "ks_urgetokill"},
  { "icon1": "ks_masteralchemist", "icon2": "ks_surgeoftoxins"},
  { "icon1": "ks_bagoftricks", "icon2": "ks_surgeoftoxins"},
  { "icon1": "ks_bagoftricks", "icon2": "ks_shadowwalker"},
  { "icon1": "ks_shadowwalker", "icon2": "ks_shadowswift"},
  { "icon1": "ks_serratededge", "icon2": "ks_shadowswift"},
  { "icon1": "ks_serratededge", "icon2": "ks_shadowwalker"},
  { "icon1": "ks_serratededge", "icon2": "ks_urgetokill"},
  { "icon1": "ks_fromtheshadows", "icon2": "ks_shadowswift"},
  { "icon1": "ks_fromtheshadows", "icon2": "ks_masterassassin"},
  { "icon1": "ks_gushingwound", "icon2": "ks_urgetokill"},
  { "icon1": "ks_gushingwound", "icon2": "ks_poisonknives"},
  { "icon1": "ks_gushingwound", "icon2": "ks_embrace"},
  { "icon1": "ks_blood", "icon2": "ks_masterassassin"},
  { "icon1": "ks_blood", "icon2": "ks_embrace"},
  { "icon1": "ks_balancedblades", "icon2": "ks_urgetokill"},
  { "icon1": "ks_balancedblades", "icon2": "ks_masterassassin"},
]

FANGS_ICONS = {
  "fangs_goremawsbite" : {"icon": "inv_knife_1h_artifactfangs_d_01", "xpos": 617, "ypos": 222, "style": "thick", "spell_id": "209782", "max_level": 1},
  "fangs_shadownova" : {"icon": "spell_fire_twilightnova", "xpos": 428, "ypos": 68, "style": "dragon", "spell_id": "209781", "max_level": 1},
  "fangs_akaarissoul" : {"icon": "ability_warlock_soullink", "xpos": 520, "ypos": 227, "style": "dragon", "spell_id": "209835", "max_level": 1},
  "fangs_finality" : {"icon": "ability_rogue_eviscerate", "xpos": 117, "ypos": 477, "style": "dragon", "spell_id": "197406", "max_level": 1},
  "fangs_energetic" : {"icon": "inv_knife_1h_pvppandarias3_c_02", "xpos": 221, "ypos": 418, "style": "thin", "spell_id": "197239", "max_level": 3},
  "fangs_ghostarmor" : {"icon": "achievement_halloween_ghost_01", "xpos": 293, "ypos": 351, "style": "thin", "spell_id": "197244", "max_level": 3},
  "fangs_catwalk" : {"icon": "ability_rogue_fleetfooted", "xpos": 365, "ypos": 257, "style": "thin", "spell_id": "197241", "max_level": 3},
  "fangs_soulshadows" : {"icon": "inv_knife_1h_grimbatolraid_d_03", "xpos": 402, "ypos": 156, "style": "thin", "spell_id": "197386", "max_level": 3},
  "fangs_gutripper" : {"icon": "ability_rogue_eviscerate", "xpos": 520, "ypos": 140, "style": "thin", "spell_id": "197234", "max_level": 3},
  "fangs_quietknife" : {"icon": "ability_backstab", "xpos": 444, "ypos": 314, "style": "thin", "spell_id": "197231", "max_level": 3},
  "fangs_faster" : {"icon": "ability_rogue_sprint_blue", "xpos": 357, "ypos": 398, "style": "thin", "spell_id": "197256", "max_level": 1},
  "fangs_second" : {"icon": "inv_throwingknife_07", "xpos": 294, "ypos": 450, "style": "thin", "spell_id": "197610", "max_level": 1},
  "fangs_demonskiss" : {"icon": "ability_priest_voidentropy", "xpos": 237, "ypos": 520, "style": "thin", "spell_id": "197233", "max_level": 3},
  "fangs_precision" : {"icon": "ability_rogue_unfairadvantage", "xpos": 372, "ypos": 488, "style": "thin", "spell_id": "197235", "max_level": 3},
  "fangs_embrace" : {"icon": "ability_rogue_eviscerate", "xpos": 481, "ypos": 393, "style": "thin", "spell_id": "197604", "max_level": 1},
  "fangs_fortunesbite" : {"icon": "ability_rogue_masterofsubtlety", "xpos": 557, "ypos": 305, "style": "thin", "spell_id": "197369", "max_level": 3},
}
FANGS_LINES = [
  { "icon1": "fangs_goremawsbite", "icon2": "fangs_fortunesbite" },
  { "icon1": "fangs_goremawsbite", "icon2": "fangs_gutripper" },
  { "icon1": "fangs_catwalk", "icon2": "fangs_gutripper" },
  { "icon1": "fangs_catwalk", "icon2": "fangs_soulshadows" },
  { "icon1": "fangs_catwalk", "icon2": "fangs_ghostarmor" },
  { "icon1": "fangs_soulshadows", "icon2": "fangs_shadownova" },
  { "icon1": "fangs_energetic", "icon2": "fangs_ghostarmor" },
  { "icon1": "fangs_energetic", "icon2": "fangs_second" },
  { "icon1": "fangs_energetic", "icon2": "fangs_finality" },
  { "icon1": "fangs_demonskiss", "icon2": "fangs_finality" },
  { "icon1": "fangs_demonskiss", "icon2": "fangs_precision" },
  { "icon1": "fangs_precision", "icon2": "fangs_second" },
  { "icon1": "fangs_quietknife", "icon2": "fangs_faster" },
  { "icon1": "fangs_quietknife", "icon2": "fangs_akaarissoul" },
  { "icon1": "fangs_ghostarmor", "icon2": "fangs_faster" },
  { "icon1": "fangs_embrace", "icon2": "fangs_precision" },
  { "icon1": "fangs_embrace", "icon2": "fangs_fortunesbite" },
]

def scale(y, old_min, old_max, new_min, new_max):
  return (((float(new_max)-float(new_min))*(float(y)-float(old_min))) / (float(old_max)-float(old_min))) + float(new_min)

if sys.argv[1] == '--db':
  ICONS = DREADBLADE_ICONS
  LINES = DREADBLADE_LINES
  BG_IMAGE = '/images/artifacts/dreadblades-bg-icons.png'
  IMAGE_HEIGHT=700
  IMAGE_WIDTH=820
elif sys.argv[1] == '--ks':
  ICONS = KINGSLAYER_ICONS
  LINES = KINGSLAYER_LINES
  BG_IMAGE = '/images/artifacts/kingslayers-bg-icons.png'
  IMAGE_HEIGHT=615
  IMAGE_WIDTH=720
elif sys.argv[1] == '--fangs':
  ICONS = FANGS_ICONS
  LINES = FANGS_LINES
  BG_IMAGE = '/images/artifacts/fangs-bg-icons.png'
  IMAGE_HEIGHT=615
  IMAGE_WIDTH=720

  # For Fangs, the default positions make the icons at the top of the tree run into
  # the right most relic icon (namely shadow nova). Scale all of them downwards so
  # shadow nova is 45px lower and everything scales from there.
  for key,value in ICONS.iteritems():
    # demon's kiss is the bottom, shadow nova is the top
    # at 520 pixels, movement should be 45 * 0%
    # at 68 pixels, movement should be 45 * 100%
    newval = int(round(scale(value['ypos'], 68, 520, 68+45, 520)))
    value['ypos'] = newval

print ICONS
    
if sys.argv[2] == '--html':
  print '<html>'
  print '  <head>'
  print '    <title>test</title>'
  print '    <style>'
  print '      .trait {'
  print '        position: absolute;'
  print '        height: 90px;'
  print '        width: 90px;'
  print '        cursor: pointer;'
  print '      }'
  print '      '
  print '      .relic {'
  print '        z-index: 0;'
  print '        visibility: hidden;'
  print '        height: 90px;'
  print '        width: 90px;'
  print '        cursor: pointer;'
  print '      }'
  print '      '
  print '      .icon {'
  print '        position: absolute;'
  print '        z-index: 1;'
  print '        border-radius: 50%;'
  print '        left: 22px;'
  print '        top: 22px;'
  print '        height: 46px;'
  print '        width: 46px;'
  print '        background: black;'
  print '      }'
  print '      '
  print '      .icon.inactive {'
  print '        opacity: 0.6;'
  print '      }'
  print '      '
  print '      .ring {'
  print '        position: absolute;'
  print '        z-index: 2;'
  print '        left: 5px;'
  print '        top: 5px;'
  print '      }'
  print '      '
  print '      .ring-thin {'
  print '        left: 17px;'
  print '        top: 17px;'
  print '      }'
  print '      '
  print '      .line {'
  print '        position: absolute;'
  print '        background-image: url(/images/artifacts/artifact-line-active.png);'
  print '        background-repeat: repeat-x;'
  print '        height: 16px;'
  print '        transform-origin: 50% 50%;'
  print '      }'
  print '      '
  print '      .line.inactive {'
  print '        background-image: url(/images/artifacts/artifact-line-inactive.png);'
  print '      }'
  print '      '
  print '      .level {'
  print '        background-color: black;'
  print '        border: 1px solid #666666;'
  print '        border-radius: 20%;'
  print '        color: #ffd100;'
  print '        display: block;'
  print '        font-family: "Open Sans", Arial;'
  print '        position: absolute;'
  print '        text-align: center;'
  print '        left: calc((100% - 2em - 2px) / 2);'
  print '        top: 65%;'
  print '        width: 2em;'
  print '        z-index: 3;'
  print '      }'
  print '      '
  print '      .level.inactive {'
  print '        display: none;'
  print '      }'
  print '    </style>'
  print '  </head>'
  print '  <body>'
  print '    <div style="background-image:url(\'{}\');height:{}px;width:{}px;position:relative">'.format(BG_IMAGE, IMAGE_HEIGHT, IMAGE_WIDTH)

  for key,value in ICONS.iteritems():
    left = (value['xpos']/float(IMAGE_WIDTH))*100.0
    top = (value['ypos']/float(IMAGE_HEIGHT))*100.0
    print '      <div class="trait" style="left:{:.3f}%;top:{:.3f}%" id="{}" data-tooltip-type="spell" data-tooltip-id={} data-tooltip-rank=0 max-level={}>'.format(left,top,key,value['spell_id'],value['max_level'])

    if value['style'] is 'thin':
      print '        <img class="relic" src="/images/artifacts/relic-blood.png" style="visibility:hidden"/>'

    print '        <img class="icon" src="http://wow.zamimg.com/images/wow/icons/large/{0}.jpg"/>'.format(value['icon'])

    if value['style'] is 'thin':
      print '        <img class="ring ring-{0}" src="/images/artifacts/ring-{0}.png"/>'.format(value['style'])
      print '        <div class="level">0/3</div>'
    else:
      print '        <img class="ring" src="/images/artifacts/ring-{0}.png"/>'.format(value['style'])
      print '        <div class="level">0/{}</div>'.format(value['max_level'])

    print '      </div>'

  for line in LINES:
    icon1=ICONS[line['icon1']]
    icon2=ICONS[line['icon2']]
    length, left, top, angle = getLineInfo(icon1, icon2, IMAGE_HEIGHT, IMAGE_WIDTH)

    print '      <div class="line" style="width:{}px;left:{:.3f}%;top:{:.3f}%;transform:rotate({:.3f}deg)"></div>'.format(length,left,top,angle)

  print '    </div>'
  print '  </body>'
  print '</html>'

elif sys.argv[2] == '--haml':

  print '  #artifactframe{:style => "background-image:url(\'%s\');"}' % BG_IMAGE

  for key,value in ICONS.iteritems():
    left = (value['xpos']/float(IMAGE_WIDTH))*100.0
    top = (value['ypos']/float(IMAGE_HEIGHT))*100.0
    sys.stdout.write('    .trait.tt{:style => ')
    sys.stdout.write('"left:{:.3f}%;top:{:.3f}%;", :id => "{}"'.format(left,top,key))
    sys.stdout.write(', "data-tooltip-type" => "spell", "data-tooltip-id" => "{}", "data-tooltip-rank" => "0", "max_level" => "{}"'.format(value['spell_id'], value['max_level']))
    sys.stdout.write('}\n')
    sys.stdout.flush()

    if value['style'] is 'thin':
      print '      =image_tag "/images/artifacts/relic-blood.png", :style => "visibility:hidden;", :class => "relic"'

    print '      =image_tag "http://wow.zamimg.com/images/wow/icons/large/{0}.jpg", :class => "icon"'.format(value['icon'])

    if value['style'] is 'thin':
      print '      =image_tag "/images/artifacts/ring-{0}.png", :class => "ring ring-{0}"'.format(value['style'])
      print '      .level 0/3'
    else:
      print '      =image_tag "/images/artifacts/ring-{0}.png", :class => "ring"'.format(value['style'])
      print '      .level 0/1'

  for line in LINES:
    icon1=ICONS[line['icon1']]
    icon2=ICONS[line['icon2']]
    length, left, top, angle = getLineInfo(icon1, icon2, IMAGE_HEIGHT, IMAGE_WIDTH)

    sys.stdout.write('    .line{:style => ')
    sys.stdout.write('"width:{}px;left:{:.3f}%;top:{:.3f}%;transform:rotate({:.3f}deg);"'.format(length,left,top,angle))
    sys.stdout.write(', :spell1 => "{}", :spell2 => "{}"'.format(icon1['spell_id'], icon2['spell_id']))
    sys.stdout.write('}\n')
    sys.stdout.flush()

elif sys.argv[2] == '--js':

  print '      traits = ['
  for key,value in iter(sorted(ICONS.iteritems())):
    left = (value['xpos']/float(IMAGE_WIDTH))*100.0
    top = (value['ypos']/float(IMAGE_HEIGHT))*100.0
    sys.stdout.write('        {')
    sys.stdout.write('id: "{}", spell_id: {}, max_level: {}, icon: "{}", ring: "{}", '.format(key,value['spell_id'], value['max_level'], value['icon'], value['style']))
    sys.stdout.write('left: {:.3f}, top: {:.3f}'.format(left, top))
    if value['style'] == 'thin':
      sys.stdout.write(', is_thin: true')
    sys.stdout.write('},\n')
  print '      ]'

  print '      lines = ['
  for line in LINES:

    icon1=ICONS[line['icon1']]
    icon2=ICONS[line['icon2']]
    length, left, top, angle = getLineInfo(icon1, icon2, IMAGE_HEIGHT, IMAGE_WIDTH)
    sys.stdout.write('        {')
    sys.stdout.write('width: {}, left: {:.3f}, top: {:.3f}, angle: {:.3f}, spell1: {}, spell2: {}'.format(length, left, top, angle, icon1['spell_id'], icon2['spell_id']))
    sys.stdout.write('},\n')
  print '      ]'
