local BaseWindow = import(".BaseWindow")
local GuildPlayerTipWindow = class("GuildPlayerTipWindow", BaseWindow)

function GuildPlayerTipWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.playerID = params.player_id
	self.playerInfo = params.player_info
	self.data = params.data
end

function GuildPlayerTipWindow:getUIComponent()
	local go = self.window_:NodeByName("e:Group").gameObject
	self.closeBtn = go:NodeByName("closeBtn").gameObject
	local pIcon = go:NodeByName("pIcon").gameObject
	self.pIcon = require("app.components.PlayerIcon").new(pIcon)
	self.playerName = go:ComponentByName("playerName", typeof(UILabel))
	self.labelText01 = go:ComponentByName("labelText01", typeof(UILabel))
	self.labelText02 = go:ComponentByName("labelText02", typeof(UILabel))
	self.groupText = go:NodeByName("groupText").gameObject
	self.labelText03 = self.groupText:ComponentByName("labelText03", typeof(UILabel))
	self.labelText04 = self.groupText:ComponentByName("labelText04", typeof(UILabel))
	self.labelFormation = go:ComponentByName("labelFormation", typeof(UILabel))
	self.groupPower = go:NodeByName("groupPower").gameObject
	self.labelPower = self.groupPower:ComponentByName("labelPower", typeof(UILabel))
	self.groupFormation1 = go:NodeByName("groupFormation1").gameObject
	self.groupFormation2 = go:NodeByName("groupFormation2").gameObject
	self.btnAppoint = go:NodeByName("btnAppoint").gameObject
	self.btnRecall = go:NodeByName("btnRecall").gameObject
	self.btnTransfer = go:NodeByName("btnTransfer").gameObject
	self.btnRemove = go:NodeByName("btnRemove").gameObject
	self.btnAppoint_label = self.btnAppoint:ComponentByName("button_label", typeof(UILabel))
	self.btnRecall_label = self.btnRecall:ComponentByName("button_label", typeof(UILabel))
	self.btnTransfer_label = self.btnTransfer:ComponentByName("button_label", typeof(UILabel))
	self.btnRemove_label = self.btnRemove:ComponentByName("button_label", typeof(UILabel))
end

function GuildPlayerTipWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function GuildPlayerTipWindow:onFormationInfo(event)
	self.playerInfo = event.data

	self:initUIComponent()
end

function GuildPlayerTipWindow:registerEvent()
	if not self.playerInfo then
		xyd.models.arena:reqEnemyInfo(self.playerID)
		self.eventProxy_:addEventListener(xyd.event.ARENA_GET_ENEMY_INFO, self.onFormationInfo, self)
	end

	self:setCloseBtn(self.closeBtn)
	xyd.setDarkenBtnBehavior(self.btnRemove, self, self.onTouchRemove)
	xyd.setDarkenBtnBehavior(self.btnTransfer, self, self.onTouchTransfer)
	xyd.setDarkenBtnBehavior(self.btnAppoint, self, self.onTouchAppoint)
	xyd.setDarkenBtnBehavior(self.btnRecall, self, self.onTouchRecall)
	self.eventProxy_:addEventListener(xyd.event.GUILD_TRANSFER, self.onTransfer, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_APPOINT, self.onAppoint, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_REMOVE, self.onRemove, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_RECALL, self.onRecall, self)
end

function GuildPlayerTipWindow:setBtns()
	self.btnAppoint_label.text = __("GUILD_TEXT33")
	self.btnRecall_label.text = __("GUILD_TEXT34")
	self.btnTransfer_label.text = __("GUILD_TEXT35")
	self.btnRemove_label.text = __("GUILD_TEXT36")

	self.btnAppoint:SetActive(false)
	self.btnRecall:SetActive(false)
	self.btnTransfer:SetActive(false)
	self.btnRemove:SetActive(false)
end

