class ShadowcraftTalents
  talentsSpent = 0
  MAX_TALENT_POINTS = 7
  TREE_SIZE = 7
  CHARACTER_SPEC = ""
  SPEC_ICONS =
    "a": "ability_rogue_eviscerate"
    "Z": "ability_backstab"
    "b": "ability_stealth"
    "": "class_rogue"
  DEFAULT_SPECS =
    "Stock Assassination":
      talents: "2211021"
      spec: "a"
    "Stock Combat":
      talents: "2211011"
      spec: "Z"
    "Stock Subtlety":
      talents: "1210011"
      spec: "b"

  @GetActiveSpecName = ->
    activeSpec = getSpec()
    if activeSpec
      return getSpecName(activeSpec)
    return ""

  getSpecName = (s) ->
    if s == "a"
      return "Assassination"
    else if s == "Z"
      return "Combat"
    else if s == "b"
      return "Subtlety"
    else
      return "Rogue"

  updateTalentAvailability = (selector) ->
    talents = if selector then selector.find(".talent") else $("#talentframe .tree .talent")
    talents.each ->
      $this = $(this)
      pos = $.data(this, "position")
      points = $.data(this, "points")
      tree = $.data(pos.tree, "info")
      icons = $.data(this, "icons")
      if tree.rowPoints[pos.row] >= 1 and points.cur != 1
        $this.css({backgroundImage: icons.grey}).removeClass("active")
      else
        $this.css({backgroundImage: icons.normal}).addClass("active")
    Shadowcraft.Talents.trigger("changed")
    Shadowcraft.update()
    checkForWarnings("talents")

  resetTalents = ->
    data = Shadowcraft.Data
    $("#talentframe .talent").each ->
      points = $.data(this, "points")
      applyTalentToButton(this, -points.cur, true, true)
    data.activeTalents = getTalents()
    updateTalentAvailability()

  setTalents = (str) ->
    data = Shadowcraft.Data
    if !str
      updateTalentAvailability(null)
      return
    talentsSpent = 0
    $("#talentframe .talent").each ->
      position = $.data(this, "position")
      points = $.data(this, "points")
      p = 0
      if str[position.row] != "." and position.col == parseInt(str[position.row], 10)
        p = 1
      applyTalentToButton(this, p - points.cur, true, true)
    data.activeTalents = getTalents()
    updateTalentAvailability(null)

  getTalents = ->
    talent_rows = ['.','.','.','.','.','.','.']
    $("#talentframe .talent").each ->
      position = $.data(this, "position")
      points = $.data(this, "points")
      if points.cur == 1
        talent_rows[position.row] = position.col
    talent_rows.join('')

  setSpec = (str) ->
    data = Shadowcraft.Data
    buffer = Templates.specActive({
      name: getSpecName(str)
      icon: SPEC_ICONS[str]
    })
    $("#specactive").get(0).innerHTML = buffer
    Shadowcraft.Talents.trigger("changedSpec", str)
    data.activeSpec = str

  getSpec = ->
    data = Shadowcraft.Data
    return data.activeSpec

  applyTalentToButton = (button, dir, force, skipUpdate) ->
    data = Shadowcraft.Data

    points = $.data(button, "points")
    position = $.data(button, "position")

    tree = $.data(position.tree, "info")
    success = false
    if force
      success = true
    else if dir == 1 && points.cur < points.max # && talentsSpent < MAX_TALENT_POINTS
      success = true
      # a bit hacky but otherwise I had to rewrite the complete talent module
      $("#talentframe .talent").each ->
        position2 = $.data(this, "position")
        points2 = $.data(this, "points")
        if points2.cur == 1 and position2.row == position.row
          applyTalentToButton(this, -points2.cur)
    else if dir == -1
      success = true

    if success
      points.cur += dir
      tree.points += dir
      talentsSpent += dir
      tree.rowPoints[position.row] += dir

      unless skipUpdate
        data.activeTalents = getTalents()
        updateTalentAvailability $(button).parent()
    return success

  updateActiveTalents: ->
    data = Shadowcraft.Data
    if not data.activeSpec
      data.activeTalents = data.talents[data.active].talents
      data.activeSpec = data.talents[data.active].spec
    setSpec data.activeSpec
    setTalents data.activeTalents

  initTalentTree: ->
    Talents = Shadowcraft.ServerData.TALENTS_WOD
    TalentLookup = Shadowcraft.ServerData.TALENT_LOOKUP_WOD

    buffer = ""

    talentTiers = [{tier:"0",level:"15"},{tier:"1",level:"30"},{tier:"2",level:"45"},{tier:"3",level:"60"},{tier:"4",level:"75"},{tier:"5",level:"90"},{tier:"6",level:"100"}]
    talentTiers = _.filter(talentTiers, (tier) ->
      return tier.level <= (Shadowcraft.Data.options.general.level || 100)
    )

    buffer += Templates.talentTier({
      background: 1,
      levels: talentTiers
    })
    for treeIndex, tree of Talents
      tree = _.filter(tree, (talent) ->
        return parseInt(talent.tier, 10) <= (talentTiers.length-1)
      )
      buffer += Templates.talentTree({
        background: 1,
        talents: tree
      })
    talentframe = $("#talentframe")
    tframe = talentframe.get(0)
    tframe.innerHTML = buffer
    $(".tree, .tree .talent, .tree .talent").disableTextSelection()

    talentTrees = $("#talentframe .tree")
    $("#talentframe .talent").each(->
      row = parseInt(this.className.match(/row-(\d)/)[1], 10)
      col = parseInt(this.className.match(/col-(\d)/)[1], 10)
      $this = $(this)
      trees = $this.closest(".tree")
      myTree = trees.get(0)
      tree = talentTrees.index(myTree)
      talent = TalentLookup[row + ":" + col]
      $.data(this, "position", {tree: myTree, treeIndex: tree, row: row, col: col})
      $.data(myTree, "info", {points: 0, rowPoints: [0, 0, 0, 0, 0, 0, 0]})
      $.data(this, "talent", talent)
      $.data(this, "points", {cur: 0, max: talent.maxRank})
      $.data(this, "icons", {grey: $this.css("backgroundImage"), normal: $this.css("backgroundImage").replace(/\/grey\//, "/")})
    ).mousedown((e) ->
      return if Modernizr.touch
      switch(e.button)
        when 0
          Shadowcraft.update() if applyTalentToButton(this, 1)
        when 2
          return if !$(this).hasClass("active")
          Shadowcraft.update() if applyTalentToButton(this, -1)

      $(this).trigger("mouseenter")
    ).bind("contextmenu", -> false )
    .mouseenter($.delegate
      ".tt": ttlib.requestTooltip
    )
    .mouseleave($.delegate
      ".tt": ttlib.hide
    )
    .bind("touchstart", (e) ->
      $.data(this, "removed", false)
      $.data(this, "listening", true)
      $.data(tframe, "listening", this)
    ).bind("touchend", (e) ->
      $.data(this, "listening", false)
      unless $.data(this, "removed") or !$(this).hasClass("active")
        Shadowcraft.update() if applyTalentToButton(this, 1)
    )

    talentframe.bind("touchstart", (e) ->
      listening = $.data(tframe, "listening")
      if e.originalEvent.touches.length > 1 and listening and $.data(listening, "listening")
        Shadowcraft.update() if applyTalentToButton.call(listening, listening, -1)
        $.data(listening, "removed", true)
    )

  initTalentsPane: ->
    this.initTalentTree()

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
    this.updateActiveTalents()

  updateTalentContribution = (LC) ->
    return unless LC.talent_ranking
    sets = {
      "Primary": LC.talent_ranking,
    }
    rankings = _.extend({}, LC.talent_ranking)
    max = _.max(rankings)
    $("#talentrankings .talent_contribution").hide()
    for setKey, setVal of sets
      buffer = ""
      target = $("#talentrankings ." + setKey)
      for k, s of setVal
        exist = $("#talentrankings #talent-weight-" + k)
        val = parseInt(s, 10)
        name = k.replace(/_/g, " ").capitalize
        if isNaN(val)
          name += " (NYI)"
          val = 0

        pct = val / max * 100 + 0.01

        if exist.length == 0
          buffer = Templates.talentContribution({
            name: name,
            raw_name: k,
            val: val.toFixed(1),
            width: pct
          })
          target.append(buffer)

        exist = $("#talentrankings #talent-weight-" + k)
        $.data(exist.get(0), "val", val)
        exist.show().find(".pct-inner").css({width: pct + "%"})
        exist.find(".name").text(name)
        exist.find(".label").text(val.toFixed(1))

    $("#talentrankings .talent_contribution").sortElements (a, b) ->
      ad = $.data(a, "val")
      bd = $.data(b, "val")
      if ad > bd then -1 else 1

  boot: ->
    this.initTalentsPane()
    app = this

    Shadowcraft.Backend.bind("recompute", updateTalentContribution)

    $("#talentsets").click $.delegate({
      ".talent_set": ->
        spec = $(this).data("spec")
        talents = $(this).data("talents")+""
        setSpec spec
        setTalents talents
    })
    $("#reset_talents").click(resetTalents)

    Shadowcraft.bind "loadData", ->
      app.updateActiveTalents()

    Shadowcraft.Options.bind "update", (opt, val) ->
      if opt in ['general.patch','general.level']
        app.initTalentTree()
        app.updateActiveTalents()
        checkForWarnings('options')

    $("#talents #talentframe").mousemove (e) ->
      $.data document, "mouse-x", e.pageX
      $.data document, "mouse-y", e.pageY
    this

  constructor: (@app) ->
    @app.Talents = this
    @resetTalents = resetTalents
    @setTalents = setTalents
    @getTalents = getTalents
    _.extend(this, Backbone.Events)
