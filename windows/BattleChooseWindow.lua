local BaseWindow = import(".BaseWindow")
local BattleChooseWindow = class("BattleChooseWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local CountDown = import("app.components.CountDown")
local funcNameToDrag = {
	["hero challenge"] = "gHeroChallenge",
	tower = "gTower",
	time_cloister = "timeCloister",
	old_building = "gTower",
	friend_team_boss = "gFriendTeamBoss",
	shrine_hurdle = "shrineHurdle"
}

function BattleChooseWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	if params then
		self.curShowIndex = params.show_index or 1
	else
		self.curShowIndex = 1
	end

	self.skinName = "BattleChooseWindowSkin"
	self.currentState = xyd.Global.lang
	self.guideName = ""

	if xyd.GuideController.get():isPlayGuide() or xyd.getWindow("guide_window") then
		local funcID = xyd.GuideController.get():getGuideID()
		local funcName = xyd.tables.guideTable:getName(funcID)
		self.guideName = funcName

		print("=========self.guideName===========", self.guideName)

		if funcName == "hero challenge" or funcName == "friend_team_boss" or funcName == "tower" or funcName == "old_building" or funcName == "time_cloister" or funcName == "shrine_hurdle" then
			self.curShowIndex = 1
		else
			self.curShowIndex = 2
		end
	end

	self.popWinArr = {
		"academy_assessment_pop_up_window"
	}
	self.popWinIndex = 1
end

function BattleChooseWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponet()
	self:layout()
	self:registerEvent()
	xyd.models.heroChallenge:reqHeroChallengeInfo()
	xyd.models.heroChallenge:reqHeroChallengeChessInfo()

	if xyd.models.shrineHurdleModel:checkFuctionOpen() then
		if not xyd.models.shrineHurdleModel:reqShineHurdleInfo() then
			self:setShrineInfo()
		end

		xyd.models.shrineHurdleModel:getHistoryInfo()
		self.shrineMaskImg:SetActive(false)
		self.shrineTime_:SetActive(true)
	else
		self.shrineMaskImg:SetActive(true)

		local functionOpenTime = xyd.tables.miscTable:getVal("shrine_time_start")

		if xyd.getServerTime() < tonumber(functionOpenTime) then
			self.shrineTime_:SetActive(true)

			self.shrineHurdleTimeLabelTimeTips.text = __("SHRINE_HURDLE_OPEN_TIME")

			if not self.timeCount then
				self.timeCount = CountDown.new(self.shrineHurdleTimeLabelTime)
			end

			self.timeCount:setInfo({
				function ()
					xyd.models.shrineHurdleModel:reqShineHurdleInfo()
				end,
				duration = tonumber(functionOpenTime) - xyd.getServerTime()
			})
		else
			self.shrineTime_:SetActive(false)
		end
	end

	self:initPrivilegeSign()
	self:waitForFrame(1, function ()
		self.tabBar:setTabActive(self.curShowIndex, true)
	end)
end

function BattleChooseWindow:checkPopWinow()
	if self.popWinIndex > #self.popWinArr then
		return
	end

	if self.popWinArr[self.popWinIndex] == "academy_assessment_pop_up_window" and xyd.models.academyAssessment:getIsNewSeason() and not xyd.db.misc:getValue("academy_assessment_pop_up_window_pop_state" .. xyd.models.academyAssessment.seasonId) then
		if xyd.models.academyAssessment:getHasData() == false then
			return
		end

		local imgUrl = "Textures/academy_assessment_web/pop_up/academy_assessment_pop_up_girls_" .. xyd.models.academyAssessment.seasonId

		local function checkAcademyPop()
			local startTime = xyd.models.academyAssessment.startTime
			local allTime = xyd.tables.miscTable:getNumber("school_practise_season_duration", "value")
			local showTime = xyd.tables.miscTable:getNumber("school_practise_display_duration", "value")

			if xyd.getServerTime() < startTime + allTime - showTime and startTime <= xyd.getServerTime() then
				-- Nothing
			elseif xyd.getServerTime() >= startTime + allTime or xyd.getServerTime() < startTime + allTime - showTime then
				return
			end

			if xyd.checkFunctionOpen(xyd.FunctionID.ACADEMY_ASSESSMENT, true) then
				local fort_id = (xyd.models.academyAssessment.seasonId - 1) % 6 + 1

				xyd.WindowManager.get():openWindow("academy_assessment_pop_up_window", {
					fort_id = fort_id
				})
				xyd.db.misc:setValue({
					value = 1,
					key = "academy_assessment_pop_up_window_pop_state" .. xyd.models.academyAssessment.seasonId
				})
				self:waitForTime(2, function ()
					local openWin = xyd.WindowManager.get():getWindow("academy_assessment_pop_up_window")

					if openWin then
						openWin:closeSelf(function ()
							self.popWinIndex = self.popWinIndex + 1

							self:checkPopWinow()
						end)
					end
				end)
			end
		end

		if xyd.isResLoad(imgUrl) then
			checkAcademyPop()
		else
			local imgArr = {}

			table.insert(imgArr, imgUrl)
			ResCache.DownloadAssets("academyAssessment_tips_img", imgArr, function ()
			end, nil)
			self:waitForTime(0.5, function ()
				if xyd.isResLoad(imgUrl) then
					checkAcademyPop()
				end
			end)
		end
	end
end

function BattleChooseWindow:getUIComponet()
	local trans = self.window_.transform
	self.bg = trans:ComponentByName("imgBg/bg_", typeof(UITexture))
	self.resGroup = trans:NodeByName("resGroup").gameObject
	self.main = trans:NodeByName("main").gameObject
	self.nav = self.main:NodeByName("nav").gameObject
	self.tabBar = CommonTabBar.new(self.nav, 2, function (index)
		self:changeTopTap(index)

		if index == 1 then
			self:playMainAction()
		else
			self:playPvpAction()
		end
	end)
	self.hideTips = self.main:NodeByName("hideTips").gameObject
	self.tipsImg = self.hideTips:NodeByName("tipsImg").gameObject
	self.scrollerPVE = self.main:ComponentByName("scrollerPVE", typeof(UIScrollView))
	self.dragPVE = self.main:NodeByName("dragPVE").gameObject
	self.groupPVE = self.scrollerPVE:NodeByName("groupPVE").gameObject
	self.gTower = self.groupPVE:NodeByName("gTower").gameObject
	self.textImg1 = self.gTower:ComponentByName("textImg1", typeof(UISprite))
	self.label_1_1 = self.gTower:ComponentByName("label_1_1", typeof(UILabel))
	self.label_1_2 = self.gTower:ComponentByName("label_1_2", typeof(UILabel))
	self.gTower_redPoint = self.gTower:NodeByName("redPoint").gameObject
	self.gTrial = self.groupPVE:NodeByName("gTrial").gameObject
	self.textImg2 = self.gTrial:ComponentByName("textImg2", typeof(UISprite))
	self.label_2_1 = self.gTrial:ComponentByName("label_2_1", typeof(UILabel))
	self.label_2_2 = self.gTrial:ComponentByName("label_2_2", typeof(UILabel))
	self.alertImg2 = self.gTrial:ComponentByName("alertImg2", typeof(UISprite))
	self.privilege_sign_gTrial = self.gTrial:ComponentByName("privilege_sign", typeof(UISprite))
	self.privilege_con_gTrial = self.privilege_sign_gTrial:NodeByName("privilege_con").gameObject
	self.privilege_textBg_gTrial = self.privilege_con_gTrial:ComponentByName("privilege_textBg", typeof(UISprite))
	self.privilege_textLabel_gTrial = self.privilege_con_gTrial:ComponentByName("privilege_textLabel", typeof(UILabel))
	self.privilege_timeLabel_gTrial = self.privilege_con_gTrial:ComponentByName("privilege_timeLabel", typeof(UILabel))
	self.groupTrialTime = self.gTrial:NodeByName("groupTrialTime").gameObject
	self.trialTimeGroup = self.groupTrialTime:ComponentByName("timeGroup", typeof(UILayout))
	self.labelTimeTrial = self.groupTrialTime:ComponentByName("timeGroup/labelTimeTrial", typeof(UILabel))
	self.tmeTrial = self.groupTrialTime:ComponentByName("timeGroup/tmeTrial", typeof(UILabel))
	self.gDungeon = self.groupPVE:NodeByName("gDungeon").gameObject
	self.textImg3 = self.gDungeon:ComponentByName("textImg3", typeof(UISprite))
	self.label_3_1 = self.gDungeon:ComponentByName("label_3_1", typeof(UILabel))
	self.label_3_2 = self.gDungeon:ComponentByName("label_3_2", typeof(UILabel))
	self.alertImg3 = self.gDungeon:ComponentByName("alertImg3", typeof(UISprite))
	self.privilege_sign_gDungeon = self.gDungeon:ComponentByName("privilege_sign", typeof(UISprite))
	self.privilege_con_gDungeon = self.privilege_sign_gDungeon:NodeByName("privilege_con").gameObject
	self.privilege_textBg_gDungeon = self.privilege_con_gDungeon:ComponentByName("privilege_textBg", typeof(UISprite))
	self.privilege_textLabel_gDungeon = self.privilege_con_gDungeon:ComponentByName("privilege_textLabel", typeof(UILabel))
	self.privilege_timeLabel_gDungeon = self.privilege_con_gDungeon:ComponentByName("privilege_timeLabel", typeof(UILabel))
	self.gDungeonTime = self.gDungeon:NodeByName("gDungeonTime").gameObject
	self.labelTimeDungeon = self.gDungeonTime:ComponentByName("timeGroup/labelTimeDungeon", typeof(UILabel))
	self.timeDungeon = self.gDungeonTime:ComponentByName("timeGroup/timeDungeon", typeof(UILabel))
	self.gTowerTime = self.gTower:NodeByName("gTowerTime").gameObject
	self.labelTimeTower = self.gTowerTime:ComponentByName("timeGroup/labelTimeTower", typeof(UILabel))
	self.timeTower = self.gTowerTime:ComponentByName("timeGroup/timeTower", typeof(UILabel))
	self.gHeroChallenge = self.groupPVE:NodeByName("gHeroChallenge").gameObject
	self.imgHChallenge = self.gHeroChallenge:ComponentByName("imgHChallenge", typeof(UISprite))
	self.labelHChallenge = self.gHeroChallenge:ComponentByName("labelHChallenge", typeof(UILabel))
	self.alertImg7 = self.gHeroChallenge:ComponentByName("alertImg7", typeof(UISprite))
	self.gFriendTeamBoss = self.groupPVE:NodeByName("gFriendTeamBoss").gameObject
	self.textImg5 = self.gFriendTeamBoss:ComponentByName("textImg5", typeof(UISprite))
	self.label_5_1 = self.gFriendTeamBoss:ComponentByName("label_5_1", typeof(UILabel))
	self.alertImg8 = self.gFriendTeamBoss:NodeByName("alertImg8").gameObject
	self.gAcademyAssessment = self.groupPVE:NodeByName("gAcademyAssessment").gameObject
	self.imgAcademyAssessment = self.gAcademyAssessment:ComponentByName("imgAcademyAssessment", typeof(UISprite))
	self.labelAcademyAssessment = self.gAcademyAssessment:ComponentByName("labelAcademyAssessment", typeof(UILabel))
	self.alertImg1 = self.gAcademyAssessment:NodeByName("alertImg1").gameObject
	self.groupAcademyTime = self.gAcademyAssessment:NodeByName("gAcademyTime").gameObject
	self.labelTimeAcademy = self.groupAcademyTime:ComponentByName("timeGroup/labelTimeAcademy", typeof(UILabel))
	self.timeAcademy = self.groupAcademyTime:ComponentByName("timeGroup/timeAcademy", typeof(UILabel))
	self.timeCloister = self.groupPVE:NodeByName("timeCloister").gameObject
	self.imgTimeCloister = self.timeCloister:ComponentByName("imgTimeCloister", typeof(UISprite))
	self.labelTimeCloister = self.timeCloister:ComponentByName("labelTimeCloister", typeof(UILabel))
	self.alertImg9 = self.timeCloister:NodeByName("alertImg9").gameObject
	self.timeCloisterTimeGroup = self.timeCloister:ComponentByName("groupTime/timeGroup", typeof(UILayout))
	self.timeCloisterLabelEnd = self.timeCloisterTimeGroup:ComponentByName("labelEnd", typeof(UILabel))
	self.timeCloisterLabelTime = self.timeCloisterTimeGroup:ComponentByName("labelTime", typeof(UILabel))
	self.shrineHurdle = self.groupPVE:NodeByName("gShrineHurdle").gameObject
	self.shrineMaskImg = self.shrineHurdle:NodeByName("imgMask").gameObject
	self.alertImg10 = self.shrineHurdle:NodeByName("alertImg10").gameObject
	self.imgShrineHurdleText = self.shrineHurdle:ComponentByName("textImg3", typeof(UISprite))
	self.labelShrineHurdle = self.shrineHurdle:ComponentByName("labelDesc", typeof(UILabel))
	self.shrineTime_ = self.shrineHurdle:NodeByName("timeGroup").gameObject
	self.shrineHurdleTimeGroup = self.shrineHurdle:ComponentByName("timeGroup/timeGroup", typeof(UILayout))
	self.shrineHurdleTimeLabelTimeTips = self.shrineHurdle:ComponentByName("timeGroup/timeGroup/labelTips", typeof(UILabel))
	self.shrineHurdleTimeLabelTime = self.shrineHurdle:ComponentByName("timeGroup/timeGroup/time", typeof(UILabel))
	self.orderPVE = {
		self.gTower,
		self.gTrial,
		self.timeCloister,
		self.gDungeon,
		self.gHeroChallenge,
		self.gFriendTeamBoss,
		self.gAcademyAssessment,
		self.shrineHurdle
	}
	self.pveRedList = {
		self.gTower_redPoint,
		self.alertImg1,
		self.alertImg2.gameObject,
		self.alertImg3.gameObject,
		self.alertImg7.gameObject,
		self.alertImg8,
		self.alertImg9,
		self.alertImg10
	}
	self.groupPVP = self.main:NodeByName("groupPVP").gameObject
	self.gArena = self.groupPVP:NodeByName("gArena").gameObject
	self.arenaImage = self.gArena:ComponentByName("e:Image", typeof(UISprite))
	self.arenaLabel = self.gArena:ComponentByName("arenaLabel", typeof(UISprite))
	self.arenaLabel2 = self.gArena:ComponentByName("arenaLabel2", typeof(UILabel))
	self.groupArenaTime = self.gArena:NodeByName("groupArenaTime").gameObject
	self.arenaTimeGroup = self.groupArenaTime:NodeByName("arenaTimeGroup").gameObject
	self.arenaLabelTime = self.arenaTimeGroup:ComponentByName("arenaLabelTime", typeof(UILabel))
	self.arenaTime = self.arenaTimeGroup:ComponentByName("arenaTime", typeof(UILabel))
	self.arenaBtnBate = self.gArena:NodeByName("arenaBtnBate").gameObject
	self.gArenaTeam = self.groupPVP:NodeByName("gArenaTeam").gameObject
	self.arenaTeamLabel = self.gArenaTeam:ComponentByName("arenaTeamLabel", typeof(UISprite))
	self.arenaTeamLabel2 = self.gArenaTeam:ComponentByName("arenaTeamLabel2", typeof(UILabel))
	self.alertImg5 = self.gArenaTeam:ComponentByName("alertImg5", typeof(UISprite))
	self.groupTeamTime = self.gArenaTeam:NodeByName("groupTeamTime").gameObject
	self.labelTimeTeam = self.groupTeamTime:ComponentByName("timeGroup/labelTimeTeam", typeof(UILabel))
	self.timeTeam = self.groupTeamTime:ComponentByName("timeGroup/timeTeam", typeof(UILabel))
	self.gArena3v3 = self.groupPVP:NodeByName("gArena3v3").gameObject
	self.arena3v3Label = self.gArena3v3:ComponentByName("arena3v3Label", typeof(UISprite))
	self.arena3v3Label2 = self.gArena3v3:ComponentByName("arena3v3Label2", typeof(UILabel))
	self.alertImg4 = self.gArena3v3:ComponentByName("alertImg4", typeof(UISprite))
	self.group3v3Time = self.gArena3v3:NodeByName("group3v3Time").gameObject
	self.labelTime3v3 = self.group3v3Time:ComponentByName("timeGroup/labelTime3v3", typeof(UILabel))
	self.time3v3 = self.group3v3Time:ComponentByName("timeGroup/time3v3", typeof(UILabel))
	self.gArenaAllServer = self.groupPVP:NodeByName("gArenaAllServer").gameObject
	self.imgArenaAllServer = self.gArenaAllServer:ComponentByName("imgArenaAllServer", typeof(UISprite))
	self.labelArenaAllServer = self.gArenaAllServer:ComponentByName("labelArenaAllServer", typeof(UILabel))
	self.alertImg6 = self.gArenaAllServer:ComponentByName("alertImg6", typeof(UISprite))
	self.groupAllServerTime = self.gArenaAllServer:NodeByName("groupAllServerTime").gameObject
	self.labelTimeAllServerLayout = self.groupAllServerTime:ComponentByName("timeGroup", typeof(UILayout))
	self.labelTimeAllServer = self.groupAllServerTime:ComponentByName("timeGroup/labelTimeAllServer", typeof(UILabel))
	self.timeAllServer = self.groupAllServerTime:ComponentByName("timeGroup/timeAllServer", typeof(UILabel))
end

function BattleChooseWindow:initPrivilegeSign()
	local privilegeData = xyd.models.activity:getActivity(xyd.ActivityID.PRIVILEGE_CARD)

	if not privilegeData or privilegeData:isHide() ~= false then
		return
	end

	self.trialActive = privilegeData:getStateById(xyd.GIFTBAG_ID.PRIVILEGE_CARD_TRIAL)
	self.dungeonActive = privilegeData:getStateById(xyd.GIFTBAG_ID.PRIVILEGE_CARD_DUNGEON)
	self.privilege_textLabel_gTrial.text = __("PRIVILEGE_CARD_ACTIVE_AND_LEFT_TIME")
	self.privilege_textLabel_gDungeon.text = __("PRIVILEGE_CARD_ACTIVE_AND_LEFT_TIME")

	self.privilege_textLabel_gTrial:X(32)
	self.privilege_textLabel_gDungeon:X(32)

	UIEventListener.Get(self.privilege_sign_gTrial.gameObject).onClick = handler(self, function ()
		if self.trialActive then
			self.privilege_con_gTrial:SetActive(not self.privilege_con_gTrial.activeSelf)
		end
	end)
	UIEventListener.Get(self.privilege_sign_gDungeon.gameObject).onClick = handler(self, function ()
		if self.dungeonActive then
			self.privilege_con_gDungeon:SetActive(not self.privilege_con_gDungeon.activeSelf)
		end
	end)

	self:updatePrivilegeSign()
end

function BattleChooseWindow:updatePrivilegeSign()
	local privilegeData = xyd.models.activity:getActivity(xyd.ActivityID.PRIVILEGE_CARD)

	if not privilegeData or privilegeData:isHide() ~= false then
		return
	end

	self.trialActive = privilegeData:getStateById(xyd.GIFTBAG_ID.PRIVILEGE_CARD_TRIAL)
	self.dungeonActive = privilegeData:getStateById(xyd.GIFTBAG_ID.PRIVILEGE_CARD_DUNGEON)

	if privilegeData then
		self.privilege_sign_gTrial:SetActive(self.trialActive)
		self.privilege_sign_gDungeon:SetActive(self.dungeonActive)
	end

	local datas = privilegeData.detail.charges
	local serverTime = xyd.getServerTime()

	for i in pairs(datas) do
		if datas[i].table_id == xyd.GIFTBAG_ID.PRIVILEGE_CARD_TRIAL or xyd.tables.giftBagTable:getParams(datas[i].table_id) and xyd.tables.giftBagTable:getParams(datas[i].table_id)[1] == xyd.GIFTBAG_ID.PRIVILEGE_CARD_TRIAL then
			local countDays = 0
			local timeDis = datas[i].end_time - serverTime

			if timeDis > 0 then
				countDays = math.ceil(timeDis / 86400)
				self.privilege_timeLabel_gTrial.text = __("DAY", tostring(countDays))

				self.privilege_timeLabel_gTrial:X(32 + self.privilege_textLabel_gTrial.width + 10)

				self.privilege_textBg_gTrial.width = 32 + self.privilege_textLabel_gTrial.width + 10 + self.privilege_timeLabel_gTrial.width + 80
			end
		end

		if datas[i].table_id == xyd.GIFTBAG_ID.PRIVILEGE_CARD_DUNGEON or xyd.tables.giftBagTable:getParams(datas[i].table_id) and xyd.tables.giftBagTable:getParams(datas[i].table_id)[1] == xyd.GIFTBAG_ID.PRIVILEGE_CARD_DUNGEON then
			local countDays = 0
			local timeDis = datas[i].end_time - serverTime

			if timeDis > 0 then
				countDays = math.ceil(timeDis / 86400)
				self.privilege_timeLabel_gDungeon.text = __("DAY", tostring(countDays))

				self.privilege_timeLabel_gDungeon:X(32 + self.privilege_textLabel_gDungeon.width + 10)

				self.privilege_textBg_gDungeon.width = 32 + self.privilege_textLabel_gDungeon.width + 10 + self.privilege_timeLabel_gDungeon.width + 80
			end
		end
	end
end

function BattleChooseWindow:layout()
	xyd.setUITextureAsync(self.bg, "Textures/scenes_web/battle_choose_win_bg")
	self:initResItem()
	self:layoutPVP()
	self:layoutPVE()
	self:changeByLang()

	if xyd.Global.isReview == 1 then
		self.nav:SetActive(false)
	end

	if xyd.Global.isReview == 1 then
		self:changeTopTap(2)
	end

	if not xyd.checkFunctionOpen(xyd.FunctionID.ARENA, true) then
		self.gArena:NodeByName("imgMask").gameObject:SetActive(true)
	end

	if not xyd.checkFunctionOpen(xyd.FunctionID.ARENA_3v3, true) then
		self.gArena3v3:NodeByName("imgMask").gameObject:SetActive(true)
	end

	if not xyd.checkFunctionOpen(xyd.FunctionID.ARENA_TEAM, true) then
		self.gArenaTeam:NodeByName("imgMask").gameObject:SetActive(true)
	end

	if not xyd.checkFunctionOpen(xyd.FunctionID.TOWER, true) then
		self.gTower:NodeByName("imgMask").gameObject:SetActive(true)
	end

	if not xyd.checkFunctionOpen(xyd.FunctionID.TRIAL, true) then
		self.gTrial:NodeByName("imgMask").gameObject:SetActive(true)
	end

	if not xyd.checkFunctionOpen(xyd.FunctionID.DUNGEON, true) then
		self.gDungeon:NodeByName("imgMask").gameObject:SetActive(true)
	end

	if not xyd.checkFunctionOpen(xyd.FunctionID.HERO_CHALLENGE, true) then
		self.gHeroChallenge:NodeByName("imgMask").gameObject:SetActive(true)
	end

	if not xyd.checkFunctionOpen(xyd.FunctionID.ACADEMY_ASSESSMENT, true) then
		self.gAcademyAssessment:NodeByName("imgMask").gameObject:SetActive(true)
	end

	if not xyd.checkFunctionOpen(xyd.FunctionID.ARENA_ALL_SERVER, true) then
		self.gArenaAllServer:NodeByName("imgMask").gameObject:SetActive(true)
	end

	if not xyd.checkFunctionOpen(xyd.FunctionID.FRIEND_TEAM_BOSS, true) then
		self.gFriendTeamBoss:NodeByName("imgMask").gameObject:SetActive(true)
	end

	if not xyd.checkFunctionOpen(xyd.FunctionID.TIME_CLOISTER, true) then
		self.timeCloister:NodeByName("imgMask").gameObject:SetActive(true)
		self.timeCloister:NodeByName("groupTime").gameObject:SetActive(false)
	end
end

function BattleChooseWindow:initResItem()
	local winTop = WindowTop.new(self.window_, self.name_, 1, true)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	winTop:setItem(items)
end

function BattleChooseWindow:layoutPVE()
	xyd.setUISpriteAsync(self.textImg1, nil, "tower_text_" .. xyd.Global.lang, function ()
	end, false, true)
	xyd.setUISpriteAsync(self.textImg2, nil, "trial_text_" .. xyd.Global.lang, function ()
	end, false, true)
	xyd.setUISpriteAsync(self.textImg3, nil, "dungeon_text_" .. xyd.Global.lang, function ()
	end, false, true)
	xyd.setUISpriteAsync(self.textImg5, nil, "friend_team_boss_text_" .. xyd.Global.lang, function ()
	end, false, true)
	xyd.setUISpriteAsync(self.imgHChallenge, nil, "h_challenge_text_" .. xyd.Global.lang, function ()
	end, false, true)

	self.labelHChallenge.text = __("HERO_CHALLENGE_MISC")

	xyd.setUISpriteAsync(self.imgAcademyAssessment, nil, "academy_assessment_label_" .. xyd.Global.lang, function ()
	end, false, true)
	xyd.setUISpriteAsync(self.imgTimeCloister, nil, "time_cloister_text_" .. xyd.Global.lang, nil, false, true)

	self.labelTimeCloister.text = __("TIME_CLOISTER_MISC")
	self.labelAcademyAssessment.text = __("ACADEMY_ASSESSMENT_MISC")
	self.tabBar.tabs[1].label.text = __("FIGHT")
	self.tabBar.tabs[2].label.text = __("OTHER_BATTLE")
	self.label_1_1.text = __("TOWER_MISC")
	self.label_2_1.text = __("TRIAL_MISC")
	self.label_3_1.text = __("DUNGEON_MISC")
	self.label_5_1.text = __("FRIEND_TEAM_BOSS_DESC")

	self:updateOpenBlock(self.gTower, xyd.FunctionID.TOWER)
	self:updateOpenBlock(self.gDungeon, xyd.FunctionID.DUNGEON)
	self:updateOpenBlock(self.gTrial, xyd.FunctionID.TRIAL)
	self:updateOpenBlock(self.gHeroChallenge, xyd.FunctionID.HERO_CHALLENGE)
	self:updateOpenBlock(self.gFriendTeamBoss, xyd.FunctionID.FRIEND_TEAM_BOSS)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.TRIAL, self.alertImg2.gameObject)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.DUNGEON, self.alertImg3.gameObject)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.HERO_CHALLENGE, self.alertImg7.gameObject)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.ACADEMY_ASSESSMENT, self.alertImg1.gameObject)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.OLD_SCHOOL,
		xyd.RedMarkType.TOWER_FUND_GIFTBAG
	}, self.gTower_redPoint.gameObject)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.FRIEND_TEAM_BOSS,
		xyd.RedMarkType.FRIEND_TEAM_BOSS_APPLY,
		xyd.RedMarkType.FRIEND_TEAM_BOSS_INVITED,
		xyd.RedMarkType.FRIEND_TEAM_BOSS_MSG,
		xyd.RedMarkType.FRIEND_TEAM_BOSS_MSG2
	}, self.alertImg8)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.TIME_CLOISTER_CAN_PROBE,
		xyd.RedMarkType.TIME_CLOISTER_PROBE_COMPLETED,
		xyd.RedMarkType.TIME_CLOISTER_ACHIEVEMENT,
		xyd.RedMarkType.TIME_CLOISTER_BATTLE
	}, self.alertImg9)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.SHRINE_CHIME,
		xyd.RedMarkType.SHRINE_NOTICE
	}, self.alertImg10)
	xyd.models.trial:setRedMark()
	xyd.models.academyAssessment:setRedMark()

	local nowTime = xyd.getServerTime()

	if xyd.models.trial:checkFunctionOpen() then
		self.groupTrialTime:SetActive(true)

		if xyd.models.trial:checkClose() then
			local opentime = xyd.tables.miscTable:getVal("new_trial_restart_open_time")

			self.tmeTrial.gameObject:SetActive(false)

			self.timeTrial = CountDown.new(self.labelTimeTrial, {
				key = "NEW_TRIAL_RESET_TEXT02",
				duration = tonumber(opentime) - nowTime
			})

			self.labelTimeTrial:X(0)
			self.tmeTrial:X(0)
		else
			self.tmeTrial.gameObject:SetActive(true)

			local data = xyd.models.trial:getData()
			local boss_id = data.boss_id

			if data.is_open and data.is_open ~= 0 then
				self.labelTimeTrial.text = __("TRIAL_CLOSE_COUNTDOWN")
				self.timeTrial = CountDown.new(self.tmeTrial, {
					duration = data.end_time - nowTime
				})
			elseif data.start_time then
				self.labelTimeTrial.text = __("TRIAL_NEW_COUNTDOWN")
				self.timeTrial = CountDown.new(self.tmeTrial, {
					duration = data.end_time + 3600 - nowTime
				})
			end

			self.trialTimeGroup:Reposition()
		end
	else
		self.groupTrialTime:SetActive(false)
	end

	if xyd.models.dungeon:checkFunctionOpen() then
		self.gDungeonTime:SetActive(true)

		local data = xyd.models.dungeon:getData()

		if data.is_open and data.is_open ~= 0 then
			self.labelTimeDungeon.text = __("DUNGEON_CLOSE_COUNTDOWN")
			self.timeDungonCount = CountDown.new(self.timeDungeon, {
				duration = data.end_time - xyd.getServerTime()
			})
		elseif data.start_time then
			self.labelTimeDungeon.text = __("DUNGEON_NEW_COUNTDOWN")
			self.timeDungonCount = CountDown.new(self.timeDungeon, {
				duration = data.start_time - xyd.getServerTime()
			})
		else
			self.gDungeonTime:SetActive(false)
		end

		local width1 = self.labelTimeDungeon.width
		local width2 = self.tmeTrial.width

		self.labelTimeDungeon:X(-width1 / 2 - width2 / 2)
		self.timeDungeon:X(width1 / 2 - width2 / 2)
	else
		self.gDungeonTime:SetActive(false)
	end

	if xyd.models.oldSchool:isCanOpen() then
		self.gTowerTime:SetActive(true)

		if xyd.getServerTime() < xyd.models.oldSchool:getChallengeEndTime() then
			local durationTime = xyd.models.oldSchool:getChallengeEndTime() - xyd.getServerTime()
			self.labelTimeTower.text = __("OLD_SCHOOL_CLOSE_TIME")
			self.timeTowerCount = CountDown.new(self.timeTower, {
				duration = durationTime
			})
		else
			local durationTime = xyd.models.oldSchool:getShowEndTime() - xyd.getServerTime()
			self.labelTimeTower.text = __("OLD_SCHOOL_OPEN_TIME")
			self.timeTowerCount = CountDown.new(self.timeTower, {
				duration = durationTime
			})
		end

		local width1 = self.labelTimeTower.width
		local width2 = self.timeTower.width

		self.labelTimeTower:X(-width1 / 2 - width2 / 2)
		self.timeTower:X(width1 / 2 - width2 / 2)
	else
		self.gTowerTime:SetActive(false)
	end

	if xyd.models.academyAssessment:checkFunctionOpen() then
		self.groupAcademyTime:SetActive(true)

		local startTime = xyd.models.academyAssessment.startTime or 0
		local allTime = xyd.tables.miscTable:getNumber("school_practise_season_duration", "value")
		local showTime = xyd.tables.miscTable:getNumber("school_practise_display_duration", "value")
		local tmpTime = startTime + allTime - showTime

		if startTime <= xyd.getServerTime() and xyd.getServerTime() - startTime < xyd.TimePeriod.DAY_TIME then
			self.labelTimeAcademy.text = __("SCHOOL_PRACTICE_NEW_SEASON")
			self.labelTimeAcademy.color = Color.New2(2986279167.0)
			self.labelTimeAcademy.effectColor = Color.New2(977490687)
		elseif xyd.getServerTime() < tmpTime and xyd.getServerTime() >= tmpTime - xyd.TimePeriod.DAY_TIME then
			self.labelTimeAcademy.text = __("SCHOOL_PRACTICE_FINISH")
			self.labelTimeAcademy.color = Color.New2(4291856383.0)
			self.labelTimeAcademy.effectColor = Color.New2(977490687)
		elseif xyd.getServerTime() < startTime + allTime and tmpTime <= xyd.getServerTime() then
			self.labelTimeAcademy.text = __("SCHOOL_PRACTICE_DISPLAY")
			self.labelTimeAcademy.color = Color.New2(4291856383.0)
			self.labelTimeAcademy.effectColor = Color.New2(977490687)
		else
			self.groupAcademyTime:SetActive(false)
		end
	else
		self.groupAcademyTime:SetActive(false)
	end

	if xyd.checkFunctionOpen(xyd.FunctionID.TIME_CLOISTER, true) then
		self:setTimeCloisterInfo()
	end

	self.labelShrineHurdle.text = xyd.tables.functionTextTable:getDesc(xyd.FunctionID.SHRINE_HURDLE)

	xyd.setUISpriteAsync(self.imgShrineHurdleText, nil, "shrine_hurdle_text_" .. xyd.Global.lang, nil, , true)
	self:onDragMoving()
	self.scrollerPVE:ResetPosition()

	if xyd.GuideController.get():isPlayGuide() or xyd.getWindow("guide_window") then
		local funcID = xyd.GuideController.get():getGuideID()
		local funcName = xyd.tables.guideTable:getName(funcID)

		if funcName == "friend_team_boss" then
			self.scrollerPVE:MoveRelative(Vector3(0, 426, 0))
		elseif funcName == "hero challenge" then
			self.scrollerPVE:MoveRelative(Vector3(0, 194, 0))
		elseif funcName == "shrine_hurdle" then
			self.orderPVE = {
				self.gTower,
				self.shrineHurdle,
				self.gTrial,
				self.timeCloister,
				self.gDungeon,
				self.gHeroChallenge,
				self.gFriendTeamBoss,
				self.gAcademyAssessment
			}

			self.shrineHurdle.transform:SetSiblingIndex(1)
		end

		local componentName = funcNameToDrag[funcName]

		if componentName then
			self[componentName]:GetComponent(typeof(UIDragScrollView)).enabled = false
		end
	else
		self:changePVEorder()
	end
