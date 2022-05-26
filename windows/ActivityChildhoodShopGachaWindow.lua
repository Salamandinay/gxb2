local BaseWindow = import(".BaseWindow")
local ActivityChildhoodShopGachaWindow = class("ActivityChildhoodShopGachaWindow", BaseWindow)
local cjson = require("cjson")

function ActivityChildhoodShopGachaWindow:ctor(name, params)
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_CHILDHOOD_SHOP)
	self.gachaCost = xyd.tables.miscTable:split2Cost("activity_children_gamble_cost", "value", "#")
	local skipAni = xyd.db.misc:getValue("activity_childhood_shop_gacha_skip")
	self.skipAni = skipAni ~= nil and tonumber(skipAni) == 1 and true or false
	local win = xyd.WindowManager.get():getWindow("activity_window")

	if not win or win:getCurContent():getActivityContentID() ~= xyd.ActivityID.ACTIVITY_CHILDHOOD_SHOP then
		xyd.goToActivityWindowAgain({
			select = xyd.ActivityID.ACTIVITY_CHILDHOOD_SHOP
		})
	end

	BaseWindow.ctor(self, name, params)
end

function ActivityChildhoodShopGachaWindow:initWindow()
	self:getUIComponent()
	ActivityChildhoodShopGachaWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
	self:updateRed()
end

function ActivityChildhoodShopGachaWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.btnHelp = self.groupAction:NodeByName("btnHelp").gameObject
	self.btnProb = self.groupAction:NodeByName("btnProb").gameObject
	self.btnSkip = self.groupAction:ComponentByName("btnSkip", typeof(UISprite))
	self.resItem = self.groupAction:NodeByName("resItem").gameObject
	self.resNum = self.resItem:ComponentByName("num", typeof(UILabel))
	self.resBtn = self.resItem:NodeByName("btn").gameObject
	self.btnGacha1 = self.groupAction:NodeByName("btnGacha1").gameObject
	self.btnGacha1Icon = self.btnGacha1:ComponentByName("icon", typeof(UISprite))
	self.btnGacha1Num = self.btnGacha1:ComponentByName("num", typeof(UILabel))
	self.btnGacha1Label = self.btnGacha1:ComponentByName("label", typeof(UILabel))
	self.btnGacha1RedMark = self.btnGacha1:NodeByName("redMark").gameObject
	self.btnGacha10 = self.groupAction:NodeByName("btnGacha10").gameObject
	self.btnGacha10Icon = self.btnGacha10:ComponentByName("icon", typeof(UISprite))
	self.btnGacha10Num = self.btnGacha10:ComponentByName("num", typeof(UILabel))
	self.btnGacha10Label = self.btnGacha10:ComponentByName("label", typeof(UILabel))
	self.btnGacha10RedMark = self.btnGacha10:NodeByName("redMark").gameObject
	self.model = self.groupAction:ComponentByName("model", typeof(UITexture))
	self.shadow = self.groupAction:NodeByName("shadow").gameObject
end

function ActivityChildhoodShopGachaWindow:initUIComponent()
	self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.CHILDHOOD_SHOP_BALLOON)

	xyd.setUISpriteAsync(self.btnGacha1Icon, nil, "icon_" .. self.gachaCost[1])
	xyd.setUISpriteAsync(self.btnGacha10Icon, nil, "icon_" .. self.gachaCost[1])

	self.btnGacha1Num.text = self.gachaCost[2]
	self.btnGacha10Num.text = self.gachaCost[2] * 10
	self.btnGacha1Label.text = __("ACTIVITY_CHILDREN_GAMBLE_BUTTON01")
	self.btnGacha10Label.text = __("ACTIVITY_CHILDREN_GAMBLE_BUTTON02")
	self.effect = xyd.Spine.new(self.model.gameObject)

	self.effect:setInfo("activity_children_gamble", function ()
		self.effect:play("idle", 0)
	end)

	if not self.skipAni then
		xyd.setUISprite(self.btnSkip, nil, "battle_img_skip2")
	else
		xyd.setUISprite(self.btnSkip, nil, "btn_max")
	end
