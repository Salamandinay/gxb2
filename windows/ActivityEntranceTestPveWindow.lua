local ActivityEntranceTestPveWindow = class("ActivityEntranceTestPveWindow", import(".BaseWindow"))
local CountDown = import("app.components.CountDown")
local ItemRender = class("ItemRender", import("app.components.CopyComponent"))
local HeroIcon = import("app.components.HeroIcon")

function ActivityEntranceTestPveWindow:ctor(name, params)
	ActivityEntranceTestPveWindow.super.ctor(self, name, params)

	self.testType = params.testType
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	self.isFirstPass = params.isFirstPass
end

function ActivityEntranceTestPveWindow:initWindow()
	self:getUIComponent()
	ActivityEntranceTestPveWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function ActivityEntranceTestPveWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.winTitle = self.topGroup:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = self.topGroup:NodeByName("closeBtn").gameObject
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.rankBtn = self.upCon:NodeByName("rankBtn").gameObject
	self.personEffectCon = self.upCon:ComponentByName("personEffectCon", typeof(UITexture))
	self.personClickCon = self.personEffectCon:ComponentByName("personClickCon", typeof(UISprite))
	self.buffsTipsCon = self.upCon:NodeByName("buffsTipsCon").gameObject
	self.buffsTipsCancel = self.upCon:ComponentByName("buffsTipsCancel", typeof(UISprite))
	self.progressCon = self.upCon:NodeByName("progressCon").gameObject
	self.progress = self.progressCon:NodeByName("progress").gameObject
	self.progressUIProgressBar = self.progressCon:ComponentByName("progress", typeof(UIProgressBar))
	self.roundText = self.progressCon:ComponentByName("roundText", typeof(UILabel))
	self.bloodText = self.progressCon:ComponentByName("bloodText", typeof(UILabel))
	self.arrowCon = self.upCon:NodeByName("arrowCon").gameObject
	self.arrowLeft = self.arrowCon:ComponentByName("arrowLeft", typeof(UISprite))
	self.arrowRight = self.arrowCon:ComponentByName("arrowRight", typeof(UISprite))
	self.upBg = self.upCon:ComponentByName("upBg", typeof(UITexture))
	self.downCon = self.groupAction:NodeByName("downCon").gameObject
	self.rewardText = self.downCon:ComponentByName("rewardText", typeof(UILabel))
	self.rewardBg = self.downCon:ComponentByName("rewardBg", typeof(UISprite))
	self.rewardItemCon = self.downCon:NodeByName("rewardItemCon").gameObject
	self.rewardItemConUILayout = self.downCon:ComponentByName("rewardItemCon", typeof(UILayout))
	self.canChallengeCon = self.downCon:NodeByName("canChallengeCon").gameObject
	self.canChallengeText = self.canChallengeCon:ComponentByName("canChallengeText", typeof(UILabel))
	self.overChallengeCon = self.downCon:NodeByName("overChallengeCon").gameObject
	self.overChallengeBg = self.overChallengeCon:ComponentByName("overChallengeBg", typeof(UISprite))
	self.overChallengeBg2 = self.overChallengeCon:ComponentByName("overChallengeBg2", typeof(UISprite))
	self.overChallengeText = self.overChallengeCon:ComponentByName("overChallengeText", typeof(UILabel))
	self.overChallengeTimeText = self.overChallengeCon:ComponentByName("overChallengeTimeText", typeof(UILabel))
	self.fakeFightBtn = self.downCon:NodeByName("fakeFightBtn").gameObject
	self.fakeFightText = self.fakeFightBtn:ComponentByName("fakeFightText", typeof(UILabel))
	self.fightBtn = self.downCon:NodeByName("fightBtn").gameObject
	self.fightBtnLayoutCon = self.fightBtn:NodeByName("fightBtnLayoutCon").gameObject
	self.fightBtnLayoutConUILayout = self.fightBtn:ComponentByName("fightBtnLayoutCon", typeof(UILayout))
	self.fightBtnIcon = self.fightBtnLayoutCon:NodeByName("fightBtnIcon").gameObject
	self.fightText = self.fightBtnLayoutCon:ComponentByName("fightText", typeof(UILabel))
	self.timeCon = self.downCon:NodeByName("timeCon").gameObject
	self.timeConUILayout = self.downCon:ComponentByName("timeCon", typeof(UILayout))
	self.timeText = self.timeCon:ComponentByName("timeText", typeof(UILabel))
	self.endText = self.timeCon:ComponentByName("endText", typeof(UILabel))
	self.heroItemRender = self.downCon:NodeByName("heroItemRender").gameObject
	self.groupPreview_ = self.groupAction:NodeByName("groupPreview_").gameObject
	self.labelPreviewTitle_ = self.groupPreview_:ComponentByName("labelPreviewTitle_", typeof(UILabel))
	self.groupPreviewHeros_ = self.groupPreview_:NodeByName("groupPreviewHeros_").gameObject
	self.groupPreviewHeros_UILayout = self.groupPreview_:ComponentByName("groupPreviewHeros_", typeof(UILayout))
	self.groupPreviewTipsCancel = self.groupAction:NodeByName("groupPreviewTipsCancel").gameObject
	self.groupPreviewBg_ = self.groupPreview_:ComponentByName("e:Image", typeof(UIWidget))
