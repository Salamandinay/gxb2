local ActivityContent = import(".ActivityContent")
local BenefitGiftbag = class("ValueGiftBag", ActivityContent)
local BenefitGiftbag03Item = class("ValueGiftBagItem", import("app.components.CopyComponent"))
BenefitGiftbag.BattleArenaGiftBagItem = BenefitGiftbag03Item
local CountDown = import("app.components.CountDown")

function BenefitGiftbag:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)
end

function BenefitGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/benefit_giftbag"
end

function BenefitGiftbag:initUI()
	self:getUIComponent()
	BenefitGiftbag.super.initUI(self)

	self.items = {}
	self.currentState = xyd.Global.lang

	self:initUIComponent()
	self:euiComplete()
end

function BenefitGiftbag:resizeToParent()
	BenefitGiftbag.super.resizeToParent(self)

	local allHeight = self.go:GetComponent(typeof(UIWidget)).height
	local bgHeight_y = 100

	if allHeight > 867 then
		bgHeight_y = 100 - (allHeight - 867)
	else
		bgHeight_y = 100 + allHeight - 867
	end

	if bgHeight_y < 0 then
		bgHeight_y = 0
	end

	self.imgBg:SetLocalPosition(0, bgHeight_y, 0)
end

function BenefitGiftbag:getUIComponent()
	local go = self.go
	self.imgBg = go:NodeByName("imgBg").gameObject
	self.modelGroup = go:NodeByName("modelGroup").gameObject
	self.groupItem1 = go:NodeByName("groupItem1").gameObject
	self.groupItem1_bg = self.groupItem1:ComponentByName("e:Image", typeof(UITexture))
	self.itemGroup1 = self.groupItem1:NodeByName("itemGroup1").gameObject
	self.groupItem2 = go:NodeByName("groupItem2").gameObject
	self.groupItem2_bg = self.groupItem2:ComponentByName("e:Image", typeof(UITexture))
	self.itemGroup2 = self.groupItem2:NodeByName("itemGroup2").gameObject
	self.countDownGroup = go:NodeByName("countDownGroup").gameObject
	self.textImg = self.countDownGroup:ComponentByName("textImg", typeof(UISprite))
	self.endLabel = self.countDownGroup:ComponentByName("endLabel", typeof(UILabel))
	self.timeLabel = self.countDownGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.benefit_giftbag_item = go:NodeByName("benefit_giftbag_item").gameObject
end

function BenefitGiftbag:initUIComponent()
	xyd.setUISpriteAsync(self.textImg, nil, "benefit_giftbag03_text01_" .. xyd.Global.lang, nil, , true)
end

function BenefitGiftbag:euiComplete()
	local activityData = self.activityData

	if xyd:getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	self.endLabel.text = __("END_TEXT")

	self.eventProxyInner_:addEventListener(xyd.event.RECHARGE, handler(self, function (evt, aaa)
		self:onRecharge(evt)
	end))
	self:initItem()

	if xyd.Global.lang == "de_de" then
		self.timeLabel:X(0)
		self.endLabel:X(10)
	end
end

function BenefitGiftbag:onRecharge(evt)
	local items = self.items
	local activityData = self.activityData

	for i in pairs(items) do
		local item = items[i]

		item:updateNum(tonumber(activityData.detail.charges[i].buy_times))
	end
end

function BenefitGiftbag:initItem()
	local activityData = self.activityData

	for i in ipairs(activityData.detail.charges) do
		local itemGroup = self["itemGroup" .. tostring(i)]
		local params = activityData.detail.charges[i]

		NGUITools.DestroyChildren(itemGroup.transform)

		local tmp = NGUITools.AddChild(itemGroup.gameObject, self.benefit_giftbag_item.gameObject)
		local item = BenefitGiftbag03Item.new(tmp, params)

		if #item:getAwards() >= 6 then
			self["groupItem" .. i .. "_bg"].height = 343

			self["groupItem" .. i .. "_bg"].gameObject:Y(-12)
			itemGroup.gameObject:Y(-80)
		end

		table.insert(self.items, item)
	end
end

