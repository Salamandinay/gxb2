local NewbeeLessonGiftbag = class("NewbeeLessonGiftbag", import(".ActivityContent"))
local GiftBagItem = class("GiftBagItem")

function NewbeeLessonGiftbag:ctor(parentGo, params, parent)
	NewbeeLessonGiftbag.super.ctor(self, parentGo, params, parent)
end

function NewbeeLessonGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/newbee_lesson_giftbag"
end

function NewbeeLessonGiftbag:resizeToParent()
	NewbeeLessonGiftbag.super.resizeToParent(self)
	self.textLogo:Y(-158 + -46 * self.scale_num_contrary)
	self.groupMain:Y(-602 + -156 * self.scale_num_contrary)
end

function NewbeeLessonGiftbag:initUI()
	self:getUIComponent()
	NewbeeLessonGiftbag.super.initUI(self)
	self:layout()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
	xyd.db.misc:setValue({
		key = "newbee_lesson_giftbag",
		value = xyd.getServerTime()
	})
	xyd.models.activity:updateRedMarkCount(self.id, function ()
	end)
end

function NewbeeLessonGiftbag:getUIComponent()
	local go = self.go
	self.textLogo = go:ComponentByName("textLogo", typeof(UISprite))
	self.labelRefreshTime = self.textLogo:ComponentByName("timeGroup/labelRefreshTime", typeof(UILabel))
	self.labelRefresh = self.textLogo:ComponentByName("timeGroup/labelRefresh", typeof(UILabel))
	self.groupMain = go:NodeByName("groupMain").gameObject
	self.scroller = self.groupMain:ComponentByName("scroller", typeof(UIScrollView))
	self.groupContent = self.scroller:NodeByName("groupContent").gameObject
	self.giftBagItem = self.groupMain:NodeByName("giftbag_item").gameObject
end

function NewbeeLessonGiftbag:layout()
	xyd.setUISpriteAsync(self.textLogo, nil, "newbee_giftbag_" .. xyd.Global.lang)

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
		self.labelRefresh.fontSize = 16
		self.labelRefreshTime.fontSize = 16
	elseif xyd.Global.lang == "en_en" then
		self.labelRefresh.fontSize = 18
		self.labelRefreshTime.fontSize = 18
	end

	local duration = nil

	if self.id == xyd.ActivityID.NEWBEE_LESSON_GIFTBAG then
		self.labelRefresh.text = __("ACTIVITY_NEWBEE_LESSON_TEXT01")
		duration = xyd.getTomorrowTime() - xyd.getServerTime()
	else
		local deltaTime = xyd.getServerTime() - xyd.getDayStartTime(self.activityData.detail_.start_time)

		if deltaTime < 604800 then
			self.labelRefresh.text = __("ACTIVITY_NEWBEE_LESSON_TEXT01")
		else
			self.labelRefresh.text = __("ACTIVITY_NEWBEE_LESSON_TEXT02")
		end

		duration = 604800 - deltaTime % 604800
	end

	if duration < 0 then
		self.labelRefreshTime:SetActive(false)
		self.labelRefresh:SetActive(false)
	else
		local timeCount = import("app.components.CountDown").new(self.labelRefreshTime)

		timeCount:setInfo({
			function ()
				xyd.models.activity:reqActivityByID(self.id)
				xyd.WindowManager.get():closeWindow("activity_window")
			end,
			duration = duration
		})
	end

	local charges = self.activityData.detail_.charges
	local list = {}

	for _, data in ipairs(charges) do
		table.insert(list, {
			table_id = data.table_id,
			buy_times = data.buy_times,
			limit_times = data.limit_times
		})
	end

	table.sort(list, function (a, b)
		local aLeft = a.limit_times - a.buy_times
		local bLeft = b.limit_times - b.buy_times

		if aLeft ~= 0 and bLeft ~= 0 or aLeft == 0 and bLeft == 0 then
			return a.table_id < b.table_id
		else
			return aLeft ~= 0
		end
	end)

	self.itemList = {}

	for _, data in ipairs(list) do
		local tmp = NGUITools.AddChild(self.groupContent, self.giftBagItem)
		local item = GiftBagItem.new(tmp, data)
		self.itemList[data.table_id] = item
	end

	self.scroller:ResetPosition()
end

function NewbeeLessonGiftbag:onRecharge(event)
	local giftBagId = event.data.giftbag_id

	if self.itemList[giftBagId] then
		local charges = self.activityData.detail_.charges
		local leftTime = 0

		for _, item in ipairs(charges) do
			if giftBagId == item.table_id then
				leftTime = item.limit_times - item.buy_times

				break
			end
		end

		self.itemList[giftBagId]:setLeftTime(leftTime)
	end
end

function GiftBagItem:ctor(go, params)
	self.go = go
	self.params = params
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.labelVIP = go:ComponentByName("labelVIP", typeof(UILabel))
	self.labelVIPvalue = go:ComponentByName("labelVIPvalue", typeof(UILabel))
	self.labelLimit = go:ComponentByName("labelLimit", typeof(UILabel))
	self.btnBuy = go:NodeByName("btnBuy").gameObject
	self.labelPrice = self.btnBuy:ComponentByName("labelPrice", typeof(UILabel))

	self:layout()

	UIEventListener.Get(self.btnBuy).onClick = function ()
		xyd.SdkManager.get():showPayment(self.params.table_id)
	end
end

function GiftBagItem:layout()
	local giftID = xyd.tables.giftBagTable:getGiftID(self.params.table_id)
	local awards = xyd.tables.giftTable:getAwards(giftID)

	for _, data in ipairs(awards) do
		if data[1] ~= xyd.ItemID.VIP_EXP then
			xyd.getItemIcon({
				show_has_num = true,
				scale = 0.7037037037037037,
				uiRoot = self.groupIcon,
				itemID = data[1],
				num = data[2]
			})
		end
	end

	self.labelVIP.text = "VIP EXP"
	self.labelVIPvalue.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.params.table_id)
	self.labelPrice.text = xyd.tables.giftBagTextTable:getCurrency(self.params.table_id) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.params.table_id)

	self:setLeftTime(self.params.limit_times - self.params.buy_times)
end

function GiftBagItem:setLeftTime(leftTime)
	if leftTime <= 0 then
		self.labelLimit:SetActive(false)
		xyd.setTouchEnable(self.btnBuy, false)
		xyd.applyChildrenGrey(self.btnBuy)
	else
		self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", leftTime)
	end
end

return NewbeeLessonGiftbag
