local BaseWindow = import(".BaseWindow")
local GuildCompetitionFightWindow = class("GuildCompetitionFightWindow", BaseWindow)
local PlayerIcon = import("app.components.PlayerIcon")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local NewSkillIcon = import("app.components.NewSkillIcon")
local skillDetail = import("app.components.NewSkillIconWayAlert")
local GuildCompetitionChallengeGroup = import("app.components.GuildCompetitionChallengeGroup")

function GuildCompetitionFightWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.fortId = 1
	self.fortId = params.fort_id
	self.playerId = params.player_id
	self.playername = params.player_name
	self.avatarFrame = params.avatar_frame
	self.avatarId = params.avatar_id
	self.info = params.info
	self.bossIndex = params.bossIndex
	self.roundIndex = params.roundIndex
end

function GuildCompetitionFightWindow:getUIComponents()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.labelWinTitle = self.topGroup:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = self.topGroup:NodeByName("closeBtn").gameObject
	self.upBg = self.groupAction:ComponentByName("upBg", typeof(UISprite))
	self.awardBtn = self.groupAction:NodeByName("awardBtn").gameObject
	self.personEffectCon = self.groupAction:ComponentByName("personEffectCon", typeof(UITexture))
	self.buffsCon = self.groupAction:NodeByName("buffsCon").gameObject
	self.buffsCon_UILayout = self.groupAction:ComponentByName("buffsCon", typeof(UILayout))
	self.buffsTipsCon = self.groupAction:NodeByName("buffsTipsCon").gameObject
	self.buffsTipsCon_UIWidget = self.groupAction:ComponentByName("buffsTipsCon", typeof(UIWidget))
	self.buffsTipsCancel = self.groupAction:NodeByName("buffsTipsCancel").gameObject
	self.progressCon = self.groupAction:NodeByName("progressCon").gameObject
	self.progress = self.groupAction:ComponentByName("progressCon/progress", typeof(UIProgressBar))
	self.roundText = self.progressCon:ComponentByName("roundText", typeof(UILabel))
	self.bloodText = self.progressCon:ComponentByName("bloodText", typeof(UILabel))
	self.personClickCon = self.personEffectCon:NodeByName("personClickCon").gameObject
	self.groupPreview_ = self.groupAction:NodeByName("groupPreview_").gameObject
	self.labelPreviewTitle_ = self.groupPreview_:ComponentByName("labelPreviewTitle_", typeof(UILabel))
	self.groupPreviewHeros_ = self.groupPreview_:NodeByName("groupPreviewHeros_").gameObject
	self.groupPreviewHeros_UILayout = self.groupPreview_:ComponentByName("groupPreviewHeros_", typeof(UILayout))
	self.groupPreviewTipsCancel = self.groupAction:NodeByName("groupPreviewTipsCancel").gameObject
	self.groupPreviewBg_ = self.groupPreview_:ComponentByName("e:Image", typeof(UIWidget))
	self.downCon = self.groupAction:NodeByName("downCon").gameObject
	self.rewardBg = self.downCon:ComponentByName("rewardBg", typeof(UISprite))
	self.rewardText = self.downCon:ComponentByName("rewardText", typeof(UILabel))
	self.rewardItemCon = self.downCon:NodeByName("rewardItemCon").gameObject
	self.rewardItemCon_UILayout = self.downCon:ComponentByName("rewardItemCon", typeof(UILayout))
	self.canChallengeCon = self.downCon:NodeByName("canChallengeCon").gameObject
	self.canChallengeBg = self.canChallengeCon:ComponentByName("canChallengeBg", typeof(UISprite))
	self.canChallengeBg2 = self.canChallengeCon:ComponentByName("canChallengeBg2", typeof(UISprite))
	self.canChallengeText = self.canChallengeCon:ComponentByName("canChallengeText", typeof(UILabel))
	self.canChallengeTimeText = self.canChallengeCon:ComponentByName("canChallengeTimeText", typeof(UILabel))
	self.overChallengeCon = self.downCon:NodeByName("overChallengeCon").gameObject
	self.overChallengeBg = self.overChallengeCon:ComponentByName("overChallengeBg", typeof(UISprite))
	self.overChallengeBg2 = self.overChallengeCon:ComponentByName("overChallengeBg2", typeof(UISprite))
	self.overChallengeText = self.overChallengeCon:ComponentByName("overChallengeText", typeof(UILabel))
	self.overChallengeTimeText = self.overChallengeCon:ComponentByName("overChallengeTimeText", typeof(UILabel))
	self.fakeFightBtn = self.downCon:NodeByName("fakeFightBtn").gameObject
	self.fakeFightText = self.fakeFightBtn:ComponentByName("fakeFightText", typeof(UILabel))
	self.fightBtn = self.downCon:NodeByName("fightBtn").gameObject
	self.fightText = self.fightBtn:ComponentByName("fightText", typeof(UILabel))
	self.timeCon = self.downCon:NodeByName("timeCon").gameObject
	self.timeCon_UILayout = self.downCon:ComponentByName("timeCon", typeof(UILayout))
	self.timeText = self.timeCon:ComponentByName("timeText", typeof(UILabel))
	self.endText = self.timeCon:ComponentByName("endText", typeof(UILabel))
	self.studyBtn = self.downCon:NodeByName("studyBtn").gameObject
	self.studyBtnText = self.studyBtn:ComponentByName("studyBtnText", typeof(UILabel))
