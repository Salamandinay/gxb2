LJ B@../../../Product/Bundles/Android/src/app/windows/BattleWindow.lua  r-  9 9   B- = - = 6 99= - = 9
=	 9  X)  = )  =   9 BK  ÀÀÀ	ÀinitLayOutalreadyFinishRoundgroup7NumbuffIDbuffID_DBuffTablegroupBuffTextTabletablesxydGroupBuffTextTableGroupBuffTableStageTable	ctor
super


GroupBuffDetailTips StageTable GroupBuffTable DBuffTable self  parentGo  params   F   
'  L .Prefabs/Components/group_buff_detail_tipsself   « 
 _#-  9 9  B9  9' B9 96 6 B A=  9
'	 6 6 B A=	  9' B9 9
' 6 6 B A=  9
' 6 6 B A= 6 99 X9 ) = 9' B9=  9' B9 9
' 6 6	 B A=  9' B9= 9  96 6 B A= 9 9= 9 9= K  ÀbaseConHeightheightinitHeightUITableattrGroupTableattrGrouplabelDesbottombuffIconGroupfontSize
ja_jp	langGlobalxydlabelLine1UILabellabelNametopUISpriteComponentByName
bgImgUIWidgettypeofGetComponentgameObjectcontentNodeByNamegoinitUI
super					


