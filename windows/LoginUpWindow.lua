local LoginUpWindow = class("LoginUpWindow", import(".BaseWindow"))
local json = require("cjson")

function LoginUpWindow:ctor(name, params)
	LoginUpWindow.super.ctor(self, name, params)

	self.password_ = ""
	self.inputTouchCount_ = 0
	self.curType_ = params.winType or xyd.LoginUpWindowType.LOGIN
	self.password_ = ""
	self.choiceItemArr = {}
	self.localAccoutArr = {}
	local loactString = UnityEngine.PlayerPrefs.GetString("local_accout_name_arr", "-1")

	if loactString and loactString ~= "-1" then
		self.localAccoutArr = json.decode(loactString)
	end
end

function LoginUpWindow:initWindow()
	LoginUpWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function LoginUpWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupMain_ = winTrans:NodeByName("groupMain_").gameObject
	self.closeBtn = self.groupMain_:NodeByName("closeBtn").gameObject
	self.btnLeft_ = self.groupMain_:NodeByName("btnLeft_").gameObject
	self.btnRight_ = self.groupMain_:NodeByName("btnRight_").gameObject
	self.btnRight_BoxCollider = self.groupMain_:ComponentByName("btnRight_", typeof(UnityEngine.BoxCollider))
	self.labelTitle_ = self.groupMain_:ComponentByName("labelTitle_", typeof(UILabel))
	self.labelAccount_ = self.groupMain_:ComponentByName("labelAccount_", typeof(UILabel))
	self.labelPassword_ = self.groupMain_:ComponentByName("labelPassword_", typeof(UILabel))
	self.labelTitle_ = self.groupMain_:ComponentByName("labelTitle_", typeof(UILabel))
	self.labelTitle_ = self.groupMain_:ComponentByName("labelTitle_", typeof(UILabel))
	self.inputAccount_ = self.groupMain_:ComponentByName("inputAccount_", typeof(UILabel))
	self.inputPassword_ = self.groupMain_:ComponentByName("inputPassword_", typeof(UILabel))
	self.choiceCon = self.groupMain_:NodeByName("choiceCon").gameObject

	xyd.addTextInput(self.inputAccount_, {
		is_no_check_illegal = true,
		limit = 50,
		type = xyd.TextInputArea.InputSingleLine,
		clickCallBack = handler(self, function ()
			if self.inputAccount_.text ~= "" then
				return
			end

			if self.choiceMenu then
				self.choiceCon:SetActive(true)
				self:setMenuPosition()
			elseif #self.localAccoutArr > 0 then
				self.choiceCon:SetActive(true)
				self:setMenuPosition()

				self.choiceMenu = import("app.components.ChoiceMenu").new(self.choiceCon)
				local list = {}

				for i, value in pairs(self.localAccoutArr) do
					local params = {
						choiceImg = "partner_sort_bg_chosen_03",
						img = "partner_sort_bg_unchosen_03",
						value = value,
						clickCallBack = function (data, index)
							self.choiceCon:SetActive(false)

							local input_window = xyd.WindowManager.get():getWindow(xyd.getInputWindowName())

							if input_window then
								xyd.WindowManager.get():closeWindow(xyd.getInputWindowName())
							end

							self.inputAccount_.text = data.value

							self.groupMain_:Y(0)
						end
					}

					table.insert(list, params)
				end

				self.choiceMenu:update(list)
			end
		end),
		openCallBack = function ()
			local input_window = xyd.WindowManager.get():getWindow(xyd.getInputWindowName())

			if input_window then
				local depth = input_window:getWindowTrans().gameObject:GetComponent(typeof(UIPanel)).depth
				self.choiceCon:GetComponent(typeof(UIPanel)).depth = depth + 2
			end

			self:setMenuPosition()
		end,
		onChangeCallBack = function (text)
			if text == "" then
				self.choiceCon:SetActive(true)
				self:setMenuPosition()
			else
				self.choiceCon:SetActive(false)
				self.groupMain_:Y(0)
			end
		end,
		callback = function ()
			self.groupMain_:Y(0)
			self.choiceCon:SetActive(false)
		end
	})
	xyd.addTextInput(self.inputPassword_, {
		is_no_check_illegal = true,
		limit = 16,
		type = xyd.TextInputArea.InputSingleLine,
		inputType = UIInput.InputType.Password,
		callback = handler(self, self.onPswChange),
		getText = function ()
			return self.password_
		end
	})
