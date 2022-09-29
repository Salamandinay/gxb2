local BaseWindow = import(".BaseWindow")
local ActivityPirateGiftbagWindow = class("ActivityPirateGiftbagWindow", BaseWindow)
local cjson = require("cjson")

function ActivityPirateGiftbagWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_PIRATE)
	self.progressValue = self.activityData:getGiftbagProgress()
end

function ActivityPirateGiftbagWindow:initWindow()
	self.giftbagID_ = self.activityData.detail.charges[1].table_id
	self.freeIcons = {}
	self.paidIcons = {}

	self:getUIComponent()
	ActivityPirateGiftbagWindow.super.initWindow(self)
	self:layout()
	self:onRegisterEvent()
	self:updateBtnState()
	self:updateRedMark()
end

function ActivityPirateGiftbagWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.imgBg_ = winTrans:ComponentByName("imgBg_", typeof(UITexture))
	local group1 = winTrans:NodeByName("group1").gameObject
	local group2 = winTrans:NodeByName("group2").gameObject
	self.labelLimit_ = group2:ComponentByName("labelLimit_", typeof(UILabel))
	self.labelPaidVip_ = group2:ComponentByName("labelVip_", typeof(UILabel))
	self.awardItemFreeGroupLayout = group1:ComponentByName("awardItemGroup1", typeof(UILayout))
	self.awardItemPaidGroupLayout = group2:ComponentByName("awardItemGroup2", typeof(UILayout))
	self.giftbagPaidBuyBtn = group2:NodeByName("giftbagBuyBtn2").gameObject
	self.giftbagPaidBuyBtnLabel = self.giftbagPaidBuyBtn:ComponentByName("button_label", typeof(UILabel))
	self.giftbagFreeBuyBtn = group1:NodeByName("giftbagBuyBtn1").gameObject
	self.giftbagFreeBuyBtnLabel = self.giftbagFreeBuyBtn:ComponentByName("button_label", typeof(UILabel))
	self.giftbagRedIcon = self.giftbagFreeBuyBtn:ComponentByName("red_icon", typeof(UISprite))
	self.progressBar_ = winTrans:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressImg = winTrans:ComponentByName("progressBar_/progressImg", typeof(UISprite))
	self.progressDesc = winTrans:ComponentByName("progressBar_/progressLabel", typeof(UILabel))
	self.progressLabel2 = winTrans:ComponentByName("progressBar_/progressLabel2", typeof(UILabel))
	self.progressLabel3 = winTrans:ComponentByName("progressBar_/progressLabel3", typeof(UILabel))
end

function ActivityPirateGiftbagWindow:layout()
	self.progressLabel2.text = __("ACTIVITY_PIRATE_TEXT01")
	self.progressLabel3.text = __("ACTIVITY_PIRATE_TEXT02")

	self:updateFreeGroup()
	self:updatePaidGroup()
	self:updateProgressBar()
end

function ActivityPirateGiftbagWindow:updateFreeGroup()
	self.giftbagFreeBuyBtnLabel.text = __("ACTIVITY_PIRATE_TEXT15")
	local awards = xyd.tables.miscTable:split2Cost("activity_pirate_giftbag_free_awards", "value", "|#")

	for index, icon in ipairs(self.freeIcons) do
		icon:SetActive(false)
	end

	self.count = 1

	for i = 1, #awards do
		local award = awards[i]

		if award[i] ~= 8 then
			local params = {
				notShowGetWayBtn = true,
				show_has_num = true,
				scale = 0.6944444444444444,
				uiRoot = self.awardItemFreeGroupLayout.gameObject,
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

			self.count = self.count + 1
		end
	end

	local leftTime = self.activityData:getFreeLeftTime()

	if leftTime <= 0 then
		xyd.applyGrey(self.giftbagFreeBuyBtn:GetComponent(typeof(UISprite)))
		self.giftbagFreeBuyBtnLabel:ApplyGrey()
		xyd.setTouchEnable(self.giftbagFreeBuyBtn, false)
	else
		xyd.applyOrigin(self.giftbagFreeBuyBtn:GetComponent(typeof(UISprite)))
		self.giftbagFreeBuyBtnLabel:ApplyOrigin()
		xyd.setTouchEnable(self.giftbagFreeBuyBtn, true)
	end

	self.awardItemFreeGroupLayout:Reposition()
end

function ActivityPirateGiftbagWindow:updatePaidGroup()
	self.labelPaidVip_.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftbagID_) .. " " .. __("VIP EXP")
	self.giftbagPaidBuyBtnLabel.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftbagID_)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftbagID_))
	self.paidGiftID = xyd.tables.giftBagTable:getGiftID(self.giftbagID_)
	local awards = xyd.tables.giftTable:getAwards(self.paidGiftID)

	for index, icon in ipairs(self.paidIcons) do
		icon:SetActive(false)
	end

	self.count = 1

	for i = 1, #awards do
		local award = awards[i]

		if award[i] ~= 8 then
			local params = {
				notShowGetWayBtn = true,
				show_has_num = true,
				scale = 0.6944444444444444,
				uiRoot = self.awardItemPaidGroupLayout.gameObject,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}

			if self.paidIcons[self.count] == nil then
				self.paidIcons[self.count] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
			else
				self.paidIcons[self.count]:setInfo(params)
			end

			self.paidIcons[self.count]:SetActive(true)

			self.count = self.count + 1
		end
	end

	local leftTime = self.activityData:getPaidLeftTime()
	self.labelLimit_.text = __("BUY_GIFTBAG_LIMIT", leftTime)

	if leftTime <= 0 then
		xyd.applyGrey(self.giftbagPaidBuyBtn:GetComponent(typeof(UISprite)))
		self.giftbagPaidBuyBtnLabel:ApplyGrey()
		xyd.setTouchEnable(self.giftbagPaidBuyBtn, false)
	else
		xyd.applyOrigin(self.giftbagPaidBuyBtn:GetComponent(typeof(UISprite)))
		self.giftbagPaidBuyBtnLabel:ApplyOrigin()
		xyd.setTouchEnable(self.giftbagPaidBuyBtn, true)
	end

	self.awardItemPaidGroupLayout:Reposition()
