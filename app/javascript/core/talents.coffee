class ShadowcraftTalents

  SPEC_ICONS =
    "a": "ability_rogue_eviscerate"
    "Z": "ability_backstab"
    "b": "ability_stealth"
    "": "class_rogue"

  DEFAULT_SPECS =
    "Stock Assassination":
      talents: "2211021"
      spec: "a"
    "Stock Outlaw":
      talents: "2211011"
      spec: "Z"
    "Stock Subtlety":
      talents: "1210011"
      spec: "b"

  TALENT_NAMES =
    "gloomblade": "Gloomblade"
    "master_of_subtlety": "Master of Subtlety"
    "weaponmaster": "Weaponmaster"
    "nightstalker": "Nightstalker"
    "shadow_focus": "Shadow Focus"
    "subterfuge": "Subterfuge"
    "anticipation": "Anticipation"
    "deeper_strategem": "Deeper Strategem"
    "vigor": "Vigor"
    "cheat_death": "Cheat Death"
    "elusiveness": "Elusiveness"
    "soothing_darkness": "Soothing Darkness"
    "prey_on_the_weak": "Prey on the Weak"
    "strike_from_the_shadows": "Strike from the Shadows"
    "tangled_shadow": "Tangled Shadow"
    "alacrity": "Alacrity"
    "enveloping_shadows": "Enveloping Shadows"
    "premeditation": "Premeditation"
    "death_from_above": "Death from Above"
    "marked_for_death": "Marked for Death"
    "master_of_shadows": "Master of Shadows"
    "ghostly_strike": "Ghostly Strike"
    "quick_draw": "Quick Draw"
    "swordmaster": "Swordmaster"
    "acrobatic_strikes": "Acrobatic Strikes"
    "grappling_hook": "Grappling Hook"
    "hit_and_run": "Hit and Run"
    "iron_stomach": "Iron Stomach"
    "dirty_tricks": "Dirty Tricks"
    "parley": "Parley"
    "prey_on_the_weak": "Prey on the Weak"
    "cannonball_barrage": "Cannonball Barrage"
    "killing_spree": "Killing Spree"
    "slice_and_dice": "Slice and Dice"
    
  @GetActiveSpecName = ->
    activeSpec = Shadowcraft.Data.activeSpec
    if activeSpec
      return getSpecName(activeSpec)
    return ""

  getSpecName = (s) ->
    if s == "a"
      return "Assassination"
    else if s == "Z"
      return "Outlaw"
    else if s == "b"
      return "Subtlety"
    else
      return "Rogue"

  applyTalent: (talent, enable) ->

    position = $.data(talent, "position")
    # if enable = false, we're disabling a talent and need to turn off the grey
    # for all icons in the row and return true
    if !enable
      $("#talentframe .talent.row-#{position['row']}").each(->
        $(this).addClass("active")
      )
      talents = Shadowcraft.Data.activeTalents.split("")
      talents[position['row']] = '.'
      Shadowcraft.Data.activeTalents = talents.join("")
      return true

    else
      talents = Shadowcraft.Data.activeTalents.split("")
      if (talents[position['row']] == position['col'])
        # if selecting the already-selected talent, do nothing and just return
        return false
      else
        # if selecting something else, deactivate all of the icons in the row
        # and activate the one that matters.
        $("#talentframe .talent.row-#{position['row']}").each(->
          $(this).removeClass("active")
        )
        $("#talentframe .talent.row-#{position['row']}.col-#{position['col']}").addClass("active")

        # update the set of active talents and return true so that the backend
        # will recalculate
        talents[position['row']] = position["col"]
        Shadowcraft.Data.activeTalents = talents.join("")
        return true
        
  resetTalents: ->
    Shadowcraft.Data.activeTalents="......."
    $("#talentframe .talent").each(->
      $(this).addClass("active")
    )
    Shadowcraft.update()
    checkForWarnings("talents")

  # Inits the sidebar with the active specs from the character data and
  # the default specs
  initSidebar: ->
    app = this

    data = Shadowcraft.Data
    buffer = ""
    for talent in data.talents
      buffer += Templates.talentSet({
        talent_string: talent.talents,
        name: "Imported " + getSpecName(talent.spec),
        spec: talent.spec
      })

    for talentName, talentSet of DEFAULT_SPECS
      buffer += Templates.talentSet({
        talent_string: talentSet.talents,
        name: talentName,
        spec: talentSet.spec
      })

    $("#talentsets").get(0).innerHTML = buffer

    $("#talentsets").click $.delegate({
      ".talent_set": ->
        app.setSpec($(this).data("spec"))
        app.setActiveTalents($(this).data("talents")+"")
        return
    })

  # Sets the active talents within the current spec and triggers an event to
  # recalculate.
  setActiveTalents: (talents) ->
    Shadowcraft.Data.activeTalents = talents

    rowTalents = talents.split("")
    for column,row in rowTalents
      if (column == '.')
        $("#talentframe .talent.row-#{row}").addClass("active")
      else
        $("#talentframe .talent.row-#{row}").removeClass("active")
        $("#talentframe .talent.row-#{row}.col-#{column}").addClass("active")

    Shadowcraft.update()
    checkForWarnings("talents")

  # Sets the tree to display the talents for a spec. This will leave all of
  # the icons disabled. setActiveTalents() should be called after this method
  # to setup the active ones.
  setSpec: (spec) ->

    app = this
    buffer = Templates.specActive({
      name: getSpecName(spec)
      icon: SPEC_ICONS[spec]
    })
    $("#specactive").get(0).innerHTML = buffer

    Talents = Shadowcraft.ServerData.TALENTS
    TalentLookup = Shadowcraft.ServerData.TALENT_LOOKUP

    talentTiers = [{tier:"0",level:"15"},{tier:"1",level:"30"},{tier:"2",level:"45"},
                   {tier:"3",level:"60"},{tier:"4",level:"75"},{tier:"5",level:"90"},
                   {tier:"6",level:"100"}]
    buffer = Templates.talentTier({
      levels: talentTiers
    })

    # Filter the talents to just the ones needed for the current spec and build
    # the HTML for all of their icons
    tree = Talents.filter((talent) ->
      return (parseInt(talent.tier, 10) <= (talentTiers.length-1)) && (talent.spec == spec)
    )
    buffer += Templates.talentTree({
      background: 1,
      talents: tree
    })

    talentframe = $("#talentframe")
    tframe = talentframe.get(0)
    tframe.innerHTML = buffer
    $(".tree, .tree .talent, .tree .talent").disableTextSelection()

    # TODO: it seems terrible to redo all of this every time vs building the tree
    # and just resetting the icons and the active talents on each pass.
    talentTrees = $("#talentframe .tree")
    $("#talentframe .talent").each(->
      row = parseInt(this.className.match(/row-(\d)/)[1], 10)
      col = parseInt(this.className.match(/col-(\d)/)[1], 10)
      $this = $(this)
      talent = TalentLookup[spec + ":" + row + ":" + col]
      $.data(this, "position", {row: row, col: col})
      $.data(this, "talent", talent)
    ).mousedown((e) ->
      switch(e.button)
        when 0
          if (app.applyTalent(this, true))
            Shadowcraft.update()
            Shadowcraft.Talents.trigger("changedTalents")
          checkForWarnings("talents")
        when 2
          return if !$(this).hasClass("active")
          if (app.applyTalent(this, false))
            Shadowcraft.update()
            Shadowcraft.Talents.trigger("changedTalents")
          checkForWarnings("talents")

      $(this).trigger("mouseenter")
    ).bind("contextmenu", -> false )
    .mouseenter($.delegate
      ".tt": ttlib.requestTooltip
    )
    .mouseleave($.delegate
      ".tt": ttlib.hide
    )

    # Clear everything out of the talent ranking sections
    for row in [15,30,45,60,75,90,100,110]
      $("#talentrankings .Tier"+row).empty()

    # Post an event to listeners that the spec changed
    Shadowcraft.Data.activeSpec = spec
    Shadowcraft.Talents.trigger("changedSpec", spec)
    return

  updateTalentRanking = ->
    buffer = ""
    ranking = Shadowcraft.lastCalculation.talent_ranking
    max = 0
    for row,row_data of ranking
      target = $("#talentrankings .Tier"+row)
      max = 0
      for talent,ep of row_data
        if ep > max
          max = ep
          
      buffer = ""
      
      for talent,ep of row_data
        if ep == "not implemented" or ep == "implementation error"
          ep = 0.0
        val = Math.round(parseFloat(ep) * 100.0)/ 100.0
        talent_name = TALENT_NAMES[talent]
        pct = val / max * 100 + 0.01

        # Only add the trait to the list the first time through this loop.
        # On subsequent passes the element just gets resized below.
        exist = target.find("#talent-weight-"+talent)
        if exist.length == 0
          buffer = Templates.talentContribution({
            name: "#{talent_name}"
            raw_name: "#{talent}"
            val: val
            width: pct
          })
          target.append(buffer)

        # Resize this element in the list to not be bigger than the actual
        # space.
        exist = target.find("#talent-weight-"+talent)
        $.data(exist.get(0), "val", val)
        exist.show().find(".pct-inner").css({width:pct+"%"})
        exist.find(".label").text("#{val}")

      # sort all of the elements so the biggest ones are at the top
      target.find(".talent_contribution").sortElements (a,b) ->
        ad = $.data(a, "val")
        bd = $.data(b, "val")
        if ad > bd then -1 else 1

    return

  boot: ->
    app = this
    this.initSidebar()

    Shadowcraft.Backend.bind("recompute", updateTalentRanking)

    data = Shadowcraft.Data
    if not data.activeSpec
      data.activeSpec = data.talents[data.active].spec
      data.activeTalents = data.talents[data.active].talents

    this.setSpec(data.activeSpec)
    this.setActiveTalents(data.activeTalents)

    $("#reset_talents").click(app.resetTalents)

    Shadowcraft.bind "loadData", ->
      app.setSpec(this.Data.activeSpec)
      app.setActiveTalents(this.Data.activeTalents)

    $("#talents #talentframe").mousemove (e) ->
      $.data document, "mouse-x", e.pageX
      $.data document, "mouse-y", e.pageY
    this

  constructor: (@app) ->
    @app.Talents = this
    _.extend(this, Backbone.Events)
