local ActivityNewbeeLesson = class("ActivityNewbeeLesson", import(".ActivityContent"))
local DailyMissionItem = class("DailyMissionItem")
local AccumulateTask = class("AccumulateTask")
local nTable = xyd.tables.activityNewbeeLessonTable
local json = require("cjson")

function ActivityNewbeeLesson:ctor(parentGo, params, parent)
	if xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_NEWBEE_LEESON) then
		xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_NEWBEE_LEESON)
	else
		xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_NEWBEE_LEESON_2)
	end

	ActivityNewbeeLesson.super.ctor(self, parentGo, params, parent)
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.layout))
end

function ActivityNewbeeLesson:getPrefabPath()
	return "Prefabs/Windows/activity/activity_newbee_lesson"
end

function ActivityNewbeeLesson:resizeToParent()
	ActivityNewbeeLesson.super.resizeToParent(self)
	self.textLogo:Y(-50 + -62 * self.scale_num_contrary)
	self.helpBtn:Y(-36 + -2 * self.scale_num_contrary)
	self.groupMission1:Y(-329 + -115 * self.scale_num_contrary)
	self.groupMission2:Y(-706 + -131 * self.scale_num_contrary)
end

function ActivityNewbeeLesson:initUI()
	self:getUIComponent()
	ActivityNewbeeLesson.super.initUI(self)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self:registerEvent(xyd.event.MIDAS_BUY_2, handler(self, self.onMidas))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))

	if not self.activityData.isSetTimer then
		self.activityData.isSetTimer = true

		xyd.models.selfPlayer:addGlobalTimer(function ()
			xyd.models.activity:reqActivityByID(self.id)
		end, 100)
	end
end

function ActivityNewbeeLesson:getUIComponent()
	local go = self.go
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.textLogo = go:ComponentByName("textLogo", typeof(UISprite))
	self.groupMission1 = go:NodeByName("groupMission1").gameObject
	self.timeGroup = self.groupMission1:ComponentByName("timeGroup", typeof(UILayout))
	self.labelRefreshTime = self.groupMission1:ComponentByName("timeGroup/labelRefreshTime", typeof(UILabel))
	self.labelRefresh = self.groupMission1:ComponentByName("timeGroup/labelRefresh", typeof(UILabel))
	self.missionItem = self.groupMission1:NodeByName("missionItem").gameObject
	self.missionContent = self.groupMission1:NodeByName("missionContent").gameObject
	self.groupMission2 = go:NodeByName("groupMission2").gameObject

	for i = 1, 2 do
		self["accumulateTask" .. i] = self.groupMission2:NodeByName("accumulateTask" .. i).gameObject
	end
end

function ActivityNewbeeLesson:layout(event)
	local id = event.data.act_info.activity_id

	if id ~= self.id then
		return
	end

	xyd.setUISpriteAsync(self.textLogo, nil, "anl_text_" .. xyd.Global.lang)

	local curDay = self:getCurDay()

	if curDay < 14 then
		self.labelRefresh.text = __("ACTIVITY_NEWBEE_LESSON_TEXT01")
	else
		self.labelRefresh.text = __("ACTIVITY_NEWBEE_LESSON_TEXT02")
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_NEWBEE_LESSON_HELP"
		})
	end

	local duration = xyd.getTomorrowTime() - xyd.getServerTime()

	if duration < 0 then
		self.labelRefreshTime:SetActive(false)
		self.labelRefresh:SetActive(false)
	else
		local timeCount = import("app.components.CountDown").new(self.labelRefreshTime)

		timeCount:setInfo({
			function ()
				xyd.WindowManager.get():closeWindow("activity_window")
			end,
			duration = duration
		})
	end

	self.timeGroup:Reposition()

	local dayMisson = nTable:getDailyMissionByDay(curDay)
	self.dailyMissionItemList = {}

	NGUITools.DestroyChildren(self.missionContent.transform)

	self.hasMidasMission = false
	self.hasCrystalMission = false

	for i = 1, 6 do
		local tmp = NGUITools.AddChild(self.missionContent, self.missionItem)
		local tableId = dayMisson[i]
		local dailyMissionItem = DailyMissionItem.new(tmp, tableId, self.id)

		table.insert(self.dailyMissionItemList, dailyMissionItem)

		if nTable:getType(tableId) == 11 then
			self.hasMidasMission = true
		end

		if nTable:getType(tableId) == 12 then
			self.hasCrystalMission = true
		end
	end

	self.missionContent:GetComponent(typeof(UIGrid)):Reposition()

	self.accumulateTaskItem1 = AccumulateTask.new(self.accumulateTask1, 19, self.id)
	self.accumulateTaskItem2 = AccumulateTask.new(self.accumulateTask2, 20, self.id)
