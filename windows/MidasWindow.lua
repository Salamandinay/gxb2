local BaseWindow = import(".BaseWindow")
local MidasWindow = class("MidasWindow", BaseWindow)
local CountDown = require("app.components.CountDown")

function MidasWindow:ctor(name, params)
	self.is_free_award = 0
	self.buy_times = 0
	self.baseNum = 0

	BaseWindow.ctor(self, name, params)
end

function MidasWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	xyd.models.midas:reqMidasInfoNew()
	self:initUIComponent()
	self:registerEvent()
end

function MidasWindow:getUIComponent()
	local go = self.window_
	self.groupClock = go:NodeByName("main/groupCountDown/groupClock").gameObject
	self.clockImg = go:ComponentByName("main/groupCountDown/groupClock/e:image", typeof(UISprite))
	self.groupCountDown = go:NodeByName("main/groupCountDown").gameObject
	self.labelText01 = go:ComponentByName("main/groupCountDown/labelText01", typeof(UILabel))
	self.labelText02 = go:ComponentByName("main/labelText02", typeof(UILabel))
	local labelTime = go:ComponentByName("main/groupCountDown/labelTime", typeof(UILabel))
	self.labelTime = CountDown.new(labelTime)
	self.labelNum1 = go:ComponentByName("main/group1/labelNum1", typeof(UILabel))
	self.labelNum2 = go:ComponentByName("main/group3/labelNum3", typeof(UILabel))
	self.btnBuy1 = go:NodeByName("main/group1/btnBuy1").gameObject
	self.btnBuy2 = go:NodeByName("main/group3/btnBuy3").gameObject
	self.btnBuy1_label = go:ComponentByName("main/group1/btnBuy1/button_label", typeof(UILabel))
	self.btnBuy2_label = go:ComponentByName("main/group3/btnBuy3/button_label", typeof(UILabel))
	self.labelText1 = go:ComponentByName("main/group1/labelGroup/textLabel", typeof(UILabel))
	self.labelText2 = go:ComponentByName("main/group3/labelGroup/textLabel", typeof(UILabel))
	self.numLabel1 = go:ComponentByName("main/group1/labelGroup/numLabel", typeof(UILabel))
	self.numLabel2 = go:ComponentByName("main/group3/labelGroup/numLabel", typeof(UILabel))
	self.spineTex = go:NodeByName("main/group3/spineTex").gameObject
	self.labelWinTitle = go:ComponentByName("main/labelWinTitle", typeof(UILabel))
	self.closeBtn = go:NodeByName("main/closeBtn").gameObject
	self.helpBtn = go:NodeByName("main/helpBtn").gameObject
end

function MidasWindow:initUIComponent()
	self.baseNum = xyd.tables.midasTable:getGoldNew(xyd.models.backpack:getLev()) * (1 + xyd.tables.vipTable:extraMidas(xyd.models.backpack:getVipLev()))

	self:setBtnState()

	self.labelText01.text = __("MIDAS_TEXT01")
	self.labelText02.text = __("MIDAS_TEXT02")

	self.labelText02:SetActive(false)

	self.labelText1.text = __("MIDAS_TEXT05") .. " "
	self.labelText2.text = __("MIDAS_TEXT06") .. " "

	if not self.effect then
		self.effect = xyd.Spine.new(self.spineTex)

		self.effect:setInfo("dianjinshou", function ()
			self.effect:SetLocalScale(0.28, 0.28, 0.28)
			self.effect:play("texiao01", 0, 1)
		end)
	else
		self.effect:play("texiao01", 0, 1)
	end

	xyd.setUISprite(self.btnBuy2:ComponentByName("costIcon", typeof(UISprite)), nil, "icon_" .. xyd.tables.midasBuyCoinTable:getCost(self.buy_times + 1)[1])

	self.clockEffect = xyd.Spine.new(self.groupClock)

	self.clockEffect:setInfo("fx_ui_shizhong", function ()
		self.clockEffect:setRenderTarget(self.clockImg, 1)
		self.clockEffect:play("texiao1", 0, 1, nil, true)
	end)
end

