# Roguething

## About

Roguething is a framework for rogue gear, talent, gem, reforge, enchant, glyph, and rotation optimization. The goal is to have a tool that can run as close to entirely clientside as possible.

Currently, Roguething uses server-side Ruby for Armory/Wowhead data import and distilling into JS files for consumption by the client.

## Requirements

Requires Ruby 1.9.2 and MongoDB 1.6+, as well as a browser made this decade.

## Installing it

    git clone git://github.com/cheald/roguething.git    
    cd roguething/
    bundle install

Start it up (passenger, unicorn, thin, whatever your poison) and you're rolling. Sweet.

## Initial data population

You'll want items in your database. Fortunately, that's easy.

    rails console production
    > Item.populate

Congrats. You now have ~2000 items and gems locally cached.

## Contributing

Guidelines:

* app.js should lint reasonably well.
* Markup should validate as HTML5.
* Javascript should be tested for workingness in Chrome and Firefox at a minimum, with Safari, Opera, and IE9 as bonus candidates.
* Commits shall have useful (terse is okay) commit messages.
* A test suite would be particularly welcome.

How To:

* Clone this repository
* Make your changes and publish to your own GitHub copy of the repository
* Issue a pull request. More information with the pull request is more likely to end up with a merge.