GroupBuffDetailTips self  `go Ycontent Ttop @bottom # Ú 9à:6-  9 9 B 99 + B 9*  *  ) B9 9  99 B=9	 9  9
9 B=9 6 ' B=6 99  99 B' B' 9 6 9 X' 9 + =6 99  99 B' B 9 99 !6 99 99 B)  ) M8
	 
 X6
 9

8	' B
:
6 :
B  9  8	B9!  9"'# 	 &6$ 6% B A9!  9"'& 	 &6$ 6% B A6 ''  6 99( 9 B A=6 9)  9* B A )   X) 9)  9+ B  X	 6, #B'- &=X 6,  B&=9 6 9 X,99&=6 '. 	 B=9/ 90) B9/ 9091B92 	 X64 95* B=364 95* B=3X
64 95* B=364 95* B=3O|9 6 9 X9  96B97 98  =K  ÀbaseConHeightcontentReposition	New2
Color
colorgroup7Num
widthXgameObjectGROUP_7_BUFF_TIP%tostringisShowPercentgetFactorDBuffTabledBuffTablePOSITION_DESClabelAttrNumUILabeltypeoflabelAttrComponentByNameattrGroupgetPosDesctonumber#getEffectStandsgroupBuffTabletablesinitHeightheight@enabledattrGroupTable+GROUP_7_BUFF+ |getEffectShowGroupBuffTable
splitxydGROUP_BUFF_DES__labelLine1getNamelabelNamegetDescGroupBuffTextTable	textlabelDesSetLocalScalebuffID_setInfobuffIconGroupnew®®ÿÈÜþ¶«þþï¸Â<					
      """""####$$$$$%%%%%&&&&&&'''((((())))))+++++,,,,,/22222333355556GroupBuffIcon self  ábuffIcon ÜeffectShowData 'µaddStr ´height poses   i effectData {effectName zeffectNum wpos_label slabelAttr 
ilabelAttrNum 
_factor L ú  "Ar  X'  L '  6 9 ' + B 	  XX 	 X:	 X:	 X6 ' B X6 ' B L BACK_POS1HEAD_POS1__|
splitxyd					self  #pos  #result poses  ×
 9 ½<-  9 9    B)  = )  = + = 4  = 4  = 4  = )  = )ÿÿ=	 4  =
 ) = ) = + = ) = ) = + = + = )  = ) = ) = ) = ) = ) = )
 = 4  = ) = 4  = 4  = 4  = + = 4  = )  =  4  =! 4  =" )  =# + =$ + =% + =& )  =' )  =( )  =) 4  =* )  =+ =, 6- 9.9, 90=/9193=2   X93  X93=2 9  X4  = 94  X)  = 95  X)  =	   96 B6- 97= 6- 97=   98 92 BK   ÀinitDataBASIC_BATTLE_SPEEDinitConstsound_posbattle_soundbattle_reportbattleReport_event_databattle_typecurBattleTypeBattlexyd
data_curDepth_
tips_AwardIdBossShowedHarmBossHarmunAutoEnd_isPlayPetSkillbattleEndsframeIndexnodeGroups_	teampetEnergy_herosPos_isBattleStart_effectsObjeffectsCountactionsroundNumzOrders_PET_SKILL_MPPET_ROUND_MPBUFF_REMOVEBUFF_OFFBUFF_WORKBUFF_ONBUFF_ON_WORKisTouchSkip_isShake_screenScaleYscreenScaleXisGuideStopBattle_newTimeScale_timeScale_soundEffects_battleSoundPosbattleSoundsoundsRate_soundstimersisSkillSound_
isWinbattleID	ctor
super		

  !!""##$$%%&&(())**++,,./////0112222233555556666677777888999:::;;;;<BattleWindow self  name  params  battleData c& É  -Æ6  99 9' ' ' B6  :=6  :=6  :=	9
 96  99 X6  *  =K  	TESTBattleTypebattle_type
data_QUADRUPLE_BATTLE_SPEEDDOUBLE_BATTLE_SPEEDBASIC_BATTLE_SPEED|
valuebattle_speed_upsplit2nummiscTabletablesxydÿself  speed 
    4EÐ9=  9= 9= 9= 6 9 B X9   X9 9  X+  = 6 9 B X9   X9 9  X+  = 9	=	 9
=
 9= 9 9= 9  X  9 BK  initEmptyFieldhasDecodedbattle_idbattleID	infobattleInfo
isWinframeslvtostring	petB	petA
teamBherosB
teamAherosA												

self  5params  5    æ9    X9  9  X+  =  9   X9 9  X+  = K  	petBpet_id	petAself   2   ð9    X4  L 
data_self   è  ,ô-  9 9B  9 B  9 9 )Ëý)@ýB  9 B  9 B  9 BK   ÀinitButtonsetConfigsetMapbottomLightresizePosYgetUIComponentinitWindow
superBattleWindow self   Ø <oý-  9 9   B6 99B 99 B6 99	 B  X6 9 B  XK  9
 6 96 9 + B  6 9B=   9 B  9 B  9 B  9 B  9 B  9 BK   ÀstartBattleinitEffectsinitGroupBuffupdateRoundLabelinitPetInfosetFormationMaxIntGetMaxTargetDepthXYDUtils
Clamp
MathfcurDepth_minDepth_window_isnull
tolualayerType_getUILayergetWindowManagerxydplayOpenAnimation
super


BattleWindow self  =callback  =layer .minDepth   ÿ @  69  9 9' B9 9' 6 6 B A=  9'	 6 6 B A=	  9'
 6 6 B A=
  9' B9 9' 6 6 B A= 6 99 X9 ) =9 )* = 9' B9-  9 + B=  9' B9= 9  9' 6 6	 B A= 9  9' 6 6	 B A= 9  9' B9= 9  9' 6 6	 B A=  9'! B9=   9'" B9=" 9"  9'# 6 6	 B A=# 9"  9'$ 6 6	 B A=$ 9"  9'% 6 6	 B A=%  9'& B9 9'' B9='  9'( B9=(  9') B9 9'	* B9=*  9'	+ B9=+  9'	, B9=,  9'	- B9=-  9'	. B9=.  9'	/ B9=/  9'	0 B9=0  9'	1 B9	 9'
2 B9=2 	 9'
4 B9=3 93 	 9'
6 6 6 B A=5 93 	 9'
8 6 6 B A=7 	 9'
9 B9
 9	': B	9		=	: 
 9	'; B	9			 9
	'< 6 6= B A
=
< 	 9
	'? 6 6 B A
=
> K  ÀpetBar_/petIconpetIconUISliderpetBar_bottom_centergroupBuff2_top_righthurtGroup/labelHurtshrineHurtLabel_pointGroup/labelshrinePointLabel_shrine_hurdle_nodeshrine_hurdle_node_groupBuff1_top_leftbottomLightheroNodeuiLayer_bottomLayer_mainLayer_buffBtnbtnPause_bottom_leftbtnSkip_btnSpeedbottom_rightspeedModeNodeImg2speedModeNodeImg1speedModeWordsspeedModeNodegroup_buff_detailgroupBuffDetailtrialAwardLevTexttrialAwardEffectNodeUILabelbossHpBarTextUIProgressBarbossHpBartrial_boss_nodetrialBossNodenewpngRound_topRound_/pngRound_height
width
en_en	langGlobalxydtopRound_/imgRoundimgRoundtopUISpriterectEnergyMask_imgBgTop_UITexturetypeofComponentByNameimgBgBot_gameObjectcenterNodeByNametransformwindow_					


      """"""######$$$$$$%%%%%%'''''')))))******++++++,,,,,,,,,---------/////0000002222233333333444444446PngNum self  winTrans centerObj topObj ñpngNum ÙbottomRightObj ZbottomLeftObj ntopLeftObj /?topRightObj #bottomCenterObj  ô  &8Ç9  9  X+ L 9  96 99 X9  996 99	9
 B:)   X
9  9	  X6 99= + L + L storyTablesub_stagegetPlotIdsactivityThermStoryTabletablesstage_idevent_data!LIBRARY_WATCHER_STAGE_FIGHT2BattleTypexydbattle_typeis_win
data_self  'stageID  b   	Ü-   9     9  - :)  B K   ÀÀ	playtrialAwardEffectself effectArr   !UÕ
9  )  =9 ' 6 9 B&=9 ' =-   9	) B6 999 B=
 9
  9' 3 B2  K  À new_trial_baoxiangsetInfotrialAwardEffectNodenew
SpinetrialAwardEffectgetRewardsEffect0trialAwardLevTextgetDisplayNumberxyd	0 / 	textbossHpBarText
valuebossHpBar	

NewTrialRewardTable self  "allDamage  "effectArr  ­   -   9   9  9  -  9  9  B-  9 9  BK   ÀspeedModeNodeImg2SetActiveactiveSelfgameObjectspeedModeWordsself v  ÛJÿáQ-   9 9 B6 94  =9  9+ B9  9+ B9 9	6 9
9 XQ6 99 96 99 9B A  9 B  X$6 99 96 99 9B A 9  9+ B6 99=   9 6   9 B*  )ÿÿB= 9  9B6 99  + B9  9+ B6 96 99 B-  9 ) B  9!  BXf9 9	6 9
9" X)6 99# 9$B  9% B  X9&  9+ B  9 6   9' B*  )ÿÿB= 9  9B )   X=6 99 :+ BX69 9	6 9
9( X6 99 ') + B9  9+ B6 96 99') BX )   X6 9=6 99 :+ B:  X6 99 :+ BX9  9+ B9 9	6 9
9* X9  9+ B6 99+ 9,9 B9- 6 99+ 9/ B=.9 9	6 9
90 X*61 6 992 939 9495B A   X9  9+ B9- 6 992 9/9 9495B=.6 9697 +  '8 B69 9:97 9;B3= =<9 9	6 9
9> X 9  9+ B6 99?=   9 6   9 B*  )ÿÿB= 9  9B9  9@) B  9!  B9 9	6 9
9A X 9  9+ B6 99B=   9 6   9 B*  )ÿÿB= 9  9B9  9@) B  9!  B'C 6 99D&6 9E9F 6 9G9H B9F  9IB2  K  ÀÀMakePixelPerfectBATTLE
AtlasimgRoundsetUISprite	langbattle_text_round_ activityLimitBossAwardTableLIMIT_CALL_BOSSgetDamage%activityIceSecretBossRewardTableICE_SECRET_BOSS onClickgameObjectGetUIEventListenerhero_challenge_nomal_iconspeedModeNodeImg1setUISpriteAsyncstage_idevent_datagetSkillIdspartnerChallengeTable	nextHERO_CHALLENGEgetSkillDesc	textspeedModeWordsgetIdByBattleIdpartnerChallengeSpeedTableHERO_CHALLENGE_SPEEDbattle_map_13_1GUILD_WARcheckShrineHurdleHurtshrine_hurdle_node_checkShrineHurdlecheckIsBossshrineHurdleModelSHRINE_HURDLEinitBossBargetDamageToBossinsert
tableimgBgTop_imgBgBot_setUITextureByNameAsync
StartcheckBossBarhandlergetTimer
timernewTrialRewardTablerewardTablegetBattleSceneBosscheckNeedTrialBossBargetBossId
trialmodelsgetBattleScenenewTrialBossScenesTabletables
TRIALBattleTypebattle_type
data_speedModeNodeSetActivetrialBossNodebattleMapGlobalxydbattleIDgetMapµæÌ³¦ý					



        !!!!"""######$$$%%%%%%%'''''*******+++++,,,,,,,---------0000000111111111111122222333333333334444445555599<<<<<<<=====>>>>??????????@@@@AAAAABBBBEEEEEEEFFFFFGGGGHHHHHHHHHHIIIIJJJJJKKKKNNNNNOOOOOOOOPPPPQQBattleTable NewTrialRewardTable self  map úmapPngStr !DallDamage @beforeScore "tableId l	allDamage ]allDamage 'roundSource 	  
  G}´+ =  6 99 9' B  X"6  B6 9' 	  X6 9	'
 X	 X6 9' = = 9  96 6 B A6 9 6 99	 B  9 B  X9  9+ B9 999 9 9)Ñÿ99B6 94  =K  aoeBuffEffect_BattlezySetLocalPositionlocalPositiontransformSetActivebtnSkip_isHideSkipCOMMON_Btn
AtlassetUISpriteUISpritetypeofGetComponentbtnSpeednewTimeScale_timeScale_new_battle_speed4QUADRUPLE_BATTLE_SPEEDnew_battle_speed2DOUBLE_BATTLE_SPEEDnew_battle_speed1BASIC_BATTLE_SPEEDtonumberbattle_speed_newgetValue	miscdbxydisStop		

self  Hval 
>type timeScale src sprite pos  À   %-Ò6  99 B6   9 B=6  99 B6   9 B=6  99 B6   9	 B=6  99
 B6   9 B=K  touchBuffbuffBtnpauseTouchbtnPause_touchSkipbtnSkip_onSpeedTouchhandleronClickbtnSpeedGetUIEventListenerself  & Õ   #Ù	6  99B 9' B  XK   9B9  X 9BK  mainLoopisBattleStart_resumeBattlebattle_windowgetWindowgetWindowManagerxyd	self  wnd 	 ö   3{ä9   XK    9 B4  4  ) ) ) M )  X 9 8  X	9 8	 9B  X6 9	 9
 8

BOé5 9 ==	=
6 99B 9'  BK  battle_all_buffs_windowopenWindowgetWindowManagerxydsideFightersselfFighterscallback  resumeBattleCallbackinsert
tableisDeath	teamstopBattlebattleEnds			
self  4selfFighters 	+sideFighters *  i needTable params 
 ë  
 %ü	9   XK    9 B5 9 =6 99B 9'	  BK  battle_tips_windowopenWindowgetWindowManagerxydcallback  resumeBattleCallbackstopBattlebattleEnds	self  params 
    9  =6 99B 9' 9  BK  pvp_vs_windowopenWindowgetWindowManagerxydpvpCallBack
data_self  callback   ½ 
  .6  99B 9' B  X! 9B6  99 X6  99	 9
B
  X )   X5 ==6  99B 9' 	 BK   BK  /time_cloister_crystal_battle_happen_windowopenWindowbattleCardIdscallback  'getThreeChoiceCrystalBattleCardIdstimeCloisterModelmodels
THREETimeCloisterMissionTypegetCurCloistertime_cloister_main_windowgetWindowgetWindowManagerxyd	self  /callback  /time_cloister_main_wd 	&curTimeCloisterId battleCardIds params 	
 Í H´4  9  96 99 XL 4  )    ) M'9	 8		 	 X

	 9
	B
8
  X)  <
	 X
 	 X
9
	 
 X9
  9

6 99
 X

	 9
	B
8
  X)  <
OÙ) 6 9	) M8	 	 X	)	  <	Oú-   9
 B L ÀgetBuffIdsGROUP_NUMFAIRY_TALEisMonstergetGroup	teamACTIVITY_SPFARMBattleTypexydbattle_type
data_
		

GroupBuffTable self  Ikey  Iresult GgroupNum 	>tNum =( ( (i &fighter $group group   i  ³   %Â
-     9   - ) B -     9  )  )  )  B -     9  ' )  B K  ÀÀtexiao01	playSetLocalPositionsetRenderTarget						
sp renderTarget  º	 L¿-   9   B6 99 B 9 3 B2  K     setInfonew
Spinexyd
getFxGroupBuffTable buffID  parent  renderTarget  fx sp  h    
×6   9  6  996 ' B A K  NO_GROUP_BUFF__	TIPSAlertType
alertxyd h    
ã6   9  6  996 ' B A K  NO_GROUP_BUFF__	TIPSAlertType
alertxyd ®
 h´¾)3    9 ) B6  B  X$9  9' 6 6 B A6 9	 6 9
9' :9&B 9+ B :99  B  9 9  ) BX6 99 B3 =  9 ) B6  B  X$9  9' 6 6 B A6 9	 6 9
9' :	9		&	B 9+ B :99  B  9 9  )	 BX6 99 B3 =K  À imgBuff2groupBuff2_ onClickGetUIEventListeneraddGroupBuffTouchSetActiveidgroup_buff_on_GROUP_BUFF
AtlassetUISpritexydUISpritetypeofimgBuff1ComponentByNamegroupBuff1_	nextgetGroupBuffID            !!!!""""""#######%%%%'')GroupBuffTable self  iinitEffect ggroup1 cimgBuff1 group2 &0imgBuff2  ­ ;¤ê  X'+  6  -  BX- 9-	 9		5
 9=
9=
B  X	9	
	 9		99	9
999! B	6	 9		-
 9

 B	 ERßX6 - 9B  X6  - 9BX6 99BERúK  À   ÀDestroyNGUITools	next
tips_insert
tableheightcontentylocalPositiontransformYgogroup7NumbuffID  idgroupBuffDetailnewipairs												buffIDs GroupBuffDetailTips self go  <isPressed  <lastItem %" " "k v  item 
"  _ tip    <é6  9 B3 =2  K  À onPressGetUIEventListenerGroupBuffDetailTips self  	obj  	buffIDs  	index  	 w   6  9  X)   X)    X+ X+    D checkConditionxyda  b   ù  ^¼-   9    B-   9   B-   9  	 B4  6 	 BH8 -  9 B  X) -  9 B8  X)   <FRé6 	 BH8-  9 B8  X)   <FRò6 	 BH8-  9 B8  X)   <FRò6 	 BH- 88B<FRùK     getResName
isAoe
pairsgetFxHurt2getFxHurt1
getFx	SkillTable FxTable getMax skillID  _data  _num  _skillIndex  _fxs Xhurt1 Rhurt2 LtmpData K  id fx curNum effectName   id fx effectName   id fx effectName   effectName  ¥ #¯1+  3  +  3 9 4  6  BX9
	6 9	B9	9	9	 9
	8)   X     9B AERê= 2  K  ÀÀeffectsCountgetSkillIndexpos	teamtargets
buffsskill_idtonumber
roundipairsframes  "$%&&&&'((()*+++,,,--------&&011SkillTable FxTable self  $getMax "getSkillEffect  frames tmpEffects   _ frame  round skillID buffs targets actor      	µK  self   Å   ?bÍ9  96 99 X9  96 99 X+ L 9 6 9 X9 6 9 X+ L 6 9	9
 96 99B96 9	9 9B)  X)  X6 96 996 ' B A+ L + L BATTLE_SPEED_ERROR_TEST__	TIPSAlertType
alertgetVipLevbackpackmax_stageCAMPAIGNMapTypegetMapInfomapmodelsQUADRUPLE_BATTLE_SPEEDBASIC_BATTLE_SPEEDnewTimeScale_	TESTSKIN_PLAYBattleTypexydbattle_type
data_						





self  @mapInfo &maxStage vip  ä   /GÞ  9  B' 9 6 9 X' X9 6 9 X' 9  9	6
 6 B A6 9 6 99 B6 9B  X	 ' &6 9 +   BK  _ios_testisIosTestCOMMON_Btn
AtlassetUISpriteUISpritetypeofGetComponentbtnSpeednew_battle_speed4QUADRUPLE_BATTLE_SPEEDnew_battle_speed2DOUBLE_BATTLE_SPEEDxydnewTimeScale_new_battle_speed1setNewSpeed								




self  0src_ +sprite     *Dî  9  B) 9 6 9 X6 9= ) X9 6 9 X6 9= )   X6 9= ) X6 9= 6 99 95	 =
BK  
value keybattle_speed_newaddOrUpdate	miscdbQUADRUPLE_BATTLE_SPEEDDOUBLE_BATTLE_SPEEDBASIC_BATTLE_SPEEDxydnewTimeScale_checkCanSpeed		


self  +canSpeed 'type & ±   )9  9  X9  = 6 9 BH9 8 99 BFRøK  setTimeScale	team
pairstimeScale_newTimeScale_self  
	 	 	id     #6  9 BH9 8 99 BFRøK  frameIndexsetFrameIndex	team
pairsself  	 	 	id  À 
 A«9    XK  + =  ) 9 99) M9 9 9 B9 96 6	 B A  X 9	BOí6
 9 BH9 8 9	BFRù) 9  ) M9 8 9BOú) 9  ) M9 8 9BOúK  
Starttimers_	Playactions	team
pairsresumeSpineAnimtypeofGetComponentgameObjectGetChildchildCounttransformuiLayer_isStop			self  B  i child spineAnim 	  id child 	  i action   i timer  ¿ 
 A«°9    XK  + =  ) 9 99) M9 9 9 B9 96 6	 B A  X 9	BOí6
 9 BH9 8 9	BFRù) 9  ) M9 8 9BOú) 9  ) M9 8 9BOúK  	Stoptimers_
Pauseactions	team
pairs
pauseSpineAnimtypeofGetComponentgameObjectGetChildchildCounttransformuiLayer_isStop		


self  B  i child spineAnim 	  id child 	  i action   i timer  5   Î+ =  K  isGuideStopBattle_self   µ  )@Ó9  6 989   X!6 99 99 B  X)  X
6 986 9 8 X	 X	6 986 9 8 L table_idisBossmonsterTabletablesisMonsterUNIT_ZORDERSxydpos
hero  *pos (zOrder % }   0à-    B-   B X  X+ X+ L + L ÀgetZOder a  b  aNum bNum 
 }   0è-    B-   B X  X+ X+ L + L ÀgetZOder a  b  aNum bNum 
 /   9  9 !L zOrdera  b   ð íÒB3  6 99 3 B6 99 3 B4  = 9  ) )ÿÿM9 86 9	9
B  X9
9  X  9 	 6
 9

9

9+   B A9 9	<	Oä9  ) )ÿÿM49 86 9	9
B  X9
9  X'+ 
  X9

  X	9
9
  X9
9	  X+   X	  9 
 6 9996 9 +   BB9	 9
6 9 

<
	OÌ9   X
9   9 9 6 99) B>9   X
9   9 9 6 99) B>9   9 B>6 99 3 B  9 B  9 B2  K  getFinalBossHitresetZorders newGod	petBnewPet	petATEAM_B_POS_BASICB	teamposATeamTypexydnewFighterhpstatusisnull
toluazOrders_ herosB herosA	sort
table    !!!!!!!!!!""""""""""""###'''''(())))))))))*+++++++++++++,..////////////////000000'44455555555557778888888888;;;;;<<<><@@@AAABBself  getZOder   i hero fighter 5 5 5i 3hero 1isInit &fighter   	  #ò6  99 9 B9  96	 6
 B	 A9 9 <6	 9
9'	 B9B
 9	  9 9 9 B	
 9	 B	
 9	9 B	
 9	 B	
 9	 B	
 9	  B	
 9	B	6
 9

6	 989 :	 B
)   9B  X+)   X)  X)  X6	 9896	 989 9 " X X	 X6	 9896	 989 9 " X6	 9899 " 6 9:	 6	 9
9"B 9  5! =
=< 9"
  )  BL SetLocalPosition  herosPos_unityPosYFlipyisBossxHeroBattlePos
round	mathgetModelOffsetsetWndsetPosIndexsetTeamTypetimeScale_setTimeScalesetBaseDepthscreenScaleYbottomLayer_uiLayer_populatenewBaseFightergetRequireBattlexydnodeGroups_
depthUIWidgettypeofGetComponentheroNodemainLayer_AddChildNGUIToolsãõÑð£áÿÿ				



self  hero  teamType  pos  flipX  zOrder  group depth 	fighter 	woffset Xx 
Ny M Í    2¶6  99' B9B 99 9 9 B 9	9
 B 96  99B 9) B 9  BL setWndsetPosIndexATeamTypesetTeamTypetimeScale_setTimeScalescreenScaleYbottomLayer_uiLayer_populatenewBaseGodgetRequireBattlexydself  !fighter  Ô   HÀ6  99' B9B 9 9 9	 9
 B 9	9
 B 9 B 9 B 9  BL setWndsetPosIndexsetTeamTypetimeScale_setTimeScalescreenScaleYbottomLayer_uiLayer_populatenewBasePetgetRequireBattlexydself   pet   teamType   pos   fighter     Ê9   9B9  X9   95 9 =BK  num iconNamebattle_roundsetInforoundNumgetNumpngRound_self     	 \Ô6   -  9B HK-  98 9B)  XB 9B  X=) 6  B)  X)ÿÿ 9 B 9B 9B-   9B  X-   9	B  X-   9
B  X 9B6 99 X 9B 9+ B 9+ B 9B 9BFR³-     9  B -  
   X -  B K   ÀÀresetZordersupdateMpBarupdateHpBarsetNeedHideHeadViewSetActivegetHeadViewBTeamTypexydgetTeamTypecheckNeedLimitBossBarcheckNeedIceBossBarcheckNeedTrialBossBarinitHeadViewresumeIdleinitModeltonumbergetFighterModelgetPosIndex	team
pairs			


self callback N N Ni Kfighter HdirectX_ < T  Ó  9  ) 3 +  B2  K   waitForFrameself  	callback  	    ø-     9   B 6  9  ' B -     9  B K    playSecondStorybattle_loading_windowcloseWindowxydcreateEffectsself  §  õ	6   9  9  B   9  ' B    X  9 3 BK     setCallBackbattle_loading_windowgetWindowgetWindowManagerxyd	self wnd 	 D  ô-     9   ) 3 B K   À waitForFrame
self  C  ó  9  3 B2  K   loadFighterModelself   ô  2[)    XK  6  99 9-  B6  99 9B8  X9  X99
  X99	99 X6
 9B-  =6  99B 96  99 BK  PARTNER_END_STORYmidrequestgetBackendstage_idpartner_end_story_reqmessages_pbfight_max_stagepre_stagebase_infogetMapListheroChallengemodelsgetFortIDpartnerChallengeTabletablesxyd		










stageId id  3fort_id 'cur_data  msg  þ  2[ª)    XK  6  99 9-  B6  99 9B8  X9  X99
  X99	99 X6
 9B-  =6  99B 96  99 BK  PARTNER_END_STORYmidrequestgetBackendstage_idpartner_end_story_reqmessages_pbfight_max_stagepre_stagebase_infogetChessMapListheroChallengemodelsgetFortIDpartnerChallengeChessTabletablesxyd		










stageId id  3fort_id 'cur_data  msg  º7áÍP9  99  99  9  X9  99  X9  994  6 99+  6 99 X)-   9	 B)
  X6 9
9 9'	 '
 B6 9B X+  X6 9
9	 9
 B X6 9
9 9	 B X{6 99 X6 99 9 B  X6 9
9 9 B 6 993 X`6 99 X6 99 9 B  X6 9
9 9 B 6 993 XE6 99 X6 9
9 9  B 6 99X46 99! X6 9
9" 9  B 6 99#X#6 99$ X6 9
9% 9  B 6 99&X6 99' X6 99( 9)6 9*9'B9+6 99#6 9,9-	  X  X:  X:)   X9.  9/+ B6 90'1 52 :	=	3=4=5B2  K    96 B2  K  ÀplayStartActionsave_callbackstory_typestory_id isShowSwitchis_backstory_windowopenWindowSetActivemainLayer_isReviewGlobalnowPlotIDActivityIDgetActivityactivityACTIVITY_ANGLE_TEA_PARTY
OTHERnewPartnerWarmUpStageTableNEW_PARTNER_WARMUPACTIVITYactivityThermStoryTable!LIBRARY_WATCHER_STAGE_FIGHT2getPlotIdsactivityNewStoryTable LIBRARY_WATCHER_STAGE_FIGHT partnerChallengeChessTablecheckPlayChessStoryHERO_CHALLENGE_CHESS PARTNERplotIdpartnerChallengeTablecheckPlayStoryheroChallengemodelsHERO_CHALLENGEgetPlotIDsByStageIDmainPlotListTablegetServerTime
valuenew_story_lock_timegetNumbermiscTabletablesgetFortIDCAMPAIGNBattleType	MAINStoryTypexydevent_datastage_idbattle_type
data_ 					




