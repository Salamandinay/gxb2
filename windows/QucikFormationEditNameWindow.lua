local BaseWindow = import(".BaseWindow")
local QucikFormationEditNameWindow = class("QucikFormationEditNameWindow", BaseWindow)

function QucikFormationEditNameWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.id = params.id
end

function QucikFormationEditNameWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function QucikFormationEditNameWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	self.closeBtn = content:NodeByName("closeBtn").gameObject
	self.labelTitle_ = content:ComponentByName("labelTitle_", typeof(UILabel))
	self.labelDesc_ = content:ComponentByName("labelDesc_", typeof(UILabel))
	local group = content:NodeByName("group").gameObject
	self.textInput_ = group:ComponentByName("input", typeof(UIInput))
	self.editLabel = group:ComponentByName("editLabel", typeof(UILabel))
	self.btnSure_ = content:NodeByName("btnSure_").gameObject
	self.btnSureLabel = self.btnSure_:ComponentByName("button_label", typeof(UILabel))
	self.cost = self.btnSure_:NodeByName("cost").gameObject
	self.btnSureLabelCost_ = self.cost:ComponentByName("labelCost", typeof(UILabel))
end

function QucikFormationEditNameWindow:layout()
	self.labelTitle_.text = __("QUICK_FORMATION_TEXT19")
	self.labelDesc_.text = __("QUICK_FORMATION_TEXT20")
	self.btnSureLabel.text = __("SURE")
	self.textInput_.value = ""
	self.editLabel.text = ""
	self.textInput_.defaultText = __("QUICK_FORMATION_TEXT14")

	xyd.setTextInputAtt(self.textInput_)
	self.cost:SetActive(false)
	self.btnSureLabel:SetLocalPosition(0, 0, 0)
end

function QucikFormationEditNameWindow:register()
	QucikFormationEditNameWindow.super.register(self)

	UIEventListener.Get(self.btnSure_).onClick = function ()
		self:onEdit()
	end

	self.eventProxy_:addEventListener(xyd.event.SET_QUICK_TEAM_NAME, handler(self, self.onSuccess))
end

function QucikFormationEditNameWindow:onSuccess(event)
	xyd.models.quickFormation:setTeamName(self.id, xyd.escapesLuaString(self.textInput_.value))

	local quickFormationWd = xyd.WindowManager.get():getWindow("quick_formation_window")

	if quickFormationWd then
		quickFormationWd:updateTeamName()
	end

	self:close()
end

function QucikFormationEditNameWindow:onEdit()
	if self:checkValid() then
		if xyd.models.quickFormation:isTeamPartnersHas(self.id) then
			local msg = messages_pb:set_quick_team_name_req()
			msg.id = self.id
			msg.name = xyd.escapesLuaString(self.textInput_.value)

			xyd.Backend.get():request(xyd.mid.SET_QUICK_TEAM_NAME, msg)
		else
			self:onSuccess()
		end
	end
end

function QucikFormationEditNameWindow:checkValid()
	local str = self.textInput_.value
	local length = xyd.getNameStringLength(str)
	local limit = {
		1,
		6
	}
	local flag = true
	local tips = ""

	if length < limit[1] then
		tips = __("PERSON_NAME_SHORT")
		flag = false
	elseif limit[2] < length then
		tips = __("PERSON_NAME_LONG")
		flag = false
	elseif length > 0 and xyd.tables.filterWordTable:isInWords(str) then
		flag = false
		tips = __("NAME_HAS_BLACK_WORD")
	end

	if tips ~= "" then
		xyd.alert(xyd.AlertType.TIPS, tips)
	end

	return flag
end

function QucikFormationEditNameWindow:willClose()
	BaseWindow.willClose(self)
end

return QucikFormationEditNameWindow
