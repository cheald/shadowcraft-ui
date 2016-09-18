class Item
  include Mongoid::Document
  include Mongoid::Timestamps
  include WowArmory::Constants

  field :remote_id, :type => Integer
  field :item_level, :type => Integer
  field :properties, :type => Hash
  field :is_gem, :type => Boolean
  field :is_glyph, :type => Boolean

  index({remote_id: 1, is_gem: 1, is_glyph: 1}, {unique: true})

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
  TRADESKILL_BONUS_IDS = [525, 558, 559, 594, 597, 598, 599, 619, 620, 666, 667, 668, 669]

  KAZZAK_ITEMS = [124545, 124546, 127971, 127975, 127976, 127980, 127982]
  ARTIFACT_WEAPONS = [128476, 128479, 128870, 128869, 128872, 134552]
  MIN_ILVL = 600

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
    }

    if properties['sockets'] and !properties['sockets'].empty?
      json[:so] = properties['sockets']
    end

    if properties['equip_location']
      json[:e] = properties['equip_location']
    end
    json[:ilvl] = properties['ilevel']

    if properties['socket_bonus']
      json[:sb] = properties['socket_bonus']
    end

    if properties['gem_slot']
      json[:sl] = properties['gem_slot']
    end

    json[:tag] = if properties['tag'] then
                   properties['tag']
                 else
                   ''
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
    if properties['bonus_tree']
      json[:bonus_tree] = properties['bonus_tree']
    end
    if properties['context']
      json[:context] = properties['context']
    end

    json
  end

  def self.populate(prefix = 'www', source = 'wowapi')
    populate_gear_wod(prefix, source)
    populate_gems_wod(prefix, source)
  end

  def self.populate_gear_wod(prefix = 'www', source = 'wowapi')
    @source = source

    item_ids = []

    # TODO: is it possible to avoid displaying items that aren't available in
    # the game anymore?
    # blue items
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 3, 600, 665)
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 3, 695, 705) # pvp
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 3, 701, 750)
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 3, 751, 800)
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 3, 801, 850)
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 3, 851, 900)

    # epic items
    # TODO: no idea why we break this up into three parts. It's probably something
    # to avoid loading too many items from wowhead at once.
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 4, 630, 665)
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 4, 666, 700)
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 4, 701, 750)
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 4, 751, 800)
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 4, 801, 850)
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 4, 851, 900)

    # Rings, necks, trinkets
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items/armor/rings/min-level:630/class:4"
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items/armor/amulets/min-level:630/class:4"
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items/armor/trinkets/min-level:630/class:4"

    # 6.1 alchemy trinkets
    item_ids += [122601, 122602, 122603, 122604]
    # 6.2 alchemy trinkets
    item_ids += [128023, 128024]
    # 6.2.3 heirloom trinket
    item_ids += [133597]

    # legendary ring
    item_ids += [124636]

    # Artifact weapons
    item_ids += ARTIFACT_WEAPONS

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

  def self.populate_gems_wod(prefix = 'www', source = 'wowapi')
    gem_ids = [
      115803, # crit taladite
      115804, # haste taladite
      115805, # mastery taladite
      115806, # multistrike taladite
      115807, # versatility taladite
      115808, # stamina taladite
      115809, # greater crit taladite
      115811, # greater haste taladite
      115812, # greater mastery taladite
      115813, # greater multistrike taladite
      115814, # greater versatility taladite
      115815, # greater stamina taladite
      127760, # immaculate crit taladite
      127761, # immaculate haste taladite
      127762, # immaculate mastery taladite
      127763, # immaculate multistrike taladite
      127764, # immaculate versatility taladite
      127765, # immaculate stamina taladite
      127414, # eye of rukhmar (+50 crit)
      127415, # eye of anzu (+50 haste)
      127416, # eye of sethe (+50 mastery)
    ]

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
          if db_item.new_record?
            db_item.save()
          end
        end

      rescue Exception => e
        Rails.logger.debug id
        Rails.logger.debug e.message
      end
    end
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
    count = Item.where(:remote_id => id, :"properties.context" => context).count()
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
      base_json = WowArmory::Document.fetch 'us', '/wow/item/%d' % id, {:bl=>0}
      if base_json['itemLevel'].to_i >= MIN_ILVL
        json_data.push(base_json)
      else
        Rails.logger.debug base_json['itemLevel']
        Rails.logger.debug "skipped due to item level filter"
      end
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
    # Because of a bug in the Blizzard API, Kazzak items return all of the raid contexts
    # even though only the raid-normal version of the item is available in-game. Remove
    # the other contexts and only load the raid-normal version for those items.
    if KAZZAK_ITEMS.include? id
      contexts.delete_if { |context| ['raid-heroic','raid-mythic'].include? context }
    end
    
    # NOTE: SPECIAL CASE HERE, REMOVE LATER
    # Mythic+ items all come in with the same data, even though there are 4 different
    # contexts for them. I'm pretty sure this is a bug in the API data, but in the meantime
    # ignore those items so they don't clutter up the list.
    contexts.delete_if { |context| context.start_with?('challenge-') }

    # NOTE: SPECIAL CASE HERE, REMOVE LATER
    # World quest items have the same problem as above, in that they all return the same
    # data. Only load one of them and reset the context below to something else. This
    # greatly reduces the amount of data we load for these items. Again, this is probably
    # a bug in the API data.
    contexts.delete_if { |context| context.start_with?('world-quest-') and !context.end_with?('-1') }

    # Next, look at the chance bonus lists that accompany the item. This bonus list is
    # the things that can be applied to an item, such as extra titles (warforged, crafting
    # stages), tertiary stats, sockets, etc.
    itemChanceBonuses = get_valid_bonus_IDs(base_json['bonusSummary']['chanceBonusLists'].clone, id, base_json['context'])
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
        next if json['itemLevel'] < MIN_ILVL
        json_data.push(json)

        # Same thing here with the bonus IDs. Gotta load all of those here too.
        itemChanceBonuses = get_valid_bonus_IDs(json['bonusSummary']['chanceBonusLists'], id, json['context'])
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

    Rails.logger.debug "Loaded a total of #{json_data.length} json entries for this item"

    # Loop through the json data that was retrieved and process each in turn
    json_data.each do |json|

      # check to see if this item is in the database yet. we check by ID and item level
      # since those are the two fields that generally differentiate different items.
      if json['context'].start_with?('world-quest')
        db_item = Item.find_or_initialize_by(:remote_id => json['id'], :context => 'world-quest')
      elsif json['context'].start_with?('dungeon-level-up')
        db_item = Item.find_or_initialize_by(:remote_id => json['id'], :context => 'dungeon-level-up')
      else
        db_item = Item.find_or_initialize_by(:remote_id => json['id'],
                                             :context => json['context'])
      end

      # if the item doesn't have properties yet, create a new item from the wow
      # armory library and then merge that into this record and save it.
      if db_item.properties.nil?
        # create an item from the json data that we've retrieved and store it in the
        # database. the initializer routine will deal with the upgrade level for us.
        item = WowArmory::Item.new(json, 'wowapi')

        # Merge the data from the armory item into the local db_item. This can't be
        # done through a function since Ruby doesn't do pass-by-value, so we have to
        # repeat this hunk of code.
        db_item.remote_id = item.id
        db_item.item_level = item.ilevel
        db_item.properties = item.as_json.with_indifferent_access
        if json['context'].start_with?('world-quest')
          db_item.properties['context'] = 'world-quest'
          db_item.properties['tag'] = "World Quest"
        elsif json['context'].start_with?('dungeon-level-up')
          db_item.properties['context'] = 'dungeon-level-up'
          db_item.properties['tag'] = "Level-up Dungeon"
        end
        db_item.is_gem = !db_item.properties['gem_slot'].blank?
        db_item.save()
      end
    end
  end

  # Trims a list of bonus IDs down to the set of IDs that we actually care about, like
  # titles, since we load an additional item for each one of those. The bonus IDs that
  # we want are white-listed earlier in this class.
  def self.get_valid_bonus_IDs(possible_IDs, item_id, context)
    itemChanceBonuses = possible_IDs.clone()
    puts itemChanceBonuses
    itemChanceBonuses.delete_if { |bonus| !BONUS_ID_WHITELIST.include? bonus }
    puts itemChanceBonuses

    # for trade-skill items, also add the bonuses for each of the "stage" titles
    if (context == 'trade-skill')
      itemChanceBonuses = TRADESKILL_BONUS_IDS
    end

    skipped = possible_IDs-itemChanceBonuses
    if !skipped.empty?
      Rails.logger.debug "skipping bonus IDs: %s" % skipped.join(",")
    end
    return itemChanceBonuses
  end

  # Retrieves a set of item IDs from wowhead using a filter on ilvl and quality
  def self.get_ids_from_wowhead_by_ilvl(prefix, quality, min_ilvl, max_ilvl)
    url = "http://#{prefix}.wowhead.com/items?filter=qu=#{quality};minle=#{min_ilvl};maxle=#{max_ilvl};ub=4;cr=21;crs=1;crv=0;eb=1"
    get_ids_from_wowhead(url)
  end

  # Retrieves a set of item IDs from wowhead based on an explicit URL
  def self.get_ids_from_wowhead(url)
    doc = open(url, 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36').read
    ids = doc.scan(/_\[(\d+)\]=\{.*?\}/).flatten.map &:to_i
    ids
  end

  def self.reindex!
    self.all.each { |i| i.save }
  end

end
