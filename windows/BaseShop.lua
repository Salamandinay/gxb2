local BaseWindow = import(".BaseWindow")
local BaseShop = class("BaseShop", BaseWindow)

function BaseShop:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.shopModel_ = xyd.models.shop
	self.shopConfigTable_ = xyd.tables.shopConfigTable
	self.shopType_ = params.shopType
end

function BaseShop:initWindow()
	BaseWindow.initWindow(self)

	self.shopInfo_ = self.shopModel_:getShopInfo(self.shopType_)

	if not self.shopInfo_ or self.shopModel_:chargeRequstState(self.shopType_) then
		self.shopModel_:refreshShopInfo(self.shopType_)
	else
		self:layOutUI()
		self:updateShopRedMark()
	end
end

function BaseShop:layOutUI()
end

function BaseShop:initLayOut()
end

function BaseShop:refreshRes(event)
end

function BaseShop:buyItemRes(event)
end

function BaseShop:updateShopRedMark()
end

function BaseShop:register()
	BaseWindow.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_SHOP_INFO, handler(self, self.onShopInfo))
	self.eventProxy_:addEventListener(xyd.event.REFRESH_SHOP, handler(self, self.refreshRes))
	self.eventProxy_:addEventListener(xyd.event.BUY_SHOP_ITEM, handler(self, self.buyItemRes))
end

return BaseShop
