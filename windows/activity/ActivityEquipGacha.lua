local ____symbolMetatable = {}

function ____symbolMetatable:__tostring()
	if self.description == nil then
		return "Symbol()"
	else
		return "Symbol(" .. tostring(self.description) .. ")"
	end
end

function __TS__Symbol(description)
	return setmetatable({
		description = description
	}, ____symbolMetatable)
end

Symbol = {
	iterator = __TS__Symbol("Symbol.iterator"),
	hasInstance = __TS__Symbol("Symbol.hasInstance")
}

function __TS__InstanceOf(obj, classTbl)
	if (type(classTbl) == "table" and "object" or type(classTbl)) ~= "object" then
		error("Right-hand side of 'instanceof' is not an object")
	end

	if classTbl[Symbol.hasInstance] ~= nil then
		return not not classTbl[Symbol.hasInstance](classTbl, obj)
	end

	if obj ~= nil then
		local luaClass = obj.constructor

		while luaClass ~= nil do
			if luaClass == classTbl then
				return true
			end

			luaClass = luaClass.____super
		end
	end

	return false
end

function __TS__ArrayIndexOf(arr, searchElement, fromIndex)
	local len = #arr

	if len == 0 then
		return -1
	end

	local n = 0

	if fromIndex then
		n = fromIndex
	end

	if len <= n then
		return -1
	end

	local k = nil

	if n >= 0 then
		k = n
	else
		k = len + n

		if k < 0 then
			k = 0
		end
	end

	local i = k

	while i < len do
		if arr[i + 1] == searchElement then
			return i
		end

		i = i + 1
	end

	return -1
end

function __TS__Iterator(iterable)
	if iterable[Symbol.iterator] then
		local iterator = iterable[Symbol.iterator](iterable)

		return function ()
			local result = iterator:next()

			if not result.done then
				return result.value
			else
				return nil
			end
		end
	else
		local i = 0

		return function ()
			i = i + 1

			return iterable[i]
		end
	end
end

function __TS__Number(value)
	local valueType = type(value)

	if valueType == "number" then
		return value
	elseif valueType == "string" then
		local numberValue = tonumber(value)

		if numberValue then
			return numberValue
		end

		if value == "Infinity" then
			return math.huge
		end

		if value == "-Infinity" then
			return -math.huge
		end

		local stringWithoutSpaces = string.gsub(value, "%s", "")

		if stringWithoutSpaces == "" then
			return 0
		end

		return 0 / 0
	elseif valueType == "boolean" then
		return value and 1 or 0
	else
		return 0 / 0
	end
end

function __TS__ArrayPush(arr, ...)
	local items = {
		...
	}

	for ____TS_index = 1, #items do
		local item = items[____TS_index]
		arr[#arr + 1] = item
	end

	return #arr
end

local ActivityContent = import(".ActivityContent")
local ActivityEquipGacha = class("ActivityEquipGacha", ActivityContent)

function ActivityEquipGacha:ctor(params)
	ActivityContent.ctor(self, params)

	self.cost_type = 54
	self.currentState = xyd.Global.lang
	self.skinName = "ActivityEquipGachaSkin"
end

function ActivityEquipGacha:euiComplete()
	ActivityContent.euiComplete(self)
	self:initAddGroup()
	self:initHelp()
	self:registerEvent()
	self:updateItems()
	self:updateProgress()
	self:layout()
end

function ActivityEquipGacha:layout()
	self.horizontalCenter = 0
	self.top = function (o, i, v)
		o[i] = v

		return v
	end(self, "bottom", 0)
	self.labelTips1.text = __(_G, "EQUIP_GACHA_TIPS1")
	self.sumTextLabel.text = __(_G, "ACTIVITY_JIGSAW_TOTAL")
	self.endLabel.text = __(_G, "END_TEXT")
	local cost = MiscTable:get():split2Cost("activity_equip_gacha_cost_all", "value", "|#")
	local cost1 = cost[0]
	local cost10 = cost[1]
	self.btnSummonOne.labelItemCost.text = cost1[1]
	self.btnSummonTen.labelItemCost.text = cost10[1]
	self.btnSummonOne.labelItemDisplay.text = __(_G, "EQUIP_GACHA_TIPS4")
	self.btnSummonTen.labelItemDisplay.text = __(_G, "EQUIP_GACHA_TIPS5")

	if xyd:getServerTime() < self.activityData:getUpdateTime() then
		self.timeLabel:setCountDownTime(self.activityData:getUpdateTime() - xyd:getServerTime())
	else
		self.timeLabel.visible = false
		self.endLabel.visible = false
	end
end

function ActivityEquipGacha:updateItems()
	local items = xyd:split(MiscTable:get():getVal("activity_equip_gacha_appoint"), "|", true)

	self.groupItems:removeChildren()

	local equips = self.activityData.detail.equips or {}
	local hasGetAll = true

	for id in __TS__Iterator(items) do
		local icon = xyd:getItemIcon({
			itemID = id
		})

		self.groupItems:addChild(icon)

		icon.scale = 70 / xyd.DEFAULT_ITEM_SIZE

		if __TS__InstanceOf(equips, Array) and __TS__ArrayIndexOf(equips, id) > -1 then
			icon.choose = true
		else
			hasGetAll = false
		end
	end

	local curTimes = self.activityData.detail.cur_times or 0
	local baodi = __TS__Number(MiscTable:get():getVal("activity_equip_gacha_insure_time"))

	if hasGetAll then
		self.labelTips2.text = __(_G, "EQUIP_GACHA_TIPS6")
	else
		xyd:setLabelFlow(self.labelTips2, __(_G, "EQUIP_GACHA_TIPS2", baodi - curTimes))
	end
end

function ActivityEquipGacha:updateProgress()
	local ids = ActivityEquipGachaTable:get():getIDs()
	local awards = self.activityData.detail.awarded or {}
	local curNum = 0
	local curPoint = self.activityData.detail.point or 0
	local pointFlag = true
	local lastPoint = 0
	local i = 0

	while i < ids.length do
		local id = ids[i]
		local point = ActivityEquipGachaTable:get():getPoint(id)
		local lab = self["boxLabel" .. tostring(id)]
		local img = self["boxImg" .. tostring(id)]
		lab.text = String(_G, point)

		if awards[i] == 1 then
			if id <= 2 then
				img.source = "activity_jigsaw_icon01_1_png"
			elseif id <= 4 then
				img.source = "activity_jigsaw_icon02_1_png"
			else
				img.source = "activity_jigsaw_open_icon_png"
			end
		elseif id <= 2 then
			img.source = "activity_jigsaw_icon01_0_png"
		elseif id <= 4 then
			img.source = "activity_jigsaw_icon02_0_png"
		else
			img.source = "trial_icon04_png"
		end

		if point <= curPoint then
			curNum = curNum + 20
		elseif pointFlag then
			local tmpPoint = curPoint - lastPoint
			local pointQuality = 20 / (point - lastPoint)
			curNum = curNum + tmpPoint * pointQuality
			pointFlag = false
		end

		lastPoint = point
		i = i + 1
	end

	self.progress.maximum = 100
	self.progress.value = curNum
	self.labelPoint.text = curPoint
	self.groupPoint.x = 79 + 510 * curNum / 100
end

function ActivityEquipGacha:registerEvent()
	self.btnAwards:addEventListener(egret.TouchEvent.TOUCH_TAP, self.onTouchAward, self)
	self.btnSummonOne:addEventListener(egret.TouchEvent.TOUCH_TAP, self.onOneTouch, self)
	self.btnSummonTen:addEventListener(egret.TouchEvent.TOUCH_TAP, self.onTenTouch, self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, self.onGetAward, self)
	self.eventProxy_:addEventListener(xyd.event.BOSS_BUY, self.onBossBuy, self)

	local i = 1

	while i <= 5 do
		local img = self["boxImg" .. tostring(i)]
		local awards = ActivityEquipGachaTable:get():getAwards(i)

		img:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
			App.WindowManager:openWindow("activity_award_preview_window", {
				awards = awards
			})
		end, self)

		i = i + 1
	end
