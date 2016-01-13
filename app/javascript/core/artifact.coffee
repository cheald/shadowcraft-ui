class ShadowcraftArtifact

  SPEC_ARTIFACT =
    "a":
      icon: "inv_knife_1h_artifactgarona_d_01"
      text: "The Kingslayers"
    "Z":
      icon: "inv_sword_1h_artifactskywall_d_01"
      text: "The Dreadblades"
    "b":
      icon: "inv_knife_1h_artifactfangs_d_01"
      text: "Fangs of the Devourer"

  displayKingslayers = ->
    buffer = Templates.artifactKingslayers()
    $("#artifactframe").get(0).innerHTML = buffer

  displayDreadblades = ->
    buffer = Templates.artifactDreadblades()
    $("#artifactframe").get(0).innerHTML = buffer

  displayFangs = ->
    buffer = Templates.artifactFangs()
    $("#artifactframe").get(0).innerHTML = buffer

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

    artifactframe = $("#artifactframe")
    $("#artifactframe .trait").each(->
    ).mousedown((e) ->
      return if Modernizr.touch
      switch(e.button)
        when 0
          console.log "left click on "
        when 2
          console.log "right click on "
    ).bind("contextmenu", -> false
    ).mouseover($.delegate
      ".tt": ttlib.requestTooltip
    )
    .mouseout($.delegate
      ".tt": ttlib.hide
    )
    .bind("touchstart", (e) ->
      $.data(this, "removed", false)
      $.data(this, "listening", true)
      $.data(tframe, "listening", this)
    ).bind("touchend", (e) ->
      $.data(this, "listening", false)
      unless $.data(this, "removed") or !$(this).hasClass("active")
        console.log("touchend")
    )

    artifactframe.bind("touchstart", (e) ->
      listening = $.data(tframe, "listening")
      if e.originalEvent.touches.length > 1 and listening and $.data(listening, "listening")
        console.log("touch start")
        $.data(listening, "removed", true)
    )

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

    this

  constructor: (@app) ->
    @app.Artifact = this
    @displayKingslayers = displayKingslayers
    @displayDreadblades = displayDreadblades
    @displayFangs = displayFangs
    _.extend(this, Backbone.Events)
