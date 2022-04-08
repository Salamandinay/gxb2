local Achievement = class("Achievement", import(".BaseModel"))
local Activity = xyd.models.activity

function Achievement:ctor()
	Achievement.super.ctor(self)

	self.achievements = {}
	self.partnerAchievements = {}
	self.isBindRecordCheck = false
	self.isShowBindAccountRedMark = false
end

function Achievement:getData()
	local msg = messages_pb.get_achievement_list_req()

	xyd.Backend.get():request(xyd.mid.GET_ACHIEVEMENT_LIST, msg)
end

function Achievement:onRegister()
	Achievement.super.onRegister(self)
	self:registerEvent(xyd.event.GET_ACHIEVEMENT_LIST, handler(self, self.onGetData))
	self:registerEvent(xyd.event.GET_ACHIEVEMENT_AWARD, handler(self, self.onGetAward))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onCheckLevUp))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onCheckLevUp))
	self:registerEvent(xyd.event.LOAD_PARTNER_ACHIEVEMENT, handler(self, self.onPartnerAchievement))
	self:registerEvent(xyd.event.FOLLOW_COMMUNITY, handler(self, self.onCommunityAchievement))
	self:registerEvent(xyd.event.COMPLETE_PARTNER_ACHIEVEMENT, handler(self, self.onCompletePartnerAchievement))
	self:registerEvent(xyd.event.RED_POINT, handler(self, self.onRedMarkInfo))
end

function Achievement:onGetData(event)
	self:onGetDataonGetData(event)
end

function Achievement:onGetDataonGetData(event)
	self.achievements = {}
	self.achievementCampaign = {}
	local achievements = event.data.achievements
	local a_t = xyd.tables.achievementTable

	dump(achievements, "achievements")

	for _, info in pairs(achievements) do
		local achievement = {
			achieve_id = 0,
			sub_value = 0,
			achieve_type = 0,
			value = 0
		}

		for hashkey, _ in pairs(achievement) do
			achievement[hashkey] = info[hashkey]
		end

		if xyd.Global.isReview ~= 1 or achievement.achieve_type ~= 20 then
			if achievement.achieve_id == 0 or a_t:hasID(achievement.achieve_id) then
				if xyd.tables.achievementTable:getIsShowStage(achievement.achieve_id) == 1 or achievement.achieve_type == xyd.ACHIEVEMENT_TYPE.CAMPAIGN then
					self.achievementCampaign = achievement
				else
					table.insert(self.achievements, achievement)
				end
			end

			if achievements.achieve_id == 110 or achievements.achieve_id == 111 then
				local num = tonumber(achievements.value or 0)
				self.fiveStarNum = num
			elseif achievements.achieve_id == 118 or achievements.achieve_id == 119 then
				local num = tonumber(achievements.value or 0)
				self.sixStarNum = num
			elseif achievements.achieve_id == 122 then
				local num = tonumber(achievements.value or 0)
				self.nineStarNum = num
			elseif achievements.achieve_id == 127 then
				local num = tonumber(achievements.value or 0)
				self.tenStarNum = num
			elseif achievements.achieve_id == 128 then
				local num = tonumber(achievements.value or 0)
				self.thirteenStarNum = num
			end
		end
	end

	self:sortAchievement()
	self:updateRedPoint()
	self:updateBindAccountEntry()
	xyd.models.activity:setDefaultRedMark()
	xyd.models.oldSchool:checkOpenState()
end

function Achievement:sortAchievement()
	local a_t = xyd.tables.achievementTable
	local b_t = xyd.tables.achievementTypeTable

	table.sort(self.achievements, function (a, b)
		local all_done_a = a.achieve_id == 0 and 1 or 0
		local all_done_b = b.achieve_id == 0 and 1 or 0
		local aValue = a_t:getCompleteValue(a.achieve_id) or 0
		local bValue = a_t:getCompleteValue(b.achieve_id) or 0
		local not_completed_a = a.value < aValue and 1 or 0
		local not_completed_b = b.value < bValue and 1 or 0
		local rank_a = b_t:getShowRank(a.achieve_type) or 0
		local rank_b = b_t:getShowRank(b.achieve_type) or 0
		local rank_done_a = b_t:getShowRankDone(a.achieve_type)
		local rank_done_b = b_t:getShowRankDone(b.achieve_type)

		if all_done_a ~= all_done_b then
			return all_done_a < all_done_b
		elseif not_completed_a ~= not_completed_b then
			return not_completed_a < not_completed_b
		elseif all_done_a == 1 then
			return rank_done_a < rank_done_b
		else
			return rank_a < rank_b
		end
	end)
end

function Achievement:onCheckLevUp()
end

