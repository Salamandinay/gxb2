local ActivitySpaceExploreBattleWindow = class("ActivitySpaceExploreBattleWindow", import(".BaseWindow"))
local PngNum = import("app.components.PngNum")

function ActivitySpaceExploreBattleWindow:ctor(name, params)
	self.grid_id = params.grid_id
	self.self_blood = params.self_blood
	self.self_atk = params.self_atk
	self.self_arm = params.self_arm
	self.is_win = params.is_win
	self.monster_id = params.monster_id
	self.callBack = params.callBack
	self.items = params.items

	function params.playOpenAnimationTweenCal(alpha)
		if self.partner_spine then
			self.partner_spine:setAlpha(alpha)
		end

		if self.monster_spine then
			self.monster_spine:setAlpha(alpha)
		end
	end

	function params.playCloseAnimationTweenCal(alpha)
		if self.partner_spine then
			self.partner_spine:setAlpha(alpha)
		end

		if self.monster_spine then
			self.monster_spine:setAlpha(alpha)
		end
	end

	ActivitySpaceExploreBattleWindow.super.ctor(self, name, params)

	local partner_id = xyd.tables.miscTable:getNumber("space_explore_begin_partner", "value")
	local partner_model_id = xyd.tables.activitySpaceExplorePartnerTable:getPartnerModel(partner_id)
	local partner_model_name = xyd.tables.modelTable:getModelName(partner_model_id)
	local monster_model_id = xyd.tables.activitySpaceExploreMonsterTable:getPartnerModel(self.monster_id)
	local monster_model_name = xyd.tables.modelTable:getModelName(monster_model_id)
	local needLoadRes = xyd.getEffectFilesByNames({
		partner_model_name,
		monster_model_name
	})

	self:setResourcePaths(needLoadRes)
end

function ActivitySpaceExploreBattleWindow:initWindow()
	self.tweenArr = {}

	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ActivitySpaceExploreBattleWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.bg_left = self.groupAction:ComponentByName("bg_left", typeof(UISprite))
	self.bg_left_mask = self.bg_left:ComponentByName("bg_left_mask", typeof(UISprite))
	self.bg_right = self.groupAction:ComponentByName("bg_right", typeof(UISprite))
	self.bg_right_mask = self.bg_right:ComponentByName("bg_right_mask", typeof(UISprite))
	self.leftPersonItem = self.groupAction:NodeByName("leftPersonItem").gameObject
	self.left_personEffect = self.leftPersonItem:ComponentByName("personEffect", typeof(UITexture))
	self.left_stateShowCon = self.leftPersonItem:NodeByName("stateShowCon").gameObject
	self.left_stateShowBg = self.left_stateShowCon:ComponentByName("stateShowBg", typeof(UISprite))
	self.left_bloodCon = self.left_stateShowCon:NodeByName("bloodCon").gameObject
	self.left_bloodIcon = self.left_bloodCon:ComponentByName("bloodIcon", typeof(UISprite))
	self.left_bloodLabel = self.left_bloodCon:ComponentByName("bloodLabel", typeof(UILabel))
	self.left_powerCon = self.left_stateShowCon:NodeByName("powerCon").gameObject
	self.left_powerIcon = self.left_powerCon:ComponentByName("powerIcon", typeof(UISprite))
	self.left_powerLabel = self.left_powerCon:ComponentByName("powerLabel", typeof(UILabel))
	self.left_guardCon = self.left_stateShowCon:NodeByName("guardCon").gameObject
	self.left_guardIcon = self.left_guardCon:ComponentByName("guardIcon", typeof(UISprite))
	self.left_guardLabel = self.left_guardCon:ComponentByName("guardLabel", typeof(UILabel))
	self.left_pngNumCon = self.leftPersonItem:NodeByName("pngNumCon").gameObject
	self.rightPersonItem = self.groupAction:NodeByName("rightPersonItem").gameObject
	self.right_personEffect = self.rightPersonItem:ComponentByName("personEffect", typeof(UITexture))
	self.right_stateShowCon = self.rightPersonItem:NodeByName("stateShowCon").gameObject
	self.right_stateShowBg = self.right_stateShowCon:ComponentByName("stateShowBg", typeof(UISprite))
	self.right_bloodCon = self.right_stateShowCon:NodeByName("bloodCon").gameObject
	self.right_bloodIcon = self.right_bloodCon:ComponentByName("bloodIcon", typeof(UISprite))
	self.right_bloodLabel = self.right_bloodCon:ComponentByName("bloodLabel", typeof(UILabel))
	self.right_powerCon = self.right_stateShowCon:NodeByName("powerCon").gameObject
	self.right_powerIcon = self.right_powerCon:ComponentByName("powerIcon", typeof(UISprite))
	self.right_powerLabel = self.right_powerCon:ComponentByName("powerLabel", typeof(UILabel))
	self.right_guardCon = self.right_stateShowCon:NodeByName("guardCon").gameObject
	self.right_guardIcon = self.right_guardCon:ComponentByName("guardIcon", typeof(UISprite))
	self.right_guardLabel = self.right_guardCon:ComponentByName("guardLabel", typeof(UILabel))
	self.right_pngNumCon = self.rightPersonItem:NodeByName("pngNumCon").gameObject
	self.vsImg = self.groupAction:ComponentByName("vsImg", typeof(UISprite))
	self.allBg = self.groupAction:ComponentByName("allBg", typeof(UISprite))
	self.tipsLabel = self.groupAction:ComponentByName("tipsLabel", typeof(UILabel))