end

function GuildCompetitionFightWindow:initWindow()
	GuildCompetitionFightWindow.super.initWindow(self)
	self:getUIComponents()
	self:register()
	self:layout()
	self:updateUI()
	self:updateGuildCompetitionTime()
	self:initTargetGroup()
	self:checkTipsShow()
end

function GuildCompetitionFightWindow:initTargetGroup()
	local bossTable = xyd.tables.guildCompetitionBossTable
	local targetArr = bossTable["getBattleChallenge" .. self.bossIndex](bossTable, self.roundIndex)
	local params = {
		isHasStar = false,
		targetArr = targetArr
	}
	self.targetGroup = GuildCompetitionChallengeGroup.new(self.groupAction.gameObject, params)

	self.groupAction:Y(104)
	self.targetGroup:getGameObject():Y(-443)
end

function GuildCompetitionFightWindow:updateGuildCompetitionTime()
	if xyd.Global.lang == "fr_fr" then
		self.endText.gameObject.transform:SetSiblingIndex(1)
		self.timeText.gameObject.transform:SetSiblingIndex(0)
	end

	if xyd.models.guild:getGuildCompetitionInfo() then
		local timeData = xyd.models.guild:getGuildCompetitionLeftTime()

		if timeData.type == 1 then
			self.timeText.gameObject:SetActive(true)

			local CountDown = import("app.components.CountDown")

			self.timeText:SetActive(true)

			if self.guildCompetitionTimeCount then
				self.guildCompetitionTimeCount:stopTimeCount()
			end

			self.guildCompetitionTimeCount = CountDown.new(self.timeText, {
				duration = timeData.curEndTime - xyd.getServerTime(),
				callback = handler(self, function ()
					self:close()
				end)
			})
			self.endText.text = __("OPEN_AFTER")

			if xyd.Global.lang == "fr_fr" then
				self.endText.gameObject.transform:SetSiblingIndex(0)
				self.timeText.gameObject.transform:SetSiblingIndex(1)
			end
		elseif timeData.type == 2 then
			self.timeText.gameObject:SetActive(true)

			local CountDown = import("app.components.CountDown")

			self.timeText:SetActive(true)

			if self.guildCompetitionTimeCount then
				self.guildCompetitionTimeCount:stopTimeCount()
			end

			self.guildCompetitionTimeCount = CountDown.new(self.timeText, {
				duration = timeData.curEndTime - xyd.getServerTime(),
				callback = handler(self, self.updateGuildCompetitionTime)
			})
			self.endText.text = __("TEXT_END")
		else
			self.timeText.gameObject:SetActive(false)

			self.endText.text = __("GUILD_COMPETITION_END_TIME")
		end
	else
		self.timeText.gameObject:SetActive(false)

		self.endText.text = __("GUILD_COMPETITION_END_TIME")
	end

	self.timeCon_UILayout:Reposition()
end

function GuildCompetitionFightWindow:willClose()
	if self.guildCompetitionTimeCount then
		self.guildCompetitionTimeCount:stopTimeCount()
	end

	GuildCompetitionFightWindow.super.willClose(self)
