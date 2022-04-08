local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local CandyCollectData = class("CandyCollectData", ActivityData, true)

function CandyCollectData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function CandyCollectData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local flag = false
	local awarded = self.detail.awarded
	local selfNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.LOVE_LETTER2)
	local listLength = {}

	for i = 1, #awarded do
		local splitStr = xyd.split(awarded[i], "#")

		if #splitStr == 1 then
			if tonumber(splitStr[1]) == 0 then
				listLength[i] = 0
			else
				listLength[i] = #splitStr
			end
		else
			listLength[i] = #splitStr
		end
	end

	local max = listLength[1]

	for i = 2, #listLength do
		if max < listLength[i] then
			max = listLength[i]
		end
	end

	for i = 1, 5 do
		local award = awarded[i]
		local awardSplit = xyd.split(award, "#")
		flag = false

		for j = 1, 4 do
			local skip = false

			for k = 1, #awardSplit do
				if tonumber(awardSplit[k]) == j then
					skip = true

					break
				end
			end

			if not skip then
				local cost = xyd.tables.activityCandyCollectTable:getCost(i, j)

				if cost[2] <= selfNum then
					flag = true

					break
				end
			end
		end

		if flag then
			if #awardSplit == 1 then
				if tonumber(awardSplit[1]) == 0 then
					flag = true
				elseif max <= #awardSplit then
					flag = false
				end
			elseif max <= #awardSplit then
				flag = false
			end

			local isAllEquil = true

			for i = 1, #listLength - 1 do
				if listLength[i] ~= listLength[i + 1] then
					isAllEquil = false
				end
			end

			if isAllEquil then
				flag = true
			end
		end

		if flag then
			return flag
		end
	end

	return self.defRedMark
end

function CandyCollectData:onAward(data)
	local details = json.decode(data.detail)

	if details.awarded then
		self.detail_.awarded = details.awarded
	end
end

return CandyCollectData
