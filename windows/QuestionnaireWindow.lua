local BaseWindow = import(".BaseWindow")
local BaseComponent = import("app.components.BaseComponent")
local QuestionnaireWindow = class("QuestionnaireWindow", BaseWindow)
local QuestionnaireWindowItem = class("QuestionnaireWindowItem", BaseComponent)
local QuestionnaireMatrix = class("QuestionnaireMatrix", BaseComponent)
local QuestionnaireMatrixItem = class("QuestionnaireMatrixItem", BaseComponent)
local QuestionnaireFill = class("QuestionnaireFill", BaseComponent)
local QuestionnaireMatrixTop = class("QuestionnaireMatrixTop", BaseComponent)
local QuestionnaireTable = xyd.tables.questionnaireTable

function QuestionnaireWindow:ctor(name, params)
	QuestionnaireWindow.super.ctor(self, name, params)

	self.select_items_ = {}
	self.options_items_ = {}
	self.limit_ = {}
	self.item_pool_ = {}
	self.selects_content_ = {}
	self.cur_item_ = {}
	self.id_ = params.current_id or 1
	self.is_finished_ = params.is_finished
end

function QuestionnaireWindow:initWindow()
	QuestionnaireWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.contentGroup_ = winTrans:NodeByName("groupAction/contentGroup").gameObject
	self.touchGroup_ = winTrans:NodeByName("touchGroup").gameObject
	self.finishGroup_ = winTrans:NodeByName("groupAction/finishGroup").gameObject
	self.finishLabel_ = winTrans:ComponentByName("groupAction/finishGroup/finishTextLabel01", typeof(UILabel))

	if self.is_finished_ then
		self:showFinish()
	end

	self.titleLabel_ = winTrans:ComponentByName("groupAction/contentGroup/titleLabel", typeof(UILabel))
	self.nextLabel_ = winTrans:ComponentByName("groupAction/contentGroup/nextBtn/nextLabel", typeof(UILabel))
	self.lastLabel_ = winTrans:ComponentByName("groupAction/contentGroup/lastBtn/lastLabel", typeof(UILabel))
	self.problemLabel_ = winTrans:ComponentByName("groupAction/contentGroup/problemLabel", typeof(UILabel))
	self.closeBtn = winTrans:ComponentByName("groupAction/contentGroup/closeBtn", typeof(UISprite)).gameObject
	self.nextBtn_ = winTrans:ComponentByName("groupAction/contentGroup/nextBtn", typeof(UISprite)).gameObject
	self.lastBtn_ = winTrans:ComponentByName("groupAction/contentGroup/lastBtn", typeof(UISprite)).gameObject
	self.bg1_ = winTrans:ComponentByName("groupAction/contentGroup/bg1", typeof(UISprite)).gameObject
	self.bg1_boxCollider = winTrans:ComponentByName("groupAction/contentGroup/bg1", typeof(UnityEngine.BoxCollider))
	self.fill_bg_ = winTrans:ComponentByName("groupAction/contentGroup/fill_bg", typeof(UISprite)).gameObject
	self.input_ = winTrans:ComponentByName("groupAction/contentGroup/input", typeof(UIInput))

	XYDUtils.AddEventDelegate(self.input_.onChange, handler(self, self.onChange))

	self.itemGroup_ = winTrans:NodeByName("groupAction/contentGroup/scroller1/itemGroup").gameObject
	self.itemGroup_Grid_ = winTrans:ComponentByName("groupAction/contentGroup/scroller1/itemGroup", typeof(UIGrid))
	self.scroller1_ = winTrans:ComponentByName("groupAction/contentGroup/scroller1", typeof(UIScrollView))
	self.scroller1_panel = winTrans:ComponentByName("groupAction/contentGroup/scroller1", typeof(UIPanel))

	self.finishGroup_:SetActive(false)
	self.contentGroup_:SetActive(true)
	self.touchGroup_:SetActive(true)
	xyd.setDragScrollView(self.bg1_, self.scroller1_)
	self:setBtnLabel()
	self:layout()
	self:initChoice()
