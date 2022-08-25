local BattleFailWindow = class("BattleFailWindow", import(".BaseWindow"))
local PlayerIcon = import("app.components.PlayerIcon")
local Partner = import("app.models.Partner")
local json = require("cjson")

function BattleFailWindow:ctor(name, params)
	BattleFailWindow.super.ctor(self, name, params)

	self.callback = nil
	self.onOpenCallback = nil
	self.StageTable = xyd.tables.stageTable
	self.isOpenCampaign = true
	self.isRecord = params.isRecord

	if params and params.listener ~= nil then
		self.callback = params.listener
	end

	if params and params.onOpenCallback ~= nil then
		self.onOpenCallback = params.onOpenCallback
	end

	if params and params.battleParams.onOpenCallback ~= nil then
		self.onOpenCallback = params.battleParams.onOpenCallback
	end

	if params.battleParams.buff_ids then
		self.buffIds_ = params.battleParams.buff_ids
	end

	self.battleParams = params.battleParams
	self.data = params
	self.mapType = params.map_type
	self.stageId = self.battleParams.stage_id
	self.recordID = self.battleParams.record_id or -1
	self.battleType = self.battleParams.battle_type or params.battle_type
	self.isNewVer = params.is_new
	self.reportTypeList = {
		xyd.BattleType.TRIAL,
		xyd.BattleType.TOWER,
		xyd.BattleType.TOWER_PRACTICE,
		xyd.BattleType.HERO_CHALLENGE,
		xyd.BattleType.HERO_CHALLENGE_REPORT,
		xyd.BattleType.HERO_CHALLENGE_SPEED,
		xyd.BattleType.FRIEND,
		xyd.BattleType.HERO_CHALLENGE_CHESS,
		xyd.BattleType.FAIR_ARENA,
		xyd.BattleType.NEW_PARTNER_WARMUP,
		xyd.BattleType.ACADEMY_ASSESSMENT,
		[13] = xyd.BattleType.ENTRANCE_TEST_REPORT,
		[14] = xyd.BattleType.GALAXY_TRIP_BATTLE,
		[14] = xyd.BattleType.GALAXY_TRIP_SPECIAL_BOSS_BATTLE
	}
	self.isReportType = false
	local battleReportData = params.real_battle_report
	battleReportData = battleReportData or params.battleParams.battle_report

	if battleReportData then
		local mvpPos = xyd.getMVPPartner(battleReportData)
		local teamA = battleReportData.teamA

		for _, teamData in ipairs(teamA) do
			if tonumber(teamData.pos) == mvpPos then
				self.skinId_ = tonumber(teamData.skin_id)
				self.tableId_ = tonumber(teamData.table_id)

				if teamData.isMonster then
					local tmpSkinID = xyd.tables.monsterTable:getSkin(self.tableId_)
					self.tableId_ = xyd.tables.monsterTable:getPartnerLink(self.tableId_)

					if tmpSkinID > 0 then
						self.skinId_ = tmpSkinID
					end
				end

				local group = xyd.tables.partnerTable:getGroup(self.tableId_)
				local showIds = xyd.tables.partnerTable:getShowIds(self.tableId_)

				if group == 7 and xyd.tables.partnerTable:getStar(self.tableId_) == 10 and tonumber(self.skinId_) == 0 then
					local awake = tonumber(teamData.awake)

					if awake < 3 then
						self.skinId_ = showIds[1]

						break
					end
				end

				if awake < 5 then
					self.skinId_ = showIds[2]

					break
				end

				if awake >= 5 then
					self.skinId_ = showIds[3]
				end

				break
			end
		end
	end

	if self.battleType == xyd.BattleType.CAMPAIGN and not xyd.GuideController.get():isGuideComplete() then
		local stageId = self.battleParams.stage_id

		if tonumber(stageId) < 3 then
			self.tableId_ = 11002
		end
	end

	if xyd.arrayIndexOf(self.reportTypeList, self.battleType) >= 1 then
		self.isReportType = true
	end

	if self.isNewVer then
		self.effectName = "shibai_new"
		self.labelImg = "battle_result_text02_" .. xyd.Global.lang
	else
		self.effectName = "shibai"
		self.labelImg = "battle_result_text04_" .. xyd.Global.lang
	end

	if self.tableId_ then
		local partner = Partner.new()

		partner:populate({
			table_id = self.tableId_
		})

		self.partner_ = partner

		self:getPartnerRes(partner)
	end
end

function BattleFailWindow:getPartnerRes(partner)
	if self.skinId_ and self.skinId_ ~= 0 then
		local girlModelId = xyd.tables.partnerPictureTable:getDragonBone(self.skinId_)

		if girlModelId and girlModelId ~= 0 then
			self.girlModelId_ = girlModelId
			self.pEffectName = xyd.tables.girlsModelTable:getResource(girlModelId)
			self.pTexiaoName = xyd.tables.girlsModelTable:getTexiaoName(girlModelId)
			self.usePEffect = true
		else
			self.usePEffect = false
			local src = xyd.tables.partnerPictureTable:getPartnerPic(self.skinId_)
			self.partnerImg = src
		end
	else
		self.usePEffect = false
		local src = partner:getPartnerPic()
		self.partnerImg = src
	end
end

