local BaseWindow = import(".BaseWindow")
local GalaxyTripFormationWindow = class("GalaxyTripFormationWindow", BaseWindow)
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local PartnerFilter = import("app.components.PartnerFilter")
local HeroIcon = import("app.components.HeroIcon")
local cjson = require("cjson")
local FormationItem = class("FormationItem")

function FormationItem:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.heroIcon_ = nil
	self.win_ = xyd.getWindow("galaxy_trip_formation_window")
end

function FormationItem:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)
	self.parent_:updateFormationItemInfo(info, realIndex)

	if not self.heroIcon_ then
		self.heroIcon_ = import("app.components.HeroIcon").new(self.uiRoot_, self.parent_.partnerRenderPanel)

		local function longPressCallback(callbackCopyIcon)
			self.parent_:longPressIcon(callbackCopyIcon)
		end

		self.heroIcon_:setLongPressListener(longPressCallback)
	end

	self.uiRoot_:SetActive(true)

	self.partner_ = info.partnerInfo
	self.callbackFunc = info.callbackFunc

	self:setIsChoose(info.isSelected)

	self.partnerId_ = self.partner_.partnerID
	self.partner_.noClickSelected = true
	self.partner_.callback = handler(self, self.onClick)
	self.partner_.dragScrollView = self.parent_.scrollView
	self.partner_.is_vowed = self.partner_.isVowed
	self.partner_.noClick = false

	self.heroIcon_:setInfo(self.partner_)
end

function FormationItem:onClick()
	local flag = self.callbackFunc(self.partner_, self.isSelected)

	if flag then
		self:setIsChoose(not self.isSelected)
	end

	self.parent_:checkBuff()
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

function GalaxyTripFormationWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.callback = nil
	self.SlotModel = xyd.models.slot
	self.teamIndex = {
		1,
		2,
		3
	}
	self.isShowGuide_ = false
	self.ifMove = false
	self.copyIconList_ = {}
	self.localPartnerList = {}
	self.nowPartnerList = {}
	self.buffDataList = {}
	self.allServerTeamList_ = {}
	self.collect = {}
	self.isIconMoving = false
	self.needSound = false
	self.partners = nil
	self.pets = {
		0,
		0,
		0,
		0
	}
	self.data = params

	if params.formation then
		self.localPartnerList = {}
		self.nowPartnerList = {}

		for i, list in pairs(params.formation) do
			dump(list)

			for j, info in pairs(list.partners) do
				dump(info)

				local index = info.pos + (i - 1) * 6

				if self.SlotModel:getPartner(info.partner_id) then
					self.nowPartnerList[index] = info.partner_id
				end
			end
		end
	end

	if #self.nowPartnerList <= 0 then
		-- Nothing
	end

	if params and params.callback then
		self.callback = params.callback
	end
end

function GalaxyTripFormationWindow:setWndComplete()
	BaseWindow.setWndComplete(self)
	self.delayGroup:SetActive(true)
	self.chooseGroup:SetActive(true)
end

function GalaxyTripFormationWindow:initWindow()
	BaseWindow.initWindow(self)

	self.curHeight = math.min(xyd.getHeight(), xyd.Global.maxBgHeight)
	self.chooseGroupHeight = 462 + (self.curHeight - 1280) / 2

	self:getUIComponents()
	self:initLayOut()
	self:registerEvent()
	self:initPartnerList()

	self.needSound = true
end

