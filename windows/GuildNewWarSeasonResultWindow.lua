local BaseWindow = import(".BaseWindow")
local GuildNewWarSeasonResultWindow = class("GuildNewWarSeasonResultWindow", BaseWindow)
local cjson = require("cjson")

function GuildNewWarSeasonResultWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.season = params.season or 1
	self.vsIndex = params.vsIndex or 1
	self.isWin = params.isWin
	self.selfRank = params.selfRank or 0
	self.selfPoint = params.selfPoint or 0
	self.guildPoint = params.guildPoint or 0
end

function GuildNewWarSeasonResultWindow:initWindow()
	GuildNewWarSeasonResultWindow.super.initWindow(self)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_NEW_WAR)

	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function GuildNewWarSeasonResultWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.midGroup = self.groupAction:NodeByName("midGroup").gameObject
	self.labelAwardText = self.midGroup:ComponentByName("labelAwardText", typeof(UILabel))
	self.itemGroupGuild = self.midGroup:NodeByName("itemGroupGuild").gameObject
	self.itemGroupGuildLayout = self.midGroup:ComponentByName("itemGroupGuild", typeof(UILayout))
	self.labelGuildPoint = self.midGroup:ComponentByName("labelGuildPoint", typeof(UILabel))
	self.labelTip = self.midGroup:ComponentByName("labelTip", typeof(UILabel))
	self.labelVSIndex = self.midGroup:ComponentByName("labelVSIndex", typeof(UILabel))
	self.imgResult = self.midGroup:ComponentByName("imgResult", typeof(UISprite))
	self.labelTextMyRank = self.midGroup:ComponentByName("labelTextMyRank", typeof(UILabel))
	self.labelTextMyPoint = self.midGroup:ComponentByName("labelTextMyPoint", typeof(UILabel))
	self.labelMyRank = self.midGroup:ComponentByName("labelMyRank", typeof(UILabel))
	self.labelMyPoint = self.midGroup:ComponentByName("labelMyPoint", typeof(UILabel))
	self.titleGroup = self.groupAction:NodeByName("titleGroup").gameObject
	self.seasonCon = self.titleGroup:NodeByName("seasonCon").gameObject
	self.seasonConLayout = self.titleGroup:ComponentByName("seasonCon", typeof(UILayout))
	self.seasonIcon = self.seasonCon:ComponentByName("seasonIcon", typeof(UISprite))
	self.img1 = self.titleGroup:ComponentByName("img1", typeof(UISprite))
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.imgResultBg1 = self.midGroup:ComponentByName("imgResultBg1", typeof(UISprite))
	self.imgResultBg2 = self.midGroup:ComponentByName("imgResultBg2", typeof(UISprite))
end

function GuildNewWarSeasonResultWindow:registerEvent()
end

function GuildNewWarSeasonResultWindow:layout()
	self.labelVSIndex.text = __("GUILD_NEW_WAR_TEXT58", self.vsIndex)
	self.labelTextMyRank.text = __("GUILD_NEW_WAR_TEXT59")
	self.labelMyRank.text = self.selfRank
	self.labelTextMyPoint.text = __("GUILD_NEW_WAR_TEXT60")
	self.labelMyPoint.text = self.selfPoint

	if self.isWin then
		self.labelGuildPoint.text = __("GUILD_NEW_WAR_TEXT61", xyd.tables.miscTable:split2num("guild_new_war_pk_points", "value", "|")[1])
	else
		self.labelGuildPoint.text = __("GUILD_NEW_WAR_TEXT61", xyd.tables.miscTable:split2num("guild_new_war_pk_points", "value", "|")[2])
	end

	self.labelTip.text = __("GUILD_NEW_WAR_TEXT62")
	self.labelAwardText.text = __("GUILD_NEW_WAR_TEXT56")
	local season = tostring(self.season)

	self.seasonIcon.gameObject.transform:SetSiblingIndex(0)

	for i = 1, #season do
		local tmp = NGUITools.AddChild(self.seasonCon.gameObject, self.seasonIcon.gameObject)
		local strNum = string.sub(season, i, i)
		local tmpUISprite = tmp:GetComponent(typeof(UISprite))

		xyd.setUISpriteAsync(tmpUISprite, nil, "guild_new_war2_" .. strNum)
		tmp.transform:SetSiblingIndex(i)
		tmp:SetLocalScale(0.45714285714285713, 0.45714285714285713, 1)
	end

	xyd.setUISpriteAsync(self.seasonIcon, nil, "guild_new_war2_S")
	self.seasonConLayout:Reposition()

	local spriteName = ""
	spriteName = not self.isWin and "battle_lost_common_bg" or "battle_win_common_bg"

	xyd.setUISpriteAsync(self.img1, nil, spriteName)

	spriteName = not self.isWin and "guild_new_war_text_bg_sb" or "guild_new_war_text_bg_sl"

	xyd.setUISpriteAsync(self.imgResultBg1, nil, spriteName)
	xyd.setUISpriteAsync(self.imgResultBg2, nil, spriteName)

	if not self.isWin then
		spriteName = "guild_new_war_text_sb_" .. xyd.Global.lang
	else
		spriteName = "guild_new_war_text_sl_" .. xyd.Global.lang
	end

	xyd.setUISpriteAsync(self.imgResult, nil, spriteName)

	local awards = {}

	if self.isWin then
		awards = xyd.tables.guildNewWarPkAwardsTable:getWinAwards(1)
	else
		awards = xyd.tables.guildNewWarPkAwardsTable:getLoseAwards(1)
	end

	for i = 1, #awards do
		local award = awards[i]
		local params = {
			scale = 0.7222222222222222,
			uiRoot = self.itemGroupGuild,
			itemID = award[1],
			num = award[2]
		}
		local icon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	end

	self.itemGroupGuildLayout:Reposition()
end

return GuildNewWarSeasonResultWindow
