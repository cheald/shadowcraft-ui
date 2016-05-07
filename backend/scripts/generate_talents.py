#!/usr/bin/python

# This script generates talent data from wowhead. It generally shouldn't be necessary
# once an expansion is released because we usually get talent data from the Blizzard
# API and use that instead. The output from this script should be copied into
# lib/wow_armory/talents.coffee. The script requires a few external libraries to be
# installed:
#
# PhantomJS:
# Install node using apt-get: apt-get install nodejs
# Install PhantomJS from npm: npm -g install phantomjs
#
# Python modules:
# Install pip: apt-get install pip
# Install selenium/BeautifulSoup: pip install selenium bs4

import time
from selenium import webdriver
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
from bs4 import BeautifulSoup

# This function is used at the end to make generating the output for javascript more
# generic. This takes the element from BeautifulSoup and scrapes the talent data for
# any given spec.
def build(source, letter):
    talents = source.select('div[cursor="pointer"]')
    for t in talents:
        tier = t['data-row']
        column = t['data-col']
        spell = t.select('a[class="screen"]')[0]['href'].split('=')[1]
        name = t.select('td')[0].text
        
        icon = t.select('ins')[0].get('style')
        icon = icon.split('/')[-1]
        icon = icon.split('.jpg')[0]
        print '        self.talents[:%s] << {tier: %d, column: %d, spell: %d, name: "%s", icon: "%s"}' % (letter, int(tier), int(column), int(spell), name, icon)

dcap = dict(DesiredCapabilities.PHANTOMJS)
dcap["phantomjs.page.settings.userAgent"] = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/53 "
    "(KHTML, like Gecko) Chrome/15.0.87"
)

# Create a PhantomJS web driver to load the pages including executing all of
# the javascript on the page.
browser = webdriver.PhantomJS(desired_capabilities=dcap)

# Scrape the three talent trees into strings and use BeautifulSoup to grab
# just the element we want from each of them.
browser.get('http://legion.wowhead.com/talent-calc/rogue/assassination')
time.sleep(2)
source = browser.page_source
soup = BeautifulSoup(source, 'html.parser')
assassination=soup.find('div', class_='talentcalc-core')

browser.get('http://legion.wowhead.com/talent-calc/rogue/outlaw')
time.sleep(2)
source = browser.page_source
soup = BeautifulSoup(source, 'html.parser')
outlaw=soup.find('div', class_='talentcalc-core')

browser.get('http://legion.wowhead.com/talent-calc/rogue/subtlety')
time.sleep(2)
source = browser.page_source
soup = BeautifulSoup(source, 'html.parser')
subtlety=soup.find('div', class_='talentcalc-core')
browser.quit()

build(assassination, 'a')
build(outlaw, 'Z')
build(subtlety, 'b')
