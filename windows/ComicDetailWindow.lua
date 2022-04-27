local ComicDetailWindow = class("ComicDetailWindow", import(".BaseWindow"))
local Input = UnityEngine.Input

function ComicDetailWindow:ctor(name, params)
	ComicDetailWindow.super.ctor(self, name, params)

	self.url_ = params.url
	self.curChapter_ = params.chapter
	self.curScale_ = 100
	self.maxScale_ = 150
	self.minScale_ = 60

	xyd.CameraManager.get():setEnabled(true)
end

function ComicDetailWindow:initWindow()
	ComicDetailWindow.super.initWindow(self)

	self.uiCamera_ = xyd.WindowManager.get():getNgui():ComponentByName("UICamera", typeof(UICamera))
	self.drag_ = self.window_:NodeByName("content/drag").gameObject
	self.scrollContainer_ = self.window_:ComponentByName("content/scrollContainer", typeof(UIScrollView))
	self.scrollContainer_panel = self.scrollContainer_:GetComponent(typeof(UIPanel))
	self.comicTexture_ = self.window_:ComponentByName("content/scrollContainer/comicImg", typeof(UITexture))

	self:loadImgByUrl(self.url_, self.comicTexture_, function ()
		self.comicTexture_:MakePixelPerfect()
	end)

	UIEventListener.Get(self.drag_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	self.scrollTrans = self.scrollContainer_.transform

	self.eventProxy_:addEventListener(xyd.event.HANDLE_MAP_ZOOM, handler(self, self.updateScale))
end

function ComicDetailWindow:willClose()
	ComicDetailWindow.super.willClose(self)
	xyd.CameraManager.get():setEnabled(false)
end

function ComicDetailWindow:loadImgByUrl(url, uiTexture, callback)
	if XYDUtils.IsTest() then
		url = "http://192.168.2.45:9595/images/img_zh.png"
	end

	if uiTexture then
		xyd.setTextureByURL(url, uiTexture, uiTexture.width, uiTexture.height, callback)
	else
		xyd.setTextureByURL(url, uiTexture, nil, , callback)
	end
end

function ComicDetailWindow:updateScale(event)
	local params = event.params
	local delta = params.delta

	if not params.double_touch then
		self.centerPoint = nil
		self.scrollContainer_.enabled = true

		return
	end

	local centerPos = params.centerPos
	self.scrollContainer_.enabled = false

	if not self.timer_ then
		self.timer_ = self:getTimer(function ()
			self.scrollContainer_.enabled = true
		end, 0.3, -1)

		self.timer_:Start()
	end

	if not params.double_touch then
		self.centerPoint = nil

		return
	end

	if not self.centerPoint then
		self.centerPoint = {
			worldPos = centerPos,
			oldX = self.scrollTrans:X(),
			oldY = self.scrollTrans:Y(),
			scale = self.curScale_
		}
	end

	local rate = math.floor((delta - 1) * 100)

	if math.abs(rate) < 1 then
		return
	end

	local newScale = Mathf.Clamp(self.curScale_ + rate, self.minScale_, self.maxScale_)
	self.curScale_ = newScale
	local addScale = self.centerPoint.scale - self.curScale_
	local localPos = self.scrollTrans:InverseTransformPoint(self.centerPoint.worldPos)
	local changeX = localPos.x * addScale / 100
	local changeY = localPos.y * addScale / 100
	local scale = self.curScale_ / xyd.PERCENT_BASE

	self.comicTexture_.transform:SetLocalScale(scale, scale, 1)

	if delta == 1 and self.centerPoint then
		self.comicTexture_.transform:X(self.centerPoint.oldX + changeX)
		self.comicTexture_.transform:Y(self.centerPoint.oldY - changeY)
	end
end

return ComicDetailWindow
