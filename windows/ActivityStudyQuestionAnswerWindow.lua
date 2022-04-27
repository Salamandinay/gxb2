local ActivityStudyQuestionAnswerWindow = class("ActivityStudyQuestionAnswerWindow", import(".BaseWindow"))

function ActivityStudyQuestionAnswerWindow:ctor(name, params)
	ActivityStudyQuestionAnswerWindow.super.ctor(self, name, params)

	self.parent_ = params.parent
	self.info_ = params.slot_info
	self.slot_id = params.slot_id
	self.id_ = self.info_.id
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.STUDY_QUESTION)
end

function ActivityStudyQuestionAnswerWindow:initWindow()
	ActivityStudyQuestionAnswerWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:updateBtnPos()
	self:checkJumpBtn()
	self:register()
end

function ActivityStudyQuestionAnswerWindow:getUIComponent()
	local goTrans = self.window_:NodeByName("groupAction").gameObject
	self.bgImg_ = goTrans:ComponentByName("e:image", typeof(UIWidget))
	self.goTrans_ = goTrans
	self.closeBtn_ = goTrans:NodeByName("closeBtn").gameObject
	self.titleLabel_ = goTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.labelDesc_ = goTrans:ComponentByName("groupTop/scrollDesc/labelDesc", typeof(UILabel))
	self.btnSearch_ = goTrans:ComponentByName("groupTop/topBtnLayout/btnSearch", typeof(UIWidget))
	self.btnSearchLabel_ = goTrans:ComponentByName("groupTop/topBtnLayout/btnSearch/label", typeof(UILabel))
	self.topBtnLayout_ = goTrans:ComponentByName("groupTop/topBtnLayout", typeof(UITable))
	self.btnCopy_ = goTrans:ComponentByName("groupTop/topBtnLayout/btnCopy", typeof(UIWidget))
	self.btnCopyLabel_ = goTrans:ComponentByName("groupTop/topBtnLayout/btnCopy/label", typeof(UILabel))
	self.btnConfirm_ = goTrans:NodeByName("btnPos/btnConfirm").gameObject
	self.btnConfirmLabel_ = goTrans:ComponentByName("btnPos/btnConfirm/label", typeof(UILabel))
	self.btnSub_ = goTrans:NodeByName("btnPos/btnSub").gameObject
	self.btnSubLabel_ = goTrans:ComponentByName("btnPos/btnSub/label", typeof(UILabel))
	self.btnReset_ = goTrans:NodeByName("btnPos/btnReset").gameObject
	self.btnResetLabel_ = goTrans:ComponentByName("btnPos/btnReset/label", typeof(UILabel))
	self.groupBottom_ = goTrans:ComponentByName("groupBottom", typeof(UITable))

	for i = 1, 3 do
		self["selectItem" .. i] = goTrans:NodeByName("groupBottom/selectItem" .. i).gameObject
		self["selectLabel" .. i] = self["selectItem" .. i]:ComponentByName("labelDesc", typeof(UILabel))
		self["resultIcon" .. i] = self["selectItem" .. i]:ComponentByName("iconPos/resultIcon", typeof(UISprite))
		self["selectItemBg" .. i] = self["selectItem" .. i]:ComponentByName("bgImg", typeof(UISprite))

		UIEventListener.Get(self["selectItemBg" .. i].gameObject).onClick = function ()
			self:onClickItem(i)
		end
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ActivityStudyQuestionAnswerWindow:checkJumpBtn()
	local jumpParams = xyd.tables.activityStudyQuestionTable:getJumpWindow(self.id_)

	if not jumpParams or not jumpParams[1] then
		self.btnSearch_.gameObject:SetActive(false)
		self:waitForFrame(1, function ()
			self.topBtnLayout_:Reposition()
		end)
	else
		local function_id = xyd.tables.getWayTable:getFunctionId(jumpParams[1])

		if not xyd.checkFunctionOpen(function_id, true) then
			self.btnSearch_.gameObject:SetActive(false)
			self:waitForFrame(1, function ()
				self.topBtnLayout_:Reposition()
			end)
		end
	end
end

