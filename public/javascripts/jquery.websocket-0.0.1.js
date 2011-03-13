/*
 * jQuery Web Sockets Plugin v0.0.1
 * http://code.google.com/p/jquery-websocket/
 *
 * This document is licensed as free software under the terms of the
 * MIT License: http://www.opensource.org/licenses/mit-license.php
 *
 * Copyright (c) 2010 by shootaroo (Shotaro Tsubouchi).
 */
(function($){
$.extend({
	websocketSettings: {
		open: function(){},
		close: function(){},
		message: function(){},
		options: {},
		events: {}
	},
	websocket: function(url, s) {
		var ws = window.WebSocket ? new WebSocket( url ) : {
			send: function(m){ return false },
			close: function(){}
		};

    ws._settings = $.extend($.websocketSettings, s);
    ws._deferred = $.Deferred();
    ws._ready    = false;
		$(ws)
      .bind('open', function() { this._ready = true; this._deferred.resolve(); })
      .bind('close', function() { this._ready = false; this._deferred.reject(); })
			.bind('open', ws._settings.open)
			.bind('close', ws._settings.close)
      .bind('error', ws._settings.error)
			.bind('message', ws._settings.message)
			.bind('message', function(e){
				var m = $.evalJSON(e.originalEvent.data);
				var h = ws._settings.events[m.type];
				if (h) h.call(this, m);
			});

		ws._send = ws.send;
    ws.ready = ws._deferred.promise;
    var doSend = function(obj, type, data) {
      var m = {type: type, data: data};
      obj._send($.toJSON(m));
    };

		ws.send = function(type, data) {
      var obj = this;
      if(obj._ready) {
        doSend(obj, type, data);
      } else {
        ws.ready().then(function() { doSend(obj, type, data); });
      }
		};

		$(window).unload(function(){ ws.close(); ws = null });
		return ws;
	}
});
})(jQuery);
