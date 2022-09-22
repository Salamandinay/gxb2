local json = require("cjson")
local GroupBuffIcon = import("app.components.GroupBuffIcon")
local GroupBuffIconItem = class("GroupBuffIconItem")
local Monster = import("app.models.Monster")
local SoundManager = xyd.SoundManager.get()

function GroupBuffIconItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.groupBuffIcon = GroupBuffIcon.new(self.go, self.parent.buffRenderPanel)

	self.groupBuffIcon:setScale(0.9)
	self.groupBuffIcon:setDragScrollView(self.parent.buffScrollView)

	UIEventListener.Get(self.groupBuffIcon:getGameObject()).onPress = function (go, isPress)
		if isPress then
			local win = xyd.WindowManager.get():getWindow("group_buff_detail_window")

			if win then
				xyd.WindowManager.get():closeWindow("group_buff_detail_window", function ()
					XYDCo.WaitForTime(1, function ()
						local params = {
							buffID = self.info_.buffId,
							type = self.info_.type_,
							contenty = self.info_.contenty,
							group7Num = self.info_.group7Num
						}

						xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
					end, nil)
				end)
			else
				local params = {
					buffID = self.info_.buffId,
					type = self.info_.type_,
					contenty = self.info_.contenty,
					group7Num = self.info_.group7Num
				}

				xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
			end
		else
			xyd.WindowManager.get():closeWindow("group_buff_detail_window")
		end
	end
end

function GroupBuffIconItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	if not self.groupBuffIcon then
		self.groupBuffIcon = GroupBuffIcon.new(self.go, self.parent.buffRenderPanel)
	end

	self.groupBuffIcon:setInfo(info.buffId, info.isAct, info.type_)

	self.info_ = info

	self.go:SetActive(true)
end

function GroupBuffIconItem:getGameObject()
	return self.go
end

local FormationItem = class("FormationItem")

function FormationItem:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.heroIcon_ = nil

	if not self.parent_ then
		self.win_ = xyd.getWindow("battle_formation_window")
	else
		self.win_ = self.parent_
	end

	self.isFriend = false
end

function FormationItem:setIsFriend(isFriend)
	self.isFriend = isFriend
end

function FormationItem:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)

	if realIndex ~= nil then
		self.parent_:updateFormationItemInfo(info, realIndex)
	end

	if not self.heroIcon_ then
		self.heroIcon_ = import("app.components.HeroIcon").new(self.uiRoot_, self.parent_.partnerRenderPanel)

		local function longPressCallback(callbackCopyIcon)
			self.parent_:longPressIcon(callbackCopyIcon)
		end

		if self.isFriend == false then
			self.heroIcon_:setLongPressListener(longPressCallback)
		end
	end

	self.uiRoot_:SetActive(true)

	self.partner_ = info.partnerInfo
	self.callbackFunc = info.callbackFunc

	self:setIsChoose(false)
	self.heroIcon_:setLock(false)
	self:setIsChoose(info.isSelected)

	self.partnerId_ = self.partner_.partnerID
	self.partner_.noClickSelected = true
	self.partner_.callback = handler(self, self.onClick)
	self.partner_.dragScrollView = self.parent_.partnerScrollView
	self.partner_.is_vowed = self.partner_.is_vowed
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

	local battleWin = xyd.WindowManager.get():getWindow("battle_formation_window")
	local battleType = -1

	if battleWin then
		battleType = battleWin.battleType
	end

	if battleType == xyd.BattleType.ENTRANCE_TEST or battleType == xyd.BattleType.ENTRANCE_TEST_DEF then
		self.heroIcon_:setEntranceTestFinish()

		local period = xyd.tables.activityWarmupArenaPartnerTable:getPeriod(self.partnerId_)

		if period and period > 0 then
			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)

			if activityData:getPvePartnerIsLock(period) then
				self.heroIcon_:setLock(true)
			else
				self.heroIcon_:setLock(false)
			end
		end
	elseif battleType == xyd.BattleType.GUILD_COMPETITION and xyd.models.guild:getCompetitionSpecialPartner() and self.partner_:getPartnerID() == xyd.models.guild:getCompetitionSpecialTruePartnerInfo().truePartnerID then
		self.heroIcon_:setLock(true)
	end

	local friendHelpBattleType = self.parent_.battleType

	if friendHelpBattleType and (friendHelpBattleType == xyd.BattleType.TIME_CLOISTER_EXTRA or friendHelpBattleType == xyd.BattleType.TIME_CLOISTER_BATTLE or friendHelpBattleType == xyd.BattleType.GUILD_COMPETITION) then
		if self.partnerId_ < 0 then
			if not self.friendHelpIcon then
				self.friendHelpIcon = NGUITools.AddChild(self.uiRoot_.gameObject, "frientHelpIcon")
				self.friendHelpIconUISprite = self.friendHelpIcon:AddComponent(typeof(UISprite))

				if friendHelpBattleType == xyd.BattleType.TIME_CLOISTER_EXTRA or friendHelpBattleType == xyd.BattleType.TIME_CLOISTER_BATTLE then
					xyd.setUISpriteAsync(self.friendHelpIconUISprite, nil, "friend_boss_assist", nil, , )

					local friendHelpIconUIWidget = self.friendHelpIcon:GetComponent(typeof(UIWidget))
					friendHelpIconUIWidget.depth = self.uiRoot_:GetComponent(typeof(UIWidget)).depth + 50
					friendHelpIconUIWidget.width = 36
					friendHelpIconUIWidget.height = 34

					self.friendHelpIcon.gameObject:SetLocalPosition(37, -40, 0)
				elseif friendHelpBattleType == xyd.BattleType.GUILD_COMPETITION then
					xyd.setUISpriteAsync(self.friendHelpIconUISprite, nil, "guild_competition_bg_gh", nil, , )

					local friendHelpIconUIWidget = self.friendHelpIcon:GetComponent(typeof(UIWidget))
					friendHelpIconUIWidget.depth = self.uiRoot_:GetComponent(typeof(UIWidget)).depth + 50
					friendHelpIconUIWidget.width = 34
					friendHelpIconUIWidget.height = 30

					self.friendHelpIcon.gameObject:SetLocalPosition(37, -40, 0)
				end
			else
				self.friendHelpIcon.gameObject:SetActive(true)
			end
		elseif self.friendHelpIcon then
			self.friendHelpIcon.gameObject:SetActive(false)
		end
	end
end

function FormationItem:onClick()
	if self.isDeath_ then
		xyd.alert(xyd.AlertType.TIPS, __("ALREADY_DIE"))

		return
	end

	local battleWin = xyd.WindowManager.get():getWindow("battle_formation_window")
	local battleType = -1

	if battleWin then
		battleType = battleWin.battleType
	end

	if battleType == xyd.BattleType.ENTRANCE_TEST or battleType == xyd.BattleType.ENTRANCE_TEST_DEF then
		local period = xyd.tables.activityWarmupArenaPartnerTable:getPeriod(self.partnerId_)

		if period and period > 0 then
			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)

			if activityData:getPvePartnerIsLock(period) then
				xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_NEW_WARMUP_TEXT" .. period + 25))

				return
			end
		end
	elseif battleType == xyd.BattleType.GUILD_COMPETITION and xyd.models.guild:getCompetitionSpecialPartner() and self.partner_:getPartnerID() == xyd.models.guild:getCompetitionSpecialTruePartnerInfo().truePartnerID then
		xyd.alertTips(__("GUILD_COMPETITION_PARTNER_TEXT07"))

		return
	end

	local isItemChoose = true

	if self.win_ ~= nil and not self.isSelected == true and self.win_.defaultMaxNum <= self.win_.selectedNum then
		isItemChoose = false
	end

	local selectPos = self.callbackFunc(self.partner_, self.isSelected)

	if isItemChoose == true then
		if self.win_.name_ == "friend_boss_battle_formation_window" and self.isFriend == true and self.win_.flag == true then
			return
		end

		if self.win_.name_ == "activity_fairy_tale_formation_window" and selectPos and selectPos == -1 then
			return
		end

		self:setIsChoose(not self.isSelected)
	end
end

function FormationItem:setIsChoose(status)
	self.isSelected = status

	self.heroIcon_:setChoose(status)
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

local HeroIconWithHP = class("HeroIconWithHP", import("app.components.HeroIcon"))

function HeroIconWithHP:initUI()
	HeroIconWithHP.super.initUI(self)

	self.progress = self:getPartExample("progress")
end

local FormationItemWithHP = class("FormationItemWithHP", FormationItem)

function FormationItemWithHP:ctor(go, parent)
	FormationItemWithHP.super.ctor(self, go, parent)

	self.progressBar = nil
end

function FormationItemWithHP:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)
	self.parent_:updateFormationItemInfo(info, realIndex)

	if not self.heroIcon_ then
		self.heroIcon_ = HeroIconWithHP.new(self.uiRoot_, self.parent_.partnerRenderPanel)

		local function longPressCallback(callbackCopyIcon)
			self.parent_:longPressIcon(callbackCopyIcon)
		end

		self.heroIcon_:setLongPressListener(longPressCallback)
	end

	self.partner_ = info.partnerInfo
	self.callbackFunc = info.callbackFunc
	self.isBeenLock = false

	self:getHeroIcon():setLock(false)
	self:setIsChoose(info.isSelected)

	self.model_ = info.model
	self.partnerId_ = self.partner_.partnerID
	self.partner_.noClickSelected = true
	self.partner_.callback = handler(self, self.onClick)
	self.partner_.dragScrollView = self.parent_.partnerScrollView
	self.partner_.is_vowed = self.partner_.is_vowed
	self.partner_.noClick = false

	self.heroIcon_:setInfo(self.partner_)

	if self.model_ then
		self.hp = self.model_:getHp(info.partnerInfo.partnerID) / 100
	else
		self.hp = xyd.models.trial:getHp(info.partnerInfo.partnerID) / 100
	end

	self.heroIcon_.progress.value = self.hp

	if self.hp <= 0 then
		xyd.applyChildrenGrey(self.uiRoot_)
	else
		xyd.applyChildrenOrigin(self.uiRoot_)
	end

	local parentParams = self.parent_:getParams()

	if self.parent_:getBattleType() == xyd.BattleType.ACTIVITY_SPFARM and parentParams.spfarm_type == xyd.ActivitySpfarmOpenBattleFormationType.DEF then
		local gridId = parentParams.gridId
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)
		local id = activityData:getBuildBaseInfo(gridId).id
		local buildInfos = activityData:getMyBuildInfos()

		for i, buildInfo in pairs(buildInfos) do
			if buildInfo.id ~= id and buildInfo.partners and #buildInfo.partners > 0 then
				for k, buildPartnerInfo in pairs(buildInfo.partners) do
					if buildPartnerInfo.partner_id == self.partnerId_ then
						self:getHeroIcon():setLock(true)

						self.isBeenLock = true
					end
				end
			end
		end
	end
end

function FormationItemWithHP:onClick()
	local parentParams = self.parent_:getParams()

	if self.parent_:getBattleType() == xyd.BattleType.ACTIVITY_SPFARM and parentParams.spfarm_type == xyd.ActivitySpfarmOpenBattleFormationType.DEF and self.isBeenLock then
		xyd.alertTips(__("ACTIVITY_SPFARM_TEXT39"))

		return
	end

	if self.hp <= 0 then
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		xyd.showToast(__("TRIAL_TEXT10"))

		return
	end

	FormationItemWithHP.super.onClick(self)
end

local FormationItemShrineHurdle = class("FormationItemShrineHurdle", FormationItem)

function FormationItemShrineHurdle:ctor(go, parent)
	FormationItemShrineHurdle.super.ctor(self, go, parent)

	self.progressBar = nil
end

function FormationItemShrineHurdle:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)
	self.parent_:updateFormationItemInfo(info, realIndex)

	if not self.heroIcon_ then
		self.heroIcon_ = HeroIconWithHP.new(self.uiRoot_, self.parent_.partnerRenderPanel)

		local function longPressCallback(callbackCopyIcon)
			self.parent_:longPressIcon(callbackCopyIcon)
		end

		self.heroIcon_:setLongPressListener(longPressCallback)
	end

	self.partner_ = info.partnerInfo
	self.callbackFunc = info.callbackFunc

	self:setIsChoose(info.isSelected)

	self.partnerId_ = self.partner_.partnerID
	self.partner_.noClickSelected = true
	self.partner_.callback = handler(self, self.onClick)
	self.partner_.dragScrollView = self.parent_.partnerScrollView
	self.partner_.is_vowed = self.partner_.is_vowed
	self.partner_.noClick = false

	self.heroIcon_:setInfo(self.partner_)

	self.hp = info.partnerInfo.status.hp / 100
	self.heroIcon_.progress.value = self.hp

	if self.hp <= 0 then
		xyd.applyChildrenGrey(self.uiRoot_)
	else
		xyd.applyChildrenOrigin(self.uiRoot_)
	end
end

function FormationItemShrineHurdle:onClick()
	if self.hp <= 0 then
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		xyd.showToast(__("TRIAL_TEXT10"))

		return
	end

	FormationItemShrineHurdle.super.onClick(self)
end

local HeroIconWithStateImg = class("HeroIconWithStateImg", import("app.components.HeroIcon"))

function HeroIconWithStateImg:initUI()
	HeroIconWithStateImg.super.initUI(self)

	self.stateImg = self:getPartExample("stateImg")
end

local FormationItemWithStateIcon = class("FormationItemWithStateIcon", FormationItem)

function FormationItemWithStateIcon:ctor(go, parent)
	FormationItemWithStateIcon.super.ctor(self, go, parent)

	self.stateImg = nil
end

function FormationItemWithStateIcon:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)
	self.parent_:updateFormationItemInfo(info, realIndex)

	if not self.heroIcon_ then
		self.heroIcon_ = HeroIconWithStateImg.new(self.uiRoot_, self.parent_.partnerRenderPanel)

		local function longPressCallback(callbackCopyIcon)
			self.parent_:longPressIcon(callbackCopyIcon)
		end

		self.heroIcon_:setLongPressListener(longPressCallback)
	end

	self.partner_ = info.partnerInfo
	self.callbackFunc = info.callbackFunc

	self:setIsChoose(info.isSelected)

	self.partnerId_ = self.partner_.partnerID
	self.partner_.noClickSelected = true
	self.partner_.callback = handler(self, self.onClick)
	self.partner_.dragScrollView = self.parent_.partnerScrollView
	self.partner_.is_vowed = self.partner_.is_vowed
	self.partner_.noClick = false

	self.heroIcon_:setInfo(self.partner_)

	local state = xyd.models.activity:getArcticPartnerState(info.partnerInfo.partnerID)

	self.heroIcon_:updateStateImg(state)
	self.heroIcon_:setClickStateImg(function ()
		xyd.WindowManager.get():openWindow("arctic_partner_fine_detail_window", {
			partner_id = self.partnerId_
		})
	end)
end

function FormationItemWithStateIcon:onClick()
	FormationItemWithStateIcon.super.onClick(self)
end

local HeroIconWithProgressState = class("HeroIconWithProgressState", import("app.components.HeroIcon"))

function HeroIconWithProgressState:initUI()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ARCTIC_EXPEDITION)

	HeroIconWithProgressState.super.initUI(self)

	self.progressWithIcon = self:getPartExample("progressWithIcon")
	self.progressIcon = self:getPartExample("progressIcon")
end

local FormationItemWithProgressIcon = class("FormationItemWithProgressIcon", FormationItem)

function FormationItemWithProgressIcon:ctor(go, parent)
	FormationItemWithProgressIcon.super.ctor(self, go, parent)
end

function FormationItemWithProgressIcon:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)
	self.parent_:updateFormationItemInfo(info, realIndex)

	if not self.heroIcon_ then
		self.heroIcon_ = HeroIconWithStateImg.new(self.uiRoot_, self.parent_.partnerRenderPanel)

		local function longPressCallback(callbackCopyIcon)
			self.parent_:longPressIcon(callbackCopyIcon)
		end

		self.heroIcon_:setLongPressListener(longPressCallback)
	end

	self.partner_ = info.partnerInfo
	self.callbackFunc = info.callbackFunc

	self:setIsChoose(info.isSelected)

	self.partnerId_ = self.partner_.partnerID
	self.partner_.noClickSelected = true
	self.partner_.callback = handler(self, self.onClick)
	self.partner_.dragScrollView = self.parent_.partnerScrollView
	self.partner_.is_vowed = self.partner_.is_vowed
	self.partner_.noClick = false

	self.heroIcon_:setInfo(self.partner_)

	local state = xyd.models.activity:getArcticPartnerState(info.partnerInfo.partnerID)
	local stateValue = xyd.models.activity:getArcticPartnerValue(info.partnerInfo.partnerID)
	local maxValue = xyd.tables.miscTable:getVal("expedition_girls_labor", "value")

	self.heroIcon_:updateStateImg(state)
	self.heroIcon_:setClickStateImg(function ()
		xyd.WindowManager.get():openWindow("arctic_partner_fine_detail_window", {
			partner_id = self.partnerId_
		})
	end)

	self.heroIcon_.progressWithIcon.value = stateValue / tonumber(maxValue)
end

function FormationItemWithProgressIcon:onClick()
	FormationItemWithProgressIcon.super.onClick(self)
end

local BattleFormationWindow = class("BattleFormationWindow", import(".BaseWindow"))
BattleFormationWindow.FormationItem = FormationItem
local PartnerFilter = import("app.components.PartnerFilter")

