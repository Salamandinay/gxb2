local ArenaAllServerQuizResultWindow = class("ArenaAllServerQuizResultWindow", import(".BaseWindow"))
local AllServerPlayerIcon = import("app.components.AllServerPlayerIcon")

function ArenaAllServerQuizResultWindow:ctor(name, params)
	ArenaAllServerQuizResultWindow.super.ctor(self, name, params)

	self.round_ = 0
	self.data_ = params.info
	self.callback = params.callback
	self.round_ = params.round
end

function ArenaAllServerQuizResultWindow:initWindow()
	ArenaAllServerQuizResultWindow.super.initWindow(self)
	self:getUIComponent()
	self:initEffect()
end

function ArenaAllServerQuizResultWindow:initEffect()
	local isWin = self.data_.is_win == 1
	local effectName = isWin and "bet_shengli" or "bet_shibai"
	self.labelTips_.color = isWin and Color.New2(2822897919.0) or Color.New2(960513791)

	xyd.setUITextureByNameAsync(self.textImg, effectName .. "_" .. xyd.Global.lang, true)

	self.fEffect = xyd.Spine.new(self.effectGroup)

	self.fEffect:setInfo(effectName, function ()
		if isWin then
			self.fEffect:changeAttachment("zi1", self.textImg)
			self.fEffect:changeAttachment("zi2", self.textImg)
		else
			self.fEffect:changeAttachment("zi1", self.textImg)
		end

		self.fEffect:SetLocalPosition(0, 120, -1)
		self.fEffect:play("texiao01", 1, 1, function ()
			self.fEffect:play("texiao02", 0)
		end)
	end)

	self.fEffect2 = xyd.Spine.new(self.effectGroup)

	self.fEffect2:setInfo(effectName, function ()
		self.fEffect2:SetLocalPosition(0, 120, 0)
		self.fEffect2:play("texiao03", 1, 1, function ()
			self.fEffect2:play("texiao04", 0)
		end)
	end)
	XYDCo.WaitForTime(0.3, function ()
		self:initLayout()
		self.mask_:SetActive(false)
	end, nil)
end

function ArenaAllServerQuizResultWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.winGroup = winTrans:NodeByName("winGroup").gameObject
	self.labelTips_ = self.winGroup:ComponentByName("labelTips_", typeof(UILabel))
	self.confirmBtn = self.winGroup:NodeByName("confirmBtn").gameObject
	self.groupAvatar = self.winGroup:NodeByName("groupAvatar").gameObject
	self.effectGroup = self.winGroup:NodeByName("effectGroup").gameObject
	self.textImg = winTrans:ComponentByName("textImg", typeof(UITexture))
	self.mask_ = winTrans:NodeByName("mask_").gameObject
end

function ArenaAllServerQuizResultWindow:initLayout()
	self.layeoutSequence = DG.Tweening.DOTween.Sequence():OnComplete(function ()
		self.confirmBtn:SetActive(true)
		self.labelTips_:SetActive(true)
	end)
	self.confirmBtn:ComponentByName("button_label", typeof(UILabel)).text = __("CONFIRM")

	self:initAvatar()

	local transform = self.groupAvatar.transform

	transform:SetLocalScale(0.01, 0.01, 1)
	transform:SetActive(true)
	self.layeoutSequence:Append(transform:DOScale(Vector3(1, 1, 1), 0.16))

	UIEventListener.Get(self.confirmBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ArenaAllServerQuizResultWindow:initAvatar()
	local item = AllServerPlayerIcon.new(self.groupAvatar)

	item:setInfo(self.data_.win_player_show_info)

	self.labelTips_.text = __("ARENA_ALL_SERVER_TEXT_27") .. __("ARENA_ALL_SERVER_ROUND_TEXT_" .. tostring(self.round_))
	local isWin = self.data_.is_win

	if not isWin then
		-- Nothing
	end
end

function ArenaAllServerQuizResultWindow:excuteCallBack(isCloseAll)
	ArenaAllServerQuizResultWindow.super.excuteCallBack(self, isCloseAll)

	if not isCloseAll and self.callback then
		self:callback()
	end
end

return ArenaAllServerQuizResultWindow
