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

  def icon
    return '' if self.properties.nil?
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

    if properties['upgrade_level']
      json[:upgrade_level] = properties['upgrade_level']
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

    json
  end

  def self.populate(prefix = 'www', source = 'wowapi')
    populate_gear_wod(prefix, source)
    populate_gems_wod(prefix, source)
  end

  KAZZAK_ITEMS = [124545, 124546, 127971, 127975, 127976, 127980, 127982]

  def self.populate_gear_wod(prefix = 'www', source = 'wowapi')
    @source = source

    item_ids = []

    # TODO: is it possible to avoid displaying items that aren't available in
    # the game anymore?
    # blue items
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 3, 600, 665)
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 3, 695, 705) # pvp

    # epic items
    # TODO: no idea why we break this up into three parts. It's probably something
    # to avoid loading too many items from wowhead at once.
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 4, 630, 665)
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 4, 666, 700)
    item_ids += get_ids_from_wowhead_by_ilvl(prefix, 4, 701, 750)

    # trinkets
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items=4.-4?filter=minle=530;ro=1"

    # 6.1 alchemy trinkets
    item_ids += [122601, 122602, 122603, 122604]
    # 6.2 alchemy trinkets
    item_ids += [128023, 128024]
    # 6.2.3 heirloom trinket
    item_ids += [133597]

    # legendary ring
    item_ids += [124636]

    # do not import mop trinkets here, so remove them
    item_ids -= [105029, 104780, 102301, 105278, 104531, 105527] # haromms_talisman
    item_ids -= [105082, 104833, 102302, 105331, 104584, 105580] # sigil_of_rampage
    item_ids -= [104974, 104725, 102292, 105223, 104476, 105472] # assurance_of_consequence
    item_ids -= [105114, 104865, 102311, 105363, 104616, 105612] # ticking_ebon_detonator

    # remove duplicates
    item_ids = item_ids.uniq

    pos = 0
    item_ids.each do |id|
      pos = pos + 1
      puts "item #{pos} of #{item_ids.length}" if pos % 10 == 0
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

    puts "importing now #{gem_ids.length} gems"
    pos = 0
    gem_ids.each do |id|
      begin
        pos = pos + 1
        puts "gem #{pos} of #{gem_ids.length}" if pos % 10 == 0
        puts id

        # TODO: theoretically we could just call Item.import here instead of duplicating
        # this code yet again.
        begin
          json = WowArmory::Document.fetch 'us', '/wow/item/%d' % id, {}
        rescue WowArmory::MissingDocument => e
          puts "import_blizzard failed fetch of #{id}: #{e.message}"
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
        puts id
        puts e.message
      end
    end
  end

  # these are the only bonus IDs we care about displaying on the gear popouts.  They're
  # mostly just the different difficulty levels that can be on gear.  Anything not listed
  # here is ignored and a separate item is not created in the database for it.  This is
  # how we prevent duplicates of items from showing up on the UI.  There are so many bonus
  # IDs that it's easier to whitelist the ones we want, instead of blacklisting the ones
  # we don't.
  #
  # This whitelist skips any of the randomly generated bonus IDs such as any "of the"
  # bonuses and any "100%" IDs.  It also skips any bonus IDs that are sockets.
  BONUS_ID_WHITELIST = [1, 15, 17, 18, 44, 171, 448, 449, 450, 451, 499, 526, 527, 545, 546, 547,
                        553, 554, 555, 556, 557, 558, 559, 560, 561, 562, 566, 567, 571, 573, 575,
                        576, 577, 582, 583, 591, 592, 593, 594, 602, 609, 615, 617, 618, 619, 620,
                        642, 644, 645, 646, 648, 651, 656, 692, 755, 756, 757, 758, 759, 760]

  # These are kept separate because we don't want to import all of them all at once.
  # Just import them organically as each ilvl becomes available.
  LEGENDARY_RING_BONUS_IDS = (622..641).to_a

  # For some reason the crafted items don't come with the "stage" bonus IDs in their
  # chanceBonusList entry.  This is the list of bonus IDs for those stages and is
  # handled slightly differently.  See below for the check for trade-skill for more
  # details.
  TRADESKILL_BONUS_IDS = [525, 558, 559, 594, 619, 620]

  # This method will directly import an item without checking for an existing
  # version before doing so.
  def self.import(id, source = 'wowapi')
    case source
      when 'wowapi'
        import_blizzard(id)
    end
  end

  # This item will check for an item ID and ilevel combination existing in the
  # database. If that combination doesn't exist, reload the whole item. Loading
  # single items doesn't take very long, so we're safe to just load the whole
  # thing (and all of the versions). This also works for gems.
  def self.check_for_import(id, item_level, is_gem=false, source='wowapi')
    # TODO: should we lock the database in some way here to avoid race condtions?
    if is_gem
      # For a gem, don't bother checking the item_level. Gems do have an item
      # level associated with them (for some reason), but there's only one
      # version of each gem stored in the DB.
      count = Item.where(:remote_id => id)
    else
      count = Item.where(:remote_id => id, :item_level => item_level).count()
    end
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
    puts "importing #{id}"

    # TODO: check for existing items and update as necessary

    # Store a flag and a set of upgrade levels for whether or not the item is upgradable.
    # This is used later during the item loading process
    upgradable = WowArmory::Item.check_upgradable(id)
    if upgradable
      upgrade_levels = [0,1,2]
    else
      upgrade_levels = [0]
    end

    # Request the initial json data from the armory and insert it in to the array of
    # json to be processed further
    json_data = Array.new
    begin
      json = WowArmory::Document.fetch 'us', '/wow/item/%d' % id, {:bl=>0}
      json_data.push(json)
    rescue WowArmory::MissingDocument => e
      puts "import_blizzard failed fetch of #{id}: #{e.message}"
      return
    end

    # Check if the item has any available contexts. Remove the first context since that
    # context is the one the first document's data is valid for. For example, loading
    # a document for an item with contexts ['raid-normal','raid-heroic'] will default
    # to returning data for raid-normal.
    contexts = json_data[0]['availableContexts'].clone
    contexts.delete_at(0)

    # NOTE: SPECIAL CASE HERE, REMOVE LATER
    # Because of a bug in the Blizzard API, Kazzak items return all of the raid contexts
    # even though only the raid-normal version of the item is available in-game. Remove
    # the other contexts and only load the raid-normal version for those items.
    if KAZZAK_ITEMS.include? id
      contexts.delete_if { |context| ['raid-heroic','raid-mythic'].include? context }
    end

    # Next, look at the chance bonus lists that accompany the item. This bonus list is
    # the things that can be applied to an item, such as extra titles (warforged, crafting
    # stages), tertiary stats, sockets, etc.
    itemChanceBonuses = get_valid_bonus_IDs(json_data[0]['bonusSummary']['chanceBonusLists'].clone, id, json_data[0]['context'])
    defaultBonuses = json_data[0]['bonusLists']

    # Loop through now-trimmed list of bonus IDs and load an additional item for each
    # one of those IDs from the armory, and store it in the list to be processed
    itemChanceBonuses.each do |bonus|
      begin
        puts "Loading extra item for bonus ID #{bonus}"
        bonuses = defaultBonuses.clone()
        bonuses.push(bonus)
        params = {
          :bl => bonuses.join(',')
        }
        json = WowArmory::Document.fetch 'us', '/wow/item/%d' % id, params
        json_data.push(json)
      rescue WowArmory::MissingDocument => e
        puts "import_blizzard failed fetch of #{id}/#{context}: #{e.message}"
        return
      end
    end

    # For each of the extra contexts, load the document for each one of them and store it
    # in the list of json to deal with
    contexts.each do |context|
      begin
        # TODO: this is probably where we should deal with the bonus IDs also. We need to
        # load each item with the necessary bonus IDs attached as well as the base items.
        puts "Loading document for extra context #{context}"
        json = WowArmory::Document.fetch 'us', '/wow/item/%d/%s' % [id,context], {}
        json_data.push(json)

        # Same thing here with the bonus IDs. Gotta load all of those here too.
        itemChanceBonuses = get_valid_bonus_IDs(json['bonusSummary']['chanceBonusLists'], id, json['context'])
        defaultBonuses = json['bonusLists']

        # Same thing here with the bonus IDs. Gotta load all of those here too.
        itemChanceBonuses.each do |bonus|
          begin
            puts "Loading extra item for bonus ID #{bonus}"
            bonuses = defaultBonuses.clone()
            bonuses.push(bonus)
            params = {
              :bl => bonuses.join(',')
            }
            json = WowArmory::Document.fetch 'us', '/wow/item/%d/%s' % [id,context], params
            json_data.push(json)
          rescue WowArmory::MissingDocument => e
            puts "import_blizzard failed fetch of #{id}/#{context}: #{e.message}"
            return
          end
        end
      rescue WowArmory::MissingDocument => e
        puts "import_blizzard failed fetch of #{id}/#{context}: #{e.message}"
        return
      end
    end

    puts "Loaded a total of #{json_data.length} json entries for this item"

    # Loop through the json data that was retrieved and process each in turn
    json_data.each do |json|

      # also loop through all of the upgrade levels, since we create a new item in the
      # database for each upgrade step.
      # TODO: could we actually not store a new item for each, but store an array of stats
      # for each upgrade level?
      upgrade_levels.each do | upgrade_level |

        # check to see if this item is in the database yet. we check by ID and item level
        # since those are the two fields that generally differentiate different items.
        db_item = Item.find_or_initialize_by(:remote_id => json['id'],
                                             :item_level => json['itemLevel'].to_i+upgrade_level*5)

        # if the item doesn't have properties yet, create a new item from the wow
        # armory library and then merge that into this record and save it.
        if db_item.properties.nil?
          # create an item from the json data that we've retrieved and store it in the
          # database. the initializer routine will deal with the upgrade level for us.
          item = WowArmory::Item.new(json, 'wowapi', upgradable, upgrade_level)

          # Merge the data from the armory item into the local db_item. This can't be
          # done through a function since Ruby doesn't do pass-by-value, so we have to
          # repeat this hunk of code.
          db_item.remote_id = item.id
          db_item.item_level = item.ilevel
          db_item.properties = item.as_json.with_indifferent_access
          db_item.is_gem = !db_item.properties['gem_slot'].blank?
          db_item.save()
        end
      end
    end
  end

  # Trims a list of bonus IDs down to the set of IDs that we actually care about, like
  # titles, since we load an additional item for each one of those. The bonus IDs that
  # we want are white-listed earlier in this class.
  def self.get_valid_bonus_IDs(possible_IDs, item_id, context)
    itemChanceBonuses = possible_IDs.clone()
    itemChanceBonuses.delete_if { |bonus| !BONUS_ID_WHITELIST.include? bonus }

    # for the legendary ring, also add the bonsues for each of the ring upgrade steps
    if (item_id == 124636)
      itemChanceBonuses = itemChanceBonuses + LEGENDARY_RING_BONUS_IDS
    end

    # for trade-skill items, also add the bonuses for each of the "stage" titles
    if (context == 'trade-skill')
      itemChanceBonuses = TRADESKILL_BONUS_IDS
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

  # TODO: this method can go away once live hits since we'll actually have the artifact
  # data from the blizzard API.
  def self.populate_artifacts
    db_item = Item.find_or_initialize_by(:remote_id => 128476, :item_level => 750)
    if (db_item.properties.nil?)
      db_item.remote_id = 128476
      db_item.item_level = 750
      db_item.properties = {
        :stats => {
          :agility => 219,
          :stamina => 328,
          :crit => 148,
          :mastery => 142},
        :icon => "inv_knife_1h_artifactfangs_d_01",
        :id => 128476,
        :name => "Fangs of the Devourer",
        :equip_location => 13,
        :ilevel => 750,
        :quality => 4, # TODO
        :socket_bonus => nil,
        :sockets => nil,
        :gem_slot => nil,
        :speed => 1.8,
        :dps => 712.82,
        :subclass => 15,
        :armor_class => nil,
        :upgradable => false,
        :upgrade_level => 0,
        :chance_bonus_lists => [],
        :bonus_tree => [743],
        :tag => "Gorefang",
      }
      db_item.is_gem = false
      db_item.save()
    end

    db_item = Item.find_or_initialize_by(:remote_id => 128479, :item_level => 750)
    if (db_item.properties.nil?)
      db_item.remote_id = 128479
      db_item.item_level = 750
      db_item.properties = {
        :stats => {
          :agility => 219,
          :stamina => 328,
          :crit => 148,
          :mastery => 142},
        :icon => "inv_knife_1h_artifactfangs_d_01",
        :id => 128476,
        :name => "Fangs of the Devourer",
        :equip_location => 13,
        :ilevel => 750,
        :quality => 4, # TODO
        :socket_bonus => nil,
        :sockets => nil, # TODO
        :gem_slot => nil,
        :speed => 1.8,
        :dps => 712.82,
        :subclass => 15,
        :armor_class => nil,
        :upgradable => false,
        :upgrade_level => 0,
        :chance_bonus_lists => [],
        :bonus_tree => [],
        :tag => "Akaari's Will",
      }
      db_item.is_gem = false
      db_item.save()
    end

    db_item = Item.find_or_initialize_by(:remote_id => 128870, :item_level => 750)
    if (db_item.properties.nil?)
      db_item.remote_id = 128870
      db_item.item_level = 750
      db_item.properties = {
        :stats => {
          :agility => 219,
          :stamina => 328,
          :crit => 148,
          :mastery => 142},
        :icon => "inv_knife_1h_artifactgarona_d_01",
        :id => 128870,
        :name => "The Kingslayers",
        :equip_location => 13,
        :ilevel => 750,
        :quality => 4, # TODO
        :socket_bonus => nil,
        :sockets => nil,
        :gem_slot => nil,
        :speed => 1.8,
        :dps => 712.82,
        :subclass => 15,
        :armor_class => nil,
        :upgradable => false,
        :upgrade_level => 0,
        :chance_bonus_lists => [],
        :bonus_tree => [743],
        :tag => "Anguish",
      }
      db_item.is_gem = false
      db_item.save()
    end


    db_item = Item.find_or_initialize_by(:remote_id => 128869, :item_level => 750)
    if (db_item.properties.nil?)
      db_item.remote_id = 128869
      db_item.item_level = 750
      db_item.properties = {
        :stats => {
          :agility => 219,
          :stamina => 328,
          :crit => 148,
          :mastery => 142},
        :icon => "inv_knife_1h_artifactgarona_d_01",
        :id => 128869,
        :name => "The Kingslayers",
        :equip_location => 13,
        :ilevel => 750,
        :quality => 4, # TODO
        :socket_bonus => nil,
        :sockets => nil,
        :gem_slot => nil,
        :speed => 1.8,
        :dps => 712.82,
        :subclass => 15,
        :armor_class => nil,
        :upgradable => false,
        :upgrade_level => 0,
        :chance_bonus_lists => [],
        :bonus_tree => [],
        :tag => "Sorrow",
      }
      db_item.is_gem = false
      db_item.save()
    end

    db_item = Item.find_or_initialize_by(:remote_id => 128872, :item_level => 750)
    if (db_item.properties.nil?)
      db_item.remote_id = 128872
      db_item.item_level = 750
      db_item.properties = {
        :stats => {
          :agility => 219,
          :stamina => 328,
          :crit => 148,
          :mastery => 142},
        :icon => "inv_knife_1h_artifactskywall_d_01",
        :id => 128872,
        :name => "The Dreadblades",
        :equip_location => 13,
        :ilevel => 750,
        :quality => 4, # TODO
        :socket_bonus => nil,
        :sockets => nil,
        :gem_slot => nil,
        :speed => 2.6,
        :dps => 712.75,
        :subclass => 15,
        :armor_class => nil,
        :upgradable => false,
        :upgrade_level => 0,
        :chance_bonus_lists => [],
        :bonus_tree => [743],
        :tag => "Fate",
      }
      db_item.is_gem = false
      db_item.save()
    end

    db_item = Item.find_or_initialize_by(:remote_id => 134552, :item_level => 750)
    if (db_item.properties.nil?)
      db_item.remote_id = 134552
      db_item.item_level = 750
      db_item.properties = {
        :stats => {
          :agility => 219,
          :stamina => 328,
          :crit => 148,
          :mastery => 142},
        :icon => "inv_knife_1h_artifactskywall_d_01",
        :id => 134552,
        :name => "The Dreadblades",
        :equip_location => 13,
        :ilevel => 750,
        :quality => 4, # TODO
        :socket_bonus => nil,
        :sockets => nil,
        :gem_slot => nil,
        :speed => 2.6,
        :dps => 712.75,
        :subclass => 15,
        :armor_class => nil,
        :upgradable => false,
        :upgrade_level => 0,
        :chance_bonus_lists => [],
        :bonus_tree => [],
        :tag => "Fortune",
      }
      db_item.is_gem = false
      db_item.save()
    end

  end

end
