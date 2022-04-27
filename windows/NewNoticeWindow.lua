local BaseWindow = import(".BaseWindow")
local NewNoticeWindow = class("NewNoticeWindow", BaseWindow)
local SettingUpInfoItem = class("SettingUpInfoItem", import("app.components.CopyComponent"))
local json = require("cjson")

function SettingUpInfoItem:ctor(go, parent, index)
	self.parent_ = parent
	self.index_ = index

	SettingUpInfoItem.super.ctor(self, go)
end

function SettingUpInfoItem:initUI()
	SettingUpInfoItem.super.initUI(self)
	self:getUIComponent()
end

function SettingUpInfoItem:setInfo(data, long)
	self.labelTitle_.text = data.title
	self.id_ = data.id
	local contents = {}

	if data.contents and data.contents ~= "" then
		contents = json.decode(data.contents)
	end

	self.totalHeight = 0
	local showUrl = ""

	for index, content in ipairs(contents) do
		if content.title and content.title ~= "" then
			local RootNew = NGUITools.AddChild(self.dialogGrid_.gameObject, self.titleItem_.gameObject)

			RootNew.transform:Y(-self.totalHeight)
			RootNew.transform:X(-300)

			local titleLabel = RootNew:ComponentByName("titleLabel", typeof(UILabel))
			self.totalHeight = self.totalHeight + 49
			titleLabel.text = content.title
		end

		if content.contents and #content.contents > 0 then
			for i = 1, #content.contents do
				local text = content.contents[i]
				local strs = xyd.split(text, "||")

				for _, str in ipairs(strs) do
					local str2 = xyd.split(str, "|")
					local itemNew = NGUITools.AddChild(self.dialogGrid_.gameObject, self.lineItem_)

					itemNew:SetActive(true)

					itemNew.transform.localPosition = Vector3(0, -self.totalHeight, 0)
					local label = itemNew:ComponentByName("lable", typeof(UILabel))
					local imgIcon = itemNew:ComponentByName("imgIcon", typeof(UISprite))

					imgIcon.gameObject:SetActive(false)

					if not string.find(str2[1], "_png") then
						self:setLabelInfo(label, {
							c = 1549556991,
							s = 20,
							x = 16,
							t = str2[1]
						})

						label.transform.localPosition = Vector3(-290, 0, 0)
						self.totalHeight = self.totalHeight + label.height + 10
					end

					local goLine1 = NGUITools.AddChild(itemNew, imgIcon.gameObject)

					goLine1:SetActive(true)

					local goLine1Img = goLine1:GetComponent(typeof(UISprite))

					xyd.setUISpriteAsync(goLine1Img, nil, "setting_up_help_icon_2", nil, )

					goLine1Img.transform.localScale = Vector3(0.5, 0.5, 0.5)

					goLine1:SetLocalPosition(-300, -10, 0)

					local itemNew2 = NGUITools.AddChild(self.dialogGrid_.gameObject, self.lineItem_)

					itemNew2:SetActive(true)

					itemNew2.transform.localPosition = Vector3(0, -self.totalHeight, 0)
					local label2 = itemNew2:ComponentByName("lable", typeof(UILabel))

					self:setLabelInfo(label2, {
						c = 1549556991,
						s = 20,
						t = str2[2] or "----++++++=====+++++-----"
					})

					self.totalHeight = self.totalHeight + label2.height + 18
				end
			end
		end

		if content.url and content.url ~= "" then
			showUrl = content.url
		end
	end

	if data.jump and tostring(data.jump) ~= "" then
		self.jump = data.jump
		self.totalHeight = self.totalHeight + 88
	end

	self.dialogImg_.height = self.totalHeight + 30

	self.jumpBtn_.transform:Y(-(self.totalHeight - 6))

	self.all = long * 92 + self.totalHeight + 30 - 721

	if showUrl and showUrl ~= "" then
		showUrl = self:changeUnityUrl(showUrl)

		self:loadImgByUrl(showUrl, self.topImg_)
	end

	if self.index_ == 1 then
		self:showAction()
	else
		self:playHide()
	end
end

function SettingUpInfoItem:onClickJump()
	if tonumber(self.jump) and tonumber(self.jump) > 0 then
		xyd.WindowManager.get():closeWindow("setting_up_window")
		self:onWindowGo(self.jump)
	elseif tostring(self.jump) and tostring(self.jump) ~= "" then
		UnityEngine.Application.OpenURL(self.jump)
	end
end

function SettingUpInfoItem:onWindowGo(id)
	local windowGoId = id
	local windowGoTable = xyd.tables.windowGoTable
	local windowName = windowGoTable:getWindowName(windowGoId)
	local params = windowGoTable:getParams(windowGoId)
	local funcId = windowGoTable:getFunctionId(windowGoId)
	local activityId = windowGoTable:getActivityId(windowGoId)

	self:checkAndOpen(windowName, params, funcId, activityId)
