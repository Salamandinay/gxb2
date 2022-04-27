local FuncOpenWindow = class("FuncOpenWindow", import(".BaseWindow"))
local FunctionTable = xyd.tables.functionTable

function FuncOpenWindow:ctor(name, params)
	FuncOpenWindow.super.ctor(self, name, params)

	self.funcID = 0
	self.effect_ = nil
	self.specialGuide = {}
	self.funcID = params.funcID
end

function FuncOpenWindow:initWindow()
	FuncOpenWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
	self:playAction()
end

function FuncOpenWindow:getUIComponent()
	local winTran = self.window_.transform
	local main = winTran:NodeByName("main").gameObject
	self.groupTitle_ = main:NodeByName("groupTitle_").gameObject
	self.imgTop1 = self.groupTitle_:NodeByName("imgTop1").gameObject
	self.imgTop2 = self.groupTitle_:NodeByName("imgTop2").gameObject
	self.imgTitle_ = self.groupTitle_:ComponentByName("imgTitle_", typeof(UISprite))
	self.imgMid = main:ComponentByName("imgMid", typeof(UISprite))
	self.groupBot_ = main:NodeByName("groupBot_").gameObject
	self.imgBot1 = self.groupBot_:NodeByName("imgBot1").gameObject
	self.imgBot2 = self.groupBot_:NodeByName("imgBot2").gameObject
	self.labelName_ = self.groupBot_:ComponentByName("labelName_", typeof(UILabel))
	self.labelDesc_ = main:ComponentByName("labelDesc_", typeof(UILabel))
	self.btnGo_ = main:NodeByName("btnGo_").gameObject
	self.midEffect = main:NodeByName("midEffect").gameObject
	self.specialTouch_ = main:NodeByName("specialTouch_").gameObject
end

function FuncOpenWindow:layout()
	self.btnGo_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self.labelName_.text = FunctionTable:getName(self.funcID)

	if xyd.FunctionID.MISSION == self.funcID then
		self.labelName_.text = __("BP_TITLE")
	end

	local titleSrc = "guide_open_" .. xyd.Global.lang

	xyd.setUISpriteAsync(self.imgTitle_, nil, titleSrc, function ()
		self.imgTitle_:MakePixelPerfect()
	end)

	self.btnGo_:ComponentByName("button_label", typeof(UILabel)).text = __("GO")
	local effect = xyd.Spine.new(self.midEffect)

	effect:setInfo("fx_ui_jingjichang", function ()
		effect:SetLocalScale(1.5, 1.5, 1)
	end)

	self.effect_ = effect

	if xyd.arrayIndexOf(self.specialGuide, self.funcID) >= 0 then
		xyd.setUISpriteAsync(self.imgMid, nil, "guide_girl", function ()
			self.imgMid:MakePixelPerfect()
		end)

		self.labelDesc_.text = __("SPECIAL_GUIDE_TEXT")
	else
		local icon = FunctionTable:getIcon(self.funcID)

		if xyd.FunctionID.MISSION == self.funcID then
			icon = "guide_icon_11_new"
		end

		xyd.setUISpriteAsync(self.imgMid, nil, icon, function ()
			self.imgMid:MakePixelPerfect()
		end)

		self.labelDesc_.text = FunctionTable:getDesc(self.funcID)
	end
end

function FuncOpenWindow:registerEvent()
	UIEventListener.Get(self.btnGo_).onClick = handler(self, self.goTouch)
	UIEventListener.Get(self.specialTouch_).onClick = handler(self, self.goTouch)
end

function FuncOpenWindow:specialTouch()
	self.specialTouch_:SetActive(false)

	if self.specialTouchFunc_ then
		local callback = self.specialTouchFunc_
		self.specialTouchFunc_ = nil

		return callback()
	end

	self:goTouch()
end

function FuncOpenWindow:goTouch()
	if xyd.arrayIndexOf(self.specialGuide, self.funcID) >= 0 then
		xyd.WindowManager.get():closeAllWindows({
			func_open_window = true,
			main_window = true,
			loading_window = true,
			guide_window = true
		}, true)
		self:specialAnimation2()
	else
		xyd.WindowManager.get():closeAllWindows({
			guide_window = true,
			main_window = true,
			loading_window = true
		}, true)
	end
