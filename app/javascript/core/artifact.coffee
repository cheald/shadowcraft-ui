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
      relic1: "shadow"
      relic2: "iron"
      relic3: "blood"
    "Z":
      icon: "inv_sword_1h_artifactskywall_d_01"
      text: "The Dreadblades"
      main: 202665
      relic1: "blood"
      relic2: "iron"
      relic3: "wind"
    "b":
      icon: "inv_knife_1h_artifactfangs_d_01"
      text: "Fangs of the Devourer"
      main: 209782
      relic1: "shadow"
      relic2: "fel"
      relic3: "fel"

  RELIC_TYPE_MAP =
    "iron": 0
    "blood": 1
    "shadow": 2
    "fel": 3
    "arcane": 4
    "frost": 5
    "fire": 6
    "water": 7
    "life": 8
    "wind": 9
    "holy": 10

  # Stores whether a trait is currently active
  active_mapping = {}

  # Stores which of the relic icons was clicked on. This is 0-2, but defaults
  # back to -1 after the click has been processed.
  clicked_relic_slot = 0

  artifact_data = null

  # Activates a trait, turns the icon enabled, and sets the level of the icon to
  # some value stored in the Shadowcraft data object.
  activateTrait = (spell_id) ->
    trait = $("#artifactframe .trait[data-tooltip-id='"+spell_id+"']")
    trait.children(".icon").removeClass("inactive")
    trait.children(".level").removeClass("inactive")
    active_mapping[parseInt(trait.attr("data-tooltip-id"))] = true
    level = artifact_data.traits[spell_id]
    max_level = parseInt(trait.attr("max_level"))
    trait.children(".level").text(""+level+"/"+max_level)
    return {current: level, max: max_level}

  # Deactivates a trait, disables the icon, and sets the level in the shadowcraft
  # data to zero.
  deactivateTrait = (spell_id, hide_icon = true) ->
    trait = $("#artifactframe .trait[data-tooltip-id='"+spell_id+"']")
    if (hide_icon)
      trait.children(".icon").addClass("inactive")
      trait.children(".level").addClass("inactive")
      active_mapping[parseInt(trait.attr("data-tooltip-id"))] = false

    artifact_data.traits[spell_id] = 0
    max_level = parseInt(trait.attr("max_level"))
    trait.children(".level").text("0/"+max_level)
    return {current: 0, max: max_level}

  # Redoes the display of all of the traits based on the data stored in the
  # global Shadowcraft.Data object. This will turn everything off and
  # completely rebuild the state every time. It's a bit of a brute-force
  # solution, but it's fast enough that it doesn't matter.
  updateTraits = ->

    # Get the main spell ID for this artifact based on the active spec
    active = SPEC_ARTIFACT[Shadowcraft.Data.activeSpec]
    main_spell_id = SPEC_ARTIFACT[Shadowcraft.Data.activeSpec].main

    # Disable everything.
    active_mapping = {}
    $("#artifactframe .trait").each(->
      active_mapping[parseInt($(this).attr("data-tooltip-id"))] = false
      $(this).children(".level").addClass("inactive")
      $(this).children(".icon").addClass("inactive")
    )
    $("#artifactframe .line").each(->
      $(this).addClass("inactive")
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
      active_mapping[main_spell_id] = true
      main = $("#artifactframe .trait[data-tooltip-id='"+main_spell_id+"']")
      main.children(".level").text("0/"+main.attr("max_level"))
      main.children(".level").removeClass("inactive")
      main.children(".icon").removeClass("inactive")
      done = [main_spell_id]

    # starting at main, run a search to enable all of the icons that need
    # to be enabled based on the line endpoints. while enabling/disabling
    # icons, also set the level display based on the current level stored in
    # the data.
    stack = [main_spell_id]

    # If there are relics attached, add them to the stack so they're
    # guaranteed to get processed.
    if artifact_data.relics[0] != 0
      relic = Shadowcraft.ServerData.RELIC_LOOKUP[artifact_data.relics[0]]
      stack.push(relic.tmi)
    if artifact_data.relics[1] != 0
      relic = Shadowcraft.ServerData.RELIC_LOOKUP[artifact_data.relics[1]]
      stack.push(relic.tmi)
    if artifact_data.relics[2] != 0
      relic = Shadowcraft.ServerData.RELIC_LOOKUP[artifact_data.relics[2]]
      stack.push(relic.tmi)

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
    return

  # Called when a user left-clicks on a trait in the UI. This increases the
  # value of a trait up to the maximum of the trait.
  increaseTrait = (e) ->
    spell_id = parseInt(e.delegateTarget.attributes["data-tooltip-id"].value)
    trait = $("#artifactframe .trait[data-tooltip-id='"+spell_id+"']")

    # if this trait is inactive, ignore this event
    if trait.children(".icon").hasClass("inactive")
      return

    # if we're already at the max for this trait, don't do anything else
    max_level = parseInt(trait.attr("max_level"))
    if (artifact_data.traits[spell_id] == max_level)
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

    # don't allow the user to decrease the value of a trait past the levels
    # contributed by any attached relics.
    if trait.attr("relic_power")?
      min_level = parseInt(trait.attr("relic_power"))
    else
      min_level = 0

    # if we're already at the minimum for this trait, don't do anything else
    if (artifact_data.traits[spell_id] == min_level)
      return

    # Decrease the level on this trait and update the display
    artifact_data.traits[spell_id] -= 1
    return updateTraits()

  get_ep = (relic) ->
    # TODO: not entirely sure how to go about this one. Right now just order
    # them by the ID so we can tell it's doing *something*.
    return relic.id

  # Called when the user clicks on a relic slot in the UI. This will create
  # a popup containing all of the relics for that type and allow the user
  # to select a relic to attach.
  clickRelicSlot = (e) ->
    relic_type = e.delegateTarget.attributes['relic-type'].value
    clicked_relic_slot = parseInt(/relic(\d+)/.exec(e.delegateTarget.id)[1])-1

    # Grab the list of relics and filter them based on the type that
    # was clicked.
    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP2
    RelicList = Shadowcraft.ServerData.RELICS.filter((relic) ->
      return relic.type == RELIC_TYPE_MAP[relic_type]
    )
    data = Shadowcraft.Data

    # Generate EP values for all of the relics selected and then sort
    # them based on the EP values, highest EP first.
    for relic in RelicList
      relic.__ep = get_ep(relic)
    RelicList.sort((relic1, relic2) -> return (relic2.__ep - relic1.__ep))

    # Loop through and build up the HTML for the popup window
    buffer = ""
    max = null
    for relic in RelicList
      max ||= relic.__ep
      desc = ""
      if (relic.ii != -1)
        desc += "+"+relic.ii+" Item Levels"
      if (relic.ii != -1 && relic.ti != -1)
        desc += " / "
      if (relic.ti != -1)
        desc += "+"+relic.ti+" Rank: "+relic.tmn

      buffer += Templates.itemSlot
        item: relic
        ep: relic.__ep
        gear: {}
        ttid: relic.id
        search: escape(relic.n)
        percent: relic.__ep / max * 10
        desc: desc

    buffer += Templates.itemSlot(
      item: {name: "[No relic]"}
      desc: "Clear this relic"
      percent: 0
      ep: 0
    )

    # Set the HTML into the popup and mark the currently active relic
    # if there is one.
    $popupbody.get(0).innerHTML = buffer
    if artifact_data.relics[clicked_relic_slot] != -1
      $popupbody.find(".slot[id='" + artifact_data.relics[clicked_relic_slot] + "']").addClass("active")

    showPopup($popup)
    false

  # Called when the user selects a relic from the popup list opened by
  # clickRelicSlot. This updates a trait with the selected relic and updates
  # the display.
  selectRelic = (clicked_relic) ->
    Shadowcraft.Console.purgeOld()
    Relics = Shadowcraft.ServerData.RELIC_LOOKUP
    data = Shadowcraft.Data

    button = $("#relic"+(clicked_relic_slot+1)+" .relicicon")

    # get the relic ID from the item that was clicked. if there wasn't
    # an id attribute, this will return a NaN which we then check for.
    # that NaN indicates that the user clicked on the "None" item and
    # that we need to disable the currently selected relic.
    relic_id = parseInt(clicked_relic.attr("id"))
    relic_id = if not isNaN(relic_id) then relic_id else null
    if relic_id?

      # If this is the relic the user already selected for this slot,
      # ignore it and continue.
      current_relic = artifact_data.relics[clicked_relic_slot]
      if current_relic == relic_id
        clicked_relic_slot = -1
        return
      else if current_relic != 0 and current_relic != relic_id
        relic = Relics[current_relic]
        trait = $("#artifactframe .trait[data-tooltip-id='"+relic.tmi+"']")
        artifact_data.traits[relic.tmi] -= relic.ti
        max_level = parseInt(trait.attr("max_level"))
        max_level -= relic.ti
        trait.attr("max_level", max_level)
        if trait.attr("relic_power")?
          relic_power = parseInt(trait.attr("relic_power")) - relic.ti
        else
          relic_power = 0
        trait.attr("relic_power", relic_power)

      # Turn on the icon on the relicicon img element and unhide it
      relic = Relics[relic_id]
      button.attr("src", "http://wow.zamimg.com/images/wow/icons/large/"+relic.icon+".jpg")
      button.removeClass("inactive")

      # Find the trait that this relic modifies, the trait element on the
      # artifact frame, and update the value stored in the data
      trait = $("#artifactframe .trait[data-tooltip-id='"+relic.tmi+"']")
      artifact_data.traits[relic.tmi] += relic.ti
      max_level = parseInt(trait.attr("max_level"))
      max_level += relic.ti
      trait.attr("max_level", max_level)
      if trait.attr("relic_power")?
        relic_power = parseInt(trait.attr("relic_power")) + relic.ti
      else
        relic_power = relic.ti
      trait.attr("relic_power", relic_power)

      # Store this relic id in the global data object and force a refresh
      # of the display
      artifact_data.relics[clicked_relic_slot] = relic_id
      updateTraits()

    else
      # Hide the icon
      button.addClass("inactive")

      # Find the trait that this relic modifies, the trait element on the
      # artifact frame, and update the value stored in the data
      relic = Relics[artifact_data.relics[clicked_relic_slot]]
      artifact_data.relics[clicked_relic_slot] = 0

      trait = $("#artifactframe .trait[data-tooltip-id='"+relic.tmi+"']")
      artifact_data.traits[relic.tmi] -= relic.ti
      max_level = parseInt(trait.attr("max_level"))
      max_level -= relic.ti
      trait.attr("max_level", max_level)
      if trait.attr("relic_power")?
        relic_power = parseInt(trait.attr("relic_power")) - relic.ti
      else
        relic_power = 0
      trait.attr("relic_power", relic_power)

      # Force a refresh of the display
      updateTraits()

    clicked_relic_slot = 0
    Shadowcraft.update()
    # TODO: is this needed?
#    app.updateDisplay()
    return true

  setSpec: (str) ->
    buffer = Templates.artifactActive({
      name: SPEC_ARTIFACT[str].text
      icon: SPEC_ARTIFACT[str].icon
    })
    $("#artifactactive").get(0).innerHTML = buffer

    if str == "a"
      buffer = ArtifactTemplates.useKingslayers()
      $("#artifactframe").get(0).innerHTML = buffer
      artifact_data = Shadowcraft.Data.artifact[str]
    else if str == "Z"
      buffer = ArtifactTemplates.useDreadblades()
      $("#artifactframe").get(0).innerHTML = buffer
      artifact_data = Shadowcraft.Data.artifact[str]
    else if str == "b"
      buffer = ArtifactTemplates.useFangs()
      $("#artifactframe").get(0).innerHTML = buffer
      artifact_data = Shadowcraft.Data.artifact[str]

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
    for id of artifact_data.traits
      artifact_data.traits[id] = 0
    artifact_data.relics[0] = 0
    artifact_data.relics[1] = 0
    artifact_data.relics[3] = 0
    updateTraits()

  boot: ->
    app = this

    $popup = $("#artifactpopup")
    $popupbody = $("#artifactpopup .body")

    # Set a default when the page loads
    Shadowcraft.bind "loadData", ->
      data = Shadowcraft.Data
      spec = data.activeSpec
      app.setSpec(spec)

    # Set the correct display when the spec changes on the talent tab
    Shadowcraft.Talents.bind "changedSpec", (spec) ->
      app.setSpec(spec)

    $("#reset_artifact").click((e) ->
      app.resetTraits()
    ).bind("contextmenu", -> false
    )

    $(".popup").mouseover($.delegate
      ".tt": ttlib.requestTooltip
    ).mouseout($.delegate
      ".tt": ttlib.hide
    )

    $(".popup .body").bind "mousewheel", (event) ->
      if (event.wheelDelta < 0 and this.scrollTop + this.clientHeight >= this.scrollHeight) or event.wheelDelta > 0 and this.scrollTop == 0
        event.preventDefault()
        return false

    $popupbody.click $.delegate
      ".slot": (e) ->
        selectRelic($(this))

    this

  constructor: (@app) ->
    @app.Artifact = this
    _.extend(this, Backbone.Events)
