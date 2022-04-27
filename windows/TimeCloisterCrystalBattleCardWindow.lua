local TimeCloisterCrystalBattleCardWindow = class("TimeCloisterCrystalBattleCardWindow", import(".BaseWindow"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local CardItem = class("CardItem", import("app.components.CopyComponent"))
local TimeCloisterScienceCard = import("app.components.TimeCloisterScienceCard")
local CommonTabBar = import("app.common.ui.CommonTabBar")

function TimeCloisterCrystalBattleCardWindow:ctor(name, params)
	TimeCloisterCrystalBattleCardWindow.super.ctor(self, name, params)
end

function TimeCloisterCrystalBattleCardWindow:initWindow()
	self:getUIComponent()
	TimeCloisterCrystalBattleCardWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function TimeCloisterCrystalBattleCardWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.groupUp = self.groupAction:NodeByName("groupUp").gameObject
	self.labelTitle = self.groupUp:ComponentByName("labelTitle", typeof(UILabel))
	self.btnClose = self.groupUp:NodeByName("btnClose").gameObject
	self.labelDesc = self.groupUp:ComponentByName("labelDesc", typeof(UILabel))
	self.btnSet = self.groupUp:NodeByName("btnSet").gameObject
	self.btnSetLabelDesc = self.btnSet:ComponentByName("labelDesc", typeof(UILabel))

	for i = 1, 3 do
		self["slot" .. i] = self.groupUp:NodeByName("slot" .. i).gameObject
		self["slotBg" .. i] = self["slot" .. i]:ComponentByName("slotBg" .. i, typeof(UISprite))
		self["slotCardCon" .. i] = self["slot" .. i]:NodeByName("slotCardCon" .. i).gameObject
	end

	self.groupDown = self.groupAction:NodeByName("groupDown").gameObject
	self.nav = self.groupDown:NodeByName("nav").gameObject

	for i = 1, 5 do
		self["tab_" .. i] = self.nav:NodeByName("tab_" .. i).gameObject

		if i == 1 then
			self["label" .. i] = self["tab_" .. i]:ComponentByName("label", typeof(UILabel))
		else
			self["icon" .. i] = self["tab_" .. i]:ComponentByName("icon", typeof(UISprite))
		end
	end

	self.itemCon = self.groupDown:NodeByName("itemCon").gameObject
	self.itemScroller = self.groupDown:NodeByName("itemScroller").gameObject
	self.itemScrollerUIScrollView = self.groupDown:ComponentByName("itemScroller", typeof(UIScrollView))
	self.itemGroup = self.itemScroller:NodeByName("itemGroup").gameObject
	self.itemGroupUIWrapContent = self.itemScroller:ComponentByName("itemGroup", typeof(UIWrapContent))
	self.itemGroupUIWrapContent = FixedMultiWrapContent.new(self.itemScrollerUIScrollView, self.itemGroupUIWrapContent, self.itemCon, CardItem, self)
end

function TimeCloisterCrystalBattleCardWindow:registerEvent()
	UIEventListener.Get(self.btnSet.gameObject).onClick = handler(self, function ()
		local sendIds = {}

		for i, value in pairs(self.battleCardIds) do
			if value ~= -1 then
				table.insert(sendIds, value)
			end
		end

		xyd.models.timeCloisterModel:sendSetIds(xyd.TimeCloisterMissionType.THREE, sendIds)
	end)
	UIEventListener.Get(self.btnClose.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

function TimeCloisterCrystalBattleCardWindow:layout()
	self.labelTitle.text = __("TIME_CLOISTER_TEXT100")
	self.label1.text = __("TIME_CLOISTER_TEXT98")
	self.labelDesc.text = __("TIME_CLOISTER_TEXT101")
	self.btnSetLabelDesc.text = __("TIME_CLOISTER_TEXT96")

	self:initNav()

	self.battleCardIds = xyd.cloneTable(xyd.models.timeCloisterModel:getThreeChoiceCrystalBattleCardIds())

	for i = 1, 3 do
		self["upCard" .. i] = TimeCloisterScienceCard.new(self["slotCardCon" .. i], {})

		self["upCard" .. i]:setCallback(handler(self, self.onClickUp))

		if not self.battleCardIds[i] then
			self.battleCardIds[i] = -1
		end
	end

	for i, index in pairs(self.battleCardIds) do
		if index ~= -1 then
			self["upCard" .. i]:setInfo({
				index = index
			})
		else
			self["upCard" .. i]:SetActive(false)
		end
	end
end

function TimeCloisterCrystalBattleCardWindow:initNav()
	self.tabBar = CommonTabBar.new(self.nav, 5, function (index)
		self:updatePage(index)
	end, nil, , 5)
end

function TimeCloisterCrystalBattleCardWindow:updatePage(index)
	if self.tabIndex and self.tabIndex == index then
		return
	end

	self.tabIndex = index

	self:choicePage(index)
	xyd.SoundManager.get():playSound(xyd.SoundID.SWITCH_PAGE)
end

function TimeCloisterCrystalBattleCardWindow:choicePage(index)
	if not self["setArr" .. index - 1] then
		local arr = xyd.models.timeCloisterModel:getThreeCrystalTypeWithCardsIndex(index - 1)
		local arr2 = xyd.cloneTable(arr)

		table.sort(arr2, function (a, b)
			local infoA = xyd.models.timeCloisterModel:getThreeCrystalCards(a)
			local infoB = xyd.models.timeCloisterModel:getThreeCrystalCards(b)
			local levA = xyd.tables.timeCloisterCrystalCardTable:getLevel(infoA.card)
			local levB = xyd.tables.timeCloisterCrystalCardTable:getLevel(infoB.card)

			if levA < levB then
				return false
			end

			local typeA = xyd.tables.timeCloisterCrystalCardTable:getType(infoA.card)
			local typeB = xyd.tables.timeCloisterCrystalCardTable:getType(infoB.card)

			if levA == levB and typeB < typeA then
				return false
			end

			if levA == levB and typeA == typeB and infoB.card < infoA.card then
				return false
			end

			return true
		end)

		self["setArr" .. index - 1] = arr2
	end

	self.itemGroupUIWrapContent:setInfos(self["setArr" .. index - 1], {})
	self:waitForFrame(1, function ()
		self.itemScrollerUIScrollView:ResetPosition()
	end)
end

function TimeCloisterCrystalBattleCardWindow:isUpYet(index)
	for i, indexCheck in pairs(self.battleCardIds) do
		if indexCheck == index then
			return true
		end
	end

	return false
end

function TimeCloisterCrystalBattleCardWindow:choiceCard(index)
	for i, indexCheck in pairs(self.battleCardIds) do
		if indexCheck == -1 then
			self.battleCardIds[i] = index

			self["upCard" .. i]:setInfo({
				index = self.battleCardIds[i]
			})
			self["upCard" .. i]:SetActive(true)

			return
		end
	end

	xyd.showToast(__("TIME_CLOISTER_TEXT115"))
end

function TimeCloisterCrystalBattleCardWindow:cancelCard(index)
	for i, indexCheck in pairs(self.battleCardIds) do
		if indexCheck == index then
			self.battleCardIds[i] = -1

			self["upCard" .. i]:SetActive(false)

			return
		end
	end
end

function TimeCloisterCrystalBattleCardWindow:onClickUp(index, test)
	self:cancelCard(index)

	local tabindex = self.tabIndex
	tabindex = tabindex or 1
	tabindex = tabindex - 1

	self.itemGroupUIWrapContent:setInfos(self["setArr" .. tabindex], {
		keepPosition = true
	})
end

function CardItem:ctor(go, parent)
	self.parent = parent

	CardItem.super.ctor(self, go)
end

function CardItem:initUI()
	self.btnSet = self.go:NodeByName("btnSet").gameObject
	self.btnSetLabelDesc = self.btnSet:ComponentByName("labelDesc", typeof(UILabel))
	self.slotCardCon = self.go:NodeByName("slotCardCon").gameObject
	UIEventListener.Get(self.btnSet.gameObject).onClick = handler(self, function ()
		if self.parent:isUpYet(self.index) then
			self.parent:cancelCard(self.index)
		else
			self.parent:choiceCard(self.index)
		end

		self:updateState()
	end)
end

function CardItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	if not self.card then
		self.card = TimeCloisterScienceCard.new(self.slotCardCon, {})

		self.card:AddUIDragScrollView()
	end

	self.index = info

	self.card:setInfo({
		index = self.index
	})
	self:updateState()
end

function CardItem:updateState()
	if self.parent:isUpYet(self.index) then
		self.card:setChoose(true)

		self.btnSetLabelDesc.text = __("CANCEL_2")
	else
		self.card:setChoose(false)

		self.btnSetLabelDesc.text = __("TIME_CLOISTER_TEXT96")
	end
end

return TimeCloisterCrystalBattleCardWindow
