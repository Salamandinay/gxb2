local BaseWindow = import(".BaseWindow")
local ActivityBeachIslandFightWindow = class("ActivityBeachIslandFightWindow", BaseWindow)
local ItemIcon = import("app.components.ItemIcon")
local HeroIcon = import("app.components.HeroIcon")

function ActivityBeachIslandFightWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.stageID = params.id
	self.challengeState = params.challenges or {
		0,
		0,
		0
	}
	self.backpack = xyd.models.backpack
end

function ActivityBeachIslandFightWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:register()
end

function ActivityBeachIslandFightWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupMain = trans:NodeByName("groupAction").gameObject
	local top = self.groupMain:NodeByName("top").gameObject
	local bottom = self.groupMain:NodeByName("bottom").gameObject
	self.labelCampaignIndex = top:ComponentByName("labelCampaignIndex", typeof(UILabel))
	self.groupMonster = top:NodeByName("groupMonster").gameObject
	self.groupMonsterGrid = self.groupMonster:GetComponent(typeof(UIGrid))
	self.groupItems = top:NodeByName("groupItems").gameObject
	self.groupItemsGrid = self.groupItems:GetComponent(typeof(UIGrid))
	self.btnBattle = bottom:NodeByName("btnBattle").gameObject
	self.btnBattleLabel = self.btnBattle:ComponentByName("button_label", typeof(UILabel))
	self.groupReward = top:NodeByName("groupReward").gameObject
	self.labelText03 = top:ComponentByName("groupReward/labelText03", typeof(UILabel))
	self.labelText02 = top:ComponentByName("groupEnemy/labelText02", typeof(UILabel))
	self.labelText04 = bottom:ComponentByName("groupChallengeLabel/labelText04", typeof(UILabel))

	for i = 1, 3 do
		self["challengeItem" .. i] = bottom:ComponentByName("groupChallenges/challengeItem" .. i, typeof(UIWidget))
		self["starImg" .. i] = bottom:ComponentByName("groupChallenges/challengeItem" .. i .. "/starImg", typeof(UISprite))
		self["challengeLabel" .. i] = bottom:ComponentByName("groupChallenges/challengeItem" .. i .. "/labelDesc", typeof(UILabel))
		self["imgComplete" .. i] = bottom:NodeByName("groupChallenges/challengeItem" .. i .. "/imgComplete").gameObject
	end
end

function ActivityBeachIslandFightWindow:setLayout()
	self.labelText02.text = __("ACTIVITY_BEACH_ISLAND_TEXT05")
	self.labelText03.text = __("ACTIVITY_BEACH_ISLAND_TEXT06")
	self.labelText04.text = __("ACTIVITY_BEACH_ISLAND_TEXT07")
	self.labelCampaignIndex.text = __("ACTIVITY_BEACH_ISLAND_TEXT04", self.stageID)

	self:setMonsterDisplay()
	self:setRewardDisplay()
	self:initChallengeState()
	xyd.setBgColorType(self.btnBattle, xyd.ButtonBgColorType.blue_btn_70_70)

	self.btnBattleLabel.text = __("TOWER_TEXT04")
end

function ActivityBeachIslandFightWindow:setMonsterDisplay()
	local battleID = xyd.tables.activityBeachIsland:getBattleID(self.stageID)
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

function ActivityBeachIslandFightWindow:initChallengeState()
	local maxLen = 0

	for i = 1, 3 do
		local text = xyd.tables.activityBeachIsland:getChallengeText(self.stageID, i)

		if text and maxLen < #text then
			maxLen = #text
		end

		self["challengeLabel" .. i].text = text

		if self.challengeState[i] and tonumber(self.challengeState[i]) == 1 then
			xyd.setUISpriteAsync(self["starImg" .. i], nil, "activity_beach_star_icon")
		else
			xyd.setUISpriteAsync(self["starImg" .. i], nil, "activity_beach_star_icon2")
		end
	end

	if xyd.Global.lang ~= "zh_tw" and xyd.Global.lang ~= "ja_jp" and xyd.Global.lang ~= "ko_kr" then
		if maxLen > 24 and maxLen <= 32 then
			for i = 1, 3 do
				self["challengeItem" .. i].width = 444
			end
		elseif maxLen > 32 then
			for i = 1, 3 do
				self["challengeItem" .. i].width = 532
			end
		end
	elseif maxLen > 48 and maxLen <= 64 then
		for i = 1, 3 do
			self["challengeItem" .. i].width = 444
		end
	elseif maxLen > 64 then
		for i = 1, 3 do
			self["challengeItem" .. i].width = 532
		end
	end
end

function ActivityBeachIslandFightWindow:setRewardDisplay()
	local rewards = xyd.tables.activityBeachIsland:getAwards(self.stageID)

	for i = 1, #rewards do
		local tableID = rewards[i][1]
		local num = rewards[i][2]
		local params = {
			notShowGetWayBtn = true,
			scale = 0.9074074074074074,
			itemID = tableID,
			num = num,
			uiRoot = self.groupItems
		}

		xyd.getItemIcon(params)
	end

	self.groupItemsGrid:Reposition()
end

function ActivityBeachIslandFightWindow:register()
	ActivityBeachIslandFightWindow.super.register(self)

	UIEventListener.Get(self.btnBattle).onClick = function ()
		self:requestBattle()
	end
end

function ActivityBeachIslandFightWindow:requestBattle()
	local fightParams = {
		showSkip = false,
		stageId = self.stageID,
		battleType = xyd.BattleType.BEACH_ISLAND
	}

	xyd.WindowManager.get():openWindow("battle_formation_window", fightParams)
end

return ActivityBeachIslandFightWindow
