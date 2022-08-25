local BaseWindow = import(".BaseWindow")
local ActivityEntranceTestWindow = class("ActivityEntranceTestWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")
local CountDown = require("app.components.CountDown")
local ActivityEntranceTestHelpItems = import("app.components.ActivityEntranceTestHelpItems")

function ActivityEntranceTestWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.isEnterRank = true
	self.tiliTimeIndex = 0
	self.currentState = xyd.Global.lang
	local msg = messages_pb:log_partner_data_touch_req()
	msg.touch_id = tonumber(xyd.DaDian.ENTRANCE_TEST)

	xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)

	if self.activityData then
		self.activityData:makeHeros()
	end

	self.timeclosekey = -1
	self.activityEntranceTestHelpItems = ActivityEntranceTestHelpItems.new()

	if params then
		self.fromTask = params.fromTask
	end
end

function ActivityEntranceTestWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:initTopGroup()
	self:layout()
	self:registerEvent()
end

function ActivityEntranceTestWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupAll = trans:NodeByName("groupAll").gameObject
	self.leftBg = self.groupAll:NodeByName("leftBg").gameObject
	self.nameText1 = self.leftBg:ComponentByName("e:Group/nameText1", typeof(UILabel))
	self.cvText1 = self.leftBg:ComponentByName("e:Group/cvText1", typeof(UILabel))
	self.groupImage1 = self.leftBg:ComponentByName("e:Group/e:image2", typeof(UISprite))
	self.rightBg = self.groupAll:NodeByName("rightBg").gameObject
	self.nameText2 = self.rightBg:ComponentByName("e:Group/nameText2", typeof(UILabel))
	self.cvText2 = self.rightBg:ComponentByName("e:Group/cvText2", typeof(UILabel))
	self.groupImage2 = self.rightBg:ComponentByName("e:Group/e:image2", typeof(UISprite))
	self.groupDown = trans:NodeByName("groupDown").gameObject
	self.groupDetail = self.groupDown:NodeByName("groupDetail").gameObject
	self.groupDetailWidgt = self.groupDetail:GetComponent(typeof(UIWidget))
	self.resNode = self.groupDetail:NodeByName("resNode").gameObject
	self.resIcon = self.resNode:ComponentByName("resIcon", typeof(UISprite))
	self.LabelResNum = self.resNode:ComponentByName("LabelResNum", typeof(UILabel))
	self.plusBtn = self.resNode:NodeByName("plusBtn").gameObject
	self.btnFight = self.groupDetail:NodeByName("btnFight").gameObject
	self.btnFight_button_label = self.btnFight:ComponentByName("button_label", typeof(UILabel))
	self.btnFight_lock = self.btnFight:NodeByName("lockImg").gameObject
	self.btnAward = self.groupDetail:NodeByName("btnAward").gameObject
	self.btnAward_icon = self.btnAward:ComponentByName("icon", typeof(UISprite))
	self.btnAward_button_label = self.btnAward:ComponentByName("button_label", typeof(UILabel))
	self.btnRecord = self.groupDetail:NodeByName("btnRecord").gameObject
	self.btnRecord_icon = self.btnRecord:ComponentByName("icon", typeof(UISprite))
	self.btnRecord_button_label = self.btnRecord:ComponentByName("button_label", typeof(UILabel))
	self.btnFormation = self.groupDetail:NodeByName("btnFormation").gameObject
	self.btnFormation_icon = self.btnFormation:ComponentByName("icon", typeof(UISprite))
	self.btnFormation_button_label = self.btnFormation:ComponentByName("button_label", typeof(UILabel))
	self.tiliNode = self.groupDetail:NodeByName("tiliNode").gameObject
	local countDownTiliText = self.tiliNode:ComponentByName("e:Group/countDownTiliText", typeof(UILabel))
	self.tiliTipWords = self.tiliNode:ComponentByName("e:Group/tiliTipWords", typeof(UILabel))
	self.scoreGroup = self.groupDetail:NodeByName("scoreGroup").gameObject
	self.levelImg = self.groupDetail:ComponentByName("scoreGroup/levelImg", typeof(UISprite))
	self.rankWords = self.scoreGroup:ComponentByName("rankWords", typeof(UILabel))
	self.scoreWords = self.scoreGroup:ComponentByName("scoreWords", typeof(UILabel))
	self.rankText = self.scoreGroup:ComponentByName("rankText", typeof(UILabel))
	self.scoreText = self.scoreGroup:ComponentByName("scoreText", typeof(UILabel))
	self.levelUPText = self.scoreGroup:ComponentByName("levelUPText", typeof(UILabel))
	self.levelUPWord = self.scoreGroup:ComponentByName("levelUPWord", typeof(UILabel))
	self.progress = self.scoreGroup:ComponentByName("progress", typeof(UIProgressBar))
	self.progressEffectNode = self.scoreGroup:NodeByName("progress/effectNode").gameObject
	self.levelUpicon = self.scoreGroup:NodeByName("levelUpIcon").gameObject
	self.groupPromotion = self.groupDown:NodeByName("groupPromotion").gameObject
	self.promotionLabel = self.groupPromotion:ComponentByName("promotionLabel", typeof(UILabel))
	self.promotionEndLabel = self.groupPromotion:ComponentByName("endGroup/endLabel", typeof(UILabel))
	self.promotionTimeLabel = self.groupPromotion:ComponentByName("endGroup/timeLabel", typeof(UILabel))
	self.logoNode = trans:NodeByName("logoNode").gameObject
	self.logoNode_widget = trans:ComponentByName("logoNode", typeof(UIWidget))
	self.logo = self.logoNode:ComponentByName("logo", typeof(UISprite))
	self.helpBtn0 = self.logoNode:NodeByName("e:GroupBtn/helpBtn0").gameObject
	local countDownText = self.logoNode:ComponentByName("e:Group/countDownText", typeof(UILabel))
	self.countDownText_label = self.logoNode:ComponentByName("e:Group/countDownText", typeof(UILabel))
	self.endLabel = self.logoNode:ComponentByName("e:Group/endLabel", typeof(UILabel))
	self.countDownText_layout = self.logoNode:ComponentByName("e:Group", typeof(UILayout))
	self.rankBtn0 = self.logoNode:NodeByName("e:GroupBtn/rankBtn0").gameObject
	self.leftNodeCon = trans:NodeByName("leftNodeCon").gameObject
	self.leftNode = self.leftNodeCon:NodeByName("leftNode").gameObject
	self.setHeroBtn = self.leftNode:NodeByName("setHeroBtn").gameObject
	self.setHeroBtn_button_label = self.leftNode:ComponentByName("setHeroBtn/button_label", typeof(UILabel))
	self.setHeroRed = self.leftNode:NodeByName("setHeroBtn/redPoint").gameObject
	self.newTipsNode = self.leftNode:NodeByName("setHeroBtn/newTipsNode").gameObject
	self.newTipsWords = self.leftNode:ComponentByName("setHeroBtn/newTipsNode/newTipsWords", typeof(UILabel))

	self.newTipsNode:SetActive(self.activityData:checkHasNew())

	self.missionBtn = self.leftNode:NodeByName("missionBtn").gameObject
	self.missionBtnLabel = self.missionBtn:ComponentByName("label", typeof(UILabel))
	self.missionBtnRed = self.leftNode:NodeByName("missionBtn/redPoint").gameObject
	self.countDownText = CountDown.new(countDownText)
	self.bg = trans:NodeByName("e:image").gameObject
	self.pveDownGroup = self.window_:NodeByName("pveDownGroup").gameObject
	self.showsBtn = self.pveDownGroup:NodeByName("showsBtn").gameObject
	self.showsBtnRed = self.showsBtn:ComponentByName("redPoint", typeof(UISprite))
	self.showsBtnLabel = self.showsBtn:ComponentByName("label", typeof(UILabel))
	self.showsBtnEffect = self.showsBtn:ComponentByName("showsBtnEffect", typeof(UITexture))

	for i = 1, 3 do
		self["pveBtn" .. i] = self.pveDownGroup:NodeByName("pveBtn" .. i).gameObject
		self["pvebtnTextImg" .. i] = self["pveBtn" .. i]:ComponentByName("pvebtnTextImg", typeof(UISprite))
		self["pveBtnRedPoint" .. i] = self["pveBtn" .. i]:ComponentByName("redPoint", typeof(UISprite)).gameObject
	end
