local Chat = class("Chat", import("app.models.BaseModel"))
local cjson = require("cjson")
local FilterWordSuperTable = xyd.tables.filterWordSuperTable
local PlayerLanguageTable = xyd.tables.playerLanguageTable
local MiscTable = xyd.tables.miscTable
local DEFAULT_HEIGHT = 135

function Chat:ctor()
	Chat.super.ctor(self)

	self.noticeList = {}
	self.isDisplayNotice = false
	self.msgs_ = {}
	self.config_ = {}
	self.talkTime_ = {}
	self.isLoadGm_ = false
	self.lastWord_ = ""
	self.records_ = {}
	self.blackList_ = {}
	self.blackNum = 0
	self.privateList = {}
	self.privateNum = 0
	self.privateMsgs = {}
	self.lastSelect = xyd.MsgType.NORMAL
	self.firstGetBlackList = true
	self.firstGetPlayerList = true
	self.translateContent_ = {}
	self.inTranslate_ = {}
	self.translaID2Content_ = {}
	self.gmMsgType = 0
	self.firstShowTips = false
	self.gmTipsHasShows = {}
	self.newQuest = true
	self.DailyUpdateHour = (24 + xyd.getTimeZone()) % 24
	self.curMsgID_ = 0
	self.totalHeight_ = {}
	self.heightCache_ = {}
	self.lastUsedTimes_ = 0
	self.filterMsgs_ = {}
end

function Chat:onRegister()
	Chat.super.onRegister(self)
	self:registerEvent(xyd.event.CHAT_MESSAGE, handler(self, self.onMessage))
	self:registerEvent(xyd.event.GET_MESSAGE_INFOS, handler(self, self.onGetMessageInfos))
	self:registerEvent(xyd.event.FRIEND_TEAM_BOSS_GET_MSG, handler(self, self.onFriendTamBossMessages))
	self:registerEvent(xyd.event.GET_TALK_LIST, handler(self, self.onGetTalkList))
	self:registerEvent(xyd.event.TALK_WITH_GM, handler(self, self.onTalkWithGm))
	self:registerEvent(xyd.event.GM_REPLY, handler(self, self.onGmReply))
	self:registerEvent(xyd.event.GET_BLACK_LIST, handler(self, self.onBlackList))
	self:registerEvent(xyd.event.GET_PLAYER_LIST, handler(self, self.onPlayerList))
	self:registerEvent(xyd.event.CHAT_WITH_PLAYER, handler(self, self.onChatWithPlayer))
	self:registerEvent(xyd.event.PRIVATE_MESSAGE, handler(self, self.onPrivateMessage))
	self:registerEvent(xyd.event.GUILD_GET_INFO, handler(self, self.onRecruitRedPoint))
	self:registerEvent(xyd.event.SEND_CROSS_MESSAGE, handler(self, self.onSendCrossMessages))
	self:registerEvent(xyd.event.SEND_LANGUAGE, handler(self, self.onSendLocalMessages))
	self:registerEvent(xyd.event.GM_REPLY_OVER, handler(self, self.onGmReplyOver))
	self:registerEvent(xyd.event.REMOVE_CHAT_PLAYER, handler(self, self.deletePrivateMessage))
	self:registerEvent(xyd.event.ARCTIC_EXPEDITION_CHAT_MSG, handler(self, self.onGetArcticMessageInfos))
	self:registerEvent(xyd.event.EXPEDITION_CHAT_BACK, handler(self, self.onGetArcticMessageBack))
	self:getConfig()
end

function Chat:onSendCrossMessages(event)
end

function Chat:onSendLocalMessages(event)
end

function Chat:onRecruitRedPoint(event)
	if event.data.self_info.guild_id then
		self:setRedMark(xyd.MsgType.RECRUIT, false)
	end
end

function Chat:onPrivateMessage(event)
	self:setRedMark(xyd.MsgType.PRIVATE, true)

	local flag = false

	for i = 1, #self.privateList do
		if self.privateList[i].player_id == event.data.sender_id then
			self.privateList[i].chat_msg.content = event.data.content
			self.privateList[i].chat_msg.sender_id = event.data.sender_id
			self.privateList[i].chat_msg.time = event.data.time
			flag = true

			self:updatePlayerList()

			break
		end
	end

	if not flag then
		self:getPlayerList()
	end

	self:setPlayerBlockWarning(2, event.data.sender_id)
end

function Chat:onChatWithPlayer(event)
	self:setRedMark(xyd.MsgType.PRIVATE, false)
	xyd.db.chat:setValue({
		key = "private" .. tostring(event.data.to_player_id),
		value = xyd.getServerTime()
	})

	local flag = false

	for i = 1, #self.privateList do
		if self.privateList[i].player_id == event.data.to_player_id then
			self.privateList[i].chat_msg.content = event.data.content
			self.privateList[i].chat_msg.sender_id = xyd.Global.playerID
			self.privateList[i].chat_msg.time = xyd.getServerTime()
			flag = true

			self:updatePlayerList()

			break
		end
	end

	if not flag then
		self:getPlayerList()
	end

	self:setPlayerBlockWarning(1, event.data.to_player_id)
end

function Chat:onBlackList(event)
	for i = 1, #event.data.list do
		self.blackList_[event.data.list[i].player_id] = event.data.list[i]
	end

	self.blackNum = #event.data.list
	self.firstGetBlackList = false

	xyd.models.friend:getInfo(true)
end

function Chat:onGmReplyOver()
	self.newQuest = true

	self:setGmReplyOver()
end

function Chat:getBlackLength()
	return self.blackNum
end

function Chat:pushBlackList(params)
	self.blackList_[params.player_id] = params
	self.blackNum = self.blackNum + 1
end

function Chat:popBlackList(id)
	self.blackList_[id] = nil
	self.blackNum = self.blackNum - 1
end

function Chat:isInBlackList(id)
	if self.blackList_[id] then
		return true
	end

	return false
end

function Chat:getAllBlack()
	return self.blackList_
end

function Chat:isLoading()
	return false
end

