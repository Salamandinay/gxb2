local ActionImg = class("ActionImg")

function ActionImg:ctor(go, params)
	self.go = go
	self.startPos = {
		x = 0,
		y = 0
	}
	self.endPos = {
		x = 0,
		y = 0
	}
	self.controlPos = {
		x = 0,
		y = 0
	}

	if params then
		self:setData(params)
	end
end

function ActionImg:setData(params)
	self.startPos = params.startPos
	self.endPos = params.endPos
	self.controlPos = params.controlPos
end

function ActionImg:setFactor(value)
	local startPos = self.startPos
	local endPos = self.endPos
	local controlPos = self.controlPos
	self.go.transform.position.x = xyd.fixNum((1 - value) * (1 - value) * startPos.x + 2 * value * (1 - value) * controlPos.x + value * value * endPos.x)
	self.go.transform.position.y = xyd.fixNum((1 - value) * (1 - value) * startPos.y + 2 * value * (1 - value) * controlPos.y + value * value * endPos.y)
end

function ActionImg:getFactor()
	return 0
end

function ActionImg:setOriginalPos()
	self.go:SetLocalPosition(self.startPos.x, self.startPos.y, 0)
end

local StageItem = class("StageItem", import("app.components.CopyComponent"))

function StageItem:ctor(goItem, tableID, maxStageId, currentStageId, isFirst, isLast)
	self.goItem_ = goItem
	self.stageId = tableID
	self.maxStageId = maxStageId
	self.currentStageId = currentStageId
	self.id_ = (tonumber(self.stageId) + 1) % 2 + 1
	self.hideId_ = tonumber(self.stageId) % 2 + 1
	self.isLast_ = isLast

	StageItem.super.ctor(self, goItem)
end

function StageItem:initUI()
	local transGo = self.go.transform
	self.sGroup1 = transGo:Find("s_group1")
	self.sGroup2 = transGo:Find("s_group2")

	self["sGroup" .. self.id_]:SetActive(true)
	self["sGroup" .. self.hideId_]:SetActive(false)

	self.sGroup = self["sGroup" .. self.id_]
	self.nameLabel = self.sGroup:ComponentByName("name_label", typeof(UILabel))
	self.routeImg = self.sGroup:ComponentByName("route_img", typeof(UISprite))
	self.imgGroup = self.sGroup:Find("img_group")
	self.stageImg = self.imgGroup:ComponentByName("stage_img", typeof(UISprite))
	self.stageFrame2 = self.imgGroup:ComponentByName("stage_frame2", typeof(UISprite))
	self.stageFrame1 = self.imgGroup:ComponentByName("stage_frame1", typeof(UISprite))
	self.maskImg = self.imgGroup:ComponentByName("mask_img", typeof(UISprite))
	self.effectImg = self.sGroup:ComponentByName("effectImg", typeof(UITexture))
	self.funcImg = self.sGroup:ComponentByName("funcImg", typeof(UISprite))

	if xyd.isIosTest() then
		xyd.iosSetUISprite(self.stageFrame1, "battle_bg_sectionsBox_ios_test")
		xyd.iosSetUISprite(self.stageFrame2, "battle_bg_selected_ios_test")
	end

	self.maskImg:SetActive(false)
	self:initItem()
end

function StageItem:initItem()
	if self.isLast_ then
		self.routeImg:SetActive(false)
	end

	local stageImg = xyd.tables.stageTable:getStageImg(self.stageId)

	xyd.setUISpriteAsync(self.stageImg, nil, stageImg)
	self.funcImg:SetActive(false)

	local func = xyd.tables.stageTable:getFunctionID(self.stageId)
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.REDEEM_CODE)

	if func and func ~= 0 and not self:checkStatus2() then
		self.funcImg:SetActive(true)
		xyd.setUISprite(self.funcImg, nil, xyd.tables.functionTable:getIcon(func) .. "_small")
		self.funcImg:MakePixelPerfect()
	end

	if self.stageId == xyd.tables.miscTable:getNumber("cdkey_gxb222_stage_id", "value") and not self:checkStatus2() and activityData and not activityData:isHide() and activityData:isOpen() then
		self.funcImg:SetActive(true)
		xyd.setUISprite(self.funcImg, nil, xyd.tables.miscTable:getString("cdkey_gxb222_icon", "value") .. "_small")
		self.funcImg:MakePixelPerfect()
	end

	local fortId = xyd.tables.stageTable:getFortID(self.stageId)
	self.nameLabel.text = tostring(fortId) .. "-" .. tostring(xyd.tables.stageTable:getName(self.stageId))
	UIEventListener.Get(self.sGroup.gameObject).onClick = handler(self, self.onClickStageItem)
	UIEventListener.Get(self.funcImg.gameObject).onClick = handler(self, function ()
		xyd.openWindow("campaign_func_alert_window", {
			stageId = self.stageId
		})
	end)

	if self:checkStatus() then
		self:unlock()

		if self.maxStageId < tonumber(self.stageId) + 1 then
			-- Nothing
		end
	else
		self:lock()
	end
end

function StageItem:onClickStageItem()
	if self.stageId == self.currentStageId then
		xyd.openWindow("campaign_stage_detail_window", {
			alpha = 0.7,
			no_close = true,
			needBtn_ = false,
			stageId = self.stageId
		})
	elseif not self:checkStatus() then
		xyd.openWindow("campaign_alert_window", {
			alpha = 0.1,
			stageId = tonumber(self.stageId)
		})
	else
		xyd.openWindow("campaign_stage_detail_window", {
			alpha = 0.7,
			no_close = true,
			needBtn_ = true,
			stageId = self.stageId
		})
	end
end

function StageItem:checkStatus()
	local lv = xyd.tables.stageTable:getLv(self.stageId)
	local playerLv = xyd.models.backpack:getLev()
	local power = xyd.tables.stageTable:getPower(self.stageId)
	local teamPower = xyd.models.map:getTeamPower()
	local res = true

	if playerLv < lv then
		res = false
	end

	if tonumber(self.maxStageId) < tonumber(self.stageId) then
		res = false
	end

	return res
end

function StageItem:checkStatus2()
	local lv = xyd.tables.stageTable:getLv(self.stageId)
	local playerLv = xyd.models.backpack:getLev()
	local power = xyd.tables.stageTable:getPower(self.stageId)
	local teamPower = xyd.models.map:getTeamPower()
	local res = true

	if playerLv < lv then
		res = false
	end

	if tonumber(self.maxStageId) <= tonumber(self.stageId) then
		res = false
	end

	return res
end

function StageItem:getCheckStatus()
	return self:checkStatus()
end

function StageItem:unlock()
	self.maskImg:SetActive(false)

	self.isLocked = false
end

function StageItem:lock()
	self.maskImg:SetActive(true)

	self.isLocked = true
end

function StageItem:setFightStates(current)
	if current then
		self.stageFrame2:SetActive(true)
	else
		self.stageFrame2:SetActive(false)
	end
end

function StageItem:addFightEffect()
	if not self.fightEffect then
		self.fightEffect = xyd.Spine.new(self.effectImg.gameObject)

		self.fightEffect:setInfo("fx_adv_stage_now", function ()
			self.fightEffect:SetLocalPosition(0, 0, 0)
			self.fightEffect:SetLocalScale(1, 1, 1)
			self.fightEffect:play("texiao01", -1)
		end)
	end
end

function StageItem:addReadyEffect(callback)
	if not self:checkStatus() then
		return
	end

	if not self.readyEffect1 then
		self.readyEffect1 = xyd.Spine.new(self.effectImg.gameObject)

		self.readyEffect1:setInfo("fx_adv_unlock", function ()
			self.readyEffect1:SetLocalPosition(0, 0, 0)
			self.readyEffect1:SetLocalScale(1, 1, 1)
			self.readyEffect1:play("texiao01", 1, 1, function ()
				if callback and not xyd.GuideController.get():isPlayGuide() then
					callback()
				end
			end)
		end)
	end
end

