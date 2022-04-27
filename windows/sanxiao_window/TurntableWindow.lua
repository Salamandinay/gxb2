local TurntableWindow = class("TurntableWindow", import(".BaseWindow"))
local cjson = require("cjson")
local MappingData = xyd.MappingData
local PlayerPrefs = UnityEngine.PlayerPrefs
local ItemConstants = xyd.ItemConstants
local SpineManager = xyd.SpineManager
local Destroy = UnityEngine.Object.Destroy
local ItemTable = xyd.tables.item
local DirectReturnGameItemID = {
	ItemConstants.ADD_FIVE_STEPS,
	ItemConstants.ADD_THREE_STEPS,
	ItemConstants.ADD_FIVE_STEPS_TIME
}

function TurntableWindow:ctor(name, params)
	TurntableWindow.super.ctor(self, name, params)

	self._gameMode = params.gameMode
	self._endGameWindow = params.endGameWindow
	self.turntableData = params.turntableData
	self.turntableLightEff = nil
	self.turntableCharEff = nil
	self.turntableFlagEff = nil
	self.turntableGlowEff = nil
end

function TurntableWindow:initWindow()
	TurntableWindow.super.initWindow(self)

	self.TURNTABLE_AWARD_KIND_NUM = 8
	self.CIRCLE_NUM = 3
	self.SLIDE_ANGLE = 5
	self.turntable_Speed = 0
	self.turntable_LastSpeed = 0
	self.turntableAngleZ = 0
	self.turntableFinalAngleZ = 0
	self.turntable_acce = 0
	self.isStartStop = false
	self.stopTarget = nil
	self.shouldAwarded = false
	self.alreadyAwarded = false
	self.directReturnGame = false
	self.inStop = false
	self.allAngleAfterStop = 0
	self.AllDeltaAngle = 0
	self.charSpineController = nil
	self.glowSpineController = nil
	self.breatheSequence = nil
	self.animationSequence = nil
	self.inLoadingGiftPicNum = 0
	self.backpackModel = xyd.ModelManager.get():loadModel(xyd.ModelType.BACKPACK)
	self.playerInfoModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYER_INFO)

	self:getUIComponent()
	self:registerEvents()
	self:initUIComponent()
	self:InitTurntableAwardFromWeb()
	self:initEffect()
end

function TurntableWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.turntableGroup = winTrans:NodeByName("turntable_group").gameObject
	self.rotate_part = winTrans:NodeByName("turntable_group/rotate_part").gameObject
	self.turntable_1 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_1", typeof(UISprite))
	self.item1 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_1/item1", typeof(UITexture))
	self.item2 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_1/item2", typeof(UITexture))
	self.item1_Num = winTrans:ComponentByName("turntable_group/rotate_part/turntable_1/item1_Num", typeof(UILabel))
	self.item2_Num = winTrans:ComponentByName("turntable_group/rotate_part/turntable_1/item2_Num", typeof(UILabel))
	self.nail1 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_1/nail1", typeof(UISprite))
	self.nail2 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_1/nail2", typeof(UISprite))
	self.turntable_2 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_2", typeof(UISprite))
	self.item3 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_2/item3", typeof(UITexture))
	self.item4 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_2/item4", typeof(UITexture))
	self.item3_Num = winTrans:ComponentByName("turntable_group/rotate_part/turntable_2/item3_Num", typeof(UILabel))
	self.item4_Num = winTrans:ComponentByName("turntable_group/rotate_part/turntable_2/item4_Num", typeof(UILabel))
	self.nail3 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_2/nail3", typeof(UISprite))
	self.nail4 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_2/nail4", typeof(UISprite))
	self.turntable_3 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_3", typeof(UISprite))
	self.item5 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_3/item5", typeof(UITexture))
	self.item6 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_3/item6", typeof(UITexture))
	self.item5_Num = winTrans:ComponentByName("turntable_group/rotate_part/turntable_3/item5_Num", typeof(UILabel))
	self.item6_Num = winTrans:ComponentByName("turntable_group/rotate_part/turntable_3/item6_Num", typeof(UILabel))
	self.nail5 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_3/nail5", typeof(UISprite))
	self.nail6 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_3/nail6", typeof(UISprite))
	self.turntable_4 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_4", typeof(UISprite))
	self.item7 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_4/item7", typeof(UITexture))
	self.item8 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_4/item8", typeof(UITexture))
	self.item7_Num = winTrans:ComponentByName("turntable_group/rotate_part/turntable_4/item7_Num", typeof(UILabel))
	self.item8_Num = winTrans:ComponentByName("turntable_group/rotate_part/turntable_4/item8_Num", typeof(UILabel))
	self.nail7 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_4/nail7", typeof(UISprite))
	self.nail8 = winTrans:ComponentByName("turntable_group/rotate_part/turntable_4/nail8", typeof(UISprite))
	self.center = winTrans:ComponentByName("turntable_group/fixed_part/center", typeof(UISprite))
	self.turntable_back_left = winTrans:ComponentByName("turntable_group/fixed_part/turntable_back_left", typeof(UISprite))
	self.turntable_back_right = winTrans:ComponentByName("turntable_group/fixed_part/turntable_back_right", typeof(UISprite))
	self.top_back = winTrans:ComponentByName("turntable_group/fixed_part/top_group/top_back", typeof(UISprite))
	self.Pointer = winTrans:NodeByName("turntable_group/fixed_part/top_group/Pointer").gameObject
	self.PointerImage = winTrans:ComponentByName("turntable_group/fixed_part/top_group/Pointer/PointerImage", typeof(UISprite))
	self.Balloon_left = winTrans:ComponentByName("turntable_group/fixed_part/top_group/Balloon_left", typeof(UISprite))
	self.Balloon_right = winTrans:ComponentByName("turntable_group/fixed_part/top_group/Balloon_right", typeof(UISprite))
	self.close_btn = winTrans:ComponentByName("turntable_group/fixed_part/top_group/close_btn", typeof(UISprite))
	self.bottom_back = winTrans:ComponentByName("turntable_group/fixed_part/bottom_group/bottom_back", typeof(UISprite))
	self.bottom_btn = winTrans:NodeByName("turntable_group/fixed_part/bottom_group/bottom_btn").gameObject
	self.backGround = winTrans:ComponentByName("turntable_group/fixed_part/bottom_group/bottom_btn/backGround", typeof(UISprite))
	self.freeAd_img = winTrans:ComponentByName("turntable_group/fixed_part/bottom_group/bottom_btn/freeAd_img", typeof(UISprite))
	self.GetAwardLabel = winTrans:ComponentByName("turntable_group/fixed_part/bottom_group/bottom_btn/GetAwardLabel", typeof(UILabel))
	self.giftBoxImg = winTrans:ComponentByName("turntable_group/fixed_part/bottom_group/giftBoxImg", typeof(UISprite))
	self.toplayer = winTrans:NodeByName("toplayer").gameObject
	self.charEffectLayer = winTrans:ComponentByName("charEffectLayer", typeof(UIWidget))
	self.flagEffectLayer = winTrans:ComponentByName("flagEffectLayer", typeof(UIWidget))
	self.glowEffLayer = winTrans:ComponentByName("toplayer/glowEffectLayer", typeof(UISprite))
	self.popup_reward_group = winTrans:NodeByName("toplayer/popup_reward_group").gameObject
	self.popup_reward = winTrans:ComponentByName("toplayer/popup_reward_group/popup_reward", typeof(UITexture))
	self.reward_num = winTrans:ComponentByName("toplayer/popup_reward_group/reward_num", typeof(UILabel))
	self.btnCollider = self.bottom_btn:GetComponent(typeof(UnityEngine.BoxCollider))
	self.exitBtnCollider = self.close_btn.gameObject:GetComponent(typeof(UnityEngine.BoxCollider))
	self.turntable_group = {
		self.turntable_1,
		self.turntable_2,
		self.turntable_3,
		self.turntable_4
	}
	self.item_group = {
		self.item1,
		self.item2,
		self.item3,
		self.item4,
		self.item5,
		self.item6,
		self.item7,
		self.item8
	}
	self.item_Num_group = {
		self.item1_Num,
		self.item2_Num,
		self.item3_Num,
		self.item4_Num,
		self.item5_Num,
		self.item6_Num,
		self.item7_Num,
		self.item8_Num
	}
	self.nail_group = {
		self.nail1,
		self.nail2,
		self.nail3,
		self.nail4,
		self.nail5,
		self.nail6,
		self.nail7,
		self.nail8
	}
