local BaseWindow = import(".BaseWindow")
local PersonEditNameWindow = class("PersonEditNameWindow", BaseWindow)

function PersonEditNameWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.isStory_ = false
	self.callback_ = nil
	self.backpack = xyd.models.backpack
	self.selfPlayer = xyd.models.selfPlayer

	if params then
		self.isStory_ = params.isStory
		self.callback_ = params.callback
	end
end

function PersonEditNameWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function PersonEditNameWindow:getUIComponent()
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

function PersonEditNameWindow:layout()
	self.labelTitle_.text = __("PERSON_EDIT_NAME")
	self.labelDesc_.text = __("PERSON_EDIT_TIPS1")

	if self.isStory_ then
		self.labelTitle_.text = __("PLOT_PERSON_EDIT_NAME")
		self.labelDesc_.text = __("PLOT_PERSON_EDIT_TIPS1")

		self.closeBtn:SetActive(false)
	end

	local cost = xyd.split(xyd.tables.miscTable:getVal("edit_name_cost"), "#", true)
	self.btnSureLabelCost_.text = cost[2]
	self.btnSureLabelCost_.color = Color.New2(4294967295.0)
	self.btnSureLabelCost_.effectColor = Color.New2(1012112383)

	if not self:checkEnough() then
		self.btnSureLabelCost_.color = Color.New2(3422556671.0)
		self.btnSureLabelCost_.effectColor = Color.New2(4294967295.0)
	end

	self.btnSureLabel.text = __("SURE")
	self.textInput_.value = ""
	self.editLabel.text = ""
	self.textInput_.defaultText = __("PERSON_EDIT_TIPS2")

	xyd.setTextInputAtt(self.textInput_)

	if xyd.models.selfPlayer:isChangeNameFree() then
		self.cost:SetActive(false)
		self.btnSureLabel:SetLocalPosition(0, 0, 0)
	end
end

function PersonEditNameWindow:checkEnough()
	if xyd.models.selfPlayer:isChangeNameFree() then
		return true
	end

	local cost = xyd.split(xyd.tables.miscTable:getVal("edit_name_cost"), "#", true)
	local crystal = self.backpack:getCrystal()

	if crystal < cost[2] then
		return false
	end

	return true
end

function PersonEditNameWindow:register()
	PersonEditNameWindow.super.register(self)

	UIEventListener.Get(self.btnSure_).onClick = function ()
		self:onEdit()
	end

	self.eventProxy_:addEventListener(xyd.event.EDIT_PLAYER_NAME, handler(self, self.onSuccess))
end

function PersonEditNameWindow:onSuccess(event)
	xyd.WindowManager.get():closeWindow(self.name_)
end

function PersonEditNameWindow:onEdit()
	if self:speceilGm() then
		return
	end

	if self:checkEnough() then
		if self:checkValid() then
			self.selfPlayer:changeName(self.textInput_.value)
		end
	else
		xyd.alert(xyd.AlertType.TIPS, __("PERSON_NO_CRYSTAL"))
	end
end

function PersonEditNameWindow:speceilGm()
	if not UNITY_EDITOR then
		return false
	end

	local strArr = xyd.split(self.textInput_.value, " = ")

	if #strArr == 2 and strArr[1] == "test_index" then
		xyd.db.misc:setValue({
			key = "test_index",
			value = strArr[2]
		})
		reportLog2("test_index: " .. strArr[2])

		return true
	end

	return false
end

function PersonEditNameWindow:checkValid()
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
	elseif length > 0 and xyd.tables.filterWordTable:isInWords(str) then
		flag = false
		tips = __("NAME_HAS_BLACK_WORD")
	end

	if tips ~= "" then
		xyd.alert(xyd.AlertType.TIPS, tips)
	end

	return flag
end

function PersonEditNameWindow:isFree()
	local playerID = xyd.Global.playerID or 1
	local name_ = "player" .. tostring(playerID % 1000000)
	local name2_ = "Senior" .. tostring(playerID % 1000000)

	if xyd.Global.playerName == name_ or xyd.Global.playerName == name2_ then
		return true
	end

	return false
end

function PersonEditNameWindow:willClose()
	BaseWindow.willClose(self)

	if self.callback_ then
		self:callback_()
	end
end

return PersonEditNameWindow
