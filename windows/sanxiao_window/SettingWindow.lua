local SettingWindow = class("SettingWindow", import(".BaseWindow"))
local EditNameComponent = import("app.components.EditNameComponent")

function SettingWindow:ctor(name, params)
	SettingWindow.super.ctor(self, name, params)

	self.hasBind_ = false
	self.btns_ = {}
end

function SettingWindow:initWindow()
	SettingWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	xyd.ModelManager.get():loadModel(xyd.ModelType.ACCOUNT)
	xyd.SdkManager.get():getBindTpType()
end

function SettingWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.lan_count = 7
	self.group_all = winTrans:NodeByName("e:Skin/group_all").gameObject
	self.bg_exit_ = winTrans:ComponentByName("e:Skin/bg_exit_", typeof(UISprite))
	self._closeBtn = winTrans:ComponentByName("e:Skin/group_all/group_bg/_closeBtn", typeof(UISprite))
	self.player_head = winTrans:ComponentByName("e:Skin/group_all/group_player/touxiang_bg/touxiang", typeof(UISprite))
	self.bg_player = winTrans:NodeByName("e:Skin/group_all/group_player/bg_player").gameObject
	self.player_name = winTrans:ComponentByName("e:Skin/group_all/group_player/bg_player/player_name", typeof(UILabel))
	self.cat_head = winTrans:ComponentByName("e:Skin/group_all/group_cat/touxiang_bg/touxiang", typeof(UISprite))
	self.bg_cat = winTrans:NodeByName("e:Skin/group_all/group_cat/bg_cat").gameObject
	self.cat_name = winTrans:ComponentByName("e:Skin/group_all/group_cat/bg_cat/cat_name", typeof(UILabel))
	self.edit_name_widget = winTrans:ComponentByName("e:Skin/edit_name_panel/edit_name_widget", typeof(UIWidget))
	self.btn_account = winTrans:ComponentByName("e:Skin/group_all/group_btns/btn_account", typeof(UISprite))
	local btn_txt = winTrans:ComponentByName("e:Skin/group_all/group_btns/btn_account/btn_txt", typeof(UILabel))
	self.btns_.fb = {
		uiBtn = self.btn_save,
		uilabel = btn_txt
	}
	self.btn_language = winTrans:ComponentByName("e:Skin/group_all/group_btns/btn_language", typeof(UISprite))
	self.btn_tips = winTrans:ComponentByName("e:Skin/group_all/group_btns/btn_tips", typeof(UISprite))
	self.btn_help = winTrans:ComponentByName("e:Skin/group_all/group_btns/btn_help", typeof(UISprite))
	self.btn_comment = winTrans:ComponentByName("e:Skin/group_all/group_btns/btn_comment", typeof(UISprite))
	self.btn_community = winTrans:ComponentByName("e:Skin/group_all/group_btns/btn_community", typeof(UISprite))
	self.btn_question = winTrans:ComponentByName("e:Skin/group_all/group_bot/btn_question", typeof(UISprite))
	self.btn_sound = winTrans:ComponentByName("e:Skin/group_all/group_bot/btn_sound", typeof(UISprite))
	self.btn_music = winTrans:ComponentByName("e:Skin/group_all/group_bot/btn_music", typeof(UISprite))
	self.btn_soundoff = winTrans:ComponentByName("e:Skin/group_all/group_bot/btn_soundoff", typeof(UISprite))
	self.btn_musicoff = winTrans:ComponentByName("e:Skin/group_all/group_bot/btn_musicoff", typeof(UISprite))
	self.device_info_win = winTrans:NodeByName("e:Skin/device_info").gameObject
	self.device_info = winTrans:ComponentByName("e:Skin/device_info/info", typeof(UILabel))
	local soundMgr = xyd.SoundManager.get()
	local bg = soundMgr:getIsSoundOn()

	if bg then
		self.btn_sound:SetActive(true)
		self.btn_soundoff:SetActive(false)
	else
		self.btn_sound:SetActive(false)
		self.btn_soundoff:SetActive(true)
	end

	bg = soundMgr:getIsMusicOn()

	if bg then
		self.btn_music:SetActive(true)
		self.btn_musicoff:SetActive(false)
	else
		self.btn_music:SetActive(false)
		self.btn_musicoff:SetActive(true)
	end

	self.group_language = winTrans:NodeByName("e:Skin/group_language").gameObject
	self._closeLan = winTrans:ComponentByName("e:Skin/group_language/group_bg/_closeLan", typeof(UISprite))
	self.group_community = winTrans:NodeByName("e:Skin/group_community").gameObject
	self._closeCom = winTrans:ComponentByName("e:Skin/group_community/group_bg/_closeCom", typeof(UISprite))
	self.group_all.transform:ComponentByName("group_bg/txt_setting", typeof(UILabel)).text = __("SETTING_TITLE")
	self.btn_account.transform:ComponentByName("btn_txt", typeof(UILabel)).text = __("SETTING_TIPS1")
	self.btn_language.transform:ComponentByName("btn_txt", typeof(UILabel)).text = __("SETTING_TIPS2")
	self.btn_tips.transform:ComponentByName("btn_txt", typeof(UILabel)).text = __("SETTING_TIPS3")
	self.btn_help.transform:ComponentByName("btn_txt", typeof(UILabel)).text = __("SETTING_TIPS4")
	self.btn_comment.transform:ComponentByName("btn_txt", typeof(UILabel)).text = __("SETTING_TIPS5")
	self.btn_community.transform:ComponentByName("btn_txt", typeof(UILabel)).text = __("SETTING_TIPS6")
	self.group_community.transform:ComponentByName("group_bg/txt_community", typeof(UILabel)).text = __("SETTING_TIPS6")
	self.player_name.text = xyd.SelfInfo.get():getNickname()
	self.cat_name.text = __("LOCKED")

	if xyd.ModelManager.get():loadModel(xyd.ModelType.QUEST):hadDoneEditCatNameQuest() then
		self.cat_name.text = xyd.SelfInfo.get():getPetInfo().pet_name
	end
