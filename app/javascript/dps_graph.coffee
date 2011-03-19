class ShadowcraftDpsGraph
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
        Shadowcraft.History.loadSnapshot(app.snapshotHistory[item.dataIndex])
    ).mousedown((e) ->
      switch e.button
        when 2
          return false
    )

  datapoint: (data) ->
    if data.total_dps != @lastDPS
      snapshot = Shadowcraft.History.takeSnapshot()

      delta = data.total_dps - (@lastDPS || 0)
      deltatext = ""
      if @lastDPS
        deltatext = if delta >= 0 then " <em class='p'>(+#{delta.toFixed(1)})</em>" else " <em class='n'>(#{delta.toFixed(1)})</em>"

      $("#dps .inner").html(data.total_dps.toFixed(1) + " DPS" + deltatext)

      if snapshot
        @dpsHistory.push [@dpsIndex, Math.floor(data.total_dps * 10) / 10]
        @dpsIndex++
        @snapshotHistory.push(snapshot)
        if @dpsHistory.length > 30
          @dpsHistory.shift()
          @snapshotHistory.shift()

        @dpsPlot = $.plot($("#dpsgraph"), [@dpsHistory], {
          lines: { show: true },
          crosshair: { mode: "y" },
          points: { show: true },
          grid: { hoverable: true, clickable: true, autoHighlight: true },
        })
      @lastDPS = data.total_dps
