local BaseWindow = import(".BaseWindow")
local TrialWindow = class("TrialWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")
local CountDown = import("app.components.CountDown")
local BaseComponent = import("app.components.BaseComponent")
local TrialCampaignItem = class("TrialCampaignItem", BaseComponent)

function TrialWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.items = {}
end

function TrialWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()
	self:setLayout()
	self:checkBuffAward()
	self:setPoint()
end

function TrialWindow:getUIComponent()
	self.imgBgTexture = self.window_:ComponentByName("imgBgTexture", typeof(UITexture))
	local trans = self.imgBgTexture.transform
	self.imgBg = self.window_.transform:ComponentByName("imgBg", typeof(UISprite))
	self.groupEffect = trans:NodeByName("groupEffect").gameObject
	self.bossNode = trans:ComponentByName("bossNode", typeof(UISprite))
	self.groupContainer = trans:NodeByName("groupContainer").gameObject
	self.groupClock = trans:NodeByName("groupClock").gameObject
	self.groupIconText = trans:NodeByName("groupIconText").gameObject
	self.groupIconTextTable = self.groupIconText:GetComponent(typeof(UITable))
	self.labelDisplay = self.groupIconText:ComponentByName("labelDisplay", typeof(UILabel))
	local labelTime = self.groupIconText:ComponentByName("labelTime", typeof(UILabel))
	self.labelTime = CountDown.new(labelTime)
	self.groupItem = trans:NodeByName("groupItem").gameObject
	self.btnShop = self.groupItem:NodeByName("btnShop").gameObject
	self.btnHelp = self.groupItem:NodeByName("btnHelp").gameObject
	self.btnRank = self.groupItem:NodeByName("btnRank").gameObject
	self.blessBtn = self.groupItem:NodeByName("btnBuff").gameObject
	self.awardGroup = trans:NodeByName("awardGroup").gameObject
	self.groupBtn = self.awardGroup:NodeByName("groupBtn").gameObject
	self.groupBtnBoxCollider = self.groupBtn:GetComponent(typeof(UnityEngine.BoxCollider))
	self.groupAwardEffect = self.groupBtn:NodeByName("groupAwardEffect").gameObject
	self.btnAward = self.groupBtn:NodeByName("btnAward").gameObject
	self.bgEffect_ = self.window_:NodeByName("bgEffect").gameObject
	self.effectChris1_ = xyd.WindowManager.get():setChristmasEffect(self.bgEffect_, true)
	self.battlePassBtn = self.window_:NodeByName("battlePassBtn").gameObject
	self.battlePassBtnLabel = self.battlePassBtn:ComponentByName("battlePassLabel", typeof(UILabel))

	if xyd.models.trial:getBossId() == 2 then
		self.imgBgTexture.transform:Y(0)
		self.groupEffect.transform:Y(self.groupEffect.transform.localPosition.y - 140)
		self.bossNode.transform:Y(self.bossNode.transform.localPosition.y - 15)
		self.bossNode.transform:X(0)
		self.groupClock.transform:Y(self.groupClock.transform.localPosition.y - 140)
		self.groupIconText.transform:Y(self.groupIconText.transform.localPosition.y - 140)
		self.groupItem.transform:Y(self.groupItem.transform.localPosition.y - 140)
		self.awardGroup.transform:Y(self.awardGroup.transform.localPosition.y - 140)
	end
end

function TrialWindow:checkBuffAward()
	if not xyd.models.trial:getData().buff_rewards or #xyd.models.trial:getData().buff_rewards <= 0 then
		return
	end

	local params = {
		info = xyd.models.trial:getData()
	}

	xyd.WindowManager.get():openWindow("activity_new_trial_fight_award_window", params)
end

