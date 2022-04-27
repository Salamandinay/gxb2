local BaseWindow = import(".BaseWindow")
local MailSendWindow = class("MailSendWindow", BaseWindow)
local Type = {
	Guild = 1,
	Multiplayer = 3,
	Player = 2
}

function MailSendWindow:ctor(name, params)
	MailSendWindow.super.ctor(self, name, params)

	self.type_ = params.type

	if self.type_ == Type.Player then
		self.oldContent_ = params.oldContent
		self.player_id_ = params.player_id
		self.player_name_ = params.player_name
		self.receiver_ = tostring(self.player_name_) .. "(id " .. tostring(self.player_id_) .. ")"
	elseif self.type_ == Type.Multiplayer then
		self.receiver_ = __("GUILD_BOSS_MAIL_TITLE")
		self.player_id_ = params.playerIDs
	else
		self.receiver_ = __("GUILD_MAIL_TITLE")
	end
end

function MailSendWindow:initWindow()
	MailSendWindow.super.initWindow(self)

	self.contentBg_ = self.window_:ComponentByName("content", typeof(UISprite))
	local contentTrans = self.contentBg_.transform
	self.closeBtn = contentTrans:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	self.scrollView_ = contentTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.btnSend_ = contentTrans:ComponentByName("btnSend", typeof(UISprite))
	self.btnSendLabel_ = contentTrans:ComponentByName("btnSend/label", typeof(UILabel))
	self.mailTitle01_ = contentTrans:ComponentByName("mailTextBg/mailTitle01", typeof(UILabel))
	self.mailTitle02_ = contentTrans:ComponentByName("mailText02", typeof(UILabel))
	self.mailTitle03_ = contentTrans:ComponentByName("mailText03", typeof(UILabel))
	self.textInput_ = contentTrans:ComponentByName("scrollView/textEdit_", typeof(UIInput))
	self.scrollViewBar_ = contentTrans:NodeByName("scrollView/scrollViewBar").gameObject

	self:setLayout()
	self:registerEvent()
end

function MailSendWindow:setLayout()
	self.mailTitle01_.text = self.receiver_
	self.mailTitle02_.text = __("MAIL_RECEIVER")
	self.mailTitle03_.text = __("MAIL_CONTENT")

	if xyd.Global.lang == "en_en" then
		self.textInput_.characterLimit = 500
	else
		self.textInput_.characterLimit = 350
	end

	self.btnSendLabel_.text = __("SEND")
end

function MailSendWindow:registerEvent()
	UIEventListener.Get(self.btnSend_.gameObject).onClick = handler(self, self.checkAndSend)
	UIEventListener.Get(self.closeBtn).onClick = handler(self, self.checkAndClose)
	UIEventListener.Get(self.contentBg_.gameObject).onClick = handler(self, self.onclickBg)
	UIEventListener.Get(self.textInput_.gameObject).onClick = handler(self, self.onclickInput)
end

function MailSendWindow:onclickInput()
	if not self.inputTouch_ then
		self.inputTouch_ = true
	end

	self:updateScroll()
end

function MailSendWindow:onclickBg()
	if self.inputTouch_ then
		self.inputTouch_ = false
	end

	self:updateScroll()
end

function MailSendWindow:checkAndSend()
	local text = self.textInput_.value
	local tips = ""

	if #text <= 0 then
		xyd.alertTips(__("MAIL_NULL"))
	elseif self:timeJudge() > 0 then
		local timeRemain = self:timeJudge()

		xyd.alertTips(__("MAIL_TOO_SOON", timeRemain))
	else
		text = xyd.tables.filterWordTable:illegalReplace(text)

		if self.type_ == Type.Player then
			xyd.models.mail:friendSendMail({
				title = self.receiver_,
				content = text,
				old_content = self.oldContent_,
				to_player_ids = {
					self.player_id_
				}
			})
		elseif self.type_ == Type.Multiplayer then
			for i = 1, #self.player_id_ do
				xyd.models.mail:friendSendMail({
					title = self.receiver_,
					content = text,
					to_player_ids = {
						self.player_id_[i]
					}
				})
			end
		else
			xyd.models.mail:guildSendMail(__("GUILD_TEXT56"), text)
		end

		xyd.alertTips(__("MAIL_SEND_SUCCESS"))
		xyd.WindowManager.get():closeWindow("mail_send_window")
	end
end

function MailSendWindow:illegal(text)
	return xyd.tables.filterWordTable:isInWords(text)
end

function MailSendWindow:timeJudge()
	return xyd.models.mail:timeRemain()
end

function MailSendWindow:updateScroll()
	self.scrollViewBar_:SetActive(self.inputTouch_)
end

function MailSendWindow:checkAndClose()
	local text = self.textInput_.value

	if #text <= 0 then
		xyd.WindowManager:get():closeWindow("mail_send_window")
	else
		xyd.alertYesNo(__("MAIL_IF_QUIT"), function (yes_no)
			if yes_no then
				xyd.WindowManager:get():closeWindow("mail_send_window")
			end
		end)
	end
end

return MailSendWindow
