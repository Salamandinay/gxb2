local BaseWindow = import(".BaseWindow")
local ArenaAllServerBattleFormationWindow = class("ArenaAllServerBattleFormationWindow", BaseWindow)
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local PartnerFilter = import("app.components.PartnerFilter")
local HeroIcon = import("app.components.HeroIcon")
local cjson = require("cjson")
local FormationItem = class("FormationItem")

function FormationItem:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.heroIcon_ = nil
	self.win_ = xyd.getWindow("arena_all_server_battle_formation_window")
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

function ArenaAllServerBattleFormationWindow:ctor(name, params)
	ArenaAllServerBattleFormationWindow.super.ctor(self, name, params)

	self.callback = nil
	self.btnSkipCallback = nil
	self.SlotModel = xyd.models.slot
	self.isShowGuide_ = false
	self.ifMove = false
	self.teamIndex = {
		1,
		2,
		3,
		4,
		5
	}
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
	self.allServer_level = xyd.models.arenaAllServerScore:getRankLevel()

	if self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF_2 then
		if params.timeType == 1 then
			self.allServer_level = 22
			self.petLimitNum_ = 5
		elseif params.timeType == 2 then
			self.allServer_level = 22
			self.petLimitNum_ = 5
		end
	end

	self:readStorageFormation()

	self.data = params

	if (self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF or self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF_2) and params.formation then
		local teams = params.formation

		if teams.partners then
			for i = 1, 6 do
				if teams.partners[i] then
					self.nowPartnerList[teams.partners[i].pos] = teams.partners[i].partner_id
				end
			end
		end

		local subsitLevel = self.allServer_level
		local subsitNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(subsitLevel)

		if teams.front_infos then
			for i = 1, #teams.front_infos do
				local oneP = teams.front_infos[i]
				local posId = (math.floor((i - 1) / 2) + 1) * 6 + math.fmod(i - 1, 2) + 1
				self.nowPartnerList[posId] = teams.front_infos[i].partner_id
			end
		end

		if teams.back_infos then
			for i = 1, #teams.back_infos do
				local oneP = teams.back_infos[i]
				local posId = (math.floor((i - 1) / 4) + 1) * 6 + math.fmod(i - 1, 4) + 3
				self.nowPartnerList[posId] = teams.back_infos[i].partner_id
			end
		end
	end

	if self.battleType == xyd.BattleType.ARENA_ALL_SERVER and #self.nowPartnerList <= 0 then
		local teams = xyd.models.arenaAllServer:getDefFormation()

		if teams.partners then
			for i = 1, 6 do
				if teams.partners[i] then
					self.nowPartnerList[i] = teams.partners[i].partner_id
				end
			end
		end

		local subsitLevel = self.params_.enemy_level or self.allServer_level
		local subsitNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(subsitLevel)

		if teams.front_infos then
			for i = 1, #teams.front_infos do
				local oneP = teams.front_infos[i]
				local posId = (math.floor((i - 1) / 2) + 1) * 6 + math.fmod(i - 1, 2) + 1
				self.nowPartnerList[posId] = teams.front_infos[i].partner_id
			end
		end

		if teams.back_infos then
			for i = 1, #teams.back_infos do
				local oneP = teams.back_infos[i]
				local posId = (math.floor((i - 1) / 4) + 1) * 6 + math.fmod(i - 1, 4) + 3
				self.nowPartnerList[posId] = teams.back_infos[i].partner_id
			end
		end
	end

	if params and params.callback then
		self.callback = params.callback
	end
end

function ArenaAllServerBattleFormationWindow:setWndComplete()
	ArenaAllServerBattleFormationWindow.super.setWndComplete(self)
	self.delayGroup:SetActive(true)
	self.chooseGroup:SetActive(true)
end

function ArenaAllServerBattleFormationWindow:updateRed()
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

	local subsitLevel = self.params_.enemy_level or self.allServer_level
	local petLimitNum = xyd.tables.arenaAllServerRankTable:getPetNum(subsitLevel)
	petNum = math.min(petLimitNum, petNum)

	if petOnNum < petNum then
		v = true
	end

	if self.petRedImg then
		self.petRedImg:SetActive(v)
	end
