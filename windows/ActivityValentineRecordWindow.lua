local BaseWindow = import(".BaseWindow")
local ActivityValentineRecordWindow = class("ActivityValentineRecordWindow", BaseWindow)
local CountDown = import("app.components.CountDown")

function ActivityValentineRecordWindow:ctor(name, params)
	ActivityValentineRecordWindow.super.ctor(self, name, params)
end

function ActivityValentineRecordWindow:initWindow()
	ActivityValentineRecordWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function ActivityValentineRecordWindow:getUIComponent()
	local groupActionTrans = self.window_:NodeByName("groupAction")

	for i = 1, 5 do
		self["image" .. i] = groupActionTrans:NodeByName("image" .. i).gameObject
	end

	self.tipLabel = groupActionTrans:ComponentByName("tipLabel", typeof(UILabel))
	self.tipLabel.text = __("ACTIVITY_VALENTINE_PHOTO_CLOSE")
end

function ActivityValentineRecordWindow:initUIComponent()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_VALENTINE)
	local pastDays = (xyd.getServerTime() - activityData.start_time) / xyd.TimePeriod.DAY_TIME
	local memory_ids = xyd.tables.miscTable:split2num("activity_valentine_plot_memory", "value", "|")
	local record_ids = activityData.detail.plot_ids
	local record_type = {}

	for i = 1, #record_ids do
		table.insert(record_type, xyd.tables.activityValentinePlotTable:getEndType(record_ids[i]))
	end

	for i = 1, 5 do
		local image = self["image" .. i]
		local mask = image:NodeByName("mask").gameObject
		local unlock_day = i - 1

		if i < 5 then
			local labelLayout = image:ComponentByName("labelGroup", typeof(UILayout))
			local textLabel = image:ComponentByName("labelGroup/label1", typeof(UILabel))
			local timeLabel = image:ComponentByName("labelGroup/label2", typeof(UILabel))

			if unlock_day <= pastDays then
				textLabel.width = 230
				textLabel.height = 32
				textLabel.overflowMethod = UILabel.Overflow.ShrinkContent
				local name = xyd.tables.activityPlotListTextTable:getName(memory_ids[i])

				if xyd.arrayIndexOf(record_type, i) < 0 then
					mask:SetActive(true)
					timeLabel:SetActive(false)

					textLabel.text = __("ACTIVITY_VALENTINE_PLOT_END", name)
					self["state" .. i] = false
				else
					mask:SetActive(false)
					timeLabel:SetActive(false)

					textLabel.text = name
					self["state" .. i] = true
				end
			else
				mask:SetActive(true)
				timeLabel:SetActive(true)

				textLabel.text = __("ACTIVITY_VALENTINE_PLOT_LOCK2")

				CountDown.new(timeLabel, {
					duration = activityData.start_time + unlock_day * 24 * 60 * 60 - xyd.getServerTime()
				})

				self["state" .. i] = false
			end

			labelLayout:Reposition()
		else
			local textLabel = image:ComponentByName("label", typeof(UILabel))

			if xyd.arrayIndexOf(record_type, i) < 0 then
				local timeLabel = image:ComponentByName("mask/label04", typeof(UILabel))
				local label01 = mask:ComponentByName("label01", typeof(UILabel))
				local label02 = mask:ComponentByName("label02", typeof(UILabel))
				local label03 = mask:ComponentByName("label03", typeof(UILabel))
				local label05 = mask:ComponentByName("label05", typeof(UILabel))
				local time = activityData.start_time + unlock_day * 24 * 60 * 60 - xyd.getServerTime()
				local num = xyd.checkCondition(activityData.detail.num <= 4, activityData.detail.num, 4)

				mask:SetActive(true)

				textLabel.text = __("ACTIVITY_VALENTINE_PLOT_UNLOCK")
				label01.text = __("ACTIVITY_VALENTINE_PLOT_LIMIT")
				label03.text = __("ACTIVITY_VALENTINE_COLLECT")
				label05.text = "(" .. num .. "/4)"

				if time > 0 then
					label02.text = __("ACTIVITY_VALENTINE_PLOT_LOCK")

					CountDown.new(timeLabel, {
						duration = activityData.start_time + unlock_day * 24 * 60 * 60 - xyd.getServerTime()
					})
				else
					local name = xyd.tables.activityPlotListTextTable:getName(memory_ids[i])

					timeLabel:SetActive(false)
					label02:SetActive(false)
					label03:Y(0)
					label05:Y(0)

					textLabel.text = __("ACTIVITY_VALENTINE_PLOT_END", name)
				end

				self["state" .. i] = false
			else
				mask:SetActive(false)

				textLabel.text = xyd.tables.activityPlotListTextTable:getName(memory_ids[i])
				self["state" .. i] = true
			end
		end
	end
end

function ActivityValentineRecordWindow:register()
	ActivityValentineRecordWindow.super.register(self)

	for i = 1, 5 do
		UIEventListener.Get(self["image" .. i]).onClick = handler(self, function ()
			self:onRecord(i)
		end)
	end
end

function ActivityValentineRecordWindow:onRecord(index)
	if not self["state" .. index] then
		xyd.alertTips(__("ACTIVITY_VALENTINE_LOCK_TIPS2"))

		return
	end

	local memory_ids = xyd.tables.miscTable:split2num("activity_valentine_plot_memory", "value", "|")
	local listId = memory_ids[index]
	local story_list = xyd.tables.activityPlotListTable:getMemoryPlotId(listId)

	xyd.WindowManager.get():openWindow("story_window", {
		jumpToSelect = true,
		story_type = xyd.StoryType.ACTIVITY_VALENTINE,
		story_list = story_list
	})
end

return ActivityValentineRecordWindow
