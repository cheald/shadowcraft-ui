(function() {
  var $, NOOP, ShadowcraftApp, ShadowcraftBackend, ShadowcraftConsole, ShadowcraftGear, ShadowcraftHistory, ShadowcraftOptions, ShadowcraftTalents, Templates, checkForWarnings, deepCopy, flash, hideFlash, json_encode, loadingSnapshot, showPopup, titleize, tooltip;
  $ = window.jQuery;
  ShadowcraftApp = (function() {
    var RATING_CONVERSIONS;
    function ShadowcraftApp() {}
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
    ShadowcraftApp.prototype.boot = function(uuid, Data, ServerData) {
      var _base, _base2;
      this.uuid = uuid;
      this.Data = Data;
      this.ServerData = ServerData;
      this.Data = $.jStorage.get(uuid, this.Data);
      (_base = this.Data).options || (_base.options = {});
      (_base2 = this.Data).weights || (_base2.weights = {
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
      });
      ShadowcraftApp.trigger("boot");
      this.Console = new ShadowcraftConsole(this);
      this.History = new ShadowcraftHistory(this).boot();
      this.Backend = new ShadowcraftBackend(this).boot();
      this.Talents = new ShadowcraftTalents(this);
      this.Options = new ShadowcraftOptions(this).boot();
      this.Gear = new ShadowcraftGear(this).boot();
      this.Talents.boot();
      this.commonInit();
      if (window.FLASH.length > 0) {
        setTimeout(function() {
          return flash("<p>" + (window.FLASH.join('</p><p>')) + "</p>");
        }, 1000);
      }
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
      $("body").append("<div id='wait' style='display: none'></div>");
      $(".showWait").click(function() {
        return $("#wait").fadeIn();
      });
      $("#reloadAllData").click(function() {
        if (confirm("Reload all data? This will wipe out all changes.")) {
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
    var i, len, out, _i, _len;
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
      for (_i = 0, _len = obj.length; _i < _len; _i++) {
        i = obj[_i];
        out[i] = arguments.callee(obj[i]);
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
      talentContribution: Handlebars.compile($("#template-talent_contribution").html())
    };
  });
  ShadowcraftBackend = (function() {
    var HTTP_ENGINE, WS_ENGINE;
    HTTP_ENGINE = "http://cheald.homedns.org:8880/";
    WS_ENGINE = "ws://cheald.homedns.org:8880/engine";
    function ShadowcraftBackend(app) {
      this.app = app;
      this.app.Backend = this;
      this.dpsHistory = [];
      this.snapshotHistory = [];
      this.dpsIndex = 0;
      _.extend(this, Backbone.Events);
    }
    ShadowcraftBackend.prototype.boot = function() {
      var self;
      self = this;
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
      var Gems, GlyphLookup, ItemLookup, Talents, buffList, data, g, gear_ids, glyph, glyph_list, k, key, mh, oh, payload, rotation_options, statSum, statSummary, th, val, _i, _len, _ref, _ref2, _ref3;
      data = Shadowcraft.Data;
      ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
      Talents = Shadowcraft.ServerData.TALENTS;
      statSum = Shadowcraft.Gear.statSum;
      Gems = Shadowcraft.ServerData;
      GlyphLookup = Shadowcraft.ServerData.GLYPH_LOOKUP;
      statSummary = Shadowcraft.Gear.sumStats();
      mh = ItemLookup[data.gear[15].item_id];
      oh = ItemLookup[data.gear[16].item_id];
      th = ItemLookup[data.gear[17].item_id];
      glyph_list = [];
      _ref = data.glyphs;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        glyph = _ref[_i];
        glyph_list.push(GlyphLookup[glyph].ename);
      }
      buffList = [];
      _ref2 = data.options.buffs;
      for (key in _ref2) {
        val = _ref2[key];
        if (val) {
          buffList.push(ShadowcraftOptions.buffMap.indexOf(key));
        }
      }
      rotation_options = null;
      if (data.tree0 >= 31) {
        rotation_options = data.options["rotation-mutilate"];
      } else if (data.tree1 >= 31) {
        rotation_options = data.options["rotation-combat"];
      } else if (data.tree2 >= 31) {
        rotation_options = data.options["rotation-subtlety"];
      }
      payload = {
        r: data.options.general.race,
        l: data.options.general.level,
        b: buffList,
        ro: rotation_options,
        settings: {
          mh_poison: data.options.general.mh_poison,
          oh_poison: data.options.general.oh_poison,
          duration: data.options.general.duration
        },
        t: [data.activeTalents.substr(0, Talents[0].talent.length), data.activeTalents.substr(Talents[0].talent.length, Talents[1].talent.length), data.activeTalents.substr(Talents[0].talent.length + Talents[1].talent.length, Talents[2].talent.length)],
        mh: [mh.speed, mh.dps * mh.speed, data.gear[15].enchant, mh.subclass],
        oh: [oh.speed, oh.dps * oh.speed, data.gear[16].enchant, oh.subclass],
        th: [th.speed, th.dps * th.speed, data.gear[17].enchant, th.subclass],
        sta: [statSummary.strength || 0, statSummary.agility || 0, statSummary.attack_power || 0, statSummary.crit_rating || 0, statSummary.hit_rating || 0, statSummary.expertise_rating || 0, statSummary.haste_rating || 0, statSummary.mastery_rating || 0],
        gly: glyph_list,
        pro: data.options.professions
      };
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
      var delta, deltatext, dpsPlot, loadingSnapshot, snapshot;
      Shadowcraft.Console.remove(".error");
      if (data.error) {
        Shadowcraft.Console.warn({}, data.error, null, "error", "error");
        return;
      }
      if (data.total_dps !== this.lastDPS && !loadingSnapshot) {
        snapshot = Shadowcraft.History.takeSnapshot();
      }
      this.app.lastCalculation = data;
      this.trigger("recompute", data);
      if (data.total_dps !== this.lastDPS || loadingSnapshot) {
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
          if (this.dpsHistory.length > 30) {
            this.dpsHistory.shift();
            this.snapshotHistory.shift();
          }
          dpsPlot = $.plot($("#dpsgraph"), [this.dpsHistory], {
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
            }
          });
        }
        this.lastDPS = data.total_dps;
      }
      return loadingSnapshot = false;
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
      var xdr;
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
    var DATA_VERSION, base36Decode, base36Encode, compress, compress_handlers, decompress, decompress_handlers, recompute;
    DATA_VERSION = 1;
    function ShadowcraftHistory(app) {
      this.app = app;
      this.app.History = this;
      Shadowcraft.Reset = this.reset;
      $("#dpsgraph").bind("plotclick", function(event, pos, item) {
        if (item) {
          dpsPlot.unhighlight();
          dpsPlot.highlight(item.series, item.datapoint);
          return loadSnapshot(snapshotHistory[item.dataIndex]);
        }
      }).mousedown(function(e) {
        switch (e.button) {
          case 2:
            return false;
        }
      });
    }
    ShadowcraftHistory.prototype.boot = function() {
      var app;
      app = this;
      $("#tabs").tabs({
        show: function(event, ui) {
          if (ui.tab.hash === "#impex") {
            return app.buildExport();
          }
        }
      });
      return this;
    };
    recompute = function() {
      return Shadowcraft.Backend.recompute();
    };
    ShadowcraftHistory.prototype.saveData = function() {
      var cancelRecompute;
      if (this.app.Data != null) {
        $.jStorage.set(this.app.uuid, this.app.Data);
      }
      if (this.recomputeTimeout) {
        this.recomputeTimeout = clearTimeout(this.recomputeTimeout);
      }
      cancelRecompute = true;
      return this.recomputeTimeout = setTimeout(recompute, 50);
    };
    ShadowcraftHistory.prototype.reset = function() {
      if (confirm("This will wipe out any changes you've made. Proceed?")) {
        $.jStorage.deleteKey(uuid);
        return window.location.reload();
      }
    };
    ShadowcraftHistory.prototype.takeSnapshot = function() {
      return deepCopy(this.app.Data);
    };
    ShadowcraftHistory.prototype.loadSnapshot = function(snapshot) {
      this.app.Data = deepCopy(snapshot);
      loadingSnapshot = true;
      return Shadowcraft.updateView();
    };
    ShadowcraftHistory.prototype.buildExport = function() {
      return $("#export").text(json_encode(compress(Shadowcraft.Data)));
    };
    base36Encode = function(r) {
      var i, v, _len;
      for (i = 0, _len = r.length; i < _len; i++) {
        v = r[i];
        if (v === 0) {
          r[i] = "";
        } else {
          r[i] = v.toString(36);
        }
      }
      return r.join(":");
    };
    base36Decode = function(s) {
      var r, v, _i, _len, _ref;
      r = [];
      _ref = s.split(":");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        v = _ref[_i];
        if (v === "") {
          r.push(0);
        } else {
          r.push(parseInt(v, 36));
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
    compress_handlers = {
      "1": function(data) {
        var buff, buffs, gear, gearSet, general, index, options, ret, set, slot, talentSet, talents, v, _i, _len, _len2, _ref, _ref2;
        ret = [DATA_VERSION];
        gearSet = [];
        for (slot = 0; slot <= 17; slot++) {
          gear = data.gear[slot];
          gearSet.push(gear.item_id);
          gearSet.push(gear.enchant || 0);
          gearSet.push(gear.reforge || 0);
          gearSet.push(gear.g0 || 0);
          gearSet.push(gear.g1 || 0);
          gearSet.push(gear.g2 || 0);
        }
        ret.push(base36Encode(gearSet));
        ret.push(ShadowcraftTalents.encodeTalents(data.activeTalents));
        ret.push(data.glyphs);
        options = [];
        options.push(data.options.professions);
        general = [data.options.general.level, data.options.general.race, data.options.general.duration, data.options.general.mh_poison, data.options.general.oh_poison, data.options.general.potion_of_the_tolvir];
        options.push(general);
        buffs = [];
        _ref = ShadowcraftOptions.buffMap;
        for (index = 0, _len = _ref.length; index < _len; index++) {
          buff = _ref[index];
          v = data.options.buffs[buff];
          buffs.push(v ? 1 : 0);
        }
        options.push(buffs);
        if (data.tree0 >= 31) {
          options.push(data.options["rotation-mutilate"]);
        } else if (data.tree1 >= 31) {
          options.push(data.options["rotation-combat"]);
        } else if (data.tree2 >= 31) {
          options.push(data.options["rotation-subtlety"]);
        }
        ret.push(options);
        talents = [];
        _ref2 = data.talents;
        for (_i = 0, _len2 = _ref2.length; _i < _len2; _i++) {
          set = _ref2[_i];
          talentSet = base36Encode(_.clone(set.glyphs || []));
          talents.push(talentSet);
          talents.push(ShadowcraftTalents.encodeTalents(set.talents));
        }
        ret.push(talents);
        ret.push(data.active);
        console.log(ret);
        console.log(decompress(ret));
        return ret;
      }
    };
    decompress_handlers = {
      "1": function(data) {
        var d, gear, general, i, id, index, k, options, set, slot, talents, v, _len, _len2, _len3, _ref, _ref2;
        d = {
          gear: {},
          activeTalents: ShadowcraftTalents.decodeTalents(data[2]),
          glyphs: data[3],
          options: {},
          talents: [],
          active: data[6]
        };
        gear = base36Decode(data[1]);
        console.log(gear);
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
        d.options.professions = options[0];
        general = options[1];
        d.options.general = {
          level: general[0],
          race: general[1],
          duration: general[2],
          mh_poison: general[3],
          oh_poison: general[4],
          potion_of_the_volvir: general[5]
        };
        d.options.buffs = {};
        _ref2 = options[2];
        for (i = 0, _len2 = _ref2.length; i < _len2; i++) {
          v = _ref2[i];
          d.options.buffs[ShadowcraftOptions.buffMap[i]] = v === 1;
        }
        talents = data[5];
        for (index = 0, _len3 = talents.length; index < _len3; index += 2) {
          set = talents[index];
          d.talents.push({
            glyphs: base36Decode(set),
            talents: ShadowcraftTalents.decodeTalents(talents[index + 1])
          });
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
  tooltip = function(data, x, y) {
    var tip;
    tip = $("#tooltip");
    if (!tip || tip.length === 0) {
      tip = $("<div id='tooltip'></div>");
      $(document.body).append(tip);
    }
    tip.html(Templates.tooltip(data));
    x || (x = $.data(document, "mouse-x"));
    y || (y = $.data(document, "mouse-y"));
    return tip.css({
      top: y,
      left: x
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
    var changeCheck, changeInput, changeOption, changeSelect;
    ShadowcraftOptions.buffMap = ['short_term_haste_buff', 'stat_multiplier_buff', 'crit_chance_buff', 'all_damage_buff', 'melee_haste_buff', 'attack_power_buff', 'str_and_agi_buff', 'armor_debuff', 'physical_vulnerability_debuff', 'spell_damage_debuff', 'spell_crit_debuff', 'bleed_damage_debuff', 'agi_flask', 'guild_feast'];
    ShadowcraftOptions.prototype.setup = function(selector, namespace, checkData) {
      var data, exist, inputType, key, ns, opt, options, s, template, templateOptions, val, _i, _k, _len, _ref, _ref2, _v;
      data = Shadowcraft.Data;
      s = $(selector);
      for (key in checkData) {
        opt = checkData[key];
        ns = data.options[namespace];
        if (!ns) {
          data.options[namespace] = {};
          ns = data.options[namespace];
        }
        val = data.options[namespace][key];
        if (val === void 0 && (opt["default"] != null)) {
          data.options[namespace][key] = opt["default"];
          val = opt["default"];
        }
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
          'default': 85
        },
        race: {
          type: "select",
          options: ["Human", "Dwarf", "Orc", "Blood Elf", "Gnome", "Worgen", "Troll", "Night Elf", "Undead"],
          name: "Race",
          'default': "Human"
        },
        duration: {
          type: "input",
          name: "Fight Duration",
          'default': 600
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
          'default': true
        },
        agi_flask: {
          name: "Agility Flask",
          desc: "Flask of the Wind/Flask of Battle",
          'default': true
        },
        short_term_haste_buff: {
          name: "+30% Haste/45 sec",
          desc: "Heroism/Bloodlust/Time Warp",
          'default': true
        },
        stat_multiplier_buff: {
          name: "5% All Stats",
          desc: "Blessing of Kings/Mark of the Wild",
          'default': true
        },
        crit_chance_buff: {
          name: "5% Crit",
          desc: "Honor Among Thieves/Leader of the Pack/Rampage/Elemental Oath",
          'default': true
        },
        all_damage_buff: {
          name: "3% All Damage",
          desc: "Arcane Tactics/Ferocious Inspiration/Communion",
          'default': true
        },
        melee_haste_buff: {
          name: "10% Haste",
          desc: "Hunting Party/Windfury Totem/Icy Talons",
          'default': true
        },
        attack_power_buff: {
          name: "10% Attack Power",
          desc: "Abomination's Might/Blessing of Might/Trueshot Aura/Unleashed Rage",
          'default': true
        },
        str_and_agi_buff: {
          name: "Agility",
          desc: "Strength of Earth/Battle Shout/Horn of Winter/Roar of Courage",
          'default': true
        }
      });
      this.setup("#settings #targetDebuffs", "buffs", {
        armor_debuff: {
          name: "-12% Armor",
          desc: "Sunder Armor/Faerie Fire/Expose Armor",
          'default': true
        },
        physical_vulnerability_debuff: {
          name: "+4% Physical Damage",
          desc: "Savage Combat/Trauma/Brittle Bones",
          'default': true
        },
        spell_damage_debuff: {
          name: "+8% Spell Damage",
          desc: "Curse of the Elements/Earth and Moon/Master Poisoner/Ebon Plaguebringer",
          'default': true
        },
        spell_crit_debuff: {
          name: "+5% Spell Crit",
          desc: "Critical Mass/Shadow and Flame",
          'default': true
        },
        bleed_damage_debuff: {
          name: "+30% Bleed Damage",
          desc: "Blood Frenzy/Mangle/Hemorrhage",
          'default': true
        }
      });
      this.setup("#settings #raidOther", "general", {
        potion_of_the_tolvir: {
          name: "Use Potion of the Tol'vir",
          'default': true
        }
      });
      this.setup("#settings section.mutilate .settings", "rotation-mutilate", {
        min_envenom_size_mutilate: {
          type: "select",
          name: "Min CP/Envenom > 35%",
          options: [5, 4, 3, 2, 1],
          'default': 4,
          desc: "Use Envenom at this many combo points, when your primary CP builder is Mutilate"
        },
        min_envenom_size_backstab: {
          type: "select",
          name: "Min CP/Envenom < 35%",
          options: [5, 4, 3, 2, 1],
          'default': 5,
          desc: "Use Envenom at this many combo points, when your primary CP builder is Backstab"
        },
        prioritize_rupture_uptime_mutilate: {
          name: "Prioritize Rupture (>35%)",
          right: true,
          desc: "Prioritize Rupture over Envenom when your CP builder is Mutilate",
          "default": true
        },
        prioritize_rupture_uptime_backstab: {
          name: "Prioritize Rupture (<35%)",
          right: true,
          desc: "Prioritize Rupture over Envenom when your CP builder is Backstab",
          "default": true
        }
      });
      this.setup("#settings section.combat .settings", "rotation-combat", {
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
          'default': 'false'
        },
        use_revealing_strike: {
          type: "select",
          name: "Revealing Strike",
          options: {
            "always": "Use for every finisher",
            "sometimes": "Only use at 4CP",
            "never": "Never use"
          },
          'default': "sometimes"
        }
      });
      return this.setup("#settings section.subtlety .settings", "rotation-subtlety", {
        clip_recuperate: "Clip Recuperate?"
      });
    };
    changeOption = function(elem, val) {
      var $this, data, name, ns, _base;
      $this = $(elem);
      data = Shadowcraft.Data;
      ns = elem.attr("data-ns") || "root";
      (_base = data.options)[ns] || (_base[ns] = {});
      name = $this.attr("name");
      if (val === void 0) {
        val = $this.val();
      }
      data.options[ns][name] = val;
      return Shadowcraft.History.saveData();
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
      this.initOptions();
      if (!window.Touch) {
        $("#settings select").selectmenu({
          style: 'dropdown'
        });
      }
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
    var DEFAULT_SPECS, MAX_TALENT_POINTS, TREE_SIZE, applyTalentToButton, getSpecFromString, getTalents, hoverTalent, majorGlyphCount, resetTalents, setTalents, sumDigits, talentMap, talentsSpent, toggleGlyph, updateGlyphWeights, updateTalentAvailability, updateTalentContribution;
    talentsSpent = 0;
    MAX_TALENT_POINTS = 41;
    TREE_SIZE = [19, 19, 19];
    DEFAULT_SPECS = {
      "Stock Assassination": "033323011302211032100200000000000000002030030000000000000",
      "Stock Combat": "023200000000000000023322303100300123210030000000000000000",
      "Stock Subtlety": "023003000000000000000200000000000000000332031321310012321"
    };
    talentMap = "0zMcmVokRsaqbdrfwihuGINALpTjnyxtgevElBCDFHJKOPQSUWXYZ123456789";
    ShadowcraftTalents.encodeTalents = function(s) {
      var c, i, index, l, offset, size, str, sub, _len, _len2;
      str = "";
      console.log("parsing string", s);
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
      console.log(s, str, ShadowcraftTalents.decodeTalents(str));
      return str;
    };
    ShadowcraftTalents.decodeTalents = function(s) {
      var a, b, char, i, idx, index, talents, tree, trees, treestr, _len, _ref;
      trees = s.split("Z");
      talents = "";
      for (index = 0, _len = trees.length; index < _len; index++) {
        tree = trees[index];
        treestr = "";
        for (i = 0, _ref = Math.floor(TREE_SIZE[index] / 2); (0 <= _ref ? i <= _ref : i >= _ref); (0 <= _ref ? i += 1 : i -= 1)) {
          char = tree[i];
          if (char) {
            idx = talentMap.indexOf(char);
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
      return Shadowcraft.History.saveData();
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
      }, pos.left + 130, pos.top - 20);
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
              Shadowcraft.History.saveData();
            }
            break;
          case 2:
            if (applyTalentToButton(this, -1)) {
              Shadowcraft.History.saveData();
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
            return Shadowcraft.History.saveData();
          }
        }
      });
      talentframe.bind("touchstart", function(e) {
        var listening;
        listening = $.data(tframe, "listening");
        if (e.originalEvent.touches.length > 1 && listening && $.data(listening, "listening")) {
          if (applyTalentToButton.call(listening, listening, -1)) {
            Shadowcraft.History.saveData();
          }
          return $.data(listening, "removed", true);
        }
      });
      buffer = "";
      _ref = data.talents;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        talent = _ref[_i];
        buffer += Templates.talentSet({
          talent_string: talent.talents,
          glyphs: talent.glyphs.join(","),
          name: "Imported " + getSpecFromString(talent.talents)
        });
      }
      for (talentName in DEFAULT_SPECS) {
        talent = DEFAULT_SPECS[talentName];
        buffer += Templates.talentSet({
          talent_string: talent,
          name: talentName
        });
      }
      $("#talentsets").get(0).innerHTML = buffer;
      this.updateActiveTalents();
      return initTalentsPane = function() {};
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
        width = weight / max * 100;
        slot = $(".glyph_slot[data-id='" + g.id + "']");
        $.data(slot[0], "weight", weight);
        $.data(slot[0], "name", g.name);
        slot.show().find(".pct-inner").css({
          width: width + "%"
        });
        slot.find(".label").text(weight.toFixed(1) + " DPS");
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
    majorGlyphCount = function() {
      var GlyphLookup, count, data, glyph, _i, _len, _ref;
      data = Shadowcraft.Data;
      GlyphLookup = Shadowcraft.ServerData.GLYPH_LOOKUP;
      count = 0;
      _ref = data.glyphs;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        glyph = _ref[_i];
        if (GlyphLookup[glyph].rank === 3) {
          count++;
        }
      }
      return count;
    };
    toggleGlyph = function(e, override) {
      var $e, $set, GlyphLookup, data, glyph, id, major;
      GlyphLookup = Shadowcraft.ServerData.GLYPH_LOOKUP;
      data = Shadowcraft.Data;
      $e = $(e);
      $set = $e.parents(".glyphset");
      id = parseInt($e.data("id"), 10);
      glyph = GlyphLookup[id];
      major = majorGlyphCount();
      if ($e.hasClass("activated")) {
        $e.removeClass("activated");
        data.glyphs = _.without(data.glyphs, id);
        $set.removeClass("full");
      } else {
        if (major >= 3 && !override) {
          return;
        }
        $e.addClass("activated");
        if (!override && data.glyphs.indexOf(id) === -1) {
          data.glyphs.push(id);
        }
        if (majorGlyphCount() >= 3) {
          $set.addClass("full");
        }
      }
      checkForWarnings('glyphs');
      return Shadowcraft.History.saveData();
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
      this.initTalentsPane();
      this.initGlyphs();
      Shadowcraft.Backend.bind("recompute", updateTalentContribution);
      Shadowcraft.Backend.bind("recompute", updateGlyphWeights);
      $("#glyphs").click($.delegate({
        ".glyph_slot": function() {
          return toggleGlyph(this);
        }
      }));
      $("#talentsets").click($.delegate({
        ".talent_set": function() {
          return setTalents($(this).attr("data-talents"));
        }
      }));
      $("#reset_talents").click(resetTalents);
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
    var $altslots, $popup, $slots, DEFAULT_BOSS_DODGE, EP_PRE_REFORGE, EP_PRE_REGEM, EP_TOTAL, JC_ONLY_GEMS, MAX_PROFESSIONAL_GEMS, REFORGABLE, REFORGE_CONST, REFORGE_FACTOR, REFORGE_STATS, SLOT_DISPLAY_ORDER, SLOT_INVTYPES, SLOT_ORDER, addTradeskillBonuses, canReforge, canUseGem, clearReforge, clickSlot, clickSlotEnchant, clickSlotGem, clickSlotName, clickSlotReforge, compactReforge, epSort, getGemRecommendationList, getGemmingRecommendation, getProfessionalGemCount, getReforgeFrom, getReforgeTo, getRegularGemEpValue, getStatWeight, get_ep, isProfessionalGem, needsDagger, racialExpertiseBonus, racialHitBonus, recommendReforge, reforgeAmount, reforgeEp, sourceStats, statsToDesc, sumItem, sumRecommendation, sumReforge, updateStatWeights, __epSort;
    MAX_PROFESSIONAL_GEMS = 3;
    JC_ONLY_GEMS = ["Dragon's Eye", "Chimera's Eye"];
    REFORGE_FACTOR = 0.4;
    DEFAULT_BOSS_DODGE = 6.5;
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
    REFORGE_CONST = 112;
    SLOT_ORDER = ["0", "1", "2", "14", "4", "8", "9", "5", "6", "7", "10", "11", "12", "13", "15", "16", "17"];
    SLOT_DISPLAY_ORDER = [["0", "1", "2", "14", "4", "8", "15", "16"], ["9", "5", "6", "7", "10", "11", "12", "13", "17"]];
    ShadowcraftGear.CHAOTIC_METAGEMS = [52291, 34220, 41285, 68778, 68780, 41398, 32409, 68779];
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
      var c, data, stat, stats, total, value, weight, weights;
      data = Shadowcraft.Data;
      weights = data.weights;
      stats = {};
      if (item.source && item.dest) {
        sumRecommendation(stats, item);
      } else {
        sumItem(stats, item, key);
      }
      total = 0;
      for (stat in stats) {
        value = stats[stat];
        weight = data.weights[stat] || 0;
        total += value * weight;
      }
      delete stats;
      c = Shadowcraft.lastCalculation;
      if (c) {
        if (item.dps) {
          if (slot === 15) {
            total += (item.dps * c.mh_ep.mh_dps) + (item.speed * c.mh_speed_ep["mh_" + item.speed]);
            total += racialExpertiseBonus(item) * weights.expertise_rating;
          } else if (slot === 16) {
            total += (item.dps * c.oh_ep.oh_dps) + (item.speed * c.oh_speed_ep["oh_" + item.speed]);
            total += racialExpertiseBonus(item) * weights.expertise_rating;
          }
        } else if (ShadowcraftGear.CHAOTIC_METAGEMS.indexOf(item.id) >= 0) {
          total += c.meta.chaotic_metagem;
        }
      }
      if (c && c.trinket_ranking[item.id]) {
        total += c.trinket_ranking[item.id];
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
    ShadowcraftGear.prototype.sumStats = function() {
      var EnchantLookup, Gems, ItemLookup, data, enchant, enchant_id, gear, gem, gid, i, item, matchesAllSockets, si, socket, socketIndex, stats, _len, _ref;
      stats = {};
      ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
      Gems = Shadowcraft.ServerData.GEMS;
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
          if (gear.reforge) {
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
      return this.statSum = stats;
    };
    racialExpertiseBonus = function(item) {
      var mh_type, race;
      mh_type = item.subclass;
      race = Shadowcraft.Data.race;
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
    getStatWeight = function(stat, num, ignore, ignoreAll) {
      var ItemLookup, boss_dodge, data, delta, exist, expertiseCap, neg, remaining, spellHitCap, total, usable, whiteHitCap, yellowHitCap;
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
          expertiseCap = Shadowcraft._R("expertise_rating") * boss_dodge * 4;
          if (data.gear[15] && data.gear[15].item_id) {
            expertiseCap -= racialExpertiseBonus(ItemLookup[data.gear[15].item_id]);
          }
          usable = expertiseCap - exist;
          if (usable < 0) {
            usable = 0;
          }
          if (usable > num) {
            usable = num;
          }
          return data.weights.expertise_rating * usable * neg;
        case "hit_rating":
          yellowHitCap = Shadowcraft._R("hit_rating") * (8 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating");
          spellHitCap = Shadowcraft._R("spell_hit") * (17 - 2 * Shadowcraft._T("precision")) - racialHitBonus("spell_hit");
          whiteHitCap = Shadowcraft._R("hit_rating") * (27 - 2 * Shadowcraft._T("precision")) - racialHitBonus("hit_rating");
          total = 0;
          remaining = num;
          if (remaining > 0 && exist < yellowHitCap) {
            delta = (yellowHitCap - exist) > remaining ? remaining : yellowHitCap - exist;
            total += delta * data.weights.yellow_hit;
            remaining -= delta;
            exist += delta;
          }
          if (remaining > 0 && exist < spellHitCap) {
            delta = (spellHitCap - exist) > remaining ? remaining : spellHitCap - exist;
            total += delta * data.weights.spell_hit;
            remaining -= delta;
            exist += delta;
          }
          if (remaining > 0 && exist < whiteHitCap) {
            delta = (whiteHitCap - exist) > remaining ? remaining : whiteHitCap - exist;
            total += delta * data.weights.hit_rating;
            remaining -= delta;
            exist += delta;
          }
          return total * neg;
      }
      return (data.weights[stat] || 0) * num * neg;
    };
    __epSort = function(a, b) {
      return b.__ep - a.__ep;
    };
    epSort = function(list, skipSort) {
      var item, _i, _len;
      for (_i = 0, _len = list.length; _i < _len; _i++) {
        item = list[_i];
        if (item) {
          item.__ep = get_ep(item);
        }
      }
      if (!skipSort) {
        return list.sort(__epSort);
      }
    };
    needsDagger = function() {
      return Shadowcraft.Data.tree0 >= 31 || Shadowcraft.Data.tree2 >= 31;
    };
    isProfessionalGem = function(gem) {
      var _ref;
      return ((_ref = gem.requires) != null ? _ref.profession : void 0) != null;
    };
    getProfessionalGemCount = function() {
      var Gems, count, gear, k, slot, _i, _j, _len, _len2, _ref;
      count = 0;
      Gems = Shadowcraft.ServerData.GEMS;
      for (_i = 0, _len = SLOT_ORDER.length; _i < _len; _i++) {
        slot = SLOT_ORDER[_i];
        gear = Shadowcraft.Data.gear[slot];
        for (_j = 0, _len2 = gear.length; _j < _len2; _j++) {
          k = gear[_j];
          if (k.indexOf("gem" === 0 && (((_ref = Gems[gear[k]].requires) != null ? _ref.profession : void 0) != null))) {
            count++;
          }
        }
      }
      return count;
    };
    canUseGem = function(gem, gemType) {
      var jc_gem_count, _ref;
      jc_gem_count = getProfessionalGemCount();
      if ((((_ref = gem.requires) != null ? _ref.profession : void 0) != null) && !Shadowcraft.Data.options.professions[gem.requires.profession] || jc_gem_count >= MAX_PROFESSIONAL_GEMS) {
        return false;
      }
      if (gemType === "Meta" && gem.slot !== "Meta") {
        return false;
      }
      if (gemType !== "Meta" && gem.slot === "Meta") {
        return false;
      }
      if (gemType === "Cogwheel" && gem.slot !== "Cogwheel") {
        return false;
      }
      if (gemType !== "Cogwheel" && gem.slot === "Cogwheel") {
        return false;
      }
      return true;
    };
    getRegularGemEpValue = function(gem) {
      var equiv_ep, j, name, prefix, reg, _i, _len, _ref, _ref2, _ref3;
      equiv_ep = gem.__ep || get_ep(gem);
      if (((_ref = gem.requires) != null ? _ref.profession : void 0) == null) {
        return equiv_ep;
      }
      if (gem.__reg_ep) {
        return gem.__reg_ep;
      }
      for (_i = 0, _len = JC_ONLY_GEMS.length; _i < _len; _i++) {
        name = JC_ONLY_GEMS[_i];
        if (gem.name.indexOf(name) >= 0) {
          prefix = gem.name.replace(name, "");
          _ref2 = Shadowcraft.ServerData.GEM_LIST;
          for (j in _ref2) {
            reg = _ref2[j];
            if (!(((_ref3 = reg.requires) != null ? _ref3.profession : void 0) != null) && reg.name.indexOf(prefix) === 0 && reg.quality === gem.quality) {
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
    getGemmingRecommendation = function(gem_list, item, returnFull) {
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
          if (!canUseGem(gem, gemType)) {
            continue;
          }
          straightGemEP += getRegularGemEpValue(gem);
          if (returnFull) {
            sGems[sGems.length] = gem.id;
          }
          break;
        }
      }
      _ref2 = item.sockets;
      for (_k = 0, _len3 = _ref2.length; _k < _len3; _k++) {
        gemType = _ref2[_k];
        for (_l = 0, _len4 = gem_list.length; _l < _len4; _l++) {
          gem = gem_list[_l];
          if (!canUseGem(gem, gemType)) {
            continue;
          }
          if (gem[gemType]) {
            matchedGemEP += getRegularGemEpValue(gem);
            if (returnFull) {
              mGems[mGems.length] = gem.id;
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
      Gems = Shadowcraft.ServerData.GEMS;
      data = Shadowcraft.Data;
      depth || (depth = 0);
      if (depth === 0) {
        EP_PRE_REGEM = EP_TOTAL;
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
          rec = getGemmingRecommendation(gem_list, item, true);
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
        this.updateDisplay();
        return Shadowcraft.Console.log("Finished automatic regemming: &Delta; " + (Math.floor(EP_TOTAL - EP_PRE_REGEM)) + " EP", "gold");
      } else {
        return this.optimizeGems(depth + 1);
      }
    };
    getGemRecommendationList = function() {
      var Gems, list;
      Gems = Shadowcraft.ServerData.GEM_LIST;
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
    ShadowcraftGear.prototype.reforgeAll = function(depth) {
      var ItemLookup, amt, data, ep, from, gear, item, madeChanges, rec, slot, to, _i, _len;
      data = Shadowcraft.Data;
      ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
      depth || (depth = 0);
      if (depth === 0) {
        EP_PRE_REFORGE = EP_TOTAL;
        Shadowcraft.Console.log("Beginning automatic reforge...", "gold underline");
      }
      madeChanges = false;
      for (_i = 0, _len = SLOT_ORDER.length; _i < _len; _i++) {
        slot = SLOT_ORDER[_i];
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
              from = getReforgeFrom(rec);
              to = getReforgeTo(rec);
              amt = reforgeAmount(item, from);
              Shadowcraft.Console.log("Reforging " + item.name + " to <span class='neg'>-" + amt + " " + (titleize(from)) + "</span> / <span class='pos'>+" + amt + " " + (titleize(to)) + "</span>");
              madeChanges = true;
              gear.reforge = rec;
              this.sumStats();
            }
          }
        }
      }
      if (!madeChanges || depth >= 10) {
        this.updateDisplay();
        return Shadowcraft.Console.log("Finished automatic reforging: &Delta; " + Math.floor(EP_TOTAL - EP_PRE_REFORGE) + " EP", "gold");
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
      return Shadowcraft.Gear.updateDisplay();
    };
    /*
    # View helpers
    */
    ShadowcraftGear.prototype.updateDisplay = function(skipSave) {
      var EnchantLookup, EnchantSlots, Gems, ItemLookup, allSlotsMatch, amt, bonuses, buffer, data, enchant, enchantable, from, gear, gem, gems, i, item, opt, reforgable, reforge, slotIndex, slotSet, socket, ssi, stat, to, _i, _len, _len2, _len3, _ref, _ref2;
      if (!skipSave) {
        this.app.History.saveData();
      }
      this.updateStatsWindow();
      ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
      EnchantLookup = Shadowcraft.ServerData.ENCHANT_LOOKUP;
      EnchantSlots = Shadowcraft.ServerData.ENCHANT_SLOTS;
      Gems = Shadowcraft.ServerData.GEMS;
      data = Shadowcraft.Data;
      opt = {};
      for (ssi = 0, _len = SLOT_DISPLAY_ORDER.length; ssi < _len; ssi++) {
        slotSet = SLOT_DISPLAY_ORDER[ssi];
        buffer = "";
        for (slotIndex = 0, _len2 = slotSet.length; slotIndex < _len2; slotIndex++) {
          i = slotSet[slotIndex];
          gear = data.gear[i];
          if (!gear) {
            continue;
          }
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
          opt.ttid = item ? item.id : null;
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
          val: this.statSum[stat],
          ep: Math.floor(weight)
        });
      }
      EP_TOTAL = total;
      return $stats.get(0).innerHTML = Templates.stats({
        stats: a_stats
      });
    };
    updateStatWeights = function(source) {
      var $weights, Weights, data, e, exist, key, weight;
      data = Shadowcraft.Data;
      Weights = Shadowcraft.Data.weights;
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
          e = $weights.append("<div class='stat' id='weight_" + key + "'><span class='key'>" + (titleize(key)) + "</span><span class='val'>" + (data.weights[key].toFixed(2)) + "</span></div>");
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
      return epSort(Shadowcraft.ServerData.GEM_LIST);
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
      var $slot, GemList, buf, buffer, deltaEp, equip_location, iEP, l, loc, max, rec, reforgedStats, requireDagger, selected_id, slot, _i, _j, _len, _len2;
      buf = clickSlot(this, "item_id");
      $slot = buf[0];
      slot = buf[1];
      selected_id = parseInt($slot.attr("id"), 10);
      equip_location = SLOT_INVTYPES[slot];
      GemList = Shadowcraft.ServerData.GEM_LIST;
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
        iEP = l.__ep.toFixed(1);
        buffer += Templates.itemSlot({
          item: l,
          gear: {},
          gems: [],
          ttid: l.id,
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
      var EnchantSlots, buf, buffer, data, eEP, enchant, enchants, equip_location, max, selected_id, slot, _i, _len;
      data = Shadowcraft.Data;
      EnchantSlots = Shadowcraft.ServerData.ENCHANT_SLOTS;
      buf = clickSlot(this, "enchant");
      slot = buf[1];
      equip_location = SLOT_INVTYPES[slot];
      enchants = EnchantSlots[equip_location];
      epSort(enchants);
      selected_id = data.gear[slot].enchant;
      max = get_ep(enchants[0]);
      buffer = "";
      for (_i = 0, _len = enchants.length; _i < _len; _i++) {
        enchant = enchants[_i];
        if (enchant && !enchant.desc) {
          enchant.desc = statsToDesc(enchant);
        }
        eEP = get_ep(enchant);
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
      GemList = Shadowcraft.ServerData.GEM_LIST;
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
      var app, reset;
      app = this;
      $slots = $(".slots");
      $popup = $(".alternatives");
      $altslots = $(".alternatives .body");
      Shadowcraft.Backend.bind("recompute", updateStatWeights);
      Shadowcraft.Backend.bind("recompute", function() {
        return Shadowcraft.Gear.updateDisplay(true);
      });
      $("#reforgeAll").click(function() {
        return Shadowcraft.Gear.reforgeAll();
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
      $altslots.click($.delegate({
        ".slot": function(e) {
          var $this, EnchantLookup, Gems, ItemLookup, data, gem_id, item_id, slot, update, val;
          ItemLookup = Shadowcraft.ServerData.ITEM_LOOKUP;
          EnchantLookup = Shadowcraft.ServerData.ENCHANT_LOOKUP;
          Gems = Shadowcraft.ServerData.GEMS;
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
      this.updateDisplay(true);
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
