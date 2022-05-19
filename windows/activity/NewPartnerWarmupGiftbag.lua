local NewPartnerWarmupGiftbag = class("NewPartnerWarmupGiftbag", import(".ActivityContent"))
local NewPartnerWarmupGiftbagItem = class("NewPartnerWarmupGiftbagItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local json = require("cjson")

function NewPartnerWarmupGiftbag:ctor(parentGO, params)
	NewPartnerWarmupGiftbag.super.ctor(self, parentGO, params)
end

function NewPartnerWarmupGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/new_partner_warmup_giftbag"
end

function NewPartnerWarmupGiftbag:resizeToParent()
	NewPartnerWarmupGiftbag.super.resizeToParent(self)
	self:resizePosY(self.bg, 30, 0)
end

function NewPartnerWarmupGiftbag:initUI()
	self:getUIComponent()
	NewPartnerWarmupGiftbag.super.initUI(self)
	self:initUIComponent()
end

function NewPartnerWarmupGiftbag:getUIComponent()
	self.bg = self.go:ComponentByName("bg", typeof(UITexture))
	self.logoBg = self.go:ComponentByName("logoBg", typeof(UISprite))
	self.imgLogo = self.go:ComponentByName("imgLogo", typeof(UISprite))
	self.timeBg = self.go:ComponentByName("timeBg", typeof(UISprite))
	self.countdown = self.go:NodeByName("countdown").gameObject
	self.labelTime = self.countdown:ComponentByName("labelTime", typeof(UILabel))
	self.labelEnd = self.countdown:ComponentByName("labelEnd", typeof(UILabel))
	self.scrollView = self.go:ComponentByName("scrollView", typeof(UIScrollView))
	self.groupItems = self.scrollView:NodeByName("groupItems").gameObject
	self.topItem = self.go:NodeByName("topItem").gameObject
	self.middleItem = self.go:NodeByName("middleItem").gameObject
	self.bottomItem = self.go:NodeByName("bottomItem").gameObject
end

function NewPartnerWarmupGiftbag:initUIComponent()
	xyd.setUISpriteAsync(self.imgLogo, nil, "new_partner_warmup_giftbag_text_" .. xyd.Global.lang, nil, , true)
	CountDown.new(self.labelTime, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.labelEnd.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.labelEnd.transform:SetSiblingIndex(0)
	end

	if xyd.Global.lang == "de_de" then
		self.timeBg.width = 350

		self.countdown:X(161)
	end

	self.items = {}

	NGUITools.DestroyChildren(self.groupItems.transform)

	for i, charge in ipairs(self.activityData.detail_.charges) do
		local go = nil

		if i == 1 then
			go = NGUITools.AddChild(self.groupItems.gameObject, self.topItem.gameObject)
		elseif i == #self.activityData.detail_.charges then
			go = NGUITools.AddChild(self.groupItems.gameObject, self.bottomItem.gameObject)
		else
			go = NGUITools.AddChild(self.groupItems.gameObject, self.middleItem.gameObject)
		end

		local item = NewPartnerWarmupGiftbagItem.new(go, self)

		item:setInfo({
			table_id = charge.table_id,
			buy_times = charge.buy_times,
			limit_times = charge.limit_times,
			isFirstGiftbag = i == 1,
			isLastGiftbag = i == i == #self.activityData.detail_.charges
		})
		xyd.setDragScrollView(item.go, self.scrollView)
		table.insert(self.items, item)
	end

	self.groupItems:GetComponent(typeof(UILayout)):Reposition()
	self.scrollView:ResetPosition()
end

function NewPartnerWarmupGiftbag:onRegister()
	self:registerEvent(xyd.event.RECHARGE, function ()
		for i, item in ipairs(self.items) do
			item:update({
				buy_times = self.activityData.detail_.charges[i].buy_times
			})
		end
	end)
end

function NewPartnerWarmupGiftbagItem:ctor(go, parent)
	NewPartnerWarmupGiftbagItem.super.ctor(self, go)

	self.go = go
	self.parent = parent
	self.commonAward = self.go:NodeByName("commonAward").gameObject
	self.purchaseBtn = self.go:NodeByName("purchaseBtn").gameObject
	self.purchaseBtnLabel = self.purchaseBtn:ComponentByName("purchaseBtnLabel", typeof(UILabel))
	self.vipLabel = self.go:ComponentByName("vipLabel", typeof(UILabel))
	self.limitLabel = self.go:ComponentByName("limitLabel", typeof(UILabel))
end

function NewPartnerWarmupGiftbagItem:update(params)
	self.buyTimes = params.buy_times or 0
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", self.limitTimes - self.buyTimes)

	if self.limitTimes <= self.buyTimes then
		self.purchaseBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		xyd.applyChildrenGrey(self.purchaseBtn.gameObject)
	end
end

function NewPartnerWarmupGiftbagItem:setInfo(params)
	self.giftbagId = params.table_id
	self.buyTimes = params.buy_times or 0
	self.limitTimes = params.limit_times or 0
	self.isFirstGiftbag = params.isFirstGiftbag or false
	self.isLastGiftbag = params.isLastGiftbag or false

	if self.isFirstGiftbag then
		self.bigAward = self.go:NodeByName("bigAward").gameObject
	end

	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", self.limitTimes - self.buyTimes)

	if self.limitTimes <= self.buyTimes then
		self.purchaseBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		xyd.applyChildrenGrey(self.purchaseBtn.gameObject)
	end

	xyd.setDragScrollView(self.purchaseBtn.gameObject, self.parent.scrollView)

	self.vipLabel.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftbagId) .. " VIP EXP"
	self.purchaseBtnLabel.text = xyd.tables.giftBagTextTable:getCurrency(self.giftbagId) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.giftbagId)
	self.giftID = xyd.tables.giftBagTable:getGiftID(self.giftbagId) or 0
	self.awards = xyd.tables.giftTable:getAwards(self.giftID) or {}
	self.awardNum = 0

	for _, award in ipairs(self.awards) do
		if award[1] ~= xyd.ItemID.VIP_EXP then
			self.awardNum = self.awardNum + 1

			xyd.getItemIcon({
				show_has_num = true,
				notShowGetWayBtn = true,
				uiRoot = self.isFirstGiftbag and self.awardNum == 2 and self.bigAward or self.commonAward,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				scale = self.isFirstGiftbag and self.awardNum == 2 and 0.7037037037037037 or 0.6018518518518519,
				dragScrollView = self.parent.scrollView
			})
		end
	end

	self.commonAward:GetComponent(typeof(UIGrid)):Reposition()

	UIEventListener.Get(self.purchaseBtn).onClick = handler(self, function ()
		xyd.SdkManager.get():showPayment(self.giftbagId)
	end)
end

return NewPartnerWarmupGiftbag
