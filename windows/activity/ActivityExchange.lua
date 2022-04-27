local ActivityContent = import(".ActivityContent")
local ActivityExchange = class("ActivityExchange", ActivityContent)
local ActivityExchangeItem = class("ActivityExchangeItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")

function ActivityExchange:ctor(parentGO, params, parent)
	ActivityExchange.super.ctor(self, parentGO, params, parent)

	self.boughtId = nil
	self.boughtNum = nil

	if not xyd.db.misc:getValue("activity_exchange_first") then
		xyd.db.misc:setValue({
			value = 1,
			key = "activity_exchange_first"
		})
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_EXCHANGE, function ()
		end)
	end
end

function ActivityExchange:getPrefabPath()
	return "Prefabs/Windows/activity/activity_exchange"
end

function ActivityExchange:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)
	self:initUIComponent()
	self:initData(true)
end

function ActivityExchange:resizeToParent()
	ActivityExchange.super.resizeToParent(self)
	self.go:Y(-5)
end

function ActivityExchange:getUIComponent()
	local go = self.go
	self.imgText_ = go:ComponentByName("imgText_", typeof(UISprite))
	self.desLabel_ = go:ComponentByName("desLabel_", typeof(UILabel))
	self.labelTime = go:ComponentByName("timeGroup/timeLabel_", typeof(UILabel))
	self.labelEnd = go:ComponentByName("timeGroup/endLabel_", typeof(UILabel))
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	local contentGroup = go:NodeByName("contentGroup").gameObject
	self.bg_ = contentGroup:ComponentByName("bg_", typeof(UISprite))
	self.scrollView = contentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = contentGroup:NodeByName("scroller/itemGroup").gameObject
	self.scrollerItem = contentGroup:NodeByName("activity_exchange_item").gameObject
end

function ActivityExchange:initUIComponent()
	xyd.setUISpriteAsync(self.imgText_, nil, "activity_exchange_" .. tostring(xyd.Global.lang))

	self.labelEnd.text = __("TEXT_END")
	self.desLabel_.text = __("ACITVITY_EXCHANGE_TEXT")

	if xyd.Global.lang == "de_de" then
		self.labelEnd.width = 100

		self.labelEnd:X(44)
		self.labelEnd:Y(-1)
		self.labelTime:X(-8)
	elseif xyd.Global.lang == "fr_fr" then
		self.desLabel_.fontSize = 22

		self.desLabel_:X(30)
	end

	local duration = self.activityData:getEndTime() - xyd.getServerTime()

	if duration < 0 then
		self.labelEnd:SetActive(false)
		self.labelTime:SetActive(false)
	else
		local timeCount = CountDown.new(self.labelTime)

		timeCount:setInfo({
			duration = duration
		})
	end
end

function ActivityExchange:initData()
	self.data = {}
	local ids = xyd.tables.activityExchangeAwardTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local limit = xyd.tables.activityExchangeAwardTable:getLimit(id)
		local buyTimes = self.activityData.detail.buy_times[id]
		local isCompleted = limit <= buyTimes

		table.insert(self.data, {
			id = tonumber(id),
			limit = limit,
			awards = xyd.tables.activityExchangeAwardTable:getAwards(id),
			cost = xyd.tables.activityExchangeAwardTable:getCost(id),
			buyTimes = buyTimes,
			isCompleted = isCompleted,
			parentClass = self
		})
	end

	local function sort_func(a, b)
		if a.isCompleted == b.isCompleted then
			return a.id < b.id
		elseif a.isCompleted then
			return false
		else
			return true
		end
	end

	table.sort(self.data, sort_func)

	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.scrollerItem, ActivityExchangeItem, self)

	self.wrapContent:setInfos(self.data)
end

function ActivityExchange:updateData()
	for i = 1, #self.data do
		local id = self.data[i].id
		local limit = self.data[i].limit
		local buyTimes = self.activityData.detail.buy_times[id]
		local isCompleted = limit <= buyTimes
		self.data[i].buyTimes = buyTimes
		self.data[i].isCompleted = isCompleted
	end

	self.wrapContent:setInfos(self.data, {
		keepPosition = true
	})
end

function ActivityExchange:onRegister()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SUMMON_GIFTBAG_HELP"
		})
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.WINDOW_WILL_CLOSE, handler(self, self.onWndClose))
end

function ActivityExchange:onWndClose(event)
	local windowName = event.params.windowName

	if windowName ~= "alert_window" then
		self:updateData()
	end
end