end

function ArenaAllServerBattleFormationWindow:initWindow()
	ArenaAllServerBattleFormationWindow.super.initWindow(self)

	self.curHeight = math.min(xyd.getHeight(), xyd.Global.maxBgHeight)
	self.chooseGroupHeight = 462 + (self.curHeight - 1280) / 2

	self:getUIComponents()
	self:initLayOut()
	self:registerEvent()

	self.needSound = true

	self:updateRed()
	self.btnPet:SetActive(false)

	self.btnPetLabel.text = __("BATTLE_FORMAION_PET")
	self.labelWinTitle_.text = __("SPRING_FESTIVAL_TEXT01")
	self.labelFront1.text = __("NEW_ARENA_ALL_SERVER_TEXT_5")
	self.labelFront2.text = __("NEW_ARENA_ALL_SERVER_TEXT_7")
	self.labelBack1.text = __("NEW_ARENA_ALL_SERVER_TEXT_6")
	self.labelBack2.text = __("NEW_ARENA_ALL_SERVER_TEXT_8")

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

	if self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF or self.battleType == xyd.BattleType.ARENA_ALL_SERVER or self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF_2 then
		self.groupForce:SetActive(true)
	end

	self:updateForceNum()
	self:updateLockImg()

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

	self:initPartnerList()
end

function ArenaAllServerBattleFormationWindow:updateLockImg()
	local subsitLevel = self.params_.enemy_level or self.allServer_level
	local subsitNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(subsitLevel)

	for i = subsitNum + 2, 5 do
		self["teamBtn" .. i]:SetActive(false)
	end

	if subsitNum > 0 then
		for i = 1, subsitNum + 1 do
			self["teamBtn" .. i]:SetActive(true)
		end
	end

	for i = (subsitNum + 1) * 6 + 1, 30 do
		self["container_lock_" .. tostring(i)]:SetActive(true)

		UIEventListener.Get(self["container_lock_" .. tostring(i)]).onClick = function ()
			if i >= 7 and i < 12 then
				xyd.alertTips(__("NEW_ARENA_ALL_SERVER_TEXT_9"))
			elseif i >= 13 and i < 18 then
				xyd.alertTips(__("NEW_ARENA_ALL_SERVER_TEXT_10"))
			else
				xyd.alertTips(__("NEW_ARENA_ALL_SERVER_TEXT_11"))
			end
		end
	end
end

function ArenaAllServerBattleFormationWindow:getUIComponents()
	local trans = self.window_:NodeByName("groupAction")
	self.teamGroup = trans:NodeByName("teamGroup").gameObject
	self.dragPanelTran = trans:Find("drag_panel")
	self.dragPanel = self.dragPanelTran.gameObject:GetComponent(typeof(UIPanel))
	self.bgImg2 = self.teamGroup:NodeByName("bgImg2").gameObject
	self.labelWinTitle_ = self.teamGroup:ComponentByName("labelWinTitle", typeof(UILabel))
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
	self.labelFront1 = self.delayGroup:ComponentByName("labelFront1", typeof(UILabel))
	self.labelFront2 = self.delayGroup:ComponentByName("labelFront2", typeof(UILabel))
	self.labelBack1 = self.delayGroup:ComponentByName("labelBack1", typeof(UILabel))
	self.labelBack2 = self.delayGroup:ComponentByName("labelBack2", typeof(UILabel))
	self.teamBg1 = self.delayGroup:NodeByName("teamBg1").gameObject
	self.teamBg2 = self.delayGroup:NodeByName("teamBg2").gameObject
	self.team = self.delayGroup:NodeByName("team").gameObject
	local defaultNum = 3

	for i = 1, 5 do
		local tmp = self.team:NodeByName("selectedFormationGroup_" .. i).gameObject
		self["selectedFormationGroup_" .. i] = tmp
		local bottom = tmp:NodeByName("bottom").gameObject

		for j = 3, 6 do
			self["container_" .. tostring(j + (i - 1) * 6)] = bottom:NodeByName("container_" .. tostring(j)).gameObject
			self["container_lock_" .. tostring(j + (i - 1) * 6)] = bottom:NodeByName("container_" .. tostring(j) .. "/lockImg").gameObject
		end

		local top = tmp:NodeByName("top").gameObject

		for j = 1, 2 do
			self["container_" .. tostring(j + (i - 1) * 6)] = top:NodeByName("container_" .. tostring(j)).gameObject
			self["container_lock_" .. tostring(j + (i - 1) * 6)] = top:NodeByName("container_" .. tostring(j) .. "/lockImg").gameObject
		end

		for j = 1, 2 do
			self["maskImg" .. tostring(j + (i - 1) * 6)] = top:NodeByName("container_" .. tostring(j) .. "/maskImg").gameObject

			self["maskImg" .. tostring(j + (i - 1) * 6)]:SetActive(false)
		end

		for j = 3, 6 do
			self["maskImg" .. tostring(j + (i - 1) * 6)] = bottom:NodeByName("container_" .. tostring(j) .. "/maskImg").gameObject

			self["maskImg" .. tostring(j + (i - 1) * 6)]:SetActive(false)
		end

		self["teamBtn" .. i] = tmp:NodeByName("teamBtn").gameObject
		self["teamBtnIcon" .. i] = self["teamBtn" .. i]:ComponentByName("icon", typeof(UISprite))
		self.btnCurState[i] = "unchosen"

		xyd.setUISpriteAsync(self["teamBtnIcon" .. i]:GetComponent(typeof(UISprite)), nil, "arena_3v3_exchange_team")
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

