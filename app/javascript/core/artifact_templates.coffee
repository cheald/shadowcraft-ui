ArtifactTemplates = null
ShadowcraftApp.bind "boot", ->
  ArtifactTemplates = 
    useDreadblades: ->
      $("#artifactframe").css("background-image", "url('/images/artifacts/44-small.jpg')")
      traits = [
        {id: "db_bladedancer", spell_id: 202507, max_level: 3, icon: "ability_warrior_bladestorm", ring: "thin", left: 15.244, top: 44.143, is_thin: true},
        {id: "db_blademaster", spell_id: 202628, max_level: 1, icon: "ability_warrior_challange", ring: "thin", left: 7.073, top: 81.571, is_thin: true},
        {id: "db_blunderbuss", spell_id: 202897, max_level: 1, icon: "inv_weapon_rifle_01", ring: "dragon", left: 19.634, top: 69.143},
        {id: "db_blurredtime", spell_id: 202769, max_level: 1, icon: "ability_rogue_quickrecovery", ring: "dragon", left: 30.854, top: 35.857},
        {id: "db_curse", spell_id: 202665, max_level: 1, icon: "inv_sword_1h_artifactskywall_d_01dual", ring: "thick", left: 56.463, top: 45.714},
        {id: "db_cursededges", spell_id: 202463, max_level: 3, icon: "inv_sword_33", ring: "thin", left: 46.585, top: 55.286, is_thin: true},
        {id: "db_cursedleather", spell_id: 202521, max_level: 3, icon: "ability_rogue_masterofsubtlety", ring: "thin", left: 57.317, top: 29.714, is_thin: true},
        {id: "db_deception", spell_id: 202755, max_level: 1, icon: "ability_rogue_disguise", ring: "thin", left: 57.195, top: 16.429, is_thin: true},
        {id: "db_fatebringer", spell_id: 202524, max_level: 3, icon: "ability_rogue_cuttothechase", ring: "thin", left: -1.220, top: 53.143, is_thin: true},
        {id: "db_fatesthirst", spell_id: 202514, max_level: 3, icon: "ability_rogue_waylay", ring: "thin", left: 66.707, top: 38.000, is_thin: true},
        {id: "db_fortunesboon", spell_id: 202907, max_level: 3, icon: "ability_rogue_surpriseattack2", ring: "thin", left: 71.341, top: 22.857, is_thin: true},
        {id: "db_fortunestrikes", spell_id: 202530, max_level: 3, icon: "ability_rogue_improvedrecuperate", ring: "thin", left: 33.293, top: 51.286, is_thin: true},
        {id: "db_ghostlyshell", spell_id: 202533, max_level: 3, icon: "spell_shadow_nethercloak", ring: "thin", left: 44.634, top: 27.857, is_thin: true},
        {id: "db_greed", spell_id: 202820, max_level: 1, icon: "warrior_skullbanner", ring: "dragon", left: 69.512, top: 4.286},
        {id: "db_gunslinger", spell_id: 202522, max_level: 3, icon: "inv_weapon_rifle_07", ring: "thin", left: 28.049, top: 87.000, is_thin: true},
        {id: "db_hiddenblade", spell_id: 202753, max_level: 1, icon: "ability_ironmaidens_bladerush", ring: "thin", left: 89.634, top: 25.000, is_thin: true}
      ]
      lines = [
        {width: 112, left: 55.487804878, top: 43.7142857143, angle: -86.423665625, spell1: 202665, spell2: 202521},
        {width: 105, left: 50.6097560976, top: 56.4285714286, angle: 140.40379136, spell1: 202665, spell2: 202463},
        {width: 204, left: 2.19512195122, top: 67.1428571429, angle: -146.776373563, spell1: 202897, spell2: 202524},
        {width: 135, left: 10.6097560976, top: 81.2857142857, angle: 139.813550894, spell1: 202897, spell2: 202628},
        {width: 143, left: 20.6097560976, top: 84.0, angle: 61.1013023992, spell1: 202897, spell2: 202522},
        {width: 126, left: 35.487804878, top: 37.8571428571, angle: -26.3618755056, spell1: 202769, spell2: 202533},
        {width: 141, left: 20.0, top: 46.0, angle: 155.623531383, spell1: 202769, spell2: 202507},
        {width: 132, left: 60.7317073171, top: 16.2857142857, angle: 139.916566006, spell1: 202820, spell2: 202755},
        {width: 220, left: 71.5853658537, top: 20.5714285714, angle: 41.3086140135, spell1: 202820, spell2: 202753},
        {width: 149, left: 3.41463414634, top: 54.5714285714, angle: 154.983106522, spell1: 202507, spell2: 202524},
        {width: 156, left: 20.243902439, top: 53.7142857143, angle: 18.6669142742, spell1: 202507, spell2: 202530},
        {width: 210, left: -4.39024390244, top: 73.2857142857, angle: -108.86573604, spell1: 202628, spell2: 202524},
        {width: 176, left: 12.3170731707, top: 90.2857142857, angle: 12.45824644, spell1: 202628, spell2: 202522},
        {width: 113, left: 38.5365853659, top: 59.2857142857, angle: -165.593314844, spell1: 202463, spell2: 202530},
        {width: 96, left: 61.5853658537, top: 39.8571428571, angle: 36.9887683871, spell1: 202521, spell2: 202514},
        {width: 130, left: 48.4146341463, top: 28.1428571429, angle: 142.163547466, spell1: 202755, spell2: 202533},
        {width: 113, left: 67.6829268293, top: 36.4285714286, angle: -70.2777222356, spell1: 202514, spell2: 202907},
        {width: 189, left: 32.9268292683, top: 45.5714285714, angle: -60.4435909822, spell1: 202530, spell2: 202533},
        {width: 254, left: 20.6097560976, top: 75.1428571429, angle: 99.7593812677, spell1: 202530, spell2: 202522},
        {width: 131, left: 67.9268292683, top: 19.5714285714, angle: -96.5819446552, spell1: 202907, spell2: 202820},
        {width: 151, left: 76.8292682927, top: 29.8571428571, angle: 5.7105931375, spell1: 202907, spell2: 202753}
      ]

      return Templates.artifact(traits: traits, lines: lines, relic1: 'blood', relic2: 'iron', relic3: 'wind')

    useFangs: ->
      $("#artifactframe").css("background-image", "url('/images/artifacts/fangs-bg.jpg')")
      traits = [
        {id: "fangs_akaarissoul", spell_id: 209835, max_level: 1, icon: "ability_warlock_soullink", ring: "dragon", left: 72.222, top: 41.626},
        {id: "fangs_catwalk", spell_id: 197241, max_level: 3, icon: "ability_rogue_fleetfooted", ring: "thin", left: 50.694, top: 46.016, is_thin: true},
        {id: "fangs_demonskiss", spell_id: 197233, max_level: 3, icon: "ability_priest_voidentropy", ring: "thin", left: 32.917, top: 84.553, is_thin: true},
        {id: "fangs_embrace", spell_id: 197604, max_level: 1, icon: "ability_rogue_eviscerate", ring: "thin", left: 66.806, top: 66.016, is_thin: true},
        {id: "fangs_energetic", spell_id: 197239, max_level: 3, icon: "inv_knife_1h_pvppandarias3_c_02", ring: "thin", left: 30.694, top: 69.593, is_thin: true},
        {id: "fangs_faster", spell_id: 197256, max_level: 1, icon: "ability_rogue_sprint_blue", ring: "thin", left: 49.583, top: 66.667, is_thin: true},
        {id: "fangs_finality", spell_id: 197406, max_level: 1, icon: "ability_rogue_eviscerate", ring: "dragon", left: 16.250, top: 78.211},
        {id: "fangs_fortunesbite", spell_id: 197369, max_level: 3, icon: "ability_rogue_masterofsubtlety", ring: "thin", left: 77.361, top: 53.008, is_thin: true},
        {id: "fangs_ghostarmor", spell_id: 197244, max_level: 3, icon: "achievement_halloween_ghost_01", ring: "thin", left: 40.694, top: 59.837, is_thin: true},
        {id: "fangs_goremawsbite", spell_id: 209782, max_level: 1, icon: "inv_knife_1h_artifactfangs_d_01", ring: "thick", left: 85.694, top: 40.976},
        {id: "fangs_gutripper", spell_id: 197234, max_level: 3, icon: "ability_rogue_eviscerate", ring: "thin", left: 72.222, top: 28.943, is_thin: true},
        {id: "fangs_precision", spell_id: 197235, max_level: 3, icon: "ability_rogue_unfairadvantage", ring: "thin", left: 51.667, top: 79.837, is_thin: true},
        {id: "fangs_quietknife", spell_id: 197231, max_level: 3, icon: "ability_backstab", ring: "thin", left: 61.667, top: 54.472, is_thin: true},
        {id: "fangs_second", spell_id: 197610, max_level: 1, icon: "inv_throwingknife_07", ring: "thin", left: 40.833, top: 74.309, is_thin: true},
        {id: "fangs_shadownova", spell_id: 209781, max_level: 1, icon: "spell_fire_twilightnova", ring: "dragon", left: 59.444, top: 18.374},
        {id: "fangs_soulshadows", spell_id: 197386, max_level: 3, icon: "inv_knife_1h_grimbatolraid_d_03", ring: "thin", left: 55.833, top: 31.220, is_thin: true},
      ]
      lines = [
        {width: 95, left: 81.250, top: 53.821, angle: 129.036, spell1: 209782, spell2: 197369},
        {width: 122, left: 76.667, top: 41.789, angle: -142.660, spell1: 209782, spell2: 197234},
        {width: 187, left: 54.722, top: 44.228, angle: -34.114, spell1: 197241, spell2: 197234},
        {width: 98, left: 52.639, top: 45.366, angle: -67.874, spell1: 197241, spell2: 197386},
        {width: 111, left: 44.306, top: 59.675, angle: 130.267, spell1: 197241, spell2: 197244},
        {width: 83, left: 58.194, top: 31.545, angle: -71.783, spell1: 197386, spell2: 209781},
        {width: 94, left: 35.417, top: 71.545, angle: -39.806, spell1: 197239, spell2: 197244},
        {width: 79, left: 36.528, top: 78.699, angle: 21.666, spell1: 197239, spell2: 197610},
        {width: 117, left: 21.667, top: 80.650, angle: 152.996, spell1: 197239, spell2: 197406},
        {width: 126, left: 22.083, top: 88.130, angle: -161.996, spell1: 197233, spell2: 197406},
        {width: 138, left: 38.889, top: 88.943, angle: -12.124, spell1: 197233, spell2: 197235},
        {width: 85, left: 46.667, top: 83.902, angle: -156.448, spell1: 197235, spell2: 197610},
        {width: 115, left: 53.889, top: 67.317, angle: 139.236, spell1: 197231, spell2: 197256},
        {width: 110, left: 65.556, top: 54.797, angle: -46.109, spell1: 197231, spell2: 209835},
        {width: 77, left: 46.111, top: 70.081, angle: 33.275, spell1: 197244, spell2: 197256},
        {width: 138, left: 55.833, top: 79.675, angle: 142.052, spell1: 197604, spell2: 197235},
        {width: 110, left: 70.694, top: 66.341, angle: -46.469, spell1: 197604, spell2: 197369},
      ]
  
      return Templates.artifact(traits: traits, lines: lines, relic1: 'shadow', relic2: 'fel', relic3: 'fel')
      
    useKingslayers: ->
      $("#artifactframe").css("background-image", "url('/images/artifacts/kingslayers-bg.jpg')")
      traits = [
        {id: "ks_bagoftricks", spell_id: 192657, max_level: 1, icon: "rogue_paralytic_poison", ring: "dragon", left: 44.167, top: 33.659},
        {id: "ks_balancedblades", spell_id: 192326, max_level: 3, icon: "ability_rogue_restlessblades", ring: "thin", left: 61.528, top: 66.992, is_thin: true},
        {id: "ks_blood", spell_id: 192923, max_level: 1, icon: "ability_deathwing_bloodcorruption_death", ring: "dragon", left: 83.611, top: 64.065},
        {id: "ks_embrace", spell_id: 192323, max_level: 3, icon: "spell_shadow_skull", ring: "thin", left: 73.333, top: 75.610, is_thin: true},
        {id: "ks_fromtheshadows", spell_id: 192428, max_level: 1, icon: "ability_rogue_deadlybrew", ring: "dragon", left: 60.556, top: 25.366},
        {id: "ks_graspofguldan", spell_id: 192759, max_level: 1, icon: "ability_rogue_focusedattacks", ring: "thick", left: -0.556, top: 80.650},
        {id: "ks_gushingwound", spell_id: 192329, max_level: 3, icon: "ability_rogue_bloodsplatter", ring: "thin", left: 59.722, top: 81.626, is_thin: true},
        {id: "ks_masteralchemist", spell_id: 192318, max_level: 3, icon: "trade_alchemy_potionb5", ring: "thin", left: 9.861, top: 56.423, is_thin: true},
        {id: "ks_masterassassin", spell_id: 192349, max_level: 3, icon: "ability_rogue_deadliness", ring: "thin", left: 71.806, top: 39.350, is_thin: true},
        {id: "ks_poisonknives", spell_id: 192376, max_level: 3, icon: "ability_rogue_dualweild", ring: "thin", left: 43.333, top: 83.902, is_thin: true},
        {id: "ks_serratededge", spell_id: 192315, max_level: 3, icon: "ability_rogue_shadowstrikes", ring: "thin", left: 53.472, top: 56.911, is_thin: true},
        {id: "ks_shadowswift", spell_id: 192422, max_level: 1, icon: "rogue_burstofspeed", ring: "thin", left: 55.417, top: 42.439, is_thin: true},
        {id: "ks_shadowwalker", spell_id: 192345, max_level: 3, icon: "ability_rogue_shadowstep", ring: "thin", left: 35.278, top: 54.472, is_thin: true},
        {id: "ks_surgeoftoxins", spell_id: 192424, max_level: 1, icon: "ability_rogue_deviouspoisons", ring: "thin", left: 27.222, top: 46.341, is_thin: true},
        {id: "ks_toxicblades", spell_id: 192310, max_level: 3, icon: "trade_brewpoison", ring: "thin", left: 3.889, top: 66.179, is_thin: true},
        {id: "ks_urgetokill", spell_id: 192384, max_level: 1, icon: "ability_rogue_improvedrecuperate", ring: "thin", left: 28.611, top: 70.569, is_thin: true},
      ]
      lines = [
        {width: 95, left: 1.389, top: 80.163, angle: -70.224, spell1: 192759, spell2: 192310},
        {width: 317, left: 5.694, top: 89.106, angle: 3.621, spell1: 192759, spell2: 192376},
        {width: 119, left: 49.583, top: 89.593, angle: 173.234, spell1: 192329, spell2: 192376},
        {width: 105, left: 65.556, top: 85.366, angle: -20.684, spell1: 192329, spell2: 192323},
        {width: 234, left: 34.167, top: 82.927, angle: -163.113, spell1: 192329, spell2: 192384},
        {width: 74, left: 7.917, top: 68.130, angle: 125.628, spell1: 192318, spell2: 192310},
        {width: 161, left: 14.306, top: 70.244, angle: 32.800, spell1: 192318, spell2: 192384},
        {width: 140, left: 15.000, top: 58.211, angle: -26.381, spell1: 192318, spell2: 192424},
        {width: 145, left: 31.944, top: 46.829, angle: 147.407, spell1: 192657, spell2: 192424},
        {width: 143, left: 36.111, top: 50.894, angle: 116.565, spell1: 192657, spell2: 192345},
        {width: 163, left: 40.278, top: 55.285, angle: -27.037, spell1: 192345, spell2: 192422},
        {width: 90, left: 54.444, top: 56.423, angle: -81.060, spell1: 192315, spell2: 192422},
        {width: 132, left: 41.389, top: 62.439, angle: -173.468, spell1: 192315, spell2: 192345},
        {width: 198, left: 33.472, top: 70.569, angle: 154.861, spell1: 192315, spell2: 192384},
        {width: 111, left: 56.528, top: 40.650, angle: 109.411, spell1: 192428, spell2: 192422},
        {width: 118, left: 64.167, top: 39.187, angle: 46.715, spell1: 192428, spell2: 192349},
        {width: 234, left: 34.167, top: 82.927, angle: -163.113, spell1: 192329, spell2: 192384},
        {width: 119, left: 49.583, top: 89.593, angle: 173.234, spell1: 192329, spell2: 192376},
        {width: 105, left: 65.556, top: 85.366, angle: -20.684, spell1: 192329, spell2: 192323},
        {width: 174, left: 71.806, top: 58.537, angle: -119.214, spell1: 192923, spell2: 192349},
        {width: 103, left: 77.639, top: 76.585, angle: 136.185, spell1: 192923, spell2: 192323},
        {width: 238, left: 34.722, top: 75.610, angle: 174.697, spell1: 192326, spell2: 192384},
        {width: 185, left: 60.139, top: 60.000, angle: -66.477, spell1: 192326, spell2: 192349},
      ]
  
      return Templates.artifact(traits: traits, lines: lines, relic1: 'shadow', relic2: 'iron', relic3: 'blood')
      