end

function BattleChooseWindow:setShrineInfo()
	local startTime = xyd.models.shrineHurdleModel:getStartTime()
	local timeSet = xyd.tables.miscTable:split2num("shrine_time_interval", "value", "|")
	local timePass = math.fmod(xyd.getServerTime() - startTime, (timeSet[1] + timeSet[2]) * xyd.DAY_TIME)

	self.shrineTime_:SetActive(true)

	if not self.timeCount then
		self.timeCount = CountDown.new(self.shrineHurdleTimeLabelTime)
	end

	if timePass <= timeSet[1] * xyd.DAY_TIME then
		self.shrineHurdleTimeLabelTimeTips.text = __("SHRINE_HURDLE_CLOSE_TIME")

		self.timeCount:setInfo({
			duration = timeSet[1] * xyd.DAY_TIME - timePass
		})
	else
		self.shrineHurdleTimeLabelTimeTips.text = __("SHRINE_HURDLE_OPEN_TIME")

		self.timeCount:setInfo({
			duration = (timeSet[1] + timeSet[2]) * xyd.DAY_TIME - timePass
		})
	end

	self.shrineHurdleTimeGroup:Reposition()
end

function BattleChooseWindow:setTimeCloisterInfo()
	local state, leftTime = nil

	if xyd.models.timeCloisterModel:getCloisterInfo() then
		local hangInfo = xyd.models.timeCloisterModel:getHangInfo()

		if hangInfo then
			if hangInfo.stop_time and hangInfo.stop_time > 0 then
				state = "over"
			else
				state = "going"
				leftTime = xyd.models.timeCloisterModel.leftProbeTime
			end
		else
			state = "free"
		end
	else
		local loginInfo = xyd.models.timeCloisterModel:getLoginInfo()

		if not loginInfo or loginInfo.cloister_id == 0 then
			state = "free"
		elseif loginInfo.stop_time > 0 then
			state = "over"
		else
			state = "going"
			local energyTime = tonumber(xyd.tables.miscTable:getVal("time_cloister_energy_time"))
			leftTime = math.ceil(loginInfo.energy * energyTime - 0.1) + loginInfo.start_time - xyd.getServerTime()
		end
	end

	if state == "over" then
		self.timeCloisterLabelEnd.text = __("TIME_CLOISTER_TEXT56")

		self.timeCloisterLabelTime:SetActive(false)

		if self.timeCloisterTimeCount then
			self.timeCloisterTimeCount:stopTimeCount()
		end
	elseif state == "free" then
		self.timeCloisterLabelEnd.text = __("TIME_CLOISTER_TEXT57")

		self.timeCloisterLabelTime:SetActive(false)

		if self.timeCloisterTimeCount then
			self.timeCloisterTimeCount:stopTimeCount()
		end
	else
		self.timeCloisterLabelEnd.text = __("TIME_CLOISTER_TEXT55")

		self.timeCloisterLabelTime:SetActive(true)

		if not self.timeCloisterTimeCount then
			self.timeCloisterTimeCount = CountDown.new(self.timeCloisterLabelTime)
		end

		self.timeCloisterTimeCount:setInfo({
			duration = leftTime,
			callback = function ()
				self.timeCloisterLabelEnd.text = __("TIME_CLOISTER_TEXT56")

				self.timeCloisterLabelTime:SetActive(false)

				if self.timeCloisterTimeCount then
					self.timeCloisterTimeCount:stopTimeCount()
				end
			end
		})
	end

	self.timeCloisterTimeGroup:Reposition()
