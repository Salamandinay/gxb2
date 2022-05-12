local BaseWindow = import(".BaseWindow")
local PartnerDetailZoomWindow = class("PartnerDetailZoomWindow", BaseWindow)
local PartnerImg = import("app.components.PartnerImg")
local PartnerGravityController = import("app.components.PartnerGravityController")

function PartnerDetailZoomWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.touchPoints = {
		ids = {}
	}
	self.touchCount = 0
	self.distance = 0
	self.itemID = params.item_id
	self.bgSource = params.bg_source
	self.curScale_ = 100

	xyd.CameraManager.get():setEnabled(true)
end

function PartnerDetailZoomWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.mainPanel = winTrans:GetComponent(typeof(UIPanel))
	self.content = winTrans:NodeByName("content").gameObject
	self.panel = self.content:ComponentByName("scrollContainer", typeof(UIPanel))
	self.bgImg = self.content:ComponentByName("bgImg", typeof(UITexture))
	self.drag = self.content:NodeByName("drag").gameObject
	local partnerImgContainer = self.content:NodeByName("scrollContainer/imgPos/partnerImg").gameObject
	self.scrollContainer_ = self.window_:ComponentByName("content/scrollContainer", typeof(UIScrollView))
	self.scrollTrans = self.scrollContainer_.transform
	local xy = xyd.tables.partnerPictureTable:getPartnerPicXY(self.itemID)
	self.offestXY = xy
	local scale = xyd.tables.partnerPictureTable:getPartnerPicScale(self.itemID)

	partnerImgContainer.transform:SetLocalPosition(xy.x, -xy.y, 0)
	partnerImgContainer.transform:SetLocalScale(scale, scale, scale)

	self.partnerImg = PartnerImg.new(partnerImgContainer)

	self.eventProxy_:addEventListener(xyd.event.HANDLE_MAP_ZOOM, handler(self, self.updateScale))

	self.mainPanel.alpha = 0.02

	if (UNITY_EDITOR or UNITY_STANDALONE or XYDUtils.IsTest()) and (UNITY_ANDROID and XYDUtils.CompVersion(UnityEngine.Application.version, "1.5.374") >= 0 or UNITY_IOS and XYDUtils.CompVersion(UnityEngine.Application.version, "71.3.444") >= 0) then
		if not self.partnerGravity then
			self.partnerGravity = PartnerGravityController.new(self.bgImg.gameObject, 3)
		else
			self.partnerGravity:SetActive(true)
		end
	end
end

function PartnerDetailZoomWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()

	self.maxScale_ = tonumber(xyd.tables.miscTable:getVal("picture_max")) * 100
	self.minScale_ = tonumber(xyd.tables.miscTable:getVal("picture_min")) * 100
end

function PartnerDetailZoomWindow:layout()
	local function setImgCallBack()
		xyd.setUITextureByNameAsync(self.bgImg, self.bgSource, false)

		self.mainPanel.alpha = 1
	end

	self.partnerImg:setImg({
		showResLoading = true,
		windowName = self.name,
		itemID = self.itemID
	}, setImgCallBack)
end

function PartnerDetailZoomWindow:registerEvent()
	UIEventListener.Get(self.drag).onClick = function ()
		self:close()
	end
end

function PartnerDetailZoomWindow:willClose()
	PartnerDetailZoomWindow.super.willClose(self)

	local win = xyd.WindowManager.get():getWindow("skin_detail_buy_window")

	if win then
		win:setPartnerRootSatus(true)
	end

	xyd.CameraManager.get():setEnabled(false)
end

function PartnerDetailZoomWindow:updateScale(event)
	local params = event.params

	if not params.double_touch then
		self.centerPoint = nil

		print("self.centerPoint = nil")

		self.scrollContainer_.enabled = true

		if self.timer_ then
			self.timer_:Stop()
		end

		return
	end

	if not self.timer_ then
		self.timer_ = self:getTimer(function ()
			self.scrollContainer_.enabled = true
		end, 0.3, -1)

		self.timer_:Start()
	end

	self.scrollContainer_.enabled = false
	local delta = params.delta
	local centerPos = params.centerPos
	local partnerImgTrans = self.partnerImg.go.transform

	if not self.centerPoint then
		self.centerPoint = {
			worldPos = centerPos,
			oldX = partnerImgTrans:X(),
			oldY = partnerImgTrans:Y(),
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

	partnerImgTrans:SetLocalScale(scale, scale, 1)

	if self.partnerImg.isModel_ then
		changeY = changeY - addScale / 100 * self.offestXY.y
	end

	partnerImgTrans:SetLocalPosition(self.centerPoint.oldX + changeX, self.centerPoint.oldY - changeY, 0)
end

return PartnerDetailZoomWindow
