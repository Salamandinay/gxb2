local BaseWindow = import(".BaseWindow")
local TavernWindow = class("TavernWindow", BaseWindow)
local backpackModel = xyd.models.backpack
local TavernModel = xyd.models.tavern
local PubScrollTable = xyd.tables.pubScrollTable
local ResItem = import("app.components.ResItem")
local PubMissionNameTextTable = xyd.tables.pubMissionNameTextTable
local missionStatus = {
	UN_DO = 0,
	DOING = 1,
	DONE = 2
}
local MissionItem = class("MissionItem", import("app.components.CopyComponent"))
local OldSize = {
	w = 720,
	h = 1280
}

function MissionItem:ctor(go, parent)
	self.parent_ = parent

	MissionItem.super.ctor(self, go)
end

function MissionItem:initUI()
	MissionItem.super.initUI(self)

	self.go_ = self.go
	self.uiPanel_ = self.parent_:getUIPanel()
	self.starGrid_ = self.go_.transform:ComponentByName("starBg/gridOfStar", typeof(UIGrid))
	self.starIcon_ = self.go_.transform:ComponentByName("starBg/starIcon", typeof(UISprite))
	self.starBg_ = self.go_.transform:ComponentByName("starBg", typeof(UISprite))
	self.awardItem_ = self.go_.transform:Find("itemPos").gameObject
	self.needPart_ = self.go_.transform:Find("needPart").gameObject
	self.btnPart_ = self.go_.transform:Find("btnPart").gameObject
	self.bg_ = self.go_.transform:ComponentByName("bg", typeof(UISprite))
	self.btnComplete_ = self.go_.transform:ComponentByName("btnPart/btnComolete", typeof(UISprite))
	self.descComplete_ = self.go_.transform:ComponentByName("btnPart/btnComolete/label", typeof(UILabel))
	self.btnCancel_ = self.go_.transform:ComponentByName("btnPart/btnCancel", typeof(UISprite))
	self.btnSpeed_ = self.go_.transform:ComponentByName("btnPart/btnSpeed", typeof(UISprite))
	self.btnSpeedIcon_ = self.go_.transform:ComponentByName("btnPart/btnSpeed/icon", typeof(UISprite))
	self.btnSpeedNum_ = self.go_.transform:ComponentByName("btnPart/btnSpeed/speedNum", typeof(UILabel))
	self.btnSpeedDesc_ = self.go_.transform:ComponentByName("btnPart/btnSpeed/label", typeof(UILabel))
	self.lockBtn_ = self.go_.transform:ComponentByName("lockBtn", typeof(UISprite))
	self.progressBar_ = self.go_.transform:ComponentByName("progressPart", typeof(UIProgressBar))
	self.progressValue_ = self.go_.transform:ComponentByName("progressPart/progressValue", typeof(UISprite))
	self.progressDesc_ = self.go_.transform:ComponentByName("progressPart/labelDesc", typeof(UILabel))
	self.needTimeLabel_ = self.go_.transform:ComponentByName("needPart/labelDesc", typeof(UILabel))
	self.labelName_ = self.go_.transform:ComponentByName("topLable", typeof(UILabel))
	self.effect_ = xyd.Spine.new(self.bg_.gameObject)
	self.upIcon = self.go:NodeByName("upIcon")

	if self.parent_.isShowUp ~= -1 then
		self.upIcon:SetActive(true)
		xyd.setUISpriteAsync(self.upIcon.gameObject:GetComponent(typeof(UISprite)), nil, "common_tips_up_" .. self.parent_.isShowUp, nil, , )
	else
		self.upIcon:SetActive(false)
	end

	for i = 1, 7 do
		NGUITools.AddChild(self.starGrid_.gameObject, self.starIcon_.gameObject)
	end
end

function MissionItem:isRefresh()
	return self.isRefresh_
end

