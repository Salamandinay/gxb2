local ActivityContent = import(".ActivityContent")
local EasterGiftbag = class("EasterGiftbag", ActivityContent)
local CountDown = import("app.components.CountDown")

function EasterGiftbag:ctor(parentGo, params)
	EasterGiftbag.super.ctor(self, parentGo, params)
end

function EasterGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/easter_giftbag"
end

function EasterGiftbag:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)
	xyd.setUISpriteAsync(self.titleImg_, nil, "easter_giftbag_logo_" .. xyd.Global.lang)

	self.desLabel_.text = __("ACTIVITY_GERMANY_GIFTBAG_TEXT")
	self.endLabel_.text = __("END")

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel_, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timerLabel:SetActive(false)
	end

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "ja_jp" then
		self.desLabel_.height = 76
		self.desLabel_.fontSize = 24

		self.desLabel_:Y(27)
	end

	self:updateStatus()
	self:initItems()
	self:register()
end

function EasterGiftbag:getUIComponent()
	local go = self.go
	self.bg1 = go:NodeByName("bg1").gameObject
	self.bg2 = go:NodeByName("bg2").gameObject
	self.titleImg_ = go:ComponentByName("titleImg_", typeof(UISprite))
	self.groupTime = go:NodeByName("titleImg_/groupTime").gameObject
	self.groupDes = go:NodeByName("groupDes").gameObject
	self.timeLabel_ = go:ComponentByName("titleImg_/groupTime/timeLabel_", typeof(UILabel))
	self.endLabel_ = go:ComponentByName("titleImg_/groupTime/endLabel_", typeof(UILabel))
	self.desLabel_ = go:ComponentByName("groupDes/desLabel_", typeof(UILabel))
	self.groupBottom0 = go:NodeByName("groupBottom0").gameObject
	self.purchaseBtn0 = go:NodeByName("groupBottom0/purchaseBtn0").gameObject
	self.purchaseBtnLabel0 = self.purchaseBtn0:ComponentByName("button_label", typeof(UILabel))
	self.limitLabel01 = go:ComponentByName("groupBottom0/limit/label1", typeof(UILabel))
	self.limitLabel02 = go:ComponentByName("groupBottom0/limit/label2", typeof(UILabel))
	self.vipLabel01 = go:ComponentByName("groupBottom0/vip/label1", typeof(UILabel))
	self.vipLabel02 = go:ComponentByName("groupBottom0/vip/label2", typeof(UILabel))
	self.itemGroup02 = go:NodeByName("groupBottom0/itemGroup2").gameObject
	self.itemGroup031 = go:NodeByName("groupBottom0/itemGroup3/itemGroup1").gameObject
	self.itemGroup032 = go:NodeByName("groupBottom0/itemGroup3/itemGroup2").gameObject
	self.groupBottom1 = go:NodeByName("groupBottom1").gameObject
	self.purchaseBtn1 = go:NodeByName("groupBottom1/purchaseBtn0").gameObject
	self.purchaseBtnLabel1 = self.purchaseBtn1:ComponentByName("button_label", typeof(UILabel))
	self.limitLabel11 = go:ComponentByName("groupBottom1/limit/label1", typeof(UILabel))
	self.limitLabel12 = go:ComponentByName("groupBottom1/limit/label2", typeof(UILabel))
	self.vipLabel11 = go:ComponentByName("groupBottom1/vip/label1", typeof(UILabel))
	self.vipLabel12 = go:ComponentByName("groupBottom1/vip/label2", typeof(UILabel))
	self.itemGroup12 = go:NodeByName("groupBottom1/itemGroup2").gameObject
	self.itemGroup131 = go:NodeByName("groupBottom1/itemGroup3/itemGroup1").gameObject
	self.itemGroup132 = go:NodeByName("groupBottom1/itemGroup3/itemGroup2").gameObject
end