function Chat:onMessage(event)
	if not xyd.Global.isLoadingFinish then
		return
	end

	local data = event.data
	local type = data.type
	local content = data.content

	if type == xyd.MsgType.NOTICE then
		local id = event.data.language

		if PlayerLanguageTable:getTrueCode(id) ~= xyd.Global.lang then
			return
		end

		local times = MiscTable:getNumber("announcement_repeat_times", "value")
		local raw_content = content
		local blank_num = MiscTable:getNumber("announcement_blanking", "value")
		local blank_str = ""

		for i = 1, blank_num do
			blank_str = tostring(blank_str) .. " "
		end

		for i = 1, times do
			content = tostring(content) .. tostring(blank_str) .. tostring(raw_content)
		end

		table.insert(self.noticeList, {
			content = content,
			goto_type = data.goto_type,
			goto_val = data.goto_val
		})
		self:displayNotice()
	elseif (type == xyd.MsgType.NORMAL or type == xyd.MsgType.SHARE_PARTNER or type == xyd.MsgType.HOUSE_SHARE_NORMAL) and self:getConfigByIndex(xyd.ChatConfig.SHOW_WORLD) == 1 then
		if self:isLoading() then
			return
		end

		local flag = self:addMsg(data)
		local isBlack = self:isInBlackList(data.sender_id)

		if flag and not isBlack then
			self:setRedMark(type, true)
		end
	elseif (type == xyd.MsgType.GUILD or type == xyd.MsgType.GUILD_WAR or type == xyd.MsgType.HOUSE_SHARE_GUILD) and self:getConfigByIndex(xyd.ChatConfig.SHOW_GUILD) == 1 then
		if self:isLoading() then
			return
		end

		local flag = self:addMsg(data)
		local isBlack = self:isInBlackList(data.sender_id)

		if flag and not isBlack then
			self:setRedMark(type, true)
		end

		xyd.db.chat:setValue({
			key = "guild_chat",
			value = data.time
		})
	elseif type == xyd.MsgType.FRIEND_TEAM_BOSS_CHAT then
		if self:isLoading() then
			return
		end

		local flag = self:addMsg(data)
		local isBlack = self:isInBlackList(data.sender_id)

		if flag and not xyd.WindowManager:get():isOpen("friend_team_boss_msg_window") and not isBlack then
			self:setRedMark(type, true)
		end

		xyd.db.chat:setValue({
			key = "friend_team_boss_chat",
			value = data.time
		})
	elseif type == xyd.MsgType.RECRUIT and self:getConfigByIndex(xyd.ChatConfig.SHOW_RECRUIT) == 1 then
		if self:isLoading() then
			return
		end

		local flag = self:addMsg(data)
		local isBlack = self:isInBlackList(data.sender_id)

		if flag and not isBlack then
			self:setRedMark(type, true)
		end

		if flag and xyd.models.guild.guildID then
			self:setRedMark(type, false)
		end

		xyd.db.chat:setValue({
			key = "recruit_chat",
			value = data.time
		})
	elseif (type == xyd.MsgType.CROSS_CHAT or type == xyd.MsgType.HOUSE_SHARE_CROSS_CHAT) and self:getConfigByIndex(xyd.ChatConfig.SHOW_CROSS) == 1 then
		if self:isLoading() then
			return
		end

		self:addMsg(data)

		local isBlack = self:isInBlackList(data.sender_id)

		if not isBlack then
			self:setRedMark(type, true)
		end

		xyd.db.chat:setValue({
			key = "cross_chat",
			value = data.time
		})
	elseif (type == xyd.MsgType.LOCAL_CHAT or type == xyd.MsgType.HOUSE_SHARE_LOCAL_CHAT or type == xyd.MsgType.NOTICE_WITH_JUMP) and self:getConfigByIndex(xyd.ChatConfig.SHOW_LOCAL) == 1 then
		if self:isLoading() then
			return
		end

		self:addMsg(data)

		local isBlack = self:isInBlackList(data.sender_id)

		if not isBlack then
			self:setRedMark(type, true)
		end

		xyd.db.chat:setValue({
			key = "local_chat",
			value = data.time
		})
	end
end

function Chat:getServerMsgs()
	xyd.Backend.get():request(xyd.mid.GET_SERVER_MESSAGE, {})
end

function Chat:getTalkList()
	if self.isLoadGm_ then
		return
	end

	self.isLoadGm_ = true
	local msg = messages_pb.get_talk_list_req()

	xyd.Backend.get():request(xyd.mid.GET_TALK_LIST, msg)
end

function Chat:getFriendTeamBossMsg()
	local msg = messages_pb.friend_team_boss_get_msg_req()

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_GET_MSG, msg)
end

function Chat:getBlackList()
	if self.firstGetBlackList then
		local msg = messages_pb.get_black_list_req()

		xyd.Backend.get():request(xyd.mid.GET_BLACK_LIST, msg)
	end
end

function Chat:ifGetBlackList()
	return self.firstGetBlackList
end

function Chat:initTempMsg(str, type, id)
	if not type then
		self.tempFakeMsg_ = {
			content = xyd.escapesLuaString(str),
			to_player_id = id
		}
	else
		self.tempFakeMsg_ = {
			channel = 0,
			player_type = 0,
			type = type,
			content = xyd.escapesLuaString(str),
			time = xyd.getServerTime(),
			sender_id = xyd.Global.playerID,
			sender_name = xyd.Global.playerName,
			sender_level = xyd.models.backpack:getLev(),
			show_vip = self:getShowVip(),
			sender_vip = xyd.models.backpack:getVipLev(),
			avatar_id = xyd.models.selfPlayer:getAvatarID(),
			server_id = xyd.models.selfPlayer:getServerID(),
			avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID()
		}
	end
end

function Chat:showFakeMsg()
	if not self.tempFakeMsg_ or not self.tempFakeMsg_.content then
		return
	end

	if self.tempFakeMsg_.to_player_id then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.CHAT_WITH_PLAYER,
			data = {
				to_player_id = self.tempFakeMsg_.to_player_id,
				content = self.tempFakeMsg_.content
			}
		})
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.CHAT_WITH_PLAYER,
			data = {
				to_player_id = self.tempFakeMsg_.to_player_id,
				content = self.tempFakeMsg_.content
			}
		})
	else
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.CHAT_MESSAGE,
			data = {
				channel = 0,
				player_type = 0,
				type = self.tempFakeMsg_.type,
				content = self.tempFakeMsg_.content,
				time = self.tempFakeMsg_.time,
				sender_id = self.tempFakeMsg_.sender_id,
				sender_name = self.tempFakeMsg_.sender_name,
				sender_level = self.tempFakeMsg_.sender_level,
				show_vip = self.tempFakeMsg_.show_vip,
				avatar_id = self.tempFakeMsg_.avatar_id,
				server_id = self.tempFakeMsg_.server_id,
				sender_vip = self.tempFakeMsg_.sender_vip,
				avatar_frame_id = self.tempFakeMsg_.avatar_frame_id
			}
		})
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.CHAT_MESSAGE,
			data = {
				channel = 0,
				player_type = 0,
				type = self.tempFakeMsg_.type,
				content = self.tempFakeMsg_.content,
				time = self.tempFakeMsg_.time,
				sender_id = self.tempFakeMsg_.sender_id,
				sender_name = self.tempFakeMsg_.sender_name,
				sender_level = self.tempFakeMsg_.sender_level,
				show_vip = self.tempFakeMsg_.show_vip,
				sender_vip = self.tempFakeMsg_.sender_vip,
				avatar_id = self.tempFakeMsg_.avatar_id,
				server_id = self.tempFakeMsg_.server_id,
				avatar_frame_id = self.tempFakeMsg_.avatar_frame_id
			}
		})
	end
end

function Chat:sendServerMsg(str, type, timeType)
	self:initTempMsg(str, type)

	if xyd.models.selfPlayer:checkPlayerBaned() then
		self:showFakeMsg()

		return
	end

	self.talkTime_[timeType or type] = xyd.getServerTime()
	local msg = messages_pb.send_server_msg_req()
	msg.content = xyd.escapesLuaString(str)
	msg.type = type
	msg.show_vip = self:getShowVip()

	self:recordDialog(msg.content)
	xyd.Backend.get():request(xyd.mid.SEND_SERVER_MSG, msg)
	self:setLastWord("")
