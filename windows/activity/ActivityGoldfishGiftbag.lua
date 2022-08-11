local ActivityContent = import(".ActivityContent")
local ActivityGoldfishGiftbag = class("ActivityGoldfishGiftbag", ActivityContent)
local ActivityGoldfishGiftbagItem = class("ActivityGoldfishGiftbagItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local AdvanceIcon = import("app.components.AdvanceIcon")
local json = require("cjson")

function ActivityGoldfishGiftbag:ctor(parentGO, params, parent)
	ActivityGoldfishGiftbag.super.ctor(self, parentGO, params, parent)
end

function ActivityGoldfishGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/activity_goldfish_giftbag"
end

function ActivityGoldfishGiftbag:initUI()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_GOLDFISH_GIFTBAG)
	self.freeIcons = {}
	self.paidGiftbagID = self.activityData.detail.charges[1].table_id
	self.paidIcons = {}

	self:getUIComponent()
	ActivityGoldfishGiftbag.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityGoldfishGiftbag:resizeToParent()
	ActivityGoldfishGiftbag.super.resizeToParent(self)
	self:resizePosY(self.paidGiftbagGroup, -337, -424)
	self:resizePosY(self.freeGiftbagGroup, 10, -51)
end

function ActivityGoldfishGiftbag:getUIComponent()
	local go = self.go
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.Bg_ = self.groupAction:ComponentByName("Bg_", typeof(UISprite))
	self.textImg_ = self.groupAction:ComponentByName("textImg_", typeof(UISprite))
	self.timeGroup = self.groupAction:NodeByName("timeGroup").gameObject
	self.timeGroupLayout = self.groupAction:ComponentByName("timeGroup", typeof(UILayout))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.timeLabel_ = self.timeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.paidGiftbagGroup = self.groupAction:NodeByName("paidGiftbagGroup").gameObject
	self.labelPaidTitle = self.paidGiftbagGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.labelPaidLimit = self.paidGiftbagGroup:ComponentByName("labelLimit", typeof(UILabel))
	self.awardItemPaidGroupLayout1 = self.paidGiftbagGroup:ComponentByName("awardItemGroup1", typeof(UILayout))
	self.awardItemPaidGroupLayout2 = self.paidGiftbagGroup:ComponentByName("awardItemGroup2", typeof(UILayout))
	self.giftbagPaidBuyBtn = self.paidGiftbagGroup:NodeByName("giftbagBuyBtn").gameObject
	self.giftbagPaidBuyBtnLabel = self.giftbagPaidBuyBtn:ComponentByName("giftbagBuyBtnLabel", typeof(UILabel))
	self.labelPaidVip = self.paidGiftbagGroup:ComponentByName("labelVip", typeof(UILabel))
	self.freeGiftbagGroup = self.groupAction:NodeByName("freeGiftbagGroup").gameObject
	self.labelFreeTitle = self.freeGiftbagGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.labelFreeLimit = self.freeGiftbagGroup:ComponentByName("labelLimit", typeof(UILabel))
	self.awardItemFreeGroup = self.freeGiftbagGroup:NodeByName("awardItemGroup").gameObject
	self.awardItemFreeGroupGrid = self.freeGiftbagGroup:ComponentByName("awardItemGroup", typeof(UIGrid))
	self.giftbagFreeBuyBtn = self.freeGiftbagGroup:NodeByName("giftbagBuyBtn").gameObject
	self.giftbagFreeBuyBtnIcon = self.giftbagFreeBuyBtn:ComponentByName("icon", typeof(UISprite))
	self.giftbagFreeBuyBtnLabel = self.giftbagFreeBuyBtn:ComponentByName("giftbagBuyBtnLabel", typeof(UILabel))
	self.labelFreeVip = self.freeGiftbagGroup:ComponentByName("labelVip", typeof(UILabel))
end

function ActivityGoldfishGiftbag:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_GOLDFISH_GIFTBAG then
			local awards = xyd.tables.miscTable:split2Cost("activity_goldfish_pack_get", "value", "|#")
			local items = {}

			for _, info in ipairs(awards) do
				local item = {
					item_id = info[1],
					item_num = info[2]
				}

				table.insert(items, item)
			end

			xyd.models.itemFloatModel:pushNewItems(items)
			self:updateFreeGroup()
			self:updatePaidGroup()
		end
	end)
	self:registerEvent(xyd.event.RECHARGE, function ()
		self:updateFreeGroup()
		self:updatePaidGroup()
	end)

	UIEventListener.Get(self.giftbagPaidBuyBtn).onClick = handler(self, function ()
		xyd.SdkManager.get():showPayment(self.paidGiftbagID)
	end)
	UIEventListener.Get(self.giftbagFreeBuyBtn).onClick = handler(self, function ()
		if self.activityData:getFreeLeftTime() <= 0 then
			return
		end

		local cost = xyd.tables.miscTable:split2Cost("activity_goldfish_pack_cost", "value", "#")

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		xyd.alertYesNo(__("CONFIRM_BUY"), function (yes)
			if yes then
				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_GOLDFISH_GIFTBAG, json.encode({}))
			end
		end)
	end)
end