$$%%%%%%%%%%%%%%&&&&&&&&'''446666677777777888899999::::::::;;;;<<<<<========>>>>?????@@@@@@@@@@AAADDDDDDDDDDDDDDEEEEEFFFFGGHJFMMOOOPPStageTable self  âbattleType ßstageId ÝplotIds ÐstoryType Ísave_callback Ìfort_id 
#timestamp  û   ;â-     9   - B    X-  6 99  X -    9  B X -    9  B K    À ÀshowBattleSoundshowEnemyEffectHERO_CHALLENGEBattleTypexydisShowBattleEffectStageTable stageID battleType self  ® JÔ6  99 99 B  X6  99B 9 B9   X2 49  9	+ B9
 99
 99
 9  X9
 99  X9
 993 6  9 B  X  9  BX6  99 X6  99 X  9  BX B2  K  K  À showTimeCloisterBattleCardsTIME_CLOISTER_EXTRATIME_CLOISTER_BATTLEBattleTypeshowPvpWindowcheckShowPvpWindow event_datastage_idbattle_type
data_SetActivemainLayer_playSoundgetSoundManager
name_openSoundwindowTabletablesxyd		

StageTable self  JsoundID BbattleType -stageID +callback  6   ü-     9   B K    destroyeffect  æ 5ù-     9   - ) B -     9  - 9- 9 -  B -     9  ' ) ) 3 B K  ÀÀÀÀ texiao01	playyxSetLocalPositionsetRenderTargetÈeffect renderTarget pos i  Ö  1	6   9     6  99) M -  98  X-  98 9+ BO óK   ÀSetActivenodeGroups_MAX_TEAM_NUMBattleTEAM_B_POS_BASICxydself   i group  <   	-     9   B K   ÀshowBattleSoundself  § 8sò6  9 6  99) M"9 8  X9 8999  96		 6

 B	 A6  999	 B
 9	6  993 B	
 9	+ B	2 2 OÞ  9 ) 3 ' B  9 * 3 ' B2  K    waitForTimeSetActive effect_battlecoversetInfomainLayer_new
SpineUITexturetypeofGetComponentuiLayer_localPositiontransformnodeGroups_MAX_TEAM_NUMBattleTEAM_B_POS_BASICxyd³æÌÌóÿself  9# # #i  group pos renderTarget effect  5    	-     9   B K   ÀmainLoopself  ¸ "4	9  	  X2 9 )    X9 )   X9 9 8  X  9 4 >6 99B  9 * 3	 '
 B2  K  K   waitForTimeBATTLE_DIALOGPartnerBattleDialogxydshowDialog	teambattleSoundbattleSoundPosbattleIDÂÿself  "fighter 
 G   Ò	-     9   - B K     processReviveself frame  6   Û	-     9   B K    checkEndsself  Ó 	
I½	!-     9   - B -     9  - B *  * - 	 X) 1 	  X) 	  X+  X+     X6 9-  )  B-   9 3 B6 9  6 9-   B)  B- 9	 X-   9- B -   9- B -   93	 BK       getRoundEndActiongetCurFrameBuffEffectTimepos schedulecheckConditionxydcheckAnyReviverefreshTeamµæÌ³¦þ³æÌÌÓÿ ÉÂë£×ÇÂþ		
 !self frame anyDead anyRevive ?tDead >tRevive =tProcessRevive tNext   :·	(-   9   	   X -    9  -  B -    9  -  + B -  9-  B-  9 3 B2  K  À À schedulegetCurFrameBuffEffectTimeupdateAllBuffsplayRoundEndActionpos '((frame self anyDead delay   oÏ¥	Q9    X2 j+ =   9 B9  =   9 B9 9 89  X4  =
  XS9=   9	 B9
 X9
	 X	9 =   9 * 3 B2  K  9 9
89 9
84  4  6 9BH		9
 98	8

6 9 
 BF	R	õ6 9BH		9
 98	8

6 9 
 BF	R	õ9
)  X  9  	 6
 9B
  BX
  9  	 6
 9B
  B2  K  K  playPetskill_idtonumberplayActortargets_2insert
tabletargets
pairs	teamnodeGroups_ schedulealreadyFinishRoundposupdateRoundLabel
roundroundNum
buffsframesupdateFrameIndexframeIndexupdateSpeedisBattleStart_isStop µæÌ³¦þ			

:;;===>>>?@CCCCDDDDEEEEECCGGGGHHHHIIIIIGGKKKKLLLLLLLLLLLNNNNNNNNNNQQself  oframe \group <actor 9actees1 8actees2 7  id 	actee 
  id 	actee  Ã y«ø	")  9 6  BXp8	9
	+  9	  X9	)   X9 9	8  Xa6 9
 X9	9  X  9	 	 B6 9
  X+ X+   B XI 9B-   9
  B-   9
 B  X:  X-  9:B6 9
  X+ X+   B X%6  B  X )  6  BX-  9 B  X-  9 B  ERð6 9
  X+ X+   B ERL 	ÀÀgetHurtSecondDelay	nextgetSpeed
getFxheroWorkFxgetModelIDcheckConditiongetHoldBuffTimeBUFF_ONbuffOnBUFF_ENERGY_SKILL_HOLDxyd	team
f_pos	nameipairs
buffs<

!DBuffTable FxTable self  zframe  zt_ xbuffs ws s sid p_  pbuff obuffName nbuffFighter mduration modelID FheroWorkFx @fxs ;duration 
duration   k fx   ¾ 
 	 x
6  99)  9+  9  X9)   X9 98  XL  9' B 9'	 B L skill02skill01getAnimationTime	team
f_pos	namemodelTabletablesxyd		
self  buff  ModelTable duration buffName buffFighter time1 time2 duration    ®
9  96 99 X9  9	  X+ L + L stage_id
TRIALBattleTypexydbattle_type
data_þÿÿÿself   Á   )µ
6  99 9B  X)    X9 99X+ X+ L isBossevent_data
data_checkIsBossshrineHurdleModelmodelsxydself  beforeScore  {   º
9  96 99 X+ L + L ICE_SECRET_BOSSBattleTypexydbattle_type
data_self   {   Á
9  96 99 X+ L + L LIMIT_CALL_BOSSBattleTypexydbattle_type
data_self   J   ð
-     9   ' )  B K  Àtexiao02	playeffectAnim  Ý / Þ§È
/+  9  989)  9  X4  9  X4  6  BX
È96 9 X96 9	 X9  98  X5 6 9
9B=96 99 X+ X+ =96 99 X+ X+ =96 99 X+ X+ =9  X)ÿÿX9=9  98 9B 9B X+ X+ 6 9 9B6 9B  X) )  X6 9 9B   X	)   X96 9 XX69  X9)   X9  X96 9 X'6 9B)   X!9
  X6 9B6 9B X  9   6 9B99 B6 9  X+ X+   B 96 9 X96 9 X!9  9 8 9!6 9"9#B 9$'% B  X9& 9'6( 6) B A 9*'+ ) B 9,'- 3. B2 E
R
62  L  CompleteaddListenertexiao01	playSpineAnimtypeofGetComponentgameObjectyueyingNodeByNameBUFF_TOPBaseFightLayerTypegetLayerByType
f_posBUFF_WEI_WEI_AN_HEALBUFF_DEBUFF_CLEAN_2_LIMITcheckConditionplayActeeskill_idBUFF_HURT_0effect_indextonumberarrayIndexOfgetTeamTypehpisFree	FREEisCrit	CRITisMiss	MISSBuffType	type  
valuegetBattleNumBUFF_ENERGYBUFF_REVIVExyd	nameipairstargets_2targets
buffspos	team	




!!!""""""####$$%&&&&&&'''''(((*(*..self  ßframe  ßactor Ýbuffs ÙfloatTime Øtargets Ôtargets2 ÐË Ë Ë_ Èbuff  Èresult :cactee `isEnemy UtargetIndex PeffectIndex JtmpT ?actor layer buffEffect effectAnim 	
 Ì  	 $3ù
6  9 X6  9 X6  9 X6  9 X6  9 X6  9 X6  9 X6  9 X+ L + L BUFF_DOT_MAX_HPBUFF_ANSUNA_DOTBUFF_DOT_FIRE_MAX_HPBUFF_DOT_TWINSBUFF_DOT_FIREBUFF_DOT_BLOODBUFF_DOT_POISONBUFF_DOTxyd		self  %name  % ü  @9   XK  6 9 BX9 98  X9 98 99	B9	  X  9 9	+
 BERêK  updatePetEnergyepupdateEnergypos	teamipairsepsself   frame     k v   ²  1±-   - 9=  -     9  ' -  9B &)  B K   ÀgetValuetexiao0	playtimeScale_timeScaledieEffectAnim self buffFighter  Ô   6Á-   - 9=  -    9  -  B -     9  ' )  B -    9  -  )  B K  À ÀstartAtFrametexiao02	play	stoptimeScale_timeScaledieEffectAnim self buffFighter  &vÅ¸+ +  9  9894    9 	 B6  BX
u+  9  X9)   X9  9896 9 XQ9	9
  XM9 9B XG)  96 99B 9' B6 96 9B) B +    X9 96 6 B A   X& 9B)  X  9 B 9B 9 9BB 9'  9B&) B9  = 9!'" 3# B2 96 9$ X) 96 99B 9'% B9 96 6 B A  X 9& B 9'' ) B 9( )  B9  = 9!'" 3) B2   9*  B  Xß96 9+ XÚ96 9, XÕ96 9 XÐ5. 6 9-9B=9/6 9091 X+ X+ =29/6 9093 X+ X+ =49/6 9095 X+ X+ =697 X+ X+ =899  X)ÿÿX99=96 9-9:B=:-   9;9B	 X)ÿÿ=99  9892  X59  X299)   X.6 9<B)   X( 9=B 9=B X+ X+   X  9>  9B  X  9?   B  X  9@ 9B  X99)   X 9AB99)   X	 9BB  X 9C99B9D  X 9E9DB-  9F9GB9G  X9-   9H B  9I  B-  9J9<B	 X+ X-  9J9<B	 X+   X-   9K B  X
-  9L  B  X+ =M9	9N  X
9	9
  X  9O  B  X 9P9 B9	9Q  X
96 9R X 9P9 B96 9S X+ =T 9U9B99)   X9  X
9	9V  X  9W 9B  X	92  X96  X9:  X9)    X  9?   B  X 9X B9	9Y  X9	9N  X 95Z 9=9=9G=GBX79	9Q  X9	9V  X/ 9[5\ 9=9=B96 9] X96 9^ X96 9_ X96 9` X
96 9a X96 9b X	 9P6c 9B'd & B96 9e X 9f99	9Y  X+ X+ + B96 9g X9	9Y  X 9h9BX 9i9B96 9j X9	9Y  X 9kB96 9l X9	9Y  X+ =T99	 X/+   9m  B  X 9i6 9aBX"96 9n X 9oBX  9p  B	 X 9qBX	 X 9rBX		 X 9sBX 9tB2 E
R
}
 X  9u 	 B2  L 	ÀÀÀ
ÀrefreshTeamdie	die5	die4	die2keepCorpse	die3BUFF_EATcheckFakeDeathBUFF_ENERGY_SKILL_LIMITholdEnergyPoseBUFF_ENERGY_SKILL_HOLDremoveBuffplayExchangeSpdBUFF_EXCHANGE_SPDplayGetLeafBUFF_GET_LEAFBtostringBUFF_FULL_ENERGY_HURTBUFF_FEISINA_EXPLODEBUFF_GET_HEAL_CURSEBUFF_RIMPRESS_HP_LIMITBUFF_RIMPRESSBUFF_CIMPRESS  removeBuffs  BUFF_ONrecordDamageNumbercheckNoRecordNumBUFF_REMOVEplayTransformisHoldEnergyPoseBUFF_TRANSFORM_BKBUFF_DOT_POISONBUFF_OFFplayBuffEffectcheckBuffPlayEffectBUFF_ON_WORKisRestarintisRestraintisDmgRestarintsgetIsAddEnergygetMpKey
isDmgtable_idgetTypeupdateShieldHpBarshieldupdateHpisDeathattackedcheckPlayAttackedcheckHasExceptDotShieldcheckHasFreeHarmgetTeamTypeskill_idgetIsHpChangeshieldCosthpisBlockis_blockisFree	FREEisCrit	CRITisMiss	MISSBuffType	type  getBattleNumBUFF_ENERGYBUFF_REVIVEcheckGodBuff startAtFrametexiao03	stopfuhuo_fx1BUFF_APATE_HURT CompleteaddListenertimeScale_timeScaletexiao0	playsetValuerefreshBuffIconsaddBuffsgetValueSpineAnimtypeofGetComponentgameObject
valuetonumbermax	mathfuhuo_fx2NodeByNameBUFF_TOPBaseFightLayerTypegetLayerByTypegetPosIndexBUFF_WORKbuffOnBUFF_APATE_REVIVExyd	name
f_posipairsupdateEnergys
buffspos	team 
							


!#####$$$$$$%%%%&&&&&&&''(((()))))*****++,,,1,244444444444444445555567777788888888889999999999::::::::::;;;;;;;<<<<<<<=====???????@@BBBCCCCCCCCCCCCCCCCDDDDDDDDDDDFFFFFFFFGGGGGGGHHHHHIIIIIIJJJMMMMMMMMMNNNNPPPQQQQSSSSSTTTUWWWWWXXXXYYYYYYYZZ[[[[[[[\^^^^^^^^^^^^^^^^^__aaaaaaaaaaaaaabbbbbeeeeeeeeefffffiiiiijjkkkkmmmmmmmmmmmmmmmmnnnnnnnnnnoooooooooooppppsssssssstttuuvvwwtxyyyyyyyyzzz{{||z~~~~~ ¡¡¡¡¡¡¢¢¢¢¢¢£££££¤¤¤¤¦¦¦¦§§¨¨¨¨©©ªªªª««¬¬¬¬®®®²´´µµµµ··DBuffTable EffectTable SkillTable GroupTable self  frame  isRoundEnd  anyDead actor buffs dieActee ø ø øindex õbuff  õbuffFighter ólayer  ?dieEffect ;value 3dieEffectAnim 2layer >"dieEffect dieEffectAnim result dactee isEnemy firstName 6¼isDmg 	³mpKey ¯keepC  y  Ð9   X+ L 96 9 X+ L K  BUFF_BOSS_STORMxyd	nameposself  buff   µ   <OÙ6  9 X46  9 X06  9 X,6  9 X(6  9 X$6  9 X 6  9 X6  9 X6  9 X6  9	 X6  9
 X6  9 X6  9 X6  9 X+ L + L BUFF_GET_HEAL_CURSEBUFF_TIME_RULEBUFF_GET_ABSORB_SHIELDBUFF_DEBUFF_CLEAN_2_LIMITBUFF_CLEARBUFF_IMMENUBUFF_GET_REFLECTBUFF_DEBUFF_TRANS_ALLBUFF_EAT_FREEHARMBUFF_FREE_HARMBUFF_DEBUFF_CLEANBUFF_TRANSFORM_BKBUFF_REVIVE_INFxyd				



self  =buffName  =    eí+ + 6   BX9
	
 X
9
	6 9
 X
9
	9 
 X
+ X
+ ERï  X  X+ L BUFF_OFFbuffOnBUFF_FREE_HARMxyd	nameposipairsself  buffs  acteePos  flag freeHarmBuffOff   _ buff   ÿ  	+{ÿ9 + + 6  BX	9 
 X9
6 9 X9
9  X+ X+ E	R	ï  X  X+   9 9B  X9  X9	  X+ L isHarmbuffIsDotBUFF_OFFbuffOnBUFF_EXCEPT_DOT_SHIELDxyd	nameipairspos 	self  ,buffs  ,buff  ,acteePos *flag )dotShieldBuffOff (  _ buff   Z   6  9 X+ L + L BUFF_XIFENG_SPDxydself  	buffName  	 §   2
6  9B  X'  ' 9&9  X ' 9&L 
f_pospos|nilskill_idtonumber	self  buff  skill_id key  £ v«+   ) M8	  9
  	 B
-   99	B  X

 X9	6 99 X+ XOéL 	À	CRITBuffTypexyd	type	name
isDmggetMpKeyDBuffTable self  mpKey  index  buffs  isCrit   i buff tmpKey isDmg  ç * Êï¹.9 9  X´-   99B  Xª96 9 X¥96 9 X 96 9 X96 9 X96 9	 X96 9
 X96 9 X96 9 X96 9 X}96 9 Xx96 9 Xs96 9 Xn96 9 Xi96 9 Xd96 9 X_96 9 XZ96 9 XU96 9 XP96 9 XK96 9 XF96 9 XA96 9 X<96 9 X796 9 X296 9 X-96 9 X(96 9 X#96 9  X96 9! X96 9" X96 9# X96 9$ X
96 9% X96 9& X+ L X9 9'  X96 9( X96 9) X+ L + L 	ÀBUFF_DOT_TWINSBUFF_HOT_HUATUOBUFF_OFFBUFF_ABSORB_DAMAGEBUFF_FEISINA_MISSBUFF_APATE_ENERGY_HURTBUFF_FULL_ENERGY_HURTBUFF_GET_LEAFBUFF_GET_THORNSBUFF_EXCHANGE_SPDBUFF_WULIEER_SEALBUFF_GET_HEAL_CURSEBUFF_GET_ABSORB_SHIELDBUFF_ADD_GET_LIGHTBUFF_GET_LIGHTBUFF_HURT_SHIELD_LIMIT3BUFF_HURT_SHIELD_LIMIT2BUFF_HURT_SHIELD_LIMIT1BUFF_FRAGRANCE_GETBUFF_HURT_BY_RECEIVEBUFF_WEI_WEI_AN_HEALBUFF_STAR_MOONBUFF_MOON_SHADOWBUFF_CRYSTALLIZEBUFF_MARK_CRYSTALBUFF_CRYSTALLBUFF_BIMPRESS_LIMIT30BUFF_MIND_CONTROLBUFF_FRIGHTENBUFF_DEC_DMG_SHIELD_LIMIT5BUFF_FREE_SHIELD_LIMIT5BUFF_SHIELDBUFF_OIMPRESSBUFF_FIMPRESSBUFF_RIMPRESS_HP_LIMITBUFF_RIMPRESSBUFF_CIMPRESSxyd	name
isDotBUFF_ONbuffOn					




     !!!!!"""""#####$$$$$%%%%%&&'(((())))))))))**--DBuffTable self  Ëbuff  ËisDot 
® Á  G±é)  =  9  ) )ÿÿM?9 84  6 9BX
6 9  B)   X6 9  BE
R
ñ6 9BX
6 9  B)   X6 9  BE
R
ñ)  )	 M8
9	 8  X 9
B	  X=  XOó9   XXOÁK  getTeamType	teamtargets_2insert
tablearrayIndexOfxydtargetsipairsframesfinalBossHitFrameIndex 





self  H@ @ @i >frame <actees ;  _ id    _ id    index id fighter 	 ½	 ¹26  9B9 98  X9  X-   9  9B A-   9 	 9B A  X  X X  9 B4  6	 9
BX6
 9

 	 B
)  
 X
6
 9

 	 B
ERñ6	 9BX6
 9

 	 B
)  
 X
6
 9

 	 B
ERñ)  ) MG8	9
 8
	
 
 XA
 9
B  9 B  X	
 9
B	 X  9  B  9 B  X	
 9
B	 X  9  B  9 B  X	
 9
B	 X  9  B  9 B  X	
 9
B	 X  9  B
 9
B
 9
BO¹K  ÀclearBuffOffrefreshBuffIconscheckShrineHurdlecheckNeedLimitBossBarcheckNeedIceBossBarbossHurtgetTeamTypecheckNeedTrialBossBarplayAllDamageNumberstargets_2insert
tablearrayIndexOfxydtargetsipairsplayShakeshakeTimegetSkillIndexisShakepos	teamskill_idtonumber
     !!!!$$$$$%%%%%&&&&)))))*****++++...///2SkillTable self  frame  skillID fighter isShake shakeTime 	actees 
r  _ id    _ id  H H Hindex Fid Efighter CtotalHarm > Ê
  §Ã»;9    X	9 9  X9  = 9  = 9 ) 9 9  X  X6 99 9	B 9
9 B 9 B 9 B!#	 X 
 9	 B	 9
 B
!	
	#	9  9	 	 X9 9	 !	9  +	 
  
 X
+	  X
 9
B

  9
 B

 
 
 X
+	 !
!#

6 9 B  	 X

  X9 9
 X  9  B9 =
9 6 9 B' 6 9 B&= 	 X9 ) = 9 B9 6 9 B' 6 9 B&=9  9
 B=9  = 9 96 99 X	  9 B  X  9 9 BK  finalShowShrineHarmcheckShrineHurdleSHRINE_HURDLEBattleTypebattle_type
data_trialAwardLevText / getDisplayNumber	textbossHpBarTextplayTrialAwardEffect
valuebossHpBar
floor	mathgetDamageToBossgetLevByDamagegetIds activityLimitBossAwardTabletablesxydrewardTableBossShowedHarmBossHarmfinalBossHitFrameIndexframeIndexrealBossHarm 			     !!!!!""""#'''(((((********++++..////////////0011122223333333333335555556668888888888889999;self  ¨RewardTable barSpeed awardIDs |nowLev xallDamage talreadyLevDamage padditionNum nmaxId 
nowDamage WisFinalLev Vvalue =finalDamage ( b   	-   9     9  - :)  B K   ÀÀ	playtrialAwardEffectself effectArr  â	 Eø9   X2 =  -   9 B9   X9  9:) ) 3 B2  K  K  À 	playtrialAwardEffectgetRewardsEffectAwardId
NewTrialRewardTable self  id  effectArr  ®  =)   XK   )  9  96  BX6
 9	B
