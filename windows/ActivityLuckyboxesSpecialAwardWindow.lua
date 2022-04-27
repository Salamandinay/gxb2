local BaseWindow = import(".BaseWindow")
local ActivityLuckyboxesSpecialAwardWindow = class("ActivityLuckyboxesSpecialAwardWindow", BaseWindow)
local ActivityLuckyboxesSpecialAwardItem = class("ActivityLuckyboxesSpecialAwardItem", import("app.common.ui.FixedWrapContentItem"))
local AdvanceIcon = import("app.components.AdvanceIcon")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ItemTable = xyd.tables.itemTable

function ActivityLuckyboxesSpecialAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LUCKYBOXES)
end

function ActivityLuckyboxesSpecialAwardWindow:getPrefabPath()
	return "Prefabs/Windows/activity_luckyboxes_special_award_window"
end

function ActivityLuckyboxesSpecialAwardWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:Register()
	self:initUIComponent()
	self:initData()
end

function ActivityLuckyboxesSpecialAwardWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelWinTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.awardContentGroup = self.groupAction:NodeByName("awardContentGroup").gameObject
	self.bg_ = self.awardContentGroup:ComponentByName("bg_", typeof(UISprite))
	self.drag = self.awardContentGroup:NodeByName("drag").gameObject
	self.scroller = self.awardContentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.item = self.scroller:NodeByName("item").gameObject
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.itemGroup_layout = self.scroller:ComponentByName("itemGroup", typeof(UILayout))
end

function ActivityLuckyboxesSpecialAwardWindow:addTitle()
	self.labelWinTitle.text = __("ACTIVITY_LUCKYBOXES_TEXT09")
end

function ActivityLuckyboxesSpecialAwardWindow:initUIComponent()
end

function ActivityLuckyboxesSpecialAwardWindow:initData()
	self.data = {}
	local ids = xyd.tables.activityLuckyboxesAwardTable:getIDs()
	self.maxId = #ids

	for i = 1, #ids do
		local id = tonumber(i)
		local title = __("ACTIVITY_LUCKYBOXES_TEXT10", id)
		local awards = self.activityData:getSpecialAwardList()[id]

		table.insert(self.data, {
			id = tonumber(id),
			title = title,
			awards = awards
		})
	end

	local function sort_func(a, b)
		return a.id < b.id
	end

	table.sort(self.data, sort_func)

	if self.wrapContent == nil then
		local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
		self.wrapContent = FixedWrapContent.new(self.scroller, wrapContent, self.item, ActivityLuckyboxesSpecialAwardItem, self)
	end

	self.wrapContent:setInfos(self.data, {})
end

function ActivityLuckyboxesSpecialAwardWindow:Register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow("activity_luckyboxes_special_award_window")
	end
end

function ActivityLuckyboxesSpecialAwardItem:ctor(go, parent)
	ActivityLuckyboxesSpecialAwardItem.super.ctor(self, go, parent)
end

function ActivityLuckyboxesSpecialAwardItem:initUI()
	local go = self.go
	self.labelIndex = self.go:ComponentByName("labelIndex", typeof(UILabel))
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject
	self.itemGroup_layout = self.go:ComponentByName("itemGroup", typeof(UILayout))
	self.icons = {}
end

function ActivityLuckyboxesSpecialAwardItem:updateInfo()
	self.id = self.data.id
	self.awards = self.data.awards
	self.title = self.data.title
	self.labelIndex.text = self.title

	for i = 1, #self.awards do
		local params = {
			show_has_num = false,
			scale = 0.6481481481481481,
			notShowGetWayBtn = true,
			uiRoot = self.itemGroup,
			itemID = self.awards[i][1],
			num = self.awards[i][2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.parent.scroller
		}

		if self.icons[i] == nil then
			params.preGenarate = true
			self.icons[i] = AdvanceIcon.new(params)
		else
			self.icons[i]:setInfo(params)
		end

		self.icons[i]:setChoose(self.data.awards[i].awarded)
	end

	self.itemGroup_layout:Reposition()
end

return ActivityLuckyboxesSpecialAwardWindow
