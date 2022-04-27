local BaseWindow = import(".BaseWindow")
local ActivityEntranceTestBuyTiliWindow = class("ActivityEntranceTestBuyTiliWindow", BaseWindow)
local CountDown = require("app.components.CountDown")

function ActivityEntranceTestBuyTiliWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.purchaseNum = 0
	self.skinName = "ActivityEntranceTestBuyTiliWindowSkin"
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
end

function ActivityEntranceTestBuyTiliWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)

	local priceArr = xyd.tables.miscTable:split2Cost("activity_warmup_arena_buy_costs", "value", "|#")
	local butTimes = self.activityData.detail.buy_times + 1

	if butTimes > #priceArr then
		butTimes = #priceArr
	end

	self.oneTiliCost = priceArr[butTimes][2]

	self:layout()
	self:registerEvent()
end

function ActivityEntranceTestBuyTiliWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupAction = trans:NodeByName("groupAction").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelWinTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
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
end

function ActivityEntranceTestBuyTiliWindow:updateItemRes()
	self.itemIcon = xyd.getItemIcon({
		show_has_num = false,
		itemID = xyd.ItemID.ENTRANCE_TEST_COIN,
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		uiRoot = self.itemIconNode.gameObject
	})
end

function ActivityEntranceTestBuyTiliWindow:layout()
	self.okBtn_label.text = __("SURE")
	self.tipsWords.text = __("ACTIVITY_ENTRANCE_TEST_TIME_TIPS")

	self:updateItemRes()
	self:initAwardCost()

	if xyd.Global.lang == "en_en" then
		self.tipsWords.overflowMethod = UILabel.Overflow.ShrinkContent
		self.tipsWords.width = 400
		self.tipsWords.height = 24

		self.timeGroup_layout:Reposition()
	end

	self.summonEffect_ = xyd.Spine.new(self.lockEffect.gameObject)

	self.summonEffect_:setInfo("fx_ui_shizhong", function ()
		self.summonEffect_:setRenderTarget(self.lockEffect:GetComponent(typeof(UITexture)), 1)
		self.summonEffect_:play("texiao1", 0)
	end)
	self.summonEffect_:SetLocalScale(0.75, 0.75, 0.75)

	self.countDownTiliText = CountDown.new(self.timeLabel)

	self.countDownTiliText:setInfo({
		duration = xyd.getTomorrowTime() - xyd.getServerTime()
	})
	self.timeGroup_layout:Reposition()
end

function ActivityEntranceTestBuyTiliWindow:initAwardCost()
	local maxTili = xyd.tables.miscTable:getNumber("activity_warmup_arena_energy_reset", "value")

	local function addCallback()
		local maxCanBuy = 0
		local priceArr = xyd.tables.miscTable:split2Cost("activity_warmup_arena_buy_costs", "value", "|#")
		local butTimes = self.activityData.detail.buy_times

		if butTimes + 1 > #priceArr then
			butTimes = #priceArr - 1
		end

		local costNum = 0
		local num = 0

		for i = butTimes + 1, #priceArr do
			costNum = costNum + priceArr[i][2]
			num = num + 1

			if xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL) < costNum then
				maxCanBuy = num - 1

				break
			else
				maxCanBuy = num
			end
		end

		local maxBuyNum = maxCanBuy

		if maxBuyNum == 0 then
			maxBuyNum = 1
		end

		if maxBuyNum < self.purchaseNum then
			if butTimes + self.purchaseNum > #priceArr then
				xyd.WindowManager.get():openWindow("alert_window", {
					alertType = xyd.AlertType.TIPS,
					message = __("ACTIVITY_WORLD_BOSS_LIMIT")
				})
			else
				xyd.WindowManager.get():openWindow("alert_window", {
					alertType = xyd.AlertType.TIPS,
					message = __("PERSON_NO_CRYSTAL")
				})
			end
		end

		self.purchaseNum = math.min(self.purchaseNum, maxBuyNum)

		self.textInput:setCurNum(self.purchaseNum)

		local priceArr = xyd.tables.miscTable:split2Cost("activity_warmup_arena_buy_costs", "value", "|#")
		local butLeftTimes = #priceArr - self.activityData.detail.buy_times

		if butLeftTimes == 0 then
			xyd.WindowManager.get():openWindow("alert_window", {
				alertType = xyd.AlertType.TIPS,
				message = __("ACTIVITY_WORLD_BOSS_LIMIT")
			})

			self.purchaseNum = 1

			self.textInput:setCurNum(self.purchaseNum)
		end

		if butLeftTimes > 0 and butLeftTimes < self.purchaseNum then
			xyd.WindowManager.get():openWindow("alert_window", {
				alertType = xyd.AlertType.TIPS,
				message = __("ACTIVITY_WORLD_BOSS_LIMIT")
			})

			self.purchaseNum = butLeftTimes

			self.textInput:setCurNum(self.purchaseNum)
		end

		self:updateCostLayout()
	end

	local SelectNum = import("app.components.SelectNum")
	self.textInput = SelectNum.new(self.textInputCon, "default")

	self.textInput:setInfo({
		minNum = 1,
		curNum = 1,
		addCallback = addCallback,
		callback = handler(self, function (self, input)
			self.purchaseNum = input

			self:updateCostLayout()
		end)
	})
	self:reSelectItem()
	self.textInput:setKeyboardPos(0, -365)
