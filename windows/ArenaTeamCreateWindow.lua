local BaseWindow = import(".BaseWindow")
local ArenaTeamCreateWindow = class("ArenaTeamCreateWindow", BaseWindow)
local MAX_COMBAT_NUM = 1999999

function ArenaTeamCreateWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.teamInfos_ = {}
end

function ArenaTeamCreateWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ArenaTeamCreateWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainGroup = winTrans:NodeByName("mainGroup").gameObject
	self.labelTitle = mainGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = mainGroup:NodeByName("closeBtn").gameObject
	local labelTipsGroup1 = mainGroup:NodeByName("labelTipsGroup1").gameObject
	self.labelTips1 = labelTipsGroup1:ComponentByName("labelTips1", typeof(UILabel))
	local editGroup = mainGroup:NodeByName("editGroup").gameObject
	self.edit = editGroup:ComponentByName("textEditName_", typeof(UIInput))
	self.editLabel = editGroup:ComponentByName("textEditName_/editName", typeof(UILabel))
	self.labelTipsGroup2 = mainGroup:NodeByName("labelTipsGroup2").gameObject
	self.labelTips2 = self.labelTipsGroup2:ComponentByName("labelTips2", typeof(UILabel))
	self.textEditForce_ = mainGroup:ComponentByName("textEditForce_/Label", typeof(UILabel))
	self.textEditForce_obj = mainGroup:NodeByName("textEditForce_").gameObject
	self.btnCreate_ = mainGroup:NodeByName("btnCreate_").gameObject
	self.btnCreate_LabelDisplay = self.btnCreate_:ComponentByName("button_label", typeof(UILabel))
	self.numberKeyBoard = winTrans:NodeByName("number_keyboard").gameObject

	for i = 0, 9 do
		self["btn" .. tostring(i) .. "_"] = self.numberKeyBoard:NodeByName("btn" .. tostring(i) .. "_").gameObject
	end

	self.btnOK_ = self.numberKeyBoard:NodeByName("btnOK_").gameObject
	self.btnC_ = self.numberKeyBoard:NodeByName("btnC_").gameObject
	self.displayBg1 = self.numberKeyBoard:NodeByName("displayBg1").gameObject

	self.numberKeyBoard:SetActive(false)
end

function ArenaTeamCreateWindow:layout()
	self.btnCreate_LabelDisplay.text = __("ARENA_TEAM_CREATE")
	self.textEditForce_.text = "1"
	self.isInit = true
	self.editLabel.text = __("ARENA_TEAM_INPUT_NAME")
	self.labelTitle.text = __("ARENA_TEAM_CREATE_WINDOW")
	self.labelTips1.text = __("ARENA_TEAM_NAME")
	self.labelTips2.text = __("ARENA_TEAM_NEED_FORCE_2")
end

function ArenaTeamCreateWindow:registerEvent()
	ArenaTeamCreateWindow.super.register(self)
	xyd.setDarkenBtnBehavior(self.btnCreate_, self, self.onCreateTouch)
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_CREATE_TEAM, handler(self, self.onCreateTeam))

	for i = 0, 9 do
		local btn = self["btn" .. tostring(i) .. "_"]

		xyd.setDarkenBtnBehavior(btn, self, function ()
			self:onNum(i)
		end)
	end

	xyd.setDarkenBtnBehavior(self.btnOK_, self, function ()
		self:onOk()
	end)
	xyd.setDarkenBtnBehavior(self.btnC_, self, function ()
		self:onC()
	end)

	UIEventListener.Get(self.displayBg1).onClick = handler(self, self.onOk)
	UIEventListener.Get(self.textEditForce_obj).onClick = handler(self, self.showKeyboard)
end

function ArenaTeamCreateWindow:showKeyboard()
	self.numberKeyBoard:SetActive(true)
end

function ArenaTeamCreateWindow:onC()
	self.textEditForce_.text = "1"
	self.isInit = true
end

function ArenaTeamCreateWindow:onOk()
	self.numberKeyBoard:SetActive(false)
end

function ArenaTeamCreateWindow:onNum(num)
	if self.isInit then
		self.isInit = false
		self.textEditForce_.text = tostring(num)

		return
	end

	if #self.textEditForce_.text <= 0 then
		self.textEditForce_.text = tostring(num)
	else
		local cur_num = tonumber(self.textEditForce_.text)

		if cur_num == 0 then
			self.textEditForce_.text = tostring(num)
		else
			local new_num = tonumber(self.textEditForce_.text .. num)

			if MAX_COMBAT_NUM <= new_num then
				self.textEditForce_.text = MAX_COMBAT_NUM
			else
				self.textEditForce_.text = self.textEditForce_.text .. tostring(num)
			end
		end
	end
end

function ArenaTeamCreateWindow:onEditChange()
end

function ArenaTeamCreateWindow:onCreateTouch()
	local teamName = self.edit.value:trim()
	local force = tonumber(self.textEditForce_.text)

	if self:checkInput(teamName, force) then
		xyd.models.arenaTeam:createTeam(teamName, force)
	end
end

function ArenaTeamCreateWindow:checkInput(teamName, force)
	local len = xyd.getNameStringLength(teamName)
	local tips = ""
	local flag = true

	if len < 4 or len > 12 then
		tips = __("ARENA_TEAM_NAME_LIMIT")
		flag = false
	elseif force < 1 or MAX_COMBAT_NUM < force then
		tips = __("ARENA_TEAM_FORCE_LIMIT")
		flag = false
	elseif xyd.tables.filterWordTable:isInWords(teamName) then
		tips = __("INVALID_CHARACTER")
		flag = false
	end

	if tips ~= "" then
		xyd.alert(xyd.AlertType.TIPS, tips)
	end

	return flag
end

function ArenaTeamCreateWindow:onCreateTeam()
	xyd.WindowManager.get():closeWindow(self.name_)
	xyd.WindowManager.get():closeWindow("arena_team_hall_window")
	xyd.WindowManager.get():closeWindow("arena_team_my_team_window")
end

return ArenaTeamCreateWindow
