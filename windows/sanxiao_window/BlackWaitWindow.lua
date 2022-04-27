local BlackWaitWindow = class("BlackWaitWindow", import(".BaseWindow"))

function BlackWaitWindow:ctor(name, params)
	BlackWaitWindow.super.ctor(self, name, params)
end

function BlackWaitWindow:initWindow()
	BlackWaitWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
end

function BlackWaitWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.bg = winTrans:ComponentByName("bg", typeof(UISprite))
	self.wait_text = winTrans:ComponentByName("wait_text", typeof(UILabel))
end

function BlackWaitWindow:initUIComponent()
	self.wait_text.text = __("BLACK_WAIT_TEXT")
end

function BlackWaitWindow:UIAnimation()
	self.sequence = DG.Tweening.DOTween.Sequence()

	self.wait_text.gameObject:SetActive(true)

	local timeNum = 40
	self.wait_text.alpha = 0

	local function textGetter()
		return self.wait_text.color
	end

	local function textSetter(value)
		self.wait_text.color = value
	end

	self.sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(textGetter, textSetter, 1, timeNum * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	self.sequence:Insert(timeNum * xyd.TweenDeltaTime, DG.Tweening.DOTween.ToAlpha(textGetter, textSetter, 0, timeNum * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	self.sequence:OnComplete(function ()
		self:close()
	end)
end

function BlackWaitWindow:close()
	xyd.WindowManager.get():closeWindow("black_wait_window")
end

function BlackWaitWindow:dispose()
	if self.sequence then
		self.sequence:Kill(true)

		self.sequence = nil
	end

	BlackWaitWindow.super.dispose(self)
end

return BlackWaitWindow
