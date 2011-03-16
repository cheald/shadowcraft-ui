class ShadowcraftHistory
  DATA_VERSION = 1
  constructor: (@app) ->
    @app.History = this
    Shadowcraft.Reset = @reset

  boot: ->
    app = this
    Shadowcraft.bind("update", -> app.save())
    $("#doImport").click ->
      json = $.parseJSON $("textarea#import").val()
      app.loadSnapshot json

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
    menu = $("#settingsDropdownMenu")
    menu.append("<li><a href='#' id='menuSaveSnapshot'>Save</li>")

    buttons =
      Ok: ->
        app.saveSnapshot($("#snapshotName").val())
        $(this).dialog "close"
      Cancel: ->
        $(this).dialog "close"

    $("#menuSaveSnapshot").click ->
      $("#saveSnapshot").dialog({
        modal: true,
        buttons: buttons,
        open: (event, ui) ->
          sn = $("#snapshotName")
          if Shadowcraft.Data.tree0 >= 31
            t = "Mutilate"
          else if Shadowcraft.Data.tree1 >= 31
            t = "Combat"
          else
            t = "Subtlety"
          d = new Date()
          t += " #{d.getFullYear()}-#{d.getMonth()}-#{d.getDate()}"
          sn.val(t)
      })

    $("#loadSnapshot").click $.delegate
      ".selectSnapshot": ->
        app.restoreSnapshot $(this).data("snapshot")
        $("#loadSnapshot").dialog("close")

      ".deleteSnapshot": ->
        app.deleteSnapshot $(this).data("snapshot")
        $("#loadSnapshot").dialog("close")
        $("#menuLoadSnapshot").click()

    menu.append("<li><a href='#' id='menuLoadSnapshot'>Load</li>")
    $("#menuLoadSnapshot").click ->
      app.selectSnapshot()
    this

  save: ->
    if @app.Data?
      data = compress(@app.Data)
      @persist(data)
      $.jStorage.set(@app.uuid, data)

  saveSnapshot: (name) ->
    key = @app.uuid + "snapshots"
    snapshots = $.jStorage.get(key, {})
    snapshots[name] = @takeSnapshot()
    $.jStorage.set(key, snapshots)
    flash "#{name} has been saved"

  selectSnapshot: ->
    key = @app.uuid + "snapshots"
    snapshots = $.jStorage.get(key, {})
    d = $("#loadSnapshot")
    d.get(0).innerHTML = Templates.loadSnapshots({snapshots: _.keys(snapshots) })
    d.dialog({
      modal: true,
      width: 500
    })

  restoreSnapshot: (name) ->
    key = @app.uuid + "snapshots"
    snapshots = $.jStorage.get(key, {})
    @loadSnapshot snapshots[name]

  deleteSnapshot: (name) ->
    if confirm "Delete this snapshot?"
      key = @app.uuid + "snapshots"
      snapshots = $.jStorage.get(key, {})
      delete snapshots[name]
      $.jStorage.set(key, snapshots)
      flash "#{name} has been deleted"

  load: (defaults) ->
    data = $.jStorage.get(@app.uuid, defaults)
    if data instanceof Array and data.length != 0
      data = decompress(data)
    else
      data = defaults
    return data

  loadFromFragment: ->
    hash = window.location.hash
    if hash and hash.match(/^#!/)
      frag = hash.substring(3)
      inflated = RawDeflate.inflate($.base64Decode(frag))
      snapshot = null
      try
        snapshot = $.parseJSON(inflated)
      catch TypeError
        snapshot = null
      if snapshot?
        @loadSnapshot snapshot
        return true
    return false

  persist: (data) ->
    @lookups ||= {}
    jd = json_encode(data)
    frag = $.base64Encode(RawDeflate.deflate( jd ) )
    window.history.replaceState("loadout", "Latest settings", window.location.pathname.replace(/\/+$/, "") + "/#!/" + frag)

  reset: ->
    if confirm("This will wipe out any changes you've made. Proceed?")
      $.jStorage.deleteKey(uuid)
      window.location.reload()

  takeSnapshot: ->
    return compress(deepCopy(@app.Data))

  loadSnapshot: (snapshot) ->
    @app.Data = decompress (snapshot)
    loadingSnapshot = true
    Shadowcraft.loadData()

  buildExport: ->
    data = json_encode compress(@app.Data)
    encoded_data = $.base64Encode(lzw_encode(data))
    $("#export").text data # encoded_data

  base10 = "0123456789"
  base77 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

  base36Encode = (a) ->
    r = []
    for v, i in a
      if v == undefined or v == null
        continue
      else if v == 0
        r.push ""
      else
        r.push convertBase(v.toString(), base10, base77)
    r.join(";")

  base36Decode = (s) ->
    r = []
    for v in s.split(";")
      if v == ""
        r.push 0
      else
        r.push parseInt(convertBase(v, base77, base10), 10)
    r

  compress = (data) ->
    compress_handlers[DATA_VERSION](data)

  decompress = (data) ->
    version = data[0].toString()
    unless decompress_handlers[version]?
      throw "Data version mismatch"

    decompress_handlers[version](data)

  professionMap = [ "enchanting", "engineering", "blacksmithing", "inscription", "jewelcrafting", "leatherworking", "tailoring" ]
  poisonMap = [ "ip", "dp", "wp" ]
  raceMap = ["Human", "Night Elf", "Worgen", "Dwarf", "Gnome", "Tauren", "Undead", "Orc", "Troll", "Blood Elf", "Goblin", "Draenei"]
  rotationOptionsMap = [
    "min_envenom_size_mutilate", "min_envenom_size_backstab", "prioritize_rupture_uptime_mutilate", "prioritize_rupture_uptime_backstab"
    "use_rupture", "ksp_immediately", "use_revealing_strike"
    "clip_recuperate"
  ]
  rotationValueMap = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, true, false, 'true', 'false', 'never', 'always', 'sometimes']

  map = (value, m) ->
    m.indexOf(value)

  unmap = (value, m) ->
    m[value]

  compress_handlers =
    "1": (data) ->
      ret = [DATA_VERSION]

      gearSet = []
      for slot in [0..17]
        gear = data.gear[slot] || {}
        gearSet.push gear.item_id || 0
        gearSet.push gear.enchant || 0
        gearSet.push gear.reforge || 0
        gearSet.push gear.g0 || 0
        gearSet.push gear.g1 || 0
        gearSet.push gear.g2 || 0
      ret.push base36Encode(gearSet)
      ret.push ShadowcraftTalents.encodeTalents(data.activeTalents)
      ret.push base36Encode(data.glyphs)

      # Options
      options = []
      professions = []
      for profession, val of data.options.professions
        professions.push map(profession, professionMap) if val
      options.push professions

      # General options
      general = [
        data.options.general.level
        map(data.options.general.race, raceMap)
        data.options.general.duration
        map(data.options.general.mh_poison, poisonMap)
        map(data.options.general.oh_poison, poisonMap)
        if data.options.general.potion_of_the_tolvir then 1 else 0
      ]
      options.push base36Encode(general)

      # Buff options
      buffs = []
      for buff, index in ShadowcraftOptions.buffMap
        v = data.options.buffs[buff]
        buffs.push if v then 1 else 0
      options.push buffs

      # Rotation options
      rotationOptions = []
      for k, v of data.options["rotation"]
        rotationOptions.push map(k, rotationOptionsMap)
        rotationOptions.push map(v, rotationValueMap)
      options.push base36Encode(rotationOptions)

      ret.push options
      return ret

  decompress_handlers =
    "1": (data) ->
      d =
        gear: {}
        activeTalents: ShadowcraftTalents.decodeTalents(data[2])
        glyphs: base36Decode(data[3])
        options: {}
        talents: []
        active: data[6]

      gear = base36Decode data[1]
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
      d.options.professions = {}
      for v, i in options[0]
        d.options.professions[unmap(v, professionMap)] = true

      general = base36Decode options[1]
      d.options.general =
        level:                general[0]
        race:                 unmap(general[1], raceMap)
        duration:             general[2]
        mh_poison:            unmap(general[3], poisonMap)
        oh_poison:            unmap(general[4], poisonMap)
        potion_of_the_volvir: general[5] == 1

      d.options.buffs = {}
      for v, i in options[2]
        d.options.buffs[ShadowcraftOptions.buffMap[i]] = v == 1

      rotation = base36Decode options[3]
      d.options.rotation = {}
      for v, i in rotation by 2
        d.options.rotation[unmap(v, rotationOptionsMap)] = unmap(rotation[i+1], rotationValueMap)

      return d