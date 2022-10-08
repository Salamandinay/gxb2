local BaseWindow = import(".BaseWindow")
local GuildNewWarFightWindow = class("GuildNewWarFightWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")
local WindowTop = import("app.components.WindowTop")

function GuildNewWarFightWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.data = params.data
	self.nodeID = params.nodeID
	self.flagID = params.flagID
end

function GuildNewWarFightWindow:initWindow()
	GuildNewWarFightWindow.super.initWindow(self)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_NEW_WAR)
	self.pIcon = {}
	self.iconsSelf = {}
	self.iconsEnemy = {}

	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function GuildNewWarFightWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelWindowTitle = self.groupAction:ComponentByName("labelWindowTitle", typeof(UILabel))
	self.btnClose = self.groupAction:NodeByName("btnClose").gameObject
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.iconPos1 = self.topGroup:NodeByName("iconPos1").gameObject
	self.labelName1 = self.topGroup:ComponentByName("labelName1", typeof(UILabel))
	self.imgVS = self.topGroup:ComponentByName("imgVS", typeof(UISprite))
	self.iconPos2 = self.topGroup:NodeByName("iconPos2").gameObject
	self.labelName2 = self.topGroup:ComponentByName("labelName2", typeof(UILabel))
	self.bottomGroup = self.groupAction:NodeByName("bottomGroup").gameObject
	self.labelTips = self.bottomGroup:ComponentByName("labelTips", typeof(UILabel))
	self.labelLimit = self.bottomGroup:ComponentByName("labelLimit", typeof(UILabel))
	self.btnSure = self.bottomGroup:NodeByName("btnSure").gameObject
	self.labelSure = self.btnSure:ComponentByName("labelSure", typeof(UILabel))
	self.selectGroup = self.bottomGroup:NodeByName("selectGroup").gameObject
	self.midGroup = self.groupAction:NodeByName("midGroup").gameObject

	for i = 1, 3 do
		self["vsGroup" .. i] = self.midGroup:NodeByName("vsGroup" .. i).gameObject
		self["labelTitle" .. i] = self["vsGroup" .. i]:ComponentByName("labelTitle", typeof(UILabel))
		self["selfGroup" .. i] = self["vsGroup" .. i]:NodeByName("selfGroup").gameObject
		self["btnDetail" .. i] = self["selfGroup" .. i]:NodeByName("btnDetail").gameObject
		self["labelPowerSelf" .. i] = self["selfGroup" .. i]:ComponentByName("labelPower", typeof(UILabel))
		self["itemGoupSelf" .. i] = self["selfGroup" .. i]:NodeByName("itemGoup").gameObject
		self["ennemyGroup" .. i] = self["vsGroup" .. i]:NodeByName("ennemyGroup").gameObject
		self["labelPowerEnnemy" .. i] = self["ennemyGroup" .. i]:ComponentByName("labelPower", typeof(UILabel))
		self["itemGoupEnnemy" .. i] = self["ennemyGroup" .. i]:NodeByName("itemGoup").gameObject
	end

	self.dragPanel = self.groupAction:ComponentByName("dargPanel", typeof(UIPanel))
end

function GuildNewWarFightWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GUILD_NEW_WAR_FIGHT, function (event)
		local leftTime = self.activityData:getLeftAttackTime()
		local limitTime = xyd.tables.miscTable:split2Cost("guild_new_war_attack_times", "value", "|")[2]
		self.labelLimit.text = __("GUILD_NEW_WAR_TEXT38", leftTime, limitTime)
		local leftTime = self.activityData:getLeftAttackTime()

		self.selectNum_:setMaxNum(leftTime)
		self.selectNum_:setCurNum(1)
		self.selectNum_:changeCurNum()
	end)

	UIEventListener.Get(self.btnClose.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnSure.gameObject).onClick = function ()
		if self.fightNum_ == 0 then
			return
		end

		local teams = self.activityData:getPvPBattleFormation().teams

		for i = 1, 3 do
			local tmpPartner = teams[i].partners
			local havePartner = false

			for j = 1, 6 do
				if tmpPartner[j] ~= nil then
					local partnerID = tmpPartner[j].partner_id or tmpPartner[j].partnerID
					local partner = nil

					if partnerID then
						partner = xyd.models.slot:getPartner(partnerID)
					end

					if partner then
						havePartner = true
					end
				end
			end

			if not havePartner then
				xyd.alertTips(__("GUILD_NEW_WAR_TEXT89"))
				xyd.WindowManager.get():openWindow("arena_3v3_battle_formation_window", {
					showSkip = true,
					battleType = xyd.BattleType.GUILD_NEW_WAR,
					formation = self.activityData:getPvPBattleFormation(),
					skipState = self.activityData:isSkipBattle(),
					btnSkipCallback = function (flag)
						self.activityData:setSkipBattle(flag)
					end
				})

				return
			end
		end

		if self.activityData:getLeftAttackTime() < self.fightNum_ then
			xyd.alertTips(__("GUILD_NEW_WAR_TIPS04"))

			return
		end

		if self.fightNum_ == 1 then
			self.activityData:reqFight(self.nodeID, self.flagID)
		else
			self.activityData:reqMultyFight(self.nodeID, self.flagID, self.fightNum_)
			xyd.WindowManager.get():openWindow("guild_new_war_record_window")
		end
	end

	for i = 1, 3 do
		UIEventListener.Get(self["btnDetail" .. i].gameObject).onClick = function ()
			xyd.WindowManager.get():openWindow("arena_3v3_battle_formation_window", {
				showSkip = true,
				battleType = xyd.BattleType.GUILD_NEW_WAR,
				formation = self.activityData:getPvPBattleFormation(),
				skipState = self.activityData:isSkipBattle(),
				btnSkipCallback = function (flag)
					self.activityData:setSkipBattle(flag)
				end
			})
		end

		UIEventListener.Get(self["selfGroup" .. i]).onDragStart = function (go)
			self:onStartDrag(go, i)
		end

		UIEventListener.Get(self["selfGroup" .. i]).onDrag = function (go, delta)
			self:onDrag(go, delta, i)
		end

		UIEventListener.Get(self["selfGroup" .. i]).onDragEnd = function (go)
			self:onEndDrag(go, i)
		end
	end
end

function GuildNewWarFightWindow:setTitle()
	self.labelWindowTitle.text = __("GUILD_NEW_WAR_TEXT48")
end

function GuildNewWarFightWindow:layout()
	self.attackFormationData = self.activityData:getPvPBattleFormation()
	self.labelWindowTitle.text = __("GUILD_NEW_WAR_TEXT48")
	self.labelTips.text = __("GUILD_NEW_WAR_TEXT49")
	self.labelSure.text = __("GUILD_NEW_WAR_TEXT50")
	local leftTime = self.activityData:getLeftAttackTime()
	local limitTime = xyd.tables.miscTable:split2Cost("guild_new_war_attack_times", "value", "|")[2]
	self.labelLimit.text = __("GUILD_NEW_WAR_TEXT38", leftTime, limitTime)
	self.fightNum_ = 1

	local function callback(num)
		self.fightNum_ = num
	end

	local SelectNum = import("app.components.SelectNum")
	self.selectNum_ = SelectNum.new(self.selectGroup, "default")

	self.selectNum_:setInfo({
		minNum = 1,
		curNum = 1,
		maxNum = leftTime,
		callback = callback
	})
	self.selectNum_:setFontSize(26, 26)
	self.selectNum_:setKeyboardPos(0, -180)
	self.selectNum_:setMaxNum(leftTime)
	self.selectNum_:setCurNum(1)
	self.selectNum_:changeCurNum()
	self.selectNum_:setSelectBGSize(200, 40)
	self:updateTopInfo()
	self:updateMidGroup()
end