function ArenaAllServerBattleFormationWindow:registerEvent()
	ArenaAllServerBattleFormationWindow.super.register(self)

	UIEventListener.Get(self.battleBtn).onClick = handler(self, self.onClickBattleBtn)
	UIEventListener.Get(self.setBtn).onClick = handler(self, self.onclickSet)

	for i = 1, 2 do
		UIEventListener.Get(self["teamBg" .. i]).onClick = handler(self, self.onclickBoard)
	end

	UIEventListener.Get(self.operationBg).onClick = handler(self, self.onclickBoard)
	UIEventListener.Get(self.bgImg2).onClick = handler(self, self.onclickBoard)
	UIEventListener.Get(self.tipBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("battle_tips_window", {})
	end)

	for i = 1, 5 do
		UIEventListener.Get(self["teamBtn" .. i]).onClick = function ()
			self:onClickTeamBtn(i)
		end
	end
end

function ArenaAllServerBattleFormationWindow:onclickBoard()
	local action = self:getSequence()

	action:Insert(0, self.teamGroup.transform:DOLocalMove(Vector3(0, 0, 0), 0.2))
	action:Insert(0, self.chooseGroup.transform:DOLocalMove(Vector3(0, -self.curHeight / 2, 0), 0.2))

	for i = 1, 5 do
		if self.btnCurState[i] == "chosen" then
			self:onClickTeamBtn(i)
		end

		xyd.setTouchEnable(self["teamBtn" .. i], true)
	end
end

function ArenaAllServerBattleFormationWindow:onclickSet()
	local action = self:getSequence()

	action:Insert(0, self.teamGroup.transform:DOLocalMove(Vector3(0, 168, 0), 0.2))
	action:Insert(0, self.chooseGroup.transform:DOLocalMove(Vector3(0, -171, 0), 0.2))
end