function MissionItem:update(_, _, missionData)
	if not missionData then
		self.go_:SetActive(false)

		return
	end

	self.go_:SetActive(true)

	if self.countDown_ then
		self.countDown_:stopTimeCount()
	end

	if self.progressEffect_ then
		self.progressEffect_:SetActive(false)
	end

	self.progressDesc_.color = Color.New2(4294967295.0)
	self.progressDesc_.effectStyle = UILabel.Effect.Outline
	self.progressDesc_.effectColor = Color.New2(255)
	self.isRefresh_ = false
	self.data_ = missionData
	self.missionTime_ = xyd.tables.pubMissionTable:getMissionTime(self.data_.table_id)
	self.labelName_.text = __(PubMissionNameTextTable:getName(self.data_.name))
	self.progressBar_.value = 0

	if self.effect_ then
		self.effect_:SetActive(false)
	end

	if self.data_.status == missionStatus.UN_DO then
		self.btnPart_.gameObject:SetActive(false)
		self.needPart_.gameObject:SetActive(true)

		self.progressDesc_.text = __("PUB_MISSION_NO_START")
		self.needTimeLabel_.text = xyd.getRoughDisplayTime(self.missionTime_)
	else
		self.descComplete_.text = __("PUB_MISSION_COMPLETE2")

		self.btnPart_.gameObject:SetActive(true)
		self.needPart_.gameObject:SetActive(false)
		self:changeBarValue()
	end

	local award = self.data_.award

	if not self.item_ then
		self.item_ = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			hideText = true,
			itemID = award[1],
			num = award[2],
			uiRoot = self.awardItem_,
			dragScrollView = self.scrollView_
		})
	else
		for i = 0, self.awardItem_.transform.childCount - 1 do
			local child = self.awardItem_.transform:GetChild(i).gameObject

			UnityEngine.Object.Destroy(child)
		end

		self.item_ = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			hideText = true,
			itemID = award[1],
			num = award[2],
			uiRoot = self.awardItem_,
			dragScrollView = self.scrollView_
		})
	end

	self.item_:setInfo({
		isAddUIDragScrollView = true,
		hideText = true,
		itemID = award[1],
		num = award[2],
		uiRoot = self.awardItem_,
		dragScrollView = self.scrollView_
	})
	self:chargeLockStatus()

	local cost = xyd.tables.pubMissionTable:getSpeedupCost(self.data_.table_id)

	if tonumber(cost[2]) == 0 then
		self.btnSpeedIcon_.gameObject:SetActive(false)
		self.btnSpeedNum_.gameObject:SetActive(false)

		self.btnSpeedDesc_.transform.localPosition = Vector3(-22, 1, 0)
		self.btnSpeedDesc_.text = __("PUB_SPEED_FREE")

		if xyd.Global.lang == "fr_fr" then
			self.btnSpeedDesc_.fontSize = 18

			self.btnSpeedDesc_:X(-30)
		end
	else
		xyd.setUISpriteAsync(self.btnSpeedIcon_, nil, "item_2", nil, )
		self.btnSpeedIcon_.gameObject:SetActive(true)
		self.btnSpeedNum_.gameObject:SetActive(true)

		if xyd.Global.lang == "de_de" then
			self.btnSpeedDesc_.transform.localPosition = Vector3(-20, 1, 0)
		elseif xyd.Global.lang == "fr_fr" then
			self.btnSpeedDesc_.fontSize = 16
			self.btnSpeedDesc_.transform.localPosition = Vector3(-20, 1, 0)
		else
			self.btnSpeedDesc_.transform.localPosition = Vector3(-5, 1, 0)
		end

		self.btnSpeedNum_.text = cost[2]
		self.btnSpeedDesc_.text = __("PUB_SPEED_UP")
	end

	self.starIcon_.gameObject:SetActive(false)

	local star = xyd.tables.pubMissionTable:getStar(self.data_.table_id)

	if not self.star_ or self.star_ ~= star then
		self.star_ = star

		xyd.setUISpriteAsync(self.starBg_, nil, "pub_mission_star" .. self.star_, nil, )

		for i = 1, 7 do
			local tempStar = self.starGrid_.transform:GetChild(i - 1).gameObject

			tempStar:SetActive(i <= self.star_)
		end
	end

	self.starGrid_:Reposition()

	UIEventListener.Get(self.lockBtn_.gameObject).onClick = handler(self, self.onClickLock)
	UIEventListener.Get(self.btnComplete_.gameObject).onClick = handler(self, self.onClickComplete)
	UIEventListener.Get(self.btnCancel_.gameObject).onClick = handler(self, self.onClickCancel)
	UIEventListener.Get(self.btnSpeed_.gameObject).onClick = handler(self, self.onClickSpeed)
	UIEventListener.Get(self.bg_.gameObject).onClick = handler(self, self.onClickItem)