end

function ActivitySpaceExploreBattleWindow:registerEvent()
	UIEventListener.Get(self.allBg.gameObject).onClick = handler(self, function ()
		if self.notClickAllBg then
			return
		end

		if self.closeYet then
			return
		end

		local timeStamp = xyd.db.misc:getValue("activity_space_explore_time_stamp")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime()) then
			self:stopBattle()
			xyd.openWindow("gamble_tips_window", {
				type = "activity_space_explore",
				isNoESC = true,
				text = __("SPACE_EXPLORE_TEXT_15"),
				callback = function ()
					self:battleOver()
				end,
				closeFun = function ()
					self:resumeBattle()
				end
			})
		elseif not self.notClickAllBg then
			self:stopBattle()
			self:waitForFrame(5, function ()
				self:battleOver()
			end)
		end
	end)
end

function ActivitySpaceExploreBattleWindow:layout()
	xyd.setUISpriteAsync(self.bg_left, nil, "activity_space_explore_bg_vs_1", nil, )
	xyd.setUISpriteAsync(self.bg_right, nil, "activity_space_explore_bg_vs_2", nil, )

	self.tipsLabel.text = __("SPACE_EXPLORE_TEXT_14")
	self.leftPngNumArr = {}

	for i = 1, 4 do
		local pngNum = PngNum.new(self.left_pngNumCon)
		pngNum.scale = 0.9
		pngNum:getGameObject():GetComponent(typeof(UIWidget)).alpha = 0.015

		table.insert(self.leftPngNumArr, pngNum)
	end

	self.rightPngNumArr = {}

	for i = 1, 4 do
		local pngNum = PngNum.new(self.right_pngNumCon)
		pngNum.scale = 0.9
		pngNum:getGameObject():GetComponent(typeof(UIWidget)).alpha = 0.015

		table.insert(self.rightPngNumArr, pngNum)
	end

	local partner_id = xyd.tables.miscTable:getNumber("space_explore_begin_partner", "value")
	local partner_model_id = xyd.tables.activitySpaceExplorePartnerTable:getPartnerModel(partner_id)
	local partner_model_name = xyd.tables.modelTable:getModelName(partner_model_id)
	local partner_model_scale = xyd.tables.modelTable:getScale(partner_model_id)
	self.partner_spine = xyd.Spine.new(self.left_personEffect.gameObject)

	self.partner_spine:setInfo(partner_model_name, function ()
		self.partner_spine:setRenderTarget(nil, 5)
		self.partner_spine:play("idle", 0)
		self.partner_spine:SetLocalScale(partner_model_scale, partner_model_scale, partner_model_scale)

		self.left_effect_ok = true

		if self.isStop then
			local left_spineAnim = self.partner_spine:getGameObject():GetComponent(typeof(SpineAnim))

			if left_spineAnim then
				left_spineAnim:pause()
			end
		end
	end)

	local monster_model_id = xyd.tables.activitySpaceExploreMonsterTable:getPartnerModel(self.monster_id)
	local monster_model_name = xyd.tables.modelTable:getModelName(monster_model_id)
	local monster_model_scale = xyd.tables.modelTable:getScale(monster_model_id)
	self.monster_spine = xyd.Spine.new(self.right_personEffect.gameObject)

	self.monster_spine:setInfo(monster_model_name, function ()
		self.monster_spine:setRenderTarget(nil, 10)
		self.monster_spine:play("idle", 0)
		self.monster_spine:SetLocalScale(monster_model_scale, monster_model_scale, monster_model_scale)

		self.right_effect_ok = true

		if self.isStop then
			local right_spineAnim = self.monster_spine:getGameObject():GetComponent(typeof(SpineAnim))

			if right_spineAnim then
				right_spineAnim:pause()
			end
		end
	end)

	self.enemy_hp = xyd.tables.activitySpaceExploreMonsterTable:getHp(self.monster_id)
	self.enemy_atk = xyd.tables.activitySpaceExploreMonsterTable:getAtk(self.monster_id)
	self.enemy_arm = xyd.tables.activitySpaceExploreMonsterTable:getArm(self.monster_id)
	self.left_bloodLabel.text = self.self_blood
	self.left_powerLabel.text = self.self_atk
	self.left_guardLabel.text = self.self_arm
	self.right_bloodLabel.text = self.enemy_hp
	self.right_powerLabel.text = self.enemy_atk
	self.right_guardLabel.text = self.enemy_arm
	local base_hurt = xyd.tables.miscTable:getNumber("space_explore_damage_min", "value")
	self.real_self_atk = math.max(base_hurt, self.self_atk - self.enemy_arm)
	self.real_enemy_atk = math.max(base_hurt, self.enemy_atk - self.self_arm)

	self:checkEffectOK()
