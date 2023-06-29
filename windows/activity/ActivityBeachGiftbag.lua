local ActivityContent = import(".ActivityContent")
local ActivityBeachGiftbag = class("ActivityBeachGiftbag", ActivityContent)
local ActivityBeachGiftbagItem = class("ActivityBeachGiftbagItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")

function ActivityBeachGiftbag:ctor(parentGO, params)
	ActivityBeachGiftbag.super.ctor(self, parentGO, params)
end

function ActivityBeachGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/activity_beach_giftbag"
end

function ActivityBeachGiftbag:initUI()
	self:getUIComponent()
	ActivityBeachGiftbag.super.initUI(self)
	self:initUIComponent()
	self:onRegister()
	self:updateItems()

	local duration = self.activityData:getUpdateTime() - xyd.getServerTime()

	if duration > 604800 then
		xyd.db.misc:setValue({
			value = 1,
			key = "ActivityBeachGiftbagRedMark_week1" .. self.activityData:getUpdateTime()
		})
	else
		xyd.db.misc:setValue({
			value = 1,
			key = "ActivityBeachGiftbagRedMark_week2" .. self.activityData:getUpdateTime()
		})
	end
end

function ActivityBeachGiftbag:getUIComponent()
	local go = self.go
	self.textImg_ = go:ComponentByName("textImg_", typeof(UISprite))
	self.week1TimeGroup_ = go:NodeByName("timeGroup_/week1TimeGroup_").gameObject
	self.refreshLabel_ = self.week1TimeGroup_:ComponentByName("timeGroup_/refreshLabel_", typeof(UILabel))
	self.week1TimeLabel_ = self.week1TimeGroup_:ComponentByName("timeGroup_/timeLabel_", typeof(UILabel))
	self.week2TimeGroup_ = go:NodeByName("timeGroup_/week2TimeGroup_").gameObject
	self.endLabel_ = self.week2TimeGroup_:ComponentByName("timeGroup_/endLabel_", typeof(UILabel))
	self.week2TimeLabel_ = self.week2TimeGroup_:ComponentByName("timeGroup_/timeLabel_", typeof(UILabel))
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.specialItemIcon_ = go:ComponentByName("specialItemGroup_/icon_", typeof(UISprite))
	self.specialItemClickArea_ = go:NodeByName("specialItemGroup_/clickArea_").gameObject
	self.specialItemNumLabel_ = go:ComponentByName("specialItemGroup_/numLabel_", typeof(UILabel))
	self.specialItemLimitLabel_ = go:ComponentByName("specialItemGroup_/limitLabel_", typeof(UILabel))
	self.specialItemExpLabel_ = go:ComponentByName("specialItemGroup_/expLabel_", typeof(UILabel))
	self.specialItemChargeBtn_ = go:NodeByName("specialItemGroup_/chargeBtn_").gameObject
	self.specialItemChargeBtnLabel_ = self.specialItemChargeBtn_:ComponentByName("button_label", typeof(UILabel))
	self.scrollView = go:ComponentByName("contentGroup_/itemScroller_", typeof(UIScrollView))
	self.itemGroup_ = go:NodeByName("contentGroup_/itemScroller_/itemGroup_").gameObject
	local wrapContent_ = self.itemGroup_:GetComponent(typeof(UIWrapContent))
	self.scrollerItem = go:NodeByName("activity_beach_giftbag_item").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent_, self.scrollerItem, ActivityBeachGiftbagItem, self)
	self.effect_ = go:NodeByName("effect_").gameObject
end

function ActivityBeachGiftbag:initUIComponent()
	xyd.setUISpriteAsync(self.textImg_, nil, "activity_beach_giftbag_logo_" .. xyd.Global.lang, nil, , true)

	self.refreshLabel_.text = __("ACTIVITY_BEACH_ISLAND_TEXT02")
	self.endLabel_.text = __("END")
	local duration = self.activityData:getUpdateTime() - xyd.getServerTime()

	CountDown.new(self.week1TimeLabel_, {
		duration = duration - 604800
	})
	CountDown.new(self.week2TimeLabel_, {
		duration = duration
	})
	self.week1TimeGroup_:ComponentByName("timeGroup_", typeof(UILayout)):Reposition()
	self.week2TimeGroup_:ComponentByName("timeGroup_", typeof(UILayout)):Reposition()

	if duration > 604800 then
		self.week1TimeGroup_:SetActive(true)
		self.week2TimeGroup_:SetActive(false)
	else
		self.week1TimeGroup_:SetActive(false)
		self.week2TimeGroup_:SetActive(true)
	end

	local effect = xyd.Spine.new(self.effect_)

	effect:setInfo("yunmu_pifu02_lihui01", function ()
		effect:SetLocalPosition(-185, -1030, 0)
		effect:SetLocalScale(-0.65, 0.65, 1)
		effect:play("animation", 0)
	end)

	if xyd.Global.lang == "de_de" then
		self.week2TimeGroup_:X(-25)
	end
