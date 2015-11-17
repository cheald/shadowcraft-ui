class Item
  include Mongoid::Document
  include Mongoid::Timestamps
  include WowArmory::Constants

  field :remote_id, :type => Integer, :index => true
  field :bonus_tree, :type => Integer
  field :upgrade_level, :type => Integer
  field :equip_location, :type => Integer, :index => true
  field :item_level, :type => Integer
  field :properties, :type => Hash
  field :info, :type => Hash
  field :stats, :type => HashWithIndifferentAccess
  field :has_stats, :type => Boolean
  field :requires, :type => Hash
  field :is_gem, :type => Boolean, :index => true
  field :is_glyph, :type => Boolean, :index => true

  attr_accessor :item_name_override

  validates_presence_of :remote_id
  validates_presence_of :properties

  before_validation :update_from_armory_if_necessary
  before_save :write_stats
  EXCLUDE_KEYS = [:stamina, :resilience, :strength, :spirit, :intellect, :dodge, :parry, :health_regen, :bonus_armor]

  def update_from_armory_if_necessary
    return if remote_id == 0
    if self.properties.nil?
      Rails.logger.debug "Loading item #{remote_id} during validation"
      item = WowArmory::Item.new(remote_id, 'wowapi', item_name_override)
      puts item
      # return false if item.stats.empty?
      self.properties = item.as_json.with_indifferent_access
      item_stats = WowArmory::Itemstats.new(self.properties, upgrade_level)
      self.properties = self.properties.merge(item_stats.as_json.with_indifferent_access)
      self.equip_location = self.properties['equip_location']
      self.is_gem = !self.properties['gem_slot'].blank?
    end
    true
  end

  # Unique Item identifier
  # TODO subject to change
  def uid
    # a bit silly
    uid = remote_id
    if not properties["upgrade_level"].nil?
      uid = uid * 1000000 + properties["upgrade_level"].to_i
    end
    uid
  end

  def icon
    return '' if self.properties.nil?
    self.properties['icon'].split('/').last
  end

  def write_stats
    return if properties.nil?
    self.stats = properties['stats']
    if all = self.stats.delete(:'all_stats')
      [:agility, :stamina, :strength].each do |stat|
        self.stats[stat] = (self.stats[stat] || 0) + all
      end
    end
    self.item_level = properties['ilevel']
    self.has_stats = !(self.stats.keys - EXCLUDE_KEYS).empty?
    true # Returning false from a before_save filter causes it to fail.
  end

  def as_json(options={})
    json = {
        :id => uid.to_i,
        :oid => remote_id,
        :n => properties['name'],
        :i => if icon.nil?
                ''
              else
                icon.gsub(/\.(tga|jpg|png)$/i, '')
              end,
        :q => properties['quality'],
        :stats => stats
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

    if properties['requirement']
      json[:rq] = {:profession => properties['requirement'].downcase}
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

    if properties['random_suffix']
      json[:suffix] = properties['random_suffix']
    end
    if properties['upgrade_level']
      json[:upgrade_level] = properties['upgrade_level']
    end
    if properties['upgradable']
      json[:upgradable] = properties['upgradable']
    end
    if properties['bonus_trees']
      json[:bonus_trees] = properties['bonus_trees']
    end
    if properties['chance_bonus_lists']
      json[:chance_bonus_lists] = properties['chance_bonus_lists']
    end

    json
  end

  KAZZAK_ITEMS = [124545, 124546, 127971, 127975, 127976, 127980, 127982]

  def self.populate_gear_wod(prefix = 'www', source = 'wowapi')
    @source = source

    # blue items
    item_ids = get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=3;minle=600;maxle=665;ub=4;cr=21;crs=1;crv=0"

    # epic items
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=630;maxle=665;ub=4;cr=21;crs=1;crv=0"
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=666;maxle=700;ub=4;cr=21;crs=1;crv=0"
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=701;maxle=750;ub=4;cr=21;crs=1;crv=0"

    # trinkets
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items=4.-4?filter=minle=530;ro=1"

    # 6.1 alchemy trinkets
    item_ids += [122601, 122602, 122603, 122604]
    # 6.2 alchemy trinkets
    item_ids += [128023, 128024]

    # legendary ring
    item_ids += [124636]

    # do not import mop trinkets here, so remove them
    item_ids -= [105029, 104780, 102301, 105278, 104531, 105527] # haromms_talisman
    item_ids -= [105082, 104833, 102302, 105331, 104584, 105580] # sigil_of_rampage
    item_ids -= [104974, 104725, 102292, 105223, 104476, 105472] # assurance_of_consequence
    item_ids -= [105114, 104865, 102311, 105363, 104616, 105612] # ticking_ebon_detonator

    # remove the Kazzak items so they can be imported separately.  Right now, Blizzard includes
    # all of the various versions of the items, even though Normal-mode items are the only ones
    # actually available in-game.
    item_ids -= KAZZAK_ITEMS

    # remove duplicates
    item_ids = item_ids.uniq

    pos = 0
    item_ids.each do |id|
      pos = pos + 1
      puts "item #{pos} of #{item_ids.length}" if pos % 10 == 0
      wod_import id
    end

    # only import the Normal version of all of the Kazzak items.  No heroic and no mythic.
    KAZZAK_ITEMS.each do |id|
      wod_import id, 'raid-normal'
    end

    true
  end

  def self.populate_gems_wod(prefix = 'www', source = 'wowhead')
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
        db_item = Item.find_or_initialize_by(:remote_id => id)
        if db_item.properties.nil?
          item = WowArmory::Item.new(id, source)
          db_item.properties = item.as_json.with_indifferent_access
          db_item.equip_location = db_item.properties['equip_location']
          db_item.is_gem = !db_item.properties['gem_slot'].blank?
          if db_item.new_record?
            db_item.save
          end
        end
      rescue WowArmory::MissingDocument => e
        puts id
        puts e.message
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
                        642, 644, 645, 646, 648, 651, 656, 692]

  # These are kept separate because we don't want to import all of them all at once.
  # Just import them organically as each ilvl becomes available.
  LEGENDARY_RING_BONUS_IDS = (622..641).to_a

  # For some reason the crafted items don't come with the "stage" bonus IDs in their
  # chanceBonusList entry.  This is the list of bonus IDs for those stages and is
  # handled slightly differently.  See below for the check for trade-skill for more
  # details.
  TRADESKILL_BONUS_IDS = [525, 558, 559, 594, 619, 620]

  def self.wod_import(id, context = '', bonuses = nil)
    source = 'wowapi'
    puts id
    existing_item = Item.find :all, :conditions => {:remote_id => id}
    unless existing_item.empty?
      existing_item.each do |item|
        copy = item.properties['bonus_trees'].clone
        if copy.include? ''
          copy.delete('')
        end
        if copy.include? 0
          copy.delete(0)
        end
        return if copy == bonuses
      end
      return if bonuses.nil?

      # if the bonus isn't in the whitelist and isn't one of the legendary ring
      # IDs, remove it so it doesn't get loaded.
      bonuses.delete_if { |bonus| !BONUS_ID_WHITELIST.include? bonus and !LEGENDARY_RING_BONUS_IDS.include? bonus }

      # if we're left with no bonuses to load, give up
      return if bonuses.empty?
      
      # make a special import with the given and possible missing bonus id data from armory
      puts "special import #{id} #{context} #{bonuses.inspect}"
      self.wod_special_import id, context, bonuses
      return
    end

    begin
      json_data = WowArmory::Document.fetch 'us', '/wow/item/%d' % id, {}, :json
    rescue WowArmory::MissingDocument => e
      puts "wod_import failed initial fetch of #{id}: #{e.message}"
      return
    end

    upgradable = WowArmory::Item.check_upgradable(id)
    if upgradable
      upgrade_levels = [0,1,2]
    else
      upgrade_levels = [0]
    end

    json_data['availableContexts'].each do |context|
      upgrade_levels.each do |upgrade_level|
        if context == ''
          context_data = json_data
        else
          context_data = WowArmory::Document.fetch 'us', '/wow/item/%d/%s' % [id, context], {}, :json
        end

        context_data['bonusSummary']['defaultBonusLists'].clone.each do |defaultBonusListsId|
          context_data['bonusSummary']['defaultBonusLists'].delete(defaultBonusListsId) unless BONUS_ID_WHITELIST.include? defaultBonusListsId
        end

        # if the context is trade-skill, add these bonus IDs manually since they don't
        # aren't in the data returned from Blizzard for whatever reason.
        if context == 'trade-skill'
          context_data['bonusSummary']['defaultBonusLists'] =
            context_data['bonusSummary']['defaultBonusLists'] + TRADESKILL_BONUS_IDS
        end

        if id = 124636
          context_data['bonusSummary']['defaultBonusLists'] =
            context_data['bonusSummary']['defaultBonusLists'] + LEGENDARY_RING_BONUS_IDS
        end

        if context_data['bonusSummary']['defaultBonusLists'].empty?
          context_data['bonusSummary']['defaultBonusLists'] = [0]
        end

        context_data['bonusSummary']['defaultBonusLists'].each do |defaultBonus|
          options = {
            :remote_id => id,
            :bonus_trees => [defaultBonus],
            :item_level => json_data["itemLevel"]+5*upgrade_level
          }
          db_item = Item.find_or_initialize_by options
          if db_item.properties.nil?
            item = WowArmory::Item.new(id, source, nil, context, options[:bonus_trees])

            db_item.properties = item.as_json.with_indifferent_access
            if (upgrade_level != 0)
              item_stats = WowArmory::Itemstats.new(db_item.properties, upgrade_level)
              db_item.properties = db_item.properties.merge(item_stats.as_json.with_indifferent_access)
            end
            db_item.equip_location = db_item.properties['equip_location']
            db_item.is_gem = !db_item.properties['gem_slot'].blank?
            if db_item.new_record?
              db_item.save
            end
            # if available we need to import warforged too
            # the other stuff like extra socket or tertiary stats are added in the UI dynamically
            context_data['bonusSummary']['chanceBonusLists'].each do |bonus|
              next unless BONUS_ID_WHITELIST.include? bonus
              puts bonus
              options = {
                :remote_id => id,
                :bonus_trees => [defaultBonus] + [bonus],
                :item_level => json_data["itemLevel"]+5*upgrade_level
              }
              db_item_with_bonus = Item.find_or_initialize_by options
              if db_item_with_bonus.properties.nil?
                item = WowArmory::Item.new(id, source, nil, context, options[:bonus_trees])
                db_item_with_bonus.properties = item.as_json.with_indifferent_access
                if (upgrade_level != 0)
                  item_stats = WowArmory::Itemstats.new(db_item_with_bonus.properties, upgrade_level)
                  db_item_with_bonus.properties = db_item_with_bonus.properties.merge(item_stats.as_json.with_indifferent_access)
                end
                db_item_with_bonus.equip_location = db_item_with_bonus.properties['equip_location']
                db_item_with_bonus.is_gem = !db_item_with_bonus.properties['gem_slot'].blank?
                if db_item_with_bonus.new_record?
                  db_item_with_bonus.save
                end
              end
            end
          end
        end
      end
    end
  end

  def self.wod_special_import(id, context, bonuses)
    begin
      source = 'wowapi'

      begin
        url = '/wow/item/%d' % id
        if context.length != 0 and context != 'quest-reward'
          url << '/%s/' % context
        end
        json_data = WowArmory::Document.fetch 'us', url, {}, :json
      rescue WowArmory::MissingDocument => e
        puts "wod_special_import: initial fetch of #{id}: #{e.message}"
        puts "url was #{url}"
        return
      end

      if WowArmory::Item.check_upgradable(id)
        upgradelevels = [0,1,2]
      else
        upgradelevels = [0]
      end

      upgradelevels.each do |upgrade_level|
        options = {
          :remote_id => id,
          :bonus_trees => bonuses.sort,
          :item_level => json_data["itemLevel"]+5*upgrade_level
        }
        
        db_item_with_bonus = Item.find_or_initialize_by options
        if db_item_with_bonus.properties.nil?
          begin
            item = WowArmory::Item.new(id, source, nil, context, options[:bonus_trees], nil)
          rescue WowArmory::MissingDocument => e
            # try without context
            item = WowArmory::Item.new(id, source, nil, '', options[:bonus_trees], nil)
          end
          db_item_with_bonus.properties = item.as_json.with_indifferent_access
          if (upgrade_level != 0)
            item_stats = WowArmory::Itemstats.new(db_item_with_bonus.properties, upgrade_level)
            db_item_with_bonus.properties = db_item_with_bonus.properties.merge(item_stats.as_json.with_indifferent_access)
          end
          db_item_with_bonus.equip_location = db_item_with_bonus.properties['equip_location']
          db_item_with_bonus.is_gem = !db_item_with_bonus.properties['gem_slot'].blank?
          if db_item_with_bonus.new_record?
            db_item_with_bonus.save
          end
        end
      end
    rescue WowArmory::MissingDocument => e
      Rails.logger.debug id
      Rails.logger.debug e.message
      return
    end
  end

  def self.get_ids_from_wowhead(url)
    doc = open(url, 'User-Agent' => 'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:27.0) Gecko/20100101 Firefox/27.0').read
    ids = doc.scan(/_\[(\d+)\]=\{.*?\}/).flatten.map &:to_i
    ids
  end

  def self.reindex!
    self.all.each { |i| i.save }
  end
end
