local ActivityContent = import(".ActivityContent")
local NewLevelUpGiftBag = class("NewLevelUpGiftBag", ActivityContent)

function NewLevelUpGiftBag:ctor(parentGO, params)
	NewLevelUpGiftBag.super.ctor(self, parentGO, params)
	self.eventProxyInner_:addEventListener(xyd.event.RECHARGE, handler(self, self.onRecharge))

	self.giftBagID = self.activityData.detail[self.type].charge.table_id

	self:setBtnState(true)

	local numLevel = xyd.tables.giftBagTable:getParams(self.giftBagID)
	self.numLevel = import("app.components.PngNum").new(self.pageNumRoot)

	self.numLevel:setInfo({
		iconName = "level_up_giftbag",
		num = numLevel[1]
	})
	self:initNumLevel()
	self:initBtn()
	self:setText()
	self:setIcon()
end

function NewLevelUpGiftBag.getPrefabPath()
	return "Prefabs/Components/new_levelUp_giftBag"
end

function NewLevelUpGiftBag:initUI()
	NewLevelUpGiftBag.super.initUI(self)
	self:getUIComponent()
end

function NewLevelUpGiftBag:initNumLevel()
	local numLevel = xyd.tables.giftBagTable:getParams(self.giftBagID)

	if xyd.Global.lang == "en_en" then
		if numLevel[1] >= 100 then
			self.numLevel.go:SetLocalScale(0.7, 0.7, 1)
		end

		self.imgText01.transform:SetLocalPosition(195, -10, 0)
		self.pageNumRoot.transform:SetLocalPosition(-10, -10, 0)

		self.imgText01.width = 350
	elseif xyd.Global.lang == "ja_jp" then
		if numLevel[1] >= 100 then
			self.numLevel.go:SetLocalScale(0.7, 0.7, 1)
		end

		self.imgText01.transform:SetLocalPosition(195, -10, 0)
		self.pageNumRoot.transform:SetLocalPosition(-35, -15, 0)

		self.imgText01.width = 380
	elseif xyd.Global.lang == "fr_fr" then
		self.imgText01.transform:SetLocalPosition(20, -10, 0)
		self.pageNumRoot.transform:SetLocalPosition(100, -10, 0)

		self.imgText01.width = 220
	elseif xyd.Global.lang == "ko_kr" then
		self.imgText01.transform:SetLocalPosition(130, -10, 0)
		self.pageNumRoot.transform:SetLocalPosition(-15, -10, 0)

		self.imgText01.width = 80
		self.imgText01.height = 80

		if numLevel[1] >= 100 then
			self.imgText01.transform:SetLocalPosition(160, -10, 0)
		end
	elseif xyd.Global.lang == "de_de" then
		self.imgText01.transform:SetLocalPosition(215, -10, 0)
		self.pageNumRoot.transform:SetLocalPosition(0, -10, 0)

		self.imgText01.width = 364
		self.imgText01.height = 58

		if numLevel[1] >= 100 then
			self.numLevel.go:SetLocalScale(0.7, 0.7, 1)
			self.pageNumRoot:X(-10)
		end
	else
		self.imgText01.transform:SetLocalPosition(185, -10, 0)
		self.pageNumRoot.transform:SetLocalPosition(-85, -10, 0)

		self.imgText01.width = 220

		if numLevel[1] >= 100 then
			self.imgText01.transform:SetLocalPosition(220, -10, 0)
		end
	end
end

function NewLevelUpGiftBag:getUpdateTime()
	local detail, tableID = nil

	if self.activityData.detail and self.activityData.detail[self.type] then
		detail = self.activityData.detail[self.type]
		tableID = self.activityData.detail[self.type].charge.table_id
	else
		detail = self.activityData.detail
		tableID = self.activityData.detail.charge.table_id
	end

	local updateTime = nil

	if detail.update_time then
		updateTime = detail.update_time
	else
		updateTime = 0
	end

	if not updateTime then
		return detail.end_time
	end

	return updateTime + xyd.tables.giftBagTable:getLastTime(tableID)
