local GuideWindow = class("GuideWindow", import(".BaseWindow"))
local GuideMaskBackgroud = import("app.components.GuideMaskBackgroud")
local GuideMask = import("app.components.GuideMask")
local GuideTable = xyd.tables.guideTable

function GuideWindow:ctor(name, params)
	GuideWindow.super.ctor(self, name, params)

	self.timers_ = {}
	self.timeKey_ = {}
	self.isLevUpHide_ = false
	self.isLevUpHide2_ = false
	self.isGuideHide_ = false
	self.sound_ = 0
	self.lastQuanTime_ = 0
	self.labelCount1_ = 0
	self.labelCount2_ = 0
	self.lanSpeed_ = 1
	self.iphoneXFixY = 0
	self.wnd_ = params.wnd
	self.guideID = params.guideID
end

function GuideWindow:initWindow()
	GuideWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:preLoadRes()
end

function GuideWindow:update(params)
	GuideWindow.super.update(self, params)
	self:clearAction()

	self.wnd_ = params.wnd
	self.guideID = params.guideID

	self:resetWnd()
	self:layout()
end

function GuideWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupMain_ = winTrans:NodeByName("groupMain_").gameObject
	self.groupDialog_ = winTrans:NodeByName("groupDialog_").gameObject
	self.maskImage_ = winTrans:ComponentByName("maskImage_", typeof(UISprite))
	self.imgHand_ = self.groupMain_:ComponentByName("imgHand_", typeof(UISprite))
	self.groupDialog1 = self.groupDialog_:NodeByName("groupDialog1").gameObject
	self.groupDialog2 = self.groupDialog_:NodeByName("groupDialog2").gameObject
	self.imgGirl_ = self.groupDialog_:NodeByName("imgGirl_").gameObject
	self.labelDesc1 = self.groupDialog1:ComponentByName("labelDesc1", typeof(UILabel))
	self.labelDesc2 = self.groupDialog2:ComponentByName("labelDesc2", typeof(UILabel))
	self.imgTrangle_ = self.groupDialog2:NodeByName("imgTrangle_").gameObject
	self.guideMaskNode = winTrans:NodeByName("guideMask").gameObject
	self.dialogTouch = winTrans:NodeByName("dialogTouch").gameObject
	self.newGirl = winTrans:NodeByName("newGirl").gameObject
	self.mapBg = self.newGirl:ComponentByName("mapBg", typeof(UITexture))
	self.bgImgGirl = self.newGirl:ComponentByName("imgGirl", typeof(UITexture))
	self.groupQuan = winTrans:NodeByName("groupQuan").gameObject
	self.guideIdText = winTrans:ComponentByName("guideIdText", typeof(UILabel))

	if xyd.isH5() then
		xyd.setUISprite(self.imgGirl_:GetComponent(typeof(UISprite)), nil, "guide_girl_h5")
	end
end

function GuideWindow:resetWnd()
	if self.mask_ then
		self.mask_:destroy()
	end

	if self.guideMask_ then
		self.guideMask_:SetActive(false)
		self.guideMask_:setTouchEnable(true)
	end

	self.maskImage_:SetActive(true)

	self.maskImage_.color = Color.New2(4294967043.0)

	self.newGirl:SetActive(false)
	self.groupMain_:SetActive(false)
	self.groupDialog_:SetActive(false)
	self.dialogTouch:SetActive(false)

	UIEventListener.Get(self.maskImage_.gameObject).onClick = nil
	UIEventListener.Get(self.dialogTouch).onClick = nil
end

function GuideWindow:didOpen()
	GuideWindow.super.didOpen(self)

	if self.guideID == 1 then
		local ani = self.window_:GetComponent(typeof(UnityEngine.Animation))

		ani:Play("firstGuideAni")
	end
end

function GuideWindow:specialFunc()
	local specialFunc_ = GuideTable:specialFunc(self.guideID)

	if specialFunc_ == "showGuide" then
		self.wnd_:showGuide(self.guideID)
	elseif specialFunc_ == "hideGuide" then
		self.isGuideHide_ = true

		self.window_:SetActive(false)
	elseif specialFunc_ == "battleTip" then
		self.isGuideHide_ = true

		self.window_:SetActive(false)
		self.wnd_:showGuideHand()
	end