end

function MissionItem:onClickItem()
	local missions = xyd.models.tavern:getMissions()
	local count = 0
	local maxCount = tonumber(xyd.tables.miscTable:getVal("pub_mission_max"))

	for _, id in pairs(missions) do
		local info = xyd.models.tavern:getMissionById(id)

		if info.status == 1 or info.status == 2 then
			count = count + 1
		end
	end

	if maxCount <= count then
		xyd.showToast(__("PUB_MISSION_LIMIT_TIPS"))
	else
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		xyd.WindowManager.get():openWindow("tavern_detail_window", self.data_)
	end
end

function MissionItem:chargeLockStatus()
	if self.data_.is_lock == 1 then
		xyd.setUISpriteAsync(self.lockBtn_, nil, "partner_lock_btn", nil, )
	else
		xyd.setUISpriteAsync(self.lockBtn_, nil, "partner_unlock_btn", nil, )
	end
end

function MissionItem:onTime()
	if self.progressBar_ then
		if self.data_.start_time ~= 0 then
			local duration = xyd.getServerTime() - self.data_.start_time
			self.progressBar_.value = duration / self.missionTime_
		else
			self.progressBar_.value = 0
		end
	end
end

function MissionItem:changeBarValue(isRefresh)
	local duration = xyd.getServerTime() - self.data_.start_time

	if self.missionTime_ - duration <= 2 or self.data_.status == missionStatus.DONE then
		self.btnComplete_.gameObject:SetActive(true)
		self.btnSpeed_.gameObject:SetActive(false)
		self.btnCancel_.gameObject:SetActive(false)

		if self.countDown_ then
			self.countDown_:stopTimeCount()
		end

		self.progressBar_.value = 1
		self.progressDesc_.text = __("PUB_MISSION_COMPLETE")

		self:setProgressEffect(true)
	else
		self:setProgressEffect(false)
		self.btnComplete_.gameObject:SetActive(false)
		self.btnSpeed_.gameObject:SetActive(true)
		self.btnCancel_.gameObject:SetActive(true)

		if not isRefresh then
			local params = {
				duration = self.missionTime_ - duration,
				doOnTime = function ()
					self:onTime()
				end
			}

			if self.countDown_ then
				self.countDown_:setInfo(params)
			else
				self.countDown_ = import("app.components.CountDown").new(self.progressDesc_, params)
			end
		end

		self.progressBar_.value = duration / self.missionTime_
	end
end

function MissionItem:onClickLock(isRefresh)
	local isLock = nil

	if self.data_.status ~= 0 then
		local params = {
			alertType = xyd.AlertType.TIPS,
			message = __("PUB_LOCK_MISSION")
		}

		xyd.WindowManager.get():openWindow("alert_window", params)

		return
	end

	if self.data_.is_lock == 1 then
		isLock = 0
	else
		isLock = 1
	end

	if isRefresh == 1 then
		self.isRefresh_ = true
	end

	TavernModel:lockMission(self.data_.mission_id, isLock)
end

function MissionItem:setProgressEffect(state)
	if state then
		if not self.progressEffect_ then
			self.progressEffect_ = xyd.Spine.new(self.progressBar_.gameObject)

			self.progressEffect_:SetActive(true)
			self.progressEffect_:setInfo("dagon_jingdutiao", function ()
				self.progressEffect_:SetLocalPosition(0, 0, 0)
				self.progressEffect_:SetLocalScale(0.98, 1.01, 1)

				if self.uiPanel_ then
					self.progressEffect_:setRenderPanel(self.uiPanel_)
				end

				self.progressEffect_:setRenderTarget(self.progressDesc_:GetComponent(typeof(UIWidget)), 0)
				self.progressValue_:SetActive(false)
				self.progressEffect_:play("texiao01", -1, 1)
			end)
		else
			self.progressEffect_:SetActive(true)
			self.progressEffect_:play("texiao01", -1, 1)
		end

		self.progressDesc_.color = Color.New2(4294908671.0)
		self.progressDesc_.effectStyle = UILabel.Effect.Outline
		self.progressDesc_.effectColor = Color.New2(255)
	else
		if self.progressEffect_ then
			self.progressEffect_:SetActive(false)
		end

		self.progressValue_:SetActive(true)
	end
