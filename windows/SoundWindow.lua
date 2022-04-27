local SoundWindow = class("SoundWindow", import(".BaseWindow"))

function SoundWindow:ctor(name, params)
	SoundWindow.super.ctor(self, name, params)

	self.curTouchBar = 0
	self.len = 330
end

function SoundWindow:initWindow()
	SoundWindow.super.initWindow(self)
	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function SoundWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle_ = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.labelTips1 = groupAction:ComponentByName("labelTips1", typeof(UILabel))
	self.labelTips2 = groupAction:ComponentByName("labelTips2", typeof(UILabel))
	self.labelTips0 = groupAction:ComponentByName("labelTips0", typeof(UILabel))
	self.labelTips3 = groupAction:ComponentByName("labelTips3", typeof(UILabel))
	self.labelOpen3 = groupAction:ComponentByName("labelOpen3", typeof(UILabel))
	self.labelClose3 = groupAction:ComponentByName("labelClose3", typeof(UILabel))
	self.btnClose3 = groupAction:NodeByName("btnClose3").gameObject
	self.btnOpen3 = groupAction:NodeByName("btnOpen3").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.barBg_ = groupAction:ComponentByName("barBg_", typeof(UISlider))
	self.barEffect_ = groupAction:ComponentByName("barEffect_", typeof(UISlider))
end

function SoundWindow:layout()
	self.labelTitle_.text = __("PERSON_BTN_4")
	self.labelTips1.text = __("PERSON_BTN_4")
	self.labelTips2.text = __("SETTING_UP_SOUND")
	self.labelTips0.text = __("PERSON_BTN_8")
	self.labelTips3.text = __("PERSON_BTN_9")
	self.labelOpen3.text = __("PERSON_MUSIC1")
	self.labelClose3.text = __("PERSON_MUSIC2")
	self.barBg_.value = xyd.SoundManager.get():getMusicVolume()
	self.barEffect_.value = xyd.SoundManager.get():getSoundVolume()

	self:updateBtn()
end

function SoundWindow:updateBtn()
	local img1 = self.btnOpen3:NodeByName("imgSelect").gameObject
	local img2 = self.btnClose3:NodeByName("imgSelect").gameObject
	local isHomeBg = true

	if xyd.Global.bgMusic ~= xyd.SoundID.HOME_BG then
		isHomeBg = false
	end

	img1:SetActive(isHomeBg)
	img2:SetActive(not isHomeBg)
	xyd.setTouchEnable(self.btnOpen3, not isHomeBg)
	xyd.setTouchEnable(self.btnClose3, isHomeBg)
end

function SoundWindow:registerEvent()
	self:register()

	UIEventListener.Get(self.btnOpen3).onClick = function ()
		self:onMusicSwitch(1)
	end

	UIEventListener.Get(self.btnClose3).onClick = function ()
		self:onMusicSwitch(2)
	end

	function self.barBg_.onDragFinished()
		xyd.SoundManager.get():setMusicVolume(self.barBg_.value)
	end

	function self.barEffect_.onDragFinished()
		xyd.SoundManager.get():setSoundVolume(self.barEffect_.value)
	end
end

function SoundWindow:onMusicSwitch(index)
	xyd.Global.bgMusic = index == 1 and xyd.SoundID.HOME_BG or xyd.SoundID.HOME_BG_OLD

	UnityEngine.PlayerPrefs.SetString("Mafia.Music.Home_Bg", xyd.Global.bgMusic)
	xyd.SoundManager.get():homeBGSwitch()
	self:updateBtn()
end

return SoundWindow