function StageItem:playItemAnimation(playType)
	self.imgGroup:GetComponent(typeof(UIWidget)).alpha = 0.01
	self.nameLabel.alpha = 0.01
	self.routeImg.alpha = 0.01

	self:waitForTime(0.1 * playType, function ()
		local sequence1 = self:getSequence()

		local function setter1(value)
			self.imgGroup:GetComponent(typeof(UIWidget)).alpha = value
		end

		sequence1:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0.01, 1, 0.1):SetEase(DG.Tweening.Ease.Linear))
		sequence1:Append(self.imgGroup:DOScale(Vector3(1.05, 1.05, 1.05), 0.1))
		sequence1:Append(self.imgGroup:DOScale(Vector3(1, 1, 1), 0.13))
		sequence1:AppendCallback(function ()
			sequence1:Kill(false)

			sequence1 = nil
		end)
		self:waitForTime(0.1, function ()
			local function setter2(value)
				self.nameLabel.alpha = value
			end

			local function setter3(value)
				self.routeImg.alpha = value
			end

			local sequence2 = self:getSequence()

			sequence2:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0.01, 1, 0.1))
			sequence2:Join(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), 0.01, 1, 0.1))
		end, nil)
	end, nil)
end

local CampaignWindow = class("CampaignWindow", import(".BaseWindow"))
local SpineManager = xyd.SpineManager
local EffectConstants = xyd.EffectConstants
local math = math
local BattleHangUp = import("app.components.BattleHangUp")
local WindowTop = import("app.components.WindowTop")
local json = require("cjson")

function CampaignWindow:ctor(name, params)
	CampaignWindow.super.ctor(self, name, params)

	self.callback = nil
	xyd.models.map = xyd.models.map
	xyd.tables.stageTable = xyd.tables.stageTable
	self.slotModel = xyd.models.slot
	self.stageList = {}
	self.isFirst = false
	self.hangGold = 0
	self.hangPartnerExp = 0
	self.hangExp = 0
	self.remainGold = 0
	self.remainPartnerExp = 0
	self.remainExp = 0
	self.allGold = 0
	self.allPartnerExp = 0
	self.allExp = 0
	self.isCanFight = false
	self.noDelay = false
	self.hasAddEffect11 = false
	self.divideTime = 0
	self.isPlayGoldEffect = false
	self.goldEffectClicked = false
	self.inGoldEffectStep = false
	self.isFirstGoldTouch = true
	self.actionList = {}
	self.layerBattleHangUp = nil
	self.preStage = nil
	self.goldEffectName = {
		{
			"num_3_state_down",
			"num_3_change",
			"num_3_state_up"
		},
		{
			"num_2_state_down",
			"num_2_change",
			"num_2_state_up"
		},
		{
			"num_1_state_down",
			"num_1_change",
			"num_2_state_up"
		}
	}

	if params and params.listener ~= nil then
		self.callback = params.listener
	end

	if params then
		self.is_win = params.is_win
	end

	if params then
		self.noDelay = params.noDelay
	end
end

function CampaignWindow:initWindow()
	CampaignWindow.super.initWindow()

	local winTrans = self.window_.transform
	self.bg = winTrans:ComponentByName("campaign_bg", typeof(UITexture))
	self.minBg = winTrans:ComponentByName("campaign_min_bg", typeof(UISprite))
	self.hangGroup = winTrans:Find("hang_group")
	self.titleLabel = self.hangGroup:ComponentByName("title_label", typeof(UILabel))
	self.hangMapGroup = self.hangGroup:Find("hang_map_group")
	self.hangupGroup = self.hangGroup:Find("hangup_group")
	self.campaignAwardBtn = self.hangGroup:NodeByName("campaign_award_btn").gameObject
	self.campaignAwardBtnRedPoint = self.campaignAwardBtn:NodeByName("redPoint").gameObject
	self.campaignAwardBtnEffectNode = self.campaignAwardBtn:NodeByName("effectNode").gameObject
	self.campaignAwardBtnLabel = self.campaignAwardBtn:ComponentByName("label", typeof(UILabel))
	self.showAwardCon = self.campaignAwardBtn:NodeByName("showAwardCon").gameObject
	self.showAwardBg = self.showAwardCon:ComponentByName("showAwardBg", typeof(UISprite))
	self.iconCon1 = self.showAwardCon:NodeByName("iconCon1").gameObject
	self.iconCon2 = self.showAwardCon:NodeByName("iconCon2").gameObject
	self.mapGroup = winTrans:Find("map_panel/map_group")
	self.goldEffectDownGroup = self.mapGroup:Find("gold_effect_down_group")
	self.goldEffectUpGroup = self.mapGroup:Find("gold_effect_up_group")
	self.listBg = self.mapGroup:ComponentByName("stage_list_bg", typeof(UITexture))
	self.listMinBg = self.mapGroup:ComponentByName("stage_list_min_bg", typeof(UISprite))
	self.dragScrollView = self.mapGroup:ComponentByName("drag", typeof(UIDragScrollView))
	self.stageScroller = self.mapGroup:ComponentByName("stage_scroller", typeof(UIScrollView))
	self.stageListGrid = self.mapGroup:ComponentByName("stage_scroller/stage_list_grid", typeof(UIGrid))
	self.stageItem = self.mapGroup:Find("stage_item")

	self.stageItem:SetActive(false)

	self.hangTopGroup = self.mapGroup:Find("hang_top_group")
	self.helpBtn = self.hangTopGroup:Find("help_btn").gameObject
	self.rankBtn = self.hangTopGroup:Find("rank_btn").gameObject
	self.coinMaskImg = self.hangGroup:Find("coin_mask_img")
	self.getHangResBtn = self.hangTopGroup:Find("get_hang_res_btn").gameObject
	self.getHangLabel = self.getHangResBtn:ComponentByName("get_hang_label", typeof(UILabel))
	self.hangTweenGroup = self.hangTopGroup:Find("hang_tween_group")
	self.resGroup = self.hangTweenGroup:Find("res_group")
	self.resGoldGroup = self.resGroup:Find("res_gold_group")
	self.resPexpGroup = self.resGroup:Find("res_pexp_group")
	self.resExpGroup = self.resGroup:Find("res_exp_group")
	self.labelHangGold = self.resGoldGroup:ComponentByName("label_hang_gold", typeof(UILabel))
	self.lableHangPexp = self.resPexpGroup:ComponentByName("lable_hang_pexp", typeof(UILabel))
	self.labelHangExp = self.resExpGroup:ComponentByName("label_hang_exp", typeof(UILabel))
	self.resGoldImg = self.resGoldGroup:Find("res_gold_img")
	self.resGoldImgO = self.resGoldGroup:Find("res_gold_img_o")
	self.resPexpImg = self.resPexpGroup:Find("res_pexp_img")
	self.resPexpImgO = self.resPexpGroup:Find("res_pexp_img_o")
	self.resExpImg = self.resExpGroup:Find("res_exp_img")
	self.hangBottomGroup = self.mapGroup:Find("hang_bottom_group")
	self.fightEndGroup = self.hangBottomGroup:Find("fight_end_group")
	self.fightEndLabel = self.fightEndGroup:ComponentByName("fight_end_label", typeof(UILabel))
	self.mapDetailBtn = self.hangBottomGroup:Find("map_detail_btn").gameObject
	self.hangRewardBtn = self.hangBottomGroup:Find("hang_reward_btn").gameObject
	self.fightBtn = self.hangBottomGroup:Find("fight_btn").gameObject
	self.fightBtnLabel = self.fightBtn:ComponentByName("fight_btn_label", typeof(UILabel))
	self.mapAlertImg = self.mapDetailBtn.transform:Find("map_alert_img")
	self.hangRewardAlertImg = self.hangRewardBtn.transform:Find("hang_reward_alert_img")
	self.mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)

	self:setSmallBg()
	self:refresh()
	self:initWindowTop()
	self:register()
	self:addGoldEffect()
	xyd.models.map:getMapHangItemsInfo()

	self.refreshDataTimer = Timer.New(handler(self, function ()
		xyd.models.map:getMapHangItemsInfo()
	end), 300, -1, false)

	self.refreshDataTimer:Start()

	self.refreshHangResTimer = Timer.New(handler(self, self.calculateHangRes), 5, -1, false)

	self.refreshHangResTimer:Start()
	self:checkCampaignError()

	if self.mapInfo and self.mapInfo.current_stage == 0 then
		xyd.models.map:hang(1)
	end

	self:checkCampaignRedState()