function BattleFailWindow:getUIComponent()
	local winTrans = self.window_.transform
	local winGroup = winTrans:NodeByName("winGroup").gameObject
	self.winGroup = winGroup
	self.mask_ = winTrans:ComponentByName("mask_", typeof(UISprite))
	self.effectTarget_ = winGroup:NodeByName("effectTarget_").gameObject
	self.pvpGroup = winGroup:NodeByName("pvpGroup").gameObject
	self.pveDropGroup = winGroup:NodeByName("pveDropGroup").gameObject
	self.pveDropGroup_grid = winGroup:ComponentByName("pveDropGroup", typeof(UIGrid))
	self.improveGroup = winGroup:NodeByName("improveGroup").gameObject
	self.labelAdvice = self.improveGroup:ComponentByName("labelAdvice", typeof(UILabel))
	self.labelEquip = self.improveGroup:ComponentByName("groupEquip/labelEquip", typeof(UILabel))
	self.labelPartner = self.improveGroup:ComponentByName("groupPartner/labelPartner", typeof(UILabel))
	self.labelSummon = self.improveGroup:ComponentByName("groupSummon/labelSummon", typeof(UILabel))
	self.groupEquip = self.improveGroup:NodeByName("groupEquip").gameObject
	self.improveEquipBtn = self.improveGroup:NodeByName("groupEquip/improveEquipBtn").gameObject
	self.groupPartner = self.improveGroup:NodeByName("groupPartner").gameObject
	self.improvePartnerBtn = self.improveGroup:NodeByName("groupPartner/improvePartnerBtn").gameObject
	self.groupSummon = self.improveGroup:NodeByName("groupSummon").gameObject
	self.summonBtn = self.improveGroup:NodeByName("groupSummon/summonBtn").gameObject
	self.damageGroup = self.winGroup:NodeByName("damageGroup").gameObject
	self.labelDamage1 = self.damageGroup:ComponentByName("labelDamage1", typeof(UILabel))
	self.labelDamage2 = self.damageGroup:ComponentByName("labelDamage2", typeof(UILabel))
	self.rightPlayerGroup = self.pvpGroup:NodeByName("rightPlayerGroup").gameObject
	self.leftPlayerGroup = self.pvpGroup:NodeByName("leftPlayerGroup").gameObject
	self.groupRightLabels_ = self.rightPlayerGroup:NodeByName("groupRightLabels_").gameObject
	self.groupLeftLabels_ = self.leftPlayerGroup:NodeByName("groupLeftLabels_").gameObject
	self.labelRightPlayerName = self.groupRightLabels_:ComponentByName("labelRightPlayerName", typeof(UILabel))
	self.labelRightScore = self.groupRightLabels_:ComponentByName("labelRightScore", typeof(UILabel))
	self.labelRightScoreText = self.groupRightLabels_:ComponentByName("labelRightScoreText", typeof(UILabel))
	self.labelRightScoreChange = self.groupRightLabels_:ComponentByName("labelRightScoreChange", typeof(UILabel))
	self.labelLeftPlayerName = self.groupLeftLabels_:ComponentByName("labelLeftPlayerName", typeof(UILabel))
	self.labelLeftScoreText = self.groupLeftLabels_:ComponentByName("labelLeftScoreText", typeof(UILabel))
	self.labelLeftScore = self.groupLeftLabels_:ComponentByName("labelLeftScore", typeof(UILabel))
	self.labelLeftScoreChange = self.groupLeftLabels_:ComponentByName("labelLeftScoreChange", typeof(UILabel))
	self.groupLeftIcon_ = self.leftPlayerGroup:NodeByName("groupLeftIcon_").gameObject
	self.groupRightIcon_ = self.rightPlayerGroup:NodeByName("groupRightIcon_").gameObject
	self.textImg = winTrans:ComponentByName("textImg", typeof(UITexture))
	self.partnerImgNode = winTrans:NodeByName("partnerImgNode").gameObject
	self.dynamicPartnerImg = winTrans:NodeByName("dynamicPartnerImgNode").gameObject
	self.labelRecord_ = winTrans:ComponentByName("labelRecord", typeof(UILabel))
	self.shrineHurdleScoreGroup_ = winGroup:NodeByName("shrineHurdleScoreGroup").gameObject
	self.diffTips_ = self.shrineHurdleScoreGroup_:ComponentByName("diffTips", typeof(UILabel))
	self.scoreGroup_ = self.shrineHurdleScoreGroup_:NodeByName("scoreGroup").gameObject
	self.shrineHurdleScoreTips_ = self.shrineHurdleScoreGroup_:ComponentByName("scoreGroup/scoreTips", typeof(UILabel))
	self.shrineHurdleScore_ = self.shrineHurdleScoreGroup_:ComponentByName("scoreGroup/score", typeof(UILabel))
	self.shrineHurdleGoldGroup_ = self.shrineHurdleScoreGroup_:NodeByName("goldGroup").gameObject
	self.shrineHurdleLabelCoinNum_ = self.shrineHurdleGoldGroup_:ComponentByName("labelCoinNum", typeof(UILabel))
	self.shrineHurdleHurtGroup_ = self.shrineHurdleScoreGroup_:NodeByName("hurtGroup").gameObject
	self.shrineHurdlehHurtTips_ = self.shrineHurdleHurtGroup_:ComponentByName("hurtTips", typeof(UILabel))
	self.shrineHurdlehHurt_ = self.shrineHurdleHurtGroup_:ComponentByName("hurt", typeof(UILabel))
	self.shrinePartnerGroup_ = self.shrineHurdleScoreGroup_:ComponentByName("partnerGroup", typeof(UILayout))

	if self.isNewVer then
		self.effectTarget1_ = winGroup:NodeByName("effectTarget1_").gameObject
		self.bottomNode = winTrans:NodeByName("bottomNode").gameObject
		self.battleDetailBtn = self.bottomNode:NodeByName("battleDetailBtn").gameObject
		self.battleReviewBtn = self.bottomNode:NodeByName("battleReviewBtn").gameObject
		self.battleCheckBuffBtn = self.bottomNode:NodeByName("battleCheckBuffBtn").gameObject
		self.confirmBtn = self.bottomNode:NodeByName("confirmBtn").gameObject
		self.confirmBtnLabel = self.confirmBtn:ComponentByName("button_label", typeof(UILabel))
		self.nextBtn = self.bottomNode:NodeByName("nextBtn").gameObject
		self.nextBtnLabel = self.nextBtn:ComponentByName("button_label", typeof(UILabel))
		self.partnerImg1 = self.partnerImgNode:ComponentByName("partnerImg", typeof(UITexture))
	else
		self.battleDetailBtn = winGroup:NodeByName("battleDetailBtn").gameObject
		self.battleReviewBtn = winGroup:NodeByName("battleReviewBtn").gameObject
		self.battleCheckBuffBtn = winGroup:NodeByName("battleCheckBuffBtn").gameObject
		self.confirmBtn = winGroup:NodeByName("confirmBtn").gameObject
		self.confirmBtnLabel = self.confirmBtn:ComponentByName("button_label", typeof(UILabel))
	end

	if self.onOpenCallback then
		self.mask_:SetActive(true)
	end
end

function BattleFailWindow:initWindow()
	BattleFailWindow.super.initWindow(self)
	self:getUIComponent()
	xyd.SoundManager.get():playSound(xyd.SoundID.BATTLE_LOSE)

	local sp1 = xyd.Spine.new(self.effectTarget_)

	local function callback()
		local winGroupWidth = self.winGroup:GetComponent(typeof(UIWidget)).width

		sp1:SetLocalPosition(0, 172, 0)
		sp1:changeAttachment("zititihuan1", self.textImg)
		sp1:play("texiao01", 1, 1, function ()
			sp1:play("texiao02", 0)

			if self.onOpenCallback then
				self.mask_:SetActive(false)
				self.onOpenCallback()
			end
		end)

		if self:checkShowBoard() then
			local sp2 = xyd.Spine.new(self.effectTarget_)

			sp2:setInfo(self.effectName, function ()
				sp2:SetLocalPosition(0, 172, 5)
				sp2:play("texiao03", 1, 1, function ()
				end)
			end)
		else
			sp1:SetLocalPosition(0, 160, 0)
		end

		self:waitForTime(0.3, function ()
			self:initLayout()
		end, "")
	end

	local function newCallback()
		if self.onOpenCallback then
			self.mask_:SetActive(true)
		end

		sp1:play("texiao01", 1, 1, function ()
			sp1:play("texiao02", 0)
		end)
		sp1.spAnim:addEvent(function (event)
			if event ~= nil and event.Data.Name == "start" then
				self:playDialog()
				self.confirmBtn:SetActive(true)
				xyd.EventDispatcher:inner():dispatchEvent({
					name = xyd.event.PLAY_REPORT_END,
					params = {}
				})

				if self.onOpenCallback then
					self.mask_:SetActive(false)
					self:onOpenCallback()
				end
			end
		end)

		if self:checkShowBoard() then
			local sp2 = xyd.Spine.new(self.effectTarget1_)

			sp2:setInfo(self.effectName, function ()
				sp2:play("texiao03", 1, 1, function ()
					sp2:play("texiao04", 0)
				end)
			end)
		end

		self:waitForTime(0.3, function ()
			self:initLayout()
		end, "")
	end

	xyd.setUITextureByNameAsync(self.textImg, self.labelImg, true)
	sp1:setInfo(self.effectName, function ()
		sp1:changeAttachment("zititihuan1", self.textImg)

		if self.isNewVer then
			local id = self.skinId_

			if not id or id == 0 then
				id = self.tableId_
			end

			local xy = xyd.tables.partnerPictureTable:getPartnerPicXY(id)
			local scale = xyd.tables.partnerPictureTable:getPartnerPicScale(id)

			if self.usePEffect then
				local sp2 = xyd.Spine.new(self.dynamicPartnerImg)

				sp2:setInfo(self.pEffectName, function ()
					sp1:followBone("lihuith", self.dynamicPartnerImg)
					sp1:followSlot("lihuith", self.dynamicPartnerImg)
					sp2:play(self.pTexiaoName, 0)
					sp2:SetLocalPosition(xy.x, -xy.y - 130, 0)
					sp2:SetLocalScale(scale, scale, scale)
				end)
			else
				xyd.setUITextureByNameAsync(self.partnerImg1, self.partnerImg, true, function ()
					sp1:followBone("lihuith", self.partnerImgNode)
					sp1:followSlot("lihuith", self.partnerImgNode)
					self.partnerImg1:SetLocalPosition(xy.x, -xy.y + 40, 0)

					self.partnerImg1.transform.localScale = Vector3(scale, scale, 1)
				end)
			end

			newCallback()

			return
		end

		callback()
	end)
end

function BattleFailWindow:playDialog()
	local dialog = xyd.tables.partnerTable:getFailedDialogInfo(self.tableId_)

	xyd.SoundManager.get():stopSound(dialog.sound)
	xyd.SoundManager.get():playSound(dialog.sound)
end

function BattleFailWindow:checkShowBoard()
	if self.battleType == xyd.BattleType.HERO_CHALLENGE or self.battleType == xyd.BattleType.HERO_CHALLENGE_REPORT or self.battleType == xyd.BattleType.ENTRANCE_TEST_REPORT or self.battleType == xyd.BattleType.LIBRARY_WATCHER_STAGE_FIGHT2 or self.battleType == xyd.BattleType.SPORTS_SHOW or self.battleType == xyd.BattleType.FRIEND_BOSS or self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS or self.battleType == xyd.BattleType.PARTNER_STATION or self.battleType == xyd.BattleType.ICE_SECRET_BOSS or self.battleType == xyd.BattleType.EXPLORE_OLD_CAMPUS or self.battleType == xyd.BattleType.BEACH_ISLAND or self.battleType == xyd.BattleType.ENCOUNTER_STORY or self.battleType == xyd.BattleType.LIMIT_CALL_BOSS then
		return false
	end

	return true
