local BaseModel = import(".BaseModel")
local OldSchool = class("OldSchool", BaseModel)
local json = require("cjson")

function OldSchool:ctor()
	self.isTestFinal = false
	self.islevel_Open = false
	self.isTowerLevel_Open = false
	self.isAchievment_Open = false

	OldSchool.super.ctor(self)
	self:startTimeSend()

	self.saveLocalBuffsCount = xyd.db.misc:getValue("old_building_buffs_choice_last_count")

	if self.saveLocalBuffsCount then
		self.saveLocalBuffsCount = tonumber(self.saveLocalBuffsCount)
	end
end

function OldSchool:onRegister()
	OldSchool.super.onRegister(self)
	self:registerEvent(xyd.event.GET_BACKPACK_INFO, function ()
		self:checkOpenState()
	end)
	self:registerEvent(xyd.event.OLD_BUILDING_INFO, handler(self, self.onInfo))
	self:registerEvent(xyd.event.OLD_BUILDING_GET_INFO, handler(self, self.onInfo))
	self:registerEvent(xyd.event.LEV_CHANGE, handler(self, function ()
		self:checkOpenState(1)
	end))
	self:registerEvent(xyd.event.OLD_BUILDING_GET_FLOOR_AWARD, handler(self, self.getFloorAwardBack))
	self:registerEvent(xyd.event.OLD_BUILDING_GET_SCORE_AWARD, handler(self, self.getPointAwardBack))
	self:registerEvent(xyd.event.PARTNER_ADD, function (event)
		if self.isAchievment_Open == false then
			local partnerInfo = xyd.models.slot:getPartner(event.data.partnerID)

			if partnerInfo:getStar() >= 10 then
				self.isAchievment_Open = true

				self:cehckFirstOpen()

				if self.allInfo == nil then
					self:updateAllInfo()
				end
			end
		end
	end)
	self:registerEventInner(xyd.event.PARTNER_ATTR_CHANGE, function (event)
		if self.isAchievment_Open == false then
			local partnerInfo = xyd.models.slot:getPartner(event.data.partnerID)

			if partnerInfo:getStar() >= 10 then
				self.isAchievment_Open = true

				self:cehckFirstOpen()

				if self.allInfo == nil then
					self:updateAllInfo()
				end
			end
		end
	end)
	self:registerEvent(xyd.event.OLD_BUILDING_HARM_LIST, handler(self, self.onGetHarmList))
	self:registerEvent(xyd.event.OLD_BUILDING_RANK_LIST, handler(self, self.onGetRankList))
end

function OldSchool:onGetRankList(event)
	self.rankData_ = xyd.decodeProtoBuf(event.data)

	self:updateRankList()
end

function OldSchool:reqRankList(battle)
	if not self.reqRankTime_ or xyd.getServerTime() - self.reqRankTime_ > 30 or battle then
		self.rankData_ = nil
		self.harmData_ = nil
		self.extraRank_ = nil
		local msg = messages_pb:old_building_rank_list_req()

		xyd.Backend.get():request(xyd.mid.OLD_BUILDING_RANK_LIST, msg)

		if xyd.getServerTime() < self:getChallengeEndTime() then
			local msg = messages_pb:old_building_harm_list_req()

			xyd.Backend.get():request(xyd.mid.OLD_BUILDING_HARM_LIST, msg)
		end

		self.reqRankTime_ = xyd.getServerTime()

		return true
	else
		return false
	end
end

function OldSchool:onGetHarmList(event)
	self.harmData_ = xyd.decodeProtoBuf(event.data)

	self:updateRankList()
end

function OldSchool:updateRankList()
	if not self.rankData_ or not self.harmData_ then
		return false
	end

	self.extraRank_ = {}
	local harmList = self.harmData_.list or {}

	for rank, data in ipairs(harmList) do
		local player_id = data.player_id
		local rank_data = self:getPlayerInfo(player_id)
		local addPoint = xyd.tables.oldBuildingHarmAwardPointTable:getPoint(rank)
		rank_data.score = rank_data.score + addPoint
	end

	local list = self.rankData_.list or {}
	local ex_list = self.rankData_.extra_list or {}

	for rank, data in ipairs(list) do
		table.insert(self.extraRank_, data)
	end

	for index, data in ipairs(ex_list) do
		table.insert(self.extraRank_, data)
	end

	table.sort(self.extraRank_, function (a, b)
		if tonumber(a.score) ~= tonumber(b.score) then
			return tonumber(b.score) < tonumber(a.score)
		elseif a.time and b.time then
			return a.time < b.time
		else
			return false
		end
	end)
