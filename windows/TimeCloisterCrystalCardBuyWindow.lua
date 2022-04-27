local TimeCloisterCrystalCardBuyWindow = class("TimeCloisterCrystalCardBuyWindow", import(".BaseWindow"))
local ChoiceCardItem = class("ChoiceCardItem", import("app.components.CopyComponent"))
local TimeCloisterScienceCard = import("app.components.TimeCloisterScienceCard")

function TimeCloisterCrystalCardBuyWindow:ctor(name, params)
	TimeCloisterCrystalCardBuyWindow.super.ctor(self, name, params)
end

function TimeCloisterCrystalCardBuyWindow:initWindow()
	self:getUIComponent()
	TimeCloisterCrystalCardBuyWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function TimeCloisterCrystalCardBuyWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.btnClose = self.groupAction:NodeByName("btnClose").gameObject
	self.helpBtn = self.groupAction:NodeByName("helpBtn").gameObject
	self.groupUp = self.groupAction:NodeByName("groupUp").gameObject
	self.resetBtn = self.groupUp:NodeByName("resetBtn").gameObject
	self.caseLabel = self.groupUp:ComponentByName("caseLabel", typeof(UILabel))
	self.caseIconCon = self.groupUp:NodeByName("caseIconCon").gameObject
	self.caseIcon = self.caseIconCon:ComponentByName("caseIcon", typeof(UISprite))
	self.caseIconLabel = self.caseIconCon:ComponentByName("caseIconLabel", typeof(UILabel))

	for i = 1, 3 do
		self["resItemCon" .. i] = self.groupUp:NodeByName("resItemCon" .. i).gameObject
		self["resItem" .. i] = self["resItemCon" .. i]:NodeByName("res_item").gameObject
		self["resIcon" .. i] = self["resItem" .. i]:ComponentByName("res_icon", typeof(UISprite))
		self["resNumLabel" .. i] = self["resItem" .. i]:ComponentByName("res_num_label", typeof(UILabel))
	end

	self.groupCenter = self.groupAction:NodeByName("groupCenter").gameObject
	self.labelDesc = self.groupCenter:ComponentByName("labelDesc", typeof(UILabel))
	self.slot = self.groupCenter:NodeByName("slot").gameObject
	self.scoreGroup = self.groupCenter:NodeByName("scoreGroup").gameObject
	self.scoreLabel = self.scoreGroup:ComponentByName("scoreLabel", typeof(UILabel))
	self.groupAttr = self.groupCenter:NodeByName("groupAttr").gameObject
	self.labelYQ = self.groupAttr:ComponentByName("labelYQ", typeof(UILabel))
	self.labelML = self.groupAttr:ComponentByName("labelML", typeof(UILabel))
	self.labelZS = self.groupAttr:ComponentByName("labelZS", typeof(UILabel))
	self.tipsBtn = self.groupCenter:NodeByName("tipsBtn").gameObject
	self.detailBtn = self.groupAction:NodeByName("detailBtn").gameObject
	self.detailBtnLabelDesc = self.detailBtn:ComponentByName("labelDesc", typeof(UILabel))
	self.skillBtn = self.groupAction:NodeByName("skillBtn").gameObject
	self.skillBtnLabelDesc = self.skillBtn:ComponentByName("labelDesc", typeof(UILabel))
	self.skillBtnRedPoint = self.skillBtn:NodeByName("skillBtnRedPoint").gameObject

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.TIME_CLOISTER_RED_THREE_SET_BATTLE_IDS
	}, self.skillBtnRedPoint)
end

function TimeCloisterCrystalCardBuyWindow:registerEvent()
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "TIME_CLOISTER_TEXT107"
		})
	end)
	UIEventListener.Get(self.btnClose.gameObject).onClick = handler(self, function ()
		self:close()
	end)

	for i = 1, 3 do
		local resArr = xyd.tables.miscTable:split2num("time_cloister_crystal_card_item", "value", "|")
		UIEventListener.Get(self["resItem" .. i].gameObject).onClick = handler(self, function ()
			local params = {
				itemID = resArr[i]
			}

			xyd.WindowManager.get():openWindow("item_tips_window", params)
		end)
	end

	UIEventListener.Get(self.resetBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("time_cloister_crystal_choice_window", {})
	end)
	UIEventListener.Get(self.tipsBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("time_cloister_crystal_show_next_window", {})
	end)
	UIEventListener.Get(self.skillBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("time_cloister_crystal_battle_card_window", {})
	end)
	UIEventListener.Get(self.detailBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("time_cloister_crystal_list_window", {})
	end)

	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.refreshItem))
	self.eventProxy_:addEventListener(xyd.event.TIME_CLOISTER_CRYSTAL_BUY_CARD, handler(self, self.onBackThreeCrystalBuyCards))
	self.eventProxy_:addEventListener(xyd.event.TIME_CLOISTER_COMMON_SET_CHOICE, handler(self, self.refreshChoice))