end

function ActivityEntranceTestWindow:playOpenAnimation(callback)
	ActivityEntranceTestWindow.super.playOpenAnimation(self, callback)
	self:resizePosY(self.leftNodeCon.gameObject, 387, 473)
	self.leftNode.transform:X(-89)
	self:waitForTime(0.1, handler(self, function ()
		self.actionLeftNode = DG.Tweening.DOTween.Sequence()

		self.actionLeftNode:Append(self.leftNode.transform:DOLocalMoveX(85, 0.2))
		self.actionLeftNode:AppendCallback(function ()
			self.actionLeftNode:Kill(true)
		end)
	end))
	self:resizePosY(self.bg.gameObject, -77, 9)
	self:resizePosY(self.leftBg.gameObject, 159, 245)
	self:resizePosY(self.pveDownGroup.gameObject, -383, -457)
	self.rightBg:Y(-95 + 76 * self.scale_num_contrary)

	self.logoNode_widget.alpha = 0.01

	self:waitForTime(0.1, handler(self, function ()
		self.actionLogoNode = DG.Tweening.DOTween.Sequence()

		self.actionLogoNode:Append(xyd.getTweenAlpha(self.logoNode_widget, 1, 0.2))
		self.actionLogoNode:AppendCallback(function ()
			self.actionLogoNode:Kill(true)
		end)
	end))