end

function Chat:recordDialog(msg)
	table.insert(xyd.Global.recordDialog, msg)

	if #xyd.Global.recordDialog > 5 then
		table.remove(xyd.Global.recordDialog, 1)
	end
end

function Chat:sendPrivateMsg(str, id)
	self:initTempMsg(str, nil, id)

	if xyd.models.selfPlayer:checkPlayerBaned() then
		self:showFakeMsg()

		return
	end

	local msg = messages_pb.chat_with_player_req()
	msg.content = xyd.escapesLuaString(str)
	msg.to_player_id = id

	self:recordDialog(msg.content)
	xyd.Backend.get():request(xyd.mid.CHAT_WITH_PLAYER, msg)
	self:setLastWord("")
end

function Chat:sendGuildMsg(str, type, timeType)
	self:initTempMsg(str, type)

	if xyd.models.selfPlayer:checkPlayerBaned() then
		self:showFakeMsg()

		return
	end

	if timeType ~= xyd.MsgType.EMOTION then
		self.talkTime_[timeType or type] = xyd.getServerTime()
	end

	local msg = messages_pb.send_guild_msgs_req()
	msg.content = xyd.escapesLuaString(str)
	msg.type = type
	msg.show_vip = self:getShowVip()

	self:recordDialog(msg.content)
	xyd.Backend.get():request(xyd.mid.SEND_GUILD_MSGS, msg)
	self:setLastWord("")
end

function Chat:sendGuildWarMsg(str, type, timeType)
	self:initTempMsg(str, type)

	if xyd.models.selfPlayer:checkPlayerBaned() then
		self:showFakeMsg()

		return
	end

	self.talkTime_[timeType or type] = xyd.getServerTime()
	local msg = messages_pb.send_guild_msgs_req()
	msg.content = xyd.escapesLuaString(str)
	msg.type = type
	msg.show_vip = self:getShowVip()

	xyd.Backend.get():request(xyd.mid.SEND_GUILD_MSGS, msg)
	self:setLastWord("")
end

function Chat:sendFriendTeamBossMsg(str, type, timeType)
	self.talkTime_[timeType or type] = xyd.getServerTime()
	local msg = messages_pb.friend_team_boss_send_msg_req()
	msg.content = xyd.escapesLuaString(str)
	msg.type = type
	msg.show_vip = self:getShowVip()

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_SEND_MSG, msg)
	self:setLastWord("")
end

function Chat:sendFriendTeamBossRemindMsg(data)
	self:addMsg(data)
end

function Chat:sendRecruitdMsg(str, type, timeType)
	self.talkTime_[timeType or type] = xyd.getServerTime()
	local msg = messages_pb.send_recruit_msgs_req()
	msg.content = xyd.escapesLuaString(str)
	msg.type = type
	msg.show_vip = self:getShowVip()

	xyd.Backend.get():request(xyd.mid.SEND_RECRUIT_MSGS, msg)
	self:setLastWord("")
end

function Chat:sendCrossMsg(str, type, timeType)
	self:initTempMsg(str, type)

	if xyd.models.selfPlayer:checkPlayerBaned() then
		self:showFakeMsg()

		return
	end

	self.talkTime_[timeType or type] = xyd.getServerTime()
	local msg = messages_pb.send_cross_message_req()
	msg.content = xyd.escapesLuaString(str)
	msg.type = type
	msg.show_vip = self:getShowVip()

	xyd.Backend.get():request(xyd.mid.SEND_CROSS_MESSAGE, msg)
	self:setLastWord("")
end

function Chat:sendLocalMsg(str, type, timeType)
	self:initTempMsg(str, type)

	if xyd.models.selfPlayer:checkPlayerBaned() then
		self:showFakeMsg()

		return
	end

	self.talkTime_[timeType or type] = xyd.getServerTime()
	local msg = messages_pb.send_language_req()
	msg.content = xyd.escapesLuaString(str)
	msg.type = type
	msg.show_vip = self:getShowVip()

	xyd.Backend.get():request(xyd.mid.SEND_LANGUAGE, msg)
	self:setLastWord("")
end

function Chat:sendArcticMsg(str, type, timeType)
	self:initTempMsg(str, type)

	if xyd.models.selfPlayer:checkPlayerBaned() then
		self:showFakeMsg()

		return
	end

	self.talkTime_[timeType or type] = xyd.getServerTime()
	local msg = messages_pb.arctic_expedition_chat_req()
	msg.content = xyd.escapesLuaString(str)
	msg.activity_id = xyd.ActivityID.ARCTIC_EXPEDITION
	msg.show_vip = self:getShowVip()

	xyd.Backend.get():request(xyd.mid.ARCTIC_EXPEDITION_CHAT, msg)
	self:setLastWord("")
end

function Chat:getShowVip()
	local showVip = self:getConfigByIndex(xyd.ChatConfig.SHOW_VIP) or 1

	return showVip
end

function Chat:onGetTalkList(event)
	self.isLoadGm_ = true
	local messages = xyd.decodeProtoBuf(event.data).list or {}
	local msgs = self:sortGMMsgByTime(messages)

	for _, msg in ipairs(msgs) do
		local newData = self:getGMMsgByEventData(msg)

		self:addMsg(newData)
	end

	local time = tonumber(xyd.db.chat:getValue("gm_chat")) or 0
	local lastTime = self:getLastGmTime()

	if time < lastTime then
		self:setGmRedMark(true)
		self:setGMHasReply()
	end

	if event.data.gm_info then
		self.gm_info = xyd.decodeProtoBuf(event.data).gm_info
	end
end

function Chat:getGmInfo()
	return self.gm_info
end

function Chat:onPlayerList(event)
	if not xyd.Global.isLoadingFinish then
		return
	end

	local tmpList = event.data.list
	self.privateList = event.data.list

	for i = 1, #tmpList do
		if not self:isInBlackList(tmpList[i].player_id) and not self:checkIsSuperFilterWord(tmpList[i].chat_msg.sender_id, tmpList[i].chat_msg.content) then
			local tmpTime = xyd.db.chat:getValue("private" .. tostring(tmpList[i].player_id)) or 0

			if tonumber(tmpTime) < tmpList[i].chat_msg.time and tmpList[i].chat_msg.sender_id ~= xyd.Global.playerID then
				self:setRedMark(xyd.MsgType.PRIVATE, true)

				break
			end
		end
	end

	self:updatePlayerList()
end

function Chat:updatePlayerList()
	local wnd = xyd.WindowManager:get():getWindow("chat_window")

	if wnd then
		wnd:updatePlayerList()
	end
end

function Chat:getPrivateList()
	return self.privateList
end

function Chat:getPlayerList()
	local msg = messages_pb.get_player_list_req()

	xyd.Backend.get():request(xyd.mid.GET_PLAYER_LIST, msg)
end

function Chat:getPlayerMessages(id)
	local msg = messages_pb.get_player_messages_req()
	msg.to_player_id = id

	xyd.Backend.get():request(xyd.mid.GET_PLAYER_MESSAGES, msg)
