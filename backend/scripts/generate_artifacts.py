#!/usr/bin/python

# This script creates artifact layout data using data from wowhead. It should be
# run every time Blizzard changes the layout of the artifact calculators. The
# output from this script (using the --js flag) should be copied into
# app/javascript/core/artifact_templates.coffee. This script requries a few
# external libraries to be installed:
#
# PhantomJS:
# Install node using apt-get: apt-get install nodejs
# Install PhantomJS from npm: npm -g install phantomjs
#
# Python modules:
# Install pip: apt-get install pip
# Install selenium/BeautifulSoup: pip install selenium bs4
#
# Huge thanks to wowhead for the layout data for these calculators. I generated
# the first set of layouts by hand so I know how much effort it is to get these
# things to look right.
#
# Usage:
#
# To load data from wowhead:
#    ./generate_artifacts.py --fetchdata
#
# To generate output layouts from fetched data:
# Pass an argument for the type of artifact: --db, --ks, or --fangs
# Pass an argument for the type of output: --html, --haml, --js
# Example:
#    ./generate_artifacts.py --db --js

import math
import sys
import time

from selenium import webdriver
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
from bs4 import BeautifulSoup

def getLineInfo(icon1, icon2, height, width):
  # adjust the corner points of each icon down and to the right 40 pixels since the outer div
  # of each icon is 80 pixels wide and tall.
  pos1=(icon1['xpos']+40, icon1['ypos']+40)
  pos2=(icon2['xpos']+40, icon2['ypos']+40)

  (dx,dy) = (pos2[0]-pos1[0],pos2[1]-pos1[1])
  length = int(round(math.sqrt(float(math.pow(math.fabs(dx),2)+(math.pow(math.fabs(dy), 2))))))
  angle = math.degrees(math.atan2(dy,dx))

  # from the midpoint, we need to put the upper left corner of the div half of the length to
  # the left and half of the height from the right (plus a little bit of fine tuning)
  midpoint = ((pos1[0]+pos2[0])/2,(pos1[1]+pos2[1])/2)
  left = (midpoint[0]-(length/2)+5) / float(width) * 100.0
  top = (midpoint[1]+2) / float(height) * 100.0

  return [length, left, top, angle]

def generateData(datafile, iconmap, linemap, idmap, height, width, excluded_icons = []):
  try:
    f = open(datafile, "r")
  except (IOError):
    print 'Data needs to be fetched from wowhead before running this script:'
    print '   ./generate_artifacts.py --fetchdata'
    sys.exit(0)

  core = BeautifulSoup(f.read(), 'html.parser')
  f.close()
  traits = core.find_all(lambda tag: tag.name == 'a' and tag.get('data-artifact-id'))
  
  power_to_id = {}
  for t in traits:
    
    styles = {}
    for style in t['style'].split(';'):
      style = style.strip()
      if (len(style) == 0):
        continue
      s = style.split(':')
      k = s[0].strip()
      v = float(s[1].strip()[:-1])
      styles[k] = v
    
    spell_id = t['href'].split('=')[1].split('&')[0]
    icondiv = t.find_all(lambda tag: tag.name == 'div' and tag.get('class') and
                         tag.get('class') == ['artifactcalc-sprite-icon'])
    icon = icondiv[0]['style'].split('/')[-1].split('.')[0]
    maxlevel = int(t['data-max-level'])

    ring = ""
    for c in t['class']:
      if 'PerkRing' in c:
        if 'MainProc' in c:
          ring = 'thick'
        elif 'GoldMedal' in c:
          ring = 'dragon'
        elif 'Small' in c:
          ring = 'thin'
          
    iconmap[idmap[spell_id]] = {
      'icon': icon,
      'xpos': int(round((styles['left'] / 100.0) * float(width))),
      'ypos': int(round((styles['top'] / 100.0) * float(height))),
      'spell_id': spell_id,
      'max_level': maxlevel,
      'style': ring,
    }

    # Generate a map of spell ID to wowhead power ID to use when building lines
    spell_id = t['href'].split('=')[1].split('&')[0]
    power_id = t['data-power-id']
    power_to_id[power_id] = idmap[spell_id]

  # If there are any excluded items, remove them from the map. Usually an excluded
  # item has been datamined, but there's not an actual connection to the tree yet,
  # so there's just an icon sitting out off by itself. Remove these from the map
  # so that it doesn't look funny.
  for e in excluded_icons:
    del iconmap[idmap[e]]

  lines = core.find_all(lambda tag: tag.name == 'div' and tag.get('data-power-from-to'))
  for l in lines:
    from_to = l['data-power-from-to'].split('-')
    line = { 'icon1': power_to_id[from_to[0]],
             'icon2': power_to_id[from_to[1]] }
    linemap.append(line)

