local BaseModel = import(".BaseModel")
local Trial = class("Trial", BaseModel, true)
Trial.____getters = {}

function Trial:ctor()
	BaseModel.ctor(self)

	self.skipReport = false
	self.status = {}
	self.enemies_ = {}
	self.rankDataLis_ = {}
	self.rankReqTime_ = {}
	self.defaultRedPoint_ = true
	self.skipReport = xyd.db.misc:getValue("trial_skip_report")

	if tonumber(self.skipReport) == 1 then
		self.skipReport = true
	else
		self.skipReport = false
	end

	self.isReport = false
end

function Trial:isSkipReport()
	return self.skipReport
end

function Trial:setIsReport(flag)
	self.isReport = flag
end

function Trial:getIsReport()
	return self.isReport
end

function Trial.____getters:currentStage()
	return self.current_stage
end

function Trial.____getters:enemy()
	return self.enemy_
end

function Trial.____getters:enemies()
	return self.enemies_
end

function Trial:get()
	if Trial.INSTANCE == nil then
		Trial.INSTANCE = Trial.new()

		Trial.INSTANCE:onRegister()
	end

	return Trial.INSTANCE
end

function Trial:reset()
	if Trial.INSTANCE then
		Trial.INSTANCE:removeEvents()
	end

	Trial.INSTANCE = nil
end

function Trial:onRegister()
	BaseModel.onRegister(self)
	self:registerEvent(xyd.event.GET_TRIAL_INFO, handler(self, self.onTrialInfo))
	self:registerEvent(xyd.event.TRIAL_START, handler(self, self.onTrialStart))
	self:registerEvent(xyd.event.NEW_TRIAL_FIGHT, handler(self, self.onTrialFight))
	self:registerEvent(xyd.event.TRIAL_AWARD, handler(self, self.onTrialAward))
	self:registerEvent(xyd.event.TRIAL_GET_RANK_LIST, handler(self, self.onTrialRankData))
	self:registerEvent(xyd.event.SYSTEM_REFRESH, handler(self, self.systemRefresh))
	self:registerEvent(xyd.event.FUNCTION_OPEN, function (event)
		local funID = event.data.functionID

		if funID == xyd.FunctionID.TRIAL then
			self:reqTrialInfo()
		end
	end)
end

function Trial:onTrialRankData(event)
	if self.tempReqBoss_ then
		self.rankDataLis_[self.tempReqBoss_] = xyd.decodeProtoBuf(event.data)
		self.tempReqBoss_ = nil
	end
end

function Trial:getRankData(boss_id)
	return self.rankDataLis_[boss_id]
end

function Trial:reqRankInfo(boss_id)
	if not self.rankReqTime_[boss_id] or xyd.getServerTime() - self.rankReqTime_[boss_id] > 180 then
		local msg = messages_pb.trial_get_rank_list_req()
		msg.boss_id = boss_id

		xyd.Backend:get():request(xyd.mid.TRIAL_GET_RANK_LIST, msg)

		self.tempReqBoss_ = boss_id
		self.rankReqTime_[boss_id] = xyd.getServerTime()

		return true
	else
		return false
	end
end

function Trial:reqTrialInfo()
	local msg = messages_pb.get_trial_info_req()

	xyd.Backend:get():request(xyd.mid.GET_TRIAL_INFO, msg)
end

function Trial:getData()
	return self.data_
end

function Trial.getBossRewardLev()
	local arr = xyd.tables.miscTable:split2num("trial_boss_levs", "value", "|")

	for i = 1, #arr - 1 do
		if xyd.models.backpack:getLev() < arr[i] then
			return i
		end
	end

	return #arr
end

function Trial:updateData(data)
	dump(data, "data")
	self:onTrialInfo({
		data = data
	})
end

function Trial:onTrialInfo(event)
	__TRACE("===========onTrialInfo=============")

	local data = event.data
	local infos = {
		current_stage = data.current_stage,
		start_time = data.start_time,
		end_time = data.end_time or 0,
		is_open = data.is_open,
		current_award = data.current_award or 0,
		enemy = data.enemy,
		partner_status = data.partner_status,
		enemies = data.enemies,
		buff_rewards = data.buff_rewards,
		buff_ids = data.buff_ids
	}

	if data.boss_id and data.boss_id > 0 then
		infos.boss_id = data.boss_id
	elseif self.data_ and tonumber(self.data_.boss_id) and self.data_.boss_id > 0 then
		infos.boss_id = self.data_.boss_id
	end

	self.data_ = infos
	self.current_stage = infos.current_stage
	self.enemy_ = infos.enemy
	self.enemies_ = infos.enemies
	self.status = {}
	local partner_status = infos.partner_status

	dump(infos, "infos")
	XYDCo.StopWait("new_trial_req_info")

	if self.data_.is_open == 1 and xyd.getServerTime() - self.data_.start_time < 169200 then
		if self.data_.end_time - xyd.getServerTime() > 0 then
			XYDCo.WaitForTime(self.data_.end_time - xyd.getServerTime(), function ()
				local win = xyd.WindowManager.get():getWindow("trial_window")

				if win then
					win:close()
				end

				self:reqTrialInfo()
			end, "new_trial_req_info")
		end
	elseif self.data_.end_time + 3600 - xyd.getServerTime() > 0 then
		XYDCo.WaitForTime(self.data_.end_time + 3600 - xyd.getServerTime(), function ()
			self:reqTrialInfo()
		end, "new_trial_req_info")
	end

	if not partner_status then
		return
	end

	for i = 1, #partner_status do
		local d = partner_status[i]
		self.status[d.partner_id] = d.hp
	end
