local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityNewbee10GachaData = class("ActivityNewbee10GachaData", ActivityData, true)

function ActivityNewbee10GachaData:isOpen()
	if not self:isFunctionOnOpen() then
		return false
	end

	local isOpen = false

	for i = 1, 5 do
		if not self.detail_.info.awards[i] or self.detail_.info.awards[i] == 0 then
			isOpen = true

			break
		end
	end

	return isOpen
end

function ActivityNewbee10GachaData:getUpdateTime()
	return self.detail_.info.start_time + xyd.TimePeriod.WEEK_TIME
end

function ActivityNewbee10GachaData:getEndTime()
	return self.detail_.info.start_time + xyd.TimePeriod.WEEK_TIME
end

function ActivityNewbee10GachaData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local redState = false
	local goinTime = tonumber(xyd.db.misc:getValue("newbee_10gacha_open_window_time"))
	local comFirmNew = tonumber(xyd.db.misc:getValue("newbee_10gacha_get_new"))

	if not xyd.isSameDay(xyd.getServerTime(), goinTime) then
		redState = true
	end

	for i = 1, 5 do
		if self.detail_.info.awards[i] and self.detail_.info.awards[i] == 0 then
			redState = true

			break
		end
	end

	if comFirmNew and comFirmNew == 1 then
		redState = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.NEWBEE_10GACHA, redState)

	return redState
end

function ActivityNewbee10GachaData:onAward(params)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.NEWBEE_10GACHA, function ()
		if type(params) == "number" then
			local giftbagID = params

			for i = 1, 5 do
				if tonumber(self.detail_.charges[i].table_id) == giftbagID then
					self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1
					self.detail_.info.awards[i] = 0

					break
				end
			end
		else
			local detail = json.decode(params.detail)
			self.detail_.info = detail.info
		end
	end)
end

return ActivityNewbee10GachaData
