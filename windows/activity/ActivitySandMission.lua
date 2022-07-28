local ActivityContent = import(".ActivityContent")
local ActivitySandMission = class("ActivitySandMission", ActivityContent)
local CommonTabBar = require("app.common.ui.CommonTabBar")
local CountDown = import("app.components.CountDown")
local ActivitySandMissionItem = class("ActivitySandMissionItem", import("app.components.CopyComponent"))

function ActivitySandMission:ctor(parentGO, params)
	self.itemArr = {}
	self.curToggleType = xyd.ActivitySandMissionEnum.TOGGLE_TYPE.DAILY
	self.isTimeWeekOver = false

	ActivityContent.ctor(self, parentGO, params)
	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SAND_MISSION, false)
end

function ActivitySandMission:initUI()
	ActivitySandMission.super.initUI(self)
	self:createChildren()
	self:register()
end

local DUMMY_GIFTBAG_STATUS = xyd.ActivitySandMissionEnum.GIFTBAG_STATUS.TO_BUY

function ActivitySandMission:register()
	UIEventListener.Get(self.giftBagBtn.gameObject).onClick = function ()
		if self:getGiftBagBtnStatus() == xyd.ActivitySandMissionEnum.GIFTBAG_STATUS.TO_BUY then
			if xyd.ActivitySandMissionEnum.TEST_FLAG_BAG_STATUS_SOURCE_OFFLINE then
				DUMMY_GIFTBAG_STATUS = xyd.ActivitySandMissionEnum.GIFTBAG_STATUS.HAS_BOUGHT
			end

			xyd.goToActivityWindowAgain({
				activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_SAND_GIFTBAG),
				select = xyd.ActivityID.ACTIVITY_SAND_GIFTBAG
			})
		end
	end
end

function ActivitySandMission:onActivityByID(event)
	local id = event.data.act_info.activity_id

	if id ~= self.id then
		return
	end

	local data = xyd.models.activity:getActivity(self.id)

	data:setData(event.data.act_info)

	if DUMMY_GIFTBAG_STATUS == xyd.ActivitySandMissionEnum.GIFTBAG_STATUS.HAS_BOUGHT then
		xyd.models.activity:getActivity(self.id):turnToDummy()
	end

	self:initMissionGroup()
	self:updateNavText()
end

function ActivitySandMission:getCurToggleType()
	return self.curToggleType
end

function ActivitySandMission:getActivityData()
	return self.activityData
end

function ActivitySandMission:getGiftBagBtnStatus()
	if xyd.ActivitySandMissionEnum.TEST_FLAG_BAG_STATUS_SOURCE_OFFLINE then
		return DUMMY_GIFTBAG_STATUS
	else
		local targetGiftBagID = tonumber(xyd.tables.miscTable:getVal("activity_sand_gift"))
		local charges = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SAND_GIFTBAG).detail.charges

		for i = 1, #charges do
			local chargeInfo = charges[i]
			local giftBagID = chargeInfo.table_id

			if giftBagID == targetGiftBagID then
				if chargeInfo.buy_times > 0 then
					return xyd.ActivitySandMissionEnum.GIFTBAG_STATUS.HAS_BOUGHT
				else
					return xyd.ActivitySandMissionEnum.GIFTBAG_STATUS.TO_BUY
				end
			end
		end
	end
end

function ActivitySandMission:getPrefabPath()
	return "Prefabs/Windows/activity/activity_sand_mission"
end

function ActivitySandMission:createChildren()
	self:getUIComponent()
	self:initTextAndImage()
	self:initCountDownAndRound()
	self:initNav()
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityByID))
	self:initMissionGroup()
	xyd.models.activity:reqActivityByID(self.id)
end

function ActivitySandMission:getUIComponent()
	local go = self.go
	self.missionItem = go:NodeByName("missionItem").gameObject
	self.bg = go:ComponentByName("bg", typeof(UISprite))
	self.allGroup = go:NodeByName("e:Group").gameObject
	self.logoImg = self.allGroup:ComponentByName("logoImg", typeof(UISprite))
	self.contentGroup = self.allGroup:NodeByName("contentGroup").gameObject
	self.nav = self.contentGroup:ComponentByName("nav", typeof(UIWidget))
	self.timeTextLabel = self.allGroup:ComponentByName("cdGroup/timeTextLabel", typeof(UILabel))
	self.timeLabel1 = self.allGroup:ComponentByName("cdGroup/timeLabel1", typeof(UILabel))
	self.timeLabel2 = self.allGroup:ComponentByName("cdGroup/timeTextLabel", typeof(UILabel))
	self.task = self.contentGroup:NodeByName("task").gameObject
	self.task_UIScrollView = self.contentGroup:ComponentByName("task", typeof(UIScrollView))
	self.task_UIPanel = self.contentGroup:ComponentByName("task", typeof(UIPanel))
	self.missionGroup = self.contentGroup:NodeByName("task/missionGroup").gameObject
	self.missionGroup_UILayout = self.contentGroup:ComponentByName("task/missionGroup", typeof(UILayout))
	self.cdGroup = self.allGroup:ComponentByName("cdGroup", typeof(UILayout))
	self.giftBagBtn = go:ComponentByName("giftbagBtn", typeof(UISprite))
	self.giftBagBtnLabel = self.giftBagBtn:ComponentByName("label", typeof(UILabel))
