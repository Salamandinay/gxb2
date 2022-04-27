local ShrineHurdleMainWindow = class("TowerWindow", import("app.components.BaseComponent"))

function ShrineHurdleMainWindow:ctor(name, params)
	ShrineHurdleMainWindow.super.ctor(self, name, params)
end

function ShrineHurdleMainWindow:initWindow()
	self:getUIComponent()
	self:updateState()
end

function ShrineHurdleMainWindow:getUIComponent()
end

function ShrineHurdleMainWindow:updateState()
end

function ShrineHurdleMainWindow:updateShow()
end

return ShrineHurdleMainWindow
