local FormationItem = class("FormationItem")

function FormationItem:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.heroIcon_ = import("app.components.HeroIcon").new(self.uiRoot_, parent.renderPanel)
end

function FormationItem:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.parent_:updateFormationItemInfo(info, realIndex)
	self.uiRoot_:SetActive(true)

	self.partner_ = info.partnerInfo
	self.callbackFunc = info.callbackFunc

	self:setIsChoose(info.isSelected)

	self.partnerId_ = self.partner_.partnerID
	local params = {
		noClickSelected = true,
		tableID = self.partner_.tableID,
		partnerID = self.partnerId_,
		lev = self.partner_.lev,
		star = self.partner_.star,
		skin_id = self.partner_.skin_id,
		is_vowed = self.partner_.isVowed,
		dragScrollView = self.parent_.partnerListScroller,
		callback = handler(self, self.onClick)
	}

	self.heroIcon_:setInfo(params)
end

function FormationItem:onClick()
	local flag = self.callbackFunc(self.partner_, self.isSelected)

	if flag then
		self:setIsChoose(not self.isSelected)
	end
end

function FormationItem:setIsChoose(status)
	self.isSelected = status
	self.heroIcon_.choose = status
end

function FormationItem:getHeroIcon()
	return self.heroIcon_
end

function FormationItem:getPartnerId()
	return self.partnerId_
end

function FormationItem:setShowActive(canShow)
	self.uiRoot_.gameObject:SetActive(canShow)
end

function FormationItem:getGameObject()
	return self.uiRoot_
end

local CampaignHangFormationWindow = class("CampaignHangFormationWindow", import(".BaseWindow"))
local PartnerFilter = import("app.components.PartnerFilter")

function CampaignHangFormationWindow:ctor(name, params)
	CampaignHangFormationWindow.super.ctor(self, name, params)

	self.defaultMaxNum = 3
	self.slotModel = xyd.models.slot
	self.backpackModel = xyd.models.backpack
	self.selectedShowList = {}
	self.copyIconList = {}
	self.hangPartnerList = {}
	self.selectedNum = 0
	self.mapsModel = xyd.models.map
	self.StageTable = xyd.tables.stageTable
	self.StageLockTable = xyd.tables.stageLockTable
	self.FortTable = xyd.tables.fortTable
	self.isMovingAfterDrag = false
	self.isStartDrag = false
end

function CampaignHangFormationWindow:playOpenAnimation(callback)
	callback()
	print("playOpenAnimations===========================")

	local oldTopY = self.topGroup.localPosition.y
	local oldChooseY = self.chooseGroup.localPosition.y
	self.topGroup.localPosition = Vector3(0, 1090, 0)
	self.chooseGroup.localPosition = Vector3(0, -810, 0)
	local sequence = self:getSequence()

	sequence:Insert(0, self.topGroup:DOLocalMoveY(oldTopY, 0.5):SetEase(DG.Tweening.Ease.InOutSine))
	sequence:Insert(0, self.chooseGroup:DOLocalMoveY(oldChooseY, 0.5):SetEase(DG.Tweening.Ease.InOutSine))
	sequence:AppendCallback(handler(self, function ()
		self:setWndComplete()
	end))
end

