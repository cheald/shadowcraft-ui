class ShadowcraftArtifact

  $popupbody = null
  $popup = null

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

  # Stores the routes through which you can get from the root trait to any
  # other currently active trait.
  route_mapping = {}

  # Stores whether a trait is currently active (in that it has routes attached)
  active_mapping = {}

  # Stores which of the relic icons was clicked on. This is 0-2, but defaults
  # back to -1 after the click has been processed.
  clicked_relic_type = -1

  # Activates a trait, turns the icon enabled, and sets the level of the icon to
  # some value stored in the Shadowcraft data object.
  activateTrait = (spell_id) ->
    trait = $("#artifactframe .trait[data-tooltip-id='"+spell_id+"']")
    trait.children(".icon").removeClass("inactive")
    trait.children(".level").removeClass("inactive")
    active_mapping[parseInt(trait.attr("data-tooltip-id"))] = true
    level = Shadowcraft.Data.artifact.settings[spell_id]
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

    # TODO: handle relics here
    Shadowcraft.Data.artifact.settings[spell_id] = 0
    max_level = parseInt(trait.attr("max_level"))
    trait.children(".level").text("0/"+max_level)
    return {current: 0, max: max_level}

  updateTraits = ->

    main_spell_id = 202665

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
    if (!Shadowcraft.Data.artifact)
      return

    # always set the route for the main proc to an empty array so that the rest
    # of the routes get setup correctly
    route_mapping[main_spell_id] = [[]]

    # if the current level for the main proc is zero, disable everything
    if (Shadowcraft.Data.artifact.settings[main_spell_id] == 0)

      # enable the level for the main icon and set the level to 0/1
      active_mapping[main_spell_id] = true
      main = $("#artifactframe .trait[data-tooltip-id='"+main_spell_id+"']")
      main.children(".level").text("0/"+main.attr("max_level"))
      main.children(".level").removeClass("inactive")
      main.children(".icon").removeClass("inactive")

    else
      # starting at main, run a search to enable all of the icons that need
      # to be enabled based on the line endpoints. while enabling/disabling
      # icons, also set the level display based on the current level stored in
      # the data.
      done = []
      stack = [main_spell_id]

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
          route_stack = []
          $("#artifactframe .line[spell1='"+spell_id+"']").each(->
            $(this).removeClass("inactive")
            other_end = $(this).attr("spell2")
            if (jQuery.inArray(other_end, done) == -1)
              stack.push(other_end)
            route_stack.push(other_end)
          )
          $("#artifactframe .line[spell2='"+spell_id+"']").each(->
            $(this).removeClass("inactive")
            other_end = $(this).attr("spell1")
            if (jQuery.inArray(other_end, done) == -1)
              stack.push(other_end)
            route_stack.push(other_end)
          )

          # Build the routes for each icon as we enable them.  This allows
          # us to disable icons when connecting icons along their routes
          # get disabled.
          for id in route_stack
            if (!(id in route_mapping))
              route_mapping[id] = []
            for route in route_mapping[spell_id]
              # don't include any routes here that this spell already
              # exists in. this helps cut down on loops.
              if spell_id in route
                continue
              newroute = route.slice(0)
              newroute.push(spell_id)
              route_mapping[id].push(newroute)

        # insert this spell ID into the list of "done" IDs so it doesn't
        # get procesed again
        done.push(spell_id)

  increaseTrait = (e) ->
    spell_id = parseInt(e.delegateTarget.attributes["data-tooltip-id"].value)
    trait = $("#artifactframe .trait[data-tooltip-id='"+spell_id+"']")

    # if this trait is inactive, ignore this event
    if trait.children(".icon").hasClass("inactive")
      return

    # if we're already at the max for this trait, don't do anything else
    max_level = parseInt(trait.attr("max_level"))
    if (Shadowcraft.Data.artifact.settings[spell_id] == max_level)
      return

    old_level = Shadowcraft.Data.artifact.settings[spell_id]
    Shadowcraft.Data.artifact.settings[spell_id] += 1
    current_level = Shadowcraft.Data.artifact.settings[spell_id]
    level = trait.children(".level")
    level.text("" + current_level + "/" +max_level)
    stack = []

    # if the new level of the trait is the maximum for that trait, we need
    # to enable the attached lines and icons.
    if (current_level == max_level)
      $("#artifactframe .line[spell1='"+spell_id+"']").each(->
        if (active_mapping[parseInt($(this).attr("spell2"))] == false)
          $(this).removeClass("inactive")
          stack.push($(this).attr("spell2"))
      )
      $("#artifactframe .line[spell2='"+spell_id+"']").each(->
        if (active_mapping[parseInt($(this).attr("spell1"))] == false)
          $(this).removeClass("inactive")
          stack.push($(this).attr("spell1"))
      )

      for id in stack
        activateTrait(id)
        if (!(id in route_mapping))
          route_mapping[id] = []
        for route in route_mapping[spell_id]
          # don't include any routes here that this spell already
          # exists in. this helps cut down on loops.
          if spell_id in route
            continue
          newroute = route.slice(0)
          newroute.push(spell_id)
          route_mapping[id].push(newroute)

    # call to update the DPS chart
    Shadowcraft.update()

  decreaseTrait = (e) ->
    spell_id = parseInt(e.delegateTarget.attributes["data-tooltip-id"].value)
    trait = $("#artifactframe .trait[data-tooltip-id='"+spell_id+"']")

    # if this trait is inactive, ignore this event
    if trait.children(".icon").hasClass("inactive")
      return

    # if we're already at the minimum for this trait, don't do anything else
    # TODO: have to handle relics somehow here
    if (Shadowcraft.Data.artifact.settings[spell_id] == 0)
      return

    # Decrease the level on this trait and update the display
    max_level = parseInt(trait.attr("max_level"))
    Shadowcraft.Data.artifact.settings[spell_id] -= 1
    current_level = Shadowcraft.Data.artifact.settings[spell_id]
    level = trait.children(".level")
    level.text("" + current_level + "/" +max_level)

    # Search through all of the currently stored routes and remove any
    # routes that involve this icon. If we find any icons that have no
    # routes after deletion, disable those too.
    for spell,routes of route_mapping
      indexes_to_remove = []
      index = 0
      for route in routes
        if (route.indexOf(spell_id) != -1)
          indexes_to_remove.push(index)
        index++
      for remove in indexes_to_remove
        routes.splice(remove, 1)
      if routes.length == 0
        deactivateTrait(spell)

    # Loop back through all of the lines and disable anything that has
    # an icon disabled at either end of it.
    # TODO: it might be possible to do this above or to remove the entire
    # section about deleting lines above.
    $("#artifactframe .line").each(->
      # don't bother doing any of this if the line is already inactive
      if $(this).hasClass("inactive")
        return

      spell1 = parseInt($(this).attr("spell1"))
      spell2 = parseInt($(this).attr("spell2"))
      if (!active_mapping[spell1] || !active_mapping[spell2])
        $(this).addClass("inactive")
    )

    # call to update the dps chart
    Shadowcraft.update()

  get_ep = (relic) ->
    # TODO: not entirely sure how to go about this one. Right now just order
    # them by the ID so we can tell it's doing *something*.
    return relic.id

  clickRelic = (e) ->
    relic_type = e.delegateTarget.attributes['relic-type'].value
    relic_number = -1
    if e.delegateTarget.id == "relic1"
      relic_number = 0
    else if e.delegateTarget.id == "relic2"
      relic_number = 1
    else if e.delegateTarget.id == "relic3"
      relic_number = 2
    clicked_relic_type = relic_number

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

    $popupbody.get(0).innerHTML = buffer
    if relic_number == 0 and Shadowcraft.Data.artifact.relic1 != 0
      $popupbody.find(".slot[id='" + Shadowcraft.Data.artifact.relic1 + "']").addClass("active")
    else if relic_number == 1 and Shadowcraft.Data.artifact.relic2 != 0
      $popupbody.find(".slot[id='" + Shadowcraft.Data.artifact.relic2 + "']").addClass("active")
    else if relic_number == 2 and Shadowcraft.Data.artifact.relic3 != 0
      $popupbody.find(".slot[id='" + Shadowcraft.Data.artifact.relic3 + "']").addClass("active")

    showPopup($popup)

    false

  selectRelic = (clicked_relic) ->
    Shadowcraft.Console.purgeOld()
    Relics = Shadowcraft.ServerData.RELIC_LOOKUP
    data = Shadowcraft.Data

    button = $("#relic"+(clicked_relic_type+1)+" .relicicon")

    # get the relic ID from the item that was clicked. if there wasn't
    # an id attribute, this will return a NaN which we then check for.
    # that NaN indicates that the user clicked on the "None" item and
    # that we need to disable the currently selected relic.
    relic_id = parseInt(clicked_relic.attr("id"), 0)
    relic_id = if not isNaN(relic_id) then relic_id else null
    if relic_id?
      # Turn on the icon on the relicicon img element and unhide it
      relic = Relics[relic_id]
      button.attr("src", "http://wow.zamimg.com/images/wow/icons/large/"+relic.icon+".jpg")
      button.removeClass("inactive")

      # Find the trait that this relic modifies, the trait element on the
      # artifact frame, and update the value stored in the data
      trait = $("#artifactframe .trait[data-tooltip-id='"+relic.tmi+"']")
      Shadowcraft.Data.artifact.settings[relic.tmi] += 1
      max_level = parseInt(trait.attr("max_level"))
      max_level += 1
      trait.attr("max_level", max_level)
      activateTrait(relic.tmi)
      if (clicked_relic_type == 0)
        Shadowcraft.Data.artifact.relic1 = relic_id
      else if (clicked_relic_type == 1)
        Shadowcraft.Data.artifact.relic2 = relic_id
      else if (clicked_relic_type == 2)
        Shadowcraft.Data.artifact.relic3 = relic_id

    else
      # Hide the icon
      button.addClass("inactive")

      # Find the trait that this relic modifies, the trait element on the
      # artifact frame, and update the value stored in the data
      if (clicked_relic_type == 0)
        relic = Relics[Shadowcraft.Data.artifact.relic1]
        Shadowcraft.Data.artifact.relic1 = 0
      else if (clicked_relic_type == 1)
        relic = Relics[Shadowcraft.Data.artifact.relic2]
        Shadowcraft.Data.artifact.relic2 = 0
      else if (clicked_relic_type == 2)
        relic = Relics[Shadowcraft.Data.artifact.relic3]
        Shadowcraft.Data.artifact.relic3 = 0

      trait = $("#artifactframe .trait[data-tooltip-id='"+relic.tmi+"']")
      Shadowcraft.Data.artifact.settings[relic.tmi] -= 1
      max_level = parseInt(trait.attr("max_level"))
      max_level -= 1
      trait.attr("max_level", max_level)
      if Shadowcraft.Data.artifact.settings[relic.tmi] > 0
        activateTrait(relic.tmi)
      else
        # if there's an existing connection to this icon, the trait should
        # stay enabled, but the level should be reduced to 0.
        if relic.tmi of route_mapping and route_mapping[relic.tmi].length > 0
          deactivateTrait(relic.tmi, false)
        else        
          deactivateTrait(relic.tmi, true)

    clicked_relic_type = -1
    Shadowcraft.update()
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
    else if str == "Z"
      buffer = ArtifactTemplates.useDreadblades()
      $("#artifactframe").get(0).innerHTML = buffer
    else if str == "b"
      buffer = ArtifactTemplates.useFangs()
      $("#artifactframe").get(0).innerHTML = buffer

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
      clickRelic(e)
    ).bind("contextmenu", -> false
    ).mouseover($.delegate
      ".tt": ttlib.requestTooltip
    )
    .mouseout($.delegate
      ".tt": ttlib.hide
    )

  resetTraits: ->
    for id of Shadowcraft.Data.artifact.settings
      Shadowcraft.Data.artifact.settings[id] = 0
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
