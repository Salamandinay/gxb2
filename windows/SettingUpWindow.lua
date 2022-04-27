local BaseWindow = import(".BaseWindow")
local SettingUpWindow = class("SettingUpWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")

function SettingUpWindow:ctor(name, params)
	SettingUpWindow.super.ctor(self, name, params)
end

function SettingUpWindow:initWindow()
	SettingUpWindow.super.initWindow(self)
	self:getUIComponent()
	SettingUpWindow.super.register(self)
	self:layout()
	self:updateNoticeShow()
	self:initResItem()
	self:registerEvent()
	xyd.models.heroChallenge:reqHeroChallengeChessInfo()
end

function SettingUpWindow:getUIComponent()
	local trans = self.window_.transform
	self.bg_ = trans:ComponentByName("bg_", typeof(UITexture))
	local groupMain_ = trans:NodeByName("groupMain_").gameObject
	self.btnMemories_ = groupMain_:ComponentByName("btnMemories_", typeof(UISprite)).gameObject
	self.btnMemories_redPoint = groupMain_:NodeByName("btnMemories_/redPoint").gameObject
	self.labelMemory = self.btnMemories_:ComponentByName("labelMemory", typeof(UILabel))
	self.btnAchieve_ = groupMain_:ComponentByName("btnAchieve_", typeof(UISprite)).gameObject
	self.btnAchieve_redPoint = groupMain_:NodeByName("btnAchieve_/redPoint").gameObject
	self.labelAchieve = self.btnAchieve_:ComponentByName("labelAchieve", typeof(UILabel))
	self.gLace_1 = groupMain_:ComponentByName("gLace_1", typeof(UIWidget))
	self.labelTips1 = groupMain_:ComponentByName("gLace_1/labelTips1", typeof(UILabel))
	self.lace_1_left = groupMain_:ComponentByName("gLace_1/lace_1_left", typeof(UIWidget))
	self.lace_1_right = groupMain_:ComponentByName("gLace_1/lace_1_right", typeof(UIWidget))
	self.btnNotice_ = groupMain_:ComponentByName("btnNotice_", typeof(UISprite)).gameObject
	self.labelNotice = self.btnNotice_:ComponentByName("labelNotice", typeof(UILabel))
	self.btnHelp_ = groupMain_:ComponentByName("btnHelp_", typeof(UISprite)).gameObject
	self.labelHelp = self.btnHelp_:ComponentByName("labelHelp", typeof(UILabel))
	self.btnEnhance_ = groupMain_:ComponentByName("btnEnhance_", typeof(UISprite)).gameObject
	self.labelEnhance = self.btnEnhance_:ComponentByName("labelEnhance", typeof(UILabel))
	self.btnCommunity_ = groupMain_:ComponentByName("btnCommunity_", typeof(UISprite)).gameObject
	self.labelCommunity = self.btnCommunity_:ComponentByName("labelCommunity", typeof(UILabel))
	self.btnCommunity_redPoint = self.btnCommunity_:ComponentByName("redMark", typeof(UISprite))
	self.btnGM_ = groupMain_:ComponentByName("btnGM_", typeof(UISprite)).gameObject
	self.btnGM_redPoint = groupMain_:ComponentByName("btnGM_/redPoint", typeof(UISprite)).gameObject
	self.btnGameNotice_ = groupMain_:NodeByName("btnGameNotice").gameObject
	self.btnGameNoticeRed_ = groupMain_:NodeByName("btnGameNotice/redPoint").gameObject
	self.btnGameNoticeLabel_ = groupMain_:ComponentByName("btnGameNotice/labelGameNotice", typeof(UILabel))
	self.labelGM = self.btnGM_:ComponentByName("labelGM", typeof(UILabel))
	self.btnAgreement_ = groupMain_:ComponentByName("btnAgreement_", typeof(UISprite)).gameObject
	self.labelAgreement = self.btnAgreement_:ComponentByName("labelAgreement", typeof(UILabel))
	self.gLace_2 = groupMain_:ComponentByName("gLace_2", typeof(UIWidget))
	self.lace_2_left = groupMain_:ComponentByName("gLace_2/lace_2_left", typeof(UIWidget))
	self.lace_2_right = groupMain_:ComponentByName("gLace_2/lace_2_right", typeof(UIWidget))
	self.labelTips2 = groupMain_:ComponentByName("gLace_2/labelTips2", typeof(UILabel))
	self.btnComic_ = groupMain_:ComponentByName("btnComic_", typeof(UISprite)).gameObject
	self.btnComic_redPoint = groupMain_:ComponentByName("btnComic_/redPoint", typeof(UISprite)).gameObject
	self.labelComic = self.btnComic_:ComponentByName("labelComic", typeof(UILabel))
	self.btnBackground_ = groupMain_:ComponentByName("btnBackground_", typeof(UISprite)).gameObject
	self.btnBackground_redPoint = groupMain_:ComponentByName("btnBackground_/redPoint", typeof(UISprite)).gameObject
	self.labelBackground = self.btnBackground_:ComponentByName("labelBackground", typeof(UILabel))
	self.btnAward_ = groupMain_:ComponentByName("btnAward_", typeof(UISprite)).gameObject
	self.labelAward = self.btnAward_:ComponentByName("labelAward", typeof(UILabel))
	self.btnQuestionnare_ = groupMain_:ComponentByName("btnQuestionnare_", typeof(UISprite)).gameObject
	self.btnQuestionnare_redPoint = groupMain_:ComponentByName("btnQuestionnare_/redPoint", typeof(UISprite)).gameObject
	self.labelQuestionnare = self.btnQuestionnare_:ComponentByName("labelQuestionaire", typeof(UILabel))
	local timeLabel = self.btnQuestionnare_:ComponentByName("timeLabel", typeof(UILabel))
	self.timeLabel = require("app.components.CountDown").new(timeLabel)
	self.endLabel = self.btnQuestionnare_:ComponentByName("endLabel", typeof(UILabel))
	self.bubble = groupMain_:ComponentByName("bubble", typeof(UIWidget))
	self.labelBindBubble = self.bubble:ComponentByName("labelBindBubble", typeof(UILabel))

	if xyd.Global.lang == "de_de" then
		self.btnBackground_.transform:X(-225)
		self.btnAward_.transform:X(0)
	end
