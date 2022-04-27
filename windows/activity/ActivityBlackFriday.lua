local ActivityContent = import(".ActivityContent")
local ActivityBlackFriday = class("ActivityBlackFriday", ActivityContent)
local CountDown = import("app.components.CountDown")

function ActivityBlackFriday:ctor(parentGo, params)
	ActivityBlackFriday.super.ctor(self, parentGo, params)
end

function ActivityBlackFriday:getPrefabPath()
	return "Prefabs/Windows/activity/activity_black_friday"
end

function ActivityBlackFriday:resizeToParent()
	ActivityBlackFriday.super.resizeToParent(self)
	self:resizePosY(self.topGroup, 5, -50)
	self:resizePosY(self.midGroup, -205, -301)
	self:resizePosY(self.bottomGroup, -535, -631)
end

function ActivityBlackFriday:initUI()
	self:getUIComponent()
	ActivityBlackFriday.super.initUI(self)
	self:initLayout()
end

function ActivityBlackFriday:getUIComponent()
	local go = self.go
	self.bg = go:ComponentByName("bg", typeof(UITexture))
	self.topGroup = go:NodeByName("topGroup").gameObject
	self.textImg = self.topGroup:ComponentByName("textImg", typeof(UISprite))
	self.timeGroup = self.topGroup:NodeByName("timeGroup").gameObject
	self.labelTime = self.timeGroup:ComponentByName("labelTime", typeof(UILabel))
	self.labelEnd = self.timeGroup:ComponentByName("labelEnd", typeof(UILabel))
	self.midGroup = go:NodeByName("midGroup").gameObject
	self.midBg = self.midGroup:ComponentByName("midBg", typeof(UISprite))
	self.midItemGroup1 = self.midGroup:NodeByName("midItemGroup1").gameObject
	self.midItemGroup2 = self.midGroup:NodeByName("midItemGroup2").gameObject
	self.midLabel = self.midGroup:ComponentByName("midLabel", typeof(UILabel))
	self.midVipLabel = self.midGroup:ComponentByName("midVipLabel", typeof(UILabel))
	self.midLimitLabel = self.midGroup:ComponentByName("midLimitLabel", typeof(UILabel))
	self.midBtn = self.midGroup:NodeByName("midBtn").gameObject
	self.midBtnLabel = self.midBtn:ComponentByName("midBtnLabel", typeof(UILabel))
	self.midBtnLineLabel = self.midBtn:ComponentByName("midBtnLineLabel", typeof(UILabel))
	self.bottomGroup = go:NodeByName("bottomGroup").gameObject
	self.bottomBg = self.bottomGroup:ComponentByName("bottomBg", typeof(UISprite))
	self.bottomItemGroup1 = self.bottomGroup:NodeByName("bottomItemGroup1").gameObject
	self.bottomItemGroup2 = self.bottomGroup:NodeByName("bottomItemGroup2").gameObject
	self.bottomLabel = self.bottomGroup:ComponentByName("bottomLabel", typeof(UILabel))
	self.bottomVipLabel = self.bottomGroup:ComponentByName("bottomVipLabel", typeof(UILabel))
	self.bottomLimitLabel = self.bottomGroup:ComponentByName("bottomLimitLabel", typeof(UILabel))
	self.bottomBtn = self.bottomGroup:NodeByName("bottomBtn").gameObject
	self.bottomBtnLabel = self.bottomBtn:ComponentByName("bottomBtnLabel", typeof(UILabel))
	self.bottomBtnLineLabel = self.bottomBtn:ComponentByName("bottomBtnLineLabel", typeof(UILabel))
end

function ActivityBlackFriday:initLayout()
	self:initTexture()
	self:initLabel()
	self:initItems()
	self:updateStatus()
	self:registerEvent()
end

function ActivityBlackFriday:initTexture()
	xyd.setUISpriteAsync(self.textImg, nil, "activity_black_new_logo_" .. xyd.Global.lang, nil, , true)
end

