local BaseWindow = import(".BaseWindow")
local GalaxyBattlePassWindow = class("GalaxyBattlePassWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local GalaxyBattlePassWindowItem1 = class("GalaxyBattlePassWindowItem1", import("app.common.ui.FixedWrapContentItem"))
local GalaxyBattlePassWindowItem2 = class("GalaxyBattlePassWindowItem2", import("app.common.ui.FixedWrapContentItem"))
local ItemTable = xyd.tables.itemTable
local awardTalbe = xyd.tables.galaxyTripBattlepassTable
local missionTalbe = xyd.tables.galaxyTripMissionTable
local json = require("cjson")

function GalaxyBattlePassWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.params = params
	self.id = params.activityID
end

function GalaxyBattlePassWindow:initWindow()
	if self.id == xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION then
		awardTalbe = xyd.tables.galaxyTripBattlepassTable
		missionTalbe = xyd.tables.galaxyTripMissionTable
	elseif self.id == xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION2 then
		awardTalbe = xyd.tables.galaxyTripBattlepass2Table
		missionTalbe = xyd.tables.galaxyTripMission2Table
	end

	self.activityData = xyd.models.activity:getActivity(self.id)

	if not self.activityData then
		xyd.closeWindow(self.name_)
	end

	self.effectList = {}
	self.curTabIndex = 1

	self:getUIComponent()
	GalaxyBattlePassWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function GalaxyBattlePassWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.groupAction = groupAction
	self.textImg_ = self.groupAction:ComponentByName("textImg_", typeof(UISprite))
	self.buyBtn = self.groupAction:NodeByName("buyBtn").gameObject
	self.labelBuy = self.buyBtn:ComponentByName("labelBuy", typeof(UILabel))
	self.timeGroup = self.groupAction:NodeByName("timeGroup").gameObject
	self.timeGroupLayout = self.groupAction:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel_ = self.timeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.nav = self.groupAction:NodeByName("nav").gameObject
	self.btnTab1 = self.nav:NodeByName("btnAwardTab").gameObject
	self.labelTab1 = self.btnTab1:ComponentByName("labelAward", typeof(UILabel))
	self.btnTab2 = self.nav:NodeByName("btnTaskTab").gameObject
	self.labelTab2 = self.btnTab2:ComponentByName("labelTask", typeof(UILabel))
	self.content = self.groupAction:NodeByName("content").gameObject
	self.content1Group = self.content:NodeByName("content1Group").gameObject
	self.awardContentGroup = self.content1Group:NodeByName("awardContentGroup").gameObject
	self.scrollerAward = self.awardContentGroup:NodeByName("scroller").gameObject
	self.scrollViewAward = self.awardContentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.progressBar = self.scrollerAward:ComponentByName("progressBar", typeof(UIProgressBar))
	self.itemGroupAward = self.scrollerAward:NodeByName("itemGroup").gameObject
	self.item1 = self.scrollerAward:NodeByName("item1").gameObject
	self.labelTitle1 = self.awardContentGroup:ComponentByName("labelTitle1", typeof(UILabel))
	self.totalEnergyNum = self.awardContentGroup:ComponentByName("totalEnergyNum", typeof(UILabel))
	self.labelTitle2 = self.awardContentGroup:ComponentByName("labelTitle2", typeof(UILabel))
	self.content2Group = self.content:NodeByName("content2Group").gameObject
	self.taskContentGroup = self.content2Group:NodeByName("taskContentGroup").gameObject
	self.scrollerTask = self.taskContentGroup:NodeByName("scroller").gameObject
	self.scrollViewTask = self.taskContentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroupTask = self.scrollerTask:NodeByName("itemGroup").gameObject
	self.item2 = self.scrollerTask:NodeByName("item2").gameObject
end

function GalaxyBattlePassWindow:initUIComponent()
	xyd.setUISpriteAsync(self.textImg_, nil, "activity_galaxy_trip_mission_logo_" .. xyd.Global.lang)

	self.labelTitle1.text = __("GALAXY_TRIP_TEXT49")
	self.labelTitle2.text = __("GALAXY_TRIP_TEXT50")
	self.labelBuy.text = __("GALAXY_TRIP_TEXT51")
	self.labelTab1.text = __("GALAXY_TRIP_TEXT47")
	self.labelTab2.text = __("GALAXY_TRIP_TEXT48")
	self.countdown = import("app.components.CountDown").new(self.timeLabel_)

	self.countdown:setCountDownTime(self.activityData:getEndTime() - xyd.getServerTime())

	self.endLabel_.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)
	end

	self.timeGroupLayout:Reposition()
	self:onClickTab(self.curTabIndex)
