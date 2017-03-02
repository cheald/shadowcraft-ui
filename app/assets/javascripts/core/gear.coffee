class ShadowcraftGear
  FACETS = {
    ITEM: 1
    GEMS: 2
    ENCHANT: 4
    ALL: 255
  }
  @FACETS = FACETS

  SLOT_ORDER = ["0", "1", "2", "14", "4", "8", "9", "5", "6", "7", "10", "11", "12", "13", "15", "16"]
  SLOT_DISPLAY_ORDER = [["0", "1", "2", "14", "4", "8", "15", "16"], ["9", "5", "6", "7", "10", "11", "12", "13"]]

  # Default weights for the DPS calculations. These get reset by calculation
  # passes through the engine.
  Weights =
    attack_power: 1
    agility: 1.1
    crit: 0.87
    haste: 1.44
    mastery: 1.15
    multistrike: 1.12
    versatility: 1.2
    strength: 1.05

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
  $popupbody = null
  $popup = null

  @initialized = false

  # Determines which value in a row of the rand prop points table to pull for a certain
  # slot.
  getRandPropEntry = (slotIndex) ->
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

  # Gets the total EP for a block of stats
  getEPForStatBlock = (stats, ignore) ->
    total = 0
    for stat, value of stats
      total += getStatWeight(stat, value, ignore) || 0
    return total

  # Gets the EP value for an item out of the last run of calculation data
  getEP = (item, slot=-1, ignore=[]) ->

    stats = {}
    sumItem(stats, item['stats'])

    # Add all of the EP for all of the stats
    total = getEPForStatBlock(stats, ignore)

    # If there was already a calculation done, there's some extra EP to add based on
    # weapon damage, enchants, and trinkets.
    c = Shadowcraft.lastCalculation
    if c
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
      else if ShadowcraftConstants.PROC_ENCHANTS[item.id]
        switch slot
          when 15
            pre = "mh_"
          when 16
            pre = "oh_"
        enchant = ShadowcraftConstants.PROC_ENCHANTS[item.id]
        if !pre and enchant
          total += c["other_ep"][enchant]
        else if pre and enchant
          total += c[pre + "ep"][pre + enchant]

      # If this is a trinket, include the value of the proc in the EP value
      item_level = item.ilvl
      if c.trinket_map[item.id]
        proc_name = c.trinket_map[item.id]
        if c.proc_ep[proc_name] and c.proc_ep[proc_name][item_level]
          total += c.proc_ep[proc_name][item_level]
        else
          console.warn "error in trinket_ranking", item_level, item.name

    total

  sumGearItem = (output, gear, ilvl_diff=0) ->

    # if gear.id in ShadowcraftConstants.ARTIFACTS
    #   item = Shadowcraft.Data.artifact_items[gear.id]
    #   ilvl_diff = item.ilvl-750
    # else
    item = getItem(gear.id, gear.base_ilvl)
    item_stats = $.extend({}, item['stats'])

    if gear.bonuses
      for id in gear.bonuses
        if !Shadowcraft.ServerData.ITEM_BONUSES[id]
          continue
        for entry in Shadowcraft.ServerData.ITEM_BONUSES[id]
          if entry.type == 2
            rand_val = Math.round(entry.val2 / 10000 * Shadowcraft.ServerData.RAND_PROP_POINTS[gear.item_level][1+getRandPropEntry(gear.slot)])
            if (!(entry.val1 in item_stats))
              item_stats[entry.val1] = 0
            item_stats[entry.val1] += rand_val

    if (ilvl_diff == 0)
      ilvl_diff = gear.item_level-item.ilvl
    
    sumItem(output, item_stats, ilvl_diff)

  # Sums all of the stats passed in into a second map of stats, recalculating for
  # item level difference if needed.
  sumItem = (output, input_stats, ilvl_difference=0) ->

    if (ilvl_difference != 0)
      newstats = recalculateStatsDiff(input_stats, ilvl_difference)
    else
      newstats = input_stats

    for stat of newstats
      output[stat] ||= 0
      output[stat] += Math.round(newstats[stat])
    null

  # Generates a stat block for a slot. This method can be used to limit the stats to
  # a specific type of data by passing a facet to the method, or to return all of the
  # stats for the item including normal stats, gems, and enchants.
  sumSlot: (gear, out, facets) ->
    return unless gear?.id?
    facets ||= FACETS.ALL

    item = getItem(gear.id, gear.base_ilvl)
    return unless item?

    if (facets & FACETS.ITEM) == FACETS.ITEM
      # if the item level is different between the gear and the item, we need to pass
      # the difference so the stats are adjusted accordingly.
      sumGearItem(out, gear)

    if (facets & FACETS.GEMS) == FACETS.GEMS
      for gid in gear.gems
        if gid and gid > 0
          gem = Shadowcraft.ServerData.GEM_LOOKUP[gid]
          sumItem(out, gem['stats']) if(gem)

    if (facets & FACETS.ENCHANT) == FACETS.ENCHANT
      enchant_id = gear.enchant
      if enchant_id and enchant_id > 0
        enchant = Shadowcraft.ServerData.ENCHANT_LOOKUP[enchant_id]
        sumItem(out, enchant['stats']) if enchant

  # Returns the complete stats for all of the items added together for a character.
  # Facets can be used to limit the data to the item, gems, or enchants.
  sumStats: ->
    stats = {}
    data = Shadowcraft.Data

    for si, i in SLOT_ORDER
      Shadowcraft.Gear.sumSlot(data.gear[si], stats, null)

    # Add the base character agility and multiply by the bonus we get for wearing
    # all leather gear. Finally, round to an even number.
    stats['agility'] = Math.round((stats['agility'] + 9030) * 1.05)

    @statSum = stats
    return stats

  # Returns a single stat from all of the stats for a character.
  getStat: (stat) ->
    this.sumStats() if !@statSum
    (@statSum[stat] || 0)

  # Stat to get the real weight for, the amount of the stat, and a hash of {stat: amount} to
  # ignore (like if swapping out a enchant or whatnot; nil the existing enchant for calcs)
  getStatWeight = (stat, num, ignore, ignoreAll) ->
    exist = 0
    unless ignoreAll
      exist = Shadowcraft.Gear.getStat(stat)
      if ignore and ignore[stat]
        exist -= ignore[stat]

    neg = if num < 0 then -1 else 1
    num = Math.abs(num)

    return (Weights[stat] || 0) * num * neg

  # Sort comparator that sorts items in reverse order (highest first)
  sortComparator = (a, b) ->
    diff = b.__ep - a.__ep
    if diff == 0
      diff = b.id - a.id
      if diff == 0
        return b.ilvl - a.ilvl
      else
        return diff
    else
      return diff

  # Sorts a list of item IDs based on their EP value. This requires repeatedly calling
  # getEP for every item, then sorting the resulting list.
  epSort = (list) ->
    for item in list
      item.__ep = getEP(item) if item
      item.__ep = 0 if isNaN(item.__ep)
    list.sort(sortComparator)

  # Calculate the EP bonus for a set bonus based on the set type and the number of pieces.
  setBonusEP = (set, count) ->
    return 0 unless c = Shadowcraft.lastCalculation

    total = 0
    for p, bonus_name of set.bonuses
      if count == (p-1)
        total += c["other_ep"][bonus_name]

    return total

  # Returns the number of pieces for each gear set that are equipped. This is used to call
  # setBonusEP to determine the EP bonus for the equipped set pieces.
  getEquippedSetCount = (setIds, ignoreSlotIndex) ->
    count = 0
    for slot in SLOT_ORDER
      continue if SLOT_INVTYPES[slot] == ignoreSlotIndex
      gear = Shadowcraft.Data.gear[slot]
      if gear.id in setIds
        count++
    return count

  # TODO: there's no reason to have two methods here
  isProfessionalGem = (gem, profession) ->
    return false unless gem?
    gem.requires?.profession? and gem.requires.profession == profession

  canUseGem = (gem) ->
    return false if gem.slot != "Prismatic"
    if gem.requires?.profession?
      return false if isProfessionalGem(gem, 'jewelcrafting')
    true

  # Check if the gems have equal stats to pretend that optimize gems not change gems to
  # stat equal gems
  equalGemStats = (from_gem,to_gem) ->
    for stat of from_gem["stats"]
      if !to_gem["stats"][stat]? or from_gem["stats"][stat] != to_gem["stats"][stat]
        return false
    return true

  # Determines the best set of gems for an item.
  getGemmingRecommendation = (gem_list, gear, offset) ->
    if !hasSocket(gear)
      return {ep: 0, gems: []}

    straightGemEP = 0
    sGems = []
    foundgem = false
    for gem in gem_list
      continue unless canUseGem(gem)
      straightGemEP += getEP(gem, null, offset)
      sGems.push gem.id
      foundgem = true
      break
    sGems.push null if !foundgem

    epValue = straightGemEP
    gems = sGems
    return {ep: epValue, gems: gems}

  # Called when a user clicks the Lock All button
  lockAll: () ->
    Shadowcraft.Console.log("Locking all items")
    for slot in SLOT_ORDER
      gear = Shadowcraft.Data.gear[slot]
      gear.locked = true
    Shadowcraft.Gear.updateDisplay()

  # Called when a user clicks the Unlock All button
  unlockAll: () ->
    Shadowcraft.Console.log("Unlocking all items")
    for slot in SLOT_ORDER
      gear = Shadowcraft.Data.gear[slot]
      gear.locked = false
    Shadowcraft.Gear.updateDisplay()

  # Called when a user clicks the Optimize Gems button. This recursively looks for
  # the best gem configuration across all of the items down, checking up to 10
  # times.
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
      continue if gear.id in ShadowcraftConstants.ARTIFACTS

      gem_offset = statOffset(gear, FACETS.GEMS)

      rec = getGemmingRecommendation(gem_list, gear, gem_offset)
      for gem, gemIndex in rec.gems
        from_gem = Gems[gear.gems[gemIndex]]
        to_gem = Gems[gem]
        continue unless to_gem?
        if gear.gems[gemIndex] != gem
          item = getItem(gear.id, gear.base_ilvl)
          if from_gem && to_gem
            continue if from_gem.name == to_gem.name
            continue if equalGemStats(from_gem, to_gem)
            Shadowcraft.Console.log "Regemming #{item.name} socket #{gemIndex+1} from #{from_gem.name} to #{to_gem.name}"
          else
            Shadowcraft.Console.log "Regemming #{item.name} socket #{gemIndex+1} to #{to_gem.name}"

          gear.gems[gemIndex] = gem
          madeChanges = true

    # If we didn't make changes on this pass, or we've went down 10 levels already
    # then stop, update the DPS calculation, update the display, and log the changes.
    # Otherwise, make another call to try again.
    if !madeChanges or depth >= 10
      @app.update()
      this.updateDisplay()
      Shadowcraft.Console.log "Finished automatic regemming: &Delta; #{Math.floor(@getEPTotal() - EP_PRE_REGEM)} EP", "gold"
    else
      this.optimizeGems(depth + 1)

  # Gets the first enchant from a list of enchants that can be applied to an item
  # based on ilvl. enchant_list is assumed to be a list of enchants sorted by
  # EP.
  getEnchantRecommendation = (enchant_list, item) ->

    for enchant in enchant_list
      # do not consider enchant if item level is higher than allowed maximum
      continue if enchant.requires?.max_item_level? and enchant.requires?.max_item_level < getBaseItemLevel(item)
      return enchant.id
    return false

  # Gets a list of enchants that apply to an item slot, sorted by EP.
  getApplicableEnchants = (slotIndex, item, enchant_offset) ->
    enchant_list = Shadowcraft.ServerData.ENCHANT_SLOTS[SLOT_INVTYPES[slotIndex]]
    unless enchant_list?
      return []

    enchants = []
    for enchant in enchant_list
      # do not show enchant if item level is higher than allowed maximum
      continue if enchant.requires?.max_item_level? and enchant.requires?.max_item_level < getBaseItemLevel(item)
      enchant.__ep = getEP(enchant, slotIndex, enchant_offset)
      enchant.__ep = 0 if isNaN(enchant.__ep)
      enchants.push(enchant)
    enchants.sort(sortComparator)
    return enchants

  getApplicableEnchants: (slotIndex, item, enchant_offset) ->
    return getApplicableEnchants(slotIndex, item, enchant_offset)

  # Called when a user clicks the Optimize Enchants button. This recursively looks
  # for the best gem configuration across all of the items down, checking up to 10
  # times.
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

      # don't auto-enchant artifact weapons
      continue if slotIndex == 15 or slotIndex == 16

      gear = data.gear[slotIndex]
      continue unless gear
      continue if gear.locked

      item = getItem(gear.id, gear.base_ilvl)
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

  # Returns a list of all of the gems available with EPs for each of them. Used
  # when opening the bonuses popup.
  # TODO: what makes this different from getGemRecommentationList?
  getBestNormalGem = ->
    Gems = Shadowcraft.ServerData.GEMS
    copy = $.extend(true, [], Gems)
    list = []
    for gem in copy
      continue if gem.requires? or gem.requires?.profession?
      gem.__color_ep = gem.__color_ep || getEP(gem)
      if (gem.slot == "Prismatic") and gem.__color_ep and gem.__color_ep > 1
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
      gem.normal_ep = getEP(gem)
      if gem.normal_ep and gem.normal_ep > 1
        list.push gem

    list.sort (a, b) ->
      b.normal_ep - a.normal_ep
    list

  # Called when a user clicks the apply button on the bonuses popup
  # window. This adds a bonus to an item in the user's gear.
  applyBonuses: ->
    Shadowcraft.Console.purgeOld()
    data = Shadowcraft.Data
    slot = $.data(document.body, "selecting-slot")
    gear = data.gear[slot]
    return unless gear
    item = getItem(gear.id, gear.base_ilvl)

    currentBonuses = []
    if gear.bonuses?
      currentBonuses = gear.bonuses

    # We have to store these because we have to do some trickery with replacing
    # the one in the ttBonus list at the end.
    oldWF = 1472
    oldTTWF = 1472
    newWF = 1472
    for bonus in currentBonuses
      if bonus in ShadowcraftConstants.WF_BONUS_IDS
        oldWF = bonus
    for bonus in gear.ttBonuses
      if bonus in ShadowcraftConstants.WF_BONUS_IDS
        oldTTWF = bonus

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
      if $(this).is(':selected') and !isNaN(val)
        checkedBonuses.push val
      else if !isNaN(val)
        uncheckedBonuses.push val

    union = _.union(currentBonuses, checkedBonuses)
    newBonuses = _.difference(union, uncheckedBonuses)
    removedBonuses = _.difference(union, newBonuses)

    # Apply new bonuses, and fix the item level the piece of gear base on whether
    # a warforged/titanforged bonus ID is applied.
    gear.bonuses = newBonuses
    gear.item_level = item.ilvl;
    if (!isNaN(gear.upgrade_level))
      gear.item_level += gear.upgrade_level * getUpgradeLevelSteps(item)
    for bonus in newBonuses
      if bonus in ShadowcraftConstants.WF_BONUS_IDS
        for entry in Shadowcraft.ServerData.ITEM_BONUSES[bonus]
          if entry.type == 1
            newWF = bonus
            gear.item_level += entry.val1

    # This is the trickery mentioned earlier. Take the difference between the old
    # WF value and the new WF value and adjust the ttBonus version of it by the
    # same amount.
    diff = newWF-oldWF
    if diff != 0
      if (oldTTWF == 1472)
        gear.ttBonuses.push(newWF)
      else
        index = gear.ttBonuses.indexOf(oldTTWF)
        gear.ttBonuses[index] = oldTTWF + diff

    # If we removed a socket, we need to remove the gem that corresponds to that
    # socket as well.
    for bonus in removedBonuses
      if bonus in ShadowcraftConstants.SOCKET_BONUS_IDS
        gear.gems[0] = 0

    $("#bonuses").removeClass("visible")
    Shadowcraft.update()
    Shadowcraft.Gear.updateDisplay()

  # Returns true if a piece of gear has a bonus on it that means an added
  # socket.
  hasSocket = (gear) ->
    for bonus in gear.bonuses
      if bonus in ShadowcraftConstants.SOCKET_BONUS_IDS
        return true
    return false

  ###
  # View helpers
  ###

  # Used by makeTag to sort a set of bonuses based on the val2 field in
  # ITEM_BONUSES to make sure that the tag text is ordered correctly.
  sortTagBonuses = (a,b) ->
    return a.position-b.position

  # Generates a tag string from a set of bonuses.
  makeTag = (bonuses) ->
    tag_bonuses = []
    for bonus in bonuses
      continue if not bonus
      if not Shadowcraft.ServerData.ITEM_BONUSES[bonus]
        console.warn "Bonus ID " + bonus + " is not valid"
        continue
      for bonus_entry in Shadowcraft.ServerData.ITEM_BONUSES[bonus]
        if bonus_entry.type == 4
          tag_bonus =
            position: bonus_entry.val2
            desc_id: bonus_entry.val1
          tag_bonuses.push tag_bonus

    tag = ""
    if (tag_bonuses.length > 0)
      tag_bonuses.sort(sortTagBonuses)
      for bonus in tag_bonuses
        if (tag.length > 0)
          tag += " "
        tag += Shadowcraft.ServerData.ITEM_DESCRIPTIONS[bonus['desc_id']]
    return tag

  # Updates the display, redrawing all of the elements on the gear tab.
  updateDisplay: ->
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
        item = getItem(gear.id, gear.base_ilvl)
        gems = []
        sockets = []
        bonuses = null
        enchant = EnchantLookup[gear.enchant]
        enchantable = null
        bonusable = null
        opt = {}
        if item?
          enchantable = gear.id not in ShadowcraftConstants.ARTIFACTS && EnchantSlots[item.equip_location]? && getApplicableEnchants(i, item).length > 0

          bonus_keys = _.keys(Shadowcraft.ServerData.ITEM_BONUSES)
          tag = ""
          if (gear.bonuses?)
            tag = makeTag(gear.bonuses)

          if tag.length == 0
            tag = item.tag

          # Check if there are any bonus traits like sockets or tertiary stats that can
          # be applied to this item.
          # TODO: add suffix support here.
          if item.chance_bonus_lists?
            for bonusId in item.chance_bonus_lists
              continue if not bonusId?
              break if bonusable
              for bonus_entry in Shadowcraft.ServerData.ITEM_BONUSES[bonusId]
                switch bonus_entry.type
                  when 6 # cool extra sockets
                    bonusable = true
                    break
                  when 2 # tertiary stats
                    bonusable = true
                    break
                  when 14 # base item level (can be warforged)
                    bonusable = true
                    break

              # Hack for warforged
              if bonusId == -1
                bonusable = true

          # If there's an enchant already on this item, grab the description of it so that
          # it can be displayed correctly.
          if enchant and !enchant.desc
            enchant.desc = statsToDesc(enchant)

          # If this item can be upgradable, determine the current upgrade level and max
          # level so that the arrow can be displayed correctly.
          if item.upgradable
            curr_level = "0"
            curr_level = gear.upgrade_level.toString() if gear.upgrade_level?
            max_level = getMaxUpgradeLevel(item)
            upgrade =
              curr_level: curr_level
              max_level: max_level

          # Generate an array of the gem objects for each gem attached to a piece of gear
          for gem in gear.gems
            if gem != 0 and gem != null
              gems[gems.length] = {gem: Gems[gem]}

          if hasSocket(gear) and gems.length == 0
            gem = {gem: {slot: "Prismatic"}}
            gems.push gem

          # If there wasn't a description for the enchant just use the name instead.
          if enchant and enchant.desc == ""
            enchant.desc = enchant.name

          # Join the list of gems together so they all display correctly.
          ttgems = gear.gems.join(":")

          opt.item = item
          opt.tag = tag
          opt.identifier = item.id + ":" + item.ilvl if item
          opt.ilvl = gear.item_level
          opt.ttid = item.id if item
          opt.quality = if gear.quality then gear.quality else item.quality
          opt.ttupgd = if upgrade then upgrade['curr_level'] else null
          opt.ttbonus = if gear.ttBonuses then gear.ttBonuses.join(":") else null
          opt.ttgems = if ttgems != "0:0:0" then ttgems else null
          opt.ep = if item then getEP(item, i).toFixed(1) else 0
          opt.bonusable = bonusable
          opt.socketbonus = bonuses
          opt.enchantable = enchantable
          opt.enchant = enchant
          opt.upgradable = if item then item.upgradable else false
          opt.upgrade = upgrade
          opt.display_ilvl = false

          if gear.id not in ShadowcraftConstants.ARTIFACTS
            opt.gems = gems
          else
            opt.gems = null

          opt.lock = true
          if gear.locked
            opt.lock_class = "lock_on"
          else
            opt.lock_class = "lock_off"

        opt.slot = i
        buffer += Templates.itemSlot(opt)

      $slots.get(ssi).innerHTML = buffer
    this.updateStatsWindow()
    this.updateSummaryWindow()
    checkForWarnings('gear')

  # Returns the current total EP summed from all of the gear, gems, and enchants.
  getEPTotal: ->
    this.sumStats()
    keys = _.keys(@statSum).sort()
    total = 0
    for idx, stat of keys
      weight = getStatWeight(stat, @statSum[stat], null, true)
      total += weight
    return total

  # Updates the display of the Summary section of the Gear tab.
  updateSummaryWindow: ->
    data = Shadowcraft.Data
    $summary = $("#summary .inner")
    a_stats = []
    valengine = "7.1.5"
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
          switch data.options.rotation.cp_builder
            when "backstab" then "Backstab"
            when "shuriken_storm" then "Shuriken Storm"
      }
    else if ShadowcraftTalents.GetActiveSpecName() == "Assassination"
      if data.options.general.lethal_poison
        a_stats.push {
          name: "Poison"
          val:
            switch data.options.general.lethal_poison
              when "wp" then "Wound"
              when "dp" then "Deadly"
        }
    $summary.get(0).innerHTML = Templates.stats {stats: a_stats}

  # Updates the display of the Gear Stats section of the Gear tab.
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

  # Updates the display of the Stat Weights section on the gear tab with
  # information from the last calculation pass.
  updateStatWeights = (source) ->
    Weights.agility = source.ep.agi
    Weights.crit = source.ep.crit
    Weights.strength = source.ep.str
    Weights.mastery = source.ep.mastery
    Weights.haste = source.ep.haste
    Weights.multistrike = source.ep.multistrike
    Weights.versatility = source.ep.versatility

    other =
      mainhand_dps: Shadowcraft.lastCalculation.mh_ep.mh_dps
      offhand_dps: Shadowcraft.lastCalculation.oh_ep.oh_dps
      t18_2pc: source.other_ep.rogue_t18_2pc || 0
      t18_4pc: source.other_ep.rogue_t18_4pc || 0
      t18_4pc_lfr: source.other_ep.rogue_t18_4pc_lfr || 0
      t19_2pc: source.other_ep.rogue_t19_2pc || 0
      t19_4pc: source.other_ep.rogue_t19_4pc || 0
      orderhall_8pc: source.other_ep.rogue_orderhall_8pc || 0

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
        else if key in ["t18_2pc","t18_4pc","t18_4pc_lfr","t19_2pc","t19_4pc","rogue_orderhall_8pc"]
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

  # Updates the engine info section of the Advanced tab with information
  # from the last calculation pass.
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

  # Updates the dps breakdown section of the Advanced tab with information
  # from the last calculation pass.
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
      skill = skill.replace(/:/g,'_')
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

  # Creates a description of an item based on the stats (+x stat)
  statsToDesc = (obj) ->
    return obj.__statsToDesc if obj.__statsToDesc
    buff = []
    for stat of obj.stats
      buff[buff.length] = "+" + obj.stats[stat] + " " + titleize(stat)
    obj.__statsToDesc = buff.join("/")
    return obj.__statsToDesc

  # Performs some standard setup for any popup windows that are opened
  clickSlot = (slot, prop) ->
    $slot = $(slot).closest(".slot")
    $slots.find(".slot").removeClass("active")
    $slot.addClass("active")
    slotIndex = parseInt($slot.attr("data-slot"), 10)
    $.data(document.body, "selecting-slot", slotIndex)
    $.data(document.body, "selecting-prop", prop)
    return [$slot, slotIndex]

  # Gets an item from the item lookup table based on item ID and base item level
  getItem = (itemId, base_ilvl) ->
    if (itemId in ShadowcraftConstants.ARTIFACTS)
      item = Shadowcraft.Data.artifact_items[itemId]
    else
      arm = [itemId, base_ilvl]
      itemString = arm.join(':')
      item = Shadowcraft.ServerData.ITEM_LOOKUP2[itemString]

    if not item?
      console.warn "item not found: #{itemId}"

    return item

  getItem: (itemId, ilvl) ->
    return getItem(itemId, ilvl)

  getMaxUpgradeLevel = (item) ->
    return 2

  getUpgradeLevelSteps = (item) ->
    return 5

  needsDagger = ->
    Shadowcraft.Data.activeSpec == "a"

  recalculateStatsDiff = (original, ilvl_difference) ->
    stats = {}
    for k,v of original
      if k != 'agility' and k != 'stamina'
        multiplier = Math.pow(1.0037444020662509239443726693104, ilvl_difference.toFixed(2))
        stats[k] = v * multiplier
      else
        multiplier =  1.0 / Math.pow(1.15, (ilvl_difference.toFixed(2) / -15.0))
        stats[k] = v * multiplier
    return stats

  recalculateStats = (original, old_ilvl, new_ilvl) ->
    recalculateStatsDiff(original, new_ilvl-old_ilvl)

  # Called when a user clicks on the name in a slot. This opens a popup with
  # a list of items.
  clickSlotName = ->
    buf = clickSlot(this, "item_id")
    $slot = buf[0]
    slot = buf[1]
    selected_id = $slot.data("identifier")
    selected_ilvl = selected_id.split(":")[1]

    equip_location = SLOT_INVTYPES[slot]
    GemList = Shadowcraft.ServerData.GEMS

    gear = Shadowcraft.Data.gear
    equipped = gear[slot]

    requireDagger = needsDagger()
    subtletyNeedsDagger = Shadowcraft.Data.activeSpec == "b" && Shadowcraft.Data.options.rotation.use_hemorrhage in ['uptime','never']

    loc_all = Shadowcraft.ServerData.SLOT_CHOICES[equip_location]
    loc = []

    # Filter the list of items down to a specific subset. There are some extra
    # criteria for hiding items as well, beyond just simple slot numbers.
    for lid in loc_all
      l = ShadowcraftData.ITEM_LOOKUP2[lid]
      if lid == selected_id # always show equipped item
        loc.push l

        # If the equipped item has WF/TF bonus ID on it, generate a second item
        # and add it to the list. This way the base item and the WF/TF item
        # will both display.
        hasUpgrade = false
        bonuses = $(equipped.bonuses).not(l.bonus_tree).get()
        for bonus in bonuses
          continue if bonus == "" or bonus not in ShadowcraftData.ITEM_BONUSES
          for entry in ShadowcraftData.ITEM_BONUSES[bonus]
            if entry.type == 1
              hasUpgrade = true
              break
          if hasUpgrade
            break

        if (hasUpgrade)
          clone = $.extend({}, l)
          clone.identifier = ""+clone.id+":"+equipped.item_level
          clone.ilvl = equipped.item_level
          clone.bonus_tree = equipped.bonuses
          clone.tag = makeTag(equipped.bonuses)
          clone.stats = recalculateStats(l.stats, l.ilvl, equipped.item_level)
          clone.upgrade_level = equipped.upgrade_level
          loc.push clone

          # Modify the selected identifier so that the right item will be selected
          # in the list.
          selected_id = clone.identifier

        continue

      # Don't display all of the different versions of the legendary ring.
      continue if l.id == 124636

      # Filter weapons to only display the artifact for the current spec and the
      # correct hand.
      if slot == 15
        continue if Shadowcraft.Data.activeSpec == "a" and l.id != 128870
        continue if Shadowcraft.Data.activeSpec == "Z" and l.id != 128872
        continue if Shadowcraft.Data.activeSpec == "b" and l.id != 128476
      if slot == 16
        continue if Shadowcraft.Data.activeSpec == "a" and l.id != 128869
        continue if Shadowcraft.Data.activeSpec == "Z" and l.id != 134552
        continue if Shadowcraft.Data.activeSpec == "b" and l.id != 128479

      # Filter out items that are outside the min and max ilvls set on the options
      # panel. Only do this for non-weapons though, so someone can always select their
      # artifact weapon. Also only do this if there's something actually equipped or
      # it will filter out everything.
      if (Shadowcraft.Data.options.general.dynamic_ilvl and equipped and slot != 15 and slot != 16 and equipped.id != 0)
        continue if l.ilvl < equipped.item_level-50 or l.ilvl > equipped.item_level+50
      else
        continue if l.ilvl > Shadowcraft.Data.options.general.max_ilvl
        continue if l.ilvl < Shadowcraft.Data.options.general.min_ilvl

      continue if (slot == 15 || slot == 16) && requireDagger && l.subclass != 15
      continue if (slot == 15) && subtletyNeedsDagger && l.subclass != 15

      # prevent unique-equippable items from showing up when it's already equipped
      # in another slot. this is mostly trinkets (slots 12 and 13) or legendary
      # and pvp rings (slots 10 and 11)
      continue if slot == 12 && l.id == gear[13].id
      continue if slot == 13 && l.id == gear[12].id

      # For pvp rings, it's if a ring has a tag and the tag either ends with
      # Tournament or "Season #", and the tag matches the currently equipped one
      # in the other slot, and the item ID matches the one in the other slot.
      # Skip those items.
      # TODO: this may be broken and requires some testing from someone who
      # actually gives two shits about PVP to tell me that.
      continue if slot == 10 && l.tag? && (/Tournament$/.test(l.tag) || /Season [0-9]$/.test(l.tag)) && l.tag == gear[11].tag && l.name == gear[11].name
      continue if slot == 11 && l.tag? && (/Tournament$/.test(l.tag) || /Season [0-9]$/.test(l.tag)) && l.tag == gear[10].tag && l.name == gear[10].name
      loc.push l

    gear_offset = statOffset(gear[slot], FACETS.ITEM)
    gem_offset = statOffset(gear[slot], FACETS.GEMS)
    epSort(GemList) # Needed for gemming recommendations

    setBonEP = {}
    for set_name, set of ShadowcraftConstants.SETS
      setCount = getEquippedSetCount(set.ids, equip_location)
      setBonEP[set_name] ||= 0
      setBonEP[set_name] += setBonusEP(set, setCount)

    for l in loc
      l.__setBonusEP = 0
      for set_name, set of ShadowcraftConstants.SETS
        if set.ids.indexOf(l.id) >= 0
          l.__setBonusEP += setBonEP[set_name]

      l.__gearEP = getEP(l, slot, gear_offset)
      l.__gearEP = 0 if isNaN l.__gearEP
      l.__setBonusEP = 0 if isNaN l.__setBonusEP
      l.__ep = l.__gearEP + l.__setBonusEP

    loc.sort(sortComparator)
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

      ctxtKeys = []
      if l.ctxts
        ctxtKeys = Object.keys(l.ctxts)

      continue if l.__ep < 1 and !("trade-skill" in ctxtKeys)
      iEP = l.__ep

      ttid = l.id
      ttrand = if l.suffix? then l.suffix else ""
      ttupgd = if l.upgradable then l.upgrade_level else ""

      ttbonus = ""
      if ctxtKeys.length > 0
        ttbonus = l.ctxts[ctxtKeys[0]].defaultBonuses.join(":")

      if l.identifier == selected_ilvl
        bonus_trees = gear[slot].bonuses
        ttbonus = bonus_trees.join(":")
      upgrade = []
      if l.upgradable
        curr_level = "0"
        curr_level = l.upgrade_level.toString() if l.upgrade_level?
        max_level = getMaxUpgradeLevel(l)
        upgrade =
          curr_level: curr_level
          max_level: max_level
      tags = []
      for key,ctx of l.ctxts
        if ctx.tag.length > 0
          tags.push ctx.tag
      tags.sort()
      tags = _.uniq(tags, true)

      buffer += Templates.itemSlot(
        item: l
        tag: l.tag
        identifier: l.id + ":" + l.ilvl
        gear: {}
        gems: []
        upgradable: l.upgradable
        upgrade: upgrade
        ttid: l.id
        ttupgd: if l.upgradable then l.upgrade_level else ""
        ttbonus: ttbonus
        quality: l.quality
        desc: "#{l.__gearEP.toFixed(1)} base #{if l.__setBonusEP > 0 then "/ "+ l.__setBonusEP.toFixed(1) + " set" else ""} "
        search: escape(l.name + " " + l.tag)
        percent: Math.max (l.__ep - minIEP) / maxIEP * 100, 0.01
        ep: l.__ep.toFixed(1)
        display_ilvl: true
        tags: tags.join(" / ")
      )

    buffer += Templates.itemSlot(
      item: {name: "[No item]"}
      desc: "Clear this slot"
      percent: 0
      ep: 0
    )

    $popupbody.get(0).innerHTML = buffer

    selected = $popupbody.find(".slot[data-identifier='#{selected_id}']")
    selected.addClass("active")
    showPopup($popup)
    false

  # Called when a user clicks on an enchant section in an item. This opens a
  # popup with a list of applicable enchants for the item.
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
    item = getItem(gear.id, gear.base_ilvl)
    for enchant in enchants
      enchant.__ep = getEP(enchant, slot, offset)
      enchant.__ep = 0 if isNaN enchant.__ep
      max = if enchant.__ep > max then enchant.__ep else max
    enchants.sort(sortComparator)
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
        ttid: enchant.tooltip_spell
        display_ilvl: false
      )

    buffer += Templates.itemSlot(
      item: {name: "[No enchant]"}
      desc: "Clear this enchant"
      percent: 0
      ep: 0
    )

    $popupbody.get(0).innerHTML = buffer
    $popupbody.find(".slot[id='#{selected_id}']").addClass("active")
    showPopup($popup)
    false

  # Gets the base item level of an item before all upgrades
  getBaseItemLevel = (item) ->
    unless item.upgrade_level
      return item.ilvl
    return item.ilvl - getUpgradeLevelSteps(item) * item.upgrade_level

  # Called when a user clicks on a gem section in an item. This opens a
  # popup with a list of applicable gems for the item.
  clickSlotGem = ->
    GemList = Shadowcraft.ServerData.GEMS
    data = Shadowcraft.Data

    buf = clickSlot(this, "gem")
    $slot = buf[0]
    slot = buf[1]
    gemSlot = $slot.find(".gem").index(this)
    $.data(document.body, "gem-slot", gemSlot)
    selected_gem_id = data.gear[slot].gems[gemSlot]

    otherGearGems = []
    for i in [0..2]
      continue if i == gemSlot
      if data.gear[slot].gems[i]
        otherGearGems.push data.gear[slot].gems[i]

    for gem in GemList
      gem.__ep = getEP(gem)
    GemList.sort(sortComparator)

    buffer = ""
    usedNames = {}
    max = null
    for gem in GemList
      if usedNames[gem.name]
        if gem.id == selected_gem_id
          selected_gem_id = usedNames[gem.name]
        continue

      usedNames[gem.name] = gem.id
      continue if gem.name.indexOf("Perfect") == 0 and selected_gem_id != gem.id
      continue unless canUseGem(gem)
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
        display_ilvl: false

    buffer += Templates.itemSlot(
      item: {name: "[No gem]"}
      desc: "Clear this gem"
      percent: 0
      ep: 0
    )

    $popupbody.get(0).innerHTML = buffer
    $popupbody.find(".slot[id='" + selected_gem_id + "']").addClass("active")
    showPopup($popup)
    false

  # Called when a user clicks on the bonuses section in an item. This opens a
  # popup with a set of checkboxes to allow a user to add bonuses (tertiary
  # stats, sockets).
  clickSlotBonuses = ->
    clickSlot(this, "bonuses")
    $(".slot").removeClass("active")
    $(this).addClass("active")
    data = Shadowcraft.Data

    $slot = $(this).closest(".slot")
    slot = parseInt($slot.data("slot"), 10)
    $.data(document.body, "selecting-slot", slot)

    gear = data.gear[slot]
    currentBonuses = gear.bonuses
    item = getItem(gear.id, gear.base_ilvl)

    # Calculate this here so that if the item supports WF/TF we can use
    # the value to display the upgrade difference.
    gear_stats = []
    sumGearItem(gear_stats, gear)
    base_item_ep = getEPForStatBlock(gear_stats)

    # Check if one of the bonus IDs currently on the gear is a WF/TF
    current_tf_id = 0
    current_tf_value = 0
    for bonusId in currentBonuses
      if bonusId in ShadowcraftConstants.WF_BONUS_IDS
        current_tf_id = bonusId
        for val in Shadowcraft.ServerData.ITEM_BONUSES[current_tf_id]
          if val.type == 1
            current_tf_value = val.val1

    # TODO build all possible bonuses with status selected or not, etc.
    groups = {
      suffixes: []
      tertiary: []
      sockets: []
      titanforged: []
    }

    for bonusId in item.chance_bonus_lists
      continue if bonusId == -1
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
          when 6 # extra sockets
            group['entries'].push entry
            gem = getBestNormalGem()
            group.ep += getEP(gem)
            subgroup = "sockets"
          when 5 # item name suffix
            group['entries'].push entry
            subgroup = "suffixes"
          when 2 # tertiary stats
            entry['val2'] = Math.round(bonus_entry.val2 / 10000 * Shadowcraft.ServerData.RAND_PROP_POINTS[item.ilvl][1 + getRandPropEntry(slot)])
            entry['val1'] = bonus_entry.val1
            group['entries'].push entry
            group.ep += getStatWeight(entry.val1, entry.val2)
            subgroup = "tertiary" unless subgroup?
      if subgroup?
        group.ep = group.ep.toFixed(2)
        groups[subgroup].push group
        groups[subgroup+"_active"] = true

    # Check whether there are any "base item level" bonus IDs on the default list for
    # this item. These ones don't show up in the chance bonus lists becasue they're a
    # fixed ID for each item difficulty.
    wf_base = 0
    steps = []
    if item.quality == 5
      wf_base = 910
      steps = [6]
    else
      for bonusId in item.ctxts[gear.context].defaultBonuses
        break if wf_base != 0
        if bonusId == -1
          wf_base = gear.base_ilvl
        else
          for bonus_entry in Shadowcraft.ServerData.ITEM_BONUSES[bonusId]
            if bonus_entry.type == 14
              wf_base = gear.base_ilvl
      steps = [1..(ShadowcraftConstants.CURRENT_MAX_ILVL - wf_base) / 5]

    # If we found an entry for a base item level, we need to generate a bunch of
    # entries for upgrades and insert them into the titanforged subgroup. Only do this
    # if the current maximum ilevel is less than the base ilevel of this item.
    if wf_base != 0 and wf_base < ShadowcraftConstants.CURRENT_MAX_ILVL
      for step in steps
        ilvl_bonus = step*5
        group = {}
        # 1472 would be the "0" point in the item upgrade bonus IDs, if it existed.
        group['bonusId'] = ilvl_bonus+1472
        group['active'] = (current_tf_id == group['bonusId'])
        temp_stats = []
        sumItem(temp_stats, item['stats'], ilvl_bonus-current_tf_value)
        temp_ep = getEPForStatBlock(temp_stats)
        group.ep = (temp_ep-base_item_ep).toFixed(2)
        entry = {}
        entry['type'] = 1
        entry['val1'] = "+"+(ilvl_bonus)+" Item Levels "
        if item.quality != 5
          if step <= 2
            entry['val1'] += "(Warforged)"
          else
            entry['val1'] += "(Titanforged)"
        entry['val2'] = "Item Level " + (wf_base+ilvl_bonus)
        group['entries'] = []
        group['entries'].push entry
        groups['titanforged'].push group

    # If any wf/tf entries were added to that subgroup, add a "None" item
    # as well.
    if groups['titanforged'].length != 0
      group = {}
      subgroup = 'titanforged'
      group['bonusId'] = 0 # This ends up leaving the value unset
      group['active'] = (current_tf_id == 0)
      if current_tf_value == 0
        group['ep'] = "0.00"
      else
        temp_stats = []
        sumItem(temp_stats, item['stats'], -current_tf_value)
        temp_ep = getEPForStatBlock(temp_stats)
        group['ep'] = (temp_ep-base_item_ep).toFixed(2)
      group['entries'] = []
      entry = {
        'type': 1
        'val1': "None "
        'val2': "Item Level " + wf_base
      }
      group['entries'].push entry
      groups['titanforged'].push group
      groups[subgroup+"_active"] = true

    for key,subgroup of groups
      continue unless _.isArray(subgroup)
      subgroup.sort (a, b) ->
        b.ep - a.ep
    $.data(document.body, "bonuses-item", item)
    $("#bonuses").html Templates.bonuses
      groups: groups
    Shadowcraft.setupLabels("#bonuses")
    showPopup $("#bonuses.popup")
    false

  # Called when a user clicks on the wowhead icon in an item. This cancels the
  # event to allow the URL clicked to open.
  clickWowhead = (e) ->
    e.stopPropagation()
    true

  # Called when a user clicks on the upgrade arrow in an item.
  clickItemUpgrade = (e) ->
    e.stopPropagation()
    buf = clickSlot(this, "item_id")
    slot = buf[1]

    data = Shadowcraft.Data

    gear = data.gear[slot]
    item = getItem(gear.id, gear.base_ilvl)
    max = getMaxUpgradeLevel(item)
    if (!gear.upgrade_level)
      gear.upgrade_level = 0
    if (gear.upgrade_level == max)
      gear.item_level -= getUpgradeLevelSteps(item) * max
      gear.upgrade_level = 0
    else
      gear.item_level += getUpgradeLevelSteps(item)
      gear.upgrade_level += 1
    Shadowcraft.update()
    Shadowcraft.Gear.updateDisplay()
    true

  # Called when a user clicks on the lock icon for an item.
  clickItemLock = (e) ->
    e.stopPropagation()
    buf = clickSlot(this, "item_id")
    slot = buf[1]

    data = Shadowcraft.Data

    gear = data.gear[slot]
    gear.locked ||= false
    data.gear[slot].locked = not gear.locked
    item = getItem(gear.id, gear.base_ilvl)
    if item
      if data.gear[slot].locked
        Shadowcraft.Console.log("Locking " + item.name + " for Optimize Gems")
      else
        Shadowcraft.Console.log("Unlocking " + item.name + " for Optimize Gems")
    Shadowcraft.Gear.updateDisplay()
    true

  boot: ->
    app = this
    $slots = $(".slots")
    $popup = $("#gearpopup")
    $popupbody = $("#gearpopup .body")

    # Register for the recompute event sent by the backend. This updates some
    # of the display with the latest information from the last calculation pass.
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
        $this.attr("checked", not $this.attr("checked")?)
        Shadowcraft.setupLabels("#bonuses")
      ".applyBonuses" : this.applyBonuses

    # Register the callback handlers for all of the various parts of each item
    # on the UI.
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

    $("#gearpopup .body").bind "mousewheel", (event) ->
      if (event.wheelDelta < 0 and this.scrollTop + this.clientHeight >= this.scrollHeight) or event.wheelDelta > 0 and this.scrollTop == 0
        event.preventDefault()
        return false

    $("#gear .slots").mousemove (e) ->
      $.data document, "mouse-x", e.pageX
      $.data document, "mouse-y", e.pageY

    # Register a callback for when a user clicks on an item in one of the
    # popup windows.
    $popupbody.click $.delegate
      ".slot" : (e) ->
        Shadowcraft.Console.purgeOld()
        data = Shadowcraft.Data

        slot = $.data(document.body, "selecting-slot")
        update = $.data(document.body, "selecting-prop")
        $this = $(this)
        slotGear = data.gear[slot]

        if update == "item_id" || update == "enchant"
          val = parseInt($this.attr("id"), 10)
          identifier = $this.data("identifier")
          if update == "item_id"
            idparts = identifier.split(":")
            item_id = parseInt(idparts[0])
            base_ilvl = parseInt(idparts[1])

            if (slot == 15 or slot == 16) and item_id in ShadowcraftConstants.ARTIFACTS
              data.gear[15].id = ShadowcraftConstants.ARTIFACT_SETS[Shadowcraft.Data.activeSpec].mh
              data.gear[15].item_level = parseInt(idparts[1])
              data.gear[15].context = ""
              data.gear[15].upgrade_level = 0
              data.gear[15].bonuses = []
              data.gear[15].enchant = 0
              data.gear[16].id = ShadowcraftConstants.ARTIFACT_SETS[Shadowcraft.Data.activeSpec].oh
              data.gear[16].item_level = parseInt(idparts[1])
              data.gear[16].context = ""
              data.gear[16].upgrade_level = 0
              data.gear[16].bonuses = []
              data.gear[16].enchant = 0
              Shadowcraft.Artifact.updateArtifactItem(data.gear[15].id, data.gear[15].item_level, data.gear[15].item_level)
            else
              if (item_id)
                item = getItem(item_id, base_ilvl)
                slotGear.id = item_id
                slotGear.item_level = base_ilvl
                slotGear.base_ilvl = base_ilvl
                slotGear.quality = parseInt($this.data("quality"))
                upgd_level = parseInt($this.data("upgrade"))
                slotGear.upgrade_level = if not isNaN(upgd_level) then upgd_level else 0

                # Get the first key from the set of contexts for this item
                context = Object.keys(item.ctxts)[0]
                if (context)
                  slotGear.context = context
                  slotGear.bonuses = item.ctxts[context].defaultBonuses
              else
                slotGear.id = 0
                slotGear.item_level = 0
                slotGear.base_ilvl = 0
                slotGear.enchant = 0
                slotGear.upgrade_level = 0
                slotGear.context = ""
                slotGear.bonuses = []
              slotGear.gems = [0,0,0]
          else
            enchant_id = if not isNaN(val) then val else null
            item = getItem(slotGear.id, slotGear.base_ilvl)
            if enchant_id?
              Shadowcraft.Console.log("Changing " + item.name + " enchant to " + Shadowcraft.ServerData.ENCHANT_LOOKUP[enchant_id].name)
            else
              Shadowcraft.Console.log("Removing Enchant from " + item.name)
            slotGear.enchant = enchant_id
        else if update == "gem"
          item_id = parseInt($this.attr("id"), 10)
          item_id = if not isNaN(item_id) then item_id else null
          gem_id = $.data(document.body, "gem-slot")
          item = getItem(slotGear.id, slotGear.base_ilvl)
          if item_id?
            Shadowcraft.Console.log("Regemming " + item.name + " socket " + (gem_id + 1) + " to " + Shadowcraft.ServerData.GEM_LOOKUP[item_id].name)
          else
            Shadowcraft.Console.log("Removing Gem from " + item.name + " socket " + (gem_id + 1))
          slotGear.gems[gem_id] = item_id
        Shadowcraft.update()
        app.updateDisplay()

    # Register a bunch of key bindings for the popup windows so that a user
    # can move up and down in the list with the keyboard, plus select items
    # with the enter key.
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

    # Bind to the update event from the Options tab for changes that affect the
    # Gear tab.
    Shadowcraft.Options.bind "update", (opt, val) ->
      if opt in ['rotation.cp_builder','rotation.blade_flurry','general.num_boss_adds','general.lethal_poison']
        app.updateSummaryWindow()

    this.updateDisplay()

    checkForWarnings('options')
    @initialized = true

    this

  constructor: (@app) ->

window.ShadowcraftGear = ShadowcraftGear