end

function SettingWindow:UIAnimation(group)
	self.bg_exit_.depth = group:GetComponent(typeof(UIWidget)).depth - 1
	local sequence = DG.Tweening.DOTween.Sequence()
	group.transform.localScale = Vector3(0.5, 0.5)
	group:GetComponent(typeof(UIWidget)).alpha = 0.5

	local function getter()
		return group:GetComponent(typeof(UIWidget)).color
	end

	local function setter(value)
		group:GetComponent(typeof(UIWidget)).color = value
	end

	sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 4 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert(0, group.transform:DOScale(Vector3(1.1, 1.1), 4 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert(4 * xyd.TweenDeltaTime, group.transform:DOScale(Vector3(0.97, 0.97), 4 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert(8 * xyd.TweenDeltaTime, group.transform:DOScale(Vector3(1, 1), 5 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
end

function SettingWindow:initUIComponent()
	xyd.setDarkenBtnBehavior(self._closeBtn.gameObject, self, self.onClose)
	xyd.setDarkenBtnBehavior(self._closeLan.gameObject, self, self.onCloseLanguage)
	xyd.setDarkenBtnBehavior(self._closeCom.gameObject, self, self.onCloseCommunity)

	UIEventListener.Get(self.btn_question.gameObject).onClick = handler(self, self.onQuestion)
	UIEventListener.Get(self.btn_sound.gameObject).onClick = handler(self, self.onSound)
	UIEventListener.Get(self.btn_music.gameObject).onClick = handler(self, self.onMusic)
	UIEventListener.Get(self.btn_soundoff.gameObject).onClick = handler(self, self.onSound)
	UIEventListener.Get(self.btn_musicoff.gameObject).onClick = handler(self, self.onMusic)

	xyd.setDarkenBtnBehavior(self.btn_account.gameObject, self, self.onAccount)
	xyd.setDarkenBtnBehavior(self.btn_language.gameObject, self, self.onLanguage)
	xyd.setDarkenBtnBehavior(self.btn_tips.gameObject, self, self.onTips)
	xyd.setDarkenBtnBehavior(self.btn_help.gameObject, self, self.onHelp)
	xyd.setDarkenBtnBehavior(self.btn_comment.gameObject, self, self.onComment)

	UIEventListener.Get(self.device_info_win).onClick = handler(self, self.onCloseDeviceInfo)
	UIEventListener.Get(self.bg_player).onClick = handler(self, self.onPlayerName)

	if xyd.ModelManager.get():loadModel(xyd.ModelType.QUEST):hadDoneEditCatNameQuest() then
		self.bg_cat:SetActive(true)
		xyd.setUISpriteAsync(self.cat_head, xyd.MappingData.bg_touxiang_2, "bg_touxiang_2", function ()
			self.cat_head:MakePixelPerfect()
		end)

		UIEventListener.Get(self.bg_cat).onClick = handler(self, self.onCatName)
	end
end

function SettingWindow:onPlayerName()
	local PLAYER = 2

	local function callback(nickname)
		self.bg_exit_.depth = self.group_all:GetComponent(typeof(UIWidget)).depth - 1

		if nickname ~= nil then
			self.player_name.text = nickname
		end
	end

	self.bg_exit_.depth = self.edit_name_widget.depth - 1

	EditNameComponent.new(self.edit_name_widget.gameObject, callback, PLAYER)
end

function SettingWindow:onCatName()
	local CAT = 1

	local function callback(catName)
		self.bg_exit_.depth = self.group_all:GetComponent(typeof(UIWidget)).depth - 1

		if catName ~= nil then
			self.cat_name.text = catName
		end
	end

	self.bg_exit_.depth = self.edit_name_widget.depth - 1

	EditNameComponent.new(self.edit_name_widget.gameObject, callback, CAT)
end

function SettingWindow:onQuestion()
	local info = XYDSDK.Instance:GetDeviceID()
	local playerID = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYER_INFO).playerID_

	if info == nil or info == "" then
		info = "Failed! >_<"
	end

	self.device_info.text = info .. "\n\n" .. playerID

	self.device_info_win:SetActive(true)
	self:UIAnimation(self.device_info_win)
end

function SettingWindow:onAccount()
	xyd.WindowManager.get():openWindow("account_window")
end

function SettingWindow:onLanguage()
	xyd.SoundManager.get():playEffect("Common/se_button")
	self.group_language:SetActive(true)

	self.group_language.transform:ComponentByName("group_bg/txt_language", typeof(UILabel)).text = __("SETTING_TIPS2")

	self:UIAnimation(self.group_language)
end

function SettingWindow:onTips()
	xyd.SoundManager.get():playEffect("Common/se_button")
end

function SettingWindow:onHelp()
	xyd.SoundManager.get():playEffect("Common/se_button")
end

function SettingWindow:onComment()
	xyd.SoundManager.get():playEffect("Common/se_button")
end

function SettingWindow:onCommunity()
	xyd.SoundManager.get():playEffect("Common/se_button")
	self.group_community:SetActive(true)
	self:UIAnimation(self.group_community)
end

function SettingWindow:onSound()
	local soundMgr = xyd.SoundManager.get()
	local bg = soundMgr:getIsSoundOn()

	if bg then
		soundMgr:setIsSoundOn(false)
		self.btn_sound:SetActive(false)
		self.btn_soundoff:SetActive(true)
	else
		soundMgr:setIsSoundOn(true)
		self.btn_sound:SetActive(true)
		self.btn_soundoff:SetActive(false)
	end
end

function SettingWindow:onMusic()
	local soundMgr = xyd.SoundManager.get()
	local bg = soundMgr:getIsMusicOn()

	if bg then
		soundMgr:setIsMusicOn(false)
		self.btn_music:SetActive(false)
		self.btn_musicoff:SetActive(true)
	else
		soundMgr:setIsMusicOn(true)
		self.btn_music:SetActive(true)
		self.btn_musicoff:SetActive(false)
	end
end

function SettingWindow:onClose()
	xyd.WindowManager.get():closeWindow("setting_window")
end

function SettingWindow:onCloseLanguage()
	self.group_language:SetActive(false)

	self.bg_exit_.depth = self.group_all:GetComponent(typeof(UIWidget)).depth - 1
end

function SettingWindow:onCloseCommunity()
	self.group_community:SetActive(false)

	self.bg_exit_.depth = self.group_all:GetComponent(typeof(UIWidget)).depth - 1
end

function SettingWindow:onCloseDeviceInfo()
	self.device_info_win:SetActive(false)

	self.bg_exit_.depth = self.group_all:GetComponent(typeof(UIWidget)).depth - 1
end

function SettingWindow:dispose()
	SettingWindow.super.dispose(self)
end

return SettingWindow
