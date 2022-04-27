local TimeCloisterMainWindow = class("TimeCloisterMainWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local timeCloister = xyd.models.timeCloisterModel
local timeCloisterTable = xyd.tables.timeCloisterTable

function TimeCloisterMainWindow:ctor(name, params)
	self.curCloister = 0
	self.hasInit = false

	TimeCloisterMainWindow.super.ctor(self, name, params)
	xyd.models.timeCloisterModel:tryGetTimeCloisterInfo()
	xyd.models.timeCloisterModel:getThreeCardBaseInfo(true)
end

function TimeCloisterMainWindow:initWindow()
	self:getUIComponent()
	self:resizeToParent()
	self:layout()
	self:registerEvent()
	self:checkGuide()
end

function TimeCloisterMainWindow:checkGuide()
	if not xyd.db.misc:getValue("time_cloister_guide") then
		xyd.WindowManager:get():openWindow("exskill_guide_window", {
			wnd = self,
			table = xyd.tables.timeCloisterGuideTable,
			guide_type = xyd.GuideType.TIME_CLOISTER
		})
		xyd.db.misc:setValue({
			value = "1",
			key = "time_cloister_guide"
		})
	end
end

function TimeCloisterMainWindow:resizeToParent()
	self.groupTop:Y(180 + self.scale_num_ * 60)
	self.groupBottom:Y(-210 + self.scale_num_ * 60)
	self.helpBtn:Y(596 - self.scale_num_ * 67)
end

function TimeCloisterMainWindow:getUIComponent()
	local win = self.window_
	self.helpBtn = win:NodeByName("helpBtn").gameObject
	self.groupTop = win:NodeByName("groupTop").gameObject
	self.turnTable = self.groupTop:NodeByName("turnTable").gameObject
	self.cloisterObjectList = {}

	for i = 1, 6 do
		local cloister = self.turnTable:NodeByName("cloister_" .. i).gameObject
		self.cloisterObjectList[i] = {
			numImg = cloister:ComponentByName("numImg", typeof(UISprite)),
			mask = cloister:NodeByName("mask").gameObject,
			lock = cloister:NodeByName("lock").gameObject,
			redPoint = cloister:NodeByName("redPoint").gameObject
		}
	end

	local groupBottom = win:NodeByName("groupBottom").gameObject
	self.groupBottom = groupBottom
	self.titleLabel = groupBottom:ComponentByName("titleLabel", typeof(UILabel))
	self.progressLabel = groupBottom:ComponentByName("progressLabel", typeof(UILabel))
	self.descLabel = groupBottom:ComponentByName("descLabel", typeof(UILabel))
	self.lockLabel = groupBottom:ComponentByName("lockLabel", typeof(UILabel))
	self.stopLabel = groupBottom:ComponentByName("stopLabel", typeof(UILabel))
	self.timeLabel = groupBottom:ComponentByName("timeLabel", typeof(UILabel))
	self.btnAch = groupBottom:NodeByName("btnAch").gameObject
	self.btnAchLabel = self.btnAch:ComponentByName("label", typeof(UILabel))
	self.btnAchRedPoint = self.btnAch:NodeByName("redPoint").gameObject
	self.btnBattle = groupBottom:NodeByName("btnBattle").gameObject
	self.btnBattleLabel = self.btnBattle:ComponentByName("label", typeof(UILabel))
	self.btnBattleRedPoint = self.btnBattle:NodeByName("redPoint").gameObject
	self.btnGo = groupBottom:NodeByName("btnGO").gameObject
	self.btnGoLabel = self.btnGo:ComponentByName("label", typeof(UILabel))
	self.btnStop = groupBottom:NodeByName("btnStop").gameObject
end

function TimeCloisterMainWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function TimeCloisterMainWindow:layout()
	self:initTopGroup()

	self.btnAchLabel.text = __("TIME_CLOISTER_TEXT01")
	self.btnBattleLabel.text = __("TIME_CLOISTER_TEXT02")
	self.stopLabel.text = __("TIME_CLOISTER_TEXT12")

	if timeCloister:getCloisterInfo() then
		self:initContent()
	end
end

function TimeCloisterMainWindow:changeCloister(index)
	self.curCloister = index

	self:updateBottom()
end

function TimeCloisterMainWindow:updateBottom()
	self.titleLabel.text = timeCloisterTable:getName(self.curCloister)
	self.descLabel.text = timeCloisterTable:getDesc(self.curCloister)
	self.btnGoLabel.text = __("TIME_CLOISTER_TEXT03")

	self.btnAch:SetActive(true)
	self.btnBattle:SetActive(true)
	self.btnStop:SetActive(false)
	self.lockLabel:SetActive(false)
	self.stopLabel:SetActive(false)
	self.timeLabel:SetActive(false)
	self.progressLabel:SetActive(true)

	local info = self.cloisterInfo[self.curCloister]

	self:checkGetNextInfo(info)

	self.progressLabel.text = __("TIME_CLOISTER_TEXT04") .. math.floor(info.progress * 100) .. " %"

	if info.state == xyd.CloisterState.UN_OPEN then
		self.descLabel.text = __("TIME_CLOISTER_TEXT05")

		self.btnAch:SetActive(false)
		self.btnBattle:SetActive(false)
		self.progressLabel:SetActive(false)
		xyd.applyChildrenGrey(self.btnGo)
		xyd.setTouchEnable(self.btnGo, false)
	elseif info.state == xyd.CloisterState.LOCK then
		self.progressLabel:SetActive(false)
		self.lockLabel:SetActive(true)

		self.lockLabel.text = __("TIME_CLOISTER_TEXT06", xyd.tables.timeCloisterTable:getName(self.curCloister - 1))

		xyd.applyChildrenGrey(self.btnGo)
		xyd.setTouchEnable(self.btnGo, false)
	elseif info.state == xyd.CloisterState.ON_GOING then
		self.btnStop:SetActive(true)

		self.btnGoLabel.text = __("TIME_CLOISTER_TEXT10")

		xyd.applyChildrenOrigin(self.btnGo)
		xyd.setTouchEnable(self.btnGo, true)

		if not self.countDown then
			self.countDown = import("app.components.CountDown").new(self.timeLabel)
		end

		self.countDown:setInfo({
			duration = timeCloister.leftProbeTime,
			callback = function ()
				info.state = xyd.CloisterState.OVER
				info.stop_time = xyd.getServerTime()

				self:updateBottom()
			end
		})
		self.timeLabel:SetActive(true)
	elseif info.state == xyd.CloisterState.OVER then
		if self.countDown then
			self.countDown:stopTimeCount()
		end

		self.btnGoLabel.text = __("TIME_CLOISTER_TEXT13")

		self.stopLabel:SetActive(true)
		xyd.applyChildrenOrigin(self.btnGo)
		xyd.setTouchEnable(self.btnGo, true)
	else
		xyd.applyChildrenOrigin(self.btnGo)
		xyd.setTouchEnable(self.btnGo, true)
	end

	self:updateRedPoint()
end

function TimeCloisterMainWindow:initContent()
	self.cloisterInfo = timeCloister:getCloisterInfo()
	self.chosenCloister = timeCloister:getChosenCloister()

	if self.hasInit then
		self:updateBottom()
	else
		for i = 1, 6 do
			if self.cloisterInfo[i].state == xyd.CloisterState.UN_OPEN then
				xyd.setUISpriteAsync(self.cloisterObjectList[i].numImg, nil, "time_cloister_" .. i .. "_0")
				self.cloisterObjectList[i].mask:SetActive(true)
				self.cloisterObjectList[i].lock:SetActive(false)
			elseif self.cloisterInfo[i].state == xyd.CloisterState.LOCK then
				xyd.setUISpriteAsync(self.cloisterObjectList[i].numImg, nil, "time_cloister_" .. i .. "_0")
				self.cloisterObjectList[i].mask:SetActive(true)
				self.cloisterObjectList[i].lock:SetActive(true)
			else
				xyd.setUISpriteAsync(self.cloisterObjectList[i].numImg, nil, "time_cloister_" .. i .. "_1")
				self.cloisterObjectList[i].mask:SetActive(false)
				self.cloisterObjectList[i].lock:SetActive(false)
			end
		end

		local default = self.chosenCloister == 0 and 1 or self.chosenCloister
		self.turnTable.transform.localEulerAngles = Vector3(0, 0, -60 * (default - 1))

		self:changeCloister(default)
	end
end

function TimeCloisterMainWindow:updateRedPoint()
	local achRed = timeCloister:getAchieveRedState()
	local battleRed = timeCloister:getBattleRedState()

	self.btnBattleRedPoint:SetActive(battleRed[self.curCloister])
	self.btnAchRedPoint:SetActive(achRed[self.curCloister])

	for i = 1, 6 do
		self.cloisterObjectList[i].redPoint:SetActive(achRed[i] or battleRed[i])
	end

	if self.chosenCloister ~= 0 and self.cloisterInfo[self.chosenCloister].state == xyd.CloisterState.OVER then
		self.cloisterObjectList[self.chosenCloister].redPoint:SetActive(true)
	end
end

function TimeCloisterMainWindow:clickBtnGo()
	if self.isPlayingAnimation then
		return
	end

	if self.chosenCloister == 0 then
		if self.cloisterInfo[self.curCloister].state == xyd.CloisterState.UN_START then
			local function func()
				xyd.WindowManager.get():openWindow("battle_formation_window", {
					showSkip = false,
					battleType = xyd.BattleType.TIME_CLOISTER_PROBE,
					cloister = self.curCloister
				})
			end

			if xyd.db.misc:getValue("time_cloister_hang_tips") then
				func()
			else
				xyd.WindowManager.get():openWindow("time_cloister_hang_tips_window", {
					callback = func
				})
			end
		end
	elseif self.chosenCloister == self.curCloister then
		self:openProbeWindow(self.curCloister)
	else
		xyd.showToast(__("TIME_CLOISTER_TEXT09"))
	end
end

function TimeCloisterMainWindow:clickTurntable()
	if self.isPlayingAnimation then
		return
	end

	local pos = xyd.mouseToLocalPos(self.groupTop.transform)
	local x = pos.x / math.sqrt(pos.x * pos.x + pos.y * pos.y)
	local delta = 0

	if x > 0.5 then
		if pos.y > 0 then
			delta = 2
		else
			delta = 1
		end
	elseif x > -0.5 then
		if pos.y > 0 then
			delta = 3
		else
			delta = 0
		end
	elseif pos.y > 0 then
		delta = 4
	else
		delta = 5
	end

	if delta == 0 then
		return
	end

	local newCloister = self.curCloister + delta

	if newCloister > 6 then
		newCloister = newCloister - 6
	end

	local sequence = self:getSequence()
	self.isPlayingAnimation = true

	sequence:Append(self.turnTable.transform:DOLocalRotate(Vector3(0, 0, -60 * (newCloister - 1)), 0.3))
	sequence:AppendCallback(function ()
		self.isPlayingAnimation = false

		self:changeCloister(newCloister)
		sequence:Kill(false)

		sequence = false
	end)
end

function TimeCloisterMainWindow:onGetHang()
	self.chosenCloister = timeCloister:getChosenCloister()

	self:updateBottom()
end

function TimeCloisterMainWindow:onRedMarkInfo(event)
	local funID = event.data.function_id

	if funID ~= xyd.FunctionID.TIME_CLOISTER then
		return
	end

	self.btnAchRedPoint:SetActive(true)
end

function TimeCloisterMainWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.RED_POINT, handler(self, self.onRedMarkInfo))
	self.eventProxy_:addEventListener(xyd.event.TIME_CLOISTER_INFO, handler(self, self.initContent))
	self.eventProxy_:addEventListener(xyd.event.STOP_HANG, handler(self, self.updateBottom))
	self.eventProxy_:addEventListener(xyd.event.START_HANG, handler(self, self.onGetHang))
	self.eventProxy_:addEventListener(xyd.event.GET_HANG, handler(self, self.onGetHang))
	self.eventProxy_:addEventListener(xyd.event.SPEED_UP_HANG, handler(self, self.updateBottom))
	self.eventProxy_:addEventListener(xyd.event.TIME_CLOISTER_FIGHT, handler(self, self.updateRedPoint))
	self.eventProxy_:addEventListener(xyd.event.GET_TEC_INFO, handler(self, self.openTimeProbeWindowBack))
	self.eventProxy_:addEventListener(xyd.event.TIME_CLOISTER_GET_ACHIEVEMENT_AWARD, handler(self, function ()
		local info = self.cloisterInfo[self.curCloister]

		self:checkGetNextInfo(info)

		self.progressLabel.text = __("TIME_CLOISTER_TEXT04") .. math.floor(info.progress * 100) .. " %"

		self:updateRedPoint()
	end))

	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		if self.isPlayingAnimation then
			return
		end

		xyd.WindowManager.get():openWindow("help_window", {
			key = "TIME_CLOISTER_HELP01"
		})
	end)
	UIEventListener.Get(self.btnAch).onClick = handler(self, function ()
		if self.isPlayingAnimation then
			return
		end

		if self.cloisterInfo[self.curCloister].state == xyd.CloisterState.LOCK then
			xyd.showToast(__("TIME_CLOISTER_TEXT07"))

			return
		end

		timeCloister:reqAchieveInfo(self.curCloister)
		xyd.WindowManager.get():openWindow("time_cloister_achievement_window", {
			cloister = self.curCloister
		})
	end)
	UIEventListener.Get(self.btnBattle).onClick = handler(self, function ()
		if self.isPlayingAnimation then
			return
		end

		if self.cloisterInfo[self.curCloister].state == xyd.CloisterState.LOCK then
			xyd.showToast(__("TIME_CLOISTER_TEXT07"))

			return
		end

		timeCloister:reqTechInfo(self.curCloister)
		timeCloister:reqCloisterInfo(self.curCloister)
		xyd.WindowManager.get():openWindow("time_cloister_battle_window", {
			cloister = self.curCloister
		})
	end)
	UIEventListener.Get(self.btnGo).onClick = handler(self, self.clickBtnGo)
	UIEventListener.Get(self.turnTable).onClick = handler(self, self.clickTurntable)

	UIEventListener.Get(self.btnStop).onClick = function ()
		xyd.alert(xyd.AlertType.YES_NO, __("TIME_CLOISTER_TEXT11"), function (yes)
			if yes then
				timeCloister:reqStopHang()
			end
		end)
	end
