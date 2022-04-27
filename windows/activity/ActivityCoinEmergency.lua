local ActivityContent = import(".ActivityContent")
local ActivityCoinEmergency = class("ActivityCoinEmergency", ActivityContent)
local CountDown = import("app.components.CountDown")

function ActivityCoinEmergency:ctor(go, params, parent)
	ActivityContent.ctor(self, go, params, parent)
end

function ActivityCoinEmergency:getPrefabPath()
	return "Prefabs/Components/coin_emergency"
end

function ActivityCoinEmergency:initUI()
	local detail, charge = nil

	if self.activityData.detail[1] then
		detail = self.activityData.detail[self.type]
		charge = detail.charge
	else
		detail = self.activityData.detail
		charge = detail
	end

	self.realCharge = charge
	self.currentState = xyd.Global.lang

	ActivityContent.initUI(self)
	self:getUIComponent()
	self:layout()
end

function ActivityCoinEmergency:getUIComponent()
	local go = self.go
	self.textImg = go:ComponentByName("groupText/textImg", typeof(UITexture))
	self.timeBg_ = go:ComponentByName("groupText/endTimeGroup/imgBg", typeof(UITexture))
	self.labelTime = go:ComponentByName("groupText/endTimeGroup/endTime/labelTime", typeof(UILabel))
	self.labelEnd = go:ComponentByName("groupText/endTimeGroup/endTime/labelEnd", typeof(UILabel))
	self.groupContent = go:NodeByName("groupContent").gameObject
	self.groupIcons = self.groupContent:NodeByName("groupIcons").gameObject
	self.labelLimit = self.groupContent:ComponentByName("labelLimit", typeof(UILabel))
	self.labelVIP = self.groupContent:ComponentByName("labelVIP", typeof(UILabel))
	self.btnBuy = self.groupContent:ComponentByName("btnBuy", typeof(UISprite))
	self.button_label = self.groupContent:ComponentByName("btnBuy/button_label", typeof(UILabel))
	self.imgBottom = go:ComponentByName("e:Image", typeof(UITexture))
end

function ActivityCoinEmergency:getUpdateTime()
	local detail, tableID = nil

	if self.activityData.detail[1] then
		detail = self.activityData.detail[self.type]
		tableID = self.activityData.detail[self.type].charge.table_id
	else
		detail = self.activityData.detail
		tableID = self.activityData.detail.table_id
	end

	local updateTime = nil

	if detail.update_time then
		updateTime = detail.update_time
	else
		updateTime = 0
	end

	if not updateTime then
		return self.realCharge.end_time
	end

	return updateTime + xyd.tables.giftBagTable:getLastTime(tableID)
end

function ActivityCoinEmergency:layout()
	if xyd.getServerTime() < self:getUpdateTime() then
		local countDown = CountDown.new(self.labelTime, {
			duration = self:getUpdateTime() - xyd.getServerTime()
		})
		self.labelEnd.text = __("END_TEXT")
	else
		self.labelEnd:SetActive(false)
		self.labelTime:SetActive(false)
	end

	xyd.setUITextureAsync(self.textImg, "Textures/activity_text_web/coin_emergency_text_" .. xyd.Global.lang)

	local id = tonumber(self.realCharge.table_id)
	local totalTimes = xyd.tables.giftBagTable:getBuyLimit(id)
	local buyTimes = self.realCharge.buy_times
	local price = tostring(xyd.tables.giftBagTextTable:getCurrency(id)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(id))
	self.labelVIP.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(id)) .. " VIP EXP"
	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT") .. tostring(totalTimes - buyTimes)
	self.button_label.text = price
	local height1 = self.parentGo:GetComponent(typeof(UIPanel)).height

	self.imgBottom:Y(-height1)

	UIEventListener.Get(self.btnBuy.gameObject).onClick = function ()
		xyd.SdkManager.get():showPayment(self.realCharge.table_id)
	end

	self:registerEvent(xyd.event.RECHARGE, function (event)
		local id = event.data.giftbag_id

		if xyd.tables.giftBagTable:getActivityID(id) ~= self.id then
			return
		end

		self:updateStatus()
	end)

	if xyd.Global.lang == "de_de" then
		self.timeBg_.width = 360
	end

	self:initItems()
	self:updateStatus()
end

function ActivityCoinEmergency:initItems()
	local id = tonumber(self.realCharge.table_id)
	local awards = xyd.tables.giftTable:getAwards(id)

	for i = 1, #awards do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local item = xyd.getItemIcon({
				show_has_num = true,
				itemID = data[1],
				num = data[2],
				uiRoot = self.groupIcons,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		end
	end
end

function ActivityCoinEmergency:updateStatus()
	local id = tonumber(self.realCharge.table_id)
	local totalTimes = xyd.tables.giftBagTable:getBuyLimit(id)
	local buyTimes = self.realCharge.buy_times

	if totalTimes <= buyTimes then
		xyd.applyGrey(self.btnBuy)
		xyd.setTouchEnable(self.btnBuy, false)
	end

	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT") .. tostring(totalTimes - buyTimes)
end

return ActivityCoinEmergency