end

function BattleChooseWindow:changePVEorder()
	self.orderPVE = {
		self.gTower,
		self.gTrial,
		self.gDungeon,
		self.gHeroChallenge,
		self.timeCloister,
		self.gAcademyAssessment,
		self.gFriendTeamBoss,
		self.shrineHurdle
	}

	if xyd.checkFunctionOpen(xyd.FunctionID.ACADEMY_ASSESSMENT, true) then
		self.timeCloister.transform:SetSiblingIndex(4)
		self.gAcademyAssessment.transform:SetSiblingIndex(5)
	end

	local trialData = xyd.models.trial:getData()

	if not trialData or not trialData.is_open or trialData.is_open == 0 then
		self.gTrial.transform:SetSiblingIndex(7)

		for i, item in ipairs(self.orderPVE) do
			if item == self.gTrial then
				table.remove(self.orderPVE, i)

				break
			end
		end

		table.insert(self.orderPVE, self.gTrial)
	end

	if not xyd.models.redMark:getRedState(xyd.RedMarkType.HERO_CHALLENGE) then
		self.gHeroChallenge.transform:SetSiblingIndex(7)

		for i, item in ipairs(self.orderPVE) do
			if item == self.gHeroChallenge then
				table.remove(self.orderPVE, i)

				break
			end
		end

		table.insert(self.orderPVE, self.gHeroChallenge)
	end

	local dungeonData = xyd.models.dungeon:getData()

	if not dungeonData and not dungeonData.is_open or dungeonData.is_open == 0 then
		self.gDungeon.transform:SetSiblingIndex(7)

		for i, item in ipairs(self.orderPVE) do
			if item == self.gDungeon then
				table.remove(self.orderPVE, i)

				break
			end
		end

		table.insert(self.orderPVE, self.gDungeon)
	end

	if not xyd.models.heroChallenge:checkNeedShowRed() then
		self.gHeroChallenge.transform:SetSiblingIndex(7)

		for i, item in ipairs(self.orderPVE) do
			if item == self.gHeroChallenge then
				table.remove(self.orderPVE, i)

				break
			end
		end

		table.insert(self.orderPVE, self.gHeroChallenge)
	end

	local startTime = xyd.models.academyAssessment.startTime or 0
	local allTime = xyd.tables.miscTable:getNumber("school_practise_season_duration", "value")
	local showTime = xyd.tables.miscTable:getNumber("school_practise_display_duration", "value")
	local tmpTime = startTime + allTime - showTime

	if not xyd.checkFunctionOpen(xyd.FunctionID.ACADEMY_ASSESSMENT, true) or xyd.getServerTime() < startTime + allTime and tmpTime <= xyd.getServerTime() then
		self.gAcademyAssessment.transform:SetSiblingIndex(7)

		for i, item in ipairs(self.orderPVE) do
			if item == self.gAcademyAssessment then
				table.remove(self.orderPVE, i)

				break
			end
		end

		table.insert(self.orderPVE, self.gAcademyAssessment)
	end

	if not xyd.models.shrineHurdleModel:checkFuctionOpen() or not xyd.models.shrineHurdleModel:checkInBattleTime() then
		self.shrineHurdle.transform:SetSiblingIndex(7)

		for i, item in ipairs(self.orderPVE) do
			if item == self.shrineHurdle then
				table.remove(self.orderPVE, i)

				break
			end
		end

		table.insert(self.orderPVE, self.shrineHurdle)
	end

	if not xyd.models.friendTeamBoss:checkInFight() then
		self.gFriendTeamBoss.transform:SetSiblingIndex(7)

		for i, item in ipairs(self.orderPVE) do
			if item == self.gFriendTeamBoss then
				table.remove(self.orderPVE, i)

				break
			end
		end

		table.insert(self.orderPVE, self.gFriendTeamBoss)
	end
