local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivitySecretTreasureHuntGiftbagData = class("ActivitySecretTreasureHuntGiftbagData", ActivityData, true)

function ActivitySecretTreasureHuntGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function ActivitySecretTreasureHuntGiftbagData:onAward(giftbag_id)
	for i = 1, #self.detail.charges do
		if self.detail.charges[i].table_id == giftbag_id then
			self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1

			break
		end
	end
end

function ActivitySecretTreasureHuntGiftbagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	else
		local lastViewTime = xyd.db.misc:getValue("secret_treasure_hunt_giftbag_view_time")

		if not lastViewTime or not xyd.isSameDay(lastViewTime, xyd.getServerTime()) then
			self.defRedMark = true
		else
			self.defRedMark = false
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SECRET_TREASURE_HUNT_GIFTBAG, self.defRedMark)

	return self.defRedMark
end

return ActivitySecretTreasureHuntGiftbagData
