local ItemPurchaseWindow = class("ItemPurchaseWindow", import(".ItemBuyWindow"))

function ItemPurchaseWindow:ctor(name, params)
	ItemPurchaseWindow.super.ctor(self, name, params)

	self.ifHideMinMax = true
	self.exchangeID_ = params.exchange_id
	local exchange = xyd.tables.itemExchangeTable:getExchangeItem(self.exchangeID_)
	self.itemParams_ = {
		itemID = exchange[1]
	}
	self.exchangeNum = exchange[2]
	self.cost_ = xyd.tables.itemExchangeTable:getCost(self.exchangeID_)
end

function ItemPurchaseWindow:exchangeItemRequest()
	if not self.purchaseNum_ then
		return
	end

	local costs = self.cost_
	local costItemID = costs[1]
	local costNum = costs[2]

	if self.backpack_:getItemNumByID(costItemID) < costNum * self.purchaseNum_ then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(costItemID)))
	else
		local msg = messages_pb.item_exchange_req()
		msg.id = self.exchangeID_
		msg.num = self.purchaseNum_

		xyd.Backend.get():request(xyd.mid.ITEM_EXCHANGE, msg)
	end

	if self.buyCallBack then
		self.buyCallBack(self.purchaseNum_)
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

return ItemPurchaseWindow