6 
 B)  X6 
 B	  X6 99	B ERë=	 9
 9  X= 9 =   9 BX9   X9 9 ! = X9  = K  checkBossBarBossShowedHarmBossHarmfinalBossHitFrameIndexframeIndexrealBossHarm	hurtgetBattleNumxydtonumberpostostringipairs
hurtsbattleReport_											



self  >hurtNum  >harmNum 8maxHarm 7hurts 5  _ hurtData  pos hurt  ø 5½¢ 9 B-  4  ) ) ) M
 9	  B	
	  X
	  X
)
 ) ) M
6 9 -  9	  B A O
ôOæ6  BX-
 
 9

	 B
6 9
 X
+
 L
 ERóK  ÀÀÀBUFF_REVIVE_INFgetTypeipairsgetEffecttableConcatxydgetPasSkillgetHeroTableID 											PartnerTable SkillTable EffectTable self  6fighter  6id 2table 1effects 0  i pasSkill   j   _ effect   ý O­¶9  9 8)  + 6 9BXB9
	 9B
 X
+9
	6 9
 X
&9
		9
 
 X
"6
 9	B
)  
 X
	6
 9	B

 X
+ X
 X
+   X
-
  
 9

9	+ B
 
 X
 	 X) L X) L 9
	 9B
 X
