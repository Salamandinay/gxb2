xyd = xyd or {}
local ALERT_WINDOW_NAME = "alert_window"
local ALERT_TIPS_WINDOW_NAME = "alert_tips_window"
local costComponent = import("app.components.BaseCost")

function xyd.alert(alertType, message, callback, confirmText, noClose, cost, title, tipsInitY_, closeCallback, tipsHeightOffset, fontSize, freezeTime, cancelText)
	local params = {
		alertType = alertType,
		message = message,
		callback = callback,
		closeCallBack = closeCallback,
		confirmText = confirmText,
		noClose = noClose,
		cost = cost,
		title = title,
		tipsInitY_ = tipsInitY_,
		tipsHeightOffset = tipsHeightOffset,
		fontSize = fontSize,
		freezeTime = freezeTime,
		cancelText = cancelText
	}

	if alertType == xyd.AlertType.TIPS then
		if xyd.WindowManager.get():getWindow(ALERT_TIPS_WINDOW_NAME) then
			xyd.WindowManager.get():closeWindow(ALERT_TIPS_WINDOW_NAME)
		end

		return xyd.WindowManager.get():openWindow(ALERT_TIPS_WINDOW_NAME, params)
	else
		if xyd.WindowManager.get():getWindow(ALERT_WINDOW_NAME) then
			xyd.WindowManager.get():closeWindow(ALERT_WINDOW_NAME)
		end

		return xyd.WindowManager.get():openWindow(ALERT_WINDOW_NAME, params)
	end
end

function xyd.alertTips(message, callback, confirmText, noClose, cost, title, tipsInitY_, closeCallback, tipsHeightOffset, fontSize, freezeTime, cancelText)
	return xyd.alert(xyd.AlertType.TIPS, message, callback, confirmText, noClose, cost, title, tipsInitY_, closeCallback, tipsHeightOffset, fontSize, freezeTime)
end

function xyd.alertYesNo(message, callback, confirmText, noClose, cost, title, tipsInitY_, closeCallback, tipsHeightOffset, fontSize, freezeTime, cancelText)
	return xyd.alert(xyd.AlertType.YES_NO, message, callback, confirmText, noClose, cost, title, tipsInitY_, closeCallback, tipsHeightOffset, fontSize, freezeTime)
end

function xyd.alertConfirm(message, callback, confirmText, noClose, cost, title, tipsInitY_, closeCallback, tipsHeightOffset, fontSize, freezeTime, cancelText)
	return xyd.alert(xyd.AlertType.CONFIRM, message, callback, confirmText, noClose, cost, title, tipsInitY_, closeCallback, tipsHeightOffset, fontSize, freezeTime)
end

local AlertWindow = class("AlertWindow", import(".BaseWindow"))

function AlertWindow:ctor(name, params)
	AlertWindow.super.ctor(self, name, params)

	self.callback = nil
	self.closeCallBack = nil
	self.noClose = false
	self.cost_ = {}
	self.titleText = nil
	self.tipsInitY_ = nil
	self.confirmText = ""
	self.type_ = params.alertType
	self.message = params.message
	self.callback = params.callback
	self.noClose = params.noClose
	self.confirmText = params.confirmText or __("YES")
	self.cancelText = params.cancelText or __("NO")
	self.cost_ = params.cost or {}
	self.titleText = params.title
	self.tipsInitY_ = params.tipsInitY_
	self.tipsHeightOffset = params.tipsHeightOffset
	self.fontSize = params.fontSize
end

function AlertWindow:getType()
	return self.type_
end

function AlertWindow:playOpenAnimations(callback)
	if self.type_ == xyd.AlertType.TIPS then
		return
	else
		AlertWindow.super.playOpenAnimations(preWinName, callback)
		self:bgAnimation(1)
	end
end

function AlertWindow:bgAnimation(alpha)
	if self.bg_ == nil or tolua.isnull(self.bg_) then
		return
	end

	local w = self.bg_:GetComponent(typeof(UIWidget))

	if not w then
		return
	end

	local function getter()
		return w.color
	end

	local function setter(value)
		w.color = value
	end

	DG.Tweening.DOTween.ToAlpha(getter, setter, alpha, 2 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear)
end

function AlertWindow:adjustWindowDepth()
	local layer = xyd.WindowManager.get():getUILayer(self.layerType_)

	if tolua.isnull(self.window_) or tolua.isnull(layer) then
		return
	end

	local minDepth = xyd.LayerType2Depth[self.layerType_] + 21

	assert(minDepth)

	local needDepth = Mathf.Clamp(XYDUtils.GetMaxTargetDepth(layer, false) + 1, minDepth, XYDUtils.MaxInt)

	if self.minDepth_ ~= needDepth then
		XYDUtils.SetTargetMinPanel(self.window_, needDepth)

		self.minDepth_ = needDepth
	end
