local BaseWindow = import(".BaseWindow")
local GuildNewWarSeasonBeginWindow = class("GuildNewWarSeasonBeginWindow", BaseWindow)
local cjson = require("cjson")

function GuildNewWarSeasonBeginWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.season = params.season or 1
end

function GuildNewWarSeasonBeginWindow:initWindow()
	GuildNewWarSeasonBeginWindow.super.initWindow(self)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_NEW_WAR)

	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function GuildNewWarSeasonBeginWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.midGroup = self.groupAction:NodeByName("midGroup").gameObject
	self.labelAwardText = self.midGroup:ComponentByName("labelAwardText", typeof(UILabel))
	self.imgS = self.midGroup:ComponentByName("imgS", typeof(UISprite))
	self.imgNum = self.midGroup:ComponentByName("imgNum", typeof(UISprite))
end

function GuildNewWarSeasonBeginWindow:registerEvent()
end

function GuildNewWarSeasonBeginWindow:layout()
	self.labelAwardText.text = __("GUILD_NEW_WAR_TEXT05")

	xyd.setUISpriteAsync(self.imgNum, nil, "guild_new_war2_" .. self.season)
	self.activityData:getRedMarkState()
end

return GuildNewWarSeasonBeginWindow
