class ShadowcraftOptions

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
      patch: {type: "select", name: "Patch/Engine", default: 70, datatype: 'integer', options: {70: '7.0'}},
      level: {type: "input", name: "Level", default: 110, datatype: 'integer', min: 110, max: 110},
      race: {type: "select", options: ["Human", "Dwarf", "Orc", "Blood Elf", "Gnome", "Worgen", "Troll", "Night Elf", "Undead", "Goblin", "Pandaren"], name: "Race", default: "Human"}
      night_elf_racial: {name: "Racial (Night Elf)", datatype: 'integer', type: 'select', options: {1: 'Day (1% Crit)', 0: 'Night (1% Haste)'}, default: 0}
      duration: {type: "input", name: "Fight Duration", default: 360, datatype: 'integer', min: 15, max: 1200}
      response_time: {type: "input", name: "Response Time", default: 0.5, datatype: 'float', min: 0.1, max: 5}
      num_boss_adds: {name: "Number of Boss Adds", datatype: 'float', type: 'input', min: 0, max: 20, default: 0}
      demon_enemy: {name: "Enemy is Demon", desc: 'Enables damage buff from heirloom trinket against demons', datatype: 'select', options: {1: 'Yes', 0: 'No'}, default: 0}
      mfd_resets: {name: "MfD Resets Per Minute", datatype: 'float', type: 'input', min: 0.0, max: 5.0, default: 0}
      finisher_threshold: {type: "select", name: "Finisher Threshold", options: [6,5,4], default: 5, datatype: "integer", desc: "Minimum CPs to use finisher"}
    })

    @setup("#settings #generalFilter", "general", {
      dynamic_ilvl: {name: "Dynamic ILevel filtering", type: "check", desc: "Dynamically filters items in gear lists to +/- 50 Ilevels of the item equipped in that slot. Disable this option to use the manual filtering options below.", default: true, datatype: 'bool'}
      max_ilvl: {name: "Max ILevel", type: "input", desc: "Don't show items over this item level in gear lists", default: 1000, datatype: 'integer', min: 540, max: 1000}
      min_ilvl: {name: "Min ILevel", type: "input", desc: "Don't show items under this item level in gear lists", default: 540, datatype: 'integer', min: 540, max: 1000}
      show_upgrades: {name: "Show Upgrades", desc: "Show all upgraded items in gear lists", datatype: 'integer', type: 'select', options: {1: 'Yes', 0: 'No'}, default: 0}
      epic_gems: {name: "Recommend Epic Gems", datatype: 'integer', type: 'select', options: {1: 'Yes', 0: 'No'}}
    })

    @setup("#settings #playerBuffs", "buffs", {
      food_buff: {name: "Food Buff", type: 'select', datatype: 'string', default: 'food_legion_375_versatility', options: {'food_legion_375_crit': 'The Hungry Magister (375 Crit)', 'food_legion_375_haste': 'Azshari Salad (375 Haste)', 'food_legion_375_mastery': 'Nightborne Delicacy Platter (375 Mastery)', 'food_legion_375_versatility': 'Seed-Battered Fish Plate (375 Versatility)', 'food_legion_feast_200': 'Lavish Suramar Feast (200 Agility)', 'food_legion_damage_3': 'Fishbrul Special (High Fire Proc)' } },
      flask_legion_agi: {name: "Legion Agility Flask", desc: "Flask of the Seventh Demon (1300 Agility)", default: true, datatype: 'bool'},
      short_term_haste_buff: {name: "+30% Haste/40 sec", desc: "Heroism/Bloodlust/Time Warp", default: true, datatype: 'bool'}
    })

    @setup("#settings #raidOther", "general", {
      prepot: {name: 'Pre-pot', type: 'select', datatype: 'string', default: 'potion_old_war', options: {'potion_old_war': 'Potion of the Old War', 'potion_deadly_grace': 'Potion of Deadly Grace', 'potion_none': 'None'} },
      potion: {name: 'Combat Potion', type: 'select', datatype: 'string', default: 'potion_old_war', options: {'potion_old_war': 'Potion of the Old War', 'potion_deadly_grace': 'Potion of Deadly Grace', 'potion_none': 'None'} }
    })

    @setup("#settings section.mutilate .settings", "rotation", {
      kingsbane: {type: "select", name: "Kingsbane w/ Vendetta", options: {"just": "Use cooldown if it aligns, but don't delay usage", "only": "Only use cooldown with Vendetta"}, default: "just"}
      exsang: {type: "select", name: "Exsang w/ Vendetta", options: {"just": "Use cooldown if it aligns, but don't delay usage", "only": "Only use cooldown with Vendetta"}, default: "just"}
      assn_cp_builder: {type: "select", name: "CP Builder", options: {'mutilate':'Mutilate','fan_of_knives':'Fan of Knives'}, default: 'mutilate', datatype: 'string'}
      lethal_poison: {name: "Lethal Poison", type: 'select', options: {'dp': 'Deadly Poison', 'wp': 'Wound Poison'}, default: 'dp'}
    })

    @setup("#settings section.combat .settings", "rotation", {
      blade_flurry: {type: "check", name: "Blade Flurry", desc: "Use Blade Flurry", default: false, datatype: "bool"}
      between_the_eyes_policy: {type: "select", name: "BtE Policy", options: {"shark": "Only use with Shark", "always": "Use BtE on cooldown", "never": "Never use BtE"}, default: "just"}
      reroll_policy: {type: "select", name: "RtB Reroll Policy", options: {"1": "Reroll single buffs", "2": "Reroll two or fewer buffs", "3": "Reroll three or fewer buffs", "custom": "Custom setup per buff (see below)"}, default: "1"}

      # I don't know why, but if i set the datatype to these to be integers and set options to be [0..3],
      # it won't actually let me select '0' as an option on the UI.
      jolly_roger_reroll: {type: "select", name: "Jolly Roger", options: ['0','1','2','3'], default: '0', desc: "0 means never reroll combos with this buff. 1 means reroll singles of this buff. 2 means reroll double-buff rolls containing this buff. 3 means reroll triple-buff rolls containing this buff."}
      grand_melee_reroll: {type: "select", name: "Grand Melee", options: ['0','1','2','3'], default: '0'}
      shark_reroll: {type: "select", name: "Shark-Infested Waters", options: ['0','1','2','3'], default: '0'}
      true_bearing_reroll: {type: "select", name: "True Bearing", options: ['0','1','2','3'], default: '0'}
      buried_treasure_reroll: {type: "select", name: "Buried Treasure", options: ['0','1','2','3'], default: '0'}
      broadsides_reroll: {type: "select", name: "Broadsides", options: ['0','1','2','3'], default: '0'}
    })

    @setup("#settings section.subtlety .settings", "rotation", {
      sub_cp_builder: {type: "select", name: "CP Builder", options: {'backstab':'Backstab','shuriken_storm':'Shuriken Storm'}, default: 'backstab', datatype: 'string'}
      symbols_policy: {type: "select", name: "SoD Policy", options: {'always':"Use on cooldown", 'just':"Only use SoD when needed to refresh"}, default: "just", datatype: "string"}
      dance_finishers_allowed: {type: "check", name: "Use Finishers during Dance", default: true, datatype: "bool"}
      positional_uptime: {type: "input", name: "Backstab uptime", desc: "Percentage of the fight you are behind the target (0-100). This has no effect if Gloomblade is selected as a talent.", datatype: "integer", default: 100, min: 0, max: 100}
      compute_cp_waste: {type: "check", name: "Compute CP Waste", desc: "EXPERIMENTAL FEATURE: Compute combo point waste", default: true, datatype: "bool"}
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
      # Hide all of the spec-specific sections from the options panel
      $("#settings section.mutilate, #settings section.combat, #settings section.subtlety").hide()

      # "a" is for assassination
      if Shadowcraft.Data.activeSpec == "a"
        # Show the mutilate section (otherwise known as the assassination section)
        $("#settings section.mutilate").show()

        # If the user has the agonizing poison talent selected, add that to the
        # menu for poisons.
        if (Shadowcraft.Data.activeTalents.split("")[5] == "0")
          $("#opt-rotation-lethal_poison").append($("<option></option>").attr("value","ap").text("Agonizing Poison"))
        else
          $("#opt-rotation-lethal_poison option[value='ap']").remove()

      # "Z" is for outlaw
      else if Shadowcraft.Data.activeSpec == "Z"
        $("#settings section.combat").show()

      # "b" is for subtlety
      else if Shadowcraft.Data.activeSpec == "b"
        $("#settings section.subtlety").show()

    Shadowcraft.Talents.bind "changedTalents", ->

      # Deeper strategem modifies a lot of options, so just check for it for all specs
      ds_active = (Shadowcraft.Data.activeTalents.split("")[2] == "0")

      Shadowcraft.Console.remove(".options-poisons")
      if Shadowcraft.Data.activeSpec == "a"
        # if in assassination, check to see if agonizing poison is selected
        agonizing = (Shadowcraft.Data.activeTalents.split("")[5] == "0")
        poisonSelect = $("#opt-rotation-lethal_poison")

        # if the user has ap selected in the options, but don't have the talent
        # selected, default back to dp and warn the user that we did it.
        if !agonizing
          if poisonSelect.val() == "ap"
            Shadowcraft.Console.warn("ap", "Agonizing Poison was selected in options. Defaulting to Deadly Poison", null, "warn", "options-poisons")
            poisonSelect.val("dp")
          $("#opt-rotation-lethal_poison option[value='ap']").remove()
        else
          poisonSelect.append($("<option></option>").attr("value","ap").text("Agonizing Poison"))

      finisher_threshold = $("#opt-general-finisher_threshold")
      if ds_active
        finisher_threshold.prepend($("<option></option>").attr("value","6").text("6"))
      else
        if finisher_threshold.find('option:selected').val() == "6"
          finisher_threshold.val("5")
        finisher_threshold.find("option[value='6']").remove()

    this

  constructor: ->
    $("#settings,#advanced").bind "change", $.delegate({ ".optionCheck": changeCheck })
    $("#settings,#advanced").bind "change", $.delegate({ ".optionSelect": changeSelect })
    $("#settings,#advanced").bind "change", $.delegate({ ".optionInput": changeInput })
    _.extend(this, Backbone.Events)

window.ShadowcraftOptions = ShadowcraftOptions
