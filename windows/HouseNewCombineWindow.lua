local HouseNewCombineWindow = class("HouseNewCombineWindow", import(".BaseWindow"))

function HouseNewCombineWindow:ctor(name, params)
	HouseNewCombineWindow.super.ctor(self, name, params)
end

function HouseNewCombineWindow:initWindow()
	HouseNewCombineWindow.super.initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function HouseNewCombineWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.labelTitle_ = winTrans:ComponentByName("groupAction/labelTitle_", typeof(UILabel))
	self.img_ = winTrans:ComponentByName("groupAction/img_", typeof(UISprite))
	self.img2_ = winTrans:ComponentByName("groupAction/img2_", typeof(UITexture))
	self.closeBtn = winTrans:NodeByName("groupAction/closeBtn").gameObject
	self.btnSure_ = winTrans:NodeByName("groupAction/btnSure_").gameObject
	self.textInput_ = winTrans:ComponentByName("groupAction/e:Group/textInput_", typeof(UILabel))
end

function HouseNewCombineWindow:layout()
	self.labelTitle_.text = __("HOUSE_TEXT_16")

	if self.params_.old_name and self.params_.old_name ~= "" then
		self.textInput_.text = self.params_.old_name
		self.enter_before = self.params_.old_name
		self.isFirstOpenText = true
	else
		self.textInput_.text = __("HOUSE_TEXT_23")
	end

	self.btnSure_:ComponentByName("button_label", typeof(UILabel)).text = __("SURE_2")

	if self.params_.is_new then
		self.img2_.mainTexture = self.params_.uploadImg
	elseif self.params_.imgUrl then
		xyd.setTextureByURL(self.params_.imgUrl, self.img2_, 202, 130)
	end
end

function HouseNewCombineWindow:registerEvent()
	self:register()

	UIEventListener.Get(self.btnSure_).onClick = handler(self, self.onSureTouch)

	xyd.addTextInput(self.textInput_, {
		check_marks = true,
		type = xyd.TextInputArea.InputSingleLine,
		getText = function ()
			if not self.isFirstOpenText then
				self.isFirstOpenText = true

				return ""
			end

			return self.textInput_.text
		end,
		callback = function ()
			if self.textInput_.text == "" then
				self.isFirstOpenText = false
				self.textInput_.text = __("HOUSE_TEXT_23")
			end
		end
	})
end

function HouseNewCombineWindow:onSureTouch()
	local name = self.textInput_.text

	if name == "" or name == __(__("HOUSE_TEXT_23")) then
		xyd.alertTips(__("PERSON_EDIT_TIPS1"))

		return
	end

	if self.params_.old_name and self.params_.old_name ~= "" and name == self.params_.old_name then
		xyd.alertTips(__("PERSON_EDIT_TIPS1"))

		return
	end

	local msg = messages_pb.house_add_combine_req()

	if self.params_.is_new then
		xyd.HouseMap.get():getSaveData(msg)
	else
		self:getOldFurniture(msg)
	end

	xyd.models.house:reqAddCombine(msg, name, self.params_.id, self.params_.uploadImg)
	xyd.WindowManager.get():closeWindow(self.name_)
end

function HouseNewCombineWindow:getOldFurniture(msg)
	local data = msg.furnitures

	for i = 1, #self.params_.furnitures do
		table.insert(data, self.params_.furnitures[i])
	end
end

return HouseNewCombineWindow
