local ActivityContent = import(".ActivityContent")
local ActivityExploreOldCampusPVE = class("ActivityExploreOldCampusPVE", ActivityContent)
local CampusItem = class("CampusItem", import("app.components.CopyComponent"))
local SecondSmallItem = class("SecondSmallItem", import("app.components.CopyComponent"))
local SecondBigItem = class("SecondBigItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local CountDown = import("app.components.CountDown")

function ActivityExploreOldCampusPVE:ctor(parentGO, params, parent)
	self.itemArr = {}
	self.lastClickAreaNum = -1

	ActivityExploreOldCampusPVE.super.ctor(self, parentGO, params, parent)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.EXPLORE_OLD_CAMPUS_PVE, function ()
		self.activityData.isShowRedPoint = false
	end)
end

function ActivityExploreOldCampusPVE:getPrefabPath()
	return "Prefabs/Windows/activity/activity_explore_old_campus_pve"
end

function ActivityExploreOldCampusPVE:initUI()
	self:getUIComponent()
	ActivityExploreOldCampusPVE.super.initUI(self)
	self:initUIComponent()
	self:updateInfo()
end

function ActivityExploreOldCampusPVE:getUIComponent()
	local go = self.go
	self.firstGroup = go:NodeByName("firstGroup").gameObject
	self.firstGroup_uiwidget = go:ComponentByName("firstGroup", typeof(UIWidget))
	self.bgImg = self.firstGroup:ComponentByName("bgImg", typeof(UITexture))
	self.imgBg1 = self.firstGroup:ComponentByName("imgBg1", typeof(UISprite))
	self.scoreName = self.imgBg1:ComponentByName("scoreName", typeof(UILabel))
	self.scoreLabel = self.imgBg1:ComponentByName("scoreLabel", typeof(UILabel))
	self.textImg = self.firstGroup:ComponentByName("textImg", typeof(UITexture))
	self.textLabel01 = self.firstGroup:ComponentByName("textLabel01", typeof(UILabel))
	self.textLabelImg = self.firstGroup:ComponentByName("textLabelImg", typeof(UISprite))
	self.timeLabelIImg = self.firstGroup:ComponentByName("timeLabelIImg", typeof(UISprite))
	self.timeLabelIImg_widget = self.firstGroup:ComponentByName("timeLabelIImg", typeof(UIWidget))
	self.timeLabelIImg_layout = self.firstGroup:ComponentByName("timeLabelIImg", typeof(UILayout))
	self.timeLabel = self.timeLabelIImg:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeLabelIImg:ComponentByName("endLabel", typeof(UILabel))
	self.scrollerBg = self.firstGroup:ComponentByName("scrollerBg", typeof(UISprite))
	self.e_Scroller = self.firstGroup:ComponentByName("e:Scroller", typeof(UIScrollView))
	self.groupItem = self.e_Scroller:ComponentByName("groupItem", typeof(UIGrid))
	self.drag = self.firstGroup:NodeByName("drag").gameObject
	self.bgImg2 = self.firstGroup:ComponentByName("bgImg2", typeof(UISprite))
	self.helpBtn = self.firstGroup:NodeByName("helpBtn").gameObject
	self.awardBtn = self.firstGroup:NodeByName("awardBtn").gameObject
	self.rankBtn = self.firstGroup:NodeByName("rankBtn").gameObject
	self.explore_item = self.go:NodeByName("explore_item").gameObject

	xyd.setUITextureByNameAsync(self.textImg, "old_building_logo_" .. xyd.Global.lang, true)
	xyd.setUISpriteAsync(self.textLabelImg, nil, "old_building_desc_bg", nil, )
	xyd.setUISpriteAsync(self.imgBg1, nil, "old_building_score_bg", nil, )

	self.textLabel01.text = __("ACTIVITY_EXPLORE_OLD_CAMPUS_DESC")
	self.scoreName.text = __("TOTAL_GRADE")
	self.secondGroup = self.go:NodeByName("secondGroup").gameObject
	self.secondGroup_uiwidget = self.go:ComponentByName("secondGroup", typeof(UIWidget))
	self.secibdBgImg = self.secondGroup:ComponentByName("secibdBgImg", typeof(UITexture))
	self.secondScroller = self.secondGroup:ComponentByName("secondScroller", typeof(UIScrollView))
	self.secondScrollerCon = self.secondScroller:ComponentByName("secondScrollerCon", typeof(MultiRowWrapContent))
	local wrapContent = self.secondScroller:ComponentByName("secondScrollerCon", typeof(MultiRowWrapContent))
	self.drag = self.secondGroup:NodeByName("drag").gameObject
	self.backBtn = self.secondGroup:NodeByName("backBtn").gameObject
	self.caseBtn = self.secondGroup:NodeByName("caseBtn").gameObject
	self.caseBtnLabel = self.caseBtn:ComponentByName("caseBtnLabel", typeof(UILabel))
	self.second_big_item = self.go:NodeByName("second_big_item").gameObject
	self.wrapContent = FixedMultiWrapContent.new(self.secondScroller, wrapContent, self.second_big_item, SecondBigItem, self)

	self.firstGroup:SetLocalPosition(0, 0, 0)
	self.secondGroup:SetLocalPosition(2000, 0, 0)

	self.caseBtnLabel.text = __("ACTIVITY_EXPLORE_CAMPUS_3")

	self:waitForFrame(2, function ()
		self.secondGroup_uiwidget.height = self.go:GetComponent(typeof(UIWidget)).height
		self.firstGroup_uiwidget.updateAnchors = UIRect.AnchorUpdate.OnEnable
	end)
	self.textImg:Y(-75.2 + -28.799999999999997 * self.scale_num_contrary)
	self.textLabel01:Y(-250 + -67 * self.scale_num_contrary)
	self.timeLabelIImg:Y(-146 + -39.599999999999994 * self.scale_num_contrary)
	self.imgBg1:Y(-381 + -99 * self.scale_num_contrary)