9
	6 9
 X
9
		9
 
 X
)
 L
 ER¼)  L ÀBUFF_APATE_REVIVEtable_idgetNum
valuetonumberBUFF_ONbuffOnBUFF_REVIVExyd	namegetPosIndexpos
buffsipairsframeIndexframes
EffectTable self  Pfighter  Pframe LselectIndex KhasBuff JE E E_ Bbuff  BeffectArr '
 é   *RÕ)  6  9BX"96	 9			 X99	 	 X99	 	 X6 9		 )
 B 96	 9	
		 X
99	 	 X6 9		 )
 B ERÜL BUFF_OFFBUFF_APATE_REVIVEmax	mathBUFF_ON_WORKBUFF_WORKbuffOnBUFF_REVIVExyd	name
buffsipairs
self  +frame  +time )% % %_ "b  " Ô   [¥â + 6  9BX96 9 X+ XER÷6  9BXF96 9 X 99  X99  X9	 9
8  X	 99
B  X	 9)
  B	 9B	 9'
 + + B96 9 X99  X9	 9
8  X	 99
B	 9)
d B	 99
9B	 9'
 + + BER¸K  
valueapateReviveBUFF_OFFBUFF_APATE_REVIVEplayGetLeafreviveupdateEnergyhpupdateHppos	teamBUFF_ON_WORKBUFF_WORKbuffOnBUFF_REVIVEBUFF_ENERGYxyd	name
buffs__TS__Iterator													


 self  \frame  \hasEnergyBuff Z
 
 
