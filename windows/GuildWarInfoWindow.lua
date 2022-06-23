local BaseWindow = import(".BaseWindow")
local GuildWarInfoWindow = class("GuildWarInfoWindow", BaseWindow)
local GuildWarItem = class("GuildWarItem")
local BaseComponent = import("app.components.BaseComponent")
local GuildWarFormation = class("GuildWarFormation", BaseComponent)
local GuildWarMatchOther = class("GuildWarMatchOther", BaseComponent)
local GuildWarAllFormationSmall = class("GuildWarAllFormationSmall", BaseComponent)
local GuildWarFormationFive = class("GuildWarFormationFive", import("app.common.ui.FixedMultiWrapContentItem"))
local GuildWarFinalItem = class("GuildWarFinalItem", BaseComponent)
local GuildWarBeforeFinalItem = class("GuildWarBeforeFinalItem", BaseComponent)
local GuildWarBeforeFinal = class("GuildWarBeforeFinal", BaseComponent)
local GuildWarGuildBaseInfo = class("GuildWarGuildBaseInfo", BaseComponent)
local GuildWarHangUp = import("app.components.BattleHangUp").GuildWarHangUp
local guildModel = xyd.models.guild
local PlayerIcon = import("app.components.PlayerIcon")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local cjson = require("cjson")

function GuildWarItem:ctor(go, parent)
	self.uiRoot_ = go
	self.parent_ = parent
	self.GuildWarFormation1_ = GuildWarFormation.new(self.uiRoot_, self.parent_)
end

function GuildWarItem:update(index, realIndex, data)
	if not data then
		self.uiRoot_:SetActive(false)

		return
	else
		self.info_ = data.info

		self.uiRoot_:SetActive(true)
		self.GuildWarFormation1_:setInfo(self.info_, data.index)
	end
end

function GuildWarItem:getGameObject()
	return self.uiRoot_
end

function GuildWarInfoWindow:ctor(name, params)
	GuildWarInfoWindow.super.ctor(self, name, params)

	self.model_ = xyd.models.guildWar
end

function GuildWarInfoWindow:initWindow()
	GuildWarInfoWindow.super.initWindow(self)

	self.mainGroup_ = self.window_:ComponentByName("e:Group", typeof(UIWidget))
	local mainTrans = self.mainGroup_.transform
	self.navGroup_ = mainTrans:NodeByName("navGroup").gameObject
	self.closeBtn = mainTrans:NodeByName("closeBtn").gameObject
	self.labelTitle_ = mainTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.gContent1_ = mainTrans:NodeByName("gContent1").gameObject
	self.gContent2_ = mainTrans:NodeByName("gContent2").gameObject
	local gContent1Trans = self.gContent1_.transform
	self.labelForce_ = gContent1Trans:ComponentByName("groupMid/labelForce_", typeof(UILabel))
	self.groupNone_ = gContent1Trans:NodeByName("groupMid/groupNone").gameObject
	self.labelNoneTips_ = gContent1Trans:ComponentByName("groupMid/groupNone/labelNoneTips", typeof(UILabel))
	self.btnSet_ = gContent1Trans:NodeByName("groupMid/btnSet").gameObject
	self.btnSetLabel_ = gContent1Trans:ComponentByName("groupMid/btnSet/btnLabel", typeof(UILabel))
	self.labelTeam_ = gContent1Trans:ComponentByName("groupMid/labelTeam", typeof(UILabel))
	self.scrollView_ = gContent1Trans:ComponentByName("groupMid/scroll", typeof(UIScrollView))
	self.grid_ = gContent1Trans:ComponentByName("groupMid/scroll/grid", typeof(MultiRowWrapContent))
	self.scrollItemRoot_ = gContent1Trans:NodeByName("groupMid/scroll/itemRoot").gameObject
	self.noRankImg_ = gContent1Trans:NodeByName("groupBottom/groupRank/noRankImg").gameObject
	self.warRankRoot_ = gContent1Trans:NodeByName("groupBottom/groupRank/warRank").gameObject
	self.labelPointTitle_ = gContent1Trans:ComponentByName("groupBottom/groupPoint/labelPoint", typeof(UILabel))
	self.labelPoint_ = gContent1Trans:ComponentByName("groupBottom/groupPoint/point", typeof(UILabel))
	self.labelTimeTitle_ = gContent1Trans:ComponentByName("groupBottom/groupTime/labelTime", typeof(UILabel))
	self.labelTime_ = gContent1Trans:ComponentByName("groupBottom/groupTime/countDown", typeof(UILabel))
	self.btnApply_ = gContent1Trans:NodeByName("groupBottom/btnApply").gameObject
	self.btnApplyMask_ = gContent1Trans:NodeByName("groupBottom/btnApply/mask").gameObject
	self.btnApplyLabel_ = gContent1Trans:ComponentByName("groupBottom/btnApply/btnLabel", typeof(UILabel))
	self.btnFormation_ = gContent1Trans:NodeByName("groupBottom/btnFormation").gameObject
	self.btnFormationLabel_ = gContent1Trans:ComponentByName("groupBottom/btnFormation/btnLabel", typeof(UILabel))
	self.btnAward_ = gContent1Trans:NodeByName("groupBottom/btnAward").gameObject
	self.btnAwardLabel_ = gContent1Trans:ComponentByName("groupBottom/btnAward/label", typeof(UILabel))
	self.btnRecord_ = gContent1Trans:NodeByName("groupBottom/btnRecord").gameObject
	self.btnRecordLabel_ = gContent1Trans:ComponentByName("groupBottom/btnRecord/label", typeof(UILabel))
	self.btnRank_ = gContent1Trans:NodeByName("groupBottom/btnRank").gameObject
	self.btnRankLabel_ = gContent1Trans:ComponentByName("groupBottom/btnRank/label", typeof(UILabel))
	self.btnEnlist_ = gContent1Trans:NodeByName("groupBottom/btnEnlist").gameObject
	self.helpBtn = mainTrans:NodeByName("btnHelp").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, self.scrollItemRoot_, GuildWarItem, self)

	self:layoutMisc()
	self:register()

	self.labelTitle_.text = __("GUILD_WAR_INFO_WWINDOW")
end

function GuildWarInfoWindow:playOpenAnimation(callback)
	GuildWarInfoWindow.super.playOpenAnimation(self, function ()
		self.model_:reqGuildWarInfo()
		callback()
	end)
end

function GuildWarInfoWindow:register()
	GuildWarInfoWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_WAR_GET_INFO, self.onGetInfo, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_WAR_JOIN, function ()
		xyd.showToast(__("GUILD_WAR_APPLY_SUCCESS"))
		self:layoutRestZone()
		self:layoutMatchZone()
	end, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_WAR_SAVE_TEAMS, function ()
		xyd.showToast(__("GUILD_WAR_TEAM_SET_SUCCESS"))
		self:layoutRestZone()
	end, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_WAR_SET_PARTNERS, function ()
		self:layoutRestZone(true)
	end, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_WAR_FIGHT, function ()
		if self.model_:getScore() == 0 then
			self.labelPoint_.text = "1000"
		else
			self.labelPoint_.text = tostring(self.model_:getScore())
		end

		if not self.warRank_ then
			self.warRank_ = import("app.components.PngNum").new(self.warRankRoot_)
		end

		self.warRank_:setInfo({
			iconName = "guild_war",
			num = self.model_:getRank()
		})
	end, self)

	UIEventListener.Get(self.btnSet_.gameObject).onClick = handler(self, self.onClickSet)
	UIEventListener.Get(self.btnEnlist_.gameObject).onClick = handler(self, self.onClickEnlist)

	UIEventListener.Get(self.btnAward_.gameObject).onClick = function ()
		if not guildModel.guildID then
			xyd.showToast(__("GUILD_TEXT66"))

			return
		end

		if tonumber(self.model_:getInfo().is_signed) <= 0 then
			xyd.showToast(__("NOT_SIGNED"))

			return
		end

		xyd.WindowManager.get():openWindow("guild_war_award_window")
	end

	UIEventListener.Get(self.btnRecord_.gameObject).onClick = function ()
		if not guildModel.guildID then
			xyd.showToast(__("GUILD_TEXT66"))

			return
		end

		if tonumber(self.model_:getInfo().is_signed) <= 0 then
			xyd.showToast(__("NOT_SIGNED"))

			return
		end

		xyd.WindowManager.get():openWindow("guild_war_record_window")
	end

	UIEventListener.Get(self.btnRank_.gameObject).onClick = function ()
		if not guildModel.guildID then
			xyd.showToast(__("GUILD_TEXT66"))

			return
		end

		local warInfo = self.model_:getInfo()

		if not warInfo then
			return
		end

		if tonumber(self.model_:getInfo().is_signed) <= 0 then
			xyd.showToast(__("NOT_SIGNED"))

			return
		end

		xyd.WindowManager.get():openWindow("guild_war_rank_window")
	end

	UIEventListener.Get(self.btnApply_.gameObject).onClick = handler(self, self.onClickApply)
	UIEventListener.Get(self.btnFormation_.gameObject).onClick = handler(self, self.onClickFormation)

	UIEventListener.Get(self.helpBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "GUILD_WAR_HELP"
		})
	end
