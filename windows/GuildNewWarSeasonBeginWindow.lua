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
	self.seasonCon = self.midGroup:NodeByName("seasonCon").gameObject
	self.seasonConLayout = self.midGroup:ComponentByName("seasonCon", typeof(UILayout))
	self.seasonIcon = self.seasonCon:ComponentByName("seasonIcon", typeof(UISprite))
end

function GuildNewWarSeasonBeginWindow:registerEvent()
end

function GuildNewWarSeasonBeginWindow:layout()
	self.labelAwardText.text = __("GUILD_NEW_WAR_TEXT05")
	local season = tostring(self.season)

	self.seasonIcon.gameObject.transform:SetSiblingIndex(0)

	for i = 1, #season do
		local tmp = NGUITools.AddChild(self.seasonCon.gameObject, self.seasonIcon.gameObject)
		local strNum = string.sub(season, i, i)
		local tmpUISprite = tmp:GetComponent(typeof(UISprite))

		xyd.setUISpriteAsync(tmpUISprite, nil, "guild_new_war2_" .. strNum)
		tmp.transform:SetSiblingIndex(i)
		tmp:SetLocalScale(1, 1, 1)
	end

	xyd.setUISpriteAsync(self.seasonIcon, nil, "guild_new_war2_S")
	self.seasonConLayout:Reposition()
	self.activityData:getRedMarkState()
end

return GuildNewWarSeasonBeginWindow