function TrialWindow:register()
	TrialWindow.super.register(self)

	UIEventListener.Get(self.btnShop).onClick = function ()
		self:openShop()
	end

	UIEventListener.Get(self.btnRank).onClick = function ()
		xyd.WindowManager.get():openWindow("new_trial_rank_window")
	end

	UIEventListener.Get(self.btnAward).onClick = function ()
	end

	UIEventListener.Get(self.btnHelp).onClick = function ()
		local params = {
			key = "TRIAL_ENTER_WINDOW_HELP"
		}

		xyd.WindowManager.get():openWindow("help_window", params)
	end

	UIEventListener.Get(self.bossNode.gameObject).onClick = function ()
		local theTrialData = xyd.models.trial:getData()

		if xyd.models.trial:getTableUse():getType(theTrialData.current_stage) ~= 4 then
			return
		end

		local params = {
			showSkip = false,
			index = 1,
			enemy = theTrialData.enemy,
			stageId = theTrialData.current_stage,
			mapType = xyd.MapType.TRIAL,
			battleType = xyd.BattleType.TRIAL,
			buffIds = theTrialData.buff_ids
		}

		if theTrialData.boss_id == 2 then
			xyd.WindowManager.get():openWindow("new_trial_boss_info_window2", params)
		else
			xyd.WindowManager.get():openWindow("new_trial_boss_info_window", params)
		end
	end

	UIEventListener.Get(self.blessBtn).onClick = function ()
		if not xyd.models.trial:getData().buff_ids or #xyd.models.trial:getData().buff_ids <= 0 then
			xyd.alertTips(__("NEW_TRIAL_NO_BLESS_TIPS"))
		else
			xyd.WindowManager.get():openWindow("activity_new_trial_bless_window", {
				buffIds = xyd.models.trial:getData().buff_ids
			})
		end
	end

	UIEventListener.Get(self.battlePassBtn).onClick = function ()
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS)

		if activityData then
			xyd.openWindow("activity_window", {
				activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS),
				activity_type2 = xyd.tables.activityTable:getType2(xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS),
				select = xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS,
				self:close()
			})
		end
	end

	self.eventProxy_:addEventListener(xyd.event.TRIAL_START, handler(self, self.updatePoint))
	self.eventProxy_:addEventListener(xyd.event.GET_TRIAL_INFO, handler(self, self.updatePoint))
	self.eventProxy_:addEventListener(xyd.event.NEW_TRIAL_FIGHT, handler(self, self.onFinishSpring))
	self.eventProxy_:addEventListener(xyd.event.SYSTEM_REFRESH, handler(self, self.systemRefresh))
	self.eventProxy_:addEventListener(xyd.event.NEW_TRIAL_NEXT_POINT, handler(self, self.onNextPoint))
end

function TrialWindow:onNextPoint(event, noNext)
	if event.data then
		xyd.models.trial:updateData(event.data)
	end

	if noNext then
		return
	end

	self:nextPoint()
	self:checkBossShow()

	if event.callback then
		event.callback()
	end
end

function TrialWindow:onFinishSpring(event)
	if event.data.battle_report and tostring(event.data.battle_report) ~= "" then
		return
	end

	if event.data.info.buff_rewards and #event.data.info.buff_rewards > 0 then
		local params = {
			info = event.data.info
		}

		xyd.WindowManager.get():openWindow("activity_new_trial_fight_award_window", params)
	end

	self:onNextPoint({
		data = event.data.info
	})
end

function TrialWindow:checkBossShow()
	if xyd.models.trial:getTableUse():getType(xyd.models.trial:currentStage()) == 4 then
		xyd.applyOrigin(self.bossNode)

		self.bossNode:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	else
		xyd.applyGrey(self.bossNode)

		self.bossNode:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	end
end