function CampaignHangFormationWindow:initWindow()
	CampaignHangFormationWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.mainGroup = winTrans:Find("main")
	self.dragPanelTran = winTrans:Find("drag_panel")
	self.dragPanel = self.dragPanelTran.gameObject:GetComponent(typeof(UIPanel))
	local dragRegion = self.dragPanel.baseClipRegion

	NGUITools.SetPanelConstrainButDontClip(self.dragPanel)

	local winPanel = self.window_:GetComponent(typeof(UIPanel))
	local winRegion = winPanel.baseClipRegion
	dragRegion.z = winRegion.z
	dragRegion.w = winRegion.w
	self.dragPanel.baseClipRegion = dragRegion
	self.topGroup = self.mainGroup:Find("top_group")
	self.chooseGroup = self.mainGroup:Find("choose_group")
	self.heroRoot = self.mainGroup:Find("hero_root")

	self.heroRoot:SetActive(false)

	self.labelWinTitle = self.topGroup:ComponentByName("title_label", typeof(UILabel))
	self.closeBtn = self.topGroup:Find("close_btn").gameObject
	self.midGroup = self.topGroup:Find("mid_group")
	self.forceNumLabel = self.midGroup:ComponentByName("force_num_label", typeof(UILabel))
	self.confirmBtn = self.midGroup:Find("confirm_btn").gameObject
	self.buttonLabel = self.confirmBtn:ComponentByName("button_label", typeof(UILabel))
	self.selectedGroup = self.midGroup:Find("selected_group")
	self.backGroup = self.selectedGroup:Find("back_group")
	self.frontGroup = self.selectedGroup:Find("front_group")
	self.backLabel = self.backGroup:ComponentByName("back_label", typeof(UILabel))
	self.frontLabel = self.frontGroup:ComponentByName("front_label", typeof(UILabel))
	self.container1 = self.frontGroup:Find("container_1")
	self.container2 = self.backGroup:Find("container_2")
	self.container3 = self.backGroup:Find("container_3")
	self.fGroup = self.chooseGroup:Find("f_group")
	self.partnerListScroller = self.chooseGroup:ComponentByName("partner_list_scroller", typeof(UIScrollView))
	self.renderPanel = self.chooseGroup:ComponentByName("partner_list_scroller", typeof(UIPanel))
	self.partnerListWarpContent_ = self.chooseGroup:ComponentByName("partner_list_scroller/partner_list_grid", typeof(MultiRowWrapContent))

	self:setText()

	self.playerLv = self.backpackModel:getLev()
	self.mapInfo = self.mapsModel:getMapInfo(xyd.MapType.CAMPAIGN)

	for k, v in pairs(self.mapInfo.hang_team) do
		if self.slotModel:getPartner(v.partner_id) then
			self.hangPartnerList[v.pos] = v.partner_id
		end
	end

	self.buttonLabel.text = __("SAVE_FORMATION")

	self:register()
	self:initPartnerList()
end

function CampaignHangFormationWindow:register()
	CampaignHangFormationWindow.super.register(self)

	UIEventListener.Get(self.confirmBtn).onClick = handler(self, function ()
		self:onClickconfirmBtn()
	end)
end

function CampaignHangFormationWindow:setText()
	self.frontLabel.text = __("FRONT_ROW")
	self.backLabel.text = __("BACK_ROW")
end

function CampaignHangFormationWindow:onClickconfirmBtn()
	local partnerIds = {}

	for i, _ in pairs(self.copyIconList) do
		if self.copyIconList[i] then
			local partnerInfo = self.copyIconList[i]:getPartnerInfo()

			table.insert(partnerIds, {
				partner_id = partnerInfo.partnerID,
				pos = partnerInfo.posId
			})
		end
	end

	self.mapsModel:setHangTeam(partnerIds)
	xyd.closeWindow(self.name_)
end

function CampaignHangFormationWindow:initPartnerList()
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
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.partnerListScroller, self.partnerListWarpContent_, self.heroRoot.gameObject, FormationItem, self)
	local partnerList = self.slotModel:getSortedPartners()
	local lvSortedList = partnerList[tostring(xyd.partnerSortType.LEV) .. "_0"]

	self:iniPartnerData(lvSortedList, true)
end

function CampaignHangFormationWindow:onSelectGroup(group)
	if self.selectGroup_ == group then
		return
	end

	self.selectGroup_ = group
	local partnerList = self.slotModel:getSortedPartners()
	local lvSortedList = partnerList[tostring(xyd.partnerSortType.LEV) .. "_" .. tostring(self.selectGroup_)]
	self.selectedNum = 0

	self:iniPartnerData(lvSortedList, false)
end

function CampaignHangFormationWindow:isSelected(cPartnerId, Plist, isDel)
	local posId = -1
	local isSelected = false

	for k, v in pairs(Plist) do
		if v == cPartnerId then
			posId = k
			isSelected = true

			if isDel ~= nil and isDel == true then
				Plist[k] = nil
			end

			break
		end
	end

	return {
		isSelected = isSelected,
		posId = posId
	}
end

