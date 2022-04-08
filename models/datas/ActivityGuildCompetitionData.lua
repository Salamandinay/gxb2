local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityGuildCompetitionData = class("ActivityGuildCompetitionData", ActivityData, true)

function ActivityGuildCompetitionData:ctor(params)
	ActivityData.ctor(self, params)
	xyd.models.guild:initGuildCompetitionInfo(self.detail_)
end

function ActivityGuildCompetitionData:setData(params)
	ActivityGuildCompetitionData.super.setData(self, params)
	xyd.models.guild:updateGuildCompetitionInfo(self.detail_)
end

return ActivityGuildCompetitionData