end

function SettingUpWindow:checkBindBubble()
	if not xyd.models.achievement:getBindAchievementRecord() then
		self.bubble.alpha = 0.01

		self.bubble:SetActive(true)

		local bubble = self.bubble
		local seq = self:getSequence()

		seq:AppendInterval(0.5)
		seq:AppendCallback(function ()
			xyd.models.achievement:setBindAchievementRecord(true)

			local function getter()
				return bubble.alpha
			end

			local function setter(value)
				bubble.alpha = value
			end

			local seq1 = self:getSequence()

			seq1:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0.01, 1, 1))
			seq1:AppendInterval(3)
			seq1:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0, 0.5))
			seq1:AppendCallback(function ()
				if not tolua.isnull(bubble) and not tolua.isnull(bubble.gameObject) then
					bubble:SetActive(false)
				end
			end)
		end)
	end
end

function SettingUpWindow:layout()
	xyd.setUITextureAsync(self.bg_, "Textures/scenes_web/setting_up_bg", function ()
	end)

	self.labelTips1.text = __("SETTING_UP_1")
	self.labelTips2.text = __("SETTING_UP_2")
	self.labelMemory.text = __("SETTING_UP_3")
	self.labelAchieve.text = __("COLLECTION_TITLE")
	self.labelNotice.text = __("SETTING_UP_5")
	self.labelHelp.text = __("SETTING_UP_6")
	self.labelEnhance.text = __("SETTING_UP_7")
	self.labelComic.text = __("SETTING_UP_9")
	self.labelCommunity.text = __("SETTING_UP_10")
	self.labelAward.text = __("SETTING_UP_AWARD_1")
	self.labelBackground.text = __("SETTING_UP_BACKGROUND")
	self.labelQuestionnare.text = __("QUESTIONNAIRE_ICON")
	self.labelGM.text = __("CHAT_LABEL_1")
	self.btnGameNoticeLabel_.text = __("SETTING_UP_11")

	if xyd.Global.lang == "ja_jp" then
		self.labelAgreement.text = __("SETTING_UP_AGREEMENT")
	end

	if xyd.Global.isReview == 1 then
		self.btnAgreement_:X(259)
		self.btnAward_:X(-259)
	end

	if not xyd.checkFunctionOpen(xyd.FunctionID.COMIC, true) then
		xyd.applyChildrenGrey(self.btnComic_)
	end

	if not xyd.checkFunctionOpen(xyd.FunctionID.BACKGROUND, true) then
		xyd.applyChildrenGrey(self.btnBackground_)
	end

	xyd.models.redMark:setMarkImg(xyd.RedMarkType.STORY_LIST_MEMORY, self.btnMemories_redPoint)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.COLLECTION_SHOP,
		xyd.RedMarkType.COLLECTION_SHOP_2
	}, self.btnAchieve_redPoint)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.COMIC, self.btnComic_redPoint)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.BACKGROUND, self.btnBackground_redPoint)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.QUESTIONNAIRE, self.btnQuestionnare_redPoint)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.GM_CHAT, self.btnGM_redPoint)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.COMMUNITY_ACTIVITY, self.btnCommunity_redPoint)
