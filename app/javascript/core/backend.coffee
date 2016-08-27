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
        return "http://#{window.location.hostname}:#{port}/#{endpoint}"

  constructor: (@app) ->
    @app.Backend = this
    _.extend(this, Backbone.Events)

  boot: ->
    self = this
    Shadowcraft.bind("update", -> self.recompute())
    this

  buildPayload: ->
    data = Shadowcraft.Data
    statSummary = Shadowcraft.Gear.sumStats()

    mh = Shadowcraft.Gear.getItem(data.gear[15].id, data.gear[15].context, data.gear[15].item_level) if data.gear[15]
    oh = Shadowcraft.Gear.getItem(data.gear[16].id, data.gear[16].context, data.gear[16].item_level) if data.gear[16]

    buffList = []
    for key, val of data.options.buffs
      if val
        buffList.push ShadowcraftOptions.buffMap.indexOf(key)

    talentArray = data.activeTalents.split ""
    for val, key in talentArray
      talentArray[key] = switch val
        when "." then "0"
        when "0", "1", "2" then parseInt(val,10)+1

    payload =
      r: data.options.general.race
      l: data.options.general.level
      pot: ShadowcraftOptions.buffPotions.indexOf(data.options.general.potion)
      prepot: ShadowcraftOptions.buffPotions.indexOf(data.options.general.prepot)
      b: buffList
      bf: ShadowcraftOptions.buffFoodMap.indexOf(data.options.buffs.food_buff)
      ro: data.options.rotation
      settings: {
        duration: data.options.general.duration
        response_time: data.options.general.response_time
        num_boss_adds: data.options.general.num_boss_adds
        latency: data.options.advanced.latency
        adv_params: data.options.advanced.adv_params
        night_elf_racial: data.options.general.night_elf_racial
        demon_enemy: data.options.general.demon_enemy
        mfd_resets: data.options.general.mfd_resets
        finisher_threshold: data.options.general.finisher_threshold
      }
      spec: data.activeSpec,
      t: talentArray.join(''),
      sta: [
        statSummary.strength || 0,
        statSummary.agility || 0,
        statSummary.attack_power || 0,
        statSummary.crit || 0,
        statSummary.haste || 0,
        statSummary.mastery || 0,
        statSummary.versatility || 0
      ],

    # Don't send artifact information if the character isn't holding two the artifact weapons
    # for their current spec.
    payload.art = {}
    if (mh and oh and mh.id == ShadowcraftGear.ARTIFACT_SETS[data.activeSpec].mh and oh.id == ShadowcraftGear.ARTIFACT_SETS[data.activeSpec].oh)
      payload.art = Shadowcraft.Artifact.getPayload()

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
      if g.id
        item = [
          g.id,
          g.item_level,
          g.enchant
        ]
        gear_ids.push(item)
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
      data = JSON.parse xdr.responseText
      app.handleRecompute(data)
    xdr.onerror = ->
      app.recomputeFailed()
      flash "Error contacting backend engine"
      false

  recompute_via_xhr: (payload) ->
    app = this
    $.ajax
      type: "POST"
      url: get_engine()
      contentType: 'application/json'
      data: $.toJSON(payload)
      dataType: 'json'
      success: (data) ->
        app.handleRecompute(data)
      error: (xhr, textStatus, error) ->
        app.recomputeFailed()