end

function ActivityExploreOldCampusPVE:initUIComponent()
	self.data = xyd.tables.activityOldBuildingAreaTable:getIDs()

	self:waitForFrame(2, function ()
		for i in pairs(self.data) do
			local tmp = NGUITools.AddChild(self.groupItem.gameObject, self.explore_item.gameObject)
			local item = CampusItem.new(tmp, self.data[i], self)

			table.insert(self.itemArr, item)
		end

		self.groupItem:Reposition()
		self.e_Scroller:ResetPosition()
	end)

	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_EXPLORE_CAMPUS_HELP"
		})
	end)
	UIEventListener.Get(self.caseBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_explore_old_campus_ways_window", {
			area_id = self.area_id
		})
	end)
	UIEventListener.Get(self.backBtn.gameObject).onClick = handler(self, function ()
		self:enterOne()
	end)

	UIEventListener.Get(self.rankBtn.gameObject).onClick = function ()
		local msg = messages_pb.old_building_activity_get_rank_list_req()
		msg.activity_id = xyd.ActivityID.EXPLORE_OLD_CAMPUS_PVE

		xyd.Backend.get():request(xyd.mid.OLD_BUILDING_ACTIVITY_GET_RANK_LIST, msg)
	end

	UIEventListener.Get(self.awardBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_explore_campus_PVE_point_window", {})
	end

	self:registerEvent(xyd.event.OLD_BUILDING_ACTIVITY_GET_FLOORS_INFO, function (event)
		local eventData = xyd.decodeProtoBuf(event.data)
		local floorArr = xyd.tables.activityOldBuildingAreaTable:getFloor(tonumber(eventData.area_id))
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

		self:enterSecond(detailArr, eventData.area_id)
		self.activityData:saveCurOpenAreaFloorsInfo(eventData)

		self.area_id = tonumber(eventData.area_id)
	end)
	self:registerEvent(xyd.event.OLD_BUILDING_ACTIVITY_SET_TEAMS, function (event)
		local data = xyd.decodeProtoBuf(event.data)
		local infoItems = self.wrapContent:getItems()

		for i in pairs(infoItems) do
			if infoItems[i].data and infoItems[i].data.floorId == data.floor_id and infoItems[i].data.floorId == self.activityData:getDefUpdataInfo().floor_id then
				infoItems[i].data.dataInfo.teams = self.activityData:getDefUpdataInfo().teams
				local fightWin = xyd.WindowManager.get():getWindow("activity_explore_campus_fight_window")

				if fightWin and xyd.tables.activityOldBuildingStageTable:getFloor(fightWin:getLevelId()) == infoItems[i].data.floorId then
					fightWin:updateHeroIcons(self.activityData:updateFormation(infoItems[i].data.dataInfo.teams))
				end

				for j in pairs(infoItems[i].data.dataInfo.cur_scores) do
					infoItems[i].data.dataInfo.cur_scores[j] = 0
				end

				infoItems[i]:update(nil, , infoItems[i].data)
				self:updateActivityDataAreaInfo(data.floor_id, infoItems[i].data.dataInfo)
			end
		end

		xyd.alertTips(__("ACTIVITY_EXPLORE_CAMPUS_SCORE_SET_TEAM_SUCCESS"))
	end)
	self:registerEvent(xyd.event.OLD_BUILDING_ACTIVITY_UNLOCK_BUFF, function (event)
		local data = xyd.decodeProtoBuf(event.data)
		local buyWin = xyd.WindowManager.get():getWindow("activity_explore_old_campus_way_buy_window")

		if buyWin then
			xyd.WindowManager.get():closeWindow("activity_explore_old_campus_way_buy_window")
		end

		self.activityData:updateUnlockBuffInfo(data)
		xyd.alertTips(__("ACTIVITY_EXPLORE_CAMPUS_PURCHASE_SUCCESS"))
	end)
	self:registerEvent(xyd.event.OLD_BUILDING_ACTIVITY_GET_RANK_LIST, function (event)
		xyd.WindowManager.get():openWindow("activity_explore_campus_PVE_rank_window", {
			rankData = event.data
		})
	end)

	self.endLabel.text = __("END_TEXT")
	local leftTime = self.activityData:getEndTime() - xyd.getServerTime()

	if leftTime > 0 then
		self.leftTimeCount = CountDown.new(self.timeLabel, {
			duration = leftTime,
			callback = handler(self, self.timeOver)
		})
	else
		self.timeLabel.text = "00:00:00"
	end

	self.timeLabelIImg_layout:Reposition()

	self.timeLabelIImg_widget.width = self.timeLabel.width + self.endLabel.width + self.timeLabelIImg_layout.gap.x + 50

	self:registerEvent(xyd.event.OLD_BUILDING_ACTIVITY_FIGHT, handler(self, self.onOldBuildingFight))
end

function ActivityExploreOldCampusPVE:timeOver(itemdata)
	self.timeLabel.text = "00:00:00"
end

function ActivityExploreOldCampusPVE:onOldBuildingFight(event)
	local data = event.data

	if not data.floor_info then
		return
	end

	if not data.battle_result then
		return
	end

	data = xyd.decodeProtoBuf(event.data)
	local backFloorId = xyd.tables.activityOldBuildingStageTable:getFloor(tonumber(data.stage_id))
	local infoItems = self.wrapContent:getItems()

	for i in pairs(infoItems) do
		if infoItems[i].data and infoItems[i].data.floorId == backFloorId then
			infoItems[i].data.dataInfo.complete_num = data.floor_info.complete_num
			infoItems[i].data.dataInfo.completeds = data.floor_info.completeds
			infoItems[i].data.dataInfo.cur_scores = data.floor_info.cur_scores
			infoItems[i].data.dataInfo.score = data.floor_info.score

			infoItems[i]:update(nil, , infoItems[i].data)
			self:updateActivityDataAreaInfo(backFloorId, infoItems[i].data.dataInfo)

			if data.floor_info.complete_num > 0 then
				self:checkFloorLock(backFloorId)
			end

			self:updateAreaScoreAndAllScore(backFloorId, data.floor_info.score)
		end
	end
end

function ActivityExploreOldCampusPVE:updateActivityDataAreaInfo(backFloorId, data)
	local floorIndex = 0
	local floorsArr = xyd.tables.activityOldBuildingAreaTable:getFloor(self.area_id)

	for k in pairs(floorsArr) do
		if tonumber(floorsArr[k]) == backFloorId then
			floorIndex = k

			break
		end
	end

	local curAreaInfo = self.activityData:getCurOpenAreaFloorsInfo()
	curAreaInfo.floor_infos[floorIndex] = data

	self.activityData:saveCurOpenAreaFloorsInfo(curAreaInfo)
end

function ActivityExploreOldCampusPVE:updateAreaScoreAndAllScore(backFloorId, score)
	local areaInfo = self.activityData:getCurOpenAreaFloorsInfo()
	local area_score = 0

	for i in pairs(areaInfo.floor_infos) do
		area_score = area_score + areaInfo.floor_infos[i].score
	end

	self.activityData.detail.area_infos[self.area_id].score = area_score
	local all_score = 0

	for i in pairs(self.activityData.detail.area_infos) do
		all_score = all_score + self.activityData.detail.area_infos[i].score
	end

	self.activityData.detail.score = all_score
	self.scoreLabel.text = self.activityData.detail.score

	self.activityData:setScore(all_score, self.area_id, area_score)

	for i in pairs(self.itemArr) do
		if tonumber(self.itemArr[i].areaId) == self.area_id then
			self.itemArr[i]:updateScore()
		end
	end

	local floorsArr = xyd.tables.activityOldBuildingAreaTable:getFloor(self.area_id)

	if self.activityData.detail.area_infos[self.area_id].max_index == #floorsArr then
		for i in pairs(self.itemArr) do
			if tonumber(self.itemArr[i].areaId) == self.area_id then
				self.itemArr[i]:updateIconChoose(true)
			end
		end
	end
end

function ActivityExploreOldCampusPVE:checkFloorLock(backFloorId)
	local floorIndex = 0
	local floorsArr = xyd.tables.activityOldBuildingAreaTable:getFloor(self.area_id)

	for k in pairs(floorsArr) do
		if tonumber(floorsArr[k]) == backFloorId then
			floorIndex = k

			break
		end
	end

	if self.activityData.detail.area_infos[self.area_id].max_index < floorIndex then
		self.activityData.detail.area_infos[self.area_id].max_index = floorIndex
	end

	if floorIndex < #floorsArr then
		local nextFloorId = floorsArr[floorIndex + 1]
		local infoItems = self.wrapContent:getItems()

		for i in pairs(infoItems) do
			if infoItems[i].data and infoItems[i].data.floorId == nextFloorId then
				infoItems[i]:update(nil, , infoItems[i].data)
			end
		end
	end
end

function ActivityExploreOldCampusPVE:enterOne(itemdata)
	local itemArr = self.wrapContent:getItems()

	for i in pairs(itemArr) do
		itemArr[i]:setAlphaAll()
	end

	self.firstGroup:SetLocalPosition(0, 0, 0)
	self.secondGroup:SetLocalPosition(2000, 0, 0)
end

function ActivityExploreOldCampusPVE:enterSecond(floorArr, areaId)
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
	self:waitForFrame(1, function ()
		self.wrapContent:jumpToInfo2(floorArr[goToIndex])
		self:waitForFrame(1, function ()
			self.firstGroup:SetLocalPosition(2000, 0, 0)
			self.secondGroup:SetLocalPosition(0, 0, 0)
		end)
	end)
end

function ActivityExploreOldCampusPVE:updateInfo()
	self.activityData = xyd.models.activity:getActivity(self.id)
	self.scoreLabel.text = self.activityData.detail.score
end

function CampusItem:ctor(goItem, areaId, parent)
	self.goItem_ = goItem
	self.areaId = areaId
	self.parent = parent
	self.iconArr = {}
	self.imgBg_ = self.goItem_:ComponentByName("imgBg_", typeof(UISprite))
	self.imgBg_right = self.goItem_:ComponentByName("imgBg_right", typeof(UISprite))
	self.labelTitle_ = self.goItem_:ComponentByName("labelTitle_", typeof(UILabel))
	self.labelDesc_ = self.goItem_:ComponentByName("labelDesc_", typeof(UILabel))
	self.showIconCon = self.goItem_:NodeByName("showIconCon").gameObject
	self.showIconCon_grid = self.goItem_:ComponentByName("showIconCon", typeof(UIGrid))
	self.maskBg_ = self.goItem_:ComponentByName("maskBg_", typeof(UISprite))
	self.locakImg_ = self.goItem_:ComponentByName("locakImg_", typeof(UISprite))
	self.labelTime_ = self.goItem_:ComponentByName("labelTime_ ", typeof(UILabel))

	xyd.setUISpriteAsync(self.imgBg_, nil, "old_building_area_bg_" .. self.areaId, nil, )
	xyd.setUISpriteAsync(self.locakImg_, nil, "lock", nil, )
	self:initItem(areaId)
	self:initEvent(areaId)

	areaId = tonumber(areaId)
	self.labelTitle_.text = __("ACTIVITY_EXPLORE_CAMPUS_AREA_" .. areaId)

	if self.parent.activityData:onAreaIsUnLock(areaId) == true then
		self.maskBg_:SetActive(false)
		self.locakImg_:SetActive(false)

		self.labelTime_.text = ""

		self.labelDesc_:SetActive(true)

		self.labelDesc_.text = __("ACTIVITY_EXPLORE_OLD_CAMPUS_AREA_GRADE") .. self.parent.activityData.detail.area_infos[areaId].score
	else
		self.maskBg_:SetActive(true)
		self.locakImg_:SetActive(true)

		local time = self.parent.activityData:getAreaIsLockTime(areaId)

		if time > 0 then
			self.labelDesc_.text = ""

			self.labelDesc_:SetActive(false)

			self["setCountDownTime" .. areaId] = CountDown.new(self.labelTime_, {
				duration = time,
				callback = handler(self, self.timeOver)
			})
		else
			self.labelTime_.text = ""

			self.labelDesc_:SetActive(true)

			self.labelDesc_.text = __("ACTIVITY_EXPLORE_OLD_CAMPUS_AREA_GRADE") .. self.parent.activityData.detail.area_infos[areaId].score
		end
	end

	local floorsArr = xyd.tables.activityOldBuildingAreaTable:getFloor(tonumber(self.areaId))

	if self.parent.activityData.detail.area_infos[tonumber(self.areaId)].max_index == #floorsArr then
		self:updateIconChoose(true)
	end
end

function CampusItem:timeOver()
	self.maskBg_:SetActive(false)
	self.locakImg_:SetActive(false)

	self.labelTime_.text = ""

	self.labelDesc_:SetActive(true)

	self.labelDesc_.text = __("ACTIVITY_EXPLORE_OLD_CAMPUS_AREA_GRADE") .. self.parent.activityData.detail.area_infos[self.areaId].score
end

function CampusItem:initEvent(areaId)
	UIEventListener.Get(self.goItem_.gameObject).onClick = handler(self, function ()
		local msg = messages_pb:old_building_activity_get_floors_info_req()
		msg.activity_id = self.parent.id
		msg.area_id = tonumber(areaId)

		xyd.Backend.get():request(xyd.mid.OLD_BUILDING_ACTIVITY_GET_FLOORS_INFO, msg)
	end)
	UIEventListener.Get(self.maskBg_.gameObject).onClick = handler(self, function ()
		xyd.alertTips(__("ACTIVITY_EXPLORE_CAMPUS_AREA_LOCK_TIPS", self.labelTime_.text))
	end)
end

function CampusItem:initItem(areaId)
	local awards = xyd.tables.activityOldBuildingAreaTable:getAwards(areaId)

	for i, value in pairs(awards) do
		local item = {
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = tonumber(value[1]),
			num = tonumber(value[2]),
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			uiRoot = self.showIconCon.gameObject
		}
		local icon = xyd.getItemIcon(item)

		table.insert(self.iconArr, icon)
	end

	self.showIconCon_grid:Reposition()
end

function CampusItem:updateScore()
	self.labelDesc_.text = __("ACTIVITY_EXPLORE_OLD_CAMPUS_AREA_GRADE") .. self.parent.activityData.detail.area_infos[tonumber(self.areaId)].score
end

function CampusItem:updateIconChoose(isChoose)
	for i in pairs(self.iconArr) do
		self.iconArr[i]:setChoose(isChoose)
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
	self.labelDesc_ = self.go:ComponentByName("labelDesc_", typeof(UILabel))
	self.labelDescBg_ = self.go:ComponentByName("labelDescBg_", typeof(UISprite))
	self.showCon = self.go:ComponentByName("showCon", typeof(UILayout))
	self.maskBg_ = self.go:ComponentByName("maskBg_", typeof(UISprite))
	self.locakImg_ = self.go:ComponentByName("locakImg_", typeof(UITexture))
	self.second_small_item = self.go:NodeByName("second_small_item").gameObject
	self.awardBtn = self.go:NodeByName("awardBtn").gameObject
	self.awardBtn_uisprite = self.go:ComponentByName("awardBtn", typeof(UISprite))

	xyd.setUITextureByNameAsync(self.locakImg_, "old_building_floor_mask_2")

	self.setPartnerBtnLabel.text = __("SET_DEF_FORMATION")
	UIEventListener.Get(self.setPartnerBtn.gameObject).onClick = handler(self, function ()
		if self.dataInfo then
			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.EXPLORE_OLD_CAMPUS_PVE)
			local areaId = xyd.tables.activityOldBuildingTable:getArea(self.data.floorId)
			local floorArr = xyd.tables.activityOldBuildingAreaTable:getFloor(areaId)
			local indexFloor = xyd.arrayIndexOf(floorArr, self.data.floorId)

			if not self.data.dataInfo.teams or self.data.dataInfo.teams and #self.data.dataInfo.teams == 0 and indexFloor > 1 then
				xyd.alertYesNo(__("ACTIVITY_EXPLORE_CAMPUS_TEAM_SAVE"), function (yes)
					if yes then
						if indexFloor > 1 then
							local infos = self.parent.wrapContent:getInfos()

							for i in pairs(infos) do
								if infos[i].dataInfo and infos[i].floorId == self.data.floorId - 1 then
									xyd.WindowManager.get():openWindow("arena_3v3_battle_formation_window", {
										isCurFloorZero = true,
										isForceSave = true,
										battleType = xyd.BattleType.EXPLORE_OLD_CAMPUS,
										formation = activityData:updateFormation(infos[i].dataInfo.teams),
										floor_id = self.data.floorId,
										levelNum = #xyd.tables.activityOldBuildingTable:getStage(self.data.floorId)
									})
								end
							end
						end
					else
						self:open3V3Win()
					end
				end)
			else
				self:open3V3Win()
			end
		end
	end)
	UIEventListener.Get(self.awardBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_explore_old_campus_floor_award_window", {
			floor_id = self.data.floorId,
			completeds = self.data.dataInfo.completeds,
			complete_num = self.data.dataInfo.complete_num
		})
	end)
	UIEventListener.Get(self.maskBg_.gameObject).onClick = handler(self, function ()
		xyd.alertTips(__("ACTIVITY_EXPLORE_CAMPUS_FLOOR_LOCK_TIPS"))
	end)
