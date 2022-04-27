local FloatMessageWindow = class("FloatMessageWindow", import(".BaseWindow"))
local Chat = xyd.models.chat

function FloatMessageWindow:ctor(name, params)
	FloatMessageWindow.super.ctor(self, name, params)

	self.curIcon_ = 1
end

function FloatMessageWindow:getUIComponents()
	local go = self.window_
	self.groupMain = go:NodeByName("groupMain").gameObject
	self.imgIcon = self.groupMain:ComponentByName("imgIcon", typeof(UISprite))
	self.groupText = self.groupMain:NodeByName("groupText").gameObject
	self.labelText = self.groupMain:ComponentByName("groupText/labelText", typeof(UILabel))
	self.goBtn = self.groupMain:ComponentByName("goBtn", typeof(UISprite))
end

function FloatMessageWindow:initWindow()
	FloatMessageWindow.super.initWindow(self)
	self:getUIComponents()

	self.window_:GetComponent(typeof(UIPanel)).depth = xyd.UILayerDepth.MAX - 2
	self.groupText:GetComponent(typeof(UIPanel)).depth = xyd.UILayerDepth.MAX - 1
	local trans = self.groupMain.transform.localPosition
	local y = math.min(xyd.Global:getMaxBgHeight(), UnityEngine.Screen.height) / 2 - 180
	y = UnityEngine.Screen.height / UnityEngine.Screen.width < 1.9444444444444444 and 460 or 599.5

	self.groupMain:SetLocalPosition(trans.x, y, trans.z)
	xyd.setUISpriteAsync(self.goBtn, nil, "float_message_btn_" .. xyd.Global.lang)
end

function FloatMessageWindow:setText(params)
	local text = params.content
	self.text = params.content
	local href = string.find(text, "<a href") or -1
	local font = string.find(text, "<font") or -1
	local content1 = string.gsub(text, "<font color=0x(%w+)>", "[%1]")
	local content2 = string.gsub(content1, "</font>", "[-]")
	local content3 = string.gsub(text, "<a href=\"(.+)\">", "[url=%1]")
	local content4 = string.gsub(text, "</a>", "[/u]")

	if href > -1 or font > -1 then
		self.labelText.text = content4
	else
		self.labelText.text = text
	end
end

function FloatMessageWindow:setUIComponent(params)
	if params.goto_type and params.goto_val then
		self.goBtn:SetActive(true)

		self.groupText:GetComponent(typeof(UIPanel)).baseClipRegion = Vector4(0, 0, 462, 42)

		self.groupText:X(-15)
		self.labelText:X(-228)

		self.params = params
		UIEventListener.Get(self.goBtn.gameObject).onClick = handler(self, self.onWindowGo)
	else
		self.goBtn:SetActive(false)

		self.groupText:GetComponent(typeof(UIPanel)).baseClipRegion = Vector4(0, 0, 510, 42)

		self.groupText:X(0)
		self.labelText:X(-255)

		self.params = nil
	end
end

function FloatMessageWindow:onWindowGo()
	local windowGoId = self:getWindowGoId(self.params.goto_type, self.params.goto_val)

	if not windowGoId or windowGoId < 0 then
		return
	end

	local windowGoTable = xyd.tables.windowGoTable
	local windowName = windowGoTable:getWindowName(windowGoId)
	local params = windowGoTable:getParams(windowGoId)
	local funcId = windowGoTable:getFunctionId(windowGoId)
	local activityId = windowGoTable:getActivityId(windowGoId)

	self:checkAndOpen(windowName, params, funcId, activityId)
end

function FloatMessageWindow:getWindowGoId(type, value)
	local windowGoOperationMapTable = xyd.tables.windowGoOperationMapTable
	local ids = windowGoOperationMapTable:getIds()

	for i = 1, #ids do
		local id = ids[i]

		if windowGoOperationMapTable:getType(id) == tonumber(type) and windowGoOperationMapTable:getValue(id) == tonumber(value) then
			return windowGoOperationMapTable:getWindowGoId(id)
		end
	end

	return -1
end

function FloatMessageWindow:checkAndOpen(winName, params, funID, activityId)
	if funID and funID > 0 and not xyd.checkFunctionOpen(funID) then
		return
	end

	if activityId and not xyd.models.activity:isOpen(activityId) then
		xyd.showToast(__("ACTIVITY_OPEN_TEXT"))

		return
	end

	if activityId == xyd.ActivityID.KAKAOPAY then
		local msg = messages_pb.log_partner_data_touch_req()
		msg.touch_id = xyd.DaDian.KAKAOPAY_MAIL_JUMP

		xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
	end

	local win = xyd.WindowManager.get():getWindow(winName)

	if win then
		xyd.WindowManager.get():closeWindow(winName, function ()
			xyd.openWindow(winName, params)
		end)

		return
	end

	xyd.WindowManager.get():openWindow(winName, params)
end

function FloatMessageWindow:playIconAction()
	if not self.iconTimer_ then
		self.iconTimer_ = self:getTimer(handler(self, self.changeIcon), 0.5, -1)

		self.iconTimer_:Start()
	end
end

function FloatMessageWindow:stopIconTimer()
	if self.iconTimer_ then
		self.iconTimer_:Stop()

		self.iconTimer_ = nil
	end
end

function FloatMessageWindow:changeIcon()
	if self.curIcon_ == 1 then
		xyd.setUISpriteAsync(self.imgIcon, nil, "floag_message_icon02")

		self.curIcon_ = 0
	else
		xyd.setUISpriteAsync(self.imgIcon, nil, "float_message_icon01")

		self.curIcon_ = 1
	end
end

function FloatMessageWindow:playExitAnimation()
	local function setter(value)
		self.groupMain:GetComponent(typeof(UIWidget)).alpha = value
	end

	local action = self:getSequence(function ()
		self.groupMain:SetActive(false)
		self:stopIconTimer()
	end)

	action:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0.01, 0.2))
end

function FloatMessageWindow:playEnterAnimation()
	self:setDepth()
	self.labelText:SetActive(false)
	self.groupMain:SetActive(true)

	local function setter(value)
		self.groupMain:GetComponent(typeof(UIWidget)).alpha = value
	end

	local action = self:getSequence(function ()
		self:textAnimation()
	end)

	action:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0.01, 1, 0.2))
	self:playIconAction()
end

function FloatMessageWindow:setDepth()
	self.window_:GetComponent(typeof(UIPanel)).depth = xyd.UILayerDepth.MAX - 2
	self.groupText:GetComponent(typeof(UIPanel)).depth = xyd.UILayerDepth.MAX - 1
end

function FloatMessageWindow:textAnimation()
	self.labelText.transform:SetLocalPosition(255, 0, 0)

	local action = self:getSequence(function ()
		xyd.models.floatMessage:setNotice(false)
		self.labelText:SetActive(false)
		self:nextMessage()
	end)
	local w = self.labelText.width
	local t = (255 + w + 10) / 100

	action:Append(self.labelText.transform:DOLocalMove(Vector3(-w - 255 - 10, 0, 0), t))
	self.labelText:SetActive(true)
end

function FloatMessageWindow:nextMessage()
	if xyd.models.floatMessage:getNotice() then
		return
	end

	local popText = Chat:popNotice()

	if not popText then
		self:playExitAnimation()

		return
	end

	xyd.models.floatMessage:setNotice(true)
	self:setText(popText)
	self:textAnimation()
end

return FloatMessageWindow
