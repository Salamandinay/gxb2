local BaseWindow = import(".BaseWindow")
local GuildWarSetAllFormationWindow = class("GuildWarSetAllFormationWindow", BaseWindow)
local GuildWarFormationSetItem = class("GuildWarFormationSetItem", import("app.components.BaseComponent"))
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")

function GuildWarSetAllFormationWindow:ctor(name, params)
	GuildWarSetAllFormationWindow.super.ctor(self, name, params)

	self.params_ = params
	self.selectedNum = params.member_ids and #params.member_ids or 0
	self.hideNum = params.hide_ids and #params.hide_ids or 0
	self.allNum = params.all_teams and #params.all_teams or 0
	self.teamList_ = {}
	self.hide_ids_ = params.hide_ids or {}
	self.member_ids_ = params.member_ids or {}
	self.all_teams_ = params.all_teams or {}
end

function GuildWarSetAllFormationWindow:initWindow()
	GuildWarSetAllFormationWindow.super.initWindow(self)

	self.content_ = self.window_:ComponentByName("e:Group", typeof(UIWidget)).gameObject
	local conTrans = self.content_.transform
	self.labelTitle_ = conTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = conTrans:NodeByName("closeBtn").gameObject
	self.labelTeamNum_ = conTrans:ComponentByName("teamNum", typeof(UILabel))
	self.btnSave_ = conTrans:NodeByName("btnSave").gameObject
	self.btnSaveLabel_ = conTrans:ComponentByName("btnSave/btnLabel", typeof(UILabel))
	self.groupNone_ = conTrans:NodeByName("groupScroll/groupNone").gameObject
	self.labelNoneTips_ = conTrans:ComponentByName("groupScroll/groupNone/labelNoneTips", typeof(UILabel))
	self.itemRoot_ = conTrans:NodeByName("groupScroll/itemRoot").gameObject
	self.scrollView_ = conTrans:ComponentByName("groupScroll/scrollView", typeof(UIScrollView))
	self.tableTeam_ = conTrans:ComponentByName("groupScroll/scrollView/tableTeam", typeof(UITable))

	self:layout()
end

function GuildWarSetAllFormationWindow:playOpenAnimation(callback)
	GuildWarSetAllFormationWindow.super.playOpenAnimation(self, function ()
		if callback then
			callback()
		end

		self:setCellsAfterOpen()
	end)
end

function GuildWarSetAllFormationWindow:updateLabelSelect()
	self.labelTeamNum_.text = tostring(self.selectedNum) .. "/" .. tostring(self.allNum)
end

function GuildWarSetAllFormationWindow:layout()
	self.btnSaveLabel_.text = __("SAVE_FORMATION")

	self:updateLabelSelect()

	if #self.all_teams_ <= 0 then
		self.labelNoneTips_.text = __("NO_TEAMS")

		self.groupNone_:SetActive(true)
	else
		self.groupNone_:SetActive(false)
	end

	UIEventListener.Get(self.btnSave_).onClick = handler(self, self.onClickSave)
	UIEventListener.Get(self.closeBtn).onClick = handler(self, self.onClickCloseButton)
end

function GuildWarSetAllFormationWindow:setCellsAfterOpen()
	if self.member_ids_ then
		for idx, id in ipairs(self.member_ids_) do
			for _, teamData in ipairs(self.all_teams_) do
				if id == teamData.player_id then
					XYDCo.WaitForFrame(1, function ()
						if self.window_ and not tolua.isnull(self.window_) then
							local item = GuildWarFormationSetItem.new(self.tableTeam_.gameObject, self)
							local isHide = xyd.arrayIndexOf(self.hide_ids_, teamData.player_id) > 0
							self.teamList_[idx] = item

							item:setInfo(teamData, idx, isHide)

							if idx == 1 or idx == #self.member_ids_ then
								self.tableTeam_:Reposition()
							end
						end
					end, nil)

					break
				end
			end
		end
	end

	local index = #self.member_ids_ + 1

	for _, teamData in ipairs(self.all_teams_) do
		if xyd.arrayIndexOf(self.member_ids_, teamData.player_id) < 0 then
			XYDCo.WaitForFrame(1, function ()
				if self.window_ and not tolua.isnull(self.window_) then
					local item = GuildWarFormationSetItem.new(self.tableTeam_.gameObject, self)
					self.teamList_[index] = item
					index = index + 1

					item:setInfo(teamData, nil, )

					if index == #self.member_ids_ + 1 or index == #self.all_teams_ then
						self.tableTeam_:Reposition()
						self.scrollView_:ResetPosition()
					end
				end
			end, nil)
		end
	end

	XYDCo.WaitForFrame(1, function ()
		self.tableTeam_:Reposition()
		self.scrollView_:ResetPosition()
	end, nil)