end

function BattleFailWindow:initReviewBtn()
	local data = self.battleParams
	local eventName = ""

	if self.battleType == xyd.BattleType.TRIAL then
		eventName = xyd.event.NEW_TRIAL_FIGHT
	elseif self.battleType == xyd.BattleType.TOWER or self.battleType == xyd.BattleType.TOWER_PRACTICE then
		eventName = xyd.event.TOWER_SELF_REPORT
	elseif self.battleType == xyd.BattleType.HERO_CHALLENGE or self.battleType == xyd.BattleType.HERO_CHALLENGE_REPORT or self.battleType == xyd.BattleType.HERO_CHALLENGE_SPEED or self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS or self.battleType == xyd.BattleType.ENTRANCE_TEST_REPORT then
		eventName = xyd.event.PARTNER_CHALLENGE_GET_REPORT
	elseif self.battleType == xyd.BattleType.FRIEND then
		eventName = xyd.event.FRIEND_FIGHT_FRIEND
	elseif self.battleType == xyd.BattleType.EXPLORE_OLD_CAMPUS then
		eventName = xyd.event.OLD_BUILDING_FIGHT
	elseif self.battleType == xyd.BattleType.FAIR_ARENA then
		eventName = xyd.event.FAIR_ARENA_BATTLE_REPORT
	elseif self.battleType == xyd.BattleType.NEW_PARTNER_WARMUP then
		eventName = xyd.event.NEW_PARTNER_WARMUP_FIGHT
	elseif self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT then
		eventName = xyd.event.ACADEMY_ASSESSMENT_REPORT
	elseif self.battleType == xyd.BattleType.GALAXY_TRIP_BATTLE then
		eventName = xyd.event.GALAXY_TRIP_GRID_BATTLE
	elseif self.battleType == xyd.BattleType.GALAXY_TRIP_SPECIAL_BOSS_BATTLE then
		eventName = xyd.event.GALAXY_TRIP_SPECIAL_BOSS_BATTLE
	end

	UIEventListener.Get(self.battleReviewBtn).onClick = function ()
		xyd.closeWindow("battle_window")
		xyd.closeWindow("battle_win_window")
		xyd.closeWindow("battle_fail_window")
		xyd.closeWindow("battle_fail_v2_window")
		xyd.closeWindow("battle_win_v2_window")
		xyd.models.trial:setIsReport(true)

		if self.battleType == xyd.BattleType.SHRINE_HURDLE then
			local verson = xyd.tables.miscTable:getNumber("battle_version", "value") or 0
			data.battle_report.battle_version = verson

			xyd.BattleController.get():onShrineHurdleReport(data, data.isBoss)
		elseif self.battleType == xyd.BattleType.ACTIVITY_SPFARM then
			local verson = xyd.tables.miscTable:getNumber("battle_version", "value") or 0
			data.battle_report.battle_version = verson

			xyd.BattleController.get():onSpfarmBattle(data)
		elseif self.battleType == xyd.BattleType.GALAXY_TRIP_BATTLE then
			local verson = xyd.tables.miscTable:getNumber("battle_version", "value") or 0
			data.battle_report.battle_version = verson

			xyd.BattleController.get():onGalayTripGridBattleReport(data)
		elseif self.battleType == xyd.BattleType.GALAXY_TRIP_SPECIAL_BOSS_BATTLE then
			local verson = xyd.tables.miscTable:getNumber("battle_version", "value") or 0
			data.battle_report.battle_version = verson

			xyd.BattleController.get():onGalayTripSpecialBossBattleReport(data)
		else
			xyd.EventDispatcher.inner():dispatchEvent({
				name = eventName,
				data = data
			})
		end
	end
end

function BattleFailWindow:checkShowDetail()
	if self.battleType == xyd.BattleType.DUNGEON or self.battleType == xyd.BattleType.ACTIVITY_SPACE_EXPLORE then
		return false
	end

	return true
end