end

function BattleChooseWindow:onDragMoving()
	local flag = false

	for _, obj in ipairs(self.pveRedList) do
		if obj and obj.activeSelf and self.main then
			local pos = self.main.transform:InverseTransformPoint(obj.transform.position)
			flag = pos.y < self.hideTips.transform.localPosition.y
		end

		if flag then
			break
		end
	end

	if self.tipsImg then
		self.tipsImg:SetActive(flag)
	end
end

function BattleChooseWindow:changeByLang()
	if xyd.lang == "fr_fr" then
		self.imgTimeCloister:X(215)
		self.imgTimeCloister:Y(50)
		self.imgTimeCloister:SetLocalScale(0.9, 0.9, 1)
		self.labelTimeCloister:Y(8)

		if xyd.models.oldSchool:isCanOpen() then
			self.label_1_1:Y(10)
		end
	end

	if xyd.Global.lang == "de_de" then
		self.labelTimeCloister.width = 200

		self.arena3v3Label2:Y(20)
		self.arenaTeamLabel2:Y(30)
		self.label_1_1:Y(5)
		self.labelTimeCloister:Y(8)
		self.imgTimeCloister:Y(60)
	end
end

function BattleChooseWindow:layoutPVP()
	xyd.setUISpriteAsync(self.arenaLabel, nil, "arena_label_" .. xyd.Global.lang, nil, false, true)
	xyd.setUISpriteAsync(self.arena3v3Label, nil, "arena3v3_label_" .. xyd.Global.lang, nil, false, true)
	xyd.setUISpriteAsync(self.arenaTeamLabel, nil, "arena_team_label_" .. xyd.Global.lang, nil, false, true)
	xyd.setUISpriteAsync(self.imgArenaAllServer, nil, "arena_allserver_label_" .. xyd.Global.lang, nil, false, true)

	self.arenaLabel2.text = __("ARENA_MISC")
	self.arena3v3Label2.text = __("ARENA_3V3_MISC")
	self.arenaTeamLabel2.text = __("ARENA_PARTNER_MISC")
	self.labelArenaAllServer.text = __("ARENA_ALL_SERVER_MISC")

	if xyd.Global.lang == "de_de" then
		self.labelArenaAllServer.transform:Y(10)

		self.labelArenaAllServer.spacingY = 0
	end

	self:updateOpenBlock(self.gArena, xyd.FunctionID.ARENA)
	self:updateOpenBlock(self.gArena3v3, xyd.FunctionID.ARENA_3v3)
	self:updateOpenBlock(self.gArenaTeam, xyd.FunctionID.ARENA_TEAM)
	self:updateOpenBlock(self.gArenaAllServer, xyd.FunctionID.ARENA_ALL_SERVER)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.ARENA_3v3, self.alertImg4.gameObject)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.ARENA_TEAM
	}, self.alertImg5.gameObject)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.ARENA_ALL_SERVER,
		xyd.RedMarkType.ARENA_ALL_SERVER_SCORE_MISSION,
		xyd.RedMarkType.ARENA_ALL_SERVER_SCORE_DEFEND
	}, self.alertImg6.gameObject)
	xyd.models.arena3v3:updateRedMark()
	xyd.models.arenaTeam:updateRedMark()
	xyd.models.arenaAllServerNew:updateRedMark()
	xyd.models.arenaAllServerScore:updateBaseInfo()

	local nowTime = xyd.getServerTime()

	self:updateArenaShow()

	if xyd.models.arena3v3:checkFunctionOpen() then
		self.group3v3Time:SetActive(true)

		if xyd.models.arena3v3:checkOpen() then
			self.labelTime3v3.text = __("ARENA_ALL_SERVER_CLOSE_COUNTDOWN")
			self.time3v3Count = CountDown.new(self.time3v3, {
				duration = xyd.models.arena3v3:getDDL() - nowTime
			})
		else
			self.labelTime3v3.text = __("ARENA_ALL_SERVER_NEW_COUNTDOWN")
			self.time3v3Count = CountDown.new(self.time3v3, {
				duration = xyd.models.arena3v3:getStartTime() - nowTime
			})
		end

		local width1 = self.labelTime3v3.width
		local width2 = self.time3v3.width

		self.labelTime3v3:X(-width1 / 2 - width2 / 2)
		self.time3v3:X(width1 / 2 - width2 / 2)
	else
		self.group3v3Time:SetActive(false)
	end

	if xyd.models.arenaTeam:checkFunctionOpen() then
		self.groupTeamTime:SetActive(true)

		if xyd.models.arenaTeam:checkOpen() then
			self.labelTimeTeam.text = __("ARENA_ALL_SERVER_CLOSE_COUNTDOWN")
			self.timeTeamCount = CountDown.new(self.timeTeam, {
				duration = xyd.models.arenaTeam:getDDL() - nowTime
			})
		else
			self.labelTimeTeam.text = __("ARENA_ALL_SERVER_NEW_COUNTDOWN")
			self.timeTeamCount = CountDown.new(self.timeTeam, {
				duration = xyd.models.arenaTeam:getStartTime() - nowTime
			})
		end

		local width1 = self.labelTimeTeam.width
		local width2 = self.timeTeam.width

		self.labelTimeTeam:X(-width1 / 2 - width2 / 2)
		self.timeTeam:X(width1 / 2 - width2 / 2)
	else
		self.groupTeamTime:SetActive(false)
	end

	if xyd.models.arenaAllServerNew:checkFunctionOpen() then
		self.groupAllServerTime:SetActive(true)

		local openTime = xyd.tables.miscTable:getNumber("new_arena_all_server_time", "value")

		if xyd.getServerTime() < openTime then
			self.labelTimeAllServer.text = __("ARENA_ALL_SERVER_NEW_COUNTDOWN")
			self.timeAllServerCount = CountDown.new(self.timeAllServer, {
				duration = openTime - xyd.getServerTime()
			})
		else
			local startTime = xyd.models.arenaAllServerScore:getStartTime()

			if xyd.models.arenaAllServerNew:checkOpen() then
				self.labelTimeAllServer.text = __("ARENA_ALL_SERVER_TEXT_9")
				self.timeAllServer.text = __("ARENA_ALL_SERVER_ROUND_TEXT_" .. tostring(xyd.models.arenaAllServerNew:getCurRound()))
				self.timeAllServer.color = Color.New2(4275079167.0)
			elseif xyd.getServerTime() < startTime and xyd.getServerTime() >= startTime - xyd.DAY_TIME then
				self.labelTimeAllServer.text = __("NEW_ARENA_ALL_SERVER_TEXT_25")
				self.timeAllServerCount = CountDown.new(self.timeAllServer, {
					duration = startTime - xyd.getServerTime()
				})
			elseif startTime <= xyd.getServerTime() and xyd.getServerTime() < startTime + 19 * xyd.DAY_TIME then
				self.labelTimeAllServer.text = __("NEW_ARENA_ALL_SERVER_TEXT_21")
				self.timeAllServerCount = CountDown.new(self.timeAllServer, {
					duration = startTime + 19 * xyd.DAY_TIME - xyd.getServerTime()
				})
			else
				self.labelTimeAllServer.text = __("ARENA_ALL_SERVER_NEW_COUNTDOWN")
				self.timeAllServerCount = CountDown.new(self.timeAllServer, {
					duration = startTime + 27 * xyd.DAY_TIME - xyd.getServerTime()
				})
			end
		end

		local width1 = self.labelTimeAllServer.width
		local width2 = self.timeAllServer.width

		self.labelTimeAllServer:X(-width1 / 2 - width2 / 2)
		self.timeAllServer:X(width1 / 2 - width2 / 2)
	else
		self.groupAllServerTime:SetActive(false)
	end
