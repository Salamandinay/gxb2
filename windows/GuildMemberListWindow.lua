local BaseWindow = import(".BaseWindow")
local GuildMemberListWindow = class("GuildMemberListWindow", BaseWindow)
local GuildMemberItem = require("app.windows.GuildWindow").GuildMemberItem

function GuildMemberListWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.items = {}
	self.sortType = 1
	self.btnNum = 3
	self.sortStation = false
end

function GuildMemberListWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function GuildMemberListWindow:getUIComponent()
	local go = self.window_:NodeByName("e:Group").gameObject
	self.labelWinTitle = go:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = go:NodeByName("closeBtn").gameObject
	self.groupItems = go:NodeByName("e:Scroller/groupItems").gameObject
end

function GuildMemberListWindow:initUIComponent()
	self:updateLayout()
end

function GuildMemberListWindow:updateLayout()
	local members = xyd.models.guild.members

	local function sort_(a, b)
		local result = nil

		if tonumber(a.job) == tonumber(b.job) then
			result = tonumber(b.last_time) < tonumber(a.last_time)
		else
			result = tonumber(b.job) < tonumber(a.job)
		end

		return result
	end

	table.sort(members, sort_)

	for i = 1, #members do
		local data = members[i]
		local item = GuildMemberItem.new(self.groupItems, data, function ()
			if data.player_id == xyd.models.selfPlayer:getPlayerID() then
				return
			end

			xyd.WindowManager.get():openWindow("guild_player_tip_window", {
				player_id = data.player_id,
				data = data
			})
		end)
		self.items[data.player_id] = item
	end

	self.groupItems:GetComponent(typeof(UILayout)):Reposition()
end

function GuildMemberListWindow:registerEvent()
	self:setCloseBtn(self.closeBtn)
	self.eventProxy_:addEventListener(xyd.event.GUILD_GET_INFO, self.onSort, self)
end

function GuildMemberListWindow:onSort()
	NGUITools.DestroyChildren(self.groupItems.transform)
	self:updateLayout()
end

return GuildMemberListWindow