end

function QuestionnaireWindow:layout()
	self:registerEvent()
	self:setLayout()
end

function QuestionnaireWindow:registerEvent()
	self:register()

	UIEventListener.Get(self.nextBtn_).onClick = handler(self, self.onNextTouch)
	UIEventListener.Get(self.lastBtn_).onClick = handler(self, self.onLastTouch)

	self.eventProxy_:addEventListener(xyd.event.ANSWER_QUESTIONNAIRE, handler(self, self.answerQuestionEvent))
	self.eventProxy_:addEventListener(xyd.event.BACK_QUESTION, handler(self, self.backQuestionEvent))
end

function QuestionnaireWindow:answerQuestionEvent(event)
	local data = event.data

	if data.is_finished ~= 0 then
		self:showFinish()
	else
		self.id_ = data.current_id

		self:initChoice()
		self:setBtnLabel()
	end
end

function QuestionnaireWindow:backQuestionEvent(event)
	local data = event.data
	self.id_ = data.question_id

	self:initChoice(data.comment)
	self:setBtnLabel()
end

function QuestionnaireWindow:onNextTouch()
	local type = QuestionnaireTable:getQuestionType(self.id_)

	if type == 3 or type == 4 or type == 5 then
		self.cur_item_:reqChoose()

		return
	end

	if next(self.select_items_) == nil then
		if QuestionnaireTable:getIsOptional(self.id_) ~= 0 then
			local msg = messages_pb:answer_questionnaire_req()
			msg.question_id = self.id_
			msg.options = ""
			msg.comment = ""
			msg.questionnaire_type = QuestionnaireTable:getType(self.id_)

			xyd.Backend.get():request(xyd.mid.ANSWER_QUESTIONNAIRE, msg)

			return
		end

		if type == 3 then
			xyd.showToast(__("QUESTIONNAIRE_NO_SELECT_NEW"))
		else
			xyd.showToast(__("QUESTIONNAIRE_NO_SELECT"))
		end

		return
	end

	local hasLimit = true

	if self.limit_ == 0 then
		hasLimit = false
	end

	if hasLimit and self.limit_ < #self.select_items_ then
		xyd.showToast(__("QUESTIONNAIRE_SELECT_MORE"))

		return
	end

	local op = "" .. tostring(self.select_items_[1])

	for i = 1, #self.select_items_ - 1 do
		op = tostring(op) .. "|" .. tostring(self.select_items_[i + 1])
	end

	local comment = ""
	local length = self.itemGroup_.transform.childCount

	for i = 1, length do
		repeat
			local item = self.item_pool_[i]

			if not item.select_ then
				break
			end

			if not item:checkLegal() then
				return
			end

			local tmp = item:getText()

			if not tmp or tmp == "" then
				break
			end

			comment = tmp
		until true
	end

	self.lastBtn_:SetActive(false)
	self.nextBtn_:SetActive(false)

	local msg = messages_pb:answer_questionnaire_req()
	msg.question_id = self.id_
	msg.options = op
	msg.comment = comment
	msg.questionnaire_type = QuestionnaireTable:getType(self.id_)

	xyd.Backend.get():request(xyd.mid.ANSWER_QUESTIONNAIRE, msg)
end

function QuestionnaireWindow:onLastTouch()
	self:backChoice()
end

function QuestionnaireWindow:setLayout()
	self.titleLabel_.text = __("QUESTIONNAIRE_WINDOW_TITLE")
end