end

function CampaignWindow:checkCampaignRedState()
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.CAMPAIGN_ACHIEVEMENT, self.campaignAwardBtnRedPoint)

	local state = xyd.models.achievement:updateRedPointCampaign()

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
		self.campaignAwardBtnLabel.fontSize = 17
	end

	local effectAct = "texiao02"

	if state then
		self.campaignAwardBtnLabel.text = __("STAGE_ACHIEVEMENT_ENTRANCE_TEXT02")
	else
		local maxStage = self.mapInfo.max_stage or 0
		local maxTableID = xyd.tables.stageTable:getMaxID()
		local fort_id = xyd.tables.stageTable:getFortID(maxStage) or 1
		local fort_id2 = xyd.tables.stageTable:getFortID(maxStage + 1)

		if maxTableID <= fort_id2 then
			fort_id2 = maxTableID
		end

		if fort_id <= fort_id2 then
			fort_id = fort_id2
		end

		local stageList = xyd.tables.stageTable:getStageListByFortId(fort_id)
		local nextStage = 0

		for _, id in ipairs(stageList) do
			if xyd.tables.stageTable:getFortFinal(id) >= 1 then
				nextStage = tonumber(id)

				break
			end
		end

		if nextStage > 0 then
			self.campaignAwardBtnLabel.text = __("STAGE_ACHIEVEMENT_ENTRANCE_TEXT01", nextStage - tonumber(maxStage))
		end

		effectAct = "texiao01"
	end

	local showAwardId = xyd.models.achievement:getAchievementCampaignData().achieve_id

	if showAwardId and showAwardId ~= 0 then
		self.showAwardCon.gameObject:SetActive(true)

		local showAwards = xyd.tables.achievementTable:getAward2(showAwardId)

		NGUITools.DestroyChildren(self.iconCon1.transform)
		NGUITools.DestroyChildren(self.iconCon2.transform)

		if showAwards and #showAwards > 0 then
			local awardIcon1 = nil

			if showAwards[1] then
				local params = {
					show_has_num = false,
					itemID = showAwards[1][1],
					scale = Vector3(0.3, 0.3, 1),
					uiRoot = self.iconCon1.gameObject
				}
				awardIcon1 = xyd.getItemIcon(params)
				awardIcon1:getGameObject():GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

				self.iconCon1.gameObject:Y(7.5)
			end

			if showAwards[2] then
				local params = {
					show_has_num = false,
					itemID = showAwards[2][1],
					scale = Vector3(0.3, 0.3, 1),
					uiRoot = self.iconCon2.gameObject
				}
				local awardIcon2 = xyd.getItemIcon(params)
				awardIcon2:getGameObject():GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

				self.iconCon1.gameObject:SetLocalPosition(-11.6, 7.1, 0)

				self.iconCon1.transform.localEulerAngles = Vector3(0, 0, 12)

				self.iconCon2.gameObject:SetLocalPosition(10.2, 8.1, 0)

				self.iconCon2.transform.localEulerAngles = Vector3(0, 0, -5.2)
			end
		end
	else
		self.showAwardCon.gameObject:SetActive(false)
	end

	if not xyd.models.achievement:getAchievementCampaignData().achieve_id or xyd.models.achievement:getAchievementCampaignData().achieve_id == 0 then
		self.campaignAwardBtn:SetActive(false)
	else
		self.campaignAwardBtn:SetActive(true)
	end

	if not self.campaignAwardEffect then
		self.campaignAwardEffect = xyd.Spine.new(self.campaignAwardBtn)

		self.campaignAwardEffect:setInfo("fx_icon_main_achievement", function ()
			self.campaignAwardEffect:play(effectAct, 0, 1)
		end)
	else
		self.campaignAwardEffect:play(effectAct, 0, 1)
	end
end

function CampaignWindow:setSmallBg()
	local tmpStage = self.mapInfo.current_stage

	if tmpStage <= 0 then
		tmpStage = 1
	end

	local setMap = xyd.tables.stageTable:getSetMap(tmpStage)

	xyd.setUISprite(self.minBg, xyd.Atlas.CAMPAIGIN, tostring(setMap) .. "_small")
end

function CampaignWindow:refreshData()
	self.mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
	local economy_items = self.mapInfo.economy_items

	for _, item_info in pairs(economy_items) do
		if tonumber(item_info.item_id) == xyd.ItemID.MANA then
			self.hangGold = tonumber(item_info.item_num) or 0
		elseif tonumber(item_info.item_id) == xyd.ItemID.PARTNER_EXP then
			self.hangPartnerExp = tonumber(item_info.item_num) or 0
		elseif tonumber(item_info.item_id) == xyd.ItemID.EXP then
			self.hangExp = tonumber(item_info.item_num) or 0
		end
	end

	self:updateAllRes()
	self:updateResLabel()
end

function CampaignWindow:enableGetResBtn(flag)
	local btnCollider = self.getHangResBtn:GetComponent(typeof(UnityEngine.BoxCollider))

	if flag then
		btnCollider.enabled = true

		if not self.resBtnSeq then
			self:initResSeq()
		end
	else
		btnCollider.enabled = false

		if self.resBtnSeq then
			self.resBtnSeq:Kill(false)

			self.resBtnSeq = nil
		end
	end
end

function CampaignWindow:refresh(event, lvChange)
	if lvChange == nil then
		lvChange = false
	end

	local evt = event

	self:refreshData()

	local top, bottom, changeMap = nil
	local firstTime = false

	if not event then
		firstTime = true
	end

	changeMap = not event or xyd.tables.stageTable:getFortID(event.data.current_stage) ~= xyd.tables.stageTable:getFortID(self.currentStage)

	if event == nil then
		top = true
		bottom = true
	elseif changeMap then
		top = false
		bottom = true
	else
		top = false
		bottom = false
	end

	self.currentStage = self.mapInfo.current_stage

	if self.currentStage <= 0 then
		self.currentStage = 1
	end

	self.hangTime = self.mapInfo.hang_time
	self.maxStage = self.mapInfo.max_stage
	self.firstHangTime = self.mapInfo.first_hang_time
	self.maxHangStage = self.mapInfo.max_hang_stage
	self.hangTeam = self.mapInfo.hang_team
	local tmpCurrentStage = self.currentStage

	if tmpCurrentStage <= 0 then
		tmpCurrentStage = 1
	end

	self.fortId = xyd.tables.stageTable:getFortID(tmpCurrentStage)
	self.stageList = xyd.tables.stageTable:getStageListByFortId(self.fortId)

	self:initTopGroup()
	self:initHangStatus()
	self:initBg()
	xyd.setUITextureAsync(self.listBg, "Textures/scenes_web/campaign_select_bg", handler(self, function ()
		self.listMinBg:SetActive(false)
	end), true)

	if self.noDelay then
		self:initStageList(firstTime, lvChange)
		self:playAnimation(top, bottom)
		self:initBattle(false)

		self.isWndComplete_ = true
	else
		self.isWndComplete_ = false

		XYDCo.WaitForTime(0.6, handler(self, function ()
			if self.window_ then
				self:initBattle(false)
			end
		end), nil)
		self:initStageList(firstTime, lvChange)
		self:playAnimation(top, bottom)
		XYDCo.WaitForFrame(2, handler(self, function ()
			if self.window_ then
				self.isWndComplete_ = true
			end
		end), nil)
	end
end

function CampaignWindow:updateAllRes()
	self.allGold = math.floor(self.hangGold + self.remainGold)
	self.allExp = math.floor(self.hangExp + self.remainExp)
	self.allPartnerExp = math.floor(self.hangPartnerExp + self.remainPartnerExp)
end

