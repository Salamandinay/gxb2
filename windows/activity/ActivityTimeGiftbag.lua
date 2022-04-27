local ActivityContent = import("app.windows.activity.ValueGiftBag")
local ActivityTimeGiftbag = class("ActivityTimeGiftbag", ActivityContent)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")

function ActivityTimeGiftbag:ctor(parentGo, params, parent)
	ActivityTimeGiftbag.super.ctor(self, parentGo, params, parent)
end

function ActivityTimeGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/activity_time_giftbag"
end

function ActivityTimeGiftbag:resizeToParent()
	ActivityTimeGiftbag.super.resizeToParent(self)
	self:resizePosY(self.groupBg, -570, -720)
	self:resizePosY(self.timeGroup, -260, -355)
	self:resizePosY(self.bg, -500, -535)
	self:resizePosY(self.textLogo, -130, -163)
end

function ActivityTimeGiftbag:initUIComponent()
	ActivityTimeGiftbag.super.initWrapContent(self)
	self:layout()
end

function ActivityTimeGiftbag:onRegisterEvent()
	ActivityTimeGiftbag.super.onRegisterEvent(self)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onCrystal))
end

function ActivityTimeGiftbag:getUIComponent()
	local go = self.go
	self.textLogo = go:ComponentByName("textLogo", typeof(UISprite))
	self.timeGroup = go:ComponentByName("timeGroup", typeof(UILayout))
	self.labelTime = self.timeGroup:ComponentByName("labelTime", typeof(UILabel))
	self.labelEnd = self.timeGroup:ComponentByName("labelEnd", typeof(UILabel))
	self.groupBg = go:ComponentByName("groupBg", typeof(UISprite))
	self.bg = go:ComponentByName("bg", typeof(UITexture))
	self.scroller = go:ComponentByName("scroller", typeof(UIScrollView))
	self.groupPackage = go:NodeByName("scroller/groupPackage").gameObject
	self.common_giftbag_item = go:NodeByName("common_giftbag_item").gameObject
	self.wrapContentCon = go:ComponentByName("scroller/groupPackage", typeof(UIWrapContent))

	self:initWrapContent()
end

function ActivityTimeGiftbag:initWrapContent()
end

function ActivityTimeGiftbag:layout()
	xyd.setUISpriteAsync(self.textLogo, nil, "activity_time_giftbag_" .. xyd.Global.lang)

	self.labelEnd.text = __("END")
	local duration = self.activityData:getEndTime() - xyd.getServerTime()

	if duration < 0 then
		self.timeGroup:SetActive(false)
	else
		local timeCount = import("app.components.CountDown").new(self.labelTime)

		timeCount:setInfo({
			duration = duration
		})
	end

	self:setItems()
end

function ActivityTimeGiftbag:setItems()
	local t = self:getItemInfos()
	self.firstItemArr = t

	self.wrapContent:setInfos(t, {})
end

function ActivityTimeGiftbag:getItemInfos()
	local cantBuy = {}
	local t = {}
	local datas = self.activityData.detail.charges
	local crystalCharge = self.activityData.detail.detail.buy_times
	local awardItems = xyd.tables.miscTable:getVal("activity_time_giftbag_cost", "value")
	local awardItems = xyd.split(awardItems, "@")
	local cryCost = xyd.split(awardItems[1], "#", true)
	local cryAwards = xyd.split(awardItems[2], "|")
	local cryLimit = tonumber(xyd.tables.miscTable:getVal("activity_time_giftbag_limit", "value"))

	for k, v in ipairs(cryAwards) do
		local award = xyd.split(v, "#")
		cryAwards[k] = award
	end

	local crystalItem = {
		isCrystalCan = true,
		isShowVipExp = false,
		isCrystal = true,
		giftBagID = 1,
		activityid = self.activityData.id,
		data = crystalCharge,
		parentScroller = self.scroller,
		limit = cryLimit,
		award = cryAwards,
		cost = cryCost
	}

	if cryLimit <= crystalCharge then
		crystalItem.isCrystalCan = false

		table.insert(cantBuy, crystalItem)
	else
		crystalItem.isCrystalCan = true

		table.insert(t, crystalItem)
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

function ActivityTimeGiftbag:onCrystal(event)
	local cjson = require("cjson")
	local info = cjson.decode(event.data.detail)

	self.activityData:updateCrystalInfo(info.info.detail.buy_times)
	xyd.EventDispatcher.inner():dispatchEvent({
		name = "updateBtCrystal"
	})
end

return ActivityTimeGiftbag