end

function OldSchool:getSelfScore()
	local score = tonumber(self:getAllInfo().score)
	local fight_rank = self:getAllInfo().fight_rank

	if self.harmData_ then
		fight_rank = self.harmData_.self_rank
	end

	if not fight_rank then
		fight_rank = 0
	else
		fight_rank = fight_rank + 1
	end

	return score + (xyd.tables.oldBuildingHarmAwardPointTable:getPoint(fight_rank) or 0)
end

function OldSchool:getHarmData()
	return self.harmData_
end

function OldSchool:getExtraRankList()
	return self.extraRank_ or self.rankData_.list
end

function OldSchool:getRankData()
	return self.rankData_
end

function OldSchool:getPlayerInfo(player_id)
	local list = self.rankData_.list
	local ex_list = self.rankData_.extra_list

	for rank, data in ipairs(list) do
		if data.player_id == player_id then
			return data
		end
	end

	for index, data in ipairs(ex_list) do
		if data.player_id == player_id then
			return data
		end
	end
end

function OldSchool:startTimeSend()
	local firstStartTime = xyd.tables.miscTable:getNumber("old_building_start_time", "value")

	if self.allInfo == nil and xyd.getServerTime() < firstStartTime then
		xyd.addGlobalTimer(function ()
			self:updateAllInfo()
		end, firstStartTime - xyd.getServerTime(), 1)
	end
end

function OldSchool:onInfo(event)
	local data = event.data
	self.islevel_Open = true
	self.isTowerLevel_Open = true
	self.isAchievment_Open = true
	self.allInfo = xyd.decodeProtoBuf(event.data)

	if self.allInfo.season_info.buffs then
		self.buffs = json.decode(self.allInfo.season_info.buffs)
	end

	if self.allInfo.used_partners then
		self.allInfo.used_partners = json.decode(self.allInfo.used_partners)
	end

	self:checkOpenState()
	self:updateRedMark()

	if self.isTimingDateUpdateScorePointAwards == nil and self:isCanOpen() == true and xyd.getServerTime() < self:getChallengeEndTime() then
		self.isTimingDateUpdateScorePointAwards = xyd.addGlobalTimer(function ()
			self:mustGetScoreGetAward()
		end, self:getChallengeEndTime() - xyd.getServerTime(), 1)
	end

	if self.isOverActiviyUpdatre == nil and self:isCanOpen() == true and xyd.getServerTime() < self:getShowEndTime() then
		self.isOverActiviyUpdatre = xyd.addGlobalTimer(function ()
			xyd.models.oldSchool:updateAllInfo(true)
		end, self:getShowEndTime() - xyd.getServerTime(), 1)
	end

	self:cehckFirstOpen()
end

function OldSchool:updateAllInfo(isMustUpdate)
	if isMustUpdate == nil and self.allInfo == nil then
		local isSend = false

		if xyd.checkFunctionOpen(xyd.FunctionID.OLD_SCHOOL, true) then
			isSend = true
		end

		if xyd.models.towerMap.stage and xyd.tables.miscTable:getNumber("old_building_floor_limit", "value") <= xyd.models.towerMap.stage then
			isSend = true
		end

		if isSend == true then
			local msg = messages_pb:old_building_get_info_req()

			xyd.Backend.get():request(xyd.mid.OLD_BUILDING_GET_INFO, msg)
		end
	end

	if isMustUpdate and isMustUpdate == true then
		local msg = messages_pb:old_building_get_info_req()

		xyd.Backend.get():request(xyd.mid.OLD_BUILDING_GET_INFO, msg)
	end
end