function ActivityExchange:onAward(event)
	if self.boughtId and self.boughtNum then
		local item = xyd.tables.activityExchangeAwardTable:getAwards(self.boughtId)
		local type = xyd.tables.itemTable:getType(item[1])

		if type == xyd.ItemType.SKIN then
			xyd.onGetNewPartnersOrSkins({
				destory_res = false,
				skins = {
					tonumber(item[1])
				}
			})
		else
			xyd.models.itemFloatModel:pushNewItems({
				{
					item_id = item[1],
					item_num = item[2] * self.boughtNum
				}
			})
		end

		self.activityData.detail.buy_times[self.boughtId] = self.activityData.detail.buy_times[self.boughtId] + self.boughtNum

		self:updateData()

		self.boughtId = nil
		self.boughtNum = nil
	end
end

function ActivityExchangeItem:ctor(go, parent)
	ActivityExchangeItem.super.ctor(self, go, parent)
end

function ActivityExchangeItem:initUI()
	local go = self.go
	self.btn = go:NodeByName("exchangeBtn").gameObject
	self.btnLabel = self.btn:ComponentByName("label", typeof(UILabel))
	self.limitLabel = go:ComponentByName("limitLabel", typeof(UILabel))
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.icon1 = self.itemGroup:NodeByName("icon1").gameObject
	self.icon2 = self.itemGroup:NodeByName("icon2").gameObject
	self.icon3 = self.itemGroup:NodeByName("icon3").gameObject
	self.label1 = self.itemGroup:ComponentByName("label1", typeof(UILabel))
	self.label2 = self.itemGroup:ComponentByName("label2", typeof(UILabel))
end

function ActivityExchangeItem:registerEvent()
	UIEventListener.Get(self.btn).onClick = function ()
		local enough1 = self.cost[1][2] <= xyd.models.backpack:getItemNumByID(self.cost[1][1])
		local enough2 = self.cost[2][2] <= xyd.models.backpack:getItemNumByID(self.cost[2][1])

		if not enough1 then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.cost[1][1])))

			return
		elseif not enough2 then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.cost[2][1])))

			return
		end

		local params = {
			notShowNum = true,
			notEnoughKey = "MID_AUTUMN_ACTIVITY_EXCHANGE_NOT_ENOUGH",
			hasMaxMin = true,
			titleKey = "MID_AUTUMN_ACTIVITY_EXCHANGE_TITLE",
			buyType = self.awards[1],
			buyNum = self.awards[2]
		}

		function params.purchaseCallback(_, num)
			if self.parentClass then
				local msg = messages_pb.get_activity_award_req()
				local data = require("cjson").encode({
					award_id = self.id,
					num = num
				})
				self.parentClass.boughtId = self.id
				self.parentClass.boughtNum = num
				msg.activity_id = xyd.ActivityID.ACTIVITY_EXCHANGE
				msg.params = data

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
			end
		end

		params.limitNum = self.limit - self.buyTimes
		params.eventType = xyd.event.GET_ACTIVITY_AWARD
		params.maxCanBuy = math.min(math.floor(xyd.models.backpack:getItemNumByID(self.cost[1][1]) / self.cost[1][2]), math.floor(xyd.models.backpack:getItemNumByID(self.cost[2][1]) / self.cost[2][2]))

		function params.calPriceCallback(num)
		end

		xyd.WindowManager.get():openWindow("limit_purchase_item_window", params)
	end
end

function ActivityExchangeItem:updateInfo()
	self.id = self.data.id
	self.limit = self.data.limit
	self.buyTimes = self.data.buyTimes
	self.cost = self.data.cost
	self.awards = self.data.awards
	self.isCompleted = self.data.isCompleted
	self.parentClass = self.data.parentClass
	self.limitLabel.text = __("LEFT_TIMES", self.limit - self.buyTimes)
	self.btnLabel.text = __("EXCHANGE2")

	xyd.setEnabled(self.btn, not self.isCompleted)

	for i = 1, 3 do
		NGUITools.DestroyChildren(self["icon" .. i].transform)

		local item = i ~= 3 and self.cost[i] or self.awards
		local icon = xyd.getItemIcon({
			show_has_num = true,
			uiRoot = self["icon" .. i],
			itemID = item[1],
			num = item[2],
			dragScrollView = self.parent.scrollView,
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			scale = i ~= 3 and Vector3(0.65, 0.65, 1) or Vector3(0.91, 0.91, 1),
			isNew = item[1] == 7173 and true or false
		})
		local label = self["label" .. i]

		if label then
			local num1 = tonumber(xyd.models.backpack:getItemNumByID(item[1]))
			local num2 = tonumber(item[2])
			label.text = xyd.getRoughDisplayNumber(num1) .. "/" .. xyd.getRoughDisplayNumber(num2)

			if num1 < num2 then
				label.color = Color.New2(4127195391.0)
			else
				label.color = Color.New2(3414179839.0)
			end
		end
	end
end

return ActivityExchange
