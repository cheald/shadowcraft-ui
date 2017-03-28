class ShadowcraftConstants

  @WOWHEAD_SPEC_IDS =
    "a": 259
    "Z": 260
    "b": 261

  @RELIC_ILVL_MAPPING = {
    650: 2,
    660: 2,
    680: 2,
    682: 2,
    685: 2,
    690: 2,
    694: 3,
    695: 3,
    700: 4,
    705: 5,
    707: 6,
    710: 7,
    715: 8,
    719: 9,
    720: 9,
    725: 10,
    730: 12,
    735: 13,
    740: 14,
    743: 15,
    745: 15,
    750: 17,
    755: 18,
    756: 18,
    760: 19,
    765: 21,
    768: 21,
    769: 21,
    770: 22,
    775: 23,
    780: 24,
    790: 27,
    805: 31,
    810: 32,
    815: 33,
    820: 35,
    825: 36,
    830: 37,
    835: 39,
    840: 40,
    845: 42,
    850: 43,
    855: 45,
    860: 46,
    865: 48,
    870: 49,
    875: 51,
    880: 52,
    885: 53,
    890: 55,
    895: 56,
    900: 58,
    905: 59,
    910: 61,
    915: 62,
    920: 64,
    925: 65,
    930: 67,
    935: 68,
    940: 70,
    945: 71,
    950: 72,
    955: 74
  }

  # Taken from https://github.com/simulationcraft/simc/blob/legion-dev/engine/dbc/generated/sc_scale_data.inc
  @COMBAT_RATINGS_MULT_BY_ILVL = [
    1,
    1,	1,	1,	1,	1,	#    5
    1,	1,	1,	1,	1,	#   10
    1,	1,	1,	1,	1,	#   15
    1,	1,	1,	1,	1,	#   20
    1,	1,	1,	1,	1,	#   25
    1,	1,	1,	1,	1,	#   30
    1,	1,	1,	1,	1,	#   35
    1,	1,	1,	1,	1,	#   40
    1,	1,	1,	1,	1,	#   45
    1,	1,	1,	1,	1,	#   50
    1,	1,	1,	1,	1,	#   55
    1,	1,	1,	1,	1,	#   60
    1,	1,	1,	1,	1,	#   65
    1,	1,	1,	1,	1,	#   70
    1,	1,	1,	1,	1,	#   75
    1,	1,	1,	1,	1,	#   80
    1,	1,	1,	1,	1,	#   85
    1,	1,	1,	1,	1,	#   90
    1,	1,	1,	1,	1,	#   95
    1,	1,	1,	1,	1,	#  100
    1,	1,	1,	1,	1,	#  105
    1,	1,	1,	1,	1,	#  110
    1,	1,	1,	1,	1,	#  115
    1,	1,	1,	1,	1,	#  120
    1,	1,	1,	1,	1,	#  125
    1,	1,	1,	1,	1,	#  130
    1,	1,	1,	1,	1,	#  135
    1,	1,	1,	1,	1,	#  140
    1,	1,	1,	1,	1,	#  145
    1,	1,	1,	1,	1,	#  150
    1,	1,	1,	1,	1,	#  155
    1,	1,	1,	1,	1,	#  160
    1,	1,	1,	1,	1,	#  165
    1,	1,	1,	1,	1,	#  170
    1,	1,	1,	1,	1,	#  175
    1,	1,	1,	1,	1,	#  180
    1,	1,	1,	1,	1,	#  185
    1,	1,	1,	1,	1,	#  190
    1,	1,	1,	1,	1,	#  195
    1,	1,	1,	1,	1,	#  200
    1,	1,	1,	1,	1,	#  205
    1,	1,	1,	1,	1,	#  210
    1,	1,	1,	1,	1,	#  215
    1,	1,	1,	1,	1,	#  220
    1,	1,	1,	1,	1,	#  225
    1,	1,	1,	1,	1,	#  230
    1,	1,	1,	1,	1,	#  235
    1,	1,	1,	1,	1,	#  240
    1,	1,	1,	1,	1,	#  245
    1,	1,	1,	1,	1,	#  250
    1,	1,	1,	1,	1,	#  255
    1,	1,	1,	1,	1,	#  260
    1,	1,	1,	1,	1,	#  265
    1,	1,	1,	1,	1,	#  270
    1,	1,	1,	1,	1,	#  275
    1,	1,	1,	1,	1,	#  280
    1,	1,	1,	1,	1,	#  285
    1,	1,	1,	1,	1,	#  290
    1,	1,	1,	1,	1,	#  295
    1,	1,	1,	1,	1,	#  300
    1,	1,	1,	1,	1,	#  305
    1,	1,	1,	1,	1,	#  310
    1,	1,	1,	1,	1,	#  315
    1,	1,	1,	1,	1,	#  320
    1,	1,	1,	1,	1,	#  325
    1,	1,	1,	1,	1,	#  330
    1,	1,	1,	1,	1,	#  335
    1,	1,	1,	1,	1,	#  340
    1,	1,	1,	1,	1,	#  345
    1,	1,	1,	1,	1,	#  350
    1,	1,	1,	1,	1,	#  355
    1,	1,	1,	1,	1,	#  360
    1,	1,	1,	1,	1,	#  365
    1,	1,	1,	1,	1,	#  370
    1,	1,	1,	1,	1,	#  375
    1,	1,	1,	1,	1,	#  380
    1,	1,	1,	1,	1,	#  385
    1,	1,	1,	1,	1,	#  390
    1,	1,	1,	1,	1,	#  395
    1,	1,	1,	1,	1,	#  400
    1,	1,	1,	1,	1,	#  405
    1,	1,	1,	1,	1,	#  410
    1,	1,	1,	1,	1,	#  415
    1,	1,	1,	1,	1,	#  420
    1,	1,	1,	1,	1,	#  425
    1,	1,	1,	1,	1,	#  430
    1,	1,	1,	1,	1,	#  435
    1,	1,	1,	1,	1,	#  440
    1,	1,	1,	1,	1,	#  445
    1,	1,	1,	1,	1,	#  450
    1,	1,	1,	1,	1,	#  455
    1,	1,	1,	1,	1,	#  460
    1,	1,	1,	1,	1,	#  465
    1,	1,	1,	1,	1,	#  470
    1,	1,	1,	1,	1,	#  475
    1,	1,	1,	1,	1,	#  480
    1,	1,	1,	1,	1,	#  485
    1,	1,	1,	1,	1,	#  490
    1,	1,	1,	1,	1,	#  495
    1,	1,	1,	1,	1,	#  500
    1,	1,	1,	1,	1,	#  505
    1,	1,	1,	1,	1,	#  510
    1,	1,	1,	1,	1,	#  515
    1,	1,	1,	1,	1,	#  520
    1,	1,	1,	1,	1,	#  525
    1,	1,	1,	1,	1,	#  530
    1,	1,	1,	1,	1,	#  535
    1,	1,	1,	1,	1,	#  540
    1,	1,	1,	1,	1,	#  545
    1,	1,	1,	1,	1,	#  550
    1,	1,	1,	1,	1,	#  555
    1,	1,	1,	1,	1,	#  560
    1,	1,	1,	1,	1,	#  565
    1,	1,	1,	1,	1,	#  570
    1,	1,	1,	1,	1,	#  575
    1,	1,	1,	1,	1,	#  580
    1,	1,	1,	1,	1,	#  585
    1,	1,	1,	1,	1,	#  590
    1,	1,	1,	1,	1,	#  595
    1,	1,	1,	1,	1,	#  600
    1,	1,	1,	1,	1,	#  605
    1,	1,	1,	1,	1,	#  610
    1,	1,	1,	1,	1,	#  615
    1,	1,	1,	1,	1,	#  620
    1,	1,	1,	1,	1,	#  625
    1,	1,	1,	1,	1,	#  630
    1,	1,	1,	1,	1,	#  635
    1,	1,	1,	1,	1,	#  640
    1,	1,	1,	1,	1,	#  645
    1,	1,	1,	1,	1,	#  650
    1,	1,	1,	1,	1,	#  655
    1,	1,	1,	1,	1,	#  660
    1,	1,	1,	1,	1,	#  665
    1,	1,	1,	1,	1,	#  670
    1,	1,	1,	1,	1,	#  675
    1,	1,	1,	1,	1,	#  680
    1,	1,	1,	1,	1,	#  685
    1,	1,	1,	1,	1,	#  690
    1,	1,	1,	1,	1,	#  695
    1,	1,	1,	1,	1,	#  700
    1,	1,	1,	1,	1,	#  705
    1,	1,	1,	1,	1,	#  710
    1,	1,	1,	1,	1,	#  715
    1,	1,	1,	1,	1,	#  720
    1,	1,	1,	1,	1,	#  725
    1,	1,	1,	1,	1,	#  730
    1,	1,	1,	1,	1,	#  735
    1,	1,	1,	1,	1,	#  740
    1,	1,	1,	1,	1,	#  745
    1,	1,	1,	1,	1,	#  750
    1,	1,	1,	1,	1,	#  755
    1,	1,	1,	1,	1,	#  760
    1,	1,	1,	1,	1,	#  765
    1,	1,	1,	1,	1,	#  770
    1,	1,	1,	1,	1,	#  775
    1,	1,	1,	1,	1,	#  780
    1,	1,	1,	1,	1,	#  785
    1,	1,	1,	1,	1,	#  790
    1,	1,	1,	1,	1,	#  795
    1,	1,	1,	1,	1,	#  800
    0.994435486,	0.988901936,	0.983399178,	0.977927039,	0.972485351,	#  805
    0.967073942,	0.961692646,	0.956341294,	0.95101972,   0.945727757,	#  810
    0.940465242,	0.93523201,   0.930027899,	0.924852745,	0.91970639,   #  815
    0.914588671,	0.909499429,	0.904438507,	0.899405746,	0.894400991,	#  820
    0.889424084,	0.884474871,	0.879553199,	0.874658913,	0.869791861,	#  825
    0.864951892,	0.860138855,	0.855352601,	0.850592979,	0.845859843,	#  830
    0.841153044,	0.836472436,	0.831817874,	0.827189212,	0.822586306,	#  835
    0.818009013,	0.813457191,	0.808930697,	0.804429391,	0.799953132,	#  840
    0.795501782,	0.791075201,	0.786673252,	0.782295798,	0.777942702,	#  845
    0.773613829,	0.769309044,	0.765028214,	0.760771204,	0.756537882,	#  850
    0.752328116,	0.748141776,	0.743978731,	0.739838851,	0.735722007,	#  855
    0.731628072,	0.727556917,	0.723508417,	0.719482444,	0.715478874,	#  860
    0.711497582,	0.707538444,	0.703601336,	0.699686137,	0.695792724,	#  865
    0.691920975,	0.688070772,	0.684241992,	0.680434518,	0.676648231,	#  870
    0.672883012,	0.669138746,	0.665415314,	0.661712601,	0.658030492,	#  875
    0.654368872,	0.650727628,	0.647106645,	0.643505811,	0.639925014,	#  880
    0.636364142,	0.632823085,	0.629301732,	0.625799974,	0.622317701,	#  885
    0.618854806,	0.61541118,   0.611986716,	0.608581307,	0.605194848,	#  890
    0.601827233,	0.598478357,	0.595148116,	0.591836406,	0.588543124,	#  895
    0.585268168,	0.582011435,	0.578772824,	0.575552235,	0.572349566,	#  900
    0.569164719,	0.565997594,	0.562848093,	0.559716117,	0.556601569,	#  905
    0.553504352,	0.550424369,	0.547361525,	0.544315724,	0.541286872,	#  910
    0.538274873,	0.535279635,	0.532301064,	0.529339068,	0.526393553,	#  915
    0.523464429,	0.520551604,	0.517654987,	0.514774489,	0.511910019,	#  920
    0.509061489,	0.506228809,	0.503411892,	0.500610649,	0.497824994,	#  925
    0.49505484,   0.492300101,	0.48956069,   0.486836523,	0.484127514,	#  930
    0.48143358,   0.478754636,	0.476090599,	0.473441387,	0.470806916,	#  935
    0.468187104,	0.46558187,   0.462991133,	0.460414813,	0.457852828,	#  940
  ]

  # This is the current maximum ilevel of items via WF/TF. This means that the WF/TF
  # popup will only show entries up to this maximum amount.
  @CURRENT_MAX_ILVL = 955

  @ARTIFACTS = [128476, 128479, 128872, 134552, 128869, 128870]
  @ARTIFACT_SETS =
    a:
      mh: 128870
      oh: 128869
    Z:
      mh: 128872
      oh: 134552
    b:
      mh: 128476
      oh: 128479

  # TODO: I'm really hoping that some of this data is available from the API
  # in the future so we don't have to store it here in the javascript.
  @SPEC_ARTIFACT =
    "a":
      icon: "inv_knife_1h_artifactgarona_d_01"
      text: "The Kingslayers"
      main: 192759
      thirtyfive: 214928
      secondmajor: 241152
      relic1: "Shadow"
      relic2: "Iron"
      relic3: "Blood"
    "Z":
      icon: "inv_sword_1h_artifactskywall_d_01"
      text: "The Dreadblades"
      main: 202665
      thirtyfive: 214929
      secondmajor: 241153
      relic1: "Blood"
      relic2: "Iron"
      relic3: "Storm"
    "b":
      icon: "inv_knife_1h_artifactfangs_d_01"
      text: "Fangs of the Devourer"
      main: 209782
      thirtyfive: 214930
      secondmajor: 241154
      relic1: "Fel"
      relic2: "Shadow"
      relic3: "Fel"

  # This is a list of the set bonuses that are available and the item IDs for those
  # sets. Legendaries are considered sets due to how they're implemented.
  @SETS =
    T18:
      ids: [124248, 124257, 124263, 124269, 124274]
      bonuses: {4: "rogue_t18_4pc", 2: "rogue_t18_2pc"}
    T18_LFR:
      ids: [128130, 128121, 128125, 128054, 128131, 128137]
      bonuses: {4: "rogue_t18_4pc_lfr"}
    T19:
      ids: [138326, 138329, 138332, 138335, 138338, 138371]
      bonuses: {4: "rogue_t19_4pc", 2: "rogue_t19_2pc"}
    ORDERHALL:
      ids: [139739, 139740, 139741, 139742, 139743, 139744, 139745, 139746]
      bonuses: {8: "rogue_orderhall_8pc"}
    MARCH_OF_THE_LEGION:
      ids: [134529, 134533]
      bonuses: {2: "march_of_the_legion_2pc"}
    JOURNEY_THROUGH_TIME:
      ids: [137419, 137487]
      bonuses: {2: "journey_through_time_2pc"}
    JACINS_RUSE:
      ids: [137480, 137397]
      bonuses: {2: "jacins_ruse_2pc"}
    INSIGNIA_OF_RAVENHOLDT:
      ids: [137049]
      bonuses: {1: "insignia_of_ravenholdt"}
    DUSKWALKERS_FOOTPADS:
      ids: [137030]
      bonuses: {1: 'duskwalkers_footpads'}
    ZOLDYCK_FAMILY_TRAINING_SHACKLES:
      ids: [137098]
      bonuses: {1: 'zoldyck_family_training_shackles'}
    THE_DREADLORDS_DECEIT:
      ids: [137021]
      bonuses: {1: 'the_dreadlords_deceit'}
    THRAXIS_TRICKSY_TREADS:
      ids: [137031]
      bonuses: {1: 'thraxis_tricksy_treads'}
    GREENSKINS_WATERLOGGED_WRISTCUFFS:
      ids: [137099]
      bonuses: {1: 'greenskins_waterlogged_wristcuffs'}
    SHIVARRAN_SYMMETRY:
      ids: [141321]
      bonuses: {1: 'shivarran_symmetry'}
    SHADOW_SATYRS_WALK:
      ids: [137032]
      bonuses: {1: 'shadow_satyrs_walk'}
    DENIAL_OF_THE_HALF_GIANTS:
      ids: [137100]
      bonuses: {1: 'denial_of_the_half_giants'}
    CINIDARIA_THE_SYMBIOTE:
      ids: [133976]
      bonuses: {1: 'cinidaria_the_symbiote'}
    MANTLE_OF_THE_MASTER_ASSASSIN:
      ids: [144236]
      bonuses: {1: 'mantle_of_the_master_assassin'}
    TOES_KNEES:
      ids: [142164, 142203]
      bonuses: {2: 'kara_empowered_2pc'}
    BLOODSTAINED:
      ids: [142159, 142203]
      bonuses: {2: 'kara_empowered_2pc'}
    EYE_OF_COMMAND:
      ids: [142167, 142203]
      bonuses: {2: 'kara_empowered_2pc'}
    SEPHUZS_SECRET:
      ids: [132452]
      bonuses: {1: 'sephuzs_secret'}

  # This is a list of the bonus IDs that mean "item level upgrade" for
  # the warforged/titanforged support.
  # TODO: it seems like this could be built and stored in index-rogue.js instead of
  # doing it manually here.
  @WF_BONUS_IDS = [546..547]
  Array::push.apply @WF_BONUS_IDS, [560..562]
  Array::push.apply @WF_BONUS_IDS, [644,646,651,656]
  Array::push.apply @WF_BONUS_IDS, [754..766]
  Array::push.apply @WF_BONUS_IDS, [1477..1672]

  @buffMap = [
    'short_term_haste_buff',
    'flask_legion_agi'
  ]

  @buffFoodMap = [
    'food_legion_375_crit',
    'food_legion_375_haste',
    'food_legion_375_mastery',
    'food_legion_375_versatility',
    'food_legion_feast_500',
    'food_legion_damage_3'
  ]

  @buffPotions = [
    'potion_old_war',
    'potion_prolonged_power',
    'potion_none'
  ]

  @PROC_ENCHANTS =
    5437: "mark_of_the_claw"
    5438: "mark_of_the_distant_army"
    5439: "mark_of_the_hidden_satyr"

  # This is all of the bonus IDs that mean +socket. Ridiculous.
  @SOCKET_BONUS_IDS = [523, 572, 608, 1808]
  @SOCKET_BONUS_IDS = @SOCKET_BONUS_IDS.concat([563..565])
  @SOCKET_BONUS_IDS = @SOCKET_BONUS_IDS.concat([715..719])
  @SOCKET_BONUS_IDS = @SOCKET_BONUS_IDS.concat([721..752])

window.ShadowcraftConstants = ShadowcraftConstants
