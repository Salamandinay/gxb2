local BaseWindow = import(".BaseWindow")
local SettingUpFpsWindow = class("SettingUpFpsWindow", BaseWindow)
local FTAME_SELECT = {
	FPS_OTHER = -1,
	FPS60 = 60,
	FPS30 = 30
}

function SettingUpFpsWindow:ctor(name, params)
	SettingUpFpsWindow.super.ctor(self, name, params)

	local abbr = UnityEngine.PlayerPrefs.GetInt("__GAME_FRAME_RATE__", FTAME_SELECT.FPS30)

	if abbr == nil then
		self.isAbbr = FTAME_SELECT.FPS30
	elseif tonumber(abbr) == FTAME_SELECT.FPS30 then
		self.isAbbr = FTAME_SELECT.FPS30
	elseif tonumber(abbr) == FTAME_SELECT.FPS60 then
		self.isAbbr = FTAME_SELECT.FPS60
	else
		self.isAbbr = FTAME_SELECT.FPS_OTHER
	end
end

function SettingUpFpsWindow:initWindow()
	SettingUpFpsWindow.super.initWindow(self)
	self:getUIComponent()
	self:initLayout()
	self:registerEvent()
end

function SettingUpFpsWindow:getUIComponent()
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

function SettingUpFpsWindow:addTitle()
	self.labelWinTitle.text = __("SETTING_UP_FPS_TITLE")
end

function SettingUpFpsWindow:initLayout()
	self.labelDesc1.text = __("SETTING_UP_FPS_TEXT01")
	self.labelChoose1.text = __("SETTING_UP_FPS_30Hz")
	self.labelChoose2.text = __("SETTING_UP_FPS_60Hz")
	self.btnSendLabel_.text = __("SURE")

	self:setAbbr(self.isAbbr)
end

function SettingUpFpsWindow:registerEvent()
	SettingUpFpsWindow.super.register(self)

	UIEventListener.Get(self.groupChoose1).onClick = function ()
		self:setAbbr(FTAME_SELECT.FPS30)
	end

	UIEventListener.Get(self.groupChoose2).onClick = function ()
		self:setAbbr(FTAME_SELECT.FPS60)
	end

	UIEventListener.Get(self.btnSend_).onClick = function ()
		UnityEngine.PlayerPrefs.SetInt("__GAME_FRAME_RATE__", self.isAbbr)
		xyd.updateFrameRate(self.isAbbr)
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function SettingUpFpsWindow:setAbbr(flag)
	if flag == FTAME_SELECT.FPS30 then
		self.imgSelect1_:SetActive(true)
		self.imgSelect2_:SetActive(false)
	elseif flag == FTAME_SELECT.FPS60 then
		self.imgSelect1_:SetActive(false)
		self.imgSelect2_:SetActive(true)
	else
		self.imgSelect1_:SetActive(false)
		self.imgSelect2_:SetActive(false)
	end

	self.isAbbr = flag
end

return SettingUpFpsWindow
