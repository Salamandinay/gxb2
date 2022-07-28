local BaseWindow = import(".BaseWindow")
local OldSchoolMainWindow = class("OldSchoolMainWindow", BaseWindow)
local CampusItem = class("CampusItem", import("app.components.CopyComponent"))
local SecondSmallItem = class("SecondSmallItem", import("app.components.CopyComponent"))
local SecondBigItem = class("SecondBigItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")
local WindowTop = import("app.components.WindowTop")
local PlayerIcon = import("app.components.PlayerIcon")
local self_oldBuildingFloorTable = nil

function OldSchoolMainWindow:ctor(name, params)
	self.itemArr = {}
	self.lastClickAreaNum = -1
	self.id = xyd.ActivityID.EXPLORE_OLD_CAMPUS_PVE

	self:getCheckTable()
	OldSchoolMainWindow.super.ctor(self, name, params)
end

function OldSchoolMainWindow:getCheckTable()
	if xyd.models.oldSchool:seasonType() == 1 then
		self.oldBuildingFloorTable = xyd.tables.oldBuildingATable
	else
		self.oldBuildingFloorTable = xyd.tables.oldBuildingBTable
	end

	self_oldBuildingFloorTable = self.oldBuildingFloorTable
end

function OldSchoolMainWindow:initWindow()
	self:getUIComponent()
	OldSchoolMainWindow.super.initWindow(self)
	self:initUIComponent()
	self:initTopGroup()
	self:updateInfo()
	self:initTime()
	xyd.models.oldSchool:reqRankList()

	local redPointState = xyd.db.misc:getValue("old_school_red_point" .. xyd.models.oldSchool:getAllInfo().season_info.count)

	if redPointState == nil then
		xyd.db.misc:setValue({
			key = "old_school_red_point" .. xyd.models.oldSchool:getAllInfo().season_info.count,
			value = xyd.models.oldSchool:getAllInfo().season_info.count
		})
		xyd.models.oldSchool:updateRedMark()
	end

	self:updateScoreGetAwardRedPoint()
end

function OldSchoolMainWindow:updateScoreGetAwardRedPoint()
	if xyd.models.oldSchool:isCheckScoreCanGetAward() == true then
		self.awardBtn_redPoint:SetActive(true)
	else
		self.awardBtn_redPoint:SetActive(false)
	end

	xyd.models.oldSchool:updateRedMark()
end

function OldSchoolMainWindow:getUIComponent()
	self.trans = self.window_.transform:NodeByName("groupAction").gameObject
	self.topGroup = self.trans:NodeByName("topGroup").gameObject
	self.groupBg = self.trans:NodeByName("groupBg").gameObject
	self.bg = self.groupBg:ComponentByName("bg", typeof(UITexture))
	self.titleImg = self.groupBg:ComponentByName("titleImg", typeof(UISprite))
	self.scoreLabelBg = self.groupBg:ComponentByName("scoreLabelBg", typeof(UISprite))
	self.scoreLabelText = self.scoreLabelBg:ComponentByName("scoreLabelText", typeof(UILabel))
	self.scoreLabel = self.scoreLabelBg:ComponentByName("scoreLabel", typeof(UILabel))
	self.tipsTextCon = self.groupBg:NodeByName("tipsTextCon").gameObject
	self.tipsTextCon_layout = self.groupBg:ComponentByName("tipsTextCon", typeof(UILayout))
	self.tipsText = self.tipsTextCon:ComponentByName("tipsText", typeof(UILabel))
	self.tipsNumText = self.tipsTextCon:ComponentByName("tipsNumText", typeof(UILabel))
	self.group1 = self.groupBg:NodeByName("group1").gameObject
	self.helpBtn = self.group1:NodeByName("helpBtn").gameObject
	self.shopBtn_ = self.group1:NodeByName("shopBtn_").gameObject
	self.rankBtn = self.group1:NodeByName("rankBtn").gameObject
	self.awardBtn = self.group1:NodeByName("awardBtn").gameObject
	self.awardBtn_redPoint = self.awardBtn:NodeByName("redPoint").gameObject
	self.groupMain = self.trans:NodeByName("groupMain").gameObject
	self.secondGroup = self.groupMain:NodeByName("secondGroup").gameObject
	self.secondGroup_uiwidget = self.groupMain:ComponentByName("secondGroup", typeof(UIWidget))
	self.secibdBgImg = self.secondGroup:ComponentByName("secibdBgImg", typeof(UITexture))
	self.secondScroller = self.secondGroup:ComponentByName("secondScroller", typeof(UIScrollView))
	self.secondScrollerCon = self.secondScroller:ComponentByName("secondScrollerCon", typeof(UIWrapContent))
	local wrapContent = self.secondScroller:ComponentByName("secondScrollerCon", typeof(UIWrapContent))
	self.drag = self.secondGroup:NodeByName("drag").gameObject
	self.backBtn = self.secondGroup:NodeByName("backBtn").gameObject
	self.caseBtn = self.secondGroup:NodeByName("caseBtn").gameObject
	self.caseBtnLabel = self.caseBtn:ComponentByName("caseBtnLabel", typeof(UILabel))
	self.second_big_item = self.groupMain:NodeByName("second_big_item").gameObject
	self.wrapContent = FixedMultiWrapContent.new(self.secondScroller, wrapContent, self.second_big_item, SecondBigItem, self)
	self.caseBtnLabel.text = __("ACTIVITY_EXPLORE_CAMPUS_3")
