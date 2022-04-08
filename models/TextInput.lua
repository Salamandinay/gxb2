local TextInput = class("TextInput", import(".BaseModel"))

function TextInput:ctor()
	TextInput.super.ctor(self)

	self.curLabels_ = {}
	self.isKeyboardShown_ = false
	self.curCallback = nil
end

function TextInput:onRegister()
	TextInput.super.onRegister(self)
	self:registerEvent(xyd.event.SDK_KEYBOARD_EVENT, handler(self, self.onKeyBoardEvent))
end

function TextInput:onKeyBoardEvent(event)
	dump(event.params)

	local params = event.params

	if params.isKeyboardShown then
		local ScreenHeight = UnityEngine.Screen.height

		dump(ScreenHeight)

		self.keyBoardHeight_ = (ScreenHeight / 2 - params.height) / ScreenHeight * xyd.Global.getRealHeight()
	else
		self.keyBoardHeight_ = 0
	end

	self.isKeyboardShown_ = params.isKeyboardShown
end

function TextInput:isShow()
	return self.isKeyboardShown_
end

function TextInput:getKeyBoardHeight()
	return self.keyBoardHeight_
end

function TextInput:addInputEvent(label, params)
	if not label:GetComponent(typeof(UnityEngine.BoxCollider)) then
		local boxCollider = label:AddComponent(typeof(UnityEngine.BoxCollider))
		local widget = label:GetComponent(typeof(UIWidget))
		boxCollider.size = Vector3(widget.width, widget.height, 0)
	end

	UIEventListener.Get(label.gameObject).onClick = function ()
		self:showInput(label, params)

		if params.clickCallBack then
			params.clickCallBack()
		end
	end
end

function TextInput:showInput(label, params)
	self.curLabel_ = label
	self.curCallback = params.callback
	params.text = label.text

	if params.getText then
		params.text = params.getText()
	end

	self.textBackLabel_ = params.textBackLabel
	self.textBack_ = params.textBack

	if params.openCallBack then
		xyd.openWindow(xyd.getInputWindowName(), params, params.openCallBack)
	else
		xyd.openWindow(xyd.getInputWindowName(), params)
	end
end

function TextInput:onSubmit(value, isCancel)
	if self.curLabel_ and not isCancel then
		self.curLabel_.text = value

		if self.textBackLabel_ and value ~= "" then
			self.textBackLabel_.text = ""
		elseif self.textBackLabel_ then
			self.textBackLabel_.text = self.textBack_
		end
	end

	if self.curCallback then
		self.curCallback(isCancel)
	end
end

return TextInput
