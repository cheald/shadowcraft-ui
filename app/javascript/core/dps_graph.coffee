class ShadowcraftDpsGraph
  MAX_POINTS = 20
  constructor: ->
    @dpsHistory = []
    @snapshotHistory = []
    @dpsIndex = 0
    app = this
    $("#dps .inner").html("--- DPS")
    Shadowcraft.Backend.bind "recompute", (data) ->
      app.datapoint(data)

    $("#dpsgraph").bind "plothover", (event, pos, item) ->
      if item
        tooltip({
          title: item.datapoint[1].toFixed(2) + " DPS",
          class: 'small clean'
        }, item.pageX, item.pageY, 15, -5)
      else
        $("#tooltip").hide()

    $("#dpsgraph").bind("plotclick", (event, pos, item) ->
      if item
        app.dpsPlot.unhighlight()
        app.dpsPlot.highlight(item.series, item.datapoint)
        snapshot = app.snapshotHistory[item.dataIndex]
        Shadowcraft.History.loadSnapshot(snapshot)
    ).mousedown((e) ->
      switch e.button
        when 2
          return false
    )

  datapointCallback: (sha, extras) ->
    data = extras['data']
    obj = extras['obj']
    delta = data.total_dps - (obj.lastDPS || 0)
    deltatext = ""
    if obj.lastDPS
      deltatext = if delta >= 0 then " <em class='p'>(+#{delta.toFixed(1)})</em>" else " <em class='n'>(#{delta.toFixed(1)})</em>"

    $("#dps .inner").html(data.total_dps.toFixed(1) + " DPS" + deltatext)

    if sha
      obj.dpsHistory.push [obj.dpsIndex, Math.round(data.total_dps * 10) / 10]
      obj.dpsIndex++
      obj.snapshotHistory.push(sha)
      if obj.dpsHistory.length > MAX_POINTS
        obj.dpsHistory.shift()
        obj.snapshotHistory.shift()

      obj.dpsPlot = $.plot($("#dpsgraph"), [obj.dpsHistory], {
        lines: { show: true }
        crosshair: { mode: "y" }
        points: { show: true }
        grid: { hoverable: true, clickable: true, autoHighlight: true }
        series: {
          threshold: { below: obj.dpsHistory[0][1], color: "rgb(200, 20, 20)" }
        }
      })
    obj.lastDPS = data.total_dps

  datapoint: (data) ->
    extras = {'data': data, 'obj': this}
    Shadowcraft.History.takeSnapshot(@datapointCallback, extras)
