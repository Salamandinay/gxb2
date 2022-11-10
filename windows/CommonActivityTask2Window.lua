local CommonActivityTask2Window = class("CommonActivityTask2Window", import(".BaseWindow"))
local TaskItem = class("TaskItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function CommonActivityTask2Window:ctor(name, params)
	CommonActivityTask2Window.super.ctor(self, name, params)

	self.all_info = params.all_info
	self.click_callBack = params.click_callBack
	self.if_sort = params.if_sort
	self.title_text = params.title_text
	self.wnd_type = params.wnd_type
	self.clickBgCallback = params.clickBgCallback
end

function CommonActivityTask2Window:initWindow()
	self:getUIComponent()
	CommonActivityTask2Window.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function CommonActivityTask2Window:getWndType()
	return self.wnd_type
end

function CommonActivityTask2Window:getUIComponent()
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

function CommonActivityTask2Window:layout()
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

function CommonActivityTask2Window:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function CommonActivityTask2Window:updateItemState(id, state)
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

function CommonActivityTask2Window:updateAllInfo(all_info)
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
	self.progressBar = self.task_item:NodeByName("progress").gameObject
	self.progressBarUIProgressBar = self.task_item:ComponentByName("progress", typeof(UISlider))
	self.progressLabel = self.progressBar:ComponentByName("labelDisplay", typeof(UILabel))
	self.labelTitle = self.task_item:ComponentByName("labelTitle", typeof(UILabel))
	self.bg = self.task_item:ComponentByName("e:Image", typeof(UISprite))
	self.btnJump = self.task_item:NodeByName("btnJump").gameObject
	self.labelJump = self.btnJump:ComponentByName("labelJump", typeof(UILabel))
	self.imgAward = self.task_item:ComponentByName("imgAward", typeof(UISprite))
	self.labelJump.text = __("GO")

	xyd.setUISpriteAsync(self.imgAward, nil, "mission_awarded_" .. xyd.Global.lang, nil, )

	if self.parent.clickBgCallback then
		UIEventListener.Get(self.btnJump.gameObject).onClick = handler(self, function ()
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
	local value = curProgressValue / ProgressLimitValue

	if value >= 1 then
		value = 1

		self.imgAward:SetActive(true)
		self.btnJump:SetActive(false)
	else
		self.imgAward:SetActive(false)
		self.btnJump:SetActive(true)
	end

	self.progressBarUIProgressBar.value = value
	self.progressLabel.text = curProgressValue .. "/" .. ProgressLimitValue
end

return CommonActivityTask2Window
