local BaseWindow = import(".BaseWindow")
local GuildCompetitionRecordWindow = class("GuildCompetitionRecordWindow", BaseWindow)
local GuildCompetitionRecordItem = class("GuildCompetitionRecordItem", import("app.components.BaseComponent"))
local cjson = require("cjson")
GuildCompetitionRecordWindow.GuildCompetitionRecordItem = GuildCompetitionRecordItem

function GuildCompetitionRecordWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.inTrans = false
	self.showTrans = false
end

function GuildCompetitionRecordWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()

	local msg = messages_pb:guild_competition_attend_req()
	msg.activity_id = xyd.ActivityID.GUILD_COMPETITION

	xyd.Backend.get():request(xyd.mid.GUILD_COMPETITION_ATTEND, msg)
end

function GuildCompetitionRecordWindow:getUIComponent()
	local go = self.window_
	local group = go:NodeByName("groupAction").gameObject
	self.labelWinTitle = group:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = group:NodeByName("closeBtn").gameObject
	self.btnMail = group:NodeByName("btnMail").gameObject
	self.btnMail_label = group:ComponentByName("btnMail/button_label", typeof(UILabel))
	self.labelName = group:ComponentByName("labelName", typeof(UILabel))
	self.labelNum = group:ComponentByName("labelNum", typeof(UILabel))
	self.scroll_ = group:ComponentByName("scroll", typeof(UIScrollView))
	self.groupItems = group:ComponentByName("scroll/groupItems", typeof(UIGrid))
	self.guild_competition_record_item = go:NodeByName("guild_competition_record_item").gameObject
end

function GuildCompetitionRecordWindow:initUIComponent()
	self.guild_competition_record_item:SetActive(false)

	local data = xyd.models.guild.base_info
	local level = xyd.models.guild.level
	local members = xyd.models.guild.members
	self.labelName.text = data.name
	self.labelNum.text = #members .. "/" .. tostring(xyd.tables.guildExpTable:getMember(level))
	self.btnMail_label.text = __("MAIL_TEXT")

	if xyd.Global.lang == "de_de" then
		self.btnMail_label.fontSize = 20
	end
end

function GuildCompetitionRecordWindow:registerEvent()
	GuildCompetitionRecordWindow.super.register(self)
	self:setCloseBtn(self.closeBtn)
	self.eventProxy_:addEventListener(xyd.event.GUILD_COMPETITION_ATTEND, self.onAttendInfo, self)

	UIEventListener.Get(self.btnMail.gameObject).onClick = handler(self, self.onTouchMail)
end

function GuildCompetitionRecordWindow:onAttendInfo(event)
	self.members = {}
	local data = cjson.decode(event.data.attend_info)
	local members = xyd.models.guild.members

	for i = 1, #members do
		local member = {
			attend_times = 0,
			data = members[i]
		}

		table.insert(self.members, member)
	end

	for i = 1, #self.members do
		if data[tostring(self.members[i].data.player_id)] ~= nil then
			self.members[i].attend_times = data[tostring(self.members[i].data.player_id)]
		end
	end

	self:setMemberList()
end

function GuildCompetitionRecordWindow:onTouchMail()
	local selectedIDs = {}
	local selectedNames = {}

	for _, item in ipairs(self.groupItems_) do
		if item:isSelected() then
			table.insert(selectedIDs, item:getPlayerID())
			table.insert(selectedNames, item:getPlayerName())
		end
	end

	if #selectedIDs == 0 then
		xyd.alert(xyd.AlertType.TIPS, __("GUILD_BOSS_SELECT"))

		return
	end

	local MailSendWindowTypeMultiPlayer = 3

	xyd.WindowManager.get():openWindow("mail_send_window", {
		type = MailSendWindowTypeMultiPlayer,
		playerIDs = selectedIDs,
		playerNames = selectedNames
	})
end

