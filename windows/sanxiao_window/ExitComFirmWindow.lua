local ExitComFirmWindow = class("ExitComFirmWindow", import(".BaseWindow"))
local MappingData = xyd.MappingData

function ExitComFirmWindow:ctor(name, params)
	ExitComFirmWindow.super.ctor(self, name, params)

	self._needPopup = false
	self._needPopupClearStreak = false
	self._selfLevel = 1
	self.params_ = params
	self.stageLevel_ = params.stageLevel
	self._selfLevel = xyd.SelfInfo.get():getCurrentLevel()
	self.twenn = nil
end

function ExitComFirmWindow:initWindow()
	ExitComFirmWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
end

function ExitComFirmWindow:getUIComponent()
	local winTrans = self.window_.transform
	self._continueBtn = winTrans:NodeByName("e:Skin/group_bg/_continueBtn").gameObject
	self._returnBtn = winTrans:NodeByName("e:Skin/group_bg/_returnBtn").gameObject
	self._closeBtn = winTrans:NodeByName("e:Skin/group_bg/_closeBtn").gameObject
	self.group_bg = winTrans:NodeByName("e:Skin/group_bg").gameObject
	self.group_bg.transform:ComponentByName("title1", typeof(UILabel)).text = __("QUIT_TITLE")
	self.group_bg.transform:ComponentByName("_targetGroup/title2", typeof(UILabel)).text = __("QUIT_TIPS")
	self._continueBtn.transform:ComponentByName("label", typeof(UILabel)).text = __("CONTINUE")
	self._returnBtn.transform:ComponentByName("label", typeof(UILabel)).text = __("EXIT_GAME")
	self.group_clearstreak = winTrans:NodeByName("e:Skin/group_clearstreak").gameObject
	self.inBubbleGroup = winTrans:NodeByName("e:Skin/group_clearstreak/inBubbleGroup").gameObject
	self.bubbleBig = winTrans:ComponentByName("e:Skin/group_clearstreak/bubbleBig", typeof(UISprite))
	self.bubbleSmall = winTrans:ComponentByName("e:Skin/group_clearstreak/bubbleSmall", typeof(UISprite))
	self.anna = winTrans:ComponentByName("e:Skin/group_clearstreak/anna", typeof(UISprite))

	xyd.setUISpriteAsync(self.anna, MappingData.girl5, "girl5")

	self._icon_reward = winTrans:ComponentByName("e:Skin/group_clearstreak/inBubbleGroup/_icon_reward", typeof(UISprite))
	self._label_desc = winTrans:ComponentByName("e:Skin/group_clearstreak/inBubbleGroup/_label_desc", typeof(UILabel))
	self._label_desc.text = __("EXIT_CONFIRM_CLEARSTREAK_TIPS")
end

function ExitComFirmWindow:initUIComponent()
	local gameWin = xyd.WindowManager.get():getWindow("game_window")

	if gameWin ~= nil then
		self.bg_target = gameWin.target_panel.transform:NodeByName("bg_target").gameObject
		self.group_target = gameWin.target_panel.transform:NodeByName("group_target").gameObject

		self.bg_target.transform:SetParent(self.window_.transform, true)
		self.group_target.transform:SetParent(self.window_.transform, true)

		local pos1 = self.bg_target.transform.localPosition
		self.bg_target.transform.localPosition = Vector3(pos1.x, pos1.y, 0)
		local pos2 = self.group_target.transform.localPosition
		self.group_target.transform.localPosition = Vector3(pos2.x, pos2.y, 0)

		self.bg_target:SetActive(false)
		self.group_target:SetActive(false)
		self.bg_target:SetActive(true)
		self.group_target:SetActive(true)
	end

	xyd.setDarkenBtnBehavior(self._continueBtn, self, self.onClose)
	xyd.setDarkenBtnBehavior(self._returnBtn, self, self.onExit)
	xyd.setDarkenBtnBehavior(self._closeBtn, self, self.onClose)
	self:setDefaultBgClick(function ()
		self:onClose()
	end)
	self:initClearStreakInfo()
end

function ExitComFirmWindow:initClearStreakInfo()
	local clearStreakNum = xyd.SelfInfo.get():getClearStreak()

	if clearStreakNum >= 1 then
		self._needPopupClearStreak = true
		local num = math.min(5, clearStreakNum)

		xyd.setUISpriteAsync(self._icon_reward, MappingData["icon_jiangli" .. tostring(num)], "icon_jiangli" .. tostring(num), function ()
			self._icon_reward:MakePixelPerfect()
		end)
	end

	self.group_clearstreak:SetActive(false)
