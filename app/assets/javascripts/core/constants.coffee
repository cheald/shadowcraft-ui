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
    955: 74,
    960: 75,
    965: 77,
    970: 78,
    975: 80,
    980: 81,
    985: 83
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
    0.4553051,		0.452771548,  0.450252095,	0.447746661,	0.445255168,	#  945
    0.44277754,		0.440313698,  0.437863566,	0.435427068,	0.433004128,	#  950
    0.430594671,	0.428198621,  0.425815904,	0.423446445,	0.421090172,	#  955
    0.41874701,		0.416416886,  0.414099729,	0.411795465,	0.409504023,	#  960
    0.407225332,	0.404959321,  0.40270592,	0.400465057,	0.398236664,	#  965
    0.39602067,		0.393817008,  0.391625607,	0.389446401,	0.387279321,	#  970
    0.3851243,		0.382981271,  0.380850166,	0.37873092,	0.376623467,	#  975
    0.37452774,		0.372443675,  0.370371207,	0.368310272,	0.366260804,	#  980
    0.364222741,	0.362196018,  0.360180574,	0.358176344,	0.356183267,	#  985
    0.35420128,		0.352230322,  0.350270331,	0.348321247,	0.346383009,	#  990
    0.344455556,	0.342538828,  0.340632766,	0.33873731,	0.336852402,	#  995
    0.334977982,	0.333113992,  0.331260375,	0.329417072,	0.327584026,	# 1000
    0.32576118,		0.323948478,  0.322145862,	0.320353277,	0.318570666,	# 1005
    0.316797976,	0.315035149,  0.313282131,	0.311538869,	0.309805306,	# 1010
    0.30808139,		0.306367067,  0.304662283,	0.302966986,	0.301281122,	# 1015
    0.299604639,	0.297937485,  0.296279607,	0.294630955,	0.292991477,	# 1020
    0.291361122,	0.289739839,  0.288127578,	0.286524288,	0.28492992,	# 1025
    0.283344423,	0.281767749,  0.280199849,	0.278640673,	0.277090173,	# 1030
    0.275548301,	0.274015008,  0.272490248,	0.270973972,	0.269466134,	# 1035
    0.267966686,	0.266475582,  0.264992774,	0.263518218,	0.262051868,	# 1040
    0.260593676,	0.259143599,  0.257701591,	0.256267607,	0.254841602,	# 1045
    0.253423533,	0.252013354,  0.250611022,	0.249216494,	0.247829725,	# 1050
    0.246450673,	0.245079295,  0.243715548,	0.242359389,	0.241010777,	# 1055
    0.239669669,	0.238336024,  0.2370098,	0.235690956,	0.23437945,	# 1060
    0.233075242,	0.231778292,  0.230488558,	0.229206002,	0.227930582,	# 1065
    0.226662259,	0.225400994,  0.224146747,	0.222899479,	0.221659152,	# 1070
    0.220425726,	0.219199164,  0.217979427,	0.216766478,	0.215560278,	# 1075
    0.21436079,		0.213167976,  0.2119818,	0.210802224,	0.209629212,	# 1080
    0.208462728,	0.207302734,  0.206149195,	0.205002075,	0.203861338,	# 1085
    0.202726949,	0.201598872,  0.200477072,	0.199361515,	0.198252165,	# 1090
    0.197148988,	0.19605195,   0.194961016,	0.193876153,	0.192797326,	# 1095
    0.191724503,	0.190657649,  0.189596732,	0.188541718,	0.187492575,	# 1100
    0.18644927,		0.185411771,  0.184380044,	0.183354059,	0.182333783,	# 1105
    0.181319184,	0.180310231,  0.179306892,	0.178309136,	0.177316933,	# 1110
    0.17633025,		0.175349058,  0.174373326,	0.173403023,	0.172438119,	# 1115
    0.171478585,	0.17052439,   0.169575505,	0.1686319,	0.167693545,	# 1120
    0.166760412,	0.165832471,  0.164909694,	0.163992052,	0.163079516,	# 1125
    0.162172058,	0.161269649,  0.160372262,	0.159479868,	0.15859244,	# 1130
    0.15770995,		0.156832371,  0.155959675,	0.155091836,	0.154228825,	# 1135
    0.153370616,	0.152517184,  0.1516685,	0.150824538,	0.149985273,	# 1140
    0.149150678,	0.148320727,  0.147495394,	0.146674654,	0.145858481,	# 1145
    0.145046849,	0.144239734,  0.14343711,	0.142638952,	0.141845236,	# 1150
    0.141055936,	0.140271028,  0.139490488,	0.138714291,	0.137942414,	# 1155
    0.137174831,	0.13641152,   0.135652456,	0.134897616,	0.134146977,	# 1160
    0.133400514,	0.132658205,  0.131920026,	0.131185956,	0.13045597,	# 1165
    0.129730046,	0.129008161,  0.128290293,	0.12757642,	0.126866519,	# 1170
    0.126160569,	0.125458547,  0.124760431,	0.1240662,	0.123375832,	# 1175
    0.122689305,	0.122006599,  0.121327691,	0.120652562,	0.119981189,	# 1180
    0.119313552,	0.11864963,   0.117989402,	0.117332849,	0.116679948,	# 1185
    0.116030681,	0.115385027,  0.114742965,	0.114104477,	0.113469541,	# 1190
    0.112838138,	0.112210248,  0.111585853,	0.110964932,	0.110347466,	# 1195
    0.109733436,	0.109122823,  0.108515607,	0.107911771,	0.107311294,	# 1200
    0.106714159,	0.106120347,  0.105529838,	0.104942616,	0.104358662,	# 1205
    0.103777956,	0.103200482,  0.102626222,	0.102055157,	0.10148727,	# 1210
    0.100922542,	0.100360957,  0.099802497,	0.099247145,	0.098694883,	# 1215
    0.098145694,	0.097599561,  0.097056467,	0.096516395,	0.095979328,	# 1220
    0.095445249,	0.094914143,  0.094385992,	0.09386078,	0.09333849,	# 1225
    0.092819107,	0.092302614,  0.091788995,	0.091278233,	0.090770314,	# 1230
    0.090265222,	0.08976294,   0.089263453,	0.088766745,	0.088272801,	# 1235
    0.087781606,	0.087293144,  0.0868074,	0.086324359,	0.085844006,	# 1240
    0.085366326,	0.084891304,  0.084418925,	0.083949174,	0.083482038,	# 1245
    0.083017501,	0.082555549,  0.082096168,	0.081639342,	0.081185059,	# 1250
    0.080733304,	0.080284062,  0.07983732,	0.079393065,	0.078951281,	# 1255
    0.078511955,	0.078075074,  0.077640625,	0.077208592,	0.076778964,	# 1260
    0.076351726,	0.075926866,  0.07550437,	0.075084225,	0.074666418,	# 1265
    0.074250935,	0.073837765,  0.073426894,	0.073018309,	0.072611997,	# 1270
    0.072207947,	0.071806145,  0.071406578,	0.071009236,	0.070614104,	# 1275
    0.070221171,	0.069830424,  0.069441851,	0.069055441,	0.068671181,	# 1280
    0.06828906,		0.067909064,  0.067531183,	0.067155405,	0.066781718,	# 1285
    0.06641011,		0.06604057,   0.065673086,	0.065307648,	0.064944242,	# 1290
    0.064582859,	0.064223487,  0.063866115,	0.063510731,	0.063157324,	# 1295
    0.062805884,	0.0624564,    0.062108861,	0.061763255,	0.061419573,	# 1300
  ]

  # This is the current maximum ilevel of items via WF/TF. This means that the WF/TF
  # popup will only show entries up to this maximum amount.
  @CURRENT_MAX_ILVL = 985

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
      concordance: 239042
      relic1: "Shadow"
      relic2: "Iron"
      relic3: "Blood"
    "Z":
      icon: "inv_sword_1h_artifactskywall_d_01"
      text: "The Dreadblades"
      main: 202665
      thirtyfive: 214929
      secondmajor: 241153
      concordance: 239042
      relic1: "Blood"
      relic2: "Iron"
      relic3: "Storm"
    "b":
      icon: "inv_knife_1h_artifactfangs_d_01"
      text: "Fangs of the Devourer"
      main: 209782
      thirtyfive: 214930
      secondmajor: 241154
      concordance: 239042
      relic1: "Fel"
      relic2: "Shadow"
      relic3: "Fel"

  # This is a list of the set bonuses that are available and the item IDs for those
  # sets. Legendaries are considered sets due to how they're implemented.
  @SETS =
    T19:
      ids: [138326, 138329, 138332, 138335, 138338, 138371]
      bonuses: {4: "rogue_t19_4pc", 2: "rogue_t19_2pc"}
    T20:
      ids: [147169, 147170, 147171, 147172, 147173, 147174]
      bonuses: {4: "rogue_t20_4pc", 2: "rogue_t20_2pc"}
    T21:
      ids: [152160, 152161, 152162, 152163, 152164, 152165]
      bonuses: {4: "rogue_t21_4pc", 2: "rogue_t21_2pc"}
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