end

function GuildWarSetAllFormationWindow:onClickCloseButton()
	if self:checkChange() then
		xyd.alertYesNo(__("GUILD_WAR_SAVE_CONFIRM"), function (flag)
			if not flag then
				self:close()

				return
			elseif self:onClickSave() then
				self:close()
			end
		end)
	else
		self:close()
	end
end

function GuildWarSetAllFormationWindow:checkChange()
	local member_ids = {}
	local hide_ids = {}

	for _, item in ipairs(self.teamList_) do
		if item:isMember() then
			table.insert(member_ids, item:getPlayerId())
		end

		if item:isHide() then
			table.insert(hide_ids, item:getPlayerId())
		end
	end

	if #member_ids ~= #xyd.models.guildWar:getInfo().member_ids or #hide_ids ~= #xyd.models.guildWar:getInfo().hide_ids then
		return true
	end

	for idx, id in ipairs(member_ids) do
		if id ~= xyd.models.guildWar:getInfo().member_ids[idx] then
			return true
		end
	end

	for idx, id in ipairs(hide_ids) do
		if id ~= xyd.models.guildWar:getInfo().hide_ids[idx] then
			return true
		end
	end

	return false
end

function GuildWarSetAllFormationWindow:onClickSave()
	if self.selectedNum < tonumber(xyd.tables.miscTable:getVal("guild_war_battle_min_num")) then
		xyd.showToast(__("GUILD_WAR_MIN_NUM", xyd.tables.miscTable:getVal("guild_war_battle_min_num")))

		return false
	end

	if self.selectedNum < #xyd.models.guildWar:getInfo().member_ids then
		xyd.showToast(__("GUILD_WAR_CAN_NOT_REDUCE_TEAM"))

		return false
	end

	if xyd.models.guildWar.MOMENT.BEFORE_FINAL < xyd.models.guildWar:judgeMoment() then
		xyd.showToast(__("GUILD_WAR_RANK_MATCH_END"))

		return false
	end

	local member_ids = {}
	local hide_ids = {}

	for _, item in ipairs(self.teamList_) do
		if item:isMember() then
			table.insert(member_ids, item:getPlayerId())
		end

		if item:isHide() then
			table.insert(hide_ids, item:getPlayerId())
		end
	end

	xyd.models.guildWar:setTeamFormation(member_ids, hide_ids)
end

function GuildWarSetAllFormationWindow:switchTeam(index1, index2)
	local item1 = self.teamList_[index1]
	local item2 = self.teamList_[index2]

	if item1 and item2 then
		local item1Trans = item1:getGameObject().transform
		local item2Trans = item2:getGameObject().transform
		local item1ChildIndex = item1Trans:GetSiblingIndex()
		local item2ChildIndex = item2Trans:GetSiblingIndex()

		if index2 < index1 then
			self:moveTeam(item1, item1Trans, item2ChildIndex, function ()
				self.teamList_[index2] = item1
				self.teamList_[index1] = item2

				self:moveTeam(item2, item2Trans, item1ChildIndex)
			end)
		else
			self:moveTeam(item2, item2Trans, item1ChildIndex, function ()
				self.teamList_[index2] = item1
				self.teamList_[index1] = item2

				self:moveTeam(item1, item1Trans, item2ChildIndex)
			end)
		end
	end
end

