local ActivityContent = import("app.windows.activity.ValueGiftBag")
local StarAltarGiftBag = class("StarAltarGiftBag", ActivityContent)
local CountDown = import("app.components.CountDown")

function StarAltarGiftBag:ctor(parentGO, params)
	StarAltarGiftBag.super.ctor(self, parentGO, params)
end

function StarAltarGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/star_altar_giftbag"
end

function StarAltarGiftBag:initTime()
	if self.activityData:getUpdateTime() - xyd.getServerTime() > 0 then
		local countdown = CountDown.new(self.labelTime, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime(),
			callback = handler(self, self.timeOver)
		})

		self.timeBg.gameObject:SetActive(true)
	else
		self.labelTime.text = "00:00:00"

		self.labelTime:SetActive(false)
		self.labelText01:SetActive(false)
		self.timeBg.gameObject:SetActive(false)
	end
end

function StarAltarGiftBag:onRegisterEvent()
	StarAltarGiftBag.super.onRegisterEvent(self)
	self:registerEvent(xyd.event.DAILY_GIFTBAG_FREE, handler(self, self.onFree))
end

function StarAltarGiftBag:onActivityData(event)
end

function StarAltarGiftBag:setTextures()
	self.timeBg = self.go:ComponentByName("timeBg", typeof(UISprite))

	self.timeBg.gameObject:SetActive(true)
	xyd.setUISpriteAsync(self.timeBg, nil, "new_partner_warmup_giftbag_time")
	xyd.setUISpriteAsync(self.imgText01, nil, "star_altar_giftbag_logo_" .. xyd.Global.lang, function ()
		self.imgText01:SetLocalPosition(143, -140, 0)
	end, nil, true)
	self.imgText02:SetActive(false)
	xyd.setUISpriteAsync(self.imgBg, nil, "star_altar_giftbag_bg", function ()
		self.imgBg.transform:Y(-352)

		self.imgBg.height = 704
	end)

	self.labelTime.fontSize = 22
	self.labelTime.color = Color.New2(4294967295.0)
	self.labelText01.fontSize = 22
	local height = self.go:GetComponent(typeof(UIWidget)).height

	self.labelTime.transform:Y(-240 - 20 * (height - 874) / 178)
	self.labelText01.transform:Y(-240 - 20 * (height - 874) / 178)
	self.timeBg.transform:Y(-240 - 20 * (height - 874) / 178)
	self.imgText01.transform:Y(-140 - 20 * (height - 874) / 178)

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" then
		self.labelTime.transform:X(145)
		self.labelText01.transform:X(150)
	end
end

function StarAltarGiftBag:setText()
	if xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" then
		self.labelTime.text = __("RESET")
	else
		self.labelText01.text = __("RESET")
	end
end

function StarAltarGiftBag:initTime()
	if self.activityData:getUpdateTime() - xyd.getServerTime() > 0 then
		if xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" then
			local countdown = CountDown.new(self.labelText01, {
				duration = self.activityData:getUpdateTime() - xyd.getServerTime(),
				callback = handler(self, self.timeOver)
			})
		else
			local countdown = CountDown.new(self.labelTime, {
				duration = self.activityData:getUpdateTime() - xyd.getServerTime(),
				callback = handler(self, self.timeOver)
			})
		end
	else
		self.labelTime.text = "00:00:00"

		self.labelTime:SetActive(false)
		self.labelText01:SetActive(false)
	end
end

function StarAltarGiftBag:getItemInfos()
	self.activityID = self.activityData.id
	local cantBuy = {}
	local t = {}
	local datas = self.activityData.detail.charges
	local freeCharge = self.activityData.detail.free_charge
	local freeData = xyd.tables.giftTable:getAwards(freeCharge.gift_id)

	if freeCharge.gift_id and freeCharge.gift_id > 0 then
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

	dump(t, "t")

	return t
end

function StarAltarGiftBag:onFree(event)
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

function StarAltarGiftBag:setItems()
	local t = self:getItemInfos()
	self.firstItemArr = t

	self.wrapContent:setInfos(t, {})

	local datas = self.activityData.detail.charges

	self:waitForFrame(2, function ()
		self:getScrollView():ResetPosition()
	end)
end

return StarAltarGiftBag
