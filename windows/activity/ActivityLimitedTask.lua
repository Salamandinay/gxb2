local ActivityLimitedTask = class("ActivityLimitedTask", import(".ActivityContent"))
local TaskItem1 = class("TaskItem1")
local TaskItem2 = class("TaskItem2")
local taskTable = xyd.tables.activityLimitedTaskTable

function ActivityLimitedTask:ctor(parentGo, params, parent)
	ActivityLimitedTask.super.ctor(self, parentGo, params, parent)
end

function ActivityLimitedTask:getPrefabPath()
	return "Prefabs/Windows/activity/activity_limited_task"
end

function ActivityLimitedTask:resizeToParent()
	ActivityLimitedTask.super.resizeToParent(self)
	self.textLogo:Y(-104 + -94 * self.scale_num_contrary)
	self.labelDesc:Y(-216 + -118 * self.scale_num_contrary)
	self.timeGroup:Y(-361 + -145 * self.scale_num_contrary)
end

function ActivityLimitedTask:initUI()
	self:getUIComponent()
	ActivityLimitedTask.super.initUI(self)
	self:layout()
end

function ActivityLimitedTask:getUIComponent()
	local go = self.go
	self.textLogo = go:ComponentByName("textLogo", typeof(UISprite))
	self.labelDesc = go:ComponentByName("labelDesc", typeof(UILabel))
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.timeGroup = go:ComponentByName("timeGroup", typeof(UILayout))
	self.labelTime = self.timeGroup:ComponentByName("labelTime", typeof(UILabel))
	self.labelEnd = self.timeGroup:ComponentByName("labelEnd", typeof(UILabel))
	local groupBottom = go:NodeByName("groupBottom").gameObject
	self.scroller = groupBottom:ComponentByName("scroller", typeof(UIScrollView))
	self.groupContent = self.scroller:NodeByName("groupContent").gameObject
	self.taskItem1 = groupBottom:NodeByName("task_item_1").gameObject
	self.taskItem2 = groupBottom:NodeByName("task_item_2").gameObject

	self.taskItem1:SetActive(false)
	self.taskItem2:SetActive(false)
end

function ActivityLimitedTask:layout()
	xyd.setUISpriteAsync(self.textLogo, nil, "activity_limited_task_" .. xyd.Global.lang)

	self.labelEnd.text = __("END")
	self.labelDesc.text = __("LIMITED_TASK_TEXT_01")

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" then
		self.labelDesc.spacingY = 0
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "LIMITED_TASK_HELP"
		})
	end

	local duration = self.activityData:getEndTime() - xyd.getServerTime()

	if duration < 0 then
		self.timeGroup:SetActive(false)
	else
		local timeCount = import("app.components.CountDown").new(self.labelTime)

		timeCount:setInfo({
			duration = duration
		})
	end

	local missions = taskTable:getMissionList()

	table.sort(missions, function (a, b)
		local completes = self.activityData.detail.is_completeds

		if completes[a] == completes[b] then
			return a < b
		else
			return completes[a] == 0
		end
	end)

	for _, id in ipairs(missions) do
		local subMissions = taskTable:getSubMission(id)
		local taskItem = nil

		if next(subMissions) == nil then
			local item = NGUITools.AddChild(self.groupContent, self.taskItem1)
			taskItem = TaskItem1.new(item)
		else
			local item = NGUITools.AddChild(self.groupContent, self.taskItem2)
			taskItem = TaskItem2.new(item)
		end

		taskItem:setInfo(id)
	end

	self:waitForFrame(1, function ()
		self.scroller:ResetPosition()
	end)
end

function TaskItem1:ctor(go)
	self.go = go

	self:getUIComponent()
	self:resizeToLanguage()
end

function TaskItem1:resizeToLanguage()
	if xyd.Global.lang == "en_en" or xyd.Global.lang == "de_de" or xyd.Global.lang == "ja_jp" then
		self.labelTitle.fontSize = 22
	elseif xyd.Global.lang == "fr_fr" then
		self.labelTitle.fontSize = 20
	end
end