function CampaignHangFormationWindow:iniPartnerData(partnerList, needUpdateTop)
	local partnerDataList = {}
	local chooseDataList = {}
	self.power = 0
	local tmpHangList = xyd.deepCopy(self.hangPartnerList)

	for _, partnerId in ipairs(partnerList) do
		local partnerInfo = self.slotModel:getPartnerData(tonumber(partnerId))
		partnerInfo.noClick = true
		partnerInfo.scale = 1
		local isS = self:isSelected(partnerId, tmpHangList, true)
		local data = {
			callbackFunc = handler(self, function (a, callbackPInfo, callbackIsChoose)
				return self:onClickheroIcon(callbackPInfo, callbackIsChoose)
			end),
			partnerInfo = partnerInfo,
			isSelected = isS.isSelected
		}

		if isS.isSelected then
			self.power = self.power + partnerInfo.power

			if needUpdateTop then
				self:onClickheroIcon(partnerInfo, false, isS.posId)
			end

			table.insert(chooseDataList, data)
		else
			table.insert(partnerDataList, data)
		end
	end

	for i, v in pairs(tmpHangList) do
		if tmpHangList[i] then
			local partnerId = tmpHangList[i]
			local partnerInfo = self.slotModel:getPartnerData(tonumber(partnerId))
			partnerInfo.noClick = true
			partnerInfo.scale = 1
			local isS = true
			self.power = self.power + partnerInfo.power
			local data = {
				callbackFunc = handler(self, function (a, callbackPInfo, callbackIsChoose)
					return self:onClickheroIcon(callbackPInfo, callbackIsChoose)
				end),
				partnerInfo = partnerInfo,
				isSelected = isS
			}

			if needUpdateTop then
				self:onClickheroIcon(partnerInfo, false, i)
			end

			table.insert(chooseDataList, data)
		end
	end

	self.forceNumLabel.text = tostring(self.power)
	partnerDataList = xyd.tableConcat(chooseDataList, partnerDataList)

	self.multiWrap_:setInfos(partnerDataList, {})
end

function CampaignHangFormationWindow:onClickheroIcon(partnerInfo, isChoose, pos)
	if not isChoose then
		local posId = -1

		if self.selectedNum == self.defaultMaxNum then
			return
		end

		if pos ~= nil and pos >= 1 then
			posId = pos
		else
			for i = 1, self.defaultMaxNum do
				if self.selectedShowList[i] and tonumber(self.selectedShowList[i]) == partnerInfo.partnerID then
					return
				end

				if not self.copyIconList[i] and posId == -1 then
					posId = i
				end
			end
		end

		partnerInfo.posId = posId
		local copyPartnerInfo = self.slotModel:getPartnerData(tonumber(partnerInfo.partnerID))

		local function copyCallback(copyIcon)
			self:iconTapHandler(copyIcon:getPartnerInfo())
		end

		copyPartnerInfo.callback = copyCallback
		copyPartnerInfo.posId = posId
		copyPartnerInfo.noClickSelected = true
		local copyIcon = import("app.components.HeroIcon").new(self["container" .. tostring(posId)].gameObject)

		copyIcon:setInfo(copyPartnerInfo)

		self.selectedShowList[posId] = partnerInfo.partnerID
		self.selectedNum = self.selectedNum + 1

		local function startCallback(callbackCopyIcon)
			if self.window_ ~= nil and not tolua.isnull(self.window_.gameObject) then
				self:startDrag(callbackCopyIcon)
			end
		end

		local function dragCallback(callbackCopyIcon, delta)
			if self.window_ ~= nil and not tolua.isnull(self.window_.gameObject) then
				self:onDrag(callbackCopyIcon, delta)
			end
		end

		local function endCallback(callbackCopyIcon)
			if self.window_ ~= nil and not tolua.isnull(self.window_.gameObject) then
				self:endDrag(callbackCopyIcon)
			end
		end

		copyIcon:setTouchDragListener(startCallback, dragCallback, endCallback)

		self.copyIconList[posId] = copyIcon
		self.hangPartnerList[posId] = partnerInfo.partnerID
	else
		local params = self:isSelected(partnerInfo.partnerID, self.hangPartnerList)
		local isChoose = params.isSelected
		local posId = params.posId

		if posId >= 0 then
			self.selectedShowList[posId] = nil

			NGUITools.DestroyChildren(self["container" .. tostring(posId)])

			self.selectedNum = self.selectedNum - 1
			self.copyIconList[posId] = nil
			self.hangPartnerList[posId] = nil
		end
	end

	self:updateForceNum()

	return true
end

function CampaignHangFormationWindow:getFormationItemByPartnerID(partnerID)
	local items = self.multiWrap_:getItems()

	for _, formationItem in ipairs(items) do
		if formationItem:getPartnerId() == partnerID then
			return formationItem
		end
	end
end

function CampaignHangFormationWindow:updateFormationItemInfo(info, realIndex)
	local partnerInfo = info.partnerInfo
	local partnerId = partnerInfo.partnerID
	local isSelected = info.isSelected
	local isS = self:isSelected(partnerId, self.hangPartnerList, false)

	if isSelected ~= isS.isSelected then
		info.isSelected = isS.isSelected

		self.multiWrap_:updateInfo(realIndex, info)
	end
end