end

function MissionItem:useScrollAni(isRefresh)
	if self.parent_.currentSortType_ and self.parent_.currentSortType_ ~= self.star_ then
		return
	end

	if not isRefresh then
		local sp1 = self:getSequence()
		self.go_.transform.localScale = Vector3(0, 0, 1)

		sp1:Append(self.go_.transform:DOScale(Vector3(1, 1, 1), 0.5))
		sp1:SetAutoKill(true)
	end

	if tonumber(self.star_) == 7 then
		self.effect_:SetActive(true)
		self.effect_:setInfo("fx_ui_jierenwuN", function ()
			self.effect_:SetLocalPosition(0, -10, 0)
			self.effect_:SetLocalScale(1.02, 1.02, 1)

			if self.uiPanel_ then
				self.effect_:setRenderPanel(self.uiPanel_)
			end

			self.effect_:setRenderTarget(self.item_:getIconSprite(), 1)
			self.effect_:play("texiao01", 1, 0.8, function ()
				self.effect_:SetActive(false)
			end)
		end)
	else
		self.effect_:SetActive(true)
		self.effect_:setInfo("fx_ui_jierenwu", function ()
			self.effect_:SetLocalPosition(0, -10, 0)
			self.effect_:SetLocalScale(1.02, 1.02, 1.02)

			if self.uiPanel_ then
				self.effect_:setRenderPanel(self.uiPanel_)
			end

			self.effect_:setRenderTarget(self.item_:getIconSprite(), 1)
			self.effect_:play("texiao1", 1, 0.8, function ()
				self.effect_:SetActive(false)
			end)
		end)
	end
end

function MissionItem:startMissionAni()
	self.effect_:SetActive(true)
	xyd.SoundManager.get():playSound(xyd.SoundID.REFRESH)
	self.effect_:setInfo("fx_ui_saoxing", function ()
		self.effect_:SetLocalPosition(0, 0, 0)
		self.effect_:SetLocalScale(1.1, 1.1, 1)

		if self.uiPanel_ then
			self.effect_:setRenderPanel(self.uiPanel_)
		end

		self.effect_:setRenderTarget(self.lockBtn_, 0)
		self.effect_:play("texiao01", 1, 1, function ()
		end)
	end)
end

function MissionItem:onClickComplete()
	local star = xyd.tables.pubMissionTable:getStar(self.data_.table_id)

	if star >= 6 then
		local params = {
			alertType = xyd.AlertType.YES_NO,
			message = __("PUB_COMPLETE_MISSION"),
			callback = function (yes)
				if yes then
					TavernModel:completeMission(self.data_.mission_id)
				end
			end
		}

		xyd.WindowManager.get():openWindow("alert_window", params)
	else
		TavernModel:completeMission(self.data_.mission_id)
	end
end

function MissionItem:onClickCancel()
	local params = {
		alertType = xyd.AlertType.YES_NO,
		message = __("PUB_MISSION_CANCEL"),
		callback = function (yes)
			if yes then
				TavernModel:cancelMission(self.data_.mission_id)
			end
		end
	}

	xyd.WindowManager.get():openWindow("alert_window", params)
end

function MissionItem:onClickSpeed()
	local cost = xyd.tables.pubMissionTable:getSpeedupCost(self.data_.table_id)

	if tonumber(cost[2]) == 0 then
		TavernModel:speedMission(self.data_.mission_id)

		return
	end

	local function callback(yes)
		if yes then
			if tonumber(cost[1]) > 0 then
				local selfNum = backpackModel:getItemNumByID(tonumber(cost[1]))

				if tonumber(selfNum) < tonumber(cost[2]) then
					self.parent_:setTimeout(function ()
						xyd.alertTips(__("PUB_SPEED_MISSION_1"))
					end, nil, 300)

					return
				end
			end

			TavernModel:speedMission(self.data_.mission_id)
		end
	end

	xyd.alertYesNo(__("PUB_SPEED_MISSION_2", cost[2]), callback)
end

function MissionItem:chargeShowBySortType(sortType)
	if sortType and self.star_ ~= sortType then
		self.go_.gameObject:SetActive(false)
	else
		self.go_.gameObject:SetActive(true)
	end
