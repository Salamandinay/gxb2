local BattleWinWindow = class("BattleWinWindow", import(".BaseWindow"))
local Partner = import("app.models.Partner")
local HeroIcon = import("app.components.HeroIcon")
local PlayerIcon = import("app.components.PlayerIcon")
local json = require("cjson")

function BattleWinWindow:ctor(name, params)
	BattleWinWindow.super.ctor(self, name, params)

	self.callback = nil
	self.onOpenCallback = nil
	self.StageTable = xyd.tables.stageTable

	if params and params.listener ~= nil then
		self.callback = params.listener
	end

	if params and params.onOpenCallback ~= nil then
		self.onOpenCallback = params.onOpenCallback
	end

	if params and params.battleParams and params.battleParams.onOpenCallback ~= nil then
		self.onOpenCallback = params.battleParams.onOpenCallback
	end

	self.battleParams = params.battleParams

	if params.battleParams.buff_ids then
		self.buffIds_ = params.battleParams.buff_ids
	end

	self.mapType = params.map_type
	self.stageId = self.battleParams.stage_id or params.stage_id
	self.recordID = self.battleParams.record_id or -1
	self.data = params
	self.battleType = self.battleParams.battle_type or params.battle_type
	self.trialSaveItems = {}
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
		xyd.BattleType.SHRINE_HURDLE_REPORT,
		xyd.BattleType.ENTRANCE_TEST_REPORT
	}
	self.isReportType = false
	self.isNewVer = params.is_new

	if xyd.arrayIndexOf(self.reportTypeList, self.battleType) >= 1 then
		self.isReportType = true
	end

	local battleReportData = params.real_battle_report
	battleReportData = battleReportData or params.battleParams.battle_report

	if battleReportData then
		local mvpPos = xyd.getMVPPartner(battleReportData)
		local teamA = battleReportData.teamA

		for _, teamData in ipairs(teamA) do
			if tonumber(teamData.pos) == mvpPos then
				self.tableId_ = tonumber(teamData.table_id)
				self.skinId_ = tonumber(teamData.skin_id)

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

	if self.isNewVer then
		self.effectName = "shengli_new"
		self.labelImg = "battle_result_text01_" .. xyd.Global.lang
	else
		self.effectName = "shengli"
		self.labelImg = "battle_result_text03_" .. xyd.Global.lang
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

function BattleWinWindow:getPartnerRes(partner)
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

function BattleWinWindow:getUIComponent()
	local winTrans = self.window_.transform
	local winGroup = winTrans:NodeByName("winGroup").gameObject
	self.winGroup = winGroup
	self.mask_ = winTrans:ComponentByName("mask_", typeof(UISprite))
	self.effectTarget_ = winGroup:NodeByName("effectTarget_").gameObject
	self.pvpGroup = winGroup:NodeByName("pvpGroup").gameObject
	self.pveDropGroup = winGroup:NodeByName("pveDropGroup").gameObject
	self.pveDropGroup_grid = winGroup:ComponentByName("pveDropGroup", typeof(UIGrid))
	self.formationGroup = winGroup:NodeByName("formationGroup").gameObject
	self.formation1 = self.formationGroup:NodeByName("formation1").gameObject
	self.formation2 = self.formationGroup:NodeByName("formation2").gameObject
	self.damageGroup = self.winGroup:NodeByName("damageGroup").gameObject
	self.labelDamage1 = self.damageGroup:ComponentByName("labelDamage1", typeof(UILabel))
	self.labelDamage2 = self.damageGroup:ComponentByName("labelDamage2", typeof(UILabel))
	self.labelFormation = self.formationGroup:ComponentByName("formationText/labelFormation", typeof(UILabel))
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
	self.progressGroup_ = winGroup:NodeByName("progressGroup").gameObject
	self.progressBar_ = self.progressGroup_:ComponentByName("progressBar", typeof(UIProgressBar))
	self.barText_ = self.progressGroup_:ComponentByName("barText", typeof(UILabel))
	self.labelHasUnlocked_ = self.progressGroup_:ComponentByName("e:group/labelHasUnlocked", typeof(UILabel))
	self.effectGroup_ = self.progressGroup_:NodeByName("effectGroup").gameObject
	self.touchGroup_ = self.progressGroup_:NodeByName("touchGroup").gameObject
	self.scrollView_ = winGroup:ComponentByName("scrollView", typeof(UIScrollView))
	self.progressItemsGroup_ = winGroup:ComponentByName("scrollView/progressItemsGroup", typeof(UIGrid))
	self.textImg = winTrans:ComponentByName("textImg", typeof(UITexture))
	self.partnerImgNode = winTrans:NodeByName("partnerImgNode").gameObject
	self.dynamicPartnerImg = winTrans:NodeByName("dynamicPartnerImgNode").gameObject
	self.oldBuildingScoreGroup_ = winGroup:NodeByName("oldBuildingScoreGroup").gameObject
	self.labelScoreNow_ = self.oldBuildingScoreGroup_:ComponentByName("labelScoreNow", typeof(UILabel))
	self.labelScoreTips_ = self.oldBuildingScoreGroup_:ComponentByName("labelScoreTips", typeof(UILabel))
	self.scoreBefore_ = self.oldBuildingScoreGroup_:ComponentByName("scoreBefore", typeof(UILabel))
	self.scoreAfter_ = self.oldBuildingScoreGroup_:ComponentByName("scoreAfter", typeof(UILabel))
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
	self.labelRecord_ = winTrans:ComponentByName("labelRecord", typeof(UILabel))

	if self.isNewVer then
		self.desGroup = winGroup:NodeByName("desGroup").gameObject
		self.labelDes = self.desGroup:ComponentByName("labelDes", typeof(UILabel))
		self.nextBtn = winGroup:NodeByName("bottomNode/nextBtn").gameObject
		self.nextBtnLabel = self.nextBtn:ComponentByName("button_label", typeof(UILabel))
		self.effectTarget1_ = winGroup:NodeByName("effectTarget1_").gameObject
		local bottomNode = winGroup:NodeByName("bottomNode").gameObject
		self.bottomNode = bottomNode
		self.battleDetailBtn = bottomNode:NodeByName("battleDetailBtn").gameObject
		self.battleReviewBtn = bottomNode:NodeByName("battleReviewBtn").gameObject
		self.battleCheckBuffBtn = bottomNode:NodeByName("battleCheckBuffBtn").gameObject
		self.confirmBtn = bottomNode:NodeByName("confirmBtn").gameObject
		self.confirmBtnLabel = self.confirmBtn:ComponentByName("button_label", typeof(UILabel))
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