end

function TurntableWindow:registerEvents()
	self.eventProxy_:addEventListener(xyd.event.SDK_GOOGLE_REWARD_AD, handler(self, self.RewardADEventHandler))
end

function TurntableWindow:initUIComponent()
	for i = 1, #self.turntable_group do
		xyd.setUISpriteAsync(self.turntable_group[i], MappingData.zhongjian, "zhongjian")
	end

	for i = 1, #self.nail_group do
		xyd.setUISpriteAsync(self.nail_group[i], MappingData.dingzi, "dingzi")
	end

	xyd.setUISpriteAsync(self.center, MappingData.zhongxin, "zhongxin")
	xyd.setUISpriteAsync(self.turntable_back_left, MappingData.zhuanpandi, "zhuanpandi")
	xyd.setUISpriteAsync(self.turntable_back_right, MappingData.zhuanpandi, "zhuanpandi")
	xyd.setUISpriteAsync(self.top_back, MappingData.zhuanpandi_shang, "zhuanpandi_shang")
	xyd.setUISpriteAsync(self.PointerImage, MappingData.zhizhen, "zhizhen")
	xyd.setUISpriteAsync(self.Balloon_left, MappingData.qiqiu_01, "qiqiu_01")
	xyd.setUISpriteAsync(self.Balloon_right, MappingData.qiqiu_02, "qiqiu_02")
	xyd.setUISpriteAsync(self.close_btn, MappingData.guanbi, "guanbi")
	xyd.setUISpriteAsync(self.bottom_back, MappingData.zhuanpandi_xia, "zhuanpandi_xia")
	xyd.setUISpriteAsync(self.backGround, MappingData.btn_huangchang_1, "btn_huangchang_1")
	xyd.setUISpriteAsync(self.freeAd_img, MappingData.wenzi, "wenzi")
	xyd.setUISpriteAsync(self.giftBoxImg, MappingData.libao, "libao")

	self.GetAwardLabel.text = __("GET")

	xyd.setNormalBtnBehavior(self.bottom_btn, self, self._OnClickBtn)
	xyd.setNormalBtnBehavior(self.close_btn.gameObject, self, self.onBtnExit)
	self:BottomBteBreatheControl(true)
	self.charEffectLayer:SetBottomAnchor(self.window_, 0, 0)
	self.charEffectLayer:SetTopAnchor(self.window_, 0, 750)

	self.charOldPosX = self.charEffectLayer.transform.localPosition.x
end

