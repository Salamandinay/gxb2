local BaseWindow = import(".BaseWindow")
local HouseShareWindow = class("HouseShareWindow", BaseWindow)
local cjson = require("cjson")

function HouseShareWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.currentSelect_ = 1
	self.channelNum_ = 5
	self.commonSize = {
		width = 220,
		height = 160
	}
	self.fbSize = {
		width = 285,
		height = 160
	}
	self.skinName = "HouseShareWindowSkin"
	self.imgParams = params
	self.uploadImg = params.uploadImg
	self.rotationNum_ = 0
end

function HouseShareWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:showImg()
	self:initList()
	self:registerEvent()
end

function HouseShareWindow:getUIComponent()
	local wndTrans = self.window_.transform
	local groupAction = wndTrans:NodeByName("groupAction").gameObject
	self.btnShare_ = groupAction:NodeByName("btnShare_").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelWinTitle = groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.groupImg = groupAction:ComponentByName("groupImg", typeof(UITexture))
	self.btns = groupAction:NodeByName("btns").gameObject

	for i = 1, self.channelNum_ do
		self["groupPick" .. i] = self.btns:NodeByName("groupPick" .. i).gameObject
		self["btnPick" .. i] = self["groupPick" .. i]:NodeByName("btnPick" .. i).gameObject
		self["btnPickSelect" .. i] = self["btnPick" .. i]:NodeByName("select").gameObject
		self["labelText" .. i] = self["groupPick" .. i]:ComponentByName("labelText" .. i, typeof(UILabel))
	end

	self.groupPick5:SetActive(false)

	self.groupLoding_ = wndTrans:NodeByName("groupLoding_").gameObject
	self.sprGroup = self.groupLoding_:NodeByName("sprGroup_show/sprGroup").gameObject
	self.groupModel = self.groupLoding_:NodeByName("groupModel").gameObject
	self.imgMask_ = self.groupLoding_:ComponentByName("imgMask_", typeof(UISprite))
	self.sprGroup_show = self.groupLoding_:NodeByName("sprGroup_show").gameObject
end

function HouseShareWindow:layout()
	self.btnShare_:ComponentByName("button_label", typeof(UILabel)).text = __("SURE_2")
end

function HouseShareWindow:showImg()
	if not self.uploadImg then
		return
	end

	self.groupImg.mainTexture = self.uploadImg
end

function HouseShareWindow:registerEvent()
	self:register()

	UIEventListener.Get(self.btnShare_).onClick = handler(self, self.onShareTouch)

	for i = 1, self.channelNum_ do
		UIEventListener.Get(self["btnPick" .. tostring(i)]).onClick = function ()
			self:onPickTouch(i)
		end
	end
end

function HouseShareWindow:onPickTouch(index)
	if index == 4 and not xyd.models.guild.guildID then
		xyd.alert(xyd.AlertType.TIPS, __("HOUSE_TEXT_54"))

		return
	end

	self.currentSelect_ = index

	self:updateSelect()
end

function HouseShareWindow:initList()
	for i = 1, self.channelNum_ do
		self["labelText" .. tostring(i)].text = __("HOUSE_SHARE_CHANNEL_" .. tostring(i))
	end

	self:updateSelect()
end

function HouseShareWindow:updateSelect()
	for i = 1, self.channelNum_ do
		local imgSelect = self["btnPickSelect" .. tostring(i)]

		if i == self.currentSelect_ then
			imgSelect:SetActive(true)
		else
			imgSelect:SetActive(false)
		end
	end
end

function HouseShareWindow:onShareTouch()
	xyd.setTouchEnable(self.btnShare_, false)
	self:uploadSourceImg()
end

function HouseShareWindow:uploadSourceImg()
	local bytes = XYDUtils.EncodeToPNG(self.uploadImg)
	local md5Name1 = XYDUtils.GetMd5Hash(bytes) .. ".png"
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
			NGUITools.Save(xyd.HOUSE_IMG_SAVE_PATH .. uploadNames[1], uploadBytes[1])
			xyd.WebPictureManager.get():addDataByUrl(xyd.downloadGMImgURL() .. uploadNames[1], xyd.HOUSE_IMG_SAVE_PATH .. uploadNames[1])
			self:onUploadCallback(success, {
				width = self.imgParams.width,
				height = self.imgParams.height,
				img = xyd.downloadGMImgURL() .. uploadNames[1],
				fileName = uploadNames[1]
			})
		else
			xyd.alert(xyd.AlertType.TIPS, __("UPLOAD_FAIL"))
		end
	end)
end

function HouseShareWindow:onUploadCallback(success, params)
	if success then
		print(params)
		self:sendMsg(params)
		xyd.closeWindow(self.name_)
		xyd.alert(xyd.AlertType.TIPS, __("HOUSE_TEXT_52"))
		xyd.models.house:setShareTimeKey()
	else
		xyd.setTouchEnable(self.btnShare_, true)
		xyd.alert(xyd.AlertType.TIPS, __("UPLOAD_FAIL"))
		self:hideResLoading()
	end
end

function HouseShareWindow:sendMsg(params)
	local data = {
		width = params.width,
		height = params.height,
		img = params.img,
		house_share_mark = xyd.HOUSE_SHARE_MAKR,
		fileName = params.fileName
	}
	local str = cjson.encode(data)

	if self.currentSelect_ == 1 then
		xyd.models.chat:sendServerMsg(str, xyd.MsgType.HOUSE_SHARE_NORMAL)
	elseif self.currentSelect_ == 2 then
		xyd.models.chat:sendLocalMsg(str, xyd.MsgType.HOUSE_SHARE_LOCAL_CHAT)
	elseif self.currentSelect_ == 3 then
		xyd.models.chat:sendCrossMsg(str, xyd.MsgType.HOUSE_SHARE_CROSS_CHAT)
	elseif self.currentSelect_ == 4 then
		xyd.models.chat:sendGuildMsg(str, xyd.MsgType.HOUSE_SHARE_GUILD)
	end
end

function HouseShareWindow:showResLoading()
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

function HouseShareWindow:hideResLoading()
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

function HouseShareWindow:sprRotation()
	self.rotationNum_ = (self.rotationNum_ + 5) % 360
	self.sprGroup.transform.localEulerAngles = Vector3(0, 0, 360 - self.rotationNum_)
end

function HouseShareWindow:willClose()
	HouseShareWindow.super.willClose(self)
	self:hideResLoading()
end

return HouseShareWindow