end

function OldSchoolMainWindow:initTime()
	self.tipsText.text = __("OLD_SCHOOL_TIME_TEXT1")
	local durationTime = xyd.models.oldSchool:getChallengeEndTime() - xyd.getServerTime()

	if durationTime > 0 then
		self.setCountDownTime = CountDown.new(self.tipsNumText, {
			duration = durationTime,
			callback = handler(self, self.timeOver)
		})
		self.refreshRankTime = Timer.New(function ()
			xyd.models.oldSchool:reqRankList()
		end, 30, -1)

		self.refreshRankTime:Start()
	else
		self:timeOver()
	end

	self.tipsTextCon_layout:Reposition()
end

function OldSchoolMainWindow:timeOver()
	self.tipsNumText.text = "00:00:00"

	xyd.WindowManager.get():closeWindow(self.name_)
	xyd.models.oldSchool:openOldSchoolMainWindow()
end

function OldSchoolMainWindow:initUIComponent()
	xyd.setUISpriteAsync(self.titleImg, nil, "old_school_title_" .. xyd.Global.lang, nil, )

	self.scoreLabelText.text = __("TOTAL_GRADE")
	self.scoreLabel.text = xyd.models.oldSchool:getSelfScore()
	self.data = self.oldBuildingFloorTable:getIDs()

	UIEventListener.Get(self.helpBtn.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "OLD_SCHOOL_HELP1"
		})
	end

	UIEventListener.Get(self.rankBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("old_school_rank_window")
	end)

	UIEventListener.Get(self.awardBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_explore_campus_PVE_point_window", {})
	end

	UIEventListener.Get(self.caseBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_explore_old_campus_ways_window", {
			area_id = self.area_id
		})
	end)

	UIEventListener.Get(self.shopBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("old_school_shop_window", {})
	end

	dump(xyd.models.oldSchool:getAllInfo().floor_infos, "xyd.models.oldSchool:getAllInfo()")

	if xyd.models.oldSchool:getAllInfo() then
		local eventData = xyd.models.oldSchool:getAllInfo()
		local floorArr = self.oldBuildingFloorTable:getIDs()
		local backFloorArr = {}

		for i = #floorArr, 1, -1 do
			table.insert(backFloorArr, floorArr[i])
		end

		local detailArr = {}

		for i in pairs(backFloorArr) do
			table.insert(detailArr, {
				floorId = backFloorArr[i],
				dataInfo = eventData.floor_infos[#backFloorArr - i + 1]
			})
		end

		self:enterSecond(detailArr)

		self.area_id = tonumber(1)
	end

	self.eventProxy_:addEventListener(xyd.event.OLD_BUILDING_SET_TEAMS, function (event)
		local data = xyd.decodeProtoBuf(event.data)
		local infoItems = self.wrapContent:getItems()

		for i in pairs(infoItems) do
			if infoItems[i].data and tonumber(infoItems[i].data.floorId) == data.floor_id and tonumber(infoItems[i].data.floorId) == xyd.models.oldSchool:getDefUpdataInfo().floor_id then
				infoItems[i].data.dataInfo.teams = xyd.models.oldSchool:getDefUpdataInfo().teams
				local fightWin = xyd.WindowManager.get():getWindow("activity_explore_campus_fight_window")

				if fightWin and xyd.tables.oldBuildingStageTable:getFloor(fightWin:getLevelId()) == tonumber(infoItems[i].data.floorId) then
					fightWin:updateHeroIcons(xyd.models.oldSchool:updateFormation(infoItems[i].data.dataInfo.teams))
				end

				for j in pairs(infoItems[i].data.dataInfo.cur_scores) do
					infoItems[i].data.dataInfo.cur_scores[j] = 0
				end

				infoItems[i]:update(nil, infoItems[i].data)
				self:updateActivityDataAreaInfo(data.floor_id, infoItems[i].data.dataInfo)
			end
		end

		if self.notShowTip then
			self.notShowTip = nil

			return
		end

		xyd.alertTips(__("ACTIVITY_EXPLORE_CAMPUS_SCORE_SET_TEAM_SUCCESS"))
	end)
	self.eventProxy_:addEventListener(xyd.event.OLD_BUILDING_ACTIVITY_UNLOCK_BUFF, function (event)
		local data = xyd.decodeProtoBuf(event.data)
		local buyWin = xyd.WindowManager.get():getWindow("activity_explore_old_campus_way_buy_window")

		if buyWin then
			xyd.WindowManager.get():closeWindow("activity_explore_old_campus_way_buy_window")
		end

		xyd.models.oldSchool:updateUnlockBuffInfo(data)
		xyd.alertTips(__("ACTIVITY_EXPLORE_CAMPUS_PURCHASE_SUCCESS"))
	end)
	self.eventProxy_:addEventListener(xyd.event.OLD_BUILDING_HARM_LIST, handler(self, self.updateScore))
	self.eventProxy_:addEventListener(xyd.event.OLD_BUILDING_RANK_LIST, handler(self, self.updateScore))
	self.eventProxy_:addEventListener(xyd.event.OLD_BUILDING_FIGHT, handler(self, self.onOldBuildingFight))
end

function OldSchoolMainWindow:updateScore()
	self.scoreLabel.text = xyd.models.oldSchool:getSelfScore()
end

function OldSchoolMainWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function OldSchoolMainWindow:onOldBuildingFight(event)
	local data = event.data

	if not data.floor_info then
		return
	end

	if not data.battle_result then
		return
	end

	data = xyd.decodeProtoBuf(event.data)
	local backFloorId = xyd.tables.oldBuildingStageTable:getFloor(tonumber(data.stage_id))
	local infoItems = self.wrapContent:getItems()

	for i in pairs(infoItems) do
		if infoItems[i].data and tonumber(infoItems[i].data.floorId) == backFloorId then
			infoItems[i].data.dataInfo.complete_num = data.floor_info.complete_num
			infoItems[i].data.dataInfo.completeds = data.floor_info.completeds
			infoItems[i].data.dataInfo.cur_scores = data.floor_info.cur_scores
			infoItems[i].data.dataInfo.score = data.floor_info.score

			infoItems[i]:update(nil, infoItems[i].data)

			for k in pairs(data.floor_info.cur_scores) do
				if tonumber(xyd.models.oldSchool:getAllInfo().max_score) < tonumber(data.floor_info.cur_scores[k]) then
					xyd.models.oldSchool:getAllInfo().max_score = data.floor_info.cur_scores[k]
				end
			end

			self:updateActivityDataAreaInfo(backFloorId, infoItems[i].data.dataInfo)

			if data.floor_info.complete_num > 0 then
				self:checkFloorLock(backFloorId)
			end

			self:updateAreaScoreAndAllScore(backFloorId, data.floor_info.score)
		end
	end

	if backFloorId == 11 then
		xyd.models.oldSchool:reqRankList(true)
	end
end

function OldSchoolMainWindow:updateActivityDataAreaInfo(backFloorId, data)
	local floorIndex = 0
	local floorsArr = self.oldBuildingFloorTable:getIDs()

	for k in pairs(floorsArr) do
		if tonumber(floorsArr[k]) == backFloorId then
			floorIndex = k

			break
		end
	end

	xyd.models.oldSchool:getAllInfo().floor_infos[floorIndex] = data
end

function OldSchoolMainWindow:updateAreaScoreAndAllScore(backFloorId, score)
	local allInfo = xyd.models.oldSchool:getAllInfo()
	local all_score = 0

	for i in pairs(allInfo.floor_infos) do
		if i ~= 11 then
			all_score = all_score + allInfo.floor_infos[i].score
		end
	end

	xyd.models.oldSchool:getAllInfo().score = all_score
	self.scoreLabel.text = xyd.models.oldSchool:getSelfScore()

	xyd.models.oldSchool:setScore(all_score)
	self:updateScoreGetAwardRedPoint()
end

function OldSchoolMainWindow:checkFloorLock(backFloorId)
	local floorIndex = 0
	local floorsArr = self.oldBuildingFloorTable:getIDs()

	for k in pairs(floorsArr) do
		if tonumber(floorsArr[k]) == backFloorId then
			floorIndex = k

			break
		end
	end

	if xyd.models.oldSchool:getAllInfo().max_index < floorIndex then
		xyd.models.oldSchool:getAllInfo().max_index = floorIndex
	end

	if floorIndex < #floorsArr then
		local nextFloorId = floorsArr[floorIndex + 1]
		local infoItems = self.wrapContent:getItems()

		for i in pairs(infoItems) do
			if infoItems[i].data and tonumber(infoItems[i].data.floorId) == nextFloorId then
				infoItems[i]:update(nil, infoItems[i].data)
			end
		end
	end
end

function OldSchoolMainWindow:enterSecond(floorArr)
	local backArr = {}

	for i = #floorArr, 1, -1 do
		table.insert(backArr, floorArr[i])
	end

	local goToIndex = 0

	for i in pairs(backArr) do
		if i < #backArr and backArr[i].dataInfo.complete_num > 0 and backArr[i + 1].dataInfo.complete_num == 0 then
			goToIndex = i + 1

			break
		end

		if i == #backArr and backArr[i].dataInfo.complete_num > 0 then
			goToIndex = i

			break
		end
	end

	goToIndex = #floorArr - goToIndex + 1

	if goToIndex == 0 or goToIndex > #floorArr then
		goToIndex = #floorArr
	end

	self.wrapContent:setInfos(floorArr, {})
	self.wrapContent:jumpToInfo(floorArr[goToIndex])
end

function OldSchoolMainWindow:updateInfo()
end

function OldSchoolMainWindow:floorGetAwardBack(floor_id)
	local infoItems = self.wrapContent:getItems()

	for i in pairs(infoItems) do
		if infoItems[i].data and tonumber(infoItems[i].data.floorId) == floor_id then
			infoItems[i].data.dataInfo.awards = xyd.models.oldSchool:getAllInfo().floor_infos[floor_id].awards

			infoItems[i]:setAwardImg()
		end
	end
end

function SecondBigItem:ctor(go, parent)
	self.itemArr = {}

	SecondBigItem.super.ctor(self, go, parent)

	self.parent = parent
end

function SecondBigItem:initUI()
	self.imgBg_ = self.go:ComponentByName("imgBg_", typeof(UITexture))
	self.setPartnerBtn = self.go:NodeByName("setPartnerBtn").gameObject
	self.redPoint = self.setPartnerBtn:ComponentByName("redPoint", typeof(UISprite))
	self.setPartnerBtnLabel = self.setPartnerBtn:ComponentByName("setPartnerBtnLabel", typeof(UILabel))
	self.name = self.go:ComponentByName("name", typeof(UILabel))
	self.nameBg_ = self.go:ComponentByName("nameBg", typeof(UISprite))
	self.labelDesc_ = self.go:ComponentByName("labelDesc_", typeof(UILabel))
	self.labelDescBg_ = self.go:ComponentByName("labelDescBg_", typeof(UISprite))
	self.showCon = self.go:ComponentByName("showCon", typeof(UILayout))
	self.maskBg_ = self.go:ComponentByName("maskBg_", typeof(UISprite))
	self.locakImg_ = self.go:ComponentByName("locakImg_", typeof(UITexture))
	self.second_small_item = self.go:NodeByName("second_small_item").gameObject
	self.awardBtn = self.go:NodeByName("awardBtn").gameObject
	self.awardBtn_uisprite = self.go:ComponentByName("awardBtn", typeof(UISprite))
	self.awardBtnRedPoint = self.go:NodeByName("awardBtnRedPoint").gameObject
	self.setPartnerBtnLabel.text = __("SET_DEF_FORMATION")
	UIEventListener.Get(self.setPartnerBtn.gameObject).onClick = handler(self, function ()
		if self.dataInfo then
			local floorArr = self_oldBuildingFloorTable:getIDs()
			local indexFloor = xyd.arrayIndexOf(floorArr, self.data.floorId)

			if not self.data.dataInfo.teams or self.data.dataInfo.teams and #self.data.dataInfo.teams == 0 and indexFloor > 1 then
				xyd.alertYesNo(__("ACTIVITY_EXPLORE_CAMPUS_TEAM_SAVE"), function (yes)
					if yes then
						if indexFloor > 1 then
							local infos = self.parent.wrapContent:getInfos()

							for i in pairs(infos) do
								if infos[i].dataInfo and tonumber(infos[i].floorId) == tonumber(self.data.floorId) - 1 then
									xyd.WindowManager.get():openWindow("arena_3v3_battle_formation_window", {
										isCurFloorZero = true,
										isForceSave = true,
										battleType = xyd.BattleType.EXPLORE_OLD_CAMPUS,
										formation = xyd.models.oldSchool:updateFormation(infos[i].dataInfo.teams),
										floor_id = tonumber(self.data.floorId),
										levelNum = #self_oldBuildingFloorTable:getStage(tonumber(self.data.floorId))
									})
								end
							end
						end
					else
						self:open3V3Win()
					end
				end)
			elseif indexFloor == 1 and xyd.db.misc:getValue("old_building_first_teams" .. xyd.models.oldSchool:getAllInfo().season_info.count - 1) and (not self.data.dataInfo.teams or self.data.dataInfo.teams and #self.data.dataInfo.teams == 0) then
				local detail = xyd.db.misc:getValue("old_building_first_teams" .. xyd.models.oldSchool:getAllInfo().season_info.count - 1)

				if detail then
					xyd.alertYesNo(__("OLD_SCHOOL_USE_LAST_TERM_TEAM"), function (yes)
						if yes then
							local cjson = require("cjson")

							xyd.WindowManager.get():openWindow("arena_3v3_battle_formation_window", {
								isCurFloorZero = true,
								isForceSave = true,
								battleType = xyd.BattleType.EXPLORE_OLD_CAMPUS,
								formation = xyd.models.oldSchool:updateFormation(cjson.decode(detail).teams),
								floor_id = tonumber(self.data.floorId),
								levelNum = #self_oldBuildingFloorTable:getStage(tonumber(self.data.floorId))
							})
						else
							self:open3V3Win()
						end
					end)
				else
					self:open3V3Win()
				end
			else
				self:open3V3Win()
			end
		end
	end)
	UIEventListener.Get(self.awardBtn.gameObject).onClick = handler(self, function ()
		if self.data.floorId >= 11 and xyd.models.oldSchool:checkUnlock11Floor() > 0 then
			xyd.WindowManager.get():openWindow("old_school_harm_rank_window", {})
		elseif self.data.floorId >= 11 and xyd.models.oldSchool:checkUnlock11Floor() < 0 then
			local point = xyd.tables.miscTable:getVal("old_building_floor11_point")

			xyd.alertTips(__("OLD_SCHOOL_FLOOR_11_TIPS", point))
		else
			xyd.WindowManager.get():openWindow("activity_explore_old_campus_floor_award_window", {
				floor_id = self.data.floorId,
				completeds = self.data.dataInfo.completeds,
				complete_num = self.data.dataInfo.complete_num
			})
		end
	end)
	UIEventListener.Get(self.maskBg_.gameObject).onClick = handler(self, function ()
		if self.data.floorId >= 11 then
			local flag = xyd.models.oldSchool:checkUnlock11Floor()

			if flag <= -1 then
				local point = xyd.tables.miscTable:getVal("old_building_floor11_point")

				xyd.alertTips(__("OLD_SCHOOL_FLOOR_11_TIPS", point))
			end
		else
			xyd.alertTips(__("ACTIVITY_EXPLORE_CAMPUS_FLOOR_LOCK_TIPS"))
		end
	end)
end

function SecondBigItem:open3V3Win()
	local isCurFloorZero = true

	for i in pairs(self.data.dataInfo.cur_scores) do
		if tonumber(self.data.dataInfo.cur_scores[i]) > 0 then
			isCurFloorZero = false
		end
	end

	xyd.WindowManager.get():openWindow("arena_3v3_battle_formation_window", {
		battleType = xyd.BattleType.EXPLORE_OLD_CAMPUS,
		formation = xyd.models.oldSchool:updateFormation(self.data.dataInfo.teams),
		floor_id = self.data.floorId,
		levelNum = #self_oldBuildingFloorTable:getStage(self.data.floorId),
		isCurFloorZero = isCurFloorZero
	})
end

function SecondBigItem:update(wrapIndex, info)
	if not info then
		self.go:SetActive(false)

		if self.data then
			self.data.floorId = -1
		end

		if self.dataInfo then
			self.dataInfo.floorId = -1
		end

		return
	end

	self.box = self.go:GetComponent(typeof(UnityEngine.BoxCollider))

	if self.box then
		self.box.enabled = false
	end

	self.go:SetActive(true)

	self.data = info

	self:updateInfo()
end

function SecondBigItem:updateInfo()
	self.dataInfo = self.data
	local floorArr = self_oldBuildingFloorTable:getIDs()
	self.name.text = __("OLD_SCHOOL_FLOOR_NAME", self.data.floorId)
	local stageArr = self_oldBuildingFloorTable:getStage(self.data.floorId)

	self:setAwardImg()

	self.itemArr = {}

	NGUITools.DestroyChildren(self.showCon.gameObject.transform)
	self.second_small_item:SetActive(true)

	local type = 1

	if self.data.floorId >= 11 then
		type = 2
		self.labelDesc_.text = __("OLD_SCHOOL_FLOOR_11_TEXT01", xyd.getRoughDisplayNumber(tonumber(self.data.dataInfo.score)))
	else
		self.labelDesc_.text = __("ACTIVITY_EXPLORE_OLD_CAMPUS_BEST_SCORE", tonumber(self.data.dataInfo.score))
	end

	for i in pairs(stageArr) do
		local tmp = NGUITools.AddChild(self.showCon.gameObject, self.second_small_item.gameObject)
		local item = SecondSmallItem.new(tmp, stageArr[i], self, self.data.dataInfo.cur_scores[i], i, type)

		table.insert(self.itemArr, item)
	end

	self.second_small_item:SetActive(false)

	if #stageArr == 2 then
		self.showCon.gap = Vector2(200, 0)
	elseif #stageArr == 3 then
		self.showCon.gap = Vector2(90, 0)
	end

	self.showCon:Reposition()

	local maxIndex = xyd.models.oldSchool:getAllInfo().max_index
	local TableIndex = 999

	for i, value in pairs(self_oldBuildingFloorTable:getIDs()) do
		if value == self.data.floorId then
			TableIndex = i

			break
		end
	end

	if TableIndex <= maxIndex + 1 and self.data.floorId < 11 or xyd.models.oldSchool:checkUnlock11Floor() > 0 and self.data.floorId >= 11 then
		self.setPartnerBtn:SetActive(true)
		self.maskBg_:SetActive(false)
		self.locakImg_:SetActive(false)

		for i in pairs(self.itemArr) do
			self.itemArr[i]:setLockState(true)
		end
	else
		self.setPartnerBtn:SetActive(false)
		self.maskBg_:SetActive(true)
		self.locakImg_:SetActive(true)

		for i in pairs(self.itemArr) do
			self.itemArr[i]:setLockState(false)
		end
	end

	if not self.data.dataInfo.teams or self.data.dataInfo.teams and #self.data.dataInfo.teams == 0 then
		self.redPoint:SetActive(true)
	else
		self.redPoint:SetActive(false)
	end

	self:updateImg()
end

function SecondBigItem:updateImg()
	if self.data.floorId >= 11 then
		xyd.setUITextureByNameAsync(self.imgBg_, "old_school_bg4", true)
		xyd.setUISpriteAsync(self.labelDescBg_, nil, "old_building_special_bg2")
		xyd.setUISpriteAsync(self.nameBg_, nil, "old_building_special_bg3")
		xyd.setUITextureByNameAsync(self.locakImg_, "old_school_bg_ft2")
	else
		xyd.setUITextureByNameAsync(self.imgBg_, "old_school_bg" .. self.data.floorId % 2 + 1, true)
		xyd.setUISpriteAsync(self.labelDescBg_, nil, "old_building_floor_score_bg")
		xyd.setUISpriteAsync(self.nameBg_, nil, "old_building_floor_title_bg")
		xyd.setUITextureByNameAsync(self.locakImg_, "old_school_bg_ft")
	end
end

function SecondBigItem:setAwardImg()
	if self.data.floorId >= 11 then
		xyd.setUISpriteAsync(self.awardBtn_uisprite, nil, "btn_rank_2", function ()
			self.awardBtn_uisprite.width = 49
			self.awardBtn_uisprite.height = 49
		end, nil)
		self.awardBtnRedPoint:SetActive(false)
	else
		local isGetAllAward = false
		local getAwardNum = 0

		for i in pairs(self.data.dataInfo.awards) do
			if self.data.dataInfo.awards[i] == 1 then
				getAwardNum = getAwardNum + 1
			end
		end

		if getAwardNum >= #self.data.dataInfo.awards then
			isGetAllAward = true
		end

		if isGetAllAward then
			xyd.setUISpriteAsync(self.awardBtn_uisprite, nil, "award_icon_open", function ()
				self.awardBtn_uisprite.width = 49
				self.awardBtn_uisprite.height = 49
			end, nil)
		else
			xyd.setUISpriteAsync(self.awardBtn_uisprite, nil, "guild_war_award", function ()
				self.awardBtn_uisprite.width = 49
				self.awardBtn_uisprite.height = 49
			end, nil)
		end

		self:isCheckFloorCanGetAward()
	end
end

function SecondBigItem:isCheckFloorCanGetAward()
	for k in pairs(self.data.dataInfo.awards) do
		if self.data.dataInfo.awards[k] == 0 then
			local complete_num = self.data.dataInfo.complete_num

			if k <= complete_num then
				self.awardBtnRedPoint:SetActive(true)
				xyd.models.oldSchool:updateRedMark()

				return
			end
		end
	end

	self.awardBtnRedPoint:SetActive(false)
	xyd.models.oldSchool:updateRedMark()
end

function SecondBigItem:setAlphaAll()
	self.itemArr = {}

	NGUITools.DestroyChildren(self.showCon.gameObject.transform)
end

function SecondSmallItem:ctor(goItem, levelId, parent, cur_score, levelIndex, type)
	self.goItem_ = goItem
	self.levelId = levelId
	self.cur_score = cur_score
	self.levelIndex = levelIndex
	self.parent = parent
	self.type_ = type
	self.imgBg = self.goItem_:ComponentByName("imgBg", typeof(UISprite))
	self.labelDesc = self.goItem_:ComponentByName("labelDesc", typeof(UILabel))
	self.groupModel = self.goItem_:NodeByName("effectCon").gameObject
	self.labelBg = self.goItem_:ComponentByName("labelBg", typeof(UISprite))
	self.fightbtn = self.goItem_:NodeByName("fightbtn").gameObject
	self.goItem_widget = self.goItem_:GetComponent(typeof(UIWidget))
	self.labelIndex = self.goItem_:ComponentByName("labelIndex", typeof(UILabel))
	self.fightbtnLabel = self.fightbtn:ComponentByName("fightbtnLabel", typeof(UILabel))
	self.effectConDis = self.goItem_:ComponentByName("effectConDis", typeof(UISprite))

	xyd.setUISpriteAsync(self.imgBg, nil, "9gongge16", nil, )

	self.waitForTimeKeys_ = {}
	local widget = self.groupModel:GetComponent(typeof(UIWidget))

	print("levelId  ", levelId)

	widget.depth = 5 + self.levelIndex * 2 + xyd.tables.oldBuildingStageTable:getFloor(levelId) * 3
	self.effectConDis.depth = widget.depth + 1

	self:initItem(levelId)
	self:initEvent(levelId)
end

function SecondSmallItem:initEvent(levelId)
	UIEventListener.Get(self.fightbtn.gameObject).onClick = handler(self, function ()
		local floorArr = self_oldBuildingFloorTable:getIDs()
		local indexFloor = xyd.arrayIndexOf(floorArr, self.parent.data.floorId)

		if not self.parent.data.dataInfo.teams or self.parent.data.dataInfo.teams and #self.parent.data.dataInfo.teams == 0 and indexFloor > 1 then
			if indexFloor ~= 6 then
				local infoItems = self.parent.parent.wrapContent:getItems()

				for i in pairs(infoItems) do
					if infoItems[i].data and tonumber(infoItems[i].data.floorId) == self.parent.data.floorId - 1 and infoItems[i].data.dataInfo.teams and #infoItems[i].data.dataInfo.teams ~= 0 then
						self.parent.data.dataInfo.teams = infoItems[i].data.dataInfo.teams
						local partners = xyd.models.oldSchool:updateFormation(self.parent.data.dataInfo.teams)
						local petIDs = {
							0,
							0,
							0,
							0
						}

						for j = 1, #self.parent.data.dataInfo.teams do
							petIDs[j + 1] = self.parent.data.dataInfo.teams[j].pet_id
						end

						local floor_id = self.parent.data.floorId
						local levelNum = #self_oldBuildingFloorTable:getStage(tonumber(self.parent.data.floorId))

						xyd.models.oldSchool:setDefFormation(partners, petIDs, floor_id, levelNum)

						self.parent.parent.notShowTip = true
					end
				end
			else
				local infos = self.parent.parent.wrapContent:getInfos()

				for i in pairs(infos) do
					if infos[i].dataInfo and tonumber(infos[i].floorId) == tonumber(self.parent.data.floorId) - 1 then
						xyd.WindowManager.get():openWindow("arena_3v3_battle_formation_window", {
							isCurFloorZero = true,
							isForceSave = true,
							battleType = xyd.BattleType.EXPLORE_OLD_CAMPUS,
							formation = xyd.models.oldSchool:updateFormation(infos[i].dataInfo.teams),
							floor_id = tonumber(self.parent.data.floorId),
							levelNum = #self_oldBuildingFloorTable:getStage(tonumber(self.parent.data.floorId))
						})
					end
				end

				return
			end
		end

		if not self.parent.dataInfo.dataInfo.teams or self.parent.dataInfo.dataInfo.teams and #self.parent.dataInfo.dataInfo.teams == 0 then
			xyd.alertTips(__("ACTIVITY_EXPLORE_CAMPUS_AREA_TEAMS_EMPTY_TIPS"))

			return
		end

		local isDataError = false
		local dataDeal = xyd.models.oldSchool:updateFormation(self.parent.data.dataInfo.teams)

		for i in pairs(dataDeal) do
			local paramsData = xyd.models.slot:getPartner(dataDeal[i].partner_id)

			if not paramsData then
				isDataError = true

				break
			end
		end

		if isDataError == true then
			xyd.alertTips(__("ACTIVITY_EXPLORE_CAMPUS_TEAM_LOST_TIPS"))

			return
		end

		local isCurFloorZero = true

		for i in pairs(self.parent.data.dataInfo.cur_scores) do
			if tonumber(self.parent.data.dataInfo.cur_scores[i]) > 0 then
				isCurFloorZero = false
			end
		end

		xyd.WindowManager.get():openWindow("activity_explore_campus_fight_window", {
			area_id = xyd.tables.oldBuildingStageTable:getArea(levelId),
			levelId = tonumber(levelId),
			formation = dataDeal,
			levelIndex = self.levelIndex,
			isCurFloorZero = isCurFloorZero
		})
	end)
	UIEventListener.Get(self.goItem_.gameObject).onClick = handler(self, function ()
		local battleId = xyd.tables.oldBuildingStageTable:getBattleId(levelId)
		local enemies = xyd.tables.battleTable:getMonsters(battleId)

		xyd.WindowManager.get():openWindow("common_enemy_show_window", {
			enemies = enemies
		})
	end)
end

function SecondSmallItem:setAlpha(num, setAlpha)
	self.goItem_widget.alpha = num

	if self.heroModel_ then
		if num ~= 1 then
			self.heroModel_:setAlpha(num)
		end

		if setAlpha and setAlpha == true then
			self.heroModel_:setAlpha(num)
		end
	end
end

function SecondSmallItem:getItemObj()
	return self.goItem_
end

function SecondSmallItem:initItem(levelId)
	if self.type_ == 1 then
		self.labelDesc.text = __("ACTIVITY_EXPLORE_OLD_CAMPUS_NOW_SCORE", xyd.getRoughDisplayNumber(tonumber(self.cur_score)))
	else
		self.labelDesc.text = __("OLD_SCHOOL_FLOOR_11_TEXT02", xyd.getRoughDisplayNumber(tonumber(self.cur_score)))
	end

	self.labelIndex.text = self.levelIndex
	self.fightbtnLabel.text = __("FIGHT")
	local heroTableID = xyd.tables.oldBuildingStageTable:getPartnerId(levelId)
	local modelID = xyd.tables.partnerTable:getModelID(heroTableID)
	local name = xyd.tables.modelTable:getModelName(modelID)

	if not self.heroModel_ or self.heroModel_:getName() ~= name then
		if self.heroModel_ then
			self.heroModel_:destroy()

			self.heroModel_ = nil
		end

		local scale = xyd.tables.modelTable:getScale(modelID)
		local node = xyd.Spine.new(self.groupModel)

		node:setInfo(name, function ()
			node:SetLocalScale(-scale, scale, scale)
			node:setRenderTarget(self.groupModel:GetComponent(typeof(UITexture)), 1)
			node:play("idle", 0)
			node:setAlpha(1)
		end)

		self.heroModel_ = node
	end

	if self.parent.data.floorId >= 11 then
		xyd.setUISpriteAsync(self.labelBg, nil, "old_building_special_bg1")
	else
		xyd.setUISpriteAsync(self.labelBg, nil, "old_building_level_score_bg")
	end
end

function SecondSmallItem:setLockState(isLock)
	self.fightbtn:SetActive(isLock)
	self.labelDesc:SetActive(isLock)
	self.labelIndex:SetActive(isLock)
end

function OldSchoolMainWindow:willClose(callback)
	if self.refreshRankTime then
		self.refreshRankTime:Stop()
	end

	OldSchoolMainWindow.super.willClose(self, callback)
end

return OldSchoolMainWindow
