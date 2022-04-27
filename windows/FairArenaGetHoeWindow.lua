local FairArenaGetHoeWindow = class("FairArenaGetHoeWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local CountDown = import("app.components.CountDown")

function FairArenaGetHoeWindow:ctor(name, params)
	FairArenaGetHoeWindow.super.ctor(self, name, params)
end

function FairArenaGetHoeWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function FairArenaGetHoeWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.centerIconBox = self.groupAction:ComponentByName("e:Image", typeof(UISprite)).gameObject
	self.btnSure = self.groupAction:NodeByName("btnSure").gameObject
	self.btnSureLabel = self.btnSure:ComponentByName("btnSureLabel", typeof(UILabel))
	self.btnSureIconGroup = self.btnSure:NodeByName("btnSureIconGroup").gameObject
	self.btnSureIcon = self.btnSureIconGroup:NodeByName("btnSureIcon").gameObject
	self.btnSureIcon_UISprite = self.btnSureIconGroup:ComponentByName("btnSureIcon", typeof(UISprite))
	self.btnSureIconNum = self.btnSureIconGroup:ComponentByName("btnSureIconNum", typeof(UILabel))
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.labelTitle = self.topGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.topGroup:NodeByName("closeBtn").gameObject
	self.helpBtn = self.topGroup:NodeByName("helpBtn").gameObject
	self.explainLabel = self.groupAction:ComponentByName("explainLabel", typeof(UILabel))
	self.buyTimesLabel = self.groupAction:ComponentByName("buyTimesLabel", typeof(UILabel))
	self.timeShowGroup = self.groupAction:NodeByName("timeShowGroup").gameObject
	self.timeExplainLabel = self.timeShowGroup:ComponentByName("timeExplainLabel", typeof(UILabel))
	self.timeExplainLabelTest = self.timeShowGroup:ComponentByName("timeExplainLabelTest", typeof(UILabel))
	self.timeGroup = self.timeShowGroup:NodeByName("timeGroup").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.timeClock = self.timeGroup:ComponentByName("timeClock", typeof(UITexture))
	self.topUp = self.window_:NodeByName("topUp").gameObject
end

function FairArenaGetHoeWindow:layout()
	self.explainLabel.text = __("FAIR_ARENA_GET_HOE_EXPLAIN")
	self.labelTitle.text = __("FAIR_ARENA_GET_HOE_TITLE")
	self.btnSureLabel.text = __("BUY2")
	local effect = xyd.Spine.new(self.timeClock.gameObject)

	effect:setInfo("fx_ui_shizhong", function ()
		effect:SetLocalScale(0.8, 0.8, 1)
		effect:play("texiao1", 0)
	end)
	self:updatePriceShow()
	self:updateTime()
	self:updateTimes()
	self:initTop()
end

function FairArenaGetHoeWindow:updatePriceShow()
	local buy_cost = self:getPrice()

	xyd.setUISpriteAsync(self.btnSureIcon_UISprite, nil, "icon_" .. buy_cost[1])

	self.btnSureIconNum.text = tostring(buy_cost[2])
end

function FairArenaGetHoeWindow:getPrice()
	local buy_cost = xyd.tables.miscTable:split2Cost("fair_arena_explore_chance_price", "value", "|#", true)
	local now_times = xyd.models.fairArena:getHoeBuyTimes()
	local need_times = now_times + 1

	if need_times > #buy_cost then
		need_times = #buy_cost
	end

	return buy_cost[need_times]
end

function FairArenaGetHoeWindow:updateTime()
	local free_get_arr = xyd.tables.miscTable:split2Cost("fair_arena_free", "value", "|#", true)
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FAIR_ARENA)
	local start_time = activityData:startTime()
	local count_time = activityData:getEndTime() - xyd.DAY_TIME
	local can_get = false

	for i, data in pairs(free_get_arr) do
		if start_time <= xyd.getServerTime() and xyd.getServerTime() < start_time + (data[1] - 1) * xyd.DAY_TIME then
			count_time = start_time + (data[1] - 1) * xyd.DAY_TIME
			can_get = true
			self.timeExplainLabel.text = __("FAIR_ARENA_GET_HOE_TIME_EXPLAIN", data[2])

			break
		end
	end

	local duration = count_time - xyd.getServerTime()

	if duration > 0 then
		if self.timeCount then
			self.timeCount:dispose()
		end

		self.timeCount = CountDown.new(self.timeLabel)

		self.timeCount:setInfo({
			duration = duration,
			callback = function ()
				self:waitForTime(2, handler(self, self.updateTime))
			end
		})
	else
		self:timeOver()
	end

	if not can_get then
		self.timeExplainLabel.text = __("FAIR_ARENA_GET_HOE_TIME_END")
	end

	self:updateTimes()

	self.timeExplainLabelTest.text = self.timeExplainLabel.text

	if xyd.Global.lang == "ja_jp" then
		self.timeExplainLabel.fontSize = 20
		self.timeExplainLabelTest.fontSize = 20
	end

	if xyd.Global.lang == "fr_fr" then
		self.timeExplainLabel.fontSize = 22
		self.timeExplainLabelTest.fontSize = 22
	end

	local time_width = self.timeLabel.width + 40 + 10
	local all_width = self.timeExplainLabelTest.width + time_width + 5

	self.timeExplainLabel.gameObject:X(-all_width / 2 + 5)
	self.timeGroup.gameObject:X(-all_width / 2 + 5 + self.timeExplainLabelTest.width + 5 + time_width / 2)
