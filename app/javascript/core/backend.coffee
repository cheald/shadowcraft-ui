class ShadowcraftBackend
  # WS_ENGINE   = "ws://#{window.location.hostname}:#{port}/engine"

  get_engine = ->
    switch Shadowcraft.Data.options.general.patch
      when 50
        port = 8881
        endpoint = "engine-5.0"
      else
        port = 8881
        endpoint = "engine-4.1"

    if window.location.host.match(/:/)
        "http://#{window.location.hostname}:#{port}/#{endpoint}"
    else
      "http://#{window.location.hostname}/#{endpoint}"

  constructor: (@app) ->
    @app.Backend = this
    _.extend(this, Backbone.Events)

  boot: ->
    self = this
    Shadowcraft.bind("update", -> self.recompute())
    this

  buildPayload: ->
    data = Shadowcraft.Data
    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP
    Talents = Shadowcraft.ServerData.TALENTS
    statSum = Shadowcraft.Gear.statSum
    Gems = Shadowcraft.ServerData.GEM_LOOKUP
    GlyphLookup = Shadowcraft.ServerData.GLYPH_LOOKUP

    statSummary = Shadowcraft.Gear.sumStats()

    mh = ItemLookup[data.gear[15].item_id] if data.gear[15]
    oh = ItemLookup[data.gear[16].item_id] if data.gear[16]
    glyph_list = []

    for glyph in data.glyphs
      if GlyphLookup[glyph]?
        glyph_list.push GlyphLookup[glyph].ename

    buffList = []
    for key, val of data.options.buffs
      if val
        buffList.push ShadowcraftOptions.buffMap.indexOf(key)

    professions = _.compact( _.map(data.options.professions, (v, k) -> if v then k else null ) )
    
    # TODO find a better solution this is very hacky but working
    talentArray = data.activeTalents.split ""
    talentString = ""
    for val, key in talentArray
      if val == "."
        talentArray[key] = "0"
      else if val == "0"
        talentArray[key] = "1"
      else if val == "1"
        talentArray[key] = "2"
      else if val == "2"
        talentArray[key] = "3"
      talentString += talentArray[key]
    
    payload =
      r: data.options.general.race
      l: data.options.general.level
      pot: if data.options.general.potion_of_the_tolvir then 1 else 0
      prepot: if data.options.general.prepot then 1 else 0
      b: buffList
      ro: data.options.rotation,
      settings: {
        tricks: data.options.general.tricks
        mh_poison: data.options.general.mh_poison
        oh_poison: data.options.general.oh_poison
        duration: data.options.general.duration
      }
      spec: data.activeSpec,
      t: talentString,
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
      #gly: glyph_list, # FIXME glyphs temporary disabled
      pro: professions

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

    gear_ids = []
    for k, g of data.gear
      gear_ids.push(g.item_id)
      if k == "0" && g.g0 && Gems[g.g0] && Gems[g.g0].Meta
        if ShadowcraftGear.CHAOTIC_METAGEMS.indexOf(g.g0) != -1
          payload.mg = "chaotic"

    payload.g = gear_ids
    payload

  handleRecompute: (data) ->
    Shadowcraft.Console.remove(".error")

    if data.error
      Shadowcraft.Console.warn {}, data.error, null, "error", "error"
      return

    if Shadowcraft.Data.options.general.receive_tricks
      data.total_dps *= 1.03
    @app.lastCalculation = data
    this.trigger("recompute2", data)
    this.trigger("recompute", data)

  recompute: (payload = null, forcePost = false) ->
    @cancelRecompute = false
    payload ||= this.buildPayload()
    return if @cancelRecompute or not payload?
    window._gaq.push ['_trackEvent', "Character", "Recompute"] if window._gaq

    if window.WebSocket and not forcePost and false
      this.recompute_via_websocket payload
    else
      this.recompute_via_post payload

  recompute_via_websocket: (payload) ->
    if @ws.readyState != 1
      @recompute(payload, true)
    else
      @ws.send "m", payload

  recompute_via_post: (payload) ->
   if $.browser.msie and window.XDomainRequest
      this.recompute_via_xdr payload
    else
      this.recompute_via_xhr payload

  recompute_via_xdr: (payload) ->
    app = this
    xdr = new XDomainRequest()
    # We have to use GET because Twisted expects a proper form header for POST data, which XDR can't send. Yay IE.
    xdr.open "get", get_engine() + "?rnd=#{new Date().getTime()}&data=" + JSON.stringify(payload)
    xdr.send()
    xdr.onload = ->
      data = JSON.parse xdr.responseText
      app.handleRecompute(data)
    xdr.onerror = ->
      flash "Error contacting backend engine"
      false

  recompute_via_xhr: (payload) ->
    app = this
    $.post(get_engine(), {
      data: $.toJSON(payload)
    }, (data) ->
      app.handleRecompute(data)
    , 'json')

loadingSnapshot = false