function GuildCompetitionRecordWindow:setMemberList()
	local members = self.members

	NGUITools.DestroyChildren(self.groupItems.gameObject.transform)

	local function sort_(a, b)
		local result = nil

		if tonumber(a.attend_times) == tonumber(b.attend_times) then
			if tonumber(a.data.job) == tonumber(b.data.job) then
				if tonumber(a.data.is_online) == tonumber(b.data.is_online) then
					result = tonumber(b.data.last_time) < tonumber(a.data.last_time)
				else
					result = tonumber(b.data.is_online) < tonumber(a.data.is_online)
				end
			else
				result = tonumber(b.data.job) < tonumber(a.data.job)
			end
		else
			result = tonumber(a.attend_times) < tonumber(b.attend_times)
		end

		return result
	end

	table.sort(members, sort_)

	self.groupItems_ = {}

	for i = 1, #members do
		local info = members[i]

		XYDCo.WaitForFrame(i, function ()
			local wnd = xyd.WindowManager.get():getWindow("guild_competition_record_window")

			if not wnd then
				return
			end

			local item = GuildCompetitionRecordItem.new(self.groupItems.gameObject, info, function ()
				if info.data.player_id == xyd.models.selfPlayer:getPlayerID() then
					return
				end

				xyd.WindowManager.get():openWindow("arena_formation_window", {
					is_robot = false,
					player_id = info.data.player_id
				})
			end, self.scroll_:GetComponent(typeof(UIPanel)))

			table.insert(self.groupItems_, item)
			self.groupItems:Reposition()

			if i == 1 or i == #members then
				self.scroll_:ResetPosition()
			end
		end, nil)
	end
end

function GuildCompetitionRecordItem:ctor(go, info, callback, parentPanel)
	GuildCompetitionRecordItem.super.ctor(self, go)

	self.data = info.data
	self.attendTimes = info.attend_times
	self.callback = callback
	self.parentPanel_ = parentPanel
	self.onSelect = false

	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function GuildCompetitionRecordItem:getPrefabPath()
	return "Prefabs/Windows/guild_competition_record_item"
end

function GuildCompetitionRecordItem:getUIComponent()
	local go = self.go
	self.imgbg = go:ComponentByName("imgbg", typeof(UISprite))
	self.groupAvatar = go:NodeByName("groupAvatar").gameObject
	self.labelText0 = go:ComponentByName("labelText0", typeof(UILabel))
	self.labelText1 = go:ComponentByName("labelText1", typeof(UILabel))
	self.labelText2 = go:ComponentByName("labelText2", typeof(UILabel))
	self.labelText3 = go:ComponentByName("labelText3", typeof(UILabel))
	self.guildWarFlag = go:ComponentByName("guildWarFlag", typeof(UISprite))
	local group = go:NodeByName("groupChoose1").gameObject
	self.groupChoose = group
	self.imgSelect = group:NodeByName("imgSelect1_").gameObject
end

function GuildCompetitionRecordItem:initUIComponent()
	local data = self.data
	local playerIcon = require("app.components.PlayerIcon").new(self.groupAvatar, self.parentPanel_)

	playerIcon:setInfo({
		noClick = true,
		avatarID = data.avatar_id,
		avatar_frame_id = data.avatar_frame_id
	})
	playerIcon:SetLocalScale(0.6491228070175439, 0.6491228070175439, 1)

	self.labelText0.text = tostring(data.lev)
	self.labelText1.text = data.player_name
	self.labelText2.text = __("GUILD_JOB" .. tostring(data.job))
	self.labelText3.text = tostring(self.attendTimes) .. "/3"

	self.imgSelect:SetActive(false)

	if self.data.player_id == xyd.models.selfPlayer:getPlayerID() then
		self.groupChoose:SetActive(false)
	end
end

function GuildCompetitionRecordItem:registerEvent()
	UIEventListener.Get(self.groupChoose).onClick = handler(self, function ()
		if self.onSelect == true then
			self.onSelect = false

			self.imgSelect:SetActive(false)
		else
			self.onSelect = true

			self.imgSelect:SetActive(true)
		end
	end)
end

function GuildCompetitionRecordItem:isSelected()
	return self.onSelect
end

function GuildCompetitionRecordItem:getPlayerID()
	return self.data.player_id
end

function GuildCompetitionRecordItem:getPlayerName()
	return self.data.player_name
end

return GuildCompetitionRecordWindow
