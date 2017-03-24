window.ArtifactTemplates = null

ShadowcraftApp.bind "boot", ->
  window.ArtifactTemplates =
    getDreadbladesTraits: ->
      return [
        {id: "db_blackpowder", spell_id: 216230, max_level: 3, icon: "inv_weapon_rifle_01", ring: "thin", left: 63.194, top: 55.122, is_thin: true},
        {id: "db_bladedancer", spell_id: 202507, max_level: 3, icon: "ability_warrior_bladestorm", ring: "thin", left: 32.222, top: 64.715, is_thin: true},
        {id: "db_blademaster", spell_id: 202628, max_level: 1, icon: "ability_warrior_challange", ring: "thin", left: 56.806, top: 43.415, is_thin: true},
        {id: "db_blunderbuss", spell_id: 202897, max_level: 1, icon: "inv_weapon_rifle_01", ring: "dragon", left: 66.667, top: 22.439},
        {id: "db_blurredtime", spell_id: 202769, max_level: 1, icon: "ability_rogue_quickrecovery", ring: "dragon", left: 67.639, top: 37.724},
        {id: "db_bravado", spell_id: 241153, max_level: 1, icon: "misc_legionfall_rogue", ring: "thick", left: 85.278, top: 73.496},
        {id: "db_concordance", spell_id: 239042, max_level: 50, icon: "trade_archaeology_shark-jaws", ring: "dragon", left: 75.139, top: 73.821},
        {id: "db_curse", spell_id: 202665, max_level: 1, icon: "inv_sword_1h_artifactskywall_d_01dual", ring: "thick", left: 37.639, top: 47.480},
        {id: "db_cursededges", spell_id: 202463, max_level: 1, icon: "inv_sword_33", ring: "thin", left: 22.917, top: 59.675, is_thin: true},
        {id: "db_cursedleather", spell_id: 202521, max_level: 3, icon: "spell_rogue_deathfromabove", ring: "thin", left: 58.611, top: 30.894, is_thin: true},
        {id: "db_cursedsteel", spell_id: 214929, max_level: 1, icon: "inv_sword_1h_artifactskywall_d_02dual", ring: "dragon", left: 7.778, top: 25.041},
        {id: "db_deception", spell_id: 202755, max_level: 1, icon: "ability_rogue_disguise", ring: "thin", left: 47.639, top: 24.715, is_thin: true},
        {id: "db_dreadbladesvigor", spell_id: 238103, max_level: 1, icon: "inv_sword_1h_artifactskywall_d_01dual", ring: "thin", left: 64.583, top: 73.659, is_thin: true},
        {id: "db_fatebringer", spell_id: 202524, max_level: 3, icon: "ability_rogue_cuttothechase", ring: "thin", left: 12.500, top: 57.724, is_thin: true},
        {id: "db_fatesthirst", spell_id: 202514, max_level: 3, icon: "ability_rogue_waylay", ring: "thin", left: 27.500, top: 43.577, is_thin: true},
        {id: "db_fortunesboon", spell_id: 202907, max_level: 3, icon: "ability_rogue_surpriseattack2", ring: "thin", left: 46.111, top: 39.837, is_thin: true},
        {id: "db_fortunestrikes", spell_id: 202530, max_level: 3, icon: "ability_rogue_improvedrecuperate", ring: "thin", left: 46.250, top: 54.959, is_thin: true},
        {id: "db_ghostlyshell", spell_id: 202533, max_level: 3, icon: "spell_shadow_nethercloak", ring: "thin", left: 1.111, top: 65.854, is_thin: true},
        {id: "db_greed", spell_id: 202820, max_level: 1, icon: "warrior_skullbanner", ring: "dragon", left: 1.389, top: 86.016},
        {id: "db_gunslinger", spell_id: 202522, max_level: 3, icon: "inv_weapon_rifle_07", ring: "thin", left: 37.222, top: 27.317, is_thin: true},
        {id: "db_hiddenblade", spell_id: 202753, max_level: 1, icon: "ability_ironmaidens_bladerush", ring: "thin", left: 12.639, top: 81.951, is_thin: true},
        {id: "db_loadeddice", spell_id: 238139, max_level: 1, icon: "ability_rogue_rollthebones", ring: "dragon", left: 75.139, top: 61.789},
        {id: "db_sabermetrics", spell_id: 238067, max_level: 4, icon: "ability_rogue_sabreslash", ring: "thin", left: 75.000, top: 85.691, is_thin: true},
      ]

    useDreadblades: ->
      $("#artifactframe").css("background-image", "url('/images/artifacts/44-small.jpg')")
      lines = [
        {width: 130, left: 27.500, top: 60.325, angle: 144.719, spell1: 202665, spell2: 202463},
        {width: 78, left: 63.472, top: 33.496, angle: 138.122, spell1: 202897, spell2: 202521},
        {width: 124, left: -1.111, top: 82.764, angle: -90.924, spell1: 202820, spell2: 202533},
        {width: 112, left: 63.889, top: 53.171, angle: 106.650, spell1: 202769, spell2: 216230},
        {width: 88, left: 53.194, top: 34.634, angle: 25.688, spell1: 202755, spell2: 202521},
        {width: 77, left: 43.333, top: 32.846, angle: 167.957, spell1: 202755, spell2: 202522},
        {width: 94, left: 46.528, top: 39.024, angle: 96.746, spell1: 202755, spell2: 202907},
        {width: 149, left: 8.472, top: 76.585, angle: -90.385, spell1: 202753, spell2: 202524},
        {width: 176, left: 16.389, top: 80.163, angle: -36.935, spell1: 202753, spell2: 202507},
        {width: 85, left: 60.417, top: 56.098, angle: 57.426, spell1: 202628, spell2: 216230},
        {width: 80, left: 52.083, top: 48.455, angle: -164.055, spell1: 202628, spell2: 202907},
        {width: 122, left: 52.500, top: 61.789, angle: -179.530, spell1: 216230, spell2: 202530},
        {width: 117, left: 37.361, top: 66.667, angle: -30.713, spell1: 202507, spell2: 202530},
        {width: 74, left: 28.611, top: 68.943, angle: -155.171, spell1: 202507, spell2: 202463},
        {width: 122, left: 30.139, top: 42.276, angle: -55.008, spell1: 202514, spell2: 202522},
        {width: 139, left: 16.667, top: 57.398, angle: 141.147, spell1: 202514, spell2: 202524},
        {width: 104, left: 24.167, top: 58.374, angle: 108.435, spell1: 202514, spell2: 202463},
        {width: 96, left: 6.389, top: 68.618, angle: 148.627, spell1: 202524, spell2: 202533},
        {width: 105, left: 68.750, top: 86.504, angle: -135.385, spell1: 238067, spell2: 238103},
        {width: 105, left: 79.167, top: 86.341, angle: -45.385, spell1: 238067, spell2: 241153},
        {width: 105, left: 68.889, top: 74.472, angle: -43.847, spell1: 238103, spell2: 238139},
        {width: 74, left: 76.250, top: 74.634, angle: 90.000, spell1: 238139, spell2: 239042},
      ]

      return Templates.artifact(traits: ArtifactTemplates.getDreadbladesTraits(), lines: lines)

    getFangsTraits: ->
      return [
        {id: "fangs_akaarissoul", spell_id: 209835, max_level: 1, icon: "ability_warlock_soullink", ring: "dragon", left: 58.611, top: 38.699},
        {id: "fangs_catlike", spell_id: 197241, max_level: 3, icon: "inv_pet_cats_calicocat", ring: "thin", left: 42.500, top: 46.992, is_thin: true},
        {id: "fangs_concordance", spell_id: 239042, max_level: 50, icon: "trade_archaeology_shark-jaws", ring: "dragon", left: 75.000, top: 74.146},
        {id: "fangs_demonskiss", spell_id: 197233, max_level: 3, icon: "ability_priest_voidentropy", ring: "thin", left: 25.417, top: 84.715, is_thin: true},
        {id: "fangs_embrace", spell_id: 197604, max_level: 1, icon: "ability_stealth", ring: "thin", left: 52.222, top: 63.902, is_thin: true},
        {id: "fangs_energetic", spell_id: 197239, max_level: 3, icon: "inv_knife_1h_pvppandarias3_c_02", ring: "thin", left: 23.472, top: 68.130, is_thin: true},
        {id: "fangs_etchedinshadow", spell_id: 238068, max_level: 4, icon: "spell_shadow_rune", ring: "thin", left: 74.861, top: 86.016, is_thin: true},
        {id: "fangs_feedingfrenzy", spell_id: 238140, max_level: 1, icon: "inv_knife_1h_artifactfangs_d_01", ring: "dragon", left: 75.000, top: 62.114},
        {id: "fangs_finality", spell_id: 197406, max_level: 1, icon: "ability_rogue_eviscerate", ring: "dragon", left: 11.944, top: 78.049},
        {id: "fangs_flickering", spell_id: 197256, max_level: 1, icon: "ability_rogue_sprint_blue", ring: "thin", left: 39.722, top: 65.041, is_thin: true},
        {id: "fangs_fortunesbite", spell_id: 197369, max_level: 3, icon: "ability_rogue_masterofsubtlety", ring: "thin", left: 62.222, top: 51.382, is_thin: true},
        {id: "fangs_ghostarmor", spell_id: 197244, max_level: 3, icon: "achievement_halloween_ghost_01", ring: "thin", left: 33.194, top: 58.537, is_thin: true},
        {id: "fangs_goremawsbite", spell_id: 209782, max_level: 1, icon: "inv_knife_1h_artifactfangs_d_01", ring: "thick", left: 65.833, top: 14.472},
        {id: "fangs_gutripper", spell_id: 197234, max_level: 3, icon: "ability_rogue_eviscerate", ring: "thin", left: 57.361, top: 23.415, is_thin: true},
        {id: "fangs_legionblade", spell_id: 214930, max_level: 1, icon: "inv_knife_1h_artifactfangs_d_02dual", ring: "dragon", left: 19.444, top: 47.642},
        {id: "fangs_precision", spell_id: 197235, max_level: 3, icon: "ability_rogue_unfairadvantage", ring: "thin", left: 40.278, top: 79.350, is_thin: true},
        {id: "fangs_quietknife", spell_id: 197231, max_level: 3, icon: "ability_backstab", ring: "thin", left: 48.750, top: 53.008, is_thin: true},
        {id: "fangs_second", spell_id: 197610, max_level: 1, icon: "inv_throwingknife_07", ring: "thin", left: 31.528, top: 73.333, is_thin: true},
        {id: "fangs_shadowfangs", spell_id: 221856, max_level: 1, icon: "inv_misc_blacksaberonfang", ring: "thin", left: 70.833, top: 35.610, is_thin: true},
        {id: "fangs_shadownova", spell_id: 209781, max_level: 1, icon: "spell_fire_twilightnova", ring: "dragon", left: 45.556, top: 22.764},
        {id: "fangs_shadows", spell_id: 241154, max_level: 1, icon: "misc_legionfall_rogue", ring: "thick", left: 85.139, top: 73.821},
        {id: "fangs_shadowswhipser", spell_id: 242707, max_level: 1, icon: "ability_rogue_masterofsubtlety", ring: "thin", left: 64.444, top: 73.984, is_thin: true},
        {id: "fangs_soulshadows", spell_id: 197386, max_level: 3, icon: "inv_knife_1h_grimbatolraid_d_03", ring: "thin", left: 44.167, top: 34.959, is_thin: true},
      ]

    useFangs: ->
      $("#artifactframe").css("background-image", "url('/images/artifacts/fangs-bg.jpg')")
      lines = [
        {width: 135, left: 65.278, top: 31.870, angle: 74.521, spell1: 209782, spell2: 221856},
        {width: 113, left: 52.083, top: 52.683, angle: -51.103, spell1: 197231, spell2: 209835},
        {width: 98, left: 43.611, top: 65.854, angle: 131.295, spell1: 197231, spell2: 197256},
        {width: 105, left: 17.639, top: 88.130, angle: -157.087, spell1: 197233, spell2: 197406},
        {width: 112, left: 31.250, top: 88.780, angle: -17.140, spell1: 197233, spell2: 197235},
        {width: 180, left: 43.611, top: 41.951, angle: 126.425, spell1: 197234, spell2: 197241},
        {width: 123, left: 61.806, top: 36.260, angle: 37.711, spell1: 197234, spell2: 221856},
        {width: 73, left: 37.083, top: 83.089, angle: -149.574, spell1: 197235, spell2: 197610},
        {width: 128, left: 43.611, top: 78.374, angle: -47.847, spell1: 197235, spell2: 197604},
        {width: 105, left: 56.250, top: 64.390, angle: 133.078, spell1: 197369, spell2: 197604},
        {width: 115, left: 64.861, top: 50.244, angle: -57.414, spell1: 197369, spell2: 221856},
        {width: 76, left: 45.833, top: 35.610, angle: -82.405, spell1: 197386, spell2: 209781},
        {width: 75, left: 44.444, top: 47.805, angle: 99.211, spell1: 197386, spell2: 197241},
        {width: 103, left: 16.806, top: 79.837, angle: 143.686, spell1: 197239, spell2: 197406},
        {width: 66, left: 29.167, top: 77.561, angle: 28.887, spell1: 197239, spell2: 197610},
        {width: 92, left: 28.194, top: 70.081, angle: -40.126, spell1: 197239, spell2: 197244},
        {width: 98, left: 37.222, top: 59.512, angle: 133.340, spell1: 197241, spell2: 197244},
        {width: 62, left: 38.333, top: 68.618, angle: 40.400, spell1: 197244, spell2: 197256},
        {width: 105, left: 68.611, top: 86.829, angle: -135.385, spell1: 238068, spell2: 242707},
        {width: 105, left: 79.028, top: 86.667, angle: -45.385, spell1: 238068, spell2: 241154},
        {width: 105, left: 68.750, top: 74.797, angle: -43.847, spell1: 242707, spell2: 238140},
        {width: 74, left: 76.111, top: 74.959, angle: 90.000, spell1: 238140, spell2: 239042},
      ]

      return Templates.artifact(traits: ArtifactTemplates.getFangsTraits(), lines: lines)

    getKingslayersTraits: ->
      return [
        {id: "ks_assassinsblades", spell_id: 214368, max_level: 1, icon: "ability_rogue_shadowstrikes", ring: "thin", left: 35.694, top: 32.195, is_thin: true},
        {id: "ks_bagoftricks", spell_id: 192657, max_level: 1, icon: "rogue_paralytic_poison", ring: "dragon", left: 5.556, top: 34.146},
        {id: "ks_balancedblades", spell_id: 192326, max_level: 3, icon: "ability_rogue_restlessblades", ring: "thin", left: 29.583, top: 52.033, is_thin: true},
        {id: "ks_concordance", spell_id: 239042, max_level: 50, icon: "trade_archaeology_shark-jaws", ring: "dragon", left: 75.000, top: 73.659},
        {id: "ks_denseconcoction", spell_id: 238102, max_level: 1, icon: "ability_rogue_crimsonvial", ring: "thin", left: 64.444, top: 73.496, is_thin: true},
        {id: "ks_embrace", spell_id: 192323, max_level: 3, icon: "spell_shadow_nethercloak", ring: "thin", left: 10.694, top: 66.667, is_thin: true},
        {id: "ks_fadeintoshadows", spell_id: 192923, max_level: 1, icon: "inv_artifact_bloodoftheassassinated", ring: "dragon", left: 5.556, top: 82.439},
        {id: "ks_fromtheshadows", spell_id: 192428, max_level: 1, icon: "ability_rogue_deadlybrew", ring: "dragon", left: 54.861, top: 24.553},
        {id: "ks_gushingwound", spell_id: 192329, max_level: 3, icon: "ability_rogue_bloodsplatter", ring: "thin", left: -2.361, top: 67.154, is_thin: true},
        {id: "ks_kingsbane", spell_id: 192759, max_level: 1, icon: "inv_knife_1h_artifactgarona_d_01", ring: "thick", left: 43.056, top: 27.642},
        {id: "ks_masteralchemist", spell_id: 192318, max_level: 3, icon: "trade_brewpoison", ring: "thin", left: -0.556, top: 48.618, is_thin: true},
        {id: "ks_masterassassin", spell_id: 192349, max_level: 3, icon: "ability_rogue_deadliness", ring: "thin", left: 12.222, top: 49.268, is_thin: true},
        {id: "ks_poisonknives", spell_id: 192376, max_level: 3, icon: "ability_rogue_dualweild", ring: "thin", left: 40.278, top: 53.821, is_thin: true},
        {id: "ks_serratededge", spell_id: 192315, max_level: 3, icon: "ability_warrior_bloodbath", ring: "thin", left: 53.611, top: 39.512, is_thin: true},
        {id: "ks_shadowswift", spell_id: 192422, max_level: 1, icon: "rogue_burstofspeed", ring: "thin", left: 19.306, top: 55.122, is_thin: true},
        {id: "ks_shadowwalker", spell_id: 192345, max_level: 3, icon: "ability_rogue_sprint", ring: "thin", left: 13.750, top: 37.561, is_thin: true},
        {id: "ks_silence", spell_id: 241152, max_level: 1, icon: "misc_legionfall_rogue", ring: "thick", left: 85.139, top: 73.333},
        {id: "ks_sinistercirculation", spell_id: 238138, max_level: 1, icon: "inv_knife_1h_artifactgarona_d_01dual", ring: "dragon", left: 75.000, top: 61.789},
        {id: "ks_slayersprecision", spell_id: 214928, max_level: 1, icon: "inv_knife_1h_artifactgarona_d_02dual", ring: "dragon", left: 65.556, top: 19.350},
        {id: "ks_strangler", spell_id: 238066, max_level: 4, icon: "ability_rogue_garrote", ring: "thin", left: 74.861, top: 85.528, is_thin: true},
        {id: "ks_surgeoftoxins", spell_id: 192424, max_level: 1, icon: "ability_rogue_deviouspoisons", ring: "thin", left: 45.694, top: 45.366, is_thin: true},
        {id: "ks_toxicblades", spell_id: 192310, max_level: 3, icon: "ability_rogue_disembowel", ring: "thin", left: 28.750, top: 35.935, is_thin: true},
        {id: "ks_urgetokill", spell_id: 192384, max_level: 1, icon: "ability_rogue_improvedrecuperate", ring: "thin", left: 21.389, top: 38.537, is_thin: true},
      ]

    useKingslayers: ->
      $("#artifactframe").css("background-image", "url('/images/artifacts/kingslayers-bg.jpg')")
      lines = [
        {width: 55, left: 27.500, top: 44.065, angle: 163.202, spell1: 192310, spell2: 192384},
        {width: 99, left: 28.611, top: 50.732, angle: 86.532, spell1: 192310, spell2: 192326},
        {width: 55, left: 34.722, top: 40.813, angle: -24.702, spell1: 192310, spell2: 214368},
        {width: 92, left: 54.028, top: 38.862, angle: -84.413, spell1: 192315, spell2: 192428},
        {width: 67, left: 51.250, top: 49.268, angle: 147.724, spell1: 192315, spell2: 192424},
        {width: 99, left: 1.944, top: 48.130, angle: -63.693, spell1: 192318, spell2: 192657},
        {width: 92, left: 5.694, top: 55.772, angle: 2.490, spell1: 192318, spell2: 192349},
        {width: 115, left: -3.194, top: 64.715, angle: 96.506, spell1: 192318, spell2: 192329},
        {width: 104, left: 7.083, top: 81.301, angle: 110.879, spell1: 192323, spell2: 192923},
        {width: 94, left: 14.722, top: 67.642, angle: -48.871, spell1: 192323, spell2: 192422},
        {width: 76, left: 25.417, top: 60.325, angle: 165.600, spell1: 192326, spell2: 192422},
        {width: 78, left: 35.694, top: 59.675, angle: 8.130, spell1: 192326, spell2: 192376},
        {width: 152, left: 0.556, top: 65.041, angle: -46.332, spell1: 192329, spell2: 192349},
        {width: 110, left: 0.139, top: 81.626, angle: 58.768, spell1: 192329, spell2: 192923},
        {width: 63, left: 11.528, top: 42.602, angle: -160.408, spell1: 192345, spell2: 192657},
        {width: 55, left: 20.000, top: 44.878, angle: 6.226, spell1: 192345, spell2: 192384},
        {width: 62, left: 17.639, top: 59.024, angle: 35.218, spell1: 192349, spell2: 192422},
        {width: 93, left: 16.667, top: 50.732, angle: -45.000, spell1: 192349, spell2: 192384},
        {width: 65, left: 44.722, top: 56.423, angle: -53.130, spell1: 192376, spell2: 192424},
        {width: 137, left: 34.722, top: 49.756, angle: -103.935, spell1: 192376, spell2: 214368},
        {width: 60, left: 41.389, top: 36.748, angle: 152.152, spell1: 192759, spell2: 214368},
        {width: 105, left: 68.611, top: 86.341, angle: -135.385, spell1: 238066, spell2: 238102},
        {width: 105, left: 79.028, top: 86.179, angle: -45.385, spell1: 238066, spell2: 241152},
        {width: 105, left: 68.750, top: 74.472, angle: -43.452, spell1: 238102, spell2: 238138},
        {width: 73, left: 76.250, top: 74.472, angle: 90.000, spell1: 238138, spell2: 239042},
      ]

      return Templates.artifact(traits: ArtifactTemplates.getKingslayersTraits(), lines: lines)

