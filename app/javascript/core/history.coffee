# Handler class for all of the history, snapshot, and URLs. This uses a couple
# of rails endpoints to store and retrieve character data via SHA256 hashes.
# This helps keep the URLs to managable lengths while allowing the ShC code to
# add more data to the history as time goes on.
class ShadowcraftHistory

  constructor: (@app) ->
    @app.History = this
    Shadowcraft.Reset = @reset

  boot: ->
    app = this
    Shadowcraft.bind("update", -> app.save())
    $("#doImport").click ->
      json = $.parseJSON $("textarea#import").val()
      app.loadSnapshot json

    menu = $("#settingsDropdownMenu")
    menu.append("<li><a href='#' id='menuSaveSnapshot'>Save snapshot</li>")

    buttons =
      Ok: ->
        app.saveSnapshot($("#snapshotName").val())
        $(this).dialog "close"
      Cancel: ->
        $(this).dialog "close"

    $("#menuSaveSnapshot").click ->
      $("#saveSnapshot").dialog({
        modal: true,
        buttons: buttons,
        open: (event, ui) ->
          sn = $("#snapshotName")
          t = ShadowcraftTalents.GetActiveSpecName()
          d = new Date()
          t += " #{d.getFullYear()}-#{d.getMonth()+1}-#{d.getDate()}"
          sn.val(t)
      })

    $("#loadSnapshot").click $.delegate
      ".selectSnapshot": ->
        app.restoreSnapshot $(this).data("snapshot")
        $("#loadSnapshot").dialog("close")

      ".deleteSnapshot": ->
        app.deleteSnapshot $(this).data("snapshot")
        $("#loadSnapshot").dialog("close")
        $("#menuLoadSnapshot").click()

    menu.append("<li><a href='#' id='menuLoadSnapshot'>Load snapshot</li>")
    $("#menuLoadSnapshot").click ->
      app.selectSnapshot()
    this

  # Request a new SHA hash from the server for the current data, update the address
  # bar, and save the hash in the local browser storage.
  save: ->
    if @app.Data?
      $.post("/history/getsha", {data: $.toJSON(@app.Data)})
        .done((data) ->
          sha = data['sha']
          if window.history.replaceState
            window.history.replaceState("loadout", "Latest settings", window.location.pathname.replace(/\/+$/, "") + "/#!/" + sha)
          else
            window.location.hash = "!/" + sha
          $.jStorage.set(Shadowcraft.uuid, sha)
        )
      return

  # Callback method for the saveSnapshot method's call to takeSnapshot.
  saveCallback: (sha, extra) ->
    snapshot[extra['name']] = sha
    $.jStorage.set(key, snapshots)
    flash "#{name} has been saved"

  # Saves a snapshot into the local web storage with a specified name.
  saveSnapshot: (name) ->
    key = @app.uuid + "snapshots"
    snapshots = $.jStorage.get(key, {})
    extras = {'name':name}
    @takeSnapshot(saveCallback, extras)

  selectSnapshot: ->
    key = @app.uuid + "snapshots"
    snapshots = $.jStorage.get(key, {})
    d = $("#loadSnapshot")
    d.get(0).innerHTML = Templates.loadSnapshots({snapshots: _.keys(snapshots) })
    d.dialog({
      modal: true,
      width: 500
    })

  restoreSnapshot: (name) ->
    key = @app.uuid + "snapshots"
    snapshots = $.jStorage.get(key, {})
    @loadSnapshot snapshots[name]
    flash "#{name} has been loaded"

  deleteSnapshot: (name) ->
    if confirm "Delete this snapshot?"
      key = @app.uuid + "snapshots"
      snapshots = $.jStorage.get(key, {})
      delete snapshots[name]
      $.jStorage.set(key, snapshots)
      flash "#{name} has been deleted"

  load: (defaults) ->
    $.jStorage.flush()
    data = $.jStorage.get(@app.uuid, defaults)
    if data instanceof Array and data.length != 0
      # TODO: i'm not sure we'll ever enter this if statement. 
      $.post("/history/getjson", {data: data})
        .done((reqdata) ->
          data = $.parseJSON(reqdata)
        ).fail(() ->
          throw "Failed to load data for snapshot " + snapshot + "!"
        )
    else
      data = defaults
    return data

  loadFromFragment: ->
    hash = window.location.hash
    if hash and hash.match(/^#!/)
      sha = hash.substring(3)
      @loadSnapshot sha
      return true
    return false

  persist: (data) ->

  reset: ->
    if confirm("This will wipe out any changes you've made. Proceed?")
      $.jStorage.deleteKey(uuid)
      window.location.reload()

  # Calls to get a sha value for the current data from the rails app and
  # calls a callback when the data is retrieved.
  takeSnapshot: (callback, name) ->
    $.post("/history/getsha", {data: $.toJSON(@app.Data)})
      .done((data) -> callback(data['sha'], name))
      .fail((xhr, textStatus, errorThrown) ->
        throw "takeSnapshot failed to retrieve sha value")

  loadSnapshot: (snapshot) ->
    $.post("/history/getjson", {data: snapshot})
      .done((data) ->
        Shadowcraft.Data = data;
        Shadowcraft.loadData()
      ).fail(() ->
        throw "Failed to load data for snapshot " + snapshot + "!"
      )
    return