end

function TimeCloisterCrystalCardBuyWindow:layout()
	self.labelTitle.text = __("TIME_CLOISTER_TEXT102")
	self.caseLabel.text = __("TIME_CLOISTER_TEXT103")
	self.detailBtnLabelDesc.text = __("TIME_CLOISTER_TEXT104")
	self.skillBtnLabelDesc.text = __("TIME_CLOISTER_TEXT105")
	self.labelDesc.text = __("TIME_CLOISTER_TEXT106")
	local tmp2 = NGUITools.AddChild(self.groupCenter.gameObject, self.slot.gameObject)
	local tmp3 = NGUITools.AddChild(self.groupCenter.gameObject, self.slot.gameObject)
	self.card1 = ChoiceCardItem.new(self.slot, self)
	self.card2 = ChoiceCardItem.new(tmp2, self)
	self.card3 = ChoiceCardItem.new(tmp3, self)

	for i = 1, 3 do
		self["card" .. i]:getGameObject():SetLocalPosition(-203 + 203 * (i - 1), 54, 0)
	end

	self:refreshItem()
	self:update()
	self:refreshChoice()
end

function TimeCloisterCrystalCardBuyWindow:update()
	local point = xyd.models.timeCloisterModel:getThreeCrystalPoint()
	self.scoreLabel.text = __("TIME_CLOISTER_TEXT108") .. " " .. point
	local pointId = xyd.tables.timeCloisterCrystalPointTable:getPointToId(point)
	self.labelYQ.text = "：+" .. xyd.tables.timeCloisterCrystalPointTable:getBase1(pointId)
	self.labelML.text = "：+" .. xyd.tables.timeCloisterCrystalPointTable:getBase2(pointId)
	self.labelZS.text = "：+" .. xyd.tables.timeCloisterCrystalPointTable:getBase3(pointId)
	local buyIds = xyd.models.timeCloisterModel:getThreeCrystalShops()

	for i in pairs(buyIds) do
		local params = {
			index = buyIds[i],
			itemI = i
		}

		self["card" .. i]:setInfo(params)
	end
end

function TimeCloisterCrystalCardBuyWindow:refreshChoice()
	local choiceId = xyd.models.timeCloisterModel:getThreeChoiceCrystalBuffId()

	if choiceId == xyd.TimeCloisterThreeChoiceBuffType.NONE then
		self.caseIcon.gameObject:SetLocalScale(0, 0, 0)

		self.caseIconLabel.text = __("TIME_CLOISTER_TEXT94")
	elseif choiceId == xyd.TimeCloisterThreeChoiceBuffType.ONE or choiceId == xyd.TimeCloisterThreeChoiceBuffType.TWO or choiceId == xyd.TimeCloisterThreeChoiceBuffType.THREE then
		self.caseIcon.gameObject:SetLocalScale(0.5, 0.5, 0)
		xyd.setUISpriteAsync(self.caseIcon, nil, xyd.tables.itemTable:getIcon(xyd.tables.timeCloisterCrystalBuffTable:getItems(choiceId)[1]))

		local lastNum = xyd.models.timeCloisterModel:getThreeChoiceCrystalBuffNum(choiceId)

		if choiceId == xyd.TimeCloisterThreeChoiceBuffType.ONE then
			self.caseIconLabel.text = "+" .. lastNum * 100 .. "%"
		elseif choiceId == xyd.TimeCloisterThreeChoiceBuffType.TWO then
			self.caseIconLabel.text = "+" .. lastNum * 100 .. "%"
		elseif choiceId == xyd.TimeCloisterThreeChoiceBuffType.THREE then
			self.caseIconLabel.text = "+" .. lastNum * 100 .. "%"
		end
	elseif choiceId == xyd.TimeCloisterThreeChoiceBuffType.ALL then
		self.caseIcon.gameObject:SetLocalScale(0, 0, 0)

		local lastNum = xyd.models.timeCloisterModel:getThreeChoiceCrystalBuffNum(choiceId)
		self.caseIconLabel.text = __("TIME_CLOISTER_TEXT95", "3", "+" .. lastNum * 100 .. "%")
	end
