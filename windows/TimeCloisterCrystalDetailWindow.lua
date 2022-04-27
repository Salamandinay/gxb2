local TimeCloisterCrystalDetailWindow = class("TimeCloisterCrystalDetailWindow", import(".BaseWindow"))

function TimeCloisterCrystalDetailWindow:ctor(name, params)
	TimeCloisterCrystalDetailWindow.super.ctor(self, name, params)
end

function TimeCloisterCrystalDetailWindow:initWindow()
	self:getUIComponent()
	TimeCloisterCrystalDetailWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function TimeCloisterCrystalDetailWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.icon = self.groupAction:ComponentByName("icon", typeof(UISprite))
	self.nameLabel = self.groupAction:ComponentByName("nameLabel", typeof(UILabel))
	self.scoreLabel = self.groupAction:ComponentByName("scoreLabel", typeof(UILabel))
	self.levGroup = self.groupAction:NodeByName("levGroup").gameObject
	self.levGroupLabel = self.levGroup:ComponentByName("levGroupLabel", typeof(UILabel))
	self.levLabel = self.levGroup:ComponentByName("levLabel", typeof(UILabel))
	self.maxGroup = self.levGroup:NodeByName("maxGroup").gameObject
	self.imgMaxLev = self.maxGroup:ComponentByName("imgMaxLev", typeof(UISprite))
	self.textMaxLev = self.maxGroup:ComponentByName("textMaxLev", typeof(UILabel))
	self.priceGroup = self.groupAction:NodeByName("priceGroup").gameObject
	self.priceGroupLabel = self.priceGroup:ComponentByName("priceGroupLabel", typeof(UILabel))
	self.groupCost = self.priceGroup:NodeByName("groupCost").gameObject
	self.bg = self.groupCost:ComponentByName("bg", typeof(UISprite))

	for i = 1, 3 do
		self["cost" .. i] = self.groupCost:NodeByName("cost" .. i).gameObject
		self["costImg" .. i] = self["cost" .. i]:ComponentByName("costImg" .. i, typeof(UISprite))
		self["labelCost" .. i] = self["cost" .. i]:ComponentByName("labelCost" .. i, typeof(UILabel))
	end

	self.descBg = self.groupAction:ComponentByName("descBg", typeof(UISprite))
	self.scroller = self.groupAction:NodeByName("scroller").gameObject
	self.scrollerUIScrollView = self.groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.descLabel = self.scroller:ComponentByName("descLabel", typeof(UILabel))
	self.drag = self.groupAction:NodeByName("drag").gameObject
end

function TimeCloisterCrystalDetailWindow:layout()
	self.levGroupLabel.text = __("LEV")
	self.priceGroupLabel.text = __("HOUSE_TEXT_5")
	self.textMaxLev.text = __("MAX_LEV")
	local info = xyd.models.timeCloisterModel:getThreeCrystalCards(self.params_.index)
	self.id = info.card
	self.buyTimes = info.buy_times

	if xyd.Global.lang == "fr_fr" then
		self.levLabel.text = "Niv." .. xyd.tables.timeCloisterCrystalCardTable:getLevel(self.id)
	else
		self.levLabel.text = "Lv." .. xyd.tables.timeCloisterCrystalCardTable:getLevel(self.id)
	end

	self.nameLabel.text = xyd.tables.timeCloisterCrystalCardTextTable:getName(self.id)
	local cardNum = xyd.tables.timeCloisterCrystalCardTable:getCardNum(self.id)

	if cardNum and cardNum > 0 then
		self.timesText = "(" .. self.buyTimes .. "/" .. cardNum .. ")"
	else
		self.timesText = ""

		self.maxGroup.gameObject:SetActive(true)
	end

	self.levLabel.text = self.levLabel.text .. "  " .. self.timesText
	self.scoreLabel.text = __("TIME_CLOISTER_TEXT108") .. tostring(xyd.tables.timeCloisterCrystalCardTable:getPoint(self.id))

	if xyd.Global.lang == "fr_fr" then
		self.scoreLabel.text = __("TIME_CLOISTER_TEXT108") .. " " .. tostring(xyd.tables.timeCloisterCrystalCardTable:getPoint(self.id))
	end

	xyd.setUISpriteAsync(self.icon, nil, xyd.tables.timeCloisterCrystalCardTable:getImg(self.id), function ()
	end, nil, true)

	local cost = xyd.tables.timeCloisterCrystalCardTable:getCost(self.id)
	self.cost = cost

	for i, data in pairs(cost) do
		self["cost" .. i].gameObject:SetActive(true)
		xyd.setUISpriteAsync(self["costImg" .. i], nil, "icon_" .. data[1])

		self["labelCost" .. i].text = tostring(data[2])
	end

	for i = #cost + 1, 3 do
		self["cost" .. i].gameObject:SetActive(false)
	end

	self.bg.width = 130 + 122 * (#cost - 1)
	local skillId = xyd.tables.timeCloisterCrystalCardTable:getSkill(self.id)
	self.descLabel.text = xyd.tables.skillTextTable:getDesc(skillId)

	self.scrollerUIScrollView:ResetPosition()
end

function TimeCloisterCrystalDetailWindow:registerEvent()
end

return TimeCloisterCrystalDetailWindow
