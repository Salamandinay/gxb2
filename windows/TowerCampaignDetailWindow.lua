local BaseWindow = import(".BaseWindow")
local TowerCampaignDetailWindow = class("TowerCampaignDetailWindow", BaseWindow)
local ItemIcon = import("app.components.ItemIcon")
local HeroIcon = import("app.components.HeroIcon")

function TowerCampaignDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.stageID = params.id
	self.backpack = xyd.models.backpack
	self.type = params.type or xyd.BattleType.TOWER
end

function TowerCampaignDetailWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:register()
end

function TowerCampaignDetailWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupMain = trans:NodeByName("groupAction").gameObject
	local top = self.groupMain:NodeByName("top").gameObject
	local bottom = self.groupMain:NodeByName("bottom").gameObject
	self.closeBtn = top:NodeByName("closeBtn").gameObject
	self.labelCampaignIndex = top:ComponentByName("labelCampaignIndex", typeof(UILabel))
	self.labelBattlePower = top:ComponentByName("labelBattlePower", typeof(UILabel))
	self.btnVideo = top:NodeByName("btnVideo").gameObject
	self.groupMonster = top:NodeByName("groupMonster").gameObject
	self.groupMonsterGrid = self.groupMonster:GetComponent(typeof(UIGrid))
	self.groupItems = top:NodeByName("groupItems").gameObject
	self.groupItemsGrid = self.groupItems:GetComponent(typeof(UIGrid))
	self.btnBattle = bottom:NodeByName("btnBattle").gameObject
	self.btnBattleLabel = self.btnBattle:ComponentByName("button_label", typeof(UILabel))
	self.groupReward = top:NodeByName("groupReward").gameObject
	self.labelText03 = top:ComponentByName("groupReward/labelText03", typeof(UILabel))
	self.labelText02 = top:ComponentByName("groupEnemy/labelText02", typeof(UILabel))
end

function TowerCampaignDetailWindow:setLayout()
	self.labelText02.text = __("TOWER_TEXT01")
	self.labelText03.text = __("TOWER_TEXT02")
	self.labelCampaignIndex.text = __("TOWER_TEXT03", self.stageID)
	self.labelBattlePower.text = xyd.tables.towerTable:getBattlePower(self.stageID)

	self:setMonsterDisplay()
	self:setRewardDisplay()
	xyd.setBgColorType(self.btnBattle, xyd.ButtonBgColorType.blue_btn_70_70)

	self.btnBattleLabel.text = __("TOWER_TEXT04")

	self.btnVideo:SetActive(self.type ~= xyd.BattleType.TOWER_PRACTICE)
end

function TowerCampaignDetailWindow:setMonsterDisplay()
	local battleID = xyd.tables.towerTable:getBattleID(self.stageID)
	local monsters = xyd.tables.battleTable:getMonsters(battleID)

	for i = 1, #monsters do
		local tableID = monsters[i]
		local id = xyd.tables.monsterTable:getPartnerLink(tableID)
		local itemID = xyd.tables.monsterTable:getSkin(tableID)
		local lev = xyd.tables.monsterTable:getShowLev(tableID)
		local icon = HeroIcon.new(self.groupMonster)

		icon:setInfo({
			is_monster = true,
			noClick = true,
			tableID = id,
			lev = lev,
			skin_id = itemID
		})

		local scale = 0.7962962962962963

		icon.go:SetLocalScale(scale, scale, scale)
	end

	self.groupMonsterGrid:Reposition()
end

function TowerCampaignDetailWindow:setRewardDisplay()
	if self.type == xyd.BattleType.TOWER_PRACTICE then
		self.groupReward:SetActive(false)
		self.groupItems:SetActive(false)

		self.groupMain:GetComponent(typeof(UIWidget)).height = 558

		return
	end

	local rewards = xyd.tables.towerTable:getReward(self.stageID)

	for i = 1, #rewards do
		local tableID = rewards[i][1]
		local num = rewards[i][2]
		local params = {
			scale = 0.9074074074074074,
			itemID = tableID,
			num = num,
			uiRoot = self.groupItems
		}

		xyd.getItemIcon(params)
	end

	self.groupItemsGrid:Reposition()
end

function TowerCampaignDetailWindow:register()
	TowerCampaignDetailWindow.super.register(self)

	UIEventListener.Get(self.btnVideo).onClick = function ()
		self:openVideo()
	end

	UIEventListener.Get(self.btnBattle).onClick = function ()
		self:requestBattle()
	end

	self.eventProxy_:addEventListener(xyd.event.TOWER_FIGHT, handler(self, self.onClickCloseButton))
end

function TowerCampaignDetailWindow:openVideo()
	xyd.WindowManager.get():openWindow("tower_video_window", {
		stage = self.stageID
	})
end

function TowerCampaignDetailWindow:requestBattle()
	if self.type ~= xyd.BattleType.TOWER_PRACTICE and xyd.isItemAbsence(xyd.ItemID.TOWER_TICKET, 1) then
		return
	end

	local skipStage = tonumber(xyd.tables.miscTable:getVal("tower_skipfight_floor"))
	local showSkip = xyd.checkCondition(skipStage <= self.stageID, true, false)

	if self.type == xyd.BattleType.TOWER_PRACTICE then
		showSkip = true
	end

	local fightParams = {
		mapType = xyd.MapType.TOWER,
		stageId = self.stageID,
		battleType = self.type,
		showSkip = showSkip,
		skipState = xyd.checkCondition(tonumber(xyd.db.misc:getValue("tower_skip_report")) == 1, true, false),
		btnSkipCallback = function (flag)
			local valuedata = xyd.checkCondition(flag, 1, 0)

			xyd.db.misc:setValue({
				key = "tower_skip_report",
				value = valuedata
			})
		end
	}

	xyd.WindowManager.get():openWindow("battle_formation_window", fightParams)
end

return TowerCampaignDetailWindow