end

function Chat:addBlackList(id)
	local msg = messages_pb.add_black_list_req()
	msg.to_player_id = id

	xyd.Backend.get():request(xyd.mid.ADD_BLACK_LIST, msg)
end

function Chat:removeBlackList(id)
	local msg = messages_pb.remove_black_list_req()
	msg.to_player_id = id

	xyd.Backend.get():request(xyd.mid.REMOVE_BLACK_LIST, msg)
end

function Chat:setBlockWarning()
	xyd.db.chat:setValue({
		value = 1,
		key = "privacy_warning"
	})
end

function Chat:setPlayerBlockWarning(index, to_player_id)
	local dbVal = xyd.db.chat:getValue("privacy_warning:" .. tostring(to_player_id))
	local val = nil

	if dbVal then
		val = cjson.decode(dbVal)
	end

	val = val or {
		0,
		0
	}
	val[index] = 1

	xyd.db.chat:setValue({
		key = "privacy_warning:" .. tostring(to_player_id),
		value = cjson.encode(val)
	})
end

function Chat:getBlockWarning(to_player_id)
	local val = xyd.db.chat:getValue("privacy_warning")

	if val and tonumber(val) == 1 then
		return true
	end

	local recordVal = xyd.db.chat:getValue("privacy_warning:" .. tostring(to_player_id))

	if recordVal then
		local playerVal = cjson.decode(recordVal)

		if playerVal and playerVal[1] == 1 and playerVal[2] == 1 then
			return true
		end
	end

	return false
end

function Chat:showVip(show_vip)
	local msg = messages_pb.show_vip_req()
	msg.show_vip = show_vip

	xyd.Backend.get():request(xyd.mid.SHOW_VIP, msg)
end

function Chat:onGetMessageInfos(event)
	local serverMessages = event.data.server_messages
	local guildMessage = event.data.guild_messages
	local recruitMessage = event.data.recruit_messages
	local crossMessage = event.data.cross_messages
	local languageMessage = event.data.language_messages

	if serverMessages then
		self:onGetServerdMessages(serverMessages)
	end

	if guildMessage then
		self:onGetGuildMessages(guildMessage)
	end

	if recruitMessage then
		self:onGetRecruitMessages(recruitMessage)
	end

	if crossMessage then
		self:onGetCrossMessage(crossMessage)
	end

	if languageMessage then
		self:onGetLocalMessage(languageMessage)
	end
end

function Chat:onFriendTamBossMessages(event)
	local friendTeamBossMessage = event.data.friend_team_boss_messages

	if friendTeamBossMessage then
		self:onGetFriendTeamBossMessages(friendTeamBossMessage)
	end
end

function Chat:sortMsgByTime(messages)
	local msgs = {}

	for i = 1, #messages do
		table.insert(msgs, messages[i])
	end

	table.sort(msgs, function (a, b)
		if a.time ~= b.time then
			return a.time < b.time and true or false
		end

		return false
	end)

	return msgs
end

function Chat:sortGMMsgByTime(messages)
	local msgs = {}

	for i = 1, #messages do
		table.insert(msgs, messages[i])
	end

	table.sort(msgs, function (a, b)
		if a.created_time ~= b.created_time then
			return a.created_time < b.created_time and true or false
		end

		return false
	end)

	return msgs
end

function Chat:onGetServerdMessages(messages)
	local msgs = self:sortMsgByTime(messages)
	local typeNormal = false

	for _, msg in ipairs(msgs) do
		local flag = self:addMsg(msg)

		if flag then
			typeNormal = true
		end
	end

	if typeNormal and self:getConfigByIndex(xyd.ChatConfig.SHOW_WORLD) == 1 then
		self:setRedMark(xyd.MsgType.NORMAL, typeNormal)
	end
end

function Chat:onGetGuildMessages(messages)
	local msgs = self:sortMsgByTime(messages)
	local guildChatTime = tonumber(xyd.db.chat:getValue("guild_chat")) or 0
	local guildFlag = false
	local maxTime = 0

	for _, msg in ipairs(msgs) do
		local flag = self:addMsg(msg)

		if flag then
			if guildChatTime < msg.time then
				guildFlag = true
			end

			maxTime = math.max(maxTime, msg.time)
		end
	end

	xyd.db.chat:setValue({
		key = "guild_chat",
		value = maxTime
	})

	if guildFlag and self:getConfigByIndex(xyd.ChatConfig.SHOW_GUILD) == 1 then
		self:setRedMark(xyd.MsgType.GUILD, guildFlag)
	end
end

function Chat:onGetFriendTeamBossMessages(messages)
	local msgs = self:sortMsgByTime(messages)
	local chatTime = tonumber(xyd.db.chat:getValue("friend_team_boss_chat")) or 0
	local FTBflag = false
	local maxTime = 0

	for _, msg in ipairs(msgs) do
		local flag = self:addMsg(msg)

		if flag then
			if chatTime < msg.time then
				FTBflag = true
			end

			maxTime = math.max(maxTime, msg.time)
		end
	end

	xyd.db.chat:setValue({
		key = "friend_team_boss_chat",
		value = maxTime
	})

	if FTBflag then
		self:setRedMark(xyd.MsgType.FRIEND_TEAM_BOSS_CHAT, FTBflag)
	end
end

function Chat:onGetRecruitMessages(messages)
	local msgs = self:sortMsgByTime(messages)
	local typeRecruit = false
	local recruitTime = tonumber(xyd.db.chat:getValue("recruit_chat")) or 0
	local maxTime = 0

	for _, msg in ipairs(msgs) do
		local flag = self:addMsg(msg)

		if flag then
			if recruitTime < msg.time then
				typeRecruit = true
			end

			maxTime = math.max(maxTime, msg.time)
		end
	end

	xyd.db.chat:setValue({
		key = "recruit_chat",
		value = maxTime
	})

	if typeRecruit and self:getConfigByIndex(xyd.ChatConfig.SHOW_RECRUIT) == 1 then
		self:setRedMark(xyd.MsgType.RECRUIT, typeRecruit)
	end

	if xyd.models.guild.guildID then
		self:setRedMark(xyd.MsgType.RECRUIT, false)
	end
end

function Chat:onGetCrossMessage(messages)
	local msgs = self:sortMsgByTime(messages)
	local crossChatTime = tonumber(xyd.db.chat:getValue("cross_chat")) or 0
	local crossFlag = false
	local maxTime = 0

	for _, msg in ipairs(msgs) do
		self:addMsg(msg)

		if crossChatTime < msg.time then
			crossFlag = true
		end

		maxTime = math.max(maxTime, msg.time)
	end

	xyd.db.chat:setValue({
		key = "cross_chat",
		value = maxTime
	})

	if crossFlag and self:getConfigByIndex(xyd.ChatConfig.SHOW_CROSS) == 1 then
		self:setRedMark(xyd.MsgType.CROSS_CHAT, crossFlag)
	end
end

