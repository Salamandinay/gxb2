function __TS__Number(value)
	local valueType = type(value)

	if valueType == "number" then
		return value
	elseif valueType == "string" then
		local numberValue = tonumber(value)

		if numberValue then
			return numberValue
		end

		if value == "Infinity" then
			return math.huge
		end

		if value == "-Infinity" then
			return -math.huge
		end

		local stringWithoutSpaces = string.gsub(value, "%s", "")

		if stringWithoutSpaces == "" then
			return 0
		end

		return 0 / 0
	elseif valueType == "boolean" then
		return value and 1 or 0
	else
		return 0 / 0
	end
end

function __TS__FunctionBind(fn, thisArg, ...)
	local boundArgs = {
		...
	}

	return function (____, ...)
		local argArray = {
			...
		}
		local i = 0

		while i < #boundArgs do
			table.insert(argArray, i + 1, boundArgs[i + 1])

			i = i + 1
		end

		return fn(thisArg, unpack or table.unpack(argArray))
	end
end

local ActivityContent = import(".ActivityContent")
local SakuraDate = class("SakuraDate", ActivityContent)

function SakuraDate:ctor(params)
	ActivityContent.ctor(self, params)

	self.boxLabelPrefix = "boxLabel"
	self.boxImagePrefix = "boxImg"
	self.allCompleteNum = 6
	self.skinName = "SakuraDateSkin"
	self.currentState = xyd.Global.lang
	local cost = MiscTable:get():split2Cost("sakura_date_buy_cost", "value", "#")
	self.cost_type = cost[0]
	self.cost_num = __TS__Number(cost[1])
end

function SakuraDate:euiComplete()
	ActivityContent.euiComplete(self)
	self:updateProgress()
	self:setCountDown()
	self:setLabelText()
	self:setBtnText()
	self:setImgSource()
	self:updateEnergy()
	self:registEvent()
end

function SakuraDate:setImgSource()
	self.imgTitle_.source = "sakura_date_text_" .. tostring(xyd.Global.lang) .. "_png"
end

function SakuraDate:getCompleteNumber()
	local cnt = 0
	local tmpStatus = self.activityData.detail.date_status
	local i = 0

	while i < self.allCompleteNum do
		if tmpStatus[i] then
			cnt = cnt + 1
		end

		i = i + 1
	end

	return cnt
end

function SakuraDate:updateProgress()
	self.progress.maximum = self.allCompleteNum
	local curCnt = self:getCompleteNumber()
	self.progress.value = curCnt
	local i = 0

	while i < self.allCompleteNum do
		local id = i
		local label = self[tostring(self.boxLabelPrefix) .. tostring(id)]
		local img = self[tostring(self.boxImagePrefix) .. tostring(id)]
		label.text = String(_G, id + 1)

		if id < curCnt then
			if id < 2 then
				img.source = "activity_jigsaw_icon01_1_png"
			elseif id < 4 then
				img.source = "activity_jigsaw_icon02_1_png"
			else
				img.source = "activity_jigsaw_open_icon_png"
			end
		end

		i = i + 1
	end
end

function SakuraDate:setCountDown()
	if xyd:getServerTime() < self.activityData:getUpdateTime() then
		self.timeLabel:setCountDownTime(self.activityData:getUpdateTime() - xyd:getServerTime())
	else
		self.endLabel.visible = false
		self.timeLabel.visible = false
	end
end

function SakuraDate:setLabelText()
	local str = nil

	if xyd.Global.lang == "en_en" then
		str = __(_G, "END_TEXT")
	else
		str = __(_G, "TEXT_END")
	end

	self.endLabel.text = str
	self.labelStart_.text = __(_G, "SAKURA_START")
	self.labelHasUnlocked_.text = __(_G, "SAKUA_HAS_UNLOCKED")
	self.labelText01_.text = __(_G, "SAKURA_TEXT01")
	self.labelText02_.text = __(_G, "SAKURA_TEXT02")
end

function SakuraDate:setBtnText()
	self.helpBtn.label = __(_G, "ACTIVITY_JIGSAW_RULE")
end

function SakuraDate:updateEnergy()
	self.labelCount_.text = String(_G, self.activityData.detail.energy + self.activityData.detail.recover_energy)
end

