local BaseWindow = import(".BaseWindow")
local FriendBossFriendAssistantSettingWindow = class("FriendBossFriendAssistantSettingWindow", BaseWindow)
local FriendBossFriendAssistantIconRenderer = class("FriendBossFriendAssistantIconRenderer")
local Partner = import("app.models.Partner")
local HeroIcon = import("app.components.HeroIcon")
local PartnerFilter = import("app.components.PartnerFilter")

function FriendBossFriendAssistantSettingWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.playerIdToHeroIcon = {}
	self.totalPositionNumber = 3
	self.selectedPositionNumber = 0
	self.selectedAssistantGroup = 0
	self.skinName = "FriendBossFriendAssistantSettingWindowSkin"
	self.selectedPlayerId = {}
	self.iconIdexList = {}
end

function FriendBossFriendAssistantSettingWindow:willOpen(params)
	BaseWindow.willOpen(self, params)
end

function FriendBossFriendAssistantSettingWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	BaseWindow.register(self)
	self:initLayout()
	self:registerEvent()
	self:initTypeGroup()
	self:initSelectedPartner()
	self:initPartnerScroller()
end

function FriendBossFriendAssistantSettingWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainNode = winTrans:NodeByName("mainNode").gameObject
	self.selectAssistantTitle_ = mainNode:ComponentByName("groupTop/selectedGroup/selectAssistantTitle", typeof(UILabel))
	self.friendSharedPartnerSelectedBtn = mainNode:NodeByName("groupTop/selectedGroup/friendSharedPartnerSelectedBtn").gameObject
	self.friendSharedPartnerSelectedBtn_button_label = mainNode:ComponentByName("groupTop/selectedGroup/friendSharedPartnerSelectedBtn/button_label", typeof(UILabel))
	self.fGroup = mainNode:ComponentByName("chooseGroup/fGroup", typeof(UIWidget))
	self.partnerScroller = mainNode:NodeByName("chooseGroup/partnerScroller").gameObject
	self.partnerScroller_scroller = mainNode:ComponentByName("chooseGroup/partnerScroller", typeof(UIScrollView))
	self.partnerScroller_uiPanel = mainNode:ComponentByName("chooseGroup/partnerScroller", typeof(UIPanel))
	self.partnerContainer = mainNode:NodeByName("chooseGroup/partnerScroller/partnerContainer").gameObject
	self.partnerContainer_MultiRowWrapContent = mainNode:ComponentByName("chooseGroup/partnerScroller/partnerContainer", typeof(MultiRowWrapContent))
	self.labelWinTitle_ = mainNode:ComponentByName("groupTop/labelWinTitle", typeof(UILabel))
	self.groupTop = mainNode:NodeByName("groupTop").gameObject
	self.chooseGroup = mainNode:NodeByName("chooseGroup").gameObject
	self.closeBtn = mainNode:NodeByName("groupTop/closeBtn").gameObject
	self.hero_root = mainNode:NodeByName("chooseGroup/hero_root").gameObject
	self.partnerScroller_uiPanel.depth = winTrans:GetComponent(typeof(UIPanel)).depth + 1

	for i = 0, 2 do
		self["friendAssistantIconGroup" .. i] = mainNode:NodeByName("groupTop/selectedGroup/friendAssistantIconGroup" .. i).gameObject
		self["friendAssistantIconGroup" .. i .. "uiPanel"] = mainNode:ComponentByName("groupTop/selectedGroup/friendAssistantIconGroup" .. i, typeof(UIPanel))
		self["friendAssistantIcon" .. i] = mainNode:NodeByName("groupTop/selectedGroup/friendAssistantIconGroup" .. i .. "/friendAssistantIcon" .. i).gameObject
		self["friendIdLabel" .. i] = mainNode:ComponentByName("groupTop/selectedGroup/friendIdLabel" .. i, typeof(UILabel))
		self["friendAssistantIconGroup" .. i .. "uiPanel"].depth = self.partnerScroller_uiPanel.depth + i + 1
	end

	self.partnerMultiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.partnerScroller_scroller, self.partnerContainer_MultiRowWrapContent, self.hero_root, FriendBossFriendAssistantIconRenderer, self)
end

function FriendBossFriendAssistantSettingWindow:initLayout()
	self.labelWinTitle_.text = __("FRIEND_ASSISTANT")
	self.selectAssistantTitle_.text = __("SELECT_ONE_ASSISTANT_IN")
	self.friendSharedPartnerSelectedBtn_button_label.text = __("BATTLE_START")
end

