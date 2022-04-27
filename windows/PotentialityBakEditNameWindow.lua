local PotentialityBakEditNameWindow = class("PotentialityBakEditNameWindow", import(".HouseEditNameWindow"))

function PotentialityBakEditNameWindow:ctor(name, params)
	PotentialityBakEditNameWindow.super.ctor(self, name, params)
end

function PotentialityBakEditNameWindow:layout()
	self.labelTitle_.text = __("PERSON_EDIT_NAME")
	self.textInput_.defaultText = __("POTENTIAL_PLAN_NAME_LIMIT")
	self.btnSure_:ComponentByName("button_label", typeof(UILabel)).text = __("SURE_2")
	self.labelDesc_.text = __("PERSON_EDIT_TIPS1")
end

function PotentialityBakEditNameWindow:onSureTouch()
	if not self:checkValid() then
		return
	end

	local name_ = self.textInput_.value

	if self.params_.callback then
		self.params_.callback(name_)
	end

	xyd.WindowManager.get():closeWindow(self.name_, function ()
		xyd.alertTips(__("PERSON_NAME_SUCCEED"))
	end)
end

function PotentialityBakEditNameWindow:checkValid()
	local str = self.textInput_.value
	local length = xyd.getNameStringLength(str)
	local limit = xyd.split(xyd.tables.miscTable:getVal("potential_name_length_limit"), "|", true)
	local flag = true
	local tips = ""

	if length < limit[1] then
		tips = __("INPUT_NULL")
		flag = false
	elseif limit[2] < length then
		tips = __("PERSON_NAME_LONG")
		flag = false
	elseif xyd.isTextInValid(str) then
		flag = false
		tips = __("NAME_HAS_BLACK_WORD")
	end

	if tips ~= "" then
		xyd.alert(xyd.AlertType.TIPS, tips)
	end

	return flag
end

return PotentialityBakEditNameWindow