function GuildWarSetAllFormationWindow:moveTeam(obj, transform, to, onComplete)
	if transform:GetSiblingIndex() == to then
		for idx, item in ipairs(self.teamList_) do
			item:updateIndex(idx)
		end

		return
	end

	obj:playDisappear(function ()
		transform:SetSiblingIndex(to)
		self.tableTeam_:Reposition()
		obj:playAppear(onComplete)

		for idx, item in ipairs(self.teamList_) do
			item:updateIndex(idx)
		end
	end)
end

function GuildWarSetAllFormationWindow:getIndex(playerID)
	for idx, item in ipairs(self.teamList_) do
		if item.player_id == playerID then
			return idx
		end
	end

	return -1
end

function GuildWarFormationSetItem:ctor(go, parent)
	self.parent_ = parent
	self.heroIconRootList_ = {}

	GuildWarFormationSetItem.super.ctor(self, go)
end

function GuildWarFormationSetItem:getPrefabPath()
	return "Prefabs/Components/guild_war_formation2"
end

function GuildWarFormationSetItem:initUI()
	local goTrans = self.go.transform
	self.goWidgt_ = self.go:GetComponent(typeof(UIWidget))
	self.teamIndexLabel_ = goTrans:ComponentByName("teamIndex", typeof(UILabel))
	self.playerNameLabel_ = goTrans:ComponentByName("playerName", typeof(UILabel))
	self.labelForce_ = goTrans:ComponentByName("labelForce", typeof(UILabel))
	self.btnSwitch_ = goTrans:NodeByName("btnSwitch").gameObject
	self.btnShowHide_ = goTrans:NodeByName("btnShowHide").gameObject
	self.imgHide_ = goTrans:NodeByName("btnShowHide/imgHide").gameObject
	self.btnSelect_ = goTrans:NodeByName("gSelect/e:image").gameObject
	self.imgSelect_ = goTrans:NodeByName("gSelect/selectImg").gameObject

	for i = 1, 6 do
		local heroIcon = {
			root = goTrans:NodeByName("groupPartner/HeroIcon" .. i).gameObject,
			cover = goTrans:NodeByName("groupPartner/HeroIcon" .. i .. "/cover").gameObject
		}

		table.insert(self.heroIconRootList_, heroIcon)
	end

	UIEventListener.Get(self.btnSelect_).onClick = handler(self, self.onClickSelect)
	UIEventListener.Get(self.btnShowHide_).onClick = handler(self, self.onClickShowHide)

	UIEventListener.Get(self.btnSwitch_).onClick = function ()
		local params = {
			currentIndex = self.parent_:getIndex(self.player_id),
			selectedNum = self.parent_.selectedNum
		}

		xyd.WindowManager.get():openWindow("guild_war_switch_team_window", params)
	end
end

function GuildWarFormationSetItem:isMember()
	return self.isMember_
end

function GuildWarFormationSetItem:isHide()
	return self.isHide_
end

function GuildWarFormationSetItem:setInfo(params, index, isHide)
	self.data_ = params
	self.player_id = params.player_id
	local data = self.data_

	if index then
		self.teamIndexLabel_.text = index

		self.imgSelect_:SetActive(true)

		self.isMember_ = true

		self.btnShowHide_:SetActive(true)
		self.btnSwitch_:SetActive(true)
	else
		self.teamIndexLabel_.text = " "

		self.imgSelect_:SetActive(false)

		self.isMember_ = false

		self.btnShowHide_:SetActive(false)
		self.btnSwitch_:SetActive(false)
	end

	self.playerNameLabel_.text = data.player_name
	local power = data.power
	self.labelForce_.text = power
	local petID = nil

	if data and data.pet then
		petID = data.pet.pet_id
	end

	for i = 1, #data.partners do
		local pos = data.partners[i].pos
		local partner = Partner.new()

		partner:populate(data.partners[i])

		local partnerInfo = partner:getInfo()
		partnerInfo.onClick = true
		partnerInfo.dragScrollView = self.parent_.scrollView_
		local heroIcon = HeroIcon.new(self.heroIconRootList_[pos].root)

		heroIcon:setInfo(partnerInfo, petID)
	end

	for i = 1, 6 do
		self.heroIconRootList_[i].cover:SetActive(isHide)
	end

	self.imgHide_:SetActive(isHide)

	self.isHide_ = isHide
