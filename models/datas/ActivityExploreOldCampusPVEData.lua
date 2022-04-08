local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityExploreOldCampusPVEData = class("ActivityExploreOldCampusPVEData", ActivityData, true)

function ActivityExploreOldCampusPVEData:ctor(params)
	ActivityData.ctor(self, params)

	self.isShowRedPoint = true
end

function ActivityExploreOldCampusPVEData:getUpdateTime()
	return self:getEndTime()
end

function ActivityExploreOldCampusPVEData:getEndTime()
	return self.start_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityExploreOldCampusPVEData:onAreaIsUnLock(areaId)
	if self.start_time + xyd.tables.activityOldBuildingAreaTable:getTime(areaId) <= xyd.getServerTime() then
		return true
	else
		return false
	end
end

function ActivityExploreOldCampusPVEData:getAreaIsLockTime(areaId)
	if xyd.getServerTime() < self.start_time + xyd.tables.activityOldBuildingAreaTable:getTime(areaId) then
		return self.start_time + xyd.tables.activityOldBuildingAreaTable:getTime(areaId) - xyd.getServerTime()
	else
		return 0
	end
end

function ActivityExploreOldCampusPVEData:onAward(giftBagID)
end

function ActivityExploreOldCampusPVEData:updateFormation(teams)
	self.defFormation = {}
	self.defTeams = {}

	for i = 1, #teams do
		for j = 1, #teams[i].partners do
			local index = (i - 1) * 6 + teams[i].partners[j].pos
			self.defFormation[index] = teams[i].partners[j]
		end
	end

	self.defTeams = teams

	return self.defFormation
end

function ActivityExploreOldCampusPVEData:getDefTeams()
	return self.defTeams or {}
end

function ActivityExploreOldCampusPVEData:setDefFormation(partners, petIDs, floor_id, levelNum)
	local msg = messages_pb:old_building_activity_set_teams_req()

	if petIDs == nil then
		petIDs = {
			0,
			0,
			0,
			0
		}
	end

	for i = 1, levelNum do
		local teamOne = messages_pb:set_partners_req()
		teamOne.pet_id = petIDs[i + 1]
		local tmpPartner = xyd.slice(partners, (i - 1) * 6 + 1, (i - 1) * 6 + 6)

		for j = 1, #tmpPartner do
			if tmpPartner[j] ~= nil then
				local fight_partner = messages_pb:fight_partner()
				fight_partner.partner_id = tmpPartner[j].partner_id
				fight_partner.pos = tmpPartner[j].pos

				table.insert(teamOne.partners, fight_partner)
			end
		end

		table.insert(msg.teams, teamOne)
	end

	msg.floor_id = tonumber(floor_id)
	msg.activity_id = self.id

	xyd.Backend.get():request(xyd.mid.OLD_BUILDING_ACTIVITY_SET_TEAMS, msg)
	self:setDefUpdataInfo(msg)
end

function ActivityExploreOldCampusPVEData:setDefUpdataInfo(teamsData)
	self.localTeamsData = teamsData
	local teamsInfo = teamsData.teams

	for _, teamInfo in ipairs(teamsInfo) do
		local partners = teamInfo.partners

		for _, partner in ipairs(partners) do
			local partner_id = partner.partner_id

			if not self.detail_.used_partners[tostring(partner_id)] then
				self.detail_.used_partners[tostring(partner_id)] = 1
			else
				self.detail_.used_partners[tostring(partner_id)] = self.detail_.used_partners[tostring(partner_id)] + 1
			end
		end
	end

	local floorIndex = xyd.tables.activityOldBuildingStageTable:getAreaIndexByFloor(teamsData.floor_id)
	local beforeFloorInfo = self.curOpenAreaFloorsInfo.floor_infos[floorIndex]
	local beforeTeamsInfo = beforeFloorInfo.teams or {}

	for _, teamInfo in ipairs(beforeTeamsInfo) do
		local partners = teamInfo.partners

		for _, partner in ipairs(partners) do
			local partner_id = partner.partner_id

			if self.detail_.used_partners[tostring(partner_id)] then
				self.detail_.used_partners[tostring(partner_id)] = self.detail_.used_partners[tostring(partner_id)] - 1
			end
		end
	end
end

function ActivityExploreOldCampusPVEData:getDefUpdataInfo()
	return self.localTeamsData or {}
end

function ActivityExploreOldCampusPVEData:saveCurOpenAreaFloorsInfo(data)
	self.curOpenAreaFloorsInfo = data
end

function ActivityExploreOldCampusPVEData:getCurOpenAreaFloorsInfo()
	return self.curOpenAreaFloorsInfo or {}
end

function ActivityExploreOldCampusPVEData:reqBuyBuff(buff_id, area_id)
	local msg = messages_pb:old_building_activity_unlock_buff_req()
	msg.activity_id = xyd.ActivityID.EXPLORE_OLD_CAMPUS_PVE
	msg.area_id = area_id
	msg.buff_id = buff_id

	xyd.Backend.get():request(xyd.mid.OLD_BUILDING_ACTIVITY_UNLOCK_BUFF, msg)
end

function ActivityExploreOldCampusPVEData:checkScoreChange(stage_id, floor_info)
	if not self.curOpenAreaFloorsInfo then
		return
	end

	local changeInfo = floor_info
	local floorIndex = xyd.tables.activityOldBuildingStageTable:getAreaIndex(stage_id)
	local beforeFloorInfo = self.curOpenAreaFloorsInfo.floor_infos[floorIndex]
	local isChange = false
	local beforeScore = beforeFloorInfo.score

	if beforeFloorInfo.score < changeInfo.score then
		isChange = true

		self:updateFloorInfo(floorIndex, floor_info)
	end

	return isChange, beforeScore or 0
end

function ActivityExploreOldCampusPVEData:updateUnlockBuffInfo(data)
	table.insert(self.detail.area_infos[tonumber(data.area_id)].unlock_buffs, tonumber(data.buff_id))

	local waysWin = xyd.WindowManager.get():getWindow("activity_explore_old_campus_ways_window")

	if waysWin then
		waysWin:updateBuffs()
	end

	local fightWin = xyd.WindowManager.get():getWindow("activity_explore_campus_fight_window")

	if fightWin then
		fightWin:updateBuffs()
	end
end

function ActivityExploreOldCampusPVEData:updateFloorInfo(floorIndex, floor_info)
	if not self.curOpenAreaFloorsInfo or not self.curOpenAreaFloorsInfo.floor_infos[floorIndex] then
		return
	end

	self.curOpenAreaFloorsInfo.floor_infos[floorIndex].score = floor_info.score
	self.curOpenAreaFloorsInfo.floor_infos[floorIndex].complete_num = floor_info.complete_num
	self.curOpenAreaFloorsInfo.floor_infos[floorIndex].cur_scores = floor_info.cur_scores
	self.curOpenAreaFloorsInfo.floor_infos[floorIndex].completeds = floor_info.completeds
end

function ActivityExploreOldCampusPVEData:setScore(allscore, area_id, areascore)
	self.detail.score = allscore
	self.detail.area_infos[area_id].score = areascore
end

function ActivityExploreOldCampusPVEData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return self.isShowRedPoint
end

return ActivityExploreOldCampusPVEData