function BenefitGiftbag03Item:ctor(goItem, params)
	self.table_id_ = params.table_id
	self.limit_ = xyd.tables.giftBagTable:getBuyLimit(self.table_id_)
	self.count_ = params.buy_times
	self.skinName = "BenefitGiftbag03ItemSkin"
	self.currentState = "up"

	self:getUIComponent(goItem)
	self:createChildren()
end

function BenefitGiftbag03Item:getUIComponent(goItem)
	self.goItem_ = goItem
	local transGo = goItem.transform
	self.itemGroup = transGo:NodeByName("itemGroup").gameObject
	self.itemGroup_UILayout = transGo:ComponentByName("itemGroup", typeof(UILayout))
	self.itemGroup1 = transGo:NodeByName("itemGroup1").gameObject
	self.itemGroup1_UILayout = transGo:ComponentByName("itemGroup1", typeof(UILayout))
	self.limitLabel = transGo:ComponentByName("limitLabel", typeof(UILabel))
	self.vipLabel = transGo:ComponentByName("vipLabel", typeof(UILabel))
	self.purchaseBtn = transGo:ComponentByName("purchaseBtn", typeof(UISprite))
	self.purchaseBtn_boxCollider = transGo:ComponentByName("purchaseBtn", typeof(UnityEngine.BoxCollider))
	self.purchaseBtn_button_label = transGo:ComponentByName("purchaseBtn/button_label", typeof(UILabel))
end

function BenefitGiftbag03Item:createChildren()
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

function BenefitGiftbag03Item:initItems()
	local awards = self:getAwards()
	local itemGroup = self.itemGroup
	local scalexy = 0.6

	if #awards > 5 then
		if #awards >= 6 then
			self.purchaseBtn.height = 67

			self.purchaseBtn.gameObject:Y(-48.6)

			self.purchaseBtn_button_label.height = 62

			self.limitLabel.gameObject:Y(23)
			self.vipLabel.gameObject:Y(1.9)

			scalexy = 0.6018518518518519
			self.itemGroup_UILayout.gap = Vector2(10, 0)
			self.itemGroup1_UILayout.gap = Vector2(10, 0)

			self.itemGroup.gameObject:Y(114.8)
			self.itemGroup1.gameObject:Y(40.1)
		else
			self.itemGroup:SetLocalPosition(0, 110, 0)
		end
	else
		self.itemGroup:SetLocalPosition(0, 88, 0)
	end

	for i in ipairs(awards) do
		if #awards > 5 and i > 4 then
			itemGroup = self.itemGroup1
			scalexy = 0.4

			if #awards >= 6 then
				scalexy = 0.6018518518518519
			end
		end

		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local item = {
				show_has_num = true,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = itemGroup.gameObject,
				scale = Vector3(scalexy, scalexy, 1)
			}

			if data[1] == xyd.ItemID.SCHOOL_OPENS_GIFTBAG_CHARGE_ITEM then
				item.effect = "fx_act_icon_2"
			end

			local icon = xyd.getItemIcon(item)

			if #awards > 5 and i > 4 then
				icon:setLabelNumScale(1.5)
			else
				icon:setLabelNumScale(1.2)
			end
		end
	end

	self.itemGroup_UILayout:Reposition()
	self.itemGroup1_UILayout:Reposition()
end

function BenefitGiftbag03Item:updateNum(num)
	local count = self.count_

	if count == num then
		return
	end

	self.count_ = num

	self:updateStaus()
end

function BenefitGiftbag03Item:updateStaus()
	local limit = self.limit_
	local limitLabel = self.limitLabel
	local count = self.count_
	limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(limit - count))

	if limit <= count then
		local purchaseBtn = self.purchaseBtn
		self.purchaseBtn_boxCollider.enabled = false

		xyd.applyChildrenGrey(purchaseBtn.gameObject)
		self.limitLabel:SetActive(false)
		self.vipLabel:SetLocalPosition(0, self.vipLabel.transform.localPosition.y + 20, 0)

		if #self:getAwards() >= 6 then
			self.vipLabel:SetLocalPosition(0, 15.5, 0)
		end

		self.purchaseBtn:SetLocalPosition(0, self.purchaseBtn.transform.localPosition.y + 10, 0)
	end
end

function BenefitGiftbag03Item:getAwards()
	return xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(self.table_id_))
end

return BenefitGiftbag
