local BaseWindow = import("app.windows.BaseWindow")
local CommonUseCostWindow = class("CommonUseCostWindow", BaseWindow)

function CommonUseCostWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.select_max_num = params.select_max_num
	self.show_max_num = params.show_max_num or self.select_max_num
	self.select_multiple = params.select_multiple or 1
	self.icon_info = params.icon_info
	self.title_text = params.title_text
	self.explain_text = params.explain_text
	self.sure_callback = params.sure_callback
	self.addCallback = params.addCallback
	self.labelNeverText = params.labelNeverText or __("GAMBLE_REFRESH_NOT_SHOW_TODAY")
	self.needTips = params.needTips
	self.hasSelectCallback = params.hasSelectCallback
end

function CommonUseCostWindow:initWindow()
	CommonUseCostWindow.super:initWindow()

	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.title = self.groupAction:ComponentByName("title", typeof(UILabel))
	self.label = self.groupAction:ComponentByName("label", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.selectGroup = self.groupAction:NodeByName("selectGroup").gameObject
	self.btn = self.groupAction:NodeByName("btn").gameObject
	self.btnLabel = self.btn:ComponentByName("button_label", typeof(UILabel))
	self.selectGroup = self.groupAction:NodeByName("selectGroup").gameObject
	self.selectNum_ = import("app.components.SelectNum").new(self.selectGroup, "minmax")

	self.selectNum_:setMaxAndMinBtnPos(224)

	self.itemLabel = self.groupAction:ComponentByName("itemGroup/label", typeof(UILabel))
	self.itemGroup = self.groupAction:NodeByName("itemGroup").gameObject
	self.icon = self.itemGroup:ComponentByName("icon", typeof(UISprite))

	self.selectNum_:setKeyboardPos(0, -340)

	self.selectNum_.inputLabel.text = "1"
	self.addBtn = self.itemGroup:NodeByName("addBtn").gameObject
	self.groupChoose = self.groupAction:NodeByName("groupChoose").gameObject
	self.groupChoose_uiLayout = self.groupAction:ComponentByName("groupChoose", typeof(UILayout))
	self.chooseMask = self.groupChoose:ComponentByName("img", typeof(UISprite))
	self.imgSelect_ = self.chooseMask:ComponentByName("imgSelect", typeof(UISprite))
	self.labelNever_ = self.groupChoose:ComponentByName("labelNever", typeof(UILabel))

	self:layout()
	self:RegisterEvent()
end

function CommonUseCostWindow:layout()
	self.title.text = self.title_text
	self.label.text = self.explain_text
	self.btnLabel.text = __("CONFIRM")
	self.bg.height = 350 + self.label.height - self.label.fontSize

	self.label.gameObject:Y(97 + (self.bg.height - 350) / 2)

	local function callback(num)
		self.itemLabel.text = num * self.select_multiple .. "/" .. self.show_max_num
	end

	self.selectNum_:setInfo({
		minNum = 1,
		curNum = 1,
		maxNum = self.select_max_num,
		callback = callback
	})
	xyd.setUISpriteAsync(self.icon, nil, self.icon_info.name, function ()
		self.icon.width = self.icon_info.width
		self.icon.height = self.icon_info.height
	end)

	if self.addCallback then
		self.addBtn:SetActive(true)

		self.itemLabel.width = 110

		self.itemLabel.gameObject:X(12)
	else
		self.addBtn:SetActive(false)
	end

	if self.labelNeverText then
		self.labelNever_.text = self.labelNeverText
	end

	if self.needTips then
		self.hasSelect_ = false
		local extraHeight = 0
		local widthValue = 420

		if xyd.Global.lang == "fr_fr" then
			widthValue = 445
		end

		if widthValue < self.labelNever_.width then
			self.labelNever_.overflowMethod = UILabel.Overflow.ResizeHeight
			self.labelNever_.width = widthValue

			self.labelNever_:MakePixelPerfect()

			extraHeight = math.max(self.labelNever_.height - 40, 0)
		end

		self.bg.height = self.bg.height + 50 + extraHeight
		local widget1 = self.btn:ComponentByName("", typeof(UISprite))

		widget1:SetTopAnchor(self.itemGroup.gameObject, 1, -103 - extraHeight)
		widget1:SetBottomAnchor(self.itemGroup.gameObject, 1, -179 - extraHeight)
		self.label.gameObject:Y(97 + (self.bg.height - 350) / 2)
		widget1:ResetAndUpdateAnchors()
		self.groupChoose:SetActive(true)
		self.groupChoose_uiLayout:Reposition()
	else
		self.groupChoose:SetActive(false)
	end
end

function CommonUseCostWindow:RegisterEvent()
	UIEventListener.Get(self.btn).onClick = handler(self, function ()
		self.sure_callback(tonumber(self.selectNum_.inputLabel.text))

		if self.hasSelect_ and self.hasSelectCallback then
			self.hasSelectCallback()
		end
	end)

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager:get():closeWindow(self.window_.name)
	end

	if self.addCallback then
		UIEventListener.Get(self.addBtn).onClick = function ()
			self.addCallback()
		end
	end

	if self.needTips then
		UIEventListener.Get(self.chooseMask.gameObject).onClick = handler(self, self.onSelect)
	end
end

function CommonUseCostWindow:onSelect()
	self.imgSelect_.gameObject:SetActive(not self.hasSelect_)

	self.hasSelect_ = not self.hasSelect_
end

return CommonUseCostWindow