function QuestionnaireWindow:initChoice(comment)
	if comment == nil then
		comment = ""
	end

	self.last_item_ = nil
	self.select_items_ = {}
	self.problemLabel_.text = xyd.tables.questionnaireTextTable:getText(self.id_)
	self.options_items_ = QuestionnaireTable:getOptions(self.id_)
	self.limit_ = QuestionnaireTable:getChoices(self.id_)
	local tmp = {}

	NGUITools.DestroyChildren(self.itemGroup_.transform)

	if type ~= 5 then
		self.bg1_boxCollider.enabled = true

		self.fill_bg_:SetActive(false)
		self.scroller1_panel:SetBottomAnchor(self.contentGroup_, 0, 100)
		self.scroller1_panel:SetTopAnchor(self.contentGroup_, 1, -240)
		self.input_:SetActive(false)
	end

	self.item_pool_ = {}
	local type = QuestionnaireTable:getQuestionType(self.id_)

	if type == 3 then
		self.cur_item_ = QuestionnaireMatrix.new({
			id = self.id_,
			comment = comment
		}, self.itemGroup_, self.scroller1_)

		self.scroller1_:ResetPosition()

		return
	elseif type == 5 then
		print("走了這個的初始化------------")
		self.input_:SetActive(true)

		self.bg1_boxCollider.enabled = false

		self.scroller1_panel:SetBottomAnchor(self.contentGroup_, 0, 120)
		self.scroller1_panel:SetTopAnchor(self.contentGroup_, 1, -245)
		self.fill_bg_:SetActive(true)

		self.cur_item_ = QuestionnaireFill.new({
			id = self.id_,
			comment = comment
		}, self.itemGroup_)
		self.input_.label = self.cur_item_:getLabel()
		self.input_.defaultText = __("QUESTIONNAIRE_DEFAULT_NEW")
		self.input_.isOnDragLight = false

		self.scroller1_:ResetPosition()

		return
	end

	for i = 1, #self.options_items_ do
		local item = QuestionnaireWindowItem.new({
			id = self.options_items_[i],
			comment = comment
		}, self.itemGroup_, self.scroller1_)

		table.insert(self.item_pool_, item)
	end

	self.itemGroup_Grid_:Reposition()
	self.scroller1_:ResetPosition()
end

function QuestionnaireWindow:setBtnLabel()
	local type = QuestionnaireTable:getType(self.id_)
	local num = QuestionnaireTable:getThisNumber(self.id_)
	self.nextLabel_.text = __("QUESTIONNAIRE_NEXT", math.floor(num * 100 / QuestionnaireTable:getTotal(type) + 0.5))
	self.lastLabel_.text = __("QUESTIONNAIRE_LAST")

	self.nextBtn_:SetActive(true)
	self.lastBtn_:SetActive(true)

	if QuestionnaireTable:getThisNumber(self.id_) == 1 then
		self.nextBtn_:SetLocalPosition(0, -268.5, 0)
		self.lastBtn_:SetActive(false)
	else
		self.nextBtn_:SetLocalPosition(160, -268.5, 0)
		self.lastBtn_:SetActive(true)
	end
end

function QuestionnaireWindow:showFinish()
	self.contentGroup_:SetActive(false)
	self.touchGroup_:SetActive(false)

	for i = 1, 3 do
		repeat
			if i == 2 or i == 3 then
				break
			end

			self.finishLabel_.text = __("QUESTIONNAIRE_FINISH_TEXT0" .. tostring(i))
		until true
	end

	self.finishGroup_:SetActive(true)
end

function QuestionnaireWindow:backChoice()
	self.lastBtn_:SetActive(false)
	self.nextBtn_:SetActive(false)

	local msg = messages_pb:back_question_req()
	msg.questionnaire_type = QuestionnaireTable:getType(self.id_)

	xyd.Backend.get():request(xyd.mid.BACK_QUESTION, msg)
end