function TurntableWindow:AnimationControl(boolean, callback)
	local turntableTrans = self.turntableGroup.transform
	local charEffLayerTrans = self.charEffectLayer.transform

	if self.animationSequence then
		self.animationSequence:Kill(true)

		self.animationSequence = DG.Tweening.DOTween.Sequence()
	else
		self.animationSequence = DG.Tweening.DOTween.Sequence()
	end

	if boolean then
		XYDCo.WaitForFrame(1, function ()
			self.charEffectLayer:SetAnchor(nil)
		end, nil)

		turntableTrans.localScale = Vector3(0, 0, 0)

		self.animationSequence:Insert(0 * xyd.TweenDeltaTime, turntableTrans:DOScale(Vector3(1, 1, 1), 12 * xyd.TweenDeltaTime))
		self.animationSequence:Insert(12 * xyd.TweenDeltaTime, turntableTrans:DOScale(Vector3(0.98, 0.98, 0.98), 3 * xyd.TweenDeltaTime))
		self.animationSequence:Insert(15 * xyd.TweenDeltaTime, turntableTrans:DOScale(Vector3(1, 1, 1), 5 * xyd.TweenDeltaTime))
		self.animationSequence:Insert(11 * xyd.TweenDeltaTime, charEffLayerTrans:DOLocalMoveX(self.charOldPosX + 377, 4 * xyd.TweenDeltaTime))
		self.animationSequence:Insert(11 * xyd.TweenDeltaTime, charEffLayerTrans:DOLocalRotate(Vector3(0, 0, -4), 4 * xyd.TweenDeltaTime))
		self.animationSequence:Insert(15 * xyd.TweenDeltaTime, charEffLayerTrans:DOLocalMoveX(self.charOldPosX + 369, 4 * xyd.TweenDeltaTime))
		self.animationSequence:Insert(15 * xyd.TweenDeltaTime, charEffLayerTrans:DOLocalRotate(Vector3(0, 0, 3), 4 * xyd.TweenDeltaTime))
		self.animationSequence:Insert(19 * xyd.TweenDeltaTime, charEffLayerTrans:DOLocalMoveX(self.charOldPosX + 371, 5 * xyd.TweenDeltaTime))
		self.animationSequence:Insert(19 * xyd.TweenDeltaTime, charEffLayerTrans:DOLocalRotate(Vector3(0, 0, 0), 5 * xyd.TweenDeltaTime))
		self.animationSequence:OnComplete(function ()
			if callback then
				callback()
			end
		end)
	else
		local waitFlagEffectFrames = 15

		if not tolua.isnull(self.turntableFlagEff) then
			local SpineController = self.turntableFlagEff:GetComponent(typeof(SpineAnim))

			SpineController:play("texiao01", 1)
			SpineController:setReverse()
		end

		self.animationSequence:Insert((4 + waitFlagEffectFrames) * xyd.TweenDeltaTime, turntableTrans:DOScale(Vector3(0.98, 0.98, 0.98), 5 * xyd.TweenDeltaTime))
		self.animationSequence:Insert((9 + waitFlagEffectFrames) * xyd.TweenDeltaTime, turntableTrans:DOScale(Vector3(1, 1, 1), 3 * xyd.TweenDeltaTime))
		self.animationSequence:Insert((12 + waitFlagEffectFrames) * xyd.TweenDeltaTime, turntableTrans:DOScale(Vector3(0, 0, 0), 12 * xyd.TweenDeltaTime))

		local popupRewardTrans = self.toplayer.transform
		local scale = self.toplayer.transform.localScale

		self.animationSequence:Insert((4 + waitFlagEffectFrames) * xyd.TweenDeltaTime, popupRewardTrans:DOScale(scale * 0.98, 5 * xyd.TweenDeltaTime))
		self.animationSequence:Insert((9 + waitFlagEffectFrames) * xyd.TweenDeltaTime, popupRewardTrans:DOScale(scale, 3 * xyd.TweenDeltaTime))
		self.animationSequence:Insert((12 + waitFlagEffectFrames) * xyd.TweenDeltaTime, popupRewardTrans:DOScale(scale * 0, 12 * xyd.TweenDeltaTime))
		self.animationSequence:Insert((0 + waitFlagEffectFrames) * xyd.TweenDeltaTime, charEffLayerTrans:DOLocalMoveX(self.charOldPosX + 369, 5 * xyd.TweenDeltaTime))
		self.animationSequence:Insert((0 + waitFlagEffectFrames) * xyd.TweenDeltaTime, charEffLayerTrans:DOLocalRotate(Vector3(0, 0, -3), 5 * xyd.TweenDeltaTime))
		self.animationSequence:Insert((5 + waitFlagEffectFrames) * xyd.TweenDeltaTime, charEffLayerTrans:DOLocalMoveX(self.charOldPosX + 377, 4 * xyd.TweenDeltaTime))
		self.animationSequence:Insert((5 + waitFlagEffectFrames) * xyd.TweenDeltaTime, charEffLayerTrans:DOLocalRotate(Vector3(0, 0, 4), 4 * xyd.TweenDeltaTime))
		self.animationSequence:Insert((9 + waitFlagEffectFrames) * xyd.TweenDeltaTime, charEffLayerTrans:DOLocalMoveX(self.charOldPosX - 80, 4 * xyd.TweenDeltaTime))
		self.animationSequence:Insert((9 + waitFlagEffectFrames) * xyd.TweenDeltaTime, charEffLayerTrans:DOLocalRotate(Vector3(0, 0, -4), 4 * xyd.TweenDeltaTime))
		self.animationSequence:OnComplete(function ()
			if callback then
				callback()
			end
		end)
	end
