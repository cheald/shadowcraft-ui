(function() {
  var $, $doc, NOOP, ShadowcraftApp, ShadowcraftBackend, ShadowcraftConsole, ShadowcraftDpsGraph, ShadowcraftGear, ShadowcraftHistory, ShadowcraftOptions, ShadowcraftTalents, ShadowcraftTiniReforgeBackend, Templates, checkForWarnings, deepCopy, flash, hideFlash, json_encode, loadingSnapshot, modal, showPopup, tip, titleize, tooltip, wait;
  $ = window.jQuery;
  ShadowcraftApp = (function() {
    var RATING_CONVERSIONS, _update;
    RATING_CONVERSIONS = {
      80: {
        hit_rating: 30.7548,
        spell_hit: 26.232,
        expertise_rating: 7.68869
      },
      81: {
        hit_rating: 40.3836,
        spell_hit: 34.4448,
        expertise_rating: 10.0959
      },
      82: {
        hit_rating: 53.0304,
        spell_hit: 45.2318,
        expertise_rating: 13.2576
      },
      83: {
        hit_rating: 69.6653,
        spell_hit: 59.4204,
        expertise_rating: 17.4163
      },
      84: {
        hit_rating: 91.4738,
        spell_hit: 78.0218,
        expertise_rating: 22.8685
      },
      85: {
        hit_rating: 120.109,
        spell_hit: 102.446,
        expertise_rating: 30.0272
      }
    };
    ShadowcraftApp.prototype.reload = function() {
      this.Options.initOptions();
      this.Talents.updateActiveTalents();
      return this.Gear.updateDisplay();
    };
    ShadowcraftApp.prototype.setupLabels = function(selector) {
      selector || (selector = document);
      selector = $(selector);
      selector.find('.label_check').removeClass('c_on');
      selector.find('.label_check input:checked').parent().addClass('c_on');
      selector.find('.label_radio').removeClass('r_on');
      return selector.find('.label_radio input:checked').parent().addClass('r_on');
    };
    ShadowcraftApp.prototype.commonInit = function() {
      $("button, input:submit, .button").button();
      return this.setupLabels();
    };
    _update = function() {
      return Shadowcraft.trigger("update");
    };
    ShadowcraftApp.prototype.update = function() {
      if (this.updateThrottle) {
        this.updateThrottle = clearTimeout(this.updateThrottle);
      }
      return this.updateThrottle = setTimeout(_update, 50);
    };
    ShadowcraftApp.prototype.loadData = function() {
      return Shadowcraft.trigger("loadData");
    };
    function ShadowcraftApp() {
      _.extend(this, Backbone.Events);
    }
    ShadowcraftApp.prototype.boot = function(uuid, data, ServerData) {
      this.uuid = uuid;
      this.ServerData = ServerData;
      try {
        return this._boot(this.uuid, data, this.ServerData);
      } catch (error) {
        $("#curtain").html("<div id='loaderror'>A fatal error occurred while loading this page.</div>").show();
        wait();
        if (confirm("An unrecoverable error has occurred. Reset data and reload?")) {
          $.jStorage.flush();
          return location.reload(true);
        } else {
          throw error;
        }
      }
    };
    ShadowcraftApp.prototype._boot = function(uuid, data, ServerData) {
      var patch, _base;
      this.uuid = uuid;
      this.ServerData = ServerData;
      this.History = new ShadowcraftHistory(this).boot();
      patch = window.location.hash.match(/#reload$/);
      if (!this.History.loadFromFragment()) {
        try {
          this.Data = this.History.load(data);
          if (patch) {
            data.options = Object.deepExtend(this.Data.options, data.options);
            this.Data = _.extend(this.Data, data);
            this.Data.activeTalents = null;
          }
        } catch (TypeError) {
          this.Data = data;
        }
      }
      this.Data || (this.Data = data);
      (_base = this.Data).options || (_base.options = {});
      ShadowcraftApp.trigger("boot");
      this.Console = new ShadowcraftConsole(this);
      this.Backend = new ShadowcraftBackend(this).boot();
      this.Talents = new ShadowcraftTalents(this);
      this.Options = new ShadowcraftOptions(this).boot();
      this.Gear = new ShadowcraftGear(this);
      this.DpsGraph = new ShadowcraftDpsGraph(this);
      this.Talents.boot();
      this.Gear.boot();
      this.commonInit();
      $("#curtain").show();
      if (window.FLASH.length > 0) {
        setTimeout(function() {
          return flash("<p>" + (window.FLASH.join('</p><p>')) + "</p>");
        }, 1000);
      }
      $("#tabs").tabs({
        show: function(event, ui) {
          return $("ul.dropdownMenu").hide();
        }
      });
      $("body").bind("touchmove", function(event) {
        return event.preventDefault();
      });
      $("#tabs > .ui-tabs-panel").oneFingerScroll();
      $(".popup .body").oneFingerScroll();
      $("body").click(function() {
        return $("ul.dropdownMenu").hide();
      }).click();
      $("a.dropdown").bind("click", function() {
        var $this, menu, p, right, top;
        $this = $(this);
        menu = $("#" + $this.data("menu"));
        if (menu.is(":visible")) {
          $this.removeClass("active");
          menu.hide();
        } else {
          $this.addClass("active");
          p = $this.position();
          $this.css({
            zIndex: 102
          });
          top = p.top + $this.height() + 2;
          right = p.left;
          menu.css({
            top: top + "px",
            left: right + "px"
          }).show();
        }
        return false;
      });
      $("body").append("<div id='wait' style='display: none'><div id='waitMsg'></div></div><div id='modal' style='display: none'></div>");
      $(".showWait").click(function() {
        $("#modal").hide();
        return wait();
      });
      $("#reloadAllData").click(function() {
        if (confirm("Are you sure you want to clear all data?\n\nThis will wipe out all locally saved changes for ALL saved characters.\n\nThere is no undo!")) {
          $.jStorage.flush();
          return location.reload(true);
        }
      });
      this.setupLabels();
      return true;
    };
    ShadowcraftApp.prototype._T = function(str) {
      var idx, t;
      if (!this.Data.activeTalents) {
        return 0;
      }
      idx = _.indexOf(this.ServerData.TALENT_INDEX, str);
      t = this.Data.activeTalents[idx];
      if (!t) {
        return 0;
      }
      return parseInt(t, 10);
    };
    ShadowcraftApp.prototype._R = function(str) {
      return RATING_CONVERSIONS[this.Data.options.general.level][str];
    };
    return ShadowcraftApp;
  })();
  _.extend(ShadowcraftApp, Backbone.Events);
  json_encode = $.toJSON || Object.toJSON || (window.JSON && (JSON.encode || JSON.stringify));
  NOOP = function() {
    return false;
  };
  $.fn.disableTextSelection = function() {
    return $(this).each(function() {
      if (typeof this.onselectstart !== "undefined") {
        return this.onselectstart = NOOP;
      } else if (typeof this.style.MozUserSelect !== "undefined") {
        return this.style.MozUserSelect = "none";
      } else {
        this.onmousedown = NOOP;
        return this.style.cursor = "default";
      }
    });
  };
  $.expr[':'].regex = function(elem, index, match) {
    var attr, matchParams, regex, validLabels;
    matchParams = match[3].split(',');
    validLabels = /^(data|css):/;
    attr = {
      method: matchParams[0].match(validLabels) ? matchParams[0].split(':')[0] : 'attr',
      property: matchParams.shift().replace(validLabels, '')
    };
    regex = new RegExp(matchParams.join('').replace(/^\s+|\s+$/g, ''), 'ig');
    return regex.test(jQuery(elem)[attr.method](attr.property));
  };
  $.delegate = function(rules) {
    return function(e) {
      var bubbledTarget, selector, target;
      target = $(e.target);
      for (selector in rules) {
        bubbledTarget = target.closest(selector);
        if (bubbledTarget.length > 0) {
          return rules[selector].apply(bubbledTarget, $.makeArray(arguments));
        }
      }
    };
  };
  $.fn.oneFingerScroll = function() {
    return (function() {
      var scrollingElement, scrollingStart, touchedAt;
      scrollingElement = null;
      touchedAt = null;
      scrollingStart = null;
      return this.bind("touchstart", function(event) {
        if (event.originalEvent.touches.length === 1) {
          touchedAt = event.originalEvent.touches[0].pageY;
          scrollingElement = $(this);
          return scrollingStart = scrollingElement.scrollTop();
        }
      }).bind("touchmove", function(event) {
        var amt, touch;
        if (event.originalEvent.touches.length === 1) {
          touch = event.originalEvent.touches[0];
          amt = touch.pageY - touchedAt;
          scrollingElement.scrollTop(scrollingStart - amt);
          event.cancelBubble = true;
          event.stopPropagation();
          event.preventDefault();
          return false;
        }
      });
    }).call(this);
  };
  deepCopy = function(obj) {
    var i, k, len, out;
    if (obj instanceof Array) {
      out = [];
      i = 0;
      len = obj.length;
      for (i = 0; (0 <= len ? i <= len : i >= len); (0 <= len ? i += 1 : i -= 1)) {
        out[i] = arguments.callee(obj[i]);
      }
      return out;
    }
    if (typeof obj === 'object') {
      out = {};
      for (i in obj) {
        k = obj[i];
        out[i] = arguments.callee(k);
      }
      return out;
    }
    return obj;
  };
  String.prototype.capitalize = function() {
    return this.replace(/(^|\s)([a-z])/g, function(m, p1, p2) {
      return p1 + p2.toUpperCase();
    });
  };
  $.fn.sortElements = (function() {
    var shift, sort;
    shift = [].shift;
    sort = [].sort;
    return function(comparator) {
      var elems, parent, _results;
      if (!(this && this.length > 0)) {
        return;
      }
      parent = this.get(0).parentNode;
      elems = this.detach();
      sort.call(elems, comparator);
      _results = [];
      while (elems.length > 0) {
        _results.push(parent.appendChild(shift.call(elems)));
      }
      return _results;
    };
  })();
  modal = function(dialog) {
    $(dialog).detach();
    $("#wait").hide();
    return $("#modal").append(dialog).fadeIn();
  };
  Object.deepExtend = function(destination, source) {
    var property, value;
    for (property in source) {
      value = source[property];
      if (value && value.constructor && value.constructor === Object) {
        destination[property] || (destination[property] = {});
        arguments.callee(destination[property], value);
      } else {
        destination[property] = value;
      }
    }
    return destination;
  };
  Templates = null;
  ShadowcraftApp.bind("boot", function() {
    return Templates = {
      itemSlot: Handlebars.compile($("#template-itemSlot").html()),
      stats: Handlebars.compile($("#template-stats").html()),
      reforge: Handlebars.compile($("#template-reforge").html()),
      checkbox: Handlebars.compile($("#template-checkbox").html()),
      select: Handlebars.compile($("#template-select").html()),
      input: Handlebars.compile($("#template-input").html()),
      talentTree: Handlebars.compile($("#template-tree").html()),
      tooltip: Handlebars.compile($("#template-tooltip").html()),
      talentSet: Handlebars.compile($("#template-talent_set").html()),
      log: Handlebars.compile($("#template-log").html()),
      glyphSlot: Handlebars.compile($("#template-glyph_slot").html()),
      talentContribution: Handlebars.compile($("#template-talent_contribution").html()),
      loadSnapshots: Handlebars.compile($("#template-loadSnapshots").html())
    };
  });
  ShadowcraftBackend = (function() {
    var HTTP_ENGINE, WS_ENGINE;
    HTTP_ENGINE = "http://" + window.location.hostname + ":8880/";
    WS_ENGINE = "ws://" + window.location.hostname + ":8880/engine";
    function ShadowcraftBackend(app) {
      this.app = app;
      this.app.Backend = this;
      _.extend(this, Backbone.Events);
    }
    ShadowcraftBackend.prototype.boot = function() {
      var self;
      self = this;
      Shadowcraft.bind("update", function() {
        return self.recompute();
      });
      this.ws = $.websocket(WS_ENGINE, {
        error: function(e) {
          return console.log(e);
        },
        events: {
          response: function(e) {
            return self.handleRecompute(e.data);
          }
        }
      });
      return this;
    };
    ShadowcraftBackend.prototype.buildPayload = function() {
      var Gems, GlyphLookup, ItemLookup, Talents, buffList, data, g, gear_ids, glyph, glyph_list, k, key, mh, oh, payload, statSum, statSummary, th, val, _i, _len, _ref, _ref2, _ref3;
      data = Shadowcraft.Data;
      ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
      Talents = Shadowcraft.ServerData.TALENTS;
      statSum = Shadowcraft.Gear.statSum;
      Gems = Shadowcraft.ServerData;
      GlyphLookup = Shadowcraft.ServerData.GLYPH_LOOKUP;
      statSummary = Shadowcraft.Gear.sumStats();
      if (data.gear[15]) {
        mh = ItemLookup[data.gear[15].item_id];
      }
      if (data.gear[16]) {
        oh = ItemLookup[data.gear[16].item_id];
      }
      if (data.gear[17]) {
        th = ItemLookup[data.gear[17].item_id];
      }
      glyph_list = [];
      _ref = data.glyphs;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        glyph = _ref[_i];
        if (GlyphLookup[glyph] != null) {
          glyph_list.push(GlyphLookup[glyph].ename);
        }
      }
      buffList = [];
      _ref2 = data.options.buffs;
      for (key in _ref2) {
        val = _ref2[key];
        if (val) {
          buffList.push(ShadowcraftOptions.buffMap.indexOf(key));
        }
      }
      payload = {
        r: data.options.general.race,
        l: data.options.general.level,
        pot: data.options.general.potion_of_the_tolvir ? 1 : 0,
        b: buffList,
        ro: data.options.rotation,
        settings: {
          mh_poison: data.options.general.mh_poison,
          oh_poison: data.options.general.oh_poison,
          duration: data.options.general.duration
        },
        t: [data.activeTalents.substr(0, Talents[0].talent.length), data.activeTalents.substr(Talents[0].talent.length, Talents[1].talent.length), data.activeTalents.substr(Talents[0].talent.length + Talents[1].talent.length, Talents[2].talent.length)],
        sta: [statSummary.strength || 0, statSummary.agility || 0, statSummary.attack_power || 0, statSummary.crit_rating || 0, statSummary.hit_rating || 0, statSummary.expertise_rating || 0, statSummary.haste_rating || 0, statSummary.mastery_rating || 0],
        gly: glyph_list,
        pro: data.options.professions
      };
      if (mh != null) {
        payload.mh = [mh.speed, mh.dps * mh.speed, data.gear[15].enchant, mh.subclass];
      }
      if (oh != null) {
        payload.oh = [oh.speed, oh.dps * oh.speed, data.gear[16].enchant, oh.subclass];
      }
      if (th != null) {
        payload.th = [th.speed, th.dps * th.speed, data.gear[17].enchant, th.subclass];
      }
      gear_ids = [];
      _ref3 = data.gear;
      for (k in _ref3) {
        g = _ref3[k];
        gear_ids.push(g.item_id);
        if (k === 0 && g.g0 && Gems[g.g0] && Gems[g.g0].Meta) {
          if (ShadowcraftGear.CHAOTIC_METAGEMS.indexOf(g.g0)) {
            payload.mg = "chaotic";
          }
        }
      }
      payload.g = gear_ids;
      return payload;
    };
    ShadowcraftBackend.prototype.handleRecompute = function(data) {
      Shadowcraft.Console.remove(".error");
      if (data.error) {
        Shadowcraft.Console.warn({}, data.error, null, "error", "error");
        return;
      }
      this.app.lastCalculation = data;
      return this.trigger("recompute", data);
    };
    ShadowcraftBackend.prototype.recompute = function() {
      var payload;
      this.cancelRecompute = false;
      payload = this.buildPayload();
      if (this.cancelRecompute || !(payload != null)) {
        return;
      }
      if (window.WebSocket) {
        return this.recompute_via_websocket(payload);
      } else {
        return this.recompute_via_post(payload);
      }
    };
    ShadowcraftBackend.prototype.recompute_via_websocket = function(payload) {
      return this.ws.send("m", payload);
    };
    ShadowcraftBackend.prototype.recompute_via_post = function(payload) {
      if ($.browser.msie && window.XDomainRequest) {
        return this.recompute_via_xdr(payload);
      } else {
        return this.recompute_via_xhr(payload);
      }
    };
    ShadowcraftBackend.prototype.recompute_via_xdr = function(payload) {
      var app, xdr;
      app = this;
      xdr = new XDomainRequest();
      xdr.open("get", HTTP_ENGINE + ("?rnd=" + (new Date().getTime()) + "&data=") + JSON.stringify(payload));
      xdr.send();
      return xdr.onload = function() {
        var data;
        data = JSON.parse(xdr.responseText);
        return app.handleRecompute(data);
      };
    };
    ShadowcraftBackend.prototype.recompute_via_xhr = function(payload) {
      var app;
      app = this;
      return $.post(HTTP_ENGINE, {
        data: $.toJSON(payload)
      }, function(data) {
        return app.handleRecompute(data);
      }, 'json');
    };
    return ShadowcraftBackend;
  })();
  loadingSnapshot = false;
  ShadowcraftHistory = (function() {
    var DATA_VERSION, base10, base36Decode, base36Encode, base77, compress, compress_handlers, decompress, decompress_handlers, map, poisonMap, professionMap, raceMap, rotationOptionsMap, rotationValueMap, unmap;
    DATA_VERSION = 1;
    function ShadowcraftHistory(app) {
      this.app = app;
      this.app.History = this;
      Shadowcraft.Reset = this.reset;
    }
    ShadowcraftHistory.prototype.boot = function() {
      var app, buttons, menu;
      app = this;
      Shadowcraft.bind("update", function() {
        return app.save();
      });
      $("#doImport").click(function() {
        var json;
        json = $.parseJSON($("textarea#import").val());
        return app.loadSnapshot(json);
      });
      menu = $("#settingsDropdownMenu");
      menu.append("<li><a href='#' id='menuSaveSnapshot'>Save snapshot</li>");
      buttons = {
        Ok: function() {
          app.saveSnapshot($("#snapshotName").val());
          return $(this).dialog("close");
        },
        Cancel: function() {
          return $(this).dialog("close");
        }
      };
      $("#menuSaveSnapshot").click(function() {
        return $("#saveSnapshot").dialog({
          modal: true,
          buttons: buttons,
          open: function(event, ui) {
            var d, sn, t;
            sn = $("#snapshotName");
            t = ShadowcraftTalents.GetPrimaryTreeName();
            d = new Date();
            t += " " + (d.getFullYear()) + "-" + (d.getMonth()) + "-" + (d.getDate());
            return sn.val(t);
          }
        });
      });
      $("#loadSnapshot").click($.delegate({
        ".selectSnapshot": function() {
          app.restoreSnapshot($(this).data("snapshot"));
          return $("#loadSnapshot").dialog("close");
        },
        ".deleteSnapshot": function() {
          app.deleteSnapshot($(this).data("snapshot"));
          $("#loadSnapshot").dialog("close");
          return $("#menuLoadSnapshot").click();
        }
      }));
      menu.append("<li><a href='#' id='menuLoadSnapshot'>Load snapshot</li>");
      $("#menuLoadSnapshot").click(function() {
        return app.selectSnapshot();
      });
      return this;
    };
    ShadowcraftHistory.prototype.save = function() {
      var data;
      if (this.app.Data != null) {
        data = compress(this.app.Data);
        this.persist(data);
        return $.jStorage.set(this.app.uuid, data);
      }
    };
    ShadowcraftHistory.prototype.saveSnapshot = function(name) {
      var key, snapshots;
      key = this.app.uuid + "snapshots";
      snapshots = $.jStorage.get(key, {});
      snapshots[name] = this.takeSnapshot();
      $.jStorage.set(key, snapshots);
      return flash("" + name + " has been saved");
    };
    ShadowcraftHistory.prototype.selectSnapshot = function() {
      var d, key, snapshots;
      key = this.app.uuid + "snapshots";
      snapshots = $.jStorage.get(key, {});
      d = $("#loadSnapshot");
      d.get(0).innerHTML = Templates.loadSnapshots({
        snapshots: _.keys(snapshots)
      });
      return d.dialog({
        modal: true,
        width: 500
      });
    };
    ShadowcraftHistory.prototype.restoreSnapshot = function(name) {
      var key, snapshots;
      key = this.app.uuid + "snapshots";
      snapshots = $.jStorage.get(key, {});
      return this.loadSnapshot(snapshots[name]);
    };
    ShadowcraftHistory.prototype.deleteSnapshot = function(name) {
      var key, snapshots;
      if (confirm("Delete this snapshot?")) {
        key = this.app.uuid + "snapshots";
        snapshots = $.jStorage.get(key, {});
        delete snapshots[name];
        $.jStorage.set(key, snapshots);
        return flash("" + name + " has been deleted");
      }
    };
    ShadowcraftHistory.prototype.load = function(defaults) {
      var data;
      data = $.jStorage.get(this.app.uuid, defaults);
      if (data instanceof Array && data.length !== 0) {
        data = decompress(data);
      } else {
        data = defaults;
      }
      return data;
    };
    ShadowcraftHistory.prototype.loadFromFragment = function() {
      var frag, hash, inflated, snapshot;
      hash = window.location.hash;
      if (hash && hash.match(/^#!/)) {
        frag = hash.substring(3);
        inflated = RawDeflate.inflate($.base64Decode(frag));
        snapshot = null;
        try {
          snapshot = $.parseJSON(inflated);
        } catch (TypeError) {
          snapshot = null;
        }
        if (snapshot != null) {
          this.loadSnapshot(snapshot);
          return true;
        }
      }
      return false;
    };
    ShadowcraftHistory.prototype.persist = function(data) {
      var frag, jd;
      this.lookups || (this.lookups = {});
      jd = json_encode(data);
      frag = $.base64Encode(RawDeflate.deflate(jd));
      if (window.history.replaceState) {
        return window.history.replaceState("loadout", "Latest settings", window.location.pathname.replace(/\/+$/, "") + "/#!/" + frag);
      } else {
        return window.location.hash = "!/" + frag;
      }
    };
    ShadowcraftHistory.prototype.reset = function() {
      if (confirm("This will wipe out any changes you've made. Proceed?")) {
        $.jStorage.deleteKey(uuid);
        return window.location.reload();
      }
    };
    ShadowcraftHistory.prototype.takeSnapshot = function() {
      return compress(deepCopy(this.app.Data));
    };
    ShadowcraftHistory.prototype.loadSnapshot = function(snapshot) {
      this.app.Data = decompress(snapshot);
      return Shadowcraft.loadData();
    };
    ShadowcraftHistory.prototype.buildExport = function() {
      var data, encoded_data;
      data = json_encode(compress(this.app.Data));
      encoded_data = $.base64Encode(lzw_encode(data));
      return $("#export").text(data);
    };
    base10 = "0123456789";
    base77 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    base36Encode = function(a) {
      var i, r, v, _len;
      r = [];
      for (i = 0, _len = a.length; i < _len; i++) {
        v = a[i];
        if (v === void 0 || v === null) {
          continue;
        } else if (v === 0) {
          r.push("");
        } else {
          r.push(convertBase(v.toString(), base10, base77));
        }
      }
      return r.join(";");
    };
    base36Decode = function(s) {
      var r, v, _i, _len, _ref;
      r = [];
      _ref = s.split(";");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        v = _ref[_i];
        if (v === "") {
          r.push(0);
        } else {
          r.push(parseInt(convertBase(v, base77, base10), 10));
        }
      }
      return r;
    };
    compress = function(data) {
      return compress_handlers[DATA_VERSION](data);
    };
    decompress = function(data) {
      var version;
      version = data[0].toString();
      if (decompress_handlers[version] == null) {
        throw "Data version mismatch";
      }
      return decompress_handlers[version](data);
    };
    professionMap = ["enchanting", "engineering", "blacksmithing", "inscription", "jewelcrafting", "leatherworking", "tailoring"];
    poisonMap = ["ip", "dp", "wp"];
    raceMap = ["Human", "Night Elf", "Worgen", "Dwarf", "Gnome", "Tauren", "Undead", "Orc", "Troll", "Blood Elf", "Goblin", "Draenei"];
    rotationOptionsMap = ["min_envenom_size_mutilate", "min_envenom_size_backstab", "prioritize_rupture_uptime_mutilate", "prioritize_rupture_uptime_backstab", "use_rupture", "ksp_immediately", "use_revealing_strike", "clip_recuperate"];
    rotationValueMap = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, true, false, 'true', 'false', 'never', 'always', 'sometimes'];
    map = function(value, m) {
      return m.indexOf(value);
    };
    unmap = function(value, m) {
      return m[value];
    };
    compress_handlers = {
      "1": function(data) {
        var buff, buffs, gear, gearSet, general, index, k, options, profession, professions, ret, rotationOptions, slot, v, val, _len, _ref, _ref2, _ref3;
        ret = [DATA_VERSION];
        gearSet = [];
        for (slot = 0; slot <= 17; slot++) {
          gear = data.gear[slot] || {};
          gearSet.push(gear.item_id || 0);
          gearSet.push(gear.enchant || 0);
          gearSet.push(gear.reforge || 0);
          gearSet.push(gear.g0 || 0);
          gearSet.push(gear.g1 || 0);
          gearSet.push(gear.g2 || 0);
        }
        ret.push(base36Encode(gearSet));
        ret.push(ShadowcraftTalents.encodeTalents(data.activeTalents));
        ret.push(base36Encode(data.glyphs));
        options = [];
        professions = [];
        _ref = data.options.professions;
        for (profession in _ref) {
          val = _ref[profession];
          if (val) {
            professions.push(map(profession, professionMap));
          }
        }
        options.push(professions);
        general = [data.options.general.level, map(data.options.general.race, raceMap), data.options.general.duration, map(data.options.general.mh_poison, poisonMap), map(data.options.general.oh_poison, poisonMap), data.options.general.potion_of_the_tolvir ? 1 : 0, data.options.general.max_ilvl];
        options.push(base36Encode(general));
        buffs = [];
        _ref2 = ShadowcraftOptions.buffMap;
        for (index = 0, _len = _ref2.length; index < _len; index++) {
          buff = _ref2[index];
          v = data.options.buffs[buff];
          buffs.push(v ? 1 : 0);
        }
        options.push(buffs);
        rotationOptions = [];
        _ref3 = data.options["rotation"];
        for (k in _ref3) {
          v = _ref3[k];
          rotationOptions.push(map(k, rotationOptionsMap));
          rotationOptions.push(map(v, rotationValueMap));
        }
        options.push(base36Encode(rotationOptions));
        ret.push(options);
        return ret;
      }
    };
    decompress_handlers = {
      "1": function(data) {
        var d, gear, general, i, id, index, k, options, rotation, slot, v, _len, _len2, _len3, _len4, _ref, _ref2, _ref3;
        d = {
          gear: {},
          activeTalents: ShadowcraftTalents.decodeTalents(data[2]),
          glyphs: base36Decode(data[3]),
          options: {},
          talents: [],
          active: data[6]
        };
        gear = base36Decode(data[1]);
        for (index = 0, _len = gear.length; index < _len; index += 6) {
          id = gear[index];
          slot = (index / 6).toString();
          d.gear[slot] = {
            item_id: gear[index],
            enchant: gear[index + 1],
            reforge: gear[index + 2],
            g0: gear[index + 3],
            g1: gear[index + 4],
            g2: gear[index + 5]
          };
          _ref = d.gear[slot];
          for (k in _ref) {
            v = _ref[k];
            if (v === 0) {
              delete d.gear[slot][k];
            }
          }
        }
        options = data[4];
        d.options.professions = {};
        _ref2 = options[0];
        for (i = 0, _len2 = _ref2.length; i < _len2; i++) {
          v = _ref2[i];
          d.options.professions[unmap(v, professionMap)] = true;
        }
        general = base36Decode(options[1]);
        d.options.general = {
          level: general[0],
          race: unmap(general[1], raceMap),
          duration: general[2],
          mh_poison: unmap(general[3], poisonMap),
          oh_poison: unmap(general[4], poisonMap),
          potion_of_the_tolvir: general[5] === 1,
          max_ilvl: general[6] || 500
        };
        d.options.buffs = {};
        _ref3 = options[2];
        for (i = 0, _len3 = _ref3.length; i < _len3; i++) {
          v = _ref3[i];
          d.options.buffs[ShadowcraftOptions.buffMap[i]] = v === 1;
        }
        rotation = base36Decode(options[3]);
        d.options.rotation = {};
        for (i = 0, _len4 = rotation.length; i < _len4; i += 2) {
          v = rotation[i];
          d.options.rotation[unmap(v, rotationOptionsMap)] = unmap(rotation[i + 1], rotationValueMap);
        }
        return d;
      }
    };
    return ShadowcraftHistory;
  })();
  titleize = function(str) {
    var f, i, r, s, sp, word, _len;
    if (!str) {
      return "";
    }
    sp = str.split(/[ _]/);
    word = [];
    for (i = 0, _len = sp.length; i < _len; i++) {
      s = sp[i];
      f = s.substring(0, 1).toUpperCase();
      r = s.substring(1).toLowerCase();
      word.push(f + r);
    }
    return word.join(' ');
  };
  tip = null;
  $doc = null;
  tooltip = function(data, x, y, ox, oy) {
    var rx, ry;
    tip = $("#tooltip");
    if (!tip || tip.length === 0) {
      tip = $("<div id='tooltip'></div>");
      $(document.body).append(tip);
      $doc = $(document.body);
    }
    tip.html(Templates.tooltip(data));
    tip.attr("class", data["class"]);
    x || (x = $.data(document, "mouse-x"));
    y || (y = $.data(document, "mouse-y"));
    rx = x + ox;
    ry = y + oy;
    if (rx + tip.outerWidth() > $doc.outerWidth()) {
      rx = x - tip.outerWidth() - ox;
    }
    if (ry + tip.outerHeight() > $doc.outerHeight()) {
      ry = y - tip.outerHeight() - oy;
    }
    return tip.css({
      top: ry,
      left: rx
    }).show();
  };
  hideFlash = function() {
    return $(".flash").fadeOut("fast");
  };
  flash = function(message) {
    var $flash, flashHide;
    $flash = $(".flash");
    if ($flash.length === 0) {
      $flash = $("<div class='flash'></div>");
      $flash.hide().click(function() {
        if (flashHide) {
          window.clearTimeout(flashHide);
        }
        return hideFlash();
      });
      $(document.body).append($flash);
    }
    $flash.html(message);
    if (!$flash.is(':visible')) {
      $(".flash").fadeIn(300);
    }
    if (flashHide) {
      window.clearTimeout(flashHide);
    }
    return flashHide = window.setTimeout(hideFlash, 20000);
  };
  checkForWarnings = function(section) {
    var EnchantLookup, EnchantSlots, ItemLookup, bestOptionalReforge, data, delta, enchant, enchantable, gear, item, rec, _results;
    Shadowcraft.Console.hide();
    data = Shadowcraft.Data;
    ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
    EnchantLookup = Shadowcraft.ServerData.ENCHANT_LOOKUP;
    EnchantSlots = Shadowcraft.ServerData.ENCHANT_SLOTS;
    if (section === void 0 || section === "glyphs") {
      Shadowcraft.Console.remove(".glyphs");
      if (data.glyphs.length < 3) {
        Shadowcraft.Console.warn({}, "Glyphs need to be selected", null, 'warn', 'glyphs');
      }
    }
    if (section === void 0 || section === "gear") {
      Shadowcraft.Console.remove(".items");
      _results = [];
      for (gear in data.gear) {
        if (!gear) {
          continue;
        }
        item = ItemLookup[gear.item_id];
        if (!item) {
          continue;
        }
        enchant = EnchantLookup[gear.enchant];
        enchantable = EnchantSlots[item.equip_location] !== void 0;
        if ((!data.options.professions.enchanting && item.equip_location === 11) || item.equip_location === "ranged") {
          enchantable = false;
        }
        if (canReforge(item)) {
          rec = recommendReforge(item.stats, gear.reforge ? gear.reforge.stats : null);
          delta = rec ? Math.round(rec[rec.source.key + "_to_" + rec.dest.key] * 100) / 100 : 0;
          if (delta > 0) {
            if (!gear.reforge) {
              Shadowcraft.Console.warn(item, "needs to be reforged", null, null, "items");
            } else {
              if (rec && (gear.reforge.from.stat !== rec.source.name || gear.reforge.to.stat !== rec.dest.name)) {
                if (!bestOptionalReforge || bestOptionalReforge < delta) {
                  bestOptionalReforge = delta;
                  Shadowcraft.Console.warn(item, "is not using an optimal reforge", "Using " + gear.reforge.from.stat + " &Rightarrow; " + gear.reforge.to.stat + ", recommend " + rec.source.name + " &Rightarrow; " + rec.dest.name + " (+" + delta + ")", "reforgeWarning", "items");
                }
              }
            }
          }
        }
        _results.push(!enchant && enchantable ? Shadowcraft.Console.warn(item, "needs an enchantment", null, null, "items") : void 0);
      }
      return _results;
    }
  };
  wait = function(msg) {
    $("#waitMsg").html(msg);
    return $("#wait").fadeIn();
  };
  showPopup = function(popup) {
    var $parent, body, ht, left, max, ot, speed, top;
    $(".popup").removeClass("visible");
    $parent = popup.parents(".ui-tabs-panel");
    max = $parent.scrollTop() + $parent.outerHeight();
    top = $.data(document, "mouse-y") - 40;
    if (top + popup.outerHeight() > max - 20) {
      top = max - 20 - popup.outerHeight();
    }
    if (top < 15) {
      top = 15;
    }
    left = $.data(document, "mouse-x") + 65;
    if (popup.width() + left > $parent.outerWidth() - 40) {
      left = popup.parents(".ui-tabs-panel").outerWidth() - popup.outerWidth() - 40;
    }
    popup.css({
      top: top + "px",
      left: left + "px"
    });
    popup.addClass("visible");
    ttlib.hide();
    body = popup.find(".body");
    if (!window.Touch) {
      $(".popup #filter input").focus();
    }
    ot = popup.find(".active").get(0);
    if (ot) {
      ht = ot.offsetTop - (popup.height() / 3);
      speed = ht / 1.3;
      if (speed > 500) {
        speed = 500;
      }
      return body.animate({
        scrollTop: ht
      }, speed, 'swing');
    }
  };
  ShadowcraftOptions = (function() {
    var cast, changeCheck, changeInput, changeOption, changeSelect, enforceBounds;
    ShadowcraftOptions.buffMap = ['short_term_haste_buff', 'stat_multiplier_buff', 'crit_chance_buff', 'all_damage_buff', 'melee_haste_buff', 'attack_power_buff', 'str_and_agi_buff', 'armor_debuff', 'physical_vulnerability_debuff', 'spell_damage_debuff', 'spell_crit_debuff', 'bleed_damage_debuff', 'agi_flask', 'guild_feast'];
    cast = function(val, dtype) {
      switch (dtype) {
        case "integer":
          val = parseInt(val, 10);
          if (isNaN(val)) {
            val = 0;
          }
          break;
        case "float":
          val = parseFloat(val, 10);
          if (isNaN(val)) {
            val = 0;
          }
          break;
        case "bool":
          val = val === true || val === "true" || val === 1;
      }
      return val;
    };
    enforceBounds = function(val, mn, mx) {
      if (typeof val === "number") {
        if (mn && val < mn) {
          val = mn;
        } else if (mx && val > mx) {
          val = mx;
        }
      } else {
        return val;
      }
      return val;
    };
    ShadowcraftOptions.prototype.setup = function(selector, namespace, checkData) {
      var data, e0, exist, inputType, key, ns, opt, options, s, template, templateOptions, val, _i, _k, _len, _ref, _ref2, _v;
      data = Shadowcraft.Data;
      s = $(selector);
      for (key in checkData) {
        opt = checkData[key];
        ns = data.options[namespace];
        val = null;
        if (!ns) {
          data.options[namespace] = {};
          ns = data.options[namespace];
        }
        if (data.options[namespace][key]) {
          val = data.options[namespace][key];
        }
        if (val === null && (opt["default"] != null)) {
          val = opt["default"];
        }
        val = cast(val, opt.datatype);
        val = enforceBounds(val, opt.min, opt.max);
        data.options[namespace][key] = val;
        exist = s.find("#opt-" + namespace + "-" + key);
        inputType = "check";
        if (typeof opt === "object" && (opt.type != null)) {
          inputType = opt.type;
        }
        if (exist.length === 0) {
          switch (inputType) {
            case "check":
              template = Templates.checkbox;
              options = {
                label: typeof opt === "string" ? opt : opt.name
              };
              break;
            case "select":
              template = Templates.select;
              templateOptions = [];
              if (opt.options instanceof Array) {
                _ref = opt.options;
                for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                  _v = _ref[_i];
                  templateOptions.push({
                    name: _v,
                    value: _v
                  });
                }
              } else {
                _ref2 = opt.options;
                for (_k in _ref2) {
                  _v = _ref2[_k];
                  templateOptions.push({
                    name: _v,
                    value: _k
                  });
                }
              }
              options = {
                options: templateOptions
              };
              break;
            case "input":
              template = Templates.input;
          }
          if (template) {
            s.append(template($.extend({
              key: key,
              label: opt.name,
              namespace: namespace,
              desc: opt.desc
            }, options)));
          }
          exist = s.find("#opt-" + namespace + "-" + key);
          e0 = exist.get(0);
          $.data(e0, "datatype", opt.datatype);
          $.data(e0, "min", opt.min);
          $.data(e0, "max", opt.max);
        }
        switch (inputType) {
          case "check":
            exist.attr("checked", val);
            break;
          case "select":
          case "input":
            exist.val(val);
        }
      }
      return null;
    };
    ShadowcraftOptions.prototype.initOptions = function() {
      var data;
      data = Shadowcraft.Data;
      this.setup("#settings #general", "general", {
        level: {
          type: "input",
          name: "Level",
          'default': 85,
          datatype: 'integer',
          min: 85,
          max: 85
        },
        race: {
          type: "select",
          options: ["Human", "Dwarf", "Orc", "Blood Elf", "Gnome", "Worgen", "Troll", "Night Elf", "Undead", "Goblin"],
          name: "Race",
          'default': "Human"
        },
        duration: {
          type: "input",
          name: "Fight Duration",
          'default': 360,
          datatype: 'integer',
          min: 15,
          max: 1200
        },
        mh_poison: {
          name: "Mainhand Poison",
          type: 'select',
          options: {
            'ip': "Instant Poison",
            'wp': 'Wound Poison',
            'dp': 'Deadly Poison'
          },
          'default': 'ip'
        },
        oh_poison: {
          name: "Offhand Poison",
          type: 'select',
          options: {
            'ip': "Instant Poison",
            'wp': 'Wound Poison',
            'dp': 'Deadly Poison'
          },
          'default': 'dp'
        },
        max_ilvl: {
          name: "Max ILevel",
          type: "input",
          desc: "Don't show items over this ilevel in gear lists",
          'default': 500,
          datatype: 'integer',
          min: 15,
          max: 500
        }
      });
      this.setup("#settings #professions", "professions", {
        blacksmithing: "Blacksmithing",
        enchanting: "Enchanting",
        engineering: "Engineering",
        inscription: "Inscription",
        jewelcrafting: "Jewelcrafting",
        leatherworking: "Leatherworking",
        tailoring: "Tailoring"
      });
      this.setup("#settings #playerBuffs", "buffs", {
        guild_feast: {
          name: "Food Buff",
          desc: "Seafood Magnifique Feast/Skewered Eel",
          'default': true,
          datatype: 'bool'
        },
        agi_flask: {
          name: "Agility Flask",
          desc: "Flask of the Wind/Flask of Battle",
          'default': true,
          datatype: 'bool'
        },
        short_term_haste_buff: {
          name: "+30% Haste/45 sec",
          desc: "Heroism/Bloodlust/Time Warp",
          'default': true,
          datatype: 'bool'
        },
        stat_multiplier_buff: {
          name: "5% All Stats",
          desc: "Blessing of Kings/Mark of the Wild",
          'default': true,
          datatype: 'bool'
        },
        crit_chance_buff: {
          name: "5% Crit",
          desc: "Honor Among Thieves/Leader of the Pack/Rampage/Elemental Oath",
          'default': true,
          datatype: 'bool'
        },
        all_damage_buff: {
          name: "3% All Damage",
          desc: "Arcane Tactics/Ferocious Inspiration/Communion",
          'default': true,
          datatype: 'bool'
        },
        melee_haste_buff: {
          name: "10% Haste",
          desc: "Hunting Party/Windfury Totem/Icy Talons",
          'default': true,
          datatype: 'bool'
        },
        attack_power_buff: {
          name: "10% Attack Power",
          desc: "Abomination's Might/Blessing of Might/Trueshot Aura/Unleashed Rage",
          'default': true,
          datatype: 'bool'
        },
        str_and_agi_buff: {
          name: "Agility",
          desc: "Strength of Earth/Battle Shout/Horn of Winter/Roar of Courage",
          'default': true,
          datatype: 'bool'
        }
      });
      this.setup("#settings #targetDebuffs", "buffs", {
        armor_debuff: {
          name: "-12% Armor",
          desc: "Sunder Armor/Faerie Fire/Expose Armor",
          'default': true,
          datatype: 'bool'
        },
        physical_vulnerability_debuff: {
          name: "+4% Physical Damage",
          desc: "Savage Combat/Trauma/Brittle Bones",
          'default': true,
          datatype: 'bool'
        },
        spell_damage_debuff: {
          name: "+8% Spell Damage",
          desc: "Curse of the Elements/Earth and Moon/Master Poisoner/Ebon Plaguebringer",
          'default': true,
          datatype: 'bool'
        },
        spell_crit_debuff: {
          name: "+5% Spell Crit",
          desc: "Critical Mass/Shadow and Flame",
          'default': true,
          datatype: 'bool'
        },
        bleed_damage_debuff: {
          name: "+30% Bleed Damage",
          desc: "Blood Frenzy/Mangle/Hemorrhage",
          'default': true,
          datatype: 'bool'
        }
      });
      this.setup("#settings #raidOther", "general", {
        potion_of_the_tolvir: {
          name: "Use Potion of the Tol'vir",
          'default': true,
          datatype: 'bool'
        }
      });
      this.setup("#settings section.mutilate .settings", "rotation", {
        min_envenom_size_mutilate: {
          type: "select",
          name: "Min CP/Envenom > 35%",
          options: [5, 4, 3, 2, 1],
          'default': 4,
          desc: "Use Envenom at this many combo points, when your primary CP builder is Mutilate",
          datatype: 'integer',
          min: 1,
          max: 5
        },
        min_envenom_size_backstab: {
          type: "select",
          name: "Min CP/Envenom < 35%",
          options: [5, 4, 3, 2, 1],
          'default': 5,
          desc: "Use Envenom at this many combo points, when your primary CP builder is Backstab",
          datatype: 'integer',
          min: 1,
          max: 5
        }
      });
      this.setup("#settings section.combat .settings", "rotation", {
        use_rupture: {
          name: "Use Rupture?",
          right: true,
          "default": true
        },
        ksp_immediately: {
          type: "select",
          name: "Killing Spree",
          options: {
            'true': "Killing Spree on cooldown",
            'false': "Wait for Bandit's Guile before using Killing Spree"
          },
          'default': 'false',
          datatype: 'bool'
        },
        use_revealing_strike: {
          type: "select",
          name: "Revealing Strike",
          options: {
            "always": "Use for every finisher",
            "sometimes": "Only use at 4CP",
            "never": "Never use"
          },
          'default': "sometimes",
          datatype: 'string'
        }
      });
      return this.setup("#settings section.subtlety .settings", "rotation", {
        clip_recuperate: "Clip Recuperate?"
      });
    };
    changeOption = function(elem, val) {
      var $this, data, dtype, max, min, name, ns, t0, _base;
      $this = $(elem);
      data = Shadowcraft.Data;
      ns = elem.attr("data-ns") || "root";
      (_base = data.options)[ns] || (_base[ns] = {});
      name = $this.attr("name");
      if (val === void 0) {
        val = $this.val();
      }
      t0 = $this.get(0);
      dtype = $.data(t0, "datatype");
      min = $.data(t0, "min");
      max = $.data(t0, "max");
      val = enforceBounds(cast(val, dtype), min, max);
      if ($this.val() !== val) {
        $this.val(val);
      }
      data.options[ns][name] = val;
      return Shadowcraft.update();
    };
    changeCheck = function() {
      var $this;
      $this = $(this);
      changeOption($this, $this.is(":checked"));
      return Shadowcraft.setupLabels("#settings");
    };
    changeSelect = function() {
      return changeOption(this);
    };
    changeInput = function() {
      return changeOption(this);
    };
    ShadowcraftOptions.prototype.boot = function() {
      var app;
      app = this;
      this.initOptions();
      Shadowcraft.bind("loadData", function() {
        app.initOptions();
        Shadowcraft.setupLabels("#settings");
        return $("#settings select").change();
      });
      Shadowcraft.Talents.bind("changed", function() {
        $("#settings section.mutilate, #settings section.combat, #settings section.subtlety").hide();
        if (Shadowcraft.Data.tree0 >= 31) {
          return $("#settings section.mutilate").show();
        } else if (Shadowcraft.Data.tree1 >= 31) {
          return $("#settings section.combat").show();
        } else {
          return $("#settings section.subtlety").show();
        }
      });
      return this;
    };
    function ShadowcraftOptions() {
      $("#settings").bind("change", $.delegate({
        ".optionCheck": changeCheck
      }));
      $("#settings").bind("change", $.delegate({
        ".optionSelect": changeSelect
      }));
      $("#settings").bind("change", $.delegate({
        ".optionInput": changeInput
      }));
    }
    return ShadowcraftOptions;
  })();
  ShadowcraftTalents = (function() {
    var DEFAULT_SPECS, MAX_TALENT_POINTS, TREE_SIZE, applyTalentToButton, getSpecFromString, getTalents, glyphRankCount, hoverTalent, resetTalents, setTalents, sumDigits, talentMap, talentsSpent, toggleGlyph, updateGlyphWeights, updateTalentAvailability, updateTalentContribution;
    talentsSpent = 0;
    MAX_TALENT_POINTS = 41;
    TREE_SIZE = [19, 19, 19];
    DEFAULT_SPECS = {
      "Stock Assassination": "033323011302211032100200000000000000002030030000000000000",
      "Stock Combat": "023200000000000000023322303100300123210030000000000000000",
      "Stock Subtlety": "023003000000000000000200000000000000000332031321310012321"
    };
    ShadowcraftTalents.GetPrimaryTreeName = function() {
      if (Shadowcraft.Data.tree0 >= 31) {
        return "Mutilate";
      } else if (Shadowcraft.Data.tree1 >= 31) {
        return "Combat";
      } else {
        return "Subtlety";
      }
    };
    talentMap = "0zMcmVokRsaqbdrfwihuGINALpTjnyxtgevElBCDFHJKOPQSUWXYZ123456789";
    ShadowcraftTalents.encodeTalents = function(s) {
      var c, i, index, l, offset, size, str, sub, _len, _len2;
      str = "";
      offset = 0;
      for (index = 0, _len = TREE_SIZE.length; index < _len; index++) {
        size = TREE_SIZE[index];
        sub = s.substr(offset, size).replace(/0+$/, "");
        offset += size;
        for (i = 0, _len2 = sub.length; i < _len2; i += 2) {
          c = sub[i];
          l = parseInt(c, 10) * 5 + parseInt(sub[i + 1] || 0, 10);
          str += talentMap[l];
        }
        if (index !== TREE_SIZE.length - 1) {
          str += "Z";
        }
      }
      return str;
    };
    ShadowcraftTalents.decodeTalents = function(s) {
      var a, b, character, i, idx, index, talents, tree, trees, treestr, _len, _ref;
      trees = s.split("Z");
      talents = "";
      for (index = 0, _len = trees.length; index < _len; index++) {
        tree = trees[index];
        treestr = "";
        for (i = 0, _ref = Math.floor(TREE_SIZE[index] / 2); (0 <= _ref ? i <= _ref : i >= _ref); (0 <= _ref ? i += 1 : i -= 1)) {
          character = tree[i];
          if (character) {
            idx = talentMap.indexOf(character);
            a = Math.floor(idx / 5);
            b = idx % 5;
          } else {
            a = "0";
            b = "0";
          }
          treestr += a;
          if (treestr.length < TREE_SIZE[index]) {
            treestr += b;
          }
        }
        talents += treestr;
      }
      return talents;
    };
    sumDigits = function(s) {
      var c, total, _i, _len;
      total = 0;
      for (_i = 0, _len = s.length; _i < _len; _i++) {
        c = s[_i];
        total += parseInt(c);
      }
      return total;
    };
    getSpecFromString = function(s) {
      if (sumDigits(s.substr(0, TREE_SIZE[0])) >= 31) {
        return "Assassination";
      } else if (sumDigits(s.substr(TREE_SIZE[0], TREE_SIZE[1])) >= 31) {
        return "Combat";
      } else {
        return "Subtlety";
      }
    };
    updateTalentAvailability = function(selector) {
      var talents;
      talents = selector ? selector.find(".talent") : $("#talentframe .tree .talent");
      talents.each(function() {
        var $this, icons, pos, tree;
        $this = $(this);
        pos = $.data(this, "position");
        tree = $.data(pos.tree, "info");
        icons = $.data(this, "icons");
        if (tree.points < pos.row * 5) {
          return $this.css({
            backgroundImage: icons.grey
          }).removeClass("active");
        } else {
          return $this.css({
            backgroundImage: icons.normal
          }).addClass("active");
        }
      });
      Shadowcraft.Talents.trigger("changed");
      return Shadowcraft.update();
    };
    hoverTalent = function() {
      var nextRank, points, pos, rank, talent;
      if (window.Touch != null) {
        return;
      }
      points = $.data(this, "points");
      talent = $.data(this, "talent");
      rank = talent.rank.length ? talent.rank[points.cur - 1] : talent.rank;
      nextRank = talent.rank.length ? talent.rank[points.cur] : null;
      pos = $(this).offset();
      return tooltip({
        title: talent.name + " (" + points.cur + "/" + points.max + ")",
        desc: rank ? rank.description : null,
        nextdesc: nextRank ? "Next rank: " + nextRank.description : null
      }, pos.left, pos.top, 130, -20);
    };
    resetTalents = function() {
      $("#talentframe .talent").each(function() {
        var points;
        points = $.data(this, "points");
        return applyTalentToButton(this, -points.cur, true, true);
      });
      data.activeTalents = getTalents();
      return updateTalentAvailability();
    };
    setTalents = function(str) {
      var ct, data;
      data = Shadowcraft.Data;
      if (!str) {
        updateTalentAvailability(null);
        return;
      }
      ct = 0;
      $("#talentframe .talent").each(function() {
        var points;
        points = $.data(this, "points");
        applyTalentToButton(this, parseInt(str[ct], 10) - points.cur, true, true);
        return ct++;
      });
      data.activeTalents = getTalents();
      return updateTalentAvailability(null);
    };
    getTalents = function() {
      return _.map($("#talentframe .talent"), function(t) {
        return $.data(t, "points").cur || 0;
      }).join("");
    };
    applyTalentToButton = function(button, dir, force, skipUpdate) {
      var $points, data, points, position, prequal, prev, success, tier, tree, _ref;
      data = Shadowcraft.Data;
      points = $.data(button, "points");
      position = $.data(button, "position");
      tree = $.data(position.tree, "info");
      success = false;
      if (force) {
        success = true;
      } else if (dir === 1 && points.cur < points.max && talentsSpent < MAX_TALENT_POINTS) {
        success = true;
      } else if (dir === -1) {
        for (tier = _ref = position.row; (_ref <= 7 ? tier <= 7 : tier >= 7); (_ref <= 7 ? tier += 1 : tier -= 1)) {
          prequal = 0;
          for (prev = 0; (0 <= tier ? prev <= tier : prev >= tier); (0 <= tier ? prev += 1 : prev -= 1)) {
            prequal += tree.rowPoints[prev];
          }
          if (tree.rowPoints[tier] > 0 && (tier * 5) >= prequal) {
            return false;
          }
        }
        if (points.cur > 0) {
          success = true;
        }
      }
      if (success) {
        points.cur += dir;
        tree.points += dir;
        talentsSpent += dir;
        tree.rowPoints[position.row] += dir;
        Shadowcraft.Data["tree" + position.treeIndex] = tree.points;
        $.data(button, "spentButton").text(tree.points);
        $points = $.data(button, "pointsButton");
        $points.get(0).className = "points";
        if (points.cur === points.max) {
          $points.addClass("full");
        } else if (points.cur > 0) {
          $points.addClass("partial");
        }
        $points.text(points.cur + "/" + points.max);
        if (!skipUpdate) {
          updateTalentAvailability($(button).parent());
          data.activeTalents = getTalents();
        }
      }
      return success;
    };
    ShadowcraftTalents.prototype.updateActiveTalents = function() {
      var data;
      data = this.app.Data;
      if (!data.activeTalents) {
        data.activeTalents = data.talents[data.active].talents;
      }
      return setTalents(data.activeTalents);
    };
    ShadowcraftTalents.prototype.initTalentsPane = function() {
      var TalentLookup, Talents, buffer, data, initTalentsPane, talent, talentName, talentTrees, talentframe, tframe, tree, treeIndex, _i, _len, _ref;
      Talents = Shadowcraft.ServerData.TALENTS;
      TalentLookup = Shadowcraft.ServerData.TALENT_LOOKUP;
      data = Shadowcraft.Data;
      buffer = "";
      for (treeIndex in Talents) {
        tree = Talents[treeIndex];
        buffer += Templates.talentTree({
          background: tree.bgImage,
          talents: tree.talent
        });
      }
      talentframe = $("#talentframe");
      tframe = talentframe.get(0);
      tframe.innerHTML = buffer;
      $(".tree, .tree .talent, .tree .talent .points").disableTextSelection();
      talentTrees = $("#talentframe .tree");
      $("#talentframe .talent").each(function() {
        var $this, col, myTree, row, talent, trees;
        row = parseInt(this.className.match(/row-(\d)/)[1], 10);
        col = parseInt(this.className.match(/col-(\d)/)[1], 10);
        $this = $(this);
        trees = $this.closest(".tree");
        myTree = trees.get(0);
        tree = talentTrees.index(myTree);
        talent = TalentLookup[tree + ":" + row + ":" + col];
        $.data(this, "position", {
          tree: myTree,
          treeIndex: tree,
          row: row,
          col: col
        });
        $.data(myTree, "info", {
          points: 0,
          rowPoints: [0, 0, 0, 0, 0, 0, 0]
        });
        $.data(this, "talent", talent);
        $.data(this, "points", {
          cur: 0,
          max: talent.maxRank
        });
        $.data(this, "pointsButton", $this.find(".points"));
        $.data(this, "spentButton", trees.find(".spent"));
        return $.data(this, "icons", {
          grey: $this.css("backgroundImage"),
          normal: $this.css("backgroundImage").replace(/\/grey\//, "/")
        });
      }).mousedown(function(e) {
        if (!$(this).hasClass("active")) {
          return;
        }
        if (window.Touch != null) {
          return;
        }
        switch (e.button) {
          case 0:
            if (applyTalentToButton(this, 1)) {
              Shadowcraft.update();
            }
            break;
          case 2:
            if (applyTalentToButton(this, -1)) {
              Shadowcraft.update();
            }
        }
        return $(this).trigger("mouseenter");
      }).bind("contextmenu", function() {
        return false;
      }).mouseenter(hoverTalent).mouseleave(function() {
        return $("#tooltip").hide();
      }).bind("touchstart", function(e) {
        $.data(this, "removed", false);
        $.data(this, "listening", true);
        return $.data(tframe, "listening", this);
      }).bind("touchend", function(e) {
        $.data(this, "listening", false);
        if (!($.data(this, "removed") || !$(this).hasClass("active"))) {
          if (applyTalentToButton(this, 1)) {
            return Shadowcraft.update();
          }
        }
      });
      talentframe.bind("touchstart", function(e) {
        var listening;
        listening = $.data(tframe, "listening");
        if (e.originalEvent.touches.length > 1 && listening && $.data(listening, "listening")) {
          if (applyTalentToButton.call(listening, listening, -1)) {
            Shadowcraft.update();
          }
          return $.data(listening, "removed", true);
        }
      });
      buffer = "";
      _ref = data.talents;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        talent = _ref[_i];
        buffer += Templates.talentSet({
          talent_string: ShadowcraftTalents.encodeTalents(talent.talents),
          glyphs: talent.glyphs.join(","),
          name: "Imported " + getSpecFromString(talent.talents)
        });
      }
      for (talentName in DEFAULT_SPECS) {
        talent = DEFAULT_SPECS[talentName];
        buffer += Templates.talentSet({
          talent_string: ShadowcraftTalents.encodeTalents(talent),
          name: talentName
        });
      }
      $("#talentsets").get(0).innerHTML = buffer;
      this.updateActiveTalents();
      return initTalentsPane = function() {};
    };
    ShadowcraftTalents.prototype.setGlyphs = function(glyphs) {
      Shadowcraft.Data.glyphs = glyphs;
      return this.initGlyphs();
    };
    ShadowcraftTalents.prototype.initGlyphs = function() {
      var Glyphs, buffer, data, g, glyph, i, idx, _len, _len2, _ref, _results;
      buffer = [null, "", "", ""];
      Glyphs = Shadowcraft.ServerData.GLYPHS;
      data = Shadowcraft.Data;
      if (!data.glyphs) {
        data.glyphs = data.talents[data.active].glyphs;
      }
      for (idx = 0, _len = Glyphs.length; idx < _len; idx++) {
        g = Glyphs[idx];
        buffer[g.rank] += Templates.glyphSlot(g);
      }
      $("#prime-glyphs .inner").get(0).innerHTML = buffer[3];
      $("#major-glyphs .inner").get(0).innerHTML = buffer[2];
      if (data.glyphs == null) {
        return;
      }
      _ref = data.glyphs;
      _results = [];
      for (i = 0, _len2 = _ref.length; i < _len2; i++) {
        glyph = _ref[i];
        g = $(".glyph_slot[data-id='" + glyph + "']");
        _results.push(g.length > 0 ? toggleGlyph(g, true) : void 0);
      }
      return _results;
    };
    updateGlyphWeights = function(data) {
      var g, glyphSet, glyphSets, key, max, slot, weight, width, _i, _len, _ref, _results;
      max = _.max(data.glyph_ranking);
      $(".glyph_slot:not(.activated)").hide();
      $(".glyph_slot .pct-inner").css({
        width: 0
      });
      _ref = data.glyph_ranking;
      for (key in _ref) {
        weight = _ref[key];
        g = Shadowcraft.ServerData.GLYPHNAME_LOOKUP[key];
        if (g) {
          width = weight / max * 100;
          slot = $(".glyph_slot[data-id='" + g.id + "']");
          $.data(slot[0], "weight", weight);
          $.data(slot[0], "name", g.name);
          slot.show().find(".pct-inner").css({
            width: width + "%"
          });
          slot.find(".label").text(weight.toFixed(1) + " DPS");
        }
      }
      glyphSets = $(".glyphset");
      _results = [];
      for (_i = 0, _len = glyphSets.length; _i < _len; _i++) {
        glyphSet = glyphSets[_i];
        _results.push($(glyphSet).find(".glyph_slot").sortElements(function(a, b) {
          var an, aw, bn, bw;
          aw = $.data(a, "weight");
          bw = $.data(b, "weight");
          an = $.data(a, "name");
          bn = $.data(b, "name");
          aw || (aw = -1);
          bw || (bw = -1);
          an || (an = "");
          bn || (bn = "");
          if (aw !== bw) {
            if (aw > bw) {
              return -1;
            } else {
              return 1;
            }
          } else {
            if (an > bn) {
              return 1;
            } else {
              return -1;
            }
          }
        }));
      }
      return _results;
    };
    glyphRankCount = function(rank, g) {
      var GlyphLookup, count, data, glyph, _i, _len, _ref;
      data = Shadowcraft.Data;
      GlyphLookup = Shadowcraft.ServerData.GLYPH_LOOKUP;
      if (g && !rank) {
        rank = GlyphLookup[g].rank;
      }
      count = 0;
      _ref = data.glyphs;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        glyph = _ref[_i];
        if (GlyphLookup[glyph] != null) {
          if (GlyphLookup[glyph].rank === rank) {
            count++;
          }
        }
      }
      return count;
    };
    toggleGlyph = function(e, override) {
      var $e, $set, GlyphLookup, data, glyph, id;
      GlyphLookup = Shadowcraft.ServerData.GLYPH_LOOKUP;
      data = Shadowcraft.Data;
      $e = $(e);
      $set = $e.parents(".glyphset");
      id = parseInt($e.data("id"), 10);
      glyph = GlyphLookup[id];
      if ($e.hasClass("activated")) {
        $e.removeClass("activated");
        data.glyphs = _.without(data.glyphs, id);
        $set.removeClass("full");
      } else {
        if (glyphRankCount(null, id) >= 3 && !override) {
          return;
        }
        $e.addClass("activated");
        if (!override && data.glyphs.indexOf(id) === -1) {
          data.glyphs.push(id);
        }
        if (glyphRankCount(null, id) >= 3) {
          $set.addClass("full");
        }
      }
      checkForWarnings('glyphs');
      return Shadowcraft.update();
    };
    updateTalentContribution = function(LC) {
      var buffer, exist, k, max, name, pct, rankings, s, setKey, setVal, sets, target, val;
      if (!LC.talent_ranking_main) {
        return;
      }
      sets = {
        "Primary": LC.talent_ranking_main,
        "Secondary": LC.talent_ranking_off
      };
      rankings = _.extend({}, LC.talent_ranking_main, LC.talent_ranking_off);
      max = _.max(rankings);
      $("#talentrankings .talent_contribution").hide();
      for (setKey in sets) {
        setVal = sets[setKey];
        buffer = "";
        target = $("#talentrankings ." + setKey);
        for (k in setVal) {
          s = setVal[k];
          exist = $("#talentrankings #talent-weight-" + k);
          val = parseInt(s, 10);
          if (isNaN(val)) {
            name += " (NYI)";
            val = 0;
          }
          pct = val / max * 100 + 0.01;
          if (exist.length === 0) {
            name = k.replace(/_/g, " ").capitalize();
            buffer = Templates.talentContribution({
              name: name,
              raw_name: k,
              val: val.toFixed(1),
              width: pct
            });
            target.append(buffer);
          }
          exist = $("#talentrankings #talent-weight-" + k);
          $.data(exist.get(0), "val", val);
          exist.show().find(".pct-inner").css({
            width: pct + "%"
          });
        }
      }
      return $("#talentrankings .talent_contribution").sortElements(function(a, b) {
        var ad, bd;
        ad = $.data(a, "val");
        bd = $.data(b, "val");
        if (ad > bd) {
          return -1;
        } else {
          return 1;
        }
      });
    };
    ShadowcraftTalents.prototype.boot = function() {
      var app;
      this.initTalentsPane();
      this.initGlyphs();
      app = this;
      Shadowcraft.Backend.bind("recompute", updateTalentContribution);
      Shadowcraft.Backend.bind("recompute", updateGlyphWeights);
      $("#glyphs").click($.delegate({
        ".glyph_slot": function() {
          return toggleGlyph(this);
        }
      })).mouseover($.delegate({
        ".glyph_slot": ttlib.requestTooltip
      })).mouseout($.delegate({
        ".glyph_slot": ttlib.hide
      }));
      $("#talentsets").click($.delegate({
        ".talent_set": function() {
          var glyph, glyphs, i, talents, _len;
          talents = ShadowcraftTalents.decodeTalents($(this).data("talents"));
          glyphs = ($(this).data("glyphs") || "").split(",");
          for (i = 0, _len = glyphs.length; i < _len; i++) {
            glyph = glyphs[i];
            glyphs[i] = parseInt(glyph, 10);
          }
          glyphs = _.compact(glyphs);
          setTalents(talents);
          return app.setGlyphs(glyphs);
        }
      }));
      $("#reset_talents").click(resetTalents);
      Shadowcraft.bind("loadData", function() {
        app.updateActiveTalents();
        return app.initGlyphs();
      });
      $("#talents #talentframe").mousemove(function(e) {
        $.data(document, "mouse-x", e.pageX);
        return $.data(document, "mouse-y", e.pageY);
      });
      return this;
    };
    function ShadowcraftTalents(app) {
      this.app = app;
      this.app.Talents = this;
      this.resetTalents = resetTalents;
      this.setTalents = setTalents;
      this.getTalents = getTalents;
      _.extend(this, Backbone.Events);
    }
    return ShadowcraftTalents;
  })();
  ShadowcraftGear = (function() {
    var $altslots, $popup, $slots, DEFAULT_BOSS_DODGE, EP_PRE_REFORGE, EP_PRE_REGEM, EP_TOTAL, JC_ONLY_GEMS, MAX_ENGINEERING_GEMS, MAX_JEWELCRAFTING_GEMS, MH_EXPERTISE_FACTOR, OH_EXPERTISE_FACTOR, PROC_ENCHANTS, REFORGABLE, REFORGE_CONST, REFORGE_FACTOR, REFORGE_STATS, SLOT_DISPLAY_ORDER, SLOT_INVTYPES, SLOT_ORDER, Weights, addTradeskillBonuses, canReforge, canUseGem, clearReforge, clickSlot, clickSlotEnchant, clickSlotGem, clickSlotName, clickSlotReforge, colorSpan, compactReforge, epSort, getEquippedGemCount, getGemRecommendationList, getGemmingRecommendation, getHitEP, getProfessionalGemCount, getReforgeFrom, getReforgeTo, getRegularGemEpValue, getStatWeight, get_ep, greenWhite, isProfessionalGem, needsDagger, pctColor, racialExpertiseBonus, racialHitBonus, recommendReforge, redGreen, redWhite, reforgeAmount, reforgeEp, sourceStats, startReforges, statsToDesc, sumItem, sumRecommendation, sumReforge, updateStatWeights, whiteWhite, __epSort;
    MAX_JEWELCRAFTING_GEMS = 3;
    MAX_ENGINEERING_GEMS = 1;
    JC_ONLY_GEMS = ["Dragon's Eye", "Chimera's Eye"];
    REFORGE_FACTOR = 0.4;
    DEFAULT_BOSS_DODGE = 6.5;
    MH_EXPERTISE_FACTOR = 0.63;
    OH_EXPERTISE_FACTOR = 1 - MH_EXPERTISE_FACTOR;
    REFORGE_STATS = [
      {
        key: "expertise_rating",
        val: "Expertise"
      }, {
        key: "hit_rating",
        val: "Hit"
      }, {
        key: "haste_rating",
        val: "Haste"
      }, {
        key: "crit_rating",
        val: "Crit"
      }, {
        key: "mastery_rating",
        val: "Mastery"
      }
    ];
    REFORGABLE = ["spirit", "dodge_rating", "parry_rating", "hit_rating", "crit_rating", "haste_rating", "expertise_rating", "mastery_rating"];
    ShadowcraftGear.REFORGABLE = REFORGABLE;
    REFORGE_CONST = 112;
    SLOT_ORDER = ["0", "1", "2", "14", "4", "8", "9", "5", "6", "7", "10", "11", "12", "13", "15", "16", "17"];
    SLOT_DISPLAY_ORDER = [["0", "1", "2", "14", "4", "8", "15", "16"], ["9", "5", "6", "7", "10", "11", "12", "13", "17"]];
    PROC_ENCHANTS = {
      4099: "landslide",
      4083: "hurricane"
    };
    ShadowcraftGear.CHAOTIC_METAGEMS = [52291, 34220, 41285, 68778, 68780, 41398, 32409, 68779];
    Weights = {
      attack_power: 1,
      agility: 2.66,
      crit_rating: 0.87,
      spell_hit: 1.3,
      hit_rating: 1.02,
      expertise_rating: 1.51,
      haste_rating: 1.44,
      mastery_rating: 1.15,
      yellow_hit: 1.79,
      strength: 1.05
    };
    ShadowcraftGear.prototype.getWeights = function() {
      return Weights;
    };
    SLOT_INVTYPES = {
      0: 1,
      1: 2,
      2: 3,
      14: 16,
      4: 5,
      8: 9,
      9: 10,
      5: 6,
      6: 7,
      7: 8,
      10: 11,
      11: 11,
      12: 12,
      13: 12,
      15: "mainhand",
      16: "offhand",
      17: "ranged"
    };
    EP_PRE_REGEM = null;
    EP_PRE_REFORGE = null;
    EP_TOTAL = null;
    $slots = null;
    $altslots = null;
    $popup = null;
    reforgeAmount = function(item, stat) {
      return Math.floor(item.stats[stat] * REFORGE_FACTOR);
    };
    getReforgeFrom = function(n) {
      var base, from;
      base = n - REFORGE_CONST - 1;
      from = Math.floor(base / 7);
      return REFORGABLE[from];
    };
    getReforgeTo = function(n) {
      var base, from, to;
      base = n - REFORGE_CONST - 1;
      from = Math.floor(base / 7);
      to = base % 7;
      if (from <= to) {
        to++;
      }
      return REFORGABLE[to];
    };
    compactReforge = function(from, to) {
      var f, t;
      f = REFORGABLE.indexOf(from);
      t = REFORGABLE.indexOf(to);
      if (t < f) {
        t++;
      }
      return REFORGE_CONST + (f * 7) + t;
    };
    sumItem = function(s, i, key) {
      var stat;
      key || (key = "stats");
      for (stat in i[key]) {
        s[stat] || (s[stat] = 0);
        s[stat] += i[key][stat];
      }
      return null;
    };
    sumRecommendation = function(s, rec) {
      var _name, _name2;
      s[_name = rec.source.key] || (s[_name] = 0);
      s[rec.source.key] += rec.qty;
      s[_name2 = rec.dest.key] || (s[_name2] = 0);
      return s[rec.dest.key] += rec.qty;
    };
    get_ep = function(item, key, slot) {
      var c, data, enchant, pre, stat, stats, total, value, weight, weights;
      data = Shadowcraft.Data;
      weights = Weights;
      stats = {};
      if (item.source && item.dest) {
        sumRecommendation(stats, item);
      } else {
        sumItem(stats, item, key);
      }
      total = 0;
      for (stat in stats) {
        value = stats[stat];
        weight = Weights[stat] || 0;
        total += value * weight;
      }
      delete stats;
      c = Shadowcraft.lastCalculation;
      if (c) {
        if (item.dps) {
          if (slot === 15) {
            total += (item.dps * c.mh_ep.mh_dps) + (item.speed * c.mh_speed_ep["mh_" + item.speed]);
            total += racialExpertiseBonus(item) * Weights.expertise_rating;
          } else if (slot === 16) {
            total += (item.dps * c.oh_ep.oh_dps) + (item.speed * c.oh_speed_ep["oh_" + item.speed]);
            total += racialExpertiseBonus(item) * Weights.expertise_rating;
          }
        } else if (ShadowcraftGear.CHAOTIC_METAGEMS.indexOf(item.id) >= 0) {
          total += c.meta.chaotic_metagem;
        } else if (PROC_ENCHANTS[item.id]) {
          switch (slot) {
            case 15:
              pre = "mh_";
              break;
            case 16:
              pre = "oh_";
          }
          enchant = PROC_ENCHANTS[item.id];
          if (pre && enchant) {
            total += c[pre + "ep"][pre + enchant];
          }
        } else if (c.trinket_ranking[item.id]) {
          total += c.trinket_ranking[item.id];
        }
      }
      return total;
    };
    sumReforge = function(stats, item, reforge) {
      var amt, from, to;
      from = getReforgeFrom(reforge);
      to = getReforgeTo(reforge);
      amt = reforgeAmount(item, from);
      stats[from] || (stats[from] = 0);
      stats[from] -= amt;
      stats[to] || (stats[to] = 0);
      return stats[to] += amt;
    };
    ShadowcraftGear.prototype.sumStats = function(excludeReforges) {
      var EnchantLookup, Gems, ItemLookup, data, enchant, enchant_id, gear, gem, gid, i, item, matchesAllSockets, si, socket, socketIndex, stats, _len, _ref;
      stats = {};
      ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
      Gems = Shadowcraft.ServerData.GEM_LOOKUP;
      EnchantLookup = Shadowcraft.ServerData.ENCHANT_LOOKUP;
      data = Shadowcraft.Data;
      for (i = 0, _len = SLOT_ORDER.length; i < _len; i++) {
        si = SLOT_ORDER[i];
        gear = data.gear[si];
        if (!(gear && gear.item_id)) {
          continue;
        }
        item = ItemLookup[gear.item_id];
        if (item) {
          sumItem(stats, item);
          matchesAllSockets = item.sockets && item.sockets.length > 0;
          _ref = item.sockets;
          for (socketIndex in _ref) {
            socket = _ref[socketIndex];
            gid = gear["g" + socketIndex];
            if (gid && gid > 0) {
              gem = Gems[gid];
              if (gem) {
                sumItem(stats, gem);
              }
            }
            if (!gem || !gem[socket]) {
              matchesAllSockets = false;
            }
          }
          if (matchesAllSockets) {
            sumItem(stats, item, "socketbonus");
          }
          if (gear.reforge && !excludeReforges) {
            sumReforge(stats, item, gear.reforge);
          }
          enchant_id = gear.enchant;
          if (enchant_id && enchant_id > 0) {
            enchant = EnchantLookup[enchant_id];
            if (enchant) {
              sumItem(stats, enchant);
            }
          }
        }
      }
      this.statSum = stats;
      return stats;
    };
    racialExpertiseBonus = function(item, mh_type) {
      var m, n, race, t, _i, _len;
      if (!((item != null) || (mh_type != null))) {
        return 0;
      }
      if (item != null) {
        mh_type = item.subclass;
      }
      if (mh_type instanceof Array) {
        m = 0;
        for (_i = 0, _len = mh_type.length; _i < _len; _i++) {
          t = mh_type[_i];
          n = racialExpertiseBonus(null, t);
          m = n > m ? n : m;
        }
        return m;
      }
      race = Shadowcraft.Data.options.general.race;
      if (race === "Human" && (mh_type === 7 || mh_type === 4)) {
        return Shadowcraft._R("expertise_rating") * 3;
      } else if (race === "Gnome" && (mh_type === 7 || mh_type === 15)) {
        return Shadowcraft._R("expertise_rating") * 3;
      } else if (race === "Dwarf" && (mh_type === 4)) {
        return Shadowcraft._R("expertise_rating") * 3;
      } else if (race === "Orc" && (mh_type === 0 || mh_type === 13)) {
        return Shadowcraft._R("expertise_rating") * 3;
      } else {
        return 0;
      }
    };
    racialHitBonus = function(key) {
      if (Shadowcraft.Data.race === "Draenei") {
        return Shadowcraft._R(key);
      } else {
        return 0;
      }
    };
    ShadowcraftGear.prototype.getStat = function(stat) {
      if (!this.statSum) {
        this.sumStats();
      }
      return this.statSum[stat] || 0;
    };
    ShadowcraftGear.prototype.getDodge = function(hand) {
      var ItemLookup, boss_dodge, data, expertise;
      data = Shadowcraft.Data;
      ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
      expertise = this.statSum.expertise_rating;
      boss_dodge = DEFAULT_BOSS_DODGE;
      if ((!(hand != null) || hand === "main") && data.gear[15] && data.gear[15].item_id) {
        expertise += racialExpertiseBonus(ItemLookup[data.gear[15].item_id]);
      } else if ((hand === "off") && data.gear[16] && data.gear[16].item_id) {
        expertise += racialExpertiseBonus(ItemLookup[data.gear[16].item_id]);
      }
      return DEFAULT_BOSS_DODGE - (expertise / Shadowcraft._R("expertise_rating") * 0.25);
    };
    getHitEP = function() {
      var exist, spellHitCap, whiteHitCap, yellowHitCap;
      yellowHitCap = Shadowcraft._R("hit_rating") * (8 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating");
      spellHitCap = Shadowcraft._R("spell_hit") * (17 - 2 * Shadowcraft._T("precision")) - racialHitBonus("spell_hit");
      whiteHitCap = Shadowcraft._R("hit_rating") * (27 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating");
      exist = Shadowcraft.Gear.getStat("hit_rating");
      if (exist < yellowHitCap) {
        return Weights.yellow_hit;
      } else if (exist < spellHitCap) {
        return Weights.spell_hit;
      } else if (exist < whiteHitCap) {
        return Weights.hit_rating;
      } else {
        return 0;
      }
    };
    ShadowcraftGear.prototype.getCaps = function() {
      var ItemLookup, caps, data, exp_base;
      data = Shadowcraft.Data;
      ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
      exp_base = Shadowcraft._R("expertise_rating") * DEFAULT_BOSS_DODGE * 4;
      caps = {
        yellow_hit: Shadowcraft._R("hit_rating") * (8 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating"),
        spell_hit: Shadowcraft._R("spell_hit") * (17 - 2 * Shadowcraft._T("precision")) - racialHitBonus("spell_hit"),
        white_hit: Shadowcraft._R("hit_rating") * (27 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating"),
        mh_exp: 791,
        oh_exp: 791
      };
      if (data.gear[15]) {
        caps.mh_exp = exp_base - racialExpertiseBonus(ItemLookup[data.gear[15].item_id]);
      }
      if (data.gear[16]) {
        caps.oh_exp = exp_base - racialExpertiseBonus(ItemLookup[data.gear[16].item_id]);
      }
      return caps;
    };
    ShadowcraftGear.prototype.getMiss = function(cap) {
      var data, hasHit, hitCap, r;
      data = Shadowcraft.Data;
      switch (cap) {
        case "yellow":
          r = Shadowcraft._R("hit_rating");
          hitCap = r * (8 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating");
          break;
        case "spell":
          r = Shadowcraft._R("spell_hit");
          hitCap = r * (17 - 2 * Shadowcraft._T("precision")) - racialHitBonus("spell_hit");
          break;
        case "white":
          r = Shadowcraft._R("hit_rating");
          hitCap = r * (27 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating");
      }
      if ((r != null) && (hitCap != null)) {
        hasHit = this.statSum.hit_rating || 0;
        if (hasHit < hitCap || cap === "white") {
          return (hitCap - hasHit) / r;
        } else {
          return 0;
        }
      }
      return -99;
    };
    getStatWeight = function(stat, num, ignore, ignoreAll) {
      var ItemLookup, boss_dodge, data, delta, exist, mhCap, neg, ohCap, remaining, spellHitCap, total, usable, whiteHitCap, yellowHitCap;
      data = Shadowcraft.Data;
      ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
      exist = 0;
      if (!ignoreAll) {
        exist = Shadowcraft.Gear.getStat(stat);
        if (ignore && ignore[stat]) {
          exist -= ignore[stat];
        }
      }
      neg = num < 0 ? -1 : 1;
      num = Math.abs(num);
      switch (stat) {
        case "expertise_rating":
          boss_dodge = DEFAULT_BOSS_DODGE;
          mhCap = Shadowcraft._R("expertise_rating") * boss_dodge * 4;
          ohCap = mhCap;
          if (data.gear[15] && data.gear[15].item_id) {
            mhCap -= racialExpertiseBonus(ItemLookup[data.gear[15].item_id]);
          }
          if (data.gear[16] && data.gear[16].item_id) {
            ohCap -= racialExpertiseBonus(ItemLookup[data.gear[16].item_id]);
          }
          total = 0;
          if (mhCap > exist) {
            usable = mhCap - exist;
            if (usable > num) {
              usable = num;
            }
            total += usable * Weights.expertise_rating * MH_EXPERTISE_FACTOR;
          }
          if (ohCap > exist) {
            usable = ohCap - exist;
            if (usable > num) {
              usable = num;
            }
            total += usable * Weights.expertise_rating * OH_EXPERTISE_FACTOR;
          }
          return total * neg;
        case "hit_rating":
          yellowHitCap = Shadowcraft._R("hit_rating") * (8 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating");
          spellHitCap = Shadowcraft._R("spell_hit") * (17 - 2 * Shadowcraft._T("precision")) - racialHitBonus("spell_hit");
          whiteHitCap = Shadowcraft._R("hit_rating") * (27 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating");
          total = 0;
          remaining = num;
          if (remaining > 0 && exist < yellowHitCap) {
            delta = (yellowHitCap - exist) > remaining ? remaining : yellowHitCap - exist;
            total += delta * Weights.yellow_hit;
            remaining -= delta;
            exist += delta;
          }
          if (remaining > 0 && exist < spellHitCap) {
            delta = (spellHitCap - exist) > remaining ? remaining : spellHitCap - exist;
            total += delta * Weights.spell_hit;
            remaining -= delta;
            exist += delta;
          }
          if (remaining > 0 && exist < whiteHitCap) {
            delta = (whiteHitCap - exist) > remaining ? remaining : whiteHitCap - exist;
            total += delta * Weights.hit_rating;
            remaining -= delta;
            exist += delta;
          }
          return total * neg;
      }
      return (Weights[stat] || 0) * num * neg;
    };
    __epSort = function(a, b) {
      return b.__ep - a.__ep;
    };
    epSort = function(list, skipSort, slot) {
      var item, _i, _len;
      for (_i = 0, _len = list.length; _i < _len; _i++) {
        item = list[_i];
        if (item) {
          item.__ep = get_ep(item, false, slot);
        }
      }
      if (!skipSort) {
        return list.sort(__epSort);
      }
    };
    needsDagger = function() {
      return Shadowcraft.Data.tree0 >= 31 || Shadowcraft.Data.tree2 >= 31;
    };
    isProfessionalGem = function(gem, profession) {
      var _ref;
      return (((_ref = gem.requires) != null ? _ref.profession : void 0) != null) && gem.requires.profession === profession;
    };
    getEquippedGemCount = function(gem, pendingChanges, ignoreSlotIndex) {
      var count, g, gear, slot, _i, _j, _len, _len2;
      count = 0;
      for (_i = 0, _len = SLOT_ORDER.length; _i < _len; _i++) {
        slot = SLOT_ORDER[_i];
        if (slot === ignoreSlotIndex) {
          continue;
        }
        gear = Shadowcraft.Data.gear[slot];
        if (gem.id === gear.g0 || gem.id === gear.g1 || gem.id === gear.g2) {
          count++;
        }
      }
      if (pendingChanges != null) {
        for (_j = 0, _len2 = pendingChanges.length; _j < _len2; _j++) {
          g = pendingChanges[_j];
          if (g === gem.id) {
            count++;
          }
        }
      }
      return count;
    };
    getProfessionalGemCount = function(profession, pendingChanges, ignoreSlotIndex) {
      var Gems, count, g, gear, gem, i, slot, _i, _j, _len, _len2;
      count = 0;
      Gems = Shadowcraft.ServerData.GEM_LOOKUP;
      for (_i = 0, _len = SLOT_ORDER.length; _i < _len; _i++) {
        slot = SLOT_ORDER[_i];
        if (slot === ignoreSlotIndex) {
          continue;
        }
        gear = Shadowcraft.Data.gear[slot];
        for (i = 0; i <= 2; i++) {
          gem = (gear["g" + i] != null) && Gems[gear["g" + i]];
          if (!gem) {
            continue;
          }
          if (isProfessionalGem(gem, profession)) {
            count++;
          }
        }
      }
      if (pendingChanges != null) {
        for (_j = 0, _len2 = pendingChanges.length; _j < _len2; _j++) {
          g = pendingChanges[_j];
          if (isProfessionalGem(g, profession)) {
            count++;
          }
        }
      }
      return count;
    };
    canUseGem = function(gem, gemType, pendingChanges, ignoreSlotIndex) {
      var _ref;
      if (((_ref = gem.requires) != null ? _ref.profession : void 0) != null) {
        if (!Shadowcraft.Data.options.professions[gem.requires.profession]) {
          return false;
        }
        if (isProfessionalGem(gem, 'jewelcrafting') && getProfessionalGemCount('jewelcrafting', pendingChanges, ignoreSlotIndex) >= MAX_JEWELCRAFTING_GEMS) {
          return false;
        }
        if (isProfessionalGem(gem, 'engineering') && getEquippedGemCount(gem, pendingChanges, ignoreSlotIndex) >= MAX_ENGINEERING_GEMS) {
          return false;
        }
      }
      if ((gemType === "Meta" || gemType === "Cogwheel") && gem.slot !== gemType) {
        return false;
      }
      if ((gem.slot === "Meta" || gem.slot === "Cogwheel") && gem.slot !== gemType) {
        return false;
      }
      return true;
    };
    getRegularGemEpValue = function(gem) {
      var equiv_ep, j, name, prefix, reg, _i, _len, _ref, _ref2;
      equiv_ep = gem.__ep || get_ep(gem);
      return equiv_ep;
      if (gem.__reg_ep) {
        return gem.__reg_ep;
      }
      for (_i = 0, _len = JC_ONLY_GEMS.length; _i < _len; _i++) {
        name = JC_ONLY_GEMS[_i];
        if (gem.name.indexOf(name) >= 0) {
          prefix = gem.name.replace(name, "");
          _ref = Shadowcraft.ServerData.GEMS;
          for (j in _ref) {
            reg = _ref[j];
            if (!(((_ref2 = reg.requires) != null ? _ref2.profession : void 0) != null) && reg.name.indexOf(prefix) === 0 && reg.quality === gem.quality) {
              equiv_ep = reg.__ep || get_ep(reg);
              equiv_ep += 1;
              gem.__reg_ep = equiv_ep;
              return false;
            }
          }
          return false;
        }
      }
      return equiv_ep;
    };
    addTradeskillBonuses = function(item) {
      var blacksmith;
      item.sockets || (item.sockets = []);
      item._sockets || (item._sockets = item.sockets.slice(0));
      blacksmith = Shadowcraft.Data.options.professions.blacksmithing != null;
      if (item.equip_location === 9 || item.equip_location === 10) {
        if (blacksmith && item.sockets[item.sockets.length - 1] !== "Prismatic") {
          return item.sockets[item.sockets.length] = "Prismatic";
        } else if (!blacksmith && item.sockets[item.sockets.length - 1] === "Prismatic") {
          return item.sockets[item.sockets.length].slice(0, item.sockets.length - 2);
        }
      }
    };
    getGemmingRecommendation = function(gem_list, item, returnFull, ignoreSlotIndex) {
      var bonus, data, epValue, gem, gemType, gems, mGems, matchedGemEP, sGems, straightGemEP, _i, _j, _k, _l, _len, _len2, _len3, _len4, _ref, _ref2;
      data = Shadowcraft.Data;
      if (!item.sockets || item.sockets.length === 0) {
        if (returnFull) {
          return {
            ep: 0,
            gems: []
          };
        } else {
          return 0;
        }
      }
      straightGemEP = 0;
      matchedGemEP = get_ep(item, "socketbonus");
      if (returnFull) {
        sGems = [];
        mGems = [];
      }
      _ref = item.sockets;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        gemType = _ref[_i];
        for (_j = 0, _len2 = gem_list.length; _j < _len2; _j++) {
          gem = gem_list[_j];
          if (!canUseGem(gem, gemType, sGems, ignoreSlotIndex)) {
            continue;
          }
          straightGemEP += getRegularGemEpValue(gem);
          if (returnFull) {
            sGems.push(gem.id);
          }
          break;
        }
      }
      _ref2 = item.sockets;
      for (_k = 0, _len3 = _ref2.length; _k < _len3; _k++) {
        gemType = _ref2[_k];
        for (_l = 0, _len4 = gem_list.length; _l < _len4; _l++) {
          gem = gem_list[_l];
          if (!canUseGem(gem, gemType, mGems, ignoreSlotIndex)) {
            continue;
          }
          if (gem[gemType]) {
            matchedGemEP += getRegularGemEpValue(gem);
            if (returnFull) {
              mGems.push(gem.id);
            }
            break;
          }
        }
      }
      bonus = false;
      if (matchedGemEP > straightGemEP) {
        epValue = matchedGemEP;
        gems = mGems;
        bonus = true;
      } else {
        epValue = straightGemEP;
        gems = sGems;
      }
      if (returnFull) {
        return {
          ep: epValue,
          takeBonus: bonus,
          gems: gems
        };
      } else {
        return epValue;
      }
    };
    ShadowcraftGear.prototype.optimizeGems = function(depth) {
      var Gems, ItemLookup, data, from_gem, gear, gem, gemIndex, gem_list, item, madeChanges, rec, slotIndex, to_gem, _i, _len, _len2, _ref;
      ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
      Gems = Shadowcraft.ServerData.GEM_LOOKUP;
      data = Shadowcraft.Data;
      depth || (depth = 0);
      if (depth === 0) {
        EP_PRE_REGEM = this.getEPTotal();
        Shadowcraft.Console.log("Beginning auto-regem...", "gold underline");
      }
      madeChanges = false;
      gem_list = getGemRecommendationList();
      for (_i = 0, _len = SLOT_ORDER.length; _i < _len; _i++) {
        slotIndex = SLOT_ORDER[_i];
        gear = data.gear[slotIndex];
        if (!gear) {
          continue;
        }
        item = ItemLookup[gear.item_id];
        if (item) {
          rec = getGemmingRecommendation(gem_list, item, true, slotIndex);
          _ref = rec.gems;
          for (gemIndex = 0, _len2 = _ref.length; gemIndex < _len2; gemIndex++) {
            gem = _ref[gemIndex];
            from_gem = Gems[gear["g" + gemIndex]];
            to_gem = Gems[gem];
            if (gear["g" + gemIndex] !== gem) {
              if (from_gem && to_gem) {
                if (from_gem.name === to_gem.name) {
                  continue;
                }
                Shadowcraft.Console.log("Regemming " + item.name + " socket " + (gemIndex + 1) + " from " + from_gem.name + " to " + to_gem.name);
              } else {
                Shadowcraft.Console.log("Regemming " + item.name + " socket " + (gemIndex + 1) + " to " + to_gem.name);
              }
              gear["g" + gemIndex] = gem;
              madeChanges = true;
            }
          }
        }
      }
      if (!madeChanges || depth >= 10) {
        this.app.update();
        this.updateDisplay();
        return Shadowcraft.Console.log("Finished automatic regemming: &Delta; " + (Math.floor(this.getEPTotal() - EP_PRE_REGEM)) + " EP", "gold");
      } else {
        return this.optimizeGems(depth + 1);
      }
    };
    getGemRecommendationList = function() {
      var Gems, list;
      Gems = Shadowcraft.ServerData.GEMS;
      list = $.extend(true, [], Gems);
      list.sort(function(a, b) {
        return getRegularGemEpValue(b) - getRegularGemEpValue(a);
      });
      return list;
    };
    /*
    # Reforge helpers
    */
    canReforge = function(item) {
      var stat;
      if (item.ilvl < 200) {
        return false;
      }
      for (stat in item.stats) {
        if (REFORGABLE.indexOf(stat) >= 0) {
          return true;
        }
      }
      return false;
    };
    sourceStats = function(stats) {
      var source, stat;
      source = [];
      for (stat in stats) {
        if (REFORGABLE.indexOf(stat) >= 0) {
          source.push({
            key: stat,
            name: titleize(stat),
            value: stats[stat],
            use: Math.floor(stats[stat] * REFORGE_FACTOR)
          });
        }
      }
      return source;
    };
    recommendReforge = function(item) {
      var best, bestVal, dep, dest, dstat, ep, ignore, ramt, reforge_stat, source, stat, _i, _len;
      source = item.stats;
      ignore = item.reforge;
      dest = REFORGE_STATS;
      best = null;
      bestVal = null;
      for (stat in source) {
        if (REFORGABLE.indexOf(stat) >= 0) {
          ramt = Math.floor(source[stat] * REFORGE_FACTOR);
          ep = getStatWeight(stat, -ramt, ignore);
          for (_i = 0, _len = REFORGE_STATS.length; _i < _len; _i++) {
            reforge_stat = REFORGE_STATS[_i];
            dstat = reforge_stat.key;
            if (source[dstat]) {
              continue;
            }
            dep = getStatWeight(dstat, ramt, ignore);
            if (!bestVal || (dep + ep) > bestVal) {
              best = compactReforge(stat, dstat);
              bestVal = dep + ep;
            }
          }
        }
      }
      return best;
    };
    reforgeEp = function(reforge, item) {
      var amt, gain, loss, stat;
      stat = getReforgeFrom(reforge);
      amt = item.stats[stat];
      loss = getStatWeight(stat, -amt);
      stat = getReforgeTo(reforge);
      gain = getStatWeight(stat, amt);
      return gain + loss;
    };
    ShadowcraftGear.prototype.setReforges = function(reforges) {
      var ItemLookup, amt, from, g, gear, id, item, model, reforge, slot, to, _i, _len;
      model = Shadowcraft.Data;
      ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
      for (id in reforges) {
        reforge = reforges[id];
        gear = null;
        id = parseInt(id, 10);
        reforge = parseInt(reforge, 10);
        if (reforge === 0) {
          reforge = null;
        }
        for (_i = 0, _len = SLOT_ORDER.length; _i < _len; _i++) {
          slot = SLOT_ORDER[_i];
          g = model.gear[slot];
          if (g.item_id === id) {
            gear = g;
            break;
          }
        }
        if (gear && gear.reforge !== reforge) {
          item = ItemLookup[gear.item_id];
          if (reforge === null) {
            Shadowcraft.Console.log("Removed reforge from " + item.name);
            delete gear.reforge;
          } else {
            from = getReforgeFrom(reforge);
            to = getReforgeTo(reforge);
            amt = reforgeAmount(item, from);
            gear.reforge = reforge;
            Shadowcraft.Console.log("Reforged " + item.name + " to <span class='neg'>-" + amt + " " + (titleize(from)) + "</span> / <span class='pos'>+" + amt + " " + (titleize(to)) + "</span>");
          }
        }
      }
      Shadowcraft.update();
      return Shadowcraft.Gear.updateDisplay();
    };
    startReforges = null;
    ShadowcraftGear.prototype.reforgeAll = function(depth) {
      var ItemLookup, amt, data, ep, from, gear, item, madeChanges, rec, reforge, slot, slots, to, _i, _j, _len, _len2;
      data = Shadowcraft.Data;
      ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
      depth || (depth = 0);
      if (depth === 0) {
        EP_PRE_REFORGE = this.getEPTotal();
        Shadowcraft.Console.log("Beginning automatic reforge...", "gold underline");
        startReforges = {};
        for (_i = 0, _len = SLOT_ORDER.length; _i < _len; _i++) {
          slot = SLOT_ORDER[_i];
          gear = data.gear[slot];
          if (!gear) {
            continue;
          }
          startReforges[slot] = gear.reforge;
        }
      }
      madeChanges = false;
      slots = _.flatten([SLOT_ORDER.slice(depth), SLOT_ORDER.slice(0, depth)]);
      for (_j = 0, _len2 = slots.length; _j < _len2; _j++) {
        slot = slots[_j];
        gear = data.gear[slot];
        if (!gear) {
          continue;
        }
        item = ItemLookup[gear.item_id];
        if (item && canReforge(item)) {
          rec = recommendReforge(item);
          if (rec) {
            ep = reforgeEp(rec, item);
            if (ep > 0 && gear.reforge !== rec) {
              madeChanges = true;
              gear.reforge = rec;
              this.sumStats();
            }
          }
        }
      }
      if (!madeChanges || depth >= SLOT_ORDER.length) {
        this.app.update();
        this.updateDisplay();
        for (slot in startReforges) {
          reforge = startReforges[slot];
          gear = data.gear[slot];
          if (gear && gear.reforge !== reforge) {
            from = getReforgeFrom(gear.reforge);
            to = getReforgeTo(gear.reforge);
            item = ItemLookup[gear.item_id];
            amt = reforgeAmount(item, from);
            Shadowcraft.Console.log("Reforged " + item.name + " to <span class='neg'>-" + amt + " " + (titleize(from)) + "</span> / <span class='pos'>+" + amt + " " + (titleize(to)) + "</span>");
          }
        }
        return Shadowcraft.Console.log("Finished automatic reforging: &Delta; " + Math.floor(this.getEPTotal() - EP_PRE_REFORGE) + " EP", "gold");
      } else {
        return this.reforgeAll(depth + 1);
      }
    };
    clearReforge = function() {
      var ItemLookup, data, gear, slot;
      data = Shadowcraft.Data;
      ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
      slot = $.data(document.body, "selecting-slot");
      gear = data.gear[slot];
      if (!gear) {
        return;
      }
      if (gear.reforge) {
        delete gear.reforge;
      }
      Shadowcraft.Console.log("Removing reforge on " + ItemLookup[gear.item_id].name);
      Shadowcraft.update();
      Shadowcraft.Gear.updateDisplay();
      return $("#reforge").removeClass("visible");
    };
    ShadowcraftGear.prototype.doReforge = function() {
      var ItemLookup, amt, data, from, gear, item, slot, to;
      data = Shadowcraft.Data;
      ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
      slot = $.data(document.body, "selecting-slot");
      from = $("#reforge input[name='oldstat']:checked").val();
      to = $("#reforge input[name='newstat']:checked").val();
      gear = data.gear[slot];
      if (!gear) {
        return;
      }
      item = ItemLookup[gear.item_id];
      amt = reforgeAmount(item, from);
      if ((from != null) && (to != null)) {
        gear.reforge = compactReforge(from, to);
        Shadowcraft.Console.log("Reforging " + item.name + " to <span class='neg'>-" + amt + " " + (titleize(from)) + "</span> / <span class='pos'>+" + amt + " " + (titleize(to)) + "</span>");
      }
      $("#reforge").removeClass("visible");
      Shadowcraft.update();
      return Shadowcraft.Gear.updateDisplay();
    };
    /*
    # View helpers
    */
    ShadowcraftGear.prototype.updateDisplay = function(skipUpdate) {
      var EnchantLookup, EnchantSlots, Gems, ItemLookup, allSlotsMatch, amt, bonuses, buffer, data, enchant, enchantable, from, gear, gem, gems, i, item, opt, reforgable, reforge, slotIndex, slotSet, socket, ssi, stat, to, _i, _len, _len2, _len3, _ref, _ref2;
      this.updateStatsWindow();
      ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
      EnchantLookup = Shadowcraft.ServerData.ENCHANT_LOOKUP;
      EnchantSlots = Shadowcraft.ServerData.ENCHANT_SLOTS;
      Gems = Shadowcraft.ServerData.GEM_LOOKUP;
      data = Shadowcraft.Data;
      opt = {};
      for (ssi = 0, _len = SLOT_DISPLAY_ORDER.length; ssi < _len; ssi++) {
        slotSet = SLOT_DISPLAY_ORDER[ssi];
        buffer = "";
        for (slotIndex = 0, _len2 = slotSet.length; slotIndex < _len2; slotIndex++) {
          i = slotSet[slotIndex];
          gear = data.gear[i] || {};
          item = ItemLookup[gear.item_id];
          gems = [];
          bonuses = null;
          enchant = EnchantLookup[gear.enchant];
          reforge = null;
          reforgable = null;
          if (item) {
            addTradeskillBonuses(item);
            enchantable = EnchantSlots[item.equip_location] != null;
            if ((!data.options.professions.enchanting && item.equip_location === 11) || item.equip_location === "ranged") {
              enchantable = false;
            }
            allSlotsMatch = item.sockets && item.sockets.length > 0;
            _ref = item.sockets;
            for (_i = 0, _len3 = _ref.length; _i < _len3; _i++) {
              socket = _ref[_i];
              gem = Gems[gear["g" + gems.length]];
              gems[gems.length] = {
                socket: socket,
                gem: gem
              };
              if (!gem || !gem[socket]) {
                allSlotsMatch = false;
              }
            }
            if (allSlotsMatch) {
              bonuses = [];
              _ref2 = item.socketbonus;
              for (stat in _ref2) {
                amt = _ref2[stat];
                bonuses[bonuses.length] = {
                  stat: titleize(stat),
                  amount: amt
                };
              }
            }
            if (enchant && !enchant.desc) {
              enchant.desc = statsToDesc(enchant);
            }
            reforgable = canReforge(item);
            if (reforgable && gear.reforge) {
              from = getReforgeFrom(gear.reforge);
              to = getReforgeTo(gear.reforge);
              amt = reforgeAmount(item, from);
              reforge = {
                value: amt,
                from: titleize(from),
                to: titleize(to)
              };
            }
          }
          if (enchant && enchant.desc === "") {
            enchant.desc = enchant.name;
          }
          opt.item = item;
          if (item) {
            if (item.id > 100000) {
              opt.ttid = Math.floor(item.id / 1000);
            } else {
              opt.ttid = item.id;
            }
          }
          opt.ep = item ? get_ep(item, null, i).toFixed(1) : 0;
          opt.slot = i + '';
          opt.gems = gems;
          opt.socketbonus = bonuses;
          opt.reforgable = reforgable;
          opt.reforge = reforge;
          opt.sockets = item ? item.sockets : null;
          opt.enchantable = enchantable;
          opt.enchant = enchant;
          buffer += Templates.itemSlot(opt);
        }
        $slots.get(ssi).innerHTML = buffer;
      }
      return checkForWarnings('gear');
    };
    whiteWhite = function(v, s) {
      return s;
    };
    redWhite = function(v, s) {
      var c;
      s || (s = v);
      c = v < 0 ? "neg" : "";
      return colorSpan(s, c);
    };
    greenWhite = function(v, s) {
      var c;
      s || (s = v);
      c = v < 0 ? "" : "pos";
      return colorSpan(s, c);
    };
    redGreen = function(v, s) {
      var c;
      s || (s = v);
      c = v < 0 ? "neg" : "pos";
      return colorSpan(s, c);
    };
    colorSpan = function(s, c) {
      return "<span class='" + c + "'>" + s + "</span>";
    };
    pctColor = function(v, func, reverse) {
      func || (func = redGreen);
      reverse || (reverse = 1);
      return func(v * reverse, v.toFixed(2) + "%");
    };
    ShadowcraftGear.prototype.getEPTotal = function() {
      var idx, keys, stat, total, weight;
      this.sumStats();
      keys = _.keys(this.statSum).sort();
      total = 0;
      for (idx in keys) {
        stat = keys[idx];
        weight = getStatWeight(stat, this.statSum[stat], null, true);
        total += weight;
      }
      return total;
    };
    ShadowcraftGear.prototype.updateStatsWindow = function() {
      var $stats, a_stats, idx, keys, stat, total, weight;
      this.sumStats();
      $stats = $("#stats .inner");
      a_stats = [];
      keys = _.keys(this.statSum).sort();
      total = 0;
      for (idx in keys) {
        stat = keys[idx];
        weight = getStatWeight(stat, this.statSum[stat], null, true);
        total += weight;
        a_stats.push({
          name: titleize(stat),
          val: this.statSum[stat]
        });
      }
      a_stats.push({
        name: "Dodge",
        val: pctColor(this.getDodge("main"), redWhite) + " " + pctColor(this.getDodge("off"), redWhite)
      });
      a_stats.push({
        name: "Yellow Miss",
        val: pctColor(this.getMiss("yellow"), redWhite, -1)
      });
      a_stats.push({
        name: "Spell Miss",
        val: pctColor(this.getMiss("spell"), redWhite)
      });
      a_stats.push({
        name: "White Miss",
        val: pctColor(this.getMiss("white"), redWhite)
      });
      EP_TOTAL = total;
      return $stats.get(0).innerHTML = Templates.stats({
        stats: a_stats
      });
    };
    updateStatWeights = function(source) {
      var $weights, data, e, exist, key, weight;
      data = Shadowcraft.Data;
      Weights.agility = source.ep.agi;
      Weights.crit_rating = source.ep.crit;
      Weights.hit_rating = source.ep.white_hit;
      Weights.spell_hit = source.ep.spell_hit;
      Weights.strength = source.ep.str;
      Weights.mastery_rating = source.ep.mastery;
      Weights.haste_rating = source.ep.haste;
      Weights.expertise_rating = source.ep.dodge_exp;
      Weights.yellow_hit = source.ep.yellow_hit;
      $weights = $("#weights .inner");
      $weights.empty();
      for (key in Weights) {
        weight = Weights[key];
        exist = $(".stat#weight_" + key);
        if (exist.length > 0) {
          exist.find("val").text(Weights[key].toFixed(2));
        } else {
          e = $weights.append("<div class='stat' id='weight_" + key + "'><span class='key'>" + (titleize(key)) + "</span><span class='val'>" + (Weights[key].toFixed(2)) + "</span></div>");
          exist = $(".stat#weight_" + key);
        }
        $.data(exist.get(0), "weight", Weights[key]);
      }
      $("#weights .stat").sortElements(function(a, b) {
        if ($.data(a, "weight") > $.data(b, "weight")) {
          return -1;
        } else {
          return 1;
        }
      });
      return epSort(Shadowcraft.ServerData.GEMS);
    };
    statsToDesc = function(obj) {
      var buff, stat;
      if (obj.__statsToDesc) {
        return obj.__statsToDesc;
      }
      buff = [];
      for (stat in obj.stats) {
        buff[buff.length] = "+" + obj.stats[stat] + " " + titleize(stat);
      }
      obj.__statsToDesc = buff.join("/");
      return obj.__statsToDesc;
    };
    clickSlot = function(slot, prop) {
      var $slot, slotIndex;
      $slot = $(slot).closest(".slot");
      $slots.find(".slot").removeClass("active");
      $slot.addClass("active");
      slotIndex = parseInt($slot.attr("data-slot"), 10);
      $.data(document.body, "selecting-slot", slotIndex);
      $.data(document.body, "selecting-prop", prop);
      return [$slot, slotIndex];
    };
    clickSlotName = function() {
      var $slot, GemList, buf, buffer, deltaEp, equip_location, iEP, l, loc, max, rec, reforgedStats, requireDagger, selected_id, slot, ttid, _i, _j, _len, _len2;
      buf = clickSlot(this, "item_id");
      $slot = buf[0];
      slot = buf[1];
      selected_id = parseInt($slot.attr("id"), 10);
      equip_location = SLOT_INVTYPES[slot];
      GemList = Shadowcraft.ServerData.GEMS;
      loc = Shadowcraft.ServerData.SLOT_CHOICES[equip_location];
      slot = parseInt($(this).parent().data("slot"), 10);
      epSort(GemList);
      for (_i = 0, _len = loc.length; _i < _len; _i++) {
        l = loc[_i];
        l.__gemRec = getGemmingRecommendation(GemList, l, true);
        l.__gemEP = l.__gemRec.ep;
        rec = recommendReforge(l.stats);
        if (rec) {
          reforgedStats = {};
          reforgedStats[rec.source.key] = -rec.qty;
          reforgedStats[rec.dest.key] = rec.qty;
          deltaEp = get_ep({
            stats: reforgedStats
          });
          l.__reforgeEP = deltaEp > 0 ? deltaEp : 0;
        } else {
          l.__reforgeEP = 0;
        }
        l.__ep = get_ep(l, null, slot) + l.__gemRec.ep + l.__reforgeEP;
      }
      loc.sort(__epSort);
      max = loc[0].__ep;
      buffer = "";
      requireDagger = needsDagger();
      for (_j = 0, _len2 = loc.length; _j < _len2; _j++) {
        l = loc[_j];
        if (l.__ep < 1) {
          continue;
        }
        if ((slot === 15 || slot === 16) && requireDagger && l.subclass !== 15) {
          continue;
        }
        if ((slot === 15) && !requireDagger && l.subclass === 15) {
          continue;
        }
        if (l.ilvl > Shadowcraft.Data.options.general.max_ilvl) {
          continue;
        }
        iEP = l.__ep.toFixed(1);
        if (l.id > 100000) {
          ttid = Math.floor(l.id / 1000);
        } else {
          ttid = l.id;
        }
        buffer += Templates.itemSlot({
          item: l,
          gear: {},
          gems: [],
          ttid: ttid,
          desc: "" + (get_ep(l).toFixed(1)) + " base / " + (l.__reforgeEP.toFixed(1)) + " reforge / " + (l.__gemEP.toFixed(1)) + " gem " + (l.__gemRec.takeBonus ? "(Match gems)" : ""),
          search: l.name,
          percent: iEP / max * 100,
          ep: iEP
        });
      }
      buffer += Templates.itemSlot({
        item: {
          name: "[No item]"
        },
        desc: "Clear this slot",
        percent: 0,
        ep: 0
      });
      $altslots.get(0).innerHTML = buffer;
      $altslots.find(".slot[id='" + selected_id + "']").addClass("active");
      showPopup($popup);
      return false;
    };
    clickSlotEnchant = function() {
      var EnchantSlots, buf, buffer, data, eEP, enchant, enchants, equip_location, max, selected_id, slot, _i, _j, _len, _len2;
      data = Shadowcraft.Data;
      EnchantSlots = Shadowcraft.ServerData.ENCHANT_SLOTS;
      buf = clickSlot(this, "enchant");
      slot = buf[1];
      equip_location = SLOT_INVTYPES[slot];
      enchants = EnchantSlots[equip_location];
      max = 0;
      for (_i = 0, _len = enchants.length; _i < _len; _i++) {
        enchant = enchants[_i];
        enchant.__ep = get_ep(enchant, null, slot);
        max = enchant.__ep > max ? enchant.__ep : max;
      }
      enchants.sort(__epSort);
      selected_id = data.gear[slot].enchant;
      buffer = "";
      for (_j = 0, _len2 = enchants.length; _j < _len2; _j++) {
        enchant = enchants[_j];
        if (enchant && !enchant.desc) {
          enchant.desc = statsToDesc(enchant);
        }
        eEP = enchant.__ep;
        if (eEP < 1) {
          continue;
        }
        buffer += Templates.itemSlot({
          item: enchant,
          percent: eEP / max * 100,
          ep: eEP.toFixed(1),
          search: enchant.name + " " + enchant.desc,
          desc: enchant.desc
        });
      }
      $altslots.get(0).innerHTML = buffer;
      $altslots.find(".slot[id='" + selected_id + "']").addClass("active");
      showPopup($popup);
      return false;
    };
    clickSlotGem = function() {
      var $slot, GemList, ItemLookup, buf, buffer, data, desc, gEP, gem, gemCt, gemSlot, gemType, item, max, selected_id, slot, socketEPBonus, usedNames, _i, _j, _len, _len2;
      ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
      GemList = Shadowcraft.ServerData.GEMS;
      data = Shadowcraft.Data;
      buf = clickSlot(this, "gem");
      $slot = buf[0];
      slot = buf[1];
      item = ItemLookup[parseInt($slot.attr("id"), 10)];
      socketEPBonus = (item.socketbonus ? get_ep(item, "socketbonus") : 0) / item.sockets.length;
      gemSlot = $slot.find(".gem").index(this);
      $.data(document.body, "gem-slot", gemSlot);
      gemType = item.sockets[gemSlot];
      selected_id = data.gear[slot]["g" + gemSlot];
      for (_i = 0, _len = GemList.length; _i < _len; _i++) {
        gem = GemList[_i];
        gem.__ep = get_ep(gem) + (gem[item.sockets[gemSlot]] ? socketEPBonus : 0);
      }
      GemList.sort(__epSort);
      buffer = "";
      gemCt = 0;
      usedNames = {};
      max = null;
      for (_j = 0, _len2 = GemList.length; _j < _len2; _j++) {
        gem = GemList[_j];
        if (!canUseGem(gem, gemType)) {
          continue;
        }
        max || (max = gem.__ep);
        if (usedNames[gem.name]) {
          if (gem.id === selected_id) {
            selected_id = usedNames[gem.name];
          }
          continue;
        }
        gemCt += 1;
        if (gemCt > 50) {
          break;
        }
        usedNames[gem.name] = gem.id;
        gEP = gem.__ep;
        desc = statsToDesc(gem);
        if (gEP < 1) {
          continue;
        }
        if (gem[item.sockets[gemSlot]]) {
          desc += " (+" + (socketEPBonus.toFixed(1)) + " bonus)";
        }
        buffer += Templates.itemSlot({
          item: gem,
          ep: gEP.toFixed(1),
          gear: {},
          ttid: gem.id,
          search: gem.name + " " + statsToDesc(gem) + " " + gem.slot,
          percent: gEP / max * 100,
          desc: desc
        });
      }
      $altslots.get(0).innerHTML = buffer;
      $altslots.find(".slot[id='" + selected_id + "']").addClass("active");
      showPopup($popup);
      return false;
    };
    clickSlotReforge = function() {
      var $slot, amt, data, from, id, item, rec, recommended, slot, source, targetStats, to;
      clickSlot(this, "reforge");
      $(".slot").removeClass("active");
      $(this).addClass("active");
      data = Shadowcraft.Data;
      $slot = $(this).closest(".slot");
      slot = parseInt($slot.data("slot"), 10);
      $.data(document.body, "selecting-slot", slot);
      id = $slot.attr("id");
      item = Shadowcraft.ServerData.ITEM_LOOKUP[id];
      rec = recommendReforge(item);
      recommended = null;
      if (rec) {
        from = getReforgeFrom(rec);
        to = getReforgeTo(rec);
        amt = reforgeAmount(item, from);
        recommended = {
          from: titleize(from),
          to: titleize(to),
          amount: amt
        };
      }
      source = sourceStats(item.stats);
      targetStats = _.select(REFORGE_STATS, function(s) {
        return item.stats[s.key] === void 0;
      });
      $.data(document.body, "reforge-recommendation", rec);
      $.data(document.body, "reforge-item", item);
      $("#reforge").html(Templates.reforge({
        stats: source,
        newstats: targetStats,
        recommended: recommended
      }));
      $("#reforge .pct").hide();
      showPopup($("#reforge.popup"));
      return false;
    };
    ShadowcraftGear.prototype.boot = function() {
      var TiniReforger, app, defaultScale, reset;
      app = this;
      $slots = $(".slots");
      $popup = $(".alternatives");
      $altslots = $(".alternatives .body");
      TiniReforger = new ShadowcraftTiniReforgeBackend(app);
      Shadowcraft.Backend.bind("recompute", updateStatWeights);
      Shadowcraft.Backend.bind("recompute", function() {
        return Shadowcraft.Gear;
      });
      Shadowcraft.bind("loadData", function() {
        return app.updateDisplay();
      });
      $("#reforgeAll").click(function() {
        return TiniReforger.buildRequest();
      });
      $("#optimizeGems").click(function() {
        return Shadowcraft.Gear.optimizeGems();
      });
      $("#reforge").click($.delegate({
        ".label_radio": function() {
          return Shadowcraft.setupLabels("#reforge");
        },
        ".doReforge": this.doReforge,
        ".clearReforge": clearReforge
      }));
      $slots.click($.delegate({
        ".name": clickSlotName,
        ".enchant": clickSlotEnchant,
        ".gem": clickSlotGem,
        ".reforge": clickSlotReforge
      }));
      $(".slots, .popup").mouseover($.delegate({
        ".tt": ttlib.requestTooltip
      })).mouseout($.delegate({
        ".tt": ttlib.hide
      }));
      $(".popup .body").bind("mousewheel", function(event) {
        if ((event.wheelDelta < 0 && this.scrollTop + this.clientHeight >= this.scrollHeight) || event.wheelDelta > 0 && this.scrollTop === 0) {
          event.preventDefault();
          return false;
        }
      });
      $("#gear .slots").mousemove(function(e) {
        $.data(document, "mouse-x", e.pageX);
        return $.data(document, "mouse-y", e.pageY);
      });
      defaultScale = {
        Intellect: -1000000,
        Spirit: -1000000,
        Is2HMace: -1000000,
        IsPolearm: -1000000,
        Is2HSword: -1000000,
        IsShield: -1000000,
        SpellPower: -1000000,
        IsStaff: -1000000,
        IsFrill: -1000000,
        IsCloth: -1000000,
        IsMail: -1000000,
        IsPlate: -1000000,
        IsRelic: -1000000,
        Ap: 1,
        IsWand: -1000000,
        SpellPenetration: -1000000,
        GemQualityLevel: 85,
        MetaGemQualityLevel: 86,
        SpeedBaseline: 2
      };
      $("#getPawnString").click(function() {
        var name, pawnstr, scale, stats, val, weight;
        scale = _.extend({}, defaultScale);
        scale.ExpertiseRating = Weights.expertise_rating;
        scale.CritRating = Weights.crit_rating;
        scale.HasteRating = Weights.haste_rating;
        scale.HitRating = getHitEP();
        scale.Agility = Weights.agility;
        scale.Strength = Weights.strength;
        scale.MainHandDps = Shadowcraft.lastCalculation.mh_ep.mh_dps;
        scale.MainHandSpeed = (Shadowcraft.lastCalculation.mh_speed_ep["mh_2.7"] - Shadowcraft.lastCalculation.mh_speed_ep["mh_2.6"]) * 10;
        scale.OffHandDps = Shadowcraft.lastCalculation.oh_ep.oh_dps;
        scale.OffHandSpeed = (Shadowcraft.lastCalculation.oh_speed_ep["oh_1.4"] - Shadowcraft.lastCalculation.oh_speed_ep["oh_1.3"]) * 10;
        scale.IsMace = racialExpertiseBonus(null, 4);
        scale.IsSword = racialExpertiseBonus(null, 7);
        scale.IsDagger = racialExpertiseBonus(null, 15);
        scale.IsAxe = racialExpertiseBonus(null, 0);
        scale.IsFist = racialExpertiseBonus(null, 13);
        scale.MetaSocketEffect = Shadowcraft.lastCalculation.meta.chaotic_metagem;
        stats = [];
        for (weight in scale) {
          val = scale[weight];
          stats.push("" + weight + "=" + val);
        }
        name = "Rogue: " + ShadowcraftTalents.GetPrimaryTreeName();
        pawnstr = "(Pawn:v1:\"" + name + "\":" + (stats.join(",")) + ")";
        $("#generalDialog").html("<textarea style='width: 450px; height: 300px;'>" + pawnstr + "</textarea>").attr("title", "Pawn Import String");
        $("#generalDialog").dialog({
          modal: true,
          width: 500
        });
        return false;
      });
      $altslots.click($.delegate({
        ".slot": function(e) {
          var $this, EnchantLookup, Gems, ItemLookup, data, gem_id, item_id, slot, update, val;
          ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
          EnchantLookup = Shadowcraft.ServerData.ENCHANT_LOOKUP;
          Gems = Shadowcraft.ServerData.GEM_LOOKUP;
          data = Shadowcraft.Data;
          slot = $.data(document.body, "selecting-slot");
          update = $.data(document.body, "selecting-prop");
          $this = $(this);
          if (update === "item_id" || update === "enchant") {
            val = parseInt($this.attr("id"), 10);
            data.gear[slot][update] = val !== 0 ? val : null;
            if (update === "item_id") {
              data.gear[slot].reforge = null;
            } else {
              Shadowcraft.Console.log("Changing " + ItemLookup[data.gear[slot].item_id].name + " enchant to " + EnchantLookup[val].name);
            }
          } else if (update === "gem") {
            item_id = parseInt($this.attr("id"), 10);
            gem_id = $.data(document.body, "gem-slot");
            Shadowcraft.Console.log("Regemming " + ItemLookup[data.gear[slot].item_id].name + " socket " + (gem_id + 1) + " to " + Gems[item_id].name);
            data.gear[slot]["g" + gem_id] = item_id;
          }
          Shadowcraft.update();
          return app.updateDisplay();
        }
      }));
      $("#reforge").change($.delegate({
        ".oldstats input": function() {
          var amt, item, max, src;
          item = $.data(document.body, "reforge-item");
          src = $(this).val();
          amt = reforgeAmount(item, src);
          max = 0;
          return $("#reforge .pct").each(function() {
            var $this, c, ep, target;
            $this = $(this);
            target = $this.closest(".stat").attr("data-stat");
            c = compactReforge("expertise_rating", "hit_rating");
            ep = Math.abs(reforgeEp(compactReforge(src, target), item));
            if (ep > max) {
              return max = ep;
            }
          }).each(function() {
            var $this, ep, inner, target, width;
            $this = $(this);
            target = $this.closest(".stat").attr("data-stat");
            ep = reforgeEp(compactReforge(src, target), item);
            width = Math.abs(ep) / max * 50;
            inner = $this.find(".pct-inner");
            inner.removeClass("reverse");
            $this.find(".label").text(ep.toFixed(1));
            if (ep < 0) {
              inner.addClass("reverse");
            }
            inner.css({
              width: width + "%"
            });
            return $this.hide().fadeIn('normal');
          });
        }
      }));
      this.updateDisplay();
      $("input.search").keydown(function(e) {
        var $this, body, height, i, next, ot, slot, slots, _len, _len2;
        $this = $(this);
        $popup = $this.closest(".popup");
        switch (e.keyCode) {
          case 27:
            $this.val("").blur().keyup();
            e.cancelBubble = true;
            e.stopPropagation();
            break;
          case 38:
            slots = $popup.find(".slot:visible");
            for (i = 0, _len = slots.length; i < _len; i++) {
              slot = slots[i];
              if (slot.className.indexOf("active") !== -1) {
                if (slots[i - 1] != null) {
                  next = $(slots[i - 1]);
                  break;
                } else {
                  next = $popup.find(".slot:visible").last();
                  break;
                }
              }
            }
            break;
          case 40:
            slots = $popup.find(".slot:visible");
            for (i = 0, _len2 = slots.length; i < _len2; i++) {
              slot = slots[i];
              if (slot.className.indexOf("active") !== -1) {
                if (slots[i + 1] != null) {
                  next = $(slots[i + 1]);
                  break;
                } else {
                  next = $popup.find(".slot:visible").first();
                  break;
                }
              }
            }
            break;
          case 13:
            $popup.find(".active").click();
            return;
        }
        if (next) {
          $popup.find(".slot").removeClass("active");
          next.addClass("active");
          ot = next.get(0).offsetTop;
          height = $popup.height();
          body = $popup.find(".body");
          if (ot > body.scrollTop() + height - 30) {
            return body.animate({
              scrollTop: next.get(0).offsetTop - height + next.height() + 30
            }, 150);
          } else if (ot < body.scrollTop()) {
            return body.animate({
              scrollTop: next.get(0).offsetTop - 30
            }, 150);
          }
        }
      }).keyup(function(e) {
        var $this, all, hide, popup, search, show;
        $this = $(this);
        popup = $this.parents(".popup");
        search = $.trim($this.val().toLowerCase());
        all = popup.find(".slot");
        show = all.filter(":regex(data-search, " + search + ")");
        hide = all.not(show);
        show.removeClass("hidden");
        return hide.addClass("hidden");
      });
      reset = function() {
        $(".popup:visible").removeClass("visible");
        ttlib.hide();
        return $slots.find(".active").removeClass("active");
      };
      $("body").click(reset).keydown(function(e) {
        if (e.keyCode === 27) {
          return reset();
        }
      });
      $("#filter, #reforge").click(function(e) {
        e.cancelBubble = true;
        return e.stopPropagation();
      });
      return this;
    };
    function ShadowcraftGear(app) {
      this.app = app;
    }
    return ShadowcraftGear;
  })();
  ShadowcraftTiniReforgeBackend = (function() {
    var ENGINE, REFORGABLE, deferred;
    ENGINE = "http://shadowref.appspot.com/calc";
    REFORGABLE = ["spirit", "dodge_rating", "parry_rating", "hit_rating", "crit_rating", "haste_rating", "expertise_rating", "mastery_rating"];
    deferred = null;
    function ShadowcraftTiniReforgeBackend(gear) {
      this.gear = gear;
    }
    ShadowcraftTiniReforgeBackend.prototype.request = function(req) {
      deferred = $.Deferred();
      wait('Optimizing reforges...');
      Shadowcraft.Console.log("Starting reforge optimization...", "gold underline");
      if ($.browser.msie && window.XDomainRequest) {
        this.request_via_xdr(req);
      } else {
        this.request_via_ajax(req);
      }
      return deferred.promise();
    };
    ShadowcraftTiniReforgeBackend.prototype.request_via_xdr = function(req) {
      var xdr;
      xdr = new XDomainRequest();
      xdr.open("post", ENGINE);
      xdr.send(JSON.stringify(req));
      xdr.onload = function() {
        var data;
        data = JSON.parse(xdr.responseText);
        Shadowcraft.Gear.setReforges(data);
        return deferred.resolve();
      };
      xdr.onerror(function() {
        return flash("Error contacting reforging service");
      });
      return xdr.ontimeout(function() {
        return flash("Timed out talking to reforging service");
      });
    };
    ShadowcraftTiniReforgeBackend.prototype.request_via_ajax = function(req) {
      return $.ajax({
        type: "POST",
        url: "http://shadowref.appspot.com/calc",
        data: json_encode(req),
        complete: function() {
          return deferred.resolve();
        },
        success: function(data) {
          return Shadowcraft.Gear.setReforges(data);
        },
        error: function(xhr, textStatus, error) {
          return flash(textStatus);
        },
        dataType: "json",
        contentType: "application/json"
      });
    };
    ShadowcraftTiniReforgeBackend.prototype.buildRequest = function() {
      var ItemLookup, caps, items, k, req, stats, v;
      ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
      stats = this.gear.sumStats(true);
      items = _.map(Shadowcraft.Data.gear, function(e) {
        var key, r, val, _ref;
        r = {
          id: e.item_id
        };
        if (ItemLookup[e.item_id]) {
          _ref = ItemLookup[e.item_id].stats;
          for (key in _ref) {
            val = _ref[key];
            if (REFORGABLE.indexOf(key) !== -1) {
              r[key] = val;
            }
          }
        }
        return r;
      });
      items = _.select(items, function(i) {
        var k, v;
        for (k in i) {
          v = i[k];
          if (REFORGABLE.indexOf(k) !== -1) {
            return true;
          }
        }
        return false;
      });
      caps = this.gear.getCaps();
      for (k in caps) {
        v = caps[k];
        caps[k] = Math.ceil(v);
      }
      req = {
        items: items,
        ep: this.gear.getWeights(),
        cap: caps,
        ratings: stats
      };
      return this.request(req).then(function() {
        $("#wait").hide();
        return Shadowcraft.Console.log("Finished reforge optimization!", "gold underline");
      });
    };
    return ShadowcraftTiniReforgeBackend;
  })();
  ShadowcraftDpsGraph = (function() {
    function ShadowcraftDpsGraph() {
      var app;
      this.dpsHistory = [];
      this.snapshotHistory = [];
      this.dpsIndex = 0;
      app = this;
      $("#dps .inner").html("--- DPS");
      Shadowcraft.Backend.bind("recompute", function(data) {
        return app.datapoint(data);
      });
      $("#dpsgraph").bind("plothover", function(event, pos, item) {
        if (item) {
          return tooltip({
            title: item.datapoint[1].toFixed(2) + " DPS",
            "class": 'small clean'
          }, item.pageX, item.pageY, 15, -5);
        } else {
          return $("#tooltip").hide();
        }
      });
      $("#dpsgraph").bind("plotclick", function(event, pos, item) {
        var snapshot;
        if (item) {
          app.dpsPlot.unhighlight();
          app.dpsPlot.highlight(item.series, item.datapoint);
          snapshot = app.snapshotHistory[item.dataIndex - 1];
          return Shadowcraft.History.loadSnapshot(snapshot);
        }
      }).mousedown(function(e) {
        switch (e.button) {
          case 2:
            return false;
        }
      });
    }
    ShadowcraftDpsGraph.prototype.datapoint = function(data) {
      var delta, deltatext, snapshot;
      if (data.total_dps !== this.lastDPS) {
        snapshot = Shadowcraft.History.takeSnapshot();
        delta = data.total_dps - (this.lastDPS || 0);
        deltatext = "";
        if (this.lastDPS) {
          deltatext = delta >= 0 ? " <em class='p'>(+" + (delta.toFixed(1)) + ")</em>" : " <em class='n'>(" + (delta.toFixed(1)) + ")</em>";
        }
        $("#dps .inner").html(data.total_dps.toFixed(1) + " DPS" + deltatext);
        if (snapshot) {
          this.dpsHistory.push([this.dpsIndex, Math.floor(data.total_dps * 10) / 10]);
          this.dpsIndex++;
          this.snapshotHistory.push(snapshot);
          if (this.dpsHistory.length > 100) {
            this.dpsHistory.shift();
            this.snapshotHistory.shift();
          }
          this.dpsPlot = $.plot($("#dpsgraph"), [this.dpsHistory], {
            lines: {
              show: true
            },
            crosshair: {
              mode: "y"
            },
            points: {
              show: true
            },
            grid: {
              hoverable: true,
              clickable: true,
              autoHighlight: true
            },
            series: {
              threshold: {
                below: this.dpsHistory[0][1],
                color: "rgb(200, 20, 20)"
              }
            }
          });
        }
        return this.lastDPS = data.total_dps;
      }
    };
    return ShadowcraftDpsGraph;
  })();
  ShadowcraftConsole = (function() {
    function ShadowcraftConsole() {
      this.$log = $("#log .inner");
      this.console = $("#console");
      this.consoleInner = $("#console .inner");
    }
    ShadowcraftConsole.prototype.boot = function() {
      return $("#console .inner, #log .inner").oneFingerScroll();
    };
    ShadowcraftConsole.prototype.log = function(msg, klass) {
      return this.$log.prepend("<div class='" + klass + "'}>" + msg + "</div");
    };
    ShadowcraftConsole.prototype.warn = function(item, msg, submsg, klass, section) {
      return this.consoleMessage(item, msg, submsg, "warning", klass, section);
    };
    ShadowcraftConsole.prototype.consoleMessage = function(item, msg, submsg, severity, klass, section) {
      var fullMsg;
      fullMsg = Templates.log({
        name: item.name,
        quality: item.quality,
        message: msg,
        submsg: submsg,
        severity: severity,
        messageClass: klass,
        section: section
      });
      this.console.show();
      return this.consoleInner.append(fullMsg);
    };
    ShadowcraftConsole.prototype.hide = function() {
      return this.console.hide();
    };
    ShadowcraftConsole.prototype.remove = function(selector) {
      return this.consoleInner.remove(selector);
    };
    ShadowcraftConsole.prototype.clear = function() {
      return this.consoleInner.empty();
    };
    return ShadowcraftConsole;
  })();
  window.Shadowcraft = new ShadowcraftApp;
}).call(this);