end

function ActivityEntranceTestPveWindow:reSize()
end

function ActivityEntranceTestPveWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)

	UIEventListener.Get(self.rankBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_entrance_test_new_rank_window", {
			curNavIndex = self.testType
		})
	end

	UIEventListener.Get(self.arrowLeft.gameObject).onClick = handler(self, function ()
		if self.testType > 1 then
			self.testType = self.testType - 1
		else
			self.testType = self.activityData:getPveMaxStage()
		end

		self.initEnemies = false
		self.isFirstPass = false

		self:updateShow()
	end)
	UIEventListener.Get(self.arrowRight.gameObject).onClick = handler(self, function ()
		if self.activityData:getPveMaxStage() <= self.testType then
			self.testType = 1
		else
			self.testType = self.testType + 1
		end

		self.initEnemies = false
		self.isFirstPass = false

		self:updateShow()
	end)
	UIEventListener.Get(self.fightBtn.gameObject).onClick = handler(self, function ()
		local times = self.activityData:getFreeTimes()

		if times <= 0 then
			self.activityData:buyTicket()

			return
		end

		xyd.WindowManager:get():openWindow("battle_formation_window", {
			showSkip = true,
			battleType = xyd.BattleType.ENTRANCE_TEST,
			mapType = xyd.MapType.ENTRANCE_TEST,
			enemy_id = self.testType,
			skipState = xyd.checkCondition(tonumber(xyd.db.misc:getValue("entrance_test_skip_pve_report")) == 1, true, false),
			btnSkipCallback = function (flag)
				local valuedata = xyd.checkCondition(flag, 1, 0)

				xyd.db.misc:setValue({
					key = "entrance_test_skip_pve_report",
					value = valuedata
				})
			end
		})
	end)
	UIEventListener.Get(self.fakeFightBtn.gameObject).onClick = handler(self, function ()
		if not self.activityData:getIsCanFake() then
			xyd.alertTips(__("ACTIVITY_NEW_WARMUP_TEXT31"))

			return
		end

		xyd.WindowManager:get():openWindow("battle_formation_window", {
			entrance_is_fake = 1,
			showSkip = true,
			battleType = xyd.BattleType.ENTRANCE_TEST,
			mapType = xyd.MapType.ENTRANCE_TEST,
			enemy_id = self.testType,
			skipState = xyd.checkCondition(tonumber(xyd.db.misc:getValue("entrance_test_skip_pve_report")) == 1, true, false),
			btnSkipCallback = function (flag)
				local valuedata = xyd.checkCondition(flag, 1, 0)

				xyd.db.misc:setValue({
					key = "entrance_test_skip_pve_report",
					value = valuedata
				})
			end
		})
	end)
	UIEventListener.Get(self.personClickCon.gameObject).onClick = handler(self, self.showEnemy)
	UIEventListener.Get(self.groupPreviewTipsCancel.gameObject).onClick = handler(self, function ()
		self.groupPreview_:SetActive(false)
		self.groupPreviewTipsCancel:SetActive(false)
	end)
end

