json_encode = $.toJSON || Object.toJSON || (window.JSON && (JSON.encode || JSON.stringify))
NOOP = ->
  false

$.fn.disableTextSelection = ->
  return $(this).each ->
    if typeof this.onselectstart != "undefined" # IE
      this.onselectstart = NOOP
    else if typeof this.style.MozUserSelect != "undefined" # Firefox
      this.style.MozUserSelect = "none"
    else # All others
      this.onmousedown = NOOP
      this.style.cursor = "default"

$.expr[':'].regex = (elem, index, match) ->
  matchParams = match[3].split(',')
  validLabels = /^(data|css):/

  attr =
    method: if matchParams[0].match(validLabels) then matchParams[0].split(':')[0] else 'attr'
    property: matchParams.shift().replace(validLabels,'')

  regex = new RegExp(matchParams.join('').replace(/^\s+|\s+$/g,''), 'ig')
  regex.test(jQuery(elem)[attr.method](attr.property))

$.delegate = (rules) ->
  (e) ->
    target = $(e.target)
    for selector of rules
      bubbledTarget = target.closest(selector)
      if bubbledTarget.length > 0
        return rules[selector].apply(bubbledTarget, $.makeArray(arguments))

$.fn.oneFingerScroll = ->
  (->
    scrollingElement = null
    touchedAt = null
    scrollingStart = null
    this.bind("touchstart", (event) ->
      if event.originalEvent.touches.length == 1
        touchedAt = event.originalEvent.touches[0].pageY
        scrollingElement = $(this)
        scrollingStart = scrollingElement.scrollTop()
    ).bind("touchmove", (event) ->
      if event.originalEvent.touches.length == 1
        touch = event.originalEvent.touches[0]
        amt = touch.pageY - touchedAt
        scrollingElement.scrollTop(scrollingStart - amt)
        event.cancelBubble = true
        event.stopPropagation()
        event.preventDefault()
        return false
    )
  ).call(this)

$.fn.sortElements = (->
  shift = [].shift
  sort = [].sort
  return (comparator) ->
    return unless this and this.length > 0
    parent = this.get(0).parentNode
    elems = this.detach()
    sort.call(elems, comparator)
    while elems.length > 0
      parent.appendChild shift.call(elems)
)()

# modal = (dialog) ->
#   $(dialog).detach()
#   $("#wait").hide()
#   $("#modal").append(dialog).fadeIn()

Object.deepExtend = (destination, source) ->
  for property, value of source
    if value && value.constructor && value.constructor == Object
      destination[property] ||= {}
      arguments.callee(destination[property], value)
    else
      destination[property] = value
  return destination
