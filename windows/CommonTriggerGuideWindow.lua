local BaseWindow = import("app.windows.BaseWindow")
local CommonTriggerGuideWindow = class("CommonTriggerGuideWindow", BaseWindow)

function CommonTriggerGuideWindow:ctor(name, params)
	CommonTriggerGuideWindow.super.ctor(self, name, params)

	self.wnd = params.wnd
	self.table_ = params.table or xyd.tables.commonTriggerGuideTable
	self.curGuideType_ = params.guide_type
	self.nextIndex = nil
	self.waitForNextWindowCount = 0
	self.iphoneXFixY = 0

	xyd.Global.initGuideMask()
end

function CommonTriggerGuideWindow:initWindow()
	CommonTriggerGuideWindow.super.initWindow(self)
	self:getUIComponent()

	local index = self:getFirsetIndex()

	self:register()
	self:runGuide(index)
end

function CommonTriggerGuideWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupGuideMask = winTrans:NodeByName("groupGuideMask").gameObject
	self.maskImage_ = winTrans:ComponentByName("maskImage_", typeof(UISprite))
	self.groupDialog_ = winTrans:NodeByName("groupDialog_").gameObject
	self.groupDialog1 = self.groupDialog_:NodeByName("groupDialog1").gameObject
	self.imgGirl_ = self.groupDialog_:ComponentByName("imgGirl_", typeof(UISprite))
	self.labelDesc1 = self.groupDialog1:ComponentByName("labelDesc1", typeof(UILabel))
	self.imgDialogBg1 = self.groupDialog1:ComponentByName("imgDialogBg1", typeof(UIRect))
	self.fx_hand = winTrans:ComponentByName("fx_hand", typeof(UITexture))
end

function CommonTriggerGuideWindow:runGuide(index)
	local ids = self.table_:getIDs()
	self.wnd = self:getWnd(index)

	if not xyd.WindowManager.get():getWindow(self.wnd.name_) then
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	if xyd.arrayIndexOf(ids, index) < 0 or self:checkCurIndex(index) == false then
		xyd.WindowManager.get():closeWindow(self.name_)

		return
	end

	if self.wnd.name_ ~= self:getWndName(index) then
		self.waitForNextWindowCount = self.waitForNextWindowCount + 1

		if self.waitForNextWindowCount < 50 then
			self:waitForTime(0.1, function ()
				self:runGuide(index)
			end)
		else
			xyd.WindowManager.get():closeWindow(self.name_)
		end

		return
	end

	self.curIndex_ = index
	self.waitForNextWindowCount = 0

	if self.groupGuideMask and not tolua.isnull(self.groupGuideMask) then
		NGUITools.DestroyChildren(self.groupGuideMask.transform)
	end

	local iconName = self.table_:getObjID(index)
	local noClick = self.table_:noCilck(index)

	self:runIndexFunction()

	if iconName == "-1" then
		XYDCo.StopWait("friend_team_boss_guide_mask_alpha")

		self.maskImage_:GetComponent(typeof(UIWidget)).alpha = 0.5

		self.maskImage_:SetActive(true)
		self.fx_hand:SetActive(false)
		self:initDialog(index, self.wnd[iconName])

		UIEventListener.Get(self.maskImage_.gameObject).onClick = function ()
			self:runGuide(index + 1)
		end
	else
		local function iconClickFun()
			local maskType = xyd.GuideMaskType.IRREGULAR

			if self.table_.getMaskType then
				maskType = self.table_:getMaskType(index)
			end

			local obj = self.wnd[tostring(iconName)]

			if tostring(iconName) and tostring(iconName) ~= "" and (not obj or tolua.isnull(obj)) then
				self:close()

				return
			end

			local pos = self.window_.transform:InverseTransformPoint(obj.transform.position)

			if maskType == xyd.GuideMaskType.IRREGULAR then
				local guideMask = xyd.Global.guideMask05

				guideMask:ChangeParent(self.groupGuideMask)

				self.guideMask_ = guideMask
				local iconOffset = self.table_:getIconOffset(index)

				self.guideMask_:updateMask2({
					{
						iconOffset = iconOffset,
						pos = {
							x = pos.x,
							y = pos.y
						},
						icon = self.table_:getMaskIcon(index)
					}
				})
			else
				local scaleX = 1
				local scaleY = 1
				local objScale = {
					1,
					1
				}

				if self.table_.getObjScale then
					objScale = self.table_:getObjScale(index)
				end

				if #objScale > 0 then
					scaleX = objScale[1]
					scaleY = objScale[2]
				end

				local offset = {
					0,
					0
				}

				if self.table_.getOffset then
					offset = self.table_:getOffset(index)
				end

				self.guideMask_ = import("app.components.GuideMaskBackgroud").new(self.groupGuideMask)

				self.guideMask_:init(xyd.Global.getRealWidth(), xyd.Global.getMaxBgHeight(), 0.5)
				self.guideMask_:SetLocalPosition(0, self.iphoneXFixY, 0)

				local widget = obj:GetComponent(typeof(UIWidget))

				self.guideMask_:draw(pos.x + offset[1], pos.y + offset[2] - self.iphoneXFixY - widget.height * (scaleY - 1) / 2, widget.width * scaleX, widget.height * scaleY)
			end

			if self.maskImage_:GetComponent(typeof(UIWidget)).alpha ~= 0.01 then
				self:waitForFrame(1, function ()
					if not noClick then
						self.maskImage_:SetActive(false)
					else
						self.maskImage_:SetActive(true)

						self.maskImage_.depth = 1
						self.maskImage_:GetComponent(typeof(UIWidget)).alpha = 0.01
					end
				end, "friend_team_boss_guide_mask_alpha")
			end

			self:initDialog(index, self.wnd[iconName])

			if not noClick then
				self.guideMask_:addTouchEvent(false)

				UIEventListener.Get(obj.gameObject).guideClick = handler(self, function ()
					xyd.Global.guideMask05:removeFromParent()

					if not self:checkCurWindowIsOpen(index + 1) then
						if not self:checkCurIndex(index + 1) then
							self:runGuide(index + 1)
						else
							self.nextIndex = index + 1

							self.groupDialog_:SetActive(false)
						end
					else
						self:runGuide(index + 1)
					end

					UIEventListener.Get(obj.gameObject).guideClick = nil
				end)
				local objPos = self.window_.transform:InverseTransformPoint(obj.transform.position)

				self:showHand(objPos, index)
			else
				self.fx_hand:SetActive(false)

				UIEventListener.Get(self.maskImage_.gameObject).onClick = function ()
					xyd.Global.guideMask05:removeFromParent()
					self:runGuide(index + 1)
				end
			end
		end

		local delayNum = 0

		if self.table_.getDelayFrame and self.table_:getDelayFrame(index) and self.table_:getDelayFrame(index) > 0 then
			delayNum = self.table_:getDelayFrame(index)
		end

		if delayNum == 0 then
			iconClickFun()
		else
			self:waitForFrame(delayNum, function ()
				iconClickFun()
			end)
		end
	end
