local AlertTipsWindow = class("AlertTipsWindow", import(".BaseWindow"))

function AlertTipsWindow:ctor(name, params)
	AlertTipsWindow.super.ctor(self, name, params)

	self.message = params.message
	self.tipsInitY_ = params.tipsInitY_
	self.freezeTime_ = params.freezeTime or 0.001
end

function AlertTipsWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function AlertTipsWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.groupTips_ = groupAction:NodeByName("groupTips_").gameObject
	self.labelTips_ = self.groupTips_:ComponentByName("labelTips_", typeof(UILabel))
end

function AlertTipsWindow:reSize()
end

function AlertTipsWindow:layout()
	self.labelTips_.text = self.message or ""
	local oldPos = self.groupTips_.transform.localPosition

	self.groupTips_:SetLocalPosition(oldPos.x, self.tipsInitY_ or oldPos.y, oldPos.z)
	self.groupTips_:SetActive(true)
	self:playAlphaAction()
end

function AlertTipsWindow:registerEvent()
end

function AlertTipsWindow:playAlphaAction()
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
		self:waitForTime(self.freezeTime_, function ()
			self:closeTips()
		end)
	end)
end

function AlertTipsWindow:closeTips()
	local wnd = xyd.WindowManager.get():getWindow("alert_tips_window")

	if wnd then
		xyd.WindowManager.get():closeWindow("alert_tips_window")
	end
end

return AlertTipsWindow
