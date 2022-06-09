local MissionType = {
	DAILY = 1,
	WEEKLY = 2
}
local ActivityContent = import(".ActivityContent")
local ActivitySpfarmMission = class("ActivitySpfarmMission", ActivityContent)
local CommonTabBar = require("app.common.ui.CommonTabBar")
local CountDown = import("app.components.CountDown")
local ActivitySpaceExploreMissionItem = class("ActivitySpaceExploreMissionItem", import("app.components.CopyComponent"))

function ActivitySpfarmMission:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.curMissionType = MissionType.DAILY
	self.itemArr = {}
	self.isTimeWeekOver = false

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SPFARM_MISSION, false)
end

function ActivitySpfarmMission:initUI()
	ActivitySpfarmMission.super.initUI(self)
	self:createChildren()
end

function ActivitySpfarmMission:onActivityByID(event)
	local id = event.data.act_info.activity_id

	if id ~= self.id then
		return
	end

	local data = xyd.models.activity:getActivity(self.id)

	data:setData(event.data.act_info)
	self:initMissionGroup()
	self:updateNavText()
end

function ActivitySpfarmMission:getPrefabPath()
	return "Prefabs/Windows/activity/activity_space_explore_mission"
end

function ActivitySpfarmMission:createChildren()
	self:getUIComponent()
	self:initTextAndImage()
	self:initCountDownAndRound()
	self:initNav()
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityByID))
	xyd.models.activity:reqActivityByID(self.id)
end

function ActivitySpfarmMission:getUIComponent()
	local go = self.go
	self.missionItem = go:NodeByName("missionItem").gameObject
	self.bg = go:ComponentByName("bg", typeof(UISprite))
	self.allGroup = go:NodeByName("e:Group").gameObject
	self.logoImg = self.allGroup:ComponentByName("logoImg", typeof(UISprite))
	self.contentGroup = self.allGroup:NodeByName("contentGroup").gameObject
	self.nav = self.contentGroup:ComponentByName("nav", typeof(UIWidget))
	self.timeTextLabel = self.allGroup:ComponentByName("cdGroup/timeTextLabel", typeof(UILabel))
	self.timeLabel1 = self.allGroup:ComponentByName("cdGroup/timeLabel1", typeof(UILabel))
	self.task = self.contentGroup:NodeByName("task").gameObject
	self.task_UIScrollView = self.contentGroup:ComponentByName("task", typeof(UIScrollView))
	self.task_UIPanel = self.contentGroup:ComponentByName("task", typeof(UIPanel))
	self.missionGroup = self.contentGroup:NodeByName("task/missionGroup").gameObject
	self.missionGroup_UILayout = self.contentGroup:ComponentByName("task/missionGroup", typeof(UILayout))
	self.descLabel = self.allGroup:ComponentByName("descLabel", typeof(UILabel))
	self.cdGroup = self.allGroup:ComponentByName("cdGroup", typeof(UILayout))
end

function ActivitySpfarmMission:initNav()
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

function ActivitySpfarmMission:updateNavText()
	local labelText = {}
	local dailyComplete = 0
	local dailyCount = 0
	local weeklyComplete = 0
	local weeklyCount = 0
	local missionTable = xyd.tables.activitySpfarmMissionTable
	local mission = missionTable:getIds()

	for idx, id in ipairs(mission) do
		local type = missionTable:isDaily(id)
		local compNum = missionTable:getCompleteNum(id)

		if type == 1 then
			if self.activityData.detail.values[idx] and compNum <= self.activityData.detail.values[idx] then
				dailyComplete = dailyComplete + 1
			end

			dailyCount = dailyCount + 1
		elseif type == 0 then
			if self.activityData.detail.values[idx] and compNum <= self.activityData.detail.values[idx] then
				weeklyComplete = weeklyComplete + 1
			end

			weeklyCount = weeklyCount + 1
		end
	end

	local text1 = __("ACTIVITY_ICE_SECRET_MISSION_DAILY") .. "(" .. dailyComplete .. "/" .. dailyCount .. ")"
	local text2 = __("ACTIVITY_SPFARM_TEXT102") .. "(" .. weeklyComplete .. "/" .. weeklyCount .. ")"

	table.insert(labelText, text1)
	table.insert(labelText, text2)

	if self.tab then
		self.tab:setTexts(labelText)
	end
end

function ActivitySpfarmMission:updateNav(i)
	if self.curMissionType == i then
		return
	end

	self.curMissionType = i

	self:initMissionGroup()
end

function ActivitySpfarmMission:initTextAndImage()
	xyd.setUISpriteAsync(self.logoImg, nil, "activity_spfarm_mission_text_" .. tostring(xyd.Global.lang))
	xyd.setUISpriteAsync(self.bg, nil, "activity_space_explore_bg_2")

	self.descLabel.text = __("ACTIVITY_SPFARM_TEXT101")

	if xyd.Global.lang == "fr_fr" then
		self.descLabel.width = 358

		self.descLabel:X(160)
	end
