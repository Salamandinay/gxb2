local BaseWindow = import(".BaseWindow")
local PersonInfoWindow = class("PersonInfoWindow", BaseWindow)
local PngNum = require("app.components.PngNum")
local PlayerIcon = require("app.components.PlayerIcon")

function PersonInfoWindow:ctor(name, params)
	PersonInfoWindow.super.ctor(self, name, params)

	self.isChangeSignature_ = false
	self.signature_ = ""
	self.old_edit_text = self.signature_
	self.selfPlayer = xyd.models.selfPlayer
	self.backpack = xyd.models.backpack
end

function PersonInfoWindow:initWindow()
	PersonInfoWindow.super.initWindow(self)
	self:getUIComponent()
	PersonInfoWindow.super.register(self)
	self:layout()
	self:registerEvent()
end

function PersonInfoWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupMain = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle_ = groupMain:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = groupMain:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	self.pageCon1 = groupMain:NodeByName("pageCon1").gameObject
	local group1 = self.pageCon1:NodeByName("group1").gameObject
	self.labelName_ = group1:ComponentByName("labelName_", typeof(UILabel))
	self.btnEdit_ = group1:NodeByName("btnEdit_").gameObject
	local group2 = self.pageCon1:NodeByName("group2").gameObject
	self.edit_ = group2:ComponentByName("edit_", typeof(UIInput))
	self.edit_label = group2:ComponentByName("edit_/edit_label", typeof(UILabel))
	self.edit_label_copy = group2:ComponentByName("edit_/edit_label_copy", typeof(UILabel))
	local group3 = self.pageCon1:NodeByName("group3").gameObject
	self.labelGuildName_ = group3:ComponentByName("labelGuildName_", typeof(UILabel))
	self.copyGroup = group3:NodeByName("copyGroup").gameObject
	local group4 = group3:NodeByName("group4").gameObject
	self.labelID_ = group4:ComponentByName("labelID_", typeof(UILabel))
	self.groupAvatar = self.pageCon1:NodeByName("groupAvatar").gameObject
	self.pIcon = PlayerIcon.new(self.groupAvatar)
	self.pIcon.go.transform.localScale = Vector3.one * 1.21
	self.imgAlert_ = self.groupAvatar:ComponentByName("imgAlert_", typeof(UISprite))
	self.groupVip = self.pageCon1:NodeByName("groupVip").gameObject
	self.groupVipNum = self.groupVip:NodeByName("groupVipNum").gameObject
	self.pngNum = self.groupVipNum:NodeByName("pngNum").gameObject
	self.pngNumVip_ = PngNum.new(self.pngNum)
	local groupLev = self.pageCon1:NodeByName("groupLev").gameObject
	self.labelLevDesc_ = groupLev:ComponentByName("labelLevDesc_", typeof(UILabel))
	self.labelLev_ = groupLev:ComponentByName("labelLev_", typeof(UILabel))
	local group5 = self.pageCon1:NodeByName("group5").gameObject
	self.bar_ = group5:ComponentByName("bar_", typeof(UIProgressBar))
	self.labelExp_ = group5:ComponentByName("labelExp_", typeof(UILabel))
	self.groupSkin = self.pageCon1:NodeByName("groupSkin").gameObject
	self.personCon = self.groupSkin:NodeByName("personCon").gameObject
	self.personBottom = self.personCon:ComponentByName("personBottom", typeof(UISprite))
	self.personEffect = self.personCon:NodeByName("personEffect").gameObject
	self.line = self.groupSkin:ComponentByName("line", typeof(UISprite))
	self.changeDressBtn = self.groupSkin:NodeByName("changeDressBtn").gameObject
	self.changeDressBtnLabel = self.changeDressBtn:ComponentByName("changeDressBtnLabel", typeof(UILabel))
	self.changeDressGreyBtn = self.groupSkin:NodeByName("changeDressGreyBtn").gameObject
	local group6 = groupMain:NodeByName("group6").gameObject
	self.labelEmail_ = group6:ComponentByName("labelEmail_", typeof(UILabel))
	self.groupPrivacy = group6:NodeByName("groupPrivacy").gameObject
	self.labelPrivate = self.groupPrivacy:ComponentByName("labelPrivate", typeof(UILabel))
	self.e_Rect = self.groupPrivacy:ComponentByName("e:Rect", typeof(UISprite)).gameObject
	self.pageCon2 = groupMain:NodeByName("pageCon2").gameObject
	local groupSystem = self.pageCon2:NodeByName("groupSystem").gameObject
	self.labelSystem = groupSystem:ComponentByName("labelSystem", typeof(UILabel))
	self.btnAccount_ = groupSystem:NodeByName("btnAccount_").gameObject
	self.btnAccountLabel = self.btnAccount_:ComponentByName("btnAccountLabel", typeof(UILabel))
	self.btnService_ = groupSystem:NodeByName("btnService_").gameObject
	self.btnServiceLabel = self.btnService_:ComponentByName("btnServiceLabel", typeof(UILabel))
	self.btnRepair_ = groupSystem:NodeByName("btnRepair_").gameObject
	self.btnRepairLabel = self.btnRepair_:ComponentByName("btnRepairLabel", typeof(UILabel))
	local groupSetting = self.pageCon2:NodeByName("groupSetting").gameObject
	self.labelSetting = groupSetting:ComponentByName("labelSetting", typeof(UILabel))
	self.btnSound_ = groupSetting:NodeByName("btnSound_").gameObject
	self.btnSoundLabel = self.btnSound_:ComponentByName("btnSoundLabel", typeof(UILabel))
	self.btnLan_ = groupSetting:NodeByName("btnLan_").gameObject
	self.btnLanLabel = self.btnLan_:ComponentByName("btnLanLabel", typeof(UILabel))
	self.btnNotice_ = groupSetting:NodeByName("btnNotice_").gameObject
	self.btnNoticeLabel = self.btnNotice_:ComponentByName("btnNoticeLabel", typeof(UILabel))
	self.btnRedpoint_ = groupSetting:NodeByName("btnRedpoint_").gameObject
	self.btnRedpointLabel = self.btnRedpoint_:ComponentByName("btnRedpointLabel", typeof(UILabel))
	self.btnOthers_ = groupSetting:NodeByName("btnOthers").gameObject
	self.btnOthersLabel = self.btnOthers_:ComponentByName("btnOthersLabel", typeof(UILabel))
	local groupSound = self.pageCon2:NodeByName("groupSound").gameObject
	self.barBg_ = groupSound:ComponentByName("barBg_", typeof(UISlider))
	self.barEffect_ = groupSound:ComponentByName("barEffect_", typeof(UISlider))
	self.labelTips1 = groupSound:ComponentByName("labelTips1", typeof(UILabel))
	self.labelTips2 = groupSound:ComponentByName("labelTips2", typeof(UILabel))
	self.labelSound = groupSound:ComponentByName("labelSound", typeof(UILabel))

	if xyd.Global.lang == "ja_jp" then
		self.labelPrivate:SetActive(false)
		self.e_Rect:SetActive(false)
	end

	self.pageCon1:SetActive(true)
	self.pageCon2:SetActive(false)

	self.labelBtnCon = groupMain:NodeByName("labelBtnCon").gameObject

	for i = 1, 2 do
		self["btnCon" .. i] = self.labelBtnCon:NodeByName("btnCon" .. i).gameObject
		self["lebelBtn" .. i] = self["btnCon" .. i]:ComponentByName("lebelBtn" .. i, typeof(UISprite))
		self["labelText" .. i] = self["btnCon" .. i]:ComponentByName("labelText" .. i, typeof(UILabel))
	end