end

function TimeCloisterCrystalCardBuyWindow:refreshItem()
	if not self.resArr then
		self.resArr = xyd.tables.miscTable:split2num("time_cloister_crystal_card_item", "value", "|")
	end

	for i in pairs(self.resArr) do
		if not self.isInitResIcon then
			xyd.setUISpriteAsync(self["resIcon" .. i], nil, "icon_" .. self.resArr[i] .. "_small", function ()
			end, nil, true)

			if i == #self.resArr then
				self.isInitResIcon = true
			end
		end

		self["resNumLabel" .. i].text = tostring(xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(self.resArr[i])))
	end
end

function TimeCloisterCrystalCardBuyWindow:sendBuyCards(itemI)
	xyd.models.timeCloisterModel:sendThreeCrystalBuyCards(itemI)

	for i = 1, 3 do
		self["card" .. i]:setBtnState(false)
	end
end

function TimeCloisterCrystalCardBuyWindow:onBackThreeCrystalBuyCards()
	self:update()

	for i = 1, 3 do
		self["card" .. i]:setBtnState(true)
	end
end

function ChoiceCardItem:ctor(goItem, parent)
	self.parent = parent

	ChoiceCardItem.super.ctor(self, goItem)
end

function ChoiceCardItem:initUI()
	self:getUIComponent()
	self:layout()
end

function ChoiceCardItem:getUIComponent()
	self.slotCardCon = self.go:NodeByName("slotCardCon").gameObject
	self.iconGroup = self.go:ComponentByName("iconGroup", typeof(UISprite)).gameObject
	self.iconGroup2 = self.iconGroup:NodeByName("iconGroup").gameObject
	self.iconGroup2Layout = self.iconGroup:ComponentByName("iconGroup", typeof(UILayout))

	for i = 1, 3 do
		self["iconItem" .. i] = self.iconGroup2:ComponentByName("iconItem" .. i, typeof(UISprite))
		self["iconItemNum" .. i] = self["iconItem" .. i]:ComponentByName("iconItemNum" .. i, typeof(UILabel))
	end

	self.skillBtn = self.go:NodeByName("skillBtn").gameObject
	self.skillBtnBoxCollider = self.go:ComponentByName("skillBtn", typeof(UnityEngine.BoxCollider))
	self.skillBtnLabelDesc = self.skillBtn:ComponentByName("labelDesc", typeof(UILabel))
	UIEventListener.Get(self.skillBtn.gameObject).onClick = handler(self, function ()
		for i, data in pairs(self.cost) do
			if xyd.models.backpack:getItemNumByID(data[1]) < data[2] then
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(data[1])))

				return
			end
		end

		self.parent:sendBuyCards(self.itemI)
	end)
end

function ChoiceCardItem:layout()
	self.skillBtnLabelDesc.text = __("BUY2")

	if not self.card then
		self.card = TimeCloisterScienceCard.new(self.slotCardCon, {})
	end
end

function ChoiceCardItem:setInfo(params)
	self.index = params.index
	self.itemI = params.itemI

	self.card:setInfo(params)

	local id = xyd.models.timeCloisterModel:getThreeCrystalCards(self.index).card
	local cost = xyd.tables.timeCloisterCrystalCardTable:getCost(id)
	self.cost = cost

	for i, data in pairs(cost) do
		self["iconItem" .. i].gameObject:SetActive(true)
		xyd.setUISpriteAsync(self["iconItem" .. i], nil, "icon_" .. data[1])

		self["iconItemNum" .. i].text = tostring(data[2])
	end

	for i = #cost + 1, 3 do
		self["iconItem" .. i].gameObject:SetActive(false)
	end

	self.iconGroup2Layout:Reposition()
end

function ChoiceCardItem:setBtnState(state)
	self.skillBtnBoxCollider.enabled = state
end

return TimeCloisterCrystalCardBuyWindow