function TrialWindow:setLayout()
	self.windowTop = WindowTop.new(self.window_, self.name_, 1, true, function ()
		xyd.WindowManager.get():closeWindow("trial_window")
		xyd.WindowManager.get():closeWindow("trial_enter_window")
	end)
	local items = {
		{
			hidePlus = true,
			id = xyd.ItemID.TRIAL_COIN
		}
	}

	self.windowTop:setItem(items)
	self.windowTop:setCanRefresh(true)
	self:setClockEffect()

	local data = xyd.models.trial:getData()
	self.battlePassBtnLabel.text = __("NEW_TRIAL_MAIN_WINDOW_TEXT02")
	self.labelDisplay.text = __("TRIAL_TEXT03")

	self.labelTime:setInfo({
		duration = data.end_time - xyd.getServerTime()
	})

	local bgImg = xyd.tables.newTrialBossScenesTable:getStageScene(xyd.models.trial:getBossId())

	if xyd.models.trial:getBossId() == 2 then
		xyd.setUISpriteAsync(self.bossNode, nil, "new_trial_boss2")
		self:waitForFrame(3, function ()
			local continerWidget = self.groupContainer:GetComponent(typeof(UIWidget))
			local height = continerWidget.height
			local changeY = (height - 1280) / 178 * 55
			local changeY2 = (height - 1280) / 178 * 40

			self.bossNode.transform:Y(self.bossNode.transform.localPosition.y - 40 + changeY2)
			self.groupContainer.transform:Y(self.groupContainer.transform.localPosition.y + changeY)
		end)
	else
		xyd.setUISpriteAsync(self.bossNode, nil, "new_trial_boss")
	end

	xyd.setUITextureAsync(self.imgBgTexture, "Textures/scenes_web/" .. bgImg)
	self:checkBossShow()
end

function TrialWindow:getWindowTop()
	return self.windowTop
end

function TrialWindow:setBGEffect()
end

function TrialWindow:setAwardEffect()
	self.awardEffect = xyd.Spine.new(self.groupAwardEffect)

	self.awardEffect:setInfo("fx_ui_ptbx", function ()
		self.awardEffect:SetLocalScale(1, 1, 1)
		self:updateAwardEffect()
	end)
	self:playAwardEffect(false)
end

function TrialWindow:setClockEffect()
	self.clockEffect = xyd.Spine.new(self.groupClock)

	self.clockEffect:setInfo("fx_ui_shizhong", function ()
		self.clockEffect:SetLocalScale(1, 1, 1)
		self.clockEffect:play("texiao1", 0)
	end)
end

function TrialWindow:setPoint()
	local boss_id = xyd.models.trial:getBossId()
	local ids = xyd.tables.newTrialOffsetTable:getIdsByBoss(boss_id)

	for i = 1, #ids do
		local id = ids[i]
		local type_ = xyd.tables.newTrialOffsetTable:getType(id)
		local offX = xyd.tables.newTrialOffsetTable:getOffsetX(id)
		local offY = xyd.tables.newTrialOffsetTable:getOffsetY(id)
		local item = TrialCampaignItem.new(self.groupContainer, id)
		local continerWidget = self.groupContainer:GetComponent(typeof(UIWidget))
		local w = nil

		if item.stageId ~= 0 then
			w = item.imgIcon:GetComponent(typeof(UIWidget))
		else
			w = item.pointImg:GetComponent(typeof(UIWidget))
		end

		local x = offX + w.width / 2 - continerWidget.width / 2
		local y = -(offY + w.height / 2) + continerWidget.height / 2
		item.go.transform.localPosition = Vector3(x, y, 1)
		local widget = item.go:GetComponent(typeof(UIWidget))
		widget.height = w.height
		widget.width = w.width
		self.items[id] = item
	end
end