function OldSchool:checkOpenState(type)
	self:updateAllInfo()

	if self.islevel_Open == false and (type == 1 or type == nil) and xyd.checkFunctionOpen(xyd.FunctionID.OLD_SCHOOL, true) then
		self.islevel_Open = true

		self:cehckFirstOpen()
	end

	if self.isTowerLevel_Open == false and (type == 2 or type == nil) and xyd.models.towerMap.stage and xyd.tables.miscTable:getNumber("old_building_floor_limit", "value") < xyd.models.towerMap.stage then
		self.isTowerLevel_Open = true

		self:cehckFirstOpen()
	end

	if self.isAchievment_Open == false and (type == 3 or type == nil) then
		local achievements = xyd.models.achievement:getAchievementList()

		if achievements then
			local achievement_id = xyd.tables.miscTable:getNumber("old_building_star_limit", "value")

			for i in pairs(achievements) do
				if achievements[i].achieve_type == achievement_id then
					local achieve_id = achievements[i].achieve_id

					if achievements[i].achieve_id == 0 then
						achieve_id = xyd.tables.achievementTypeTable:getEndAchievement(achievements[i].achieve_type)
					end

					if xyd.tables.achievementTable:getCompleteValue(achieve_id) <= achievements[i].value then
						self.isAchievment_Open = true

						self:cehckFirstOpen()

						break
					end
				end
			end
		end
	end
end

function OldSchool:cehckFirstOpen()
	if self.islevel_Open == true and self.isTowerLevel_Open == true and self.isAchievment_Open == true then
		local towerWin = xyd.WindowManager.get():getWindow("tower_window")

		if towerWin then
			towerWin:checkOldSchoolImg()
		end

		if self.allInfo then
			self:updateRedMark()
		end
	end
end

function OldSchool:getStartTime()
	return self.allInfo.season_info.start_time
end

function OldSchool:getChallengeEndTime()
	local disTime = tonumber(xyd.tables.miscTable:split2Cost("old_building_time_interval", "value", "|")[1])

	return self:getStartTime() + disTime
end

function OldSchool:getShowEndTime()
	local disTime1 = tonumber(xyd.tables.miscTable:split2Cost("old_building_time_interval", "value", "|")[1])
	local disTime2 = tonumber(xyd.tables.miscTable:split2Cost("old_building_time_interval", "value", "|")[2])

	return self:getStartTime() + disTime1 + disTime2
end

function OldSchool:getAllInfo()
	return self.allInfo
end

function OldSchool:seasonType()
	if self.allInfo.season_info.count % 2 == 1 then
		return 1
	end

	return 2
end

function OldSchool:getOldBuildingTableTable()
	if xyd.models.oldSchool:seasonType() == 1 then
		return xyd.tables.oldBuildingATable
	else
		return xyd.tables.oldBuildingBTable
	end
end

function OldSchool:getOldBuildingAward2Table()
	if xyd.models.oldSchool:seasonType() == 1 then
		return xyd.tables.oldBuildingAAward2Table
	else
		return xyd.tables.oldBuildingBAward2Table
	end
end

function OldSchool:getOldBuildingAward1Table()
	if xyd.models.oldSchool:seasonType() == 1 then
		return xyd.tables.oldBuildingAAward1Table
	else
		return xyd.tables.oldBuildingAAward1Table
	end
end

function OldSchool:openOldSchoolMainWindow()
	if self:isCanOpen(true) == false then
		return
	end

	if xyd.getServerTime() < self:getChallengeEndTime() then
		xyd.WindowManager.get():openWindow("old_school_main_window")
	else
		self:mustGetScoreGetAward()
		xyd.WindowManager.get():openWindow("old_school_final_rank_window")
	end
end

function OldSchool:mustGetScoreGetAward()
	if xyd.getServerTime() < self:getChallengeEndTime() then
		-- Nothing
	elseif self.allInfo then
		for i in pairs(self.allInfo.awards) do
			if self.allInfo.awards[i] == 0 then
				local score = tonumber(self.allInfo.score)

				if self:getOldBuildingAward1Table():getPoint(i) <= score then
					self.allInfo.awards[i] = 1
				end
			end
		end

		self:updateRedMark()
	end
end

