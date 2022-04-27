local BattleFormationWindow = import(".BattleFormationWindow")
local ActivityFairyTaleBattleFormationWindow = class("ActivityFairyTaleBattleFormationWindow", BattleFormationWindow)

function ActivityFairyTaleBattleFormationWindow:ctor(name, params)
	ActivityFairyTaleBattleFormationWindow.super.ctor(self, name, params)

	self.npc_list_ = params.npc_list
	self.npcPartnerNum = 5
	self.petId = -1
	self.cellId_ = params.cell_id
	self.npcIconList_ = {}
end

function ActivityFairyTaleBattleFormationWindow:initWindow()
	ActivityFairyTaleBattleFormationWindow.super.initWindow(self)
	self:getUIComponent()
	self:initLayout()
	self:initNpcPartner()
end

function ActivityFairyTaleBattleFormationWindow:getUIComponent()
	local winTrans = self.window_.transform
	local npcPartnerGroup = winTrans:NodeByName("main/choose_group/npcPartnerGroup").gameObject

	for i = 1, 5 do
		self["NPCIconGroup" .. i] = npcPartnerGroup:NodeByName("npcIconGroup" .. i).gameObject
		self["NPCIcon" .. i] = self["NPCIconGroup" .. i]:NodeByName("friendAssistantIcon0").gameObject
		self["assistSubscript" .. i] = self["NPCIconGroup" .. i]:NodeByName("assistSubscript0").gameObject
		local label = self["NPCIconGroup" .. i]:ComponentByName("assistSubscript0/npcTips", typeof(UILabel))
		label.text = __("NPC")
	end

	self.mask1 = self.frontGroup:Find("mask1")
	self.mask2 = self.frontGroup:Find("mask2")
	self.mask3 = self.backGroup:Find("mask3")
	self.mask4 = self.backGroup:Find("mask4")
	self.mask5 = self.backGroup:Find("mask5")
	self.mask6 = self.backGroup:Find("mask6")
	self.assistLabel = npcPartnerGroup:ComponentByName("assistLabel", typeof(UILabel))
end

function ActivityFairyTaleBattleFormationWindow:initLayout()
	self.assistLabel.text = __("ASSISTANT")
end

function ActivityFairyTaleBattleFormationWindow:playOpenAnimation(callback)
	self.labelWinTitle.text = __("BATTLE_FORMATION_WIN")

	ActivityFairyTaleBattleFormationWindow.super.playOpenAnimation(self, callback)
end

function ActivityFairyTaleBattleFormationWindow:initNpcPartner()
	local Monster = import("app.models.Monster")
	local i = 1

	while i <= self.npcPartnerNum do
		self["assistSubscript" .. tostring(i)]:SetActive(false)

		local monsterId = self.npc_list_[i]

		if monsterId ~= nil then
			local partner = Monster.new()

			partner:populateWithTableID(monsterId)

			partner.noClick = true
			partner.partnerType = "npcPartner"
			local partnerInfo = {
				partnerType = "npcPartner",
				is_npc = true,
				noClick = true,
				tableID = xyd.tables.monsterTable:getPartnerLink(monsterId),
				lev = partner:getLevel(),
				awake = partner.awake,
				group = partner:getGroup(),
				grade = partner:getGrade(),
				partnerID = monsterId,
				power = partner:getPower()
			}

			NGUITools.DestroyChildren(self["NPCIcon" .. tostring(i)].transform)

			local partnerIcon = BattleFormationWindow.FormationItem.new(self["NPCIcon" .. tostring(i)], self)
			local isS = self:isSelected(partnerInfo.tableID, self.nowPartnerList, false)
			local data = {
				callbackFunc = function (heroIcon, needUpdate, isChoose, needAnimation, posId)
					local posId = self:onClickheroIcon(heroIcon, needUpdate, isChoose, needAnimation, posId, true)

					return posId
				end,
				partnerInfo = partnerInfo,
				isSelected = isS.isSelected
			}

			partnerIcon:update(nil, , data)

			self.npcIconList_[i] = partnerIcon

			self["assistSubscript" .. tostring(i)]:SetActive(true)
		end

		i = i + 1
	end
end