function ArenaAllServerBattleFormationWindow:onClickBattleBtn()
	local partnerParams = {}
	local formationIds = {}
	local indexMap = {}

	for i = 0, #self.teamIndex - 1 do
		indexMap[self.teamIndex[i + 1]] = i
	end

	local canFight = false
	local subsitLevel = self.params_.enemy_level or self.allServer_level
	local subsitNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(subsitLevel)

	for posId, _ in pairs(self.copyIconList_) do
		local index = math.floor(tonumber(posId - 1) / 6) + 1
		local id = indexMap[index] * 6 + tonumber(posId - 1) % 6 + 1
		local partnerIcon = self.copyIconList_[posId]

		if partnerIcon then
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

	for i = 1, 6 do
		if partnerParams[i] then
			canFight = true

			break
		end
	end

	if not canFight then
		return
	end

	local formation = {
		pet_ids = self.pets,
		partners = formationIds
	}
	local dbVal = xyd.db.formation:getValue(self.battleType)

	if dbVal then
		local data = cjson.decode(dbVal)

		if data.partners and next(data.partners) ~= nil then
			local subsitLevel = self.params_.enemy_level or self.allServer_level
			local subsitNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(subsitLevel)

			for i = 1, 30 do
				local stringi = tostring(i)

				if data.partners[stringi] and tonumber(data.partners[stringi]) and xyd.arrayIndexOf(formationIds, data.partners[stringi]) > 0 then
					data.partners[stringi] = nil
				end
			end

			for i = 1, (subsitNum + 1) * 6 do
				local stringi = tostring(i)
				data.partners[stringi] = formationIds[stringi]
			end
		end

		data.pet_ids = self.pets

		xyd.db.formation:setValue({
			key = self.battleType,
			value = cjson.encode(data)
		})
	else
		xyd.db.formation:setValue({
			key = self.battleType,
			value = cjson.encode(formation)
		})
	end

	self.isCloseSelf = true

	if self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF then
		self:arenaAllServerBattleDef(partnerParams)
	elseif self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF_2 then
		self:arenaAllServerBattleDef2(partnerParams)
	elseif self.battleType == xyd.BattleType.ARENA_ALL_SERVER then
		self:arenaAllServerBattleBattle(partnerParams)
	end

	self.callback = nil

	if self.isCloseSelf then
		xyd.WindowManager.get():closeWindow("arena_all_server_battle_formation_window")
	end
end

function ArenaAllServerBattleFormationWindow:arena3v3Battle(params)
	xyd.models.arena3v3:fight(self.params_.enemy_id, params, self.pets, self.params_.is_revenge)
end

function ArenaAllServerBattleFormationWindow:arena3v3BattleDef(params)
	xyd.models.arena3v3:setDefFormation(params, self.pets)

	local rank = xyd.models.arena3v3:getRank()

	if rank <= xyd.TOP_ARENA_NUM then
		self:waitForTime(0.1, xyd.models.arena3v3.reqRankList)
	end

	function self.callback()
		local win = xyd.WindowManager.get():getWindow("arena_3v3_window")

		if win then
			-- Nothing
		end
	end
end

function ArenaAllServerBattleFormationWindow:arenaAllServerBattleDef(params)
	xyd.models.arenaAllServerScore:reqSetTeams(params, self.pets)
end

function ArenaAllServerBattleFormationWindow:arenaAllServerBattleDef2(params)
	xyd.models.arenaAllServerNew:reqSetTeams(params, self.pets, self.allServer_level)
end

function ArenaAllServerBattleFormationWindow:arenaAllServerBattleBattle(params)
	local needCheck = not xyd.models.arenaAllServerScore.hasCheck

	if needCheck then
		local defPartners = xyd.models.arenaAllServerScore:getDefFormation()
		local oldDef = defPartners.partners or {}
		local oldDef2 = defPartners.front_infos or {}
		local oldDef3 = defPartners.back_infos or {}
		local defPower = 0

		for i = 1, #oldDef do
			local power = oldDef[i].power
			defPower = defPower + power
		end

		for i = 1, #oldDef2 do
			local power = oldDef2[i].power
			defPower = defPower + power
		end

		for i = 1, #oldDef3 do
			local power = oldDef3[i].power
			defPower = defPower + power
		end

		local numSave = xyd.tables.miscTable:getVal("defense_team_save")

		if self.power and tonumber(numSave) < self.power / defPower then
			xyd.models.arenaAllServerScore:checkDefFormation()
		end

		xyd.models.arenaAllServerScore.hasCheck = true
	end

	xyd.models.arenaAllServerScore:reqFight(params, self.pets, self.params_.enemy_id, self.params_.enemy_level, self.params_.is_revenge)
end

