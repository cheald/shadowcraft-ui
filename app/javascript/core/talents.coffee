class ShadowcraftTalents
  talentsSpent = 0
  MAX_TALENT_POINTS = 6
  TREE_SIZE = 6
  ALWAYS_SHOW_GLYPHS = []
  CHARACTER_SPEC = ""
  DEFAULT_SPECS =
    "Stock Assassination":
      talents: "221102"
      glyphs: [45761]
      spec: "a"
    "Stock Combat":
      talents: "221102"
      glyphs: [42972]
      spec: "Z"
    "Stock Subtlety":
      talents: "221002"
      glyphs: []
      spec: "b"

  @GetActiveSpecName = ->
    activeSpec = getSpec()
    if activeSpec
      return getSpecName(activeSpec)
    return ""
  
  # not used anymore
  talentMap = "0zMcmVokRsaqbdrfwihuGINALpTjnyxtgevElBCDFHJKOPQSUWXYZ123456789"
  @encodeTalents = (s) ->
    str = ""
    offset = 0
    for size, index in TREE_SIZE
      sub = s.substr(offset, size).replace(/0+$/, "")
      offset += size
      for c, i in sub by 2
        l = parseInt(c, 10) * 5 + parseInt(sub[i+1] || 0, 10)
        str += talentMap[l]
      str += "Z" unless index == TREE_SIZE.length - 1
    return str

  @decodeTalents = (s) ->
    talents = ""
    #for char, index in s.split ''
      # Needs to be fleshed out
    return s

  sumDigits = (s) ->
    total = 0
    for c in s
      total += parseInt(c)
    return total

  getSpecName = (s) ->
    if s == "a"
      return "Assassination"
    else if s == "Z"
      return "Combat"
    else
      return "Subtlety"

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

  hoverTalent = ->
    return if window.Touch?
    points = $.data(this, "points")
    talent = $.data(this, "talent")
    rank = if talent.rank.length then talent.rank[points.cur - 1] else talent.rank
    nextRank = if talent.rank.length then talent.rank[points.cur] else null
    pos = $(this).offset()
    tooltip({
      title: talent.name + " (" + points.cur + "/" + points.max + ")",
      desc: if rank then rank.description else null,
      nextdesc: if nextRank then "Next rank: " + nextRank.description else null

    }, pos.left, pos.top, 130, -20)

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
    data = Shadowcraft.Data
    talent_rows = ['.','.','.','.','.','.']
    $("#talentframe .talent").each ->
      position = $.data(this, "position")
      points = $.data(this, "points")
      if points.cur == 1
        talent_rows[position.row] = position.col
    talent_rows.join('')

  setSpec = (str) ->
    data = Shadowcraft.Data
    $("#specactive").html(getSpecName(str)) #TODO working but is html the right function?
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
    else if dir == 1 && points.cur < points.max && talentsSpent < MAX_TALENT_POINTS
      success = true
    else if dir == -1
      success = true

    if success
      points.cur += dir
      tree.points += dir
      talentsSpent += dir
      tree.rowPoints[position.row] += dir

      #Shadowcraft.Data["tree" + position.treeIndex] = tree.points
      $.data(button, "spentButton").text(tree.points)
      $points = $.data(button, "pointsButton")
      $points.get(0).className = "points"
      if points.cur == points.max
        $points.addClass("full")
      else if points.cur > 0
        $points.addClass("partial")
      $points.text(points.cur + "/" + points.max)
      unless skipUpdate
        data.activeTalents = getTalents()
        updateTalentAvailability $(button).parent()
    return success

  updateActiveTalents: ->
    data = Shadowcraft.Data
    if not data.activeTalents
      data.activeTalents = data.talents[data.active].talents
      data.activeSpec = data.talents[data.active].spec
    setSpec data.activeSpec
    setTalents data.activeTalents

  initTalentsPane: ->
    Talents = Shadowcraft.ServerData.TALENTS
    TalentLookup = Shadowcraft.ServerData.TALENT_LOOKUP
    data = Shadowcraft.Data

    buffer = ""
    buffer += Templates.talentTier({
      background: 1,
      levels: [{tier:"0",level:"15"},{tier:"1",level:"30"},{tier:"2",level:"45"},{tier:"3",level:"60"},{tier:"4",level:"75"},{tier:"5",level:"90"}]
    })
    for treeIndex, tree of Talents
      buffer += Templates.talentTree({
        background: 1,
        talents: tree
      })
    talentframe = $("#talentframe")
    tframe = talentframe.get(0)
    tframe.innerHTML = buffer
    $(".tree, .tree .talent, .tree .talent .points").disableTextSelection()

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
      $.data(myTree, "info", {points: 0, rowPoints: [0, 0, 0, 0, 0, 0]})
      $.data(this, "talent", talent)
      $.data(this, "points", {cur: 0, max: talent.maxRank})
      $.data(this, "pointsButton", $this.find(".points"))
      $.data(this, "spentButton", trees.find(".spent"))
      $.data(this, "icons", {grey: $this.css("backgroundImage"), normal: $this.css("backgroundImage").replace(/\/grey\//, "/")})
    ).mousedown((e) ->
      return if !$(this).hasClass("active")
      return if window.Touch?

      switch(e.button)
        when 0
          Shadowcraft.update() if applyTalentToButton(this, 1)
        when 2
          Shadowcraft.update() if applyTalentToButton(this, -1)

      $(this).trigger("mouseenter")
    ).bind("contextmenu", -> false )
    .mouseenter(hoverTalent)
    .mouseleave(-> $("#tooltip").hide() )
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

    buffer = ""
    for talent in data.talents
      buffer += Templates.talentSet({
        talent_string: talent.talents,
        glyphs: talent.glyphs.join(","),
        name: "Imported " + getSpecName(talent.spec),
        spec: talent.spec
      })

    for talentName, talentSet of DEFAULT_SPECS
      buffer += Templates.talentSet({
        talent_string: talentSet.talents,
        glyphs: talentSet.glyphs.join(","),
        name: talentName,
        spec: talentSet.spec
      })

    $("#talentsets").get(0).innerHTML = buffer
    this.updateActiveTalents()
    initTalentsPane = ->

  setGlyphs: (glyphs) ->
    Shadowcraft.Data.glyphs = glyphs
    this.initGlyphs()

  initGlyphs: ->
    buffer = [null, "", ""]
    Glyphs = Shadowcraft.ServerData.GLYPHS
    data = Shadowcraft.Data
    if not data.glyphs
      data.glyphs = data.talents[data.active].glyphs

    for g, idx in Glyphs
      buffer[g.rank] += Templates.glyphSlot(g)

    $("#major-glyphs .inner").get(0).innerHTML = buffer[1]
    $("#minor-glyphs .inner").get(0).innerHTML = buffer[2]

    return unless data.glyphs?
    for glyph, i in data.glyphs
      g = $(".glyph_slot[data-id='" + glyph + "']")
      toggleGlyph(g, true) if g.length > 0

  updateGlyphWeights = (data) ->
    max = _.max(data.glyph_ranking)
    # $(".glyph_slot:not(.activated)").hide()
    $(".glyph_slot .pct-inner").css({width: 0})
    for key, weight of data.glyph_ranking
      g = Shadowcraft.ServerData.GLYPHNAME_LOOKUP[key]
      if g
        width = weight / max * 100
        slot = $(".glyph_slot[data-id='" + g.id + "']")
        $.data(slot[0], "weight", weight)
        $.data(slot[0], "name", g.name)
        slot.show().find(".pct-inner").css({width: width + "%"})
        slot.find(".label").text(weight.toFixed(1) + " DPS")

    for id in ALWAYS_SHOW_GLYPHS
      $(".glyph_slot[data-id='#{id}']").show()

    glyphSets = $(".glyphset")
    for glyphSet in glyphSets
      $(glyphSet).find(".glyph_slot").sortElements (a, b) ->
        aw = $.data(a, "weight")
        bw = $.data(b, "weight")
        an = $.data(a, "name")
        bn = $.data(b, "name")
        aw ||= -1; bw ||= -1; an ||= ""; bn ||= ""
        if aw != bw
          if aw > bw then -1 else 1
        else
          if an > bn then 1 else -1

  glyphRankCount = (rank, g) ->
    data = Shadowcraft.Data
    GlyphLookup = Shadowcraft.ServerData.GLYPH_LOOKUP
    if g and !rank
      rank = GlyphLookup[g].rank

    count = 0
    for glyph in data.glyphs
      if GlyphLookup[glyph]?
        count++ if GlyphLookup[glyph].rank == rank
    count

  toggleGlyph = (e, override) ->
    GlyphLookup = Shadowcraft.ServerData.GLYPH_LOOKUP
    data = Shadowcraft.Data

    $e = $(e)
    $set = $e.parents(".glyphset")
    id = parseInt($e.data("id"), 10)
    glyph = GlyphLookup[id]
    if $e.hasClass("activated")
      $e.removeClass("activated")
      data.glyphs = _.without(data.glyphs, id)
      $set.removeClass("full")
    else
      return if glyphRankCount(null, id) >= 3 and !override
      $e.addClass("activated")
      if !override and data.glyphs.indexOf(id) == -1
        data.glyphs.push(id)
      if glyphRankCount(null, id) >= 3
        $set.addClass("full")

    checkForWarnings('glyphs')
    Shadowcraft.update()

  updateTalentContribution = (LC) ->
    return unless LC.talent_ranking_main
    sets = {
      "Primary": LC.talent_ranking_main,
      "Secondary": LC.talent_ranking_off
    }
    rankings = _.extend({}, LC.talent_ranking_main, LC.talent_ranking_off)
    max = _.max(rankings)
    $("#talentrankings .talent_contribution").hide()
    for setKey, setVal of sets
      buffer = ""
      target = $("#talentrankings ." + setKey)
      for k, s of setVal
        exist = $("#talentrankings #talent-weight-" + k)
        val = parseInt(s, 10)
        name = k.replace(/_/g, " ").capitalize()
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
        exist.find(".label").text(val.toFixed(1))

    $("#talentrankings .talent_contribution").sortElements (a, b) ->
      ad = $.data(a, "val")
      bd = $.data(b, "val")
      if ad > bd then -1 else 1

  boot: ->
    this.initTalentsPane()
    this.initGlyphs()
    app = this

    Shadowcraft.Backend.bind("recompute", updateTalentContribution)
    Shadowcraft.Backend.bind("recompute", updateGlyphWeights)

    $("#glyphs").click($.delegate
      ".glyph_slot": -> toggleGlyph(this)
    ).mouseover($.delegate
      ".glyph_slot": ttlib.requestTooltip
    ).mouseout($.delegate
      ".glyph_slot": ttlib.hide
    )

    $("#talentsets").click $.delegate({
      ".talent_set": ->
        spec = $(this).data("spec")
        talents = $(this).data("talents")+""
        glyphs = ($(this).data("glyphs")+"" || "").split ","
        for glyph, i in glyphs
          glyphs[i] = parseInt(glyph, 10)
        glyphs = _.compact(glyphs)
        setSpec spec
        setTalents talents
        app.setGlyphs glyphs
    })
    $("#reset_talents").click(resetTalents)

    Shadowcraft.bind "loadData", ->
      app.updateActiveTalents()
      app.initGlyphs()

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