end

function GuildCompetitionFightWindow:addTitle()
	if self.labelWinTitle then
		self.labelWinTitle.text = __("ITEM_DETAIL")
	end
end

function GuildCompetitionFightWindow:register()
	GuildCompetitionFightWindow.super.register(self)

	UIEventListener.Get(self.buffsTipsCancel.gameObject).onClick = handler(self, function ()
		self.skillDetailGroup:SetActive(false)
		self.buffsTipsCancel:SetActive(false)
	end)
	UIEventListener.Get(self.fightBtn.gameObject).onClick = handler(self, self.onFight)
	UIEventListener.Get(self.fakeFightBtn.gameObject).onClick = handler(self, self.onFakeFight)
	UIEventListener.Get(self.awardBtn.gameObject).onClick = handler(self, function ()
		local msg = messages_pb:guild_competition_boss_rank_req()
		msg.boss_id = self.bossIndex
		msg.activity_id = xyd.ActivityID.GUILD_COMPETITION

		xyd.Backend.get():request(xyd.mid.GUILD_COMPETITION_BOSS_RANK, msg)
	end)
	UIEventListener.Get(self.studyBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("guild_competition_partner_study_window", {})
	end)

	self.eventProxy_:addEventListener(xyd.event.GUILD_COMPETITION_BOSS_RANK, handler(self, function (__, event)
		local data = xyd.decodeProtoBuf(event.data)

		xyd.WindowManager.get():openWindow("guild_competition_boss_rank_window", {
			bossData = data,
			bossId = self.bossIndex,
			roundIndex = self.roundIndex
		})
	end))

	UIEventListener.Get(self.groupPreviewTipsCancel.gameObject).onClick = handler(self, function ()
		self.groupPreview_:SetActive(false)
		self.groupPreviewTipsCancel:SetActive(false)
	end)
	UIEventListener.Get(self.personClickCon.gameObject).onClick = handler(self, self.showEnemy)
end

function GuildCompetitionFightWindow:layout()
	self.roundText.text = __("GUILD_COMPETITION_ROUND", xyd.models.guild:getGuildCompetitionInfo().boss_info.rounds[self.bossIndex])
	self.rewardText.text = __("GUILD_BOSS_AWARD_2")
	self.canChallengeText.text = __("GUILD_COMPETITION_BOSS_LIMIT")
	self.labelPreviewTitle_.text = __("DUNGEON_MONSTER_PREVIEW")
	self.studyBtnText.text = __("GUILD_COMPETITION_PARTNER_TITLE")

	while true do
		if self.canChallengeText.width <= 250 then
			break
		end

		if self.canChallengeText.width > 250 then
			self.canChallengeText.fontSize = self.canChallengeText.fontSize - 1
		end
	end

	self.overChallengeText.text = __("GUILD_COMPETITION_PLAYER_LIMIT")

	while true do
		if self.overChallengeText.width <= 250 then
			break
		end

		if self.overChallengeText.width > 250 then
			self.overChallengeText.fontSize = self.overChallengeText.fontSize - 1
		end
	end

	self.fakeFightText.text = __("GUILD_COMPETITION_SIMULATE")
	self.fightText.text = __("GUILD_COMPETITION_ACTUAL")
	self.endText.text = __("TEXT_END")

	xyd.setUISpriteAsync(self.upBg, nil, "guild_competition_bg_" .. self.bossIndex)

	local timeData = xyd.models.guild:getGuildCompetitionLeftTime()

	if timeData.type ~= 2 then
		xyd.applyChildrenGrey(self.fightBtn.gameObject)
		xyd.applyChildrenGrey(self.fakeFightBtn.gameObject)

		if timeData.type == 1 then
			self.fightBtn.gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
			self.fakeFightBtn.gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		end
	end

	self.skillDetailGroup = skillDetail.new(self.buffsTipsCon, {})

	self.skillDetailGroup:SetActive(false)

	local bossTable = xyd.tables.guildCompetitionBossTable
	local skillArr = bossTable["getBattleSkill" .. self.bossIndex](bossTable, self.roundIndex)

	for i in pairs(skillArr) do
		self.skillIcon = NewSkillIcon.new(self.buffsCon.gameObject)
		local params = {
			scale = 0.5,
			callBack = function ()
				if self.skillDetailGroup:getBuffId() and self.skillDetailGroup:getBuffId() == skillArr[i] and self.skillDetailGroup:getGameObject().activeSelf then
					return
				end

				self.skillDetailGroup:setInfo({
					id = skillArr[i]
				})
				self.skillDetailGroup:SetActive(true)

				self.buffsTipsCon_UIWidget.alpha = 0.01

				self:waitForFrame(1, function ()
					self.buffsTipsCon:Y(114 + self.skillDetailGroup:getActionHeight() - 157)

					self.buffsTipsCon_UIWidget.alpha = 1

					self.buffsTipsCancel:SetActive(true)
				end)
			end
		}

		self.skillIcon:setInfo(skillArr[i], params)
	end

	self.buffsCon_UILayout:Reposition()

	local partnerArr = xyd.tables.miscTable:split2num("guild_competition_boss_model", "value", "|")
	local modelId = xyd.tables.partnerTable:getModelID(partnerArr[self.bossIndex])
	local effectName = xyd.tables.modelTable:getModelName(modelId)
	local effectScale = xyd.tables.modelTable:getScale(modelId)
	self.effect_ = xyd.Spine.new(self.personEffectCon.gameObject)
	local scale_x = effectScale * -1

	if self.bossIndex == 2 then
		scale_x = effectScale
	end

	self.effect_:setInfo(effectName, function ()
		self.effect_:SetLocalScale(scale_x * 0.92, effectScale * 0.92, effectScale * 0.92)
		self.effect_:play("idle", 0)
	end)

	local awardsArr = xyd.tables.guildCompetitionBossTable:getKillAwards(self.roundIndex)

	for i in pairs(awardsArr) do
		local item = {
			isShowSelected = false,
			itemID = awardsArr[i][1],
			num = awardsArr[i][2],
			scale = Vector3(0.7037037037037037, 0.7037037037037037, 1),
			uiRoot = self.rewardItemCon.gameObject
		}
		local icon = xyd.getItemIcon(item)
	end

	self.rewardItemCon_UILayout:Reposition()
