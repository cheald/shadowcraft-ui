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

    $("#menuLoadSnapshot").click ->
      app.selectSnapshot()

    $("#loadSnapshot").click $.delegate
      ".selectSnapshot": ->
        app.restoreSnapshot $(this).data("snapshot")
        $("#loadSnapshot").dialog("close")

      ".deleteSnapshot": ->
        app.deleteSnapshot $(this).data("snapshot")
        $("#loadSnapshot").dialog("close")
        $("#menuLoadSnapshot").click()

    $("#menuGetDebugURL").click ->
      app.takeSnapshot(app.debugURLCallback, null)

    this

  # Save the current data state into in the browser's local storage.
  save: ->
    if @app.Data?
      $.jStorage.set(Shadowcraft.uuid, @app.Data)      
      return

  # Saves a snapshot into the local web storage with a specified name.
  saveSnapshot: (name) ->
    key = @app.uuid + "snapshots"
    snapshots = $.jStorage.get(key, {})
    snapshots[name] = $.toJSON(@app.Data)
    $.jStorage.set(key, snapshots)

  # Creates a popup dialog for the user to pick from a list of snapshots to
  # restore from.
  selectSnapshot: ->
    key = @app.uuid + "snapshots"
    snapshots = $.jStorage.get(key, {})
    d = $("#loadSnapshot")
    d.get(0).innerHTML = Templates.loadSnapshots({snapshots: _.keys(snapshots) })
    d.dialog({
      modal: true,
      width: 500
    })

  # Callback for the dialog created by the above selectSnapshot() method. This
  # takes the snapshot name the user selected and loads it.
  restoreSnapshot: (name) ->
    key = @app.uuid + "snapshots"
    snapshots = $.jStorage.get(key, {})
    this.loadSnapshot($.parseJSON(snapshots[name]))
    flash "#{name} has been loaded"

  # Callback for the dialog created by the above selectSnapshot() method. This
  # will delete a snapshot from local stoage.
  deleteSnapshot: (name) ->
    if confirm "Delete this snapshot?"
      key = @app.uuid + "snapshots"
      snapshots = $.jStorage.get(key, {})
      delete snapshots[name]
      $.jStorage.set(key, snapshots)
      flash "#{name} has been deleted"

  load: (defaults) ->
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

  # This method will attempt to load data from a URL with a hash in it. We only
  # handle these URLs for debugging purposes since the URL size was getting
  # completely out of hand and wasn't really necessary anyways. This calls the
  # rails instance and asks for data out of mongo that matches the requested
  # hash, then loads it. This method called directly from boot(), but will
  # generally just return false right away since the URL wont contain a hash.
  loadFromFragment: ->
    hash = window.location.hash
    if hash and hash.match(/^#!/)
      sha = hash.substring(3)
      $.post("/history/getjson", {data: sha})
        .done((data) ->
          Shadowcraft.Data = data;
          Shadowcraft.loadData()
        ).fail(() ->
          throw "Failed to load data for sha " + sha + "!"
        )
      return true
    return false

  # Resets all of the data in jstorage for a specific character's uuid. This
  # is akin to basically wiping out all of their snapshots. It will force a
  # reload of the window, which immediately reloads the current character data
  # back into jstorage.
  reset: ->
    if confirm("This will wipe out any changes you've made. Proceed?")
      $.jStorage.deleteKey(uuid)
      window.location.reload()

  # Calls to get a sha value for the current data from the rails app and calls
  # a callback when the data is retrieved.
  takeSnapshot: (callback, extras) ->
    $.post("/history/getsha", {data: $.toJSON(@app.Data)})
      .done((data) -> callback(data['sha'], extras))
      .fail((xhr, textStatus, errorThrown) ->
        throw "takeSnapshot failed to retrieve sha value")

  # Callback method for takeSnapshot method above. This is passed from the menu
  # item to get a debug URL, and opens a message box where the user can copy a
  # URL.
  debugURLCallback: (sha, extras) ->
    url = window.location.href.slice(0,-1)+"/#!/"+sha
    $("#generalDialog").html("<textarea style='width: 450px; height: 200px;'>#{url}</textarea>")
    $("#generalDialog").dialog({modal: true, width: 500, title: "Debugging URL" })

  # Loads the data from a snapshot and refreshes the window.
  loadSnapshot: (data) ->
    Shadowcraft.Data = data
    Shadowcraft.loadData()
    
