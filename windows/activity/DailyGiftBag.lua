local ActivityContent = import("app.windows.activity.ValueGiftBag")
local DailyGiftBag = class("DailyGiftBag", ActivityContent)
local CountDown = import("app.components.CountDown")

function DailyGiftBag:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)
end

function DailyGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/value_giftbag"
end

function DailyGiftBag:onRegisterEvent()
	DailyGiftBag.super.onRegisterEvent(self)
	self:registerEvent(xyd.event.DAILY_GIFTBAG_FREE, handler(self, self.onFree))
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityData))
end

function DailyGiftBag:onActivityData()
	local giftBagID = self.activityData:getGiftBagID()
	local giftBagIDAfter = giftBagID

	if xyd.tables.giftBagTable:getParams(giftBagID) and xyd.tables.giftBagTable:getParams(giftBagID)[1] then
		giftBagIDAfter = xyd.tables.giftBagTable:getParams(giftBagID)[1]
	end

	local t = self:getItemInfos()
	local isGoOn = false

	for i in pairs(t) do
		for j in pairs(self.firstItemArr) do
			if giftBagIDAfter == t[i].giftBagID and giftBagID == self.firstItemArr[j].giftBagID then
				self.firstItemArr[j] = t[i]
				isGoOn = true

				break
			end
		end

		if isGoOn then
			break
		end
	end

	self.wrapContent:setInfos(self.firstItemArr, {})
end

function DailyGiftBag:setTextures()
	xyd.setUISpriteAsync(self.imgText01, nil, "daily_giftbag_text01_" .. xyd.Global.lang, function ()
		self.imgText01:SetLocalPosition(143, -140, 0)
	end, nil, true)
	self.imgText02:SetActive(false)
	xyd.setUISpriteAsync(self.imgBg, nil, "daily_bg01", function ()
	end)

	self.labelTime.fontSize = 19
	self.labelTime.effectStyle = UILabel.Effect.None
	self.labelTime.color = Color.New2(4294967295.0)

	self.labelTime:SetLocalPosition(226.1, -272.79, 0)

	self.labelText01.fontSize = 19
	self.labelText01.effectStyle = UILabel.Effect.None

	self.labelText01:SetLocalPosition(81.9, -272.79, 0)

	if xyd.Global.lang == "fr_fr" then
		self.labelTime:X(250)
		self.labelText01:X(50)

		self.labelText01.fontSize = 17
	elseif xyd.Global.lang == "ja_jp" then
		self.labelTime:X(245)
		self.labelText01:X(65)
	elseif xyd.Global.lang == "ko_kr" then
		self.labelText01:X(75)
	elseif xyd.Global.lang == "de_de" then
		self.labelTime:X(255)
		self.labelText01:X(50)

		self.labelText01.fontSize = 16
	end
end

function DailyGiftBag:setText()
	self.labelText01.text = __("RESET")
end

function DailyGiftBag:getItemInfos()
	self.activityID = self.activityData.id
	self.discountActivityID = self.activityID == xyd.ActivityID.DAILY_GIFGBAG and xyd.ActivityID.LIMIT_DISCOUNT_DAILY_GIFGBAG or xyd.ActivityID.LIMIT_DISCOUNT_DAILY_GIFGBAG02
	self.discountGiftBagIDs = xyd.tables.activityTable:getGiftBag(self.discountActivityID)
	local cantBuy = {}
	local t = {}
	local datas = self.activityData.detail.charges
	local freeCharge = self.activityData.detail.free_charge
	local freeData = xyd.tables.giftTable:getAwards(freeCharge.gift_id)
	local freeItem = {
		isFree = true,
		activityid = self.activityData.id,
		giftBagID = freeCharge.gift_id,
		data = freeData,
		parentScroller = self.scroller,
		isFreeCan = freeCharge.awarded
	}

	if freeCharge.awarded ~= 0 then
		table.insert(cantBuy, freeItem)
	else
		table.insert(t, freeItem)
	end

	local giftIDs = xyd.tables.activityTable:getGiftBag(self.activityID)
	local giftIndex = {}

	for i, v in ipairs(giftIDs) do
		giftIndex[v] = i
	end

	table.sort(datas, function (a, b)
		return (giftIndex[a.table_id] or a.table_id) < (giftIndex[b.table_id] or b.table_id)
	end)

	for i = 1, #datas do
		local data = datas[i]
		local isDiscount = false
		local originTableID = data.table_id

		for j = 1, #self.discountGiftBagIDs do
			if data.table_id == self.discountGiftBagIDs[i] then
				isDiscount = true
				originTableID = xyd.tables.giftBagTable:getParams(data.table_id)[1]

				break
			end
		end

		if data.table_id == 376 or data.table_id == 382 then
			isDiscount = false
		end

		data.isDiscount = isDiscount
		data.originPrice = __("SALE_MONTH_GIFTBAG1") .. " " .. tostring(xyd.tables.giftBagTextTable:getCurrency(originTableID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(originTableID))
		local id = data.table_id
		local params = {
			giftBagID = id,
			data = data,
			parentScroller = self.scroller
		}

		if xyd.tables.giftBagTable:getBuyLimit(id) <= data.buy_times then
			table.insert(cantBuy, params)
		else
			table.insert(t, params)
		end
	end

	for i = 1, #cantBuy do
		local params = cantBuy[i]

		table.insert(t, params)
	end

	return t
end

function DailyGiftBag:onFree(event)
	local data = event.data
	local items = data.items

	xyd.itemFloat(items, nil, , self.scroller_Panel.depth + 1)
	self.activityData:updateInfo({
		awarded = 1
	})
	xyd.EventDispatcher.inner():dispatchEvent({
		name = "updateBt"
	})
end

return DailyGiftBag
