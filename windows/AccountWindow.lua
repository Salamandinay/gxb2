local AccountWindow = class("AccountWindow", import(".BaseWindow"))
local PlayerIcon = import("app.components.PlayerIcon")

function AccountWindow:ctor(name, params)
	AccountWindow.super.ctor(self, name, params)

	self.windowType = ""

	if params then
		self.windowType = params.type
	end

	self.selfPlayer = xyd.models.selfPlayer
end

function AccountWindow:initWindow()
	AccountWindow.super.initWindow(self)
	self:getUIComponent()
	AccountWindow.super.register(self)
	self:initUIComponent()
	self:registerEvent()
end

function AccountWindow:registerEvent()
	UIEventListener.Get(self.btnRegister_).onClick = handler(self, self.onRegisterTouch)
	UIEventListener.Get(self.btnChangeAccount_).onClick = handler(self, self.onChangeAccountTouch)
	UIEventListener.Get(self.helpBtn).onClick = handler(self, self.onHelpTouch)
end

function AccountWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction_ = winTrans:NodeByName("groupAction")
	self.labelTitle_ = winTrans:ComponentByName("groupAction/labelTitle", typeof(UILabel))
	self.btnRegister_ = winTrans:NodeByName("groupAction/btnRegister").gameObject
	self.btnChangeAccount_ = winTrans:NodeByName("groupAction/btnChangeAccount").gameObject
	self.labelChangeAccount_ = winTrans:ComponentByName("groupAction/btnChangeAccount/button_label", typeof(UILabel))
	self.labelRegister_ = winTrans:ComponentByName("groupAction/btnRegister/button_label", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("groupAction/closeBtn").gameObject
	self.helpBtn = winTrans:NodeByName("groupAction/helpBtn").gameObject
	self.labelPlayerAccount_ = winTrans:ComponentByName("groupAction/labelPlayerAccount", typeof(UILabel))
	self.labelPlayerName_ = winTrans:ComponentByName("groupAction/labelPlayerName", typeof(UILabel))
	local playIcon_ = winTrans:NodeByName("groupAction/player_icon").gameObject
	self.playerIcon_ = PlayerIcon.new(playIcon_)
end

function AccountWindow:initUIComponent()
	self.labelTitle_.text = __("PERSON_BTN_1")
	self.labelRegister_.text = __("REGISTER_WINDOW_LABEL_1")
	self.labelChangeAccount_.text = __("CHANGE_ACCOUNT")
	self.labelRegister_.fontSize = 25

	if self.windowType == "register" then
		self:updateLayout()
	else
		self:updatePlayerInfo()
	end
end

function AccountWindow:updatePlayerInfo()
	if xyd.Global.isAnonymous_ == 1 then
		self.btnRegister_:SetActive(true)

		self.labelRegister_.text = __("REGISTER_WINDOW_LABEL_1")

		self.labelPlayerAccount_:SetActive(false)

		self.labelPlayerName_.text = __("ANONY_GUEST")

		self.btnRegister_:X(-125)
		self.btnChangeAccount_:SetActive(true)
		self.btnChangeAccount_:X(125)
	else
		local account = self.selfPlayer:getAccount()

		if account and account ~= "" then
			local accountDivide = xyd.split(account, "@")
			local tmpStr = accountDivide[1]

			if xyd.utf8len(tmpStr) > 12 then
				tmpStr = xyd.subUft8Len(tmpStr, 12) .. "..."
			end

			if accountDivide[2] then
				account = tmpStr .. "@" .. accountDivide[2]
			end
		end

		self.btnRegister_:SetActive(false)

		self.labelPlayerName_.text = self.selfPlayer:getPlayerName()
		self.labelPlayerAccount_.text = account

		self.labelPlayerAccount_:SetActive(true)
		self.btnChangeAccount_:X(0)
	end

	self:initIcon()
end

function AccountWindow:updateLayout()
	self.btnRegister_:SetActive(true)

	self.labelRegister_.text = __("REGISTER_WINDOW_LABEL_1")

	self.labelPlayerAccount_:SetActive(false)

	self.labelPlayerName_.text = __("ANONY_GUEST")

	self.btnRegister_:X(-125)
	self.btnChangeAccount_:SetActive(true)
	self.btnChangeAccount_:X(125)
	self:initIcon()
end

function AccountWindow:initIcon()
	local params = {
		noClick = true,
		avatarID = self.selfPlayer:getAvatarID(),
		lev = xyd.models.backpack:getLev(),
		avatar_frame_id = self.selfPlayer:getAvatarFrameID()
	}

	self.playerIcon_:setInfo(params)
end

function AccountWindow:onRegisterTouch()
	if xyd.Global.isAnonymous_ == 1 or self.windowType == "register" then
		xyd.WindowManager.get():openWindow("modify_account_window", {
			winType = xyd.ModifyAccountWindowType.REGISTER
		})
	else
		xyd.WindowManager.get():openWindow("modify_password_window")
	end
end

function AccountWindow:onChangeAccountTouch()
	if xyd.Global.isAnonymous_ == 1 then
		local function callback(yes)
			if not yes then
				return
			end

			xyd.WindowManager.get():openWindow("modify_account_window", {
				winType = xyd.ModifyAccountWindowType.CHANGE_ACCOUNT
			})
		end

		xyd.alert(xyd.AlertType.YES_NO, __("ANONYMOUS_MODIFY_ACCOUNT_TIPS"), callback)
	else
		xyd.WindowManager.get():openWindow("modify_account_window", {
			winType = xyd.ModifyAccountWindowType.CHANGE_ACCOUNT
		})
	end
end

function AccountWindow:onHelpTouch()
	xyd.WindowManager.get():openWindow("help_window", {
		key = "ACCOUNT_HELP"
	})
end

return AccountWindow
