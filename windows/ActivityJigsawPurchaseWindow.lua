local LimitItemPurchaseWindow = import(".LimitItemPurchaseWindow")
local ActivityJigsawPurchaseWindow = class("ActivityJigsawPurchaseWindow", LimitItemPurchaseWindow)

function ActivityJigsawPurchaseWindow:ctor(name, params)
	ActivityJigsawPurchaseWindow.super.ctor(self, name, params)

	self.textArray_ = params.textArray
end

function ActivityJigsawPurchaseWindow:initWindow()
	ActivityJigsawPurchaseWindow.super.initWindow(self)
	self:setLabelText()
end

function ActivityJigsawPurchaseWindow:setLabelText()
	for i = 1, #self.textArray_ do
		self["textLabel" .. i].text = self.textArray_[i]
	end
end

function ActivityJigsawPurchaseWindow:getUIComponent()
	local winTrans = self.window_.transform
	local allGroup = winTrans:NodeByName("groupAction").gameObject
	self.bgImg = allGroup:NodeByName("e:Image").gameObject
	local upGroup = allGroup:NodeByName("upGroup").gameObject
	self.labelTitle = upGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = upGroup:NodeByName("closeBtn").gameObject
	self.groupItem = allGroup:NodeByName("groupItem").gameObject
	self.textInputCon = allGroup:NodeByName("textInput").gameObject
	self.btnSure = allGroup:NodeByName("btnSure").gameObject
	self.btnSure_button_label = allGroup:ComponentByName("btnSure/button_label", typeof(UILabel))
	self.numGroup = allGroup:NodeByName("numGroup").gameObject
	self.ImgExchange = allGroup:ComponentByName("numGroup/ImgExchange", typeof(UISprite))
	self.labelTotal = allGroup:ComponentByName("numGroup/labelTotal", typeof(UILabel))
	self.labelSplit = allGroup:ComponentByName("numGroup/labelSplit", typeof(UILabel))
	self.labelCost = allGroup:ComponentByName("numGroup/labelCost", typeof(UILabel))
	self.textLabel1 = allGroup:ComponentByName("textLabel0", typeof(UILabel))
	self.textLabel2 = allGroup:ComponentByName("textLabel1", typeof(UILabel))

	if xyd.Global.lang == "fr_fr" then
		self.textLabel2:Y(58)
	end
end

return ActivityJigsawPurchaseWindow
