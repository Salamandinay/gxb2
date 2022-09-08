local ActivityData = import("app.models.ActivityData")
local ActivityInvitationSeniorData = class("ActivityInvitationSeniorData", ActivityData, true)
local cjson = require("cjson")

function ActivityInvitationSeniorData:ctor(params)
	ActivityData.ctor(self, params)

	self.rankDataList_ = {}
	self.recordRankSelfScoreArr = {}
	self.isCanUpdateRank = true

	self:checkRedPoint()
end

function ActivityInvitationSeniorData:setData(params)
	ActivityInvitationSeniorData.super.setData(self, params)
	self:checkRedPoint()
end

function ActivityInvitationSeniorData:setDataNodecode(params)
	ActivityInvitationSeniorData.super.setDataNodecode(self, params)
	self:checkRedPoint()
end

function ActivityInvitationSeniorData:register()
end

function ActivityInvitationSeniorData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_INVITATION_SENIOR then
		return
	end

	local data = xyd.decodeProtoBuf(data)
	local info = require("cjson").decode(data.detail)

	dump(info, "data_back_314=----------------")

	local award_type = info.award_type

	if award_type == xyd.ActivityInvitationSeniorSendType.BIND then
		self.detail = info

		self:checkRedPoint()
	elseif award_type == xyd.ActivityInvitationSeniorSendType.SEND_AWARD then
		self.detail.daily_send = info.daily_send
	elseif award_type == xyd.ActivityInvitationSeniorSendType.GET_AWARD then
		self:onGetDailyAward(data)
	elseif award_type == xyd.ActivityInvitationSeniorSendType.DEL_INVITEE then
		self.detail = info
	elseif award_type == xyd.ActivityInvitationSeniorSendType.WEEK_SHARE_AWARD then
		self.detail.weekly_share = info.weekly_share

		self:checkRedPoint()
	elseif award_type == xyd.ActivityInvitationSeniorSendType.GET_RANK then
		self:onGetRankInfo(info)
	elseif award_type == xyd.ActivityInvitationSeniorSendType.GET_OLD_TASK_AWARD then
		for i, state in pairs(info.inviter_awarded) do
			if state and state == 1 and (not self.detail.inviter_awarded[i] or self.detail.inviter_awarded[i] == 0) then
				local awards = xyd.tables.activityInvitationOldAwardTable:getAwards(i)
				local items = {}

				for k in pairs(awards) do
					table.insert(items, {
						item_id = awards[k][1],
						item_num = awards[k][2]
					})
				end

				xyd.models.itemFloatModel:pushNewItems(items)

				if not self.detail.point then
					self.detail.point = 0
				end

				self.detail.point = self.detail.point + xyd.tables.activityInvitationOldAwardTable:getPoint(i)

				break
			end
		end

		self.detail.inviter_awarded = info.inviter_awarded

		self:checkRedPoint()
	end
end

function ActivityInvitationSeniorData:getState()
	local curGrowthNum = xyd.models.growthDiary:getChapter()
	local invitation_senpai = xyd.tables.miscTable:getNumber("invitation_senpai", "value")

	if invitation_senpai < curGrowthNum then
		return xyd.ActivityInvitationSeniorState.OLD
	end

	local inviter = self:getInviter()

	if inviter and inviter ~= 0 then
		return xyd.ActivityInvitationSeniorState.NEW
	end

	local playerLev = xyd.models.backpack:getLev()
	local targetLev = xyd.tables.miscTable:getNumber("invitation_new", "value")

	if playerLev <= targetLev then
		return xyd.ActivityInvitationSeniorState.NEW
	end

	return xyd.ActivityInvitationSeniorState.NO
end

function ActivityInvitationSeniorData:isShowSettingUpEnter()
	if self:getState() == xyd.ActivityInvitationSeniorState.NEW or self:getState() == xyd.ActivityInvitationSeniorState.OLD then
		return true
	end

	return false
end

function ActivityInvitationSeniorData:getBindCount()
	return self.detail.bind_count
end

function ActivityInvitationSeniorData:getInviter()
	return self.detail.inviter
end

function ActivityInvitationSeniorData:getInviterInfo()
	return self.detail.inviter_info
end

function ActivityInvitationSeniorData:getInvitees()
	return self.detail.invitees or {}
end

function ActivityInvitationSeniorData:getInviteeInfos()
	return self.detail.invitee_infos
end

function ActivityInvitationSeniorData:getInviteeAwarded()
	return self.detail.invitee_awarded
end

function ActivityInvitationSeniorData:getDailySend()
	return self.detail.daily_send
end

function ActivityInvitationSeniorData:getInviterCompletes()
	return self.detail.inviter_completes
end

function ActivityInvitationSeniorData:getInviterAwarded()
	return self.detail.inviter_awarded
end

function ActivityInvitationSeniorData:getWeeklyShare()
	return self.detail.weekly_share
end

function ActivityInvitationSeniorData:getWeeklyShareIsSameWeek()
	local weekly_share = self.detail.weekly_share or 0
	local disTime = xyd.getServerTime() - weekly_share

	if disTime > 0 and disTime < 604800 then
		return true
	end

	return false
end

