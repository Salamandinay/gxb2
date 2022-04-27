local ActivityNewbeeGiftBag = class("ActivityNewbeeGiftBag", import(".ActivityContent"))
local CountDown = import("app.components.CountDown")
local giftBagItem = class("giftBagItem", import("app.components.CopyComponent"))
local GiftBagTextTable = xyd.tables.giftBagTextTable
local json = require("cjson")

function ActivityNewbeeGiftBag:ctor(parentGO, params, parent)
	self.giftBagItem_ = {}

	ActivityNewbeeGiftBag.super.ctor(self, parentGO, params, parent)
end

function ActivityNewbeeGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/activity_newbee_giftbag"
end

function ActivityNewbeeGiftBag:initUI()
	ActivityNewbeeGiftBag.super.initUI(self)

	local timeStamp = xyd.tables.miscTable:getNumber("activity_newbee_gacha_dropbox_new_time", "value")

	if timeStamp < xyd.getServerTime() then
		self.isNewVersion = true
	end

	self:getUIComponent()
	self:layout()
	self:initGiftBagItem()
	self:register()

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)
		self.timeLayout:Reposition()
	end
end

function ActivityNewbeeGiftBag:getUIComponent()
	local goTrans = self.go.transform
	self.titleImg_ = goTrans:ComponentByName("titleImg", typeof(UITexture))
	self.timeLayout = goTrans:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel_ = goTrans:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.endLabel_ = goTrans:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.scrollView_ = goTrans:ComponentByName("scrollViewGiftBag", typeof(UIScrollView))
	self.grid_ = self.scrollView_.transform:ComponentByName("grid", typeof(UIGrid))
	self.tempGiftItem_ = goTrans:NodeByName("tempGiftItem").gameObject
end

function ActivityNewbeeGiftBag:layout()
	xyd.setUITextureByNameAsync(self.titleImg_, "activity_newbee_giftbag_logo_" .. xyd.Global.lang, true)

	self.endLabel_.text = __("END")
	local endTime = self.activityData:getEndTime()
	local timeCount = CountDown.new(self.timeLabel_)

	timeCount:setInfo({
		duration = endTime - xyd:getServerTime()
	})
end

function ActivityNewbeeGiftBag:initGiftBagItem()
	local ids = xyd.tables.activityTable:getGiftBag(self.id)
	self.giftBagIds_ = {}

	if self.isNewVersion then
		for i = #ids / 2 + 1, #ids do
			table.insert(self.giftBagIds_, ids[i])
		end
	else
		for i = 1, #ids / 2 do
			table.insert(self.giftBagIds_, ids[i])
		end
	end

	local tempItem1 = NGUITools.AddChild(self.grid_.gameObject, self.tempGiftItem_)

	tempItem1:SetActive(true)

	self.giftBagItem_[1] = giftBagItem.new(tempItem1, true, nil, self, 1)

	for i = 1, #self.giftBagIds_ do
		local tempItem = NGUITools.AddChild(self.grid_.gameObject, self.tempGiftItem_)

		tempItem:SetActive(true)

		local newItem = giftBagItem.new(tempItem, false, self.giftBagIds_[i], self, i + 1)

		table.insert(self.giftBagItem_, newItem)
	end

	self:waitForFrame(1, function ()
		self.grid_:Reposition()
		self.scrollView_:ResetPosition()
	end)
end

function ActivityNewbeeGiftBag:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function ActivityNewbeeGiftBag:onAward(event)
	local items = json.decode(event.data.detail).items

	xyd.models.itemFloatModel:pushNewItems(items)
	self.giftBagItem_[1]:updateBtn()
end

function ActivityNewbeeGiftBag:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	for _, item in ipairs(self.giftBagItem_) do
		if item:getGiftBagId() == giftBagID then
			item:updateBtn()
		end
	end
end

function giftBagItem:ctor(parentGo, isFirst, giftBagId, parent, index)
	self.isFirst_ = isFirst
	self.giftBagId_ = giftBagId
	self.parent_ = parent
	self.index_ = index

	giftBagItem.super.ctor(self, parentGo)
end

function giftBagItem:initUI()
	giftBagItem.super.initUI(self)
	self:getUIComponent()
	self:layout()
	self:initItems()
end

function giftBagItem:getUIComponent()
	local goTrans = self.go.transform
	self.giftImg_ = goTrans:ComponentByName("giftImg", typeof(UISprite))
	self.itemGrid_ = goTrans:ComponentByName("itemGrid", typeof(UILayout))
	self.buyBtn_ = goTrans:NodeByName("buyBtn").gameObject
	self.labelPrice_ = goTrans:ComponentByName("buyBtn/labelPrice", typeof(UILabel))
	self.groupCost_ = goTrans:NodeByName("buyBtn/groupCost").gameObject
	self.labelCost_ = goTrans:ComponentByName("buyBtn/groupCost/labelCost", typeof(UILabel))
	self.limitLabel_ = goTrans:ComponentByName("limitLabel", typeof(UILabel))
	self.vipExp_ = goTrans:ComponentByName("vipExp", typeof(UILabel))
	UIEventListener.Get(self.buyBtn_).onClick = handler(self, self.onClickBuyBtn)
