local BaseWindow = import(".BaseWindow")
local BattleFormationWindow = import(".BattleFormationWindow")
local FairArenaBattleFormationWindow = class("BattleFormationWindow", BattleFormationWindow)
local FormationItem = BattleFormationWindow.FormationItem
local FairArenaFormationItem = class("BattleFormationWindow", FormationItem)
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local GroupBuffIcon = import("app.components.GroupBuffIcon")
local SoundManager = xyd.SoundManager.get()

function FairArenaFormationItem:update(index, realIndex, info)
	FairArenaFormationItem.super.update(self, index, realIndex, info)
	self:updateShowEquip()
end

function FairArenaFormationItem:updateShowEquip()
	if self.partnerId_ and self.partnerId_ > 0 then
		local need_partner_info = xyd.models.fairArena:getPartnerByID(self.partnerId_)
		self.equipID = need_partner_info:getEquipment()[6] or 0

		self.heroIcon_:initEquipId(self.equipID)
	end
end

function FairArenaBattleFormationWindow:ctor(name, params)
	FairArenaBattleFormationWindow.super.ctor(self, name, params)

	self.skipBtnCallback = nil
	self.ifMove = false
	self.defaultMaxNum = 6
	self.selectedNum = 0
	self.copyIconList = {}
	self.nowPartnerList = {}
	self.isIconMoving = false
	self.needSound = false
	self.partners = {}
	self.mapsModel = xyd.models.map
	self.data = params
	self.mapType = params.mapType or xyd.MapType.CAMPAIGN
	self.battleType = params.battleType or xyd.BattleType.FAIR_ARENA
	self.currentGroup_ = params.current_group or 0

	self:readStorageFormation()

	if params and params.callback then
		self.callback = params.callback
	end
end

function FairArenaBattleFormationWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initLabel()
	self:initBuffGroup()
	self:initEnemyGroup()
	self:iniPartnerData()
	self:updateForceNum()
	self:updateBuff()
	self:register()

	self.needSound = true
end

function FairArenaBattleFormationWindow:getUIComponent()
	BaseWindow.initWindow(self)

	self.dragPanelTran = self.window_:NodeByName("drag_panel")
	self.dragPanel = self.dragPanelTran:GetComponent(typeof(UIPanel))
	local dragRegion = self.dragPanel.baseClipRegion

	NGUITools.SetPanelConstrainButDontClip(self.dragPanel)

	local winPanel = self.window_:GetComponent(typeof(UIPanel))
	local winRegion = winPanel.baseClipRegion
	dragRegion.z = winRegion.z
	dragRegion.w = winRegion.w
	self.dragPanel.baseClipRegion = dragRegion
	local winTrans = self.window_:NodeByName("main")
	self.topGroup = winTrans:NodeByName("top_group").gameObject
	self.labelWinTitle = self.topGroup:ComponentByName("title_label", typeof(UILabel))
	self.closeBtn = self.topGroup:NodeByName("close_btn").gameObject
	self.tipBtn = self.topGroup:NodeByName("tip_btn").gameObject

	for i = 1, 5 do
		self["buffNode" .. i] = self.topGroup:NodeByName("buffGroup/icon" .. i .. "/buff" .. i).gameObject
	end

	self.selectedGroup = self.topGroup:NodeByName("selected_group")
	self.labelForceNum = self.selectedGroup:ComponentByName("force_num_label", typeof(UILabel))
	self.frontGroup = self.selectedGroup:NodeByName("front_group")
	self.labelFront = self.frontGroup:ComponentByName("front_label", typeof(UILabel))
	self.container1 = self.frontGroup:Find("container_1")
	self.container2 = self.frontGroup:Find("container_2")
	self.backGroup = self.selectedGroup:Find("back_group")
	self.labelBack = self.backGroup:ComponentByName("back_label", typeof(UILabel))
	self.container3 = self.backGroup:Find("container_3")
	self.container4 = self.backGroup:Find("container_4")
	self.container5 = self.backGroup:Find("container_5")
	self.container6 = self.backGroup:Find("container_6")
	self.battleBtn = self.selectedGroup:Find("battle_btn").gameObject
	self.labelBattleBtn = self.selectedGroup:ComponentByName("battle_btn/button_label", typeof(UILabel))
	self.enemyGroup = self.topGroup:NodeByName("enemyGroup").gameObject
	self.textLabel_ = self.enemyGroup:ComponentByName("textLabel_", typeof(UILabel))
	self.enemyPowerLabel_ = self.enemyGroup:ComponentByName("powerGroup/enemyPowerLabel_", typeof(UILabel))

	for i = 1, 5 do
		self["enemyBuffNode" .. i] = self.enemyGroup:NodeByName("buffGroup/icon" .. i .. "/buff" .. i).gameObject
	end

	self.enemyContainer1 = self.enemyGroup:NodeByName("group1/icon1/hero1").gameObject
	self.enemyContainer2 = self.enemyGroup:NodeByName("group1/icon2/hero2").gameObject
	self.enemyContainer3 = self.enemyGroup:NodeByName("group2/icon3/hero3").gameObject
	self.enemyContainer4 = self.enemyGroup:NodeByName("group2/icon4/hero4").gameObject
	self.enemyContainer5 = self.enemyGroup:NodeByName("group2/icon5/hero5").gameObject
	self.enemyContainer6 = self.enemyGroup:NodeByName("group2/icon6/hero6").gameObject
	self.chooseGroup = winTrans:NodeByName("choose_group")
	self.textLabel2_ = self.chooseGroup:ComponentByName("bg_/e:Image/textLabel_", typeof(UILabel))
	self.partnerScrollView = self.chooseGroup:ComponentByName("partner_scroller", typeof(UIScrollView))
	self.partnerRenderPanel = self.chooseGroup:ComponentByName("partner_scroller", typeof(UIPanel))
	self.partnerScroller_uiPanel = self.chooseGroup:ComponentByName("partner_scroller", typeof(UIPanel))
	self.partnerListWarpContent_ = self.chooseGroup:ComponentByName("partner_scroller/partner_container", typeof(MultiRowWrapContent))
	self.heroRoot = self.chooseGroup:Find("hero_root").gameObject
	self.tipsLabel_ = self.chooseGroup:ComponentByName("tipsLabel_", typeof(UILabel))