function Chat:onGetLocalMessage(messages)
	local msgs = self:sortMsgByTime(messages)
	local localChatTime = tonumber(xyd.db.chat:getValue("local_chat")) or 0
	local localFlag = false
	local maxTime = 0

	for _, msg in ipairs(msgs) do
		self:addMsg(msg)

		if localChatTime < msg.time then
			localFlag = true
		end

		maxTime = math.max(maxTime, msg.time)
	end

	xyd.db.chat:setValue({
		key = "local_chat",
		value = maxTime
	})

	if localFlag and self:getConfigByIndex(xyd.ChatConfig.SHOW_LOCAL) == 1 then
		self:setRedMark(xyd.MsgType.LOCAL_CHAT, localFlag)
	end
end

function Chat:addArcticMsg(data)
	if data.content and data.sender_id and self:checkIsSuperFilterWord(data.sender_id, data.content) then
		local key = tostring(data.sender_id) .. tostring(data.time or 0)
		self.filterMsgs_[key] = true

		return false
	end

	local type_ = data.type

	if not xyd.MsgType2Index[type_] then
		return false
	end

	local function addMsgByType(msgType)
		local msgs = self:getMsgsByType(msgType)
		local newData = self:getMsgByEventData(data)

		table.insert(msgs, newData)
		self:updateHeight(msgType, newData.hashCode, DEFAULT_HEIGHT)
	end

	local channel = tonumber(data.channel)

	if channel == 1 then
		addMsgByType(xyd.MsgType.ARCTIC_EXPEDITION_ASSEMBLE, data)
	elseif channel == 2 then
		addMsgByType(xyd.MsgType.ARCTIC_EXPEDITION_SYS, data)
	end

	return true
end

function Chat:onGetArcticMessageInfos(event)
	local messageData = xyd.decodeProtoBuf(event.data)
	local messages = messageData.msg
	local messagesSelf = messageData.msg_self
	messages = xyd.arrayMerge(messages, messagesSelf)
	local msgs = self:sortMsgByTime(messages)

	for _, msg in ipairs(msgs) do
		local eMsgId = tonumber(msg.e_msg_id) or 0

		if eMsgId == 0 then
			msg.type = xyd.MsgType.ARCTIC_EXPEDITION_NORMAL
		elseif eMsgId <= 5 then
			msg.type = xyd.MsgType.ARCTIC_EXPEDITION_SYS
		else
			msg.type = xyd.MsgType.ARCTIC_EXPEDITION_ASSEMBLE
		end

		self:addArcticMsg(msg)
	end
end

function Chat:onGetArcticMessageBack(event)
	local msg = xyd.decodeProtoBuf(event.data)
	local eMsgId = tonumber(msg.e_msg_id) or 0

	if eMsgId == 0 then
		msg.type = xyd.MsgType.ARCTIC_EXPEDITION_NORMAL
	elseif eMsgId <= 5 then
		msg.type = xyd.MsgType.ARCTIC_EXPEDITION_SYS
	else
		msg.type = xyd.MsgType.ARCTIC_EXPEDITION_ASSEMBLE
	end

	self:addArcticMsg(msg)
end

function Chat:getMsgsByType(type)
	local index = xyd.MsgType2Index[type]

	if not self.msgs_[index] then
		self.msgs_[index] = {}
	end

	return self.msgs_[index]
end

function Chat:getMsgsByTypeWithFilter(type)
	local index = xyd.MsgType2Index[type]

	if not self.msgs_[index] then
		self.msgs_[index] = {}
	end

	return self:filterBlackList(self.msgs_[index])
end

function Chat:filterBlackList(msgs)
	local result = {}

	for i = 1, #msgs do
		local msg = msgs[i]

		if not msg.sender_id or not self:isInBlackList(msg.sender_id) then
			table.insert(result, msg)
		end
	end

	return result
end

