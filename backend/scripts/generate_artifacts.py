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

FRAME_HEIGHT = 615
FRAME_WIDTH = 720

def getLineInfo(icon1, icon2, height, width):
    # adjust the corner points of each icon down and to the right 40 pixels since the outer div
    # of each icon is 80 pixels wide and tall.
    pos1 = (icon1['x']+40, icon1['y']+40)
    pos2 = (icon2['x']+40, icon2['y']+40)

    (dx, dy) = (pos2[0]-pos1[0], pos2[1]-pos1[1])
    length = int(round(math.sqrt(float(math.pow(math.fabs(dx), 2)+(math.pow(math.fabs(dy), 2))))))
    angle = math.degrees(math.atan2(dy, dx))

    # from the midpoint, we need to put the upper left corner of the div half of the length to
    # the left and half of the height from the right (plus a little bit of fine tuning)
    midpoint = ((pos1[0]+pos2[0])/2, (pos1[1]+pos2[1])/2)
    left = (midpoint[0]-(length/2)+5) / float(width) * 100.0
    top = (midpoint[1]+2) / float(height) * 100.0

    return [length, left, top, angle]

def generateData(datafile, iconmap, linemap, idmap):
    try:
        f = open(datafile, "r")
    except IOError:
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
            if len(style) == 0:
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
            'x': int(round((styles['left'] / 100.0) * float(FRAME_WIDTH))) + 45,
            'y': int(round((styles['top'] / 100.0) * float(FRAME_HEIGHT))) + 45,
            'spell_id': spell_id,
            'max_level': maxlevel,
            'style': ring,
        }

        # If this is a thin-ring icon, we need to move it up and to the left slightly so that
        # it matches the layout on wowhead a bit better.
        if ring == 'thin':
            iconmap[idmap[spell_id]]['x'] -= 15
            iconmap[idmap[spell_id]]['y'] -= 15
            iconmap[idmap[spell_id]]['relic'] = True
        else:
            iconmap[idmap[spell_id]]['relic'] = False

        # Generate a map of spell ID to wowhead power ID to use when building lines
        spell_id = t['href'].split('=')[1].split('&')[0]
        power_id = t['data-power-id']
        power_to_id[power_id] = idmap[spell_id]

    lines = core.find_all(lambda tag: tag.name == 'div' and tag.get('data-power-from-to'))
    for l in lines:
        from_to = l['data-power-from-to'].split('-')
        line = {'icon1': power_to_id[from_to[0]],
                'icon2': power_to_id[from_to[1]]}
        linemap.append(line)

def get_db_data():

    DATA = {
        'name': 'Dreadblades',
        'bg': '/images/artifacts/44-small.jpg'
    }

    ICONS = {}
    LINES = []

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
        "241153": "db_bravado",
        "238067": "db_sabermetrics",
        "238103": "db_dreadbladesvigor",
        "238139": "db_loadeddice",
        "239042": "db_concordance"
    }

    generateData('dreadblades_data.txt', ICONS, LINES, spell_id_map)
    DATA['traits'] = ICONS
    DATA['lines'] = LINES
    return DATA

def get_ks_data():

    DATA = {
        'name': 'Kingslayers',
        'bg': '/images/artifacts/kingslayers-bg.jpg'
    }

    ICONS = {}
    LINES = []

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
        "241152": "ks_silence",
        "238066": "ks_strangler",
        "238102": "ks_denseconcoction",
        "238138": "ks_sinistercirculation",
        "239042": "ks_concordance"
    }

    generateData('kingslayers_data.txt', ICONS, LINES, spell_id_map)
    DATA['traits'] = ICONS
    DATA['lines'] = LINES
    return DATA

