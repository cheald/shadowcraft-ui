window.ArtifactTemplates = null
ShadowcraftApp.bind "boot", ->
  window.ArtifactTemplates =
    useDreadblades: ->
      $("#artifactframe").css("background-image", "url('/images/artifacts/44-small.jpg')")
      traits = [
        {id: "db_blackpowder", spell_id: 216230, max_level: 3, icon: "inv_weapon_rifle_01", ring: "thin", left: 82.317, top: 57.571, is_thin: true},
        {id: "db_bladedancer", spell_id: 202507, max_level: 3, icon: "ability_warrior_bladestorm", ring: "thin", left: 43.659, top: 67.143, is_thin: true},
        {id: "db_blademaster", spell_id: 202628, max_level: 1, icon: "ability_warrior_challange", ring: "thin", left: 74.268, top: 45.714, is_thin: true},
        {id: "db_blunderbuss", spell_id: 202897, max_level: 1, icon: "inv_weapon_rifle_01", ring: "dragon", left: 84.512, top: 22.429},
        {id: "db_blurredtime", spell_id: 202769, max_level: 1, icon: "ability_rogue_quickrecovery", ring: "dragon", left: 85.610, top: 37.714},
        {id: "db_curse", spell_id: 202665, max_level: 1, icon: "inv_sword_1h_artifactskywall_d_01dual", ring: "thick", left: 48.293, top: 47.429},
        {id: "db_cursededges", spell_id: 202463, max_level: 1, icon: "inv_sword_33", ring: "thin", left: 32.195, top: 62.000, is_thin: true},
        {id: "db_cursedleather", spell_id: 202521, max_level: 3, icon: "spell_rogue_deathfromabove", ring: "thin", left: 76.463, top: 33.286, is_thin: true},
        {id: "db_deception", spell_id: 202755, max_level: 1, icon: "ability_rogue_disguise", ring: "thin", left: 62.927, top: 27.143, is_thin: true},
        {id: "db_fatebringer", spell_id: 202524, max_level: 3, icon: "ability_rogue_cuttothechase", ring: "thin", left: 19.268, top: 60.286, is_thin: true},
        {id: "db_fatesthirst", spell_id: 202514, max_level: 3, icon: "ability_rogue_waylay", ring: "thin", left: 37.805, top: 46.000, is_thin: true},
        {id: "db_fortunesboon", spell_id: 202907, max_level: 3, icon: "ability_rogue_surpriseattack2", ring: "thin", left: 61.098, top: 42.286, is_thin: true},
        {id: "db_fortunestrikes", spell_id: 202530, max_level: 3, icon: "ability_rogue_improvedrecuperate", ring: "thin", left: 61.098, top: 57.429, is_thin: true},
        {id: "db_ghostlyshell", spell_id: 202533, max_level: 3, icon: "spell_shadow_nethercloak", ring: "thin", left: 5.000, top: 68.286, is_thin: true},
        {id: "db_greed", spell_id: 202820, max_level: 1, icon: "warrior_skullbanner", ring: "dragon", left: 3.171, top: 86.000},
        {id: "db_gunslinger", spell_id: 202522, max_level: 3, icon: "inv_weapon_rifle_07", ring: "thin", left: 49.878, top: 29.714, is_thin: true},
        {id: "db_hiddenblade", spell_id: 202753, max_level: 1, icon: "ability_ironmaidens_bladerush", ring: "thin", left: 19.390, top: 84.429, is_thin: true},
      ]
      lines = [
        {width: 167, left: 35.610, top: 60.714, angle: 142.306, spell1: 202665, spell2: 202463},
        {width: 101, left: 79.878, top: 33.857, angle: 130.972, spell1: 202897, spell2: 202521},
        {width: 125, left: 1.951, top: 83.143, angle: -83.103, spell1: 202820, spell2: 202533},
        {width: 142, left: 80.732, top: 53.571, angle: 100.993, spell1: 202769, spell2: 216230},
        {width: 119, left: 67.927, top: 36.143, angle: 21.176, spell1: 202755, spell2: 202521},
        {width: 109, left: 55.244, top: 34.429, angle: 170.451, spell1: 202755, spell2: 202522},
        {width: 107, left: 60.976, top: 40.714, angle: 98.054, spell1: 202755, spell2: 202907},
        {width: 169, left: 14.512, top: 78.286, angle: -90.339, spell1: 202753, spell2: 202524},
        {width: 233, left: 22.805, top: 81.714, angle: -31.301, spell1: 202753, spell2: 202507},
        {width: 106, left: 77.317, top: 57.571, angle: 51.509, spell1: 202628, spell2: 216230},
        {width: 111, left: 66.463, top: 50.000, angle: -167.471, spell1: 202628, spell2: 202907},
        {width: 174, left: 66.585, top: 63.429, angle: -179.671, spell1: 216230, spell2: 202530},
        {width: 158, left: 48.171, top: 68.286, angle: -25.432, spell1: 202507, spell2: 202530},
        {width: 101, left: 37.317, top: 70.571, angle: -159.044, spell1: 202507, spell2: 202463},
        {width: 151, left: 40.122, top: 43.857, angle: -49.028, spell1: 202514, spell2: 202522},
        {width: 182, left: 22.927, top: 59.143, angle: 146.659, spell1: 202514, spell2: 202524},
        {width: 121, left: 33.171, top: 60.000, angle: 112.329, spell1: 202514, spell2: 202463},
        {width: 130, left: 9.634, top: 70.286, angle: 154.423, spell1: 202524, spell2: 202533},
      ]

      return Templates.artifact(traits: traits, lines: lines, relic1: 'blood', relic2: 'iron', relic3: 'storm')

    useFangs: ->
      $("#artifactframe").css("background-image", "url('/images/artifacts/fangs-bg.jpg')")
      traits = [
        {id: "fangs_akaarissoul", spell_id: 209835, max_level: 1, icon: "ability_warlock_soullink", ring: "dragon", left: 74.306, top: 43.252},
        {id: "fangs_catwalk", spell_id: 197241, max_level: 3, icon: "inv_pet_cats_calicocat", ring: "thin", left: 52.639, top: 48.455, is_thin: true},
        {id: "fangs_demonskiss", spell_id: 197233, max_level: 3, icon: "ability_priest_voidentropy", ring: "thin", left: 35.278, top: 86.829, is_thin: true},
        {id: "fangs_embrace", spell_id: 197604, max_level: 1, icon: "ability_stealth", ring: "thin", left: 68.611, top: 68.130, is_thin: true},
        {id: "fangs_energetic", spell_id: 197239, max_level: 3, icon: "inv_knife_1h_pvppandarias3_c_02", ring: "thin", left: 32.917, top: 72.033, is_thin: true},
        {id: "fangs_faster", spell_id: 197256, max_level: 1, icon: "ability_rogue_sprint_blue", ring: "thin", left: 51.806, top: 68.943, is_thin: true},
        {id: "fangs_finality", spell_id: 197406, max_level: 1, icon: "ability_rogue_eviscerate", ring: "dragon", left: 16.250, top: 78.699},
        {id: "fangs_fortunesbite", spell_id: 197369, max_level: 3, icon: "ability_rogue_masterofsubtlety", ring: "thin", left: 80.972, top: 56.911, is_thin: true},
        {id: "fangs_ghostarmor", spell_id: 197244, max_level: 3, icon: "achievement_halloween_ghost_01", ring: "thin", left: 42.778, top: 62.114, is_thin: true},
        {id: "fangs_goremawsbite", spell_id: 209782, max_level: 1, icon: "inv_knife_1h_artifactfangs_d_01", ring: "thick", left: 83.472, top: 21.463},
        {id: "fangs_gutripper", spell_id: 197234, max_level: 3, icon: "ability_rogue_eviscerate", ring: "thin", left: 75.000, top: 31.707, is_thin: true},
        {id: "fangs_precision", spell_id: 197235, max_level: 3, icon: "ability_rogue_unfairadvantage", ring: "thin", left: 53.750, top: 82.114, is_thin: true},
        {id: "fangs_quietknife", spell_id: 197231, max_level: 3, icon: "ability_backstab", ring: "thin", left: 64.306, top: 58.374, is_thin: true},
        {id: "fangs_second", spell_id: 197610, max_level: 1, icon: "inv_throwingknife_07", ring: "thin", left: 42.778, top: 76.585, is_thin: true},
        {id: "fangs_shadowfangs", spell_id: 221856, max_level: 1, icon: "inv_misc_blacksaberonfang", ring: "thin", left: 91.667, top: 42.602, is_thin: true},
        {id: "fangs_shadownova", spell_id: 209781, max_level: 1, icon: "spell_fire_twilightnova", ring: "dragon", left: 63.611, top: 20.000},
        {id: "fangs_soulshadows", spell_id: 197386, max_level: 3, icon: "inv_knife_1h_grimbatolraid_d_03", ring: "thin", left: 61.944, top: 33.821, is_thin: true},
      ]
      lines = [
        {width: 143, left: 83.889, top: 38.862, angle: 65.589, spell1: 209782, spell2: 221856},
        {width: 118, left: 67.361, top: 57.561, angle: -52.253, spell1: 197231, spell2: 209835},
        {width: 111, left: 56.667, top: 70.407, angle: 144.162, spell1: 197231, spell2: 197256},
        {width: 146, left: 21.806, top: 89.593, angle: -159.950, spell1: 197233, spell2: 197406},
        {width: 136, left: 41.250, top: 91.220, angle: -12.301, spell1: 197233, spell2: 197235},
        {width: 191, left: 56.806, top: 46.829, angle: 147.391, spell1: 197234, spell2: 197241},
        {width: 137, left: 80.139, top: 43.902, angle: 29.176, spell1: 197234, spell2: 221856},
        {width: 86, left: 48.472, top: 86.179, angle: -156.714, spell1: 197235, spell2: 197610},
        {width: 137, left: 57.917, top: 81.951, angle: -38.790, spell1: 197235, spell2: 197604},
        {width: 113, left: 73.194, top: 69.268, angle: 142.214, spell1: 197369, spell2: 197604},
        {width: 117, left: 84.444, top: 56.585, angle: -48.814, spell1: 197369, spell2: 221856},
        {width: 86, left: 63.056, top: 33.659, angle: -81.964, spell1: 197386, spell2: 209781},
        {width: 112, left: 55.694, top: 47.967, angle: 126.666, spell1: 197386, spell2: 197241},
        {width: 127, left: 22.083, top: 82.114, angle: 161.136, spell1: 197239, spell2: 197406},
        {width: 76, left: 38.750, top: 81.138, angle: 21.523, spell1: 197239, spell2: 197610},
        {width: 94, left: 37.500, top: 73.821, angle: -40.668, spell1: 197239, spell2: 197244},
        {width: 110, left: 46.250, top: 62.114, angle: 130.206, spell1: 197241, spell2: 197244},
        {width: 77, left: 48.194, top: 72.358, angle: 32.869, spell1: 197244, spell2: 197256},
      ]

      return Templates.artifact(traits: traits, lines: lines, relic1: 'fel', relic2: 'shadow', relic3: 'fel')

    useKingslayers: ->
      $("#artifactframe").css("background-image", "url('/images/artifacts/kingslayers-bg.jpg')")
      traits = [
        {id: "ks_assassinsblades", spell_id: 214368, max_level: 1, icon: "ability_rogue_shadowstrikes", ring: "thin", left: 47.917, top: 34.634, is_thin: true},
        {id: "ks_bagoftricks", spell_id: 192657, max_level: 1, icon: "rogue_paralytic_poison", ring: "dragon", left: 8.472, top: 34.146},
        {id: "ks_balancedblades", spell_id: 192326, max_level: 3, icon: "ability_rogue_restlessblades", ring: "thin", left: 40.556, top: 54.472, is_thin: true},
        {id: "ks_blood", spell_id: 192923, max_level: 1, icon: "inv_artifact_bloodoftheassassinated", ring: "dragon", left: 8.472, top: 82.439},
        {id: "ks_embrace", spell_id: 192323, max_level: 3, icon: "spell_shadow_nethercloak", ring: "thin", left: 16.944, top: 69.106, is_thin: true},
        {id: "ks_fromtheshadows", spell_id: 192428, max_level: 1, icon: "ability_rogue_deadlybrew", ring: "dragon", left: 69.861, top: 24.553},
        {id: "ks_graspofguldan", spell_id: 192759, max_level: 1, icon: "ability_rogue_focusedattacks", ring: "thick", left: 55.139, top: 27.642},
        {id: "ks_gushingwound", spell_id: 192329, max_level: 3, icon: "ability_rogue_bloodsplatter", ring: "thin", left: 0.694, top: 69.593, is_thin: true},
        {id: "ks_masteralchemist", spell_id: 192318, max_level: 3, icon: "trade_brewpoison", ring: "thin", left: 2.917, top: 51.057, is_thin: true},
        {id: "ks_masterassassin", spell_id: 192349, max_level: 3, icon: "ability_rogue_deadliness", ring: "thin", left: 18.889, top: 51.707, is_thin: true},
        {id: "ks_poisonknives", spell_id: 192376, max_level: 3, icon: "ability_rogue_dualweild", ring: "thin", left: 53.750, top: 56.260, is_thin: true},
        {id: "ks_serratededge", spell_id: 192315, max_level: 3, icon: "ability_warrior_bloodbath", ring: "thin", left: 70.417, top: 41.951, is_thin: true},
        {id: "ks_shadowswift", spell_id: 192422, max_level: 1, icon: "rogue_burstofspeed", ring: "thin", left: 27.639, top: 57.561, is_thin: true},
        {id: "ks_shadowwalker", spell_id: 192345, max_level: 3, icon: "ability_rogue_sprint", ring: "thin", left: 20.833, top: 40.000, is_thin: true},
        {id: "ks_surgeoftoxins", spell_id: 192424, max_level: 1, icon: "ability_rogue_deviouspoisons", ring: "thin", left: 60.556, top: 47.805, is_thin: true},
        {id: "ks_toxicblades", spell_id: 192310, max_level: 3, icon: "ability_rogue_disembowel", ring: "thin", left: 39.444, top: 38.374, is_thin: true},
        {id: "ks_urgetokill", spell_id: 192384, max_level: 1, icon: "ability_rogue_improvedrecuperate", ring: "thin", left: 30.278, top: 40.976, is_thin: true},
      ]
      lines = [
        {width: 68, left: 36.389, top: 46.504, angle: 166.373, spell1: 192310, spell2: 192384},
        {width: 99, left: 39.444, top: 53.171, angle: 85.380, spell1: 192310, spell2: 192326},
        {width: 65, left: 45.417, top: 43.252, angle: -20.659, spell1: 192310, spell2: 214368},
        {width: 107, left: 69.028, top: 40.000, angle: -92.141, spell1: 192315, spell2: 192428},
        {width: 80, left: 66.111, top: 51.707, angle: 153.113, spell1: 192315, spell2: 192424},
        {width: 111, left: 4.306, top: 49.431, angle: -68.962, spell1: 192318, spell2: 192657},
        {width: 115, left: 9.167, top: 58.211, angle: 1.992, spell1: 192318, spell2: 192349},
        {width: 115, left: 0.139, top: 67.154, angle: 97.989, spell1: 192318, spell2: 192329},
        {width: 102, left: 11.806, top: 82.602, angle: 126.646, spell1: 192323, spell2: 192923},
        {width: 105, left: 21.250, top: 70.081, angle: -42.678, spell1: 192323, spell2: 192422},
        {width: 95, left: 33.750, top: 62.764, angle: 168.453, spell1: 192326, spell2: 192422},
        {width: 96, left: 46.667, top: 62.114, angle: 6.605, spell1: 192326, spell2: 192376},
        {width: 171, left: 4.167, top: 67.480, angle: -40.020, spell1: 192329, spell2: 192349},
        {width: 97, left: 4.167, top: 82.764, angle: 54.669, spell1: 192329, spell2: 192923},
        {width: 96, left: 14.167, top: 43.902, angle: -157.977, spell1: 192345, spell2: 192657},
        {width: 68, left: 27.083, top: 47.317, angle: 5.042, spell1: 192345, spell2: 192384},
        {width: 73, left: 24.444, top: 61.463, angle: 29.745, spell1: 192349, spell2: 192422},
        {width: 105, left: 23.611, top: 53.171, angle: -38.830, spell1: 192349, spell2: 192384},
        {width: 71, left: 58.472, top: 58.862, angle: -46.701, spell1: 192376, spell2: 192424},
        {width: 139, left: 47.500, top: 52.195, angle: -107.526, spell1: 192376, spell2: 214368},
        {width: 67, left: 53.194, top: 37.886, angle: 140.412, spell1: 192759, spell2: 214368},
      ]

      return Templates.artifact(traits: traits, lines: lines, relic1: 'shadow', relic2: 'iron', relic3: 'blood')

