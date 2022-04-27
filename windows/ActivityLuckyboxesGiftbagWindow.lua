local BaseWindow = import(".BaseWindow")
local ActivityLuckyboxesGiftbagWindow = class("ActivityLuckyboxesGiftbagWindow", BaseWindow)
local ActivityLuckyboxesSpecialAwardItem = class("ActivityLuckyboxesSpecialAwardItem", import("app.common.ui.FixedWrapContentItem"))
local AdvanceIcon = import("app.components.AdvanceIcon")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ItemTable = xyd.tables.itemTable
local json = require("cjson")

function ActivityLuckyboxesGiftbagWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LUCKYBOXES)
end

function ActivityLuckyboxesGiftbagWindow:getPrefabPath()
	return "Prefabs/Windows/activity_luckyboxes_giftbag_window"
end

function ActivityLuckyboxesGiftbagWindow:initWindow()
	self.giftBagIDs = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.ACTIVITY_LUCKYBOXES)

	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:Register()
	self:initUIComponent()
	self:initData()
end

function ActivityLuckyboxesGiftbagWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelWinTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.awardContentGroup = self.groupAction:NodeByName("awardContentGroup").gameObject
	self.bg_ = self.awardContentGroup:ComponentByName("bg_", typeof(UISprite))
	self.drag = self.awardContentGroup:NodeByName("drag").gameObject
	self.scroller = self.awardContentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.item = self.scroller:NodeByName("item").gameObject
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
end

function ActivityLuckyboxesGiftbagWindow:addTitle()
	self.labelWinTitle.text = __("ACTIVITY_LUCKYBOXES_TEXT04")
end

function ActivityLuckyboxesGiftbagWindow:initUIComponent()
end

function ActivityLuckyboxesGiftbagWindow:initData()
	self.data = {}
	local charges = self.activityData.detail.charges

	for i = 1, #charges do
		local giftBagID = tonumber(charges[i].table_id)
		local awarded = 0

		if charges[i].limit_times <= charges[i].buy_times then
			awarded = 1
		end

		table.insert(self.data, {
			giftBagID = giftBagID,
			left_time = charges[i].limit_times - charges[i].buy_times,
			awarded = awarded
		})
	end

	local ids = xyd.tables.activityLuckyboxesExchangTable:getIDs()
	local freecharges = self.activityData.detail.free_charge

	for i = 1, #ids do
		local awarded = 0

		if xyd.tables.activityLuckyboxesExchangTable:getLimit(i) - self.activityData.detail.exchange_times[i] < 1 then
			awarded = 1
		end

		table.insert(self.data, {
			isFreeGiftbag = true,
			left_time = xyd.tables.activityLuckyboxesExchangTable:getLimit(i) - self.activityData.detail.exchange_times[i],
			awarded = awarded,
			freeGiftbagID = i
		})
	end

	local function sort_func(a, b)
		if a.awarded ~= b.awarded then
			return a.awarded < b.awarded
		elseif a.isFreeGiftbag == true then
			return true
		elseif b.isFreeGiftbag == true then
			return false
		else
			return a.giftBagID < b.giftBagID
		end
	end

	table.sort(self.data, sort_func)

	if self.wrapContent == nil then
		local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
		self.wrapContent = FixedWrapContent.new(self.scroller, wrapContent, self.item, ActivityLuckyboxesSpecialAwardItem, self)
	end

	self.wrapContent:setInfos(self.data, {})
end

function ActivityLuckyboxesGiftbagWindow:Register()
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, function (event)
		self:initData()
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data
		local detail = json.decode(data.detail)

		if data.activity_id == xyd.ActivityID.ACTIVITY_LUCKYBOXES then
			local awards = xyd.tables.activityLuckyboxesExchangTable:getAwards(detail.award_id)
			local items = {}

			for _, info in ipairs(awards) do
				local item = {
					item_id = info[1],
					item_num = info[2]
				}

				table.insert(items, item)
			end

			xyd.models.itemFloatModel:pushNewItems(items)
			self:initData()
		end
	end)

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow("activity_luckyboxes_giftbag_window")
	end
end

function ActivityLuckyboxesSpecialAwardItem:ctor(go, parent)
	ActivityLuckyboxesSpecialAwardItem.super.ctor(self, go, parent)
end

