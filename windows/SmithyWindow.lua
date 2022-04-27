local BaseWindow = import(".BaseWindow")
local SmithyWindow = class("SmithyWindow", BaseWindow)
local CommonTabBar = import("app.common.ui.CommonTabBar")
local ItemIcon = import("app.components.ItemIcon")
local SelectNum = import("app.components.SelectNum")
local Backpack = xyd.models.backpack
local EquipTable = xyd.tables.equipTable

function SmithyWindow:ctor(name, params)
	SmithyWindow.super.ctor(self, name, params)

	self.curNum_ = 0
	self.maxComposeNum_ = 0
	self.curSelectItem_ = nil
	self.composeEffects = {
		"fx_ui_xhsc",
		"fx_ui_zbhc_down",
		"fx_ui_zbhc_up"
	}
	self.isLoadEffects = false
	self.items_ = {}
	self.showEquipPos = xyd.EquipPos.WEAPON
end

function SmithyWindow:initWindow()
	SmithyWindow.super.initWindow(self)
	self:initData()
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function SmithyWindow:getUIComponent()
	local go = self.window_
	self.item1 = go:NodeByName("item1").gameObject
	self.item2 = go:NodeByName("item2").gameObject
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.barLabel = go:ComponentByName("progressBar_/label", typeof(UILabel))
	self.labelTitle_ = go:ComponentByName("labelTitle_", typeof(UILabel))
	self.progressBar_ = go:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressSp = self.progressBar_.gameObject:ComponentByName("thumb", typeof(UISprite))
	self.btnCompose_ = go:NodeByName("btnCompose_").gameObject
	self.labelComponse = go:ComponentByName("btnCompose_/button_label", typeof(UILabel))
	self.btnAutoMerge_ = go:NodeByName("btnAutoMerge_").gameObject
	self.labelAutoMerge = go:ComponentByName("btnAutoMerge_/button_label", typeof(UILabel))
	self.labelCost_ = go:ComponentByName("labelCost_", typeof(UILabel))
	self.groupBottom = go:NodeByName("groupBottom").gameObject
	self.nav = go:NodeByName("nav").gameObject
	self.selectNumPos = go:NodeByName("selectNumPos").gameObject
	self.closeBtn = go:NodeByName("closeBtn").gameObject
	self.effectNode1 = go:NodeByName("effectNode1").gameObject
	self.groupEffectTop_ = go:NodeByName("groupEffectTop_").gameObject
	self.groupEffectBot_ = go:NodeByName("groupEffectBot_").gameObject

	for i = 1, 4 do
		self["nav_redpoint_" .. i] = self.nav:NodeByName("tab_" .. i):NodeByName("redPoint").gameObject
	end
end

function SmithyWindow:initUIComponent()
	self.selectNum = SelectNum.new(self.selectNumPos, "default", {})
	self.labelTitle_.text = __("EQUIPMENT_COMPOSE")
	self.labelComponse.text = __("COMPOSE")
	self.labelAutoMerge.text = __("ONE_KEY_COMPOSE")
	self.itemIcons = {}

	for i = 1, #self.items_[xyd.EquipPos.WEAPON] do
		local itemGO = ItemIcon.new(self.groupBottom)
		self.itemIcons[i] = itemGO
		local x = -219 + (i - 1) % 4 * 158 - 20
		local y = 183 - math.floor((i - 1) / 4) * 122

		itemGO:getGameObject():SetLocalPosition(x, y, 0)
	end

	self.itemiconReq_ = ItemIcon.new(self.item2)
	self.itemIconRes_ = ItemIcon.new(self.item1)
	local chosen = {
		color = Color.New2(4278124287.0),
		effectColor = Color.New2(1012112383)
	}
	local unchosen = {
		color = Color.New2(960513791),
		effectColor = Color.New2(4294967295.0)
	}
	local colorParams = {
		chosen = chosen,
		unchosen = unchosen
	}
	self.tab = CommonTabBar.new(self.nav, 4, function (index)
		self.showEquipPos = index

		self:changeDataGroup()
	end, nil, colorParams)

	self.tab:setTexts({
		__("EQUIP_NAME_1"),
		__("EQUIP_NAME_2"),
		__("EQUIP_NAME_3"),
		__("EQUIP_NAME_4")
	})
	self:checkAllNavRedPoint()