end

function AlertWindow:initWindow()
	AlertWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:setupButtons()
	self:registerEvent()
end

function AlertWindow:open(window)
	AlertWindow.super.open(self, window)
end

function AlertWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.bg_ = winTrans:NodeByName("bg_").gameObject
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.groupTips_ = groupAction:NodeByName("groupTips_").gameObject
	self.labelTips_ = self.groupTips_:ComponentByName("labelTips_", typeof(UILabel))
	self.groupConfirm_ = groupAction:NodeByName("groupConfirm_").gameObject
	self.labelTitle_ = self.groupConfirm_:ComponentByName("labelTitle_", typeof(UILabel))
	self.labelDesc_ = self.groupConfirm_:ComponentByName("labelDesc_", typeof(UILabel))
	self.btnSure_ = self.groupConfirm_:NodeByName("btnSure_").gameObject
	self.btnCancel_ = self.groupConfirm_:NodeByName("btnCancel_").gameObject
	self.btnConfirm_ = self.groupConfirm_:NodeByName("btnConfirm_").gameObject
	self.closeBtn = self.groupConfirm_:NodeByName("closeBtn").gameObject

	self:setCloseBtn(self.closeBtn)
end

function AlertWindow:update()
	self:layout()
	self:setupButtons()
end

function AlertWindow:willClose(params, skipAnimation, force)
	AlertWindow.super.willClose(self, params, skipAnimation, force)
end

function AlertWindow:layout()
	self.type_ = self.params_.alertType
	self.message = self.params_.message
	self.callback = self.params_.callback
	self.confirmText = self.params_.confirmText or __("YES")
	self.noClose = self.params_.noClose

	if self.type_ == xyd.AlertType.TIPS then
		self.groupTips_:SetActive(false)
		self.groupConfirm_:SetActive(false)
		self.bg_:SetActive(false)

		if xyd.WindowManager.get():getWindow(ALERT_TIPS_WINDOW_NAME) then
			xyd.WindowManager.get():closeWindow(ALERT_TIPS_WINDOW_NAME)
		end

		xyd.WindowManager.get():openWindow(ALERT_TIPS_WINDOW_NAME, {
			message = self.message,
			tipsInitY_ = self.tipsInitY_
		})
		self:closeTips()
	else
		local text = self.message or ""
		self.labelDesc_.text = text
		self.labelTitle_.text = __("TIPS")

		self.groupTips_:SetActive(false)
		self.groupConfirm_:SetActive(true)

		if self.titleText then
			self.labelTitle_.text = self.titleText
		end

		if self.tipsHeightOffset then
			local base = 150

			print(self.tipsHeightOffset)

			self.labelDesc_.height = base + self.tipsHeightOffset
			self.groupConfirm_:ComponentByName("bg", typeof(UISprite)).height = 330 + self.tipsHeightOffset

			self.closeBtn:Y(141 + self.tipsHeightOffset / 2)
			self.labelTitle_:Y(141 + self.tipsHeightOffset / 2)
			self.btnCancel_:Y(-102 - self.tipsHeightOffset / 2)
			self.btnConfirm_:Y(-102 - self.tipsHeightOffset / 2)
			self.btnSure_:Y(-102 - self.tipsHeightOffset / 2)
		end

		if self.fontSize then
			self.labelDesc_.fontSize = self.fontSize
		end
	end
end

function AlertWindow:playAlphaAction()
	local widget = self.groupTips_:GetComponent(typeof(UIWidget))
	widget.alpha = 0.5

	local function getter()
		return widget.color
	end

	local function setter(value)
		widget.color = value
	end

	local sequence1 = self:getSequence()

	sequence1:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 1.2):SetEase(DG.Tweening.Ease.Linear))
	sequence1:AppendCallback(function ()
		self:closeTips()
	end)
end

function AlertWindow:closeWin(event)
	App.WindowManager:closeWindow(self.name)
end

function AlertWindow:registerEvent()
	UIEventListener.Get(self.btnSure_).onClick = handler(self, self.sureTouch)
	UIEventListener.Get(self.btnCancel_).onClick = handler(self, self.cancelTouch)
	UIEventListener.Get(self.btnConfirm_).onClick = handler(self, self.confirmTouch)
end

