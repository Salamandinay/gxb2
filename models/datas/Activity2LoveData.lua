local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local Activity2LoveData = class("Activity2LoveData", ActivityData, true)
local resItemID = 427

function Activity2LoveData:ctor(params)
	ActivityData.ctor(self, params)

	self.resItemNum = xyd.models.backpack:getItemNumByID(resItemID)
end

function Activity2LoveData:getUpdateTime()
	return self:getEndTime()
end

function Activity2LoveData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxyOuter_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
end

function Activity2LoveData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_2LOVE then
		return
	end

	local data_ = xyd.decodeProtoBuf(data)

	if data_.detail then
		local info = require("cjson").decode(data_.detail)
		self.detail_ = info

		self:getRedMarkState()
	end
end

function Activity2LoveData:onItemChange(event)
	local items = event.data.items

	for i = 1, #items do
		if items[i].item_id == resItemID then
			if self.resItemNum < xyd.models.backpack:getItemNumByID(resItemID) then
				xyd.models.itemFloatModel:pushNewItems({
					{
						item_id = resItemID,
						item_num = xyd.models.backpack:getItemNumByID(resItemID) - self.resItemNum
					}
				})
			end

			self.resItemNum = xyd.models.backpack:getItemNumByID(resItemID)
		end

		if items[i].item_id == xyd.ItemID.VIP_EXP then
			xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_2LOVE)
		end
	end

	self:updateRedMark()
end

function Activity2LoveData:updateRedMark()
	self.holdRed = true

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_2LOVE, function ()
		self.holdRed = false
	end)
end

function Activity2LoveData:getRedMarkState()
	if not self.detail_ then
		return false
	end

	local isOver = true
	local idsData = self.detail_.ids

	for index, id in ipairs(idsData) do
		if id == 0 or not id then
			isOver = false
		end
	end

	local redState = false

	if self.resItemNum >= 1 then
		redState = true
	end

	if self.detail_.free_count == 0 then
		redState = true
	end

	if self.detail_.is_cost == 1 then
		redState = true
	end

	if isOver then
		redState = false
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_2LOVE, redState)

	return redState
end

return Activity2LoveData
