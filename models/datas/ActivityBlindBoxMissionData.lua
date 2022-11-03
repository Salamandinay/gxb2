local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityBlindBoxMissionData = class("ActivityBlindBoxMissionData", ActivityData, true)

function ActivityBlindBoxMissionData:getRedMarkState()
	local redState = true
	local lastViewTime = xyd.db.misc:getValue("activity_blind_box_mission_last_view_time")

	if lastViewTime and xyd.isSameDay(tonumber(lastViewTime), xyd.getServerTime()) then
		redState = false
	end

	return redState
end

function ActivityBlindBoxMissionData:setFirstTimeEnter(flag)
	if flag then
		self.firstTimeEnter = flag
	else
		self.firstTimeEnter = false
	end
end

function ActivityBlindBoxMissionData:isFirstTimeEnter()
	if self.firstTimeEnter ~= nil then
		return self.firstTimeEnter
	end

	return true
end

function ActivityBlindBoxMissionData:getVipExp()
	return self.detail.vip_exp
end

function ActivityBlindBoxMissionData:register()
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onVIPExpChange))
end

function ActivityBlindBoxMissionData:onVIPExpChange(event)
	for i = 1, #event.data.items do
		local itemId = event.data.items[i].item_id

		if itemId == xyd.ItemID.VIP_EXP then
			local msg = messages_pb:get_activity_info_by_id_req()
			msg.activity_id = self.id

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)

			break
		end
	end
end

return ActivityBlindBoxMissionData
