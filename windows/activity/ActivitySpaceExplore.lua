local ActivityContent = import(".ActivityContent")
local ActivitySpaceExplore = class("ActivitySpaceExplore", ActivityContent)
local CountDown = import("app.components.CountDown")

function ActivitySpaceExplore:ctor(parentGO, params, parent)
	ActivitySpaceExplore.super.ctor(self, parentGO, params, parent)
	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_SPACE_EXPLORE)
end

function ActivitySpaceExplore:getPrefabPath()
	return "Prefabs/Windows/activity/activity_space_explore"
end

function ActivitySpaceExplore:initUI()
	self:getUIComponent()
	ActivitySpaceExplore.super.initUI(self)
	self:initUIComponent()
end

function ActivitySpaceExplore:getUIComponent()
	self.trans = self.go
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.imgBg = self.groupAction:ComponentByName("imgBg", typeof(UITexture))
	self.leftUpCon = self.groupAction:NodeByName("leftUpCon").gameObject
	self.logoTextImg = self.leftUpCon:ComponentByName("logoTextImg", typeof(UISprite))
	self.imgText02 = self.leftUpCon:NodeByName("imgText02").gameObject
	self.imgText02_UILayout = self.leftUpCon:ComponentByName("imgText02", typeof(UILayout))
	self.labelTime = self.imgText02:ComponentByName("labelTime", typeof(UILabel))
	self.labelText01 = self.imgText02:ComponentByName("labelText01", typeof(UILabel))
	self.centerCon = self.groupAction:NodeByName("centerCon").gameObject
	self.explainLabel = self.centerCon:ComponentByName("explainLabel", typeof(UILabel))
	self.leftDownCon = self.groupAction:NodeByName("leftDownCon").gameObject
	self.progressLabel = self.leftDownCon:ComponentByName("progressLabel", typeof(UILabel))
	self.floorLabel = self.leftDownCon:ComponentByName("floorLabel", typeof(UILabel))
	self.goBtn = self.leftDownCon:NodeByName("goBtn").gameObject
	self.goBtnLabel = self.goBtn:ComponentByName("goBtnLabel", typeof(UILabel))
	self.rightCon = self.groupAction:NodeByName("rightCon").gameObject
	self.personCon = self.rightCon:ComponentByName("personCon", typeof(UITexture))
	self.bubble = self.rightCon:NodeByName("bubble").gameObject
	self.bubble_widget = self.rightCon:ComponentByName("bubble", typeof(UIWidget))
	self.bubbleBg = self.bubble:ComponentByName("bubbleBg", typeof(UISprite))
	self.bubbleLabel = self.bubble:ComponentByName("bubbleLabel", typeof(UILabel))
	self.rightUpCon = self.groupAction:NodeByName("rightUpCon").gameObject
	self.helpBtn = self.rightUpCon:NodeByName("helpBtn").gameObject
	self.awardBtn = self.rightUpCon:NodeByName("awardBtn").gameObject
	self.rankBtn = self.rightUpCon:NodeByName("rankBtn").gameObject
	self.rankBtn_BoxCollider = self.rightUpCon:ComponentByName("rankBtn", typeof(UnityEngine.BoxCollider))
	self.personClickBtn = self.groupAction:NodeByName("personClickBtn").gameObject

	if xyd.Global.lang == "fr_fr" then
		self.explainLabel.width = 172
	end
end

function ActivitySpaceExplore:resizeToParent()
	ActivitySpaceExplore.super.resizeToParent(self)
	self:resizePosY(self.imgBg.gameObject, -92, -5)
end