function FriendBossFriendAssistantSettingWindow:playOpenAnimation(callback)
	FriendBossFriendAssistantSettingWindow.super.playOpenAnimation(self, callback)
	self.groupTop:SetLocalPosition(0, 810, 0)
	self.chooseGroup:SetLocalPosition(0, -1090, 0)

	self.top_tween = DG.Tweening.DOTween.Sequence()

	self.top_tween:Append(self.groupTop.transform:DOLocalMoveY(280.5, 0.5))
	self.top_tween:AppendCallback(function ()
		if self.top_tween then
			self.top_tween:Kill(true)
		end
	end)

	self.down_tween = DG.Tweening.DOTween.Sequence()

	self.down_tween:Append(self.chooseGroup.transform:DOLocalMoveY(-200.5, 0.5))
	self.down_tween:AppendCallback(function ()
		if self.down_tween then
			self.down_tween:Kill(true)
		end
	end)
end

function FriendBossFriendAssistantSettingWindow:playCloseAnimation(callback)
	if self.down_tween then
		self.down_tween:Kill(true)
	end

	if self.top_tween then
		self.top_tween:Kill(true)
	end

	FriendBossFriendAssistantSettingWindow.super.playCloseAnimation(self, callback)
end

function FriendBossFriendAssistantSettingWindow:getTargetLocal(targetObj, container)
	local targetGlobalPos = targetObj:localToGlobal()
	local targetContainerPos = container:globalToLocal(targetGlobalPos.x, targetGlobalPos.y)

	return targetContainerPos
end

function FriendBossFriendAssistantSettingWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_FRIEND_BOSS_INFO, handler(self, self.onGetFriendSharedPartner))

	for i = 0, 2 do
		UIEventListener.Get(self["friendAssistantIcon" .. i].gameObject).onClick = handler(self, function ()
			self:onClickSelectedHeroIcon(i)
		end)
	end

	UIEventListener.Get(self.friendSharedPartnerSelectedBtn.gameObject).onClick = handler(self, self.onSelectedFriendSharedPartner)
end

function FriendBossFriendAssistantSettingWindow:onGetFriendSharedPartner(event)
	self:updatePartnerDataProvider()
	self:updateSelectedPartner()
end

function FriendBossFriendAssistantSettingWindow:updateSelectedPartner()
	local i = 0

	while i < self.totalPositionNumber do
		local playerId = tonumber(xyd.db.misc:getValue("selectedPartnerPlayerId" .. tostring(i)))

		if playerId ~= nil and playerId ~= -1 then
			local friendSharedPartnerInfo = xyd.models.friend:getPlayerSharedPartner(playerId)

			if friendSharedPartnerInfo ~= nil then
				local friendSharedPartner = Partner.new()

				friendSharedPartner:populate(friendSharedPartnerInfo.shared_partner)

				friendSharedPartner.noClick = true
				friendSharedPartner.playerId = friendSharedPartnerInfo.shared_partner.playerId or friendSharedPartnerInfo.player_id
				friendSharedPartner.playerName = friendSharedPartnerInfo.shared_partner.playerName
				local copyIcon = HeroIcon.new(self["friendAssistantIcon" .. tostring(i)])

				copyIcon:setInfo(friendSharedPartner)
				self:putIconToPosition(copyIcon, i)

				self["friendIdLabel" .. tostring(i)].text = friendSharedPartner.playerName or friendSharedPartnerInfo.player_name
			end
		end

		i = i + 1
	end
end

function FriendBossFriendAssistantSettingWindow:initSelectedPartner()
	self:updateSelectedPartner()
end

function FriendBossFriendAssistantSettingWindow:initTypeGroup()
	local params = {
		isCanUnSelected = 1,
		chosenGroup = 0,
		scale = 1,
		gap = 20,
		callback = handler(self, function (self, group)
			self:onSelectGroup(group)
		end),
		width = self.fGroup:GetComponent(typeof(UIWidget)).width
	}
	local partnerFilter = PartnerFilter.new(self.fGroup.gameObject, params)
	self.partnerFilter = partnerFilter
end

function FriendBossFriendAssistantSettingWindow:onSelectGroup(group)
	if self.selectedAssistantGroup == group then
		return
	end

	self.selectedAssistantGroup = group

	self:updatePartnerDataProvider()
end

function FriendBossFriendAssistantSettingWindow:onSelectedFriendSharedPartner()
	local i = 0

	while i < self.totalPositionNumber do
		local valuePlayerId = self.selectedPlayerId[i]

		if self.selectedPlayerId[i] == nil then
			valuePlayerId = -1
		end

		xyd.db.misc:setValue({
			key = "selectedPartnerPlayerId" .. tostring(i),
			value = valuePlayerId
		})

		i = i + 1
	end

	local assistantSettingWin = xyd.WindowManager.get():getWindow("friend_boss_assistant_setting_window")

	if assistantSettingWin ~= nil then
		assistantSettingWin:updateFriendAssistantIcon()
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

