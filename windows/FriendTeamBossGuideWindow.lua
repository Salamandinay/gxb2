local BaseWindow = import(".BaseWindow")
local FriendTeamBossGuideWindow = class("FriendTeamBossGuideWindow", BaseWindow)

function FriendTeamBossGuideWindow:ctor(name, params)
	FriendTeamBossGuideWindow.super.ctor(self, name, params)

	self.wnd = params.wnd
	self.table_ = params.table or xyd.tables.friendTeamBossGuideTable
	self.curGuideType_ = params.guide_type or xyd.GuideType.FRIEND_TEAM_BOSS

	xyd.Global.initGuideMask()
end

function FriendTeamBossGuideWindow:initWindow()
	FriendTeamBossGuideWindow.super.initWindow(self)
	self:getUIComponent()

	local index = self:getFirsetIndex()

	self:runGuide(index)
end

function FriendTeamBossGuideWindow:getUIComponent()
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

function FriendTeamBossGuideWindow:runGuide(index)
	local ids = self.table_:getIDs()

	if xyd.arrayIndexOf(ids, index) < 0 or self:checkCurIndex(index) == false then
		xyd.WindowManager.get():closeWindow(self.name_)

		return
	end

	NGUITools.DestroyChildren(self.groupGuideMask.transform)

	local iconName = self.table_:getObjID(index)
	local noClick = self.table_:noCilck(index)

	if iconName == "-1" then
		XYDCo.StopWait("friend_team_boss_guide_mask_alpha")

		self.maskImage_:GetComponent(typeof(UIWidget)).alpha = 0.5

		self.maskImage_:SetActive(true)
		self:initDialog(index, self.wnd[iconName])

		UIEventListener.Get(self.maskImage_.gameObject).onClick = function ()
			self:runGuide(index + 1)
		end
	else
		local guideMask = xyd.Global.guideMask05

		guideMask:ChangeParent(self.groupGuideMask)

		self.guideMask_ = guideMask
		local obj = self.wnd[tostring(iconName)]
		local pos = self.window_.transform:InverseTransformPoint(obj.transform.position)
		local iconOffset = self.table_:getIconOffset(index)

		self.guideMask_:updateMask2({
			{
				pos = {
					x = pos.x,
					y = pos.y
				},
				icon = self.table_:getMaskIcon(index),
				iconOffset = iconOffset
			}
		})

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
				self:runGuide(index + 1)
			end)
			local objPos = self.window_.transform:InverseTransformPoint(obj.transform.position)

			self:showHand(objPos)
		else
			self.fx_hand:SetActive(false)

			UIEventListener.Get(self.maskImage_.gameObject).onClick = function ()
				xyd.Global.guideMask05:removeFromParent()
				self:runGuide(index + 1)
			end
		end
	end
end

function FriendTeamBossGuideWindow:initDialog(index, obj)
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

		if obj then
			local tmpPos = self.window_.transform:InverseTransformPoint(obj.transform.position)
			local excelPos = self.table_:getPosition(index)

			self.groupDialog_:X(tmpPos.x + excelPos[1])
			self.groupDialog_:Y(tmpPos.y + excelPos[2])
		else
			self.groupDialog_:X(0)
			self.groupDialog_:Y(0)
		end
	else
		self.groupDialog_:SetActive(false)
	end

	local sound = self.table_:getSound(index)

	if sound > 0 then
		xyd.SoundManager.get():playSound(sound)
	end
end

function FriendTeamBossGuideWindow:showHand(objPos)
	self.fx_hand:SetActive(true)

	if not self.effect then
		self.effect = xyd.Spine.new(self.fx_hand.gameObject)

		self.effect:setInfo("fx_ui_dianji", function ()
			self.effect:SetLocalPosition(objPos.x - 50, objPos.y + 50)
			self.effect:play("texiao01", 0)
		end)
	else
		self.effect:SetLocalPosition(objPos.x - 50, objPos.y + 50)
	end
end

function FriendTeamBossGuideWindow:playOpenAnimation(callback)
	FriendTeamBossGuideWindow.super.playOpenAnimation(self, callback)
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

function FriendTeamBossGuideWindow:getFirsetIndex()
	local index = 1

	if self.curGuideType_ == xyd.GuideType.FRIEND_TEAM_BOSS then
		local is_fight = xyd.models.friendTeamBoss:checkInFight()

		if not is_fight then
			index = self.table_:getFirstIndex(xyd.models.friendTeamBoss.STATE.TEAMUP)
		else
			index = self.table_:getFirstIndex(xyd.models.friendTeamBoss.STATE.FIGHTING)
		end
	end

	return index
end

function FriendTeamBossGuideWindow:checkCurIndex(index)
	local flag = true

	if self.curGuideType_ == xyd.GuideType.FRIEND_TEAM_BOSS then
		local type = xyd.models.friendTeamBoss:checkInFight() and 2 or 1

		if self.table_:getType(index) ~= type then
			flag = false
		end
	end

	return flag
end

return FriendTeamBossGuideWindow
