class ShadowcraftOptions
  @buffMap = [
    'short_term_haste_buff',
    'flask_legion_agi'
  ]

  @buffFoodMap = [
    'food_legion_375_crit',
    'food_legion_375_haste',
    'food_legion_375_mastery',
    'food_legion_375_versatility',
    'food_legion_feast_200',
    'food_legion_damage_3'
  ]

  @buffPotions = [
    'potion_old_war',
    'potion_deadly_grace',
    'potion_none'
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
    s = $(selector)
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
          when "subheader"
            template = Templates.subheader
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

    @setup("#settings #general", "general", {
      patch: {type: "select", name: "Patch/Engine", default: 60, datatype: 'integer', options: {60: '6.2'}},
      level: {type: "input", name: "Level", default: 100, datatype: 'integer', min: 100, max: 100},
      race: {type: "select", options: ["Human", "Dwarf", "Orc", "Blood Elf", "Gnome", "Worgen", "Troll", "Night Elf", "Undead", "Goblin", "Pandaren"], name: "Race", default: "Human"}
      night_elf_racial: {name: "Racial (Night Elf)", datatype: 'integer', type: 'select', options: {1: 'Day (1% Crit)', 0: 'Night (1% Haste)'}, default: 0}
      duration: {type: "input", name: "Fight Duration", default: 360, datatype: 'integer', min: 15, max: 1200}
      response_time: {type: "input", name: "Response Time", default: 0.5, datatype: 'float', min: 0.1, max: 5}
      time_in_execute_range: {type: "input", name: "Time in Execute Range", desc: "Only used in Assassination Spec", default: 0.35, datatype: 'float', min: 0, max: 1}
      lethal_poison: {name: "Lethal Poison", type: 'select', options: {'dp': 'Deadly Poison', 'wp': 'Wound Poison'}, default: 'dp'}
      num_boss_adds: {name: "Number of Boss Adds", datatype: 'float', type: 'input', min: 0, max: 20, default: 0}
      demon_enemy: {name: "Enemy is Demon", desc: 'Enables damage buff from heirloom trinket against demons (The Demon Button)', datatype: 'select', options: {1: 'Yes', 0: 'No'}, default: 0}
    })

    @setup("#settings #generalFilter", "general", {
      dynamic_ilvl: {name: "Dynamic ILevel filtering", type: "check", desc: "Dynamically filters items in gear lists to +/- 50 Ilevels of the item equipped in that slot. Disable this option to use the manual filtering options below.", default: true, datatype: 'bool'}
      max_ilvl: {name: "Max ILevel", type: "input", desc: "Don't show items over this item level in gear lists", default: 1000, datatype: 'integer', min: 540, max: 1000}
      min_ilvl: {name: "Min ILevel", type: "input", desc: "Don't show items under this item level in gear lists", default: 540, datatype: 'integer', min: 540, max: 1000}
      show_random_items: {name: "Min ILvL (Random Items)", desc: "Don't show random items under this item level in gear lists", datatype: 'integer', type: 'input', min: 540, max: 1000, default: 540}
      show_upgrades: {name: "Show Upgrades", desc: "Show all upgraded items in gear lists", datatype: 'integer', type: 'select', options: {1: 'Yes', 0: 'No'}, default: 0}
      epic_gems: {name: "Recommend Epic Gems", datatype: 'integer', type: 'select', options: {1: 'Yes', 0: 'No'}}
    })

    @setup("#settings #playerBuffs", "buffs", {
      food_buff: {name: "Food Buff", type: 'select', datatype: 'string', default: 'food_legion_375_versatility', options: {'food_legion_375_crit': 'The Hungry Magister (375 Crit)', 'food_legion_375_haste': 'Azshari Salad (375 Haste)', 'food_legion_375_mastery': 'Nightborne Delicacy Platter (375 Mastery)', 'food_legion_375_versatility': 'Seed-Battered Fish Plate (375 Versatility)', 'food_legion_feast_200': 'Lavish Suramar Feast (200 Agility)', 'food_legion_damage_3': 'Fishbrul Special (High Fire Proc)' } },
      flask_legion_agi: {name: "Legion Agility Flask", desc: "Flask of the Seventh Demon (1300 Agility)", default: true, datatype: 'bool'},
      short_term_haste_buff: {name: "+30% Haste/40 sec", desc: "Heroism/Bloodlust/Time Warp", default: true, datatype: 'bool'},
    })

    @setup("#settings #raidOther", "general", {
      prepot: {name: 'Pre-pot', type: 'select', datatype: 'string', default: 'potion_old_war', options: {'potion_old_war': 'Potion of the Old War', 'potion_deadly_grace': 'Potion of Deadly Grace', 'potion_none': 'None'} },
      potion: {name: 'Combat Potion', type: 'select', datatype: 'string', default: 'potion_old_war', options: {'potion_old_war': 'Potion of the Old War', 'potion_deadly_grace': 'Potion of Deadly Grace', 'potion_none': 'None'} }
    })

    @setup("#settings section.mutilate .settings", "rotation", {
      min_envenom_size_non_execute: {type: "select", name: "Min CP/Envenom > 35%", options: [5,4,3,2,1], default: 4, desc: "CP for Envenom when using Mutilate, no effect with Anticipation", datatype: 'integer', min: 1, max: 5}
      min_envenom_size_execute: {type: "select", name: "Min CP/Envenom < 35%", options: [5,4,3,2,1], default: 5, desc: "CP for Envenom when using Dispatch, no effect with Anticipation", datatype: 'integer', min: 1, max: 5}
      opener_name_assassination: {type: "select", name: "Opener Name", options: {'mutilate': "Mutilate", 'ambush': "Ambush", 'garrote': "Garrote"}, default: 'ambush', datatype: 'string'}
      opener_use_assassination: {type: "select", name: "Opener Usage", options: {'always': "Always", 'opener': "Start of the Fight", 'never': "Never"}, default: 'always', datatype: 'string'}
    })

    @setup("#settings section.combat .settings", "rotation", {
      ksp_immediately: {type: "select", name: "Killing Spree", options: {'true': "Killing Spree on cooldown", 'false': "Wait for Bandit's Guile before using Killing Spree"}, default: 'true', datatype: 'string'}
      revealing_strike_pooling: {type: "check", name: "Pool for Revealing Strike",  default: true, datatype: 'bool'}
      blade_flurry: {type: "check", name: "Blade Flurry", desc: "Use Blade Flurry", default: false, datatype: 'bool'}
      opener_name_combat: {type: "select", name: "Opener Name", options: {'sinister_strike': "Sinister Strike", 'revealing_strike': "Revealing Strike", 'ambush': "Ambush", 'garrote': "Garrote"}, default: 'ambush', datatype: 'string'}
      opener_use_combat: {type: "select", name: "Opener Usage", options: {'always': "Always", 'opener': "Start of the Fight", 'never': "Never"}, default: 'always', datatype: 'string'}
    })

    @setup("#settings section.subtlety .settings", "rotation", {
      sub_other_header: {type: "subheader", desc: "Main Rotation Options"}
      cp_builder: {type: "select", name: "CP Builder", options: {'backstab':'Backstab','gloomblade':'Gloomblade','shuriken_storm':'Shuriken Storm'}, default: 'backstab', datatype: 'string'}
      dance_cp_builder: {type: "select", name: "Dance CP Builder", options: {"shuriken_storm":"Shuriken Storm", "shadowstrike":"Shadowstrike"}, default: "shadowstrike", datatype: "string"}
      symbols_policy: {type: "select", name: "SoD Policy", options: {'always':"Use on cooldown", 'just':"Only use SoD when needed to refresh"}, default: "just", datatype: "string"}
      symbols_during_vanish: {type: "check", name: "Use SoD during Vanish", default: true, datatype: "bool"}
      max_vanish_builders: {type: "select", name: "Max Vanish Builders", options: [3,2,1,0], default: 3, datatype: 'integer', desc: "Maximum number of CP builders to use during Vanish. This option is modified by the Subterfuge talent."}
      max_dance_builders: {type: "select", name: "Max Dance Builders", options: [4,3,2,1,0], default: 4, datatype: 'integer', desc: "Maximum number of CP builders to use during Shadow Dance. This option is modified by the Subterfuge talent."}

      sub_finisher_header: {type: "subheader", desc: "Finisher Thresholds (Minimum CPs for each finisher)"}
      eviscerate_cps: {type: "select", name: "Eviscerate", options: [6,5,4,3,2,1], default: 5, datatype: 'integer', desc: "This option is modified by the Deeper Strategem talent"}
      nightblade_cps: {type: "select", name: "Nightblade", options: [6,5,4,3,2,1], default: 5, datatype: 'integer', desc: "This option is modified by the Deeper Strategem talent"}
      finality_eviscerate_cps: {type: "select", name: "Finality: Eviscerate", options: [6,5,4,3,2,1], default: 5, datatype: 'integer', desc: "This option is modified by the Deeper Strategem talent"}
      finality_nightblade_cps: {type: "select", name: "Finality: Nightblade", options: [6,5,4,3,2,1], default: 5, datatype: 'integer', desc: "This option is modified by the Deeper Strategem talent"}
      dfa_cps: {type: "select", name: "Death From Above", options: [6,5,4,3,2,1], default: 5, datatype: 'integer', desc: "This option is modified by the Deeper Strategem talent"}

      sub_dance_header: {type: "subheader", desc: "Shadow Dance Finishers"}
      sub_dance_evis: {type: "check", name: "Eviscerate", default: true, datatype: 'bool'}
      sub_dance_nb: {type: "check", name: "Nightblade", default: true, datatype: 'bool'}
      sub_dance_fin_evis: {type: "check", name: "Finality: Eviscerate", default: true, datatype: 'bool'}
      sub_dance_fin_nb: {type: "check", name: "Finality: Nightblade", default: true, datatype: 'bool'}
    })

    @setup("#settings #advancedSettings", "advanced", {
      latency: {type: "input", name: "Latency", default: 0.03, datatype: 'float', min: 0.0, max: 5}
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

    Shadowcraft.Talents.bind "changedSpec", (spec) ->
      $("#settings section.mutilate, #settings section.combat, #settings section.subtlety").hide()
      if Shadowcraft.Data.activeSpec == "a"
        $("#settings section.mutilate").show()
        if (Shadowcraft.Data.activeTalents.split("")[5] == "0")

          $("#opt-general-lethal_poison").append($("<option></option>").attr("value","ap").text("Agonizing Poison"))

      else if Shadowcraft.Data.activeSpec == "Z"
        $("#settings section.combat").show()
        $("#opt-general-lethal_poison option[value='ap']").remove()
      else if Shadowcraft.Data.activeSpec == "b"
        $("#settings section.subtlety").show()
        $("#opt-general-lethal_poison option[value='ap']").remove()

    Shadowcraft.Talents.bind "changedTalents", ->

      # Deeper strategem modifies a lot of options, so just check for it for all specs
      ds_active = (Shadowcraft.Data.activeTalents.split("")[2] == "0")
      
      Shadowcraft.Console.remove(".options-poisons")
      if Shadowcraft.Data.activeSpec == "a"
        # if in assassination, check to see if agonizing poison is selected
        agonizing = (Shadowcraft.Data.activeTalents.split("")[5] == "0")
        poisonSelect = $("#opt-general-lethal_poison")

        # if the user has ap selected in the options, but don't have the talent
        # selected, default back to dp and warn the user that we did it.
        if !agonizing
          if poisonSelect.val() == "ap"
            Shadowcraft.Console.warn("ap", "Agonizing Poison was selected in options. Defaulting to Deadly Poison", null, "warn", "options-poisons")
            poisonSelect.val("dp")
          $("#opt-general-lethal_poison option[value='ap']").remove()
        else
          poisonSelect.append($("<option></option>").attr("value","ap").text("Agonizing Poison"))

      else if Shadowcraft.Data.activeSpec == "b"

        if ds_active
          console.log "ds active"
          for i in ['eviscerate','nightblade','finality_eviscerate','finality_nightblade']
            box = $("#opt-rotation-#{i}_cps")
            if $("#opt-rotation-#{i}_cps option[value='6']").length == 0
              box.prepend($("<option></option>").attr("value","6").text("6"))
        else
          console.log "ds inactive"
          for i in ['eviscerate','nightblade','finality_eviscerate','finality_nightblade']
            box = $("#opt-rotation-#{i}_cps")
            if box.val() == "6"
              box.val("5")
            $("#opt-rotation-#{i}_cps option[value='6']").remove()

        max_dance = $("#opt-rotation-max_dance_builders")
        max_vanish = $("#opt-rotation-max_vanish_builders")

        # Subterfuge (row 2, column 2) modifies a few options. Max dance builders is 0-4 with
        # subterfuge and 0-3 without. Max vanish builders is 0-3 with subterfuge and 0-1
        # without.
        if (Shadowcraft.Data.activeTalents.split("")[1] == "1")
          console.log "subterfuge active"
          if $("#opt-rotation-max_dance_builders option[value='4']").length == 0
            max_dance.prepend($("<option></option>").attr("value","4").text("4"))
          if $("#opt-rotation-max_vanish_builders option[value='2']").length == 0
            max_vanish.prepend($("<option></option>").attr("value","2").text("2"))
          if $("#opt-rotation-max_vanish_builders option[value='3']").length == 0
            max_vanish.prepend($("<option></option>").attr("value","3").text("3"))
          
        else
          console.log "subterfuge inactive"
          if parseInt(max_dance.val()) > 3
            max_dance.val("3")
          $("#opt-rotation-max_dance_builders option[value='4']").remove()
          if parseInt(max_vanish.val()) > 1
            max_vanish.val("1")
          $("#opt-rotation-max_vanish_builders option[value='3']").remove()
          $("#opt-rotation-max_vanish_builders option[value='2']").remove()

    this

  constructor: ->
    $("#settings,#advanced").bind "change", $.delegate({ ".optionCheck": changeCheck })
    $("#settings,#advanced").bind "change", $.delegate({ ".optionSelect": changeSelect })
    $("#settings,#advanced").bind "change", $.delegate({ ".optionInput": changeInput })
    _.extend(this, Backbone.Events)
