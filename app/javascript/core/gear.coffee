class ShadowcraftGear
  MAX_ENGINEERING_GEMS = 1
  MAX_HYDRAULIC_GEMS = 1
  JC_ONLY_GEMS = ["Dragon's Eye", "Chimera's Eye", "Serpent's Eye"]
  CHAPTER_2_ACHIEVEMENTS = [7534, 8008]
  LEGENDARY_META_GEM_QUESTS = [32595]

  FACETS = {
    ITEM: 1
    GEMS: 2
    ENCHANT: 4
    ALL: 255
  }
  @FACETS = FACETS

  SLOT_ORDER = ["0", "1", "2", "14", "4", "8", "9", "5", "6", "7", "10", "11", "12", "13", "15", "16"]
  SLOT_DISPLAY_ORDER = [["0", "1", "2", "14", "4", "8", "15", "16"], ["9", "5", "6", "7", "10", "11", "12", "13"]]
  PROC_ENCHANTS =
    4099: "landslide"
    4083: "hurricane"
    4441: "windsong"
    4443: "elemental_force"
    4444: "dancing_steel"
    5125: "dancing_steel"
    5330: "mark_of_the_thunderlord"
    5331: "mark_of_the_shattered_hand"
    5334: "mark_of_the_frostwolf"
    5337: "mark_of_warsong"
    5384: "mark_of_the_bleeding_hollow"


  @CHAOTIC_METAGEMS = [52291, 34220, 41285, 68778, 68780, 41398, 32409, 68779, 76884, 76885, 76886]
  @LEGENDARY_META_GEM = 95346
  @FURY_OF_XUEN_CLOAK = 102248

  Sets =
    T14:
      ids: [85299, 85300, 85301, 85302, 85303, 86639, 86640, 86641, 86642, 86643, 87124, 87125, 87126, 87127, 87128]
      bonuses: {4: "rogue_t14_4pc", 2: "rogue_t14_2pc"}
    T15:
      ids: [95935, 95306, 95307, 95305, 95939, 96683, 95938, 96682, 95937, 96681, 95308, 95936, 95309, 96680, 96679]
      bonuses: {4: "rogue_t15_4pc", 2: "rogue_t15_2pc"}
    T16:
      ids: [99006, 99007, 99008, 99009, 99010, 99112, 99113, 99114, 99115, 99116, 99348, 99349, 99350, 99355, 99356, 99629, 99630, 99631, 99634, 99635]
      bonuses: {4: "rogue_t16_4pc", 2: "rogue_t16_2pc"}
    T17:
      ids: [115570, 115571, 115572, 115573, 115574]
      bonuses: {4: "rogue_t17_4pc", 2: "rogue_t17_2pc"}
    T17_LFR:
      ids: [120384, 120383, 120382, 120381, 120380, 120379]
      bonuses: {4: "rogue_t17_4pc_lfr"}
    T18:
      ids: [124248, 124257, 124263, 124269, 124274]
      bonuses: {4: "rogue_t18_4pc", 2: "rogue_t18_2pc"}
    T18_LFR:
      ids: [128130, 128121, 128125, 128054, 128131, 128137]
      bonuses: {4: "rogue_t18_4pc_lfr"}

  Weights =
    attack_power: 1
    agility: 1.1
    crit: 0.87
    haste: 1.44
    mastery: 1.15
    multistrike: 1.12
    versatility: 1.2
    strength: 1.05
    pvp_power: 0

  getWeights: ->
    Weights

  SLOT_INVTYPES =
      0: 1 # head
      1: 2 # neck
      2: 3 # shoulder
      14: 16 # back
      4: 5 # chest
      8: 9 # wrist
      9: 10 # gloves
      5: 6 # belt
      6: 7 # legs
      7: 8 # boots
      10: 11 # ring1
      11: 11 # ring2
      12: 12 # trinket1
      13: 12 # trinket2
      15: "mainhand" # mainhand
      16: "offhand" # offhand

  EP_PRE_REGEM = null
  EP_TOTAL = null
  $slots = null
  $altslots = null
  $popup = null

  getRandPropRow = (slotIndex) ->
    slotIndex = parseInt(slotIndex, 10)
    switch slotIndex
      when 0, 4, 6
        return 0
      when 2, 5, 7, 9, 12, 13
        return 1
      when 1, 8, 10, 11, 14
        return 2
      when 15, 16
        return 3
      else
        return 2

  statOffset = (gear, facet) ->
    offsets = {}
    if gear
      Shadowcraft.Gear.sumSlot(gear, offsets, facet)
    return offsets

  sumItem = (s, i, key) ->
    key ||= "stats"
    for stat of i[key]
      s[stat] ||= 0
      s[stat] += i[key][stat]
    null

  get_ep = (item, key, slot, ignore) ->

    stats = {}
    sumItem(stats, item, key)

    total = 0
    for stat, value of stats
      weight = getStatWeight(stat, value, ignore) || 0
      total += weight

    delete stats
    c = Shadowcraft.lastCalculation
    if c and key != "socketbonus"
      if item.dps
        if slot == 15
          total += (item.dps * c.mh_ep.mh_dps) + c.mh_speed_ep["mh_" + item.speed]
          if c.mh_type_ep?
            if item.subclass == 15
              total += c.mh_type_ep["mh_type_dagger"]
            else
              total += c.mh_type_ep["mh_type_one-hander"]
        else if slot == 16
          total += (item.dps * c.oh_ep.oh_dps) + c.oh_speed_ep["oh_" + item.speed]
          if c.oh_type_ep?
            if item.subclass == 15
              total += c.oh_type_ep["oh_type_dagger"]
            else
              total += c.oh_type_ep["oh_type_one-hander"]
      else if PROC_ENCHANTS[item.id]
        switch slot
          when 14
            pre = ""
          when 15
            pre = "mh_"
          when 16
            pre = "oh_"
        enchant = PROC_ENCHANTS[item.id]
        if !pre and enchant
          total += c["other_ep"][enchant]
        else if pre and enchant
          total += c[pre + "ep"][pre + enchant]

      item_level = item.ilvl
      if c.trinket_map[item.original_id]
        proc_name = c.trinket_map[item.original_id]
        if c.proc_ep[proc_name] and c.proc_ep[proc_name][item_level]
          total += c.proc_ep[proc_name][item_level]
        else
          console.warn "error in trinket_ranking", item_level, item.name

    total

  sumSlot: (gear, out, facets) ->
    return unless gear?.item_id?
    facets ||= FACETS.ALL

    Gems = Shadowcraft.ServerData.GEM_LOOKUP
    EnchantLookup = Shadowcraft.ServerData.ENCHANT_LOOKUP

    item = getItem(gear.original_id, gear.item_level, gear.suffix)
    return unless item?

    if (facets & FACETS.ITEM) == FACETS.ITEM
      sumItem(out, item)

    if (facets & FACETS.GEMS) == FACETS.GEMS
      matchesAllSockets = item.sockets and item.sockets.length > 0
      for socketIndex, socket of item.sockets
          gid = gear["g" + socketIndex]
          if gid and gid > 0
            gem = Gems[gid]
            sumItem(out, gem) if(gem)
          matchesAllSockets = false if !gem or !gem[socket]
      
      if matchesAllSockets
        sumItem(out, item, "socketbonus")

    if (facets & FACETS.ENCHANT) == FACETS.ENCHANT
      enchant_id = gear.enchant
      if enchant_id and enchant_id > 0
        enchant = EnchantLookup[enchant_id]
        sumItem(out, enchant) if enchant

  sumStats: (facets) ->
    stats = {}
    data = Shadowcraft.Data

    for si, i in SLOT_ORDER
      Shadowcraft.Gear.sumSlot(data.gear[si], stats, facets)

    @statSum = stats
    return stats

  getStat: (stat) ->
    this.sumStats() if !@statSum
    (@statSum[stat] || 0)

  # Stat to get the real weight for, the amount of the stat, and a hash of {stat: amount} to ignore (like if swapping out a enchant or whatnot; nil the existing enchant for calcs)
  getStatWeight = (stat, num, ignore, ignoreAll) ->
    exist = 0
    unless ignoreAll
      exist = Shadowcraft.Gear.getStat(stat)
      if ignore and ignore[stat]
        exist -= ignore[stat]


    neg = if num < 0 then -1 else 1
    num = Math.abs(num)

    return (Weights[stat] || 0) * num * neg

  __epSort = (a, b) ->
    b.__ep - a.__ep

  epSort = (list, skipSort, slot) ->
    for item in list
      item.__ep = get_ep(item, false, slot) if item
      item.__ep = 0 if isNaN(item.__ep)
    list.sort(__epSort) unless skipSort

  needsDagger = ->
    Shadowcraft.Data.activeSpec == "a"
  
  setBonusEP = (set, count) ->
    return 0 unless c = Shadowcraft.lastCalculation
  
    total = 0
    for p, bonus_name of set.bonuses
      if count == (p-1)
        total += c["other_ep"][bonus_name]

    return total

  getEquippedSetCount = (setIds, ignoreSlotIndex) ->
    count = 0
    for slot in SLOT_ORDER
      continue if SLOT_INVTYPES[slot] == ignoreSlotIndex
      gear = Shadowcraft.Data.gear[slot]
      _item_id = gear.item_id
      if _item_id in setIds
        count++
    return count

  isProfessionalGem = (gem, profession) ->
    return false unless gem?
    gem.requires?.profession? and gem.requires.profession == profession

  getEquippedGemCount = (gem, pendingChanges, ignoreSlotIndex) ->
    count = 0
    for slot in SLOT_ORDER
      continue if parseInt(slot, 10) == ignoreSlotIndex
      gear = Shadowcraft.Data.gear[slot]
      if gem.id == gear.g0 or gem.id == gear.g1 or gem.id == gear.g2
        count++
    if pendingChanges?
      for g in pendingChanges
        count++ if g == gem.id
    return count

  getGemTypeCount = (gemType, pendingChanges, ignoreSlotIndex) ->
    count = 0
    Gems = Shadowcraft.ServerData.GEM_LOOKUP

    for slot in SLOT_ORDER
      continue if parseInt(slot, 10) == ignoreSlotIndex
      gear = Shadowcraft.Data.gear[slot]
      for i in [0..2]
        gem = gear["g" + i]? and Gems[gear["g" + i]]
        continue unless gem
        if gem.slot == gemType
          count++

    if pendingChanges?
      for g in pendingChanges
        gem = Gems[g]
        count++ if gem.slot == gemType
    return count

  canUseGem = (gem, gemType, pendingChanges, ignoreSlotIndex) ->
    if gem.requires?.profession?
      return false if isProfessionalGem(gem, 'jewelcrafting')

    return false if not gem[gemType]
    return false if gem.slot == "Cogwheel" and getEquippedGemCount(gem, pendingChanges, ignoreSlotIndex) >= MAX_ENGINEERING_GEMS
    return false if gem.slot == "Hydraulic" and getEquippedGemCount(gem, pendingChanges, ignoreSlotIndex) >= MAX_HYDRAULIC_GEMS
    return false if (gemType == "Meta" or gemType == "Cogwheel" or gemType == "Hydraulic") and gem.slot != gemType
    return false if (gem.slot == "Meta" or gem.slot == "Cogwheel" or gem.slot == "Hydraulic") and gem.slot != gemType
    true

  addAchievementBonuses = (item) ->
    item.sockets ||= []
    if item.equip_location in ["mainhand","offhand"]
      chapter2 = hasAchievement(CHAPTER_2_ACHIEVEMENTS)
      last = item.sockets[item.sockets.length - 1]
      if canUsePrismaticSocket(item) and last != "Prismatic" and chapter2
        item.sockets.push "Prismatic"
      else if last != "Prismatic" and last == "Hydraulic" and chapter2
        item.sockets.push "Prismatic"
      else if !chapter2 and last == "Prismatic"
        item.sockets.pop()

  hasAchievement = (achievements) ->
    return false unless Shadowcraft.Data.achievements
    for id in Shadowcraft.Data.achievements
      if id in achievements
        return true
    return false

  hasQuest = (quests) ->
    return false unless Shadowcraft.Data.quests
    for id in Shadowcraft.Data.quests
      if id in quests
        return true
    return false

  canUseLegendaryMetaGem = (item) ->
    return false if not hasQuest(LEGENDARY_META_GEM_QUESTS)
    # TODO identify ToT items with a better method
    return false if item.ilvl < 502
    if item.ilvl >= 502 and item.ilvl < 522
      if item.name.indexOf("Tidesplitter Hood") >= 0
        return true
      else if item.tag == "Raid Finder"
        return true
      return false
    true

  canUsePrismaticSocket = (item) ->
    return false if item.equip_location not in ["mainhand","offhand"]
    return false if not hasAchievement(CHAPTER_2_ACHIEVEMENTS)
    last = item.sockets.length - 1
    return true if last > -1 and item.sockets[last] == "Hydraulic"
    return true if last > 0 and item.sockets[last] == "Prismatic" and item.sockets[last-1] == "Hydraulic"
    return false if item.ilvl < 502 or item.ilvl > 549
    return false if item.ilvl >= 528 and (item.tag.indexOf("Raid Finder") >= 0 or item.tag.indexOf("Flexible") >= 0)
    return false if item.original_id == 87012 or item.original_id == 87032 or item.tag.indexOf("Season") >= 0 or item.name.indexOf("Immaculate") >= 0
    return true

  # Check if the gems have equal stats to pretend that optimize gems 
  # not change gems to stat equal gems
  equalGemStats = (from_gem,to_gem) ->
    for stat of from_gem["stats"]
      if !to_gem["stats"][stat]? or from_gem["stats"][stat] != to_gem["stats"][stat]
        return false
    return true

  # Assumes gem_list is already sorted preferred order.
  getGemmingRecommendation = (gem_list, item, returnFull, ignoreSlotIndex, offset) ->
    if !item.sockets or item.sockets.length == 0
      if returnFull
        return {ep: 0, gems: []}
      else
        return 0

    straightGemEP = 0
    if returnFull
      sGems = []
    for gemType in item.sockets
      broke = false
      for gem in gem_list
        continue unless canUseGem gem, gemType, sGems, ignoreSlotIndex
        continue if gem.id == ShadowcraftGear.LEGENDARY_META_GEM and not canUseLegendaryMetaGem(item)
        continue if gem.name.indexOf('Taladite') >= 0 and item? and item.quality == 7 and item.ilvl <= 620 # do not recommend wod gems to heirlooms
        continue if gem.name.indexOf('Taladite') >= 0 and item? and item.id == 102248 and item.ilvl <= 616 # do not recommend wod gems for legendary cloak
        straightGemEP += get_ep(gem, false, null, offset)
        sGems.push gem.id if returnFull
        broke = true
        break
      sGems.push null if !broke and returnFull

    epValue = straightGemEP
    gems = sGems
    # if all sockets are filled with gems the bonus always applies
    # and returnFull is true
    bonus = returnFull

    if returnFull
      return {ep: epValue, takeBonus: bonus, gems: gems}
    else
      return epValue

  lockAll: () ->
    Shadowcraft.Console.log("Locking all items")
    for slot in SLOT_ORDER
      gear = Shadowcraft.Data.gear[slot]
      item = getItem(gear.original_id, gear.item_level, gear.suffix)
      gear.locked = true
    Shadowcraft.Gear.updateDisplay()

  unlockAll: () ->
    Shadowcraft.Console.log("Unlocking all items")
    for slot in SLOT_ORDER
      gear = Shadowcraft.Data.gear[slot]
      item = getItem(gear.original_id, gear.item_level, gear.suffix)
      gear.locked = false
    Shadowcraft.Gear.updateDisplay()

  optimizeGems: (depth) ->
    Gems = Shadowcraft.ServerData.GEM_LOOKUP
    data = Shadowcraft.Data

    depth ||= 0
    if depth == 0
      Shadowcraft.Console.purgeOld()
      EP_PRE_REGEM = @getEPTotal()
      Shadowcraft.Console.log "Beginning auto-regem...", "gold underline"
    madeChanges = false
    gem_list = getGemRecommendationList()
    for slotIndex in SLOT_ORDER
      slotIndex = parseInt(slotIndex, 10)
      gear = data.gear[slotIndex]
      continue unless gear
      continue if gear.locked

      item = getItem(gear.original_id, gear.item_level, gear.suffix)
      gem_offset = statOffset(gear, FACETS.GEMS)

      if item
        rec = getGemmingRecommendation(gem_list, item, true, slotIndex, gem_offset)
        for gem, gemIndex in rec.gems
          from_gem = Gems[gear["g#{gemIndex}"]]
          to_gem = Gems[gem]
          continue unless to_gem?
          if gear["g#{gemIndex}"] != gem
            if from_gem && to_gem
              continue if from_gem.name == to_gem.name
              continue if equalGemStats(from_gem, to_gem)
              Shadowcraft.Console.log "Regemming #{item.name} socket #{gemIndex+1} from #{from_gem.name} to #{to_gem.name}"
            else
              Shadowcraft.Console.log "Regemming #{item.name} socket #{gemIndex+1} to #{to_gem.name}"

            gear["g" + gemIndex] = gem
            madeChanges = true

    if !madeChanges or depth >= 10
      @app.update()
      this.updateDisplay()
      Shadowcraft.Console.log "Finished automatic regemming: &Delta; #{Math.floor(@getEPTotal() - EP_PRE_REGEM)} EP", "gold"
    else
      this.optimizeGems depth + 1

  # Assumes enchant_list is already sorted preferred order.
  getEnchantRecommendation = (enchant_list, item) ->

    for enchant in enchant_list
      # do not recommend bloody dancing steel
      continue if enchant.id == 5125
      continue if enchant.id == 4914 # do not recommend inscription shoulder enchant
      # do not consider enchant if item level is higher than allowed maximum
      continue if enchant.requires?.max_item_level? and enchant.requires?.max_item_level < getBaseItemLevel(item)
      return enchant.id
    return false

  getApplicableEnchants = (slotIndex, item, enchant_offset) ->
    enchant_list = Shadowcraft.ServerData.ENCHANT_SLOTS[SLOT_INVTYPES[slotIndex]]
    unless enchant_list?
      return []

    enchants = []
    for enchant in enchant_list
      # do not show enchant if item level is higher than allowed maximum
      continue if enchant.requires?.max_item_level? and enchant.requires?.max_item_level < getBaseItemLevel(item)
      enchant.__ep = get_ep(enchant, null, slotIndex, enchant_offset)
      enchant.__ep = 0 if isNaN enchant.__ep
      enchants.push(enchant)
    enchants.sort(__epSort)
    return enchants

  getApplicableEnchants: (slotIndex, item, enchant_offset) ->
    return getApplicableEnchants(slotIndex, item, enchant_offset)

  optimizeEnchants: (depth) ->
    Enchants = Shadowcraft.ServerData.ENCHANT_LOOKUP
    data = Shadowcraft.Data

    depth ||= 0
    if depth == 0
      Shadowcraft.Console.purgeOld()
      EP_PRE_REGEM = @getEPTotal()
      Shadowcraft.Console.log "Beginning auto-enchant...", "gold underline"
    madeChanges = false
    for slotIndex in SLOT_ORDER
      slotIndex = parseInt(slotIndex, 10)

      gear = data.gear[slotIndex]
      continue unless gear
      continue if gear.locked

      item = getItem(gear.original_id, gear.item_level, gear.suffix)
      continue unless item
      enchant_offset = statOffset(gear, FACETS.ENCHANT)

      enchants = getApplicableEnchants(slotIndex, item, enchant_offset)

      if item
        enchantId = getEnchantRecommendation(enchants, item)
        if enchantId
          from_enchant = Enchants[gear.enchant]
          to_enchant = Enchants[enchantId]
          if from_enchant && to_enchant
            continue if from_enchant.id == to_enchant.id
            Shadowcraft.Console.log "Change enchant of #{item.name} from #{from_enchant.name} to #{to_enchant.name}"
          else
            Shadowcraft.Console.log "Enchant #{item.name} with #{to_enchant.name}"
          gear.enchant = enchantId
          madeChanges = true

    if !madeChanges or depth >= 10
      @app.update()
      this.updateDisplay()
      Shadowcraft.Console.log "Finished automatic enchanting: &Delta; #{Math.floor(@getEPTotal() - EP_PRE_REGEM)} EP", "gold"
    else
      this.optimizeEnchants depth + 1

  getBestNormalGem = ->
    Gems = Shadowcraft.ServerData.GEMS
    copy = $.extend(true, [], Gems)
    list = []
    for gem in copy
      continue if gem.requires? or gem.requires?.profession?
      gem.__color_ep = gem.__color_ep || get_ep(gem)
      if (gem["Red"] or gem["Yellow"] or gem["Blue"]) and gem.__color_ep and gem.__color_ep > 1
        list.push gem

    list.sort (a, b) ->
      b.__color_ep - a.__color_ep
    list[0]

  # Returns an EP-sorted list of gems with the twist that the
  # JC-only gems are sorted at the same EP-value as regular gems.
  # This prevents the automatic picking algorithm from choosing
  # JC-only gems over the slot bonus.
  getGemRecommendationList = ->
    Gems = Shadowcraft.ServerData.GEMS
    copy = $.extend(true, [], Gems)
    list = []
    use_epic_gems = Shadowcraft.Data.options.general.epic_gems == 1
    for gem in copy
      continue if gem.quality == 4 and gem.requires == undefined and not use_epic_gems
      gem.normal_ep = get_ep(gem, false, null)
      if gem.normal_ep and gem.normal_ep > 1
        list.push gem

    list.sort (a, b) ->
      b.normal_ep - a.normal_ep
    list

  setGems: (_gems) ->
    Shadowcraft.Console.purgeOld()
    model = Shadowcraft.Data
    for id, gems of _gems
      gear = null
      [id, s] = id.split "-"
      id = parseInt(id, 10)
      for slot in SLOT_ORDER
        g = model.gear[slot]
        if g.item_id == id and slot == s
          gear = g
          break
      if gear
        for gem, i in gems
          continue if gem == 0
          gear["g" + i] = gem
    Shadowcraft.update()
    Shadowcraft.Gear.updateDisplay()

  clearBonuses = ->
    console.log 'clear'
    return

  applyBonuses: ->
    Shadowcraft.Console.purgeOld()
    data = Shadowcraft.Data
    slot = $.data(document.body, "selecting-slot")
    gear = data.gear[slot]
    return unless gear
    item = getItem(gear.item_id, gear.item_level, gear.suffix)

    currentBonuses = []
    for bonusIndex in [0..9]
      currentBonuses.push gear["b" + bonusIndex] if gear["b" + bonusIndex]?

    checkedBonuses = []
    uncheckedBonuses = []
    $("#bonuses input:checkbox").each ->
      val = parseInt($(this).val(), 10)
      if $(this).is(':checked')
        checkedBonuses.push val
      else
        uncheckedBonuses.push val

    $("#bonuses select option").each ->
      val = parseInt($(this).val(), 10)
      if $(this).is(':selected')
        checkedBonuses.push val
      else
        uncheckedBonuses.push val

    union = _.union(currentBonuses, checkedBonuses)
    newBonuses = _.difference(union, uncheckedBonuses)

    # remove all from old bonuses
    for bonus in currentBonuses
      if bonus in uncheckedBonuses
        applyBonusToItem(item, bonus, slot, false)

    # apply new bonuses
    for bonusIndex in [0..9]
      gear["b" + bonusIndex] = newBonuses[bonusIndex]

    $("#bonuses").removeClass("visible")
    Shadowcraft.update()
    Shadowcraft.Gear.updateDisplay()

  applyBonusToItem = (item, bonusId, slot, apply = true) ->
    for bonus_entry in Shadowcraft.ServerData.ITEM_BONUSES[bonusId]
      switch bonus_entry.type
        when 6 # cool extra sockets
          if apply
            last = item.sockets[item.sockets.length - 1]
            item.sockets.push "Prismatic"
          else
            item.sockets.pop()
        when 5 # item name suffix
          if apply
            item.name_suffix = bonus_entry.val1
          else
            item.name_suffix = ""
        when 2 # awesome extra stats
          value = Math.round(bonus_entry.val2 / 10000 * Shadowcraft.ServerData.RAND_PROP_POINTS[item.ilvl][1 + getRandPropRow(slot)])
          item.stats[bonus_entry.val1] ||= 0
          if apply
            item.stats[bonus_entry.val1] = value
          else
            item.stats[bonus_entry.val1] -= value
          delete item.stats[bonus_entry.val1] if item.stats[bonus_entry.val1] == 0

  ###
  # View helpers
  ###

  updateDisplay: (skipUpdate) ->
    EnchantLookup = Shadowcraft.ServerData.ENCHANT_LOOKUP
    EnchantSlots = Shadowcraft.ServerData.ENCHANT_SLOTS
    Gems = Shadowcraft.ServerData.GEM_LOOKUP
    data = Shadowcraft.Data
    opt = {}

    for slotSet, ssi in SLOT_DISPLAY_ORDER
      buffer = ""
      for i, slotIndex in slotSet
        data.gear[i] ||= {}
        gear = data.gear[i]
        item = getItem(gear.original_id, gear.item_level, gear.suffix)
        gems = []
        bonuses = null
        enchant = EnchantLookup[gear.enchant]
        enchantable = null
        reforge = null
        reforgable = null
        upgradable = null
        bonusable = null
        if item
          addAchievementBonuses(item)
          enchantable = EnchantSlots[item.equip_location]? && getApplicableEnchants(i, item).length > 0

          bonus_keys = _.keys(Shadowcraft.ServerData.ITEM_BONUSES)
          bonuses_equipped = []
          if item.sockets.length > 0
            for socketIndex in [item.sockets.length-1..0]
              last = item.sockets[socketIndex]
              if last == "Prismatic"
                item.sockets.pop()
          for bonusIndex in [0..9]
            continue unless gear["b" + bonusIndex]?
            bonuses_equipped.push gear["b" + bonusIndex]
            if _.contains(bonus_keys, gear["b" + bonusIndex]+"")
                applyBonusToItem(item, gear["b" + bonusIndex], i) # here happens all the magic
          if item.chance_bonus_lists?
            for bonusId in item.chance_bonus_lists
              continue if not bonusId?
              break if bonusable
              for bonus_entry in Shadowcraft.ServerData.ITEM_BONUSES[bonusId]
                switch bonus_entry.type
                  when 6 # cool extra sockets
                    bonusable = true
                    break
                  when 2
                    bonusable = true
                    break
          allSlotsMatch = item.sockets && item.sockets.length > 0
          for socket in item.sockets
            gem = Gems[gear["g" + gems.length]]
            gems[gems.length] = {socket: socket, gem: gem}
            continue if socket == "Prismatic" # prismatic sockets don't contribute to socket bonus
            if !gem or !gem[socket]
              allSlotsMatch = false
          
          if allSlotsMatch
            bonuses = []
            for stat, amt of item.socketbonus
              bonuses[bonuses.length] = {stat: titleize(stat), amount: amt}

          if enchant and !enchant.desc
            enchant.desc = statsToDesc(enchant)

          if item.upgradable
            curr_level = "0"
            curr_level = gear.upgrade_level if gear.upgrade_level?
            max_level = getMaxUpgradeLevel(item)
            upgrade = 
              curr_level: curr_level
              max_level: max_level
        if enchant and enchant.desc == ""
          enchant.desc = enchant.name

        opt = {}
        opt.item = item
        opt.identifier = item.original_id + ":" + item.ilvl + ":" + (item.suffix || 0) if item
        opt.ttid = item.original_id if item
        opt.ttrand = if item then item.suffix else null
        opt.ttupgd = if item then item.upgrade_level else null
        opt.ttbonus = if bonuses_equipped then bonuses_equipped.join(":") else null
        opt.ep = if item then get_ep(item, null, i).toFixed(1) else 0
        opt.slot = i + ''
        opt.gems = gems
        opt.socketbonus = bonuses
        opt.reforgable = reforgable
        opt.reforge = reforge
        opt.bonusable = true # TODO
        opt.sockets = if item then item.sockets else null
        opt.enchantable = enchantable
        opt.enchant = enchant
        opt.upgradable = if item then item.upgradable else false
        opt.upgrade = upgrade
        opt.bonusable = bonusable
        if item
          opt.lock = true
          if gear.locked
            opt.lock_class = "lock_on"
          else
            opt.lock_class = "lock_off"
        buffer += Templates.itemSlot(opt)
      $slots.get(ssi).innerHTML = buffer
    this.updateStatsWindow()
    this.updateSummaryWindow()
    checkForWarnings('gear')

  whiteWhite = (v, s) ->
    s

  redWhite = (v, s) ->
    s ||= v
    c = if v < 0 then "neg" else ""
    colorSpan s, c

  greenWhite = (v, s) ->
    s ||= v
    c = if v < 0 then "" else "pos"
    colorSpan s, c

  redGreen = (v, s) ->
    s ||= v
    c = if v < 0 then "neg" else "pos"
    colorSpan s, c

  colorSpan = (s, c) ->
    "<span class='#{c}'>#{s}</span>"

  pctColor = (v, func, reverse) ->
    func ||= redGreen
    reverse ||= 1
    func v * reverse, v.toFixed(2) + "%"

  getEPTotal: ->
    this.sumStats()
    keys = _.keys(@statSum).sort()
    total = 0
    for idx, stat of keys
      weight = getStatWeight(stat, @statSum[stat], null, true)
      total += weight
    return total

  updateSummaryWindow: ->
    data = Shadowcraft.Data
    $summary = $("#summary .inner")
    a_stats = []
    if data.options.general.patch
      if data.options.general.patch == 60
        valengine = "6.2"
      else
        valengine = data.options.general.patch / 10
    else
      valengine = "6.x"
    valengine += " " + if data.options.general.pvp then "(PvP)" else "(PvE)"
    a_stats.push {
      name: "Engine"
      val: valengine
    }
    a_stats.push {
      name: "Spec"
      val: ShadowcraftTalents.GetActiveSpecName() || "n/a"
    }
    a_stats.push {
      name: "Boss Adds"
      val: if data.options.general.num_boss_adds? and (data.options.general.num_boss_adds > 0) then Math.min(4, data.options.general.num_boss_adds) else "0"
    }
    if ShadowcraftTalents.GetActiveSpecName() == "Combat"
      a_stats.push {
        name: "Blade Flurry"
        val: if data.options.rotation.blade_flurry then "ON" else "OFF"
      }
    else if ShadowcraftTalents.GetActiveSpecName() == "Subtlety"
      a_stats.push {
        name: "CP Builder"
        val:
          switch data.options.rotation.use_hemorrhage
            when "never" then "Backstab"
            when "always" then "Hemorrhage"
            when "uptime" then "Backstab w/ Hemo"
      }
    if data.options.general.lethal_poison
      a_stats.push {
        name: "Poison"
        val:
          switch data.options.general.lethal_poison
            when "wp" then "Wound"
            when "dp" then "Deadly"
      }
    $summary.get(0).innerHTML = Templates.stats {stats: a_stats}

  updateStatsWindow: ->
    this.sumStats()
    $stats = $("#stats .inner")
    a_stats = []
    keys = _.keys(@statSum).sort()
    total = 0
    for idx, stat of keys
      weight = getStatWeight(stat, @statSum[stat], null, true)
      total += weight
      a_stats.push {
        name: titleize(stat),
        val: @statSum[stat],
        # ep: Math.floor(weight)
      }

    EP_TOTAL = total
    $stats.get(0).innerHTML = Templates.stats {stats: a_stats}

  updateStatWeights = (source) ->
    Weights.agility = source.ep.agi
    Weights.crit = source.ep.crit
    Weights.strength = source.ep.str
    Weights.mastery = source.ep.mastery
    Weights.haste = source.ep.haste
    Weights.multistrike = source.ep.multistrike
    Weights.versatility = source.ep.versatility
    Weights.pvp_power = source.ep.pvp_power || 0

    other =
      mainhand_dps: Shadowcraft.lastCalculation.mh_ep.mh_dps
      offhand_dps: Shadowcraft.lastCalculation.oh_ep.oh_dps
      t14_2pc: source.other_ep.rogue_t14_2pc || 0
      t14_4pc: source.other_ep.rogue_t14_4pc || 0
      t15_2pc: source.other_ep.rogue_t15_2pc || 0
      t15_4pc: source.other_ep.rogue_t15_4pc || 0
      t16_2pc: source.other_ep.rogue_t16_2pc || 0
      t16_4pc: source.other_ep.rogue_t16_4pc || 0
      t17_2pc: source.other_ep.rogue_t17_2pc || 0
      t17_4pc: source.other_ep.rogue_t17_4pc || 0
      t17_4pc_lfr: source.other_ep.rogue_t17_4pc_lfr || 0
      t18_2pc: source.other_ep.rogue_t18_2pc || 0
      t18_4pc: source.other_ep.rogue_t18_4pc || 0
      t18_4pc_lfr: source.other_ep.rogue_t18_4pc_lfr || 0

    all = _.extend(Weights, other)

    $weights = $("#weights .inner")
    $weights.empty()
    for key, weight of all
      continue if isNaN weight
      continue if weight == 0
      exist = $(".stat#weight_" + key)
      if exist.length > 0
        exist.find("val").text weight.toFixed(3)
      else
        $weights.append("<div class='stat' id='weight_#{key}'><span class='key'>#{titleize(key)}</span><span class='val'>#{Weights[key].toFixed(3)}</span></div>")
        exist = $(".stat#weight_" + key)
        $.data(exist.get(0), "sortkey", 0)
        if key in ["mainhand_dps","offhand_dps"]
          $.data(exist.get(0), "sortkey", 1)
        else if key in ["t14_2pc","t14_4pc","t15_2pc","t15_4pc","t16_2pc","t16_4pc","t17_2pc","t17_4pc","t17_4pc_lfr","t18_2pc","t18_4pc","t18_4pc_lfr"]
          $.data(exist.get(0), "sortkey", 2)
      $.data(exist.get(0), "weight", weight)

    $("#weights .stat").sortElements (a, b) ->
      as = $.data(a, "sortkey")
      bs = $.data(b, "sortkey")
      if as != bs
        return if as > bs then 1 else -1
      else
        if $.data(a, "weight") > $.data(b, "weight") then -1 else 1
    epSort(Shadowcraft.ServerData.GEMS)

  statsToDesc = (obj) ->
    return obj.__statsToDesc if obj.__statsToDesc
    buff = []
    for stat of obj.stats
      buff[buff.length] = "+" + obj.stats[stat] + " " + titleize(stat)
    obj.__statsToDesc = buff.join("/")
    return obj.__statsToDesc

  updateEngineInfoWindow = ->
    return unless Shadowcraft.lastCalculation.engine_info?
    engine_info = Shadowcraft.lastCalculation.engine_info
    $summary = $("#engineinfo .inner")
    data = []
    for name, val of engine_info
      data.push {
        name: titleize name
        val: val
      }
    $summary.get(0).innerHTML = Templates.stats {stats: data}

  updateDpsBreakdown = ->
    dps_breakdown = Shadowcraft.lastCalculation.breakdown
    total_dps = Shadowcraft.lastCalculation.total_dps
    max = null
    buffer = ""
    target = $("#dpsbreakdown .inner")
    rankings = _.extend({}, dps_breakdown)
    max = _.max(rankings)
    $("#dpsbreakdown .talent_contribution").hide()
    for skill, val of dps_breakdown
      skill = skill.replace('(','').replace(')','').split(' ').join('_')
      val = parseFloat(val)
      name = titleize(skill)
      skill = skill.replace(/\./g,'_')
      exist = $("#dpsbreakdown #talent-weight-" + skill)
      if isNaN(val)
        name += " (NYI)"
        val = 0
      pct = val / max * 100 + 0.01
      pct_dps = val / total_dps * 100
      if exist.length == 0
        buffer = Templates.talentContribution({
          name: "#{name} (#{val.toFixed 1} DPS)",
          raw_name: skill,
          val: val.toFixed(1),
          width: pct
        })
        target.append(buffer)
      exist = $("#dpsbreakdown #talent-weight-" + skill)
      $.data(exist.get(0), "val", val)
      exist.show().find(".pct-inner").css({width: pct + "%"})
      exist.find(".label").text(pct_dps.toFixed(2) + "%")

    $("#dpsbreakdown .talent_contribution").sortElements (a, b) ->
      ad = $.data(a, "val")
      bd = $.data(b, "val")
      if ad > bd then -1 else 1
    

  # Standard setup for the popup
  clickSlot = (slot, prop) ->
    $slot = $(slot).closest(".slot")
    $slots.find(".slot").removeClass("active")
    $slot.addClass("active")
    slotIndex = parseInt($slot.attr("data-slot"), 10)
    $.data(document.body, "selecting-slot", slotIndex)
    $.data(document.body, "selecting-prop", prop)
    return [$slot, slotIndex]

  patch_max_ilevel = (patch) ->
    switch patch
      when 60
        1000
      else
        1000

  getItem = (itemId, itemLevel, suffix) ->
    arm = [itemId, itemLevel, suffix || 0]
    itemString = arm.join(':')
    item = Shadowcraft.ServerData.ITEM_LOOKUP2[itemString]
    if not item? and itemId
      console.warn "item not found", itemString
    return item

  getItem: (itemId, itemLevel, suffix) ->
    return getItem(itemId, itemLevel, suffix)

  getItems = (filter = {}) ->
    _.where(Shadowcraft.ServerData.ITEM_LOOKUP2, filter)

  getMaxUpgradeLevel = (item) ->
    if item.quality == 3
      return 1
    else
      if Shadowcraft.region in ["KR", "TW", "CN"]
        return 6
      else
        return 4

  getUpgradeLevelSteps = (item) ->
    if item.quality == 3
      return 8
    else
      return 4

  # Click a name in a slot, for binding to event delegation
  clickSlotName = ->
    buf = clickSlot(this, "item_id")
    $slot = buf[0]
    slot = buf[1]
    selected_identifier = $slot.data("identifier")

    equip_location = SLOT_INVTYPES[slot]
    GemList = Shadowcraft.ServerData.GEMS

    gear = Shadowcraft.Data.gear

    requireDagger = needsDagger()
    combatSpec = Shadowcraft.Data.activeSpec == "Z"
    subtletyNeedsDagger = Shadowcraft.Data.activeSpec == "b" && Shadowcraft.Data.options.rotation.use_hemorrhage in ['uptime','never']

    loc_all = Shadowcraft.ServerData.SLOT_CHOICES[equip_location]
    loc = []
    for lid in loc_all
      l = ShadowcraftData.ITEM_LOOKUP2[lid]
      if lid == selected_identifier # always show equipped item
        loc.push l
        continue
      continue if l.ilvl > Shadowcraft.Data.options.general.max_ilvl
      continue if l.ilvl < Shadowcraft.Data.options.general.min_ilvl
      continue if (slot == 15 || slot == 16) && requireDagger && l.subclass != 15
      #continue if (slot == 15) && combatSpec && l.subclass == 15 && !(l.id >= 77945 && l.id <= 77950)  # If combat, filter all daggers EXCEPT the legendaries.
      continue if (slot == 15) && subtletyNeedsDagger && l.subclass != 15
      #continue if l.ilvl > patch_max_ilevel(Shadowcraft.Data.options.general.patch)
      #continue if l.upgrade_level and not Shadowcraft.Data.options.general.show_upgrades and lid != selected_identifier
      continue if l.upgrade_level? and l.upgrade_level > getMaxUpgradeLevel(l)
      continue if l.suffix and Shadowcraft.Data.options.general.show_random_items > l.ilvl and lid != selected_identifier
      continue if l.tag? and /Tournament$/.test(l.tag) and not Shadowcraft.Data.options.general.pvp
      loc.push l

    #slot = parseInt($(this).parent().data("slot"), 10)

    gear_offset = statOffset(gear[slot], FACETS.ITEM)
    gem_offset = statOffset(gear[slot], FACETS.GEMS)
    epSort(GemList) # Needed for gemming recommendations

    # set bonus
    setBonEP = {}
    for set_name, set of Sets
      setCount = getEquippedSetCount(set.ids, equip_location)
      setBonEP[set_name] ||= 0
      setBonEP[set_name] += setBonusEP(set, setCount)
    for l in loc
      addAchievementBonuses(l)
      l.__gemRec = getGemmingRecommendation(GemList, l, true, slot, gem_offset)
      l.__setBonusEP = 0
      for set_name, set of Sets
        if set.ids.indexOf(l.original_id) >= 0
          l.__setBonusEP += setBonEP[set_name]

      l.__gearEP = get_ep(l, null, slot, gear_offset)
      l.__gearEP = 0 if isNaN l.__gearEP
      l.__setBonusEP = 0 if isNaN l.__setBonusEP
      l.__ep = l.__gearEP + l.__gemRec.ep + l.__setBonusEP


    loc.sort(__epSort)
    maxIEP = 1
    minIEP = 0
    buffer = ""

    for l in loc
      continue if l.__ep < 1
      unless isNaN l.__ep
        maxIEP = l.__ep if maxIEP <= 1
        minIEP = l.__ep

    maxIEP -= minIEP

    for l in loc
      continue if l.__ep < 1
      iEP = l.__ep

      ttid = l.original_id
      ttrand = if l.suffix? then l.suffix else ""
      ttupgd = if l.upgrade_level? then l.upgrade_level else ""
      ttbonus = if l.bonus_trees? then l.bonus_trees.join(":") else ""
      if l.identifier == selected_identifier
        bonus_trees = []
        for bonusIndex in [0..9]
          bonus_trees.push gear[slot]["b" + bonusIndex] if gear[slot]["b" + bonusIndex]?
        ttbonus = bonus_trees.join(":")
      upgrade = []
      if l.upgradable
        curr_level = "0"
        curr_level = l.upgrade_level if l.upgrade_level?
        max_level = getMaxUpgradeLevel(l)
        upgrade = 
          curr_level: curr_level
          max_level: max_level
      buffer += Templates.itemSlot(
        item: l
        identifier: l.original_id + ":" + l.ilvl + ":" + (l.suffix || 0)
        gear: {}
        gems: []
        upgradable: l.upgradable
        upgrade: upgrade
        ttid: ttid
        ttrand: ttrand
        ttupgd: ttupgd
        ttbonus: ttbonus
        desc: "#{l.__gearEP.toFixed(1)} base / #{l.__gemRec.ep.toFixed(1)} gem #{if l.__setBonusEP > 0 then "/ "+ l.__setBonusEP.toFixed(1) + " set" else ""} "
        search: escape(l.name + " " + l.tag)
        percent: Math.max (iEP - minIEP) / maxIEP * 100, 0.01
        ep: iEP.toFixed(1)
      )

    buffer += Templates.itemSlot(
      item: {name: "[No item]"}
      desc: "Clear this slot"
      percent: 0
      ep: 0
    )

    $altslots.get(0).innerHTML = buffer
    $altslots.find(".slot[data-identifier='#{selected_identifier}']").addClass("active")
    showPopup($popup) # TODO
    false

  # Change out an enchant, for binding to event delegation
  clickSlotEnchant = ->
    data = Shadowcraft.Data
    EnchantSlots = Shadowcraft.ServerData.ENCHANT_SLOTS

    buf = clickSlot(this, "enchant")
    slot = buf[1]
    equip_location = SLOT_INVTYPES[slot]

    enchants = EnchantSlots[equip_location]
    max = 0

    gear = Shadowcraft.Data.gear[slot]
    offset = statOffset(gear, FACETS.ENCHANT)
    item = getItem(gear.original_id, gear.item_level, gear.suffix)
    for enchant in enchants
      enchant.__ep = get_ep(enchant, null, slot, offset)
      enchant.__ep = 0 if isNaN enchant.__ep
      max = if enchant.__ep > max then enchant.__ep else max
    enchants.sort(__epSort)
    selected_id = data.gear[slot].enchant
    buffer = ""

    for enchant in enchants
      # do not show enchant if item level is higher than allowed maximum
      continue if enchant.requires?.max_item_level? and enchant.requires?.max_item_level < getBaseItemLevel(item)
      enchant.desc = statsToDesc(enchant) if enchant && !enchant.desc
      enchant.desc = enchant.name if enchant and enchant.desc == ""
      eEP = enchant.__ep
      continue if eEP < 1
      buffer += Templates.itemSlot(
        item: enchant
        percent: eEP / max * 100
        ep: eEP.toFixed(1)
        search: escape(enchant.name + " " + enchant.desc)
        desc: enchant.desc
      )

    buffer += Templates.itemSlot(
      item: {name: "[No enchant]"}
      desc: "Clear this enchant"
      percent: 0
      ep: 0
    )

    $altslots.get(0).innerHTML = buffer
    $altslots.find(".slot[id='#{selected_id}']").addClass("active")
    showPopup($popup) # TODO
    false

  getBaseItemLevel = (item) ->
    unless item.upgrade_level
      return item.ilvl
    return item.ilvl - getUpgradeLevelSteps(item) * item.upgrade_level

  # Change out a gem
  clickSlotGem = ->
    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP2
    GemList = Shadowcraft.ServerData.GEMS
    data = Shadowcraft.Data

    buf = clickSlot(this, "gem")
    $slot = buf[0]
    slot = buf[1]
    item = ItemLookup[$slot.data("identifier")]
    gemSlot = $slot.find(".gem").index(this)
    $.data(document.body, "gem-slot", gemSlot)
    gemType = item.sockets[gemSlot]
    selected_id = data.gear[slot]["g" + gemSlot]

    otherGearGems = []
    for i in [0..2]
      continue if i == gemSlot
      if data.gear[slot]["g" + i]
        otherGearGems.push data.gear[slot]["g" + i]

    for gem in GemList
      gem.__ep = get_ep(gem)
    GemList.sort(__epSort)

    buffer = ""
    usedNames = {}
    max = null
    for gem in GemList
      if usedNames[gem.name]
        if gem.id == selected_id
          selected_id = usedNames[gem.name]
        continue

      usedNames[gem.name] = gem.id
      continue if gem.name.indexOf("Perfect") == 0 and selected_id != gem.id
      continue unless canUseGem gem, gemType, otherGearGems, slot
      continue if gem.name.indexOf('Taladite') >= 0 and item? and item.quality == 7 and item.ilvl <= 620 # do not recommend wod gems to heirlooms
      continue if gem.name.indexOf('Taladite') >= 0 and item? and item.id in [98148,102248] and item.ilvl <= 616 # do not recommend wod gems for legendary cloak
      max ||= gem.__ep
      gEP = gem.__ep
      desc = statsToDesc(gem)

      continue if gEP < 1

      buffer += Templates.itemSlot
        item: gem
        ep: gEP.toFixed(1)
        gear: {}
        ttid: gem.id
        search: escape(gem.name + " " + statsToDesc(gem) + " " + gem.slot)
        percent: gEP / max * 100
        desc: desc
    
    buffer += Templates.itemSlot(
      item: {name: "[No gem]"}
      desc: "Clear this gem"
      percent: 0
      ep: 0
    )

    $altslots.get(0).innerHTML = buffer
    $altslots.find(".slot[id='" + selected_id + "']").addClass("active")
    showPopup($popup) # TODO
    false

  clickSlotBonuses = ->
    clickSlot(this, "bonuses")
    $(".slot").removeClass("active")
    $(this).addClass("active")
    data = Shadowcraft.Data

    $slot = $(this).closest(".slot")
    slot = parseInt($slot.data("slot"), 10)
    $.data(document.body, "selecting-slot", slot)

    identifier = $slot.data("identifier")
    item = Shadowcraft.ServerData.ITEM_LOOKUP2[identifier]

    gear = data.gear[slot]
    currentBonuses = []
    for bonusIndex in [0..9]
      currentBonuses.push gear["b" + bonusIndex] if gear["b" + bonusIndex]?
    # TODO build all possible bonuses with status selected or not, etc.
    groups = {
      suffixes: []
      tertiary: []
      sockets: []
    }
    for bonusId in item.chance_bonus_lists
      group = {}
      group['bonusId'] = bonusId
      group['active'] = true if _.contains(currentBonuses, bonusId)
      group['entries'] = []
      group.ep = 0
      subgroup = null
      for bonus_entry in Shadowcraft.ServerData.ITEM_BONUSES[bonusId]
        entry = {
          'type': bonus_entry.type
          'val1': bonus_entry.val1
          'val2': bonus_entry.val2
        }
        switch bonus_entry.type
          when 6 # cool extra sockets
            group['entries'].push entry
            gem = getBestNormalGem
            group.ep += get_ep(gem)
            subgroup = "sockets"
          when 5 # item name suffix
            group['entries'].push entry
            subgroup = "suffixes"
          when 2 # awesome extra stats
            entry['val2'] = Math.round(bonus_entry.val2 / 10000 * Shadowcraft.ServerData.RAND_PROP_POINTS[item.ilvl][1 + getRandPropRow(slot)])
            entry['val1'] = bonus_entry.val1
            group['entries'].push entry
            group.ep += getStatWeight(entry.val1, entry.val2)
            subgroup = "tertiary" unless subgroup?
      if subgroup?
        group.ep = group.ep.toFixed(2)
        groups[subgroup].push group
        groups[subgroup+"_active"] = true
    for key,subgroup of groups
      continue unless _.isArray(subgroup)
      subgroup.sort (a, b) ->
        b.ep - a.ep
    $.data(document.body, "bonuses-item", item)
    $("#bonuses").html Templates.bonuses
      groups: groups
    Shadowcraft.setupLabels("#bonuses")
    showPopup $("#bonuses.popup") # TODO
    false

  clickWowhead = (e) ->
    e.stopPropagation()
    true

  clickItemUpgrade = (e) ->
    e.stopPropagation()
    buf = clickSlot(this, "item_id")
    slot = buf[1]

    data = Shadowcraft.Data

    #slot = parseInt($(this).parent().data("slot"), 10)

    gear = data.gear[slot]
    item = getItem(gear.original_id, gear.item_level, gear.suffix)
    new_item_id = gear.item_id
    if gear.upgrade_level
      new_item_id = Math.floor(new_item_id / 1000000)
      max = getMaxUpgradeLevel(item)
      gear.upgrade_level += 1
      gear.item_level += getUpgradeLevelSteps(item)
      if gear.upgrade_level > max
        gear.item_level -= getUpgradeLevelSteps(item) * gear.upgrade_level
        delete gear.upgrade_level
    else
      if item.suffix
        new_item_id = Math.floor(new_item_id / 1000)
      gear.upgrade_level = 1
      gear.item_level += getUpgradeLevelSteps(item)
    if gear.upgrade_level
      new_item_id = new_item_id * 1000000 + gear.upgrade_level
      if item.suffix
        new_item_id += Math.abs(item.suffix) * 1000
    else if item.suffix
      new_item_id = new_item_id * 1000 + Math.abs(item.suffix)
    data.gear[slot].item_id = new_item_id
    Shadowcraft.update()
    Shadowcraft.Gear.updateDisplay()
    true

  clickItemLock = (e) ->
    e.stopPropagation()
    buf = clickSlot(this, "item_id")
    slot = buf[1]

    data = Shadowcraft.Data

    gear = data.gear[slot]
    gear.locked ||= false
    data.gear[slot].locked = not gear.locked
    item = getItem(gear.original_id, gear.item_level, gear.suffix)
    if item
      if data.gear[slot].locked
        Shadowcraft.Console.log("Locking " + item.name + " for Optimize Gems")
      else
        Shadowcraft.Console.log("Unlocking " + item.name + " for Optimize Gems")
    #Shadowcraft.update()
    Shadowcraft.Gear.updateDisplay()
    true

  boot: ->
    app = this
    $slots = $(".slots")
    $popup = $(".alternatives")
    $altslots = $(".alternatives .body")

    Shadowcraft.Backend.bind("recompute", updateStatWeights)
    Shadowcraft.Backend.bind("recompute", -> Shadowcraft.Gear )
    Shadowcraft.Backend.bind("recompute", updateDpsBreakdown)
    Shadowcraft.Backend.bind("recompute", updateEngineInfoWindow)

    Shadowcraft.Talents.bind "changed", ->
      app.updateStatsWindow()
      app.updateSummaryWindow()

    Shadowcraft.bind "loadData", ->
      app.updateDisplay()

    $("#optimizeGems").click ->
      window._gaq.push ['_trackEvent', "Character", "Optimize Gems"] if window._gaq
      Shadowcraft.Gear.optimizeGems()

    $("#optimizeEnchants").click ->
      window._gaq.push ['_trackEvent', "Character", "Optimize Enchants"] if window._gaq
      Shadowcraft.Gear.optimizeEnchants()

    $("#lockAll").click ->
      window._gaq.push ['_trackEvent', "Character", "Lock All"] if window._gaq
      Shadowcraft.Gear.lockAll()

    $("#unlockAll").click ->
      window._gaq.push ['_trackEvent', "Character", "Unlock All"] if window._gaq
      Shadowcraft.Gear.unlockAll()

    # Initialize UI handlers
    $("#bonuses").click $.delegate
      ".label_check input"  : ->
        $this = $(this)
        #changeOption($this, "check", not $this.attr("checked")?)
        $this.attr("checked", not $this.attr("checked")?)
        Shadowcraft.setupLabels("#bonuses")
      ".applyBonuses" : this.applyBonuses
      ".clearBonuses" : clearBonuses

    #  Change out an item
    $slots.click $.delegate
      ".upgrade" : clickItemUpgrade
      ".lock"    : clickItemLock
      ".wowhead" : clickWowhead
      ".name"    : clickSlotName
      ".enchant" : clickSlotEnchant
      ".gem"     : clickSlotGem
      ".bonuses" : clickSlotBonuses

    $(".slots, .popup").mouseover($.delegate
      ".tt": ttlib.requestTooltip
    ).mouseout($.delegate
      ".tt": ttlib.hide
    )

    $(".popup .body").bind "mousewheel", (event) ->
      if (event.wheelDelta < 0 and this.scrollTop + this.clientHeight >= this.scrollHeight) or event.wheelDelta > 0 and this.scrollTop == 0
        event.preventDefault()
        return false

    $("#gear .slots").mousemove (e) ->
      $.data document, "mouse-x", e.pageX
      $.data document, "mouse-y", e.pageY

    defaultScale =
      Intellect:            -1000000
      Spirit:               -1000000
      Is2HMace:             -1000000
      IsPolearm:            -1000000
      Is2HSword:            -1000000
      IsShield:             -1000000
      SpellPower:           -1000000
      IsStaff:              -1000000
      IsFrill:              -1000000
      IsCloth:              -1000000
      IsMail:               -1000000
      IsPlate:              -1000000
      IsRelic:              -1000000
      Ap:                   1
      IsWand:               -1000000
      SpellPenetration:     -1000000
      GemQualityLevel:      85
      MetaGemQualityLevel:  86
      SpeedBaseline:        2

    $("#getPawnString").click ->
      scale = _.extend({}, defaultScale)
      scale.MasteryRating = Weights.mastery
      scale.CritRating = Weights.crit
      scale.HasteRating = Weights.haste
      scale.Agility = Weights.agility
      scale.Strength = Weights.strength
      scale.MainHandDps = Shadowcraft.lastCalculation.mh_ep.mh_dps
      scale.MainHandSpeed = (Shadowcraft.lastCalculation.mh_speed_ep["mh_2.7"] - Shadowcraft.lastCalculation.mh_speed_ep["mh_2.6"]) * 10
      scale.OffHandDps = Shadowcraft.lastCalculation.oh_ep.oh_dps
      scale.OffHandSpeed = (Shadowcraft.lastCalculation.oh_speed_ep["oh_1.4"] - Shadowcraft.lastCalculation.oh_speed_ep["oh_1.3"]) * 10
      scale.MetaSocketEffect = 0

      stats = []
      for weight, val of scale
        stats.push "#{weight}=#{val}"
      name = "Rogue: " + ShadowcraftTalents.GetActiveSpecName()
      pawnstr = "(Pawn:v1:\"#{name}\":#{stats.join(",")})"
      $("#generalDialog").html("<textarea style='width: 450px; height: 300px;'>#{pawnstr}</textarea>")
      $("#generalDialog").dialog({ modal: true, width: 500, title: "Pawn Import String" })
      return false


    # Select an item from a popup
    $altslots.click $.delegate
      ".slot": (e) ->
        Shadowcraft.Console.purgeOld()
        ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP2
        EnchantLookup = Shadowcraft.ServerData.ENCHANT_LOOKUP
        Gems = Shadowcraft.ServerData.GEM_LOOKUP
        data = Shadowcraft.Data

        slot = $.data(document.body, "selecting-slot")
        update = $.data(document.body, "selecting-prop")
        $this = $(this)
        if update == "item_id" || update == "enchant"
          val = parseInt($this.attr("id"), 10)
          identifier = $this.data("identifier")
          data.gear[slot][update] = if val != 0 then val else null
          if update == "item_id"
            item = ItemLookup[identifier]
            data.gear[slot].reforge = null
            if data.gear[slot].item_id and item.upgrade_level
              data.gear[slot].upgrade_level = item.upgrade_level
            else
              data.gear[slot].upgrade_level = null
            if item
              data.gear[slot].original_id = item.original_id
              data.gear[slot].item_level = item.ilvl
              if item.suffix
                data.gear[slot].suffix = item.suffix
              else
                data.gear[slot].suffix = null
              if item.sockets
                socketlength = item.sockets.length
                for i in [0..2]
                  if i >= socketlength
                    data.gear[slot]["g" + i] = null
                  else if data.gear[slot]["g" + i]?
                    gem = Gems[data.gear[slot]["g" + i]]
                    if gem
                      if gem.id == ShadowcraftGear.LEGENDARY_META_GEM and not canUseLegendaryMetaGem(item)
                        data.gear[slot]["g" + i] = null
                      else if not canUseGem Gems[data.gear[slot]["g" + i]], item.sockets[i], [], slot
                        data.gear[slot]["g" + i] = null
              if item.bonus_trees
                for bonusIndex in [0..9]
                  data.gear[slot]["b" + bonusIndex] = null
                for bonusIndex, bonus_id of item.bonus_trees
                  data.gear[slot]["b" + bonusIndex] = bonus_id
            else
              data.gear[slot].original_id = null
              data.gear[slot].item_level = null
              data.gear[slot]["g" + i] = null for i in [0..2]
              data.gear[slot]["b" + i] = null for i in [0..9]
              data.gear[slot].suffix = null
          else
            enchant_id = if not isNaN(val) then val else null
            item = getItem(data.gear[slot].original_id, data.gear[slot].item_level, data.gear[slot].suffix)
            if enchant_id?
              Shadowcraft.Console.log("Changing " + item.name + " enchant to " + EnchantLookup[enchant_id].name)
            else
              Shadowcraft.Console.log("Removing Enchant from " + item.name)
        else if update == "gem"
          item_id = parseInt($this.attr("id"), 10)
          item_id = if not isNaN(item_id) then item_id else null
          gem_id = $.data(document.body, "gem-slot")
          item = getItem(data.gear[slot].original_id, data.gear[slot].item_level, data.gear[slot].suffix)
          if item_id?
            Shadowcraft.Console.log("Regemming " + item.name + " socket " + (gem_id + 1) + " to " + Gems[item_id].name)
          else
            Shadowcraft.Console.log("Removing Gem from " + item.name + " socket " + (gem_id + 1))
          data.gear[slot]["g" + gem_id] = item_id
        Shadowcraft.update()
        app.updateDisplay()

    this.updateDisplay()

    $("input.search").keydown((e) ->
      $this = $(this)
      $popup = $this.closest(".popup")
      switch e.keyCode
        when 27 #  Esc
          $this.val("").blur().keyup()
          e.cancelBubble = true
          e.stopPropagation()
        when 38 #  Up arrow
          slots = $popup.find(".slot:visible")
          for slot, i in slots
            if slot.className.indexOf("active") != -1
              if slots[i-1]?
                next = $(slots[i-1])
                break
              else
                next = $popup.find(".slot:visible").last()
                break
        when 40 # Down arrow
          slots = $popup.find(".slot:visible")
          for slot, i in slots
            if slot.className.indexOf("active") != -1
              if slots[i+1]?
                next = $(slots[i+1])
                break
              else
                next = $popup.find(".slot:visible").first()
                break
        when 13 # Enter
          $popup.find(".active").click()
          return

      if next
        $popup.find(".slot").removeClass("active")
        next.addClass("active")
        ot = next.get(0).offsetTop
        height = $popup.height()
        body = $popup.find(".body")

        if ot > body.scrollTop() + height - 30
          body.animate({scrollTop: next.get(0).offsetTop - height + next.height() + 30}, 150)
        else if ot < body.scrollTop()
          body.animate({scrollTop: next.get(0).offsetTop - 30}, 150)
    ).keyup( (e) ->
      $this = $(this)
      popup = $this.parents(".popup")
      search = $.trim($this.val().toLowerCase())
      all = popup.find(".slot:not(.active)")
      show = all.filter(":regex(data-search, " + escape(search) + ")")
      hide = all.not(show)
      show.removeClass("hidden")
      hide.addClass("hidden")
    )

    # On escape, clear popups
    reset = ->
      $(".popup:visible").removeClass("visible")
      ttlib.hide()
      $slots.find(".active").removeClass("active")

    $("body").click(reset).keydown (e) ->
      if e.keyCode == 27
        reset()

    $("#filter, #bonuses").click (e) ->
      e.cancelBubble = true
      e.stopPropagation()

    Shadowcraft.Options.bind "update", (opt, val) ->
      if opt in ['rotation.use_hemorrhage','general.pvp']
        app.updateDisplay()
      if opt in ['rotation.blade_flurry','general.num_boss_adds','general.lethal_poison']
        app.updateSummaryWindow()

    checkForWarnings('options')

    this

  constructor: (@app) ->
