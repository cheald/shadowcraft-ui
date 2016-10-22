# Handler class for the artifact tab. This relies heavily on just brute forcing
# the tree into the state we want it in. updateTraits() handles all of the heavy
# lifting and gets called basically whenever the user does anything at all.
class ShadowcraftArtifact

  $popupbody = null
  $popup = null

  # TODO: I'm really hoping that some of this data is available from the API
  # in the future so we don't have to store it here in the javascript.
  SPEC_ARTIFACT =
    "a":
      icon: "inv_knife_1h_artifactgarona_d_01"
      text: "The Kingslayers"
      main: 192759
      relic1: "Shadow"
      relic2: "Iron"
      relic3: "Blood"
    "Z":
      icon: "inv_sword_1h_artifactskywall_d_01"
      text: "The Dreadblades"
      main: 202665
      relic1: "Blood"
      relic2: "Iron"
      relic3: "Storm"
    "b":
      icon: "inv_knife_1h_artifactfangs_d_01"
      text: "Fangs of the Devourer"
      main: 209782
      relic1: "Fel"
      relic2: "Shadow"
      relic3: "Fel"

  # Stores which of the relic icons was clicked on. This is 0-2, but defaults
  # back to -1 after the click has been processed.
  clicked_relic_slot = 0

  # Stores a mapping of ilvl increase to the EP increase for that ilvl. These
  # get reset whenever a calculation happens (because the EP for each stat
  # changes). Some may get recalculated if the user goes to select a relic.
  artifact_ilvl_stats = {}

  artifact_data = null

  # Activates a trait, turns the icon enabled, and sets the level of the icon to
  # some value stored in the Shadowcraft data object.
  activateTrait = (spell_id) ->
    trait = $("#artifactframe .trait[data-tooltip-id='"+spell_id+"']")
    trait.children(".icon").removeClass("inactive")
    trait.children(".level").removeClass("inactive")

    relic_power = trait.data("relic-power")
    level = artifact_data.traits[spell_id] + relic_power
    if isNaN(level)
      level = relic_power
    max_level = parseInt(trait.attr("max_level"))+relic_power
    trait.children(".level").text(""+level+"/"+max_level)
    trait.data("tooltip-rank", level-1)
    return {current: level, max: max_level}

  updateArtifactItem = (id, oldIlvl, newIlvl) ->
    # if the item isn't an artifact weapon, just return here and don't do
    # anything. getStatsForIlvl would have thrown an exception anyways.
    if id not in ShadowcraftConstants.ARTIFACTS
      return

    ident = id+":750"
    baseItem = Shadowcraft.ServerData.ITEM_LOOKUP2[ident]

    updatedItem = $.extend({}, baseItem)
    updatedItem.ilvl = newIlvl
    updatedItem.id = id
    updatedItem.identifier = ""+id+":"+newIlvl

    newStats = getStatsForIlvl(newIlvl)
    updatedItem.stats = $.extend({}, newStats["stats"])
    updatedItem.dps = newStats["dps"]
    if (Shadowcraft.Data.artifact_items == undefined)
      Shadowcraft.Data.artifact_items = {}
    Shadowcraft.Data.artifact_items[id] = updatedItem

  updateArtifactItem: (id, oldIlvl, newIlvl) ->
    updateArtifactItem(id, oldIlvl, newIlvl)

  # Redoes the display of all of the traits based on the data stored in the
  # global Shadowcraft.Data object. This will turn everything off and
  # completely rebuild the state every time. It's a bit of a brute-force
  # solution, but it's fast enough that it doesn't matter.
  updateTraits = ->

    # Get the main spell ID for this artifact based on the active spec
    active = SPEC_ARTIFACT[Shadowcraft.Data.activeSpec]
    main_spell_id = SPEC_ARTIFACT[Shadowcraft.Data.activeSpec].main

    # Disable everything.
    $("#artifactframe .trait").each(->
      $(this).children(".level").addClass("inactive")
      $(this).children(".icon").addClass("inactive")
      $(this).children(".relic").addClass("inactive")
      $(this).data("tooltip-rank", -1)
      $(this).data("relic-power", 0)
    )
    $("#artifactframe .line").each(->
      $(this).addClass("inactive")
    )

    # Relics too!
    $("#artifactframe .relicframe").each(->
      $(this).children(".relicicon").addClass("inactive")
      $(this).removeData("tooltip-id")
      $(this).removeData("tooltip-spec")
    )

    # if there's no artifact data in the data object, just return and don't do
    # anything else. this is mostly here for testing right now, but it's best
    # to check instead of throwing an error.
    if (!artifact_data)
      return

    # if the current level for the main proc is zero, disable everything
    done = []
    if (artifact_data.traits[main_spell_id] == 0)

      # enable the level for the main icon and set the level to 0/1
      main = $("#artifactframe .trait[data-tooltip-id='"+main_spell_id+"']")
      main.children(".level").text("0/"+main.attr("max_level"))
      main.children(".level").removeClass("inactive")
      main.children(".icon").removeClass("inactive")
      main.data("tooltip-rank", -1)
      done = [main_spell_id]

      for trait,rank of artifact_data.traits
        if (trait != main_spell_id)
          artifact_data.traits[trait] = 0

    # starting at main, run a search to enable all of the icons that need
    # to be enabled based on the line endpoints. while enabling/disabling
    # icons, also set the level display based on the current level stored in
    # the data.
    stack = [main_spell_id]

    # If there are relics attached, add them to the stack so they're
    # guaranteed to get processed. Also update the trait's relic power so
    # it gets added to the trait's level when the display is updated.
    for i in [0...3]
      unless _.isEmpty(artifact_data.relics[i])
        relic = Shadowcraft.ServerData.RELIC_LOOKUP[artifact_data.relics[i].id]
        spell = relic.ts[Shadowcraft.Data.activeSpec].spell
        trait = $("#artifactframe .trait[data-tooltip-id='#{spell}']")
        current = trait.data('relic-power')
        current += relic.ts[Shadowcraft.Data.activeSpec].rank
        trait.data('relic-power', current)
        stack.push(relic.ts[Shadowcraft.Data.activeSpec].spell)

    while (stack.length > 0)
      spell_id = stack.pop()

      # if we've already processed this one (covers loops), skip it and go
      # on to the next one
      if (jQuery.inArray(spell_id, done) != -1)
        continue

      levels = activateTrait(spell_id)

      # if the level is equal to the max level, then enable the lines
      # attached to this icon and insert the spell IDs for the icons
      # at the other ends to the stack so they'll get processed too.
      if (levels.current == levels.max)
        $("#artifactframe .line[spell1='"+spell_id+"']").each(->
          $(this).removeClass("inactive")
          other_end = $(this).attr("spell2")
          if (jQuery.inArray(other_end, done) == -1)
            stack.push(parseInt(other_end))
        )
        $("#artifactframe .line[spell2='"+spell_id+"']").each(->
          $(this).removeClass("inactive")
          other_end = $(this).attr("spell1")
          if (jQuery.inArray(other_end, done) == -1)
            stack.push(parseInt(other_end))
        )

      # insert this spell ID into the list of "done" IDs so it doesn't
      # get procesed again
      done.push(parseInt(spell_id))

    # If a spell is not in the done list, set the value of the trait to zero.
    # This keeps "zombie" values from coming back the next time the icon is
    # enabled.
    $("#artifactframe .trait").each(->
      check_id = parseInt($(this).attr('data-tooltip-id'))
      if (jQuery.inArray(check_id, done) == -1)
        artifact_data.traits[check_id] = 0
    )

    # Deal with relics that are attached to the weapon. This may enable other
    # icons that are currently disabled, but doesn't increase their value in
    # the data map.
    # TODO: make this item level a constant somewhere
    oldIlvl = Shadowcraft.Data.gear[15].item_level
    ilvl = 750
    for i in [0...3]
      button = $("#relic"+(i+1)+" .relicicon")
      relicdiv = $("#relic"+(i+1))
      unless _.isEmpty(artifact_data.relics[i])
        relic = Shadowcraft.ServerData.RELIC_LOOKUP[artifact_data.relics[i].id]
        relicItem = Shadowcraft.ServerData.GEM_LOOKUP[relic.id]
        if !relicItem
          console.log "Unable to find relic #{relic.id} in database. Not equipping."
          continue
        ilvl += ShadowcraftConstants.RELIC_ILVL_MAPPING[artifact_data.relics[i].ilvl]
        relicTrait = relic.ts[Shadowcraft.Data.activeSpec]
        button.attr("src", "http://wow.zamimg.com/images/wow/icons/large/"+relicItem.icon+".jpg")
        button.removeClass("inactive")
        relicdiv.data("tooltip-id", relic.id)
        relicdiv.data("tooltip-spec", ShadowcraftConstants.WOWHEAD_SPEC_IDS[Shadowcraft.Data.activeSpec])
        relicdiv.data("tooltip-bonus", artifact_data.relics[i].bonuses.join(":"))

        # TODO: should this apply multiple relic outlines to a single trait
        # or just the last one that it encounters?
        trait = $("#artifactframe .trait[data-tooltip-id='#{relicTrait.spell}']")
        trait.children(".relic").attr("src", "/images/artifacts/relic-"+relic.type.toLowerCase()+".png")
        trait.children(".relic").removeClass("inactive")

        # Setting the gems in the items causes wowhead tooltips to automatically
        # update the weapon item levels.
        Shadowcraft.Data.gear[15].gems[i] = relic.id
        Shadowcraft.Data.gear[16].gems[i] = relic.id
      else
        button.addClass("inactive")

    # One last check. Make sure that any activated trait that has relic power
    # but no active connections only has the relic power as the level. This may
    # happen when a user increases the level of a trait that has a relic attach
    # and then decreases all of the connected traits that would disable it. We
    # don't properly decrease the value of that trait when it's disabled.
    # NOTE: this is kind of a hack and there might be a better way to do this.
    total_artifact_points = 0
    $("#artifactframe .trait").children(".level").not(".inactive").each(->
      local_trait = $(this).parent()
      local_spell_id = local_trait.attr("data-tooltip-id")
      if (local_trait.data("relic-power") > 0)
        has_active_attachment = false
        if ($("#artifactframe .line[spell1='#{local_spell_id}']").not(".inactive").length > 0)
          has_active_attachment = true
        if ($("#artifactframe .line[spell2='#{local_spell_id}']").not(".inactive").length > 0)
          has_active_attachment = true

        if (!has_active_attachment)
          artifact_data.traits[local_spell_id] = 0
          relic_power = local_trait.data("relic-power")
          level = relic_power
          max_level = parseInt(local_trait.attr("max_level"))+relic_power
          local_trait.children(".level").text(""+level+"/"+max_level)
          local_trait.data("tooltip-rank", level-1)

      if artifact_data.traits[local_spell_id]
        total_artifact_points += artifact_data.traits[local_spell_id]
      return
    )

    trait = $("#artifactframe .trait[data-tooltip-id='"+spell_id+"']")

    buffer = Templates.artifactActive({
      name: SPEC_ARTIFACT[Shadowcraft.Data.activeSpec].text
      icon: SPEC_ARTIFACT[Shadowcraft.Data.activeSpec].icon
      points: "#{total_artifact_points}"
    })
    $("#artifactactive").get(0).innerHTML = buffer

    # Update the stored item level of the artifact weapons so that a
    # recalculation takes the relics into account.
    # TODO: i'm not entirely sure we should do this anymore. I think we should be updating the
    # ilvl on the gear item and letting gear.coffee sort out the stats when it recalculates.
    updateArtifactItem(Shadowcraft.Data.gear[15].id, oldIlvl, ilvl)
    updateArtifactItem(Shadowcraft.Data.gear[16].id, oldIlvl, ilvl)

    # Update the DPS based on the latest information
    Shadowcraft.update()

    # Update the gear display so that the two weapons will display the
    # correct tooltips.
    if (Shadowcraft.Gear.initialized)
      Shadowcraft.Gear.updateDisplay()

    return

  # Called when a user left-clicks on a trait in the UI. This increases the
  # value of a trait up to the maximum of the trait.
  increaseTrait = (e) ->
    spell_id = parseInt(e.delegateTarget.attributes["data-tooltip-id"].value)
    trait = $("#artifactframe .trait[data-tooltip-id='"+spell_id+"']")

    # if this trait is inactive, ignore this event
    if trait.children(".icon").hasClass("inactive")
      return

    if (!artifact_data.traits.hasOwnProperty(spell_id))
      artifact_data.traits[spell_id] = 0

    # if we're already at the max for this trait, don't do anything else
    max_level = parseInt(trait.attr("max_level"))
    if (artifact_data.traits[spell_id] == max_level)
      return

    # don't allow the user to increase the value of this trait if there are no
    # connected traits at max level. This may happen if the user attaches a
    # relic to a trait, which removes the "inactive" CSS class. We don't want
    # them to be able to increase the value beyond that.
    if (trait.data("relic-power") > 0)
      has_active_attachement = false
      if ($("#artifactframe .line[spell1='"+spell_id+"']").not(".inactive").length > 0)
        has_active_attachment = true
      if ($("#artifactframe .line[spell2='"+spell_id+"']").not(".inactive").length > 0)
        has_active_attachment = true

      if (!has_active_attachment)
        return

    artifact_data.traits[spell_id] += 1
    current_level = artifact_data.traits[spell_id]
    return updateTraits()

  # Called when a user right-clicks on a trait in the UI. This decreases the
  # value of a trait, stopping at either zero or the value of a relic if a
  # related relic is attached.
  decreaseTrait = (e) ->
    spell_id = parseInt(e.delegateTarget.attributes["data-tooltip-id"].value)

    # if this trait is inactive, ignore this event
    trait = $("#artifactframe .trait[data-tooltip-id='"+spell_id+"']")
    if trait.children(".icon").hasClass("inactive")
      return

    # don't do anything if the artifact_data doesn't have an entry for this trait
    # because it means that the value for it is already zero.
    if !artifact_data.traits.hasOwnProperty(spell_id)
      return

    # don't allow the user to decrease the value of a trait past the levels
    # contributed by any attached relics.
    relic_power = 0
    if trait.data("relic-power")?
      relic_power = parseInt(trait.data("relic-power"))

    if (relic_power > 0)
      min_level = relic_power
    else
      min_level = 0

    # if we're already at the minimum for this trait, don't do anything else
    if (artifact_data.traits[spell_id]+relic_power == min_level)
      return

    # Decrease the level on this trait and update the display
    artifact_data.traits[spell_id] -= 1
    return updateTraits()

  # Returns the stats for an artifact based on a requested ilvl. These are kept in a
  # map so that it can just do a lookup if needed.
  getStatsForIlvl = (ilvl) ->

    if !(ilvl of artifact_ilvl_stats)
      # get the stats for the base artifact item
      itemid = Shadowcraft.Data.gear[15].id
      stats = $.extend({}, Shadowcraft.ServerData.ITEM_LOOKUP2[""+itemid+":750"].stats)
      dps = Shadowcraft.ServerData.ITEM_LOOKUP2[""+itemid+":750"].dps

      # recalcuate and store
      multiplier =  1.0 / Math.pow(1.15, ((ilvl-750) / 15.0 * -1))
      for stat,value of stats
        if stat == 'agility' || stat == 'stamina'
          stats[stat] = Math.round(value * multiplier)
        else
          stats[stat] = Math.round(value * multiplier * ShadowcraftConstants.COMBAT_RATINGS_MULT_BY_ILVL[ilvl])

      artifact_ilvl_stats[ilvl] = {}
      artifact_ilvl_stats[ilvl]["stats"] = stats
      artifact_ilvl_stats[ilvl]["dps"] = dps * multiplier

    return artifact_ilvl_stats[ilvl]

  # Externally-available version of the above
  getStatsForIlvl: (ilvl) ->
    return getStatsForIlvl(ilvl)

  # Calculates the EP for a relic.
  getRelicEP = (relic, baseIlvl, baseStats) ->
    # If we haven't gotten a calculation back from the engine yet (this should *never*
    # happen unless the engine threw an error), just return a zero EP.
    if (!Shadowcraft.lastCalculation)
      return 0

    # Look up this relic in the other list of relics that contains the trait data so
    # we can calculate the EP associated with increasing that trait.
    relic2 = (ShadowcraftData.RELICS.filter (r) -> r.id == relic.id)[0]
    ep = 0
    if relic2
      trait = relic2.ts[Shadowcraft.Data.activeSpec]
      ep = trait.rank * Shadowcraft.lastCalculation.artifact_ranking[trait.spell]

    # Calculate the difference for each stat and the EP gain/loss for those differences
    # TODO: really should make all of these consistent everywhere
    # TODO: also, multistrike doesn't exist in legion
    # TODO: this needs to take both weapons into account, not just one of them
    newStats = getStatsForIlvl(baseIlvl+ShadowcraftConstants.RELIC_ILVL_MAPPING[relic.ilvl])
    for stat of baseStats["stats"]
      diff = newStats["stats"][stat] - baseStats["stats"][stat]
      if (stat == "agility")
        ep += diff * Shadowcraft.lastCalculation.ep["agi"]
      else if (stat == "mastery")
        ep += diff * Shadowcraft.lastCalculation.ep["mastery"]
      else if (stat == "crit")
        ep += diff * Shadowcraft.lastCalculation.ep["crit"]
      else if (stat == "multistrike")
        ep += diff * Shadowcraft.lastCalculation.ep["multistrike"]
      else if (stat == "haste")
        ep += diff * Shadowcraft.lastCalculation.ep["haste"]

    ep += (newStats["dps"]-baseStats["dps"]) * Shadowcraft.lastCalculation.mh_ep.mh_dps

    return Math.round(ep * 100.0) / 100.0;

  # Called when the user clicks on a relic slot in the UI. This will create
  # a popup containing all of the relics for that type and allow the user
  # to select a relic to attach.
  clickRelicSlot = (e) ->
    relic_type = e.delegateTarget.attributes['relic-type'].value
    clicked_relic_slot = parseInt(/relic(\d+)/.exec(e.delegateTarget.id)[1])-1
    activeSpec = Shadowcraft.Data.activeSpec

    # Get the stat information for the artifact weapon, potentially without the
    # currently applied relic, if there is one.
    currentRelic = artifact_data.relics[clicked_relic_slot]
    if _.isEmpty(currentRelic)
      baseIlvl = Shadowcraft.Data.gear[15].item_level
    else
      baseIlvl = Shadowcraft.Data.gear[15].item_level-ShadowcraftConstants.RELIC_ILVL_MAPPING[currentRelic.ilvl]
    baseArtifactStats = getStatsForIlvl(baseIlvl)

    # Generate EP values for all of the relics selected and then sort
    # them based on the EP values, highest EP first.
    max = 0
    relics = []
    for k,relic of Shadowcraft.ServerData.RELIC_ITEM_LOOKUP[relic_type]
      relic.__ep = getRelicEP(relic, baseIlvl, baseArtifactStats)
      if relic.__ep > max
        max = relic.__ep
      relics.push relic

    # Double check that the currently selected relic is in the list of relics. If not, create a new one so it
    # shows up in the list (and can be selected).
    r = (i for i in relics when i.id == currentRelic.id and i.ilvl == currentRelic.ilvl)
    if r.length == 0
      # Get the list of relics with the same ID and find the one with the closest item level. Sort them in reverse
      # order so that we can grab the closest one from the beginning of the list.
      r = (i for i in relics when i.id == currentRelic.id and i.ilvl <= currentRelic.ilvl)
      r.sort((r1, r2) -> return (r2.ilvl-r1.ilvl))
      r = r[0]
      clone = $.extend({},r)
      clone.ilvl = currentRelic.ilvl
      clone.identifier = "#{currentRelic.id}:#{currentRelic.ilvl}"
      clone.__ep = getRelicEP(clone, baseIlvl, baseArtifactStats)
      if clone.__ep > max
        max == clone.__ep
      relics.push clone

    relics.sort((relic1, relic2) -> return (relic2.__ep - relic1.__ep))

    # Loop through and build up the HTML for the popup window
    buffer = ""
    for relic in relics
      desc = "+" + ShadowcraftConstants.RELIC_ILVL_MAPPING[relic.ilvl] + " Item Levels"
      relic2 = (ShadowcraftData.RELICS.filter (r) -> r.id == relic.id)[0]
      if relic2
        desc += " / "
        desc += "+"+relic2.ts[activeSpec].rank+" Rank: "+relic2.ts[activeSpec].name

      ttbonus = ""
      if relic.ctxts
        keys = Object.keys(relic.ctxts)
        if keys.length > 0
          ttbonus = relic.ctxts[keys[0]].defaultBonuses.join(":")

      buffer += Templates.itemSlot(
        item: relic
        gear: {}
        identifier: "#{relic.id}:#{relic.ilvl}"
        ttid: relic.id
        ttspec: ShadowcraftConstants.WOWHEAD_SPEC_IDS[Shadowcraft.Data.activeSpec]
        ttbonus: ttbonus
        search: escape(relic.name)
        desc: desc
        percent: relic.__ep / max * 100
        ep: relic.__ep
        display_ilvl: true
      )

    buffer += Templates.itemSlot(
      item: {name: "[No relic]"}
      desc: "Clear this relic"
      percent: 0
      ep: 0
    )

    # Set the HTML into the popup and mark the currently active relic
    # if there is one.
    $popupbody.get(0).innerHTML = buffer
    
    if !_.isEmpty(currentRelic)
      r = (i for i in relics when i.id == currentRelic.id and i.ilvl == currentRelic.ilvl)
      if r.length == 1
        $popupbody.find(".slot[data-identifier='#{r[0].id}:#{r[0].ilvl}']").addClass("active")

    showPopup($popup)
    false

  # Called when the user selects a relic from the popup list opened by
  # clickRelicSlot. This updates a trait with the selected relic and updates
  # the display.
  selectRelic = (clicked_relic) ->

    # get the relic ID from the item that was clicked. if there wasn't
    # an id attribute, this will return a NaN which we then check for.
    # that NaN indicates that the user clicked on the "None" item and
    # that we need to disable the currently selected relic.
    relic_id = parseInt(clicked_relic.attr("id"))
    relic_id = if not isNaN(relic_id) then relic_id else null
    if relic_id?
      artifact_data.relics[clicked_relic_slot] = {
        id: parseInt(relic_id)
        bonuses: []
      }
    else
      artifact_data.relics[clicked_relic_slot] = {}

    # Force a refresh of the display
    updateTraits()

    clicked_relic_slot = 0
    return true

  setSpec: (str) ->
    buffer = Templates.artifactActive({
      name: SPEC_ARTIFACT[str].text
      icon: SPEC_ARTIFACT[str].icon
      points: "0"
    })
    $("#artifactactive").get(0).innerHTML = buffer

    if str == "a"
      buffer = ArtifactTemplates.useKingslayers()
    else if str == "Z"
      buffer = ArtifactTemplates.useDreadblades()
    else if str == "b"
      buffer = ArtifactTemplates.useFangs()

    $("#artifactframe").get(0).innerHTML = buffer

    # Reformat the trait data into something easier to deal with.
    artifact_data = {}
    artifact_data['relics'] = Shadowcraft.Data.artifact[str]['relics']
    artifact_data['traits'] = {}
    for trait in Shadowcraft.Data.artifact[str]['traits']
      artifact_data['traits'][trait['id']] = trait['rank']

    $("#relic1").attr("relic-type", SPEC_ARTIFACT[str].relic1)
    $("#relic2").attr("relic-type", SPEC_ARTIFACT[str].relic2)
    $("#relic3").attr("relic-type", SPEC_ARTIFACT[str].relic3)

    updateTraits()

    $("#artifactframe .trait").each(->
    ).mousedown((e) ->
      switch(e.button)
        when 0
          increaseTrait(e)
        when 2
          decreaseTrait(e)
    ).bind("contextmenu", -> false
    ).mouseover($.delegate
      ".tt": ttlib.requestTooltip
    )
    .mouseout($.delegate
      ".tt": ttlib.hide
    )

    $("#artifactframe .relicframe").each(->
    ).click((e) ->
      clickRelicSlot(e)
    ).bind("contextmenu", -> false
    ).mouseover($.delegate
      ".tt": ttlib.requestTooltip
    )
    .mouseout($.delegate
      ".tt": ttlib.hide
    )

  resetTraits: ->

    for i in [0..2]
      artifact_data.relics[i] = {}

    artifact_data.traits = []
    updateTraits()

  updateTraitRanking = ->
    buffer = ""
    target = $("#traitrankings")
    ranking = Shadowcraft.lastCalculation.artifact_ranking
    max = _.max(ranking)
    for trait,ep of ranking
      val = Math.round(parseFloat(ep) * 100.0)/ 100.0
      trait_name = ShadowcraftData.ARTIFACT_LOOKUP[parseInt(trait)].n
      pct = val / max * 100 + 0.01

      # Only add the trait to the list the first time through this loop.
      # On subsequent passes the element just gets resized below.
      exist = $("#traitrankings #talent-weight-"+trait)
      if exist.length == 0
        buffer = Templates.talentContribution({
          name: "#{trait_name}"
          raw_name: "#{trait}"
          val: val
          width: pct
        })
        target.append(buffer)

      # Resize this element in the list to not be bigger than the actual
      # space.
      exist = $("#traitrankings #talent-weight-"+trait)
      $.data(exist.get(0), "val", val)
      exist.show().find(".pct-inner").css({width:pct+"%"})
      exist.find(".label").text("#{val}")

    # sort all of the elements so the biggest ones are at the top
    $("#traitrankings .talent_contribution").sortElements (a,b) ->
      ad = $.data(a, "val")
      bd = $.data(b, "val")
      if ad > bd then -1 else 1

    return

  getPayload: ->
    payload = {}
    $("#artifactframe .trait").children(".level").each(->
      local_trait = $(this).parent()
      local_spell_id = local_trait.attr("data-tooltip-id")
      payload_value = local_trait.data("relic-power")
      if artifact_data.traits.hasOwnProperty(local_spell_id)
        payload_value += artifact_data.traits[local_spell_id]
      payload[local_spell_id] = payload_value
      return
    )
    return payload

  updateGlobalData: ->
    Shadowcraft.Data.artifact[Shadowcraft.Data.activeSpec].traits = []
    for trait,rank of artifact_data.traits
      continue if rank == 0
      obj = {
        id: parseInt(trait)
        rank: parseInt(rank)
      }
      Shadowcraft.Data.artifact[Shadowcraft.Data.activeSpec].traits.push(obj)

  boot: ->
    app = this

    $popup = $("#artifactpopup")
    $popupbody = $("#artifactpopup .body")

    # Set a default when the page loads
    Shadowcraft.bind "loadData", ->
      app.setSpec(Shadowcraft.Data.activeSpec)

    # Set the correct display when the spec changes on the talent tab
    Shadowcraft.Talents.bind "changedSpec", (spec) ->
      app.setSpec(spec)

    # Register for the recompute event sent by the backend. This updates some
    # of the display with the latest information from the last calculation pass.
    Shadowcraft.Backend.bind("recompute", updateTraitRanking)

    $("#reset_artifact").click((e) ->
      app.resetTraits()
    ).bind("contextmenu", -> false
    )

    $("#artifactpopup").mouseover($.delegate
      ".tt": ttlib.requestTooltip
    ).mouseout($.delegate
      ".tt": ttlib.hide
    )

    $("#artifactpopup .body").bind "mousewheel", (event) ->
      if (event.wheelDelta < 0 and this.scrollTop + this.clientHeight >= this.scrollHeight) or event.wheelDelta > 0 and this.scrollTop == 0
        event.preventDefault()
        return false

    $popupbody.click $.delegate
      ".slot": (e) ->
        selectRelic($(this))

    # Register a bunch of key bindings for the popup windows so that a user
    # can move up and down in the list with the keyboard, plus select items
    # with the enter key.
    $("input.search").keydown((e) ->
      $this = $(this)
      $popup = $this.closest("#artifactpopup")
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
      popup = $this.parents("#artifactpopup")
      search = $.trim($this.val().toLowerCase())
      all = popup.find(".slot:not(.active)")
      show = all.filter(":regex(data-search, " + escape(search) + ")")
      hide = all.not(show)
      show.removeClass("hidden")
      hide.addClass("hidden")
    )

    # On escape, clear popups
    reset = ->
      $("#artifactpopup:visible").removeClass("visible")
      ttlib.hide()

    $("body").click(reset).keydown (e) ->
      if e.keyCode == 27
        reset()

    $("#filter").click (e) ->
      e.cancelBubble = true
      e.stopPropagation()

    this

  constructor: (@app) ->
    @app.Artifact = this
    _.extend(this, Backbone.Events)

window.ShadowcraftArtifact = ShadowcraftArtifact
