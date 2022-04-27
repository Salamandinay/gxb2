local LetterWindow = class("LetterWindow", import(".BaseWindow"))
local EffectConstants = xyd.EffectConstants
local SpineManager = xyd.SpineManager

function LetterWindow:ctor(name, params)
	LetterWindow.super.ctor(self, name, params)

	self._usingTimelines = {}

	if params and params.on_complete then
		self._onComplete = params.on_complete
	end
end

function LetterWindow:initWindow()
	LetterWindow.super.initWindow()
	self:getUIComponent()

	local width = xyd.getFixedWidth()
	local height = xyd.getFixedHeight()

	if height / width > 1.7777777777777777 then
		self.bg_exit_.transform.localScale = Vector3(height / 1920, height / 1920, 1)
		self.bg_pre.transform.localScale = Vector3(height / 1920, height / 1920, 1)
	elseif height / width < 1.7777777777777777 then
		self.bg_exit_.transform.localScale = Vector3(width / 1080, width / 1080, 1)
		self.bg_pre.transform.localScale = Vector3(width / 1080, width / 1080, 1)
	end

	self:initUIComponent()
end

function LetterWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.group_eff = winTrans:NodeByName("e:Skin/group_eff").gameObject
	self.group_all = winTrans:ComponentByName("e:Skin/group_all", typeof(UIWidget))
	self.text_1 = winTrans:ComponentByName("e:Skin/text_1", typeof(UISprite))
	self.text_2 = winTrans:ComponentByName("e:Skin/text_2", typeof(UISprite))
	self._quitBtn = winTrans:NodeByName("e:Skin/group_all/_quitBtn").gameObject
	self.bg_exit_ = winTrans:ComponentByName("e:Skin/bg_exit_", typeof(UITexture))
	self.bg_pre = winTrans:ComponentByName("e:Skin/bg_pre", typeof(UISprite))
end

function LetterWindow:initUIComponent()
	xyd.setUITextureAsync(self.bg_exit_, "Textures/Game_web/earth")

	local sequence = DG.Tweening.DOTween.Sequence()

	table.insert(self._usingTimelines, sequence)

	self.text_1.transform.localPosition = Vector3(self.text_1.transform.localPosition.x, -480 - (xyd.getFixedHeight() / 2 - 480) / 2 + 60)
	self.text_2.transform.localPosition = Vector3(self.text_2.transform.localPosition.x, self.text_1.transform.localPosition.y - 90)
	self.text_1.alpha = 0
	self.text_2.alpha = 0

	local function text1_setter(value)
		self.text_1.color = value
	end

	local function text1_getter()
		return self.text_1.color
	end

	local function text2_setter(value)
		self.text_2.color = value
	end

	local function text2_getter()
		return self.text_2.color
	end

	local function letterAnimation()
		xyd.SoundManager.get():playVoice("dad_read_letter")

		self.group_all.transform.localScale = Vector3(0.5, 0.5, 1)

		local function setter(value)
			self.group_all.color = value
		end

		local function getter()
			return self.group_all.color
		end

		local sequence2 = DG.Tweening.DOTween.Sequence()

		table.insert(self._usingTimelines, sequence2)
		sequence2:Append(self.group_all.transform:DOScale(Vector3(1, 1, 1), 20 * xyd.TweenDeltaTime))
		sequence2:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 20 * xyd.TweenDeltaTime))
		sequence2:AppendCallback(function ()
			xyd.setNormalBtnBehavior(self._quitBtn, self, self.onBtnExit)
		end)
	end

	sequence:Insert(20 * xyd.TweenDeltaTime, DG.Tweening.DOTween.ToAlpha(text1_getter, text1_setter, 1, 60 * xyd.TweenDeltaTime))
	sequence:Insert(80 * xyd.TweenDeltaTime, DG.Tweening.DOTween.ToAlpha(text2_getter, text2_setter, 1, 60 * xyd.TweenDeltaTime))
	sequence:AppendCallback(function ()
		local effname = EffectConstants.LATTER

		if effname then
			SpineManager.get():newEffect(self.group_eff, effname, function (success, eff)
				if success then
					self._letterEff = eff
					eff.transform.localScale = Vector3(100, 100, 100)
					local SpineController = eff:GetComponent(typeof(SpineAnim))
					SpineController.RenderTarget = self.text_1
					SpineController.targetDelta = 2

					SpineController:play("texiao01", 1)

					local onComplete = nil

					function onComplete()
						UnityEngine.Object.Destroy(eff)
						letterAnimation()
					end

					SpineController:addListener("complete", onComplete)
				else
					letterAnimation()
				end
			end)
		end
	end)
end

function LetterWindow:onBtnExit()
	xyd.SoundManager.get():playVoice("blank")
	xyd.WindowManager.get():closeWindow("letter_window")

	xyd.SelfInfo.get().letterCompleted = true

	if xyd.SelfInfo.get().mapInitCompleted then
		xyd.QuestController.get():startQuestStory()
	end
end

function LetterWindow:willClose()
	if self.isDisposed_ then
		return
	end

	if self._onComplete then
		self:_onComplete()
	end

	self._onComplete = nil

	LetterWindow.super.willClose(self)
end

function LetterWindow:dispose()
	for _, sq in ipairs(self._usingTimelines) do
		sq:Kill(true)
	end

	if self._letterEff ~= nil and not tolua.isnull(self._letterEff) then
		UnityEngine.Object.Destroy(self._letterEff)

		self._letterEff = nil
	end

	LetterWindow.super.dispose(self)
end

return LetterWindow
