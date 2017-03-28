# Handler class for the artifact tab. This relies heavily on just brute forcing
# the tree into the state we want it in. updateTraits() handles all of the heavy
# lifting and gets called basically whenever the user does anything at all.
class ShadowcraftArtifact

  $popupbody = null
  $popup = null

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

  deactivateTrait = (spell_id) ->
    trait = $("#artifactframe .trait[data-tooltip-id='"+spell_id+"']")
    trait.children(".level").addClass("inactive")
    trait.children(".icon").addClass("inactive")
    trait.children(".relic").addClass("inactive")
    trait.data("tooltip-rank", -1)
    trait.data("relic-power", 0)

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
    active = ShadowcraftConstants.SPEC_ARTIFACT[Shadowcraft.Data.activeSpec]
    main_spell_id = ShadowcraftConstants.SPEC_ARTIFACT[Shadowcraft.Data.activeSpec].main
    thirty_five = ShadowcraftConstants.SPEC_ARTIFACT[Shadowcraft.Data.activeSpec].thirtyfive
    second_major = ShadowcraftConstants.SPEC_ARTIFACT[Shadowcraft.Data.activeSpec].secondmajor
    concordance = ShadowcraftConstants.SPEC_ARTIFACT[Shadowcraft.Data.activeSpec].concordance

    # Make things easier on me. Please.
    if (!artifact_data.traits[thirty_five])
      artifact_data.traits[thirty_five] = 0
    if (!artifact_data.traits[second_major])
      artifact_data.traits[second_major] = 0
    if (!artifact_data.traits[concordance])
      artifact_data.traits[concordance] = 0

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
        relic_trait = artifact_data.relics[i].trait
        trait = $("#artifactframe .trait[data-tooltip-id='#{relic_trait.spell}']")
        current = trait.data('relic-power') + relic_trait.rank
        trait.data('relic-power', current)
        stack.push(relic_trait.spell)

    # If the user has points put in to their 35th trait, add the second major to the
    # stack so that tree gets processed as well.
    if artifact_data.traits[thirty_five] > 0
      activateTrait(thirty_five)
      stack.push(second_major)

      $("#artifactframe .trait[max_level=3]").each(->
        $(this).attr('max_level', 4))
    else
      $("#artifactframe .trait[max_level=4]").each(->
        $(this).attr('max_level', 3))

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
      if (levels.current == levels.max ||
          (artifact_data.traits[thirty_five] > 0 && levels.current == levels.max-1 && levels.current > 0))
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
      if (check_id != thirty_five and check_id != second_major and jQuery.inArray(check_id, done) == -1)
        artifact_data.traits[check_id] = 0
    )

    # Deal with relics that are attached to the weapon. This may enable other
    # icons that are currently disabled, but doesn't increase their value in
    # the data map.
    # TODO: make this item level a constant somewhere
    old_ilvl = Shadowcraft.Data.gear[15].item_level

    new_ilvl = 750
    for i in [0...3]
      unless _.isEmpty(artifact_data.relics[i])
        trait_id = artifact_data.relics[i].trait.spell
        relic_ilvl = artifact_data.relics[i].ilvl
        $("#relic-#{i}-#{trait_id}").prop('selected', true)
        $("#relicilvl-#{i}-#{relic_ilvl}").prop('selected', true)

        new_ilvl += ShadowcraftConstants.RELIC_ILVL_MAPPING[relic_ilvl]

        relic_type = ShadowcraftConstants.SPEC_ARTIFACT[Shadowcraft.Data.activeSpec]["relic#{i+1}"]

        # TODO: should this apply multiple relic outlines to a single trait
        # or just the last one that it encounters?
        trait = $("#artifactframe .trait[data-tooltip-id='#{trait_id}']")
        trait.children(".relic").attr("src", "/images/artifacts/relic-#{relic_type.toLowerCase()}.png")
        trait.children(".relic").removeClass("inactive")

      else
        $("#relic-#{i}-none").prop("selected", true)
        $("#relicilvl-#{i}-none").prop("selected", true)

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

        if (!has_active_attachment && local_spell_id != thirty_five && local_spell_id != second_major)
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

    #Do not count first trait
    if total_artifact_points > 0
      total_artifact_points -= 1

    if total_artifact_points >= 34
      activateTrait(thirty_five)

    if total_artifact_points >= 35
      activateTrait(second_major)

    if total_artifact_points >= 51
      activateTrait(concordance)
    else
      artifact_data.traits[concordance] = 0
      deactivateTrait(concordance)
      $("#artifactframe .line[spell1='"+concordance+"']").each(->
        $(this).addClass("inactive"))
      $("#artifactframe .line[spell2='"+concordance+"']").each(->
        $(this).addClass("inactive"))

    trait = $("#artifactframe .trait[data-tooltip-id='"+spell_id+"']")

    buffer = Templates.artifactActive({
      name: ShadowcraftConstants.SPEC_ARTIFACT[Shadowcraft.Data.activeSpec].text
      icon: ShadowcraftConstants.SPEC_ARTIFACT[Shadowcraft.Data.activeSpec].icon
      points: "#{total_artifact_points}"
    })
    $("#artifactactive").get(0).innerHTML = buffer

    # Update the stored item level of the artifact weapons so that a
    # recalculation takes the relics into account.
    # TODO: i'm not entirely sure we should do this anymore. I think we should
    # be updating the ilvl on the gear item and letting gear.coffee sort out the
    # stats when it recalculates.
    updateArtifactItem(Shadowcraft.Data.gear[15].id, old_ilvl, new_ilvl)
    updateArtifactItem(Shadowcraft.Data.gear[16].id, old_ilvl, new_ilvl)

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
      multiplier = Math.pow(1.15, ((ilvl - 750.0) / 15.0)) * 1.05
      for stat,value of stats
        v = value * multiplier
        if stat == 'agility' || stat == 'stamina'
          stats[stat] = Math.round(v)
        else
          stats[stat] = Math.round(v * ShadowcraftConstants.COMBAT_RATINGS_MULT_BY_ILVL[ilvl])

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
      else if (stat == "haste")
        ep += diff * Shadowcraft.lastCalculation.ep["haste"]

    ep += (newStats["dps"]-baseStats["dps"]) * Shadowcraft.lastCalculation.mh_ep.mh_dps

    return Math.round(ep * 100.0) / 100.0;

  # Called when the user selects a new relic from the drop downs on the UI
  clickRelicSlot = (target) ->
    index = target.getAttribute("data-index")
    spell_id = parseInt(target.selectedOptions[0].value) || 0
    artifact_data.relics[index].trait = {}
    if spell_id != 0
      trait_data = Shadowcraft.ServerData.ARTIFACT_LOOKUP[spell_id]
      artifact_data.relics[index].trait['name'] = trait_data.n
      artifact_data.relics[index].trait['spell'] = trait_data.id

      # TODO: hardcode this for now since we only have single-point relics right now. this
      # will have to be fixed later, probably with a third dropdown menu on the UI for each
      # relic.
      artifact_data.relics[index].trait['rank'] = 1

    # Force a refresh of the display
    updateTraits()

  # Called when the user selects a new relic ilvl from the drop downs on the UI
  clickRelicSlotIlvl = (target) ->
    index = target.getAttribute("data-index")
    artifact_data.relics[index].ilvl = parseInt(target.selectedOptions[0].value)

    # Force a refresh of the display
    updateTraits()

  setSpec: (str) ->
    buffer = Templates.artifactActive({
      name: ShadowcraftConstants.SPEC_ARTIFACT[str].text
      icon: ShadowcraftConstants.SPEC_ARTIFACT[str].icon
      points: "0"
    })
    $("#artifactactive").get(0).innerHTML = buffer

    if str == "a"
      buffer = ArtifactTemplates.useKingslayers()
      traits = ArtifactTemplates.getKingslayersTraits()
    else if str == "Z"
      buffer = ArtifactTemplates.useDreadblades()
      traits = ArtifactTemplates.getDreadbladesTraits()
    else if str == "b"
      buffer = ArtifactTemplates.useFangs()
      traits = ArtifactTemplates.getFangsTraits()

    $("#artifactframe").get(0).innerHTML = buffer

    relic_options = []
    for trait in traits
      if not trait.is_thin
        continue

      relic_options.push {
        id: trait.spell_id
        name: ShadowcraftData.ARTIFACT_LOOKUP[trait.spell_id].n
      }

    relic_ilvls = []
    for ilvl in [830..ShadowcraftConstants.CURRENT_MAX_ILVL]
      if ilvl % 5 != 0
        continue
      relic_ilvls.push {ilvl: ilvl}

    buffer = ""
    for i in [0...3]
      relic_type = ShadowcraftConstants.SPEC_ARTIFACT[str]['relic'+(i+1)]
      buffer += Templates.relicPicker(name: "Relic #{i+1} (#{relic_type}): ", traits: relic_options, ilvls: relic_ilvls, index: "#{i}")
      buffer += "<br/>"

    $("#relicframe").get(0).innerHTML = buffer

    # Reformat the trait data into something easier to deal with.
    artifact_data = {}
    artifact_data['relics'] = Shadowcraft.Data.artifact[str]['relics']
    artifact_data['traits'] = {}
    for trait in Shadowcraft.Data.artifact[str]['traits']
      artifact_data['traits'][trait['id']] = trait['rank']

    updateTraits()

    # Set up a click handler for each trait to handle both left and right clicks
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

    # Set up some change handlers for the relics
    for i in [0...3]
      $("#relic-#{i}-select").change ->
        clickRelicSlot(this)
      $("#relicilvl-#{i}-select").change ->
        clickRelicSlotIlvl(this)

  resetTraits: ->

    for i in [0...3]
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