end

function TimeCloisterMainWindow:openProbeWindow(cloister)
	if timeCloister:getTechInfoByCloister(cloister) then
		xyd.WindowManager.get():openWindow("time_cloister_probe_window", {
			cloister = cloister
		})
	else
		self.isOpenBattleWindow = true

		timeCloister:reqTechInfo(cloister)
	end
end

function TimeCloisterMainWindow:openTimeProbeWindowBack(event)
	if self.isOpenBattleWindow then
		xyd.WindowManager.get():openWindow("time_cloister_probe_window", {
			cloister = event.data.cloister_id
		})

		self.isOpenBattleWindow = false
	end
end

function TimeCloisterMainWindow:checkGetNextInfo(info)
	local proNum = xyd.tables.miscTable:getNumber("time_cloister_clear", "value")
	local checkMaxNum = 2
	local checkNextId = self.curCloister + 1

	if checkMaxNum >= checkNextId and proNum <= info.progress and self.cloisterInfo[self.curCloister + 1] and self.cloisterInfo[self.curCloister + 1].state == xyd.CloisterState.LOCK then
		timeCloister:reqTimeCloisterInfo(1)
	end
end

function TimeCloisterMainWindow:getCurCloister()
	return self.curCloister
end

return TimeCloisterMainWindow
