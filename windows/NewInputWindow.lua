local NewInputWindow = class("NewInputWindow", import(".BaseWindow"))
local CopyAndPaste = import("app.components.CopyAndPaste")

function NewInputWindow:ctor(name, params)
	NewInputWindow.super.ctor(self, name, params)

	self.data_ = params
	self.curType_ = params.type
	self.inputModel_ = xyd.models.textInput
	self.lineNum = 0
	self.max_line = params.max_line
	self.max_length = params.max_length
	self.max_tips = params.max_tips
	self.check_marks = params.check_marks
	self.check_length_function = params.check_length_function
	self.is_no_check_illegal = params.is_no_check_illegal
end

function NewInputWindow:initWindow()
	self:getUIComponent()

	local default_Y = -xyd.Global.getRealHeight() / 2 + self:getGoHeight()

	self.go_:Y(default_Y)
	self.groupPaste:Y(default_Y + 62)
	NewInputWindow.super.initWindow(self)

	self.isCanClose = true

	self:setNotCloseState()
	self:registerEvent()
	self:layout()
end

function NewInputWindow:getUIComponent()
	local winTrans = self.window_.transform
	local go = winTrans:NodeByName("singleLine").gameObject
	self.touchBg = winTrans:NodeByName("touchBg").gameObject
	self.inputPanelCon = go:NodeByName("inputPanelCon").gameObject
	self.inputPanelCon_UIWidget = go:ComponentByName("inputPanelCon", typeof(UIWidget))
	self.inputPanel_obj = self.inputPanelCon:NodeByName("inputPanel").gameObject
	self.inputPanel_UIScrollView = self.inputPanelCon:ComponentByName("inputPanel", typeof(UIScrollView))
	self.label = self.inputPanel_obj:ComponentByName("label", typeof(UILabel))
	self.input_ = self.inputPanelCon:ComponentByName("input", typeof(ChatInput))
	self.groupLayout = go:ComponentByName("group", typeof(UILayout))
	self.labelSure = go:ComponentByName("group/labelSure", typeof(UILabel))
	self.labelSureBoxCollider = go:ComponentByName("group/labelSure", typeof(UnityEngine.BoxCollider))
	self.labelCancel = go:ComponentByName("group/labelCancel", typeof(UILabel))
	self.labelCancelBoxCollider = go:ComponentByName("group/labelCancel", typeof(UnityEngine.BoxCollider))
	self.groupPaste = winTrans:NodeByName("groupPaste").gameObject
	self.btnPaste = self.groupPaste:NodeByName("btnPaste").gameObject
	self.input_.submitOnUnselect = true
	self.go_ = go

	self.inputPanel_UIScrollView:ResetPosition()

	self.input_.isOnDragLight = false
	self.input_.isSupportArabic = true

	if UNITY_EDITOR or UNITY_ANDROID and XYDUtils.CompVersion(UnityEngine.Application.version, "1.4.30") >= 0 or UNITY_IOS and XYDUtils.CompVersion(UnityEngine.Application.version, "71.2.94") >= 0 then
		self.CopyAndPaste_ = CopyAndPaste.new(self.label, self.input_, self.input_.gameObject, self.input_:GetComponent(typeof(UIDragScrollView)), self.groupPaste, handler(self, self.updateLabelPos))
	end
end

function NewInputWindow:layout()
	self.labelSure.text = __("COMPLETE")
	self.labelCancel.text = __("CANCEL_2")

	self:init()
	self:setFocus()

	if xyd.Global.lang == "fr_fr" then
		self.labelSure.fontSize = 28
		self.labelCancel.fontSize = 28

		self.groupLayout:Reposition()
	end

	self.labelSureBoxCollider.size = Vector3(self.labelSure.width, 90, 0)
	self.labelCancelBoxCollider.size = Vector3(self.labelCancel.width, 90, 0)
end