function OldSchool:isCanOpen(isShowTips)
	local tipsText = ""

	if self.islevel_Open == false and not xyd.checkFunctionOpen(xyd.FunctionID.OLD_SCHOOL, true) and isShowTips and isShowTips == true then
		local openValue = xyd.tables.functionTable:getOpenValue(xyd.FunctionID.OLD_SCHOOL)
		local fortId = xyd.tables.stageTable:getFortID(openValue)
		local text = tostring(fortId) .. "-" .. tostring(xyd.tables.stageTable:getName(openValue))
		tipsText = __("OLD_SCHOOL_OPEN_LEV", text)
	end

	if self.isTowerLevel_Open == false then
		local towerLev = xyd.tables.miscTable:getNumber("old_building_floor_limit", "value")

		if isShowTips and isShowTips == true then
			if tipsText ~= "" then
				tipsText = tipsText .. "\n"
			end

			tipsText = tipsText .. __("OLD_SCHOOL_OPEN_FLOOR", towerLev)
		end
	end

	if self.isAchievment_Open == false and isShowTips and isShowTips == true then
		if tipsText ~= "" then
			tipsText = tipsText .. "\n"
		end

		tipsText = tipsText .. __("OLD_SCHOOL_OPEN_STAR")
	end

	if tipsText ~= "" then
		xyd.alert(xyd.AlertType.TIPS, tipsText, nil)

		return false
	end

	if self.islevel_Open == false or self.isTowerLevel_Open == false or self.isAchievment_Open == false then
		return false
	end

	if xyd.getServerTime() < xyd.tables.miscTable:getNumber("old_building_start_time", "value") then
		if isShowTips and isShowTips == true then
			xyd.alert(xyd.AlertType.TIPS, __("NO_OPEN"), nil)
		end

		return false
	end

	if self.allInfo == nil or self.allInfo and (xyd.getServerTime() < self.allInfo.season_info.start_time or self:getShowEndTime() <= xyd.getServerTime()) then
		if isShowTips and isShowTips == true then
			xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_END_YET"), nil)
		end

		return false
	end

	return true
end

function OldSchool:checkRedMark()
	if self:isCanOpen() == false then
		return false
	end

	if self.allInfo then
		local redPointState = xyd.db.misc:getValue("old_school_red_point" .. self.allInfo.season_info.count)

		if redPointState == nil then
			return true
		end

		if self:isCheckScoreCanGetAward() == true then
			return true
		end

		if self:isCheckFloorCanGetAward() == true then
			return true
		end
	end

	return false
end

function OldSchool:isCheckScoreCanGetAward()
	if xyd.getServerTime() < self:getChallengeEndTime() and self:getStartTime() < xyd.getServerTime() then
		for i in pairs(self.allInfo.awards) do
			if self.allInfo.awards[i] == 0 then
				local score = tonumber(self.allInfo.score)

				if self:getOldBuildingAward1Table():getPoint(i) <= score then
					return true
				end
			end
		end
	end

	return false
end

function OldSchool:isCheckFloorCanGetAward()
	if xyd.getServerTime() < self:getChallengeEndTime() and self:getStartTime() < xyd.getServerTime() then
		for i, floor_infos in pairs(self.allInfo.floor_infos) do
			for k in pairs(floor_infos.awards) do
				if floor_infos.awards[k] == 0 and tonumber(i) < 11 then
					local complete_num = floor_infos.complete_num

					if k <= complete_num then
						return true
					end
				end
			end
		end
	end

	return false
end

function OldSchool:updateRedMark()
	xyd.models.redMark:setMark(xyd.RedMarkType.OLD_SCHOOL, self:checkRedMark())
end

function OldSchool:updateFormation(teams)
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

function OldSchool:getDefTeams()
	return self.defTeams or {}
end

function OldSchool:setDefFormation(partners, petIDs, floor_id, levelNum)
	local msg = messages_pb:old_building_set_teams_req()

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

	if tonumber(floor_id) == 1 then
		local cjson = require("cjson")
		local detail = cjson.encode(xyd.decodeProtoBuf(msg))

		xyd.db.misc:setValue({
			key = "old_building_first_teams" .. xyd.models.oldSchool:getAllInfo().season_info.count,
			value = detail
		})
	end

	msg.floor_id = tonumber(floor_id)

	xyd.Backend.get():request(xyd.mid.OLD_BUILDING_SET_TEAMS, msg)
	self:setDefUpdataInfo(msg)
end

