local BaseModel = import(".BaseModel")
local DailyQuiz = class("DailyQuiz", BaseModel)
local DailyQuizTable = xyd.tables.dailyQuizTable
local redMark = xyd.models.redMark

function DailyQuiz:ctor()
	DailyQuiz.super.ctor(self)

	self.backpack = xyd.models.backpack
	self.skipReport = false
	self.skipReport = tonumber(xyd.db.misc:getValue("daily_quiz_skip_report")) == 1 and function ()
		return true
	end or function ()
		return false
	end()
end

function DailyQuiz:onRegister()
	DailyQuiz.super.onRegister(self)
	self:registerEvent(xyd.event.GET_QUIZ_LIST, self.onDailyQuizInfo, self)
	self:registerEvent(xyd.event.QUIZ_FIGHT, self.onDailyQuizFight, self)
	self:registerEvent(xyd.event.QUIZ_BUY, self.onDailyQuizBuy, self)
	self:registerEvent(xyd.event.QUIZ_SWEEP, self.onDailyQuizSweep, self)
	self:registerEvent(xyd.event.QUIZ_BUY_AND_SWEEP, self.onDailyQuizBuyAndSweep, self)
	self:registerEvent(xyd.event.FUNCTION_OPEN, function (__, event)
		local funID = event.data.functionID

		if funID == xyd.FunctionID.QUIZ then
			self:reqDailyQuizInfo()
		end
	end, self)
end

function DailyQuiz:reqDailyQuizInfo()
	if self.data_ then
		return
	end

	local msg = messages_pb:get_quiz_list_req()

	xyd.Backend:get():request(xyd.mid.GET_QUIZ_LIST, msg)
end

function DailyQuiz:reqFight(id, partners, petID)
	local params = {
		quiz_id = id,
		partners = partners,
		pet_id = petID
	}
	self.fightParams_ = params
	local msg = messages_pb:quiz_fight_req()
	msg.quiz_id = id

	for _, p in pairs(partners) do
		local fightPartnerMsg = messages_pb.fight_partner()
		fightPartnerMsg.partner_id = p.partner_id
		fightPartnerMsg.pos = p.pos

		table.insert(msg.partners, fightPartnerMsg)
	end

	msg.pet_id = petID

	xyd.Backend:get():request(xyd.mid.QUIZ_FIGHT, msg)
end

function DailyQuiz:nextFight()
	if self.fightParams_ then
		self:reqFight(self.fightParams_.quiz_id, self.fightParams_.partners, self.fightParams_.pet_id)
	end
end

function DailyQuiz:reqBuy(quizType, times)
	local msg = messages_pb:quiz_buy_req()
	msg.quiz_type = quizType
	msg.times = tonumber(times)

	xyd.Backend:get():request(xyd.mid.QUIZ_BUY, msg)
end

function DailyQuiz:reqSweep(id, times)
	local params = {
		quiz_id = id
	}
	self.sweepParams_ = params
	local msg = messages_pb:quiz_sweep_req()
	msg.quiz_id = id
	msg.times = times or 1

	xyd.Backend:get():request(xyd.mid.QUIZ_SWEEP, msg)
end

function DailyQuiz:reqBuyAndSweep(buyTimes)
	local msg = messages_pb:quiz_buy_and_sweep_req()

	for i = 1, 3 do
		table.insert(msg.buy_times, buyTimes[i])
		table.insert(msg.quiz_types, i)

		local data = self:getDataByType(i)

		table.insert(msg.quiz_ids, data.cur_quiz_id)
	end

	xyd.Backend:get():request(xyd.mid.QUIZ_BUY_AND_SWEEP, msg)
end

function DailyQuiz:onDailyQuizBuyAndSweep(event)
	local award = event.data.items
	local awardparams = {}
	local tempItems = {}

	for i = 1, #award do
		if not tempItems[award[i].item_id] then
			tempItems[award[i].item_id] = 0
		end

		tempItems[award[i].item_id] = tempItems[award[i].item_id] + award[i].item_num
	end

	for item_id, item_num in pairs(tempItems) do
		table.insert(awardparams, {
			item_id = item_id,
			item_num = item_num
		})
	end

	table.sort(awardparams, function (a, b)
		return a.item_id < b.item_id
	end)
	xyd.WindowManager:get():openWindow("daily_quiz_crit_award_window", {
		quiz_type = 0,
		data = awardparams
	})

	local newQuizs = event.data.quizzes
	local quizzes = self:getQuizzes()

	for j = 1, #newQuizs do
		local newQuiz = newQuizs[j]

		for i = 1, #quizzes do
			local data = quizzes[i]

			if data.quiz_type == newQuiz.quiz_type then
				quizzes[i] = newQuiz

				break
			end
		end
	end