function FriendBossFriendAssistantSettingWindow:updatePartnerDataProvider()
	local partnerDataList = self:getPartnerList(self.selectedAssistantGroup)

	self.partnerMultiWrap_:setInfos(partnerDataList, {})
end

function FriendBossFriendAssistantSettingWindow:getPartnerList(groupType)
	local friendSharedPartnerListTotal = xyd.models.friend:getClassifiedFriendSharedPartner()
	local friendSharedPartnerList = friendSharedPartnerListTotal[tostring(groupType)]
	local partnerList = {}

	if friendSharedPartnerList == nil then
		return partnerList
	end

	for i, partner in pairs(friendSharedPartnerList) do
		local friendSharedPartnerInfo = partner
		local isSelected = false
		local partnerData = {
			callbackFunc = function (____, heroIcon, needUpdate, isChoose, needAnimation, posId)
				self:onClickheroIcon(heroIcon, needUpdate, isChoose, needAnimation, posId)
			end,
			friendSharedPartnerInfo = friendSharedPartnerInfo,
			isSelected = isSelected
		}

		table.insert(partnerList, partnerData)
	end

	return partnerList
end

function FriendBossFriendAssistantSettingWindow:onClickheroIcon(heroIcon, needUpdate, isChoose, needAnimation, posId)
	if posId == nil then
		posId = 0
	end

	local heroInfo = heroIcon:getPartnerInfo()
	local playerId = heroInfo.playerId
	local heroPosId = self:getPartnerSelectedPosition(playerId)

	if heroPosId ~= nil then
		heroIcon.choose = false

		self:removeIconfromPosition(heroPosId)

		return
	elseif self.totalPositionNumber <= self.selectedPositionNumber then
		return
	else
		heroPosId = self:getEmptyIconPosition()
		heroIcon.choose = true
		local copyIcon = HeroIcon.new(self["friendAssistantIcon" .. tostring(heroPosId)])
		local partnerInfo = heroIcon:getPartnerInfo()

		copyIcon:setInfo(partnerInfo)
		self:putIconToPosition(copyIcon, heroPosId)

		if needAnimation then
			local nowVectoryPos = self["friendAssistantIcon" .. tostring(heroPosId)].transform.position
			copyIcon:getIconRoot().transform.position = heroIcon:getIconRoot().transform.position
			self.copyIcon_tween = DG.Tweening.DOTween.Sequence()

			self.copyIcon_tween:Append(copyIcon:getIconRoot().transform:DOMove(nowVectoryPos, 0.2))
			self.copyIcon_tween:AppendCallback(function ()
				if self.copyIcon_tween then
					self.copyIcon_tween:Kill(true)
				end
			end)
		end

		self["friendIdLabel" .. tostring(heroPosId)].text = partnerInfo.playerName
	end
end

function FriendBossFriendAssistantSettingWindow:onClickSelectedHeroIcon(index)
	if self.iconIdexList[index] == nil then
		return
	end

	local selectedFriendAssistantIcon = self.iconIdexList[index]
	local playerId = selectedFriendAssistantIcon:getPartnerInfo().playerId
	local originalIcon = self.playerIdToHeroIcon[playerId]

	if originalIcon ~= nil then
		originalIcon.choose = false
	end

	local heroPosId = self:getPartnerSelectedPosition(playerId)

	self:removeIconfromPosition(heroPosId)
end

function FriendBossFriendAssistantSettingWindow:initPartnerScroller()
	self:initPartnerDataProvider()
end

function FriendBossFriendAssistantSettingWindow:initPartnerDataProvider()
	self:updatePartnerDataProvider()
end

function FriendBossFriendAssistantSettingWindow:getPartnerSelectedPosition(playerId)
	if self.selectedPlayerId ~= nil then
		local posId = 0

		while posId < self.totalPositionNumber do
			if self.selectedPlayerId[posId] ~= nil and self.selectedPlayerId[posId] == playerId then
				return posId
			end

			posId = posId + 1
		end
	end

	return nil
end

function FriendBossFriendAssistantSettingWindow:getEmptyIconPosition()
	if self.totalPositionNumber <= self.selectedPositionNumber then
		return nil
	end

	local posId = 0

	while posId < self.totalPositionNumber do
		if self.selectedPlayerId[posId] == nil then
			return posId
		end

		posId = posId + 1
	end

	return nil
end

function FriendBossFriendAssistantSettingWindow:removeIconfromPosition(posId)
	if self.copyIcon_tween then
		self.copyIcon_tween:Kill(true)
	end

	NGUITools.DestroyChildren(self["friendAssistantIcon" .. tostring(posId)].transform)

	self["friendIdLabel" .. tostring(posId)].text = ""
	self.selectedPlayerId[posId] = nil
	self.selectedPositionNumber = self.selectedPositionNumber - 1
	self.iconIdexList[posId] = nil
