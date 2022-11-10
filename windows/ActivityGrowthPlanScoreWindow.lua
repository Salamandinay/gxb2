local BaseWindow = import(".BaseWindow")
local ActivityGrowthPlanScoreWindow = class("ActivityGrowthPlanScoreWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")

function ActivityGrowthPlanScoreWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	if params and params.ActivityID and params.ActivityID == xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN then
		self.id = xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN
	else
		self.id = xyd.ActivityID.ACTIVITY_GROWTH_PLAN
	end

	if self.id == xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN then
		self.preText = "ACTIVITY_NEW_GROWTH_PLAN_TEXT"
	else
		self.preText = "ACTIVITY_GROWTH_PLAN_TEXT"
	end
end

function ActivityGrowthPlanScoreWindow:initWindow()
	ActivityGrowthPlanScoreWindow.super.initWindow(self)

	self.activityData = xyd.models.activity:getActivity(self.id)

	self:getUIComponent()
	self:initUIComponent()
	self:updateData()
	self:setSelectNum()
	self:register()
end

function ActivityGrowthPlanScoreWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.titleLabel_ = groupAction:ComponentByName("titleLabel_", typeof(UILabel))
	self.desLabel_ = groupAction:ComponentByName("desLabel_", typeof(UILabel))
	self.selectNumPos = groupAction:NodeByName("selectNumPos").gameObject
	self.resLabel_ = groupAction:ComponentByName("resGroup/resLabel_", typeof(UILabel))
	self.scoreBtn_ = groupAction:NodeByName("scoreBtn_").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
end

function ActivityGrowthPlanScoreWindow:initUIComponent()
	self.titleLabel_.text = __("ACTIVITY_MISSION_POINT_TEXT13")
	self.scoreBtn_:ComponentByName("button_label", typeof(UILabel)).text = __("CONFIRM")
	self.textInput_ = SelectNum.new(self.selectNumPos, "minmax")

	self.textInput_:setFontSize(26, 26)
	self.textInput_:setKeyboardPos(0, -235)
end

function ActivityGrowthPlanScoreWindow:updateData()
	self.score = self.activityData:getCanResitScore()
	self.desLabel_.text = __(self.preText .. "15", self.score)
end

function ActivityGrowthPlanScoreWindow:setSelectNum()
	if self.id == xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN then
		self.cost = xyd.tables.miscTable:split2num("activity_new_growth_plan_cost", "value", "#")
	else
		self.cost = xyd.tables.miscTable:split2num("activity_growth_plan_cost", "value", "#")
	end

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

function ActivityGrowthPlanScoreWindow:register()
	ActivityGrowthPlanScoreWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.BATTLE_PASS_SP_BUY_POINT, handler(self, self.onComplete))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onComplete))

	UIEventListener.Get(self.scoreBtn_).onClick = function ()
		local cost = self.purchaseNum_ * self.cost[2]
		local hasNum = xyd.models.backpack:getItemNumByID(self.cost[1])

		if hasNum < cost then
			xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH_CRYSTAL"))

			return
		end

		local timeStamp = xyd.db.misc:getValue("activity_growth_plan_score_time_stamp")

		if self.id == xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN then
			timeStamp = xyd.db.misc:getValue("activity_new_growth_plan_score_time_stamp")
		end

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				type = "activity_growth_plan_score",
				wndType = self.curWindowType_,
				callback = function ()
					if self.id == xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN then
						local msg = messages_pb:get_activity_award_req()
						msg.params = require("cjson").encode({
							type = 3,
							point = self.purchaseNum_
						})
						msg.activity_id = self.id
						self.activityData.buyPoint = self.purchaseNum_

						xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
					else
						local msg = messages_pb.battle_pass_sp_buy_point_req()
						msg.activity_id = self.id
						msg.point = self.purchaseNum_
						self.activityData.buyPoint = self.purchaseNum_

						xyd.Backend.get():request(xyd.mid.BATTLE_PASS_SP_BUY_POINT, msg)
					end
				end,
				text = __(self.preText .. "19", cost)
			})
		elseif self.id == xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN then
			local msg = messages_pb:get_activity_award_req()
			msg.params = require("cjson").encode({
				type = 3,
				point = self.purchaseNum_
			})
			msg.activity_id = self.id
			self.activityData.buyPoint = self.purchaseNum_

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
		else
			local msg = messages_pb.battle_pass_sp_buy_point_req()
			msg.activity_id = self.id
			msg.point = self.purchaseNum_
			self.activityData.buyPoint = self.purchaseNum_

			xyd.Backend.get():request(xyd.mid.BATTLE_PASS_SP_BUY_POINT, msg)
		end
	end
end

function ActivityGrowthPlanScoreWindow:updateResLabel()
	self.resLabel_.text = xyd.getRoughDisplayNumber(self.purchaseNum_ * self.cost[2])
end

function ActivityGrowthPlanScoreWindow:onComplete(event)
	xyd.closeWindow("activity_growth_plan_score_window")
end

return ActivityGrowthPlanScoreWindow
