local BaseWindow = import(".BaseWindow")
local BackgroundPreviewConfirmWindow = class("BackgroundPreviewConfirmWindow", BaseWindow)

function BackgroundPreviewConfirmWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.id_ = params.id
	self.skinName = "BackgroundPreviewConfirmWindowSkin"
end

function BackgroundPreviewConfirmWindow:initWindow()
	BackgroundPreviewConfirmWindow.super.initWindow(self)
	self:getUIComponent()
	BackgroundPreviewConfirmWindow.super.register(self)
	self:layout()
end

function BackgroundPreviewConfirmWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainGroup = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = mainGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.labelDesc = mainGroup:ComponentByName("labelDesc", typeof(UILabel))
	self.btnImg = mainGroup:NodeByName("btnImg").gameObject
	self.btnEffect = mainGroup:NodeByName("btnEffect").gameObject
	self.closeBtn = mainGroup:NodeByName("closeBtn").gameObject
	self.btnImgLabelDisplay = self.btnImg:ComponentByName("button_label", typeof(UILabel))
	self.btnEffectLabelDisplay = self.btnEffect:ComponentByName("button_label", typeof(UILabel))
end

function BackgroundPreviewConfirmWindow:layout()
	self.labelTitle.text = __("BACKGROUND_PREVIEW_CONFIRM_WINDOW_TITLE")
	self.labelDesc.text = __("BACKGROUND_PREVIEW_CONFIRM_WINDOW_DESC")

	if xyd.Global.lang == "ja_jp" then
		self.labelDesc.fontSize = 23
	end

	xyd.setDarkenBtnBehavior(self.btnImg, self, function ()
		self:onTouch(0)
	end)

	self.btnImgLabelDisplay.text = __("BACKGROUND_PREVIEW_CONFIRM_WINDOW_IMG")

	xyd.setDarkenBtnBehavior(self.btnEffect, self, function ()
		self:onTouch(1)
	end)

	self.btnEffectLabelDisplay.text = __("BACKGROUND_PREVIEW_CONFIRM_WINDOW_EFFECT")
	self.btnEffectLabelDisplay.fontSize = 24
	self.btnEffectLabelDisplay.color = Color.New2(1012112383)
	self.btnEffectLabelDisplay.effectColor = Color.New2(4294967295.0)

	self.eventProxy_:addEventListener(xyd.event.SET_BACKGROUND, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function BackgroundPreviewConfirmWindow:onTouch(index)
	xyd.models.background:reqAddSelect(self.id_, index)
end

return BackgroundPreviewConfirmWindow
