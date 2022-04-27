local BaseWindow = import(".BaseWindow")
local NoticeWindow = class("NoticeWindow", BaseWindow)
local NoticeItem = class("NoticeItem")
local SettingUpModel = xyd.models.settingUp

function NoticeWindow:ctor(name, params)
	NoticeWindow.super.ctor(self, name, params)

	self.notices_ = {}
	self.animationList_ = {}
	self.noticeItems_ = {}
end

function NoticeWindow:initWindow()
	BaseWindow.initWindow(self)

	local winTrans = self.window_.transform
	self.winTitle_ = winTrans:ComponentByName("groupAction/groupTop/labelTitle", typeof(UILabel))
	self.closeBtn_ = winTrans:ComponentByName("groupAction/groupTop/closeBtn", typeof(UISprite)).gameObject
	self.noticeItemRoot_ = winTrans:NodeByName("groupAction/groupMid/noticeItem").gameObject
	self.table_ = winTrans:ComponentByName("groupAction/groupMid/scrollView/table", typeof(UITable))

	self.noticeItemRoot_:SetActive(false)

	self.winTitle_.text = __("NOTICE_WINDOW")

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function NoticeWindow:playOpenAnimation(callback)
	NoticeWindow.super.playOpenAnimation(self, function ()
		if not self.close_ then
			self:layout()

			if callback then
				callback()
			end
		end
	end)
end

function NoticeWindow:layout()
	local data = SettingUpModel:getNotice()

	if not data or not data.contents then
		self.close_ = true

		xyd.WindowManager.get():closeWindow(self.name_)

		return
	end

	for i = 1, #data.contents do
		if data.contents[i] then
			local itemRoot = NGUITools.AddChild(self.table_.gameObject, self.noticeItemRoot_)

			itemRoot:SetActive(true)

			local notice = NoticeItem.new(itemRoot, self)

			notice:setInfos(data.contents[i])
			table.insert(self.noticeItems_, notice)
		end
	end

	self.table_:Reposition()
end

function NoticeItem:ctor(go, parent)
	self.go_ = go
	self.parent_ = parent
	self.uiLayout_ = self.go_:GetComponent(typeof(UILayout))
	self.groupImg_ = self.go_.transform:NodeByName("groupImg")
	self.imgUrl_ = self.groupImg_.transform:ComponentByName("img", typeof(UITexture))
	self.groupTips_ = self.go_.transform:ComponentByName("groupLabel/groupTips", typeof(UIWidget))
	self.lableTips_ = self.groupTips_.transform:ComponentByName("labelTips", typeof(UILabel))
	self.groupDesc_ = self.go_.transform:ComponentByName("groupLabel/groupDesc", typeof(UITable))
	self.descLabel_ = self.groupDesc_.transform:ComponentByName("labelDesc", typeof(UILabel))

	self.descLabel_.gameObject:SetActive(false)
end

function NoticeItem:setInfos(data)
	self.data_ = data

	if not self.data_ then
		self.go_:SetActive(false)
	end

	if not data.title or data.title == "" then
		self.groupTips_.gameObject:SetActive(false)
	else
		self.lableTips_.text = data.title

		self.groupTips_.gameObject:SetActive(true)
		self:setVisibleEase(self.groupTips_, true)
	end

	local frameCount = 0
	local url = data.url

	if XYDUtils.IsTest() then
		-- Nothing
	end

	if url and url ~= "" then
		url = self:changeUnityUrl(url)

		self:loadImgByUrl(url, self.imgUrl_)
	end

	if data.contents and #data.contents > 0 then
		for _, content in ipairs(data.contents) do
			frameCount = frameCount + 1

			if frameCount then
				XYDCo.WaitForFrame(frameCount, function ()
					if not tolua.isnull(self.groupDesc_) then
						local newItem = NGUITools.AddChild(self.groupDesc_.gameObject, self.descLabel_.gameObject)
						local newLabel = newItem:GetComponent(typeof(UILabel))
						local content2 = string.gsub(content, "<font color=0x(%w+)>", "[c][%1]")
						local content3 = string.gsub(content2, "</font>", "[-][/c]")
						local content4 = string.gsub(content3, "<font size=\"(%d+)\">", "[size=%1]")
						local content5 = string.gsub(content4, "<a href=\"([^>]+)\">", "[url=%1]")
						local content6 = string.gsub(content5, "</a>", "[/u]")
						local content7 = string.gsub(content6, "<big>", "")
						local content8 = string.gsub(content7, "</big>", "")
						newLabel.text = content8

						self:setVisibleEase(newLabel, true)
						self.groupDesc_:Reposition()

						if string.find(content8, "url=") then
							xyd.setUrlLabelTouch(newLabel)
						end
					end

					if frameCount == #data.contents then
						local wnd = xyd.WindowManager.get():getWindow("notice_window")

						if wnd then
							wnd.table_:Reposition()
						end
					end
				end, nil)
			end
		end
	end
end

function NoticeItem:changeUnityUrl(url)
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

function NoticeItem:setVisibleEase(obj, visible)
	local widget = obj.gameObject:GetComponent(typeof(UIWidget))
	local from = visible and 0 or 1
	local to = visible and 1 or 0
	widget.alpha = from

	local function setter(value)
		widget.alpha = value
	end

	local action = DG.Tweening.DOTween.Sequence()

	table.insert(self.parent_.animationList_, action)
	action:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), from, to, 0.3))
end

function NoticeItem:loadImgByUrl(url, texture)
	xyd.setTextureByURL(url, texture, nil, , function ()
		texture:MakePixelPerfect()

		self.groupImg_:GetComponent(typeof(UIWidget)).width = texture.width
		self.groupImg_:GetComponent(typeof(UIWidget)).height = texture.height
		local wnd = xyd.WindowManager.get():getWindow("notice_window")

		if wnd then
			wnd.table_:Reposition()
		end

		self.uiLayout_:Reposition()
	end)
end

return NoticeWindow
