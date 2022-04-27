local BaseWindow = import(".BaseWindow")
local DatesGiftsWindow = class("DatesGiftsWindow", BaseWindow)
local CommonTabBar = import("app.common.ui.CommonTabBar")
local ItemIcon = import("app.components.ItemIcon")
local SelectNum = import("app.components.SelectNum")
local DatesGiftItem = class("DatesGiftItem", import("app.common.ui.FixedMultiWrapContentItem"))

function DatesGiftsWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.curNum_ = 0
	self.maxComposeNum_ = 0
	self.curSelectItem_ = nil
	self.items_ = {}
	self.showEquipPos = 1
	self.backpack = xyd.models.backpack
end

function DatesGiftsWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initData()
	self:updateShow()
	self:registerEvent()
end

function DatesGiftsWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelWinTitle = groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.btns = groupAction:NodeByName("btns").gameObject
	self.tabBar = CommonTabBar.new(self.btns, 4, handler(self, self.btnSelectTouchEvent))
	local top = groupAction:NodeByName("top").gameObject
	self.groupModel = top:ComponentByName("groupModel", typeof(UISprite))
	self.groupCompose = top:NodeByName("groupCompose").gameObject
	local itemIconNode = self.groupCompose:NodeByName("itemIconRes_").gameObject
	self.labelCost_ = self.groupCompose:ComponentByName("groupCost/labelCost_", typeof(UILabel))
	self.btnCompose_ = self.groupCompose:NodeByName("btnCompose_").gameObject
	local selectNumNode = self.groupCompose:NodeByName("selectNum_").gameObject
	self.groupScroll = top:NodeByName("groupScroll").gameObject
	self.groupItemEffect = self.groupScroll:ComponentByName("groupItemEffect", typeof(UISprite))
	self.touchImage = groupAction:NodeByName("touchImage").gameObject
	local scrollView = groupAction:ComponentByName("bottom/scrollview", typeof(UIScrollView))
	local wrapContent = scrollView:ComponentByName("mainDataGroup_", typeof(MultiRowWrapContent))
	local item = groupAction:NodeByName("bottom/item").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(scrollView, wrapContent, item, DatesGiftItem, self)
	self.itemIconRes_ = ItemIcon.new(itemIconNode)
	self.selectNum_ = SelectNum.new(selectNumNode, "gift")
end

function DatesGiftsWindow:layout()
	xyd.setBtnLabel(self.btnCompose_, {
		text = __("DATES_GIFTS_TEXT01")
	})
	xyd.setBgColorType(self.btnCompose_, xyd.ButtonBgColorType.blue_btn_65_65)

	for i = 1, 4 do
		local label = self.btns:ComponentByName("tab_" .. i .. "/label", typeof(UILabel))
		label.text = __("DATES_GIFTS_GROUP_" .. i)
	end

	self:initModel()
end

function DatesGiftsWindow:initData()
	for i = 1, 4 do
		self.items_[i] = {}
	end

	local DatesGiftTable = xyd.tables.datesGiftTable
	local giftIDs = DatesGiftTable:getIDs()

	for i = 1, #giftIDs do
		local itemID = giftIDs[i]
		local group = DatesGiftTable:getGroup(itemID)

		table.insert(self.items_[group], {
			isSelect = false,
			id = itemID,
			obj = self
		})
	end
end

function DatesGiftsWindow:changeDataGroup()
	local items = self.items_[self.showEquipPos]
	self.selectID = items[1].id

	self.multiWrap_:setInfos(items, {})
	self:changeSelect(items[1])
end

function DatesGiftsWindow:registerEvent()
	self:register()

	UIEventListener.Get(self.btnCompose_).onClick = handler(self, self.composeItem)

	self.eventProxy_:addEventListener(xyd.event.DATES_GIFTS_COMPOSE, handler(self, self.composeCallback))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.itemChange))
end

function DatesGiftsWindow:composeItem()
	if self.maxComposeNum_ < self.curNum_ then
		xyd.showToast(__("COMPOSE_DATES_GIFTS_TEXT02"))

		return
	elseif self.curNum_ == 0 then
		xyd.showToast(__("COMPOSE_DATES_GIFTS_TEXT03"))

		return
	else
		self:setTouchImg(true)
		self.backpack:composeDatesGifts(self.selectID, self.curNum_)
	end
end

function DatesGiftsWindow:composeCallback(event)
	xyd.SoundManager.get():playSound(xyd.SoundID.COMPOSE_EQUIP)

	local itemID = event.data.item_id
	local itemNum = event.data.item_num
	local item = {
		item_id = itemID,
		item_num = itemNum
	}

	self:playModelMake({
		item
	})
end

function DatesGiftsWindow:setTouchImg(flag)
	if tolua.isnull(self.touchImage) then
		return
	end

	self.touchImage:SetActive(flag)
end

function DatesGiftsWindow:itemChange(event)
	local data = event.data.items

	for i = 1, #data do
		local item = data[i]

		if item.item_id == xyd.ItemID.DATES_GIFT_DEBRIS then
			local needs = xyd.tables.miscTable:split2Cost("love_gift_cost", "value", "#")
			local num = self.backpack:getItemNumByID(needs[1])

			self:initSelectNum(math.floor(num / needs[2]), needs)
		end
	end
end

function DatesGiftsWindow:btnSelectTouchEvent(num)
	if self.showEquipPos ~= num then
		self.showEquipPos = num

		self:updateShow()
		self:playModelSwitch()
	end
end

function DatesGiftsWindow:updateShow()
	self:changeDataGroup()
end