end

function BattleChooseWindow:registerEvent()
	UIEventListener.Get(self.gArena).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self:checkAndOpen("arena_window", xyd.FunctionID.ARENA)
	end

	UIEventListener.Get(self.gArena3v3).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self:checkAndOpen("arena_3v3_window", xyd.FunctionID.ARENA_3v3)
	end

	UIEventListener.Get(self.gArenaTeam).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self:checkAndOpen("arena_team_window", xyd.FunctionID.ARENA_TEAM)
	end

	UIEventListener.Get(self.gTower).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self:checkAndOpen("tower_window", xyd.FunctionID.TOWER)
	end

	UIEventListener.Get(self.gTrial).onClick = function ()
		if xyd.models.trial:checkClose() then
			xyd.alertTips(__("NEW_TRIAL_RESET_TEXT01"))

			return
		end

		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self:checkAndOpen("trial_enter_window", xyd.FunctionID.TRIAL)
	end

	UIEventListener.Get(self.gDungeon).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self:checkAndOpen("dungeon_window", xyd.FunctionID.DUNGEON)
	end

	UIEventListener.Get(self.gHeroChallenge).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self:checkAndOpen("hero_challenge_window", xyd.FunctionID.HERO_CHALLENGE)
	end

	UIEventListener.Get(self.gAcademyAssessment).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

		if xyd.models.academyAssessment:getIsNewSeason() then
			local startTime = xyd.models.academyAssessment.startTime
			local allTime = xyd.tables.miscTable:getNumber("school_practise_season_duration", "value")
			local showTime = xyd.tables.miscTable:getNumber("school_practise_display_duration", "value")
			local durationTime = startTime + allTime - showTime - xyd.getServerTime()

			if xyd.getServerTime() < startTime + allTime - showTime and startTime <= xyd.getServerTime() then
				self:checkAndOpen("academy_assessment_window", xyd.FunctionID.ACADEMY_ASSESSMENT)
			elseif xyd.getServerTime() < startTime + allTime and xyd.getServerTime() >= startTime + allTime - showTime then
				self:checkAndOpen("academy_assessment_final_rank_window", xyd.FunctionID.ACADEMY_ASSESSMENT)
			else
				xyd.showToast(__("ACADEMY_ASSESSMENT_END_TIPS"))
			end
		else
			self:checkAndOpen("academy_assessment_window", xyd.FunctionID.ACADEMY_ASSESSMENT)
		end
	end

	UIEventListener.Get(self.gArenaAllServer).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self:checkAndOpen("arena_all_server_window", xyd.FunctionID.ARENA_ALL_SERVER)
	end

	UIEventListener.Get(self.gFriendTeamBoss).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self:checkAndOpen("friend_team_boss_window", xyd.FunctionID.FRIEND_TEAM_BOSS)
	end

	UIEventListener.Get(self.timeCloister).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

		if not xyd.checkFunctionOpen(xyd.FunctionID.TIME_CLOISTER) then
			return
		end

		if self.guideName == "time_cloister" then
			self.timeCloister:GetComponent(typeof(UIDragScrollView)).enabled = true
		end

		xyd.models.timeCloisterModel:tryGetTimeCloisterInfo()

		if not xyd.db.misc:getValue("time_cloister_story") then
			local storyId = 5216

			xyd.WindowManager.get():openWindow("story_window", {
				is_back = true,
				story_type = xyd.StoryType.PARTNER,
				story_id = storyId,
				callback = function ()
					xyd.WindowManager.get():openWindow("time_cloister_main_window")
				end
			})
			xyd.db.misc:setValue({
				value = 1,
				key = "time_cloister_story"
			})
		else
			xyd.WindowManager.get():openWindow("time_cloister_main_window")
		end
	end

	UIEventListener.Get(self.shrineHurdle).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

		if not xyd.models.shrineHurdleModel:checkFuctionOpen() then
			local functionOpenTime = xyd.tables.miscTable:getVal("shrine_time_start")

			if xyd.getServerTime() < tonumber(functionOpenTime) then
				xyd.alertTips(__("DRESS_GACHA_OPEN_TIME", xyd.getRoughDisplayTime(tonumber(functionOpenTime) - xyd.getServerTime())))

				return
			end

			local towerStage = xyd.models.towerMap.stage
			local needTowerStage = tonumber(xyd.tables.miscTable:getVal("shrine_open_limit", "value"))

			if towerStage < needTowerStage + 1 then
				xyd.alertTips(__("OLD_SCHOOL_OPEN_FLOOR", needTowerStage))
			else
				xyd.alertTips(__("OLD_SCHOOL_OPEN_STAR"))
			end

			return
		end

		if self.guideName == "shrine_hurdle" then
			self.shrineHurdle:GetComponent(typeof(UIDragScrollView)).enabled = true
		end

		if not xyd.models.shrineHurdleModel:checkPlotRead(1000) then
			xyd.models.shrineHurdleModel:setFlag(1000, nil)
			xyd.WindowManager.get():openWindow("story_window", {
				story_id = 1,
				story_type = xyd.StoryType.SHRINE_HURDLE,
				callback = function ()
					self:checkAndOpen("shrine_hurdle_entrance_window", xyd.FunctionID.SHRINE_HURDLE)
				end
			})
		else
			self:checkAndOpen("shrine_hurdle_entrance_window", xyd.FunctionID.SHRINE_HURDLE)
		end
	end

	self.scrollerPVE.onDragMoving = handler(self, self.onDragMoving)

	self.eventProxy_:addEventListener(xyd.event.TIME_CLOISTER_INFO, handler(self, self.setTimeCloisterInfo))
	self.eventProxy_:addEventListener(xyd.event.STOP_HANG, handler(self, self.setTimeCloisterInfo))
	self.eventProxy_:addEventListener(xyd.event.START_HANG, handler(self, self.setTimeCloisterInfo))
	self.eventProxy_:addEventListener(xyd.event.GET_HANG, handler(self, self.setTimeCloisterInfo))
	self.eventProxy_:addEventListener(xyd.event.SPEED_UP_HANG, handler(self, self.setTimeCloisterInfo))
	self.eventProxy_:addEventListener(xyd.event.GET_ARENA_ALL_SERVER_INFO, handler(self, self.updateArenaLabel))
	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_GET_SELF_INFO_NEW, handler(self, self.updateArenaLabel))
	self.eventProxy_:addEventListener(xyd.event.SHRINE_HURDLE_GET_INFO, handler(self, self.onGetShrineInfo))
	self.eventProxy_:addEventListener(xyd.event.GET_TRIAL_INFO, handler(self, self.onGetTrialInfo))
