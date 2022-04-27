local ChatWindow = import(".ChatWindow")
local FriendTeamBossMsgWindow = class("FriendTeamBossMsgWindow", ChatWindow)
local ChatPage = import("app.components.ChatPage")

function FriendTeamBossMsgWindow:ctor(name, params)
	ChatWindow.ctor(self, name, params)

	self.curSelect_ = xyd.MsgType.FRIEND_TEAM_BOSS_CHAT
end

function FriendTeamBossMsgWindow:initWindow()
	FriendTeamBossMsgWindow.super.initWindow(self)
	self:onRemindMessage()
end

function FriendTeamBossMsgWindow:getUIComponent()
	ChatWindow.getUIComponent(self)
	self.groupTop:SetActive(false)

	self.imgListBg.height = 764

	self.imgListBg:SetLocalPosition(0, 10, 0)
	self.btnRecord:Y(332)
end

function FriendTeamBossMsgWindow:onSend()
	local type = self:getMsgTypeBySelect(self.curSelect_)

	if not self:checkValid(type) then
		return
	end

	self.chat_:sendFriendTeamBossMsg(self.textEdit_.text, self.curSelect_)

	self.textEdit_.text = ""
	self.oldText_ = ""
end

function FriendTeamBossMsgWindow:setSelect()
	self.curSelect_ = xyd.MsgType.FRIEND_TEAM_BOSS_CHAT

	self.chat_:setRedMark(self:getMsgTypeBySelect(self.curSelect_), false)
end

function FriendTeamBossMsgWindow:onRemindMessage()
	local msgs = xyd.models.friendTeamBoss:getRemindMsg()

	if not msgs then
		return
	end

	for i = 1, #msgs do
		local msg = msgs[i]
		local params = {
			content = __("FRIEND_TEAM_MSG_TEXT0" .. msg.state, msg.playerName),
			time = xyd.getServerTime(),
			type = xyd.MsgType.FRIEND_TEAM_BOSS_REMIND
		}

		self:waitForFrame(1, function ()
			self.chat_:sendFriendTeamBossRemindMsg(params)
			self.chatPage_:addNewMsg(params)
		end)
	end

	self:updateRedMark()
end

function FriendTeamBossMsgWindow:updateRedMark()
	xyd.db.misc:setValue({
		key = "friend_team_boss_remind_state",
		value = xyd.models.friendTeamBoss:getTeamInfo().team_status
	})
	xyd.db.misc:setValue({
		key = "friend_team_boss_remind_time",
		value = xyd.getServerTime()
	})
	xyd.models.redMark:setMark(xyd.RedMarkType.FRIEND_TEAM_BOSS_MSG2, false)

	local win = xyd.WindowManager.get():getWindow("friend_team_boss_window")

	if win then
		win:updateRedMark()
	end
end

function FriendTeamBossMsgWindow:willClose()
	FriendTeamBossMsgWindow.super.willClose(self)

	local msgs = self.chat_:getMsgsByType(self.curSelect_)
	local i = 1
	local length = #msgs

	while i <= length do
		local msg = msgs[i]

		if msg and msg.type == xyd.MsgType.FRIEND_TEAM_BOSS_REMIND then
			table.remove(msgs, i)

			length = length - 1
		else
			i = i + 1
		end
	end
end

return FriendTeamBossMsgWindow