end

function ActivitySandMission:initNav()
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

function ActivitySandMission:updateNavText()
	local labelText = {}
	local dailyComplete = 0
	local dailyCount = 0
	local weeklyComplete = 0
	local weeklyCount = 0
	local awarded = self.activityData.detail_.awarded

	for id, v in ipairs(awarded) do
		local missionTable = xyd.tables.activitySandMissionTable
		local type = missionTable:getToggleType(id)

		if type == xyd.ActivitySandMissionEnum.TOGGLE_TYPE.DAILY then
			if v == 1 then
				dailyComplete = dailyComplete + 1
			end

			dailyCount = dailyCount + 1
		elseif type == xyd.ActivitySandMissionEnum.TOGGLE_TYPE.WEEKLY then
			if v == 1 then
				weeklyComplete = weeklyComplete + 1
			end

			weeklyCount = weeklyCount + 1
		end
	end

	local text1 = __("ACTIVITY_SAND_MISSION_TAB01") .. "(" .. dailyComplete .. "/" .. dailyCount .. ")"
	local text2 = __("ACTIVITY_SAND_MISSION_TAB02") .. "(" .. weeklyComplete .. "/" .. weeklyCount .. ")"

	table.insert(labelText, text1)
	table.insert(labelText, text2)

	if self.tab then
		self.tab:setTexts(labelText)
	end
end

local navMapping = {
	xyd.ActivitySandMissionEnum.TOGGLE_TYPE.DAILY,
	xyd.ActivitySandMissionEnum.TOGGLE_TYPE.WEEKLY
}

function ActivitySandMission:updateNav(i)
	local targetToggleType = navMapping[i]

	if self.curToggleType == targetToggleType then
		return
	end

	self.curToggleType = targetToggleType

	self:initMissionGroup()
end

local giftBagBtnLabelMapping = {
	TEXT = {
		[xyd.ActivitySandMissionEnum.GIFTBAG_STATUS.TO_BUY] = __("ACTIVITY_SAND_GIFTBAG_TEXT02"),
		[xyd.ActivitySandMissionEnum.GIFTBAG_STATUS.HAS_BOUGHT] = __("ACTIVITY_SAND_GIFTBAG_TEXT03")
	}
}

function ActivitySandMission:initTextAndImage()
	self.giftBagBtnLabel.text = giftBagBtnLabelMapping.TEXT[self:getGiftBagBtnStatus()]
	local disableFlag = self:getGiftBagBtnStatus() == xyd.ActivitySandMissionEnum.GIFTBAG_STATUS.TO_BUY

	xyd.setEnabled(self.giftBagBtn, not disableFlag)
	xyd.setTouchEnable(self.giftBagBtn, disableFlag)
	xyd.setUISpriteAsync(self.logoImg, nil, "activity_sand_mission_logo_" .. tostring(xyd.Global.lang))
end

function ActivitySandMission:initCountDownAndRound()
	local duration = nil

	if xyd.getServerTime() < self.activityData:getEndTime() then
		local dayRound = self.activityData:getPassedDayRound()

		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_SAND_MISSION, function ()
			xyd.db.misc:setValue({
				key = "daytime_interval_between_most_recently_click_and_event_begin_of_activity_sand_mission",
				value = dayRound
			})
		end)
		self.timeLabel1:SetActive(true)

		self.timeTextLabel.text = __("END")
		duration = self.activityData:getEndTime() - xyd.getServerTime()
	end

	if duration then
		self.cdGroup:SetActive(true)
		CountDown.new(self.timeLabel1, {
			duration = duration
		})
	else
		self.cdGroup:SetActive(false)
	end

	if xyd.Global.lang == "fr_fr" then
		self.timeLabel2.transform:SetSiblingIndex(0)
	end

	self.cdGroup:Reposition()
end

function ActivitySandMission:timeOverDaily()
	xyd.models.activity:reqActivityByID(self.id)
	self:initCountDownAndRound()
end

function ActivitySandMission:timeOverWeek()
	self.isTimeWeekOver = true
end

