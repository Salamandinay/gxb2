local ActivityContent = import(".ActivityContent")
local ActivityFreebuyGiftbag = class("ActivityFreebuyGiftbag", ActivityContent)
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")

function ActivityFreebuyGiftbag:ctor(parentGO, params)
	self.canAwardList_ = {}

	ActivityContent.ctor(self, parentGO, params)
end

function ActivityFreebuyGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/freebuy_giftbag"
end

function ActivityFreebuyGiftbag:initUI()
	ActivityFreebuyGiftbag.super.initUI(self)
	self:getUIComponent()
	self:initLayout()
	self:onRegister()

	local realHeight = xyd.Global.getRealHeight()

	self.cardPos_.transform:Y(0 - 0.9943820224719101 * (realHeight - 1280))
end

function ActivityFreebuyGiftbag:getUIComponent()
	local goTrans = self.go.transform
	self.titleImg_ = goTrans:ComponentByName("titleImg", typeof(UISprite))
	self.titleLabel_ = goTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.timeGroup_ = goTrans:NodeByName("timeGroup").gameObject
	self.timeLabel_ = goTrans:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.cardPos_ = goTrans:NodeByName("cardScrollPos")
	self.cardGroup_ = goTrans:ComponentByName("cardScrollPos/cardGroup", typeof(UIScrollView))

	for i = 1, 3 do
		self["cardItem" .. i] = goTrans:NodeByName("cardScrollPos/cardGroup/grid/cardItem" .. i).gameObject
		self["imgIcon" .. i] = self["cardItem" .. i]:NodeByName("imgIcon").gameObject
		self["buyBtn" .. i] = self["cardItem" .. i]:NodeByName("buyBtn").gameObject
		self["maskImg" .. i] = self["buyBtn" .. i]:NodeByName("maskImg").gameObject
		self["lockImg" .. i] = self["buyBtn" .. i]:NodeByName("lockImg").gameObject
		self["buyBtnLabel" .. i] = self["buyBtn" .. i]:ComponentByName("button_label", typeof(UILabel))
		self["awardBtn" .. i] = self["cardItem" .. i]:NodeByName("awardBtn").gameObject
		self["awardBtnLabel" .. i] = self["awardBtn" .. i]:ComponentByName("button_label", typeof(UILabel))
		self["awardGroup" .. i] = self["cardItem" .. i]:ComponentByName("awardGroup", typeof(UIGrid))
		self["labelTips" .. i] = self["cardItem" .. i]:ComponentByName("labelTips", typeof(UILabel))
		self["labelTitle" .. i] = self["cardItem" .. i]:ComponentByName("titleGroup/labelTitle", typeof(UILabel))
	end
end

function ActivityFreebuyGiftbag:onRegister()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_FREEBUY_HELP"
		})
	end

	for i = 1, 3 do
		UIEventListener.Get(self["imgIcon" .. i]).onClick = function ()
			xyd.WindowManager.get():openWindow("freebuy_giftbag_award_window", {
				index = i
			})
		end

		UIEventListener.Get(self["maskImg" .. i]).onClick = function ()
			local endBuyTime = self.activityData:getShowEndTime()

			if endBuyTime < xyd.getServerTime() then
				xyd.alertTips(__("ACTIVITY_FREEBUY_TEXT12"))

				return
			end

			local index = 1

			if self.activityData:checkBuyTimes(1) then
				index = 2
			end

			xyd.alertYesNo(__("ACTIVITY_FREEBUY_TEXT08"), function (yes_no)
				if yes_no then
					xyd.WindowManager.get():openWindow("freebuy_giftbag_award_window", {
						index = index
					})
				end
			end)
		end

		UIEventListener.Get(self["buyBtn" .. i]).onClick = function ()
			local cost = xyd.tables.activityFreebuyGiftBagTable:getCost(i)

			if not self.activityData:checkCanBuy(i) then
				local index = 1

				if self.activityData:checkBuyTimes(1) then
					index = 2
				end

				xyd.alertYesNo(__("ACTIVITY_FREEBUY_TEXT08"), function (yes_no)
					if yes_no then
						xyd.WindowManager.get():openWindow("freebuy_giftbag_award_window", {
							index = index
						})
					end
				end)
			end

			if xyd.models.backpack:getItemNumByID(tonumber(cost[1])) < tonumber(cost[2]) then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(tonumber(cost[1]))))
			else
				xyd.alertYesNo(__("CONFIRM_BUY"), function (yes_no)
					if yes_no then
						local params = {
							num = 1,
							type = 1,
							award_id = i
						}

						self.activityData:setTempAwardID(i)
						xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_FREEBUY, cjson.encode(params))
					end
				end)
			end
		end

		UIEventListener.Get(self["awardBtn" .. i]).onClick = function ()
			local hasAwarded_day, canAwardIDs = self.activityData:getCanAwardList(i)
			local duringDay = self.activityData:getTodayAfterBuy(i)

			if hasAwarded_day >= 7 then
				return
			end

			if #canAwardIDs <= 0 or duringDay <= hasAwarded_day then
				xyd.alertTips(__("ACTIVITY_FREEBUY_TEXT13"))

				return
			end

			if canAwardIDs and #canAwardIDs > 0 then
				local params = {
					type = 2,
					ids = canAwardIDs
				}

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_FREEBUY, cjson.encode(params))
			end
		end
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
end

