local ActivitySandSearchHelpWindow = class("ActivitySandSearchHelpWindow", import(".BaseWindow"))

function ActivitySandSearchHelpWindow:ctor(name, params)
	ActivitySandSearchHelpWindow.super.ctor(self, name, params)
end

function ActivitySandSearchHelpWindow:initWindow()
	self:getUIComponent()
end

function ActivitySandSearchHelpWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.labelTip1 = winTrans:ComponentByName("labelTip1", typeof(UILabel))
	self.labelTip2 = winTrans:ComponentByName("labelTip2", typeof(UILabel))
	self.labelTip3 = winTrans:ComponentByName("labelTip3", typeof(UILabel))
	self.labelTip1.text = __("ACTIVITY_SAND_HELP01")
	self.labelTip2.text = __("ACTIVITY_SAND_HELP02")
	self.labelTip3.text = __("ACTIVITY_SAND_HELP03")

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end
end

return ActivitySandSearchHelpWindow
