local ActivityCrystalBallQAWindow = class("ActivityCrystalBallQAWindow", import(".BaseWindow"))

function ActivityCrystalBallQAWindow:ctor(name, params)
	ActivityCrystalBallQAWindow.super.ctor(self, name, params)

	self.selectList_ = {}
	self.parent_ = params.parent
	self.id_ = params.id
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.CRYSTAL_BALL)
end

function ActivityCrystalBallQAWindow:initWindow()
	ActivityCrystalBallQAWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function ActivityCrystalBallQAWindow:getUIComponent()
	local goTrans = self.window_:NodeByName("groupAction").gameObject
	self.bgImg_ = goTrans:ComponentByName("e:image", typeof(UIWidget))
	self.goTrans_ = goTrans
	self.titleLabel_ = goTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.labelDesc_ = goTrans:ComponentByName("groupTop/labelDesc", typeof(UILabel))
	self.iconImg_ = goTrans:ComponentByName("groupTop/iconImg", typeof(UISprite))
	self.btnSub_ = goTrans:NodeByName("btnSub").gameObject
	self.btnSubLabel_ = goTrans:ComponentByName("btnSub/label", typeof(UILabel))
	self.groupBottom_ = goTrans:ComponentByName("groupBottom", typeof(UITable))
	self.rightShowPart_ = goTrans:ComponentByName("rightShowPart", typeof(UIWidget))
	local rightTrans = self.rightShowPart_.transform
	self.rightPartner_ = rightTrans:ComponentByName("partnerImg", typeof(UITexture))
	self.iconImgShow_ = rightTrans:ComponentByName("iconImgShow", typeof(UISprite))
	self.jumpBtn_ = rightTrans:NodeByName("jumpBtn").gameObject
	self.jumpBtnLabel_ = rightTrans:ComponentByName("jumpBtn/label", typeof(UILabel))
	self.descNode_ = rightTrans:NodeByName("descNode").gameObject
	self.descLabel_ = rightTrans:ComponentByName("descNode/descLabel", typeof(UILabel))
	self.tipsLabel_ = rightTrans:ComponentByName("tipsLabel", typeof(UILabel))

	for i = 1, 4 do
		self["selectItem" .. i] = goTrans:NodeByName("groupBottom/selectItem" .. i).gameObject
		self["selectLabel" .. i] = self["selectItem" .. i]:ComponentByName("labelDesc", typeof(UILabel))
		self["resultIcon" .. i] = self["selectItem" .. i]:ComponentByName("iconPos/resultIcon", typeof(UISprite))
		self["selectItemBg" .. i] = self["selectItem" .. i]:ComponentByName("bgImg", typeof(UISprite))

		UIEventListener.Get(self["selectItemBg" .. i].gameObject).onClick = function ()
			self:onClickItem(i)
		end
	end
end

function ActivityCrystalBallQAWindow:initRightPart()
	local iconName = xyd.tables.activityCrystalBallTable:getImgName(self.id_)

	xyd.setUISpriteAsync(self.iconImgShow_, nil, iconName)

	self.jumpBtnLabel_.text = __("FOR_SURE")
	local starPlotId = xyd.tables.activityCrystalBallTable:getUnlockPlot(self.id_)
	self.tipsLabel_.text = __("ACTIVITY_CRYSTAL_BALL_TEXT06", xyd.tables.activityCrystalBallPlotTextTable:getTitle(starPlotId))
	self.descLabel_.text = xyd.tables.activityCrystalBallTable:getTrueText(self.id_)
	local partner_picture_id = xyd.tables.activityCrystalBallTable:getRightShowImg(self.id_)
	local src = xyd.tables.partnerPictureTable:getPartnerPic(partner_picture_id)
	local xy = xyd.tables.partnerPictureTable:getPartnerPicXY(partner_picture_id)
	local scale = xyd.tables.partnerPictureTable:getPartnerPicScale(partner_picture_id)

	xyd.setUITextureByNameAsync(self.rightPartner_, src, true, function ()
		self.rightPartner_.transform:SetLocalPosition(xy.x, -xy.y, 0)
		self.rightPartner_.transform:SetLocalScale(scale, scale, scale)

		self.rightPartner_.alpha = 0
	end)
	self.descNode_:SetActive(false)
	self.jumpBtn_:SetActive(false)
end