end

function ActivityEntranceTestBuyTiliWindow:reSelectItem()
	self.purchaseNum = 1

	self.textInput:setCurNum(self.purchaseNum)
	self:updateCostLayout()
end

function ActivityEntranceTestBuyTiliWindow:updateCostLayout()
	local total = xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)
	local priceArr = xyd.tables.miscTable:split2Cost("activity_warmup_arena_buy_costs", "value", "|#")
	local butTimes = self.activityData.detail.buy_times
	local maxSearchNum = butTimes + self.purchaseNum

	if maxSearchNum > #priceArr then
		maxSearchNum = #priceArr
	end

	local newCostNum = 0

	for i = butTimes + 1, maxSearchNum do
		newCostNum = newCostNum + priceArr[i][2]
	end

	local needMoney = newCostNum
	self.labelTotal.text = xyd.getRoughDisplayNumber(total)

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL) < needMoney then
		self.labelTotal.color = Color.New2(4278190335.0)
	else
		self.labelTotal.color = Color.New2(1583978239)
	end

	self.labelCost.text = tostring(needMoney)

	self.numTextGroup_layout:Reposition()
end

function ActivityEntranceTestBuyTiliWindow:registerEvent()
	UIEventListener.Get(self.btnHelp.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_ENTRANCE_TEST_TILI_HELP"
		})
	end)
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.okBtn.gameObject).onClick = handler(self, function ()
		if xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL) < self.oneTiliCost then
			xyd.WindowManager.get():openWindow("alert_window", {
				alertType = xyd.AlertType.TIPS,
				message = __("NOT_ENOUGH", xyd.tables.itemTextTable:getName(xyd.ItemID.CRYSTAL))
			})

			return
		end

		local priceArr = xyd.tables.miscTable:split2Cost("activity_warmup_arena_buy_costs", "value", "|#")
		local butLeftTimes = #priceArr - self.activityData.detail.buy_times

		if butLeftTimes == 0 then
			xyd.WindowManager.get():openWindow("alert_window", {
				alertType = xyd.AlertType.TIPS,
				message = __("ACTIVITY_WORLD_BOSS_LIMIT")
			})
		end

		local maxTili = xyd.tables.miscTable:getNumber("activity_warmup_arena_energy_reset", "value")

		if maxTili < self.purchaseNum + self.activityData.detail.free_times then
			local timeStamp = xyd.db.misc:getValue("activity_entrance_test_buy_tili_tip_time_stamp")

			if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
				xyd.WindowManager.get():openWindow("gamble_tips_window", {
					tipsTextY = 60,
					type = "activity_entrance_test_buy_tili_tip",
					tipsHeight = 100,
					callback = handler(self, function ()
						self:buyTili()
					end),
					text = __("ENTRANCE_TEST_ENERGY_EXCEED")
				})

				return
			end
		end

		local msg = messages_pb:boss_buy_req()
		msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
		msg.num = self.purchaseNum

		xyd.Backend.get():request(xyd.mid.BOSS_BUY, msg)
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function ActivityEntranceTestBuyTiliWindow:buyTili()
	local msg = messages_pb:boss_buy_req()
	msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
	msg.num = self.purchaseNum

	xyd.Backend.get():request(xyd.mid.BOSS_BUY, msg)
	xyd.WindowManager.get():closeWindow(self.name_)
end

return ActivityEntranceTestBuyTiliWindow