function NewInputWindow:init()
	if self.data_.inputType then
		self.input_.inputType = self.data_.inputType
	else
		self.input_.inputType = UIInput.InputType.Standard
	end

	if self.data_.limit then
		self.input_.characterLimit = self.data_.limit
	else
		self.input_.characterLimit = 0
	end

	if self.data_.defaultText then
		self.input_.defaultText = self.data_.defaultText
	else
		self.input_.defaultText = ""
	end

	if self.data_.text then
		self.input_.value = self.data_.text
	else
		self.input_.value = ""
	end

	self.label.multiLine = true
end

function NewInputWindow:registerEvent()
	UIEventListener.Get(self.labelSure.gameObject).onPress = handler(self, self.onSureTouch)
	UIEventListener.Get(self.labelCancel.gameObject).onPress = handler(self, self.onCancelTouch)
	UIEventListener.Get(self.btnPaste).onClick = handler(self, self.onPasteTouch)
	UIEventListener.Get(self.touchBg).onClick = handler(self, self.onTouchBg)

	XYDUtils.AddEventDelegate(self.input_.onChange, handler(self, self.onChange))
	self.eventProxy_:addEventListener(xyd.event.SDK_KEYBOARD_EVENT, handler(self, self.onKeyBoardEvent))
end

function NewInputWindow:onSureTouch(gameObject, isPressed)
	self:onSubmit()
end

function NewInputWindow:onChange()
	local pos = self.input_.caretVerts
	local pos_y = math.abs(tonumber(pos.y))
	local lineNum = math.floor(pos_y / self.label.fontSize)
	local length = xyd.getStrLength(self.input_.value)

	if self.check_length_function then
		length = self.check_length_function(self.input_.value)
	end

	local default_line_max = xyd.tables.miscTable:getNumber("talk_text_line_limit", "value")
	local default_length_max = 99999999
	local default_tips_max = __("TALK_TEXT_LINE_LIMIT_TIPS")

	if self.max_line then
		default_line_max = self.max_line
	end

	if self.max_length then
		default_length_max = self.max_length
	end

	if self.max_tips then
		default_tips_max = self.max_tips
	end

	if self.check_marks and length > 0 and xyd.tables.filterWordTable:isInMarks(self.input_.value) then
		if not self.lastTextValue then
			self.lastTextValue = ""
		end

		self.input_.value = self.lastTextValue

		xyd.alertTips(__("CHAT_HAS_BLACK_WORD"))

		return
	end

	if not self.is_no_check_illegal and length > 0 and xyd.tables.filterWordTable:isInWords(self.input_.value) then
		if not self.lastTextValue then
			self.lastTextValue = ""
		end

		self.input_.value = self.lastTextValue

		xyd.alertTips(__("CHAT_HAS_BLACK_WORD"))

		return
	end

	if default_length_max < length or self.label.height > default_line_max * self.label.fontSize then
		if not self.lastTextValue then
			self.lastTextValue = ""
		end

		self.input_.value = self.lastTextValue

		self:onChange()
		xyd.alertTips(default_tips_max)

		return
	else
		self.lastTextValue = self.input_.value
	end

	if self.label.height > 40 and self.firstToLong == nil then
		self.inputPanelCon_UIWidget.height = 87
		self.firstToLong = true
		self.inputPanel_UIScrollView.padding = Vector3(0, 0)

		self:waitForFrame(1, function ()
			self.inputPanel_UIScrollView:ResetPosition()
		end)
		self:changePos()
	end

	if self.label.height <= 40 and self.firstToLong == true then
		self.inputPanelCon_UIWidget.height = 52
		self.firstToLong = nil
		self.inputPanel_UIScrollView.padding = Vector3(0, 3)

		self:waitForFrame(1, function ()
			self.inputPanel_UIScrollView:ResetPosition()
		end)
		self:changePos()
	end

	if lineNum ~= self.lineNum and lineNum > 2 then
		pos = Vector3(0, 57 + (lineNum - 2) * self.label.fontSize, 0)

		self:waitForFrame(2, function ()
			SpringPanel.Begin(self.inputPanel_obj.gameObject, pos, 8)
		end)
	end

	if lineNum ~= self.lineNum and lineNum <= 2 and self.label.height > 40 and self.lineNum == 3 and lineNum == 2 then
		pos = Vector3(0, 57, 0)

		self:waitForFrame(2, function ()
			SpringPanel.Begin(self.inputPanel_obj.gameObject, pos, 8)
		end)
	end

	self.lineNum = lineNum

	if self.data_.onChangeCallBack then
		self.data_.onChangeCallBack(self.input_.value)
	end
