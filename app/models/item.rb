class Item
  include Mongoid::Document
  include Mongoid::Timestamps
  include WowArmory::Constants

  field :remote_id, :type => Integer
  field :item_level, :type => Integer
  field :properties, :type => Hash
  field :contexts, :type => Array, :default => []
  field :context_map, :type => Hash
  field :is_gem, :type => Boolean, :default => false

  index({remote_id: 1, contexts: 1}, {unique: true})
  index({remote_id: 1, item_level: 1, is_gem: 1}, {unique: true})

  attr_accessor :item_name_override

  validates_presence_of :remote_id
  validates_presence_of :properties

  # These are the only bonus IDs we care about displaying on the gear popouts.  They're
  # mostly just the different difficulty levels that can be on gear.  Anything not listed
  # here is ignored and a separate item is not created in the database for it.  This is
  # how we prevent duplicates of items from showing up on the UI.  There are so many bonus
  # IDs that it's easier to whitelist the ones we want, instead of blacklisting the ones
  # we don't.
  #
  # This whitelist skips any of the randomly generated bonus IDs such as any "of the"
  # bonuses and any "100%" IDs.  It also skips any bonus IDs that are sockets.
  BASE_WHITELIST = [1, 15, 17, 18, 44, 171, 448, 449, 450, 451, 499, 526, 527, 545, 546, 547,
                    553, 554, 555, 556, 557, 558, 559, 566, 567, 573, 575, 576, 577, 582, 583,
                    591, 592, 593, 594, 602, 609, 615, 617, 618, 619, 620, 645, 656, 692]

  # These are the bonus IDs for "base item levels". This generally means there are WF/TF
  # versions of the item.
  BASE_ILEVEL_WHITELIST = [1726, 1727, 1798, 1799, 1801, 1805, 1806, 1807, 1824, 1825, 1826,
                           3379, 3394, 3395, 3396, 3397, 3399, 3410, 3411, 3412, 3413, 3414,
                           3415, 3416, 3417, 3418, 3427, 3428, 3432, 3443, 3444, 3445, 3446]

  BONUS_ID_WHITELIST = BASE_WHITELIST + BASE_ILEVEL_WHITELIST

  # For some reason the crafted items don't come with the "stage" bonus IDs in their
  # chanceBonusList entry.  This is the list of bonus IDs for those stages and is
  # handled slightly differently.  See below for the check for trade-skill for more
  # details.
  WOD_TRADESKILL_BONUS_IDS = [525, 526, 527, 558, 559, 593, 594, 617, 619, 618, 620]
  TRADESKILL_BONUS_IDS = [596, 597, 598, 599, 666, 667, 668, 669, 670, 671, 672]

  ARTIFACT_WEAPONS = [128476, 128479, 128870, 128869, 128872, 134552]
  ORDER_HALL_SET = [139739, 139740, 139741, 139742, 139743, 139744, 139745, 139746]
  MIN_ILVL = 800

  # This is the set of bonus IDs that should be on basically every legion item, but the API
  # neglects to actually add. These are the four tertiary stats and a legion socket.
  CHANCE_BONUSES = [40, 41, 42, 43, 1808, -1]

  def icon
    return '' if self.properties.nil?
    return '' if self.properties['icon'] == nil
    self.properties['icon'].split('/').last
  end

  def as_json(options={})
    json = {
      :id => remote_id,
      :n => properties['name'],
      :i => if icon.nil?
              ''
            else
              icon.gsub(/\.(tga|jpg|png)$/i, '')
            end,
      :q => properties['quality'],
      :stats => properties['stats'],
      :ctxts => context_map,
      :ilvl => item_level
    }

    if properties['equip_location']
      json[:e] = properties['equip_location']
    end

    if properties['gem_slot']
      json[:sl] = properties['gem_slot']
    end

    unless properties['speed'].blank?
      json[:speed] = properties['speed']
      json[:dps] = properties['dps']
      json[:subclass] = properties['subclass']
    end

    if properties['upgradable']
      json[:upgradable] = properties['upgradable']
    end
    if properties['chance_bonus_lists']
      json[:chance_bonus_lists] = properties['chance_bonus_lists']
    end

    json
  end

  def self.populate(prefix = 'www', source = 'wowapi')
    populate_gear(prefix, source)
    populate_gems(prefix, source)
    populate_relics()
  end

  def self.populate_gear(prefix = 'www', source = 'wowapi')
    @source = source

    item_ids = []

    # TODO: is it possible to avoid displaying items that aren't available in
    # the game anymore?
    # blue items
    puts "Requesting rare items from wowhead..."
    puts "Item levels 801 to 850"
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 3, 801, 850)
    puts "Item levels 851 to 900"
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 3, 851, 900)
    puts "Item levels 901 to 950"
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 3, 901, 950)

    # epic items
    # TODO: no idea why we break this up into three parts. It's probably something
    # to avoid loading too many items from wowhead at once.
    puts "Requesting epic items from wowhead..."
    puts "Item levels 801 to 850"
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 4, 801, 850)
    puts "Item levels 851 to 900"
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 4, 851, 900)
    puts "Item levels 901 to 950"
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 4, 901, 950)

    # Brinewashed items that don't show up in the wowhead searches
    item_ids += [134241, 134238, 134239, 134240, 134237, 134243, 134242]

    # Rings, necks, trinkets
    puts "Requesting list of rings from wowhead"
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items/armor/rings/min-level:800/class:4"
    puts "Requesting list of necks from wowhead"
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items/armor/amulets/min-level:800/class:4"
    puts "Requesting list of trinkets from wowhead"
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items/armor/trinkets/min-level:800/class:4"

    # Artifact weapons
    item_ids += ARTIFACT_WEAPONS
    item_ids += ORDER_HALL_SET

    # Legendaries
    puts "Requesting list of legendaries from wowhead"
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/armor/min-level:895/class:4/quality:5"

    # remove duplicates.
    item_ids = item_ids.uniq

    pos = 0
    item_ids.each do |id|
      pos = pos + 1
      Rails.logger.debug "item #{pos} of #{item_ids.length}" if pos % 10 == 0
      import id
    end

    true
  end

  def self.populate_gems(prefix = 'www', source = 'wowapi')
    gem_ids = get_ids_from_wowhead("http://www.wowhead.com/items/gems/prismatic?filter=166;6;0")
    gem_ids += get_ids_from_wowhead("http://www.wowhead.com/items/gems/prismatic?filter=166;7;0")

    Rails.logger.debug "importing now #{gem_ids.length} gems"
    pos = 0
    gem_ids.each do |id|
      begin
        pos = pos + 1
        Rails.logger.debug "gem #{pos} of #{gem_ids.length}" if pos % 10 == 0
        Rails.logger.debug id

        # TODO: theoretically we could just call Item.import here instead of duplicating
        # this code yet again.
        begin
          json = WowArmory::Document.fetch 'us', '/wow/item/%d' % id, {}
        rescue WowArmory::MissingDocument => e
          Rails.logger.debug "import_blizzard failed fetch of #{id}: #{e.message}"
          next
        end

        # check to see if this item is in the database yet. we check by ID and item level
        # since those are the two fields that generally differentiate different items.
        db_item = Item.find_or_initialize_by(:remote_id => json['id'])

        # if the item doesn't have properties yet, create a new item from the wow
        # armory library and then merge that into this record and save it.
        if db_item.properties.nil?
          # create an item from the json data that we've retrieved and store it in the
          # database. the initializer routine will deal with the upgrade level for us.
          item = WowArmory::Item.new(json, 'wowapi')

          # Merge the data from the armory item into the local db_item. This can't be
          # done through a function since Ruby doesn't do pass-by-value, so we have to
          # repeat this hunk of code.
          db_item.properties = item.as_json.with_indifferent_access
          db_item.is_gem = !db_item.properties['gem_slot'].blank?
          db_item.item_level = item.ilevel

          # Gems from the armory are coming with incorrect stats.
          db_item.properties['stats'].each do |key,value|
            # Legion Gems
            if value == 250
              db_item.properties['stats'][key] = 100
            elsif value == 375
              db_item.properties['stats'][key] = 150
            elsif value == 500
              db_item.properties['stats'][key] = 200
            # WoD Gems
            elsif value == 200
              db_item.properties['stats'][key] = 75
            elsif value == 160
              db_item.properties['stats'][key] = 50
            elsif value == 120
              db_item.properties['stats'][key] = 35
            end
          end

          if db_item.new_record?
            puts db_item.properties['name']
            db_item.save!
          end
        end

      rescue Exception => e
        Rails.logger.debug id
        Rails.logger.debug e.message
      end
    end
    true
  end

  def self.populate_relics
    item_ids = []

    # In this order: Iron, Blood, Shadow, Fel, Storm
    item_ids += get_ids_from_wowhead_by_type(-8)
    item_ids += get_ids_from_wowhead_by_type(-9)
    item_ids += get_ids_from_wowhead_by_type(-10)
    item_ids += get_ids_from_wowhead_by_type(-11)
    item_ids += get_ids_from_wowhead_by_type(-17)
    item_ids = item_ids.uniq

    Rails.logger.debug "importing now #{item_ids.length} relics"
    pos = 0
    item_ids.each do |id|
      begin
        pos = pos + 1
        Rails.logger.debug "relic #{pos} of #{item_ids.length}" if pos % 10 == 0
        Rails.logger.debug id

        # Use the normal item importer to import the base data for the item
        import id

      rescue Exception => e
        Rails.logger.debug id
        Rails.logger.debug e.message
      end
    end
    true
  end

  # This method will directly import an item without checking for an existing
  # version before doing so.
  def self.import(id, source = 'wowapi')
    case source
      when 'wowapi'
        import_blizzard(id)
    end
  end

  # This function will check for an item ID and context combination existing in the
  # database. If that combination doesn't exist, reload the whole item. Loading single
  # items doesn't take very long, so we're safe to just load the whole thing.
  def self.check_item_for_import(id, context, source='wowapi')
    count = Item.where(:remote_id => id, :contexts => context).count()
    if (count == 0)
      case source
        when 'wowapi'
          import_blizzard(id)
      end
    end
  end

  # Same as above, but for gems. This just checks item IDs since every gem has a different
  # item ID.
  def self.check_gem_for_import(id, source='wowapi')
    count = Item.where(:remote_id => id)
    if (count == 0)
      case source
        when 'wowapi'
          import_blizzard(id)
      end
    end
  end

  # Imports an item and all of its variants (contexts, upgrades, etc) from the
  # Blizzard armory API.
  def self.import_blizzard(id)
    Rails.logger.debug "importing #{id}"

    # Check for an existing item before loading everything for this one
    db_item = Item.find_or_initialize_by(:remote_id => id)
    unless db_item.properties.nil?
      return
    end

    # Request the initial json data from the armory and insert it in to the array of
    # json to be processed further
    json_data = Array.new
    begin
      base_json = WowArmory::Document.fetch 'us', '/wow/item/%d' % id, {}
      json_data.push(base_json)
    rescue WowArmory::MissingDocument => e
      Rails.logger.debug "import_blizzard failed fetch of #{id}: #{e.message}"
      return
    end

    # Check if the item has any available contexts. Remove the first context since that
    # context is the one the first document's data is valid for. For example, loading
    # a document for an item with contexts ['raid-normal','raid-heroic'] will default
    # to returning data for raid-normal.
    contexts = base_json['availableContexts'].clone
    contexts.delete_at(0)

    # NOTE: SPECIAL CASE HERE, REMOVE LATER
    # World quest items have the same problem as above, in that they all return the same
    # data. Only load one of them and reset the context below to something else. This
    # greatly reduces the amount of data we load for these items. Again, this is probably
    # a bug in the API data.
    if (contexts.find { |context| context.start_with?('world-quest-') })
      wq_contexts = contexts.clone()
      wq_contexts.keep_if { |context| context.start_with?('world-quest-') }
      wq_contexts.sort!
      contexts.delete_if { |context| context.start_with?('world-quest-') }
      contexts.push wq_contexts[-1]
    end

    # Next, look at the chance bonus lists that accompany the item. This bonus list is
    # the things that can be applied to an item, such as extra titles (warforged, crafting
    # stages), tertiary stats, sockets, etc.
    itemChanceBonuses = get_bonus_IDs_to_load(base_json['bonusSummary']['chanceBonusLists'].clone, id, base_json['context'], base_json['itemLevel'])
    defaultBonuses = base_json['bonusLists']

    # Loop through now-trimmed list of bonus IDs and load an additional item for each
    # one of those IDs from the armory, and store it in the list to be processed
    itemChanceBonuses.each do |bonus|
      begin
        Rails.logger.debug "Loading extra item for bonus ID #{bonus}"
        bonuses = defaultBonuses.clone()
        bonuses.push(bonus)
        params = {
          :bl => bonuses.join(',')
        }
        json = WowArmory::Document.fetch 'us', '/wow/item/%d' % id, params
        json_data.push(json)
      rescue WowArmory::MissingDocument => e
        Rails.logger.debug "import_blizzard failed fetch of #{id}/#{context}: #{e.message}"
        return
      end
    end

    # For each of the extra contexts, load the document for each one of them and store it
    # in the list of json to deal with
    contexts.each do |context|
      begin
        # TODO: this is probably where we should deal with the bonus IDs also. We need to
        # load each item with the necessary bonus IDs attached as well as the base items.
        Rails.logger.debug "Loading document for extra context #{context}"
        json = WowArmory::Document.fetch 'us', '/wow/item/%d/%s' % [id,context], {}

        # Flush anything that isn't above the minimum ilvl down the toilet. This happens
        # because timewalking items get added to the list, and we try to load the base
        # version of the item too.
        json_data.push(json)

        # Same thing here with the bonus IDs. Gotta load all of those here too.
        itemChanceBonuses = get_bonus_IDs_to_load(json['bonusSummary']['chanceBonusLists'], id, json['context'], json['itemLevel'])
        defaultBonuses = json['bonusLists']

        # Same thing here with the bonus IDs. Gotta load all of those here too.
        itemChanceBonuses.each do |bonus|
          begin
            Rails.logger.debug "Loading extra item for bonus ID #{bonus}"
            bonuses = defaultBonuses.clone()
            bonuses.push(bonus)
            params = {
              :bl => bonuses.join(',')
            }
            json = WowArmory::Document.fetch 'us', '/wow/item/%d/%s' % [id,context], params
            json_data.push(json)
          rescue WowArmory::MissingDocument => e
            Rails.logger.debug "import_blizzard failed fetch of #{id}/#{context}: #{e.message}"
            return
          end
        end
      rescue WowArmory::MissingDocument => e
        Rails.logger.debug "import_blizzard failed fetch of #{id}/#{context}: #{e.message}"
        return
      end
    end

    current_total = json_data.length
    json_data.delete_if {|x| x['itemLevel'] < MIN_ILVL and not ARTIFACT_WEAPONS.include? id and not ORDER_HALL_SET.include? id}
    Rails.logger.debug "Rejected #{current_total-json_data.length} json entries due to item level filter"

    Rails.logger.debug "Loading data from a total of #{json_data.length} json entries for this item"

    # Loop through the json data that was retrieved and process each in turn
    json_data.each do |json|

      # check to see if there is an item in the database with this ID and base item level yet. We
      # combine duplicate items together based on these two values.
      db_item = Item.find_or_initialize_by(:remote_id => json['id'], :item_level => json['itemLevel'])

      # create an item from the json data that we've retrieved so that we can use it
      # to build a database item. some parts of this will be used whether or not the
      # we haven't found a database item, so might as well go ahead and make it.
      item = WowArmory::Item.new(json, 'wowapi')

      if db_item.contexts.nil?
        db_item.contexts = []
      end

      if db_item.context_map.nil?
        db_item.context_map = {}
      end

      # if the item doesn't have properties yet, create a new item from the wow
      # armory library and then merge that into this record and save it.
      if db_item.properties.nil?

        # Merge the data from the armory item into the local db_item. This can't be
        # done through a function since Ruby doesn't do pass-by-value, so we have to
        # repeat this hunk of code.
        db_item.remote_id = item.id
        db_item.item_level = item.ilevel
        db_item.properties = item.as_json.with_indifferent_access
        db_item.is_gem = !db_item.properties['gem_slot'].blank?
      end

      name = item.context
      context = {}
      context['tag'] = item.tag
      if item.context.start_with?('world-quest')
        name = 'world-quest'
        context['tag'] = "World Quest"
      elsif item.context.start_with?('dungeon-level-up')
        name = 'dungeon-level-up'
        context['tag'] = "Level-up Dungeon"
      end
      context['defaultBonuses'] = item.bonus_tree

      # NOTE: this is a massive hack because of Blizzard. The API isn't returning chance
      # bonuses for lots and lots of items, which means we have no way to know whether
      # an item can have sockets or be warforged, etc. For non-trade-skill items, just
      # stick a set of bonuses on the item and be done with it.
      if item.context != 'trade-skill' and !db_item.is_gem?
        db_item.properties['chance_bonus_lists'] |= CHANCE_BONUSES
      end

      Rails.logger.debug json
      Rails.logger.debug context

      db_item.context_map[name] = context
      db_item.contexts.push(name)
      db_item.save!

    end
    true
  end

  # Trims a list of bonus IDs down to the set of IDs that we actually care about, like
  # titles, since we load an additional item for each one of those. The bonus IDs that
  # we want are white-listed earlier in this class. Extra items will be loaded for
  # these bonus IDs.
  def self.get_bonus_IDs_to_load(possible_IDs, item_id, context, item_level)
    itemChanceBonuses = possible_IDs.clone()
    itemChanceBonuses.delete_if { |bonus| !BONUS_ID_WHITELIST.include? bonus }

    # for trade-skill items, also add the bonuses for each of the "stage" titles
    if (context == 'trade-skill')
      if (item_level > 750)
        itemChanceBonuses = TRADESKILL_BONUS_IDS
      else
        itemChanceBonuses = WOD_TRADESKILL_BONUS_IDS
      end
    end

    if !itemChanceBonuses.empty?
      Rails.logger.debug "Loading extra items for these bonus IDs: %s" % itemChanceBonuses.join(",")
    end
    return itemChanceBonuses
  end

  # Retrieves a set of item IDs from wowhead using a filter on ilvl and quality
  def self.get_ids_from_wowhead_by_ilvl(prefix, quality, min_ilvl, max_ilvl)
    url = "http://#{prefix}.wowhead.com/items/min-level:#{min_ilvl}/max-level:#{max_ilvl}/class:4/quality:#{quality}/live-only:on?filter=21;1;0"
    get_ids_from_wowhead(url)
  end

  # Retrieves a set of item IDs from wowhead based on an explicit URL
  def self.get_ids_from_wowhead(url)
    doc = open(url, 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36').read
    ids = doc.scan(/_\[(\d+)\]=\{.*?\}/).flatten.map &:to_i
    ids
  end

  # Retrieves a set of item IDs from wowhead based on type. Used for loading relic IDs.
  def self.get_ids_from_wowhead_by_type(type)
    url = "http://www.wowhead.com/gems/type:#{type}?filter=166;7;0"
    doc = open(url, 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36').read
    ids = doc.scan(/_\[(\d+)\]=\{.*?\}/).flatten.map &:to_i
    ids
  end

  def self.reindex!
    self.all.each { |i| i.save }
  end

end