function CampaignWindow:updateResLabel()
	self.labelHangGold.text = tostring(xyd.getRoughDisplayNumber(self.allGold))
	self.lableHangPexp.text = tostring(xyd.getRoughDisplayNumber(self.allPartnerExp))
	self.labelHangExp.text = tostring(xyd.getRoughDisplayNumber(self.allExp))
end

function CampaignWindow:playAnimation(top, bottom)
	local btnGroups1 = {
		self.helpBtn.transform,
		self.rankBtn.transform,
		self.getHangResBtn.transform
	}
	local btnGroups2 = {
		self.fightBtn.transform,
		self.mapDetailBtn.transform,
		self.hangRewardBtn.transform
	}

	if not self.fightBtn.activeSelf then
		btnGroups2[1] = self.fightEndGroup
	end

	if self.currentStage <= 3 then
		return
	end

	if top then
		for i = 1, 3 do
			btnGroups1[i]:GetComponent(typeof(UIWidget)).alpha = 0.01
			btnGroups2[i]:GetComponent(typeof(UIWidget)).alpha = 0.01
		end

		local sequence1 = self:getSequence()

		local function resGroupSetter(value)
			self.resGroup:GetComponent(typeof(UIWidget)).alpha = value
		end

		sequence1:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(resGroupSetter), 0.01, 1, 0.3):SetEase(DG.Tweening.Ease.Linear))
		sequence1:AppendCallback(handler(self, function ()
			sequence1:Kill(false)

			sequence1 = nil
		end))

		for i = 1, 3 do
			local btn1 = btnGroups1[i]
			local btn2 = btnGroups2[i]

			local function btn1Setter(value)
				btn1:GetComponent(typeof(UIWidget)).alpha = value
			end

			local function btn2Setter(value)
				btn2:GetComponent(typeof(UIWidget)).alpha = value
			end

			local sequence2 = self:getSequence()
			local sequence3 = self:getSequence()

			sequence2:Insert(0.1 * (i - 1) + 0.1, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(btn1Setter), 0.01, 1, 0.1):SetEase(DG.Tweening.Ease.Linear))
			sequence2:Insert(0.1 * (i - 1) + 0.2, btn1:DOScale(Vector3(1.05, 1.05, 1.05), 0.1))
			sequence2:Insert(0.1 * (i - 1) + 0.3, btn1:DOScale(Vector3(1, 1, 1), 0.13))
			sequence2:AppendCallback(handler(self, function ()
				sequence2:Kill(false)

				sequence2 = nil
			end))
			sequence3:Insert(0.1 * (i - 1) + 0.1, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(btn2Setter), 0.01, 1, 0.1):SetEase(DG.Tweening.Ease.Linear))
			sequence3:Insert(0.1 * (i - 1) + 0.2, btn2:DOScale(Vector3(1.05, 1.05, 1.05), 0.1))
			sequence3:Insert(0.1 * (i - 1) + 0.3, btn2:DOScale(Vector3(1, 1, 1), 0.13))
			sequence3:AppendCallback(handler(self, function ()
				sequence3:Kill(false)

				sequence3 = nil
			end))
		end
	end

	if bottom then
		self:bottomAnimation()
	end
end

