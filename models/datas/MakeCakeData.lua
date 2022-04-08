local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local MakeCakeData = class("MakeCakeData", ActivityData, true)

function MakeCakeData:ctor(params)
	ActivityData.ctor(self, params)

	self.isShowRedPoint = self:initRedMarkState()
end

function MakeCakeData:getUpdateTime()
	return self:getEndTime()
end

function MakeCakeData:initRedMarkState()
	local val = xyd.db.misc:getValue("make_cake_caffe_flag")

	if val == nil or val == false then
		return true
	end

	local ids = xyd.tables.activityMakeCakeTable:getIDs()

	for ind = 1, #ids do
		local lock = true
		local id = tonumber(ids[ind])

		if tonumber(id) == 1 then
			lock = false
		else
			local times = self.detail["times_" .. id - 1]

			for j = 1, #times do
				if times[j] ~= 0 then
					lock = false
				end
			end
		end

		if lock == false then
			local useRed = true
			local max = 0

			for k = 1, 3 do
				local info = xyd.tables.activityMakeCakeTable:getAwardInfo(id, k)

				if info ~= nil then
					if max < info.cost[2] then
						max = info.cost[2]
					end

					if self.detail["times_" .. id][k] > 0 then
						useRed = false

						break
					end
				end
			end

			if useRed and max <= xyd.models.backpack:getItemNumByID(xyd.ItemID.MAKE_CAKE_THREE_COIN) then
				return true
			end
		end
	end

	return false
end

function MakeCakeData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return self.isShowRedPoint
end

function MakeCakeData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
end

function MakeCakeData:onItemChange(event)
	local items = event.data.items

	for _, itemInfo in ipairs(items) do
		if itemInfo.item_id == xyd.ItemID.MAKE_CAKE_THREE_COIN then
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.MAKE_CAKE, function ()
				self.isShowRedPoint = self:initRedMarkState()
			end)
		end
	end
end

function MakeCakeData:onAward(data)
	local real_data = json.decode(data.detail)
	local i = 1

	while i <= 5 do
		self.detail["times_" .. tostring(i)] = real_data["times_" .. tostring(i)]
		i = i + 1
	end

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.MAKE_CAKE, function ()
		self.isShowRedPoint = self:initRedMarkState()
	end)
end

return MakeCakeData