def scale(y, old_min, old_max, new_min, new_max):
  return (((float(new_max)-float(new_min))*(float(y)-float(old_min))) / (float(old_max)-float(old_min))) + float(new_min)

if sys.argv[1] == '--db':

  ICONS = {}
  LINES = []
  BG_IMAGE = '/images/artifacts/dreadblades-bg-icons.png'
  IMAGE_HEIGHT=615
  IMAGE_WIDTH=720
  datafile = "dreadblades_data.txt"

  spell_id_map = {
    "202665": "db_curse",
    "202897": "db_blunderbuss",
    "202769": "db_blurredtime",
    "202820": "db_greed",
    "202507": "db_bladedancer",
    "202628": "db_blademaster",
    "202463": "db_cursededges",
    "202521": "db_cursedleather",
    "202755": "db_deception",
    "202524": "db_fatebringer",
    "202514": "db_fatesthirst",
    "202530": "db_fortunestrikes",
    "202907": "db_fortunesboon",
    "202533": "db_ghostlyshell",
    "202522": "db_gunslinger",
    "202753": "db_hiddenblade",
    "216230": "db_blackpowder",
    "214929": "db_cursedsteel",
  }
  
  exclude = []

  generateData('dreadblades_data.txt', ICONS, LINES, spell_id_map, IMAGE_HEIGHT, IMAGE_WIDTH, exclude)

elif sys.argv[1] == '--ks':

  ICONS = {}
  LINES = []
  BG_IMAGE = '/images/artifacts/kingslayers-bg-icons.png'
  IMAGE_HEIGHT=615
  IMAGE_WIDTH=720

  spell_id_map = {
    "192759": "ks_kingsbane",
    "192657": "ks_bagoftricks",
    "192428": "ks_fromtheshadows",
    "192923": "ks_fadeintoshadows",
    "192310": "ks_toxicblades",
    "192318": "ks_masteralchemist",
    "192424": "ks_surgeoftoxins",
    "192349": "ks_masterassassin",
    "192422": "ks_shadowswift",
    "192345": "ks_shadowwalker",
    "192384": "ks_urgetokill",
    "192315": "ks_serratededge",
    "192326": "ks_balancedblades",
    "192323": "ks_embrace",
    "192329": "ks_gushingwound",
    "192376": "ks_poisonknives",
    "214928": "ks_slayersprecision",
    "214368": "ks_assassinsblades",
  }

  exclude = []

  generateData('kingslayers_data.txt', ICONS, LINES, spell_id_map, IMAGE_HEIGHT, IMAGE_WIDTH, exclude)

elif sys.argv[1] == '--fangs':

  ICONS = {}
  LINES = []
  BG_IMAGE = '/images/artifacts/fangs-bg-icons.png'
  IMAGE_HEIGHT=615
  IMAGE_WIDTH=720

  spell_id_map = {
    "209782": "fangs_goremawsbite",
    "209781": "fangs_shadownova",
    "209835": "fangs_akaarissoul",
    "197406": "fangs_finality",
    "197239": "fangs_energetic",
    "197244": "fangs_ghostarmor",
    "197241": "fangs_catlike",
    "197386": "fangs_soulshadows",
    "197234": "fangs_gutripper",
    "197231": "fangs_quietknife",
    "197256": "fangs_flickering",
    "197610": "fangs_second",
    "197233": "fangs_demonskiss",
    "197235": "fangs_precision",
    "197604": "fangs_embrace",
    "197369": "fangs_fortunesbite",
    "214930": "fangs_legionblade",
    "221856": "fangs_shadowfangs",
  }

  exclude = []

  generateData('fangs_data.txt', ICONS, LINES, spell_id_map, IMAGE_HEIGHT, IMAGE_WIDTH, exclude)

  # For Fangs, the default positions make the icons at the top of the tree run into
  # the right most relic icon (namely shadow nova). Scale all of them downwards so
  # shadow nova is 45px lower and everything scales from there.
  for key,value in ICONS.iteritems():
    # demon's kiss is the bottom, shadow nova is the top
    # at 520 pixels, movement should be 45 * 0%
    # at 68 pixels, movement should be 45 * 100%
    newval = int(round(scale(value['ypos'], 68, 520, 68+45, 520)))
    value['ypos'] = newval

