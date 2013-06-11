class ShadowcraftConsole
  constructor: ->
    @$log = $("#log .inner")
    @console = $("#console")
    @consoleInner = $("#console .inner")

  boot: ->
    $("#console .inner, #log .inner").oneFingerScroll()

  log: (msg, klass) ->
    date = new Date()
    now = Math.round date/1000
    msg = "["+date.getHours()+":"+date.getMinutes()+":"+date.getSeconds()+"] " + msg
    @$log.append("<div class='#{klass}' data-created='#{now}'>#{msg}</div>").scrollTop(@$log.get(0).scrollHeight)

  warn: (item, msg, submsg, klass, section) ->
    this.consoleMessage(item, msg, submsg, "warning", klass, section)

  consoleMessage: (item, msg, submsg, severity, klass, section) ->
    fullMsg = Templates.log({
      name: item.name,
      quality: item.quality,
      message: msg,
      submsg: submsg,
      severity: severity,
      messageClass: klass,
      section: section
    })

    @console.show()
    @consoleInner.append(fullMsg)

  hide: ->
    if not @consoleInner.html().trim()
      @console.hide()

  remove: (selector) ->
    @consoleInner.find("div"+selector).remove()
    if not @consoleInner.html().trim()
      @console.hide()

  clear: ->
    @consoleInner.empty()

  purgeOld: (age=60) ->
    now = Math.round +new Date()/1000
    $("#log .inner div").each ->
      $this = $(this)
      created = $this.data("created")
      if created + age < now
        $this.fadeOut 500, -> $this.remove()
    
