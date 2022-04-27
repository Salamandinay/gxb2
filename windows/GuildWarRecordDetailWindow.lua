local BaseWindow = import(".BaseWindow")
local PlayerIcon = import("app.components.PlayerIcon")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local GuildWarRecordDetailWindow = class("GuildWarRecordDetailWindow", BaseWindow)
local GuildWarRecordDetailItem = class("GuildWarRecordDetailItem", import("app.components.BaseComponent"))

function GuildWarRecordDetailWindow:ctor(name, params)
	GuildWarRecordDetailWindow.super.ctor(self, name, params)

	self.isReport_ = params.isReport
	self.params = params.info

	if not self.params then
		self.isReport_ = false
		self.params = params
	end

	self.teamInfos_ = self.params.team_infos
end

function GuildWarRecordDetailWindow:initWindow()
	GuildWarRecordDetailWindow.super.initWindow(self)

	local contentTrans = self.window_:NodeByName("e:image").gameObject
	self.titleLabel_ = contentTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn_ = contentTrans:NodeByName("closeBtn").gameObject
	self.iconWin_ = contentTrans:ComponentByName("iconWin", typeof(UITexture))
	self.iconLost_ = contentTrans:ComponentByName("iconLost", typeof(UITexture))
	self.guildIcon1_ = contentTrans:ComponentByName("groupGuildInfo1/guildIcon", typeof(UISprite))
	self.guildName1_ = contentTrans:ComponentByName("groupGuildInfo1/guildName", typeof(UILabel))
	self.serverId1_ = contentTrans:ComponentByName("groupGuildInfo1/serverGroup/serverId", typeof(UILabel))
	self.guildIcon2_ = contentTrans:ComponentByName("groupGuildInfo2/guildIcon", typeof(UISprite))
	self.guildName2_ = contentTrans:ComponentByName("groupGuildInfo2/guildName", typeof(UILabel))
	self.serverId2_ = contentTrans:ComponentByName("groupGuildInfo2/serverGroup/serverId", typeof(UILabel))
	self.scrollView_ = contentTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = contentTrans:ComponentByName("scrollView/grid", typeof(UIGrid))

	self:registerEvent()
	self:layoutGuild()

	if not self.isReport_ then
		self:layoutItems()
	elseif self.params.record_ids then
		xyd.models.guildWar:reqRecordDetail(self.params.record_ids)
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow("guild_war_record_detail_window")
	end
end

function GuildWarRecordDetailWindow:layoutGuild()
	self.titleLabel_.text = __("GUILD_TEXT67")

	xyd.setUISpriteAsync(self.guildIcon1_, nil, xyd.tables.guildIconTable:getIcon(self.params.a_info.flag))
	xyd.setUISpriteAsync(self.guildIcon2_, nil, xyd.tables.guildIconTable:getIcon(self.params.b_info.flag))

	self.guildName1_.text = self.params.a_info.name
	self.guildName2_.text = self.params.b_info.name
	self.serverId1_.text = xyd.getServerNumber(self.params.a_info.server_id)
	self.serverId2_.text = xyd.getServerNumber(self.params.b_info.server_id)
	local isWin = self.params.is_win
	local lang = "en_en"

	if xyd.Global.lang == "zh_tw" then
		lang = "zh_tw"
	end

	if isWin and isWin == 1 then
		xyd.setUITextureAsync(self.iconWin_, "Textures/arena_web/arena_text/arena_3v3_win_" .. lang)
		xyd.setUITextureAsync(self.iconLost_, "Textures/arena_web/arena_text/arena_3v3_lost_" .. lang)
	else
		xyd.setUITextureAsync(self.iconLost_, "Textures/arena_web/arena_text/arena_3v3_win_" .. lang)
		xyd.setUITextureAsync(self.iconWin_, "Textures/arena_web/arena_text/arena_3v3_lost_" .. lang)
	end
end

function GuildWarRecordDetailWindow:layoutItems()
	NGUITools.DestroyChildren(self.grid_.transform)

	for idx, teamInfo in ipairs(self.teamInfos_) do
		XYDCo.WaitForFrame(1, function ()
			local itemNew = GuildWarRecordDetailItem.new(self.grid_.gameObject, self)

			itemNew:setInfo(teamInfo, idx)
			self.grid_:Reposition()

			if idx == 1 or idx == #self.teamInfos_ then
				self.scrollView_:ResetPosition()
			end
		end, nil)
	end
end

function GuildWarRecordDetailWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GUILD_WAR_GET_RECORD_DETAIL, handler(self, self.onRecorde))
	self.eventProxy_:addEventListener(xyd.event.GUILD_WAR_GET_REPORT, function (event)
		xyd.BattleController:onGuildwarBattle(event)
	end)
end

function GuildWarRecordDetailWindow:onRecorde(event)
	local data = event.data
	self.teamInfos_ = data.report_teams

	self:layoutItems()
end

function GuildWarRecordDetailItem:ctor(go, parent)
	self.parent_ = parent
	self.heroIconList1_ = {}
	self.heroIconList2_ = {}

	GuildWarRecordDetailItem.super.ctor(self, go)
end

function GuildWarRecordDetailItem:getPrefabPath()
	return "Prefabs/Components/guild_war_record_detail_item"
end