end

function ActivitySpfarmMission:initCountDownAndRound()
	local startTime = self.activityData:startTime()
	local passedTotalTime = xyd.getServerTime() - startTime
	self.round = math.ceil(passedTotalTime / xyd.TimePeriod.WEEK_TIME)

	if xyd.getServerTime() < self.activityData:getEndTime() then
		local dayRound = math.ceil(passedTotalTime / xyd.TimePeriod.DAY_TIME)

		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_SPACE_EXPLORE_MISSION, function ()
			xyd.db.misc:setValue({
				key = "activity_space_explore_mission",
				value = dayRound
			})
		end)
		self.timeLabel1:SetActive(true)

		self.timeTextLabel.text = __("END")
		local duration = self.activityData:getEndTime() - xyd.getServerTime()

		CountDown.new(self.timeLabel1, {
			duration = duration
		})

		if xyd.Global.lang == "fr_fr" then
			self.timeTextLabel.transform:SetSiblingIndex(0)
		end
	end

	self.cdGroup:Reposition()
end

function ActivitySpfarmMission:timeOverDaily()
	xyd.models.activity:reqActivityByID(self.id)
	self:initCountDownAndRound()
end

function ActivitySpfarmMission:timeOverWeek()
	self.isTimeWeekOver = true
end

function ActivitySpfarmMission:initMissionGroup()
	local missionTable = xyd.tables.activitySpfarmMissionTable
	local missionTextTable = xyd.tables.activitySpfarmMissionTextTable
	local mission = missionTable:getIds()
	local paramsNow = {}

	for i = 1, #mission do
		if missionTable:isDaily(i) == 1 and self.curMissionType == MissionType.DAILY or missionTable:isDaily(i) == 0 and self.curMissionType == MissionType.WEEKLY then
			local type = missionTable:getType(i)
			local params = {
				id = i,
				desc = missionTextTable:getDescription(type, missionTable:getCompleteNum(i), missionTable:getParams(i)),
				award = missionTable:getAward(i),
				completeNum = missionTable:getCompleteNum(i),
				value = self.activityData.detail.values[i] or 0,
				act_id = self.id
			}

			table.insert(paramsNow, params)
		end
	end

	for i in pairs(paramsNow) do
		if self.itemArr[i] == nil then
			local tmp = NGUITools.AddChild(self.missionGroup.gameObject, self.missionItem.gameObject)
			local item = ActivitySpaceExploreMissionItem.new(tmp, paramsNow[i])

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

function ActivitySpaceExploreMissionItem:ctor(goItem, params)
	self.super.ctor(self, goItem)

	self.goItem_ = goItem
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

	if xyd.Global.lang == "zh_tw" or xyd.Global.lang == "ja_jp" then
		self.descLabel.overflowHeight = 30
	end

	self.descLabel.text = params.desc

	self:createChildren()
end

function ActivitySpaceExploreMissionItem:getGo()
	return self.goItem_
end

function ActivitySpaceExploreMissionItem:createChildren()
	self:initIcon()
	self:initProgress()
	self.itemLayout:Reposition()

	UIEventListener.Get(self.goItem_).onClick = handler(self, function ()
		local getWayId = xyd.tables.activitySpfarmMissionTable:getGetway(self.id)

		if getWayId > 0 then
			xyd.goWay(getWayId, nil, , function ()
				xyd.models.activity:reqActivityByID(self.act_id)
			end)
		end
	end)
end

function ActivitySpaceExploreMissionItem:initIcon()
	NGUITools.DestroyChildren(self.itemGroup.transform)

	for _, v in ipairs(self.items) do
		local icon = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			itemID = v.itemId,
			num = v.itemNum,
			uiRoot = self.itemGroup.gameObject,
			scale = Vector3(0.5925925925925926, 0.5925925925925926, 1)
		})

		if self.completeNum <= self.value then
			icon:setChoose(true)
		end
	end
end

function ActivitySpaceExploreMissionItem:initProgress()
	if self.completeNum <= self.value then
		self.value = self.completeNum

		xyd.setUISpriteAsync(self.progressImg, nil, "activity_bar_thumb_2")
	else
		xyd.setUISpriteAsync(self.progressImg, nil, "activity_bar_thumb")
	end

	self.progressBar.value = math.min(self.value, self.completeNum) / self.completeNum
	self.progressDesc.text = self.value .. " / " .. self.completeNum
end

function ActivitySpaceExploreMissionItem:updateParams(params)
	self.id = params.id
	self.descLabel.text = params.desc
	self.completeNum = params.completeNum
	self.value = params.value
	self.items = params.award

	self:createChildren()
end

return ActivitySpfarmMission