end

function ActivityBeachGiftbag:onRegister()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.updateItems))

	UIEventListener.Get(self.specialItemClickArea_.gameObject).onClick = handler(self, function ()
		local params = {
			notShowGetWayBtn = true,
			showGetWays = false,
			itemID = 358,
			show_has_num = true,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end)
	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_BEACH_GIFTBAG_HELP"
		})
	end)
end

function ActivityBeachGiftbag:updateItems()
	self:updateSpecialItem()
	self:updateCommonItems()
end

function ActivityBeachGiftbag:updateSpecialItem()
	local giftbagID = xyd.tables.activityTable:getGiftBag(self.id)[1]
	local limitTimes = self.activityData.detail.charges[1].limit_times - self.activityData.detail.charges[1].buy_times

	xyd.setUISpriteAsync(self.specialItemIcon_, nil, "icon_358", nil, , true)

	self.specialItemNumLabel_.text = "X100"
	self.specialItemLimitLabel_.text = __("BUY_GIFTBAG_LIMIT") .. tostring(limitTimes)
	self.specialItemExpLabel_.text = "+" .. xyd.tables.giftBagTable:getVipExp(giftbagID) .. " VIP EXP"
	self.specialItemChargeBtnLabel_.text = xyd.tables.giftBagTextTable:getCurrency(giftbagID) .. " " .. xyd.tables.giftBagTextTable:getCharge(giftbagID)

	if limitTimes <= 0 then
		xyd.applyChildrenGrey(self.specialItemChargeBtn_)

		self.specialItemChargeBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	end

	UIEventListener.Get(self.specialItemChargeBtn_).onClick = function ()
		xyd.SdkManager.get():showPayment(giftbagID)
	end
end

function ActivityBeachGiftbag:updateCommonItems()
	local collection = {}
	local giftbagIDs = xyd.tables.activityTable:getGiftBag(self.id)

	for i = 2, #giftbagIDs do
		table.insert(collection, {
			giftbagID = giftbagIDs[i],
			limitTimes = self.activityData.detail.charges[i].limit_times - self.activityData.detail.charges[i].buy_times
		})
	end

	self.wrapContent:setInfos(collection, {})
	self.scrollView:ResetPosition()
end

function ActivityBeachGiftbagItem:ctor(go, parent)
	ActivityBeachGiftbagItem.super.ctor(self, go, parent)
end

function ActivityBeachGiftbagItem:initUI()
	local go = self.go
	self.awardGroup_ = go:NodeByName("awardGroup_").gameObject
	self.layout = self.awardGroup_:GetComponent(typeof(UILayout))
	self.vipLabel_ = go:ComponentByName("vipLabel_", typeof(UILabel))
	self.expLabel_ = go:ComponentByName("expLabel_", typeof(UILabel))
	self.limitLabel_ = go:ComponentByName("limitLabel_", typeof(UILabel))
	self.chargeBtn_ = go:NodeByName("chargeBtn_").gameObject
	self.chargeBtnLabel_ = self.chargeBtn_:ComponentByName("button_label", typeof(UILabel))
end

function ActivityBeachGiftbagItem:updateInfo()
	local giftbagID = self.data.giftbagID
	local limitTimes = self.data.limitTimes
	local awards = xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(giftbagID))

	NGUITools.DestroyChildren(self.awardGroup_.transform)

	for i = 1, #awards do
		local award = awards[i]

		if award[1] ~= xyd.ItemID.VIP_EXP then
			local icon = xyd.getItemIcon({
				show_has_num = true,
				notShowGetWayBtn = true,
				scale = 0.7037037037037037,
				uiRoot = self.awardGroup_,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})

			icon:AddUIDragScrollView()
		end
	end

	self.layout:Reposition()

	self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT") .. tostring(limitTimes)
	self.vipLabel_.text = "VIP EXP"
	self.expLabel_.text = xyd.tables.giftBagTable:getVipExp(giftbagID)
	self.chargeBtnLabel_.text = xyd.tables.giftBagTextTable:getCurrency(giftbagID) .. " " .. xyd.tables.giftBagTextTable:getCharge(giftbagID)

	if limitTimes <= 0 then
		xyd.applyChildrenGrey(self.chargeBtn_)

		self.chargeBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	end

	UIEventListener.Get(self.chargeBtn_).onClick = function ()
		xyd.SdkManager.get():showPayment(giftbagID)
	end
end

return ActivityBeachGiftbag
