local BaseWindow = import(".BaseWindow")
local LoadingWindow = class("LoadingWindow", BaseWindow)

function LoadingWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.delay = 3
	self.timeKey_ = nil
	self.isWndShow_ = false
	self.maxDelay = 30
	self.refreshTimeKey_ = nil
	self.showAlert_ = false
	self.skinName = "LoadingSprSkin"
end

function LoadingWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initModel()
	self.groupMain_:SetActive(false)
end

function LoadingWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupMain_ = winTrans:NodeByName("groupMain_").gameObject
	self.imgMask_ = self.groupMain_:ComponentByName("imgMask_", typeof(UISprite))
	self.sprGroup_show = self.groupMain_:NodeByName("sprGroup_show").gameObject
	self.sprGroupTween = self.sprGroup_show:ComponentByName("sprGroup", typeof(TweenRotation))
	self.groupModel = self.groupMain_:ComponentByName("groupModel", typeof(UITexture))
end

function LoadingWindow:show()
	if self.timeKey_ then
		return
	end

	if not self.window_ then
		return
	end

	self.isWndShow_ = true
	self.imgMask_.alpha = 0.01

	self.groupMain_:SetActive(true)
	self.sprGroup_show:SetActive(false)
	self.groupModel:SetActive(false)

	self.timeKey_ = "loading_time_key_1"

	XYDCo.WaitForTime(self.delay, function ()
		self.sprGroup_show:SetActive(true)
		self.groupModel:SetActive(true)
		self:playMaskAction()
		self.sprGroupTween:PlayForward()

		if self.dragonEffect_ then
			self.dragonEffect_:play("idle", 0)
		end

		self:recordDelay()
	end, self.timeKey_)
	self:showRefresh()
end

function LoadingWindow:playMaskAction()
	if self.maskSequence_ then
		self.maskSequence_:Restart()

		return
	end

	self.maskSequence_ = self:getSequence()

	self.maskSequence_:Append(xyd.getTweenAlpha(self.imgMask_, 0.7, 0.1))
	self.maskSequence_:SetAutoKill(false)
end

function LoadingWindow:recordDelay()
	local mids = xyd.MainController.get():getCurMids()
	local msg = messages_pb.delay_log_req()

	for i = 1, #mids do
		table.insert(msg.delay_mids, mids[i])
	end

	xyd.Backend.get():request(xyd.mid.DELAY_LOG, msg)
end

function LoadingWindow:showRefresh()
	if self.refreshTimeKey_ then
		XYDCo.StopWait(self.refreshTimeKey_)

		self.refreshTimeKey_ = nil
	end

	self.refreshTimeKey_ = "loading_time_key_refresh"

	XYDCo.WaitForTime(self.maxDelay + self.delay, function ()
		self.showAlert_ = true

		xyd.systemAlert(xyd.AlertType.YES_NO, __("REFRESH_GAME"), function (yes)
			self.showAlert_ = false

			if yes then
				xyd.MainController.get():restartGame()
			else
				self:showRefresh()
			end
		end)
	end, self.refreshTimeKey_)
end

function LoadingWindow:isWndShow()
	return self.isWndShow_
end

function LoadingWindow:hide()
	if not self:isWndShow() then
		return
	end

	if not self.window_ then
		return
	end

	self.isWndShow_ = false

	self.groupMain_:SetActive(false)

	if self.timeKey_ then
		XYDCo.StopWait(self.timeKey_)

		self.timeKey_ = nil
	end

	if self.refreshTimeKey_ then
		XYDCo.StopWait(self.refreshTimeKey_)

		self.refreshTimeKey_ = nil
	end

	if self.dragonEffect_ then
		self.dragonEffect_:stop()
	end

	if self.maskSequence_ then
		self.maskSequence_:Pause()
	end

	if self.showAlert_ then
		xyd.closeWindow("system_alert_window")
	end

	if self.sprGroupTween then
		self.sprGroupTween.enabled = false
	end

	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.LOADING_WINDOW_HIDE
	})
end

function LoadingWindow:willClose()
	BaseWindow.willClose(self)

	if self.timeKey_ then
		XYDCo.StopWait(self.timeKey_)

		self.timeKey_ = nil
	end

	if self.refreshTimeKey_ then
		XYDCo.StopWait(self.refreshTimeKey_)

		self.refreshTimeKey_ = nil
	end

	if self.sprGroupTween then
		self.sprGroupTween.enabled = false
	end
end

function LoadingWindow:initModel()
	local dragon = xyd.Spine.new(self.groupModel.gameObject)

	dragon:setInfo("loading", function ()
		if self:isWndShow() then
			dragon:play("idle", 0)
		end
	end)

	self.dragonEffect_ = dragon
end

return LoadingWindow
