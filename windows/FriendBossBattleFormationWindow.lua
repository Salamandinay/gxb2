local BattleFormationWindow = import(".BattleFormationWindow")
local FriendBossBattleFormationWindow = class("FriendBossBattleFormationWindow", BattleFormationWindow)

function FriendBossBattleFormationWindow:ctor(name, params)
	BattleFormationWindow.ctor(self, name, params)

	self.friendPartnerNum = 3
	self.petId = -1
	self.flag = false
	self.skinName = "FriendBossBattleFormationWindowSkin"
end

function FriendBossBattleFormationWindow:willOpen(params)
	BattleFormationWindow.willOpen(self, params)
end

function FriendBossBattleFormationWindow:initWindow()
	BattleFormationWindow.initWindow(self)
	self:getUIComponent()
	self:initLayout()
	self:initFriendPartner()
end

function FriendBossBattleFormationWindow:getUIComponent()
	FriendBossBattleFormationWindow.super.getUIComponent(self)

	local winTrans = self.window_.transform
	local friendSharedPartnerGroup = winTrans:NodeByName("main/choose_group/friendSharedPartnerGroup").gameObject

	for i = 0, 2 do
		self["friendAssistantIconGroup" .. i] = friendSharedPartnerGroup:NodeByName("friendAssistantIconGroup" .. i).gameObject
		self["friendAssistantIcon" .. i] = self["friendAssistantIconGroup" .. i]:NodeByName("friendAssistantIcon" .. i).gameObject
		self["assistSubscript" .. i] = self["friendAssistantIconGroup" .. i]:NodeByName("assistSubscript" .. i).gameObject
	end

	self.assistLabel = friendSharedPartnerGroup:ComponentByName("assistLabel", typeof(UILabel))
end

function FriendBossBattleFormationWindow:initLayout()
	self.labelWinTitle.text = __("BATTLE_FORMATION_WIN")
	self.assistLabel.text = __("ASSISTANT")
end

function FriendBossBattleFormationWindow:addTitle()
	self.labelWinTitle.text = __("BATTLE_FORMATION_WIN")
	self.assistLabel.text = __("ASSISTANT")
end

function FriendBossBattleFormationWindow:initFriendPartner()
	local Partner = import("app.models.Partner")
	local i = 0

	while i < self.friendPartnerNum do
		local playerId = tonumber(xyd.db.misc:getValue("selectedPartnerPlayerId" .. tostring(i)))

		self["assistSubscript" .. tostring(i)]:SetActive(false)

		if playerId ~= nil and playerId ~= -1 then
			local friendSharedPartnerInfo = xyd.models.friend:getPlayerSharedPartner(playerId)

			if friendSharedPartnerInfo ~= nil then
				local partnerInfo = friendSharedPartnerInfo.shared_partner
				local partner = Partner.new()

				partner:populate(partnerInfo)

				partner.noClick = true
				partner.partnerType = "FriendSharedPartner"
				local partnerInfo = {
					partnerType = "FriendSharedPartner",
					noClick = true,
					tableID = partner:getTableID(),
					lev = partner:getLevel(),
					awake = partner.awake,
					group = partner:getGroup(),
					grade = partner:getGrade(),
					skin_id = partner:getSkinId(),
					is_vowed = partner.is_vowed,
					partnerID = tonumber(friendSharedPartnerInfo.playerId or friendSharedPartnerInfo.player_id),
					partner_id = tonumber(friendSharedPartnerInfo.playerId or friendSharedPartnerInfo.player_id),
					power = partner:getPower(),
					star = partner.star
				}

				NGUITools.DestroyChildren(self["friendAssistantIcon" .. tostring(i)].transform)

				local partnerIcon = BattleFormationWindow.FormationItem.new(self["friendAssistantIcon" .. tostring(i)], self, self)

				partnerIcon:setIsFriend(true)

				local isS = self:isSelected(partnerInfo.partnerID, self.nowPartnerList, false)
				local data = {
					callbackFunc = function (heroIcon, needUpdate, isChoose, needAnimation, posId)
						self:onClickheroIcon(heroIcon, needUpdate, isChoose, needAnimation, posId, true)
					end,
					partnerInfo = partnerInfo,
					isSelected = isS.isSelected
				}

				partnerIcon:update(nil, , data)
				self["assistSubscript" .. tostring(i)]:SetActive(true)
			end
		end

		i = i + 1
	end
end

function FriendBossBattleFormationWindow:updateFriendPartnerState()
	self:initFriendPartner()
end

function FriendBossBattleFormationWindow:friendPartnerIsSelect()
	return self.flag
end

function FriendBossBattleFormationWindow:setFriendPartnerIsSelect(f)
	self.flag = f
end

function FriendBossBattleFormationWindow:fightBoss(partnerParams)
	local selectedBossLevel = xyd.models.friend:getSelectedBossLevel()
	partnerParams.stage_id = tonumber(selectedBossLevel)

	if self.pet ~= -1 then
		partnerParams.pet_id = self.pet
	end

	local msg = messages_pb:friend_boss_fight_req()
	msg.stage_id = tonumber(selectedBossLevel)

	if self.pet ~= -1 then
		msg.pet_id = self.pet
	else
		msg.pet_id = 0
	end

	for i in ipairs(partnerParams.partners) do
		local tempMsg = messages_pb:partner_with_pos()

		if partnerParams.partners[i].partner_id ~= nil then
			tempMsg.partner_id = tonumber(partnerParams.partners[i].partner_id)
		end

		if partnerParams.partners[i].player_id ~= nil or partnerParams.partners[i].playerId ~= nil then
			tempMsg.player_id = tonumber(partnerParams.partners[i].player_id or partnerParams.partners[i].playerId)
		end

		tempMsg.pos = partnerParams.partners[i].pos

		table.insert(msg.partners, tempMsg)
	end

	xyd.models.friend:FightBoss(msg)
	xyd.WindowManager.get():closeWindow(self.name_)
end

return FriendBossBattleFormationWindow
