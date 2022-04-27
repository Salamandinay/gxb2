local ChatWindow = import(".ChatWindow")
local GuildRecruitWindow = class("GuildRecruitWindow", ChatWindow)

function GuildRecruitWindow:ctor(name, params)
	GuildRecruitWindow.super.ctor(self, name, params)

	self.text = ""
	self.MAX_LEN = 200
	self.curSelect_ = xyd.MsgType.RECRUIT
	self.oldRecords[xyd.MsgType.RECRUIT] = xyd.models.chat:getRecord(xyd.MsgType.RECRUIT)
end

function GuildRecruitWindow:initWindow()
	local groupTop = self.window_:NodeByName("groupAction/groupTop")
	local listBg = self.window_:ComponentByName("groupAction/imgListBg", typeof(UISprite))
	groupTop.localScale = Vector3(1, 0, 1)
	listBg.height = 760
	listBg.gameObject.transform.localPosition = Vector3(0, 15, 0)

	GuildRecruitWindow.super.initWindow(self)

	local imgTextBg = self.groupBottom:ComponentByName("e:Group/e:Image", typeof(UIWidget))
	imgTextBg.width = 405

	xyd.addTextInput(self.textEdit_, {
		type = xyd.TextInputArea.InputSingleLine,
		textBackLabel = self.textBack_,
		textBack = __("GUILD_TEXT42")
	})

	self.textBack_.text = __("GUILD_TEXT42")

	self:setLayout()
	self.btnSendImg:SetActive(false)
	self.btnEmo_:SetActive(false)
	self.btnRecord.transform:Y(332)
end

function GuildRecruitWindow:setSelect()
	self.curSelect_ = xyd.MsgType.RECRUIT
end

function GuildRecruitWindow:registerEvent()
	UIEventListener.Get(self.btnConfig_).onClick = handler(self, self.onShowConfig)
	UIEventListener.Get(self.btnSend_).onClick = handler(self, self.onSend)
	UIEventListener.Get(self.btnDown_).onClick = handler(self, self.onDownTouch)
	UIEventListener.Get(self.btnRecord).onClick = handler(self, self.onRecordTouch)

	self.eventProxy_:addEventListener(xyd.event.CHAT_MESSAGE, handler(self, self.onMessage))

	UIEventListener.Get(self.imgConfigMask_).onClick = handler(self, self.onHideConfig)
	UIEventListener.Get(self.imgConfigMask_1).onClick = handler(self, self.onHideEmotion)

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function GuildRecruitWindow:setLayout()
	self:setText()
end

function GuildRecruitWindow.updateTap()
end

function GuildRecruitWindow:layout()
end

function GuildRecruitWindow:setText()
	self.btnSend_:ComponentByName("button_label", typeof(UILabel)).text = __("SEND")
end

function GuildRecruitWindow:onSend()
	if xyd.models.guild.guildJob == xyd.GUILD_JOB.NORMAL then
		xyd.showToast(__("GUILD_TEXT65"))

		return
	end

	local cd = xyd.tables.miscTable:getNumber("guild_recruit", "value")
	local time = xyd.getServerTime() - xyd.models.guild:getRecruitTime()

	if cd > time then
		xyd.showToast(__("GUILD_TEXT43", xyd.getRoughDisplayTime(cd - time)))

		return
	end

	if xyd.tables.filterWordTable:isInWords(self.textEdit_.text) then
		xyd.showToast(__("INVALID_CHARACTER"))

		return
	end

	local text = "[ " .. tostring(xyd.models.guild:getBaseInfo().name) .. " ] " .. tostring(self.textEdit_.text)
	local data = {
		text = text,
		guild_id = xyd.models.guild.guildID
	}
	data = require("cjson").encode(data)

	xyd.models.chat:sendRecruitdMsg(data, xyd.MsgType.RECRUIT)

	self.textEdit_.text = ""

	xyd.showToast(__("GUILD_TEXT44"))
end

function GuildRecruitWindow:judgeReachLimitLen(str)
	return self.MAX_LEN < xyd.getStrLength(str)
end

function GuildRecruitWindow:getMsgTypeBySelect(select_)
	return select_
end

return GuildRecruitWindow
