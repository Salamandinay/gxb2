local BaseWindow = import(".BaseWindow")
local TrialEnterWindow = class("TrialEnterWindow", BaseWindow)
local cjson = require("cjson")
local WindowTop = import("app.components.WindowTop")
local GirlsModel = import("app.components.GirlsModel")
local BubbleText = import("app.components.BubbleText")
local BaseComponent = import("app.components.BaseComponent")
local CountDown = import("app.components.CountDown")
local TrialFlowerButton = class("TrialFlowerButton", BaseComponent)

function TrialEnterWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function TrialEnterWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()
	self:setLayout()
	self:initGirl()
	self:initPrivilegeCard()
end

function TrialEnterWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupEffect1 = trans:NodeByName("groupEffect1").gameObject
	self.imgBgTexture = trans:ComponentByName("imgBgTexture", typeof(UITexture))
	self.groupEffect2 = trans:NodeByName("groupEffect2").gameObject
	self.groupEffect3 = trans:NodeByName("groupEffect3").gameObject
	self.girlGroup = trans:NodeByName("girlGroup").gameObject
	self.groupItem = trans:NodeByName("groupItem").gameObject
	self.bubbleTextGroup = trans:NodeByName("bubbleTextGroup").gameObject
	self.helpBtn = self.groupItem:NodeByName("helpBtn").gameObject
	self.btnShop = self.groupItem:NodeByName("btnShop").gameObject
	self.btnRank = self.groupItem:NodeByName("btnRank").gameObject
	local btnGoGroup = trans:NodeByName("btnGoGroup").gameObject
	self.btnGo = TrialFlowerButton.new(btnGoGroup)

	self.btnGo.go:SetActive(false)

	self.privilegeCardCon = trans:NodeByName("privilegeCardCon").gameObject
	self.privilegeCardBg = self.privilegeCardCon:ComponentByName("privilegeCardBg", typeof(UITexture))
	self.privilegeCardIcon = self.privilegeCardCon:ComponentByName("privilegeCardIcon", typeof(UITexture))
	self.privilegeCardLabel = self.privilegeCardCon:ComponentByName("privilegeCardLabel", typeof(UILabel))
	self.titleGroup = trans:NodeByName("titleGroup").gameObject
	self.titleLayout = self.titleGroup:ComponentByName("bg", typeof(UILayout))
	self.titleLabel = self.titleGroup:ComponentByName("bg/label", typeof(UILabel))
	self.battlePassBtn = trans:NodeByName("battlePassBtn").gameObject
	self.battlePassBtnLabel = self.battlePassBtn:ComponentByName("battlePassLabel", typeof(UILabel))
end

function TrialEnterWindow:register()
	TrialEnterWindow.super.register(self)

	UIEventListener.Get(self.btnGo.groupMain_).onClick = function ()
		self:onOpenTrial()
	end

	UIEventListener.Get(self.btnShop).onClick = function ()
		self:openShop()
	end

	UIEventListener.Get(self.btnRank).onClick = function ()
		xyd.WindowManager.get():openWindow("new_trial_rank_window")
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

	self.eventProxy_:addEventListener(xyd.event.GET_TRIAL_INFO, handler(self, self.onTrialInfo))
	self.eventProxy_:addEventListener(xyd.event.TRIAL_START, handler(self, self.startTrial))
end

function TrialEnterWindow:setLayout()
	self.windowTop = WindowTop.new(self.window_, self.name_, 1, true)
	local items = {
		{
			hidePlus = true,
			id = xyd.ItemID.TRIAL_COIN
		}
	}

	self.windowTop:setItem(items)

	local data = xyd.models.trial:getData()

	if not data or data.start_time == nil or data.start_time < xyd.getServerTime() then
		xyd.models.trial:reqTrialInfo()
	else
		self:onTrialInfo()
	end

	xyd.setUITextureAsync(self.imgBgTexture, "Textures/scenes_web/trial_bg01")
end

