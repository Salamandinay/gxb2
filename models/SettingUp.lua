local BaseModel = import(".BaseModel")
local SettingUp = class("SettingUp", BaseModel)
local json = require("cjson")

function SettingUp:ctor(...)
	SettingUp.super.ctor(self, ...)

	self.serverDatas_ = nil
	self.noticeData_ = nil
	self.isChangeLan_ = false
	self.isOnlyChange_ = false
end

function SettingUp:onRegister()
	SettingUp.super.onRegister(self)
	self:registerEvent(xyd.event.GET_SERVER_LIST, self.onServerList, self)
	self:registerEvent(xyd.event.GET_APP_NEW, self.onNotice, self)
	self:registerEvent(xyd.event.CHANGE_LANGUAGE, self.onChangeLanguage, self)
	self:registerEvent(xyd.event.GET_GAME_NOTICE_LIST, self.onGetGameNoticeInfo, self)
end

function SettingUp:reqSettingUpInfo()
end

function SettingUp:reqGetServerList()
	if self.serverDatas_ then
		return
	end

	local msg = messages_pb:get_server_list_req()
	msg.uid = xyd.Global.uid
	msg.platform_id = xyd.Global.platformId_

	xyd.Backend:get():request(xyd.mid.GET_SERVER_LIST, msg)
end

function SettingUp:onServerList(event)
	self.serverDatas_ = event.data
	local serverInfos = self:getServerInfos()

	table.sort(serverInfos, function (a, b)
		return tonumber(a.server_id) < tonumber(b.server_id)
	end)

	local i = #serverInfos

	while i >= 1 and i >= #serverInfos - 1 do
		serverInfos[i] = {
			is_new = true,
			name = serverInfos[i].name,
			is_hide = serverInfos[i].is_hide,
			create_time = serverInfos[i].create_time,
			server_id = serverInfos[i].server_id
		}
		i = i - 1
	end

	self:sortServerInfo()
end

function SettingUp:reqNotice()
	if self.noticeData_ then
		return
	end

	local msg = messages_pb.get_app_new_req()
	msg.language = tonumber(xyd.tables.playerLanguageTable:getIDByName(xyd.Global.lang))

	xyd.Backend:get():request(xyd.mid.GET_APP_NEW, msg)
end

function SettingUp:onNotice(event)
	if not event.data.content then
		return
	end

	self.noticeData_ = require("cjson").decode(event.data.content)
	self.iosAppV_ = event.data.ios_app_v
	self.androidAppV_ = event.data.android_app_v
	self.webAppV_ = event.data.web_v
	self.gameV_ = event.data.version
end

function SettingUp:setNoticedata(data)
	self.noticeData_ = require("cjson").decode(data)
end

function SettingUp:reqFeedback(message)
end

function SettingUp:getNotice()
	if self.noticeData_ then
		return self.noticeData_
	end

	return nil
end

function SettingUp:getAppV()
	return 0
end

function SettingUp:getGameV()
	return self.gameV_ or "1.0.0"
end

function SettingUp:getServerData()
	return self.serverDatas_ or {}
end

function SettingUp:getServerInfos()
	return self:getServerData().server_infos or {}
end

function SettingUp:getPlayerInfos()
	return self:getServerData().player_infos or {}
end

function SettingUp:checkHasRole(serverID)
	if not self.roleServerId then
		self.roleServerId = {}
		local playerInfos = self:getPlayerInfos()

		for _, info in ipairs(playerInfos) do
			self.roleServerId[info.server_id] = info
		end
	end

	return self.roleServerId[serverID]
end

function SettingUp:getLevByServerId(id)
	local info = self:checkHasRole(id)

	if not info then
		return 0
	else
		return info.lev
	end
end

function SettingUp:sortServerInfo()
	local infos = self:getServerInfos()
	local curServerID = xyd.models.selfPlayer:getServerID()

	table.sort(infos, function (a, b)
		local valA = 0
		local valB = 0

		if a.server_id == curServerID then
			valA = valA + 1000
		end

		if b.server_id == curServerID then
			valB = valB + 1000
		end

		if self:checkHasRole(a.server_id) ~= nil then
			valA = valA + 100
		end

		if self:checkHasRole(b.server_id) ~= nil then
			valB = valB + 100
		end

		if self:checkHasRole(a.server_id) and self:checkHasRole(b.server_id) then
			local levA = self:getLevByServerId(a.server_id)
			local levB = self:getLevByServerId(b.server_id)

			if levB < levA then
				valA = valA + 500
			elseif levA < levB then
				valB = valB + 500
			end
		end

		if b.server_id < a.server_id then
			valA = valA + 50
		elseif a.server_id < b.server_id then
			valB = valB + 50
		end

		return valA > valB
	end)
