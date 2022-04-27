local BaseWindow = import(".BaseWindow")
local ActivityPopularityVoteSurveySkinWindow = class("ActivityPopularityVoteSurveySkinWindow", BaseWindow)

function ActivityPopularityVoteSurveySkinWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinURL = params.skinURL
	self.skinName = params.skinName
end

function ActivityPopularityVoteSurveySkinWindow:initWindow()
	ActivityPopularityVoteSurveySkinWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
end

function ActivityPopularityVoteSurveySkinWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.imgSkin = groupAction:ComponentByName("imgSkin", typeof(UITexture))
	self.labelDesc = groupAction:ComponentByName("labelDesc", typeof(UILabel))
end

function ActivityPopularityVoteSurveySkinWindow:initUIComponent()
	xyd.setUITextureByNameAsync(self.imgSkin, self.skinURL, true)

	self.labelDesc.text = __(self.skinName)
end

return ActivityPopularityVoteSurveySkinWindow
