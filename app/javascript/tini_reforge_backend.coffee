class ShadowcraftTiniReforgeBackend
  REFORGABLE = ["spirit", "dodge_rating", "parry_rating", "hit_rating", "crit_rating", "haste_rating", "expertise_rating", "mastery_rating"]

  constructor: (@gear) ->

  request: (req) ->
    wait('Optimizing reforges...')
    Shadowcraft.Console.log "Starting reforge optimization...", "gold underline"
    $.ajax
      type: "POST"
      url: "http://shadowref.appspot.com/calc"
      data: json_encode(req)
      complete: ->
        $("#wait").hide()
        Shadowcraft.Console.log "Finished reforge optimization!", "gold underline"
      success: (data) ->
        Shadowcraft.Gear.setReforges(data)
      error: (xhr, textStatus, error) ->
        flash textStatus
      dataType: "json",
      contentType: "application/json"

  buildRequest: ->
    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP
    stats = @gear.sumStats(true)

    items = _.map(Shadowcraft.Data.gear, (e) ->
      r = { id: e.item_id }
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

    req =
      items: items
      ep: @gear.getWeights()
      cap: caps
      ratings: stats
    @request(req)