function AlertWindow:sureTouch()
	if not self.noClose then
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	if self.callback then
		self.callback(true)
	end
end

function AlertWindow:cancelTouch()
	if not self.noClose then
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	if self.callback then
		self.callback(false)
	end
end

function AlertWindow:confirmTouch()
	if not self.noClose then
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	if self.callback then
		self.callback(true)
	end
end

function AlertWindow:setupButtons()
	local costBtn = nil

	if self.type_ == xyd.AlertType.CONFIRM then
		self.btnConfirm_:SetActive(true)

		local label = self.btnConfirm_:ComponentByName("button_label", typeof(UILabel))
		label.text = self.confirmText
		label.color = Color.New2(4294967295.0)

		xyd.setBgColorType(self.btnConfirm_, xyd.ButtonBgColorType.blue_btn_70_70)
		self.btnSure_:SetActive(false)
		self.btnCancel_:SetActive(false)
		self.closeBtn:SetActive(true)

		costBtn = self.btnConfirm_
	elseif self.type_ == xyd.AlertType.YES_NO then
		self.btnConfirm_:SetActive(false)
		self.btnSure_:SetActive(true)

		local label = self.btnSure_:ComponentByName("button_label", typeof(UILabel))
		label.text = self.confirmText
		label.color = Color.New2(4294967295.0)

		xyd.setBgColorType(self.btnSure_, xyd.ButtonBgColorType.blue_btn_70_70)
		xyd.setBgColorType(self.btnCancel_, xyd.ButtonBgColorType.white_btn_70_70)
		self.btnCancel_:SetActive(true)
		self.closeBtn:SetActive(false)

		local label2 = self.btnCancel_:ComponentByName("button_label", typeof(UILabel))
		label2.text = self.cancelText
		self.cancelBtnUILabel = label2
		costBtn = self.btnSure_
	end

	self:initCost(costBtn)

	if self.noClose then
		self.closeBtn:SetActive(false)
	end
end

function AlertWindow:initCost(btn)
	if #self.cost_ > 0 then
		local costPart = costComponent.new(btn)

		costPart:setInfo({
			cost = self.cost_,
			localPosition = Vector3(-50, 0, 0)
		})
		costPart:setLabelWidth(45)

		local lable = btn:ComponentByName("button_label", typeof(UILabel))
		lable.effectColor = Color.New2(1012112383)

		lable.transform:SetLocalPosition(15, 0, 0)
		costPart:getGameObject().transform:SetSiblingIndex(0)
		lable.gameObject.transform:SetSiblingIndex(1)

		lable.overflowMethod = UILabel.Overflow.ResizeFreely

		while true do
			if lable.width > 128 then
				lable.fontSize = lable.fontSize - 1
			else
				break
			end
		end

		local btn_ui_layout = btn:GetComponent(typeof(UILayout))

		if btn_ui_layout then
			btn_ui_layout:Reposition()
		else
			btn:AddComponent(typeof(UILayout))

			local ui_layout = btn:GetComponent(typeof(UILayout))
			ui_layout.gap = Vector2(10, 0)

			ui_layout:Reposition()

			if lable.gameObject.transform.localPosition.x + lable.width / 2 > 87 then
				ui_layout.gap = Vector2(0, 0)

				ui_layout:Reposition()
			end
		end
	end
end

function AlertWindow:closeTips()
	local wnd = xyd.WindowManager.get():getWindow(ALERT_WINDOW_NAME)

	if wnd and wnd:getType() == xyd.AlertType.TIPS then
		xyd.WindowManager.get():closeWindow(ALERT_WINDOW_NAME)
	end
end

function AlertWindow:onClickCloseButton()
	AlertWindow.super.onClickCloseButton(self)

	if self.closeCallBack then
		self:closeCallBack()
	end
end

function AlertWindow:iosTestChangeUI()
	local winTrans = self.window_.transform

	xyd.iosSetUISprite(winTrans:ComponentByName("groupAction/groupConfirm_/bg", typeof(UISprite)), "9gongge21_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("groupAction/groupConfirm_/btnSure_", typeof(UISprite)), "blue_btn_65_65_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("groupAction/groupConfirm_/btnCancel_", typeof(UISprite)), "white_btn70_70_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("groupAction/groupConfirm_/btnConfirm_", typeof(UISprite)), "white_btn70_70_ios_test")
end

function AlertWindow:setDescWidth(width)
	self.labelDesc_.width = width
end

function AlertWindow:setCancelBtnLabel(str)
	if self.cancelBtnUILabel then
		self.cancelBtnUILabel.text = str
	end
end

return AlertWindow
