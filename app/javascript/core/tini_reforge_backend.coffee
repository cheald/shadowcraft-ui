class ShadowcraftTiniReforgeBackend
  # Rather than sending the client to shadowref directly, we'll proxy through nginx.
  # This lets us set up load balancing if needed and plays nicely with noscript.
  # We'll go directly if running on a custom port, though, since this likely means development mode
  # if window.location.host.match(/:/)
  #  ENGINE = "http://shadowref.appspot.com/calc"
  # else
  #  ENGINE = "http://#{window.location.hostname}/calc"
  #ENGINES = ["http://shadowref2.appspot.com/calc", "http://shadowref.appspot.com/calc"]
  ENGINES = ["http://shadowref4.appspot.com/calc", "http://shadowref3.appspot.com/calc"]
  ENGINE = ENGINES[Math.floor(Math.random() * ENGINES.length)]
  REFORGABLE = ["spirit", "dodge", "parry", "hit", "crit", "haste", "expertise", "mastery"]
  REFORGER_MAP =
    "spirit": "spirit"
    "dodge": "dodge_rating"
    "parry": "parry_rating"
    "hit": "hit_rating"
    "crit": "crit_rating"
    "haste": "haste_rating"
    "expertise": "expertise_rating"
    "mastery": "mastery_rating"
    "mh_expertise": "mh_expertise_rating"
    "oh_expertise": "oh_expertise_rating"

  deferred = null
  constructor: (@gear) ->

  request: (req) ->
    deferred = $.Deferred()
    wait('Optimizing reforges...')
    Shadowcraft.Console.log "Starting reforge optimization...", "gold underline"
    if $.browser.msie and window.XDomainRequest
      @request_via_xdr req
    else
      @request_via_ajax req
    deferred.promise()

  request_via_xdr: (req) ->
    xdr = new XDomainRequest()
    # We have to use GET because Twisted expects a proper form header for POST data, which XDR can't send. Yay IE.

    xdr.open "post", ENGINE
    xdr.send JSON.stringify(req)
    xdr.onload = ->
      data = JSON.parse xdr.responseText
      Shadowcraft.Gear.setReforges(data)
      deferred.resolve()
    xdr.onerror = ->
      flash "Error contacting reforging service"
      false
    xdr.ontimeout = ->
      flash "Timed out talking to reforging service"
      false

  request_via_ajax: (req) ->
    $.ajax
      type: "POST"
      url: ENGINE
      data: json_encode(req)
      complete: ->
        deferred.resolve()
      success: (data) ->
        Shadowcraft.Gear.setReforges(data)
        Shadowcraft.update()
        Shadowcraft.Gear.updateDisplay()
      error: (xhr, textStatus, error) ->
        Shadowcraft.Console.remove(".error")
        Shadowcraft.Console.warn {}, "Timed out talking to reforging service", null, "error", "error"
      dataType: "json",
      contentType: "application/json"

  buildRequest: (override = false) ->
    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP
    f = ShadowcraftGear.FACETS
    _stats = @gear.sumStats(f.ITEM | f.GEMS | f.ENCHANT)
    stats = {}
    for k, v of _stats
       continue unless k in REFORGABLE
       stats[REFORGER_MAP[k]] = v

    items = _.map(Shadowcraft.Data.gear, (e, k) ->
      r = { id: e.item_id+"-"+k }
      if e.locked # return empty item but add reforge item stats to stats
        _temp = {}
        Shadowcraft.Gear.sumSlot(e, _temp, f.REFORGE)
        for k, v of _temp
          continue unless k in REFORGABLE
          stats[REFORGER_MAP[k]] ||= 0
          stats[REFORGER_MAP[k]] += v
        return r
      if ItemLookup[e.item_id]
        for key, val of ItemLookup[e.item_id].stats
          if REFORGABLE.indexOf(key) != -1
            r[REFORGER_MAP[key]] = val
      r
    )
    revert = {}
    for k,v of REFORGER_MAP
      revert[v] = k
    items = _.select items, (i) ->
      for k, v of i
        if REFORGABLE.indexOf(revert[k]) != -1
          return true
      return false

    if items.length < 2
      Shadowcraft.Console.remove(".error")
      Shadowcraft.Console.warn {}, "You must have at least two reforgable items to use the reforger", null, "error", "error"
      return

    caps = @gear.getCaps()
    for k, v of caps
      caps[k] = Math.ceil(v)
    
    _ep = @gear.getWeights()
    ep = {}
    for k, v of _ep
      if k in _.keys(REFORGER_MAP)
        ep[REFORGER_MAP[k]] = v
      else
        ep[k] = v

    # Temporary? fix for long computation time until the reforging service covers the
    # cases where exp/yellowhit EP and the secondary stats having big gapes
    # with reducing those big gaps the computation time drops significantly
    #if not newmethod
    #  max = Math.max ep.haste_rating,ep.mastery_rating,ep.crit_rating
    #  if max < ep.expertise_rating and 2.5 < ep.expertise_rating
    #    diff = ep.expertise_rating - max
    #    ep.expertise_rating = max + diff / 3
    #    ep.mh_expertise_rating = ep.expertise_rating - ep.oh_expertise_rating
    #  if max < ep.yellow_hit and 2.5 < ep.yellow_hit
    #    diff = ep.yellow_hit - max
    #    ep.yellow_hit = max + diff / 3
    #  if ep.yellow_hit < ep.expertise_rating
    #    ep.yellow_hit = ep.expertise_rating * 1.1

    if override and override == "weights"
      ep.mh_expertise_rating = Shadowcraft.Data.options.advanced.mh_expertise_rating_override
      ep.oh_expertise_rating = Shadowcraft.Data.options.advanced.oh_expertise_rating_override
      ep.expertise_rating = ep.mh_expertise_rating + ep.oh_expertise_rating
      ep.haste_rating = Shadowcraft.Data.options.advanced.haste_override
      ep.mastery_rating = Shadowcraft.Data.options.advanced.mastery_override
      ep.crit_rating = Shadowcraft.Data.options.advanced.crit_override
    else if override and override == "priority"
      prio = Shadowcraft.Data.options.advanced.force_priority
      if prio and prio != 'nochange'
        ep_ranking = _.sortBy ["crit", "haste", "mastery"], (k) -> 
          return ep[REFORGER_MAP[k]]
        ep_num_ranking = [ep[REFORGER_MAP[ep_ranking[0]]],ep[REFORGER_MAP[ep_ranking[1]]],ep[REFORGER_MAP[ep_ranking[2]]]]
        decoder = {'h': "haste", 'm': "mastery", "c": "crit" }
        rank = []
        for char in prio.split('').reverse()
          rank.push(decoder[char])
        for stat,index in rank # bad -> good
          ep[REFORGER_MAP[stat]] = ep_num_ranking[index]

    req =
      items: items
      ep: ep
      cap: caps
      ratings: stats
    @request(req).then ->
      stopWait()
      Shadowcraft.Console.log "Finished reforge optimization!", "gold underline"
