local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local JackpotMachineData = class("JackpotMachineData", ActivityData, true)

function JackpotMachineData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function JackpotMachineData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_JACKPOT_ENERGY) > 0 then
		return true
	end

	return self.defRedMark
end

function JackpotMachineData:onAward(data)
	local real_data = json.decode(data.detail)
	self.detail_.energy_update_time = real_data.act_info.energy_update_time
	self.detail_.buy_times = real_data.act_info.buy_times

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, {
		activity_id = xyd.ActivityID.JACKPOT_MACHINE_SCORE
	})
end

return JackpotMachineData
