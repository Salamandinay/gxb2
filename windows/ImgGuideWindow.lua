local BaseWindow = import(".BaseWindow")
local ImgGuideWindow = class("ImgGuideWindow", BaseWindow)
local ImgGuideItem = class("ImgGuideItem", import("app.components.BaseComponent"))
local ImgGuideTable = xyd.tables.imgGuideTable

function ImgGuideWindow:ctor(name, params)
	self.closeCallback = nil
	self.curPage_ = 1
	self.type = params.type or 1
	self.startType = 1
	self.mark_flag = true
	self.delta_ = 0

	if params.start_type then
		self.startType = params.start_type + 1
	end

	if params.wndname then
		self.totalPage_ = tonumber(ImgGuideTable:getGuideNumber(params.wndname)[self.startType])
	end

	if params.totalPage then
		self.totalPage_ = params.totalPage
	end

	if params.items then
		self.items = params.items
	end

	self.closeCallback = params.callback

	BaseWindow.ctor(self, name, params)
end

function ImgGuideWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.btnLeft_ = winTrans:ComponentByName("groupAction/btnPanel/btnLeft_", typeof(UISprite))
	self.btnRight_ = winTrans:ComponentByName("groupAction/btnPanel/btnRight_", typeof(UISprite))
	self.closeBtn = winTrans:NodeByName("groupAction/btnPanel/closeBtn").gameObject
	self.groupMarks_ = winTrans:NodeByName("groupAction/btnPanel/groupMarks_").gameObject
	self.imgBg_ = winTrans:NodeByName("groupAction/imgBg_").gameObject
	self.bg_ = winTrans:ComponentByName("groupAction/bg_", typeof(UISprite))
	self.imgBg1_ = winTrans:NodeByName("groupAction/e:Group/imgBg1_").gameObject
	self.groupMain_ = winTrans:NodeByName("groupAction/e:Group/scroller_/groupMain_").gameObject
	self.scrollerObj = winTrans:NodeByName("groupAction/e:Group/scroller_").gameObject
	self.scroller_panel = winTrans:ComponentByName("groupAction/e:Group/scroller_", typeof(UIPanel))
end

function ImgGuideWindow:initWindow()
	ImgGuideWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:updateLayout()
	self:registerEvent()
	self:register()
end

function ImgGuideWindow:layout()
	if self.type == 2 then
		self.imgBg_:SetActive(false)
		self.imgBg1_:SetActive(true)
	else
		self.imgBg_:SetActive(true)
		self.imgBg1_:SetActive(false)
	end

	if self.totalPage_ <= 1 then
		self.groupMarks_:SetActive(false)
	end

	local iconCount = 0
	local labelCount = 0
	local guideNumber = ImgGuideTable:getGuideNumber(self.params_.wndname)
	local startPos = 0

	if self.items == nil then
		local i = 1

		while i < self.startType do
			startPos = startPos + tonumber(guideNumber[i])
			i = i + 1
		end

		i = 1

		while startPos > i do
			iconCount = iconCount + tonumber(ImgGuideTable:getIconNum(self.params_.wndname)[i])
			labelCount = labelCount + tonumber(ImgGuideTable:getLabelNum(self.params_.wndname)[i])
			i = i + 1
		end

		for i = 1, self.totalPage_ do
			local item = ImgGuideItem.new(self.groupMain_, {
				wndName = self.params_.wndname,
				chapter = i,
				iconStart = iconCount,
				labelStart = labelCount
			})
			iconCount = iconCount + tonumber(ImgGuideTable:getIconNum(self.params_.wndname)[i])
			labelCount = labelCount + tonumber(ImgGuideTable:getLabelNum(self.params_.wndname)[i])
		end
	else
		for i = 1, self.totalPage_ do
			local item = self.items[i].new(self.groupMain_)

			item.go:X(656 * (i - 1))
		end
	end
end

function ImgGuideWindow:updateLayout()
	self:setBtnState()
	self:setMarkState()
end

function ImgGuideWindow:setBtnState()
	if self.totalPage_ == 1 then
		self.btnLeft_:SetActive(false)
		self.btnRight_:SetActive(false)

		return
	end

	if self.curPage_ == 1 then
		self.btnLeft_:SetActive(false)
		self.btnRight_:SetActive(true)
	elseif self.curPage_ == self.totalPage_ then
		self.btnRight_:SetActive(false)
		self.btnLeft_:SetActive(true)
	else
		self.btnRight_:SetActive(true)
		self.btnLeft_:SetActive(true)
	end
end

