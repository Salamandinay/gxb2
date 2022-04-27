local ActivityContent = import("app.windows.activity.DailyGiftBag")
local MonthlyGiftBag = class("MonthlyGiftBag", ActivityContent)
local CountDown = import("app.components.CountDown")

function MonthlyGiftBag:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)
end

function MonthlyGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/value_giftbag"
end

function MonthlyGiftBag:setTextures()
	xyd.setUISpriteAsync(self.imgText01, nil, "monthly_giftbag_text01_" .. xyd.Global.lang, nil, , true)

	if xyd.Global.lang == "en_en" then
		self.imgText01:SetLocalPosition(135, -115, 0)
	elseif xyd.Global.lang == "ja_jp" then
		self.imgText01:SetLocalPosition(150, -115, 0)
	elseif xyd.Global.lang == "de_de" then
		self.imgText01:SetLocalPosition(125, -115, 0)
	else
		self.imgText01:SetLocalPosition(165, -115, 0)
	end

	self.imgText02:SetActive(false)
	xyd.setUISpriteAsync(self.imgBg, nil, "monthly_bg01")

	self.labelTime.gameObject:GetComponent(typeof(UIWidget)).pivot = UIWidget.Pivot.Left

	self.labelTime:SetLocalPosition(150, -252, 0)

	self.labelText01.gameObject:GetComponent(typeof(UIWidget)).pivot = UIWidget.Pivot.Right

	self.labelText01:SetLocalPosition(143, -251.3, 0)
end

function MonthlyGiftBag:setText()
	self.labelText01.text = __("RESET")
end

function MonthlyGiftBag:getItemInfos()
	self.activityID = self.activityData.id
	self.discountActivityID = xyd.ActivityID.LIMIT_DISCOUNT_MONTHLY_GIFTBAG

	if self.activityID == xyd.ActivityID.MONTHLY_GIFTBAG02 then
		self.discountActivityID = xyd.ActivityID.LIMIT_DISCOUNT_MONTHLY_GIFTBAG02
	end

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

return MonthlyGiftBag
