local ActivityFairyTaleGiftPreviewWindow = class("ActivityFairyTaleGiftPreviewWindow", import(".BaseWindow"))
local fairyAwardItem = class("fairyAwardItem", import("app.components.CopyComponent"))

function ActivityFairyTaleGiftPreviewWindow:ctor(name, params)
	ActivityFairyTaleGiftPreviewWindow.super.ctor(self, name, params)
end

function ActivityFairyTaleGiftPreviewWindow:initWindow()
	ActivityFairyTaleGiftPreviewWindow.super.initWindow(self)
	self:getComponent()
	self:refreshList()
	self:regisetr()

	self.winTitle_.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	self.labelTips_.text = __("FAIRY_TALE_GIFT_MAIL_SEND")
end

function ActivityFairyTaleGiftPreviewWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.winTitle_ = winTrans:ComponentByName("winTitle", typeof(UILabel))
	self.scrollView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("scrollView/grid", typeof(MultiRowWrapContent))
	self.labelTips_ = winTrans:ComponentByName("labelTips", typeof(UILabel))
	local awardItemRoot = self.window_:NodeByName("awardItem").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, awardItemRoot, fairyAwardItem, self)
end

function ActivityFairyTaleGiftPreviewWindow:regisetr()
	ActivityFairyTaleGiftPreviewWindow.super.register(self)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ActivityFairyTaleGiftPreviewWindow:refreshList()
	local ids = xyd.tables.activityFairyTaleLevelTable:getIds()
	local tempList = {}

	for i = 2, #ids do
		local params = {
			id = ids[i],
			awards = xyd.tables.activityFairyTaleLevelTable:getAwards(ids[i])
		}

		table.insert(tempList, params)
	end

	self.awardItemInfoList_ = tempList

	self.multiWrap_:setInfos(self.awardItemInfoList_, {})
end

function fairyAwardItem:ctor(parentGo, parent)
	self.parent_ = parent

	fairyAwardItem.super.ctor(self, parentGo)
end

function fairyAwardItem:initUI()
	fairyAwardItem.super.initUI(self)
	self:getComponent()
end

function fairyAwardItem:getComponent()
	self.levNum_ = self.go:ComponentByName("levGroup/levNum", typeof(UILabel))
	self.awardsGroup_ = self.go:ComponentByName("itemsGroup", typeof(UIGrid))
end

function fairyAwardItem:update(_, _, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.info_ = info
	self.levNum_.text = self.info_.id
	local params = {
		uiRoot = self.awardsGroup_.gameObject,
		itemID = self.info_.awards[1],
		num = self.info_.awards[2]
	}

	if not self.awardItemList_ then
		self.awardItemList_ = xyd.getItemIcon(params)
	else
		self.awardItemList_:setInfo(params)
	end
end

return ActivityFairyTaleGiftPreviewWindow