function BattleFormationWindow:ctor(name, params)
	BattleFormationWindow.super.ctor(self, name, params)

	self.callback = nil
	self.skipBtnCallback = nil
	self.groupBuffTable = xyd.tables.groupBuffTable
	self.SlotModel = xyd.models.slot
	self.isShowGuide_ = false
	self.ifMove = false
	self.defaultMaxNum = 6
	self.selectedNum = 0
	self.copyIconList = {}
	self.nowPartnerList = {}
	self.buffDataList = {}
	self.isIconMoving = false
	self.needSound = false
	self.partners = {}
	self.pet = 0
	self.isSkip = params.isSkip or false
	self.isSkip = params.skipState or false
	self.sort_type_ = -1
	self.ifChooseEnemy = false
	self.mapsModel = xyd.models.map
	self.StageTable = xyd.tables.stageTable
	self.FortTable = xyd.tables.fortTable
	self.data = params
	self.ifChooseEnemy = params.choose_enemy or false
	self.mapType = params.mapType or xyd.MapType.CAMPAIGN
	self.battleType = params.battleType or xyd.BattleType.CAMPAIGN
	self.stageId = params.stageId
	self.cellId_ = params.cell_id
	self.spFarmType = params.spfarm_type
	self.pet = params.pet or 0
	self.currentGroup_ = params.current_group or 0
	self.gridId_ = params.gridId
	self.formationID = params.formation_id
	self.showFormationTeamTypeArr = {
		xyd.BattleType.CAMPAIGN,
		xyd.BattleType.TOWER,
		xyd.BattleType.FRIEND_TEAM_BOSS,
		xyd.BattleType.ACADEMY_ASSESSMENT,
		xyd.BattleType.TIME_CLOISTER_BATTLE,
		xyd.BattleType.ARENA,
		xyd.BattleType.GUILD_BOSS,
		xyd.BattleType.FRIEND,
		xyd.BattleType.TOWER_PRACTICE,
		xyd.BattleType.TIME_CLOISTER_EXTRA
	}

	if self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT then
		self.selectGroup_ = params.current_group or 0
	end

	if self.battleType == xyd.BattleType.ACTIVITY_SPFARM then
		self.defaultMaxNum = 3
	end

	if self.battleType ~= xyd.BattleType.ACADEMY_ASSESSMENT then
		local loadFlag = self:readStorageFormation()

		if self.mapType == xyd.MapType.CAMPAIGN then
			self.mapInfo = self.mapsModel:getMapInfo(xyd.MapType.CAMPAIGN)
			self.maxStage = self.mapInfo.max_stage

			if self.maxStage == 1 then
				local partnerList = self.SlotModel:getSortedPartners()
				local partners = partnerList[xyd.partnerSortType.PARTNER_ID]
				self.nowPartnerList = {
					partners[2],
					partners[1]
				}
			end
		end

		if self.battleType == xyd.BattleType.ARENADEF and params.formation then
			self.nowPartnerList = {}
			local formation = params.formation

			for i = 1, #formation do
				if formation[i] then
					self.nowPartnerList[tonumber(formation[i].pos)] = formation[i].partner_id
				end
			end
		end

		if (self.battleType == xyd.BattleType.ENTRANCE_TEST_DEF or self.battleType == xyd.BattleType.ENTRANCE_TEST) and params.formation and #params.formation > 0 then
			self.localPartnerList = {}
			self.nowPartnerList = {}
			local activityData = nil
			activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)

			for i in pairs(params.formation) do
				local thePartnerId = activityData:getPartnerIdByPartner(params.formation[i], self.nowPartnerList)

				if params.formation[i] and thePartnerId then
					self.nowPartnerList[tonumber(params.formation[i].pos)] = thePartnerId
				end
			end
		end

		if self.battleType == xyd.BattleType.ENTRANCE_TEST then
			local entranceTestSaveFormationTime = xyd.db.misc:getValue("entrance_test_save_formation_save_time" .. self.data.enemy_id)
			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)

			if entranceTestSaveFormationTime then
				entranceTestSaveFormationTime = tonumber(entranceTestSaveFormationTime)

				if entranceTestSaveFormationTime < activityData:startTime() or activityData:getEndTime() <= entranceTestSaveFormationTime then
					self.localPartnerList = {}
					self.nowPartnerList = {}
				end
			end
		end

		if self.battleType == xyd.BattleType.ARENA and not loadFlag then
			self.nowPartnerList = {}
			local formation = xyd.models.arena:getDefFormation()

			for i = 1, #formation do
				if formation[i] then
					self.nowPartnerList[tonumber(formation[i].pos)] = formation[i].partner_id
				end
			end
		end

		if self.battleType == xyd.BattleType.ARENA_TEAM_DEF and params.formation then
			self.nowPartnerList = {}
			local formation = params.formation

			for i = 1, #formation do
				if formation[i] then
					self.nowPartnerList[tonumber(formation[i].pos)] = formation[i].partner_id
				end
			end
		end

		if self.battleType == xyd.BattleType.GUILD_WAR_DEF then
			local info = xyd.models.guild.self_info
			local partners = xyd.models.guildWar:getDefFormation()

			if #partners > 0 then
				self.nowPartnerList = {}

				for i = 1, #partners do
					self.nowPartnerList[tonumber(partners[i].pos)] = partners[i].partner_id
				end
			end
		end

		if self.battleType == xyd.BattleType.ACTIVITY_SPFARM then
			if self.spFarmType == xyd.ActivitySpfarmOpenBattleFormationType.DEF then
				self.nowPartnerList = {}
				local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)
				local buildInfo = activityData:getBuildBaseInfo(self.params_.gridId)

				if buildInfo.partners and #buildInfo.partners > 0 then
					for i, partnerInfo in pairs(buildInfo.partners) do
						local index = nil

						if partnerInfo.pos == 1 then
							index = 1
						elseif partnerInfo.pos == 3 then
							index = 2
						elseif partnerInfo.pos == 5 then
							index = 3
						end

						self.nowPartnerList[index] = partnerInfo.partner_id
					end
				else
					self.nowPartnerList = {}
				end
			else
				self.nowPartnerList = {}
			end
		end

		if self.battleType == xyd.BattleType.QUICK_TEAM_SET then
			self.nowPartnerList = {}
			local formation = params.formation

			for pos, info in pairs(formation) do
				self.nowPartnerList[tonumber(pos)] = info:getPartnerID()
			end
		end
	else
		self:readStorageFormation()
	end

	if params and params.callback then
		self.callback = params.callback
	end

	xyd.SoundManager:get():playSound(2125)
end

function BattleFormationWindow:initWindow()
	BattleFormationWindow.super.initWindow(self)
	self:getUIComponent()
	self:updateForceNum()
	self:initLabel()
	self:initBuffList()
	self:updatePetRed()
	self:initSpeedModeNode()
	XYDCo.WaitForTime(0.1, function ()
		self:updateBuff()
	end, nil)
	self:register()
	self:initPartnerList()

	self.needSound = true
end

function BattleFormationWindow:getUIComponent()
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
	self.chooseGroupWidget = self.chooseGroup:GetComponent(typeof(UIWidget))
	local height = xyd.Global.getRealHeight()
	self.chooseGroupWidget.height = (height - 1280) / 279 * 169 + 464

	self.mainGroup.transform:Y(self.scale_num_ * -16 - 75)

	self.labelWinTitle = self.topGroup:ComponentByName("title_label", typeof(UILabel))
	self.closeBtn = self.topGroup:Find("close_btn").gameObject
	self.tipBtn = self.topGroup:Find("tip_btn").gameObject
	self.selectedGroup = self.topGroup:Find("selected_group")
	self.speedModeNode = self.topGroup:Find("speedModeNode")

	if self.speedModeNode then
		self.speedModeWords = self.speedModeNode:ComponentByName("speedModeWords", typeof(UILabel))
		self.speedNodeImg = self.speedModeNode:ComponentByName("speedModeNodeImg1", typeof(UISprite))
	end

	self.petBtn = self.selectedGroup:Find("pet_btn").gameObject
	self.labelPetBtn = self.selectedGroup:ComponentByName("pet_btn/button_label", typeof(UILabel))
	self.petRedImg = self.selectedGroup:ComponentByName("pet_btn/red_icon", typeof(UISprite))
	self.skipBtn = self.selectedGroup:Find("skip_btn").gameObject
	self.labelSkipBtn = self.selectedGroup:ComponentByName("skip_btn/button_label", typeof(UILabel))
	self.selectedSkipIcon = self.selectedGroup:ComponentByName("skip_btn/selected_icon", typeof(UISprite))

	self.selectedSkipIcon:SetActive(self.isSkip)

	self.battleBtn = self.selectedGroup:Find("battle_btn").gameObject
	self.entranceBtn = self.selectedGroup:Find("entrance_set_btn")

	if self.entranceBtn then
		self.entranceBtnLabel = self.entranceBtn:ComponentByName("button_label", typeof(UILabel))
	end

	self.labelBattleBtn = self.selectedGroup:ComponentByName("battle_btn/button_label", typeof(UILabel))
	self.quickSetBtn = self.selectedGroup:Find("quick_set_btn")
	self.buffGroup = self.selectedGroup:Find("buff_group")
	self.buffRoot = self.buffGroup:Find("buff_root").gameObject
	self.buffScrollView = self.buffGroup:ComponentByName("buff_scroller", typeof(UIScrollView))
	self.buffRenderPanel = self.buffGroup:ComponentByName("buff_scroller", typeof(UIPanel))
	self.buffContainer = self.buffScrollView:ComponentByName("buff_container", typeof(UIWrapContent))
	self.groupGuide = self.selectedGroup:Find("guide_group")
	self.labelForceNum = self.selectedGroup:ComponentByName("force_num_label", typeof(UILabel))
	self.backGroup = self.selectedGroup:Find("back_group")
	self.frontGroup = self.selectedGroup:Find("front_group")
	self.labelFront = self.frontGroup:ComponentByName("front_label", typeof(UILabel))
	self.labelBack = self.backGroup:ComponentByName("back_label", typeof(UILabel))

	if self.battleType == xyd.BattleType.ACTIVITY_SPFARM then
		self.container1 = self.frontGroup:Find("container_1")
		self.container2 = self.backGroup:Find("container_2")
		self.container3 = self.backGroup:Find("container_3")
		self.container4 = self.frontGroup:Find("container_4")
		self.container5 = self.backGroup:Find("container_5")
		self.container6 = self.backGroup:Find("container_6")
	else
		self.container1 = self.frontGroup:Find("container_1")
		self.container2 = self.frontGroup:Find("container_2")
		self.container3 = self.backGroup:Find("container_3")
		self.container4 = self.backGroup:Find("container_4")
		self.container5 = self.backGroup:Find("container_5")
		self.container6 = self.backGroup:Find("container_6")
	end

	self.fGroup = self.chooseGroup:Find("f_group")
	self.partnerScrollView = self.chooseGroup:ComponentByName("partner_scroller", typeof(UIScrollView))
	self.partnerRenderPanel = self.chooseGroup:ComponentByName("partner_scroller", typeof(UIPanel))
	self.partnerScroller_uiPanel = self.chooseGroup:ComponentByName("partner_scroller", typeof(UIPanel))
	self.partnerListWarpContent_ = self.chooseGroup:ComponentByName("partner_scroller/partner_container", typeof(MultiRowWrapContent))
	self.heroRoot = self.chooseGroup:Find("hero_root").gameObject

	if self.battleType == xyd.BattleType.TRIAL or self.battleType == xyd.BattleType.SHRINE_HURDLE or self.battleType == xyd.BattleType.ACTIVITY_SPFARM or self.battleType == xyd.BattleType.SHRINE_HURDLE_SET then
		self.progress1 = self.container1:ComponentByName("progress1", typeof(UIProgressBar))
		self.progress2 = self.container2:ComponentByName("progress2", typeof(UIProgressBar))
		self.progress3 = self.container3:ComponentByName("progress3", typeof(UIProgressBar))
		self.progress4 = self.container4:ComponentByName("progress4", typeof(UIProgressBar))
		self.progress5 = self.container5:ComponentByName("progress5", typeof(UIProgressBar))
		self.progress6 = self.container6:ComponentByName("progress6", typeof(UIProgressBar))

		for i = 1, 6 do
			self["container" .. i]:NodeByName("progressWithIcon" .. i).gameObject:SetActive(false)
		end
	elseif self.battleType == xyd.BattleType.ARCTIC_EXPEDITION then
		for i = 1, 6 do
			self["container" .. i]:NodeByName("progress" .. i).gameObject:SetActive(false)

			self["progressWithIcon" .. i] = self["container" .. i]:ComponentByName("progressWithIcon" .. i, typeof(UIProgressBar))
			self["progressIcon" .. i] = self["container" .. i]:ComponentByName("progressWithIcon" .. i .. "/stateImg", typeof(UISprite))

			UIEventListener.Get(self["progressIcon" .. i].gameObject).onClick = function ()
				if self.copyIconList[i] then
					local partnerID = self.copyIconList[i]:getPartnerInfo().partnerID

					if partnerID and tonumber(partnerID) > 0 then
						xyd.WindowManager.get():openWindow("arctic_partner_fine_detail_window", {
							partner_id = partnerID
						})
					end
				end
			end
		end

		self.filterLine = self.fGroup:NodeByName("lineImg").gameObject
		self.filterGroupArctic = self.fGroup:NodeByName("filterGroup7").gameObject
		self.filterGroupArcticChooseImg = self.fGroup:NodeByName("filterGroup7/group7_chosen").gameObject
	end

	local ifShowPetBtn = true

	if xyd.checkFunctionOpen(xyd.FunctionID.PET, true) or self.battleType == xyd.BattleType.HERO_CHALLENGE or self.battleType == xyd.BattleType.ENTRANCE_TEST_DEF or self.battleType == xyd.BattleType.ENTRANCE_TEST then
		self.petBtn:SetActive(true)
	else
		self.petBtn:SetActive(false)

		ifShowPetBtn = false
		self.skipBtn.transform.localPosition.x = self.petBtn.transform.localPosition.x
	end

	if self.battleType == xyd.BattleType.ENTRANCE_TEST_DEF or self.battleType == xyd.BattleType.ENTRANCE_TEST then
		self.entranceBtn.gameObject:SetActive(true)
		self.petBtn:SetActive(true)
		self.battleBtn.transform:X(120)
	end

	if self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT then
		if self.quickSetBtn then
			self.quickSetBtnRedIcon = self.quickSetBtn:Find("red_icon")

			self.quickSetBtn:SetActive(true)

			local abbr1 = xyd.db.misc:getValue("academy_assessment_battle_set_fail_end")
			local abbr2 = xyd.db.misc:getValue("academy_assessment_battle_set_ticket_end")

			if abbr1 and tonumber(abbr1) ~= 0 or abbr2 and tonumber(abbr2) ~= 0 then
				self.quickSetBtnRedIcon:SetActive(false)
			else
				self.quickSetBtnRedIcon:SetActive(true)
			end
		end

		self:initAcademyAssessmentGuide()
	end

	if self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS or self.battleType == xyd.BattleType.BEACH_ISLAND or self.battleType == xyd.BattleType.ENCOUNTER_STORY or self.battleType == xyd.BattleType.TIME_CLOISTER_PROBE or self.battleType == xyd.BattleType.ACTIVITY_SPFARM then
		self.petBtn:SetActive(false)

		ifShowPetBtn = false
	end

	if self.params_.showSkip then
		self.skipBtn:SetActive(true)

		local y = 137

		if self.battleType == xyd.BattleType.TRIAL or self.battleType == xyd.BattleType.SHRINE_HURDLE or self.battleType == xyd.BattleType.SHRINE_HURDLE_SET or self.battleType == xyd.BattleType.ACTIVITY_SPFARM then
			y = 170
		end

		if ifShowPetBtn then
			self.skipBtn:SetLocalPosition(63, y, 0)
		else
			self.skipBtn:SetLocalPosition(239, y, 0)
		end

		if self.battleType == xyd.BattleType.EXPLORE_ADVENTURE then
			self.skipBtn:SetLocalPosition(35, 148, 0)
		end
	else
		self.skipBtn:SetActive(false)
	end

	self:initQuickFormationTeam()
end

function BattleFormationWindow:register()
	BattleFormationWindow.super.register(self)

	UIEventListener.Get(self.skipBtn).onClick = handler(self, function ()
		self.isSkip = not self.isSkip

		self.selectedSkipIcon.gameObject:SetActive(self.isSkip)

		if self.params_.btnSkipCallback then
			self.params_.btnSkipCallback(self.isSkip)
		end
	end)
	UIEventListener.Get(self.petBtn).onClick = handler(self, function ()
		self:petChoose()
	end)
	UIEventListener.Get(self.battleBtn).onClick = handler(self, function ()
		self:onClickBattleBtn()
	end)

	if self.entranceBtn then
		UIEventListener.Get(self.entranceBtn.gameObject).onClick = function ()
			local partnerInfo = nil

			if self.nowTempList_[1] then
				partnerInfo = self.nowTempList_[1].partnerInfo
			end

			self:showPartnerDetail(partnerInfo)
		end
	end

	if self.quickSetBtn then
		UIEventListener.Get(self.quickSetBtn.gameObject).onClick = function ()
			xyd.WindowManager.get():openWindow("academy_assessment_battle_set_window", {
				closeCallBack = function ()
					if self.quickSetBtn then
						self.quickSetBtnRedIcon = self.quickSetBtn:Find("red_icon")
						local abbr1 = xyd.db.misc:getValue("academy_assessment_battle_set_fail_end")
						local abbr2 = xyd.db.misc:getValue("academy_assessment_battle_set_ticket_end")

						if abbr1 and tonumber(abbr1) ~= 0 or abbr2 and tonumber(abbr2) ~= 0 then
							self.quickSetBtnRedIcon:SetActive(false)
						else
							self.quickSetBtnRedIcon:SetActive(true)
						end
					end
				end
			})

			if self.academyAssessmentGuideObj then
				self.academyAssessmentGuideObj:SetActive(false)
				xyd.db.misc:setValue({
					value = "1",
					key = "academy_assessment_battle_set_guide"
				})
			end
		end
	end

	UIEventListener.Get(self.tipBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("battle_tips_window", {})
	end)

	if self.filterGroupArctic then
		UIEventListener.Get(self.filterGroupArctic).onClick = handler(self, self.onClickArcticSort)
	end

	self.eventProxy_:addEventListener(xyd.event.WARMUP_UPDATE_PARTNER_LIST, handler(self, self.updateCopyListRed))

	if self.battleFormationTeamBtn then
		UIEventListener.Get(self.battleFormationTeamBtn).onClick = handler(self, function ()
			self:onQuickFormationTeamBtnTouch(true)
		end)
		UIEventListener.Get(self.formationQuickTeamMask).onClick = handler(self, function ()
			self:onQuickFormationTeamBtnTouch()
		end)
		UIEventListener.Get(self.saveTeamBtn).onClick = handler(self, function ()
			self:onSaveTeamBtnTouch(true)
		end)
		UIEventListener.Get(self.saveTeamMask).onClick = handler(self, function ()
			self:onSaveTeamBtnTouch()
		end)
		UIEventListener.Get(self.formationPetBtn).onClick = handler(self, function ()
			self:petChoose()
		end)
		UIEventListener.Get(self.formationTeamQuitEditorBtn).onClick = handler(self, function ()
			self:onQuickFormationTeamQuit()
		end)

		self.eventProxy_:addEventListener(xyd.event.SET_QUICK_TEAM, handler(self, self.updateQuickRed))
	end
end

function BattleFormationWindow:initSpeedModeNode()
	if not self.speedModeNode then
		return
	end

	local isShowSpeedMode = self:checkShowSpeedMode()

	self.speedModeNode:SetActive(isShowSpeedMode)

	if not isShowSpeedMode then
		return
	end

	local text = xyd.tables.partnerChallengeTable:getSkillDesc(self.params_.battleID)

	if self.battleType == xyd.BattleType.HERO_CHALLENGE_SPEED then
		text = xyd.tables.partnerChallengeSpeedTable:getSkillDesc(self.params_.battleID)
	elseif self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS then
		text = xyd.tables.partnerChallengeChessTable:getSkillDesc(self.params_.battleID)
	elseif self.battleType == xyd.BattleType.SPORTS_PVP then
		xyd.setUISpriteAsync(self.speedNodeImg, nil, "sports_normal_icon", function ()
			self.speedNodeImg:MakePixelPerfect()
		end)
	else
		xyd.setUISpriteAsync(self.speedNodeImg, nil, "hero_challenge_nomal_icon", function ()
			self.speedNodeImg:MakePixelPerfect()
		end)
	end

	if self.battleType == xyd.BattleType.SPORTS_PVP then
		self.speedModeWords.fontSize = 24
		text = __("ACTIVITY_SPORTS_FIGHT_BUFF_SUM")

		UIEventListener.Get(self.speedModeNode.gameObject).onPress = function (go, isPress)
			if isPress then
				local win = xyd.WindowManager.get():getWindow("group_buff_detail_window")

				if win then
					xyd.WindowManager.get():closeWindow("group_buff_detail_window", function ()
						XYDCo.WaitForTime(1, function ()
							local params = {
								buffID = 16,
								type = xyd.GroupBuffIconType.SPORTS,
								contenty = 223
							}

							xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
						end, nil)
					end)
				else
					local params = {
						buffID = 16,
						type = xyd.GroupBuffIconType.SPORTS,
						contenty = 223
					}

					xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
				end
			else
				xyd.WindowManager.get():closeWindow("group_buff_detail_window")
			end
		end
	end

	self.speedModeWords.text = text
end

function BattleFormationWindow:checkShowSpeedMode()
	local res = false

	if self.battleType == xyd.BattleType.HERO_CHALLENGE_SPEED then
		res = true
	end

	if self.battleType == xyd.BattleType.HERO_CHALLENGE and next(xyd.tables.partnerChallengeTable:getSkillIds(self.params_.battleID)) then
		res = true
	end

	if self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS and next(xyd.tables.partnerChallengeChessTable:getSkillIds(self.params_.battleID)) then
		res = true
	end

	if self.battleType == xyd.BattleType.SPORTS_PVP then
		res = true
	end

	return res
end

function BattleFormationWindow:updatePetRed()
	local petModel = nil

	if self.battleType == xyd.BattleType.HERO_CHALLENGE or self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS then
		petModel = xyd.models.heroChallenge
	else
		petModel = xyd.models.petSlot
	end

	local hasPet = false
	local v = nil
	local pets = petModel:getPetIDs()
	local i = 1

	while i <= #pets do
		if petModel:getPetByID(pets[i]):getLevel() > 0 then
			hasPet = true
		end

		i = i + 1
	end

	v = self.pet == 0 and hasPet

	if self.petRedImg then
		self.petRedImg:SetActive(v)
	end

	if self.formationPetBtnRedPoint then
		self.formationPetBtnRedPoint:SetActive(v)

		if self.pet == 0 then
			self.formationPetBtnIcon:SetActive(false)
			self.formationPetBtnDefaultIcon:SetActive(true)
		else
			self.formationPetBtnIcon:SetActive(true)
			self.formationPetBtnDefaultIcon:SetActive(false)

			local petInfo = petModel:getPetByID(self.pet)
			local iconSource = xyd.tables.petTable:getAvatar(self.pet) .. tostring(petInfo:getGrade())

			xyd.setUISpriteAsync(self.formationPetBtnIcon, nil, iconSource)

			self.formationPetBtnLev.text = tostring(petInfo:getLevel())
		end
	end
