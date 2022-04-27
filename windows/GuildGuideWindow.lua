local BaseWindow = import("app.windows.BaseWindow")
local GuildGuideWindow = class("GuildGuideWindow", BaseWindow)

function GuildGuideWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.index = 0
end

function GuildGuideWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getComponents()
	self:setText()
	self:regisetr()
	self:showDialog()
end

function GuildGuideWindow:getComponents()
	local winTrans = self.window_.transform
	self.touchField = winTrans:NodeByName("touchField").gameObject
	self.dialog1 = winTrans:NodeByName("groupDialog_1").gameObject
	self.dialogText1 = self.dialog1:ComponentByName("groupDialog1/labelDesc1", typeof(UILabel))
	self.dialog2 = winTrans:NodeByName("groupDialog_2").gameObject
	self.dialogText2 = self.dialog2:ComponentByName("groupDialog1/labelDesc1", typeof(UILabel))

	for i = 1, 6 do
		self["node" .. i] = winTrans:NodeByName("node" .. i).gameObject
	end
end

function GuildGuideWindow:setText()
	self["node" .. 1]:ComponentByName("labelName", typeof(UILabel)).text = __("GUILD_TEXT50")
	self["node" .. 2]:ComponentByName("labelName", typeof(UILabel)).text = __("GUILD_TEXT54")
	self["node" .. 3]:ComponentByName("labelName", typeof(UILabel)).text = __("GUILD_TEXT51")
	self["node" .. 4]:ComponentByName("labelName", typeof(UILabel)).text = __("GUILD_TEXT55")
	self["node" .. 5]:ComponentByName("labelName", typeof(UILabel)).text = __("GUILD_TEXT53")
	self["node" .. 6]:ComponentByName("labelName", typeof(UILabel)).text = __("GUILD_TEXT52")
end

function GuildGuideWindow:regisetr()
	UIEventListener.Get(self.touchField).onClick = handler(self, self.showDialog)
end

function GuildGuideWindow:showDialog()
	if self.index >= 6 then
		xyd.WindowManager.get():closeWindow(self.window_.name)

		return
	end

	self.index = self.index + 1
	local func = {
		function ()
			for i = 1, 6 do
				self["node" .. i]:SetActive(false)
			end

			self["node" .. 1]:SetActive(true)

			self.dialogText1.text = xyd.tables.guildGuideTextTable:getDesc(1)

			self.dialog1:SetLocalPosition(-143, 420, 0)
			self.dialog1:SetActive(true)
			self.dialog2:SetActive(false)
		end,
		function ()
			for i = 1, 6 do
				self["node" .. i]:SetActive(false)
			end

			self["node" .. 2]:SetActive(true)

			self.dialogText2.text = xyd.tables.guildGuideTextTable:getDesc(2)

			self.dialog2:SetLocalPosition(-143, 267, 0)
			self.dialog2:SetActive(true)
			self.dialog1:SetActive(false)
		end,
		function ()
			for i = 1, 6 do
				self["node" .. i]:SetActive(false)
			end

			self["node" .. 3]:SetActive(true)

			self.dialogText1.text = xyd.tables.guildGuideTextTable:getDesc(3)

			self.dialog1:SetLocalPosition(117, 267, 0)
			self.dialog1:SetActive(true)
			self.dialog2:SetActive(false)
		end,
		function ()
			for i = 1, 6 do
				self["node" .. i]:SetActive(false)
			end

			self["node" .. 4]:SetActive(true)

			self.dialogText2.text = xyd.tables.guildGuideTextTable:getDesc(4)

			self.dialog2:SetLocalPosition(-75, 70, 0)
			self.dialog2:SetActive(true)
			self.dialog1:SetActive(false)
		end,
		function ()
			for i = 1, 6 do
				self["node" .. i]:SetActive(false)
			end

			self["node" .. 5]:SetActive(true)

			self.dialogText1.text = xyd.tables.guildGuideTextTable:getDesc(5)

			self.dialog1:SetLocalPosition(126, -40, 0)
			self.dialog1:SetActive(true)
			self.dialog2:SetActive(false)
		end,
		function ()
			for i = 1, 6 do
				self["node" .. i]:SetActive(false)
			end

			self["node" .. 6]:SetActive(true)

			self.dialogText2.text = xyd.tables.guildGuideTextTable:getDesc(6)

			self.dialog2:SetLocalPosition(-137, -40, 0)
			self.dialog2:SetActive(true)
			self.dialog1:SetActive(false)
		end
	}

	func[self.index]()
end

return GuildGuideWindow