end

function SecondBigItem:open3V3Win()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.EXPLORE_OLD_CAMPUS_PVE)
	local isCurFloorZero = true

	for i in pairs(self.data.dataInfo.cur_scores) do
		if self.data.dataInfo.cur_scores[i] > 0 then
			isCurFloorZero = false
		end
	end

	xyd.WindowManager.get():openWindow("arena_3v3_battle_formation_window", {
		battleType = xyd.BattleType.EXPLORE_OLD_CAMPUS,
		formation = activityData:updateFormation(self.data.dataInfo.teams),
		floor_id = self.data.floorId,
		levelNum = #xyd.tables.activityOldBuildingTable:getStage(self.data.floorId),
		isCurFloorZero = isCurFloorZero
	})
end

function SecondBigItem:update(wrapIndex, index, info)
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

	self.go:SetActive(true)

	self.data = info

	self:updateInfo()
end

function SecondBigItem:updateInfo()
	self.dataInfo = self.data
	local areaId = xyd.tables.activityOldBuildingTable:getArea(self.data.floorId)
	local floorArr = xyd.tables.activityOldBuildingAreaTable:getFloor(areaId)
	self.name.text = __("ACTIVITY_EXPLORE_CAMPUS_AREA_FLOOR_" .. areaId, xyd.arrayIndexOf(floorArr, self.data.floorId))
	local stageArr = xyd.tables.activityOldBuildingTable:getStage(self.data.floorId)

	xyd.setUITextureByNameAsync(self.imgBg_, "old_building_floor_bg_" .. self.data.floorId % 2 + 1, true)

	self.labelDesc_.text = __("ACTIVITY_EXPLORE_OLD_CAMPUS_BEST_SCORE", self.data.dataInfo.score)

	if self.data.dataInfo.complete_num >= #self.data.dataInfo.completeds then
		xyd.setUISpriteAsync(self.awardBtn_uisprite, nil, "award_icon_open", function ()
			self:setAwardImg()
		end, nil)
	else
		xyd.setUISpriteAsync(self.awardBtn_uisprite, nil, "guild_war_award", function ()
			self:setAwardImg()
		end, nil)
	end

	self.itemArr = {}

	NGUITools.DestroyChildren(self.showCon.gameObject.transform)
	self.second_small_item:SetActive(true)

	for i in pairs(stageArr) do
		local tmp = NGUITools.AddChild(self.showCon.gameObject, self.second_small_item.gameObject)
		local item = SecondSmallItem.new(tmp, stageArr[i], self, self.data.dataInfo.cur_scores[i], i)

		table.insert(self.itemArr, item)
	end

	self.second_small_item:SetActive(false)

	if #stageArr == 2 then
		self.showCon.gap = Vector2(200, 0)
	elseif #stageArr == 3 then
		self.showCon.gap = Vector2(90, 0)
	end

	self.showCon:Reposition()

	local areaId = xyd.tables.activityOldBuildingTable:getArea(self.data.floorId)
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.EXPLORE_OLD_CAMPUS_PVE)
	local maxIndex = activityData.detail.area_infos[areaId].max_index
	local TableIndex = 999

	for i, value in pairs(xyd.tables.activityOldBuildingAreaTable:getFloor(areaId)) do
		if value == self.data.floorId then
			TableIndex = i

			break
		end
	end

	if TableIndex <= maxIndex + 1 then
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
end

