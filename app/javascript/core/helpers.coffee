titleize = (str) ->
  return "" unless str
  sp = str.split(/[ _]/)
  word = []
  for s, i in sp
    f = s.substring(0,1).toUpperCase()
    r = s.substring(1).toLowerCase()
    word.push f+r
  word.join(' ')

formatreforge = (str) ->
  return "" unless str
  sp = str.split(/[ _]/)
  word = []
  for s, i in sp
    f = s.substring(0,1).toUpperCase()
    r = s.substring(1).toLowerCase()
    word.push f+r+"Rating"
  word.join('')

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
  $flash = $(".flash");
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
  ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP
  EnchantLookup = Shadowcraft.ServerData.ENCHANT_LOOKUP
  EnchantSlots = Shadowcraft.ServerData.ENCHANT_SLOTS

  if section == undefined or section == "options"
    # Warn basic stuff
    Shadowcraft.Console.remove(".options")
    if parseInt(data.options.general.patch) < 52
      Shadowcraft.Console.warn({}, "You are using an old Engine. Please switch to the newest Patch and/or clear all saved data and refresh from armory.", null, 'warn', 'options')
    if parseInt(data.options.general.patch) < 54
      Shadowcraft.Console.warn({}, "5.4 PTR Version now available. Feel free to play with it.", "Please report every error or bug you encounter.", 'warn', 'options')
    if parseInt(data.options.general.patch) == 54
      Shadowcraft.Console.warn({}, "You are using 5.4 PTR: Feel free to play with it.", "Please report every error or bug you encounter.", 'warn', 'options')

  if section == undefined or section == "glyphs"
    # Warn glyphs
    Shadowcraft.Console.remove(".glyphs")
    if data.glyphs.length < 1
      Shadowcraft.Console.warn({}, "Glyphs need to be selected", null, 'warn', 'glyphs')

  if section == undefined or section == "talents"
    # Warn talents
    Shadowcraft.Console.remove(".talents")
    if data.activeTalents
      talents = data.activeTalents.split ""
      for row, i in talents
        if i in [0,5] and row == "."
          Shadowcraft.Console.warn({}, "Level " +  (i+1)*15 + " Talent not set", null, 'warn', 'talents')
        if i == 5 and row == "0"
          Shadowcraft.Console.warn({}, "Talent Shuriken Toss is not fully supported by Shadowcraft.", "It is recommended to not use this talent.", 'warn', 'talents')

  if section == undefined or section == "gear"
    # Warn items
    Shadowcraft.Console.remove(".items")
    for slotIndex, gear of data.gear
      continue if !gear
      item = ItemLookup[gear.item_id]
      continue unless item
      if item.name.indexOf("Rune of Re-Origination") != -1
        Shadowcraft.Console.warn(item, "is not fully supported but also bad for rogues.", "It is recommended to not use this trinket.", "warn", "items")
      enchant = EnchantLookup[gear.enchant]
      enchantable = EnchantSlots[item.equip_location] != undefined
      if (!data.options.professions.enchanting && item.equip_location == 11)
        enchantable = false

      #if Shadowcraft.Gear.canReforge item
      #  rec = Shadowcraft.Gear.recommendReforge(item, if gear.reforge then gear.reforge.stats else null)
      #  delta = if rec then Math.round(rec[rec.source.key + "_to_" + rec.dest.key] * 100) / 100 else 0
      #  if delta > 0
      #    if !gear.reforge
      #      Shadowcraft.Console.warn(item, "needs to be reforged", null, null, "items")
      #    else
      #      if rec and (gear.reforge.from.stat != rec.source.name || gear.reforge.to.stat != rec.dest.name)
      #        if !bestOptionalReforge || bestOptionalReforge < delta
      #          bestOptionalReforge = delta;
      #          Shadowcraft.Console.warn(item,
      #            "is not using an optimal reforge",
      #            "Using " + gear.reforge.from.stat + " &Rightarrow; " + gear.reforge.to.stat + ", recommend " + rec.source.name + " &Rightarrow; " + rec.dest.name + " (+" + delta + ")",
      #            "reforgeWarning",
      #            "items"
      #          );

      if !enchant and enchantable
        Shadowcraft.Console.warn(item, "needs an enchantment", null, "warn", "items")

wait = (msg) ->
  msg ||= ""
  $("#waitMsg").html(msg)
  $("#wait").data('timeout', setTimeout('$("#wait").show()', 1000))

stopWait = ->
  clearTimeout($("#wait").hide().data('timeout'))
  $("#wait").hide()

showPopup = (popup) ->
  $(".popup").removeClass("visible")
  if popup.find(".close-popup").length == 0
    popup.append("<a href='#' class='close-popup ui-dialog-titlebar-close ui-corner-all' role='button'><span class='ui-icon ui-icon-closethick'></span></a>")
    popup.find(".close-popup").click(->
      $(".popup").removeClass("visible")
      $(".slots").find(".active").removeClass("active")
      return false
    ).hover ->
      $(this).addClass('ui-state-hover')
    , ->
      $(this).removeClass('ui-state-hover')

  $parent = popup.parents(".ui-tabs-panel")
  max = $parent.scrollTop() + $parent.outerHeight()
  top = $.data(document, "mouse-y") - 40 + $parent.scrollTop()
  if top + popup.outerHeight() > max - 20
    top = max - 20 - popup.outerHeight()

  if top < 15
    top = 15

  left = $.data(document, "mouse-x") + 65
  if popup.width() + left > $parent.outerWidth() - 40
    left = popup.parents(".ui-tabs-panel").outerWidth() - popup.outerWidth() - 40

  popup.css({top: top + "px", left: left + "px"})
  popup.addClass("visible")
  ttlib.hide()
  body = popup.find(".body")
  $(".popup #filter input").val("")
  unless window.Touch
    $(".popup #filter input").focus()
  ot = popup.find(".active").get(0)
  if ot
    ht = ot.offsetTop - (popup.height() / 3)
    speed = ht / 1.3
    speed = 500 if speed > 500
    body.animate({scrollTop: ht}, speed, 'swing')
