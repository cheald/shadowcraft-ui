(function() {
  var $, $doc, ArtifactTemplates, NOOP, ShadowcraftApp, ShadowcraftArtifact, ShadowcraftBackend, ShadowcraftConsole, ShadowcraftDpsGraph, ShadowcraftGear, ShadowcraftHistory, ShadowcraftOptions, ShadowcraftTalents, Templates, checkForWarnings, flash, hideFlash, json_encode, modal, showPopup, tip, titleize, tooltip, wait,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  $ = window.jQuery;

  ShadowcraftApp = (function() {
    var _update;

    ShadowcraftApp.prototype.reload = function() {
      this.Options.initOptions();
      this.Talents.updateActiveTalents();
      return this.Gear.updateDisplay();
    };

    ShadowcraftApp.prototype.setupLabels = function(selector) {
      selector || (selector = document);
      selector = $(selector);
      selector.find('.label_check input:checkbox').each(function() {
        return $(this).parent()[(($(this).attr("checked") != null) || $(this).val() === "true" ? "add" : "remove") + "Class"]('c_on');
      });
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

    ShadowcraftApp.prototype.boot = function(uuid1, region, data, ServerData) {
      var error, error1;
      this.uuid = uuid1;
      this.region = region;
      this.ServerData = ServerData;
      try {
        return this._boot(this.uuid, data, this.ServerData);
      } catch (error1) {
        error = error1;
        console.log(error);
        $("#curtain").html("<div id='loaderror'>A fatal error occurred while loading this page.</div>").show();
        wait();
        if (confirm("An unrecoverable error has occurred. Reset data and reload?")) {
          $.jStorage.flush();
          window.location.hash = "";
          return location.reload(true);
        } else {
          throw error;
        }
      }
    };

    ShadowcraftApp.prototype._boot = function(uuid1, data, ServerData) {
      var TypeError, base, error1, patch;
      this.uuid = uuid1;
      this.ServerData = ServerData;
      this.History = new ShadowcraftHistory(this).boot();
      patch = window.location.hash.match(/#reload$/);
      if (!this.History.loadFromFragment()) {
        try {
          this.Data = this.History.load(data);
          if (patch) {
            data.options = Object.deepExtend(this.Data.options, data.options);
            this.Data = _.extend(this.Data, data);
            this.Data.active = data.active;
            this.Data.activeSpec = data.activeSpec;
            this.Data.activeTalents = data.activeTalents;
          }
        } catch (error1) {
          TypeError = error1;
          this.Data = data;
        }
      }
      this.Data || (this.Data = data);
      (base = this.Data).options || (base.options = {});
      ShadowcraftApp.trigger("boot");
      this.Console = new ShadowcraftConsole(this);
      this.Backend = new ShadowcraftBackend(this).boot();
      this.Artifact = new ShadowcraftArtifact(this);
      this.Talents = new ShadowcraftTalents(this);
      this.Options = new ShadowcraftOptions(this).boot();
      this.Gear = new ShadowcraftGear(this);
      this.DpsGraph = new ShadowcraftDpsGraph(this);
      this.Artifact.boot();
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
          top = p.top + $this.height() + 5;
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
          location.hash = "";
          return location.reload(true);
        }
      });
      $(function() {
        return Shadowcraft.update();
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

  $.fn.sortElements = (function() {
    var shift, sort;
    shift = [].shift;
    sort = [].sort;
    return function(comparator) {
      var elems, parent, results;
      if (!(this && this.length > 0)) {
        return;
      }
      parent = this.get(0).parentNode;
      elems = this.detach();
      sort.call(elems, comparator);
      results = [];
      while (elems.length > 0) {
        results.push(parent.appendChild(shift.call(elems)));
      }
      return results;
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
      bonuses: Handlebars.compile($("#template-bonuses").html()),
      checkbox: Handlebars.compile($("#template-checkbox").html()),
      select: Handlebars.compile($("#template-select").html()),
      input: Handlebars.compile($("#template-input").html()),
      talentTree: Handlebars.compile($("#template-tree").html()),
      talentTier: Handlebars.compile($("#template-tier").html()),
      specActive: Handlebars.compile($("#template-specactive").html()),
      artifactActive: Handlebars.compile($("#template-artifactactive").html()),
      tooltip: Handlebars.compile($("#template-tooltip").html()),
      talentSet: Handlebars.compile($("#template-talent_set").html()),
      log: Handlebars.compile($("#template-log").html()),
      talentContribution: Handlebars.compile($("#template-talent_contribution").html()),
      loadSnapshots: Handlebars.compile($("#template-loadSnapshots").html()),
      artifact: Handlebars.compile($("#template-artifact").html())
    };
  });

  ArtifactTemplates = null;

  ShadowcraftApp.bind("boot", function() {
    return ArtifactTemplates = {
      useDreadblades: function() {
        var lines, traits;
        $("#artifactframe").css("background-image", "url('/images/artifacts/44-small.jpg')");
        traits = [
          {
            id: "db_blackpowder",
            spell_id: 216230,
            max_level: 3,
            icon: "inv_weapon_rifle_01",
            ring: "thin",
            left: 82.317,
            top: 57.571,
            is_thin: true
          }, {
            id: "db_bladedancer",
            spell_id: 202507,
            max_level: 3,
            icon: "ability_warrior_bladestorm",
            ring: "thin",
            left: 43.659,
            top: 67.143,
            is_thin: true
          }, {
            id: "db_blademaster",
            spell_id: 202628,
            max_level: 1,
            icon: "ability_warrior_challange",
            ring: "thin",
            left: 74.268,
            top: 45.714,
            is_thin: true
          }, {
            id: "db_blunderbuss",
            spell_id: 202897,
            max_level: 1,
            icon: "inv_weapon_rifle_01",
            ring: "dragon",
            left: 84.512,
            top: 22.429
          }, {
            id: "db_blurredtime",
            spell_id: 202769,
            max_level: 1,
            icon: "ability_rogue_quickrecovery",
            ring: "dragon",
            left: 85.610,
            top: 37.714
          }, {
            id: "db_curse",
            spell_id: 202665,
            max_level: 1,
            icon: "inv_sword_1h_artifactskywall_d_01dual",
            ring: "thick",
            left: 48.293,
            top: 47.429
          }, {
            id: "db_cursededges",
            spell_id: 202463,
            max_level: 1,
            icon: "inv_sword_33",
            ring: "thin",
            left: 32.195,
            top: 62.000,
            is_thin: true
          }, {
            id: "db_cursedleather",
            spell_id: 202521,
            max_level: 3,
            icon: "spell_rogue_deathfromabove",
            ring: "thin",
            left: 76.463,
            top: 33.286,
            is_thin: true
          }, {
            id: "db_deception",
            spell_id: 202755,
            max_level: 1,
            icon: "ability_rogue_disguise",
            ring: "thin",
            left: 62.927,
            top: 27.143,
            is_thin: true
          }, {
            id: "db_fatebringer",
            spell_id: 202524,
            max_level: 3,
            icon: "ability_rogue_cuttothechase",
            ring: "thin",
            left: 19.268,
            top: 60.286,
            is_thin: true
          }, {
            id: "db_fatesthirst",
            spell_id: 202514,
            max_level: 3,
            icon: "ability_rogue_waylay",
            ring: "thin",
            left: 37.805,
            top: 46.000,
            is_thin: true
          }, {
            id: "db_fortunesboon",
            spell_id: 202907,
            max_level: 3,
            icon: "ability_rogue_surpriseattack2",
            ring: "thin",
            left: 61.098,
            top: 42.286,
            is_thin: true
          }, {
            id: "db_fortunestrikes",
            spell_id: 202530,
            max_level: 3,
            icon: "ability_rogue_improvedrecuperate",
            ring: "thin",
            left: 61.098,
            top: 57.429,
            is_thin: true
          }, {
            id: "db_ghostlyshell",
            spell_id: 202533,
            max_level: 3,
            icon: "spell_shadow_nethercloak",
            ring: "thin",
            left: 5.000,
            top: 68.286,
            is_thin: true
          }, {
            id: "db_greed",
            spell_id: 202820,
            max_level: 1,
            icon: "warrior_skullbanner",
            ring: "dragon",
            left: 3.171,
            top: 86.000
          }, {
            id: "db_gunslinger",
            spell_id: 202522,
            max_level: 3,
            icon: "inv_weapon_rifle_07",
            ring: "thin",
            left: 49.878,
            top: 29.714,
            is_thin: true
          }, {
            id: "db_hiddenblade",
            spell_id: 202753,
            max_level: 1,
            icon: "ability_ironmaidens_bladerush",
            ring: "thin",
            left: 19.390,
            top: 84.429,
            is_thin: true
          }
        ];
        lines = [
          {
            width: 167,
            left: 35.610,
            top: 60.714,
            angle: 142.306,
            spell1: 202665,
            spell2: 202463
          }, {
            width: 101,
            left: 79.878,
            top: 33.857,
            angle: 130.972,
            spell1: 202897,
            spell2: 202521
          }, {
            width: 125,
            left: 1.951,
            top: 83.143,
            angle: -83.103,
            spell1: 202820,
            spell2: 202533
          }, {
            width: 142,
            left: 80.732,
            top: 53.571,
            angle: 100.993,
            spell1: 202769,
            spell2: 216230
          }, {
            width: 119,
            left: 67.927,
            top: 36.143,
            angle: 21.176,
            spell1: 202755,
            spell2: 202521
          }, {
            width: 109,
            left: 55.244,
            top: 34.429,
            angle: 170.451,
            spell1: 202755,
            spell2: 202522
          }, {
            width: 107,
            left: 60.976,
            top: 40.714,
            angle: 98.054,
            spell1: 202755,
            spell2: 202907
          }, {
            width: 169,
            left: 14.512,
            top: 78.286,
            angle: -90.339,
            spell1: 202753,
            spell2: 202524
          }, {
            width: 233,
            left: 22.805,
            top: 81.714,
            angle: -31.301,
            spell1: 202753,
            spell2: 202507
          }, {
            width: 106,
            left: 77.317,
            top: 57.571,
            angle: 51.509,
            spell1: 202628,
            spell2: 216230
          }, {
            width: 111,
            left: 66.463,
            top: 50.000,
            angle: -167.471,
            spell1: 202628,
            spell2: 202907
          }, {
            width: 174,
            left: 66.585,
            top: 63.429,
            angle: -179.671,
            spell1: 216230,
            spell2: 202530
          }, {
            width: 158,
            left: 48.171,
            top: 68.286,
            angle: -25.432,
            spell1: 202507,
            spell2: 202530
          }, {
            width: 101,
            left: 37.317,
            top: 70.571,
            angle: -159.044,
            spell1: 202507,
            spell2: 202463
          }, {
            width: 151,
            left: 40.122,
            top: 43.857,
            angle: -49.028,
            spell1: 202514,
            spell2: 202522
          }, {
            width: 182,
            left: 22.927,
            top: 59.143,
            angle: 146.659,
            spell1: 202514,
            spell2: 202524
          }, {
            width: 121,
            left: 33.171,
            top: 60.000,
            angle: 112.329,
            spell1: 202514,
            spell2: 202463
          }, {
            width: 130,
            left: 9.634,
            top: 70.286,
            angle: 154.423,
            spell1: 202524,
            spell2: 202533
          }
        ];
        return Templates.artifact({
          traits: traits,
          lines: lines,
          relic1: 'blood',
          relic2: 'iron',
          relic3: 'wind'
        });
      },
      useFangs: function() {
        var lines, traits;
        $("#artifactframe").css("background-image", "url('/images/artifacts/fangs-bg.jpg')");
        traits = [
          {
            id: "fangs_akaarissoul",
            spell_id: 209835,
            max_level: 1,
            icon: "ability_warlock_soullink",
            ring: "dragon",
            left: 74.306,
            top: 43.252
          }, {
            id: "fangs_catwalk",
            spell_id: 197241,
            max_level: 3,
            icon: "inv_pet_cats_calicocat",
            ring: "thin",
            left: 52.639,
            top: 48.455,
            is_thin: true
          }, {
            id: "fangs_demonskiss",
            spell_id: 197233,
            max_level: 3,
            icon: "ability_priest_voidentropy",
            ring: "thin",
            left: 35.278,
            top: 86.829,
            is_thin: true
          }, {
            id: "fangs_embrace",
            spell_id: 197604,
            max_level: 1,
            icon: "ability_stealth",
            ring: "thin",
            left: 68.611,
            top: 68.130,
            is_thin: true
          }, {
            id: "fangs_energetic",
            spell_id: 197239,
            max_level: 3,
            icon: "inv_knife_1h_pvppandarias3_c_02",
            ring: "thin",
            left: 32.917,
            top: 72.033,
            is_thin: true
          }, {
            id: "fangs_faster",
            spell_id: 197256,
            max_level: 1,
            icon: "ability_rogue_sprint_blue",
            ring: "thin",
            left: 51.806,
            top: 68.943,
            is_thin: true
          }, {
            id: "fangs_finality",
            spell_id: 197406,
            max_level: 1,
            icon: "ability_rogue_eviscerate",
            ring: "dragon",
            left: 16.250,
            top: 78.699
          }, {
            id: "fangs_fortunesbite",
            spell_id: 197369,
            max_level: 3,
            icon: "ability_rogue_masterofsubtlety",
            ring: "thin",
            left: 80.972,
            top: 56.911,
            is_thin: true
          }, {
            id: "fangs_ghostarmor",
            spell_id: 197244,
            max_level: 3,
            icon: "achievement_halloween_ghost_01",
            ring: "thin",
            left: 42.778,
            top: 62.114,
            is_thin: true
          }, {
            id: "fangs_goremawsbite",
            spell_id: 209782,
            max_level: 1,
            icon: "inv_knife_1h_artifactfangs_d_01",
            ring: "thick",
            left: 83.472,
            top: 21.463
          }, {
            id: "fangs_gutripper",
            spell_id: 197234,
            max_level: 3,
            icon: "ability_rogue_eviscerate",
            ring: "thin",
            left: 75.000,
            top: 31.707,
            is_thin: true
          }, {
            id: "fangs_precision",
            spell_id: 197235,
            max_level: 3,
            icon: "ability_rogue_unfairadvantage",
            ring: "thin",
            left: 53.750,
            top: 82.114,
            is_thin: true
          }, {
            id: "fangs_quietknife",
            spell_id: 197231,
            max_level: 3,
            icon: "ability_backstab",
            ring: "thin",
            left: 64.306,
            top: 58.374,
            is_thin: true
          }, {
            id: "fangs_second",
            spell_id: 197610,
            max_level: 1,
            icon: "inv_throwingknife_07",
            ring: "thin",
            left: 42.778,
            top: 76.585,
            is_thin: true
          }, {
            id: "fangs_shadowfangs",
            spell_id: 221856,
            max_level: 1,
            icon: "inv_misc_blacksaberonfang",
            ring: "thin",
            left: 91.667,
            top: 42.602,
            is_thin: true
          }, {
            id: "fangs_shadownova",
            spell_id: 209781,
            max_level: 1,
            icon: "spell_fire_twilightnova",
            ring: "dragon",
            left: 63.611,
            top: 20.000
          }, {
            id: "fangs_soulshadows",
            spell_id: 197386,
            max_level: 3,
            icon: "inv_knife_1h_grimbatolraid_d_03",
            ring: "thin",
            left: 61.944,
            top: 33.821,
            is_thin: true
          }
        ];
        lines = [
          {
            width: 143,
            left: 83.889,
            top: 38.862,
            angle: 65.589,
            spell1: 209782,
            spell2: 221856
          }, {
            width: 118,
            left: 67.361,
            top: 57.561,
            angle: -52.253,
            spell1: 197231,
            spell2: 209835
          }, {
            width: 111,
            left: 56.667,
            top: 70.407,
            angle: 144.162,
            spell1: 197231,
            spell2: 197256
          }, {
            width: 146,
            left: 21.806,
            top: 89.593,
            angle: -159.950,
            spell1: 197233,
            spell2: 197406
          }, {
            width: 136,
            left: 41.250,
            top: 91.220,
            angle: -12.301,
            spell1: 197233,
            spell2: 197235
          }, {
            width: 191,
            left: 56.806,
            top: 46.829,
            angle: 147.391,
            spell1: 197234,
            spell2: 197241
          }, {
            width: 137,
            left: 80.139,
            top: 43.902,
            angle: 29.176,
            spell1: 197234,
            spell2: 221856
          }, {
            width: 86,
            left: 48.472,
            top: 86.179,
            angle: -156.714,
            spell1: 197235,
            spell2: 197610
          }, {
            width: 137,
            left: 57.917,
            top: 81.951,
            angle: -38.790,
            spell1: 197235,
            spell2: 197604
          }, {
            width: 113,
            left: 73.194,
            top: 69.268,
            angle: 142.214,
            spell1: 197369,
            spell2: 197604
          }, {
            width: 117,
            left: 84.444,
            top: 56.585,
            angle: -48.814,
            spell1: 197369,
            spell2: 221856
          }, {
            width: 86,
            left: 63.056,
            top: 33.659,
            angle: -81.964,
            spell1: 197386,
            spell2: 209781
          }, {
            width: 112,
            left: 55.694,
            top: 47.967,
            angle: 126.666,
            spell1: 197386,
            spell2: 197241
          }, {
            width: 127,
            left: 22.083,
            top: 82.114,
            angle: 161.136,
            spell1: 197239,
            spell2: 197406
          }, {
            width: 76,
            left: 38.750,
            top: 81.138,
            angle: 21.523,
            spell1: 197239,
            spell2: 197610
          }, {
            width: 94,
            left: 37.500,
            top: 73.821,
            angle: -40.668,
            spell1: 197239,
            spell2: 197244
          }, {
            width: 110,
            left: 46.250,
            top: 62.114,
            angle: 130.206,
            spell1: 197241,
            spell2: 197244
          }, {
            width: 77,
            left: 48.194,
            top: 72.358,
            angle: 32.869,
            spell1: 197244,
            spell2: 197256
          }
        ];
        return Templates.artifact({
          traits: traits,
          lines: lines,
          relic1: 'shadow',
          relic2: 'fel',
          relic3: 'fel'
        });
      },
      useKingslayers: function() {
        var lines, traits;
        $("#artifactframe").css("background-image", "url('/images/artifacts/kingslayers-bg.jpg')");
        traits = [
          {
            id: "ks_assassinsblades",
            spell_id: 214368,
            max_level: 1,
            icon: "ability_rogue_shadowstrikes",
            ring: "thin",
            left: 47.917,
            top: 34.634,
            is_thin: true
          }, {
            id: "ks_bagoftricks",
            spell_id: 192657,
            max_level: 1,
            icon: "rogue_paralytic_poison",
            ring: "dragon",
            left: 8.472,
            top: 34.146
          }, {
            id: "ks_balancedblades",
            spell_id: 192326,
            max_level: 3,
            icon: "ability_rogue_restlessblades",
            ring: "thin",
            left: 40.556,
            top: 54.472,
            is_thin: true
          }, {
            id: "ks_blood",
            spell_id: 192923,
            max_level: 1,
            icon: "inv_artifact_bloodoftheassassinated",
            ring: "dragon",
            left: 8.472,
            top: 82.439
          }, {
            id: "ks_embrace",
            spell_id: 192323,
            max_level: 3,
            icon: "spell_shadow_nethercloak",
            ring: "thin",
            left: 16.944,
            top: 69.106,
            is_thin: true
          }, {
            id: "ks_fromtheshadows",
            spell_id: 192428,
            max_level: 1,
            icon: "ability_rogue_deadlybrew",
            ring: "dragon",
            left: 69.861,
            top: 24.553
          }, {
            id: "ks_graspofguldan",
            spell_id: 192759,
            max_level: 1,
            icon: "ability_rogue_focusedattacks",
            ring: "thick",
            left: 55.139,
            top: 27.642
          }, {
            id: "ks_gushingwound",
            spell_id: 192329,
            max_level: 3,
            icon: "ability_rogue_bloodsplatter",
            ring: "thin",
            left: 0.694,
            top: 69.593,
            is_thin: true
          }, {
            id: "ks_masteralchemist",
            spell_id: 192318,
            max_level: 3,
            icon: "trade_brewpoison",
            ring: "thin",
            left: 2.917,
            top: 51.057,
            is_thin: true
          }, {
            id: "ks_masterassassin",
            spell_id: 192349,
            max_level: 3,
            icon: "ability_rogue_deadliness",
            ring: "thin",
            left: 18.889,
            top: 51.707,
            is_thin: true
          }, {
            id: "ks_poisonknives",
            spell_id: 192376,
            max_level: 3,
            icon: "ability_rogue_dualweild",
            ring: "thin",
            left: 53.750,
            top: 56.260,
            is_thin: true
          }, {
            id: "ks_serratededge",
            spell_id: 192315,
            max_level: 3,
            icon: "ability_warrior_bloodbath",
            ring: "thin",
            left: 70.417,
            top: 41.951,
            is_thin: true
          }, {
            id: "ks_shadowswift",
            spell_id: 192422,
            max_level: 1,
            icon: "rogue_burstofspeed",
            ring: "thin",
            left: 27.639,
            top: 57.561,
            is_thin: true
          }, {
            id: "ks_shadowwalker",
            spell_id: 192345,
            max_level: 3,
            icon: "ability_rogue_sprint",
            ring: "thin",
            left: 20.833,
            top: 40.000,
            is_thin: true
          }, {
            id: "ks_surgeoftoxins",
            spell_id: 192424,
            max_level: 1,
            icon: "ability_rogue_deviouspoisons",
            ring: "thin",
            left: 60.556,
            top: 47.805,
            is_thin: true
          }, {
            id: "ks_toxicblades",
            spell_id: 192310,
            max_level: 3,
            icon: "ability_rogue_disembowel",
            ring: "thin",
            left: 39.444,
            top: 38.374,
            is_thin: true
          }, {
            id: "ks_urgetokill",
            spell_id: 192384,
            max_level: 1,
            icon: "ability_rogue_improvedrecuperate",
            ring: "thin",
            left: 30.278,
            top: 40.976,
            is_thin: true
          }
        ];
        lines = [
          {
            width: 68,
            left: 36.389,
            top: 46.504,
            angle: 166.373,
            spell1: 192310,
            spell2: 192384
          }, {
            width: 99,
            left: 39.444,
            top: 53.171,
            angle: 85.380,
            spell1: 192310,
            spell2: 192326
          }, {
            width: 65,
            left: 45.417,
            top: 43.252,
            angle: -20.659,
            spell1: 192310,
            spell2: 214368
          }, {
            width: 107,
            left: 69.028,
            top: 40.000,
            angle: -92.141,
            spell1: 192315,
            spell2: 192428
          }, {
            width: 80,
            left: 66.111,
            top: 51.707,
            angle: 153.113,
            spell1: 192315,
            spell2: 192424
          }, {
            width: 111,
            left: 4.306,
            top: 49.431,
            angle: -68.962,
            spell1: 192318,
            spell2: 192657
          }, {
            width: 115,
            left: 9.167,
            top: 58.211,
            angle: 1.992,
            spell1: 192318,
            spell2: 192349
          }, {
            width: 115,
            left: 0.139,
            top: 67.154,
            angle: 97.989,
            spell1: 192318,
            spell2: 192329
          }, {
            width: 102,
            left: 11.806,
            top: 82.602,
            angle: 126.646,
            spell1: 192323,
            spell2: 192923
          }, {
            width: 105,
            left: 21.250,
            top: 70.081,
            angle: -42.678,
            spell1: 192323,
            spell2: 192422
          }, {
            width: 95,
            left: 33.750,
            top: 62.764,
            angle: 168.453,
            spell1: 192326,
            spell2: 192422
          }, {
            width: 96,
            left: 46.667,
            top: 62.114,
            angle: 6.605,
            spell1: 192326,
            spell2: 192376
          }, {
            width: 171,
            left: 4.167,
            top: 67.480,
            angle: -40.020,
            spell1: 192329,
            spell2: 192349
          }, {
            width: 97,
            left: 4.167,
            top: 82.764,
            angle: 54.669,
            spell1: 192329,
            spell2: 192923
          }, {
            width: 96,
            left: 14.167,
            top: 43.902,
            angle: -157.977,
            spell1: 192345,
            spell2: 192657
          }, {
            width: 68,
            left: 27.083,
            top: 47.317,
            angle: 5.042,
            spell1: 192345,
            spell2: 192384
          }, {
            width: 73,
            left: 24.444,
            top: 61.463,
            angle: 29.745,
            spell1: 192349,
            spell2: 192422
          }, {
            width: 105,
            left: 23.611,
            top: 53.171,
            angle: -38.830,
            spell1: 192349,
            spell2: 192384
          }, {
            width: 71,
            left: 58.472,
            top: 58.862,
            angle: -46.701,
            spell1: 192376,
            spell2: 192424
          }, {
            width: 139,
            left: 47.500,
            top: 52.195,
            angle: -107.526,
            spell1: 192376,
            spell2: 214368
          }, {
            width: 67,
            left: 53.194,
            top: 37.886,
            angle: 140.412,
            spell1: 192759,
            spell2: 214368
          }
        ];
        return Templates.artifact({
          traits: traits,
          lines: lines,
          relic1: 'shadow',
          relic2: 'iron',
          relic3: 'blood'
        });
      }
    };
  });

  ShadowcraftBackend = (function() {
    var get_engine;

    get_engine = function() {
      var endpoint, port;
      switch (Shadowcraft.Data.options.general.patch) {
        case 63:
          port = 8880;
          endpoint = "engine-6.3";
          return "http://" + window.location.hostname + ":" + port + "/" + endpoint;
        default:
          port = 8881;
          endpoint = "engine-6.2";
          return "http://" + window.location.hostname + ":" + port + "/" + endpoint;
      }
    };

    function ShadowcraftBackend(app1) {
      this.app = app1;
      this.app.Backend = this;
      _.extend(this, Backbone.Events);
    }

    ShadowcraftBackend.prototype.boot = function() {
      var self;
      self = this;
      Shadowcraft.bind("update", function() {
        return self.recompute();
      });
      return this;
    };

    ShadowcraftBackend.prototype.buildPayload = function() {
      var Gems, buffFood, buffList, data, g, gear_ids, item, j, k, key, len, mh, oh, payload, ref, ref1, specName, statSummary, talentArray, talentString, val;
      data = Shadowcraft.Data;
      Gems = Shadowcraft.ServerData.GEM_LOOKUP;
      statSummary = Shadowcraft.Gear.sumStats();
      if (data.gear[15]) {
        mh = Shadowcraft.Gear.getItem(data.gear[15].id, data.gear[15].context);
      }
      if (data.gear[16]) {
        oh = Shadowcraft.Gear.getItem(data.gear[16].id, data.gear[16].context);
      }
      buffList = [];
      ref = data.options.buffs;
      for (key in ref) {
        val = ref[key];
        if (val) {
          buffList.push(ShadowcraftOptions.buffMap.indexOf(key));
        }
      }
      buffFood = 0;
      talentArray = data.activeTalents.split("");
      for (key = j = 0, len = talentArray.length; j < len; key = ++j) {
        val = talentArray[key];
        talentArray[key] = (function() {
          switch (val) {
            case ".":
              return "0";
            case "0":
            case "1":
            case "2":
              return parseInt(val, 10) + 1;
          }
        })();
      }
      talentString = talentArray.join('');
      specName = {
        a: 'assassination',
        Z: 'combat',
        b: 'subtlety'
      }[data.activeSpec];
      data.options.rotation['opener_name'] = data.options.rotation["opener_name_" + specName];
      data.options.rotation['opener_use'] = data.options.rotation["opener_use_" + specName];
      payload = {
        r: data.options.general.race,
        l: data.options.general.level,
        pot: ShadowcraftOptions.buffPotions.indexOf(data.options.general.potion),
        prepot: ShadowcraftOptions.buffPotions.indexOf(data.options.general.prepot),
        b: buffList,
        bf: buffFood,
        ro: data.options.rotation,
        settings: {
          dmg_poison: data.options.general.lethal_poison,
          utl_poison: data.options.general.utility_poison !== 'n' ? data.options.general.utility_poison : void 0,
          duration: data.options.general.duration,
          response_time: data.options.general.response_time,
          time_in_execute_range: data.options.general.time_in_execute_range,
          num_boss_adds: data.options.general.num_boss_adds,
          latency: data.options.advanced.latency,
          adv_params: data.options.advanced.adv_params,
          night_elf_racial: data.options.general.night_elf_racial,
          demon_enemy: data.options.general.demon_enemy
        },
        spec: data.activeSpec,
        t: talentString,
        sta: [statSummary.strength || 0, statSummary.agility || 0, statSummary.attack_power || 0, statSummary.crit || 0, statSummary.haste || 0, statSummary.mastery || 0, statSummary.multistrike || 0, statSummary.versatility || 0]
      };
      payload.art = {};
      if (mh && oh) {
        if (mh.id === ShadowcraftGear.ARTIFACT_SETS[data.activeSpec].mh && oh.id === ShadowcraftGear.ARTIFACT_SETS[data.activeSpec].oh) {
          payload.art = data.artifact[data.activeSpec].traits;
        }
      }
      if (mh != null) {
        payload.mh = [mh.speed, mh.dps * mh.speed, data.gear[15].enchant, mh.subclass];
      }
      if (oh != null) {
        payload.oh = [oh.speed, oh.dps * oh.speed, data.gear[16].enchant, oh.subclass];
      }
      gear_ids = [];
      ref1 = data.gear;
      for (k in ref1) {
        g = ref1[k];
        if (g.id) {
          item = [g.id, g.item_level, g.enchant];
          gear_ids.push(item);
        }
      }
      payload.g = gear_ids;
      return payload;
    };

    ShadowcraftBackend.prototype.recomputeFailed = function() {
      Shadowcraft.Console.remove(".error");
      return Shadowcraft.Console.warn({}, "Error contacting backend engine", null, "error", "error");
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

    ShadowcraftBackend.prototype.recompute = function(payload, forcePost) {
      if (payload == null) {
        payload = null;
      }
      if (forcePost == null) {
        forcePost = false;
      }
      this.cancelRecompute = false;
      payload || (payload = this.buildPayload());
      if (this.cancelRecompute || (payload == null)) {
        return;
      }
      if (window._gaq) {
        window._gaq.push(['_trackEvent', "Character", "Recompute"]);
      }
      if (window.WebSocket && !forcePost && false) {
        return this.recompute_via_websocket(payload);
      } else {
        return this.recompute_via_post(payload);
      }
    };

    ShadowcraftBackend.prototype.recompute_via_websocket = function(payload) {
      if (this.ws.readyState !== 1) {
        return this.recompute(payload, true);
      } else {
        return this.ws.send("m", payload);
      }
    };

    ShadowcraftBackend.prototype.recompute_via_post = function(payload) {
      if (/msie/.test(navigator.userAgent.toLowerCase()) && window.XDomainRequest) {
        return this.recompute_via_xdr(payload);
      } else {
        return this.recompute_via_xhr(payload);
      }
    };

    ShadowcraftBackend.prototype.recompute_via_xdr = function(payload) {
      var app, xdr;
      app = this;
      xdr = new XDomainRequest();
      xdr.open("get", get_engine() + ("?rnd=" + (new Date().getTime()) + "&data=") + JSON.stringify(payload));
      xdr.send();
      xdr.onload = function() {
        var data;
        data = JSON.parse(xdr.responseText);
        return app.handleRecompute(data);
      };
      return xdr.onerror = function() {
        app.recomputeFailed();
        flash("Error contacting backend engine");
        return false;
      };
    };

    ShadowcraftBackend.prototype.recompute_via_xhr = function(payload) {
      var app;
      app = this;
      return $.ajax({
        type: "POST",
        url: get_engine(),
        contentType: 'application/json',
        data: $.toJSON(payload),
        dataType: 'json',
        success: function(data) {
          return app.handleRecompute(data);
        },
        error: function(xhr, textStatus, error) {
          return app.recomputeFailed();
        }
      });
    };

    return ShadowcraftBackend;

  })();

  ShadowcraftHistory = (function() {
    function ShadowcraftHistory(app1) {
      this.app = app1;
      this.app.History = this;
      Shadowcraft.Reset = this.reset;
    }

    ShadowcraftHistory.prototype.boot = function() {
      var app, buttons;
      app = this;
      Shadowcraft.bind("update", function() {
        return app.save();
      });
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
            t = ShadowcraftTalents.GetActiveSpecName();
            d = new Date();
            t += " " + (d.getFullYear()) + "-" + (d.getMonth() + 1) + "-" + (d.getDate());
            return sn.val(t);
          }
        });
      });
      $("#menuLoadSnapshot").click(function() {
        return app.selectSnapshot();
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
      $("#menuGetDebugURL").click(function() {
        return app.takeSnapshot(app.debugURLCallback, null);
      });
      return this;
    };

    ShadowcraftHistory.prototype.save = function() {
      if (this.app.Data != null) {
        $.jStorage.set(Shadowcraft.uuid, this.app.Data);
      }
    };

    ShadowcraftHistory.prototype.saveSnapshot = function(name) {
      var key, snapshots;
      key = this.app.uuid + "snapshots";
      snapshots = $.jStorage.get(key, {});
      snapshots[name] = $.toJSON(this.app.Data);
      return $.jStorage.set(key, snapshots);
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
      this.loadSnapshot($.parseJSON(snapshots[name]));
      return flash(name + " has been loaded");
    };

    ShadowcraftHistory.prototype.deleteSnapshot = function(name) {
      var key, snapshots;
      if (confirm("Delete this snapshot?")) {
        key = this.app.uuid + "snapshots";
        snapshots = $.jStorage.get(key, {});
        delete snapshots[name];
        $.jStorage.set(key, snapshots);
        return flash(name + " has been deleted");
      }
    };

    ShadowcraftHistory.prototype.load = function(defaults) {
      var data;
      data = $.jStorage.get(this.app.uuid, defaults);
      return data;
    };

    ShadowcraftHistory.prototype.loadFromFragment = function() {
      var hash, sha;
      hash = window.location.hash;
      if (hash && hash.match(/^#!/)) {
        sha = hash.substring(3);
        $.post("/history/getjson", {
          data: sha
        }).done(function(data) {
          Shadowcraft.Data = data;
          return Shadowcraft.loadData();
        }).fail(function() {
          throw "Failed to load data for sha " + sha + "!";
        });
        return true;
      }
      return false;
    };

    ShadowcraftHistory.prototype.reset = function() {
      if (confirm("This will wipe out any changes you've made. Proceed?")) {
        $.jStorage.deleteKey(uuid);
        return window.location.reload();
      }
    };

    ShadowcraftHistory.prototype.takeSnapshot = function(callback, extras) {
      return $.post("/history/getsha", {
        data: $.toJSON(this.app.Data)
      }).done(function(data) {
        return callback(data['sha'], extras);
      }).fail(function(xhr, textStatus, errorThrown) {
        throw "takeSnapshot failed to retrieve sha value";
      });
    };

    ShadowcraftHistory.prototype.debugURLCallback = function(sha, extras) {
      var url;
      url = window.location.href.slice(0, -1) + "/#!/" + sha;
      $("#generalDialog").html("<textarea style='width: 450px; height: 200px;'>" + url + "</textarea>");
      return $("#generalDialog").dialog({
        modal: true,
        width: 500,
        title: "Debugging URL"
      });
    };

    ShadowcraftHistory.prototype.loadSnapshot = function(data) {
      Shadowcraft.Data = data;
      return Shadowcraft.loadData();
    };

    return ShadowcraftHistory;

  })();

  titleize = function(str) {
    var f, i, j, len, r, s, sp, word;
    if (!str) {
      return "";
    }
    sp = str.split(/[ _]/);
    word = [];
    for (i = j = 0, len = sp.length; j < len; i = ++j) {
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
      tip = $("<div id='tooltip'></div>").addClass("ui-widget");
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
    return flashHide = window.setTimeout(hideFlash, 1500);
  };

  checkForWarnings = function(section) {
    var EnchantLookup, EnchantSlots, data, enchant, enchantable, gear, i, item, j, len, level, ref, results, row, slotIndex, talents;
    Shadowcraft.Console.hide();
    data = Shadowcraft.Data;
    EnchantLookup = Shadowcraft.ServerData.ENCHANT_LOOKUP;
    EnchantSlots = Shadowcraft.ServerData.ENCHANT_SLOTS;
    if (section === void 0 || section === "options") {
      Shadowcraft.Console.remove(".options");
      if (parseInt(data.options.general.patch) < 60) {
        Shadowcraft.Console.warn({}, "You are using an old Engine. Please switch to the newest Patch and/or clear all saved data and refresh from armory.", null, 'warn', 'options');
      }
    }
    if (section === void 0 || section === "talents") {
      Shadowcraft.Console.remove(".talents");
      if (data.activeTalents) {
        talents = data.activeTalents.split("");
        for (i = j = 0, len = talents.length; j < len; i = ++j) {
          row = talents[i];
          if (indexOf.call([0, 1, 2, 3, 4, 5, 6], i) >= 0 && row === ".") {
            level = 0;
            if (i < 6) {
              level = (i + 1) * 15;
            } else if (i === 6) {
              level = 100;
            }
            Shadowcraft.Console.warn({}, "Level " + level + " Talent not set", null, 'warn', 'talents');
          }
          if (i === 5 && row === "0") {
            Shadowcraft.Console.warn({}, "Talent Shuriken Toss is not fully supported by Shadowcraft.", "It is recommended to not use this talent.", 'warn', 'talents');
          }
        }
      }
    }
    if (section === void 0 || section === "gear") {
      Shadowcraft.Console.remove(".items");
      ref = data.gear;
      results = [];
      for (slotIndex in ref) {
        gear = ref[slotIndex];
        if (!gear || _.isEmpty(gear)) {
          continue;
        }
        item = Shadowcraft.Gear.getItem(gear.id, gear.context);
        if (!item) {
          continue;
        }
        if (item.name.indexOf("Rune of Re-Origination") !== -1) {
          Shadowcraft.Console.warn(item, "is not fully supported but also bad for rogues.", "It is recommended to not use this trinket.", "warn", "items");
        }
        enchant = EnchantLookup[gear.enchant];
        enchantable = EnchantSlots[item.equip_location] !== void 0 && Shadowcraft.Gear.getApplicableEnchants(slotIndex, item).length > 0;
        if (!enchant && enchantable) {
          results.push(Shadowcraft.Console.warn(item, "needs an enchantment", null, "warn", "items"));
        } else {
          results.push(void 0);
        }
      }
      return results;
    }
  };

  wait = function(msg) {
    msg || (msg = "");
    $("#waitMsg").html(msg);
    return $("#wait").data('timeout', setTimeout('$("#wait").show()', 1000));
  };

  showPopup = function(popup) {
    var $parent, body, ht, left, max, ot, speed, top;
    $(".popup").removeClass("visible");
    if (popup.find(".close-popup").length === 0) {
      popup.append("<a href='#' class='close-popup ui-dialog-titlebar-close ui-corner-all' role='button'><span class='ui-icon ui-icon-closethick'></span></a>");
      popup.find(".close-popup").click(function() {
        $(".popup").removeClass("visible");
        $(".slots").find(".active").removeClass("active");
        return false;
      }).hover(function() {
        return $(this).addClass('ui-state-hover');
      }, function() {
        return $(this).removeClass('ui-state-hover');
      });
    }
    $parent = popup.parents(".ui-tabs-panel");
    max = $parent.scrollTop() + $parent.outerHeight();
    top = $.data(document, "mouse-y") - 40 + $parent.scrollTop();
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
    $(".popup #filter input").val("");
    if (!Modernizr.touch) {
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

    ShadowcraftOptions.buffMap = ['short_term_haste_buff', 'flask_legion_agi'];

    ShadowcraftOptions.buffFoodMap = ['food_750_crit', 'food_750_haste', 'food_750_mastery', 'food_750_versatility', 'food_400_feast', 'food_high_proc'];

    ShadowcraftOptions.buffPotions = ['potion_old_war', 'potion_deadly_grace', 'potion_none'];

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
      var _k, _v, data, e0, exist, inputType, j, key, len, ns, opt, options, ref, ref1, s, template, templateOptions, val;
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
        if (data.options[namespace][key] != null) {
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
                ref = opt.options;
                for (j = 0, len = ref.length; j < len; j++) {
                  _v = ref[j];
                  templateOptions.push({
                    name: _v + "",
                    value: _v
                  });
                }
              } else {
                ref1 = opt.options;
                for (_k in ref1) {
                  _v = ref1[_k];
                  templateOptions.push({
                    name: _v + "",
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
              options = {};
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
            exist.val(val);
            break;
          case "select":
          case "input":
            exist.val(val);
        }
      }
      return null;
    };

    ShadowcraftOptions.prototype.initOptions = function() {
      this.setup("#settings #general", "general", {
        patch: {
          type: "select",
          name: "Patch/Engine",
          'default': 60,
          datatype: 'integer',
          options: {
            60: '6.2'
          }
        },
        level: {
          type: "input",
          name: "Level",
          'default': 100,
          datatype: 'integer',
          min: 100,
          max: 100
        },
        race: {
          type: "select",
          options: ["Human", "Dwarf", "Orc", "Blood Elf", "Gnome", "Worgen", "Troll", "Night Elf", "Undead", "Goblin", "Pandaren"],
          name: "Race",
          'default': "Human"
        },
        night_elf_racial: {
          name: "Racial (Night Elf)",
          datatype: 'integer',
          type: 'select',
          options: {
            1: 'Day (1% Crit)',
            0: 'Night (1% Haste)'
          },
          "default": 0
        },
        duration: {
          type: "input",
          name: "Fight Duration",
          'default': 360,
          datatype: 'integer',
          min: 15,
          max: 1200
        },
        response_time: {
          type: "input",
          name: "Response Time",
          'default': 0.5,
          datatype: 'float',
          min: 0.1,
          max: 5
        },
        time_in_execute_range: {
          type: "input",
          name: "Time in Execute Range",
          desc: "Only used in Assassination Spec",
          'default': 0.35,
          datatype: 'float',
          min: 0,
          max: 1
        },
        lethal_poison: {
          name: "Lethal Poison",
          type: 'select',
          options: {
            'dp': 'Deadly Poison',
            'wp': 'Wound Poison'
          },
          'default': 'dp'
        },
        num_boss_adds: {
          name: "Number of Boss Adds",
          datatype: 'float',
          type: 'input',
          min: 0,
          max: 20,
          'default': 0
        },
        demon_enemy: {
          name: "Enemy is Demon",
          desc: 'Enables damage buff from heirloom trinket against demons (The Demon Button)',
          datatype: 'select',
          options: {
            1: 'Yes',
            0: 'No'
          },
          'default': 0
        }
      });
      this.setup("#settings #generalFilter", "general", {
        max_ilvl: {
          name: "Max ILevel",
          type: "input",
          desc: "Don't show items over this item level in gear lists",
          'default': 1000,
          datatype: 'integer',
          min: 540,
          max: 1000
        },
        min_ilvl: {
          name: "Min ILevel",
          type: "input",
          desc: "Don't show items under this item level in gear lists",
          'default': 540,
          datatype: 'integer',
          min: 540,
          max: 1000
        },
        show_random_items: {
          name: "Min ILvL (Random Items)",
          desc: "Don't show random items under this item level in gear lists",
          datatype: 'integer',
          type: 'input',
          min: 540,
          max: 1000,
          'default': 540
        },
        show_upgrades: {
          name: "Show Upgrades",
          desc: "Show all upgraded items in gear lists",
          datatype: 'integer',
          type: 'select',
          options: {
            1: 'Yes',
            0: 'No'
          },
          'default': 0
        },
        epic_gems: {
          name: "Recommend Epic Gems",
          datatype: 'integer',
          type: 'select',
          options: {
            1: 'Yes',
            0: 'No'
          }
        }
      });
      this.setup("#settings #playerBuffs", "buffs", {
        food_buff: {
          name: "Food Buff",
          type: 'select',
          datatype: 'string',
          "default": 'food_750_versatility',
          options: {
            'food_750_crit': 'The Hungry Magister (750 Crit)',
            'food_750_haste': 'Azshari Salad (750 Haste)',
            'food_750_mastery': 'Nightborne Delicacy Platter (750 Mastery)',
            'food_750_versatility': 'Seed-Battered Fish Plate (750 Versatility)',
            'food_400_feast': 'Lavish Suramar Feast (400 Stat)',
            'food_high_proc': 'Fishbrul Special (High Fire Proc)'
          }
        },
        flask_legion_agi: {
          name: "Legion Agility Flask",
          desc: "Flask of the Seventh Demon (1300 Agility)",
          'default': true,
          datatype: 'bool'
        },
        short_term_haste_buff: {
          name: "+30% Haste/40 sec",
          desc: "Heroism/Bloodlust/Time Warp",
          'default': true,
          datatype: 'bool'
        }
      });
      this.setup("#settings #raidOther", "general", {
        prepot: {
          name: 'Pre-pot',
          type: 'select',
          datatype: 'string',
          "default": 'potion_old_war',
          options: {
            'potion_old_war': 'Potion of the Old War',
            'potion_deadly_grace': 'Potion of Deadly Grace',
            'potion_none': 'None'
          }
        },
        potion: {
          name: 'Combat Potion',
          type: 'select',
          datatype: 'string',
          "default": 'potion_old_war',
          options: {
            'potion_old_war': 'Potion of the Old War',
            'potion_deadly_grace': 'Potion of Deadly Grace',
            'potion_none': 'None'
          }
        }
      });
      this.setup("#settings section.mutilate .settings", "rotation", {
        min_envenom_size_non_execute: {
          type: "select",
          name: "Min CP/Envenom > 35%",
          options: [5, 4, 3, 2, 1],
          'default': 4,
          desc: "CP for Envenom when using Mutilate, no effect with Anticipation",
          datatype: 'integer',
          min: 1,
          max: 5
        },
        min_envenom_size_execute: {
          type: "select",
          name: "Min CP/Envenom < 35%",
          options: [5, 4, 3, 2, 1],
          'default': 5,
          desc: "CP for Envenom when using Dispatch, no effect with Anticipation",
          datatype: 'integer',
          min: 1,
          max: 5
        },
        opener_name_assassination: {
          type: "select",
          name: "Opener Name",
          options: {
            'mutilate': "Mutilate",
            'ambush': "Ambush",
            'garrote': "Garrote"
          },
          'default': 'ambush',
          datatype: 'string'
        },
        opener_use_assassination: {
          type: "select",
          name: "Opener Usage",
          options: {
            'always': "Always",
            'opener': "Start of the Fight",
            'never': "Never"
          },
          'default': 'always',
          datatype: 'string'
        }
      });
      this.setup("#settings section.combat .settings", "rotation", {
        ksp_immediately: {
          type: "select",
          name: "Killing Spree",
          options: {
            'true': "Killing Spree on cooldown",
            'false': "Wait for Bandit's Guile before using Killing Spree"
          },
          'default': 'true',
          datatype: 'string'
        },
        revealing_strike_pooling: {
          type: "check",
          name: "Pool for Revealing Strike",
          "default": true,
          datatype: 'bool'
        },
        blade_flurry: {
          type: "check",
          name: "Blade Flurry",
          desc: "Use Blade Flurry",
          "default": false,
          datatype: 'bool'
        },
        opener_name_combat: {
          type: "select",
          name: "Opener Name",
          options: {
            'sinister_strike': "Sinister Strike",
            'revealing_strike': "Revealing Strike",
            'ambush': "Ambush",
            'garrote': "Garrote"
          },
          'default': 'ambush',
          datatype: 'string'
        },
        opener_use_combat: {
          type: "select",
          name: "Opener Usage",
          options: {
            'always': "Always",
            'opener': "Start of the Fight",
            'never': "Never"
          },
          'default': 'always',
          datatype: 'string'
        }
      });
      this.setup("#settings section.subtlety .settings", "rotation", {
        use_hemorrhage: {
          type: "select",
          name: "CP Builder",
          options: {
            'never': "Backstab",
            'always': "Hemorrhage",
            'uptime': "Use Backstab and Hemorrhage for 100% DoT uptime"
          },
          "default": 'uptime',
          datatype: 'string'
        },
        opener_name_subtlety: {
          type: "select",
          name: "Opener Name",
          options: {
            'ambush': "Ambush",
            'garrote': "Garrote"
          },
          'default': 'ambush',
          datatype: 'string'
        },
        opener_use_subtlety: {
          type: "select",
          name: "Opener Usage",
          options: {
            'always': "Always",
            'opener': "Start of the Fight",
            'never': "Never"
          },
          'default': 'always',
          datatype: 'string'
        }
      });
      return this.setup("#settings #advancedSettings", "advanced", {
        latency: {
          type: "input",
          name: "Latency",
          'default': 0.03,
          datatype: 'float',
          min: 0.0,
          max: 5
        },
        adv_params: {
          type: "input",
          name: "Advanced Parameters",
          "default": "",
          datatype: 'string'
        }
      });
    };

    changeOption = function(elem, inputType, val) {
      var $this, base, data, dtype, max, min, name, ns, t0;
      $this = $(elem);
      data = Shadowcraft.Data;
      ns = elem.attr("data-ns") || "root";
      (base = data.options)[ns] || (base[ns] = {});
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
      if (inputType === "check") {
        $this.attr("checked", val);
      }
      data.options[ns][name] = val;
      Shadowcraft.Options.trigger("update", ns + "." + name, val);
      if ((ns !== 'advanced') || (name === 'latency' || name === 'adv_params')) {
        return Shadowcraft.update();
      }
    };

    changeCheck = function() {
      var $this;
      $this = $(this);
      changeOption($this, "check", $this.attr("checked") == null);
      return Shadowcraft.setupLabels("#settings,#advanced");
    };

    changeSelect = function() {
      return changeOption(this, "select");
    };

    changeInput = function() {
      return changeOption(this, "input");
    };

    ShadowcraftOptions.prototype.boot = function() {
      var app;
      app = this;
      this.initOptions();
      Shadowcraft.bind("loadData", function() {
        app.initOptions();
        Shadowcraft.setupLabels("#settings,#advanced");
        return $("#settings,#advanced select").change();
      });
      Shadowcraft.Talents.bind("changedSpec", function(spec) {
        $("#settings section.mutilate, #settings section.combat, #settings section.subtlety").hide();
        if (Shadowcraft.Data.activeSpec === "a") {
          $("#settings section.mutilate").show();
          if (Shadowcraft.Data.activeTalents.split("")[5] === "0") {
            return $("#opt-general-lethal_poison").append($("<option></option>").attr("value", "ap").text("Agonizing Poison"));
          }
        } else if (Shadowcraft.Data.activeSpec === "Z") {
          $("#settings section.combat").show();
          return $("#opt-general-lethal_poison option[value='ap']").remove();
        } else {
          $("#settings section.subtlety").show();
          return $("#opt-general-lethal_poison option[value='ap']").remove();
        }
      });
      Shadowcraft.Talents.bind("changedTalents", function() {
        var agonizing, poisonSelect;
        Shadowcraft.Console.remove(".options-poisons");
        if (Shadowcraft.Data.activeSpec === "a") {
          agonizing = Shadowcraft.Data.activeTalents.split("")[5] === "0";
          poisonSelect = $("#opt-general-lethal_poison");
          if (!agonizing) {
            if (poisonSelect.val() === "ap") {
              Shadowcraft.Console.warn("ap", "Agonizing Poison was selected in options. Defaulting to Deadly Poison", null, "warn", "options-poisons");
              poisonSelect.val("dp");
            }
            return $("#opt-general-lethal_poison option[value='ap']").remove();
          } else {
            return poisonSelect.append($("<option></option>").attr("value", "ap").text("Agonizing Poison"));
          }
        } else {
          if (poisonSelect.val() === "ap") {
            poisonSelect.val("dp");
          }
          return $("#opt-general-lethal_poison option[value='ap']").remove();
        }
      });
      return this;
    };

    function ShadowcraftOptions() {
      $("#settings,#advanced").bind("change", $.delegate({
        ".optionCheck": changeCheck
      }));
      $("#settings,#advanced").bind("change", $.delegate({
        ".optionSelect": changeSelect
      }));
      $("#settings,#advanced").bind("change", $.delegate({
        ".optionInput": changeInput
      }));
      _.extend(this, Backbone.Events);
    }

    return ShadowcraftOptions;

  })();

  ShadowcraftArtifact = (function() {
    var $popup, $popupbody, RELIC_TYPE_MAP, SPEC_ARTIFACT, WOWHEAD_SPEC_IDS, activateTrait, active_mapping, artifact_data, artifact_ilvl_stats, clickRelicSlot, clicked_relic_slot, decreaseTrait, getRelicEP, getStatsForIlvl, increaseTrait, selectRelic, updateArtifactItem, updateTraitRanking, updateTraits;

    $popupbody = null;

    $popup = null;

    SPEC_ARTIFACT = {
      "a": {
        icon: "inv_knife_1h_artifactgarona_d_01",
        text: "The Kingslayers",
        main: 192759,
        relic1: "shadow",
        relic2: "iron",
        relic3: "blood"
      },
      "Z": {
        icon: "inv_sword_1h_artifactskywall_d_01",
        text: "The Dreadblades",
        main: 202665,
        relic1: "blood",
        relic2: "iron",
        relic3: "wind"
      },
      "b": {
        icon: "inv_knife_1h_artifactfangs_d_01",
        text: "Fangs of the Devourer",
        main: 209782,
        relic1: "shadow",
        relic2: "fel",
        relic3: "fel"
      }
    };

    WOWHEAD_SPEC_IDS = {
      "a": 259,
      "Z": 260,
      "b": 261
    };

    RELIC_TYPE_MAP = {
      "iron": 0,
      "blood": 1,
      "shadow": 2,
      "fel": 3,
      "arcane": 4,
      "frost": 5,
      "fire": 6,
      "water": 7,
      "life": 8,
      "wind": 9,
      "holy": 10
    };

    active_mapping = {};

    clicked_relic_slot = 0;

    artifact_ilvl_stats = {};

    artifact_data = null;

    activateTrait = function(spell_id) {
      var level, max_level, relic_power, trait;
      trait = $("#artifactframe .trait[data-tooltip-id='" + spell_id + "']");
      trait.children(".icon").removeClass("inactive");
      trait.children(".level").removeClass("inactive");
      active_mapping[parseInt(trait.attr("data-tooltip-id"))] = true;
      relic_power = trait.data("relic-power");
      level = artifact_data.traits[spell_id] + relic_power;
      max_level = parseInt(trait.attr("max_level")) + relic_power;
      trait.children(".level").text("" + level + "/" + max_level);
      trait.data("tooltip-rank", level - 1);
      return {
        current: level,
        max: max_level
      };
    };

    updateArtifactItem = function(id, oldIlvl, newIlvl) {
      var baseItem, ident, newStats, updatedItem;
      if (indexOf.call(ShadowcraftGear.ARTIFACTS, id) < 0) {
        return;
      }
      ident = id + ":750:0";
      baseItem = Shadowcraft.ServerData.ITEM_LOOKUP2[ident];
      updatedItem = $.extend({}, baseItem);
      updatedItem.ilvl = newIlvl;
      updatedItem.id = id;
      updatedItem.identifier = "" + id + ":" + newIlvl + ":0";
      newStats = getStatsForIlvl(newIlvl);
      updatedItem.stats = $.extend({}, newStats["stats"]);
      updatedItem.dps = newStats["dps"];
      if (Shadowcraft.Data.artifact_items === void 0) {
        Shadowcraft.Data.artifact_items = {};
      }
      return Shadowcraft.Data.artifact_items[id] = updatedItem;
    };

    ShadowcraftArtifact.prototype.updateArtifactItem = function(id, oldIlvl, newIlvl) {
      return updateArtifactItem(id, oldIlvl, newIlvl);
    };

    updateTraits = function() {
      var active, button, current, done, i, ilvl, j, key, levels, m, main, main_spell_id, oldIlvl, relic, relicTrait, relicdiv, spell, spell_id, stack, trait, type, val;
      active = SPEC_ARTIFACT[Shadowcraft.Data.activeSpec];
      main_spell_id = SPEC_ARTIFACT[Shadowcraft.Data.activeSpec].main;
      active_mapping = {};
      $("#artifactframe .trait").each(function() {
        active_mapping[parseInt($(this).attr("data-tooltip-id"))] = false;
        $(this).children(".level").addClass("inactive");
        $(this).children(".icon").addClass("inactive");
        $(this).children(".relic").addClass("inactive");
        $(this).data("tooltip-rank", -1);
        return $(this).data("relic-power", 0);
      });
      $("#artifactframe .line").each(function() {
        return $(this).addClass("inactive");
      });
      $("#artifactframe .relicframe").each(function() {
        $(this).children(".relicicon").addClass("inactive");
        $(this).removeData("tooltip-id");
        return $(this).removeData("tooltip-spec");
      });
      if (!artifact_data) {
        return;
      }
      done = [];
      if (artifact_data.traits[main_spell_id] === 0) {
        active_mapping[main_spell_id] = true;
        main = $("#artifactframe .trait[data-tooltip-id='" + main_spell_id + "']");
        main.children(".level").text("0/" + main.attr("max_level"));
        main.children(".level").removeClass("inactive");
        main.children(".icon").removeClass("inactive");
        main.data("tooltip-rank", -1);
        done = [main_spell_id];
      }
      stack = [main_spell_id];
      for (i = j = 0; j < 3; i = ++j) {
        if (artifact_data.relics[i] !== 0) {
          relic = Shadowcraft.ServerData.RELIC_LOOKUP[artifact_data.relics[i]];
          spell = relic.ts[Shadowcraft.Data.activeSpec].spell;
          trait = $("#artifactframe .trait[data-tooltip-id='" + spell + "'");
          current = trait.data('relic-power');
          current += relic.ts[Shadowcraft.Data.activeSpec].rank;
          trait.data('relic-power', current);
          stack.push(relic.ts[Shadowcraft.Data.activeSpec].spell);
        }
      }
      while (stack.length > 0) {
        spell_id = stack.pop();
        if (jQuery.inArray(spell_id, done) !== -1) {
          continue;
        }
        levels = activateTrait(spell_id);
        if (levels.current === levels.max) {
          $("#artifactframe .line[spell1='" + spell_id + "']").each(function() {
            var other_end;
            $(this).removeClass("inactive");
            other_end = $(this).attr("spell2");
            if (jQuery.inArray(other_end, done) === -1) {
              return stack.push(parseInt(other_end));
            }
          });
          $("#artifactframe .line[spell2='" + spell_id + "']").each(function() {
            var other_end;
            $(this).removeClass("inactive");
            other_end = $(this).attr("spell1");
            if (jQuery.inArray(other_end, done) === -1) {
              return stack.push(parseInt(other_end));
            }
          });
        }
        done.push(parseInt(spell_id));
      }
      $("#artifactframe .trait").each(function() {
        var check_id;
        check_id = parseInt($(this).attr('data-tooltip-id'));
        if (jQuery.inArray(check_id, done) === -1) {
          return artifact_data.traits[check_id] = 0;
        }
      });
      oldIlvl = Shadowcraft.Data.gear[15].item_level;
      ilvl = 750;
      for (i = m = 0; m < 3; i = ++m) {
        button = $("#relic" + (i + 1) + " .relicicon");
        relicdiv = $("#relic" + (i + 1));
        if (artifact_data.relics[i] !== 0) {
          relic = Shadowcraft.ServerData.RELIC_LOOKUP[artifact_data.relics[i]];
          ilvl += relic.ii;
          relicTrait = relic.ts[Shadowcraft.Data.activeSpec];
          button.attr("src", "http://wow.zamimg.com/images/wow/icons/large/" + relic.icon + ".jpg");
          button.removeClass("inactive");
          relicdiv.data("tooltip-id", relic.id);
          relicdiv.data("tooltip-spec", WOWHEAD_SPEC_IDS[Shadowcraft.Data.activeSpec]);
          for (key in RELIC_TYPE_MAP) {
            val = RELIC_TYPE_MAP[key];
            if (val === relic.type) {
              type = key;
              break;
            }
          }
          trait.children(".relic").attr("src", "/images/artifacts/relic-" + type + ".png");
          trait.children(".relic").removeClass("inactive");
          Shadowcraft.Data.gear[15].gems[i] = relic.id;
          Shadowcraft.Data.gear[16].gems[i] = relic.id;
        } else {
          button.addClass("inactive");
        }
      }
      updateArtifactItem(Shadowcraft.Data.gear[15].id, oldIlvl, ilvl);
      updateArtifactItem(Shadowcraft.Data.gear[16].id, oldIlvl, ilvl);
      Shadowcraft.update();
      if (Shadowcraft.Gear.initialized) {
        Shadowcraft.Gear.updateDisplay();
      }
    };

    increaseTrait = function(e) {
      var current_level, max_level, spell_id, trait;
      spell_id = parseInt(e.delegateTarget.attributes["data-tooltip-id"].value);
      trait = $("#artifactframe .trait[data-tooltip-id='" + spell_id + "']");
      if (trait.children(".icon").hasClass("inactive")) {
        return;
      }
      max_level = parseInt(trait.attr("max_level"));
      if (artifact_data.traits[spell_id] === max_level) {
        return;
      }
      artifact_data.traits[spell_id] += 1;
      current_level = artifact_data.traits[spell_id];
      return updateTraits();
    };

    decreaseTrait = function(e) {
      var min_level, spell_id, trait;
      spell_id = parseInt(e.delegateTarget.attributes["data-tooltip-id"].value);
      trait = $("#artifactframe .trait[data-tooltip-id='" + spell_id + "']");
      if (trait.children(".icon").hasClass("inactive")) {
        return;
      }
      if (trait.attr("relic_power") != null) {
        min_level = parseInt(trait.attr("relic_power"));
      } else {
        min_level = 0;
      }
      if (artifact_data.traits[spell_id] === min_level) {
        return;
      }
      artifact_data.traits[spell_id] -= 1;
      return updateTraits();
    };

    getStatsForIlvl = function(ilvl) {
      var dps, itemid, multiplier, stat, stats, value;
      if (!(ilvl in artifact_ilvl_stats)) {
        itemid = Shadowcraft.Data.gear[15].id;
        stats = $.extend({}, Shadowcraft.ServerData.ITEM_LOOKUP2["" + itemid + ":750:0"].stats);
        dps = Shadowcraft.ServerData.ITEM_LOOKUP2["" + itemid + ":750:0"].dps;
        multiplier = 1.0 / Math.pow(1.15, (ilvl - 750) / 15.0 * -1);
        for (stat in stats) {
          value = stats[stat];
          stats[stat] = Math.round(value * multiplier);
        }
        artifact_ilvl_stats[ilvl] = {};
        artifact_ilvl_stats[ilvl]["stats"] = stats;
        artifact_ilvl_stats[ilvl]["dps"] = dps * multiplier;
      }
      return artifact_ilvl_stats[ilvl];
    };

    ShadowcraftArtifact.prototype.getStatsForIlvl = function(ilvl) {
      return getStatsForIlvl(ilvl);
    };

    getRelicEP = function(relic, baseIlvl, baseStats) {
      var activeSpec, diff, ep, newStats, stat, trait;
      activeSpec = Shadowcraft.Data.activeSpec;
      trait = relic.ts[activeSpec];
      ep = trait.rank * Shadowcraft.lastCalculation.artifact_ranking[trait.spell];
      newStats = getStatsForIlvl(baseIlvl + relic.ii);
      for (stat in baseStats["stats"]) {
        diff = newStats["stats"][stat] - baseStats["stats"][stat];
        if (stat === "agility") {
          ep += diff * Shadowcraft.lastCalculation.ep["agi"];
        } else if (stat === "mastery") {
          ep += diff * Shadowcraft.lastCalculation.ep["mastery"];
        } else if (stat === "crit") {
          ep += diff * Shadowcraft.lastCalculation.ep["crit"];
        } else if (stat === "multistrike") {
          ep += diff * Shadowcraft.lastCalculation.ep["multistrike"];
        } else if (stat === "haste") {
          ep += diff * Shadowcraft.lastCalculation.ep["haste"];
        }
      }
      ep += (newStats["dps"] - baseStats["dps"]) * Shadowcraft.lastCalculation.mh_ep.mh_dps;
      return Math.round(ep * 100.0) / 100.0;
    };

    clickRelicSlot = function(e) {
      var RelicList, activeSpec, baseArtifactStats, baseIlvl, buffer, currentRelic, currentRelicId, data, desc, i, j, len, len1, m, max, relic, relic_type;
      relic_type = e.delegateTarget.attributes['relic-type'].value;
      clicked_relic_slot = parseInt(/relic(\d+)/.exec(e.delegateTarget.id)[1]) - 1;
      activeSpec = Shadowcraft.Data.activeSpec;
      RelicList = Shadowcraft.ServerData.RELICS.filter(function(relic) {
        return relic.type === RELIC_TYPE_MAP[relic_type];
      });
      data = Shadowcraft.Data;
      currentRelicId = Shadowcraft.Data.artifact[activeSpec].relics[clicked_relic_slot];
      if (currentRelicId !== 0) {
        currentRelic = ((function() {
          var j, len, results;
          results = [];
          for (j = 0, len = RelicList.length; j < len; j++) {
            i = RelicList[j];
            if (i.id === currentRelicId) {
              results.push(i);
            }
          }
          return results;
        })())[0];
        baseIlvl = Shadowcraft.Data.gear[15].item_level - currentRelic.ii;
      } else {
        baseIlvl = Shadowcraft.Data.gear[15].item_level;
      }
      baseArtifactStats = getStatsForIlvl(baseIlvl);
      max = 0;
      for (j = 0, len = RelicList.length; j < len; j++) {
        relic = RelicList[j];
        relic.__ep = getRelicEP(relic, baseIlvl, baseArtifactStats);
        if (relic.__ep > max) {
          max = relic.__ep;
        }
      }
      RelicList.sort(function(relic1, relic2) {
        return relic2.__ep - relic1.__ep;
      });
      buffer = "";
      for (m = 0, len1 = RelicList.length; m < len1; m++) {
        relic = RelicList[m];
        desc = "";
        if (relic.ii !== -1) {
          desc += "+" + relic.ii + " Item Levels";
        }
        if (relic.ii !== -1 && relic.ts[activeSpec].rank !== -1) {
          desc += " / ";
        }
        if (relic.ts[activeSpec].rank !== -1) {
          desc += "+" + relic.ts[activeSpec].rank + " Rank: " + relic.ts[activeSpec].name;
        }
        buffer += Templates.itemSlot({
          item: relic,
          gear: {},
          ttid: relic.id,
          ttspec: WOWHEAD_SPEC_IDS[Shadowcraft.Data.activeSpec],
          search: escape(relic.n),
          desc: desc,
          percent: relic.__ep / max * 100,
          ep: relic.__ep
        });
      }
      buffer += Templates.itemSlot({
        item: {
          name: "[No relic]"
        },
        desc: "Clear this relic",
        percent: 0,
        ep: 0
      });
      $popupbody.get(0).innerHTML = buffer;
      if (artifact_data.relics[clicked_relic_slot] !== -1) {
        $popupbody.find(".slot[id='" + artifact_data.relics[clicked_relic_slot] + "']").addClass("active");
      }
      showPopup($popup);
      return false;
    };

    selectRelic = function(clicked_relic) {
      var relic_id;
      relic_id = parseInt(clicked_relic.attr("id"));
      relic_id = !isNaN(relic_id) ? relic_id : null;
      if (relic_id != null) {
        artifact_data.relics[clicked_relic_slot] = relic_id;
      } else {
        artifact_data.relics[clicked_relic_slot] = 0;
      }
      updateTraits();
      clicked_relic_slot = 0;
      return true;
    };

    ShadowcraftArtifact.prototype.setSpec = function(str) {
      var buffer;
      buffer = Templates.artifactActive({
        name: SPEC_ARTIFACT[str].text,
        icon: SPEC_ARTIFACT[str].icon
      });
      $("#artifactactive").get(0).innerHTML = buffer;
      if (str === "a") {
        buffer = ArtifactTemplates.useKingslayers();
        $("#artifactframe").get(0).innerHTML = buffer;
        artifact_data = Shadowcraft.Data.artifact[str];
      } else if (str === "Z") {
        buffer = ArtifactTemplates.useDreadblades();
        $("#artifactframe").get(0).innerHTML = buffer;
        artifact_data = Shadowcraft.Data.artifact[str];
      } else if (str === "b") {
        buffer = ArtifactTemplates.useFangs();
        $("#artifactframe").get(0).innerHTML = buffer;
        artifact_data = Shadowcraft.Data.artifact[str];
      }
      $("#relic1").attr("relic-type", SPEC_ARTIFACT[str].relic1);
      $("#relic2").attr("relic-type", SPEC_ARTIFACT[str].relic2);
      $("#relic3").attr("relic-type", SPEC_ARTIFACT[str].relic3);
      updateTraits();
      $("#artifactframe .trait").each(function() {}).mousedown(function(e) {
        switch (e.button) {
          case 0:
            return increaseTrait(e);
          case 2:
            return decreaseTrait(e);
        }
      }).bind("contextmenu", function() {
        return false;
      }).mouseover($.delegate({
        ".tt": ttlib.requestTooltip
      })).mouseout($.delegate({
        ".tt": ttlib.hide
      }));
      return $("#artifactframe .relicframe").each(function() {}).click(function(e) {
        return clickRelicSlot(e);
      }).bind("contextmenu", function() {
        return false;
      }).mouseover($.delegate({
        ".tt": ttlib.requestTooltip
      })).mouseout($.delegate({
        ".tt": ttlib.hide
      }));
    };

    ShadowcraftArtifact.prototype.resetTraits = function() {
      var i, id, j;
      for (id in artifact_data.traits) {
        artifact_data.traits[id] = 0;
      }
      for (i = j = 0; j < 2; i = ++j) {
        artifact_data.relics[i] = 0;
      }
      return updateTraits();
    };

    updateTraitRanking = function() {
      var buffer, ep, exist, max, pct, ranking, target, trait, trait_name, val;
      buffer = "";
      target = $("#traitrankings");
      ranking = Shadowcraft.lastCalculation.artifact_ranking;
      max = _.max(ranking);
      for (trait in ranking) {
        ep = ranking[trait];
        val = parseFloat(ep);
        trait_name = ShadowcraftData.ARTIFACT_LOOKUP[parseInt(trait)].n;
        pct = val / max * 100 + 0.01;
        exist = $("#traitrankings #talent-weight-" + trait);
        if (exist.length === 0) {
          buffer = Templates.talentContribution({
            name: "" + trait_name,
            raw_name: "" + trait,
            val: val,
            width: pct
          });
          target.append(buffer);
        }
        exist = $("#traitrankings #talent-weight-" + trait);
        $.data(exist.get(0), "val", val);
        exist.show().find(".pct-inner").css({
          width: pct + "%"
        });
        exist.find(".label").text("" + val);
      }
      $("#traitrankings .talent_contribution").sortElements(function(a, b) {
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

    ShadowcraftArtifact.prototype.boot = function() {
      var app;
      app = this;
      $popup = $("#artifactpopup");
      $popupbody = $("#artifactpopup .body");
      Shadowcraft.bind("loadData", function() {
        var data, spec;
        data = Shadowcraft.Data;
        spec = data.activeSpec;
        return app.setSpec(spec);
      });
      Shadowcraft.Talents.bind("changedSpec", function(spec) {
        return app.setSpec(spec);
      });
      Shadowcraft.Backend.bind("recompute", updateTraitRanking);
      $("#reset_artifact").click(function(e) {
        return app.resetTraits();
      }).bind("contextmenu", function() {
        return false;
      });
      $(".popup").mouseover($.delegate({
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
      $popupbody.click($.delegate({
        ".slot": function(e) {
          return selectRelic($(this));
        }
      }));
      return this;
    };

    function ShadowcraftArtifact(app1) {
      this.app = app1;
      this.app.Artifact = this;
      _.extend(this, Backbone.Events);
    }

    return ShadowcraftArtifact;

  })();

  ShadowcraftTalents = (function() {
    var DEFAULT_SPECS, SPEC_ICONS, getSpecName;

    SPEC_ICONS = {
      "a": "ability_rogue_eviscerate",
      "Z": "ability_backstab",
      "b": "ability_stealth",
      "": "class_rogue"
    };

    DEFAULT_SPECS = {
      "Stock Assassination": {
        talents: "2211021",
        spec: "a"
      },
      "Stock Outlaw": {
        talents: "2211011",
        spec: "Z"
      },
      "Stock Subtlety": {
        talents: "1210011",
        spec: "b"
      }
    };

    ShadowcraftTalents.GetActiveSpecName = function() {
      var activeSpec;
      activeSpec = Shadowcraft.Data.activeSpec;
      if (activeSpec) {
        return getSpecName(activeSpec);
      }
      return "";
    };

    getSpecName = function(s) {
      if (s === "a") {
        return "Assassination";
      } else if (s === "Z") {
        return "Outlaw";
      } else if (s === "b") {
        return "Subtlety";
      } else {
        return "Rogue";
      }
    };

    ShadowcraftTalents.prototype.applyTalent = function(talent, enable) {
      var position, talents;
      position = $.data(talent, "position");
      if (!enable) {
        $("#talentframe .talent.row-" + position['row']).each(function() {
          return $(this).addClass("active");
        });
        talents = Shadowcraft.Data.activeTalents.split("");
        talents[position['row']] = '.';
        Shadowcraft.Data.activeTalents = talents.join("");
        return true;
      } else {
        talents = Shadowcraft.Data.activeTalents.split("");
        if (talents[position['row']] === position['col']) {
          return false;
        } else {
          $("#talentframe .talent.row-" + position['row']).each(function() {
            return $(this).removeClass("active");
          });
          $("#talentframe .talent.row-" + position['row'] + ".col-" + position['col']).addClass("active");
          talents[position['row']] = position["col"];
          Shadowcraft.Data.activeTalents = talents.join("");
          return true;
        }
      }
    };

    ShadowcraftTalents.prototype.resetTalents = function() {
      Shadowcraft.Data.activeTalents = ".......";
      $("#talentframe .talent").each(function() {
        return $(this).addClass("active");
      });
      Shadowcraft.update();
      return checkForWarnings("talents");
    };

    ShadowcraftTalents.prototype.initSidebar = function() {
      var app, buffer, data, j, len, ref, talent, talentName, talentSet;
      app = this;
      data = Shadowcraft.Data;
      buffer = "";
      ref = data.talents;
      for (j = 0, len = ref.length; j < len; j++) {
        talent = ref[j];
        buffer += Templates.talentSet({
          talent_string: talent.talents,
          name: "Imported " + getSpecName(talent.spec),
          spec: talent.spec
        });
      }
      for (talentName in DEFAULT_SPECS) {
        talentSet = DEFAULT_SPECS[talentName];
        buffer += Templates.talentSet({
          talent_string: talentSet.talents,
          name: talentName,
          spec: talentSet.spec
        });
      }
      $("#talentsets").get(0).innerHTML = buffer;
      return $("#talentsets").click($.delegate({
        ".talent_set": function() {
          app.setSpec($(this).data("spec"));
          app.setActiveTalents($(this).data("talents") + "");
        }
      }));
    };

    ShadowcraftTalents.prototype.setActiveTalents = function(talents) {
      var column, j, len, row, rowTalents;
      Shadowcraft.Data.activeTalents = talents;
      rowTalents = talents.split("");
      for (row = j = 0, len = rowTalents.length; j < len; row = ++j) {
        column = rowTalents[row];
        if (column === '.') {
          $("#talentframe .talent.row-" + row).addClass("active");
        } else {
          $("#talentframe .talent.row-" + row).removeClass("active");
          $("#talentframe .talent.row-" + row + ".col-" + column).addClass("active");
        }
      }
      Shadowcraft.update();
      return checkForWarnings("talents");
    };

    ShadowcraftTalents.prototype.setSpec = function(spec) {
      var TalentLookup, Talents, app, buffer, talentTiers, talentTrees, talentframe, tframe, tree;
      app = this;
      buffer = Templates.specActive({
        name: getSpecName(spec),
        icon: SPEC_ICONS[spec]
      });
      $("#specactive").get(0).innerHTML = buffer;
      Talents = Shadowcraft.ServerData.TALENTS;
      TalentLookup = Shadowcraft.ServerData.TALENT_LOOKUP;
      talentTiers = [
        {
          tier: "0",
          level: "15"
        }, {
          tier: "1",
          level: "30"
        }, {
          tier: "2",
          level: "45"
        }, {
          tier: "3",
          level: "60"
        }, {
          tier: "4",
          level: "75"
        }, {
          tier: "5",
          level: "90"
        }, {
          tier: "6",
          level: "100"
        }
      ];
      buffer = Templates.talentTier({
        levels: talentTiers
      });
      tree = Talents.filter(function(talent) {
        return (parseInt(talent.tier, 10) <= (talentTiers.length - 1)) && (talent.spec === spec);
      });
      buffer += Templates.talentTree({
        background: 1,
        talents: tree
      });
      talentframe = $("#talentframe");
      tframe = talentframe.get(0);
      tframe.innerHTML = buffer;
      $(".tree, .tree .talent, .tree .talent").disableTextSelection();
      talentTrees = $("#talentframe .tree");
      $("#talentframe .talent").each(function() {
        var $this, col, row, talent;
        row = parseInt(this.className.match(/row-(\d)/)[1], 10);
        col = parseInt(this.className.match(/col-(\d)/)[1], 10);
        $this = $(this);
        talent = TalentLookup[spec + ":" + row + ":" + col];
        $.data(this, "position", {
          row: row,
          col: col
        });
        return $.data(this, "talent", talent);
      }).mousedown(function(e) {
        switch (e.button) {
          case 0:
            if (app.applyTalent(this, true)) {
              Shadowcraft.update();
              Shadowcraft.Talents.trigger("changedTalents");
            }
            checkForWarnings("talents");
            break;
          case 2:
            if (!$(this).hasClass("active")) {
              return;
            }
            if (app.applyTalent(this, false)) {
              Shadowcraft.update();
              Shadowcraft.Talents.trigger("changedTalents");
            }
            checkForWarnings("talents");
        }
        return $(this).trigger("mouseenter");
      }).bind("contextmenu", function() {
        return false;
      }).mouseenter($.delegate({
        ".tt": ttlib.requestTooltip
      })).mouseleave($.delegate({
        ".tt": ttlib.hide
      }));
      Shadowcraft.Data.activeSpec = spec;
      Shadowcraft.Talents.trigger("changedSpec", spec);
    };

    ShadowcraftTalents.prototype.boot = function() {
      var app, data;
      app = this;
      this.initSidebar();
      data = Shadowcraft.Data;
      if (!data.activeSpec) {
        data.activeSpec = data.talents[data.active].spec;
        data.activeTalents = data.talents[data.active].talents;
      }
      this.setSpec(data.activeSpec);
      this.setActiveTalents(data.activeTalents);
      $("#reset_talents").click(app.resetTalents);
      Shadowcraft.bind("loadData", function() {
        app.setSpec(this.Data.activeSpec);
        return app.setActiveTalents(this.Data.activeTalents);
      });
      $("#talents #talentframe").mousemove(function(e) {
        $.data(document, "mouse-x", e.pageX);
        return $.data(document, "mouse-y", e.pageY);
      });
      return this;
    };

    function ShadowcraftTalents(app1) {
      this.app = app1;
      this.app.Talents = this;
      _.extend(this, Backbone.Events);
    }

    return ShadowcraftTalents;

  })();

  ShadowcraftGear = (function() {
    var $popup, $popupbody, $slots, EP_PRE_REGEM, EP_TOTAL, FACETS, LEGENDARY_RINGS, PROC_ENCHANTS, SLOT_DISPLAY_ORDER, SLOT_INVTYPES, SLOT_ORDER, Sets, Weights, canUseGem, clearBonuses, clickItemLock, clickItemUpgrade, clickSlot, clickSlotBonuses, clickSlotEnchant, clickSlotGem, clickSlotName, clickWowhead, epSort, equalGemStats, getApplicableEnchants, getBaseItemLevel, getBestNormalGem, getEP, getEPForStatBlock, getEnchantRecommendation, getEquippedSetCount, getGemRecommendationList, getGemmingRecommendation, getItem, getMaxUpgradeLevel, getRandPropRow, getStatWeight, getUpgradeLevelSteps, hasSocket, isProfessionalGem, j, makeTag, needsDagger, recalculateStats, recalculateStatsDiff, results, setBonusEP, sortComparator, sortTagBonuses, statOffset, statsToDesc, sumItem, updateDpsBreakdown, updateEngineInfoWindow, updateStatWeights;

    FACETS = {
      ITEM: 1,
      GEMS: 2,
      ENCHANT: 4,
      ALL: 255
    };

    ShadowcraftGear.FACETS = FACETS;

    SLOT_ORDER = ["0", "1", "2", "14", "4", "8", "9", "5", "6", "7", "10", "11", "12", "13", "15", "16"];

    SLOT_DISPLAY_ORDER = [["0", "1", "2", "14", "4", "8", "15", "16"], ["9", "5", "6", "7", "10", "11", "12", "13"]];

    PROC_ENCHANTS = {
      5330: "mark_of_the_thunderlord",
      5331: "mark_of_the_shattered_hand",
      5334: "mark_of_the_frostwolf",
      5337: "mark_of_warsong",
      5384: "mark_of_the_bleeding_hollow"
    };

    LEGENDARY_RINGS = [118302, 118307, 124636];

    ShadowcraftGear.ARTIFACTS = [128476, 128479, 128872, 134552, 128869, 128870];

    ShadowcraftGear.ARTIFACT_SETS = {
      a: {
        mh: 128870,
        oh: 128869
      },
      Z: {
        mh: 128872,
        oh: 134552
      },
      b: {
        mh: 128476,
        oh: 128479
      }
    };

    Sets = {
      T18: {
        ids: [124248, 124257, 124263, 124269, 124274],
        bonuses: {
          4: "rogue_t18_4pc",
          2: "rogue_t18_2pc"
        }
      },
      T18_LFR: {
        ids: [128130, 128121, 128125, 128054, 128131, 128137],
        bonuses: {
          4: "rogue_t18_4pc_lfr"
        }
      },
      T19: {
        ids: [138326, 138329, 138332, 138335, 138338, 138371],
        bonuses: {
          4: "rogue_t19_4pc",
          2: "rogue_t19_2pc"
        }
      },
      ORDERHALL: {
        ids: [139739, 139740, 139741, 139742, 139743, 139744, 139745, 139746],
        bonuses: {
          8: "rogue_orderhall_8pc"
        }
      }
    };

    ShadowcraftGear.WF_BONUS_IDS = [546, 547];

    Array.prototype.push.apply(ShadowcraftGear.WF_BONUS_IDS, [560, 561, 562]);

    Array.prototype.push.apply(ShadowcraftGear.WF_BONUS_IDS, [644, 646, 651, 656]);

    Array.prototype.push.apply(ShadowcraftGear.WF_BONUS_IDS, [754, 755, 756, 757, 758, 759, 760, 761, 762, 763, 764, 765, 766]);

    Array.prototype.push.apply(ShadowcraftGear.WF_BONUS_IDS, (function() {
      results = [];
      for (j = 1477; j <= 1672; j++){ results.push(j); }
      return results;
    }).apply(this));

    Weights = {
      attack_power: 1,
      agility: 1.1,
      crit: 0.87,
      haste: 1.44,
      mastery: 1.15,
      multistrike: 1.12,
      versatility: 1.2,
      strength: 1.05
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
      16: "offhand"
    };

    EP_PRE_REGEM = null;

    EP_TOTAL = null;

    $slots = null;

    $popupbody = null;

    $popup = null;

    ShadowcraftGear.initialized = false;

    getRandPropRow = function(slotIndex) {
      slotIndex = parseInt(slotIndex, 10);
      switch (slotIndex) {
        case 0:
        case 4:
        case 6:
          return 0;
        case 2:
        case 5:
        case 7:
        case 9:
        case 12:
        case 13:
          return 1;
        case 1:
        case 8:
        case 10:
        case 11:
        case 14:
          return 2;
        case 15:
        case 16:
          return 3;
        default:
          return 2;
      }
    };

    statOffset = function(gear, facet) {
      var offsets;
      offsets = {};
      if (gear) {
        Shadowcraft.Gear.sumSlot(gear, offsets, facet);
      }
      return offsets;
    };

    sumItem = function(s, i, key, ilvl_difference) {
      var newstats, stat;
      if (key == null) {
        key = 'stats';
      }
      if (ilvl_difference == null) {
        ilvl_difference = 0;
      }
      key || (key = 'stats');
      if (ilvl_difference !== 0) {
        newstats = recalculateStatsDiff(i[key], ilvl_difference);
      } else {
        newstats = i[key];
      }
      for (stat in newstats) {
        s[stat] || (s[stat] = 0);
        s[stat] += Math.round(newstats[stat]);
      }
      return null;
    };

    getEPForStatBlock = function(stats, ignore) {
      var stat, total, value;
      total = 0;
      for (stat in stats) {
        value = stats[stat];
        total += getStatWeight(stat, value, ignore) || 0;
      }
      return total;
    };

    getEP = function(item, slot, ignore) {
      var c, enchant, item_level, pre, proc_name, stats, total;
      if (slot == null) {
        slot = -1;
      }
      if (ignore == null) {
        ignore = [];
      }
      console.log("getEP: ignore = " + ignore);
      stats = {};
      sumItem(stats, item);
      total = getEPForStatBlock(stats, ignore);
      c = Shadowcraft.lastCalculation;
      if (c) {
        if (item.dps) {
          if (slot === 15) {
            total += (item.dps * c.mh_ep.mh_dps) + c.mh_speed_ep["mh_" + item.speed];
            if (c.mh_type_ep != null) {
              if (item.subclass === 15) {
                total += c.mh_type_ep["mh_type_dagger"];
              } else {
                total += c.mh_type_ep["mh_type_one-hander"];
              }
            }
          } else if (slot === 16) {
            total += (item.dps * c.oh_ep.oh_dps) + c.oh_speed_ep["oh_" + item.speed];
            if (c.oh_type_ep != null) {
              if (item.subclass === 15) {
                total += c.oh_type_ep["oh_type_dagger"];
              } else {
                total += c.oh_type_ep["oh_type_one-hander"];
              }
            }
          }
        } else if (PROC_ENCHANTS[item.id]) {
          switch (slot) {
            case 14:
              pre = "";
              break;
            case 15:
              pre = "mh_";
              break;
            case 16:
              pre = "oh_";
          }
          enchant = PROC_ENCHANTS[item.id];
          if (!pre && enchant) {
            total += c["other_ep"][enchant];
          } else if (pre && enchant) {
            total += c[pre + "ep"][pre + enchant];
          }
        }
        item_level = item.ilvl;
        if (c.trinket_map[item.id]) {
          proc_name = c.trinket_map[item.id];
          if (c.proc_ep[proc_name] && c.proc_ep[proc_name][item_level]) {
            total += c.proc_ep[proc_name][item_level];
          } else {
            console.warn("error in trinket_ranking", item_level, item.name);
          }
        }
      }
      return total;
    };

    ShadowcraftGear.prototype.sumSlot = function(gear, out, facets) {
      var enchant, enchant_id, gem, gid, item, len, m, ref;
      if ((gear != null ? gear.id : void 0) == null) {
        return;
      }
      facets || (facets = FACETS.ALL);
      item = getItem(gear.id, gear.context);
      if (item == null) {
        return;
      }
      if ((facets & FACETS.ITEM) === FACETS.ITEM) {
        sumItem(out, item, 'stats', gear.item_level - item.ilvl);
      }
      if ((facets & FACETS.GEMS) === FACETS.GEMS) {
        ref = gear.gems;
        for (m = 0, len = ref.length; m < len; m++) {
          gid = ref[m];
          if (gid && gid > 0) {
            gem = Shadowcraft.ServerData.GEM_LOOKUP[gid];
            if (gem) {
              sumItem(out, gem);
            }
          }
        }
      }
      if ((facets & FACETS.ENCHANT) === FACETS.ENCHANT) {
        enchant_id = gear.enchant;
        if (enchant_id && enchant_id > 0) {
          enchant = Shadowcraft.ServerData.ENCHANT_LOOKUP[enchant_id];
          if (enchant) {
            return sumItem(out, enchant);
          }
        }
      }
    };

    ShadowcraftGear.prototype.sumStats = function() {
      var data, i, len, m, si, stats;
      stats = {};
      data = Shadowcraft.Data;
      for (i = m = 0, len = SLOT_ORDER.length; m < len; i = ++m) {
        si = SLOT_ORDER[i];
        Shadowcraft.Gear.sumSlot(data.gear[si], stats, null);
      }
      this.statSum = stats;
      return stats;
    };

    ShadowcraftGear.prototype.getStat = function(stat) {
      if (!this.statSum) {
        this.sumStats();
      }
      return this.statSum[stat] || 0;
    };

    getStatWeight = function(stat, num, ignore, ignoreAll) {
      var exist, neg;
      exist = 0;
      if (!ignoreAll) {
        exist = Shadowcraft.Gear.getStat(stat);
        if (ignore && ignore[stat]) {
          exist -= ignore[stat];
        }
      }
      neg = num < 0 ? -1 : 1;
      num = Math.abs(num);
      return (Weights[stat] || 0) * num * neg;
    };

    sortComparator = function(a, b) {
      return b.__ep - a.__ep;
    };

    epSort = function(list) {
      var item, len, m;
      for (m = 0, len = list.length; m < len; m++) {
        item = list[m];
        if (item) {
          item.__ep = getEP(item);
        }
        if (isNaN(item.__ep)) {
          item.__ep = 0;
        }
      }
      return list.sort(sortComparator);
    };

    setBonusEP = function(set, count) {
      var bonus_name, c, p, ref, total;
      if (!(c = Shadowcraft.lastCalculation)) {
        return 0;
      }
      total = 0;
      ref = set.bonuses;
      for (p in ref) {
        bonus_name = ref[p];
        if (count === (p - 1)) {
          total += c["other_ep"][bonus_name];
        }
      }
      return total;
    };

    getEquippedSetCount = function(setIds, ignoreSlotIndex) {
      var count, gear, len, m, ref, slot;
      count = 0;
      for (m = 0, len = SLOT_ORDER.length; m < len; m++) {
        slot = SLOT_ORDER[m];
        if (SLOT_INVTYPES[slot] === ignoreSlotIndex) {
          continue;
        }
        gear = Shadowcraft.Data.gear[slot];
        if (ref = gear.id, indexOf.call(setIds, ref) >= 0) {
          count++;
        }
      }
      return count;
    };

    isProfessionalGem = function(gem, profession) {
      var ref;
      if (gem == null) {
        return false;
      }
      return (((ref = gem.requires) != null ? ref.profession : void 0) != null) && gem.requires.profession === profession;
    };

    canUseGem = function(gem) {
      var ref;
      if (((ref = gem.requires) != null ? ref.profession : void 0) != null) {
        if (isProfessionalGem(gem, 'jewelcrafting')) {
          return false;
        }
      }
      return true;
    };

    equalGemStats = function(from_gem, to_gem) {
      var stat;
      for (stat in from_gem["stats"]) {
        if ((to_gem["stats"][stat] == null) || from_gem["stats"][stat] !== to_gem["stats"][stat]) {
          return false;
        }
      }
      return true;
    };

    getGemmingRecommendation = function(gem_list, gear, offset) {
      var epValue, foundgem, gem, gems, len, m, sGems, straightGemEP;
      if (!hasSocket(gear)) {
        return {
          ep: 0,
          gems: []
        };
      }
      straightGemEP = 0;
      sGems = [];
      foundgem = false;
      for (m = 0, len = gem_list.length; m < len; m++) {
        gem = gem_list[m];
        if (!canUseGem(gem)) {
          continue;
        }
        straightGemEP += getEP(gem, null, offset);
        sGems.push(gem.id);
        foundgem = true;
        break;
      }
      if (!foundgem) {
        sGems.push(null);
      }
      epValue = straightGemEP;
      gems = sGems;
      return {
        ep: epValue,
        gems: gems
      };
    };

    ShadowcraftGear.prototype.lockAll = function() {
      var gear, len, m, slot;
      Shadowcraft.Console.log("Locking all items");
      for (m = 0, len = SLOT_ORDER.length; m < len; m++) {
        slot = SLOT_ORDER[m];
        gear = Shadowcraft.Data.gear[slot];
        gear.locked = true;
      }
      return Shadowcraft.Gear.updateDisplay();
    };

    ShadowcraftGear.prototype.unlockAll = function() {
      var gear, len, m, slot;
      Shadowcraft.Console.log("Unlocking all items");
      for (m = 0, len = SLOT_ORDER.length; m < len; m++) {
        slot = SLOT_ORDER[m];
        gear = Shadowcraft.Data.gear[slot];
        gear.locked = false;
      }
      return Shadowcraft.Gear.updateDisplay();
    };

    ShadowcraftGear.prototype.optimizeGems = function(depth) {
      var Gems, data, from_gem, gear, gem, gemIndex, gem_list, gem_offset, item, len, len1, m, madeChanges, n, rec, ref, ref1, slotIndex, to_gem;
      Gems = Shadowcraft.ServerData.GEM_LOOKUP;
      data = Shadowcraft.Data;
      depth || (depth = 0);
      if (depth === 0) {
        Shadowcraft.Console.purgeOld();
        EP_PRE_REGEM = this.getEPTotal();
        Shadowcraft.Console.log("Beginning auto-regem...", "gold underline");
      }
      madeChanges = false;
      gem_list = getGemRecommendationList();
      for (m = 0, len = SLOT_ORDER.length; m < len; m++) {
        slotIndex = SLOT_ORDER[m];
        slotIndex = parseInt(slotIndex, 10);
        gear = data.gear[slotIndex];
        if (!gear) {
          continue;
        }
        if (gear.locked) {
          continue;
        }
        if (ref = gear.id, indexOf.call(ShadowcraftGear.ARTIFACTS, ref) >= 0) {
          continue;
        }
        gem_offset = statOffset(gear, FACETS.GEMS);
        rec = getGemmingRecommendation(gem_list, gear, gem_offset);
        ref1 = rec.gems;
        for (gemIndex = n = 0, len1 = ref1.length; n < len1; gemIndex = ++n) {
          gem = ref1[gemIndex];
          from_gem = Gems[gear.gems[gemIndex]];
          to_gem = Gems[gem];
          if (to_gem == null) {
            continue;
          }
          if (gear.gems[gemIndex] !== gem) {
            item = getItem(gear.id, gear.context);
            if (from_gem && to_gem) {
              if (from_gem.name === to_gem.name) {
                continue;
              }
              if (equalGemStats(from_gem, to_gem)) {
                continue;
              }
              Shadowcraft.Console.log("Regemming " + item.name + " socket " + (gemIndex + 1) + " from " + from_gem.name + " to " + to_gem.name);
            } else {
              Shadowcraft.Console.log("Regemming " + item.name + " socket " + (gemIndex + 1) + " to " + to_gem.name);
            }
            gear.gems[gemIndex] = gem;
            madeChanges = true;
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

    getEnchantRecommendation = function(enchant_list, item) {
      var enchant, len, m, ref, ref1;
      for (m = 0, len = enchant_list.length; m < len; m++) {
        enchant = enchant_list[m];
        if ((((ref = enchant.requires) != null ? ref.max_item_level : void 0) != null) && ((ref1 = enchant.requires) != null ? ref1.max_item_level : void 0) < getBaseItemLevel(item)) {
          continue;
        }
        return enchant.id;
      }
      return false;
    };

    getApplicableEnchants = function(slotIndex, item, enchant_offset) {
      var enchant, enchant_list, enchants, len, m, ref, ref1;
      enchant_list = Shadowcraft.ServerData.ENCHANT_SLOTS[SLOT_INVTYPES[slotIndex]];
      if (enchant_list == null) {
        return [];
      }
      enchants = [];
      for (m = 0, len = enchant_list.length; m < len; m++) {
        enchant = enchant_list[m];
        if ((((ref = enchant.requires) != null ? ref.max_item_level : void 0) != null) && ((ref1 = enchant.requires) != null ? ref1.max_item_level : void 0) < getBaseItemLevel(item)) {
          continue;
        }
        enchant.__ep = getEP(enchant, slotIndex, enchant_offset);
        if (isNaN(enchant.__ep)) {
          enchant.__ep = 0;
        }
        enchants.push(enchant);
      }
      enchants.sort(sortComparator);
      return enchants;
    };

    ShadowcraftGear.prototype.getApplicableEnchants = function(slotIndex, item, enchant_offset) {
      return getApplicableEnchants(slotIndex, item, enchant_offset);
    };

    ShadowcraftGear.prototype.optimizeEnchants = function(depth) {
      var Enchants, data, enchantId, enchant_offset, enchants, from_enchant, gear, item, len, m, madeChanges, slotIndex, to_enchant;
      Enchants = Shadowcraft.ServerData.ENCHANT_LOOKUP;
      data = Shadowcraft.Data;
      depth || (depth = 0);
      if (depth === 0) {
        Shadowcraft.Console.purgeOld();
        EP_PRE_REGEM = this.getEPTotal();
        Shadowcraft.Console.log("Beginning auto-enchant...", "gold underline");
      }
      madeChanges = false;
      for (m = 0, len = SLOT_ORDER.length; m < len; m++) {
        slotIndex = SLOT_ORDER[m];
        slotIndex = parseInt(slotIndex, 10);
        gear = data.gear[slotIndex];
        if (!gear) {
          continue;
        }
        if (gear.locked) {
          continue;
        }
        item = getItem(gear.id, gear.context);
        if (!item) {
          continue;
        }
        enchant_offset = statOffset(gear, FACETS.ENCHANT);
        enchants = getApplicableEnchants(slotIndex, item, enchant_offset);
        if (item) {
          enchantId = getEnchantRecommendation(enchants, item);
          if (enchantId) {
            from_enchant = Enchants[gear.enchant];
            to_enchant = Enchants[enchantId];
            if (from_enchant && to_enchant) {
              if (from_enchant.id === to_enchant.id) {
                continue;
              }
              Shadowcraft.Console.log("Change enchant of " + item.name + " from " + from_enchant.name + " to " + to_enchant.name);
            } else {
              Shadowcraft.Console.log("Enchant " + item.name + " with " + to_enchant.name);
            }
            gear.enchant = enchantId;
            madeChanges = true;
          }
        }
      }
      if (!madeChanges || depth >= 10) {
        this.app.update();
        this.updateDisplay();
        return Shadowcraft.Console.log("Finished automatic enchanting: &Delta; " + (Math.floor(this.getEPTotal() - EP_PRE_REGEM)) + " EP", "gold");
      } else {
        return this.optimizeEnchants(depth + 1);
      }
    };

    getBestNormalGem = function() {
      var Gems, copy, gem, len, list, m, ref;
      Gems = Shadowcraft.ServerData.GEMS;
      copy = $.extend(true, [], Gems);
      list = [];
      for (m = 0, len = copy.length; m < len; m++) {
        gem = copy[m];
        if ((gem.requires != null) || (((ref = gem.requires) != null ? ref.profession : void 0) != null)) {
          continue;
        }
        gem.__color_ep = gem.__color_ep || getEP(gem);
        if ((gem["Red"] || gem["Yellow"] || gem["Blue"]) && gem.__color_ep && gem.__color_ep > 1) {
          list.push(gem);
        }
      }
      list.sort(function(a, b) {
        return b.__color_ep - a.__color_ep;
      });
      return list[0];
    };

    getGemRecommendationList = function() {
      var Gems, copy, gem, len, list, m, use_epic_gems;
      Gems = Shadowcraft.ServerData.GEMS;
      copy = $.extend(true, [], Gems);
      list = [];
      use_epic_gems = Shadowcraft.Data.options.general.epic_gems === 1;
      for (m = 0, len = copy.length; m < len; m++) {
        gem = copy[m];
        if (gem.quality === 4 && gem.requires === void 0 && !use_epic_gems) {
          continue;
        }
        gem.normal_ep = getEP(gem);
        if (gem.normal_ep && gem.normal_ep > 1) {
          list.push(gem);
        }
      }
      list.sort(function(a, b) {
        return b.normal_ep - a.normal_ep;
      });
      return list;
    };

    clearBonuses = function() {
      console.log('clear');
    };

    ShadowcraftGear.prototype.applyBonuses = function() {
      var bonus, checkedBonuses, currentBonuses, data, entry, gear, item, len, len1, m, n, newBonuses, ref, slot, uncheckedBonuses, union;
      Shadowcraft.Console.purgeOld();
      data = Shadowcraft.Data;
      slot = $.data(document.body, "selecting-slot");
      gear = data.gear[slot];
      if (!gear) {
        return;
      }
      item = getItem(gear.id, gear.context);
      currentBonuses = [];
      if (gear.bonuses != null) {
        currentBonuses = gear.bonuses;
      }
      checkedBonuses = [];
      uncheckedBonuses = [];
      $("#bonuses input:checkbox").each(function() {
        var val;
        val = parseInt($(this).val(), 10);
        if ($(this).is(':checked')) {
          return checkedBonuses.push(val);
        } else {
          return uncheckedBonuses.push(val);
        }
      });
      $("#bonuses select option").each(function() {
        var val;
        val = parseInt($(this).val(), 10);
        if ($(this).is(':selected') && !isNaN(val)) {
          return checkedBonuses.push(val);
        } else if (!isNaN(val)) {
          return uncheckedBonuses.push(val);
        }
      });
      union = _.union(currentBonuses, checkedBonuses);
      newBonuses = _.difference(union, uncheckedBonuses);
      gear.bonuses = newBonuses;
      gear.item_level = item.ilvl + (gear.upgrade_level * getUpgradeLevelSteps(item));
      for (m = 0, len = newBonuses.length; m < len; m++) {
        bonus = newBonuses[m];
        if (indexOf.call(ShadowcraftGear.WF_BONUS_IDS, bonus) >= 0) {
          ref = Shadowcraft.ServerData.ITEM_BONUSES[bonus];
          for (n = 0, len1 = ref.length; n < len1; n++) {
            entry = ref[n];
            if (entry.type === 1) {
              gear.item_level += entry.val1;
            }
          }
        }
      }
      $("#bonuses").removeClass("visible");
      Shadowcraft.update();
      return Shadowcraft.Gear.updateDisplay();
    };

    hasSocket = function(gear) {
      var bonus, len, m, n, ref, results1, socketBonuses;
      socketBonuses = [523, 572, 608];
      socketBonuses = socketBonuses.concat([563, 564, 565]);
      socketBonuses = socketBonuses.concat([715, 716, 717, 718, 719]);
      socketBonuses = socketBonuses.concat((function() {
        results1 = [];
        for (m = 721; m <= 752; m++){ results1.push(m); }
        return results1;
      }).apply(this));
      ref = gear.bonuses;
      for (n = 0, len = ref.length; n < len; n++) {
        bonus = ref[n];
        if (indexOf.call(socketBonuses, bonus) >= 0) {
          return true;
        }
      }
      return false;
    };


    /*
     * View helpers
     */

    sortTagBonuses = function(a, b) {
      return a.position - b.position;
    };

    makeTag = function(bonuses) {
      var bonus, bonus_entry, len, len1, len2, m, n, o, ref, tag, tag_bonus, tag_bonuses;
      tag_bonuses = [];
      for (m = 0, len = bonuses.length; m < len; m++) {
        bonus = bonuses[m];
        if (!bonus) {
          continue;
        }
        ref = Shadowcraft.ServerData.ITEM_BONUSES[bonus];
        for (n = 0, len1 = ref.length; n < len1; n++) {
          bonus_entry = ref[n];
          if (bonus_entry.type === 4) {
            tag_bonus = {
              position: bonus_entry.val2,
              desc_id: bonus_entry.val1
            };
            tag_bonuses.push(tag_bonus);
          }
        }
      }
      tag = "";
      if (tag_bonuses.length > 0) {
        tag_bonuses.sort(sortTagBonuses);
        for (o = 0, len2 = tag_bonuses.length; o < len2; o++) {
          bonus = tag_bonuses[o];
          if (tag.length > 0) {
            tag += " ";
          }
          tag += Shadowcraft.ServerData.ITEM_DESCRIPTIONS[bonus['desc_id']];
        }
      }
      return tag;
    };

    ShadowcraftGear.prototype.updateDisplay = function() {
      var EnchantLookup, EnchantSlots, Gems, base, bonusId, bonus_entry, bonus_keys, bonusable, bonuses, buffer, curr_level, data, enchant, enchantable, gear, gem, gems, i, item, len, len1, len2, len3, len4, m, max_level, n, o, opt, q, ref, ref1, ref2, ref3, ref4, slotIndex, slotSet, sockets, ssi, tag, ttgems, u, upgrade;
      EnchantLookup = Shadowcraft.ServerData.ENCHANT_LOOKUP;
      EnchantSlots = Shadowcraft.ServerData.ENCHANT_SLOTS;
      Gems = Shadowcraft.ServerData.GEM_LOOKUP;
      data = Shadowcraft.Data;
      opt = {};
      for (ssi = m = 0, len = SLOT_DISPLAY_ORDER.length; m < len; ssi = ++m) {
        slotSet = SLOT_DISPLAY_ORDER[ssi];
        buffer = "";
        for (slotIndex = n = 0, len1 = slotSet.length; n < len1; slotIndex = ++n) {
          i = slotSet[slotIndex];
          (base = data.gear)[i] || (base[i] = {});
          gear = data.gear[i];
          item = getItem(gear.id, gear.context);
          gems = [];
          sockets = [];
          bonuses = null;
          enchant = EnchantLookup[gear.enchant];
          enchantable = null;
          bonusable = null;
          if (item) {
            enchantable = (ref = gear.id, indexOf.call(ShadowcraftGear.ARTIFACTS, ref) < 0) && (EnchantSlots[item.equip_location] != null) && getApplicableEnchants(i, item).length > 0;
            bonus_keys = _.keys(Shadowcraft.ServerData.ITEM_BONUSES);
            tag = "";
            if ((gear.bonuses != null)) {
              tag = makeTag(gear.bonuses);
            }
            if (tag.length === 0) {
              tag = item.tag;
            }
            if (item.chance_bonus_lists != null) {
              ref1 = item.chance_bonus_lists;
              for (o = 0, len2 = ref1.length; o < len2; o++) {
                bonusId = ref1[o];
                if (bonusId == null) {
                  continue;
                }
                if (bonusable) {
                  break;
                }
                ref2 = Shadowcraft.ServerData.ITEM_BONUSES[bonusId];
                for (q = 0, len3 = ref2.length; q < len3; q++) {
                  bonus_entry = ref2[q];
                  switch (bonus_entry.type) {
                    case 6:
                      bonusable = true;
                      break;
                    case 2:
                      bonusable = true;
                      break;
                  }
                }
              }
            }
            if (enchant && !enchant.desc) {
              enchant.desc = statsToDesc(enchant);
            }
            if (item.upgradable) {
              curr_level = "0";
              if (gear.upgrade_level != null) {
                curr_level = gear.upgrade_level.toString();
              }
              max_level = getMaxUpgradeLevel(item);
              upgrade = {
                curr_level: curr_level,
                max_level: max_level
              };
            }
            ref3 = gear.gems;
            for (u = 0, len4 = ref3.length; u < len4; u++) {
              gem = ref3[u];
              if (gem !== 0) {
                gems[gems.length] = {
                  gem: Gems[gem]
                };
              }
            }
          }
          if (enchant && enchant.desc === "") {
            enchant.desc = enchant.name;
          }
          ttgems = gear.gems.join(":");
          opt = {};
          opt.item = item;
          opt.tag = tag;
          if (item) {
            opt.identifier = item.id + ":" + item.ilvl + ":" + (item.suffix || 0);
          }
          if (item) {
            opt.ttid = item.id;
          }
          opt.ttrand = item ? item.suffix : null;
          opt.ttupgd = item ? upgrade['curr_level'] : null;
          opt.ttbonus = gear.bonuses ? gear.bonuses.join(":") : null;
          opt.ttgems = ttgems !== "0:0:0" ? ttgems : null;
          opt.ep = item ? getEP(item, i).toFixed(1) : 0;
          opt.slot = i + '';
          opt.bonusable = bonusable;
          opt.socketbonus = bonuses;
          opt.enchantable = enchantable;
          opt.enchant = enchant;
          opt.upgradable = item ? item.upgradable : false;
          opt.upgrade = upgrade;
          opt.gems = gear.gems;
          if (item && (ref4 = item.id, indexOf.call(ShadowcraftGear.ARTIFACTS, ref4) < 0)) {
            opt.sockets = item.sockets;
            opt.gems = gems;
          } else {
            opt.sockets = null;
            opt.gems = null;
          }
          if (item) {
            opt.lock = true;
            if (gear.locked) {
              opt.lock_class = "lock_on";
            } else {
              opt.lock_class = "lock_off";
            }
          }
          buffer += Templates.itemSlot(opt);
        }
        $slots.get(ssi).innerHTML = buffer;
      }
      this.updateStatsWindow();
      this.updateSummaryWindow();
      return checkForWarnings('gear');
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

    ShadowcraftGear.prototype.updateSummaryWindow = function() {
      var $summary, a_stats, data, valengine;
      data = Shadowcraft.Data;
      $summary = $("#summary .inner");
      a_stats = [];
      if (data.options.general.patch) {
        if (data.options.general.patch === 60) {
          valengine = "6.2";
        } else {
          valengine = data.options.general.patch / 10;
        }
      } else {
        valengine = "6.x";
      }
      a_stats.push({
        name: "Engine",
        val: valengine
      });
      a_stats.push({
        name: "Spec",
        val: ShadowcraftTalents.GetActiveSpecName() || "n/a"
      });
      a_stats.push({
        name: "Boss Adds",
        val: (data.options.general.num_boss_adds != null) && (data.options.general.num_boss_adds > 0) ? Math.min(4, data.options.general.num_boss_adds) : "0"
      });
      if (ShadowcraftTalents.GetActiveSpecName() === "Combat") {
        a_stats.push({
          name: "Blade Flurry",
          val: data.options.rotation.blade_flurry ? "ON" : "OFF"
        });
      } else if (ShadowcraftTalents.GetActiveSpecName() === "Subtlety") {
        a_stats.push({
          name: "CP Builder",
          val: (function() {
            switch (data.options.rotation.use_hemorrhage) {
              case "never":
                return "Backstab";
              case "always":
                return "Hemorrhage";
              case "uptime":
                return "Backstab w/ Hemo";
            }
          })()
        });
      }
      if (data.options.general.lethal_poison) {
        a_stats.push({
          name: "Poison",
          val: (function() {
            switch (data.options.general.lethal_poison) {
              case "wp":
                return "Wound";
              case "dp":
                return "Deadly";
            }
          })()
        });
      }
      return $summary.get(0).innerHTML = Templates.stats({
        stats: a_stats
      });
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
      EP_TOTAL = total;
      return $stats.get(0).innerHTML = Templates.stats({
        stats: a_stats
      });
    };

    updateStatWeights = function(source) {
      var $weights, all, exist, key, other, weight;
      Weights.agility = source.ep.agi;
      Weights.crit = source.ep.crit;
      Weights.strength = source.ep.str;
      Weights.mastery = source.ep.mastery;
      Weights.haste = source.ep.haste;
      Weights.multistrike = source.ep.multistrike;
      Weights.versatility = source.ep.versatility;
      other = {
        mainhand_dps: Shadowcraft.lastCalculation.mh_ep.mh_dps,
        offhand_dps: Shadowcraft.lastCalculation.oh_ep.oh_dps,
        t18_2pc: source.other_ep.rogue_t18_2pc || 0,
        t18_4pc: source.other_ep.rogue_t18_4pc || 0,
        t18_4pc_lfr: source.other_ep.rogue_t18_4pc_lfr || 0,
        t19_2pc: source.other_ep.rogue_t19_2pc || 0,
        t19_4pc: source.other_ep.rogue_t19_4pc || 0,
        orderhall_8pc: source.other_ep.rogue_orderhall_8pc || 0
      };
      all = _.extend(Weights, other);
      $weights = $("#weights .inner");
      $weights.empty();
      for (key in all) {
        weight = all[key];
        if (isNaN(weight)) {
          continue;
        }
        if (weight === 0) {
          continue;
        }
        exist = $(".stat#weight_" + key);
        if (exist.length > 0) {
          exist.find("val").text(weight.toFixed(3));
        } else {
          $weights.append("<div class='stat' id='weight_" + key + "'><span class='key'>" + (titleize(key)) + "</span><span class='val'>" + (Weights[key].toFixed(3)) + "</span></div>");
          exist = $(".stat#weight_" + key);
          $.data(exist.get(0), "sortkey", 0);
          if (key === "mainhand_dps" || key === "offhand_dps") {
            $.data(exist.get(0), "sortkey", 1);
          } else if (key === "t18_2pc" || key === "t18_4pc" || key === "t18_4pc_lfr" || key === "t19_2pc" || key === "t19_4pc" || key === "rogue_orderhall_8pc") {
            $.data(exist.get(0), "sortkey", 2);
          }
        }
        $.data(exist.get(0), "weight", weight);
      }
      $("#weights .stat").sortElements(function(a, b) {
        var as, bs;
        as = $.data(a, "sortkey");
        bs = $.data(b, "sortkey");
        if (as !== bs) {
          if (as > bs) {
            return 1;
          } else {
            return -1;
          }
        } else {
          if ($.data(a, "weight") > $.data(b, "weight")) {
            return -1;
          } else {
            return 1;
          }
        }
      });
      return epSort(Shadowcraft.ServerData.GEMS);
    };

    updateEngineInfoWindow = function() {
      var $summary, data, engine_info, name, val;
      if (Shadowcraft.lastCalculation.engine_info == null) {
        return;
      }
      engine_info = Shadowcraft.lastCalculation.engine_info;
      $summary = $("#engineinfo .inner");
      data = [];
      for (name in engine_info) {
        val = engine_info[name];
        data.push({
          name: titleize(name),
          val: val
        });
      }
      return $summary.get(0).innerHTML = Templates.stats({
        stats: data
      });
    };

    updateDpsBreakdown = function() {
      var buffer, dps_breakdown, exist, max, name, pct, pct_dps, rankings, skill, target, total_dps, val;
      dps_breakdown = Shadowcraft.lastCalculation.breakdown;
      total_dps = Shadowcraft.lastCalculation.total_dps;
      max = null;
      buffer = "";
      target = $("#dpsbreakdown .inner");
      rankings = _.extend({}, dps_breakdown);
      max = _.max(rankings);
      $("#dpsbreakdown .talent_contribution").hide();
      for (skill in dps_breakdown) {
        val = dps_breakdown[skill];
        skill = skill.replace('(', '').replace(')', '').split(' ').join('_');
        val = parseFloat(val);
        name = titleize(skill);
        skill = skill.replace(/\./g, '_');
        exist = $("#dpsbreakdown #talent-weight-" + skill);
        if (isNaN(val)) {
          name += " (NYI)";
          val = 0;
        }
        pct = val / max * 100 + 0.01;
        pct_dps = val / total_dps * 100;
        if (exist.length === 0) {
          buffer = Templates.talentContribution({
            name: name + " (" + (val.toFixed(1)) + " DPS)",
            raw_name: skill,
            val: val.toFixed(1),
            width: pct
          });
          target.append(buffer);
        }
        exist = $("#dpsbreakdown #talent-weight-" + skill);
        $.data(exist.get(0), "val", val);
        exist.show().find(".pct-inner").css({
          width: pct + "%"
        });
        exist.find(".label").text(pct_dps.toFixed(2) + "%");
      }
      return $("#dpsbreakdown .talent_contribution").sortElements(function(a, b) {
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

    getItem = function(itemId, context) {
      var arm, item, itemString;
      if ((indexOf.call(ShadowcraftGear.ARTIFACTS, itemId) >= 0)) {
        item = Shadowcraft.Data.artifact_items[itemId];
      } else {
        arm = [itemId, context];
        itemString = arm.join(':');
        item = Shadowcraft.ServerData.ITEM_BY_CONTEXT[itemString];
      }
      if ((item == null) && itemId) {
        console.warn("item not found by context", itemString);
      }
      return item;
    };

    ShadowcraftGear.prototype.getItem = function(itemId, context) {
      return getItem(itemId, context);
    };

    getMaxUpgradeLevel = function(item) {
      return 2;
    };

    getUpgradeLevelSteps = function(item) {
      return 5;
    };

    needsDagger = function() {
      return Shadowcraft.Data.activeSpec === "a";
    };

    recalculateStatsDiff = function(original, ilvl_difference) {
      var k, multiplier, stats, v;
      multiplier = 1.0 / Math.pow(1.15, ilvl_difference / 15.0 * -1);
      stats = {};
      for (k in original) {
        v = original[k];
        stats[k] = v * multiplier;
      }
      return stats;
    };

    recalculateStats = function(original, old_ilvl, new_ilvl) {
      return recalculateStatsDiff(original, new_ilvl - old_ilvl);
    };

    clickSlotName = function() {
      var $slot, GemList, bonus, bonus_trees, bonuses, buf, buffer, clone, curr_level, entry, equip_location, equipped, gear, gear_offset, gem_offset, hasUpgrade, iEP, l, len, len1, len2, len3, len4, len5, lid, loc, loc_all, m, maxIEP, max_level, minIEP, n, o, q, ref, ref1, ref2, ref3, ref4, ref5, requireDagger, selected_identifier, set, setBonEP, setCount, set_name, slot, subtletyNeedsDagger, ttbonus, ttid, ttrand, ttupgd, u, upgrade, w;
      buf = clickSlot(this, "item_id");
      $slot = buf[0];
      slot = buf[1];
      selected_identifier = $slot.data("identifier");
      equip_location = SLOT_INVTYPES[slot];
      GemList = Shadowcraft.ServerData.GEMS;
      gear = Shadowcraft.Data.gear;
      equipped = gear[slot];
      requireDagger = needsDagger();
      subtletyNeedsDagger = Shadowcraft.Data.activeSpec === "b" && ((ref = Shadowcraft.Data.options.rotation.use_hemorrhage) === 'uptime' || ref === 'never');
      loc_all = Shadowcraft.ServerData.SLOT_CHOICES[equip_location];
      loc = [];
      for (m = 0, len = loc_all.length; m < len; m++) {
        lid = loc_all[m];
        l = ShadowcraftData.ITEM_LOOKUP2[lid];
        if (lid === selected_identifier) {
          loc.push(l);
          hasUpgrade = false;
          bonuses = $(equipped.bonuses).not(l.bonus_tree).get();
          for (n = 0, len1 = bonuses.length; n < len1; n++) {
            bonus = bonuses[n];
            if (bonus === "") {
              continue;
            }
            ref1 = ShadowcraftData.ITEM_BONUSES[bonus];
            for (o = 0, len2 = ref1.length; o < len2; o++) {
              entry = ref1[o];
              if (entry.type === 1) {
                hasUpgrade = true;
                break;
              }
            }
            if (hasUpgrade) {
              break;
            }
          }
          if (hasUpgrade) {
            clone = $.extend({}, l);
            clone.identifier = "" + clone.id + ":" + equipped.item_level + ":0";
            clone.ilvl = equipped.item_level;
            clone.bonus_tree = equipped.bonuses;
            clone.tag = makeTag(equipped.bonuses);
            clone.stats = recalculateStats(l.stats, l.ilvl, equipped.item_level);
            clone.upgrade_level = equipped.upgrade_level;
            loc.push(clone);
            selected_identifier = clone.identifier;
          }
          continue;
        }
        if (l.id === 124636) {
          continue;
        }
        if (slot === 15) {
          if (Shadowcraft.Data.activeSpec === "a" && l.id !== 128870) {
            continue;
          }
          if (Shadowcraft.Data.activeSpec === "Z" && l.id !== 128872) {
            continue;
          }
          if (Shadowcraft.Data.activeSpec === "b" && l.id !== 128476) {
            continue;
          }
        }
        if (slot === 16) {
          if (Shadowcraft.Data.activeSpec === "a" && l.id !== 128869) {
            continue;
          }
          if (Shadowcraft.Data.activeSpec === "Z" && l.id !== 134552) {
            continue;
          }
          if (Shadowcraft.Data.activeSpec === "b" && l.id !== 128479) {
            continue;
          }
        }
        if (l.ilvl > Shadowcraft.Data.options.general.max_ilvl) {
          continue;
        }
        if (l.ilvl < Shadowcraft.Data.options.general.min_ilvl) {
          continue;
        }
        if ((slot === 15 || slot === 16) && requireDagger && l.subclass !== 15) {
          continue;
        }
        if ((slot === 15) && subtletyNeedsDagger && l.subclass !== 15) {
          continue;
        }
        if (slot === 12 && l.id === gear[13].id) {
          continue;
        }
        if (slot === 13 && l.id === gear[12].id) {
          continue;
        }
        if (slot === 10 && (ref2 = gear[11].id, indexOf.call(LEGENDARY_RINGS, ref2) >= 0) && (ref3 = l.id, indexOf.call(LEGENDARY_RINGS, ref3) >= 0)) {
          continue;
        }
        if (slot === 11 && (ref4 = gear[10].id, indexOf.call(LEGENDARY_RINGS, ref4) >= 0) && (ref5 = l.id, indexOf.call(LEGENDARY_RINGS, ref5) >= 0)) {
          continue;
        }
        if (slot === 10 && (l.tag != null) && (/Tournament$/.test(l.tag) || /Season [0-9]$/.test(l.tag)) && l.tag === gear[11].tag && l.name === gear[11].name) {
          continue;
        }
        if (slot === 11 && (l.tag != null) && (/Tournament$/.test(l.tag) || /Season [0-9]$/.test(l.tag)) && l.tag === gear[10].tag && l.name === gear[10].name) {
          continue;
        }
        loc.push(l);
      }
      gear_offset = statOffset(gear[slot], FACETS.ITEM);
      gem_offset = statOffset(gear[slot], FACETS.GEMS);
      epSort(GemList);
      setBonEP = {};
      for (set_name in Sets) {
        set = Sets[set_name];
        setCount = getEquippedSetCount(set.ids, equip_location);
        setBonEP[set_name] || (setBonEP[set_name] = 0);
        setBonEP[set_name] += setBonusEP(set, setCount);
      }
      for (q = 0, len3 = loc.length; q < len3; q++) {
        l = loc[q];
        l.__setBonusEP = 0;
        for (set_name in Sets) {
          set = Sets[set_name];
          if (set.ids.indexOf(l.id) >= 0) {
            l.__setBonusEP += setBonEP[set_name];
          }
        }
        l.__gearEP = getEP(l, slot, gear_offset);
        if (isNaN(l.__gearEP)) {
          l.__gearEP = 0;
        }
        if (isNaN(l.__setBonusEP)) {
          l.__setBonusEP = 0;
        }
        l.__ep = l.__gearEP + l.__setBonusEP;
      }
      loc.sort(sortComparator);
      maxIEP = 1;
      minIEP = 0;
      buffer = "";
      for (u = 0, len4 = loc.length; u < len4; u++) {
        l = loc[u];
        if (l.__ep < 1) {
          continue;
        }
        if (!isNaN(l.__ep)) {
          if (maxIEP <= 1) {
            maxIEP = l.__ep;
          }
          minIEP = l.__ep;
        }
      }
      maxIEP -= minIEP;
      for (w = 0, len5 = loc.length; w < len5; w++) {
        l = loc[w];
        if (l.__ep < 1) {
          continue;
        }
        iEP = l.__ep;
        ttid = l.id;
        ttrand = l.suffix != null ? l.suffix : "";
        ttupgd = l.upgradable ? l.upgrade_level : "";
        ttbonus = l.bonus_tree != null ? l.bonus_tree.join(":") : "";
        if (l.identifier === selected_identifier) {
          bonus_trees = gear[slot].bonuses;
          ttbonus = bonus_trees.join(":");
        }
        upgrade = [];
        if (l.upgradable) {
          curr_level = "0";
          if (l.upgrade_level != null) {
            curr_level = l.upgrade_level.toString();
          }
          max_level = getMaxUpgradeLevel(l);
          upgrade = {
            curr_level: curr_level,
            max_level: max_level
          };
        }
        buffer += Templates.itemSlot({
          item: l,
          tag: l.tag,
          identifier: l.id + ":" + l.ilvl + ":" + (l.suffix || 0),
          gear: {},
          gems: [],
          upgradable: l.upgradable,
          upgrade: upgrade,
          ttid: ttid,
          ttrand: ttrand,
          ttupgd: ttupgd,
          ttbonus: ttbonus,
          desc: (l.__gearEP.toFixed(1)) + " base " + (l.__setBonusEP > 0 ? "/ " + l.__setBonusEP.toFixed(1) + " set" : "") + " ",
          search: escape(l.name + " " + l.tag),
          percent: Math.max((iEP - minIEP) / maxIEP * 100, 0.01),
          ep: iEP.toFixed(1)
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
      $popupbody.get(0).innerHTML = buffer;
      $popupbody.find(".slot[data-identifier='" + selected_identifier + "']").addClass("active");
      showPopup($popup);
      return false;
    };

    clickSlotEnchant = function() {
      var EnchantSlots, buf, buffer, data, eEP, enchant, enchants, equip_location, gear, item, len, len1, m, max, n, offset, ref, ref1, selected_id, slot;
      data = Shadowcraft.Data;
      EnchantSlots = Shadowcraft.ServerData.ENCHANT_SLOTS;
      buf = clickSlot(this, "enchant");
      slot = buf[1];
      equip_location = SLOT_INVTYPES[slot];
      enchants = EnchantSlots[equip_location];
      max = 0;
      gear = Shadowcraft.Data.gear[slot];
      offset = statOffset(gear, FACETS.ENCHANT);
      item = getItem(gear.id, gear.context);
      for (m = 0, len = enchants.length; m < len; m++) {
        enchant = enchants[m];
        enchant.__ep = getEP(enchant, slot, offset);
        if (isNaN(enchant.__ep)) {
          enchant.__ep = 0;
        }
        max = enchant.__ep > max ? enchant.__ep : max;
      }
      enchants.sort(sortComparator);
      selected_id = data.gear[slot].enchant;
      buffer = "";
      for (n = 0, len1 = enchants.length; n < len1; n++) {
        enchant = enchants[n];
        if ((((ref = enchant.requires) != null ? ref.max_item_level : void 0) != null) && ((ref1 = enchant.requires) != null ? ref1.max_item_level : void 0) < getBaseItemLevel(item)) {
          continue;
        }
        if (enchant && !enchant.desc) {
          enchant.desc = statsToDesc(enchant);
        }
        if (enchant && enchant.desc === "") {
          enchant.desc = enchant.name;
        }
        eEP = enchant.__ep;
        if (eEP < 1) {
          continue;
        }
        buffer += Templates.itemSlot({
          item: enchant,
          percent: eEP / max * 100,
          ep: eEP.toFixed(1),
          search: escape(enchant.name + " " + enchant.desc),
          desc: enchant.desc,
          ttid: enchant.tooltip_spell
        });
      }
      buffer += Templates.itemSlot({
        item: {
          name: "[No enchant]"
        },
        desc: "Clear this enchant",
        percent: 0,
        ep: 0
      });
      $popupbody.get(0).innerHTML = buffer;
      $popupbody.find(".slot[id='" + selected_id + "']").addClass("active");
      showPopup($popup);
      return false;
    };

    getBaseItemLevel = function(item) {
      if (!item.upgrade_level) {
        return item.ilvl;
      }
      return item.ilvl - getUpgradeLevelSteps(item) * item.upgrade_level;
    };

    clickSlotGem = function() {
      var $slot, GemList, buf, buffer, data, desc, gEP, gem, gemSlot, gemType, i, len, len1, m, max, n, o, otherGearGems, selected_gem_id, slot, usedNames;
      GemList = Shadowcraft.ServerData.GEMS;
      data = Shadowcraft.Data;
      buf = clickSlot(this, "gem");
      $slot = buf[0];
      slot = buf[1];
      gemSlot = $slot.find(".gem").index(this);
      $.data(document.body, "gem-slot", gemSlot);
      selected_gem_id = data.gear[slot].gems[gemSlot];
      gemType = Shadowcraft.ServerData.GEM_LOOKUP[selected_gem_id].slot;
      otherGearGems = [];
      for (i = m = 0; m <= 2; i = ++m) {
        if (i === gemSlot) {
          continue;
        }
        if (data.gear[slot].gems[i]) {
          otherGearGems.push(data.gear[slot].gems[i]);
        }
      }
      for (n = 0, len = GemList.length; n < len; n++) {
        gem = GemList[n];
        gem.__ep = getEP(gem);
      }
      GemList.sort(sortComparator);
      buffer = "";
      usedNames = {};
      max = null;
      for (o = 0, len1 = GemList.length; o < len1; o++) {
        gem = GemList[o];
        if (usedNames[gem.name]) {
          if (gem.id === selected_gem_id) {
            selected_gem_id = usedNames[gem.name];
          }
          continue;
        }
        usedNames[gem.name] = gem.id;
        if (gem.name.indexOf("Perfect") === 0 && selected_gem_id !== gem.id) {
          continue;
        }
        if (!canUseGem(gem, gemType)) {
          continue;
        }
        max || (max = gem.__ep);
        gEP = gem.__ep;
        desc = statsToDesc(gem);
        if (gEP < 1) {
          continue;
        }
        buffer += Templates.itemSlot({
          item: gem,
          ep: gEP.toFixed(1),
          gear: {},
          ttid: gem.id,
          search: escape(gem.name + " " + statsToDesc(gem) + " " + gem.slot),
          percent: gEP / max * 100,
          desc: desc
        });
      }
      buffer += Templates.itemSlot({
        item: {
          name: "[No gem]"
        },
        desc: "Clear this gem",
        percent: 0,
        ep: 0
      });
      $popupbody.get(0).innerHTML = buffer;
      $popupbody.find(".slot[id='" + selected_gem_id + "']").addClass("active");
      showPopup($popup);
      return false;
    };

    clickSlotBonuses = function() {
      var $slot, base_item_ep, bonusId, bonus_entry, currentBonuses, current_tf_id, current_tf_value, data, entry, gear, gear_stats, gem, group, groups, ilvl_bonus, item, key, len, len1, len2, len3, m, n, new_ilvl, o, q, ref, ref1, ref2, slot, subgroup, temp_ep, temp_stats, val;
      clickSlot(this, "bonuses");
      $(".slot").removeClass("active");
      $(this).addClass("active");
      data = Shadowcraft.Data;
      $slot = $(this).closest(".slot");
      slot = parseInt($slot.data("slot"), 10);
      $.data(document.body, "selecting-slot", slot);
      gear = data.gear[slot];
      currentBonuses = gear.bonuses;
      item = getItem(gear.id, gear.context);
      gear_stats = [];
      sumItem(gear_stats, item);
      base_item_ep = getEPForStatBlock(gear_stats);
      current_tf_id = 0;
      current_tf_value = 0;
      for (m = 0, len = currentBonuses.length; m < len; m++) {
        bonusId = currentBonuses[m];
        if (indexOf.call(ShadowcraftGear.WF_BONUS_IDS, bonusId) >= 0) {
          current_tf_id = bonusId;
          ref = Shadowcraft.ServerData.ITEM_BONUSES[current_tf_id];
          for (n = 0, len1 = ref.length; n < len1; n++) {
            val = ref[n];
            if (val.type === 1) {
              current_tf_value = val.val1;
            }
          }
        }
      }
      groups = {
        suffixes: [],
        tertiary: [],
        sockets: [],
        titanforged: []
      };
      ref1 = item.chance_bonus_lists;
      for (o = 0, len2 = ref1.length; o < len2; o++) {
        bonusId = ref1[o];
        group = {};
        group['bonusId'] = bonusId;
        if (_.contains(currentBonuses, bonusId)) {
          group['active'] = true;
        }
        group['entries'] = [];
        group.ep = 0;
        subgroup = null;
        ref2 = Shadowcraft.ServerData.ITEM_BONUSES[bonusId];
        for (q = 0, len3 = ref2.length; q < len3; q++) {
          bonus_entry = ref2[q];
          entry = {
            'type': bonus_entry.type,
            'val1': bonus_entry.val1,
            'val2': bonus_entry.val2
          };
          switch (bonus_entry.type) {
            case 6:
              console.log("extra socket");
              group['entries'].push(entry);
              gem = getBestNormalGem();
              group.ep += getEP(gem);
              subgroup = "sockets";
              break;
            case 5:
              group['entries'].push(entry);
              subgroup = "suffixes";
              break;
            case 2:
              entry['val2'] = Math.round(bonus_entry.val2 / 10000 * Shadowcraft.ServerData.RAND_PROP_POINTS[item.ilvl][1 + getRandPropRow(slot)]);
              entry['val1'] = bonus_entry.val1;
              group['entries'].push(entry);
              group.ep += getStatWeight(entry.val1, entry.val2);
              if (subgroup == null) {
                subgroup = "tertiary";
              }
              break;
            case 1:
              if (indexOf.call(ShadowcraftGear.WF_BONUS_IDS, bonusId) >= 0) {
                ilvl_bonus = entry['val1'];
                entry['val1'] = "+" + ilvl_bonus + " Item Levels ";
                if (ilvl_bonus < 15) {
                  entry['val1'] += "(Warforged)";
                } else {
                  entry['val1'] += "(Titanforged)";
                }
                new_ilvl = gear.item_level - current_tf_value + ilvl_bonus;
                entry['val2'] = "Item Level " + new_ilvl;
                group['entries'].push(entry);
                temp_stats = [];
                sumItem(temp_stats, item, 'stats', ilvl_bonus - current_tf_value);
                temp_ep = getEPForStatBlock(temp_stats);
                group.ep = temp_ep - base_item_ep;
                subgroup = "titanforged";
              }
          }
        }
        if (subgroup != null) {
          group.ep = group.ep.toFixed(2);
          groups[subgroup].push(group);
          groups[subgroup + "_active"] = true;
        }
      }
      if (groups['titanforged'].length !== 0) {
        group = {};
        subgroup = 'titanforged';
        group['bonusId'] = 0;
        group['active'] = current_tf_id === 0;
        if (current_tf_value === 0) {
          group['ep'] = "0.00";
        } else {
          temp_stats = [];
          sumItem(temp_stats, item, 'stats', -current_tf_value);
          temp_ep = getEPForStatBlock(temp_stats);
          group['ep'] = (temp_ep - base_item_ep).toFixed(2);
        }
        group['entries'] = [];
        entry = {
          'type': 1,
          'val1': "None ",
          'val2': "Item Level " + (item.ilvl + (gear.upgrade_level * getUpgradeLevelSteps(item)))
        };
        group['entries'].push(entry);
        groups['titanforged'].push(group);
      }
      for (key in groups) {
        subgroup = groups[key];
        if (!_.isArray(subgroup)) {
          continue;
        }
        subgroup.sort(function(a, b) {
          return b.ep - a.ep;
        });
      }
      $.data(document.body, "bonuses-item", item);
      $("#bonuses").html(Templates.bonuses({
        groups: groups
      }));
      Shadowcraft.setupLabels("#bonuses");
      showPopup($("#bonuses.popup"));
      return false;
    };

    clickWowhead = function(e) {
      e.stopPropagation();
      return true;
    };

    clickItemUpgrade = function(e) {
      var buf, data, gear, item, max, slot;
      e.stopPropagation();
      buf = clickSlot(this, "item_id");
      slot = buf[1];
      data = Shadowcraft.Data;
      gear = data.gear[slot];
      item = getItem(gear.id, gear.context);
      max = getMaxUpgradeLevel(item);
      if (gear.upgrade_level === max) {
        gear.item_level -= getUpgradeLevelSteps(item) * max;
        gear.upgrade_level = 0;
      } else {
        gear.item_level += getUpgradeLevelSteps(item);
        gear.upgrade_level += 1;
      }
      Shadowcraft.update();
      Shadowcraft.Gear.updateDisplay();
      return true;
    };

    clickItemLock = function(e) {
      var buf, data, gear, item, slot;
      e.stopPropagation();
      buf = clickSlot(this, "item_id");
      slot = buf[1];
      data = Shadowcraft.Data;
      gear = data.gear[slot];
      gear.locked || (gear.locked = false);
      data.gear[slot].locked = !gear.locked;
      item = getItem(gear.id, gear.context);
      if (item) {
        if (data.gear[slot].locked) {
          Shadowcraft.Console.log("Locking " + item.name + " for Optimize Gems");
        } else {
          Shadowcraft.Console.log("Unlocking " + item.name + " for Optimize Gems");
        }
      }
      Shadowcraft.Gear.updateDisplay();
      return true;
    };

    ShadowcraftGear.prototype.boot = function() {
      var app, reset;
      app = this;
      $slots = $(".slots");
      $popup = $("#gearpopup");
      $popupbody = $("#gearpopup .body");
      Shadowcraft.Backend.bind("recompute", updateStatWeights);
      Shadowcraft.Backend.bind("recompute", function() {
        return Shadowcraft.Gear;
      });
      Shadowcraft.Backend.bind("recompute", updateDpsBreakdown);
      Shadowcraft.Backend.bind("recompute", updateEngineInfoWindow);
      Shadowcraft.Talents.bind("changed", function() {
        app.updateStatsWindow();
        return app.updateSummaryWindow();
      });
      Shadowcraft.bind("loadData", function() {
        return app.updateDisplay();
      });
      $("#optimizeGems").click(function() {
        if (window._gaq) {
          window._gaq.push(['_trackEvent', "Character", "Optimize Gems"]);
        }
        return Shadowcraft.Gear.optimizeGems();
      });
      $("#optimizeEnchants").click(function() {
        if (window._gaq) {
          window._gaq.push(['_trackEvent', "Character", "Optimize Enchants"]);
        }
        return Shadowcraft.Gear.optimizeEnchants();
      });
      $("#lockAll").click(function() {
        if (window._gaq) {
          window._gaq.push(['_trackEvent', "Character", "Lock All"]);
        }
        return Shadowcraft.Gear.lockAll();
      });
      $("#unlockAll").click(function() {
        if (window._gaq) {
          window._gaq.push(['_trackEvent', "Character", "Unlock All"]);
        }
        return Shadowcraft.Gear.unlockAll();
      });
      $("#bonuses").click($.delegate({
        ".label_check input": function() {
          var $this;
          $this = $(this);
          $this.attr("checked", $this.attr("checked") == null);
          return Shadowcraft.setupLabels("#bonuses");
        },
        ".applyBonuses": this.applyBonuses,
        ".clearBonuses": clearBonuses
      }));
      $slots.click($.delegate({
        ".upgrade": clickItemUpgrade,
        ".lock": clickItemLock,
        ".wowhead": clickWowhead,
        ".name": clickSlotName,
        ".enchant": clickSlotEnchant,
        ".gem": clickSlotGem,
        ".bonuses": clickSlotBonuses
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
      $popupbody.click($.delegate({
        ".slot": function(e) {
          var $this, bonuses, data, enchant_id, gem_id, identifier, idparts, item, item_id, ref, slot, slotGear, update, upgd_level, val;
          Shadowcraft.Console.purgeOld();
          data = Shadowcraft.Data;
          slot = $.data(document.body, "selecting-slot");
          update = $.data(document.body, "selecting-prop");
          $this = $(this);
          slotGear = data.gear[slot];
          if (update === "item_id" || update === "enchant") {
            val = parseInt($this.attr("id"), 10);
            identifier = $this.data("identifier");
            slotGear[update] = val !== 0 ? val : null;
            if (update === "item_id") {
              bonuses = "" + $this.data("bonus");
              idparts = identifier.split(":");
              slotGear.id = parseInt(idparts[0]);
              slotGear.item_level = parseInt(idparts[1]);
              slotGear.name = $this.data("name");
              slotGear.context = $this.data("context");
              slotGear.tag = $this.data("tag");
              upgd_level = parseInt($this.data("upgrade"));
              slotGear.upgrade_level = !isNaN(upgd_level) ? upgd_level : 0;
              slotGear.bonuses = bonuses.split(":");
              if ((ref = slotGear.id, indexOf.call(ShadowcraftGear.ARTIFACTS, ref) >= 0)) {
                Shadowcraft.Artifact.updateArtifactItem(slotGear.id, slotGear.item_level, slotGear.item_level);
              }
            } else {
              enchant_id = !isNaN(val) ? val : null;
              item = getItem(slotGear.id, slotGear.context);
              if (enchant_id != null) {
                Shadowcraft.Console.log("Changing " + item.name + " enchant to " + Shadowcraft.ServerData.ENCHANT_LOOKUP[enchant_id].name);
              } else {
                Shadowcraft.Console.log("Removing Enchant from " + item.name);
              }
            }
          } else if (update === "gem") {
            item_id = parseInt($this.attr("id"), 10);
            item_id = !isNaN(item_id) ? item_id : null;
            gem_id = $.data(document.body, "gem-slot");
            item = getItem(slotGear.id, slotGear.context);
            if (item_id != null) {
              Shadowcraft.Console.log("Regemming " + item.name + " socket " + (gem_id + 1) + " to " + Shadowcraft.ServerData.GEM_LOOKUP[item_id].name);
            } else {
              Shadowcraft.Console.log("Removing Gem from " + item.name + " socket " + (gem_id + 1));
            }
            slotGear.gems[gem_id] = item_id;
          }
          Shadowcraft.update();
          return app.updateDisplay();
        }
      }));
      $("input.search").keydown(function(e) {
        var $this, body, height, i, len, len1, m, n, next, ot, slot, slots;
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
            for (i = m = 0, len = slots.length; m < len; i = ++m) {
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
            for (i = n = 0, len1 = slots.length; n < len1; i = ++n) {
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
        all = popup.find(".slot:not(.active)");
        show = all.filter(":regex(data-search, " + escape(search) + ")");
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
      $("#filter, #bonuses").click(function(e) {
        e.cancelBubble = true;
        return e.stopPropagation();
      });
      Shadowcraft.Options.bind("update", function(opt, val) {
        if (opt === 'rotation.use_hemorrhage') {
          app.updateDisplay();
        }
        if (opt === 'rotation.blade_flurry' || opt === 'general.num_boss_adds' || opt === 'general.lethal_poison') {
          return app.updateSummaryWindow();
        }
      });
      this.updateDisplay();
      checkForWarnings('options');
      this.initialized = true;
      return this;
    };

    function ShadowcraftGear(app1) {
      this.app = app1;
    }

    return ShadowcraftGear;

  })();

  ShadowcraftDpsGraph = (function() {
    var MAX_POINTS;

    MAX_POINTS = 20;

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
          snapshot = $.parseJSON(app.snapshotHistory[item.dataIndex]);
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
      var delta, deltatext;
      delta = data.total_dps - (this.lastDPS || 0);
      deltatext = "";
      if (this.lastDPS) {
        deltatext = delta >= 0 ? " <em class='p'>(+" + (delta.toFixed(1)) + ")</em>" : " <em class='n'>(" + (delta.toFixed(1)) + ")</em>";
      }
      $("#dps .inner").html(data.total_dps.toFixed(1) + " DPS" + deltatext);
      this.dpsHistory.push([this.dpsIndex, Math.round(data.total_dps * 10) / 10]);
      this.dpsIndex++;
      this.snapshotHistory.push($.toJSON(Shadowcraft.Data));
      if (this.dpsHistory.length > MAX_POINTS) {
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
      return this.lastDPS = data.total_dps;
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
      var date, now;
      date = new Date();
      now = Math.round(date / 1000);
      msg = "[" + date.getHours() + ":" + ("0" + date.getMinutes()).slice(-2) + ":" + ("0" + date.getSeconds()).slice(-2) + "] " + msg;
      return this.$log.append("<div class='" + klass + "' data-created='" + now + "'>" + msg + "</div>").scrollTop(this.$log.get(0).scrollHeight);
    };

    ShadowcraftConsole.prototype.warn = function(item, msg, submsg, klass, section) {
      this.consoleMessage(item, msg, submsg, "warning", klass, section);
      return this.purgeOld();
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
      if (!this.consoleInner.html().trim()) {
        return this.console.hide();
      }
    };

    ShadowcraftConsole.prototype.remove = function(selector) {
      this.consoleInner.find("div" + selector).remove();
      if (!this.consoleInner.html().trim()) {
        return this.console.hide();
      }
    };

    ShadowcraftConsole.prototype.clear = function() {
      return this.consoleInner.empty();
    };

    ShadowcraftConsole.prototype.purgeOld = function(age) {
      var now;
      if (age == null) {
        age = 60;
      }
      now = Math.round(+new Date() / 1000);
      return $("#log .inner div").each(function() {
        var $this, created;
        $this = $(this);
        created = $this.data("created");
        if (created + age < now) {
          return $this.fadeOut(500, function() {
            return $this.remove();
          });
        }
      });
    };

    return ShadowcraftConsole;

  })();

  window.Shadowcraft = new ShadowcraftApp;

}).call(this);