end

function ActivityNewbeeLesson:getCurDay()
	local startTime = self.activityData.detail_.start_time

	return math.ceil((xyd.getServerTime() - startTime) / 86400)
end

function ActivityNewbeeLesson:onAward(event)
	local items = json.decode(event.data.detail).items

	xyd.models.itemFloatModel:pushNewItems(items)

	for _, item in ipairs(self.dailyMissionItemList) do
		item:update()
	end

	self.accumulateTaskItem1:layout()
	self.accumulateTaskItem2:layout()
end

function ActivityNewbeeLesson:onRecharge()
	xyd.models.activity:reqActivityByID(self.id)
end

function ActivityNewbeeLesson:onMidas()
	if self.hasMidasMission then
		xyd.models.activity:reqActivityByID(self.id)
	end
end

function ActivityNewbeeLesson:onItemChange(event)
	if self.hasCrystalMission then
		local data = event.data.items

		for i = 1, #data do
			local item = data[i]

			if item.item_id == xyd.ItemID.CRYSTAL then
				xyd.models.activity:reqActivityByID(self.id)
			end
		end
	end
end

function DailyMissionItem:ctor(go, tableId, activityID)
	self.go = go
	self.tableId = tableId
	self.activityID = activityID
	self.labelLesson = go:ComponentByName("labelLesson", typeof(UILabel))
	self.iconRoot = go:NodeByName("iconRoot").gameObject
	self.btn = go:NodeByName("btn").gameObject
	self.labelBtn = self.btn:ComponentByName("labelBtn", typeof(UILabel))
	self.redPoint = self.btn:NodeByName("redMark").gameObject

	self:layout()
end

function DailyMissionItem:layout()
	if xyd.Global.lang ~= "zh_tw" then
		self.labelLesson.fontSize = 18
	end

	self.labelLesson.text = nTable:getName(self.tableId)
	local award = nTable:getAward(self.tableId)[1]
	local awardItem = xyd.getItemIcon({
		show_has_num = true,
		scale = 0.6018518518518519,
		itemID = award[1],
		num = award[2],
		uiRoot = self.iconRoot
	})

	self:update()

	UIEventListener.Get(self.go).onClick = function ()
		xyd.WindowManager.get():openWindow("newbee_lesson_daily_mission_detail_window", {
			tableId = self.tableId,
			activityID = self.activityID
		})
	end

	UIEventListener.Get(self.btn).onClick = handler(self, self.onClickBtn)
end

function DailyMissionItem:setBtn()
	local btnSprite, btnText, btnEffectColor = nil

	if self.isAwarded == 1 then
		btnSprite = "anl_btn_got"
		btnText = __("ALREADY_GET_PRIZE")
		btnEffectColor = 2510072063.0

		xyd.setTouchEnable(self.btn, false)
	elseif self.isCompleted == 1 then
		btnSprite = "anl_btn_get"
		btnText = __("GET2")
		btnEffectColor = 3819719423.0
	else
		btnSprite = "anl_btn_check"
		btnText = __("CHECK_TEAM")
		btnEffectColor = 1285419263
	end

	xyd.setUISpriteAsync(self.btn:GetComponent(typeof(UISprite)), nil, btnSprite)

	self.labelBtn.text = btnText
	self.labelBtn.effectColor = Color.New2(btnEffectColor)

	self.redPoint:SetActive(self.isAwarded == 0 and self.isCompleted == 1)
end

