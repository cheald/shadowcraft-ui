window.Templates = null
ShadowcraftApp.bind "boot", ->
  window.Templates =
    itemSlot:            Handlebars.compile $("#template-itemSlot").html()
    stats:               Handlebars.compile $("#template-stats").html()
    bonuses:             Handlebars.compile $("#template-bonuses").html()
    checkbox:            Handlebars.compile $("#template-checkbox").html()
    select:              Handlebars.compile $("#template-select").html()
    input:               Handlebars.compile $("#template-input").html()
    subheader:           Handlebars.compile $("#template-subheader").html()
    talentTree:          Handlebars.compile $("#template-tree").html()
    talentTier:          Handlebars.compile $("#template-tier").html()
    specActive:          Handlebars.compile $("#template-specactive").html()
    artifactActive:      Handlebars.compile $("#template-artifactactive").html()
    tooltip:             Handlebars.compile $("#template-tooltip").html()
    talentSet:           Handlebars.compile $("#template-talent_set").html()
    log:                 Handlebars.compile $("#template-log").html()
    talentContribution:  Handlebars.compile $("#template-talent_contribution").html()
    loadSnapshots:       Handlebars.compile $("#template-loadSnapshots").html()
    artifact:            Handlebars.compile $("#template-artifact").html()
