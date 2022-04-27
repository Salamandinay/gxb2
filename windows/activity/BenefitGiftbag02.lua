local ActivityContent = import(".ActivityContent")
local BenefitGiftbag02 = class("ValueGiftBag", ActivityContent)
local BenefitGiftbag03Item = class("ValueGiftBagItem", import("app.components.CopyComponent"))
BenefitGiftbag02.BattleArenaGiftBagItem = BenefitGiftbag03Item
local CountDown = import("app.components.CountDown")

function BenefitGiftbag02:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)
end

function BenefitGiftbag02:getPrefabPath()
	return "Prefabs/Windows/activity/benefit_gift_bag"
end

function BenefitGiftbag02:initUI()
	self:getUIComponent()
	BenefitGiftbag02.super.initUI(self)

	self.items = {}
	self.currentState = xyd.Global.lang

	self:initUIComponent()
	self:euiComplete()
end

function BenefitGiftbag02:resizeToParent()
	BenefitGiftbag02.super.resizeToParent(self)
	self.go:SetLocalPosition(0, -self.go:GetComponent(typeof(UIWidget)).height / 2, 0)
	self.buttomGroup:SetLocalPosition(0, -self.go:GetComponent(typeof(UIWidget)).height / 2 + 158, 0)
end

function BenefitGiftbag02:getUIComponent()
	local go = self.go
	self.buttomGroup = go:NodeByName("buttomGroup").gameObject
	self.imgBg = go:ComponentByName("imgBg", typeof(UITexture))
	self.modelGroup = go:NodeByName("modelGroup").gameObject
	self.item1 = self.buttomGroup:NodeByName("item1").gameObject
	self.item2 = self.buttomGroup:NodeByName("item2").gameObject
	self.model = go:ComponentByName("modelGroup", typeof(UITexture))
	self.benefit_giftbag_item = self.buttomGroup:NodeByName("itemCell").gameObject
	self.endLabel = self.buttomGroup:ComponentByName("timerGroup/labelGroup/endLabel", typeof(UILabel))
	self.timeLabel = self.buttomGroup:ComponentByName("timerGroup/labelGroup/timeLabel", typeof(UILabel))

	if xyd.Global.lang == "fr_fr" then
		self.buttomGroup:ComponentByName("timerGroup/bg", typeof(UISprite)).width = 233
	end

	if xyd.Global.lang == "ja_jp" then
		self.timeLabel.fontSize = 20
		self.endLabel.fontSize = 20
	end

	self.skinEffectGroup = go:NodeByName("skinEffectGroup").gameObject
	self.cancelEffectGroup = self.skinEffectGroup:NodeByName("cancelEffectGroup").gameObject
	self.skinEffectGroupBg = self.skinEffectGroup:ComponentByName("imgBg", typeof(UISprite))
	self.labelSkinDesc = self.skinEffectGroup:ComponentByName("labelSkinDesc", typeof(UILabel))
	self.groupEffect1 = self.skinEffectGroup:NodeByName("groupEffect1").gameObject
	self.groupEffect2 = self.skinEffectGroup:NodeByName("groupEffect2").gameObject
	self.groupTouch = self.skinEffectGroup:NodeByName("groupTouch").gameObject
	self.groupModel = self.skinEffectGroup:NodeByName("groupModel").gameObject
	self.showSkinBtn = go:NodeByName("showSkinBtn").gameObject
end

function BenefitGiftbag02:initUIComponent()
	local strArr = xyd.tables.miscTable:split("activity_45_hero_model", "value", "|")

	if self.activityData.id == xyd.ActivityID.BENEFIT_GIFTBAG01 then
		strArr = xyd.tables.miscTable:split("activity_44_hero_model", "value", "|")
	elseif self.activityData.id == xyd.ActivityID.BENEFIT_GIFTBAG05 then
		strArr = xyd.tables.miscTable:split("activity_147_hero_model", "value", "|")
	elseif self.activityData.id == xyd.ActivityID.BENEFIT_GIFTBAG07 then
		strArr = xyd.tables.miscTable:split("activity_276_hero_model", "value", "|")
	end

	self.modelSpine = xyd.Spine.new(self.modelGroup)

	self.modelSpine:setInfo(strArr[1], function ()
		self.modelSpine:play("animation", 0)
		self.modelSpine:SetLocalPosition(tonumber(strArr[2]), tonumber(strArr[3]), 0)
		self.modelSpine:setRenderTarget(self.model, 1)
	end, true)

	local scale = tonumber(strArr[4])

	self.modelGroup:SetLocalScale(scale, scale, scale)
	self:loadSkinModel()
	self:initSkinEffect()

	UIEventListener.Get(self.showSkinBtn).onClick = function ()
		self.skinEffectGroup:SetActive(not self.skinEffectGroup.activeSelf)
		self:playSkinEffect()
	end

	UIEventListener.Get(self.cancelEffectGroup).onClick = function ()
		self.skinEffectGroup:SetActive(false)
		self:stopSkinEffect()
	end

	UIEventListener.Get(self.groupTouch).onClick = handler(self, self.onModelTouch)