end

function PersonInfoWindow:layout()
	self.labelName_.text = self.selfPlayer:getPlayerName()
	self.labelID_.text = "ID:" .. tostring(self.selfPlayer:getPlayerID())
	self.labelLevDesc_.text = __("LV")
	self.labelLev_.text = tostring(self.backpack:getLev())

	self.pngNumVip_:setInfo({
		iconName = "player_vip",
		num = self.backpack:getVipLev()
	})

	local numW = self.pngNumVip_:getWidth()
	self.pngNum:GetComponent(typeof(UIWidget)).width = numW
	local data = xyd.models.guild.base_info

	if data and data.name then
		self.labelGuildName_.text = __("PERSON_GUILD_NAME", data.name)
	else
		self.labelGuildName_.text = ""
	end

	self.labelEmail_.text = __("SETTING_LABEL_1")
	self.labelPrivate.text = __("SETTING_UP_PRIVACY")
	self.btnAccountLabel.text = __("PERSON_BTN_1")
	self.btnServiceLabel.text = __("PERSON_BTN_2")
	self.btnRepairLabel.text = __("PERSON_BTN_3")
	self.btnSoundLabel.text = __("PERSON_BTN_4")
	self.btnLanLabel.text = __("PERSON_BTN_5")
	self.btnNoticeLabel.text = __("PERSON_BTN_6")
	self.btnRedpointLabel.text = __("RED_POINT_BTN_WORDS")
	self.btnOthersLabel.text = __("SETTING_UP_OTHER")
	self.labelSystem.text = __("PERSON_SYSTEM")
	self.labelSetting.text = __("PERSON_SETTING")
	self.edit_label.text = __("PERSON_SIGNATURE_TEXT_1")
	local signature = self.selfPlayer:getSignature()
	self.edit_.value = signature
	self.signature_ = signature
	self.old_edit_text = self.signature_

	for i = 1, 2 do
		xyd.setUISpriteAsync(self["lebelBtn" .. i], nil, "person_skin_mark_bg" .. i, nil, , )

		self["labelText" .. i].text = __("PERSON_INFO_LABEL_" .. i)
	end

	self.labelTitle_.text = __("PERSON_INFO_LABEL_1")
	self.labelTips1.text = __("SETTING_UP_MUSIC")
	self.labelTips2.text = __("SETTING_UP_SOUND")
	self.labelSound.text = __("SETTING_UP_VOLUME")
	self.changeDressBtnLabel.text = __("PERSON_INFO_LABEL_3")
	self.barBg_.value = xyd.SoundManager.get().musicVolume_
	self.barEffect_.value = xyd.SoundManager.get():getSoundVolume()

	self:initBar()
	self:initAvatar()
	self:initName()
	self:initDress()

	if DEBUG then
		self.gm = eui.TextInput.new()

		self:addChild(self.gm)

		local tmp = eui.Button.new()
		self.gm.text = "item 1 1"
		self.gm.textDisplay.multiline = true
		self.gm.top = 90
		self.gm.left = 5
		self.gm.width = 500

		self.gm:addEventListener(egret.Event.CHANGE, function (____, event)
			local text = event.target.text

			if text[text.length - 1] == "\n" then
				self.gm.text = ""

				GMcommand:get():request(text)
			end
		end, self)
	end