end

function MissionItem:showItem(missionData)
	if not missionData then
		self.go_.gameObject:SetActive(false)

		if self.progressEffect_ then
			self.progressEffect_:SetActive(false)
		end

		self.progressDesc_.color = Color.New2(4294967295.0)
		self.progressDesc_.effectStyle = UILabel.Effect.Outline
		self.progressDesc_.effectColor = Color.New2(255)

		self:clearTimer()
	else
		self.go_.gameObject:SetActive(true)
	end
end

function MissionItem:getMissionId()
	if not self.data_ then
		return 0
	else
		return self.data_.mission_id or 0
	end
end

function MissionItem:clearTimer()
	if self.countDown_ then
		self.countDown_:stopTimeCount()

		self.countDown_ = nil
	end
end

function MissionItem:getGameObject()
	return self.go_
end

function TavernWindow:ctor(name, params)
	TavernWindow.super.ctor(self, name, params)

	self.currentSortType_ = nil
end

function TavernWindow:initWindow()
	TavernWindow.super.initWindow(self)
	self:updateUpIcon()

	local winTrans = self.window_.transform
	self.content_ = winTrans:ComponentByName("content", typeof(UISprite))
	self.grid_ = self.content_.transform:ComponentByName("scrollView/grid", typeof(MultiRowWrapContent))
	self.scrollView_ = self.content_.transform:ComponentByName("scrollView", typeof(UIScrollView))
	local itemPrefab = self.content_.transform:Find("tempItem").gameObject
	self.missionListWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, itemPrefab, MissionItem, self)
	self.scrollViewPanel_ = self.scrollView_:GetComponent(typeof(UIPanel))
	local bottomBtn = self.content_:NodeByName("bottomBtn").gameObject
	self.btnUse = bottomBtn:NodeByName("btnUse").gameObject
	self.btnUseLabel = self.btnUse:ComponentByName("labelDesc", typeof(UILabel))
	self.btnMissions = bottomBtn:NodeByName("btnMissions").gameObject
	self.btnMissionsLabel = self.btnMissions:ComponentByName("labelDesc", typeof(UILabel))
	self.btnComplete = bottomBtn:NodeByName("btnComplete").gameObject
	self.btnCompleteLabel = self.btnComplete:ComponentByName("labelDesc", typeof(UILabel))
	local helpBtn = self.content_.transform:ComponentByName("topPos/infoBtn", typeof(UISprite))

	UIEventListener.Get(helpBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "TAVERN_WINDOW_TIPS"
		})
	end

	self.btnUseLabel.text = __("USE")
	self.btnMissionsLabel.text = __("PUB_MISSION_AUTO_TEXT05")
	self.btnCompleteLabel.text = __("PUB_MISSION_AUTO_TEXT1")

	UIEventListener.Get(self.btnUse).onClick = function ()
		xyd.WindowManager.get():openWindow("tavern_use_scroll_window", {
			closeCallBack = function (missions)
				self:onUseScroll(missions)
			end
		})
	end

	UIEventListener.Get(self.btnMissions).onClick = function ()
		local missions = xyd.models.tavern:getMissions()
		local count = 0
		local maxCount = tonumber(xyd.tables.miscTable:getVal("pub_mission_max"))

		for _, id in pairs(missions) do
			local info = xyd.models.tavern:getMissionById(id)

			if info.status == 1 or info.status == 2 then
				count = count + 1
			end
		end

		if maxCount <= count then
			xyd.showToast(__("PUB_MISSION_LIMIT_TIPS"))
		else
			xyd.WindowManager.get():openWindow("tavern_multimission_window", {
				state = "mission",
				chooseType = self.currentSortType_
			})
		end
	end

	UIEventListener.Get(self.btnComplete).onClick = function ()
		xyd.WindowManager.get():openWindow("tavern_multimission_window", {
			state = "complete",
			chooseType = self.currentSortType_
		})
	end

	self:initTimer()
	self:initTopGroup()
	self:initChoosePart()
	self:registerEvent()
	self:playAnimation()
	TavernModel:reqPubInfo()
end