function DatesGiftsWindow:changeSelect(selectInfo, isTouchItem)
	self.selectID = selectInfo.id
	local items = self.items_[self.showEquipPos]

	if self.curSelectItem_ ~= nil then
		self.curSelectItem_.isSelect = false
	end

	self.curSelectItem_ = selectInfo
	selectInfo.isSelect = true

	self.itemIconRes_:setInfo({
		itemID = selectInfo.id
	})

	local needs = xyd.tables.miscTable:split2Cost("love_gift_cost", "value", "#")
	local num = self.backpack:getItemNumByID(needs[1])

	self:initSelectNum(math.floor(num / needs[2]), needs)

	if isTouchItem then
		local items = self.multiWrap_:getItems()

		for i = 1, #items do
			items[i]:changeSelect()
		end
	end
end

function DatesGiftsWindow:initSelectNum(maxNum, prices)
	local mana = self.backpack:getItemNumByID(prices[1])
	local curNum = maxNum
	local price = prices[2]

	if mana < maxNum * price then
		curNum = math.floor(mana / price)
	end

	self.maxComposeNum_ = curNum

	local function callback(num)
		self.curNum_ = num
		self.labelCost_.text = xyd.getRoughDisplayNumber(mana) .. "/" .. tostring(xyd.getRoughDisplayNumber(num * price))
		local textColor = 1432789759

		if curNum < num then
			textColor = 4278190335.0
		end

		xyd.setLabel(self.labelCost_, {
			textColor = textColor
		})
	end

	self.selectNum_:setInfo({
		curNum = 1,
		maxNum = maxNum,
		callback = callback
	})

	self.selectNum_:getGameObject():GetComponent(typeof(UIWidget)).width = 146

	self.selectNum_:setFontSize(30, 30)
	self.selectNum_:changeCurNum()
	self.selectNum_:setKeyboardPos(-150, -200)
end

function DatesGiftsWindow:initModel()
	self.db = xyd.Spine.new(self.groupModel.gameObject)

	self.db:setInfo("gongsunzan_liwuzhizuo", function ()
		self.db:SetLocalScale(0.75, 0.75, 1)
		self.db:play("idle", 0)
	end)

	self.db01 = xyd.Spine.new(self.groupItemEffect.gameObject)

	self.db01:setInfo("shiwuzhizuo", function ()
		self:playDBEffect(self.db01, 1, 1)
	end)

	self.db02 = xyd.Spine.new(self.groupItemEffect.gameObject)

	self.db02:setInfo("wanjuzhizuo", function ()
		self:playDBEffect(self.db02, 2, 2)
	end)

	self.db03 = xyd.Spine.new(self.groupItemEffect.gameObject)

	self.db03:setInfo("shipinzhizuo", function ()
		self:playDBEffect(self.db03, 3, 3)
	end)

	self.db04 = xyd.Spine.new(self.groupItemEffect.gameObject)

	self.db04:setInfo("zawuzhizuo", function ()
		self:playDBEffect(self.db04, 4, 4)
	end)

	self.effectsMap = {
		self.db01,
		self.db02,
		self.db03,
		self.db04
	}
	self.currentEffect = 1
end

function DatesGiftsWindow:playDBEffect(db, pos, effectIndex)
	if self.showEquipPos == pos then
		db:play("idle", 0)

		self.currentEffect = effectIndex
	else
		db:SetActive(false)
	end
end

function DatesGiftsWindow:playModelSwitch()
	if self.isPlayModelSwitch or self.currentEffect == self.showEquipPos then
		return
	end

	local from = self.currentEffect
	local to = self.showEquipPos
	self.currentEffect = to
	local fromEffect = self.effectsMap[from]
	local toEffect = self.effectsMap[to]
	self.isPlayModelSwitch = true

	self.db:play("switch02", 1, 1, function ()
		self.db:play("switch01", 1, 1, function ()
			self.db:play("idle", 0)
		end)
	end)
	fromEffect:SetActive(true)
	fromEffect:play("switch02", 1, 1, function ()
		fromEffect:SetActive(false)
		toEffect:SetActive(true)
		toEffect:play("switch01", 1, 1, function ()
			if self.isEffectDelay then
				self.isEffectDelay = false

				toEffect:play("make", 1, 1, function ()
					toEffect:play("idle", 0)

					self.isPlayModelSwitch = false
				end)
			else
				toEffect:play("idle", 0)

				self.isPlayModelSwitch = false
			end
		end)
	end)
end

function DatesGiftsWindow:playModelMake(params)
	if self.db:isValid() then
		self.db:play("make", 1, 1, function ()
			self.db:play("idle", 0)
			xyd.alertItems(params)
			self:setTouchImg(false)
		end)
	else
		xyd.alertItems(params)
		self:setTouchImg(false)
	end

	local effect = self.effectsMap[self.currentEffect]

	if self.isPlayModelSwitch then
		self.isEffectDelay = true
	else
		effect:SetActive(true)
		effect:play("make", 1, 1, function ()
			effect:play("idle", 0)
		end)
	end
end

function DatesGiftItem:ctor(go, parent)
	DatesGiftItem.super.ctor(self, go, parent)
end

function DatesGiftItem:initUI()
	DatesGiftItem.super.initUI(self)

	self.itemIcon = ItemIcon.new(self.go)
end

function DatesGiftItem:setDragScrollView()
	self.itemIcon:setDragScrollView(self.parent.scrollView)
end

function DatesGiftItem:updateInfo()
	local obj = self.data.obj
	local itemID = self.data.id

	local function clickCallback()
		obj:changeSelect(self.data, true)
	end

	self.itemIcon:setInfo({
		itemID = itemID,
		callback = clickCallback
	})
	self:changeSelect()
end

function DatesGiftItem:changeSelect()
	if not self.data then
		return
	end

	local flag = self.data.isSelect

	self.itemIcon:setSelected(flag)
end

return DatesGiftsWindow