function ActivityFairyTaleBattleFormationWindow:getNpcSelectPos()
	return self.npc_pos_
end

function ActivityFairyTaleBattleFormationWindow:setNpcSelectPos(posId)
	self.npc_pos_ = posId

	self:updateMask()
end

function ActivityFairyTaleBattleFormationWindow:onClickheroIcon(partnerInfo, isChoose, pos, needAnimation, posId, isNpc)
	if self.needSound then
		-- Nothing
	end

	if isChoose == false and isNpc ~= nil and isNpc == true then
		local Win = xyd.WindowManager.get():getWindow("activity_fairy_tale_formation_window")

		if Win and Win:getNpcSelectPos() then
			xyd.alert(xyd.AlertType.TIPS, __("ASSISTANT_LIMIT"))

			return -1
		end
	end

	local posId = nil

	if isChoose then
		local params = self:isSelected(partnerInfo.partnerID, self.nowPartnerList)
		local isChoose = params.isSelected
		posId = params.posId

		if posId >= 0 then
			local container = self["container" .. tostring(posId)]
			local heroIcon = container.transform:NodeByName("hero_icon").gameObject
			local progress = self["progress" .. tostring(posId)]

			if heroIcon then
				NGUITools.Destroy(heroIcon)
			end

			if progress then
				progress.value = 0
			end

			if isNpc then
				self.selectedNum = self.selectedNum - 2
			else
				self.selectedNum = self.selectedNum - 1
			end

			self.copyIconList[posId] = nil
			self.nowPartnerList[posId] = nil

			if xyd.BattleType.FAIRY_TALE == self.battleType and isNpc == true then
				local win = xyd.WindowManager.get():getWindow("activity_fairy_tale_formation_window")

				if win then
					win:initNpcPartner()
					win:setNpcSelectPos(nil)
				end
			end

			return posId
		end
	else
		posId = -1

		if self.selectedNum == self.defaultMaxNum then
			return
		end

		if pos ~= nil and pos >= 1 then
			posId = pos
		else
			for i = 1, self.defaultMaxNum do
				if not self.copyIconList[i] then
					if isNpc then
						if posId == -1 and i ~= 2 and i ~= 6 and not self.copyIconList[i + 1] then
							posId = i

							break
						end
					elseif posId == -1 and (not self.npc_pos_ or self.npc_pos_ and i ~= self.npc_pos_ + 1) then
						posId = i

						break
					end
				end
			end
		end

		if posId == -1 then
			if isNpc then
				xyd.showToast(__("FAIRY_TALE_NPC_LOCATION_RESTRICT"))
			end

			return posId
		end

		local function copyCallback(copyIcon)
			self:iconTapHandler(copyIcon:getPartnerInfo(), isNpc)
		end

		local copyPartnerInfo = {
			noClickSelected = true,
			tableID = partnerInfo.tableID,
			lev = partnerInfo.lev,
			star = partnerInfo.star,
			skin_id = partnerInfo.skin_id,
			is_vowed = partnerInfo.is_vowed,
			posId = posId,
			callback = copyCallback,
			awake = partnerInfo.awake,
			grade = partnerInfo.grade,
			group = partnerInfo.group or partnerInfo:getGroup(),
			partnerID = partnerInfo.partnerID,
			power = partnerInfo.power or partnerInfo:getPower(),
			partnerType = partnerInfo.partnerType,
			is_npc = isNpc
		}
		local copyIcon = import("app.components.HeroIcon").new(self["container" .. tostring(posId)].gameObject)

		copyIcon:setInfo(copyPartnerInfo, self.pet)

		if isNpc then
			self.selectedNum = self.selectedNum + 2
		else
			self.selectedNum = self.selectedNum + 1
		end

		local function startCallback(callbackCopyIcon)
			self:startDrag(callbackCopyIcon)
		end

		local function dragCallback(callbackCopyIcon, delta)
			self:onDrag(callbackCopyIcon, delta)
		end

		local function endCallback(callbackCopyIcon)
			self:endDrag(callbackCopyIcon)
		end

		local function longPressCallback(callbackCopyIcon)
			self:longPressIcon(callbackCopyIcon)
		end

		copyIcon:setTouchDragListener(startCallback, dragCallback, endCallback)

		if isNpc == false or isNpc == nil then
			copyIcon:setLongPressListener(longPressCallback)
		end

		self.copyIconList[posId] = copyIcon
		self.nowPartnerList[posId] = partnerInfo.partnerID

		if xyd.BattleType.FAIRY_TALE == self.battleType then
			local win = xyd.WindowManager.get():getWindow("activity_fairy_tale_formation_window")

			if win and isNpc then
				win:setNpcSelectPos(posId)
			end
		end
	end

	self:updateForceNum()
	self:updateBuff()

	return posId