function ActivityEntranceTestPveWindow:layout()
	self.roundText.text = __("ACTIVITY_NEW_WARMUP_TEXT16")
	self.rewardText.text = __("ACTIVITY_NEW_WARMUP_TEXT17")
	self.canChallengeText.text = __("ACTIVITY_NEW_WARMUP_TEXT18")
	self.overChallengeText.text = __("ACTIVITY_NEW_WARMUP_TEXT19")
	self.fakeFightText.text = __("ACTIVITY_NEW_WARMUP_TEXT20")
	self.fightText.text = __("ACTIVITY_NEW_WARMUP_TEXT21")
	self.labelPreviewTitle_.text = __("ENEMY_PREVIEW")

	self.fightBtnLayoutConUILayout:Reposition()

	self.endText.text = __("TEXT_END")

	if xyd.Global.lang == "fr_fr" then
		self.endText.transform:SetSiblingIndex(0)
		self.timeText.transform:SetSiblingIndex(1)
	end

	self:initTime()
	self:updateShow()
end

function ActivityEntranceTestPveWindow:initTime()
	local endTime = self.activityData:getEndTime()
	local disTime = endTime - xyd:getServerTime()

	if disTime > 0 then
		local timeCount = CountDown.new(self.timeText)

		timeCount:setInfo({
			duration = disTime,
			callback = function ()
				self.timeText.text = "00:00:00"

				self.timeConUILayout:Reposition()
			end
		})
	else
		self.timeText.text = "00:00:00"
	end

	if xyd.Global.lang == "fr_fr" then
		self.endText.transform:SetSiblingIndex(0)
		self.timeText.transform:SetSiblingIndex(1)
	end

	self.timeConUILayout:Reposition()
end

function ActivityEntranceTestPveWindow:updateShow()
	self:updateBaseShow()
	self:updateAwardShow()
	self:updatePersonShow()
	self:updateFreeTimesShow()

	local nowHarm = self.activityData:getBossHarm(self.testType)
	local totalHarm = xyd.tables.activityWarmupArenaBossTable:getBossScore(self.testType)

	if totalHarm < nowHarm then
		nowHarm = totalHarm
	end

	self.bloodText.text = xyd.getRoughDisplayNumber(nowHarm) .. "/" .. xyd.getRoughDisplayNumber(totalHarm)
	self.progressUIProgressBar.value = nowHarm / totalHarm
end

function ActivityEntranceTestPveWindow:updateFreeTimesShow()
	local times = self.activityData:getFreeTimes()

	if times <= 0 then
		self.overChallengeTimeText.color = Color.New2(3422556671.0)
	else
		self.overChallengeTimeText.color = Color.New2(960513791)
	end

	self.overChallengeTimeText.text = times
end

function ActivityEntranceTestPveWindow:updateBaseShow()
	self.winTitle.text = __("ACTIVITY_NEW_WARMUP_TEXT" .. self.testType + 33)

	xyd.setUITextureByNameAsync(self.upBg, "activity_entrance_test_pve_bg_" .. self.testType, nil, function ()
		xyd.setUITextureByNameAsync(self.upBg, "activity_entrance_test_pve_bg_" .. self.testType)
	end)
end

function ActivityEntranceTestPveWindow:updateAwardShow()
	local awards = xyd.tables.activityWarmupArenaPartnerTable:getPeriodArrWithType(self.testType)

	if not self.awardArr then
		self.awardArr = {}
	end

	if #awards > 0 then
		for i, id in pairs(awards) do
			local param = {
				id = id,
				index = i
			}

			if not self.awardArr[i] then
				local tmp = NGUITools.AddChild(self.rewardItemCon.gameObject, self.heroItemRender.gameObject)
				local item = ItemRender.new(tmp, self)

				item:setInfo(param)

				self.awardArr[i] = item
			else
				self.awardArr[i]:setInfo(param)
			end

			self.awardArr[i]:getGameObject():SetActive(true)
		end

		self.rewardItemConUILayout:Reposition()
	end

	for i = #awards + 1, #self.awardArr do
		self.awardArr[i]:getGameObject():SetActive(false)
	end
end