function CampaignWindow:bottomAnimation()
	local pos = xyd.tables.stageTable:getName(self.currentStage)
	local stageItem = self.stageItemList[pos]

	stageItem:playItemAnimation(0)

	for i = 1, math.max(pos, #self.stageList - pos) do
		if pos + i < #self.stageList then
			stageItem = self.stageItemList[pos + i]

			stageItem:playItemAnimation(i)
		end

		if pos - i > 0 then
			stageItem = self.stageItemList[pos - i]

			stageItem:playItemAnimation(i)
		end
	end
end

function CampaignWindow:playOpenAnimation(callback)
	callback()
end

function CampaignWindow:register()
	CampaignWindow.super.register(self)

	UIEventListener.Get(self.rankBtn).onClick = handler(self, function ()
		self:onClickMapRankBtn()
	end)
	UIEventListener.Get(self.mapDetailBtn).onClick = handler(self, function ()
		self:onClickMapBtn()
	end)
	UIEventListener.Get(self.getHangResBtn).onClick = handler(self, function ()
		self:stopResSeq()
		self:onClickgetHangResBtn()
	end)
	UIEventListener.Get(self.hangRewardBtn).onClick = handler(self, function ()
		self:onClickgetHangRewardBtn()
	end)
	UIEventListener.Get(self.hangupGroup.gameObject).onClick = handler(self, function ()
		self:onClickHangTeamBtn()
	end)
	UIEventListener.Get(self.fightBtn).onClick = handler(self, function ()
		self:onClickFightBtn()
	end)

	UIEventListener.Get(self.campaignAwardBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("campaign_award_window", {})
	end

	self.eventProxy_:addEventListener(xyd.event.STAGE_HANG, handler(self, self.refresh))
	self.eventProxy_:addEventListener(xyd.event.GET_MAP_INFO, handler(self, self.refresh))
	self.eventProxy_:addEventListener(xyd.event.GET_MAP_HANG_ITEMS_INFO, handler(self, self.refreshHangItems))
	self.eventProxy_:addEventListener(xyd.event.GET_HANG_ITEM, handler(self, self.refreshHangRes))
	self.eventProxy_:addEventListener(xyd.event.SET_HANG_TEAM, handler(self, self.refreshHangTeam))
	self.eventProxy_:addEventListener(xyd.event.LEV_CHANGE, function (event)
		XYDCo.WaitForTime(1.4, function ()
			self:refresh(event, true)
		end, nil)
	end)
end

function CampaignWindow:initBg()
	local stageId = 1

	if self.currentStage > 0 then
		stageId = self.currentStage
		local str = tostring(xyd.tables.stageTextTable:getFortId(self.currentStage)) .. "-" .. tostring(xyd.tables.stageTable:getName(self.currentStage))
		self.titleLabel.text = tostring(str) .. tostring(xyd.tables.stageTextTable:getName(self.currentStage))
	end

	local setMap = xyd.tables.stageTable:getSetMap(stageId)

	xyd.setUITextureByNameAsync(self.bg, setMap, false, handler(self, function ()
		self.minBg:SetActive(false)
	end), true)
end

function CampaignWindow:getBestThreeHero()
	local powerSortedHeros = {}
	local allHeros = xyd.models.slot:getSortedPartners()["0_0"]
	local num = math.min(#allHeros, 3)

	for i = 1, #allHeros do
		table.insert(powerSortedHeros, {
			id = allHeros[i],
			power = xyd.models.slot:getPartner(allHeros[i]):getPower()
		})
	end

	table.sort(powerSortedHeros, function (a, b)
		return a.power < b.power
	end)

	local returnValue = {}

	for i = 1, num do
		table.insert(returnValue, {
			partner_id = powerSortedHeros[i].id,
			pos = i
		})
	end

	return returnValue
end

function CampaignWindow:initBattle(refresh)
	if self.fightBtn.activeSelf and self.currentStage == 1 then
		return
	end

	local monsterShow = xyd.split(xyd.tables.stageTable:getMonsterShow(self.currentStage), "|")
	local monsterSkinIDs = xyd.tables.stageTable:getMonsterSkin(self.currentStage)
	local monsterIDs = {}

	for _, mId in ipairs(monsterShow) do
		table.insert(monsterIDs, tonumber(mId))
	end

	local hangPartnerList = self.mapInfo.hang_team or {}

	if #hangPartnerList == 0 then
		hangPartnerList = self:getBestThreeHero()
	else
		table.sort(hangPartnerList, function (a, b)
			return a.pos < b.pos
		end)
	end

	local tableIDs = {}
	local skinIDs = {}
	local poses = {}

	for i = 1, #hangPartnerList do
		local pId = hangPartnerList[i].partner_id
		local pos = hangPartnerList[i].pos
		local partner = self.slotModel:getPartner(tonumber(pId))

		if partner then
			local tableID = partner:getTableID()

			table.insert(tableIDs, tonumber(tableID))

			local skinID = partner.skin_id

			table.insert(skinIDs, skinID)
			table.insert(poses, pos)
		end
	end

	local battleParams = {
		tableIDs = tableIDs,
		skinIDs = skinIDs,
		monsterIDs = monsterIDs,
		monsterSkinIDs = monsterSkinIDs,
		positions = poses
	}

	if self.layerBattleHangUp and refresh == false then
		local params = {
			ifUpdate = true,
			tableIDs = self.layerBattleHangUp.herosA,
			skinIDs = self.layerBattleHangUp.selectSkinIDs,
			monsterIDs = monsterIDs,
			monsterSkinIDs = monsterSkinIDs,
			positions = poses
		}
		self.layerBattleHangUp.data_ = params

		return
	elseif self.layerBattleHangUp and refresh == true then
		self.layerBattleHangUp:clearAction()
		NGUITools.DestroyChildren(self.hangMapGroup)
	end

	self.layerBattleHangUp = BattleHangUp.new(self.hangMapGroup.gameObject, battleParams)

	self.layerBattleHangUp:startBattle()

	if self.fightBtn.activeSelf and self.currentStage == 1 then
		self.layerBattleHangUp.go:SetActive(false)
	end
end

function CampaignWindow:initHangStatus()
	self.fightBtnLabel.text = __("FIGHT_EVENT")
	local drop_items = self.mapInfo.drop_items

	if #drop_items > 0 then
		self.hangRewardAlertImg:SetActive(true)
	else
		self.hangRewardAlertImg:SetActive(false)
	end

	local serverTime = xyd.getServerTime()

	if self.maxStage < self.currentStage then
		local battleTime = xyd.tables.stageTable:getBattleTime(self.currentStage)
		local leftTime = battleTime - (serverTime - self.firstHangTime)

		if leftTime <= 0 then
			self:setHangBtnBattle(true)
		else
			self:startProgress(battleTime, leftTime, true)
		end
	elseif self.currentStage > 0 then
		self:setHangBtnHanged()
	else
		self:setHangBtnBattleFirst()
	end
end

function CampaignWindow:startProgress(totalTime, leftTime, firstTime)
	if firstTime == nil then
		firstTime = false
	end

	self.fightEndGroup:SetActive(false)

	if self.currentStage == 1 and self.layerBattleHangUp then
		self.layerBattleHangUp.go:SetActive(false)
	end

	self:setHangBtnBattle(firstTime)
end

function CampaignWindow:playMidBtnAnimation(firstTime)
	if not firstTime or firstTime == nil then
		self.fightEndGroup:SetActive(false)
		self.fightBtn:SetActive(true)

		return
	end

	local tween = self.fightEndGroup:DOScale(Vector3(0.5, 0.5, 0.5), 0.1)

	tween:OnComplete(handler(self, function ()
		self.fightEndGroup:SetActive(false)

		self.fightEndGroup.localScale = Vector3.one

		self.fightBtn:SetActive(true)
	end))

	local sequence = self:getSequence()

	sequence:Append(tween)
	sequence:Append(self.fightBtn.transform:DOScale(Vector3(1.05, 1.05, 1.05), 0.13))
	sequence:Append(self.fightBtn.transform:DOScale(Vector3(1, 1, 1), 0.2))
	sequence:AppendCallback(function ()
		self.fightEndGroup:SetActive(false)

		self.fightEndGroup.localScale = Vector3.one

		sequence:Kill(false)

		sequence = nil
	end)
end

function CampaignWindow:setHangBtnBattle(firstTime)
	if firstTime == nil then
		firstTime = false
	end

	if self.currentStage ~= self.maxStage + 1 then
		return
	end

	self:playMidBtnAnimation(firstTime)

	if self.layerBattleHangUp and self.currentStage == 1 then
		self.layerBattleHangUp.go:SetActive(false)
	end

	self.isCanFight = true

	if not xyd.isIosTest() and not self.campaignEffect2 then
		self.campaignEffect2 = xyd.Spine.new(self.fightBtn)

		self.campaignEffect2:setInfo("fx_adv_battle_btn", function ()
			self.campaignEffect2:SetLocalPosition(0, 0, 0)
			self.campaignEffect2:SetLocalScale(1, 1, 1)
			self.campaignEffect2:setRenderTarget(self.fightBtn:GetComponent(typeof(UISprite)), 1)
			self.campaignEffect2:play("txiao01", -1)
		end)
	end
end

function CampaignWindow:setHangBtnBattleFirst()
	self.fightBtn:SetActive(false)

	if self.layerBattleHangUp then
		self.layerBattleHangUp.go:SetActive(true)
	end

	self.fightEndGroup:SetActive(true)
	self.fightEndLabel:SetActive(false)

	self.isCanFight = true
end

function CampaignWindow:onClickFightBtn()
	local fightParams = {
		forceConfirm = 1,
		alpha = 0.7,
		no_close = true,
		mapType = xyd.MapType.CAMPAIGN,
		battleType = xyd.BattleType.CAMPAIGN,
		stageId = self.currentStage
	}

	xyd.openWindow("battle_formation_window", fightParams)

	self.preStage = self.currentStage
end

function CampaignWindow:setHangBtnHanged()
	if self.currentStage <= 0 then
		self.fightEndLabel:SetActive(false)
	else
		self.fightEndLabel:SetActive(true)
	end

	self.fightEndLabel.text = __("STAGE_FIGHTED")

	self.fightBtn:SetActive(false)

	if self.layerBattleHangUp then
		self.layerBattleHangUp.go:SetActive(true)
	end

	self.fightEndGroup:SetActive(true)
end

function CampaignWindow:setHangBtnHanging()
end

function CampaignWindow:calculateHangRes()
	if not self.currentStage or self.currentStage <= 0 then
		return
	end

	local vip = xyd.models.backpack:getVipLev() or 0
	local vipOutPutExtra = xyd.tables.vipTable:extraOutput(vip)
	local weekCardGoldExtra = 0
	local weekCardPExpExtra = 0
	local weekCardGoldExtra = xyd.checkCondition(xyd.models.activity:isManaCardPurchased(), xyd.tables.miscTable:getNumber("subscription_rate_gold", "value"), 0)
	local weekCardPExpExtra = xyd.checkCondition(xyd.models.activity:isManaCardPurchased(), xyd.tables.miscTable:getNumber("subscription_rate_juice", "value"), 0)
	local double = xyd.checkCondition(xyd.getReturnBackIsDoubleTime() == true, 1, 0)
	local goldData = xyd.split(xyd.tables.stageTable:getGold(self.currentStage), "#")
	local ePData = xyd.split(xyd.tables.stageTable:getExpPartner(self.currentStage), "#")
	local ePlayerData = xyd.split(xyd.tables.stageTable:getExpPlayer(self.currentStage), "#")
	self.hangGold = self.hangGold + tonumber(goldData[2]) * (1 + vipOutPutExtra + weekCardGoldExtra + double)
	self.hangPartnerExp = self.hangPartnerExp + tonumber(ePData[2]) * (1 + vipOutPutExtra + weekCardPExpExtra + double)
	self.hangExp = self.hangExp + tonumber(ePlayerData[2]) * (1 + vipOutPutExtra)

	self:updateAllRes()
	self:updateResLabel()
	self:enableGetResBtn(true)
end

function CampaignWindow:initWindowTop()
	self.windowTop = WindowTop.new(self.window_, self.name_, nil, , function ()
		self.isOpenLastWindow = true

		self:close()
	end)
	local items = {
		{
			id = xyd.ItemID.MANA
		},
		{
			hidePlus = 1,
			id = xyd.ItemID.PARTNER_EXP
		}
	}

	self.windowTop:setItem(items)
	self.windowTop:setTitle(xyd.tables.fortTable:getName(self.fortId))

	if xyd.models.activity:isResidentReturnAddTime() then
		self.windowTop:addLeftTop("first_tips", "common_tips_2", 0.5, function ()
			xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_RETURN2_ADD_TEXT09"))
		end)
		self.windowTop:addLeftTop("first_tips2", "common_tips_3", 0.5, function ()
			xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_RETURN2_ADD_TEXT10"))
		end)
	end
end

function CampaignWindow:initResSeq()
	local function initSeq()
		self.resBtnSeq = self:getSequence()

		self.resBtnSeq:Append(self.getHangResBtn.transform:DOScale(Vector3(1.05, 1.05, 1.05), 0.333))
		self.resBtnSeq:Append(self.getHangResBtn.transform:DOScale(Vector3(1.06, 1.06, 1.06), 0.167))
		self.resBtnSeq:Append(self.getHangResBtn.transform:DOScale(Vector3(1, 1, 1), 0.6))
		self.resBtnSeq:AppendCallback(handler(self, function ()
			self.resBtnSeq:Restart()
		end))
	end

	if self.resBtnSeq then
		self.resBtnSeq:Kill(false)

		self.resBtnSeq = nil
	end

	initSeq()
end

function CampaignWindow:stopResSeq()
	if self.resBtnSeq then
		self.resBtnSeq:Kill(false)

		self.resBtnSeq = nil
	end

	self.getHangResBtn.transform.localScale = Vector3.one
end

function CampaignWindow:initTopGroup()
	self.getHangLabel.text = __("GET")

	self:updateResLabel()

	if self.allGold == 0 or self.allPartnerExp == 0 or self.allExp == 0 then
		self:enableGetResBtn(false)
	end

	if not self.resBtnSeq then
		self:initResSeq()
	end

	if not self.campaignEffect1 then
		self.campaignEffect1 = xyd.Spine.new(self.getHangResBtn)

		self.campaignEffect1:setInfo("fx_adv_get_btn", function ()
			self.campaignEffect1:SetLocalPosition(0, 0, 0)
			self.campaignEffect1:SetLocalScale(1, 1, 1)
			self.campaignEffect1:setRenderTarget(self.getHangResBtn:GetComponent(typeof(UISprite)), 1)
			self.campaignEffect1:play("texiao01", -1, 0.54)
		end)
	end
end

function CampaignWindow:onClickgetHangResBtn()
	if self.divideTime <= 0 then
		xyd.SoundManager.get():playSound(xyd.SoundID.GET_EXP)
		self.windowTop:setCanRefresh(false)
		xyd.models.map:getHangItem(1)
	else
		self:goldTouchFunc()
	end
end

function CampaignWindow:onClickgetHangRewardBtn()
	self.mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
	local dropItems = self.mapInfo.drop_items

	if #dropItems > 0 then
		xyd.openWindow("campaign_hang_item_window", {
			alpha = 0.7,
			no_close = true,
			stageId = self.currentStage
		})
	else
		xyd.showToast(__("NO_HANG_REWARD"))
	end
end

function CampaignWindow:onClickHangTeamBtn()
	xyd.openWindow("campaign_hang_formation_window", {
		alpha = 0.7,
		no_close = true
	})
end

function CampaignWindow:initStageList(firstTime, lvChange)
	if lvChange == nil then
		lvChange = false
	end

	local tmpCurrentStage = 1

	if self.currentStage > 0 then
		tmpCurrentStage = self.currentStage
	end

	NGUITools.DestroyChildren(self.stageListGrid.transform)

	local stageItemWidth = 0
	local currId = 0
	local nextId = 0
	local hasMatch = false
	local hasMatchNext = false
	local maxWidth = 38
	self.nextStageItem = nil
	self.currentStageItem = nil
	self.stageItemList = {}
	local isCurrentLast = false

	for i = 1, #self.stageList do
		local stageId = self.stageList[i]
		local isFirst = i == 1
		local isLast = i == #self.stageList
		local go = NGUITools.AddChild(self.stageListGrid.gameObject, self.stageItem.gameObject)

		go:SetActive(true)

		go.name = "campaign_stage_" .. i
		local stageItem = StageItem.new(go, stageId, self.maxStage + 1, self.currentStage, isFirst, isLast)

		table.insert(self.stageItemList, stageItem)

		if self.currentStage > 0 then
			if not hasMatchNext then
				nextId = nextId + 1
			end

			if hasMatch == false then
				currId = currId + 1
			end

			if tonumber(stageId) == tonumber(self.currentStage) then
				hasMatch = true
				self.currentStageItem = stageItem

				if isLast then
					isCurrentLast = true
				end
			end

			if tonumber(stageId) == tonumber(self.maxStage + 1) then
				self.nextStageItem = stageItem
				hasMatchNext = true
			end
		end
	end

	self.stageListGrid:Reposition()
	self:waitForFrame(1, function ()
		self:updateStageListPos(currId)
	end)

	if self.currentStageItem then
		self.currentStageItem:addFightEffect()
	end

	if self.maxHangStage ~= self.maxStage + 1 and self.maxHangStage ~= 0 and self.nextStageItem then
		self.nextStageItem:addReadyEffect(function ()
			if lvChange then
				local nextStage = tonumber(self.maxStage + 1)
				local curChapter = xyd.tables.stageTable:getFortID(self.currentStage)
				local nextStageChapter = xyd.tables.stageTable:getFortID(nextStage)

				if curChapter == nextStageChapter then
					-- Nothing
				end
			elseif self.currentStage == self.maxStage then
				xyd.models.map:hang(self.currentStage + 1)
			end
		end)
	end

	local maxStageID = self.maxHangStage
	local nowFortID1 = xyd.tables.stageTable:getFortID(self.maxStage)
	local nowFortID2 = xyd.tables.stageTable:getFortID(self.maxHangStage)

	if nowFortID1 == nowFortID2 then
		maxStageID = self.maxStage
	end

	if maxStageID > 0 then
		local nowFortID = xyd.tables.stageTable:getFortID(maxStageID)
		local nextFortID = xyd.tables.stageTable:getFortID(maxStageID + 1)

		if nowFortID ~= nextFortID then
			if not self.campaignEffect5 then
				self.campaignEffect5 = xyd.Spine.new(self.mapDetailBtn)

				self.campaignEffect5:setInfo("fx_adv_book_btn", function ()
					self.campaignEffect5:SetLocalPosition(10, -41, 0)
					self.campaignEffect5:SetLocalScale(1, 1, 1)
					self.campaignEffect5:setRenderTarget(self.mapDetailBtn:GetComponent(typeof(UISprite)), 1)
					self.campaignEffect5:play("texiao01", -1)
					self.mapAlertImg:SetActive(true)
				end)
			else
				self.mapAlertImg:SetActive(false)
				self.campaignEffect5:cleanUp()

				self.campaignEffect5 = nil
			end
		else
			if self.campaignEffect5 then
				self.campaignEffect5:cleanUp()

				self.campaignEffect5 = nil
			end

			if self.campaignEffect10 then
				self.campaignEffect10:cleanUp()

				self.campaignEffect10 = nil
			end
		end
	end

	self:setCurrentStage()
	self:dispatchGuideNodeChange()
end

function CampaignWindow:updateStageListPos(currId)
	local stageItemWidth = self.stageItem:GetComponent(typeof(UIWidget)).width - 10
	local maxWidth = stageItemWidth * #self.stageItemList
	local sWidth = xyd.Global.getRealWidth()
	local maxStageNum = math.floor(sWidth / stageItemWidth)
	local minStageNum = 3
	local endX = 0

	if currId <= minStageNum then
		endX = 0
	elseif currId > #self.stageItemList - maxStageNum + 1 then
		endX = -(maxWidth - sWidth)
	else
		endX = -(currId - minStageNum + 1) * stageItemWidth
	end

	local scrollW = self.stageScroller:GetComponent(typeof(UIPanel)).width
	local curX = self.stageScroller:X()
	local initX = scrollW / 2 - stageItemWidth / 2 - 8

	self.stageScroller:MoveRelative(Vector3(endX - curX - initX, 0, 0))

	if self.maxStage < 3 then
		self.dragScrollView:SetActive(false)
	end

	self:setWndComplete()
end

function CampaignWindow:setCurrentStage()
	for i = 1, #self.stageItemList do
		local stageItem = self.stageItemList[i]

		if stageItem.stageId == self.currentStageItem.stageId then
			stageItem:setFightStates(true)
		else
			stageItem:setFightStates(false)
		end
	end
end

function CampaignWindow:onClickMapBtn()
	if self.campaignEffect5 then
		self.campaignEffect5:cleanUp()

		self.campaignEffect5 = nil
	end

	if self.mapAlertImg.gameObject.activeSelf then
		self.mapAlertImg:SetActive(false)
	end

	xyd.openWindow("campaign_fort_window")
end

function CampaignWindow:onClickMapRankBtn()
	local rankInfo_ = xyd.models.map:getMapRank(xyd.MapType.CAMPAIGN)

	if rankInfo_ then
		local stageId = tonumber(rankInfo_.score)
		local mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
		local maxStage = mapInfo.max_stage or 0

		if maxStage ~= stageId then
			xyd.models.map:resetMapRank(xyd.MapType.CAMPAIGN)
		end
	end

	xyd.openWindow("rank_window", {
		mapType = xyd.MapType.CAMPAIGN
	})
end

function CampaignWindow:refreshHangItems()
	self:refreshData()
	self:updateResLabel()

	local drop_items = self.mapInfo.drop_items

	self:enableGetResBtn(true)

	if #drop_items > 0 then
		self.hangRewardAlertImg:SetActive(true)
	else
		self.hangRewardAlertImg:SetActive(false)
	end
end

function CampaignWindow:refreshHangTeam()
	self.mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)

	self:initBg()
	self:initBattle(true)
	self:initStageList(false)
	self:playAnimation(false, false)
end

function CampaignWindow:addGoldEffect()
	if not xyd.GuideController.get():isGuideComplete() then
		return
	end

	local goldBase = xyd.split(xyd.tables.stageTable:getGold(self.currentStage), "#")[2]
	local goldPlus = 0
	local vip_lev = xyd.models.backpack:getVipLev()

	if vip_lev >= 1 then
		local count = xyd.tables.vipTable:extraOutput(vip_lev)
		goldPlus = goldPlus + count
	end

	goldPlus = goldBase * (goldPlus / 100 + 1) / 5
	local hangHours = self.hangGold / goldPlus / 3600

	if hangHours > 6 then
		self.divideTime = 3
	elseif hangHours > 3 then
		self.divideTime = 2
	elseif hangHours > 0.5 then
		self.divideTime = 1
	else
		self.divideTime = 0
	end

	print("divideTime========", self.divideTime)

	if self.divideTime == 0 then
		return
	end

	self:setCoinMaskImg(true)
	self.windowTop:setCanRefresh(false)

	self.goldDownEffect = xyd.Spine.new(self.goldEffectDownGroup.gameObject)

	self.goldDownEffect:setInfo("guajijiemian", function ()
		self.goldDownEffect:SetLocalPosition(0, 0, 0)
		self.goldDownEffect:SetLocalScale(1, 1, 1)
		self.goldDownEffect:setPlayNeedStop(true)
		self.goldDownEffect:setRenderPanel(self.window_:GetComponent(typeof(UIPanel)))
		self.goldDownEffect:setNoStopResumeSetupPose(true)
		self.goldDownEffect:play(self.goldEffectName[self.divideTime][1], -1)
	end)

	self.goldUpEffect = xyd.Spine.new(self.goldEffectUpGroup.gameObject)

	self.goldUpEffect:setInfo("guajijiemian", function ()
		self.goldUpEffect:SetLocalPosition(0, 0, 0)
		self.goldUpEffect:SetLocalScale(1, 1, 1)
		self.goldUpEffect:setPlayNeedStop(true)
		self.goldUpEffect:setNoStopResumeSetupPose(true)
		self.goldUpEffect:play(self.goldEffectName[self.divideTime][3], -1)

		UIEventListener.Get(self.coinMaskImg.gameObject).onClick = handler(self, function ()
			self:goldTouchFunc()
		end)
	end)
end

function CampaignWindow:goldTouchFunc()
	if self.inGoldEffectStep then
		return
	end

	xyd.SoundManager.get():playSound(xyd.SoundID.GET_EXP)
	xyd.models.map:getHangItem(1)

	if not self.goldEffectClicked then
		self.goldEffectClicked = true

		self:updateAllRes()

		return
	end

	if not self.goldDownEffect or not self.goldUpEffect then
		return
	end

	self.inGoldEffectStep = true

	self.goldDownEffect:play(self.goldEffectName[self.divideTime][2], 1, 1, function ()
		if not self.goldUpEffect then
			return
		end

		if self.divideTime <= 1 then
			self:setCoinMaskImg(false)
			self.goldUpEffect:destroy()
			self.goldDownEffect:destroy()

			self.isPlayGoldEffect = false
			self.goldUpEffect = nil
			self.goldDownEffect = nil

			self.windowTop:setCanRefresh(true)

			self.divideTime = 0

			self:enableGetResBtn(false)

			self.isFirstGoldTouch = true

			return
		end

		self.divideTime = self.divideTime - 1

		self.goldUpEffect:play(self.goldEffectName[self.divideTime][3], -1)
		self.goldDownEffect:play(self.goldEffectName[self.divideTime][1], -1)

		self.inGoldEffectStep = false
	end)
	self.goldUpEffect:stop()
	self:playEffect()
end

function CampaignWindow:playEffect()
	local function effFunc(trans, callback)
		local sequence = self:getSequence()

		trans:SetActive(true)

		trans.localScale = Vector3.one

		sequence:Append(trans:DOScale(Vector3(1.15, 1.15, 1.15), 0.1))

		local function setter(value)
			trans:GetComponent(typeof(UISprite)).alpha = value
		end

		sequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0, 0.2):SetEase(DG.Tweening.Ease.Linear))
		sequence:AppendCallback(function ()
			if callback then
				callback()
			end

			trans.localScale = Vector3(0.4, 0.4, 0.4)
			trans:GetComponent(typeof(UISprite)).alpha = 1

			sequence:Kill(false)

			sequence = nil
		end)
	end

	effFunc(self.resPexpImg, function ()
		self:updateResLabel()

		if self.divideTime <= 0 then
			self:enableGetResBtn(false)
		else
			self:enableGetResBtn(true)
		end

		self:initResSeq()
		self:showResAction()
	end)
	effFunc(self.resExpImg)
	effFunc(self.resGoldImg)