end

function FuncOpenWindow:willClose()
	if self.timer_ then
		self.timer_:Stop()

		self.timer_ = nil
	end

	FuncOpenWindow.super.willClose(self)
end

function FuncOpenWindow:playAction()
	local count = 0
	local flag = xyd.arrayIndexOf(self.specialGuide, self.funcID) >= 0

	local function callback()
		count = count + 1

		if flag then
			self:specialAnimation1(count)
		else
			self:normalAnimation(count)
		end
	end

	local timer = Timer.New(callback, 0.1, 4)

	timer:Start()

	self.timer_ = timer
end

function FuncOpenWindow:specialAnimation1(count)
	if count == 1 then
		self.groupTitle_:SetActive(true)

		local action = self:getSequence()
		local top1W = self.imgTop1:GetComponent(typeof(UIWidget))
		top1W.alpha = 0
		local top1Pos = self.imgTop1.transform.localPosition

		self.imgTop1:SetLocalPosition(top1Pos.x - 10, top1Pos.y, 0)

		local top2W = self.imgTop2:GetComponent(typeof(UIWidget))
		top2W.alpha = 0
		local top2Pos = self.imgTop2.transform.localPosition

		self.imgTop2:SetLocalPosition(top2Pos.x + 10, top2Pos.y, 0)

		local titleW = self.imgTitle_:GetComponent(typeof(UIWidget))
		titleW.alpha = 0

		action:Append(self.imgTop1.transform:DOLocalMove(Vector3(top1Pos.x + 5, top1Pos.y, 0), 0.2)):Join(xyd.getTweenAlpha(top1W, 1, 0.2)):Join(self.imgTop2.transform:DOLocalMove(Vector3(top2Pos.x - 5, top2Pos.y, 0), 0.2)):Join(xyd.getTweenAlpha(top2W, 1, 0.2)):Join(xyd.getTweenAlpha(titleW, 1, 0.2)):Append(self.imgTop1.transform:DOLocalMove(Vector3(top1Pos.x, top1Pos.y, 0), 0.2)):Append(self.imgTop2.transform:DOLocalMove(Vector3(top2Pos.x, top2Pos.y, 0), 0.2)):AppendCallback(function ()
			self.specialTouch_:SetActive(true)
		end)
	end
end

function FuncOpenWindow:specialAnimation2()
	if self.timer_ then
		self.timer_:Stop()

		self.timer_ = nil
	end

	local count = 1

	function self.specialTouchFunc_()
		local win = xyd.WindowManager:get():getWindow("main_window")

		if win then
			local pos = self.imgMid.transform.position

			win:leftFuncOpenAnimation(self.funcID, pos)
		end

		xyd.WindowManager:get():closeWindow(self.name_)
	end

	local function callback()
		count = count + 1

		self:normalAnimation(count)

		if count == 4 then
			self.specialTouch_:SetActive(true)
		end
	end

	self.timer_ = Timer.New(callback, 0.1, 3)

	self.imgMid:SetActive(false)
	self.groupBot_:SetActive(false)
	self.labelDesc_:SetActive(false)
	self.btnGo_:SetActive(false)

	self.labelDesc_.text = FunctionTable:getDesc(self.funcID)
	local icon = FunctionTable:getIcon(self.funcID)

	if xyd.FunctionID.MISSION == self.funcID and xyd.models.activity:getBattlePassId() == xyd.ActivityID.BATTLE_PASS then
		icon = "guide_icon_11_new"
	end

	xyd.setUISpriteAsync(self.imgMid, nil, icon, function ()
		self.imgMid:MakePixelPerfect()
	end)

	local win = xyd.WindowManager:get():getWindow("main_window")
	local pos = self.imgMid.transform.position

	if win then
		win:beforeLeftFuncOpen(self.funcID, pos)
	end

	self.timer_:Start()
end