function ArenaAllServerBattleFormationWindow:initLayOut()
	self.setBtnLabel.text = __("SET_DEF_FORMATION")

	if self.battleType == xyd.BattleType.ARENA_3v3 or self.battleType == xyd.BattleType.ARENA_ALL_SERVER then
		self.battleBtnLabel.text = __("BATTLE_START")
	elseif self.battleType == xyd.BattleType.ARENA_3v3_DEF or self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF or self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF_2 or self.battleType == xyd.BattleType.EXPLORE_OLD_CAMPUS then
		self.battleBtnLabel.text = __("SAVE_DEF_FORMATION")
	end

	self.teamGroup.transform.localPosition = Vector3(0, 0, 0)

	self.delayGroup:SetActive(false)

	self.chooseGroup.transform.localPosition = Vector3(0, -self.curHeight / 2, 0)
end

function ArenaAllServerBattleFormationWindow:onSelectGroup(group)
	if self.selectGroup_ == group then
		return
	end

	self.selectGroup_ = group

	self:iniPartnerData(group)
end

function ArenaAllServerBattleFormationWindow:getPartners()
	local list = self.SlotModel:getSortedPartners()

	return list
end

function ArenaAllServerBattleFormationWindow:initPartnerList()
	self:iniPartnerData(0)
end

function ArenaAllServerBattleFormationWindow:iniPartnerData(groupID)
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
		local ifContinue = false
		local partner = self.SlotModel:getPartner(tonumber(partnerId))
		local partnerInfo = partner:getInfo()
		partnerInfo.power = partner:getPower()
		partnerInfo.noClick = true
		local pGroupID = xyd.tables.partnerTable:getGroup(partnerInfo.tableID)
		local isS = isSelected(partnerInfo.partnerID, self.nowPartnerList, false)

		if groupID ~= 0 and pGroupID ~= groupID then
			if not isS then
				ifContinue = true
			end
		elseif self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF_2 then
			local nID = xyd.tables.partnerTable:getTenId(partnerInfo.tableID) or 0
			local star10 = xyd.tables.partnerTable:getStar10(partnerInfo.tableID) or 0
			local maxStar = xyd.tables.partnerTable:getStar(partnerInfo.tableID)

			if star10 <= 0 and nID <= 0 and maxStar ~= 10 then
				ifContinue = true
			end

			if partnerInfo.tableID > 660000 and partnerInfo.tableID < 670000 or partnerInfo.tableID > 760000 and partnerInfo.tableID < 770000 then
				ifContinue = true
			end
		elseif (self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF or self.battleType == xyd.BattleType.ARENA_ALL_SERVER) and (partnerInfo.tableID > 560000 and partnerInfo.tableID < 570000 or partnerInfo.tableID > 660000 and partnerInfo.tableID < 670000 or partnerInfo.tableID > 760000 and partnerInfo.tableID < 770000) then
			ifContinue = true
		end

		if not ifContinue then
			local data = {
				callbackFunc = function (partnerInfo, isChoose)
					return self:onClickheroIcon(partnerInfo, isChoose, true)
				end,
				partnerInfo = partnerInfo,
				isSelected = isS
			}

			table.insert(partnerDataList, data)
		end
	end

	local subsitLevel = self.params_.enemy_level or self.allServer_level
	local subsitNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(subsitLevel)

	for i, _ in pairs(self.nowPartnerList) do
		if i <= (subsitNum + 1) * 6 then
			local ifContinue = false
			local partnerId = self.nowPartnerList[i]
			local partner = self.SlotModel:getPartner(tonumber(partnerId))

			if partner then
				local partnerInfo = partner:getInfo()

				if self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF_2 then
					local nID = xyd.tables.partnerTable:getTenId(partnerInfo.tableID)
					local star10 = xyd.tables.partnerTable:getStar10(partnerInfo.tableID)
					local maxStar = xyd.tables.partnerTable:getStar(partnerInfo.tableID)

					if star10 <= 0 and nID <= 0 and maxStar ~= 10 then
						ifContinue = true
					end
				elseif (self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF or self.battleType == xyd.BattleType.ARENA_ALL_SERVER) and (partnerInfo.tableID > 560000 and partnerInfo.tableID < 570000 or partnerInfo.tableID > 660000 and partnerInfo.tableID < 670000 or partnerInfo.tableID > 760000 and partnerInfo.tableID < 770000) then
					ifContinue = true
				end

				if not ifContinue then
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
		else
			self.nowPartnerList[i] = nil
		end
	end

	self.labelForceNum.text = tostring(self.power)

	self.partnerContainer:setInfos(partnerDataList, {})

	self.collect = partnerDataList
