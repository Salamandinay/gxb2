local BaseWindow = import(".BaseWindow")
local AcademyAssessmentEnemyDetailWindow = class("AcademyAssessmentEnemyDetailWindow", BaseWindow)
local ItemIcon = import("app.components.ItemIcon")
local HeroIcon = import("app.components.HeroIcon")
local Monster = import("app.models.Monster")

function AcademyAssessmentEnemyDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.table_id = params.table_id
	self.battleType = params.battle_type
	self.stageID = params.id
	self.lev = params.lev
end

function AcademyAssessmentEnemyDetailWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:register()
end

function AcademyAssessmentEnemyDetailWindow:getUIComponent()
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

function AcademyAssessmentEnemyDetailWindow:setLayout()
	self.labelText02.text = __("TOWER_TEXT01")
	self.labelCampaignIndex.text = __("TOWER_TEXT03", self.lev)

	if self.battleType and self.battleType > 0 then
		xyd.setUISpriteAsync(self.bgImg, nil, "shrine_enemy_bg", nil, , true)
		self.bgImg.transform:Y(-7)

		self.bgImg.width = 638
		self.bgImg.height = 254

		self.closeBtn.transform:Y(-38)
	else
		xyd.setUISpriteAsync(self.bgImg, nil, "tower_detailbg", nil, , true)

		self.bgImg.width = 700
		self.bgImg.height = 300
	end

	self:setMonsterDisplay()
end

function AcademyAssessmentEnemyDetailWindow:setMonsterDisplay()
	local monsters = xyd.tables.battleTable:getMonsters(self.stageID)
	local table = nil

	if self.battleType and self.battleType == 1 then
		table = xyd.tables.shrineHurdleBattleTable
	elseif self.battleType and self.battleType == 2 then
		table = xyd.tables.shrineHurdleBossTable
	end

	if table then
		local battle_id = table:getBattleId(self.table_id)
		monsters = xyd.tables.battleTable:getMonsters(battle_id)
	end

	for i = 1, #monsters do
		local tableID = monsters[i]
		local id = xyd.tables.monsterTable:getPartnerLink(tableID)
		local lev = xyd.tables.monsterTable:getShowLev(tableID)
		local icon = HeroIcon.new(self.groupMonster)
		local params = {
			noClick = true,
			tableID = id,
			lev = lev
		}

		if self.battleType and self.battleType == 1 then
			local partner = Monster.new()

			partner:populateWithTableID(tableID)

			partner.noClick = false
			partner.hide_attr = true
			partner.tableID = tableID

			icon:setInfo(partner)
		else
			icon:setInfo(params)
		end

		local scale = 0.7962962962962963

		icon.go:SetLocalScale(scale, scale, scale)
	end

	self.groupMonsterGrid:Reposition()
end

function AcademyAssessmentEnemyDetailWindow:register()
	AcademyAssessmentEnemyDetailWindow.super.register(self)
end

return AcademyAssessmentEnemyDetailWindow
