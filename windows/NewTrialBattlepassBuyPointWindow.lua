local BaseWindow = import(".BaseWindow")
local NewTrialBattlepassBuyPointWindow = class("NewTrialBattlepassBuyPointWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")

function NewTrialBattlepassBuyPointWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function NewTrialBattlepassBuyPointWindow:initWindow()
	NewTrialBattlepassBuyPointWindow.super.initWindow(self)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS)

	self:getUIComponent()
	self:initUIComponent()
	self:updateData()
	self:setSelectNum()
	self:register()
end

function NewTrialBattlepassBuyPointWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.titleLabel_ = groupAction:ComponentByName("titleLabel_", typeof(UILabel))
	self.desLabel_ = groupAction:ComponentByName("desLabel_", typeof(UILabel))
	self.selectNumPos = groupAction:NodeByName("selectNumPos").gameObject
	self.resLabel_ = groupAction:ComponentByName("resGroup/resLabel_", typeof(UILabel))
	self.scoreBtn_ = groupAction:NodeByName("scoreBtn_").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
end

function NewTrialBattlepassBuyPointWindow:initUIComponent()
	self.titleLabel_.text = __("NEW_TRIAL_BATTLEPASS_TEXT19")
	self.scoreBtn_:ComponentByName("button_label", typeof(UILabel)).text = __("CONFIRM")
	self.textInput_ = SelectNum.new(self.selectNumPos, "minmax")

	self.textInput_:setFontSize(26, 26)
	self.textInput_:setKeyboardPos(0, -235)
end

function NewTrialBattlepassBuyPointWindow:updateData()
	self.score = self.activityData:getRestCanBuy()
	self.hasBuy = self.activityData.detail.buy_times
	self.desLabel_.text = __("NEW_TRIAL_BATTLEPASS_TEXT18", self.score)
end

function NewTrialBattlepassBuyPointWindow:setSelectNum()
	self.cost = xyd.tables.miscTable:split2num("new_trial_battlepass_point_paid_cost", "value", "#")
	local max_can = tonumber(xyd.tables.miscTable:getVal("new_trial_battlepass_point_paid_limit"))
	local max_can2 = tonumber(xyd.tables.miscTable:getVal("new_trial_battlepass_point_paid_limit2"))
	local max_can3 = tonumber(xyd.tables.miscTable:getVal("new_trial_battlepass_point_paid_limit3"))
	local cost2 = xyd.tables.miscTable:split2num("new_trial_battlepass_point_paid_cost2", "value", "#")
	local cost3 = xyd.tables.miscTable:split2num("new_trial_battlepass_point_paid_cost3", "value", "#")
	local hasNum = xyd.models.backpack:getItemNumByID(self.cost[1])
	local maxNum = self.score

	if self.activityData:checkBuy() and self.activityData:getUpdateTime() - xyd.getServerTime() <= 24 * xyd.HOUR then
		if self.hasBuy < max_can then
			if math.floor(hasNum / self.cost[2]) > max_can - self.hasBuy then
				if math.floor((hasNum - self.cost[2] * (max_can - self.hasBuy)) / cost2[2]) > max_can2 - max_can then
					self.maxCanBuyNum = max_can2 + max_can + math.floor(hasNum - (self.cost[2] * (max_can - self.hasBuy) - cost2[2] * max_can2) / cost3[2])
				else
					self.maxCanBuyNum = max_can + math.floor((hasNum - self.cost[2] * (max_can - self.hasBuy)) / cost2[2])
				end
			else
				self.maxCanBuyNum = math.floor(hasNum / self.cost[2])
			end
		elseif self.hasBuy < max_can2 + max_can then
			if math.floor(hasNum / cost2[2]) > max_can2 - self.hasBuy then
				self.maxCanBuyNum = max_can2 + max_can + math.floor(hasNum - cost2[2] * (max_can2 - self.hasBuy) / cost3[2])
			else
				self.maxCanBuyNum = math.floor(hasNum / cost2[2]) + self.hasBuy
			end
		else
			self.maxCanBuyNum = math.floor(hasNum / cost3[2])
		end
	else
		self.maxCanBuyNum = math.floor(hasNum / self.cost[2])
	end

	self.maxCanBuyNum = math.min(maxNum, self.maxCanBuyNum)
	self.purchaseNum_ = self.maxCanBuyNum

	if self.purchaseNum_ <= 0 then
		self.purchaseNum_ = 1
	end

	local params = {
		minNum = 0,
		curNum = self.purchaseNum_,
		maxNum = maxNum,
		maxCanBuyNum = self.maxCanBuyNum,
		callback = function (input)
			self.purchaseNum_ = tonumber(input)

			self:updateResLabel()
		end
	}

	self.textInput_:setInfo(params)
