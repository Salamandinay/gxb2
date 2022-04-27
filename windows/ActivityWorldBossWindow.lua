local FriendBossWindow = import("app.windows.FriendBossWindow")
local ActivityWorldBossWindow = class("ActivityWorldBossWindow", FriendBossWindow)
local json = require("cjson")

function ActivityWorldBossWindow:ctor(name, params)
	FriendBossWindow.ctor(self, name, params)
end

function ActivityWorldBossWindow:initWindow()
	FriendBossWindow.initWindow(self)
end

function ActivityWorldBossWindow:layout()
	self.labelTili_.text = tostring(xyd.models.backpack:getItemNumByID(28))

	xyd.setUISpriteAsync(self.iconImg_, nil, xyd.tables.itemTable:getIcon(28), nil, )

	self.iconImg_:GetComponent(typeof(UIWidget)).width = 45
	self.iconImg_:GetComponent(typeof(UIWidget)).height = 45

	self.iconImg_:SetLocalPosition(-64, 0, 0)
	self.labelLevel:SetActive(true)

	self.labelLevel.text = __("ACTIVITY_WORLD_BOSS_LEVEL_TIPS", xyd.tables.activityBossTable:getLevel(self.baseInfo_.boss_id or 1))
	self.labelWinTitle_.text = __("ACTIVITY_WORLD_BOSS_TITLE")
end

function ActivityWorldBossWindow:initHeros()
	NGUITools.DestroyChildren(self.gridOfBossIcon_.transform)

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_WORLD_BOSS)

	print("cccccccccccccc:", self.params_.boss_type)

	local baseInfo = activityData.detail.boss_infos[self.params_.boss_type]
	local enemies = baseInfo.enemies
	local bossID = baseInfo.boss_id or 0
	local battleID = xyd.tables.activityBossTable:getBattleID(bossID)

	if battleID > 0 then
		local monsters = xyd.tables.battleTable:getMonsters(battleID)

		for i, monsterID in ipairs(monsters) do
			local itemRoot = NGUITools.AddChild(self.gridOfBossIcon_.gameObject, self.bossIconRoot_)

			itemRoot:SetActive(true)

			local heroIcon = xyd.getHeroIcon({
				isMonster = true,
				noClick = true,
				uiRoot = itemRoot,
				tableID = monsterID,
				lev = xyd.tables.monsterTable:getShowLev(monsterID),
				dragScrollView = self.scrollView_
			})
		end

		self.gridOfBossIcon_:Reposition()
		self.scrollView_:ResetPosition()
	end

	local tot_hp = 0
	local max_hp = xyd.tables.activityBossTable:getHp(bossID)

	if #enemies > 0 then
		for i in ipairs(enemies) do
			local status = enemies[i].status

			if status.true_hp ~= nil and status.true_hp ~= nil then
				tot_hp = tot_hp + tonumber(status.true_hp)
			else
				tot_hp = max_hp

				break
			end
		end

		self.progressBar_.value = math.floor(100 * tot_hp / max_hp) / 100
		self.progressBar_.value = math.max(self.progressBar_.value, 0.01)
		local showTextNum = xyd.checkCondition(math.floor(100 * tot_hp / max_hp) < 0.01, 0.01, math.floor(100 * tot_hp / max_hp))
		self.progressLabel_.text = showTextNum .. "%"
	else
		self.progressBar_.value = 1
		self.progressLabel_.text = "100%"
	end
end

function ActivityWorldBossWindow:updateStatus()
	self:initHeros()
	self:layout()
end

function ActivityWorldBossWindow:register()
	ActivityWorldBossWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.BOSS_FIGHT, handler(self, self.onFight))
	self.eventProxy_:addEventListener(xyd.event.BOSS_SWEEP, handler(self, self.onSweepBoss))
end

function ActivityWorldBossWindow:initTime()
	self.labelTimeNum_:SetActive(false)
	self.labelTime_:SetActive(false)
end

function ActivityWorldBossWindow:onFightTouch()
	if self:checkCanFight() then
		local fightParams = {
			activity_id = self.params_.activity_id,
			boss_type = self.params_.boss_type,
			battleType = xyd.BattleType.WORLD_BOSS
		}

		xyd.WindowManager.get():openWindow("battle_formation_window", fightParams)
	end
end

function ActivityWorldBossWindow:onSweepTouch()
	if not self:checkCanFight() then
		return
	end

	local fightParams = {
		activity_id = self.params_.activity_id,
		boss_type = self.params_.boss_type,
		battleType = xyd.BattleType.WORLD_BOSS
	}

	xyd.WindowManager.get():openWindow("activity_world_boss_sweep_window", fightParams)
end

function ActivityWorldBossWindow:checkCanFight()
	local data = xyd.tables.miscTable:split2Cost("activity_boss_fight_cost", "value", "#")
	local has = xyd.models.backpack:getItemNumByID(data[1])

	if data[2] <= has then
		return true
	else
		xyd.showToast(__("ACTIVITY_WORLD_BOSS_NOT_ENOUGH"))

		return false
	end
end

function ActivityWorldBossWindow:onFight(event)
	self:updateNumber()
end

function ActivityWorldBossWindow:onSweepBoss(evt)
	local data = evt.data
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_WORLD_BOSS)
	local type = data.boss_info.boss_type

	if data.items then
		local params = {
			items = data.items,
			harm = data.total_harm
		}

		xyd.WindowManager.get():openWindow("alert_award_with_harm_window", params)
	end

	local info = data.boss_info

	if info then
		if info.enemies then
			activityData.detail.boss_infos[type].enemies = info.enemies
		else
			activityData.detail.boss_infos[type].enemies = {}
		end
	else
		activityData.detail.boss_infos[type].enemies = {}
	end

	activityData:setDataNodecode(activityData)
	self:updateStatus()

	if data.is_win ~= 0 then
		xyd.WindowManager.get():closeWindow("activity_world_boss_window")
		xyd.showToast(__("WORLD_BOSS_KILL"))
	end

	if data.is_win ~= 0 then
		if info then
			local cur_id = activityData.detail.boss_infos[type].boss_id
			activityData.detail.boss_infos[type].boss_id = xyd.tables.activityBossTable:getNext(cur_id)
		end
	else
		activityData.detail.boss_infos[type].boss_id = data.boss_info.boss_id
	end

	activityData:setDataNodecode(activityData)
	self:updateNumber()
end

function ActivityWorldBossWindow:updateNumber()
	self.labelTili_.text = tostring(xyd.models.backpack:getItemNumByID(28))
end

return ActivityWorldBossWindow