end

function CampaignWindow:refreshHangRes(event)
	local params = event.data
	local item_type = params.item_type

	if item_type == xyd.CampaignHangItemType.ECONOMY_ITEMS and (self.divideTime <= 0 or self.isFirstGoldTouch and self.divideTime > 0) then
		self.remainExp = self.hangExp
		self.remainGold = self.hangGold
		self.remainPartnerExp = self.hangPartnerExp
		self.hangExp = 0
		self.hangGold = 0
		self.hangPartnerExp = 0

		self:playEffect()

		self.isFirstGoldTouch = false

		if not self.goldUpEffect or not self.goldDownEffect then
			return
		end

		self.inGoldEffectStep = true

		self.goldDownEffect:play(self.goldEffectName[self.divideTime][2], 1, 1, function ()
			if not self.goldUpEffect or not self.goldDownEffect then
				return
			end

			if self.divideTime <= 1 then
				self:setCoinMaskImg(false)
				self.goldUpEffect:cleanUp()
				self.goldDownEffect:cleanUp()

				self.isPlayGoldEffect = false
				self.goldUpEffect = nil
				self.goldDownEffect = nil

				self.windowTop:setCanRefresh(true)

				self.divideTime = 0

				self:enableGetResBtn(false)

				self.isFirstGoldTouch = true

				NGUITools.DestroyChildren(self.goldEffectDownGroup)
				NGUITools.DestroyChildren(self.goldEffectUpGroup)

				return
			end

			self.divideTime = self.divideTime - 1

			self.goldDownEffect:play(self.goldEffectName[self.divideTime][1], -1)
			self.goldUpEffect:play(self.goldEffectName[self.divideTime][3], -1)

			self.inGoldEffectStep = false
		end)
		self.goldUpEffect:stop()
	elseif item_type == xyd.CampaignHangItemType.DROP_ITEMS then
		self.hangRewardAlertImg:SetActive(false)
	end