function SecondBigItem:setAwardImg()
	if self.data.dataInfo.complete_num >= #self.data.dataInfo.completeds then
		xyd.setUISpriteAsync(self.awardBtn_uisprite, nil, "award_icon_open", function ()
			self.awardBtn_uisprite:MakePixelPerfect()
			self.awardBtn_uisprite:SetLocalScale(0.7, 0.7, 0.7)
		end, nil)
	else
		xyd.setUISpriteAsync(self.awardBtn_uisprite, nil, "guild_war_award", function ()
			self.awardBtn_uisprite:MakePixelPerfect()
			self.awardBtn_uisprite:SetLocalScale(0.7, 0.7, 0.7)
		end, nil)
	end
end

function SecondBigItem:setAlphaAll()
	self.itemArr = {}

	NGUITools.DestroyChildren(self.showCon.gameObject.transform)
end

function SecondSmallItem:ctor(goItem, levelId, parent, cur_score, levelIndex)
	self.goItem_ = goItem
	self.levelId = levelId
	self.cur_score = cur_score
	self.levelIndex = levelIndex
	self.parent = parent
	self.imgBg = self.goItem_:ComponentByName("imgBg", typeof(UISprite))
	self.labelDesc = self.goItem_:ComponentByName("labelDesc", typeof(UILabel))
	self.groupModel = self.goItem_:NodeByName("effectCon").gameObject
	self.labelBg = self.goItem_:ComponentByName("labelBg", typeof(UISprite))
	self.fightbtn = self.goItem_:NodeByName("fightbtn").gameObject
	self.goItem_widget = self.goItem_:GetComponent(typeof(UIWidget))
	self.labelIndex = self.goItem_:ComponentByName("labelIndex", typeof(UILabel))
	self.fightbtnLabel = self.fightbtn:ComponentByName("fightbtnLabel", typeof(UILabel))

	xyd.setUISpriteAsync(self.imgBg, nil, "9gongge16", nil, )
	self:initItem(levelId)
	self:initEvent(levelId)
