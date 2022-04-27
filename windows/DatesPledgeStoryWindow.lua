local BaseWindow = import(".BaseWindow")
local DatesPledgeStoryWindow = class("DatesPledgeStoryWindow", BaseWindow)
local PartnerPictureTable = xyd.tables.partnerPictureTable
local ParnterImg = import("app.components.PartnerImg")

function DatesPledgeStoryWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.step = 0
	self.textPos = {}
	self.partner = params.partner
	self.isReplayStory = xyd.checkCondition(params.isReplayStory, true, false)
	local files = xyd.getEffectFilesByNames({
		"date_vow01",
		"date_vow02",
		"date_vow03",
		"date_vow04",
		"date_vow05",
		"shuangzi_shiyue"
	})

	if params.show_id then
		self.show_id = params.show_id
	end

	table.insert(files, xyd.SCENE_PATH .. "dates_bg14")

	local picRes = self:getPictureResource()

	table.insert(files, picRes)
	self:setResourcePaths(files)
end

function DatesPledgeStoryWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:adaptX()
	self:layout()
	self:registerEvent()
	self:step1()
end

function DatesPledgeStoryWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.main = winTrans:NodeByName("main").gameObject
	self.bgGroup = self.main:NodeByName("bgGroup").gameObject
	self.bg = self.bgGroup:ComponentByName("bg", typeof(UITexture))
	self.groupDoor = self.bgGroup:NodeByName("groupDoor").gameObject
	local top = self.main:NodeByName("top").gameObject

	for i = 2, 4 do
		local key = "imgHand" .. i
		self[key] = top:NodeByName(key).gameObject
	end

	for i = 4, 7 do
		local key = "imgRing" .. i
		self[key] = top:NodeByName(key).gameObject
	end

	self.groupTip = top:NodeByName("groupTip").gameObject
	self.groupTipEffect = top:NodeByName("groupTipEffect").gameObject
	self.groupEffect = top:NodeByName("groupEffect").gameObject
	self.groupRing = top:NodeByName("groupRing").gameObject
	self.labelTip = self.groupTip:ComponentByName("labelTip", typeof(UILabel))
	local bottom = self.main:NodeByName("bottom").gameObject
	self.imgHand1 = bottom:NodeByName("imgHand1").gameObject
	self.imgRing1 = bottom:NodeByName("imgRing1").gameObject
	self.imgRingBox = bottom:NodeByName("imgRingBox").gameObject
	self.imgRing3 = bottom:NodeByName("imgRing3").gameObject
	self.groupPicture = self.main:NodeByName("groupPicture").gameObject
	self.textGroup = self.groupPicture:NodeByName("textGroup").gameObject
	self.labelName = self.textGroup:ComponentByName("labelName", typeof(UILabel))
	self.labelDialog = self.textGroup:ComponentByName("labelDialog", typeof(UILabel))
	self.imgTouch = self.main:NodeByName("imgTouch").gameObject
	self.bgMask = self.main:NodeByName("bgMask").gameObject
	self.shiyue = self.main:NodeByName("shiyue").gameObject
	self.btnSkipGroup = winTrans:NodeByName("btnSkipGroup").gameObject
	self.btnSkip = self.btnSkipGroup:NodeByName("btnSkip").gameObject
	self.imgPicture = ParnterImg.new(self.groupPicture)
end

function DatesPledgeStoryWindow:adaptX()
	local height = xyd.WindowManager.get():getUIRootHeight()

	if xyd.Global.getMaxHeight() <= height then
		local rect = self.main:GetComponent(typeof(UIRect))

		rect:SetTopAnchor(self.window_, 1, 51)
		rect:SetBottomAnchor(self.window_, 0, -51)
	end
end

function DatesPledgeStoryWindow:registerEvent()
	UIEventListener.Get(self.imgTouch).onClick = handler(self, self.onTouch)

	UIEventListener.Get(self.imgTouch).onDragStart = function ()
		self:onBegin()
	end

	UIEventListener.Get(self.imgTouch).onDrag = function (go, delta)
		self:onMove(delta)
	end

	UIEventListener.Get(self.btnSkip).onClick = handler(self, self.onSkipTouch)

	UIEventListener.Get(self.imgTouch).onDragEnd = function (go)
		self:onEnd()
	end
end