function GuildNewWarFightWindow:updateTopInfo()
	local data = self.data
	local infos = {
		data.selfInfo,
		data.enemyInfo
	}

	for i = 1, 2 do
		local info = infos[i]
		self.pIcon[i] = xyd.getItemIcon({
			noClick = true,
			scale = 1.0555555555555556,
			uiRoot = self["iconPos" .. i],
			avatarID = info.playerInfo.avatar_id,
			avatar_frame_id = info.playerInfo.avatar_frame_id,
			lev = info.playerInfo.lev
		}, xyd.ItemIconType.ADVANCE_ICON)
		self["labelName" .. i].text = info.playerInfo.playerName or info.playerInfo.player_name
	end
end

function GuildNewWarFightWindow:updateMidGroup()
	self.attackFormationData = self.activityData:getPvPBattleFormation()
	self.enemyFormationData = self.activityData:getEnemyFormationData(self.data.enemyInfo.playerInfo.player_id)

	if not self.enemyFormationData then
		return
	end

	local data = self.data
	local infos = {
		data.selfInfo,
		data.enemyInfo
	}

	for i = 1, 3 do
		self["labelTitle" .. i].text = __("GUILD_NEW_WAR_TEXT67", i)
		local power = 0

		for j = 1, 6 do
			if self.attackFormationData.teams[i].partners[j] then
				if self.attackFormationData.teams[i].partners[j].partnerID then
					if self.attackFormationData.teams[i].partners[j]:getPower() == 0 then
						self.attackFormationData.teams[i].partners[j]:updateAttrs()
					end

					power = power + self.attackFormationData.teams[i].partners[j]:getPower()
				elseif self.attackFormationData.teams[i].partners[j].partner_id then
					power = power + self.attackFormationData.teams[i].partners[j].power
				end
			end
		end

		self["labelPowerSelf" .. i].text = power
		power = 0

		for j = 1, 6 do
			if self.enemyFormationData.teams[i].partners[j] and self.enemyFormationData.teams[i].partners[j].power then
				power = power + self.enemyFormationData.teams[i].partners[j].power
			end
		end

		self["labelPowerEnnemy" .. i].text = power

		if not self.iconsSelf[i] then
			self.iconsSelf[i] = {}
		end

		if not self.iconsEnemy[i] then
			self.iconsEnemy[i] = {}
		end

		self["selfGroup" .. i]:SetActive(false)
		self:waitForFrame(1, function ()
			self["selfGroup" .. i]:SetActive(true)
		end)

		for j = 1, 6 do
			local beginX = 23
			local infoSelfPartner = self.attackFormationData.teams[i].partners[j]
			local partnerID = nil

			if infoSelfPartner then
				partnerID = infoSelfPartner.partner_id or infoSelfPartner.partnerID
			end

			local partner = nil

			if partnerID then
				partner = xyd.models.slot:getPartner(partnerID)
			end

			if partner then
				local params1 = infoSelfPartner
				params1.uiRoot = self["itemGoupSelf" .. i]
				params1.scale = 0.4444444444444444
				params1.noClick = true

				if self.iconsSelf[i][j] then
					self.iconsSelf[i][j]:SetActive(true)
					self.iconsSelf[i][j]:setInfo(params1)
				else
					self.iconsSelf[i][j] = xyd.getItemIcon(params1, xyd.ItemIconType.ADVANCE_ICON)
					local offsetDepth = self["itemGoupSelf" .. i]:ComponentByName("", typeof(UIWidget)).depth
				end
			elseif self.iconsSelf[i][j] then
				self.iconsSelf[i][j]:SetActive(false)
			end

			if self.iconsSelf[i][j] then
				self.iconsSelf[i][j]:getRoot():X(beginX + (j - 1) * 52)
			end

			beginX = 23
			local infoEnemyPartner = self.enemyFormationData.teams[i].partners[j]

			if infoEnemyPartner then
				local params2 = infoEnemyPartner
				params2.uiRoot = self["itemGoupEnnemy" .. i]
				params2.scale = 0.4444444444444444
				params2.noClick = true

				if self.iconsEnemy[i][j] then
					self.iconsEnemy[i][j]:SetActive(true)
					self.iconsEnemy[i][j]:setInfo(params2)
				else
					self.iconsEnemy[i][j] = xyd.getItemIcon(params2, xyd.ItemIconType.ADVANCE_ICON)
				end
			elseif self.iconsEnemy[i][j] then
				self.iconsEnemy[i][j]:SetActive(false)
			end

			if self.iconsEnemy[i][j] then
				self.iconsEnemy[i][j]:getRoot():X(beginX + (j - 1) * 52)
			end
		end
	end