end

function CampaignWindow:showResAction()
	if not self.goldAction then
		self.goldAction = ActionImg.new(self.resGoldImg)
	end

	if not self.pexpAction then
		self.pexpAction = ActionImg.new(self.resPexpImg)
	end

	local awardGold, awardPartnerExp = nil
	local rate = 1

	if self.divideTime > 0 then
		rate = 1 / self.divideTime
	end

	awardGold = xyd.round(self.remainGold * rate)
	awardPartnerExp = xyd.round(self.remainPartnerExp * rate)
	self.remainGold = xyd.round(self.remainGold * (1 - rate))
	self.remainPartnerExp = xyd.round(self.remainPartnerExp * (1 - rate))
	self.remainExp = xyd.round(self.remainExp * (1 - rate))

	self:updateAllRes()
	self:updateResLabel()
	self:playCircleAction(self.pexpAction, self.resPexpImgO, 2, awardPartnerExp)
	self:playCircleAction(self.goldAction, self.resGoldImgO, 1, awardGold)
end

function CampaignWindow:playCircleAction(actionImg, startImg, index, award)
	if not self.window_ or not self.windowTop then
		return
	end

	local endResItem = self.windowTop:getResItems()[index]

	if not endResItem then
		return
	end

	local imgTran = actionImg.go.transform
	local resIcon = endResItem:getResIcon()
	local endPos = imgTran.parent:InverseTransformPoint(resIcon.position)
	endPos.z = 0
	local startPos = startImg.localPosition

	imgTran:SetLocalPosition(startPos.x, startPos.y, 0)

	local controlX = nil

	if index == 1 then
		controlX = endPos.x
	else
		controlX = startPos.x

		if endPos.x < startPos.x then
			controlX = endPos.x
		end
	end

	local params = {
		startPos = startPos,
		endPos = endPos,
		controlPos = {
			x = xyd.fixNum(controlX),
			y = xyd.fixNum((startPos.y + endPos.y) / 2)
		}
	}

	print("factor params=== ", json.encode(params))
	actionImg:setData(params)

	imgTran:GetComponent(typeof(UISprite)).alpha = 1

	local function setter(value)
		actionImg:setFactor(xyd.fixNum(value))
	end

	local sequence = self:getSequence(function ()
		actionImg:setOriginalPos()
		self:playTopAction(index, award)
	end)

	sequence:Append(imgTran:DOLocalMove(endPos, 0.75):SetEase(DG.Tweening.Ease.InSine))