end

function CommonTriggerGuideWindow:getCurIndex()
	return self.curIndex_
end

function CommonTriggerGuideWindow:initDialog(index, obj)
	local desc = self.table_:getDesc(index)
	local type_ = self.table_:getDialogType(index)

	if desc and desc ~= "" then
		self.groupDialog_:SetActive(true)

		self.labelDesc1.text = desc

		if self.table_:isFlipX(index) then
			self.imgDialogBg1:SetLeftAnchor(self.labelDesc1.gameObject, 1, -20)
			self.imgDialogBg1:SetRightAnchor(self.labelDesc1.gameObject, 0, 20)
			self.labelDesc1:SetLocalScale(-1, 1, 1)
			self.groupDialog_:SetLocalScale(-1, 1, 1)

			if not self.is_filp then
				self.labelDesc1:X(-self.labelDesc1.transform.localPosition.x)

				self.is_filp = true
			end
		else
			self.imgDialogBg1:SetLeftAnchor(self.labelDesc1.gameObject, 0, -20)
			self.imgDialogBg1:SetRightAnchor(self.labelDesc1.gameObject, 1, 20)
			self.labelDesc1:SetLocalScale(1, 1, 1)
			self.groupDialog_:SetLocalScale(1, 1, 1)

			if self.is_filp then
				self.labelDesc1:X(-self.labelDesc1.transform.localPosition.x)

				self.is_filp = false
			end
		end

		local size = self.labelDesc1.fontSize

		if self.labelDesc1.height <= self.labelDesc1.spacingY + size then
			self.labelDesc1.alignment = NGUIText.Alignment.Center
		else
			self.labelDesc1.alignment = NGUIText.Alignment.Left
		end

		if obj then
			local tmpPos = self.window_.transform:InverseTransformPoint(obj.transform.position)
			local excelPos = self.table_:getPosition(index)

			self.groupDialog_:X(tmpPos.x + excelPos[1])
			self.groupDialog_:Y(tmpPos.y + excelPos[2])
		else
			local excelPos = self.table_:getPosition(index)

			self.groupDialog_:X(excelPos[1])
			self.groupDialog_:Y(excelPos[2])
		end
	else
		self.groupDialog_:SetActive(false)
	end

	local sound = self.table_:getSound(index)

	if sound > 0 then
		xyd.SoundManager.get():playSound(sound)
	end