function DatesPledgeStoryWindow:layout()
	self.db01 = xyd.Spine.new(self.groupDoor)
	self.db02 = xyd.Spine.new(self.groupDoor)
	self.db03 = xyd.Spine.new(self.groupTipEffect)
	self.db04 = xyd.Spine.new(self.groupEffect)
	self.db05 = xyd.Spine.new(self.groupRing)
	self.db06 = xyd.Spine.new(self.shiyue)

	self.db01:setInfo("date_vow01", function ()
	end)
	self.db02:setInfo("date_vow01", function ()
		self.db02.spAnim.targetDelta = 1

		self.db01:SetLocalScale(1.25, 1.25, 1)
	end)
	self.db03:setInfo("date_vow02", function ()
	end)
	self.db04:setInfo("date_vow03", function ()
	end)
	self.db05:setInfo("date_vow05", function ()
	end)
	self.db06:setInfo("shuangzi_shiyue", function ()
	end)
	self.db01:SetActive(false)
	self.db02:SetActive(false)
	self.db03:SetActive(false)
	self.db06:SetActive(false)
	self.groupRing:SetActive(false)

	self.delayTime = xyd.Global.lang == "en_en" and 20 or 40

	if self.isReplayStory then
		self.btnSkipGroup:SetActive(true)
	end

	local showID = self:getPartnerShowId()
	showID = showID or self.partner:getTableID()

	self.imgPicture:setImg({
		itemID = showID
	})

	local xy = PartnerPictureTable:getPartnerPicXY(showID)
	local scale = PartnerPictureTable:getPartnerPicScale(showID)

	self.imgPicture:SetLocalPosition(xy.x, -xy.y, 0)
	self.imgPicture:SetLocalScale(scale, scale, 1)
end

function DatesPledgeStoryWindow:onSkipTouch()
	xyd.alert(xyd.AlertType.YES_NO, __("VOW_TEXT_1"), function (yes)
		if yes then
			xyd.closeWindow("dates_pledge_window")
		end
	end)
end

function DatesPledgeStoryWindow:getPictureResource()
	local res = xyd.getPicturePath(nil, self.partner)

	return res
end

function DatesPledgeStoryWindow:initPlayTextEffect(text)
	self.curStr = text
	self.curStrPos = 1
	self.labelDialog.text = ""
	self.labelName.text = self.partner:getName()
end

function DatesPledgeStoryWindow:textEffect()
	local speed = self.delayTime / 1000
	self.curStrList_ = xyd.getColorLabelList(self.curStr)
	local loop = #self.curStrList_
	local timer = self:getTimer(function ()
		self.labelDialog.text = self.labelDialog.text .. self.curStrList_[self.curStrPos]
		self.curStrPos = self.curStrPos + 1
	end, speed, loop)

	timer:Start()

	self.textEffectTimeoutId = timer
end

function DatesPledgeStoryWindow:onBegin()
	self.moveY = 0
end

function DatesPledgeStoryWindow:onTouch()
	if not self.step then
		return
	end

	if self.step == 4 then
		self:step5()
	elseif self.step == 18 then
		self:step20()
	end
end

function DatesPledgeStoryWindow:onMove(delta)
	self.moveY = self.moveY + delta.y
end

function DatesPledgeStoryWindow:onEnd(event)
	if self.moveY > 50 then
		if self.step == 12 then
			self:step13()
		elseif self.step == 23 then
			self:step24()
		elseif self.step == 26 then
			self:step27()
		end
	end

	self.moveY = 0
end

function DatesPledgeStoryWindow:willClose()
	BaseWindow.willClose(self)

	if self.textEffectTimeoutId then
		self.textEffectTimeoutId:Stop()

		self.textEffectTimeoutId = nil
	end
end

function DatesPledgeStoryWindow:step1()
	local sequence = self:getSequence()

	sequence:Append(self.bgGroup.transform:DOScale(Vector3(1.2, 1.2, 1), 3))
	self.db01:SetActive(true)
	self.db02:SetActive(true)
	self.db01:play("texiao01", 1, 1, function ()
		self.db01:SetActive(false)
	end, true)
	self.db02:play("texiao02", 1, 1, function ()
		self.db02:SetActive(false)
	end, true)
	self:waitForTime(3.17, function ()
		self:step2()
	end, "")

	self.step = 1
end

function DatesPledgeStoryWindow:step2()
	xyd.setUITextureAsync(self.bg, xyd.SCENE_PATH .. "dates_bg14")
	self.bgGroup:SetLocalScale(1, 1, 1)
	self:waitForTime(1.67, function ()
		self:step3()
	end, "")

	self.step = 2
