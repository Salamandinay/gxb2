local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityTowerEmergencyData = class("ActivityTowerEmergencyData", ActivityData, true)

function ActivityTowerEmergencyData:getUpdateTime()
	return self.detail[1].update_time + xyd.tables.giftBagTable:getLastTime(self.detail[1].charge.table_id)
end

function ActivityTowerEmergencyData:onAward(giftBagID)
	self.detail[1].charge.buy_times = self.detail[1].charge.buy_times + 1
end

return ActivityTowerEmergencyData