end

function ActivityEntranceTestWindow:playCloseAnimation(callback)
	ActivityEntranceTestWindow.super.playCloseAnimation(self, callback)

	if self.actionLeftBg then
		self.actionLeftBg:Kill(true)
	end

	if self.actionRightBg then
		self.actionRightBg:Kill(true)
	end

	if self.actionLeftNode then
		self.actionLeftNode:Kill(true)
	end

	if self.actionGroupDetail then
		self.actionGroupDetail:Kill(true)
	end

	if self.actionLogoNode then
		self.actionLogoNode:Kill(true)
	end

	if self.actioneffectNode then
		self.actioneffectNode:Kill(true)
	end
end

function ActivityEntranceTestWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_, 50)
	local items = {
		{
			id = xyd.ItemID.ENTRANCE_PVE_TICKET
		},
		{
			id = xyd.ItemID.CRYSTAL
		}
	}

	self.windowTop:setItem(items)

	self.firstResItem = self.windowTop:getResItems()[1]

	self.firstResItem:setIsRefreshWithItemChange(false)
	self:updateFreeTimesShow()

	local plusBtn = self.firstResItem:getGameObject():NodeByName("plus_btn").gameObject
	local plusBtnBoxCollider = plusBtn:AddComponent(typeof(UnityEngine.BoxCollider))
	plusBtnBoxCollider.size = Vector2(60, 60)

	UIEventListener.Get(plusBtn).onClick = function ()
		self.activityData:buyTicket()
	end
end

function ActivityEntranceTestWindow:updateFreeTimesShow()
	self.firstResItem:setItemNum(self.activityData:getFreeTimes())
end

function ActivityEntranceTestWindow:getWindowTop()
	return self.windowTop
end

