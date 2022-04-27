local BaseWindow = import(".BaseWindow")
local FriendBossMyAssistantSettingWindow = class("FriendBossMyAssistantSettingWindow", BaseWindow)
local Partner = import("app.models.Partner")
local HeroIcon = import("app.components.HeroIcon")
local FriendBossMyAssistantIconRenderer = class("FriendBossMyAssistantIconRenderer")
local PartnerFilter = import("app.components.PartnerFilter")
local cjson = require("cjson")

function FriendBossMyAssistantSettingWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	if params then
		self.windowType_ = params.type
		self.cellId_ = params.cell_id
		self.selectedPartners_ = params.selected_partners
	end

	self.SlotModel = xyd.models.slot
end

function FriendBossMyAssistantSettingWindow:willOpen(params)
	BaseWindow.willOpen(self, params)
end

function FriendBossMyAssistantSettingWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	BaseWindow.register(self)
	self:initLayout()
	self:registerEvent()
	self:initTypeGroup()
	self:initSelectedPartner()
	self:initPartnerScroller()
end

function FriendBossMyAssistantSettingWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainNode = winTrans:NodeByName("mainNode").gameObject
	self.selectAssistantTitle = mainNode:ComponentByName("groupTop/selectedGroup/selectAssistantTitle", typeof(UILabel))
	self.myAssistantIcon = mainNode:NodeByName("groupTop/selectedGroup/myAssistantIconGroup/myAssistantIcon").gameObject
	self.myAssistantIcon_uiPanel = mainNode:ComponentByName("groupTop/selectedGroup/myAssistantIconGroup/myAssistantIcon", typeof(UIPanel))
	self.selectedBtn = mainNode:NodeByName("groupTop/selectedGroup/selectedBtn").gameObject
	self.selectedBtn_button_label = mainNode:ComponentByName("groupTop/selectedGroup/selectedBtn/button_label", typeof(UILabel))
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
	self.myAssistantIcon_uiPanel.depth = self.partnerScroller_uiPanel.depth + 1
	self.partnerMultiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.partnerScroller_scroller, self.partnerContainer_MultiRowWrapContent, self.hero_root, FriendBossMyAssistantIconRenderer, self)
end

function FriendBossMyAssistantSettingWindow:initLayout()
	self.labelWinTitle_.text = __("MY_ASSISTANT")

	if self.windowType_ == "fairy_tale" then
		self.labelWinTitle_.text = __("ACTIVITY_FAIRY_TALE_HELP_TITL")
		self.selectAssistantTitle.text = __("ACTIVITY_FAIRY_TALE_HELP_SELETE")
	end

	self.selectAssistantTitle.text = __("SELECT_ONE_ASSISTANT_OUT")
	self.selectedBtn_button_label.text = __("BATTLE_START")
end

function FriendBossMyAssistantSettingWindow:initSelectedPartner()
	local mySharedPartnerInfo = xyd.models.friend:getMySharedPartner()

	if self.windowType_ == "fairy_tale" then
		mySharedPartnerInfo = nil
	end

	if mySharedPartnerInfo == nil or mySharedPartnerInfo.shared_partner == nil then
		return
	end

	if mySharedPartnerInfo.shared_partner.table_id == nil and mySharedPartnerInfo.shared_partner.tableID == nil then
		return
	end

	NGUITools.DestroyChildren(self.myAssistantIcon.transform)

	local mySharedPartner = Partner.new()

	mySharedPartner:populate(mySharedPartnerInfo.shared_partner)

	local mySharedPartnerIcon = HeroIcon.new(self.myAssistantIcon)
	mySharedPartner.noClick = true

	mySharedPartnerIcon:setInfo(mySharedPartner)

	self.selectedPartnerId = mySharedPartnerInfo.shared_partner.partner_id
end

function FriendBossMyAssistantSettingWindow:playOpenAnimation(callback)
	FriendBossMyAssistantSettingWindow.super.playOpenAnimation(self, callback)
	self.groupTop:SetLocalPosition(0, 810, 0)
	self.chooseGroup:SetLocalPosition(0, -1090, 0)

	self.top_tween = DG.Tweening.DOTween.Sequence()

	self.top_tween:Append(self.groupTop.transform:DOLocalMoveY(83, 0.5))
	self.top_tween:AppendCallback(function ()
		if self.top_tween then
			self.top_tween:Kill(true)
		end
	end)

	self.down_tween = DG.Tweening.DOTween.Sequence()

	self.down_tween:Append(self.chooseGroup.transform:DOLocalMoveY(-399, 0.5))
	self.down_tween:AppendCallback(function ()
		if self.down_tween then
			self.down_tween:Kill(true)
		end
	end)
end

