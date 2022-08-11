local FloatMessageWindow2 = class("FloatMessageWindow2", import(".BaseWindow"))

function FloatMessageWindow2:ctor(name, params)
	FloatMessageWindow2.super.ctor(self, name, params)

	self.curIcon_ = 1
	self.hasInited = false
end

function FloatMessageWindow2:initWindow()
	FloatMessageWindow2.super.initWindow(self)

	self.window_:GetComponent(typeof(UIPanel)).depth = xyd.UILayerDepth.MAX - 2

	self:getUIComponents()

	self.groupTextPanel:GetComponent(typeof(UIPanel)).depth = xyd.UILayerDepth.MAX - 1
	self.hasInited = true
end

function FloatMessageWindow2:getUIComponents()
	local go = self.window_
	self.groupMain = go:NodeByName("groupMain_").gameObject
	self.imgIcon = self.groupMain:ComponentByName("imgIcon", typeof(UISprite))
	self.groupTextPanel = self.groupMain:NodeByName("groupTextPanel").gameObject
	self.groupText = self.groupMain:NodeByName("groupTextPanel/groupText").gameObject
	local trans = self.groupMain.transform.localPosition
	local y = math.min(xyd.Global:getMaxBgHeight(), UnityEngine.Screen.height) / 2 - 180
	y = UnityEngine.Screen.height / UnityEngine.Screen.width < 1.9444444444444444 and 460 or 599.5

	self.groupMain:SetLocalPosition(trans.x, y, trans.z)
end

function FloatMessageWindow2:playEnterAnimation()
	local target = self.groupMain

	target:SetActive(true)

	local action = self:getSequence(function ()
		self:textAnimation()
	end)

	local function setter(value)
		self.groupMain:GetComponent(typeof(UIWidget)).alpha = value
	end

	action:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0.01, 1, 0.2))
	self:playIconAction()
end

function FloatMessageWindow2:nextMessage()
	self:textAnimation(true)
end

function FloatMessageWindow2:getNextNotice()
	local notices = xyd.models.floatMessage2.notices_
	local res = notices[1]
	xyd.models.floatMessage2.notices_ = xyd.tableShift(notices)

	return res
end

function FloatMessageWindow2:textAnimation(flag)
	if flag == nil then
		flag = false
	end

	self.count_ = 0

	if not self.timer_ then
		self.timer_ = self:getTimer(handler(self, self.onTimer), 1, -1)

		self.timer_:Start()
	end

	local data = self:getNextNotice()

	self:showText(data, flag)
end

function FloatMessageWindow2:playExitAnimation()
	local target = self.groupMain
	xyd.models.floatMessage2.isShowNotice = false
	target:GetComponent(typeof(UIWidget)).alpha = 1
	local action = self:getSequence(function ()
		target:SetActive(false)
		self:clearLabel()
		self:stopIconTimer()
	end)

	local function setter(value)
		target:GetComponent(typeof(UIWidget)).alpha = value
	end

	action:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0.01, 0.2))

	if self.timer_ then
		self.timer_:Stop()

		self.timer_ = nil
	end

	if self.curAction_ then
		self.curAction_:Kill()

		self.curAction_ = nil
	end
end

function FloatMessageWindow2:setDepth()
	if self.hasInited then
		self.window_:GetComponent(typeof(UIPanel)).depth = xyd.UILayerDepth.MAX - 2
		self.groupTextPanel:GetComponent(typeof(UIPanel)).depth = xyd.UILayerDepth.MAX - 1
	end
end

function FloatMessageWindow2:onTimer()
	self.count_ = self.count_ + 1

	if self.count_ > 1 and #xyd.models.floatMessage2.notices_ > 0 then
		self:nextMessage()

		return
	elseif self.count_ >= 5 then
		self.count_ = 0

		self:playExitAnimation()
	end
end

function FloatMessageWindow2:getTarget()
	return self.groupMain_
end

function FloatMessageWindow2:clearLabel()
	NGUITools.DestroyChildren(self.groupText.transform)

	self.curLabel_ = nil
	self.replaceLabel_ = nil
end