function Chat:getFinalMsgItem(type)
	local msgs = self:getMsgsByTypeWithFilter(type)

	return msgs[#msgs - 1 + 1]
end

function Chat:getMsgByEventData(data)
	local newData = {
		is_filter = false,
		type = data.type,
		content = data.content,
		time = data.time,
		sender_id = data.sender_id,
		sender_name = data.sender_name,
		sender_level = data.sender_level,
		sender_vip = data.sender_vip,
		show_vip = data.show_vip,
		avatar_id = data.avatar_id,
		channel = data.channel,
		server_id = data.server_id,
		player_type = data.player_type,
		avatar_frame_id = data.avatar_frame_id,
		language = data.language,
		goto_type = data.goto_type,
		goto_val = data.goto_val,
		hashCode = self:getMsgID(),
		originalContent = data.content,
		group = data.group,
		channel = data.channel,
		e_msg_id = data.e_msg_id
	}

	return newData
end

function Chat:getGMMsgByEventData(data)
	local newData = {
		talker_id = data.talker_id,
		talker_name = data.talker_name,
		created_time = data.created_time,
		id = data.id,
		is_talk_over = data.is_talk_over,
		content = data.content,
		player_id = data.player_id,
		is_gm_online = data.is_gm_online,
		msg_format = data.msg_format,
		type = xyd.MsgType.GM,
		hashCode = self:getMsgID(),
		is_filter = false,
		channel = data.channel
	}

	return newData
end

function Chat:addMsg(data)
	if data.content and data.sender_id and self:checkIsSuperFilterWord(data.sender_id, data.content) then
		local key = tostring(data.sender_id) .. tostring(data.time or 0)
		self.filterMsgs_[key] = true

		return false
	end

	local type_ = data.type

	if not xyd.MsgType2Index[type_] then
		return false
	end

	if (type_ == xyd.MsgType.HOUSE_SHARE_NORMAL or type_ == xyd.MsgType.HOUSE_SHARE_GUILD or type_ == xyd.MsgType.HOUSE_SHARE_CROSS_CHAT or type_ == xyd.MsgType.HOUSE_SHARE_LOCAL_CHAT) and xyd.models.chat:getConfigByIndex(xyd.ChatConfig.SHOW_SHARE) == 0 then
		return false
	end

	local msgs = self:getMsgsByType(type_)
	local newData = data

	if data.type ~= xyd.MsgType.GM then
		newData = self:getMsgByEventData(data)
	end

	table.insert(msgs, newData)
	self:updateHeight(type_, newData.hashCode, DEFAULT_HEIGHT)

	if xyd.MAX_CHAT_MSG_NUM < #msgs then
		-- Nothing
	end

	return true
end

function Chat:checkMsgFilter(data)
	if not data.sender_id then
		return false
	end

	local key = tostring(data.sender_id) .. tostring(data.time or 0)

	return self.filterMsgs_[key]
end

function Chat:getMsgID()
	self.curMsgID_ = self.curMsgID_ + 1

	return self.curMsgID_
end

function Chat:getTotalHeight(dataType)
	local index = xyd.MsgType2Index[dataType]

	return self.totalHeight_[index] or 0
end

function Chat:updateHeight(dataType, hashCode, height)
	local index = xyd.MsgType2Index[dataType]
	local curTotalHeight = self.totalHeight_[index] or 0
	local oldHeight = self.heightCache_[hashCode]

	if oldHeight == nil then
		self.heightCache_[hashCode] = height
		curTotalHeight = curTotalHeight + height
	elseif oldHeight ~= height then
		self.heightCache_[hashCode] = height
		curTotalHeight = curTotalHeight + height - oldHeight
	end

	self.totalHeight_[index] = curTotalHeight
end

function Chat:createReportMessage(data)
	data.hasReported = true
	local type_ = data.type
	local msgs = self:getMsgsByTypeWithFilter(type_)
	local max_record_num = 5
	local pre_message = {}
	local later_message = {}
	local findIndx = false
	local popIndx = {}

	for i = 1, #msgs do
		local t_data = msgs[i]

		if not findIndx then
			if t_data.time == data.time then
				findIndx = true
			else
				table.insert(pre_message, {
					player_id = t_data.sender_id,
					content = t_data.content,
					player_name = t_data.sender_name
				})
				table.insert(popIndx, i)

				if max_record_num < #pre_message then
					table.remove(pre_message, 1)
				end
			end
		else
			table.insert(later_message, {
				player_id = t_data.sender_id,
				content = t_data.content,
				player_name = t_data.sender_name
			})

			if max_record_num <= #later_message then
				break
			end
		end
	end

	local msg_string = ""

	for i = 1, #pre_message do
		local pre_msg = pre_message[i]
		msg_string = tostring(msg_string) .. tostring(pre_msg.player_name) .. " " .. tostring(pre_msg.player_id) .. ":" .. tostring(pre_msg.content) .. "|"
	end

	msg_string = tostring(msg_string) .. "REPORT_MESSAGE: " .. tostring(data.content) .. "|"

	for i = 1, #later_message do
		local lat_msg = later_message[i]
		msg_string = tostring(msg_string) .. tostring(lat_msg.player_name) .. " " .. tostring(lat_msg.player_id) .. ":" .. tostring(lat_msg.content) .. "|"
	end

	msg_string = string.sub(msg_string, 1, #msg_string - 1)

	return msg_string
end

function Chat:checkIsSuperFilterWord(playerID, content)
	if playerID ~= xyd.Global.playerID and FilterWordSuperTable:isInWords(content) then
		return true
	end

	return false
end

function Chat:saveConfig(index, flag)
	self:getConfig()

	self.config_[index] = flag

	xyd.db.chat:setValue({
		key = "chat_config",
		value = cjson.encode(self.config_)
	})
end

function Chat:getConfig()
	local str = xyd.db.chat:getValue("chat_config")
	self.config_ = {}

	if str then
		self.config_ = cjson.decode(str)
	end
end

function Chat:getConfigByIndex(index)
	self:getConfig()

	local val = self.config_[index] or 1

	if val and type(val) == "userdata" then
		val = 1
	end

	return val
end

function Chat:getLastTalk(type)
	return self.talkTime_[type] or 0
end

function Chat:talkWithGM(message, timeType, format)
	if format == nil then
		format = "text"
	end

	if self:checkTalkWithGM(message, timeType, format) then
		return
	end

	local msg = messages_pb.talk_with_gm_req()
	msg.content = xyd.escapesLuaString(message)
	msg.msg_format = format
	msg.msg_type = self.gmMsgType
	self.newQuest = false

	xyd.Backend.get():request(xyd.mid.TALK_WITH_GM, msg)

	if format == "img" then
		self:addUsedTimes()
	end

	self:setLastWord("")
end

function Chat:onTalkWithGm(event)
	if self:isLoading() then
		return
	end

	local data = event.data
	local newData = self:getGMMsgByEventData(event.data)

	self:addMsg(newData)

	if data.is_gm_online == 0 then
		XYDCo.WaitForTime(1, function ()
			self:addAutoReply()
		end, nil)
	end
end

function Chat:addAutoReply()
	local params = {
		is_talk_over = 0,
		talker_name = "GM",
		id = 1,
		talker_id = xyd.GM_TALK_ID,
		player_id = xyd.Global.playerID,
		content = __("GM_AUTO_ANSWER"),
		created_time = xyd.getServerTime()
	}

	xyd.EventDispatcher.outer():dispatchEvent({
		name = xyd.event.GM_REPLY,
		data = params
	})
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.GM_REPLY,
		data = params
	})
end

function Chat:addAutoGMReply()
	if self.firstShowTips then
		return
	end

	local isExclusiveGm = false

	if self:getGmInfo() then
		local chat_gm_window = xyd.WindowManager.get():getWindow("chat_gm_window")

		if chat_gm_window then
			isExclusiveGm = true
		end
	end

	if not isExclusiveGm then
		local flag = self:checkLastGMQuestEnd()

		if not flag then
			return
		end
	end

	self.firstShowTips = true
	local params = {
		is_talk_over = 1,
		talker_name = "GM",
		id = 1,
		msg_format = "gm_auto_reply",
		talker_id = xyd.GM_TALK_ID,
		player_id = xyd.Global.playerID,
		content = __("GM_AUTO_RECALL"),
		created_time = xyd.getServerTime()
	}

	xyd.EventDispatcher.outer():dispatchEvent({
		name = xyd.event.GM_REPLY,
		data = params
	})
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.GM_REPLY,
		data = params
	})
end

function Chat:createAutoGMReplyDetail(GMMsgType)
	self.gmMsgType = GMMsgType

	if self.gmTipsHasShows[GMMsgType] then
		xyd.alert(xyd.AlertType.TIPS, __("GM_RECALL_6"))

		return
	end

	self.gmTipsHasShows[GMMsgType] = true
	local params = {
		is_talk_over = 1,
		talker_name = "GM",
		id = 1,
		msg_format = "gm_recall",
		talker_id = xyd.GM_TALK_ID,
		player_id = xyd.Global.playerID,
		content = __("GM_RECALL_" .. tostring(GMMsgType)),
		created_time = xyd.getServerTime()
	}

	xyd.EventDispatcher.outer():dispatchEvent({
		name = xyd.event.GM_REPLY,
		data = params
	})
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.GM_REPLY,
		data = params
	})
end

function Chat:isNewQuest()
	if self:checkLastGMQuestEnd() then
		return self.newQuest
	end

	return false
end

function Chat:checkLastGMQuestEnd()
	local flag = xyd.db.chat:getValue("gm_has_reply")

	if flag then
		return self:isGMQuestEnded()
	else
		return true
	end
end

function Chat:isGMQuestEnded()
	local msgs = self:getMsgsByType(xyd.MsgType.GM)
	local id = -1

	for i = #msgs, 1, -1 do
		local data = msgs[i]

		if data.talker_id <= xyd.GM_TALK_ID then
			local is_talk_over = data.is_talk_over

			return xyd.checkCondition(is_talk_over and is_talk_over == 1, true, false)
		end
	end

	return true
end

function Chat:setGMHasReply()
	local flag = xyd.db.chat:getValue("gm_has_reply")

	if not flag then
		xyd.db.chat:setValue({
			value = 1,
			key = "gm_has_reply"
		})
	end
end

function Chat:checkTalkWithGM(message, timeType, format)
	if format == nil then
		format = "text"
	end

	if format == "img" then
		return false
	end

	local len = xyd.getStrLength(message)

	if len <= 4 and self:isNewQuest() then
		self:creatFakeGMReply(message)

		return true
	end

	return false