end

function GuildWarInfoWindow:onClickFormation()
	if not guildModel.guildID then
		xyd.showToast(__("GUILD_TEXT66"))

		return
	end

	local warInfo = self.model_:getInfo()

	if not warInfo then
		return
	end

	if tonumber(xyd.models.guild.guild_battle_id) > 0 and xyd.models.guild.guild_battle_id ~= xyd.models.guild.guildID then
		xyd.showToast(__("GUILD_WAR_NO_TIPS"))

		return
	end

	if tonumber(self.model_:getInfo().is_signed) > 0 then
		if #self.model_:getDefFormation() > 0 then
			xyd.showToast(__("GUILD_WAR_CANNOT_CHANGE_TEAM"))

			return
		end
	else
		local moment = self.model_:judgeMoment()

		if self.model_.MOMENT.BEFORE_FINAL < moment then
			xyd.showToast(__("GUILD_WAR_RANK_MATCH_END"))

			return
		end
	end

	xyd.WindowManager:get():openWindow("battle_formation_window", {
		showSkip = false,
		battleType = xyd.BattleType.GUILD_WAR_DEF,
		mapType = xyd.MapType.GUILD_WAR
	})
end

function GuildWarInfoWindow:onClickApply()
	if not guildModel.guildID then
		xyd.showToast(__("GUILD_TEXT66"))

		return
	end

	if guildModel.guildJob == xyd.GUILD_JOB.NORMAL then
		xyd.showToast(__("HAS_NO_RIGHT"))

		return
	end

	if self.model_.MOMENT.RANK_MATCH < self.model_:judgeMoment() then
		xyd.showToast(__("GUILD_WAR_RANK_MATCH_END"))

		return
	end

	if #self.model_.info_.member_ids < tonumber(xyd.tables.miscTable:getVal("guild_war_battle_min_num")) then
		xyd.showToast(__("GUILD_WAR_MIN_NUM", xyd.tables.miscTable:getVal("guild_war_battle_min_num")))

		return
	end

	if tonumber(self.model_:getInfo().is_signed) > 0 then
		xyd.showToast(__("GUILD_WAR_IS_SIGNED"))
		self:setChildrenColorGrey(self.btnApply_)
		self.btnApplyMask_:SetActive(true)

		return
	end

	self.model_:Join()
end

function GuildWarInfoWindow:onClickEnlist()
	xyd.alertYesNo(__("GUILD_WAR_CONFIRM_SEND"), function (flag)
		if flag then
			if not guildModel.guildID then
				xyd.showToast(__("GUILD_TEXT66"))

				return
			end

			local cd = guildModel.enlistTime + tonumber(xyd.tables.miscTable:getVal("guild_recruit")) - xyd.getServerTime()

			if cd > 0 then
				xyd.showToast(__("GUILD_WAR_CONFIRM_LIMIT_TIME", math.ceil(cd / 60)))

				return
			end

			local text = __("GUILD_WAR_ENLIST_TEXT")
			local data = cjson.encode({
				text = text,
				guild_id = guildModel.guildID
			})

			xyd.models.chat:sendGuildWarMsg(data, xyd.MsgType.GUILD_WAR)
			xyd.showToast(__("GUILD_WAR_SEND_SUCCESS"))

			guildModel.enlistTime = xyd.getServerTime()
		end
	end)
end

function GuildWarInfoWindow:onClickSet()
	local moment = self.model_:judgeMoment()

	if self.model_.MOMENT.BEFORE_FINAL < moment then
		xyd.showToast(__("GUILD_WAR_RANK_MATCH_END"))
	end

	xyd.WindowManager:get():openWindow("guild_war_set_all_formation_window", self.info_)
end

function GuildWarInfoWindow:onClickNav(index)
	xyd.SoundManager.get():playSound(xyd.SoundID.TAB)
	self.gContent1_:SetActive(index == 1)

	if index == 1 then
		self.gContent2_:X(1000)
	elseif index == 2 then
		self.gContent2_:X(0)
	end
end

function GuildWarInfoWindow:onGetInfo()
	if not self.tab then
		self.tab = import("app.common.ui.CommonTabBar").new(self.navGroup_, 2, function (index)
			self:onClickNav(index)
		end)

		self.tab:setTexts({
			__("REST_ZONE"),
			__("MATCH_ZONE")
		})
		self.tab:setBrforeChangeFuc(function (index, currentIndex)
			if index == 2 then
				local moment = self.model_:judgeMoment()

				if moment < self.model_.MOMENT.BEFORE_FINAL and self.model_:getInfo().is_signed <= 0 then
					xyd.showToast(__("NOT_SIGNED"))
					self.tab:setTabActive(currentIndex, true, false)

					return true
				end
			end

			return false
		end)
	end

	self:layoutRestZone()
	XYDCo.WaitForFrame(5, function ()
		if self.window_ and not tolua.isnull(self.window_) then
			self:layoutMatchZone()
		end
	end, nil)
end

function GuildWarInfoWindow:layoutMisc()
	self.gContent1_:SetActive(true)
	self.gContent2_:X(1000)

	if guildModel.guildJob ~= xyd.GUILD_JOB.NORMAL then
		self.btnSet_:SetActive(true)

		self.btnSetLabel_.text = __("SET_FORMATION")

		self.btnEnlist_:SetActive(true)
	else
		self.btnSet_:SetActive(false)
		self.btnEnlist_:SetActive(false)
	end

	self.labelPointTitle_.text = __("POINT")
	self.btnAwardLabel_.text = __("GUILD_WAR_AWARD")
	self.btnRecordLabel_.text = __("REOCRD")
	self.btnRankLabel_.text = __("CAMPAIGN_RANK")
	self.btnApplyLabel_.text = __("SIGN_UP")
	self.btnFormationLabel_.text = __("MY_TEAM")
end