end

function ExitComFirmWindow:onCloseAnimation(callback)
	if self.tween and not tolua.isnull(self.tween) then
		self.tween.timeScale = 3

		self.tween:PlayBackwards()

		local sequence = DG.Tweening.DOTween.Sequence()

		sequence:InsertCallback(0.5, function ()
			callback()
		end)
	else
		callback()
	end
end

function ExitComFirmWindow:onClose()
	self._continueBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self._closeBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

	self:setDefaultBgClick(nil)

	local function onComplete()
		local gameWin = xyd.WindowManager.get():getWindow("game_window")

		if gameWin ~= nil then
			self.bg_target.transform:SetParent(gameWin.target_panel.transform, true)
			self.group_target.transform:SetParent(gameWin.target_panel.transform, true)

			local pos1 = self.bg_target.transform.localPosition
			self.bg_target.transform.localPosition = Vector3(pos1.x, pos1.y, 0)
			local pos2 = self.group_target.transform.localPosition
			self.group_target.transform.localPosition = Vector3(pos2.x, pos2.y, 0)
		end

		self:close()
	end

	self:onCloseAnimation(onComplete)
end

function ExitComFirmWindow:onExit()
	if self._needPopupClearStreak and not self.group_clearstreak.activeSelf then
		self:_onExitAnimation()
	else
		local function onComplete()
			self:close()
			xyd.EventDispatcher.inner():dispatchEvent({
				name = xyd.event.CLICK_EXIT_BTN,
				params = {}
			})
		end

		self:onCloseAnimation(onComplete)
	end
end

function ExitComFirmWindow:_onExitAnimation()
	local group = self.group_clearstreak
	local big = self.bubbleBig
	local small = self.bubbleSmall
	local anna = self.anna
	local inbub = self.inBubbleGroup:GetComponent(typeof(UIWidget))

	group:SetActive(true)

	local scale_big = big.transform.localScale.x
	local sequence = DG.Tweening.DOTween.Sequence()
	sequence.timeScale = 2
	anna.alpha = 0

	local function annasetter(value)
		anna.color = value
	end

	local function annagetter()
		return anna.color
	end

	sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(annagetter, annasetter, 1, 8 * xyd.TweenDeltaTime))

	big.alpha = 0

	local function bigsetter(value)
		big.color = value
	end

	local function biggetter()
		return big.color
	end

	sequence:Insert(24 * xyd.TweenDeltaTime, DG.Tweening.DOTween.ToAlpha(biggetter, bigsetter, 1, 9 * xyd.TweenDeltaTime))

	local scale_big = big.transform.localScale.x
	big.transform.localScale = Vector3(0.78, 0.78, 1)

	sequence:Insert(24 * xyd.TweenDeltaTime, big.transform:DOScale(Vector3(scale_big * 1.015, scale_big * 1.015, 1), 9 * xyd.TweenDeltaTime))
	sequence:Insert(33 * xyd.TweenDeltaTime, big.transform:DOScale(Vector3(scale_big, scale_big, 1), 12 * xyd.TweenDeltaTime))

	small.alpha = 0

	local function smallsetter(value)
		small.color = value
	end

	local function smallgetter()
		return small.color
	end

	sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(smallgetter, smallsetter, 1, 3 * xyd.TweenDeltaTime))

	local scale_small = small.transform.localScale.x
	small.transform.localScale = Vector3(0.5, 0.5, 1)

	sequence:Insert(3 * xyd.TweenDeltaTime, small.transform:DOScale(Vector3(scale_small * 1.06, scale_small * 1.06, 1), 9 * xyd.TweenDeltaTime))
	sequence:Insert(12 * xyd.TweenDeltaTime, small.transform:DOScale(Vector3(scale_small, scale_small, 1), 9 * xyd.TweenDeltaTime))

	inbub.alpha = 0

	local function inbubsetter(value)
		inbub.color = value
	end

	local function inbubgetter()
		return inbub.color
	end

	sequence:Insert(24 * xyd.TweenDeltaTime, DG.Tweening.DOTween.ToAlpha(inbubgetter, inbubsetter, 1, 6 * xyd.TweenDeltaTime))

	self.tween = sequence

	sequence:SetAutoKill(false)
end

function ExitComFirmWindow:dispose()
	if self.tween and not tolua.isnull(self.tween) then
		self.tween:Kill()
	end

	ExitComFirmWindow.super.dispose(self)
end

return ExitComFirmWindow