end

function giftBagItem:onClickBuyBtn()
	if self.isFirst_ then
		local cost = xyd.tables.miscTable:getVal("newbee_gacha_giftbag_cost", "value")
		cost = xyd.split(cost, "@")
		cost = cost[1]
		cost = xyd.split(cost, "#")

		xyd.alertYesNo(__("CONFIRM_BUY"), function (flag)
			if flag then
				if xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL) < tonumber(cost[2]) then
					xyd.alertTips(__("SPIRIT_NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.CRYSTAL)))

					return
				end

				local params = {
					num = 1
				}
				params = json.encode(params)

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.NEWBEE_GIFTBAG, params)
			end
		end, __("BUY"))

		return
	end

	xyd.SdkManager.get():showPayment(self.giftBagId_)
end

function giftBagItem:layout()
	xyd.setUISpriteAsync(self.giftImg_, nil, "activity_newbee_giftbag_icon" .. self.index_, function ()
		self.giftImg_:MakePixelPerfect()
	end)

	if self.isFirst_ then
		self.labelPrice_.gameObject:SetActive(false)
		self.groupCost_:SetActive(true)

		local limitTime = xyd.tables.miscTable:getVal("newbee_gacha_giftbag_limit")
		local cost = xyd.tables.miscTable:getVal("newbee_gacha_giftbag_cost", "value")
		cost = xyd.split(cost, "@")
		cost = cost[1]
		cost = xyd.split(cost, "#")
		self.labelCost_.text = cost[2]
		local buyTimes = self:getBuyTime()
		self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT", tostring(limitTime - buyTimes))

		self:updateBtn(limitTime - buyTimes)

		self.vipExp_.text = "+0 VIP EXP"
	else
		self.labelPrice_.gameObject:SetActive(true)
		self.groupCost_:SetActive(false)

		self.vipExp_.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftBagId_) .. " VIP EXP"
		self.labelPrice_.text = GiftBagTextTable:getCurrency(self.giftBagId_) .. " " .. GiftBagTextTable:getCharge(self.giftBagId_)
		local limitTime = xyd.tables.giftBagTable:getBuyLimit(self.giftBagId_)
		local buyTimes = self:getBuyTime()
		self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT", tostring(limitTime - buyTimes))

		self:updateBtn(limitTime - buyTimes)
	end
end

function giftBagItem:initItems()
	if self.isFirst_ then
		local awardItems = xyd.tables.miscTable:getVal("newbee_gacha_giftbag_cost", "value")
		awardItems = xyd.split(awardItems, "@")
		awardItems = awardItems[2]
		awardItems = xyd.split(awardItems, "|")

		for i = 1, #awardItems do
			local itemData = xyd.split(awardItems[i], "#", true)
			local scale = nil

			if i == 1 then
				scale = 0.9074074074074074
			else
				scale = 0.7037037037037037
			end

			xyd.getItemIcon({
				show_has_num = true,
				uiRoot = self.itemGrid_.gameObject,
				itemID = itemData[1],
				num = itemData[2],
				scale = scale,
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent_.scrollView_
			})
		end
	else
		local giftId = xyd.tables.giftBagTable:getGiftID(self.giftBagId_)
		local awards = xyd.tables.giftTable:getAwards(giftId)

		for j = 1, #awards do
			local award = awards[j]

			if award[1] ~= xyd.ItemID.VIP_EXP then
				local scale = 0.9074074074074074

				if j >= 3 then
					scale = 0.7037037037037037
				end

				xyd.getItemIcon({
					show_has_num = true,
					uiRoot = self.itemGrid_.gameObject,
					itemID = award[1],
					num = award[2],
					wndType = xyd.ItemTipsWndType.ACTIVITY,
					scale = scale,
					dragScrollView = self.parent_.scrollView_
				})
			end
		end
	end
end

function giftBagItem:getBuyTime()
	if self.isFirst_ then
		return self.parent_.activityData.detail.info.buy_times
	else
		for i = 1, #self.parent_.activityData.detail.charges do
			if self.parent_.activityData.detail.charges[i].table_id == self.giftBagId_ then
				return self.parent_.activityData.detail.charges[i].buy_times
			end
		end

		return self.parent_.activityData.detail.charges[self.index_ - 1].buy_times
	end
end

function giftBagItem:getGiftBagId()
	return self.giftBagId_
end

function giftBagItem:updateBtn(leftTime)
	local limitTimeLeft = nil

	if not leftTime then
		local buyTimes = self:getBuyTime()

		if self.isFirst_ then
			local limitTime = xyd.tables.miscTable:getVal("newbee_gacha_giftbag_limit")
			limitTimeLeft = tonumber(limitTime) - buyTimes
		else
			local limitTime = xyd.tables.giftBagTable:getBuyLimit(self.giftBagId_)
			limitTimeLeft = tonumber(limitTime) - buyTimes
		end
	else
		limitTimeLeft = leftTime
	end

	self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT", limitTimeLeft)

	if limitTimeLeft <= 0 then
		xyd.setEnabled(self.buyBtn_, false)
	end
end

return ActivityNewbeeGiftBag
