local ActivityContent = import(".ActivityContent")
local LimitGropupGiftBag = class("LimitGropupGiftBag", ActivityContent)
local CountDown = require("app.components.CountDown")
local GiftBagTable = xyd.tables.giftBagTable
local GiftBagTextTable = xyd.tables.giftBagTextTable

function LimitGropupGiftBag:ctor(parentGO, params, parent)
	ActivityContent.ctor(self, parentGO, params, parent)
	dump(self.activityData.detail)
end

function LimitGropupGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/limit_gropup_giftbag"
end

function LimitGropupGiftBag:getUIComponent()
	local go = self.go
	self.imgBg_ = go:ComponentByName("imgBg1_", typeof(UITexture))
	self.imgText_ = go:ComponentByName("imgText_", typeof(UITexture))
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))

	for i = 1, 2 do
		self["contentGroup" .. i] = go:NodeByName("contentGroup" .. i).gameObject
		self["expLabel" .. i] = self["contentGroup" .. i]:ComponentByName("expLabel", typeof(UILabel))
		self["itemGroup" .. i] = self["contentGroup" .. i]:NodeByName("itemGroup").gameObject
		self["buyBtn" .. i] = self["contentGroup" .. i]:NodeByName("buyBtn").gameObject
		self["btnLabel1_" .. i] = self["contentGroup" .. i]:ComponentByName("buyBtn/button_label1", typeof(UILabel))
		self["btnLabel2_" .. i] = self["contentGroup" .. i]:ComponentByName("buyBtn/button_label2", typeof(UILabel))
		self["dumpLabel" .. i] = self["contentGroup" .. i]:ComponentByName("dumpIcon/dumpLabel", typeof(UILabel))
		self["dumpLabelNum" .. i] = self["contentGroup" .. i]:ComponentByName("dumpIcon/dumpLabelNum", typeof(UILabel))
	end
end

function LimitGropupGiftBag:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)
	self:initUIComponent()
	self:updateState()
end

function LimitGropupGiftBag:initUIComponent()
	xyd.setUITextureByNameAsync(self.imgText_, "activity_gropup_giftbag_logo_" .. xyd.Global.lang, true)

	local giftBagIds = xyd.tables.activityTable:getGiftBag(self.id)

	CountDown.new(self.timeLabel, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel.text = __("END")
	self.btnLabel1_1.text = GiftBagTextTable:getCurrency(giftBagIds[1]) .. " " .. GiftBagTextTable:getCharge(giftBagIds[1])
	self.btnLabel2_1.text = "[s]" .. __("GIFTBAG_TURIN_PRICE1") .. "[/s]"
	self.expLabel1.text = "+" .. GiftBagTable:getVipExp(giftBagIds[1]) .. " VIP EXP"
	self.dumpLabel1.text = __("ACTIVITY_WARMUP_PACK_TEXT05")
	self.dumpLabelNum1.text = "[size=20]+[size=28]" .. __("GIFTBAG_TURIN_TEXT1") .. "[size=20]%"
	self.btnLabel1_2.text = GiftBagTextTable:getCurrency(giftBagIds[2]) .. " " .. GiftBagTextTable:getCharge(giftBagIds[2])
	self.btnLabel2_2.text = "[s]" .. __("GIFTBAG_TURIN_PRICE2") .. "[/s]"
	self.expLabel2.text = "+" .. GiftBagTable:getVipExp(giftBagIds[2]) .. " VIP EXP"
	self.dumpLabel2.text = __("ACTIVITY_WARMUP_PACK_TEXT05")
	self.dumpLabelNum2.text = "[size=20]+[size=28]" .. __("GIFTBAG_TURIN_TEXT2") .. "[size=20]%"

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
		self.timeGroup:Y(-177)
	elseif xyd.Global.lang == "ja_jp" then
		self.btnLabel2_1:SetActive(false)
		self.btnLabel1_1.transform:Y(0)
		self.btnLabel2_2:SetActive(false)
		self.btnLabel1_2.transform:Y(0)
	end

	self:setIcon()
end

function LimitGropupGiftBag:setIcon()
	local giftBagIds = xyd.tables.activityTable:getGiftBag(self.id)

	for i = 1, 2 do
		local giftBagID = giftBagIds[i]
		local giftId = xyd.tables.giftBagTable:getGiftID(giftBagID)
		local awards = xyd.tables.giftTable:getAwards(giftId)

		for j = 1, #awards do
			local award = awards[j]

			if award[1] ~= xyd.ItemID.VIP_EXP then
				local scale = 0.6574074074074074

				if xyd.tables.itemTable:getType(award[1]) == xyd.ItemType.HERO_DEBRIS or xyd.tables.itemTable:getType(award[1]) == xyd.ItemType.SKIN then
					scale = 0.7962962962962963
				end

				xyd.getItemIcon({
					show_has_num = true,
					uiRoot = self["itemGroup" .. i],
					itemID = award[1],
					num = award[2],
					wndType = xyd.ItemTipsWndType.ACTIVITY,
					scale = scale
				})
			end
		end

		self["itemGroup" .. i]:GetComponent(typeof(UILayout)):Reposition()
	end
end

function LimitGropupGiftBag:updateState()
	local giftBagIds = xyd.tables.activityTable:getGiftBag(self.id)

	for i = 1, 2 do
		local giftBagId = giftBagIds[i]
		local limit = GiftBagTable:getBuyLimit(giftBagId)

		if limit - self.activityData.detail.charge[i].buy_times > 0 then
			xyd.setEnabled(self["buyBtn" .. i], true)
		else
			xyd.setEnabled(self["buyBtn" .. i], false)
		end
	end
end

function LimitGropupGiftBag:onRegister()
	ActivityContent.onRegister(self)

	UIEventListener.Get(self.buyBtn1).onClick = function ()
		local giftBagIds = xyd.tables.activityTable:getGiftBag(self.id)

		print("self.giftbag_id", giftBagIds[1])
		xyd.SdkManager.get():showPayment(giftBagIds[1])
	end

	UIEventListener.Get(self.buyBtn2).onClick = function ()
		local giftBagIds = xyd.tables.activityTable:getGiftBag(self.id)

		print("self.giftbag_id", giftBagIds[2])
		xyd.SdkManager.get():showPayment(giftBagIds[2])
	end

	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function LimitGropupGiftBag:onRecharge(evt)
	local giftBagID = evt.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	self:updateState()
end

function LimitGropupGiftBag:resizeToParent()
	ActivityContent.resizeToParent(self)

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	if p_height >= 1047 then
		p_height = 1047
	end

	self.contentGroup1:Y(-193 - (p_height - 869) * 71 / 178)
	self.contentGroup2:Y(-524 - (p_height - 869) * 82 / 178)
end

return LimitGropupGiftBag
