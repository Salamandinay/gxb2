local HouseEditNameWindow = class("HouseEditNameWindow", import(".BaseWindow"))

function HouseEditNameWindow:ctor(name, params)
	HouseEditNameWindow.super.ctor(self, name, params)
end

function HouseEditNameWindow:initWindow()
	HouseEditNameWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function HouseEditNameWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.labelTitle_ = winTrans:ComponentByName("groupAction/labelTitle_", typeof(UILabel))
	self.labelDesc_ = winTrans:ComponentByName("groupAction/labelDesc_", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("groupAction/closeBtn").gameObject
	self.btnSure_ = winTrans:NodeByName("groupAction/btnSure_").gameObject
	self.textInput_ = winTrans:ComponentByName("groupAction/e:Group/textInput_", typeof(UIInput))
end

function HouseEditNameWindow:layout()
	self.labelTitle_.text = __("PERSON_EDIT_NAME")
	local oldName = xyd.models.house:getHouseName()
	self.textInput_.defaultText = __("PERSON_EDIT_TIPS2")
	self.textInput_.value = oldName or ""
	self.btnSure_:ComponentByName("button_label", typeof(UILabel)).text = __("SURE_2")
	self.labelDesc_.text = __("PERSON_EDIT_TIPS1")
end

function HouseEditNameWindow:registerEvent()
	self:register()

	UIEventListener.Get(self.btnSure_).onClick = handler(self, self.onSureTouch)
end

function HouseEditNameWindow:onSureTouch()
	if not self:checkValid() then
		return
	end

	local name_ = self.textInput_.value

	xyd.models.house:reqSaveHouseName(string.trim(name_))
	xyd.WindowManager.get():closeWindow(self.name_)
end

function HouseEditNameWindow:checkValid()
	local str = self.textInput_.value
	local length = xyd.getNameStringLength(str)
	local limit = xyd.split(xyd.tables.miscTable:getVal("edit_name_length_limit"), "|", true)
	local flag = true
	local tips = ""

	if length < limit[1] then
		tips = __("PERSON_NAME_SHORT")
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

return HouseEditNameWindow
