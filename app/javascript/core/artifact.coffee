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

  updateTraits = ->

    main_spell_id = 202665
    traits = $("#artifactframe .trait")

    # Disable everything.
    traits.each(->
      $(this).children(".level").addClass("inactive")
      $(this).children(".icon").addClass("inactive")
    )
    $("#artifactframe .line").each(->
      # TODO: set the line to a lighter version
    )

    # if there's no artifact data in the data object, just return and don't do
    # anything else. this is mostly here for testing right now, but it's best
    # to check instead of throwing an error.
    if (!Shadowcraft.Data.artifact)
      return

    # get the element for the main proc of the artifact
    main = $("#artifactframe .trait[data-tooltip-id='"+main_spell_id+"']")

    # if the current level for the main proc is zero, disable everything
    if (Shadowcraft.Data.artifact.settings[main_spell_id] == 0)

      # enable the level for the main icon and set the level to 0/1
      main.children(".level").text("0/"+trait.attr("max_level"))
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
        console.log("processing icon for "+ spell_id)

        # if we've already processed this one (covers loops), skip it and go
        # on to the next one
        if (jQuery.inArray(spell_id, done) != -1)
          continue

        # find the trait element with this spell ID
        trait = $("#artifactframe .trait[data-tooltip-id='"+spell_id+"']")
        max_level = parseInt(trait.attr("max_level"))
        icon = trait.children(".icon")
        level = trait.children(".level")
        current_level = Shadowcraft.Data.artifact.settings[spell_id]

        level.text("" + current_level + "/" +max_level)
        level.removeClass("inactive")
        icon.removeClass("inactive")

        # if the level is equal to the max level, then enable the lines
        # attached to this icon and insert the spell IDs for the icons
        # at the other ends to the stack so they'll get processed too.
        if (current_level == max_level)
          $("#artifactframe .line[spell1='"+spell_id+"']").each(->
            # TODO: enable line
            if (jQuery.inArray($(this).attr("spell2"), done) == -1)
              stack.push($(this).attr("spell2"))
          )
          $("#artifactframe .line[spell2='"+spell_id+"']").each(->
            # TODO: enable line
            if (jQuery.inArray($(this).attr("spell1"), done) == -1)
              stack.push($(this).attr("spell1"))
          )

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
    max_level = parseInt(trait.attr("max_level"))
    if (Shadowcraft.Data.artifact.settings[spell_id] == max_level)
      return

    old_level = Shadowcraft.Data.artifact.settings[spell_id]
    Shadowcraft.Data.artifact.settings[spell_id] += 1
    current_level = Shadowcraft.Data.artifact.settings[spell_id]

    level = trait.children(".level")
    level.text("" + current_level + "/" +max_level)
    stack = []
    if (current_level == max_level)
      $("#artifactframe .line[spell1='"+spell_id+"']").each(->
        # TODO: enable line
        stack.push($(this).attr("spell2"))
      )
      $("#artifactframe .line[spell2='"+spell_id+"']").each(->
        # TODO: enable line
        stack.push($(this).attr("spell1"))
      )

      for id in stack
        traits = $("#artifactframe .trait[data-tooltip-id='"+id+"']")
        traits.each(->
          $(this).children(".icon").removeClass("inactive")
          $(this).children(".level").removeClass("inactive")
        )

    else if (old_level == max_level)
      $("#artifactframe .line[spell1='"+spell_id+"']").each(->
        # TODO: enable line
        stack.push($(this).attr("spell2"))
      )
      $("#artifactframe .line[spell2='"+spell_id+"']").each(->
        # TODO: enable line
        stack.push($(this).attr("spell1"))
      )

      for id in stack
        traits = $("#artifactframe .trait[data-tooltip-id='"+id+"']")
        traits.each(->
          $(this).children(".icon").addClass("inactive")
          $(this).children(".level").addClass("inactive")
        )

  decreaseTrait = (e) ->
    console.log e.delegateTarget.id

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
    console.log "clicked reset button"

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

    $("#reset_artifact").mousedown((e) ->
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
