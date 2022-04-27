local BaseWindow = import(".BaseWindow")
local GuildLogWindow = class("GuildLogWindow", BaseWindow)
local GuildLogWindowItem = class("GuildLogWindowItem")
local GuildLogItemDetail = class("GuildLogItemDetail")

function GuildLogWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.MAX_SZ = 10
end

function GuildLogWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:setCloseBtn(self.closeBtn)
end

function GuildLogWindow:getUIComponent()
	self.guild_log_item = self.window_:NodeByName("guild_log_item").gameObject
	local go = self.window_:NodeByName("e:Group").gameObject
	self.titleLabel = go:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = go:NodeByName("closeBtn").gameObject
	self.itemGroup = go:NodeByName("e:Scroller/itemGroup").gameObject

	self.guild_log_item:SetActive(false)
end

function GuildLogWindow:initUIComponent()
	self.titleLabel.text = __("GUILD_LOG_TITLE")
	local logs = xyd.models.guild.logs
	local list = {}

	if #logs > 0 then
		local data = logs[1]

		xyd.models.guild:updateLogRedMark(data.time)
	else
		xyd.models.guild:updateLogRedMark(nil)
	end

	table.sort(logs, function (a, b)
		return tonumber(b.time) < tonumber(a.time)
	end)

	local tList = {}

	for i = 1, #logs do
		local data = logs[i]
		local t = xyd.getDisplayTime(data.time, xyd.TimestampStrType.DATE)

		if not list[t] then
			list[t] = {}
		end

		if xyd.arrayIndexOf(tList, t) < 0 then
			table.insert(tList, t)
		end

		table.insert(list[t], data)
	end

	local sum = 0

	for _, i in ipairs(tList) do
		if self.MAX_SZ < sum then
			break
		end

		local item = nil

		if self.MAX_SZ < sum + #list[i] then
			local new_list = {}

			for j = 1, self.MAX_SZ - sum do
				table.insert(new_list, list[i][j])
			end

			local go = NGUITools.AddChild(self.itemGroup, self.guild_log_item)
			item = GuildLogWindowItem.new(go, new_list)
		else
			local go = NGUITools.AddChild(self.itemGroup, self.guild_log_item)
			item = GuildLogWindowItem.new(go, list[i])
		end

		self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
	end
end

function GuildLogWindowItem:ctor(go, params)
	self.data = params
	self.go = go

	self:getUIComponent()
	self:initUIComponent()
end

function GuildLogWindowItem:getUIComponent()
	local go = self.go
	self.dateLabel = go:ComponentByName("dateLabel", typeof(UILabel))
	self.textGroup = go:NodeByName("textGroup").gameObject
	self.text_item = go:NodeByName("text_item").gameObject
end

function GuildLogWindowItem:initUIComponent()
	self.text_item:SetActive(false)

	local t = xyd.getDisplayTime(self.data[1].time, xyd.TimestampStrType.DATE)
	self.dateLabel.text = t
	local height = 50

	for i = 1, #self.data do
		local cur_data = self.data[i]
		local time = cur_data.time
		local player_name = cur_data.player_name
		local operate_id = cur_data.operate_id
		local player_name2 = cur_data.player_name2
		local params = {
			time = xyd.getDisplayTime(time, xyd.TimestampStrType.TIME_NO_SECOND),
			content = self:setOperate(player_name, operate_id, player_name2)
		}
		local go = NGUITools.AddChild(self.textGroup, self.text_item)
		local text_item = GuildLogItemDetail.new(go, params)
		height = height + text_item.go:GetComponent(typeof(UIWidget)).height
	end

	self.go:GetComponent(typeof(UIWidget)).height = height + 11 * (#self.data - 1)

	self.textGroup:GetComponent(typeof(UILayout)):Reposition()
end

function GuildLogWindowItem:setOperate(player_name, operate_id, player_name2)
	if operate_id == 6 then
		return xyd.tables.guildLogTextTable:translate(operate_id, player_name, player_name2)
	else
		return xyd.tables.guildLogTextTable:translate(operate_id, player_name)
	end
end

function GuildLogItemDetail:ctor(go, params)
	self.go = go
	self.time = params.time
	self.content = params.content

	self:getUIComponent()
	self:initUIComponent()
end

function GuildLogItemDetail:getUIComponent()
	local go = self.go
	self.timeLabel = go:ComponentByName("timeLabel", typeof(UILabel))
	self.operateLabel = go:ComponentByName("operateLabel", typeof(UILabel))
end

function GuildLogItemDetail:initUIComponent()
	self.timeLabel.text = self.time
	self.operateLabel.text = self.content
	self.go:GetComponent(typeof(UIWidget)).height = self.operateLabel.height
end

return GuildLogWindow