end

function GuideWindow:layout()
	self:initPause()
	self:specialFunc()

	if self:checkLoadingWindow() then
		return
	end

	if self:checkLevUpWindow() then
		return
	end

	if not self:checkWndComplete() then
		return
	end

	self.guideIdText.text = self.guideID

	self.window_:SetActive(true)
	self:specialFunc()

	local delay = GuideTable:getDelay(self.guideID)
	delay = xyd.checkCondition(delay > 0, delay, 0)

	local function callback()
		if GuideTable:isTransition(self.guideID) then
			self.maskImage_.color = Color.New2(4294967218.0)
		end

		self:initGuide()
	end

	if delay > 0 then
		XYDCo.WaitForTime(delay, callback, "guide_wait_for_init")
	else
		callback()
	end

	table.insert(self.timeKey_, "guide_wait_for_time")
end

function GuideWindow:initGuide()
	if not tolua.isnull(self.window_) then
		self:initObj()
		self:initHand()
		self:initMask()
		self:initDialog()
		self:playAction()
		self:initDuration()
		self:registerEvent()
	end
end

function GuideWindow:checkLoadingWindow()
	local wnd = xyd.getWindow("loading_window")

	return false
end

function GuideWindow:checkWndComplete()
	local flag = self.wnd_:isWndComplete()

	if not flag then
		local timer = nil

		local function callback()
			if self.wnd_:isWndComplete() then
				timer:Stop()
				self:clearAction()
				self:layout()
			end
		end

		timer = Timer.New(callback, 0.1, -1)

		timer:Start()
		table.insert(self.timers_, timer)
	end

	return flag
end

function GuideWindow:checkLevUpWindow()
	local isOpen = xyd.WindowManager.get():isOpen("person_lev_up_window")

	return false
end

function GuideWindow:initObj()
	local id = self.guideID
	local objType = GuideTable:getObjType(id)
	local objID = GuideTable:getObjID(id)
	local obj = self:getObj(objType, objID)

	if obj and not GuideTable:noCilck(id) then
		UIEventListener.Get(obj.gameObject).guideClick = handler(self, self.onObjClick)
	end

	if obj then
		local collider = obj:GetComponent(typeof(UnityEngine.BoxCollider))

		if collider then
			collider.enabled = true
		end
	end

	self.obj = obj
end

function GuideWindow:getObj(objType, objID)
	local obj = nil

	if objType == 1 then
		local objP = self.wnd_[objID[1]]
		obj = objP:NodeByName(objID[2]).gameObject
	elseif objType == 2 then
		local objP = self.wnd_[objID[1]]
		local objP2 = objP[objID[2]]
		obj = objP2:NodeByName(objID[3]).gameObject
	elseif objType == 3 then
		local objP = self.wnd_[objID[1]]
		local objP2 = objP:NodeByName(objID[2]).gameObject
		obj = objP2[objID[3]]
	elseif objType == 4 then
		local objP = self.wnd_[objID[1]]
		obj = objP[objID[2]]
	elseif objType == 5 then
		local objP = self.wnd_:NodeByName(objID[1]).gameObject
		obj = objP[objID[2]]
	elseif objType == 6 then
		obj = self.wnd_.window_
	elseif objType == 7 then
		local objP = self.wnd_[objID[1]][objID[2]]
		obj = objP[objID[3]]
	else
		dump("............................................")
		dump(objID)

		if objID[1] ~= nil and objID[1] ~= "" and objID[1] ~= "-1" then
			dump("............................................" .. objID[1])

			obj = self.wnd_[objID[1]]

			dump(obj)
			dump(type(obj))
		end
	end

	if obj and type(obj) == "table" then
		obj = obj:getGameObject()
	end

	return obj
end

function GuideWindow:onObjClick()
	xyd.GuideController.get():completeOneGuide(self.guideID)
end