function ActivityStudyQuestionAnswerWindow:register()
	ActivityStudyQuestionAnswerWindow.super.register(self)

	UIEventListener.Get(self.btnSearch_.gameObject).onClick = handler(self, self.onClickSearch)
	UIEventListener.Get(self.btnConfirm_).onClick = handler(self, self.onClickConfirm)
	UIEventListener.Get(self.btnSub_).onClick = handler(self, self.onClickSub)
	UIEventListener.Get(self.btnReset_).onClick = handler(self, self.onClickReset)

	UIEventListener.Get(self.btnCopy_.gameObject).onClick = function ()
		local text = __("ACTIVITY_STUDY_COPY_CONTENT", self.labelDesc_.text, self.selectLabel1.text, self.selectLabel2.text, self.selectLabel3.text)

		xyd.SdkManager:get():copyToClipboard(text)
		xyd.showToast(__("ACTIVITY_STUDY_COPY"))
	end

	self.eventProxy_:addEventListener(xyd.event.QUIZ_ANSWER_QUESTION, handler(self, self.onAnswerQuestion))
	self.eventProxy_:addEventListener(xyd.event.QUIZ_RESET_QUESTION, handler(self, self.onReset))
	self.eventProxy_:addEventListener(xyd.event.QUIZ_UNLOCK_QUESTION, handler(self, self.updateLayout))
end

function ActivityStudyQuestionAnswerWindow:onReset()
	xyd.alertTips(__("EX_SKILL_RESET_SUCCESS"))

	self.info_ = self.activityData.detail.slot_infos[self.slot_id]
	self.id_ = self.info_.id

	self:layout()
	self:updateBtnPos()
	self:checkJumpBtn()
end

function ActivityStudyQuestionAnswerWindow:onAnswerQuestion()
	self.info_ = self.activityData.detail.slot_infos[self.slot_id]

	self.btnSub_:SetActive(false)
	self.btnReset_:SetActive(false)
	self.btnConfirm_:SetActive(true)

	self.hasAnswered_ = true

	if self.info_.is_correct and self.info_.is_correct == 1 then
		xyd.alertTips(__("ACTIVITY_STUDY_RIGHT"))

		self.btnConfirmLabel_.text = __("FOR_SURE")

		self:updateOptionState()
	else
		xyd.alertTips(__("ACTIVITY_STUDY_WRONG"))

		self.btnConfirmLabel_.text = __("ACTIVITY_STUDY_REANSWER")

		self:updateOptionState(true)
	end
end

function ActivityStudyQuestionAnswerWindow:layout()
	self.titleLabel_.text = __("ActivityStudyQuestionAnswerWindow")
	self.titleLabel_.text = __("ACTIVITY_STUDY_QUEST_TITLE")
	self.labelDesc_.text = xyd.tables.activityStudyQuestionTable:getQueText(self.id_)

	for i = 1, 3 do
		self["selectLabel" .. i].text = xyd.tables.activityStudyQuestionTable:getQueOptionText(self.id_, i)
	end

	self:waitForFrame(1, function ()
		self.groupBottom_:Reposition()

		local height = self.bgImg_.height
		local moveHeight = height - 616

		if moveHeight <= 0 then
			moveHeight = 0
		end

		self.goTrans_:Y(moveHeight / 2)
	end)

	self.btnConfirmLabel_.text = __("FOR_SURE")
	self.btnSubLabel_.text = __("SUBMIT")
	self.btnResetLabel_.text = __("RESET")
	self.btnCopyLabel_.text = __("ACTIVITY_STUDY_COPY_QUESTION")
	self.btnCopy_.width = self.btnCopyLabel_.width + 60
	self.btnSearchLabel_.text = __("ACTIVITY_STUDY_SEARCH")
	self.btnSearch_.width = self.btnSearchLabel_.width + 60

	self:waitForFrame(1, function ()
		self.topBtnLayout_:Reposition()
	end)
	self:updateOptionState()
end

