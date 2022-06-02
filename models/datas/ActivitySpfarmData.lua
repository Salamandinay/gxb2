local ActivityData = import("app.models.ActivityData")
local ActivitySpfarmData = class("ActivitySpfarmData", ActivityData, true)
local json = require("cjson")

function ActivitySpfarmData:getUpdateTime()
	return self:getEndTime()
end

function ActivitySpfarmData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_SPFARM then
		return
	end

	local data = xyd.decodeProtoBuf(data)

	dump(data, "data_back_300=----------------")

	local info = json.decode(data.detail)
	local type = info.type

	if type == xyd.ActivitySpfarmType.BUILD then
		local oldLength = #self.detail.build_infos

		table.insert(self.detail.build_infos, {
			lv = 1,
			build_id = info.build_id,
			id = oldLength + 1
		})

		self.detail.map[info.pos] = oldLength + 1
	end
end

function ActivitySpfarmData:getMyMap()
	return self.detail.map
end

function ActivitySpfarmData:getMyBuildIndos()
	return self.detail.build_infos
end

function ActivitySpfarmData:getFamousNum()
	local famousNum = 0
	local famousWithIds = xyd.tables.activitySpfarmPolicyTable:getFamousWithIds()

	for i = 1, #famousWithIds do
		local ids = famousWithIds[i]
		local isAdd = true

		for k, id in pairs(ids) do
			if not self.detail.policys[id] or self.detail.policys[id] and self.detail.policys[id] == 0 then
				isAdd = false
			end
		end

		if isAdd then
			famousNum = famousNum + 1
		else
			break
		end
	end

	return famousNum
end

function ActivitySpfarmData:getTypeBuildLimitLevUp(serchType)
	local ids = xyd.tables.activitySpfarmPolicyTable:getIDs()
	local buildLev = nil

	for i, id in pairs(ids) do
		local type = xyd.tables.activitySpfarmPolicyTable:getType(id)
		local otherParam = xyd.tables.activitySpfarmPolicyTable:getParams(id)

		if type == 1 and serchType == otherParam and self.detail.policys[id] and self.detail.policys[id] == 1 then
			buildLev = xyd.tables.activitySpfarmPolicyTable:getNum(id)
		end
	end

	return buildLev
end

function ActivitySpfarmData:getTypeBuildLimitNumUp(serchType)
	local ids = xyd.tables.activitySpfarmPolicyTable:getIDs()
	local buildNum = nil

	for i, id in pairs(ids) do
		local type = xyd.tables.activitySpfarmPolicyTable:getType(id)
		local otherParam = xyd.tables.activitySpfarmPolicyTable:getParams(id)

		if type == 2 and serchType == otherParam and self.detail.policys[id] and self.detail.policys[id] == 1 then
			buildNum = xyd.tables.activitySpfarmPolicyTable:getNum(id)
		end
	end

	return buildNum
end

function ActivitySpfarmData:getcurBuildNum(serchBuildId)
	local curNum = 0

	for i, info in pairs(self.detail.build_infos) do
		local buildId = info.build_id

		if buildId == serchBuildId then
			curNum = curNum + 1
		end
	end

	return curNum
end

function ActivitySpfarmData:getAllBuildTotalLev()
	local totalLev = 0

	for i, info in pairs(self.detail.build_infos) do
		if i ~= 1 then
			totalLev = totalLev + info.lv
		end
	end

	return totalLev
end

return ActivitySpfarmData