end

function BattleFormationWindow:playOpenAnimation(callback)
	if callback then
		callback()
	end

	local addPos = 0

	print("self.battleType   ", self.battleType)

	if self.battleType == xyd.BattleType.ACTIVITY_SPFARM then
		addPos = 183
	end

	self.topGroup:SetLocalPosition(0, 810, 0)
	self.chooseGroup:SetLocalPosition(0, -858, 0)

	local y1 = 234

	if self.battleType == xyd.BattleType.EXPLORE_ADVENTURE then
		y1 = 260
	end

	self.top_tween = self:getSequence()

	self.top_tween:Append(self.topGroup.transform:DOLocalMoveY(y1, 0.5))
	self.top_tween:AppendCallback(function ()
		self:setWndComplete()

		if self.top_tween then
			self.top_tween:Kill(true)
		end
	end)

	self.down_tween = self:getSequence()

	self.down_tween:Append(self.chooseGroup.transform:DOLocalMoveY(-78 + addPos, 0.5))
	self.down_tween:AppendCallback(function ()
		if self.down_tween then
			self.down_tween:Kill(true)
		end
	end)
end

function BattleFormationWindow:playCloseAnimation(callback)
	if self.down_tween then
		self.down_tween:Kill(true)
	end

	if self.top_tween then
		self.top_tween:Kill(true)
	end

	BattleFormationWindow.super.playCloseAnimation(self, callback)
end

function BattleFormationWindow:getFormationData()
	local partnerParams = {}
	local formationIds = {}

	for i, _ in pairs(self.copyIconList) do
		local posId = i
		local partnerIcon = self.copyIconList[posId]

		if partnerIcon then
			local partnerInfo = partnerIcon:getPartnerInfo()
			local pInfo = {}

			if partnerInfo.partnerType ~= nil and partnerInfo.partnerType == "FriendSharedPartner" then
				pInfo = {
					player_id = tonumber(partnerInfo.partnerID),
					pos = tonumber(partnerInfo.posId)
				}
			elseif partnerInfo.partnerType ~= nil and partnerInfo.partnerType == "npcPartner" then
				pInfo = {
					partner_id = tonumber(partnerInfo.partnerID),
					pos = tonumber(partnerInfo.posId),
					is_npc = partnerInfo.is_npc
				}
			else
				pInfo = {
					partner_id = tonumber(partnerInfo.partnerID),
					pos = tonumber(partnerInfo.posId)
				}
			end

			table.insert(partnerParams, pInfo)

			if self.battleType == xyd.BattleType.HERO_CHALLENGE or self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS then
				formationIds[posId] = partnerInfo.tableID
			else
				formationIds[posId] = partnerInfo.partnerID
			end
		else
			formationIds[posId] = nil
		end
	end

	local formationData = {
		formationIds = formationIds,
		partnerParams = partnerParams
	}

	return formationData
end

function BattleFormationWindow:onClickBattleBtn()
	if self.battleType ~= xyd.BattleType.PARTNER_STATION then
		SoundManager:playSound(xyd.SoundID.START_BATTLE)
	end

	local formationData = self:getFormationData()
	local partnerParams = formationData.partnerParams
	local formationIds = formationData.formationIds

	if #partnerParams <= 0 and self.battleType ~= xyd.BattleType.ACTIVITY_SPFARM or #partnerParams <= 0 and self.battleType == xyd.BattleType.ACTIVITY_SPFARM and self.spFarmType == xyd.ActivitySpfarmOpenBattleFormationType.BATTLE then
		xyd.alert(xyd.AlertType.TIPS, __("AT_LEAST_ONE_HERO"))

		return
	end

	local formation = {
		pet_id = self.pet,
		partners = formationIds
	}

	self:saveLocalformation(formation)

	local battleFunc = {
		[xyd.BattleType.CAMPAIGN] = self.campaignBattle,
		[xyd.BattleType.TOWER] = self.towerBattle,
		[xyd.BattleType.TOWER_PRACTICE] = self.towerPractice,
		[xyd.BattleType.DAILY_QUIZ] = self.dailyQuizBattle,
		[xyd.BattleType.ARENA] = self.arenaBattle,
		[xyd.BattleType.ARENADEF] = self.arenaBattleDef,
		[xyd.BattleType.ARENA_TEAM_DEF] = self.arenaTeamBattleDef,
		[xyd.BattleType.FRIEND_BOSS] = self.friendBossBattle2,
		[xyd.BattleType.FRIEND] = self.friendBattle,
		[xyd.BattleType.TRIAL] = self.newTrialBattle,
		[xyd.BattleType.GUILD_BOSS] = self.guildBossBattle,
		[xyd.BattleType.WORLD_BOSS] = self.worldBossBattle,
		[xyd.BattleType.GUILD_WAR_DEF] = self.GuildWarBattleDef,
		[xyd.BattleType.HERO_CHALLENGE] = self.heroChallengeBattle,
		[xyd.BattleType.HERO_CHALLENGE_CHESS] = self.heroChallengeChessBattle,
		[xyd.BattleType.HERO_CHALLENGE_SPEED] = self.heroChallengeSpeedBattle,
		[xyd.BattleType.FRIEND_TEAM_BOSS] = self.friendTeamBossBattle,
		[xyd.BattleType.ACADEMY_ASSESSMENT] = self.academyAssessmentBattle,
		[xyd.BattleType.LIBRARY_WATCHER_STAGE_FIGHT2] = self.libraryWatcher2Battle,
		[xyd.BattleType.SPORTS_PVP_DEF] = self.sportsBattleDef,
		[xyd.BattleType.SPORTS_PVP] = self.sportsBattle,
		[xyd.BattleType.PARTNER_STATION] = self.stationBattle,
		[xyd.BattleType.ENTRANCE_TEST_DEF] = self.entranceTestBattleDef,
		[xyd.BattleType.ENTRANCE_TEST] = self.entranceTestBattle,
		[xyd.BattleType.FAIRY_TALE] = self.enterFairyTaleBattle,
		[xyd.BattleType.ICE_SECRET_BOSS] = self.iceSecretBossBattle,
		[xyd.BattleType.LIMIT_CALL_BOSS] = self.limitCallBossBattle,
		[xyd.BattleType.EXPLORE_ADVENTURE] = self.exploreAdventureBattle,
		[xyd.BattleType.GUILD_COMPETITION] = self.guildCompetitionBattle,
		[xyd.BattleType.BEACH_ISLAND] = self.beachIslandBattle,
		[xyd.BattleType.ENCOUNTER_STORY] = self.encounterStoryBattle,
		[xyd.BattleType.TIME_CLOISTER_PROBE] = self.timeCloisterProbe,
		[xyd.BattleType.TIME_CLOISTER_BATTLE] = self.timeCloisterBattle,
		[xyd.BattleType.ARCTIC_EXPEDITION] = self.arcticExpeditionBattle,
		[xyd.BattleType.TIME_CLOISTER_EXTRA] = self.timeCloisterEncounter,
		[xyd.BattleType.SHRINE_HURDLE] = self.shrineHurdleBattle,
		[xyd.BattleType.GAME_ASSISTANT_ARENA] = self.gameAssistantArenaBattle,
		[xyd.BattleType.GAME_ASSISTANT_GUILD] = self.gameAssistantGuildBattle,
		[xyd.BattleType.ACTIVITY_SPFARM] = self.spfarmFight,
		[xyd.BattleType.QUICK_TEAM_SET] = self.quickSetTeam,
		[xyd.BattleType.GALAXY_TRIP_BATTLE] = self.galaxyTripBattle,
		[xyd.BattleType.GALAXY_TRIP_SPECIAL_BOSS_BATTLE] = self.galaxyTripSpecialBossBattle,
		[xyd.BattleType.SHRINE_HURDLE_SET] = self.shrineHurdleSetTeam
	}

	if battleFunc[self.battleType] then
		battleFunc[self.battleType](self, partnerParams)
	end

	if self.battleType ~= xyd.BattleType.ENTRANCE_TEST and self.battleType ~= xyd.BattleType.ENTRANCE_TEST_DEF then
		xyd.closeWindow("battle_formation_window")
	end
end

function BattleFormationWindow:GuildWarBattleDef(partnerParams)
	if self.chooseQuickTeam_ and self.chooseQuickTeam_ > 0 then
		local partner_list = xyd.models.quickFormation:getPartnerList(self.chooseQuickTeam_)
		local canFight = false

		for i = 1, 6 do
			if partner_list[i] then
				canFight = true
			end
		end

		if not canFight then
			xyd.alertTips(__("QUICK_FORMATION_TEXT09"))

			return
		end
	end

	if #xyd.models.guild.self_info.partners > 0 then
		xyd.models.guildWar:setDefFormation(partnerParams, self.pet, self.chooseQuickTeam_)
	else
		xyd.alert(xyd.AlertType.YES_NO, __("GUILD_WAR_MY_TEAM_TIPS"), function (flag)
			if flag then
				xyd.models.guildWar:setDefFormation(partnerParams, self.pet, self.chooseQuickTeam_)
			end
		end)
	end
end

function BattleFormationWindow:heroChallengeBattle(partnerParams)
	xyd.models.heroChallenge:reqFight(partnerParams, self.pet, self.params_.battleID)
	xyd.closeWindow("hero_challenge_fight_window")
end

function BattleFormationWindow:arenaBattleDef(partnerParams)
	local msg = messages_pb.set_partners_req()
	msg.pet_id = self.pet

	if self.chooseQuickTeam_ and self.chooseQuickTeam_ > 0 then
		local partner_list = xyd.models.quickFormation:getPartnerList(self.chooseQuickTeam_)
		local canFight = false

		for i = 1, 6 do
			if partner_list[i] then
				canFight = true
			end
		end

		if not canFight then
			xyd.alertTips(__("QUICK_FORMATION_TEXT09"))

			return
		end

		msg.formation_id = self.chooseQuickTeam_
	else
		xyd.getFightPartnerMsg(msg.partners, partnerParams)
	end

	xyd.Backend.get():request(xyd.mid.SET_PARTNERS, msg)

	local rank = xyd.models.arena:getRank()

	if rank <= xyd.TOP_ARENA_NUM then
		XYDCo.WaitForTime(0.1, xyd.models.arena.reqRankList, xyd.getTimeKey())
	end

	function self.callback()
		local win = xyd.WindowManager.get():getWindow("arena_window")

		if win then
			win:setMask(false)
		end
	end
end

function BattleFormationWindow:arenaTeamBattleDef(partnerParams)
	local msg = messages_pb.set_arena_team_partners_req()
	msg.pet_id = self.pet

	if self.chooseQuickTeam_ and self.chooseQuickTeam_ > 0 then
		local partner_list = xyd.models.quickFormation:getPartnerList(self.chooseQuickTeam_)
		local canFight = false

		for i = 1, 6 do
			if partner_list[i] then
				canFight = true
			end
		end

		if not canFight then
			xyd.alertTips(__("QUICK_FORMATION_TEXT09"))

			return
		end

		msg.formation_id = self.chooseQuickTeam_
	else
		xyd.getFightPartnerMsg(msg.partners, partnerParams)
	end

	xyd.Backend.get():request(xyd.mid.SET_ARENA_TEAM_PARTNERS, msg)

	local rank = xyd.models.arenaTeam:getRank()

	if rank <= xyd.TOP_ARENA_NUM and rank > 0 then
		self:setTimeout(xyd.models.arenaTeam.reqRankList, self, 100)
	end

	function self.callback()
		local win = xyd.WindowManager.get():getWindow("arena_team_window")

		if not win then
			return
		end

		win:setMask(false)
	end
end

function BattleFormationWindow:heroChallengeChessBattle(partnerParams)
	xyd.models.heroChallenge:reqFightChess(partnerParams, self.pet, self.params_.battleID)
	xyd.closeWindow("hero_challenge_fight_window")
end

function BattleFormationWindow:arenaBattle(partnerParams)
	local noFight = false

	if xyd.models.arena:getIsSettlementing() then
		xyd.alertTips(__("ARENA_NO_FIGHT"))

		noFight = true
	end

	if xyd.models.arena:getIsOld() ~= nil then
		local newArenaStartTimeLeft = xyd.models.arena:getStartTime() + xyd.models.arena:getNewSeasonOpenTime() - xyd.getServerTime()

		if newArenaStartTimeLeft > 0 and newArenaStartTimeLeft < xyd.models.arena:getNewSeasonOpenTime() then
			xyd.alertTips(__("ARENA_NO_FIGHT"))

			noFight = true
		end
	end

	if noFight then
		local arenaChoosePlayerWd = xyd.WindowManager.get():getWindow("arena_choose_player_window")

		if arenaChoosePlayerWd then
			xyd.WindowManager.get():closeWindow("arena_choose_player_window")
		end

		return
	end

	local msg = messages_pb.arena_fight_req()
	msg.pet_id = self.pet
	msg.enemy_id = self.params_.enemy_id

	if self.chooseQuickTeam_ and self.chooseQuickTeam_ > 0 then
		local partner_list = xyd.models.quickFormation:getPartnerList(self.chooseQuickTeam_)
		local canFight = false

		for i = 1, 6 do
			if partner_list[i] then
				canFight = true
			end
		end

		if not canFight then
			xyd.alertTips(__("QUICK_FORMATION_TEXT09"))

			return
		end

		msg.formation_id = self.chooseQuickTeam_
	else
		xyd.getFightPartnerMsg(msg.partners, partnerParams)
	end

	if self.params_.is_revenge then
		msg.is_revenge = 1
	else
		msg.is_revenge = 0
	end

	local defomation = xyd.models.arena:getDefFormation()
	local needCheck = not xyd.models.arena.hasCheck

	if needCheck then
		local power = 0

		for i = 1, #defomation do
			power = defomation[i].power + power
		end

		local numSave = xyd.tables.miscTable:getVal("defense_team_save")

		if self.power and tonumber(numSave) < self.power / power then
			xyd.models.arena.needCheck = true
		end

		xyd.models.arena.hasCheck = true
	end

	xyd.Backend.get():request(xyd.mid.ARENA_FIGHT, msg)

	local freeTime = xyd.models.arena:getFreeTimes()

	if freeTime > 0 then
		xyd.models.arena:setFreeTimes(freeTime - 1)
	end
end

local function addFightPartnerMsg(protoMsg, partnerParams)
	for _, partnerInfo in pairs(partnerParams) do
		local fightPartnerMsg = messages_pb.fight_partner()
		fightPartnerMsg.partner_id = partnerInfo.partner_id
		fightPartnerMsg.pos = partnerInfo.pos

		table.insert(protoMsg.partners, fightPartnerMsg)
	end
end

function BattleFormationWindow:campaignBattle(partnerParams)
	local msg = messages_pb.map_fight_req()
	msg.map_type = self.mapType
	msg.stage_id = self.stageId
	msg.pet_id = self.pet

	if self.chooseQuickTeam_ and self.chooseQuickTeam_ > 0 then
		local partner_list = xyd.models.quickFormation:getPartnerList(self.chooseQuickTeam_)
		local canFight = false

		for i = 1, 6 do
			if partner_list[i] then
				canFight = true
			end
		end

		if not canFight then
			xyd.alertTips(__("QUICK_FORMATION_TEXT09"))

			return
		end

		msg.formation_id = self.chooseQuickTeam_
	else
		addFightPartnerMsg(msg, partnerParams)
	end

	xyd.Backend.get():request(xyd.mid.MAP_FIGHT, msg)
	xyd.closeWindow("campaign_window", nil, , true)
end

function BattleFormationWindow:towerBattle(partnerParams)
	local msg = messages_pb.tower_fight_req()
	msg.pet_id = self.pet

	if self.chooseQuickTeam_ and self.chooseQuickTeam_ > 0 then
		local partner_list = xyd.models.quickFormation:getPartnerList(self.chooseQuickTeam_)
		local canFight = false

		for i = 1, 6 do
			if partner_list[i] then
				canFight = true
			end
		end

		if not canFight then
			xyd.alertTips(__("QUICK_FORMATION_TEXT09"))

			return
		end

		msg.formation_id = self.chooseQuickTeam_

		xyd.db.misc:setValue({
			key = "tower_battle_formation",
			value = self.chooseQuickTeam_
		})
	else
		xyd.db.misc:setValue({
			value = 0,
			key = "tower_battle_formation"
		})
		addFightPartnerMsg(msg, partnerParams)
	end

	xyd.Backend.get():request(xyd.mid.TOWER_FIGHT, msg)
end

function BattleFormationWindow:towerPractice(partnerParams)
	local msg = messages_pb.tower_practice_req()
	msg.pet_id = self.pet
	msg.stage_id = self.stageId

	if self.chooseQuickTeam_ and self.chooseQuickTeam_ > 0 then
		local partner_list = xyd.models.quickFormation:getPartnerList(self.chooseQuickTeam_)
		local canFight = false

		for i = 1, 6 do
			if partner_list[i] then
				canFight = true
			end
		end

		if not canFight then
			xyd.alertTips(__("QUICK_FORMATION_TEXT09"))

			return
		end

		msg.formation_id = self.chooseQuickTeam_
	else
		addFightPartnerMsg(msg, partnerParams)
	end

	xyd.Backend.get():request(xyd.mid.TOWER_PRACTICE, msg)
	xyd.closeWindow("tower_campaign_detail_window", nil, true)
end

function BattleFormationWindow:academyAssessmentBattle(partnerParams)
	if self.chooseQuickTeam_ and self.chooseQuickTeam_ > 0 then
		local partner_list = xyd.models.quickFormation:getPartnerList(self.chooseQuickTeam_)

		for pos, partnerInfo in pairs(partner_list) do
			local group = partnerInfo:getGroup()

			if group ~= self.currentGroup_ then
				xyd.alertTips(__("QUICK_FORMATION_TEXT10"))

				return
			end
		end

		local canFight = false

		for i = 1, 6 do
			if partner_list[i] then
				canFight = true
			end
		end

		if not canFight then
			xyd.alertTips(__("QUICK_FORMATION_TEXT09"))

			return
		end

		xyd.db.misc:setValue({
			key = "academy_battle_formation",
			value = self.chooseQuickTeam_
		})
	else
		xyd.db.misc:setValue({
			value = 0,
			key = "academy_battle_formation"
		})
	end

	xyd.models.academyAssessment:reqFight(self.stageId, partnerParams, self.pet, self.chooseQuickTeam_)
end

function BattleFormationWindow:libraryWatcher2Battle(partnerParams)
	local params = {
		stage_id = self.params_.stage_id,
		partners = partnerParams,
		pet_id = self.pet
	}

	xyd.activity:reqAwardWithParams(xyd.ActivityID.LIBRARY_WATCHER2, require("cjson").encode(params))
end

function BattleFormationWindow:sportsBattleDef(partnerParams)
	local params = messages_pb:sports_set_partners_req()

	if type(self.pet) == "number" and self.pet ~= 0 then
		params.activity_id = xyd.ActivityID.SPORTS
		params.pet_id = self.pet

		addFightPartnerMsg(params, partnerParams)
	else
		params.activity_id = xyd.ActivityID.SPORTS

		addFightPartnerMsg(params, partnerParams)
	end

	xyd.Backend.get():request(xyd.mid.SPORTS_SET_PARTNERS, params)

	self.callback = nil
end

function BattleFormationWindow:sportsBattle(partnerParams)
	local params = messages_pb:sports_fight_req()
	params.activity_id = xyd.ActivityID.SPORTS
	params.pet_id = self.pet
	params.enemy_id = self.params_.enemy_id

	addFightPartnerMsg(params, partnerParams)
	xyd.Backend.get():request(xyd.mid.SPORTS_FIGHT, params)
end

function BattleFormationWindow:entranceTestBattleDef(partnerParams)
	local function setFunction()
		local msg = messages_pb:warmup_set_partner_req()
		msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
		msg.pet_id = self.pet

		for i in pairs(partnerParams) do
			local msgData = messages_pb:team_formation()
			msgData.partner_id = partnerParams[i].partner_id
			msgData.pos = partnerParams[i].pos

			table.insert(msg.partners, msgData)
		end

		xyd.Backend.get():request(xyd.mid.WARMUP_SET_PARTNER, msg)

		self.callback = nil

		xyd.closeWindow("battle_formation_window")
	end

	if not self:checkCopyReady() then
		local timeStamp = xyd.db.misc:getValue("entrance_test_time_stamp")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				tipsTextY = 60,
				type = "entrance_test",
				tipsHeight = 100,
				callback = function ()
					setFunction()
				end,
				closeCallback = function ()
					self:showEntranceFinger()
				end
			})
		else
			setFunction()
		end
	else
		setFunction()
	end