end

function GalaxyBattlePassWindow:register()
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, function (self, event)
		local activity_id = event.data.activity_id

		if activity_id ~= xyd.ActivityID.ENTRANCE_TEST then
			return
		end

		self:initData()
	end))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data

		if data.activity_id ~= self.id then
			return
		end

		self:onGetAward(event)
	end)
	self.eventProxy_:addEventListener(xyd.event.GALAXY_TRIP_GET_MISSIONS_INFO, function (event)
		self.haveReqTask = true

		self:initData()
	end)
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, function ()
		self.activityData:setHaveBuyGiftbag()
		self:initData()
	end)

	UIEventListener.Get(self.buyBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("galaxy_battle_pass_preview_window", {
			activityID = self.id
		})
	end

	UIEventListener.Get(self.btnTab1).onClick = handler(self, function ()
		if self.curTabIndex and self.curTabIndex == 1 then
			return
		else
			self:onClickTab(1)
		end
	end)
	UIEventListener.Get(self.btnTab2).onClick = handler(self, function ()
		if self.curTabIndex and self.curTabIndex == 2 then
			return
		else
			self:onClickTab(2)
		end
	end)
end

function GalaxyBattlePassWindow:onClickTab(index)
	self.curTabIndex = xyd.checkCondition(index == 1, 2, 1)

	self["content" .. self.curTabIndex .. "Group"]:SetActive(false)

	local imgNameArr = {
		"activity_galaxy_trip_mission_bg_jf_zc",
		"activity_galaxy_trip_mission_bg_rw_zc"
	}

	xyd.setUISpriteAsync(self["btnTab" .. self.curTabIndex]:ComponentByName("img", typeof(UISprite)), nil, imgNameArr[self.curTabIndex])
	xyd.setUISpriteAsync(self["btnTab" .. self.curTabIndex]:ComponentByName("bg", typeof(UISprite)), nil, "activity_galaxy_trip_mission_btn_txz_zc")

	self["labelTab" .. self.curTabIndex].color = Color.New2(2846672383.0)
	self["labelTab" .. self.curTabIndex].effectColor = Color.New2(471871999)
	self.curTabIndex = index

	self["content" .. self.curTabIndex .. "Group"]:SetActive(true)

	local imgNameArr = {
		"activity_galaxy_trip_mission_bg_jf_xz",
		"activity_galaxy_trip_mission_bg_rw_xz"
	}

	xyd.setUISpriteAsync(self["btnTab" .. self.curTabIndex]:ComponentByName("img", typeof(UISprite)), nil, imgNameArr[self.curTabIndex])
	xyd.setUISpriteAsync(self["btnTab" .. self.curTabIndex]:ComponentByName("bg", typeof(UISprite)), nil, "activity_galaxy_trip_mission_btn_txz_xz")

	self["labelTab" .. self.curTabIndex].color = Color.New2(4294967295.0)
	self["labelTab" .. self.curTabIndex].effectColor = Color.New2(563797503)

	self:initData()
end

function GalaxyBattlePassWindow:initData()
	if not self.haveReqTask and self.activityData:checkNeedReqTaskInfo() then
		return
	end

	self.curSeason = self.activityData:getCurSeason()
	self.data2 = {}
	local ids = missionTalbe:getIDsBySeason(self.curSeason)

	for i = 1, #ids do
		local id = tonumber(ids[i])

		table.insert(self.data2, {
			id = tonumber(id),
			needCompleteValue = missionTalbe:getComplete(id),
			completeValue = self.activityData:getTaskCompleteValue(id),
			desc = missionTalbe:getDesc(id),
			isCompleted = self.activityData:getTaskAwarded(id),
			energyValue = missionTalbe:getExplorePoints(id),
			isAwarded = self.activityData:getTaskAwarded(id)
		})
	end

	dump(self.data2)

	local function sort_func(a, b)
		if a.isAwarded ~= b.isAwarded then
			return b.isAwarded
		elseif a.isCompleted ~= b.isCompleted then
			return a.isCompleted
		else
			return a.id < b.id
		end
	end

	table.sort(self.data2, sort_func)

	if self.wrapContent2 == nil then
		local wrapContent = self.itemGroupTask:GetComponent(typeof(UIWrapContent))
		self.wrapContent2 = FixedWrapContent.new(self.scrollViewTask, wrapContent, self.item2, GalaxyBattlePassWindowItem2, self)
	end

	self.wrapContent2:setInfos(self.data2, {})

	self.data1 = {}
	local ids = awardTalbe:getIDs(self.activityData:getCurSeason())
	local maxEnergy = 0

	for i = 1, #ids do
		local id = tonumber(ids[i])

		if maxEnergy < awardTalbe:getPointLimit(id) then
			maxEnergy = awardTalbe:getPointLimit(id)
		end

		table.insert(self.data1, {
			id = tonumber(id),
			freeAwarded = self.activityData:getFreeAwardAwarded(id),
			paidAwarded = self.activityData:getPaidAwardAwarded(id),
			isCompleted = awardTalbe:getPointLimit(id) <= self.activityData:getTotalEnergy(),
			needEnergy = awardTalbe:getPointLimit(id)
		})
	end

	local function sort_func(a, b)
		return a.id < b.id
	end

	table.sort(self.data1, sort_func)

	if self.wrapContent1 == nil then
		local wrapContent = self.itemGroupAward:GetComponent(typeof(UIWrapContent))
		self.wrapContent1 = FixedWrapContent.new(self.scrollViewAward, wrapContent, self.item1, GalaxyBattlePassWindowItem1, self)
	end

	self.wrapContent1:setInfos(self.data1, {})

	self.totalEnergyNum.text = self.activityData:getTotalEnergy()
	local ids = awardTalbe:getIDs(self.activityData:getCurSeason())
	local totalEnergy = self.activityData:getTotalEnergy()
	local baseProgrssValue = 0
	local value = 0

	for i = 1, #ids do
		local id = i
		local needEnergy = awardTalbe:getPointLimit(id)

		if i == 1 then
			if totalEnergy < needEnergy then
				value = baseProgrssValue * totalEnergy / needEnergy
			elseif needEnergy <= totalEnergy then
				value = baseProgrssValue
			end
		elseif totalEnergy < needEnergy then
			if awardTalbe:getPointLimit(id - 1) < totalEnergy then
				value = value + (totalEnergy - awardTalbe:getPointLimit(id - 1)) / (needEnergy - awardTalbe:getPointLimit(id - 1)) * (1 - baseProgrssValue) / (#ids - 1)
			end
		elseif needEnergy <= totalEnergy then
			value = value + (1 - baseProgrssValue) / (#ids - 1)
		end
	end

	self.progressBar:ComponentByName("", typeof(UIProgressBar)).value = math.min(value, 1)

	self:initListPositon()

	if self.activityData:IfBuyGiftBag() then
		xyd.applyGrey(self.buyBtn:GetComponent(typeof(UISprite)))
		self.labelBuy:ApplyGrey()
		xyd.setTouchEnable(self.buyBtn, false)
	end

	self:checkRedPoint()

	local ids = awardTalbe:getIDs(self.activityData:getCurSeason())
	self.progressBar:ComponentByName("", typeof(UISprite)).height = 98 * (#ids - 1)
	self.progressBar:ComponentByName("progress", typeof(UISprite)).height = 98 * (#ids - 1) - 10
end

function GalaxyBattlePassWindow:initListPositon()
	self:waitForFrame(5, function ()
		local moveIndex = 1
		local index = 1
		local flag = false
		local ids = awardTalbe:getIDs(self.activityData:getCurSeason())

		for i = #ids, 1, -1 do
			local id = i

			if awardTalbe:getPointLimit(id) <= self.activityData:getTotalEnergy() and (not self.activityData:getFreeAwardAwarded(id) or not self.activityData:getPaidAwardAwarded(id) and self.activityData:IfBuyGiftBag() == true) then
				moveIndex = id
				flag = true
			end
		end

		if flag == false then
			for i = #ids, 1, -1 do
				local id = i

				if self.activityData:getTotalEnergy() < awardTalbe:getPointLimit(id) then
					moveIndex = id
				end
			end
		end

		local sp = self.scrollViewAward.gameObject:GetComponent(typeof(SpringPanel))
		local initPos = self.scrollViewAward.transform.localPosition.y
		moveIndex = math.min(moveIndex, #ids - 1)
		local dis = initPos + (moveIndex - 1) * 100

		sp.Begin(sp.gameObject, Vector3(0, dis, 0), 8)
	end)
end

function GalaxyBattlePassWindow:updateContent()
end

function GalaxyBattlePassWindow:checkRedPoint()
	self.btnTab1:NodeByName("redPoint").gameObject:SetActive(self.activityData:checkRedMaskOfAward())
	self.btnTab2:NodeByName("redPoint").gameObject:SetActive(self.activityData:checkRedMaskOfTask())
end

function GalaxyBattlePassWindow:onGetAward(event)
	local data = event.data
	local floatItems = {}
	local skins = {}
	local detailsObj = json.decode(data.detail)

	if not detailsObj then
		return
	end

	for _, item_ in ipairs(detailsObj.batch_result) do
		floatItems = xyd.tableConcat(floatItems, item_.items)

		for _, item in ipairs(item_.items) do
			if xyd.tables.itemTable:getType(item.item_id) == xyd.ItemType.SKIN then
				table.insert(skins, item.item_id)
			end
		end
	end

	if #skins > 0 then
		xyd.onGetNewPartnersOrSkins({
			destory_res = false,
			skins = skins,
			callback = function ()
				xyd.models.itemFloatModel:pushNewItems(floatItems)
			end
		})
	else
		xyd.models.itemFloatModel:pushNewItems(floatItems)
	end

	self:initData()
end

function GalaxyBattlePassWindow:GetAward()
	self.activityData = xyd.models.activity:getActivity(self.id)
	local param = {
		batches = {}
	}
	local ids = awardTalbe:getIDs(self.activityData:getCurSeason())

	for i = 1, #ids do
		local id = tonumber(ids[i])

		if awardTalbe:getPointLimit(id) <= self.activityData:getTotalEnergy() then
			if not self.activityData:getFreeAwardAwarded(id) then
				table.insert(param.batches, {
					index = 1,
					id = id
				})
			end

			if not self.activityData:getPaidAwardAwarded(id) and self.activityData:IfBuyGiftBag() == true then
				table.insert(param.batches, {
					index = 2,
					id = id
				})
			end
		end
	end

	local param2 = require("cjson").encode(param)
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = self.id
	msg.params = param2

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function GalaxyBattlePassWindow:onGetTask(event)
end

function GalaxyBattlePassWindow:GetTask()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	local msg = messages_pb:warmup_get_award_req()
	local ids = missionTalbe:getIDsBySeason(self.curSeason)

	for i = 1, #ids do
		local id = tonumber(ids[i])

		if missionTalbe:getComplete(id) <= self.activityData:getTaskCompleteValue(id) and not self.activityData:getTaskAwarded(id) then
			table.insert(msg.table_ids, id)
		end
	end

	msg.activity_id = self.id

	xyd.Backend.get():request(xyd.mid.WARMUP_GET_AWARD, msg)
end

function GalaxyBattlePassWindow:willClose()
	BaseWindow.willClose(self)
end

function GalaxyBattlePassWindowItem1:ctor(go, parent)
	GalaxyBattlePassWindowItem1.super.ctor(self, go, parent)

	self.freeIcons = {}
	self.paidIcons = {}
end

function GalaxyBattlePassWindowItem1:initUI()
	local go = self.go
	self.energyGroup = self.go:ComponentByName("energyGroup", typeof(UISprite))
	self.energyNum = self.energyGroup:ComponentByName("energyNum", typeof(UILabel))
	self.freeAwardItemGroup = self.go:NodeByName("freeAwardItemGroup").gameObject
	self.freeAwardItemGroupLayout = self.go:ComponentByName("freeAwardItemGroup", typeof(UILayout))
	self.freeAwardClickArea = self.go:NodeByName("freeAwardClickArea").gameObject
	self.paidAwardItemGroup = self.go:NodeByName("paidAwardItemGroup").gameObject
	self.paidAwardItemGroupLayout = self.go:ComponentByName("paidAwardItemGroup", typeof(UILayout))
	self.paidAwardClickArea = self.go:NodeByName("paidAwardClickArea").gameObject

	self.go:SetActive(true)
end

function GalaxyBattlePassWindowItem1:updateInfo()
	self.id = self.data.id
	self.isCompleted = self.data.isCompleted
	self.freeAwarded = self.data.freeAwarded
	self.paidAwarded = self.data.paidAwarded
	self.needEnergy = self.data.needEnergy
	self.energyNum.text = self.needEnergy

	if self.isCompleted then
		xyd.setUISpriteAsync(self.energyGroup, nil, "activity_galaxy_trip_mission_bg_jf_2")
	else
		xyd.setUISpriteAsync(self.energyGroup, nil, "activity_galaxy_trip_mission_bg_jf_3")
	end

	self.freeAwards = awardTalbe:getFreeAwards(self.id)

	for i = 1, #self.freeIcons do
		self.freeIcons[i]:SetActive(false)
	end

	for i = 1, #self.freeAwards do
		local data = self.freeAwards[i]
		local params = {
			show_has_num = true,
			hideText = false,
			scale = 0.6296296296296297,
			uiRoot = self.freeAwardItemGroup,
			itemID = data[1],
			num = data[2],
			dragScrollView = self.parent.scrollViewAward
		}

		if self.isCompleted == true and self.freeAwarded == false then
			params.effect = "bp_available"
		end

		if not self.freeIcons[i] then
			self.freeIcons[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.freeIcons[i]:setInfo(params)
			self.freeIcons[i]:setEffect(self.isCompleted == true and self.freeAwarded == false, params.effect)
		end

		self.freeIcons[i]:SetActive(true)

		local icon = self.freeIcons[i]

		if self.freeAwarded then
			icon:setMask(false)
			icon:setLock(false)
			icon:setChoose(true)
		else
			if self.isCompleted == false then
				icon:setLock(false)
				icon:setChoose(false)
				icon:setMask(true)
			end

			if self.isCompleted == true then
				icon:setMask(false)
				icon:setLock(false)
				icon:setChoose(false)
			end
		end
	end

	self.freeAwardItemGroupLayout:Reposition()

	self.paidAwards = awardTalbe:getPayAwards(self.id)

	for i = 1, #self.paidIcons do
		self.paidIcons[i]:SetActive(false)
	end

	for i = 1, #self.paidAwards do
		local data = self.paidAwards[i]
		local params = {
			show_has_num = true,
			hideText = false,
			scale = 0.6296296296296297,
			uiRoot = self.paidAwardItemGroup,
			itemID = data[1],
			num = data[2],
			dragScrollView = self.parent.scrollViewAward
		}

		if self.isCompleted == true and self.parent.activityData:IfBuyGiftBag() and self.paidAwarded == false then
			params.effect = "bp_available"
		end

		if not self.paidIcons[i] then
			self.paidIcons[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.paidIcons[i]:setInfo(params)
			self.paidIcons[i]:setEffect(self.isCompleted == true and self.parent.activityData:IfBuyGiftBag() and self.paidAwarded == false, params.effect)
		end

		self.paidIcons[i]:SetActive(true)

		local icon = self.paidIcons[i]

		if not self.parent.activityData:IfBuyGiftBag() then
			icon:setMask(false)
			icon:setChoose(false)
			icon:setLock(true)
		elseif self.paidAwarded then
			icon:setMask(false)
			icon:setLock(false)
			icon:setChoose(true)
		elseif not self.parent.activityData:IfBuyGiftBag() or self.isCompleted == false then
			icon:setLock(false)
			icon:setChoose(false)
			icon:setMask(true)
		else
			icon:setMask(false)
			icon:setLock(false)
			icon:setChoose(false)
		end
	end

	self.paidAwardItemGroupLayout:Reposition()

	if not self.freeAwarded and self.isCompleted == true then
		self.freeAwardClickArea:SetActive(true)

		UIEventListener.Get(self.freeAwardClickArea).onClick = function ()
			if not self.freeAwarded and self.isCompleted == true then
				self:onTouchAward()
			end
		end
	else
		self.freeAwardClickArea:SetActive(false)
	end

	if not self.paidAwarded and self.parent.activityData:IfBuyGiftBag() == true and self.isCompleted == true then
		self.paidAwardClickArea:SetActive(true)

		UIEventListener.Get(self.paidAwardClickArea).onClick = function ()
			if not self.paidAwarded and self.parent.activityData:IfBuyGiftBag() == true and self.isCompleted == true then
				self:onTouchAward()
				self.paidAwardClickArea:SetActive(false)
			end
		end
	else
		self.paidAwardClickArea:SetActive(false)
	end
end

function GalaxyBattlePassWindowItem1:onTouchAward()
	self.parent:GetAward()
end

function GalaxyBattlePassWindowItem2:ctor(go, parent)
	GalaxyBattlePassWindowItem2.super.ctor(self, go, parent)

	self.parent = parent
end

function GalaxyBattlePassWindowItem2:initUI()
	local go = self.go
	self.bg_ = self.go:ComponentByName("bg_", typeof(UISprite))
	self.taskDesclabel = self.go:ComponentByName("taskDesclabel", typeof(UILabel))
	self.labelNeedPoint = self.go:ComponentByName("labelNeedPoint", typeof(UILabel))
	self.img = self.go:ComponentByName("img", typeof(UISprite))
	self.labelProgress = self.go:ComponentByName("labelProgress", typeof(UILabel))
	self.awardedGroup = self.go:NodeByName("awardedGroup").gameObject
	self.awardMask = self.go:NodeByName("awardMask").gameObject

	self.go:SetActive(true)
end

function GalaxyBattlePassWindowItem2:updateInfo()
	self.id = self.data.id
	self.needCompleteValue = self.data.needCompleteValue
	self.completeValue = self.data.completeValue
	self.desc = self.data.desc
	self.energyValue = self.data.energyValue
	self.isCompleted = self.data.isCompleted
	self.isAwarded = self.data.isAwarded
	self.taskDesclabel.text = xyd.stringFormat(self.desc, self.needCompleteValue)
	self.labelProgress.text = math.min(self.completeValue, self.needCompleteValue) .. "/" .. self.needCompleteValue
	self.labelNeedPoint.text = self.energyValue

	self.awardedGroup.gameObject:SetActive(self.isAwarded)

	if not self.isAwarded and self.isCompleted then
		self.awardMask:SetActive(true)

		UIEventListener.Get(self.awardMask).onClick = function ()
			self:onTouchTask()
			self.awardMask:SetActive(false)
		end
	else
		self.awardMask:SetActive(false)
	end
end

function GalaxyBattlePassWindowItem2:onTouchTask()
	self.parent:GetTask()
end

return GalaxyBattlePassWindow
