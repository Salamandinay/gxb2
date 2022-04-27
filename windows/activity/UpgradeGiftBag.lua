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

function __TS__ArrayReverse(arr)
	local i = 0
	local j = #arr - 1

	while i < j do
		local temp = arr[j + 1]
		arr[j + 1] = arr[i + 1]
		arr[i + 1] = temp
		i = i + 1
		j = j - 1
	end

	return arr
end

local BaseGiftBag = import(".BaseGiftBag")
local UpgradeGiftBag = class("UpgradeGiftBag", BaseGiftBag)

function UpgradeGiftBag:ctor(params)
	BaseGiftBag.ctor(self, params)

	self.items_ = {}
	self.skinName = "UpgradeGiftBagSkin"
	self.currentState = xyd.Global.lang:toLowerCase()
end

function UpgradeGiftBag:euiComplete()
	BaseGiftBag.euiComplete(self)

	local rec = eui.Rect.new(true)
	rec.top = 0
	rec.bottom = 0
	rec.width = 696

	self:addChild(rec)

	self.imgBg0.mask = rec
	local model = DragonBones.new("huangzhong_lihui01", {
		scaleY = 0.98,
		scaleX = -0.98,
		callback = function ()
			model:play("texiao01", 0)

			model.x = 200
			model.y = 1400
		end
	})

	self.modelGroup:addChild(model)

	local activityData = self.activityData

	if xyd:getServerTime() <= activityData:getUpdateTime() then
		self.timeLabel:setCountDownTime(activityData:getUpdateTime() - xyd:getServerTime())
	else
		self.timeLabel.visible = false
		self.endLabel.visible = false
	end

	self.endLabel.text = __(_G, "END_TEXT")
	self.textImg.source = "upgrade_giftbag_text01_" .. tostring(xyd.Global.lang:toLowerCase()) .. "_png"

	xyd:setLabelFlow(self.labelText, __(_G, "UPGRADE_GIFTBAG_TEXT01"))

	self.vipLabel.text = "+" .. tostring(self.vip_) .. " VIP EXP"
	self.goBtn.labelDisplay.text = __(_G, "UPGRADE_GIFTBAG_TEXT02")

	self.goBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		local win = App.WindowManager:getWindow("activity_window")

		win:setCurrentActivity(61)
	end, self)
	self:updateStatus()
end

function UpgradeGiftBag:returnCommonScreen()
	BaseGiftBag.returnCommonScreen(self)

	local ____TS_obj = self.contentGroup
	local ____TS_index = "y"
	____TS_obj[____TS_index] = ____TS_obj[____TS_index] - 70
end

function UpgradeGiftBag:updateIcon()
	local awards = self:getAwards()
	local status = nil
	local limit = GiftBagTable:get():getBuyLimit(__TS__Number(ActivityTable:get():getGiftBag(self.id)))
	status = limit > self.activityData.detail.charges[0].buy_times
	local items = self.items_
	local itemGroup = self.itemGroup

	if #items == 0 then
		local i = 0
		local length = #awards

		while i < length do
			local item = awards[i + 1]
			local icon = xyd:getItemIcon({
				itemID = item[0],
				num = item[1]
			})

			if __TS__InstanceOf(icon, ItemIcon) then
				icon.lock = status
			else
				icon.bigLock = status
			end

			__TS__ArrayPush(items, icon)
			itemGroup:addChild(icon)

			icon.scaleX = 0.7407407407407407
			icon.scaleY = 0.7407407407407407
			i = i + 1
		end
	else
		local i = 0
		local length = #items

		while i < length do
			local item = items[i + 1]
			item.lock = status
			i = i + 1
		end
	end
end

function UpgradeGiftBag:updateStatus()
	if self.buy_limit_count_ <= self.activityData.detail.charges[0].buy_times then
		self.purchaseBtn.visible = false
		self.goBtn.visible = true
		local beachData = ActivityModel:get():getActivity(xyd.ActivityID.BEACH)

		if beachData.detail.advance_award_is_lock == 1 then
			beachData.detail.advance_award_is_lock = 0
		end
	else
		self.purchaseBtn.visible = true
		self.goBtn.visible = false
	end

	self:updateIcon()
end

function UpgradeGiftBag:getAwards()
	local ids = ActivityBeachAwardsTable:get():getIDs()
	local awards = {}
	local i = 0
	local length = ids.length

	while i < length do
		local id = ids[i]

		__TS__ArrayPush(awards, ActivityBeachAwardsTable:get():getAwards(id, 2))

		i = i + 1
	end

	__TS__ArrayReverse(awards)

	return awards
end

return UpgradeGiftBag