end

function BenefitGiftbag02:loadSkinModel()
	local strArr = xyd.tables.miscTable:split("activity_45_hero_model", "value", "|")

	if self.activityData.id == xyd.ActivityID.BENEFIT_GIFTBAG01 then
		strArr = xyd.tables.miscTable:split("activity_44_hero_model", "value", "|")
	elseif self.activityData.id == xyd.ActivityID.BENEFIT_GIFTBAG05 then
		strArr = xyd.tables.miscTable:split("activity_147_hero_model", "value", "|")
	elseif self.activityData.id == xyd.ActivityID.BENEFIT_GIFTBAG07 then
		strArr = xyd.tables.miscTable:split("activity_276_hero_model", "value", "|")
	end

	local modelID = strArr[5]

	if tonumber(strArr[6]) == 7226 and xyd.Global.lang == "de_de" then
		self.labelSkinDesc.width = 450
	else
		self.labelSkinDesc.width = 348
	end

	self.labelSkinDesc.text = xyd.tables.equipTextTable:getSkinDesc(strArr[6])

	if self.labelSkinDesc.height > 70 then
		self.skinEffectGroupBg.height = self.skinEffectGroupBg.height + self.labelSkinDesc.height - 70

		self.skinEffectGroupBg:Y(-(self.labelSkinDesc.height - 70) / 2)
	end

	local name = xyd.tables.modelTable:getModelName(modelID)
	local scale = xyd.tables.modelTable:getScale(modelID)
	self.isFirstSettingSkinModelScale = scale

	if self.skinModel and self.skinModel:getName() == name then
		return
	end

	if self.skinModel then
		self.skinModel:destroy()
	end

	local model = xyd.Spine.new(self.groupModel)

	model:setInfo(name, function ()
		model:SetLocalPosition(0, 0, 0)
		model:SetLocalScale(scale, scale, 1)

		self.isFirstSettingSkinModel = true

		model:play("idle", 0)
	end)

	self.skinModel = model
end

function BenefitGiftbag02:initSkinEffect()
	if self.skinEffect1 then
		return
	end

	self.skinEffect1 = xyd.Spine.new(self.groupEffect1)
	self.skinEffect2 = xyd.Spine.new(self.groupEffect2)

	self.skinEffect1:setInfo("fx_ui_fazhen", function ()
		self.skinEffect1:SetLocalPosition(0, 0, -10)
		self.skinEffect1:SetLocalScale(1, 1, 1)
	end)
	self.skinEffect2:setInfo("fx_ui_fazhen", function ()
		self.skinEffect2:SetLocalPosition(0, 0, 0)
		self.skinEffect2:SetLocalScale(1, 1, 1)
	end)
	self.groupEffect1:SetActive(false)
	self.groupEffect2:SetActive(false)
end

function BenefitGiftbag02:playSkinEffect()
	if self.skinModel then
		if not self.isFirstSettingSkinModel then
			self.skinModel:SetLocalPosition(0, 0, 0)
			self.skinModel:SetLocalScale(self.isFirstSettingSkinModelScale, self.isFirstSettingSkinModelScale, 1)
		end

		self.skinModel:play("idle", 0, 1, nil, true)
	end

	if not self.skinEffect1 then
		return
	end

	if not self.skinEffect2 then
		return
	end

	self.skinEffect1:play("texiao01", 0, 1, nil, true)
	self.skinEffect2:play("texiao02", 0, 1, nil, true)
	self.groupEffect1:SetActive(true)
	self.groupEffect2:SetActive(true)
end

function BenefitGiftbag02:stopSkinEffect()
	if self.skinModel then
		self.skinModel:stop()
	end

	if self.skinEffect1 then
		self.skinEffect1:stop()
	end

	if self.skinEffect1 then
		self.skinEffect2:stop()
	end

	self.groupEffect1:SetActive(false)
	self.groupEffect2:SetActive(false)
end

