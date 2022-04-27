local TimeCloisterCrystalChoiceWindow = class("TimeCloisterCrystalChoiceWindow", import(".BaseWindow"))

function TimeCloisterCrystalChoiceWindow:ctor(name, params)
	TimeCloisterCrystalChoiceWindow.super.ctor(self, name, params)
end

function TimeCloisterCrystalChoiceWindow:initWindow()
	self:getUIComponent()
	TimeCloisterCrystalChoiceWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function TimeCloisterCrystalChoiceWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.bg2 = self.groupAction:ComponentByName("bg2", typeof(UISprite))
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.labelDesc = self.groupAction:ComponentByName("labelDesc", typeof(UILabel))
	self.btnClose = self.groupAction:NodeByName("btnClose").gameObject
	self.items = self.groupAction:NodeByName("items").gameObject

	for i = 0, 4 do
		self["item" .. i] = self.items:NodeByName("item" .. i).gameObject
		self["bg" .. i] = self["item" .. i]:ComponentByName("bg" .. i, typeof(UISprite))
		self["selectBtn" .. i] = self["item" .. i]:NodeByName("selectBtn" .. i).gameObject
		self["imgSelect" .. i] = self["selectBtn" .. i]:ComponentByName("imgSelect" .. i, typeof(UISprite))
		self["label" .. i] = self["item" .. i]:ComponentByName("label" .. i, typeof(UILabel))

		if i == 1 or i == 2 or i == 3 then
			self["icon" .. i] = self["item" .. i]:ComponentByName("icon" .. i, typeof(UISprite))
		end
	end

	self.btnSet = self.groupAction:NodeByName("btnSet").gameObject
	self.btnSet = self.groupAction:ComponentByName("btnSet", typeof(UISprite))
	self.btnSetLabelDesc = self.btnSet:ComponentByName("labelDesc", typeof(UILabel))
end

function TimeCloisterCrystalChoiceWindow:registerEvent()
	UIEventListener.Get(self.btnClose.gameObject).onClick = handler(self, function ()
		self:close()
	end)

	for i = 0, 4 do
		UIEventListener.Get(self["bg" .. i].gameObject).onClick = handler(self, function ()
			if i ~= 0 then
				local tecMineArrs = xyd.models.timeCloisterModel:getTechInfoByCloister(xyd.TimeCloisterMissionType.THREE)[2]
				local tecId = xyd.tables.timeCloisterCrystalBuffTable:getTecId(i)[1]

				if tecMineArrs[tecId].curLv <= 0 then
					local name = xyd.tables.timeCloisterTecTextTable:getName(tecId)

					xyd.showToast(__("TIME_CLOISTER_TEXT113", name))

					return
				end
			end

			self.choiceYetId = i

			self:changeSelect()
		end)
	end

	UIEventListener.Get(self.btnSet.gameObject).onClick = handler(self, function ()
		if self.choiceYetId == xyd.models.timeCloisterModel:getThreeChoiceCrystalBuffId() then
			self:close()
		else
			xyd.models.timeCloisterModel:setChoiceInfo(xyd.TimeCloisterMissionType.THREE, self.choiceYetId)
		end
	end)
end

function TimeCloisterCrystalChoiceWindow:layout()
	self.labelTitle.text = __("TIME_CLOISTER_TEXT92")
	self.labelDesc.text = __("TIME_CLOISTER_TEXT93")
	self.btnSetLabelDesc.text = __("TIME_CLOISTER_TEXT96")
	self.choiceYetId = xyd.models.timeCloisterModel:getThreeChoiceCrystalBuffId()

	self:refreshChoice()
	self:changeSelect()
end

function TimeCloisterCrystalChoiceWindow:refreshChoice()
	for i = 0, 4 do
		local choiceId = i

		if choiceId == xyd.TimeCloisterThreeChoiceBuffType.NONE then
			self["label" .. i].text = __("TIME_CLOISTER_TEXT94")
		elseif choiceId == xyd.TimeCloisterThreeChoiceBuffType.ONE or choiceId == xyd.TimeCloisterThreeChoiceBuffType.TWO or choiceId == xyd.TimeCloisterThreeChoiceBuffType.THREE then
			xyd.setUISpriteAsync(self["icon" .. i], nil, xyd.tables.itemTable:getIcon(xyd.tables.timeCloisterCrystalBuffTable:getItems(choiceId)[1]))

			local lastNum = xyd.models.timeCloisterModel:getThreeChoiceCrystalBuffNum(choiceId)

			if choiceId == xyd.TimeCloisterThreeChoiceBuffType.ONE then
				self["label" .. i].text = "+" .. lastNum * 100 .. "%"
			elseif choiceId == xyd.TimeCloisterThreeChoiceBuffType.TWO then
				self["label" .. i].text = "+" .. lastNum * 100 .. "%"
			elseif choiceId == xyd.TimeCloisterThreeChoiceBuffType.THREE then
				self["label" .. i].text = "+" .. lastNum * 100 .. "%"
			end
		elseif choiceId == xyd.TimeCloisterThreeChoiceBuffType.ALL then
			local lastNum = xyd.models.timeCloisterModel:getThreeChoiceCrystalBuffNum(choiceId)
			self["label" .. i].text = __("TIME_CLOISTER_TEXT95", "3", "+" .. lastNum * 100 .. "%")
		end

		if i ~= 0 then
			local tecMineArrs = xyd.models.timeCloisterModel:getTechInfoByCloister(xyd.TimeCloisterMissionType.THREE)[2]
			local tecId = xyd.tables.timeCloisterCrystalBuffTable:getTecId(choiceId)[1]

			if tecMineArrs[tecId].curLv <= 0 then
				self["imgSelect" .. i].color = Color.New(0.71, 0.71, 0.71, 1)
			end
		end
	end
end

function TimeCloisterCrystalChoiceWindow:changeSelect()
	for i = 0, 4 do
		if i == self.choiceYetId then
			xyd.setUISpriteAsync(self["imgSelect" .. i], nil, "setting_up_pick")
		else
			xyd.setUISpriteAsync(self["imgSelect" .. i], nil, "setting_up_unpick")
		end
	end
end

return TimeCloisterCrystalChoiceWindow
