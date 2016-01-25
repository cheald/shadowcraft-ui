class ShadowcraftArtifact

  SPEC_ARTIFACT =
    "a":
      icon: "inv_knife_1h_artifactgarona_d_01"
      text: "The Kingslayers"
      main: 0
    "Z":
      icon: "inv_sword_1h_artifactskywall_d_01"
      text: "The Dreadblades"
      main: 202665
    "b":
      icon: "inv_knife_1h_artifactfangs_d_01"
      text: "Fangs of the Devourer"
      main: 0

  route_mapping = {}
  active_mapping = {}

  activateTrait = (spell_id) ->
    trait = $("#artifactframe .trait[data-tooltip-id='"+spell_id+"']")
    trait.children(".icon").removeClass("inactive")
    trait.children(".level").removeClass("inactive")
    active_mapping[parseInt(trait.attr("data-tooltip-id"))] = true
    level = Shadowcraft.Data.artifact.settings[spell_id]
    max_level = parseInt(trait.attr("max_level"))
    trait.children(".level").text(""+level+"/"+max_level)
    return {current: level, max: max_level}

  deactivateTrait = (spell_id) ->
    trait = $("#artifactframe .trait[data-tooltip-id='"+spell_id+"']")
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

  displayKingslayers = ->
    buffer = Templates.artifactKingslayers()
    $("#artifactframe").get(0).innerHTML = buffer

  displayDreadblades = ->
    buffer = Templates.artifactDreadblades()
    $("#artifactframe").get(0).innerHTML = buffer

  displayFangs = ->
    buffer = Templates.artifactFangs()
    $("#artifactframe").get(0).innerHTML = buffer

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

  setSpec: (str) ->
    buffer = Templates.artifactActive({
      name: SPEC_ARTIFACT[str].text
      icon: SPEC_ARTIFACT[str].icon
    })
    $("#artifactactive").get(0).innerHTML = buffer

    if str == "a"
      displayKingslayers()
    else if str == "Z"
      displayDreadblades()
    else if str == "b"
      displayFangs()

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

  resetTraits: ->
    for id of Shadowcraft.Data.artifact.settings
      Shadowcraft.Data.artifact.settings[id] = 0
    updateTraits()

  boot: ->
    app = this

    # Set a default when the page loads
    Shadowcraft.bind "loadData", ->
      data = Shadowcraft.Data
      spec = data.activeSpec
      app.setSpec(spec)

    # Set the correct display when the spec changes on the talent tab
    Shadowcraft.Talents.bind "changedSpec", (spec) ->
      app.setSpec(spec)

    $("#reset_artifact").click((e) ->
      switch(e.button)
        when 0
          app.resetTraits()
    ).bind("contextmenu", -> false
    )
    this

  constructor: (@app) ->
    @app.Artifact = this
    @displayKingslayers = displayKingslayers
    @displayDreadblades = displayDreadblades
    @displayFangs = displayFangs
    _.extend(this, Backbone.Events)
