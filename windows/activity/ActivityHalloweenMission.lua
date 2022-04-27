local MissionType = {
	DAILY = 1,
	WEEKLY = 2
}
local ActivityContent = import(".ActivityContent")
local ActivityHalloweenMission = class("ActivityHalloweenMission", ActivityContent)
local CommonTabBar = require("app.common.ui.CommonTabBar")
local CountDown = import("app.components.CountDown")
local ActivityHalloweenMissionItem = class("ActivityHalloweenMissionItem", import("app.components.CopyComponent"))

function ActivityHalloweenMission:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.curMissionType = MissionType.DAILY
	self.itemArr = {}
	self.isTimeWeekOver = false
end

function ActivityHalloweenMission:initUI()
	ActivityHalloweenMission.super.initUI(self)
	self:createChildren()
end

function ActivityHalloweenMission:onActivityByID(event)
	local id = event.data.act_info.activity_id

	if id ~= self.id then
		return
	end

	local data = xyd.models.activity:getActivity(self.id)

	data:setData(event.data.act_info)
	self:initMissionGroup()
	self:updateNavText()
end

function ActivityHalloweenMission:getPrefabPath()
	return "Prefabs/Windows/activity/activity_halloween_mission"
end

function ActivityHalloweenMission:createChildren()
	self:getUIComponent()
	self:initTextAndImage()
	self:initResItem()
	self:initCountDownAndRound()
	self:initNav()
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityByID))
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.GHOST_POTION)
	end)
	xyd.models.activity:reqActivityByID(self.id)
end

function ActivityHalloweenMission:getUIComponent()
	local go = self.go
	self.missionItem = go:NodeByName("missionItem").gameObject
	self.bg = go:ComponentByName("bg", typeof(UISprite))
	self.logoImg = go:ComponentByName("logoImg", typeof(UISprite))
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.nav = self.contentGroup:ComponentByName("nav", typeof(UIWidget))
	self.timeTextLabel = go:ComponentByName("cdGroup/timeTextLabel", typeof(UILabel))
	self.timeLabel1 = go:ComponentByName("cdGroup/timeLabel1", typeof(UILabel))
	self.task = self.contentGroup:NodeByName("task").gameObject
	self.task_UIScrollView = self.contentGroup:ComponentByName("task", typeof(UIScrollView))
	self.task_UIPanel = self.contentGroup:ComponentByName("task", typeof(UIPanel))
	self.missionGroup = self.contentGroup:NodeByName("task/missionGroup").gameObject
	self.missionGroup_UILayout = self.contentGroup:ComponentByName("task/missionGroup", typeof(UILayout))
	self.descLabel = go:ComponentByName("descLabel", typeof(UILabel))
	self.cdGroup = go:ComponentByName("cdGroup", typeof(UILayout))
	self.resItem = go:NodeByName("resItem").gameObject
	self.resNum = self.resItem:ComponentByName("num", typeof(UILabel))
	self.resBtn = self.resItem:NodeByName("btn").gameObject
end

function ActivityHalloweenMission:initNav()
	local index = 2
	local labelStates = {
		chosen = {
			color = Color.New2(4294967295.0),
			effectColor = Color.New2(1012112383)
		},
		unchosen = {
			color = Color.New2(960513791),
			effectColor = Color.New2(4294967295.0)
		}
	}
	self.tab = CommonTabBar.new(self.nav.gameObject, index, function (index)
		self:updateNav(index)
	end, nil, labelStates)

	self:updateNavText()
end

function ActivityHalloweenMission:updateNavText()
	local labelText = {}
	local dailyComplete = 0
	local dailyCount = 0
	local weeklyComplete = 0
	local weeklyCount = 0

	for id, v in ipairs(self.activityData.detail.is_completeds) do
		local missionTable = xyd.tables.activityHalloweenMissionTable
		local type = missionTable:getType(id)

		if type == MissionType.DAILY - 1 then
			if v == 1 then
				dailyComplete = dailyComplete + 1
			end

			dailyCount = dailyCount + 1
		elseif type == MissionType.WEEKLY - 1 then
			if v == 1 then
				weeklyComplete = weeklyComplete + 1
			end

			weeklyCount = weeklyCount + 1
		end
	end

	local text1 = __("ACTIVITY_ICE_SECRET_MISSION_DAILY") .. "(" .. dailyComplete .. "/" .. dailyCount .. ")"
	local text2 = __("ACTIVITY_ICE_SECRET_MISSION_WEEKLY") .. "(" .. weeklyComplete .. "/" .. weeklyCount .. ")"

	table.insert(labelText, text1)
	table.insert(labelText, text2)

	if self.tab then
		self.tab:setTexts(labelText)
	end
end

function ActivityHalloweenMission:updateNav(i)
	if self.curMissionType == i then
		return
	end

	self.curMissionType = i

	self:initMissionGroup()
end

function ActivityHalloweenMission:initTextAndImage()
	xyd.setUISpriteAsync(self.logoImg, nil, "activity_halloween_mission_text_" .. tostring(xyd.Global.lang))

	self.descLabel.text = __("ACTIVITY_TRICKORTREAT_TASK01")

	if xyd.Global.lang == "fr_fr" then
		self.descLabel.width = 358

		self.descLabel:X(160)
	end
end

