local TimeCloisterCrystalShowNextWindow = class("TimeCloisterCrystalShowNextWindow", import(".BaseWindow"))
local addItem = class("addItem", import("app.components.CopyComponent"))

function TimeCloisterCrystalShowNextWindow:ctor(name, params)
	TimeCloisterCrystalShowNextWindow.super.ctor(self, name, params)
end

function TimeCloisterCrystalShowNextWindow:initWindow()
	self:getUIComponent()
	TimeCloisterCrystalShowNextWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function TimeCloisterCrystalShowNextWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.nameLabel = self.groupAction:ComponentByName("nameLabel", typeof(UILabel))
	self.bg2 = self.groupAction:ComponentByName("bg2", typeof(UISprite))
	self.addItem = self.groupAction:NodeByName("addItem").gameObject
	self.maxIcon = self.groupAction:ComponentByName("maxIcon", typeof(UISprite))
end

function TimeCloisterCrystalShowNextWindow:registerEvent()
end

function TimeCloisterCrystalShowNextWindow:layout()
	self.nameLabel.text = __("TIME_CLOISTER_TEXT88")

	xyd.setUISpriteAsync(self.maxIcon, nil, "pet_skill_max_" .. xyd.Global.lang, nil, , true)

	local point = xyd.models.timeCloisterModel:getThreeCrystalPoint()
	local pointId = xyd.tables.timeCloisterCrystalPointTable:getPointToId(point)
	local item = addItem.new(self.addItem, self, {
		index = 1,
		point = point,
		id = pointId
	})
	local allIds = xyd.tables.timeCloisterCrystalPointTable:getIDs()

	if pointId and pointId == allIds[#allIds] then
		self.maxIcon.gameObject:SetActive(true)
	else
		local tmp = NGUITools.AddChild(self.groupAction.gameObject, self.addItem.gameObject)

		addItem.new(tmp, self, {
			index = 2,
			point = xyd.tables.timeCloisterCrystalPointTable:getPoint(pointId + 1),
			id = pointId + 1
		})
		tmp.gameObject:Y(-120)
		self.maxIcon.gameObject:SetActive(false)
	end
end

function addItem:ctor(goItem, parent, params)
	self.parent = parent
	self.params = params

	addItem.super.ctor(self, goItem)
end

function addItem:initUI()
	self.addItem = self.go
	self.addbg = self.addItem:ComponentByName("addbg", typeof(UISprite))
	self.addLabel = self.addItem:ComponentByName("addLabel", typeof(UILabel))
	self.scoreGroup = self.addItem:NodeByName("scoreGroup").gameObject
	self.addScoreLabel = self.scoreGroup:ComponentByName("addScoreLabel", typeof(UILabel))
	self.addScoreNumLabel = self.scoreGroup:ComponentByName("addScoreNumLabel", typeof(UILabel))
	self.addValueGroup = self.addItem:NodeByName("addValueGroup").gameObject
	self.addvalueLabel = self.addValueGroup:ComponentByName("addvalueLabel", typeof(UILabel))
	self.addValueIconGroup = self.addValueGroup:NodeByName("addValueIconGroup").gameObject

	for i = 1, 3 do
		self["cost" .. i] = self.addValueIconGroup:NodeByName("cost" .. i).gameObject
		self["costImg" .. i] = self["cost" .. i]:ComponentByName("costImg" .. i, typeof(UISprite))
		self["labelCost" .. i] = self["cost" .. i]:ComponentByName("labelCost" .. i, typeof(UILabel))
	end

	self:layout()
end

function addItem:layout()
	if self.params.index == 1 then
		self.addLabel.text = __("TIME_CLOISTER_TEXT89")
		self.addScoreLabel.text = __("TIME_CLOISTER_TEXT90") .. "："
	elseif self.params.index == 2 then
		self.addLabel.text = __("TIME_CLOISTER_TEXT112")
		self.addScoreLabel.text = __("TIME_CLOISTER_TEXT111") .. "："
	end

	self.addScoreNumLabel.text = self.params.point
	self.addvalueLabel.text = __("TIME_CLOISTER_TEXT91") .. "："

	for i = 1, 3 do
		self["labelCost" .. i].text = "：+" .. xyd.tables.timeCloisterCrystalPointTable["getBase" .. i](xyd.tables.timeCloisterCrystalPointTable, self.params.id)
	end
end

return TimeCloisterCrystalShowNextWindow
