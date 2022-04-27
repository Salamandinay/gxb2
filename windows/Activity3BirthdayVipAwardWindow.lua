local BaseWindow = import(".BaseWindow")
local Activity3BirthdayVipAwardWindow = class("Activity3BirthdayVipAwardWindow", BaseWindow)
local Activity3BirthdayVipAwardItem = class("Activity3BirthdayVipAwardItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")
local PngNum = import("app.components.PngNum")
local cjson = require("cjson")
local Activity3BirthdayVipAwardTable = xyd.tables.activity3BirthdayVipAwardTable

function Activity3BirthdayVipAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function Activity3BirthdayVipAwardWindow:initWindow()
	Activity3BirthdayVipAwardWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:initContent()
	self:register()
end

function Activity3BirthdayVipAwardWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle_ = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.tipLabel_ = groupAction:ComponentByName("tipLabel_", typeof(UILabel))
	local groupCountDown = groupAction:NodeByName("groupCountDown").gameObject
	self.groupClock = groupCountDown:NodeByName("groupClock").gameObject
	self.imgClock_ = self.groupClock:ComponentByName("imgClock_", typeof(UISprite))
	self.labelTime_ = groupCountDown:ComponentByName("labelTime_", typeof(UILabel))
	self.scrollView = groupAction:ComponentByName("mainGroup/itemScroller", typeof(UIScrollView))
	self.itemGroup = groupAction:NodeByName("mainGroup/itemScroller/itemGroup").gameObject
	self.scrollerItem = winTrans:NodeByName("activity_3birthday_vip_award_item").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.scrollerItem, Activity3BirthdayVipAwardItem, self)
end

function Activity3BirthdayVipAwardWindow:initUIComponent()
	self.labelTitle_.text = __("ACTIVITY_3BIRTHDAY_VIP_TEXT04")
	self.tipLabel_.text = __("ACTIVITY_3BIRTHDAY_VIP_TEXT05")

	CountDown.new(self.labelTime_, {
		duration = xyd.getTomorrowTime() - xyd.getServerTime()
	})

	self.clockEffect = xyd.Spine.new(self.groupClock)

	self.clockEffect:setInfo("fx_ui_shizhong", function ()
		self.clockEffect:setRenderTarget(self.imgClock_, 1)
		self.clockEffect:play("texiao1", 0, 1, nil, true)
	end)
end

function Activity3BirthdayVipAwardWindow:initContent()
	local ids = Activity3BirthdayVipAwardTable:getIds()
	local collection = {}

	for i, id in ipairs(ids) do
		table.insert(collection, {
			id = id
		})
	end

	self.wrapContent:setInfos(collection, {})
	self.scrollView:ResetPosition()
end

function Activity3BirthdayVipAwardWindow:register()
	Activity3BirthdayVipAwardWindow.super.register(self)
end

function Activity3BirthdayVipAwardItem:ctor(go, parent)
	Activity3BirthdayVipAwardItem.super.ctor(self, go, parent)
end

function Activity3BirthdayVipAwardItem:initUI()
	local go = self.go
	self.vipLevel_ = go:NodeByName("vipGroup/vipLevel_").gameObject
	self.awardGroup = go:NodeByName("awardGroup").gameObject
	self.layout_ = self.awardGroup:GetComponent(typeof(UILayout))
end

function Activity3BirthdayVipAwardItem:updateInfo()
	self.id = self.data.id
	self.vipLev = Activity3BirthdayVipAwardTable:getVipLevel(self.id)

	NGUITools.DestroyChildren(self.vipLevel_.transform)

	self.pageVipNum_ = PngNum.new(self.vipLevel_)

	self.pageVipNum_:setInfo({
		iconName = "player_vip",
		num = self.vipLev
	})

	local awards = Activity3BirthdayVipAwardTable:getdailyAwards(self.id)

	NGUITools.DestroyChildren(self.awardGroup.transform)

	for i = 1, #awards do
		local award = awards[i]

		xyd.getItemIcon({
			show_has_num = true,
			scale = 0.7037037037037037,
			uiRoot = self.awardGroup,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.parent.scrollView
		})
	end

	self.layout_:Reposition()
end

return Activity3BirthdayVipAwardWindow
