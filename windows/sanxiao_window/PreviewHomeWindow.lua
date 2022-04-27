local PreviewHomeWindow = class("PreviewHomeWindow", import(".BaseWindow"))

function PreviewHomeWindow:ctor(name, params)
	PreviewHomeWindow.super.ctor(self, name, params)

	self._offsetX = 20
	self._offsetY = -40
	self._offsetFit = 0
	self._scale = 1.2
end

function PreviewHomeWindow:initWindow()
	PreviewHomeWindow.super.initWindow(self)

	self._offsetFit = (xyd.getFixedHeight() - 1920) / 2

	self:getUIComponent()
	xyd.setNormalBtnBehavior(self.btn_back.gameObject, self, self._close)
	xyd.setUITextureAsync(self.img_home, "Textures/Preview_home_web/future_home_big")
	xyd.setUITextureAsync(self.img_pre_home, "Textures/Preview_home_web/future_home_small")
	self.scroller.gameObject:SetActive(false)
	self:_doAnimation()
end

function PreviewHomeWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.btn_back = winTrans:ComponentByName("e:Skin/e:Group/btn_back", typeof(UISprite))
	self.img_home = winTrans:ComponentByName("e:Skin/e:Group/scroller/img_home", typeof(UITexture))
	self.img_pre_home = winTrans:ComponentByName("e:Skin/e:Group/img_pre_home", typeof(UITexture))
	self.scroller = winTrans:ComponentByName("e:Skin/e:Group/scroller", typeof(UIScrollView))
end

function PreviewHomeWindow:_doAnimation()
	xyd.SpineManager.get():newEffect(self.window_, "building_preview", function (success, eff)
		if success then
			local SpineController = eff:GetComponent(typeof(SpineAnim))
			SpineController.RenderTarget = self.img_pre_home
			SpineController.targetDelta = 100

			SpineController:play("building_preview1", 1)

			eff.transform.localPosition = Vector3(self._offsetX, -self._offsetY - self._offsetFit, -100)
			eff.transform.localScale = Vector3(100, 100, 100)
			self.img_pre_home.transform.localPosition = Vector3(self._offsetX, -self._offsetY - self._offsetFit, 0)
			self.img_pre_home.transform.localScale = Vector3(0.1, 0.1, 0.1)
			self.img_pre_home.alpha = 1
			local onComplete1, onComplete2 = nil

			function onComplete1()
				SpineController:play("building_preview2", 2)
				SpineController:addListener("Complete", onComplete2)
			end

			function onComplete2()
				eff.transform.localPosition = Vector3(0, 0, -100)

				SpineController:play("building_preview3", 1)
				self.img_pre_home:SetActive(false)
				self.scroller.gameObject:SetActive(true)
				self.btn_back.gameObject:SetActive(true)
			end

			SpineController:addListener("Complete", onComplete1)

			return
		end

		self:_close()
	end)
end

function PreviewHomeWindow:_preHomeMoveAnimation()
	self.preHomeTimeline_ = TimelineLite.new()

	self.preHomeTimeline_:add(TweenLite:to(self.img_pre_home, 4 * xyd.TweenDeltaTime, {
		onComplete = function ()
			self.img_pre_home.alpha = 0.16
			self.img_pre_home.x = xyd.stageWidth / 2 - 81.5 - 97 * (self._scale - 1) / 2
			self.img_pre_home.y = xyd.stageHeight / 2 - 38.5 + self._offsetFit - 129 * (self._scale - 1) / 2
			self.img_pre_home.width = 97 * self._scale
			self.img_pre_home.height = 129 * self._scale
			self.img_pre_home.visible = true
		end
	}), 0)
	self.preHomeTimeline_:add(TweenLite:to(self.img_pre_home, 14 * xyd.TweenDeltaTime, {
		alpha = 1,
		x = xyd.stageWidth / 2 - 64 + self._offsetX - 121 * (self._scale - 1) / 2,
		y = xyd.stageHeight / 2 - 92 + self._offsetY + self._offsetFit - 184 * (self._scale - 1) / 2,
		width = 121 * self._scale,
		height = 184 * self._scale
	}), 4 * xyd.TweenDeltaTime)
	self.preHomeTimeline_:add(TweenLite:to(self.img_pre_home, 80 * xyd.TweenDeltaTime, {
		onComplete = function ()
			self.img_pre_home.width = 1080
			self.img_pre_home.height = 1920
			self.img_pre_home.x = xyd.stageWidth / 2 - self.img_pre_home.width / 2
			self.img_pre_home.y = xyd.stageHeight / 2 - self.img_pre_home.height / 2
			local final_width = self.img_pre_home.width
			local final_height = self.img_pre_home.height
			self.img_pre_home.mask = egret.Rectangle.new(self.img_pre_home.width * 0.5, self.img_pre_home.height * 0.5, 0, 0)

			self.preHomeTimeline_:add(TweenLite:to(self.img_pre_home.mask, 21 * xyd.TweenDeltaTime, {
				x = 0,
				y = 0,
				width = final_width,
				height = final_height
			}), 98 * xyd.TweenDeltaTime)
			self.preHomeTimeline_:call(function ()
				self.img_pre_home.visible = false
				self.scroller.visible = true
				self.btn_back.visible = true
			end)
		end
	}), 18 * xyd.TweenDeltaTime)
end

function PreviewHomeWindow:_close()
	xyd.WindowManager.get():closeWindow("preview_home_window")
end

function PreviewHomeWindow:dispose()
	if self.preHomeTimeline_ then
		self.preHomeTimeline_:stop()
		self.preHomeTimeline_:kill()
	end

	if self._eff then
		local Destroy = UnityEngine.Object.Destroy

		self._eff:Destroy()
	end

	PreviewHomeWindow.super.dispose(self)
end

return PreviewHomeWindow