end

function SmithyWindow:checkAllNavRedPoint(typeNum)
	local startNum = 1
	local endNum = 4

	if typeNum ~= nil then
		startNum = typeNum
		endNum = typeNum
	end

	for i = startNum, endNum do
		local items = self.items_[i]
		local hasNavRedPoint = false

		for j in pairs(items) do
			local need = EquipTable:needFormula(items[j].id)
			local needEquip = need[1]
			local selfNum = Backpack:getItemNumByID(needEquip[1])

			if needEquip[2] <= selfNum then
				hasNavRedPoint = true

				break
			end
		end

		self["nav_redpoint_" .. i]:SetActive(hasNavRedPoint)
	end
end

function SmithyWindow:initData()
	self.items_ = {
		[xyd.EquipPos.WEAPON] = {},
		[xyd.EquipPos.CLOTH] = {},
		[xyd.EquipPos.PANTS] = {},
		[xyd.EquipPos.SHOES] = {}
	}
	local ids = EquipTable:getIDs()
	local i = 1

	while i <= #ids do
		local id = ids[i]
		local pos = EquipTable:getPos(id)
		local need = EquipTable:needFormula(id)

		if pos <= 4 and #need > 0 then
			table.insert(self.items_[pos], {
				isSelect = false,
				id = id,
				obj = self
			})
		end

		i = i + 1
	end

	for _, v in pairs(self.items_) do
		table.sort(v, function (a, b)
			return tonumber(a.id) < tonumber(b.id)
		end)
	end
end

function SmithyWindow:changeDataGroup()
	local items = self.items_[self.showEquipPos]

	for i, v in ipairs(items) do
		v.isSelect = i == 1
		local itemID = v.id

		self:setItemIcon(itemID, i)
	end

	self:changeSelect(items[1].id, 1)
end

function SmithyWindow:setItemIcon(itemID, index)
	local itemIcon = self.itemIcons[index]

	itemIcon:setInfo({
		itemID = itemID,
		callback = function ()
			itemIcon:setSelected(true)
			self:changeSelect(itemID, index)
		end
	})

	local need = EquipTable:needFormula(itemID)
	local needEquip = need[1]
	local needMana = need[2]
	local selfNum = Backpack:getItemNumByID(needEquip[1])

	itemIcon:setRedMark(needEquip[2] <= selfNum)
end

function SmithyWindow:registerEvent()
	self:register()
	xyd.setDarkenBtnBehavior(self.btnCompose_, self, self.composeItem)
	xyd.setDarkenBtnBehavior(self.btnAutoMerge_, self, self.autoCompose)
	self.eventProxy_:addEventListener(xyd.event.COMPOSE_ITEM, handler(self, self.composeCallback))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.itemChange))
	self.eventProxy_:addEventListener(xyd.event.COMPOSE_MULTI_EQUIP, handler(self, self.composeCallback))
end

function SmithyWindow:onBackpackTouch()
	self:close()
	xyd.WindowManager.get():openWindow("backpack_window")
end

function SmithyWindow:composeItem()
	if self.maxComposeNum_ < self.curNum_ then
		xyd.alertTips(__("COMPOSE_EQUIP_NO_MANA"))
	elseif self.curNum_ == 0 then
		local need = EquipTable:needFormula(self.selectID)
		local needEquip = need[1]
		local selfNum = Backpack:getItemNumByID(needEquip[1])

		if selfNum < needEquip[2] then
			xyd.alertTips(__("COMPOSE_EQUIP_NO_MATERIAL"))
		else
			xyd.alertTips(__("COMPOSE_EQUIP_NUM_0"))
		end
	else
		self.autoComposeArr = {}

		Backpack:composeItem(self.selectID, self.curNum_)

		self.selectNum.inputLabel.text = ""

		self.selectNum.inputLabel:SetActive(false)
		self.selectNum.promptLabel:SetActive(true)
	end