end

function BattleFormationWindow:hideEntranceFinger()
	if self.entranceEffect_ then
		self.entranceEffect_:SetActive(false)
	end
end

function BattleFormationWindow:showEntranceFinger()
	local targetIcon = nil

	if xyd.BattleType.ENTRANCE_TEST == self.battleType or xyd.BattleType.ENTRANCE_TEST_DEF == self.battleType then
		for i = 1, 6 do
			local heroIcon = self.copyIconList[i]

			if heroIcon and not heroIcon:checkEntranceTestFinish() then
				targetIcon = heroIcon

				break
			end
		end
	end

	if targetIcon then
		if self.fingerEffect_ then
			self.fingerEffect_:destroy()
			NGUITools.DestroyChildren(targetIcon:getGEffectObj().transform)
			self:waitForFrame(1, function ()
				self.fingerEffect_ = xyd.Spine.new(targetIcon:getGEffectObj())

				self.fingerEffect_:setInfo("fx_ui_changan", function ()
					self.fingerEffect_:SetLocalPosition(30, -30, 0)
					self.fingerEffect_:play("texiao1", 0)
				end)
			end)
		else
			self.fingerEffect_ = xyd.Spine.new(targetIcon:getGEffectObj())

			self.fingerEffect_:setInfo("fx_ui_changan", function ()
				self.fingerEffect_:SetLocalPosition(30, -30, 0)
				self.fingerEffect_:play("texiao1", 0)
			end)
		end
	end
end

function BattleFormationWindow:checkCopyReady()
	if xyd.BattleType.ENTRANCE_TEST == self.battleType or xyd.BattleType.ENTRANCE_TEST_DEF == self.battleType then
		for _, heroIcon in pairs(self.copyIconList) do
			if not heroIcon:checkEntranceTestFinish() then
				return false
			end
		end
	end

	return true
end

function BattleFormationWindow:entranceTestBattle(partnerParams)
	local function battlefunc()
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)

		if self.data.entrance_is_fake and self.data.entrance_is_fake == 1 then
			-- Nothing
		else
			local times = activityData:getFreeTimes()

			if times <= 0 then
				xyd.showToast(__("ENTRANCE_TEST_FIGHT_TIP"))

				return
			end
		end

		local params = {
			boss_id = self.data.enemy_id,
			partners = partnerParams,
			pet_id = self.pet
		}

		if self.data.entrance_is_fake and self.data.entrance_is_fake == 1 then
			params.is_fake = 1

			activityData:fakeToFight()
		end

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ENTRANCE_TEST, require("cjson").encode(params))
		xyd.closeWindow("battle_formation_window")
		xyd.closeWindow("activity_entrance_test_enemy_window")
		xyd.closeWindow("activity_entrance_test_record_window")
	end

	if not self:checkCopyReady() then
		local timeStamp = xyd.db.misc:getValue("entrance_test_time_stamp")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				tipsTextY = 60,
				type = "entrance_test",
				tipsHeight = 100,
				callback = function ()
					battlefunc()
				end,
				closeCallback = function ()
					self:showEntranceFinger()
				end
			})
		else
			battlefunc()
		end
	else
		battlefunc()
	end
end

function BattleFormationWindow:beachIslandBattle(partnerParams)
	local msg = messages_pb.activity_beach_island_battle_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_BEACH_SUMMER
	msg.stage = self.stageId

	addFightPartnerMsg(msg, partnerParams)
	xyd.Backend.get():request(xyd.mid.ACTIVITY_BEACH_ISLAND_BATTLE, msg)
	xyd.WindowManager.get():closeWindow("activity_beach_island_fight_window")
end

function BattleFormationWindow:encounterStoryBattle(partnerParams)
	local msg = messages_pb.encounter_fight_req()
	msg.activity_id = xyd.ActivityID.ENCONTER_STORY
	msg.stage = self.stageId

	addFightPartnerMsg(msg, partnerParams)
	xyd.Backend.get():request(xyd.mid.ENCOUNTER_FIGHT, msg)
end

function BattleFormationWindow:stationBattle(partnerParams)
end

function BattleFormationWindow:dailyQuizBattle(partnerParams)
	xyd.models.dailyQuiz:reqFight(self.params_.quizID, partnerParams, self.pet)
end

function BattleFormationWindow:friendBossBattle(partnerParams)
	if self.params_.is_weep then
		xyd.models.friend:sweepBoss(partnerParams, self.params_.friend_id, self.params_.sweep_num, self.pet)
	else
		xyd.models.friend:fightBoss(self.params_.friend_id, partnerParams, self.pet)
	end

	xyd.closeWindow("friend_boss_window")
end

function BattleFormationWindow:friendBossBattle2(partnerParams)
	local friendBossBattleFormationWin = xyd.WindowManager.get():getWindow("friend_boss_battle_formation_window")

	if friendBossBattleFormationWin ~= nil then
		local params = {
			partners = partnerParams
		}

		friendBossBattleFormationWin:fightBoss(params)
	end
end

function BattleFormationWindow:friendBattle(partnerParams)
	if self.chooseQuickTeam_ and self.chooseQuickTeam_ > 0 then
		local partner_list = xyd.models.quickFormation:getPartnerList(self.chooseQuickTeam_)
		local canFight = false

		for i = 1, 6 do
			if partner_list[i] then
				canFight = true
			end
		end

		if not canFight then
			xyd.alertTips(__("QUICK_FORMATION_TEXT09"))

			return
		end
	else
		xyd.models.friend:clearQuickTeamInfo()
	end

	xyd.models.friend:fightFriend(self.params_.friend_id, partnerParams, self.pet, self.chooseQuickTeam_)
end

function BattleFormationWindow:newTrialBattle(partnerParams)
	local msg = messages_pb.new_trial_fight_req()
	msg.pet_id = self.pet
	msg.stage_id = tonumber(self.stageId)

	for _, info in ipairs(partnerParams) do
		local fightPatner = messages_pb.fight_partner()
		fightPatner.partner_id = info.partner_id
		fightPatner.pos = info.pos

		table.insert(msg.partners, fightPatner)
	end

	xyd.Backend.get():request(xyd.mid.NEW_TRIAL_FIGHT, msg)
	xyd.closeWindow("battle_formation_trial_window")
	xyd.WindowManager.get():closeWindow("trial_campaign_window")
	xyd.WindowManager.get():closeWindow("new_trial_boss_info_window")
	xyd.WindowManager.get():closeWindow("new_trial_boss_info_window2")
end

function BattleFormationWindow:quickSetTeam(partnerParams)
	local win = xyd.WindowManager.get():getWindow("quick_formation_window")

	if win then
		win:setPartnerList(partnerParams, self.pet)
	end
end

function BattleFormationWindow:spfarmFight(partnerParams)
	if self.spFarmType == xyd.ActivitySpfarmOpenBattleFormationType.DEF then
		local partners = {}

		for _, info in ipairs(partnerParams) do
			local fightPatner = {
				partner_id = info.partner_id,
				pos = info.pos * 2 - 1
			}

			table.insert(partners, fightPatner)
		end

		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
			type = xyd.ActivitySpfarmType.SET_DEF,
			id = activityData:getBuildBaseInfo(self.params_.gridId).id,
			partners = partners
		}))
		self:close()
	else
		local partners = {}
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)
		local partnerUseList = activityData:getPartnerUse()

		for _, info in ipairs(partnerParams) do
			local fightPatner = {}
			local index = 0

			for idx, partnerData in ipairs(partnerUseList) do
				if info.partner_id == partnerData.partner_id or info.partner_id == partnerData.partnerID then
					index = idx

					break
				end
			end

			if index > 0 then
				fightPatner.partner_id = index
				fightPatner.pos = info.pos * 2 - 1

				table.insert(partners, fightPatner)
			end
		end

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
			type = xyd.ActivitySpfarmType.FIGHT,
			pos = self.params_.gridId,
			partners = partners
		}))
		self:close()
	end
end

function BattleFormationWindow:shrineHurdleBattle(partnerParams)
	local guideIndex = xyd.models.shrineHurdleModel:checkInGuide()

	if guideIndex and guideIndex == 4 then
		xyd.models.shrineHurdleModel:setFlag(nil, 4)
		xyd.models.shrineHurdleModel:fakeBattle(1, partnerParams, self.pet)

		self.callback = nil
	elseif guideIndex and guideIndex == 9 then
		xyd.models.shrineHurdleModel:setFlag(nil, 9)
		xyd.models.shrineHurdleModel:fakeBattle(2, partnerParams, self.pet)

		self.callback = nil
	else
		xyd.models.shrineHurdleModel:challengeFight(partnerParams, self.pet)
	end

	xyd.closeWindow("battle_formation_trial_window")
end

function BattleFormationWindow:shrineHurdleSetTeam(partnerParams)
	local win = xyd.WindowManager.get():getWindow("shrine_hurdle_auto_setting_window")

	if win then
		win:setPartnerList(partnerParams, self.pet)
		win:updatePartnerList()
	end

	xyd.closeWindow("battle_formation_trial_window")
end

function BattleFormationWindow:gameAssistantArenaBattle(partnerParams)
	local partners = xyd.models.arena:getDefFormation()

	if #partners <= 0 then
		local msg = messages_pb.set_partners_req()
		msg.pet_id = self.pet

		xyd.getFightPartnerMsg(msg.partners, partnerParams)
		xyd.Backend.get():request(xyd.mid.SET_PARTNERS, msg)

		local rank = xyd.models.arena:getRank()

		if rank <= xyd.TOP_ARENA_NUM then
			XYDCo.WaitForTime(0.1, xyd.models.arena.reqRankList, xyd.getTimeKey())
		end
	end

	local presetData = xyd.models.gameAssistant.presetData
	presetData.arenaBattleFormationInfo = {
		pet_id = self.pet,
		partners = partnerParams,
		power = self.power
	}

	xyd.closeWindow("battle_formation_window")
end

function BattleFormationWindow:gameAssistantGuildBattle(partnerParams)
	if os.date("!*t", xyd.getServerTime()).wday == 6 and os.date("!*t", xyd.getServerTime()).hour == 0 and self.params_.bossId == xyd.GUILD_FINAL_BOSS_ID then
		xyd.showToast(__("GUILD_TEXT68"))
		xyd.closeWindow("guild_final_boss_window")
		xyd.closeWindow(self.name_)
	end

	local presetData = xyd.models.gameAssistant.presetData
	presetData.guildBattleFormationInfo = {
		pet_id = self.pet,
		partners = partnerParams,
		power = self.power
	}

	xyd.closeWindow("battle_formation_window")
end

function BattleFormationWindow:arcticExpeditionBattle(partnerParams)
	xyd.models.activity:getActivity(xyd.ActivityID.ARCTIC_EXPEDITION):arcticExpeditionBattle(partnerParams, self.pet, self.cellId_)
	xyd.closeWindow("battle_formation_trial_window")
end

function BattleFormationWindow:enterFairyTaleBattle(partnerParams)
	local msg = messages_pb.fairy_challenge_req()
	msg.activity_id = xyd.ActivityID.FAIRY_TALE
	msg.cell_id = self.cellId_
	local params = {}
	local info = {}

	for _, info in ipairs(partnerParams) do
		local fightPatner = {
			partner_id = info.partner_id,
			pos = info.pos,
			is_npc = info.is_npc
		}

		table.insert(params, fightPatner)
	end

	info.partners = params
	info.pet_id = self.pet
	msg.params = json.encode(info)

	xyd.Backend.get():request(xyd.mid.FAIRY_CHALLENGE, msg)
	xyd.WindowManager.get():closeWindow("activity_fairy_tale_formation_window")
end

function BattleFormationWindow:iceSecretBossBattle(partnerParams)
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ICE_SECRET_BOSS_CHALLENGE
	local params = {}
	local info = {}

	for _, info in ipairs(partnerParams) do
		local fightPatner = {
			partner_id = info.partner_id,
			pos = info.pos
		}

		table.insert(params, fightPatner)
	end

	info.partners = params
	info.pet_id = self.pet
	msg.params = json.encode(info)

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function BattleFormationWindow:limitCallBossBattle(partnerParams)
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.LIMIT_CALL_BOSS
	local params = {}
	local info = {}

	for _, info in ipairs(partnerParams) do
		local fightPatner = {
			partner_id = info.partner_id,
			pos = info.pos
		}

		table.insert(params, fightPatner)
	end

	info.partners = params
	info.pet_id = self.pet
	msg.params = json.encode(info)

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function BattleFormationWindow:exploreAdventureBattle(partnerParams)
	if not self.params_.isSetting then
		xyd.models.exploreModel:reqAdventureCost({
			pet_id = self.pet,
			partners = partnerParams
		})
	end

	xyd.closeWindow("adventure_battle_formation_window")
end

function BattleFormationWindow:timeCloisterProbe(partnerParams)
	local partners = {
		0,
		0,
		0,
		0,
		0,
		0
	}

	for _, item in ipairs(partnerParams) do
		partners[item.pos] = item.partner_id
	end

	if #partners == 0 then
		xyd.showToast("zhi shao xuan yi ge")
	else
		xyd.models.timeCloisterModel:reqStartHang(self.params_.cloister, partners)

		local timeCloisterMainWindow = xyd.WindowManager.get():getWindow("time_cloister_main_window")

		if timeCloisterMainWindow then
			timeCloisterMainWindow:openProbeWindow(self.params_.cloister)
		end
	end
end

function BattleFormationWindow:timeCloisterBattle(partnerParams)
	local timeCloister = xyd.models.timeCloisterModel

	if self.chooseQuickTeam_ and self.chooseQuickTeam_ > 0 then
		local partner_list = xyd.models.quickFormation:getPartnerList(self.chooseQuickTeam_)
		local canFight = false

		for i = 1, 6 do
			if partner_list[i] then
				canFight = true
			end
		end

		if not canFight then
			xyd.alertTips(__("QUICK_FORMATION_TEXT09"))

			return
		end
	end

	timeCloister:reqTimeCloisterBattle(self.params_.cloister, self.params_.stage, partnerParams, self.pet, self.chooseQuickTeam_)

	local energyMax = xyd.split(xyd.tables.miscTable:getVal("time_cloister_fight_energy_max"), "#", true)
	local num = timeCloister:getBattleEnergyAndTime()

	if energyMax[2] <= num then
		timeCloister.battleEnergyUpdateTime = xyd.getServerTime()
	end
end

function BattleFormationWindow:timeCloisterEncounter(partnerParams)
	local timeCloister = xyd.models.timeCloisterModel

	if self.chooseQuickTeam_ and self.chooseQuickTeam_ > 0 then
		local partner_list = xyd.models.quickFormation:getPartnerList(self.chooseQuickTeam_)
		local canFight = false

		for i = 1, 6 do
			if partner_list[i] then
				canFight = true
			end
		end

		if not canFight then
			xyd.alertTips(__("QUICK_FORMATION_TEXT09"))

			return
		end
	end

	timeCloister:reqTimeCloisterEncounter(self.params_.eventId, partnerParams, self.pet, self.chooseQuickTeam_)

	local energyMax = xyd.split(xyd.tables.miscTable:getVal("time_cloister_fight_energy_max"), "#", true)
	local num = timeCloister:getBattleEnergyAndTime()

	if energyMax[2] <= num then
		timeCloister.battleEnergyUpdateTime = xyd.getServerTime()
	end
end

function BattleFormationWindow:friendTeamBossBattle(partnerParams)
	if self.chooseQuickTeam_ and self.chooseQuickTeam_ > 0 then
		local partner_list = xyd.models.quickFormation:getPartnerList(self.chooseQuickTeam_)
		local canFight = false

		for i = 1, 6 do
			if partner_list[i] then
				canFight = true
			end
		end

		if not canFight then
			xyd.alertTips(__("QUICK_FORMATION_TEXT09"))

			return
		end
	end

	xyd.models.friendTeamBoss:reqFight(partnerParams, self.pet, self.params_.index, self.chooseQuickTeam_)
	xyd.WindowManager.get():closeWindow("friend_team_boss_info_window")
end

function BattleFormationWindow:guildBossBattle(partnerParams)
	if os.date("!*t", xyd.getServerTime()).wday == 6 and os.date("!*t", xyd.getServerTime()).hour == 0 and self.params_.bossId == xyd.GUILD_FINAL_BOSS_ID then
		xyd.showToast(__("GUILD_TEXT68"))
		xyd.closeWindow("guild_final_boss_window")
		xyd.closeWindow(self.name_)
	end

	xyd.WindowManager.get():closeWindow("guild_gym_window")

	if self.chooseQuickTeam_ and self.chooseQuickTeam_ > 0 then
		local partner_list = xyd.models.quickFormation:getPartnerList(self.chooseQuickTeam_)
		local canFight = false

		for i = 1, 6 do
			if partner_list[i] then
				canFight = true
			end
		end

		if not canFight then
			xyd.alertTips(__("QUICK_FORMATION_TEXT09"))

			return
		end
	end

	xyd.models.guild:fightBoss(self.params_.bossId, partnerParams, self.pet, self.chooseQuickTeam_)

	if xyd.models.guild:getFightUpdateTime() <= xyd:getServerTime() then
		xyd.models.deviceNotify:setNotifyTime(xyd.DEVICE_NOTIFY.NEW_GUILD_BOSS_CAN_FIGHT, xyd:getServerTime() + xyd.tables.miscTable:getNumber("guild_boss_fight_cd", "value"))
	end
end

function BattleFormationWindow:worldBossBattle(partnerParams)
	if self.params_.activity_id == xyd.ActivityID.MONTHLY_HIKE then
		if self.params_.stage_id then
			if self.params_.is_weep then
				xyd.models.activity:sweepBossNew(self.params_.stage_id, self.params_.num, true)
			else
				xyd.models.activity:sweepBossNew(self.params_.stage_id, 1, false)
			end

			return
		end

		if self.params_.is_weep then
			xyd.models.activity:fightBossNew(self.params_.activity_id, partnerParams, self.pet, self.params_.num, true)
		else
			xyd.models.activity:fightBossNew(self.params_.activity_id, partnerParams, self.pet, 1, false)
		end
	elseif self.params_.is_weep then
		xyd.models.activity:sweepBoss(self.params_.activity_id, self.params_.boss_type, partnerParams, self.params_.num, self.pet)
	else
		xyd.models.activity:fightBoss(self.params_.activity_id, self.params_.boss_type, partnerParams, self.pet)
	end
end

function BattleFormationWindow:guildCompetitionBattle(partnerParams)
	local params_data = self.params_
	local pet_data = self.pet
	local isHasFakePartner = false

	for i, info in pairs(partnerParams) do
		if tonumber(info.partner_id) == -1 then
			local trueInfo = xyd.models.guild:getCompetitionSpecialTruePartnerInfo()
			local fakePartner = xyd.models.guild:getCompetitionSpecialPartner()
			info.partner_id = trueInfo.truePartnerID
			info.table_id = trueInfo.trueTableID
			info.super = 1
			info.equips = fakePartner:getEquipment()
			info.potentials = fakePartner:getPotential()
			info.skill_index = fakePartner:getSkillIndex()
			info.is_fake_partner = 1
			info.lv = fakePartner:getLevel()
			info.awake = fakePartner:getAwake()
			isHasFakePartner = true
		end
	end

	if params_data.type == 1 then
		if isHasFakePartner then
			local cost = xyd.tables.miscTable:split2num("guild_competition_partner_cost", "value", "#")

			xyd.alertYesNo(__("GUILD_COMPETITION_PARTNER_TEXT03"), function (yes)
				if yes then
					if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
						xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

						return
					end

					xyd.models.guild:setGuildCompetitionFight(params_data.boss_id, params_data.type, partnerParams, pet_data)
				end
			end)

			return
		end

		xyd.alertYesNo(__("GUILD_COMPETITION_FIGHT_TIME"), function (yes)
			if yes then
				xyd.models.guild:setGuildCompetitionFight(params_data.boss_id, params_data.type, partnerParams, pet_data)
			end
		end)
	else
		xyd.models.guild:setGuildCompetitionFight(params_data.boss_id, params_data.type, partnerParams, pet_data)
	end
end

function BattleFormationWindow:galaxyTripBattle(partnerParams)
	local params_data = self.params_
	local pet_data = self.pet

	xyd.WindowManager.get():closeWindow("galaxy_trip_fight_window")
	xyd.models.galaxyTrip:setGridBattleFight(params_data.gridId, partnerParams, pet_data)