function GuideWindow:initHand()
	if self.obj then
		local handType = GuideTable:handType(self.guideID)

		self.groupMain_:SetActive(true)

		local pos = self.obj.transform.position
		local tmpPos = self.window_.transform:InverseTransformPoint(pos)
		local x_ = tmpPos.x
		local y_ = tmpPos.y

		self.groupMain_:SetLocalPosition(x_, y_, 0)

		if handType[1] == 1 then
			local function moveAction()
				local action = DG.Tweening.DOTween.Sequence()
				self.imgHand_.color = Color.New2(4294967295.0)

				self.imgHand_:SetActive(true)
				self.imgHand_:SetLocalPosition(76, -178, 0)
				action:Append(self.imgHand_.transform:DOLocalMove(Vector3(76, -178 - handType[2], 0), 0.5)):Append(xyd.getTweenAlpha(self.imgHand_, 0, 0.1))
			end

			local timer = Timer.New(moveAction, 2, 0)

			timer:Start()
			moveAction()
			table.insert(self.timers_, timer)
		elseif GuideTable:getObjType(self.guideID) ~= 6 then
			local hand = xyd.Spine.new(self.groupMain_)

			hand:setInfo("fx_ui_dianji", function ()
				local fingerFlip = GuideTable:getFingerFlip(self.guideID)
				local scaleX = 1.1
				local scaleY = 1.1
				local y_ = 0
				local x_ = 0

				if fingerFlip == 1 then
					local trans = hand:getGameObject().transform
					trans.localEulerAngles = Vector3(0, 0, 90)
					y_ = 0
				elseif fingerFlip == 2 then
					scaleX = -1.1
					x_ = 0
				elseif fingerFlip == 3 then
					scaleY = -1.1
					scaleX = -1.1
				end

				hand:SetLocalScale(scaleX, scaleY, 1)
				hand:SetLocalPosition(x_, y_, 0)
				hand:setRenderTarget(self.groupMain_:GetComponent(typeof(UIWidget)), 1)
				hand:play("texiao01", 0)
			end)

			self.spineHand_ = hand

			self.imgHand_:SetActive(false)
		end

		return
	end

	self.groupMain_:SetActive(false)
end

function GuideWindow:showClickQuan()
	if os.time() - self.lastQuanTime_ < 3 then
		return
	end

	self.lastQuanTime_ = os.time()

	if self.quan_ then
		self.groupQuan:SetLocalPosition(self.groupMain_:X(), self.groupMain_:Y(), 0)
		self.quan_:play("texiao01", 1, 1, nil, true)

		return
	end

	local quan = xyd.Spine.new(self.groupQuan)

	quan:setInfo("fx_ui_quan", function ()
		quan:play("texiao01", 1, 1)
	end)

	self.quan_ = quan

	self.groupQuan:SetLocalPosition(self.groupMain_:X(), self.groupMain_:Y(), 0)
end

function GuideWindow:onTouch()
	dump("cccccccccccccccccconTouch")

	if GuideTable:getSoft(self.guideID) then
		xyd.GuideController.get():saveSoftByClose(self.guideID)
		xyd.closeWindow(self.name_)

		return
	end

	if self.maskImageClick then
		dump("cccccccccccccccccconTouchmaskImageClick ")

		local callback = self.maskImageClick
		self.maskImageClick = nil

		callback()

		return
	end

	if self.obj then
		if self.isShowLastLabel_ then
			self:showClickQuan()
		else
			self:showLastLabel()
		end
	end
end

function GuideWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GUIDE_NODE_CHANGE, self.onGuideNodeChange, self)

	UIEventListener.Get(self.maskImage_.gameObject).onClick = handler(self, self.onTouch)
	UIEventListener.Get(self.dialogTouch).onClick = handler(self, self.showLastLabel)
end

function GuideWindow:onGuideNodeChange()
	if self.obj then
		self:initObj()
	end
end

function GuideWindow:onResize()
end

function GuideWindow:onError(e)
	dump(e)
end

function GuideWindow:recordSpecial(stageSize, rectangle)
end

