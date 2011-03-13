class ShadowcraftConsole
  constructor: ->
    @$log = $("#log .inner")
    @console = $("#console")
    @consoleInner = $("#console .inner")

  boot: ->
    $("#console .inner, #log .inner").oneFingerScroll()

  log: (msg, klass) ->
    @$log.prepend("<div class='#{klass}'}>#{msg}</div")

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
    @console.hide()

  remove: (selector) ->
    @consoleInner.remove(selector)

  clear: ->
    @consoleInner.empty()