function ActivitySpaceExplore:initUIComponent()
	xyd.setUISpriteAsync(self.logoTextImg, nil, "activity_space_explore_text_" .. xyd.Global.lang, nil, )

	self.personEffect = xyd.Spine.new(self.personCon.gameObject)

	self.personEffect:setInfo("school_practise_luxifa", function ()
		self.personEffect:play("texiao01", 0)

		local scale = 0.7

		self.personEffect:SetLocalScale(scale, scale, scale)
		self.personEffect:SetLocalPosition(30, -794, 0)
	end)

	self.labelText01.text = __("END")
	local duration = self.activityData:getEndTime() - xyd.getServerTime()

	if duration < 0 then
		self.labelTime.text = "00:00:00"
	else
		local timeCount = import("app.components.CountDown").new(self.labelTime)

		timeCount:setInfo({
			duration = duration,
			callback = handler(self, self.overTime)
		})
	end

	self.imgText02_UILayout:Reposition()

	self.explainLabel.text = __("SPACE_EXPLORE_TEXT_04")
	self.progressLabel.text = __("SPACE_EXPLORE_TEXT_05")
	self.goBtnLabel.text = __("TRAVEL_BUILDING_NAME5")

	self:updateFloorLabel()

	self.chat_index = 1
	self.bubbleLabel.text = __("SPACE_EXPLORE_TEXT_0" .. self.chat_index)
	self.bubble_widget.alpha = 1
	self.chat_active = true

	self:startChatShow()
end

function ActivitySpaceExplore:overTime()
	self.labelTime.text = "00:00:00"

	self.imgText02_UILayout:Reposition()
end

function ActivitySpaceExplore:startChatShow()
	self.chat_time_key = self:waitForTime(5, function ()
		self.bubble_widget.alpha = 0.02
		self.chat_active = false

		self:startChatHide()
	end)
end

function ActivitySpaceExplore:startChatHide()
	self.chat_time_key = self:waitForTime(10, function ()
		self.chat_index = self.chat_index + 1

		if self.chat_index > 3 then
			self.chat_index = 1
		end

		self.bubbleLabel.text = __("SPACE_EXPLORE_TEXT_0" .. self.chat_index)
		self.bubble_widget.alpha = 1
		self.chat_active = true

		self:startChatShow()
	end)
end

function ActivitySpaceExplore:onRegister()
	ActivitySpaceExplore.super.onRegister(self)

	UIEventListener.Get(self.personClickBtn.gameObject).onClick = handler(self, function ()
		if self.chat_time_key ~= -1 then
			XYDCo.StopWait(self.chat_time_key)

			self.chat_time_key = -1
		end

		self.chat_index = self.chat_index + 1

		if self.chat_index > 3 then
			self.chat_index = 1
		end

		self.bubbleLabel.text = __("SPACE_EXPLORE_TEXT_0" .. self.chat_index)

		if not self.chat_active then
			self.bubble_widget.alpha = 1
			self.chat_active = true
		end

		self:startChatShow()
	end)
	UIEventListener.Get(self.goBtn.gameObject).onClick = handler(self, function ()
		self:clickToMap()
	end)
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SPACE_EXPLORE_HELP_01"
		})
	end)
	UIEventListener.Get(self.awardBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_space_explore_check_award_window")
	end)
	UIEventListener.Get(self.rankBtn.gameObject).onClick = handler(self, function ()
		self.rankBtn_BoxCollider.enabled = false
		local msg = messages_pb:space_explore_get_rank_list_req()
		msg.activity_id = self.id

		xyd.Backend.get():request(xyd.mid.SPACE_EXPLORE_GET_RANK_LIST, msg)
		self:waitForTime(0.5, function ()
			self.rankBtn_BoxCollider.enabled = true
		end)
	end)

	self:registerEvent(xyd.event.SPACE_EXPLORE_GET_RANK_LIST, handler(self, self.onRankListBack))
end

function ActivitySpaceExplore:clickToMap()
	xyd.WindowManager.get():openWindow("activity_space_explore_map_window")
end

function ActivitySpaceExplore:mapCloseBack()
	self:updateFloorLabel()
	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_SPACE_EXPLORE)
end

function ActivitySpaceExplore:updateFloorLabel()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPACE_EXPLORE)
	local ids = xyd.tables.activitySpaceExploreMapTable:getIds()

	if self.activityData.detail.stage_id > #ids then
		self.floorLabel.text = __("SPACE_EXPLORE_TEXT_06", #ids)

		return
	end

	self.floorLabel.text = __("SPACE_EXPLORE_TEXT_06", self.activityData.detail.stage_id)
end

function ActivitySpaceExplore:onRankListBack(event)
	self.rankBtn_BoxCollider.enabled = true

	xyd.WindowManager.get():openWindow("new_dress_rank_window", {
		rank_info = event.data
	})
end

return ActivitySpaceExplore
