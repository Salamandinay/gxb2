local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityGuildCompetitionData = class("ActivityGuildCompetitionData", ActivityData, true)

function ActivityGuildCompetitionData:ctor(params)
	ActivityData.ctor(self, params)
	xyd.models.guild:initGuildCompetitionInfo(self.detail)
end

function ActivityGuildCompetitionData:setData(params)
	ActivityGuildCompetitionData.super.setData(self, params)
	xyd.models.guild:updateGuildCompetitionInfo(self.detail)
end

function ActivityGuildCompetitionData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.GUILD_COMPETITION then
		return
	end

	local data = xyd.decodeProtoBuf(data)
	local backInfo = json.decode(data.detail)

	dump(backInfo, "data_back_201=----------------")

	for i, info in pairs(self.detail.mission_infos) do
		if info.mission_id == backInfo.table_id then
			info.is_awarded = 1

			break
		end
	end

	xyd.models.itemFloatModel:pushNewItems(backInfo.items)
	xyd.models.guild:setGuildCompetitionMissionInfo(self.detail.mission_infos)
end

function ActivityGuildCompetitionData:addUsedPrs(tableId)
	table.insert(self.detail.used_prs, tableId)
	xyd.models.guild:setGuildCompetitionUsedPrs(self.detail.used_prs)
end

function ActivityGuildCompetitionData:getActCount()
	return self.detail.act_count or 1
end

function ActivityGuildCompetitionData:getCount()
	local count = self:getActCount() % 3

	if count == 0 then
		count = 3
	end

	return count
end

return ActivityGuildCompetitionData
