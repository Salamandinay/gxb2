local GuildNewWarMainRankWindow = class("GuildNewWarMainRankWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")

function GuildNewWarMainRankWindow:ctor(name, params)
	GuildNewWarMainRankWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_NEW_WAR)
	self.state = params.state
	self.guildInfo = params.guildInfo

	dump(params.guildInfo, "test1111")
end

function GuildNewWarMainRankWindow:initWindow()
	self:getUIComponent()
	GuildNewWarMainRankWindow.super.initWindow(self)
	self:reSize()
	self:registerEvent()
	self:layout()
end

function GuildNewWarMainRankWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.nav = self.groupAction:NodeByName("nav").gameObject
	self.btnCon = self.groupAction:NodeByName("btnCon").gameObject
	self.backBtn = self.btnCon:NodeByName("backBtn").gameObject
	self.awardBtn = self.btnCon:NodeByName("awardBtn").gameObject
	self.awardBtnIcon = self.awardBtn:NodeByName("awardBtnIcon").gameObject
	self.awardBtnLabel = self.awardBtn:ComponentByName("awardBtnLabel", typeof(UILabel))
	self.awardBtnRed = self.awardBtn:NodeByName("awardBtnRed").gameObject
	self.titleGroup = self.groupAction:NodeByName("titleGroup").gameObject
	self.titleConPanel = self.titleGroup:NodeByName("titleConPanel").gameObject
	self.titleBtnCon = self.titleConPanel:NodeByName("btnCon").gameObject
	self.helpBtn = self.titleBtnCon:NodeByName("helpBtn").gameObject
	self.titleCon = self.titleConPanel:NodeByName("titleCon").gameObject
	self.titleBg = self.titleCon:ComponentByName("titleBg", typeof(UISprite))
	self.seasonCon = self.titleCon:NodeByName("seasonCon").gameObject
	self.seasonConUILayout = self.titleCon:ComponentByName("seasonCon", typeof(UILayout))
	self.seasonIcon = self.seasonCon:ComponentByName("seasonIcon", typeof(UISprite))
	self.titleNameText = self.seasonCon:ComponentByName("titleNameText", typeof(UILabel))
	self.timeCon = self.titleConPanel:NodeByName("timeCon").gameObject
	self.timeConUILayout = self.titleConPanel:ComponentByName("timeCon", typeof(UILayout))
	self.timeDescText = self.timeCon:ComponentByName("timeDescText", typeof(UILabel))
	self.timeNumText = self.timeCon:ComponentByName("timeNumText", typeof(UILabel))
	self.guildCon = self.groupAction:NodeByName("guildCon").gameObject
	self.personCon = self.groupAction:NodeByName("personCon").gameObject
	self.recordCon = self.groupAction:NodeByName("recordCon").gameObject
end

function GuildNewWarMainRankWindow:reSize()
	self:resizePosY(self.titleGroup.gameObject, 524, 605)
	self:resizePosY(self.btnCon, -559, -676)
	self:resizePosY(self.nav, -465, -580)
	self:reSizeGuildItem()
	self:reSizePersonItem()
	self:reSizeRecordItem()
end

function GuildNewWarMainRankWindow:reSizeGuildItem()
	local upCon = self.guildCon:NodeByName("upCon").gameObject
	local downCon = self.guildCon:NodeByName("downCon").gameObject
	local downConBgGroup = downCon:NodeByName("downConBgGroup").gameObject
	local tipsNone = downCon:NodeByName("tipsNone").gameObject

	self:resizePosY(tipsNone.gameObject, 147, 107)
	self:resizePosY(upCon.gameObject, 346, 427)
	self:resizePosY(downCon.gameObject, -227, -146)

	downConBgGroup:GetComponent(typeof(UIWidget)).height = 810 + 199 * self.scale_num_contrary
end

function GuildNewWarMainRankWindow:reSizePersonItem()
	local upCon = self.personCon:NodeByName("upCon").gameObject
	local downCon = self.personCon:NodeByName("downCon").gameObject
	local downConBgGroup = downCon:NodeByName("downConBgGroup").gameObject
	local tipsNone = downCon:NodeByName("tipsNone").gameObject

	self:resizePosY(tipsNone.gameObject, 147, 107)
	self:resizePosY(upCon.gameObject, 346, 427)
	self:resizePosY(downCon.gameObject, -227, -146)

	downConBgGroup:GetComponent(typeof(UIWidget)).height = 810 + 199 * self.scale_num_contrary
