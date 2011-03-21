class ShadowcraftGear
  MAX_JEWELCRAFTING_GEMS = 3
  MAX_ENGINEERING_GEMS = 1
  JC_ONLY_GEMS = ["Dragon's Eye", "Chimera's Eye"]
  REFORGE_FACTOR = 0.4
  DEFAULT_BOSS_DODGE = 6.5

  # Relative value of expertise per hand; both should add up to 1.
  MH_EXPERTISE_FACTOR = 0.63
  OH_EXPERTISE_FACTOR = 1 - MH_EXPERTISE_FACTOR

  REFORGE_STATS = [
    # {key: "spirit", val: "Spirit"}
    {key: "expertise_rating", val: "Expertise"}
    {key: "hit_rating", val: "Hit"}
    {key: "haste_rating", val: "Haste"}
    {key: "crit_rating", val: "Crit"}
    {key: "mastery_rating", val: "Mastery"}
  ]
  REFORGABLE = ["spirit", "dodge_rating", "parry_rating", "hit_rating", "crit_rating", "haste_rating", "expertise_rating", "mastery_rating"]
  @REFORGABLE = REFORGABLE
  REFORGE_CONST = 112
  SLOT_ORDER = ["0", "1", "2", "14", "4", "8", "9", "5", "6", "7", "10", "11", "12", "13", "15", "16", "17"]
  SLOT_DISPLAY_ORDER = [["0", "1", "2", "14", "4", "8", "15", "16"], ["9", "5", "6", "7", "10", "11", "12", "13", "17"]]
  PROC_ENCHANTS =
    4099: "landslide"
    4083: "hurricane"

  @CHAOTIC_METAGEMS = [52291, 34220, 41285, 68778, 68780, 41398, 32409, 68779]

  Weights =
    attack_power: 1
    agility: 2.66
    crit_rating: 0.87
    spell_hit: 1.3
    hit_rating: 1.02
    expertise_rating: 1.51
    haste_rating: 1.44
    mastery_rating: 1.15
    yellow_hit: 1.79
    strength: 1.05

  getWeights: ->
    Weights

  SLOT_INVTYPES =
      0: 1
      1: 2
      2: 3
      14: 16
      4: 5
      8: 9
      9: 10
      5: 6
      6: 7
      7: 8
      10: 11
      11: 11
      12: 12
      13: 12
      15: "mainhand"
      16: "offhand"
      17: "ranged"

  EP_PRE_REGEM = null
  EP_PRE_REFORGE = null
  EP_TOTAL = null
  $slots = null
  $altslots = null
  $popup = null

  statOffset = (gear) ->
    statOffset = {}
    if gear
      sumSlot(gear, statOffset, false)
    return statOffset

  reforgeAmount = (item, stat) ->
    Math.floor(item.stats[stat] * REFORGE_FACTOR)

  getReforgeFrom = (n) ->
    base = n - REFORGE_CONST - 1
    from = Math.floor(base / 7)
    return REFORGABLE[from]

  getReforgeTo = (n) ->
    base = n - REFORGE_CONST - 1
    from = Math.floor(base / 7)
    to = base % 7
    to++ if from <= to
    return REFORGABLE[to]

  reforgeToHash = (ref, amt) ->
    return {} if !ref or ref == 0
    r = {}
    r[getReforgeFrom(ref)] = -amt
    r[getReforgeTo(ref)] = amt
    r

  compactReforge = (from, to) ->
    f = REFORGABLE.indexOf(from)
    t = REFORGABLE.indexOf(to)
    t++ if t < f
    return REFORGE_CONST + (f * 7) + t

  # console.log getReforgeFrom(161), getReforgeTo(161), "should be expertise to mastery"
  # console.log getReforgeFrom(113), getReforgeTo(113), "should be spirit to dodge"
  # console.log getReforgeFrom(134), getReforgeTo(134), "should be hit to spirit"
  # console.log compactReforge("spirit", "dodge_rating"), "should be 113"
  # console.log compactReforge("hit_rating", "spirit"), "should be 134"

  sumItem = (s, i, key) ->
    key ||= "stats"
    for stat of i[key]
      s[stat] ||= 0
      s[stat] += i[key][stat]
    null

  sumRecommendation = (s, rec) ->
    s[rec.source.key] ||= 0
    s[rec.source.key] += rec.qty
    s[rec.dest.key] ||= 0
    s[rec.dest.key] += rec.qty

  get_ep = (item, key, slot) ->
    data = Shadowcraft.Data
    weights = Weights

    stats = {}
    if item.source and item.dest
      sumRecommendation(stats, item)
    else
      sumItem(stats, item, key)

    total = 0
    for stat, value of stats
      weight = Weights[stat] || 0
      total += value * weight

    delete stats
    c = Shadowcraft.lastCalculation
    if c
      if item.dps
        if slot == 15
          total += (item.dps * c.mh_ep.mh_dps) + (item.speed * c.mh_speed_ep["mh_" + item.speed])
          total += racialExpertiseBonus(item) * Weights.expertise_rating
        else if slot == 16
          total += (item.dps * c.oh_ep.oh_dps) + (item.speed * c.oh_speed_ep["oh_" + item.speed])
          total += racialExpertiseBonus(item) * Weights.expertise_rating
      else if ShadowcraftGear.CHAOTIC_METAGEMS.indexOf(item.id) >= 0
        total += c.meta.chaotic_metagem
      else if PROC_ENCHANTS[item.id]
        switch slot
          when 15
            pre = "mh_"
          when 16
            pre = "oh_"
        enchant = PROC_ENCHANTS[item.id]
        if pre and enchant
          total += c[pre + "ep"][pre + enchant]
      else if c.trinket_ranking[item.id]
        total += c.trinket_ranking[item.id]

    total

  sumReforge = (stats, item, reforge) ->
    from = getReforgeFrom(reforge)
    to = getReforgeTo(reforge)
    amt = reforgeAmount(item, from)
    stats[from] ||= 0
    stats[from] -= amt
    stats[to] ||= 0
    stats[to] += amt

  sumSlot = (gear, out, excludeReforges) ->
    return unless gear?.item_id?

    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP
    Gems = Shadowcraft.ServerData.GEM_LOOKUP
    EnchantLookup = Shadowcraft.ServerData.ENCHANT_LOOKUP

    item = ItemLookup[gear.item_id]
    return unless item?

    sumItem(out, item)
    matchesAllSockets = item.sockets and item.sockets.length > 0
    for socketIndex, socket of item.sockets
        gid = gear["g" + socketIndex]
        if gid and gid > 0
          gem = Gems[gid]
          sumItem(out, gem) if(gem)
        matchesAllSockets = false if !gem or !gem[socket]

    if matchesAllSockets
      sumItem(out, item, "socketbonus")

    if gear.reforge and not excludeReforges
      sumReforge(out, item, gear.reforge)

    enchant_id = gear.enchant
    if enchant_id and enchant_id > 0
      enchant = EnchantLookup[enchant_id]
      sumItem(out, enchant) if enchant


  sumStats: (excludeReforges) ->
    stats = {}
    data = Shadowcraft.Data

    for si, i in SLOT_ORDER
      sumSlot(data.gear[si], stats, excludeReforges)

    @statSum = stats
    return stats

  racialExpertiseBonus = (item, mh_type) ->
    return 0 unless item? or mh_type?
    if item?
      mh_type = item.subclass

    if mh_type instanceof Array
      m = 0
      for t in mh_type
        n = racialExpertiseBonus(null, t)
        m = if n > m then n else m
      return m

    race = Shadowcraft.Data.options.general.race

    if(race == "Human" && (mh_type == 7 || mh_type == 4))
      Shadowcraft._R("expertise_rating") * 3
    else if(race == "Gnome" && (mh_type == 7 || mh_type == 15))
      Shadowcraft._R("expertise_rating") * 3
    else if(race == "Dwarf" && (mh_type == 4))
      Shadowcraft._R("expertise_rating") * 3
    else if(race == "Orc" && (mh_type == 0 || mh_type == 13))
      Shadowcraft._R("expertise_rating") * 3
    else
      0

  racialHitBonus = (key) ->
    if Shadowcraft.Data.race == "Draenei" then Shadowcraft._R(key) else 0

  getStat: (stat) ->
    this.sumStats() if !@statSum
    (@statSum[stat] || 0)

  getDodge: (hand) ->
    data = Shadowcraft.Data
    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP
    expertise = @statSum.expertise_rating
    boss_dodge = DEFAULT_BOSS_DODGE
    if (!hand? or hand == "main") and data.gear[15] and data.gear[15].item_id
      expertise += racialExpertiseBonus(ItemLookup[data.gear[15].item_id])
    else if (hand == "off") and data.gear[16] and data.gear[16].item_id
      expertise += racialExpertiseBonus(ItemLookup[data.gear[16].item_id])
    return DEFAULT_BOSS_DODGE - (expertise / Shadowcraft._R("expertise_rating") * 0.25)

  getHitEP = ->
    yellowHitCap = Shadowcraft._R("hit_rating") * (8 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating")
    spellHitCap = Shadowcraft._R("spell_hit")  * (17 - 2 * Shadowcraft._T("precision")) - racialHitBonus("spell_hit")
    whiteHitCap = Shadowcraft._R("hit_rating") * (27 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating")
    exist = Shadowcraft.Gear.getStat("hit_rating")
    if exist < yellowHitCap
      Weights.yellow_hit
    else if exist < spellHitCap
      Weights.spell_hit
    else if exist < whiteHitCap
      Weights.hit_rating
    else
      0

  getCaps: ->
    data = Shadowcraft.Data
    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP

    exp_base = Shadowcraft._R("expertise_rating") * DEFAULT_BOSS_DODGE * 4
    caps =
      yellow_hit: Shadowcraft._R("hit_rating") * (8 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating")
      spell_hit: Shadowcraft._R("spell_hit")  * (17 - 2 * Shadowcraft._T("precision")) - racialHitBonus("spell_hit")
      white_hit: Shadowcraft._R("hit_rating") * (27 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating")
      mh_exp: 791
      oh_exp: 791
    if data.gear[15]
      caps.mh_exp = exp_base - racialExpertiseBonus(ItemLookup[data.gear[15].item_id])
    if data.gear[16]
      caps.oh_exp = exp_base - racialExpertiseBonus(ItemLookup[data.gear[16].item_id])
    caps

  getMiss: (cap) ->
    data = Shadowcraft.Data
    switch cap
      when "yellow"
        r = Shadowcraft._R("hit_rating")
        hitCap = r * (8 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating")
      when "spell"
        r = Shadowcraft._R("spell_hit")
        hitCap = r * (17 - 2 * Shadowcraft._T("precision")) - racialHitBonus("spell_hit")
      when "white"
        r = Shadowcraft._R("hit_rating")
        hitCap = r * (27 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating")
    if r? and hitCap?
      hasHit = @statSum.hit_rating || 0
      if hasHit < hitCap or cap == "white"
        return (hitCap - hasHit) / r
      else
        return 0
    return -99

  # TODO: Adjust for racial bonuses.
  # Stat to get the real weight for, the amount of the stat, and a hash of {stat: amount} to ignore (like if swapping out a reforge or whatnot; nil the existing reforge for calcs)
  getStatWeight = (stat, num, ignore, ignoreAll) ->
    data = Shadowcraft.Data
    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP

    exist = 0
    unless ignoreAll
      exist = Shadowcraft.Gear.getStat(stat)
      if ignore and ignore[stat]
        exist -= ignore[stat]

    neg = if num < 0 then -1 else 1
    num = Math.abs(num)

    switch(stat)
      when "expertise_rating"
        boss_dodge = DEFAULT_BOSS_DODGE
        mhCap = Shadowcraft._R("expertise_rating") * boss_dodge * 4
        ohCap = mhCap
        if data.gear[15] and data.gear[15].item_id
          mhCap -= racialExpertiseBonus(ItemLookup[data.gear[15].item_id])
        if data.gear[16] and data.gear[16].item_id
          ohCap -= racialExpertiseBonus(ItemLookup[data.gear[16].item_id])

        total = 0
        if mhCap > exist
          usable = mhCap - exist
          usable = num if usable > num
          total += usable * Weights.expertise_rating * MH_EXPERTISE_FACTOR
        if ohCap > exist
          usable = ohCap - exist
          usable = num if usable > num
          total += usable * Weights.expertise_rating * OH_EXPERTISE_FACTOR

        return total * neg
      when "hit_rating"
        yellowHitCap = Shadowcraft._R("hit_rating") * (8 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating")
        spellHitCap = Shadowcraft._R("spell_hit")  * (17 - 2 * Shadowcraft._T("precision")) - racialHitBonus("spell_hit")
        whiteHitCap = Shadowcraft._R("hit_rating") * (27 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating")

        total = 0
        remaining = num
        if remaining > 0 and exist < yellowHitCap
          delta = if (yellowHitCap - exist) > remaining then remaining else (yellowHitCap - exist)
          total += delta * Weights.yellow_hit
          remaining -= delta
          exist += delta

        if remaining > 0 and exist < spellHitCap
          delta = if (spellHitCap - exist) > remaining then remaining else (spellHitCap - exist)
          total += delta * Weights.spell_hit
          remaining -= delta
          exist += delta

        if remaining > 0 && exist < whiteHitCap
          delta = if (whiteHitCap - exist) > remaining then remaining else (whiteHitCap - exist)
          total += delta * Weights.hit_rating
          remaining -= delta
          exist += delta

        return total * neg

    return (Weights[stat] || 0) * num * neg

  __epSort = (a, b) ->
    b.__ep - a.__ep

  epSort = (list, skipSort, slot) ->
    for item in list
      item.__ep = get_ep(item, false, slot) if item
    list.sort(__epSort) unless skipSort

  needsDagger = ->
    Shadowcraft.Data.tree0 >= 31 || Shadowcraft.Data.tree2 >= 31

  isProfessionalGem = (gem, profession) ->
    gem.requires?.profession? and gem.requires.profession == profession

  getEquippedGemCount = (gem, pendingChanges, ignoreSlotIndex) ->
    count = 0
    for slot in SLOT_ORDER
      continue if slot == ignoreSlotIndex
      gear = Shadowcraft.Data.gear[slot]
      if gem.id == gear.g0 or gem.id == gear.g1 or gem.id == gear.g2
        count++
    if pendingChanges?
      for g in pendingChanges
        count++ if g == gem.id
    return count

  getProfessionalGemCount = (profession, pendingChanges, ignoreSlotIndex) ->
    count = 0
    Gems = Shadowcraft.ServerData.GEM_LOOKUP

    for slot in SLOT_ORDER
      continue if slot == ignoreSlotIndex
      gear = Shadowcraft.Data.gear[slot]
      for i in [0..2]
        gem = gear["g" + i]? and Gems[gear["g" + i]]
        continue unless gem
        if isProfessionalGem(gem, profession)
          count++

    if pendingChanges?
      for g in pendingChanges
        count++ if isProfessionalGem(g, profession)

    return count

  canUseGem = (gem, gemType, pendingChanges, ignoreSlotIndex) ->
    if gem.requires?.profession?
      return false unless Shadowcraft.Data.options.professions[gem.requires.profession]
      return false if isProfessionalGem(gem, 'jewelcrafting') and getProfessionalGemCount('jewelcrafting', pendingChanges, ignoreSlotIndex) >= MAX_JEWELCRAFTING_GEMS
      return false if isProfessionalGem(gem, 'engineering') and getEquippedGemCount(gem, pendingChanges, ignoreSlotIndex) >= MAX_ENGINEERING_GEMS

    return false if (gemType == "Meta" or gemType == "Cogwheel") and gem.slot != gemType
    return false if (gem.slot == "Meta" or gem.slot == "Cogwheel") and gem.slot != gemType
    true

  # Returns the EP value of a gem.  If it happens to require JC, it'll return
  # the regular EP value for the same quality gem, if found.
  getRegularGemEpValue = (gem) ->
    equiv_ep = gem.__ep || get_ep(gem)

    return equiv_ep # unless gem.requires?.profession?
    return gem.__reg_ep if gem.__reg_ep

    for name in JC_ONLY_GEMS
      if gem.name.indexOf(name) >= 0
        prefix = gem.name.replace(name, "")
        for j, reg of Shadowcraft.ServerData.GEMS
          if !reg.requires?.profession? and reg.name.indexOf(prefix) == 0 and reg.quality == gem.quality
            equiv_ep = reg.__ep || get_ep(reg)
            equiv_ep += 1
            gem.__reg_ep = equiv_ep
            return false
        return false
    return equiv_ep

  addTradeskillBonuses = (item) ->
    item.sockets ||= []
    blacksmith = Shadowcraft.Data.options.professions.blacksmithing
    if item.equip_location == 9 or item.equip_location == 10
      last = item.sockets[item.sockets.length - 1]
      if last != "Prismatic" and blacksmith
        item.sockets.push "Prismatic"
      else if !blacksmith and last == "Prismatic"
        item.sockets.pop()

  # Assumes gem_list is already sorted preferred order.  Also, normalizes
  # JC-only gem EP to their non-JC-only values to prevent the algorithm from
  # picking up those gems over the socket bonus.
  getGemmingRecommendation = (gem_list, item, returnFull, ignoreSlotIndex) ->
    data = Shadowcraft.Data
    if !item.sockets or item.sockets.length == 0
      if returnFull
        return {ep: 0, gems: []}
      else
        return 0

    straightGemEP = 0
    matchedGemEP = get_ep(item, "socketbonus")
    if returnFull
      sGems = []
      mGems = []

    for gemType in item.sockets
      for gem in gem_list
        continue unless canUseGem gem, gemType, sGems, ignoreSlotIndex
        straightGemEP += getRegularGemEpValue(gem)
        sGems.push gem.id if returnFull
        break

    for gemType in item.sockets
      for gem in gem_list
        continue unless canUseGem gem, gemType, mGems, ignoreSlotIndex
        if gem[gemType]
          matchedGemEP += getRegularGemEpValue(gem)
          mGems.push gem.id if returnFull
          break

    bonus = false
    if matchedGemEP > straightGemEP
      epValue = matchedGemEP
      gems = mGems
      bonus = true
    else
      epValue = straightGemEP
      gems = sGems

    if returnFull
      return {ep: epValue, takeBonus: bonus, gems: gems}
    else
      return epValue

  optimizeGems: (depth)->
    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP
    Gems = Shadowcraft.ServerData.GEM_LOOKUP
    data = Shadowcraft.Data

    depth ||= 0
    if depth == 0
      EP_PRE_REGEM = @getEPTotal()
      Shadowcraft.Console.log "Beginning auto-regem...", "gold underline"
    madeChanges = false
    gem_list = getGemRecommendationList()

    for slotIndex in SLOT_ORDER
      gear = data.gear[slotIndex]
      continue unless gear

      item = ItemLookup[gear.item_id]

      if item
        rec = getGemmingRecommendation(gem_list, item, true, slotIndex)
        for gem, gemIndex in rec.gems
          from_gem = Gems[gear["g#{gemIndex}"]]
          to_gem = Gems[gem]

          if gear["g#{gemIndex}"] != gem
            if from_gem && to_gem
              continue if from_gem.name == to_gem.name
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

  # Returns an EP-sorted list of gems with the twist that the
  # JC-only gems are sorted at the same EP-value as regular gems.
  # This prevents the automatic picking algorithm from choosing
  # JC-only gems over the slot bonus.
  getGemRecommendationList = ->
    Gems = Shadowcraft.ServerData.GEMS
    list = $.extend(true, [], Gems)
    list.sort (a, b) ->
      getRegularGemEpValue(b) - getRegularGemEpValue(a)
    list

  ###
  # Reforge helpers
  ###

  canReforge = (item) ->
    return false if item.ilvl < 200
    for stat of item.stats
      return true if REFORGABLE.indexOf(stat) >= 0
    return false

  sourceStats = (stats) ->
    source = []
    for stat of stats
      if REFORGABLE.indexOf(stat) >= 0
        source.push {
          key: stat,
          name: titleize(stat),
          value: stats[stat],
          use: Math.floor(stats[stat] * REFORGE_FACTOR)
        }
    source

  recommendReforge = (item, offset) ->
    return 0 if item.stats == null
    best = 0
    bestFrom = null
    bestTo = null

    for stat, value of item.stats
      ramt = Math.floor(value * REFORGE_FACTOR)
      if REFORGABLE.indexOf(stat) >= 0
        loss = getStatWeight(stat, -ramt, offset)
        for dstat in REFORGABLE
          if not item.stats[dstat]?
            gain = getStatWeight(dstat, ramt, offset)
            if gain + loss > best
              best = gain + loss
              bestFrom = stat
              bestTo = dstat

    if bestFrom? and bestTo?
      return compactReforge(bestFrom, bestTo)
    else
      return 0

  reforgeEp = (reforge, item, offset) ->
    stat = getReforgeFrom(reforge)
    amt = Math.floor(item.stats[stat] * REFORGE_FACTOR)
    loss = getStatWeight(stat, -amt, offset)
    fstat = stat

    stat = getReforgeTo(reforge)
    gain = getStatWeight(stat, amt, offset)

    return gain + loss

  setReforges: (reforges) ->
    model = Shadowcraft.Data
    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP
    for id, reforge of reforges
      gear = null
      id = parseInt(id, 10)
      reforge = parseInt(reforge, 10)
      reforge = null if reforge == 0
      for slot in SLOT_ORDER
        g = model.gear[slot]
        if g.item_id == id
          gear = g
          break
      if gear and gear.reforge != reforge
        item = ItemLookup[gear.item_id]
        if reforge == null
          Shadowcraft.Console.log "Removed reforge from #{item.name}"
          delete gear.reforge
        else
          from = getReforgeFrom(reforge)
          to = getReforgeTo(reforge)
          amt = reforgeAmount(item, from)
          gear.reforge = reforge
          Shadowcraft.Console.log "Reforged #{item.name} to <span class='neg'>-#{amt} #{titleize(from)}</span> / <span class='pos'>+#{amt} #{titleize(to)}</span>"
    Shadowcraft.update()
    Shadowcraft.Gear.updateDisplay()

  clearReforge = ->
    data = Shadowcraft.Data
    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP

    slot = $.data(document.body, "selecting-slot")
    gear = data.gear[slot]
    return unless gear
    delete gear.reforge if gear.reforge
    Shadowcraft.Console.log "Removing reforge on " + ItemLookup[gear.item_id].name
    Shadowcraft.update()
    Shadowcraft.Gear.updateDisplay()
    $("#reforge").removeClass("visible")

  doReforge: ->
    data = Shadowcraft.Data
    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP

    slot = $.data(document.body, "selecting-slot")
    from = $("#reforge input[name='oldstat']:checked").val()
    to = $("#reforge input[name='newstat']:checked").val()
    gear = data.gear[slot]
    return unless gear
    item = ItemLookup[gear.item_id]
    amt = reforgeAmount(item, from)

    if from? and to?
      gear.reforge = compactReforge(from, to)
      Shadowcraft.Console.log "Reforging #{item.name} to <span class='neg'>-#{amt} #{titleize(from)}</span> / <span class='pos'>+#{amt} #{titleize(to)}</span>"

    $("#reforge").removeClass("visible")
    Shadowcraft.update()
    Shadowcraft.Gear.updateDisplay()

  ###
  # View helpers
  ###

  updateDisplay: (skipUpdate) ->
    this.updateStatsWindow()
    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP
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
        item = ItemLookup[gear.item_id]
        gems = []
        bonuses = null
        enchant = EnchantLookup[gear.enchant]
        reforge = null
        reforgable = null
        if item
          addTradeskillBonuses(item)
          enchantable = EnchantSlots[item.equip_location]?
          if (!data.options.professions.enchanting && item.equip_location == 11) || item.equip_location == "ranged"
            enchantable = false
          allSlotsMatch = item.sockets && item.sockets.length > 0
          for socket in item.sockets
            gem = Gems[gear["g" + gems.length]]
            gems[gems.length] = {socket: socket, gem: gem}
            if !gem or !gem[socket]
              allSlotsMatch = false

          if allSlotsMatch
            bonuses = []
            for stat, amt of item.socketbonus
              bonuses[bonuses.length] = {stat: titleize(stat), amount: amt}

          if enchant and !enchant.desc
            enchant.desc = statsToDesc(enchant)

          reforgable = canReforge item
          if reforgable and gear.reforge
            from = getReforgeFrom(gear.reforge)
            to = getReforgeTo(gear.reforge)
            amt = reforgeAmount(item, from)
            reforge = {
              value: amt
              from: titleize(from)
              to: titleize(to)
            }

        if enchant and enchant.desc == ""
          enchant.desc = enchant.name

        opt.item = item
        if item
          if item.id > 100000 # It has a random component
            opt.ttid = Math.floor(item.id / 1000)
          else
            opt.ttid = item.id
        opt.ep = if item then get_ep(item, null, i).toFixed(1) else 0
        opt.slot = i + ''
        opt.gems = gems
        opt.socketbonus = bonuses
        opt.reforgable = reforgable
        opt.reforge = reforge
        opt.sockets = if item then item.sockets else null
        opt.enchantable = enchantable
        opt.enchant = enchant

        buffer += Templates.itemSlot(opt)
      $slots.get(ssi).innerHTML = buffer
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

    a_stats.push {
      name: "Dodge"
      val: pctColor(this.getDodge("main"), redWhite) + " " + pctColor(this.getDodge("off"), redWhite)
    }
    a_stats.push {
      name: "Yellow Miss"
      val: pctColor this.getMiss("yellow"), redWhite, -1
    }
    a_stats.push {
      name: "Spell Miss"
      val: pctColor this.getMiss("spell"), redWhite
    }
    a_stats.push {
      name: "White Miss"
      val: pctColor this.getMiss("white"), redWhite
    }

    EP_TOTAL = total
    $stats.get(0).innerHTML = Templates.stats {stats: a_stats}

  updateStatWeights = (source) ->
    data = Shadowcraft.Data
    Weights.agility = source.ep.agi
    Weights.crit_rating = source.ep.crit
    Weights.hit_rating = source.ep.white_hit
    Weights.spell_hit = source.ep.spell_hit
    Weights.strength = source.ep.str
    Weights.mastery_rating = source.ep.mastery
    Weights.haste_rating = source.ep.haste
    Weights.expertise_rating = source.ep.dodge_exp
    Weights.yellow_hit = source.ep.yellow_hit

    $weights = $("#weights .inner")
    $weights.empty()
    for key, weight of Weights
      exist = $(".stat#weight_" + key)
      if exist.length > 0
        exist.find("val").text Weights[key].toFixed(2)
      else
        e = $weights.append("<div class='stat' id='weight_#{key}'><span class='key'>#{titleize(key)}</span><span class='val'>#{Weights[key].toFixed(2)}</span></div>")
        exist = $(".stat#weight_" + key)
      $.data(exist.get(0), "weight", Weights[key])

    $("#weights .stat").sortElements (a, b) ->
      if $.data(a, "weight") > $.data(b, "weight") then -1 else 1
    epSort(Shadowcraft.ServerData.GEMS)

  statsToDesc = (obj) ->
    return obj.__statsToDesc if obj.__statsToDesc
    buff = []
    for stat of obj.stats
      buff[buff.length] = "+" + obj.stats[stat] + " " + titleize(stat)
    obj.__statsToDesc = buff.join("/")
    return obj.__statsToDesc

  # Standard setup for the popup
  clickSlot = (slot, prop) ->
    $slot = $(slot).closest(".slot")
    $slots.find(".slot").removeClass("active")
    $slot.addClass("active")
    slotIndex = parseInt($slot.attr("data-slot"), 10)
    $.data(document.body, "selecting-slot", slotIndex)
    $.data(document.body, "selecting-prop", prop)
    return [$slot, slotIndex]

  # Click a name in a slot, for binding to event delegation
  clickSlotName = ->
    buf = clickSlot(this, "item_id")
    $slot = buf[0]
    slot = buf[1]
    selected_id = parseInt $slot.attr("id"), 10
    equip_location = SLOT_INVTYPES[slot]
    GemList = Shadowcraft.ServerData.GEMS

    gear = Shadowcraft.Data.gear
    loc = Shadowcraft.ServerData.SLOT_CHOICES[equip_location]

    slot = parseInt($(this).parent().data("slot"), 10)
    offset = statOffset(gear[slot])

    epSort(GemList) # Needed for gemming recommendations
    for l in loc
      l.__gemRec = getGemmingRecommendation(GemList, l, true)
      l.__gemEP = l.__gemRec.ep
      rec = recommendReforge(l, offset)
      if rec
        l.__reforgeEP = reforgeEp(rec, l, offset)
      else
        l.__reforgeEP = 0

      l.__ep = get_ep(l, null, slot) + l.__gemRec.ep + l.__reforgeEP

    loc.sort(__epSort)
    max = null
    buffer = ""
    requireDagger = needsDagger()

    for l in loc
      continue if l.__ep < 1
      continue if (slot == 15 || slot == 16) && requireDagger && l.subclass != 15
      continue if (slot == 15) && !requireDagger && l.subclass == 15
      continue if l.ilvl > Shadowcraft.Data.options.general.max_ilvl
      max ||= l.__ep

      iEP = l.__ep.toFixed(1)

      if l.id > 100000 # It has a random component
        ttid = Math.floor(l.id / 1000)
      else
        ttid = l.id

      buffer += Templates.itemSlot(
        item: l
        gear: {}
        gems: []
        ttid: ttid
        desc: "#{get_ep(l).toFixed(1)} base / #{l.__reforgeEP.toFixed(1)} reforge / #{l.__gemEP.toFixed(1)} gem #{if l.__gemRec.takeBonus then "(Match gems)" else "" }"
        search: l.name
        percent: iEP / max * 100
        ep: iEP
      )

    buffer += Templates.itemSlot(
      item: {name: "[No item]"}
      desc: "Clear this slot"
      percent: 0
      ep: 0
    )

    $altslots.get(0).innerHTML = buffer
    $altslots.find(".slot[id='#{selected_id}']").addClass("active")
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
    for enchant in enchants
      enchant.__ep = get_ep(enchant, null, slot)
      max = if enchant.__ep > max then enchant.__ep else max
    enchants.sort(__epSort)
    selected_id = data.gear[slot].enchant
    buffer = ""

    for enchant in enchants
      enchant.desc = statsToDesc(enchant) if enchant && !enchant.desc
      eEP = enchant.__ep
      continue if eEP < 1
      buffer += Templates.itemSlot(
        item: enchant
        percent: eEP / max * 100
        ep: eEP.toFixed(1)
        search: enchant.name + " " + enchant.desc
        desc: enchant.desc
      )

    $altslots.get(0).innerHTML = buffer
    $altslots.find(".slot[id='#{selected_id}']").addClass("active")
    showPopup($popup) # TODO
    false

  # Change out a gem
  clickSlotGem = ->
    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP
    GemList = Shadowcraft.ServerData.GEMS
    data = Shadowcraft.Data

    buf = clickSlot(this, "gem")
    $slot = buf[0]
    slot = buf[1]

    item = ItemLookup[parseInt($slot.attr("id"), 10)]
    socketEPBonus = (if item.socketbonus then get_ep(item, "socketbonus") else 0) / item.sockets.length
    gemSlot = $slot.find(".gem").index(this)
    $.data(document.body, "gem-slot", gemSlot)
    gemType = item.sockets[gemSlot]
    selected_id = data.gear[slot]["g" + gemSlot]

    for gem in GemList
      gem.__ep = get_ep(gem) + (if gem[item.sockets[gemSlot]] then socketEPBonus else 0)
    GemList.sort(__epSort)

    buffer = ""
    gemCt = 0
    usedNames = {}
    max = null
    for gem in GemList
      continue unless canUseGem gem, gemType
      max ||= gem.__ep

      if usedNames[gem.name]
        if gem.id == selected_id
          selected_id = usedNames[gem.name]
        continue

      gemCt += 1
      break if gemCt > 50
      usedNames[gem.name] = gem.id
      gEP = gem.__ep
      desc = statsToDesc(gem)

      continue if gEP < 1

      if gem[item.sockets[gemSlot]]
        desc += " (+#{socketEPBonus.toFixed(1)} bonus)"

      buffer += Templates.itemSlot
        item: gem
        ep: gEP.toFixed(1)
        gear: {}
        ttid: gem.id
        search: gem.name + " " + statsToDesc(gem) + " " + gem.slot
        percent: gEP / max * 100
        desc: desc

    $altslots.get(0).innerHTML = buffer
    $altslots.find(".slot[id='" + selected_id + "']").addClass("active")
    showPopup($popup) # TODO
    false

  clickSlotReforge = ->
    clickSlot(this, "reforge")
    $(".slot").removeClass("active")
    $(this).addClass("active")
    data = Shadowcraft.Data

    $slot = $(this).closest(".slot")
    slot = parseInt($slot.data("slot"), 10)
    $.data(document.body, "selecting-slot", slot)

    id = $slot.attr("id")
    item = Shadowcraft.ServerData.ITEM_LOOKUP[id]

    offset = statOffset(Shadowcraft.Data.gear[slot])

    rec = recommendReforge(item, offset)
    recommended = null
    if rec
      from = getReforgeFrom(rec)
      to   = getReforgeTo(rec)
      amt  = reforgeAmount(item, from)
      recommended = {
        from: titleize(from)
        to: titleize(to)
        amount: amt
      }

    source = sourceStats(item.stats)
    targetStats = _.select(REFORGE_STATS, (s) -> item.stats[s.key] == undefined)
    $.data(document.body, "reforge-recommendation", rec)
    $.data(document.body, "reforge-item", item)
    $("#reforge").html Templates.reforge
      stats: source
      newstats: targetStats
      recommended: recommended

    $("#reforge .pct").hide()
    showPopup $("#reforge.popup") # TODO
    false

  boot: ->
    app = this
    $slots = $(".slots")
    $popup = $(".alternatives")
    $altslots = $(".alternatives .body")

    TiniReforger = new ShadowcraftTiniReforgeBackend(app)

    Shadowcraft.Backend.bind("recompute", updateStatWeights)
    Shadowcraft.Backend.bind("recompute", -> Shadowcraft.Gear )

    Shadowcraft.Talents.bind "changed", ->
      app.updateStatsWindow()

    Shadowcraft.bind "loadData", ->
      app.updateDisplay()

    $("#reforgeAll").click ->
      # Shadowcraft.Gear.reforgeAll()
      TiniReforger.buildRequest()

    $("#optimizeGems").click ->
      Shadowcraft.Gear.optimizeGems()

    # Initialize UI handlers
    $("#reforge").click $.delegate
      ".label_radio"  : -> Shadowcraft.setupLabels("#reforge")
      ".doReforge"    : this.doReforge
      ".clearReforge" : clearReforge

    #  Change out an item
    $slots.click $.delegate
      ".name"    : clickSlotName
      ".enchant" : clickSlotEnchant
      ".gem"     : clickSlotGem
      ".reforge" : clickSlotReforge

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
      scale.ExpertiseRating = Weights.expertise_rating
      scale.CritRating = Weights.crit_rating
      scale.HasteRating = Weights.haste_rating
      scale.HitRating = getHitEP()
      scale.Agility = Weights.agility
      scale.Strength = Weights.strength
      scale.MainHandDps = Shadowcraft.lastCalculation.mh_ep.mh_dps
      scale.MainHandSpeed = (Shadowcraft.lastCalculation.mh_speed_ep["mh_2.7"] - Shadowcraft.lastCalculation.mh_speed_ep["mh_2.6"]) * 10
      scale.OffHandDps = Shadowcraft.lastCalculation.oh_ep.oh_dps
      scale.OffHandSpeed = (Shadowcraft.lastCalculation.oh_speed_ep["oh_1.4"] - Shadowcraft.lastCalculation.oh_speed_ep["oh_1.3"]) * 10
      scale.IsMace = racialExpertiseBonus(null, 4)
      scale.IsSword = racialExpertiseBonus(null, 7)
      scale.IsDagger = racialExpertiseBonus(null, 15)
      scale.IsAxe = racialExpertiseBonus(null, 0)
      scale.IsFist = racialExpertiseBonus(null, 13)
      scale.MetaSocketEffect = Shadowcraft.lastCalculation.meta.chaotic_metagem

      stats = []
      for weight, val of scale
        stats.push "#{weight}=#{val}"
      name = "Rogue: " + ShadowcraftTalents.GetPrimaryTreeName()
      pawnstr = "(Pawn:v1:\"#{name}\":#{stats.join(",")})"
      $("#generalDialog").html("<textarea style='width: 450px; height: 300px;'>#{pawnstr}</textarea>").attr("title", "Pawn Import String")
      $("#generalDialog").dialog({ modal: true, width: 500 })
      return false


    # Select an item from a popup
    $altslots.click $.delegate
      ".slot": (e) ->
        ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP
        EnchantLookup = Shadowcraft.ServerData.ENCHANT_LOOKUP
        Gems = Shadowcraft.ServerData.GEM_LOOKUP
        data = Shadowcraft.Data

        slot = $.data(document.body, "selecting-slot")
        update = $.data(document.body, "selecting-prop")
        $this = $(this)
        if update == "item_id" || update == "enchant"
          val = parseInt($this.attr("id"), 10)
          data.gear[slot][update] = if val != 0 then val else null
          if update == "item_id"
            data.gear[slot].reforge = null
          else
            Shadowcraft.Console.log("Changing " + ItemLookup[data.gear[slot].item_id].name + " enchant to " + EnchantLookup[val].name)

        else if update == "gem"
          item_id = parseInt($this.attr("id"), 10)
          gem_id = $.data(document.body, "gem-slot")
          Shadowcraft.Console.log("Regemming " + ItemLookup[data.gear[slot].item_id].name + " socket " + (gem_id + 1) + " to " + Gems[item_id].name)
          data.gear[slot]["g" + gem_id] = item_id
        Shadowcraft.update()
        app.updateDisplay()

    $("#reforge").change $.delegate(
      ".oldstats input": ->
        item = $.data(document.body, "reforge-item")
        src = $(this).val()
        amt = reforgeAmount(item, src)
        max = 0
        $("#reforge .pct").each(->
          $this = $(this)
          target = $this.closest(".stat").attr("data-stat")
          c = compactReforge("expertise_rating", "hit_rating")

          ep = Math.abs reforgeEp(compactReforge(src, target), item)
          max = ep if ep > max
        ).each(->
          $this = $(this)
          target = $this.closest(".stat").attr("data-stat")
          ep = reforgeEp(compactReforge(src, target), item)
          width = Math.abs(ep) / max * 50
          inner = $this.find(".pct-inner")
          inner.removeClass("reverse")
          $this.find(".label").text(ep.toFixed(1))
          inner.addClass("reverse") if(ep < 0)
          inner.css({width: width + "%"})
          $this.hide().fadeIn('normal')
        )
    )
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
      all = popup.find(".slot")
      show = all.filter(":regex(data-search, " + search + ")")
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

    $("#filter, #reforge").click (e) ->
      e.cancelBubble = true
      e.stopPropagation()

    Shadowcraft.Options.bind "update", (opt, val) ->
      if opt == "professions.blacksmithing"
        app.updateDisplay()

    this

  constructor: (@app) ->