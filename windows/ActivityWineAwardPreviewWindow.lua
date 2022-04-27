local BaseWindow = import(".BaseWindow")
local ActivityWineAwardPreviewWindow = class("ActivityWineAwardPreviewWindow", BaseWindow)
local ActivityWineAwardPreviewItem = class("ActivityWineAwardPreviewItem", import("app.components.CopyComponent"))

function ActivityWineAwardPreviewWindow:ctor(name, params)
	ActivityWineAwardPreviewWindow.super.ctor(self, name, params)

	self.params = params
end

function ActivityWineAwardPreviewWindow:initWindow()
	ActivityWineAwardPreviewWindow.super.initWindow(self)
	self:getUIComponent()
	self:initLayout()
	self:register()
	self:initData()
end

function ActivityWineAwardPreviewWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainNode = winTrans:NodeByName("mainNode").gameObject
	self.mainGroup = mainNode:NodeByName("mainGroup").gameObject
	self.awardScroller = mainNode:NodeByName("mainGroup/scroller").gameObject
	self.awardScroller_scroller = mainNode:ComponentByName("mainGroup/scroller", typeof(UIScrollView))
	self.awardScroller_uiPanel = mainNode:ComponentByName("mainGroup/scroller", typeof(UIPanel))
	self.awardContainer = mainNode:NodeByName("mainGroup/scroller/container").gameObject
	self.awardContainer_MultiRowWrapContent = mainNode:ComponentByName("mainGroup/scroller/container", typeof(MultiRowWrapContent))
	self.labelWinTitle_ = mainNode:ComponentByName("mainGroup/labelTitle", typeof(UILabel))
	self.closeBtn = mainNode:NodeByName("mainGroup/closeBtn").gameObject
	self.icon_root = mainNode:NodeByName("mainGroup/icon_root").gameObject
	self.awardMultiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.awardScroller_scroller, self.awardContainer_MultiRowWrapContent, self.icon_root, ActivityWineAwardPreviewItem, self)
end

function ActivityWineAwardPreviewWindow:initLayout()
	self.labelWinTitle_.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	local widget = self.mainGroup:GetComponent(typeof(UIWidget))

	if #self.params > 15 then
		widget.height = 680
	else
		widget.height = 550
	end
end

function ActivityWineAwardPreviewWindow:register()
	ActivityWineAwardPreviewWindow.super.register(self)
	self:setCloseBtn(self.closeBtn)
end

function ActivityWineAwardPreviewWindow:initData()
	self.awardMultiWrap_:setInfos(self.params, {})
	self:waitForFrame(1, function ()
		self.awardScroller_scroller:ResetPosition()
	end)
end

function ActivityWineAwardPreviewItem:ctor(parentGo, parent)
	self.parent_ = parent

	ActivityWineAwardPreviewItem.super.ctor(self, parentGo)
end

function ActivityWineAwardPreviewItem:getIconRoot()
	return self.go
end

function ActivityWineAwardPreviewItem:initUI()
	ActivityWineAwardPreviewItem.super.initUI(self)

	self.labelNum_ = self.go:ComponentByName("labelNum", typeof(UILabel))
	UIEventListener.Get(self.go).onClick = handler(self, self.onClick)
end

function ActivityWineAwardPreviewItem:update(_, _, info)
	if not info or not info.items then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data_ = info
	self.labelNum_.text = self.data_.cur_num .. "/" .. self.data_.num
	self.labelNum_.color = Color.New2(1583978239)
	self.num_ = info.hasGotNum
	local params = {
		noClick = true,
		uiRoot = self.go,
		itemID = info.items[1],
		num = info.items[2]
	}

	if not self.itemIcon_ then
		self.itemIcon_ = xyd.getItemIcon(params)
	else
		NGUITools.Destroy(self.itemIcon_.go)

		self.itemIcon_ = xyd.getItemIcon(params)
	end

	if self.data_.cur_num == 0 then
		xyd.applyChildrenGrey(self.itemIcon_.go)

		self.labelNum_.color = Color.New2(3422556671.0)
	else
		xyd.applyChildrenOrigin(self.itemIcon_.go)
	end
end

function ActivityWineAwardPreviewItem:getInfo()
	return self.data_
end

function ActivityWineAwardPreviewItem:onClick()
	local params = {
		notShowGetWayBtn = true,
		show_has_num = true,
		itemID = self.data_.items[1],
		itemNum = self.data_.items[2] or 0,
		wndType = xyd.ItemTipsWndType.ACTIVITY
	}

	xyd.WindowManager.get():openWindow("item_tips_window", params)
end

function ActivityWineAwardPreviewItem:refreshNum()
	local isChoosing = self.parent_:isIconSelected(self.data_.id)

	if isChoosing then
		self.data_.hasGotNum = self.data_.hasGotNum - 1
	else
		self.data_.hasGotNum = self.data_.hasGotNum + 1
	end

	self.labelNum_.text = self.data_.limit - self.data_.hasGotNum .. "/" .. self.data_.limit
end

function ActivityWineAwardPreviewItem:getData()
	return self.data_
end

return ActivityWineAwardPreviewWindow