function GuideWindow:initMask()
	local objID = GuideTable:getObjID(self.guideID)
	local isBlack = GuideTable:isBlack(self.guideID)
	local objScale = GuideTable:objScale(self.guideID)

	if self.obj then
		local maskType = GuideTable:getMaskType(self.guideID)
		local pos = self.obj.transform.position
		local tmpPos = self.window_.transform:InverseTransformPoint(pos)

		if maskType == xyd.GuideMaskType.IRREGULAR then
			local icon = GuideTable:getMaskIcon(self.guideID)
			local iconOffset = GuideTable:getIconOffset(self.guideID)
			local iconH5 = GuideTable:getMaskIconH5(self.guideID)
			local iconOffsetH5 = GuideTable:getIconOffsetH5(self.guideID)

			if xyd.isH5() then
				if iconH5 and iconH5 ~= "" then
					icon = iconH5
				end

				if iconOffsetH5 and #iconOffsetH5 == 2 then
					iconOffset = iconOffsetH5
				end
			end

			self:initMask2(tmpPos, iconOffset, icon)
			self.maskImage_:SetActive(false)
		else
			if not self.mask_ then
				self.mask_ = GuideMaskBackgroud.new(self.guideMaskNode)

				self.mask_:SetLocalPosition(0, self.iphoneXFixY, 0)
			end

			local alpha_ = 0.5

			if not isBlack then
				alpha_ = 0.01
			end

			self.mask_:init(xyd.Global.getRealWidth(), xyd.Global.getMaxBgHeight(), alpha_)
			self:actionMask(self.guideMaskNode:GetComponent(typeof(UIWidget)), 1)

			local scaleX = 1
			local scaleY = 1

			if #objScale > 0 then
				scaleX = objScale[1]
				scaleY = objScale[2]
			end

			local widget = self.obj:GetComponent(typeof(UIWidget))

			self.mask_:draw(tmpPos.x, tmpPos.y - self.iphoneXFixY - widget.height * (scaleY - 1) / 2, widget.width * scaleX, widget.height * scaleY)
			self.maskImage_:SetActive(false)
			self.mask_:addTouchEvent(true, handler(self, self.onTouch))
		end
	elseif objID[1] == "-1" then
		if isBlack then
			self:actionMask(self.maskImage_, 0.5)
		else
			self.maskImage_.color = Color.New2(4294967043.0)
		end

		self.maskImageClick = handler(self, self.onObjClick)
	elseif self.wnd_.name == "guide_edit_name_window" then
		self.maskImage_:SetActive(false)
	elseif isBlack then
		self:actionMask(self.maskImage_, 0.5)
	else
		self.maskImage_.color = Color.New2(4294967043.0)
	end

	local specialFunc = GuideTable:specialFunc(self.guideID)

	if specialFunc == "showGuide" then
		self.wnd_:initGuideMask()
	end

	self:initSpecialArea()
end

function GuideWindow:playAction()
	local type_ = GuideTable:getDialogType(self.guideID)

	if type_ == 2 then
		local action = DG.Tweening.DOTween.Sequence()
		local transform = self.imgTrangle_.transform

		action:Append(transform:DOLocalMove(Vector3(184, -83, 0), 0.5)):Append(transform:DOLocalMove(Vector3(184, -70, 0), 0.5)):SetLoops(-1, DG.Tweening.LoopType.Restart)

		self.imgTrangleAction_ = action
	end
end

function GuideWindow:playImgHandAction()
end

function GuideWindow:willClose()
	GuideWindow.super.willClose(self)
	self:clearAction()

	if self.useGuideMask_ then
		xyd.Global.guideMask05:removeFromParent()
		xyd.Global.guideMask001:removeFromParent()

		self.useGuideMask_ = false
	end
end

function GuideWindow:didClose()
	GuideWindow.super.didClose(self)

	local specialFunc = GuideTable:specialFunc(self.guideID)

	if specialFunc == "showEditName" then
		-- Nothing
	end
end