end

function GuildWarFormationSetItem:updateIndex()
	local index = self.parent_:getIndex(self.player_id)

	if self.isMember_ and index > 0 then
		self.teamIndexLabel_.text = index
	else
		self.teamIndexLabel_.text = " "
	end
end

function GuildWarFormationSetItem:onClickShowHide(force)
	if not self.isMember_ and not force then
		return
	end

	if not self.isHide_ then
		if tonumber(xyd.tables.miscTable:getVal("guild_war_battle_hide_num")) <= self.parent_.hideNum then
			xyd.showToast(__("GUILD_WAR_MAX_HIDE", xyd.tables.miscTable:getVal("guild_war_battle_hide_num")))

			return
		end

		self.isHide_ = true

		for i = 1, 6 do
			self.heroIconRootList_[i].cover:SetActive(true)
		end

		self.imgHide_:SetActive(true)

		self.parent_.hideNum = self.parent_.hideNum + 1
	else
		self.isHide_ = false

		for i = 1, 6 do
			self.heroIconRootList_[i].cover:SetActive(false)
		end

		self.imgHide_:SetActive(false)

		self.parent_.hideNum = self.parent_.hideNum - 1
	end
end

function GuildWarFormationSetItem:onClickSelect()
	self.imgSelect_:SetActive(not self.isMember_)

	if not self.isMember_ then
		if tonumber(xyd.tables.miscTable:getVal("guild_war_battle_max_num")) <= self.parent_.selectedNum then
			self.imgSelect_:SetActive(self.isMember_)
			xyd.showToast(__("GUILD_WAR_TEAM_MAX", xyd.tables.miscTable:getVal("guild_war_battle_max_num")))

			return
		end

		self.isMember_ = true
		local indexBefoe = self.parent_:getIndex(self.player_id)

		table.remove(self.parent_.teamList_, indexBefoe)

		local pos = self.parent_.selectedNum + 1

		table.insert(self.parent_.teamList_, pos, self)
		self.parent_:moveTeam(self, self.go.transform, self.parent_.selectedNum)

		self.parent_.selectedNum = self.parent_.selectedNum + 1

		self.btnShowHide_:SetActive(true)
		self.btnSwitch_:SetActive(true)
	else
		self.isMember_ = false
		local indexBefoe = self.parent_:getIndex(self.player_id)

		table.remove(self.parent_.teamList_, indexBefoe)
		table.insert(self.parent_.teamList_, self.parent_.allNum, self)
		self.parent_:moveTeam(self, self.go.transform, self.parent_.allNum - 1)

		self.parent_.selectedNum = self.parent_.selectedNum - 1

		self.btnShowHide_:SetActive(false)
		self.btnSwitch_:SetActive(false)

		if self.isHide_ then
			self:onClickShowHide(true)
		end
	end

	self.parent_:updateLabelSelect()
end

function GuildWarFormationSetItem:playDisappear(onComplete)
	local seq = DG.Tweening.DOTween.Sequence()

	seq:Insert(0, self.go.transform:DOScale(Vector3(1.05, 1.05, 1), 0.1))
	seq:Insert(0.1, self.go.transform:DOScale(Vector3(0.01, 0.01, 0.01), 0.16))
	seq:AppendCallback(function ()
		onComplete()
		seq:Kill(true)

		seq = nil
	end)
end

function GuildWarFormationSetItem:playAppear(onComplete)
	local seq = DG.Tweening.DOTween.Sequence()
	self.goWidgt_.alpha = 0
	self.go.transform.localScale = Vector3(1, 1, 1)

	self.parent_.tableTeam_:Reposition()

	self.goWidgt_.alpha = 1
	self.go.transform.localScale = Vector3(0.5, 0.5, 0.5)

	seq:Insert(0, self.go.transform:DOScale(Vector3(1, 1, 1), 0.1))
	seq:AppendCallback(function ()
		if onComplete then
			onComplete()
		end

		self.parent_.tableTeam_:Reposition()
		seq:Kill(true)

		seq = nil
	end)
end

function GuildWarFormationSetItem:getPlayerId()
	return self.player_id
end

return GuildWarSetAllFormationWindow