end

function ArenaAllServerBattleFormationWindow:isPartnerSelected(partnerID)
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

function ArenaAllServerBattleFormationWindow:refreshDataGroup(updatePartnerInfo)
	for i, partnerInfo in pairs(self.collect) do
		local partnerID = partnerInfo.partnerID

		if partnerID == updatePartnerInfo.partnerID then
			self.collect[i].partnerInfo = updatePartnerInfo

			break
		end
	end
end

function ArenaAllServerBattleFormationWindow:updateFormationItemInfo(info, realIndex)
	local partnerInfo = info.partnerInfo
	local partnerId = partnerInfo.partnerID
	local isSelected = info.isSelected
	local isS = self:isSelected(partnerId, self.nowPartnerList, false)

	if isSelected ~= isS.isSelected then
		info.isSelected = isS.isSelected

		self.partnerContainer:updateInfo(realIndex, info)
	end
end

function ArenaAllServerBattleFormationWindow:isSelected(cPartnerId, Plist, isDel)
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

function ArenaAllServerBattleFormationWindow:onClickheroIcon(partnerInfo, isChoose, needAnimation, posId)
	if self.isMaskOn then
		return
	end

	if posId == nil then
		posId = 0
	end

	if self.needSound then
		-- Nothing
	end

	local subsitLevel = self.params_.enemy_level or self.allServer_level
	local subsitNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(subsitLevel)

	if isChoose then
		local params = self:isSelected(partnerInfo.partnerID, self.nowPartnerList)
		local isChoose = params.isSelected
		posId = params.posId

		if posId >= 0 then
			local container = self["container_" .. tostring(posId)]
			local heroIcon = container.transform:NodeByName("hero_icon").gameObject

			if heroIcon then
				NGUITools.Destroy(heroIcon)
			end

			self.copyIconList_[posId] = nil
			self.nowPartnerList[posId] = nil
		end

		self:updateForceNum()

		return true
	end

	posId = tonumber(posId)

	if posId == 0 or not posId then
		local flag = false

		for i = 1, subsitNum + 1 do
			for j = 1, 6 do
				posId = (i - 1) * 6 + j

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
	local petId = self:getPet()

	if posId and posId > 6 then
		petId = 0
	end

	copyIcon:setInfo(copyPartnerInfo, petId)

	self.copyIconList_[posId] = copyIcon
	self.nowPartnerList[posId] = partnerInfo.partnerID
	local container = self["container_" .. posId]

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

function ArenaAllServerBattleFormationWindow:startDrag(copyIcon)
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

function ArenaAllServerBattleFormationWindow:onDrag(copyIcon, delta)
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

function ArenaAllServerBattleFormationWindow:endDrag(copyIcon)
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

function ArenaAllServerBattleFormationWindow:playCopyIconActionByEndDrag(copyIcon, endContainer, cPosId, endPosition, aniDurition)
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

function ArenaAllServerBattleFormationWindow:longPressIcon(copyIcon)
	self:showPartnerDetail(copyIcon:getPartnerInfo())
end

function ArenaAllServerBattleFormationWindow:showPartnerDetail(partnerInfo)
	if not partnerInfo then
		return
	end

	local params = {
		unable_move = true,
		isLongTouch = true,
		sort_key = "0_0",
		not_open_slot = true,
		ifAllServer = true,
		partner_id = partnerInfo.partnerID,
		table_id = partnerInfo.tableID,
		battleData = self.params_,
		ifSchool = self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT
	}
	local wndName = "partner_detail_window"
	local partnerParams = {}
	local formationIds = {}
	local indexMap = {}
	local subsitLevel = self.params_.enemy_level or self.allServer_level
	local subsitNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(subsitLevel)

	for i = 0, subsitNum do
		indexMap[i + 1] = i
	end

	for posId, _ in pairs(self.copyIconList_) do
		local index = math.floor(tonumber(posId - 1) / 6) + 1
		local id = indexMap[index] * 6 + tonumber(posId - 1) % 6 + 1
		local partnerIcon = self.copyIconList_[posId]

		if partnerIcon then
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

	if #partnerParams <= 0 then
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
	xyd.openWindow(wndName, params)