b I I Ib Factee actee ! =   -     9   B K   ÀplayBattleResultself  ñ CK  9  B9  X+ 2 :6 99  X9   X9 9   X+ =   9 B  X  9	 ) 3
 B+ 2  L   9 B+ 2  L X6 99  X9 9  8  X  9 + B2  K    9 B+ 2  L L mainLoopshowUnAutoBtnplayBattleResult playStorycheckPlayAfterStoryframesframeIndexunAutoEnd_unAutoBattlexydbattleEndsresetZorders
self  C    +6  9 BH	6  B)  X 9BFRõK  resetZOrdertonumber	team
pairs						


self    pos 	v  	 ®   Tw«9  96 99 X9  96 99 X9  96 99 X9  96 99 X+ L 6 99	 9
B6 99 9' ' B6 99 9' ' B9  96 99 X X9   X+ L X
 X6 96 ' B A + L 9   X+ L + L BATTLE_SKIP_ERROR__alertTipsisTouchSkip_
TOWERtower_skipfight_level
valuebattle_skip_levelgetNumbermiscTabletablesgetLevbackpackmodels	TESTPARTNER_STATIONSKIN_PLAYGUILD_WARBattleTypexydbattle_type
data_			

self  Ulev %0needLev (towerLev      +S¿9  99  99  9  X9  99  X9  99+ 6 99 X6 99 X	6 99	 9
 B  X6 99 X+ L  LIBRARY_WATCHER_STAGE_FIGHTcheckHideSkipheroChallengemodelsHERO_CHALLENGECAMPAIGNBattleTypexydevent_datastage_idbattle_type
data_							
self  ,battleType )stageID 'isHide  }   Î  9  B  X+ L + =   9 BK  openSkipWindowisTouchSkip_checkCanSkipself   =   ñ-     9   B K    playBattleResultself  ï );ì6  99B 9' B  X   X-   9B  X-   9) 3 B2  K   9+ BX	 9	B9
  X 9BK   ÀmainLoopisBattleStart_resumeBattleplayBattleResult playStorycheckPlayAfterStorybattle_windowgetWindowgetWindowManagerxyd




self yes  *wnd 	!   è+ =    9 B6 96 ' B3 B2  K   SKIP_BATTLE__alertYesNoxydstopBattleisTouchSkip_self    
 c°  X+ 6  99B 9B9  )   X) 9  ) M9 8 9BOú9 96  99		  X06  9
9 X6  9
9 X
6  9
9 X6  9
9 X9 99 9 =9 9  X9 99  X9 996  99B 9  	 BX9 9 =6  9 9B 95 6  99==BK  	data	name  BATTLE_END
eventdispatchEvent
innerEventDispatcherplayThirdStoryBattleControllerevent_databattleReport_real_battle_reportstage_id LIBRARY_WATCHER_STAGE_FIGHTHERO_CHALLENGE_CHESSHERO_CHALLENGECAMPAIGNBattleTypeisReviewGlobalbattle_type
data_stopSoundsoundEffects_stopBggetSoundManagerxyd 			self  disSkip  d  id effect battleType GstageId data data  !     K  self  params   k  	£-  9 9  B  9 BK   ÀclearConfigwillClose
superBattleWindow self  
 O  ¨-  9 9  BK   ÀdidClose
superBattleWindow self   ¤   -b­6  94  =6 9 BH9 8 9BFRù  9 B  9 B6  94  =) 9	  ) M	9	 8 9
B 9BO÷4  =	 6 9BK  ForceGCCollectResManager	Kill
PauseactionsbattleMapclearSoundsclearEffectclearAction	team
pairsretainDragonbonesGlobalxyd					

	self  .  i fighter 
 
 
i action  Å <ÙÀ4  6  9 BH  X9 8 9B6 9	 
 B)	  	 X6 9	 
 BFRê6 9 ' B)  ) M8-   9	 B6	 	 BX-  9
 + BERøOí-  9BK  ÀÀclearEffectListclearEffectsipairsgetResNames	buffinsert
tablearrayIndexOfxydgetModelName	team
pairsResourceEffectTable BattleEffectFactory self  =groupNames ;  i fighter modelName   i modelName names 	 	 	_ name_  flag       	ÚK  self   5    ô-   
   X -   B K  Àcallback  « #Që6  9)    X+ X+  )  B 	  X
  X B2 +  3   9 B 9 B 9 B2  K  K  AppendCallbackAppendIntervalgetTimeLineLite checkConditionxyd self  #time  #callback  #complete action 
 õ 
  #N	6   BX9)	 	 X
9)	 	 X9)	 	 XL X9)	 	 X	9)	 	 X9)	 	 XL ERã:L posIndexipairsself  $actor  $actees1  $  k v   A   Ó-     9   - B K  ÀsetZOrderactor z2  9   Ù-     9   B K  ÀresetZOrderactor  O   û-     9   - :B K   ÀplayShakeself tmpShakeTime     -     9   - B -     9  - B -     9  B K     resetEnergyMaskupdateAllBuffsplayOtherPlayerActionself frame  6   -     9   B K    checkEndsself   	oæ"-     9   - B )  )    X  -   9  3 BX-   9- B-   9- B-   9B-   9- B   - -  - :  X)   !   X6 '  B-  9	- -  9
B A)  6  BX-
 
 9

	 B
 
 X-
 
 9

	 B

 
 
ERð- -  - :  X)   !    X- :  X)   ! -   9  3 BK       
      getHurtSecondDelayipairsgetSkillIndexgetFxHurt1&hurt to slow=====================
print!getPlayOtherPlayerActionTimeresetEnergyMaskupdateAllBuffsplayOtherPlayerAction scheduleplayHurtEffects< 		!"self frame tBack tAttack changeTime SkillTable skillID actor FxTable res ja ib *?fxs 0tableRes /  k fx   GÙì;
   XD9  9 X@-  )   X- 9 !. X0  6 9- *  B. -  9- - B-  9- - B-   X-  X6	 9
- ' + B-  9:3 B2 -  9- -	 !3 B-   X-  9- BK           	 
    ÀplaySound  schedule|
splitxydplayAllupdateActorEnergymax	math	Timehit	Name	DataçÌ³³æÌþ<





677788888;tBack tAttack self actor frame skillID actees1 shakeTime tFxHurt tRdFxHurt changeTime SkillTable FxTable ifAheadPlaySound event  HtmpShakeTime / °  GÓàK-     9   - B 6 99 9  B  X-   9- B- -   9B X-  9- B)   X-   9 -  B-   9	- - 3
 B- -   9B X- 9)   X
-  94 -  >6 99B2  K  À  À ÀÀÀ	À
 SKILL_DIALOGPartnerBattleDialogshowDialogframeIndex playAttackplayOnegetSkillEffectsgetEnergyIDplaySoundisPlaySelfsoundTabletablesxydgetSound						GHHHHHHHHHHHHIIIIIIIIIIKKactor skillID SkillTable actees1 tBack tAttack self frame shakeTime tFxHurt tRdFxHurt changeTime FxTable soundId BifAheadPlaySound ;fx 	    ±-     9   - B -     9  - B -     9  B K     resetEnergyMaskupdateAllBuffsplayOtherPlayerActionself frame  6   ¼-     9   B K    checkEndsself  ¼ 4a­*   -   9 - B)   X-   9 3 BX-   9- B-   9- B-   9B-   9- B -   9-   - :  X)  ! 3 BK   ÀÀ
 !getPlayOtherPlayerActionTimeresetEnergyMaskupdateAllBuffsplayOtherPlayerAction scheduleplayHurtEffectsçÌ³³æÌþ<




self frame tBack changeTime tAttack 3res . G   ×-     9   - B K     processReviveself frame  6   Ý-     9   B K    checkEndsself   
>Á-     9   - B -   9- B*  * 	  X) +  	 X) 	 X+ X+   X6 9   )  B-   9 3 B6 9 6 9   	 B)  B-   9- B -   93 BK   ÀÀ getCurFrameBuffEffectTime schedulecheckConditionxydcheckAnyReviveupdateAllBuffsµæÌ³¦þ³æÌÌÓÿ ÉÂë£×ÇÂþ

self frame anyDead 9anyRevive 4tDead 3tRevive 2tProcessRevive tNext  3ÊöÚ+ +   X	 9 
 B	  X+ X	 9
 B  X	+   X	 9
 B  X	99  X+ 	 96
 9

B  X		 96
 9

B  X	+ )  )	  4
   9	 B  X 9
B  X 9  B  9 B
  9 B	  9 B)  )  -   9  9B A-   9  9B A:
  X)  !  X-   9  9B A	 X* * 6 9:6 9:  9  9B86 99)  B+  -   9  9B A	 XQ+   )   X  9   B X )   X:-   9  9B A  X:  X:  X5 
  X* 9B 9B6 99 X6 9 9 B : 9: )  B X6 9:!9: )  B  9!B  X  9"B9#  9$ B 9% 9&  + B A 9'3( B 9) B 9% 9&  B A 9'3* B2  X)   X	  9+     B    X X