end

function BattleFormationWindow:galaxyTripSpecialBossBattle(partnerParams)
	local params_data = self.params_
	local pet_data = self.pet

	xyd.WindowManager.get():closeWindow("galaxy_trip_fight_window")
	xyd.models.galaxyTrip:setSpecialBossBattleFight(params_data.specialId, partnerParams, pet_data, params_data.isBoss)
end

function BattleFormationWindow:initLabel()
	self.labelSkipBtn.text = __("SKIP_BATTLE2")
	self.labelPetBtn.text = __("BATTLE_FORMAION_PET")
	self.labelFront.text = __("FRONT_ROW")
	self.labelBack.text = __("BACK_ROW")
	self.labelBattleBtn.text = __("BATTLE_START")

	if self.entranceBtnLabel then
		self.entranceBtnLabel.text = __("ENTRANCE_TEST_BATTLE_JUMP_SET")
	end

	if self.battleType == xyd.BattleType.CAMPAIGN then
		self.labelBattleBtn.text = __("FIGHT_BOSS")
	elseif self.battleType == xyd.BattleType.EXPLORE_ADVENTURE then
		self.labelBattleBtn.text = __("FRIEND_FIGHT")
	end
end

function BattleFormationWindow:initBuffList()
	self.buffDataList = {}
	local buffIds = self.groupBuffTable:getIds()

	for i, buffId in ipairs(buffIds) do
		local isAct = false

		table.insert(self.buffDataList, {
			isAct = isAct,
			buffId = tonumber(buffId)
		})
	end

	table.sort(self.buffDataList, function (a, b)
		return a.buffId < b.buffId
	end)

	if self.battleType == xyd.BattleType.HERO_CHALLENGE or self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS then
		local buffs = xyd.models.heroChallenge:getBuffIDs(self.params_.fortID)

		for i, buffId in ipairs(buffs) do
			table.insert(self.buffDataList, 1, {
				isAct = true,
				buffId = tonumber(buffId),
				type_ = xyd.GroupBuffIconType.HERO_CHALLENGE
			})
		end
	elseif self.battleType == xyd.BattleType.TRIAL then
		local buffIds = xyd.models.trial:getData().buff_ids

		if buffIds and #buffIds > 0 then
			for i = 1, #buffIds do
				table.insert(self.buffDataList, 1, {
					isAct = true,
					buffId = tonumber(buffIds[i]),
					type_ = xyd.GroupBuffIconType.NEW_TRIAL
				})
			end
		end
	end

	self:initBuffList2()
end

function BattleFormationWindow:initBuffList2()
	self.buffWrapContent = require("app.common.ui.FixedWrapContent").new(self.buffScrollView, self.buffContainer, self.buffRoot, GroupBuffIconItem, self)

	self.buffWrapContent:setInfos(self.buffDataList, {})
end

function BattleFormationWindow:onSelectGroup(group)
	if self.selectGroup_ == group then
		return
	end

	self.selectGroup_ = group
	self.currentGroup_ = group

	if self.filterGroupArctic then
		self.sortByPartnerArctic = false

		self.filterGroupArcticChooseImg:SetActive(false)
	end

	self:iniPartnerData(group, false)
end

function BattleFormationWindow:getPartners()
	local list = self.SlotModel:getSortedPartners()

	if xyd.MapType.ENTRANCE_TEST == self.mapType then
		local activityData = nil
		activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
		list = activityData:getSortedPartners()
	end

	if xyd.BattleType.TRIAL ~= self.battleType and xyd.BattleType.ACTIVITY_SPFARM ~= self.battleType then
		return list
	end

	if self.partners ~= nil and #self.partners > 0 then
		return self.partners
	end

	if xyd.BattleType.TRIAL == self.battleType then
		local filterList = {}

		for i, _ in pairs(list) do
			local partners = list[i]
			filterList[i] = {}

			for j = 1, #partners do
				local partnerID = partners[j]
				local partner = self.SlotModel:getPartner(partnerID)

				if partner and partner:getLevel() >= 40 then
					table.insert(filterList[i], partnerID)
				end
			end
		end

		self.partners = filterList

		return self.partners
	elseif xyd.BattleType.ACTIVITY_SPFARM == self.battleType then
		if self.spFarmType == xyd.ActivitySpfarmOpenBattleFormationType.DEF then
			return list
		else
			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)

			if not activityData then
				return {}
			else
				return activityData:getPartnerUse()
			end
		end
	end
end

function BattleFormationWindow:initPartnerList()
	local scale = 0.9

	if self.battleType == xyd.BattleType.EXPLORE_ADVENTURE then
		scale = 0.83
	end

	local params = {
		isCanUnSelected = 1,
		chosenGroup = 0,
		gap = 20,
		callback = handler(self, function (self, group)
			self:onSelectGroup(group)
		end),
		width = self.fGroup:GetComponent(typeof(UIWidget)).width,
		scale = scale
	}
	local partnerFilter = PartnerFilter.new(self.fGroup.gameObject, params)
	self.partnerFilter = partnerFilter

	if self.battleType == xyd.BattleType.ARCTIC_EXPEDITION then
		self.partnerFilter:changePositionX(-54)
		self.filterLine:SetActive(true)
		self.filterGroupArctic:SetActive(true)
	end

	if self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT then
		self.partnerFilter:SetActive(false)
	end

	if self.currentGroup_ and self.currentGroup_ ~= 0 then
		self.partnerFilter:updateChooseGroup(self.currentGroup_)
	end

	if self.battleType == xyd.BattleType.TRIAL or self.battleType == xyd.BattleType.ACTIVITY_SPFARM then
		self.partnerMultiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.partnerScrollView, self.partnerListWarpContent_, self.heroRoot, FormationItemWithHP, self)
	elseif self.battleType == xyd.BattleType.ARCTIC_EXPEDITION then
		self.partnerMultiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.partnerScrollView, self.partnerListWarpContent_, self.heroRoot, FormationItemWithStateIcon, self)
	elseif self.battleType == xyd.BattleType.SHRINE_HURDLE or self.battleType == xyd.BattleType.SHRINE_HURDLE_SET then
		self.partnerMultiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.partnerScrollView, self.partnerListWarpContent_, self.heroRoot, FormationItemShrineHurdle, self)
	else
		self.partnerMultiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.partnerScrollView, self.partnerListWarpContent_, self.heroRoot, FormationItem, self)
	end

	self:iniPartnerData(0, true)
end

function BattleFormationWindow:onClickArcticSort()
	if not self.sortByPartnerArctic then
		self.sortByPartnerArctic = true

		self:iniPartnerData(7, false)
		self.filterGroupArcticChooseImg:SetActive(true)
	else
		self.sortByPartnerArctic = false

		self:iniPartnerData(0, false)
		self.filterGroupArcticChooseImg:SetActive(false)
	end

	self.partnerFilter:updateChooseGroup(0)

	self.currentGroup_ = 0
end

function BattleFormationWindow:isSelected(cPartnerId, Plist, isDel)
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

function BattleFormationWindow:getPartnerByPartnerId(partnerId)
	local partnerInfo = self.SlotModel:getPartner(tonumber(partnerId))

	if xyd.MapType.ENTRANCE_TEST == self.mapType then
		local activityData = nil
		activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
		partnerInfo = activityData:getPartner(tonumber(partnerId))
	end

	if (self.battleType == xyd.BattleType.TIME_CLOISTER_EXTRA or self.battleType == xyd.BattleType.TIME_CLOISTER_BATTLE) and self.params_.cloisterExtraPartnerId and tonumber(partnerId) < 0 then
		local techInfo = xyd.models.timeCloisterModel:getTechInfoByCloister(self.params_.cloister)
		local level = techInfo[3][xyd.TimeCloisterSpecialTecId.PARTNER_3_TEC].curLv
		local needTableId = xyd.tables.timeCloisterPartnerTable:checkLeveltoId(level)
		local partner = import("app.models.Partner").new()
		local parnertId = xyd.tables.timeCloisterPartnerTable:getTableId(needTableId)

		partner:populate({
			table_id = parnertId,
			lev = level,
			awake = xyd.tables.timeCloisterPartnerTable:getAwake(needTableId),
			grade = xyd.tables.timeCloisterPartnerTable:getGrade(needTableId)
		})

		partner.partnerID = tonumber(partnerId)
		partnerInfo = partner
	end

	if self.battleType == xyd.BattleType.GUILD_COMPETITION and xyd.models.guild:getCompetitionSpecialPartner() and tonumber(partnerId) < 0 then
		partnerInfo = xyd.models.guild:getCompetitionSpecialPartner()
	end

	return partnerInfo
end

function BattleFormationWindow:initNormalPartnerData(groupID, needUpdateTop)
	local partnerList = self:getPartners()
	local lvSortedList = partnerList[tostring(xyd.partnerSortType.isCollected) .. "_0"]

	if self.battleType == xyd.BattleType.ENTRANCE_TEST or self.battleType == xyd.BattleType.ENTRANCE_TEST_DEF then
		lvSortedList = partnerList[tostring(xyd.partnerSortEntranceTestType.FINISH) .. "_0_0"]
	end

	if self.mapType == xyd.MapType.CAMPAIGN then
		self.mapInfo = self.mapsModel:getMapInfo(xyd.MapType.CAMPAIGN)
		self.maxStage = self.mapInfo.max_stage

		if self.maxStage <= 3 then
			lvSortedList = partnerList[xyd.partnerSortType.PARTNER_ID]
		end
	end

	if (self.battleType == xyd.BattleType.TIME_CLOISTER_EXTRA or self.battleType == xyd.BattleType.TIME_CLOISTER_BATTLE) and self.params_.cloisterExtraPartnerId then
		local tempArr = {}

		for i in pairs(lvSortedList) do
			table.insert(tempArr, lvSortedList[i])
		end

		table.insert(tempArr, 1, tonumber(self.params_.cloisterExtraPartnerId))

		lvSortedList = tempArr
	end

	if self.battleType == xyd.BattleType.GUILD_COMPETITION then
		local tempArr = {}
		local searchFakePartnerId = nil

		if xyd.models.guild:getCompetitionSpecialPartner() then
			searchFakePartnerId = xyd.models.guild:getCompetitionSpecialTruePartnerInfo().truePartnerID
		end

		for i in pairs(lvSortedList) do
			local isAdd = true

			if searchFakePartnerId and searchFakePartnerId == lvSortedList[i] then
				isAdd = false
			end

			if isAdd then
				table.insert(tempArr, lvSortedList[i])
			end
		end

		if xyd.models.guild:getCompetitionSpecialPartner() then
			table.insert(tempArr, 1, tonumber(xyd.models.guild:getCompetitionSpecialPartnerId()))
		end

		lvSortedList = tempArr
	end

	local partnerDataList = {}
	local chooseDataList = {}
	local tmpHangList = xyd.deepCopy(self.nowPartnerList)
	self.power = 0
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)

	for _, partnerId in ipairs(lvSortedList) do
		if partnerId ~= 0 then
			local partnerInfo = self:getPartnerByPartnerId(tonumber(partnerId))

			if self.battleType == xyd.BattleType.ENTRANCE_TEST or self.battleType == xyd.BattleType.ENTRANCE_TEST_DEF then
				partnerInfo = partnerId
			end

			partnerInfo.noClick = true
			local pGroupID = xyd.tables.partnerTable:getGroup(partnerInfo.tableID)
			local isS = self:isSelected(partnerId, self.nowPartnerList, false)

			if self.battleType == xyd.BattleType.ENTRANCE_TEST or self.battleType == xyd.BattleType.ENTRANCE_TEST_DEF then
				isS = self:isSelected(partnerInfo.partnerID or partnerId, self.nowPartnerList, false)
				local activityData = nil
				activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)

				partnerInfo:updateAttrs({
					isEntrance = true,
					fullStarOrigin = true
				})
			end

			local data = {
				callbackFunc = handler(self, function (a, callbackPInfo, callbackIsChoose)
					self:onClickheroIcon(callbackPInfo, callbackIsChoose)
				end),
				partnerInfo = partnerInfo,
				isSelected = isS.isSelected
			}

			if self.battleType == xyd.BattleType.ACTIVITY_SPFARM then
				data.model = activityData
			end

			if isS.isSelected then
				table.insert(partnerDataList, data)

				if needUpdateTop == true then
					self:onClickheroIcon(partnerInfo, false, isS.posId)
				end
			elseif groupID == 0 or pGroupID == groupID then
				table.insert(partnerDataList, data)
			end
		end
	end

	for i in pairs(self.nowPartnerList) do
		local partnerId = self.nowPartnerList[i]

		if partnerId ~= nil and partnerId ~= 0 then
			local partnerInfo = self:getPartnerByPartnerId(tonumber(partnerId))

			if partnerInfo then
				partnerInfo.noClick = true
				partnerInfo.posId = i
				local isS = true
				self.power = self.power + partnerInfo:getPower()
				local cParams = self:isPartnerSelected(partnerInfo.partnerID)
				local isChoose = cParams.isSelected

				if not isChoose then
					local HeroIcon = import("app.components.HeroIcon")
					local heroIcon = HeroIcon.new()

					heroIcon:setInfo(partnerInfo, self.pet)

					if xyd.BattleType.TRIAL == self.battleType then
						heroIcon.scale = 1
					end

					self:onClickheroIcon(heroIcon, false, false, false, partnerInfo.posId)
				end
			end
		end
	end

	self.labelForceNum.text = tostring(self.power)

	return partnerDataList
end

function BattleFormationWindow:initSHPartnerData(groupID, needUpdateTop)
	local partnerList = xyd.models.shrineHurdleModel:getPartners()

	if xyd.models.shrineHurdleModel:checkInGuide() then
		partnerList = xyd.models.shrineHurdleModel:getGuidePartnerList()
	end

	local partnerDataList = {}
	self.power = 0

	for partnerId, partnerInfo in pairs(partnerList) do
		if partnerId ~= 0 then
			partnerInfo.noClick = true
			local pGroupID = xyd.tables.partnerTable:getGroup(partnerInfo.table_id)
			local isS = self:isSelected(partnerId, self.nowPartnerList, false)
			partnerInfo.partnerID = partnerId
			partnerInfo.skin_id = partnerInfo.equips[7]
			partnerInfo.star = xyd.tables.partnerTable:getStar(partnerInfo.table_id) + partnerInfo.awake
			partnerInfo.group = pGroupID
			local data = {
				callbackFunc = handler(self, function (a, callbackPInfo, callbackIsChoose)
					self:onClickheroIcon(callbackPInfo, callbackIsChoose)
				end),
				partnerInfo = partnerInfo,
				isSelected = isS.isSelected
			}

			if isS.isSelected then
				table.insert(partnerDataList, data)

				if needUpdateTop == true then
					self:onClickheroIcon(partnerInfo, false, isS.posId)
				end
			elseif groupID == 0 or pGroupID == groupID then
				table.insert(partnerDataList, data)
			end
		end
	end

	table.sort(partnerDataList, function (a, b)
		local lva = a.partnerInfo.lv or a.partnerInfo.level
		local lvb = b.partnerInfo.lv or b.partnerInfo.level
		local table_id_a = a.partnerInfo.table_id * 100
		local table_id_b = b.partnerInfo.table_id * 100
		local a_partner_id = a.partnerInfo.pr_id or a.partnerInfo.partnerID
		local b_partner_id = b.partnerInfo.pr_id or b.partnerInfo.partnerID

		return lva * 1000000000 + table_id_a + a_partner_id > lvb * 1000000000 + table_id_b + b_partner_id
	end)

	for i in pairs(self.nowPartnerList) do
		local partnerId = self.nowPartnerList[i]

		if partnerId ~= nil and partnerId ~= 0 then
			local partnerInfo = xyd.models.shrineHurdleModel:getPartner(partnerId)

			if partnerInfo then
				partnerInfo.noClick = true
				partnerInfo.posId = i
				local isS = true
				self.power = self.power + partnerInfo.power
				local cParams = self:isPartnerSelected(partnerInfo.partnerID)
				local isChoose = cParams.isSelected

				if not isChoose then
					local HeroIcon = import("app.components.HeroIcon")
					local heroIcon = HeroIcon.new()

					heroIcon:setInfo(partnerInfo, self.pet)

					if xyd.BattleType.TRIAL == self.battleType then
						heroIcon.scale = 1
					end

					self:onClickheroIcon(heroIcon, false, false, false, partnerInfo.posId)
				end
			end
		end
	end

	self.labelForceNum.text = tostring(self.power)

	return partnerDataList
end

function BattleFormationWindow:initSpfarmFightData(groupID, needUpdateTop)
	local partnerList = self:getPartners()
	local partnerDataList = {}
	self.power = 0
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)

	for index, partnerInfo in ipairs(partnerList) do
		if partnerInfo and partnerInfo.partner_id ~= 0 then
			local partnerId = partnerInfo.partner_id or partnerInfo.partnerID
			local partnerInfo = self:getPartnerByPartnerId(tonumber(partnerId))
			partnerInfo.noClick = true
			local pGroupID = xyd.tables.partnerTable:getGroup(partnerInfo.tableID)
			local isS = self:isSelected(partnerId, self.nowPartnerList, false)
			local isArcticFine = xyd.models.activity:getArcticPartnerValue(partnerId) >= 12
			local data = {
				callbackFunc = handler(self, function (a, callbackPInfo, callbackIsChoose)
					self:onClickheroIcon(callbackPInfo, callbackIsChoose)
				end),
				partnerInfo = partnerInfo,
				isSelected = isS.isSelected,
				model = activityData
			}

			if isS.isSelected then
				table.insert(partnerDataList, data)

				if needUpdateTop == true then
					self:onClickheroIcon(partnerInfo, false, isS.posId)
				end
			elseif groupID == 0 or pGroupID == groupID or groupID == 7 and isArcticFine then
				table.insert(partnerDataList, data)
			end
		end
	end

	__TRACE("測試一次")

	for i, _ in pairs(self.nowPartnerList) do
		local partnerId = self.nowPartnerList[i]

		if partnerId ~= nil and partnerId ~= 0 then
			local partnerInfo = self:getPartnerByPartnerId(tonumber(partnerId))

			if partnerInfo then
				partnerInfo.noClick = true
				partnerInfo.posId = i
				local isS = true
				self.power = self.power + partnerInfo:getPower()
				local cParams = self:isPartnerSelected(partnerInfo.partnerID)
				local isChoose = cParams.isSelected

				if not isChoose then
					local HeroIcon = import("app.components.HeroIcon")
					local heroIcon = HeroIcon.new()

					heroIcon:setInfo(partnerInfo, self.pet)
					self:onClickheroIcon(heroIcon, false, false, false, partnerInfo.posId)
				end
			end
		end
	end

	self.labelForceNum.text = tostring(self.power)

	return partnerDataList
end

function BattleFormationWindow:initPartnerDataWithLev(groupID, needUpdateTop, limitLev)
	local partnerList = self:getPartners()
	local lvSortedList = partnerList[tostring(xyd.partnerSortType.isCollected) .. "_0"]
	local partnerDataList = {}
	local chooseDataList = {}
	local tmpHangList = xyd.deepCopy(self.nowPartnerList)
	self.power = 0

	for _, partnerId in ipairs(lvSortedList) do
		if partnerId ~= 0 then
			local partnerInfo = self:getPartnerByPartnerId(tonumber(partnerId))
			partnerInfo.noClick = true
			local pGroupID = xyd.tables.partnerTable:getGroup(partnerInfo.tableID)
			local isS = self:isSelected(partnerId, self.nowPartnerList, false)
			local isArcticFine = xyd.models.activity:getArcticPartnerValue(partnerId) >= 12
			local data = {
				callbackFunc = handler(self, function (a, callbackPInfo, callbackIsChoose)
					self:onClickheroIcon(callbackPInfo, callbackIsChoose)
				end),
				partnerInfo = partnerInfo,
				isSelected = isS.isSelected
			}

			if isS.isSelected then
				table.insert(partnerDataList, data)

				if needUpdateTop == true then
					self:onClickheroIcon(partnerInfo, false, isS.posId)
				end
			elseif (groupID == 0 or pGroupID == groupID or groupID == 7 and isArcticFine) and limitLev <= partnerInfo:getLevel() then
				table.insert(partnerDataList, data)
			end
		end
	end

	__TRACE("測試一次")

	for i, _ in pairs(self.nowPartnerList) do
		local partnerId = self.nowPartnerList[i]

		if partnerId ~= nil and partnerId ~= 0 then
			local partnerInfo = self:getPartnerByPartnerId(tonumber(partnerId))

			if partnerInfo and limitLev <= partnerInfo:getLevel() then
				partnerInfo.noClick = true
				partnerInfo.posId = i
				local isS = true
				self.power = self.power + partnerInfo:getPower()
				local cParams = self:isPartnerSelected(partnerInfo.partnerID)
				local isChoose = cParams.isSelected

				if not isChoose then
					local HeroIcon = import("app.components.HeroIcon")
					local heroIcon = HeroIcon.new()

					heroIcon:setInfo(partnerInfo, self.pet)
					self:onClickheroIcon(heroIcon, false, false, false, partnerInfo.posId)
				end
			end
		end
	end

	self.labelForceNum.text = tostring(self.power)

	return partnerDataList