function ActivityEntranceTestWindow:layout()
	self.tiliNode:SetActive(false)

	self.btnAward_button_label.text = __("CAMPAIGN_RANK")
	self.btnRecord_button_label.text = __("RECORD")
	self.btnFormation_button_label.text = __("DEFFORMATION")
	self.btnFight_button_label.text = __("FIGHT2")
	self.rankText.text = __("RANK")
	self.scoreText.text = __("SCORE")
	self.levelUPText.text = __("ENTRANCE_TEST_LEVEL_UP_NEED")
	self.tiliTipWords.text = __("ACTIVITY_ENTRANCE_TEST_TIME_TIPS")
	self.setHeroBtn_button_label.text = __("ENTRANCE_TEST_SETTING_PARTNER")
	self.newTipsWords.text = __("ENTRANCE_TEST_NEW_HERO_TIPS")
	self.promotionLabel.text = __("ENTRANCE_TEST_LEVEL_UP_ING")
	self.promotionEndLabel.text = __("ACTIVITY_ENTRANCE_TEST_RANK_WINDOW_4")
	self.missionBtnLabel.text = __("WARMUP_ARENA_TASK_ENTRANCE")
	self.showsBtnLabel.text = __("ACTIVITY_ENTRANCE_TEST_TEXT01")

	xyd.setUISpriteAsync(self.logo, nil, "activity_entrance_test_logo_" .. xyd.Global.lang, nil, , true)
	xyd.db.misc:setValue({
		value = "1",
		key = "ActivityFirstRedMark_" .. xyd.ActivityID.ENTRANCE_TEST .. "_" .. self.activityData.end_time
	})
	self.activityData:getRedMarkState()

	local partnerID = xyd.tables.miscTable:split2Cost("activity_gacha_partners", "value", "|")

	for i = 1, 2 do
		if partnerID[i] then
			xyd.setUISpriteAsync(self["groupImage" .. i], nil, "img_group" .. xyd.tables.partnerTable:getGroup(partnerID[i]))

			self["nameText" .. tostring(i)].text = xyd.tables.partnerTable:getName(partnerID[i])
		end
	end

	if xyd.Global.lang == "ja_jp" then
		self.nameText1.width = 110

		self.nameText1:X(20)
	end

	self:setTimeShow()
	self.btnFight_lock:SetActive(not xyd.checkFunctionOpen(xyd.FunctionID.ENTRANCE_TEST, true))
	self.showsBtnRed:SetActive(self.activityData:getBetRed())

	local openTime = tonumber(xyd.db.misc:getValue("warmup_set_open_time"))

	if openTime and self.activityData:startTime() < openTime then
		self.setHeroRed:SetActive(false)
		self.newTipsNode:SetActive(false)
	else
		self.setHeroRed:SetActive(true)
		self.newTipsNode:SetActive(self.activityData:checkHasNew())
	end

	local level = self.activityData:getLevel()

	xyd.setUISpriteAsync(self.levelImg, nil, "entrance_test_level_" .. level, function ()
		self.levelImg.transform.localScale = Vector3(0.746, 0.734, 1)
	end, nil, true)
	self:updateMissionRed()

	for i = 1, self.activityData:getPveMaxStage() do
		xyd.setUISpriteAsync(self["pvebtnTextImg" .. i], nil, "activity_entrance_ysz_" .. i .. "_" .. xyd.Global.lang, nil, , true)

		local pveBtnRedPointClickTime = xyd.db.misc:getValue("pveBtnRedPointTime" .. i)

		if not pveBtnRedPointClickTime then
			self["pveBtnRedPoint" .. i]:SetActive(true)
		end

		if pveBtnRedPointClickTime then
			pveBtnRedPointClickTime = tonumber(pveBtnRedPointClickTime)

			if pveBtnRedPointClickTime < self.activityData:startTime() or self.activityData:getEndTime() <= pveBtnRedPointClickTime then
				self["pveBtnRedPoint" .. i]:SetActive(true)
			end
		end
	end

	self.showsBtnIconEffect = xyd.Spine.new(self.showsBtnEffect.gameObject)

	self.showsBtnIconEffect:setInfo("fx_warmup_arena_bubble", function ()
		self.showsBtnIconEffect:setRenderTarget(self.showsBtnEffect, 1)

		if self.activityData:isCanGuess() and xyd.getServerTime() < self.activityData:getEndTime() - xyd.DAY_TIME then
			self.showsBtnIconEffect:play("texiao01", 0)
		else
			self.showsBtnIconEffect:setToSetupPose()
		end
	end)
