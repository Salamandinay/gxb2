local UpLoadImgWindow = class("UpLoadImgWindow", import(".BaseWindow"))
local DEFAULT_CLIP_PATH = "Pictures/"
local cjson = require("cjson")

function UpLoadImgWindow:ctor(name, params)
	UpLoadImgWindow.super.ctor(self, name, params)

	self.imgSize = 0
	self.data_ = params
	self.rotationNum_ = 0
end

function UpLoadImgWindow:initWindow()
	UpLoadImgWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function UpLoadImgWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupMain_ = winTrans:ComponentByName("groupMain_", typeof(UITexture))
	self.closeBtn = winTrans:NodeByName("topRight/closeBtn").gameObject
	self.labelTitle = winTrans:ComponentByName("groupTop/labelTitle", typeof(UILabel))
	self.btnSend_ = winTrans:NodeByName("botRight/btnSend_").gameObject
	self.groupSelect = winTrans:NodeByName("botLeft/groupSelect").gameObject
	self.imgSelect = self.groupSelect:NodeByName("imgSelect").gameObject
	self.labelTips_ = self.groupSelect:ComponentByName("labelTips_", typeof(UILabel))
	self.groupSelect_btn = winTrans:NodeByName("botLeft/groupSelect/e:Image").gameObject
	self.groupLoding_ = winTrans:NodeByName("groupLoding_").gameObject
	self.sprGroup = self.groupLoding_:NodeByName("sprGroup_show/sprGroup").gameObject
	self.groupModel = self.groupLoding_:NodeByName("groupModel").gameObject
	self.imgMask_ = self.groupLoding_:ComponentByName("imgMask_", typeof(UISprite))
	self.sprGroup_show = self.groupLoding_:NodeByName("sprGroup_show").gameObject
end

function UpLoadImgWindow:layout()
	self.btnSend_:ComponentByName("button_label", typeof(UILabel)).text = __("SEND")
	self.labelTips_.text = ""
	self.labelTitle.text = __("UPLOAD_IMG_WINDOW")

	self:showImg()
end

