local DressNewSuitWindow = class("DressNewSuitWindow", import(".BaseWindow"))

function DressNewSuitWindow:ctor(name, params)
	DressNewSuitWindow.super.ctor(self, name, params)

	self.index = params.index
	self.styles = params.styles
end

function DressNewSuitWindow:initWindow()
	DressNewSuitWindow.super.initWindow()
	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function DressNewSuitWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.labelTitle_ = winTrans:ComponentByName("groupAction/labelTitle_", typeof(UILabel))
	self.personCon = winTrans:NodeByName("groupAction/personCon").gameObject
	self.closeBtn = winTrans:NodeByName("groupAction/closeBtn").gameObject
	self.btnSure_ = winTrans:NodeByName("groupAction/btnSure_").gameObject
	self.textInput_ = winTrans:ComponentByName("groupAction/e:Group/textInput_", typeof(UIInput))
	self.textInput_UILabel = winTrans:ComponentByName("groupAction/e:Group/textInput_/textInputLabel_", typeof(UILabel))
	self.showLabel = winTrans:ComponentByName("groupAction/e:Group/showLabel", typeof(UILabel))

	self.showLabel.gameObject:SetActive(false)
end

function DressNewSuitWindow:layout()
	self.labelTitle_.text = __("HOUSE_TEXT_16")
	self.textInput_UILabel.text = __("PERSON_EDIT_TIPS2")

	if self.params_.old_name and self.params_.old_name ~= "" then
		self.textInput_.value = self.params_.old_name
		self.enter_before = self.textInput_.value
		self.isFirstOpenText = true
	else
		self.textInput_.value = ""
	end

	self.btnSure_:ComponentByName("button_label", typeof(UILabel)).text = __("SURE_2")
	self.normalModel_ = import("app.components.SenpaiModel").new(self.personCon)

	self.normalModel_:setModelInfo({
		isNewClipShader = false,
		scale = 0.8,
		ids = self.styles
	})
end

function DressNewSuitWindow:registerEvent()
	self:register()

	UIEventListener.Get(self.btnSure_).onClick = handler(self, self.onSureTouch)
	local limit = xyd.split(xyd.tables.miscTable:getVal("edit_name_length_limit"), "|", true)

	xyd.addTextInput(self.textInput_UILabel, {
		check_marks = true,
		type = xyd.TextInputArea.InputSingleLine,
		getText = function ()
			if not self.isFirstOpenText then
				self.isFirstOpenText = true

				return ""
			end

			return self.textInput_UILabel.text
		end,
		callback = function ()
			if self.textInput_UILabel.text == "" then
				self.isFirstOpenText = false
				self.textInput_UILabel.text = __("PERSON_EDIT_TIPS2")
			end
		end,
		max_length = limit[2],
		max_tips = __("PERSON_NAME_LONG"),
		check_length_function = xyd.getNameStringLength
	})

	self.textInput_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
end

function DressNewSuitWindow:onChange()
	if not self.enter_before then
		self.enter_before = ""
	end

	local str = self.textInput_.value
	local length = xyd.getNameStringLength(str)
	local limit = xyd.split(xyd.tables.miscTable:getVal("edit_name_length_limit"), "|", true)

	if length > 0 and xyd.tables.filterWordTable:isInWords(self.textInput_.value) then
		self.textInput_.value = self.enter_before

		xyd.alertTips(__("NAME_HAS_BLACK_WORD"))

		return
	elseif limit[2] < length then
		self.textInput_.value = self.enter_before

		xyd.alertTips(__("PERSON_NAME_LONG"))

		return
	else
		self.enter_before = self.textInput_.value
	end
end

function DressNewSuitWindow:onSureTouch()
	local name = self.textInput_UILabel.text

	if name == "" or name == __(__("PERSON_EDIT_TIPS2")) then
		xyd.alertTips(__("PERSON_EDIT_TIPS1"))

		return
	end

	if self.params_.old_name and self.params_.old_name ~= "" and name == self.params_.old_name then
		xyd.alertTips(__("PERSON_EDIT_TIPS1"))

		return
	end

	local str = self.textInput_UILabel.text
	local length = xyd.getNameStringLength(str)
	local limit = xyd.split(xyd.tables.miscTable:getVal("edit_name_length_limit"), "|", true)

	if length < limit[1] then
		xyd.alertTips(__("PERSON_NAME_SHORT"))

		return
	end

	local msg = messages_pb.dress_suit_save_req()
	msg.name = name

	for i in pairs(self.styles) do
		table.insert(msg.style_ids, self.styles[i])
	end

	msg.index = self.index

	xyd.Backend.get():request(xyd.mid.DRESS_SUIT_SAVE, msg)
	self:close()
end

return DressNewSuitWindow