function ImgGuideWindow:setMarkState()
	if self.totalPage_ <= 1 then
		return
	end

	if self.mark_flag then
		self.mark_flag = false

		for i = 1, self.totalPage_ do
			local img = NGUITools.AddChild(self.groupMarks_, "img" .. tostring(i))
			local sprite = img:AddComponent(typeof(UISprite))

			if i == 1 then
				xyd.setUISpriteAsync(sprite, nil, "emotbtn2_png", function ()
					sprite:MakePixelPerfect()
				end)
			else
				xyd.setUISpriteAsync(sprite, nil, "emotbtn1_png", function ()
					sprite:MakePixelPerfect()
				end)
			end
		end
	else
		for i = 1, self.totalPage_ do
			local sprite = self.groupMarks_:ComponentByName("img" .. tostring(i), typeof(UISprite))

			if i == self.curPage_ then
				xyd.setUISpriteAsync(sprite, nil, "emotbtn2_png", function ()
					sprite:MakePixelPerfect()
				end)
			else
				xyd.setUISpriteAsync(sprite, nil, "emotbtn1_png", function ()
					sprite:MakePixelPerfect()
				end)
			end
		end
	end
end

function ImgGuideWindow:registerEvent()
	UIEventListener.Get(self.btnLeft_.gameObject).onClick = handler(self, self.onLastPage)
	UIEventListener.Get(self.btnRight_.gameObject).onClick = handler(self, self.onNextPage)

	if self.type == 1 then
		UIEventListener.Get(self.imgBg_).onClick = handler(self, self.onTouchOutside)
	elseif self.type == 2 then
		UIEventListener.Get(self.imgBg1_).onDrag = function (event, delta)
			self:onEnd(event, delta)
		end
	end
end

function ImgGuideWindow:onEnd(event, delta)
	self.delta_ = self.delta_ + delta.x

	if self.delta_ > 30 then
		self:onLastPage()
	end

	if self.delta_ < -30 then
		self:onNextPage()
	end

	self.delta_ = 0
end

function ImgGuideWindow:onNextPage()
	if self.curPage_ == self.totalPage_ then
		return
	end

	self.curPage_ = self.curPage_ + 1
	local pos = Vector3(-656 * (self.curPage_ - 1), 0, 0)

	SpringPanel.Begin(self.scroller_panel.gameObject, pos, 8)
	self:updateLayout()
end

function ImgGuideWindow:onLastPage()
	if self.curPage_ == 1 then
		return
	end

	self.curPage_ = self.curPage_ - 1
	local pos = Vector3(-656 * (self.curPage_ - 1), 0, 0)

	SpringPanel.Begin(self.scroller_panel.gameObject, pos, 8)
	self:updateLayout()
end

function ImgGuideWindow:onTouchOutside()
	self:onNextPage()
end

function ImgGuideWindow:onTouchInside()
	self:onNextPage()
end

function ImgGuideWindow:willClose()
	ImgGuideWindow.super.willClose(self)

	if self.closeCallback then
		self:closeCallback()
	end
end

function ImgGuideWindow:setBg(source)
	self.groupMain_:SetActive(true)
	self.groupMarks_:SetActive(self.totalPage_ > 1)
	self.closeBtn:SetActive(true)
	self.btnLeft_:SetActive(true)
	self.btnRight_:SetActive(true)
end

function ImgGuideItem:ctor(parentGo, params)
	self.imgRes = {}
	self.curChapter = params.chapter
	self.labelNum = tonumber(ImgGuideTable:getLabelNum(params.wndName)[params.chapter])
	self.iconNum = tonumber(ImgGuideTable:getIconNum(params.wndName)[params.chapter])
	self.iconStart = params.iconStart
	self.labelStart = params.labelStart
	self.params = params

	ImgGuideItem.super.ctor(self, parentGo)
end

function ImgGuideItem:getPrefabPath()
	local name = string.lower(tostring(ImgGuideTable:getSkinName(self.params.wndName))) .. tostring(self.params.chapter)

	return "Prefabs/Components/img_guide_" .. name .. "_" .. xyd.Global.lang
end

function ImgGuideItem:initUI()
	ImgGuideItem.super.initUI(self)
	self.go:X(656 * (self.curChapter - 1))
	self:layout()
end

function ImgGuideItem:downloadRes()
end

function ImgGuideItem:layout()
	local wnd = xyd.getWindow("img_guide_window")

	if wnd then
		wnd:setBg("img_guide_bg_png")
	end

	for i = 1, self.labelNum do
		local tip_label = XYDUtils.FindDeepChild(self.go, "label" .. tostring(i))
		local label = tip_label:GetComponent(typeof(UILabel))
		local pos = i + self.labelStart

		if label then
			label.text = __("IMG_GUIDE_" .. ImgGuideTable:getLabelName(self.params.wndName) .. tostring(pos))
		end
	end

	for i = 1, self.iconNum do
		local pos = i + self.iconStart
		local sprite = self["icon" .. tostring(i)]

		if sprite then
			local spriteName = "img_guide_" .. ImgGuideTable:getPreName(self.params.wndName) .. "_icon" .. pos .. "_" .. xyd.Global.lang .. "_png"

			xyd.setUISpriteAsync(sprite, nil, spriteName, nil, true)
		end
	end
end

return ImgGuideWindow