function TavernWindow:playAnimation()
	self.content_.gameObject:X(-1000)

	local q = self:getSequence()

	q:Append(self.content_.gameObject.transform:DOLocalMoveX(50, 0.5))
	q:Append(self.content_.gameObject.transform:DOLocalMoveX(0, 0.5))
	q:AppendCallback(function ()
		q:Kill(false)

		q = nil
	end)
end

function TavernWindow:updateUpIcon()
	self.isShowUp = -1

	if xyd.models.activity:isResidentReturnAddTime() then
		local return_multiple = xyd.tables.activityReturn2AddTable:getMultiple(xyd.ActivityResidentReturnAddType.WORKING)
		self.isShowUp = return_multiple
	end
end

function TavernWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.PUB_GET_LIST, handler(self, self.onPubInfo))
	self.eventProxy_:addEventListener(xyd.event.PUB_START_MISSION, handler(self, self.onStartMission))
	self.eventProxy_:addEventListener(xyd.event.PUB_LOCK_MISSION, handler(self, self.onLockMission))
	self.eventProxy_:addEventListener(xyd.event.PUB_REFRESH, handler(self, self.onRefreshInfo))
	self.eventProxy_:addEventListener(xyd.event.PUB_CANCEL_MISSION, handler(self, self.onCancelMission))
	self.eventProxy_:addEventListener(xyd.event.PUB_COMPLETE_MISSION, handler(self, self.onComplete))
	self.eventProxy_:addEventListener(xyd.event.PUB_SPEED_MISSION, handler(self, self.onComplete))
	self.eventProxy_:addEventListener(xyd.event.PUB_INFOS, handler(self, self.onStartMultiMissions))
	self.eventProxy_:addEventListener(xyd.event.BATCH_COMPLETE_PUB_MISSIONS, handler(self, self.onCompleteMultiMissions))
end

function TavernWindow:initTopGroup()
	self.resItemTop_ = {}
	local topTrans = self.window_.transform:ComponentByName("topPart", typeof(UIWidget)).transform
	local closeBtn = topTrans:ComponentByName("close_btn", typeof(UISprite))
	local itemGrid = topTrans:ComponentByName("res_item_group", typeof(UIGrid))
	local topList = {
		tonumber(PubScrollTable:getCost(1)[1]),
		tonumber(PubScrollTable:getCost(2)[1])
	}

	for _, itemID in ipairs(topList) do
		local params = {
			notSmall = true,
			tableId = tonumber(itemID)
		}
		local item = ResItem.new(itemGrid.gameObject, itemID)

		item:hidePlus()

		params.bgSize = {
			h = 36,
			w = 150
		}

		item:setInfo(params)
		item:setLeftLinePos(-75, 0, 0)
		item:setRightLinePos(85, 0, 0)
		table.insert(self.resItemTop_, item)
	end

	local params = {
		tableId = xyd.ItemID.CRYSTAL
	}
	local item = ResItem.new(topTrans:Find("item2Pos").gameObject, xyd.ItemID.CRYSTAL)

	item:setInfo(params)
	table.insert(self.resItemTop_, item)
	itemGrid:Reposition()

	UIEventListener.Get(closeBtn.gameObject).onClick = function ()
		if self.callback_ then
			self.callback_()
		else
			self:onClickCloseButton()
		end
	end

	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.refresResItems))
end

function TavernWindow:refresResItems()
	for _, item in ipairs(self.resItemTop_) do
		item:refresh()
	end
end

function TavernWindow:onPubInfo()
	self:initBottom()
	self:initContentPart()
end

function TavernWindow:initContentPart(refreshMissionList)
	self:initScrollList(refreshMissionList)
end

function TavernWindow:getUIPanel()
	return self.scrollViewPanel_
end

function TavernWindow:initScrollList(refreshMissionList, keepPosition)
	local missionIDs = TavernModel:getMissions()
	local missionInfos = {}

	for idx, missionID in ipairs(missionIDs) do
		local mission = TavernModel:getMissionById(missionID)
		local star = xyd.tables.pubMissionTable:getStar(mission.table_id)

		if not self.currentSortType_ or self.currentSortType_ == star then
			table.insert(missionInfos, mission)
		end
	end

	self.missionInfos_ = missionInfos

	self.missionListWrap_:setInfos(self.missionInfos_, {
		keepPosition = keepPosition
	})

	local items = self.missionListWrap_:getItems()

	self:waitForFrame(1, function ()
		if not refreshMissionList then
			refreshMissionList = {}
		end

		for _, missionData in ipairs(refreshMissionList) do
			for _, item in ipairs(items) do
				if missionData.mission_id == item:getMissionId() then
					item:useScrollAni(true)
				end
			end
		end
	end)