end

function DatesPledgeStoryWindow:step3()
	local w = self.groupPicture:GetComponent(typeof(UIWidget))
	w.alpha = 0

	w:SetActive(true)
	xyd.getTweenAlpha(w, 1, 2, self)
	self:waitForTime(2, function ()
		self:step4()
	end, "")

	self.step = 3
end

function DatesPledgeStoryWindow:step4()
	self:initPlayTextEffect(__("VOW_SHOW_HAND"))
	self:textEffect()

	self.step = 4
end

function DatesPledgeStoryWindow:step5()
	self.step = 5

	self.bgMask:SetActive(true)

	local w = self.bgMask:GetComponent(typeof(UIWidget))
	local getter, setter = xyd.getTweenAlphaGeterSeter(w)
	local sequence = self:getSequence()

	sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 1)):AppendCallback(function ()
		self:step6()
	end):Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0, 1))
end

function DatesPledgeStoryWindow:step6()
	self.step = 6

	self.groupPicture:SetActive(false)
	self:waitForTime(1, function ()
		self:step7()
	end, "")
end

function DatesPledgeStoryWindow:step7()
	self.bgMask:SetActive(false)
	self.imgHand1:SetActive(true)
	self.imgRing1:SetActive(true)

	local ringW = self.imgRing1:GetComponent(typeof(UIWidget))
	ringW.alpha = 0
	local handTrans = self.imgHand1.transform
	local ringTrans = self.imgRing1.transform
	local sequence = self:getSequence()

	sequence:Append(handTrans:DOLocalMoveY(0, 2):SetEase(DG.Tweening.Ease.OutQuart)):Append(xyd.getTweenAlpha(ringW, 1, 1.5)):Append(ringTrans:DOLocalMoveY(556, 1.5):SetEase(DG.Tweening.Ease.OutQuart))
	self:waitForTime(5.8, function ()
		self:step8()
	end, "")

	self.step = 7
end

function DatesPledgeStoryWindow:step8()
	self.bgMask:SetActive(true)

	local w = self.bgMask:GetComponent(typeof(UIWidget))
	local getter, setter = xyd.getTweenAlphaGeterSeter(w)
	local sequence = self:getSequence()

	sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 1)):AppendCallback(function ()
		self:step9()
	end):Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0, 1))

	self.step = 8
end

function DatesPledgeStoryWindow:step9()
	self.imgHand1:SetActive(false)
	self.imgRing1:SetActive(false)
	self:waitForTime(1, function ()
		local tableID = self.partner:getTableID()

		if tableID == 55006 or tableID == 655015 or tableID == 755005 then
			self:step22()
		else
			self:step10()
		end
	end, "")

	self.step = 9
end

function DatesPledgeStoryWindow:step22()
	self.db06:SetActive(true)
	self.db06:play("animation", 1, 1, function ()
		self.db06:SetActive(false)
	end, true)
	self:waitForTime(4.8, function ()
		self.db04:SetActive(true)
		self.db04:play("texiao01", 1, 1, function ()
			self:step23()
		end, true)
	end, "")

	self.step = 22
end

function DatesPledgeStoryWindow:step23()
	self.imgHand3:SetActive(true)
	self.imgRing4:SetActive(true)
	self.imgRing5:SetActive(true)
	self.groupTip:SetActive(true)

	self.labelTip.text = __("VOW_TIPS")

	self.db03:SetActive(true)
	self.db03:play("texiao01", 0, 1, nil, true)

	local sequence = self:getSequence()

	sequence:Append(self.imgHand3.transform:DOLocalMoveY(0, 2):SetEase(DG.Tweening.Ease.OutQuart))
	self:waitForTime(3.2, function ()
		self.step = 23
	end, "")
end

function DatesPledgeStoryWindow:step24()
	self.db03:stop()
	self.db03:SetActive(false)

	local sequence = self:getSequence()

	sequence:Append(self.imgRing4.transform:DOLocalMoveY(-452, 2)):Join(self.imgRing5.transform:DOLocalMoveY(-452, 2)):AppendCallback(function ()
		self:step25()
	end)

	self.step = 24
end