end

function PersonInfoWindow:initAvatar()
	local avatarID = self.selfPlayer:getAvatarID()
	local avatarFrameID = self.selfPlayer:getAvatarFrameID()

	self.pIcon:setInfo({
		avatarID = avatarID,
		avatar_frame_id = avatarFrameID,
		callback = function ()
			self:onShowAvatar()
		end
	})
	self:onNewAvatars()
end

function PersonInfoWindow:initName()
	local name = self.selfPlayer:getPlayerName()
	self.labelName_.text = name
end

function PersonInfoWindow:initBar()
	local exp = self.backpack:getItemNumByID(xyd.ItemID.EXP)
	local lev = self.backpack:getLev()
	local lastAllExp = xyd.tables.expPlayerTable:allExp(lev)
	local curLevNeedExp = xyd.tables.expPlayerTable:needExp(lev)
	local curExp = exp - lastAllExp
	self.labelExp_.text = tostring(curExp) .. " / " .. tostring(curLevNeedExp)
	self.bar_.value = curExp / curLevNeedExp
end

function PersonInfoWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.EDIT_PLAYER_AVATAR, handler(self, self.initAvatar))
	self.eventProxy_:addEventListener(xyd.event.EDIT_PLAYER_AVATAR_FRAME, handler(self, self.initAvatar))
	self.eventProxy_:addEventListener(xyd.event.EDIT_PLAYER_NAME, handler(self, self.onEditName))
	self.eventProxy_:addEventListener(xyd.event.NEW_AVATARS, handler(self, self.onNewAvatars))
	self.eventProxy_:addEventListener(xyd.event.FOCUS_OUT, function ()
		self.onChangeSignature()
	end, self)

	UIEventListener.Get(self.copyGroup).onClick = function ()
		local id = self.selfPlayer:getPlayerID()

		xyd.SdkManager:get():copyToClipboard(tostring(id))
		xyd.showToast(__("COPY_SELF_ID_SUCCESSFUL"))
	end

	UIEventListener.Get(self.btnEdit_).onClick = handler(self, function ()
		self.onEdit()
	end)
	UIEventListener.Get(self.btnAccount_).onClick = handler(self, function ()
		self.onAccountTouch()
	end)
	UIEventListener.Get(self.btnService_).onClick = handler(self, function ()
		self.onServiceTouch()
	end)
	UIEventListener.Get(self.btnRepair_).onClick = handler(self, function ()
		self.onRepairTouch()
	end)
	UIEventListener.Get(self.btnSound_).onClick = handler(self, function ()
		self.onSoundTouch()
	end)
	UIEventListener.Get(self.btnLan_).onClick = handler(self, function ()
		self.onLanTouch()
	end)
	UIEventListener.Get(self.btnNotice_).onClick = handler(self, function ()
		self.onNoticeTouch()
	end)
	UIEventListener.Get(self.btnRedpoint_).onClick = handler(self, function ()
		self.onRedpointTouch()
	end)
	UIEventListener.Get(self.btnOthers_).onClick = handler(self, function ()
		self.onOtherTouch()
	end)
	UIEventListener.Get(self.labelPrivate.gameObject).onClick = handler(self, function ()
		self.onPrivatePolicy()
	end)

	UIEventListener.Get(self.groupVip).onClick = function ()
		xyd.SoundManager:playSound(xyd.SoundID.BUTTON)
		xyd.WindowManager.get():openWindow("vip_window", {
			show_benefit = true
		})
	end

	XYDUtils.AddEventDelegate(self.edit_.onChange, handler(self, self.onChangeSignature))

	UIEventListener.Get(self.lebelBtn1.gameObject).onClick = function ()
		if not self.pageCon1.gameObject.activeSelf then
			self.labelTitle_.text = __(__("PERSON_INFO_LABEL_1"))

			self.pageCon1:SetActive(true)
			self.pageCon2:SetActive(false)
			xyd.setUISpriteAsync(self.lebelBtn1, nil, "person_skin_mark_bg1", nil, , )
			xyd.setUISpriteAsync(self.lebelBtn2, nil, "person_skin_mark_bg2", nil, , )
		end
	end

	UIEventListener.Get(self.lebelBtn2.gameObject).onClick = function ()
		if not self.pageCon2.gameObject.activeSelf then
			self.labelTitle_.text = __(__("PERSON_INFO_LABEL_2"))

			self.pageCon1:SetActive(false)
			self.pageCon2:SetActive(true)
			xyd.setUISpriteAsync(self.lebelBtn1, nil, "person_skin_mark_bg2", nil, , )
			xyd.setUISpriteAsync(self.lebelBtn2, nil, "person_skin_mark_bg1", nil, , )
		end
	end

	function self.barBg_.onDragFinished()
		xyd.SoundManager.get():setMusicVolume(self.barBg_.value)
	end

	function self.barEffect_.onDragFinished()
		xyd.SoundManager.get():setSoundVolume(self.barEffect_.value)
	end

	UIEventListener.Get(self.changeDressBtn.gameObject).onClick = function ()
		if xyd.checkFunctionOpen(xyd.FunctionID.DRESS) then
			xyd.WindowManager.get():openWindow("dress_main_window", {
				window_top_close_fun = function ()
					xyd.WindowManager.get():openWindow("person_info_window")
				end
			})
			self:close(nil, true)
		end
	end

	UIEventListener.Get(self.changeDressGreyBtn.gameObject).onClick = function ()
		if xyd.checkFunctionOpen(xyd.FunctionID.DRESS) then
			xyd.WindowManager.get():openWindow("dress_main_window", {
				window_top_close_fun = function ()
					xyd.WindowManager.get():openWindow("person_info_window")
				end
			})
			self:close(nil, true)
		end
	end