end

function SettingUp:changeLanguage(language, onlyChange)
	self.isOnlyChange_ = onlyChange
	local msg = messages_pb.change_language_req()
	msg.language = tonumber(language)

	xyd.Backend:get():request(xyd.mid.CHANGE_LANGUAGE, msg)
end

function SettingUp:onChangeLanguage(event)
	if self.isChangeLan_ or self.isOnlyChange_ then
		return
	end

	self.isChangeLan_ = true
	local lanID = event.data.language
	local lan = xyd.tables.playerLanguageTable:getTrueCode(lanID)
	xyd.Global.lang = lan
	xyd.lang = lan

	UnityEngine.PlayerPrefs.SetString(XYDDef.PrefLangKey, lan)
	xyd.SdkManager.get():SetSDKLanguage()
	xyd.EventDispatcher:inner():dispatchEvent({
		name = xyd.event.CHANGE_PLAYER_LANGUAGE,
		data = {}
	})
end

function SettingUp:getValue(key)
	local redMarkSetting = xyd.db.misc:getValue(key)

	return redMarkSetting
end

function SettingUp:setValue(redMarkData)
	xyd.db.misc:setValue({
		key = "red_mark_setting",
		value = json.encode(redMarkData)
	})
end

function SettingUp:reqGameNoticeInfo()
	local msg = messages_pb.get_game_notice_list_req()

	xyd.Backend:get():request(xyd.mid.GET_GAME_NOTICE_LIST, msg)
end

function SettingUp:onGetGameNoticeInfo(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.gameNoticeInfo_ = data.game_notice_list
	local community_act_list = event.data.community_act_list

	if tostring(community_act_list) ~= "" then
		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.GET_COMMUNITY_ACT_INFO,
			data = community_act_list
		})
	end

	self:updateGetNoticeReadList()
end

function SettingUp:getGameNotices()
	return self.gameNoticeInfo_ or {}
end

function SettingUp:updateGetNoticeReadList()
	local noticeList = self:getGameNoticeReadList()
	local noticeDatas = self:getGameNotices()
	self.needRedList = {}

	for _, data in ipairs(noticeDatas) do
		local id = data.id
		local index = xyd.arrayIndexOf(noticeList, id)

		if xyd.getServerTime() <= data.end_time and data.start_time <= xyd.getServerTime() then
			self.needRedList[id] = 1
		elseif data.end_time < xyd.getServerTime() and index > 0 then
			table.remove(noticeList, index)

			self.needRedList[id] = 0
		else
			self.needRedList[id] = 0
		end
	end

	xyd.db.misc:setValue({
		key = "game_notice_read_list",
		value = json.encode(noticeList)
	})
end

function SettingUp:getShowNoticeBtn()
	if not self.needRedList then
		return false
	else
		for index, value in pairs(self.needRedList) do
			if value >= 1 then
				return true
			end
		end
	end

	return false
end

function SettingUp:checkNoticeShow()
	local noticeList = self:getGameNoticeReadList()
	local needShow = false

	if self.needRedList then
		for index, value in pairs(self.needRedList) do
			if value == 1 and xyd.arrayIndexOf(noticeList, index) < 0 then
				needShow = true

				break
			end
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.GAME_NOTICE, needShow)

	return needShow
end

function SettingUp:addReadId(id)
	local noticeList = self:getGameNoticeReadList()

	table.insert(noticeList, id)
	xyd.db.misc:setValue({
		key = "game_notice_read_list",
		value = json.encode(noticeList)
	})
end

function SettingUp:getGameNoticeReadList()
	local choose_list = xyd.db.misc:getValue("game_notice_read_list")

	if choose_list and choose_list ~= "" then
		return json.decode(choose_list)
	else
		return {}
	end
end

return SettingUp
