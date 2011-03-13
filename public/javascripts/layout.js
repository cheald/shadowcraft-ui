$(function() {

  $(".tab_content").hide();
  $("ul.tabs").each(function() {
    var $this = $(this);
    var active = $this.data("active");
    if(!active) {
      active = 0;
    }
    $($this.find("li").get(active)).addClass("active").show();
    var $tabset = $(".tab_container[data-tabset='" + $this.data("tabset") + "']");
    $($tabset.find(".tab_content").get(active)).show();
  });

  $("ul.tabs li").click(function(e) {
    var $this = $(this);
    var $tabs = $this.closest("ul.tabs");
    var $tabset = $(".tab_container[data-tabset='" + $tabs.data("tabset") + "']");
    $tabs.find("li").removeClass("active");
    $this.addClass("active");
    $tabset.find(".tab_content").animate({opacity: 'hide', height: 'hide'}, 'fast', function() {
      var activeTab = $this.find("a").attr("href");
      $(activeTab).animate({opacity: 'show', height: 'show'}, 'fast');
    });

    e.stopPropagation();
    return false;
  });

  $(".floater h3").disableTextSelection();

});