function BattleWinWindow:initWindow()
	BattleWinWindow.super.initWindow(self)
	self:getUIComponent()
	xyd.SoundManager.get():playSound(xyd.SoundID.BATTLE_WIN)

	local sp1 = xyd.Spine.new(self.effectTarget_)

	local function callback()
		sp1:SetLocalPosition(0, 120, 0)
		sp1:setPlayNeedStop(true)
		sp1:setNoStopResumeSetupPose(true)
		sp1:play("texiao01", 1, 1, function ()
			if self:checkNewTrialEnd() then
				self.progressGroup_:SetActive(true)

				self.progressItemsList_ = {}
				self.rewardEffect_ = xyd.Spine.new(self.effectGroup_)

				self.rewardEffect_:setInfo("new_trial_baoxiang", function ()
					UIEventListener.Get(self.touchGroup_).onClick = handler(self, self.completeProgress)

					self.touchGroup_:SetActive(true)
					self:prepareProgress()
				end)
			end

			if self.battleType == xyd.BattleType.ICE_SECRET_BOSS then
				self.progressGroup_:SetActive(true)

				self.progressItemsList_ = {}
				self.rewardTable = xyd.tables.activityIceSecretBossRewardTable
				UIEventListener.Get(self.touchGroup_).onClick = handler(self, self.completeActivityProgress)

				self.touchGroup_:SetActive(true)
				self:prepareActivityProgress()
			end

			if self.battleType == xyd.BattleType.LIMIT_CALL_BOSS then
				self.progressGroup_:SetActive(true)

				self.progressItemsList_ = {}
				self.rewardTable = xyd.tables.activityLimitBossAwardTable
				UIEventListener.Get(self.touchGroup_).onClick = handler(self, self.completeActivityProgress)

				self.touchGroup_:SetActive(true)
				self:prepareActivityProgress()
			end

			sp1:play("texiao02", 0)
			xyd.EventDispatcher:inner():dispatchEvent({
				name = xyd.event.PLAY_REPORT_END,
				params = {}
			})

			if self.onOpenCallback then
				self.onOpenCallback()
				self.mask_:SetActive(false)
			end
		end)

		if self:checkShowBoard() then
			local sp2 = xyd.Spine.new(self.effectTarget_)

			sp2:setInfo(self.effectName, function ()
				sp2:SetLocalPosition(0, 120, 5)
				sp2:setRenderTarget(self.effectTarget_.gameObject:GetComponent(typeof(UIWidget)), 0)
				sp2:play("texiao03", 1, 1, function ()
					sp2:play("texiao04", 0)
				end)
			end)
		else
			sp1:SetLocalPosition(0, 100, 0)
			self.confirmBtn:SetLocalPosition(0, -177, 0)
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

				if self:checkNewTrialEnd() then
					self.progressGroup_:SetActive(true)

					self.progressItemsList_ = {}
					self.rewardEffect_ = xyd.Spine.new(self.effectGroup_)

					self.rewardEffect_:setInfo("new_trial_baoxiang", function ()
						UIEventListener.Get(self.touchGroup_).onClick = handler(self, self.completeProgress)

						self.touchGroup_:SetActive(true)
						self:prepareProgress()
					end)
				end

				if self.battleType == xyd.BattleType.ICE_SECRET_BOSS then
					self.progressGroup_:SetActive(true)

					self.progressItemsList_ = {}
					self.rewardTable = xyd.tables.activityIceSecretBossRewardTable
					UIEventListener.Get(self.touchGroup_).onClick = handler(self, self.completeActivityProgress)

					self.touchGroup_:SetActive(true)
					self:prepareActivityProgress()
				end

				if self.battleType == xyd.BattleType.LIMIT_CALL_BOSS then
					self.progressGroup_:SetActive(true)

					self.progressItemsList_ = {}
					self.rewardTable = xyd.tables.activityLimitBossAwardTable
					UIEventListener.Get(self.touchGroup_).onClick = handler(self, self.completeActivityProgress)

					self.touchGroup_:SetActive(true)
					self:prepareActivityProgress()
				end

				self.confirmBtn:SetActive(true)
				xyd.EventDispatcher:inner():dispatchEvent({
					name = xyd.event.PLAY_REPORT_END,
					params = {}
				})

				if self.onOpenCallback then
					self:onOpenCallback()
					self.mask_:SetActive(false)
				end
			end
		end)

		if self:checkShowBoard() then
			local sp2 = xyd.Spine.new(self.effectTarget1_)

			sp2:setInfo(self.effectName, function ()
				self.battleDetailBtn:Y(360)
				self.battleReviewBtn:Y(360)
				self.battleCheckBuffBtn:Y(360)
				sp2:setRenderTarget(self.effectTarget1_.gameObject:GetComponent(typeof(UIWidget)), 1)
				sp2:play("texiao03", 1, 1, function ()
					sp2:play("texiao04", 0)
				end)
			end)
			self.desGroup:SetActive(true)
		end

		self:waitForTime(0.3, function ()
			self:initLayout()
		end, "")
	end

	xyd.setUITextureByNameAsync(self.textImg, self.labelImg, true)
	sp1:setInfo(self.effectName, function ()
		sp1:setRenderTarget(self.effectTarget_.gameObject:GetComponent(typeof(UIWidget)), 0)
		sp1:changeAttachment("zititihuan1", self.textImg)
		sp1:changeAttachment("zititihuan2", self.textImg)

		if self.isNewVer then
			self.labelDes.text = __("FRIEND_BATTLE_AWARDS")
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
					if not self.partnerImgNode or tolua.isnull(self.partnerImgNode) then
						return
					end

					sp1:followBone("lihuith", self.partnerImgNode)
					sp1:followSlot("lihuith", self.partnerImgNode)
					self.partnerImg1:SetLocalPosition(xy.x, -xy.y, 0)
					self.partnerImg1:SetLocalScale(scale, scale, scale)
				end)
			end

			newCallback()

			return
		end

		callback()
	end)
	xyd.models.dress:showDelayBuffTips(xyd.DressBuffTipsType.FIGHT_WIN)
end

function BattleWinWindow:playDialog()
	local dialog = xyd.tables.partnerTable:getVictoryDialogInfo(self.tableId_)

	xyd.SoundManager.get():stopSound(dialog.sound)
	xyd.SoundManager.get():playSound(dialog.sound)
end