end

function ActivitySpaceExploreBattleWindow:checkEffectOK()
	self:waitForTime(1, function ()
		if not self.isStop then
			if self.left_effect_ok and self.right_effect_ok then
				self.isStart = true

				self:battleRound()
			else
				self:checkEffectOK()
			end
		end
	end)
end

function ActivitySpaceExploreBattleWindow:battleRound()
	local left_tween = self:getSequence()

	self.partner_spine:play("attack", 1)
	left_tween:Append(self.left_personEffect.gameObject.transform:DOLocalMove(Vector3(68, -73, 0), 0.5))
	left_tween:AppendCallback(function ()
		local old_blood = self.self_blood
		self.self_blood = self.self_blood - self.real_enemy_atk

		if self.self_blood < 0 then
			self.self_blood = 0
		end

		local new_blood = self.self_blood
		local blood_dis = new_blood - old_blood

		self:hurt("left", blood_dis)

		self.left_bloodLabel.text = self.self_blood

		left_tween:Kill(true)

		local new_left_tween = self:getSequence()

		new_left_tween:Append(self.left_personEffect.gameObject.transform:DOLocalMove(Vector3(-50, -20, 0), 0.5))
		new_left_tween:AppendCallback(function ()
			if self.self_blood <= 0 then
				self.partner_spine:stop()
				self.partner_spine:play("idle", 0)
				self:playOverShow()
			elseif self.enemy_hp > 0 and self.self_blood > 0 then
				self:battleRound()
			else
				self.partner_spine:stop()
				self.partner_spine:play("idle", 0)
				self:playOverShow()
			end

			new_left_tween:Kill(true)
		end)
	end)

	local right_tween = self:getSequence()

	self.monster_spine:play("attack", 1)
	right_tween:Append(self.right_personEffect.gameObject.transform:DOLocalMove(Vector3(3, 101, 0), 0.5))
	right_tween:AppendCallback(function ()
		local old_blood = self.enemy_hp
		self.enemy_hp = self.enemy_hp - self.real_self_atk

		if self.enemy_hp < 0 then
			self.enemy_hp = 0
		end

		local new_blood = self.enemy_hp
		local blood_dis = new_blood - old_blood

		self:hurt("right", blood_dis)

		self.right_bloodLabel.text = self.enemy_hp

		right_tween:Append(self.right_personEffect.gameObject.transform:DOLocalMove(Vector3(90, 0, 0), 0.5))
		right_tween:Kill(true)

		local new_right_tween = self:getSequence()

		new_right_tween:AppendCallback(function ()
			if self.enemy_hp <= 0 then
				self.monster_spine:stop()
				self.monster_spine:play("idle", 0)
			elseif self.enemy_hp <= 0 or self.self_blood <= 0 then
				self.monster_spine:stop()
				self.monster_spine:play("idle", 0)
			end

			new_right_tween:Kill(true)
		end)
	end)