function FloatMessageWindow2:getText(data)
	local label = xyd.getLabel({
		s = 20,
		uiRoot = self.groupText
	})
	label.overflowMethod = UILabel.Overflow.ResizeFreely
	local str = xyd.tables.noticeTextTable:getDesc(data.broadcast_type)
	local text = nil

	if data.broadcast_type == xyd.SysBroadcast.ACTIVITY_EXPEDITION then
		local cellID = data.table_id
		local groupID = data.player_id
		local groupName = __("ARCTIC_EXPEDITION_GROUP_" .. groupID)
		local cellPos = xyd.tables.arcticExpeditionCellsTable:getCellPos(cellID)
		local cellType = xyd.tables.arcticExpeditionCellsTable:getCellType(cellID)
		local cellName = xyd.tables.arcticExpeditionCellsTypeTable:getCellName(cellType)
		local x = cellPos[1]
		local y = cellPos[2]
		cellName = cellName .. "(" .. x .. " , " .. y .. ")"
		text = xyd.stringFormat(str, groupName, data.player_name, cellName)
	elseif data.broadcast_type == xyd.SysBroadcast.ACTIVITY_GOLDFISH then
		text = xyd.stringFormat(str, data.player_name, data.table_id)
	else
		local itemName = xyd.tables.itemTable:getName(data.table_id)
		text = xyd.stringFormat(str, data.player_name, itemName)
	end

	local href = string.find(text, "<a href") or -1
	local font = string.find(text, "<font") or -1
	local content1 = string.gsub(text, "<font color=0x(%w+)>", "[%1]")
	local content2 = string.gsub(content1, "</font>", "")
	local content3 = string.gsub(text, "<a href=\"(.+)\">", "[url=%1]")
	local content4 = string.gsub(text, "</a>", "[/u]")
	local content5 = string.gsub(content4, " stroke=(%w+)", "")
	local content6, content7, content8, content9 = nil

	if UNITY_ANDROID and XYDUtils.CompVersion(UnityEngine.Application.version, xyd.ANDROID_1_1_64) <= 0 then
		content6 = string.gsub(content5, " strokecolor=0x(%w+)", "")
		content7 = string.gsub(content6, " strokeColor=0x(%w+)", "")
		content8 = string.gsub(content7, "%[0x(%w+)", "%[%1")
		content9 = content8
	else
		content6 = string.gsub(content5, " strokecolor=0x(%w+)", "][sc][%1")
		content7 = string.gsub(content6, " strokeColor=0x(%w+)", "][sc][%1")
		content8 = string.gsub(content7, "%[0x(%w+)", "%[%1")
		content9 = string.gsub(content8, "%[%-]", "[-][/sc]")
	end

	label.text = content9

	label:SetLocalPosition((label.width - 510) / 2, 0, 0)

	return label
end

function FloatMessageWindow2:showText(data, flag)
	if not self.curLabel_ then
		self.curLabel_ = self:getText(data)

		self:playScroll()

		return
	end

	if flag then
		self:playReplace(data)
	end
end

function FloatMessageWindow2:playIconAction()
	if not self.iconTimer_ then
		self.iconTimer_ = self:getTimer(handler(self, self.changeIcon), 0.5, -1)

		self.iconTimer_:Start()
	end
end

function FloatMessageWindow2:stopIconTimer()
	if self.iconTimer_ then
		self.iconTimer_:Stop()

		self.iconTimer_ = nil
	end
end

function FloatMessageWindow2:changeIcon()
	if self.curIcon_ == 1 then
		self.curIcon_ = 0

		xyd.setUISpriteAsync(self.imgIcon, nil, "float_message_icon02")
	else
		self.curIcon_ = 1

		xyd.setUISpriteAsync(self.imgIcon, nil, "float_message_icon01")
	end
end

function FloatMessageWindow2:playScroll()
	if not self.curLabel_ then
		return
	end

	local width = self.curLabel_.width

	if self.curAction_ then
		self.curAction_:Kill()

		self.curAction_ = nil
	end

	if width > 510 then
		local action = self:getSequence()
		local t = (width - 510) / 100

		action:Append(self.curLabel_.transform:DOLocalMove(Vector3(-(width - 510) / 2, 0, 0), t))

		self.curAction_ = action
	end
end

function FloatMessageWindow2:playReplace(text)
	if not self.replaceLabel_ then
		self.replaceLabel_ = self:getText(text)
	end

	if self.curAction_ then
		self.curAction_:Kill()

		self.curAction_ = nil
	end

	self.replaceLabel_.transform.localPosition.y = -40
	local action = self:getSequence()
	local pos = self.curLabel_.transform.localPosition

	action:Append(self.curLabel_.transform:DOLocalMove(Vector3(pos.x, 40, 0), 0.5))

	local action2 = self:getSequence(function ()
		if self.curLabel_ then
			NGUITools.Destroy(self.curLabel_.gameObject)
		end

		self.curLabel_ = self.replaceLabel_
		self.replaceLabel_ = nil

		self:playScroll()
	end)

	action2:Append(self.replaceLabel_.transform:DOLocalMove(Vector3(pos.x, 0, 0), 0.5))
end

function FloatMessageWindow2:willClose()
	FloatMessageWindow2.super.willClose(self)

	if self.timer_ then
		self.timer_:Stop()

		self.timer_ = nil
	end
end

return FloatMessageWindow2