function BattleWinWindow:checkShowBoard()
	if self.battleType == xyd.BattleType.HERO_CHALLENGE and (not self.battleParams.items or #self.battleParams.items <= 0) or self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS and (not self.battleParams.items or #self.battleParams.items <= 0) or self.battleType == xyd.BattleType.SPORTS_SHOW or self.battleType == xyd.BattleType.HERO_CHALLENGE_REPORT or self.battleType == xyd.BattleType.ENTRANCE_TEST_REPORT or self.battleType == xyd.BattleType.LIBRARY_WATCHER_STAGE_FIGHT or self.battleType == xyd.BattleType.LIBRARY_WATCHER_STAGE_FIGHT2 or self.battleType == xyd.BattleType.SKIN_PLAY or (self.battleType == xyd.BattleType.BEACH_ISLAND or self.battleType == xyd.BattleType.ENCOUNTER_STORY) and (not self.battleParams.items or #self.battleParams.items <= 0) or self.battleType == xyd.BattleType.FAIRY_TALE and (not self.battleParams.items or #self.battleParams.items <= 0) or self.battleType == xyd.BattleType.EXPLORE_OLD_CAMPUS and not self.battleParams.is_score_up then
		return false
	end

	return true
end

function BattleWinWindow:initReviewBtn()
	local data = self.battleParams
	local eventName = ""

	if self.battleType == xyd.BattleType.TRIAL then
		eventName = xyd.event.NEW_TRIAL_FIGHT
	elseif self.battleType == xyd.BattleType.TOWER or self.battleType == xyd.BattleType.TOWER_PRACTICE then
		eventName = xyd.event.TOWER_SELF_REPORT
	elseif self.battleType == xyd.BattleType.HERO_CHALLENGE or self.battleType == xyd.BattleType.HERO_CHALLENGE_REPORT or self.battleType == xyd.BattleType.ENTRANCE_TEST_REPORT or self.battleType == xyd.BattleType.HERO_CHALLENGE_SPEED or self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS then
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
	elseif self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT then
		eventName = xyd.event.TIME_CLOISTER_EXTRA
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
		elseif self.battleType == xyd.BattleType.ENTRANCE_TEST then
			xyd.BattleController.get():onActivityFight({
				data = {
					isReview = true,
					detail = self.battleParams,
					activity_id = xyd.ActivityID.ENTRANCE_TEST
				}
			})
		else
			xyd.EventDispatcher.inner():dispatchEvent({
				name = eventName,
				data = data
			})
		end
	end
end

function BattleWinWindow:initLayout()
	local function completeCallback()
		if self:checkShowDetail() then
			self.battleDetailBtn:SetActive(true)
		end

		if self.isReportType then
			self.battleReviewBtn:SetActive(true)
		elseif self.battleType == xyd.BattleType.EXPLORE_OLD_CAMPUS then
			self.battleDetailBtn:X(230)

			if self.initNext_ then
				self.battleDetailBtn.transform:X(255)
				self.battleReviewBtn.transform:X(320)
			end
		elseif self.battleType == xyd.BattleType.SHRINE_HURDLE or self.battleType == xyd.BattleType.ACTIVITY_SPFARM or self.battleType == xyd.BattleType.ENTRANCE_TEST then
			self.battleDetailBtn.transform:X(260)
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
	self.pveDropGroup:SetActive(false)

	self.confirmBtnLabel.text = __("CONFIRM")

	local function pvpFun()
		self.pvpGroup:SetLocalScale(0, 0, 1)
		self.pvpGroup:SetActive(true)
		self.layeoutSequence:Append(self.pvpGroup.transform:DOScale(Vector3(1, 1, 1), 0.16))
		self.battleDetailBtn:X(285)
	end

	local function pveFun()
		self.pveDropGroup:SetLocalScale(0, 0, 1)
		self.pveDropGroup:SetActive(true)

		local scaleNum = 1

		if self.pveDropGroup.transform.childCount >= 6 then
			scaleNum = 0.9
		end

		self.layeoutSequence:Append(self.pveDropGroup.transform:DOScale(Vector3(scaleNum, scaleNum, 1), 0.16))
	end

	self:initReviewBtn()

	if self.battleType == xyd.BattleType.CAMPAIGN then
		local rewardList = xyd.split(self.StageTable:getReward(self.stageId), "|")

		for _, itemData in ipairs(rewardList) do
			itemData = xyd.split(itemData, "#")
			local itemId = itemData[1]
			local itemNum = tonumber(itemData[2])
			local itemIcon = xyd.getItemIcon({
				showSellLable = false,
				itemID = itemId,
				num = itemNum,
				uiRoot = self.pveDropGroup
			})
		end

		pveFun()
	elseif self.battleType == xyd.BattleType.DUNGEON then
		self:initDungeon()
		pvpFun()
	elseif self.battleType == xyd.BattleType.DAILY_QUIZ or self.battleType == xyd.BattleType.FAIRY_TALE then
		self:initDailyQuiz()
		pveFun()
	elseif self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT then
		self:initAcademyAssessment()
		pveFun()
	elseif self.battleType == xyd.BattleType.TOWER then
		if not self.data.isRecord then
			self:initTower()
			pveFun()
		else
			self:initTowerPractice()
			self.formationGroup:SetActive(true)
		end
	elseif self.battleType == xyd.BattleType.TOWER_PRACTICE then
		self:initTowerPractice()
		self.formationGroup:SetActive(true)
	elseif self.battleType == xyd.BattleType.SPORTS_PVP then
		self:initSport()
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
		self:initFriendBoss2()
		pveFun()
	elseif self.battleType == xyd.BattleType.FRIEND then
		self:initFriend()
		pvpFun()
		self.battleDetailBtn:X(265)
		self.battleReviewBtn:X(325)
	elseif self.battleType == xyd.BattleType.ARCTIC_EXPEDITION then
		pvpFun()
		self:initCellInfo()
	elseif self.battleType == xyd.BattleType.TRIAL then
		if self:checkNewTrialEnd() then
			self:initProgressGroup()
			self.scrollView_.gameObject:SetActive(true)
			self.battleDetailBtn:SetActive(true)
		else
			self.pveDropGroup.transform:SetLocalScale(0, 0, 1)

			local seq = DG.Tweening.DOTween.Sequence()

			seq:Insert(0, self.pveDropGroup.transform:DOScale(Vector3(1, 1, 1), 0.16))
			self:initHeroChallenge()
			pveFun()
		end
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
	elseif self.battleType == xyd.BattleType.GUILD_WAR then
		self:initGuildWar()
		pvpFun()
	elseif self.battleType == xyd.BattleType.HERO_CHALLENGE or self.battleType == xyd.BattleType.LIBRARY_WATCHER_STAGE_FIGHT or self.battleType == xyd.BattleType.LIBRARY_WATCHER_STAGE_FIGHT2 or self.battleType == xyd.BattleType.HERO_CHALLENGE_CHESS then
		self:initHeroChallenge()
		pveFun()
	elseif self.battleType == xyd.BattleType.HERO_CHALLENGE_REPORT or self.battleType == xyd.BattleType.ENTRANCE_TEST_REPORT then
		self.layeoutSequence:Append(self.pveDropGroup.transform:DOScale(Vector3(1, 1, 1), 0.16))
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
	elseif self.battleType == xyd.BattleType.SPORTS_SHOW then
		-- Nothing
	elseif self.battleType == xyd.BattleType.ICE_SECRET_BOSS or self.battleType == xyd.BattleType.LIMIT_CALL_BOSS then
		local rewardList = self.battleParams.battle_report.items

		for i = 1, #rewardList do
			if rewardList[i] then
				local itemId = rewardList[i][1]
				local itemNum = rewardList[i][2]
				local itemIcon = xyd.getItemIcon({
					showSellLable = false,
					uiRoot = self.pveDropGroup,
					itemID = itemId,
					num = itemNum
				})
			end
		end

		self.progressGroup_:Y(30)
		self.pveDropGroup:SetLocalScale(0, 0, 0)
		self.pveDropGroup:Y(-80)
		self.pveDropGroup:SetActive(true)
		self.layeoutSequence:Append(self.pveDropGroup.transform:DOScale(Vector3(1, 1, 1), 0.16))
		self:initProgressGroup()
		self.scrollView_.gameObject:SetActive(true)
		self.battleDetailBtn:SetActive(true)
	elseif self.battleType == xyd.BattleType.EXPLORE_OLD_CAMPUS then
		self.battleCheckBuffBtn:SetActive(true)
		self.battleReviewBtn:SetActive(true)
		self.battleDetailBtn.transform:X(240)
		self:updateScroePart()
	elseif self.battleType == xyd.BattleType.SHRINE_HURDLE then
		self.battleReviewBtn:SetActive(true)
		self.battleDetailBtn.transform:X(260)
		self:updateShrineHurdlePart()
	elseif self.battleType == xyd.BattleType.EXPLORE_ADVENTURE then
		local rewardList = xyd.models.exploreModel:getBattleAwards()

		for _, itemData in ipairs(rewardList) do
			local itemIcon = xyd.getItemIcon({
				showSellLable = false,
				itemID = tonumber(itemData.item_id),
				num = tonumber(itemData.item_num),
				uiRoot = self.pveDropGroup
			})
		end

		pveFun()
	elseif self.battleType == xyd.BattleType.GUILD_COMPETITION then
		self:initGuildCompetition()
		self.pveDropGroup.gameObject:SetActive(true)
		self.pveDropGroup.transform:SetLocalScale(0, 0, 0)
		self.layeoutSequence:Append(self.pveDropGroup.transform:DOScale(Vector3(1, 1, 1), 0.16))
	elseif self.battleType == xyd.BattleType.ENTRANCE_TEST then
		self:initEntranceTest()
		self.battleReviewBtn:SetActive(true)
		self:initReviewBtn()
		self.pveDropGroup.gameObject:SetActive(true)
		self.pveDropGroup.transform:SetLocalScale(0, 0, 0)
		self.layeoutSequence:Append(self.pveDropGroup.transform:DOScale(Vector3(1, 1, 1), 0.16))
	elseif self.battleType == xyd.BattleType.FAIR_ARENA then
		self:initGuildWar()
		pvpFun()
		self.battleDetailBtn.transform:X(260)
	elseif self.battleType == xyd.BattleType.ACTIVITY_SPACE_EXPLORE then
		local rewardList = self.battleParams.items

		for i = 1, #rewardList do
			if rewardList[i] then
				local itemId = tonumber(rewardList[i].item_id)

				if itemId ~= xyd.ItemID.EXP and itemId ~= xyd.ItemID.VIP_EXP then
					local itemNum = tonumber(rewardList[i].item_num)
					local itemIcon = xyd.getItemIcon({
						showSellLable = false,
						uiRoot = self.pveDropGroup,
						itemID = itemId,
						num = itemNum
					})
				end
			end
		end

		self.pveDropGroup:SetActive(true)
		self.battleDetailBtn:SetActive(false)

		local spaceExploreMapWindow = xyd.WindowManager.get():getWindow("activity_space_explore_map_window")

		if spaceExploreMapWindow and spaceExploreMapWindow:getIsAuto() then
			local auto_time = 0.5

			if UNITY_EDITOR then
				local gm_auto_time = xyd.db.misc:getValue("gm_set_space_explore_auto_time")

				if gm_auto_time then
					auto_time = tonumber(gm_auto_time) / 10

					if auto_time <= 0 then
						auto_time = 0.05
					end
				end
			end

			self:waitForTime(auto_time, function ()
				self:close()
			end)
		end
	elseif self.battleType == xyd.BattleType.BEACH_ISLAND or self.battleType == xyd.BattleType.ENCOUNTER_STORY then
		if self.battleParams.items and #self.battleParams.items > 0 then
			for _, itemData in ipairs(self.battleParams.items) do
				local itemIcon = xyd.getItemIcon({
					showSellLable = false,
					itemID = tonumber(itemData.item_id),
					num = tonumber(itemData.item_num),
					uiRoot = self.pveDropGroup
				})
			end
		end

		self.pveDropGroup:SetActive(self.battleParams.items and #self.battleParams.items > 0)
	elseif self.battleType == xyd.BattleType.TIME_CLOISTER_BATTLE or self.battleType == xyd.BattleType.TIME_CLOISTER_EXTRA then
		if self.battleParams.items and #self.battleParams.items > 0 then
			for _, itemData in ipairs(self.battleParams.items) do
				local itemIcon = xyd.getItemIcon({
					showSellLable = false,
					itemID = tonumber(itemData.item_id),
					num = tonumber(itemData.item_num),
					uiRoot = self.pveDropGroup
				})
			end

			self.pveDropGroup:SetActive(true)
		else
			self.pveDropGroup_grid:Reposition()

			if self.name_ == "battle_win_v2_window" then
				self.damageGroup:Y(-390)
			elseif self.name_ == "battle_win_window" then
				self.damageGroup:Y(-40)
			end

			self.labelDamage1.fontSize = 36
			self.labelDamage2.fontSize = 36
			self.labelDamage1.text = __("FRIEND_HARM")
			self.labelDamage2.text = xyd.getDisplayNumber(self.battleParams.total_harm)

			self.damageGroup:SetActive(true)
		end
	elseif self.battleType == xyd.BattleType.ACTIVITY_SPFARM then
		self.battleReviewBtn:SetActive(true)
		self:initSpfarm()
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

function BattleWinWindow:closeSelf()
	if self.battleType == xyd.BattleType.TOWER then
		xyd.closeWindow("tower_window")
	elseif self.battleType == xyd.BattleType.TIME_CLOISTER_EXTRA then
		local time_cloister_probe_wd = xyd.WindowManager.get():getWindow("time_cloister_probe_window")

		if time_cloister_probe_wd then
			time_cloister_probe_wd:showItemsTween(self.battleParams.items, xyd.TimeCloisterExtraEvent.ENCOUNTER_BATTLE)
		end
	elseif self.battleType == xyd.BattleType.TIME_CLOISTER_BATTLE then
		local timeCloisterBattleWd = xyd.WindowManager.get():getWindow("time_cloister_battle_window")

		timeCloisterBattleWd:showClearLastRankTips()
	end

	xyd.WindowManager.get():closeWindow("battle_window")
	xyd.WindowManager.get():closeWindow(self.name_)
end

function BattleWinWindow:updateScroePart()
	local stage_id = self.battleParams.stage_id
	local floor_id = xyd.tables.oldBuildingStageTable:getFloor(stage_id)

	if floor_id == 11 then
		self.buffIds_ = {}
		local allBuffs = xyd.models.oldSchool:getBuffs()

		for index, list in ipairs(allBuffs) do
			for key, value in ipairs(list) do
				table.insert(self.buffIds_, value)
			end
		end
	end

	xyd.models.oldSchool.failNum_ = 0

	if self.battleParams.is_score_up then
		self.oldBuildingScoreGroup_:SetActive(true)

		local floorIndex = xyd.tables.oldBuildingStageTable:getFloorIndex(stage_id)
		local floorInfo = self.battleParams.floor_info
		local scoreBefore = self.battleParams.beforeScore
		local curScore = floorInfo.cur_scores[floorIndex]

		if self.params_.is_new then
			self.confirmBtn:Y(-20)
		end

		local nowScore = floorInfo.score

		if floor_id == 11 then
			self.labelScoreNow_.text = __("OLD_SCHOOL_FLOOR_11_TEXT16") .. "[c][0069cc]" .. curScore .. "[-][/c]"
			self.labelScoreTips_.text = __("OLD_SCHOOL_FLOOR_11_TEXT17")
		else
			self.labelScoreNow_.text = __("ACTIVITY_EXPLORE_CAMPUS_SCORE_CUR") .. "[c][0069cc]" .. curScore .. "[-][/c]"
			self.labelScoreTips_.text = __("ACTIVITY_EXPLORE_CAMPUS_SCORE_UP_TIPS")
		end

		self.scoreBefore_.text = scoreBefore
		self.scoreAfter_.text = nowScore
	end

	local nextId = xyd.models.oldSchool:getNextStage(stage_id)
	local selectInfo = xyd.db.misc:getValue("old_building_setting")

	if selectInfo then
		selectInfo = json.decode(selectInfo)
	else
		selectInfo = {}
	end

	if nextId > 0 and selectInfo.select and tonumber(selectInfo.select) ~= 0 then
		local function callback()
			local win = xyd.WindowManager.get():getWindow(self.name_)

			if not win then
				return
			end

			if self.autoBattle and self.stopAutoBattle then
				self.autoBattle = false

				return
			end

			xyd.models.oldSchool:autoBattle(nextId)
			self:close()
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

function BattleWinWindow:updateShrineHurdlePart()
	self.shrineHurdleScoreGroup_:SetActive(true)

	local diffLevel = xyd.models.shrineHurdleModel:getDiffNum()
	self.diffTips_.text = __("SHRINE_HURDLE_TEXT03") .. " : " .. diffLevel
	self.shrineHurdleScoreTips_.text = __("SHRINE_HURDLE_TEXT10")
	local isRecord = nil

	if self.data then
		isRecord = self.data.isRecord
	end

	if not isRecord then
		local addGold, addScore = xyd.models.shrineHurdleModel:getGoldScoreChange()
		local guideIndex = xyd.models.shrineHurdleModel:checkInGuide()

		if guideIndex then
			self.battleReviewBtn:SetActive(false)
		end

		self.shrineHurdleScore_.text = "+" .. addScore
		self.shrineHurdleScoreTips_.text = __("SHRINE_HURDLE_TEXT10")

		if xyd.models.shrineHurdleModel:checkIsBoss() then
			self.shrineHurdleGoldGroup_:SetActive(false)
			self.shrineHurdleHurtGroup_:SetActive(true)

			self.shrineHurdlehHurtTips_.text = __("WORLD_BOSS_SWEEP_TEXT06") .. " : "
			self.shrineHurdlehHurt_.text = xyd.getDisplayNumber(tonumber(self.battleParams.total_harm))

			xyd.models.shrineHurdleModel:clearScoreBefore()
		end

		if addGold and addGold >= 0 then
			self.shrineHurdleGoldGroup_:SetActive(true)
			self.shrineHurdleHurtGroup_:SetActive(false)

			self.shrineHurdleLabelCoinNum_.text = "+" .. addGold
		end

		if guideIndex and guideIndex >= 9 then
			self.shrineHurdleGoldGroup_:SetActive(false)
			self.shrineHurdleHurtGroup_:SetActive(true)

			self.shrineHurdlehHurtTips_.text = __("WORLD_BOSS_SWEEP_TEXT06") .. " : "
			self.shrineHurdleScore_.text = math.ceil(tonumber(self.battleParams.battle_report.total_harm) * 1e-08)
			self.shrineHurdlehHurt_.text = xyd.getDisplayNumber(tonumber(self.battleParams.battle_report.total_harm))

			xyd.models.shrineHurdleModel:clearScoreBefore()
		end
	else
		self.shrineHurdleGoldGroup_:SetActive(false)
		self.shrineHurdleHurtGroup_:SetActive(false)
		self.shrineHurdleScore_.gameObject:SetActive(false)
		self.shrineHurdleScoreTips_.gameObject:SetActive(false)

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

		self.shrinePartnerGroup_:Reposition()
		self.scoreGroup_:SetActive(false)
	end
end

function BattleWinWindow:checkNewTrialEnd()
	if self.battleType == xyd.BattleType.TRIAL and self.stageId == -1 then
		return true
	else
		return false
	end
end

function BattleWinWindow:checkShowDetail()
	if self.battleType == xyd.BattleType.DUNGEON or self.battleType == xyd.BattleType.ACTIVITY_SPACE_EXPLORE then
		return false
	end

	return true
end

function BattleWinWindow:initArenaTeam()
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

function BattleWinWindow:initSpfarm()
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

function BattleWinWindow:initProgressGroup()
	self.labelHasUnlocked_.text = "0"

	self.pveDropGroup.gameObject:SetActive(true)
	self.confirmBtn:SetActive(true)
end

function BattleWinWindow:initArenaAllServerScore()
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

function BattleWinWindow:initArena3v3()
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

function BattleWinWindow:initSport()
	self.labelLeftPlayerName.text = self.battleParams.self_info.player_name
	self.labelRightPlayerName.text = self.battleParams.enemy_info.player_name
	local paramsA = {
		avatar_frame_id = self.battleParams.self_info.avatar_frame_id,
		avatarID = self.battleParams.self_info.avatar_id,
		lev = self.battleParams.self_info.lev
	}
	local paramsB = {
		avatarID = self.battleParams.enemy_info.avatar_id,
		avatar_frame_id = self.battleParams.enemy_info.avatar_frame_id,
		lev = self.battleParams.enemy_info.lev
	}
	local iconA = PlayerIcon.new(self.groupLeftIcon_)
	local iconB = PlayerIcon.new(self.groupRightIcon_)

	iconA:setInfo(paramsA)
	iconB:setInfo(paramsB)

	self.labelLeftScoreText.text = __("SCORE2")
	self.labelRightScoreText.text = __("SCORE2")
	self.labelLeftScore.text = self.battleParams.score
	self.labelRightScore.text = self.battleParams.enemy_info.score

	if self.battleType == xyd.BattleType.ENTRANCE_TEST and self.battleParams.enemy_info.score <= 0 then
		self.labelRightScore.text = 0
	end

	local changeTextLeft = xyd.checkCondition(self.battleParams.self_change > 0, "+", "") .. self.battleParams.self_change
	self.labelLeftScoreChange.text = "(" .. changeTextLeft .. ")"
	self.labelRightScoreChange.text = ""
	self.labelRightScore.gameObject:GetComponent(typeof(UIWidget)).pivot = UIWidget.Pivot.Center

	self.labelRightScore:X(0)
	xyd.itemFloat(self.battleParams.items)
end

function BattleWinWindow:initArena()
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

	if self.battleType == xyd.BattleType.ENTRANCE_TEST and self.battleParams.enemy_info.score <= 0 then
		self.labelRightScore.text = 0
	end

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

function BattleWinWindow:initGuildWar()
	self.labelLeftPlayerName.text = self.battleParams.self_info.player_name
	self.labelRightPlayerName.text = self.battleParams.enemy_info.player_name

	dump(self.battleParams, "傳進來的數據09090990909090909090")
	__TRACE("測試進來的東西")

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

function BattleWinWindow:initDungeon()
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

	iconB:setGrey()

	local isAlive = xyd.models.dungeon:checkPartnerAlive(teamA[1].table_id)

	if not isAlive then
		iconA:setGrey(isAlive)
	end
end

function BattleWinWindow:initDailyQuiz()
	local items = self.battleParams.items

	for _, item in ipairs(items) do
		local itemIcon = xyd.getItemIcon({
			itemID = tonumber(item.item_id),
			num = tonumber(item.item_num),
			uiRoot = self.pveDropGroup.gameObject
		})

		if #items >= 6 then
			self.pveDropGroup_grid.cellWidth = 115
			self.pveDropGroup_grid.cellHeight = 115

			self.pveDropGroup_grid:Reposition()
		end
	end

	if self.battleType ~= xyd.BattleType.FAIRY_TALE and xyd.models.dailyQuiz:isHasLeftTimes(self.battleParams.quiz_type) then
		local callback = nil

		function callback()
			xyd.WindowManager.get():closeWindow("battle_window")
			xyd.WindowManager.get():closeWindow(self.name_)
			xyd.models.dailyQuiz:nextFight()
		end

		self:initNextBtn("NEXT_BATTLE", callback)
	end
end

function BattleWinWindow:initHeroChallenge()
	local items = self.battleParams.items

	if items and #items > 0 then
		for _, item in ipairs(items) do
			xyd.getItemIcon({
				itemID = tonumber(item.item_id),
				num = math.floor(tonumber(item.item_num)),
				uiRoot = self.pveDropGroup
			})
		end

		self.pveDropGroup:GetComponent(typeof(UIGrid)):Reposition()
	end
end

function BattleWinWindow:initNextBtn(str, callback)
	self.nextBtn_ = NGUITools.AddChild(self.winGroup.gameObject, self.confirmBtn.gameObject)
	self.nextBtn_sprite = self.nextBtn_:GetComponent(typeof(UISprite))
	self.nextBtn_button_label = self.nextBtn_:ComponentByName("button_label", typeof(UILabel))

	xyd.setUISpriteAsync(self.nextBtn_sprite, nil, "blue_btn_65_65", nil, )

	self.nextBtn_button_label.text = __(str)
	self.nextBtn_button_label.color = Color.New2(4294967295.0)
	self.nextBtn_button_label.effectColor = Color.New2(473916927)
	self.nextBtn_.transform.name = "next_btn"

	self.nextBtn_:SetActive(false)

	UIEventListener.Get(self.nextBtn_.gameObject).onClick = handler(self, callback)

	if self.isNewVer then
		self.confirmBtn:SetLocalPosition(-140, 0, 0)
		self.nextBtn_:SetLocalPosition(140, -569, 0)
	else
		self.confirmBtn:SetLocalPosition(-140, -254, 0)
		self.nextBtn_:SetLocalPosition(140, -254, 0)
	end
end

function BattleWinWindow:initFriendBoss2()
	for i, itemData in ipairs(self.battleParams.items) do
		local itemIcon = xyd.getItemIcon({
			showSellLable = false,
			itemID = tonumber(itemData.item_id),
			num = tonumber(itemData.item_num),
			uiRoot = self.pveDropGroup
		})

		self.pveDropGroup:GetComponent(typeof(UIGrid)):Reposition()
	end
end

function BattleWinWindow:initFriendBoss()
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
		xyd.WindowManager.get():closeWindow(self.name_)
		Friend:get():fightBoss(self.battleParams.friend_id)
	end

	if Friend:get():getTili() > 0 and Friend:get():checkHasBoss(self.battleParams.friend_id) then
		self:initNextBtn("FRIEND_RE_FIGHT_BOSS", callback)
	end
end

function BattleWinWindow:initFriend()
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

function BattleWinWindow:initCellInfo()
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

	self.groupRightIcon_.transform:Y(-7)

	local imgSprite = self.groupRightIcon_:GetComponent(typeof(UISprite))
	imgSprite.width = 114
	imgSprite.height = 132

	xyd.setUISpriteAsync(imgSprite, nil, cellImg)
	self.groupLeftIcon_.transform:Y(-7)
	self.pvpGroup:NodeByName("vsIcon"):Y(20)

	local iconA = PlayerIcon.new(self.groupLeftIcon_)

	iconA:setInfo(paramsA)
	self.labelLeftScoreText:SetActive(false)
	self.labelRightScoreText:SetActive(false)
	self.labelLeftScore:SetActive(false)
	self.labelRightScore:SetActive(false)
	self.labelLeftScoreChange:SetActive(false)
	self.labelRightScoreChange:SetActive(false)
end

function BattleWinWindow:initAcademyAssessment()
	local items = self.battleParams.items

	for _, item in ipairs(items) do
		local itemIcon = xyd.getItemIcon({
			itemID = tonumber(item.item_id),
			num = tonumber(item.item_num),
			uiRoot = self.pveDropGroup.gameObject
		})

		if #items >= 6 then
			self.pveDropGroup_grid.cellWidth = 115
			self.pveDropGroup_grid.cellHeight = 115

			self.pveDropGroup_grid:Reposition()
		end
	end

	local academy_stageId = xyd.db.misc:getValue("cur_academy_assessment_stage_id")
	academy_stageId = xyd.checkCondition(academy_stageId, tonumber(academy_stageId), 0)
	local fortTable_ = xyd.tables.academyAssessmentNewTable
	local time = xyd.tables.miscTable:getVal("school_practise_switch_time")

	if tonumber(time) <= xyd.getServerTime() then
		fortTable_ = xyd.tables.academyAssessmentNewTable2
	end

	local nextId = fortTable_:getNext(academy_stageId) or 0

	if nextId > 0 then
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
				xyd.models.academyAssessment:onNextBattle(nextId)
				xyd.WindowManager.get():closeWindow("battle_window")
				xyd.WindowManager.get():closeWindow(self.name_)
			else
				xyd.showToast(__("SCHOOL_PRACTICE_CHALLENGE_TICKETS_NOT_ENOUGH"))
			end
		end

		self:initNextBtn("NEXT_BATTLE", callback)

		local abbr1 = xyd.db.misc:getValue("academy_assessment_battle_set_fail_end")
		local abbr2 = xyd.db.misc:getValue("academy_assessment_battle_set_ticket_end")

		if abbr1 and tonumber(abbr1) ~= 0 or abbr2 and tonumber(abbr2) ~= 0 then
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
end

function BattleWinWindow:initTower()
	local rewardList = xyd.tables.towerTable:getReward(self.stageId)

	for _, itemData in ipairs(rewardList) do
		local itemId = itemData[1]
		local itemNum = itemData[2]
		local itemIcon = xyd.getItemIcon({
			showSellLable = false,
			itemID = itemId,
			num = itemNum,
			uiRoot = self.pveDropGroup
		})
	end

	local maxTowerNum = xyd.tables.miscTable:getNumber("tower_top", "value")
	local isRecord = self.data.isRecord

	if self.stageId < maxTowerNum and not isRecord then
		local function callback()
			local tickts_num = xyd.models.backpack:getItemNumByID(xyd.ItemID.TOWER_TICKET)

			if tickts_num > 0 then
				xyd.WindowManager.get():closeWindow("battle_window")
				xyd.WindowManager.get():closeWindow(self.name_)

				local next_id = self.stageId + 1

				xyd.models.towerMap:TowerBattle(next_id)
			else
				xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGU", tickts_num))
			end
		end

		self:initNextBtn("NEXT_BATTLE", callback)
	end
end

function BattleWinWindow:initTowerPractice()
	local battleReport = self.battleParams.battle_report
	local teamA = battleReport.teamA
	local petA = battleReport.petA

	for i = 1, 6 do
		local data = teamA[i]

		if data then
			local icon = nil
			local tableId = data.table_id
			local lev = data.level
			local partnerInfo = nil
			local partner = Partner.new()

			partner:populate({
				table_id = tableId,
				lev = lev,
				awake = data.awake,
				show_skin = data.show_skin,
				is_vowed = data.is_vowed,
				equips = {
					0,
					0,
					0,
					0,
					0,
					0,
					data.skin_id
				}
			})

			partnerInfo = partner:getInfo()
			partnerInfo.noClick = true
			local parent = nil

			if tonumber(data.pos) <= 2 then
				parent = self.formation1
			else
				parent = self.formation2
			end

			icon = HeroIcon.new(parent)

			if petA then
				icon:setInfo(partnerInfo, petA.pet_id)
			else
				icon:setInfo(partnerInfo)
			end

			icon.scale = 97 / xyd.DEFAULT_ITEM_SIZE
		end
	end

	self.labelFormation.text = __("TOWER_PRACTICE_WIN_TIPS")
end

function BattleWinWindow:initTrial()
	local level = xyd.models.backpack:getLev()
	local rewardList = xyd.tables.TrialTable:get():getAward(level, self.stageId)

	for itemData in __TS__Iterator(rewardList) do
		local itemId = itemData[0]
		local itemNum = itemData[1]
		local itemIcon = xyd:getItemIcon({
			showSellLable = false,
			itemID = itemId,
			num = itemNum
		})

		self.pveDropGroup:addChild(itemIcon)
	end
end

function BattleWinWindow:initFriendTeamBoss()
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

function BattleWinWindow:initFriendTeamBossReport()
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

function BattleWinWindow:initGuildBoss()
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
		local itemId = tonumber(itemData[1])
		local itemNum = tonumber(itemData[2])

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

function BattleWinWindow:initGuildCompetition()
	local targetArr = self.battleParams.battle_report.purposes
	local targetCompleteNum = 0

	if targetArr then
		for i in pairs(targetArr) do
			if targetArr[i] == 1 then
				targetCompleteNum = targetCompleteNum + 1
			end
		end
	end

	if self.battleParams.type == 1 then
		local awardsDataList = self.battleParams.items

		for i = 1, #awardsDataList do
			local itemData = awardsDataList[i]
			local itemId = tonumber(itemData.item_id)
			local itemNum = tonumber(itemData.item_num)

			xyd.getItemIcon({
				showSellLable = false,
				uiRoot = self.pveDropGroup,
				itemID = itemId,
				num = itemNum
			})
		end

		self.labelDamage1.color = Color.New2(960513791)
		self.labelDamage1.effectColor = Color.New2(4294967295.0)
		self.labelDamage1.effectStyle = UILabel.Effect.Outline8
		self.labelDamage1.fontSize = 24
		self.labelDamage2.color = Color.New2(3613720831.0)
		self.labelDamage2.effectColor = Color.New2(4294967295.0)
		self.labelDamage2.effectStyle = UILabel.Effect.Outline8
		self.labelDamage2.fontSize = 26

		if self.damageGroup:GetComponent(typeof(UILayout)) then
			self.damageGroup:GetComponent(typeof(UILayout)).gap = Vector2(0, 0)
		end

		if self.damageGroup:GetComponent(typeof(UITable)) then
			self.damageGroup:GetComponent(typeof(UITable)).padding = Vector2(0, 0)
		end

		self.pveDropGroup_grid:Reposition()

		self.labelDamage1.text = __("FRIEND_HARM")
		local tmp = NGUITools.AddChild(self.winGroup.gameObject, self.damageGroup.gameObject)
		self.damageGroup_1 = tmp
		local labelDamage1_1 = tmp:ComponentByName("labelDamage1", typeof(UILabel))
		local labelDamage2_1 = tmp:ComponentByName("labelDamage2", typeof(UILabel))
		labelDamage1_1.text = __("BOSS_POINT")
		labelDamage2_1.text = math.floor(tonumber(self.battleParams.point)) .. " (+" .. targetCompleteNum * 10 .. "%)"

		if self.name_ == "battle_win_v2_window" then
			self.damageGroup:Y(-295)
			tmp:Y(-329)
			self.pveDropGroup:Y(-420)
		elseif self.name_ == "battle_win_window" then
			self.damageGroup:Y(29)
			tmp:Y(-4)
			self.pveDropGroup:Y(-94)
		end
	elseif self.battleParams.type == 2 then
		self.labelDamage1.text = __("FRIEND_HARM")

		if self.name_ == "battle_win_v2_window" then
			self.damageGroup:GetComponent(typeof(UILayout)).enabled = false
		elseif self.name_ == "battle_win_window" then
			self.damageGroup:GetComponent(typeof(UITable)).enabled = false
		end

		self.labelDamage1.gameObject:X(0)

		self.labelDamage1.color = Color.New2(960513791)
		self.labelDamage1.effectColor = Color.New2(4294967295.0)
		self.labelDamage1.effectStyle = UILabel.Effect.Outline8
		self.labelDamage1.fontSize = 24

		self.labelDamage2.gameObject:X(0)

		self.labelDamage2.color = Color.New2(3613720831.0)
		self.labelDamage2.effectColor = Color.New2(4294967295.0)
		self.labelDamage2.effectStyle = UILabel.Effect.Outline8
		self.labelDamage2.fontSize = 40
		self.labelDamage1.text = __("GUILD_COMPETITION_SIMULATE_DAMAGE")
		local tmp = NGUITools.AddChild(self.winGroup.gameObject, self.damageGroup.gameObject)
		local labelDamage1_1 = tmp:ComponentByName("labelDamage1", typeof(UILabel))
		local labelDamage2_1 = tmp:ComponentByName("labelDamage2", typeof(UILabel))
		labelDamage1_1.text = __("BOSS_POINT")
		labelDamage2_1.text = math.floor(tonumber(self.battleParams.point)) .. " (+" .. targetCompleteNum * 10 .. "%)"

		if self.name_ == "battle_win_v2_window" then
			self.damageGroup:Y(-250)
			self.labelDamage1.gameObject:Y(-53)
			self.labelDamage2.gameObject:Y(-98)
			tmp:Y(-357)
			labelDamage1_1.gameObject:Y(-53)
			labelDamage2_1.gameObject:Y(-98)
		elseif self.name_ == "battle_win_window" then
			self.damageGroup:Y(-141)
			self.labelDamage1.gameObject:Y(168)
			self.labelDamage2.gameObject:Y(124)
			tmp:Y(-245)
			labelDamage1_1.gameObject:Y(168)
			labelDamage2_1.gameObject:Y(124)
		end
	end

	self.labelDamage2.text = xyd.getDisplayNumber(math.floor(self.battleParams.self_harm))

	self.damageGroup:SetActive(true)

	if self.battleParams.type == 1 then
		if self.damageGroup:GetComponent(typeof(UILayout)) then
			self.damageGroup:GetComponent(typeof(UILayout)):Reposition()
			self.damageGroup_1:GetComponent(typeof(UILayout)):Reposition()
		end

		if self.damageGroup:GetComponent(typeof(UITable)) then
			self.damageGroup:GetComponent(typeof(UITable)):Reposition()
			self.damageGroup_1:GetComponent(typeof(UITable)):Reposition()
		end
	end

	local guildCompetitionTipsBtn = nil

	if self.name_ == "battle_win_v2_window" then
		guildCompetitionTipsBtn = NGUITools.AddChild(self.bottomNode.gameObject, self.battleDetailBtn.gameObject)

		guildCompetitionTipsBtn.gameObject:X(220)
		guildCompetitionTipsBtn.gameObject:Y(360)
	elseif self.name_ == "battle_win_window" then
		guildCompetitionTipsBtn = NGUITools.AddChild(self.winGroup.gameObject, self.battleDetailBtn.gameObject)

		guildCompetitionTipsBtn.gameObject:X(226)
		guildCompetitionTipsBtn.gameObject:Y(-138)
	end

	local guildCompetitionTipsBtnUISprite = guildCompetitionTipsBtn:GetComponent(typeof(UISprite))

	xyd.setUISpriteAsyncWithAtlas(guildCompetitionTipsBtnUISprite, "CommonBtn", "btn_tips", function ()
		guildCompetitionTipsBtnUISprite.width = 55
		guildCompetitionTipsBtnUISprite.height = 55
	end)

	guildCompetitionTipsBtnUISprite.depth = 155
	UIEventListener.Get(guildCompetitionTipsBtn.gameObject).onClick = handler(self, function ()
		if not self.guildCompetitionTargetGroup then
			local targetObj = NGUITools.AddChild(self.winGroup.gameObject, "targetObj")
			local targetObjUIWidget = targetObj:AddComponent(typeof(UIWidget))
			targetObjUIWidget.depth = 150
			local bossTable = xyd.tables.guildCompetitionBossTable
			local targetArr = bossTable["getBattleChallenge" .. self.battleParams.boss_id](bossTable, self.battleParams.battle_lv)
			local params = {
				isHasStar = true,
				targetArr = targetArr,
				completeArr = self.battleParams.battle_report.purposes
			}
			self.guildCompetitionTargetGroup = import("app.components.GuildCompetitionChallengeGroup").new(targetObjUIWidget.gameObject, params)

			self.guildCompetitionTargetGroup:setBgClickHide()

			self.guildCompetitionTargetGroup:getGameObject():GetComponent(typeof(UIWidget)).alpha = 0.02
		elseif self.guildCompetitionTargetGroup:getGameObject().activeSelf then
			self.guildCompetitionTargetGroup:SetActive(false)
		else
			self.guildCompetitionTargetGroup:SetActive(true)
		end

		local function setGroupPos()
			if self.guildCompetitionTargetGroup and self.guildCompetitionTargetGroup:getGameObject().activeSelf then
				if self.name_ == "battle_win_window" then
					self.guildCompetitionTargetGroup:getGameObject():Y(self.guildCompetitionTargetGroup:getHeight() - 223)
				elseif self.name_ == "battle_win_v2_window" then
					self.guildCompetitionTargetGroup:getGameObject():Y(self.guildCompetitionTargetGroup:getHeight() - 299)
				end
			end
		end

		setGroupPos()
		self:waitForFrame(3, function ()
			setGroupPos()

			self.guildCompetitionTargetGroup:getGameObject():GetComponent(typeof(UIWidget)).alpha = 1
		end)
	end)
end

function BattleWinWindow:initEntranceTest()
	if self.name_ == "battle_win_v2_window" then
		self.damageGroup:GetComponent(typeof(UILayout)).enabled = false
	elseif self.name_ == "battle_win_window" then
		local damageGroupUITable = self.damageGroup:GetComponent(typeof(UITable))

		if damageGroupUITable then
			damageGroupUITable:Destroy()
		end

		local layout = self.damageGroup:AddComponent(typeof(UILayout))
		layout.gap = Vector2(15, 0)
	end

	self.labelDamage1.gameObject:X(0)

	self.labelDamage1.color = Color.New2(1128218623)
	self.labelDamage1.effectStyle = UILabel.Effect.None
	self.labelDamage1.fontSize = 24

	self.labelDamage2.gameObject:X(0)

	self.labelDamage2.color = Color.New2(4182721023.0)
	self.labelDamage2.effectColor = Color.New2(4294967295.0)
	self.labelDamage2.effectStyle = UILabel.Effect.Outline8
	self.labelDamage2.fontSize = 28
	self.labelDamage1.text = __("ACTIVITY_NEW_WARMUP_TEXT29")

	if self.name_ == "battle_win_v2_window" then
		self.damageGroup:Y(-250)
	elseif self.name_ == "battle_win_window" then
		self.damageGroup:Y(-15)
	end

	self.labelDamage2.text = xyd.getDisplayNumber(math.floor(self.battleParams.total_harm))

	self.damageGroup:GetComponent(typeof(UILayout)):Reposition()
	self.damageGroup:SetActive(true)

	if self.battleParams.is_fake and self.battleParams.is_fake == 1 then
		-- Nothing
	elseif self.battleParams.isFirstPass or self.battleParams.isShowNewHarm then
		local newImg = NGUITools.AddChild(self.winGroup.gameObject, "newImg")
		local newImgUISprite = newImg:AddComponent(typeof(UISprite))
		newImgUISprite.depth = 20

		newImg.gameObject:SetLocalPosition(123, -103, 0)

		if self.battleParams.isFirstPass then
			xyd.setUISpriteAsync(newImgUISprite, nil, "activity_entrance_bg_sctg_" .. xyd.Global.lang, nil, , true)
		elseif self.battleParams.isShowNewHarm then
			xyd.setUISpriteAsync(newImgUISprite, nil, "activity_entrance_bg_xjl_" .. xyd.Global.lang, nil, , true)
		end
	end
end

function BattleWinWindow:initWorldBoss()
	local awardsDataList = self.battleParams.items

	if #awardsDataList > 6 then
		self.pveDropGroup.transform:Y(-410)
	end

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

function BattleWinWindow:willClose()
	BattleWinWindow.super.willClose(self)

	local win = xyd.getWindow("tower_window")

	if win then
		win:show()
	end

	if self.layeoutSequence then
		self.layeoutSequence = nil
	end

	if self.callback then
		self.callback(true)
	end

	if self.battleType == xyd.BattleType.ARENA then
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.HIGH_PRAISE
		})
	elseif self.battleType == xyd.BattleType.SKIN_PLAY then
		xyd.WindowManager.get():resumeHideAllWindow()
	elseif self.battleType == xyd.BattleType.CAMPAIGN then
		local win = xyd.WindowManager.get():getWindow("campaign_window")

		if win then
			xyd.GuideController.get():checkFuncsComplete()
			xyd.models.trial:checkFunctionOpen()
			win:checkCampaignRedState()
		end
	elseif self.battleType == xyd.BattleType.ENTRANCE_TEST then
		xyd.WindowManager.get():openWindow("activity_entrance_test_pve_window", {
			testType = self.battleParams.boss_id,
			isFirstPass = self.battleParams.isFirstPass
		})
	end
