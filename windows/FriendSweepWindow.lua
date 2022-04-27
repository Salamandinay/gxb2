local BaseWindow = import(".BaseWindow")
local FriendSweepWindow = class("FriendSweepWindow", BaseWindow)
local FriendModel = xyd.models.friend
local OldSize = {
	w = 720,
	h = 1280
}

function FriendSweepWindow:ctor(name, params)
	FriendSweepWindow.super.ctor(self, name, params)

	self.friendID_ = params.friend_id
	self.curNum_ = 1
end

function FriendSweepWindow:initWindow()
	FriendSweepWindow.super.initWindow(self)

	self.content_ = self.window_:ComponentByName("groupAction", typeof(UISprite))
	local contentTrans = self.content_.transform
	local sWidth, sHeight = xyd.getScreenSize()
	local activeHeight = xyd.WindowManager.get():getActiveHeight()
	local activeWidth = xyd.WindowManager.get():getActiveWidth()

	if sHeight / sWidth <= 1.4 then
		contentTrans.localScale = Vector3(1.15, 1.15, 1.15)
		contentTrans.localPosition = Vector3(0, contentTrans.localPosition.y * 1.15, 0)
	else
		contentTrans.localScale = Vector3(activeWidth / OldSize.w, activeHeight / OldSize.h, 1)
		contentTrans.localPosition = Vector3(0, contentTrans.localPosition.y * activeHeight / OldSize.h, 0)
	end

	self.iconImg_ = contentTrans:ComponentByName("groupTili/image", typeof(UISprite))
	self.labelWinTitle_ = contentTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.labelTips_ = contentTrans:ComponentByName("labelTips_", typeof(UILabel))
	self.btnSure_ = contentTrans:ComponentByName("btnSure", typeof(UISprite)).gameObject
	self.btnSureLabel_ = contentTrans:ComponentByName("btnSure/label", typeof(UILabel))
	self.labelTili_ = contentTrans:ComponentByName("groupTili/label", typeof(UILabel))
	self.addbtn = contentTrans:ComponentByName("groupTili/addbtn", typeof(UISprite))
	self.selectNumPos_ = contentTrans:NodeByName("selectNumPos").gameObject
	self.closeBtn = contentTrans:ComponentByName("closeBtn", typeof(UISprite)).gameObject

	self:layout()
	self:register()
end

function FriendSweepWindow:layout()
	self.labelWinTitle_.text = __("FRIEND_SWEEP_WINDOW")
	self.btnSureLabel_.text = __("CONFIRM")

	xyd.setUISpriteAsync(self.iconImg_, nil, "friend_icon_tili", nil, )
	self:initTextInput()
end

function FriendSweepWindow:initTextInput()
	local maxTili = FriendModel:getTili()

	local function callback(num)
		self.curNum_ = num
		self.labelTili_.text = tostring(maxTili)
	end

	self.selectNum_ = import("app.components.SelectNum").new(self.selectNumPos_, "default")

	self.selectNum_:setInfo({
		minNum = 1,
		curNum = maxTili,
		maxNum = maxTili,
		callback = callback
	})
	self.selectNum_:setPrompt(__("FRIEND_SWEEP_TIPS"))
	self.selectNum_:setFontSize(26, 26)
	self.selectNum_:setKeyboardPos(0, -350)
end

function FriendSweepWindow:register()
	FriendSweepWindow.super.register(self)

	UIEventListener.Get(self.btnSure_.gameObject).onClick = handler(self, self.sureTouch)
	UIEventListener.Get(self.addbtn.gameObject).onClick = handler(self, self.addTouch)
end

function FriendSweepWindow:sureTouch()
	if self:checkCanFight() then
		local fightParams = {
			is_weep = true,
			battleType = xyd.BattleType.FRIEND_BOSS,
			friend_id = self.friendID_,
			sweep_num = self.curNum_
		}

		xyd.WindowManager.get():openWindow("battle_formation_window", fightParams)
		FriendSweepWindow.super.onClickCloseButton(self)
	end
end

function FriendSweepWindow:checkCanFight()
	return true
end

function FriendSweepWindow:addTouch()
end

return FriendSweepWindow