function UpLoadImgWindow:showImg()
	if not self.data_ or not self.data_.path then
		return
	end

	local splitedPath = string.split(self.data_.path, "/")
	local filePath = DEFAULT_CLIP_PATH .. splitedPath[#splitedPath]
	self.filePath_ = filePath
	local width = self.data_.width
	local height = self.data_.height
	self.sendDataWidth = self.data_.width
	self.sendDataHeight = self.data_.height
	local maxWidth = 553
	local maxHeight = 984
	local finalWidth = width
	local finalHeight = height

	if maxWidth < width then
		finalWidth = maxWidth
		finalHeight = math.floor(maxWidth / width * height)
	end

	if maxHeight < finalHeight then
		finalHeight = maxHeight
		finalWidth = math.floor(maxHeight / finalHeight * finalWidth)
	end

	XYDCo.WaitForTime(0.3, function ()
		if tolua.isnull(self.window_) then
			return
		end

		local data = NGUITools.Load(filePath)

		if data and not tolua.isnull(data) then
			self.texture = XYDUtils.CreateTexture2D(width or 128, height or 128, 1, false)

			if not XYDUtils.Texture2DLoadImg(self.texture, data) then
				return
			end

			if width and width > 340 then
				local targetHeight = 128
				local targetWidth = 340

				if height then
					targetHeight = height
				end

				targetHeight = targetHeight * 340 / width
				self.texture_small = XYDUtils.CreateTexture2D(targetWidth, targetHeight, 4, false)
				self.sendDataWidth = targetWidth
				self.sendDataHeight = targetHeight
				local rpixels = self.texture_small:GetPixels(0)
				local incX = 1 / targetWidth
				local incY = 1 / targetHeight

				for px = 0, rpixels.Length - 1 do
					rpixels[px] = self.texture:GetPixelBilinear(incX * (px % targetWidth), incY * math.floor(px / targetWidth))
				end

				self.texture_small:SetPixels(rpixels, 0)
				self.texture_small:Apply()
			else
				self.texture_small = self.texture
			end

			self.groupMain_.mainTexture = self.texture
			self.groupMain_.width = finalWidth
			self.groupMain_.height = finalHeight

			if XYDUtils.GetBytesLength(data) >= 1048576 then
				self.imgSize = XYDUtils.GetBytesLength(data) / 1024 / 1024
				self.labelTips_.text = __("GM_IMG_SIZE", string.format("%.2f", self.imgSize) .. "MB")
			else
				self.imgSize = math.ceil(XYDUtils.GetBytesLength(data) / 1024)
				self.labelTips_.text = __("GM_IMG_SIZE", tostring(self.imgSize) .. "KB")
			end

			self.binaryData_ = data
		end
	end, nil)
end

function UpLoadImgWindow:registerEvent()
	UpLoadImgWindow.super.register(self)

	UIEventListener.Get(self.btnSend_).onClick = handler(self, self.onSendTouch)
	UIEventListener.Get(self.groupSelect_btn).onClick = handler(self, self.onSelectTouch)
end

function UpLoadImgWindow:onSendTouch()
	if not self.binaryData_ then
		return
	end

	self:uploadSourceImg()
end

function UpLoadImgWindow:uploadSourceImg()
	local bytes = self.binaryData_
	local md5Name1 = XYDUtils.GetMd5Hash(bytes) .. ".jpg"
	local uploadNames = {
		md5Name1
	}
	local uploadBytes = {
		bytes
	}

	self:showResLoading()
	xyd.uploadBinaryData(xyd.uploadGMImgURL(), uploadNames, uploadBytes, function (success)
		self:hideResLoading()

		if success then
			NGUITools.Save(xyd.GM_IMG_SAVE_PATH .. uploadNames[1], uploadBytes[1])
			NGUITools.Delete(self.filePath_)
			xyd.WebPictureManager.get():addDataByUrl(xyd.downloadGMImgURL() .. uploadNames[1], xyd.GM_IMG_SAVE_PATH .. uploadNames[1])

			local str = cjson.encode({
				width = self.sendDataWidth,
				height = self.sendDataHeight,
				img = xyd.downloadGMImgURL() .. uploadNames[1]
			})

			xyd.models.chat:talkWithGM(str, nil, "img")
			xyd.closeWindow(self.name_)
		else
			xyd.alert(xyd.AlertType.TIPS, __("UPLOAD_FAIL"))
		end
	end)
end

function UpLoadImgWindow:uploadNomalImg()
end

function UpLoadImgWindow:onSelectTouch()
	self.imgSelect:SetActive(not self.imgSelect.activeSelf)

	if self.imgSelect.activeSelf then
		if self.texture then
			local data = nil

			if self.bigData then
				data = self.bigData
			else
				data = XYDUtils.EncodeToPNG(self.texture)
			end

			self.bigData = data

			if XYDUtils.GetBytesLength(data) >= 1048576 then
				self.imgSize = XYDUtils.GetBytesLength(data) / 1024 / 1024
				self.labelTips_.text = __("GM_IMG_SIZE", string.format("%.2f", self.imgSize) .. "MB")
			else
				self.imgSize = math.ceil(XYDUtils.GetBytesLength(data) / 1024)
				self.labelTips_.text = __("GM_IMG_SIZE", tostring(self.imgSize) .. "KB")
			end

			self.binaryData_ = data
			self.groupMain_.mainTexture = self.texture
		end
	elseif self.texture_small then
		local data = nil

		if self.smallData then
			data = self.smallData
		else
			data = XYDUtils.EncodeToPNG(self.texture_small)
		end

		self.smallData = data

		if XYDUtils.GetBytesLength(data) >= 1048576 then
			self.imgSize = XYDUtils.GetBytesLength(data) / 1024 / 1024
			self.labelTips_.text = __("GM_IMG_SIZE", string.format("%.2f", self.imgSize) .. "MB")
		else
			self.imgSize = math.ceil(XYDUtils.GetBytesLength(data) / 1024)
			self.labelTips_.text = __("GM_IMG_SIZE", tostring(self.imgSize) .. "KB")
		end

		self.binaryData_ = data
		self.groupMain_.mainTexture = self.texture_small
	end
end

function UpLoadImgWindow:onUploadCallback(success, params)
end

function UpLoadImgWindow:showResLoading()
	self.groupLoding_:SetActive(true)
	self.sprGroup_show:SetActive(false)
	XYDCo.WaitForTime(0.5, function ()
		if tolua.isnull(self.window_) then
			return
		end

		if self.spEffect then
			self.spEffect:destroy()

			self.spEffect = nil
		end

		self.imgMask_.color = Color.New(1, 1, 1, 0.7)

		self.sprGroup_show:SetActive(true)

		local sp = xyd.Spine.new(self.groupModel)

		sp:setInfo("loading", function ()
			sp:play("idle", 0)
		end)

		self.spEffect = sp
		local timer = FrameTimer.New(handler(self, self.sprRotation), 1, -1)

		timer:Start()
		XYDCo.WaitForTime(10, function ()
			self:hideResLoading()
		end, "wait_hide_resloading")

		self.sprRotationTimer = timer
	end, "wait_show_resloading")
end

function UpLoadImgWindow:hideResLoading()
	XYDCo.StopWait("wait_show_resloading")
	XYDCo.StopWait("wait_hide_resloading")

	if self.sprRotationTimer then
		self.sprRotationTimer:Stop()

		self.sprRotationTimer = nil
	end

	if self.spEffect then
		self.spEffect:destroy()

		self.spEffect = nil
	end

	if tolua.isnull(self.window_) then
		return
	end

	self.groupLoding_:SetActive(false)

	self.imgMask_.color = Color.New(1, 1, 1, 0.01)
end

function UpLoadImgWindow:sprRotation()
	self.rotationNum_ = (self.rotationNum_ + 5) % 360
	self.sprGroup.transform.localEulerAngles = Vector3(0, 0, 360 - self.rotationNum_)
end

function UpLoadImgWindow:willClose()
	UpLoadImgWindow.super.willClose(self)
	self:hideResLoading()
end

return UpLoadImgWindow