end

function FairArenaBattleFormationWindow:initLabel()
	self.labelFront.text = __("FRONT_ROW")
	self.labelBack.text = __("BACK_ROW")
	self.labelBattleBtn.text = __("BATTLE_START")
	self.textLabel_.text = __("DEFFORMATION")
	self.textLabel2_.text = __("FAIR_ARENA_TEAM_PARTNER")
	self.tipsLabel_.text = __("FAIR_ARENA_NOTES_PRESS")
end

function FairArenaBattleFormationWindow:initBuffGroup()
	self.buffDataList = {}
	local buffIds = xyd.tables.groupBuffTable:getIds()

	for i, buffId in ipairs(buffIds) do
		table.insert(self.buffDataList, tonumber(buffId))
	end

	table.sort(self.buffDataList)

	local buffs = xyd.models.fairArena:getBuffs()

	for i = 1, #buffs do
		local icon = GroupBuffIcon.new(self["buffNode" .. i])

		icon:SetLocalScale(0.5714285714285714, 0.6, 1)
		icon:setInfo(buffs[i], true, xyd.GroupBuffIconType.FAIR_ARENA)

		UIEventListener.Get(icon.go).onSelect = function (go, isSelect)
			if isSelect then
				self:onClcikBuffNode(buffs[i], 120, true)
			else
				self:clearBuffTips()
			end
		end
	end
end

function FairArenaBattleFormationWindow:initEnemyGroup()
	local data = xyd.models.fairArena:getEnemyInfo()
	local partners = data.partners
	local power = 0
	local groupNum = {
		0,
		0,
		0,
		0,
		0,
		0
	}

	for i = 1, #partners do
		local params = {
			isHeroBook = true,
			scale = 0.8055555555555556,
			isShowSelected = false,
			tableID = partners[i].table_id,
			lev = partners[i].lv,
			grade = partners[i].grade,
			equips = partners[i].equips
		}
		local partner = Partner.new()

		partner:populate(params)

		power = power + partner:getPower()
		local group = partner:getGroup()
		groupNum[group] = groupNum[group] + 1

		function params.callback()
			xyd.WindowManager.get():openWindow("fair_arena_partner_info_window", {
				partner = partner
			})
		end

		local hero = HeroIcon.new(self["enemyContainer" .. i])

		hero:setInfo(params)
	end

	self.enemyPowerLabel_.text = power
	local buffs = data.god_skills

	for i = 1, #buffs do
		local icon = GroupBuffIcon.new(self["enemyBuffNode" .. i])

		icon:SetLocalScale(0.5714285714285714, 0.6, 1)
		icon:setInfo(buffs[i], true, xyd.GroupBuffIconType.FAIR_ARENA)

		UIEventListener.Get(icon.go).onSelect = function (go, isSelect)
			if isSelect then
				self:onClcikBuffNode(buffs[i], 380, true)
			else
				self:clearBuffTips()
			end
		end
	end

	if #partners < 6 then
		return
	end

	local actBuffID = self:getGroupBuffID(groupNum)

	if actBuffID > 0 then
		local enemyGroupBuff = GroupBuffIcon.new(self.enemyBuffNode5)

		enemyGroupBuff:SetLocalScale(0.5714285714285714, 0.5714285714285714, 1)
		enemyGroupBuff:setInfo(actBuffID, true)

		UIEventListener.Get(enemyGroupBuff:getGameObject()).onSelect = function (go, isSelect)
			if isSelect then
				self:onClcikBuffNode(actBuffID, 380)
			else
				self:clearBuffTips()
			end
		end
	end
