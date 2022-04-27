local ActivityContent = import(".ActivityContent")
local ActivityStudyQuestion = class("ActivityStudyQuestion", ActivityContent)

function ActivityStudyQuestion:ctor(name, params)
	self.awardItemIconList = {}

	ActivityStudyQuestion.super.ctor(self, name, params)
	dump(self.activityData.detail, "+++++++++++++++++++++++")
end

function ActivityStudyQuestion:getPrefabPath()
	return "Prefabs/Windows/activity/activity_school_qa"
end

function ActivityStudyQuestion:initUI()
	ActivityStudyQuestion.super.initUI(self)
	self:getUIComponent()
	self:updatePos()
	self:layout()
	self:register()
	self:updateEnergyAndScore()
	self:setPartnerImg()
	self:updateQuesitonState()
	self:updateAwardGroup()
end

function ActivityStudyQuestion:updatePos()
	local p_height = self.go:GetComponent(typeof(UIWidget)).height

	if p_height >= 1047 then
		p_height = 1047
	end

	self.logoImg_.transform:Y(-0.06179775280898876 * (p_height - 869))
	self.progressGroup_.transform:Y(40 - 0.2247191011235955 * (p_height - 869))
	self.detailGroup_.transform:Y(-300 - 0.33707865168539325 * (p_height - 869))
	self.posRoot_:Y(-0.11235955056179775 * (p_height - 869))
	self.bubbleGroup_.transform:Y(70 - 0.2808988764044944 * (p_height - 869))
end

function ActivityStudyQuestion:register()
	self:registerEvent(xyd.event.QUIZ_UNLOCK_QUESTION, handler(self, self.onUnlockQue))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.QUIZ_RESET_QUESTION, handler(self, self.onReset))
	self:registerEvent(xyd.event.QUIZ_ANSWER_QUESTION, handler(self, self.onAnswerQuestion))

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_STUDY_HELP"
		})
	end
end

function ActivityStudyQuestion:getUIComponent()
	local goTrans = self.go.transform
	self.logoImg_ = goTrans:ComponentByName("logo", typeof(UITexture))
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.progressGroup_ = goTrans:NodeByName("progressGroup")
	self.groupImg_ = goTrans:ComponentByName("progressGroup/groupImg", typeof(UISprite))

	for i = 1, 3 do
		self["progressLabel" .. i] = self.progressGroup_:ComponentByName("label" .. i, typeof(UILabel))
		self["progressValue" .. i] = self.progressGroup_:ComponentByName("value" .. i, typeof(UILabel))
	end

	self.partnerGroup_ = goTrans:NodeByName("partnerGroup")
	self.partnerImg_ = self.partnerGroup_:ComponentByName("partnerImg", typeof(UITexture))
	self.bubbleGroup_ = self.partnerGroup_:ComponentByName("bubbleGroup", typeof(UIWidget))
	self.bubbleText_ = self.partnerGroup_:ComponentByName("bubbleGroup/bubbleText", typeof(UILabel))
	self.detailGroup_ = goTrans:NodeByName("detailGroup")
	self.posRoot_ = self.detailGroup_:NodeByName("pos")
	self.detailtips_ = self.detailGroup_:ComponentByName("lineTips", typeof(UILabel))

	for i = 1, 16 do
		self["questionBtn" .. i] = self.detailGroup_:ComponentByName("pos/questionGroup/question" .. i, typeof(UISprite))

		UIEventListener.Get(self["questionBtn" .. i].gameObject).onClick = function ()
			self:onClickQuestionBtn(i)
		end
	end

	for i = 1, 9 do
		self["line" .. i] = self.detailGroup_:NodeByName("pos/lineGroup/lineImg" .. i).gameObject
		self["AwardBtn" .. i] = self.detailGroup_:ComponentByName("pos/awardGroup/awardItem" .. i, typeof(UISprite))
		self["AwardClick" .. i] = self["AwardBtn" .. i]:NodeByName("awardGroup").gameObject
		self["AwardEffect" .. i] = self["AwardBtn" .. i]:NodeByName("effectGroup").gameObject

		UIEventListener.Get(self["AwardClick" .. i].gameObject).onClick = function ()
			self:onClickAwardBtn(i)
		end
	end

	self.bubbleGroup_.alpha = 0
end