end

function SettingUpWindow:initResItem()
	self.windowTop = WindowTop.new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function SettingUpWindow:registerEvent()
	UIEventListener.Get(self.btnMemories_).onClick = handler(self, self.onBtnMemoriesTouch)
	UIEventListener.Get(self.btnAchieve_).onClick = handler(self, self.onBtnAchieveTouch)
	UIEventListener.Get(self.btnNotice_).onClick = handler(self, self.onBtnNoticeTouch)
	UIEventListener.Get(self.btnHelp_).onClick = handler(self, self.onBtnHelpTouch)
	UIEventListener.Get(self.btnEnhance_).onClick = handler(self, self.onBtnEnhanceTouch)
	UIEventListener.Get(self.btnComic_).onClick = handler(self, self.onBtnComicTouch)
	UIEventListener.Get(self.btnCommunity_).onClick = handler(self, self.onBtnCommunityTouch)
	UIEventListener.Get(self.btnAward_).onClick = handler(self, self.onAwardTouch)
	UIEventListener.Get(self.btnBackground_).onClick = handler(self, self.onBackgroundTouch)
	UIEventListener.Get(self.btnQuestionnare_).onClick = handler(self, self.onQuestionnareTouch)
	UIEventListener.Get(self.btnGM_).onClick = handler(self, self.onBtnGMTouch)

	if xyd.Global.lang == "ja_jp" then
		UIEventListener.Get(self.btnAgreement_).onClick = handler(self, self.onAgreementTouch)
	end

	UIEventListener.Get(self.btnGameNotice_).onClick = function ()
		xyd.WindowManager.get():openWindow("new_notice_window", {})
	end
end

function SettingUpWindow:onBackgroundTouch()
	if not xyd.checkFunctionOpen(xyd.FunctionID.BACKGROUND) then
		return
	end

	xyd.WindowManager:get():openWindow("background_window")
end

function SettingUpWindow:onAgreementTouch()
	xyd.WindowManager:get():openWindow("agreement_choose_window")
end

function SettingUpWindow:onDoctor()
	xyd.WindowManager:get():openWindow("system_doctor_window")
end

function SettingUpWindow:onBtnMemoriesTouch()
	xyd.WindowManager:get():openWindow("story_list_window")
end

function SettingUpWindow:onBtnAchieveTouch()
	xyd.WindowManager:get():openWindow("collection_window")
end

function SettingUpWindow:onBtnNoticeTouch()
	xyd.WindowManager:get():openWindow("notice_window")
end

function SettingUpWindow:onBtnHelpTouch()
	xyd.WindowManager:get():openWindow("setting_up_info_window")
end

function SettingUpWindow:onBtnEnhanceTouch()
	xyd.WindowManager:get():openWindow("enhance_window")
end

function SettingUpWindow:onBtnGMTouch()
	xyd.WindowManager:get():openWindow("chat_gm_window")
end

function SettingUpWindow:onBtnComicTouch()
	if not xyd.checkFunctionOpen(xyd.FunctionID.COMIC) then
		return
	end

	xyd.WindowManager:get():openWindow("comic_window")
