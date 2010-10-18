var ttlib = {
  init: function() {
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
    ttlib.mouseMove(pos.left + ttlib.jstooltip.owner.width() + 30, pos.top);
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
    var diff;
    if( x + ttlib.jstooltip.offsetWidth > de.clientWidth ) {
      diff = (x + ttlib.jstooltip.offsetWidth) - de.clientWidth;
      x -= diff + (de.clientWidth - x) + 40;
    // Simpler form, only for things that aren't actually off screen but are close enough to clipping that they go
    // over the horizontal scroll bar
    } else if( x + ttlib.jstooltip.offsetWidth + 30 > de.clientWidth ) {
      diff = (x + ttlib.jstooltip.offsetWidth) - de.clientWidth;
      x -= (de.clientWidth - x) + 30;
    }
    ttlib.jstooltip.style.left = x+"px";
    ttlib.jstooltip.style.top = y+"px";
  },
    
  // Queue management
  requestTooltip: function() {
    var $this = $(this);
    var id = $this.data("tooltip-id");
    if(!id) { return; }
    
    var t = $this.data("tooltip-type") || "item";
    var url = "http://www.wowhead.com/" + t + "=" + id + "&power";
    
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
    data.tooltip = data.tooltip_enus;
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