function ActivityStudyQuestion:layout()
	self.progressLabel1.text = __("ACTIVITY_STUDY_TIPS1")
	self.progressLabel2.text = __("ACTIVITY_STUDY_TIPS2")
	self.progressLabel3.text = __("ACTIVITY_STUDY_TIPS3")
	local nowGroup = xyd.tables.miscTable:getVal("activity_study_host")
	self.progressValue1.text = __("SCHOOL_PRACTICE_TITLE_0" .. nowGroup)

	xyd.setUISpriteAsync(self.groupImg_, nil, "img_group" .. nowGroup)

	self.detailtips_.text = __("ACTIVITY_STUDY_TIPS4")

	if xyd.Global.lang == "de_de" then
		self.progressValue1.fontSize = 20

		self.progressValue1.transform:Y(self.progressValue1.transform.localPosition.y - 5)

		self.progressValue2.fontSize = 20

		self.progressValue2.transform:Y(self.progressValue2.transform.localPosition.y - 5)

		self.progressValue3.fontSize = 20

		self.progressValue3.transform:Y(self.progressValue3.transform.localPosition.y - 5)
	end

	xyd.setUITextureByNameAsync(self.logoImg_, "activity_school_qa_logo_" .. xyd.Global.lang)
end

function ActivityStudyQuestion:updateEnergyAndScore()
	local energy = self.activityData.detail.energy or 0
	local score = self.activityData.detail.score or 0
	self.progressValue3.text = energy .. "/" .. xyd.tables.miscTable:getVal("activity_study_energy_limit")
end

function ActivityStudyQuestion:setPartnerImg()
	local score = self:getScore()
	local partnerID, scale, offsetPos, selectID = xyd.tables.activityStudyScoreTable:getPartnerIDByScore(score)
	self.selectID = selectID
	self.partnerID = partnerID
	local partnerName = xyd.tables.partnerTable:getName(partnerID)
	self.progressValue2.text = partnerName
	local parnerImgName = xyd.tables.partnerPictureTable:getPartnerPic(partnerID)

	xyd.setUITextureByNameAsync(self.partnerImg_, parnerImgName, true)

	self.partnerImg_.transform.localScale = Vector3(scale, scale, scale)

	self.partnerImg_.transform:SetLocalPosition(offsetPos[1], offsetPos[2], 0)

	return scale
end

function ActivityStudyQuestion:getScore()
	local score = 0

	for i = 1, 16 do
		if self.activityData.detail.slot_infos[i] and self.activityData.detail.slot_infos[i].is_correct == 1 then
			score = score + 1
		end
	end

	return score
end

function ActivityStudyQuestion:updateQuesitonState()
	local questionState = self.activityData.detail.slot_infos or {}

	for i = 1, 16 do
		if not questionState[i] then
			xyd.setUISpriteAsync(self["questionBtn" .. i], nil, "activity_school_qa_0")
		else
			local chooseIndex = questionState[i].choose_index

			if questionState[i].is_correct and tonumber(questionState[i].is_correct) == 1 then
				xyd.setUISpriteAsync(self["questionBtn" .. i], nil, "activity_school_qa_2")
			elseif chooseIndex and chooseIndex[1] then
				xyd.setUISpriteAsync(self["questionBtn" .. i], nil, "activity_school_qa_1")
			elseif questionState[i].id and questionState[i].id > 0 then
				xyd.setUISpriteAsync(self["questionBtn" .. i], nil, "activity_school_qa_3")
			else
				xyd.setUISpriteAsync(self["questionBtn" .. i], nil, "activity_school_qa_0")
			end
		end
	end
end

function ActivityStudyQuestion:updateAwardGroup()
	local questionState = self.activityData.detail.slot_infos or {}
	local awardState = self.activityData.detail.awarded or {}

	for i = 1, 9 do
		local needQues = xyd.tables.activityStudyAwardTable:getNeedQue(i)
		local canAward = true
		local awardItem = xyd.tables.activityStudyAwardTable:getAward(i)

		if not self.awardItemIconList[i] then
			self.awardItemIconList[i] = xyd.getItemIcon({
				scale = 0.6481481481481481,
				uiRoot = self["AwardBtn" .. i].gameObject,
				itemID = awardItem[1],
				num = awardItem[2]
			})
		end

		if awardState[i] and awardState[i] > 0 then
			canAward = false

			self.awardItemIconList[i]:setChoose(true)
			self["line" .. i]:SetActive(false)
		else
			self.awardItemIconList[i]:setChoose(false)
			self.awardItemIconList[i]:setMask(true)

			for _, queID in pairs(needQues) do
				if not questionState[queID].is_correct or questionState[queID].is_correct == 0 then
					canAward = false

					break
				end
			end
		end

		if not canAward then
			self.awardItemIconList[i]:setEffect(false)
			self["AwardClick" .. i]:SetActive(false)
			self.awardItemIconList[i]:setMask(true)
		else
			self["line" .. i]:SetActive(false)
			self.awardItemIconList[i]:setMask(false)
			self["AwardClick" .. i]:SetActive(true)

			local effect = "fx_ui_bp_available"

			self.awardItemIconList[i]:setEffect(true, effect, {
				effectPos = Vector3(0, 5, 0)
			})
		end
	end