function BattleFailWindow:initLayout()
	local function completeCallback()
		if self:checkShowDetail() then
			self.battleDetailBtn:SetActive(true)
		end

		if self.isReportType then
			self.battleReviewBtn:SetActive(true)
		elseif self.battleType == xyd.BattleType.EXPLORE_OLD_CAMPUS then
			self.battleDetailBtn:X(240)
			self.battleReviewBtn:X(290)

			if self.initNext_ then
				self.battleDetailBtn.transform:X(255)
				self.battleReviewBtn.transform:X(320)
			end
		elseif self.battleType == xyd.BattleType.SHRINE_HURDLE or self.battleType == xyd.BattleType.ACTIVITY_SPFARM then
			self.battleDetailBtn.transform:X(260)
			self.battleReviewBtn.transform:X(320)
		elseif self.battleType == xyd.BattleType.GALAXY_TRIP_BATTLE or self.battleType == xyd.BattleType.GALAXY_TRIP_SPECIAL_BOSS_BATTLE then
			self.battleReviewBtn:SetActive(true)
			self.battleDetailBtn.transform:X(260)
			self.battleReviewBtn.transform:X(320)
		else
			self.battleDetailBtn:X(290)
		end

		self.confirmBtn:SetActive(true)

		if self.nextBtn_ then
			self.nextBtn_:SetActive(true)
		end
	end

	self.layeoutSequence = DG.Tweening.DOTween.Sequence():OnComplete(completeCallback)

	self.pvpGroup:SetActive(false)
	self.improveGroup:SetActive(false)

	self.confirmBtnLabel.text = __("CONFIRM")

	self:initReviewBtn()

	local function pvpFun()
		self.pvpGroup:SetLocalScale(0, 0, 1)
		self.pvpGroup:SetActive(true)
		self.layeoutSequence:Append(self.pvpGroup.transform:DOScale(Vector3(1, 1, 1), 0.16))
	end

	local function pveFun()
		self.improveGroup:SetLocalScale(0, 0, 1)
		self.improveGroup:SetActive(true)
		self.layeoutSequence:Append(self.improveGroup.transform:DOScale(Vector3(1, 1, 1), 0.16))

		if self.isNewVer then
			self.refer_y = 340 + -569 - self.bottomNode.transform.localPosition.y
		else
			self.refer_y = self.confirmBtn.transform.localPosition.y
		end

		if (self.battleType == xyd.BattleType.TOWER or self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT) and not self.isNewVer then
			self.battleDetailBtn:SetLocalPosition(270, -150, 0)
			self.battleReviewBtn:SetLocalPosition(330, -150, 0)
		else
			self.battleDetailBtn:Y(self.refer_y)
			self.battleReviewBtn:Y(self.refer_y)
		end
	end

	if self.battleType == xyd.BattleType.CAMPAIGN or self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT or self.battleType == xyd.BattleType.DAILY_QUIZ or self.battleType == xyd.BattleType.TOWER or self.battleType == xyd.BattleType.TOWER_PRACTICE or self.battleType == xyd.BattleType.TRIAL or self.battleType == xyd.BattleType.EXPLORE_ADVENTURE or self.battleType == xyd.BattleType.TIME_CLOISTER_BATTLE or self.battleType == xyd.BattleType.TIME_CLOISTER_EXTRA or self.battleType == xyd.BattleType.ENTRANCE_TEST then
		self:initImproveGroup()
		pveFun()
	elseif self.battleType == xyd.BattleType.SPORTS_PVP then
		self:initSportGroup()
		pvpFun()
	elseif self.battleType == xyd.BattleType.DUNGEON then
		self:initDungeon()
		pvpFun()
	elseif self.battleType == xyd.BattleType.ARENA then
		self:initArena()
		pvpFun()
	elseif self.battleType == xyd.BattleType.ARENA_3v3 then
		self:initArena3v3()
		pvpFun()
	elseif self.battleType == xyd.BattleType.ARENA_ALL_SERVER then
		self:initArenaAllServerScore()
		pvpFun()
	elseif self.battleType == xyd.BattleType.ARENA_TEAM then
		self:initArenaTeam()
		pvpFun()
	elseif self.battleType == xyd.BattleType.FRIEND_BOSS then
		-- Nothing
	elseif self.battleType == xyd.BattleType.FRIEND then
		self:initFriend()
		pvpFun()
	elseif self.battleType == xyd.BattleType.ARCTIC_EXPEDITION then
		pvpFun()
		self:initCellInfo()
	elseif self.battleType == xyd.BattleType.FRIEND_TEAM_BOSS then
		self:initFriendTeamBoss()
		pvpFun()
	elseif self.battleType == xyd.BattleType.FRIEND_TEAM_BOSS_REPORT then
		self:initFriendTeamBossReport()
		pvpFun()
	elseif self.battleType == xyd.BattleType.GUILD_BOSS then
		self:initGuildBoss()
		self.pveDropGroup.gameObject:SetActive(true)
		self.pveDropGroup.transform:SetLocalScale(0, 0, 0)
		self.layeoutSequence:Append(self.pveDropGroup.transform:DOScale(Vector3(1, 1, 1), 0.16))
	elseif self.battleType == xyd.BattleType.WORLD_BOSS then
		self:initWorldBoss()
		pveFun()
		self.improveGroup:SetActive(false)
	elseif self.battleType == xyd.BattleType.GUILD_WAR then
		self:initGuildWar()
		pvpFun()
	elseif self.battleType == xyd.BattleType.FAIR_ARENA then
		self:initGuildWar()
		pvpFun()
		self.battleReviewBtn:X(320)
		self.battleDetailBtn:X(260)
	elseif self.battleType == xyd.BattleType.EXPLORE_OLD_CAMPUS then
		self.battleCheckBuffBtn:SetActive(true)
		self.battleReviewBtn:SetActive(true)
		self:initOldCampus()
	elseif self.battleType == xyd.BattleType.NEW_PARTNER_WARMUP then
		local rewardList = xyd.tables.newPartnerWarmUpStageTable:getReward(self.stageId)

		for __, itemData in pairs(rewardList) do
			local itemId = itemData[1]
			local itemNum = itemData[2]
			local itemIcon = xyd.getItemIcon({
				showSellLable = false,
				uiRoot = self.pveDropGroup,
				itemID = itemId,
				num = itemNum
			})
		end

		self.pveDropGroup:SetLocalScale(0, 0, 0)
		self.pveDropGroup:SetActive(true)
		self.layeoutSequence:Append(self.pveDropGroup.transform:DOScale(Vector3(1, 1, 1), 0.16))
	elseif self.battleType == xyd.BattleType.ACTIVITY_SPACE_EXPLORE then
		self.pvpGroup:SetActive(false)
		self.battleDetailBtn:SetActive(false)

		self.labelAdvice.text = __("FAIL_ADVICE")

		self.improveGroup:SetActive(true)

		local tmp = NGUITools.AddChild(self.improveGroup.gameObject, self.groupPartner.gameObject)

		self.groupEquip:SetActive(false)
		self.groupPartner:SetActive(false)
		self.groupSummon:SetActive(false)

		local tmp_btn = tmp:NodeByName("improvePartnerBtn").gameObject
		local tmp_label = tmp:ComponentByName("labelPartner", typeof(UILabel))
		local tmp_btn_uiSprite = tmp:ComponentByName("improvePartnerBtn", typeof(UISprite))

		xyd.setUISpriteAsync(tmp_btn_uiSprite, nil, "activity_space_explore_btn_sb_dy", nil, , true)

		tmp_label.text = __("SPACE_EXPLORE_TEXT_12")

		UIEventListener.Get(tmp_btn).onClick = function ()
			xyd.WindowManager.get():openWindow("activity_space_explore_team_window")
			xyd.WindowManager.get():closeWindow(self.name_)
		end

		local left_tmp = NGUITools.AddChild(self.improveGroup.gameObject, self.groupPartner.gameObject)

		left_tmp.gameObject:X(-173)

		local left_tmp_btn = left_tmp:NodeByName("improvePartnerBtn").gameObject
		local left_tmp_label = left_tmp:ComponentByName("labelPartner", typeof(UILabel))
		local left_tmp_btn_uiSprite = left_tmp:ComponentByName("improvePartnerBtn", typeof(UISprite))

		xyd.setUISpriteAsync(left_tmp_btn_uiSprite, nil, "activity_space_explore_btn_sb_bg", nil, , true)

		left_tmp_label.text = __("SPACE_EXPLORE_TEXT_29")

		UIEventListener.Get(left_tmp_btn).onClick = function ()
			xyd.WindowManager.get():closeWindow("activity_space_explore_map_window")
			xyd.WindowManager.get():closeWindow("activity_window")

			local params = xyd.tables.getWayTable:getGoParam(xyd.GoWayId.ACTIVITY_SPACE_EXPLORE_SUPPLY)

			xyd.WindowManager.get():openWindow("activity_window", params[1])
			xyd.WindowManager.get():closeWindow(self.name_)
		end

		local right_tmp = NGUITools.AddChild(self.improveGroup.gameObject, self.groupPartner.gameObject)

		right_tmp.gameObject:X(173)

		local right_tmp_btn = right_tmp:NodeByName("improvePartnerBtn").gameObject
		local right_tmp_label = right_tmp:ComponentByName("labelPartner", typeof(UILabel))
		local right_tmp_btn_uiSprite = right_tmp:ComponentByName("improvePartnerBtn", typeof(UISprite))

		xyd.setUISpriteAsync(right_tmp_btn_uiSprite, nil, "activity_space_explore_btn_sb_zj", nil, , true)

		right_tmp_label.text = __("SPACE_EXPLORE_TEXT_30")

		UIEventListener.Get(right_tmp_btn).onClick = function ()
			xyd.WindowManager.get():closeWindow("activity_space_explore_map_window")
			xyd.WindowManager.get():closeWindow("activity_window")

			local params = xyd.tables.getWayTable:getGoParam(xyd.GoWayId.ACTIVITY_SPACE_EXPLORE_TEAM)

			xyd.WindowManager.get():openWindow("activity_window", params[1])
			xyd.WindowManager.get():closeWindow(self.name_)
		end
	elseif self.battleType == xyd.BattleType.SHRINE_HURDLE then
		self.battleReviewBtn:SetActive(true)
		self.battleDetailBtn.transform:X(260)
		self:updateShrineHurdlePart()
	elseif self.battleType == xyd.BattleType.HERO_CHALLENGE or self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS or self.battleType == xyd.BattleType.HERO_CHALLENGE_REPORT or self.battleType == xyd.BattleType.LIBRARY_WATCHER_STAGE_FIGHT2 or self.battleType == xyd.BattleType.FRIEND_BOSS or self.battleType == xyd.BattleType.SPORTS_SHOW or self.battleType == xyd.BattleType.PARTNER_STATION or self.battleType == xyd.BattleType.ICE_SECRET_BOSS or self.battleType == xyd.BattleType.BEACH_ISLAND or self.battleType == xyd.BattleType.ENCOUNTER_STORY or self.battleType == xyd.BattleType.ENTRANCE_TEST_REPORT or self.battleType == xyd.BattleType.LIMIT_CALL_BOSS then
		self.layeoutSequence:Append(self.pveDropGroup.transform:DOScale(Vector3(1, 1, 1), 0.16))
	elseif self.battleType == xyd.BattleType.ACTIVITY_SPFARM then
		self.battleReviewBtn:SetActive(true)
		self:initSpfarm()
		pvpFun()
	elseif self.battleType == xyd.BattleType.GALAXY_TRIP_BATTLE or self.battleType == xyd.BattleType.GALAXY_TRIP_SPECIAL_BOSS_BATTLE then
		self.battleReviewBtn:SetActive(true)
		self:initImproveGroup()
		pveFun()
	else
		pvpFun()
	end

	UIEventListener.Get(self.battleDetailBtn).onClick = function ()
		if self.labelTime then
			self.stopAutoBattle = true

			self.labelTime:SetActive(false)
		end

		if self.battleParams.battle_report_backend then
			local real_battle_report = self.battleParams.battle_report_backend

			xyd.WindowManager.get():openWindow("battle_detail_data_window", {
				alpha = 0.7,
				battle_params = self.battleParams.battle_report_backend,
				real_battle_report = real_battle_report,
				die_info = real_battle_report.die_info
			})
		else
			xyd.WindowManager.get():openWindow("battle_detail_data_window", {
				alpha = 0.7,
				battle_params = self.battleParams,
				real_battle_report = self.params_.real_battle_report
			})
		end
	end

	UIEventListener.Get(self.battleCheckBuffBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_explore_old_campus_check_buff_window", {
			buff_list = self.buffIds_
		})
	end

	UIEventListener.Get(self.confirmBtn).onClick = handler(self, self.closeSelf)

	if self.recordID > 0 then
		self.labelRecord_.text = self.recordID

		self.labelRecord_:SetActive(true)
	end
end