function TrialWindow:nextPoint()
	local points = {}
	local current = xyd.models.trial:currentStage()

	for i = 1, 29 do
		local id = i + (xyd.models.trial:getBossId() - 1) * 29
		local type_ = xyd.tables.newTrialOffsetTable:getType(id)
		local stage = xyd.tables.newTrialOffsetTable:getStage(id)

		if type_ > 0 and type_ < current then
			self.items[id]:setFinish()
			self.items[id]:setTouchEnabled(false)
		end

		if stage == current then
			table.insert(points, self.items[id])
		end
	end

	for i = 1, #points do
		local item = points[i]
		local widget = item.go:GetComponent(typeof(UIWidget))

		item:SetActive(true)

		widget.alpha = 0
		item.go.transform.localScale = Vector3(0, 0, 0)
		local action = self:getSequence()
		local getter, setter = xyd.getTweenAlphaGeterSeter(widget)

		action:Insert(0.2 * (i - 1), item.go.transform:DOScale(Vector3(1.2, 1.2, 1.2), 0.2))
		action:Insert(0.2 * (i - 1), DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.2))
		action:Insert(0.4 * (i - 1), item.go.transform:DOScale(Vector3(1, 1, 1), 0.1))
		action:AppendCallback(function ()
			action:Kill(false)

			action = nil
		end)
	end
end

function TrialWindow:updatePoint()
	local current = xyd.models.trial:currentStage()

	for i = 1, #self.items do
		local id = i
		local type_ = xyd.tables.newTrialOffsetTable:getType(id)
		local stage = xyd.tables.newTrialOffsetTable:getStage(id)

		if type_ > 0 and type_ < current then
			self.items[i]:setFinish()
			self.items[i]:setTouchEnabled(false)
		end

		if current < stage then
			self.items[i]:SetActive(false)
		end
	end

	local data = xyd.models.trial:getData()

	self.labelTime:setCountDownTime(data.end_time - xyd.getServerTime())
end

function TrialWindow:updateAwardEffect()
	local current_award = xyd.models.trial:getData().current_award
	local current = xyd.models.trial:currentStage()
	local play = current_award < math.floor((current - 1) / 3)

	self:playAwardEffect(play)
end

function TrialWindow:playAwardEffect(bool)
	self.awardEffect:SetActive(bool)

	if bool then
		self.btnAward:SetActive(false)

		self.groupBtnBoxCollider.enabled = false
	else
		self.btnAward:SetActive(true)

		self.groupBtnBoxCollider.enabled = true
	end

	if self.awardEffect:isValid() then
		if bool then
			self.awardEffect:play("texiao01", 0)
		else
			self.awardEffect:stop()
		end
	end
end

function TrialWindow:openShop()
	xyd.WindowManager.get():openWindow("shop_window", {
		shopType = xyd.ShopType.SHOP_TRIAL,
		closeCallBack = function ()
			if not self or not self.windowTop then
				return
			end
		end
	})
end

function TrialWindow:systemRefresh()
	xyd.showToast(__("TRIAL_TEXT09"))
	xyd.WindowManager.get():closeWindow(self.name)
	xyd.WindowManager.get():closeWindow("trial_campaign_window")
end

function TrialWindow:didClose(params)
	BaseWindow.didClose(self, params)
end

function TrialWindow:willClose()
	if self.effectChris1_ then
		self.effectChris1_:destroy()
	end

	xyd.models.trial:checkUpdateBattlePass()
end

function TrialCampaignItem:ctor(parentGo, id)
	self.id = id

	TrialCampaignItem.super.ctor(self, parentGo)
end

function TrialCampaignItem:getPrefabPath()
	return "Prefabs/Components/trial_item"
end

TrialCampaignItem.iconList = {
	"new_trial_point3",
	"new_trial_point2",
	"new_trial_point5",
	"new_trial_point_1",
	"new_trial_point5"
}

function TrialCampaignItem:initUI()
	TrialCampaignItem.super.initUI(self)

	self.boxCollider = self.go:GetComponent(typeof(UnityEngine.BoxCollider))
	self.imgIcon = self.go:ComponentByName("imgIcon", typeof(UISprite))

	xyd.setUISpriteAsync(self.imgIcon, nil, "trial_icon09")

	self.labelNumber = self.go:ComponentByName("labelNumber", typeof(UILabel))
	self.pointImg = self.go:ComponentByName("pointIcon", typeof(UISprite))

	self:setChildren()