function OldSchool:setDefUpdataInfo(teamsData)
	self.localTeamsData = teamsData
	local teamsInfo = teamsData.teams

	for _, teamInfo in ipairs(teamsInfo) do
		local partners = teamInfo.partners

		for _, partner in ipairs(partners) do
			local partner_id = partner.partner_id

			if not self.allInfo.used_partners[tostring(partner_id)] then
				self.allInfo.used_partners[tostring(partner_id)] = 1
			else
				self.allInfo.used_partners[tostring(partner_id)] = self.allInfo.used_partners[tostring(partner_id)] + 1
			end
		end
	end

	local floorIndex = teamsData.floor_id
	local beforeFloorInfo = self.allInfo.floor_infos[floorIndex]
	local beforeTeamsInfo = beforeFloorInfo.teams or {}

	for _, teamInfo in ipairs(beforeTeamsInfo) do
		local partners = teamInfo.partners

		for _, partner in ipairs(partners) do
			local partner_id = partner.partner_id

			if self.allInfo.used_partners[tostring(partner_id)] then
				self.allInfo.used_partners[tostring(partner_id)] = self.allInfo.used_partners[tostring(partner_id)] - 1
			end
		end
	end
end

function OldSchool:getDefUpdataInfo()
	return self.localTeamsData or {}
end

function OldSchool:saveCurOpenAreaFloorsInfo(data)
	self.allInfo = data
end

function OldSchool:getCurOpenAreaFloorsInfo()
	return self.allInfo or {}
end

function OldSchool:reqBuyBuff(buff_id, area_id)
	local msg = messages_pb:old_building_activity_unlock_buff_req()
	msg.activity_id = xyd.ActivityID.EXPLORE_OLD_CAMPUS_PVE
	msg.area_id = area_id
	msg.buff_id = buff_id

	xyd.Backend.get():request(xyd.mid.OLD_BUILDING_ACTIVITY_UNLOCK_BUFF, msg)
end

function OldSchool:checkScoreChange(stage_id, floor_info)
	if not self.allInfo then
		return
	end

	local changeInfo = floor_info
	local floorIndex = xyd.tables.oldBuildingStageTable:getFloor(stage_id)
	local beforeFloorInfo = self.allInfo.floor_infos[floorIndex]
	local isChange = false
	local beforeScore = tonumber(beforeFloorInfo.score)

	if beforeScore < tonumber(changeInfo.score) then
		isChange = true

		self:updateFloorInfo(floorIndex, floor_info)
	end

	return isChange, beforeScore or 0
end

function OldSchool:updateUnlockBuffInfo(data)
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

function OldSchool:updateFloorInfo(floorIndex, floor_info)
	if not self.allInfo or not self.allInfo.floor_infos[floorIndex] then
		return
	end

	self.allInfo.floor_infos[floorIndex].score = tonumber(floor_info.score)
	self.allInfo.floor_infos[floorIndex].complete_num = floor_info.complete_num
	self.allInfo.floor_infos[floorIndex].cur_scores = floor_info.cur_scores
	self.allInfo.floor_infos[floorIndex].completeds = floor_info.completeds
end

function OldSchool:setScore(allscore)
	self.allInfo.score = allscore
end

function OldSchool:getRedMarkState()
	return self.isShowRedPoint
end

function OldSchool:getFloorAwardBack(event)
	local dataInfo = xyd.decodeProtoBuf(event.data)

	for i in pairs(dataInfo.indexes) do
		self.allInfo.floor_infos[dataInfo.floor_id].awards[dataInfo.indexes[i]] = 1
	end

	xyd.itemFloat(dataInfo.items, nil, , 7000)

	local awardPanel = xyd.WindowManager.get():getWindow("activity_explore_old_campus_floor_award_window")

	if awardPanel then
		awardPanel:updateAwardBack(event)
	end

	local oldSchoolPanel = xyd.WindowManager.get():getWindow("old_school_main_window")

	if oldSchoolPanel then
		oldSchoolPanel:floorGetAwardBack(dataInfo.floor_id)
	end
end