end

function GuildCompetitionFightWindow:updateUI()
	local bloodPrams = xyd.models.guild:getGuildCompetitionBossPress(self.bossIndex)
	self.bloodText.text = tostring(xyd.getRoughDisplayNumber3(bloodPrams.curBlood)) .. "/" .. tostring(xyd.getRoughDisplayNumber3(bloodPrams.allBlood))
	self.progress.value = bloodPrams.provalue
	local canChallengeTimes = xyd.tables.miscTable:getNumber("guild_competition_boss_limit", "value") - tonumber(xyd.models.guild:getGuildCompetitionInfo().boss_info.times[self.bossIndex])
	canChallengeTimes = xyd.checkCondition(canChallengeTimes < 0, 0, canChallengeTimes)
	self.canChallengeTimeText.text = tostring(canChallengeTimes)
	self.canChallengeTimeText_num = canChallengeTimes
	local overChallengeTimes = xyd.tables.miscTable:getNumber("guild_competition_personal_limit", "value") - tonumber(xyd.models.guild:getGuildCompetitionInfo().times)
	overChallengeTimes = xyd.checkCondition(overChallengeTimes < 0, 0, overChallengeTimes)
	self.overChallengeTimeText.text = tostring(overChallengeTimes)
end

function GuildCompetitionFightWindow:onFight()
	local timeData = xyd.models.guild:getGuildCompetitionLeftTime()

	if timeData.type == 2 then
		local selfNum = tonumber(self.overChallengeTimeText.text)

		if selfNum <= 0 then
			xyd.showToast(__("GUILD_BOSS_TEXT02"))

			return
		end

		local allGuildNum = tonumber(self.canChallengeTimeText_num)

		if allGuildNum <= 0 then
			xyd.showToast(__("GUILD_COMPETITION_NO_TIMES"))

			return
		end

		xyd.WindowManager.get():openWindow("battle_formation_window", {
			type = 1,
			showSkip = false,
			battleType = xyd.BattleType.GUILD_COMPETITION,
			boss_id = self.bossIndex
		})
	else
		xyd.showToast(__("ACTIVITY_END_YET"))
	end
end

