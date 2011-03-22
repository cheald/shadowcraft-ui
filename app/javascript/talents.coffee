class ShadowcraftTalents
  talentsSpent = 0
  MAX_TALENT_POINTS = 41
  TREE_SIZE = [19, 19, 19]
  ALWAYS_SHOW_GLYPHS = [45767]
  DEFAULT_SPECS =
    "Stock Assassination":
      talents: "033323011302211032100200000000000000002030030000000000000"
      glyphs: [45768, 42956, 42969, 45767]
    "Stock Combat":
      talents: "023200000000000000023322303100300123210030000000000000000"
      glyphs: [42972, 42954, 42973, 45767]
    "Stock Subtlety":
      talents: "023003000000000000000200000000000000000332031321310012321"
      glyphs: [42956, 42973, 45764, 45767]

  @GetPrimaryTreeName = ->
    if Shadowcraft.Data.tree0 >= 31
      "Mutilate"
    else if Shadowcraft.Data.tree1 >= 31
      "Combat"
    else
      "Subtlety"

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
    trees = s.split("Z")
    talents = ""
    for tree, index in trees
      treestr = ""
      for i in [0..Math.floor(TREE_SIZE[index] / 2)]
        character = tree[i]
        if character
          idx = talentMap.indexOf(character)
          a = Math.floor(idx / 5)
          b = idx % 5
        else
          a = "0"
          b = "0"
        treestr += a
        if treestr.length < TREE_SIZE[index]
          treestr += b
      talents += treestr
    return talents

  sumDigits = (s) ->
    total = 0
    for c in s
      total += parseInt(c)
    return total

  getSpecFromString = (s) ->
    if sumDigits(s.substr(0, TREE_SIZE[0])) >= 31
      return "Assassination"
    else if sumDigits(s.substr(TREE_SIZE[0], TREE_SIZE[1])) >= 31
      return "Combat"
    else
      return "Subtlety"

  updateTalentAvailability = (selector) ->
    talents = if selector then selector.find(".talent") else $("#talentframe .tree .talent")
    talents.each ->
      $this = $(this)
      pos = $.data(this, "position")
      tree = $.data(pos.tree, "info")
      icons = $.data(this, "icons")
      if tree.points < (pos.row) * 5
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
    ct = 0
    $("#talentframe .talent").each ->
      points = $.data(this, "points")
      applyTalentToButton(this, parseInt(str[ct], 10) - points.cur, true, true)
      ct++
    data.activeTalents = getTalents()
    updateTalentAvailability(null)

  getTalents = ->
    return _.map($("#talentframe .talent"), (t) ->
      $.data(t, "points").cur || 0
    ).join("")

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
      prequal = 0
      for tier in [0..position.row]
        prequal += tree.rowPoints[tier]
      if tree.rowPoints[position.row+1] and tree.rowPoints[position.row+1] > 0
        return false if prequal <= (position.row+1) * 5
      success = true if points.cur > 0

    if success
      points.cur += dir
      tree.points += dir
      talentsSpent += dir
      tree.rowPoints[position.row] += dir

      Shadowcraft.Data["tree" + position.treeIndex] = tree.points
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
    data = @app.Data
    if not data.activeTalents
      data.activeTalents = data.talents[data.active].talents
    setTalents data.activeTalents

  initTalentsPane: ->
    Talents = Shadowcraft.ServerData.TALENTS
    TalentLookup = Shadowcraft.ServerData.TALENT_LOOKUP
    data = Shadowcraft.Data

    buffer = ""
    for treeIndex, tree of Talents
      buffer += Templates.talentTree({
        background: tree.bgImage,
        talents: tree.talent
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
      talent = TalentLookup[tree + ":" + row + ":" + col]
      $.data(this, "position", {tree: myTree, treeIndex: tree, row: row, col: col})
      $.data(myTree, "info", {points: 0, rowPoints: [0, 0, 0, 0, 0, 0, 0]})
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
        talent_string: ShadowcraftTalents.encodeTalents(talent.talents)
        glyphs: talent.glyphs.join(",")
        name: "Imported " + getSpecFromString(talent.talents)
      })

    for talentName, talentSet of DEFAULT_SPECS
      buffer += Templates.talentSet({
        talent_string: ShadowcraftTalents.encodeTalents(talentSet.talents),
        glyphs: talentSet.glyphs.join(",")
        name: talentName
      })

    $("#talentsets").get(0).innerHTML = buffer
    this.updateActiveTalents()
    initTalentsPane = ->

  setGlyphs: (glyphs) ->
    Shadowcraft.Data.glyphs = glyphs
    this.initGlyphs()

  initGlyphs: ->
    buffer = [null, "", "", ""]
    Glyphs = Shadowcraft.ServerData.GLYPHS
    data = Shadowcraft.Data
    if not data.glyphs
      data.glyphs = data.talents[data.active].glyphs

    for g, idx in Glyphs
      buffer[g.rank] += Templates.glyphSlot(g)

    $("#prime-glyphs .inner").get(0).innerHTML = buffer[3]
    $("#major-glyphs .inner").get(0).innerHTML = buffer[2]
    # $("#minor-glyphs .inner").get(0).innerHTML = buffer[1]

    return unless data.glyphs?
    for glyph, i in data.glyphs
      g = $(".glyph_slot[data-id='" + glyph + "']")
      toggleGlyph(g, true) if g.length > 0

  updateGlyphWeights = (data) ->
    max = _.max(data.glyph_ranking)
    $(".glyph_slot:not(.activated)").hide()
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
        talents = ShadowcraftTalents.decodeTalents $(this).data("talents")
        glyphs = ($(this).data("glyphs") || "").split(",")
        for glyph, i in glyphs
          glyphs[i] = parseInt(glyph, 10)
        glyphs = _.compact(glyphs)

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