end

function ArenaAllServerBattleFormationWindow:saveLocalformation(formation)
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

function ArenaAllServerBattleFormationWindow:iconTapHandler(copyPartnerInfo)
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
	end

	self:updateForceNum()
end

function ArenaAllServerBattleFormationWindow:getFormationItemByPartnerID(partnerID)
	local items = self.partnerContainer:getItems()

	for _, formationItem in ipairs(items) do
		if formationItem:getPartnerId() == partnerID then
			return formationItem
		end
	end
end

function ArenaAllServerBattleFormationWindow:isChange(copyIcon)
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
	local subsitLevel = self.params_.enemy_level or self.allServer_level
	local subsitNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(subsitLevel)

	for posId = 1, 6 * (subsitNum + 1) do
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

function ArenaAllServerBattleFormationWindow:updateForceNum()
	local power = 0

	for i, _ in pairs(self.copyIconList_) do
		if self.copyIconList_[i] then
			local partnerInfo = self.copyIconList_[i]:getPartnerInfo()
			power = power + partnerInfo.power
		end
	end

	self.labelForceNum.text = tostring(power)
end

function ArenaAllServerBattleFormationWindow:willClose()
	BaseWindow.willClose(self)

	if self.chooseGroup then
		self.chooseGroup:SetActive(false)
		NGUITools.DestroyChildren(self.chooseGroup.transform)
		NGUITools.Destroy(self.chooseGroup)
	end

	if self.callback then
		self:callback()
	end

	self.chooseGroup:SetActive(false)
	self.delayGroup:SetActive(false)
end

function ArenaAllServerBattleFormationWindow:getBattleType()
	return self.battleType
end

function ArenaAllServerBattleFormationWindow:readStorageFormation()
	local dbVal = xyd.db.formation:getValue(self.battleType)

	if not dbVal then
		return
	end

	local data = cjson.decode(dbVal)

	if not data.partners then
		return
	end

	self.pets = data.pet_ids or self.pets

	if self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF then
		local teams = xyd.models.arenaAllServerScore:getDefFormation()
		local petLimitNum = xyd.tables.arenaAllServerRankTable:getPetNum(self.params_.enemy_level or self.allServer_level)
		local pets = {
			0,
			0,
			0,
			0,
			0,
			0,
			0
		}
		local pet_infos = teams.pet_infos or {}
		local isSetverPet = false

		for i = 1, #pets do
			if pet_infos[i] and pet_infos[i].pet_id > 0 then
				pets[i + 1] = pet_infos[i].pet_id
			else
				pets[i + 1] = 0
			end
		end

		self.pets = pets
	elseif self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF_2 then
		local teams = xyd.models.arenaAllServerNew:getDefFormation()
		local pets = {
			0,
			0,
			0,
			0,
			0,
			0,
			0
		}
		local petLimitNum = self.petLimitNum_ or xyd.tables.arenaAllServerRankTable:getPetNum(self.params_.enemy_level or self.allServer_level)
		local pet_infos = teams.pet_infos or {}
		local isSetverPet = false

		for i = 1, #pets do
			if pet_infos[i] and pet_infos[i].pet_id > 0 and i <= petLimitNum then
				pets[i + 1] = pet_infos[i].pet_id
			else
				pets[i + 1] = 0
			end
		end

		self.pets = pets
	elseif self.battleType == xyd.BattleType.ARENA_ALL_SERVER then
		local pets = {
			0,
			0,
			0,
			0,
			0,
			0,
			0
		}
		local petLimitNum = xyd.tables.arenaAllServerRankTable:getPetNum(self.params_.enemy_level or self.allServer_level)

		for i = 1, #pets do
			if data.pet_ids[i] and data.pet_ids[i] > 0 then
				pets[i] = data.pet_ids[i]
			else
				pets[i] = 0
			end
		end

		self.pets = pets
	end

	self.localPartnerList = data.partners

	for i = 1, 30 do
		local sPartnerID = tonumber(self.localPartnerList[tostring(i)])
		self.nowPartnerList[i] = sPartnerID

		if not xyd.models.slot:getPartner(sPartnerID) then
			self.localPartnerList[i] = nil
			self.nowPartnerList[i] = nil
		end

		local subsitLevel = self.params_.enemy_level or self.allServer_level
		local subsitNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(subsitLevel)

		if i > (subsitNum + 1) * 6 then
			self.localPartnerList[i] = nil
			self.nowPartnerList[i] = nil
		end
	end
