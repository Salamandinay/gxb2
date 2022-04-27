local ArcticExpeditionCellDetailWindow = class("ArcticExpeditionCellDetailWindow", import(".BaseWindow"))

function ArcticExpeditionCellDetailWindow:ctor(name, params)
	ArcticExpeditionCellDetailWindow.super.ctor(self, name, params)

	self.cellID_ = params.cell_id
	self.cellType_ = xyd.tables.arcticExpeditionCellsTable:getCellType(self.cellID_)
end

function ArcticExpeditionCellDetailWindow:initWindow()
	ArcticExpeditionCellDetailWindow.super.initWindow(self)
	self:getUIComponent()
	self:initLayout()
end

function ArcticExpeditionCellDetailWindow:getUIComponent()
	local winTrans = self.window_.transform:NodeByName("groupAction")
	self.guidePos = winTrans:NodeByName("bg").gameObject
	self.labelDesc_ = winTrans:ComponentByName("labelDesc", typeof(UILabel))
	self.labelText_ = winTrans:ComponentByName("imgBg/labelText", typeof(UILabel))

	for i = 1, 3 do
		self["attrText" .. i] = winTrans:ComponentByName("attrGroup" .. i .. "/labelName", typeof(UILabel))
		self["labelValue" .. i] = winTrans:ComponentByName("attrGroup" .. i .. "/labelValue", typeof(UILabel))
	end
end

function ArcticExpeditionCellDetailWindow:initLayout()
	self.labelText_.text = __("ARCTIC_EXPEDITION_TEXT_55")
	self.attrText1.text = __("ARCTIC_EXPEDITION_TEXT_56")
	self.attrText2.text = __("ARCTIC_EXPEDITION_TEXT_57")
	self.attrText3.text = __("ARCTIC_EXPEDITION_TEXT_58")
	local scorePreiod = xyd.tables.arcticExpeditionCellsTypeTable:getScorePeriod(self.cellType_)
	self.labelDesc_.text = xyd.tables.arcticExpeditionCellsTypeTextTable:getDesc(self.cellType_)
	self.labelValue1.text = xyd.tables.arcticExpeditionCellsTypeTable:getScoreFirst(self.cellType_)

	if scorePreiod and scorePreiod > 0 then
		self.labelValue2.text = math.ceil(xyd.DAY_TIME / xyd.tables.arcticExpeditionCellsTypeTable:getScorePeriod(self.cellType_))
	else
		self.labelValue2.text = "-"
	end

	self.labelValue3.text = xyd.tables.arcticExpeditionCellsTypeTable:getContribution(self.cellType_)
end

return ArcticExpeditionCellDetailWindow