function GuildWarRecordDetailItem:initUI()
	local go = self.go
	self.matchNumLabel_ = go:ComponentByName("groupTop/matchNum", typeof(UILabel))
	self.videoBtn_ = go:NodeByName("groupTop/videoBtn").gameObject
	local conTrans = go:NodeByName("groupContent").gameObject.transform
	self.resultIcon1_ = conTrans:ComponentByName("resultIcon1", typeof(UITexture))
	self.resultIcon2_ = conTrans:ComponentByName("resultIcon2", typeof(UITexture))
	self.pIconRoot1_ = conTrans:NodeByName("pIconRoot1").gameObject
	self.pIconRoot2_ = conTrans:NodeByName("pIconRoot2").gameObject
	self.pName1_ = conTrans:ComponentByName("pName1", typeof(UILabel))
	self.pName2_ = conTrans:ComponentByName("pName2", typeof(UILabel))
	local groupHeroIcon1Trans = conTrans:NodeByName("groupHeroIcon1").gameObject
	local groupHeroIcon2Trans = conTrans:NodeByName("groupHeroIcon2").gameObject

	for i = 1, 6 do
		local heroIcon1 = {}
		local heroIcon2 = {}
		heroIcon1.root = groupHeroIcon1Trans:NodeByName("HeroIcon" .. i).gameObject
		heroIcon1.cover = groupHeroIcon1Trans:NodeByName("HeroIcon" .. i .. "/cover").gameObject
		heroIcon2.root = groupHeroIcon2Trans:NodeByName("HeroIcon" .. i).gameObject
		heroIcon2.cover = groupHeroIcon2Trans:NodeByName("HeroIcon" .. i .. "/cover").gameObject

		table.insert(self.heroIconList1_, heroIcon1)
		table.insert(self.heroIconList2_, heroIcon2)
	end

	xyd.setUISpriteAsync(conTrans:ComponentByName("imgBg", typeof(UISprite)), nil, "guild_war_bg05")
end

function GuildWarRecordDetailItem:setInfo(params, index)
	self.params_ = params
	local isWin = params.is_win
	local lang = "en_en"

	if xyd.Global.lang == "zh_tw" then
		lang = "zh_tw"
	end

	if isWin and isWin == 1 then
		xyd.setUITextureByNameAsync(self.resultIcon1_, "arena_3v3_win_" .. lang)
		xyd.setUITextureByNameAsync(self.resultIcon2_, "arena_3v3_lost_" .. lang)
	else
		xyd.setUITextureByNameAsync(self.resultIcon2_, "arena_3v3_win_" .. lang)
		xyd.setUITextureByNameAsync(self.resultIcon1_, "arena_3v3_lost_" .. lang)
	end

	self.matchNumLabel_.text = __("MATCH_NUM", index)

	if not self.playerIcon1_ then
		self.playerIcon1_ = PlayerIcon.new(self.pIconRoot1_)
	end

	if not self.playerIcon2_ then
		self.playerIcon2_ = PlayerIcon.new(self.pIconRoot2_)
	end

	self.playerIcon1_:setInfo(params.self_info)
	self.playerIcon2_:setInfo(params.enemy_info)

	self.pName1_.text = params.self_info.player_name
	self.pName2_.text = params.enemy_info.player_name
	local teamA = params.self_info.partner_infos
	local teamB = params.enemy_info.partner_infos
	local petA = nil

	if params.self_info.pet then
		petA = params.self_info.pet.pet_id
	end

	local petB = nil

	if params.self_info.pet then
		petB = params.enemy_info.pet.pet_id
	end

	local showRootList1 = {}

	for i = 1, #teamA do
		local pos = teamA[i].pos
		local partner = Partner.new()

		partner:populate(teamA[i])

		local partnerInfo = partner:getInfo()
		partnerInfo.noClick = true
		local heroIcon = self.heroIconList1_[pos].heroIcon
		heroIcon = heroIcon or HeroIcon.new(self.heroIconList1_[pos].root)
		showRootList1[pos] = 1
		partnerInfo.dragScrollView = self.parent_.scrollView_

		heroIcon:setInfo(partnerInfo, petA)

		if teamA[i].status and teamA[i].status.hp == 0 then
			heroIcon:setGrey()
		else
			heroIcon:setOrigin()
		end

		self.heroIconList1_[pos].heroIcon = heroIcon
	end

	for k = 1, 6 do
		if self.heroIconList1_[k].heroIcon then
			self.heroIconList1_[k].heroIcon:getIconRoot():SetActive(showRootList1[k] == 1)
		end
	end

	local showRootList2 = {}

	for i = 1, #teamB do
		local pos = teamB[i].pos
		local partner = Partner.new()

		partner:populate(teamB[i])

		local partnerInfo = partner:getInfo()
		partnerInfo.noClick = true
		local heroIcon = self.heroIconList2_[pos].heroIcon
		heroIcon = heroIcon or HeroIcon.new(self.heroIconList2_[pos].root)
		showRootList2[pos] = 1
		partnerInfo.dragScrollView = self.parent_.scrollView_

		heroIcon:setInfo(partnerInfo, petB)

		if teamB[i].status and teamB[i].status.hp == 0 then
			heroIcon:setGrey()
		else
			heroIcon:setOrigin()
		end

		self.heroIconList2_[pos].heroIcon = heroIcon
	end

	for k = 1, 6 do
		if self.heroIconList2_[k].heroIcon then
			self.heroIconList2_[k].heroIcon:getIconRoot():SetActive(showRootList2[k] == 1)
		end
	end

	UIEventListener.Get(self.videoBtn_).onClick = function ()
		xyd.models.guildWar:reqReport(self.params_.record_id)
	end
end

return GuildWarRecordDetailWindow