function TrialEnterWindow:initGirl()
	self.girlModel = GirlsModel.new(self.girlGroup)

	self.girlModel:setModelInfo({
		id = 8,
		timeScale = 1
	})

	local posScaleArr = xyd.tables.miscTable:split2num("trial_enter_girl_pos_scale", "value", "|")
	local wHeight = self.window_:GetComponent(typeof(UIPanel)).height

	self.girlGroup:X(posScaleArr[1])
	self.girlGroup:Y(wHeight / 2 - posScaleArr[2])
	self.girlGroup.transform:SetLocalScale(posScaleArr[3], posScaleArr[3], posScaleArr[3])

	local bubble = BubbleText.new(self.bubbleTextGroup)

	self.bubbleTextGroup.transform:SetLocalScale(1.2, 1.2, 1.2)
	bubble:setText(xyd.tables.girlsModelTable:getEnterDialog(8))
	bubble:setBgVector(false)
	bubble:setPosition(Vector3(-100, 160, 0))
	bubble:setBubbleFlipX(false)
	bubble:setBubble(nil, Color.New2(1061442047), nil, )
	self.girlModel:setBubble(bubble)
end

function TrialEnterWindow:onOpenTrial()
	local data = xyd.models.trial:getData()

	if data.is_open == 0 then
		return
	elseif data.current_stage == 0 then
		xyd.models.trial:startReq()
	else
		self:startTrial()
	end
end

function TrialEnterWindow:onTrialInfo()
	local data = xyd.models.trial:getData()
	local boss_id = data.boss_id
	self.battlePassBtnLabel.text = __("NEW_TRIAL_MAIN_WINDOW_TEXT02")

	if data.is_open == 0 then
		self.btnGo:setCurrentState(1)

		self.btnGo.labelDisplay.text = __("TRIAL_TEXT01")

		self.btnGo.labelTime:setInfo({
			duration = data.end_time + 3600 - xyd.getServerTime()
		})
		self.btnGo:setTouchEnable(false)
		self.btnGo:setClockEffect()
	else
		if boss_id and boss_id > 0 then
			local desc = nil

			if boss_id == 2 then
				desc = "[c][fe8165]" .. __("NEW_TRIAL_SEA_SECRET") .. "[-][c]"
			else
				desc = "[c][fe8165]" .. __("NEW_TRIAL_VOLCAN_SECRET") .. "[-][c]"
			end

			self.titleLabel.text = __("NEW_TRIAL_MAIN_WINDOW_TEXT01", desc)

			self.titleLayout:Reposition()
			self.titleGroup:SetActive(true)
			self:initEffectNew()

			if not self.effectNew then
				self.effectNew = xyd.Spine.new(self.groupEffect3)

				self.effectNew:setInfo("fx_new_trial_scence", function ()
					self.effectNew:play("texiao0" .. boss_id, 0, 1)
				end)
			else
				self.effectNew:play("texiao0" .. boss_id, 0, 1)
			end
		end

		self.btnGo:setCurrentState(2)

		self.btnGo.labelDisplay02.text = __("TRIAL_TEXT02")

		self.btnGo:setTouchEnable(true)
	end

	self.btnGo:resetLablePos()
	self.btnGo:SetActive(true)
end

function TrialEnterWindow:initEffectNew()
end

function TrialEnterWindow:openShop()
	xyd.WindowManager.get():openWindow("shop_window", {
		shopType = xyd.ShopType.SHOP_TRIAL
	})
	self.girlModel:stopSound()
end

function TrialEnterWindow:startTrial()
	xyd.models.trial:setDefaultRedMark()

	if self.params_.closeCallBack then
		self.params_.closeCallBack = nil
	end

	local params = xyd.db.misc:getValue("trial_boss_story")

	if not params then
		params = {}
	else
		params = cjson.decode(params)
	end

	if not params["boss_" .. xyd.models.trial:getBossId()] then
		xyd.WindowManager.get():openWindow("story_window", {
			isDisappearCall = true,
			story_id = xyd.models.trial:getBossId() * 100 + 1,
			story_type = xyd.StoryType.TRIAL,
			callback = function ()
				params["boss_" .. xyd.models.trial:getBossId()] = 1

				xyd.db.misc:setValue({
					key = "trial_boss_story",
					value = cjson.encode(params)
				})
				xyd.WindowManager.get():openWindow("trial_window", {
					closeCallBack = self.params_.closeCallBack
				})
			end
		})
	else
		xyd.WindowManager.get():openWindow("trial_window", {
			closeCallBack = self.params_.closeCallBack
		})
	end
end

function TrialEnterWindow:initPrivilegeCard()
	UIEventListener.Get(self.privilegeCardBg.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("privilege_card_activity_pop_up_window", {
			giftid = xyd.GIFTBAG_ID.PRIVILEGE_CARD_TRIAL
		})
	end)

	self:updatePrivilegeCard()
