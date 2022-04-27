local ExploreAdventurePrepareWindow = class("ExploreAdventurePrepareWindow", import(".BaseWindow"))
local HeroIcon = import("app.components.HeroIcon")
local Monster = import("app.models.Monster")

function ExploreAdventurePrepareWindow:ctor(name, params)
	ExploreAdventurePrepareWindow.super.ctor(self, name, params)

	self.eventID = params.eventID
	self.battleID = params.battleID
	self.lv = params.lv
end

function ExploreAdventurePrepareWindow:initWindow()
	self:getUIComponent()
	self:layout()

	UIEventListener.Get(self.btnBattle).onClick = handler(self, self.prepareBattle)
end

function ExploreAdventurePrepareWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.labelBattlePower = groupAction:ComponentByName("top/labelBattlePower", typeof(UILabel))
	self.groupMonster = groupAction:ComponentByName("top/groupMonster", typeof(UIGrid))
	self.groupItems = groupAction:ComponentByName("top/groupItems", typeof(UIGrid))
	self.labelAward = groupAction:ComponentByName("top/groupReward/labelAward", typeof(UILabel))
	self.labelTitle = groupAction:ComponentByName("top/imgTitle/labelTitle", typeof(UILabel))
	self.btnBattle = groupAction:NodeByName("bottom/btnBattle").gameObject
	self.labelBattle = self.btnBattle:ComponentByName("labelBattle", typeof(UILabel))
	self.effectNode = groupAction:NodeByName("top/effectNode").gameObject
end

function ExploreAdventurePrepareWindow:layout()
	self.labelTitle.text = __("TRAVEL_MAIN_TEXT31")

	if xyd.Global.lang == "fr_fr" then
		self.labelTitle.fontSize = 22
	end

	self.labelAward.text = __("TRAVEL_MAIN_TEXT33")
	self.labelBattle.text = __("TOWER_TEXT04")
	local dropboxID = xyd.tables.adventureEventTable:getRewards(self.eventID, self.lv)
	local dropList = xyd.tables.dropboxShowTable:getIdsByBoxId(dropboxID).list

	for i = 1, #dropList do
		local item = xyd.tables.dropboxShowTable:getItem(dropList[i])

		xyd.getItemIcon({
			scale = 0.8148148148148148,
			itemID = item[1],
			uiRoot = self.groupItems.gameObject
		})
	end

	self.groupItems:Reposition()

	local monsters = xyd.tables.battleTable:getMonsters(self.battleID)
	local power = 0

	for i = 1, #monsters do
		local tableID = monsters[i]
		local id = xyd.tables.monsterTable:getPartnerLink(tableID)
		local itemID = xyd.tables.monsterTable:getSkin(tableID)
		local lev = xyd.tables.exploreAdventureTable:getEnemyLv(self.lv)
		local icon = HeroIcon.new(self.groupMonster.gameObject)

		icon:setInfo({
			scale = 0.7962962962962963,
			is_monster = true,
			noClick = true,
			tableID = id,
			lev = lev,
			skin_id = itemID
		})

		local mon = Monster.new()

		mon:populateWithTableID(tableID, {
			lev = lev
		})

		power = power + mon:getPower()
	end

	self.labelBattlePower.text = power

	self.groupMonster:Reposition()

	local partnerID = xyd.tables.monsterTable:getPartnerLink(monsters[1])
	local modelID = xyd.tables.partnerTable:getModelID(partnerID)
	local name = xyd.tables.modelTable:getModelName(modelID)
	local scale = xyd.tables.modelTable:getScale(modelID)
	local effect = xyd.Spine.new(self.effectNode)

	effect:setInfo(name, function ()
		effect:SetLocalScale(-scale, scale, scale)
		effect:play("attack", 1, 1, function ()
			effect:play("idle", 0)
		end)
	end)
end

function ExploreAdventurePrepareWindow:prepareBattle()
	local fightParams = {
		battleType = xyd.BattleType.EXPLORE_ADVENTURE,
		showSkip = xyd.tables.miscTable:getNumber("travel_quick_limit", "value") <= self.lv,
		skipState = xyd.checkCondition(tonumber(xyd.db.misc:getValue("explore_adventure_skip_report")) == 1, true, false),
		btnSkipCallback = function (flag)
			local valuedata = xyd.checkCondition(flag, 1, 0)

			xyd.db.misc:setValue({
				key = "explore_adventure_skip_report",
				value = valuedata
			})
		end
	}

	xyd.WindowManager.get():openWindow("adventure_battle_formation_window", fightParams)
end

return ExploreAdventurePrepareWindow