function ActivitySandMission:initMissionGroup()
	local missionTable = xyd.tables.activitySandMissionTable
	local missionTextTable = xyd.tables.activitySandMissionTextTable
	local mission = missionTable:getIds()
	local paramsNow = {}

	for i = 1, #mission do
		local id = mission[i]

		if missionTable:getToggleType(i) == self:getCurToggleType() then
			local labelStyle1Flag = id == 1 and self:getGiftBagBtnStatus() == xyd.ActivitySandMissionEnum.GIFTBAG_STATUS.HAS_BOUGHT
			local params = {
				id = i,
				desc = missionTextTable:getDesc(i),
				award = missionTable:getAward(i),
				completeNum = missionTable:getCompleteNum(i),
				value = self.activityData:getValue(i) or 0,
				act_id = self.id,
				labelStyle1Flag = labelStyle1Flag
			}

			table.insert(paramsNow, params)
		end
	end

	table.sort(paramsNow, function (a, b)
		local aComplete = a.completeNum <= a.value
		local bComplete = b.completeNum <= b.value

		if aComplete ~= bComplete then
			return bComplete
		else
			return a.id < b.id
		end
	end)

	for i in ipairs(paramsNow) do
		if self.itemArr[i] == nil then
			local tmp = NGUITools.AddChild(self.missionGroup.gameObject, self.missionItem.gameObject)
			local item = ActivitySandMissionItem.new(tmp, paramsNow[i])

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

function ActivitySandMissionItem:ctor(goItem, params)
	self._icons = {}

	self.super.ctor(self, goItem)

	self.goItem_ = goItem
	local transGo = goItem.transform
	self.id = params.id
	self.act_id = params.act_id
	self.completeNum = params.completeNum
	self.value = params.value
	self.items = params.award
	self.labelStyle1Flag = params.labelStyle1Flag
	self.descLabel = transGo:ComponentByName("descLabel", typeof(UILabel))
	self.progressBar = transGo:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressImg = transGo:ComponentByName("progressBar/progressImg", typeof(UISprite))
	self.progressDesc = transGo:ComponentByName("progressBar/progressLabel", typeof(UILabel))
	self.itemGroup = transGo:NodeByName("itemGroup").gameObject
	self.itemLayout = self.itemGroup:GetComponent(typeof(UILayout))

	if xyd.Global.lang == "zh_tw" or xyd.Global.lang == "ja_jp" then
		self.descLabel.overflowHeight = 30
	end

	if xyd.Global.lang == "de_de" then
		self.descLabel.fontSize = 20
	end

	self.descLabel.text = params.desc

	self:createChildren()
end

function ActivitySandMissionItem:getGo()
	return self.goItem_
end

function ActivitySandMissionItem:createChildren()
	self:initIcon()
	self:initProgress()
	self.itemLayout:Reposition()

	UIEventListener.Get(self.goItem_).onClick = handler(self, function ()
		local getWayId = xyd.tables.activitySandMissionTable:getGetway(self.id)

		if getWayId > 0 then
			xyd.goWay(getWayId, nil, , function ()
				xyd.models.activity:reqActivityByID(self.act_id)
			end)
		end
	end)
end

function ActivitySandMissionItem:initIcon()
	NGUITools.DestroyChildren(self.itemGroup.transform)

	for _, v in ipairs(self.items) do
		local icon = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			itemID = v.itemId,
			num = v.itemNum,
			uiRoot = self.itemGroup.gameObject,
			scale = Vector3(0.5925925925925926, 0.5925925925925926, 1)
		})

		table.insert(self._icons, icon)

		if self.completeNum <= self.value then
			icon:setChoose(true)
		end

		local fontColor = self.completeNum <= self.value and xyd.FONT_COLOR.LABEL_STYLE1_DARK or xyd.FONT_COLOR.LABEL_STYLE1_LIGHT

		icon:setLabelStyle1(self.labelStyle1Flag, {
			text = "X2",
			color = fontColor
		})
	end
end

function ActivitySandMissionItem:initProgress()
	if self.completeNum <= self.value then
		self.value = self.completeNum

		xyd.setUISpriteAsync(self.progressImg, nil, "activity_bar_thumb_2")
	else
		xyd.setUISpriteAsync(self.progressImg, nil, "activity_bar_thumb")
	end

	self.progressBar.value = math.min(self.value, self.completeNum) / self.completeNum
	self.progressDesc.text = self.value .. " / " .. self.completeNum
end

function ActivitySandMissionItem:updateParams(params)
	self.id = params.id
	self.descLabel.text = params.desc
	self.completeNum = params.completeNum
	self.value = params.value
	self.items = params.award
	self.labelStyle1Flag = params.labelStyle1Flag

	self:createChildren()
end

return ActivitySandMission
