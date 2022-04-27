local BaseWindow = import(".BaseWindow")
local ArcticExpeditionBuyWindow = class("ArcticExpeditionBuyWindow", BaseWindow)
local CountDown = require("app.components.CountDown")

function ArcticExpeditionBuyWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.purchaseNum = 0
	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.ARCTIC_EXPEDITION)
end

function ArcticExpeditionBuyWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:layout()
	self:registerEvent()
end

function ArcticExpeditionBuyWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupAction = trans:NodeByName("groupAction").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelWinTitle_ = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.timeGroup = self.groupAction:NodeByName("timeGroup").gameObject
	self.timeGroup_layout = self.groupAction:ComponentByName("timeGroup", typeof(UILayout))
	self.tipsWords = self.timeGroup:ComponentByName("tipsWords", typeof(UILabel))
	self.lockEffect = self.timeGroup:NodeByName("lockEffect").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.okBtn = self.groupAction:NodeByName("okBtn").gameObject
	self.okBtn_label = self.groupAction:ComponentByName("okBtn/button_label", typeof(UILabel))
	self.itemIconNode = self.groupAction:NodeByName("itemIconNode").gameObject
	self.textInputCon = self.groupAction:NodeByName("textInputCon").gameObject
	self.btnHelp = self.groupAction:NodeByName("btnHelp").gameObject
	self.numGroup = self.groupAction:NodeByName("numGroup").gameObject
	self.ImgExchange = self.numGroup:ComponentByName("ImgExchange", typeof(UISprite))
	self.numTextGroup = self.numGroup:NodeByName("e:Group").gameObject
	self.numTextGroup_layout = self.numGroup:ComponentByName("e:Group", typeof(UILayout))
	self.labelCost = self.numTextGroup:ComponentByName("labelCost", typeof(UILabel))
	self.labelSplit = self.numTextGroup:ComponentByName("labelSplit", typeof(UILabel))
	self.labelTotal = self.numTextGroup:ComponentByName("labelTotal", typeof(UILabel))
	self.resBuyTime = self.groupAction:ComponentByName("resBuyTime", typeof(UILabel))
end

function ArcticExpeditionBuyWindow:updateItemRes()
	self.itemIcon = xyd.getItemIcon({
		source = "arctic_expedition_sta",
		show_has_num = false,
		noClick = true,
		itemID = xyd.ItemID.ENTRANCE_TEST_COIN,
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		uiRoot = self.itemIconNode.gameObject
	})
end

function ArcticExpeditionBuyWindow:layout()
	self.okBtn_label.text = __("SURE")
	self.tipsWords.text = __("ARCTIC_EXPEDITION_BUY_TIPS")
	self.labelWinTitle_.text = __("ARCTIC_EXPEDITION_TEXT_42")

	self:updateItemRes()
	self:initAwardCost()

	self.summonEffect_ = xyd.Spine.new(self.lockEffect.gameObject)

	self.summonEffect_:setInfo("fx_ui_shizhong", function ()
		self.summonEffect_:setRenderTarget(self.lockEffect:GetComponent(typeof(UITexture)), 1)
		self.summonEffect_:play("texiao1", 0)
	end)
	self.summonEffect_:SetLocalScale(0.75, 0.75, 0.75)

	self.countDownTiliText = CountDown.new(self.timeLabel)
	local startTime = self.activityData_:startTime()
	local duration = xyd.tables.miscTable:getVal("expedition_energy_cd")

	self.countDownTiliText:setInfo({
		duration = tonumber(duration) - math.fmod(xyd.getServerTime() - startTime, tonumber(duration))
	})
	self.timeGroup_layout:Reposition()
end

function ArcticExpeditionBuyWindow:initAwardCost()
	local priceArr = xyd.tables.miscTable:split2Cost("expedition_energy_price", "value", "#")

	local function addCallback()
		local maxCanBuy = self:getMaxBuyNum()

		if maxCanBuy == 0 then
			maxCanBuy = 1
		end

		if maxCanBuy < self.purchaseNum then
			if priceArr[2] < priceArr[2] * self.purchaseNum < xyd.models.backpack:getItemNumByID(priceArr[1]) then
				xyd.WindowManager.get():openWindow("alert_window", {
					alertType = xyd.AlertType.TIPS,
					message = __("PERSON_NO_CRYSTAL")
				})
			else
				xyd.WindowManager.get():openWindow("alert_window", {
					alertType = xyd.AlertType.TIPS,
					message = __("ACTIVITY_WORLD_BOSS_LIMIT")
				})
			end
		end

		self.purchaseNum = math.min(self.purchaseNum, maxCanBuy)

		self.textInput:setCurNum(self.purchaseNum)
		self:updateCostLayout()
	end

	local SelectNum = import("app.components.SelectNum")
	self.textInput = SelectNum.new(self.textInputCon, "default")

	self.textInput:setInfo({
		minNum = 1,
		curNum = 1,
		maxNum = self:getMaxBuyNum(),
		addCallback = addCallback,
		callback = handler(self, function (self, input)
			self.purchaseNum = input

			self:updateCostLayout()
		end)
	})
	self:reSelectItem()
	self.textInput:setKeyboardPos(0, -365)
end

function ArcticExpeditionBuyWindow:getMaxBuyNum()
	local maxCanBuy = self.activityData_:getMaxBuyNum() or 1
	local cost = xyd.tables.miscTable:split2Cost("expedition_energy_price", "value", "#")
	local backpackCanBuy = math.floor(xyd.models.backpack:getItemNumByID(cost[1]) / cost[2])

	return math.min(backpackCanBuy, maxCanBuy)
end

function ArcticExpeditionBuyWindow:reSelectItem()
	self.purchaseNum = 1

	self.textInput:setCurNum(self.purchaseNum)
	self:updateCostLayout()
end

function ArcticExpeditionBuyWindow:updateCostLayout()
	local total = xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)
	local priceArr = xyd.tables.miscTable:split2Cost("expedition_energy_price", "value", "#")
	local buyNum = self.purchaseNum

	if buyNum <= 0 then
		buyNum = 1
	end

	local needMoney = buyNum * priceArr[2]
	self.costNum_ = needMoney
	self.labelTotal.text = xyd.getRoughDisplayNumber(total)

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL) < needMoney then
		self.labelTotal.color = Color.New2(4278190335.0)
	else
		self.labelTotal.color = Color.New2(1583978239)
	end

	self.labelCost.text = tostring(needMoney)

	self.numTextGroup_layout:Reposition()
end

function ArcticExpeditionBuyWindow:registerEvent()
	UIEventListener.Get(self.btnHelp.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ARCTIC_EXPEDITION_HELP_ENERGY"
		})
	end)
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.okBtn.gameObject).onClick = handler(self, function ()
		if xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL) < self.costNum_ then
			xyd.WindowManager.get():openWindow("alert_window", {
				alertType = xyd.AlertType.TIPS,
				message = __("NOT_ENOUGH", xyd.tables.itemTextTable:getName(xyd.ItemID.CRYSTAL))
			})

			return
		end

		local canBuyTime = self:getMaxBuyNum()

		if canBuyTime == 0 then
			xyd.WindowManager.get():openWindow("alert_window", {
				alertType = xyd.AlertType.TIPS,
				message = __("ACTIVITY_WORLD_BOSS_LIMIT")
			})
		end

		local msg = messages_pb:boss_buy_req()
		msg.activity_id = xyd.ActivityID.ARCTIC_EXPEDITION
		msg.num = self.purchaseNum

		xyd.Backend.get():request(xyd.mid.BOSS_BUY, msg)
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

return ArcticExpeditionBuyWindow