99  X  9,  3- BX  X  X  9, !	3. BX  9, * 3/ B  X 90B X 91 B  X  92   B2  K  ÀÀsetEnergyMaskisBlackScreengetEnergyID   scheduleplayActorPosAction AppendInterval AppendCallbackDOLocalMoveAppendgetTimeLineLitetransformgetParentgetParentCurDepthgetXOffsetATeamTypegetTeamTypegetParentPos    jumpDeltagetEnemyActoryxVector3getPosIndexherosPos_UNIT_ZORDERS	jumpshakeTimegetSkillIndexheroPosTypegetSpeedReducegetHurtTimegetChangeTimegetAttackTimegetPugongIDcheckIsMindControlBUFF_LUOBI_PRE_COMBOLBUFF_NUOLISI_ADD_RATExydisHasBuffactiveInHierarchyparentisLiuBeiAttackcheckIsAttack checkSkillHasAddHurtFreeArm<ñú¨¸ÑðúýµæÌ³¦ýµæÌóñµæÌ³¦þ











      """"""""""""#$&&&&&&&&'''''((((()**********+,,,,-------..../1111111122222222355666777777778888888888888888:::::::::::<<<<AABEEEEFFFGGGGGGGGGHHKHLLLLMMMMMMMMNNPNPQQQQQRRRRRRRRRTTTTTTTTUUU U ¡¡¡¡¢¢¢´¢´¶¶¶Õ¶×××××××××××××ØØØØØÚÚSkillTable FxTable self  Ëframe  Ëactor  ËskillID  Ëactees1  Ëactees2  Ëattack ÉliubeiFragranceAtk ÈtAttack .tFxHurt changeTime tRdFxHurt  øtJump ÷tBack öheroPosType îshakeTime ædelayBack àz2 heroPos p1 p2 actee Pdelta 8parentPos 'transform . jumpAction  § 
	4{ç+  9   X/9 9 8  X*6 9B  X%6 9B  X 9 9 896 9 X6 9!-   96 9B	 9B A  X	8  X8X:  X:L ÀgetSkillIndexanimationTEAM_B_POS_BASICxydposskill_idtonumber	team
f_pos 		


SkillTable self  5buff  5actionName 3buffFighter pos animation  Ð  0û9 9)  6  BX&8
9
  X9
 X9
9  X9
  X  9 
 B  X9 9
8 9 B6	 9
  X+ X+   B ERØL checkConditionxydgetAnimationTime	teamgetSkillAnimationNameBUFF_REMOVEbuffOn
f_posipairspos
buffs
		


self  1frame  1buffs /curFighterPos_ .t_ -) ) )id &__  &buff %actionName buffFighter tmpT  õ  	$9 96  BX8	9
	 
 X
9
	
 X
9
	9 
 X
9
	
  X
  9
 	 B
 
 X9 9	8 9
 BERãK  playOnlyAnimation	teamgetSkillAnimationNameBUFF_REMOVEbuffOn
f_posipairspos
buffs
			



self  %frame  %buffs #curFighterPos_ "  id _  buff actionName 	buffFighter  Ù  	!m 9 6  BX89	9
 	
 X	9	9
 	
 X	9		  X	
  9	  B	 	 X
9
 98


 9
	 BERåK  playOnlyAnimation
f_pos	teamgetSkillAnimationNameBUFF_OFFBUFF_REMOVEbuffOnipairs
buffs
self  "frame  "buffs    id _  buff actionName 	buffFighter  ´  -®9 )  6  BX$8	9
	9 
 X
9
	9 
 X
9
	
  X
  9
 	 B
 
 X9 9	8 9
 B6	 9
  X+ X+   B ERÚL checkConditionxydgetAnimationTime
f_pos	teamgetSkillAnimationNameBUFF_OFFBUFF_REMOVEbuffOnipairs
buffs
				










self  .frame  .buffs ,t_ +' ' 'id $_  $buff #actionName buffFighter tmpT     U¿
9   9+ B6 9 BH9 8+  X	6	 9		
  B	)
ÿÿ
	 X	+ 
 9	 B	FRìK  setMaskColorarrayIndexOfxyd	team
pairsSetActiverectEnergyMask_
self  actor  actees1  	  id child flag  Ç   BË9   9+ B6 9 BH9 8	 9+
 BFRøK  setMaskColor	team
pairsSetActiverectEnergyMask_self  actor  actees1  		 	 	id child  %   Ù-   9   L  À
colorw  -  Ü-  =  K  À
colorw value   å   1-     9   B   9  - 9- 9- 9B -     X-    9  + B -     9  - B K  ÀÀÀsetZOrderSetActivezyxSetLocalPositiongetParentactor p2 headView z2      3-     9   B   9  - 9- 9- 9B -     X-     9  B    X -    9  + B -     9  B K  ÀÀÀresetZOrderSetActivegetNeedHideHeadViewzyxSetLocalPositiongetParentactor p1 headView  â   4²-     9   B   9  - 9- 9)  B -     X-    9  + B -     9  - B K  ÀÀsetZOrderSetActiveyxSetLocalPositiongetParentactor center headView z2     7»-     9   B   9  - 9- 9)  B -     X-     9  B    X -    9  + B -     9  B K  ÀÀÀresetZOrderSetActivegetNeedHideHeadViewyxSetLocalPositiongetParentactor heroPos headView  (ÈÓr)  )   9 B 96	 6
 B	 A3 3	 -
  
 9

  9B A
	  X5 :
=	:
 =
* )  ) )  9B 9B6 99 X6 9 6 95 9	=	:
 =
 9 8  X9 8 9B X
9 8  X9 8 9B 6 9)   B 9  9B86 9	9
)  B6 9	9
)  B 9 B9  9 B 96 999 	 )  * B A 9 3! B 96 999 	 ) * B A 9" B 96 999 	 )  * B A 9 3# B 96 999 	 ) * B A2q	 Xo5$ :
=	:
 =
)  )  ) )  9B 9B6 99 X6 9 6 95% 9	=	:
 =
 9 8  X9 8 9B X
9 8  X9 8 9B 6 9)   B 9  9B8 9 B9  9 B 9 3& B 9" B 96 999 	 )  * B A 9 3' B 96 999 	 ) * B A2   2  J À       AppendInterval AppendCallbackToAlphaDOTweenTweeningDGAppendgetTimeLineLitetransformVector3getPosIndexherosPos_max	mathgetParentCurDepth	team  TEAM_B_POS_BASICBTeamTypexydgetTeamTypegetHeadViewyx  getSkillIndexheroPosTypeXY  UIWidgettypeofGetComponentgetParentµæÌ³¦þ µæÌ³æý!!!!"""""""####$$$$$$&&&&&&'''''((((()))))****+++------------..4.555555555555666677777777777788>8?????????????@@ABBCCCEGHIJJJKKKKKKKKLLLMMMNOOOPPPQSSSSTTTTTTTUUUUVVVVVV[[[[[[\\\\\]]]]^^^__e_ffffgggggggggggghhnhoooooooooooooqqqqSkillTable self  actor  heroPosType  delayBack  skillID  tJump tBack w 	getter setter heroPosTypeXY center z2 index1 index2 headView heroPos 6Mp1 Hp2 Ctransform ?jumpAction <center Ehz2 findex1 eindex2 dheadView aheroPos 6+transform 'jumpAction $ w   Ò-     9   - B -     9  - B K     updateAllBuffsplayOtherPlayerActionself frame  6   Û-     9   B K    checkEndsself  Ì  'BÏ-     9   - B )    X-   9  3 BX
-   9- B-   9- B-   9- B   -   9-   3 BK   ÀÀ
À !getPlayOtherPlayerActionTimeupdateAllBuffsplayOtherPlayerAction scheduleplayHurtEffects					self frame nextTime res " ¡  Ç+ )  	 9 B)	  )
   X X 9B  9  3 B 9 B2  K  playSound scheduleplayEnergySkillgetHurtTimeself  frame  actor  skillID  actees1  actees2  attack tFxMain tFxHurt tFxSelf nextTime   jã$4  4  )  ) MR8		 9
 	B
 
 XK+ )  6 99 X	 9	B-   9 	 9	B A9 X)  6 9  B)ÿÿ X+ 6 99	 X		 9
	B6 99 X+ 
 9
  B  X6 9  B6 99 X6 9  B)   X6 9  BO® )   X) 9  ) M9	 8			 9
	*  B
Où= K  ÀsetVolumesoundEffects_insert
tableshowDialogBTeamTypegetTeamTypeSKILL_DIALOGarrayIndexOfidgetSkingetDeadSoundgetHeroTableIDDEAD_DIALOGPartnerBattleDialogxydgetHeadViewÿ					


    "$PartnerTable self  kfighters  kindex  kcurSoundEffects isoundIDs hS S Si Qfighter PheadView Mflag JsoundID IheroID sound soundEffect  "  i soundEffect      	K  self   ñ 
 5~4  ) ) 4  4  )   X)U(6  9B*	  	 X<X	 <	6  9B*	  	 X<X	 <	<	 <	XÕ4 >>L random	mathÿ						




self  6t  6data 4init_shake_x 3init_shake_y 2shake_x 1shake_y 0i +   %6´-   -    X -  9     9  )  )  )  B -  + = K  -  9     9  - -   89- -   89)  B -      .   K  À ÀyxisShake_SetLocalPositionimgBgBot_count data self  Ã
  0^ª  X) 9    X9   9B+  =  4
 5 >5 >5 >5 >5 >5 >5 >5	 >5
 >	)  3   9  ) 	 B=  9   9B+ = 2  K  isShake_
StartgetFrameTimer  x y  xûÿÿÿy xy xy  x y xöÿÿÿy  xy x
y  x y 	StopshakeTimer_	self  1shakeTime  1data  count callback  ÷   9Ã6  9BH989	 	 X
  X	
 9	9B	FRó  X	 96 9B A  XX  X 9B6 9B X+  96	 9
B  X
 9B  X+  9 BK  setFreeSkillgetFreeSkillBUFF_FREE_SKILLxydisHasBuffgetEnergyIDskill_idtonumbercheckSkillIsPugongupdateEnergy	f_ep
buffs
pairs										self  :actor  :frame  :  id _  buff 	flag !hasFreeSkill 
 ¯ 	B®Ù)  	 9 B
 9	 B		 X+ X	+   X	%-	  
	 9		  9B A	-
  
 9

 ) B
6 9
 X)  X
-   9  9B A 8	 9	 B X	  X	
 9	-   9  9B A A		 L ÀgetFxHurt2playHurtFxgetFxHurt1AddNDSV_SKILL_TARGETxydgetTargetsgetSkillIndexgetFxHurt1getTeamType						