end

function Chat:creatFakeGMReply(message)
	local params = {
		is_talk_over = 0,
		id = 2,
		msg_format = "text",
		talker_id = xyd.Global.playerID,
		talker_name = xyd.Global.playerName,
		player_id = xyd.Global.playerID,
		content = message,
		created_time = xyd.getServerTime()
	}

	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.TALK_WITH_GM,
		data = params
	})
	xyd.EventDispatcher.outer():dispatchEvent({
		name = xyd.event.TALK_WITH_GM,
		data = params
	})
	XYDCo.WaitForTime(1, function ()
		self:createFakeShortReply()
	end, nil)
end

function Chat:createFakeShortReply()
	local params = {
		is_talk_over = 1,
		talker_name = "GM",
		id = 1,
		talker_id = xyd.GM_TALK_ID,
		player_id = xyd.Global.playerID,
		content = __("GM_RECALL_6"),
		created_time = xyd.getServerTime()
	}

	xyd.EventDispatcher.outer():dispatchEvent({
		name = xyd.event.GM_REPLY,
		data = params
	})
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.GM_REPLY,
		data = params
	})
end

function Chat:setGmReplyOver()
	local msgs = self:getMsgsByType(xyd.MsgType.GM)
	local id = -1

	for i = #msgs, 1, -1 do
		local data = msgs[i]

		if data.talker_id <= xyd.GM_TALK_ID then
			data.is_talk_over = 1

			return
		end
	end
end

function Chat:onGmReply(event)
	if self:isLoading() then
		return
	end

	local newData = self:getGMMsgByEventData(event.data)

	if newData.talker_id ~= xyd.Global.playerID and newData.id ~= 1 then
		if self:getGmInfo() and (not newData.channel or newData.channel and newData.channel ~= "exclusive") then
			return
		end

		if not self:getGmInfo() and newData.channel and newData.channel == "exclusive" then
			return
		end
	end

	newData.type = xyd.MsgType.GM

	self:addMsg(newData)
	self:setGmRedMark(true)
	self:setGMHasReply()

	local time = xyd.getServerTime() + xyd.tables.deviceNotifyTable:getDelayTime(xyd.DEVICE_NOTIFY.NEW_GM_REPLY_MESSAGE)

	xyd.models.deviceNotify:setNotifyTime(xyd.DEVICE_NOTIFY.NEW_GM_REPLY_MESSAGE, time)
end

function Chat:getLastGmID()
	local msgs = self:getMsgsByType(xyd.MsgType.GM)
	local id = -1

	for i = #msgs, 1, -1 do
		local data = msgs[i]

		if data.talker_id <= xyd.GM_TALK_ID then
			id = data.id

			break
		end
	end

	return id
end

function Chat:getLastGmTime()
	local msgs = self:getMsgsByType(xyd.MsgType.GM)
	local time = -1

	for i = #msgs, 1, -1 do
		local data = msgs[i]

		if data.talker_id <= xyd.GM_TALK_ID and data.id ~= 1 then
			time = data.created_time

			break
		end
	end

	return time
end

function Chat:setGmRead()
	local id = self:getLastGmID()
	local time = self:getLastGmTime()

	xyd.db.chat:setValue({
		key = "gm_chat",
		value = time
	})

	if id == 1 then
		return
	end

	local msg = messages_pb.set_gm_message_read_req()
	msg.id = id

	if self:getGmInfo() then
		msg.channel = "exclusive"
	end

	xyd.Backend.get():request(xyd.mid.SET_GM_MESSAGE_READ, msg)
end

function Chat:setGmRedMark(flag)
	if not flag then
		self:setGmRead()
	end

	self:setRedMark(xyd.MsgType.GM, flag)
end

function Chat:setRedMark(msgType, flag)
	local redMarkType = 0

	if msgType == xyd.MsgType.NORMAL then
		redMarkType = xyd.RedMarkType.CHAT
	elseif msgType == xyd.MsgType.GM then
		redMarkType = xyd.RedMarkType.GM_CHAT
	elseif msgType == xyd.MsgType.GUILD then
		redMarkType = xyd.RedMarkType.GUILD_CHAT
	elseif msgType == xyd.MsgType.RECRUIT then
		redMarkType = xyd.RedMarkType.RECRUIT_CHAT
	elseif msgType == xyd.MsgType.PRIVATE then
		redMarkType = xyd.RedMarkType.PRIVATE_CHAT
	elseif msgType == xyd.MsgType.GUILD_WAR then
		redMarkType = xyd.RedMarkType.GUILD_CHAT
	elseif msgType == xyd.MsgType.CROSS_CHAT then
		redMarkType = xyd.RedMarkType.CROSS_CHAT
	elseif msgType == xyd.MsgType.FRIEND_TEAM_BOSS_CHAT then
		redMarkType = xyd.RedMarkType.FRIEND_TEAM_BOSS_MSG
	elseif msgType == xyd.MsgType.LOCAL_CHAT or msgType == xyd.MsgType.NOTICE_WITH_JUMP then
		redMarkType = xyd.RedMarkType.LOCAL_CHAT
	elseif msgType == xyd.MsgType.ARCTIC_EXPEDITION_ASSEMBLE then
		redMarkType = xyd.RedMarkType.ARCTIC_CHAT_EXPEDITION_1
	elseif msgType == xyd.MsgType.ARCTIC_EXPEDITION_SYS then
		redMarkType = xyd.RedMarkType.ARCTIC_CHAT_EXPEDITION_2
	end

	if redMarkType == xyd.RedMarkType.GM_CHAT and not flag then
		self:setGmRead()
	end

	if redMarkType > 0 then
		xyd.models.redMark:setMark(redMarkType, flag)
	end

	self:updateMainWindowRed()
end

function Chat:updateMainWindowRed()
	local redMark = xyd.models.redMark

	if redMark:getRedState(xyd.RedMarkType.PRIVATE_CHAT) then
		xyd.models.redMark:setMark(xyd.RedMarkType.CHAT_RED_PRIVATE, true)
		xyd.models.redMark:setMark(xyd.RedMarkType.CHAT_RED_NORMAL, false)
		xyd.models.redMark:setMark(xyd.RedMarkType.CHAT_RED_GUILD, false)
	elseif redMark:getRedState(xyd.RedMarkType.GUILD_CHAT) then
		xyd.models.redMark:setMark(xyd.RedMarkType.CHAT_RED_PRIVATE, false)
		xyd.models.redMark:setMark(xyd.RedMarkType.CHAT_RED_NORMAL, false)
		xyd.models.redMark:setMark(xyd.RedMarkType.CHAT_RED_GUILD, true)
	elseif redMark:getRedState(xyd.RedMarkType.CHAT) or redMark:getRedState(xyd.RedMarkType.RECRUIT_CHAT) or redMark:getRedState(xyd.RedMarkType.CROSS_CHAT) or redMark:getRedState(xyd.RedMarkType.LOCAL_CHAT) then
		xyd.models.redMark:setMark(xyd.RedMarkType.CHAT_RED_PRIVATE, false)
		xyd.models.redMark:setMark(xyd.RedMarkType.CHAT_RED_NORMAL, true)
		xyd.models.redMark:setMark(xyd.RedMarkType.CHAT_RED_GUILD, false)
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.CHAT_RED_PRIVATE, false)
		xyd.models.redMark:setMark(xyd.RedMarkType.CHAT_RED_NORMAL, false)
		xyd.models.redMark:setMark(xyd.RedMarkType.CHAT_RED_GUILD, false)
	end
