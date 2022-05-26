local ItemTips = import(".ItemTips")
local ItemCollectionTips = import(".ItemCollectionTips")
local ItemTipsWindow = class("ItemTipsWindow", import(".BaseWindow"))

function ItemTipsWindow:ctor(name, params)
	ItemTipsWindow.super.ctor(self, name, params)

	self.closeCallback = params.callback
	self.winType_ = params.wndType
end

function ItemTipsWindow:initWindow()
	ItemTipsWindow.super.initWindow(self)

	local parentGO = self.window_:NodeByName("groupAction").gameObject
	local tips = nil

	if self.winType_ == xyd.ItemTipsWndType.COLLECTION then
		tips = ItemCollectionTips.new(parentGO, self.params_)
	else
		tips = ItemTips.new(parentGO, self.params_)
	end

	self.itemTips_ = tips
end

function ItemTipsWindow:getWinType()
	return self.winType_
end

function ItemTipsWindow:excuteCallBack(isCloseAll)
	if isCloseAll then
		return
	end

	if self.closeCallback ~= nil then
		self.closeCallback()
	end
end

function ItemTipsWindow:addTips(params)
	if self.diffItemTips then
		NGUITools.Destory(self.diffItemTips.go.transform)
	end

	local parentGO = self.window_:NodeByName("groupAction").gameObject
	local windowDepth = self.window_:GetComponent(typeof(UIPanel)).depth
	local tableComponent = parentGO:AddComponent(typeof(UITable))
	tableComponent.columns = 1
	tableComponent.pivot = UIWidget.Pivot.Center
	tableComponent.cellAlignment = UIWidget.Pivot.Center
	self.diffItemTips = ItemTips.new(parentGO, params, windowDepth)

	tableComponent:Reposition()
end

return ItemTipsWindow
