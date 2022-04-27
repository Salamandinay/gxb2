local BaseWindow = import(".BaseWindow")
local TimeCloisterBattleEnemyDetailWindow = class("TimeCloisterBattleEnemyDetailWindow", BaseWindow)
local HeroIcon = import("app.components.HeroIcon")

function TimeCloisterBattleEnemyDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.stageID = params.stageID
	self.monsters = params.monsters
	self.cloister = params.cloister
end

function TimeCloisterBattleEnemyDetailWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:register()
end

function TimeCloisterBattleEnemyDetailWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupMain = trans:NodeByName("groupAction").gameObject
	local top = self.groupMain:NodeByName("top").gameObject
	self.closeBtn = top:NodeByName("closeBtn").gameObject
	self.labelCampaignIndex = top:ComponentByName("labelCampaignIndex", typeof(UILabel))
	self.groupMonster = top:NodeByName("groupMonster").gameObject
	self.groupMonsterGrid = self.groupMonster:GetComponent(typeof(UIGrid))
	self.labelText02 = top:ComponentByName("groupEnemy/labelText02", typeof(UILabel))
end

function TimeCloisterBattleEnemyDetailWindow:setLayout()
	local ids = xyd.tables.timeCloisterBattleTable:getIdsByCloister(self.cloister)
	self.labelText02.text = __("TOWER_TEXT01")
	self.labelCampaignIndex.text = __("TOWER_TEXT03", self.stageID - (ids[1] - 1))

	self:setMonsterDisplay()
end

function TimeCloisterBattleEnemyDetailWindow:setMonsterDisplay()
	local monsters = xyd.tables.battleTable:getMonsters(self.monsters)

	for i = 1, #monsters do
		local tableID = monsters[i]
		local id = xyd.tables.monsterTable:getPartnerLink(tableID)
		local lev = xyd.tables.monsterTable:getShowLev(tableID)
		local icon = HeroIcon.new(self.groupMonster)

		icon:setInfo({
			noClick = true,
			tableID = id,
			lev = lev
		})

		local scale = 0.7962962962962963

		icon.go:SetLocalScale(scale, scale, scale)
	end

	self.groupMonsterGrid:Reposition()
end

function TimeCloisterBattleEnemyDetailWindow:register()
	TimeCloisterBattleEnemyDetailWindow.super.register(self)
end

return TimeCloisterBattleEnemyDetailWindow
