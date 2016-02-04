ArtifactTemplates = null
ShadowcraftApp.bind "boot", ->
  ArtifactTemplates = 
    useDreadblades: ->
      $("#artifactframe").css("background-image", "url('/images/artifacts/44-small.jpg')")
      traits = [
        {id: "db_bladedancer", spell_id: 202507, max_level: 3, icon: "ability_warrior_bladestorm", ring: "thin", left: 15.244, top: 44.143, is_thin: true},
        {id: "db_blademaster", spell_id: 202628, max_level: 3, icon: "ability_warrior_challange", ring: "thin", left: 7.073, top: 81.571, is_thin: true},
        {id: "db_blunderbuss", spell_id: 202897, max_level: 1, icon: "inv_weapon_rifle_01", ring: "dragon", left: 19.634, top: 69.143},
        {id: "db_blurredtime", spell_id: 202769, max_level: 1, icon: "ability_rogue_quickrecovery", ring: "dragon", left: 30.854, top: 35.857},
        {id: "db_curse", spell_id: 202665, max_level: 1, icon: "inv_sword_1h_artifactskywall_d_01dual", ring: "thick", left: 56.463, top: 45.714},
        {id: "db_cursededges", spell_id: 202463, max_level: 3, icon: "inv_sword_33", ring: "thin", left: 46.585, top: 55.286, is_thin: true},
        {id: "db_cursedleather", spell_id: 202521, max_level: 3, icon: "ability_rogue_masterofsubtlety", ring: "thin", left: 57.317, top: 29.714, is_thin: true},
        {id: "db_deception", spell_id: 202755, max_level: 3, icon: "ability_rogue_disguise", ring: "thin", left: 57.195, top: 16.429, is_thin: true},
        {id: "db_fatebringer", spell_id: 202524, max_level: 3, icon: "ability_rogue_cuttothechase", ring: "thin", left: -1.220, top: 53.143, is_thin: true},
        {id: "db_fatesthirst", spell_id: 202514, max_level: 3, icon: "ability_rogue_waylay", ring: "thin", left: 66.707, top: 38.000, is_thin: true},
        {id: "db_fortunesboon", spell_id: 202907, max_level: 3, icon: "ability_rogue_surpriseattack2", ring: "thin", left: 71.341, top: 22.857, is_thin: true},
        {id: "db_fortunestrikes", spell_id: 202530, max_level: 3, icon: "ability_rogue_improvedrecuperate", ring: "thin", left: 33.293, top: 51.286, is_thin: true},
        {id: "db_ghostlyshell", spell_id: 202533, max_level: 3, icon: "spell_shadow_nethercloak", ring: "thin", left: 44.634, top: 27.857, is_thin: true},
        {id: "db_greed", spell_id: 202820, max_level: 1, icon: "warrior_skullbanner", ring: "dragon", left: 69.512, top: 4.286},
        {id: "db_gunslinger", spell_id: 202522, max_level: 3, icon: "inv_weapon_rifle_07", ring: "thin", left: 28.049, top: 87.000, is_thin: true},
        {id: "db_hiddenblade", spell_id: 202753, max_level: 3, icon: "ability_ironmaidens_bladerush", ring: "thin", left: 89.634, top: 25.000, is_thin: true}
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
      $("#artifactframe").css("background-image", "url('/images/artifacts/44-small.jpg')")
      traits = [
      ]
      lines = [
      ]

      return Templates.artifact(traits: traits, lines: lines, relic1: 'shadow', relic2: 'fel', relic3: 'fel')
      
    useKingslayers: ->
      $("#artifactframe").css("background-image", "url('/images/artifacts/44-small.jpg')")
      traits = [
      ]
      lines = [
      ]

      return Templates.artifact(traits: traits, lines: lines, relic1: 'shadow', relic2: 'iron', relic3: 'blood')
      