function GuideWindow:clearAction()
	dump("clearAction================================")

	if #self.timers_ > 0 then
		for i = 1, #self.timers_ do
			local timer = self.timers_[i]

			timer:Stop()
		end

		self.timers_ = {}
	end

	if self.obj and not tolua.isnull(self.obj.gameObject) then
		UIEventListener.Get(self.obj.gameObject).guideClick = nil
	end

	if self.imgTrangleAction_ then
		self.imgTrangleAction_:Pause()
		self.imgTrangleAction_:Kill()

		self.imgTrangleAction_ = nil
	end

	if self.spineHand_ then
		self.spineHand_:destroy()

		self.spineHand_ = nil
	end

	if self.quan_ then
		self.quan_:stop()
	end

	self.lastQuanTime_ = 0
end

function GuideWindow:setDialogLabel(label, desc)
	label.text = desc

	label:SetActive(true)
end

function GuideWindow:initDialog()
	local desc = GuideTable:getDesc(self.guideID)
	local type_ = GuideTable:getDialogType(self.guideID)
	local objType = GuideTable:getObjType(self.guideID)

	if desc and desc ~= "" then
		self.groupDialog_:SetActive(true)

		local label, imgDialogBg, anchorNum = nil

		if type_ == 1 then
			self.groupDialog1:SetActive(true)
			self.groupDialog2:SetActive(false)

			label = self.labelDesc1
			imgDialogBg = self.groupDialog1:ComponentByName("imgDialogBg1", typeof(UIRect))
			anchorNum = 30

			self:setDialogLabel(label, desc)
		else
			self.groupDialog1:SetActive(false)
			self.groupDialog2:SetActive(true)

			label = self.labelDesc2
			imgDialogBg = self.groupDialog2:ComponentByName("imgDialogBg2", typeof(UIRect))
			anchorNum = 45

			self:setDialogLabel(label, desc)
		end

		self:playLabelAction(label)

		if GuideTable:isFlipX(self.guideID) then
			self.groupDialog_:SetLocalScale(-1, 1, 1)
			label:SetLocalScale(-1, 1, 1)
			imgDialogBg:SetLeftAnchor(label.gameObject, 1, -anchorNum)
			imgDialogBg:SetRightAnchor(label.gameObject, 0, anchorNum)
		else
			self.groupDialog_:SetLocalScale(1, 1, 1)
			label:SetLocalScale(1, 1, 1)
			imgDialogBg:SetLeftAnchor(label.gameObject, 0, -anchorNum)
			imgDialogBg:SetRightAnchor(label.gameObject, 1, anchorNum)
		end

		if self.obj and objType ~= 6 then
			local objPos = self.obj.transform.position
			local tmpPos = self.window_.transform:InverseTransformPoint(objPos)

			self.groupDialog_:SetLocalPosition(tmpPos.x, tmpPos.y, 0)
		else
			self.groupDialog_:SetLocalPosition(0, 0, 0)
		end

		local pos = GuideTable:getPosition(self.guideID)

		if #pos > 0 then
			local oldPos = self.groupDialog_.transform.localPosition

			self.groupDialog_:SetLocalPosition(oldPos.x + pos[1], oldPos.y - pos[2], 0)
		end

		if self.guideID == 1 then
			self.imgGirl_:SetActive(false)
			self.newGirl:SetActive(true)
			self:initNewGirl()
		else
			self.imgGirl_:SetActive(true)
			self.newGirl:SetActive(false)
		end

		if not self.obj then
			self:createDialogTouchImg()
		end
	else
		self.isShowLastLabel_ = true

		self.groupDialog_:SetActive(false)
	end

	local sound = GuideTable:getSound(self.guideID)

	if sound > 0 and self.sound_ == 0 then
		self.sound_ = sound
	end
end

function GuideWindow:initNewGirl()
	if xyd.isH5() then
		xyd.setUITextureByName(self.mapBg, "mapBg")
		xyd.setUITextureByName(self.bgImgGirl, "partner_picture_51009")
	else
		xyd.setUITextureByName(self.mapBg, "bg_top_floor")
		xyd.setUITextureByName(self.bgImgGirl, "partner_picture_56003")
	end