function ActivityEntranceTestPveWindow:updatePersonShow()
	local partnerArr = xyd.tables.miscTable:split2num("activity_warmup_arena_boss_model", "value", "|")
	local modelId = xyd.tables.partnerTable:getModelID(partnerArr[self.testType])
	local effectName = xyd.tables.modelTable:getModelName(modelId)
	local effectScale = xyd.tables.modelTable:getScale(modelId)

	if not self["personEffect" .. self.testType] then
		self["personEffect" .. self.testType] = xyd.Spine.new(self.personEffectCon.gameObject)

		self["personEffect" .. self.testType]:setInfo(effectName, function ()
			self["personEffect" .. self.testType]:SetLocalScale(effectScale * 0.92, effectScale * 0.92, effectScale * 0.92)
			self["personEffect" .. self.testType]:play("idle", 0)
		end)
	else
		self["personEffect" .. self.testType]:SetActive(true)
	end

	for i = 1, self.activityData:getPveMaxStage() do
		if i ~= self.testType and self["personEffect" .. i] then
			self["personEffect" .. i]:SetActive(false)
		end
	end
end

function ActivityEntranceTestPveWindow:getIsFirstPass()
	return self.isFirstPass
end

function ActivityEntranceTestPveWindow:getTestType()
	return self.testType
end

function ActivityEntranceTestPveWindow:showEnemy()
	if not self.initEnemies then
		local bossTable = xyd.tables.activityWarmupArenaBossTable
		local battleId = bossTable:getBattleId(self.testType)
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
					scale = 0.7037037037037037,
					tableID = id,
					lev = lev
				})
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

function ItemRender:ctor(go, parent)
	ItemRender.super.ctor(self, go)

	self.parent = parent
end

function ItemRender:getUIComponent()
	self.goWidget = self.go:GetComponent(typeof(UIWidget))
	self.itemCon = self.go:NodeByName("itemCon").gameObject
	self.itemConUIWidget = self.go:ComponentByName("itemCon", typeof(UIWidget))
	self.lockEffectCon = self.go:ComponentByName("lockEffectCon", typeof(UITexture))
end

function ItemRender:initUI()
	self:getUIComponent()
	ItemRender.super.initUI(self)
end

function ItemRender:setInfo(info)
	local id = info.id
	local index = info.index
	self.itemConUIWidget.depth = index * 200
	self.lockEffectCon.depth = self.itemConUIWidget.depth + 100

	self.lockEffectCon.gameObject:SetLocalPosition(24.6, -35.8, 0)

	local partnerId = xyd.tables.activityWarmupArenaPartnerTable:getPartnerId(id)
	local params = {
		num = 1,
		isShowSelected = false,
		itemID = partnerId,
		scale = Vector3(0.7, 0.7, 1),
		uiRoot = self.itemCon.gameObject,
		callback = function ()
			local params = {
				current_group = 0,
				partner = self.parent.activityData:getPartnerByIndex(id),
				sort_key = xyd.partnerSortType.SHENXUE .. "_0" .. "_0",
				table_id = partnerId,
				sort_type = xyd.partnerSortType.SHENXUE
			}

			xyd.WindowManager.get():openWindow("activity_entrance_test_partner_window", params)
		end
	}

	if not self.heroIcon then
		self.heroIcon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	else
		self.heroIcon:setInfo(params)
	end

	self.goWidget.width = 75.6
	self.goWidget.height = 75.6

	if not self.lockEffect then
		self.lockEffect = xyd.Spine.new(self.lockEffectCon.gameObject)

		self.lockEffect:setInfo("fx_warmup_arena_unlock", function ()
			self.lockEffect:setRenderTarget(self.lockEffectCon, 1)
			self.lockEffect:stop()
			self.lockEffect:setToSetupPose()

			if self.parent:getIsFirstPass() then
				self.lockEffect:play("texiao01", 1)
			elseif not self.parent.activityData:getPvePartnerIsLock(self.parent:getTestType()) then
				self.lockEffect:SetActive(false)
			end
		end)
	else
		self.lockEffect:SetActive(true)
		self.lockEffect:stop()
		self.lockEffect:setToSetupPose()

		if self.parent:getIsFirstPass() then
			self.lockEffect:play("texiao01", 1)
		elseif not self.parent.activityData:getPvePartnerIsLock(self.parent:getTestType()) then
			self.lockEffect:SetActive(false)
		else
			self.lockEffect:SetActive(true)
		end
	end

	self.heroIcon:setMask(self.parent.activityData:getPvePartnerIsLock(self.parent:getTestType()))
end

return ActivityEntranceTestPveWindow