end

function ActivityStudyQuestion:onClickQuestionBtn(index)
	local slotInfo = self.activityData.detail.slot_infos[index]

	if not slotInfo or not slotInfo.id then
		local energy = self.activityData.detail.energy

		if energy and energy <= 0 then
			xyd.alertTips(__("ACTIVITY_STUDY_NO_ENERGY1"))
		else
			local value = tonumber(xyd.db.misc:getValue("study_question_4_time_stamp"))

			if not value then
				xyd.WindowManager.get():openWindow("gamble_tips_window", {
					type = "study_question_4",
					callback = function ()
						local msg = messages_pb.quiz_unlock_question_req()
						msg.activity_id = xyd.ActivityID.STUDY_QUESTION
						msg.slot_id = index

						xyd.Backend.get():request(xyd.mid.QUIZ_UNLOCK_QUESTION, msg)

						self.unlockID_ = index
					end,
					text = __("ACTIVITY_STUDY_NEED_ENERGY1")
				})
			else
				local msg = messages_pb.quiz_unlock_question_req()
				msg.activity_id = xyd.ActivityID.STUDY_QUESTION
				msg.slot_id = index

				xyd.Backend.get():request(xyd.mid.QUIZ_UNLOCK_QUESTION, msg)

				self.unlockID_ = index
			end
		end
	else
		local params = {
			slot_id = index,
			slot_info = slotInfo,
			parent = self
		}

		xyd.WindowManager.get():openWindow("activity_study_question_answer_window", params)
	end
end

function ActivityStudyQuestion:onUnlockQue(event)
	self:updateEnergyAndScore()

	if not self.unlockID_ then
		return
	end

	local slotInfo = self.activityData.detail.slot_infos[self.unlockID_]
	local params = {
		slot_id = self.unlockID_,
		slot_info = slotInfo,
		parent = self
	}
	self.unlockID_ = nil

	xyd.WindowManager.get():openWindow("activity_study_question_answer_window", params)
	self:updateQuesitonState()
end

function ActivityStudyQuestion:onClickAwardBtn(index)
	local params = {
		award_id = index
	}
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.STUDY_QUESTION
	msg.params = require("cjson").encode(params)

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

	self.awardIndex = index
end

function ActivityStudyQuestion:onAward()
	if self.awardIndex and self.awardIndex > 0 then
		self.awardItemIconList[self.awardIndex]:setChoose(true)

		local awardItem = xyd.tables.activityStudyAwardTable:getAward(self.awardIndex)

		self.awardItemIconList[self.awardIndex]:setEffect(false)
		xyd.models.itemFloatModel:pushNewItems({
			{
				item_id = awardItem[1],
				item_num = awardItem[2]
			}
		})

		self.awardIndex = nil
	end
end

function ActivityStudyQuestion:doCloseAni(slotID, isRight)
	if not isRight then
		self:playBubble(false)
	else
		self:playBubble(true)

		local awardList = xyd.tables.activityStudyAwardTable:getAwardIDSlotID(slotID)
		local awardState = self.activityData.detail.awarded or {}
		local questionState = self.activityData.detail.slot_infos or {}

		for _, id in ipairs(awardList) do
			local needQues = xyd.tables.activityStudyAwardTable:getNeedQue(id) or {}
			local canAward = true

			if awardState[id] and awardState[id] > 0 then
				canAward = false
			else
				for _, queID in pairs(needQues) do
					if not questionState[queID].is_correct or questionState[queID].is_correct == 0 then
						canAward = false

						break
					end
				end
			end

			if canAward and tonumber(id) ~= 9 then
				self:playAwardAnimation(id)
			elseif tonumber(id) == 9 and canAward then
				self:waitForTime(0.7, function ()
					self:playFinalAwardAnimation()
				end)
			end
		end
	end