end

function GuideWindow:createDialogTouchImg()
	if xyd.Global.lang == "en_en" then
		return
	end

	self.dialogTouch:SetActive(true)
end

function GuideWindow:showLastLabel()
	if xyd.Global.lang == "en_en" then
		return
	end

	local desc = GuideTable:getDesc(self.guideID)

	if desc and desc ~= "" then
		if self.labelActionTimer then
			self.labelActionTimer:Stop()

			self.labelActionTimer = nil
		end

		self:setDialogLabel(self.actionLabel_, desc)
		self:cleanDialogTouchImg()
	end

	self.isShowLastLabel_ = true
end

function GuideWindow:cleanDialogTouchImg()
	self.dialogTouch:SetActive(false)
end

function GuideWindow:initLanSpeed()
	if xyd.Global.lang == "en_en" then
		self.lanSpeed_ = 3
	else
		self.lanSpeed_ = 1
	end
end

function GuideWindow:playLabelAction(label)
	if xyd.Global.lang == "en_en" then
		self.isShowLastLabel_ = true

		return
	end

	self:initLanSpeed()

	self.isShowLastLabel_ = false
	self.actionLabel_ = label
	self.curStr = ""
	self.curStrPos = 1
	self.labelHeight_ = label.height

	self.actionLabel_:SetActive(false)

	local speed = 0.06
	self.curStrList_ = xyd.getColorLabelList(label.text)
	local loop = #self.curStrList_
	local timer = Timer.New(handler(self, self.playLabelActionFlow), speed, loop)

	timer:Start()
	table.insert(self.timers_, timer)

	self.labelActionTimer = timer
end

function GuideWindow:playLabelActionFlow()
	self.actionLabel_:SetActive(true)

	if self.curStrPos == 1 then
		self.actionLabel_.text = ""
	end

	self.curStr = self.curStr .. self.curStrList_[self.curStrPos]
	self.actionLabel_.text = self.curStr
	local tmpS = ""

	if self.actionLabel_.height < self.labelHeight_ then
		local len = (self.labelHeight_ - self.actionLabel_.height) / 36

		for i = 1, len do
			tmpS = tmpS .. "\n"
		end
	end

	self.actionLabel_.text = self.curStr .. tmpS
	self.curStrPos = self.curStrPos + 1

	if self.curStrPos > #self.curStrList_ then
		self.labelActionTimer:Stop()

		self.labelActionTimer = nil

		self:cleanDialogTouchImg()

		self.isShowLastLabel_ = true
	end
end

function GuideWindow:initDuration()
	local duration = GuideTable:getDuration(self.guideID)

	if duration > 0 then
		local key = "guide_duration_key"

		XYDCo.WaitForTime(duration, function ()
			xyd.GuideController.get():completeOneGuide(self.guideID)
		end, key)
		table.insert(self.timeKey_, key)
	end
end

function GuideWindow:initPause()
	local pause = GuideTable:getPause(self.guideID)

	if pause[1] and pause[1] > 0 and self.wnd_.name_ == "battle_window" then
		local wnd = self.wnd_

		if pause[2] == 0 then
			wnd:stopBattleByGuide()
		end
	end
end

function GuideWindow:playLevUpHide(isHide)
	if self.isLevUpHide_ or self.isGuideHide_ then
		return
	end

	if not self.isLevUpHide2_ and isHide then
		self:hide()
	elseif self.isLevUpHide2_ and not isHide then
		self:show()
		self:initObj()
	end

	self.isLevUpHide2_ = isHide
end

function GuideWindow:drawShader(obj, pos, a, b)
end

