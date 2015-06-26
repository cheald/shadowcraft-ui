class ShadowcraftBackend
  # WS_ENGINE   = "ws://#{window.location.hostname}:#{port}/engine"

  get_engine = ->
    switch Shadowcraft.Data.options.general.patch
      when 63
        port = 8880
        endpoint = "engine-6.3"
        return "http://#{window.location.hostname}:#{port}/#{endpoint}"
      else
        port = 8881
        endpoint = "engine-6.2"
        if window.location.host.match(/:/)
          return "http://#{window.location.hostname}:#{port}/#{endpoint}"
        else
          return "http://#{window.location.hostname}/#{endpoint}"

  constructor: (@app) ->
    @app.Backend = this
    _.extend(this, Backbone.Events)

  boot: ->
    self = this
    Shadowcraft.bind("update", -> self.recompute())
    this

  buildPayload: ->
    data = Shadowcraft.Data
    Gems = Shadowcraft.ServerData.GEM_LOOKUP
    GlyphLookup = Shadowcraft.ServerData.GLYPH_LOOKUP

    statSummary = Shadowcraft.Gear.sumStats()

    mh = Shadowcraft.Gear.getItem(data.gear[15].original_id, data.gear[15].item_level, data.gear[15].suffix) if data.gear[15]
    oh = Shadowcraft.Gear.getItem(data.gear[16].original_id, data.gear[16].item_level, data.gear[16].suffix) if data.gear[16]
    glyph_list = []

    for glyph in data.glyphs
      if GlyphLookup[glyph]?
        glyph_list.push GlyphLookup[glyph].ename

    buffList = []
    for key, val of data.options.buffs
      if val
        buffList.push ShadowcraftOptions.buffMap.indexOf(key)

    buffFood = ShadowcraftOptions.buffFoodMap.indexOf(data.options.buffs.food_buff)
    
    talentArray = data.activeTalents.split ""
    for val, key in talentArray
      talentArray[key] = switch val
        when "." then "0"
        when "0", "1", "2" then parseInt(val,10)+1
    talentString = talentArray.join('')

    # opener
    specName = {a: 'assassination', Z: 'combat', b: 'subtlety'}[data.activeSpec]
    data.options.rotation['opener_name'] = data.options.rotation["opener_name_#{specName}"]
    data.options.rotation['opener_use'] = data.options.rotation["opener_use_#{specName}"]
    
    payload =
      r: data.options.general.race
      l: data.options.general.level
      pot: if data.options.general.potion then 1 else 0
      prepot: if data.options.general.prepot then 1 else 0
      b: buffList
      bf: buffFood
      ro: data.options.rotation
      settings: {
        dmg_poison: data.options.general.lethal_poison
        utl_poison: data.options.general.utility_poison if data.options.general.utility_poison != 'n'
        duration: data.options.general.duration
        response_time: data.options.general.response_time
        time_in_execute_range: data.options.general.time_in_execute_range
        pvp: data.options.general.pvp
        num_boss_adds: data.options.general.num_boss_adds
        latency: data.options.advanced.latency
        adv_params: data.options.advanced.adv_params
        night_elf_racial: data.options.general.night_elf_racial
      }
      spec: data.activeSpec,
      t: talentString,
      sta: [
        statSummary.strength || 0,
        statSummary.agility || 0,
        statSummary.attack_power || 0,
        statSummary.crit || 0,
        statSummary.haste || 0,
        statSummary.mastery || 0,
        statSummary.multistrike || 0,
        statSummary.versatility || 0,
        statSummary.resilience || 0,
        statSummary.pvp_power || 0
      ],
      gly: glyph_list

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
      if g.original_id
        item = [
          g.original_id,
          g.item_level
        ]
        gear_ids.push(item)
#      if k == "0" && g.g0 && Gems[g.g0] && Gems[g.g0].Meta
#        if ShadowcraftGear.CHAOTIC_METAGEMS.indexOf(g.g0) != -1
#          payload.mg = "chaotic"
#        if ShadowcraftGear.LEGENDARY_META_GEM == g.g0
#          payload.mg = "capacitive"
    payload.g = gear_ids
    payload

  recomputeFailed: ->
    Shadowcraft.Console.remove(".error")
    Shadowcraft.Console.warn {}, "Error contacting backend engine", null, "error", "error"

  handleRecompute: (data) ->
    Shadowcraft.Console.remove(".error")
    if data.error
      Shadowcraft.Console.warn {}, data.error, null, "error", "error"
      return

    @app.lastCalculation = data
    #this.trigger("recompute2", data)
    this.trigger("recompute", data)

  recompute: (payload = null, forcePost = false) ->
    @cancelRecompute = false
    payload ||= this.buildPayload()
    return if @cancelRecompute or not payload?
    window._gaq.push ['_trackEvent', "Character", "Recompute"] if window._gaq

    #wait('Calculate...')
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
   if /msie/.test(navigator.userAgent.toLowerCase()) and window.XDomainRequest
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
      #stopWait()
      data = JSON.parse xdr.responseText
      app.handleRecompute(data)
    xdr.onerror = ->
      #stopWait()
      app.recomputeFailed()
      flash "Error contacting backend engine"
      false

  recompute_via_xhr: (payload) ->
    app = this
    $.ajax
      type: "POST"
      url: get_engine()
      data: { data: $.toJSON(payload) }
      dataType: 'json'
      success: (data) ->
        app.handleRecompute(data)
        #stopWait()
      error: (xhr, textStatus, error) ->
        app.recomputeFailed()

    #$.post(get_engine(), {
    #  data: $.toJSON(payload)
    #}, (data) ->
    #  app.handleRecompute(data)
    #  #stopWait()
    #, 'json')

loadingSnapshot = false
