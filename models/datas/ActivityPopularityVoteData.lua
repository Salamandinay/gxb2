local ActivityData = import("app.models.ActivityData")
local ActivityPopularityVoteData = class("ActivityPopularityVoteData", ActivityData, true)
local cjson = require("cjson")

function ActivityPopularityVoteData:ctor(params)
	ActivityData.ctor(self, params)

	self.supportRankList = {}
	self.rank_list = {}
	self.supportCommentList = {}
	self.selfCommentList = {}
	self.history = {}

	self:getCurPeriod()
end

function ActivityPopularityVoteData:register()
	self:registerEvent(xyd.event.ACTIVITY_POPULARITY_VOTE_GET_VOTE_LIST, function (event)
		self.rank_list = cjson.decode(event.data.rank_list)
		self.history[self.tempPeriod] = cjson.decode(event.data.rank_list)
		local vote_list = cjson.decode(event.data.vote_list)

		for _, list in ipairs(self.history[self.tempPeriod]) do
			for _, item in ipairs(list) do
				for table_id, value in pairs(vote_list) do
					if item.table_id == tonumber(table_id) then
						item.myVote = value
					end
				end
			end
		end

		self.isReqingVoteList = false

		self:checkPeriodData()
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_POPULARITY_VOTE then
			local detail = cjson.decode(data.detail)
			local type = detail.type

			if type == 2 then
				local table_id = tonumber(detail.table_id)
				self.selfCommentList[table_id] = detail.msg .. ":" .. xyd.getServerTime()
			elseif type == 3 then
				self.supportRankList[self.tempPartnerTableID] = detail.player_list
			elseif type == 4 then
				local table_id = tonumber(detail.table_id)
				self.supportCommentList[table_id] = detail.list
				self.selfCommentList[table_id] = detail.self_msg
			end
		end
	end)
	self:registerEvent(xyd.event.ACTIVITY_POPULARITY_VOTE_SUPPORT, function (event)
		self:reqVoteRankList(math.min(9, self.curPeriod))

		local lastVote = self.lastVote or {
			0,
			0
		}
		self.detail.vote_num = self.detail.vote_num + lastVote[2]

		if lastVote[1] == xyd.ItemID.POPULARITY_TICKET then
			local lastNum = self.detail_.mission_count[4]
			self.detail_.mission_count[4] = math.min(self.detail_.mission_count[4] + lastVote[2], 10)

			if lastNum < 10 and lastNum + lastVote[2] >= 10 then
				xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_POPULARITY_VOTE_AWARD, true)
			end
		end
	end)
end

function ActivityPopularityVoteData:checkPeriodData()
	self:getCurPeriod()

	for i = 1, math.min(self.curPeriod, 9) do
		if not self.history[i] then
			self:reqVoteRankList(i)

			return
		end
	end
end

function ActivityPopularityVoteData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self.detail_.partner_id then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_POPULARITY_VOTE_AWARD, false)

		return false
	end

	local flag = false
	local lastTime = xyd.db.misc:getValue("activity_popularity_vote_award")
	flag = not lastTime or not xyd.isSameDay(tonumber(lastTime), xyd.getServerTime())
	local t = xyd.tables.activityPopularityVoteTaskTable
	local ids = t:getIDs()
	local missionCount = self.detail_.mission_count
	local missionAwarded = self.detail_.mission_awarded

	for i = 1, #ids do
		local complete = t:getCompleteNum(i)

		if complete <= missionCount[i] and missionAwarded[i] == 0 then
			flag = true

			break
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_POPULARITY_VOTE_AWARD, flag)

	return flag
end

function ActivityPopularityVoteData:setVote(itemID, num, lastVoteTableID)
	self.lastVote = {
		itemID,
		num
	}
	self.lastVoteTableID = lastVoteTableID
end

function ActivityPopularityVoteData:setDefRedMark(flag)
	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_POPULARITY_VOTE_AWARD, flag)

	local msg = messages_pb.activity_popularity_vote_vote_mission_info_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_POPULARITY_VOTE

	xyd.Backend.get():request(xyd.mid.ACTIVITY_POPULARITY_VOTE_VOTE_MISSION_INFO, msg)
end

function ActivityPopularityVoteData:reqVoteRankList(period)
	if self.isReqingVoteList then
		return
	end

	self.isReqingVoteList = true
	local msg = messages_pb.activity_popularity_vote_get_vote_list_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_POPULARITY_VOTE
	msg.period = period
	self.tempPeriod = period

	xyd.Backend.get():request(xyd.mid.ACTIVITY_POPULARITY_VOTE_GET_VOTE_LIST, msg)