def get_fangs_data():

    DATA = {
        'name': 'Fangs',
        'bg': '/images/artifacts/fangs-bg.jpg'
    }

    ICONS = {}
    LINES = []

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
        "241154": "fangs_shadows",
        "238068": "fangs_etchedinshadow",
        "242707": "fangs_shadowswhipser",
        "238140": "fangs_feedingfrenzy",
        "239042": "fangs_concordance"
    }

    generateData('fangs_data.txt', ICONS, LINES, spell_id_map)
    DATA['traits'] = ICONS
    DATA['lines'] = LINES
    return DATA

def fetch_data():
    dcap = dict(DesiredCapabilities.PHANTOMJS)
    dcap["phantomjs.page.settings.userAgent"] = (
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/53 "
        "(KHTML, like Gecko) Chrome/15.0.87"
    )

    # Create a PhantomJS web driver to load the pages including executing all of
    # the javascript on the page.
    browser = webdriver.PhantomJS(desired_capabilities=dcap)

    browser.get('http://ptr.wowhead.com/artifact-calc/rogue/outlaw/AgXiIsA')
    time.sleep(2)
    source = browser.page_source
    soup = BeautifulSoup(source, 'html.parser')
    core = soup.find('div', class_='artifactcalc-core')

    f = open('dreadblades_data.txt', 'w')
    f.write(str(core))
    f.close()

    browser.get('http://ptr.wowhead.com/artifact-calc/rogue/assassination/AvTSIrA')
    time.sleep(2)
    source = browser.page_source
    soup = BeautifulSoup(source, 'html.parser')
    core = soup.find('div', class_='artifactcalc-core')

    f = open('kingslayers_data.txt', 'w')
    f.write(str(core))
    f.close()

    browser.get('http://ptr.wowhead.com/artifact-calc/rogue/subtlety/AlIxIRA')
    time.sleep(2)
    source = browser.page_source
    soup = BeautifulSoup(source, 'html.parser')
    core = soup.find('div', class_='artifactcalc-core')

    f = open('fangs_data.txt', 'w')
    f.write(str(core))
    f.close()

    browser.quit()
    sys.exit(0)

def dump_output(data):

    print '    get%sTraits: ->' % data['name']
    print '      return ['
    for key, value in iter(sorted(data['traits'].iteritems())):
        left = (value['x'] / float(FRAME_WIDTH)) * 100.0
        top = (value['y'] / float(FRAME_HEIGHT)) * 100.0
        sys.stdout.write('        {')
        sys.stdout.write('id: "{}", spell_id: {}, max_level: {}, icon: "{}", ring: "{}", '.format(key,value['spell_id'], value['max_level'], value['icon'], value['style']))
        sys.stdout.write('left: {:.3f}, top: {:.3f}'.format(left, top))
        if value['style'] == 'thin':
            sys.stdout.write(', is_thin: true')
        sys.stdout.write('},\n')
    print '      ]'
    print

    print '    use%s: ->' % data['name']
    print '      $("#artifactframe").css("background-image", "url(\'%s\')")' % data['bg']
    print '      lines = ['
    for line in data['lines']:

        icon1 = data['traits'][line['icon1']]
        icon2 = data['traits'][line['icon2']]
        length, left, top, angle = getLineInfo(icon1, icon2, FRAME_HEIGHT, FRAME_WIDTH)
        sys.stdout.write('        {')
        sys.stdout.write('width: {}, left: {:.3f}, top: {:.3f}, angle: {:.3f}, spell1: {}, spell2: {}'.format(length, left, top, angle, icon1['spell_id'], icon2['spell_id']))
        sys.stdout.write('},\n')

    print '      ]'
    print
    print '      return Templates.artifact(traits: ArtifactTemplates.get%sTraits(), lines: lines)' % data['name']
    print

if len(sys.argv) == 1:
    dump_output(get_db_data())
    dump_output(get_fangs_data())
    dump_output(get_ks_data())
elif sys.argv[1] == '--db':
    dump_output(get_db_data())
elif sys.argv[1] == '--ks':
    dump_output(get_ks_data())
elif sys.argv[1] == '--fangs':
    dump_output(get_fangs_data())
elif sys.argv[1] == '--fetchdata':
    fetch_data()
