class ShadowcraftBackend
  HTTP_ENGINE = "http://#{window.location.hostname}:8880/"
  WS_ENGINE   = "ws://#{window.location.hostname}:8880/engine"

  constructor: (@app) ->
    @app.Backend = this
    @dpsHistory = []
    @snapshotHistory = []
    @dpsIndex = 0
    _.extend(this, Backbone.Events)

  boot: ->
    self = this
    Shadowcraft.bind("update", -> self.recompute())
    @ws = $.websocket(WS_ENGINE, {
      error: (e)-> console.log(e)
      events:
        response: (e) -> self.handleRecompute(e.data)
    })
    this

  buildPayload: ->
    data = Shadowcraft.Data
    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP
    Talents = Shadowcraft.ServerData.TALENTS
    statSum = Shadowcraft.Gear.statSum
    Gems = Shadowcraft.ServerData
    GlyphLookup = Shadowcraft.ServerData.GLYPH_LOOKUP

    statSummary = Shadowcraft.Gear.sumStats()

    mh = ItemLookup[data.gear[15].item_id] if data.gear[15]
    oh = ItemLookup[data.gear[16].item_id] if data.gear[16]
    th = ItemLookup[data.gear[17].item_id] if data.gear[17]
    glyph_list = []

    for glyph in data.glyphs
      if GlyphLookup[glyph]?
        glyph_list.push GlyphLookup[glyph].ename

    buffList = []
    for key, val of data.options.buffs
      if val
        buffList.push ShadowcraftOptions.buffMap.indexOf(key)

    payload =
      r: data.options.general.race
      l: data.options.general.level
      b: buffList
      ro: data.options.rotation,
      settings: {
        # tricks: data.options.general.tricks
        mh_poison: data.options.general.mh_poison
        oh_poison: data.options.general.oh_poison
        duration: data.options.general.duration
      }
      t: [
        data.activeTalents.substr(0, Talents[0].talent.length)
        data.activeTalents.substr(Talents[0].talent.length, Talents[1].talent.length)
        data.activeTalents.substr(Talents[0].talent.length + Talents[1].talent.length, Talents[2].talent.length)
      ],
      sta: [
        statSummary.strength || 0,
        statSummary.agility || 0,
        statSummary.attack_power || 0,
        statSummary.crit_rating || 0,
        statSummary.hit_rating || 0,
        statSummary.expertise_rating || 0,
        statSummary.haste_rating || 0,
        statSummary.mastery_rating || 0
      ],
      gly: glyph_list,
      pro: data.options.professions

    if mh?
      payload.mh = [
        mh.speed
        mh.dps * mh.speed
        data.gear[15].enchant
        mh.subclass
      ]
    if oh?
      payload.oh = [
        oh.speed,
        oh.dps * oh.speed,
        data.gear[16].enchant,
        oh.subclass
      ]
    if th?
      payload.th = [
        th.speed,
        th.dps * th.speed,
        data.gear[17].enchant,
        th.subclass
      ]

    gear_ids = []
    for k, g of data.gear
      gear_ids.push(g.item_id);
      if k == 0 && g.g0 && Gems[g.g0] && Gems[g.g0].Meta
        if ShadowcraftGear.CHAOTIC_METAGEMS.indexOf(g.g0)
          payload.mg = "chaotic"

    payload.g = gear_ids
    payload

  handleRecompute: (data) ->
    Shadowcraft.Console.remove(".error")

    if data.error
      Shadowcraft.Console.warn {}, data.error, null, "error", "error"
      return

    if data.total_dps != @lastDPS && !loadingSnapshot
      snapshot = Shadowcraft.History.takeSnapshot()

    @app.lastCalculation = data
    this.trigger("recompute", data);

    if data.total_dps != @lastDPS || loadingSnapshot
      delta = data.total_dps - (@lastDPS || 0)
      deltatext = ""
      if @lastDPS
        deltatext = if delta >= 0 then " <em class='p'>(+#{delta.toFixed(1)})</em>" else " <em class='n'>(#{delta.toFixed(1)})</em>"

      $("#dps .inner").html(data.total_dps.toFixed(1) + " DPS" + deltatext)

      if snapshot
        @dpsHistory.push [@dpsIndex, Math.floor(data.total_dps * 10) / 10]
        @dpsIndex++
        @snapshotHistory.push(snapshot)
        if @dpsHistory.length > 30
          @dpsHistory.shift()
          @snapshotHistory.shift()

        dpsPlot = $.plot($("#dpsgraph"), [@dpsHistory], {
          lines: { show: true },
          crosshair: { mode: "y" },
          points: { show: true },
          grid: { hoverable: true, clickable: true, autoHighlight: true },
        })
      @lastDPS = data.total_dps
    loadingSnapshot = false;

  recompute: ->
    @cancelRecompute = false
    payload = this.buildPayload()
    return if @cancelRecompute or not payload?

    if window.WebSocket
      this.recompute_via_websocket payload
    else
      this.recompute_via_post payload

  recompute_via_websocket: (payload) ->
    @ws.send "m", payload

  recompute_via_post: (payload) ->
   if $.browser.msie and window.XDomainRequest
      this.recompute_via_xdr payload
    else
      this.recompute_via_xhr payload

  recompute_via_xdr: (payload) ->
    xdr = new XDomainRequest()
    # We have to use GET because Twisted expects a proper form header for POST data, which XDR can't send. Yay IE.
    xdr.open "get", HTTP_ENGINE + "?rnd=#{new Date().getTime()}&data=" + JSON.stringify(payload)
    xdr.send()
    xdr.onload = ->
      data = JSON.parse xdr.responseText
      app.handleRecompute(data)

  recompute_via_xhr: (payload) ->
    app = this
    $.post(HTTP_ENGINE, {
      data: $.toJSON(payload)
    }, (data) ->
      app.handleRecompute(data);
    , 'json')

loadingSnapshot = false