function FuncOpenWindow:normalAnimation(count)
	if count == 1 then
		self.groupTitle_:SetActive(true)

		local action = self:getSequence()
		local top1W = self.imgTop1:GetComponent(typeof(UIWidget))
		top1W.alpha = 0
		local top1Pos = self.imgTop1.transform.localPosition

		self.imgTop1:SetLocalPosition(top1Pos.x - 10, top1Pos.y, 0)

		local top2W = self.imgTop2:GetComponent(typeof(UIWidget))
		top2W.alpha = 0
		local top2Pos = self.imgTop2.transform.localPosition

		self.imgTop2:SetLocalPosition(top2Pos.x + 10, top2Pos.y, 0)

		local titleW = self.imgTitle_:GetComponent(typeof(UIWidget))
		titleW.alpha = 0

		action:Append(self.imgTop1.transform:DOLocalMove(Vector3(top1Pos.x + 5, top1Pos.y, 0), 0.2)):Join(xyd.getTweenAlpha(top1W, 1, 0.2)):Join(self.imgTop2.transform:DOLocalMove(Vector3(top2Pos.x - 5, top2Pos.y, 0), 0.2)):Join(xyd.getTweenAlpha(top2W, 1, 0.2)):Join(xyd.getTweenAlpha(titleW, 1, 0.2)):Append(self.imgTop1.transform:DOLocalMove(Vector3(top1Pos.x, top1Pos.y, 0), 0.2)):Append(self.imgTop2.transform:DOLocalMove(Vector3(top2Pos.x, top2Pos.y, 0), 0.2))
	elseif count == 2 then
		self.imgMid:SetActive(true)
		self.imgMid:SetLocalScale(0.36, 0.36, 1)
		self.midEffect:SetActive(true)

		local action4 = self:getSequence()
		local midTrans = self.imgMid.transform

		action4:Append(midTrans:DOScale(Vector3(1.2, 1.2, 1), 0.13)):Append(midTrans:DOScale(Vector3(0.9, 0.9, 1), 0.16)):Append(midTrans:DOScale(Vector3(1, 1, 1), 0.16))
		self.effect_:play("texiao01", 1, 1, function ()
			self.effect_:play("texiao02", 0)
		end, true)
	elseif count == 3 then
		self.groupBot_:SetActive(true)

		local action = self:getSequence()
		local top1W = self.imgBot1:GetComponent(typeof(UIWidget))
		top1W.alpha = 0
		local top1Pos = self.imgBot1.transform.localPosition

		self.imgBot1:SetLocalPosition(top1Pos.x - 10, top1Pos.y, 0)

		local top2W = self.imgBot2:GetComponent(typeof(UIWidget))
		top2W.alpha = 0
		local top2Pos = self.imgBot2.transform.localPosition

		self.imgBot2:SetLocalPosition(top2Pos.x + 10, top2Pos.y, 0)

		local titleW = self.labelName_:GetComponent(typeof(UIWidget))
		titleW.alpha = 0

		action:Append(self.imgBot1.transform:DOLocalMove(Vector3(top1Pos.x + 5, top1Pos.y, 0), 0.2)):Join(xyd.getTweenAlpha(top1W, 1, 0.2)):Join(self.imgBot2.transform:DOLocalMove(Vector3(top2Pos.x - 5, top2Pos.y, 0), 0.2)):Join(xyd.getTweenAlpha(top2W, 1, 0.2)):Join(xyd.getTweenAlpha(titleW, 1, 0.2)):Append(self.imgBot1.transform:DOLocalMove(Vector3(top1Pos.x, top1Pos.y, 0), 0.2)):Append(self.imgBot2.transform:DOLocalMove(Vector3(top2Pos.x, top2Pos.y, 0), 0.2))
	elseif count == 4 then
		self.labelDesc_:SetActive(true)

		local titleW = self.labelDesc_:GetComponent(typeof(UIWidget))
		titleW.alpha = 0
		local action = self:getSequence()

		action:Append(xyd.getTweenAlpha(titleW, 1, 0.2))
	end
end

return FuncOpenWindow