function QuestionnaireWindow:selectItem(id, flag, item)
	local type = QuestionnaireTable:getQuestionType(self.id_)
	local limit = QuestionnaireTable:getChoices(self.id_)

	if flag then
		if limit == 1 and self.last_item_ then
			self.last_item_:refreshSelect(false)

			self.last_item_ = item
			self.select_items_ = {
				id
			}

			item:refreshSelect(true)

			return true
		elseif limit == 1 and self.last_item_ == nil then
			self.last_item_ = item
			self.select_items_ = {
				id
			}

			item:refreshSelect(true)

			return true
		end

		for k, v in pairs(self.select_items_) do
			if v == id then
				return false
			end
		end

		item:refreshSelect(true)
		table.insert(self.select_items_, id)

		self.last_item_ = item

		return true
	elseif type == 2 then
		local flag = false

		for k, v in pairs(self.select_items_) do
			if v == id then
				flag = true

				table.remove(self.select_items_, k)

				break
			end
		end

		if not flag then
			return false
		end

		self.last_item_ = nil

		item:refreshSelect(not flag)

		return true
	elseif self.last_item_ ~= nil and limit == 1 and self.last_item_.id_ == id then
		self.last_item_ = nil
		self.select_items_ = {}

		item:refreshSelect(false)

		return true
	end
end

function QuestionnaireWindow:onChange()
	if not self.cur_item_ or not self.cur_item_:getLabel() then
		return
	end

	local label = self.cur_item_:getLabel()
	local length = xyd.getStrLength(self.input_.value)
	local limit = tonumber(xyd.tables.miscTable:split2Cost("questionnaire_str_limit", "value", "|")[1])
	local max_line = tonumber(xyd.tables.miscTable:split2Cost("questionnaire_str_limit", "value", "|")[2])

	if limit < length or label.height > max_line * label.fontSize then
		if not self.lastTextValue then
			self.lastTextValue = ""
		end

		self.input_.value = self.lastTextValue

		self:onChange()
		xyd.alertTips(__("QUESTIONNAIRE_TIPS", max_line))

		return
	else
		self.lastTextValue = self.input_.value
	end

	if not self.lineNum then
		self.lineNum = 1
	end

	local pos = self.input_.caretVerts
	local pos_y = math.abs(tonumber(pos.y))
	local lineNum = math.floor(pos_y / label.fontSize)

	if lineNum ~= self.lineNum and lineNum > 12 then
		pos = Vector3(0, -149 + (lineNum - 12) * label.fontSize, 0)

		self:waitForFrame(2, function ()
			SpringPanel.Begin(self.scroller1_.gameObject, pos, 8)
		end)
	end

	if lineNum ~= self.lineNum and lineNum <= 12 then
		pos = Vector3(0, -149, 0)

		self:waitForFrame(2, function ()
			SpringPanel.Begin(self.scroller1_.gameObject, pos, 8)
		end)
	end

	self.lineNum = lineNum
end

function QuestionnaireWindowItem:ctor(params, parentGo, scrollerGo)
	QuestionnaireWindowItem.super.ctor(self, parentGo)

	self.select_ = false
	self.fill_text_ = xyd.tables.questionnaireOptionsTable:getIsFillable(params.id)
	self.scroller1_ = scrollerGo
	self.id_ = params.id
	self.comment_ = params.comment
	local itemTrans = self.go.transform
	self.descLabel_ = itemTrans:ComponentByName("group/descLabel", typeof(UILabel))
	self.selectImg_ = itemTrans:ComponentByName("group/selectImg", typeof(UISprite))
	self.selectIcon_ = itemTrans:ComponentByName("group/iconGroup/selectIcon", typeof(UISprite))
	self.notSelectIcon_ = itemTrans:ComponentByName("group/iconGroup/notSelectIcon", typeof(UISprite))
	self.touchGroup_ = itemTrans:ComponentByName("group/touchGroup", typeof(UIWidget)).gameObject
	self.textInput = itemTrans:NodeByName("textInput").gameObject
	self.textLabel_ = self.textInput:ComponentByName("textLabel_", typeof(UILabel))
	self.backLabel_ = self.textInput:ComponentByName("backLabel_", typeof(UILabel))
	UIEventListener.Get(self.touchGroup_).onClick = handler(self, self.onItemTouch)

	xyd.setDragScrollView(self.touchGroup_, self.scroller1_)
	self:refreshSelect(false)
	self:setLayout()
end

function QuestionnaireWindowItem.getPrefabPath()
	return "Prefabs/Components/questionnaire_window_item"
end

