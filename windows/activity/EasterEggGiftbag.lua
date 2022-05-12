local EasterEggGiftbag = class("EasterEggGiftbag", import(".ActivityContent"))
local GiftBagItem = class("GiftBagItem")

function EasterEggGiftbag:ctor(parentGo, params, parent)
	EasterEggGiftbag.super.ctor(self, parentGo, params, parent)
end

function EasterEggGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/easter_egg_giftbag"
end

function EasterEggGiftbag:resizeToParent()
	EasterEggGiftbag.super.resizeToParent(self)
	self:resizePosY(self.textLogo, -108, -162)
	self:resizePosY(self.timeGroup, -172, -227)
	self:resizePosY(self.groupItems, -531, -698)
end

function EasterEggGiftbag:initUI()
	self:getUIComponent()
	EasterEggGiftbag.super.initUI(self)
	self:layout()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function EasterEggGiftbag:getUIComponent()
	local go = self.go
	self.textLogo = go:ComponentByName("textLogo", typeof(UISprite))
	self.timeGroup = go:ComponentByName("timeGroup", typeof(UILayout))
	self.labelTime = self.timeGroup:ComponentByName("labelTime", typeof(UILabel))
	self.labelEnd = self.timeGroup:ComponentByName("labelEnd", typeof(UILabel))
	self.groupItems = go:NodeByName("groupItems").gameObject
	self.giftBagItem = go:NodeByName("giftBagItem").gameObject

	self.giftBagItem:SetActive(false)
end

function EasterEggGiftbag:layout()
	xyd.setUISpriteAsync(self.textLogo, nil, "easter_egg_giftbag_" .. xyd.Global.lang)

	self.labelEnd.text = __("END")
	local duration = self.activityData:getEndTime() - xyd.getServerTime()

	if duration < 0 then
		self.timeGroup:SetActive(false)
	else
		local timeCount = import("app.components.CountDown").new(self.labelTime)

		timeCount:setInfo({
			duration = duration
		})
	end

	self.groupItemsList = {}
	local charges = self.activityData.detail.charges

	for _, item in ipairs(charges) do
		local go = NGUITools.AddChild(self.groupItems, self.giftBagItem)
		local giftBagItem = GiftBagItem.new(go)
		self.groupItemsList[item.table_id] = giftBagItem

		giftBagItem:setInfo({
			giftBagId = item.table_id,
			leftTimes = item.limit_times - item.buy_times
		})
	end

	if xyd.Global.lang == "fr_fr" then
		self.labelEnd.transform:SetSiblingIndex(0)
		self.timeGroup:GetComponent(typeof(UILayout)):Reposition()
	end
end

function EasterEggGiftbag:onRecharge(event)
	if xyd.tables.giftBagTable:getActivityID(event.data.giftbag_id) ~= xyd.ActivityID.EASTER_EGG_GIFTBAG then
		return
	end

	self.groupItemsList[event.data.giftbag_id]:onBuy()
end

function GiftBagItem:ctor(go)
	self.go = go
	self.giftBagImg = go:ComponentByName("giftBagImg", typeof(UISprite))
	self.labelLimits = go:ComponentByName("labelLimits", typeof(UILabel))
	self.labelExp = go:ComponentByName("labelExp", typeof(UILabel))
	self.buyBtn = go:NodeByName("buyBtn").gameObject
	self.buyBtnLabel = self.buyBtn:ComponentByName("button_label", typeof(UILabel))
	self.itemGroup = go:NodeByName("itemGroup").gameObject
end

function GiftBagItem:setInfo(info)
	self.id = info.giftBagId

	xyd.setUISpriteAsync(self.giftBagImg, nil, "easter_egg_giftbag_icon_" .. info.giftBagId)

	self.labelLimits.text = __("BUY_GIFTBAG_LIMIT", info.leftTimes)
	self.labelExp.text = "+" .. xyd.tables.giftBagTable:getVipExp(info.giftBagId) .. " VIP EXP"
	self.buyBtnLabel.text = xyd.tables.giftBagTextTable:getCurrency(info.giftBagId) .. " " .. xyd.tables.giftBagTextTable:getCharge(info.giftBagId)
	local giftId = xyd.tables.giftBagTable:getGiftID(info.giftBagId)
	local awards = xyd.tables.giftTable:getAwards(giftId)
	local itemList = {}

	for _, data in ipairs(awards) do
		if data[1] ~= xyd.ItemID.VIP_EXP then
			local item = xyd.getItemIcon({
				show_has_num = true,
				scale = 0.7037037037037037,
				itemID = data[1],
				num = data[2],
				uiRoot = self.itemGroup
			})

			table.insert(itemList, item)
		end
	end

	itemList[1]:setScale(0.9074074074074074)
	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()

	if info.leftTimes > 0 then
		UIEventListener.Get(self.buyBtn).onClick = function ()
			xyd.SdkManager.get():showPayment(info.giftBagId)
		end
	else
		xyd.setTouchEnable(self.buyBtn, false)
		xyd.applyChildrenGrey(self.buyBtn)
	end
end

function GiftBagItem:onBuy()
	local charges = xyd.models.activity:getActivity(xyd.ActivityID.EASTER_EGG_GIFTBAG).detail.charges
	local leftTimes = 0

	for i = 1, #charges do
		if charges[i].table_id == self.id then
			leftTimes = charges[i].limit_times - charges[i].buy_times
		end
	end

	self.labelLimits.text = __("BUY_GIFTBAG_LIMIT", leftTimes)

	if leftTimes <= 0 then
		xyd.setTouchEnable(self.buyBtn, false)
		xyd.applyChildrenGrey(self.buyBtn)
	end
end

return EasterEggGiftbag