function EasterGiftbag:initItems()
	local data = self.activityData

	for i = 1, #data.detail.charges do
		local awards = self:getAwards(data.detail.charges[i].table_id)
		local filteredAwards = {}

		for j = 1, #awards do
			local award = awards[j]

			if award[1] ~= xyd.ItemID.VIP_EXP then
				table.insert(filteredAwards, award)
			end
		end

		if #filteredAwards == 2 then
			for j = 1, 2 do
				local icon = xyd.getItemIcon({
					show_has_num = true,
					scale = 0.5185185185185185,
					uiRoot = self["itemGroup" .. tostring(i - 1) .. "2"],
					itemID = filteredAwards[j][1],
					num = filteredAwards[j][2],
					wndType = xyd.ItemTipsWndType.ACTIVITY
				})
			end

			self["itemGroup" .. tostring(i - 1) .. "2"]:GetComponent(typeof(UILayout)):Reposition()
		elseif #filteredAwards == 3 then
			local icon = xyd.getItemIcon({
				show_has_num = true,
				scale = 0.5185185185185185,
				uiRoot = self["itemGroup" .. tostring(i - 1) .. "31"],
				itemID = filteredAwards[1][1],
				num = filteredAwards[1][2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})

			for j = 2, 3 do
				local icon = xyd.getItemIcon({
					show_has_num = true,
					scale = 0.5185185185185185,
					uiRoot = self["itemGroup" .. tostring(i - 1) .. "32"],
					itemID = filteredAwards[j][1],
					num = filteredAwards[j][2],
					wndType = xyd.ItemTipsWndType.ACTIVITY
				})
			end

			self["itemGroup" .. tostring(i - 1) .. "32"]:GetComponent(typeof(UILayout)):Reposition()
		end
	end
end

function EasterGiftbag:register()
	local data = self.activityData

	for i = 1, #data.detail.charges do
		local id = self.activityData.detail.charges[i].table_id

		UIEventListener.Get(self["purchaseBtn" .. tostring(i - 1)]).onClick = function ()
			xyd.SdkManager.get():showPayment(id)
		end

		self["purchaseBtnLabel" .. tostring(i - 1)].text = xyd.tables.giftBagTextTable:getCurrency(id) .. " " .. xyd.tables.giftBagTextTable:getCharge(id)
	end

	self:registerEvent(xyd.event.RECHARGE, function (evt)
		local gift_bag_id = evt.data.giftbag_id

		if xyd.tables.giftBagTable:getActivityID(gift_bag_id) ~= self.id then
			return
		end

		self:updateStatus()
	end, self)
end

function EasterGiftbag:updateStatus()
	local activityData = self.activityData

	for i = 1, #activityData.detail.charges do
		local buyTimes = activityData.detail.charges[i].buy_times
		local limit = activityData.detail.charges[i].limit_times
		local tableId = activityData.detail.charges[i].table_id

		if limit <= buyTimes then
			xyd.applyGrey(self["purchaseBtn" .. tostring(i - 1)]:GetComponent(typeof(UISprite)))
			xyd.setTouchEnable(self["purchaseBtn" .. tostring(i - 1)], false)
			self["purchaseBtnLabel" .. tostring(i - 1)]:ApplyGrey()
		end

		self["vipLabel" .. tostring(i - 1) .. 1].text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(tableId))
		self["vipLabel" .. tostring(i - 1) .. 2].text = " VIP EXP"
		self["limitLabel" .. tostring(i - 1) .. 1].text = __("BUY_GIFTBAG_LIMIT")
		self["limitLabel" .. tostring(i - 1) .. 2].text = tostring(limit - buyTimes)
	end
end

function EasterGiftbag:getAwards(id)
	return xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(id))
end

function EasterGiftbag:resizeToParent()
	EasterGiftbag.super.resizeToParent(self)

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.bg1:Y(50 + (867 - p_height) / 178 * 50)
	self.bg2:Y(-437 + (867 - p_height) / 178 * 40)
	self.titleImg_:Y(-100 + (867 - p_height) / 178 * 40)
	self.groupDes:Y(-228 + (867 - p_height) / 178 * 50)
	self.groupBottom0:Y(-424 + (867 - p_height) / 178 * 60)
	self.groupBottom1:Y(-720 + (867 - p_height) / 178 * 80)
end

return EasterGiftbag