end

function ActivityFairyTaleBattleFormationWindow:iconTapHandler(copyPartnerInfo, isNpc)
	if self.isShowGuide_ then
		return
	end

	if self.isMovingAfterDrag then
		return
	end

	local partnerInfo = copyPartnerInfo
	local params = self:isSelected(partnerInfo.partnerID, self.nowPartnerList)
	local isChoose = params.isSelected
	local posId = params.posId

	if posId >= 0 then
		NGUITools.Destroy(self.copyIconList[posId].go)

		local fItem = self:getFormationItemByPartnerID(partnerInfo.partnerID)

		if fItem then
			fItem:setIsChoose(false)
		end

		if isNpc then
			self.selectedNum = self.selectedNum - 2
			self.npc_pos_ = nil
			local npcItem = self:getNpcIcon(partnerInfo.partnerID)

			if npcItem then
				npcItem:setIsChoose(false)
			end
		else
			self.selectedNum = self.selectedNum - 1
		end

		self.copyIconList[posId] = nil
		self.nowPartnerList[posId] = nil
	end

	self:updateForceNum()
	self:updateBuff()

	if xyd.BattleType.FAIRY_TALE == self.battleType and isNpc == true then
		local win = xyd.WindowManager.get():getWindow("activity_fairy_tale_formation_window")

		if win then
			win:initNpcPartner()
			win:setNpcSelectPos(nil)
		end
	end
end