function ActivityBlackFriday:initLabel()
	local activityData = self.activityData
	local charge1 = activityData.detail.charges[1]
	local charge2 = activityData.detail.charges[2]

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		CountDown.new(self.labelTime, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})

		self.labelEnd.text = __("END_TEXT")

		self.timeGroup:GetComponent(typeof(UILayout)):Reposition()
	else
		self.labelTime:SetActive(false)
		self.labelEnd:SetActive(false)
	end

	self.midLabel.text = __("BLACK_FRIDAY_GIFTBAG_DISCOUNT")
	self.bottomLabel.text = __("BLACK_FRIDAY_GIFTBAG_DISCOUNT")
	self.midVipLabel.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(charge1.table_id)) .. " VIP EXP"
	self.bottomVipLabel.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(charge2.table_id)) .. " VIP EXP"
	self.midBtnLabel.text = tostring(xyd.tables.giftBagTextTable:getCurrency(charge1.table_id)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(charge1.table_id))
	self.bottomBtnLabel.text = tostring(xyd.tables.giftBagTextTable:getCurrency(charge2.table_id)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(charge2.table_id))
	self.midBtnLineLabel.text = "[s]" .. __("BLACK_FRIDAY_GIFTBAG_PRICE1") .. "[/s]"
	self.bottomBtnLineLabel.text = "[s]" .. __("BLACK_FRIDAY_GIFTBAG_PRICE2") .. "[/s]"

	if xyd.Global.lang == "en_en" then
		self.bottomBtnLineLabel.fontSize = 15
		self.midBtnLineLabel.fontSize = 15
	end

	if xyd.Global.lang == "ja_jp" then
		self.midVipLabel:X(-145)
		self.midLimitLabel:X(47)
		self.bottomVipLabel:X(-145)
		self.bottomLimitLabel:X(47)
		self.midBtnLineLabel:SetActive(false)
		self.bottomBtnLineLabel:SetActive(false)
		self.midBtnLabel:Y(0)
		self.bottomBtnLabel:Y(0)
	end

	if xyd.Global.lang == "fr_fr" then
		self.midVipLabel:X(-145)
		self.midLimitLabel:X(47)
		self.bottomVipLabel:X(-145)
		self.bottomLimitLabel:X(47)
	end
end

function ActivityBlackFriday:initItems()
	local activityData = self.activityData
	local tableId1 = activityData.detail.charges[1].table_id
	local tableId2 = activityData.detail.charges[2].table_id
	local awards1 = xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(tableId1))
	local awards2 = xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(tableId2))
	local midIconNum = 0
	local bottomIconNum = 0

	for i, data in ipairs(awards1) do
		if data[1] ~= xyd.ItemID.VIP_EXP then
			local params = {
				show_has_num = true,
				scale = 0.7037037037037037,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = midIconNum < 4 and self.midItemGroup1 or self.midItemGroup2
			}

			xyd.getItemIcon(params)

			midIconNum = midIconNum + 1
		end
	end

	for i, data in ipairs(awards2) do
		if data[1] ~= xyd.ItemID.VIP_EXP then
			local params = {
				show_has_num = true,
				scale = 0.7037037037037037,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = bottomIconNum < 4 and self.bottomItemGroup1 or self.bottomItemGroup2
			}

			xyd.getItemIcon(params)

			bottomIconNum = bottomIconNum + 1
		end
	end

	self.midItemGroup1:GetComponent(typeof(UILayout)):Reposition()
	self.midItemGroup2:GetComponent(typeof(UILayout)):Reposition()
	self.bottomItemGroup1:GetComponent(typeof(UILayout)):Reposition()
	self.bottomItemGroup2:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityBlackFriday:updateStatus()
	local activityData = self.activityData
	local charge1 = activityData.detail.charges[1]
	local charge2 = activityData.detail.charges[2]
	local buyTimes1 = charge1.buy_times
	local buyTimes2 = charge2.buy_times
	local limitTimes1 = xyd.tables.giftBagTable:getBuyLimit(charge1.table_id)
	local limitTimes2 = xyd.tables.giftBagTable:getBuyLimit(charge2.table_id)

	if limitTimes1 <= buyTimes1 then
		xyd.setTouchEnable(self.midBtn, false)
		xyd.applyChildrenGrey(self.midBtn)
	end

	if limitTimes2 <= buyTimes2 then
		xyd.setTouchEnable(self.bottomBtn, false)
		xyd.applyChildrenGrey(self.bottomBtn)
	end

	self.midLimitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(limitTimes1 - buyTimes1))
	self.bottomLimitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(limitTimes2 - buyTimes2))
end

function ActivityBlackFriday:registerEvent()
	UIEventListener.Get(self.midBtn).onClick = function ()
		xyd.SdkManager.get():showPayment(self.activityData.detail.charges[1].table_id)
	end

	UIEventListener.Get(self.bottomBtn).onClick = function ()
		xyd.SdkManager.get():showPayment(self.activityData.detail.charges[2].table_id)
	end

	self.eventProxyInner_:addEventListener(xyd.event.RECHARGE, handler(self, function (event)
		self:updateStatus()
	end))
end

return ActivityBlackFriday