end

function SettingUpWindow:onBtnCommunityTouch()
	if xyd.models.community:getActInfo() and #xyd.models.community:getActInfo() > 0 and xyd.models.community:checkLegal() then
		xyd.WindowManager:get():openWindow("community_activity_window")
	else
		xyd.WindowManager:get():openWindow("setting_up_community_window")
	end
end

function SettingUpWindow:onAwardTouch()
	xyd.WindowManager:get():openWindow("setting_up_award_window")
end

function SettingUpWindow:onQuestionnareTouch()
	local st_time = tonumber(xyd.tables.miscTable:getVal("new_questionnaire_begin_time"))
	local ed_time = tonumber(xyd.tables.miscTable:getVal("new_questionnaire_end_time"))
	local cur_questionnaire_type = xyd.tables.miscTable:getNumber("new_questionnaire_type", "value")
	local cur_time = xyd:getServerTime()

	if cur_time < st_time then
		return
	end

	if ed_time < cur_time then
		xyd.showToast(__("QUESTIONNAIRE_OVER"))

		return
	end

	local limit_lev = xyd.tables.miscTable:getNumber("new_questionnaire_level_limit", "value")
	local cur_lev = xyd.models.backpack:getLev()

	if cur_lev < limit_lev then
		xyd.showToast(__("QUESTIONNAIRE_LOWER"))

		return
	end

	local list = nil
	local infos = xyd.models.selfPlayer:getQuestionnaireInfo()

	for i = 1, #infos do
		if infos[i].questionnaire_type == cur_questionnaire_type then
			list = infos[i]

			break
		end
	end

	if not list then
		return
	end

	local id = list.current_id
	local finish = list.is_finished

	if finish == 1 then
		xyd.showToast(__("QUESTIONNAIRE_FINISHED"))

		return
	end

	local is_first = xyd.tables.questionnaireTable:isFirst(id)

	if is_first == 1 then
		xyd.WindowManager.get():openWindow("questionnaire_start_window", {
			id = id
		})
	else
		xyd.WindowManager.get():openWindow("questionnaire_window", list)
	end
end

function SettingUpWindow.bindFunc(func, this, ...)
	local args = {
		...
	}

	return function (__, ...)
		local tmpArgs = {
			...
		}
		local i = 1

		while i <= #args do
			table.insert(tmpArgs, i, args[i])

			i = i + 1
		end

		return func(this, unpack(tmpArgs))
	end
end