function DailyMissionItem:update()
	local detail = xyd.models.activity:getActivity(self.activityID).detail_
	self.isAwarded = detail.awards[self.tableId]
	self.isCompleted = detail.is_completeds[self.tableId]

	self:setBtn()
end

function DailyMissionItem:onClickBtn()
	if self.isCompleted == 1 then
		local params = json.encode({
			table_id = tonumber(self.tableId)
		})

		xyd.models.activity:reqAwardWithParams(self.activityID, params)
	else
		xyd.WindowManager.get():openWindow("newbee_lesson_daily_mission_detail_window", {
			tableId = self.tableId,
			activityID = self.activityID
		})
	end
end

function AccumulateTask:ctor(go, type, activityID)
	self.go = go
	self.type = type
	self.activityID = activityID
	self.awardGroup = self.go:NodeByName("awardGroup").gameObject
	self.tipsLabel = self.go:ComponentByName("tipsLabel", typeof(UILabel))
	self.valueLabel = self.go:ComponentByName("valueLabel", typeof(UILabel))
	self.btn = self.go:NodeByName("getBtn").gameObject
	self.labelGetBtn = self.btn:ComponentByName("labelGetBtn", typeof(UILabel))
	self.redPoint = self.btn:NodeByName("redMark").gameObject
	self.detailBtn = self.go:NodeByName("detailBtn").gameObject

	self:layout()

	UIEventListener.Get(self.detailBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("newbee_lesson_task_preview_window", {
			type = self.type,
			activityID = self.activityID
		})
	end

	UIEventListener.Get(self.btn).onClick = handler(self, self.onClickGetBtn)
end

function AccumulateTask:layout()
	local taskList = nTable:getAccumulateTaskByType(self.type)
	local detail = xyd.models.activity:getActivity(self.activityID).detail_
	local curId = taskList[#taskList]

	for _, id in ipairs(taskList) do
		if detail.awards[id] == 0 then
			curId = id

			break
		end
	end

	self.tipsLabel.text = nTable:getDesc(curId)
	local completeValue = nTable:getCompleteValue(curId)
	self.valueLabel.text = "(" .. detail.values[curId] .. "/" .. completeValue .. ")"
	local awards = nTable:getAward(curId)

	NGUITools.DestroyChildren(self.awardGroup.transform)

	self.itemList = {}

	for _, data in pairs(awards) do
		local item = xyd.getItemIcon({
			show_has_num = true,
			scale = 0.7037037037037037,
			uiRoot = self.awardGroup,
			itemID = data[1],
			num = data[2]
		})

		table.insert(self.itemList, item)
	end

	self.awardGroup:GetComponent(typeof(UIGrid)):Reposition()

	if detail.awards[curId] == 1 then
		self.labelGetBtn.text = __("ALREADY_GET_PRIZE")

		for _, item in ipairs(self.itemList) do
			item:setChoose(true)
		end

		xyd.setTouchEnable(self.btn, false)
		xyd.applyChildrenGrey(self.btn)
	elseif detail.is_completeds[curId] == 1 then
		self.labelGetBtn.text = __("GET2")

		if self.type == 20 then
			xyd.setTouchEnable(self.btn, true)
			xyd.applyChildrenOrigin(self.btn)
		end
	elseif self.type == 19 then
		self.labelGetBtn.text = __("GO")
	else
		self.labelGetBtn.text = __("GET2")

		xyd.setTouchEnable(self.btn, false)
		xyd.applyChildrenGrey(self.btn)
	end

	self.redPoint:SetActive(detail.awards[curId] == 0 and detail.is_completeds[curId] == 1)

	self.curId = curId
end

function AccumulateTask:onClickGetBtn()
	local detail = xyd.models.activity:getActivity(self.activityID).detail_

	if detail.is_completeds[self.curId] == 1 then
		local params = json.encode({
			table_id = tonumber(self.curId)
		})

		xyd.models.activity:reqAwardWithParams(self.activityID, params)
	else
		xyd.goWay(xyd.GoWayId.ACITVITY_NEWBEE_LESSON_GIFTBAG_2)
	end
end

return ActivityNewbeeLesson