end

function ActivitySpaceExploreBattleWindow:hurt(state, num)
	local arr = nil

	if state == "left" then
		arr = self.leftPngNumArr
	elseif state == "right" then
		arr = self.rightPngNumArr
	end

	for i, pngNum in pairs(arr) do
		if pngNum:getGameObject():GetComponent(typeof(UIWidget)).alpha <= 0.015 then
			pngNum:setInfo({
				isShowAdd = true,
				iconName = "battle_crit",
				num = num
			})
			pngNum:getGameObject():X(math.random() * 100 - 50)
			pngNum:getGameObject():Y(math.random() * 60 - 20)

			pngNum:getGameObject():GetComponent(typeof(UIWidget)).alpha = 1

			self:hurtTween(pngNum)

			break
		end
	end
end

function ActivitySpaceExploreBattleWindow:hurtTween(png_num)
	local scaleX = 1
	local scaleY = 1
	local action = self:getSequence()
	local transform = png_num:getGameObject().transform
	local x_ = transform.localPosition.x
	local y_ = transform.localPosition.y
	local w = png_num:getGameObject():GetComponent(typeof(UIWidget))

	local function getter()
		return w.color
	end

	local function setter(value)
		w.color = value
	end

	action:Append(transform:DOScale(Vector3(scaleX * 1.25, scaleY * 1.25, 1), 0.067))
	action:Append(transform:DOScale(Vector3(scaleX * 0.9, scaleY * 0.9, 1), 0.1))
	action:Append(transform:DOScale(Vector3(scaleX * 1.05, scaleY * 1.05, 1), 0.1))
	action:Append(transform:DOScale(Vector3(scaleX * 0.95, scaleY * 0.95, 1), 0.067))
	action:Append(transform:DOScale(Vector3(scaleX, scaleY, 1), 0.067))
	action:AppendInterval(0.1)

	local tween = DG.Tweening.DOTween.ToAlpha(getter, setter, 0.3, 0.8)

	table.insert(self.tweenArr, tween)
	action:Append(tween)
	action:Join(transform:DOLocalMove(Vector3(x_, y_ + 40, 0), 0.8))
	action:AppendCallback(function ()
		action:Kill(true)

		w.alpha = 0.015
	end)
end

