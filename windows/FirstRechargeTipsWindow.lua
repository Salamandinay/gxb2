local BaseWindow = import(".BaseWindow")
local FirstRechargeTipsWindow = class("FirstRechargeTipsWindow", BaseWindow)

function FirstRechargeTipsWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function FirstRechargeTipsWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:setText()
	self:registerEvent()
end

function FirstRechargeTipsWindow:getUIComponent()
	self.trans = self.window_.transform
	self.main = self.trans:NodeByName("main").gameObject
	self.bg = self.main:ComponentByName("bg", typeof(UISprite))
	self.labelTitle_ = self.main:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = self.main:NodeByName("closeBtn").gameObject
	self.labelText01_ = self.main:ComponentByName("labelText01_", typeof(UILabel))
	self.labelText02_ = self.main:ComponentByName("labelText02_", typeof(UILabel))
	self.btns = self.main:NodeByName("btns").gameObject
	self.btn1 = self.btns:NodeByName("btn1").gameObject
	self.buttonText1 = self.btn1:ComponentByName("button_label", typeof(UILabel))
	self.btn2 = self.btns:NodeByName("btn2").gameObject
	self.buttonText2 = self.btn2:ComponentByName("button_label", typeof(UILabel))
	self.btn3 = self.btns:NodeByName("btn3").gameObject
	self.buttonText3 = self.btn3:ComponentByName("button_label", typeof(UILabel))
end

function FirstRechargeTipsWindow:setText()
	self.labelTitle_.text = __("FIRST_RECHARGE_TIPS_TEXT01")
	self.labelText01_.text = __("FIRST_RECHARGE_TIPS_TEXT02")
	self.labelText02_.text = __("FIRST_RECHARGE_TIPS_TEXT03")
	local i = 1

	while i <= 3 do
		self["buttonText" .. tostring(i)].text = __("FIRST_RECHARGE_TIPS_TEXT0" .. tostring(tostring(i + 3)))
		i = i + 1
	end
end

function FirstRechargeTipsWindow:registerEvent()
	for i = 1, 3 do
		UIEventListener.Get(self["btn" .. tostring(i)].gameObject).onClick = handler(self, function ()
			xyd.models.selfPlayer:hasDisplayShouChong()
		end)
	end

	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)

	self.eventProxy_:addEventListener(xyd.event.KAIMEN_PLAYED, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end, self)
end

function FirstRechargeTipsWindow:didClose(params)
	FirstRechargeTipsWindow.super.didClose(self, params)

	if xyd.models.selfPlayer:isShouChongDisplayed() == false then
		xyd.models.selfPlayer:hasDisplayShouChong()
	end
end

return FirstRechargeTipsWindow
