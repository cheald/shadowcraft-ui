Templates = null
ShadowcraftApp.bind "boot", ->
  Templates =
    itemSlot:           Handlebars.compile $("#template-itemSlot").html()
    stats:              Handlebars.compile $("#template-stats").html()
    bonuses:            Handlebars.compile $("#template-bonuses").html()
    checkbox:           Handlebars.compile $("#template-checkbox").html()
    select:             Handlebars.compile $("#template-select").html()
    input:              Handlebars.compile $("#template-input").html()
    talentTree:         Handlebars.compile $("#template-tree").html()
    talentTier:         Handlebars.compile $("#template-tier").html()
    specActive:         Handlebars.compile $("#template-specactive").html()
    tooltip:            Handlebars.compile $("#template-tooltip").html()
    talentSet:          Handlebars.compile $("#template-talent_set").html()
    log:                Handlebars.compile $("#template-log").html()
    glyphSlot:          Handlebars.compile $("#template-glyph_slot").html()
    talentContribution: Handlebars.compile $("#template-talent_contribution").html()
    loadSnapshots:      Handlebars.compile $("#template-loadSnapshots").html()