end

function FairArenaGetHoeWindow:timeOver()
	self.timeLabel.text = "00:00:00"
end

function FairArenaGetHoeWindow:updateTimes()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FAIR_ARENA)
	local every_day_can_buy_times = xyd.tables.miscTable:getNumber("fair_arena_buy_time", "value")
	local allCanBuyTimes = math.ceil((xyd.getServerTime() - activityData:startTime()) / xyd.DAY_TIME) * every_day_can_buy_times
	local yet_buy_tims = allCanBuyTimes - xyd.models.fairArena:getHoeBuyTimes()

	if yet_buy_tims < 0 then
		yet_buy_tims = 0
	end

	self.yet_buy_tims = yet_buy_tims
	self.buyTimesLabel.text = __("FAIR_ARENA_GET_HOE_BUY_TIMES_YET") .. yet_buy_tims
end

function FairArenaGetHoeWindow:initTop()
	self.windowTop = WindowTop.new(self.topUp, self.name_, 10, false)
	local cost_id = tonumber(xyd.tables.miscTable:split2num("fair_arena_ticket_item", "value", "#")[1])
	local items = {
		{
			hidePlus = true,
			id = cost_id
		},
		{
			id = xyd.ItemID.CRYSTAL
		}
	}

	self.windowTop:hideBg()
	self.windowTop:addTopBox()
	self.windowTop:setItem(items)
end

function FairArenaGetHoeWindow:registerEvent()
	UIEventListener.Get(self.btnSure.gameObject).onClick = handler(self, function ()
		if self.yet_buy_tims <= 0 then
			xyd.alertTips(__("FAIR_ARENA_GET_HOE_SHOW_TIMES_NONE"))

			return
		end

		local function buyFun()
			local cost_arr = self:getPrice()

			if cost_arr[2] <= xyd.models.backpack:getItemNumByID(cost_arr[1]) then
				xyd.models.fairArena:reqExplore(xyd.FairArenaType.BUY_HOE)
			else
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost_arr[1])))
			end
		end

		local timeStamp = xyd.db.misc:getValue("fair_arena_get_hoe_time_stamp")
		timeStamp = timeStamp and tonumber(timeStamp)
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FAIR_ARENA)

		if not timeStamp or timeStamp < activityData:startTime() or activityData:getEndTime() < timeStamp then
			local params = {
				type = "fair_arena_get_hoe",
				text = __("FAIR_ARENA_GET_HOE_BUY_TIPS", self:getPrice()[2]),
				callback = function ()
					buyFun()
				end,
				labelNeverText = __("FAIR_ARENA_OPEN_BACK_PACK_TIPS2")
			}

			if xyd.Global.lang ~= "zh_tw" then
				params.tipsTextY = 55.5
				params.tipsHeight = 124
			end

			xyd.openWindow("gamble_tips_window", params)
		else
			buyFun()
		end
	end)
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "FAIR_ARENA_GET_HOE_BUY_HELP"
		})
	end)
	UIEventListener.Get(self.centerIconBox.gameObject).onClick = handler(self, function ()
		local cost_id = tonumber(xyd.tables.miscTable:split2num("fair_arena_ticket_item", "value", "#")[1])
		local params = {
			show_has_num = true,
			itemID = cost_id,
			wndType = xyd.ItemTipsWndType.BACKPACK
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end)

	self.eventProxy_:addEventListener(xyd.event.FAIR_ARENA_EXPLORE, handler(self, self.onExplore))
end

function FairArenaGetHoeWindow:onExplore(event)
	local data = event.data

	if data.operate == xyd.FairArenaType.BUY_HOE then
		self:updateTimes()
		self:updatePriceShow()
	end
end

return FairArenaGetHoeWindow