end

function TurntableWindow:UIAnimation(callback)
	self:AnimationControl(true, callback)
end

function TurntableWindow:UICloseAnimation(callback)
	self:AnimationControl(false, callback)
end

function TurntableWindow:SetSpriteAward(data)
	self.inLoadingGiftPicNum = self.TURNTABLE_AWARD_KIND_NUM

	for i = 1, self.TURNTABLE_AWARD_KIND_NUM do
		local iconName = data[i].icon
		local itemNum = data[i].num
		local md5 = data[i].md5

		self:setGiftBag(self.item_group[i], iconName, md5, function ()
		end)

		self.item_Num_group[i].text = "x" .. itemNum
	end
end

function TurntableWindow:InitTurntableAwardFromWeb()
	self.turntable_Speed = 40

	UpdateBeat:Add(self.RotateTurntable, self)
	self:SetSpriteAward(self.turntableData)
end

function TurntableWindow:initEffect()
	SpineManager.get():newEffect(self.center.gameObject, "turntable_light", function (success, eff)
		if success then
			self.turntableLightEff = eff
			eff.transform.localPosition = Vector3(0, -693, 0)
			eff.transform.localScale = Vector3(100, 100, 100)
			local SpineController = eff:GetComponent(typeof(SpineAnim))
			SpineController.RenderTarget = self.center
			SpineController.timeScale = 1

			SpineController:play("texiao01", -1)
		end
	end)
	SpineManager.get():newEffect(self.flagEffectLayer.gameObject, "turntable_flag", function (success, eff)
		if success then
			self.turntableFlagEff = eff
			eff.transform.localPosition = Vector3(0, -870, 0)
			eff.transform.localScale = Vector3(100, 100, 100)
			local SpineController = eff:GetComponent(typeof(SpineAnim))
			SpineController.RenderTarget = self.center

			SpineController:play("texiao01", 1)
		end
	end)
	SpineManager.get():newEffect(self.charEffectLayer.gameObject, "turntable_char", function (success, eff)
		if success then
			self.turntableCharEff = eff
			eff.transform.localPosition = Vector3(0, -372, 0)
			eff.transform.localScale = Vector3(120, 120, 120)
			self.charSpineController = eff:GetComponent(typeof(SpineAnim))
			self.charSpineController.RenderTarget = self.center

			self.charSpineController:play("idle_pre", 1)

			local function onComplete()
				self.charSpineController:play("idle", -1)
			end

			self.charSpineController:addListener("complete", onComplete)
		end
	end)
	SpineManager.get():newEffect(self.glowEffLayer.gameObject, "turntable_reward_glow", function (success, eff)
		if success then
			self.turntableGlowEff = eff
			eff.transform.localScale = Vector3(100, 100, 100)
			self.glowSpineController = eff:GetComponent(typeof(SpineAnim))

			eff:SetActive(false)
		end
	end)
end

function TurntableWindow:_OnClickBtn()
	if not self.shouldAwarded then
		self:PlayAdvertise()
		self:BottomBtnControl(1)
		self:BottomBteBreatheControl(false)
	else
		self:onBtnExit()
	end
end

function TurntableWindow:RewardADEventHandler(event)
	__TRACE("===================== RewardADEventHandler ========== ", event.params.status)

	local status = event.params.status

	if status == 3 or status == 7 or status == 8 then
		self:AlertWindow(2)
	elseif status == 9 then
		self:RewardAdClosed()
	elseif status == 10 then
		self.shouldAwarded = true
	end
end

