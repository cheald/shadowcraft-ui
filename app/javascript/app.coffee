$ = window.jQuery

class ShadowcraftApp
  RATING_CONVERSIONS = {
    80:
      hit_rating: 30.7548
      spell_hit: 26.232
      expertise_rating: 7.68869
    81:
      hit_rating: 40.3836
      spell_hit: 34.4448
      expertise_rating: 10.0959
    82:
      hit_rating: 53.0304
      spell_hit: 45.2318
      expertise_rating: 13.2576
    83:
      hit_rating: 69.6653
      spell_hit: 59.4204
      expertise_rating: 17.4163
    84:
      hit_rating: 91.4738
      spell_hit: 78.0218
      expertise_rating: 22.8685
    85:
      hit_rating: 120.109
      spell_hit: 102.446
      expertise_rating: 30.0272
  }

  reload: ->
    this.Options.initOptions()
    this.Talents.updateActiveTalents()
    this.Gear.updateDisplay()
    # $("select").selectmenu({ style: 'dropdown' })
    # checkForWarnings() # TODO - warnings for each module

  setupLabels: (selector) ->
    selector ||= document
    selector = $(selector)
    selector.find('.label_check').removeClass 'c_on'
    selector.find('.label_check input:checked').parent().addClass 'c_on'
    selector.find('.label_radio').removeClass 'r_on'
    selector.find('.label_radio input:checked').parent().addClass 'r_on'

  commonInit: ->
    $( "button, input:submit, .button").button()
    @setupLabels()

  boot: (@uuid, @Data, @ServerData) ->
    @Data = $.jStorage.get(uuid, @Data)
    @Data.options ||= {}

    # These are dummy default weights
    @Data.weights ||=
      attack_power: 1
      agility: 2.66
      crit_rating: 0.87
      spell_hit: 1.3
      hit_rating: 1.02
      expertise_rating: 1.51
      haste_rating: 1.44
      mastery_rating: 1.15
      yellow_hit: 1.79
      strength: 1.05

    ShadowcraftApp.trigger("boot")
    @Console = new ShadowcraftConsole(this);
    @History = new ShadowcraftHistory(this).boot()
    @Backend = new ShadowcraftBackend(this).boot()
    @Talents = new ShadowcraftTalents(this)
    @Options = new ShadowcraftOptions(this).boot()
    @Gear    = new ShadowcraftGear(this).boot()

    @Talents.boot()

    @commonInit()

    if window.FLASH.length > 0
      setTimeout(->
        flash "<p>#{window.FLASH.join('</p><p>')}</p>"
      , 1000)

    # Make scrolling more friendly on touchscreen devices
    $("body").bind "touchmove", (event) ->
      event.preventDefault()
    $("#tabs > .ui-tabs-panel").oneFingerScroll()
    $(".popup .body").oneFingerScroll()

    $("body").click(->
      $("ul.dropdownMenu").hide()
    ).click()
    $("a.dropdown").bind "click", ->
      $this = $(this)
      menu = $("#" + $this.data("menu"))
      if menu.is(":visible")
        $this.removeClass("active")
        menu.hide()
      else
        $this.addClass("active")
        p = $this.position()
        $this.css({zIndex: 102})
        top = p.top + $this.height() + 2
        right = p.left # + $this.width()
        menu.css({top: top + "px", left: right + "px"}).show()
      return false

    $("body").append("<div id='wait' style='display: none'></div>")
    $(".showWait").click ->
      $("#wait").fadeIn()

    $("#reloadAllData").click ->
      if confirm("Reload all data? This will wipe out all changes.")
        $.jStorage.flush()
        location.reload(true)

    this.setupLabels()
    true

  _T: (str) ->
    return 0 unless @Data.activeTalents
    idx = _.indexOf(@ServerData.TALENT_INDEX, str)
    t = @Data.activeTalents[idx]
    return 0 unless t
    return parseInt(t, 10)

  _R: (str) ->
    RATING_CONVERSIONS[@Data.options.general.level][str]

_.extend(ShadowcraftApp, Backbone.Events)