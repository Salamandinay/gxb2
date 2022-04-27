local GameModeConstants = xyd.GameModeConstants
local CellConstants = xyd.CellConstants
local MainController = xyd.MainController
local DisplayConstants = xyd.DisplayConstants
local LevelTable = xyd.tables.level
local SpineManager = xyd.SpineManager
local LoadingComponent = class("LoadingComponent", import(".BaseWindow"))

function LoadingComponent:ctor(name, params)
	LoadingComponent.super.ctor(self, name, params)
end

function LoadingComponent:initWindow()
	LoadingComponent.super.initWindow(self)
	self:initEvents()
	self:initUIComponent()
end

function LoadingComponent:initEvents()
	if not self.eventProxy_ then
		self.eventProxy_ = xyd.EventProxy.new(xyd.EventDispatcher.inner(), self)
	end

	self:_addEvent(xyd.event.LOADING_DOWN_START, self.loadingStart, self)
	self:_addEvent(xyd.event.LOADING_UP_START, self.loadingEnd, self)
end

function LoadingComponent:loadingStart(event)
	self.onComplete = event.params.onComplete

	self:resetUIComponents()
end

function LoadingComponent:loadingEnd()
	self:removeFromScene()
end

function LoadingComponent:_addEvent(event, func, thisObject)
	self.eventProxy_:addEventListener(event, handler(thisObject, func))
end

function LoadingComponent:initUIComponent()
	local winTrans = self.window_.transform
	self.title_tex = winTrans:ComponentByName("sprite_title", typeof(UITexture))
	self.sprite_title = self.title_tex.gameObject
	self.title_bg = winTrans:ComponentByName("sprite_bg", typeof(UITexture))
	self.title_bg.alpha = 0.6
	local winTrans = self.window_.transform
	winTrans.localPosition = Vector3(0, 8000)

	SpineManager.get():newEffect(self.sprite_title, "loading_paper", function (success, eff)
	end)
	self.window_:SetActive(false)
end

function LoadingComponent:clickSprite()
end

function LoadingComponent:resetUIComponents()
	self.window_:SetActive(true)

	local winTrans = self.window_.transform
	winTrans.localPosition = Vector3(0, 0)
	UIEventListener.Get(self.sprite_title).onClick = handler(self, self.clickSprite)
	UIEventListener.Get(self.sprite_title).onPress = handler(self, self.clickSprite)
	self.title_tex = winTrans:ComponentByName("sprite_title", typeof(UITexture))
	self.sprite_title = self.title_tex.gameObject
	self.title_tex.alpha = 0

	XYDCo.WaitForFrame(1, function ()
		self.title_tex:SetAnchor(nil)

		local sequence = DG.Tweening.DOTween.Sequence()
		self.sprite_title.transform.localPosition = Vector3(0, 2500)
		self.title_tex.alpha = 1

		if not self.effTxtDisplay then
			SpineManager.get():newEffect(self.sprite_title, "loading_paper", function (success, eff)
				if success then
					self.effTxtDisplay = eff
					local height = self.title_tex.height
					eff.transform.localPosition = Vector3(0, 0, -1)
					eff.transform.localScale = Vector3(200, 200, 200)
					local SpineController = eff:GetComponent(typeof(SpineAnim))
					SpineController.RenderTarget = self.title_tex
					SpineController.targetDelta = 1
					SpineController.timeScale = 0.5

					SpineController:play("texiao02", 1)
				end
			end)
		end

		sequence:Insert(0, self.sprite_title.transform:DOLocalMoveY(-50, 23 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
		sequence:AppendCallback(function ()
			xyd.EventDispatcher.inner():dispatchEvent({
				name = xyd.event.LOADING_DOWN_END,
				params = {}
			})

			if self.onComplete then
				self:onComplete()
			end

			if self.effTxtDisplay then
				local SpineController = self.effTxtDisplay:GetComponent(typeof(SpineAnim))
				SpineController.RenderTarget = self.title_tex
				SpineController.timeScale = 1

				SpineController:play("texiao01", 1)
			end
		end)
	end, nil)
end

function LoadingComponent:removeFromScene()
	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Insert(0.5, self.sprite_title.transform:DOLocalMoveY(2500, 14 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.InOutSine))
	sequence:AppendCallback(function ()
		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.LOADING_UP_END,
			params = {}
		})
		self.window_:SetActive(false)
	end)
end

function LoadingComponent:dispose()
	if self.effDisplay then
		SpineManager.get():pushEffect(self.effDisplay)
	end

	if self.effTxtDisplay then
		SpineManager.get():pushEffect(self.effTxtDisplay)
	end

	LoadingComponent.super.dispose(self)
end

return LoadingComponent