function ActivityFairyTaleBattleFormationWindow:endDrag(copyIcon)
	if not self.isStartDrag then
		return
	end

	self.isStartDrag = false
	self.isMovingAfterDrag = true
	local partnerInfo = copyIcon:getPartnerInfo()
	local posId = tonumber(partnerInfo.posId)
	local cPosId = self:isChange(copyIcon)
	local aniDurition = 0.2
	local container = self["container" .. posId]
	local endPosition = self.dragPanelTran:InverseTransformPoint(container.position)
	local endContainer = container
	local canMoveNpc = (not self.nowPartnerList[cPosId + 1] or self.nowPartnerList[cPosId + 1] and cPosId + 1 == self.npc_pos_) and cPosId > 0 and cPosId ~= 2 and cPosId ~= 6
	local isNpc = self.npc_pos_ and self.npc_pos_ == posId
	local isTargetNpc = self.npc_pos_ and cPosId == self.npc_pos_
	local canChangeNpc = not self.nowPartnerList[posId + 1] and posId > 0 and posId ~= 2 and posId ~= 6

	if cPosId > 0 and self:chackCanMove(posId, cPosId) then
		aniDurition = 0.1
		local cContainer = self["container" .. tostring(cPosId)]
		local cCopyIcon = self.copyIconList[cPosId]
		local tmpPartnerId = self.nowPartnerList[cPosId]
		endPosition = self.dragPanelTran:InverseTransformPoint(cContainer.position)
		endContainer = cContainer

		if cCopyIcon then
			local cEndPosition = cContainer:InverseTransformPoint(container.position)
			local cContainerWidget = cContainer.gameObject:GetComponent(typeof(UIWidget))
			local cGo = cCopyIcon.go
			local cTrans = cGo.transform
			local cInfo = cCopyIcon:getPartnerInfo()
			local sequence = DG.Tweening.DOTween.Sequence()

			sequence:Append(cTrans:DOLocalMove(cEndPosition, 0.1):SetEase(DG.Tweening.Ease.OutSine))
			sequence:AppendCallback(function ()
				cTrans.parent = container
				local offsetDepth = cContainerWidget.depth

				cCopyIcon:setDepth(offsetDepth)
				cCopyIcon:SetActive(false)
				cCopyIcon:SetActive(true)

				cCopyIcon.noClick = false

				cCopyIcon:updatePartnerInfo({
					posId = posId
				})

				if isTargetNpc and canChangeNpc then
					self:setNpcSelectPos(posId)
				end

				sequence:Kill(false)
			end)

			if self["progress" .. cPosId] and self["progress" .. posId] then
				self["progress" .. cPosId].value = xyd.models.trial:getHp(partnerInfo.partnerID)
				self["progress" .. posId].value = xyd.models.trial:getHp(cInfo.partnerID)
			end
		end

		self.nowPartnerList[cPosId] = self.nowPartnerList[posId]
		self.nowPartnerList[posId] = tmpPartnerId
		self.copyIconList[cPosId] = self.copyIconList[posId]
		self.copyIconList[posId] = cCopyIcon

		if self["progress" .. cPosId] then
			self["progress" .. cPosId].value = xyd.models.trial:getHp(partnerInfo.partnerID)
		end
	elseif cPosId > 0 and isNpc and not canMoveNpc or isTargetNpc and not canChangeNpc then
		cPosId = -1
	else
		cPosId = -1
	end

	local containerWidget = endContainer.gameObject:GetComponent(typeof(UIWidget))
	local go = copyIcon.go
	local trans = go.transform
	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Append(trans:DOLocalMove(endPosition, aniDurition):SetEase(DG.Tweening.Ease.OutSine))
	sequence:AppendCallback(function ()
		trans.parent = endContainer
		local offsetDepth = containerWidget.depth

		copyIcon:setDepth(offsetDepth)
		copyIcon:SetActive(false)
		copyIcon:SetActive(true)

		copyIcon.noClick = false

		if cPosId > 0 then
			copyIcon:updatePartnerInfo({
				posId = cPosId
			})

			if isNpc and canMoveNpc then
				self:setNpcSelectPos(cPosId)
			end
		end

		self.isMovingAfterDrag = false

		sequence:Kill(false)

		sequence = nil
	end)
end

function ActivityFairyTaleBattleFormationWindow:getNpcIcon(partnerID)
	for _, formationItem in ipairs(self.npcIconList_) do
		if formationItem:getPartnerId() == partnerID then
			return formationItem
		end
	end
end

function ActivityFairyTaleBattleFormationWindow:isChange(copyIcon)
	if self.isShowGuide_ then
		return self:isGuideChange(copyIcon)
	end

	local pInfo = copyIcon:getPartnerInfo()
	local dPosId = tonumber(pInfo.posId) or -1
	local posId = 0
	local go = copyIcon.go
	local goTrans = go.transform
	local iconWidget = go:GetComponent(typeof(UIWidget))
	local iconWidth = iconWidget.width
	local iconHeight = iconWidget.height
	local tarPos = goTrans.localPosition

	for posId = 1, 6 do
		if dPosId ~= posId then
			local containerPos = self.dragPanelTran:InverseTransformPoint(self["container" .. posId].position)
			local tmpPosId = posId

			if math.abs(tarPos.x - containerPos.x) > iconWidth / 2 then
				tmpPosId = -1
			end

			if math.abs(tarPos.y - containerPos.y) > iconHeight / 2 then
				tmpPosId = -1
			end

			if tmpPosId ~= -1 then
				return posId
			end
		end
	end

	return -1
end

function ActivityFairyTaleBattleFormationWindow:updateMask()
	for i = 1, 6 do
		if self.npc_pos_ then
			self["mask" .. i]:SetActive(i == self.npc_pos_ + 1)
		else
			self["mask" .. i]:SetActive(false)
		end
	end
end

function ActivityFairyTaleBattleFormationWindow:showPartnerDetail(partnerInfo)
end

