local BaseWindow = import(".BaseWindow")
local ActivityResidentReturnSupportScoreWindow = class("ActivityResidentReturnSupportScoreWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")
local cjson = require("cjson")
local ActivityResidentReturnRewardTable = xyd.tables.activityResidentReturnRewardTable

function ActivityResidentReturnSupportScoreWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function ActivityResidentReturnSupportScoreWindow:initWindow()
	ActivityResidentReturnSupportScoreWindow.super.initWindow(self)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_RESIDENT_RETURN)

	self:getUIComponent()
	self:initUIComponent()
	self:updateData()
	self:setSelectNum()
	self:register()
end

function ActivityResidentReturnSupportScoreWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.titleLabel_ = groupAction:ComponentByName("titleLabel_", typeof(UILabel))
	self.desLabel_ = groupAction:ComponentByName("desLabel_", typeof(UILabel))
	self.selectNumPos = groupAction:NodeByName("selectNumPos").gameObject
	self.resLabel_ = groupAction:ComponentByName("resGroup/resLabel_", typeof(UILabel))
	self.scoreBtn_ = groupAction:NodeByName("scoreBtn_").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
end

function ActivityResidentReturnSupportScoreWindow:initUIComponent()
	self.titleLabel_.text = __("ACTIVITY_MISSION_POINT_TEXT13")
	self.scoreBtn_:ComponentByName("button_label", typeof(UILabel)).text = __("CONFIRM")
	self.textInput_ = SelectNum.new(self.selectNumPos, "minmax")

	self.textInput_:setFontSize(26, 26)
	self.textInput_:setKeyboardPos(0, -235)
end

function ActivityResidentReturnSupportScoreWindow:updateData()
	self.score = self.activityData:getReturnSupportCanResitScore()
	self.desLabel_.text = __("ACTIVITY_RETURN2_SUPPORT_TEXT06", self.score)
end

function ActivityResidentReturnSupportScoreWindow:setSelectNum()
	self.cost = xyd.tables.miscTable:split2num("activity_return2_point_exchange", "value", "#")
	local hasNum = xyd.models.backpack:getItemNumByID(self.cost[1])
	local maxNum = self.score
	local maxCanBuyNum = math.floor(hasNum / self.cost[2])
	self.purchaseNum_ = math.min(maxNum, maxCanBuyNum)

	if self.purchaseNum_ <= 0 then
		self.purchaseNum_ = 1
	end

	local params = {
		minNum = 0,
		curNum = self.purchaseNum_,
		maxNum = maxNum,
		maxCanBuyNum = maxCanBuyNum,
		callback = function (input)
			self.purchaseNum_ = tonumber(input)

			self:updateResLabel()
		end
	}

	self.textInput_:setInfo(params)
end

function ActivityResidentReturnSupportScoreWindow:updateResLabel()
	self.resLabel_.text = xyd.getRoughDisplayNumber(self.purchaseNum_ * self.cost[2])
end

function ActivityResidentReturnSupportScoreWindow:register()
	ActivityResidentReturnSupportScoreWindow.super.register(self)

	UIEventListener.Get(self.scoreBtn_).onClick = function ()
		local cost = self.purchaseNum_ * self.cost[2]
		local hasNum = xyd.models.backpack:getItemNumByID(self.cost[1])

		if hasNum < cost then
			xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH_CRYSTAL"))

			return
		end

		local data = cjson.encode({
			num = tonumber(self.purchaseNum_)
		})
		local msg = messages_pb.get_activity_award_req()
		msg.activity_id = xyd.ActivityID.ACTIVITY_RESIDENT_RETURN
		msg.params = data

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
		xyd.closeWindow("activity_resident_return_support_score_window")
	end
end

return ActivityResidentReturnSupportScoreWindow