function MidasWindow:setBtnState()
	if self.is_free_award and self.is_free_award > 0 then
		self.btnBuy1_label.color = Color.New2(960513791)
		self.btnBuy1_label.effectColor = Color.New2(4294967295.0)
		self.btnBuy1_label.text = __("ALREADY_GET_PRIZE")

		xyd.applyChildrenGrey(self.btnBuy1.gameObject)

		self.btnBuy1:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	else
		self.btnBuy1_label.color = Color.New2(4294967295.0)
		self.btnBuy1_label.effectColor = Color.New2(1012112383)
		self.btnBuy1_label.text = __("MIDAS_TEXT03")

		xyd.applyChildrenOrigin(self.btnBuy1.gameObject)

		self.btnBuy1:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end

	self.labelNum1.text = "X" .. self.baseNum

	if self.buy_times < xyd.tables.vipTable:getMidasTimes(xyd.models.backpack:getVipLev()) then
		self.labelNum2.text = "X" .. self.baseNum * xyd.tables.midasBuyCoinTable:getMultiple(self.buy_times + 1)
	else
		self.labelNum2.text = "X" .. self.baseNum * xyd.tables.midasBuyCoinTable:getMultiple(self.buy_times)
	end

	self.numLabel1.text = 1 - self.is_free_award
	self.numLabel2.text = xyd.tables.vipTable:getMidasTimes(xyd.models.backpack:getVipLev()) - self.buy_times

	if self.buy_times and xyd.tables.vipTable:getMidasTimes(xyd.models.backpack:getVipLev()) <= self.buy_times then
		xyd.applyChildrenGrey(self.btnBuy2.gameObject)

		self.btnBuy2:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		self.btnBuy2_label.color = Color.New2(960513791)
		self.btnBuy2_label.effectColor = Color.New2(4294967295.0)

		self["btnBuy" .. 2]:ComponentByName("costIcon", typeof(UISprite)):SetActive(false)

		self["btnBuy" .. 2 .. "_label"].text = __("MIDAS_TEXT08")
		self["btnBuy" .. 2 .. "_label"].width = 140

		self["btnBuy" .. 2 .. "_label"].gameObject:X(0)
	else
		xyd.applyChildrenOrigin(self.btnBuy2.gameObject)

		self.btnBuy2:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		self.btnBuy2_label.color = Color.New2(4294967295.0)
		self.btnBuy2_label.effectColor = Color.New2(1012112383)

		self["btnBuy" .. 2]:ComponentByName("costIcon", typeof(UISprite)):SetActive(true)

		self["btnBuy" .. 2 .. "_label"].text = xyd.tables.midasBuyCoinTable:getCost(self.buy_times + 1)[2]

		self["btnBuy" .. 2 .. "_label"].gameObject:X(28)
	end
end

function MidasWindow:registerEvent()
	xyd.setDarkenBtnBehavior(self["btnBuy" .. 1].gameObject, self, function ()
		xyd.models.midas:buyNew(1)

		self.buyIndex = 1
	end)
	xyd.setDarkenBtnBehavior(self["btnBuy" .. 2].gameObject, self, function ()
		if xyd.isItemAbsence(xyd.tables.midasBuyCoinTable:getCost(self.buy_times + 1)[1], xyd.tables.midasBuyCoinTable:getCost(self.buy_times + 1)[2]) then
			return
		end

		local timeStamp = xyd.db.misc:getValue("midas_time_stamp")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime()) then
			xyd.openWindow("gamble_tips_window", {
				type = "midas",
				text = __("MIDAS_TEXT07", xyd.tables.midasBuyCoinTable:getCost(self.buy_times + 1)[2]),
				callback = function ()
					xyd.models.midas:buyNew(2)

					self.buyIndex = 2
				end
			})
		else
			xyd.models.midas:buyNew(2)

			self.buyIndex = 2
		end
	end)
	self.eventProxy_:addEventListener(xyd.event.MIDAS_BUY_2, self.onBuy, self)
	self.eventProxy_:addEventListener(xyd.event.GET_MIDAS_INFO_2, self.onMidasInfo, self)
	self:setCloseBtn(self.closeBtn)

	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		local window = xyd.WindowManager:get():openWindow("help_window", {
			key = "MIDAS_TEXT_HELP"
		})
	end)
end

function MidasWindow:onBuy(event)
	local flag = false
	local items = {}

	if self.is_free_award < 1 then
		flag = true
	end

	self.is_free_award = event.data.is_free_award
	self.buy_times = event.data.buy_times

	self:setBtnState()
	self:setTimeCountDown(xyd.getTomorrowTime())

	if self.buyIndex == 1 then
		items = {}

		table.insert(items, {
			item_id = 1,
			item_num = self.baseNum
		})
	else
		local num = self.baseNum * xyd.tables.midasBuyCoinTable:getMultiple(self.buy_times)
		items = {}

		table.insert(items, {
			item_id = 1,
			item_num = num
		})
	end

	xyd.models.itemFloatModel:pushNewItems(items)
end

function MidasWindow:onMidasInfo(event)
	self.is_free_award = event.data.is_free_award
	self.buy_times = event.data.buy_times

	self:setBtnState()
	self:setTimeCountDown(xyd.getTomorrowTime())
end

function MidasWindow:setTimeCountDown(nextBuyTime)
	if nextBuyTime - xyd:getServerTime() <= 0 then
		self.labelTime:stopTimeCount()
		self.groupCountDown:SetActive(false)
		self.groupClock:SetActive(false)
		self.labelText02:SetActive(true)

		return
	end

	self.groupCountDown:SetActive(true)
	self.groupClock:SetActive(true)
	self.labelText02:SetActive(false)
	self.labelTime:setInfo({
		duration = nextBuyTime - xyd:getServerTime(),
		callback = function ()
			xyd.models.midas:reqMidasInfo()
		end
	})
end

return MidasWindow