end

function BattleFormationWindow:initHeroChallengePartnerData(groupID, needUpdateTop)
	local partnerList = xyd.models.heroChallenge:getHeros(self.params_.fortID)
	local partnerDataList = {}
	self.power = 0

	for _, partner in ipairs(partnerList) do
		local partnerInfo = {
			noClick = true,
			tableID = partner:getHeroTableID(),
			lev = partner:getLevel(),
			awake = partner.awake,
			group = partner:getGroup(),
			grade = partner:getGrade(),
			partnerID = partner:getPartnerID(),
			power = partner:getPower()
		}
		local pGroupID = partner:getGroup()
		local isS = self:isSelected(partnerInfo.partnerID, self.nowPartnerList, false)
		local data = {
			callbackFunc = handler(self, function (a, callbackPInfo, callbackIsChoose)
				self:onClickheroIcon(callbackPInfo, callbackIsChoose)
			end),
			partnerInfo = partnerInfo,
			isSelected = isS.isSelected
		}

		if isS.isSelected then
			table.insert(partnerDataList, data)

			self.power = self.power + partner:getPower()

			if needUpdateTop == true then
				self:onClickheroIcon(partnerInfo, false, isS.posId)
			end
		elseif groupID == 0 or pGroupID == groupID then
			table.insert(partnerDataList, data)
		end
	end

	self.labelForceNum.text = tostring(self.power)

	return partnerDataList
end

function BattleFormationWindow:initBeachIslandPartnerData(groupID, needUpdateTop)
	local partnerList = xyd.tables.activityBeachIsland:getOptionalPartners(self.stageId)

	if self.battleType == xyd.BattleType.ENCOUNTER_STORY then
		partnerList = xyd.tables.activityEnconterBattleTable:getOptionalPartners(self.stageId)
	end

	local partnerDataList = {}
	self.power = 0
	local i = 1

	while i <= #partnerList do
		local monsterId = partnerList[i]

		if monsterId ~= nil then
			local partner = Monster.new()

			partner:populateWithTableID(monsterId)

			partner.noClick = true
			partner.partnerType = "npcPartner"
			local partnerInfo = {
				isMonster = true,
				noClick = true,
				tableID = xyd.tables.monsterTable:getPartnerLink(monsterId),
				lev = partner:getLevel(),
				awake = partner.awake,
				group = partner:getGroup(),
				grade = partner:getGrade(),
				partnerID = i,
				power = partner:getPower(),
				skin_id = xyd.tables.monsterTable:getPartnerSkin(monsterId),
				monster_id = monsterId
			}
			local pGroupID = partner:getGroup()
			local isS = self:isSelected(partnerInfo.partnerID, self.nowPartnerList, false)
			local data = {
				callbackFunc = handler(self, function (a, callbackPInfo, callbackIsChoose)
					self:onClickheroIcon(callbackPInfo, callbackIsChoose)
				end),
				partnerInfo = partnerInfo,
				isSelected = isS.isSelected
			}

			if isS.isSelected then
				table.insert(partnerDataList, data)

				self.power = self.power + partner:getPower()

				if needUpdateTop == true then
					self:onClickheroIcon(partnerInfo, false, isS.posId)
				end
			elseif groupID == 0 or pGroupID == groupID then
				table.insert(partnerDataList, data)
			end
		end

		i = i + 1
	end

	return partnerDataList
end

function BattleFormationWindow:isDeath(partnerID)
	local flag = false

	if (self.battleType == xyd.BattleType.HERO_CHALLENGE or self.bttleType == xyd.BattleType.HERO_CHALLENGE_CHESS) and xyd.models.heroChallenge:isDead(partnerID, self.params_.fortID) then
		flag = true
	end

	return flag
end

function BattleFormationWindow:isPartnerSelected(partnerID)
	local isSelected = false
	local sPosId = -1

	for posId in pairs(self.copyIconList) do
		local heroIcon = self.copyIconList[posId]

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

function BattleFormationWindow:checkNeedGrey()
	local flag = false

	if self.battleType == xyd.BattleType.HERO_CHALLENGE then
		flag = true
	end

	return flag
end

function BattleFormationWindow:iniPartnerData(groupID, needUpdateTop)
	if self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT or self.battleType == xyd.BattleType.ENTRANCE_TEST_DEF or self.battleType == xyd.BattleType.ENTRANCE_TEST then
		groupID = self.currentGroup_
	end

	local partnerDataList = nil

	if self.battleType == xyd.BattleType.HERO_CHALLENGE or self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS then
		partnerDataList = self:initHeroChallengePartnerData(groupID, needUpdateTop)
	elseif self.battleType == xyd.BattleType.BEACH_ISLAND or self.battleType == xyd.BattleType.ENCOUNTER_STORY then
		partnerDataList = self:initBeachIslandPartnerData(groupID, needUpdateTop)
	elseif self.battleType == xyd.BattleType.ARCTIC_EXPEDITION then
		partnerDataList = self:initPartnerDataWithLev(groupID, needUpdateTop, 100)
	elseif self.battleType == xyd.BattleType.SHRINE_HURDLE or self.battleType == xyd.BattleType.SHRINE_HURDLE_SET then
		partnerDataList = self:initSHPartnerData(groupID, needUpdateTop)
	elseif self.battleType == xyd.BattleType.ACTIVITY_SPFARM then
		if self.spFarmType == xyd.ActivitySpfarmOpenBattleFormationType.DEF then
			partnerDataList = self:initNormalPartnerData(groupID, needUpdateTop)
		else
			partnerDataList = self:initSpfarmFightData(groupID, needUpdateTop)
		end
	else
		partnerDataList = self:initNormalPartnerData(groupID, needUpdateTop)
	end

	self.partnerScrollView.enabled = true
	self.nowTempList_ = partnerDataList or {}

	self.partnerMultiWrap_:setInfos(partnerDataList, {})
end

function BattleFormationWindow:getTargetLocal(targetObj, container)
	local targetGlobalPos = targetObj:localToGlobal()
	local targetContainerPos = container:globalToLocal(targetGlobalPos.x, targetGlobalPos.y)

	return targetContainerPos
end

function BattleFormationWindow:onClickheroIcon(partnerInfo, isChoose, pos, needAnimation, posId, isFriendPartner)
	if self.needSound then
		SoundManager:playSound("2037")
	end

	if isChoose == false and isFriendPartner ~= nil and isFriendPartner == true then
		local Win = xyd.WindowManager.get():getWindow("friend_boss_battle_formation_window")

		if Win:friendPartnerIsSelect() then
			xyd.alert(xyd.AlertType.TIPS, __("ASSISTANT_LIMIT"))

			return
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
			local progressWithIcon = self["progressWithIcon" .. tostring(posId)]

			if heroIcon then
				NGUITools.Destroy(heroIcon)
			end

			if progress then
				progress.value = 0
			end

			if progressWithIcon then
				progressWithIcon.value = 0

				if self["progressIcon" .. tostring(posId)] then
					self["progressIcon" .. tostring(posId)].gameObject:SetActive(false)
				end
			end

			self.selectedNum = self.selectedNum - 1
			self.copyIconList[posId] = nil
			self.nowPartnerList[posId] = nil

			if xyd.BattleType.FRIEND_BOSS == self.battleType and isFriendPartner == true then
				local friendwin = xyd.WindowManager.get():getWindow("friend_boss_battle_formation_window")

				if friendwin then
					friendwin:updateFriendPartnerState()
					friendwin:setFriendPartnerIsSelect(false)
				end
			end
		end
	else
		if self.battleType == xyd.BattleType.HERO_CHALLENGE then
			local partnerId = partnerInfo.partnerID

			if xyd.models.heroChallenge:isDead(partnerId, self.params_.fortID) then
				xyd.alert(xyd.AlertType.TIPS, __("ALREADY_DIE"))

				return
			end
		end

		posId = -1

		if self.selectedNum == self.defaultMaxNum then
			return
		end

		if pos ~= nil and pos >= 1 then
			posId = pos
		else
			for i = 1, self.defaultMaxNum do
				if not self.copyIconList[i] and posId == -1 then
					posId = i

					break
				end
			end
		end

		local function copyCallback(copyIcon)
			self:iconTapHandler(copyIcon:getPartnerInfo(), isFriendPartner)
		end

		local copyPartnerInfo = {
			noClickSelected = true,
			tableID = partnerInfo.tableID or partnerInfo.table_id,
			lev = partnerInfo.lev or partnerInfo.lv,
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
			equips = partnerInfo.equips,
			ex_skills = partnerInfo.ex_skills,
			potentials = partnerInfo.potentials,
			skill_index = partnerInfo.skill_index,
			love_point = partnerInfo.love_point,
			star_origin = partnerInfo.star_origin,
			travel = partnerInfo.travel
		}
		local copyIcon = import("app.components.HeroIcon").new(self["container" .. tostring(posId)].gameObject)

		copyIcon:setInfo(copyPartnerInfo, self.pet)

		self.selectedNum = self.selectedNum + 1

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

		if isFriendPartner == false or isFriendPartner == nil then
			copyIcon:setLongPressListener(longPressCallback)
		end

		self.copyIconList[posId] = copyIcon
		self.nowPartnerList[posId] = partnerInfo.partnerID

		if xyd.BattleType.TRIAL == self.battleType then
			local hp = xyd.models.trial:getHp(partnerInfo.partnerID)
			self["progress" .. tostring(tostring(posId))].value = hp / 100
		elseif xyd.BattleType.ACTIVITY_SPFARM == self.battleType then
			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)
			local hp = 100

			if activityData then
				hp = activityData:getHp(partnerInfo.partnerID)
			end

			self["progress" .. tostring(tostring(posId))].value = hp / 100
		elseif xyd.BattleType.SHRINE_HURDLE == self.battleType or self.battleType == xyd.BattleType.SHRINE_HURDLE_SET then
			local hp = partnerInfo.status.hp
			self["progress" .. tostring(tostring(posId))].value = hp / 100
		elseif xyd.BattleType.ARCTIC_EXPEDITION == self.battleType then
			local progressWithIcon = self["progressWithIcon" .. tostring(posId)]
			local progressIcon = self["progressIcon" .. tostring(posId)]
			local state = xyd.models.activity:getArcticPartnerState(partnerInfo.partnerID)
			local stateValue = xyd.models.activity:getArcticPartnerValue(partnerInfo.partnerID) or 0
			local maxValue = xyd.tables.miscTable:getVal("expedition_girls_labor", "value")
			progressWithIcon.value = stateValue / tonumber(maxValue)
			local imgName = "expedition_partner_state_icon_small_" .. state

			progressIcon.gameObject:SetActive(true)
			xyd.setUISpriteAsync(progressIcon, nil, imgName)
		end

		if xyd.BattleType.FRIEND_BOSS == self.battleType then
			local friendwin = xyd.WindowManager.get():getWindow("friend_boss_battle_formation_window")

			if friendwin and isFriendPartner then
				friendwin:setFriendPartnerIsSelect(true)
				friendwin:updateFriendPartnerState()
			end
		end
	end

	self:updateForceNum()
	self:updateBuff()
	self:updateCopyListRed()
end

function BattleFormationWindow:updateCopyListRed()
	if xyd.BattleType.ENTRANCE_TEST == self.battleType or xyd.BattleType.ENTRANCE_TEST_DEF == self.battleType then
		for _, heroIcon in pairs(self.copyIconList) do
			heroIcon:showRedMark(not heroIcon:checkEntranceTestFinish())
		end
	end
end

function BattleFormationWindow:longPressIcon(copyIcon)
	if self.isEditorQuickTeam then
		return
	end

	self:showPartnerDetail(copyIcon:getPartnerInfo())
end

function BattleFormationWindow:startDrag(copyIcon)
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

	local info = copyIcon:getPartnerInfo()
	local posId = tonumber(info.posId)

	if self["progress" .. posId] then
		self["progress" .. posId].value = 0
	end

	if self["progressIcon" .. tostring(posId)] then
		self["progressIcon" .. tostring(posId)].gameObject:SetActive(false)
	end

	if self["progressWithIcon" .. tostring(posId)] then
		self["progressWithIcon" .. tostring(posId)].value = 0
	end
end

function BattleFormationWindow:onDrag(copyIcon, delta)
	if not self.isStartDrag then
		return
	end

	local go = copyIcon.go
	local pos = go.transform.localPosition
	go.transform.localPosition = Vector3(pos.x + delta.x / xyd.Global.screenToLocalAspect(), pos.y + delta.y / xyd.Global.screenToLocalAspect(), pos.z)
end

function BattleFormationWindow:endDrag(copyIcon)
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

	if cPosId > 0 then
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
				sequence:Kill(false)
			end)

			if self["progress" .. cPosId] and self["progress" .. posId] then
				if xyd.BattleType.TRIAL == self.battleType then
					self["progress" .. cPosId].value = xyd.models.trial:getHp(partnerInfo.partnerID) / 100
					self["progress" .. posId].value = xyd.models.trial:getHp(cInfo.partnerID) / 100
				elseif xyd.BattleType.ACTIVITY_SPFARM == self.battleType then
					local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)
					self["progress" .. cPosId].value = activityData:getHp(partnerInfo.partnerID) / 100
					self["progress" .. posId].value = activityData:getHp(cInfo.partnerID) / 100
				else
					local cpartnerID = partnerInfo.partnerID
					local posPartnerID = cInfo.partnerID
					self["progress" .. cPosId].value = xyd.models.shrineHurdleModel:getPartner(cpartnerID).status.hp / 100
					self["progress" .. posId].value = xyd.models.shrineHurdleModel:getPartner(posPartnerID).status.hp / 100
				end
			elseif self["progressWithIcon" .. tostring(posId)] and self["progressWithIcon" .. tostring(cPosId)] then
				local state1 = xyd.models.activity:getArcticPartnerState(cInfo.partnerID)
				local value1 = xyd.models.activity:getArcticPartnerValue(cInfo.partnerID)
				local state2 = xyd.models.activity:getArcticPartnerState(partnerInfo.partnerID)
				local value2 = xyd.models.activity:getArcticPartnerValue(partnerInfo.partnerID)
				local maxValue = xyd.tables.miscTable:getVal("expedition_girls_labor", "value")
				self["progressWithIcon" .. tostring(posId)].value = value1 / tonumber(maxValue)
				self["progressWithIcon" .. tostring(cPosId)].value = value2 / tonumber(maxValue)

				self["progressIcon" .. tostring(posId)].gameObject:SetActive(true)
				self["progressIcon" .. tostring(cPosId)].gameObject:SetActive(true)
				xyd.setUISpriteAsync(self["progressIcon" .. tostring(posId)], nil, "expedition_partner_state_icon_small_" .. state1)
				xyd.setUISpriteAsync(self["progressIcon" .. tostring(cPosId)], nil, "expedition_partner_state_icon_small_" .. state2)
			end
		end

		self.nowPartnerList[cPosId] = self.nowPartnerList[posId]
		self.nowPartnerList[posId] = tmpPartnerId
		self.copyIconList[cPosId] = self.copyIconList[posId]
		self.copyIconList[posId] = cCopyIcon

		if self["progress" .. cPosId] then
			if self.battleType == xyd.BattleType.TRIAL then
				self["progress" .. cPosId].value = xyd.models.trial:getHp(partnerInfo.partnerID) / 100
			elseif xyd.BattleType.ACTIVITY_SPFARM == self.battleType then
				local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)
				self["progress" .. cPosId].value = activityData:getHp(partnerInfo.partnerID) / 100
			else
				local cpartnerID = partnerInfo.partnerID
				self["progress" .. cPosId].value = xyd.models.shrineHurdleModel:getPartner(cpartnerID).status.hp / 100
			end
		elseif self["progressWithIcon" .. tostring(cPosId)] then
			local maxValue = xyd.tables.miscTable:getVal("expedition_girls_labor", "value")
			self["progressWithIcon" .. tostring(cPosId)].value = xyd.models.activity:getArcticPartnerValue(partnerInfo.partnerID) / maxValue

			if self["progressIcon" .. tostring(cPosId)] then
				local state = xyd.models.activity:getArcticPartnerState(partnerInfo.partnerID)

				self["progressIcon" .. tostring(cPosId)].gameObject:SetActive(true)
				xyd.setUISpriteAsync(self["progressIcon" .. tostring(cPosId)], nil, "expedition_partner_state_icon_small_" .. state)
			end
		end
	elseif self["progress" .. posId] then
		if self.isShowGuide_ then
			self["progress" .. posId].value = 0
		elseif self.battleType == xyd.BattleType.TRIAL then
			self["progress" .. posId].value = xyd.models.trial:getHp(partnerInfo.partnerID) / 100
		elseif xyd.BattleType.ACTIVITY_SPFARM == self.battleType then
			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)
			self["progress" .. posId].value = activityData:getHp(partnerInfo.partnerID) / 100
		else
			local cpartnerID = partnerInfo.partnerID
			self["progress" .. posId].value = xyd.models.shrineHurdleModel:getPartner(cpartnerID).status.hp / 100
		end
	elseif self["progressIcon" .. tostring(posId)] then
		local progressWithIcon = self["progressWithIcon" .. tostring(posId)]
		local progressIcon = self["progressIcon" .. tostring(posId)]
		local state = xyd.models.activity:getArcticPartnerState(partnerInfo.partnerID)
		local stateValue = xyd.models.activity:getArcticPartnerValue(partnerInfo.partnerID) or 0
		local maxValue = xyd.tables.miscTable:getVal("expedition_girls_labor", "value")
		progressWithIcon.value = stateValue / tonumber(maxValue)
		local imgName = "expedition_partner_state_icon_small_" .. state

		progressIcon.gameObject:SetActive(true)
		xyd.setUISpriteAsync(progressIcon, nil, imgName)
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
		end

		self.isMovingAfterDrag = false

		sequence:Kill(false)

		sequence = nil
	end)
end

function BattleFormationWindow:isChange(copyIcon)
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