function QuestionnaireWindowItem:init(id, comment)
	self.id_ = id
	self.fill_text_ = xyd.tables.questionnaireOptionsTable:getIsFillable(id)
	self.comment_ = comment

	self:refreshSelect(false)
	self:setLayout()
end

function QuestionnaireWindowItem:onItemTouch()
	local win = xyd.WindowManager.get():getWindow("questionnaire_window")

	win:selectItem(self.id_, not self.select_, self)
end

function QuestionnaireWindowItem:setLayout()
	self.descLabel_.text = xyd.tables.questionnaireOptionsTextTable:getText(self.id_)

	if self.fill_text_ == 1 then
		self.textInput:SetActive(true)

		self.backLabel_.text = __("QUESTIONNAIRE_DEFAULT")
		local limit = xyd.tables.miscTable:split2num("questionnaire_other_limit", "value", "|")

		xyd.addTextInput(self.textLabel_, {
			type = xyd.TextInputArea.InputSingleLine,
			openCallBack = function ()
				self.backLabel_:SetActive(false)
			end,
			max_line = limit[2],
			max_length = limit[1],
			max_tips = __("QUESTIONNAIRE_OTHER_TIPS", limit[2])
		})

		if self.comment_ and #self.comment_ > 0 then
			self.textLabel_.text = self.comment_

			self.backLabel_:SetActive(false)
		end
	else
		self.textInput:SetActive(false)
	end
end

function QuestionnaireWindowItem:checkLegal()
	local flag1 = false
	local flag2 = false
	local flag3 = false

	if self.fill_text_ == 0 then
		flag1 = true
	end

	if self.fill_text_ ~= 0 then
		flag2 = true
		flag3 = self:checkLegalText(self.textLabel_.text)
	end

	return self.select_ and (flag1 or flag2 and flag3)
end

function QuestionnaireWindowItem:checkLegalText(text)
	if text == nil or text == "" then
		xyd.showToast(__("QUESTIONNAIRE_EMPTY"))

		return false
	end

	local str_limit = 200

	if xyd.Global.lang == "ja_jp" then
		str_limit = 400
	end

	if str_limit < xyd.getStrLength(text) then
		xyd.showToast(__("QUESTIONNAIRE_TOO_LONG"))

		return false
	end

	if xyd.tables.filterWordTable:isInWords(text) or xyd.tables.filterWordSuperTable:isInWords(text) then
		xyd.showToast(__("QUESTIONNAIRE_DIRTY"))

		return false
	end

	return true
end

function QuestionnaireWindowItem:refreshSelect(flag)
	self.select_ = flag

	if flag then
		xyd.setUISpriteAsync(self.selectImg_, "qustionnaire_web", "questionnaire_select_png", nil, )
	else
		xyd.setUISpriteAsync(self.selectImg_, "qustionnaire_web", "questionnaire_unselect_png", nil, )
	end

	self.selectIcon_:SetActive(flag)
	self.notSelectIcon_:SetActive(not flag)
end

function QuestionnaireWindowItem:getText()
	if self.fill_text_ == 1 then
		return self.textLabel_.text
	end

	return ""
end

function QuestionnaireMatrix:ctor(params, parentGo, scrollerGo)
	QuestionnaireMatrix.super.ctor(self, parentGo)

	self.items_ = {}
	self.id_ = params.id
	self.scroller1_ = scrollerGo
	local itemTrans = self.go.transform
	self.itemGroup_ = itemTrans:NodeByName("group/itemGroup").gameObject
	self.bg = itemTrans:ComponentByName("group/bg", typeof(UISprite))

	self:init()
end

function QuestionnaireMatrix.getPrefabPath()
	return "Prefabs/Components/questionnaire_matrix"
end

