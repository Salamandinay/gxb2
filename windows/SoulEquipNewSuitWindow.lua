local SoulEquipNewSuitWindow = class("SoulEquipNewSuitWindow", import(".BaseWindow"))

function SoulEquipNewSuitWindow:ctor(name, params)
	SoulEquipNewSuitWindow.super.ctor(self, name, params)

	self.equips = params.equips
	self.oldName = params.oldName
	self.pos = params.pos
	self.callback = params.callback
	self.icons = {}
end

function SoulEquipNewSuitWindow:initWindow()
	SoulEquipNewSuitWindow.super.initWindow()
	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function SoulEquipNewSuitWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.labelWindowTtile = self.groupAction:ComponentByName("labelWindowTtile", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.inputGroup = self.groupAction:NodeByName("inputGroup").gameObject
	self.bg = self.inputGroup:ComponentByName("bg", typeof(UISprite))
	self.textInput = self.inputGroup:ComponentByName("textInput", typeof(UIInput))
	self.textInputLabel = self.textInput:ComponentByName("textInputLabel", typeof(UILabel))
	self.showLabel = self.inputGroup:ComponentByName("showLabel", typeof(UILabel))
	self.btnSure = self.groupAction:NodeByName("btnSure_").gameObject
	self.labelSure = self.btnSure:ComponentByName("button_label", typeof(UILabel))
	self.equip1Group = self.groupAction:NodeByName("equip1Group").gameObject
	self.iconPos1 = self.equip1Group:NodeByName("iconPos").gameObject
	self.equipBg1 = self.iconPos1:ComponentByName("bg", typeof(UISprite))
	self.equipImgChoose1 = self.iconPos1:ComponentByName("imgChoose", typeof(UISprite))
	self.equipimgPlus1 = self.iconPos1:ComponentByName("imgPlus", typeof(UISprite))
	self.equiplabelLevel1 = self.iconPos1:ComponentByName("labelLevel", typeof(UILabel))
	self.equip2Group = self.groupAction:NodeByName("equip2Group").gameObject

	for i = 1, 4 do
		self["iconPos" .. i + 1] = self.equip2Group:NodeByName("iconPos" .. i).gameObject
		self["equipBg" .. i + 1] = self["iconPos" .. i + 1]:ComponentByName("bg", typeof(UISprite))
		self["equipImgChoose" .. i + 1] = self["iconPos" .. i + 1]:ComponentByName("imgChoose", typeof(UISprite))
		self["equipimgPlus" .. i + 1] = self["iconPos" .. i + 1]:ComponentByName("imgPlus", typeof(UISprite))
		self["equiplabelLevel" .. i + 1] = self["iconPos" .. i + 1]:ComponentByName("labelLevel", typeof(UILabel))
		self["imgIcon" .. i + 1] = self["iconPos" .. i + 1]:ComponentByName("imgIcon", typeof(UISprite))
		self["imgQlt" .. i + 1] = self["iconPos" .. i + 1]:ComponentByName("imgQlt", typeof(UISprite))
		self["imgbg" .. i + 1] = self["iconPos" .. i + 1]:ComponentByName("imgbg", typeof(UISprite))
		self["imgStar" .. i + 1] = self["iconPos" .. i + 1]:ComponentByName("imgStar", typeof(UISprite))
	end
end

function SoulEquipNewSuitWindow:layout()
	self.labelWindowTtile.text = __("SOUL_EQUIP_TEXT28")
	self.textInputLabel.text = __("SOUL_EQUIP_TEXT29")

	if self.oldName and self.oldName ~= "" then
		self.textInput.value = self.oldName
		self.enter_before = self.textInput.value
		self.isFirstOpenText = true
	else
		self.textInput.value = ""
	end

	self.labelSure.text = __("SURE_2")
	local equips = self.equips

	for i = 1, 1 do
		if not equips[i] then
			if self.icons[i] then
				self.icons[i]:SetActive(false)
			end
		else
			local params = {
				noClick = true,
				uiRoot = self["iconPos" .. i],
				itemID = equips[i]:getTableID(),
				callback = function ()
				end,
				soulEquipInfo = equips[i]:getSoulEquipInfo()
			}

			if i == 1 then
				params.scale = 1
			else
				params.scale = 1.4054054054054055
			end

			if self.icons[i] then
				self.icons[i]:setInfo(params)
				self.icons[i]:SetActive(true)
			else
				self.icons[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
			end
		end

		self["equipImgChoose" .. i]:SetActive(i == self.curSelectEquipPos)
	end

	for i = 2, 5 do
		if not equips[i] then
			self["imgIcon" .. i]:SetActive(false)
			self["imgQlt" .. i]:SetActive(false)
			self["imgbg" .. i]:SetActive(false)
			self["imgStar" .. i]:SetActive(true)
			self["equiplabelLevel" .. i]:SetActive(false)
			self["equipBg" .. i]:SetActive(true)
		else
			self["imgIcon" .. i]:SetActive(true)
			self["imgQlt" .. i]:SetActive(true)
			self["imgbg" .. i]:SetActive(true)
			self["imgStar" .. i]:SetActive(true)
			self["equiplabelLevel" .. i]:SetActive(true)
			self["equipBg" .. i]:SetActive(false)

			self["equiplabelLevel" .. i].text = "+" .. equips[i]:getLevel()

			xyd.setUISpriteAsync(self["imgIcon" .. i], nil, xyd.tables.itemTable:getIcon(equips[i]:getTableID()))
			xyd.setUISpriteAsync(self["imgQlt" .. i], nil, "soul_equip_kuang_small_" .. equips[i]:getQlt())
			xyd.setUISpriteAsync(self["imgStar" .. i], nil, "pub_star_require" .. equips[i]:getStar())
		end

		self["equipImgChoose" .. i]:SetActive(i == self.curSelectEquipPos)
	end
end

function SoulEquipNewSuitWindow:registerEvent()
	UIEventListener.Get(self.btnSure).onClick = handler(self, self.onSureTouch)

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	local limit = xyd.split(xyd.tables.miscTable:getVal("edit_name_length_limit"), "|", true)

	xyd.addTextInput(self.textInputLabel, {
		check_marks = true,
		type = xyd.TextInputArea.InputSingleLine,
		getText = function ()
			if not self.isFirstOpenText then
				self.isFirstOpenText = true

				return ""
			end

			return self.textInputLabel.text
		end,
		callback = function ()
			if self.textInputLabel.text == "" then
				self.isFirstOpenText = false
				self.textInputLabel.text = __("PERSON_EDIT_TIPS2")
			end
		end,
		max_length = limit[2],
		max_tips = __("PERSON_NAME_LONG"),
		check_length_function = xyd.getNameStringLength
	})

	self.textInput:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
end

function SoulEquipNewSuitWindow:onSureTouch()
	local name = self.textInputLabel.text

	if name == "" or name == __(__("PERSON_EDIT_TIPS2")) then
		xyd.alertTips(__("PERSON_EDIT_TIPS1"))

		return
	end

	local str = self.textInputLabel.text
	local length = xyd.getNameStringLength(str)
	local limit = xyd.split(xyd.tables.miscTable:getVal("edit_name_length_limit"), "|", true)

	if length < limit[1] then
		xyd.alertTips(__("PERSON_NAME_SHORT"))

		return
	end

	local equipIDs = {}

	for i = 1, 5 do
		equipIDs[i] = 0

		if self.equips[i] then
			equipIDs[i] = self.equips[i]:getSoulEquipID()
		end
	end

	xyd.models.slot:setSoulEquipCombination({
		combination = {
			id = self.pos,
			equipIDs = equipIDs,
			name = str
		}
	}, 3, function ()
		if self.callback then
			self.callback()
		end
	end)
	self:close()
end

return SoulEquipNewSuitWindow