function DatesPledgeStoryWindow:step25()
	local sequence = self:getSequence()

	sequence:Append(self.imgHand3.transform:DOLocalMoveY(796, 2)):Join(self.imgRing4.transform:DOLocalMoveY(452, 2)):Join(self.imgRing5.transform:DOLocalMoveY(452, 2)):AppendCallback(function ()
		self.imgHand3:SetActive(false)
		self.imgRing4:SetActive(false)
		self.imgRing5:SetActive(false)
		self.groupTip:SetActive(false)
		self:step26()
	end)

	self.step = 25
end

function DatesPledgeStoryWindow:step26()
	self.imgHand4:SetActive(true)
	self.imgRing6:SetActive(true)
	self.imgRing7:SetActive(true)
	self.groupTip:SetActive(true)
	self.db03:SetActive(true)
	self.db03:play("texiao01", 0, 1, nil, true)

	local sequence = self:getSequence()

	sequence:Append(self.imgHand4.transform:DOLocalMoveY(0, 2):SetEase(DG.Tweening.Ease.OutQuart))
	self:waitForTime(3.2, function ()
		self.step = 26
	end, "")
end

function DatesPledgeStoryWindow:step27()
	self.db03:stop()
	self.db03:SetActive(false)

	local sequence = self:getSequence()

	sequence:Append(self.imgRing6.transform:DOLocalMoveY(-452, 2)):Join(self.imgRing7.transform:DOLocalMoveY(-452, 2)):AppendCallback(function ()
		self:step28()
	end)

	self.step = 27
end

function DatesPledgeStoryWindow:step28()
	self.db04:SetActive(true)
	self.db04:play("texiao01", 1, 1, nil, true)
	self:waitForTime(2.67, function ()
		self.imgHand4:SetActive(false)
		self.imgRing6:SetActive(false)
		self.imgRing7:SetActive(false)
		self.groupTip:SetActive(false)
		self:step15()
	end, "")

	self.step = 28
end

function DatesPledgeStoryWindow:step10()
	self.imgRingBox:SetActive(true)
	self.imgRing3:SetActive(true)
	self.imgHand2:SetActive(true)

	local showID = self:getPartnerShowId()
	showID = showID or self.partner:getTableID()
	local hand_type = PartnerPictureTable:getHandType(showID)

	if hand_type == 2 then
		xyd.setUISpriteAsync(self.imgHand2:GetComponent(typeof(UISprite)), nil, "dates_icon50")
	end

	local boxW = self.imgRingBox:GetComponent(typeof(UIWidget))
	local ring3W = self.imgRing3:GetComponent(typeof(UIWidget))
	boxW.alpha = 0
	ring3W.alpha = 0
	local sequence = self:getSequence()

	sequence:Append(self.imgHand2.transform:DOLocalMoveY(0, 2):SetEase(DG.Tweening.Ease.OutQuart)):AppendInterval(0.5):Append(xyd.getTweenAlpha(boxW, 1, 1.5)):Join(xyd.getTweenAlpha(ring3W, 1, 1.5)):Append(xyd.getTweenAlpha(ring3W, 0, 1))
	self:waitForTime(4.5, function ()
		self:step11()
	end, "")

	self.step = 10
end

function DatesPledgeStoryWindow:step11()
	self.groupRing:SetActive(true)
	self.imgRing3:SetActive(false)

	local ringW = self.groupRing:GetComponent(typeof(UIWidget))
	ringW.alpha = 0

	self.db05:play("texiao01", 0, 1, nil, true)
	xyd.getTweenAlpha(ringW, 1, 1.5, self)
	self:waitForTime(1.5, function ()
		self:step12()
	end, "")

	self.step = 11
end

function DatesPledgeStoryWindow:step12()
	self.groupTip:SetActive(true)

	self.labelTip.text = __("VOW_TIPS")
	local tipW = self.groupTip:GetComponent(typeof(UIWidget))
	tipW.alpha = 0

	self.db05:play("texiao01", 0, 1, nil, true)
	xyd.getTweenAlpha(tipW, 1, 1.2, self)
	self.db03:play("texiao01", 0, 1, nil, true)
	self.db03:SetActive(true)
	self:waitForTime(1.2, function ()
		self.step = 12
	end, "")
end

function DatesPledgeStoryWindow:step13()
	self.db03:stop()
	self.db03:SetActive(false)

	local y = -473
	local showID = self:getPartnerShowId()
	showID = showID or self.partner:getTableID()

	self.imgPicture:setImg({
		itemID = showID
	})

	local hand_type = PartnerPictureTable:getHandType(showID)

	if hand_type == 2 then
		y = y + 60
	end

	local sequence = self:getSequence()

	sequence:Append(self.groupRing.transform:DOLocalMoveY(y, 1.5):SetEase(DG.Tweening.Ease.OutQuart))
	self:waitForTime(1.5, function ()
		self:step14()
	end, "")

	self.step = 13
