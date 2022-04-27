local StageMap = import("app.maps.StageMap")
local StageWindow = class("StageWindow", import(".BaseWindow"))

function StageWindow:ctor(name, params)
	StageWindow.super.ctor(self, name, params)

	self.params_ = params
end

function StageWindow:initWindow()
	StageWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()

	self._map = StageMap.new(self.group_bg, self.params_)

	self._map:init()
end

function StageWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.group_start = winTrans:NodeByName("e:Skin/group_start").gameObject
	self.group_bg = winTrans:NodeByName("e:Skin").gameObject
end

function StageWindow:initUIComponent()
	xyd.setDarkenBtnBehavior(self.group_start, self, self._onBtnStart)
end

function StageWindow:_onBtnStart()
	xyd.WindowManager.get():closeWindow("stage_window")
end

function StageWindow:dispose()
	self._map:dispose()
	xyd.MapController.get():openSelfMap(nil)
	StageWindow.super.dispose(self)
end

return StageWindow