end

function SmithyWindow:autoCompose()
	local items = self.items_[self.showEquipPos]
	self.autoComposeArr = {}
	local allCoinNum = 0
	local newEquipGetProcessArr = {}

	for i, v in ipairs(items) do
		local itemID = v.id
		local selfNum = Backpack:getItemNumByID(itemID)

		table.insert(self.autoComposeArr, selfNum)
	end

	for i, v in ipairs(items) do
		local itemID = v.id
		local need = EquipTable:needFormula(itemID)
		local needEquip = need[1]
		local needMana = need[2]
		local selfNum = Backpack:getItemNumByID(needEquip[1])

		if i > 1 then
			selfNum = self.autoComposeArr[i - 1]
		end

		local composeNum = math.floor(selfNum / needEquip[2])

		if composeNum >= 1 then
			allCoinNum = allCoinNum + composeNum * needMana[2]
			self.autoComposeArr[i] = self.autoComposeArr[i] + composeNum

			if i > 1 then
				self.autoComposeArr[i - 1] = self.autoComposeArr[i - 1] - composeNum * needEquip[2]
			end
		end

		table.insert(newEquipGetProcessArr, composeNum)
	end

	if allCoinNum <= 0 then
		xyd.alertTips(__("ONE_KEY_COMPOSE_TEXT2"))

		return
	end

	for i, v in ipairs(items) do
		local itemID = v.id
		local selfNum = Backpack:getItemNumByID(itemID)

		if selfNum < self.autoComposeArr[i] then
			self.autoComposeArr[i] = self.autoComposeArr[i] - selfNum
		else
			self.autoComposeArr[i] = 0
		end
	end

	xyd.WindowManager.get():openWindow("resource_merge_window", {
		items = items,
		numArr = self.autoComposeArr,
		needCoin = allCoinNum,
		newEquipGetProcessArr = newEquipGetProcessArr
	})
end