end

function ActivityStudyQuestion:playBubble(isRight)
	local function setter3(value)
		self.bubbleGroup_.alpha = value
	end

	local function setter4(value)
		self.bubbleText_.alpha = value
	end

	self.bubbleGroup_.transform.localScale = Vector3(0.1, 0.1, 0.1)
	self.bubbleGroup_.alpha = 0
	self.bubbleText_.alpha = 0
	local seq3 = self:getSequence()

	if isRight then
		local score = self:getScore()
		local partnerID = xyd.tables.activityStudyScoreTable:getPartnerIDByScore(score)
		local sclaeBefore = self.partnerImg_.transform.localScale.x

		if self.partnerID ~= partnerID then
			local seq1 = self:getSequence(function ()
				local scaleNeed = self:setPartnerImg()
				local text = xyd.tables.activityStudyScoreTable:getRightText(self.selectID)
				self.bubbleText_.text = text
				local seq2 = self:getSequence()

				local function setter2(value)
					self.partnerImg_.alpha = value
				end

				seq2:Insert(0, self.partnerImg_.transform:DOScale(Vector3(scaleNeed * 1.02, scaleNeed * 1.02, 1), 0.13333333333333333))
				seq2:Insert(0.13333333333333333, self.partnerImg_.transform:DOScale(Vector3(scaleNeed * 1, scaleNeed * 1, scaleNeed * 1), 0.1))
				seq2:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0, 1, 0.06666666666666667))
				seq3:Insert(0, self.bubbleGroup_.transform:DOScale(Vector3(1.02, 1.02, 1.02), 0.16666666666666666))
				seq3:Insert(0.16666666666666666, self.bubbleGroup_.transform:DOScale(Vector3(1, 1, 1), 0.1))
				seq3:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), 0, 1, 0.1))
				seq3:Insert(0.23333333333333334, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter4), 0, 1, 0.1))
			end)

			local function setter(value)
				self.partnerImg_.alpha = value
			end

			seq1:Insert(0, self.partnerImg_.transform:DOScale(Vector3(sclaeBefore * 0.4, sclaeBefore * 0.4, 1), 0.13333333333333333))
			seq1:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0, 0.13333333333333333))
		else
			local text = xyd.tables.activityStudyScoreTable:getRightText(self.selectID)
			self.bubbleText_.text = text
			self.bubbleGroup_.alpha = 0

			seq3:Insert(0, self.bubbleGroup_.transform:DOScale(Vector3(1.02, 1.02, 1.02), 0.16666666666666666))
			seq3:Insert(0.16666666666666666, self.bubbleGroup_.transform:DOScale(Vector3(1, 1, 1), 0.1))
			seq3:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), 0, 1, 0.1))
			seq3:Insert(0.23333333333333334, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter4), 0, 1, 0.1))
		end
	else
		local text = xyd.tables.activityStudyScoreTable:getWrongText(self.selectID)
		self.bubbleText_.text = text

		seq3:Insert(0, self.bubbleGroup_.transform:DOScale(Vector3(1.02, 1.02, 1.02), 0.16666666666666666))
		seq3:Insert(0.16666666666666666, self.bubbleGroup_.transform:DOScale(Vector3(1, 1, 1), 0.1))
		seq3:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), 0, 1, 0.1))
		seq3:Insert(0.23333333333333334, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter4), 0, 1, 0.1))
	end
end

