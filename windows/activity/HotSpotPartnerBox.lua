local ActivityContent = import(".ActivityContent")
local HotSpotPartnerBox = class("HotSpotPartnerBox", ActivityContent)
local BoxItem = class("ValueGiftBagItem", import("app.components.CopyComponent"))
HotSpotPartnerBox.BattleArenaGiftBagItem = BoxItem
local CountDown = import("app.components.CountDown")

function HotSpotPartnerBox:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.items = {}
	self.currentState = xyd.Global.lang

	self:getUIComponent()
	self:initUIComponent()
	self:euiComplete()
end

function HotSpotPartnerBox:getPrefabPath()
	return "Prefabs/Windows/activity/hot_spot_partner_box"
end

function HotSpotPartnerBox:getUIComponent()
	local go = self.go
	self.allGroup = go:NodeByName("allGroup").gameObject
	self.logoImg = self.allGroup:ComponentByName("logoImg", typeof(UITexture))
	self.itemGroup1 = self.allGroup:NodeByName("topGroup").gameObject
	self.itemGroup2 = self.allGroup:NodeByName("downGroup").gameObject
	self.groupItem = self.allGroup:NodeByName("groupItem").gameObject
end

function HotSpotPartnerBox:initUIComponent()
	xyd.setUITextureByNameAsync(self.logoImg, "hot_spot_partner_box_name_" .. xyd.Global.lang, true)
end

function HotSpotPartnerBox:euiComplete()
	local activityData = self.activityData

	self.eventProxyInner_:addEventListener(xyd.event.RECHARGE, handler(self, function (evt, aaa)
		self:onRecharge(evt)
	end))
	self.allGroup:Y(-438 + -46 * self.scale_num_contrary)
	self:initItem()
	self.groupItem:SetActive(false)
end

function HotSpotPartnerBox:onRecharge(evt)
	local items = self.items
	local activityData = self.activityData

	for i in pairs(items) do
		local item = items[i]

		item:updateNum(tonumber(activityData.detail.charges[i].buy_times))
	end
end

function HotSpotPartnerBox:initItem()
	local activityData = self.activityData

	for i in ipairs(activityData.detail.charges) do
		local itemGroup = self["itemGroup" .. tostring(i)]
		local params = activityData.detail.charges[i]
		local tmp = NGUITools.AddChild(itemGroup.gameObject, self.groupItem.gameObject)

		if i == 1 then
			tmp:SetLocalPosition(0, -88, 0)
		elseif i == 2 then
			tmp:SetLocalPosition(0, 6, 0)
		end

		local item = BoxItem.new(tmp, params)

		table.insert(self.items, item)
	end
end

function BoxItem:ctor(goItem, params)
	self.table_id_ = params.table_id
	self.limit_ = xyd.tables.giftBagTable:getBuyLimit(self.table_id_)
	self.count_ = params.buy_times

	self:getUIComponent(goItem)
	self:createChildren()
end

function BoxItem:getUIComponent(goItem)
	self.goItem_ = goItem
	local transGo = goItem.transform
	self.itemGroup = transGo:NodeByName("itemGroup1").gameObject
	self.itemGroup1 = transGo:NodeByName("itemGroup2").gameObject
	self.limitLabel = transGo:ComponentByName("limitText", typeof(UILabel))
	self.vipLabel = transGo:ComponentByName("vipText", typeof(UILabel))
	self.purchaseBtn = transGo:ComponentByName("buyBtn", typeof(UISprite))
	self.purchaseBtn_boxCollider = transGo:ComponentByName("buyBtn", typeof(UnityEngine.BoxCollider))
	self.purchaseBtn_button_label = transGo:ComponentByName("buyBtn/buyBtnText", typeof(UILabel))
end

function BoxItem:createChildren()
	local giftbag_id = xyd.tables.giftBagTable:getGiftID(self.table_id_)
	local table_id = self.table_id_
	UIEventListener.Get(self.purchaseBtn.gameObject).onClick = handler(self, function ()
		xyd.SdkManager.get():showPayment(table_id)
	end)
	self.vipLabel.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(table_id)) .. " VIP EXP"
	self.purchaseBtn_button_label.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.table_id_) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.table_id_))

	self:initItems()
	self:updateStaus()
end

function BoxItem:initItems()
	local awards = self:getAwards()
	local checkArr = {}
	local itemGroup = self.itemGroup

	for i in ipairs(awards) do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			table.insert(checkArr, awards[i])
		end
	end

	local scalexy = 0.8148148148148148

	for i in ipairs(checkArr) do
		if i > 1 then
			itemGroup = self.itemGroup1
			scalexy = 0.7222222222222222
		end

		local data = checkArr[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local item = {
				show_has_num = true,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = itemGroup.gameObject,
				scale = Vector3(scalexy, scalexy, 1)
			}
			local icon = xyd.getItemIcon(item)
		end
	end
end

function BoxItem:updateNum(num)
	local count = self.count_

	if count == num then
		return
	end

	self.count_ = num

	self:updateStaus()
end

function BoxItem:updateStaus()
	local limit = self.limit_
	local limitLabel = self.limitLabel
	local count = self.count_
	limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(limit - count))

	if limit <= count then
		local purchaseBtn = self.purchaseBtn
		self.purchaseBtn_boxCollider.enabled = false

		xyd.applyChildrenGrey(purchaseBtn.gameObject)
		self.limitLabel:SetActive(false)
		self.vipLabel:SetLocalPosition(0, -40, 0)
		self.purchaseBtn:SetLocalPosition(0, -95, 0)
	end
end

function BoxItem:getAwards()
	return xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(self.table_id_))
end

return HotSpotPartnerBox