end

function BattleChooseWindow:onGetTrialInfo()
	local nowTime = xyd.getServerTime()

	if xyd.models.trial:checkFunctionOpen() then
		self.groupTrialTime:SetActive(true)

		if xyd.models.trial:checkClose() then
			local opentime = xyd.tables.miscTable:getVal("new_trial_restart_open_time")

			self.tmeTrial.gameObject:SetActive(false)

			self.timeTrial = CountDown.new(self.labelTimeTrial, {
				key = "NEW_TRIAL_RESET_TEXT02",
				duration = tonumber(opentime) - nowTime
			})

			self.labelTimeTrial:X(0)
			self.tmeTrial:X(0)
		else
			self.tmeTrial.gameObject:SetActive(true)

			local data = xyd.models.trial:getData()
			local boss_id = data.boss_id

			if data.is_open and data.is_open ~= 0 then
				self.labelTimeTrial.text = __("TRIAL_CLOSE_COUNTDOWN")
				self.timeTrial = CountDown.new(self.tmeTrial, {
					duration = data.end_time - nowTime
				})
			elseif data.start_time then
				self.labelTimeTrial.text = __("TRIAL_NEW_COUNTDOWN")
				self.timeTrial = CountDown.new(self.tmeTrial, {
					duration = data.end_time + 3600 - nowTime
				})
			end

			self.trialTimeGroup:Reposition()
		end
	else
		self.groupTrialTime:SetActive(false)
	end