end

function GuildNewWarFightWindow:onStartDrag(go, oldIndex)
	if self.isDraging then
		return
	end

	self.isDraging = true
	local trans = go.transform
	self.oldDragIndex = oldIndex

	trans:SetParent(self.dragPanel.transform)
	go:SetActive(false)
	go:SetActive(true)
end

function GuildNewWarFightWindow:onDrag(go, delta, oldIndex)
	if not self.isDraging then
		return
	end

	local pos = go.transform.localPosition
	go.transform.localPosition = Vector3(pos.x + delta.x / xyd.Global.screenToLocalAspect(), pos.y + delta.y / xyd.Global.screenToLocalAspect(), pos.z)
end

function GuildNewWarFightWindow:onEndDrag(go, oldIndex)
	if not self.isDraging then
		return
	end

	local newIndex = -1
	local targetGo = nil

	for i = 1, 3 do
		if i ~= oldIndex then
			local targetRoot = self["selfGroup" .. i]

			targetRoot.transform:SetParent(self.dragPanel.transform)

			local goPos = go.transform.localPosition
			local targetRootPos = targetRoot.transform.localPosition

			if math.abs(goPos.x - targetRootPos.x) <= 161.5 and math.abs(goPos.y - targetRootPos.y) <= 58.5 then
				newIndex = i
				targetGo = targetRoot

				break
			end
		end
	end

	for i = 1, 3 do
		self["selfGroup" .. i].transform:SetParent(self["vsGroup" .. i].transform)
	end

	for i = 1, 3 do
		self["selfGroup" .. i]:SetActive(false)
		self["selfGroup" .. i]:SetActive(true)
	end

	if newIndex > 0 then
		local oldParent = self["vsGroup" .. oldIndex]
		local newParent = self["vsGroup" .. newIndex]

		go.transform:SetParent(newParent.transform)
		targetGo.transform:SetParent(oldParent.transform)

		local formation = self.activityData:getPvPBattleFormation()
		local temp = formation.teams[oldIndex]
		formation.teams[oldIndex] = formation.teams[newIndex]
		formation.teams[newIndex] = temp
		local temp = self.iconsSelf[oldIndex]
		self.iconsSelf[oldIndex] = self.iconsSelf[newIndex]
		self.iconsSelf[newIndex] = temp

		self:saveFormation(formation)
	end

	self.isDraging = false

	self:resetSelfGroup()
end

function GuildNewWarFightWindow:resetSelfGroup()
	self:getUIComponent()

	for i = 1, 3 do
		self["selfGroup" .. i]:X(-160)
		self["selfGroup" .. i]:Y(0)
		UIEventListener.Get(self["selfGroup" .. i]):Clear()

		UIEventListener.Get(self["selfGroup" .. i]).onDragStart = function (go)
			self:onStartDrag(go, i)
		end

		UIEventListener.Get(self["selfGroup" .. i]).onDrag = function (go, delta)
			self:onDrag(go, delta, i)
		end

		UIEventListener.Get(self["selfGroup" .. i]).onDragEnd = function (go)
			self:onEndDrag(go, i)
		end
	end
end

function GuildNewWarFightWindow:saveFormation(formation)
	local formationData = {
		pet_ids = {
			0,
			0,
			0,
			0
		},
		partners = {}
	}

	for i = 1, 3 do
		for j = 1, 6 do
			if formation.teams[i].partners[j] then
				formationData.partners[tostring((i - 1) * 6 + j)] = formation.teams[i].partners[j].partnerID
			end
		end

		if formation.teams[i].pet then
			formationData.pet_ids[i + 1] = formation.teams[i].pet.petID
		end
	end

	xyd.db.formation:setValue({
		key = xyd.BattleType.GUILD_NEW_WAR,
		value = cjson.encode(formationData)
	})
end

return GuildNewWarFightWindow