function GalaxyTripFormationWindow:getUIComponents()
	local trans = self.window_:NodeByName("groupAction")
	self.teamGroup = trans:NodeByName("teamGroup").gameObject
	self.dragPanelTran = trans:Find("drag_panel")
	self.dragPanel = self.dragPanelTran.gameObject:GetComponent(typeof(UIPanel))
	self.bgImg2 = self.teamGroup:NodeByName("bgImg2").gameObject
	self.labelWinTitle = self.teamGroup:ComponentByName("labelWinTitle", typeof(UILabel))
	self.delayGroup = self.teamGroup:NodeByName("delayGroup").gameObject
	self.team = self.delayGroup:NodeByName("team").gameObject
	local defaultNum = 3

	for i = 1, 3 do
		local tmp = self.team:NodeByName("selectedFormationGroup_" .. i).gameObject
		self["selectedFormationGroup_" .. i] = tmp
		self["teamBg" .. i] = tmp:NodeByName("teamBg").gameObject
		self["labelBuff" .. i] = tmp:ComponentByName("buffGroup/labelBuff", typeof(UILabel))
		local top = tmp:NodeByName("top").gameObject

		for j = 1, 6 do
			self["container_" .. tostring(j + (i - 1) * 6)] = top:NodeByName("container_" .. tostring(j + (i - 1) * 6)).gameObject
		end
	end

	self.btnSet = self.teamGroup:NodeByName("btnSet").gameObject
	self.setBtnLabel = self.btnSet:ComponentByName("setBtnLabel", typeof(UILabel))
	self.btnSave = self.teamGroup:NodeByName("btnSave").gameObject
	self.saveBtnLabel = self.btnSave:ComponentByName("saveBtnLabel", typeof(UILabel))
	self.closeBtn = self.teamGroup:NodeByName("closeBtn").gameObject
	self.helpBtn = self.teamGroup:NodeByName("helpBtn").gameObject
	self.maskBg = self.teamGroup:NodeByName("maskBg").gameObject
	self.chooseGroup = trans:NodeByName("chooseGroup").gameObject
	self.fGroup = self.chooseGroup:NodeByName("fGroup").gameObject
	self.scrollView = self.chooseGroup:ComponentByName("partnerScroller", typeof(UIScrollView))
	local scrollRoot = self.chooseGroup:NodeByName("partnerScroller").gameObject
	local heroRoot = scrollRoot:NodeByName("hero_root").gameObject
	local wrapContent = scrollRoot:ComponentByName("partnerContainer", typeof(MultiRowWrapContent))
	self.partnerContainer = FixedMultiWrapContent.new(self.scrollView, wrapContent, heroRoot, FormationItem, self)
end

function GalaxyTripFormationWindow:registerEvent()
	GalaxyTripFormationWindow.super.register(self)

	UIEventListener.Get(self.btnSave).onClick = handler(self, self.onClickBtnSave)
	UIEventListener.Get(self.btnSet).onClick = handler(self, self.onclickSet)

	for i = 1, 3 do
		UIEventListener.Get(self["teamBg" .. i]).onClick = handler(self, self.onclickBoard)
	end

	UIEventListener.Get(self.bgImg2).onClick = handler(self, self.onclickBoard)
	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "GALAXY_TRIP_HELP03"
		})
	end)
end

function GalaxyTripFormationWindow:onclickBoard()
	local action = self:getSequence()

	action:Insert(0, self.teamGroup.transform:DOLocalMove(Vector3(0, 0, 0), 0.2))
	action:Insert(0, self.chooseGroup.transform:DOLocalMove(Vector3(0, -self.curHeight / 2, 0), 0.2))
end

function GalaxyTripFormationWindow:onclickSet()
	local action = self:getSequence()

	action:Insert(0, self.teamGroup.transform:DOLocalMove(Vector3(0, 206, 0), 0.2))
	action:Insert(0, self.chooseGroup.transform:DOLocalMove(Vector3(0, -167, 0), 0.2))
end

