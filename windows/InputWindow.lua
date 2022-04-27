local InputWindow = class("InputWindow", import(".BaseWindow"))
local CopyAndPaste = import("app.components.CopyAndPaste")

function InputWindow:ctor(name, params)
	InputWindow.super.ctor(self, name, params)

	self.data_ = params
	self.curType_ = params.type
	self.inputModel_ = xyd.models.textInput
	self.max_length = params.max_length
	self.max_tips = params.max_tips
end

function InputWindow:initWindow()
	self:getUIComponent()

	local default_Y = -xyd.Global.getRealHeight() / 2 + self:getGoHeight()

	dump(default_Y, "初始化沒有走sdk時給個默認值")
	self.go_:Y(default_Y)
	self.groupPaste:Y(default_Y + 62)
	InputWindow.super.initWindow(self)

	self.isCanClose = true

	self:registerEvent()
	self:layout()
	self:setNotCloseState()
end

function InputWindow:getUIComponent()
	local winTrans = self.window_.transform
	local go = winTrans:NodeByName("singleLine").gameObject
	self.touchBg = winTrans:NodeByName("touchBg").gameObject
	self.label = go:ComponentByName("label", typeof(UILabel))
	self.input_ = go:ComponentByName("input", typeof(ChatInput))
	self.groupLayout = go:ComponentByName("group", typeof(UILayout))
	self.labelSure = go:ComponentByName("group/labelSure", typeof(UILabel))
	self.labelCancel = go:ComponentByName("group/labelCancel", typeof(UILabel))
	self.groupPaste = winTrans:NodeByName("groupPaste").gameObject
	self.btnPaste = self.groupPaste:NodeByName("btnPaste").gameObject
	self.input_.submitOnUnselect = true
	self.go_ = go
end

function InputWindow:layout()
	self.labelSure.text = __("COMPLETE")
	self.labelCancel.text = __("CANCEL_2")

	self:init()
	self:setFocus()

	if xyd.Global.lang == "fr_fr" then
		self.labelSure.fontSize = 28
		self.labelCancel.fontSize = 28

		self.groupLayout:Reposition()
	end
end

function InputWindow:init()
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

	if self.curType_ == xyd.TextInputArea.InputSingleLine then
		self.label.multiLine = false
	else
		self.label.multiLine = true
	end
end

function InputWindow:registerEvent()
	UIEventListener.Get(self.labelSure.gameObject).onPress = handler(self, self.onSureTouch)
	UIEventListener.Get(self.labelCancel.gameObject).onPress = handler(self, self.onCancelTouch)
	UIEventListener.Get(self.btnPaste).onClick = handler(self, self.onPasteTouch)
	UIEventListener.Get(self.touchBg).onClick = handler(self, self.onTouchBg)

	XYDUtils.AddEventDelegate(self.input_.onChange, handler(self, self.onChange))
	self.eventProxy_:addEventListener(xyd.event.SDK_KEYBOARD_EVENT, handler(self, self.onKeyBoardEvent))
end

function InputWindow:onChange()
	local length = xyd.getStrLength(self.input_.value)
	local default_length_max = 99999999
	local default_tips_max = __("TALK_TEXT_LINE_LIMIT_TIPS")

	if self.max_length then
		default_length_max = self.max_length
	end

	if self.max_tips then
		default_tips_max = self.max_tips
	end

	if default_length_max < length then
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

	if self.data_.onChangeCallBack then
		self.data_.onChangeCallBack(self.input_.value)
	end
end

function InputWindow:onSureTouch(gameObject, isPressed)
	self:onSubmit()
end

function InputWindow:onPasteTouch()
	dump("======================" .. NGUITools.clipboard)

	local text = NGUITools.clipboard or ""
	local val = xyd.insertStringInUIInput(self.input_, text)

	dump(val)

	self.input_.value = val
end

function InputWindow:onCancelTouch(gameObject, isPressed)
	if self.isCanClose == false then
		return
	end

	self.cancelTouch_ = true

	self:onSubmit()
end

function InputWindow:onSubmit()
	if self.isCanClose == false then
		return
	end

	if self.input_ then
		self.inputModel_:onSubmit(self.input_.value, self.cancelTouch_)
		self.input_:Deselect()

		self.hasDeselect = true

		xyd.closeWindow(self.name_)
	end
end

function InputWindow:onTouchBg()
	self:onSubmit()
end

function InputWindow:setFocus()
	self.input_.isSelected = true
end

function InputWindow:onKeyBoardEvent()
	self:changePos()
end

function InputWindow:getGoHeight()
	return 73
end

function InputWindow:willClose()
	InputWindow.super.willClose(self)

	if not self.hasDeselect and self.input_ then
		self.input_:Deselect()

		self.hasDeselect = true
	end
end

function InputWindow:changePos()
	local isShow_ = self.inputModel_:isShow()

	print("inputWindow go in :", isShow_)

	if isShow_ then
		local posY = self.inputModel_:getKeyBoardHeight() + self:getGoHeight() / 2

		dump(posY)
		self.go_:Y(posY)
		self.groupPaste:Y(posY + 62)
		self:setNotCloseState()
	else
		self:onTouchBg()
	end
end

function InputWindow:setNotCloseState()
	if self.closeKey then
		XYDCo.StopWait(self.closeKey)
	end

	self.isCanClose = false
	self.closeKey = self:waitForTime(0.5, function ()
		self.isCanClose = true
	end)
end

function InputWindow:getPositionY()
	return self.go_.transform.localPosition.y
end

return InputWindow