end

function Chat:displayNotice()
	xyd.models.floatMessage:showMessage()
end

function Chat:popNotice()
	local notice = table.remove(self.noticeList, #self.noticeList)

	return notice
end

function Chat:checkEmoLegal(str)
	if string.sub(str, 1, 8) == "#emotion" then
		local numNew = xyd.split(str, "#emotion")
		local num = tonumber(numNew[2])
		local all = xyd.tables.emotionTable:getLength()

		if num and tonumber(num) >= 1 and tonumber(num) <= all then
			return tonumber(num)
		end
	end

	return -1
end

function Chat:checkGifLegal(str)
	if string.sub(str, 1, 4) == "#gif" then
		local numNew = xyd.split(str, "#gif")
		local num = tonumber(numNew[2])
		local all = xyd.tables.emotionGifTable:getAllLength()

		if num and tonumber(num) >= 1 and tonumber(num) <= all and xyd.tables.emotionGifTable:getIsShow(tonumber(num)) then
			return tonumber(num)
		end
	end

	return -1
end

function Chat:checkHouseShareLegal(str)
	local data = cjson.decode(str)

	if data.house_share_mark ~= xyd.HOUSE_SHARE_MAKR then
		return -1
	end

	return 1
end

function Chat:checkIfGifOrEmo(str)
	return self:checkEmoLegal(str) ~= -1 or self:checkGifLegal(str) ~= -1
end

function Chat:test(content, goto_type, goto_val)
	local times = MiscTable:getNumber("announcement_repeat_times", "value")
	local raw_content = content

	for i = 1, times do
		content = content .. raw_content
	end

	table.insert(self.noticeList, {
		content = content,
		goto_type = goto_type,
		goto_val = goto_val
	})
	self:displayNotice()
end

function Chat:getLastWord()
	return self.lastWord_
end

function Chat:setLastWord(word)
	self.lastWord_ = word
end

function Chat:getRecord(index)
	return self.records_[index] or 1
end

function Chat:setRecord(index, key)
	if not key then
		local msgs = self:getMsgsByTypeWithFilter(index)
		key = #msgs
	end

	self.records_[index] = key
end

function Chat:translateFrontend(msg, callback)
	local content = msg.content
	local translate = self:checkTranslate(content)

	if translate then
		msg.translate = translate

		return callback(msg, xyd.TranslateType.OK)
	elseif self:isInTranslate(content) then
		table.insert(self.inTranslate_[content], callback)

		return callback(msg, xyd.TranslateType.DOING)
	end

	self.inTranslate_[content] = {}

	table.insert(self.inTranslate_[content], callback)

	local msgID = tostring(xyd.Global.playerID) .. tostring(xyd.getServerTime())

	if XYDUtils.IsTest() then
		msgID = "123"
	end

	self.translaID2Content_[msgID] = msg

	xyd.TranslationManager.get():translate(msgID, content, handler(self, self.onTranslate))
end

function Chat:checkTranslate(content)
	return self.translateContent_[content] or nil
end

function Chat:isInTranslate(content)
	return self.inTranslate_[content]
end

function Chat:onTranslate(data)
	local msg = self.translaID2Content_[data.msgID] or {}
	local content = msg.content

	if content then
		local transl = data.transl
		self.translateContent_[content] = transl
		local callbacks = self:isInTranslate(content) or {}

		for _, callback in ipairs(callbacks) do
			if callback then
				msg.translate = transl

				callback(msg, xyd.TranslateType.OK)
			end
		end

		self.inTranslate_[content] = nil
	end
end

function Chat:testTranslate(msgID, content, callback)
	local random = true
	local data = {
		transl = "transl .. " .. tostring(content),
		msgID = msgID
	}

	if random then
		callback(data)
	else
		XYDCo.WaitForTime(0.5, function ()
			callback(data)
		end)
	end
end

function Chat:checkUpdateUpLoadTimes()
	local curTime = os.time()

	if self.lastSaveTime_ == nil then
		local str = xyd.db.chat:getValue("gmchat_upload_img_time")

		if str then
			local array = xyd.split(str, "|", true)
			self.lastSaveTime_ = math.min(array[1] or 0, curTime)
			self.lastUsedTimes_ = array[2] or 0
		else
			self.lastSaveTime_ = 0
			self.lastUsedTimes_ = 0
		end
	end

	local oldTb = os.date("*t", self.lastSaveTime_)
	local nextUpdateTime = 0

	if self.DailyUpdateHour <= oldTb.hour then
		local tmp = (oldTb.hour - self.DailyUpdateHour) * 3600 + oldTb.min * 60 + oldTb.sec
		nextUpdateTime = self.lastSaveTime_ + 86400 - tmp
	else
		local tmp = (self.DailyUpdateHour - oldTb.hour) * 3600 - oldTb.min * 60 - oldTb.sec
		nextUpdateTime = self.lastSaveTime_ + tmp
	end

	if curTime >= nextUpdateTime then
		self.lastSaveTime_ = curTime
		self.lastUsedTimes_ = 0

		xyd.db.chat:setValue({
			key = "gmchat_upload_img_time",
			value = tostring(self.lastSaveTime_) .. "|" .. tostring(self.lastUsedTimes_)
		})
	end
end

function Chat:checkCanUpLoad()
	self:checkUpdateUpLoadTimes()

	local limit = MiscTable:getVal("gm_image_limit") or 0

	return tonumber(limit) - self.lastUsedTimes_ > 0
end

function Chat:addUsedTimes()
	self.lastUsedTimes_ = self.lastUsedTimes_ + 1

	xyd.db.chat:setValue({
		key = "gmchat_upload_img_time",
		value = tostring(self.lastSaveTime_) .. "|" .. tostring(self.lastUsedTimes_)
	})
end

function Chat:reportMessage(report_player_id, report_type, message)
	local msg = messages_pb.report_message_req()
	msg.to_player_id = report_player_id
	msg.report_type = report_type
	msg.message = message

	xyd.Backend.get():request(xyd.mid.REPORT_MESSAGE, msg)
end

function Chat:checkIsGif(msg)
	local isEmo = string.find(msg, "#emotion")
	local isGif = string.find(msg, "#gif")

	if isEmo or isGif then
		return true
	end

	return false
end

function Chat:deleteChatMsg(playerID)
	local msg = messages_pb.remove_chat_player_req()
	msg.other_player_id = playerID

	xyd.Backend.get():request(xyd.mid.REMOVE_CHAT_PLAYER, msg)
end

function Chat:deletePrivateMessage(event)
	local playerID = event.data.player_id

	for i = 1, #self.privateList do
		if self.privateList[i].player_id == playerID then
			table.remove(self.privateList, i)

			break
		end
	end
end

return Chat