function BattleFormationWindow:showPartnerDetail(partnerInfo)
	if self.battleType == xyd.BattleType.QUICK_TEAM_SET then
		return
	end

	if xyd.GuideController.get():isPlayGuide() then
		return
	end

	if not partnerInfo then
		return
	end

	local closeBefore = false
	local params = {
		unable_move = true,
		isLongTouch = true,
		sort_key = "0_0",
		not_open_slot = true,
		partner_id = partnerInfo.partnerID,
		table_id = partnerInfo.tableID,
		battleData = self.params_,
		ifSchool = self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT,
		skin_id = partnerInfo.skin_id
	}
	local wndName = nil

	if self.battleType == xyd.BattleType.HERO_CHALLENGE or self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS then
		params.partners = {
			{
				table_id = partnerInfo.tableID
			}
		}
		wndName = "guide_detail_window"
	elseif self.battleType == xyd.BattleType.ENTRANCE_TEST or self.battleType == xyd.BattleType.ENTRANCE_TEST_DEF then
		params.partner = partnerInfo
		params.sort_type = tostring(xyd.partnerSortEntranceTestType.FINISH)
		params.current_group = self.currentGroup_
		params.battleData.current_group = self.currentGroup_
		local formationData = self:getFormationData()
		local partnerParams = formationData.partnerParams
		params.partnerParams = partnerParams
		wndName = "activity_entrance_test_partner_window"
	elseif self.battleType == xyd.BattleType.GUILD_COMPETITION and partnerInfo.partnerID < 0 then
		if partnerInfo.partnerID < 0 then
			local PartnerGuild = import("app.models.Partner")
			local guildCopyPartner = nil
			local copyPartner = xyd.models.guild:getCompetitionSpecialPartner()

			if copyPartner then
				guildCopyPartner = copyPartner
			else
				guildCopyPartner = PartnerGuild.new()

				guildCopyPartner:populate(partnerInfo)
			end

			local params = {
				hide_btn = false,
				index = 1,
				partner = guildCopyPartner,
				table_id = partnerInfo.tableID,
				partner_list = {}
			}

			xyd.WindowManager.get():openWindow("guild_competition_special_partner_window", params)

			return
		end
	elseif self.battleType == xyd.BattleType.SHRINE_HURDLE or self.battleType == xyd.BattleType.SHRINE_HURDLE_SET then
		wndName = "partner_detail_window"
		params.isTrial = true
		params.isShrineHurdle = true
		params.noClick = true
		params.closeBefore = true
		params.partner = partnerInfo
	elseif self.battleType == xyd.BattleType.TRIAL then
		wndName = "partner_detail_window"
		closeBefore = true
		params.isTrial = true
	elseif xyd.BattleType.ACTIVITY_SPFARM == self.battleType then
		wndName = "partner_detail_window"
		closeBefore = true
		params.isSpfarm = true
	elseif self.battleType == xyd.BattleType.ARCTIC_EXPEDITION then
		wndName = "partner_detail_window"
		closeBefore = true
		params.isTrial = true
	elseif self.battleType == xyd.BattleType.BEACH_ISLAND or self.battleType == xyd.BattleType.ENCOUNTER_STORY then
		params.partners = {
			{
				table_id = partnerInfo.tableID,
				isMonster = partnerInfo.isMonster,
				monster_id = partnerInfo.monster_id
			}
		}
		wndName = "guide_detail_window"
	elseif (self.battleType == xyd.BattleType.TIME_CLOISTER_EXTRA or self.battleType == xyd.BattleType.TIME_CLOISTER_BATTLE) and partnerInfo.partnerID < 0 then
		return
	else
		wndName = "partner_detail_window"
	end

	if self.battleType == xyd.BattleType.SHRINE_HURDLE and xyd.models.shrineHurdleModel:checkInGuide() then
		return
	end

	local showTime = xyd.tables.partnerPictureTable:getShowTime(params.skin_id)

	if params.skin_id and showTime and xyd.getServerTime() < showTime then
		params.skin_id = nil
	end

	local formationData = self:getFormationData()
	local partnerParams = formationData.partnerParams
	local formationIds = formationData.formationIds
	local formation = {
		pet_id = self.pet,
		partners = formationIds
	}

	self:saveLocalformation(formation)
	xyd.openWindow(wndName, params, function ()
		if closeBefore then
			xyd.WindowManager.get():closeWindow(self.name_)
		end
	end)
end

function BattleFormationWindow:saveLocalformation(formation)
	if self.battleType and xyd.arrayIndexOf(self.showFormationTeamTypeArr, self.battleType) > 0 and self.isEditorQuickTeam then
		local dbParams = {
			key = self.battleType .. "_quick",
			value = self.chooseQuickTeam_
		}

		xyd.db.formation:addOrUpdate(dbParams)

		return
	else
		local dbParams = {
			key = self.battleType .. "_quick",
			value = 0
		}

		xyd.db.formation:addOrUpdate(dbParams)
	end

	local dbParams = {
		value = json.encode(formation)
	}

	if self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT then
		dbParams.key = self.battleType .. "_" .. self.selectGroup_
	elseif self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS or self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS then
		dbParams.key = self.battleType .. "_" .. self.params_.fortID
	elseif self.battleType == xyd.BattleType.SHRINE_HURDLE then
		dbParams.key = self.battleType .. "_1"
	elseif self.battleType == xyd.BattleType.SHRINE_HURDLE_SET then
		dbParams.key = "shrine_hurdle_auto_partner"
	elseif self.battleType == xyd.BattleType.ENTRANCE_TEST then
		dbParams.key = self.battleType .. "_" .. self.data.enemy_id
		local entranceTestActivityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)

		xyd.db.misc:setValue({
			key = "entrance_test_save_formation_save_time" .. self.data.enemy_id,
			value = xyd.getServerTime()
		})
	elseif not self.ifChooseEnemy then
		dbParams.key = self.battleType
	else
		dbParams.key = self.battleType .. "_enemy"
	end

	xyd.db.formation:addOrUpdate(dbParams)
end

function BattleFormationWindow:updateFormationItemInfo(info, realIndex)
	local partnerInfo = info.partnerInfo
	local partnerId = partnerInfo.partnerID
	local isSelected = info.isSelected
	local isS = self:isSelected(partnerId, self.nowPartnerList, false)

	if isSelected ~= isS.isSelected then
		info.isSelected = isS.isSelected

		self.partnerMultiWrap_:updateInfo(realIndex, info)
	end
end

function BattleFormationWindow:getFormationItemByPartnerID(partnerID)
	local items = self.partnerMultiWrap_:getItems()

	for _, formationItem in ipairs(items) do
		if formationItem:getPartnerId() == partnerID then
			return formationItem
		end
	end
end

function BattleFormationWindow:iconTapHandler(copyPartnerInfo, isFriendPartner)
	if self.isShowGuide_ then
		return
	end

	SoundManager:playSound("2038")

	if self.isMovingAfterDrag then
		return
	end

	local partnerInfo = copyPartnerInfo
	local params = self:isSelected(partnerInfo.partnerID, self.nowPartnerList)
	local isChoose = params.isSelected
	local posId = params.posId

	if posId >= 0 then
		NGUITools.Destroy(self.copyIconList[posId]:getGameObject())

		self.selectedNum = self.selectedNum - 1
		local fItem = self:getFormationItemByPartnerID(partnerInfo.partnerID)

		if fItem then
			fItem:setIsChoose(false)
		end

		self.copyIconList[posId] = nil
		self.nowPartnerList[posId] = nil
	end

	self:updateForceNum()
	self:updateBuff()

	if xyd.BattleType.TRIAL == self.battleType or xyd.BattleType.SHRINE_HURDLE == self.battleType or self.battleType == xyd.BattleType.SHRINE_HURDLE_SET or xyd.BattleType.ACTIVITY_SPFARM == self.battleType then
		local copyIconInfo = copyPartnerInfo
		local posId = copyIconInfo.posId

		if self["progress" .. tostring(tostring(posId))] then
			self["progress" .. tostring(tostring(posId))].value = 0
		end
	elseif xyd.BattleType.ARCTIC_EXPEDITION == self.battleType then
		if self["progressWithIcon" .. tostring(posId)] then
			self["progressWithIcon" .. tostring(posId)].value = 0
		end

		if self["progressIcon" .. tostring(posId)] then
			self["progressIcon" .. tostring(posId)].gameObject:SetActive(false)
		end
	end

	if xyd.BattleType.FRIEND_BOSS == self.battleType and isFriendPartner == true then
		local friendwin = xyd.WindowManager.get():getWindow("friend_boss_battle_formation_window")

		if friendwin then
			friendwin:updateFriendPartnerState()
			friendwin:setFriendPartnerIsSelect(false)
		end
	end
end

function BattleFormationWindow:isGuideChange(copyIcon)
	local pInfo = copyIcon:getPartnerInfo()
	local dPosId = tonumber(pInfo.posId)
	local posIds = {
		1,
		3
	}
	local go = copyIcon.go
	local goTrans = go.transform
	local iconWidget = go:GetComponent(typeof(UIWidget))
	local iconWidth = iconWidget.width
	local iconHeight = iconWidget.height
	local tarPos = goTrans.localPosition

	for i = 1, #posIds do
		local posId = posIds[i]

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
				xyd.GuideController.get():completeOneGuide()

				if self.guideMask_ then
					self.guideMask_:destroy()

					self.guideMask_ = nil
				end

				return posId
			end
		end
	end

	return -1
end

function BattleFormationWindow:updateForceNum()
	local power = 0

	for i, _ in pairs(self.copyIconList) do
		if self.copyIconList[i] then
			local partnerInfo = self.copyIconList[i]:getPartnerInfo()

			if self.battleType == xyd.BattleType.HERO_CHALLENGE or self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS then
				local partner = xyd.models.heroChallenge:getPartner(partnerInfo.partnerID, self.params_.fortID)
				power = power + partner:getPower()
			else
				power = power + partnerInfo.power
			end
		end
	end

	self.labelForceNum.text = tostring(power)
end

function BattleFormationWindow:updateBuff()
	local groupNum = {}
	local tNum = 0

	for i = 1, #self.copyIconList do
		local partnerIcon = self.copyIconList[i]

		if partnerIcon then
			local partnerInfo = partnerIcon:getPartnerInfo()
			local group = nil

			if self.battleType == xyd.BattleType.HERO_CHALLENGE or self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS then
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

	for i = 1, xyd.GROUP_NUM do
		if not groupNum[i] then
			groupNum[i] = 0
		end
	end

	local showBuffIds = self.groupBuffTable:getBuffIds(groupNum)
	local showBuffIds_ = {}

	for k, v in ipairs(showBuffIds) do
		showBuffIds_[v.id] = v.group7Num or 0
	end

	local buffIds = self.groupBuffTable:getIds()
	local maxWidth = #self.buffDataList * 76
	local maxNum = 8
	local scrollWidth = 632
	local firstJump = nil

	for i = 1, #self.buffDataList do
		local buffId = self.buffDataList[i].buffId
		local isAct = self.buffDataList[i].isAct
		local type_ = self.buffDataList[i].type_ or xyd.GroupBuffIconType.GROUP_BUFF

		if type_ ~= xyd.GroupBuffIconType.HERO_CHALLENGE and type_ ~= xyd.GroupBuffIconType.NEW_TRIAL then
			local groupDataList = xyd.split(self.groupBuffTable:getGroupConfig(buffId), "|")
			local isNewAct = true
			local type = self.groupBuffTable:getType(self.buffDataList[i].buffId)

			if not showBuffIds_[buffId] then
				isNewAct = false
			elseif showBuffIds_[buffId] > 0 then
				self.buffDataList[i].group7Num = showBuffIds_[buffId]
			end

			if isNewAct ~= isAct then
				self.buffDataList[i].isAct = isNewAct
				firstJump = firstJump or self.buffDataList[i]
			end
		end
	end

	if firstJump then
		self:waitForFrame(1, function ()
			if self.buffScrollView.gameObject.activeInHierarchy then
				self.buffWrapContent:setInfos(self.buffDataList)
				self.buffWrapContent:jumpToInfo(firstJump)
				self.buffWrapContent.wrapContent_:WrapContent()
			end
		end)
	end
end

function BattleFormationWindow:showGuide(guideID)
	if self.isShowGuide_ then
		return
	end

	if guideID then
		self.isShowGuide_ = true
	end

	for i = 1, 2 do
		self["guideDialog" .. i] = self.groupGuide:NodeByName("guideDialog" .. i).gameObject
		self["labelGuideDesc" .. i] = self["guideDialog" .. i]:ComponentByName("labelGuideDesc" .. i, typeof(UILabel))
	end

	self.labelGuideDesc1.text = __("GUIDE_CAMPAIGN_TIPS_1")
	self.labelGuideDesc2.text = __("GUIDE_CAMPAIGN_TIPS_2")

	self.groupGuide:SetActive(true)
	self.guideDialog1:SetActive(true)

	local w = self.guideDialog1:GetComponent(typeof(UIWidget))
	w.alpha = 0
	local w2 = self.guideDialog2:GetComponent(typeof(UIWidget))
	w2.alpha = 0
	local action = DG.Tweening.DOTween.Sequence()

	action:Append(xyd.getTweenAlpha(w, 1, 0.5)):AppendCallback(function ()
		self.guideDialog2:SetActive(true)
	end):Append(xyd.getTweenAlpha(w2, 1, 0.5))
end

function BattleFormationWindow:initGuideMask()
	if tolua.isnull(self.window_) then
		return
	end

	if self.guideMask_ then
		self.guideMask_:destroy()

		self.guideMask_ = nil
	end

	local guideMaskNode_ = self.groupGuide:NodeByName("guideMask").gameObject
	local guideMask = import("app.components.GuideMask").new(guideMaskNode_)

	guideMask:init(xyd.Global.getRealWidth(), xyd.Global.getMaxBgHeight())

	self.guideMask_ = guideMask
	local maskPos = self.groupGuide.position
	local pos = self.groupGuide:InverseTransformPoint(maskPos)

	self.guideMask_:updateMask2({
		{
			icon = "buttoncrop_22",
			pos = {
				x = pos.x - 132,
				y = pos.y + 130 + 71
			},
			iconOffset = {
				0,
				0
			}
		}
	})
	self.guideMask_:SetLocalPosition(0, -13, 0)
end

function BattleFormationWindow:initAcademyAssessmentGuide()
	local flag = xyd.db.misc:getValue("academy_assessment_battle_set_guide")

	if flag and tonumber(flag) == 1 then
		return
	end

	self.academyAssessmentGuideObj = NGUITools.AddChild(self.quickSetBtn.gameObject, "academyAssessmentGuide")
	local academyAssessmentGuideTexture = self.academyAssessmentGuideObj:AddComponent(typeof(UITexture))
	academyAssessmentGuideTexture.width = 2
	academyAssessmentGuideTexture.height = 2

	xyd.setUITextureByName(academyAssessmentGuideTexture, "spine_tex")

	academyAssessmentGuideTexture.depth = 100
	local guideHand = xyd.Spine.new(self.academyAssessmentGuideObj)

	guideHand:setInfo("fx_ui_dianji", function ()
		guideHand:play("texiao01", 0, 1)
	end)
end

function BattleFormationWindow:willClose()
	BattleFormationWindow.super.willClose(self)

	if self.guideTimer_ then
		self.guideTimer_:stop()

		self.guideTimer_ = nil
	end

	if self.iconTouchTimer_ then
		self.iconTouchTimer_:stop()

		self.iconTouchTimer_ = nil
	end
end

function BattleFormationWindow:excuteCallBack()
	if self.callback then
		self:callback()
	end
end

function BattleFormationWindow:getBattleType()
	return self.battleType
end

function BattleFormationWindow:readStorageFormation()
	if self.battleType and xyd.arrayIndexOf(self.showFormationTeamTypeArr, self.battleType) > 0 then
		local dbVal = tonumber(xyd.db.formation:getValue(self.battleType .. "_quick"))

		if dbVal and dbVal > 0 then
			self.storageTeam_ = dbVal

			return
		end
	end

	local dbVal = xyd.db.formation:getValue(self.battleType)

	if self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT then
		dbVal = xyd.db.formation:getValue(self.battleType .. "_" .. self.selectGroup_)
	elseif self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS or self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS then
		dbVal = xyd.db.formation:getValue(self.battleType .. "_" .. self.params_.fortID)
	elseif self.battleType == xyd.BattleType.SHRINE_HURDLE then
		dbVal = xyd.db.formation:getValue(self.battleType .. "_1")
	elseif self.battleType == xyd.BattleType.SHRINE_HURDLE_SET then
		dbVal = xyd.db.formation:getValue("shrine_hurdle_auto_partner")
	elseif self.battleType == xyd.BattleType.ENTRANCE_TEST then
		dbVal = xyd.db.formation:getValue(self.battleType .. "_" .. self.data.enemy_id)
	end

	if self.ifChooseEnemy then
		dbVal = xyd.db.formation:getValue(self.battleType .. "_enemy")
	end

	if not dbVal then
		return false
	end

	local data = json.decode(dbVal)

	if not data.partners then
		return false
	end

	if not self.ifChooseEnemy then
		self.pet = xyd.checkCondition(self.pet == 0, data.pet_id, self.pet) or 0
	else
		self.pet = self.pet or 0
	end

	if self.battleType == xyd.BattleType.HERO_CHALLENGE and not xyd.models.heroChallenge:isHasPet(self.pet, self.params_.fortID) then
		self.pet = 0
	end

	local tmpPartnerList = data.partners
	local hasSelect = {}

	for i = #tmpPartnerList, 1, -1 do
		local sPartnerID = tonumber(tmpPartnerList[i])
		self.nowPartnerList[i] = sPartnerID

		if self.battleType == xyd.BattleType.ENTRANCE_TEST or self.battleType == xyd.BattleType.ENTRANCE_TEST_DEF then
			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
			local p = activityData:getPartnerByIndex(sPartnerID)

			if p and p.partnerID ~= 0 then
				sPartnerID = p.partnerID
			else
				tmpPartnerList[i] = nil
				self.nowPartnerList[i] = nil
			end
		elseif self.battleType == xyd.BattleType.HERO_CHALLENGE or self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS then
			local p_ = xyd.models.heroChallenge:getPartnerByTableID(sPartnerID, self.params_.fortID, hasSelect)

			if not p_ or self:isDeath(p_:getPartnerID()) then
				tmpPartnerList[i] = nil
				self.nowPartnerList[i] = nil
			else
				table.insert(hasSelect, p_:getPartnerID())

				tmpPartnerList[i] = p_:getPartnerID()
				self.nowPartnerList[i] = p_:getPartnerID()
			end
		elseif self.battleType == xyd.BattleType.TRIAL then
			local hp = xyd.models.trial:getHp(sPartnerID) / 100

			if hp <= 0 then
				tmpPartnerList[i] = nil
				self.nowPartnerList[i] = nil
			end
		elseif xyd.BattleType.ACTIVITY_SPFARM == self.battleType then
			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)
			local hp = activityData:getHp(sPartnerID) / 100

			if hp <= 0 then
				tmpPartnerList[i] = nil
				self.nowPartnerList[i] = nil
			end
		elseif self.battleType == xyd.BattleType.SHRINE_HURDLE_SET or self.battleType == xyd.BattleType.SHRINE_HURDLE and tonumber(sPartnerID) and tonumber(sPartnerID) > 0 then
			local partnerInfo = xyd.models.shrineHurdleModel:getPartner(sPartnerID)

			if not partnerInfo then
				tmpPartnerList[i] = nil
				self.nowPartnerList[i] = nil
			else
				local hp = partnerInfo.status.hp / 100

				if hp <= 0 then
					tmpPartnerList[i] = nil
					self.nowPartnerList[i] = nil
				end
			end
		elseif self.battleType ~= xyd.BattleType.BEACH_ISLAND then
			if self.battleType == xyd.BattleType.ENCOUNTER_STORY then
				-- Nothing
			elseif self.battleType == xyd.BattleType.TIME_CLOISTER_EXTRA or self.battleType == xyd.BattleType.TIME_CLOISTER_BATTLE then
				if sPartnerID and sPartnerID > 0 and not xyd.models.slot:getPartner(sPartnerID) then
					tmpPartnerList[i] = nil
					self.nowPartnerList[i] = nil
				elseif sPartnerID and sPartnerID < 0 and sPartnerID ~= tonumber(self.params_.cloister) * -1 then
					tmpPartnerList[i] = nil
					self.nowPartnerList[i] = nil
				end
			elseif self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT then
				if self.ifChooseEnemy then
					-- Nothing
				elseif not self:getPartnerByPartnerId(sPartnerID) then
					tmpPartnerList[i] = nil
					self.nowPartnerList[i] = nil
				elseif not xyd.models.slot:getPartner(sPartnerID) then
					tmpPartnerList[i] = nil
					self.nowPartnerList[i] = nil
				elseif xyd.models.slot:getPartner(sPartnerID):getGroup() ~= self.selectGroup_ then
					tmpPartnerList[i] = nil
					self.nowPartnerList[i] = nil
				end
			elseif self.battleType == xyd.BattleType.QUICK_TEAM_SET then
				-- Nothing
			elseif self.battleType == xyd.BattleType.GUILD_COMPETITION then
				if xyd.models.guild:getCompetitionSpecialPartner() and sPartnerID and sPartnerID == xyd.models.guild:getCompetitionSpecialTruePartnerInfo().truePartnerID then
					tmpPartnerList[i] = nil
					self.nowPartnerList[i] = nil
				end

				if sPartnerID and sPartnerID < 0 then
					tmpPartnerList[i] = nil
					self.nowPartnerList[i] = nil
				end
			elseif self.ifChooseEnemy then
				-- Nothing
			elseif not self:getPartnerByPartnerId(sPartnerID) then
				tmpPartnerList[i] = nil
				self.nowPartnerList[i] = nil
			elseif not xyd.models.slot:getPartner(sPartnerID) then
				tmpPartnerList[i] = nil
				self.nowPartnerList[i] = nil
			end
		end
	end

	return true
end