end

function LoginUpWindow:setMenuPosition()
	if #self.localAccoutArr > 0 and self.choiceCon.activeSelf then
		local input_window = xyd.WindowManager.get():getWindow(xyd.getInputWindowName())

		if input_window then
			local toY = input_window:getPositionY() + 15 + #self.localAccoutArr * 50

			if self.groupMain_.transform.localPosition.y < toY then
				self.groupMain_:Y(toY)
			end
		end
	end
end

function LoginUpWindow:layout()
	self.labelAccount_.text = __("SETTING_UP_USER_NAME")
	self.labelPassword_.text = __("SETTING_UP_PASSWORD")
	self.btnRight_:ComponentByName("button_label", typeof(UILabel)).text = __("LOGIN_UP")

	if self.curType_ == xyd.LoginUpWindowType.LOGIN then
		self:initLogin()
	else
		self:initSwitchAccount()
	end
end

function LoginUpWindow:initLogin()
	self.labelTitle_.text = __("LOGIN_UP")
	self.btnLeft_:ComponentByName("button_label", typeof(UILabel)).text = __("FORGET_PASSWORD")
end

function LoginUpWindow:initSwitchAccount()
	self.labelTitle_.text = __("CHANGE_ACCOUNT")
	self.btnLeft_:ComponentByName("button_label", typeof(UILabel)).text = __("CANCEL")
end

function LoginUpWindow:registerEvent()
	self:register()

	UIEventListener.Get(self.btnLeft_).onClick = handler(self, self.onLeftTouch)
	UIEventListener.Get(self.btnRight_).onClick = handler(self, self.onRightTouch)
end

function LoginUpWindow:onLeftTouch()
	if self.curType_ == xyd.LoginUpWindowType.LOGIN then
		local params = {
			key = "FIND_PASS_WORD_HELP",
			title = __("FIND_PASS_WORD_TITLE")
		}

		xyd.WindowManager.get():openWindow("help_window", params)
	else
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function LoginUpWindow:onRightTouch()
	local szReg = "^[A-Za-z0-9]+[a-zA-Z0-9-._@]*[A-Za-z0-9]+$"
	local account = self.inputAccount_.text
	local result = string.match(account, szReg)

	if account == "login_master" or result then
		if self.password_ and #self.password_ > 0 then
			local isFind = false
			local findIndex = -1

			for i in pairs(self.localAccoutArr) do
				if self.localAccoutArr[i] == account then
					isFind = true
					findIndex = i

					break
				end
			end

			if isFind and findIndex ~= -1 and findIndex ~= 1 then
				for i = findIndex, 2, -1 do
					self.localAccoutArr[i] = self.localAccoutArr[i - 1]
				end

				self.localAccoutArr[1] = account
			end

			if isFind == false then
				if #self.localAccoutArr >= 5 then
					for i = #self.localAccoutArr, 2, -1 do
						self.localAccoutArr[i] = self.localAccoutArr[i - 1]
					end

					self.localAccoutArr[1] = account
				else
					table.insert(self.localAccoutArr, account)

					for i = #self.localAccoutArr, 2, -1 do
						self.localAccoutArr[i] = self.localAccoutArr[i - 1]
					end

					self.localAccoutArr[1] = account
				end
			end

			UnityEngine.PlayerPrefs.SetString("local_accout_name_arr", json.encode(self.localAccoutArr))
			xyd.SdkManager.get():accountLogin(account, self.password_)

			self.btnRight_BoxCollider.enabled = false

			self:waitForTime(1.5, function ()
				self.btnRight_BoxCollider.enabled = true
			end)
		else
			xyd.alert(xyd.AlertType.TIPS, __("PASSWORD_INVALID"))
		end
	else
		xyd.alert(xyd.AlertType.TIPS, __("ACCOUNT_INVALID"))
	end
end

function LoginUpWindow:onPswChange(isCancel)
	if isCancel then
		return
	end

	local newStr = self.inputPassword_.text
	self.password_ = newStr
	local str = ""

	for i = 1, #newStr do
		str = str .. "●"
	end

	self.inputPassword_.text = str
end

return LoginUpWindow