function GuildCompetitionFightWindow:onFakeFight()
	local timeData = xyd.models.guild:getGuildCompetitionLeftTime()

	if timeData.type == 2 then
		xyd.WindowManager.get():openWindow("battle_formation_window", {
			type = 2,
			showSkip = false,
			battleType = xyd.BattleType.GUILD_COMPETITION,
			boss_id = self.bossIndex
		})
	else
		xyd.showToast(__("ACTIVITY_END_YET"))
	end
end

function GuildCompetitionFightWindow:showEnemy()
	if not self.initEnemies then
		local bossTable = xyd.tables.guildCompetitionBossTable
		local battleId = bossTable["getBattleId" .. self.bossIndex](bossTable, self.roundIndex)
		local enemies = xyd.tables.battleTable:getMonsters(battleId)

		if #enemies > 0 then
			self.groupPreviewTipsCancel:SetActive(true)
			NGUITools.DestroyChildren(self.groupPreviewHeros_.transform)

			for i = 1, #enemies do
				local tableID = enemies[i]
				local id = xyd.tables.monsterTable:getPartnerLink(tableID)
				local lev = xyd.tables.monsterTable:getShowLev(tableID)
				local icon = HeroIcon.new(self.groupPreviewHeros_)

				icon:setInfo({
					noClick = true,
					tableID = id,
					lev = lev
				})
			end

			if #enemies > 5 then
				self.groupPreviewBg_.width = 706
				self.groupPreviewHeros_UILayout.gap = Vector2(5, 0)
			elseif #enemies == 5 then
				self.groupPreviewBg_.width = 647
				self.groupPreviewHeros_UILayout.gap = Vector2(12, 0)
			else
				self.groupPreviewBg_.width = 556
				self.groupPreviewHeros_UILayout.gap = Vector2(12, 0)
			end

			self.groupPreview_:SetActive(true)
			self.groupPreviewHeros_UILayout:Reposition()
		end

		self.initEnemies = true
	else
		self.groupPreview_:SetActive(true)
		self.groupPreviewTipsCancel:SetActive(true)
	end
end

function GuildCompetitionFightWindow:hideEffect()
	if self.effect_ then
		self.effect_:SetActive(false)
	end
end

function GuildCompetitionFightWindow:checkTipsShow()
	local timeData = xyd.models.guild:getGuildCompetitionLeftTime()

	if timeData.type ~= 2 then
		return
	end

	local lastTipsTime = xyd.db.misc:getValue("guild_competition_boss_high_tips")

	if lastTipsTime then
		lastTipsTime = tonumber(lastTipsTime)
		local guildCompetitionData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_COMPETITION)

		if lastTipsTime < guildCompetitionData:startTime() or guildCompetitionData:getEndTime() <= lastTipsTime then
			for i = 1, 3 do
				xyd.db.misc:setValue({
					value = 0,
					key = "guild_competition_boss_high_tips_with_boss_" .. i
				})
			end

			xyd.db.misc:setValue({
				key = "guild_competition_boss_high_tips",
				value = xyd.getServerTime()
			})
		end
	else
		for i = 1, 3 do
			xyd.db.misc:setValue({
				value = 0,
				key = "guild_competition_boss_high_tips_with_boss_" .. i
			})
		end

		xyd.db.misc:setValue({
			key = "guild_competition_boss_high_tips",
			value = xyd.getServerTime()
		})
	end

	local bossTable = xyd.tables.guildCompetitionBossTable
	local isTips = bossTable["getSkillTips" .. self.bossIndex](bossTable, self.roundIndex)

	if isTips and isTips > 0 then
		local lastCheckTipsRound = 0
		local localCheckTipsRound = xyd.db.misc:getValue("guild_competition_boss_high_tips_with_boss_" .. self.bossIndex)

		if localCheckTipsRound then
			lastCheckTipsRound = tonumber(localCheckTipsRound)
		end

		if lastCheckTipsRound < self.roundIndex then
			xyd.alertConfirm(__("GUILD_COMPETITION_SKILL_TIPS"), nil, __("SURE"))
			xyd.db.misc:setValue({
				key = "guild_competition_boss_high_tips_with_boss_" .. self.bossIndex,
				value = self.roundIndex
			})
		end
	end
end

return GuildCompetitionFightWindow