end

function FriendBossFriendAssistantSettingWindow:putIconToPosition(assistantIcon, posId)
	local partnerInfo = assistantIcon:getPartnerInfo()
	self.selectedPlayerId[posId] = partnerInfo.playerId
	self.selectedPositionNumber = self.selectedPositionNumber + 1
	self.iconIdexList[posId] = assistantIcon
end

function FriendBossFriendAssistantSettingWindow:setPlayerToHeroIcon(playerId, heroIcon)
	if playerId == nil then
		return
	end

	self.playerIdToHeroIcon[playerId] = heroIcon
end

function FriendBossFriendAssistantIconRenderer:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.skinName = "FriendBossFriendAssistantSettingItemSkin"
	self.friendAssistantItem = self.uiRoot_:NodeByName("friendAssistantItem").gameObject
	self.friendAssistantIconGroup = self.uiRoot_:NodeByName("friendAssistantItem/friendAssistantIconGroup").gameObject
	self.friendId = self.uiRoot_:ComponentByName("friendAssistantItem/friendId", typeof(UILabel))
	self.friendAssistantInfoBtn = self.uiRoot_:NodeByName("friendAssistantItem/friendAssistantInfoBtn").gameObject
	self.fatherWindow = xyd.WindowManager.get():getWindow("friend_boss_friend_assistant_setting_window")

	self:createChildren()
end

function FriendBossFriendAssistantIconRenderer:createChildren()
	self:initLayout()

	self.friendAssistantIcon = HeroIcon.new(self.friendAssistantIconGroup)

	self:registerEvent()
end

function FriendBossFriendAssistantIconRenderer:getHeroIcon()
	return self.friendAssistantIcon
end

function FriendBossFriendAssistantIconRenderer:setShowActive(canShow)
	self.uiRoot_.gameObject:SetActive(canShow)
end

function FriendBossFriendAssistantIconRenderer:getGameObject()
	return self.uiRoot_
end

function FriendBossFriendAssistantIconRenderer:initLayout()
	self.friendId.text = "playerId"
end

function FriendBossFriendAssistantIconRenderer:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.data = info

	self.uiRoot_:SetActive(true)

	if self.data.friendSharedPartnerInfo.shared_partner == nil then
		return
	end

	if self.data.friendSharedPartnerInfo.shared_partner.table_id == nil and self.data.friendSharedPartnerInfo.shared_partner.tableID == nil then
		return
	end

	local friendSharedPartner = Partner.new()

	friendSharedPartner:populate(self.data.friendSharedPartnerInfo.shared_partner)

	friendSharedPartner.noClick = true
	friendSharedPartner.playerId = self.data.friendSharedPartnerInfo.player_id
	friendSharedPartner.playerName = self.data.friendSharedPartnerInfo.player_name

	self.friendAssistantIcon:setInfo(friendSharedPartner)

	self.baseinfo = friendSharedPartner
	self.friendId.text = self.data.friendSharedPartnerInfo.player_name
	local partnerPosId = self.fatherWindow:getPartnerSelectedPosition(self.data.friendSharedPartnerInfo.player_id)

	if partnerPosId ~= nil then
		self.friendAssistantIcon.choose = true
	else
		self.friendAssistantIcon.choose = false
	end

	self.fatherWindow:setPlayerToHeroIcon(self.data.friendSharedPartnerInfo.player_id, self.friendAssistantIcon)

	self.tableId = self.data.friendSharedPartnerInfo.shared_partner.tableID
end

function FriendBossFriendAssistantIconRenderer:registerEvent()
	UIEventListener.Get(self.friendAssistantIconGroup.gameObject).onClick = handler(self, self.onSelectTouch)
	UIEventListener.Get(self.friendAssistantInfoBtn.gameObject).onClick = handler(self, self.onFriendAssistantInfoTouch)
end

function FriendBossFriendAssistantIconRenderer:onSelectTouch()
	self.data.callbackFunc(self, self.friendAssistantIcon, true, self.friendAssistantIcon.choose, true)
end

function FriendBossFriendAssistantIconRenderer:onFriendAssistantInfoTouch()
	local partnerInfo = self.data.friendSharedPartnerInfo.shared_partner
	local tempPartnerInfo = {
		equipments = partnerInfo.equips,
		tableID = self.baseinfo.tableID,
		awake = partnerInfo.awake,
		lev = self.baseinfo.lev,
		ex_skills = self.data.friendSharedPartnerInfo.shared_partner.ex_skills,
		noWays = true
	}

	xyd.WindowManager.get():openWindow("partner_info", tempPartnerInfo)
end

return FriendBossFriendAssistantSettingWindow