end

function ActivityPirateGiftbagWindow:updateRedMark()
	self.giftbagRedIcon:SetActive(self.activityData:getGiftbagRedMarkState())
end

function ActivityPirateGiftbagWindow:updateBtnState()
	local tmpLable1 = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftbagID_)) or ""
	local tmpLable2 = tostring(xyd.tables.giftBagTextTable:getCharge(self.giftbagID_)) or ""
	self.labelPaidVip_.text = "+" .. tostring(tostring(xyd.tables.giftBagTable:getVipExp(self.giftbagID_))) .. " VIP EXP"
	local freeleftTime = self.activityData:getFreeLeftTime()

	if freeleftTime <= 0 then
		xyd.applyChildrenGrey(self.giftbagFreeBuyBtn.gameObject)

		self.giftbagFreeBuyBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	else
		xyd.applyChildrenOrigin(self.giftbagFreeBuyBtn.gameObject)

		self.giftbagFreeBuyBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end

	local paidleftTime = self.activityData:getPaidLeftTime()
	self.labelLimit_.text = __("BUY_GIFTBAG_LIMIT", paidleftTime)

	if paidleftTime <= 0 then
		xyd.applyChildrenGrey(self.giftbagPaidBuyBtn.gameObject)

		self.giftbagPaidBuyBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	else
		xyd.applyChildrenOrigin(self.giftbagPaidBuyBtn.gameObject)

		self.giftbagPaidBuyBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end

	if self.progressValue == 1 then
		self.progressBar_:SetActive(false)
	else
		self.progressBar_:SetActive(true)
	end
end

function ActivityPirateGiftbagWindow:onRegisterEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))

	UIEventListener.Get(self.giftbagPaidBuyBtn).onClick = function ()
		if self.progressValue == 1 then
			xyd.SdkManager:get():showPayment(self.giftbagID_)
		else
			xyd.alertTips(__("ACTIVITY_PIRATE_TEXT14"))
		end
	end

	UIEventListener.Get(self.giftbagFreeBuyBtn).onClick = handler(self, function ()
		if self.progressValue == 1 then
			local data = cjson.encode({
				type = 2
			})

			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_PIRATE, data)
		else
			xyd.alertTips(__("ACTIVITY_PIRATE_TEXT14"))
		end
	end)

	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, function (self, evt)
		self:updateBtnState()
		self:updateRedMark()
	end))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, function (event)
		local data = event.activityData

		if data.activity_id == xyd.ActivityID.ACTIVITY_PIRATE then
			local awards = xyd.tables.miscTable:split2Cost("activity_pirate_giftbag_free_awards", "value", "|#")
			local items = {}

			for _, info in ipairs(awards) do
				local item = {
					item_id = info[1],
					item_num = info[2]
				}

				table.insert(items, item)
			end

			xyd.models.itemFloatModel:pushNewItems(items)
			self:updateBtnState()
			self:updateRedMark()
		end
	end))
end

function ActivityPirateGiftbagWindow:updateProgressBar()
	local progress = string.format("%.3f", self.progressValue * 100)
	self.progressDesc.text = progress .. "%"

	xyd.setUISpriteAsync(self.progressImg, nil, "activity_pirate_progress_bg3")

	self.progressBar_.value = self.progressValue
end

function ActivityPirateGiftbagWindow:onGetAward(event)
	local data = xyd.decodeProtoBuf(event.data)
	local detail = cjson.decode(data.detail)

	for i = 1, #detail.items do
		local itemId = detail.items[i].item_id

		if xyd.tables.itemTable:getType(itemId) == xyd.ItemType.SKIN then
			xyd.onGetNewPartnersOrSkins({
				destory_res = false,
				skins = {
					itemId
				}
			})
		end
	end
end

return ActivityPirateGiftbagWindow