end

function ActivityEntranceTestWindow:updateEffect()
	if not self.effect then
		self.effect = xyd.Spine.new(self.btnFight.gameObject)
	end

	self.effect:setInfo("fx_ui_dianji", function ()
		self.effect:setRenderTarget(self.btnFight:GetComponent(typeof(UISprite)), 50)
		self.effect:play("texiao01", 0)
	end)
end

function ActivityEntranceTestWindow:initLevelUpTimeGroup()
	self.groupPromotion:SetActive(true)
	self.leftNode:SetActive(false)

	self.groupDetailWidgt.alpha = 0
	local next8Time = xyd.getTomorrowTime()
	local today8Time = next8Time - 86400
	self.timeCount = import("app.components.CountDown").new(self.promotionTimeLabel)

	self.timeCount:setInfo({
		duration = 300 + today8Time - xyd.getServerTime(),
		callback = function ()
			self.needClose_ = true

			xyd.models.activity:reqActivityByID(xyd.ActivityID.ENTRANCE_TEST)
		end
	})
end

function ActivityEntranceTestWindow:onUpdateInfo(event)
	local id = event.data.activity_id

	if id == xyd.ActivityID.ENTRANCE_TEST and self.needClose_ then
		xyd.WindowManager.get():closeWindow(self.name_, function ()
			xyd.openWindow("activity_entrance_test_window")
		end, true)
	end
end

function ActivityEntranceTestWindow:updateTili()
	if self.tiliTimeIndex <= 0 then
		self.tiliNode.visible = false
	end

	self.tiliTimeIndex = self.tiliTimeIndex - 1
end

function ActivityEntranceTestWindow:setTimeShow()
	if self.activityData:getEndTime() < xyd.getServerTime() then
		self.countDownText_label.text = "00:00:00"
		self.endLabel.text = __("END_TEXT")
	else
		local cur_time = self.activityData:getEndTime() - xyd.getServerTime()

		if cur_time > 0 then
			self.countDownText:setInfo({
				duration = cur_time
			})
		else
			self.countDownText_label.text = "00:00:00"
		end

		self.endLabel.text = __("END_TEXT")
	end

	if xyd.Global.lang == "fr_fr" then
		self.endLabel.transform:SetSiblingIndex(0)
		self.countDownText_label.transform:SetSiblingIndex(1)
	end

	self.countDownText_layout:Reposition()
	self:waitForFrame(1, function ()
		if xyd.Global.lang == "zh_tw" then
			self.countDownText_label:Y(-1)
		end
	end)
end

function ActivityEntranceTestWindow:onDayRefresh()
end

function ActivityEntranceTestWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.SYSTEM_REFRESH, self.onDayRefresh, self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, self.onAward, self)

	UIEventListener.Get(self.helpBtn0.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("img_guide_window", {
			totalPage = 3,
			items = {
				self.activityEntranceTestHelpItems.ActivityEntranceTestHelp1,
				self.activityEntranceTestHelpItems.ActivityEntranceTestHelp2,
				self.activityEntranceTestHelpItems.ActivityEntranceTestHelp3
			}
		})
	end)

	UIEventListener.Get(self.rankBtn0).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_entrance_test_new_rank_window", {
			curNavIndex = 1
		})
	end

	UIEventListener.Get(self.missionBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_entrance_test_challenge_task_window", {
			showGiftBag = true
		})
	end

	UIEventListener.Get(self.btnFight.gameObject).onClick = handler(self, function ()
		if self.effect then
			self.effect:stop()
		end

		if not xyd.checkFunctionOpen(xyd.FunctionID.ENTRANCE_TEST, true) then
			local openValue = xyd.tables.functionTable:getOpenValue(xyd.FunctionID.ENTRANCE_TEST)
			local fortId = xyd.tables.stageTable:getFortID(openValue)
			local text = tostring(fortId) .. "-" .. tostring(xyd.tables.stageTable:getName(openValue))

			xyd.alertTips(__("ENTRANCE_TEST_NOT_OPEN", text))

			return
		end

		self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)

		if not self.activityData.hasDefence then
			xyd.alertYesNo(__("NEED_DEFFORMATION"), function (yes_no)
				if yes_no then
					self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)

					self.activityData:sendSettedPartnerReq()

					local params = {
						battleType = xyd.BattleType.ENTRANCE_TEST_DEF,
						formation = self.activityData.detail.partners,
						mapType = xyd.MapType.ENTRANCE_TEST
					}

					xyd.WindowManager.get():openWindow("battle_formation_window", params)
				end
			end)

			return
		end

		local times = self.activityData.detail.free_times

		if times <= 0 then
			xyd.showToast(__("ENTRANCE_TEST_FIGHT_TIP"))

			return
		end

		if self.activityData.matchEnemyList[self.activityData.matchIndex] then
			self:openEnemyWindow()
		else
			local msg = messages_pb:warmup_get_match_infos_req()
			msg.activity_id = xyd.ActivityID.ENTRANCE_TEST

			xyd.Backend.get():request(xyd.mid.WARMUP_GET_MATCH_INFOS, msg)
		end
	end)
	UIEventListener.Get(self.plusBtn.gameObject).onClick = handler(self, function ()
		if not xyd.checkFunctionOpen(xyd.FunctionID.ENTRANCE_TEST, true) then
			local openValue = xyd.tables.functionTable:getOpenValue(xyd.FunctionID.ENTRANCE_TEST)

			xyd.alertTips(__("ENTRANCE_TEST_NOT_OPEN"), openValue)

			return
		end

		local priceArr = xyd.tables.miscTable:split2Cost("activity_warmup_arena_buy_costs", "value", "|#")

		if self.activityData.detail.buy_times and self.activityData.detail.buy_times >= #priceArr then
			xyd.showToast(__("ACTIVITY_WORLD_BOSS_LIMIT"))
		else
			xyd.WindowManager.get():openWindow("activity_entrance_test_buy_tili_window")
		end
	end)
	UIEventListener.Get(self.btnRecord.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_entrance_test_record_window")
	end)
	UIEventListener.Get(self.setHeroBtn.gameObject).onClick = handler(self, function ()
		if not xyd.checkFunctionOpen(xyd.FunctionID.ENTRANCE_TEST, true) then
			xyd.alertYesNo(__("ENTRANCE_TEST_CANNOT_FIGHT"), function (yes_no)
				if yes_no then
					xyd.WindowManager.get():openWindow("activity_entrance_test_slot_window")
					xyd.db.misc:setValue({
						key = "warmup_set_open_time",
						value = xyd.getServerTime()
					})
					self.setHeroRed:SetActive(false)
					self.newTipsNode:SetActive(false)
				end
			end)
		else
			xyd.WindowManager.get():openWindow("activity_entrance_test_slot_window")
			xyd.db.misc:setValue({
				key = "warmup_set_open_time",
				value = xyd.getServerTime()
			})
			self.setHeroRed:SetActive(false)
			self.newTipsNode:SetActive(false)
		end
	end)
	UIEventListener.Get(self.btnFormation.gameObject).onClick = handler(self, function ()
		if not xyd.checkFunctionOpen(xyd.FunctionID.ENTRANCE_TEST, true) then
			local openValue = xyd.tables.functionTable:getOpenValue(xyd.FunctionID.ENTRANCE_TEST)
			local fortId = xyd.tables.stageTable:getFortID(openValue)
			local text = tostring(fortId) .. "-" .. tostring(xyd.tables.stageTable:getName(openValue))

			xyd.alertTips(__("ENTRANCE_TEST_NOT_OPEN", text))

			return
		end

		self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
		local params = {
			battleType = xyd.BattleType.ENTRANCE_TEST_DEF,
			formation = self.activityData.detail.partners,
			mapType = xyd.MapType.ENTRANCE_TEST
		}

		xyd.WindowManager.get():openWindow("battle_formation_window", params)
	end)

	UIEventListener.Get(self.showsBtn).onClick = function ()
		if self.activityData:isCanGuess() then
			if self.showsBtnRed.gameObject.activeSelf then
				self.showsBtnRed:SetActive(false)
				xyd.db.misc:setValue({
					key = "warmup_bet_time_new",
					value = xyd.getServerTime()
				})
			end

			xyd.WindowManager.get():openWindow("activity_entrance_test_show_window", {})
		else
			xyd.alertTips(__("ACTIVITY_NEW_WARMUP_TEXT33"))
		end
	end

	for i = 1, self.activityData:getPveMaxStage() do
		UIEventListener.Get(self["pveBtn" .. i]).onClick = function ()
			xyd.WindowManager.get():openWindow("activity_entrance_test_pve_window", {
				testType = i
			})

			if self["pveBtnRedPoint" .. i].activeSelf then
				xyd.db.misc:setValue({
					key = "pveBtnRedPointTime" .. i,
					value = xyd.getServerTime()
				})
				self["pveBtnRedPoint" .. i]:SetActive(false)
			end
		end
	end

	self.eventProxy_:addEventListener(xyd.event.WARMUP_SET_PARTNER, self.updatePartnersDef, self)
	self.eventProxy_:addEventListener(xyd.event.WARMUP_GET_MATCH_INFOS, self.matchInfos, self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, self.onUpdateInfo, self)
