class ShadowcraftHistory
  DATA_VERSION = 2
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
          t = ShadowcraftTalents.GetActiveSpecName()
          d = new Date()
          t += " #{d.getFullYear()}-#{d.getMonth()+1}-#{d.getDate()}"
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
    flash "#{name} has been loaded"

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
    return compress(@app.Data)

  loadSnapshot: (snapshot) ->
    @app.Data = decompress (snapshot)
    Shadowcraft.loadData()

  buildExport: ->
    data = json_encode compress(@app.Data)
    shavalue = sha1(data)
    console.log(shavalue)
    $("#export").text data

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
      throw new Error("Data version mismatch")

    decompress_handlers[version](data)

  poisonMap = [ "dp", "wp" ]
  utilPoisonMap = [ "lp", "n" ]
  raceMap = ["Human", "Night Elf", "Worgen", "Dwarf", "Gnome", "Tauren", "Undead", "Orc", "Troll", "Blood Elf", "Goblin", "Draenei", "Pandaren"]
  rotationOptionsMap = [
    "min_envenom_size_non_execute", "min_envenom_size_execute",
    "ksp_immediately", "revealing_strike_pooling", "blade_flurry",
    "use_hemorrhage",
    "opener_name_assassination", "opener_use_assassination", "opener_name_combat", "opener_use_combat", "opener_name_subtlety", "opener_use_subtlety", "opener_name", "opener_use",
  ]
  rotationValueMap = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, "24", true, false, 'true', 'false', 'never', 'always', 'garrote', 'ambush', 'mutilate', 'sinister_strike', 'revealing_strike', 'opener', 'uptime']

  map = (value, m) ->
    m.indexOf(value)

  unmap = (value, m) ->
    m[value]

  compress_handlers =
    "2": (data) ->
      ret = [DATA_VERSION]

      gearSet = []
      for slot in [0..17]
        gear = data.gear[slot] || {}
        gearSet.push gear.item_id || 0
        gearSet.push gear.enchant || 0
        gearSet.push gear.upgrade_level || 0
        gearSet.push gear.original_id || 0
        gearSet.push gear.item_level || 0
        gearSet.push Math.abs(gear.suffix) || 0
        if (gear.gems)
          gearSet.push gear.gems[0] || 0
          gearSet.push gear.gems[1] || 0
          gearSet.push gear.gems[2] || 0
        else
          gearSet.push 0
          gearSet.push 0
          gearSet.push 0
        if (gear.bonuses)
          gearSet.push Math.abs(gear.bonuses.length) || 0
          for bonus in gear.bonuses
            gearSet.push bonus
        else
          gearSet.push 0
      ret.push base36Encode(gearSet)
      ret.push data.active
      ret.push data.activeSpec
      ret.push data.activeTalents
      talentSet = []
      for set in [0,1]
        talent = data.talents[set]
        talentSet.push talent.spec
        talentSet.push talent.talents
      ret.push talentSet

      # Options
      options = []

      # General options
      general = [
        data.options.general.level
        map(data.options.general.race, raceMap)
        data.options.general.duration
        map(data.options.general.lethal_poison, poisonMap)
        map(data.options.general.utility_poison, utilPoisonMap)
        if data.options.general.potion then 1 else 0
        data.options.general.max_ilvl
        if data.options.general.prepot then 1 else 0
        data.options.general.patch,
        data.options.general.min_ilvl
        if data.options.general.epic_gems then 1 else 0
        if data.options.general.pvp then 1 else 0
        if data.options.general.show_upgrades then 1 else 0
        data.options.general.show_random_items || 600
        data.options.general.num_boss_adds * 100 || 0
        data.options.general.response_time * 100 || 50
        data.options.general.time_in_execute_range * 100 || 35
        data.options.general.night_elf_racial || 0
        data.options.general.demon_enemy || 0
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

      # advanced options
      advancedOptions = []
      for k, v of data.options["advanced"]
        advancedOptions.push k
        advancedOptions.push v
      options.push advancedOptions

      # Food Buff options
      buffFood = data.options.buffs.food_buff || 0
      options.push ShadowcraftOptions.buffFoodMap.indexOf(buffFood)

      ret.push options

      artifactSet = []
      for spec,artifact of data.artifact
        artifactSet.push spec
        artifactSet.push artifact.relics
        artifactSet.push artifact.traits
      ret.push artifactSet

      return ret

  decompress_handlers =
    "2": (data) ->
      d =
        gear: {}
        active: data[2]
        activeSpec: data[3]
        activeTalents: data[4]
        options: {}
        talents: []
        artifact: {}

      talentSets = data[5]
      for id, index in talentSets by 3
        set = (index / 3).toString()
        d.talents[set] =
          spec: talentSets[index]
          talents: talentSets[index + 1]

      gear = base36Decode data[1]
      index = 0
      for slot in [0..17]
        d.gear[slot] =
          item_id: gear[index++]
          enchant: gear[index++]
          upgrade_level: gear[index++]
          original_id: gear[index++]
          item_level: gear[index++]
          suffix: gear[index++] * -1
        d.gear[slot].gems = []
        d.gear[slot].gems.push gear[index++]
        d.gear[slot].gems.push gear[index++]
        d.gear[slot].gems.push gear[index++]
        numbonuses = gear[index++]
        if numbonuses != 0
          d.gear[slot].bonuses = []
        for [0...numbonuses]
          d.gear[slot].bonuses.push gear[index++]

        # Remove all of the gem entries if there aren't any
        if (d.gear[slot].gems[0] == 0 && d.gear[slot].gems[1] == 0 && d.gear[slot].gems[2] == 0)
          delete d.gear[slot].gems

        for k, v of d.gear[slot]
          delete d.gear[slot][k] if v == 0

      options = data[6]
      general = base36Decode options[0]
      d.options.general =
        level:                  general[0]
        race:                   unmap(general[1], raceMap)
        duration:               general[2]
        lethal_poison:          unmap(general[3], poisonMap)
        utility_poison:         unmap(general[4], utilPoisonMap)
        potion:                 general[5] != 0
        max_ilvl:               general[6] || 1000
        prepot:                 general[7] != 0
        patch:                  general[8] || 60
        min_ilvl:               general[9] || 540
        epic_gems:              general[10] || 0
        pvp:                    general[11] || 0
        show_upgrades:          general[12] || 0
        show_random_items:      general[13] || 0
        num_boss_adds:          general[14] / 100 || 0
        response_time:          general[15] / 100 || 0.5
        time_in_execute_range:  general[16] / 100 || 0.35
        night_elf_racial:       general[17] || 0
        demon_enemy:            general[18] || 0

      d.options.buffs = {}
      for v, i in options[1]
        d.options.buffs[ShadowcraftOptions.buffMap[i]] = v == 1

      rotation = base36Decode options[2]
      d.options.rotation = {}
      for v, i in rotation by 2
        d.options.rotation[unmap(v, rotationOptionsMap)] = unmap(rotation[i+1], rotationValueMap)
      if options[3]
        advanced = options[3]
        d.options.advanced = {}
        for v, i in advanced by 2
          d.options.advanced[v] = advanced[i+1]

      buffFood = options[4]
      d.options.buffs.food_buff = ShadowcraftOptions.buffFoodMap[buffFood]

      artifactSet = data[7]
      for i in [0,3,6]
        spec = "#{artifactSet[i]}"
        d.artifact[spec] = {}
        d.artifact[spec].relics = artifactSet[i+1]
        d.artifact[spec].traits = artifactSet[i+2]
      return d