function ActivityHalloweenMission:initResItem()
	self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.GHOST_POTION)

	UIEventListener.Get(self.resBtn).onClick = function ()
		xyd.closeWindow("activity_window")
		xyd.openWindow("activity_window", {
			activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_HALLOWEEN),
			select = xyd.ActivityID.ACTIVITY_HALLOWEEN
		})
	end
end

function ActivityHalloweenMission:initCountDownAndRound()
	local startTime = self.activityData:startTime()
	local passedTotalTime = xyd.getServerTime() - startTime
	self.round = math.ceil(passedTotalTime / xyd.TimePeriod.WEEK_TIME)

	if xyd.getServerTime() < self.activityData:getEndTime() then
		local dayRound = math.ceil(passedTotalTime / xyd.TimePeriod.DAY_TIME)

		self.timeLabel1:SetActive(true)

		self.timeTextLabel.text = __("END")
		local duration = self.activityData:getEndTime() - xyd.getServerTime()

		CountDown.new(self.timeLabel1, {
			duration = duration
		})
	end

	self.cdGroup:Reposition()
end

function ActivityHalloweenMission:timeOverDaily()
	xyd.models.activity:reqActivityByID(self.id)
	self:initCountDownAndRound()
end

function ActivityHalloweenMission:timeOverWeek()
	self.isTimeWeekOver = true
end

function ActivityHalloweenMission:initMissionGroup()
	local missionTable = xyd.tables.activityHalloweenMissionTable
	local missionTextTable = xyd.tables.activityHalloweenMissionTextTable
	local mission = missionTable:getIds()
	local paramsNow = {}

	for i = 1, #mission do
		if missionTable:getType(i) == self.curMissionType - 1 then
			local params = {
				id = i,
				desc = missionTextTable:getDescription(i),
				award = missionTable:getAward(i),
				completeNum = missionTable:getCompleteNum(i),
				value = self.activityData.detail.values[i],
				act_id = self.id
			}

			table.insert(paramsNow, params)
		end
	end

	for i in pairs(paramsNow) do
		if self.itemArr[i] == nil then
			local tmp = NGUITools.AddChild(self.missionGroup.gameObject, self.missionItem.gameObject)
			local item = ActivityHalloweenMissionItem.new(tmp, self, paramsNow[i])

			xyd.setDragScrollView(item.goItem_, self.task_UIScrollView)
			table.insert(self.itemArr, item)
		else
			self.itemArr[i]:getGo():SetActive(true)
			self.itemArr[i]:updateParams(paramsNow[i])
		end
	end

	if #self.itemArr > #paramsNow then
		for i = #paramsNow + 1, #self.itemArr do
			self.itemArr[i]:getGo():SetActive(false)
		end
	end

	self.missionGroup_UILayout:Reposition()
	self.task_UIScrollView:ResetPosition()
	xyd.changeScrollViewMove(self.task, true)
end

function ActivityHalloweenMissionItem:ctor(goItem, parent, params)
	self.super.ctor(self, goItem)

	self.goItem_ = goItem
	self.parent = parent
	local transGo = goItem.transform
	self.id = params.id
	self.act_id = params.act_id
	self.completeNum = params.completeNum
	self.value = params.value
	self.items = params.award
	self.descLabel = transGo:ComponentByName("descLabel", typeof(UILabel))
	self.progressBar = transGo:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressImg = transGo:ComponentByName("progressBar/progressImg", typeof(UISprite))
	self.progressDesc = transGo:ComponentByName("progressBar/progressLabel", typeof(UILabel))
	self.itemGroup = transGo:NodeByName("itemGroup").gameObject
	self.itemLayout = self.itemGroup:GetComponent(typeof(UILayout))
	self.descLabel.text = params.desc

	self:createChildren()
end

function ActivityHalloweenMissionItem:getGo()
	return self.goItem_
end

function ActivityHalloweenMissionItem:createChildren()
	self:initIcon()
	self:initProgress()
	self.itemLayout:Reposition()

	UIEventListener.Get(self.goItem_).onClick = handler(self, function ()
		local getWayId = xyd.tables.activityHalloweenMissionTable:getGetway(self.id)

		if getWayId > 0 then
			xyd.goWay(getWayId, nil, , function ()
				xyd.models.activity:reqActivityByID(self.act_id)
			end)
		end
	end)
end

function ActivityHalloweenMissionItem:initIcon()
	NGUITools.DestroyChildren(self.itemGroup.transform)

	for _, v in ipairs(self.items) do
		local icon = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			itemID = v.itemId,
			num = v.itemNum,
			uiRoot = self.itemGroup.gameObject,
			scale = Vector3(0.6296296296296297, 0.6296296296296297, 1),
			dragScrollView = self.parent.task_UIScrollView
		})

		if self.completeNum <= self.value then
			icon:setChoose(true)
		end
	end
end

function ActivityHalloweenMissionItem:initProgress()
	if self.completeNum <= self.value then
		self.value = self.completeNum

		xyd.setUISpriteAsync(self.progressImg, nil, "activity_bar_thumb_2")
	else
		xyd.setUISpriteAsync(self.progressImg, nil, "activity_bar_thumb")
	end

	self.progressBar.value = math.min(self.value, self.completeNum) / self.completeNum
	self.progressDesc.text = self.value .. " / " .. self.completeNum
end

function ActivityHalloweenMissionItem:updateParams(params)
	self.id = params.id
	self.descLabel.text = params.desc
	self.completeNum = params.completeNum
	self.value = params.value
	self.items = params.award

	self:createChildren()
end

return ActivityHalloweenMission
