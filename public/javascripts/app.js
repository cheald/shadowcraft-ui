/**
 * Prevents click-based selectiion of text in all matched elements.
 */

window["RogueApp"] = {};
RogueApp.setupLabel = function() {
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

RogueApp.commonInit = function($) {
  $('.label_check, .label_radio').live("click", RogueApp.setupLabel);
  $( "button, input:submit, .button").button();
};

RogueApp.initApp = function($, uuid, data, serverData) {
  // Config
  var RATING_CONVERSIONS = {
    80: {
      hit_rating: 30.7548,
      spell_hit: 26.24,
      expertise_rating: 32.78998947      
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
  
  var REFORGE_FACTOR = 0.4;
  var MAX_TALENT_POINTS = 36;
  
  /**************************************************************************************************************/
  
  RogueApp.ServerData = serverData;
  RogueApp.Data = data;
  var D = data;
  if(!data.options) { data.options = {}; }
  var statSum;  
  
  var ITEM_LOOKUP = serverData.ITEM_LOOKUP, WEIGHTS = serverData.WEIGHTS, ITEMS = serverData.ITEMS, SLOT_CHOICES = serverData.SLOT_CHOICES,
    TALENTS = serverData.TALENTS, TALENT_LOOKUP = serverData.TALENT_LOOKUP, GEMS = serverData.GEMS, ENCHANT_LOOKUP = serverData.ENCHANT_LOOKUP, 
    ENCHANT_SLOTS = serverData.ENCHANT_SLOTS, GEM_LIST = serverData.GEM_LIST;
  if(!data.weights) { data.weights = WEIGHTS; }
    
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
  }  
  
  $(function() {
    RogueApp.setupLabel();
  });
  
  $("select").selectmenu({ style: 'dropdown' });
  $("#talents").mousemove(function(e){
    $.data(document, "mouse-x", e.pageX);
    $.data(document, "mouse-y", e.pageY);
  });
  

  var template = Handlebars.compile($("#template-itemSlot").html());
  var statsTemplate = Handlebars.compile($("#template-stats").html());  
  var reforgeTemplate = Handlebars.compile($("#template-reforge").html());
  var checkboxTemplate = Handlebars.compile($("#template-checkbox").html());
  var talentTreeTemplate = Handlebars.compile($("#template-tree").html());
  var tooltipTemplate = Handlebars.compile($("#template-tooltip").html());
  var talentSetTemplate = Handlebars.compile($("#template-talent_set").html());
  var logTemplate = Handlebars.compile($("#template-log").html());
  
  function saveData() {
    $.jStorage.set(uuid, data);
  }
  
  var $slots = $(".slots");
  var $popup = $(".alternatives");
  var $altslots = $(".alternatives .body");
  var json_encode = $.toJSON || Object.toJSON || (window.JSON && (JSON.encode || JSON.stringify));
  /*
  var json_decode = $.evalJSON || (window.JSON && (JSON.decode || JSON.parse)) || function(str){
      return String(str).evalJSON();
  };
  */
  var talentsSpent = 0;
  
  /************************************
  *** Computation Utility Functions ***
  ************************************/
  
  function _T(str) {
    var idx = _.indexOf(serverData.TALENT_INDEX, str);
    if(!data.activeTalents) { return 0; }
    return parseInt(data.activeTalents[idx], 10);
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
  
  function aep(item, key) {
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
    return Math.round(total * 10) / 10;
  }
  
  function sumStats() {
    var stats = {};
    for(var si = 0; si < slotOrder.length; si++) {
      var i = slotOrder[si];
      var gear = data.gear[i];
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
        
        var a1 = stats.agility;
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
  
  // TODO: Adjust for racial bonuses.
  // Stat to get the real weight for, the amount of the stat, and a hash of {stat: amount} to ignore (like if swapping out a reforge or whatnot; nil the existing reforge for calcs)
  function getStatWeight(stat, num, ignore, ignoreAll) {
    if(!statSum) { sumStats(); }
    var exist = ignoreAll ? 0 : ((statSum[stat] || 0) - (ignore ? (ignore[stat] || 0) : 0));
    var neg = num < 0 ? -1 : 1;
    num = Math.abs(num);
    var modNum = num;
    switch(stat) {    
    case "expertise_rating":
      var expertiseCap = _R("expertise_rating") * 6.1; 
      var usable = expertiseCap - exist; usable = usable < 0 ? 0 : usable; usable = usable > num ? num : usable;
      return data.weights.expertise_rating * usable * neg;
    case "hit_rating":
      var whiteHitCap = _R("hit_rating") * (27 - 2 * _T("precision"));
      var spellHitCap = _R("spell_hit")  * (17 - 2 * _T("precision"));      
      var spellHit = spellHitCap - exist; spellHit = spellHit < 0 ? 0 : spellHit; spellHit = spellHit > num ? num : spellHit;
      var whiteHit = whiteHitCap - exist; whiteHit = whiteHit < 0 ? 0 : whiteHit; whiteHit = (num - spellHit) > whiteHit ? whiteHit : (num - spellHit);
      return ((data.weights.spell_hit * spellHit) + (data.weights.hit_rating * whiteHit)) * neg;
    }    
    return (data.weights[stat] || 0) * num * neg;
  }
  
  var presortedLists = {};
  function __aepSort(a, b) { return b.__aep - a.__aep; }
  function aepSort(list, skipSort) {
    // if(!presortedLists[list]) {
      for(var i = 0; i < list.length; i++) {
        if(list[i]) {
          list[i].__aep = aep(list[i]);
        }
      }
    // }
    // presortedLists[list] = true;
    if(!skipSort) {
      list.sort(__aepSort);
    }
  }  
  
  // Assumes that you've AEP-sorted your gem list beforehand!
  function getGemmingRecommendation(item, returnFull) {
    if(!item.sockets || item.sockets.length === 0) {
      if(returnFull) {
        return {aep: 0, gems: []};
      } else {
        return 0;
      }
    }
    
    var straightGemAEP = 0, matchedGemAEP = aep(item, "socketbonus"), s, i, gemType, gem, sGems, mGems, gems;
    if(returnFull) {
      sGems = []; mGems = [];
    }
    
    for(s = 0; s < item.sockets.length; s++) {
      gemType = item.sockets[s];
      for(i = 0; i < GEM_LIST.length; i++) {
        gem = GEM_LIST[i];
        if(gem.requires && gem.requires.profession && !data.options.professions[gem.requires.profession]) { continue; }
        if(gemType == "Meta" && gem.slot != "Meta") { continue; }
        if(gemType != "Meta" && gem.slot == "Meta") { continue; }                
        straightGemAEP += aep(gem);
        if(returnFull) { sGems[sGems.length] = gem.id; }
        break;
      }
    }
    
    for(s = 0; s < item.sockets.length; s++) {
      gemType = item.sockets[s];
      for(i = 0; i < GEM_LIST.length; i++) {
        gem = GEM_LIST[i];
        if(gem.requires && gem.requires.profession && !data.options.professions[gem.requires.profession]) { continue; }
        if(gemType == "Meta" && gem.slot != "Meta") { continue; }
        if(gemType != "Meta" && gem.slot == "Meta") { continue; }                
        if(gem[gemType]) {
          matchedGemAEP += aep(gem);
          if(returnFull) { mGems[mGems.length] = gem.id; }
          break;
        }
      }
    }
    
    var aepValue, gemList, bonus = false;
    if(matchedGemAEP > straightGemAEP) {
      aepValue = matchedGemAEP;
      gems = mGems;
      bonus = true;
    } else {
      aepValue = straightGemAEP;
      gems = sGems;
    }
    if(returnFull) {
      return {aep: aepValue, takeBonus: bonus, gems: gems};
    } else {
      return aepValue;
    }
  }  
  
  /************************************
  ***  Interface Utility Functions  ***
  ************************************/
  function titleize(str) {
    if(!str) { return ""; }
    var sp = str.split(/[ _]/); var f, r; var word = [];
    for (var i = 0 ; i < sp.length ; i ++ ) { f = sp[i].substring(0,1).toUpperCase(); r = sp[i].substring(1).toLowerCase(); word[i] = f+r; }
    return word.join(' ');
  }  
  
  var AEP_TOTAL;
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
        aep: Math.floor(weight)
      };
    }
    a_stats[a_stats.length] = {
      name: "Total AEP",
      aep: Math.floor(total)
    };
    AEP_TOTAL = total;
    $stats.get(0).innerHTML = statsTemplate({stats: a_stats});
  }    
  
  var $log = $("#log .inner");
  function log(msg) {
    $log.prepend("<div>" + msg + "</div");
  }
  
  function warn(item, msg, submsg, klass) {
    consoleMessage(item, msg, submsg, "warning", klass);
  }
  
  var $console = $("#console .inner");
  function consoleMessage(item, msg, submsg, severity, klass) {
    var fullMsg = logTemplate({
      name: item.name,
      quality: item.quality,
      message: msg,
      submsg: submsg,
      severity: severity,
      messageClass: klass
    });
    
    if(klass && false) {
      var exist = $console.find("#" + klass);
      if(exist.length > 0) {
        exist.replaceWith(fullMsg);
        return;
      }
    }    
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
      $(".flash").fadeIn(1200);
    }    
    if(flashHide) { window.clearTimeout(flashHide); }
    flashHide = window.setTimeout(hideFlash, 4000);
  }
  RogueApp.flash = flash;
  
  RogueApp.ResetLocalStorage = function() {
    if(confirm("This will wipe out any changes you've made. Proceed?")) {
      $.jStorage.flush(); window.location.reload();
    }
  }
  
  /**************************
  ***  UI Init Functions  ***
  **************************/
  var talentTree = [];
  
  if(window.FLASH.length > 0) {
    setTimeout(function() {
      flash("<p>" + window.FLASH.join("</p><p>") + "</p>");
    }, 1000);  
  }
  
  // Item form callback
  $("form#new_item").bind('ajax:success', function(_, data, status, xhr) {
    if(data.id && data.name) {
      if(!ITEM_LOOKUP[data.id]) {
        ITEM_LOOKUP[data.id] = data;
        ITEMS[ITEMS.length] = data;
        if(data.equip_location) {
          SLOT_CHOICES[data.equip_location][SLOT_CHOICES[data.equip_location].length] = data;
        }
      }
      flash("Item added: " + data.name);
    } else {
      flash("Invalid item");
    }
  });
  
  $(".floater h3").disableTextSelection();
  // $(".floater").draggable({
  
  $("select#race").val(data.race).change(function() { data.race = $(this).val(); });
  function initChecks(selector, namespace, checkData) {    
    var s = $(selector);
    _.each(checkData, function(str, key) {
      var ns = data.options[namespace];
      if(!ns) { data.options[namespace] = {}; ns = data.options[namespace]; }
      var checked = ns[key] ? "checked" : "";
      s.append(checkboxTemplate({key: key, label: str, checked: checked, namespace: namespace}));
    });
  }  

  $("#tabs").tabs({
    show: function(event, ui) {
      if(ui.tab.hash == "#talents") {
        initTalentsPane();
      } else if(ui.tab.hash == "#impex") {
        $("#export").text("[" + uuid + "]" + json_encode(data));
      }
    }
  });
  
  initChecks("#professions", "professions", {
    blacksmithing: "Blacksmithing",
    enchanting: "Enchanting",
    engineering: "Engineering",
    inscription: "Inscription",
    jewelcrafting: "Jewelcrafting",
    leatherworking: "Leatherworking",
    tailoring: "Tailoring"
  });

  initChecks("#buffs", "playerBuffs", {
    bok: "Blessing of Kings",
    ap: "Battle Shout",
    haste: "Windfury"
  });

  initChecks("#debuffs", "targetDebuffs", {
    major_armor: "Major Armor",
    minor_armor: "Minor Armor",
    spell_hit: "Spell Hit"
  });

  initChecks("#settings #rotation", "rotation", {
    rvs_rupture_4: "Use Revealing Strike for 4CP Rupture?",
    rvs_rupture_5: "Use Revealing Strike for 5CP Rupture?",
    rvs_evis_4: "Use Revealing Strike for 4CP Eviscerate?",
    rvs_evis_5: "Use Revealing Strike for 5CP Eviscerate?"   
  });
  
  $(".optionCheck").change(function() {
    var $this = $(this);
    var ns = $this.attr("data-ns") || "root";
    if(!data.options[ns]) { data.options[ns] = {}; }
    data.options[ns][$this.attr("name")] = $this.is(":checked");
    saveData();
  });
  
  for(var key in data.weights) {
    if(data.weights.hasOwnProperty(key)) {
      $("#weights .inner").append("<dt>" + titleize(key) + "</dt><dd><input type='text' id='weight-" + key + "' data-stat='" + key + "' value='" + data.weights[key] + "'/>");
    }
  }
  $("#weights .inner input").change(function() {
    var attr = $.trim($(this).attr("data-stat"));
    data.weights[attr] = parseFloat($(this).val());
    RogueApp.updateDisplayedGear();
  });
  
  /***********************************
  ** Talents
  ***********************************/

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
  
  function applyTalent(tree, row, col, dir) {
    var button = talentTree[tree * 25 + (row * 4) + col];
    return applyTalentToButton(button, dir);
  }
  
  function resetTalents() {
    $("#talentframe .talent").each(function() {
      var points = $.data(this, "points");
      applyTalentToButton(this, -points.cur, true, true);
    });      
    data.activeTalents = getTalents();
    updateTalentAvailability();
  }
  
  function setTalents(str) {
    if(!str) { return; }
    var ct = 0;
    $("#talentframe .talent").each(function() {
      var points = $.data(this, "points");
      applyTalentToButton(this, parseInt(str[ct], 10) - points.cur, true, true);
      ct++;
    });
    data.activeTalents = getTalents();
    updateTalentAvailability();
  }
  
  function getTalents() {
    return _.map($("#talentframe .talent"), function(t) {
      return $.data(t, "points").cur || 0;
    }).join("");
  }
  
  RogueApp.resetTalents = resetTalents;
  RogueApp.setTalents = setTalents;
  RogueApp.getTalents = getTalents;  
  
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
      talentTree[tree * 25 + (row * 4) + col] = this;      
    }).mousedown(function(e) {      
      if(!$(this).hasClass("active")) { return; }
      
      switch(e.which) {
      case 1:
        applyTalentToButton(this, 1);
        break;
      case 3:
        applyTalentToButton(this, -1);
        break;
      }      
      $(this).trigger("mouseenter");      
    }).bind("contextmenu", function() { return false; })
    .mouseenter(hoverTalent)
    .mouseleave(function() { $("#tooltip").hide();});  
    
    buffer = "";
    for(var talentName in data.talents) {
      if(data.talents.hasOwnProperty(talentName)) {
        buffer += talentSetTemplate({
          talent_string: data.talents[talentName],
          name: talentName
        });
      }
    }
    $("#talentsets").get(0).innerHTML = buffer;
    
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
  
  $("#talentsets").click($.delegate({
    ".talent_set": function() { setTalents($(this).attr("data-talents")); }
  }));
  
  RogueApp.updateDisplayedGear = function() {
    saveData();    
    $("#console .inner").empty();

    updateStatsWindow();
    var buffer = "";
    var bestOptionalReforge;
    for(var si = 0; si < slotOrder.length; si++) {
      var i = slotOrder[si];
      var gear = data.gear[i];
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
        
        if(canReforge(item)) {
          if(!gear.reforge) {
            warn(item, "needs to be reforged");
          } else {
            var rec = recommendReforge(item.stats, gear.reforge.stats);
            if(rec && (gear.reforge.from.stat != rec.source.name || gear.reforge.to.stat != rec.dest.name)) {
              var delta = Math.round(rec[rec.source.key + "_to_" + rec.dest.key] * 100) / 100;
              if(delta > 0) {
                if(!bestOptionalReforge || bestOptionalReforge < delta) {
                  bestOptionalReforge = delta;
                  warn(item,
                    "is not using an optimal reforge",
                    "Using " + gear.reforge.from.stat + " &Rightarrow; " + gear.reforge.to.stat + ", recommend " + rec.source.name + " &Rightarrow; " + rec.dest.name + " (+" + delta + ")",
                    "reforgeWarning"
                  );
                }
              }
            }
          }
        }        
        
        if(!enchant && enchantable) {
          warn(item, "needs an enchantment");
        }
      }
      buffer += template({
        item: item,
        ttid: item ? item.id : null,
        aep: item ? aep(item) : 0,
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
    $slots.get(0).innerHTML = buffer;
  };
  
  RogueApp.updateDisplayedGear();
  
  function addTradeskillBonuses(item) {
    if(!item.sockets) { item.sockets = []; }
    if(!item._sockets) { item._sockets = item.sockets.slice(0); }    // Originals    
    var blacksmith = data.options.professions.blacksmithing;
    if(item.equip_location == 9 || item.equip_location == 10) {      
      if(blacksmith && item.sockets[item.sockets.length-1] != "Prismatic") { item.sockets[item.sockets.length] = "Prismatic"; }
      else if(!blacksmith && item.sockets[item.sockets.length-1] == "Prismatic") { item.sockets[item.sockets.length].slice(0, item.sockets.length - 2); }
    }
  }

  // Select an item from a popup
  $altslots.click($.delegate({
    ".slot": function(e) {
      var slot = $.data(document.body, "selecting-slot");
      var update = $.data(document.body, "selecting-prop");
      var $this = $(this);
      if(update == "item_id" || update == "enchant") {
        var val = parseInt($this.attr("id"), 10);
        data.gear[slot][update] = val > 0 ? val : null;
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
  
  // Standard setup for the popup
  var popupTop;
  function clickSlot(slot, prop) {
    var $slot = $(slot).closest(".slot");
    popupTop = $slot.position().top;
    $slots.find(".slot").removeClass("active");
    $slot.addClass("active");
    var slotIndex = parseInt($slot.attr("data-slot"), 10);
    $.data(document.body, "selecting-slot", slotIndex);
    $.data(document.body, "selecting-prop", prop);
    return [$slot, slotIndex];
  }
  
  function showPopup(popup) {
    // $(".popup").hide();
    $(".popup").removeClass("visible");
    // popup.show();
    if(popupTop !== undefined) {
      var max = document.body.scrollTop + $(window).height();
      var top = popupTop;
      if(popupTop + popup.height() + 200 > max) {
        top = max - popup.height() - 200;
      }    
      popup.css({top: top + "px"});
    }
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
  
  // Click a name in a slot, for binding to event delegation
  function clickSlotName() {
    var i, buf = clickSlot(this, "item_id"); var $slot = buf[0]; var slot = buf[1];
    var selected_id = + $slot.attr("id");
    var equip_location = SLOT_INVTYPES[slot];    
    
    var loc = SLOT_CHOICES[equip_location];
    aepSort(GEM_LIST); // Needed for gemming recommendations
    for(i = 0; i < loc.length; i++) {        
      loc[i].__gemRec = getGemmingRecommendation(loc[i], true);
      loc[i].__gemAEP = Math.round(loc[i].__gemRec.aep * 10) / 10;
      
      var rec = recommendReforge(loc[i].stats);
      if(rec) {
        var reforgedStats = {};
        reforgedStats[rec.source.key] = -rec.qty;
        reforgedStats[rec.dest.key] = rec.qty;
        var deltaAep = aep({stats: reforgedStats});
        if(deltaAep > 0) {
          loc[i].__reforgeAep = deltaAep;
        } else {
          loc[i].__reforgeAep = 0;
        }
      } else {
        loc[i].__reforgeAep = 0;
      }
      
      loc[i].__aep = aep(loc[i]) + loc[i].__gemRec.aep + loc[i].__reforgeAep;
    }
    loc.sort(__aepSort);
    var max = loc[0].__aep;
    var buffer = "";
    for(i = 0; i < loc.length; i++) {
      var iAep = Math.round(loc[i].__aep * 10) / 10;
      buffer += template({
        item: loc[i],
        gear: {},
        gems: [],
        ttid: loc[i].id,
        desc: aep(loc[i]) + " base / " + loc[i].__reforgeAep + " reforge / " + loc[i].__gemAEP + " gem " + (loc[i].__gemRec.takeBonus ? "(Match gems)" : ""),
        search: loc[i].name,
        percent: iAep / max * 100,
        aep: iAep
      });
    }
    buffer += template({
      item: {name: "[No item]"},
      desc: "Clear this slot",
      percent: 0,
      aep: 0
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
    aepSort(enchants);
    var selected_id = data.gear[slot].enchant;
    var max = aep(enchants[0]);
    var buffer = "";
    
    for(var i = 0; i<enchants.length; i++) {
      var enchant = enchants[i];
      if(enchant && !enchant.desc) {
        enchant.desc = statsToDesc(enchant);
      }
      var eAep = aep(enchant);
      buffer += template({
        item: enchant,
        percent: eAep / max * 100,
        aep: eAep,
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
    var socketAEPBonus = Math.floor((item.socketbonus ? aep(item, "socketbonus") : 0) / item.sockets.length * 10) / 10;
    
    var gemSlot = $slot.find(".gem").index(this);
    $.data(document.body, "gem-slot", gemSlot);
    var gemType = item.sockets[gemSlot];
    var selected_id = data.gear[slot]["gem" + gemSlot];
    
    for(var i=0; i<GEM_LIST.length; i++) {
      GEM_LIST[i].__aep = aep(GEM_LIST[i]) + (GEM_LIST[i][item.sockets[gemSlot]] ? socketAEPBonus : 0);
    }
    GEM_LIST.sort(__aepSort);
    
    var buffer = "";
    var i, gemCt = 0, gem, max, usedNames = {};
    for(i = 0; i < GEM_LIST.length; i++) {        
      gem = GEM_LIST[i];
      if(gem.requires && gem.requires.profession && !data.options.professions[gem.requires.profession]) { continue; }      
      if(gemType == "Meta" && gem.slot != "Meta") { continue; }
      if(gemType != "Meta" && gem.slot == "Meta") { continue; }
      if(!max) { max = gem.__aep; }
      if(usedNames[gem.name]) {
        if(gem.id == selected_id) {
          selected_id = usedNames[gem.name];
        }
        continue;
      }
      gemCt += 1;
      if(gemCt > 50) { break; }
      usedNames[gem.name] = gem.id;
      var gAep = Math.round(gem.__aep * 10) / 10;
      var desc = statsToDesc(gem);
      if(gem[item.sockets[gemSlot]]) {
        desc += " (+" + (Math.round(socketAEPBonus * 10) / 10) + " bonus)";
      }
      buffer += template({
        item: gem,
        aep: gAep,
        gear: {},
        ttid: gem.id,
        search: gem.name + " " + statsToDesc(gem) + " " + gem.slot,
        percent: gAep / max * 100,
        desc: desc
      });
    }
    $altslots.get(0).innerHTML = buffer;
    $altslots.find(".slot[id='" + selected_id + "']").addClass("active");
    showPopup($popup);
    return false;
  }
  
  $("#reforge").click($.delegate({
    ".label_radio": RogueApp.setupLabel,
    "input[type='button']": doReforge
  }));
  
  function clickSlotReforge() {
    clickSlot(this, "reforge");
    $(".slot").removeClass("active");
    $(this).addClass("active");
    
    var $slot = $(this).closest(".slot");
    var slot = parseInt($slot.attr("data-slot"), 10);
    $.data(document.body, "selecting-slot", slot);
    
    var id = parseInt($slot.attr("id"), 10);
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
  
  var AEP_PRE_REGEM;
  function optimizeGems(depth) {
    if(!depth) { depth = 0; }
    if(depth === 0) { AEP_PRE_REGEM = AEP_TOTAL; }
    var madeChanges = false;
    
    aepSort(GEM_LIST); // Needed for gemming recommendations
    
    for(var si = 0; si < slotOrder.length; si++) {
      var gear = data.gear[slotOrder[si]];
      var item = ITEM_LOOKUP[gear.item_id];
      
      if(item) {      
        var rec = getGemmingRecommendation(item, true);
        for(var i = 0; i < rec.gems.length; i++) {
          var from_gem = GEMS[gear["gem" + i]];
          var to_gem = GEMS[rec.gems[i]];
          if(gear["gem" + i] != rec.gems[i] && from_gem && to_gem && from_gem.name != to_gem.name) {
            log("Regemming " + item.name + " socket " + (i+1) + " from " + from_gem.name + " to " + to_gem.name);
            gear["gem" + i] = rec.gems[i];            
            madeChanges = true;            
          }
        }
      }
    }
    if(!madeChanges || depth >= 10) {
      RogueApp.updateDisplayedGear();
      log("Finished automatic regemming: &Delta; " + Math.floor(AEP_TOTAL - AEP_PRE_REGEM) + " AEP");
    } else {
      optimizeGems(depth + 1);
    }
  }
  RogueApp.optimizeGems = optimizeGems;
 
  
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
  
  var AEP_PRE_REFORGE;
  function reforgeAll(depth) {
    if(!depth) { depth = 0; }
    if(depth === 0) { AEP_PRE_REFORGE = AEP_TOTAL; }
    var madeChanges = false;
    for(var si = 0; si < slotOrder.length; si++) {
      var i = slotOrder[si];
      var gear = data.gear[i];
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
      log("Finished automatic reforging: &Delta; " + Math.floor(AEP_TOTAL - AEP_PRE_REFORGE) + " AEP");
    } else {
      reforgeAll(depth + 1);
    }
  }
  RogueApp.reforgeAll = reforgeAll;
  
  function doReforge() {
    var slot = $.data(document.body, "selecting-slot");
    var amt = $.data(document.body, "reforge-amount");
    var from = $("#reforge input[name='oldstat']:checked").val();
    var to = $("#reforge input[name='newstat']:checked").val();
    var gear = data.gear[slot];
    
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
    $("#reforge").fadeOut(150);
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
        $this.find(".label").text(Math.floor(ep * 10) / 10);
        if(ep < 0) {
          inner.addClass("reverse");
        }
        inner.css({width: width + "%"});
        $this.hide().fadeIn('normal');
      });
    });
  
  /*****************************
  ** Various interface handlers
  *****************************/

  
  // $(".slot a").live("click", function() { return false; });
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
};