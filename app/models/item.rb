class Item
  include Mongoid::Document
  include Mongoid::Timestamps

  @item_bonus_map = nil

  field :remote_id, :type => Integer, :index => true
  field :bonus_tree, :type => Integer
  field :equip_location, :type => Integer, :index => true
  field :item_level, :type => Integer
  field :properties, :type => Hash
  field :info, :type => Hash
  field :stats, :type => HashWithIndifferentAccess
  field :has_stats, :type => Boolean
  field :requires, :type => Hash
  field :is_gem, :type => Boolean, :index => true
  field :is_glyph, :type => Boolean, :index => true

  referenced_in :loadout

  attr_accessor :item_name_override

  validates_presence_of :remote_id
  validates_presence_of :properties

  before_validation :update_from_armory_if_necessary
  before_save :write_stats
  EXCLUDE_KEYS = [:stamina, :resilience, :strength, :spirit, :intellect, :dodge, :parry, :health_regen, :bonus_armor]

  def update_from_armory_if_necessary
    return if remote_id == 0
    if self.properties.nil?
      Rails.logger.debug "Loading item #{remote_id}"
      item = WowArmory::Item.new(remote_id, item_name_override)
      # return false if item.stats.empty?
      self.properties = item.as_json.with_indifferent_access
      item_stats = WowArmory::Itemstats.new(self.properties)
      self.properties = self.properties.merge(item_stats.as_json.with_indifferent_access)
      self.equip_location = self.properties['equip_location']
      self.is_gem = !self.properties['gem_slot'].blank?
    end
    true
  end

  def icon(size = 51)
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
        :id => remote_id,
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

    # remove duplicates
    item_ids = item_ids.uniq

    pos = 0
    item_ids.each do |id|
      pos = pos + 1
      puts "item #{pos} of #{item_ids.length}" if pos % 10 == 0
      wod_import id
    end

    # import all stages from skull of war by default
    wod_special_import 112318, 'trade-skill', [525]
    wod_special_import 112318, 'trade-skill', [526]
    wod_special_import 112318, 'trade-skill', [527]
    wod_special_import 112318, 'trade-skill', [593]
    wod_special_import 112318, 'trade-skill', [617]
    wod_special_import 112318, 'trade-skill', [618]

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

  BLACKLIST_EXTRA_SOCKETS = [3, 497, 523, 563, 564, 565, 572] # extra sockets

  BLACKLIST_RANDOM_SUFFIXES = [3, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 45,
                           46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68,
                           69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91,
                           92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111,
                           112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129,
                           130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147,
                           148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165,
                           166, 167, 168, 169, 170, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187,
                           188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205,
                           206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223,
                           224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241,
                           242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 259,
                           260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 274, 275, 276, 277,
                           278, 279, 280, 281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 291, 292, 293, 294, 295,
                           296, 297, 298, 299, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312, 313,
                           314, 315, 316, 317, 318, 319, 320, 321, 322, 323, 324, 325, 326, 327, 328, 329, 330, 331,
                           332, 333, 334, 335, 336, 337, 338, 339, 340, 341, 342, 343, 344, 345, 346, 347, 348, 349,
                           350, 351, 352, 353, 354, 355, 356, 357, 358, 359, 360, 361, 362, 363, 364, 365, 366, 367,
                           368, 369, 370, 371, 372, 373, 374, 375, 376, 377, 378, 379, 380, 381, 382, 383, 384, 385,
                           386, 387, 388, 389, 390, 391, 392, 393, 394, 395, 396, 397, 398, 399, 400, 401, 402, 403,
                           404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 419, 420, 421,
                           422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432, 433, 434, 435, 436, 437, 438, 439,
                           440, 441, 442, 443, 444, 445, 446, 447, 459, 460, 461, 462, 463, 464, 465, 466, 467, 468,
                           469, 470, 471, 472, 473, 474, 475, 476, 477, 478, 479, 480, 481, 482, 483, 484, 485, 486,
                           487, 488, 489, 490, 491, 492, 497]

  BLACKLIST_TERTIARY_STATS = [40, 41, 42, 43]

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
      # if bonus is in blacklist filter out
      return if bonuses.nil?
      bonuses.clone.each do |bonus|
        bonuses.delete(bonus) if BLACKLIST_EXTRA_SOCKETS.include? bonus # extra sockets
        bonuses.delete(bonus) if BLACKLIST_TERTIARY_STATS.include? bonus # avoidance, leech, speed, indestructible
        bonuses.delete(bonus) if BLACKLIST_RANDOM_SUFFIXES.include? bonus # random suffixes
      end
      return if bonuses.empty?
      # make a special import with the given and possible missing bonus id data from armory
      puts "special import #{id} #{context} #{bonuses.inspect}"
      self.wod_special_import id, context, bonuses
      return
    end

    begin
      json_data = WowArmory::Document.fetch 'us', '/wow/item/%d' % id, {}, :json
    rescue WowArmory::MissingDocument => e
      puts id
      puts e.message
      return
    end
    json_data['availableContexts'].each do |context|
      if context == ''
        context_data = json_data
      else
        context_data = WowArmory::Document.fetch 'us', '/wow/item/%d/%s' % [id, context], {}, :json
      end
      context_data['bonusSummary']['defaultBonusLists'].clone.each do |defaultBonusListsId|
        context_data['bonusSummary']['defaultBonusLists'].delete(defaultBonusListsId) if BLACKLIST_EXTRA_SOCKETS.include? defaultBonusListsId # extra sockets
        context_data['bonusSummary']['defaultBonusLists'].delete(defaultBonusListsId) if BLACKLIST_TERTIARY_STATS.include? defaultBonusListsId # avoidance, leech, speed, indestructible
        context_data['bonusSummary']['defaultBonusLists'].delete(defaultBonusListsId) if BLACKLIST_RANDOM_SUFFIXES.include? defaultBonusListsId # random suffixes
      end
      if context_data['bonusSummary']['defaultBonusLists'].empty?
        context_data['bonusSummary']['defaultBonusLists'] = [0]
      end
      context_data['bonusSummary']['defaultBonusLists'].each do |defaultBonus|
        options = {
            :remote_id => id,
            :bonus_trees => [defaultBonus]
        }
        db_item = Item.find_or_initialize_by options
        if db_item.properties.nil?
          item = WowArmory::Item.new(id, source, nil, context, options[:bonus_trees], nil, false)
          db_item.properties = item.as_json.with_indifferent_access
          db_item.equip_location = db_item.properties['equip_location']
          db_item.is_gem = !db_item.properties['gem_slot'].blank?
          if db_item.new_record?
            db_item.save
          end
          # if available we need to import warforged too
          # the other stuff like extra socket or tertiary stats are added in the UI dynamically
          context_data['bonusSummary']['chanceBonusLists'].each do |bonus|
            next if BLACKLIST_EXTRA_SOCKETS.include? bonus # avoidance, leech, speed, indestructible
            next if BLACKLIST_RANDOM_SUFFIXES.include? bonus # random suffix
            next if BLACKLIST_TERTIARY_STATS.include? bonus # tertiary stats
            puts bonus
            options = {
                :remote_id => id,
                :bonus_trees => [defaultBonus] + [bonus]
            }
            db_item_with_bonus = Item.find_or_initialize_by options
            if db_item_with_bonus.properties.nil?
              item = WowArmory::Item.new(id, source, nil, context, options[:bonus_trees], nil, false)
              db_item_with_bonus.properties = item.as_json.with_indifferent_access
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

  def self.wod_special_import(id, context, bonuses)
    begin
      source = 'wowapi'
      options = {
          :remote_id => id,
          :bonus_trees => bonuses.sort
      }
      db_item_with_bonus = Item.find_or_initialize_by options
      if db_item_with_bonus.properties.nil?
        begin
          item = WowArmory::Item.new(id, source, nil, context, options[:bonus_trees], nil, false)
        rescue WowArmory::MissingDocument => e
          # try without context
          item = WowArmory::Item.new(id, source, nil, '', options[:bonus_trees], nil, false)
        end
        db_item_with_bonus.properties = item.as_json.with_indifferent_access
        db_item_with_bonus.equip_location = db_item_with_bonus.properties['equip_location']
        db_item_with_bonus.is_gem = !db_item_with_bonus.properties['gem_slot'].blank?
        if db_item_with_bonus.new_record?
          db_item_with_bonus.save
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