end

function PersonInfoWindow:onEditFocusOut(event)
	if event.data.target == self.edit_ then
		self:onChangeSignature()
	end
end

function PersonInfoWindow:onChangeSignature()
	self.isChangeSignature_ = true

	if self:checkValid() then
		self.signature_ = tostring(self.edit_.value)
		self.old_edit_text = self.signature_
	else
		local length = xyd.getNameStringLength(self.old_edit_text)
		local limit = xyd.tables.miscTable:getNumber("player_sign_num_max", "value", "|")
		local max_line = xyd.tables.miscTable:getNumber("partner_signature_length_limit", "value", "|")
		self.edit_label_copy.text = self.old_edit_text

		if limit < length or self.edit_label_copy.height > max_line * 24 then
			self.old_edit_text = ""
		end

		self.edit_.value = self.old_edit_text
	end
end

function PersonInfoWindow:checkValid()
	local str = tostring(self.edit_.value)
	self.edit_label_copy.text = str
	local length = xyd.getNameStringLength(str)
	local limit = xyd.tables.miscTable:getNumber("player_sign_num_max", "value", "|")
	local max_line = xyd.tables.miscTable:getNumber("partner_signature_length_limit", "value", "|")
	local flag = true
	local tips = ""

	if limit < length or self.edit_label_copy.height > max_line * 24 then
		tips = __("PERSON_SIGNATURE_TEXT_2")
		flag = false
	elseif length > 0 and xyd.tables.filterWordTable:isInWords(str) then
		flag = false
		tips = __("NAME_HAS_BLACK_WORD")
		self.edit_.value = self.signature_
	end

	if tips ~= "" then
		xyd.alert(xyd.AlertType.TIPS, tips)
	end

	return flag