function GuildWarInfoWindow:layoutRestTeams(keepPosition)
	local collection = {}

	if #self.info_.all_teams <= 0 then
		self.groupNone_:SetActive(true)

		self.labelNoneTips_.text = __("NO_TEAMS")
	else
		self.groupNone_:SetActive(false)

		for i = 1, #self.info_.member_ids do
			for j = 1, #self.info_.all_teams do
				if self.info_.member_ids[i] == self.info_.all_teams[j].player_id then
					local tempInfo = self.info_.all_teams[j]
					local params = {
						index = i,
						info = tempInfo
					}

					table.insert(collection, params)
				end
			end
		end
	end

	for i = 1, #self.info_.all_teams do
		local mem_ids = self.info_.member_ids

		if xyd.arrayIndexOf(mem_ids, self.info_.all_teams[i].player_id) < 0 then
			local tempInfo = self.info_.all_teams[i]
			local params = {
				info = tempInfo
			}

			table.insert(collection, params)
		end
	end

	if xyd.models.guild.guildJob == xyd.GUILD_JOB.NORMAL then
		local result = {}
		local _index = 1
		local _num = #collection

		while #collection > 0 do
			local ran = math.random(0, #collection)

			if collection[ran] then
				result[_index] = collection[ran]

				table.remove(collection, ran)

				_index = _index + 1

				if _num < _index then
					break
				end
			end
		end

		collection = result
	end

	self.collecItems_ = collection

	self.multiWrap_:setInfos(collection, {
		keepPosition = keepPosition
	})
end

function GuildWarInfoWindow:layoutRestMisc()
	self.info_ = self.model_.info_
	self.labelForce_.text = tostring(self:calTeamPower())
	self.labelTeam_.text = tostring(__("GUILD_TEAM") .. " : " .. tostring(#self.info_.member_ids) .. "/" .. tostring(#self.info_.all_teams))

	if self.info_.score > 0 then
		self.noRankImg_:SetActive(false)
		self.warRankRoot_:SetActive(true)

		if not self.warRank_ then
			self.warRank_ = import("app.components.PngNum").new(self.warRankRoot_)
		end

		self.warRank_:setInfo({
			iconName = "guild_war",
			num = self.model_:getRank()
		})
	else
		self.noRankImg_:SetActive(true)
		self.warRankRoot_:SetActive(false)
	end

	if tonumber(self.info_.score) == 0 then
		self.labelPoint_.text = 1000
	else
		self.labelPoint_.text = self.info_.score
	end

	local moment = self.model_:judgeMoment() + 1
	self.labelTimeTitle_.text = __("TIME_TO_GUILD_WAR_" .. tostring(moment - 1))
	local intervals = xyd.split(xyd.tables.miscTable:getVal("guild_war_time_interval"), "|", true)
	local endTime = self.info_.week_start_time + intervals[moment] - xyd.getServerTime()
	local params = {
		duration = endTime
	}

	if not self.countDown_ then
		self.countDown_ = import("app.components.CountDown").new(self.labelTime_, params)
	else
		self.countDown_:setInfo(params)
	end

	if tonumber(self.model_:getInfo().is_signed) > 0 then
		self:setChildrenColorGrey(self.btnApply_)
		self.btnApplyMask_:SetActive(true)
	else
		self.btnApplyMask_:SetActive(false)
	end
end

function GuildWarInfoWindow:setChildrenColorGrey(go)
	local widget1 = go:GetComponent(typeof(UIWidget))

	if widget1 then
		widget1.color = Color.New2(255)
	end

	for i = 1, go.transform.childCount do
		local child = go.transform:GetChild(i - 1).gameObject
		local widget = child:GetComponent(typeof(UIWidget))

		if widget then
			widget.color = Color.New2(255)
		end

		local label = child:GetComponent(typeof(UILabel))

		if label then
			widget.color = Color.New2(4294967295.0)
		end

		if child.transform.childCount > 0 then
			self:setChildrenColorGrey(child)
		end
	end
end

function GuildWarInfoWindow:layoutRestZone(keepPosition)
	self:layoutRestMisc()
	self:layoutRestTeams(keepPosition)
end

function GuildWarInfoWindow:layoutMatch()
	if not self.GuildWarMatchOther_ then
		self.GuildWarMatchOther_ = GuildWarMatchOther.new(self.gContent2_, self)
	end

	if self.GuildWarBeforeFinal_ then
		self.GuildWarBeforeFinal_:SetActive(false)
	end

	if self.GuildWarFinalItem_ then
		self.GuildWarFinalItem_:SetActive(false)
	end

	self.GuildWarMatchOther_:SetActive(true)
	self.GuildWarMatchOther_:layout()
	self.GuildWarMatchOther_:initEffect1()
end

function GuildWarInfoWindow:layoutBeforeFinal()
	if not self.GuildWarBeforeFinal_ then
		self.GuildWarBeforeFinal_ = GuildWarBeforeFinal.new(self.gContent2_, self)
	end

	if self.GuildWarMatchOther_ then
		self.GuildWarMatchOther_:SetActive(false)
	end

	if self.GuildWarFinalItem_ then
		self.GuildWarFinalItem_:SetActive(false)
	end

	self.GuildWarBeforeFinal_:SetActive(true)
	xyd.models.guildWar:reqRankList()
	self.GuildWarBeforeFinal_:initMisc()
end

function GuildWarInfoWindow:layoutFinal()
	if not self.GuildWarFinalItem_ then
		self.GuildWarFinalItem_ = GuildWarFinalItem.new(self.gContent2_, self)
	end

	if self.GuildWarBeforeFinal_ then
		self.GuildWarBeforeFinal_:SetActive(false)
	end

	if self.GuildWarMatchOther_ then
		self.GuildWarMatchOther_:SetActive(false)
	end

	self.GuildWarFinalItem_:SetActive(false)
	xyd.models.guildWar:reqFinalInfo()
end

function GuildWarInfoWindow:layoutMatchZone()
	self.info_ = self.model_:getInfo()
	local moment = self.model_:judgeMoment()
	local switch = {
		[self.model_.MOMENT.RANK_MATCH] = function ()
			self:layoutMatch()
		end,
		[self.model_.MOMENT.BEFORE_FINAL] = function ()
			self:layoutBeforeFinal()
		end,
		[self.model_.MOMENT.FINAL] = function ()
			self:layoutBeforeFinal()
		end,
		[self.model_.MOMENT.AFTER_FINAL] = function ()
			self:layoutFinal()
		end
	}

	switch[moment]()
end

function GuildWarInfoWindow:calTeamPower()
	local power = 0
	local ids = self.info_.member_ids

	for i = 1, #ids do
		for j = 1, #self.info_.all_teams do
			if ids[i] == self.info_.all_teams[j].player_id then
				power = power + self.info_.all_teams[j].power

				break
			end
		end
	end

	return power
end

function GuildWarInfoWindow:willClose()
	if self.countDown_ then
		self.countDown_:stopTimeCount()
	end

	if self.fightCount_ then
		self.fightCount_:stopTimeCount()
	end

	if self.timer_ then
		self.timer_:Stop()

		self.timer_ = nil
	end

	if self.GuildWarMatchOther_ then
		self.GuildWarMatchOther_:removeEvent()
	end

	if self.GuildWarBeforeFinal_ then
		self.GuildWarBeforeFinal_:removeEvent()
	end

	if self.GuildWarMatchOther_ then
		self.GuildWarMatchOther_:removeEvent()
	end

	GuildWarInfoWindow.super.willClose(self)
end

function GuildWarFormation:ctor(parentGo, parent)
	self.heroIconRootList_ = {}
	self.parent_ = parent
	self.panel_ = self.parent_.scrollView_:GetComponent(typeof(UIPanel))

	GuildWarFormation.super.ctor(self, parentGo)
end

function GuildWarFormation:getPrefabPath()
	return "Prefabs/Components/guild_war_formation"
end

function GuildWarFormation:initUI()
	local goTrans = self.go.transform
	self.teamIndexLabel_ = goTrans:ComponentByName("teamIndex", typeof(UILabel))
	self.playerNameLabel_ = goTrans:ComponentByName("playerName", typeof(UILabel))
	self.playerIconRoot_ = goTrans:NodeByName("playerIcon").gameObject
	self.btnDetail_ = goTrans:NodeByName("btnDetail").gameObject

	for i = 1, 6 do
		local heroIcon = {
			root = goTrans:NodeByName("groupPartner/HeroIcon" .. i).gameObject,
			cover = goTrans:NodeByName("groupPartner/HeroIcon" .. i .. "/cover").gameObject
		}

		table.insert(self.heroIconRootList_, heroIcon)
	end

	UIEventListener.Get(self.btnDetail_).onClick = handler(self, self.onClickDetail)
end

function GuildWarFormation:setInfo(data, index)
	if not data then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)

		if xyd.models.guild.guildJob == xyd.GUILD_JOB.NORMAL then
			self.teamIndexLabel_.gameObject:SetActive(false)
		end

		if data.index or index then
			self.teamIndexLabel_.text = data.index or index
		else
			self.teamIndexLabel_.text = " "
		end

		self.playerNameLabel_.text = data.player_name

		if not self.playerIcon_ then
			self.playerIcon_ = PlayerIcon.new(self.playerIconRoot_, self.panel_)
		end

		self.playerIcon_:setInfo({
			avatarID = data.avatar_id,
			lev = data.lev,
			avatar_frame_id = data.avatar_frame_id
		})

		local petID = nil

		if data and data.pet then
			petID = data.pet.pet_id
		end

		local showRootList = {}

		for i = 1, 6 do
			showRootList[i] = 0
		end

		for i = 1, #data.partners do
			local pos = data.partners[i].pos

			if pos and pos > 0 then
				local partner = Partner.new()

				partner:populate(data.partners[i])

				local partnerInfo = partner:getInfo()
				partnerInfo.noClick = true
				local heroIcon = self.heroIconRootList_[pos].heroIcon
				heroIcon = heroIcon or HeroIcon.new(self.heroIconRootList_[pos].root, self.panel_)
				showRootList[pos] = 1
				partnerInfo.dragScrollView = self.parent_.scrollView_

				heroIcon:setInfo(partnerInfo, petID)

				self.heroIconRootList_[pos].heroIcon = heroIcon
			end
		end

		for k = 1, 6 do
			if self.heroIconRootList_[k].heroIcon then
				self.heroIconRootList_[k].heroIcon:getIconRoot():SetActive(showRootList[k] == 1)
			end
		end

		self.showRootList_ = showRootList
	end

	self.data_ = data
end

function GuildWarFormation:onClickDetail()
	if self.data_ then
		xyd.WindowManager.get():openWindow("guild_war_formation_window", self.data_)
	end
end

function GuildWarMatchOther:ctor(go, parent)
	self.parent_ = parent
	self.parentPanel_ = self.parent_.window_:GetComponent(typeof(UIPanel))

	GuildWarMatchOther.super.ctor(self, go)
	self:registerEvent()
end

function GuildWarMatchOther:getPrefabPath()
	return "Prefabs/Components/guild_war_match_other"
end

function GuildWarMatchOther:initUI()
	local go = self.go
	self.groupTop_ = go:NodeByName("groupTop").gameObject
	local topTrans = self.groupTop_.transform
	self.groupMyTeam_ = topTrans:NodeByName("groupMyTeam").gameObject
	self.groupOtherTeam_ = topTrans:NodeByName("groupOtherTeam").gameObject
	self.groupNone_ = topTrans:NodeByName("groupNone").gameObject
	self.labelNoneTips_ = self.groupNone_:ComponentByName("labelNoneTips", typeof(UILabel))
	self.groupEffect2_ = topTrans:NodeByName("Geffect2").gameObject
	self.energyTips_ = go:NodeByName("energyTips").gameObject
	local panel = self.energyTips_:GetComponent(typeof(UIPanel))
	panel.depth = panel.depth + self.parentPanel_.depth
	local energyTrans = self.energyTips_.transform
	self.labelNextEnergy_ = energyTrans:ComponentByName("labelNextEnergy", typeof(UILabel))
	self.energyCountDown_ = energyTrans:ComponentByName("energyCountDown", typeof(UILabel))
	self.groupBottom_ = go:NodeByName("groupBottom").gameObject
	local bottomTrans = self.groupBottom_.transform
	self.btnFight_ = bottomTrans:ComponentByName("btnFight", typeof(UISprite))
	self.btnFightLabel_ = bottomTrans:ComponentByName("btnFight/btnLabel", typeof(UILabel))
	self.btnFightMask_ = bottomTrans:NodeByName("btnFight/mask").gameObject
	self.btnMatch_ = bottomTrans:ComponentByName("btnMatch", typeof(UISprite))
	self.btnMatchMask_ = bottomTrans:NodeByName("btnMatch/mask").gameObject
	self.btnMatchLabel_ = bottomTrans:ComponentByName("btnMatch/btnLabel", typeof(UILabel))
	self.groupEnergy_ = bottomTrans:NodeByName("groupEnergy").gameObject
	self.energyLabel_ = bottomTrans:ComponentByName("groupEnergy/label", typeof(UILabel))
	self.groupMc = bottomTrans:NodeByName("groupMc").gameObject
	self.matchGroup_ = bottomTrans:NodeByName("groupMc/groupMatch").gameObject
	self.matchStateBg_ = bottomTrans:ComponentByName("groupMc/groupMatch/matchStateBg", typeof(UITexture))
	self.mcEffectGroup_ = bottomTrans:ComponentByName("groupMc/groupMatch/effectGroup", typeof(UIWidget))
	self.groupMatchText_ = bottomTrans:ComponentByName("groupMc/groupMatch/groupMatchText", typeof(UIWidget))
	self.mcName1_ = bottomTrans:ComponentByName("groupMc/groupMatch/groupMatchText/name1", typeof(UILabel))
	self.mcNameEnemy_ = bottomTrans:ComponentByName("groupMc/groupMatch/groupMatchText/name2", typeof(UILabel))
	self.mcName3_ = bottomTrans:ComponentByName("groupMc/groupMatch/groupMatchText/name3", typeof(UILabel))
	self.groupBattle_ = bottomTrans:NodeByName("groupBattle").gameObject
	self.fightCountDown_ = self.groupBattle_:ComponentByName("coutDown", typeof(UILabel))
	self.hangUp_ = self.groupBattle_:NodeByName("hangUp").gameObject
	self.fightBar_ = self.groupBattle_:ComponentByName("progressPart", typeof(UIProgressBar))
	self.mcEimage_ = bottomTrans:ComponentByName("groupMc/e:image", typeof(UISprite))
	self.topEimage_ = topTrans:ComponentByName("e:imageBg", typeof(UISprite))
	self.effect1_ = xyd.Spine.new(self.mcEffectGroup_.gameObject)
	self.effect2_ = xyd.Spine.new(self.groupEffect2_.gameObject)

	xyd.setUISpriteAsync(topTrans:ComponentByName("img1", typeof(UISprite)), nil, "guild_war_deco3")
	xyd.setUISpriteAsync(topTrans:ComponentByName("img2", typeof(UISprite)), nil, "guild_war_deco3")
	xyd.setUISpriteAsync(self.groupEnergy_:ComponentByName("imgEnergy", typeof(UISprite)), nil, "guild_war_energy")
	xyd.setUISpriteAsync(self.groupMc:ComponentByName("mcBg", typeof(UISprite)), nil, "guild_war_bg07")
	xyd.setUISpriteAsync(self.groupBattle_:ComponentByName("imgBattleTop", typeof(UISprite)), nil, "guild_war_countdown_bg")
end

function GuildWarMatchOther:layout()
	self.info_ = xyd.models.guildWar:getInfo()
	self.matchInfo_ = xyd.models.guildWar:getMatchInfo()
	self.labelNoneTips_.text = __("GUILD_WAR_NO_MATCH_TEAM")

	if self.matchInfo_ and self.matchInfo_.guild_info and self.matchInfo_.guild_info.name then
		self.groupOtherTeam_:SetActive(true)

		if not self.otherTeam_ then
			self.otherTeam_ = GuildWarAllFormationSmall.new(self.groupOtherTeam_, self.parentPanel_)
		end

		self.otherTeam_:setInfo(self.matchInfo_)
		self.btnFightMask_:SetActive(false)
		self.groupNone_:SetActive(false)

		self.mcNameEnemy_.text = self.matchInfo_.guild_info.name

		self:randGuildNames()
	else
		self.groupOtherTeam_:SetActive(false)
		self.btnFightMask_:SetActive(true)
		self.groupNone_:SetActive(true)
	end

	local myTeamInfo = {}

	for i = 1, #self.info_.member_ids do
		for j = 1, #self.info_.all_teams do
			if self.info_.member_ids[i] == self.info_.all_teams[j].player_id then
				table.insert(myTeamInfo, self.info_.all_teams[j])

				break
			end
		end
	end

	local params = {
		noHide = true,
		guild_info = xyd.models.guild:getBaseInfo(),
		team_infos = {
			teams = myTeamInfo,
			hide_ids = self.info_.hide_ids,
			member_ids = self.info_.member_ids
		},
		rank = self.info_.rank
	}

	if not self.myTeam_ then
		self.myTeam_ = GuildWarAllFormationSmall.new(self.groupMyTeam_, self.parentPanel_)

		self.myTeam_:setInfo(params)
	else
		local rank = xyd.models.guildWar:getRank()

		self.myTeam_:updateRank(rank)
	end

	self:updateEnergy()

	self.btnMatchLabel_.text = __("MATCH")
	self.btnFightLabel_.text = __("FIGHT3")
	self.labelNextEnergy_.text = __("NEXT_ENERGY")

	self:refreshCountDownEnergy()
	self.matchGroup_:SetActive(true)
	self.groupBattle_:SetActive(false)
end

function GuildWarMatchOther:initEffect1()
	if not self.hasInitEffect1_ then
		self.effect1_:setInfo("fx_ui_pipeizhuan", function ()
			self.effect1_:SetLocalPosition(0, 0, 0)
			self.effect1_:SetLocalScale(1, 1, 1)
			self.effect1_:setRenderPanel(self.parentPanel_)
			self.effect1_:setRenderTarget(self.mcEimage_, 0)

			if self.matchInfo_ then
				xyd.setUITextureByNameAsync(self.matchStateBg_, "match_time_71")
			else
				xyd.setUITextureByNameAsync(self.matchStateBg_, "match_time_0")
			end

			self.effect1_:pause()
			self.effect1_:SetActive(true)

			self.hasInitEffect1_ = true
		end)
	end
end

function GuildWarMatchOther:randGuildNames()
	if self.matchInfo_ and self.matchInfo_.guild_names and self.matchInfo_.rank then
		local names = self.matchInfo_.guild_names
		local rand = math.random(#names)
		self.mcName1_.text = names[rand] or " "

		if rand + 1 > #names then
			self.mcName3_.text = names[rand + 1 - #names]
		else
			self.mcName3_.text = names[rand + 1]
		end
	else
		self.mcName1_.text = " "
		self.mcName3_.text = " "
	end
end

function GuildWarMatchOther:updateMatchInfo()
	self.info_ = xyd.models.guildWar:getInfo()
	self.matchInfo_ = xyd.models.guildWar:getMatchInfo()

	if self.matchInfo_ and self.otherTeam_ then
		self.otherTeam_:Destroy()
	end
end

function GuildWarMatchOther:setMatchInfo()
	if self.matchInfo_ then
		self.otherTeam_ = GuildWarAllFormationSmall.new(self.groupOtherTeam_, self.parentPanel_)

		self.otherTeam_:setInfo(self.matchInfo_)

		self.mcNameEnemy_.text = self.matchInfo_.guild_info.name

		self.groupNone_:SetActive(false)
		self:randGuildNames()
	end
end

function GuildWarMatchOther:refreshCountDownEnergy()
	local interval = tonumber(xyd.tables.miscTable:getVal("guild_war_energy_cd"))
	local nextTime = interval - (xyd.getServerTime() - xyd.models.guildWar:getInfo().week_start_time) % interval
	local params = {
		duration = nextTime,
		onComplete = function ()
			self:updateNextTime()
			self:refreshCountDownEnergy()
		end
	}

	if not self.energyTimeCount_ then
		self.energyTimeCount_ = import("app.components.CountDown").new(self.energyCountDown_, params)
	else
		self.energyTimeCount_:setInfo(params)
	end
end

function GuildWarMatchOther:updateNextTime()
	local fixEnergy = xyd.models.guildWar:getEnergy() + 1
	local maxEnergy = tonumber(xyd.tables.miscTable:getVal("guild_war_energy_max"))

	if maxEnergy < fixEnergy then
		fixEnergy = maxEnergy
	end

	xyd.models.guildWar:setEnergy(fixEnergy)
	self:updateEnergy()
end

function GuildWarMatchOther:updateEnergy()
	self.energyLabel_.text = xyd.models.guildWar:getEnergy() .. "/" .. xyd.tables.miscTable:getVal("guild_war_energy_max")
end

function GuildWarMatchOther:onClickMatch()
	if xyd.models.guild.guildJob == xyd.GUILD_JOB.NORMAL then
		xyd.showToast(__("HAS_NO_RIGHT"))

		return
	end

	self.groupMatchText_.gameObject:SetActive(false)
	self.groupNone_:SetActive(false)

	local callbacks = {
		hit = function ()
			self:showMatchText()
			self:showMatchTeam()
		end
	}

	if self.effect1_ and self.matchInfo_ then
		self.matchStateBg_.gameObject:SetActive(false)
		self.effect1_:SetActive(true)
		self.effect1_:resume()
		self.btnFightMask_:SetActive(true)
		self.groupOtherTeam_:SetActive(false)
		self.effect1_:playWithEvent("texiao02", 1, 1, callbacks, nil)

		self.paushFrame_ = 71
	elseif self.effect1_ then
		self.matchStateBg_.gameObject:SetActive(false)
		self.effect1_:resume()
		self.effect1_:SetActive(true)
		self.btnFightMask_:SetActive(true)
		self.groupOtherTeam_:SetActive(false)
		self.effect1_:playWithEvent("texiao01", 1, 1, callbacks, nil)

		self.paushFrame_ = 0
	end

	self.matchDirtyFlag = false

	xyd.models.guildWar:reqEnemyInfo()
	self.btnMatchMask_:SetActive(true)
	xyd.setUISpriteAsync(self.btnMatch_, nil, "white_btn70_70")

	local params = {
		duration = 10,
		callback = function ()
			xyd.setUISpriteAsync(self.btnMatch_, nil, "blue_btn70_70")
			self.btnMatchMask_:SetActive(false)

			self.btnMatchLabel_.color = Color.New2(4294967295.0)
			self.btnMatchLabel_.effectStyle = UILabel.Effect.Outline
			self.btnMatchLabel_.effectColor = Color.New2(473916927)
			self.matchCountDown_ = nil
			self.btnMatchLabel_.text = __("MATCH")
		end
	}
	self.btnMatchLabel_.color = Color.New2(960513791)
	self.btnMatchLabel_.effectStyle = UILabel.Effect.None
	self.matchCountDown_ = import("app.components.CountDown").new(self.btnMatchLabel_, params)
end

function GuildWarMatchOther:onClickFight()
	if xyd.models.guild.guildJob == xyd.GUILD_JOB.NORMAL then
		xyd.showToast(__("HAS_NO_RIGHT"))

		return
	end

	if xyd.models.guildWar:getEnergy() <= 0 then
		xyd.showToast(__("GUILD_WAR_NO_TILI"))

		return
	end

	if not self.matchInfo_ then
		return
	end

	xyd.models.guildWar:fight()
	self.matchGroup_:SetActive(false)
	self.groupBattle_:SetActive(true)
	self.btnMatchMask_:SetActive(true)
	xyd.setUISpriteAsync(self.btnMatch_, nil, "white_btn70_70")

	self.btnFight_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

	if self.matchCountDown_ then
		self.matchCountDown_:stopTimeCount()

		self.matchCountDown_ = nil
	end

	self.btnMatchLabel_.text = __("FIGHTING")

	self:playBattleAction()
end

function GuildWarMatchOther:playBattleAction()
	self.groupMatchText_.gameObject:SetActive(false)

	local tableIDS = {}
	local skinIDs = {}
	local tmpFormation = self.info_.all_teams[1].partners

	for i = 1, 2 do
		table.insert(tableIDS, tmpFormation[i].table_id)
		table.insert(skinIDs, tmpFormation[i].equips[7])
	end

	local monsterIDS = {}
	tmpFormation = self.matchInfo_.team_infos.teams[1].partners

	for i = 1, 2 do
		table.insert(monsterIDS, tmpFormation[i].table_id)
	end

	local params = {
		tableIDs = tableIDS,
		skinIDs = skinIDs,
		monsterIDs = monsterIDS
	}
	local item = GuildWarHangUp.getGuildWar().new(self.hangUp_, params)
	self.hangUpItem = item

	item:startBattle()

	local param = {
		duration = 10,
		callback = function ()
			if self.fightData then
				self:layout()
				xyd.WindowManager.get():openWindow("guild_war_record_detail_window", {
					info = self.fightData
				})

				self.fightData = nil

				if self.hangUpItem then
					self.hangUpItem:clearAction()
				end

				self.btnMatchMask_:SetActive(false)

				self.btnMatchLabel_.text = __("MATCH")
				self.btnMatchLabel_.color = Color.New2(4294967295.0)
				self.btnMatchLabel_.effectStyle = UILabel.Effect.Outline
				self.btnMatchLabel_.effectColor = Color.New2(473916927)

				xyd.setUISpriteAsync(self.btnMatch_, nil, "blue_btn70_70")

				self.btnFight_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
			end
		end
	}

	if not self.fightCount_ then
		self.fightCount_ = import("app.components.CountDown").new(self.fightCountDown_, param)
	end

	self.fightCount_:setInfo(param)
	self:initBar()
end

function GuildWarMatchOther:initBar()
	self.fightBar_.value = 0

	local function onTime()
		self.fightBar_.value = self.fightBar_.value + 0.05

		if self.fightBar_.value >= 1 then
			self.timer_:Stop()

			self.timer_ = nil
		end
	end

	self.timer_ = Timer.New(onTime, 1, -1, false)

	self.timer_:Start()
end

function GuildWarMatchOther:registerEvent()
	self.eventProxyInner_:addEventListener(xyd.event.GUILD_WAR_MATCH, handler(self, self.updateMatchInfo))
	self.eventProxyInner_:addEventListener(xyd.event.GUILD_WAR_FIGHT, handler(self, self.onFight))

	UIEventListener.Get(self.btnMatch_.gameObject).onClick = handler(self, self.onClickMatch)
	UIEventListener.Get(self.btnFight_.gameObject).onClick = handler(self, self.onClickFight)

	UIEventListener.Get(self.groupEnergy_.gameObject).onPress = function (_, isPress)
		self.energyTips_:SetActive(isPress)
	end
end

function GuildWarMatchOther:removeEvent()
	self.eventProxyInner_:removeAllEventListeners()

	if self.matchCountDown_ then
		self.matchCountDown_:stopTimeCount()
	end

	if self.energyTimeCount_ then
		self.energyTimeCount_:stopTimeCount()
	end
end

function GuildWarMatchOther:onFight(event)
	local data = event.data
	self.fightData = data

	self:updateEnergy()
end

function GuildWarMatchOther:showMatchText()
	self.groupMatchText_.gameObject:SetActive(true)

	self.groupMatchText_.alpha = 0.01

	local function getter()
		return self.groupMatchText_.alpha
	end

	local function setter(value)
		self.groupMatchText_.alpha = value
	end

	local seq = DG.Tweening.DOTween.Sequence()

	seq:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0.01, 0.25, 0.033))
	seq:Insert(0, self.groupMatchText_.transform:DOScale(Vector3(1.02, 1.02, 1), 0.03))
	seq:Insert(0.033, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0.25, 0.5, 0.033))
	seq:Insert(0.033, self.groupMatchText_.transform:DOScale(Vector3(1, 1, 1), 0.03))
	seq:Insert(0.067, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0.5, 0.75, 0.033))
	seq:Insert(0.067, self.groupMatchText_.transform:DOScale(Vector3(1.1, 1.1, 1.1), 0.03))
	seq:Insert(0.1, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0.75, 1, 0.033))
	seq:Insert(0.1, self.groupMatchText_.transform:DOScale(Vector3(1, 1, 1), 0.033))
	seq:AppendCallback(function ()
		seq:Kill(true)

		seq = nil
	end)
