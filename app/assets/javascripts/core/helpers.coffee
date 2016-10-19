titleize = (str) ->
  return "" unless str
  sp = str.split(/[ _]/)
  word = []
  for s, i in sp
    f = s.substring(0,1).toUpperCase()
    r = s.substring(1).toLowerCase()
    word.push f+r
  word.join(' ')

tip = null
$doc = null
tooltip = (data, x, y, ox, oy) ->
  tip = $("#tooltip")
  if !tip or tip.length == 0
    tip = $("<div id='tooltip'></div>").addClass("ui-widget")
    $(document.body).append(tip)
    $doc = $(document.body)

  tip.html Templates.tooltip(data)
  tip.attr("class", data.class)
  x ||= $.data(document, "mouse-x")
  y ||= $.data(document, "mouse-y")
  rx = x + ox
  ry = y + oy

  if rx + tip.outerWidth() > $doc.outerWidth()
    rx = x - tip.outerWidth() - ox
  if ry + tip.outerHeight() > $doc.outerHeight()
    ry = y - tip.outerHeight() - oy

  tip.css({top: ry, left: rx}).show()

hideFlash = ->
  $(".flash").fadeOut("fast")

flash = (message) ->
  $flash = $(".flash")
  if $flash.length == 0
    $flash = $("<div class='flash'></div>")
    $flash.hide().click ->
      if flashHide
        window.clearTimeout(flashHide)
      hideFlash()
    $(document.body).append($flash)
  $flash.html(message)
  if !$flash.is(':visible')
    $(".flash").fadeIn(300)
  if flashHide
    window.clearTimeout(flashHide)
  flashHide = window.setTimeout(hideFlash, 1500)

# /******* View update helpers *************/

# This is kludgy.
checkForWarnings = (section) ->
  Shadowcraft.Console.hide()
  data = Shadowcraft.Data
  EnchantLookup = Shadowcraft.ServerData.ENCHANT_LOOKUP
  EnchantSlots = Shadowcraft.ServerData.ENCHANT_SLOTS

  if section == undefined or section == "options"
    # Warn basic stuff
    Shadowcraft.Console.remove(".options")
    if parseInt(data.options.general.patch) < 60
      Shadowcraft.Console.warn({}, "You are using an old Engine. Please switch to the newest Patch and/or clear all saved data and refresh from armory.", null, 'warn', 'options')

  if section == undefined or section == "talents"
    # Warn talents
    Shadowcraft.Console.remove(".talents")
    if data.activeTalents
      talents = data.activeTalents.split ""
      for row, i in talents
        if i in [0..6] and row == "."
          level = 0
          if (i < 6)
            level = (i+1)*15
          else if (i == 6)
            level = 100
          Shadowcraft.Console.warn({}, "Level #{level} Talent not set", null, 'warn', 'talents')

  if section == undefined or section == "gear"
    # Warn items
    Shadowcraft.Console.remove(".items")
    for slotIndex, gear of data.gear
      continue if !gear or _.isEmpty(gear) or gear.id in ShadowcraftConstants.ARTIFACTS
      item = Shadowcraft.Gear.getItem(gear.id, gear.base_ilvl)
      continue unless item
      enchant = EnchantLookup[gear.enchant]
      enchantable = EnchantSlots[item.equip_location] != undefined && Shadowcraft.Gear.getApplicableEnchants(slotIndex, item).length > 0

      if !enchant and enchantable
        i = {
          name: item.name,
          quality: gear.quality
        }
        Shadowcraft.Console.warn(i, "needs an enchantment", null, "warn", "items")

    # Warn artifact/relics might not work if not wearing complete set of artifact weapons
    mh_id = data.gear[15].id
    oh_id = data.gear[16].id
    if mh_id != ShadowcraftConstants.ARTIFACT_SETS[data.activeSpec].mh or oh_id != ShadowcraftConstants.ARTIFACT_SETS[data.activeSpec].oh
      Shadowcraft.Console.warn({}, "One or more weapons do not match Artifact set for current spec.", "Relic selection may not function correctly.", "warn", "items")

wait = (msg) ->
  msg ||= ""
  $("#waitMsg").html(msg)
  $("#wait").data('timeout', setTimeout('$("#wait").show()', 1000))

showPopup = (popup) ->
  # close any other visible popups and tooltips
  $(".popup").removeClass("visible")
  ttlib.hide()

  # make sure that this popup has a close button in the upper right corner and add
  # click and hover events for it
  if popup.find(".close-popup").length == 0
    popup.append("<a href='#' class='close-popup ui-dialog-titlebar-close ui-corner-all' role='button'><span class='ui-icon ui-icon-closethick'></span></a>")
    popup.find(".close-popup").click(->
      # hide the popup that is this close button's parent
      $(this).parent().removeClass("visible")

      # if this popup was the gear one, disable the active selection on the gear
      # slots that opened this popup
      if $(this).parent()[0].id == "gearpopup"
        $(".slots").find(".active").removeClass("active")
      return false
    ).hover ->
      $(this).addClass('ui-state-hover')
    , ->
      $(this).removeClass('ui-state-hover')

  # find the tab panel that this popup is being opened from. this will allow us to
  # position the popup relative to that tab panel.
  $parent = popup.parents(".ui-tabs-panel")
  max = $parent.scrollTop() + $parent.outerHeight()
  top = $.data(document, "mouse-y") - 40 + $parent.scrollTop()
  if top + popup.outerHeight() > max - 20
    top = max - 20 - popup.outerHeight()

  # make sure that the popup is at least 15 pixels from the top of the tab frame
  if top < 15
    top = 15

  left = $.data(document, "mouse-x") + 65
  if popup.width() + left > $parent.outerWidth() - 40
    left = popup.parents(".ui-tabs-panel").outerWidth() - popup.outerWidth() - 40

  # Position the popup and make it show up.
  popup.css({top: top + "px", left: left + "px"})
  popup.addClass("visible")
  body = popup.find(".body")

  # clear out the filter field on the popup
  popup.find("#filter input").val("")
  unless Modernizr.touch
    popup.find("#filter input").focus()
  ot = popup.find(".active").get(0)
  if ot
    ht = ot.offsetTop - (popup.height() / 3)
    speed = ht / 1.3
    speed = 500 if speed > 500
    body.animate({scrollTop: ht}, speed, 'swing')

window.titleize = titleize
window.tooltip = tooltip
window.hideFlash = hideFlash
window.flash = flash
window.showPopup = showPopup
window.wait = wait
window.checkForWarnings = checkForWarnings
