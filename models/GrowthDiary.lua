local BaseModel = import(".BaseModel")
local GrowthDiary = class("GrowthDiary", BaseModel)

function GrowthDiary:ctor()
	GrowthDiary.super.ctor(self)

	self.missionList_ = {}
	self.awardsData_ = {}
	self.reqTimeList_ = {}
	self.chapter_id = 1
end

function GrowthDiary:onRegister()
	GrowthDiary.super.onRegister(self)
	self:registerEvent(xyd.event.RED_POINT, handler(self, self.onRedMarkInfo))
	self:registerEvent(xyd.event.GET_GROWTH_MISSIONS, handler(self, self.onGetMissionList))
	self:registerEvent(xyd.event.GET_GROWTH_MISSIONS_AWARDS, handler(self, self.onGetAwards))
	self:registerEvent(xyd.event.GET_GROWTH_CHAPTER_AWARDS, handler(self, self.onGetChapterAwards))
end

function GrowthDiary:reqChapterAward(chapter_id)
	local msg = messages_pb.get_growth_chapter_awards_req()
	msg.id = chapter_id

	xyd.Backend.get():request(xyd.mid.GET_GROWTH_CHAPTER_AWARDS, msg)
end

function GrowthDiary:reqAward(mission_id)
	local msg = messages_pb.get_growth_missions_awards_req()

	table.insert(msg.mission_ids, mission_id)
	xyd.Backend.get():request(xyd.mid.GET_GROWTH_MISSIONS_AWARDS, msg)
end

function GrowthDiary:reqMissionData(chapter_id)
	chapter_id = chapter_id or self.chapter_id

	if chapter_id < self.chapter_id or self:checkFinish() then
		local ids = xyd.tables.grouthDiaryMissionTable:getIDsByChapter(chapter_id)

		for _, id in ipairs(ids) do
			self.missionList_[tonumber(id)] = {
				is_completed = 1,
				value = 1,
				is_awarded = 1,
				mission_id = id
			}
		end

		return false
	end

	if not self.reqTimeList_[chapter_id] or xyd.getServerTime() - self.reqTimeList_[chapter_id] > 30 or xyd.models.redMark:getRedState(xyd.RedMarkType.GROWTH_DIARY) then
		local ids = xyd.tables.grouthDiaryMissionTable:getIDsByChapter(chapter_id)
		local msg = messages_pb.get_growth_missions_req()

		for _, id in ipairs(ids) do
			table.insert(msg.mission_ids, id)
		end

		xyd.Backend.get():request(xyd.mid.GET_GROWTH_MISSIONS, msg)

		self.reqTimeList_[chapter_id] = xyd.getServerTime()

		return true
	else
		return false
	end
end

function GrowthDiary:getChapter()
	return self.chapter_id or 1
end

function GrowthDiary:clearTime()
	self.reqTimeList_ = {}
end

function GrowthDiary:onGetAwards(event)
	local mission_ids = event.data.mission_ids

	for index, mission_id in ipairs(mission_ids) do
		local missionData = self:getMissionInfo(mission_id)
		missionData.is_awarded = 1
	end

	self:updateRedMark()
end

function GrowthDiary:onGetChapterAwards(event)
	local id = event.data.id
	self.awardsData_[id] = 1
	local msg = messages_pb.log_partner_data_touch_req()
	msg.touch_id = xyd.DaDian.GROWTH_DIARY
	msg.desc = tostring(id)

	xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
	self:updateChapter()
	self:updateRedMark()

	local long = xyd.tables.grouthDiaryMissionTable:getChapterLong()

	if long <= id then
		local wnd = xyd.getWindow("main_window")

		if wnd then
			wnd:checkTrBtn()
		end
	end
end

function GrowthDiary:onGetMissionList(event)
	local data = xyd.decodeProtoBuf(event.data)
	local missions = data.missions or {}

	for index, missionData in ipairs(missions) do
		local mission_id = missionData.mission_id
		self.missionList_[tonumber(mission_id)] = missionData
	end

	self:updateRedMark()
end

function GrowthDiary:updateRedMark()
	self:updateChapter()

	local ids = xyd.tables.grouthDiaryMissionTable:getIDsByChapter(self.chapter_id)

	table.sort(ids)

	local redFlag = false
	local completeNum = 0

	for _, id in ipairs(ids) do
		local missionData = self:getMissionInfo(id)

		if missionData and missionData.is_completed == 1 and missionData.is_awarded ~= 1 then
			redFlag = true

			break
		end

		if missionData and missionData.is_completed == 1 then
			completeNum = completeNum + 1
		end
	end

	if completeNum >= #ids and self.awardsData_[self.chapter_id] ~= 1 then
		redFlag = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.GROWTH_DIARY, redFlag)
end

function GrowthDiary:updateChapter()
	self.chapter_id = 1

	for index, value in ipairs(self.awardsData_) do
		if value == 1 then
			self.chapter_id = index + 1
		end
	end

	local long = xyd.tables.grouthDiaryMissionTable:getChapterLong()

	print("self.chapter_id   ", self.chapter_id, "long  ", long)

	if long < self.chapter_id then
		self.chapter_id = long
		self.isFinish_ = true
	end

	local activityInvitationSeniorData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_INVITATION_SENIOR)

	if activityInvitationSeniorData then
		activityInvitationSeniorData:checkRedPoint()
	end
end

function GrowthDiary:checkFinish()
	return self.isFinish_
end

function GrowthDiary:getMissionInfo(mission_id)
	return self.missionList_[tonumber(mission_id)]
end

function GrowthDiary:onRedMarkInfo(event)
	if not xyd.Global.isLoadingFinish then
		return
	end

	local funID = event.data.function_id

	if tonumber(funID) == xyd.FunctionID.GROWTH_DIARY then
		local value = event.data.value
		local chapter = xyd.tables.grouthDiaryMissionTable:getChapterID(value)

		if chapter <= self.chapter_id then
			xyd.models.redMark:setMark(xyd.RedMarkType.GROWTH_DIARY, true)
		end
	end
end

function GrowthDiary:onLoginInfo(event)
	self.awardsData_ = {}

	for index, value in ipairs(event.awards) do
		self.awardsData_[index] = value
	end

	self:updateChapter()
	self:reqMissionData()
end

function GrowthDiary:checkChapterAwarded(chapter_id)
	return self.awardsData_[chapter_id] == 1
end

function GrowthDiary:checkCanAward(chapter_id)
	local ids = xyd.tables.grouthDiaryMissionTable:getIDsByChapter(chapter_id)
	local completeNum = 0

	for _, id in ipairs(ids) do
		local missionData = self:getMissionInfo(id)

		if missionData.is_completed == 1 and missionData.is_awarded == 1 then
			completeNum = completeNum + 1
		end
	end

	return completeNum >= 4
end

return GrowthDiary
