/**
 * Prevents click-based selection of text in all matched elements.
 */

window["RogueApp"] = {};
RogueApp.commonInit = function($) {
  $( "button, input:submit, .button").button();
};

RogueApp.initApp = function($, uuid, data, serverData, config) {
  var $slots = $(".slots");
  var $popup = $(".alternatives");
  var $altslots = $(".alternatives .body");

  // Config
var RATING_CONVERSIONS = {
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

var SLOT_INVTYPES = {
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

var REFORGE_STATS = [
  // {key: "spirit", val: "Spirit"},
  {key: "expertise_rating", val: "Expertise"},
  {key: "hit_rating", val: "Hit"},
  {key: "haste_rating", val: "Haste"},
  {key: "crit_rating", val: "Crit"},
  {key: "mastery_rating", val: "Mastery"}
];
var reforgableStats = ["crit_rating", "hit_rating", "haste_rating", "expertise_rating", "mastery_rating"];
var slotOrder = ["0", "1", "2", "14", "4", "8", "9", "5", "6", "7", "10", "11", "12", "13", "15", "16", "17"];
var slotDisplayOrder = [["0", "1", "2", "14", "4", "8", "15", "16"], ["9", "5", "6", "7", "10", "11", "12", "13", "17"]];
var CHAOTIC_METAGEMS = [52291, 34220, 41285, 68778, 68780, 41398, 32409, 68779];

var REFORGE_FACTOR = 0.4;
var MAX_TALENT_POINTS = 41;
var DEFAULT_BOSS_DODGE = 6.5;
var MAX_PROFESSIONAL_GEMS = 3;
var JC_ONLY_GEMS = ["Dragon's Eye", "Chimera's Eye"];

var DEFAULT_SPECS = {
  "Stock Assassination": "033323011302211032100200000000000000002030030000000000000",
  "Stock Combat": "023200000000000000023322303100300123210030000000000000000",
  "Stock Subtlety": "023003000000000000000200000000000000000332031321310012321"
}

/**************************************************************************************************************/

RogueApp.ServerData = serverData;
RogueApp.Data = data;

if(!data.options) { data.options = {}; }
var statSum;

var ITEM_LOOKUP = serverData.ITEM_LOOKUP, WEIGHTS = serverData.WEIGHTS, ITEMS = serverData.ITEMS, SLOT_CHOICES = serverData.SLOT_CHOICES,
  TALENTS = serverData.TALENTS, TALENT_LOOKUP = serverData.TALENT_LOOKUP, GEMS = serverData.GEMS, ENCHANT_LOOKUP = serverData.ENCHANT_LOOKUP,
  ENCHANT_SLOTS = serverData.ENCHANT_SLOTS, GEM_LIST = serverData.GEM_LIST, GLYPHS = serverData.GLYPHS, GLYPH_LOOKUP = serverData.GLYPH_LOOKUP,
  GLYPHNAME_LOOKUP = serverData.GLYPHNAME_LOOKUP;
data.weights = WEIGHTS;
  var json_encode = $.toJSON || Object.toJSON || (window.JSON && (JSON.encode || JSON.stringify));
var NOOP = function() { return false; };

$.fn.disableTextSelection = function() {
  return $(this).each(function()
  {
    if (typeof this.onselectstart != "undefined") { // IE
      this.onselectstart = NOOP;
    } else if (typeof this.style.MozUserSelect != "undefined") { // Firefox
      this.style.MozUserSelect = "none";
    } else { // All others
      this.onmousedown = NOOP;
      this.style.cursor = "default";
    }
  });
};

$.expr[':'].regex = function(elem, index, match) {
  var matchParams = match[3].split(','),
    validLabels = /^(data|css):/,
    attr = {
      method: matchParams[0].match(validLabels) ?  matchParams[0].split(':')[0] : 'attr',
      property: matchParams.shift().replace(validLabels,'')
    },
    regexFlags = 'ig',
    regex = new RegExp(matchParams.join('').replace(/^\s+|\s+$/g,''), regexFlags);
  return regex.test(jQuery(elem)[attr.method](attr.property));
};

$.delegate = function(rules) {
  return function(e) {
    var target = $(e.target);
    for (var selector in rules) {
      var bubbledTarget = target.closest(selector);
      if (bubbledTarget.length > 0) {
        return rules[selector].apply(bubbledTarget, $.makeArray(arguments));
      }
    }
  }
};

function _sortPairsByVal(a, b) { return a[1] > b[1] ? 1 : -1 }
function sortObjectByValue(obj) {
  var pairs = [];
  for(var k in obj) {
    if(obj.hasOwnProperty(k)) {
      pairs.push([k, obj[k]]);
    }
  }
  return _.sortBy(pairs, _sortPairsByVal);
}

function deepCopy(obj) {
  if (Object.prototype.toString.call(obj) === '[object Array]') {
    var out = [], i = 0, len = obj.length;
    for (; i < len; i++) {
      out[i] = arguments.callee(obj[i]);
    }
    return out;
  }
  if (typeof obj === 'object') {
    var out = {}, i;
    for (i in obj) {
      out[i] = arguments.callee(obj[i]);
    }
    return out;
  }
  return obj;
}

String.prototype.capitalize = function(){
 return this.replace( /(^|\s)([a-z])/g , function(m,p1,p2){ return p1+p2.toUpperCase(); } );
};

$.fn.sortElements = (function() {
  var sort = [].sort;
  return function(comparator, getSortable) {
    getSortable = getSortable || function() {
      return this;
    };

    var placements = this.map(function() {
      var sortElement = getSortable.call(this),
        parentNode = sortElement.parentNode,

        // Since the element itself will change position, we have
        // to have some way of storing its original position in
        // the DOM. The easiest way is to have a 'flag' node:
        nextSibling = parentNode.insertBefore(
          document.createTextNode(''),
          sortElement.nextSibling
          );

      return function() {
        if (parentNode === this) {
          throw new Error(
            "You can't sort elements if any one is a descendant of another."
            );
        }

        // Insert before flag:
        parentNode.insertBefore(this, nextSibling);
        // Remove flag:
        parentNode.removeChild(nextSibling);
      };
    });

    return sort.call(this, comparator).each(function(i) {
      placements[i].call(getSortable.call(this));
    });
  };
})();
  var template = Handlebars.compile($("#template-itemSlot").html());
var statsTemplate = Handlebars.compile($("#template-stats").html());
var reforgeTemplate = Handlebars.compile($("#template-reforge").html());
var checkboxTemplate = Handlebars.compile($("#template-checkbox").html());
var selectTemplate = Handlebars.compile($("#template-select").html());
var inputTemplate = Handlebars.compile($("#template-input").html());
var talentTreeTemplate = Handlebars.compile($("#template-tree").html());
var tooltipTemplate = Handlebars.compile($("#template-tooltip").html());
var talentSetTemplate = Handlebars.compile($("#template-talent_set").html());
var logTemplate = Handlebars.compile($("#template-log").html());
var glyphSlotTemplate = Handlebars.compile($("#template-glyph_slot").html());
var talentContributionTemplate = Handlebars.compile($("#template-talent_contribution").html());
  var ENGINE_ERRORS = [];
var recomputeTimeout, cancelRecompute = false;
var lastDPS;
var dpsHistory = [];
var snapshotHistory = [];
var dpsPlot;
var loadingSnapshot = false;
var dpsIndex = 0;

function buildPayload() {
  sumStats();
  var mh = ITEM_LOOKUP[data.gear[15].item_id];
  var oh = ITEM_LOOKUP[data.gear[16].item_id];
  var th = ITEM_LOOKUP[data.gear[17].item_id];
  var glyph_list = [];
  for(var i = 0; i < data.glyphs.length; i++) {
    var glyphSet = data.glyphs[i];
    for(var j = 0; j < glyphSet.length; j++) {
      glyph_list.push(GLYPH_LOOKUP[glyphSet[j]].ename);
    }
  }
  var payload = {
    r: data.race,
    l: 85, //data.options.general.level,
    t: [
      data.activeTalents.substr(0, TALENTS[0].talent.length),
      data.activeTalents.substr(TALENTS[0].talent.length, TALENTS[1].talent.length),
      data.activeTalents.substr(TALENTS[0].talent.length + TALENTS[1].talent.length, TALENTS[2].talent.length)
    ],
    mh: [
      mh.speed,
      mh.dps * mh.speed,
      data.gear[15].enchant,
      mh.subclass
    ],
    oh: [
      oh.speed,
      oh.dps * oh.speed,
      data.gear[16].enchant,
      oh.subclass
    ],
    th: [
      th.speed,
      th.dps * th.speed,
      data.gear[17].enchant,
      th.subclass
    ],
    sta: [
      statSum.strength || 0,
      statSum.agility || 0,
      statSum.attack_power || 0,
      statSum.crit_rating || 0,
      statSum.hit_rating || 0,
      statSum.expertise_rating || 0,
      statSum.haste_rating || 0,
      statSum.mastery_rating || 0
    ],
    gly: glyph_list,
    pro: data.options.professions
  };

  var gear_ids = [];
  for(var k in data.gear) {
    if(data.gear.hasOwnProperty(k)) {
      var g = data.gear[k];
      gear_ids.push(g.item_id);
      if(k == 0 && g.gem0 && GEMS[g.gem0] && GEMS[g.gem0].Meta) {
        if(CHAOTIC_METAGEMS.indexOf(g.gem0)) {
          payload.mg = "chaotic";
        }
      }
    }
  }
  payload.g = gear_ids;

  return payload;
}


var ws = $.websocket("ws://cheald.homedns.org:8880/engine", {
  error: function(e) { console.log(e) },
  events: {
    response: function(e) { handleRecompute(e.data); }
  }
});

function handleRecompute(data) {
  $console.find(".error").remove();
  // console.log(data);
  console.log(data.calc_time);
  if(data.error) {
    warn({}, data.error, null, "error", "error");
    return;
  }
  var snapshot;
  if(data.total_dps != lastDPS && !loadingSnapshot) {
    snapshot = takeSnapshot();
  }

  RogueApp.lastCalculation = data;
  updateStatWeights(data);
  updateTalentContribution();
  updateGlyphWeights();
  RogueApp.updateDisplayedGear(true);

  if(data.total_dps != lastDPS || loadingSnapshot) {
    var delta = data.total_dps - (lastDPS || 0);
    var deltatext = "";
    if(lastDPS)
      deltatext = delta >= 0 ? " <em class='p'>(+" + delta.toFixed(1) + ")</em>" : " <em class='n'>(" + delta.toFixed(1) + ")</em>";
    $("#dps .inner").html(data.total_dps.toFixed(1) + " DPS" + deltatext);

    if(snapshot) {
      dpsHistory.push( [dpsIndex, Math.floor(data.total_dps * 10) / 10]) ;
      dpsIndex++;
      snapshotHistory.push(snapshot);
      if(dpsHistory.length > 30) {
        dpsHistory.shift();
        snapshotHistory.shift();
      }

      dpsPlot = $.plot($("#dpsgraph"), [dpsHistory], {
        lines: { show: true },
        crosshair: { mode: "y" },
        points: { show: true },
        grid: { hoverable: true, clickable: true, autoHighlight: true },
      });
    }
    lastDPS = data.total_dps;
  }
  loadingSnapshot = false;
}

function recompute() {
  if(window.WebSocket) {
    recompute_via_websocket();
  } else {
    recompute_via_post();
  }
}

function recompute_via_websocket() {
  cancelRecompute = false;
  var payload = buildPayload();
  if(cancelRecompute) { return; }
  ws.send("m", payload);
}

function recompute_via_post() {
  cancelRecompute = false;
  var payload = buildPayload();
  if(cancelRecompute) { return; }
  if(payload) {
    $.post("http://cheald.homedns.org:8880/", {
      data: $.toJSON(payload)
    }, function(data) {
      handleRecompute(data);
    }, 'json');
  }
}
  
$("#dpsgraph").bind("plotclick", function (event, pos, item) {
  if (item) {
    dpsPlot.unhighlight();
    dpsPlot.highlight(item.series, item.datapoint);
    loadSnapshot(snapshotHistory[item.dataIndex]);
  }
}).mousedown(function(e) {
  switch(e.button) {
    case 2:
    return false;
  }
});

function saveData() {
  $.jStorage.set(uuid, data);
  if(recomputeTimeout) {
    recomputeTimeout = clearTimeout(recomputeTimeout);
  }
  cancelRecompute = true;
  recomputeTimeout = setTimeout(recompute, 50);
}

RogueApp.ResetLocalStorage = function() {
  if(confirm("This will wipe out any changes you've made. Proceed?")) {
    $.jStorage.set(uuid, null);
    window.location.reload();
  }
};

function takeSnapshot() {
  return deepCopy(RogueApp.Data);
}

function loadSnapshot(snapshot) {
  // if(RogueApp.Data == snapshot) { return; }
  RogueApp.Data = deepCopy(snapshot);
  data = RogueApp.Data;
  WEIGHTS = data.weights;
  loadingSnapshot = true;
  updateView();
}
RogueApp.saveData = saveData;
  function _T(str) {
  var idx = _.indexOf(serverData.TALENT_INDEX, str);
  if(!data.activeTalents) { return 0; }
  var t = data.activeTalents[idx];
  if(!t) return 0;
  return parseInt(t, 10);
}

function _R(str) {
  return RATING_CONVERSIONS[data.options.general.level][str];
}


function sumItem(s, i, key) {
  if(!key) { key = "stats"; }
  for(var stat in i[key]) {
    if(i[key].hasOwnProperty(stat)) {
      if(!s[stat]) { s[stat] = 0; }
      s[stat] += i[key][stat];
    }
  }
}

function sumRecommendation(s, rec) {
  if(!s[rec.source.key]) { s[rec.source.key] = 0; }
  s[rec.source.key] += rec.qty;
  if(!s[rec.dest.key]) { s[rec.dest.key] = 0; }
  s[rec.dest.key] += rec.qty;
}

// This is actually EP, but the function name remains for my sanity.
function ep(item, key, slot) {
  var stats = {};
  if(item.source && item.dest) {
    sumRecommendation(stats, item);
  } else {
    sumItem(stats, item, key);
  }
  var total = 0;
  for(var stat in stats) {
    if(stats.hasOwnProperty(stat)) {
      var weight = data.weights[stat] ? data.weights[stat] : 0;
      total += stats[stat] * weight;
    }
  }
  delete stats;
  var c = RogueApp.lastCalculation;
  if(c) {
    if(item.dps) {
      if(slot == 15) {
        total += (item.dps * c.mh_ep.mh_dps) + (item.speed * c.mh_speed_ep["mh_" + item.speed]);
        total += racialExpertiseBonus(item) * data.weights.expertise_rating;
      } else if(slot == 16) {
        total += (item.dps * c.oh_ep.oh_dps) + (item.speed * c.oh_speed_ep["oh_" + item.speed]);
        total += racialExpertiseBonus(item) * data.weights.expertise_rating;
      }
    } else if(CHAOTIC_METAGEMS.indexOf(item.id) >= 0) {
      total += c.meta.chaotic_metagem;
    }
  }

  if(c && c.trinket_ranking[item.id]) {
    total += c.trinket_ranking[item.id];
  }
  return total;
}

function sumStats() {
  var stats = {};
  for(var si = 0; si < slotOrder.length; si++) {
    var i = slotOrder[si];
    var gear = data.gear[i];
    if(!gear || !gear.item_id) { continue; }
    var item = ITEM_LOOKUP[gear.item_id];
    if(item) {
      sumItem(stats, item);
      var matchesAllSockets = item.sockets && item.sockets.length > 0;
      for(var socketIndex in item.sockets) {
        if(item.sockets.hasOwnProperty(socketIndex)) {
          var gid = gear["gem" + socketIndex];
          var gem;
          if(gid && gid > 0) {
            gem = GEMS[gid];
            if(gem) { sumItem(stats, gem); }
          }
          if(!gem || !gem[item.sockets[socketIndex]]) { matchesAllSockets = false; }
        }
      }

      if(matchesAllSockets) {
        sumItem(stats, item, "socketbonus");
      }

      if(gear.reforge && gear.reforge) {
        sumItem(stats, gear.reforge);
      }

      var enchant_id = gear.enchant;
      if(enchant_id && enchant_id > 0) {
        var enchant = ENCHANT_LOOKUP[enchant_id];
        if(enchant) { sumItem(stats, enchant); }
      }

    }
  }
  statSum = stats;
}

function racialExpertiseBonus(item) {
  // return 0; // HAX
  var mh_type = item.subclass;
  if(data.race == "Human" && (mh_type == 7 || mh_type == 4)) {
    return _R("expertise_rating") * 3;
  } else if(data.race == "Gnome" && (mh_type == 7 || mh_type == 15)) {
    return _R("expertise_rating") * 3;
  } else if(data.race == "Dwarf" && (mh_type == 4)) {
    return _R("expertise_rating") * 3;
  } else if(data.race == "Orc" && (mh_type == 0 || mh_type == 13)) {
    return _R("expertise_rating") * 3;
  } else {
    return 0;
  }
}

function racialHitBonus(key) {
  return data.race == "Draenei" ? _R(key) : 0;
}

// TODO: Adjust for racial bonuses.
// Stat to get the real weight for, the amount of the stat, and a hash of {stat: amount} to ignore (like if swapping out a reforge or whatnot; nil the existing reforge for calcs)
function getStatWeight(stat, num, ignore, ignoreAll) {
  if(!statSum) { sumStats(); }
  var exist = ignoreAll ? 0 : ((statSum[stat] || 0) - (ignore ? (ignore[stat] || 0) : 0));
  var neg = num < 0 ? -1 : 1;
  num = Math.abs(num);
  switch(stat) {
  case "expertise_rating":
    var boss_dodge = DEFAULT_BOSS_DODGE;
    var expertiseCap = (_R("expertise_rating") * boss_dodge * 4);
    if(data.gear[15] && data.gear[15].item_id) {
      expertiseCap -= racialExpertiseBonus(ITEM_LOOKUP[data.gear[15].item_id])
    }

    var usable = expertiseCap - exist; usable = usable < 0 ? 0 : usable; usable = usable > num ? num : usable;
    return data.weights.expertise_rating * usable * neg;
  case "hit_rating":
    var yellowHitCap = _R("hit_rating") * (8 - 2 * _T("precision")) - racialHitBonus("hit_rating");
    var spellHitCap = _R("spell_hit")  * (17 - 2 * _T("precision")) - racialHitBonus("spell_hit");
    var whiteHitCap = _R("hit_rating") * (27 - 2 * _T("precision")) - racialHitBonus("hit_rating");

    var total = 0;
    var remaining = num;
    var delta;
    if(remaining > 0 && exist < yellowHitCap) {
      delta = (yellowHitCap - exist) > remaining ? remaining: (yellowHitCap - exist);
      total += delta * data.weights.yellow_hit;
      remaining -= delta;
      exist += delta;
    }

    if(remaining > 0 && exist < spellHitCap) {
      delta = (spellHitCap - exist) > remaining ? remaining : (spellHitCap - exist);
      total += delta * data.weights.spell_hit;
      remaining -= delta;
      exist += delta;
    }

    if(remaining > 0 && exist < whiteHitCap) {
      delta = (whiteHitCap - exist) > remaining ? remaining: (whiteHitCap - exist);
      total += delta * data.weights.hit_rating;
      remaining -= delta;
      exist += delta;
    }

    return total * neg;
  }
  return (data.weights[stat] || 0) * num * neg;
}

var presortedLists = {};

function __epSort(a, b) { return b.__ep - a.__ep; }
function epSort(list, skipSort) {
  for(var i = 0; i < list.length; i++) {
    if(list[i]) {
      list[i].__ep = ep(list[i]);
    }
  }
  if(!skipSort) {
    list.sort(__epSort);
  }
}

// Assumes gem_list is already sorted preferred order.  Also, normalizes
// JC-only gem EP to their non-JC-only values to prevent the algorithm from
// picking up those gems over the socket bonus.
function getGemmingRecommendation(gem_list, item, returnFull) {
  if(!item.sockets || item.sockets.length === 0) {
    if(returnFull) {
      return {ep: 0, gems: []};
    } else {
      return 0;
    }
  }

  var straightGemEP = 0, matchedGemEP = ep(item, "socketbonus"), s, i, gemType, gem, sGems, mGems, gems;
  if(returnFull) {
    sGems = []; mGems = [];
  }

  var jc_gem_count = getProfessionalGemCount();

  for(s = 0; s < item.sockets.length; s++) {
    gemType = item.sockets[s];
    for(i = 0; i < gem_list.length; i++) {
      gem = gem_list[i];
      if((isProfessionalGem(gem) && !data.options.professions[gem.requires.profession])
         || jc_gem_count >= MAX_PROFESSIONAL_GEMS) { continue; }
      if(gemType == "Meta" && gem.slot != "Meta") { continue; }
      else if(gemType != "Meta" && gem.slot == "Meta") { continue; }
      else if(gemType == "Cogwheel" && gem.slot != "Cogwheel") { continue; }
      else if(gemType != "Cogwheel" && gem.slot == "Cogwheel") { continue; }
      straightGemEP += getRegularGemEpValue(gem);
      if(returnFull) { sGems[sGems.length] = gem.id; }
      break;
    }
  }

  for(s = 0; s < item.sockets.length; s++) {
    gemType = item.sockets[s];
    for(i = 0; i < gem_list.length; i++) {
      gem = gem_list[i];
      if((isProfessionalGem(gem) && !data.options.professions[gem.requires.profession])
         || jc_gem_count >= MAX_PROFESSIONAL_GEMS) { continue; }
      if(gemType == "Meta" && gem.slot != "Meta") { continue; }
      else if(gemType != "Meta" && gem.slot == "Meta") { continue; }
      else if(gemType == "Cogwheel" && gem.slot != "Cogwheel") { continue; }
      else if(gemType != "Cogwheel" && gem.slot == "Cogwheel") { continue; }
      if(gem[gemType]) {
        matchedGemEP += getRegularGemEpValue(gem);
        if(returnFull) { mGems[mGems.length] = gem.id; }
        break;
      }
    }
  }

  var epValue, bonus = false;
  if(matchedGemEP > straightGemEP) {
    epValue = matchedGemEP;
    gems = mGems;
    bonus = true;
  } else {
    epValue = straightGemEP;
    gems = sGems;
  }
  if(returnFull) {
    return {ep: epValue, takeBonus: bonus, gems: gems};
  } else {
    return epValue;
  }
}

// Returns the EP value of a gem.  If it happens to require JC, it'll return
// the regular EP value for the same quality gem, if found.
function getRegularGemEpValue(gem) {
  var equiv_ep = gem.__ep || ep(gem);
  if (!isProfessionalGem(gem)) return equiv_ep;
  if (gem.__reg_ep) return gem.__reg_ep;

  $.each(JC_ONLY_GEMS, function(i, name) {
    if (gem.name.indexOf(name) >= 0) {
      var prefix = gem.name.replace(name, "");
      $.each(GEM_LIST, function(j, reg) {
        if (!isProfessionalGem(reg)
            && reg.name.indexOf(prefix) == 0
            && reg.quality == gem.quality)
        {
          equiv_ep = reg.__ep || ep(reg);
          equiv_ep += 1;
          gem.__reg_ep = equiv_ep;
          return false;
        }
      });
      return false;
    }
  });
  return equiv_ep;
}

function addTradeskillBonuses(item) {
  if(!item.sockets) { item.sockets = []; }
  if(!item._sockets) { item._sockets = item.sockets.slice(0); }    // Originals
  var blacksmith = data.options.professions.blacksmithing;
  if(item.equip_location == 9 || item.equip_location == 10) {
    if(blacksmith && item.sockets[item.sockets.length-1] != "Prismatic") { item.sockets[item.sockets.length] = "Prismatic"; }
    else if(!blacksmith && item.sockets[item.sockets.length-1] == "Prismatic") { item.sockets[item.sockets.length].slice(0, item.sockets.length - 2); }
  }
}

  function titleize(str) {
  if(!str) { return ""; }
  var sp = str.split(/[ _]/); var f, r; var word = [];
  for (var i = 0 ; i < sp.length ; i ++ ) { f = sp[i].substring(0,1).toUpperCase(); r = sp[i].substring(1).toLowerCase(); word[i] = f+r; }
  return word.join(' ');
}

var EP_TOTAL;
function updateStatsWindow() {
  sumStats();
  var $stats = $("#stats .inner");
  var a_stats = [];
  var keys = _.keys(statSum).sort();
  var total = 0;
  for(var idx = 0; idx < keys.length; idx++) {
    var stat = keys[idx];
    var weight = getStatWeight(stat, statSum[stat], null, true);
    total += weight;
    a_stats[a_stats.length] = {
      name: titleize(stat),
      val: statSum[stat],
      ep: Math.floor(weight)
    };
  }
  EP_TOTAL = total;
  $stats.get(0).innerHTML = statsTemplate({stats: a_stats});
}

var $log = $("#log .inner");
function log(msg) {
  $log.prepend("<div>" + msg + "</div");
}

function warn(item, msg, submsg, klass, section) {
  consoleMessage(item, msg, submsg, "warning", klass, section);
}

var $console = $("#console .inner");
function consoleMessage(item, msg, submsg, severity, klass, section) {
  var fullMsg = logTemplate({
    name: item.name,
    quality: item.quality,
    message: msg,
    submsg: submsg,
    severity: severity,
    messageClass: klass,
    section: section
  });

  if(klass && false) {
    var exist = $console.find("#" + klass);
    if(exist.length > 0) {
      exist.replaceWith(fullMsg);
      return;
    }
  }
  $("#console").show();
  $console.append(fullMsg);
}

function statsToDesc(obj) {
  if(obj.__statsToDesc) { return obj.__statsToDesc; }
  var buff = [];
  for(var stat in obj.stats) {
    if(obj.stats.hasOwnProperty(stat)) {
      buff[buff.length] = "+" + obj.stats[stat] + " " + titleize(stat);
    }
  }
  obj.__statsToDesc = buff.join("/");
  return obj.__statsToDesc;
}

function tooltip(data, x, y) {
  var tip = $("#tooltip");
  if(!tip || tip.length === 0) {
    tip = $("<div id='tooltip'></div>");
    $(document.body).append(tip);
  }
  tip.html(tooltipTemplate(data));
  x = x || $.data(document, "mouse-x");
  y = y || $.data(document, "mouse-y");
  tip.css({top: y, left: x}).show();
}

var flashHide;
function hideFlash() {
  $(".flash").fadeOut("fast");
}

function flash(message) {
  var $flash = $(".flash");
  if($flash.length === 0) {
    $flash = $("<div class='flash'></div>");
    $flash.hide().click(function() {
      if(flashHide) {
        window.clearTimeout(flashHide);
      }
      hideFlash();
    });
    $(document.body).append($flash);
  }
  $flash.html(message);
  if(!$flash.is(':visible')) {
    $(".flash").fadeIn(300);
  }
  if(flashHide) { window.clearTimeout(flashHide); }
  flashHide = window.setTimeout(hideFlash, 20000);
}
RogueApp.flash = flash;

/******* View update helpers *************/

RogueApp.updateDisplayedGear = function(skipSave) {
  if(!skipSave) { saveData(); }
  ENGINE_ERRORS = [];

  updateStatsWindow();
  for(var ssi = 0; ssi < slotDisplayOrder.length; ssi++) {
    var buffer = "";
    for(var si = 0; si < slotDisplayOrder[ssi].length; si++) {
      var i = slotDisplayOrder[ssi][si];
      var gear = data.gear[i];
      if(!gear) { continue; }
      var item = ITEM_LOOKUP[gear.item_id];
      var gems = [], bonuses = null, enchant = ENCHANT_LOOKUP[gear.enchant], enchantable;
      if(item) {
        addTradeskillBonuses(item);
        enchantable = ENCHANT_SLOTS[item.equip_location] !== undefined;
        if((!data.options.professions.enchanting && item.equip_location == 11) || item.equip_location == "ranged") {
          enchantable = false;
        }
        var allSlotsMatch = item.sockets && item.sockets.length > 0;
        for(var socket = 0; socket < item.sockets.length; socket++) {
          var gem = GEMS[gear["gem" + gems.length]];
          gems[gems.length] = {socket: item.sockets[socket], gem: gem};
          if(!gem || !gem[item.sockets[socket]]) {
            allSlotsMatch = false;
          }
        }
        if(allSlotsMatch) {
          bonuses = [];
          for(var stat in item.socketbonus) {
            if(item.socketbonus.hasOwnProperty(stat)) {
              bonuses[bonuses.length] = {stat: titleize(stat), amount: item.socketbonus[stat]};
            }
          }
        }

        if(enchant && !enchant.desc) {
          enchant.desc = statsToDesc(enchant);
        }
      }
      if(enchant && enchant.desc == "") enchant.desc = enchant.name;
      buffer += template({
        item: item,
        ttid: item ? item.id : null,
        ep: item ? ep(item, null, i).toFixed(1) : 0,
        slot: i + '',
        gems: gems,
        socketbonus: bonuses,
        reforgable: item ? canReforge(item) : false,
        reforge: gear.reforge,
        sockets: item ? item.sockets : null,
        enchantable: enchantable,
        enchant: enchant
      });
    }
    $slots.get(ssi).innerHTML = buffer;
  }
  checkForWarnings('gear');
};

function updateView() {
  initOptions();
  $("select").selectmenu({ style: 'dropdown' });
  updateActiveTalents();
  RogueApp.updateDisplayedGear();
  checkForWarnings();
}

// This is kludgy.
function checkForWarnings(section) {
  $("#console").hide();
  if(section === undefined || section == "glyphs") {
    // Warn glyphs
    $("#console .glyphs").remove();
    if(RogueApp.Data.glyphs[2].length < 3) {
      warn({}, "Glyphs need to be selected", null, 'warn', 'glyphs');
    }
  }

  if(section === undefined || section == "gear") {
    // Warn items
    $("#console .items").remove();
    var bestOptionalReforge;
    for(var i in data.gear) {
      if(data.gear.hasOwnProperty(i)) {
        var gear = data.gear[i];
        if(!gear) { continue; }
        var item = ITEM_LOOKUP[gear.item_id];
        if(!item) { continue; }
        var enchant = ENCHANT_LOOKUP[gear.enchant];
        var enchantable = ENCHANT_SLOTS[item.equip_location] !== undefined;
        if((!data.options.professions.enchanting && item.equip_location == 11) || item.equip_location == "ranged") {
          enchantable = false;
        }

        if(canReforge(item)) {
          var rec = recommendReforge(item.stats, gear.reforge ? gear.reforge.stats : null);
          var delta = rec ? Math.round(rec[rec.source.key + "_to_" + rec.dest.key] * 100) / 100 : 0;
          if(delta > 0) {
            if(!gear.reforge) {
              warn(item, "needs to be reforged", null, null, "items");
            } else {
              if(rec && (gear.reforge.from.stat != rec.source.name || gear.reforge.to.stat != rec.dest.name)) {
                if(!bestOptionalReforge || bestOptionalReforge < delta) {
                  bestOptionalReforge = delta;
                  warn(item,
                    "is not using an optimal reforge",
                    "Using " + gear.reforge.from.stat + " &Rightarrow; " + gear.reforge.to.stat + ", recommend " + rec.source.name + " &Rightarrow; " + rec.dest.name + " (+" + delta + ")",
                    "reforgeWarning",
                    "items"
                  );
                }
              }
            }
          }
        }

        if(!enchant && enchantable) {
          warn(item, "needs an enchantment", null, null, "items");
        }
      }
    }
  }
}

var $weights = $("#weights .inner");
function updateStatWeights(source) {
  WEIGHTS.agility = source.ep.agi;
  WEIGHTS.crit_rating = source.ep.crit;
  WEIGHTS.hit_rating = source.ep.white_hit;
  WEIGHTS.spell_hit = source.ep.spell_hit;
  WEIGHTS.strength = source.ep.str;
  WEIGHTS.mastery_rating = source.ep.mastery;
  WEIGHTS.haste_rating = source.ep.haste;
  WEIGHTS.expertise_rating = source.ep.dodge_exp;
  WEIGHTS.yellow_hit = source.ep.yellow_hit;

  $weights.empty();
  for(var key in data.weights) {
    if(data.weights.hasOwnProperty(key)) {
      var exist = $(".stat#weight_" + key);
      if(exist.length > 0) {
        exist.find("val").text(data.weights[key].toFixed(2));
      } else {
        var e = $weights.append("<div class='stat' id='weight_" + key + "'><span class='key'>" + titleize(key) + "</span><span class='val'>" + data.weights[key].toFixed(2) + "</span></div>");
        exist = $(".stat#weight_" + key);
      }
      $.data(exist.get(0), "weight", data.weights[key]);
    }
  }
  $("#weights .stat").sortElements(function(a, b) {
    return $.data(a, "weight") > $.data(b, "weight") ? -1 : 1
  });
  epSort(GEM_LIST);
}

function showPopup(popup) {
  $(".popup").removeClass("visible");

  var $parent = popup.parents(".ui-tabs-panel");
  var max = $parent.scrollTop() + $parent.outerHeight();
  var top = $.data(document, "mouse-y") - 40;
  if(top + popup.outerHeight() > max - 20) {
    top = max - 20 - popup.outerHeight();
  }
  if(top < 15) top = 15;
  console.log($.data(document, "mouse-x"))
  var left = $.data(document, "mouse-x") + 65;
  if(popup.width() + left > $parent.outerWidth() - 40) {
    left = popup.parents(".ui-tabs-panel").outerWidth() - popup.outerWidth() - 40;
  }
  popup.css({top: top + "px", left: left + "px"});

  popup.addClass("visible");
  ttlib.hide();
  var body = popup.find(".body");
  $(".popup #filter input").focus();
  var ot = popup.find(".active").get(0);
  if(ot) {
    var ht = ot.offsetTop - (popup.height() / 3);
    var speed = ht / 1.3;
    if(speed > 500) { speed = 500; }
    body.animate({scrollTop: ht}, speed, 'swing');
  }
}

function setupLabels() {
  if ($('.label_check input').length) {
    $('.label_check').each(function(){
      $(this).removeClass('c_on');
    });
    $('.label_check input:checked').each(function(){
      $(this).parent('label').addClass('c_on');
    });
  }
  if ($('.label_radio input').length) {
    $('.label_radio').each(function(){
      $(this).removeClass('r_on');
    });
    $('.label_radio input:checked').each(function(){
      $(this).parent('label').addClass('r_on');
    });
  }
};
  function initChecks(selector, namespace, checkData) {
  var s = $(selector);
  _.each(checkData, function(str, key) {
    var ns = data.options[namespace];
    if(!ns) { data.options[namespace] = {}; ns = data.options[namespace]; }
    var checked = ns[key] ? "checked" : "";
    var exist = s.find("#opt-" + key);
    if(exist.length == 0) {
      var options, temp;
      if(typeof(str) == "string") {
        options = {
          checked: checked,
          label: str
        };
        temp = checkboxTemplate;
      } else if(typeof(str) == "object") {
        if(!str.type || str.type == "check") {
          options = { checked: checked };
          temp = checkboxTemplate;
        } else if(str.type == "select") {
          temp = selectTemplate;
          var templateOptions = [];
          for(var k in str.options) {
            if(str.options.hasOwnProperty(k)) {
              var _k, _v;
              if (str.options instanceof Array) {
                _k = str.options[k]; _v = _k;
              } else {
                _k = k; _v = str.options[k];
              }
              templateOptions.push({name: _v, value: _k});
            }
          }
          options = { options: templateOptions }
        } else if(str.type == 'input') {
          temp = inputTemplate;
        }
      }
      if(temp)
        s.append(temp($.extend({key: key, label: str.name, namespace: namespace, desc: str.desc}, options)));
      exist = s.find("#opt-" + key);
    }
  });
}

$("#settings").bind("change", $.delegate({
  ".optionCheck": changeCheck
}));

function changeCheck() {
  var $this = $(this);
  var ns = $this.attr("data-ns") || "root";
  if(!data.options[ns]) { data.options[ns] = {}; }
  if($this.is(":checked"))
    data.options[ns][$this.attr("name")] = true;
  else
    delete data.options[ns][$this.attr("name")];
  saveData();
}

function initOptions() {
  $("select#race").val(data.race);

  initChecks("#settings #general", "general", {
    level: {type: "input", name: "Level", 'default': 85},
    race: {type: "select", options: ["Human", "Dwarf", "Orc", "Blood Elf", "Gnome", "Worgen", "Troll", "Night Elf", "Undead"], name: "Race", 'default': "Human"}
  });

  initChecks("#settings #professions", "professions", {
    blacksmithing: "Blacksmithing",
    enchanting: "Enchanting",
    engineering: "Engineering",
    inscription: "Inscription",
    jewelcrafting: "Jewelcrafting",
    leatherworking: "Leatherworking",
    tailoring: "Tailoring"
  });

  initChecks("#settings #playerBuffs", "playerBuffs", {
    guild_feast: {name: "Food Buff", desc: "Seafood Magnifique Feast/Skewered Eel", 'default': true},
    agi_flask: {name: "Agility Flask", desc: "Flask of the Wind/Flask of Battle", 'default': true},
    short_term_haste_buff: {name: "Heroism/Bloodlust", 'default': true},
    stat_multiplier_buff: {name: "5% All Stats", desc: "Blessing of Kings/Mark of the Wild", 'default': true},
    crit_chance_buff: {name: "5% Crit", desc: "Honor Among Thieves/Leader of the Pack/Rampage/Elemental Oath", 'default': true},
    all_damage_buff: {name: "3% All Damage", desc: "Arcane Tactics/Ferocious Inspiration/Communion", 'default': true},
    melee_haste_buff: {name: "10% Haste", desc: "Hunting Party/Windfury Totem/Icy Talons", 'default': true},
    attack_power_buff: {name: "10% Attack Power", desc: "Abomination's Might/Blessing of Might/Trueshot Aura/Unleashed Rage", 'default': true},
    str_and_agi_buff: {name: "Agility", desc: "Strength of Earth/Battle Shout/Horn of Winter/Roar of Courage", 'default': true}
  });

  initChecks("#settings #targetDebuffs", "targetDebuffs", {
    armor_debuff: {name: "-12% Armor", desc: "Sunder Armor/Faerie Fire/Expose Armor", 'default': true},
    physical_vulnerability_debuff: {name: "+4% Physical Damage", desc: "Savage Combat/Trauma/Brittle Bones", 'default': true},
    spell_damage_debuff: {name: "+8% Spell Damage", desc: "Curse of the Elements/Earth and Moon/Master Poisoner/Ebon Plaguebringer", 'default': true},
    spell_crit_debuff: {name: "+5% Spell Crit", desc: "Critical Mass/Shadow and Flame", 'default': true},
    bleed_damage_debuff: {name: "+30% Bleed Damage", desc: "Blood Frenzy/Mangle/Hemorrhage", 'default': true}
  });

  initChecks("#settings #raidOther", "general", {
    potion_of_the_tolvir: {name: "Use Potion of the Tol'vir", 'default': true}
  });

  initChecks("#settings section.combat .settings", "rotation", {
    ksp_immediately: {type: "select", name: "Killing Spree", options: {'true': "Killing Spree on cooldown", 'false': "Wait for Bandit's Guile before using Killing Spree"}, 'default': 'false'},
    revealing_strike: {type: "select", name: "Revealing Strike", options: {"always": "Use for every finisher", "sometimes": "Only use at 4CP", "never": "Never use"}, 'default': "always"}
  });
}
  var talentsSpent = 0;
function updateTalentAvailability(selector) {
  var talents = selector ? selector.find(".talent") : $("#talentframe .tree .talent");
  talents.each(function() {
    var $this = $(this);
    var pos = $.data(this, "position");
    var tree = $.data(pos.tree, "info");
    var icons = $.data(this, "icons");
    if(tree.points < (pos.row) * 5) {
      $this.css({backgroundImage: icons.grey}).removeClass("active");
    } else {
      $this.css({backgroundImage: icons.normal}).addClass("active");
    }
  });
  saveData();
}

var hoverTalent = function() {
  var points = $.data(this, "points");
  var talent = $.data(this, "talent");
  var rank = talent.rank.length ? talent.rank[points.cur - 1] : talent.rank;
  var nextRank = talent.rank.length ? talent.rank[points.cur] : null;
  var pos = $(this).offset();
  tooltip({
    title: talent.name + " (" + points.cur + "/" + points.max + ")",
    desc: rank ? rank.description: null,
    nextdesc: nextRank ? "Next rank: " + nextRank.description: null

  }, pos.left + 130, pos.top - 20);
};

function resetTalents() {
  $("#talentframe .talent").each(function() {
    var points = $.data(this, "points");
    applyTalentToButton(this, -points.cur, true, true);
  });
  data.activeTalents = getTalents();
  updateTalentAvailability();
}

function setTalents(str) {
  if(!str) { updateTalentAvailability(null); return; }
  var ct = 0;
  $("#talentframe .talent").each(function() {
    var points = $.data(this, "points");
    applyTalentToButton(this, parseInt(str[ct], 10) - points.cur, true, true);
    ct++;
  });
  data.activeTalents = getTalents();
  updateTalentAvailability(null);
}

function getTalents() {
  return _.map($("#talentframe .talent"), function(t) {
    return $.data(t, "points").cur || 0;
  }).join("");
}

function applyTalentToButton(button, dir, force, skipUpdate) {
  var points = $.data(button, "points");
  var position = $.data(button, "position");
  var tree = $.data(position.tree, "info");
  var success = false;
  if(force) {
    success = true;
  } else if(dir == 1 && points.cur < points.max && talentsSpent < MAX_TALENT_POINTS) {
    success = true;
  } else if(dir == -1) {
    for(var tier = 7; tier > position.row; tier--) {
      var prequal = 0;
      for(var prev = 0; prev < tier; prev++) { prequal += tree.rowPoints[prev]; }
      if(tree.rowPoints[tier] > 0 && (tier * 5) >= prequal) { return false; }
    }
    if(points.cur > 0) { success = true; }
  }

  if(success) {
    points.cur += dir;
    tree.points += dir;
    talentsSpent += dir;
    tree.rowPoints[position.row] += dir;
  }

  if(success) {
    data["tree" + position.treeIndex] = tree.points;
    $.data(button, "spentButton").text(tree.points);
    var $points = $.data(button, "pointsButton");
    $points.get(0).className = "points";
    if(points.cur == points.max) { $points.addClass("full"); }
    else if(points.cur > 0) { $points.addClass("partial"); }
    $points.text(points.cur + "/" + points.max);
    if(!skipUpdate) {
      updateTalentAvailability($(button).parent());
      data.activeTalents = getTalents();
    }
  }
  return success;
}

function updateActiveTalents() {
  if(data.activeTalents) {
    setTalents(data.activeTalents);
  } else {
    for(var k in data.talents) {
      if(data.talents.hasOwnProperty(k)) {
        setTalents(data.talents[k]);
        break;
      }
    }
  }
}

function initTalentsPane() {
  if($.data(document.body, "talentsInitialized")) { return; }
  $.data(document.body, "talentsInitialized", true);
  var buffer = "";
  for(var treeIndex in TALENTS) {
    if(TALENTS.hasOwnProperty(treeIndex)) {
      var tree = TALENTS[treeIndex];
      buffer += talentTreeTemplate({
        background: tree.bgImage,
        talents: tree.talent
      });
    }
  }

  $("#talentframe").get(0).innerHTML = buffer;
  $(".tree, .tree .talent, .tree .talent .points").disableTextSelection();

  var talentTrees = $("#talentframe .tree");
  $("#talentframe .talent").each(function() {
    var row = parseInt(this.className.match(/row-(\d)/)[1], 10);
    var col = parseInt(this.className.match(/col-(\d)/)[1], 10);
    var $this = $(this);
    var trees = $this.closest(".tree");
    var myTree = trees.get(0);
    var tree = talentTrees.index(myTree);
    var talent = TALENT_LOOKUP[tree + ":" + row + ":" + col];
    $.data(this, "position", {tree: myTree, treeIndex: tree, row: row, col: col});
    $.data(myTree, "info", {points: 0, rowPoints: [0, 0, 0, 0, 0, 0, 0]});
    $.data(this, "talent", talent);
    $.data(this, "points", {cur: 0, max: talent.maxRank});
    $.data(this, "pointsButton", $this.find(".points"));
    $.data(this, "spentButton", trees.find(".spent"));
    $.data(this, "icons", {grey: $this.css("backgroundImage"), normal: $this.css("backgroundImage").replace(/\/grey\//, "/")});
    // talentTree[tree * 25 + (row * 4) + col] = this;
  }).mousedown(function(e) {
    if(!$(this).hasClass("active")) { return; }

    switch(e.button) {
    case 0:
      if(applyTalentToButton(this, 1)) { saveData(); }
      break;
    case 2:
      if(applyTalentToButton(this, -1)) { saveData(); }
      break;
    }

    $(this).trigger("mouseenter");
  }).bind("contextmenu", function() { return false; })
  .mouseenter(hoverTalent)
  .mouseleave(function() { $("#tooltip").hide();});

  var talentName;
  buffer = "";
  for(talentName in data.talents) {
    if(data.talents.hasOwnProperty(talentName)) {
      buffer += talentSetTemplate({
        talent_string: data.talents[talentName],
        name: talentName
      });
    }
  }

  for(talentName in DEFAULT_SPECS) {
    if(DEFAULT_SPECS.hasOwnProperty(talentName)) {
      buffer += talentSetTemplate({
        talent_string: DEFAULT_SPECS[talentName],
        name: talentName
      });
    }
  }

  $("#talentsets").get(0).innerHTML = buffer;
  updateActiveTalents();
}

function initGlyphs() {
  var buffer = [null, "", "", ""];
  for(var idx in GLYPHS) {
    var g = GLYPHS[idx];
    buffer[g.rank] += glyphSlotTemplate(g)
  }
  $("#prime-glyphs .inner").get(0).innerHTML = buffer[3];
  $("#major-glyphs .inner").get(0).innerHTML = buffer[2];
  // $("#minor-glyphs .inner").get(0).innerHTML = buffer[1];

  for(var i = 0; i < data.glyphs.length; i++) {
    var glyphSet = data.glyphs[i];
    for(var j = 0; j < glyphSet.length; j++) {
      var g = $(".glyph_slot[data-id='" + glyphSet[j] + "']");
      if(g.length > 0)
        toggleGlyph(g, true);
    }
  }
}

function updateGlyphWeights() {
  var data = RogueApp.lastCalculation;
  var max = _.max(data.glyph_ranking);
  $(".glyph_slot:not(.activated)").hide();
  $(".glyph_slot .pct-inner").css({width: 0});
  for(var key in data.glyph_ranking) {
    if(data.glyph_ranking.hasOwnProperty(key)) {
      var g = GLYPHNAME_LOOKUP[key];
      var weight = data.glyph_ranking[key];
      var width = weight / max * 100;
      var slot = $(".glyph_slot[data-id='" + g.spell + "']")
      $.data(slot.get(0), "weight", weight);
      $.data(slot.get(0), "name", g.name);
      slot.show().find(".pct-inner").css({width: width + "%"});
      slot.find(".label").text(weight.toFixed(1) + " DPS");
    }
  }
  $(".glyphset").each(function(k, e) {
    $(e).find(".glyph_slot").sortElements(function(a, b) {
      var aw = $.data(a, "weight"), bw = $.data(b, "weight");
      var an = $.data(a, "name"), bn = $.data(b, "name");
      if(aw === undefined) aw = -1;
      if(bw === undefined) bw = -1;
      if(an === undefined) an = "";
      if(bn === undefined) bn = "";
      if(aw != bw) {
        return aw > bw ? -1 : 1;
      } else {
        return an > bn ? 1 : -1;
      }
    });
  });
}

function toggleGlyph(e, override) {
  var $e = $(e);
  var $set = $e.parents(".glyphset");
  var id = parseInt($e.data("id"), 10);
  var glyph = GLYPH_LOOKUP[id];
  if($e.hasClass("activated")) {
    $e.removeClass("activated");
    data.glyphs[glyph.rank - 1] = _.without(data.glyphs[glyph.rank - 1], id);
    $set.removeClass("full");
  } else {
    if(data.glyphs[glyph.rank - 1].length >= 3 && !override) { return; }
    $e.addClass("activated");
    if(!override)
      data.glyphs[glyph.rank - 1].push(id);
    if(data.glyphs[glyph.rank - 1].length >= 3) {
      $set.addClass("full");
    }
  }
  checkForWarnings('glyphs');
  saveData();
}

function updateTalentContribution() {
  var LC = RogueApp.lastCalculation;
  if(!LC.talent_ranking_main) { return; }
  var sets = {
    "Primary": LC.talent_ranking_main,
    "Secondary": LC.talent_ranking_off
  };
  var rankings = _.extend({}, LC.talent_ranking_main, LC.talent_ranking_off);
  var max = _.max(rankings), exist;
  $("#talentrankings .talent_contribution").hide();
  for (var setKey in sets) {
    var buffer = "";
    var target = $("#talentrankings ." + setKey);
    if(sets.hasOwnProperty(setKey)) {
      // _.max(sets[setKey]);
      for(var k in sets[setKey]) {
        exist = $("#talentrankings #talent-weight-" + k);
        var val = parseInt(sets[setKey][k], 10);
        if(isNaN(val)) {
          name += " (NYI)";
          val = 0;
        }
        var pct = val / max * 100 + 0.01;

        if(exist.length == 0) {
          var name = k.replace(/_/g, " ").capitalize();
          buffer = talentContributionTemplate({
            name: name,
            raw_name: k,
            val: val.toFixed(1),
            width: pct
          });
          target.append(buffer);
        }
        exist = $("#talentrankings #talent-weight-" + k);
        $.data(exist.get(0), "val", val);
        exist.show().find(".pct-inner").css({width: pct + "%"});
      }
    }
  }
  $("#talentrankings .talent_contribution").sortElements(function(a, b) {
    var ad = $.data(a, "val"), bd = $.data(b, "val");
    return ad > bd ? -1 : 1;
  });
}

$("#glyphs").click($.delegate({
  ".glyph_slot": function() { toggleGlyph(this) }
}))

$("#talentsets").click($.delegate({
  ".talent_set": function() { setTalents($(this).attr("data-talents")); }
}));
$("#reset_talents").click(resetTalents);

RogueApp.resetTalents = resetTalents;
RogueApp.setTalents = setTalents;
RogueApp.getTalents = getTalents;


  function needsDagger() {
  return data.tree0 >= 31 || data.tree2 >= 31
}

function isProfessionalGem(gem) {
  return gem && gem.requires && gem.requires.profession;
}

function getProfessionalGemCount() {
  var count = 0;
  $.each(slotOrder, function(i, slot) {
    var gear = data.gear[slot];
    for (var k in gear) {
      if (k.indexOf("gem") == 0 && isProfessionalGem(GEMS[gear[k]])) {
        count++;
      }
    }
  });
  return count;
}
  // Standard setup for the popup
function clickSlot(slot, prop) {
  var $slot = $(slot).closest(".slot");
  $slots.find(".slot").removeClass("active");
  $slot.addClass("active");
  var slotIndex = parseInt($slot.attr("data-slot"), 10);
  $.data(document.body, "selecting-slot", slotIndex);
  $.data(document.body, "selecting-prop", prop);
  return [$slot, slotIndex];
}

// Click a name in a slot, for binding to event delegation
function clickSlotName() {
  var i, buf = clickSlot(this, "item_id"); var $slot = buf[0]; var slot = buf[1];
  var selected_id = + $slot.attr("id");
  var equip_location = SLOT_INVTYPES[slot];

  var loc = SLOT_CHOICES[equip_location];
  var slot = parseInt($(this).parent().data("slot"), 10);
  epSort(GEM_LIST); // Needed for gemming recommendations
  for(i = 0; i < loc.length; i++) {
    loc[i].__gemRec = getGemmingRecommendation(GEM_LIST, loc[i], true);
    loc[i].__gemEP = loc[i].__gemRec.ep;

    var rec = recommendReforge(loc[i].stats);
    if(rec) {
      var reforgedStats = {};
      reforgedStats[rec.source.key] = -rec.qty;
      reforgedStats[rec.dest.key] = rec.qty;
      var deltaEp = ep({stats: reforgedStats});
      if(deltaEp > 0) {
        loc[i].__reforgeEP = deltaEp;
      } else {
        loc[i].__reforgeEP = 0;
      }
    } else {
      loc[i].__reforgeEP = 0;
    }

    loc[i].__ep = ep(loc[i], null, slot) + loc[i].__gemRec.ep + loc[i].__reforgeEP;
  }
  loc.sort(__epSort);
  var max = loc[0].__ep;
  var buffer = "";
  var requireDagger = needsDagger();
  for(i = 0; i < loc.length; i++) {
    if(loc[i].__ep < 1) continue;
    if((slot == 15 || slot == 16) && requireDagger && loc[i].subclass != 15) continue;
    if((slot == 15) && !requireDagger && loc[i].subclass == 15) continue;

    var iEP = loc[i].__ep.toFixed(1);

    buffer += template({
      item: loc[i],
      gear: {},
      gems: [],
      ttid: loc[i].id,
      desc: ep(loc[i]).toFixed(1) + " base / " + loc[i].__reforgeEP.toFixed(1) + " reforge / " + loc[i].__gemEP.toFixed(1) + " gem " + (loc[i].__gemRec.takeBonus ? "(Match gems)" : ""),
      search: loc[i].name,
      percent: iEP / max * 100,
      ep: iEP
    });
  }
  buffer += template({
    item: {name: "[No item]"},
    desc: "Clear this slot",
    percent: 0,
    ep: 0
  });
  $altslots.get(0).innerHTML = buffer;
  $altslots.find(".slot[id='" + selected_id + "']").addClass("active");
  showPopup($popup);
  return false;
}

// Change out an enchant, for binding to event delegation
function clickSlotEnchant() {
  var buf = clickSlot(this, "enchant"), slot = buf[1];
  var equip_location = SLOT_INVTYPES[slot];

  var enchants = ENCHANT_SLOTS[equip_location];
  epSort(enchants);
  var selected_id = data.gear[slot].enchant;
  var max = ep(enchants[0]);
  var buffer = "";

  for(var i = 0; i<enchants.length; i++) {
    var enchant = enchants[i];
    if(enchant && !enchant.desc) {
      enchant.desc = statsToDesc(enchant);
    }
    var eEP = ep(enchant);
    buffer += template({
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
}

// Change out a gem
function clickSlotGem() {
  var buf = clickSlot(this, "gem"); var $slot = buf[0]; var slot = buf[1];

  var item = ITEM_LOOKUP[parseInt($slot.attr("id"), 10)];
  var socketEPBonus = ((item.socketbonus ? ep(item, "socketbonus") : 0) / item.sockets.length);

  var gemSlot = $slot.find(".gem").index(this);
  $.data(document.body, "gem-slot", gemSlot);
  var gemType = item.sockets[gemSlot];
  var selected_id = data.gear[slot]["gem" + gemSlot];

  for(var i=0; i<GEM_LIST.length; i++) {
    GEM_LIST[i].__ep = ep(GEM_LIST[i]) + (GEM_LIST[i][item.sockets[gemSlot]] ? socketEPBonus : 0);
  }
  GEM_LIST.sort(__epSort);

  var buffer = "";
  var i, gemCt = 0, gem, max, usedNames = {};
  for(i = 0; i < GEM_LIST.length; i++) {
    gem = GEM_LIST[i];
    if(gem.requires && gem.requires.profession && !data.options.professions[gem.requires.profession]) { continue; }
    if(gemType == "Meta" && gem.slot != "Meta") { continue; }
    else if(gemType != "Meta" && gem.slot == "Meta") { continue; }
    else if(gemType == "Cogwheel" && gem.slot != "Cogwheel") { continue; }
    else if(gemType != "Cogwheel" && gem.slot == "Cogwheel") { continue; }

    if(!max) { max = gem.__ep; }
    if(usedNames[gem.name]) {
      if(gem.id == selected_id) {
        selected_id = usedNames[gem.name];
      }
      continue;
    }
    gemCt += 1;
    if(gemCt > 50) { break; }
    usedNames[gem.name] = gem.id;
    var gEP = gem.__ep;
    var desc = statsToDesc(gem);
    if(gem[item.sockets[gemSlot]]) {
      desc += " (+" + socketEPBonus.toFixed(1) + " bonus)";
    }
    buffer += template({
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
}

function clickSlotReforge() {
  clickSlot(this, "reforge");
  $(".slot").removeClass("active");
  $(this).addClass("active");

  var $slot = $(this).closest(".slot");
  var slot = parseInt($slot.attr("data-slot"), 10);
  $.data(document.body, "selecting-slot", slot);

  var id = $slot.attr("id");
  var item = ITEM_LOOKUP[id];
  var existingReforge = data.gear[slot].reforge ? data.gear[slot].reforge.stats : null;

  $.data(document.body, "reforge-amount", null);
  var rec = recommendReforge(item.stats, existingReforge);
  var source = sourceStats(item.stats);
  var targetStats = _.select(REFORGE_STATS, function(s) { return item.stats[s.key] === undefined; });
  $.data(document.body, "reforge-recommendation", rec);
  $.data(document.body, "reforge-item", item);
  $("#reforge").html(reforgeTemplate({
    stats: source,
    newstats: targetStats,
    recommended: rec
  }));
  $("#reforge .pct").hide();
  showPopup($("#reforge.popup"));
  return false;
}

$("#reforge").click($.delegate({
  ".label_radio": setupLabels,
  ".doReforge": doReforge,
  ".clearReforge": clearReforge
}));

// Change out an item
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

// Select an item from a popup
$altslots.click($.delegate({
  ".slot": function(e) {
    var slot = $.data(document.body, "selecting-slot");
    var update = $.data(document.body, "selecting-prop");
    var $this = $(this);
    if(update == "item_id" || update == "enchant") {
      var val = parseInt($this.attr("id"), 10);
      data.gear[slot][update] = val != 0 ? val : null;
      if(update == "item_id") {
        data.gear[slot].reforge = null;
      } else {
        log("Changing " + ITEM_LOOKUP[data.gear[slot].item_id].name + " enchant to " + ENCHANT_LOOKUP[val].name);
      }
    } else if (update == "gem") {
      var item_id = parseInt($this.attr("id"), 10);
      var gem_id = $.data(document.body, "gem-slot");
      log("Regemming " + ITEM_LOOKUP[data.gear[slot].item_id].name + " socket " + (gem_id + 1) + " to " + GEMS[item_id].name);
      data.gear[slot]["gem" + gem_id] = item_id;
    }
    RogueApp.updateDisplayedGear();
  }
}));
  var EP_PRE_REGEM;
function optimizeGems(depth) {
  if(!depth) { depth = 0; }
  if(depth === 0) { EP_PRE_REGEM = EP_TOTAL; }
  var madeChanges = false;

  var gem_list = getGemRecommendationList();

  for(var si = 0; si < slotOrder.length; si++) {
    var gear = data.gear[slotOrder[si]];
    if(!gear) { continue; }
    var item = ITEM_LOOKUP[gear.item_id];

    if(item) {
      var rec = getGemmingRecommendation(gem_list, item, true);
      for(var i = 0; i < rec.gems.length; i++) {
        var from_gem = GEMS[gear["gem" + i]];
        var to_gem = GEMS[rec.gems[i]];
        if(gear["gem" + i] != rec.gems[i]) {
          if(from_gem && to_gem) {
            if(from_gem.name == to_gem.name) { continue; }
            log("Regemming " + item.name + " socket " + (i+1) + " from " + from_gem.name + " to " + to_gem.name);
          } else {
            log("Regemming " + item.name + " socket " + (i+1) + " to " + to_gem.name);
          }
          gear["gem" + i] = rec.gems[i];
          madeChanges = true;
        }
      }
    }
  }
  if(!madeChanges || depth >= 10) {
    RogueApp.updateDisplayedGear();
    log("Finished automatic regemming: &Delta; " + Math.floor(EP_TOTAL - EP_PRE_REGEM) + " EP");
  } else {
    optimizeGems(depth + 1);
  }
}
RogueApp.optimizeGems = optimizeGems;

// Returns an EP-sorted list of gems with the twist that the
// JC-only gems are sorted at the same EP-value as regular gems.
// This prevents the automatic picking algorithm from choosing
// JC-only gems over the slot bonus.
function getGemRecommendationList() {
  var list = $.extend(true, [], GEM_LIST);
  list.sort(function(a, b) {
    return getRegularGemEpValue(b) - getRegularGemEpValue(a);
  });
  return list;
}
  /****************
** Reforging
****************/
function canReforge(item) {
  if(item.ilvl < 200) { return false; }
  for(var stat in item.stats) {
    if(_.include(reforgableStats, stat)) {
      return true;
    }
  }
  return false;
}

function sourceStats(stats) {
  var source = [];
  for(var stat in stats) {
    if(stats.hasOwnProperty(stat) && _.include(reforgableStats, stat)) {
      source[source.length] = {
        key: stat,
        name: titleize(stat),
        value: stats[stat],
        use: Math.floor(stats[stat] * REFORGE_FACTOR)
      };
    }
  }
  return source;
}

function recommendReforge(source, ignore) {
  var dest = REFORGE_STATS;
  var rec = { };
  var max_ep, rmax, max_ep_src, max_ep_dest, max_ep_qty, reforgable = false;
  for(var stat in source) {
    if(_.include(reforgableStats, stat)) {
      reforgable = true;
      var ramt = Math.floor(source[stat] * REFORGE_FACTOR);
      var ep = getStatWeight(stat, -ramt, ignore);
      for(var idx = 0; idx < REFORGE_STATS.length; idx++) {
        if(source[REFORGE_STATS[idx].key]) { continue; }
        var dstat = REFORGE_STATS[idx].key;
        var dep = getStatWeight(dstat, ramt, ignore);
        rec[stat + "_to_" + dstat] = dep + ep;
        if(!rmax || Math.abs(dep + ep) > rmax) { rmax = Math.abs(dep + ep); }
        if(!max_ep || dep + ep > max_ep) {
          max_ep = dep + ep;
          max_ep_src = stat;
          max_ep_dest = dstat;
          max_ep_qty = ramt;
        }
      }
    }
  }
  if(!reforgable) { return; }

  rec = _.extend(rec, {
    max: max_ep,
    rmax: rmax,
    qty: max_ep_qty,
    source: {
      key: max_ep_src,
      name: titleize(max_ep_src)
    },
    dest: {
      key: max_ep_dest,
      name: titleize(max_ep_dest)
    }
  });
  return rec;
}

var EP_PRE_REFORGE;
function reforgeAll(depth) {
  if(!depth) { depth = 0; }
  if(depth === 0) { EP_PRE_REFORGE = EP_TOTAL; }
  var madeChanges = false;
  for(var si = 0; si < slotOrder.length; si++) {
    var i = slotOrder[si];
    var gear = data.gear[i];
    if(!gear) { continue; }
    var item = ITEM_LOOKUP[gear.item_id];
    if(item) {
      if(canReforge(item)) {
        var rec = recommendReforge(item.stats, gear.reforge ? gear.reforge.stats: null);
        if(rec && rec.max > 0 && (!gear.reforge || (gear.reforge.from.stat != rec.source.name || gear.reforge.to.stat != rec.dest.name))) {
          log("Reforging " + item.name + " to -" + rec.qty + " " + rec.source.name + "/+" + rec.qty + " " + rec.dest.name);
          madeChanges = true;
          gear.reforge = {stats: {}};
          gear.reforge.stats[rec.source.key] = -rec.qty;
          gear.reforge.stats[rec.dest.key]   =  rec.qty;
          gear.reforge.from = {stat: rec.source.name, value: -rec.qty};
          gear.reforge.to   = {stat: rec.dest.name,   value:  rec.qty};
          sumStats();
        }
      }
    }
  }
  if(!madeChanges || depth >= 10) {
    RogueApp.updateDisplayedGear();
    log("Finished automatic reforging: &Delta; " + Math.floor(EP_TOTAL - EP_PRE_REFORGE) + " EP");
  } else {
    reforgeAll(depth + 1);
  }
}
RogueApp.reforgeAll = reforgeAll;

function clearReforge() {
  var slot = $.data(document.body, "selecting-slot");
  var gear = data.gear[slot];
  if(!gear) { return; }
  if(gear.reforge) delete gear.reforge;
  log("Removing reforge on " + ITEM_LOOKUP[gear.item_id].name);
  $("#reforge").removeClass("visible");
  RogueApp.updateDisplayedGear();
}

function doReforge() {
  var slot = $.data(document.body, "selecting-slot");
  var amt = $.data(document.body, "reforge-amount");
  var from = $("#reforge input[name='oldstat']:checked").val();
  var to = $("#reforge input[name='newstat']:checked").val();
  var gear = data.gear[slot];
  if(!gear) { return; }

  gear.reforge = {};
  if(slot !== undefined && amt !== undefined && from !== undefined && to !== undefined) {
    // Write as a hash for easy computation when summing a slot's stats...
    gear.reforge.stats = {};
    gear.reforge.stats[from] = -amt;
    gear.reforge.stats[to] = amt;
    // ...and as a pair of objects for use in templates.
    gear.reforge.from = {stat: titleize(from), value: -amt};
    gear.reforge.to = {stat: titleize(to), value: amt};
  }
  log("Reforging " + ITEM_LOOKUP[gear.item_id].name + " to " + gear.reforge.from.value + " " + gear.reforge.from.stat + "/+" + gear.reforge.to.value + " " + gear.reforge.to.stat);
  $("#reforge").removeClass("visible");
  RogueApp.updateDisplayedGear();
}

$(".oldstats input").live("change", function() {
    var rec = $.data(document.body, "reforge-recommendation");
    var item = $.data(document.body, "reforge-item");
    var src = $(this).val();
    var amt = Math.floor(item.stats[src] * REFORGE_FACTOR);
    $.data(document.body, "reforge-amount", amt);
    $("#reforge .pct").each(function() {
      var $this = $(this);
      var target = $this.closest(".stat").attr("data-stat");
      var ep = rec[src + "_to_" + target];
      var width = Math.abs(ep) / rec.rmax * 50;
      var inner = $this.find(".pct-inner");
      inner.removeClass("reverse");
      $this.find(".label").text(ep.toFixed(1));
      if(ep < 0) {
        inner.addClass("reverse");
      }
      inner.css({width: width + "%"});
      $this.hide().fadeIn('normal');
    });
  });
  $("#talents #talentframe, #gear .slots").mousemove(function(e){
  $.data(document, "mouse-x", e.pageX);
  $.data(document, "mouse-y", e.pageY);
});

if(window.FLASH.length > 0) {
  setTimeout(function() {
    flash("<p>" + window.FLASH.join("</p><p>") + "</p>");
  }, 1000);
}

$("#tabs").tabs({
  show: function(event, ui) {
    if(ui.tab.hash == "#talents") {
      // initTalentsPane();
    } else if(ui.tab.hash == "#impex") {
      $("#export").text("[" + uuid + "]" + json_encode(data));
    }
  }
});

function reset() {
  $(".popup:visible").removeClass("visible");
  ttlib.hide();
  $slots.find(".active").removeClass("active");
}
$("body").click(reset).keydown(function(e) {
  if(e.keyCode == 27) {
    reset();
  }
});

$("#filter, #reforge").click(function(e) { e.cancelBubble = true; e.stopPropagation(); });
$("input.search").keydown(function(e) {
  var $this = $(this);
  var $popup = $this.closest(".popup");
  var next, slots, i;
  switch(e.keyCode) {
    case 27:    // Esc
      $this.val("");
      $this.blur();
      $this.keyup();
      e.cancelBubble = true;
      e.stopPropagation();
      break;
    case 38:    // Up arrow
      slots = $popup.find(".slot:visible");
      for(i = 0; i < slots.length; i++) {
        if(slots[i].className.indexOf("active") != -1) {
          if(slots[i-1]) {next = $(slots[i-1]); break; }
          else { next = $popup.find(".slot:visible").last(); break; }
        }
      }
      break;
    case 40:    // Down arrow
      slots = $popup.find(".slot:visible");
      for(i = 0; i < slots.length; i++) {
        if(slots.get(i).className.indexOf("active") != -1) {
          if(slots[i+1]) { next = $(slots[i+1]); break; }
          else { next = $popup.find(".slot:visible").first(); break; }
        }
      }
      break;
    case 13:    // Enter
      $popup.find(".active").click();
      return;
  }
  if(next) {
    $popup.find(".slot").removeClass("active");
    next.addClass("active");
    var ot = next.get(0).offsetTop;
    var height = $popup.height();
    var body = $popup.find(".body");

    if(ot > body.scrollTop() + height - 30) {
      body.animate({scrollTop: next.get(0).offsetTop - height + next.height() + 30}, 150);
    } else if (ot < body.scrollTop()) {
      body.animate({scrollTop: next.get(0).offsetTop - 30}, 150);
    }
  }
}).keyup(function(e) {
  var $this = $(this);
  var popup = $this.parents(".popup");
  var search = $.trim($this.val().toLowerCase());
  var all = popup.find(".slot");
  var show = all.filter(":regex(data-search, " + search + ")");
  var hide = all.not(show);
  show.removeClass("hidden");
  hide.addClass("hidden");
});

$(document).keyup(function(e) {
  if(e.altKey) {
    if(e.keyCode >= 49 && e.keyCode <= 58) {
      $("#tabs").tabs("select", e.keyCode - 49);
      return false;
    }
  }
});

  // And boot it up
  initTalentsPane();
  initGlyphs();
  updateView();
  setupLabels();
};
