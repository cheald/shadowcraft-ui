class ShadowcraftOptions
  @buffMap = [
    'short_term_haste_buff',
    'stat_multiplier_buff',
    'crit_chance_buff',
    'haste_buff',
    'multistrike_buff',
    'attack_power_buff',
    'mastery_buff',
    'versatility_buff',
    'agi_flask_mop',
    'food_300_agi'
  ]

  cast = (val, dtype) ->
    switch dtype
      when "integer"
        val = parseInt(val, 10)
        val = 0 if isNaN(val)
      when "float"
        val = parseFloat(val, 10)
        val = 0 if isNaN(val)
      when "bool"
        val = val == true or val == "true" or val == 1
    val

  enforceBounds = (val, mn, mx) ->
    if typeof(val) == "number"
      if mn and val < mn
        val = mn
      else if mx and val > mx
        val = mx
    else
      return val
    val

  setup: (selector, namespace, checkData) ->
    data = Shadowcraft.Data
    s = $(selector);
    for key, opt of checkData
      ns = data.options[namespace]
      val = null
      if !ns
        data.options[namespace] = {}
        ns = data.options[namespace]
      if data.options[namespace][key]?
        val = data.options[namespace][key]
      if val == null and opt.default?
        val = opt.default

      val = cast(val, opt.datatype)
      val = enforceBounds(val, opt.min, opt.max)
      data.options[namespace][key] = val

      exist = s.find("#opt-" + namespace + "-" + key)

      inputType = "check"
      if typeof(opt) == "object" and opt.type?
        inputType = opt.type

      if exist.length == 0
        switch inputType
          when "check"
            template = Templates.checkbox
            options =
              label: if typeof(opt) == "string" then opt else opt.name
          when "select"
            template = Templates.select
            templateOptions = []
            if opt.options instanceof Array
              for _v in opt.options
                templateOptions.push {name: _v+"", value: _v}
            else
              for _k, _v of opt.options
                templateOptions.push {name: _v+"", value: _k}
            options =
              options: templateOptions
          when "input"
            template = Templates.input
            options = {}
        if template
          s.append template($.extend({
            key: key
            label: opt.name
            namespace: namespace
            desc: opt.desc
          }, options))

        exist = s.find("#opt-" + namespace + "-" + key)
        e0 = exist.get(0)
        $.data(e0, "datatype", opt.datatype)
        $.data(e0, "min", opt.min)
        $.data(e0, "max", opt.max)
      
      switch inputType
        when "check"
          exist.attr("checked", val)
          exist.val(val)
        when "select", "input"
          exist.val(val)

    null

  initOptions: ->
    data = Shadowcraft.Data

    @setup("#settings #general", "general", {
      patch: {type: "select", name: "Patch/Engine", 'default': 60, datatype: 'integer', options: {60: '6.0 (Level 90)', 54: '5.4'}},
      level: {type: "input", name: "Level", 'default': 90, datatype: 'integer', min: 90, max: 100},
      race: {type: "select", options: ["Human", "Dwarf", "Orc", "Blood Elf", "Gnome", "Worgen", "Troll", "Night Elf", "Undead", "Goblin", "Pandaren"], name: "Race", 'default': "Human"}
      duration: {type: "input", name: "Fight Duration", 'default': 360, datatype: 'integer', min: 15, max: 1200}
      response_time: {type: "input", name: "Response Time", 'default': 0.5, datatype: 'float', min: 0.1, max: 5}
      time_in_execute_range: {type: "input", name: "Time in Execute Range", desc: "Only used in Assassination Spec", 'default': 0.35, datatype: 'float', min: 0, max: 1}
      lethal_poison: {name: "Lethal Poison", type: 'select', options: {'dp': 'Deadly Poison', 'wp': 'Wound Poison'}, 'default': 'dp'}
      utility_poison: {name: "Utility Poison", type: 'select', options: {'lp': 'Leeching Poison', 'n': 'Other/None'}, 'default': 'lp'}
      num_boss_adds: {name: "Number of Boss Adds", desc: "Used for Blade Flurry / Trinket Sigil of Rampage / Legendary Cloak", datatype: 'float', type: 'input', min: 0, max: 5, 'default': 0}
    })

    @setup("#settings #generalFilter", "general", {
      max_ilvl: {name: "Max ILevel", type: "input", desc: "Don't show items over this ilevel in gear lists", 'default': 700, datatype: 'integer', min: 430, max: 700}
      min_ilvl: {name: "Min ILevel", type: "input", desc: "Don't show items under this ilevel in gear lists", 'default': 430, datatype: 'integer', min: 430, max: 700},
      show_random_items: {name: "Min ILvL (Random Items)", desc: "Don't show random items under this ilevel in gear lists", datatype: 'integer', type: 'input', min: 430, max: 700, 'default': 502}
      show_upgrades: {name: "Show Upgrades", desc: "Show all upgraded items in gear lists", datatype: 'integer', type: 'select', options: {1: 'Yes', 0: 'No'}, 'default': 0}
      epic_gems: {name: "Recommend Epic Gems", datatype: 'integer', type: 'select', options: {1: 'Yes', 0: 'No'}}
    })

    @setup("#settings #professions", "professions", {
      alchemy:        {'default': false, datatype: 'bool', name: "Alchemy"}
      blacksmithing:  {'default': false, datatype: 'bool', name: "Blacksmithing"}
      enchanting:     {'default': false, datatype: 'bool', name: "Enchanting"}
      engineering:    {'default': false, datatype: 'bool', name: "Engineering"}
      herbalism:      {'default': false, datatype: 'bool', name: "Herbalism"}
      inscription:    {'default': false, datatype: 'bool', name: "Inscription"}
      jewelcrafting:  {'default': false, datatype: 'bool', name: "Jewelcrafting"}
      leatherworking: {'default': false, datatype: 'bool', name: "Leatherworking"}
      mining:         {'default': false, datatype: 'bool', name: "Mining"}
      skinning:       {'default': false, datatype: 'bool', name: "Skinning"}
      tailoring:      {'default': false, datatype: 'bool', name: "Tailoring"}
    })
    
    @setup("#settings #playerBuffs", "buffs", {
      food_300_agi: {name: "Food Buff", desc: "300 Agi Food", 'default': true, datatype: 'bool'},
      agi_flask_mop: {name: "Agility Flask", desc: "Mists Flask", 'default': true, datatype: 'bool'},
      short_term_haste_buff: {name: "+30% Haste/40 sec", desc: "Heroism/Bloodlust/Time Warp", 'default': true, datatype: 'bool'},
      stat_multiplier_buff: {name: "5% All Stats", desc: "Blessing of Kings/Mark of the Wild/Legacy of the Emperor", 'default': true, datatype: 'bool'},
      crit_chance_buff: {name: "5% Crit", desc: "Leader of the Pack/Arcane Brilliance/Legacy of the White Tiger", 'default': true, datatype: 'bool'},
      haste_buff: {name: "5% Haste", desc: "Unleashed Rage/Unholy Aura/Swiftblade's Cunning", 'default': true, datatype: 'bool'},
      multistrike_buff: {name: "5% Multistrike", desc: "Swiftblade's Cunning", 'default': true, datatype: 'bool'},
      attack_power_buff: {name: "10% Attack Power", desc: "Horn of Winter/Trueshot Aura/Battle Shout", 'default': true, datatype: 'bool'},
      mastery_buff: {name: "Mastery", desc: "Blessing of Might/Grace of Air", 'default': true, datatype: 'bool'},
      versatility_buff: {name: "3% Versatility", desc: "PH", 'default': true, datatype: 'bool'},
    })

    @setup("#settings #raidOther", "general", {
      prepot: {type: "check", name: "Pre-pot (Virmen's Bite)", 'default': false, datatype: 'bool'},
      virmens_bite: {type: "check", name: "Combat potion (Virmen's Bite)", 'default': true, datatype: 'bool'},
    })

    @setup("#settings #pvp", "general", {
      pvp: {type: "check", name: "PvP Mode", desc: "Activate the PvP Mode", 'default': false, datatype: 'bool'},
      #pvp_target_armor: {type: "input", name: "bla", desc: "blllaaa", 'default': 10000, datatype: 'integer', min: 3000, max: 99000},
    })

    @setup("#settings section.mutilate .settings", "rotation", {
      min_envenom_size_non_execute: {type: "select", name: "Min CP/Envenom > 35%", options: [5,4,3,2,1], 'default': 4, desc: "CP for Envenom when using Mutilate, no effect with Anticipation", datatype: 'integer', min: 1, max: 5}
      min_envenom_size_execute: {type: "select", name: "Min CP/Envenom < 35%", options: [5,4,3,2,1], 'default': 5, desc: "CP for Envenom when using Dispatch, no effect with Anticipation", datatype: 'integer', min: 1, max: 5}
      prioritize_rupture_uptime_non_execute: {type: "check", name: "Prioritize Rupture (>35%)", desc: "Prioritize Rupture over Envenom when your CP builder is Mutilate", default: true, datatype: 'bool'}
      prioritize_rupture_uptime_execute: {type: "check", name: "Prioritize Rupture (<35%)", desc: "Prioritize Rupture over Envenom when your CP builder is Dispatch", default: true, datatype: 'bool'}
      opener_name_assassination: {type: "select", name: "Opener Name", options: {'mutilate': "Mutilate", 'ambush': "Ambush", 'garrote': "Garrote"}, 'default': 'ambush', datatype: 'string'}
      opener_use_assassination: {type: "select", name: "Opener Usage", options: {'always': "Always", 'opener': "Start of the Fight", 'never': "Never"}, 'default': 'always', datatype: 'string'}
    })

    @setup("#settings section.combat .settings", "rotation", {
      ksp_immediately: {type: "select", name: "Killing Spree", options: {'true': "Killing Spree on cooldown", 'false': "Wait for Bandit's Guile before using Killing Spree"}, 'default': 'true', datatype: 'string'}
      revealing_strike_pooling: {type: "check", name: "Pool for Revealing Strike",  default: true, datatype: 'bool'}
      blade_flurry: {type: "check", name: "Blade Flurry", desc: "Use Blade Flurry", default: false, datatype: 'bool'}
      bf_targets: {type: "select", name: "Blade Flurry Targets", options: [0,1,2,3,4,5,6,7,8,9], desc: "With 5.4 you need to use the Option 'Number of Boss Adds' under General Settings", 'default': 1, datatype: 'integer', min: 0, max: 9}
      opener_name_combat: {type: "select", name: "Opener Name", options: {'sinister_strike': "Sinister Strike", 'revealing_strike': "Revealing Strike", 'ambush': "Ambush", 'garrote': "Garrote"}, 'default': 'ambush', datatype: 'string'}
      opener_use_combat: {type: "select", name: "Opener Usage", options: {'always': "Always", 'opener': "Start of the Fight", 'never': "Never"}, 'default': 'always', datatype: 'string'}
    })

    @setup("#settings section.subtlety .settings", "rotation", {
      use_hemorrhage: {type: "select", name: "CP Builder", options: {'never': "Backstab", 'always': "Hemorrhage", '24': "Use Backstab and apply Hemorrhage every 24sec"}, default: '24', datatype: 'string'}
      opener_name_subtlety: {type: "select", name: "Opener Name", options: {'ambush': "Ambush", 'garrote': "Garrote"}, 'default': 'ambush', datatype: 'string'}
      opener_use_subtlety: {type: "select", name: "Opener Usage", options: {'always': "Always", 'opener': "Start of the Fight", 'never': "Never"}, 'default': 'always', datatype: 'string'}
    })

    @setup("#settings #advancedSettings", "advanced", {
      latency: {type: "input", name: "Latency", 'default': 0.03, datatype: 'float', min: 0.0, max: 5}
      adv_params: {type: "input", name: "Advanced Parameters", default: "", datatype: 'string'}
    })


  changeOption = (elem, inputType, val) ->
    $this = $(elem)
    data = Shadowcraft.Data
    ns = elem.attr("data-ns") || "root"
    data.options[ns] ||= {}
    name = $this.attr("name")
    if val == undefined
      val = $this.val()
    t0 = $this.get(0)
    dtype = $.data(t0, "datatype")
    min = $.data(t0, "min")
    max = $.data(t0, "max")
    val = enforceBounds(cast(val, dtype), min, max)
    if $this.val() != val
      $this.val(val)
    if inputType == "check"
      $this.attr("checked", val)

    data.options[ns][name] = val
    Shadowcraft.Options.trigger("update", ns + "." + name, val)
    if ns not in ['advanced'] or name in ['latency','adv_params']
      Shadowcraft.update()
    
  changeCheck = ->
    $this = $(this)
    changeOption($this, "check", not $this.attr("checked")?)
    Shadowcraft.setupLabels("#settings,#advanced")

  changeSelect = ->
    changeOption(this, "select")

  changeInput = ->
    changeOption(this, "input")

  boot: ->
    app = this
    @initOptions()

    Shadowcraft.bind "loadData", ->
      app.initOptions()
      Shadowcraft.setupLabels("#settings,#advanced")
      $("#settings,#advanced select").change()

    Shadowcraft.Talents.bind "changed", ->
      $("#settings section.mutilate, #settings section.combat, #settings section.subtlety").hide()
      if Shadowcraft.Data.activeSpec == "a"
        $("#settings section.mutilate").show()
      else if Shadowcraft.Data.activeSpec == "Z"
        $("#settings section.combat").show()
      else
        $("#settings section.subtlety").show()

    this

  constructor: ->
    $("#settings,#advanced").bind "change", $.delegate({ ".optionCheck": changeCheck })
    $("#settings,#advanced").bind "change", $.delegate({ ".optionSelect": changeSelect })
    $("#settings,#advanced").bind "change", $.delegate({ ".optionInput": changeInput })
    _.extend(this, Backbone.Events)