SkillTable self  Cactor  Cactee  CskillID  Cname  CisMiss  CtargetIndex  Ct AisEnemy 6fxs 
selectType  §   /ë)  -  9  ) M -  9 8-  X6 9-  9  BX O òK   Àremove
tableactionsself action   i    =é+  3  6 999B 9 B 9 = 9+ B6	 9
9  B2  L actionsinsert
tableSetAutoKilltimeScale_timeScaleOnCompleteSequenceDOTweenTweeningDG 	self  action completeCallback  Î   /Dû9   9+ B9   X&9   9+ B9  )  =)  = 6 99 99 9	B6
 9 9B&6 99 '  B6 99  96   9 B AK  showBarEffecthandleronChangeAddEventDelegateXYDUtilspet_avatar_webpetIconsetUISpriteAsync
gradetostringpet_idgetBattleAvatarpetTabletablesxydpetEnergy_
value	petASetActivepetBar_self  0iconSource   /  ¨-  =  K  À
valuebar value    ?~9    X2 :9  =   X= 6 99 )d B 9 9 X)9   X9  9+ B+  =   9 B= * 	 X* 9 99 3	 9 	 9
6
 9

9

9

6 999 B   B
 A2 K  K  DOSetter_float	CoreToDOTweenTweeningDGAppend getTimeLineLite	KillpetBarAction_
valuepetBar_min	mathpetEnergy_	petAÈçÌ³³æþ ÿ				


self  ?val  ?direct  ?showVal .t startVal bar setter  Í  HP¯9  	  X9 9)   X9   X
+ =   9 + ' ) BK  X9  	  X
9 9	  X+ =   9 + B9 9)   X  9 + BK  X9 9)   X9 9)  X  9 + BK  X
  9 + B  9 + ' )  BK  texiao01showBarProtexiao02showBarFullisPlayPetSkill
valuepetBar_petEnergy_ 					



self  I    "Ë-   9     9  - ) B -   9     9  ' )  B K   ÀÀtexiao01	playsetRenderTargetbarEffectPro_self renderTarget  ñ	 8dÄ  X,9  96 9 B9   X6 999  9B= 9   9	'
 6 6 B A9  9' 3 B2 9  9) )  B9  9+ BX9   X9  9+ B2  K  SetActiveSetLocalPosition ui_pet_energybarsetInfoUISpritetypeofbarThumbComponentByNamegameObjectnew
SpinexydbarEffectPro_
floor	math
valuepetBar_ø¤

self  9flag  9val )width %renderTarget  Þ   ;Þ-   9     9  - ) B -   9     9  - - B -   9     9  )  ) )  B K   ÀÀÀÀSetLocalPosition	playsetRenderTargetbarEffectFullself renderTarget effectName count  	  +^Ù  X9    X6 999 9B=  9  9' 6 6	 B A9   9
' 3 B2 9   9+ BX9    X9   9+ B2  K  SetActive ui_pet_energyfullsetInfoUISpritetypeofbarThumbComponentByNamegameObjectpetBar_new
SpinexydbarEffectFull		self  ,flag  ,effectName  ,count  ,renderTarget       ìK  self  index   "    ù	K  	self  fighter       	K  self       K  self  flag       K  self  flag   ©  UÞ±6  99 9B96  99 9 B6  99 9B6  99	 9
 B  X)   X*  6 99 B6 9""B6  9	 B6	  9		9		
	 9		' ' B	6
  9

	 )   B
6 
 B B 9 6 ' B'  &=9 6 ' '  ' &B=K  [-][/c][c][d15b8b]SHRINE_HURDLE_TEXT10shrinePointLabel_ : WORLD_BOSS_DESC_TEXT__	textshrineHurtLabel_	loadstringFormat2
value#shrine_hurdle_boss_score_countgetStringmiscTablegetDisplayNumberBossHarm	ceil	mathgetRatioshrineHurdleDiffTablegetDiffNumgetPointHurtshrineHurdleBossTabletablesbattle_idgetExtrashrineHurdleModelmodelsxydõ°£óò		
self  Vextra Obattle_table_id NhurtPoint GdefNum Aratio :bossHarm 
0totalPoint +bossHarmShow 'miscString string2 pointFunc  ´  UíÈ6  99 9B96  99 9 B6  99 9B6  99	 9
 B6 9 B  X)   X*  6 9"	"		B6	  9		
 B	6
  9

9


 9

' ' B
6  9
 )   B6  B B 9 6 ' B' 	 &=9 6 ' '  ' &B=K  [-][/c][c][d15b8b]SHRINE_HURDLE_TEXT10shrinePointLabel_: WORLD_BOSS_DESC_TEXT__	textshrineHurtLabel_	loadstringFormat2
value#shrine_hurdle_boss_score_countgetStringmiscTablegetDisplayNumber
floor	ceil	mathgetRatioshrineHurdleDiffTablegetDiffNumgetPointHurtshrineHurdleBossTabletablesbattle_idgetExtrashrineHurdleModelmodelsxydõ°£óò

self  VshowBossHarm  Vextra Obattle_table_id NhurtPoint GdefNum Aratio :bossHarm 6totalPoint +bossHarmShow 'miscString string2 pointFunc    	Cß9   96 6 B+ B)  9 ) M
86 9 +	  9
' &

BOöK  _ios_testspriteNamesetUISpritexydLengthUISpritetypeofGetComponentsInChildrenwindow_self  allSprites 	  i 	sprite  ô    ¬ã è6   ' 6 ' B A 6 996 996 996  '	 6 '
 B A6 ' B6 ' B6 996 996	 9		9		6
 9

9

6 996 996 996 996 99B3 =3 =3 =3 =3  =3! = 3# =" 3% =$ 3' =& 3) =( 3+ =* 3- =, 3/ =. 31 =0 33 =2 35 =4 37 =6 39 =8 3; =: 3= =< 3? => 3A =@ 3C =B 3E =D 3G =F 3I =H 3K =J 3M =L 3O =N 3Q =P 3S =R 3U =T 3W =V 3Y =X 3[ =Z 3] =\ 3_ =^ 3a =` 3c =b 3e =d 3g =f 3i =h 3k =j 3m =l 3o =n 3q =p 3s =r 3u =t 3w =v 3y =x 3{ =z 3} =| 3 =~ 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3¡ =  3£ =¢ 3¥ =¤ 3§ =¦ 3© =¨ 3« =ª 3­ =¬ 3¯ =® 3± =° 3³ =² 3µ =´ 3· =¶ 3¹ =¸ 3» =º 3½ =¼ 3¿ =¾ 3Á =À 3Ã =Â 3Å =Ä 3Ç =Æ 3É =È 3Ë =Ê 3Í =Ì 3Ï =Î 3Ñ =Ð 3Ó =Ò 3Õ =Ô 3× =Ö 3Ù =Ø 3Û =Ú 3Ý =Ü 3ß =Þ 3á =à 3ã =â 3å =ä 3ç =æ 3é =è 3ë =ê 3í =ì 3ï =î 3ñ =ð 3ó =ò 3õ =ô 3÷ =ö 3ù =ø 3û =ú 3ý =ü 3ÿ =þ ' 3< '3< '3< 2  L   iosTestChangeUI finalShowShrineHarm checkShrineHurdleHurt showFightersSpeed showUnAutoBtn playUnautoEnd setCurFighter useSkill showBarFull showBarPro showBarEffect updatePetEnergy initPetInfo getTimeLineLite playActee updateActorEnergy playShake createShakeData playSounds showDialog playPet playActorPosAction resetEnergyMask setEnergyMask getRoundEndAction playRoundEndAction playOtherPlayerAction !getPlayOtherPlayerActionTime getSkillAnimationName playActor getEnemyActor schedule clearSounds clearEffect clearConfig didClose willClose didOpen playBattleResult openSkipWindow touchSkip isHideSkip checkCanSkip resetZorders checkEnds processRevive checkAnyRevive keepCorpse checkFakeDeath bossHurt playTrialAwardEffect checkBossBar refreshTeam getFinalBossHit checkBuffPlayEffect checkSkillIsCrit getMpKey checkPlayAttacked checkHasExceptDotShield checkHasFreeHarm checkNoRecordNum checkGodBuff updateAllBuffs updateEnergys buffIsDot playHurtEffects checkNeedLimitBossBar checkNeedIceBossBar checkShrineHurdle checkNeedTrialBossBar getHoldBuffTime getCurFrameBuffEffectTime mainLoop showBattleSound showEnemyEffect playStartAction playSecondStory startBattle loadFighterModel updateRoundLabel newPet newGod newFighter setFormation stopBattleByGuide stopBattle resumeBattle updateFrameIndex updateSpeed setNewSpeed onSpeedTouch checkCanSpeed createEffects initEffects addGroupBuffTouch initGroupBuff getGroupBuffID  showTimeCloisterBattleCards showPvpWindow pauseTouch touchBuff resumeBattleCallback initButton setConfig setMap initBossBar checkPlayAfterStory getUIComponent playOpenAnimation initWindow getData initEmptyField initData initConst  getPosDesc initLayOut initUI getPrefabPath 	ctorgetBattleEffectFactoryresourceEffectTablenewTrialRewardTablepartnerTablefxTablegroupTabledBuffTableeffectTableskillTableapp.components.PngNum!app.components.GroupBuffIcon!app.components.BaseComponentGroupBuffDetailTipsstageTablegroupBuffTablebattleTabletablesxyd.BaseWindowimportBattleWindow
class                              	 	 	 
 
 
                      !  8 # p :  r Ä  Î Æ ä Ð î æ ò ð û ô ý ESG_U²aÐ´×ÒâÙúäü
<g>i³½µÜÍìÞî.L0PNR´¾¶ÈÀÑÊñÓ óRpTr£ö¥ø,3.85?:FAwHyMWPkY}m©·«ç¹é8v;x ´¢Ó¶àÕâ)=+L?fNh¡ ¦£«¨¾­ØÀéÚýë		 	å		ù	ç	
û	

,
 
=
.
I
?
Q
K
Å
S
á
Ç
ã

	(A*WCgYyi{­Â¯×ÄêÙ÷ìù/1F1H]H_e_ggBattleWindow ¦BattleTable £GroupBuffTable  StageTable GroupBuffDetailTips GroupBuffIcon PngNum SkillTable EffectTable DBuffTable GroupTable FxTable PartnerTable ÿNewTrialRewardTable üResourceEffectTable ùBattleEffectFactory õ  