function GuildPlayerTipWindow:initUIComponent()
	self:setBtns()

	if not self.playerInfo then
		return
	end

	local data = self.playerInfo
	self.labelFormation.text = __("GUILD_TEXT37")
	self.playerName.text = data.player_name
	self.labelText01.text = "ID"
	self.labelText02.text = data.player_id
	self.labelText03.text = __("GUILD_TEXT12")
	self.labelText04.text = data.guild_name

	self.groupText:GetComponent(typeof(UILayout)):Reposition()
	self.pIcon:setInfo({
		avatarID = data.avatar_id,
		lev = data.lev
	})

	local power = 0

	for i = 1, #data.partners do
		local pos = data.partners[i].pos
		local partner = require("app.models.Partner").new()

		partner:populate(data.partners[i])

		local partnerInfo = partner:getInfo()
		partnerInfo.noClick = true
		local group = pos <= 2 and self.groupFormation1:NodeByName("icon" .. pos).gameObject or self.groupFormation2:NodeByName("icon" .. pos).gameObject
		local heroIcon = require("app.components.HeroIcon").new(group)

		heroIcon:setInfo(partnerInfo)
		heroIcon:SetLocalScale(0.7962962962962963, 0.7962962962962963, 1)

		local icon = pos <= 2 and self.window_:NodeByName("e:Group/groupFormation1/icon" .. pos .. "/imgIcon" .. pos).gameObject or self.window_:NodeByName("e:Group/groupFormation2/icon" .. pos .. "/imgIcon" .. pos).gameObject

		icon:SetActive(false)

		power = power + data.partners[i].power
	end

	self.groupFormation1:GetComponent(typeof(UILayout)):Reposition()
	self.groupFormation2:GetComponent(typeof(UILayout)):Reposition()

	self.labelPower.text = power

	self.groupPower:GetComponent(typeof(UILayout)):Reposition()

	if self.data.job == xyd.GUILD_JOB.VICE_LEADER and xyd.models.guild.guildJob == xyd.GUILD_JOB.LEADER then
		self.btnRecall:SetActive(true)
		self.btnTransfer:SetActive(true)
		self.btnRemove:SetActive(true)
	elseif self.data.job == xyd.GUILD_JOB.NORMAL and xyd.models.guild.guildJob == xyd.GUILD_JOB.LEADER then
		self.btnAppoint:SetActive(true)
		self.btnTransfer:SetActive(true)
		self.btnRemove:SetActive(true)
	elseif self.data.job == xyd.GUILD_JOB.NORMAL and xyd.models.guild.guildJob == xyd.GUILD_JOB.VICE_LEADER then
		self.btnRemove:SetActive(true)
	end
end

function GuildPlayerTipWindow:onTouchRemove()
	if xyd.models.guild:getGuildCompetitionInfo() and xyd.models.guild:getGuildCompetitionLeftTime().type == 2 then
		xyd.showToast(__("GUILD_COMPETITION_NO_TIPS2"))

		return
	end

	xyd.alert(xyd.AlertType.YES_NO, __("GUILD_KICK_TIPS"), function (yes_no)
		if yes_no then
			xyd.models.guild:removeMember(self.playerID)
		end
	end)
end

function GuildPlayerTipWindow:onTouchAppoint()
	local max = xyd.tables.guildExpTable:getAssistant(xyd.models.guild.level)
	local members = xyd.models.guild.members
	local count = 0

	for i = 1, #members do
		local data = members[i]

		if data.job == xyd.GUILD_JOB.VICE_LEADER then
			count = count + 1
		end
	end

	if max <= count then
		xyd.showToast(__("GUILD_TEXT57"))

		return
	end

	xyd.models.guild:appointGuildLeder(self.playerID)
end

function GuildPlayerTipWindow:onTouchTransfer()
	xyd.alert(xyd.AlertType.YES_NO, __("GUILD_TEXT60"), function (yes_no)
		if not yes_no then
			return
		end

		xyd.models.guild:transferGuildLeder(self.playerID)
	end)
end

function GuildPlayerTipWindow:onTouchRecall()
	xyd.models.guild:recallGuildLeder(self.playerID)
end

function GuildPlayerTipWindow:onTransfer()
	self:onClickCloseButton()
	xyd.showToast(__("GUILD_TEXT38"))
end

function GuildPlayerTipWindow:onAppoint()
	self:onClickCloseButton()
	xyd.showToast(__("GUILD_TEXT39"))
end

function GuildPlayerTipWindow:onRecall()
	self:onClickCloseButton()
	xyd.showToast(__("GUILD_TEXT40"))
end

function GuildPlayerTipWindow:onRemove()
	xyd.showToast(__("GUILD_TEXT41"))
	self:onClickCloseButton()
end

return GuildPlayerTipWindow