function BattleFailWindow:closeSelf()
	if self.battleType == xyd.BattleType.TIME_CLOISTER_EXTRA then
		local time_cloister_probe_wd = xyd.WindowManager.get():getWindow("time_cloister_probe_window")

		if time_cloister_probe_wd then
			time_cloister_probe_wd:showItemsTween(self.battleParams.items, xyd.TimeCloisterExtraEvent.ENCOUNTER_BATTLE)
		end
	end

	xyd.WindowManager.get():closeWindow("battle_window")
	xyd.WindowManager.get():closeWindow(self.name_)
end

function BattleFailWindow:initImproveGroup()
	self.labelAdvice.text = __("FAIL_ADVICE")
	self.labelEquip.text = __("EQUIP_STRENGTHEN")
	self.labelPartner.text = __("PARTNER_LEV_UP")
	self.labelSummon.text = __("PARTNER_SUMMON")

	UIEventListener.Get(self.improveEquipBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("backpack_window", {}, function ()
			self.isOpenCampaign = false

			xyd.WindowManager.get():closeAllWindows({
				loading_window = true,
				main_window = true,
				guide_window = true,
				backpack_window = true
			})
			xyd.WindowManager.get():getWindow("main_window"):updateWindowDisplay(xyd.WindowManager.get():getWindow("backpack_window"):hideType())
		end)
	end

	UIEventListener.Get(self.improvePartnerBtn).onClick = function ()
		self.isOpenCampaign = false

		xyd.WindowManager.get():openWindow("slot_window", {}, function ()
			xyd.WindowManager.get():closeAllWindows({
				slot_window = true,
				main_window = true,
				loading_window = true,
				guide_window = true
			})
			xyd.WindowManager.get():getWindow("main_window"):updateWindowDisplay(xyd.WindowManager.get():getWindow("slot_window"):hideType())
		end)
	end

	UIEventListener.Get(self.summonBtn).onClick = function ()
		self.isOpenCampaign = false

		xyd.WindowManager.get():openWindow("summon_window", {}, function ()
			xyd.WindowManager.get():closeAllWindows({
				summon_window = true,
				main_window = true,
				loading_window = true,
				guide_window = true
			})
			xyd.WindowManager.get():getWindow("main_window"):updateWindowDisplay(xyd.WindowManager.get():getWindow("summon_window"):hideType())
		end)
	end

	if self.battleType == xyd.BattleType.TOWER then
		self:initTowerRetry()
	end

	if self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT then
		self:initAcademyRetry()
	end
end

function BattleFailWindow:initGuildWar()
	self.labelLeftPlayerName.text = self.battleParams.self_info.player_name
	self.labelRightPlayerName.text = self.battleParams.enemy_info.player_name
	local paramsA = {
		avatarID = self.battleParams.self_info.avatar_id,
		lev = self.battleParams.self_info.lev
	}

	if self.battleParams.self_info.avatar_frame_id then
		paramsA.avatar_frame_id = self.battleParams.self_info.avatar_frame_id
	end

	local paramsB = {
		avatarID = self.battleParams.enemy_info.avatar_id,
		lev = self.battleParams.enemy_info.lev
	}

	if self.battleParams.enemy_info.avatar_frame_id then
		paramsB.avatar_frame_id = self.battleParams.enemy_info.avatar_frame_id
	end

	local iconA = PlayerIcon.new(self.groupLeftIcon_)
	local iconB = PlayerIcon.new(self.groupRightIcon_)

	iconA:setInfo(paramsA)
	iconB:setInfo(paramsB)
	self.labelLeftScoreText:SetActive(false)
	self.labelRightScoreText:SetActive(false)
	self.labelLeftScore:SetActive(false)
	self.labelRightScore:SetActive(false)
	self.labelLeftScoreChange:SetActive(false)
	self.labelRightScoreChange:SetActive(false)
end

function BattleFailWindow:initOldCampus()
	local nextId = self.battleParams.stage_id
	local selectInfo = xyd.db.misc:getValue("old_building_setting")

	if selectInfo then
		selectInfo = json.decode(selectInfo)
	else
		selectInfo = {}
	end

	if nextId > 0 and selectInfo.select and tonumber(selectInfo.select) >= 2 and xyd.models.oldSchool.failNum_ <= 50 then
		local function callback()
			local win = xyd.WindowManager.get():getWindow(self.name_)

			if not win then
				return
			end

			if self.autoBattle and self.stopAutoBattle then
				self.autoBattle = false

				return
			end

			self:close()
			xyd.models.oldSchool:autoBattle(nextId, true)
		end

		self:initNextBtn("NEXT_BATTLE", callback)
		self.nextBtn_.transform:X(120)

		self.nextBtn_:GetComponent(typeof(UIWidget)).width = 192

		self.confirmBtn.transform:X(-120)

		self.confirmBtn:GetComponent(typeof(UIWidget)).width = 192
		self.initNext_ = true

		if not self.labelTime then
			self.labelTime = NGUITools.AddChild(self.winGroup.gameObject, self.nextBtn_button_label.gameObject):GetComponent(typeof(UILabel))
			self.labelTime.transform.name = "labelTime"
		end

		self.labelTime:SetActive(true)

		self.labelTime.color = Color.New2(4292346111.0)
		self.labelTime.fontSize = 28

		if self.isNewVer then
			self.labelTime:SetLocalPosition(120, -622, 0)
		else
			self.labelTime:SetLocalPosition(120, -309, 0)
		end

		local countdown = 3
		local setTime = nil

		function setTime()
			self.labelTime.text = tostring(countdown) .. "s"

			self:waitForTime(1, setTime)

			if countdown <= 0 then
				self.labelTime:SetActive(false)

				return
			end

			countdown = countdown - 1
		end

		setTime()

		self.nextBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		self:waitForTime(1, function ()
			self.nextBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		end)
		self:waitForTime(3, function ()
			self.autoBattle = true

			callback()
		end)
	end
end

function BattleFailWindow:initArenaTeam()
	local battleIndex = xyd.models.arenaTeam:getNowBattleIndex()
	local tempIndex = xyd.models.arenaTeam:getTempIndex()

	if tempIndex then
		battleIndex = tempIndex

		xyd.models.arenaTeam:resetTempIndex()
	end

	local data = self.battleParams

	if self.battleParams.matchNum and self.battleParams.matchNum > 0 then
		battleIndex = self.battleParams.matchNum
	end

	self.labelLeftPlayerName.text = data.self_info.players[battleIndex].player_name
	self.labelRightPlayerName.text = data.enemy_info.players[battleIndex].player_name
	local paramsA = {
		avatarID = data.self_info.players[battleIndex].avatar_id,
		lev = data.self_info.players[battleIndex].lev,
		avatar_frame_id = data.self_info.players[battleIndex].avatar_frame_id
	}
	local paramsB = {
		avatarID = data.enemy_info.players[battleIndex].avatar_id,
		lev = data.enemy_info.players[battleIndex].lev,
		avatar_frame_id = data.enemy_info.players[battleIndex].avatar_frame_id
	}
	local iconA = PlayerIcon.new(self.groupLeftIcon_)
	local iconB = PlayerIcon.new(self.groupRightIcon_)

	iconA:setInfo(paramsA)
	iconB:setInfo(paramsB)

	if not self.params_.is_last then
		self.confirmBtnLabel.text = __("NEXT_BATTLE")
	end

	self.labelLeftScoreText:SetActive(false)
	self.labelRightScoreText:SetActive(false)
	self.labelLeftScore:SetActive(false)
	self.labelRightScore:SetActive(false)
	self.labelLeftScoreChange:SetActive(false)
	self.labelRightScoreChange:SetActive(false)
end

function BattleFailWindow:initArenaAllServerScore()
	self.labelLeftPlayerName.text = self.battleParams.self_info.player_name
	self.labelRightPlayerName.text = self.battleParams.enemy_info.player_name
	local paramsA = {
		avatarID = self.battleParams.self_info.avatar_id,
		lev = self.battleParams.self_info.lev,
		avatar_frame_id = self.battleParams.self_info.avatar_frame_id
	}
	local paramsB = {
		avatarID = self.battleParams.enemy_info.avatar_id,
		lev = self.battleParams.enemy_info.lev,
		avatar_frame_id = self.battleParams.enemy_info.avatar_frame_id
	}
	local iconA = PlayerIcon.new(self.groupLeftIcon_)
	local iconB = PlayerIcon.new(self.groupRightIcon_)

	iconA:setInfo(paramsA)
	iconB:setInfo(paramsB)

	if not self.params_.is_last then
		self.confirmBtnLabel.text = __("NEXT_BATTLE")
	end

	self.labelLeftScoreText:SetActive(false)
	self.labelRightScoreText:SetActive(false)
	self.labelLeftScore:SetActive(false)
	self.labelRightScore:SetActive(false)
	self.labelLeftScoreChange:SetActive(false)
	self.labelRightScoreChange:SetActive(false)
end

function BattleFailWindow:initArena3v3()
	self.labelLeftPlayerName.text = self.battleParams.self_info.player_name
	self.labelRightPlayerName.text = self.battleParams.enemy_info.player_name
	local paramsA = {
		avatarID = self.battleParams.self_info.avatar_id,
		lev = self.battleParams.self_info.lev,
		avatar_frame_id = self.battleParams.self_info.avatar_frame_id
	}
	local paramsB = {
		avatarID = self.battleParams.enemy_info.avatar_id,
		lev = self.battleParams.enemy_info.lev,
		avatar_frame_id = self.battleParams.enemy_info.avatar_frame_id
	}
	local iconA = PlayerIcon.new(self.groupLeftIcon_)
	local iconB = PlayerIcon.new(self.groupRightIcon_)

	iconA:setInfo(paramsA)
	iconB:setInfo(paramsB)

	if not self.params_.is_last then
		self.confirmBtnLabel.text = __("NEXT_BATTLE")
	end

	self.labelLeftScoreText:SetActive(false)
	self.labelRightScoreText:SetActive(false)
	self.labelLeftScore:SetActive(false)
	self.labelRightScore:SetActive(false)
	self.labelLeftScoreChange:SetActive(false)
	self.labelRightScoreChange:SetActive(false)
end

function BattleFailWindow:initSportGroup()
	self.labelLeftPlayerName.text = self.battleParams.self_info.player_name
	self.labelRightPlayerName.text = self.battleParams.enemy_info.player_name
	local paramsA = {
		avatarID = self.battleParams.self_info.avatar_id,
		lev = self.battleParams.self_info.lev,
		avatar_frame_id = self.battleParams.self_info.avatar_frame_id
	}
	local paramsB = {
		avatarID = self.battleParams.enemy_info.avatar_id,
		lev = self.battleParams.enemy_info.lev,
		avatar_frame_id = self.battleParams.enemy_info.avatar_frame_id
	}
	local iconA = PlayerIcon.new(self.groupLeftIcon_)
	local iconB = PlayerIcon.new(self.groupRightIcon_)

	iconA:setInfo(paramsA)
	iconB:setInfo(paramsB)

	self.labelLeftScoreText.text = __("SCORE2")
	self.labelRightScoreText.text = __("SCORE2")
	self.labelLeftScore.text = self.battleParams.score
	self.labelRightScore.text = self.battleParams.enemy_info.score
	local changeTextLeft = xyd.checkCondition(self.battleParams.self_change > 0, "+", "") .. self.battleParams.self_change
	self.labelLeftScoreChange.text = "(" .. changeTextLeft .. ")"
	self.labelRightScoreChange.text = ""
	self.labelRightScore.gameObject:GetComponent(typeof(UIWidget)).pivot = UIWidget.Pivot.Center

	self.labelRightScore:X(0)
end

function BattleFailWindow:initArena()
	self.labelLeftPlayerName.text = self.battleParams.self_info.player_name
	local paramsA = {
		avatarID = self.battleParams.self_info.avatar_id,
		lev = self.battleParams.self_info.lev,
		avatar_frame_id = self.battleParams.self_info.avatar_frame_id
	}
	local paramsB = {
		avatarID = self.battleParams.enemy_info.avatar_id,
		lev = self.battleParams.enemy_info.lev,
		avatar_frame_id = self.battleParams.enemy_info.avatar_frame_id
	}

	if self.battleParams.enemy_info.is_robot == 1 then
		local allInfo = xyd.tables.activityEntranceTestRobotTable:getAllInfo(tonumber(self.battleParams.enemy_info.player_id))
		self.labelRightPlayerName.text = allInfo.name
		paramsB.avatarID = allInfo.avatar
		paramsB.lev = allInfo.lev
	else
		self.labelRightPlayerName.text = self.battleParams.enemy_info.player_name
	end

	local iconA = PlayerIcon.new(self.groupLeftIcon_)
	local iconB = PlayerIcon.new(self.groupRightIcon_)

	iconA:setInfo(paramsA)
	iconB:setInfo(paramsB)

	self.labelLeftScoreText.text = __("SCORE2")
	self.labelRightScoreText.text = __("SCORE2")
	self.labelLeftScore.text = self.battleParams.score
	self.labelRightScore.text = self.battleParams.enemy_info.score
	local changeTextLeft = xyd.checkCondition(self.battleParams.self_change > 0, "+", "") .. self.battleParams.self_change
	local changeTextRight = ""

	if self.battleParams.enemy_change then
		changeTextRight = xyd.checkCondition(self.battleParams.enemy_change > 0, "+", "") .. self.battleParams.enemy_change
		changeTextRight = "(" .. changeTextRight .. ")"
	end

	self.labelLeftScoreChange.text = "(" .. changeTextLeft .. ")"
	self.labelRightScoreChange.text = changeTextRight

	if changeTextRight == "" then
		self.labelRightScore.gameObject:GetComponent(typeof(UIWidget)).pivot = UIWidget.Pivot.Center

		self.labelRightScore:X(0)
	end
end

function BattleFailWindow:initDungeon()
	self.groupRightLabels_:SetActive(false)
	self.groupLeftLabels_:SetActive(false)
	self.pvpGroup:SetActive(true)

	local battleReport = self.battleParams.battle_report
	local teamA = battleReport.teamA
	local teamB = battleReport.teamB
	local paramsA = {
		noClick = true,
		tableID = teamA[1].table_id,
		lev = teamA[1].level,
		isMonster = teamA[1].isMonster,
		awake = teamA[1].awake,
		show_skin = teamA[1].show_skin,
		equips = {
			0,
			0,
			0,
			0,
			0,
			0,
			teamA[1].skin_id
		},
		uiRoot = self.groupLeftIcon_
	}
	local iconA = xyd.getHeroIcon(paramsA)
	local index = -1

	for i = 1, #teamB do
		local hero = teamB[i]

		if index == -1 and hero.status and hero.status.hp > 0 then
			index = i
		end
	end

	local paramsB = {
		noClick = true,
		tableID = teamB[index].table_id,
		lev = teamB[index].level,
		isMonster = teamB[index].isMonster,
		awake = teamB[index].awake,
		uiRoot = self.groupRightIcon_
	}
	local iconB = xyd.getHeroIcon(paramsB)
	local isAlive = xyd.models.dungeon:checkPartnerAlive(teamA[1].table_id)

	if not isAlive then
		iconA:setGrey(isAlive)
	end
end

function BattleFailWindow:initFriendBoss()
	local group = eui.Group.new()

	self.winGroup:addChild(group)

	local harm = self.battleParams.total_harm
	local score = self.battleParams.score
	group.horizontalCenter = 0
	group.y = 200
	group.width = 720
	group.height = 1
	local label1 = xyd:getLabel({
		b = true,
		c = 6052956,
		s = 22,
		t = __(_G, "FRIEND_SCORE"),
		f = xyd.TEXT_FONT
	})

	group:addChild(label1)

	label1.left = 268
	label1.top = 118
	local label2 = xyd:getLabel({
		b = true,
		c = 6052956,
		s = 22,
		t = __(_G, "FRIEND_HARM"),
		f = xyd.TEXT_FONT
	})

	group:addChild(label2)

	label2.left = 268
	label2.top = 118 + label1.height * label1.scaleY + 22
	local label3 = xyd:getLabel({
		b = true,
		c = 27084,
		s = 24,
		t = "+" .. tostring(String(_G, score)),
		f = xyd.TEXT_FONT
	})

	group:addChild(label3)

	label3.left = 268 + label1.width * label1.scaleX + 5
	label3.top = 118
	local label4 = xyd:getLabel({
		b = true,
		c = 27084,
		s = 24,
		t = String(_G, harm),
		f = xyd.TEXT_FONT
	})

	group:addChild(label4)

	label4.left = 268 + label2.width * label2.scaleX + 5
	label4.top = label2.top
	group.scaleX = 0
	group.scaleY = 0

	self.layeoutSequence:add(TweenLite:to(group, 0.16, {
		scaleY = 1,
		scaleX = 1
	}))

	local callback = nil

	function callback()
		xyd.WindowManager.get():closeWindow("battle_window")
		xyd.WindowManager.get():closeWindow()
		Friend:get():fightBoss(self.battleParams.friend_id)
	end

	if Friend:get():getTili() > 0 and Friend:get():checkHasBoss(self.battleParams.friend_id) then
		self:initNextBtn("FRIEND_RE_FIGHT_BOSS", callback)
	end
end

function BattleFailWindow:initFriend()
	if not self.battleParams.self_info then
		return
	end

	self.labelLeftPlayerName.text = self.battleParams.self_info.player_name
	self.labelRightPlayerName.text = self.battleParams.enemy_info.player_name
	local paramsA = {
		avatarID = self.battleParams.self_info.avatar_id,
		lev = self.battleParams.self_info.lev,
		avatar_frame_id = self.battleParams.self_info.avatar_frame_id
	}
	local paramsB = {
		avatarID = self.battleParams.enemy_info.avatar_id,
		lev = self.battleParams.enemy_info.lev,
		avatar_frame_id = self.battleParams.enemy_info.avatar_frame_id
	}
	local iconA = PlayerIcon.new(self.groupLeftIcon_)
	local iconB = PlayerIcon.new(self.groupRightIcon_)

	iconA:setInfo(paramsA)
	iconB:setInfo(paramsB)
	self.labelLeftScoreText:SetActive(false)
	self.labelRightScoreText:SetActive(false)
	self.labelLeftScore:SetActive(false)
	self.labelRightScore:SetActive(false)
	self.labelLeftScoreChange:SetActive(false)
	self.labelRightScoreChange:SetActive(false)

	local callback = nil

	function callback()
		xyd.WindowManager.get():closeWindow("battle_window")
		xyd.WindowManager.get():closeWindow(self.name_)
		xyd.models.friend:fightFriend(self.battleParams.enemy_info.player_id)
	end

	self:initNextBtn("FRIEND_RE_FIGHT", callback)
end

function BattleFailWindow:initCellInfo()
	if not self.battleParams.self_info then
		return
	end

	local cell_id = self.battleParams.cell_id
	self.labelLeftPlayerName.text = self.battleParams.self_info.player_name
	local paramsA = {
		avatarID = self.battleParams.self_info.avatar_id,
		lev = self.battleParams.self_info.lev,
		avatar_frame_id = self.battleParams.self_info.avatar_frame_id
	}
	local cell_type = xyd.tables.arcticExpeditionCellsTable:getCellType(cell_id)
	self.labelRightPlayerName.text = xyd.tables.arcticExpeditionCellsTypeTextTable:getName(cell_type)
	local cellImg = xyd.tables.arcticExpeditionCellsTypeTable:getIconImg(cell_type)
	local imgSprite = self.groupRightIcon_:GetComponent(typeof(UISprite))
	imgSprite.width = 114
	imgSprite.height = 132

	xyd.setUISpriteAsync(imgSprite, nil, cellImg)

	local iconA = PlayerIcon.new(self.groupLeftIcon_)

	self.pvpGroup:NodeByName("vsIcon"):Y(20)
	self.groupLeftIcon_.transform:Y(-7)
	self.groupRightIcon_.transform:Y(-7)
	iconA:setInfo(paramsA)
	self.labelLeftScoreText:SetActive(false)
	self.labelRightScoreText:SetActive(false)
	self.labelLeftScore:SetActive(false)
	self.labelRightScore:SetActive(false)
	self.labelLeftScoreChange:SetActive(false)
	self.labelRightScoreChange:SetActive(false)
end

function BattleFailWindow:initTowerRetry()
	local function callback()
		local tickts_num = xyd.models.backpack:getItemNumByID(xyd.ItemID.TOWER_TICKET)

		if tickts_num > 0 then
			local timeStamp = xyd.db.misc:getValue("tower_fail_retry_time_stamp")

			if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
				xyd.WindowManager.get():openWindow("gamble_tips_window", {
					type = "tower_fail_retry",
					wndType = self.curWindowType_,
					callback = function ()
						xyd.WindowManager.get():closeWindow("battle_window")
						xyd.WindowManager.get():closeWindow(self.name_)
						xyd.models.towerMap:TowerBattle(self.stageId)
					end,
					text = __("SCHOOL_PRACTICE_RETRY_CONFIRM")
				})
			else
				xyd.WindowManager.get():closeWindow("battle_window")
				xyd.WindowManager.get():closeWindow(self.name_)
				xyd.models.towerMap:TowerBattle(self.stageId)
			end
		else
			xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.TOWER_TICKET)))
		end
	end

	self:initNextBtn("SCHOOL_PRACTICE_RETRY", callback)