end

function GuildWarMatchOther:showMatchTeam()
	self.matchDirtyFlag = true

	if not xyd.models.guildWar:getmatchDirtyFlag() then
		return
	end

	local targetBg = nil

	if self.otherTeam_ then
		targetBg = self.otherTeam_:getBgImage()
	else
		targetBg = self.topEimage_
	end

	self.groupOtherTeam_:SetActive(true)
	self:setMatchInfo()

	if self.effect2_ and not self.hasLoadpipeikuang_ then
		self.effect2_:setInfo("fx_ui_pipeikuang", function ()
			self.effect2_:SetLocalPosition(0, 0, 0)
			self.effect2_:SetLocalScale(1, 1, 1)
			self.effect2_:setRenderPanel(self.parentPanel_)
			self.effect2_:setRenderTarget(targetBg, 1)
			self.effect2_:SetActive(true)
			self.effect2_:play("texiao01", 1, 1)

			self.hasLoadpipeikuang_ = true

			self.btnFightMask_:SetActive(false)
		end)
	elseif self.hasLoadpipeikuang_ then
		self.effect2_:play("texiao01", 1, 1)
		self.btnFightMask_:SetActive(false)
	end
end

function GuildWarAllFormationSmall:ctor(go, parentPanel)
	self.parentPanel_ = parentPanel

	GuildWarAllFormationSmall.super.ctor(self, go)