function SakuraDate:registEvent()
	self.helpBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		local params = {
			key = "ACTIVITY_SAKURA_HELP",
			title = __(_G, "ACTIVITY_SAKURA_RULE")
		}

		App.WindowManager:openWindow("help_window", params)
	end, self)
	self.plusBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		if self:getBuyTime() <= 0 then
			xyd:showToast(__(_G, "SAKURA_LIMIT"))

			return
		end

		AlertWindow:open(xyd.AlertType.YES_NO, __(_G, "SAKURA_BUY_ENERGY", self.cost_num), function (____, yes_no)
			if yes_no then
				local crystal = Backpack:get():getItemNumByID(self.cost_type)

				if crystal < self.cost_num then
					AlertWindow:open(xyd.AlertType.TIPS, __(_G, "PERSON_NO_CRYSTAL"))

					return
				end

				xyd.Backend:get():request(xyd.mid.BOSS_BUY, {
					num = 1,
					activity_id = self.id
				})
			end
		end)
	end, self)
	self.btnStart_:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		local energy = self.activityData.detail.energy + self.activityData.detail.recover_energy

		if energy <= 0 and self.activityData.detail.is_starting == 0 then
			AlertWindow:open(xyd.AlertType.TIPS, __(_G, "SAKURA_NO_ENERGY"))

			return
		end

		if self.activityData.detail.is_starting == 1 then
			self:onStart()
		else
			xyd.Backend:get():request(xyd.mid.SAKURA_DATE_START, {
				activity_id = self.id
			})
		end
	end, self)
	self.eventProxy_:addEventListener(xyd.event.SAKURA_DATE_START, __TS__FunctionBind(self.onStart, self), self)
	self.eventProxy_:addEventListener(xyd.event.SAVE_SAKURA_DATE, function (____, event)
		self.activityData.detail.current_date_id = event.data.current_date_id
	end)
	self.eventProxy_:addEventListener(xyd.event.SAKURA_DATE_FINISH, function (____, event)
		local data = event.data
		self.activityData.detail.is_starting = data.is_starting
		self.activityData.detail.energy = data.energy
		self.activityData.detail.recover_energy = data.recover_energy
		self.activityData.detail.buy_times = data.buy_times
		self.activityData.detail.current_date_id = 0
		local i = 0

		while i < self.allCompleteNum do
			self.activityData.detail.date_status[i] = data.date_status[i]
			i = i + 1
		end

		self:updateProgress()
		self:updateEnergy()
	end, self)

	local i = 0

	while i < self.allCompleteNum do
		local id = i
		local img = self["boxImg" .. tostring(id)]

		img:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
			App.WindowManager:openWindow("activity_award_preview_window", {
				awards = ActivitySakuraDateAwardTable:get():getAwards(id)
			})
		end, self)

		i = i + 1
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (____, event)
		local data = event.data

		if self.id ~= data.activity_id then
			return
		end

		self:updateEnergy()
		self:updateProgress()
	end)
	self.eventProxy_:addEventListener(xyd.event.BOSS_BUY, function (____, event)
		AlertWindow:open(xyd.AlertType.TIPS, __(_G, "DAILY_QUIZ_BUY_TIPS_3"))

		local data = event.data

		if data.activity_id ~= self.id then
			return
		end

		self.activityData.detail.buy_times = event.data.buy_times
		self.activityData.detail.energy = event.data.energy

		self:updateEnergy()
	end)
end

function SakuraDate:onStart(event)
	if event then
		local data = event.data
		self.activityData.detail.is_starting = data.is_starting
		self.activityData.detail.energy = data.energy
		self.activityData.detail.recover_energy = data.recover_energy

		self:updateEnergy()
	end

	local curId = self.activityData.detail.current_date_id

	if curId == 0 then
		curId = MiscTable:get():getNumber("sakura_date_plot_1st_page", "value")
	end

	App.WindowManager:openWindow("story_window", {
		story_id = curId,
		story_type = xyd.StoryType.PARTNER,
		save_callback = function (____, storyID)
			local nextId = PartnerPlotTable:get():getNext(storyID)

			if nextId == -1 then
				local endPages = MiscTable:get():split("sakura_date_plot_end_pages", "value", "|")
				local ending = -1
				local i = 0

				while i < endPages.length do
					if endPages[i] == storyID then
						ending = i + 1

						break
					end

					i = i + 1
				end

				xyd.Backend:get():request(xyd.mid.SAKURA_DATE_FINISH, {
					activity_id = self.id,
					finish_id = ending
				})
			else
				xyd.Backend:get():request(xyd.mid.SAVE_SAKURA_DATE, {
					activity_id = self.id,
					date_id = storyID
				})
			end
		end
	})
end

function SakuraDate:getBuyTime()
	return MiscTable:get():getNumber("sakura_date_buy_limit", "value") - self:getHasBoughtTime()
end

function SakuraDate:getHasBoughtTime()
	return self.activityData.detail.buy_times
end

return SakuraDate
