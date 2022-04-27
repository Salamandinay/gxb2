local ActivityContent = import(".ActivityContent")
local LimitFiveStarGiftBag = class("LimitFiveStarGiftBag", ActivityContent)
local CountDown = require("app.components.CountDown")
local GiftBagTable = xyd.tables.giftBagTable
local GiftBagTextTable = xyd.tables.giftBagTextTable

function LimitFiveStarGiftBag:ctor(parentGO, params, parent)
	ActivityContent.ctor(self, parentGO, params, parent)
	dump(self.activityData.detail)
end

function LimitFiveStarGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/limit_five_star_giftbag"
end

function LimitFiveStarGiftBag:getUIComponent()
	local go = self.go
	self.imgBg2_ = go:ComponentByName("imgBg2_", typeof(UISprite))
	self.imgText_ = go:ComponentByName("imgText_", typeof(UISprite))
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
	self.preViewBtn = go:NodeByName("preViewGroup/preViewBtn_").gameObject
	self.preViewBtnLabel = go:ComponentByName("preViewGroup/preViewBtnLabel_", typeof(UILabel))
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.desLabel = self.contentGroup:ComponentByName("desLabel", typeof(UILabel))
	self.expLabel = self.contentGroup:ComponentByName("expLabel", typeof(UILabel))
	self.itemGroup = self.contentGroup:NodeByName("itemGroup").gameObject
	self.buyBtn = self.contentGroup:NodeByName("buyBtn").gameObject
	self.btnLabel1 = self.buyBtn:ComponentByName("button_label1", typeof(UILabel))
	self.btnLabel2 = self.buyBtn:ComponentByName("button_label2", typeof(UILabel))
	self.dumpLabel = self.contentGroup:ComponentByName("dumpIcon/dumpLabel", typeof(UILabel))
	self.dumpLabelNum = self.contentGroup:ComponentByName("dumpIcon/dumpLabelNum", typeof(UILabel))
end

function LimitFiveStarGiftBag:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)
	self:initUIComponent()
	self:updateState()
end

function LimitFiveStarGiftBag:initUIComponent()
	xyd.setUISpriteAsync(self.imgText_, nil, "limit_five_star_giftbag_text01_" .. xyd.Global.lang, nil, , true)

	self.giftbag_id = self.activityData.detail.table_id

	if xyd.Global.lang == "fr_fr" then
		self.endLabel.transform:SetSiblingIndex(0)
		self.timeGroup:GetComponent(typeof(UILayout)):Reposition()
	end

	CountDown.new(self.timeLabel, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel.text = __("END")
	self.desLabel.text = __("NEW_RECHARGE_TEXT04")
	self.btnLabel1.text = GiftBagTextTable:getCurrency(self.giftbag_id) .. " " .. GiftBagTextTable:getCharge(self.giftbag_id)
	self.btnLabel2.text = "[s]" .. __("NEW_RECHARGE_TEXT05") .. "[/s]"
	self.expLabel.text = "+" .. GiftBagTable:getVipExp(self.giftbag_id) .. " VIP EXP"
	self.preViewBtnLabel.text = __("NEW_RECHARGE_TEXT03")
	self.dumpLabel.text = __("ACTIVITY_WARMUP_PACK_TEXT05")
	self.dumpLabelNum.text = "[size=20]+[size=28]" .. __("NEW_RECHARGE_TEXT06")

	self:setIcon()
end

function LimitFiveStarGiftBag:setIcon()
	local giftId = xyd.tables.giftBagTable:getGiftID(self.giftbag_id)
	local awards = xyd.tables.giftTable:getAwards(giftId)

	for i = 1, #awards do
		local award = awards[i]

		if award[1] ~= xyd.ItemID.VIP_EXP then
			local scale = 0.6574074074074074

			if xyd.tables.itemTable:getType(award[1]) == xyd.ItemType.HERO_DEBRIS then
				scale = 0.7962962962962963
			end

			xyd.getItemIcon({
				show_has_num = true,
				uiRoot = self.itemGroup,
				itemID = award[1],
				num = award[2],
				scale = scale
			})
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

function LimitFiveStarGiftBag:updateState()
	local limit = GiftBagTable:getBuyLimit(self.giftbag_id)

	if limit - self.activityData.detail.buy_times > 0 then
		xyd.setEnabled(self.buyBtn, true)
	else
		xyd.setEnabled(self.buyBtn, false)
	end
end

function LimitFiveStarGiftBag:onRegister()
	ActivityContent.onRegister(self)

	UIEventListener.Get(self.buyBtn).onClick = handler(self, self.onBuy)

	UIEventListener.Get(self.preViewBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("partner_info", {
			grade = 5,
			lev = 100,
			table_id = 53007
		})
	end

	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, function ()
		xyd.GiftbagPushController.get():checkGropupRechargePop()
	end)
end

function LimitFiveStarGiftBag:onBuy(event)
	xyd.SdkManager.get():showPayment(self.giftbag_id)
end

function LimitFiveStarGiftBag:onRecharge(evt)
	local giftBagID = evt.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	xyd.models.activity:reqActivityByID(xyd.ActivityID.TULIN_GROWUP_GIFTBAG)
	self:updateState()
end

function LimitFiveStarGiftBag:resizeToParent()
	ActivityContent.resizeToParent(self)
	self.go:Y(-520)

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.imgText_:Y(458 - (p_height - 869) * 0.06)
	self.timeGroup:Y(386 - (p_height - 869) * 0.06)
	self.contentGroup:Y(-90 - (p_height - 869) * 0.62)
	self.imgBg2_:Y(118 - (p_height - 869) * 0.58)

	if xyd.Global.lang == "fr_fr" then
		self.desLabel.width = 320

		self.desLabel:X(30)
	elseif xyd.Global.lang == "ja_jp" then
		self.desLabel.width = 260

		self.btnLabel2:SetActive(false)
		self.btnLabel1.transform:Y(0)
	elseif xyd.Global.lang == "ko_kr" then
		self.desLabel.alignment = NGUIText.Alignment.Center

		self.desLabel:X(0)
	elseif xyd.Global.lang == "de_de" then
		self.desLabel.width = 290
		self.desLabel.fontSize = 20
		self.desLabel.spacingY = 0

		self.desLabel:SetLocalPosition(30, 150, 0)
	end
end

return LimitFiveStarGiftBag
