local BaseWindow = import(".BaseWindow")
local KaiXueWindow = class("KaiXueWindow", BaseWindow)

function KaiXueWindow:ctor(name, params)
	KaiXueWindow.super.ctor(self, name, params)

	self.skinName = "KaiXueWindowSkin"
	self.currentState = xyd.Global.lang
	local files = xyd.getEffectFilesByNames({
		"ruxueshi_kaimen"
	})

	self:setResourcePaths(files)

	self.kaimenTimerIDList_ = {}
end

function KaiXueWindow:initWindow()
	KaiXueWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
	self:playAction()
end

function KaiXueWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupMain = trans:NodeByName("groupMain").gameObject
	self.bg = self.groupMain:NodeByName("bg").gameObject
	self.effectNode1 = self.groupMain:NodeByName("effectNode1").gameObject
	self.effectNode2 = self.groupMain:NodeByName("effectNode2").gameObject
	self.effectNode3 = self.groupMain:NodeByName("effectNode3").gameObject
	self.tips_ = self.groupMain:NodeByName("tips_").gameObject
	self.tipsBg = self.tips_:ComponentByName("tipsBg", typeof(UISprite))
	self.tipsLabel = self.tips_:ComponentByName("tipsLabel", typeof(UILabel))
end

function KaiXueWindow:layout()
	self.tipsLabel.text = __("TOUCH_ME_DUDE")
end

function KaiXueWindow:registerEvent()
	UIEventListener.Get(self.bg).onClick = handler(self, self.onBgClick)
end

function KaiXueWindow:onBgClick()
	UIEventListener.Get(self.bg).onClick = nil

	self.kaimenEffect:play("texiao01", 1, 1, nil, true)
	self.kaimenShanguang:play("texiao02", 1, 1, nil, true)
	self.kaimenShanguang:SetActive(true)

	if self.kaimenHand then
		self.kaimenHand:SetActive(false)
	end

	xyd.SoundManager.get():playSound("2051")

	local sequence = self:getSequence()

	sequence:Append(self.tips_.transform:DOScale(Vector3(1.05, 1.05, 1), 0.06)):Append(self.tips_.transform:DOScale(Vector3(0.5, 0.5, 1), 0.2)):Join(xyd.getTweenAlpha(self.tips_:GetComponent(typeof(UIWidget)), 0, 0.2)):AppendCallback(function ()
		self.tips_:SetActive(false)
	end)
	self:clearUpTimer()
	self:createViewMove()
end

function KaiXueWindow:playAction()
	self.kaimenEffect = xyd.Spine.new(self.effectNode1)

	self.kaimenEffect:setInfo("ruxueshi_kaimen", function ()
		self.kaimenEffect:SetLocalScale(1.25, 1.25, 1)
		self.kaimenEffect:setRenderTarget()
		self.kaimenEffect:pause()
	end)

	self.kaimenShanguang = xyd.Spine.new(self.effectNode3)

	self.kaimenShanguang:setInfo("ruxueshi_kaimen", function ()
		self.kaimenShanguang:SetLocalScale(1.15, 0.95, 1)
		self.kaimenShanguang:SetActive(false)
	end)
	self:createKaimenTimer()
	xyd.models.selfPlayer:hasPlayedKaimen()
end

function KaiXueWindow:createKaimenTimer()
	local key1 = self:waitForTime(1, function ()
		self.kaimenHand = xyd.Spine.new(self.effectNode2)

		self.kaimenHand:setInfo("fx_ui_dianji", function ()
			self.kaimenHand:setAlpha(0.5)
			self.kaimenHand:play("texiao01", 0)

			local action = self:getSequence()

			local function setter(val)
				self.kaimenHand:setAlpha(val)
			end

			action:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0.5, 1, 1))
		end)
	end)
	local key2 = self:waitForTime(4, function ()
		self:createKaimenTips()
	end)

	table.insert(self.kaimenTimerIDList_, key1)
	table.insert(self.kaimenTimerIDList_, key2)
end

function KaiXueWindow:createKaimenTips()
	local action = self:getSequence()

	self.tips_:SetActive(true)

	local w = self.tips_:GetComponent(typeof(UIWidget))
	w.alpha = 0.5

	action:Append(xyd.getTweenAlpha(w, 1, 1.5))
end

function KaiXueWindow:clearUpTimer()
	if #self.kaimenTimerIDList_ <= 0 then
		return
	end

	for i = 1, #self.kaimenTimerIDList_ do
		local timerID = self.kaimenTimerIDList_[i]

		XYDCo.StopWait(timerID)
	end
end

function KaiXueWindow:createViewMove()
	local action1 = self:getSequence()

	action1:Append(self.groupMain.transform:DOScale(Vector3(1.2, 1.2, 1), 3.5)):Join(self.groupMain.transform:DOLocalMoveY(-100, 3.5)):AppendCallback(function ()
		self.kaimenEffect:SetActive(false)
		self.bg:SetActive(false)
		self.winBg_:SetActive(false)
	end)
	self:waitForTime(5, function ()
		local wnd = xyd.getWindow("main_window")

		if wnd then
			wnd:checkIfOldPlayerBack()
		end

		xyd.closeWindow(self.name_)
	end)
end

return KaiXueWindow
