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
    # do not import mop trinkets here, so remove them
    item_ids -= [105029, 104780, 102301, 105278, 104531, 105527] # haromms_talisman
    item_ids -= [105082, 104833, 102302, 105331, 104584, 105580] # sigil_of_rampage
    item_ids -= [104974, 104725, 102292, 105223, 104476, 105472] # assurance_of_consequence
    item_ids -= [105114, 104865, 102311, 105363, 104616, 105612] # ticking_ebon_detonator

    # add the 6.1 alchemy trinkets since wowhead doesn't include them in the above searches yet
    item_ids += [122601, 122602, 122603, 122604]

    pos = 0
    item_ids.each do |id|
      pos = pos + 1
      puts "item #{pos} of #{item_ids.length}" if pos % 10 == 0
      wod_import id
    end
    true
  end

  def self.populate_gems_wod(prefix = 'www', source = 'wowhead')
    gem_ids = [115809, 115811, 115812, 115813, 115814, 115815, 115803, 115804, 115805, 115806, 115807, 115808]

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

  def self.populate_gear_mop(prefix = 'www', source = 'wowhead')
    @source = source
    # suffixes = (-137..-133).to_a
    # random_item_ids = get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=3;minle=430;ub=4;cr=124;crs=0;crv=zephyr"
    # random_item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items=4?filter=na=hozen-speed"
    # random_item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items=4?filter=na=Stormcrier"
    #
    # random_item_ids += (93049..93056).to_a
    # puts "importing now #{random_item_ids.length} random items"
    # random_item_ids.each do |id|
    #   import_mop id,[nil,1,2,3,4,5,6],suffixes
    # end

    # 5.2 random enchantment items
    # suffixes = (-340..-336).to_a
    # random_item_ids = [ 94979, 95796, 96168, 96540, 96912 ]
    # puts "importing now #{random_item_ids.length} random items for 5.2"
    # random_item_ids.each do |id|
    #   import_mop id,[nil,1,2,3,4,5,6],suffixes
    # end

    # 5.3 random enchantment items
    # suffixes = (-348..-344).to_a + (-357..-353).to_a
    # random_item_ids = [ 98279, 98275, 98280, 98271, 98272, 98189, 98172, 98190 ]
    # random_item_ids += (98173..98180).to_a # tidesplitter ilvl 516
    # random_item_ids += [ 97663, 97647, 97682, 97633, 97655, 97639, 97675 ] # disowner ilvl 502
    # puts "importing now #{random_item_ids.length} random items for 5.3"
    # random_item_ids.each do |id|
    #   import_mop id,[nil,1,2,3,4,5,6],suffixes
    # end

    # 5.4 random enchantment items
    # suffixes = (-348..-344).to_a + (-357..-353).to_a # 0 sockets

    # ilvl 496
    # suffixes_05 = (-465..-461).to_a + (-474..-470).to_a # 0.5 socket cost ilvl 496
    # suffixes_15 = (-381..-377).to_a + (-390..-386).to_a # 1.5 socket cost ilvl 496
    # random_item_ids = [ 101862, 101863, 101865, 101868, 101869 ] # 0 socket items
    # random_item_ids += [ 101827, 101828, 101829 ] # neck, ring, cloak
    # random_item_ids_05 = [ 101864, 101867 ] # 1 socket items
    # random_item_ids_15 = [ 101866 ] # 2 socket items
    # puts "importing now #{random_item_ids.length+random_item_ids_05.length+random_item_ids_15.length} random items for 5.4 (ilvl 496)"
    # random_item_ids.each do |id|
    #   import_mop id,[nil,1,2,3,4,5,6],suffixes
    # end
    # random_item_ids_05.each do |id|
    #   import_mop id,[nil,1,2,3,4,5,6],suffixes_05
    # end
    # random_item_ids_15.each do |id|
    #   import_mop id,[nil,1,2,3,4,5,6],suffixes_15
    # end

    # ilvl 535
    # suffixes_05 = (-409..-405).to_a + (-418..-414).to_a # 0.5 socket cost ilvl 535
    # suffixes_15 = (-437..-433).to_a + (-446..-442).to_a # 1.5 socket cost ilvl 535
    # random_item_ids = [ 101949, 101950, 101952, 101955, 101956 ] # 0 sockets
    # random_item_ids += [ 101916, 101917, 101918 ] # neck, ring, cloak
    # random_item_ids_05 = [ 101951, 101954 ] # 1 socket items
    # random_item_ids_15 = [ 101953 ] # 2 socket items
    # puts "importing now #{random_item_ids.length+random_item_ids_05.length+random_item_ids_15.length} random items for 5.4 (ilvl 535)"
    # random_item_ids.each do |id|
    #   import_mop id,[nil,1,2,3,4,5,6],suffixes
    # end
    # random_item_ids_05.each do |id|
    #   import_mop id,[nil,1,2,3,4,5,6],suffixes_05
    # end
    # random_item_ids_15.each do |id|
    #   import_mop id,[nil,1,2,3,4,5,6],suffixes_15
    # end

    # item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=3;minle=430;maxle=500;ub=4;cr=21;crs=1;crv=0"
    # item_ids = get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=430;maxle=483;ub=4;cr=21;crs=1;crv=0"
    # item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=484;maxle=500;ub=4;cr=21;crs=1;crv=0"
    # item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=501;maxle=510;ub=4;cr=21;crs=1;crv=0"
    # item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=511;maxle=530;ub=4;cr=21;crs=1;crv=0"
    # item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=531;maxle=550;ub=4;cr=21;crs=1;crv=0"
    item_ids = get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=4;minle=540;maxle=580;ub=4;cr=21;crs=1;crv=0"

    # item_ids += [ 87057, 86132, 86791, 87574, 81265, 81267, 75274, 87495, 77534, 77530 ] # some extra_items, mostly 5.0 trinkets
    # item_ids += [ 94523, 96409, 96037, 95665] # bad juju
    # item_ids += [ 96741, 96369, 95997, 94512, 95625] # renatakis soul charm
    # item_ids += [ 96174, 94511] # missing other trinkets
    # item_ids += [ 96741, 96781] # heroic thunderforged, rune of reorigination and talisman of bloodlust still missing
    item_ids += [98148] # ilvl 600 cloak 5.3

    # 5.4
    item_ids += [98604, 98613] # 5.4 crafting items
    item_ids += [102248] # ilvl 600 legendary cloak 5.4
    item_ids += [105029, 104780, 102301, 105278, 104531, 105527] # haromms_talisman
    item_ids += [105082, 104833, 102302, 105331, 104584, 105580] # sigil_of_rampage
    item_ids += [104974, 104725, 102292, 105223, 104476, 105472] # assurance_of_consequence
    item_ids += [105114, 104865, 102311, 105363, 104616, 105612] # ticking_ebon_detonator
    item_ids += [103686, 103986] # discipline of xuen timeless isle trinkets

    # filter out not existing items and other class set items
    item_ids -= [102312] # agi dps 5 trinket is basically discipline of xuen
    item_ids -= [99322, 99326, 99327, 99328, 99329, 99419, 99420, 99421, 99422, 99423, 99163, 99164, 99165, 99166, 99170, 99180, 99181, 99182, 99183, 99184, 99589, 99599, 99600, 99610, 99622, 99623, 99624, 99632, 99633, 99664, 98978, 98981, 98999, 99000, 99001, 99022, 99041, 99042, 99043, 99044] # druid set
    item_ids -= [99382, 99383, 99384, 99385, 99386, 99392, 99393, 99394, 99395, 99396, 99140, 99141, 99142, 99143, 99144, 99145, 99146, 99154, 99155, 99156, 99555, 99556, 99565, 99606, 99607, 99643, 99644, 99653, 99654, 99655, 99050, 99051, 99063, 99064, 99065, 99071, 99072, 99073, 99074, 99075] # monk set

    # 6.0.2
    # UBRS GEAR
    item_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items?filter=qu=3;minle=550;maxle=550;maxrl=90;ub=4;cr=21;crs=1;crv=0"

    # heirlooms lvl100 edition
    item_ids += [104400, 105671, 105684] # razor
    item_ids += [104404, 105672, 105685] # cleaver

    puts "importing now #{item_ids.length} items"
    pos = 0
    item_ids.each do |id|
      pos = pos + 1
      puts "item #{pos} of #{item_ids.length}" if pos % 10 == 0
      import_mop id, [nil, 1, 2, 3, 4, 5, 6]
    end
    true
  end

  def self.populate_gems_mop(prefix = 'www', source = 'wowhead')
    gem_ids = get_ids_from_wowhead "http://#{prefix}.wowhead.com/items=3?filter=qu=2:3;minle=86;maxle=90"
    gem_ids += get_ids_from_wowhead "http://#{prefix}.wowhead.com/items=3?filter=qu=2:3:4;minle=86;maxle=90;cr=99;crs=11;crv=0"

    gem_ids += [89873] # 500agi gem
    gem_ids += [95346] # legendary meta gem

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

  def self.import_mop(id, upgrade_levels = [nil, 1, 2, 3, 4, 5, 6], random_suffixes = nil, source = @source, override_ilvl = nil)
    source = 'wowhead'
    # options need to be upgrade_level = [nil,1,2,3,4,5,6]
    # same for random_suffix
    random_suffixes = [nil] if random_suffixes.nil?
    item = nil
    begin
      random_suffixes.each do |suffix|
        upgrade_levels.each do |level|
          options = {}
          options[:remote_id] = id
          options[:upgrade_level] = level
          options[:random_suffix] = suffix unless suffix.nil?
          db_item = Item.find_or_initialize_by options
          if db_item.properties.nil?
            if item.nil?
              item = WowArmory::Item.new(id, source, nil, '', [], override_ilvl)
            end
            db_item.properties = item.as_json.with_indifferent_access
            item_stats = WowArmory::Itemstats.new(db_item.properties, suffix, level)
            db_item.properties = db_item.properties.merge(item_stats.as_json.with_indifferent_access)
            db_item.equip_location = db_item.properties['equip_location']
            db_item.is_gem = !db_item.properties['gem_slot'].blank?
            if db_item.new_record?
              db_item.save
            end
          end
        end
      end
    rescue WowArmory::MissingDocument => e
      puts id
      puts e.message
    rescue StandardError => e
      puts id
      puts e.message
    end
  end

  SKIP_EXTRA_SOCKETS = [3, 497, 523, 563, 564, 565, 572] # extra sockets

  SKIP_RANDOM_SUFFIXES = [3, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 45,
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

  SKIP_TERTIARY_STATS = [40, 41, 42, 43]

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
      # if bonus is in skip list filter out
      return if bonuses.nil?
      bonuses.clone.each do |bonus|
        bonuses.delete(bonus) if SKIP_EXTRA_SOCKETS.include? bonus # extra sockets
        bonuses.delete(bonus) if SKIP_TERTIARY_STATS.include? bonus # avoidance, leech, speed, indestructible
        bonuses.delete(bonus) if SKIP_RANDOM_SUFFIXES.include? bonus # random suffixes
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
        context_data['bonusSummary']['defaultBonusLists'].delete(defaultBonusListsId) if SKIP_EXTRA_SOCKETS.include? defaultBonusListsId # extra sockets
        context_data['bonusSummary']['defaultBonusLists'].delete(defaultBonusListsId) if SKIP_TERTIARY_STATS.include? defaultBonusListsId # avoidance, leech, speed, indestructible
        context_data['bonusSummary']['defaultBonusLists'].delete(defaultBonusListsId) if SKIP_RANDOM_SUFFIXES.include? defaultBonusListsId # random suffixes
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
            next if SKIP_EXTRA_SOCKETS.include? bonus # avoidance, leech, speed, indestructible
            next if SKIP_RANDOM_SUFFIXES.include? bonus # random suffix
            next if SKIP_TERTIARY_STATS.include? bonus # tertiary stats
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
          :bonus_trees => bonuses
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
