local BaseWindow = import(".BaseWindow")
local GuildWarAllFormationWindow = class("GuildWarAllFormationWindow", BaseWindow)
local GuildWarFormationFour = class("GuildWarFormationFour", import("app.components.BaseComponent"))
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")

function GuildWarAllFormationWindow:ctor(name, params)
	GuildWarAllFormationWindow.super.ctor(self, name, params)
end

function GuildWarAllFormationWindow:initWindow()
	GuildWarAllFormationWindow.super.initWindow(self)

	local eGroup = self.window_:ComponentByName("e:Group", typeof(UIWidget)).gameObject
	self.labelTitle_ = eGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn_ = eGroup:NodeByName("closeBtn").gameObject
	self.scrollView_ = eGroup:ComponentByName("groupScroll/scrollView", typeof(UIScrollView))
	self.grid_ = eGroup:ComponentByName("groupScroll/scrollView/grid", typeof(MultiRowWrapContent))
	local itemRoot = eGroup:NodeByName("groupScroll/itemRoot").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, itemRoot, GuildWarFormationFour, self)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow("guild_war_all_formation_window")
	end

	self:layout()
end

function GuildWarAllFormationWindow:layout()
	if not self.params_ then
		xyd.showToast("GUILD_WAR_TEXT01")

		return
	elseif not self.params_.team_infos then
		xyd.showToast("GUILD_WAR_TEXT01")

		return
	elseif not self.params_.team_infos.teams or #self.params_.team_infos.teams <= 0 then
		xyd.showToast("GUILD_WAR_TEXT01")

		return
	end

	local content = {}

	for idx, info in ipairs(self.params_.team_infos.teams) do
		local tempInfo = {}

		if xyd.arrayIndexOf(self.params_.team_infos.hide_ids, info.player_id) < 0 then
			tempInfo.isHide = false
		else
			tempInfo.isHide = true
		end

		if self.params_.noHide then
			tempInfo.isHide = false
		end

		tempInfo.teamInfo = info
		tempInfo.index = idx

		table.insert(content, tempInfo)
	end

	self.labelTitle_.text = __("GUILD_WAR_FORMATION")

	self.multiWrap_:setInfos(content, {})
end

function GuildWarFormationFour:ctor(go, parent)
	self.parent_ = parent
	self.heroIconRootList_ = {}

	GuildWarFormationFour.super.ctor(self, go)
end

function GuildWarFormationFour:getPrefabPath()
	return "Prefabs/Components/guild_war_formation4"
end

function GuildWarFormationFour:initUI()
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

function GuildWarFormationFour:update(index, realIndex, params)
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
				heroIcon = heroIcon or HeroIcon.new(self.heroIconRootList_[pos].root)
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

function GuildWarFormationFour:getGameObject()
	return self.go
end

return GuildWarAllFormationWindow