function SmithyWindow:composeCallback(event)
	self.selectNum:setFirstChange(true)

	local item = event.data.item

	xyd.SoundManager.get():playSound(xyd.SoundID.COMPOSE_EQUIP)
	xyd.Spine:downloadAssets(self.composeEffects, function ()
		if self.willClose_ or tolua.isnull(self.window_) then
			return
		end

		local eff1 = xyd.Spine.new(self.effectNode1)

		eff1:setInfo(self.composeEffects[1], function ()
			eff1:SetLocalScale(1.03, 1.03, 1)
			eff1:play("texiao", 1, 1, function ()
				eff1:destroy()
			end)
		end)

		local eff2 = xyd.Spine.new(self.groupEffectBot_)

		eff2:setInfo(self.composeEffects[2], function ()
			eff2:SetLocalScale(0.5, 0.5, 1)
			eff2:play("texiao", 1, 1, function ()
				eff2:destroy()

				if (not self.autoComposeArr or self.autoComposeArr and #self.autoComposeArr == 0) and item then
					xyd.alertItems({
						item
					})
				end
			end)
		end)

		local eff3 = xyd.Spine.new(self.groupEffectTop_)

		eff3:setInfo(self.composeEffects[3], function ()
			eff3:play("texiao", 1, 1, function ()
				eff3:destroy()
			end)
		end)
	end)
end

function SmithyWindow:itemChange(event)
	self:changeSelect(self.selectID, self.curSelectItem_)
	self:updateRedMark()
	self:showGetEquips(event)
end

function SmithyWindow:showGetEquips(event)
	local items = {}

	if self.autoComposeArr and #self.autoComposeArr > 0 then
		local resourceMergeWin = xyd.WindowManager.get():getWindow("resource_merge_window")

		if resourceMergeWin then
			xyd.WindowManager.get():closeWindow("resource_merge_window")
		end

		local defData = xyd.decodeProtoBuf(event.data)
		local isGetItem = false

		for i in pairs(defData.items) do
			for j in pairs(self.autoComposeArr) do
				if defData.items[i].item_id == self.items_[self.showEquipPos][j].id then
					isGetItem = true

					break
				end
			end
		end

		if isGetItem == false then
			return
		end

		for i in pairs(self.autoComposeArr) do
			if self.autoComposeArr[i] > 0 then
				table.insert(items, {
					item_id = self.items_[self.showEquipPos][i].id,
					item_num = self.autoComposeArr[i]
				})
			end
		end
	end

	if #items > 0 then
		xyd.alertItems(items)
	end
end

function SmithyWindow:updateRedMark()
	local items = self.items_[self.showEquipPos]
	local hasNavRedPoint = false

	for i, v in ipairs(items) do
		local itemID = v.id
		local need = EquipTable:needFormula(itemID)
		local needEquip = need[1]
		local needMana = need[2]
		local selfNum = Backpack:getItemNumByID(needEquip[1])
		local itemIcon = self.itemIcons[i]

		if itemIcon then
			itemIcon:setRedMark(needEquip[2] <= selfNum)

			if needEquip[2] <= selfNum then
				hasNavRedPoint = true
			end
		end
	end

	self["nav_redpoint_" .. self.showEquipPos]:SetActive(hasNavRedPoint)
end

function SmithyWindow:btnSelectTouchEvent(num)
	if self.showEquipPos ~= num then
		self.showEquipPos = num

		self:updateShow()
	end
end

function SmithyWindow:changeSelect(itemID, itemIndex)
	self.selectID = itemID

	self.itemIconRes_:setInfo({
		itemID = itemID
	})

	local need = EquipTable:needFormula(itemID)
	local needEquip = need[1]
	local needMana = need[2]

	self.itemiconReq_:setInfo({
		itemID = needEquip[1],
		wndType = xyd.ItemTipsWndType.SMITHY
	})

	local selfNum = Backpack:getItemNumByID(needEquip[1])
	self.progressBar_.value = math.min(1, selfNum / needEquip[2])
	self.barLabel.text = tostring(selfNum) .. "/" .. tostring(needEquip[2])

	if needEquip[2] <= selfNum then
		xyd.setUISprite(self.progressSp, nil, "bp_bar_green")
	else
		xyd.setUISprite(self.progressSp, nil, "bp_bar_blue")
	end

	self:initSelectNum(math.floor(selfNum / needEquip[2]), needMana)

	if self.curSelectItem_ ~= nil then
		self.itemIcons[self.curSelectItem_]:setSelected(false)
	end

	self.curSelectItem_ = itemIndex

	self.itemIcons[self.curSelectItem_]:setSelected(true)
end

function SmithyWindow:initSelectNum(maxNum, prices)
	local mana = Backpack:getItemNumByID(prices[1])
	local curNum = maxNum
	local price = prices[2]

	if mana < maxNum * price then
		curNum = math.floor(mana / price)
	end

	self.maxComposeNum_ = curNum
	curNum = maxNum and maxNum >= 1 and 1 or 0

	local function callback(num)
		self.curNum_ = num
		self.labelCost_.text = xyd.getRoughDisplayNumber(num * price)
		local mana_ = Backpack:getItemNumByID(prices[1])

		if mana_ < num * price then
			self.labelCost_.color = Color.New2(4278190335.0)
		else
			self.labelCost_.color = Color.New2(1432789759)
		end
	end

	self.selectNum:setInfo({
		maxNum = maxNum,
		curNum = curNum,
		callback = callback
	})
	self.selectNum:setFontSize(30, 30)
	self.selectNum:setPrompt(maxNum)
	self.selectNum:setKeyboardPos(0, -200)
end

function SmithyWindow:onClickCloseButton()
	local lastWindow = self.params_.lastWindow

	SmithyWindow.super.onClickCloseButton(self)

	if lastWindow and (lastWindow == "daily_mission_window" or lastWindow == "enhance_window") then
		local win = xyd.WindowManager.get():getWindow("main_window")

		if win then
			win:setBottomBtnStatus(1, true)
		end
	end
end

function SmithyWindow:playOpenAnimation(callback)
end

return SmithyWindow