function ActivityInvitationSeniorData:checkRedPoint()
	if self:getState() == xyd.ActivityInvitationSeniorState.NEW then
		if not self:getInviter() or self:getInviter() == 0 then
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_INVITATION_SENIOR, true)

			return
		end
	end

	if self:getState() == xyd.ActivityInvitationSeniorState.OLD then
		local ids = xyd.tables.activityInvitationOldAwardTable:getIDs()

		for i, id in pairs(ids) do
			local params = xyd.tables.activityInvitationOldAwardTable:getParameter(id)
			local inviter_completes = self:getInviterCompletes()
			local inviter_awarded = self:getInviterAwarded()

			if params[1] < inviter_completes then
				inviter_completes = params[1]
			end

			if params[1] <= inviter_completes then
				if not inviter_awarded[id] or inviter_awarded[id] ~= 1 then
					xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_INVITATION_SENIOR, true)

					return
				end
			end
		end
	end

	if self:getIsShareOpen() and self:getState() == xyd.ActivityInvitationSeniorState.OLD and not self:getWeeklyShareIsSameWeek() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_INVITATION_SENIOR, true)

		return
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_INVITATION_SENIOR, false)
end

function ActivityInvitationSeniorData:getIsUpdateRankState()
	return self.isCanUpdateRank
end

function ActivityInvitationSeniorData:setUpdateRankState(state)
	self.isCanUpdateRank = state

	if state == false then
		self.rankTimeKeyID = xyd.addGlobalTimer(function ()
			self.isCanUpdateRank = true
			self.rankTimeKeyID = nil
		end, 60, 1)
	elseif state == true and self.rankTimeKeyID then
		xyd.removeGlobalTimer(self.rankTimeKeyID)

		self.rankTimeKeyID = nil
	end
end

function ActivityInvitationSeniorData:reqRankInfo()
	if self:getIsUpdateRankState() then
		local msg = messages_pb.get_activity_award_req()
		msg.activity_id = xyd.ActivityID.ACTIVITY_INVITATION_SENIOR
		msg.params = cjson.encode({
			award_type = 7
		})

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
		self:setUpdateRankState(false)

		return true
	else
		return false
	end
end

function ActivityInvitationSeniorData:getRankData()
	for i = 1, #self.rankDataList_ do
		self.rankDataList_[i].rank = i
	end

	local socre = 0

	if self.recordRankSelfScoreArr and self.recordRankSelfScoreArr[1] then
		socre = self.recordRankSelfScoreArr[1]
	end

	local rank = -1

	if self.recordRankSelfScoreArr and self.recordRankSelfScoreArr[2] then
		rank = self.recordRankSelfScoreArr[2]
	end

	local data = {
		list = self.rankDataList_,
		score = socre,
		rank = rank
	}

	return data
end

function ActivityInvitationSeniorData:onGetRankInfo(detail)
	local list = {}

	for index, value in ipairs(detail.list) do
		table.insert(list, {
			player_id = value.player_id,
			player_name = value.player_name,
			avatar_frame = value.avatar_frame_id,
			avatar_id = value.avatar_id,
			server_id = value.server_id,
			dress_style = value.dress_style or {},
			lev = value.lev,
			score = value.score,
			rank = tonumber(index),
			avatarID = value.avatar_id,
			avatar_frame_id = value.avatar_frame_id
		})
	end

	self.rankDataList_ = list
	self.recordRankSelfScoreArr = {
		detail.score,
		detail.rank
	}
end

function ActivityInvitationSeniorData:checkHaveDailyGift()
	local flag = false

	if self:getState() == xyd.ActivityInvitationSeniorState.NEW and self.detail.daily_receive and self.detail.daily_receive > 0 then
		flag = true
	end

	return flag
end

function ActivityInvitationSeniorData:getInviterID()
	return self.detail.inviter
end

function ActivityInvitationSeniorData:reqGetDailyAward()
	if self:checkHaveDailyGift() then
		local msg = messages_pb.get_activity_award_req()
		msg.activity_id = xyd.ActivityID.ACTIVITY_INVITATION_SENIOR
		msg.params = cjson.encode({
			award_type = 3
		})

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
	end
end

function ActivityInvitationSeniorData:onGetDailyAward(event)
	self.detail.daily_receive = 0
	local wnd = xyd.getWindow("main_window")

	if wnd then
		wnd:updateBtnDailyGift()
	end

	local items = xyd.tables.miscTable:split2Cost("invitation_daily_gift", "value", "|#")
	local realItems = {}

	for i = 1, #items do
		local item = items[i]

		table.insert(realItems, {
			item_id = item[1],
			item_num = item[2]
		})
	end

	xyd.itemFloat(realItems)
end

function ActivityInvitationSeniorData:getIsShareOpen()
	local pkgName = XYDDef.PkgName
	local languages = xyd.package2Language[pkgName]

	dump(pkgName, "pkg1")
	dump(languages, "pkg2")

	if UNITY_EDITOR or UNITY_ANDROID and XYDUtils.CompVersion(UnityEngine.Application.version, xyd.ANDROID_INVITE_SHARE_VERSION) >= 0 or UNITY_IOS and languages[1] == "ja_jp" and XYDUtils.CompVersion(UnityEngine.Application.version, xyd.IOS_INVITE_SHARE_VERSION_JP) >= 0 or UNITY_IOS and languages[1] ~= "ja_jp" and XYDUtils.CompVersion(UnityEngine.Application.version, xyd.IOS_INVITE_SHARE_VERSION) >= 0 then
		return true
	end

	return false
end

return ActivityInvitationSeniorData