function GuideWindow:initMask2(pos, iconOffset, icon)
	if self.guideMask_ then
		-- Nothing
	end

	local isBlack = GuideTable:isBlack(self.guideID)
	local alpha_ = 0.5

	if not isBlack then
		alpha_ = 0.01
	end

	local guideMask = self:getMaskByAlpha(alpha_)

	guideMask:ChangeParent(self.guideMaskNode)

	self.guideMask_ = guideMask

	self.guideMask_:SetActive(true)
	self.guideMask_:setTouchEnable(true)

	local offX = 0
	local offY = 0

	dump(iconOffset, "cccccccccccccccc")

	if #iconOffset > 0 then
		offX = iconOffset[1] or 0
		offY = iconOffset[2] or 0
	end

	local objID = GuideTable:getObjID(self.guideID)

	if objID[1] == "fightBtn" and self.wnd_.name == "campaign_window" then
		-- Nothing
	end

	self.guideMask_:updateMask2({
		{
			pos = {
				x = pos.x + offX,
				y = pos.y + offY - self.iphoneXFixY
			},
			icon = icon,
			iconOffset = {
				0,
				0
			}
		}
	})
	guideMask:SetLocalPosition(0, self.iphoneXFixY, 0)
	guideMask:SetAlpha(0.01)
	self:actionMask(guideMask:getWidget(), 1)

	self.useGuideMask_ = true

	self.guideMask_:addTouchEvent(true, handler(self, self.onTouch))
end

function GuideWindow:getMaskByAlpha(alpha)
	if alpha == 0.5 then
		return xyd.Global.guideMask05
	end

	return xyd.Global.guideMask001
end

function GuideWindow:initMask3(marks)
	if self.specialAreaMask_ then
		self.specialAreaMask_ = nil
	end

	local specialAreaMask = self:getMaskByAlpha(0.5)

	specialAreaMask:ChangeParent(self.guideMaskNode)

	self.specialAreaMask_ = specialAreaMask

	self.specialAreaMask_:updateMask2(marks, -self.iphoneXFixY)
	self.maskImage_:SetActive(true)

	self.maskImage_.color = Color.New2(4294967043.0)

	specialAreaMask:SetLocalPosition(0, self.iphoneXFixY, 0)
	specialAreaMask:SetAlpha(0.01)
	self:actionMask(specialAreaMask:getWidget(), 1)

	self.useGuideMask_ = true

	specialAreaMask:setTouchEnable(false)
end

function GuideWindow:initSpecialArea()
	local areas = GuideTable:specialArea(self.guideID)

	if #areas <= 0 then
		return
	end

	local objID = GuideTable:getObjID(self.guideID)

	if #objID ~= 1 or objID[1] ~= "-1" then
		return
	end

	local datas = {}

	for _, str in ipairs(areas) do
		local data = xyd.split(str, ":")

		if #data >= 4 then
			local curObjID = xyd.split(data[2], "|")
			local obj = self:getObj(data[1], curObjID)

			if obj then
				local pos = obj.transform.position
				local tmpPos = self.window_.transform:InverseTransformPoint(pos)
				local icon = tostring(data[3])
				local iconOffset = xyd.split(data[4], "|")

				table.insert(datas, {
					pos = tmpPos,
					iconOffset = iconOffset,
					icon = icon
				})
			end
		end
	end

	self:initMask3(datas)
end

function GuideWindow:actionMask(obj, toAlpha)
	if GuideTable:isTransition(self.guideID) then
		dump(obj.alpha)

		if obj.alpha ~= toAlpha then
			obj.alpha = toAlpha
		end
	else
		dump("cccccccccccccccccc")
		print(debug.traceback())

		local action = DG.Tweening.DOTween.Sequence()

		action:Append(xyd.getTweenAlpha(obj, toAlpha, 0.5))
	end
end

function GuideWindow:preLoadRes()
end

function GuideWindow:getGuideId()
	return self.guideID
end

function GuideWindow:CameraCapture()
end

function GuideWindow:iosTestChangeUI()
	self.labelDesc1.color = Color.New2(4294967295.0)
	self.labelDesc2.color = Color.New2(4294967295.0)

	xyd.setUISprite(self.groupDialog1:ComponentByName("imgDialogBg1", typeof(UISprite)), nil, "guide_9gongge_ios_test")
	xyd.setUISprite(self.groupDialog2:ComponentByName("imgDialogBg2", typeof(UISprite)), nil, "guide_dialog_bg_ios_test")
end

return GuideWindow