function ActivityFairyTaleBattleFormationWindow:updateBuff()
	local groupNum = {}
	local tNum = 0

	for i = 1, #self.copyIconList do
		local partnerIcon = self.copyIconList[i]

		if partnerIcon then
			local partnerInfo = partnerIcon:getPartnerInfo()
			local group = nil

			if self.battleType == xyd.BattleType.HERO_CHALLENGE then
				local partner = xyd.models.heroChallenge:getPartner(partnerInfo.partnerID, self.params_.fortID)
				group = partner:getGroup()
			elseif self.ifChooseEnemy then
				local partner = xyd.models.partnerDataStation:getPartner(tonumber(partnerInfo.partnerID))
				group = partner:getGroup()
			else
				group = partnerInfo.group
			end

			if not groupNum[group] then
				groupNum[group] = 0
			end

			groupNum[group] = groupNum[group] + 1
			tNum = tNum + 1
		end
	end

	if self.npc_pos_ and self.npc_pos_ > 0 then
		local partnerInfo = self.copyIconList[self.npc_pos_]:getPartnerInfo()
		local group = partnerInfo.group

		if not groupNum[group] then
			groupNum[group] = 0
		end

		groupNum[group] = groupNum[group] + 1
		tNum = tNum + 1
	end

	for i = 1, 6 do
		if not groupNum[i] then
			groupNum[i] = 0
		end
	end

	local buffIds = self.groupBuffTable:getIds()
	local maxWidth = #self.buffDataList * 76
	local maxNum = 8
	local scrollWidth = 632

	for i = 1, #self.buffDataList do
		local buffId = self.buffDataList[i].buffId
		local isAct = self.buffDataList[i].isAct
		local type_ = self.buffDataList[i].type or xyd.GroupBuffIconType.GROUP_BUFF

		if type_ ~= xyd.GroupBuffIconType.HERO_CHALLENGE and type_ ~= xyd.GroupBuffIconType.NEW_TRIAL then
			local groupDataList = xyd.split(self.groupBuffTable:getGroupConfig(buffId), "|")
			local isNewAct = true

			if tNum < 6 then
				isNewAct = false
			else
				local type = self.groupBuffTable:getType(self.buffDataList[i].buffId)

				if tonumber(type) == 1 then
					for _, gi in ipairs(groupDataList) do
						local giList = xyd.split(gi, "#")

						if tonumber(groupNum[tonumber(giList[1])]) ~= tonumber(giList[2]) then
							isNewAct = false

							break
						end
					end
				elseif tonumber(type) == 2 then
					local numCount = {}

					for num, _ in ipairs(groupNum) do
						if not numCount[groupNum[num]] then
							numCount[groupNum[num]] = 0
						end

						if tonumber(num) < 5 then
							numCount[groupNum[num]] = numCount[groupNum[num]] + 1
						end
					end

					if groupNum[5] + groupNum[6] == 3 and numCount[1] == 3 then
						isNewAct = true
					else
						isNewAct = false
					end
				end
			end

			self.actBuffID = 0

			if isNewAct then
				self.actBuffID = buffId
			end

			if isNewAct ~= isAct then
				self.buffDataList[i].isAct = isNewAct

				self:waitForFrame(1, function ()
					self.buffWrapContent:setInfos(self.buffDataList)
					self.buffWrapContent:jumpToInfo(self.buffDataList[i])
					self.buffWrapContent.wrapContent_:WrapContent()
				end)

				break
			end
		end
	end
end

function ActivityFairyTaleBattleFormationWindow:chackCanMove(posId, cPosId)
	local isNpc = self.npc_pos_ and posId == self.npc_pos_

	if isNpc then
		if cPosId == 2 or cPosId == 6 then
			return false
		end

		if self.nowPartnerList[cPosId + 1] == nil then
			return true
		elseif cPosId + 1 == posId and self.nowPartnerList[cPosId] ~= nil then
			return false
		elseif cPosId + 1 ~= posId and self.nowPartnerList[cPosId + 1] ~= nil then
			return false
		end
	else
		local isTargetNpc = self.npc_pos_ and self.npc_pos_ == cPosId

		if isTargetNpc then
			if posId == 2 or posId == 6 then
				return false
			end

			if self.nowPartnerList[posId + 1] then
				return false
			end
		end

		if self.npc_pos_ and cPosId == self.npc_pos_ + 1 then
			return false
		end
	end

	return true
end

return ActivityFairyTaleBattleFormationWindow