function TurntableWindow:HandleItemAward(ItemID, Num)
	if ItemID and Num then
		if ItemID == ItemConstants.ADD_THREE_STEPS then
			local steps = Num * 3

			self._gameMode:addExtraMoves(steps)
		elseif ItemID == ItemConstants.ADD_FIVE_STEPS or ItemID == ItemConstants.ADD_FIVE_STEPS_TIME then
			local steps = Num * 5

			self._gameMode:addExtraMoves(steps)
		elseif ItemID == ItemConstants.HALF_HOUR_STAMINA or ItemID == ItemConstants.ONE_HOUR_STAMINA or ItemID == ItemConstants.TWO_HOUR_STAMINA then
			self.backpackModel:addInfStaminaByID(ItemID)
		elseif ItemID == ItemConstants.ONE_STAMINA then
			self.playerInfoModel:addStamina(Num)
		else
			local itemTableData = ItemTable:getTableDataByItemID(ItemID)
			local expirelist = {}

			if itemTableData.valid_period and itemTableData.valid_period > 0 then
				for i = 1, Num do
					table.insert(expirelist, os.time() + itemTableData.valid_period)
				end
			end

			self.backpackModel:addItemByID(ItemID, Num, expirelist)
		end
	end
end

function TurntableWindow:GetAward()
	local url = xyd.LoadingController.get():backendURL()
	local params = {
		mid = xyd.mid.GET_TURNTABLE_REWARD,
		token = xyd.Global.token
	}

	self:ExitWindowControl(false)

	self.stopTarget = 0

	local function callback(response, success)
		if success then
			self.turntable_Speed = 400

			if not tolua.isnull(self.turntableCharEff) then
				self.charSpineController:play("spin_pre", 1)

				local function onComplete()
					self.charSpineController:play("spin", -1)
				end

				self.charSpineController:addListener("complete", onComplete)
			end

			self.stopTarget = response.payload.gift_index
			local rewards = response.payload.rewards

			for i = 1, #rewards do
				local reward = rewards[i]
				local isStepItem = self:CheckISRewardStepItem(reward.item_id)

				if isStepItem then
					self.directReturnGame = true
				end

				self:HandleItemAward(reward.item_id, reward.item_num)
			end

			xyd.SelfInfo.get():syncItem(self.backpackModel.items)

			self.alreadyAwarded = true
			xyd.MainController.get().alreadyTurntableAwarded = true

			XYDCo.WaitForTime(2, function ()
				self.isStartStop = true
			end, "")
		else
			__TRACE("error happen in GetAward")

			self.stopTarget = -1

			self:AlertWindow(1)
		end

		self:ExitWindowControl(true)
	end

	xyd.Backend.get():webRequestWithLoadSprite(url, params, callback, self.center, 20, 0, 0, 1.5, self.window_)
end

function TurntableWindow:CheckISRewardStepItem(itemID)
	for i = 1, #DirectReturnGameItemID do
		if itemID == DirectReturnGameItemID[i] then
			return true
		end
	end

	return false
end

function TurntableWindow:PlayAdvertise()
	__TRACE("/////////////////////////showGoogleRewardVideoAd /////////////////////////")
	xyd.SdkManager.get():showGoogleRewardVideoAd()
end

function TurntableWindow:BottomBteBreatheControl(value)
	if value then
		if not self.breatheSequence then
			self.breatheSequence = DG.Tweening.DOTween.Sequence()

			self.breatheSequence:Append(self.bottom_btn.transform:DOScale(self.bottom_btn.transform.localScale * 1.1, 0.5))
			self.breatheSequence:SetLoops(-1, DG.Tweening.LoopType.Yoyo)
		end
	elseif self.breatheSequence then
		self.breatheSequence:Kill(true)

		self.bottom_btn.transform.localScale = Vector3(1, 1, 1)
		self.breatheSequence = nil
	end
end

function TurntableWindow:ExitWindowControl(value)
	self.exitBtnCollider.enabled = value
end

function TurntableWindow:BottomBtnControl(opCode)
	if opCode == 1 then
		self.btnCollider.enabled = false
	elseif opCode == 2 then
		self.btnCollider.enabled = true
	elseif opCode == 3 then
		xyd.setUISpriteAsync(self.backGround, MappingData.btn_huangchang_1, "btn_huangchang_1")
		self.freeAd_img.gameObject:SetActive(true)
		self.GetAwardLabel.gameObject:SetActive(false)
	elseif opCode == 4 then
		xyd.setUISpriteAsync(self.backGround, MappingData.btn_luchang, "btn_luchang")
		self.freeAd_img.gameObject:SetActive(false)
		self.GetAwardLabel.gameObject:SetActive(true)
	end
