var ttlib = {
  init: function() {
    if(Modernizr.touch) { return; }
    var tooltip = document.createElement("div");
    tooltip.className = "ea-tooltip";
    ttlib.jstooltip = tooltip;
    ttlib.hide();

    ttlib.queue = [];
    ttlib.cache = {};
    ttlib.currentRequest = null;
    ttlib.jstooltip.maxWidth = 370;

    document.getElementsByTagName("body")[0].appendChild(tooltip);
  },

  // Functions for managing visibility or showing tooltips
  show: function() {
    if( !ttlib.jstooltip ) { return; }
    var pos = ttlib.jstooltip.owner.offset();
    var dwidth = document.body.clientWidth;

    var left = pos.left + ttlib.jstooltip.owner.width() + 30;
    var top  = pos.top;
    if(dwidth - left < 400) {
      left = pos.left - ttlib.jstooltip.offsetWidth - 30;
    }

    ttlib.mouseMove(left, top);
    ttlib.jstooltip.style.width = null;
    ttlib.jstooltip.style.visibility = "visible";
  },
  showText: function(text) {
    if( !ttlib.jstooltip ) { return; }

    ttlib.jstooltip.innerHTML = "<div class='border text'>" + text + "</div>";
    ttlib.show();
  },
  showCachedData: function(data) {
    if( !ttlib.jstooltip ) { return; }

    ttlib.jstooltip.innerHTML = data.tooltip;
    ttlib.show();
  },
  showData: function(data) {
    if( !ttlib.jstooltip ) { return; }

    data.tooltip = "<div class='border'>" + data.tooltip + "</div>";
    ttlib.cache[ttlib.currentRequest] = data;

    if( ttlib.currentMouseover == ttlib.currentRequest ) {
      ttlib.showCachedData(data);
    }

    ttlib.currentRequest = null;
    ttlib.processQueue();
  },
  showError: function() {
    if( !ttlib.jstooltip ) { return; }

    ttlib.currentRequest = null;
    ttlib.showText("Error loading tooltip.");
  },
  hide: function() {
    if( !ttlib.jstooltip ) { return; }

    ttlib.jstooltip.style.visibility = "hidden";
    ttlib.currentMouseover = null;
  },

  // Tooltip positioning
  mouseMove: function(x, y) {
    var de = document.documentElement;
    var body = document.body;

    // Figure out the true width, by moving the tooltip to the top left where it can resize as much as it needs
    ttlib.jstooltip.style.left = "0px";
    ttlib.jstooltip.style.top = "0px";
    if( ( ttlib.jstooltip.style.width && ttlib.jstooltip.style.width > ttlib.jstooltip.maxWidth ) || ( ttlib.jstooltip.offsetWidth && ttlib.jstooltip.offsetWidth > ttlib.jstooltip.maxWidth ) ) {
      ttlib.jstooltip.style.width = ttlib.jstooltip.maxWidth + "px";
    }

    // Bottom clamp
    if (y + ttlib.jstooltip.offsetHeight > de.clientHeight + body.scrollTop + de.scrollTop) {
      y += (de.clientHeight + body.scrollTop + de.scrollTop) - (y + ttlib.jstooltip.offsetHeight);
    }
    // Top clamp
    if( y < 0 ) { y = 0; }

    // Right clamp
    // if(x + ttlib.jstooltip.offsetWidth > de.clientWidth - 30)
    // x -= ttlib.jstooltip.offsetWidth + 40

    ttlib.jstooltip.style.left = x+"px";
    ttlib.jstooltip.style.top = y+"px";
  },

  // Queue management
  requestTooltip: function() {
    if(!ttlib.jstooltip) { return; }
    var $this = $(this);
    var id = $this.data("tooltip-id");
    var spellid = $this.data("tooltip-spellid");
    var rand = $this.data("tooltip-rand");
    var upgd = $this.data("tooltip-upgd");
    var bonus = $this.data("tooltip-bonus");
    if(!id) { return; }
    var t = $this.data("tooltip-type") || "item";
    var url = "http://www.wowhead.com/" + t + "=" + id + "&power";
    if(rand && rand != "0") {
      url += "&rand=" + rand;
    }
    if(upgd && upgd != "0") {
      url += "&upgd=" + upgd;
    }
    if(bonus) {
      url += "&bonus=" + bonus;
    }
    url += "&lvl=100";

    ttlib.currentMouseover = url;
    ttlib.jstooltip.style.width = null;
    ttlib.jstooltip.owner = $this;

    if( ttlib.cache[url] ) {
      ttlib.showCachedData(ttlib.cache[url]);
    } else {
      ttlib.queueRequest(url);
      ttlib.showText("Loading tooltip...");
    }
  },
  queueRequest: function(url) {
    if( ttlib.currentRequest != url ) {
      ttlib.queue.push(url);
      ttlib.processQueue();
    }
  },
  processQueue: function() {
    if( ttlib.queue.length === 0 || ttlib.currentRequest ) { return; }

    ttlib.currentRequest = ttlib.queue.pop();

    $.ajax({
      url: ttlib.currentRequest,
      dataType: "script",
      error: ttlib.showError
    });
  },

  // Wowhead fun!
  wowheadTooltip: function(id, showIcon, data) {
    data.tooltip = data.tooltip_enus || data.tooltip_beta;
    ttlib.showData(data);
  }
};

// Wowhead compatibility function
var $WowheadPower = {
  registerItem: ttlib.wowheadTooltip,
  registerSpell: ttlib.wowheadTooltip,
  registerAchievement: ttlib.wowheadTooltip,
  registerStatistic: ttlib.wowheadTooltip,
  registerNpc: ttlib.wowheadTooltip,
  registerObject: ttlib.wowheadTooltip,
  registerQuest: ttlib.wowheadTooltip
};

$(document).ready(ttlib.init);
