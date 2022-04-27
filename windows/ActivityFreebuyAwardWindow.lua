local BaseWindow = import(".BaseWindow")
local ActivityFreebuyAwardWindow = class("ActivityFreebuyAwardWindow", BaseWindow)
local cjson = require("cjson")

function ActivityFreebuyAwardWindow:ctor(name, params)
	ActivityFreebuyAwardWindow.super.ctor(self, name, params)

	self.index_ = params.index
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FREEBUY)
end

function ActivityFreebuyAwardWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:regiseter()
end

function ActivityFreebuyAwardWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.bg2 = winTrans:NodeByName("bg2").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.buyBtn_ = winTrans:NodeByName("buyBtn").gameObject
	self.buyBtnLabel_ = winTrans:ComponentByName("buyBtn/button_label", typeof(UILabel))
	self.maskImg_ = self.buyBtn_:NodeByName("maskImg").gameObject
	self.lockImg_ = self.buyBtn_:NodeByName("lockImg").gameObject
	self.awardBtn_ = winTrans:NodeByName("awardBtn").gameObject
	self.awardBtnLabel_ = winTrans:ComponentByName("awardBtn/button_label", typeof(UILabel))
	self.awardGroup_ = winTrans:ComponentByName("awardGroup", typeof(UIScrollView))
	self.awardGrid_ = winTrans:ComponentByName("awardGroup/grid", typeof(UIGrid))
	self.awardItem_ = winTrans:NodeByName("awardItem").gameObject
end

function ActivityFreebuyAwardWindow:regiseter()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.maskImg_).onClick = function ()
		local endBuyTime = self.activityData:getShowEndTime()

		if endBuyTime < xyd.getServerTime() then
			xyd.alertTips(__("ACTIVITY_FREEBUY_TEXT12"))

			return
		end

		if not self.activityData:checkCanBuy(self.index_) then
			local index = 1

			if self.activityData:checkBuyTimes(1) then
				index = 2
			end

			xyd.alertYesNo(__("ACTIVITY_FREEBUY_TEXT08"), function (yes_no)
				if yes_no then
					xyd.WindowManager.get():closeWindow("freebuy_giftbag_award_window", function ()
						xyd.WindowManager.get():openWindow("freebuy_giftbag_award_window", {
							index = index
						})
					end)
				end
			end)
		end
	end

	UIEventListener.Get(self.buyBtn_).onClick = function ()
		local cost = xyd.tables.activityFreebuyGiftBagTable:getCost(self.index_)

		if not self.activityData:checkCanBuy(self.index_) then
			return
		end

		if xyd.models.backpack:getItemNumByID(tonumber(cost[1])) < tonumber(cost[2]) then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(tonumber(cost[1]))))
		else
			xyd.alertYesNo(__("CONFIRM_BUY"), function (yes_no)
				if yes_no then
					local params = {
						num = 1,
						type = 1,
						award_id = self.index_
					}

					self.activityData:setTempAwardID(self.index_)
					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_FREEBUY, cjson.encode(params))
					self:close()
				end
			end)
		end
	end
end

function ActivityFreebuyAwardWindow:layout()
	self.titleLabel_.text = __("BATTLE_PASS_CHECK_AWARD_WINDOW")
	local hasBuy = self.activityData:checkBuyTimes(self.index_)
	local canBuy = self.activityData:checkCanBuy(self.index_)

	if not hasBuy then
		local cost = xyd.tables.activityFreebuyGiftBagTable:getCost(self.index_)
		self.buyBtnLabel_.text = cost[2]

		self.buyBtn_:SetActive(true)
		self.awardBtn_:SetActive(false)

		if canBuy then
			self.maskImg_:SetActive(false)
			self.lockImg_:SetActive(false)
		else
			self.maskImg_:SetActive(true)
			self.lockImg_:SetActive(true)
		end
	else
		self.bg2:GetComponent(typeof(UIWidget)).height = 549
		self.awardBtnLabel_.text = __("ACTIVITY_GROWTH_PLAN_TEXT07")

		self.awardBtn_:SetActive(false)
		self.buyBtn_:SetActive(false)
	end

	local awardItem1 = xyd.tables.activityFreebuyGiftBagTable:getAwards(self.index_)
	local NewItemRoot1 = NGUITools.AddChild(self.awardGrid_.gameObject, self.awardItem_)

	NewItemRoot1:SetActive(true)

	local titleLabel1 = NewItemRoot1:ComponentByName("labelTitle", typeof(UILabel))
	titleLabel1.text = __("ACTIVITY_FREEBUY_TEXT09")
	local itemList1 = NewItemRoot1:ComponentByName("itemList", typeof(UIGrid))

	for _, item_info in ipairs(awardItem1) do
		local params = {
			scale = 0.6481481481481481,
			uiRoot = itemList1.gameObject,
			itemID = item_info[1],
			num = item_info[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.awardGroup_
		}
		local item1 = xyd.getItemIcon(params)

		if hasBuy then
			item1:setChoose(true)
		else
			item1:setChoose(false)
		end
	end

	itemList1:Reposition()

	local awardIds = xyd.tables.activityFreebuyAwardTable:getIdsByType(self.index_)
	local awarded = self.activityData.detail.awards

	for _, id in ipairs(awardIds) do
		local NewItemRoot = NGUITools.AddChild(self.awardGrid_.gameObject, self.awardItem_)
		local day = xyd.tables.activityFreebuyAwardTable:getDay(id)

		NewItemRoot:SetActive(true)

		local titleLabel = NewItemRoot:ComponentByName("labelTitle", typeof(UILabel))
		titleLabel.text = __("ACTIVITY_WEEK_DATE", day)
		local itemList = NewItemRoot:ComponentByName("itemList", typeof(UIGrid))
		local awardItems = xyd.tables.activityFreebuyAwardTable:getAwards(id)

		for _, item_info in ipairs(awardItems) do
			local params = {
				scale = 0.6481481481481481,
				uiRoot = itemList.gameObject,
				itemID = item_info[1],
				num = item_info[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.awardGroup_
			}
			local item = xyd.getItemIcon(params)

			if awarded[id] and awarded[id] == 1 then
				item:setChoose(true)
			else
				item:setChoose(false)
			end
		end

		itemList:Reposition()
	end

	self.awardGrid_:Reposition()
	self.awardGroup_:ResetPosition()
end

return ActivityFreebuyAwardWindow
