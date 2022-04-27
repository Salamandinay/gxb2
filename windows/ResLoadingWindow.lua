local BaseWindow = import(".BaseWindow")
local ResLoadingWindow = class("ResLoadingWindow", BaseWindow)

function ResLoadingWindow:ctor(name, params)
	if params == nil then
		params = nil
	else
		self.params = params
	end

	self.currRealProgress_ = 0
	self.isProgressComplete_ = false
	self.oldTime_ = 0
	self.loadWndName_ = nil
	self.totalNum_ = 0

	ResLoadingWindow.super.ctor(self, name, params)

	self.hideMask = params.hide_mask

	if params.delta_x then
		self.deltaX = params.delta_x
	end

	if params.delta_y then
		self.deltaY = params.delta_y
	end

	if params.can_touch then
		self.canTouch = params.can_touch
	end
end

function ResLoadingWindow:willClose()
	ResLoadingWindow.super.willClose(self)
end

function ResLoadingWindow:checkDelay(params)
	if self.params.timeDelay then
		local waitKey_ = "resloading_wait_show_main_group"

		self:addTimeKey(waitKey_)
		self.mainGroup:SetActive(false)
		XYDCo.WaitForTime(self.params.timeDelay, function ()
			if not tolua.isnull(self.mainGroup) then
				self.mainGroup:SetActive(true)
			end
		end, waitKey_)
	end
end

function ResLoadingWindow:getUIComponent()
	print(tostring(self == nil))
	print(tostring(self.name_ == nil) .. " " .. tostring(self.window_ == nil))

	local winTrans = self.window_.transform
	self.mainGroup = winTrans:NodeByName("mainGroup").gameObject
	local infoGroup = self.mainGroup:NodeByName("infoGroup").gameObject
	self.imgLogo = infoGroup:ComponentByName("imgLogo", typeof(UISprite))
	self.imgLogo2 = infoGroup:ComponentByName("imgLogo2", typeof(UISprite))
	self.groupModel = infoGroup:NodeByName("groupModel").gameObject
	self.groupBot_ = infoGroup:NodeByName("groupBot_").gameObject
	self.progress = self.groupBot_:GetComponent(typeof(UIProgressBar))
	self.progressLabel = self.groupBot_:ComponentByName("labelDisplay", typeof(UILabel))
	self.labelTips_ = self.groupBot_:ComponentByName("labelTips_", typeof(UILabel))
	self.touchBg = winTrans:NodeByName("touchBg").gameObject
end

function ResLoadingWindow:initWindow()
	ResLoadingWindow.super.initWindow(self)
	self:getUIComponent()

	if self.canTouch == true then
		xyd.setTouchEnable(self.touchBg, false)
	end

	if self.hideMask == true then
		self.imgLogo:SetActive(false)
		self.imgLogo2:SetActive(false)
	end

	local pos = self.mainGroup.transform.localPosition

	self.mainGroup:SetLocalPosition(pos.x + (self.deltaX or 0), pos.y + (self.deltaY or 0), pos.z)
	self:layout()
	self:checkDelay()
end

function ResLoadingWindow:layout()
	self.labelTips_.text = __("RES_LOADING")
	local effect = xyd.Spine.new(self.groupModel)

	effect:setInfo("loading", function ()
		effect:SetLocalScale(0.6, 0.6, 1)
		effect:play("idle", 0)
	end)

	self.effect_ = effect
end

function ResLoadingWindow:setLoadWndName(wndName)
	if self.loadWndName_ ~= nil then
		return
	end

	self.loadWndName_ = wndName
end

function ResLoadingWindow:isCurLoading(wndName)
	return self.loadWndName_ == wndName
end

function ResLoadingWindow:setLoadProgress(wndName, progress)
	if self.loadWndName_ ~= wndName then
		return
	end

	self:changeProgress(progress)
end

function ResLoadingWindow:changeProgress(progress)
	self:updateBar(progress)
end

function ResLoadingWindow:updateBar(progress)
	self.currRealProgress_ = progress

	if self.currRealProgress_ == 1 then
		self:playActionEnd(100, function ()
			self.isProgressComplete_ = true

			xyd.WindowManager.get():closeWindow(self.name_)
		end)

		return
	end

	local duration = self.oldTime_ - os.time()
	duration = math.max(duration, 0.1)
	duration = math.min(duration, 0.2)

	self:playAction(duration, self.currRealProgress_)
end

function ResLoadingWindow:playAction(t, val, callback)
	if val == nil then
		val = -1
	end

	if callback == nil then
		callback = nil
	end

	if self.seq then
		self.seq:Kill()

		self.seq = nil
	end

	self.seq = self:getSequence(function ()
		if callback ~= nil then
			callback()
		end
	end)
	local tVal = val

	local function setter(value)
		if self.progress then
			self.progress.value = value
		end
	end

	self.seq:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), self.progress.value, tVal, t):SetEase(DG.Tweening.Ease.Linear))

	local value = math.floor(val * 10000) / 100
	local value2 = math.floor(value)
	self.progressLabel.text = tostring(value2) .. "%"
	self.oldTime_ = os.time()
end

function ResLoadingWindow:playActionEnd(val, callback)
	if callback == nil then
		callback = nil
	end

	if self.action then
		self.seq:Kill()

		self.seq = nil
	end

	self.progress.value = 1

	self:waitForFrame(1, function ()
		callback()
	end, nil)
end

return ResLoadingWindow