end

function DatesPledgeStoryWindow:step14()
	local showID = self:getPartnerShowId()
	showID = showID or self.partner:getTableID()

	self.imgPicture:setImg({
		itemID = showID
	})

	local hand_type = PartnerPictureTable:getHandType(showID)

	if hand_type == 2 then
		self.db04:SetLocalPosition(0, 60, 0)
	end

	self.db04:play("texiao01", 1, 1, nil, true)
	self.db04:SetActive(true)
	self:waitForTime(2.67, function ()
		self:step15()
	end, "")

	self.step = 14
end

function DatesPledgeStoryWindow:step15()
	self.imgHand2:SetActive(false)
	self.groupRing:SetActive(false)
	self.imgRingBox:SetActive(false)
	self.groupTip:SetActive(false)
	self.db05:stop()

	if self.partner:getWeddingSkin() > 0 then
		self:step16()
	else
		self:step17()
	end

	self.step = 15
end

function DatesPledgeStoryWindow:step16()
	self.groupPicture:SetActive(true)

	local dialog = xyd.tables.partnerTable:getVowDialog(self.partner:getTableID())
	local text = dialog.dialog or " "
	self.curStrPos = 1

	self:playTextFlowEffect(text)
	self:waitForTime(0.6, function ()
		self:step18()
	end, "")

	self.step = 16

	xyd.SoundManager.get():playSound(xyd.tables.partnerTable:getVowSound(self.partner:getTableID()))
end

function DatesPledgeStoryWindow:playTextFlowEffect(text)
	self.labelName.text = self.partner:getName()
	self.labelDialog.text = ""
	local speed = self.delayTime / 1000
	self.curStrList_ = xyd.getColorLabelList(text)
	local loop = #self.curStrList_
	local timer = self:getTimer(function ()
		self.labelDialog.text = self.labelDialog.text .. self.curStrList_[self.curStrPos]
		self.curStrPos = self.curStrPos + 1
	end, speed, loop)

	timer:Start()

	self.textEffectTimeoutId = timer
end

function DatesPledgeStoryWindow:step17()
	self.groupPicture:SetActive(true)
	self.textGroup:SetActive(false)
	self:waitForTime(2.5, function ()
		self:step19()
	end, "")

	self.step = 17
end

function DatesPledgeStoryWindow:step18()
	if not self.isReplayStory then
		self.groupTip:SetActive(true)

		self.labelTip.text = __("VOW_SKIN_TIPS")
		local tipW = self.groupTip:GetComponent(typeof(UIWidget))
		tipW.alpha = 0

		xyd.getTweenAlpha(tipW, 1, 1.2, self)
	end

	self.step = 18
end

function DatesPledgeStoryWindow:step20()
	local sequence = self:getSequence()
	local tipW = self.groupTip:GetComponent(typeof(UIWidget))
	local picW = self.groupPicture:GetComponent(typeof(UIWidget))

	sequence:Append(xyd.getTweenAlpha(tipW, 0, 1)):Join(xyd.getTweenAlpha(picW, 0, 1))

	self.step = 20

	self:waitForTime(1, function ()
		self:step21()
	end, "")
end

function DatesPledgeStoryWindow:step19()
	local picW = self.groupPicture:GetComponent(typeof(UIWidget))

	xyd.getTweenAlpha(picW, 0, 1, self)

	self.step = 20

	self:waitForTime(1, function ()
		self:step21()
	end, "")
end

function DatesPledgeStoryWindow:step21()
	self.step = 20
	local wnd = xyd.WindowManager:get():getWindow("dates_pledge_window")

	if wnd then
		wnd.canReplayPledgeAnimation = false

		wnd:showAnimation()
	end

	local datesWnd = xyd.WindowManager:get():getWindow("dates_window")

	if datesWnd then
		datesWnd:updateBg(false)
	end

	local partnerWnd = xyd.WindowManager:get():getWindow("partner_detail_window")

	if partnerWnd then
		partnerWnd:updateBg()
	end
end

function DatesPledgeStoryWindow:getPartnerShowId()
	local backId = self.partner:getShowID()

	if self.show_id then
		backId = self.show_id
	end

	return backId
end

return DatesPledgeStoryWindow
