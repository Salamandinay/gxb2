local BaseWindow = import(".BaseWindow")
local ActivityExploreOldCampusWaysAlertWindow = class("ActivityExploreOldCampusWaysAlertWindow", BaseWindow)
local skillDetail = import("app.components.ActivityExploreOldCampusWayAlert")
local TYPE_LENGTH = 2

function ActivityExploreOldCampusWaysAlertWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function ActivityExploreOldCampusWaysAlertWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)

	self.itemArr = {}

	self:initUIComponent()
end

function ActivityExploreOldCampusWaysAlertWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupAction = trans:NodeByName("groupAction").gameObject
	self.groupAction_widget = trans:ComponentByName("groupAction", typeof(UIWidget))
end

function ActivityExploreOldCampusWaysAlertWindow:initUIComponent()
	if self.params_.index then
		skillDetail = import("app.components.HeroChallengeFightBossAlert")
		self.skillDetailGroup_ = skillDetail.new(self.groupAction, {
			id = self.params_.buff_id,
			index = self.params_.index,
			isOpen = self.params_.isOpen
		})
	else
		self.skillDetailGroup_ = skillDetail.new(self.groupAction, {
			id = self.params_.buff_id
		})
	end

	if self.params_.posy then
		self.groupAction:Y(self.params_.posy + self.skillDetailGroup_:getActionHeight() + 37.8 - 83)
	end
end

return ActivityExploreOldCampusWaysAlertWindow
