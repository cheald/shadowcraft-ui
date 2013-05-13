class ShadowcraftConsole
  constructor: ->
    @$log = $("#log .inner")
    @console = $("#console")
    @consoleInner = $("#console .inner")

  boot: ->
    $("#console .inner, #log .inner").oneFingerScroll()

  log: (msg, klass) ->
    @$log.append("<div class='#{klass}'>#{msg}</div>").scrollTop(@$log.get(0).scrollHeight)

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