function GalaxyTripFormationWindow:onClickBtnSave()
	local partnerParams = {}
	local formationIds = {}
	local indexMap = {}

	for i = 0, #self.teamIndex - 1 do
		indexMap[self.teamIndex[i + 1]] = i
	end

	for posId, _ in pairs(self.copyIconList_) do
		local index = math.floor(tonumber(posId - 1) / 6) + 1
		local id = indexMap[index] * 6 + tonumber(posId - 1) % 6 + 1
		local partnerIcon = self.copyIconList_[posId]

		if partnerIcon then
			print(posId)

			local partnerInfo = partnerIcon:getPartnerInfo()
			local pInfo = {
				partner_id = tonumber(partnerInfo.partnerID),
				pos = tonumber(partnerInfo.posId - 1) % 6 + 1
			}
			partnerParams[id] = pInfo
			formationIds[tostring(id)] = partnerInfo.partnerID
		else
			formationIds[tostring(id)] = nil
		end
	end

	if not self:checkLegal(partnerParams) then
		xyd.alert(xyd.AlertType.TIPS, __("AT_LEAST_ONE_HERO_PER_TEAM"))

		return
	end

	local curMapId = xyd.models.galaxyTrip:getGalaxyTripGetCurMap()

	if curMapId ~= 0 then
		local isBatch = xyd.models.galaxyTrip:getGalaxyTripGetMainIsBatch()

		if isBatch and isBatch == 1 then
			xyd.alertTips(__("GALAXY_TRIP_TIPS_14"))

			return
		end

		local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(curMapId)

		if ballMapInfo then
			local ballMap = ballMapInfo.map

			for i in pairs(ballMap) do
				local gridState = xyd.models.galaxyTrip:getGridState(ballMap[i].gridId, curMapId)

				if gridState == xyd.GalaxyTripGridStateType.CAN_GET then
					xyd.alertTips(__("GALAXY_TRIP_TIPS_17"))

					return
				end

				if gridState == xyd.GalaxyTripGridStateType.SEARCH_ING then
					xyd.alertTips(__("GALAXY_TRIP_TIPS_16"))

					return
				end
			end
		end
	end

	local formation = {
		pet_ids = self.pets,
		partners = formationIds
	}
	self.isCloseSelf = true

	self:setGalaxyFormation(partnerParams)

	if self.isCloseSelf then
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function GalaxyTripFormationWindow:checkLegal(partnerParams)
	local teams = {}

	return true
end

function GalaxyTripFormationWindow:setGalaxyFormation(params)
	xyd.models.galaxyTrip:setFormation(params)
end

function GalaxyTripFormationWindow:addTitle()
	if self.labelWinTitle then
		self.labelWinTitle.text = __("GALAXY_TRIP_TEXT22")
	end
end

function GalaxyTripFormationWindow:initLayOut()
	self.setBtnLabel.text = __("GALAXY_TRIP_TEXT25")
	self.saveBtnLabel.text = __("GALAXY_TRIP_TEXT26")
	self.teamGroup.transform.localPosition = Vector3(0, 0, 0)

	self.delayGroup:SetActive(false)

	self.chooseGroup.transform.localPosition = Vector3(0, -self.curHeight / 2, 0)

	self:checkBuff()
end

function GalaxyTripFormationWindow:onSelectGroup(group)
	if self.selectGroup_ == group then
		return
	end

	self.selectGroup_ = group

	self:iniPartnerData(group)
end

function GalaxyTripFormationWindow:getPartners()
	local list = self.SlotModel:getSortedPartners()

	return list
end

function GalaxyTripFormationWindow:initPartnerList()
	local fParams = {
		isCanUnSelected = 1,
		chosenGroup = 0,
		gap = 16,
		scale = 1,
		callback = handler(self, function (self, group)
			self:onSelectGroup(group)
		end)
	}
	local selectGroup = PartnerFilter.new(self.fGroup, fParams)

	self:iniPartnerData(0)
end

function GalaxyTripFormationWindow:iniPartnerData(groupID)
	local partnerList = self:getPartners()
	local lvSortedList = partnerList[tostring(xyd.partnerSortType.LEV) .. "_0"]

	local function isSelected(cPartnerId, Plist, isDel)
		if #Plist > 0 then
			local res = false

			for i, partnerId in pairs(Plist) do
				if partnerId == cPartnerId then
					res = true

					if isDel then
						Plist = xyd.splice(Plist, i, 1)
					end

					break
				end
			end

			return res
		else
			return false
		end
	end

	local partnerDataList = {}
	local chooseDataList = {}
	self.power = 0

	for _, partnerId in pairs(lvSortedList) do
		local ifConitnue = false
		local partner = self.SlotModel:getPartner(tonumber(partnerId))
		local partnerInfo = partner:getInfo()
		partnerInfo.power = partner:getPower()
		partnerInfo.noClick = true
		local pGroupID = xyd.tables.partnerTable:getGroup(partnerInfo.tableID)
		local isS = isSelected(partnerInfo.partnerID, self.nowPartnerList, false)

		if groupID ~= 0 and pGroupID ~= groupID and not isS then
			ifConitnue = true
		end

		if not ifConitnue then
			local data = {
				callbackFunc = function (partnerInfo, isChoose)
					return self:onClickheroIcon(partnerInfo, isChoose, true)
				end,
				partnerInfo = partnerInfo,
				isSelected = isSelected
			}

			table.insert(partnerDataList, data)
		end
	end

	for i, _ in pairs(self.nowPartnerList) do
		if i <= #self.teamIndex * 6 then
			local ifContinue = false
			local partnerId = self.nowPartnerList[i]
			local partner = self.SlotModel:getPartner(tonumber(partnerId))

			if partner then
				local partnerInfo = partner:getInfo()
				partnerInfo.power = partner:getPower()
				partnerInfo.noClick = true
				partnerInfo.posId = i
				local isS = true
				self.power = self.power + partner:getPower()
				local cParams = self:isPartnerSelected(partnerInfo.partnerID)
				local isChoose = cParams.isSelected

				if not isChoose then
					self:onClickheroIcon(partnerInfo, false, false, partnerInfo.posId)
				end
			end
		end
	end

	self.partnerContainer:setInfos(partnerDataList, {})

	self.collect = partnerDataList
