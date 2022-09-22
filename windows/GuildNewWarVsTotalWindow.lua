local BaseWindow = import(".BaseWindow")
local GuildNewWarVsTotalWindow = class("GuildNewWarVsTotalWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")
local WindowTop = import("app.components.WindowTop")

function GuildNewWarVsTotalWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function GuildNewWarVsTotalWindow:initWindow()
	GuildNewWarVsTotalWindow.super.initWindow(self)

	self.icon1 = {}
	self.icon2 = {}
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_NEW_WAR)

	self.activityData:getCurPeriod()
	self:getUIComponent()
	self:reSize()
	self:registerEvent()
	self:layout()
end

function GuildNewWarVsTotalWindow:reSize()
	self:resizePosY(self.btnGo, -30, -16)
	self:resizePosY(self.btnAward, -12, -123)
	self:resizePosY(self.btnClose, -31, -145)
	self:resizePosY(self.awardGroup, -831, -808)
	self:resizePosY(self.guildGroup, -105, -71)
	self:resizePosY(self.topGroup, -154, -70)
end

function GuildNewWarVsTotalWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.imgBg = self.groupAction:ComponentByName("imgBg", typeof(UITexture))
	self.guildGroup = self.groupAction:NodeByName("guildGroup").gameObject
	self.vsEffectPos = self.guildGroup:ComponentByName("vsEffectPos", typeof(UITexture))
	self.guild1 = self.guildGroup:NodeByName("guild1").gameObject
	self.guild2 = self.guildGroup:NodeByName("guild2").gameObject
	self.awardGroup = self.groupAction:NodeByName("awardGroup").gameObject
	self.titleGroup = self.awardGroup:NodeByName("titleGroup").gameObject
	self.labelAwardTitle = self.titleGroup:ComponentByName("label", typeof(UILabel))
	self.winAward = self.awardGroup:NodeByName("winAward").gameObject
	self.labelWin = self.winAward:ComponentByName("labelWin", typeof(UILabel))
	self.itemGroupWin = self.winAward:NodeByName("itemGroupWin").gameObject
	self.itemGroupWinLayout = self.winAward:ComponentByName("itemGroupWin", typeof(UILayout))
	self.loseAward = self.awardGroup:NodeByName("loseAward").gameObject
	self.labelLose = self.loseAward:ComponentByName("labelLose", typeof(UILabel))
	self.itemGroupLose = self.loseAward:NodeByName("itemGroupLose").gameObject
	self.itemGroupLoseLayout = self.loseAward:ComponentByName("itemGroupLose", typeof(UILayout))
	self.bottomGroup = self.groupAction:NodeByName("bottomGroup").gameObject
	self.btnGo = self.bottomGroup:NodeByName("btnGo").gameObject
	self.labelGo = self.btnGo:ComponentByName("labelGo", typeof(UILabel))
	self.btnClose = self.bottomGroup:NodeByName("btnClose").gameObject
	self.labelClose = self.btnClose:ComponentByName("labelClose", typeof(UILabel))
	self.btnAward = self.bottomGroup:NodeByName("btnAward").gameObject
	self.labelAward = self.btnAward:ComponentByName("labelAward", typeof(UILabel))
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.helpBtn = self.topGroup:NodeByName("helpBtn").gameObject
	self.labelSeason = self.topGroup:ComponentByName("labelSeason", typeof(UILabel))
	self.seasonCon = self.labelSeason:NodeByName("seasonCon").gameObject
	self.seasonConLayout = self.labelSeason:ComponentByName("seasonCon", typeof(UILayout))
	self.seasonIcon = self.seasonCon:ComponentByName("seasonIcon", typeof(UISprite))
	self.titleNameText = self.seasonCon:ComponentByName("titleNameText", typeof(UILabel))
	self.timeGroup = self.topGroup:NodeByName("timeGroup").gameObject
	self.timeGroupLayout = self.topGroup:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel_ = self.timeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.progressGroup = self.topGroup:NodeByName("progressGroup").gameObject
	self.progressBar = self.progressGroup:ComponentByName("progressBar", typeof(UISprite))
	self.progressImg1 = self.progressBar:ComponentByName("progressImg1", typeof(UISprite))
	self.progressImg2 = self.progressBar:ComponentByName("progressImg2", typeof(UISprite))
	self.imgPoint = self.progressBar:ComponentByName("imgPoint", typeof(UISprite))
	self.readyTimeGroup = self.progressGroup:NodeByName("readyTimeGroup").gameObject
	self.readyTimeGroupLayout = self.progressGroup:ComponentByName("readyTimeGroup", typeof(UILayout))
	self.readyTimeDescLabel_ = self.readyTimeGroup:ComponentByName("descLabel_", typeof(UILabel))
	self.readyTimeTimeLabel_ = self.readyTimeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.battleTimeGroup = self.progressGroup:NodeByName("battleTimeGroup").gameObject
	self.battleTimeGroupLayout = self.progressGroup:ComponentByName("battleTimeGroup", typeof(UILayout))
	self.battleTimeDescLabel_ = self.battleTimeGroup:ComponentByName("descLabel_", typeof(UILabel))
	self.battleTimeTimeLabel_ = self.battleTimeGroup:ComponentByName("timeLabel_", typeof(UILabel))