end

function CommonTriggerGuideWindow:register()
	self.eventProxy_:addEventListener(xyd.event.WINDOW_DID_OPEN, handler(self, self.onWindowOpen))
end

function CommonTriggerGuideWindow:onWindowOpen(event)
	if event.params and self.nextIndex then
		local windowName = event.params.windowName

		if windowName == self:getWndName(self.nextIndex) then
			self:runGuide(self.nextIndex)

			self.nextIndex = nil
		end
	end
end

function CommonTriggerGuideWindow:getWnd(index)
	if self.table_ and self.table_.getWindowName then
		local winName = self.table_:getWindowName(index)

		print(index)
		print(winName)

		if winName then
			local win = xyd.getWindow(winName)

			if win then
				print("winName")

				return win
			end
		end
	end

	return self.wnd
end

function CommonTriggerGuideWindow:getWndName(index)
	if self.table_ and self.table_.getWindowName then
		local winName = self.table_:getWindowName(index)

		return winName
	end

	return nil
end

function CommonTriggerGuideWindow:checkCurWindowIsOpen(index)
	if self.table_ and self.table_.getWindowName then
		local winName = self.table_:getWindowName(index)

		if winName and xyd.WindowManager.get():getWindow(winName) then
			return true
		end
	end

	return false
end

function CommonTriggerGuideWindow:showHand(objPos, index)
	local handPos = {}

	if self.table_.getHandPos then
		handPos = self.table_:getHandPos(index)
	end

	self.fx_hand:SetActive(true)

	local handPosX = objPos.x + 50
	local handPosY = objPos.y

	if #handPos > 0 then
		handPosX = handPosX + handPos[1]
		handPosY = handPosY + handPos[2]
	end

	local handType = 0

	if self.table_.getHandType then
		handType = self.table_:getHandType(index)
	end

	if not self.effect then
		self.effect = xyd.Spine.new(self.fx_hand.gameObject)

		self.effect:setInfo("fx_ui_dianji", function ()
			self.effect:SetLocalPosition(handPosX, handPosY)
			self.effect:play("texiao01", 0)
		end)
	else
		self.effect:SetLocalPosition(handPosX, handPosY)
	end

	local scaleX = 1
	local scaleY = 1

	if handType == 0 then
		scaleX = 1
		scaleY = 1
	elseif handType == 1 then
		scaleX = -1
		scaleY = 1
	elseif handType == 2 then
		scaleX = 1
		scaleY = -1
	elseif handType == 3 then
		scaleX = -1
		scaleY = -1
	end

	self.effect:SetLocalScale(scaleX, scaleY, 1)
end

function CommonTriggerGuideWindow:playOpenAnimation(callback)
	CommonTriggerGuideWindow.super.playOpenAnimation(self, callback)
	self.imgGirl_:SetActive(true)
	self.groupDialog1:SetActive(false)
	self.imgGirl_:SetLocalScale(0.83, 0.83, 0.83)

	local action = self:getSequence(function ()
		self.groupDialog1:SetActive(true)
	end)

	action:Append(self.imgGirl_.transform:DOScale(0.83, 0.3))
	action:Append(self.imgGirl_.transform:DOScale(1.1, 0.1))
	action:Append(self.imgGirl_.transform:DOScale(1, 0.1))
	action:Append(self.imgGirl_.transform:DOScale(1, 0.1))
end

function CommonTriggerGuideWindow:getFirsetIndex()
	local index = 1
	index = self.table_:getFirstIndex(self.curGuideType_)

	return index
end

function CommonTriggerGuideWindow:checkCurIndex(index)
	local flag = true
	local checkType = self.table_:getType(index)

	if not checkType or checkType and checkType == 0 or checkType and checkType ~= self.curGuideType_ then
		flag = false
	end

	return flag
end

function CommonTriggerGuideWindow:dispose()
	CommonTriggerGuideWindow.super.dispose(self)
end

function CommonTriggerGuideWindow:runIndexFunction()
end

return CommonTriggerGuideWindow