end

function TurntableWindow:GlowEffectControl(boolean)
	if not tolua.isnull(self.turntableGlowEff) then
		self.turntableGlowEff:SetActive(true)

		self.glowSpineController.RenderTarget = self.glowEffLayer

		if boolean then
			self.glowSpineController:stop()
			self.glowSpineController:play("texiao_01", 1)
		else
			self.glowSpineController:stop()
			self.glowSpineController:play("texiao_02", -1)
		end
	end
end

function TurntableWindow:RewardAdClosed()
	if self.shouldAwarded then
		self:GetAward()
	else
		self:BottomBtnControl(2)
		self:BottomBteBreatheControl(true)
	end
end

function TurntableWindow:AlertWindow(val)
	if val == 1 then
		UIManager.ShowAlert("", __("NOT_CONNECTED"), __("RESTART"), __("WITHDRAW"), false, function (yes)
			if yes then
				self:GetAward()
			else
				self:onBtnExit()
			end
		end)
	elseif val == 2 then
		UIManager.ShowAlert("", __("NOT_CONNECTED"), __("RESTART"), __("WITHDRAW"), false, function (yes)
			if yes then
				self:PlayAdvertise()
				self:BottomBtnControl(1)
			else
				self:onBtnExit()
			end
		end)
	end
end

function TurntableWindow:GetStopParams()
	if self.stopTarget > 0 and self.stopTarget <= self.TURNTABLE_AWARD_KIND_NUM then
		local deltaAngle = (self.TURNTABLE_AWARD_KIND_NUM - self.stopTarget) * 45 - self.turntableAngleZ

		if deltaAngle < 0 then
			deltaAngle = deltaAngle + 360
		end

		local finalDeltaAngel = deltaAngle + 360 * self.CIRCLE_NUM + math.random(2, 43) - self.SLIDE_ANGLE
		self.turntableFinalAngleZ = self.turntableAngleZ + finalDeltaAngel
		self.AllDeltaAngle = finalDeltaAngel
		self.turntable_acce = -(self.turntable_Speed * self.turntable_Speed) / (2 * finalDeltaAngel)
	end
end

function TurntableWindow:setGiftBag(uiTexture, picName, md5, callback)
	self:setGiftBagInternal(uiTexture, picName, md5, callback)
end

function TurntableWindow:setGiftBagInternal(uiTexture, picName, md5, callback)
	local function onResDownloaded(texPath)
		ResCache.SetUITextureAsync(uiTexture, texPath)

		self.inLoadingGiftPicNum = self.inLoadingGiftPicNum - 1

		if self.inLoadingGiftPicNum == 0 then
			ResCache.RemoveLoadingSprite(self.center)
		end

		if callback then
			callback()
		end
	end

	if not md5 or not UNITY_ANDROID and not UNITY_IOS then
		local texPath = "Textures/TurntableGift_web/" .. picName

		onResDownloaded(texPath)
	else
		local path = "TurntableGift_web/" .. md5 .. "/" .. picName

		if FileUtils.IsResInData(string.lower(path) .. ".bytes") then
			__TRACE("ResInData ---------------------------------------", string.lower(path) .. ".bytes")
			onResDownloaded(path)
		else
			local url = XYDUtils.CdnUrl() .. "Android/" .. picName .. ".bytes." .. md5

			__TRACE(url, "gift Texture URL ============================")
			ResCache.AddLoadingSprite(self.center, 20, 0, 0, 1.5)
			ResManager.DownloadRes(url, md5, string.lower(path) .. ".bytes", function (status)
				if status == DownloadStatus.Success then
					onResDownloaded(path)
				end
			end)
		end
	end
end

function TurntableWindow:onBtnExit()
	local function callback()
		if self.directReturnGame then
			self._endGameWindow:TurntableReturn(1)
		elseif self.alreadyAwarded then
			self._endGameWindow:TurntableReturn(2)
		else
			self._endGameWindow:TurntableReturn(3)
		end
	end

	UpdateBeat:Remove(self.RotateTurntable, self)
	xyd.WindowManager.get():closeWindow("turntable_window", callback)