end

function BattleWinWindow:prepareProgress(cur_lev)
	self.curLev = cur_lev or 0

	if self.complelte_flag then
		return
	end

	local total = 0
	local max_lev = xyd.tables.newTrialRewardTable:getLevByDamage(tonumber(self.battleParams.total_harm))
	self.labelHasUnlocked_.text = self.curLev

	if self.curLev ~= 0 then
		local EffectArr = xyd.tables.newTrialRewardTable:getRewardsEffect(self.curLev)

		if self.rewardEffect_ then
			self.rewardEffect_:play(EffectArr[1], 1, 1, function ()
				self.rewardEffect_:play(EffectArr[2], 1, 0)
			end)
		end
	elseif self.rewardEffect_ then
		self.rewardEffect_:play("texiao02", 1, 1)
	end

	if max_lev <= self.curLev then
		self:endProgress(self.curLev)

		return
	end

	local function callback()
		if self.complelte_flag then
			self.frameTimer_:Stop()

			return
		end

		total = total + 1
		self.progressBar_.value = 0.025 * total
		local allDamage = xyd.tables.newTrialRewardTable:getDamageToBoss(self.curLev + 1)
		local alreadyLevDamage = xyd.tables.newTrialRewardTable:getDamageToBoss(self.curLev)
		local nowDamage = alreadyLevDamage + (allDamage - alreadyLevDamage) * total / 40

		if tonumber(nowDamage) < tonumber(self.battleParams.total_harm) then
			self.barText_.text = xyd.getDisplayNumber(math.floor(nowDamage)) .. "/" .. xyd.getDisplayNumber(allDamage)
		else
			self.barText_.text = xyd.getDisplayNumber(math.floor(self.battleParams.total_harm)) .. "/" .. xyd.getDisplayNumber(allDamage)

			self:endProgress(self.curLev)
			self.frameTimer_:Stop()

			return
		end

		if total >= 40 then
			total = 0
			self.curLev = self.curLev + 1

			if max_lev < self.curLev then
				self:endProgress(self.curLev)
				self.frameTimer_:Stop()

				return
			end

			self.labelHasUnlocked_.text = self.curLev

			if self.curLev ~= 0 then
				local EffectArr = xyd.tables.newTrialRewardTable:getRewardsEffect(self.curLev)
				local items = xyd.tables.newTrialRewardTable:getRewardsOnAccount(self.curLev)

				if self.trialSaveItemNum and self.trialSaveItemNum >= #items then
					self.trialSaveItems = {}

					return
				end

				if self.rewardEffect_ then
					self:waitForTime(0.6, function ()
						self:playItemAction(self.curLev)
					end, "award_boss_items" .. self.curLev)
					self.rewardEffect_:play(EffectArr[1], 1, 1, function ()
						self.rewardEffect_:play(EffectArr[2], 1, 0)
					end)
				end
			end
		end
	end

	if not self.frameTimer_ then
		self.frameTimer_ = FrameTimer.New(callback, 1, -1)
	end

	table.insert(self.timers_, self.frameTimer_)
	self.frameTimer_:Start()