end

function ActivityEntranceTestWindow:updateMissionRed()
	local redState = self.activityData:checkRedMaskOfTask()

	print(redState)
	self.missionBtnRed:SetActive(redState)
end

function ActivityEntranceTestWindow:onAward(event)
	local id = event.data.activity_id

	if id ~= xyd.ActivityID.ENTRANCE_TEST then
		return
	end

	local detail = event.data.detail

	if detail.score then
		self.activityData.detail.score = detail.score
	end

	if detail.rank then
		self.activityData.detail.rank = detail.rank
	end
end

function ActivityEntranceTestWindow:openRankWindow(event)
	self.rankData = event.data

	if self.isEnterRank then
		self.isEnterRank = false

		return
	end

	xyd.WindowManager.get():openWindow("activity_entrance_test_new_rank_window", {
		curNavIndex = 1
	})
end

function ActivityEntranceTestWindow:matchInfos(event)
	if #event.data.match_infos == 0 then
		xyd.showToast(__("ENTRANCE_TEST_NO_ENEMY"))

		return
	end

	local mathdata = xyd.decodeProtoBuf(event.data)
	self.activityData.matchEnemyList = mathdata.match_infos
	self.activityData.matchIndex = 1

	self:openEnemyWindow()
end

function ActivityEntranceTestWindow:openEnemyWindow()
	xyd.WindowManager.get():openWindow("activity_entrance_test_enemy_window", {
		matchInfo = self.activityData.matchEnemyList[self.activityData.matchIndex]
	})
end

function ActivityEntranceTestWindow:updatePartnersDef(event)
	local backData = xyd.decodeProtoBuf(event.data)
	self.activityData.detail.partners = backData.partners
	self.activityData.detail.power = backData.power
	self.activityData.detail.score = backData.score
	self.activityData.detail.rank = backData.rank
	self.activityData.hasDefence = true

	if backData.rank then
		self.rankData.rank = backData.rank
	end
end

function ActivityEntranceTestWindow:battleBack(data)
	if data.score then
		self.activityData.detail.score = data.score
	end

	if data.rank then
		self.activityData.detail.rank = data.rank

		if self.rankData then
			self.rankData.rank = data.rank
		end
	end

	if data.num then
		self.activityData.detail.num = data.num

		if self.rankData then
			self.rankData.num = data.num
		end
	end
end

function ActivityEntranceTestWindow:willClose()
	ActivityEntranceTestWindow.super.willClose(self)

	if self.timeCount then
		self.timeCount:stopTimeCount()
	end
end

return ActivityEntranceTestWindow
