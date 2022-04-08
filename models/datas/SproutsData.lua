local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local SproutsData = class("SproutsData", ActivityData, true)

function SproutsData:getUpdateTime()
	return self:getEndTime()
end

function SproutsData:onAward(data)
	self.detail_ = json.decode(data.detail).info
end

function SproutsData:getRedMarkState1()
	if not self:isFunctionOnOpen() then
		return false
	end

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.SPROUTS_ITEM) > 0 then
		return true
	end
end

function SproutsData:getRedMarkState2()
	if not self:isFunctionOnOpen() then
		return false
	end

	local flag1 = false
	local HeightAwardTable = xyd.tables.activitySproutsHeightAwardTable
	local Ids = HeightAwardTable:getIDs()
	local height = self.detail_.height or -1
	local awards = self.detail_.awards

	for i = 1, #Ids do
		local height_ = HeightAwardTable:getHeight(i) or 0

		if height >= height_ and awards[i] and awards[i] == 0 then
			flag1 = true

			break
		end
	end

	return flag1
end

function SproutsData:getRedMarkState3()
	if not self:isFunctionOnOpen() then
		return false
	end

	local flag2 = false
	local PartnerAwardTable = xyd.tables.activitySproutsPartnerAwardTable
	local Ids = PartnerAwardTable:getIDs()
	local pr_times = self.detail_.pr_times or 0
	local pr_awards = self.detail_.pr_awards

	for i = 1, #Ids do
		if PartnerAwardTable:getPoint(i) <= pr_times and pr_awards[i] == 0 then
			flag2 = true

			break
		end
	end

	return flag2
end

function SproutsData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return self:getRedMarkState1() or self:getRedMarkState2() or self:getRedMarkState3()
end

return SproutsData