function ActivityFreebuyGiftbag:onGetAward(event)
	local detail = event.data.detail
	local data = detail

	if detail and tostring(detail) ~= "" then
		data = cjson.decode(detail)
	end

	if data.type and data.type == 2 then
		local awardItems = data.items

		xyd.WindowManager.get():openWindow("gamble_rewards_window", {
			wnd_type = 2,
			data = awardItems
		})
		self:updateShowItemList()
		self:updateBtnState()
	else
		local tempAwardID = self.activityData:getTempAwardID()

		if tempAwardID and tempAwardID > 0 then
			local awardItem1 = xyd.tables.activityFreebuyGiftBagTable:getAwards(tempAwardID)
			local params = {}

			for _, data in ipairs(awardItem1) do
				table.insert(params, {
					item_id = data[1],
					item_num = data[2]
				})
			end

			xyd.WindowManager.get():openWindow("gamble_rewards_window", {
				wnd_type = 2,
				data = params
			})
			self.activityData:clearTempAwardID()
		end

		self:updateShowItemList()
		self:updateBtnState()
	end
end

function ActivityFreebuyGiftbag:initLayout()
	xyd.setUISpriteAsync(self.titleImg_, nil, "freebuy_title_" .. xyd.Global.lang)

	self.titleLabel_.text = __("ACTIVITY_FREEBUY_TEXT01")

	self:updateShowEndTime()
	self:updateShowItemList()
	self:updateBtnState()

	for i = 1, 3 do
		local cost = xyd.tables.activityFreebuyGiftBagTable:getCost(i)
		self["buyBtnLabel" .. i].text = cost[2]
		self["awardBtnLabel" .. i].text = __("GET2")
		local rate = xyd.tables.activityFreebuyGiftBagTable:getRate(i)
		self["labelTitle" .. i].text = __("ACTIVITY_FREEBUY_TEXT07", rate * 100 .. "%")
	end
end

function ActivityFreebuyGiftbag:updateBtnState()
	for i = 1, 3 do
		local hasBuy = self.activityData:checkBuyTimes(i)
		local canBuy = self.activityData:checkCanBuy(i)

		if hasBuy then
			self["buyBtn" .. i]:SetActive(false)
			self["awardBtn" .. i]:SetActive(true)

			local duringDay = self.activityData:getTodayAfterBuy(i)
			local hasAwarded_day, canAwardIDs = self.activityData:getCanAwardList(i)

			if #canAwardIDs <= 0 or hasAwarded_day >= 7 or duringDay <= hasAwarded_day then
				if hasAwarded_day >= 7 then
					xyd.setEnabled(self["awardBtn" .. i], false)
				else
					xyd.applyChildrenGrey(self["awardBtn" .. i])
				end

				if duringDay <= hasAwarded_day and hasAwarded_day < 7 then
					self["labelTips" .. i].text = __("ACTIVITY_FREEBUY_TEXT10")
				elseif hasAwarded_day >= 7 then
					self["labelTips" .. i].text = __("ACTIVITY_FREEBUY_TEXT11")
				end
			else
				xyd.setEnabled(self["awardBtn" .. i], true)

				self["labelTips" .. i].text = __("ACTIVITY_FREEBUY_TEXT04")
			end
		elseif canBuy then
			self["labelTips" .. i].text = __("ACTIVITY_LOTTERY_TEXT02")

			self["buyBtn" .. i]:SetActive(true)
			self["awardBtn" .. i]:SetActive(false)
			self["maskImg" .. i]:SetActive(false)
			self["lockImg" .. i]:SetActive(false)
		else
			self["labelTips" .. i].text = __("ACTIVITY_LOTTERY_TEXT02")

			self["buyBtn" .. i]:SetActive(true)
			self["awardBtn" .. i]:SetActive(false)
			self["maskImg" .. i]:SetActive(true)
			self["lockImg" .. i]:SetActive(true)
		end
	end