end

function CampaignWindow:playTopAction(index, award)
	if not self.window_ then
		return
	end

	local resItem = self.windowTop:getResItems()[index]

	if not resItem then
		return
	end

	local curNum = resItem:getTrueNum()

	local function setter(value)
		resItem:setItemNum(xyd.round(value))
	end

	local icontran = resItem:getResIcon()
	local sequence = self:getSequence()

	sequence:Append(icontran:DOScale(Vector3(1.1, 1.1, 1), 0.06))
	sequence:Join(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), curNum, curNum + award, 0.33))
	sequence:Append(icontran:DOScale(Vector3(0.9, 0.9, 1), 0.06))
	sequence:Append(icontran:DOScale(Vector3(1.1, 1.1, 1), 0.06))
	sequence:Append(icontran:DOScale(Vector3(0.9, 0.9, 1), 0.06))
	sequence:Append(icontran:DOScale(Vector3(1, 1, 1), 0.03))
	sequence:AppendCallback(function ()
		sequence:Kill(false)

		sequence = nil
	end)

	if self.divideTime <= 1 then
		self.windowTop:setCanRefresh(true)
	end
end

function CampaignWindow:setCoinMaskImg(flag)
	if tolua.isnull(self.coinMaskImg) then
		return
	end

	self.coinMaskImg:SetActive(flag)
end

function CampaignWindow:checkCampaignError()
	local currentStage = self.mapInfo.current_stage

	if currentStage == 0 and self.hangTeam and #self.hangTeam > 0 then
		xyd.models.map:hang(1)
	end
end

function CampaignWindow:willClose()
	CampaignWindow.super.willClose(self)

	if self.refreshDataTimer then
		self.refreshDataTimer:Stop()

		self.refreshDataTimer = nil
	end

	if self.refreshHangResTimer then
		self.refreshHangResTimer:Stop()

		self.refreshHangResTimer = nil
	end

	if self.resBtnSeq then
		self.resBtnSeq:Kill(false)

		self.resBtnSeq = nil
	end

	if self.layerBattleHangUp then
		self.layerBattleHangUp:clearAction(true)
	end

	if self.campaignEffect1 then
		self.campaignEffect1:destroy()

		self.campaignEffect1 = nil
	end

	if self.isOpenLastWindow and self.params_ and self.params_.lastWindow and self.name_ ~= "smithy_window" and self.name_ ~= "enhance_window" then
		xyd.WindowManager.get():openWindow(self.params_.lastWindow)
	end
end

function CampaignWindow:didClose(params)
	CampaignWindow.super.didClose(self, params)
end

function CampaignWindow:iosTestChangeUI()
	local winTrans = self.window_.transform

	winTrans:NodeByName("map_panel/map_group/stage_list_bg").gameObject:SetActive(false)

	local iosBg = NGUITools.AddChild(winTrans:NodeByName("map_panel/map_group").gameObject, "iosBg")
	local iosBG = iosBg:AddComponent(typeof(UISprite))
	iosBG.height = 695
	iosBG.width = 1000

	iosBg:SetLocalPosition(0, -65, 0)
	xyd.setUISprite(iosBG, nil, "battle_bg_sections_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("map_panel/map_group/hang_top_group/help_btn", typeof(UISprite)), "battle_btn_round_help_blue_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("map_panel/map_group/hang_top_group/rank_btn", typeof(UISprite)), "battle_btn_round_rank_blue_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("map_panel/map_group/hang_top_group/get_hang_res_btn", typeof(UISprite)), "blue_btn_65_65test_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("map_panel/map_group/hang_top_group/hang_tween_group/e:Image", typeof(UISprite)), "battle_bg_campBuff")
	xyd.iosSetUISprite(winTrans:ComponentByName("map_panel/map_group/hang_bottom_group/map_detail_btn", typeof(UISprite)), "battle_btn_chapter_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("map_panel/map_group/hang_bottom_group/hang_reward_btn", typeof(UISprite)), "battle_btn_bonus_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("map_panel/map_group/hang_bottom_group/fight_btn", typeof(UISprite)), "battle_btn_battle_ios_test")

	winTrans:ComponentByName("map_panel/map_group/hang_bottom_group/fight_btn", typeof(UISprite)).height = 164

	winTrans:NodeByName("map_panel/map_group/hang_bottom_group/fight_btn/fight_bg").gameObject:SetActive(false)
	winTrans:NodeByName("map_panel/map_group/hang_bottom_group/fight_btn/fight_bg_1").gameObject:SetActive(false)

	local label = winTrans:ComponentByName("map_panel/map_group/hang_bottom_group/fight_btn/fight_btn_label", typeof(UILabel))
	label.depth = 60
	label.color = Color.New2(4294967295.0)

	label:SetLocalPosition(0, -40, 0)

	label.fontSize = 30
	label.effectStyle = UILabel.Effect.Outline8
	label.effectColor = Color.New2(3429853951.0)

	xyd.iosSetUISprite(winTrans:ComponentByName("map_panel/map_group/hang_bottom_group/fight_end_group/e:Image", typeof(UISprite)), "battle_btn_battleOver_ios_test")

	local label = winTrans:ComponentByName("map_panel/map_group/hang_bottom_group/fight_end_group/fight_end_label", typeof(UILabel))
	label.depth = 60
	label.color = Color.New2(4294967295.0)

	label:SetLocalPosition(0, -40, 0)

	label.fontSize = 30
	label.effectStyle = UILabel.Effect.Outline8
	label.effectColor = Color.New2(799854591)

	xyd.setUISprite(self.getHangResBtn:GetComponent(typeof(UISprite)), nil, "blue_btn_65_65_ios_test")
end

function CampaignWindow:onClickEscBack()
	self.isOpenLastWindow = true

	CampaignWindow.super.onClickEscBack(self)
end

return CampaignWindow
