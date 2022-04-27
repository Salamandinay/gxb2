local ActivityWorldBossSweepWindow = import("app.windows.ActivityWorldBossSweepWindow")
local ActivityAllStarsPrayMaterialWindow = class("ActivityWorldBossSweepWindow", ActivityWorldBossSweepWindow)

function ActivityAllStarsPrayMaterialWindow:ctor(name, params)
	ActivityAllStarsPrayMaterialWindow.super.ctor(self, name, params)

	self.selectGroup = params.selectGroup
	self.backpack = xyd.models.backpack
	self.exchangeID = params.exchangeID or 1
	self.activityData = params.activityData
	self.activityId = params.activityId
end

function ActivityAllStarsPrayMaterialWindow:initWindow()
	ActivityAllStarsPrayMaterialWindow.super.initWindow(self)
end

function ActivityAllStarsPrayMaterialWindow:layout()
	xyd.setUISpriteAsync(self.iconImg_, nil, xyd.tables.itemTable:getIcon(111), nil, )

	self.iconImg_:GetComponent(typeof(UIWidget)).width = 45
	self.iconImg_:GetComponent(typeof(UIWidget)).height = 45
	self.labelWinTitle_.text = __("ACTIVITY_PRAY_COMMIT_TEXT01")
	self.btnSureLabel_.text = __("CONFIRM")
	self.labelTips_.text = __("ACTIVITY_PRAY_COMMIT_TEXT02")
	self.labelTips_.color = Color.New2(1549556991)
	self.selectNum_ = import("app.components.SelectNum").new(self.selectNumPos_, "default")

	self.addbtn:SetActive(true)
	self:initTextInput()
	self.selectNum_:setKeyboardPos(0, -380)
end

function ActivityAllStarsPrayMaterialWindow:register()
	ActivityAllStarsPrayMaterialWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.ITEM_EXCHANGE, handler(self, self.onExchangeItem))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.updateItemNumber))
	self.eventProxy_:addEventListener(xyd.event.ALL_STAR_PRAY_BUY, function ()
		xyd.WindowManager.get():closeWindow("limit_purchase_item_window")
	end)
	self.eventProxy_:addEventListener(xyd.event.USE_PRAY_ITEM, function (event)
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function ActivityAllStarsPrayMaterialWindow:initTextInput()
	local max = tonumber(xyd.models.backpack:getItemNumByID(tonumber(xyd.tables.miscTable:getVal("activity_pray_cost"))))
	self.selectNum_.inputLabel.text = "1"

	local function callback(num)
		if num > 99 then
			self.curNum_ = 99
		elseif max < num then
			self.curNum_ = max
		else
			self.curNum_ = num
		end

		self.selectNum_.inputLabel.text = tostring(self.curNum_)

		self.selectNum_:setCurNum(self.curNum_)

		self.labelTili_.text = tostring(max)
	end

	self.selectNum_:setInfo({
		clearNotCallback = true,
		maxNum = 99,
		minNum = 1,
		notCallback = true,
		curNum = 1,
		callback = callback,
		maxCallback = function ()
			if max >= 90 then
				-- Nothing
			end
		end
	})

	self.labelTili_.text = tostring(max)
end

function ActivityAllStarsPrayMaterialWindow:sureTouch()
	local msg = messages_pb.use_pray_item_req()
	msg.activity_id = xyd.ActivityID.ALL_STARS_PRAY
	msg.bench_id = self.selectGroup
	msg.num = self.curNum_

	xyd.Backend.get():request(xyd.mid.USE_PRAY_ITEM, msg)
end

function ActivityAllStarsPrayMaterialWindow:checkCanFight()
	return true
end

function ActivityAllStarsPrayMaterialWindow:addTouch()
	if self:getBuyTime() <= 0 then
		xyd:showToast(__(_G, "ACTIVITY_WORLD_BOSS_LIMIT"))

		return
	end

	local data = {
		{},
		{}
	}
	local list1 = xyd.split(xyd.tables.miscTable:getString("activity_pray_buy_price", "value"), "|")
	local list2 = {}

	for i in ipairs(list1) do
		local t = xyd.split(list1[i], "-")

		for k, j in pairs(t) do
			table.insert(data[i], xyd.split(j, "#"))
		end
	end

	xyd.WindowManager.get():openWindow("limit_purchase_item_window", {
		limitKey = "ACTIVITY_WORLD_BOSS_LIMIT",
		notEnoughKey = "PERSON_NO_CRYSTAL",
		needTips = true,
		titleKey = "ACTIVITY_PRAY_BUY",
		buyType = tonumber(data[1][2][1]),
		buyNum = tonumber(data[1][2][2]),
		costType = tonumber(data[1][1][1]),
		costNum = tonumber(data[1][1][2]),
		purchaseCallback = function (evt, num)
			local msg = messages_pb.all_star_pray_buy_req()
			msg.activity_id = xyd.ActivityID.ALL_STARS_PRAY
			msg.num = num
			msg.type = 1

			xyd.Backend.get():request(xyd.mid.ALL_STAR_PRAY_BUY, msg)

			if xyd.models.backpack:getItemNumByID(tonumber(data[1][1][1])) < tonumber(data[1][1][2]) then
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(data[1])))

				return
			end

			xyd.itemFloat({
				{
					item_id = tonumber(data[1][2][1]),
					item_num = tonumber(data[1][2][2]) * num
				}
			}, nil, , 6002)
		end,
		limitNum = tonumber(self:getBuyTime()),
		eventType = xyd.event.BOSS_BUY,
		showWindowCallback = function ()
			xyd.WindowManager.get():openWindow("vip_window")
		end
	})
end

function ActivityAllStarsPrayMaterialWindow:getBuyTime()
	return tonumber(xyd.tables.miscTable:split2Cost("activity_pray_buy_limit", "value", "|")[1]) - self.activityData.detail.buy_times
end

function ActivityAllStarsPrayMaterialWindow:exchangeItemRequest()
	xyd.Backend:get():request(xyd.mid.USE_PRAY_ITEM, {
		activity_id = xyd.ActivityID.ALL_STARS_PRAY,
		bench_id = self.selectGroup,
		num = self.purchaseNum
	})
end

function ActivityAllStarsPrayMaterialWindow:onExchangeItem(event)
	if event.data.id then
		xyd.WindowManager.get():closeWindow(self.name_)
		xyd.WindowManager.get():openWindow("alert_window", {
			alertType = xyd.AlertType.TIPS,
			message = __("PURCHASE_SUCCESS")
		})
	end
end

function ActivityAllStarsPrayMaterialWindow:updateItemNumber()
	self.labelTili_.text = tostring(xyd.models.backpack:getItemNumByID(tonumber(xyd.tables.miscTable:getVal("activity_pray_cost"))))
end

return ActivityAllStarsPrayMaterialWindow