end

function BattleWinWindow:prepareActivityProgress(cur_lev)
	local RewardTable = self.rewardTable
	self.curLev = cur_lev or 0

	if self.complelte_flag then
		return
	end

	local total = 0
	local max_lev = RewardTable:getLevByDamage(tonumber(self.battleParams.total_harm))
	self.labelHasUnlocked_.text = self.curLev

	if max_lev <= self.curLev then
		self:endActivityProgress(self.curLev)

		return
	end

	local function callback()
		if self.complelte_flag then
			self.frameTimer_:Stop()

			return
		end

		total = total + 1
		self.progressBar_.value = 0.025 * total
		local allDamage = RewardTable:getDamage(self.curLev + 1)
		local alreadyLevDamage = RewardTable:getDamage(self.curLev)
		local nowDamage = alreadyLevDamage + (allDamage - alreadyLevDamage) * total / 40

		if tonumber(nowDamage) < tonumber(self.battleParams.total_harm) then
			self.barText_.text = xyd.getDisplayNumber(math.floor(nowDamage)) .. "/" .. xyd.getDisplayNumber(allDamage)
		else
			self.barText_.text = xyd.getDisplayNumber(math.floor(self.battleParams.total_harm)) .. "/" .. xyd.getDisplayNumber(allDamage)

			self:endActivityProgress(self.curLev)
			self.frameTimer_:Stop()

			return
		end

		if total >= 40 then
			total = 0
			self.curLev = self.curLev + 1

			if max_lev < self.curLev then
				self:endActivityProgress(self.curLev)
				self.frameTimer_:Stop()

				return
			end

			self.labelHasUnlocked_.text = self.curLev
		end
	end

	if not self.frameTimer_ then
		self.frameTimer_ = FrameTimer.New(callback, 1, -1)
	end

	table.insert(self.timers_, self.frameTimer_)
	self.frameTimer_:Start()
