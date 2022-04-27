local BaseWindow = import(".BaseWindow")
local ShrineHurdleEnemyDetailWindow = class("ShrineHurdleEnemyDetailWindow", BaseWindow)
local ItemIcon = import("app.components.ItemIcon")
local HeroIcon = import("app.components.HeroIcon")

function ShrineHurdleEnemyDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.lev = params.lev
	self.battleID_ = params.battle_id
end

function ShrineHurdleEnemyDetailWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:register()
end

function ShrineHurdleEnemyDetailWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupMain = trans:NodeByName("groupAction").gameObject
	self.bgImg = self.groupMain:ComponentByName("e:Image", typeof(UISprite))
	local top = self.groupMain:NodeByName("top").gameObject
	self.closeBtn = top:NodeByName("closeBtn").gameObject
	self.labelCampaignIndex = top:ComponentByName("labelCampaignIndex", typeof(UILabel))
	self.groupMonster = top:NodeByName("groupMonster").gameObject
	self.groupMonsterGrid = self.groupMonster:GetComponent(typeof(UIGrid))
	self.labelText02 = top:ComponentByName("groupEnemy/labelText02", typeof(UILabel))
end

function ShrineHurdleEnemyDetailWindow:setLayout()
	self.labelText02.text = __("TOWER_TEXT01")
	self.labelCampaignIndex.text = __("TOWER_TEXT03", self.lev)

	self:setMonsterDisplay()
end

function ShrineHurdleEnemyDetailWindow:setMonsterDisplay()
	local monsters = xyd.tables.battleTable:getMonsters(self.battleID_)

	for i = 1, #monsters do
		local tableID = monsters[i]
		local id = xyd.tables.monsterTable:getPartnerLink(tableID)
		local lev = xyd.tables.monsterTable:getShowLev(tableID)
		local icon = HeroIcon.new(self.groupMonster)

		icon:setInfo({
			isEntrance = true,
			noClick = false,
			tableID = id,
			lev = lev
		})

		local scale = 0.7962962962962963

		icon.go:SetLocalScale(scale, scale, scale)
	end

	self.groupMonsterGrid:Reposition()
end

function ShrineHurdleEnemyDetailWindow:register()
	ShrineHurdleEnemyDetailWindow.super.register(self)
end

return ShrineHurdleEnemyDetailWindow