end

function NewInputWindow:updateLabelPos(delte)
	local maxNum = math.ceil(self.label.height / self.label.fontSize)

	if not self.lineNum then
		self.lineNum = 1
	end

	local newLine = nil

	if maxNum < self.lineNum + delte then
		newLine = maxNum
	elseif self.lineNum + delte <= 1 then
		newLine = 1
	else
		newLine = self.lineNum + delte
	end

	local pos = nil

	if newLine ~= self.lineNum and newLine > 2 then
		pos = Vector3(0, 57 + (newLine - 2) * self.label.fontSize, 0)

		self:waitForFrame(2, function ()
			SpringPanel.Begin(self.inputPanel_obj.gameObject, pos, 8)
		end)

		self.lineNum = newLine
	end

	if newLine ~= self.lineNum and newLine <= 2 and self.label.height > 40 and self.lineNum == 3 and newLine == 2 then
		pos = Vector3(0, 57, 0)

		self:waitForFrame(2, function ()
			SpringPanel.Begin(self.inputPanel_obj.gameObject, pos, 8)
		end)

		self.lineNum = newLine
	end
end

function NewInputWindow:onPasteTouch()
	local text = NGUITools.clipboard or ""
	local val = xyd.insertStringInUIInput(self.input_, text)
	self.input_.value = val
end

function NewInputWindow:onCancelTouch(gameObject, isPressed)
	if self.isCanClose == false then
		return
	end

	self.cancelTouch_ = true

	self:onSubmit()
end

function NewInputWindow:onSubmit()
	if self.isCanClose == false then
		return
	end

	if self.input_ then
		self.inputModel_:onSubmit(self.input_.value, self.cancelTouch_)
		dump("增加ios測試日誌2")
		self.input_:Deselect()

		self.hasDeselect = true

		xyd.closeWindow(self.name_)
	end
end

function NewInputWindow:onTouchBg()
	self:onSubmit()
end

function NewInputWindow:setFocus()
	self.input_.isSelected = true
end

function NewInputWindow:onKeyBoardEvent()
	self:changePos()
end

function NewInputWindow:getGoHeight()
	return 73
end

function NewInputWindow:willClose()
	NewInputWindow.super.willClose(self)

	if not self.hasDeselect and self.input_ then
		dump("增加ios測試日誌1")
		self.input_:Deselect()

		self.hasDeselect = true
	end
end

function NewInputWindow:changePos()
	local isShow_ = self.inputModel_:isShow()

	if isShow_ then
		local posY = self.inputModel_:getKeyBoardHeight() + self:getGoHeight() / 2

		self.go_:Y(posY)

		if self.firstToLong then
			self.groupPaste:Y(posY + 55)
		else
			self.groupPaste:Y(posY + 25)
		end

		self:onChange()
		self:setNotCloseState()
	else
		self:onTouchBg()
	end
end

function NewInputWindow:setNotCloseState()
	if self.closeKey then
		XYDCo.StopWait(self.closeKey)
	end

	self.isCanClose = false
	self.closeKey = self:waitForTime(0.5, function ()
		self.isCanClose = true
	end)
end

function NewInputWindow:getPositionY()
	return self.go_.transform.localPosition.y
end

return NewInputWindow