end

function ActivityChildhoodShopGachaWindow:updateRed()
	if xyd.models.backpack:getItemNumByID(self.gachaCost[1]) < self.gachaCost[2] then
		self.btnGacha1RedMark:SetActive(false)
	else
		self.btnGacha1RedMark:SetActive(true)
	end

	if xyd.models.backpack:getItemNumByID(self.gachaCost[1]) < self.gachaCost[2] * 10 then
		self.btnGacha10RedMark:SetActive(false)
	else
		self.btnGacha10RedMark:SetActive(true)
	end
end

function ActivityChildhoodShopGachaWindow:register()
	ActivityChildhoodShopGachaWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function ()
		self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.CHILDHOOD_SHOP_BALLOON)

		self:updateRed()
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = xyd.decodeProtoBuf(event.data)

		if data.activity_id ~= xyd.ActivityID.ACTIVITY_CHILDHOOD_SHOP then
			return
		end

		local detail = cjson.decode(data.detail)

		if detail.type == 2 then
			xyd.WindowManager:get():openWindow("activity_childhood_shop_select_award_window")
		end
	end)

	UIEventListener.Get(self.resBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.CHILDHOOD_SHOP_BALLOON,
			activityData = self.activityData,
			openItemBuyWnd = function ()
				local limitTime = xyd.tables.miscTable:getNumber("activity_children_buy_limit", "value")
				local maxNumCanBuy = limitTime - self.activityData.detail.buy

				xyd.WindowManager.get():openWindow("item_buy_window", {
					item_no_click = false,
					cost = xyd.tables.miscTable:split2Cost("activity_children_buy_cost", "value", "#"),
					max_num = maxNumCanBuy,
					itemParams = {
						num = 1,
						itemID = xyd.ItemID.CHILDHOOD_SHOP_BALLOON
					},
					buyCallback = function (num)
						if maxNumCanBuy <= 0 then
							xyd.showToast(__("FULL_BUY_SLOT_TIME"))

							return
						end

						self.activityData:sendReq({
							type = 3,
							num = num
						})
					end,
					limitText = __("BUY_GIFTBAG_LIMIT", self.activityData.detail.buy .. "/" .. limitTime)
				})
			end
		})
	end

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_CHILDREN_GAMBLE_HELP"
		})
	end

	UIEventListener.Get(self.btnProb).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_childhood_shop_gacha_probability_window")
	end

	UIEventListener.Get(self.btnSkip.gameObject).onClick = function ()
		self.skipAni = not self.skipAni

		xyd.db.misc:setValue({
			key = "activity_childhood_shop_gacha_skip",
			value = self.skipAni and 1 or 0
		})

		if not self.skipAni then
			xyd.setUISprite(self.btnSkip, nil, "battle_img_skip2")
		else
			xyd.setUISprite(self.btnSkip, nil, "btn_max")
		end
	end

	UIEventListener.Get(self.btnGacha1).onClick = function ()
		self:gacha(1)
	end

	UIEventListener.Get(self.btnGacha10).onClick = function ()
		self:gacha(10)
	end
end

function ActivityChildhoodShopGachaWindow:gacha(num)
	if self.doGacha then
		return
	end

	if xyd.models.backpack:getItemNumByID(self.gachaCost[1]) < self.gachaCost[2] * num then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.gachaCost[1])))

		return
	end

	if self.skipAni then
		self.doGacha = true

		self:waitForTime(0.2, function ()
			self.shadow:X(-100)
		end)
		self.effect:play("hit", 1, nil, function ()
			self.doGacha = false

			self.activityData:sendReq({
				type = 2,
				num = num
			})
			self.effect:play("idle", 0)
			self.shadow:X(-15)
		end)
	else
		self.activityData:sendReq({
			type = 2,
			num = num
		})
	end
end

return ActivityChildhoodShopGachaWindow