end

function GalaxyTripFormationWindow:isPartnerSelected(partnerID)
	local isSelected = false
	local sPosId = -1

	for posId, _ in pairs(self.copyIconList_) do
		local heroIcon = self.copyIconList_[posId]

		if heroIcon then
			local partnerInfo = heroIcon:getPartnerInfo()

			if partnerID == partnerInfo.partnerID then
				isSelected = true
				sPosId = tonumber(posId)

				break
			end
		end
	end

	return {
		isSelected = isSelected,
		posId = sPosId
	}
end

function GalaxyTripFormationWindow:refreshDataGroup(updatePartnerInfo)
	for i, partnerInfo in pairs(self.collect) do
		local partnerID = partnerInfo.partnerID

		if partnerID == updatePartnerInfo.partnerID then
			self.collect[i].partnerInfo = updatePartnerInfo

			break
		end
	end
end

function GalaxyTripFormationWindow:updateFormationItemInfo(info, realIndex)
	local partnerInfo = info.partnerInfo
	local partnerId = partnerInfo.partnerID
	local isSelected = info.isSelected
	local isS = self:isSelected(partnerId, self.nowPartnerList, false)

	if isSelected ~= isS.isSelected then
		info.isSelected = isS.isSelected

		self.partnerContainer:updateInfo(realIndex, info)
	end
end

function GalaxyTripFormationWindow:isSelected(cPartnerId, Plist, isDel)
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

function GalaxyTripFormationWindow:onClickheroIcon(partnerInfo, isChoose, needAnimation, posId)
	if posId == nil then
		posId = 0
	end

	if self.needSound then
		-- Nothing
	end

	if isChoose then
		local params = self:isSelected(partnerInfo.partnerID, self.nowPartnerList)
		local isChoose = params.isSelected
		posId = params.posId

		if posId >= 0 then
			local container = self["container_" .. tostring(posId)]
			local heroIcon = container.transform:NodeByName("hero_icon").gameObject
			local progress = self["progress" .. tostring(posId)]

			if heroIcon then
				NGUITools.Destroy(heroIcon)
			end

			if progress then
				progress.value = 0
			end

			self.copyIconList_[posId] = nil
			self.nowPartnerList[posId] = nil
		end

		return true
	end

	posId = tonumber(posId)

	if posId == 0 or not posId then
		local flag = false

		for i = 1, #self.teamIndex do
			local base = (self.teamIndex[i] - 1) * 6

			for j = 1, 6 do
				posId = base + j

				if not self.copyIconList_[posId] or self.copyIconList_[posId] == nil then
					flag = true

					break
				end
			end

			if flag then
				break
			end
		end

		if not flag then
			xyd.alert(xyd.AlertType.TIPS, __("NO_SLOT_FOR_FIGHTERS"))

			return
		end
	end

	partnerInfo.posId = posId

	local function copyCallback(copyIcon)
		self:iconTapHandler(copyIcon:getPartnerInfo())
		self:checkBuff()
	end

	local copyPartnerInfo = {
		noClickSelected = true,
		scale = 0.7222222222222222,
		tableID = partnerInfo.tableID,
		lev = partnerInfo.lev,
		star = partnerInfo.star,
		skin_id = partnerInfo.skin_id,
		is_vowed = partnerInfo.isVowed,
		posId = posId,
		callback = copyCallback,
		awake = partnerInfo.awake,
		grade = partnerInfo.grade,
		group = partnerInfo.group,
		partnerID = partnerInfo.partnerID,
		power = partnerInfo.power
	}
	local copyIcon = HeroIcon.new(self["container_" .. posId])

	copyIcon:setInfo(copyPartnerInfo)

	self.copyIconList_[posId] = copyIcon
	self.nowPartnerList[posId] = partnerInfo.partnerID
	local container = self["container_" .. posId]

	if needAnimation then
		-- Nothing
	end

	self:refreshDataGroup(partnerInfo)

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
	copyIcon:setLongPressListener(longPressCallback)
	self:checkBuff()

	return true