end

function GuildNewWarMainRankWindow:reSizeRecordItem()
	local downCon = self.recordCon:NodeByName("downCon").gameObject
	local downConBgGroup = downCon:NodeByName("downConBgGroup").gameObject
	local tipsNone = downCon:NodeByName("tipsNone").gameObject

	self:resizePosY(tipsNone.gameObject, 237, 237)
	self:resizePosY(downConBgGroup.gameObject, 620, 702)

	downConBgGroup:GetComponent(typeof(UIWidget)).height = 1135 + 202 * self.scale_num_contrary
end

function GuildNewWarMainRankWindow:registerEvent()
	UIEventListener.Get(self.backBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.awardBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("guild_new_war_rank_window")
	end)
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "GUILD_NEW_WAR_HELP01"
		})
	end)
end

function GuildNewWarMainRankWindow:layout()
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

	self:initTop()
	self:initNav()
	self:initSeason()
	self:initTimeShow()

	self.guildItem = import("app.components.GuildNewWarMainRankGuildItem").new(self.guildCon.gameObject, self, self.guildInfo)
end

function GuildNewWarMainRankWindow:initSeason()
	self.titleNameText.text = ""
	self.awardBtnLabel.text = __("GUILD_NEW_WAR_TEXT21")
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
	self.seasonConUILayout:Reposition()
end

function GuildNewWarMainRankWindow:initTop()
	self.windowTop = WindowTop.new(self.window_, self.name_, 50)
	local items = {
		{
			id = xyd.ItemID.MANA
		},
		{
			id = xyd.ItemID.CRYSTAL
		}
	}

	self.windowTop:setItem(items)
end

function GuildNewWarMainRankWindow:initNav()
	local index = 2
	self.tab = require("app.common.ui.CommonTabBar").new(self.nav.gameObject, index, function (index)
		self:updateNav(index)
	end)

	if self.state == xyd.GuildNewWarMainRankType.RANK_RANK then
		self.tab:setTexts({
			__("GUILD_NEW_WAR_TEXT40"),
			__("GUILD_NEW_WAR_TEXT41")
		})
	elseif self.state == xyd.GuildNewWarMainRankType.RANK_RECORD then
		self.tab:setTexts({
			__("GUILD_NEW_WAR_TEXT03"),
			__("GUILD_NEW_WAR_TEXT04")
		})
	end

	self.tab:setTabActive(1, true, false)
end

function GuildNewWarMainRankWindow:updateNav(index)
	if self.state == xyd.GuildNewWarMainRankType.RANK_RANK then
		if index == 1 then
			self.guildItem:getGameObject():X(0)

			if self.personItem then
				self.personItem:getGameObject():X(2000)
			end
		elseif index == 2 then
			local function checkPersonFun(data)
				self.personListInfo = data

				if not self.personItem then
					self.personItem = import("app.components.GuildNewWarMainRankPersonItem").new(self.personCon.gameObject, self, self.personListInfo)
				end

				if self.guildItem then
					self.guildItem:getGameObject():X(2000)
					self.personItem:getGameObject():X(0)
				end
			end

			if not self.personListInfo then
				self.activityData:reqPersonRankList(checkPersonFun)
			else
				checkPersonFun(self.personListInfo)
			end
		end
	elseif self.state == xyd.GuildNewWarMainRankType.RANK_RECORD then
		if index == 1 then
			self.guildItem:getGameObject():X(0)

			if self.recordItem then
				self.recordItem:getGameObject():X(2000)
			end
		elseif index == 2 then
			local function checkGuildLogFun(data)
				self.guildLogInfo = data

				if not self.recordItem then
					self.recordItem = import("app.components.GuildNewWarMainRankRecordItem").new(self.recordCon.gameObject, self, self.guildLogInfo)
				end

				if self.recordItem then
					self.guildItem:getGameObject():X(2000)
					self.recordItem:getGameObject():X(0)
				end
			end

			if not self.guildLogInfo then
				self.activityData:reqGuildLogList(checkGuildLogFun)
			else
				checkGuildLogFun(self.guildLogInfo)
			end
		end
	end
