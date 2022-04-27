local BaseWindow = import(".BaseWindow")
local ShowWebImgWindow = class("ShowWebImgWindow", BaseWindow)

function ShowWebImgWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.data = params
end

function ShowWebImgWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ShowWebImgWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.imgLoad_ = winTrans:ComponentByName("groupMain_/imgLoad_", typeof(UITexture))
	self.imgTouch_ = winTrans:NodeByName("imgTouch_").gameObject
end

function ShowWebImgWindow:layout()
	local width_ = self.data.width
	local height_ = self.data.height

	if width_ and height_ then
		self.imgLoad_.height = height_ / width_ * self.imgLoad_.width
	end

	if self.imgLoad_.height > 1200 then
		self.imgLoad_.width = 1200 / self.imgLoad_.height * self.imgLoad_.width
		self.imgLoad_.height = 1200
	end

	xyd.setTextureByURL(self.data.url, self.imgLoad_, self.imgLoad_.width, self.imgLoad_.height, function ()
	end)
end

function ShowWebImgWindow:registerEvent()
	UIEventListener.Get(self.imgTouch_).onClick = function ()
		xyd.closeWindow(self.name_)
	end
end

return ShowWebImgWindow