function ActivityLuckyboxesSpecialAwardItem:initUI()
	local go = self.go
	self.bg_ = self.go:ComponentByName("bg_", typeof(UISprite))
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject
	self.itemGroup_layout = self.go:ComponentByName("itemGroup", typeof(UILayout))
	self.labelExp = self.go:ComponentByName("labelExp", typeof(UILabel))
	self.label_ = self.go:ComponentByName("label_", typeof(UILabel))
	self.labellimit = self.go:ComponentByName("labellimit", typeof(UILabel))
	self.giftbagBuyBtn = self.go:NodeByName("giftbagBuyBtn").gameObject
	self.giftbagBuyBtnLabel = self.giftbagBuyBtn:ComponentByName("giftbagBuyBtnLabel", typeof(UILabel))
	self.labelNum = self.giftbagBuyBtn:ComponentByName("labelNum", typeof(UILabel))
	self.icon = self.giftbagBuyBtn:ComponentByName("icon", typeof(UISprite))
	self.icons = {}
	UIEventListener.Get(self.giftbagBuyBtn).onClick = handler(self, function ()
		if self.isFreeGiftbag == true then
			self:buyFreeGiftbag()
		else
			xyd.SdkManager.get():showPayment(self.giftBagID)
		end
	end)
end

function ActivityLuckyboxesSpecialAwardItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)

	self.giftBagID = self.data.giftBagID
	self.left_time = self.data.left_time
	self.isFreeGiftbag = self.data.isFreeGiftbag
	self.freeGiftbagID = self.data.freeGiftbagID

	self.label_:SetActive(self.isFreeGiftbag ~= true)
	self.labelExp:SetActive(self.isFreeGiftbag ~= true)
	self.giftbagBuyBtnLabel:SetActive(self.isFreeGiftbag ~= true)
	self.icon:SetActive(self.isFreeGiftbag == true)
	self.labelNum:SetActive(self.isFreeGiftbag == true)

	local awards = nil
	self.labellimit.text = __("BUY_GIFTBAG_LIMIT", self.left_time)

	if self.isFreeGiftbag == true then
		local cost = xyd.tables.activityLuckyboxesExchangTable:getCost(self.freeGiftbagID)

		xyd.setUISpriteAsync(self.icon, nil, "icon" .. cost[1])

		self.labelNum.text = cost[2]
		awards = xyd.tables.activityLuckyboxesExchangTable:getAwards(self.freeGiftbagID)
	else
		self.label_.text = __("VIP EXP")
		self.labelExp.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftBagID)
		self.giftbagBuyBtnLabel.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftBagID))
		self.giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID)
		awards = xyd.tables.giftTable:getAwards(self.giftID)
	end

	for i = 1, #self.icons do
		self.icons[i]:SetActive(false)
	end

	self.count = 1

	for i = 1, #awards do
		local award = awards[i]

		if award[i] ~= 8 and xyd.tables.itemTable:getType(award[i]) ~= 12 then
			local params = {
				show_has_num = false,
				scale = 0.6018518518518519,
				notShowGetWayBtn = true,
				uiRoot = self.itemGroup,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scroller
			}

			if self.icons[self.count] == nil then
				params.preGenarate = true
				self.icons[self.count] = AdvanceIcon.new(params)
			else
				self.icons[self.count]:setInfo(params)
			end

			self.icons[self.count]:SetActive(true)
			self.icons[self.count]:setChoose(self.left_time <= 0)

			self.count = self.count + 1
		end
	end

	if self.left_time <= 0 then
		xyd.applyGrey(self.giftbagBuyBtn:GetComponent(typeof(UISprite)))
		xyd.applyGrey(self.icon)
		self.giftbagBuyBtnLabel:ApplyGrey()
		xyd.setTouchEnable(self.giftbagBuyBtn, false)
	else
		xyd.applyOrigin(self.giftbagBuyBtn:GetComponent(typeof(UISprite)))
		xyd.applyOrigin(self.icon)
		self.giftbagBuyBtnLabel:ApplyOrigin()
		xyd.setTouchEnable(self.giftbagBuyBtn, true)
	end

	self.itemGroup_layout:Reposition()
end

function ActivityLuckyboxesSpecialAwardItem:buyFreeGiftbag()
	if self.left_time <= 0 then
		return
	end

	local cost = xyd.tables.activityLuckyboxesExchangTable:getCost(self.freeGiftbagID)

	if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

		return
	end

	xyd.alertYesNo(__("CONFIRM_BUY"), function (yes)
		if yes then
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LUCKYBOXES, json.encode({
				award_type = 1,
				award_id = self.freeGiftbagID
			}))
		end
	end)
end

return ActivityLuckyboxesGiftbagWindow