function Achievement:onGetAward(event)
	local achievement_info = event.data

	for key, _ in pairs(self.achievements) do
		if achievement_info.achieve_type == self.achievements[key].achieve_type then
			self.achievements[key].achieve_id = achievement_info.achieve_id

			break
		end
	end

	if achievement_info.achieve_type == self.achievementCampaign.achieve_type then
		self.achievementCampaign.achieve_id = achievement_info.achieve_id
	end

	self:sortAchievement()
	self:updateRedPoint()
	self:updateRedPointCampaign()
	self:updateBindAccountEntry()

	local win = xyd.WindowManager.get():getWindow("achievement_window")

	if win then
		win:onGetAward(event)
	else
		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.ACHIEVEMENT_GET_AWARD,
			params = event
		})
	end
end

function Achievement:onCommunityAchievement()
	for key, _ in pairs(self.achievements) do
		if self.achievements[key].achieve_type == 37 then
			self.achievements[key].achieve_id = 2301
			self.achievements[key].value = 1

			break
		end
	end
end

function Achievement:setRefreshAfterTime(time)
	local refreshTime = xyd.getServerTime() + time
	self.timer_ = Timer.New(function ()
		if refreshTime <= xyd.getServerTime() then
			self.timer_:Stop()
			xyd.EventDispatcher.inner():dispatchEvent({
				name = xyd.event.ACHIEVEMENT_GET_AWARD,
				params = {}
			})
		end
	end, 1, -1, false)

	self.timer_:Start()
end

function Achievement:updateRedPoint(event)
	self.redPoint = false

	for key, _ in pairs(self.achievements) do
		local complete_value = xyd.tables.achievementTable:getCompleteValue(self.achievements[key].achieve_id)

		if complete_value and complete_value <= self.achievements[key].value then
			self.redPoint = true

			break
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACHIEVEMENT, self.redPoint)
end

function Achievement:showRedPoint()
	return self.redPoint
end

function Achievement:getAchievementList()
	return self.achievements
end

function Achievement:getAchievementCampaignData()
	if not self.achievementCampaign then
		return {}
	end

	return self.achievementCampaign
end

function Achievement:updateRedPointCampaign()
	local showRed = false

	if self.achievementCampaign then
		local complete_value = xyd.tables.achievementTable:getCompleteValue(self.achievementCampaign.achieve_id)

		if complete_value and complete_value <= self.achievementCampaign.value then
			showRed = true
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.CAMPAIGN_ACHIEVEMENT, showRed)

	return showRed
end

function Achievement:getAward(type_id)
	local msg = messages_pb.get_achievement_award_req()
	msg.achievement_type = type_id

	xyd.Backend.get():request(xyd.mid.GET_ACHIEVEMENT_AWARD, msg)
end

function Achievement:loadPartnerAchievement()
	local msg = messages_pb.load_partner_achievement_req()

	xyd.Backend.get():request(xyd.mid.LOAD_PARTNER_ACHIEVEMENT, msg, "LOAD_PARTNER_ACHIEVEMENT")
end

function Achievement:onPartnerAchievement(event)
	local datas = event.data.achievement_list
	local count = 0

	for i = 1, #datas do
		local data = datas[i]

		if data.table_id < 26 or data.table_id > 35 then
			local tableIDs = xyd.tables.partnerAchievementTable:getPartnerTableIDs(data.table_id)

			if tableIDs then
				local tableID = tableIDs[1]
				local keys = xyd.tables.partnerTable:getShowIds(tableID)
				local key = keys[1]
				self.partnerAchievements[key] = data
				local isRed = xyd.tables.partnerAchievementTable:getLastID(data.table_id) ~= 0 and data.is_complete and not data.is_reward

				if isRed then
					local table0 = xyd.models.slot:getListByTableID(tableIDs[1])
					local table1 = xyd.models.slot:getListByTableID(tableIDs[2])
					local table2 = xyd.models.slot:getListByTableID(tableIDs[3])
					local isPartnerExist = #table0 > 0 or #table1 > 0 or #table2 > 0

					if isPartnerExist then
						count = count + 1
					end
				end
			end
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.DATES_STORY, count > 0)
end

function Achievement:completePartnerAchievement(tableID)
	local msg = messages_pb.complete_partner_achievement_req()
	msg.table_id = tableID

	xyd.Backend.get():request(xyd.mid.COMPLETE_PARTNER_ACHIEVEMENT, msg, "COMPLETE_PARTNER_ACHIEVEMENT")
end

