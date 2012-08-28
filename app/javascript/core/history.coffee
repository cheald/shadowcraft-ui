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

    menu = $("#settingsDropdownMenu")
    menu.append("<li><a href='#' id='menuSaveSnapshot'>Save snapshot</li>")

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
          t = ShadowcraftTalents.GetPrimaryTreeName()
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

    menu.append("<li><a href='#' id='menuLoadSnapshot'>Load snapshot</li>")
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
    if window.history.replaceState
      window.history.replaceState("loadout", "Latest settings", window.location.pathname.replace(/\/+$/, "") + "/#!/" + frag)
    else
      window.location.hash = "!/" + frag

  reset: ->
    if confirm("This will wipe out any changes you've made. Proceed?")
      $.jStorage.deleteKey(uuid)
      window.location.reload()

  takeSnapshot: ->
    return compress(deepCopy(@app.Data))

  loadSnapshot: (snapshot) ->
    @app.Data = decompress (snapshot)
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

  professionMap = [ "enchanting", "engineering", "blacksmithing", "inscription", "jewelcrafting", "leatherworking", "tailoring", "alchemy", "skinning", "herbalism", "mining" ]
  poisonMap = [ "dp", "wp" ]
  utilPoisonMap = [ "lp", "n" ]
  raceMap = ["Human", "Night Elf", "Worgen", "Dwarf", "Gnome", "Tauren", "Undead", "Orc", "Troll", "Blood Elf", "Goblin", "Draenei", "Pandaren"]
  rotationOptionsMap = [
    "min_envenom_size_mutilate", "min_envenom_size_backstab", "prioritize_rupture_uptime_mutilate", "prioritize_rupture_uptime_backstab", "opener_name", "opener_use"
    "use_rupture", "ksp_immediately", "use_revealing_strike"
    "clip_recuperate", "use_hemorrhage"
  ]
  rotationValueMap = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, true, false, 'true', 'false', 'never', 'always', 'sometimes', 'pool', 'garrote', 'ambush', 'mutilate']

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
        data.options.general.max_ilvl
        if data.options.general.tricks then 1 else 0
        if data.options.general.receive_tricks then 1 else 0
        if data.options.general.prepot then 1 else 0
        data.options.general.patch,
        data.options.general.min_ilvl,
        data.options.general.epic_gems
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
        lethal_poison:        unmap(general[3], poisonMap)
        utility_poison:       unmap(general[4], utilPoisonMap)
        virmens_bite:         general[5] != 0
        max_ilvl:             general[6] || 600
        tricks:               general[7] != 0
        receive_tricks:       general[8] != 0
        prepot:               general[9] != 0
        patch:                general[10] || 43
        min_ilvl:             general[11] || 333
        epic_gems:            general[12] || 0

      d.options.buffs = {}
      for v, i in options[2]
        d.options.buffs[ShadowcraftOptions.buffMap[i]] = v == 1

      rotation = base36Decode options[3]
      d.options.rotation = {}
      for v, i in rotation by 2
        d.options.rotation[unmap(v, rotationOptionsMap)] = unmap(rotation[i+1], rotationValueMap)

      return d