function ActivityGoldfishGiftbag:initUIComponent()
	self.labelFreeTitle.text = __("ACTIVITY_SAND_GIFTBAG_TEXT01")
	self.labelFreeLimit.text = __("ACTIVITY_SAND_GIFTBAG_TEXT05")
	self.labelPaidTitle.text = __("ACTIVITY_GOLDFISH_PACK_TEXT01")
	self.endLabel_.text = __("END")

	xyd.setUISpriteAsync(self.textImg_, nil, "activity_goldfish_giftbag_logo_" .. xyd.Global.lang)

	self.countdown = import("app.components.CountDown").new(self.timeLabel_)

	self.countdown:setCountDownTime(self.activityData:getEndTime() - xyd.getServerTime())

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)
	end

	self.timeGroupLayout:Reposition()
	self:updatePaidGroup()
	self:updateFreeGroup()
end

function ActivityGoldfishGiftbag:updatePaidGroup()
	self.labelPaidVip.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.paidGiftbagID) .. " " .. __("VIP EXP")
	self.giftbagPaidBuyBtnLabel.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.paidGiftbagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.paidGiftbagID))
	self.paidGiftID = xyd.tables.giftBagTable:getGiftID(self.paidGiftbagID)
	local awards = xyd.tables.giftTable:getAwards(self.paidGiftID)

	for index, icon in ipairs(self.paidIcons) do
		icon:SetActive(false)
	end

	self.count = 1

	for i = 1, #awards do
		local award = awards[i]

		if award[i] ~= 8 and xyd.tables.itemTable:getType(award[i]) ~= 12 then
			local params = {
				notShowGetWayBtn = true,
				show_has_num = false,
				scale = 0.6018518518518519,
				uiRoot = self.awardItemPaidGroupLayout1.gameObject,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}

			if self.count > 3 then
				params.uiRoot = self.awardItemPaidGroupLayout2.gameObject
			end

			if self.count == 2 then
				params.scale = 0.7962962962962963
			end

			if self.paidIcons[self.count] == nil then
				self.paidIcons[self.count] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
			else
				self.paidIcons[self.count]:setInfo(params)
			end

			self.paidIcons[self.count]:SetActive(true)
			self.paidIcons[self.count]:setChoose(self.activityData:getPaidLeftTime() <= 0)

			self.count = self.count + 1
		end
	end

	local leftTime = self.activityData:getPaidLeftTime()
	self.labelPaidLimit.text = __("BUY_GIFTBAG_LIMIT", leftTime)

	if leftTime <= 0 then
		xyd.applyGrey(self.giftbagPaidBuyBtn:GetComponent(typeof(UISprite)))
		self.giftbagPaidBuyBtnLabel:ApplyGrey()
		xyd.setTouchEnable(self.giftbagPaidBuyBtn, false)
	else
		xyd.applyOrigin(self.giftbagPaidBuyBtn:GetComponent(typeof(UISprite)))
		self.giftbagPaidBuyBtnLabel:ApplyOrigin()
		xyd.setTouchEnable(self.giftbagPaidBuyBtn, true)
	end

	self.awardItemPaidGroupLayout1:Reposition()
	self.awardItemPaidGroupLayout2:Reposition()
end

function ActivityGoldfishGiftbag:updateFreeGroup()
	local cost = xyd.tables.miscTable:split2Cost("activity_goldfish_pack_cost", "value", "#")

	xyd.setUISpriteAsync(self.giftbagFreeBuyBtnIcon, nil, xyd.tables.itemTable:getIcon(cost[1]))

	self.giftbagFreeBuyBtnLabel.text = cost[2]
	local awards = xyd.tables.miscTable:split2Cost("activity_goldfish_pack_get", "value", "|#")

	for index, icon in ipairs(self.freeIcons) do
		icon:SetActive(false)
	end

	self.count = 1

	for i = 1, #awards do
		local award = awards[i]

		if award[i] ~= 8 and xyd.tables.itemTable:getType(award[i]) ~= 12 then
			local params = {
				notShowGetWayBtn = true,
				show_has_num = false,
				scale = 0.8055555555555556,
				uiRoot = self.awardItemFreeGroup.gameObject,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}

			if self.freeIcons[self.count] == nil then
				self.freeIcons[self.count] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
			else
				self.freeIcons[self.count]:setInfo(params)
			end

			self.freeIcons[self.count]:SetActive(true)
			self.freeIcons[self.count]:setChoose(self.activityData:getFreeLeftTime() <= 0)

			self.count = self.count + 1
		end
	end

	local leftTime = self.activityData:getFreeLeftTime()
	self.labelFreeLimit.text = __("BUY_GIFTBAG_LIMIT", leftTime)

	if leftTime <= 0 then
		xyd.applyGrey(self.giftbagFreeBuyBtn:GetComponent(typeof(UISprite)))
		xyd.applyGrey(self.giftbagFreeBuyBtnIcon)
		self.giftbagFreeBuyBtnLabel:ApplyGrey()
		xyd.setTouchEnable(self.giftbagFreeBuyBtn, false)
	else
		xyd.applyOrigin(self.giftbagFreeBuyBtn:GetComponent(typeof(UISprite)))
		xyd.applyOrigin(self.giftbagFreeBuyBtnIcon)
		self.giftbagFreeBuyBtnLabel:ApplyOrigin()
		xyd.setTouchEnable(self.giftbagFreeBuyBtn, true)
	end

	self.awardItemFreeGroupGrid:Reposition()
end

return ActivityGoldfishGiftbag