function FriendBossMyAssistantSettingWindow:playCloseAnimation(callback)
	if self.down_tween then
		self.down_tween:Kill(true)
	end

	if self.top_tween then
		self.top_tween:Kill(true)
	end

	FriendBossMyAssistantSettingWindow.super.playCloseAnimation(self, callback)
end

function FriendBossMyAssistantSettingWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_FRIEND_BOSS_INFO, handler(self, self.onGetFriendBossInfo))

	UIEventListener.Get(self.myAssistantIcon.gameObject).onClick = handler(self, self.onClickSelectedHeroIcon)
	UIEventListener.Get(self.selectedBtn.gameObject).onClick = handler(self, self.onSelectedTouch)
end

function FriendBossMyAssistantSettingWindow:onGetFriendBossInfo(event)
	self:cleanUpSelectedInfo()
	self:initTypeGroup()
	self:initSelectedPartner()
	self:initPartnerScroller()
end

function FriendBossMyAssistantSettingWindow:cleanUpSelectedInfo()
	self.selectedPartnerId = -1

	self.myAssistantIcon:removeChildren()
end

function FriendBossMyAssistantSettingWindow:initPartnerScroller()
	self:initPartnerDataProvider()
end

function FriendBossMyAssistantSettingWindow:initPartnerDataProvider()
	self:updatePartnerDataProvider(0)
end

function FriendBossMyAssistantSettingWindow:initTypeGroup()
	local fParams = {
		isCanUnSelected = 1,
		chosenGroup = 0,
		scale = 1,
		gap = 20,
		width = self.fGroup.width,
		callback = handler(self, function (self, group)
			self:onSelectGroup(group)
		end)
	}
	local selectGroup = PartnerFilter.new(self.fGroup.gameObject, fParams)
end

function FriendBossMyAssistantSettingWindow:onSelectGroup(group)
	if self.selectedGroup == group then
		return
	end

	self.selectedGroup = group

	self:updatePartnerDataProvider(group)
end

function FriendBossMyAssistantSettingWindow:updatePartnerDataProvider(type)
	local partnerDataList = self:getPartnerList(type)

	self:updateSelectedPartner()
	self.partnerMultiWrap_:setInfos(partnerDataList, {})
end

function FriendBossMyAssistantSettingWindow:setSelectedPartnerIcon(heroIcon)
	self.selectedPartnerIcon = heroIcon
end

function FriendBossMyAssistantSettingWindow:updateSelectedPartner()
end

function FriendBossMyAssistantSettingWindow:getPartnerList(groupType)
	local partnerSortedListTotal = self.SlotModel:getSortedPartners()
	local partnerSortedList = partnerSortedListTotal[tostring(xyd.partnerSortType.LEV) .. "_" .. tostring(groupType)]
	local partnerList = {}

	for i, partnerId in ipairs(partnerSortedList) do
		local partnerInfo = self.SlotModel:getPartner(tonumber(partnerId))
		partnerInfo.noClick = true
		local isSelected = false

		if self.selectedPartnerId == partnerId then
			isSelected = true
		end

		local partnerData = {
			callbackFunc = function (____, heroIcon, needUpdate, isChoose, needAnimation, posId)
				self:onClickheroIcon(heroIcon, needUpdate, isChoose, needAnimation, posId)
			end,
			partnerInfo = partnerInfo,
			isSelected = isSelected
		}

		table.insert(partnerList, partnerData)
	end

	return partnerList
end

function FriendBossMyAssistantSettingWindow:onClickheroIcon(heroIcon, needUpdate, isChoose, needAnimation, posId)
	if posId == nil then
		posId = 0
	end

	local heroInfo = heroIcon:getPartnerInfo()

	if self.selectedPartnerId ~= nil then
		if self.selectedPartnerId == heroInfo.partnerID then
			if needAnimation then
				-- Nothing
			end

			self.selectedPartnerId = nil
			heroIcon.choose = false

			if self.copyIcon_tween then
				self.copyIcon_tween:Kill(true)
			end

			NGUITools.DestroyChildren(self.myAssistantIcon.transform)

			return
		else
			return
		end
	end

	self.selectedPartnerId = heroIcon:getPartnerInfo().partnerID
	heroIcon.choose = true
	local copyIcon = HeroIcon.new(self.myAssistantIcon)
	local partnerInfo = heroIcon:getPartnerInfo()
	self.selectedPartnerIcon = heroIcon

	copyIcon:setInfo(partnerInfo)

	if needAnimation then
		local nowVectoryPos = self.myAssistantIcon.transform.position
		copyIcon:getIconRoot().transform.position = heroIcon:getIconRoot().transform.position
		self.copyIcon_tween = DG.Tweening.DOTween.Sequence()

		self.copyIcon_tween:Append(copyIcon:getIconRoot().transform:DOMove(nowVectoryPos, 0.2))
		self.copyIcon_tween:AppendCallback(function ()
			if self.copyIcon_tween then
				self.copyIcon_tween:Kill(true)
			end
		end)
	end