end

function GuildNewWarVsTotalWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data
		local detail = cjson.decode(data.detail)
	end)

	UIEventListener.Get(self.helpBtn.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "GUILD_NEW_WAR_HELP01"
		})
	end

	UIEventListener.Get(self.btnClose.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnGo.gameObject).onClick = function ()
		self.activityData:reqFlagInfo(function ()
			xyd.WindowManager:get():openWindow("guild_new_war_map_window")
		end)
	end

	UIEventListener.Get(self.btnAward.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("guild_new_war_rank_window")
	end
end

function GuildNewWarVsTotalWindow:layout()
	self.data_ = self.activityData:getVsTotalData()
	local record = xyd.db.misc:getValue("guild_new_war_" .. self.activityData:getBeginTime())

	if not record then
		xyd.WindowManager:get():openWindow("guild_new_war_season_begin_window", {
			season = self.activityData:getCurSeason()
		})
		xyd.db.misc:setValue({
			value = 1,
			key = "guild_new_war_" .. self.activityData:getBeginTime()
		})
	end

	self.labelAward.text = __("GUILD_NEW_WAR_TEXT13")
	self.labelWin.text = __("GUILD_NEW_WAR_TEXT14")
	self.labelLose.text = __("GUILD_NEW_WAR_TEXT15")
	self.labelGo.text = __("GUILD_NEW_WAR_TEXT16")
	self.labelAwardTitle.text = __("GUILD_NEW_WAR_TEXT13")
	self.labelClose.text = __("RETURN")
	local season = tostring(self.activityData:getCurSeason())

	self.seasonIcon.gameObject.transform:SetSiblingIndex(0)

	for i = 1, #season do
		local tmp = NGUITools.AddChild(self.seasonCon.gameObject, self.seasonIcon.gameObject)
		local strNum = string.sub(season, i, i)
		local tmpUISprite = tmp:GetComponent(typeof(UISprite))

		xyd.setUISpriteAsync(tmpUISprite, nil, "guild_new_war2_" .. strNum)
		tmp.transform:SetSiblingIndex(i)
		tmp:SetLocalScale(0.4, 0.4, 1)
	end

	xyd.setUISpriteAsync(self.seasonIcon, nil, "guild_new_war2_S")
	self.titleNameText.gameObject.transform:SetSiblingIndex(#season + 1)
	self.seasonConLayout:Reposition()

	local winTop = WindowTop.new(self.window_, self.name_, 1, true)
	local items = {
		{
			id = xyd.ItemID.MANA
		},
		{
			id = xyd.ItemID.CRYSTAL
		}
	}

	winTop:setItem(items)

	self.windowTop = winTop

	self:updateCountDown()
	self:updateGuildInfo()
	self:initAwardGroup()
end

function GuildNewWarVsTotalWindow:updateCountDown()
	local curPeriod, curPeriodEndTime = nil
	curPeriod, curPeriodEndTime = self.activityData:getCurPeriod()
	local nowTime = xyd.getServerTime()
	local duration1 = 0
	local duration2 = 0
	local duration3 = 0

	if curPeriod == xyd.GuildNewWarPeroid.READY1 or curPeriod == xyd.GuildNewWarPeroid.READY2 then
		if curPeriod == xyd.GuildNewWarPeroid.READY1 then
			duration1 = curPeriodEndTime + self.activityData:getFightingTimeDay() * xyd.DAY_TIME - xyd.getServerTime()
		else
			duration1 = curPeriodEndTime + self.activityData:getFightingTimeDay() * xyd.DAY_TIME - xyd.getServerTime()
		end

		duration2 = curPeriodEndTime - xyd.getServerTime()
	elseif curPeriod == xyd.GuildNewWarPeroid.FIGHTING1 or curPeriod == xyd.GuildNewWarPeroid.FIGHTING2 then
		if curPeriod == xyd.GuildNewWarPeroid.FIGHTING1 then
			duration1 = curPeriodEndTime - xyd.getServerTime()
		else
			duration1 = curPeriodEndTime + self.activityData:getNormalRelaxDay() * xyd.DAY_TIME - xyd.getServerTime()
		end

		duration3 = curPeriodEndTime - xyd.getServerTime()
	end

	self.timeGroup:SetActive(duration1 > 0)

	if duration1 > 0 and not self.countDownToNextWar then
		self.countDownToNextWar = CountDown.new(self.timeLabel_, {
			duration = duration1,
			callback = function ()
				self:updateCountDown()
			end
		})

		if curPeriod == xyd.GuildNewWarPeroid.READY1 or curPeriod == xyd.GuildNewWarPeroid.READY2 then
			self.endLabel_.text = __("GUILD_NEW_WAR_TEXT78")
		else
			self.endLabel_.text = __("GUILD_NEW_WAR_TEXT02")
		end

		self.timeGroupLayout:Reposition()
	end

	self.readyTimeGroup:SetActive(duration2 > 0)

	if duration2 > 0 and not self.countDown2 then
		self.countDown2 = CountDown.new(self.readyTimeTimeLabel_, {
			duration = duration2,
			callback = function ()
				self:updateCountDown()
			end
		})
		self.readyTimeDescLabel_.text = __("GUILD_NEW_WAR_TEXT08")

		self.readyTimeGroupLayout:Reposition()
	end

	self.battleTimeGroup:SetActive(duration3 > 0)

	if duration3 > 0 and not self.countDown3 then
		self.countDown3 = CountDown.new(self.battleTimeTimeLabel_, {
			duration = duration3,
			callback = function ()
				self:updateCountDown()
			end
		})
		self.battleTimeDescLabel_.text = __("GUILD_NEW_WAR_TEXT09")

		self.battleTimeGroupLayout:Reposition()
	end

	if duration2 > 0 then
		self.progressImg1.fillAmount = 1 - duration2 / xyd.DAY_TIME
	else
		self.progressImg1.fillAmount = 1
	end

	if duration3 > 0 then
		self.progressImg2.fillAmount = 1 - duration3 / (2 * xyd.DAY_TIME)

		self.imgPoint:SetActive(true)
	else
		self.progressImg2.fillAmount = 0

		self.imgPoint:SetActive(false)
	end
end

function GuildNewWarVsTotalWindow:updateGuildInfo()
	if not self.data_ then
		return
	end

	for i = 1, 2 do
		local info = self.data_.baseInfo[i]
		local guild = self["guild" .. i]
		local labelGuildName = guild:ComponentByName("labelGuildName", typeof(UILabel))
		local flagGuild = guild:ComponentByName("flagGuild", typeof(UISprite))
		local labelPower = guild:ComponentByName("powerInfo/label", typeof(UILabel))
		local labelLeader = guild:ComponentByName("leaderInfo/label", typeof(UILabel))
		local labelPoint = guild:ComponentByName("pointInfo/label", typeof(UILabel))
		labelGuildName.text = info.guildName

		xyd.setUISpriteAsync(flagGuild, nil, xyd.tables.guildIconTable:getIcon(info.flag))

		labelPower.text = xyd.getRoughDisplayNumber(tonumber(info.power))
		labelLeader.text = info.leader
		labelPoint.text = info.point
	end
end

function GuildNewWarVsTotalWindow:initAwardGroup()
	local season = self.activityData:getCurSeason()
	local awards = xyd.tables.guildNewWarPkAwardsTable:getWinAwards(1)

	for i = 1, #awards do
		local award = awards[i]
		local params = {
			scale = 0.7222222222222222,
			uiRoot = self.itemGroupWin,
			itemID = award[1],
			num = award[2]
		}

		if not self.icon1[i] then
			self.icon1[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.icon1[i]:setInfo(params)
		end
	end

	self.itemGroupWinLayout:Reposition()

	awards = xyd.tables.guildNewWarPkAwardsTable:getLoseAwards(1)

	for i = 1, #awards do
		local award = awards[i]
		local params = {
			scale = 0.7222222222222222,
			uiRoot = self.itemGroupLose,
			itemID = award[1],
			num = award[2]
		}

		if not self.icon2[i] then
			self.icon2[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.icon2[i]:setInfo(params)
		end
	end

	self.itemGroupLoseLayout:Reposition()
end

return GuildNewWarVsTotalWindow
