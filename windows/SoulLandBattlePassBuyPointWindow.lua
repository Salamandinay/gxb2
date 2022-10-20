local BaseWindow = import(".BaseWindow")
local NewTrialBattlepassBuyPointWindow = class("NewTrialBattlepassBuyPointWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")

function NewTrialBattlepassBuyPointWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function NewTrialBattlepassBuyPointWindow:initWindow()
	NewTrialBattlepassBuyPointWindow.super.initWindow(self)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.SOUL_LAND_BATTLE_PASS)

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
	self.titleLabel_.text = __("SOUL_LAND_BATTLEPASS_TEXT09")
	self.scoreBtn_:ComponentByName("button_label", typeof(UILabel)).text = __("CONFIRM")
	self.textInput_ = SelectNum.new(self.selectNumPos, "minmax")

	self.textInput_:setFontSize(26, 26)
	self.textInput_:setKeyboardPos(0, -235)
end

function NewTrialBattlepassBuyPointWindow:updateData()
	self.scoreCanBuy = self.activityData:getRestCanBuy()
	self.hasBuy = self.activityData.detail.buy_times
	self.desLabel_.text = __("SOUL_LAND_BATTLEPASS_TEXT10", self.scoreCanBuy)
end

function NewTrialBattlepassBuyPointWindow:setSelectNum()
	self.cost = self.activityData:getCost()
	local hasNum = xyd.models.backpack:getItemNumByID(self.cost[1])
	local maxNum = self.scoreCanBuy
	self.maxCanBuyNum = math.floor(hasNum / self.cost[2])
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

		xyd.alertYesNo(__("SOUL_LAND_BATTLEPASS_TEXT11", self.costNum_, self.purchaseNum_), function (yes_no)
			if yes_no then
				self.activityData:buyScore(self.purchaseNum_)
				self:close()
			end
		end)
	end
end

function NewTrialBattlepassBuyPointWindow:updateResLabel()
	self.costNum_ = self.purchaseNum_ * self.cost[2]
	self.resLabel_.text = xyd.getRoughDisplayNumber(self.costNum_)
end

return NewTrialBattlepassBuyPointWindow
