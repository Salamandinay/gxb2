local ActivityContent = import(".ActivityContent")
local ActivityLostSpace = class("ActivityLostSpace", ActivityContent)
local json = require("cjson")
local CountDown = import("app.components.CountDown")

function ActivityLostSpace:ctor(parentGO, params, parent)
	ActivityLostSpace.super.ctor(self, parentGO, params, parent)
end

function ActivityLostSpace:getPrefabPath()
	return "Prefabs/Windows/activity/activity_lost_space"
end

function ActivityLostSpace:initUI()
	self:getUIComponent()
	ActivityLostSpace.super.initUI(self)
	self:initUIComponent()
end

function ActivityLostSpace:getUIComponent()
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.goBtn = self.groupAction:NodeByName("goBtn").gameObject
	self.goBtnLabel = self.goBtn:ComponentByName("goBtnLabel", typeof(UILabel))
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.logoTextImg = self.upCon:ComponentByName("logoTextImg", typeof(UISprite))
	self.imgText02 = self.upCon:NodeByName("imgText02").gameObject
	self.imgText02UILayout = self.upCon:ComponentByName("imgText02", typeof(UILayout))
	self.labelTime = self.imgText02:ComponentByName("labelTime", typeof(UILabel))
	self.labelText01 = self.imgText02:ComponentByName("labelText01", typeof(UILabel))
	self.storyBtn = self.upCon:NodeByName("storyBtn").gameObject
	self.helpBtn = self.upCon:NodeByName("helpBtn").gameObject
end

function ActivityLostSpace:onRegister()
	ActivityLostSpace.super.onRegister(self)

	UIEventListener.Get(self.goBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_lost_space_map_window")
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_LOST_SPACE_HELP_TEXT"
		})
	end

	UIEventListener.Get(self.storyBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("story_window", {
			story_id = xyd.tables.miscTable:getNumber("activity_lost_space_plot", "value"),
			story_type = xyd.StoryType.ACTIVITY
		})
	end
end

function ActivityLostSpace:initUIComponent()
	local storyId = xyd.tables.miscTable:getNumber("activity_lost_space_plot", "value")

	if xyd.arrayIndexOf(self.activityData.detail.plots, storyId) < 0 then
		xyd.WindowManager.get():openWindow("story_window", {
			story_id = storyId,
			story_type = xyd.StoryType.ACTIVITY
		})
		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LOST_SPACE, json.encode({
			type = xyd.ActivityLostSpaceType.STORY_OLOT,
			id = storyId
		}))
	end

	self.goBtnLabel.text = __("ACTIVITY_LOST_SPACE_SKILL_START")

	xyd.setUISpriteAsync(self.logoTextImg, nil, "activity_lost_space_logo_" .. xyd.Global.lang)

	if xyd.Global.lang == "fr_fr" then
		self.labelText01.transform:SetSiblingIndex(0)
		self.labelTime.transform:SetSiblingIndex(1)
	end

	self.labelText01.text = __("END")
	local endTime = self.activityData:getEndTime()
	local disTime = endTime - xyd:getServerTime()

	if disTime > 0 then
		local timeCount = CountDown.new(self.labelTime)

		timeCount:setInfo({
			duration = disTime,
			callback = function ()
				self.labelTime.text = "00:00:00"
			end
		})
	else
		self.labelTime.text = "00:00:00"
	end
end

function ActivityLostSpace:resizeToParent()
	ActivityLostSpace.super.resizeToParent(self)
	self:resizePosY(self.upCon.gameObject, 366.5, 456)
	self:resizePosY(self.goBtn.gameObject, -370, -419)
end

return ActivityLostSpace