end

function GuildWarAllFormationSmall:getPrefabPath()
	return "Prefabs/Components/guild_war_all_formation_small"
end

function GuildWarAllFormationSmall:initUI()
	local go = self.go
	self.imgBg_ = go:ComponentByName("imgBg", typeof(UISprite))
	local imgTrans = self.imgBg_.transform
	self.guildIcon_ = imgTrans:ComponentByName("groupInfo/guildIcon", typeof(UISprite))
	self.guildName_ = imgTrans:ComponentByName("groupInfo/guildName", typeof(UILabel))
	self.guildRank_ = imgTrans:ComponentByName("groupInfo/guildRank", typeof(UILabel))
	self.serverID_ = imgTrans:ComponentByName("groupInfo/serverGroup/label", typeof(UILabel))
	self.scrollView_ = imgTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = imgTrans:ComponentByName("scrollView/grid", typeof(MultiRowWrapContent))
	self.scrollItemRoot_ = imgTrans:NodeByName("scrollView/guild_war_formation5").gameObject
	local panel = self.scrollView_:GetComponent(typeof(UIPanel))
	panel.depth = self.parentPanel_.depth + 1
	self.wrapContent_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, self.scrollItemRoot_, GuildWarFormationFive, self)
	self.btnDetail_ = go:ComponentByName("imgBg/btnDetail", typeof(UISprite))

	UIEventListener.Get(self.btnDetail_.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("guild_war_all_formation_window", self.data_)
	end

	self.e_image = go:ComponentByName("imgBg/groupInfo/serverGroup/e:image", typeof(UISprite))

	xyd.setUISpriteAsync(self.e_image, nil, "guild_war_bg06", nil, )
end

function GuildWarAllFormationSmall:Destroy()
	NGUITools.Destroy(self.go)
end

function GuildWarAllFormationSmall:getBgImage()
	return self.imgBg_
end

function GuildWarAllFormationSmall:setInfo(params)
	self.data_ = params
	local collection = {}

	for idx, teamInfo in ipairs(self.data_.team_infos.teams) do
		local isHide = xyd.arrayIndexOf(self.data_.team_infos.hide_ids, teamInfo.player_id) > 0

		if self.data_.noHide then
			isHide = false
		end

		local tempInfo = {
			index = idx,
			isHide = isHide,
			teamInfo = teamInfo
		}

		table.insert(collection, tempInfo)
	end

	self.wrapContent_:setInfos(collection, {})

	local guildIconName = xyd.tables.guildIconTable:getIcon(self.data_.guild_info.flag)

	xyd.setUISpriteAsync(self.guildIcon_, nil, guildIconName)

	self.guildName_.text = self.data_.guild_info.name

	if self.data_.noHide or self.data_.rank < 50 then
		self.guildRank_.text = __("RANK") .. ":" .. tostring(self.data_.rank)
	else
		local n = math.floor(self.data_.rank / 50)
		local str = tonumber(n * 50 + 1) .. "~" .. tonumber(n * 50 + 50)
		self.guildRank_.text = __("RANK") .. ":" .. tostring(str)
	end

	self.serverID_.text = xyd.getServerNumber(self.data_.guild_info.server_id)
end

function GuildWarAllFormationSmall:updateRank(rank)
	self.data_.rank = rank

	if self.data_.noHide or self.data_.rank < 50 then
		self.guildRank_.text = __("RANK") .. ":" .. tostring(self.data_.rank)
	else
		local n = math.floor(self.data_.rank / 50)
		local str = tonumber(n * 50 + 1) .. "~" .. tonumber(n * 50 + 50)
		self.guildRank_.text = __("RANK") .. ":" .. tostring(str)
	end
end

function GuildWarFormationFive:ctor(go, parent)
	self.parent_ = parent
	self.renderPanel_ = parent.scrollView_:GetComponent(typeof(UIPanel))
	self.heroIconRootList_ = {}

	GuildWarFormationFive.super.ctor(self, go, parent)
end

function GuildWarFormationFive:initUI()
	local go = self.go
	self.teamIndex_ = go:ComponentByName("teamIndex", typeof(UILabel))

	for i = 1, 6 do
		local heroIcon = {
			root = go:NodeByName("groupPartner/HeroIcon" .. i).gameObject,
			cover = go:NodeByName("groupPartner/HeroIcon" .. i .. "/cover").gameObject
		}

		table.insert(self.heroIconRootList_, heroIcon)
	end
end

function GuildWarFormationFive:update(index, realIndex, params)
	if not params then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	local data = params.teamInfo
	local petID = nil

	if data and data.pet then
		petID = data.pet.pet_id
	end

	if params.index then
		self.teamIndex_.text = params.index
	else
		self.teamIndex_.text = " "
	end

	if not self.isHide_ or params.isHide ~= self.isHide_ then
		for _, heroIcon in ipairs(self.heroIconRootList_) do
			heroIcon.cover:SetActive(params.isHide)
		end

		if not params.isHide then
			local showRootList = {}

			for i = 1, 6 do
				showRootList[i] = 0
			end

			for i = 1, #data.partners do
				local pos = data.partners[i].pos
				local partner = Partner.new()

				partner:populate(data.partners[i])

				local partnerInfo = partner:getInfo()
				partnerInfo.noClick = true
				local heroIcon = self.heroIconRootList_[pos].heroIcon
				heroIcon = heroIcon or HeroIcon.new(self.heroIconRootList_[pos].root, self.renderPanel_)
				showRootList[pos] = 1
				partnerInfo.dragScrollView = self.parent_.scrollView_

				heroIcon:setInfo(partnerInfo, petID)

				self.heroIconRootList_[pos].heroIcon = heroIcon
			end

			for k = 1, 6 do
				if self.heroIconRootList_[k].heroIcon then
					self.heroIconRootList_[k].heroIcon:getIconRoot():SetActive(showRootList[k] == 1)
				end
			end

			self.showRootList_ = showRootList
		else
			for _, heroIcon in ipairs(self.heroIconRootList_) do
				if heroIcon.heroIcon then
					heroIcon.heroIcon:SetActive(false)
				end
			end
		end
	end

	self.isHide_ = params.isHide
	self.info_ = params.teamInfo
end

function GuildWarFormationFive:getGameObject()
	return self.go
end

function GuildWarBeforeFinal:ctor(go, parent)
	self.parent_ = parent
	self.parentPanel_ = self.parent_.window_:GetComponent(typeof(UIPanel))

	GuildWarBeforeFinal.super.ctor(self, go)
	self:registerEvent()
end

function GuildWarBeforeFinal:initUI()
	local go = self.go
	self.titleLabel_ = go:ComponentByName("e:image/titleLabel", typeof(UILabel))
	self.labelTime_ = go:ComponentByName("e:image/groupTime/labelTime", typeof(UILabel))
	self.timeCountDown_ = go:ComponentByName("e:image/groupTime/timeCountDown", typeof(UILabel))
	self.itemRoot_ = go:NodeByName("e:image/groupScroll/itemRoot").gameObject
	self.scrollView_ = go:ComponentByName("e:image/groupScroll/scrollView", typeof(UIScrollView))
	local panel = self.scrollView_:GetComponent(typeof(UIPanel))
	panel.depth = self.parentPanel_.depth + 1
	self.grid_ = go:ComponentByName("e:image/groupScroll/scrollView/grid", typeof(MultiRowWrapContent))
	self.wrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, self.itemRoot_, GuildWarBeforeFinalItem, self)
	self.e_image = go:ComponentByName("e:image", typeof(UISprite))

	xyd.setUISpriteAsync(self.e_image, nil, "guild_war_bg04", nil, )