end

function ActivityFreebuyGiftbag:updateShowEndTime()
	local showEndTime = self.activityData:getShowEndTime()

	if showEndTime and showEndTime - xyd.getServerTime() <= 0 then
		if self.countDown_ then
			self.countDown_:SetActive(false)
		end

		self.timeGroup_:SetActive(false)
		self.timeLabel_.gameObject:SetActive(false)
	else
		if not self.countDown_ then
			self.countDown_ = CountDown.new(self.timeLabel_)
		end

		self.countDown_:setInfo({
			key = "ACTIVITY_FREEBUY_TIME",
			duration = showEndTime - xyd:getServerTime()
		})
	end
end

function ActivityFreebuyGiftbag:updateShowItemList()
	for i = 1, 3 do
		local hasBuy = self.activityData:checkBuyTimes(i)
		local hasAwarded_day, canAwardIDs = self.activityData:getCanAwardList(i)

		if hasBuy and hasAwarded_day < 7 then
			self.canAwardList_[i] = xyd.cloneTable(canAwardIDs)
			local awardItems = {}

			for _, id in ipairs(canAwardIDs) do
				local awards = xyd.tables.activityFreebuyAwardTable:getAwards(id)
				awardItems = xyd.arrayMerge(awardItems, awards)
			end

			local showItemList = self:getShowAwardItems(awardItems)

			NGUITools.DestroyChildren(self["awardGroup" .. i].transform)

			for index, itemData in ipairs(showItemList) do
				local params = {
					scale = 0.7037037037037037,
					itemID = itemData.item_id,
					num = itemData.item_num,
					wndType = xyd.ItemTipsWndType.ACTIVITY,
					uiRoot = self["awardGroup" .. i].gameObject,
					dragScrollView = self.cardGroup_
				}

				xyd.getItemIcon(params)
			end

			self["awardGroup" .. i]:Reposition()
		else
			local awardItem1 = xyd.tables.activityFreebuyGiftBagTable:getAwards(i)
			local awardIds = xyd.tables.activityFreebuyAwardTable:getIdsByType(i)
			local awardItem2 = {}

			for _, id in ipairs(awardIds) do
				local awardItem3 = xyd.tables.activityFreebuyAwardTable:getAwards(id)
				awardItem2 = xyd.arrayMerge(awardItem3, awardItem2)
			end

			local awardItems = xyd.arrayMerge(awardItem1, awardItem2)
			local showItemList = self:getShowAwardItems(awardItems)

			NGUITools.DestroyChildren(self["awardGroup" .. i].transform)

			for index, itemData in ipairs(showItemList) do
				local params = {
					scale = 0.7037037037037037,
					itemID = itemData.item_id,
					num = itemData.item_num,
					dragScrollView = self.cardGroup_,
					wndType = xyd.ItemTipsWndType.ACTIVITY,
					uiRoot = self["awardGroup" .. i].gameObject
				}

				xyd.getItemIcon(params)
			end

			self["awardGroup" .. i]:Reposition()
		end
	end
end

function ActivityFreebuyGiftbag:getShowAwardItems(items)
	local tmpData = {}

	for _, item in ipairs(items) do
		local itemID = item[1]

		if tmpData[itemID] == nil then
			tmpData[itemID] = 0
		end

		tmpData[itemID] = tmpData[item[1]] + item[2]
	end

	local datas = {}

	for k, v in pairs(tmpData) do
		table.insert(datas, {
			item_id = tonumber(k),
			item_num = v
		})
	end

	table.sort(datas, function (a, b)
		return b.item_id < a.item_id
	end)

	return datas
end

return ActivityFreebuyGiftbag