end

function GalaxyTripFormationWindow:checkBuff()
	for i = 1, 3 do
		local totalAwakeStar = 0

		for j = 1, 6 do
			local index = (i - 1) * 6 + j

			if self.nowPartnerList[index] then
				local partner = self.SlotModel:getPartner(tonumber(self.nowPartnerList[index]))
				local star = partner:getStar()

				if star > 10 then
					totalAwakeStar = totalAwakeStar + star - 10
				end
			end
		end

		self["labelBuff" .. i].text = xyd.tables.galaxyTripTeamTable:getDesc(totalAwakeStar, i)

		if xyd.Global.lang == "fr_fr" then
			self["labelBuff" .. i].fontSize = 16
		end
	end
end

function GalaxyTripFormationWindow:startDrag(copyIcon)
	if self.isMovingAfterDrag then
		return
	end

	self.isStartDrag = true
	copyIcon.noClick = true
	local go = copyIcon.go
	local trans = go.transform
	trans.parent = self.dragPanelTran
	local offsetDepth = self.dragPanel.depth
	copyIcon.depth = offsetDepth

	copyIcon:SetActive(false)
	copyIcon:SetActive(true)
end

function GalaxyTripFormationWindow:onDrag(copyIcon, delta)
	if not self.isStartDrag then
		return
	end

	local go = copyIcon.go
	local pos = go.transform.localPosition
	go.transform.localPosition = Vector3(pos.x + delta.x / xyd.Global.screenToLocalAspect(), pos.y + delta.y / xyd.Global.screenToLocalAspect(), pos.z)
end

function GalaxyTripFormationWindow:endDrag(copyIcon)
	if not self.isStartDrag then
		return
	end

	self.isStartDrag = false
	self.isMovingAfterDrag = true
	local partnerInfo = copyIcon:getPartnerInfo()
	local posId = tonumber(partnerInfo.posId)
	local cPosId = self:isChange(copyIcon)
	local aniDurition = 0.2
	local container = self["container_" .. posId]
	local endPosition = self.dragPanelTran:InverseTransformPoint(container.transform.position)
	local endContainer = container

	if cPosId > 0 then
		local cContainer = self["container_" .. tostring(cPosId)]
		local cCopyIcon = self.copyIconList_[cPosId]
		local tmpPartnerId = self.nowPartnerList[cPosId]

		if cCopyIcon then
			local cEndPosition = cContainer.transform:InverseTransformPoint(container.transform.position)
			local cContainerWidget = cContainer.gameObject:GetComponent(typeof(UIWidget))
			local cGo = cCopyIcon.go
			local cTrans = cGo.transform
			local sequence = DG.Tweening.DOTween.Sequence()

			sequence:Append(cTrans:DOLocalMove(cEndPosition, 0.1):SetEase(DG.Tweening.Ease.OutSine))
			sequence:AppendCallback(function ()
				cTrans.parent = container.transform
				local offsetDepth = cContainerWidget.depth
				cCopyIcon.depth = offsetDepth

				cCopyIcon:SetActive(false)
				cCopyIcon:SetActive(true)

				cCopyIcon.noClick = false

				cCopyIcon:updatePartnerInfo({
					posId = posId
				})
				sequence:Kill(false)
			end)
		end

		aniDurition = 0.1
		endPosition = self.dragPanelTran:InverseTransformPoint(cContainer.transform.position)
		endContainer = cContainer
		self.nowPartnerList[cPosId] = self.nowPartnerList[posId]
		self.nowPartnerList[posId] = tmpPartnerId
		self.copyIconList_[cPosId] = self.copyIconList_[posId]
		self.copyIconList_[posId] = cCopyIcon
	end

	self:playCopyIconActionByEndDrag(copyIcon, endContainer, cPosId, endPosition, aniDurition)
	self:checkBuff()