function ActivitySpaceExploreBattleWindow:playOverShow()
	self.notClickAllBg = true
	local vs_tween = self:getSequence()

	vs_tween:Append(self.vsImg.transform:DOScale(Vector3(0, 0, 0), 0.2))
	vs_tween:AppendCallback(function ()
		vs_tween:Kill(true)

		if self.self_blood <= 0 then
			xyd.setUISpriteAsync(self.bg_left, nil, "activity_space_explore_bg_vs_1_1", nil, )
			self.bg_left_mask:SetActive(true)
		end

		if self.enemy_hp <= 0 then
			xyd.setUISpriteAsync(self.bg_right, nil, "activity_space_explore_bg_vs_2_2", nil, )
			self.bg_right_mask:SetActive(true)
		end

		self:waitForTime(0.2, function ()
			self:battleOver()
		end)
	end)
end

function ActivitySpaceExploreBattleWindow:battleOver()
	for i in pairs(self.tweenArr) do
		if self.tweenArr[i] then
			self.tweenArr[i]:Pause()
			self.tweenArr[i]:Kill(true)
		end
	end

	if self.is_win == 1 then
		xyd.WindowManager.get():openWindow("battle_win_window", {
			battleParams = {
				items = self.items
			},
			battle_type = xyd.BattleType.ACTIVITY_SPACE_EXPLORE,
			closeCallBack = self.callBack
		})
	elseif self.is_win == 0 then
		xyd.WindowManager.get():openWindow("battle_fail_window", {
			battleParams = {},
			battle_type = xyd.BattleType.ACTIVITY_SPACE_EXPLORE,
			closeCallBack = self.callBack
		})
	end

	self.window_.gameObject:GetComponent(typeof(UIPanel)).alpha = 0.02

	if self.left_personEffect and self.left_personEffect.gameObject then
		self.left_personEffect.gameObject:SetActive(false)
	end

	if self.right_personEffect and self.right_personEffect.gameObject then
		self.right_personEffect.gameObject:SetActive(false)
	end

	self.closeYet = true

	self:waitForFrame(20, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function ActivitySpaceExploreBattleWindow:willClose()
	ActivitySpaceExploreBattleWindow.super.willClose(self)
end

function ActivitySpaceExploreBattleWindow:resumeBattle()
	if not self.isStop then
		return
	end

	self.isStop = false

	if self.left_effect_ok then
		local left_spineAnim = self.partner_spine:getGameObject():GetComponent(typeof(SpineAnim))

		if left_spineAnim then
			left_spineAnim:resume()
		end
	end

	if self.right_effect_ok then
		local right_spineAnim = self.monster_spine:getGameObject():GetComponent(typeof(SpineAnim))

		if right_spineAnim then
			right_spineAnim:resume()
		end
	end

	for i in pairs(self.sequence_) do
		if self.sequence_[i] then
			self.sequence_[i]:Play()
		end
	end

	for i = 1, #self.timers_ do
		local timer = self.timers_[i]

		timer:Start()
	end

	if not self.isStart then
		self:checkEffectOK()
	end
end

function ActivitySpaceExploreBattleWindow:stopBattle()
	if self.isStop then
		return
	end

	self.isStop = true

	if self.left_effect_ok then
		local left_spineAnim = self.partner_spine:getGameObject():GetComponent(typeof(SpineAnim))

		if left_spineAnim then
			left_spineAnim:pause()
		end
	end

	if self.right_effect_ok then
		local right_spineAnim = self.monster_spine:getGameObject():GetComponent(typeof(SpineAnim))

		if right_spineAnim then
			right_spineAnim:pause()
		end
	end

	for i in pairs(self.sequence_) do
		if self.sequence_[i] then
			self.sequence_[i]:Pause()
		end
	end

	for i = 1, #self.waitForTimeKeys_ do
		XYDCo.StopWait(self.waitForTimeKeys_[i])
	end

	self.waitForTimeKeys_ = {}
end

return ActivitySpaceExploreBattleWindow
