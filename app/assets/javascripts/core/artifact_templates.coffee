window.ArtifactTemplates = null

ShadowcraftApp.bind "boot", ->
  window.ArtifactTemplates =
    getDreadbladesTraits: ->
      return [
        {id: "db_blackpowder", spell_id: 216230, max_level: 3, icon: "inv_weapon_rifle_01", ring: "thin", left: 65.278, top: 57.561, is_thin: true},
        {id: "db_bladedancer", spell_id: 202507, max_level: 3, icon: "ability_warrior_bladestorm", ring: "thin", left: 34.306, top: 67.154, is_thin: true},
        {id: "db_blademaster", spell_id: 202628, max_level: 1, icon: "ability_warrior_challange", ring: "thin", left: 58.889, top: 45.854, is_thin: true},
        {id: "db_blunderbuss", spell_id: 202897, max_level: 1, icon: "inv_weapon_rifle_01", ring: "dragon", left: 66.667, top: 22.439},
        {id: "db_blurredtime", spell_id: 202769, max_level: 1, icon: "ability_rogue_quickrecovery", ring: "dragon", left: 67.639, top: 37.724},
        {id: "db_bravado", spell_id: 241153, max_level: 1, icon: "misc_legionfall_rogue", ring: "thick", left: 85.278, top: 73.496},
        {id: "db_concordance", spell_id: 239042, max_level: 50, icon: "trade_archaeology_shark-jaws", ring: "dragon", left: 75.139, top: 73.821},
        {id: "db_curse", spell_id: 202665, max_level: 1, icon: "inv_sword_1h_artifactskywall_d_01dual", ring: "thick", left: 37.639, top: 47.480},
        {id: "db_cursededges", spell_id: 202463, max_level: 1, icon: "inv_sword_33", ring: "thin", left: 25.000, top: 62.114, is_thin: true},
        {id: "db_cursedleather", spell_id: 202521, max_level: 3, icon: "spell_rogue_deathfromabove", ring: "thin", left: 60.694, top: 33.333, is_thin: true},
        {id: "db_cursedsteel", spell_id: 214929, max_level: 1, icon: "inv_sword_1h_artifactskywall_d_02dual", ring: "dragon", left: 7.778, top: 25.041},
        {id: "db_deception", spell_id: 202755, max_level: 1, icon: "ability_rogue_disguise", ring: "thin", left: 49.722, top: 27.154, is_thin: true},
        {id: "db_dreadbladesvigor", spell_id: 238103, max_level: 1, icon: "inv_sword_1h_artifactskywall_d_01dual", ring: "thin", left: 66.667, top: 76.098, is_thin: true},
        {id: "db_fatebringer", spell_id: 202524, max_level: 3, icon: "ability_rogue_cuttothechase", ring: "thin", left: 14.583, top: 60.163, is_thin: true},
        {id: "db_fatesthirst", spell_id: 202514, max_level: 3, icon: "ability_rogue_waylay", ring: "thin", left: 29.583, top: 46.016, is_thin: true},
        {id: "db_fortunesboon", spell_id: 202907, max_level: 3, icon: "ability_rogue_surpriseattack2", ring: "thin", left: 48.194, top: 42.276, is_thin: true},
        {id: "db_fortunestrikes", spell_id: 202530, max_level: 3, icon: "ability_rogue_improvedrecuperate", ring: "thin", left: 48.333, top: 57.398, is_thin: true},
        {id: "db_ghostlyshell", spell_id: 202533, max_level: 3, icon: "spell_shadow_nethercloak", ring: "thin", left: 3.194, top: 68.293, is_thin: true},
        {id: "db_greed", spell_id: 202820, max_level: 1, icon: "warrior_skullbanner", ring: "dragon", left: 1.389, top: 86.016},
        {id: "db_gunslinger", spell_id: 202522, max_level: 3, icon: "inv_weapon_rifle_07", ring: "thin", left: 39.306, top: 29.756, is_thin: true},
        {id: "db_hiddenblade", spell_id: 202753, max_level: 1, icon: "ability_ironmaidens_bladerush", ring: "thin", left: 14.722, top: 84.390, is_thin: true},
        {id: "db_loadeddice", spell_id: 238139, max_level: 1, icon: "ability_rogue_rollthebones", ring: "dragon", left: 75.139, top: 61.789},
        {id: "db_sabermetrics", spell_id: 238067, max_level: 4, icon: "ability_rogue_sabreslash", ring: "thin", left: 77.083, top: 88.130, is_thin: true},
      ]

    useDreadblades: ->
      $("#artifactframe").css("background-image", "url('/images/artifacts/44-small.jpg')")
      lines = [
        {width: 128, left: 28.611, top: 61.626, angle: 135.317, spell1: 202665, spell2: 202463},
        {width: 80, left: 64.306, top: 34.634, angle: 122.692, spell1: 202897, spell2: 202521},
        {width: 110, left: 0.833, top: 83.902, angle: -83.199, spell1: 202820, spell2: 202533},
        {width: 123, left: 64.167, top: 54.472, angle: 97.933, spell1: 202769, spell2: 216230},
        {width: 88, left: 55.278, top: 37.073, angle: 25.688, spell1: 202755, spell2: 202521},
        {width: 77, left: 45.417, top: 35.285, angle: 167.957, spell1: 202755, spell2: 202522},
        {width: 94, left: 48.611, top: 41.463, angle: 96.746, spell1: 202755, spell2: 202907},
        {width: 149, left: 10.556, top: 79.024, angle: -90.385, spell1: 202753, spell2: 202524},
        {width: 176, left: 18.472, top: 82.602, angle: -36.935, spell1: 202753, spell2: 202507},
        {width: 85, left: 62.500, top: 58.537, angle: 57.426, spell1: 202628, spell2: 216230},
        {width: 80, left: 54.167, top: 50.894, angle: -164.055, spell1: 202628, spell2: 202907},
        {width: 122, left: 54.583, top: 64.228, angle: -179.530, spell1: 216230, spell2: 202530},
        {width: 117, left: 39.444, top: 69.106, angle: -30.713, spell1: 202507, spell2: 202530},
        {width: 74, left: 30.694, top: 71.382, angle: -155.171, spell1: 202507, spell2: 202463},
        {width: 122, left: 32.222, top: 44.715, angle: -55.008, spell1: 202514, spell2: 202522},
        {width: 139, left: 18.750, top: 59.837, angle: 141.147, spell1: 202514, spell2: 202524},
        {width: 104, left: 26.250, top: 60.813, angle: 108.435, spell1: 202514, spell2: 202463},
        {width: 96, left: 8.472, top: 71.057, angle: 148.627, spell1: 202524, spell2: 202533},
        {width: 105, left: 70.833, top: 88.943, angle: -135.385, spell1: 238067, spell2: 238103},
        {width: 108, left: 79.861, top: 87.642, angle: -56.753, spell1: 238067, spell2: 241153},
        {width: 107, left: 69.722, top: 75.772, angle: -55.271, spell1: 238103, spell2: 238139},
        {width: 74, left: 76.250, top: 74.634, angle: 90.000, spell1: 238139, spell2: 239042},
      ]

      return Templates.artifact(traits: ArtifactTemplates.getDreadbladesTraits(), lines: lines)

    getFangsTraits: ->
      return [
        {id: "fangs_akaarissoul", spell_id: 209835, max_level: 1, icon: "ability_warlock_soullink", ring: "dragon", left: 58.611, top: 43.252},
        {id: "fangs_catlike", spell_id: 197241, max_level: 3, icon: "inv_pet_cats_calicocat", ring: "thin", left: 44.583, top: 53.008, is_thin: true},
        {id: "fangs_concordance", spell_id: 239042, max_level: 50, icon: "trade_archaeology_shark-jaws", ring: "dragon", left: 75.000, top: 75.122},
        {id: "fangs_demonskiss", spell_id: 197233, max_level: 3, icon: "ability_priest_voidentropy", ring: "thin", left: 27.500, top: 86.829, is_thin: true},
        {id: "fangs_embrace", spell_id: 197604, max_level: 1, icon: "ability_stealth", ring: "thin", left: 54.306, top: 68.130, is_thin: true},
        {id: "fangs_energetic", spell_id: 197239, max_level: 3, icon: "inv_knife_1h_pvppandarias3_c_02", ring: "thin", left: 25.556, top: 72.033, is_thin: true},
        {id: "fangs_etchedinshadow", spell_id: 238068, max_level: 4, icon: "spell_shadow_rune", ring: "thin", left: 76.944, top: 88.130, is_thin: true},
        {id: "fangs_feedingfrenzy", spell_id: 238140, max_level: 1, icon: "inv_knife_1h_artifactfangs_d_01", ring: "dragon", left: 75.000, top: 64.390},
        {id: "fangs_finality", spell_id: 197406, max_level: 1, icon: "ability_rogue_eviscerate", ring: "dragon", left: 11.944, top: 78.699},
        {id: "fangs_flickering", spell_id: 197256, max_level: 1, icon: "ability_rogue_sprint_blue", ring: "thin", left: 41.806, top: 69.106, is_thin: true},
        {id: "fangs_fortunesbite", spell_id: 197369, max_level: 3, icon: "ability_rogue_masterofsubtlety", ring: "thin", left: 64.306, top: 56.911, is_thin: true},
        {id: "fangs_ghostarmor", spell_id: 197244, max_level: 3, icon: "achievement_halloween_ghost_01", ring: "thin", left: 35.278, top: 63.252, is_thin: true},
        {id: "fangs_goremawsbite", spell_id: 209782, max_level: 1, icon: "inv_knife_1h_artifactfangs_d_01", ring: "thick", left: 65.833, top: 21.463},
        {id: "fangs_gutripper", spell_id: 197234, max_level: 3, icon: "ability_rogue_eviscerate", ring: "thin", left: 59.444, top: 31.707, is_thin: true},
        {id: "fangs_legionblade", spell_id: 214930, max_level: 1, icon: "inv_knife_1h_artifactfangs_d_02dual", ring: "dragon", left: 19.444, top: 51.382},
        {id: "fangs_precision", spell_id: 197235, max_level: 3, icon: "ability_rogue_unfairadvantage", ring: "thin", left: 42.361, top: 82.114, is_thin: true},
        {id: "fangs_quietknife", spell_id: 197231, max_level: 3, icon: "ability_backstab", ring: "thin", left: 50.833, top: 58.374, is_thin: true},
        {id: "fangs_second", spell_id: 197610, max_level: 1, icon: "inv_throwingknife_07", ring: "thin", left: 33.611, top: 76.585, is_thin: true},
        {id: "fangs_shadowfangs", spell_id: 221856, max_level: 1, icon: "inv_misc_blacksaberonfang", ring: "thin", left: 72.917, top: 42.602, is_thin: true},
        {id: "fangs_shadownova", spell_id: 209781, max_level: 1, icon: "spell_fire_twilightnova", ring: "dragon", left: 45.556, top: 28.943},
        {id: "fangs_shadows", spell_id: 241154, max_level: 1, icon: "misc_legionfall_rogue", ring: "thick", left: 85.139, top: 74.959},
        {id: "fangs_shadowswhipser", spell_id: 242707, max_level: 1, icon: "ability_rogue_masterofsubtlety", ring: "thin", left: 66.528, top: 77.236, is_thin: true},
        {id: "fangs_soulshadows", spell_id: 197386, max_level: 3, icon: "inv_knife_1h_grimbatolraid_d_03", ring: "thin", left: 46.250, top: 42.114, is_thin: true},
      ]

    useFangs: ->
      $("#artifactframe").css("background-image", "url('/images/artifacts/fangs-bg.jpg')")
      lines = [
        {width: 140, left: 65.833, top: 38.862, angle: 68.580, spell1: 209782, spell2: 221856},
        {width: 109, left: 53.472, top: 57.561, angle: -58.946, spell1: 197231, spell2: 209835},
        {width: 93, left: 46.111, top: 70.569, angle: 134.563, spell1: 197231, spell2: 197256},
        {width: 123, left: 17.500, top: 89.593, angle: -155.943, spell1: 197233, spell2: 197406},
        {width: 111, left: 33.472, top: 91.220, angle: -15.164, spell1: 197233, spell2: 197235},
        {width: 169, left: 46.528, top: 49.106, angle: 129.242, spell1: 197234, spell2: 197241},
        {width: 118, left: 64.167, top: 43.902, angle: 34.634, spell1: 197234, spell2: 221856},
        {width: 72, left: 39.167, top: 86.179, angle: -151.645, spell1: 197235, spell2: 197610},
        {width: 122, left: 46.111, top: 81.951, angle: -45.000, spell1: 197235, spell2: 197604},
        {width: 100, left: 58.611, top: 69.268, angle: 136.219, spell1: 197369, spell2: 197604},
        {width: 108, left: 67.361, top: 56.585, angle: -54.834, spell1: 197369, spell2: 221856},
        {width: 81, left: 46.528, top: 42.276, angle: -93.532, spell1: 197386, spell2: 209781},
        {width: 68, left: 46.944, top: 54.309, angle: 100.154, spell1: 197386, spell2: 197241},
        {width: 106, left: 17.639, top: 82.114, angle: 157.297, spell1: 197239, spell2: 197406},
        {width: 64, left: 31.389, top: 81.138, angle: 25.769, spell1: 197239, spell2: 197610},
        {width: 88, left: 30.556, top: 74.472, angle: -37.648, spell1: 197239, spell2: 197244},
        {width: 92, left: 39.722, top: 64.878, angle: 136.762, spell1: 197241, spell2: 197244},
        {width: 59, left: 40.694, top: 73.008, angle: 37.451, spell1: 197244, spell2: 197256},
        {width: 101, left: 70.972, top: 89.431, angle: -138.225, spell1: 238068, spell2: 242707},
        {width: 100, left: 80.278, top: 88.293, angle: -53.931, spell1: 238068, spell2: 241154},
        {width: 100, left: 70.000, top: 77.561, angle: -52.326, spell1: 242707, spell2: 238140},
        {width: 66, left: 76.667, top: 76.585, angle: 90.000, spell1: 238140, spell2: 239042},
      ]
      return Templates.artifact(traits: ArtifactTemplates.getFangsTraits(), lines: lines)

    getKingslayersTraits: ->
      return [
        {id: "ks_assassinsblades", spell_id: 214368, max_level: 1, icon: "ability_rogue_shadowstrikes", ring: "thin", left: 37.778, top: 34.634, is_thin: true},
        {id: "ks_bagoftricks", spell_id: 192657, max_level: 1, icon: "rogue_paralytic_poison", ring: "dragon", left: 5.556, top: 34.146},
        {id: "ks_balancedblades", spell_id: 192326, max_level: 3, icon: "ability_rogue_restlessblades", ring: "thin", left: 31.667, top: 54.472, is_thin: true},
        {id: "ks_concordance", spell_id: 239042, max_level: 50, icon: "trade_archaeology_shark-jaws", ring: "dragon", left: 75.000, top: 73.659},
        {id: "ks_denseconcoction", spell_id: 238102, max_level: 1, icon: "ability_rogue_crimsonvial", ring: "thin", left: 66.528, top: 75.935, is_thin: true},
        {id: "ks_embrace", spell_id: 192323, max_level: 3, icon: "spell_shadow_nethercloak", ring: "thin", left: 12.778, top: 69.106, is_thin: true},
        {id: "ks_fadeintoshadows", spell_id: 192923, max_level: 1, icon: "inv_artifact_bloodoftheassassinated", ring: "dragon", left: 5.556, top: 82.439},
        {id: "ks_fromtheshadows", spell_id: 192428, max_level: 1, icon: "ability_rogue_deadlybrew", ring: "dragon", left: 54.861, top: 24.553},
        {id: "ks_gushingwound", spell_id: 192329, max_level: 3, icon: "ability_rogue_bloodsplatter", ring: "thin", left: -0.278, top: 69.593, is_thin: true},
        {id: "ks_kingsbane", spell_id: 192759, max_level: 1, icon: "inv_knife_1h_artifactgarona_d_01", ring: "thick", left: 43.056, top: 27.642},
        {id: "ks_masteralchemist", spell_id: 192318, max_level: 3, icon: "trade_brewpoison", ring: "thin", left: 1.528, top: 51.057, is_thin: true},
        {id: "ks_masterassassin", spell_id: 192349, max_level: 3, icon: "ability_rogue_deadliness", ring: "thin", left: 14.306, top: 51.707, is_thin: true},
        {id: "ks_poisonknives", spell_id: 192376, max_level: 3, icon: "ability_rogue_dualweild", ring: "thin", left: 42.361, top: 56.260, is_thin: true},
        {id: "ks_serratededge", spell_id: 192315, max_level: 3, icon: "ability_warrior_bloodbath", ring: "thin", left: 55.694, top: 41.951, is_thin: true},
        {id: "ks_shadowswift", spell_id: 192422, max_level: 1, icon: "rogue_burstofspeed", ring: "thin", left: 21.389, top: 57.561, is_thin: true},
        {id: "ks_shadowwalker", spell_id: 192345, max_level: 3, icon: "ability_rogue_sprint", ring: "thin", left: 15.833, top: 40.000, is_thin: true},
        {id: "ks_silence", spell_id: 241152, max_level: 1, icon: "misc_legionfall_rogue", ring: "thick", left: 85.139, top: 73.333},
        {id: "ks_sinistercirculation", spell_id: 238138, max_level: 1, icon: "inv_knife_1h_artifactgarona_d_01dual", ring: "dragon", left: 75.000, top: 61.789},
        {id: "ks_slayersprecision", spell_id: 214928, max_level: 1, icon: "inv_knife_1h_artifactgarona_d_02dual", ring: "dragon", left: 65.556, top: 19.350},
        {id: "ks_strangler", spell_id: 238066, max_level: 4, icon: "ability_rogue_garrote", ring: "thin", left: 76.944, top: 87.967, is_thin: true},
        {id: "ks_surgeoftoxins", spell_id: 192424, max_level: 1, icon: "ability_rogue_deviouspoisons", ring: "thin", left: 47.778, top: 47.805, is_thin: true},
        {id: "ks_toxicblades", spell_id: 192310, max_level: 3, icon: "ability_rogue_disembowel", ring: "thin", left: 30.833, top: 38.374, is_thin: true},
        {id: "ks_urgetokill", spell_id: 192384, max_level: 1, icon: "ability_rogue_improvedrecuperate", ring: "thin", left: 23.472, top: 40.976, is_thin: true},
      ]

    useKingslayers: ->
      $("#artifactframe").css("background-image", "url('/images/artifacts/kingslayers-bg.jpg')")
      lines = [
        {width: 55, left: 29.583, top: 46.504, angle: 163.202, spell1: 192310, spell2: 192384},
        {width: 99, left: 30.694, top: 53.171, angle: 86.532, spell1: 192310, spell2: 192326},
        {width: 55, left: 36.806, top: 43.252, angle: -24.702, spell1: 192310, spell2: 214368},
        {width: 107, left: 54.167, top: 40.000, angle: -93.209, spell1: 192315, spell2: 192428},
        {width: 67, left: 53.333, top: 51.707, angle: 147.724, spell1: 192315, spell2: 192424},
        {width: 108, left: 2.222, top: 49.431, angle: -74.419, spell1: 192318, spell2: 192657},
        {width: 92, left: 7.778, top: 58.211, angle: 2.490, spell1: 192318, spell2: 192349},
        {width: 115, left: -1.111, top: 67.154, angle: 96.506, spell1: 192318, spell2: 192329},
        {width: 97, left: 8.750, top: 82.602, angle: 122.381, spell1: 192323, spell2: 192923},
        {width: 94, left: 16.806, top: 70.081, angle: -48.871, spell1: 192323, spell2: 192422},
        {width: 76, left: 27.500, top: 62.764, angle: 165.600, spell1: 192326, spell2: 192422},
        {width: 78, left: 37.778, top: 62.114, angle: 8.130, spell1: 192326, spell2: 192376},
        {width: 152, left: 2.639, top: 67.480, angle: -46.332, spell1: 192329, spell2: 192349},
        {width: 89, left: 2.778, top: 82.764, angle: 62.003, spell1: 192329, spell2: 192923},
        {width: 82, left: 11.250, top: 43.902, angle: -154.058, spell1: 192345, spell2: 192657},
        {width: 55, left: 22.083, top: 47.317, angle: 6.226, spell1: 192345, spell2: 192384},
        {width: 62, left: 19.722, top: 61.463, angle: 35.218, spell1: 192349, spell2: 192422},
        {width: 93, left: 18.750, top: 53.171, angle: -45.000, spell1: 192349, spell2: 192384},
        {width: 65, left: 46.806, top: 58.862, angle: -53.130, spell1: 192376, spell2: 192424},
        {width: 137, left: 36.806, top: 52.195, angle: -103.935, spell1: 192376, spell2: 214368},
        {width: 57, left: 42.778, top: 37.886, angle: 131.468, spell1: 192759, spell2: 214368},
        {width: 105, left: 70.694, top: 88.780, angle: -135.385, spell1: 238066, spell2: 238102},
        {width: 108, left: 79.722, top: 87.480, angle: -56.753, spell1: 238066, spell2: 241152},
        {width: 106, left: 69.583, top: 75.610, angle: -54.964, spell1: 238102, spell2: 238138},
        {width: 73, left: 76.250, top: 74.472, angle: 90.000, spell1: 238138, spell2: 239042},
      ]

      return Templates.artifact(traits: ArtifactTemplates.getKingslayersTraits(), lines: lines)