function ActivityCrystalBallQAWindow:showRightAction()
	self.rightShowPart_.alpha = 1
	local moveXY = xyd.tables.activityCrystalBallTable:getMoveDelta(self.id_)
	local action = self:getSequence()
	local beforePos = self.iconImgShow_.transform.localPosition

	action:Insert(0, self.iconImgShow_.transform:DOLocalMove(Vector3(beforePos.x + moveXY[1], beforePos.y + moveXY[2], 0), 1))

	local function setter1(value)
		self.iconImgShow_.alpha = value
	end

	local function setter2(value)
		self.rightPartner_.alpha = value
	end

	action:Insert(0.4, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 1, 0, 1))
	action:Insert(0.4, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0, 1, 1))
	action:AppendCallback(function ()
		self.descNode_:SetActive(true)
		self.jumpBtn_:SetActive(true)
	end)
end

function ActivityCrystalBallQAWindow:register()
	ActivityCrystalBallQAWindow.super.register(self)

	UIEventListener.Get(self.btnSub_).onClick = handler(self, self.onClickSub)
	UIEventListener.Get(self.jumpBtn_).onClick = handler(self, self.onClickJump)

	self.eventProxy_:addEventListener(xyd.event.CRYSTAL_BALL_READ_PLOT, handler(self, self.onAnswerQuestion))
end

function ActivityCrystalBallQAWindow:onClickJump()
	xyd.WindowManager.get():closeWindow("activity_crystal_ball_laf_window")
	xyd.WindowManager.get():closeWindow(self.name_, function ()
		xyd.WindowManager.get():openWindow("activity_crystal_ball_story_window", {})
	end)
end

function ActivityCrystalBallQAWindow:onAnswerQuestion()
	self:showRightAction()
end

function ActivityCrystalBallQAWindow:updateHeight()
	local addHeight = self.labelDesc_.height - 32

	if addHeight > 0 then
		self.bgImg_.height = 782 + addHeight
	end

	self.goTrans_:Y(addHeight / 2)
end

function ActivityCrystalBallQAWindow:layout()
	self.titleLabel_.text = __("ACTIVITY_CRYSTAL_BALL_TEXT01")

	if xyd.Global.lang == "fr_fr" then
		self.titleLabel_.transform:Y(332)
	end

	self.labelDesc_.text = xyd.tables.activityCrystalBallTable:getQuestionText(self.id_)

	self:updateHeight()

	local iconName = xyd.tables.activityCrystalBallTable:getImgName(self.id_)

	xyd.setUISpriteAsync(self.iconImg_, nil, iconName)

	local idList = xyd.tables.activityCrystalBallTable:getSelectList(self.id_)
	local random = math.random(4)
	self.idList_ = {}

	if random == 2 then
		self.idList_[1] = idList[random]
		self.idList_[2] = idList[random + 1]
		self.idList_[3] = idList[random + 2]
		self.idList_[4] = idList[random - 1]
	elseif random == 3 then
		self.idList_[1] = idList[random]
		self.idList_[2] = idList[random + 1]
		self.idList_[3] = idList[random - 2]
		self.idList_[4] = idList[random - 1]
	elseif random == 4 then
		for i = 4 - random + 1, random do
			self.idList_[i] = idList[i]
		end
	else
		self.idList_ = idList
	end

	local strList = {
		"A.",
		"B.",
		"C.",
		"D."
	}

	for i = 1, 4 do
		self["selectLabel" .. i].text = strList[i] .. xyd.tables.activityCrystalBallTextTable:getText(self.idList_[i])
	end

	self.btnSubLabel_.text = __("SUBMIT")

	self:updateOptionState()
	self:initRightPart()
end

function ActivityCrystalBallQAWindow:updateOptionState(isFromWrong)
	local rightIndex = xyd.tables.activityCrystalBallTable:getTrueIndex(self.id_)

	for i = 1, 4 do
		if self.idList_[i] == rightIndex and xyd.arrayIndexOf(self.selectList_, i) > 0 then
			xyd.setUISpriteAsync(self["resultIcon" .. i], nil, "activity_school_qa_icon_right", function ()
				self["resultIcon" .. i]:MakePixelPerfect()
			end)
			xyd.setUISpriteAsync(self["selectItemBg" .. i], nil, "activity_school_qa_btn_right")

			self["selectItemBg" .. i].gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		elseif self.idList_[i] ~= rightIndex and xyd.arrayIndexOf(self.selectList_, i) > 0 then
			xyd.setUISpriteAsync(self["resultIcon" .. i], nil, "activity_school_qa_right_wrong", function ()
				self["resultIcon" .. i]:MakePixelPerfect()
			end)

			self["selectItemBg" .. i].gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

			xyd.setUISpriteAsync(self["selectItemBg" .. i], nil, "activity_school_qa_btn_wrong")
		else
			xyd.setUISpriteAsync(self["resultIcon" .. i], nil, "setting_up_unpick", function ()
				self["resultIcon" .. i]:MakePixelPerfect()
			end)
			self["resultIcon" .. i].gameObject:SetActive(true)

			self["selectItemBg" .. i].gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

			xyd.setUISpriteAsync(self["selectItemBg" .. i], nil, "questionnaire_unselect")
		end
	end
