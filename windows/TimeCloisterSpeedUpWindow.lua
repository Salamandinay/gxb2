local TimeCloisterSpeedUpWindow = class("TimeCloisterSpeedUpWindow", import(".BaseWindow"))
local SelectNum = import("app.components.SelectNum")
local timeCloister = xyd.models.timeCloisterModel

function TimeCloisterSpeedUpWindow:ctor(name, params)
	self.info = params.info

	TimeCloisterSpeedUpWindow.super.ctor(self, name, params)

	self.speedOneToTime = xyd.tables.miscTable:split2num("time_cloister_time_accelerata", "value", "|")[2]
end

function TimeCloisterSpeedUpWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function TimeCloisterSpeedUpWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel = groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.descLabel = groupAction:ComponentByName("descLabel", typeof(UILabel))
	self.itemRoot = groupAction:NodeByName("itemRoot").gameObject
	local selectNumRoot = groupAction:NodeByName("selectNumRoot").gameObject
	self.selectNum = SelectNum.new(selectNumRoot, "minmax")
	self.timeGroup = groupAction:NodeByName("timeGroup").gameObject
	self.labelEnd = self.timeGroup:ComponentByName("labelEnd", typeof(UILabel))
	self.labelTime = self.timeGroup:ComponentByName("labelTime", typeof(UILabel))
	self.btnSure = groupAction:NodeByName("btnSure").gameObject
	self.btnSureLabel = self.btnSure:ComponentByName("label", typeof(UILabel))
end

function TimeCloisterSpeedUpWindow:layout()
	self.titleLabel.text = __("TIME_CLOISTER_TEXT14")

	if xyd.Global.lang == "ko_kr" then
		self.descLabel.fontSize = 22
	elseif xyd.Global.lang == "de_de" then
		self.descLabel.fontSize = 20
	elseif xyd.Global.lang ~= "zh_tw" then
		self.descLabel.fontSize = 18
	end

	self.descLabel.text = __("TIME_CLOISTER_TEXT15")
	self.btnSureLabel.text = __("SURE")
	self.labelEnd.text = __("TIME_CLOISTER_TEXT16")
	self.timeCount = import("app.components.CountDown").new(self.labelTime, {
		duration = timeCloister.leftProbeTime
	})
	local speedUp = xyd.split(xyd.tables.miscTable:getVal("time_cloister_time_accelerata"), "|", true)
	self.itemID = speedUp[1]
	self.perTime = speedUp[2]
	local itemNum = xyd.models.backpack:getItemNumByID(self.itemID)
	self.item = xyd.getItemIcon({
		uiRoot = self.itemRoot,
		itemID = self.itemID,
		num = itemNum
	})
	self.buyNum = 0
	local params = {
		minNum = 1,
		curNum = 1,
		maxNum = itemNum,
		maxCanBuyNum = math.ceil(timeCloister.leftProbeTime / self.perTime),
		callback = function (input)
			self.buyNum = math.min(input, itemNum)

			self:setTime()
		end
	}

	self.selectNum:setInfo(params)
	self.selectNum:setFontSize(26)
	self.selectNum:setBtnPos(152)
	self.selectNum:setMaxAndMinBtnPos(226)
	self.selectNum:setKeyboardPos(0, -200)
end

function TimeCloisterSpeedUpWindow:setTime()
	self.timeCount:setInfo({
		duration = timeCloister.leftProbeTime - self.buyNum * self.perTime
	})
end

function TimeCloisterSpeedUpWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnSure).onClick = function ()
		local energy = timeCloister:getHangInfo().energy

		print("testtest", energy)

		local cradJumpTimeDis = xyd.tables.miscTable:getNumber("time_cloister_card_time", "value")
		local cradEnergyTime = xyd.tables.miscTable:getNumber("time_cloister_energy_time", "value")

		if math.floor(energy * cradEnergyTime + 0.05) < cradJumpTimeDis then
			timeCloister:setOver()
			self:close()

			return
		end

		if self.buyNum == 0 then
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.itemID)))
		elseif timeCloister.leftProbeTime <= 0 then
			xyd.showToast(__("TIME_CLOISTER_TEXT17"))
		elseif self.buyNum > 0 then
			timeCloister:setSpeedMorePropTips(false)

			local realMax = math.ceil(timeCloister.leftProbeTime / self.perTime)
			local sendNum = math.min(self.buyNum, realMax)
			local leftTime = math.floor(energy * cradEnergyTime + 0.05) - (sendNum - 1) * self.speedOneToTime

			if cradJumpTimeDis > leftTime then
				sendNum = sendNum - 1

				timeCloister:setSpeedMorePropTips(true)
			end

			xyd.models.timeCloisterModel:reqSpeedUpHang(sendNum)
			xyd.models.timeCloisterModel:setSpeedUpNum(sendNum)
		end

		self:close()
	end
end

return TimeCloisterSpeedUpWindow