end

function TavernWindow:refreshScrollListBySortType()
	local missionIDs = TavernModel:getMissions()
	local missionInfos = {}

	for idx, missionID in ipairs(missionIDs) do
		local mission = TavernModel:getMissionById(missionID)
		local star = xyd.tables.pubMissionTable:getStar(mission.table_id)

		if not self.currentSortType_ or self.currentSortType_ == star then
			table.insert(missionInfos, mission)
		end
	end

	table.sort(missionInfos, function (a, b)
		if a.status ~= b.status then
			return a.status < b.status
		else
			local starA = xyd.tables.pubMissionTable:getStar(a.table_id)
			local starB = xyd.tables.pubMissionTable:getStar(b.table_id)

			if starA ~= starB then
				return starB < starA
			else
				return b.table_id < a.table_id
			end
		end
	end)

	self.missionInfos_ = missionInfos

	self.missionListWrap_:setInfos(self.missionInfos_, {})
end

function TavernWindow:initTimer()
	local timeDesc = self.content_.transform:ComponentByName("topPos/labelCon/labelTimeTips", typeof(UILabel))
	local labelCon_layout = self.content_.transform:ComponentByName("topPos/labelCon", typeof(UILayout))
	self.timerLabel_ = self.content_.transform:ComponentByName("topPos/labelCon/labelTimeCount", typeof(UILabel))
	timeDesc.text = __("PUB_MISSION_TIME", #TavernModel:getMissions(), xyd.tables.vipTable:getPubMissionNum(backpackModel:getVipLev()))
	local duration = TavernModel:getEndTime() - xyd.getServerTime()
	self.duration_ = duration
	self.timerLabel_.text = xyd.secondsToString(self.duration_)

	if not self.tlabelRefreshTime_ then
		self.tlabelRefreshTime_ = Timer.New(handler(self, self.onWindowTime), 1, -1, false)

		self.tlabelRefreshTime_:Start()
	end

	self.timerLabel_.gameObject:SetActive(true)
	labelCon_layout:Reposition()
end

function TavernWindow:onWindowTime()
	self.duration_ = self.duration_ - 1
	self.timerLabel_.text = xyd.secondsToString(self.duration_)

	if self.duration_ <= 0 then
		self.duration_ = 0

		self.tlabelRefreshTime_:Stop()

		self.tlabelRefreshTime_ = nil

		TavernModel:reqPubInfo()
	end
end

function TavernWindow:initChoosePart()
	self.starBgList_ = {}
	local btnContent = self.content_.transform:NodeByName("choosePart/btnContent").gameObject
	self.btnRefresh = btnContent:NodeByName("btnRefresh").gameObject

	for i = 1, 7 do
		local childGo = btnContent:NodeByName(i).gameObject
		local btnIcon = childGo:NodeByName("btnIcon").gameObject
		local chosen = childGo:NodeByName("chosen").gameObject
		local mask = childGo:NodeByName("mask").gameObject

		table.insert(self.starBgList_, {
			chosen,
			mask
		})
		chosen:SetActive(self.currentSortType_ == i)
		mask:SetActive(self.currentSortType_ == i)

		UIEventListener.Get(btnIcon).onClick = function ()
			if self.currentSortType_ == i then
				self.currentSortType_ = nil
			else
				self.currentSortType_ = i
			end

			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
			self:updateSort()
			self:refreshScrollListBySortType()
		end
	end

	UIEventListener.Get(self.btnRefresh).onClick = function ()
		local hasNum = backpackModel:getCrystal()
		local cost = self:getRefreshCost()

		if cost == 0 then
			xyd.WindowManager.get():openWindow("alert_window", {
				alertType = xyd.AlertType.TIPS,
				message = __("PUB_MISSION_REFRESH_2")
			})
		else
			local function callback()
				if tonumber(hasNum) < tonumber(cost) then
					xyd.WindowManager.get():openWindow("alert_window", {
						alertType = xyd.AlertType.TIPS,
						message = __("PUB_MISSION_REFRESH_3")
					})
				else
					TavernModel:refreshMission()
				end
			end

			local value = xyd.db.misc:getValue("tavern_refresh_time_stamp")

			if not value or not xyd.isSameDay(tonumber(value), xyd.getServerTime()) then
				local params = {
					type = "tavern_refresh",
					text = __("PUB_MISSION_REFRESH_1", cost),
					callback = callback
				}

				xyd.WindowManager.get():openWindow("gamble_tips_window", params)
			else
				callback()
			end
		end
	end
end

function TavernWindow:updateSort()
	for idx, item in ipairs(self.starBgList_) do
		item[1]:SetActive(self.currentSortType_ == idx)
		item[2]:SetActive(self.currentSortType_ == idx)
	end
end

function TavernWindow:initBottom()
end

function TavernWindow:getRefreshCost()
	local num = 0
	local oneCost = xyd.split(xyd.tables.miscTable:getVal("pub_mission_refresh_cost"), "#", true)
	local missions = TavernModel:getMissions()

	for _, missionID in ipairs(missions) do
		local mission = TavernModel:getMissionById(missionID)

		if mission.is_lock == 0 then
			num = num + 1
		end
	end

	return num * oneCost[2]
end

function TavernWindow:onStartMission(event)
	self:initTimer()
	self:initBottom()

	local missionID = event.data.mission_id
	local items = self.missionListWrap_:getItems()

	self:initScrollList(nil, true)

	for _, missionItem in ipairs(items) do
		if missionItem:getMissionId() == missionID then
			missionItem:startMissionAni()

			break
		end
	end
end

function TavernWindow:onStartMultiMissions(event)
	self:initTimer()
	self:initBottom()
	self:initScrollList(nil, true)

	local infos = event.data.pub_infos
	local items = self.missionListWrap_:getItems()

	for _, info in ipairs(infos) do
		for _, missionItem in ipairs(items) do
			if missionItem:getMissionId() == info.mission_id then
				missionItem:startMissionAni()

				break
			end
		end
	end
end

function TavernWindow:onLockMission(event)
	local missionData = TavernModel:getMissionById(event.data.mission_id)

	self:initBottom()

	local items = self.missionListWrap_:getItems()

	for _, missionItem in ipairs(items) do
		if missionItem:getMissionId() == event.data.mission_id then
			self:initScrollList(nil, true)

			break
		end
	end
end

function TavernWindow:onRefreshInfo(event)
	self:initContentPart(event.data.missions)
	self:initBottom()
end

function TavernWindow:onCancelMission(event)
	self:initScrollList(nil, true)
	self:initTimer()
	self:initBottom()
end

function TavernWindow:onComplete(event)
	local award = event.data.award

	self:initScrollList(nil, true)
	xyd.itemFloat({
		{
			item_id = tonumber(award[1]),
			item_num = tonumber(award[2])
		}
	}, nil, , 2999)
	self:initTimer()
end

function TavernWindow:onCompleteMultiMissions(event)
	local infos = event.data.pub_infos
	local awards = {}

	for _, data in ipairs(infos) do
		table.insert(awards, {
			item_id = data.award[1],
			item_num = data.award[2]
		})
	end

	xyd.models.itemFloatModel:pushNewItems(awards)
	self:initScrollList(nil, true)
	self:initTimer()
end

function TavernWindow:onUseScroll(missions)
	self:initBottom()
	self:initTimer()
	self:initScrollList(nil, false)
	self:waitForFrame(1, function ()
		local items = self.missionListWrap_:getItems()

		for _, missionID in ipairs(missions) do
			for _, missionItem in ipairs(items) do
				if missionItem:getMissionId() == missionID then
					missionItem:useScrollAni()

					break
				end
			end
		end
	end)
end

function TavernWindow:willClose()
	TavernWindow.super.willClose(self)
	self:clearItemTimer()

	if self.tlabelRefreshTime_ then
		self.tlabelRefreshTime_:Stop()

		self.tlabelRefreshTime_ = nil
	end

	xyd.models.tavern:updateRedMark()
end

function TavernWindow:clearItemTimer()
	local items = self.missionListWrap_:getItems()

	for _, item in ipairs(items) do
		item:clearTimer()
	end
end

return TavernWindow