function SettingUpWindow:playOpenAnimation(callback)
	SettingUpWindow.super.playOpenAnimation(self, callback)

	local action = self:getSequence()

	if xyd.Global.isReview == 0 then
		action:AppendInterval(0.034)
		action:AppendCallback(self.bindFunc(self.itemAnimation, self, self.btnMemories_))
	end

	action:AppendInterval(0.034)
	action:AppendCallback(self.bindFunc(self.itemAnimation, self, self.btnAchieve_))
	action:AppendCallback(self.bindFunc(self.lineAnimation, self, self.gLace_1, self.lace_1_left, self.lace_1_right, self.labelTips1))
	action:AppendInterval(0.034)
	action:AppendCallback(self.bindFunc(self.itemAnimation, self, self.btnNotice_))
	action:AppendInterval(0.034)
	action:AppendCallback(self.bindFunc(self.itemAnimation, self, self.btnHelp_))
	action:AppendInterval(0.034)
	action:AppendCallback(self.bindFunc(self.itemAnimation, self, self.btnEnhance_))
	action:AppendInterval(0.034)
	action:AppendCallback(self.bindFunc(self.itemAnimation, self, self.btnCommunity_))
	action:AppendInterval(0.034)
	action:AppendCallback(self.bindFunc(self.itemAnimation, self, self.btnGM_))
	action:AppendInterval(0.034)

	if xyd.models.settingUp:getShowNoticeBtn() then
		action:AppendInterval(0.034)
		action:AppendCallback(self.bindFunc(self.itemAnimation, self, self.btnGameNotice_))
	end

	if xyd.Global.lang == "ja_jp" then
		action:AppendInterval(0.034)
		action:AppendCallback(self.bindFunc(self.itemAnimation, self, self.btnAgreement_))
	end

	action:AppendInterval(0.034)
	action:AppendCallback(self.bindFunc(self.lineAnimation, self, self.gLace_2, self.lace_2_left, self.lace_2_right, self.labelTips2))

	if xyd.Global.lang ~= "de_de" then
		action:AppendInterval(0.034)
		action:AppendCallback(self.bindFunc(self.itemAnimation, self, self.btnComic_))
	end

	action:AppendInterval(0.034)
	action:AppendCallback(self.bindFunc(self.itemAnimation, self, self.btnBackground_))

	if xyd.Global.isReview ~= 1 then
		action:AppendInterval(0.034)
		action:AppendCallback(self.bindFunc(self.itemAnimation, self, self.btnAward_))
	end

	local st_time = xyd.tables.miscTable:getNumber("new_questionnaire_begin_time", "value")
	local ed_time = xyd.tables.miscTable:getNumber("new_questionnaire_end_time", "value")
	local cur_time = xyd:getServerTime()
	local limit_lev = xyd.tables.miscTable:getNumber("new_questionnaire_level_limit", "value")
	local cur_lev = xyd.models.backpack:getLev()

	if st_time <= cur_time and cur_time <= ed_time and limit_lev <= cur_lev then
		action:AppendInterval(0.034)
		action:AppendCallback(self.bindFunc(self.itemAnimation, self, self.btnQuestionnare_))
		action:AppendCallback(self.bindFunc(self.setWndComplete, self))
		self.endLabel:SetActive(false)
		self.timeLabel:setCountDownTime(ed_time - cur_time)

		self.timeLabel.right = 20

		if xyd.Global.lang == "ja_jp" then
			self.btnGameNotice_:SetLocalPosition(0, -139, 0)
		end
	else
		if xyd.Global.lang == "ja_jp" then
			self.btnGameNotice_:SetLocalPosition(-225, -139, 0)
		end

		action:AppendCallback(self.bindFunc(self.setWndComplete, self))
	end
end

function SettingUpWindow:updateNoticeShow()
	self.btnGameNoticeRed_:SetActive(xyd.models.settingUp:checkNoticeShow())
end

function SettingUpWindow:itemAnimation(item)
	item:SetActive(true)

	item:GetComponent(typeof(UIWidget)).alpha = 0

	local function setter(value)
		item:GetComponent(typeof(UIWidget)).alpha = value
	end

	self:waitForFrame(1, function ()
		item:GetComponent(typeof(UIWidget)).alpha = 0.5
		item.transform.localScale = Vector3(0.8, 0.8, 1)
		local action = self:getSequence()

		action:Insert(0, item.transform:DOScale(Vector3(1.05, 1.05, 1), 0.13))
		action:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0.5, 1, 0.13))
		action:Insert(0.13, item.transform:DOScale(Vector3(1, 1, 1), 0.07))
	end, nil)
end

function SettingUpWindow:lineAnimation(groupBot_, imgBot1, imgBot2, labelName_)
	local function setter1(value)
		imgBot1.alpha = value
	end

	local function setter2(value)
		imgBot2.alpha = value
	end

	local function setter3(value)
		labelName_.alpha = value
	end

	local y1 = imgBot1.transform.localPosition.y
	local y2 = imgBot2.transform.localPosition.y

	groupBot_:SetActive(true)

	imgBot1.transform.localPosition = Vector3(-200, y1, 0)
	imgBot2.transform.localPosition = Vector3(200, y2, 0)
	labelName_.alpha = 0.01
	local action = self:getSequence()

	action:Insert(0, imgBot1.transform:DOLocalMove(Vector3(-156, y1, 0), 0.2))
	action:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0.01, 1, 0.2))
	action:Insert(0, imgBot2.transform:DOLocalMove(Vector3(156, y2, 0), 0.2))
	action:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0.01, 1, 0.2))
	action:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), 0.01, 1, 0.2))
	action:Insert(0.2, imgBot1.transform:DOLocalMove(Vector3(-176, y1, 0), 0.2))
	action:Insert(0.2, imgBot2.transform:DOLocalMove(Vector3(176, y2, 0), 0.2))
end

return SettingUpWindow
