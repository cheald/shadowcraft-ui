window.ArtifactTemplates = null

ShadowcraftApp.bind "boot", ->
  window.ArtifactTemplates =
    getDreadbladesTraits: ->
      return [
        {id: "db_blackpowder", spell_id: 216230, max_level: 3, icon: "inv_weapon_rifle_01", ring: "thin", left: 69.444, top: 62.439, is_thin: true},
        {id: "db_bladedancer", spell_id: 202507, max_level: 3, icon: "ability_warrior_bladestorm", ring: "thin", left: 38.472, top: 72.033, is_thin: true},
        {id: "db_blademaster", spell_id: 202628, max_level: 1, icon: "ability_warrior_challange", ring: "thin", left: 63.056, top: 50.732, is_thin: true},
        {id: "db_blunderbuss", spell_id: 202897, max_level: 1, icon: "inv_weapon_rifle_01", ring: "dragon", left: 72.917, top: 29.756},
        {id: "db_blurredtime", spell_id: 202769, max_level: 1, icon: "ability_rogue_quickrecovery", ring: "dragon", left: 73.889, top: 45.041},
        {id: "db_bravado", spell_id: 241153, max_level: 1, icon: "misc_legionfall_rogue", ring: "thick", left: 91.528, top: 80.813},
        {id: "db_concordance", spell_id: 239042, max_level: 50, icon: "trade_archaeology_shark-jaws", ring: "dragon", left: 81.389, top: 81.138},
        {id: "db_curse", spell_id: 202665, max_level: 1, icon: "inv_sword_1h_artifactskywall_d_01dual", ring: "thick", left: 43.889, top: 54.797},
        {id: "db_cursededges", spell_id: 202463, max_level: 1, icon: "inv_sword_33", ring: "thin", left: 29.167, top: 66.992, is_thin: true},
        {id: "db_cursedleather", spell_id: 202521, max_level: 3, icon: "spell_rogue_deathfromabove", ring: "thin", left: 64.861, top: 38.211, is_thin: true},
        {id: "db_cursedsteel", spell_id: 214929, max_level: 1, icon: "inv_sword_1h_artifactskywall_d_02dual", ring: "dragon", left: 14.028, top: 32.358},
        {id: "db_deception", spell_id: 202755, max_level: 1, icon: "ability_rogue_disguise", ring: "thin", left: 53.889, top: 32.033, is_thin: true},
        {id: "db_dreadbladesvigor", spell_id: 238103, max_level: 1, icon: "inv_sword_1h_artifactskywall_d_01dual", ring: "thin", left: 70.833, top: 80.976, is_thin: true},
        {id: "db_fatebringer", spell_id: 202524, max_level: 3, icon: "ability_rogue_cuttothechase", ring: "thin", left: 18.750, top: 65.041, is_thin: true},
        {id: "db_fatesthirst", spell_id: 202514, max_level: 3, icon: "ability_rogue_waylay", ring: "thin", left: 33.750, top: 50.894, is_thin: true},
        {id: "db_fortunesboon", spell_id: 202907, max_level: 3, icon: "ability_rogue_surpriseattack2", ring: "thin", left: 52.361, top: 47.154, is_thin: true},
        {id: "db_fortunestrikes", spell_id: 202530, max_level: 3, icon: "ability_rogue_improvedrecuperate", ring: "thin", left: 52.500, top: 62.276, is_thin: true},
        {id: "db_ghostlyshell", spell_id: 202533, max_level: 3, icon: "spell_shadow_nethercloak", ring: "thin", left: 7.361, top: 73.171, is_thin: true},
        {id: "db_greed", spell_id: 202820, max_level: 1, icon: "warrior_skullbanner", ring: "dragon", left: 7.639, top: 93.333},
        {id: "db_gunslinger", spell_id: 202522, max_level: 3, icon: "inv_weapon_rifle_07", ring: "thin", left: 43.472, top: 34.634, is_thin: true},
        {id: "db_hiddenblade", spell_id: 202753, max_level: 1, icon: "ability_ironmaidens_bladerush", ring: "thin", left: 18.889, top: 89.268, is_thin: true},
        {id: "db_loadeddice", spell_id: 238139, max_level: 1, icon: "ability_rogue_rollthebones", ring: "dragon", left: 81.389, top: 69.106},
        {id: "db_sabermetrics", spell_id: 238067, max_level: 4, icon: "ability_rogue_sabreslash", ring: "thin", left: 81.250, top: 93.008, is_thin: true},
      ]

    useDreadblades: ->
      $("#artifactframe").css("background-image", "url('/images/artifacts/44-small.jpg')")
      lines = [
        {width: 130, left: 33.750, top: 67.642, angle: 144.719, spell1: 202665, spell2: 202463},
        {width: 78, left: 69.722, top: 40.813, angle: 138.122, spell1: 202897, spell2: 202521},
        {width: 124, left: 5.139, top: 90.081, angle: -90.924, spell1: 202820, spell2: 202533},
        {width: 112, left: 70.139, top: 60.488, angle: 106.650, spell1: 202769, spell2: 216230},
        {width: 88, left: 59.444, top: 41.951, angle: 25.688, spell1: 202755, spell2: 202521},
        {width: 77, left: 49.583, top: 40.163, angle: 167.957, spell1: 202755, spell2: 202522},
        {width: 94, left: 52.778, top: 46.341, angle: 96.746, spell1: 202755, spell2: 202907},
        {width: 149, left: 14.722, top: 83.902, angle: -90.385, spell1: 202753, spell2: 202524},
        {width: 176, left: 22.639, top: 87.480, angle: -36.935, spell1: 202753, spell2: 202507},
        {width: 85, left: 66.667, top: 63.415, angle: 57.426, spell1: 202628, spell2: 216230},
        {width: 80, left: 58.333, top: 55.772, angle: -164.055, spell1: 202628, spell2: 202907},
        {width: 122, left: 58.750, top: 69.106, angle: -179.530, spell1: 216230, spell2: 202530},
        {width: 117, left: 43.611, top: 73.984, angle: -30.713, spell1: 202507, spell2: 202530},
        {width: 74, left: 34.861, top: 76.260, angle: -155.171, spell1: 202507, spell2: 202463},
        {width: 122, left: 36.389, top: 49.593, angle: -55.008, spell1: 202514, spell2: 202522},
        {width: 139, left: 22.917, top: 64.715, angle: 141.147, spell1: 202514, spell2: 202524},
        {width: 104, left: 30.417, top: 65.691, angle: 108.435, spell1: 202514, spell2: 202463},
        {width: 96, left: 12.639, top: 75.935, angle: 148.627, spell1: 202524, spell2: 202533},
        {width: 105, left: 75.000, top: 93.821, angle: -135.385, spell1: 238067, spell2: 238103},
        {width: 105, left: 85.417, top: 93.659, angle: -45.385, spell1: 238067, spell2: 241153},
        {width: 105, left: 75.139, top: 81.789, angle: -43.847, spell1: 238103, spell2: 238139},
        {width: 74, left: 82.500, top: 81.951, angle: 90.000, spell1: 238139, spell2: 239042},
      ]

      return Templates.artifact(traits: ArtifactTemplates.getDreadbladesTraits(), lines: lines)

    getFangsTraits: ->
      return [
        {id: "fangs_akaarissoul", spell_id: 209835, max_level: 1, icon: "ability_warlock_soullink", ring: "dragon", left: 64.861, top: 46.016},
        {id: "fangs_catlike", spell_id: 197241, max_level: 3, icon: "inv_pet_cats_calicocat", ring: "thin", left: 48.750, top: 54.309, is_thin: true},
        {id: "fangs_concordance", spell_id: 239042, max_level: 50, icon: "trade_archaeology_shark-jaws", ring: "dragon", left: 81.250, top: 81.463},
        {id: "fangs_demonskiss", spell_id: 197233, max_level: 3, icon: "ability_priest_voidentropy", ring: "thin", left: 31.667, top: 92.033, is_thin: true},
        {id: "fangs_embrace", spell_id: 197604, max_level: 1, icon: "ability_stealth", ring: "thin", left: 58.472, top: 71.220, is_thin: true},
        {id: "fangs_energetic", spell_id: 197239, max_level: 3, icon: "inv_knife_1h_pvppandarias3_c_02", ring: "thin", left: 29.722, top: 75.447, is_thin: true},
        {id: "fangs_etchedinshadow", spell_id: 238068, max_level: 4, icon: "spell_shadow_rune", ring: "thin", left: 81.111, top: 93.333, is_thin: true},
        {id: "fangs_feedingfrenzy", spell_id: 238140, max_level: 1, icon: "inv_knife_1h_artifactfangs_d_01", ring: "dragon", left: 81.250, top: 69.431},
        {id: "fangs_finality", spell_id: 197406, max_level: 1, icon: "ability_rogue_eviscerate", ring: "dragon", left: 18.194, top: 85.366},
        {id: "fangs_flickering", spell_id: 197256, max_level: 1, icon: "ability_rogue_sprint_blue", ring: "thin", left: 45.972, top: 72.358, is_thin: true},
        {id: "fangs_fortunesbite", spell_id: 197369, max_level: 3, icon: "ability_rogue_masterofsubtlety", ring: "thin", left: 68.472, top: 58.699, is_thin: true},
        {id: "fangs_ghostarmor", spell_id: 197244, max_level: 3, icon: "achievement_halloween_ghost_01", ring: "thin", left: 39.444, top: 65.854, is_thin: true},
        {id: "fangs_goremawsbite", spell_id: 209782, max_level: 1, icon: "inv_knife_1h_artifactfangs_d_01", ring: "thick", left: 72.083, top: 21.789},
        {id: "fangs_gutripper", spell_id: 197234, max_level: 3, icon: "ability_rogue_eviscerate", ring: "thin", left: 63.611, top: 30.732, is_thin: true},
        {id: "fangs_legionblade", spell_id: 214930, max_level: 1, icon: "inv_knife_1h_artifactfangs_d_02dual", ring: "dragon", left: 25.694, top: 54.959},
        {id: "fangs_precision", spell_id: 197235, max_level: 3, icon: "ability_rogue_unfairadvantage", ring: "thin", left: 46.528, top: 86.667, is_thin: true},
        {id: "fangs_quietknife", spell_id: 197231, max_level: 3, icon: "ability_backstab", ring: "thin", left: 55.000, top: 60.325, is_thin: true},
        {id: "fangs_second", spell_id: 197610, max_level: 1, icon: "inv_throwingknife_07", ring: "thin", left: 37.778, top: 80.650, is_thin: true},
        {id: "fangs_shadowfangs", spell_id: 221856, max_level: 1, icon: "inv_misc_blacksaberonfang", ring: "thin", left: 77.083, top: 42.927, is_thin: true},
        {id: "fangs_shadownova", spell_id: 209781, max_level: 1, icon: "spell_fire_twilightnova", ring: "dragon", left: 51.806, top: 30.081},
        {id: "fangs_shadows", spell_id: 241154, max_level: 1, icon: "misc_legionfall_rogue", ring: "thick", left: 91.389, top: 81.138},
        {id: "fangs_shadowswhipser", spell_id: 242707, max_level: 1, icon: "ability_rogue_masterofsubtlety", ring: "thin", left: 70.694, top: 81.301, is_thin: true},
        {id: "fangs_soulshadows", spell_id: 197386, max_level: 3, icon: "inv_knife_1h_grimbatolraid_d_03", ring: "thin", left: 50.417, top: 42.276, is_thin: true},
      ]

    useFangs: ->
      $("#artifactframe").css("background-image", "url('/images/artifacts/fangs-bg.jpg')")
      lines = [
        {width: 135, left: 71.528, top: 39.187, angle: 74.521, spell1: 209782, spell2: 221856},
        {width: 113, left: 58.333, top: 60.000, angle: -51.103, spell1: 197231, spell2: 209835},
        {width: 98, left: 49.861, top: 73.171, angle: 131.295, spell1: 197231, spell2: 197256},
        {width: 105, left: 23.889, top: 95.447, angle: -157.087, spell1: 197233, spell2: 197406},
        {width: 112, left: 37.500, top: 96.098, angle: -17.140, spell1: 197233, spell2: 197235},
        {width: 180, left: 49.861, top: 49.268, angle: 126.425, spell1: 197234, spell2: 197241},
        {width: 123, left: 68.056, top: 43.577, angle: 37.711, spell1: 197234, spell2: 221856},
        {width: 73, left: 43.333, top: 90.407, angle: -149.574, spell1: 197235, spell2: 197610},
        {width: 128, left: 49.861, top: 85.691, angle: -47.847, spell1: 197235, spell2: 197604},
        {width: 105, left: 62.500, top: 71.707, angle: 133.078, spell1: 197369, spell2: 197604},
        {width: 115, left: 71.111, top: 57.561, angle: -57.414, spell1: 197369, spell2: 221856},
        {width: 76, left: 52.083, top: 42.927, angle: -82.405, spell1: 197386, spell2: 209781},
        {width: 75, left: 50.694, top: 55.122, angle: 99.211, spell1: 197386, spell2: 197241},
        {width: 103, left: 23.056, top: 87.154, angle: 143.686, spell1: 197239, spell2: 197406},
        {width: 66, left: 35.417, top: 84.878, angle: 28.887, spell1: 197239, spell2: 197610},
        {width: 92, left: 34.444, top: 77.398, angle: -40.126, spell1: 197239, spell2: 197244},
        {width: 98, left: 43.472, top: 66.829, angle: 133.340, spell1: 197241, spell2: 197244},
        {width: 62, left: 44.583, top: 75.935, angle: 40.400, spell1: 197244, spell2: 197256},
        {width: 105, left: 74.861, top: 94.146, angle: -135.385, spell1: 238068, spell2: 242707},
        {width: 105, left: 85.278, top: 93.984, angle: -45.385, spell1: 238068, spell2: 241154},
        {width: 105, left: 75.000, top: 82.114, angle: -43.847, spell1: 242707, spell2: 238140},
        {width: 74, left: 82.361, top: 82.276, angle: 90.000, spell1: 238140, spell2: 239042},
      ]

      return Templates.artifact(traits: ArtifactTemplates.getFangsTraits(), lines: lines)

    getKingslayersTraits: ->
      return [
        {id: "ks_assassinsblades", spell_id: 214368, max_level: 1, icon: "ability_rogue_shadowstrikes", ring: "thin", left: 41.944, top: 39.512, is_thin: true},
        {id: "ks_bagoftricks", spell_id: 192657, max_level: 1, icon: "rogue_paralytic_poison", ring: "dragon", left: 11.806, top: 41.463},
        {id: "ks_balancedblades", spell_id: 192326, max_level: 3, icon: "ability_rogue_restlessblades", ring: "thin", left: 35.833, top: 59.350, is_thin: true},
        {id: "ks_concordance", spell_id: 239042, max_level: 50, icon: "trade_archaeology_shark-jaws", ring: "dragon", left: 81.250, top: 80.976},
        {id: "ks_denseconcoction", spell_id: 238102, max_level: 1, icon: "ability_rogue_crimsonvial", ring: "thin", left: 70.694, top: 80.813, is_thin: true},
        {id: "ks_embrace", spell_id: 192323, max_level: 3, icon: "spell_shadow_nethercloak", ring: "thin", left: 16.944, top: 73.984, is_thin: true},
        {id: "ks_fadeintoshadows", spell_id: 192923, max_level: 1, icon: "inv_artifact_bloodoftheassassinated", ring: "dragon", left: 11.806, top: 89.756},
        {id: "ks_fromtheshadows", spell_id: 192428, max_level: 1, icon: "ability_rogue_deadlybrew", ring: "dragon", left: 61.111, top: 31.870},
        {id: "ks_gushingwound", spell_id: 192329, max_level: 3, icon: "ability_rogue_bloodsplatter", ring: "thin", left: 3.889, top: 74.472, is_thin: true},
        {id: "ks_kingsbane", spell_id: 192759, max_level: 1, icon: "inv_knife_1h_artifactgarona_d_01", ring: "thick", left: 49.306, top: 34.959},
        {id: "ks_masteralchemist", spell_id: 192318, max_level: 3, icon: "trade_brewpoison", ring: "thin", left: 5.694, top: 55.935, is_thin: true},
        {id: "ks_masterassassin", spell_id: 192349, max_level: 3, icon: "ability_rogue_deadliness", ring: "thin", left: 18.472, top: 56.585, is_thin: true},
        {id: "ks_poisonknives", spell_id: 192376, max_level: 3, icon: "ability_rogue_dualweild", ring: "thin", left: 46.528, top: 61.138, is_thin: true},
        {id: "ks_serratededge", spell_id: 192315, max_level: 3, icon: "ability_warrior_bloodbath", ring: "thin", left: 59.861, top: 46.829, is_thin: true},
        {id: "ks_shadowswift", spell_id: 192422, max_level: 1, icon: "rogue_burstofspeed", ring: "thin", left: 25.556, top: 62.439, is_thin: true},
        {id: "ks_shadowwalker", spell_id: 192345, max_level: 3, icon: "ability_rogue_sprint", ring: "thin", left: 20.000, top: 44.878, is_thin: true},
        {id: "ks_silence", spell_id: 241152, max_level: 1, icon: "misc_legionfall_rogue", ring: "thick", left: 91.389, top: 80.650},
        {id: "ks_sinistercirculation", spell_id: 238138, max_level: 1, icon: "inv_knife_1h_artifactgarona_d_01dual", ring: "dragon", left: 81.250, top: 69.106},
        {id: "ks_slayersprecision", spell_id: 214928, max_level: 1, icon: "inv_knife_1h_artifactgarona_d_02dual", ring: "dragon", left: 71.806, top: 26.667},
        {id: "ks_strangler", spell_id: 238066, max_level: 4, icon: "ability_rogue_garrote", ring: "thin", left: 81.111, top: 92.846, is_thin: true},
        {id: "ks_surgeoftoxins", spell_id: 192424, max_level: 1, icon: "ability_rogue_deviouspoisons", ring: "thin", left: 51.944, top: 52.683, is_thin: true},
        {id: "ks_toxicblades", spell_id: 192310, max_level: 3, icon: "ability_rogue_disembowel", ring: "thin", left: 35.000, top: 43.252, is_thin: true},
        {id: "ks_urgetokill", spell_id: 192384, max_level: 1, icon: "ability_rogue_improvedrecuperate", ring: "thin", left: 27.639, top: 45.854, is_thin: true},
      ]

    useKingslayers: ->
      $("#artifactframe").css("background-image", "url('/images/artifacts/kingslayers-bg.jpg')")
      lines = [
        {width: 55, left: 33.750, top: 51.382, angle: 163.202, spell1: 192310, spell2: 192384},
        {width: 99, left: 34.861, top: 58.049, angle: 86.532, spell1: 192310, spell2: 192326},
        {width: 55, left: 40.972, top: 48.130, angle: -24.702, spell1: 192310, spell2: 214368},
        {width: 92, left: 60.278, top: 46.179, angle: -84.413, spell1: 192315, spell2: 192428},
        {width: 67, left: 57.500, top: 56.585, angle: 147.724, spell1: 192315, spell2: 192424},
        {width: 99, left: 8.194, top: 55.447, angle: -63.693, spell1: 192318, spell2: 192657},
        {width: 92, left: 11.944, top: 63.089, angle: 2.490, spell1: 192318, spell2: 192349},
        {width: 115, left: 3.056, top: 72.033, angle: 96.506, spell1: 192318, spell2: 192329},
        {width: 104, left: 13.333, top: 88.618, angle: 110.879, spell1: 192323, spell2: 192923},
        {width: 94, left: 20.972, top: 74.959, angle: -48.871, spell1: 192323, spell2: 192422},
        {width: 76, left: 31.667, top: 67.642, angle: 165.600, spell1: 192326, spell2: 192422},
        {width: 78, left: 41.944, top: 66.992, angle: 8.130, spell1: 192326, spell2: 192376},
        {width: 152, left: 6.806, top: 72.358, angle: -46.332, spell1: 192329, spell2: 192349},
        {width: 110, left: 6.389, top: 88.943, angle: 58.768, spell1: 192329, spell2: 192923},
        {width: 63, left: 17.778, top: 49.919, angle: -160.408, spell1: 192345, spell2: 192657},
        {width: 55, left: 26.250, top: 52.195, angle: 6.226, spell1: 192345, spell2: 192384},
        {width: 62, left: 23.889, top: 66.341, angle: 35.218, spell1: 192349, spell2: 192422},
        {width: 93, left: 22.917, top: 58.049, angle: -45.000, spell1: 192349, spell2: 192384},
        {width: 65, left: 50.972, top: 63.740, angle: -53.130, spell1: 192376, spell2: 192424},
        {width: 137, left: 40.972, top: 57.073, angle: -103.935, spell1: 192376, spell2: 214368},
        {width: 60, left: 47.639, top: 44.065, angle: 152.152, spell1: 192759, spell2: 214368},
        {width: 105, left: 74.861, top: 93.659, angle: -135.385, spell1: 238066, spell2: 238102},
        {width: 105, left: 85.278, top: 93.496, angle: -45.385, spell1: 238066, spell2: 241152},
        {width: 105, left: 75.000, top: 81.789, angle: -43.452, spell1: 238102, spell2: 238138},
        {width: 73, left: 82.500, top: 81.789, angle: 90.000, spell1: 238138, spell2: 239042},
      ]

      return Templates.artifact(traits: ArtifactTemplates.getKingslayersTraits(), lines: lines)