end

function NewLevelUpGiftBag:initBtn()
	UIEventListener.Get(self.buyBtn.gameObject).onClick = function ()
		xyd.SdkManager.get():showPayment(self.giftBagID)
	end

	if xyd.tables.giftBagTable:getBuyLimit(self.giftBagID) <= self.activityData.detail[self.type].charge.buy_times or self:getUpdateTime() <= xyd.getServerTime() then
		self:setBtnState(false)
	end
end

function NewLevelUpGiftBag:setText()
	if self:getUpdateTime() - xyd.getServerTime() > 0 then
		local params = {
			duration = self:getUpdateTime() - xyd.getServerTime()
		}

		if not self.timeCountDown_ then
			self.timeCountDown_ = import("app.components.CountDown").new(self.timeCountDown, params)
		else
			self.timeCountDown_:setInfo(params)
		end
	else
		if self.timeCountDown_ then
			self.timeCountDown_:stopTimeCount()
		end

		self.timeCountDown.gameObject:SetActive(false)
	end

	self.buyBtnLabel.text = xyd.tables.giftBagTextTable:getCurrency(self.giftBagID) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.giftBagID)
	self.addExpLabel.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftBagID) .. "VIP EXP"
	local limit = xyd.tables.giftBagTable:getBuyLimit(self.giftBagID) - self.activityData.detail[self.type].charge.buy_times
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", limit)

	xyd.setUISpriteAsync(self.imgText01, nil, "level_up_giftbag_text01_" .. tostring(xyd.Global.lang), nil, , true)
end

function NewLevelUpGiftBag:setIcon()
	local giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID)
	local awards = xyd.tables.giftTable:getAwards(giftID)

	for i = 1, #awards do
		local cur_data = awards[i]

		if cur_data[1] ~= xyd.ItemID.VIP_EXP then
			local item = {
				show_has_num = true,
				scale = 0.8981481481481481,
				uiRoot = self.itemGroup.gameObject,
				itemID = cur_data[1],
				num = cur_data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}

			xyd.getItemIcon(item)
		end
	end

	self.itemGroup:Reposition()
end

function NewLevelUpGiftBag:setBtnState(can)
	if not can then
		xyd.applyGrey(self.buyBtn)
		self.limitLabel.gameObject:SetActive(false)

		self.buyBtn.gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	else
		xyd.applyOrigin(self.buyBtn)
		self.limitLabel.gameObject:SetActive(true)

		self.buyBtnLabel.color = Color.New2(2975269119.0)
		self.buyBtn.gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end
end

function NewLevelUpGiftBag:getUIComponent()
	local goTrans = self.go:NodeByName("mainGroup")
	self.groupText = goTrans:NodeByName("groupText")
	self.pageNumRoot = self.groupText:NodeByName("pageNumRoot").gameObject
	self.imgText01 = self.groupText:ComponentByName("imgText01", typeof(UISprite))
	self.itemGroup = goTrans:ComponentByName("itemGroup", typeof(UIGrid))
	self.addExpLabel = goTrans:ComponentByName("addExpLabel", typeof(UILabel))
	self.limitLabel = goTrans:ComponentByName("limitLabel", typeof(UILabel))
	self.buyBtn = goTrans:ComponentByName("buyBtn", typeof(UISprite))

	xyd.setUISpriteAsync(self.buyBtn, nil, "mana_week_card_btn01")

	self.buyBtnLabel = goTrans:ComponentByName("buyBtn/label", typeof(UILabel))
	self.timeCountDown = goTrans:ComponentByName("timeCountDown", typeof(UILabel))
end

function NewLevelUpGiftBag:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	local limit = xyd.tables.giftBagTable:getBuyLimit(self.giftBagID) - self.activityData.detail[self.type].charge.buy_times
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", limit)

	if xyd.tables.giftBagTable:getBuyLimit(self.giftBagID) <= self.activityData.detail[self.type].charge.buy_times then
		self:setBtnState(false)
	end
end

return NewLevelUpGiftBag