end

function TrialEnterWindow:updatePrivilegeCard()
	local privilegeData = xyd.models.activity:getActivity(xyd.ActivityID.PRIVILEGE_CARD)

	if privilegeData and privilegeData:isHide() == false then
		self.privilegeCardCon:SetActive(true)
	else
		self.privilegeCardCon:SetActive(false)

		return
	end

	if privilegeData:getStateById(xyd.GIFTBAG_ID.PRIVILEGE_CARD_TRIAL) == true then
		xyd.setUITextureByNameAsync(self.privilegeCardBg, "tips_btn_color_privilege_card", true)
		xyd.setUITextureByNameAsync(self.privilegeCardIcon, "tips_show_color_privilege_card", true)

		self.privilegeCardLabel.text = __("PRIVILEGE_CARD_ACTIVE")
		self.privilegeCardLabel.color = Color.New2(3506416383.0)
		self.privilegeCardLabel.effectColor = Color.New2(960513791)
	else
		xyd.setUITextureByNameAsync(self.privilegeCardBg, "tips_btn_grey_privilege_card", true)
		xyd.setUITextureByNameAsync(self.privilegeCardIcon, "tips_show_grey1_privilege_card", true)

		self.privilegeCardLabel.text = __("PRIVILEGE_CARD_IN_ACTIVE")
		self.privilegeCardLabel.color = Color.New2(4160157439.0)
		self.privilegeCardLabel.effectColor = Color.New2(1179010815)
	end
end

function TrialEnterWindow:didClose(params)
	BaseWindow.didClose(self, params)
	self.girlModel:stopSound()
end

function TrialFlowerButton:ctor(parentGo)
	TrialFlowerButton.super.ctor(self, parentGo)
end

function TrialFlowerButton:getPrefabPath()
	return "Prefabs/Components/trial_flower_button"
end

function TrialFlowerButton:initUI()
	TrialFlowerButton.super.initUI(self)

	self.groupMain_ = self.go:NodeByName("groupMain_").gameObject
	self.boxCollider = self.groupMain_:GetComponent(typeof(UnityEngine.BoxCollider))
	self.img = self.groupMain_:ComponentByName("img", typeof(UISprite))

	xyd.setUISpriteAsync(self.img, nil, "trial_btn02")

	self.groupIconText = self.groupMain_:NodeByName("groupIconText").gameObject
	self.groupIconTextTable = self.groupIconText:GetComponent(typeof(UITable))
	self.labelDisplay = self.groupIconText:ComponentByName("labelDisplay", typeof(UILabel))
	self.labelDisplay02 = self.groupIconText:ComponentByName("labelDisplay02", typeof(UILabel))
	local labelTime = self.groupIconText:ComponentByName("labelTime", typeof(UILabel))
	self.labelTime = CountDown.new(labelTime)
	self.groupClock = self.groupIconText:NodeByName("groupClock").gameObject

	self:setChildren()
end

function TrialFlowerButton:setCurrentState(state)
	if state == 1 then
		xyd.setUISpriteAsync(self.img, nil, "new_trial_btn01")
		self.groupClock:SetActive(true)
		self.labelDisplay:SetActive(true)
		self.labelTime.go:SetActive(true)
		self.labelDisplay02:SetActive(false)
	else
		xyd.setUISpriteAsync(self.img, nil, "new_trial_btn02")
		self.groupClock:SetActive(false)
		self.labelDisplay:SetActive(false)
		self.labelTime.go:SetActive(false)
		self.labelDisplay02:SetActive(true)
	end
end

function TrialFlowerButton:setChildren()
end

function TrialFlowerButton:onTAP()
end

function TrialFlowerButton:setTouchEnable(enable)
	self.boxCollider.enabled = enable
end

function TrialFlowerButton:resetLablePos()
	self.groupIconTextTable:Reposition()
end

function TrialFlowerButton:setClockEffect()
	self.clockEffect = xyd.Spine.new(self.groupClock)

	self.clockEffect:setInfo("fx_ui_shizhong", function ()
		self.clockEffect:SetLocalScale(1, 1, 1)
		self.clockEffect:setRenderTarget(self.img, 1)
		self.clockEffect:play("texiao1", 0, 1)
		self:resetLablePos()
	end)
end

return TrialEnterWindow