function ActivityStudyQuestion:playAwardAnimation(award_id)
	local effectRoot = self["AwardEffect" .. award_id]
	local offsetPos = Vector3(-210, 0, 0)

	if award_id <= 4 then
		effectRoot.transform.localEulerAngles = Vector3(0, 0, 0)
	else
		effectRoot.transform.localEulerAngles = Vector3(0, 0, -90)
	end

	local awardEffect = xyd.Spine.new(effectRoot)

	self.awardItemIconList[tonumber(award_id)]:setMask(false)
	awardEffect:setInfo("activity_study_complete", function ()
		awardEffect:SetLocalPosition(offsetPos.x, offsetPos.y, offsetPos.z)
		awardEffect:play("texiao01", 1, 1, function ()
			self["line" .. award_id]:SetActive(false)
		end)

		local seq = self:getSequence()
		local needQues = xyd.tables.activityStudyAwardTable:getNeedQue(award_id)

		for index, id in ipairs(needQues) do
			local queRoot = self["questionBtn" .. id]

			local function setter(value)
				queRoot.transform.localEulerAngles = Vector3(0, 0, value)
			end

			seq:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 4, 0.03333333333333333))
			seq:Insert(0.03333333333333333, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 4, -4, 0.06666666666666667))
			seq:Insert(0.1, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), -4, 0, 0.03333333333333333))
			seq:Insert(0, queRoot.transform:DOScale(Vector3(0.95, 0.95, 1), 0.06666666666666667))
			seq:Insert(0.06666666666666667, queRoot.transform:DOScale(Vector3(1, 1, 1), 0.06666666666666667))
			seq:Insert(0.13333333333333333, queRoot.transform:DOScale(Vector3(0.95, 0.95, 1), 0.06666666666666667))
			seq:Insert(0.2, queRoot.transform:DOScale(Vector3(1, 1, 1), 0.06666666666666667))
		end
	end)
end

function ActivityStudyQuestion:playFinalAwardAnimation()
	local effectRoot = self.AwardEffect9
	local awardEffect1 = xyd.Spine.new(effectRoot)
	local awardEffect2 = xyd.Spine.new(effectRoot)

	self.awardItemIconList[9]:setMask(false)
	awardEffect1:setInfo("activity_study_complete", function ()
		awardEffect1:setLocalEulerAngles(0, 0, 0)
		awardEffect1:SetLocalPosition(-210, 0, 0)
		awardEffect1:play("texiao01", 1, 1, function ()
			self["line" .. 9]:SetActive(false)
		end)

		local seq = self:getSequence()

		for i = 1, 4 do
			local queRoot = self["AwardBtn" .. i]

			local function setter(value)
				queRoot.transform.localEulerAngles = Vector3(0, 0, value)
			end

			seq:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 4, 0.03333333333333333))
			seq:Insert(0.03333333333333333, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 4, -4, 0.06666666666666667))
			seq:Insert(0.1, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), -4, 0, 0.03333333333333333))
			seq:Insert(0, queRoot.transform:DOScale(Vector3(0.95, 0.95, 1), 0.06666666666666667))
			seq:Insert(0.06666666666666667, queRoot.transform:DOScale(Vector3(1, 1, 1), 0.06666666666666667))
			seq:Insert(0.13333333333333333, queRoot.transform:DOScale(Vector3(0.95, 0.95, 1), 0.06666666666666667))
			seq:Insert(0.2, queRoot.transform:DOScale(Vector3(1, 1, 1), 0.06666666666666667))
		end
	end)
	awardEffect2:setInfo("activity_study_complete", function ()
		awardEffect2:setLocalEulerAngles(0, 0, -90)
		awardEffect2:SetLocalPosition(0, 210, 0)
		awardEffect2:play("texiao01", 1, 1, function ()
			self["line" .. 9]:SetActive(false)
		end)

		local seq = self:getSequence()

		for i = 5, 8 do
			local queRoot = self["AwardBtn" .. i]

			local function setter(value)
				queRoot.transform.localEulerAngles = Vector3(0, 0, value)
			end

			seq:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 4, 0.03333333333333333))
			seq:Insert(0.03333333333333333, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 4, -4, 0.06666666666666667))
			seq:Insert(0.1, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), -4, 0, 0.03333333333333333))
			seq:Insert(0, queRoot.transform:DOScale(Vector3(0.95, 0.95, 1), 0.06666666666666667))
			seq:Insert(0.06666666666666667, queRoot.transform:DOScale(Vector3(1, 1, 1), 0.06666666666666667))
			seq:Insert(0.13333333333333333, queRoot.transform:DOScale(Vector3(0.95, 0.95, 1), 0.06666666666666667))
			seq:Insert(0.2, queRoot.transform:DOScale(Vector3(1, 1, 1), 0.06666666666666667))
		end
	end)
end

function ActivityStudyQuestion:onAnswerQuestion()
	self:updateEnergyAndScore()
	self:updateQuesitonState()
	self:updateAwardGroup()
end

function ActivityStudyQuestion:onReset()
	self:updateEnergyAndScore()
	self:updateQuesitonState()
end

return ActivityStudyQuestion
