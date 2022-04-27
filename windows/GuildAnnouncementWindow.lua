local BaseWindow = import(".BaseWindow")
local GuildAnnouncementWindow = class("GuildAnnouncementWindow", BaseWindow)

function GuildAnnouncementWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.params = params
	self.MAX_LEN = 200
	self.inputTouch = false
end

function GuildAnnouncementWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
	self:waitForTime(0.2, function ()
		local win = xyd.WindowManager.get():getWindow("guild_setting_window")

		if win then
			win:fixInput()
		end
	end)
end

function GuildAnnouncementWindow:getUIComponent()
	local go = self.window_:NodeByName("groupMain").gameObject
	self.closeBtn = go:NodeByName("closeBtn").gameObject
	self.titleLabel = go:ComponentByName("titleLabel", typeof(UILabel))
	self.editScroll = go:ComponentByName("inputScroll", typeof(UIScrollView))
	self.editableText = go:ComponentByName("inputScroll/editableText", typeof(UIInput))
	self.editLabel = go:ComponentByName("inputScroll/editableText", typeof(UILabel))
	self.confirmBtn = go:NodeByName("confirmBtn").gameObject
	self.confirmBtn_label = self.confirmBtn:ComponentByName("button_label", typeof(UILabel))
end

function GuildAnnouncementWindow:initUIComponent()
	self.titleLabel.text = __("GUILD_ANNOUNCEMENT_SETTING_UP_TITLE")
	self.confirmBtn_label.text = __("CONFIRM")
	local text = xyd.models.guild.base_info.announcement
	self.editableText.defaultText = __("GUILD_TEXT23")
	self.editableText.defaultColor = Color.New2(3385711103.0)
	self.editableText.value = text
end

function GuildAnnouncementWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GUILD_EDIT_ANNOUNCEMENT, self.onEditAnnouncement, self)
	xyd.setDarkenBtnBehavior(self.confirmBtn, self, self.onConfirmClick)
	self:setCloseBtn(self.closeBtn)
	XYDUtils.AddEventDelegate(self.editableText.onChange, handler(self, self.onChange))
end

function GuildAnnouncementWindow:onChange()
	local pos = self.editableText.caretVerts
	local pos_y = math.abs(tonumber(pos.y))
	local lineNum = math.floor(pos_y / self.editLabel.fontSize)

	if lineNum ~= self.lineNum and lineNum > 8 then
		pos = Vector3(0, -25 + (lineNum - 7) * self.editLabel.fontSize, 0)

		self:waitForFrame(2, function ()
			SpringPanel.Begin(self.editScroll.gameObject, pos, 8)
		end)
	end

	self.lineNum = lineNum
end

function GuildAnnouncementWindow:onConfirmClick()
	local text = self.editableText.value or ""

	if xyd.tables.filterWordTable:isInWords(text) then
		xyd.showToast(__("INVALID_CHARACTER"))
	end

	xyd.models.guild:guildEditAnnouncement(text)
end

function GuildAnnouncementWindow:onEditAnnouncement()
	xyd.showToast(__("GUILD_ANNOUNCEMENT_SETTING_UP_SUCCESSFULLY"))
	xyd.WindowManager:get():closeWindow(self.name_)
end

function GuildAnnouncementWindow:changeWndY(flag)
	if xyd.Global.osType_ ~= "android" or tonumber(xyd.Global.appV_) < 2300010 or tonumber(xyd.Global.appV_) >= 2300022 then
		return
	end

	if flag then
		self.inputTouch = true
	else
		self.inputTouch = false
	end

	if self.inputTouch then
		self.groupMain.y = 360
	else
		self.groupMain.y = 0
	end
end

return GuildAnnouncementWindow