end

function ActivityEquipGacha:onBossBuy(event)
	self.activityData.detail.buy_times = event.data.buy_times or 0
end

function ActivityEquipGacha:onGetAward(event)
	local detail = JSON:parse(event.data.detail)
	local items = detail.items
	local tmpItems = {}
	local appointItems = xyd:split(MiscTable:get():getVal("activity_equip_gacha_appoint"), "|", true)

	for item in __TS__Iterator(items) do
		local isCool = appointItems:indexOf(item[0]) > -1 and 1 or 0

		__TS__ArrayPush(tmpItems, {
			item_id = item[0],
			item_num = item[1],
			cool = isCool
		})
	end

	local params = {
		data = tmpItems,
		wnd_type = GambleRewardsWindow.WindowType.EQUIP_GACHA,
		callback = function ()
			if self.stage then
				self:updateItems()
			end
		end
	}

	App.WindowManager:openWindow("gamble_rewards_window", params)
	self:updateProgress()
end

function ActivityEquipGacha:onOneTouch()
	ActivityModel:get():equipGacha(1)
end

function ActivityEquipGacha:onTenTouch()
	ActivityModel:get():equipGacha(2)
end

function ActivityEquipGacha:getCanBuyTimes()
	local total = MiscTable:get():getVal("activity_equip_gacha_buy_limit")
	local hasBuy = self.activityData.detail.buy_times

	return __TS__Number(total) - hasBuy
end

function ActivityEquipGacha:initAddGroup()
	self:updateItemNumber()
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, self.updateItemNumber, self)
	self.addBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		local params = {
			showGetWays = true,
			itemID = self.cost_type,
			wndType = xyd.ItemTipsWndType.BACKPACK,
			ways_val = self.activityData.detail.tasks or 0
		}

		App.WindowManager:openWindow("item_tips_window", params)
	end, self)
end

function ActivityEquipGacha:updateItemNumber()
	self.numberLabel.text = String(_G, Backpack:get():getItemNumByID(self.cost_type))
end

function ActivityEquipGacha:onTouchAward(evt)
	xyd.WindowManager:get():openWindow("activity_equi_gacha_awards")
end

function ActivityEquipGacha:initHelp()
	self.helpBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		local tasks = self.activityData.detail.tasks
		local str = __(_G, "EQUIP_GACHA_HELP", tasks[0], tasks[1], tasks[2], self.activityData.detail.buy_times)
		local str_list = xyd:split(str, "|")
		local params = {
			str_list = str_list
		}

		App.WindowManager:openWindow("help_window", params)
	end, self)
end

local BaseWindow = import(".BaseWindow")
local ActivityEquiGachaAwards = class("ActivityEquiGachaAwards", BaseWindow)

function ActivityEquiGachaAwards:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "ActivityEquiGachaAwardsSkin"
end

function ActivityEquiGachaAwards:initWindow()
	BaseWindow.initWindow(self)
	self:layout()
end

function ActivityEquiGachaAwards:layout()
	self.labelTitle_.text = __(_G, "EQUIP_GACHA_TIPS3")
	local items = xyd:split(MiscTable:get():getVal("activity_equip_gacha_list"), "|", true)
	local i = 0

	while i < items.length do
		local icon = xyd:getItemIcon({
			itemID = items[i]
		})

		self.groupMain_:addChild(icon)

		i = i + 1
	end
end

return ActivityEquipGacha
