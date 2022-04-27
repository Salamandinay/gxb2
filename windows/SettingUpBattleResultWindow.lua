local BaseWindow = import(".BaseWindow")
local SettingUpBattleResultWindow = class("SettingUpBattleResultWindow", BaseWindow)

function SettingUpBattleResultWindow:ctor(name, params)
	SettingUpBattleResultWindow.super.ctor(self, name, params)

	local abbr = xyd.db.misc:getValue("abbr_setting_up_battle_result")

	if abbr and tonumber(abbr) ~= 0 or not abbr then
		self.isAbbr = true
	else
		self.isAbbr = false
	end
end

function SettingUpBattleResultWindow:initWindow()
	SettingUpBattleResultWindow.super.initWindow(self)
	self:getUIComponent()
	self:initLayout()
	self:registerEvent()
end

function SettingUpBattleResultWindow:getUIComponent()
	local win = self.window_:NodeByName("groupAction").gameObject
	self.labelWinTitle = win:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = win:NodeByName("closeBtn").gameObject
	self.labelDesc1 = win:ComponentByName("labelDesc1", typeof(UILabel))
	self.btnSend_ = win:NodeByName("btnSend_").gameObject
	self.btnSendLabel_ = self.btnSend_:ComponentByName("button_label", typeof(UILabel))

	for i = 1, 2 do
		self["labelChoose" .. i] = win:ComponentByName("labelChoose" .. i, typeof(UILabel))
		local group = win:NodeByName("groupChoose" .. i).gameObject
		self["imgSelect" .. i .. "_"] = group:NodeByName("imgSelect" .. i .. "_").gameObject
		self["groupChoose" .. i] = group
	end
end

function SettingUpBattleResultWindow:initLayout()
	self.labelDesc1.text = __("SETTING_UP_BATTLE_RESULT_DEC")
	self.labelChoose1.text = __("SETTING_UP_BATTLE_RESULT_OPTION_1")
	self.labelChoose2.text = __("SETTING_UP_BATTLE_RESULT_OPTION_2")
	self.btnSendLabel_.text = __("SURE")

	self:setAbbr(self.isAbbr)
end

function SettingUpBattleResultWindow:registerEvent()
	SettingUpBattleResultWindow.super.register(self)

	UIEventListener.Get(self.groupChoose1).onClick = function ()
		self:setAbbr(true)
	end

	UIEventListener.Get(self.groupChoose2).onClick = function ()
		self:setAbbr(false)
	end

	UIEventListener.Get(self.btnSend_).onClick = function ()
		local value = 0

		if self.isAbbr then
			value = 1
		end

		xyd.db.misc:setValue({
			key = "abbr_setting_up_battle_result",
			value = value
		})
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function SettingUpBattleResultWindow:setAbbr(flag)
	if flag then
		self.imgSelect1_:SetActive(true)
		self.imgSelect2_:SetActive(false)
	else
		self.imgSelect1_:SetActive(false)
		self.imgSelect2_:SetActive(true)
	end

	self.isAbbr = flag
end

return SettingUpBattleResultWindow