function ActivityStudyQuestionAnswerWindow:updateOptionState(isFromWrong)
	local selectList = self.info_.choose_index or {}
	local rightIndex = xyd.tables.activityStudyQuestionTable:getAnswer(self.id_)

	for i = 1, 3 do
		if i == rightIndex and xyd.arrayIndexOf(selectList, i) > 0 then
			xyd.setUISpriteAsync(self["resultIcon" .. i], nil, "activity_school_qa_icon_right", function ()
				self["resultIcon" .. i]:MakePixelPerfect()
			end)
			xyd.setUISpriteAsync(self["selectItemBg" .. i], nil, "activity_school_qa_btn_right")

			self["selectItemBg" .. i].gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		elseif i ~= rightIndex and xyd.arrayIndexOf(selectList, i) > 0 then
			xyd.setUISpriteAsync(self["resultIcon" .. i], nil, "activity_school_qa_right_wrong", function ()
				self["resultIcon" .. i]:MakePixelPerfect()
			end)

			self["selectItemBg" .. i].gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

			xyd.setUISpriteAsync(self["selectItemBg" .. i], nil, "activity_school_qa_btn_wrong")
		else
			if self.info_.is_correct == 1 or isFromWrong then
				self["resultIcon" .. i].gameObject:SetActive(false)

				self["selectItemBg" .. i].gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
			else
				xyd.setUISpriteAsync(self["resultIcon" .. i], nil, "setting_up_unpick", function ()
					self["resultIcon" .. i]:MakePixelPerfect()
				end)
				self["resultIcon" .. i].gameObject:SetActive(true)

				self["selectItemBg" .. i].gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
			end

			xyd.setUISpriteAsync(self["selectItemBg" .. i], nil, "questionnaire_unselect")
		end
	end
end

function ActivityStudyQuestionAnswerWindow:updateBtnPos()
	if self.info_.is_correct and self.info_.is_correct == 1 then
		self.btnConfirmLabel_.text = __("FOR_SURE")

		self.btnConfirm_:SetActive(true)
		self.btnSub_:SetActive(false)
		self.btnReset_:SetActive(false)
	else
		self.btnConfirm_:SetActive(false)
		self.btnSub_:SetActive(true)

		if self.info_.reset_id and self.info_.reset_id > 0 then
			self.btnReset_:SetActive(false)
			self.btnSub_.transform:X(0)
		else
			self.btnReset_:SetActive(true)
			self.btnSub_.transform:X(134)
		end
	end
end

function ActivityStudyQuestionAnswerWindow:onClickItem(index)
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
		xyd.setUISpriteAsync(self["resultIcon" .. self.selectIndex], nil, "setting_up_unpick", function ()
			self["resultIcon" .. self.selectIndex]:MakePixelPerfect()
		end)
		xyd.setUISpriteAsync(self["selectItemBg" .. self.selectIndex], nil, "questionnaire_unselect")
		xyd.setUISpriteAsync(self["resultIcon" .. index], nil, "setting_up_pick", function ()
			self["resultIcon" .. index]:MakePixelPerfect()
		end)
		xyd.setUISpriteAsync(self["selectItemBg" .. index], nil, "questionnaire_select")

		self.selectIndex = index
	end
end

function ActivityStudyQuestionAnswerWindow:onClickSearch()
	local jumpParams = xyd.tables.activityStudyQuestionTable:getJumpWindow(self.id_)

	if not jumpParams or not jumpParams[1] then
		return
	end

	local lev = xyd.tables.getWayTable:getLvLimit(jumpParams[1])

	if xyd.models.backpack:getLev() < lev then
		xyd.showToast(__("DOCTOR_NOT_OPEN"))

		return
	end

	if jumpParams[1] == 123 then
		local partnerID = jumpParams[2]
		local collection = {
			{
				table_id = partnerID
			}
		}
		local params = {
			partners = collection,
			table_id = partnerID
		}

		xyd.WindowManager.get():openWindow("guide_detail_window", params)
	else
		local windows = xyd.tables.getWayTable:getGoWindow(jumpParams[1])
		local params = xyd.tables.getWayTable:getGoParam(jumpParams[1])

		for i in pairs(windows) do
			local windowName = windows[i]

			if jumpParams[1] == 52 then
				self:activityEquipGachaPurchase()
			elseif windowName == "guild_territory_window" then
				if xyd.models.guild.guildID > 0 then
					xyd.WindowManager.get():openWindow("guild_territory_window", {}, function ()
						xyd.WindowManager.get():closeAllWindows({
							main_window = true,
							loading_window = true,
							guild_territory_window = true,
							guide_window = true,
							res_loading_window = true
						})
					end)
				else
					xyd.WindowManager.get():openWindow("guild_join_window", {}, function ()
						xyd.WindowManager.get():closeAllWindows({
							main_window = true,
							loading_window = true,
							guild_join_window = true,
							guide_window = true,
							res_loading_window = true
						})
					end)
				end
			else
				local params2 = {
					loading_window = true,
					main_window = true,
					guide_window = true,
					res_loading_window = true,
					[windowName] = true
				}

				xyd.WindowManager.get():openWindow(windowName, params[i])
				xyd.WindowManager.get():closeWindow(self.name_)
				xyd.WindowManager.get():closeWindow("activity_window")
			end
		end
	end