end

function BattleFailWindow:initAcademyRetry()
	local academy_stageId = xyd.db.misc:getValue("cur_academy_assessment_stage_id")
	academy_stageId = xyd.checkCondition(academy_stageId, tonumber(academy_stageId), 0)

	local function callback()
		local win = xyd.WindowManager.get():getWindow(self.name_)

		if not win then
			return
		end

		if self.autoBattle and self.stopAutoBattle then
			self.autoBattle = false

			return
		end

		local tickts_num = xyd.models.academyAssessment:getChallengeTimes()

		if tickts_num > 0 then
			local timeStamp = xyd.db.misc:getValue("academy_assessment_retry_time_stamp")

			if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
				xyd.WindowManager.get():openWindow("gamble_tips_window", {
					type = "academy_assessment_retry",
					wndType = self.curWindowType_,
					callback = function ()
						xyd.models.academyAssessment:onNextBattle(academy_stageId)
						xyd.WindowManager.get():closeWindow("battle_window")
						xyd.WindowManager.get():closeWindow(self.name_)
					end,
					text = __("SCHOOL_PRACTICE_RETRY_CONFIRM")
				})
			else
				xyd.models.academyAssessment:onNextBattle(academy_stageId)
				xyd.WindowManager.get():closeWindow("battle_window")
				xyd.WindowManager.get():closeWindow(self.name_)
			end
		else
			xyd.showToast(__("SCHOOL_PRACTICE_CHALLENGE_TICKETS_NOT_ENOUGH"))
		end
	end

	self:initNextBtn("SCHOOL_PRACTICE_RETRY", callback)

	local abbr2 = xyd.db.misc:getValue("academy_assessment_battle_set_ticket_end")

	if abbr2 and tonumber(abbr2) ~= 0 then
		if not self.labelTime then
			self.labelTime = NGUITools.AddChild(self.winGroup.gameObject, self.nextBtn_button_label.gameObject):GetComponent(typeof(UILabel))
			self.labelTime.transform.name = "labelTime"
		end

		self.labelTime:SetActive(true)

		self.labelTime.color = Color.New2(4292346111.0)
		self.labelTime.fontSize = 28

		if self.isNewVer then
			self.labelTime:SetLocalPosition(140, -622, 0)
		else
			self.labelTime:SetLocalPosition(140, -309, 0)
		end

		local countdown = 3
		local setTime = nil

		function setTime()
			self.labelTime.text = tostring(countdown) .. "s"

			self:waitForTime(1, setTime)

			if countdown <= 0 then
				self.labelTime:SetActive(false)

				return
			end

			countdown = countdown - 1
		end

		setTime()
		self:waitForTime(3, function ()
			self.autoBattle = true

			callback()
		end)
	end
