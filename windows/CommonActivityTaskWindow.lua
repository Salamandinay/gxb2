local CommonActivityTaskWindow = class("CommonActivityTaskWindow", import(".BaseWindow"))
local TaskItem = class("TaskItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function CommonActivityTaskWindow:ctor(name, params)
	CommonActivityTaskWindow.super.ctor(self, name, params)

	self.all_info = params.all_info
	self.if_sort = params.if_sort
	self.title_text = params.title_text
	self.wnd_type = params.wnd_type
	self.clickBgCallback = params.clickBgCallback
end

function CommonActivityTaskWindow:initWindow()
	self:getUIComponent()
	CommonActivityTaskWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function CommonActivityTaskWindow:getWndType()
	return self.wnd_type
end

function CommonActivityTaskWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.bg_UIWidget = self.groupAction:ComponentByName("bg", typeof(UIWidget))
	self.labelTitle_ = self.groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.scrollView = self.groupAction:ComponentByName("scrollView", typeof(UIScrollView))
	self.gridDaily = self.scrollView:NodeByName("gridDaily").gameObject
	self.gridDaily_UIWrapContent = self.scrollView:ComponentByName("gridDaily", typeof(UIWrapContent))
	self.taskItem = self.groupAction:NodeByName("task_item").gameObject
end

function CommonActivityTaskWindow:layout()
	if self.title_text then
		self:setTitle(self.title_text)
	else
		self:setTitle(__("MAIL_AWAED_TEXT"))
	end

	if self.if_sort then
		self.sortArr_1 = {}
		self.sortArr_2 = {}

		for i in pairs(self.all_info) do
			table.insert(self["sortArr_" .. self.all_info[i].state], self.all_info[i])
		end

		for i in pairs(self.sortArr_2) do
			table.insert(self.sortArr_1, self.sortArr_2[i])
		end

		self.all_info = self.sortArr_1
	end

	self.itemsArr = {}

	if #self.all_info >= 7 then
		self.bg_UIWidget.height = 710
	end

	self:waitForFrame(1, function ()
		self.wrapContent = FixedWrapContent.new(self.scrollView, self.gridDaily_UIWrapContent, self.taskItem, TaskItem, self)

		self:waitForFrame(1, function ()
			self.wrapContent:setInfos(self.all_info, {})
			self.scrollView:ResetPosition()
		end)
	end)
end

function CommonActivityTaskWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function CommonActivityTaskWindow:updateItemState(id, state)
	for i in pairs(self.all_info) do
		if self.all_info[i].id == id then
			self.all_info[i].state = state

			break
		end
	end

	self.wrapContent:setInfos(self.all_info, {
		keepPosition = true
	})
end

function CommonActivityTaskWindow:updateAllInfo(all_info)
	self.all_info = all_info

	self:waitForFrame(1, function ()
		self.wrapContent:setInfos(self.all_info, {})
	end)
end

function TaskItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.awardItemsArr = {}

	TaskItem.super.ctor(self, go)
end

function TaskItem:initUI()
	self.task_item = self.go
	self.progressBar = self.task_item:ComponentByName("progressBar_", typeof(UISprite))
	self.progressBarUIProgressBar = self.task_item:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressImg = self.progressBar:ComponentByName("progressImg", typeof(UISprite))
	self.progressLabel = self.progressBar:ComponentByName("progressLabel", typeof(UILabel))
	self.itemsGroup = self.task_item:NodeByName("itemsGroup").gameObject
	self.itemsGroupUILayout = self.task_item:ComponentByName("itemsGroup", typeof(UILayout))
	self.labelTitle = self.task_item:ComponentByName("labelTitle", typeof(UILabel))
	self.completeNum = self.task_item:ComponentByName("completeNum", typeof(UILabel))
	self.bg = self.task_item:ComponentByName("e:Image", typeof(UISprite))

	if self.parent.clickBgCallback then
		UIEventListener.Get(self.bg.gameObject).onClick = handler(self, function ()
			print("1")
			self.parent.clickBgCallback(self.id)
		end)
	end
end

function TaskItem:update(index, data)
	if not data then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	if self.id and self.state and data and self.id == data.id and self.state == data.state then
		return
	end

	self.id = data.id
	self.labelTitle.text = data.desc
	local limit = data.limitNum
	local curCompleteNum = data.curCompleteNum
	local ProgressLimitValue = data.progressLimitValue
	local curProgressValue = data.curProgressValue

	if limit <= curCompleteNum then
		self.completeNum.text = __("ACTIVITY_VAMPIRE_TASK_TEXT01") .. " : " .. "[c][5d9201]" .. limit .. "/" .. limit .. "[-][/c]"
		self.progressBarUIProgressBar.value = 1
		self.progressLabel.text = ProgressLimitValue .. "/" .. ProgressLimitValue
	else
		self.completeNum.text = __("ACTIVITY_VAMPIRE_TASK_TEXT01") .. " : " .. "[c][ac3824]" .. curCompleteNum .. "/" .. limit .. "[-][/c]"
		local value = curProgressValue / ProgressLimitValue

		if value > 1 then
			value = 1
		end

		self.progressBarUIProgressBar.value = value
		self.progressLabel.text = curProgressValue .. "/" .. ProgressLimitValue
	end

	local awardItems = data.awards

	for i in pairs(awardItems) do
		local params = {
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = awardItems[i][1],
			num = awardItems[i][2],
			scale = Vector3(0.6018518518518519, 0.6018518518518519, 1),
			uiRoot = self.itemsGroup.gameObject
		}

		if not self.awardItemsArr[i] then
			local itemIcon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)

			table.insert(self.awardItemsArr, itemIcon)
		else
			self.awardItemsArr[i]:setInfo(params)
		end

		if limit <= curCompleteNum then
			self.awardItemsArr[i]:setChoose(true)
		else
			self.awardItemsArr[i]:setChoose(false)
		end
	end

	if #awardItems < #self.awardItemsArr then
		for i = #awardItems + 1, #self.awardItemsArr do
			self.awardItemsArr[i]:SetActive(false)
		end
	end

	self.itemsGroupUILayout:Reposition()
end

return CommonActivityTaskWindow
