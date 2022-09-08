local BaseModel = import(".BaseModel")
local ErrorModel = class("ErrorModel", BaseModel)

function ErrorModel:ctor()
	ErrorModel.super.ctor(self)

	self.items_ = {}
end

function ErrorModel:onRegister()
	BaseModel:onRegister()
	self:registerEvent(xyd.event.ERROR_MESSAGE, handler(self, self.onError))
end

function ErrorModel:onError(event)
	local errorCode = event.data.error_code
	local errorMid = event.data.error_mid

	if errorCode == xyd.ErrorCode.SERVER_ERROR then
		xyd.alert(xyd.AlertType.CONFIRM, __("SERVER_ERROR"), function (yes)
			if yes then
				xyd.db.misc:setValue({
					value = "",
					key = "cdkey"
				})
				xyd.MainController.get():restartGame()
			end
		end, nil, true)

		return
	end

	if not xyd.Global.isLoadingFinish then
		return
	end

	if tonumber(errorCode) == 6021 then
		xyd.models.chat:showFakeMsg()

		return
	end

	if tonumber(errorCode) == xyd.ErrorCode.UNENABLED_LOGIN_SERVER then
		local loginWd = xyd.WindowManager.get():getWindow("login_window")
		xyd.Global.isHasBeenBanServer = true

		if loginWd then
			loginWd:update({})
		else
			xyd.WindowManager.get():openWindow("login_window", {})
		end
	end

	if tonumber(errorCode) == xyd.ErrorCode.FRIEND_NOT_SERVER then
		local arenaFormationWindow = xyd.WindowManager.get():getWindow("arena_formation_window")

		if arenaFormationWindow then
			xyd.WindowManager.get():closeWindow("arena_formation_window")
		end
	end

	local text = xyd.tables.errorInfoTextTable:getText(errorCode)

	if text and text ~= "" then
		xyd.showToast(text)
	end
end

return ErrorModel