end

function BattleFailWindow:initNextBtn(str, callback)
	self.nextBtn_ = NGUITools.AddChild(self.winGroup.gameObject, self.confirmBtn.gameObject)
	self.nextBtn_sprite = self.nextBtn_:GetComponent(typeof(UISprite))
	self.nextBtn_button_label = self.nextBtn_:ComponentByName("button_label", typeof(UILabel))

	xyd.setUISpriteAsync(self.nextBtn_sprite, nil, "blue_btn_65_65", nil, )

	self.nextBtn_button_label.color = Color.New2(4294967295.0)
	self.nextBtn_button_label.effectColor = Color.New2(473916927)
	self.nextBtn_button_label.text = __(str)
	self.nextBtn_.transform.name = "next_btn"

	self.nextBtn_:SetActive(false)

	UIEventListener.Get(self.nextBtn_.gameObject).onClick = handler(self, callback)

	if self.isNewVer then
		self.confirmBtn:SetLocalPosition(-140, -569 - self.bottomNode.transform.localPosition.y, 0)
		self.nextBtn_:SetLocalPosition(140, -569, 0)
	else
		self.confirmBtn:SetLocalPosition(-140, -254, 0)
		self.nextBtn_:SetLocalPosition(140, -254, 0)
	end
end

function BattleFailWindow:initFriendTeamBoss()
	self.labelLeftPlayerName.text = xyd.models.selfPlayer:getPlayerName()
	local bossName = self.battleParams.boss_index == 1 and "FRIEND_TEAM_BOSS_NAME1" or "FRIEND_TEAM_BOSS_NAME2"
	self.labelRightPlayerName.text = __(bossName, self.battleParams.team_info.boss_level)
	local paramsA = {
		avatarID = xyd.models.selfPlayer:getAvatarID(),
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID()
	}
	local iconA = PlayerIcon.new(self.groupLeftIcon_)
	local iconB = PlayerIcon.new(self.groupRightIcon_)

	iconA:setInfo(paramsA)
	iconB:setInfo({})

	local path = xyd.tables.friendTeamBossTable:getBossAvatar(self.battleParams.team_info.boss_level, self.battleParams.boss_index)

	iconB:setAvatarPath(path)
	self.labelLeftScoreText:SetActive(false)
	self.labelRightScoreText:SetActive(false)
	self.labelLeftScore:SetActive(false)
	self.labelRightScore:SetActive(false)
	self.labelLeftScoreChange:SetActive(false)
	self.labelRightScoreChange:SetActive(false)
