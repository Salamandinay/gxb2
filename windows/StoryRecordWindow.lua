local BaseWindow = import(".BaseWindow")
local StoryRecordWindow = class("StoryRecordWindow", BaseWindow)
local StoryRecordItem = class("StoryRecordItem", import("app.components.CopyComponent"))

function StoryRecordWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "StoryRecordWindowSkin"
	self.data_ = params.data
	self.callback = params.callback
end

function StoryRecordWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function StoryRecordWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.labelTitle_ = winTrans:ComponentByName("topLeft/labelTitle_", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("topRight/closeBtn").gameObject
	self.item = winTrans:NodeByName("top/item").gameObject
	self.scrollView = winTrans:ComponentByName("top/scroller_", typeof(UIScrollView))
	self.itemList_ = self.scrollView:NodeByName("itemList_").gameObject
	local wrapContent = self.scrollView:ComponentByName("itemList_", typeof(UIWrapContent))
end

function StoryRecordWindow:layout()
	self.labelTitle_.text = __("STORY_RECORD_TITLE")
	local height = 0

	for i = 1, #self.data_ do
		local itemNode = NGUITools.AddChild(self.itemList_, self.item)
		local item = StoryRecordItem.new(itemNode)

		item:setInfo(self.data_[i])

		height = height + item.go:GetComponent(typeof(UIWidget)).height
	end

	height = height + #self.data_ * self.itemList_:GetComponent(typeof(UILayout)).gap.y
	local panel_h = self.scrollView.gameObject:GetComponent(typeof(UIPanel)).baseClipRegion.w

	print(height, panel_h)
	self:waitForFrame(1, function ()
		self.itemList_:GetComponent(typeof(UILayout)):Reposition()
		self.scrollView:ResetPosition()

		if panel_h < height then
			self.scrollView:MoveRelative(Vector3(0, height - panel_h, 0))
		end
	end)
end

function StoryRecordWindow:scrollEnd()
end

function StoryRecordWindow:excuteCallBack(isCloseAll)
	BaseWindow.excuteCallBack(self)

	if isCloseAll then
		return
	end

	if self.callback then
		self.callback()
	end
end

function StoryRecordItem:ctor(go)
	StoryRecordItem.super.ctor(self, go)
end

function StoryRecordItem:setInfo(data)
	self.data = data

	self:layout()
end

function StoryRecordItem:initUI()
	StoryRecordItem.super.initUI(self)

	self.labelName_ = self.go:ComponentByName("labelName_", typeof(UILabel))
	self.labelDialog_ = self.go:ComponentByName("labelDialog_", typeof(UILabel))
end

function StoryRecordItem:layout()
	self.labelName_.text = self.data.name
	self.labelDialog_.text = self.data.dialog
end

return StoryRecordWindow
