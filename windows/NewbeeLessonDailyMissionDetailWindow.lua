local NewbeeLessonDailyMissionDetailWindow = class("NewbeeLessonDailyMissionDetailWindow", import(".BaseWindow"))
local json = require("cjson")
local nTable = xyd.tables.activityNewbeeLessonTable

function NewbeeLessonDailyMissionDetailWindow:ctor(name, params)
	NewbeeLessonDailyMissionDetailWindow.super.ctor(self, name, params)
end

function NewbeeLessonDailyMissionDetailWindow:initWindow()
	self:getUIComponent()
	self:getData()
	self:layout()
end

function NewbeeLessonDailyMissionDetailWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.labelLesson = groupAction:ComponentByName("labelLesson", typeof(UILabel))
	self.labelValue = groupAction:ComponentByName("labelValue", typeof(UILabel))
	self.labelDesc = groupAction:ComponentByName("labelDesc", typeof(UILabel))
	self.labelAward = groupAction:ComponentByName("labelAward", typeof(UILabel))
	self.iconRoot = groupAction:NodeByName("iconRoot").gameObject
	self.btn = groupAction:NodeByName("btn").gameObject
	self.labelBtn = self.btn:ComponentByName("labelBtn", typeof(UILabel))
end

function NewbeeLessonDailyMissionDetailWindow:getData()
	local detail = xyd.models.activity:getActivity(self.params_.activityID).detail_
	self.tableId = self.params_.tableId
	self.isAwarded = detail.awards[self.tableId]
	self.isCompleted = detail.is_completeds[self.tableId]
	self.value = detail.values[self.tableId]
end

function NewbeeLessonDailyMissionDetailWindow:layout()
	self.labelTitle.text = __("ACTIVITY_NEWBEE_LESSON_TITEL")
	self.labelLesson.text = nTable:getName(self.tableId)
	local completeValue = nTable:getCompleteValue(self.tableId)
	self.labelValue.text = "(" .. self.value .. "/" .. completeValue .. ")"
	self.labelDesc.text = nTable:getDesc(self.tableId)
	self.labelAward.text = __("AWARD3")
	local award = nTable:getAward(self.tableId)[1]
	local awardItem = xyd.getItemIcon({
		show_has_num = true,
		itemID = award[1],
		num = award[2],
		uiRoot = self.iconRoot
	})

	if self.isAwarded == 1 then
		xyd.setTouchEnable(self.btn, false)
		xyd.applyChildrenGrey(self.btn)

		self.labelBtn.text = __("ALREADY_GET_PRIZE")
	elseif self.isCompleted == 1 then
		self.labelBtn.text = __("GET2")
	else
		self.labelBtn.text = __("GO")
	end

	UIEventListener.Get(self.btn).onClick = handler(self, self.onClickBtn)

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end
end

function NewbeeLessonDailyMissionDetailWindow:onClickBtn()
	if self.isCompleted == 1 then
		local params = json.encode({
			table_id = tonumber(self.tableId)
		})

		xyd.models.activity:reqAwardWithParams(self.params_.activityID, params)
	else
		local getWayId = nTable:getGetway(self.tableId)
		local GetWayTable = xyd.tables.getWayTable
		local function_id = GetWayTable:getFunctionId(getWayId)
		local activityID = self.params_.activityID

		if not xyd.checkFunctionOpen(function_id) then
			return
		end

		local windows = GetWayTable:getGoWindow(getWayId) or {}
		local params = GetWayTable:getGoParam(getWayId)

		for i in pairs(windows) do
			if not params[i] then
				params[i] = {}
			end

			params[i].closeCallBack = function ()
				xyd.WindowManager.get():openWindow("activity_window", {
					select = activityID
				})
			end

			xyd.WindowManager.get():openWindow(windows[i], params[i])
		end

		xyd.WindowManager.get():closeWindow("activity_window")
	end

	self:close()
end

return NewbeeLessonDailyMissionDetailWindow