end

function ActivityStudyQuestionAnswerWindow:onClickSub()
	if not self.selectIndex then
		xyd.alertTips(__("ACTIVITY_STUDY_NO_ANWER"))

		return
	else
		local value = tonumber(xyd.db.misc:getValue("study_question_3_time_stamp"))

		if not value and #self.info_.choose_index > 0 then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				type = "study_question_3",
				callback = function ()
					local energy = self.activityData.detail.energy

					if energy and energy <= 0 then
						xyd.alertTips(__("ACTIVITY_STUDY_NO_ENERGY1"))

						return
					end

					local msg = messages_pb.quiz_answer_question_req()
					msg.activity_id = xyd.ActivityID.STUDY_QUESTION
					msg.slot_id = self.slot_id
					msg.index = self.selectIndex

					xyd.Backend.get():request(xyd.mid.QUIZ_ANSWER_QUESTION, msg)

					self.selectIndex = nil
				end,
				text = __("ACTIVITY_STUDY_NEED_ENERGY3")
			})
		elseif value and #self.info_.choose_index > 0 then
			local energy = self.activityData.detail.energy

			if energy and energy <= 0 then
				xyd.alertTips(__("ACTIVITY_STUDY_NO_ENERGY1"))

				return
			end

			local msg = messages_pb.quiz_answer_question_req()
			msg.activity_id = xyd.ActivityID.STUDY_QUESTION
			msg.slot_id = self.slot_id
			msg.index = self.selectIndex

			xyd.Backend.get():request(xyd.mid.QUIZ_ANSWER_QUESTION, msg)

			self.selectIndex = nil
		else
			local msg = messages_pb.quiz_answer_question_req()
			msg.activity_id = xyd.ActivityID.STUDY_QUESTION
			msg.slot_id = self.slot_id
			msg.index = self.selectIndex

			xyd.Backend.get():request(xyd.mid.QUIZ_ANSWER_QUESTION, msg)

			self.selectIndex = nil
		end
	end
end

function ActivityStudyQuestionAnswerWindow:onClickConfirm()
	if self.info_.is_correct and self.info_.is_correct == 1 then
		xyd.WindowManager.get():closeWindow(self.name_)
	else
		self:updateOptionState()
		self:updateBtnPos()
	end
end

function ActivityStudyQuestionAnswerWindow:onClickReset()
	local type, text = nil

	if self.info_.choose_index and #self.info_.choose_index > 0 then
		type = "study_question_1"
		text = __("ACTIVITY_STUDY_RESET") .. __("ACTIVITY_STUDY_NEED_ENERGY2")
		local energy = self.activityData.detail.energy

		if energy and energy <= 0 then
			xyd.alertTips(__("ACTIVITY_STUDY_NO_ENERGY1"))

			return
		end
	else
		type = "study_question_2"
		text = __("ACTIVITY_STUDY_RESET")
	end

	local value = tonumber(xyd.db.misc:getValue(type .. "_time_stamp"))

	if not value then
		xyd.WindowManager.get():openWindow("gamble_tips_window", {
			callback = function ()
				local msg = messages_pb.quiz_reset_question_req()
				msg.activity_id = xyd.ActivityID.STUDY_QUESTION
				msg.slot_id = self.slot_id

				xyd.Backend.get():request(xyd.mid.QUIZ_RESET_QUESTION, msg)

				self.selectIndex = nil
			end,
			type = type,
			text = text
		})
	else
		local msg = messages_pb.quiz_reset_question_req()
		msg.activity_id = xyd.ActivityID.STUDY_QUESTION
		msg.slot_id = self.slot_id

		xyd.Backend.get():request(xyd.mid.QUIZ_RESET_QUESTION, msg)

		self.selectIndex = nil
	end
end

function ActivityStudyQuestionAnswerWindow:updateLayout()
	self.info_ = self.activityData.detail.slot_infos[self.slot_id]

	self:updateOptionState()
	self:updateBtnPos()
end

function ActivityStudyQuestionAnswerWindow:excuteCallBack()
	ActivityStudyQuestionAnswerWindow.super.excuteCallBack(self)

	if self.hasAnswered_ then
		self.parent_:doCloseAni(self.slot_id, self.info_.is_correct == 1)
	end
end

return ActivityStudyQuestionAnswerWindow