end

function GuildWarBeforeFinal:getPrefabPath()
	return "Prefabs/Components/guild_war_before_final"
end

function GuildWarBeforeFinal:registerEvent()
	self.eventProxyOuter_:addEventListener(xyd.event.GUILD_WAR_GET_RANK_LIST, handler(self, self.layoutVs))
end

function GuildWarBeforeFinal:removeEvent()
	self.eventProxyOuter_:removeAllEventListeners()

	if self.countDown_ then
		self.countDown_:stopTimeCount()
	end
end

function GuildWarBeforeFinal:initMisc()
	self.titleLabel_.text = __("FINAL_DETAIL")
	local moment = xyd.models.guildWar:judgeMoment()

	if moment == xyd.models.guildWar.MOMENT.BEFORE_FINAL then
		self.labelTime_.text = __("TIME_TO_BEGIN")
	elseif moment == xyd.models.guildWar.MOMENT.FINAL then
		self.labelTime_.text = __("TIME_TO_END")
	end

	local tmpStr = xyd.tables.miscTable:getVal("guild_war_time_interval")
	local timeIntervals = xyd.split(tmpStr, "|", true)
	local endTime = xyd.models.guildWar:getInfo().week_start_time + timeIntervals[moment + 1] - xyd.getServerTime()

	self:updateCountDown(endTime)