end

function BattleChooseWindow:onGetShrineInfo()
	if xyd.checkFunctionOpen(xyd.FunctionID.SHRINE_HURDLE, true) then
		self:setShrineInfo()
		xyd.models.shrine:getAchieveData()
		xyd.models.shrine:getMissionData()
		self.shrineMaskImg:SetActive(false)
	else
		self.shrineMaskImg:SetActive(true)
	end
end

function BattleChooseWindow:updateArenaLabel()
	if xyd.models.arenaAllServerNew:checkFunctionOpen() then
		self.groupAllServerTime:SetActive(true)

		local openTime = xyd.tables.miscTable:getNumber("new_arena_all_server_time", "value")

		if xyd.getServerTime() < openTime then
			self.labelTimeAllServer.text = __("ARENA_ALL_SERVER_NEW_COUNTDOWN")

			self.timeAllServerCount:setInfo({
				duration = openTime - xyd.getServerTime()
			})
		else
			local startTime = xyd.models.arenaAllServerScore:getStartTime()

			if xyd.models.arenaAllServerNew:checkOpen() then
				self.labelTimeAllServer.text = __("ARENA_ALL_SERVER_TEXT_9")
				self.timeAllServer.text = __("ARENA_ALL_SERVER_ROUND_TEXT_" .. tostring(xyd.models.arenaAllServerNew:getCurRound()))
				self.timeAllServer.color = Color.New2(4275079167.0)
			elseif xyd.getServerTime() < startTime and xyd.getServerTime() >= startTime - xyd.DAY_TIME then
				self.labelTimeAllServer.text = __("NEW_ARENA_ALL_SERVER_TEXT_25")

				self.timeAllServerCount:setInfo({
					duration = startTime - xyd.getServerTime()
				})
			elseif startTime <= xyd.getServerTime() and xyd.getServerTime() < startTime + 19 * xyd.DAY_TIME then
				self.labelTimeAllServer.text = __("NEW_ARENA_ALL_SERVER_TEXT_21")

				self.timeAllServerCount:setInfo({
					duration = startTime + 19 * xyd.DAY_TIME - xyd.getServerTime()
				})
			else
				self.labelTimeAllServer.text = __("ARENA_ALL_SERVER_NEW_COUNTDOWN")

				self.timeAllServerCount:setInfo({
					duration = startTime + 27 * xyd.DAY_TIME - xyd.getServerTime()
				})
			end
		end

		local width1 = self.labelTimeAllServer.width
		local width2 = self.timeAllServer.width

		self.labelTimeAllServerLayout:Reposition()
	else
		self.groupAllServerTime:SetActive(false)
	end
end

function BattleChooseWindow:changeTopTap(index)
	self.curShowIndex = index

	xyd.SoundManager.get():playSound(xyd.SoundID.TAB_LIST_TO_BOTTOM)
	__TRACE(index)

	if index == 1 then
		self.dragPVE:SetActive(true)
		self.scrollerPVE:SetActive(true)
		self.hideTips:SetActive(true)
		self.groupPVP:SetActive(false)
	elseif index == 2 then
		self.dragPVE:SetActive(false)
		self.scrollerPVE:SetActive(false)
		self.hideTips:SetActive(false)
		self.groupPVP:SetActive(true)
	end

	if index == 2 then
		xyd.models.arenaAllServerNew:reqSelfInfo()
	end
end

function BattleChooseWindow:updateOpenBlock(g, funID)
	if funID then
		local openLev = xyd.tables.functionTable:getOpenValue(funID) or 0
	end
end

function BattleChooseWindow:checkAndOpen(winName, funID)
	if funID then
		if not xyd.checkFunctionOpen(funID) then
			return
		end

		if funID == xyd.FunctionID.ARENA_ALL_SERVER then
			local openTime = xyd.tables.miscTable:getNumber("new_arena_all_server_time", "value")

			if xyd.getServerTime() < openTime then
				xyd.alert(xyd.AlertType.TIPS, tostring(__("ARENA_ALL_SERVER_OPEN")) .. xyd.getRoughDisplayTime(openTime - xyd.getServerTime()))

				return
			end

			if xyd.models.arenaAllServerScore:checkNoInfo() then
				return
			end
		end

		if funID == xyd.FunctionID.ARENA and xyd.models.arena:getIsSettlementing() then
			xyd.alert(xyd.AlertType.TIPS, __("ARENA_SETTLEMENT_TIPS"))

			return
		end
	end

	if self.guideName ~= "" and funcNameToDrag[self.guideName] then
		local componentName = funcNameToDrag[self.guideName]

		if componentName then
			self[componentName]:GetComponent(typeof(UIDragScrollView)).enabled = false
		end
	end

	xyd.WindowManager.get():openWindow(winName)
end

function BattleChooseWindow:playMainAction()
	local items = self.orderPVE

	for i = 1, #items do
		local item = items[i]
		local w = item:GetComponent(typeof(UIWidget))

		if w == nil then
			print(i)
		end

		w.alpha = 0.01
	end

	local action = self:getSequence()

	for i = 1, #items do
		action:InsertCallback(0.06 * (i - 1), function ()
			self:itemAnimation(items[i])
		end)
	end

	action:AppendCallback(function ()
		action:Kill(false)

		action = nil
	end)
