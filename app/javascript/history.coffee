class ShadowcraftHistory
  DATA_VERSION = 1
  constructor: (@app) ->
    @app.History = this
    Shadowcraft.Reset = @reset

    $("#dpsgraph").bind("plotclick", (event, pos, item) ->
      if item
        dpsPlot.unhighlight()
        dpsPlot.highlight(item.series, item.datapoint)
        loadSnapshot(snapshotHistory[item.dataIndex])
    ).mousedown((e) ->
      switch e.button
        when 2
          return false
    )

  boot: ->
    app = this
    $("#tabs").tabs({
      show: (event, ui) ->
        if ui.tab.hash == "#impex"
          app.buildExport()
    })
    this

  recompute = ->
    Shadowcraft.Backend.recompute()

  saveData: ->
    $.jStorage.set(@app.uuid, @app.Data) if @app.Data?
    if @recomputeTimeout
      @recomputeTimeout = clearTimeout(@recomputeTimeout)

    cancelRecompute = true
    @recomputeTimeout = setTimeout(recompute, 50)

  reset: ->
    if confirm("This will wipe out any changes you've made. Proceed?")
      $.jStorage.deleteKey(uuid)
      window.location.reload()

  takeSnapshot: ->
    return deepCopy(@app.Data)

  loadSnapshot: (snapshot) ->
    @app.Data = deepCopy(snapshot)
    loadingSnapshot = true
    Shadowcraft.updateView()

  buildExport: ->
    $("#export").text json_encode(compress(Shadowcraft.Data))

  base36Encode = (r) ->
    for v, i in r
      if v == 0
        r[i] = ""
      else
        r[i] = v.toString(36)
    r.join(":")

  base36Decode = (s) ->
    r = []
    for v in s.split(":")
      if v == ""
        r.push 0
      else
        r.push parseInt(v, 36)
    r

  compress = (data) ->
    compress_handlers[DATA_VERSION](data)

  decompress = (data) ->
    version = data[0].toString()
    unless decompress_handlers[version]?
      throw "Data version mismatch"

    decompress_handlers[version](data)

  compress_handlers =
    "1": (data) ->
      ret = [DATA_VERSION]

      gearSet = []
      for slot in [0..17]
        gear = data.gear[slot]
        gearSet.push gear.item_id
        gearSet.push gear.enchant || 0
        gearSet.push gear.reforge || 0
        gearSet.push gear.g0 || 0
        gearSet.push gear.g1 || 0
        gearSet.push gear.g2 || 0
      ret.push base36Encode(gearSet)
      ret.push ShadowcraftTalents.encodeTalents(data.activeTalents)
      ret.push data.glyphs

      # Options
      options = []
      options.push data.options.professions

      # General options
      general = [
        data.options.general.level
        data.options.general.race
        data.options.general.duration
        data.options.general.mh_poison
        data.options.general.oh_poison
        data.options.general.potion_of_the_tolvir
      ]
      options.push general

      # Buff options
      buffs = []
      for buff, index in ShadowcraftOptions.buffMap
        v = data.options.buffs[buff]
        buffs.push if v then 1 else 0
      options.push buffs

      # Rotation options
      if data.tree0 >= 31
        options.push data.options["rotation-mutilate"]
      else if data.tree1 >= 31
        options.push data.options["rotation-combat"]
      else if data.tree2 >= 31
        options.push data.options["rotation-subtlety"]

      ret.push options

      # Talents
      talents = []
      for set in data.talents
        talentSet = base36Encode _.clone(set.glyphs || [])
        talents.push talentSet
        talents.push ShadowcraftTalents.encodeTalents(set.talents)
      ret.push talents

      ret.push data.active
      console.log(ret)
      console.log decompress(ret)
      return ret

  decompress_handlers =
    "1": (data) ->
      d =
        gear: {}
        activeTalents: ShadowcraftTalents.decodeTalents(data[2])
        glyphs: data[3]
        options: {}
        talents: []
        active: data[6]

      gear = base36Decode data[1]
      console.log(gear)
      for id, index in gear by 6
        slot = (index / 6).toString()
        d.gear[slot] =
          item_id: gear[index]
          enchant: gear[index + 1]
          reforge: gear[index + 2]
          g0: gear[index + 3]
          g1: gear[index + 4]
          g2: gear[index + 5]
        for k, v of d.gear[slot]
          delete d.gear[slot][k] if v == 0

      options = data[4]
      d.options.professions = options[0]
      general = options[1]
      d.options.general =
        level:                general[0]
        race:                 general[1]
        duration:             general[2]
        mh_poison:            general[3]
        oh_poison:            general[4]
        potion_of_the_volvir: general[5]

      d.options.buffs = {}
      for v, i in options[2]
        d.options.buffs[ShadowcraftOptions.buffMap[i]] = v == 1

      talents = data[5]
      for set, index in talents by 2
        d.talents.push
          glyphs: base36Decode(set)
          talents: ShadowcraftTalents.decodeTalents(talents[index+1])

      return d