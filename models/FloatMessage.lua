local Chat = xyd.models.chat
local FloatMessage = class("FloatMessage", import("app.models.BaseModel"))

function FloatMessage:ctor()
	FloatMessage.super.ctor(self)

	self.msgWnd = nil
end

function FloatMessage:createEffect(callback)
	local win = xyd.WindowManager.get():getWindow("float_message_window")

	if not win then
		xyd.WindowManager.get():openWindow("float_message_window", {}, callback)
	end
end

function FloatMessage:adjustDepth()
end

function FloatMessage:setNotice(flag)
	self.showNotice = flag
end

function FloatMessage:getNotice()
	return self.showNotice
end

function FloatMessage:showMessage()
	local isLogin = xyd.WindowManager.get():getWindow("login_window")

	if isLogin or self.showNotice then
		return
	end

	local function callback(window)
		window = window or self.msgWnd
		local popText = Chat:popNotice()

		if not popText then
			window:playExitAnimation()

			return
		end

		self.showNotice = true

		window:setText(popText)
		window:playEnterAnimation()

		self.msgWnd = window
	end

	local win = xyd.WindowManager.get():getWindow("float_message_window")

	if not win then
		self:createEffect(callback)
	else
		callback(win)
	end
end

function FloatMessage:disposeAll()
	FloatMessage.super.disposeAll(self)

	local win = xyd.WindowManager.get():getWindow("float_message_window")

	if win then
		xyd.closeWindow("float_message_window")
	end
end

return FloatMessage
