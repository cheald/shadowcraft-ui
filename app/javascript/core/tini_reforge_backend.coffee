class ShadowcraftTiniReforgeBackend
  # Rather than sending the client to shadowref directly, we'll proxy through nginx.
  # This lets us set up load balancing if needed and plays nicely with noscript.
  # We'll go directly if running on a custom port, though, since this likely means development mode
  # if window.location.host.match(/:/)
  #  ENGINE = "http://shadowref.appspot.com/calc"
  # else
  #  ENGINE = "http://#{window.location.hostname}/calc"
  ENGINES = ["http://shadowref2.appspot.com/calc", "http://shadowref.appspot.com/calc"]
  ENGINE = ENGINES[Math.floor(Math.random() * ENGINES.length)]
  REFORGABLE = ["spirit", "dodge_rating", "parry_rating", "hit_rating", "crit_rating", "haste_rating", "expertise_rating", "mastery_rating"]

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
        Shadowcraft.update()
        Shadowcraft.Gear.updateDisplay()
      success: (data) ->
        Shadowcraft.Gear.setReforges(data)
      error: (xhr, textStatus, error) ->
        flash textStatus
      dataType: "json",
      contentType: "application/json"

  buildRequest: (override = false) ->
    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP
    f = ShadowcraftGear.FACETS
    stats = @gear.sumStats(f.ITEM | f.GEMS | f.ENCHANT)

    items = _.map(Shadowcraft.Data.gear, (e, k) ->
      r = { id: e.item_id+"-"+k }
      if ItemLookup[e.item_id]
        for key, val of ItemLookup[e.item_id].stats
          if REFORGABLE.indexOf(key) != -1
            r[key] = val
      r
    )

    items = _.select items, (i) ->
      for k, v of i
        if REFORGABLE.indexOf(k) != -1
          return true
      return false

    caps = @gear.getCaps()
    for k, v of caps
      caps[k] = Math.ceil(v)
    
    ep = @gear.getWeights()
    if override
      ep.mh_expertise_rating = Shadowcraft.Data.options.advanced.mh_expertise_rating_override
      ep.oh_expertise_rating = Shadowcraft.Data.options.advanced.oh_expertise_rating_override
      ep.expertise_rating = ep.mh_expertise_rating + ep.oh_expertise_rating
    req =
      items: items
      ep: ep
      cap: caps
      ratings: stats
    @request(req).then ->
      stopWait()
      Shadowcraft.Console.log "Finished reforge optimization!", "gold underline"