end

function FriendBossMyAssistantSettingWindow:getTargetLocal(targetObj, container)
	local targetGlobalPos = targetObj:localToGlobal()
	local targetContainerPos = container:globalToLocal(targetGlobalPos.x, targetGlobalPos.y)

	return targetContainerPos
end

function FriendBossMyAssistantSettingWindow:onClickSelectedHeroIcon()
	if self.selectedPartnerId == nil then
		return
	end

	self.selectedPartnerId = nil

	if self.selectedPartnerIcon ~= nil then
		self.selectedPartnerIcon.choose = false
	end

	NGUITools.DestroyChildren(self.myAssistantIcon.transform)
end

function FriendBossMyAssistantSettingWindow:isPartnerSelected(partnerId)
	if self.selectedPartnerId ~= nil and partnerId == self.selectedPartnerId then
		return true
	else
		return false
	end
end

function FriendBossMyAssistantSettingWindow:isPartnerLock(partnerId)
	if self.selectedPartners_ and #self.selectedPartners_ > 0 then
		local index = xyd.arrayIndexOf(self.selectedPartners_, partnerId)

		if index and index > 0 then
			return true
		else
			return false
		end
	else
		return false
	end
end

function FriendBossMyAssistantSettingWindow:onSelectedTouch()
	if self.windowType_ == "fairy_tale" then
		if self.selectedPartnerId ~= nil then
			local msg = messages_pb.fairy_challenge_req()
			msg.activity_id = xyd.ActivityID.FAIRY_TALE
			msg.cell_id = self.cellId_
			msg.params = cjson.encode({
				partner_id = self.selectedPartnerId
			})

			xyd.Backend.get():request(xyd.mid.FAIRY_CHALLENGE, msg)
			xyd.WindowManager.get():closeWindow(self.name_)
		else
			xyd.showToast(__("FAIRY_TALE_HELP_RESTRICT"))
		end
	elseif self.selectedPartnerId ~= nil then
		xyd.models.friend:setMySharedPartner(self.selectedPartnerId)
		xyd.db.misc:setValue({
			key = "selectedSharedPartner",
			value = self.selectedPartnerId
		})
		xyd.WindowManager.get():closeWindow(self.name_)
	else
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function FriendBossMyAssistantSettingWindow:isEmpty()
	if self.myAssistantIcon.numChildren == 0 then
		return true
	else
		return false
	end
end

function FriendBossMyAssistantIconRenderer:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.fatherWindow = xyd.WindowManager.get():getWindow("friend_boss_my_assistant_setting_window")

	self:createChildren()
end

function FriendBossMyAssistantIconRenderer:getHeroIcon()
	return self.heroIcon
end

function FriendBossMyAssistantIconRenderer:getPartnerId()
	return self.partnerId_
end

function FriendBossMyAssistantIconRenderer:setShowActive(canShow)
	self.uiRoot_.gameObject:SetActive(canShow)
end

function FriendBossMyAssistantIconRenderer:getGameObject()
	return self.uiRoot_
end

function FriendBossMyAssistantIconRenderer:createChildren()
	NGUITools.DestroyChildren(self.uiRoot_.transform)

	self.heroIcon = HeroIcon.new(self.uiRoot_, self.parent_.partnerScroller_uiPanel)

	self:registerEvent()
end

function FriendBossMyAssistantIconRenderer:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.data = info

	self.heroIcon:setInfo(self.data.partnerInfo)

	self.partner_ = info.partnerInfo
	self.partnerId_ = self.partner_.partnerID
	local isChoose = self.fatherWindow:isPartnerSelected(self.data.partnerInfo.partnerID)
	self.isLock_ = self.fatherWindow:isPartnerLock(self.data.partnerInfo.partnerID)
	self.heroIcon.choose = isChoose

	if isChoose then
		self.fatherWindow:setSelectedPartnerIcon(self.heroIcon)
	end

	if self.isLock_ then
		self.parent_:waitForFrame(5, function ()
			self.heroIcon:setGrey()
		end)
		self.heroIcon:setNoClick(true)
	else
		self.heroIcon:setNoClick(false)
	end
end

function FriendBossMyAssistantIconRenderer:registerEvent()
	UIEventListener.Get(self.uiRoot_.gameObject).onClick = handler(self, self.onSelectTouch)
end

function FriendBossMyAssistantIconRenderer:onSelectTouch()
	if not self.isLock_ then
		self.data.callbackFunc(self, self.heroIcon, true, self.heroIcon.choose, true)
	end
end

return FriendBossMyAssistantSettingWindow