end

function BattleWinWindow:playItemAction(lev)
	local items = xyd.tables.newTrialRewardTable:getRewardsOnAccount(lev)
	local show_items = items[#items]
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.PRIVILEGE_CARD)

	for i = 1, #show_items do
		local show_item = show_items[i]
		local Sequence = self:getSequence()
		local itemId = show_item[1]
		local itemNum = tonumber(show_item[2])

		if activityData then
			local isHasCard = activityData:getStateById(xyd.GIFTBAG_ID.PRIVILEGE_CARD_TRIAL)

			if isHasCard then
				itemNum = math.floor(itemNum * 1.2)
			end
		end

		local params = {
			scale = 1,
			itemID = itemId,
			num = itemNum,
			uiRoot = self.effectGroup_
		}
		local itemIcon = xyd.getItemIcon(params)

		Sequence:Insert(0, itemIcon.go.transform:DOLocalMove(Vector3(-150, -90, 0), 0.4 + i * 0.3))
		Sequence:Insert(0, itemIcon.go.transform:DOScale(Vector3(0.4, 0.4, 0), 0.4 + i * 0.3))
		Sequence:AppendCallback(function ()
			if itemIcon and itemIcon.go then
				NGUITools.Destroy(itemIcon.go)
			end

			self:addTrialAwardItem(itemId, itemNum, i == #show_items)
		end)
	end
end

function BattleWinWindow:addTrialAwardItem(itemId, itemNum, isFinal, needCheckCard)
	table.insert(self.trialSaveItems, {
		itemId = itemId,
		itemNum = tonumber(itemNum)
	})

	local levIds = xyd.tables.newTrialRewardTable:getIds()
	local awardList = xyd.tables.newTrialRewardTable:getRewardsOnAccount(levIds[#levIds])

	if isFinal then
		if self.trialSaveItemNum and self.trialSaveItemNum >= #awardList then
			self.trialSaveItems = {}

			return
		end

		for _, item in ipairs(self.trialSaveItems) do
			local itemId = item.itemId
			local itemnum = item.itemNum
			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.PRIVILEGE_CARD)

			if needCheckCard and activityData and activityData:getStateById(xyd.GIFTBAG_ID.PRIVILEGE_CARD_TRIAL) then
				itemnum = math.floor(itemnum * 1.2)
			end

			local hasSameId = false

			for _, itemIcon in ipairs(self.progressItemsList_) do
				if itemIcon:getItemID() == itemId then
					hasSameId = true

					itemIcon:setNum(itemIcon:getNum() + itemnum)

					break
				end
			end

			if not hasSameId then
				local icon = xyd.getItemIcon({
					uiRoot = self.progressItemsGroup_.gameObject,
					itemID = itemId,
					num = tonumber(itemnum)
				})

				table.insert(self.progressItemsList_, icon)
			end

			self.progressItemsGroup_:Reposition()
		end

		if self.trialSaveItemNum then
			self.trialSaveItemNum = self.trialSaveItemNum + 1
		else
			self.trialSaveItemNum = 1
		end

		self.trialSaveItems = {}
	end
end

function BattleWinWindow:endProgress(lev)
	local ret_damage = self.battleParams.total_harm - xyd.tables.newTrialRewardTable:getDamageToBoss(lev)
	local all_damage = xyd.tables.newTrialRewardTable:getDamageToBoss(lev + 1) - xyd.tables.newTrialRewardTable:getDamageToBoss(lev)

	local function setter(value)
		self.progressBar_.value = value
	end

	self.progressBar_.value = 0

	self:waitForFrame(1, function ()
		local sequence = self:getSequence()
		local maxLev = #xyd.tables.newTrialRewardTable:getIds()

		if xyd.tables.newTrialRewardTable:getDamageToBoss(maxLev) <= tonumber(self.battleParams.total_harm) then
			sequence:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 1, 0.1))

			self.barText_.text = xyd.getDisplayNumber(self.battleParams.total_harm) .. "/" .. xyd.getDisplayNumber(xyd.tables.newTrialRewardTable:getDamageToBoss(maxLev))
		else
			sequence:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, ret_damage / all_damage, 0.1))

			self.barText_.text = xyd.getDisplayNumber(self.battleParams.total_harm) .. "/" .. xyd.getDisplayNumber(xyd.tables.newTrialRewardTable:getDamageToBoss(lev + 1))
		end
	end)
	self.touchGroup_:SetActive(false)
