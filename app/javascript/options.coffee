class ShadowcraftOptions
  @buffMap = [
    'short_term_haste_buff',
    'stat_multiplier_buff',
    'crit_chance_buff',
    'all_damage_buff',
    'melee_haste_buff',
    'attack_power_buff',
    'str_and_agi_buff',
    'armor_debuff',
    'physical_vulnerability_debuff',
    'spell_damage_debuff',
    'spell_crit_debuff',
    'bleed_damage_debuff',
    'agi_flask',
    'guild_feast'
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
      if data.options[namespace][key]
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
                templateOptions.push {name: _v, value: _v}
            else
              for _k, _v of opt.options
                templateOptions.push {name: _v, value: _k}
            options =
              options: templateOptions
          when "input"
            template = Templates.input
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
        when "select", "input"
          exist.val(val)

    null

  initOptions: ->
    data = Shadowcraft.Data

    @setup("#settings #general", "general", {
      level: {type: "input", name: "Level", 'default': 85, datatype: 'integer', min: 85, max: 85},
      race: {type: "select", options: ["Human", "Dwarf", "Orc", "Blood Elf", "Gnome", "Worgen", "Troll", "Night Elf", "Undead", "Goblin"], name: "Race", 'default': "Human"}
      duration: {type: "input", name: "Fight Duration", 'default': 360, datatype: 'integer', min: 15, max: 1200}
      # tricks: {name: "Tricks of the Trade on cooldown", 'default': true}
      mh_poison: {name: "Mainhand Poison", type: 'select', options: {'ip': "Instant Poison", 'wp': 'Wound Poison', 'dp': 'Deadly Poison'}, 'default': 'ip'}
      oh_poison: {name: "Offhand Poison", type: 'select', options: {'ip': "Instant Poison", 'wp': 'Wound Poison', 'dp': 'Deadly Poison'}, 'default': 'dp'}
      max_ilvl: {name: "Max ILevel", type: "input", desc: "Don't show items over this ilevel in gear lists", 'default': 500, datatype: 'integer', min: 15, max: 500}
    })

    @setup("#settings #professions", "professions", {
      blacksmithing: "Blacksmithing",
      enchanting: "Enchanting",
      engineering: "Engineering",
      inscription: "Inscription",
      jewelcrafting: "Jewelcrafting",
      leatherworking: "Leatherworking",
      tailoring: "Tailoring"
    })

    @setup("#settings #playerBuffs", "buffs", {
      guild_feast: {name: "Food Buff", desc: "Seafood Magnifique Feast/Skewered Eel", 'default': true, datatype: 'bool'},
      agi_flask: {name: "Agility Flask", desc: "Flask of the Wind/Flask of Battle", 'default': true, datatype: 'bool'},
      short_term_haste_buff: {name: "+30% Haste/45 sec", desc: "Heroism/Bloodlust/Time Warp", 'default': true, datatype: 'bool'},
      stat_multiplier_buff: {name: "5% All Stats", desc: "Blessing of Kings/Mark of the Wild", 'default': true, datatype: 'bool'},
      crit_chance_buff: {name: "5% Crit", desc: "Honor Among Thieves/Leader of the Pack/Rampage/Elemental Oath", 'default': true, datatype: 'bool'},
      all_damage_buff: {name: "3% All Damage", desc: "Arcane Tactics/Ferocious Inspiration/Communion", 'default': true, datatype: 'bool'},
      melee_haste_buff: {name: "10% Haste", desc: "Hunting Party/Windfury Totem/Icy Talons", 'default': true, datatype: 'bool'},
      attack_power_buff: {name: "10% Attack Power", desc: "Abomination's Might/Blessing of Might/Trueshot Aura/Unleashed Rage", 'default': true, datatype: 'bool'},
      str_and_agi_buff: {name: "Agility", desc: "Strength of Earth/Battle Shout/Horn of Winter/Roar of Courage", 'default': true, datatype: 'bool'}
    })

    @setup("#settings #targetDebuffs", "buffs", {
      armor_debuff: {name: "-12% Armor", desc: "Sunder Armor/Faerie Fire/Expose Armor", 'default': true, datatype: 'bool'},
      physical_vulnerability_debuff: {name: "+4% Physical Damage", desc: "Savage Combat/Trauma/Brittle Bones", 'default': true, datatype: 'bool'},
      spell_damage_debuff: {name: "+8% Spell Damage", desc: "Curse of the Elements/Earth and Moon/Master Poisoner/Ebon Plaguebringer", 'default': true, datatype: 'bool'},
      spell_crit_debuff: {name: "+5% Spell Crit", desc: "Critical Mass/Shadow and Flame", 'default': true, datatype: 'bool'},
      bleed_damage_debuff: {name: "+30% Bleed Damage", desc: "Blood Frenzy/Mangle/Hemorrhage", 'default': true, datatype: 'bool'}
    })

    @setup("#settings #raidOther", "general", {
      potion_of_the_tolvir: {name: "Use Potion of the Tol'vir", 'default': true, datatype: 'bool'}
    })

    @setup("#settings section.mutilate .settings", "rotation", {
      min_envenom_size_mutilate: {type: "select", name: "Min CP/Envenom > 35%", options: [5,4,3,2,1], 'default': 4, desc: "Use Envenom at this many combo points, when your primary CP builder is Mutilate", datatype: 'integer', min: 1, max: 5}
      min_envenom_size_backstab: {type: "select", name: "Min CP/Envenom < 35%", options: [5,4,3,2,1], 'default': 5, desc: "Use Envenom at this many combo points, when your primary CP builder is Backstab", datatype: 'integer', min: 1, max: 5}
      # prioritize_rupture_uptime_mutilate: {name: "Prioritize Rupture (>35%)", right: true, desc: "Prioritize Rupture over Envenom when your CP builder is Mutilate", default: true, datatype: 'bool'}
      # prioritize_rupture_uptime_backstab: {name: "Prioritize Rupture (<35%)", right: true, desc: "Prioritize Rupture over Envenom when your CP builder is Backstab", default: true, datatype: 'bool'}
    })

    @setup("#settings section.combat .settings", "rotation", {
      use_rupture: {name: "Use Rupture?", right: true, default: true}
      ksp_immediately: {type: "select", name: "Killing Spree", options: {'true': "Killing Spree on cooldown", 'false': "Wait for Bandit's Guile before using Killing Spree"}, 'default': 'false', datatype: 'string'}
      use_revealing_strike: {type: "select", name: "Revealing Strike", options: {"always": "Use for every finisher", "sometimes": "Only use at 4CP", "never": "Never use"}, 'default': "sometimes", datatype: 'string'}
    })

    @setup("#settings section.subtlety .settings", "rotation", {
      clip_recuperate: "Clip Recuperate?"
    })

  changeOption = (elem, val) ->
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

    data.options[ns][name] = val
    Shadowcraft.update()

  changeCheck = ->
    $this = $(this)
    changeOption($this, $this.is(":checked"))
    Shadowcraft.setupLabels("#settings")

  changeSelect = ->
    changeOption(this)

  changeInput = ->
    changeOption(this)

  boot: ->
    app = this
    @initOptions()

    Shadowcraft.bind "loadData", ->
      app.initOptions()
      Shadowcraft.setupLabels("#settings")
      $("#settings select").change()

    Shadowcraft.Talents.bind "changed", ->
      $("#settings section.mutilate, #settings section.combat, #settings section.subtlety").hide()
      if Shadowcraft.Data.tree0 >= 31
        $("#settings section.mutilate").show()
      else if Shadowcraft.Data.tree1 >= 31
        $("#settings section.combat").show()
      else
        $("#settings section.subtlety").show()

    this

  constructor: ->
    $("#settings").bind "change", $.delegate({ ".optionCheck": changeCheck })
    $("#settings").bind "change", $.delegate({ ".optionSelect": changeSelect })
    $("#settings").bind "change", $.delegate({ ".optionInput": changeInput })