function Achievement:onCompletePartnerAchievement(event)
	local datas = event.data.achievement_list
	local count = 0

	for i = 1, #datas do
		local data = datas[i]

		if data.table_id < 26 or data.table_id > 35 then
			local tableIDs = xyd.tables.partnerAchievementTable:getPartnerTableIDs(data.table_id)

			if tableIDs then
				local tableID = tableIDs[1]
				local keys = xyd.tables.partnerTable:getShowIds(tableID)
				local key = keys[1]
				self.partnerAchievements[key] = data
				local isRed = xyd.tables.partnerAchievementTable:getLastID(data.table_id) ~= 0 and data.is_complete and not data.is_reward

				if isRed then
					local table0 = xyd.models.slot:getListByTableID(tableIDs[1])
					local table1 = xyd.models.slot:getListByTableID(tableIDs[2])
					local table2 = xyd.models.slot:getListByTableID(tableIDs[3])
					local isPartnerExist = #table0 > 0 or #table1 > 0 or #table2 > 0

					if isPartnerExist then
						count = count + 1
					end
				end
			end
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.DATES_STORY, count > 0)
end

function Achievement:getPartnerAchievement(tableID)
	local keys = xyd.tables.partnerTable:getShowIds(tableID)
	local key = keys[1]
	local data = self.partnerAchievements[key]

	return data
end

function Achievement:onRedMarkInfo(event)
	if not xyd.Global.isLoadingFinish then
		return
	end

	local funID = event.data.function_id

	if tonumber(funID) == xyd.FunctionID.ACHIEVEMENT then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACHIEVEMENT, true)
	elseif tonumber(funID) ~= xyd.FunctionID.DATES_STORY then
		return
	end

	self:loadPartnerAchievement()
end

function Achievement:getBindAchievementRecord()
	if not xyd.GuideController.get():isGuideComplete() then
		return true
	end

	if self.isBindRecordCheck then
		return true
	end

	for i = 1, #self.achievements do
		if self.achievements[i].achieve_type == xyd.ACHIEVEMENT_TYPE.BINDING_ACCOUNT and self.achievements[i].value >= 1 then
			self.isBindRecordCheck = true

			return true
		end
	end

	if xyd.models.backpack:getLev() <= 30 then
		return false
	end
end

function Achievement:setBindAchievementRecord(value)
	self.isBindRecordCheck = value
end

function Achievement:checkBindAccount()
	if not self.achievements then
		return 0
	end

	for i = 1, #self.achievements do
		if self.achievements[i].achieve_type == xyd.ACHIEVEMENT_TYPE.BINDING_ACCOUNT then
			local data = self.achievements[i]

			if data.achieve_id == 0 then
				return 2
			elseif data.value >= 1 then
				return 1
			end

			return 0
		end
	end

	return 0
end

function Achievement:updateBindAccountEntry()
	local status = self:checkBindAccount()

	if self.isShowBindAccountRedMark ~= (status == 1) then
		Activity:updateRedMarkCount(xyd.ActivityID.BIND_ACCOUNT, function ()
			if status == 1 then
				self.isShowBindAccountRedMark = true
			else
				self.isShowBindAccountRedMark = false
			end
		end)
	end

	Activity:updateFuncEntry(xyd.ActivityID.BIND_ACCOUNT_ENTRY)
end

function Achievement:checkDaDian(np)
	local star = np:getStar()

	if star == 5 then
		if self.fiveStarNum and self.fiveStarNum >= 0 then
			self.fiveStarNum = self.fiveStarNum + 1

			if self.fiveStarNum >= 1 and self.fiveStarNum <= 10 then
				xyd.SdkManager.get():eventTracking("5star-" + self.fiveStarNum)
			end
		end
	elseif star == 6 then
		if self.sixStarNum and self.sixStarNum >= 0 then
			self.sixStarNum = self.sixStarNum + 1

			if self.sixStarNum >= 1 and self.sixStarNum <= 3 then
				xyd.SdkManager.get():eventTracking("6star-" + self.sixStarNum)
			end
		end
	elseif star == 9 then
		if self.nineStarNum and self.nineStarNum >= 0 then
			self.nineStarNum = self.nineStarNum + 1

			if self.nineStarNum == 1 then
				xyd.SdkManager.get():eventTracking("9star-" + self.nineStarNum)
			end
		end
	elseif star == 10 then
		if self.tenStarNum and self.tenStarNum >= 0 then
			self.tenStarNum = self.tenStarNum + 1

			if self.tenStarNum == 1 then
				xyd.SdkManager.get():eventTracking("10star-" + self.tenStarNum)
			end
		end
	elseif star == 13 and self.thirteenStarNum and self.thirteenStarNum >= 0 then
		self.thirteenStarNum = self.thirteenStarNum + 1

		if self.thirteenStarNum == 1 then
			xyd.SdkManager.get().eventTracking("13star-" + self.thirteenStarNum)
		end
	end
end

return Achievement
