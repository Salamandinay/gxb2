local BaseWindow = import(".BaseWindow")
local ArtifactShopWarmUpScoreWindow = class("ArtifactShopWarmUpScoreWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")

function ArtifactShopWarmUpScoreWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function ArtifactShopWarmUpScoreWindow:initWindow()
	ArtifactShopWarmUpScoreWindow.super.initWindow(self)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ARTIFACT_SHOP_WARM_UP)

	self:getUIComponent()
	self:initUIComponent()
	self:updateData()
	self:setSelectNum()
	self:register()
end

function ArtifactShopWarmUpScoreWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.titleLabel_ = groupAction:ComponentByName("titleLabel_", typeof(UILabel))
	self.desLabel_ = groupAction:ComponentByName("desLabel_", typeof(UILabel))
	self.selectNumPos = groupAction:NodeByName("selectNumPos").gameObject
	self.resLabel_ = groupAction:ComponentByName("resGroup/resLabel_", typeof(UILabel))
	self.scoreBtn_ = groupAction:NodeByName("scoreBtn_").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
end

function ArtifactShopWarmUpScoreWindow:initUIComponent()
	self.titleLabel_.text = __("ACTIVITY_MISSION_POINT_TEXT13")
	self.scoreBtn_:ComponentByName("button_label", typeof(UILabel)).text = __("CONFIRM")
	self.textInput_ = SelectNum.new(self.selectNumPos, "minmax")

	self.textInput_:setFontSize(26, 26)
	self.textInput_:setKeyboardPos(0, -235)
end

function ArtifactShopWarmUpScoreWindow:updateData()
	self.score = self.activityData:getCanResitScore()
	self.desLabel_.text = __("ACTIVITY_MISSION_POINT_TEXT10", self.score)
end

function ArtifactShopWarmUpScoreWindow:setSelectNum()
	self.cost = xyd.tables.miscTable:split2num("mission_act_point_exchange", "value", "#")
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

function ArtifactShopWarmUpScoreWindow:register()
	ArtifactShopWarmUpScoreWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.ARTIFACT_SCORE_RESIT, handler(self, self.onComplete))

	UIEventListener.Get(self.scoreBtn_).onClick = function ()
		local cost = self.purchaseNum_ * self.cost[2]
		local hasNum = xyd.models.backpack:getItemNumByID(self.cost[1])

		if hasNum < cost then
			xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH_CRYSTAL"))

			return
		end

		local timeStamp = xyd.db.misc:getValue("artifact_shop_warm_up_time_stamp")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				type = "artifact_shop_warm_up",
				wndType = self.curWindowType_,
				callback = function ()
					local msg = messages_pb.artifact_score_resit_req()
					msg.activity_id = xyd.ActivityID.ARTIFACT_SHOP_WARM_UP
					msg.num = self.purchaseNum_

					xyd.Backend.get():request(xyd.mid.ARTIFACT_SCORE_RESIT, msg)
				end,
				text = __("ACTIVITY_MISSION_POINT_TEXT11", cost)
			})
		else
			local msg = messages_pb.artifact_score_resit_req()
			msg.activity_id = xyd.ActivityID.ARTIFACT_SHOP_WARM_UP
			msg.num = self.purchaseNum_

			xyd.Backend.get():request(xyd.mid.ARTIFACT_SCORE_RESIT, msg)
		end
	end
end

function ArtifactShopWarmUpScoreWindow:updateResLabel()
	self.resLabel_.text = xyd.getRoughDisplayNumber(self.purchaseNum_ * self.cost[2])
end

function ArtifactShopWarmUpScoreWindow:onComplete(event)
	self.activityData.detail.point = event.data.point
	self.activityData.detail.awarded = event.data.awarded

	xyd.closeWindow("artifact_shop_warm_up_score_window")
end

return ArtifactShopWarmUpScoreWindow