end

function BattleFailWindow:initFriendTeamBossReport()
	self.labelLeftPlayerName.text = self.battleParams.show_info.player_name
	local bossName = self.battleParams.boss_index == 1 and "FRIEND_TEAM_BOSS_NAME1" or "FRIEND_TEAM_BOSS_NAME2"
	local team_info = xyd.models.friendTeamBoss:getTeamInfo()
	self.labelRightPlayerName.text = __(bossName, team_info.boss_level)
	local paramsA = {
		avatarID = self.battleParams.show_info.avatar_id,
		avatar_frame_id = self.battleParams.show_info.avatar_frame_id
	}
	local iconA = PlayerIcon.new(self.groupLeftIcon_)
	local iconB = PlayerIcon.new(self.groupRightIcon_)

	iconA:setInfo(paramsA)
	iconB:setInfo({})

	local path = xyd.tables.friendTeamBossTable:getBossAvatar(team_info.boss_level, self.battleParams.boss_index)

	iconB:setAvatarPath(path)
	self.labelLeftScoreText:SetActive(false)
	self.labelRightScoreText:SetActive(false)
	self.labelLeftScore:SetActive(false)
	self.labelRightScore:SetActive(false)
	self.labelLeftScoreChange:SetActive(false)
	self.labelRightScoreChange:SetActive(false)
end

function BattleFailWindow:initGuildBoss()
	local bossId = self.battleParams.boss_id
	local awardsDataList = {}

	if self.battleParams.awards and #self.battleParams.awards > 0 then
		local awards = self.battleParams.awards

		for i = 1, #awards do
			table.insert(awardsDataList, {
				awards[i].item_id,
				awards[i].item_num
			})
		end
	else
		awardsDataList = xyd.tables.guildBossTable:getBattleAwards(bossId)
	end

	local exp = xyd.tables.guildBossTable:getGuildExp(bossId)

	for i = 1, #awardsDataList do
		local itemData = awardsDataList[i]
		local itemId = itemData[1]
		local itemNum = itemData[2]

		xyd.getItemIcon({
			showSellLable = false,
			uiRoot = self.pveDropGroup,
			itemID = itemId,
			num = itemNum
		})
	end

	self.pveDropGroup_grid:Reposition()

	self.labelDamage1.text = __("FRIEND_HARM")
	self.labelDamage2.text = xyd.getDisplayNumber(self.battleParams.total_harm)

	self.damageGroup:SetActive(true)
end

function BattleFailWindow:initWorldBoss()
	local awardsDataList = self.battleParams.items

	for i in pairs(awardsDataList) do
		local itemData = awardsDataList[i]

		if itemData ~= nil then
			local itemId = itemData.item_id
			local itemNum = itemData.item_num

			if itemNum ~= nil and itemId ~= nil then
				local itemIcon = xyd.getItemIcon({
					showSellLable = false,
					itemID = itemId,
					num = tonumber(itemNum),
					uiRoot = self.pveDropGroup.gameObject
				})
			end
		end
	end

	self.labelDamage1.text = __("FRIEND_HARM")
	self.labelDamage2.text = xyd.getDisplayNumber(self.battleParams.total_harm)

	self.damageGroup:SetActive(true)
	self.pveDropGroup:SetActive(true)
end

function BattleFailWindow:updateShrineHurdlePart()
	self.shrineHurdleScoreGroup_:SetActive(true)

	local diffLevel = xyd.models.shrineHurdleModel:getDiffNum()
	self.diffTips_.text = __("SHRINE_HURDLE_TEXT03") .. " : " .. diffLevel
	self.shrineHurdleScoreTips_.text = __("SHRINE_HURDLE_TEXT10")
	local addGold, addScore = xyd.models.shrineHurdleModel:getGoldScoreChange()
	self.shrineHurdleScore_.text = "+ " .. addScore
	self.shrineHurdleScoreTips_.text = __("SHRINE_HURDLE_TEXT10")
	local isRecord = nil

	if self.data then
		isRecord = self.data.isRecord
	end

	if not isRecord then
		local addGold, addScore = xyd.models.shrineHurdleModel:getGoldScoreChange()
		self.shrineHurdleScore_.text = "+ " .. addScore
		self.shrineHurdleScoreTips_.text = __("SHRINE_HURDLE_TEXT10")

		if addGold and addGold >= 0 then
			self.shrineHurdleGoldGroup_:SetActive(true)
			self.shrineHurdleHurtGroup_:SetActive(false)

			self.shrineHurdleLabelCoinNum_.text = "+" .. addGold
		elseif self.battleParams.total_harm then
			self.shrineHurdleGoldGroup_:SetActive(false)
			self.shrineHurdleHurtGroup_:SetActive(true)

			self.shrineHurdlehHurtTips_.text = __("WORLD_BOSS_SWEEP_TEXT06")
			self.shrineHurdlehHurt_.text = self.battleParams.total_harm
		end
	else
		self.shrineHurdleGoldGroup_:SetActive(false)
		self.shrineHurdleHurtGroup_:SetActive(false)
		self.shrineHurdleScore_.gameObject:SetActive(false)
		self.shrineHurdleScoreTips_.gameObject:SetActive(false)
		self.scoreGroup_:SetActive(false)

		local partners = self.data.battleParams.battle_report.teamA

		table.sort(partners, function (a, b)
			return a.pos < b.pos
		end)

		for _, partner_info in ipairs(partners) do
			local paramsA = {
				noClick = true,
				tableID = partner_info.table_id,
				lev = partner_info.level,
				show_skin = partner_info.show_skin,
				awake = partner_info.awake,
				equips = partner_info.equips,
				uiRoot = self.shrinePartnerGroup_.gameObject,
				is_vowed = partner_info.is_vowed
			}
			local icon = xyd.getHeroIcon(paramsA)

			icon:setScale(0.8)
		end
	end
end

function BattleFailWindow:willClose()
	BattleFailWindow.super.willClose(self)

	if self.layeoutSequence then
		self.layeoutSequence = nil
	end

	if self.callback then
		self.callback(self.isOpenCampaign)
	end
end

function BattleFailWindow:initSpfarm()
	self.labelLeftPlayerName.text = xyd.Global.playerName
	self.labelRightPlayerName.text = __("ACTIVITY_SPFARM_TEXT23")
	local battleReport = self.battleParams.battle_report
	local teamB = battleReport.teamB
	local index = 1
	local paramsB = {
		noClick = true,
		tableID = teamB[index].table_id,
		lev = teamB[index].level,
		isMonster = teamB[index].isMonster,
		awake = teamB[index].awake,
		uiRoot = self.groupRightIcon_
	}
	local iconB = xyd.getHeroIcon(paramsB)
	local paramsA = {
		avatarID = xyd.models.selfPlayer:getAvatarID(),
		lev = xyd.models.backpack:getLev(),
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID()
	}
	local iconA = PlayerIcon.new(self.groupLeftIcon_)

	iconA:setInfo(paramsA)
	self.labelLeftScoreText:SetActive(false)
	self.labelRightScoreText:SetActive(false)
	self.labelLeftScore:SetActive(false)
	self.labelRightScore:SetActive(false)
	self.labelLeftScoreChange:SetActive(false)
	self.labelRightScoreChange:SetActive(false)
end

return BattleFailWindow