elif sys.argv[1] == '--fetchdata':

  dcap = dict(DesiredCapabilities.PHANTOMJS)
  dcap["phantomjs.page.settings.userAgent"] = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/53 "
    "(KHTML, like Gecko) Chrome/15.0.87"
  )
  
  # Create a PhantomJS web driver to load the pages including executing all of
  # the javascript on the page.
  browser = webdriver.PhantomJS(desired_capabilities=dcap)

  browser.get('http://www.wowhead.com/artifact-calc/rogue/outlaw/AgXiIsA')
  time.sleep(2)
  source = browser.page_source
  soup = BeautifulSoup(source, 'html.parser')
  core=soup.find('div', class_='artifactcalc-core')

  f = open('dreadblades_data.txt', 'w')
  f.write(str(core))
  f.close()

  browser.get('http://www.wowhead.com/artifact-calc/rogue/assassination/AvTSIrA')
  time.sleep(2)
  source = browser.page_source
  soup = BeautifulSoup(source, 'html.parser')
  core=soup.find('div', class_='artifactcalc-core')

  f = open('kingslayers_data.txt', 'w')
  f.write(str(core))
  f.close()

  browser.get('http://www.wowhead.com/artifact-calc/rogue/subtlety/AlIxIRA')
  time.sleep(2)
  source = browser.page_source
  soup = BeautifulSoup(source, 'html.parser')
  core=soup.find('div', class_='artifactcalc-core')

  f = open('fangs_data.txt', 'w')
  f.write(str(core))
  f.close()

  browser.quit()
  sys.exit(0)

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

elif sys.argv[2] == '--rails':
  sys.stdout.write(':traits => {')
  for key,value in iter(sorted(ICONS.iteritems())):
    sys.stdout.write('\'{}\':0,'.format(value['spell_id']))
  sys.stdout.write('}')

elif sys.argv[2] == '--reacttags':
  for key,value in iter(sorted(ICONS.iteritems())):
    left = (value['xpos']/float(IMAGE_WIDTH))*100.0
    top = (value['ypos']/float(IMAGE_HEIGHT))*100.0
    sys.stdout.write('<ArtifactTrait id="{}" tooltip_id="{}" left="{:.3f}%" top="{:.3f}%" max_rank="{}" icon="{}" ring="{}" cur_rank="0" />\n'.format(key, value['spell_id'], left, top, value['max_level'], value['icon'], value['style']))

  sys.stdout.write('\n')
  for line in LINES:
    icon1=ICONS[line['icon1']]
    icon2=ICONS[line['icon2']]
    x1 = (icon1['xpos']/float(IMAGE_WIDTH))*100.0
    y1 = (icon1['ypos']/float(IMAGE_HEIGHT))*100.0
    x2 = (icon2['xpos']/float(IMAGE_WIDTH))*100.0
    y2 = (icon2['ypos']/float(IMAGE_HEIGHT))*100.0
    sys.stdout.write('<line x1="{:.3f}%" y1="{:.3f}%" x2="{:.3f}%" y2="{:.3f}%" strokeWidth="6" stroke="yellow"/>\n'.format(x1, y1, x2, y2))

elif sys.argv[2] == '--react':
  print 'traits: {'
  for key,value in iter(sorted(ICONS.iteritems())):
    x = int(value['xpos'])
    y = int(value['ypos'])
    if value['style'] == 'thin':
      x += 30
      y += 30
    else:
      x += 45
      y += 45

    print '"%s": {' % key
    print 'id: %d,' % int(value['spell_id'])
    print 'x: %d,' % x
    print 'y: %d,' % y
    print 'icon: "%s",' % value['icon']
    print 'ring: "%s",' % value['style']
    print 'max_rank: %s' % value['max_level']
    print '},'
  print '},'

  print 'lines: ['
  for line in LINES:
    icon1=ICONS[line['icon1']]
    icon2=ICONS[line['icon2']]
    print '{'
    print 'trait1: "%s",' % line['icon1']
    print 'trait2: "%s"' % line['icon2']
    print '},'
  print ']'