end

function SettingUpInfoItem:checkAndOpen(winName, params, funID, activityId)
	if funID and funID > 0 and not xyd.checkFunctionOpen(funID) then
		return
	end

	if activityId and tonumber(activityId) > 0 and not xyd.models.activity:isOpen(tonumber(activityId)) then
		xyd.showToast(__("ACTIVITY_OPEN_TEXT"))

		return
	end

	xyd.WindowManager.get():openWindow(winName, params)
	self.parent_:close()
end

function SettingUpInfoItem:loadImgByUrl(url, texture)
	xyd.setTextureByURL(url, texture, nil, , function ()
		self.topItem_:SetActive(true)
		texture:MakePixelPerfect()

		self.dialogImg_.height = self.totalHeight + texture.height + 38

		self.jumpBtn_.transform:Y(-(self.totalHeight + 50 + texture.height + 43 - 109))

		self.all = self.all + texture.height + 38

		self:waitForFrame(1, function ()
			local wnd = xyd.WindowManager.get():getWindow("new_notice_window")

			if wnd then
				wnd.grid_:Reposition()
			end

			self.uiLayout_:Reposition()
		end)
	end)
end

function SettingUpInfoItem:changeUnityUrl(url)
	if xyd.isH5() then
		return url
	end

	local list = xyd.split(url, "/")
	local pngStr = list[#list]
	local index = string.find(pngStr, ".png") or string.find(pngStr, ".jpg")

	if index and index > 0 then
		pngStr = string.sub(pngStr, 1, index - 1)
		local newPngStr = pngStr .. "_unity"
		url = string.gsub(url, pngStr, newPngStr)
	end

	return url
end

function SettingUpInfoItem:getUIComponent()
	local itemTrans = self.go.transform
	self.groupTitleBg_ = itemTrans:NodeByName("groupTitle/img").gameObject
	self.groupDialog_ = itemTrans:NodeByName("groupDialog").gameObject
	self.labelTitle_ = itemTrans:ComponentByName("groupTitle/labelTitle", typeof(UILabel))
	self.imgArr_ = itemTrans:ComponentByName("groupTitle/imgArr", typeof(UISprite))
	self.dialogImg_ = itemTrans:ComponentByName("groupDialog/img", typeof(UISprite))
	self.uiLayout_ = itemTrans:ComponentByName("groupDialog/img", typeof(UILayout))
	self.topItem_ = self.dialogImg_.transform:NodeByName("topItem").gameObject
	self.dialogGrid_ = itemTrans:NodeByName("groupDialog/img/itemGroup")
	self.lineItem_ = itemTrans:NodeByName("groupDialog/img/lineItem").gameObject
	self.topImg_ = itemTrans:ComponentByName("groupDialog/img/topImg", typeof(UITexture))
	self.titleItem_ = itemTrans:NodeByName("groupDialog/img/titleItem").gameObject
	self.jumpBtn_ = itemTrans:NodeByName("groupDialog/jumpBtn").gameObject
	self.jumpBtnLabel_ = self.jumpBtn_:ComponentByName("label", typeof(UILabel))
	UIEventListener.Get(self.groupTitleBg_.gameObject).onClick = handler(self, self.onClick)
	UIEventListener.Get(self.jumpBtn_).onClick = handler(self, self.onClickJump)
	self.jumpBtnLabel_.text = __("NOTICE_BTN_GO_TO_TEXT")
end

function SettingUpInfoItem:setLabelInfo(label, params)
	if params.w then
		label.width = params.w
	end

	if params.h then
		label.height = params.h
	end

	if params.s then
		label.fontSize = params.s
	end

	if params.c then
		label.color = Color.New2(params.c)
	end

	if params.t then
		label.text = params.t
	end

	if params.b then
		label.fontStyle = UnityEngine.FontStyle.Bold
	else
		label.fontStyle = UnityEngine.FontStyle.Normal
	end

	if params.p then
		label.pivot = UIWidget.Pivot[params.p]
	end

	if params.ec then
		label.effectStyle = UILabel.Effect.Outline
		label.effectDistance = Vector2(1, 1)
		label.effectColor = Color.New2(params.ec)
	end
end

function SettingUpInfoItem:onClick()
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	if self.isShow_ then
		self:playHide()
	else
		self:showAction()
	end
end

function SettingUpInfoItem:showAction()
	self.parent_:playHideItem()

	self.isShow_ = true

	self.dialogImg_:SetLocalScale(1, 1, 1)

	self.dialogImg_.alpha = 0

	self.dialogImg_:SetActive(true)
	self.parent_.grid_:Reposition()
	self.dialogImg_:SetLocalScale(1, 0, 1)

	self.dialogImg_.alpha = 1

	self.uiLayout_:Reposition()

	local action = DG.Tweening.DOTween.Sequence()
	self.imgArr_.transform.localEulerAngles = Vector3(0, 0, 0)

	action:Insert(0, self.dialogImg_.transform:DOScale(Vector3(1, 1, 1), 0.1))
	action:AppendCallback(function ()
		if self.jump and tostring(self.jump) ~= "" then
			self.jumpBtn_:SetActive(true)
		else
			self.jumpBtn_:SetActive(false)
		end

		self.parent_.grid_:Reposition()
		self.uiLayout_:Reposition()
		XYDCo.WaitForFrame(1, function ()
			self.parent_.scrollView_:SetDragAmount(0, math.min(1, (self.index_ - 1) * 92 / self.all), false)
		end, nil)
	end)
	self.parent_:updateReadList(self.id_)
end

function SettingUpInfoItem:isShow()
	return self.isShow_
end

function SettingUpInfoItem:playHide(noAction, callback)
	if not self.isShow_ then
		return
	end

	self.imgArr_.transform.localEulerAngles = Vector3(0, 0, 90)

	if noAction then
		self.isShow_ = false
		self.dialogImg_.transform.localScale = Vector3(1, 0, 1)

		self.parent_.grid_:Reposition()
		self.jumpBtn_:SetActive(false)
	else
		local action = DG.Tweening.DOTween.Sequence()

		action:Insert(0, self.dialogImg_.transform:DOScale(Vector3(1, 0, 1), 0.1))
		action:AppendCallback(function ()
			self.dialogImg_:SetActive(false)

			self.isShow_ = false

			self.jumpBtn_:SetActive(false)
			XYDCo.WaitForFrame(1, function ()
				self.parent_.grid_:Reposition()

				if callback then
					callback()
				end
			end, nil)
		end)
	end
end

function NewNoticeWindow:ctor(name, params)
	NewNoticeWindow.super.ctor(self, name, params)

	self.noticeItemList_ = {}
	self.chooenIndex_ = 1
end

function NewNoticeWindow:initWindow()
	NewNoticeWindow.super.initWindow(self)
	self:getUIComponent()
	self:initList()
	self:register()
end

function NewNoticeWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.title_ = winTrans:ComponentByName("title", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.scrollView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("scrollView/grid", typeof(UITable))
	self.notice_item_ = winTrans:NodeByName("notice_item").gameObject
	self.title_.text = __("SETTING_UP_WINDOW_11")
end

function NewNoticeWindow:register()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end
end

function NewNoticeWindow:initList()
	local game_notice_data = xyd.models.settingUp:getGameNotices()
	self.lineNum_ = 0

	table.sort(game_notice_data, function (a, b)
		return a.order < b.order
	end)

	for index, data in ipairs(game_notice_data) do
		if data.start_time <= xyd.getServerTime() and xyd.getServerTime() <= data.end_time then
			self.lineNum_ = self.lineNum_ + 1
		end
	end

	for _, data in ipairs(game_notice_data) do
		if data.start_time <= xyd.getServerTime() and xyd.getServerTime() <= data.end_time then
			local index = #self.noticeItemList_ + 1
			local newItemRoot = NGUITools.AddChild(self.grid_.gameObject, self.notice_item_)
			self.noticeItemList_[index] = SettingUpInfoItem.new(newItemRoot, self, index)

			self.noticeItemList_[index]:setInfo(data, self.lineNum_)
			self.grid_:Reposition()

			if index == 1 or self.lineNum_ <= index then
				self.scrollView_:ResetPosition()
			end
		end
	end

	for idx, item in ipairs(self.noticeItemList_) do
		if not item:isShow() then
			item:playHide(true)
		end
	end

	self.grid_:Reposition()
	self.scrollView_:ResetPosition()

	self.scrollPos_ = self.scrollView_.transform.localPosition
end

function NewNoticeWindow:playHideItem()
	for idx, item in ipairs(self.noticeItemList_) do
		if item:isShow() then
			item:playHide(true)

			break
		end
	end
end

function NewNoticeWindow:updateReadList(id)
	xyd.models.settingUp:addReadId(id)
end

function NewNoticeWindow:willClose(callback)
	local win = xyd.WindowManager.get():getWindow("main_window")
	local win2 = xyd.WindowManager.get():getWindow("setting_up_window")

	xyd.models.settingUp:updateGetNoticeReadList()

	if win then
		win:updateBtnNotice()
	end

	if win2 then
		win2:updateNoticeShow()
	end

	NewNoticeWindow.super.willClose(self, callback)
end

return NewNoticeWindow
