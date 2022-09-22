local GuildNewWarFightInfoWindow = class("GuildNewWarFightInfoWindow", import(".BaseWindow"))
local ThemeItem = class("ThemeItem", import("app.common.ui.FlexibleWrapContentItem"))
local LuaFlexibleWrapContent = import("app.common.ui.FlexibleWrapContent")
local json = require("cjson")

function GuildNewWarFightInfoWindow:ctor(name, params)
	self.messageInfo = params.messageInfo
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_NEW_WAR)

	GuildNewWarFightInfoWindow.super.ctor(self, name, params)
end

function GuildNewWarFightInfoWindow:initWindow()
	self:getUIComponent()
	GuildNewWarFightInfoWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
	self.activityData:saveReadBattleMessageNum()
end

function GuildNewWarFightInfoWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.scroller = self.groupAction:NodeByName("scroller").gameObject
	self.scrollerUIScrollView = self.groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.scrollerContent = self.scroller:NodeByName("scrollerContent").gameObject
	self.drag = self.groupAction:NodeByName("drag").gameObject
	self.item = self.groupAction:NodeByName("item").gameObject

	if not self.wrapContent then
		self.wrapContent = LuaFlexibleWrapContent.new(self.scrollerUIScrollView.gameObject, ThemeItem, self.item, self.scrollerContent, self.scrollerUIScrollView, nil, self)
	end

	self.tipsNone = self.groupAction:NodeByName("tipsNone").gameObject
	self.labelNoneTips = self.tipsNone:ComponentByName("labelNoneTips", typeof(UILabel))
end

function GuildNewWarFightInfoWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

function GuildNewWarFightInfoWindow:layout()
	self.labelTitle.text = __("GUILD_NEW_WAR_TEXT82")
	self.labelNoneTips.text = __("GUILD_NEW_WAR_TEXT81")

	if self.messageInfo and self.messageInfo.msg and #self.messageInfo.msg > 0 then
		self.wrapContent:update()
		self.wrapContent:setDataNum(#self.messageInfo.msg)
		self.tipsNone:SetActive(false)
	else
		self.tipsNone:SetActive(true)
	end
end

function ThemeItem:ctor(go, parent, realIndex)
	self.parent = parent

	ThemeItem.super.ctor(self, go, parent)

	self.realIndex = realIndex
end

function ThemeItem:initUI()
	local go = self.go
	self.goUIWidget = self.go:GetComponent(typeof(UIWidget))
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.timeLabel = self.go:ComponentByName("timeLabel", typeof(UILabel))
	self.descLabel = self.go:ComponentByName("descLabel", typeof(UILabel))
end

function ThemeItem:refresh()
	self.data = self.parent.messageInfo.msg[-self.realIndex]

	if not self.data then
		self.go.gameObject:SetActive(false)

		return
	else
		self.go.gameObject:SetActive(true)
	end

	local content = self.data.content
	content = json.decode(content)
	local contentType = xyd.tables.guildNewWarMessageTable:getConnectType(self.data.e_msg_id)

	for i in pairs(content) do
		if contentType[i] and #contentType[i] > 0 then
			local table = nil

			if contentType[i][1] == "guild_new_war_base" then
				table = xyd.tables.guildNewWarBaseTable
			end

			local textId = table:getString(content[i], contentType[i][2])
			content[i] = xyd.tables.guildNewWarBaseTextTable:getDesc(textId)
		end
	end

	self.descLabel.text = xyd.tables.guildNewWarMessageTextTable:getDesc(self.data.e_msg_id, unpack(content))
	self.goUIWidget.height = 69 + self.descLabel.height
	self.bg.height = 69 + self.descLabel.height

	self:setLabelTime(self.timeLabel)
end

function ThemeItem:getHeight()
	return self.goUIWidget.height + 13
end

function ThemeItem:setLabelTime(labelTime)
	local timeNum = self.data.time
	local dateInfo = os.date("*t", timeNum)
	local hour = xyd.checkCondition(dateInfo.hour < 10, "0" .. tostring(dateInfo.hour), dateInfo.hour)
	local min = xyd.checkCondition(dateInfo.min < 10, "0" .. tostring(dateInfo.min), dateInfo.min)
	local month = xyd.checkCondition(dateInfo.month < 10, "0" .. tostring(dateInfo.month), dateInfo.month)
	local day = xyd.checkCondition(dateInfo.day < 10, "0" .. tostring(dateInfo.day), dateInfo.day)
	labelTime.text = "[ " .. tostring(hour) .. ":" .. tostring(min) .. " " .. tostring(month) .. "/" .. tostring(day) .. " ]"
end

return GuildNewWarFightInfoWindow