end

function ActivityPopularityVoteData:getSelfComment(partnerTableID)
	return self.selfCommentList[partnerTableID]
end

function ActivityPopularityVoteData:sendSelfComment(partnerTableID, msgText)
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_POPULARITY_VOTE
	msg.params = cjson.encode({
		type = 2,
		table_id = partnerTableID,
		msg = msgText
	})
	self.tempPartnerTableID = partnerTableID

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function ActivityPopularityVoteData:reqAllSelfComment()
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_POPULARITY_VOTE
	msg.params = cjson.encode({
		type = 5
	})

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function ActivityPopularityVoteData:reqCommentInfos(partnerTableID)
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_POPULARITY_VOTE
	msg.params = cjson.encode({
		type = 4,
		table_id = partnerTableID
	})
	self.tempPartnerTableID = partnerTableID

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function ActivityPopularityVoteData:reqRankListByParner(partnerTableID)
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_POPULARITY_VOTE
	msg.params = cjson.encode({
		type = 3,
		table_id = partnerTableID
	})
	self.tempPartnerTableID = partnerTableID

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function ActivityPopularityVoteData:getRankListByParner(partnerTableID)
	return self.supportRankList[partnerTableID]
end

function ActivityPopularityVoteData:getCommentListByParner(partnerTableID)
	local selfComment = self:getSelfComment(partnerTableID)

	dump(selfComment)

	local list = {}

	if selfComment then
		local texts = xyd.split(selfComment, ":")
		local time = tonumber(texts[#texts])
		local msg = ""

		for i = 1, #texts - 1 do
			msg = msg .. texts[i]
		end

		table.insert(list, {
			player_id = xyd.Global.playerID,
			player_name = xyd.Global.playerName,
			avatar_id = xyd.models.selfPlayer:getAvatarID(),
			frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
			level = xyd.models.backpack:getLev(),
			server_id = xyd.models.selfPlayer:getServerID(),
			msg = msg,
			time = time,
			vote = self:getSelfTicketByPartner(partnerTableID)
		})
	end

	dump(self.supportCommentList[partnerTableID])

	for key, value in pairs(self.supportCommentList[partnerTableID]) do
		if value.player_id ~= xyd.Global.playerID then
			local texts = xyd.split(value.msg, ":")

			if not value.time then
				value.time = tonumber(texts[#texts])
				value.msg = ""

				for i = 1, #texts - 1 do
					value.msg = value.msg .. texts[i]
				end
			end

			table.insert(list, value)
		end
	end

	table.sort(list, function (a, b)
		if a.player_id == xyd.Global.playerID or b.player_id == xyd.Global.playerID then
			return a.player_id == xyd.Global.playerID
		elseif a.vote ~= b.vote then
			return tonumber(b.vote) < tonumber(a.vote)
		else
			return tonumber(a.player_id) < tonumber(b.player_id)
		end
	end)

	return list
end

function ActivityPopularityVoteData:getSelfTicketByPeriodAndPartner(partnerTableID, period)
	if self.history[period] then
		dump(self.history[period])

		for _, list in ipairs(self.history[period]) do
			for _, item in ipairs(list) do
				if tonumber(item.table_id) == tonumber(partnerTableID) then
					return item.myVote or 0
				end
			end
		end
	end

	return 0
end

function ActivityPopularityVoteData:getSelfTicketByPartner(partnerTableID)
	local sum = 0

	for i = 1, self.curPeriod do
		sum = sum + self:getSelfTicketByPeriodAndPartner(partnerTableID, i)
	end

	return sum
end

function ActivityPopularityVoteData:getTicketByPeriodAndPartner(partnerTableID, period)
	if self.history[period] then
		for _, list in ipairs(self.history[period]) do
			for _, item in ipairs(list) do
				if tonumber(item.table_id) == tonumber(partnerTableID) then
					return item.score
				end
			end
		end
	end

	return 0
end

function ActivityPopularityVoteData:getCurPeriod()
	local curDay = (xyd.getServerTime() - self.start_time) / 86400
	local periodList = xyd.split(xyd.tables.miscTable:getVal("activity_popularity_vote_stagetime"), "|", true)
	self.curPeriod = 1

	for k, v in ipairs(periodList) do
		if curDay < v then
			self.curPeriod = k

			break
		end
	end

	return self.curPeriod
end

return ActivityPopularityVoteData