function TaskItem1:getUIComponent()
	local go = self.go
	self.progressBar_ = go:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressLabel = self.progressBar_:ComponentByName("progressLabel", typeof(UILabel))
	self.progressImg = self.progressBar_:ComponentByName("progressImg", typeof(UISprite))
	self.itemsGroup = go:NodeByName("itemsGroup").gameObject
	self.labelTitle = go:ComponentByName("labelTitle", typeof(UILabel))
end

function TaskItem1:setInfo(id)
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LIMITED_TASK).detail
	local hasNum = tonumber(activityData.values[id]) or 0
	local completeValue = taskTable:getCompleteValue(id)
	self.labelTitle.text = xyd.stringFormat(taskTable:getDesc(id), completeValue)
	self.progressBar_.value = hasNum / completeValue
	self.progressLabel.text = hasNum .. "/" .. completeValue
	local awards = taskTable:getAwards(id)
	local isCompleted = activityData.is_completeds[id] == 1

	if isCompleted then
		xyd.setUISpriteAsync(self.progressImg, nil, "activity_bar_thumb_2")
	else
		xyd.setUISpriteAsync(self.progressImg, nil, "activity_bar_thumb")
	end

	NGUITools.DestroyChildren(self.itemsGroup.transform)

	for i = 1, #awards do
		local data = awards[i]
		local item = xyd.getItemIcon({
			show_has_num = true,
			labelNumScale = 1.2,
			scale = 0.7,
			uiRoot = self.itemsGroup,
			itemID = data[1],
			num = data[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		item:setChoose(isCompleted)
	end
end

function TaskItem2:ctor(go)
	self.go = go

	self:getUIComponent()
	self:resizeToLanguage()
end

function TaskItem2:resizeToLanguage()
	if xyd.Global.lang == "en_en" or xyd.Global.lang == "de_de" or xyd.Global.lang == "ja_jp" then
		self.labelTitle1.fontSize = 22
		self.labelTitle2.fontSize = 22
	elseif xyd.Global.lang == "fr_fr" then
		self.labelTitle1.fontSize = 20
		self.labelTitle2.fontSize = 20
	end
end

function TaskItem2:getUIComponent()
	local go = self.go
	self.progressBar_1 = go:ComponentByName("progressBar_1", typeof(UIProgressBar))
	self.progressLabel_1 = self.progressBar_1:ComponentByName("progressLabel", typeof(UILabel))
	self.progressImg_1 = self.progressBar_1:ComponentByName("progressImg", typeof(UISprite))
	self.progressBar_2 = go:ComponentByName("progressBar_2", typeof(UIProgressBar))
	self.progressLabel_2 = self.progressBar_2:ComponentByName("progressLabel", typeof(UILabel))
	self.progressImg_2 = self.progressBar_2:ComponentByName("progressImg", typeof(UISprite))
	self.itemsGroup = go:NodeByName("itemsGroup").gameObject
	self.labelTitle1 = go:ComponentByName("labelTitle1", typeof(UILabel))
	self.labelTitle2 = go:ComponentByName("labelTitle2", typeof(UILabel))
end

function TaskItem2:setInfo(id)
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LIMITED_TASK).detail
	local subIds = taskTable:getSubMission(id)

	for i = 1, 2 do
		local subId = tonumber(subIds[i])
		local hasNum = tonumber(activityData.values[subId]) or 0
		local completeValue = taskTable:getCompleteValue(subId)

		if completeValue <= hasNum then
			xyd.setUISpriteAsync(self["progressImg_" .. i], nil, "activity_bar_thumb_2")
		else
			xyd.setUISpriteAsync(self["progressImg_" .. i], nil, "activity_bar_thumb")
		end

		self["progressBar_" .. i].value = hasNum / completeValue
		self["progressLabel_" .. i].text = hasNum .. "/" .. completeValue
		self["labelTitle" .. i].text = xyd.stringFormat(taskTable:getDesc(subId), completeValue)
	end

	local awards = taskTable:getAwards(id)
	local isCompleted = activityData.is_completeds[id] == 1

	NGUITools.DestroyChildren(self.itemsGroup.transform)

	for i = 1, #awards do
		local data = awards[i]
		local item = xyd.getItemIcon({
			show_has_num = true,
			labelNumScale = 1.2,
			scale = 0.7,
			uiRoot = self.itemsGroup,
			itemID = data[1],
			num = data[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		item:setChoose(isCompleted)
	end
end

return ActivityLimitedTask