end

function TrialCampaignItem:setChildren()
	self.stageId = xyd.tables.newTrialOffsetTable:getType(self.id)
	local belongId = self.stageId

	if belongId == 0 then
		belongId = xyd.tables.newTrialOffsetTable:getStage(self.id)
	end

	local current = xyd.models.trial:currentStage()

	self:initImgs()
	self:updatePointShow(belongId - current)

	if self.stageId <= 0 then
		return
	end

	UIEventListener.Get(self.go).onClick = function ()
		self:onTouch()
	end
end

function TrialCampaignItem:setTouchEnabled(enabled)
	self.boxCollider.enabled = enabled
end

function TrialCampaignItem:initImgs()
	local type_ = 1

	if self.stageId ~= 0 then
		type_ = xyd.models.trial:getTableUse():getType(self.stageId) or 1
	end

	if type_ ~= 4 then
		xyd.setUISpriteAsync(self.imgIcon, nil, self.iconList[type_])
		self.labelNumber.gameObject:SetActive(true)
	else
		self.labelNumber.gameObject:SetActive(false)
	end
end

function TrialCampaignItem:updatePointShow(currentType_)
	if self.stageId ~= 0 then
		self.imgIcon.gameObject:SetActive(true)
		self.pointImg.gameObject:SetActive(false)

		self.labelNumber.text = tostring(self.stageId)
	else
		self.imgIcon.gameObject:SetActive(false)
		self.pointImg.gameObject:SetActive(true)

		self.labelNumber.text = " "
	end

	if currentType_ == 0 then
		self.go:SetActive(true)
	elseif currentType_ < 0 then
		self.go:SetActive(true)
		self:setFinish()
	elseif xyd.models.trial:currentStage() == -1 then
		self.go:SetActive(true)
		self:setFinish()
	else
		self.go:SetActive(false)
	end
end

function TrialCampaignItem:onTouch()
	print("==========onTouch ========  ")
	xyd.SoundManager:playSound(xyd.SoundID.BUTTON)
	print("self.stageId  ", self.stageId)

	if self.stageId <= 0 or self.stageId ~= xyd.models.trial:currentStage() then
		return
	end

	local type_ = xyd.models.trial:getTableUse():getType(self.stageId)
	local enemy = xyd.models.trial.enemy

	print("type_  ", type_)

	if type_ == xyd.NewTrialPointType.FIGHT or type_ == xyd.NewTrialPointType.SUPER_FIGHT then
		local params = {
			enemy = enemy,
			stage_id = self.stageId
		}

		xyd.WindowManager.get():openWindow("trial_campaign_window", params)
	elseif type_ == xyd.NewTrialPointType.SHOP then
		xyd.alertConfirm(__("TRIAL_SPRING_DES"), function ()
			local msg = messages_pb.new_trial_fight_req()
			msg.stage_id = self.stageId

			xyd.Backend.get():request(xyd.mid.NEW_TRIAL_FIGHT, msg)
			xyd.WindowManager.get():closeWindow("alert_window")
		end, __("TRIAL_SPRING_OK"), true, {}, __("TRIAL_SPRING_TITLE"))
	elseif type_ == xyd.NewTrialPointType.REST then
		local msg = messages_pb.new_trial_fight_req()
		msg.stage_id = self.stageId

		xyd.Backend.get():request(xyd.mid.NEW_TRIAL_FIGHT, msg)
	end
end

function TrialCampaignItem:setFinish()
	local type_ = xyd.models.trial:getTableUse():getType(self.stageId)

	if self.stageId ~= 0 and type_ ~= 4 then
		xyd.setUISpriteAsync(self.imgIcon, nil, self.iconList[4])

		self.labelNumber.text = " "
	end
end

return TrialWindow
