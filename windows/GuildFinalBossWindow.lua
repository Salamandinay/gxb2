local BaseWindow = import(".BaseWindow")
local SkillIcon = import("app.components.SkillIcon")
local GuildFinalBossWindow = class("GuildFinalBossWindow", BaseWindow)

function GuildFinalBossWindow:ctor(name, params)
	GuildFinalBossWindow.super.ctor(self, name, params)

	self.bossData_ = nil
	self.bossId_ = params.bossId or 0
	self.skillItems_ = {}
end

function GuildFinalBossWindow:initWindow()
	GuildFinalBossWindow.super.initWindow(self)
	self:getComponent()
	self:layOut()
	self:register()

	self.bossData_ = xyd.models.guild:getBossInfo(self.bossId_)

	if self.bossData_ then
		self:refreshData()
	else
		xyd.models.guild:reqBossInfo(self.bossId_)
	end
end

function GuildFinalBossWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.winTitle_ = winTrans:ComponentByName("winTitle", typeof(UILabel))
	self.bossWord_ = winTrans:ComponentByName("bossWord/label", typeof(UILabel))
	self.helpBtn_ = winTrans:NodeByName("helpBtn").gameObject
	self.rankBtn_ = winTrans:NodeByName("rankBtn").gameObject
	self.labelLeftCount_ = winTrans:ComponentByName("labelLeftCount", typeof(UILabel))
	self.btnFight_ = winTrans:NodeByName("btnFight").gameObject
	self.btnFightLabel_ = winTrans:ComponentByName("btnFight/label", typeof(UILabel))
	self.groupSkillInfo_ = winTrans:NodeByName("groupSkillInfo").gameObject
	self.skillIconGroup_ = winTrans:ComponentByName("groupSkill", typeof(UILayout))
	self.touchGroup_ = winTrans:NodeByName("touchGroup").gameObject
end

function GuildFinalBossWindow:layOut()
	self.bossWord_.text = __("GUILD_BOSS_DIALOG")
	self.btnFightLabel_.text = __("FIGHT3")
	self.winTitle_.text = __("GUILD_BOSS_WINDOW")
end

function GuildFinalBossWindow:register()
	GuildFinalBossWindow.super.register(self)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	local flag = false

	if xyd.Global.lang == "zh_tw" then
		flag = true
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "GUILD_FINAL_BOSS_WINDOW_HELP",
			isEast = flag
		})
	end

	UIEventListener.Get(self.touchGroup_).onClick = function ()
		self:clearSkillTips()
	end

	UIEventListener.Get(self.rankBtn_).onClick = handler(self, self.onClickRankBtn)
	UIEventListener.Get(self.btnFight_).onClick = handler(self, self.onClickFightBtn)

	self.eventProxy_:addEventListener(xyd.event.GUILD_BOSS_INFO, self.refreshData, self)
end

function GuildFinalBossWindow:refreshData()
	local num = xyd.models.guild:getFinalBossLeftCount()
	self.labelLeftCount_.text = __("GUILD_BOSS_TEXT01", num)
	local fightTime = xyd.models.guild:getGuildBossTime()[1] or 0

	if xyd.isToday(fightTime) then
		self.labelLeftCount_.text = __("GUILD_BOSS_TEXT01", 0)
	end

	self.bossData_ = xyd.models.guild:getBossInfo(self.bossId_)
	local bossTableId = xyd.tables.monsterTable:getPartnerLink(self.bossData_.bossInfo.enemies[1].table_id)
	local skillIds = {
		xyd.tables.partnerTable:getAllPugongIDs(bossTableId)[1],
		xyd.tables.partnerTable:getEnergyID(bossTableId)
	}

	for i = 1, 3 do
		local skillId = xyd.tables.partnerTable:getPasSkill(bossTableId, i)

		if skillId ~= 0 then
			table.insert(skillIds, skillId)
		end
	end

	for i = 1, #skillIds do
		local item = SkillIcon.new(self.skillIconGroup_.gameObject)

		item:setScale(0.8, 0.8, 0.8)
		item:setInfo(skillIds[i], {
			showGroup = self.groupSkillInfo_,
			callback = function ()
				self:clearSkillTips()
				item:showTips(true, item.showGroup, true)
			end
		})
		table.insert(self.skillItems_, item)
	end

	self.skillIconGroup_:Reposition()
end

function GuildFinalBossWindow:clearSkillTips()
	for _, item in ipairs(self.skillItems_) do
		item:showTips(false, item.showGroup)
	end
end

function GuildFinalBossWindow:onClickFightBtn()
	local fightTime = xyd.models.guild:getGuildBossTime()[1] or 0

	if xyd.isToday(fightTime) then
		xyd.alertTips(__("GUILD_BOSS_CANT_FIGHT"))

		return
	end

	local num = xyd.models.guild:getFinalBossLeftCount()

	if os.date("!*t", xyd.getServerTime()).wday == 6 and os.date("!*t", xyd.getServerTime()).hour == 0 then
		xyd.showToast(__("GUILD_TEXT68"))
		xyd.closeWindow(self.name_)
	end

	if num > 0 then
		local fightParams = {
			forceConfirm = 1,
			alpha = 0.7,
			no_close = true,
			mapType = xyd.MapType.GUILD_BOSS,
			battleType = xyd.BattleType.GUILD_BOSS,
			bossId = self.bossId_
		}

		xyd.WindowManager.get():openWindow("battle_formation_window", fightParams)
	else
		xyd.alertTips(__("GUILD_BOSS_TEXT02"))
	end
end

function GuildFinalBossWindow:onClickRankBtn()
	xyd.WindowManager.get():openWindow("guild_final_boss_rank_window", {
		bossId = self.bossId_
	})
end

return GuildFinalBossWindow