function BattleFormationWindow:petChoose()
	if self.isEditorQuickTeam then
		xyd.alertTips(__("QUICK_FORMATION_TEXT07"))

		return
	end

	local petType = xyd.PetFormationType.Battle1v1

	if self.battleType == xyd.BattleType.HERO_CHALLENGE then
		petType = xyd.PetFormationType.HeroChallenge
	elseif self.battleType == xyd.BattleType.ENTRANCE_TEST or self.battleType == xyd.BattleType.ENTRANCE_TEST_DEF then
		petType = xyd.PetFormationType.ENTRANCE_TEST
	end

	if self.battleType == xyd.BattleType.PARTNER_STATION then
		xyd.WindowManager.get():openWindow("station_choose_pet_window", {
			type = petType,
			select = {
				self.pet,
				0,
				0,
				0
			}
		})
	else
		xyd.WindowManager.get():openWindow("choose_pet_window", {
			type = petType,
			select = {
				self.pet,
				0,
				0,
				0
			}
		})
	end
end

function BattleFormationWindow:onChoosePet(selectIDs)
	self.pet = selectIDs[1] or 0

	for _, icon in pairs(self.copyIconList) do
		if icon then
			icon:setPetFrame(self.pet)
		end
	end

	self:updatePetRed()
end

function BattleFormationWindow:iosTestChangeUI()
	local allSprites = self.window_:GetComponentsInChildren(typeof(UISprite), true)

	for i = 0, allSprites.Length - 1 do
		local sprite = allSprites[i]

		xyd.setUISprite(sprite, nil, sprite.spriteName .. "_ios_test")
	end

	xyd.setUISprite(self.selectedGroup:ComponentByName("e:Image", typeof(UISprite)), nil, "9gongge23_ios_test")

	self.selectedGroup:ComponentByName("e:Image", typeof(UISprite)).height = 280

	self.selectedGroup:ComponentByName("e:Image", typeof(UISprite)):Y(-33)

	self.labelFront.color = Color.New2(4294967295.0)
	self.labelBack.color = Color.New2(4294967295.0)
end

function BattleFormationWindow:initQuickFormationTeam()
	if self.battleType and xyd.arrayIndexOf(self.showFormationTeamTypeArr, self.battleType) > 0 and xyd.checkFunctionOpen(xyd.FunctionID.QUICK_FORMATION, true) then
		xyd.models.quickFormation:updatePartnerInfo()
		xyd.models.quickFormation:updateRedStatus()

		self.redStatus_ = xyd.models.quickFormation:getRedStatus()

		if not self.battleFormationTeamBtn then
			local obj = ResCache.AddGameObject(self.selectedGroup.gameObject, "Prefabs/Components/formation_team_con")

			obj:SetLocalPosition(185, 137, 0)
			self.skipBtn.transform:X(20)

			self.sortPop = obj:NodeByName("sortPop").gameObject
			self.formationQuickTeamMask = self.sortPop:NodeByName("formationQuickTeamMask").gameObject
			self.battleFormationTeamBtn = self.sortPop:NodeByName("formationTeamBtn").gameObject
			self.battleFormationTeamBtnLabel = self.battleFormationTeamBtn:ComponentByName("battleFormationTeamBtnLabel", typeof(UILabel))
			self.formationTeamArrowImg = self.battleFormationTeamBtn:NodeByName("formationTeamArrowImg").gameObject
			self.battleFormationTeamBtnLabel.text = __("QUICK_FORMATION_TEXT05")

			if xyd.Global.lang == "de_de" then
				self.battleFormationTeamBtnLabel.transform:X(-15)

				self.battleFormationTeamBtnLabel.width = 100
			end

			self.saveBottom = obj:NodeByName("saveBottom").gameObject
			self.saveTeamMask = self.saveBottom:NodeByName("saveTeamMask").gameObject
			self.saveTeamBtn = self.saveBottom:NodeByName("saveTeamBtn").gameObject
			self.saveTeamBtnBtnLabel = self.saveTeamBtn:ComponentByName("saveTeamBtnLabel", typeof(UILabel))
			self.saveTeamArrowImg = self.saveTeamBtn:NodeByName("saveTeamArrowImg").gameObject
			self.saveTeamBtnBtnLabel.text = __("QUICK_FORMATION_TEXT25")
			self.formationPetBtn = obj:NodeByName("formationPetBtn").gameObject
			self.formationPetBtnIcon = self.formationPetBtn:ComponentByName("formationPetBtnIcon", typeof(UISprite))
			self.formationPetBtnLev = self.formationPetBtnIcon:ComponentByName("formationPetBtnLev", typeof(UILabel))
			self.formationPetBtnDefaultIcon = self.formationPetBtn:NodeByName("formationPetBtnDefaultIcon").gameObject
			self.formationPetBtnRedPoint = self.formationPetBtn:NodeByName("formationPetBtnRedPoint").gameObject

			if self.petBtn.gameObject.activeSelf then
				self.petBtn:SetActive(false)
				self.formationPetBtn.gameObject:SetActive(true)
			else
				self.formationPetBtn.gameObject:SetActive(false)
			end

			self.formationTeamEditorDownShow = obj:NodeByName("formationTeamEditorDownShow").gameObject
			self.formationTeamQuitEditorBtn = self.formationTeamEditorDownShow:NodeByName("formationTeamQuitEditorBtn").gameObject
			self.formationTeamQuitEditorBtnLabel = self.formationTeamQuitEditorBtn:ComponentByName("formationTeamQuitEditorBtnLabel", typeof(UILabel))
			self.formationTeamEditorTips = self.formationTeamEditorDownShow:ComponentByName("formationTeamEditorTips", typeof(UILabel))
			self.formationTeamQuitEditorBtnLabel.text = __("QUICK_FORMATION_TEXT06")
			self.formationTeamEditorTips.text = __("QUICK_FORMATION_TEXT07")
			local tabTeam = obj:NodeByName("tab_team").gameObject
			local saveTeam = obj:NodeByName("tab_save_team").gameObject
			self.sorPopCon = self.sortPop:NodeByName("sorPopCon").gameObject
			local teamNum = xyd.models.quickFormation:getTeamNum()
			local itemHeight = 52
			self.sorPopCon:GetComponent(typeof(UIWidget)).height = teamNum * itemHeight

			for i = 1, teamNum do
				local tmp = NGUITools.AddChild(self.sorPopCon.gameObject, tabTeam.gameObject)
				tmp.name = "tab_" .. i

				tmp.gameObject:Y((i - 1) * -1 * itemHeight)

				self["formationQuickTeamBtnRedPoint" .. i] = tmp:NodeByName("redPoint").gameObject
				local label = tmp:ComponentByName("label", typeof(UILabel))
				label.text = xyd.models.quickFormation:getTeamName(i)

				if i == 1 or i == teamNum then
					local chosen = tmp:ComponentByName("chosen", typeof(UISprite))
					local unchosen = tmp:ComponentByName("unchosen", typeof(UISprite))
					local chosenStr = "partner_sort_bg_chosen_03"
					local unchosenStr = "partner_sort_bg_unchosen_03"

					if i == 1 then
						chosenStr = "partner_sort_bg_chosen_01"
						unchosenStr = "partner_sort_bg_unchosen_01"
					elseif i == teamNum then
						chosenStr = "partner_sort_bg_chosen_02"
						unchosenStr = "partner_sort_bg_unchosen_02"
					end

					xyd.setUISpriteAsync(chosen, nil, chosenStr)
					xyd.setUISpriteAsync(unchosen, nil, unchosenStr)
				end

				if not xyd.models.quickFormation:isTeamPartnersHas(i) then
					local mask = tmp:NodeByName("mask").gameObject

					mask:SetActive(true)

					UIEventListener.Get(mask).onClick = function ()
						xyd.alertTips(__("QUICK_FORMATION_TEXT09"))
					end
				end
			end

			self.saveBottomCon = self.saveBottom:NodeByName("saveBottomCon").gameObject

			for i = 1, teamNum do
				local tmp = NGUITools.AddChild(self.saveBottomCon.gameObject, saveTeam.gameObject)
				tmp.name = "tab_" .. i

				tmp.gameObject:Y((i - 1) * itemHeight)

				local label = tmp:ComponentByName("label", typeof(UILabel))
				label.text = xyd.models.quickFormation:getTeamName(i)
				self["saveTeamBtnRedPoint" .. i] = tmp:NodeByName("redPoint").gameObject

				if i == 1 or i == teamNum then
					local unchosen = tmp:ComponentByName("unchosen", typeof(UISprite))
					local unchosenStr = "partner_sort_bg_unchosen_03"

					if i == teamNum then
						unchosenStr = "partner_sort_bg_unchosen_01"
					elseif i == 1 then
						unchosenStr = "partner_sort_bg_unchosen_02"
					end

					xyd.setUISpriteAsync(unchosen, nil, unchosenStr)
				end

				UIEventListener.Get(tmp).onClick = function ()
					self:onClickSaveTeam(i)
				end
			end

			self.formationQuickTeamTab = require("app.common.ui.CommonTabBar").new(self.sorPopCon.gameObject, teamNum, function (index)
				self:onTouchFormationQuickTeam(index)
			end)
		end

		if self.storageTeam_ and self.storageTeam_ > 0 then
			self:waitForFrame(5, function ()
				self:onTouchFormationQuickTeam(self.storageTeam_, true)
			end)
		end
	end
end

function BattleFormationWindow:onQuickFormationTeamBtnTouch(update_red)
	if self.quickFormationTeamSortStation then
		self.formationTeamArrowImg.gameObject:SetLocalScale(1, -1, 1)
	else
		self.formationTeamArrowImg.gameObject:SetLocalScale(1, 1, 1)
	end

	local teamNum = xyd.models.quickFormation:getTeamNum()

	self:moveQuickFormationTeamGroup()

	if update_red then
		for i = 1, teamNum do
			self["formationQuickTeamBtnRedPoint" .. i]:SetActive(self.redStatus_[i] == 1)
		end
	end
end

function BattleFormationWindow:onSaveTeamBtnTouch(update_red)
	if self.formationQuickTeamMask.activeSelf then
		self:onQuickFormationTeamBtnTouch()
	end

	if self.saveTeamSortStation then
		self.saveTeamArrowImg.gameObject:SetLocalScale(1, 1, 1)
	else
		self.saveTeamArrowImg.gameObject:SetLocalScale(1, -1, 1)
	end

	local teamNum = xyd.models.quickFormation:getTeamNum()

	self:moveSaveTeamGroup()

	if update_red then
		for i = 1, teamNum do
			self["saveTeamBtnRedPoint" .. i]:SetActive(self.redStatus_[i] == 1)
		end
	end
end

function BattleFormationWindow:updateQuickRed()
	self.redStatus_ = xyd.models.quickFormation:getRedStatus()
	local teamNum = xyd.models.quickFormation:getTeamNum()

	for i = 1, teamNum do
		self["saveTeamBtnRedPoint" .. i]:SetActive(self.redStatus_[i] == 1)
	end

	for i = 1, teamNum do
		self["formationQuickTeamBtnRedPoint" .. i]:SetActive(self.redStatus_[i] == 1)
	end
end

function BattleFormationWindow:moveQuickFormationTeamGroup()
	if self.quickFormationTeamSortStation == nil then
		self.quickFormationTeamSortStation = false
	end

	local groupSort = self.sorPopCon.transform

	if self.quickFormationTeamSortStation then
		self.formationQuickTeamMask:SetActive(false)

		local sequence = self:getSequence()

		sequence:Append(groupSort:DOLocalMoveY(-12, 0.067)):Append(groupSort:DOLocalMoveY(34, 0.1)):Join(xyd.getTweenAlpha(self.sorPopCon:GetComponent(typeof(UIWidget)), 0.01, 0.1)):AppendCallback(function ()
			self.sorPopCon:SetActive(false)
		end)

		self.quickFormationTeamSortStation = not self.quickFormationTeamSortStation
	else
		self.formationQuickTeamMask:SetActive(true)
		self.sorPopCon:SetActive(true)

		self.sorPopCon:GetComponent(typeof(UIWidget)).alpha = 0.01

		self.sorPopCon:SetLocalPosition(groupSort.localPosition.x, 20, 0)

		local sequence = self:getSequence()

		sequence:Append(groupSort:DOLocalMoveY(-5, 0.1)):Join(xyd.getTweenAlpha(self.sorPopCon:GetComponent(typeof(UIWidget)), 1, 0.1)):Append(groupSort:DOLocalMoveY(0, 0.2))

		self.quickFormationTeamSortStation = not self.quickFormationTeamSortStation
	end
end

function BattleFormationWindow:moveSaveTeamGroup()
	if self.saveTeamSortStation == nil then
		self.saveTeamSortStation = false
	end

	local groupSort = self.saveBottomCon.transform

	if self.saveTeamSortStation then
		self.saveTeamMask:SetActive(false)

		local sequence = self:getSequence()

		sequence:Append(groupSort:DOLocalMoveY(95, 0.067)):Append(groupSort:DOLocalMoveY(30, 0.1)):Join(xyd.getTweenAlpha(self.saveBottomCon:GetComponent(typeof(UIWidget)), 0.01, 0.1)):AppendCallback(function ()
			self.saveBottomCon:SetActive(false)
		end)

		self.saveTeamSortStation = not self.saveTeamSortStation
	else
		self.saveTeamMask:SetActive(true)
		self.saveBottomCon:SetActive(true)

		self.saveBottomCon:GetComponent(typeof(UIWidget)).alpha = 0.01

		self.saveBottomCon:SetLocalPosition(groupSort.localPosition.x, 20, 0)

		local sequence = self:getSequence()

		sequence:Append(groupSort:DOLocalMoveY(101, 0.1)):Join(xyd.getTweenAlpha(self.saveBottomCon:GetComponent(typeof(UIWidget)), 1, 0.1)):Append(groupSort:DOLocalMoveY(106, 0.2))

		self.saveTeamSortStation = not self.saveTeamSortStation
	end
end

function BattleFormationWindow:onTouchFormationQuickTeam(index, is_smart)
	if self.redStatus_[index] == 1 then
		xyd.alertTips(__("QUICK_FORMATION_TEXT11"))
	end

	if index == 0 then
		-- Nothing
	else
		self.isEditorQuickTeam = true

		self.saveBottom:SetActive(false)
		self.chooseGroup:SetActive(false)
		self.formationTeamEditorDownShow:SetActive(true)

		if not is_smart then
			self:onQuickFormationTeamBtnTouch()
		end
	end

	if index == 0 then
		self.chooseQuickTeam_ = index

		self:clearPartners(true)
		self:onChoosePet({
			0
		})

		self.battleFormationTeamBtnLabel.text = __("QUICK_FORMATION_TEXT05")
	else
		self:clearPartners()

		self.chooseQuickTeam_ = index
		local partner_list = xyd.models.quickFormation:getPartnerList(index)
		self.selectedNum = 0

		for pos, partnerInfo in pairs(partner_list) do
			local copyPartnerInfo = {
				noClick = true,
				noClickSelected = true,
				tableID = partnerInfo.tableID or partnerInfo.table_id,
				lev = partnerInfo.lev or partnerInfo.lv,
				star = partnerInfo.star,
				skin_id = partnerInfo.skin_id,
				is_vowed = partnerInfo.is_vowed,
				posId = pos,
				awake = partnerInfo.awake,
				grade = partnerInfo.grade,
				group = partnerInfo.group or partnerInfo:getGroup(),
				partnerID = partnerInfo.partnerID,
				power = partnerInfo.power or partnerInfo:getPower(),
				partnerType = partnerInfo.partnerType,
				equips = partnerInfo.equips,
				ex_skills = partnerInfo.ex_skills,
				potentials = partnerInfo.potentials,
				skill_index = partnerInfo.skill_index,
				love_point = partnerInfo.love_point,
				travel = partnerInfo.travel
			}
			local copyIcon = import("app.components.HeroIcon").new(self["container" .. tostring(pos)].gameObject)

			copyIcon:setInfo(copyPartnerInfo, self.pet)

			self.selectedNum = self.selectedNum + 1
			self.copyIconList[pos] = copyIcon
			self.nowPartnerList[pos] = partnerInfo.partnerID
		end

		self:updateForceNum()
		self:updateBuff()
		self:onChoosePet({
			xyd.models.quickFormation:getPet(index)
		})

		local name = xyd.models.quickFormation:getTeamName(index)
		self.battleFormationTeamBtnLabel.text = name
	end
end

function BattleFormationWindow:onClickSaveTeam(index)
	local formationData = self:getFormationData()
	local partnerParams = formationData.partnerParams

	if #partnerParams <= 0 then
		xyd.alertTips(__("QUICK_FORMATION_TEXT27"))

		return
	end

	xyd.alertYesNo(__("QUICK_FORMATION_TEXT26"), function (yes_no)
		if yes_no then
			self:onSaveTeamBtnTouch()

			local partnerData = {}

			for _, prInfo in ipairs(partnerParams) do
				local pos = prInfo.pos
				local partner_id = prInfo.partner_id
				local partner_info = xyd.models.slot:getPartner(partner_id)
				local params = {
					pos = pos,
					skill_index = partner_info.skill_index,
					potentials = partner_info.potentials,
					partner_id = partner_id,
					equips = {}
				}
				local equipments = partner_info:getEquipment()

				for index, equip in pairs(equipments) do
					params.equips[index] = {
						id = equip,
						from_partner_id = partner_id
					}
				end

				table.insert(partnerData, params)
			end

			xyd.models.quickFormation:setTeamInfo(index, self.pet, partnerData)
		end
	end)
end

function BattleFormationWindow:onQuickFormationTeamQuit()
	self.isEditorQuickTeam = false

	self.chooseGroup:SetActive(true)
	self.saveBottom:SetActive(true)
	self.formationTeamEditorDownShow:SetActive(false)
	self.formationQuickTeamTab:clearChoose()
	self:onTouchFormationQuickTeam(0)
end

function BattleFormationWindow:clearPartners(reset)
	self.nowPartnerList = {}

	for i, _ in pairs(self.copyIconList) do
		local partnerIcon = self.copyIconList[i]

		NGUITools.Destroy(partnerIcon:getGameObject())
	end

	self.copyIconList = {}
	self.selectedNum = 0
	self.chooseQuickTeam_ = nil

	if reset then
		self:readStorageFormation()
	end

	self:iniPartnerData(self.currentGroup_, true)
end

function BattleFormationWindow:getBackPackEquipInfo()
	local bpEquips = {}
	local bp = xyd.models.backpack
	local itemTable = xyd.tables.itemTable
	local MAP_TYPE_2_POS = {
		["6"] = 1,
		["9"] = 4,
		["7"] = 2,
		["8"] = 3,
		["11"] = 6
	}
	local datas = bp:getItems()

	for i = 1, #datas do
		local itemID = datas[i].item_id
		local itemNum = tonumber(datas[i].item_num)
		local item = {
			itemID = itemID,
			itemNum = itemNum
		}
		local pos = MAP_TYPE_2_POS[tostring(itemTable:getType(itemID))]

		if pos ~= nil then
			bpEquips[pos] = bpEquips[pos] or {}

			table.insert(bpEquips[pos], item)
		end
	end

	local equipsOfPartners = xyd.models.slot:getEquipsOfPartners()

	for key, _ in pairs(equipsOfPartners) do
		local itemID = tonumber(key)
		local itemNum = 1
		local pos = MAP_TYPE_2_POS[tostring(itemTable:getType(itemID))]

		if pos then
			for _, partner_id in ipairs(equipsOfPartners[key]) do
				local item = {
					itemID = itemID,
					itemNum = itemNum,
					partner_id = partner_id
				}
				bpEquips[pos] = bpEquips[pos] or {}

				table.insert(bpEquips[pos], item)
			end
		end
	end

	return bpEquips
end

function BattleFormationWindow:getFromPartnerID(itemID, bpEquips)
	local itemTable = xyd.tables.itemTable
	local MAP_TYPE_2_POS = {
		["6"] = 1,
		["9"] = 4,
		["7"] = 2,
		["8"] = 3,
		["11"] = 6
	}
	local pos = MAP_TYPE_2_POS[tostring(itemTable:getType(itemID))]
	local list = bpEquips[pos] or {}

	for index, itemInfo in ipairs(list) do
		if itemInfo.itemID == itemID and (not itemInfo.itemNum or tonumber(itemInfo.itemNum) > 0) then
			if not itemInfo.partner_id or itemInfo.partner_id <= 0 then
				itemInfo.itemNum = itemInfo.itemNum - 1

				return 0
			else
				itemInfo.itemNum = itemInfo.itemNum - 1

				return itemInfo.partner_id
			end
		end
	end

	return -1
end

return BattleFormationWindow