function OldSchool:getPointAwardBack(event)
	local dataInfo = xyd.decodeProtoBuf(event.data)

	for i in pairs(dataInfo.table_ids) do
		self.allInfo.awards[dataInfo.table_ids[i]] = 1
	end

	xyd.itemFloat(dataInfo.items, nil, , 7000)

	local awardPanel = xyd.WindowManager.get():getWindow("activity_explore_campus_PVE_point_window")

	if awardPanel then
		awardPanel:updateAwardBack(event)
	end

	local oldSchoolPanel = xyd.WindowManager.get():getWindow("old_school_main_window")

	if oldSchoolPanel then
		oldSchoolPanel:updateScoreGetAwardRedPoint()
	end

	local oldSchoolFinalPanel = xyd.WindowManager.get():getWindow("old_school_final_rank_window")

	if oldSchoolFinalPanel then
		oldSchoolFinalPanel:updateScoreGetAwardRedPoint()
	end
end

function OldSchool:reqShopInfo()
	local msg = messages_pb:old_building_get_shop_info_res()

	xyd.Backend.get():request(xyd.mid.OLD_BUILDING_GET_SHOP_INFO, msg)
end

function OldSchool:getBuffs()
	return self.buffs
end

function OldSchool:getSaveLocalBuffsCount()
	if not self.saveLocalBuffsCount then
		return -1
	end

	return self.saveLocalBuffsCount
end

function OldSchool:setSaveLocalBuffsCount(value)
	if not self.saveLocalBuffsCount or self.saveLocalBuffsCount and self.saveLocalBuffsCount ~= value then
		xyd.db.misc:setValue({
			key = "old_building_buffs_choice_last_count",
			value = value
		})

		self.saveLocalBuffsCount = value
	end
end

function OldSchool:getNextStage(stage_id)
	if not self.historyStage_ then
		self.historyStage_ = {}
	end

	local selectInfo = xyd.db.misc:getValue("old_building_setting")

	if selectInfo and type(selectInfo) == "string" then
		selectInfo = json.decode(selectInfo)
	else
		return -1
	end

	local floor_id = xyd.tables.oldBuildingStageTable:getFloor(stage_id)
	local stageArr = xyd.models.oldSchool:getOldBuildingTableTable():getStage(floor_id)
	local floor_index = xyd.arrayIndexOf(stageArr, stage_id)
	local next_stage = -1

	table.insert(self.historyStage_, stage_id)

	if floor_index and floor_index > 0 then
		for index = 1, 3 do
			if tonumber(selectInfo.floor[index]) and index and index ~= floor_index and stageArr[index] and stageArr[index] > 0 and tonumber(selectInfo.floor[index]) > 0 and xyd.arrayIndexOf(self.historyStage_, stageArr[index]) < 0 then
				next_stage = stageArr[index]

				break
			end
		end
	end

	return next_stage
end

function OldSchool:clearFloorHistory()
	self.historyStage_ = {}
	self.failNum_ = 0
end

function OldSchool:autoBattle(stage_id, is_fail)
	local cjson = require("cjson")
	local detail = xyd.db.misc:getValue("old_building_buffs_choice_common")

	if detail and type(detail) == "string" then
		detail = cjson.decode(detail)
	else
		detail = {}
	end

	if xyd.models.oldSchool:getChallengeEndTime() <= xyd.getServerTime() then
		xyd.alertTips(__("ACTIVITY_END_YET"))

		return
	end

	if xyd.models.activity:getExploreOldCampusIsFight() == false then
		xyd.alertTips(__("ACTIVITY_EXPLORE_CAMPUS_LIMIT_TIME", 1))

		return
	end

	local msg = messages_pb:old_building_fight_req()
	msg.stage_id = stage_id

	for i in pairs(detail) do
		if detail[i] > 0 then
			table.insert(msg.buff_ids, detail[i])
		end
	end

	if is_fail then
		self.failNum_ = self.failNum_ + 1
	end

	xyd.Backend.get():request(xyd.mid.OLD_BUILDING_FIGHT, msg)
end

function OldSchool:checkUnlock11Floor()
	local floor_infos = self:getAllInfo().floor_infos
	local isAllComplete = true

	for index, floor_info in ipairs(floor_infos) do
		if index < 11 and floor_info and floor_info.complete_num < #floor_info.completeds then
			isAllComplete = false

			break
		end
	end

	if not isAllComplete then
		return -1
	end

	local point = xyd.tables.miscTable:getVal("old_building_floor11_point")

	if self:getSelfScore() < tonumber(point) then
		return -2
	end

	return 1
end

return OldSchool