function CampaignHangFormationWindow:iconTapHandler(copyPartnerInfo)
	if self.isMovingAfterDrag then
		return
	end

	local partnerInfo = copyPartnerInfo
	local params = self:isSelected(partnerInfo.partnerID, self.hangPartnerList)
	local isChoose = params.isSelected
	local posId = params.posId

	if posId >= 0 then
		self.selectedShowList[posId] = nil

		NGUITools.DestroyChildren(self["container" .. tostring(posId)])

		self.selectedNum = self.selectedNum - 1
		local fItem = self:getFormationItemByPartnerID(partnerInfo.partnerID)

		if fItem then
			fItem:setIsChoose(false)
		end

		self.copyIconList[posId] = nil
		self.hangPartnerList[posId] = nil
	end

	self:updateForceNum()
end

function CampaignHangFormationWindow:startDrag(copyIcon)
	if self.isMovingAfterDrag then
		return
	end

	self.isStartDrag = true
	copyIcon.noClick = true
	local go = copyIcon.go
	local trans = go.transform
	trans.parent = self.dragPanelTran
	local offsetDepth = self.dragPanel.depth

	copyIcon:setDepth(offsetDepth)
	copyIcon:SetActive(false)
	copyIcon:SetActive(true)
end

function CampaignHangFormationWindow:onDrag(copyIcon, delta)
	if not self.isStartDrag then
		return
	end

	local go = copyIcon.go
	go.transform.localPosition = go.transform.localPosition + go.transform:InverseTransformDirection(Vector2(delta.x, delta.y))
end

function CampaignHangFormationWindow:endDrag(copyIcon)
	if not self.isStartDrag then
		return
	end

	self.isStartDrag = false
	self.isMovingAfterDrag = true
	local partnerInfo = copyIcon:getPartnerInfo()
	local posId = tonumber(partnerInfo.posId)
	local cPosId = self:isChange(copyIcon)

	print("cPosId=================", cPosId, " posId=================", posId)

	local aniDurition = 0.2
	local container = self["container" .. posId]
	local endPosition = self.dragPanelTran:InverseTransformPoint(container.position)
	local endContainer = container

	if cPosId > 0 then
		aniDurition = 0.1
		local cContainer = self["container" .. tostring(cPosId)]
		local cCopyIcon = self.copyIconList[cPosId]
		local tmpPartnerId = self.hangPartnerList[cPosId]
		endPosition = self.dragPanelTran:InverseTransformPoint(cContainer.position)
		endContainer = cContainer

		if cCopyIcon then
			local cEndPosition = cContainer:InverseTransformPoint(container.position)
			local cContainerWidget = cContainer.gameObject:GetComponent(typeof(UIWidget))
			local cGo = cCopyIcon.go
			local cTrans = cGo.transform
			local sequence = self:getSequence()

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
				sequence:Kill(false)
			end)
		end

		self.hangPartnerList[cPosId] = self.hangPartnerList[posId]
		self.hangPartnerList[posId] = tmpPartnerId
		self.copyIconList[cPosId] = self.copyIconList[posId]
		self.copyIconList[posId] = cCopyIcon

		for i = 1, 3 do
			if self.copyIconList[i] then
				local partnerInfo = self.copyIconList[i]:getPartnerInfo()
				self.selectedShowList[i] = partnerInfo.partnerID
			else
				self.selectedShowList[i] = nil
			end
		end
	end

	local containerWidget = endContainer.gameObject:GetComponent(typeof(UIWidget))
	local go = copyIcon.go
	local trans = go.transform
	local sequence = self:getSequence()

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
		end

		self.isMovingAfterDrag = false

		sequence:Kill(false)

		sequence = nil
	end)
end

function CampaignHangFormationWindow:isChange(copyIcon)
	local pInfo = copyIcon:getPartnerInfo()
	local dPosId = tonumber(pInfo.posId) or -1
	local posId = 0
	local go = copyIcon.go
	local goTrans = go.transform
	local iconWidget = go:GetComponent(typeof(UIWidget))
	local iconWidth = iconWidget.width
	local iconHeight = iconWidget.height
	local tarPos = goTrans.localPosition

	for posId = 1, 3 do
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

function CampaignHangFormationWindow:updateForceNum()
	local power = 0

	for i, _ in pairs(self.copyIconList) do
		if self.copyIconList[i] then
			local partnerInfo = self.copyIconList[i]:getPartnerInfo()
			power = power + partnerInfo.power
		end
	end

	self.forceNumLabel.text = tostring(power)
end

return CampaignHangFormationWindow
