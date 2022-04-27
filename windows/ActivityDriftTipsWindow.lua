local BaseWindow = import(".BaseWindow")
local ActivityDriftTipsWindow = class("ActivityDriftTipsWindow", BaseWindow)

function ActivityDriftTipsWindow:ctor(parentGO, params)
	BaseWindow.ctor(self, parentGO, params)

	self.id = params.id
end

function ActivityDriftTipsWindow:initUI()
	BaseWindow.initUI(self)
	self:getUIComponent()
	self:initUIComponent()
end

function ActivityDriftTipsWindow:getUIComponent()
	local winTrans = self.go.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
end

function ActivityDriftTipsWindow:initUIComponent()
end

return ActivityDriftTipsWindow