end

function DailyQuiz:nextSweep()
	if self.sweepParams_ then
		self:reqSweep(self.sweepParams_.quiz_id, 1)
	end
end

function DailyQuiz:onDailyQuizInfo(event)
	self.data_ = event.data

	self:updateRedMark()
end

function DailyQuiz:onDailyQuizFight(event)
	local type_ = event.data.quiz_type
	local data = self:getDataByType(type_)

	if event.data.battle_report.isWin == 1 then
		data.fight_times = data.fight_times + 1
		data.cur_quiz_id = event.data.cur_quiz_id
	end
end

function DailyQuiz:onDailyQuizBuy(event)
	local newQuiz = event.data.quiz
	local quizzes = self:getQuizzes()

	for i = 1, #quizzes do
		local data = quizzes[i]

		if data.quiz_type == newQuiz.quiz_type then
			quizzes[i] = newQuiz

			break
		end
	end
end

function DailyQuiz:onDailyQuizSweep(event)
	local type_ = event.data.quiz_type
	local data = self:getDataByType(type_)
	local cur_fight_times = event.data.fight_times - data.fight_times
	data.fight_times = event.data.fight_times
	local award = event.data.items
	local awardparams = {}

	if cur_fight_times > 1 then
		local tempItems = {}

		for i = 1, #award do
			if not tempItems[award[i].item_id] then
				tempItems[award[i].item_id] = 0
			end

			tempItems[award[i].item_id] = tempItems[award[i].item_id] + award[i].item_num
		end

		for item_id, item_num in pairs(tempItems) do
			table.insert(awardparams, {
				item_id = item_id,
				item_num = item_num
			})
		end

		table.sort(awardparams, function (a, b)
			return a.item_id < b.item_id
		end)
	else
		for i = 1, #award do
			table.insert(awardparams, {
				item_id = award[i].item_id,
				item_num = award[i].item_num
			})
		end
	end

	local wnd = xyd.getWindow("game_assistant_result_window")

	if wnd then
		return
	end

	xyd.WindowManager:get():openWindow("daily_quiz_crit_award_window", {
		data = awardparams,
		quiz_type = type_
	})
end

function DailyQuiz:getDataByType(quizType)
	for _, data in pairs(self:getQuizzes()) do
		if data.quiz_type == quizType then
			return data
		end
	end

	return nil
end

function DailyQuiz:getQuizzes()
	return self:getData().quizzes or {}
end

function DailyQuiz:getData()
	return self.data_ or {}
end

function DailyQuiz:clearData()
	self.data_ = nil
end

function DailyQuiz:getEndTime()
	return self:getData().end_time or 0
end

function DailyQuiz:checkCanFight(id)
	local lv = DailyQuizTable:getLv(id)

	if self.backpack:getLev() < lv then
		return false
	end

	local quizType = xyd.tables.dailyQuizTable:getType(id)

	return self:isHasLeftTimes(quizType)
end

function DailyQuiz:isHasLeftTimes(quizType)
	if quizType == 0 then
		return false
	end

	local leftCount = 0
	local data = self:getDataByType(quizType)

	if data then
		leftCount = data.limit_times - data.fight_times
	end

	return leftCount > 0
end

function DailyQuiz:setSkipReport(flag)
	self.skipReport = flag
	local value = flag and 1 or 0

	xyd.db.misc:setValue({
		key = "daily_quiz_skip_report",
		value = value
	})
end

function DailyQuiz:isSkipReport()
	return self.skipReport
end

function DailyQuiz:isAllMaxLev()
	local flag = true

	for i = 1, 3 do
		local ids = xyd.tables.dailyQuizTable:getIDsByType(i)
		local data = self:getDataByType(i)
		local id = data.cur_quiz_id
		flag = flag and ids[#ids] == data.cur_quiz_id
	end

	return flag
end

function DailyQuiz:updateRedMark()
	local value = xyd.db.misc:getValue("daily_quize_redmark")
	local clickTime = tonumber(value) or 0
	local nowTime = xyd.getServerTime()

	if xyd.isSameDay(clickTime, nowTime) then
		xyd.models.redMark:setMark(xyd.RedMarkType.DAILY_QUIZ, false)
	else
		local hasTimes = false

		for i = 1, 3 do
			if self:isHasLeftTimes(i) then
				hasTimes = true

				break
			end
		end

		if hasTimes then
			xyd.models.redMark:setMark(xyd.RedMarkType.DAILY_QUIZ, true)
		end
	end
end

return DailyQuiz
