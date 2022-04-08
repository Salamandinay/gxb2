local Shop = class("Shop", import(".BaseModel"))
local cjson = require("cjson")

function Shop:ctor()
	Shop.super.ctor(self)

	self.shopList_ = {}
	self.redPoint_ = {}
	self.TableClase_ = {
		[xyd.ShopType.SHOP_HERO] = xyd.tables.shopHeroTable
	}
	self.requestTimeList_ = {}
end

function Shop:onRegister()
	Shop.super.onRegister(self)
	self:registerEvent(xyd.event.GET_SHOP_INFO, handler(self, self.onShopInfo))
	self:registerEvent(xyd.event.REFRESH_SHOP, handler(self, self.onRefreshShopInfo))
	self:registerEvent(xyd.event.BUY_SHOP_ITEM, handler(self, self.onShopInfo))
end

function Shop:onShopInfo(event)
	local params = event.data
	local shopType = params.shop_type

	if not self.shopList_[shopType] then
		self.shopList_[shopType] = {}
	end

	self.shopList_[shopType].items = params.items
	self.shopList_[shopType].refreshTime = params.refresh_time

	if params.end_time then
		self.shopList_[shopType].end_time = params.end_time
	end

	self.requestTimeList_[shopType] = xyd.getServerTime()

	self:updateShopRedMark(shopType)
end

function Shop:getShopInfo(shopType)
	return self.shopList_[shopType]
end

function Shop:updateShopRedMark(shopType)
	local shopType2RedMarkType = {
		[xyd.ShopType.SHOP_SKIN] = xyd.RedMarkType.SKIN_SHOP,
		[xyd.ShopType.SHOP_HERO_NEW] = xyd.RedMarkType.COFFEE_SHOP,
		[xyd.ShopType.SHOP_ARENA] = xyd.RedMarkType.ARENA_SHOP
	}
	local redMarkType = shopType2RedMarkType[shopType]

	if not redMarkType then
		return
	end

	local flag = self:checkShopHasNew(shopType)

	if not self.redPoint_[shopType] then
		self.redPoint_[shopType] = false
	end

	if flag ~= self.redPoint_[shopType] then
		xyd.models.redMark:setMark(redMarkType, flag)
	end

	self.redPoint_[shopType] = flag
end

function Shop:checkShopHasNew(shopType)
	if shopType == xyd.ShopType.SHOP_HERO_NEW then
		local nowTime = xyd.getServerTime()
		local ids = xyd.tables.shopHeroNewTable:getIds()

		for i = 1, #ids do
			local endTime = xyd.tables.shopHeroNewTable:getShopNew(i)
			local itemId = xyd.tables.shopHeroNewTable:getItemId(i)
			local lastTime = tonumber(xyd.db.misc:getValue("shop_hero_new_timestamp" .. itemId)) or 0

			if endTime > lastTime and nowTime < endTime then
				return true
			end
		end

		return false
	end

	local shopDBKey = xyd.tables.shopConfigTable:getRedMarkKey(shopType)
	local shopTable = xyd.tables.shopConfigTable:getShopTable(shopType)
	local ids = xyd.tables[shopTable]:getIds()
	local value = xyd.db.misc:getValue(shopDBKey)
	local recordedIds = nil

	if not value then
		recordedIds = {}
	else
		recordedIds = cjson.decode(value)
	end

	local nowTime = xyd.getServerTime()

	for _, id in ipairs(ids) do
		local endTime = xyd.tables[shopTable]:getShopNew(id)

		if endTime > 0 and nowTime < endTime and xyd.arrayIndexOf(recordedIds, id) < 1 then
			return true
		end
	end

	return false
end

function Shop:updateRedMark()
	local flag = self:blackShopFreeRefresh()

	if flag ~= self.redPoint_ then
		xyd.models.redMark:setMark(xyd.RedMarkType.MARKET, flag)
	end

	self.redPoint_ = flag
end

function Shop:onRefreshShopInfo(event)
	local params = event.data
	local shopType = params.shop_type

	if not self:judgeHasUnchangeItem(shopType) then
		self:onShopInfo(event)
	else
		self.shopList_[shopType].refreshTime = params.refresh_time
		local refresh_item = params.items
		local i = 1

		while i <= #refresh_item do
			if shopType ~= xyd.ShopType.SHOP_HERO or not xyd.tables.shopHeroTable:checkUnchangeByItemID(refresh_item[i].item[1]) then
				self.shopList_[shopType].items[i] = refresh_item[i]
			end

			i = i + 1
		end

		if shopType == xyd.ShopType.SHOP_BLACK then
			self:updateRedMark()
		end
	end
end

function Shop:judgeHasUnchangeItem(shopType)
	return self:getUnchangeNum(shopType) ~= 0
end

function Shop:getUnchangeNum(shopType)
	local tableInstance = self.TableClase_[shopType]

	if not tableInstance then
		return 0
	else
		return tableInstance:getUnchangeNumber()
	end
end

function Shop:buyUnchangeItem(shopType, index, num)
	if num == nil then
		num = 1
	end

	local buyTimes = self.shopList_[shopType].items[index].buy_times
	self.shopList_[shopType].items[index].buy_times = buyTimes + num
end

function Shop:chargeRequstState(shopType)
	if shopType == xyd.ShopType.SHOP_BLACK_NEW and self.requestTimeList_[shopType] then
		local week1 = xyd.getGMTWeekDay(self.requestTimeList_[shopType])
		local week2 = xyd.getGMTWeekDay(xyd.getServerTime())

		if week1 ~= week2 then
			return true
		end
	end

	return false
end

function Shop:refreshShopInfo(shopType)
	if not shopType then
		return
	end

	local msg = messages_pb.get_shop_info_req()
	msg.shop_type = shopType

	xyd.Backend.get():request(xyd.mid.GET_SHOP_INFO, msg)

	self.requestTimeList_[shopType] = xyd.getServerTime()
end

function Shop:refreshShop(shopType)
	if not shopType then
		return
	end

	local msg = messages_pb.refresh_shop_req()
	msg.shop_type = shopType

	xyd.Backend.get():request(xyd.mid.REFRESH_SHOP, msg)
end

function Shop:buyShopItem(shopType, index, num)
	if num == nil then
		num = 1
	end

	if not shopType or not index then
		return
	end

	local msg = messages_pb.buy_shop_item_req()
	msg.shop_type = shopType
	msg.index = index
	msg.num = num

	xyd.Backend.get():request(xyd.mid.BUY_SHOP_ITEM, msg)
end

return Shop