end

function ArenaAllServerBattleFormationWindow:petChoose()
	xyd.WindowManager.get():openWindow("choose_pet_window", {
		type = xyd.PetFormationType.Battle5v5,
		select = self.pets,
		subsitLevel = self.params_.enemy_level or self.allServer_level,
		pet_limit_num = self.petLimitNum_
	})
end

function ArenaAllServerBattleFormationWindow:onChoosePet(selectIDs)
	self.pets = selectIDs
	local i = 1
	local subsitLevel = self.params_.enemy_level or self.allServer_level
	local subsitNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(subsitLevel)

	for index, copyIcon in pairs(self.copyIconList_) do
		local ifContinue = false
		local petId = self:getPet()
		local cContainer = self["container_" .. index]
		local cIcon = self.copyIconList_[index]

		if index > 6 then
			petId = 0
		end

		if cIcon then
			cIcon:setPetFrame(petId)
		end
	end

	self:updateRed()
end

function ArenaAllServerBattleFormationWindow:getPet()
	local index = 6
	local petId = 0

	for i, pet_id in ipairs(self.pets) do
		if pet_id and pet_id > 0 and i < index then
			petId = pet_id
			index = i

			break
		end
	end

	return petId
end

function ArenaAllServerBattleFormationWindow:onClickTeamBtn(index)
	local choseFlag = self.btnCurState[index] == "chosen"
	local switchFlag = self.btnCurState[index] == "switch"
	local subsitLevel = self.params_.enemy_level or self.allServer_level
	local subsitNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(subsitLevel)

	if not switchFlag then
		for i = 1, subsitNum + 1 do
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

		for i = 1, 5 do
			if self.btnCurState[i] == "chosen" then
				chosenIndex = i

				break
			end
		end

		if chosenIndex == 0 then
			for i = 1, 5 do
				self.btnCurState[i] = "unchosen"

				xyd.setUISpriteAsync(self["teamBtnIcon" .. i]:GetComponent(typeof(UISprite)), nil, "arena_3v3_exchange_team")
				xyd.setUISpriteAsync(self["teamBtn" .. i]:GetComponent(typeof(UISprite)), nil, "white_btn_65_65")
			end

			return
		end

		self:switchTeam(index, chosenIndex)

		for i = 1, 5 do
			self.btnCurState[i] = "unchosen"

			xyd.setUISpriteAsync(self["teamBtnIcon" .. i]:GetComponent(typeof(UISprite)), nil, "arena_3v3_exchange_team")
			xyd.setUISpriteAsync(self["teamBtn" .. i]:GetComponent(typeof(UISprite)), nil, "white_btn_65_65")
		end

		self:removeMask()
	end
end

function ArenaAllServerBattleFormationWindow:setMask(index)
	for i = 1, 30 do
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

function ArenaAllServerBattleFormationWindow:removeMask()
	for i = 1, 30 do
		self["maskImg" .. i]:SetActive(false)
	end

	xyd.setTouchEnable(self.setBtn, true)
	xyd.setTouchEnable(self.battleBtn, true)
	xyd.setTouchEnable(self.btnSkip, true)

	self.isMaskOn = false
end

function ArenaAllServerBattleFormationWindow:switchTeam(index1, index2)
	local teamGroup1 = self["selectedFormationGroup_" .. index1]
	local teamGroup2 = self["selectedFormationGroup_" .. index2]
	local pos1 = teamGroup1.transform.localPosition
	teamGroup1.transform.localPosition = teamGroup2.transform.localPosition
	teamGroup2.transform.localPosition = pos1
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

return ArenaAllServerBattleFormationWindow
