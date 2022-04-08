local BaseWindow = import(".BaseWindow")
local SummonMemeoryWindow = class("SummonMemeoryWindow", BaseWindow)

function SummonMemeoryWindow:ctor(name, params)
	SummonMemeoryWindow.super.ctor(self, name, params)

	local summonData = xyd.models.summon:getSummonDate()

	if summonData then
		self.summonDate_ = summonData
	end
end

function SummonMemeoryWindow:initWindow()
	SummonMemeoryWindow.super.initWindow(self)
	self:getComponent()
end

function SummonMemeoryWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.labelTitle_ = winTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.groupNav1_ = winTrans:NodeByName("navGroup1").gameObject
	self.groupNav2_ = winTrans:NodeByName("navGroup2").gameObject
end

return SummonMemeoryWindow
