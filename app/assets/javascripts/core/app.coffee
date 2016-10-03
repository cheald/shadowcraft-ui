$ = window.jQuery

class ShadowcraftApp

  reload: ->
    this.Options.initOptions()
    this.Talents.updateActiveTalents()
    this.Gear.updateDisplay()
    # checkForWarnings() # TODO - warnings for each module

  setupLabels: (selector) ->
    selector ||= document
    selector = $(selector)
    selector.find('.label_check input:checkbox').each ->
      $(this).parent()[(if $(this).attr("checked")? or $(this).val() == "true" then "add" else "remove")+"Class"] 'c_on'
    selector.find('.label_radio').removeClass 'r_on'
    selector.find('.label_radio input:checked').parent().addClass 'r_on'

  commonInit: ->
    $( "button, input:submit, .button").button()
    @setupLabels()

  _update = ->
    Shadowcraft.trigger("update")

  update: ->
    if @updateThrottle
      @updateThrottle = clearTimeout(@updateThrottle)
    @updateThrottle = setTimeout(_update, 50)

  loadData: ->
    Shadowcraft.trigger("loadData")

  constructor: ->
    _.extend(this, Backbone.Events)

  boot: (@uuid, @region, data, @ServerData) ->
    try
      @_boot @uuid, data, @ServerData
    catch error
      console.log error
      $("#curtain").html("<div id='loaderror'>A fatal error occurred while loading this page.</div>").show()
      wait()
      if confirm("An unrecoverable error has occurred. Reset data and reload?")
        $.jStorage.flush()
        window.location.hash = ""
        newpath = window.location.href + "/refresh"
        location.assign(newpath)
      else
        throw error

  _boot: (@uuid, data, @ServerData) ->
    @History = new ShadowcraftHistory(this).boot()

    patch = window.location.hash.match(/#reload$/)

    unless @History.loadFromFragment()
      try
        @Data = @History.load(data)
        if patch
          data.options = Object.deepExtend(@Data.options, data.options)
          @Data = _.extend(@Data, data)

          @Data.active = data.active
          @Data.activeSpec = data.activeSpec
          @Data.activeTalents = data.activeTalents
      catch TypeError
        @Data = data
    @Data ||= data

    @Data.options ||= {}

    ShadowcraftApp.trigger("boot")
    @Console  = new ShadowcraftConsole(this)
    @Backend  = new ShadowcraftBackend(this).boot()
    @Artifact = new ShadowcraftArtifact(this)
    @Talents  = new ShadowcraftTalents(this)
    @Options  = new ShadowcraftOptions(this).boot()
    @Gear     = new ShadowcraftGear(this)
    @DpsGraph = new ShadowcraftDpsGraph(this)

    @Artifact.boot()
    @Talents.boot()
    @Gear.boot()

    @commonInit()

    $("#curtain").show()

    if window.FLASH.length > 0
      setTimeout(->
        flash "<p>#{window.FLASH.join('</p><p>')}</p>"
      , 1000)

    $("#tabs").tabs({
      show: (event, ui) ->
        $("ul.dropdownMenu").hide()
    })

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
        top = p.top + $this.height() + 5
        right = p.left # + $this.width()
        menu.css({top: top + "px", left: right + "px"}).show()
      return false

    $("body").append("<div id='wait' style='display: none'><div id='waitMsg'></div></div><div id='modal' style='display: none'></div>")
    $(".showWait").click ->
      $("#modal").hide()
      wait()

    $("#reloadAllData").click ->
      if confirm("Are you sure you want to clear all data?\n\nThis will wipe out all locally saved changes for ALL saved characters.\n\nThere is no undo!")
        $.jStorage.flush()
        location.hash = ""
        location.reload(true)

    $ ->
      Shadowcraft.update()

    this.setupLabels()
    true

  _T: (str) ->
    return 0 unless @Data.activeTalents
    idx = _.indexOf(@ServerData.TALENT_INDEX, str)
    t = @Data.activeTalents[idx]
    return 0 unless t
    return parseInt(t, 10)

_.extend(ShadowcraftApp, Backbone.Events)

window.ShadowcraftApp = ShadowcraftApp