end

function TurntableWindow:PopupRewardAnimation()
	self.RewardSequence = DG.Tweening.DOTween.Sequence()

	self:GlowEffectControl(true)
	self.RewardSequence:Insert(0 * xyd.TweenDeltaTime, self.popup_reward_group.transform:DOScale(Vector3(2, 2, 2), 10 * xyd.TweenDeltaTime))
	self.RewardSequence:OnComplete(function ()
		self:GlowEffectControl(false)
	end)
end

function TurntableWindow:RotateTurntable()
	self.turntable_Speed = self.turntable_Speed + Time.deltaTime * self.turntable_acce

	if self.turntable_Speed <= 5 then
		self.turntable_acce = 0
	end

	local deltaAngle = (self.turntable_Speed + self.turntable_LastSpeed) / 2 * Time.deltaTime

	if self.turntable_Speed > 0 then
		self.turntableAngleZ = (self.turntableAngleZ + deltaAngle) % 360
	end

	self.turntable_LastSpeed = self.turntable_Speed

	if self.inStop then
		self.allAngleAfterStop = self.allAngleAfterStop + deltaAngle

		if self.allAngleAfterStop < self.AllDeltaAngle + self.SLIDE_ANGLE then
			self.rotate_part.transform.localEulerAngles = Vector3(0, 0, -self.turntableAngleZ)
		else
			local RealFinalAngle = self.turntableFinalAngleZ + self.SLIDE_ANGLE
			self.rotate_part.transform.localEulerAngles = Vector3(0, 0, -(RealFinalAngle % 360))
			self.turntable_Speed = 0
			local iconName = self.turntableData[self.stopTarget].icon
			local md5 = self.turntableData[self.stopTarget].md5
			local iconNum = self.turntableData[self.stopTarget].num

			self:setGiftBag(self.popup_reward, iconName, md5, nil)

			self.reward_num.text = "x" .. iconNum
			self.popup_reward_group.transform.localScale = Vector3(0.1, 0.1, 0.1)

			self:BottomBtnControl(4)
			UpdateBeat:Remove(self.RotateTurntable, self)
			XYDCo.WaitForTime(0.5, function ()
				if not tolua.isnull(self.turntableCharEff) then
					self.charSpineController:play("win_pre", 1)

					local function onComplete()
						self.charSpineController:play("win", -1)
					end

					self.charSpineController:addListener("complete", onComplete)
				end

				self.defaultBg_:GetComponent(typeof(UISprite)).depth = 40
				self.defaultBg_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
				self.backGround.depth = 50
				self.freeAd_img.depth = 51
				self.GetAwardLabel.depth = 52

				self:BottomBtnControl(2)
				self.popup_reward_group:SetActive(true)
				self:PopupRewardAnimation()
			end, "")
		end
	else
		self.rotate_part.transform.localEulerAngles = Vector3(0, 0, -self.turntableAngleZ)
	end

	if self.isStartStop then
		self:GetStopParams()

		self.inStop = true
		self.isStartStop = false
	end
end

function TurntableWindow:DestroyAllEffect()
	if not tolua.isnull(self.turntableLightEff) then
		Destroy(self.turntableLightEff)

		self.turntableLightEff = nil
	end

	if not tolua.isnull(self.turntableCharEff) then
		Destroy(self.turntableCharEff)

		self.turntableCharEff = nil
	end

	if not tolua.isnull(self.turntableFlagEff) then
		Destroy(self.turntableFlagEff)

		self.turntableFlagEff = nil
	end

	if not tolua.isnull(self.turntableGlowEff) then
		Destroy(self.turntableGlowEff)

		self.turntableGlowEff = nil
	end
end

function TurntableWindow:dispose()
	if self.breatheSequence then
		self.breatheSequence:Kill(false)
	end

	if self.animationSequence then
		self.animationSequence:Kill(false)
	end

	if self.RewardSequence then
		self.RewardSequence:Kill(false)
	end

	self:DestroyAllEffect()
	TurntableWindow.super.dispose(self)
end

return TurntableWindow
