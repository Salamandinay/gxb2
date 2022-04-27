local BaseWindow = import(".BaseWindow")
local SelectBattleNumWindow = class("SelectBattleNumWindow", BaseWindow)

function SelectBattleNumWindow:ctor(name, params)
	SelectBattleNumWindow.super.ctor(self, name, params)

	local abbr = xyd.db.misc:getValue("abbr_battle_num")

	if abbr and tonumber(abbr) ~= 0 then
		self.isAbbr = true
	else
		self.isAbbr = false
	end
end

function SelectBattleNumWindow:initWindow()
	SelectBattleNumWindow.super.initWindow(self)
	self:getUIComponent()
	self:initLayout()
	self:registerEvent()
end

function SelectBattleNumWindow:getUIComponent()
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

function SelectBattleNumWindow:initLayout()
	self.labelDesc1.text = __("CHOOSE_BATTLE_NUM_TEXT0")
	self.labelChoose1.text = __("CHOOSE_BATTLE_NUM_TEXT1")
	self.labelChoose2.text = __("CHOOSE_BATTLE_NUM_TEXT2")
	self.btnSendLabel_.text = __("SURE")

	self:setAbbr(self.isAbbr)
end

function SelectBattleNumWindow:registerEvent()
	SelectBattleNumWindow.super.register(self)

	UIEventListener.Get(self.groupChoose1).onClick = function ()
		self:setAbbr(false)
	end

	UIEventListener.Get(self.groupChoose2).onClick = function ()
		self:setAbbr(true)
	end

	UIEventListener.Get(self.btnSend_).onClick = function ()
		local value = 0

		if self.isAbbr then
			value = 1
		end

		xyd.db.misc:setValue({
			key = "abbr_battle_num",
			value = value
		})
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function SelectBattleNumWindow:setAbbr(flag)
	if flag then
		self.imgSelect1_:SetActive(false)
		self.imgSelect2_:SetActive(true)
	else
		self.imgSelect1_:SetActive(true)
		self.imgSelect2_:SetActive(false)
	end

	self.isAbbr = flag
end

return SelectBattleNumWindow