end

function FairArenaBattleFormationWindow:iniPartnerData()
	local partnerDataList = self:initFairArenaPartnerData()
	self.partnerMultiWrap_ = FixedMultiWrapContent.new(self.partnerScrollView, self.partnerListWarpContent_, self.heroRoot, FairArenaFormationItem, self)
	self.partnerScrollView.enabled = true

	self.partnerMultiWrap_:setInfos(partnerDataList, {})
end

function BattleFormationWindow:initFairArenaPartnerData()
	self.power = 0
	local partnerList = xyd.models.fairArena:getPartners()
	local partnerDataList = {}

	for _, partner in ipairs(partnerList) do
		local partnerInfo = {
			noClick = true,
			tableID = partner:getTableID(),
			lev = partner:getLevel(),
			awake = partner.awake,
			group = partner:getGroup(),
			grade = partner:getGrade(),
			partnerID = partner:getPartnerID(),
			power = partner:getPower()
		}
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

			self:onClickheroIcon(partnerInfo, false, isS.posId)
		else
			table.insert(partnerDataList, data)
		end
	end

	return partnerDataList
end

function FairArenaBattleFormationWindow:register()
	BaseWindow.register(self)

	UIEventListener.Get(self.battleBtn).onClick = handler(self, function ()
		self:onClickBattleBtn()
	end)
	UIEventListener.Get(self.tipBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("battle_tips_window", {})
	end)

	self.eventProxy_:addEventListener(xyd.event.FAIR_ARENA_EQUIP, handler(self, self.updateEquipShow))
end

function FairArenaBattleFormationWindow:updateEquipShow()
	local items = self.partnerMultiWrap_:getItems()

	for i in pairs(items) do
		items[i]:updateShowEquip()
	end

	self:updateTopPartnerEquipShow()
end

function FairArenaBattleFormationWindow:updateTopPartnerEquipShow()
	for posId in pairs(self.copyIconList) do
		local heroIcon = self.copyIconList[posId]

		if heroIcon then
			local partnerInfo = heroIcon:getPartnerInfo()

			if partnerInfo and partnerInfo.partnerID then
				local need_partner_info = xyd.models.fairArena:getPartnerByID(partnerInfo.partnerID)
				local equipID = need_partner_info:getEquipment()[6] or 0

				heroIcon:initEquipId(equipID)
			end
		end
	end
end

function FairArenaBattleFormationWindow:onClickheroIcon(partnerInfo, isChoose, pos, needAnimation, posId, isFriendPartner)
	FairArenaBattleFormationWindow.super.onClickheroIcon(self, partnerInfo, isChoose, pos, needAnimation, posId, isFriendPartner)
	self:updateTopPartnerEquipShow()
end

function FairArenaBattleFormationWindow:updateForceNum()
	local power = 0

	for i, _ in pairs(self.copyIconList) do
		if self.copyIconList[i] then
			local partnerInfo = self.copyIconList[i]:getPartnerInfo()
			local need_partner_info = xyd.models.fairArena:getPartnerByID(partnerInfo.partnerID)
			power = power + need_partner_info:getPower()
		end
	end

	self.labelForceNum.text = power
end

function FairArenaBattleFormationWindow:updateBuff()
	if #self.copyIconList < 6 then
		NGUITools.DestroyChildren(self.buffNode5.transform)

		self.groupBuff = nil

		return false
	end

	local groupNum = {
		0,
		0,
		0,
		0,
		0,
		0
	}

	for i = 1, #self.copyIconList do
		local partnerIcon = self.copyIconList[i]

		if partnerIcon then
			local partnerInfo = partnerIcon:getPartnerInfo()
			local group = partnerInfo.group
			groupNum[group] = groupNum[group] + 1
		end
	end

	local actBuffID = self:getGroupBuffID(groupNum)

	if actBuffID > 0 then
		if not self.groupBuff then
			self.groupBuff = GroupBuffIcon.new(self.buffNode5)

			self.groupBuff:SetLocalScale(0.5714285714285714, 0.5714285714285714, 1)
		end

		self.groupBuff:setInfo(actBuffID, true)

		UIEventListener.Get(self.groupBuff:getGameObject()).onSelect = function (go, isSelect)
			if isSelect then
				self:onClcikBuffNode(actBuffID, 120)
			else
				self:clearBuffTips()
			end
		end
	else
		NGUITools.DestroyChildren(self.buffNode5.transform)

		self.groupBuff = nil
	end
