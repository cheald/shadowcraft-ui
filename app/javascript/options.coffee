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

  setup: (selector, namespace, checkData) ->
    data = Shadowcraft.Data
    s = $(selector);
    for key, opt of checkData
      ns = data.options[namespace]
      if !ns
        data.options[namespace] = {}
        ns = data.options[namespace]
      val = data.options[namespace][key]

      if val == undefined and opt.default?
        data.options[namespace][key] = opt.default
        val = opt.default

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
      switch inputType
        when "check"
          exist.attr("checked", val)
        when "select", "input"
          exist.val(val)

    null

  initOptions: ->
    data = Shadowcraft.Data

    @setup("#settings #general", "general", {
      level: {type: "input", name: "Level", 'default': 85},
      race: {type: "select", options: ["Human", "Dwarf", "Orc", "Blood Elf", "Gnome", "Worgen", "Troll", "Night Elf", "Undead", "Goblin"], name: "Race", 'default': "Human"}
      duration: {type: "input", name: "Fight Duration", 'default': 360}
      # tricks: {name: "Tricks of the Trade on cooldown", 'default': true}
      mh_poison: {name: "Mainhand Poison", type: 'select', options: {'ip': "Instant Poison", 'wp': 'Wound Poison', 'dp': 'Deadly Poison'}, 'default': 'ip'}
      oh_poison: {name: "Offhand Poison", type: 'select', options: {'ip': "Instant Poison", 'wp': 'Wound Poison', 'dp': 'Deadly Poison'}, 'default': 'dp'}
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
      guild_feast: {name: "Food Buff", desc: "Seafood Magnifique Feast/Skewered Eel", 'default': true},
      agi_flask: {name: "Agility Flask", desc: "Flask of the Wind/Flask of Battle", 'default': true},
      short_term_haste_buff: {name: "+30% Haste/45 sec", desc: "Heroism/Bloodlust/Time Warp", 'default': true},
      stat_multiplier_buff: {name: "5% All Stats", desc: "Blessing of Kings/Mark of the Wild", 'default': true},
      crit_chance_buff: {name: "5% Crit", desc: "Honor Among Thieves/Leader of the Pack/Rampage/Elemental Oath", 'default': true},
      all_damage_buff: {name: "3% All Damage", desc: "Arcane Tactics/Ferocious Inspiration/Communion", 'default': true},
      melee_haste_buff: {name: "10% Haste", desc: "Hunting Party/Windfury Totem/Icy Talons", 'default': true},
      attack_power_buff: {name: "10% Attack Power", desc: "Abomination's Might/Blessing of Might/Trueshot Aura/Unleashed Rage", 'default': true},
      str_and_agi_buff: {name: "Agility", desc: "Strength of Earth/Battle Shout/Horn of Winter/Roar of Courage", 'default': true}
    })

    @setup("#settings #targetDebuffs", "buffs", {
      armor_debuff: {name: "-12% Armor", desc: "Sunder Armor/Faerie Fire/Expose Armor", 'default': true},
      physical_vulnerability_debuff: {name: "+4% Physical Damage", desc: "Savage Combat/Trauma/Brittle Bones", 'default': true},
      spell_damage_debuff: {name: "+8% Spell Damage", desc: "Curse of the Elements/Earth and Moon/Master Poisoner/Ebon Plaguebringer", 'default': true},
      spell_crit_debuff: {name: "+5% Spell Crit", desc: "Critical Mass/Shadow and Flame", 'default': true},
      bleed_damage_debuff: {name: "+30% Bleed Damage", desc: "Blood Frenzy/Mangle/Hemorrhage", 'default': true}
    })

    @setup("#settings #raidOther", "general", {
      potion_of_the_tolvir: {name: "Use Potion of the Tol'vir", 'default': true}
    })

    @setup("#settings section.mutilate .settings", "rotation", {
      min_envenom_size_mutilate: {type: "select", name: "Min CP/Envenom > 35%", options: [5,4,3,2,1], 'default': 4, desc: "Use Envenom at this many combo points, when your primary CP builder is Mutilate"}
      min_envenom_size_backstab: {type: "select", name: "Min CP/Envenom < 35%", options: [5,4,3,2,1], 'default': 5, desc: "Use Envenom at this many combo points, when your primary CP builder is Backstab"}
      prioritize_rupture_uptime_mutilate: {name: "Prioritize Rupture (>35%)", right: true, desc: "Prioritize Rupture over Envenom when your CP builder is Mutilate", default: true}
      prioritize_rupture_uptime_backstab: {name: "Prioritize Rupture (<35%)", right: true, desc: "Prioritize Rupture over Envenom when your CP builder is Backstab", default: true}
    })

    @setup("#settings section.combat .settings", "rotation", {
      use_rupture: {name: "Use Rupture?", right: true, default: true}
      ksp_immediately: {type: "select", name: "Killing Spree", options: {'true': "Killing Spree on cooldown", 'false': "Wait for Bandit's Guile before using Killing Spree"}, 'default': 'false'}
      use_revealing_strike: {type: "select", name: "Revealing Strike", options: {"always": "Use for every finisher", "sometimes": "Only use at 4CP", "never": "Never use"}, 'default': "sometimes"}
    })

    @setup("#settings section.subtlety .settings", "rotation", {
      clip_recuperate: "Clip Recuperate?"
    })

  changeOption = (elem, val) ->
    $this = $(elem)
    data = Shadowcraft.Data
    ns = elem.attr("data-ns") || "root";
    data.options[ns] ||= {}
    name = $this.attr("name")
    if val == undefined
      val = $this.val()

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
    unless window.Touch
      $("#settings select").selectmenu({ style: 'dropdown' });

    Shadowcraft.bind "loadData", ->
      app.initOptions()

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