local BaseWindow = import(".BaseWindow")
local GuildNameChangeWindow = class("GuildNameChangeWindow", BaseWindow)

function GuildNameChangeWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.cur_name = nil
	self.MAX_LEN = 24
	self.MIN_LEN = 4
end

function GuildNameChangeWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
end

function GuildNameChangeWindow:getUIComponent()
	local go = self.window_:NodeByName("e:Group").gameObject
	self.titleLabel = go:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = go:NodeByName("closeBtn").gameObject
	self.textInput = go:ComponentByName("textInput", typeof(UIInput))
	local confirmBtn = go:NodeByName("confirmBtn").gameObject
	self.confirmBtn = require("app.components.SummonButton").new(confirmBtn)
	self.nameLabel = go:ComponentByName("nameLabel", typeof(UILabel))
end

function GuildNameChangeWindow:initUIComponent()
	self.eventProxy_:addEventListener(xyd.event.GUILD_EDIT_NAME, function ()
		self:close()
		xyd.alert(xyd.AlertType.CONFIRM, __("GUILD_EDIT_NAME_SUCCESSFULLY"))
	end)

	self.textInput.defaultText = __("GUILD_TEXT62")
	self.textInput.defaultColor = Color.New2(3385711103.0)
	self.nameLabel.text = __("GUILD_TEXT22")
	self.titleLabel.text = __("GUILD_NAME_CHANGE_TITLE")
	local cost = xyd.tables.miscTable:split2Cost("modify_guild_name_cost", "value", "#")

	self.confirmBtn:setCostIcon(cost)
	self.confirmBtn:setLabel(__("CONFIRM"))
	xyd.setDarkenBtnBehavior(self.confirmBtn:getGameObject(), self, self.onConfirmClick)

	if xyd.Global.lang == "fr_fr" then
		self.window_:NodeByName("e:Group").gameObject:NodeByName("confirmBtn/itemIcon"):X(-63)
	end

	self:setCloseBtn(self.closeBtn)
end

function GuildNameChangeWindow:onConfirmClick()
	local cost = xyd.tables.miscTable:split2Cost("modify_guild_name_cost", "value", "#")

	if xyd.isItemAbsence(cost[1], cost[2]) then
		return
	end

	local name = self.textInput.value

	if self:isNameValid(name) then
		xyd.models.guild:guildEditName(name)
	end
end

function GuildNameChangeWindow:isNameValid(name)
	if not name or name == "" then
		xyd.showToast(__("GUILD_TEXT22"))

		return false
	end

	if string.find(name, " ") ~= nil then
		xyd.showToast(__("NAME_HAS_BLACK_WORD"))

		return false
	end

	local limit = xyd.tables.miscTable:split2Cost("guild_name_num_max", "value", "|")

	if xyd.getNameStringLength(name) < limit[1] then
		xyd.showToast(__("GUILD_TEXT30", 2, 3))

		return
	end

	if limit[2] < xyd.getNameStringLength(name) then
		xyd.showToast(__("GUILD_TEXT31", 6, 12))

		return false
	end

	if xyd.tables.filterWordTable:isInWords(name) then
		xyd.showToast(__("GUILD_TEXT29"))

		return false
	end

	if tonumber(name) then
		xyd.showToast(__("GUILD_TEXT32"))

		return false
	end

	return true
end

return GuildNameChangeWindow