end

function PersonInfoWindow:onAccountTouch()
	xyd.WindowManager.get():openWindow("account_window")
end

function PersonInfoWindow:onServiceTouch()
	xyd.WindowManager.get():openWindow("service_window")
end

function PersonInfoWindow:onRepairTouch()
	xyd.WindowManager.get():openWindow("system_doctor_window")
end

function PersonInfoWindow:onSoundTouch()
	xyd.WindowManager.get():openWindow("sound_window")
end

function PersonInfoWindow:onLanTouch()
	xyd.WindowManager.get():openWindow("change_language_window")
end

function PersonInfoWindow:onNoticeTouch()
	xyd.WindowManager.get():openWindow("notify_manager_window")
end

function PersonInfoWindow:onRedpointTouch()
	xyd.WindowManager.get():openWindow("red_point_manager_window")
end

function PersonInfoWindow:onOtherTouch()
	xyd.WindowManager.get():openWindow("other_window")
end

function PersonInfoWindow:onEdit()
	xyd.WindowManager.get():openWindow("person_edit_name_window")
end

function PersonInfoWindow:onPictureTouch()
	xyd.WindowManager.get():openWindow("edit_picture_window")
end

function PersonInfoWindow:onEditName()
	self:initName()
	xyd.alert(xyd.AlertType.TIPS, __("PERSON_NAME_SUCCEED"))
end

function PersonInfoWindow:onShowAvatar()
	xyd.WindowManager.get():openWindow("person_avatars_window")
end

function PersonInfoWindow:onNewPicture()
end

function PersonInfoWindow:onNewAvatars()
	local newAvatars = self.backpack:getNewAvatars()

	if #newAvatars > 0 then
		self.imgAlert_:SetActive(true)
	else
		self.imgAlert_:SetActive(false)
	end
end

function PersonInfoWindow:onPrivatePolicy()
	if xyd.Global.lang == "en_en" then
		UnityEngine.Application.OpenURL("https://girlsh5.carolgames.com/en/privacy-and-cookie-policy/")
	elseif xyd.Global.lang == "zh_tw" then
		UnityEngine.Application.OpenURL("https://girlsh5.carolgames.com/tw/privacy-and-cookie-policy/")
	elseif xyd.Global.lang == "fr_fr" then
		UnityEngine.Application.OpenURL("https://mhome.carolgames.com/fr/article/privacy_policy")
	elseif xyd.Global.lang == "ko_kr" then
		UnityEngine.Application.OpenURL("https://carolgames.com/ko/article/privacy_policy")
	end
end

function PersonInfoWindow:willClose()
	PersonInfoWindow.super.willClose(self)

	if self.isChangeSignature_ then
		local curStr = self.edit_.value:trim()

		if curStr ~= self.selfPlayer:getSignature() then
			self.selfPlayer:editSignature(curStr)
		end
	end
end

function PersonInfoWindow:initDress()
	local iconClass = require("app.components.ThreeAttrComponent")
	self.attr_map = iconClass.new(self.groupSkin)
	local params = {
		max_value = xyd.models.dress:getThreeMaxValue(),
		value_arr = xyd.models.dress:getAttrs(),
		text_arr = {
			__("PERSON_DRESS_ATTR_1"),
			__("PERSON_DRESS_ATTR_2"),
			__("PERSON_DRESS_ATTR_3")
		}
	}

	self.attr_map:setInfo(params)
	self.attr_map:SetLocalPosition(153.5, 0.4, 0)

	self.normalModel_ = import("app.components.SenpaiModel").new(self.personEffect)

	self.normalModel_:setModelInfo({
		isNewClipShader = true,
		ids = xyd.models.dress:getEffectEquipedStyles()
	})

	if xyd.checkFunctionOpen(xyd.FunctionID.DRESS, true) then
		self.changeDressGreyBtn.gameObject:SetActive(false)
		xyd.applyChildrenOrigin(self.changeDressBtn)

		self.changeDressBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	else
		self.changeDressGreyBtn.gameObject:SetActive(true)
		xyd.applyChildrenGrey(self.changeDressBtn)

		self.changeDressBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	end
end

return PersonInfoWindow