end

function BattleWinWindow:endActivityProgress(lev)
	local RewardTable = self.rewardTable
	local ret_damage = self.battleParams.total_harm - RewardTable:getDamage(lev)
	local all_damage = RewardTable:getDamage(lev + 1) - RewardTable:getDamage(lev)

	if all_damage == 0 then
		all_damage = 1
	end

	local function setter(value)
		self.progressBar_.value = value
	end

	self.touchGroup_:SetActive(false)
end

function BattleWinWindow:completeProgress()
	XYDCo.StopWait("award_boss_items" .. self.curLev)

	local total_harm = tonumber(self.battleParams.total_harm)
	local lev = xyd.tables.newTrialRewardTable:getLevByDamage(total_harm)
	local effectArr = xyd.tables.newTrialRewardTable:getRewardsEffect(lev)

	if self.rewardEffect_ and effectArr[2] then
		self.rewardEffect_:play(effectArr[2], 1, 1)
	end

	self.complelte_flag = true
	local maxLev = #xyd.tables.newTrialRewardTable:getIds()

	if lev == maxLev then
		self.progressBar_.value = 1
		self.barText_.text = xyd.getDisplayNumber(self.battleParams.total_harm) .. "/" .. xyd.getDisplayNumber(xyd.tables.newTrialRewardTable:getDamageToBoss(lev + 1))
	else
		local ret_damage = self.battleParams.total_harm - xyd.tables.newTrialRewardTable:getDamageToBoss(lev)
		local all_damage = xyd.tables.newTrialRewardTable:getDamageToBoss(lev + 1) - xyd.tables.newTrialRewardTable:getDamageToBoss(lev)
		self.progressBar_.value = ret_damage / all_damage
		self.barText_.text = xyd.getDisplayNumber(self.battleParams.total_harm) .. "/" .. xyd.getDisplayNumber(xyd.tables.newTrialRewardTable:getDamageToBoss(lev + 1))
	end

	self.labelHasUnlocked_.text = lev
	local itemsData = xyd.tables.newTrialRewardTable:getRewardsOnAccount(lev)
	local hasInitNum = nil

	if self.trialSaveItemNum then
		hasInitNum = self.trialSaveItemNum + 1
	else
		hasInitNum = 1
	end

	for i = hasInitNum, #itemsData do
		for idx, data in ipairs(itemsData[i]) do
			self:addTrialAwardItem(data[1], data[2], idx == #itemsData[i], true)
		end
	end

	self.touchGroup_:SetActive(false)
end

function BattleWinWindow:completeActivityProgress()
	local RewardTable = self.rewardTable
	local awardIDs = RewardTable:getIds()
	local maxLev = #awardIDs
	local lev = 0

	for i = 1, maxLev do
		if RewardTable:getDamage(i) <= self.battleParams.total_harm then
			lev = i
		else
			break
		end
	end

	self.complelte_flag = true

	if lev == maxLev then
		self.progressBar_.value = 1
		self.barText_.text = xyd.getDisplayNumber(self.battleParams.total_harm) .. "/" .. xyd.getDisplayNumber(RewardTable:getDamage(lev))

		if self.battleType == xyd.BattleType.ICE_SECRET_BOSS then
			local allDamage = RewardTable:getDamage(maxLev + 1)
			local alreadyLevDamage = RewardTable:getDamage(maxLev)
			local nowDamage = alreadyLevDamage + (allDamage - alreadyLevDamage) * 40 / 40
			self.barText_.text = xyd.getDisplayNumber(math.floor(nowDamage)) .. "/" .. xyd.getDisplayNumber(allDamage)
		end
	else
		local ret_damage = self.battleParams.total_harm - RewardTable:getDamage(lev)
		local all_damage = RewardTable:getDamage(lev + 1) - RewardTable:getDamage(lev)
		self.progressBar_.value = ret_damage / all_damage
		self.barText_.text = xyd.getDisplayNumber(self.battleParams.total_harm) .. "/" .. xyd.getDisplayNumber(RewardTable:getDamage(lev + 1))
	end

	self.labelHasUnlocked_.text = lev

	self.touchGroup_:SetActive(false)
end

function BattleWinWindow:iosTestChangeUI()
	xyd.setUISprite(self.confirmBtn:GetComponent(typeof(UISprite)), nil, "blue_btn70_70_ios_test")
end

return BattleWinWindow