end

function ActivityCrystalBallQAWindow:onClickItem(index)
	if self.selectIndex and self.selectIndex == index then
		xyd.setUISpriteAsync(self["resultIcon" .. self.selectIndex], nil, "setting_up_unpick", function ()
			self["resultIcon" .. self.selectIndex]:MakePixelPerfect()
		end)
		xyd.setUISpriteAsync(self["selectItemBg" .. self.selectIndex], nil, "questionnaire_unselect")

		self.selectIndex = nil
	elseif not self.selectIndex then
		xyd.setUISpriteAsync(self["resultIcon" .. index], nil, "setting_up_pick", function ()
			self["resultIcon" .. index]:MakePixelPerfect()
		end)
		xyd.setUISpriteAsync(self["selectItemBg" .. index], nil, "questionnaire_select")

		self.selectIndex = index
	elseif self.selectIndex and self.selectIndex ~= index then
		local rightIndex = xyd.tables.activityCrystalBallTable:getTrueIndex(self.id_)

		if xyd.arrayIndexOf(self.selectList_, self.selectIndex) > 0 and self.idList_[self.selectIndex] ~= rightIndex then
			xyd.setUISpriteAsync(self["resultIcon" .. self.selectIndex], nil, "activity_school_qa_right_wrong", function ()
				self["resultIcon" .. self.selectIndex]:MakePixelPerfect()
			end)
			xyd.setUISpriteAsync(self["selectItemBg" .. self.selectIndex], nil, "activity_school_qa_btn_wrong")
		else
			xyd.setUISpriteAsync(self["resultIcon" .. self.selectIndex], nil, "setting_up_unpick", function ()
				self["resultIcon" .. self.selectIndex]:MakePixelPerfect()
			end)
			xyd.setUISpriteAsync(self["selectItemBg" .. self.selectIndex], nil, "questionnaire_unselect")
		end

		xyd.setUISpriteAsync(self["resultIcon" .. index], nil, "setting_up_pick", function ()
			self["resultIcon" .. index]:MakePixelPerfect()
		end)
		xyd.setUISpriteAsync(self["selectItemBg" .. index], nil, "questionnaire_select")

		self.selectIndex = index
	end
end

function ActivityCrystalBallQAWindow:onClickSub()
	if not self.selectIndex then
		xyd.alertTips(__("ACTIVITY_STUDY_NO_ANWER"))

		return
	else
		if xyd.arrayIndexOf(self.selectList_, self.selectIndex) < 0 then
			table.insert(self.selectList_, self.selectIndex)
		end

		local rightIndex = xyd.tables.activityCrystalBallTable:getTrueIndex(self.id_)

		if self.idList_[self.selectIndex] == rightIndex then
			self:updateOptionState()

			local unlockId = xyd.tables.activityCrystalBallTable:getUnlockPlot(self.id_)
			local msg = messages_pb.crystal_ball_read_plot_req()
			msg.activity_id = xyd.ActivityID.CRYSTAL_BALL
			msg.id = unlockId

			xyd.Backend.get():request(xyd.mid.CRYSTAL_BALL_READ_PLOT, msg)
			self:showRightAction()
		else
			self:updateOptionState()

			self.labelDesc_.text = xyd.tables.activityCrystalBallTable:getWrongText(self.id_)
			self.countTime_ = 5
			self.btnSubLabel_.text = self.countTime_

			xyd.setEnabled(self.btnSub_, false)

			if not self.timer_ then
				self.timer_ = Timer.New(handler(self, self.onWrongTimer), 1, -1, true)
			end

			self.timer_:Start()

			self.selectIndex = false
		end
	end
end

function ActivityCrystalBallQAWindow:onWrongTimer()
	if not self.window_ or tolua.isnull(self.window_) then
		return
	end

	self.countTime_ = self.countTime_ - 1
	self.btnSubLabel_.text = self.countTime_

	if self.countTime_ <= 0 then
		if self.timer_ then
			self.timer_:Stop()
		end

		self.btnSubLabel_.text = __("SUBMIT")

		xyd.setEnabled(self.btnSub_, true)
	end
end

function ActivityCrystalBallQAWindow:excuteCallBack()
	ActivityCrystalBallQAWindow.super.excuteCallBack(self)

	if self.hasAnswered_ then
		self.parent_:doCloseAni(self.slot_id, self.info_.is_correct == 1)
	end
end

return ActivityCrystalBallQAWindow