function QuestionnaireMatrix:init()
	local options = QuestionnaireTable:getOptions(self.id_)

	for i = 1, #options do
		local lab = self:createOptionLabel(i, #options)
		lab.label.text = xyd.tables.questionnaireOptionsTextTable:getText(options[i])

		if i == #options then
			local lastImg = lab.item:getGameObject():NodeByName("img")

			if lastImg and lastImg.gameObject then
				lastImg:SetActive(false)
			end
		end
	end

	local pro = QuestionnaireTable:getSubQuestion(self.id_)

	for i = 1, #pro do
		local item = QuestionnaireMatrixItem.new({
			id = pro[i],
			main_id = self.id_,
			is_last = i == #pro
		}, self.itemGroup_, self.scroller1_)

		table.insert(self.items_, item)
		item:getGameObject():SetLocalPosition(0, 290 - 114 * i, 0)
	end

	self.bg.height = 84 + 114 * #pro
end

function QuestionnaireMatrix:createOptionLabel(i, all)
	local item = QuestionnaireMatrixTop.new(self:getGameObject(), i == all)
	local label = item:getGameObject().transform:ComponentByName("descLabel", typeof(UILabel))

	item:getGameObject():SetLocalPosition(i * 126 - 383, 231, 0)

	return {
		label = label,
		item = item
	}
end

function QuestionnaireMatrixTop:ctor(parentGo, iflast)
	QuestionnaireMatrixTop.super.ctor(self, parentGo)
end

function QuestionnaireMatrixTop.getPrefabPath()
	return "Prefabs/Components/questionnaire_matrix_top"
end

function QuestionnaireMatrix:reqChoose()
	local op = ""

	for i = 0, #self.items_ - 1 do
		local item = self.items_[i + 1]

		if not item:checkComplete() then
			xyd.showToast(__("QUESTIONNAIRE_NO_SELECT_NEW"))

			return
		end

		local cur = item:getSelect()

		if #op > 0 then
			op = tostring(op) .. "|"
		end

		if not cur then
			op = tostring(op) .. "0"
		else
			op = tostring(op) .. tostring(cur)
		end
	end

	local msg = messages_pb:answer_questionnaire_req()
	msg.question_id = self.id_
	msg.options = op
	msg.comment = ""
	msg.questionnaire_type = QuestionnaireTable:getType(self.id_)

	xyd.Backend.get():request(xyd.mid.ANSWER_QUESTIONNAIRE, msg)
end

function QuestionnaireMatrixItem:ctor(params, parentGo, scrollerGo)
	QuestionnaireMatrixItem.super.ctor(self, parentGo)

	self.id_ = params.id
	self.main_id_ = params.main_id
	self.is_last_ = params.is_last
	self.options_ = QuestionnaireTable:getOptions(params.main_id)
	self.cur_select_ = nil
	self.cur_img_ = nil
	self.scroller1_ = scrollerGo
	local itemTrans = self.go.transform
	self.titleLabel_ = itemTrans:ComponentByName("group/titleLabel", typeof(UILabel))
	self.img_ = itemTrans:ComponentByName("group/img", typeof(UISprite))
	self.itemGroup_ = itemTrans:NodeByName("group/itemGroup").gameObject
	self.btnJump = itemTrans:NodeByName("group/btnJump").gameObject

	self:init(parentGo)
end

function QuestionnaireMatrixItem.getPrefabPath()
	return "Prefabs/Components/questionnaire_matrix_item"
end

function QuestionnaireMatrixItem:init(parentGo)
	self.titleLabel_.text = xyd.tables.questionnaireTextTable:getText(self.id_)
	local checkType = xyd.tables.questionnaireTable:getCheckType(self.id_)

	if checkType and checkType > 0 then
		self.btnJump:SetActive(true)

		local jumpID = xyd.tables.questionnaireTable:getCheckID(self.id_)
		UIEventListener.Get(self.btnJump).onClick = handler(self, function ()
			if checkType == 1 then
				xyd.WindowManager.get():openWindow("guide_detail_window", {
					partners = {
						{
							table_id = jumpID
						}
					},
					table_id = jumpID,
					closeCallBack = function ()
						xyd.WindowManager.get():openWindow("questionnaire_window", {
							current_id = self.main_id_
						})
					end
				})
				xyd.WindowManager.get():closeWindowsOnLayer(6)
			elseif checkType == 2 then
				xyd.WindowManager.get():openWindow("collection_skin_detail_window", {
					skin_id = jumpID,
					closeCallBack = function ()
						xyd.WindowManager.get():openWindow("questionnaire_window", {
							current_id = self.main_id_
						})
					end
				})
				xyd.WindowManager.get():closeWindowsOnLayer(6)
			elseif checkType == 3 then
				local office_id = xyd.tables.senpaiDressItemTable:getGroup(jumpID)

				xyd.WindowManager.get():openWindow("dress_check_office_window", {
					showALL = true,
					office_id = office_id
				})
			end
		end)
	else
		self.titleLabel_:X(-295)

		self.titleLabel_.width = 590

		self.btnJump:SetActive(false)
	end

	for i = 1, #self.options_ do
		local obj = NGUITools.AddChild(self.itemGroup_, "icon" .. i)
		local sp = obj:AddComponent(typeof(UISprite))

		xyd.setUISpriteAsync(sp, "CommonUI", "setting_up_lan1_png", nil, )

		sp:GetComponent(typeof(UIWidget)).width = 40
		sp:GetComponent(typeof(UIWidget)).height = 40

		obj:SetLocalPosition(i * 128 - 389, 0, 0)
		obj:AddComponent(typeof(UIDragScrollView))

		local bc = obj:AddComponent(typeof(UnityEngine.BoxCollider))
		bc.size = Vector3(60, 60, 0)
		sp.depth = self:getGameObject():GetComponent(typeof(UIWidget)).depth + 1
		UIEventListener.Get(obj).onClick = handler(self, function ()
			if self.cur_select_ ~= self.options_[i] then
				xyd.setUISpriteAsync(sp, "CommonUI", "setting_up_lan2_png", nil, )

				self.cur_select_ = self.options_[i]

				if self.cur_img_ then
					xyd.setUISpriteAsync(self.cur_img_, "CommonUI", "setting_up_lan1_png", nil, )
				end

				self.cur_img_ = sp
			end
		end)
	end

	if self.is_last_ then
		self.img_.gameObject:SetActive(false)
	end
end

function QuestionnaireMatrixItem:checkComplete()
	if self.cur_select_ ~= nil or QuestionnaireTable:getIsOptional(self.id_) ~= 0 then
		return true
	end

	return false
end

function QuestionnaireMatrixItem:getSelect()
	return self.cur_select_
end

function QuestionnaireFill:ctor(params, parentGo)
	self.id_ = params.id
	self.commnet_ = params.comment

	self:init(parentGo)
end

function QuestionnaireFill:init(parentGo)
	QuestionnaireFill.super.ctor(self, parentGo)

	local itemTrans = self.go.transform
	self.label_ = itemTrans:ComponentByName("group/label", typeof(UILabel))
	self.input_ = itemTrans:ComponentByName("group/input", typeof(UIInput))
end

function QuestionnaireFill.getPrefabPath()
	return "Prefabs/Components/questionnaire_fill_item"
end

function QuestionnaireFill:getLabel()
	return self.label_
end

function QuestionnaireFill:reqChoose()
	if not self:checkComplete() then
		return
	end

	local msg = messages_pb:answer_questionnaire_req()
	msg.question_id = self.id_
	msg.options = ""
	msg.comment = self.label_.text
	msg.questionnaire_type = QuestionnaireTable:getType(self.id_)

	xyd.Backend.get():request(xyd.mid.ANSWER_QUESTIONNAIRE, msg)
end

function QuestionnaireFill:checkComplete()
	local str_limit = 1000

	if xyd.Global.lang == "ja_jp" then
		str_limit = 2000
	end

	if str_limit < xyd.getStrLength(tostring(self.label_.text)) then
		xyd.showToast(__("QUESTIONNAIRE_TOO_LONG"))

		return false
	end

	return true
end

function QuestionnaireWindow:dispose()
	QuestionnaireWindow.super.dispose(self)
end

return QuestionnaireWindow
