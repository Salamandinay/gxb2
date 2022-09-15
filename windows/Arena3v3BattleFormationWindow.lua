local BaseWindow = import(".BaseWindow")
local Arena3v3BattleFormationWindow = class("Arena3v3BattleFormationWindow", BaseWindow)
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local ArenaBattleFormationHeroIcon = class("ArenaBattleFormationHeroIcon", FormationItem)
local PartnerFilter = import("app.components.PartnerFilter")
local HeroIcon = import("app.components.HeroIcon")
local cjson = require("cjson")
local FormationItem = class("FormationItem")

function FormationItem:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.heroIcon_ = nil
	self.win_ = xyd.getWindow("arena_3v3_battle_formation_window")
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

	if self.win_ and self.win_.isDeath and self.win_.checkNeedGrey and self.win_:checkNeedGrey() then
		local flag = self.win_:isDeath(self.partnerId_)

		if flag then
			self.heroIcon_:setGrey()
		else
			self.heroIcon_:setOrigin()
		end

		self.isDeath_ = flag
	end

	self.heroIcon_:setInfo(self.partner_)
end

function FormationItem:onClick()
	if self.isDeath_ then
		xyd.alert(xyd.AlertType.TIPS, __("ALREADY_DIE"))

		return
	end

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

function Arena3v3BattleFormationWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.callback = nil
	self.btnSkipCallback = nil
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
	self.btnCurState = {}
	self.mapsModel = xyd.models.map
	self.StageTable = xyd.tables.stageTable
	self.FortTable = xyd.tables.fortTable
	self.mapType = params.mapType
	self.battleType = params.battleType

	self:readStorageFormation()

	self.data = params

	if (self.battleType == xyd.BattleType.ARENA_3v3_DEF or self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF) and params.formation then
		self.localPartnerList = {}
		self.nowPartnerList = {}

		for i, _ in pairs(params.formation) do
			if params.formation[i] and self.SlotModel:getPartner(params.formation[i].partner_id) then
				self.nowPartnerList[i] = params.formation[i].partner_id
			end
		end
	end

	if self.battleType == xyd.BattleType.EXPLORE_OLD_CAMPUS and params.formation then
		self.localPartnerList = {}
		self.nowPartnerList = {}

		for i, _ in pairs(params.formation) do
			if params.formation[i] then
				self.nowPartnerList[i] = params.formation[i].partner_id
			end
		end

		self.is_old_campus_ShowAlert = true

		if #self.nowPartnerList == 0 then
			self.is_old_campus_ShowAlert = false
		end

		self.old_campus_PartnerList = {}

		for i in pairs(self.nowPartnerList) do
			self.old_campus_PartnerList[i] = self.nowPartnerList[i]
		end

		for i in pairs(self.nowPartnerList) do
			local paramsData = xyd.models.slot:getPartner(self.nowPartnerList[i])

			if not paramsData then
				table.remove(self.nowPartnerList, i)
			end
		end
	end

	if self.battleType == xyd.BattleType.ARENA_3v3 and #self.nowPartnerList <= 0 then
		local formation = xyd.models.arena3v3:getDefFormation()

		for i, _ in pairs(formation) do
			if formation[i] then
				self.nowPartnerList[i] = formation[i].partner_id
			end
		end
	end

	if params and params.callback then
		self.callback = params.callback
	end

	if self.battleType == xyd.BattleType.EXPLORE_OLD_CAMPUS then
		self.teamIndex = {}

		for i = 1, self.data.levelNum do
			table.insert(self.teamIndex, i)
		end
	end
end

function Arena3v3BattleFormationWindow:setWndComplete()
	BaseWindow.setWndComplete(self)
	self.delayGroup:SetActive(true)
	self.chooseGroup:SetActive(true)
end