end

function GuildWarBeforeFinal:updateCountDown(endTime)
	local params = {
		duration = endTime
	}

	if not self.countDown_ then
		self.countDown_ = import("app.components.CountDown").new(self.timeCountDown_, params)
	else
		self.countDown_:setInfo(params)
	end
end

function GuildWarBeforeFinal:layoutVs(event)
	local data = event.data.list
	local collectInfos = {}

	for i = 1, 8 do
		local opponent = xyd.models.guildWar.VS[i]
		local tempInfo = {
			a_info = data[i],
			b_info = data[opponent]
		}

		if tempInfo.a_info or tempInfo.b_info then
			table.insert(collectInfos, tempInfo)
		end
	end

	self.wrap_:setInfos(collectInfos, {})
end

function GuildWarBeforeFinalItem:ctor(go, parent)
	self.parent_ = parent

	GuildWarBeforeFinal.super.ctor(self, go)
end

function GuildWarBeforeFinalItem:initUI()
	local go = self.go
	self.guildGroup1_ = go:NodeByName("guildGroup1").gameObject
	self.guildGroup2_ = go:NodeByName("guildGroup2").gameObject
	self.guildIcon1_ = self.guildGroup1_:ComponentByName("guildIcon", typeof(UISprite))
	self.guildName1_ = self.guildGroup1_:ComponentByName("guildName", typeof(UILabel))
	self.serverId1_ = self.guildGroup1_:ComponentByName("serverInfo/serverId", typeof(UILabel))
	self.guildIcon2_ = self.guildGroup2_:ComponentByName("guildIcon", typeof(UISprite))
	self.guildName2_ = self.guildGroup2_:ComponentByName("guildName", typeof(UILabel))
	self.serverId2_ = self.guildGroup2_:ComponentByName("serverInfo/serverId", typeof(UILabel))
end

function GuildWarBeforeFinalItem:update(index, realIndex, params)
	if not params then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	if params.a_info then
		if not self.aFlag_ or self.aFlag_ ~= params.a_info.flag then
			local iconName = xyd.tables.guildIconTable:getIcon(params.a_info.flag)

			xyd.setUISpriteAsync(self.guildIcon1_, nil, iconName)
		end

		self.guildName1_.text = params.a_info.name
		self.serverId1_.text = xyd.getServerNumber(params.a_info.server_id)
		self.aFlag_ = params.a_info.flag
	else
		self.guildGroup1_:SetActive(false)
	end

	if params.b_info then
		if not self.bFlag_ or self.bFlag_ ~= params.b_info.flag then
			local iconName = xyd.tables.guildIconTable:getIcon(params.b_info.flag)

			xyd.setUISpriteAsync(self.guildIcon2_, nil, iconName)
		end

		self.guildName2_.text = params.b_info.name
		self.serverId2_.text = xyd.getServerNumber(params.b_info.server_id)
		self.bFlag_ = params.b_info.flag
	else
		self.guildGroup2_:SetActive(false)
	end
end

function GuildWarBeforeFinalItem.getPrefabPath()
	return "Prefabs/Components/guild_war_before_final_item"
end

local lineNum = {
	1,
	4,
	7,
	6
}
local lineNum2 = {
	1,
	4,
	2,
	3
}

function GuildWarFinalItem:ctor(go, parent)
	self.parent_ = parent
	self.lineGroup_ = {}
	self.videoGroup_ = {}
	self.guildWarInfoRoot_ = {}
	self.guildWarInfo_ = {}

	GuildWarFinalItem.super.ctor(self, go)
	self:registerEvent()
end

function GuildWarFinalItem.getPrefabPath()
	return "Prefabs/Components/guild_war_final"
end

function GuildWarFinalItem:initUI()
	local go = self.go
	self.titleLabel_ = go:ComponentByName("e:image/titleLabel", typeof(UILabel))
	local lineGroup = go:NodeByName("e:image/groupLine").gameObject
	local videoGroup = go:NodeByName("e:image/groupVideos").gameObject

	for i = 1, 4 do
		self.lineGroup_["_1_" .. lineNum[i] .. "_win"] = lineGroup:ComponentByName("group" .. i .. "/_1_" .. lineNum[i] .. "_win", typeof(UISprite))
		self.lineGroup_["_1_" .. lineNum[i] .. "_lose"] = lineGroup:ComponentByName("group" .. i .. "/_1_" .. lineNum[i] .. "_lose", typeof(UISprite))
		self.lineGroup_["_1_" .. 9 - lineNum[i] .. "_win"] = lineGroup:ComponentByName("group" .. i .. "/_1_" .. 9 - lineNum[i] .. "_win", typeof(UISprite))
		self.lineGroup_["_1_" .. 9 - lineNum[i] .. "_lose"] = lineGroup:ComponentByName("group" .. i .. "/_1_" .. 9 - lineNum[i] .. "_lose", typeof(UISprite))
		self.lineGroup_["_2_" .. lineNum2[i] .. "_win"] = lineGroup:ComponentByName("group" .. i .. "/_2_" .. lineNum2[i] .. "_win", typeof(UISprite))
		self.lineGroup_["_2_" .. lineNum2[i] .. "_lose"] = lineGroup:ComponentByName("group" .. i .. "/_2_" .. lineNum2[i] .. "_lose", typeof(UISprite))

		for j = 1, math.pow(2, 4 - i) do
			self.videoGroup_["v_" .. i .. "_" .. j] = videoGroup:ComponentByName("v_" .. i .. "_" .. j, typeof(UISprite))
		end
	end

	self.lineGroup_._3_1_win = lineGroup:ComponentByName("group1/_3_1_win", typeof(UISprite))
	self.lineGroup_._3_1_lose = lineGroup:ComponentByName("group2/_3_1_lose", typeof(UISprite))
	self.lineGroup_._3_2_win = lineGroup:ComponentByName("group3/_3_2_win", typeof(UISprite))
	self.lineGroup_._3_2_lose = lineGroup:ComponentByName("group4/_3_2_lose", typeof(UISprite))
	self.lineGroup_._4_1_win = lineGroup:ComponentByName("_4_1_win", typeof(UISprite))
	self.lineGroup_._4_1_lose = lineGroup:ComponentByName("_4_1_lose", typeof(UISprite))
	self.lineGroup_._fix_1 = lineGroup:ComponentByName("_fix_1", typeof(UISprite))
	self.lineGroup_._fix_2 = lineGroup:ComponentByName("_fix_2", typeof(UISprite))

	for i = 1, 16 do
		self.guildWarInfoRoot_[i] = go:NodeByName("e:image/guildRoot" .. i).gameObject
	end

	self.semiTopRoot_ = go:NodeByName("e:image/semiTop").gameObject
	self.semiBotRoot_ = go:NodeByName("e:image/semiBot").gameObject
	self.finalSemiRoot_ = go:NodeByName("e:image/finalSemi").gameObject
	self.e_image1 = go:ComponentByName("e:image/e:image1", typeof(UISprite))

	xyd.setUISpriteAsync(self.e_image1, nil, "guild_war_deco2", nil, )

	self.e_image2 = go:ComponentByName("e:image/e:image2", typeof(UISprite))

	xyd.setUISpriteAsync(self.e_image2, nil, "guild_war_deco2", nil, )

	self.e_image = go:ComponentByName("e:image", typeof(UISprite))

	xyd.setUISpriteAsync(self.e_image, nil, "guild_war_bg04", nil, )
