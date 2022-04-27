local MonthCardEverydayAwardWindow = class("MonthCardEverydayAwardWindow", import(".BaseWindow"))
local VipItem = class("VipItem", import("app.common.ui.FixedWrapContentItem"))
local PngNum = require("app.components.PngNum")

function MonthCardEverydayAwardWindow:ctor(name, params)
	MonthCardEverydayAwardWindow.super.ctor(self, name, params)
end

function MonthCardEverydayAwardWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function MonthCardEverydayAwardWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel = groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.scrollView = groupAction:ComponentByName("scrollView", typeof(UIScrollView))
	local itemRoot = groupAction:NodeByName("itemRoot").gameObject
	local wrapContent = self.scrollView:ComponentByName("groupContent", typeof(UIWrapContent))
	self.wrapContent = import("app.common.ui.FixedWrapContent").new(self.scrollView, wrapContent, itemRoot, VipItem, self)
end

function MonthCardEverydayAwardWindow:layout()
	self.titleLabel.text = __("MONTH_CARD_TEXT003")
	self.vipLev = xyd.models.backpack:getVipLev()
	local maxLev = xyd.models.backpack:getMaxVipLev()
	local list = {}

	for i = 2, maxLev do
		table.insert(list, i)
	end

	self.wrapContent:setInfos(list)

	local delta = 0

	if self.vipLev > 2 and self.vipLev <= 10 then
		delta = (self.vipLev - 2) * 107
	elseif self.vipLev > 10 then
		delta = 927
	end

	if delta > 0 then
		self:waitForFrame(1, function ()
			self.scrollView:MoveRelative(Vector3(0, delta, 0))
		end)
	end
end

function MonthCardEverydayAwardWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end
end

function VipItem:ctor(go, parent)
	VipItem.super.ctor(self, go, parent)
end

function VipItem:initUI()
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.awardGroup = self.go:NodeByName("awardGroup").gameObject
	local vipNum = self.go:NodeByName("vipGroup/vipNum").gameObject
	self.vipNum = PngNum.new(vipNum)
end

function VipItem:updateInfo()
	if self.data == self.parent.vipLev then
		xyd.setUISpriteAsync(self.bg, nil, "my_viplev_bg")
	else
		xyd.setUISpriteAsync(self.bg, nil, "9gongge17")
	end

	self.vipNum:setInfo({
		iconName = "player_vip",
		num = self.data
	})

	local awards = xyd.tables.vipTable:split2Cost(self.data, "month_card_awards_show", "|#")

	NGUITools.DestroyChildren(self.awardGroup.transform)

	for _, data in ipairs(awards) do
		xyd.getItemIcon({
			scale = 0.7037037037037037,
			uiRoot = self.awardGroup,
			itemID = data[1],
			num = data[2],
			dragScrollView = self.parent.scrollView
		})
	end

	self.awardGroup:GetComponent(typeof(UIGrid)):Reposition()
end

return MonthCardEverydayAwardWindow