function Arena3v3BattleFormationWindow:updateRed()
	local petModel = xyd.models.petSlot
	local pets = petModel:getPetIDs()
	local petNum = 0
	local petOnNum = 0
	local v = false

	for i = 1, #pets do
		if petModel:getPetByID(pets[i]):getLevel() > 0 then
			petNum = petNum + 1
		end
	end

	for _, pet in ipairs(self.pets) do
		if pet then
			petOnNum = petOnNum + 1
		end
	end

	petNum = math.min(#self.teamIndex, petNum)

	if petOnNum < petNum then
		v = true
	end

	if self.petRedImg then
		self.petRedImg:SetActive(v)
	end
end

function Arena3v3BattleFormationWindow:initWindow()
	BaseWindow.initWindow(self)

	self.curHeight = math.min(xyd.getHeight(), xyd.Global.maxBgHeight)
	self.chooseGroupHeight = 462 + (self.curHeight - 1280) / 2

	self:getUIComponents()
	self:initLayOut()
	self:registerEvent()
	self:initPartnerList()

	self.needSound = true

	self:updateRed()
	self.btnPet:SetActive(false)

	self.btnPetLabel.text = __("BATTLE_FORMAION_PET")

	if xyd.checkFunctionOpen(xyd.FunctionID.PET, true) then
		self.btnPet:SetActive(true)

		UIEventListener.Get(self.btnPet).onClick = handler(self, self.petChoose)
	else
		self.btnSkip.transform.localPosition = Vector3(92, 0, 0)
	end

	if self.params_.showSkip then
		self.selected = self.btnSkipIcon

		self.btnSkip:SetActive(true)

		self.btnSkipLabel.text = __("SKIP_BATTLE2")

		if self.params_.skipState then
			self.selected:SetActive(true)
		else
			self.selected:SetActive(false)
		end

		UIEventListener.Get(self.btnSkip).onClick = function ()
			local v = not self.selected.gameObject.activeSelf

			self.selected:SetActive(v)

			if self.params_.btnSkipCallback then
				self.btnSkipCallback = self.params_.btnSkipCallback

				self.btnSkipCallback(v)
			end
		end
	end

	if self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF then
		self.groupForce:SetActive(false)
	end

	self:updateForceNum()
end

function Arena3v3BattleFormationWindow:getUIComponents()
	local trans = self.window_:NodeByName("groupAction")
	self.teamGroup = trans:NodeByName("teamGroup").gameObject
	self.dragPanelTran = trans:Find("drag_panel")
	self.dragPanel = self.dragPanelTran.gameObject:GetComponent(typeof(UIPanel))
	self.bgImg2 = self.teamGroup:NodeByName("bgImg2").gameObject
	self.labelWinTitle = self.teamGroup:ComponentByName("labelWinTitle", typeof(UILabel))
	self.delayGroup = self.teamGroup:NodeByName("delayGroup").gameObject
	self.operationBg = self.delayGroup:NodeByName("operationBg").gameObject
	self.groupForce = self.delayGroup:NodeByName("groupForce").gameObject
	self.labelForceNum = self.groupForce:ComponentByName("labelForceNum", typeof(UILabel))
	self.skipBtnGroup = self.delayGroup:NodeByName("skipBtnGroup").gameObject
	self.btnSkip = self.skipBtnGroup:NodeByName("btnSkip").gameObject
	self.btnSkipLabel = self.btnSkip:ComponentByName("btnSkipLabel", typeof(UILabel))
	self.btnSkipIcon = self.btnSkip:ComponentByName("btnSkipIcon", typeof(UISprite))
	self.btnPet = self.skipBtnGroup:NodeByName("btnPet").gameObject
	self.btnPetLabel = self.btnPet:ComponentByName("btnPetLabel", typeof(UILabel))
	self.team = self.delayGroup:NodeByName("team").gameObject
	local defaultNum = 3

	if self.battleType == xyd.BattleType.EXPLORE_OLD_CAMPUS then
		defaultNum = self.data.levelNum
	end

	for i = 1, 3 do
		local tmp = self.team:NodeByName("selectedFormationGroup_" .. i).gameObject
		self["selectedFormationGroup_" .. i] = tmp
		self["teamBg" .. i] = tmp:NodeByName("teamBg" .. i).gameObject
		self["teamImg" .. i] = tmp:ComponentByName("teamImg" .. i, typeof(UISprite))
		self["labelFront" .. i] = tmp:ComponentByName("labelFront" .. i, typeof(UILabel))
		self["labelBack" .. i] = tmp:ComponentByName("labelBack" .. i, typeof(UILabel))
		local bottom = tmp:NodeByName("bottom").gameObject

		for j = 3, 6 do
			self["container_" .. tostring(j + (i - 1) * 6)] = bottom:NodeByName("container_" .. tostring(j + (i - 1) * 6)).gameObject
		end

		local top = tmp:NodeByName("top").gameObject

		for j = 1, 2 do
			self["container_" .. tostring(j + (i - 1) * 6)] = top:NodeByName("container_" .. tostring(j + (i - 1) * 6)).gameObject
		end

		for j = 1, 6 do
			self["maskImg" .. tostring(j + (i - 1) * 6)] = self["container_" .. tostring(j + (i - 1) * 6)]:ComponentByName("maskImg" .. tostring(j + (i - 1) * 6), typeof(UISprite))
			self["maskImg" .. tostring(j + (i - 1) * 6)]:GetComponent(typeof(UIWidget)).depth = 90
		end

		self["teamBtn" .. i] = tmp:NodeByName("teamBtn" .. i).gameObject
		self["teamBtnIcon" .. i] = self["teamBtn" .. i]:ComponentByName("icon", typeof(UISprite))
		self.btnCurState[i] = "unchosen"

		xyd.setUISpriteAsync(self["teamBtnIcon" .. i]:GetComponent(typeof(UISprite)), nil, "arena_3v3_exchange_team")
	end

	for i = defaultNum + 1, 3 do
		local tmp = self.team:NodeByName("selectedFormationGroup_" .. i).gameObject
		self["teamImg" .. i] = tmp:ComponentByName("teamImg" .. i, typeof(UISprite))
		self["labelFront" .. i] = tmp:ComponentByName("labelFront" .. i, typeof(UILabel))
		self["labelBack" .. i] = tmp:ComponentByName("labelBack" .. i, typeof(UILabel))
		local bottom = tmp:NodeByName("bottom").gameObject
		local top = tmp:NodeByName("top").gameObject
		self["teamBtn" .. i] = tmp:NodeByName("teamBtn" .. i).gameObject
		self["noTipsText" .. i] = tmp:ComponentByName("noTipsText" .. i, typeof(UILabel))

		self["teamImg" .. i].gameObject:SetActive(false)
		self["labelFront" .. i].gameObject:SetActive(false)
		self["labelBack" .. i].gameObject:SetActive(false)
		bottom:SetActive(false)
		top:SetActive(false)
		self["teamBtn" .. i]:SetActive(false)
		self["noTipsText" .. i].gameObject:SetActive(true)

		self["noTipsText" .. i].text = __("ACTIVITY_EXPLORE_CAMPUS_NOT_NEED_TEAM", i)
	end

	self.setBtn = self.teamGroup:NodeByName("setBtn").gameObject
	self.setBtnLabel = self.setBtn:ComponentByName("setBtnLabel", typeof(UILabel))
	self.battleBtn = self.teamGroup:NodeByName("battleBtn").gameObject
	self.battleBtnLabel = self.battleBtn:ComponentByName("battleBtnLabel", typeof(UILabel))
	self.closeBtn = self.teamGroup:NodeByName("closeBtn").gameObject
	self.tipBtn = self.teamGroup:NodeByName("tipBtn").gameObject
	self.maskBg = self.teamGroup:NodeByName("maskBg").gameObject
	self.chooseGroup = trans:NodeByName("chooseGroup").gameObject
	self.fGroup = self.chooseGroup:NodeByName("fGroup").gameObject
	self.scrollView = self.chooseGroup:ComponentByName("partnerScroller", typeof(UIScrollView))
	local scrollRoot = self.chooseGroup:NodeByName("partnerScroller").gameObject
	local heroRoot = scrollRoot:NodeByName("hero_root").gameObject
	local wrapContent = scrollRoot:ComponentByName("partnerContainer", typeof(MultiRowWrapContent))
	self.partnerContainer = FixedMultiWrapContent.new(self.scrollView, wrapContent, heroRoot, FormationItem, self)
end

function Arena3v3BattleFormationWindow:registerEvent()
	Arena3v3BattleFormationWindow.super.register(self)

	UIEventListener.Get(self.battleBtn).onClick = handler(self, self.onClickBattleBtn)

	for i = 1, 3 do
		UIEventListener.Get(self["teamBtn" .. i]).onClick = function ()
			self:onClickTeamBtn(i)
		end
	end

	UIEventListener.Get(self.setBtn).onClick = handler(self, self.onclickSet)

	for i = 1, 3 do
		UIEventListener.Get(self["teamBg" .. i]).onClick = handler(self, self.onclickBoard)
	end

	UIEventListener.Get(self.operationBg).onClick = handler(self, self.onclickBoard)
	UIEventListener.Get(self.bgImg2).onClick = handler(self, self.onclickBoard)
	UIEventListener.Get(self.tipBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("battle_tips_window", {})
	end)
end

function Arena3v3BattleFormationWindow:onclickBoard()
	local action = self:getSequence()

	action:Insert(0, self.teamGroup.transform:DOLocalMove(Vector3(0, 0, 0), 0.2))
	action:Insert(0, self.chooseGroup.transform:DOLocalMove(Vector3(0, -self.curHeight / 2, 0), 0.2))

	for i = 1, 3 do
		local item = self["teamBtn" .. i]

		if self.btnCurState[i] == "chosen" then
			self:onClickTeamBtn(i)
		end

		xyd.setTouchEnable(self["teamBtn" .. i], true)
	end
end

function Arena3v3BattleFormationWindow:onclickSet()
	local action = self:getSequence()

	action:Insert(0, self.teamGroup.transform:DOLocalMove(Vector3(0, 168, 0), 0.2))
	action:Insert(0, self.chooseGroup.transform:DOLocalMove(Vector3(0, -171, 0), 0.2))

	for i = 1, 3 do
		xyd.setTouchEnable(self["teamBtn" .. i], false)
	end
end

function Arena3v3BattleFormationWindow:setMask(index)
	for i = 1, 18 do
		if i > (index - 1) * 6 and i <= index * 6 then
			self["maskImg" .. i]:SetActive(false)
		else
			self["maskImg" .. i]:SetActive(true)
		end
	end

	xyd.setTouchEnable(self.setBtn, false)
	xyd.setTouchEnable(self.battleBtn, false)
	xyd.setTouchEnable(self.btnSkip, false)

	self.isMaskOn = true
end

function Arena3v3BattleFormationWindow:removeMask()
	for i = 1, 18 do
		self["maskImg" .. i]:SetActive(false)
	end

	xyd.setTouchEnable(self.setBtn, true)
	xyd.setTouchEnable(self.battleBtn, true)
	xyd.setTouchEnable(self.btnSkip, true)

	self.isMaskOn = false
end

function Arena3v3BattleFormationWindow:onClickTeamBtn(index)
	local choseFlag = self.btnCurState[index] == "chosen"
	local switchFlag = self.btnCurState[index] == "switch"

	if not switchFlag then
		for i = 1, #self.teamIndex do
			if self.teamIndex[i] == index then
				local state = "chosen"
				local src = "arena_3v3_cancle"

				if choseFlag then
					state = "unchosen"
					src = "arena_3v3_exchange_team"

					self:removeMask()
				else
					self:setMask(index)
				end

				self.btnCurState[index] = state

				xyd.setUISpriteAsync(self["teamBtnIcon" .. index]:GetComponent(typeof(UISprite)), nil, src)
				xyd.setUISpriteAsync(self["teamBtn" .. index]:GetComponent(typeof(UISprite)), nil, "white_btn_65_65")
			else
				local state = "switch"
				local src = "arena_3v3_move_team"
				local btnSrc = "blue_btn_65_65"

				if choseFlag then
					state = "unchosen"
					src = "arena_3v3_exchange_team"
					btnSrc = "white_btn_65_65"
				end

				self.btnCurState[self.teamIndex[i]] = state

				xyd.setUISpriteAsync(self["teamBtnIcon" .. self.teamIndex[i]]:GetComponent(typeof(UISprite)), nil, src)
				xyd.setUISpriteAsync(self["teamBtn" .. self.teamIndex[i]]:GetComponent(typeof(UISprite)), nil, btnSrc)
			end
		end
	else
		local chosenIndex = 0

		for i = 1, 3 do
			if self.btnCurState[i] == "chosen" then
				chosenIndex = i

				break
			end
		end

		if chosenIndex == 0 then
			for i = 1, 3 do
				self.btnCurState[i] = "unchosen"

				xyd.setUISpriteAsync(self["teamBtnIcon" .. i]:GetComponent(typeof(UISprite)), nil, "arena_3v3_exchange_team")
				xyd.setUISpriteAsync(self["teamBtn" .. i]:GetComponent(typeof(UISprite)), nil, "white_btn_65_65")
			end

			return
		end

		self:switchTeam(index, chosenIndex)

		for i = 1, 3 do
			self.btnCurState[i] = "unchosen"

			xyd.setUISpriteAsync(self["teamBtnIcon" .. i]:GetComponent(typeof(UISprite)), nil, "arena_3v3_exchange_team")
			xyd.setUISpriteAsync(self["teamBtn" .. i]:GetComponent(typeof(UISprite)), nil, "white_btn_65_65")
		end

		self:removeMask()
	end
end

function Arena3v3BattleFormationWindow:switchTeam(index1, index2)
	local teamGroup1 = self["selectedFormationGroup_" .. index1]
	local teamGroup2 = self["selectedFormationGroup_" .. index2]
	local pos1 = teamGroup1.transform.localPosition
	teamGroup1.transform.localPosition = teamGroup2.transform.localPosition
	teamGroup2.transform.localPosition = pos1
	local teamImg1 = self["teamImg" .. index1].spriteName
	local teamImg2 = self["teamImg" .. index2].spriteName

	xyd.setUISpriteAsync(self["teamImg" .. index1], nil, teamImg2)
	xyd.setUISpriteAsync(self["teamImg" .. index2], nil, teamImg1)

	local arrID1 = -1
	local arrID2 = -1

	for i = 1, #self.teamIndex do
		if self.teamIndex[i] == index1 then
			arrID1 = i
		end

		if self.teamIndex[i] == index2 then
			arrID2 = i
		end
	end

	if arrID1 >= 0 and arrID2 >= 0 then
		self.teamIndex[arrID1] = index2
		self.teamIndex[arrID2] = index1
		local petID = self.pets[arrID1 + 1]
		self.pets[arrID1 + 1] = self.pets[arrID2 + 1]
		self.pets[arrID2 + 1] = petID
	end
end

function Arena3v3BattleFormationWindow:onClickBattleBtn()
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

	local formation = {
		pet_ids = self.pets,
		partners = formationIds
	}

	xyd.db.formation:setValue({
		key = self.battleType,
		value = cjson.encode(formation)
	})

	self.isCloseSelf = true

	if self.battleType == xyd.BattleType.ARENA_3v3 then
		self:arena3v3Battle(partnerParams)
	elseif self.battleType == xyd.BattleType.ARENA_3v3_DEF then
		self:arena3v3BattleDef(partnerParams)
	elseif self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF then
		self:arenaAllServerBattleDef(partnerParams)
	elseif self.battleType == xyd.BattleType.EXPLORE_OLD_CAMPUS then
		if self.is_old_campus_ShowAlert then
			local isSame = true

			for i = 1, 18 do
				if not self.old_campus_PartnerList[i] and partnerParams[i] then
					isSame = false
				end

				if self.old_campus_PartnerList[i] and not partnerParams[i] then
					isSame = false
				end

				if self.old_campus_PartnerList[i] and partnerParams[i] and self.old_campus_PartnerList[i] ~= partnerParams[i].partner_id then
					isSame = false
				end

				if isSame == false then
					break
				end
			end

			if not self.old_campus_pets then
				self.old_campus_pets = {
					0,
					0,
					0,
					0
				}
			end

			for i in pairs(self.pets) do
				if not self.old_campus_pets[i] and self.pets[i] then
					isSame = false
				end

				if self.old_campus_pets[i] and not self.pets[i] then
					isSame = false
				end

				if self.old_campus_pets[i] and self.pets[i] and self.old_campus_pets[i] ~= self.pets[i] then
					isSame = false
				end

				if isSame == false then
					break
				end
			end

			if isSame == false or self.params_ and self.params_.isForceSave == true then
				self.isCloseSelf = false

				if self.params_.isCurFloorZero == true then
					self:exploreOldCampusSaveFormation(partnerParams)
					xyd.WindowManager.get():closeWindow("arena_3v3_battle_formation_window")
				else
					xyd.alertYesNo(__("ACTIVITY_EXPLORE_CAMPUS_SCORE_SET_TEAM_TIPS"), function (yes)
						if yes then
							self:exploreOldCampusSaveFormation(partnerParams)
							xyd.WindowManager.get():closeWindow("arena_3v3_battle_formation_window")
						else
							return
						end
					end)
				end
			end
		else
			self:exploreOldCampusSaveFormation(partnerParams)
		end
	end

	if self.isCloseSelf then
		xyd.WindowManager.get():closeWindow("arena_3v3_battle_formation_window")
	end
end

function Arena3v3BattleFormationWindow:checkLegal(partnerParams)
	local teams = {}

	for i = 0, 2 do
		teams[i + 1] = xyd.slice(partnerParams, i * 6 + 1, i * 6 + 6)

		for j = 6, 1, -1 do
			if teams[i + 1][j] == nil then
				teams[i + 1] = xyd.splice(teams[i + 1], j, 1)
			end
		end
	end

	for i = 1, #self.teamIndex do
		if #teams[i] <= 0 then
			return false
		end
	end

	return true
end

function Arena3v3BattleFormationWindow:arena3v3Battle(params)
	local needCheck = not xyd.models.arena3v3.hasCheck
	local deformation = xyd.models.arena3v3:getDefFormation()

	if needCheck then
		local power = 0

		for index, partner in pairs(deformation) do
			power = power + partner.power
		end

		local numSave = xyd.tables.miscTable:getVal("defense_team_save")

		if self.power and tonumber(numSave) < self.power / power then
			xyd.models.arena3v3:checkDefFormation()
		end

		xyd.models.arena3v3.hasCheck = true
	end

	xyd.models.arena3v3:fight(self.params_.enemy_id, params, self.pets, self.params_.is_revenge, self.params_.index)
end

function Arena3v3BattleFormationWindow:arena3v3BattleDef(params)
	xyd.models.arena3v3:setDefFormation(params, self.pets)

	local rank = xyd.models.arena3v3:getRank()

	if rank <= xyd.TOP_ARENA_NUM then
		self:waitForTime(0.1, xyd.models.arena3v3.reqRankList)
	end

	function self.callback()
		local win = xyd.WindowManager.get():getWindow("arena_3v3_window")

		if win then
			win:setMask(false)
		end
	end
end

function Arena3v3BattleFormationWindow:arenaAllServerBattleDef(params)
	xyd.models.arenaAllServer:reqSetTeams(params, self.pets)
end

function Arena3v3BattleFormationWindow:initLayOut()
	self.labelFront1.text = __("FRONT_ROW")
	self.labelBack1.text = __("BACK_ROW")
	self.labelFront2.text = __("FRONT_ROW")
	self.labelBack2.text = __("BACK_ROW")
	self.labelFront3.text = __("FRONT_ROW")
	self.labelBack3.text = __("BACK_ROW")
	self.setBtnLabel.text = __("SET_DEF_FORMATION")

	if self.battleType == xyd.BattleType.ARENA_3v3 then
		self.battleBtnLabel.text = __("BATTLE_START")
	elseif self.battleType == xyd.BattleType.ARENA_3v3_DEF or self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF or self.battleType == xyd.BattleType.EXPLORE_OLD_CAMPUS then
		self.battleBtnLabel.text = __("SAVE_DEF_FORMATION")
	end

	self.teamGroup.transform.localPosition = Vector3(0, 0, 0)

	self.delayGroup:SetActive(false)

	self.chooseGroup.transform.localPosition = Vector3(0, -self.curHeight / 2, 0)
end

function Arena3v3BattleFormationWindow:delLocalPartnerList(partnerID)
	if #self.nowPartnerList <= 0 then
		return
	end

	for pos, id in pairs(self.nowPartnerList) do
		if tonumber(partnerID) == tonumber(id) then
			self.nowPartnerList.splice(pos, 1)

			break
		end
	end
end

function Arena3v3BattleFormationWindow:isInLocalFormation(partnerID)
	local res = false

	if #self.nowPartnerList <= 0 then
		return res
	end

	for pos, id in pairs(self.nowPartnerList) do
		if tonumber(partnerID) == tonumber(id) then
			res = true

			break
		end
	end

	return res
end

function Arena3v3BattleFormationWindow:onSelectGroup(group)
	if self.selectGroup_ == group then
		return
	end

	self.selectGroup_ = group

	self:iniPartnerData(group)
end

function Arena3v3BattleFormationWindow:getPartners()
	local list = self.SlotModel:getSortedPartners()

	return list
end

function Arena3v3BattleFormationWindow:initPartnerList()
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

function Arena3v3BattleFormationWindow:iniPartnerData(groupID)
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

		if groupID ~= 0 and pGroupID ~= groupID then
			if not isS then
				ifConitnue = true
			end
		elseif self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF then
			local nID = xyd.tables.partnerTable:getTenId(partnerInfo.tableID) or 0
			local star10 = xyd.tables.partnerTable:getStar10(partnerInfo.tableID) or 0
			local maxStar = xyd.tables.partnerTable:getStar(partnerInfo.tableID)

			if star10 <= 0 and nID <= 0 and maxStar ~= 10 then
				ifConitnue = true
			end

			if partnerInfo.tableID > 660000 and partnerInfo.tableID < 670000 or partnerInfo.tableID > 760000 and partnerInfo.tableID < 770000 then
				ifConitnue = true
			end
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

				if self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF then
					local nID = xyd.tables.partnerTable:getTenId(partnerInfo.tableID)
					local star10 = xyd.tables.partnerTable:getStar10(partnerInfo.tableID)
					local maxStar = xyd.tables.partnerTable:getStar(partnerInfo.tableID)

					if not star10 and not nID and maxStar ~= 10 then
						ifContinue = true
					end
				end

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

	self.labelForceNum.text = tostring(self.power)

	self.partnerContainer:setInfos(partnerDataList, {})

	self.collect = partnerDataList
end

function Arena3v3BattleFormationWindow:isPartnerSelected(partnerID)
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

function Arena3v3BattleFormationWindow:refreshDataGroup(updatePartnerInfo)
	for i, partnerInfo in pairs(self.collect) do
		local partnerID = partnerInfo.partnerID

		if partnerID == updatePartnerInfo.partnerID then
			self.collect[i].partnerInfo = updatePartnerInfo

			break
		end
	end
end

function Arena3v3BattleFormationWindow:updateFormationItemInfo(info, realIndex)
	local partnerInfo = info.partnerInfo
	local partnerId = partnerInfo.partnerID
	local isSelected = info.isSelected
	local isS = self:isSelected(partnerId, self.nowPartnerList, false)

	if isSelected ~= isS.isSelected then
		info.isSelected = isS.isSelected

		self.partnerContainer:updateInfo(realIndex, info)
	end
end

function Arena3v3BattleFormationWindow:isSelected(cPartnerId, Plist, isDel)
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

function Arena3v3BattleFormationWindow:onClickheroIcon(partnerInfo, isChoose, needAnimation, posId)
	if self.isMaskOn then
		return
	end

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

			self:unChooseHeroByTeamList(posId, partnerInfo.tableID)
		end

		self:updateForceNum()

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

	if not self:checkAllServerBattleLimitByTouch(posId, partnerInfo.tableID) then
		return
	end

	partnerInfo.posId = posId

	local function copyCallback(copyIcon)
		self:iconTapHandler(copyIcon:getPartnerInfo())
	end

	local copyPartnerInfo = {
		noClickSelected = true,
		scale = 0.64,
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
	local index = self:getPetIndex(posId)

	copyIcon:setInfo(copyPartnerInfo, self.pets[index + 1])

	self.copyIconList_[posId] = copyIcon
	self.nowPartnerList[posId] = partnerInfo.partnerID
	local container = self["container_" .. posId]

	if needAnimation then
		-- Nothing
	end

	self:updateForceNum()
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

	return true
end

function Arena3v3BattleFormationWindow:checkAllServerBattleLimitBySwitch(partnerInfo, cPosId)
	if self.battleType ~= xyd.BattleType.ARENA_ALL_SERVER_DEF or cPosId <= 0 then
		return cPosId
	end

	local posId = tonumber(partnerInfo.posId)
	local tableID = partnerInfo.tableID
	local firstTableID = xyd.tables.partnerTable:getHeroList(tableID)[1] or 0
	local teamID = math.ceil(posId / 6)
	local cTeamID = math.ceil(cPosId / 6)

	if teamID == cTeamID then
		return cPosId
	end

	local cCopyIcon = self.copyIconList_[cPosId]

	if cCopyIcon then
		local cTableID = cCopyIcon:getPartnerInfo().tableID
		local cFirstTableID = xyd.tables.partnerTable:getHeroList(cTableID)[1] or 0

		if cFirstTableID == firstTableID then
			return cPosId
		end
	end

	if self:checkAllServerBattleLimit(cTeamID, firstTableID) then
		return 0
	end

	if cCopyIcon then
		local cTableID = cCopyIcon:getPartnerInfo().tableID
		local cFirstTableID = xyd.tables.partnerTable:getHeroList(cTableID)[1] or 0

		if self:checkAllServerBattleLimit(teamID, cFirstTableID) then
			return 0
		end

		self:changeAllServerTeamListVal(cTeamID, cFirstTableID, -1)
		self:changeAllServerTeamListVal(teamID, cFirstTableID, 1)
	end

	self:changeAllServerTeamListVal(teamID, firstTableID, -1)
	self:changeAllServerTeamListVal(cTeamID, firstTableID, 1)

	return cPosId
end

function Arena3v3BattleFormationWindow:checkAllServerBattleLimitByTouch(posId, tableID)
	if self.battleType ~= xyd.BattleType.ARENA_ALL_SERVER_DEF then
		return true
	end

	local firstTableID = xyd.tables.partnerTable:getHeroList(tableID)[1] or 0
	local teamID = math.ceil(posId / 6)

	if self:checkAllServerBattleLimit(teamID, firstTableID) then
		return false
	end

	self:changeAllServerTeamListVal(teamID, firstTableID, 1)

	return true
end

function Arena3v3BattleFormationWindow:checkAllServerBattleLimit(teamID, firstTableID)
	if self.allServerTeamList_[teamID] and self.allServerTeamList_[teamID][firstTableID] and self.allServerTeamList_[teamID][firstTableID] >= 2 then
		xyd.showToast(__("ARENA_ALL_SERVER_GROUP_LIMIT"))

		return true
	end

	return false
end

function Arena3v3BattleFormationWindow:unChooseHeroByTeamList(posId, tableID)
	if self.battleType ~= xyd.BattleType.ARENA_ALL_SERVER_DEF then
		return true
	end

	local firstTableID = xyd.tables.partnerTable:getHeroList(tableID)[1] or 0
	local teamID = math.ceil(posId / 6)

	self:changeAllServerTeamListVal(teamID, firstTableID, -1)
end

function Arena3v3BattleFormationWindow:changeAllServerTeamListVal(teamID, firstTableID, val)
	self.allServerTeamList_[teamID] = self.allServerTeamList_[teamID] or {}
	self.allServerTeamList_[teamID][firstTableID] = (self.allServerTeamList_[teamID][firstTableID] or 0) + val
end

function Arena3v3BattleFormationWindow:startDrag(copyIcon)
	if self.isMaskOn then
		return
	end

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

function Arena3v3BattleFormationWindow:onDrag(copyIcon, delta)
	if self.isMaskOn then
		return
	end

	if not self.isStartDrag then
		return
	end

	local go = copyIcon.go
	local pos = go.transform.localPosition
	go.transform.localPosition = Vector3(pos.x + delta.x / xyd.Global.screenToLocalAspect(), pos.y + delta.y / xyd.Global.screenToLocalAspect(), pos.z)
end

function Arena3v3BattleFormationWindow:endDrag(copyIcon)
	if self.isMaskOn then
		return
	end

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
	cPosId = self:checkAllServerBattleLimitBySwitch(partnerInfo, cPosId)

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

	if math.floor((cPosId - 1) / 6) ~= math.floor((posId - 1) / 6) and cPosId ~= -1 and posId ~= -1 then
		self:onChoosePet(self.pets)
	end
end

function Arena3v3BattleFormationWindow:playCopyIconActionByEndDrag(copyIcon, endContainer, cPosId, endPosition, aniDurition)
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

function Arena3v3BattleFormationWindow:longPressIcon(copyIcon)
	self:showPartnerDetail(copyIcon:getPartnerInfo())
end

function Arena3v3BattleFormationWindow:showPartnerDetail(partnerInfo)
	if not partnerInfo then
		return
	end

	local params = {
		sort_key = "0_0",
		unable_move = true,
		isLongTouch = true,
		not_open_slot = true,
		if3v3 = true,
		partner_id = partnerInfo.partnerID,
		table_id = partnerInfo.tableID,
		battleData = self.params_,
		ifSchool = self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT,
		skin_id = partnerInfo.skin_id
	}
	local wndName = nil

	if self.battleType == xyd.BattleType.HERO_CHALLENGE then
		local guidePartners = {}
		local groupIds = xyd.tables.groupTable:getGroupIds()
		guidePartners[0] = {}

		for i = 1, #groupIds do
			guidePartners[groupIds[i]] = {}
		end

		local partnerTable = xyd.tables.partnerTable
		local list = partnerTable:getIds()
		local heroIds = {}

		for i = 1, #list do
			if not xyd.tables.partnerTable:checkPuppetPartner(list[i]) then
				table.insert(heroIds, list[i])
			end
		end

		local exceptIdList = xyd.tables.miscTable:split2num("warmup_challenge_partner", "value", "|")

		for i = 1, #heroIds do
			local id = heroIds[i]
			local showInGuide = partnerTable:getShowInGuide(id)

			if xyd.Global.isReview ~= 1 and (xyd.arrayIndexOf(exceptIdList, tonumber(id)) > 0 or showInGuide >= 1 and showInGuide < xyd.getServerTime()) then
				local group = partnerTable:getGroup(id)

				table.insert(guidePartners[group], {
					table_id = id,
					key = group,
					parent = self
				})
				table.insert(guidePartners[0], {
					key = "0",
					table_id = id,
					parent = self
				})
			elseif xyd.global.isreview == 1 and partnerTable:getshowinreviewguide(id) == 1 then
				local group = partnerTable:getgroup(id)

				table.insert(guidePartners[group], {
					table_id = id,
					key = group,
					parent = self
				})
				table.insert(guidePartners[0], {
					key = "0",
					table_id = id,
					parent = self
				})
			end
		end

		wndName = "guide_detail_window"
	else
		wndName = "partner_detail_window"
	end

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
		pet_ids = self.pets,
		partners = formationIds
	}

	xyd.db.formation:setValue({
		key = self.battleType,
		value = cjson.encode(formation)
	})
	xyd.openWindow(wndName, params)
end

function Arena3v3BattleFormationWindow:saveLocalformation(formation)
	local dbParams = {
		value = cjson.encode(formation)
	}

	if self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT then
		dbParams.key = self.battleType .. "_" .. self.selectGroup_
	elseif not self.ifChooseEnemy then
		dbParams.key = self.battleType
	else
		dbParams.key = self.battleType .. "_enemy"
	end

	xyd.db.formation:addOrUpdate(dbParams)
end

function Arena3v3BattleFormationWindow:iconTapHandler(copyPartnerInfo)
	if self.isMaskOn then
		return
	end

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

		self:unChooseHeroByTeamList(posId, partnerInfo.tableID)
	end

	self:updateForceNum()
end

function Arena3v3BattleFormationWindow:getFormationItemByPartnerID(partnerID)
	local items = self.partnerContainer:getItems()

	for _, formationItem in ipairs(items) do
		if formationItem:getPartnerId() == partnerID then
			return formationItem
		end
	end
end

function Arena3v3BattleFormationWindow:isChange(copyIcon)
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

function Arena3v3BattleFormationWindow:updateForceNum()
	local power = 0

	for i, _ in pairs(self.copyIconList_) do
		if self.copyIconList_[i] then
			local partnerInfo = self.copyIconList_[i]:getPartnerInfo()
			power = power + partnerInfo.power
		end
	end

	self.labelForceNum.text = tostring(power)
end

function Arena3v3BattleFormationWindow:willClose()
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

function Arena3v3BattleFormationWindow:getBattleType()
	return self.battleType
end

function Arena3v3BattleFormationWindow:readStorageFormation()
	local dbVal = xyd.db.formation:getValue(self.battleType)

	if not dbVal then
		return
	end

	local data = cjson.decode(dbVal)

	if not data.partners then
		return
	end

	self.pets = data.pet_ids or self.pets

	if self.battleType == xyd.BattleType.ARENA_3v3_DEF then
		local teams = xyd.models.arena3v3:getDefTeams()
		local pets = {
			0,
			0,
			0,
			0
		}
		local isSetverPet = false

		for k, v in ipairs(teams) do
			local petId = v.pet.pet_id

			if petId and petId > 0 then
				pets[k + 1] = petId
				isSetverPet = true
			end
		end

		if not isSetverPet and self.pets and #self.pets >= 4 then
			pets = self.pets
		end

		self.pets = pets
	elseif self.battleType == xyd.BattleType.EXPLORE_OLD_CAMPUS then
		local teams = xyd.models.oldSchool:getDefTeams()
		local pets = {
			0,
			0,
			0,
			0
		}

		for k, v in ipairs(teams) do
			local petId = v.pet_id

			if petId and petId > 0 then
				pets[k + 1] = petId
			end
		end

		self.pets = pets
		self.old_campus_pets = {}

		for i in pairs(self.pets) do
			self.old_campus_pets[i] = self.pets[i]
		end
	end

	self.localPartnerList = data.partners

	for i = 1, 18 do
		local sPartnerID = tonumber(self.localPartnerList[tostring(i)])
		self.nowPartnerList[i] = sPartnerID

		if not xyd.models.slot:getPartner(sPartnerID) then
			self.localPartnerList[i] = nil
			self.nowPartnerList[i] = nil
		end
	end
end

function Arena3v3BattleFormationWindow:petChoose()
	if self.battleType == xyd.BattleType.EXPLORE_OLD_CAMPUS then
		xyd.WindowManager.get():openWindow("choose_pet_window", {
			type = xyd.PetFormationType.EXPLORE_OLD_CAMPUS,
			select = self.pets,
			levelNum = self.data.levelNum
		})
	end

	xyd.WindowManager.get():openWindow("choose_pet_window", {
		type = xyd.PetFormationType.Battle3v3,
		select = self.pets
	})
end

function Arena3v3BattleFormationWindow:onChoosePet(selectIDs)
	self.pets = selectIDs
	local i = 1

	for i = 1, 18 do
		local ifContinue = false
		local petIndex = self:getPetIndex(i)
		local cContainer = self["container_" .. i]
		local cIcon = self.copyIconList_[i]

		if cIcon then
			cIcon:setPetFrame(self.pets[petIndex + 1])
		end
	end

	self:updateRed()
end

function Arena3v3BattleFormationWindow:getPetIndex(posIndex)
	local indexMap = {}
	local i = 0

	for i = 1, #self.teamIndex do
		indexMap[self.teamIndex[i]] = i
	end

	local index = math.floor((posIndex - 1) / 6) + 1
	local i = indexMap[index]

	return i
end

function Arena3v3BattleFormationWindow:exploreOldCampusSaveFormation(params)
	xyd.models.oldSchool:setDefFormation(params, self.pets, self.data.floor_id, self.data.levelNum)
end

function ArenaBattleFormationHeroIcon:ctor()
	ArenaBattleFormationHeroIcon.super.ctor(self)

	self.win_ = xyd.WindowManager.get():getWindow("arena_3v3_battle_formation_window")
end

return Arena3v3BattleFormationWindow