end

function Trial:checkClose()
	local timeOpen = xyd.tables.miscTable:getVal("new_trial_restart_open_time")
	local time1 = xyd.tables.miscTable:getVal("new_trial_restart_close_time")
	local time2 = xyd.tables.miscTable:getVal("new_trial_restart_close_time2")

	if tonumber(timeOpen) <= xyd.getServerTime() then
		return false
	end

	if tonumber(time1) <= xyd.getServerTime() then
		return true
	elseif tonumber(time2) <= xyd.getServerTime() and (not self.data_.is_open or self.data_.is_open == 0) then
		return true
	end

	return false
end

function Trial:onTrialStart(event)
	self.current_stage = event.data.current_stage
	self.data_.current_stage = event.data.current_stage
	self.data_.enemy = event.data.enemy
	self.enemy_ = event.data.enemy
end

function Trial:getTableUse()
	if self.data_ and self.data_.boss_id and self.data_.boss_id == 2 then
		return xyd.tables.newTrialStageSeaTable
	else
		return xyd.tables.newTrialStageTable
	end
end

function Trial:onTrialFight(event)
	if not event.data.battle_report then
		return
	end

	local is_win = event.data.is_win
	local partner_status = event.data.partner_status

	if partner_status then
		for i = 1, #partner_status do
			local d = partner_status[i]
			self.status[d.partner_id] = d.hp
		end
	end

	self.needUpdateBattlePassPoint_ = true
	self.enemy_ = event.data.info.enemy
end

function Trial:checkUpdateBattlePass()
	if self.needUpdateBattlePassPoint_ then
		self.needUpdateBattlePassPoint_ = nil

		xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS)
	end
end

function Trial:onTrialAward(event)
	self.data_.current_award = event.data.current_award
end

function Trial:reqFight(partners, petID)
	local msg = messages_pb:trial_fight_req()

	for i = 1, #partners do
		local p = partners[i]
		local fight_partner = messages_pb:fight_partner()
		fight_partner.partner_id = p.partner_id
		fight_partner.pos = p.pos

		table.insert(msg.partners, fight_partner)
	end

	msg.pet_id = petID

	xyd.Backend:get():request(xyd.mid.TRIAL_FIGHT, msg)
end

function Trial:getBossId()
	return self.data_.boss_id
end

function Trial:startReq()
	if self.current_stage and self.current_stage > 0 and self.current_stage <= 15 then
		return
	end

	local msg = messages_pb.trial_start_req()

	xyd.Backend:get():request(xyd.mid.TRIAL_START, msg)
end

function Trial:reqAward()
	xyd.Backend:get():request(xyd.mid.TRIAL_AWARD)
end

function Trial:getHp(partnerID)
	if self.status[partnerID] or self.status[partnerID] == 0 then
		return self.status[partnerID]
	end

	return 100
end

function Trial:currentStage()
	return self.current_stage
end

function Trial:checkIsOpen()
	if self.data_.is_open == 1 and xyd.getServerTime() < self.data_.end_time then
		return true
	elseif self.data_.is_open == 0 and self.data_.start_time <= xyd.getServerTime() then
		return true
	end

	return false
end

function Trial:setRedMark()
	if not self.data_ then
		return
	end

	if self.data_.is_open == 1 then
		local lastTime = xyd.db.misc:getValue("trial_last_time")

		if not lastTime or tonumber(self.data_.end_time) ~= tonumber(lastTime) then
			local redMark = self:checkFunctionOpen() and self.defaultRedPoint_

			xyd.models.redMark:setMark(xyd.RedMarkType.TRIAL, redMark)
		else
			xyd.models.redMark:setMark(xyd.RedMarkType.TRIAL, false)
		end
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.TRIAL, false)
	end
end

function Trial:setDefaultRedMark()
	self.defaultRedPoint_ = false

	self:setRedMark()

	if self.data_ and self.data_.is_open then
		local lastTime = xyd.db.misc:getValue("trial_last_time")

		if not lastTime or self.data_.end_time ~= lastTime then
			xyd.db.misc:addOrUpdate({
				key = "trial_last_time",
				value = self.data_.end_time
			})
		end
	end
end

function Trial:systemRefresh()
	self:reqTrialInfo()
end

function Trial:setSkipReport(flag)
	self.skipReport = flag
	local value = nil

	if flag then
		value = 1
	else
		value = 0
	end

	xyd.db.misc:addOrUpdate({
		key = "trial_skip_report",
		value = value
	})
end

function Trial:isSkipReport()
	return self.skipReport
end

function Trial:checkFunctionOpen()
	if xyd.checkFunctionOpen(xyd.FunctionID.TRIAL, true) == true and not self.data_ then
		self:reqTrialInfo()
	end

	return xyd.checkFunctionOpen(xyd.FunctionID.TRIAL, true)
end

return Trial
