local ActivitySportsGroupWindow = class("ActivitySportsGroupWindow", import(".BaseWindow"))

function ActivitySportsGroupWindow:ctor(name, params)
	ActivitySportsGroupWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.SPORTS)
end

function ActivitySportsGroupWindow:initWindow()
	ActivitySportsGroupWindow.super.initWindow(self)
	self:getComponent()
	self:registerEvent()
	self:layout()
	xyd.models.activity:reqActivityByID(xyd.ActivityID.SPORTS)
end

function ActivitySportsGroupWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.winTitle_ = winTrans:ComponentByName("winTitle", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.awardBtn_ = winTrans:NodeByName("awardBtn").gameObject
	self.awardBtnLabel_ = winTrans:ComponentByName("awardBtn/label", typeof(UILabel))
	self.mineBtn_ = winTrans:NodeByName("mineBtn").gameObject
	self.mineBtnLabel_ = winTrans:ComponentByName("mineBtn/label", typeof(UILabel))
	local flagItemGroup = winTrans:NodeByName("flagItemGroup").gameObject

	for i = 1, 6 do
		self["flagItem" .. i] = flagItemGroup:ComponentByName("flagItem" .. i, typeof(UISprite))
		self["lightImg" .. i] = self["flagItem" .. i]:NodeByName("lightImg").gameObject
		self["flagItemLabel" .. i] = self["flagItem" .. i]:ComponentByName("labelBg/label", typeof(UILabel))
	end
end

function ActivitySportsGroupWindow:registerEvent()
	ActivitySportsGroupWindow.super.register(self)

	UIEventListener.Get(self.mineBtn_).onClick = function ()
		local msg = messages_pb.sports_get_rank_list_req()
		msg.activity_id = xyd.ActivityID.SPORTS
		msg.rank_type = xyd.ActivitySportsRankType["GROUP_POINT_" .. self.activityData.detail.arena_info.group]

		xyd.Backend.get():request(xyd.mid.SPORTS_GET_RANK_LIST, msg)
	end

	UIEventListener.Get(self.awardBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_sports_rank1_window", {
			activityData = self.activityData
		})
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	self.eventProxy_:addEventListener(xyd.event.SPORTS_GET_RANK_LIST, handler(self, self.onGetRankList))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, function ()
		self:updateScore()
	end)
end

function ActivitySportsGroupWindow:onGetRankList(event)
	if event.data.rank_type <= 6 then
		xyd.WindowManager.get():openWindow("activity_sports_rank2_window", {
			eventData = event.data,
			activityData = self.activityData
		})
	end
end

function ActivitySportsGroupWindow:layout()
	self.winTitle_.text = __("ACTIVITY_SPORTS_GROUP_WINDOW")
	self.mineBtnLabel_.text = __("ACTIVITY_SPORTS_GROUP_MY_GROUP")
	self.awardBtnLabel_.text = __("ACTIVITY_SPORTS_GROUP_AWARD_BTN")

	for i = 1, 6 do
		local isSelf = false

		if self.activityData.detail.arena_info.group == i then
			isSelf = true
		end

		xyd.setUISpriteAsync(self["flagItem" .. i], nil, "sports_group_" .. i)
		self["lightImg" .. i]:SetActive(isSelf)

		self["flagItemLabel" .. i].text = self.activityData.detail.all_group_points[i]
	end
end

function ActivitySportsGroupWindow:updateScore()
	for i = 1, 6 do
		self["flagItemLabel" .. i].text = self.activityData.detail.all_group_points[i]
	end
end

return ActivitySportsGroupWindow
