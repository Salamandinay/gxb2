local CommonTipWindow = class("CommonTipWindow", import(".BaseWindow"))

function CommonTipWindow:ctor(name, params)
	CommonTipWindow.super.ctor(self, name, params)

	self.time_ = params.time or 1.5
	self.desc = params.desc
end

function CommonTipWindow:didOpen()
	CommonTipWindow.super.didOpen()

	local co = nil
	co = coroutine.start(function ()
		coroutine.wait(self.time_)

		if tolua.isnull(self.window_) then
			return
		end

		coroutine.stop(co)
		self:close()
	end)
end

function CommonTipWindow:initWindow()
	CommonTipWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
end

function CommonTipWindow:getUIComponent()
	local winTrans = self.window_.transform
	self._desc = winTrans:ComponentByName("e:Skin/main_group/_desc", typeof(UILabel))
end

function CommonTipWindow:initUIComponent()
	self._desc.text = self.desc
end

return CommonTipWindow