end

function BattleChooseWindow:playPvpAction()
	local items = {
		self.gArena,
		self.gArenaTeam,
		self.gArena3v3,
		self.gArenaAllServer
	}

	for i = 1, #items do
		local item = items[i]
		local w = item:GetComponent(typeof(UIWidget))
		w.alpha = 0.01
	end

	local action = self:getSequence()

	for i = 1, #items do
		action:InsertCallback(0.06 * (i - 1), function ()
			self:itemAnimation(items[i])
		end)
	end

	action:AppendCallback(function ()
		action:Kill(false)

		action = nil
	end)
end

function BattleChooseWindow:itemAnimation(item)
	local action = self:getSequence()
	local widget = item:GetComponent(typeof(UIWidget))
	local originY = item.transform.localPosition.y

	action:Insert(0, item.transform:DOLocalMoveY(originY + 30, 0))
	action:Insert(0, item.transform:DOLocalMoveY(originY, 0.2))

	local getter, setter = xyd.getTweenAlphaGeterSeter(widget)

	action:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.2))
	action:AppendCallback(function ()
		action:Kill(false)

		action = nil
	end)
end

function BattleChooseWindow:applyDark(g)
end

function BattleChooseWindow:applyOrigin(g)
end

function BattleChooseWindow:willClose(params)
	BaseWindow.willClose(self, params)

	if self.timeTrial then
		self.timeTrial:stopTimeCount()
	end

	if self.timeDungonCount then
		self.timeDungonCount:stopTimeCount()
	end

	if self.time3v3Count then
		self.time3v3Count:stopTimeCount()
	end

	if self.timeTeamCount then
		self.timeTeamCount:stopTimeCount()
	end

	if self.countAllSeverTime then
		self.countAllSeverTime:stopTimeCount()
	end

	if self.timeTowerCount then
		self.timeTowerCount:stopTimeCount()
	end
end

function BattleChooseWindow:updateHeroChallenge()
	if xyd.models.activity:isOpen(xyd.ActivityID.HERO_CHALLENGE_SPEED) then
		self.labelHChallengeTips_.text = __("HERO_CHALLENGE_TIPS6")

		self.groupHTime_:SetActive(true)
	else
		self.groupHTime_:SetActive(false)
	end
end

function BattleChooseWindow:iosTestChangeUI()
	local winTrans = self.window_.transform

	xyd.setUITexture(winTrans:ComponentByName("imgBg/bg_", typeof(UITexture)), "Textures/texture_ios/bg_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("main/groupPVE/gTower/e:Image", typeof(UISprite)), "btn_tower_battle_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("main/groupPVE/gTrial/e:Image", typeof(UISprite)), "btn_trial_battle_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("main/groupPVE/gDungeon/e:Image", typeof(UISprite)), "btn_dungeon_battle_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("main/groupPVE/gHeroChallenge/e:Image", typeof(UISprite)), "btn_h_challenge_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("main/groupPVE/gFriendTeamBoss/e:Image", typeof(UISprite)), "btn_friend_team_boss_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("main/groupPVE/gAcademyAssessment/e:Image", typeof(UISprite)), "btn_school_practice_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("main/groupPVP/gArena/e:Image", typeof(UISprite)), "btn_arena_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("main/groupPVP/gArena3v3/e:Image", typeof(UISprite)), "btn_arena_3v3_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("main/groupPVP/gArenaTeam/e:Image", typeof(UISprite)), "btn_arena_team_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("main/groupPVP/gArenaAllServer/e:Image", typeof(UISprite)), "btn_arena_all_server_ios_test")
	xyd.setUISprite(winTrans:ComponentByName("main/nav/tab_1", typeof(UISprite)), nil, "nav_btn_white_left_ios_test")
	xyd.setUISprite(winTrans:ComponentByName("main/nav/tab_2", typeof(UISprite)), nil, "nav_btn_white_right_ios_test")
	xyd.setUISprite(winTrans:ComponentByName("main/nav/tab_1/selected", typeof(UISprite)), nil, "nav_btn_blue_left_ios_test")
	xyd.setUISprite(winTrans:ComponentByName("main/nav/tab_2/selected", typeof(UISprite)), nil, "nav_btn_blue_right_ios_test")
end

function BattleChooseWindow:updateArenaShow()
	local isHasTime = false
	local params = nil

	self.groupArenaTime:SetActive(false)
	self:updateArenaLabel(false)

	if xyd.checkFunctionOpen(xyd.FunctionID.ARENA, true) then
		local arenaIsLast = xyd.models.arena:getIsLast()

		if xyd.models.arena:getIsOld() == nil and arenaIsLast ~= nil and arenaIsLast == 1 then
			self.groupArenaTime:SetActive(true)
			self:updateArenaLabel(true)

			local arenaEndTime = xyd.models.arena:getDDL() - xyd.getServerTime()

			if arenaEndTime > 0 then
				self.arenaLabelTime.text = __("ARENA_NEW_SEASON_SERVER_TIME_TEXT")
				params = {
					duration = arenaEndTime,
					callback = function ()
						self.arenaTime.text = "00:00:00"

						self:waitForTime(1, function ()
							local arenaWd = xyd.WindowManager.get():getWindow("arena_window")

							if arenaWd then
								xyd.WindowManager.get():closeWindow("arena_window")
							end

							xyd.models.arena:reqArenaInfo()
							xyd.models.arena:reqRankList()
							self.groupArenaTime:SetActive(false)
							self:updateArenaLabel(false)
							xyd.setUISpriteAsync(self.arenaImage, nil, "btn_arena_new")
							self.arenaBtnBate.gameObject:SetActive(true)
						end)
					end
				}
				isHasTime = true
			else
				self.groupArenaTime:SetActive(false)
				self:updateArenaLabel(false)
			end
		elseif xyd.models.arena:getIsOld() ~= nil then
			self.groupArenaTime:SetActive(false)
			self:updateArenaLabel(false)

			local newArenaStartTimeLeft = xyd.models.arena:getStartTime() + xyd.models.arena:getNewSeasonOpenTime() - xyd.getServerTime()

			if newArenaStartTimeLeft > 0 and newArenaStartTimeLeft < xyd.models.arena:getNewSeasonOpenTime() then
				self.groupArenaTime:SetActive(true)
				self:updateArenaLabel(true)

				self.arenaLabelTime.text = __("ARENA_OPEN_TIPS_TEXT")
				params = {
					duration = newArenaStartTimeLeft,
					callback = function ()
						self.arenaTime.text = "00:00:00"

						self:waitForTime(1, function ()
							self:updateArenaShow()
						end)
					end
				}
				isHasTime = true
			elseif xyd.getServerTime() < xyd.models.arena:getDDL() then
				self.groupArenaTime:SetActive(true)
				self:updateArenaLabel(true)

				self.arenaLabelTime.text = __("ARENA_END_TIPS_TEXT")
				params = {
					duration = xyd.models.arena:getDDL() - xyd.getServerTime(),
					callback = function ()
						self.arenaTime.text = "00:00:00"

						self:waitForTime(1, function ()
							self:updateArenaShow()
						end)
					end
				}
				isHasTime = true
			end
		else
			self.groupArenaTime:SetActive(false)
			self:updateArenaLabel(false)
		end
	else
		self.groupArenaTime:SetActive(false)
		self:updateArenaLabel(false)
	end

	if isHasTime and params ~= nil then
		if not self.timeArenaCount then
			self.timeArenaCount = CountDown.new(self.arenaTime, params)
		else
			self.timeArenaCount:setInfo(params)
		end

		local width1 = self.arenaLabelTime.width
		local width2 = self.arenaTime.width

		self.arenaLabelTime:X(-width1 / 2 - width2 / 2)
		self.arenaTime:X(width1 / 2 - width2 / 2)
	end

	if xyd.models.arena:getIsOld() ~= nil then
		xyd.setUISpriteAsync(self.arenaImage, nil, "btn_arena_new")
		self.arenaBtnBate.gameObject:SetActive(true)
	else
		xyd.setUISpriteAsync(self.arenaImage, nil, "btn_arena")
		self.arenaBtnBate.gameObject:SetActive(false)
	end
end

function BattleChooseWindow:updateArenaLabel(state)
	if state then
		if xyd.Global.lang == "en_en" then
			self.arenaLabel:Y(103)
			self.arenaLabel2:Y(14)
		elseif xyd.Global.lang == "fr_fr" then
			self.arenaLabel2:Y(22)
		elseif xyd.Global.lang == "de_de" then
			self.arenaLabel2:Y(37)
		else
			self.arenaLabel:Y(84)
			self.arenaLabel2:Y(-5)
		end
	else
		self.arenaLabel:Y(84)

		if xyd.Global.lang == "de_de" then
			self.arenaLabel2:Y(20)
		else
			self.arenaLabel2:Y(-5)
		end
	end
end

return BattleChooseWindow