end

function GuildWarFinalItem:registerEvent()
	self.eventProxyInner_:addEventListener(xyd.event.GUILD_WAR_GET_FINAL_INFO, handler(self, self.layout))
	self.eventProxyInner_:addEventListener(xyd.event.GUILD_WAR_GET_FINAL_RECORD, handler(self, self.onGetDetail))
end

function GuildWarFinalItem:removeEvent()
	self.eventProxyOuter_:removeAllEventListeners()
end

function GuildWarFinalItem:onGetDetail(event)
	local params = event.data

	xyd.WindowManager.get():openWindow("guild_war_record_detail_window", params)
end

function GuildWarFinalItem:layout()
	self:SetActive(true)

	self.titleLabel_.text = __("GUILD_FINAL_RESULT")
	self.roundInfo_ = xyd.models.guildWar:getFinalInfo().rounds

	self:layoutLinesAndVideos()
	self:layoutItems()
end

function GuildWarFinalItem:layoutLinesAndVideos()
	for round = 1, 4 do
		for index = 1, math.pow(2, 4 - round) do
			if self.roundInfo_[round][index] == 0 and self.roundInfo_[round + 1][index] == 0 then
				-- Nothing
			elseif self.roundInfo_[round][index] == self.roundInfo_[round + 1][index] then
				local lineIcon = self.lineGroup_["_" .. round .. "_" .. index .. "_win"]

				xyd.setUISpriteAsync(lineIcon, nil, "road_yellow_" .. round)
			else
				local lineIcon = self.lineGroup_["_" .. round .. "_" .. index .. "_lose"]

				xyd.setUISpriteAsync(lineIcon, nil, "road_yellow_" .. round)
			end

			if self.roundInfo_[round + 1][index] == 0 or self.roundInfo_[round][math.pow(2, 4 - round) - index] == 0 then
				self.videoGroup_["v_" .. round .. "_" .. index]:SetActive(false)
			end

			UIEventListener.Get(self.videoGroup_["v_" .. round .. "_" .. index].gameObject).onClick = function ()
				self:onClickVideo(round, index)
			end
		end
	end

	if self.roundInfo_[4][1] ~= 0 then
		xyd.setUISpriteAsync(self.lineGroup_._fix_1, nil, "road_yellow_4")
	end

	if self.roundInfo_[4][2] ~= 0 then
		xyd.setUISpriteAsync(self.lineGroup_._fix_2, nil, "road_yellow_4")
	end
end

function GuildWarFinalItem:layoutItems()
	for i = 1, 16 do
		if not self.guildWarInfo_[i] then
			self.guildWarInfo_[i] = GuildWarGuildBaseInfo.new(self.guildWarInfoRoot_[i], self)
		end

		if self.roundInfo_[1][i] and self.roundInfo_[1][i] ~= 0 then
			local info = xyd.models.guildWar:getFinalInfo().guilds[self.roundInfo_[1][i]] or nil

			self.guildWarInfo_[i]:setInfo(info, nil, i)
		else
			self.guildWarInfo_[i]:setInfo(nil, true, i)
		end
	end

	if self.roundInfo_[4][1] > 0 then
		if not self.semiTop_ then
			self.semiTop_ = GuildWarGuildBaseInfo.new(self.semiTopRoot_, self)
		end

		local info = xyd.models.guildWar:getFinalInfo().guilds[self.roundInfo_[4][1]]

		self.semiTop_:setInfo(info, nil, 17)
	elseif self.semiTop_ then
		self.semiTop_:setInfo(nil, true)
	end

	if self.roundInfo_[4][2] > 0 then
		if not self.semiBot_ then
			self.semiBot_ = GuildWarGuildBaseInfo.new(self.semiBotRoot_, self)
		end

		local info = xyd.models.guildWar:getFinalInfo().guilds[self.roundInfo_[4][2]]

		self.semiBot_:setInfo(info, nil, 17)
	elseif self.semiBot_ then
		self.semiBot_:setInfo(nil, true)
	end

	if self.roundInfo_[5][1] > 0 then
		if not self.finalSemi_ then
			self.finalSemi_ = GuildWarGuildBaseInfo.new(self.finalSemiRoot_, self)
		end

		local info = xyd.models.guildWar:getFinalInfo().guilds[self.roundInfo_[5][1]]

		self.finalSemi_:setInfo(info, nil, 18)
	elseif self.finalSemi_ then
		self.finalSemi_:setInfo(nil, true)
	end
end

function GuildWarFinalItem:onClickVideo(round, index)
	xyd.models.guildWar:reqFinalRecord(round, index)
end

function GuildWarGuildBaseInfo:ctor(parentGO, parent)
	self.parent_ = parent

	GuildWarGuildBaseInfo.super.ctor(self, parentGO)

	self.changeList = {
		4,
		13,
		5,
		12,
		3,
		14,
		6,
		11
	}
end

function GuildWarGuildBaseInfo.getPrefabPath()
	return "Prefabs/Components/guild_war_guild_base_info"
end

function GuildWarGuildBaseInfo:initUI()
	local go = self.go
	self.bgImg_ = go:ComponentByName("e:image", typeof(UISprite))
	self.guildIcon_ = go:ComponentByName("guildIcon", typeof(UISprite))
	self.guildName_ = go:ComponentByName("guildName", typeof(UILabel))
	self.serverGroup_ = go:NodeByName("serverGroup").gameObject
	self.serverId_ = go:ComponentByName("serverGroup/serverId", typeof(UILabel))
end

function GuildWarGuildBaseInfo:setInfo(params, isNone, pos)
	if not params then
		isNone = true
	end

	if isNone then
		self.guildIcon_.gameObject:SetActive(false)
		self.guildName_.gameObject:SetActive(false)
		self.serverGroup_:SetActive(false)
	else
		local flagIcon = xyd.tables.guildIconTable:getIcon(params.flag)

		xyd.setUISpriteAsync(self.guildIcon_, nil, flagIcon)

		if xyd.utf8len(params.name) >= 9 and pos >= 1 and pos <= 16 then
			self.guildName_.text = xyd.subUft8Len(params.name, 9) .. "..."
		else
			self.guildName_.text = params.name
		end

		self.serverId_.text = xyd.getServerNumber(params.server_id)
	end

	if pos == 17 then
		self.bgImg_.height = 86
		self.bgImg_.width = 208

		xyd.setUISpriteAsync(self.bgImg_, nil, "guild_war_bg02")
	elseif pos == 18 then
		self.bgImg_.height = 145
		self.bgImg_.width = 240

		xyd.setUISpriteAsync(self.bgImg_, nil, "guild_war_bg03")
		self.guildIcon_.transform:Y(-20)
		self.guildIcon_.transform:X(-60)

		self.guildIcon_.transform.localScale = Vector3(1.4, 1.4, 1.4)

		self.guildName_.transform:Y(-5)
		self.serverGroup_.transform:Y(-20)
	elseif xyd.arrayIndexOf(self.changeList, tonumber(pos)) > 0 then
		self.guildName_.transform:X(-60)
		self.serverGroup_.transform:X(-50)
		self.guildIcon_.transform:X(50)
	end
end

return GuildWarInfoWindow