end

function GalaxyTripFormationWindow:playCopyIconActionByEndDrag(copyIcon, endContainer, cPosId, endPosition, aniDurition)
	local containerWidget = endContainer.gameObject:GetComponent(typeof(UIWidget))
	local go = copyIcon.go
	local trans = go.transform
	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Append(trans:DOLocalMove(endPosition, aniDurition):SetEase(DG.Tweening.Ease.OutSine))
	sequence:AppendCallback(function ()
		trans.parent = endContainer.transform
		local offsetDepth = containerWidget.depth
		copyIcon.depth = offsetDepth

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

function GalaxyTripFormationWindow:longPressIcon(copyIcon)
	self:showPartnerDetail(copyIcon:getPartnerInfo())
end

function GalaxyTripFormationWindow:showPartnerDetail(partnerInfo)
	if not partnerInfo then
		return
	end

	local params = {
		isLongTouch = true,
		unable_move = true,
		sort_key = "0_0",
		not_open_slot = true,
		ifGalaxy = true,
		partner_id = partnerInfo.partnerID,
		table_id = partnerInfo.tableID,
		battleData = self.params_,
		skin_id = partnerInfo.skin_id
	}
	local wndName = "partner_detail_window"
	local showTime = xyd.tables.partnerPictureTable:getShowTime(params.skin_id)

	if params.skin_id and showTime and xyd.getServerTime() < showTime then
		params.skin_id = nil
	end

	local partnerParams = {}
	local formationIds = {}
	local indexMap = {}

	for i = 0, #self.teamIndex - 1 do
		indexMap[self.teamIndex[i + 1]] = i
	end

	for posId, _ in pairs(self.copyIconList_) do
		local index = math.floor(tonumber(posId - 1) / 6) + 1
		local id = indexMap[index] * 6 + tonumber(posId - 1) % 6 + 1
		local partnerIcon = self.copyIconList_[posId]

		if partnerIcon then
			print(posId)

			local partnerInfo = partnerIcon:getPartnerInfo()
			local pInfo = {
				partner_id = tonumber(partnerInfo.partnerID),
				pos = tonumber(partnerInfo.posId - 1) % 6 + 1
			}
			partnerParams[id] = pInfo
			formationIds[tostring(id)] = partnerInfo.partnerID
		else
			formationIds[tostring(id)] = nil
		end
	end

	local formation = {
		partners = formationIds
	}

	xyd.openWindow(wndName, params)
end

function GalaxyTripFormationWindow:iconTapHandler(copyPartnerInfo)
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

	if posId > 0 then
		NGUITools.Destroy(self.copyIconList_[posId].go)

		local fItem = self:getFormationItemByPartnerID(partnerInfo.partnerID)

		if fItem then
			fItem:setIsChoose(false)
		end

		self.copyIconList_[posId] = nil
		self.nowPartnerList[posId] = nil
	end
end

function GalaxyTripFormationWindow:getFormationItemByPartnerID(partnerID)
	local items = self.partnerContainer:getItems()

	for _, formationItem in ipairs(items) do
		if formationItem:getPartnerId() == partnerID then
			return formationItem
		end
	end
end

function GalaxyTripFormationWindow:isChange(copyIcon)
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

	for posId = 1, 6 * #self.teamIndex do
		if dPosId ~= posId then
			local containerPos = self.dragPanelTran:InverseTransformPoint(self["container_" .. posId].transform.position)
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

function GalaxyTripFormationWindow:willClose()
	BaseWindow.willClose(self)

	if self.chooseGroup then
		self.chooseGroup:SetActive(false)
	end

	if self.callback then
		self:callback()
	end

	if not tolua.isnull(self.window_) then
		self.chooseGroup:SetActive(false)
	end

	self.delayGroup:SetActive(false)
end

return GalaxyTripFormationWindow