function BenefitGiftbag02:onModelTouch()
	if not self.skinModel then
		return
	end

	local strArr = xyd.tables.miscTable:split("activity_45_hero_model", "value", "|")

	if self.activityData.id == xyd.ActivityID.BENEFIT_GIFTBAG01 then
		strArr = xyd.tables.miscTable:split("activity_44_hero_model", "value", "|")
	elseif self.activityData.id == xyd.ActivityID.BENEFIT_GIFTBAG05 then
		strArr = xyd.tables.miscTable:split("activity_147_hero_model", "value", "|")
	elseif self.activityData.id == xyd.ActivityID.BENEFIT_GIFTBAG07 then
		strArr = xyd.tables.miscTable:split("activity_276_hero_model", "value", "|")
	end

	local tableID = string.sub(strArr[5], 1, #strArr[5] - 2)
	local mp = xyd.tables.partnerTable:getEnergyID(tableID)
	local ack = xyd.tables.partnerTable:getPugongID(tableID)
	local skillID = 0

	if xyd.getServerTime() % 2 > 0 then
		skillID = mp

		if tableID ~= 755005 and tableID ~= 55006 and tableID ~= 655015 then
			self.skinModel:play("skill", 1, 1, function ()
				self.skinModel:play("idle", 0)
			end)
		else
			self.skinModel:play("skill01", 1, 1, function ()
				self.skinModel:play("idle", 0)
			end)
		end
	else
		skillID = ack

		self.skinModel:play("attack", 1, 1, function ()
			self.skinModel:play("idle", 0)
		end, true)
	end

	if self.skillSound then
		-- Nothing
	end

	self.skillSound = xyd.tables.skillTable:getSound(skillID)
end

function BenefitGiftbag02:euiComplete()
	local activityData = self.activityData

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	self.endLabel.text = __("END_TEXT")

	if xyd.Global.lang == "ko_kr" then
		self.timeLabel.fontSize = 20
		self.endLabel.fontSize = 20
	elseif xyd.Global.lang == "fr_fr" then
		self.timeLabel.fontSize = 19
		self.endLabel.fontSize = 19
	end

	self:initItem()
	self.benefit_giftbag_item:SetActive(false)
	self.eventProxyInner_:addEventListener(xyd.event.RECHARGE, function (evt)
		self:onRecharge(evt)
	end)

	if xyd.Global.lang == "de_de" then
		local timerGroup = self.buttomGroup:NodeByName("timerGroup").gameObject
		local bg = timerGroup:ComponentByName("bg", typeof(UISprite))
		bg.width = 310

		timerGroup:X(185)
	end
end

function BenefitGiftbag02:onRecharge(evt)
	for i in ipairs(self.items) do
		local item = self.items[i]

		item:updateNum(tonumber(self.activityData.detail.charges[i].buy_times))
	end
end

function BenefitGiftbag02:initItem()
	local activityData = self.activityData

	for i in ipairs(activityData.detail.charges) do
		local itemGroup = self["item" .. tostring(i)]
		local params = activityData.detail.charges[i]

		NGUITools.DestroyChildren(itemGroup.transform)

		local tmp = NGUITools.AddChild(itemGroup.gameObject, self.benefit_giftbag_item)
		local item = BenefitGiftbag03Item.new(tmp, params)

		table.insert(self.items, item)
	end
end

function BenefitGiftbag03Item:ctor(goItem, params)
	self.table_id_ = params.table_id
	self.limit_ = xyd.tables.giftBagTable:getBuyLimit(self.table_id_)
	self.count_ = params.buy_times
	self.currentState = "up"

	self:getUIComponent(goItem)
	self:createChildren()
end

function BenefitGiftbag03Item:getUIComponent(goItem)
	self.goItem_ = goItem
	local transGo = goItem.transform
	self.itemGroup = transGo:NodeByName("itemGroup").gameObject
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

	if #awards >= 5 then
		if #awards >= 6 then
			self.itemGroup:SetLocalPosition(-93, 0, 0)
			self.purchaseBtn.gameObject:SetLocalPosition(238, -15, 0)
			self.limitLabel.gameObject:SetLocalPosition(238, 44.4, 0)

			self.limitLabel.color = Color.New2(3006283519.0)

			self.vipLabel.gameObject:SetLocalPosition(238, 25.6, 0)

			self.vipLabel.width = 170
			self.vipLabel.overflowMethod = UILabel.Overflow.ShrinkContent
		else
			self.itemGroup:SetLocalPosition(-135, 0, 0)
		end
	else
		self.itemGroup:SetLocalPosition(-140, 0, 0)
	end

	for i in ipairs(awards) do
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
			local icon = xyd.getItemIcon(item)

			if xyd.tables.itemTable:getType(data[1]) == xyd.ItemType.SKIN then
				icon.go:SetLocalScale(80 / icon.go:GetComponent(typeof(UIWidget)).width, 80 / icon.go:GetComponent(typeof(UIWidget)).height, 1)
			else
				icon.go:SetLocalScale(70 / icon.go:GetComponent(typeof(UIWidget)).width, 70 / icon.go:GetComponent(typeof(UIWidget)).height, 1)
			end

			if #awards > 5 and i > 4 then
				icon.go:SetLocalScale(icon.go.transform.localScale.x * 65 / 76, icon.go.transform.localScale.y * 65 / 76, 1)
			end
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
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
	end
end

function BenefitGiftbag03Item:getAwards()
	return xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(self.table_id_))
end

return BenefitGiftbag02
