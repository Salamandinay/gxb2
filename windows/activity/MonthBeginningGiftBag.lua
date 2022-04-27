local ActivityContent = import("app.windows.activity.ValueGiftBag")
local MonthBeginningGiftBag = class("MonthBeginningGiftBag", ActivityContent)
local CountDown = import("app.components.CountDown")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function MonthBeginningGiftBag:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)
end

function MonthBeginningGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/month_beginning_giftbag"
end

function MonthBeginningGiftBag:initUIComponent()
	MonthBeginningGiftBag.super.initWrapContent(self)
	self:setItems()
	self:setTextures()
	self:initTime()
end

function MonthBeginningGiftBag:getUIComponent()
	local go = self.go
	self.floatCon = go:NodeByName("floatCon").gameObject
	self.imgBg = go:ComponentByName("imgBg", typeof(UITexture))
	self.imgText01 = go:ComponentByName("imgText01", typeof(UITexture))
	self.monthText = self.imgText01:ComponentByName("monthText", typeof(UILabel))
	self.imgText02 = go:ComponentByName("imgText02", typeof(UISprite))
	self.imgText02_layout = go:ComponentByName("imgText02", typeof(UILayout))
	self.labelTime = self.imgText02.gameObject:ComponentByName("labelTime", typeof(UILabel))
	self.labelText01 = self.imgText02.gameObject:ComponentByName("labelText01", typeof(UILabel))
	self.e_Image = go:ComponentByName("e:Image", typeof(UISprite))
	self.scroller = go:ComponentByName("scroller", typeof(UIScrollView))
	self.scroller_Panel = go:ComponentByName("scroller", typeof(UIPanel))
	self.groupPackage = go:NodeByName("scroller/groupPackage").gameObject
	self.common_giftbag_item = go:NodeByName("common_giftbag_item").gameObject
	self.wrapContentCon = go:ComponentByName("scroller/groupPackage", typeof(UIWrapContent))
	self.e_Image2 = go:ComponentByName("e:Image2", typeof(UISprite))

	self:initWrapContent()
	self.imgText01:Y(-187 + -81 * self.scale_num_contrary)
	self.imgText02:Y(-337 + -81 * self.scale_num_contrary)
end

function MonthBeginningGiftBag:initWrapContent()
end

function MonthBeginningGiftBag:onRegisterEvent()
	MonthBeginningGiftBag.super.onRegisterEvent(self)
	self:registerEvent(xyd.event.DAILY_GIFTBAG_FREE, handler(self, self.onFree))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onCrystal))
end

function MonthBeginningGiftBag:setTextures()
	xyd.setUITextureByNameAsync(self.imgText01, "activity_month_gift_hello_" .. xyd.Global.lang, true)
	xyd.setUISpriteAsync(self.imgText02, nil, "activity_month_gift_time_bg", nil, )
	xyd.setUITextureByNameAsync(self.imgBg, "activity_month_gift_bg", false)

	self.imgBg.gameObject:GetComponent(typeof(UIWidget)).pivot = UIWidget.Pivot.Top

	self.imgBg:SetLocalPosition(0, 0, 0)

	local timeDesc = os.date("*t", xyd.getServerTime())
	local monthNum = timeDesc.month

	if tonumber(timeDesc.day) > 15 then
		monthNum = tonumber(monthNum) + 1
	end

	if tonumber(monthNum) > 12 then
		monthNum = 1
	end

	self.monthText.text = __("MONTH_BEGINNING_GIFTBAG_" .. monthNum)

	if xyd.Global.lang == "en_en" then
		self.monthText:SetLocalPosition(-42, -35, 0)
	else
		self.monthText:SetLocalPosition(-42, 26, 0)
	end

	xyd.setUISpriteAsync(self.e_Image2, nil, "activity_month_gift_time_bg2")
	self:getScrollView():ResetPosition()
end

function MonthBeginningGiftBag:initTime()
	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		if xyd.Global.lang == "fr_fr" then
			self.labelTime.color = Color.New2(4294901503.0)
			self.labelText01.color = Color.New2(2986279167.0)
			self.labelTime.text = __("END")

			CountDown.new(self.labelText01, {
				duration = self.activityData:getUpdateTime() - xyd.getServerTime()
			})
		else
			self.labelText01.text = __("END")

			CountDown.new(self.labelTime, {
				duration = self.activityData:getUpdateTime() - xyd.getServerTime()
			})
		end
	else
		self.labelTime:SetActive(false)
		self.labelText01:SetActive(false)
	end

	self.imgText02_layout:Reposition()

	self.imgText02.width = self.labelTime.width + self.labelText01.width + self.imgText02_layout.gap.x + 50
end

function MonthBeginningGiftBag:getItemInfos()
	local cantBuy = {}
	local t = {}
	local datas = self.activityData.detail.charges
	local freeCharge = self.activityData.detail.free_charge
	local crystalCharge = self.activityData.detail.buy_times
	local freeData = xyd.tables.giftTable:getAwards(freeCharge.gift_id)
	local freeItem = {
		isShowVipExp = false,
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

	for i in pairs(crystalCharge) do
		local crystalItem = {
			isCrystalCan = true,
			isShowVipExp = false,
			isCrystal = true,
			activityid = self.activityData.id,
			giftBagID = i,
			data = crystalCharge[i],
			parentScroller = self.scroller,
			limit = xyd.tables.activityMonthGiftTable:getLimit(i),
			award = xyd.tables.activityMonthGiftTable:getAward(i),
			cost = xyd.tables.activityMonthGiftTable:getCost(i)
		}

		if xyd.tables.activityMonthGiftTable:getLimit(i) <= crystalCharge[i] then
			crystalItem.isCrystalCan = false

			table.insert(cantBuy, crystalItem)
		else
			crystalItem.isCrystalCan = true

			table.insert(t, crystalItem)
		end
	end

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

	return t
end

function MonthBeginningGiftBag:onFree(event)
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

function MonthBeginningGiftBag:onCrystal(event)
	local cjson = require("cjson")
	local awardStateArrs = cjson.decode(event.data.detail)

	self.activityData:updateCrystalInfo(awardStateArrs)
	xyd.EventDispatcher.inner():dispatchEvent({
		name = "updateBtCrystal"
	})
end

return MonthBeginningGiftBag