end

function SecondSmallItem:initEvent(levelId)
	UIEventListener.Get(self.fightbtn.gameObject).onClick = handler(self, function ()
		if not self.parent.dataInfo.dataInfo.teams or self.parent.dataInfo.dataInfo.teams and #self.parent.dataInfo.dataInfo.teams == 0 then
			xyd.alertTips(__("ACTIVITY_EXPLORE_CAMPUS_AREA_TEAMS_EMPTY_TIPS"))

			return
		end

		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.EXPLORE_OLD_CAMPUS_PVE)
		local isDataError = false
		local dataDeal = activityData:updateFormation(self.parent.data.dataInfo.teams)

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
			if self.parent.data.dataInfo.cur_scores[i] > 0 then
				isCurFloorZero = false
			end
		end

		xyd.WindowManager.get():openWindow("activity_explore_campus_fight_window", {
			area_id = xyd.tables.activityOldBuildingStageTable:getArea(levelId),
			levelId = tonumber(levelId),
			formation = dataDeal,
			levelIndex = self.levelIndex,
			isCurFloorZero = isCurFloorZero
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
	self.labelDesc.text = __("ACTIVITY_EXPLORE_OLD_CAMPUS_NOW_SCORE", self.cur_score)
	self.labelIndex.text = self.levelIndex
	self.fightbtnLabel.text = __("FIGHT")
	local heroTableID = xyd.tables.activityOldBuildingStageTable:getPartnerId(levelId)
	local modelID = xyd.tables.partnerTable:getModelID(heroTableID)
	local name = xyd.tables.modelTable:getModelName(modelID)

	if not self.heroModel_ or self.heroModel_:getName() ~= name then
		if self.heroModel_ then
			self.heroModel_:destroy()

			self.heroModel_ = nil
		end

		local widget = self.groupModel:GetComponent(typeof(UIWidget))
		local scale = xyd.tables.modelTable:getScale(modelID)
		local node = xyd.Spine.new(self.groupModel)

		node:setInfo(name, function ()
			node:SetLocalScale(-scale, scale, scale)
			node:setRenderTarget(self.groupModel:GetComponent(typeof(UIWidget)), 1)
			node:play("idle", 0)
			node:setAlpha(1)
		end)

		self.heroModel_ = node
	end
end

function SecondSmallItem:setLockState(isLock)
	self.fightbtn:SetActive(isLock)
	self.labelDesc:SetActive(isLock)
	self.labelIndex:SetActive(isLock)
end

return ActivityExploreOldCampusPVE
