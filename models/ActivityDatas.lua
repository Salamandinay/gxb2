local ModelClass = {
	[xyd.ActivityID.CHECKIN] = require("app.models.datas.CheckInData"),
	[xyd.ActivityID.RECHARGE] = require("app.models.datas.RechargeData"),
	[xyd.ActivityID.MONTH_CARD] = require("app.models.datas.MonthCardData"),
	[xyd.ActivityID.MINI_MONTH_CARD] = require("app.models.datas.MonthCardData"),
	[xyd.ActivityID.MONTHLY_GIFTBAG] = require("app.models.datas.MonthlyGiftBagData"),
	[xyd.ActivityID.WEEKLY_GIFTBAG] = require("app.models.datas.WeeklyGiftBagData"),
	[xyd.ActivityID.FOUR_STAR_GIFT] = require("app.models.datas.FiveStarGiftData"),
	[xyd.ActivityID.FIVE_STAR_GIFT] = require("app.models.datas.FiveStarGiftData"),
	[xyd.ActivityID.FIRST_RECHARGE] = require("app.models.datas.FirstRechargeData"),
	[xyd.ActivityID.SUMMON_GIFTBAG] = require("app.models.datas.SummonGiftBagData"),
	[xyd.ActivityID.VALUE_GIFTBAG01] = require("app.models.datas.ValueGiftBagData"),
	[xyd.ActivityID.VALUE_GIFTBAG02] = require("app.models.datas.ValueGiftBagData"),
	[xyd.ActivityID.VALUE_GIFTBAG03] = require("app.models.datas.ValueGiftBagData"),
	[xyd.ActivityID.LEVEL_UP_GIFTBAG] = require("app.models.datas.LevelUpGiftBagData"),
	[xyd.ActivityID.SUMMON_SPECIAL_HERO_GIFT] = require("app.models.datas.SummonSpecialHeroGiftData"),
	[xyd.ActivityID.PROPHET_SUMMON_GIFTBAG] = require("app.models.datas.ProphetSummonGiftBagData"),
	[xyd.ActivityID.MIRACLE_GIFTBAG] = require("app.models.datas.MiracleGiftBagData"),
	[xyd.ActivityID.FOLLOWING_GIFTBAG] = require("app.models.datas.FollowingGiftBagData"),
	[xyd.ActivityID.ONLINE_AWARD] = require("app.models.datas.OnlineAwardData"),
	[xyd.ActivityID.BIND_ACCOUNT_ENTRY] = require("app.models.datas.BindAccountEntryData"),
	[xyd.ActivityID.ACTIVITY_SEVENDAYS] = require("app.models.datas.ActivitySevenDayData"),
	[xyd.ActivityID.FREE_RECHARGE] = require("app.models.datas.FreeRechargeData"),
	[xyd.ActivityID.WISHING_POOL_GIFTBAG] = require("app.models.datas.WishingPoolGiftBagData"),
	[xyd.ActivityID.PUB_MISSION_GIFTBAG] = require("app.models.datas.PubMissionGiftBagData"),
	[xyd.ActivityID.BATTLE_ARENA_GIFTBAG] = require("app.models.datas.BattleArenaGiftBagData"),
	[xyd.ActivityID.SHELTER_GIFTBAG] = require("app.models.datas.ShelterGiftBagData"),
	[xyd.ActivityID.SHENXUE_GIFTBAG] = require("app.models.datas.ShenXueGiftBagData"),
	[xyd.ActivityID.HERO_EXCHANGE] = require("app.models.datas.HeroExchangeData"),
	[xyd.ActivityID.QIXI_GIFTBAG] = require("app.models.datas.QiXiGiftBagData"),
	[xyd.ActivityID.SWEETY_HOUSE] = require("app.models.datas.SweetyHouseData"),
	[xyd.ActivityID.ACTIVITY_CV] = require("app.models.datas.ActivityCVData"),
	[xyd.ActivityID.LIMIT_FIVE_STAR_GIFTBAG] = require("app.models.datas.LimitFiveStarGiftBagData"),
	[xyd.ActivityID.ACTIVITY_WORLD_BOSS] = require("app.models.datas.ActivityWorldBossData"),
	[xyd.ActivityID.MID_AUTUMN_ACTIVITY] = require("app.models.datas.MidAutumnActivityData"),
	[xyd.ActivityID.DARK_GUARD] = require("app.models.datas.DarkGuardData"),
	[xyd.ActivityID.BLACK_CARD] = require("app.models.datas.BlackCardData"),
	[xyd.ActivityID.ACTIVITY_JIGSAW] = require("app.models.datas.ActivityJigsawData"),
	[xyd.ActivityID.SUBSCRIPTION] = require("app.models.datas.SubscriptionData"),
	[xyd.ActivityID.MONTHLY_GIFTBAG02] = require("app.models.datas.MonthlyGiftBagData"),
	[xyd.ActivityID.WEEKLY_GIFTBAG02] = require("app.models.datas.WeeklyGiftBagData"),
	[xyd.ActivityID.AWAWKE_GIFTBAG] = require("app.models.datas.AwakeGiftBagData"),
	[xyd.ActivityID.CHRISTMAS_1] = require("app.models.datas.ActivityChristmas1Data"),
	[xyd.ActivityID.CHRISTMAS_2] = require("app.models.datas.ActivityChristmas2Data"),
	[xyd.ActivityID.BENEFIT_GIFTBAG01] = require("app.models.datas.BenefitGiftbagData"),
	[xyd.ActivityID.BENEFIT_GIFTBAG02] = require("app.models.datas.BenefitGiftbag02Data"),
	[xyd.ActivityID.BENEFIT_GIFTBAG03] = require("app.models.datas.BenefitGift03bagData"),
	[xyd.ActivityID.BENEFIT_GIFTBAG04] = require("app.models.datas.BenefitGift03bagData"),
	[xyd.ActivityID.BENEFIT_GIFTBAG05] = require("app.models.datas.BenefitGiftbagData"),
	[xyd.ActivityID.BENEFIT_GIFTBAG06] = require("app.models.datas.BenefitGift03bagData"),
	[xyd.ActivityID.FAVORABILITY] = require("app.models.datas.FavorabilityData"),
	[xyd.ActivityID.NEWYEAR_SIGNIN] = require("app.models.datas.NewyearSignInData"),
	[xyd.ActivityID.TEN_STAR_EXCHANGE] = require("app.models.datas.TenStarExchangeData"),
	[xyd.ActivityID.STAGE_GIFTBAG] = require("app.models.datas.StageGiftBagData"),
	[xyd.ActivityID.SAKURA_DATE] = require("app.models.datas.SakuraDateData"),
	[xyd.ActivityID.RING_GIFTBAG] = require("app.models.datas.RingGiftbagData"),
	[xyd.ActivityID.ACTIVITY_VOTE] = require("app.models.datas.ActivityVoteData"),
	[xyd.ActivityID.ACTIVITY_VOTE2] = require("app.models.datas.ActivityVote2Data"),
	[xyd.ActivityID.FIT_UP_DORM] = require("app.models.datas.ActivityFitUpDormData"),
	[xyd.ActivityID.ACTIVITY_SCHOOL_GIFTBAG] = require("app.models.datas.SchoolOpensGiftbagData"),
	[xyd.ActivityID.TEST_TASK] = require("app.models.datas.TestTaskGiftBagData"),
	[xyd.ActivityID.TEST_FEEDBACK] = require("app.models.datas.TestFeedbackData"),
	[xyd.ActivityID.NEW_SERVER_SUMMON_GIFTBAG] = require("app.models.datas.NewServerSummonGiftbagData"),
	[xyd.ActivityID.PLOT_FINISH_GIFTBAG] = require("app.models.datas.PlotFinishGiftBagData"),
	[xyd.ActivityID.GROW_UP_GIFTBAG] = require("app.models.datas.GrowUpGiftBagData"),
	[xyd.ActivityID.EQUIP_GACHA] = require("app.models.datas.ActivityEquipGachaData"),
	[xyd.ActivityID.UPGRADE_GIFTBAG] = require("app.models.datas.UpgradeGiftBagData"),
	[xyd.ActivityID.BEACH] = require("app.models.datas.ActivityBeachData"),
	[xyd.ActivityID.MAKE_CAKE] = require("app.models.datas.MakeCakeData"),
	[xyd.ActivityID.JACKPOT_MACHINE_SCORE] = require("app.models.datas.JackpotMachineScoreData"),
	[xyd.ActivityID.JACKPOT_MACHINE] = require("app.models.datas.ActivityJackpotMachineData"),
	[xyd.ActivityID.PROMOTION_GIFTBAG] = require("app.models.datas.PromotionGiftbagData"),
	[xyd.ActivityID.ACTIVITY_CONCERT] = require("app.models.datas.ActivityConcertData"),
	[xyd.ActivityID.ACTIVITY_MUSIC_JIGSAW] = require("app.models.datas.ActivityMusicJigsawData"),
	[xyd.ActivityID.LEVEL_FUND] = require("app.models.datas.LevelFundData"),
	[xyd.ActivityID.BOOK_RESEARCH] = require("app.models.datas.BookResearchData"),
	[xyd.ActivityID.LIBRARY_WATCHER] = require("app.models.datas.LibraryWatcherData"),
	[xyd.ActivityID.DOUBLE_RING_GIFTBAG] = require("app.models.datas.DoubleRingGiftbagData"),
	[xyd.ActivityID.CANDY_COLLECT] = require("app.models.datas.CandyCollectData"),
	[xyd.ActivityID.LIBRARY_WATCHER2] = require("app.models.datas.LibraryWatcherData"),
	[xyd.ActivityID.BATTLE_PASS] = require("app.models.datas.BattlePass"),
	[xyd.ActivityID.BATTLE_PASS_2] = require("app.models.datas.BattlePass"),
	[xyd.ActivityID.LIBRARY_WATCHER2] = require("app.models.datas.LibraryWatcherData"),
	[xyd.ActivityID.SUPER_HERO_CLUB] = require("app.models.datas.SuperHeroClubData"),
	[xyd.ActivityID.DAILY_GIFGBAG] = require("app.models.datas.DailyGiftBagData"),
	[xyd.ActivityID.DAILY_GIFGBAG02] = require("app.models.datas.DailyGiftBagData"),
	[xyd.ActivityID.ACTIVITY_MONTHLY] = require("app.models.datas.ActivityMonthlyData"),
	[xyd.ActivityID.NEW_LEVEL_UP_GIFTBAG] = require("app.models.datas.NewLevelUpGiftBagData"),
	[xyd.ActivityID.BENEFIT_GIFTBAG03] = require("app.models.datas.BenefitGiftbagData"),
	[xyd.ActivityID.ALL_STARS_PRAY] = require("app.models.datas.AllStarsPrayData"),
	[xyd.ActivityID.NEWBIE_CAMP] = require("app.models.datas.NewBieCampData"),
	[xyd.ActivityID.NEW_FOUR_STAR_GIFT] = require("app.models.datas.NewFiveStarGiftBagData"),
	[xyd.ActivityID.NEW_FIVE_STAR_GIFT] = require("app.models.datas.NewFiveStarGiftBagData"),
	[xyd.ActivityID.ENERGY_SUMMON] = require("app.models.datas.ActivityEnergySummonData"),
	[xyd.ActivityID.NEW_PARTNER_WARMUP] = require("app.models.datas.NewPartnerWarmupData"),
	[xyd.ActivityID.ENTRANCE_TEST] = require("app.models.datas.ActivityEntranceTestData"),
	[xyd.ActivityID.WARMUP_GIFT] = require("app.models.datas.WarmUpGiftData"),
	[xyd.ActivityID.PRIVILEGE_CARD] = require("app.models.datas.PpivilegeCardData"),
	[xyd.ActivityID.ICE_SUMMER] = require("app.models.datas.ActivityIceSummerData"),
	[xyd.ActivityID.ICE_SECRET] = require("app.models.datas.ActivityIceSecretData"),
	[xyd.ActivityID.SUMMON_WELFARE] = require("app.models.datas.SummonWelfareData"),
	[xyd.ActivityID.NEW_STAGE_GIFTBAG] = require("app.models.datas.NewStageGiftBagData"),
	[xyd.ActivityID.ACTIVITY_TOWER_EMERGENCY] = require("app.models.datas.ActivityTowerEmergencyData"),
	[xyd.ActivityID.ACTIVITY_FOOD_FESTIVAL] = require("app.models.datas.ActivityFoodFestivalData"),
	[xyd.ActivityID.ACTIVITY_COIN_EMERGENCY] = require("app.models.datas.ActivityCoinEmergencyData"),
	[xyd.ActivityID.ACTIVITY_EXP_EMERGENCY] = require("app.models.datas.ActivityExpEmergencyData"),
	[xyd.ActivityID.SEVEN_STAR_GIFT] = require("app.models.datas.SevnStarGiftData"),
	[xyd.ActivityID.NINE_STAR_GIFT1] = require("app.models.datas.NineStarGiftBag1Data"),
	[xyd.ActivityID.NINE_STAR_GIFT2] = require("app.models.datas.NineStarGiftBag2Data"),
	[xyd.ActivityID.ACTIVITY_ICE_SECRET_GIFTBAG] = require("app.models.datas.ActivityIceSecretGiftbagData"),
	[xyd.ActivityID.ACTIVITY_ICE_SECRET_MISSION] = require("app.models.datas.ActivityIceSecretMissionData"),
	[xyd.ActivityID.RETURN] = require("app.models.datas.ActivityReturnTestData"),
	[xyd.ActivityID.NEW_SUMMON_SPECIAL_HERO_GIFT] = require("app.models.datas.NewSummonSpecialHeroGiftData"),
	[xyd.ActivityID.HOT_POINT_PARTNER] = require("app.models.datas.HotSpotPartnerBoxData"),
	[xyd.ActivityID.DISCOUNT_MONTHLY] = require("app.models.datas.MonthCardData"),
	[xyd.ActivityID.ACTIVITY_EQUIP_LEVEL_UP] = require("app.models.datas.ActivityEquipLevelUpData"),
	[xyd.ActivityID.WISH_CAPSULE] = require("app.models.datas.WishCapsuleData"),
	[xyd.ActivityID.FAIRY_TALE] = require("app.models.datas.FairyTaleData"),
	[xyd.ActivityID.ACTIVITY_KEYBOARD] = require("app.models.datas.ActivityKeyboardData"),
	[xyd.ActivityID.DRAGON_BOAT] = require("app.models.datas.ActivityDragonBoatData"),
	[xyd.ActivityID.SPROUTS] = require("app.models.datas.SproutsData"),
	[xyd.ActivityID.RED_RIDING_HOOD] = require("app.models.datas.RedRidingHoodData"),
	[xyd.ActivityID.ACTIVITY_CRYSTAL_GIFT] = require("app.models.datas.ActivityCrystalGiftData"),
	[xyd.ActivityID.TOWER_FUND_GIFTBAG] = require("app.models.datas.ActivityTowerFundGiftBag"),
	[xyd.ActivityID.SPORTS] = require("app.models.datas.ActivitySportsData"),
	[xyd.ActivityID.ACTIVITY_DOUBLE_DROP_QUIZ] = require("app.models.datas.ActivityDoubleDropData"),
	[xyd.ActivityID.ICE_SECRET_BOSS_CHALLENGE] = require("app.models.datas.IceSecretBossChallengeData"),
	[xyd.ActivityID.ACTIVITY_SCRATCH_CARD] = require("app.models.datas.ActivityScratchCardData"),
	[xyd.ActivityID.HALLOWEEN_PUMPKIN_FIELD] = require("app.models.datas.HalloweenPumpkinFieldData"),
	[xyd.ActivityID.ACTIVITY_LASSO] = require("app.models.datas.ActivityLassoData"),
	[xyd.ActivityID.MAGIC_DUST_PUSH_GIFTBGA] = require("app.models.datas.MagicDustPushGiftbagData"),
	[xyd.ActivityID.GRADE_STONE_PUSH_GIFTBAG] = require("app.models.datas.GradeStonePushGiftbagData"),
	[xyd.ActivityID.PET_STONE_PUSH_GIFTBAG] = require("app.models.datas.PetStonePushGiftbagData"),
	[xyd.ActivityID.ACADEMY_ASSESSMENT_PUSH_GIFTBAG] = require("app.models.datas.AcademyAssessmentPushGiftbagData"),
	[xyd.ActivityID.FAN_PAI] = require("app.models.datas.ActivityFanPaiData"),
	[xyd.ActivityID.EASTER_EGG] = require("app.models.datas.ActivityEasterEggData"),
	[xyd.ActivityID.WELFARE_SALE] = require("app.models.datas.WelfareSaleData"),
	[xyd.ActivityID.NEW_SEVENDAY_GIFTBAG] = require("app.models.datas.NewSevendayGiftbagData"),
	[xyd.ActivityID.WEEK_MISSION] = require("app.models.datas.ActivityWeekMissionData"),
	[xyd.ActivityID.MONTH_BEGINNING_GIFTBAG] = require("app.models.datas.MonthBeginningGiftBagData"),
	[xyd.ActivityID.WEEK_MISSION] = require("app.models.datas.ActivityWeekMissionData"),
	[xyd.ActivityID.KAKAOPAY] = require("app.models.datas.ActivityKakaopayData"),
	[xyd.ActivityID.LIMIT_CALL_BOSS] = require("app.models.datas.ActivityLimitCallBossData"),
	[xyd.ActivityID.LIMIT_GACHA_AWARD] = require("app.models.datas.ActivityLimitGachaAwardData"),
	[xyd.ActivityID.TIME_LIMIT_CALL] = require("app.models.datas.ActivityTimeLimitCallData"),
	[xyd.ActivityID.ACTIVITY_SEARCH_BOOK] = require("app.models.datas.ActivitySearchBookData"),
	[xyd.ActivityID.ACTIVITY_BLACK_FRIDAY] = require("app.models.datas.ActivityBlackFridayData"),
	[xyd.ActivityID.NEW_FIRST_RECHARGE] = require("app.models.datas.NewFirstRechargeData"),
	[xyd.ActivityID.NEW_LIMIT_FIVE_STAR_GIFTBAG] = require("app.models.datas.LimitFiveStarGiftBagData"),
	[xyd.ActivityID.LAFULI_DRIFT] = require("app.models.datas.LafuliDriftData"),
	[xyd.ActivityID.LAFULI_DRIFT_GIFTBAG] = require("app.models.datas.ActivityLafuliDriftGiftbagData"),
	[xyd.ActivityID.EXCHANGE_DUMMY] = require("app.models.datas.ActivityChristmasExchangeDummyData"),
	[xyd.ActivityID.TURING_MISSION] = require("app.models.datas.ActivityTuringMissionData"),
	[xyd.ActivityID.CHRISTMAS_COST] = require("app.models.datas.ActivityChristmasCostData"),
	[xyd.ActivityID.ACTIVITY_CHRISTMAS_SALE] = require("app.models.datas.ActivityChristmasSaleData"),
	[xyd.ActivityID.NEW_SUMMON_GIFTBAG] = require("app.models.datas.NewSummonGiftBagData"),
	[xyd.ActivityID.NEWYEAR_NEW_SIGNIN] = require("app.models.datas.NewyearNewSignInData"),
	[xyd.ActivityID.ACTIVITY_YEAR_FUND] = require("app.models.datas.ActivityYearFundData"),
	[xyd.ActivityID.NEWYEAR_BAOXIANG] = require("app.models.datas.NewyearBaoxiangData"),
	[xyd.ActivityID.STUDY_QUESTION] = require("app.models.datas.ActivityStudyQuestion"),
	[xyd.ActivityID.TULIN_GROWUP_GIFTBAG] = require("app.models.datas.ActivityGropupGiftBag"),
	[xyd.ActivityID.NEWBEE_10GACHA] = require("app.models.datas.ActivityNewbee10Gacha"),
	[xyd.ActivityID.ACTIVITY_NEWBEE_FUND] = require("app.models.datas.ActivityNewbeeFundData"),
	[xyd.ActivityID.ARTIFACT_SHOP_WARM_UP] = require("app.models.datas.ArtifactShopWarmUpData"),
	[xyd.ActivityID.NEWBEE_GIFTBAG] = require("app.models.datas.ActivityNewbeeGiftBag"),
	[xyd.ActivityID.GAMBLE_PLUS] = require("app.models.datas.GamblePlusData"),
	[xyd.ActivityID.NEWBEE_GACHA_POOL] = require("app.models.datas.NewbeeGachaPoolData"),
	[xyd.ActivityID.NEWYEAR_WELFARE] = require("app.models.datas.NewyearWelfareData"),
	[xyd.ActivityID.SPRING_NEW_YEAR] = require("app.models.datas.SpringNewYearData"),
	[xyd.ActivityID.ACTIVITY_EXCHANGE] = require("app.models.datas.ActivityExchangeData"),
	[xyd.ActivityID.ACTIVITY_RECHARGE] = require("app.models.datas.ActivityRechargeData"),
	[xyd.ActivityID.ACTIVITY_NEW_SHIMO] = require("app.models.datas.ActivityNewShimoData"),
	[xyd.ActivityID.ACTIVITY_SHIMO_GIFTBAG] = require("app.models.datas.ActivityShimoGiftbagData"),
	[xyd.ActivityID.ACTIVITY_VALENTINE] = require("app.models.datas.ActivityValentineData"),
	[xyd.ActivityID.ACTIVITY_TREE_GROUP] = require("app.models.datas.ActivityTreeGroupData"),
	[xyd.ActivityID.ACTIVITY_PUPPET] = require("app.models.datas.ActivityPuppetData"),
	[xyd.ActivityID.EASTER_GIFTBAG] = require("app.models.datas.EasterGiftbagData"),
	[xyd.ActivityID.ACTIVITY_SMASH_EGG] = require("app.models.datas.ActivitySmashEggData"),
	[xyd.ActivityID.ACTIVITY_LIMITED_TASK] = require("app.models.datas.ActivityLimitedTaskData"),
	[xyd.ActivityID.EASTER_EGG_GIFTBAG] = require("app.models.datas.EasterEggGiftbagData"),
	[xyd.ActivityID.REDEEM_CODE] = require("app.models.datas.ActivityRedeemCodeData"),
	[xyd.ActivityID.GUILD_COMPETITION] = require("app.models.datas.ActivityGuildCompetitionData"),
	[xyd.ActivityID.ACTIVITY_BOMB] = require("app.models.datas.ActivityBombData"),
	[xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG] = require("app.models.datas.ActivityGraduateGiftbagData"),
	[xyd.ActivityID.ACTIVITY_FAIR_ARENA] = require("app.models.datas.ActivityFairArenaData"),
	[xyd.ActivityID.ACTIVITY_PARTNER_GALLERY] = require("app.models.datas.ActivityPartnerGalleryData"),
	[xyd.ActivityID.GUILD_SHOP] = require("app.models.datas.GuildShopData"),
	[xyd.ActivityID.COURSE_RESEARCH] = require("app.models.datas.ActivityCourseResearchData"),
	[xyd.ActivityID.COLLECT_CORAL_BRANCH] = require("app.models.datas.CollectCoralBranchData"),
	[xyd.ActivityID.ACTIVITY_NEWBEE_LEESON] = require("app.models.datas.ActivityNewbeeLessonData"),
	[xyd.ActivityID.NEWBEE_LESSON_GIFTBAG] = require("app.models.datas.NewbeeLessonGiftbagData"),
	[xyd.ActivityID.ACTIVITY_TIME_PARTNER] = require("app.models.datas.ActivityTimePartnerData"),
	[xyd.ActivityID.ACTIVITY_TIME_GIFTBAG] = require("app.models.datas.ActivityTimeGiftbagData"),
	[xyd.ActivityID.ACTIVITY_TIME_GAMBLE] = require("app.models.datas.ActivityTimeGambleData"),
	[xyd.ActivityID.ACTIVITY_TIME_MISSION] = require("app.models.datas.ActivityTimeMissionData"),
	[xyd.ActivityID.ACTIVITY_GIFTBAG_OPTIONAL] = require("app.models.datas.ActivityGiftBagOptionalData"),
	[xyd.ActivityID.ACTIVITY_SPACE_EXPLORE_SUPPLY] = require("app.models.datas.ActivitySpaceExploreSupplyData"),
	[xyd.ActivityID.ACTIVITY_SPACE_EXPLORE_MISSION] = require("app.models.datas.ActivitySpaceExploreMissionData"),
	[xyd.ActivityID.ACTIVITY_SPACE_EXPLORE_TEAM] = require("app.models.datas.ActivitySpaceExploreTeamData"),
	[xyd.ActivityID.ACTIVITY_SPACE_EXPLORE] = require("app.models.datas.ActivitySpaceExploreData"),
	[xyd.ActivityID.ACTIVITY_OPTIONAL_SUPPLY] = require("app.models.datas.ActivityOptionalSupplyData"),
	[xyd.ActivityID.ACTIVITY_NEWBEE_LEESON_2] = require("app.models.datas.ActivityNewbeeLessonData"),
	[xyd.ActivityID.NEWBEE_LESSON_GIFTBAG_2] = require("app.models.datas.NewbeeLessonGiftbagData"),
	[xyd.ActivityID.COURSE_RESEARCH_2] = require("app.models.datas.ActivityCourseResearchData"),
	[xyd.ActivityID.ACTIVITY_RESIDENT_RETURN] = require("app.models.datas.ActivityResidentReturnData"),
	[xyd.ActivityID.CRYSTAL_BALL] = require("app.models.datas.ActivityCrystalBallData"),
	[xyd.ActivityID.ACTIVITY_RETURN_GIFT_OPTIONAL] = require("app.models.datas.ActivityReturnGiftOptionalData"),
	[xyd.ActivityID.ACTIVIYT_RETURN_PRIVILEGE_DISCOUNT] = require("app.models.datas.ActivityReturnPrivilegeDiscountData"),
	[xyd.ActivityID.YEARS_SUMMARY] = require("app.models.datas.ActivityYearsSummary"),
	[xyd.ActivityID.ACTIVITY_WINE] = require("app.models.datas.ActivityWineData"),
	[xyd.ActivityID.ACTIVITY_TREASURE] = require("app.models.datas.ActivityTreasureData"),
	[xyd.ActivityID.ANNIVERSARY_GIFTBAG3_1] = require("app.models.datas.AnniversaryGiftbag3Data"),
	[xyd.ActivityID.ANNIVERSARY_GIFTBAG3_2] = require("app.models.datas.AnniversaryGiftbag3Data"),
	[xyd.ActivityID.ACTIVITY_POPULARITY_VOTE] = require("app.models.datas.ActivityPopularityVoteData"),
	[xyd.ActivityID.TRIPLE_FIRST_CHARGE] = require("app.models.datas.ActivityTripleFirstChargeData"),
	[xyd.ActivityID.ACTIVITY_3BIRTHDAY_VIP] = require("app.models.datas.Activity3BirthdayVipData"),
	[xyd.ActivityID.ACTIVITY_BEACH_GIFTBAG] = require("app.models.datas.ActivityBeachGiftbagData"),
	[xyd.ActivityID.ACTIVITY_BEACH_SUMMER] = require("app.models.datas.ActivityBeachSummerData"),
	[xyd.ActivityID.ACTIVITY_BEACH_PUZZLE] = require("app.models.datas.ActivityBeachPuzzleData"),
	[xyd.ActivityID.ACTIVITY_BEACH_SHOP] = require("app.models.datas.ActivityBeachShopData"),
	[xyd.ActivityID.ACTIVITY_JUNGLE] = require("app.models.datas.ActivityJungleData"),
	[xyd.ActivityID.ACTIVITY_POPULARITY_VOTE_SURVEY] = require("app.models.datas.ActivityPopularityVoteSurveyData"),
	[xyd.ActivityID.DRESS_SUMMON_LIMIT_FREE] = require("app.models.datas.DressSummonLimitFreeData"),
	[xyd.ActivityID.DRESS_SUMMON_FREE] = require("app.models.datas.DressSummonFreeData"),
	[xyd.ActivityID.DRESS_SUMMON_LIMIT] = require("app.models.datas.DressSummonLimitData"),
	[xyd.ActivityID.ACTIVITY_EQUIP_LEVEL_ANTIQUE] = require("app.models.datas.ActivityEquipLevelAntiqueData"),
	[xyd.ActivityID.ENCONTER_STORY] = require("app.models.datas.ActivityEnconterStoryData"),
	[xyd.ActivityID.ACTIVITY_OPTIONAL_SUPPLY_SUPER] = require("app.models.datas.ActivityOptionalSupplySuperData"),
	[xyd.ActivityID.ACTIVITY_DRESS_OPENING_CEREMONY] = require("app.models.datas.ActivityDressOpeningCeremonyData"),
	[xyd.ActivityID.ACTIVITY_ARTIFACT_EXCHANGE] = require("app.models.datas.ActivityArtifactExchangeData"),
	[xyd.ActivityID.ACTIVITY_ANGLE_TEA_PARTY] = require("app.models.datas.ActivityAngleTeaPartyData"),
	[xyd.ActivityID.ACTIVITY_FISHING] = require("app.models.datas.ActivityFishingData"),
	[xyd.ActivityID.MONTHLY_HIKE] = require("app.models.datas.ActivityMonthlyHikeData"),
	[xyd.ActivityID.ACTIVITY_NEWBEE_FUND3] = require("app.models.datas.ActivityNewbeeFund3Data"),
	[xyd.ActivityID.ACTIVITY_HALLOWEEN] = require("app.models.datas.ActivityHalloweenData"),
	[xyd.ActivityID.ACTIVITY_HALLOWEEN_MISSION] = require("app.models.datas.ActivityHalloweenMissionData"),
	[xyd.ActivityID.ACTIVITY_HALLOWEEN_GIFTBAG] = require("app.models.datas.ActivityHalloweenGiftbagData"),
	[xyd.ActivityID.ACTIVITY_SECRET_TREASURE_HUNT] = require("app.models.datas.ActivitySecretTreasureHuntData"),
	[xyd.ActivityID.ACTIVITY_SECRET_TREASURE_HUNT_MISSION] = require("app.models.datas.ActivitySecretTreasureHuntMissionData"),
	[xyd.ActivityID.ACTIVITY_SECRET_TREASURE_HUNT_GIFTBAG] = require("app.models.datas.ActivitySecretTreasureHuntGiftbagData"),
	[xyd.ActivityID.ALL_STARS_PRAY_GIFTBAG] = require("app.models.datas.AllStarsPrayGiftbagData"),
	[xyd.ActivityID.THANKSGIVING_GIFTBAG] = require("app.models.datas.ThanksgivingGiftbagData"),
	[xyd.ActivityID.ACTIVITY_CHRISTMAS_SIGN_UP] = require("app.models.datas.ActivityChristmasSignUpData"),
	[xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY] = require("app.models.datas.ActivityJackpotLotteryData"),
	[xyd.ActivityID.ACTIVITY_GROWTH_PLAN] = require("app.models.datas.ActivityGrowthPlanData"),
	[xyd.ActivityID.ACTIVITY_LUCKYBOXES] = require("app.models.datas.ActivityLuckyboxesData"),
	[xyd.ActivityID.LIMIT_DISCOUNT_MONTHLY_GIFTBAG] = require("app.models.datas.LimitDiscountMonthlyGiftbagData"),
	[xyd.ActivityID.LIMIT_DISCOUNT_WEEKLY_GIFTBAG] = require("app.models.datas.LimitDiscountWeeklyGiftbagData"),
	[xyd.ActivityID.LIMIT_DISCOUNT_MONTH_CARD] = require("app.models.datas.LimitDiscountMonthCardData"),
	[xyd.ActivityID.LIMIT_DISCOUNT_MINI_MONTH_CARD] = require("app.models.datas.LimitDiscountMiniMonthCardData"),
	[xyd.ActivityID.LIMIT_DISCOUNT_PRIVILEGE_CARD] = require("app.models.datas.LimitDiscountPrivilegeData"),
	[xyd.ActivityID.LIMIT_DISCOUNT_DAILY_GIFGBAG] = require("app.models.datas.LimitDiscountdailyGiftbagData"),
	[xyd.ActivityID.LIMIT_DISCOUNT_MONTHLY_GIFTBAG02] = require("app.models.datas.LimitDiscountMonthlyGiftbagData02"),
	[xyd.ActivityID.LIMIT_DISCOUNT_WEEKLY_GIFTBAG02] = require("app.models.datas.LimitDiscountWeeklyGiftbagData02"),
	[xyd.ActivityID.LIMIT_DISCOUNT_DAILY_GIFGBAG02] = require("app.models.datas.LimitDiscountdailyGiftbagData02"),
	[xyd.ActivityID.ARCTIC_EXPEDITION] = require("app.models.datas.ArcticExpeditionData"),
	[xyd.ActivityID.ACTIVITY_SANTA_VISIT] = require("app.models.datas.ActivitySantaVisitData"),
	[xyd.ActivityID.ACTIVITY_CHRISTMAS_EXCHANGE] = require("app.models.datas.ActivityChristmasExchangeData"),
	[xyd.ActivityID.ACTIVITY_FIREWORK] = require("app.models.datas.ActivityFireworkData"),
	[xyd.ActivityID.ACTIVITY_FIREWORK_AWARD] = require("app.models.datas.ActivityFireworkAwardData"),
	[xyd.ActivityID.ACTIVITY_LUCKYBOXES_GIFTBAG] = require("app.models.datas.ActivityLuckyboxesGiftbagData"),
	[xyd.ActivityID.BENEFIT_GIFTBAG07] = require("app.models.datas.BenefitGiftbagData"),
	[xyd.ActivityID.ACTIVITY_RECALL_LOTTERY] = require("app.models.datas.ActivityRecallLotteryData"),
	[xyd.ActivityID.ACTIVITY_VAMPIRE_TASK] = require("app.models.datas.ActivityVampireTaskData"),
	[xyd.ActivityID.ACTIVITY_PROMOTION_TEST] = require("app.models.datas.ActivityPromotionTestData"),
	[xyd.ActivityID.ACTIVITY_PROMOTION_TEST_GIFTBAG] = require("app.models.datas.ActivityPromotionTestGiftbagData"),
	[xyd.ActivityID.ACTIVITY_LAFULI_CASTLE] = require("app.models.datas.ActivityLafuliCastleData"),
	[xyd.ActivityID.ACTIVITY_PROMOTION_LADDER] = require("app.models.datas.ActivityPromotionLadderData"),
	[xyd.ActivityID.ACTIVITY_FREEBUY] = require("app.models.datas.ActivityFreeBuyData"),
	[xyd.ActivityID.ACTIVITY_CLOCK] = require("app.models.datas.ActivityClockData"),
	[xyd.ActivityID.ACTIVITY_RECHARGE_LOTTERY] = require("app.models.datas.ActivityRechargeLotteryData"),
	[xyd.ActivityID.ACTIVITY_FOOL_CLOCK_GIFTBAG] = require("app.models.datas.ActivityFoolClockGiftbagData"),
	[xyd.ActivityID.ACTIVITY_EASTER2022] = require("app.models.datas.ActivityEaster2022Data"),
	[xyd.ActivityID.ACTIVITY_SIMULATION_GACHA] = require("app.models.datas.ActivitySimulationGachaData"),
	[xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS] = require("app.models.datas.NewTrialBattlepassData"),
	[xyd.ActivityID.ACTIVITY_RELAY_GIFT] = require("app.models.datas.ActivityRelayGiftData"),
	[xyd.ActivityID.ACTIVITY_LOST_SPACE] = require("app.models.datas.ActivityLostSpaceData"),
	[xyd.ActivityID.ACTIVITY_LOST_SPACE_GIFTBAG] = require("app.models.datas.ActivityLostSpaceGiftData"),
	[xyd.ActivityID.SPRING_GIFTBAG] = require("app.models.datas.SpringGiftbagData"),
	[xyd.ActivityID.ACTIVITY_STAR_ALTAR_MISSION] = require("app.models.datas.ActivityStarAltarMissionData"),
	[xyd.ActivityID.NEW_PARTNER_WARMUP_GIFTBAG] = require("app.models.datas.NewPartnerWarmupGiftbagData"),
	[xyd.ActivityID.ACTIVITY_STAR_ALTAR_GIFTBAG] = require("app.models.datas.StarAltarGiftBagData"),
	[xyd.ActivityID.ACTIVITY_CHILDHOOD_SHOP] = require("app.models.datas.ActivityChildhoodShopData"),
	[xyd.ActivityID.ACTIVITY_CHILDREN_TASK] = require("app.models.datas.ActivityChildrenTaskData"),
	[xyd.ActivityID.ACTIVITY_SPFARM] = require("app.models.datas.ActivitySpfarmData"),
	[xyd.ActivityID.ACTIVITY_DRAGONBOAT2022] = require("app.models.datas.ActivityDragonboat2022Data"),
	[xyd.ActivityID.ACTIVITY_SPFARM_SUPPLY] = require("app.models.datas.ActivitySpfarmSupplyData"),
	[xyd.ActivityID.ACTIVITY_SPFARM_MISSION] = require("app.models.datas.ActivitySpfarmMissionData"),
	[xyd.ActivityID.ACTIVITY_4BIRTHDAY_MUSIC] = require("app.models.datas.Activity4BirthdayMusicData"),
	[xyd.ActivityID.ACTIVITY_4ANNIVERSARY_SIGN] = require("app.models.datas.Activity4AnniversarySignData"),
	[xyd.ActivityID.ACTIVITY_4BIRTHDAY_MISSION] = require("app.models.datas.Activity4BirthdayMission"),
	[xyd.ActivityID.ACTIVITY_4BIRTHDAY_PARTY] = require("app.models.datas.Activity4BirthdayPartyData"),
	[xyd.ActivityID.ACTIVITY_CHIME] = require("app.models.datas.ActivityChimeData"),
	[xyd.ActivityID.ACTIVITY_CUPID_GIFT] = require("app.models.datas.ActivityCupidGiftData"),
	[xyd.ActivityID.ACTIVITY_SAND_SEARCH] = require("app.models.datas.ActivitySandSearchData"),
	[xyd.ActivityID.ACTIVITY_SAND_GIFTBAG] = require("app.models.datas.ActivitySandGiftbagData"),
	[xyd.ActivityID.ACTIVITY_SAND_SHOP] = require("app.models.datas.ActivitySandShopData"),
	[xyd.ActivityID.ACTIVITY_SAND_MISSION] = require("app.models.datas.ActivitySandMissionData"),
	[xyd.ActivityID.ACTIVITY_FREE_REVERGE] = require("app.models.datas.ActivityFreeRevertData"),
	[xyd.ActivityID.ACTIVITY_GOLDFISH] = require("app.models.datas.ActivityGoldfishData"),
	[xyd.ActivityID.ACTIVITY_GOLDFISH_GIFTBAG] = require("app.models.datas.ActivityGoldfishGiftbagData"),
	[xyd.ActivityID.ACTIVITY_GOLDFISH_AWARDS] = require("app.models.datas.ActivityGoldfishAwardsData"),
	[xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION] = require("app.models.datas.ActivityGalaxyTripMissionData"),
	[xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION2] = require("app.models.datas.ActivityGalaxyTripMissionData"),
	[xyd.ActivityID.ACTIVITY_LEGENDARY_SKIN] = require("app.models.datas.ActivityLegendarySkinData"),
	[xyd.ActivityID.ACTIVITY_LEGENDARY_SKIN_GIFTBAG] = require("app.models.datas.ActivityLegendarySkinGiftbagData"),
	[xyd.ActivityID.ACTIVITY_LEGENDARY_SKIN_GIFTBAG] = require("app.models.datas.ActivityLegendarySkinGiftbagData"),
	[xyd.ActivityID.ACTIVITY_INVITATION_SENIOR] = require("app.models.datas.ActivityInvitationSeniorData"),
	[xyd.ActivityID.ACTIVITY_FOOD_CONSUME] = require("app.models.datas.ActivityFoodConsumeData"),
	[xyd.ActivityID.GUILD_NEW_WAR] = require("app.models.datas.GuildNewWarData"),
	[xyd.ActivityID.ACTIVITY_REPAIR_CONSOLE] = require("app.models.datas.ActivityRepairConsoleData"),
	[xyd.ActivityID.ACTIVITY_REPAIR_GIFTBAG] = require("app.models.datas.ActivityRepairGiftBag"),
	[xyd.ActivityID.ACTIVITY_REPAIR_MISSION] = require("app.models.datas.ActivityRepairMissionData"),
	[xyd.ActivityID.ACTIVITY_PIRATE] = require("app.models.datas.ActivityPirateData"),
	[xyd.ActivityID.ACTIVITY_PIRATE_SHOP] = require("app.models.datas.ActivityPirateShopData"),
	[xyd.ActivityID.ACTIVITY_2LOVE] = require("app.models.datas.Activity2LoveData"),
	[xyd.ActivityID.SOUL_LAND_BATTLE_PASS] = require("app.models.datas.SoulLandBattlePassData"),
	[xyd.ActivityID.ACTIVITY_RELAY_GIFT_NEW] = require("app.models.datas.ActivityRelayGiftNewData"),
	[xyd.ActivityID.ACTIVITY_HW2022] = require("app.models.datas.ActivityHw2022Data"),
	[xyd.ActivityID.ACTIVITY_LIMIT_CULTIVATE] = require("app.models.datas.ActivityLimitCultivateData"),
	[xyd.ActivityID.ACTIVITY_HW2022_SHOP] = require("app.models.datas.ActivityHw2022ShopData"),
	[xyd.ActivityID.ACTIVITY_HW2022_SUPPLY] = require("app.models.datas.ActivityHw2022SupplyData"),
	[xyd.ActivityID.ACTIVITY_PROMOTION_LADDER2] = require("app.models.datas.ActivityPromotionLadder2Data")
}
local TableClass = {
	[xyd.ActivityID.CHECKIN] = function ()
		return {
			"activity_login.json"
		}
	end,
	[xyd.ActivityID.SUMMON_GIFTBAG] = function ()
		return {
			"activity_gacha.json"
		}
	end,
	[xyd.ActivityID.PROPHET_SUMMON_GIFTBAG] = function ()
		return {
			"activity_tree.json"
		}
	end,
	[xyd.ActivityID.MIRACLE_GIFTBAG] = function ()
		return {
			"activity_partner_miracle.json"
		}
	end,
	[xyd.ActivityID.WISHING_POOL_GIFTBAG] = function ()
		return {
			"activity_gamble.json"
		}
	end,
	[xyd.ActivityID.PUB_MISSION_GIFTBAG] = function ()
		return {
			"activity_pub_mission.json"
		}
	end,
	[xyd.ActivityID.BATTLE_ARENA_GIFTBAG] = function ()
		return {
			"activity_arena.json"
		}
	end,
	[xyd.ActivityID.SHELTER_GIFTBAG] = function ()
		return {
			"activity_shelter.json"
		}
	end,
	[xyd.ActivityID.SHENXUE_GIFTBAG] = function ()
		return {
			"activity_compose.json"
		}
	end,
	[xyd.ActivityID.HERO_EXCHANGE] = function ()
		return {
			"activity_shop_hero.json"
		}
	end,
	[xyd.ActivityID.QIXI_GIFTBAG] = function ()
		return {
			"activity_giftbox.json"
		}
	end,
	[xyd.ActivityID.SWEETY_HOUSE] = function ()
		return {
			"activity_house.json"
		}
	end,
	[xyd.ActivityID.ACTIVITY_CV] = function ()
		return {
			"activity_cv.json"
		}
	end,
	[xyd.ActivityID.ACTIVITY_WORLD_BOSS] = function ()
		return {
			"activity_boss_award.json",
			"activity_boss.json"
		}
	end,
	[xyd.ActivityID.MID_AUTUMN_ACTIVITY] = function ()
		return {
			"activity_festival.json"
		}
	end,
	[xyd.ActivityID.DARK_GUARD] = function ()
		return {
			"activity_guard.json",
			"activity_guard_text_" .. tostring(xyd.Global.lang) .. ".json"
		}
	end,
	[xyd.ActivityID.ACTIVITY_JIGSAW] = function ()
		return {
			"activity_jigsaw_buy.json",
			"activity_jigsaw_award.json",
			"activity_jigsaw_pic.json",
			"activity_jigsaw_pic_text_" .. tostring(xyd.Global.lang) .. ".json"
		}
	end,
	[xyd.ActivityID.AWAWKE_GIFTBAG] = function ()
		return {
			"activity_compose_10.json"
		}
	end,
	[xyd.ActivityID.CHRISTMAS_1] = function ()
		return {
			"activity_festival_in_file1.json"
		}
	end,
	[xyd.ActivityID.CHRISTMAS_2] = function ()
		return {
			"activity_festival_in_file2.json"
		}
	end,
	[xyd.ActivityID.FAVORABILITY] = function ()
		return {
			"activity_love_point.json"
		}
	end,
	[xyd.ActivityID.NEWYEAR_SIGNIN] = function ()
		return {
			"activity_festival_login.json"
		}
	end,
	[xyd.ActivityID.SAKURA_DATE] = function ()
		return {
			"activity_sakura_date_award.json"
		}
	end,
	[xyd.ActivityID.ACTIVITY_VOTE] = function ()
		return {
			"activity_wedding_vote_list.json",
			"activity_wedding_vote_mission.json",
			"activity_wedding_vote_award.json"
		}
	end,
	[xyd.ActivityID.FIT_UP_DORM] = function ()
		return {
			"activity_fit_up_dorm.json",
			"activity_fit_up_dorm_text_" .. tostring(xyd.Global.lang) .. ".json"
		}
	end,
	[xyd.ActivityID.ACTIVITY_SCHOOL_GIFTBAG] = function ()
		return {
			"activity_school_gift.json",
			"activity_school_gift_exchange.json"
		}
	end,
	[xyd.ActivityID.NEW_SERVER_SUMMON_GIFTBAG] = function ()
		return {
			"activity_gacha_new_server.json"
		}
	end,
	[xyd.ActivityID.PLOT_FINISH_GIFTBAG] = function ()
		return {
			"activity_plot_finish.json"
		}
	end,
	[xyd.ActivityID.EQUIP_GACHA] = function ()
		return {
			"activity_equip_gacha.json"
		}
	end,
	[xyd.ActivityID.UPGRADE_GIFTBAG] = function ()
		return {
			"activity_beach_awards.json"
		}
	end,
	[xyd.ActivityID.BEACH] = function ()
		return {
			"activity_beach_boss.json",
			"activity_beach_matchup.json",
			"activity_beach_awards.json"
		}
	end,
	[xyd.ActivityID.MAKE_CAKE] = function ()
		return {
			"activity_make_cake.json"
		}
	end,
	[xyd.ActivityID.JACKPOT_MACHINE_SCORE] = function ()
		return {
			"activity_jackpot_point.json"
		}
	end,
	[xyd.ActivityID.JACKPOT_MACHINE] = function ()
		return {
			"activity_jackpot_exchange.json",
			"activity_jackpot_machine.json",
			"activity_jackpot_list.json"
		}
	end,
	[xyd.ActivityID.ACTIVITY_CONCERT] = function ()
		return {
			"activity_music_game.json",
			"activity_music_game_text_" .. tostring(xyd.Global.lang) .. ".json"
		}
	end,
	[xyd.ActivityID.ACTIVITY_MUSIC_JIGSAW] = function ()
		return {
			"activity_music_day.json",
			"activity_music_game.json",
			"activity_music_game_text_" .. tostring(xyd.Global.lang) .. ".json"
		}
	end,
	[xyd.ActivityID.LEVEL_FUND] = function ()
		return {
			"activity_level_up.json"
		}
	end,
	[xyd.ActivityID.LIBRARY_WATCHER] = function ()
		return {
			"activity_new_story_award.json",
			"activity_new_story_stage.json"
		}
	end,
	[xyd.ActivityID.BOOK_RESEARCH] = function ()
		return {
			"activity_nsshaft_award2.json"
		}
	end,
	[xyd.ActivityID.CANDY_COLLECT] = function ()
		return {
			"activity_candy_collect.json",
			"activity_candy_collect_text_" .. tostring(xyd.Global.lang) .. ".json"
		}
	end,
	[xyd.ActivityID.LIBRARY_WATCHER2] = function ()
		return {
			"activity_therm_story.json",
			"activity_therm_story_award.json",
			"activity_therm_story_stage.json"
		}
	end,
	[xyd.ActivityID.SUPER_HERO_CLUB] = function ()
		return {
			"activity_partner_jackpot_json.json",
			"activity_partner_jackpot_text_.json"
		}
	end,
	[xyd.ActivityID.ACTIVITY_SEVENDAYS] = function ()
		return {
			"activity_sevendays_awards.json"
		}
	end,
	[xyd.ActivityID.SPORTS] = function ()
		return {
			"activity_sports_robot.json",
			"activity_sports_energy.json",
			"activity_demo_fight.json",
			"activity_sports_achv_type.json",
			"activity_sports_achievement.json",
			"activity_sports_mission.json",
			"activity_tour.json",
			"activity_tour_item.json",
			"activity_tour_plot.json",
			"activity_tour_plot_text_" .. tostring(xyd.Global.lang) .. ".json",
			"activity_sports_rank_award1.json",
			"activity_sports_rank_award3.json",
			"activity_sports_rank_award2.json",
			"activity_sports_rank_award3.json",
			"activity_sports_achievement_text_" .. tostring(xyd.Global.lang) .. ".json",
			"activity_sports_mission_text_" .. tostring(xyd.Global.lang) .. ".json"
		}
	end
}
local PrefabsPath = {
	[xyd.ActivityID.CHECKIN] = "check_in",
	[xyd.ActivityID.MONTH_CARD] = "month_card",
	[xyd.ActivityID.MINI_MONTH_CARD] = "month_card",
	[xyd.ActivityID.MONTHLY_GIFTBAG] = "value_giftbag",
	[xyd.ActivityID.WEEKLY_GIFTBAG] = "value_giftbag",
	[xyd.ActivityID.VALUE_GIFTBAG01] = "value_giftbag",
	[xyd.ActivityID.VALUE_GIFTBAG02] = "value_giftbag",
	[xyd.ActivityID.SUMMON_GIFTBAG] = "summon_giftbag",
	[xyd.ActivityID.FOLLOWING_GIFTBAG] = "following_gift_bag",
	[xyd.ActivityID.ONLINE_AWARD] = "online_award",
	[xyd.ActivityID.BIND_ACCOUNT_ENTRY] = "bind_account_entry",
	[xyd.ActivityID.PUB_MISSION_GIFTBAG] = "list_time_common_activity",
	[xyd.ActivityID.BATTLE_ARENA_GIFTBAG] = "list_time_common_activity",
	[xyd.ActivityID.SHENXUE_GIFTBAG] = "shengxue_giftBag",
	[xyd.ActivityID.ACTIVITY_WORLD_BOSS] = "activity_word_boss",
	[xyd.ActivityID.SUBSCRIPTION] = "subscription_pre",
	[xyd.ActivityID.RING_GIFTBAG] = "ringGiftBag",
	[xyd.ActivityID.LEVEL_FUND] = "level_fund_window",
	[xyd.ActivityID.ACTIVITY_MONTHLY] = "activity_monthly",
	[xyd.ActivityID.SUPER_HERO_CLUB] = "super_hero_club",
	[xyd.ActivityID.DAILY_GIFGBAG] = "value_giftbag",
	[xyd.ActivityID.DAILY_GIFGBAG02] = "value_giftbag",
	[xyd.ActivityID.NEWBIE_CAMP] = "newbie_camp_window",
	[xyd.ActivityID.ACTIVITY_SEVENDAYS] = "activity_seven_day",
	[xyd.ActivityID.ENERGY_SUMMON] = "activity_energy_summon",
	[xyd.ActivityID.WARMUP_GIFT] = "warm_up_gift",
	[xyd.ActivityID.ACTIVITY_SCHOOL_GIFTBAG] = "school_opens_gift_bag",
	[xyd.ActivityID.ACTIVITY_FOOD_FESTIVAL] = "activity_food_festival",
	[xyd.ActivityID.NEW_SUMMON_SPECIAL_HERO_GIFT] = "new_summon_special_hero_gift",
	[xyd.ActivityID.MIRACLE_GIFTBAG] = "miracle_giftbag",
	[xyd.ActivityID.ACTIVITY_KEYBOARD] = "activity_keyboard",
	[xyd.ActivityID.RED_RIDING_HOOD] = "red_riding_hood",
	[xyd.ActivityID.ACTIVITY_BLACK_FRIDAY] = "activity_black_friday"
}

return {
	ModelClass,
	TableClass,
	PrefabsPath
}
