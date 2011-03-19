# ShadowCraft

## About

ShadowCraft is a framework for rogue gear, talent, gem, reforge, enchant, glyph, and rotation optimization. The goal is to have a tool that can run as close to entirely clientside as possible.

Currently, ShadowCraft uses server-side Ruby for Armory/Wowhead data import and distilling into JS files for consumption by the client.

## Requirements

Requires Ruby 1.9.2, Rails 3, Coffeescript (which means node.js), and MongoDB 1.6+, as well as a browser made this decade.

The engine requires Python 2.6 and a recent version of Twisted.

## Installing it

    git clone git://github.com/cheald/shadowcraft-ui.git
    cd shadowcraft-ui/
    bundle install

Start it up (passenger, unicorn, thin, whatever your poison) and you're rolling. Sweet.

## Initial data population

You'll want items in your database. Fortunately, that's easy.

    rails console production
    > Item.populate_gear
    > Item.populate_gems
    > Glyph.populate!
    > Enchant.update_from_json!

Congrats. You now have ~2000 items and gems locally cached.

## Contributing

Guidelines:

* All client app updates are done in coffeescript, and make.watchr is used to compile them into concatenation.js.
* Markup should validate as HTML5.
* Javascript should be tested for workingness in Chrome, Firefox 3.6/4, Safari, and IE9.
* Commits shall have useful (terse is okay) commit messages.
* A test suite would be particularly welcome.

How To:

* Clone this repository
* Make your changes and publish to your own GitHub copy of the repository
* Issue a pull request. More information with the pull request is more likely to end up with a merge.