end

function FairArenaBattleFormationWindow:getGroupBuffID(groupNum)
	local actBuffID = 0

	for i = 1, #self.buffDataList do
		local buffId = self.buffDataList[i]
		local groupDataList = xyd.split(xyd.tables.groupBuffTable:getGroupConfig(buffId), "|")
		local type = xyd.tables.groupBuffTable:getType(buffId)
		local isNewAct = true

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

		if isNewAct then
			actBuffID = buffId

			print(actBuffID)

			break
		end
	end

	return actBuffID
end

function FairArenaBattleFormationWindow:onClickBattleBtn()
	if self.battleType ~= xyd.BattleType.PARTNER_STATION then
		SoundManager:playSound(xyd.SoundID.START_BATTLE)
	end

	local formationData = self:getFormationData()
	local partnerParams = formationData.partnerParams
	local formationIds = formationData.formationIds

	if #partnerParams <= 0 then
		xyd.alert(xyd.AlertType.TIPS, __("AT_LEAST_ONE_HERO"))

		return
	end

	local formation = {
		partners = formationIds
	}

	self:saveLocalformation(formation)

	local msg = messages_pb.fair_arena_battle_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_FAIR_ARENA

	xyd.getFightPartnerMsg(msg.partners, partnerParams)
	xyd.Backend.get():request(xyd.mid.FAIR_ARENA_BATTLE, msg)
	xyd.closeWindow("fair_arena_battle_formation_window")
	xyd.closeWindow("fair_arena_enemy_formation_window")
end

function FairArenaBattleFormationWindow:longPressIcon(copyIcon)
	local info = copyIcon:getPartnerInfo()
	local list = {}

	if info.dragScrollView then
		list = xyd.models.fairArena:getPartnerIds()
	else
		local i = 1

		for _, id in pairs(self.nowPartnerList) do
			list[i] = id
			i = i + 1
		end
	end

	xyd.WindowManager.get():openWindow("fair_arena_partner_info_window", {
		partnerID = info.partnerID,
		list = list
	})
end

function FairArenaBattleFormationWindow:readStorageFormation()
	local dbVal = xyd.db.formation:getValue(self.battleType)

	if not dbVal then
		return false
	end

	local data = require("cjson").decode(dbVal)

	if not data.partners then
		return false
	end

	local tmpPartnerList = data.partners
	local hasSelect = {}

	for i = #tmpPartnerList, 1, -1 do
		local sPartnerID = tonumber(tmpPartnerList[i])
		self.nowPartnerList[i] = sPartnerID
	end

	return true
end

function FairArenaBattleFormationWindow:playOpenAnimation(callback)
	if callback then
		callback()
	end

	self.topGroup:SetLocalPosition(0, 810, 0)
	self.chooseGroup:SetLocalPosition(0, -1090, 0)

	self.top_tween = self:getSequence()

	self.top_tween:Append(self.topGroup.transform:DOLocalMoveY(234, 0.5))
	self.top_tween:AppendCallback(function ()
		self:setWndComplete()

		if self.top_tween then
			self.top_tween:Kill(true)
		end
	end)

	self.down_tween = self:getSequence()

	self.down_tween:Append(self.chooseGroup.transform:DOLocalMoveY(-265, 0.5))
	self.down_tween:AppendCallback(function ()
		if self.down_tween then
			self.down_tween:Kill(true)
		end
	end)
end

function FairArenaBattleFormationWindow:onClcikBuffNode(buffID, contenty, isFairType)
	local params = {
		buffID = buffID,
		contenty = contenty
	}

	if isFairType then
		params.type = xyd.GroupBuffIconType.FAIR_ARENA
	end

	local win = xyd.getWindow("group_buff_detail_window")

	if win then
		win:update(params)
	else
		xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
	end
end

function FairArenaBattleFormationWindow:clearBuffTips()
	xyd.closeWindow("group_buff_detail_window")
end

return FairArenaBattleFormationWindow