end

function NewTrialBattlepassBuyPointWindow:register()
	NewTrialBattlepassBuyPointWindow.super.register(self)

	UIEventListener.Get(self.scoreBtn_).onClick = function ()
		local hasNum = xyd.models.backpack:getItemNumByID(self.cost[1])

		if hasNum < self.costNum_ then
			xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH_CRYSTAL"))

			return
		end

		if self.activityData:getRestCanBuy() < self.purchaseNum_ then
			xyd.alertTips(__("FULL_BUY_SLOT_TIME"))

			return
		end

		xyd.alertYesNo(__("NEW_TRIAL_BATTLEPASS_TEXT23", self.costNum_, self.purchaseNum_), function (yes_no)
			if yes_no then
				self.activityData:buyPoint(self.purchaseNum_)
				self:close()
			end
		end)
	end
end

function NewTrialBattlepassBuyPointWindow:updateResLabel()
	local max_can = tonumber(xyd.tables.miscTable:getVal("new_trial_battlepass_point_paid_limit"))
	local max_can2 = tonumber(xyd.tables.miscTable:getVal("new_trial_battlepass_point_paid_limit2"))
	local max_can3 = tonumber(xyd.tables.miscTable:getVal("new_trial_battlepass_point_paid_limit3"))
	local cost2 = xyd.tables.miscTable:split2num("new_trial_battlepass_point_paid_cost2", "value", "#")
	local cost3 = xyd.tables.miscTable:split2num("new_trial_battlepass_point_paid_cost3", "value", "#")

	if self.activityData:checkBuy() and self.activityData:getUpdateTime() - xyd.getServerTime() <= 24 * xyd.HOUR then
		if self.hasBuy < max_can then
			if self.purchaseNum_ + self.hasBuy > max_can + max_can2 then
				self.costNum_ = max_can2 * cost2[2] + (max_can - self.hasBuy) * self.cost[2] + (self.purchaseNum_ + self.hasBuy - max_can - max_can2) * cost3[2]
			elseif max_can < self.purchaseNum_ + self.hasBuy then
				self.costNum_ = (max_can - self.hasBuy) * self.cost[2] + (self.purchaseNum_ + self.hasBuy - max_can) * cost2[2]
			else
				self.costNum_ = self.purchaseNum_ * self.cost[2]
			end
		elseif self.hasBuy < max_can + max_can2 then
			if self.purchaseNum_ + self.hasBuy > max_can + max_can2 then
				self.costNum_ = (max_can + max_can2 - self.hasBuy) * cost2[2] + (self.purchaseNum_ + self.hasBuy - max_can - max_can2) * cost3[2]
			else
				self.costNum_ = self.purchaseNum_ * cost2[2]
			end
		else
			self.costNum_ = self.purchaseNum_ * cost3[2]
		end
	else
		self.costNum_ = self.purchaseNum_ * self.cost[2]
	end

	self.resLabel_.text = xyd.getRoughDisplayNumber(self.costNum_)
end

return NewTrialBattlepassBuyPointWindow