end

function GuildNewWarMainRankWindow:initTimeShow()
	if self.state == xyd.GuildNewWarMainRankType.RANK_RANK then
		self.timeDescText.text = __("GUILD_NEW_WAR_TEXT78")
		local curPeriod, endTime = self.activityData:getCurPeriod()

		if curPeriod == xyd.GuildNewWarPeroid.ATTACHING1 or curPeriod == xyd.GuildNewWarPeroid.ATTACHING2 then
			endTime = xyd.getTomorrowTime() + (self.activityData:getReadyTimeDay() - 1) * xyd.DAY_TIME + xyd.DAY_TIME * self.activityData:getFightingTimeDay()
		elseif curPeriod == xyd.GuildNewWarPeroid.READY1 or curPeriod == xyd.GuildNewWarPeroid.READY2 then
			endTime = endTime + xyd.DAY_TIME * self.activityData:getFightingTimeDay()
		elseif curPeriod ~= xyd.GuildNewWarPeroid.FIGHTING1 then
			if curPeriod ~= xyd.GuildNewWarPeroid.FIGHTING2 then
				endTime = 0
			end
		end

		local disTime = endTime - xyd.getServerTime()

		if disTime > 1 then
			disTime = disTime - 1
			self.timeCount = import("app.components.CountDown").new(self.timeNumText)

			self.timeCount:setInfo({
				duration = disTime,
				callback = function ()
					self.timeNumText.text = "00:00:00"
				end
			})
		else
			self.timeNumText.text = "00:00:00"
		end
	elseif self.state == xyd.GuildNewWarMainRankType.RANK_RECORD then
		self.timeDescText.text = __("GUILD_NEW_WAR_TEXT02")
		local curPeriod, endTime = self.activityData:getCurPeriod()

		if curPeriod == xyd.GuildNewWarPeroid.BEGIN_RELAX then
			endTime = endTime + xyd.DAY_TIME * self.activityData:getNormalRelaxDay()
		elseif curPeriod == xyd.GuildNewWarPeroid.END_RELAX then
			self.timeDescText.text = __("GUILD_NEW_WAR_TEXT39")
		elseif curPeriod == xyd.GuildNewWarPeroid.NORMAL_RELAX then
			-- Nothing
		elseif curPeriod == xyd.GuildNewWarPeroid.READY1 or curPeriod == xyd.GuildNewWarPeroid.READY2 then
			if xyd.getServerTime() > self.activityData:getEndTime() - xyd.DAY_TIME * (self.activityData:getEndRelaxDay() + self.activityData:getFightingTimeDay() + self.activityData:getReadyTimeDay()) then
				self.timeDescText.text = __("GUILD_NEW_WAR_TEXT39")
				endTime = endTime + xyd.DAY_TIME * (self.activityData:getFightingTimeDay() + self.activityData:getEndRelaxDay())
			else
				endTime = endTime + xyd.DAY_TIME * (self.activityData:getFightingTimeDay() + self.activityData:getNormalRelaxDay())
			end
		elseif curPeriod == xyd.GuildNewWarPeroid.FIGHTING1 or curPeriod == xyd.GuildNewWarPeroid.FIGHTING1 then
			if xyd.getServerTime() > self.activityData:getEndTime() - xyd.DAY_TIME * (self.activityData:getEndRelaxDay() + self.activityData:getFightingTimeDay() + self.activityData:getReadyTimeDay()) then
				self.timeDescText.text = __("GUILD_NEW_WAR_TEXT39")
				endTime = endTime + xyd.DAY_TIME * self.activityData:getNormalRelaxDay()
			else
				endTime = endTime + xyd.DAY_TIME * (self.activityData:getFightingTimeDay() + self.activityData:getNormalRelaxDay())
			end
		end

		local disTime = endTime - xyd.getServerTime()

		if disTime > 0 then
			self.timeCount = import("app.components.CountDown").new(self.timeNumText)

			self.timeCount:setInfo({
				duration = disTime,
				callback = function ()
					self.timeNumText.text = "00:00:00"
				end
			})
		end
	end

	self.timeConUILayout:Reposition()
end

return GuildNewWarMainRankWindow
