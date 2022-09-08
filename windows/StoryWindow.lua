local StorySelectItem = class("StorySelectItem")

function StorySelectItem:ctor(go)
	self.go = go
end

function StorySelectItem:setInfo(params)
	self.text_ = ""
	self.index_ = 0
	self.nextID_ = 0
	self.text_ = params.text or ""
	self.index_ = params.index
	self.nextID_ = params.nextID
	self.records_ = params.records
	self.type = params.type
	self.storyID = params.storyID
	local label = self.go:ComponentByName("label", typeof(UILabel))
	label.text = self.text_
	UIEventListener.Get(self.go).onClick = handler(self, self.onTouch)

	if xyd.Global.lang == "en_en" then
		label.fontSize = 20
	end

	if self.type == xyd.StoryType.ACTIVITY_VALENTINE then
		local limit = xyd.tables.activityValentinePlotTable:getSelectLimit(self.storyID)
		local data = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_VALENTINE)

		if data and #limit > 0 and limit[self.index_] > 0 then
			local openDay = xyd.tables.activityValentinePlotTable:getOpenDay(self.storyID) - 1
			local pastDays = (xyd.getServerTime() - data.start_time) / xyd.TimePeriod.DAY_TIME

			if openDay > pastDays then
				self.limit_time = data.start_time + openDay * 24 * 60 * 60 - xyd.getServerTime()
			end
		end

		local nextIDs = self.nextID_
		local round_flag = xyd.db.misc:getValue("activity_valentine_round_flag") or 0
		self.nextID_ = nextIDs[1]

		if nextIDs[2] and tonumber(round_flag) > 0 then
			self.nextID_ = nextIDs[2]
		end
	end
end

function StorySelectItem:onTouch()
	if self.limit_time and self.limit_time > 0 then
		xyd.alertTips(__("ACTIVITY_VALENTINE_LOCK_TIPS", xyd.secondsToString(self.limit_time, xyd.SECOND2STR.NOMINU)))

		return
	end

	local wnd = xyd.WindowManager.get():getWindow("story_window")

	if wnd then
		if self.records_ then
			table.insert(self.records_, {
				is_select = true,
				name = xyd.Global.playerName,
				dialog = self.text_
			})
		end

		wnd:onSelectTouch(self.nextID_)
	end
end

local StoryWindow = class("StoryWindow", import(".BaseWindow"))
local ParnterImg = import("app.components.PartnerImg")
local PartnerPictureTable = xyd.tables.partnerPictureTable
local CustomBackgroundTable = xyd.tables.customBackgroundTable
local StoryCG = import("app.components.StoryCG")
local ActivityEffectPlayer = import("app.common.ActivityEffectPlayer")
local MapSwapColor = {
	[1.0] = 257,
	[2.0] = 4294967041.0,
	[3] = xyd.Battle.effect_switch
}

function StoryWindow:ctor(name, params)
	StoryWindow.super.ctor(self, name, params)

	self.storyType_ = xyd.StoryType.PARTNER
	self.storyID_ = 0
	self.timesLines_ = {}
	self.images_ = {}
	self.deltaX = 0
	self.deltaY = 0
	self.delayTime = 0.04
	self.textEffectTimeoutId = nil
	self.autoTimeKey_ = -1
	self.isAuto_ = false
	self.tmpAuto_ = false
	self.records_ = {}
	self.bigPics_ = {}
	self.callback = nil
	self.saveCallback = nil
	self.isSkip_ = false
	self.effectNames_ = {}
	self.curEffects_ = {}
	self.isPlayText = false
	self.isPlayEnter = false
	self.isPlayEixt = false
	self.isPlayCgEnter = false
	self.isPlayCgExit = false
	self.isPlayBg = false
	self.isPlayContent = false
	self.isShowSelect = false
	self.isDisappear = false
	self.musicID_ = 0
	self.soundID_ = 0
	self.curSingleEffectNum_ = 0
	self.story_id_pool_ = {}
	self.isShowSwitch = false
	self.is_back_ = false
	self.no_click_timeout_id_ = nil
	self.effectGroupPool_ = {}
	self.effectGroupInUse_ = {}
	self.ambientSounds = {}
	self.lastMemoryType = -1
	self.jumpToSelect = false
	self.memory = {
		{
			"bg_",
			"storyCG0_",
			"storyCG1_",
			"groupMain_"
		},
		{
			"bg_",
			"storyCG0_",
			"storyCG1_",
			"groupMain_"
		}
	}
	self.curExpressionID = 0
	self.curExpressionCount = 0
	self.isWndShake = false
	self.storyType_ = params.story_type
	self.isShowSwitch = params.isShowSwitch

	if params.story_list then
		self.story_id_pool_ = params.story_list
	elseif params.story_id then
		self.story_id_pool_ = {
			params.story_id
		}
	end

	self.callback = params.callback
	self.saveCallback = params.save_callback
	self.is_back_ = params.is_back
	self.effectPlayer = ActivityEffectPlayer.new()

	if xyd.Global.lang == "en_en" then
		self.delayTime = 0.02
	end

	self.storyID_ = table.remove(self.story_id_pool_, 1)

	self:initTable()

	local needLoadRes = xyd.getStoryLoadRes(self.storyID_, self.storyType_, self.bigPics_, self.effectNames_)

	for i = 1, #self.story_id_pool_ do
		local id = self.story_id_pool_[i]
		local tmpRes = xyd.getStoryLoadRes(id, self.storyType_, self.bigPics_, self.effectNames_)

		for j = 1, #tmpRes do
			if xyd.arrayIndexOf(needLoadRes, tmpRes[j]) < 0 then
				table.insert(needLoadRes, tmpRes[j])
			end
		end
	end

	if params.extra_res then
		needLoadRes = xyd.arrayMerge(needLoadRes, params.extra_res)
	end

	if params.extra_fx then
		needLoadRes = xyd.arrayMerge(needLoadRes, xyd.getEffectFilesByNames(params.extra_fx))
	end

	if params.jumpToSelect then
		self.jumpToSelect = params.jumpToSelect
	end

	self:setResourcePaths(needLoadRes)
end

function StoryWindow:playOpenAnimation(callback)
	if callback then
		callback()
	end

	local flag = (self.storyType_ == xyd.StoryType.OTHER or self.storyType_ == xyd.StoryType.ACTIVITY or self.storyType_ == xyd.StoryType.MAIN or self.storyType_ == xyd.StoryType.PARTNER) and self.isShowSwitch

	if not flag then
		local blackScreen = self.window_:ComponentByName("e:Image", typeof(UISprite))
		local loadingText = blackScreen:ComponentByName("loadingText", typeof(UILabel))
		loadingText.text = __("PLOT_LOADING")
		local loadingPartnerGroup = blackScreen:NodeByName("loadingPartnerGroup").gameObject
		local effect = xyd.Spine.new(loadingPartnerGroup)

		effect:setInfo("loading", function ()
			effect:play("idle", 0)
		end)

		local w = blackScreen:GetComponent(typeof(UIWidget))
		local getter, setter = xyd.getTweenAlphaGeterSeter(w)
		local sequence = self:getSequence()

		sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0.01, 0))
		sequence:AppendCallback(function ()
			blackScreen.depth = 40

			self.window_:NodeByName("center").gameObject:SetActive(false)
			self.window_:NodeByName("bottom").gameObject:SetActive(false)
			self.window_:NodeByName("btnSkipGroup_").gameObject:SetActive(false)
			self.winBg_:SetActive(false)
			loadingText:SetActive(true)
			loadingPartnerGroup:SetActive(true)
		end)
		sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.86))

		local function resGroupSetter(value)
			effect:setAlpha(value)
		end

		sequence:Join(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(resGroupSetter), 0.01, 1, 0.86):SetEase(DG.Tweening.Ease.Linear))
		sequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(resGroupSetter), 1, 0.01, 0.33):SetEase(DG.Tweening.Ease.Linear))

		local getterL, setterL = xyd.getTweenAlphaGeterSeter(loadingText)

		sequence:Join(DG.Tweening.DOTween.ToAlpha(getterL, setterL, 0.01, 0.33))
		sequence:AppendCallback(function ()
			self.window_:NodeByName("center").gameObject:SetActive(true)
			self.window_:NodeByName("bottom").gameObject:SetActive(true)
			self.window_:NodeByName("btnSkipGroup_").gameObject:SetActive(true)
			self.winBg_:SetActive(true)
			loadingText:SetActive(false)
			loadingPartnerGroup:SetActive(false)
			effect:destroy()

			effect = nil

			self:startStory()
		end)
		sequence:Insert(1.06, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.01, 1.5))
		sequence:AppendCallback(function ()
			blackScreen.depth = 0

			sequence:Kill(false)

			sequence = nil
		end)

		return
	end

	self:startStory()
end

function StoryWindow:initWindow()
	StoryWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function StoryWindow:getUIComponent()
	local winTrans = self.window_.transform
	local centerObj = winTrans:NodeByName("center").gameObject
	self.bg_ = centerObj:ComponentByName("bg_", typeof(UITexture))
	self.bg2_ = centerObj:ComponentByName("bg2_", typeof(UISprite))
	self.groupLayer1_ = centerObj:NodeByName("groupLayer1_").gameObject
	self.groupLayer2_ = centerObj:NodeByName("groupLayer2_").gameObject
	self.groupLayer3_ = centerObj:NodeByName("groupLayer3_").gameObject
	self.groupLayer4_ = centerObj:NodeByName("groupLayer4_").gameObject
	local storyCG0Obj_ = centerObj:NodeByName("storyCG0_").gameObject
	self.storyCG0_ = StoryCG.new(storyCG0Obj_)
	local storyCG1Obj_ = centerObj:NodeByName("storyCG1_").gameObject
	self.storyCG1_ = StoryCG.new(storyCG1Obj_)
	self.groupMain_ = centerObj:NodeByName("groupMain_").gameObject
	self.smallPicShowBg_ = self.groupMain_:ComponentByName("smallPicShowBg_", typeof(UITexture))
	self.imgTouch_ = centerObj:NodeByName("imgTouch_").gameObject
	local bottomObj = winTrans:NodeByName("bottom").gameObject
	self.textGroup = bottomObj:NodeByName("textGroup").gameObject
	self.textBgGroup0 = self.textGroup:NodeByName("textBgGroup0").gameObject
	self.labelName0 = self.textBgGroup0:ComponentByName("e:Group/labelName0", typeof(UILabel))
	self.imgName0 = self.textBgGroup0:ComponentByName("e:Group/imgName0", typeof(UITexture))
	self.textBgGroup1 = self.textGroup:NodeByName("textBgGroup1").gameObject
	self.textBgGroup2 = self.textGroup:NodeByName("textBgGroup2").gameObject
	self.labelName2 = self.textBgGroup2:ComponentByName("e:Group/labelName2", typeof(UILabel))
	self.imgName2 = self.textBgGroup2:ComponentByName("e:Group/imgName2", typeof(UITexture))
	self.labelDialog_ = self.textGroup:ComponentByName("labelDialog_", typeof(UILabel))
	self.groupBtns_ = bottomObj:NodeByName("groupBtns_").gameObject
	self.btnBottomSkip_ = self.groupBtns_:NodeByName("btnBottomSkip_").gameObject
	self.btnAuto_ = self.groupBtns_:NodeByName("btnAuto_").gameObject
	self.btnRecord_ = self.groupBtns_:NodeByName("btnRecord_").gameObject
	self.btnBottomSkipNew_ = self.groupBtns_:NodeByName("btnBottomSkipNew_").gameObject
	self.btnSaveGroup_ = winTrans:NodeByName("btnSaveGroup_").gameObject
	self.btnSave_ = self.btnSaveGroup_:NodeByName("btnSave_").gameObject
	self.btnSkipGroup_ = winTrans:NodeByName("btnSkipGroup_").gameObject
	self.btnSkip_ = self.btnSkipGroup_:NodeByName("btnSkip_").gameObject
	self.groupSelect_ = winTrans:NodeByName("groupSelect_").gameObject
	self.btnSelect = self.groupSelect_:NodeByName("btnSelect").gameObject
	self.rectSelectBg_ = winTrans:ComponentByName("rectSelectBg_", typeof(UISprite))
	self.bgMask = winTrans:ComponentByName("bgMask", typeof(UISprite))
end

function StoryWindow:initTable()
	if self.storyType_ == xyd.StoryType.PARTNER then
		self.storyTable_ = xyd.tables.partnerPlotTable
	elseif self.storyType_ == xyd.StoryType.MAIN then
		self.storyTable_ = xyd.tables.mainPlotTable
	elseif self.storyType_ == xyd.StoryType.ACTIVITY then
		self.storyTable_ = xyd.tables.storyTable
	elseif self.storyType_ == xyd.StoryType.OLD_PLAYER_BACK then
		self.storyTable_ = xyd.tables.playerReturnStoryTable
	elseif self.storyType_ == xyd.StoryType.OTHER then
		self.storyTable_ = xyd.tables.partnerWarmUpPlotTable
	elseif self.storyType_ == xyd.StoryType.ACTIVITY_FROG then
		self.storyTable_ = xyd.tables.activityTravelFrogPlotTable
	elseif self.storyType_ == xyd.StoryType.TRIAL then
		self.storyTable_ = xyd.tables.newTrialPlotTable
	elseif self.storyType_ == xyd.StoryType.DATE_MONOPOLY then
		self.storyTable_ = xyd.tables.activityDatePlotTable
	elseif self.storyType_ == xyd.StoryType.SWIMSUIT then
		self.storyTable_ = xyd.tables.activityIceSummerPlotTable
	elseif self.storyType_ == xyd.StoryType.ACTIVITY_VALENTINE then
		self.storyTable_ = xyd.tables.activityValentinePlotTable
	elseif self.storyType_ == xyd.StoryType.CRYSTAL_BALL then
		self.storyTable_ = xyd.tables.activityCrystalBallPlotTable
	elseif self.storyType_ == xyd.StoryType.SHRINE_HURDLE then
		self.storyTable_ = xyd.tables.activityShrinePlotTable
	elseif self.storyType_ == xyd.StoryType.ACTIVITY_4BIRTHDAY_PARTY then
		self.storyTable_ = xyd.tables.activity4birthdayPlotTable
	end
end

function StoryWindow:layout()
	self.btnBottomSkip_:ComponentByName("button_label", typeof(UILabel)).text = __("PLOT_SKIP")
	self.btnBottomSkipNew_:ComponentByName("button_label", typeof(UILabel)).text = __("MAIN_PLOT_NEW")
	self.btnAuto_:ComponentByName("button_label", typeof(UILabel)).text = __("AUTO")
	self.btnRecord_:ComponentByName("button_label", typeof(UILabel)).text = __("MEMORIES")

	if self.storyType_ == xyd.StoryType.OLD_PLAYER_BACK then
		self.groupBtns_:SetActive(false)
		self.btnSkipGroup_:SetActive(false)
		self.btnSaveGroup_:SetActive(false)
	end

	if self.saveCallback and not self.is_back_ then
		if self.btnSave_ then
			local btnSkipGroup = self.btnSkipGroup_

			NGUITools.Destroy(btnSkipGroup)

			self.btnSkipGroup_ = nil
			self.btnSkip_ = nil
		end
	else
		local btnSaveGroup = self.btnSaveGroup_

		NGUITools.Destroy(btnSaveGroup)

		local btnBottomSkip = self.btnBottomSkip_

		NGUITools.Destroy(btnBottomSkip)

		self.btnBottomSkip_ = nil
		self.btnSaveGroup_ = nil
		self.btnSave_ = nil
	end

	self.storyCG0_:update({
		index = 0,
		storyType = self.storyType_
	})
	self.storyCG1_:update({
		index = 1,
		storyType = self.storyType_
	})
end

function StoryWindow:registerEvent()
	UIEventListener.Get(self.btnAuto_).onClick = handler(self, self.onAutoTouch)

	if self.saveCallback and not self.is_back_ then
		UIEventListener.Get(self.btnSkip_).onClick = handler(self, self.onNextSelect)
		UIEventListener.Get(self.btnBottomSkipNew_).onClick = handler(self, self.onNextSelect)
	else
		UIEventListener.Get(self.btnSkip_).onClick = handler(self, self.onSkipTouch)
		UIEventListener.Get(self.btnBottomSkipNew_).onClick = handler(self, self.onSkipTouch)
	end

	UIEventListener.Get(self.btnRecord_).onClick = handler(self, self.onRecordTouch)
	UIEventListener.Get(self.imgTouch_).onClick = handler(self, self.onNextTouch)

	if self.btnSave_ then
		UIEventListener.Get(self.btnSave_).onClick = function ()
			xyd.alertYesNo(__("PLOT_SAVE"), function (yes)
				local wnd = xyd.WindowManager.get():getWindow("story_window")

				if not wnd then
					return
				end

				if yes then
					wnd:disappearStory()
				else
					wnd:resumeAuto()
				end
			end, "", false, {}, __("TIPS"))
		end
	end

	if self.btnBottomSkip_ then
		UIEventListener.Get(self.btnBottomSkip_).onClick = handler(self, self.onNextSelect)
	end
end

function StoryWindow:onAutoTouch()
	self.isAuto_ = not self.isAuto_

	if not self.isAuto_ and self.autoTimeKey_ > -1 then
		XYDCo.StopWait(self:getAutoTimeName())

		self.autoTimeKey_ = -1
	elseif self.isAuto_ and not self:isPlaying() and not self.storyTable_:isSelect(self.storyID_) then
		self:nextStory()
	end

	local state = xyd.checkCondition(self.isAuto_, "story_btn_origin", "story_btn_yellow")
	local sp = self.btnAuto_:GetComponent(typeof(UISprite))

	xyd.setUISpriteAsync(sp, xyd.Atlas.COMMON_Btn, state)
end

function StoryWindow:onSkipTouch()
	self:stopAuto()
	xyd.alertYesNo(__("STORY_IS_SKIP"), function (yes)
		local wnd = xyd.WindowManager.get():getWindow("story_window")

		if not wnd then
			return
		end

		if yes then
			if self.storyID_ then
				local msg = messages_pb:log_partner_data_touch_req()
				msg.touch_id = xyd.DaDian.STORY_SKIP
				msg.desc = self.storyID_ .. "," .. self.storyType_

				xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
			end

			if self.jumpToSelect then
				if self.storyType_ == xyd.StoryType.ACTIVITY_VALENTINE then
					while self.storyID_ > 0 do
						if self.storyTable_:isSelect(self.storyID_) then
							break
						end

						local nextId = self.storyTable_:getNext(self.storyID_)

						if nextId < 0 then
							self.endId = self.storyID_
						end

						self.storyID_ = nextId

						if self.storyTable_:isSelect(self.storyID_) then
							break
						end

						local flag = self.storyTable_:getPicture(self.storyID_)

						if flag and flag ~= "" then
							break
						end
					end

					if self.storyID_ > 0 then
						if self.groupMain_.transform.childCount > 1 then
							local item = self.groupMain_:NodeByName("partner_card").gameObject

							if item then
								self.effectPlayer:stop()
								NGUITools.Destroy(item)
							end
						end

						self:playAction(self.storyID_, false)
						self:showSelects(self.storyID_)
						wnd:resumeAuto()

						return
					end
				else
					while self.storyID_ > 0 do
						if self.storyTable_:isSelect(self.storyID_) then
							break
						end

						local nextId = self.storyTable_:getNext(self.storyID_)

						if nextId < 0 then
							self.endId = self.storyID_
						end

						self.storyID_ = nextId

						if self.storyTable_:isSelect(self.storyID_) then
							break
						end
					end

					if self.storyID_ > 0 then
						self:playAction(self.storyID_, false)
						self:showSelects(self.storyID_)
						wnd:resumeAuto()

						return
					end
				end
			end

			wnd.isSkip_ = true

			wnd:disappearStory(true)
		else
			wnd:resumeAuto()
		end
	end)
end

function StoryWindow:onRecordTouch()
	local data_ = self:getCurReords()

	self:stopAuto()
	xyd.WindowManager.get():openWindow("story_record_window", {
		data = data_,
		callback = function ()
			self:resumeAuto()
		end
	})
end

function StoryWindow:getCurReords()
	return self.records_
end

function StoryWindow:onNextTouch()
	if self:isPlaying() then
		self:cancelEffect()

		return
	elseif self.storyTable_:isSelect(self.storyID_) then
		self:showSelects(self.storyID_)

		return
	elseif self:checkEditName(self.storyID_) then
		self:showEditName(self.storyID_)

		return
	end

	if self.autoTimeKey_ > -1 then
		XYDCo.StopWait(self:getAutoTimeName())

		self.autoTimeKey_ = -1
	end

	self:nextStory()
end

function StoryWindow:onNextSelect()
	if self.isAuto_ then
		xyd.alertTips(__("PLOT_CANT_SKIP"))

		return
	end

	xyd.alertYesNo(__("PLOT_FORWARD"), function (yes)
		if not yes then
			return
		end

		if self:isPlaying() then
			self:cancelEffect()
		end

		local item = self.groupMain_:NodeByName("partner_card").gameObject

		if item then
			NGUITools.Destroy(item)
		end

		if self.storyTable_:isSelect(self.storyID_) then
			self:showSelects(self.storyID_)

			return
		end

		local cur_id = self.storyTable_:getNext(self.storyID_)
		local select_ = nil
		local count = 0

		while cur_id > 0 do
			count = count + 1
			self.storyID_ = cur_id
			select_ = self.storyTable_:getSelects(cur_id)

			if select_ and #select_ > 0 then
				break
			end

			local curStr = self:getDialog(cur_id)
			local name_ = self.storyTable_:getName(cur_id)

			if name_ == "*" then
				name_ = xyd.Global.playerName
			end

			table.insert(self.records_, {
				name = name_,
				dialog = curStr
			})

			cur_id = self.storyTable_:getNext(cur_id)
		end

		if cur_id <= 0 then
			self.isSkip_ = true

			self:disappearStory()
		else
			self.storyID_ = cur_id

			self:checkPlayEffectEnd(count)
			self:playAction(cur_id, false)
			self:showSelects(cur_id)
		end
	end, "", false, {}, __("TIPS"))
end

function StoryWindow:cancelEffect()
	local flag = self:isPlaying()

	if not flag then
		return
	end

	for i = 1, #self.timesLines_ do
		local action = self.timesLines_[i]

		action:Pause()
		action:Kill()
	end

	self.timesLines_ = {}

	if self.autoTimeKey_ > -1 then
		XYDCo.StopWait(self.autoTimeKey_)

		self.autoTimeKey_ = -1
	end

	if self.isPlayEixt then
		self:setBg(self.storyID_)

		local img = self.groupMain_:NodeByName("partner_card")

		if img then
			if self.last_partner_img and not tolua.isnull(self.last_partner_img:getGameObject()) then
				NGUITools.Destroy(self.last_partner_img:getGameObject())

				self.last_partner_img = nil
			end

			if img and not tolua.isnull(img.gameObject) then
				NGUITools.Destroy(img.gameObject)
			end
		end

		self:setCompletedImgStatus(self.storyID_)
		self:setCompletedTextEffect(self.storyID_)
	end

	if self.isPlayEnter then
		self:setBg(self.storyID_)
		self:setCompletedImgStatus(self.storyID_)
	end

	if self.isPlayText then
		XYDCo.StopWait(self.textEffectTimeoutId)

		self.textEffectTimeoutId = nil
		local cur_name = self.storyTable_:getName(self.storyID_)
		cur_name = string.gsub(cur_name, "*", xyd.Global.playerName)
		local utf8len = xyd.utf8len(cur_name)
		local minUtf8len = 14

		if utf8len < minUtf8len then
			local addNum = math.ceil((minUtf8len - utf8len) / 2)

			for i = 1, addNum do
				cur_name = " " .. cur_name .. " "
			end
		end

		self.labelName_.text = cur_name

		self:adaptLabelImg()

		self.labelDialog_.text = self.curStr
	end

	if self.isPlayBg then
		self:setBigPicSource(self.bg_, self.storyTable_:getImagePath(self.storyID_))

		self.bgMask.alpha = 0.01
	end

	if self.isPlayCgEnter then
		self.storyCG0_:playCgActionEnd(self.storyID_)
		self.storyCG1_:playCgActionEnd(self.storyID_)
	end

	if self.isPlayCgExit then
		self.storyCG0_:playCgExitEnd(self.storyID_)
		self.storyCG1_:playCgExitEnd(self.storyID_)
	end

	if self.isPlayContent then
		self.textGroup:GetComponent(typeof(UIWidget)).alpha = 1

		if not self.isPlayEixt then
			self:setCompletedTextEffect(self.storyID_)
		end
	end

	if self.storyTable_:isSelect(self.storyID_) then
		self:showSelects(self.storyID_)
	end

	if self:checkEditName(self.storyID_) then
		self:showEditName(self.storyID_)
	end

	if self.storyID_ < 0 and (self.isPlayEnter or self.isPlayEixt) then
		self:disappearStory()
	end

	self:showExpression(self.storyID_)
	self:checkAutoNext()

	if self.storyType_ ~= xyd.StoryType.OLD_PLAYER_BACK then
		self.groupBtns_:SetActive(true)
	end

	self.isPlayText = false
	self.isPlayEixt = false
	self.isPlayEnter = false
	self.isPlayBg = false
	self.isPlayContent = false
	self.isPlayCgExit = false
	self.isPlayCgEnter = false
end

function StoryWindow:setCompletedImgStatus(id)
	if id < 0 then
		return
	end

	local card = self.groupMain_:NodeByName("partner_card")

	if not card then
		card = self:initCard(id)

		if not card then
			return
		end
	end

	card = card.gameObject
	local w = card:GetComponent(typeof(UIWidget))
	w.alpha = 1
	local scale = self.storyTable_:getScale(id)
	card.transform.localScale = Vector3(scale, scale, 1)
	local name = self.storyTable_:getResPath(self.storyID_)
	local size = xyd.getTextureRealSize(name)
	size.width = math.max(1000, size.width)
	size.height = math.max(1457, size.height)
	local groupMainW = self.groupMain_:GetComponent(typeof(UIWidget))
	local x = groupMainW.width / 2 + self:getFinalX(id) - size.width * (1 - scale) / 2
	local y = groupMainW.height / 2 + self:getFinalY(id) - size.height * (1 - scale) / 2
	card.transform.localPosition = Vector3(x, -y, 0)
end

function StoryWindow:setCompletedTextEffect(id)
	local type = self.storyTable_:getType(id)
	local curStr = self:getDialog(id)

	self:changeTextType(type)

	self.labelDialog_.text = curStr
	local name_ = self.storyTable_:getName(id)
	name_ = string.gsub(name_, "*", xyd.Global.playerName)
	local utf8len = xyd.utf8len(name_)
	local minUtf8len = 14

	if utf8len < minUtf8len then
		local addNum = math.ceil((minUtf8len - utf8len) / 2)

		for i = 1, addNum do
			name_ = " " .. name_ .. " "
		end
	end

	self.labelName_.text = name_

	self:adaptLabelImg()
	table.insert(self.records_, {
		name = name_,
		dialog = curStr
	})
end

function StoryWindow:isPlaying()
	return self.isPlayEixt or self.isPlayEnter or self.isPlayText or self.isPlayBg or self.isPlayContent or self.isPlayCgEnter or self.isPlayCgExit
end

function StoryWindow:getImage(type_)
	local image = nil

	if self.last_partner_img ~= nil and tolua.isnull(self.last_partner_img:getGameObject()) then
		self.last_partner_img = nil
	end

	if type_ == xyd.StoryImageType.PARTNER_IMG and self.last_partner_img == nil then
		image = ParnterImg.new(self.groupMain_)
		self.last_partner_img = image
	elseif type_ == xyd.StoryImageType.PARTNER_IMG and self.last_partner_img ~= nil then
		return self.last_partner_img
	else
		image = NGUITools.AddChild(self.groupMain_, "image")

		if type_ == xyd.StoryImageType.SPRITE then
			local sp = view:AddComponent(typeof(UISprite))
			sp.depth = self.groupMain_:GetComponent(typeof(UIWidget)).depth + 1
		else
			local sp = view:AddComponent(typeof(UITexture))
			sp.depth = self.groupMain_:GetComponent(typeof(UIWidget)).depth + 1
		end
	end

	return image
end

function StoryWindow:startStory()
	local storyID = self.storyID_

	if storyID == 1 and self.storyType_ == xyd.StoryType.MAIN and xyd.models.selfPlayer:isChangeNameFree() then
		self.btnSkip_:SetActive(false)
	end

	self:playMusic(storyID, true)
	self:playAction(storyID)
end

function StoryWindow:playExitEffect(nextID)
	if nextID == nil then
		nextID = -2
	end

	local id = self.storyID_
	local oldCard = self.groupMain_:NodeByName("partner_card")
	local callback = nil

	function callback()
		self.isPlayEixt = false
		local isNotDesTroy = false
		local cardRes_ = self.storyTable_:getResPath(self.storyID_)

		if self.last_partner_img ~= nil then
			if cardRes_ and string.find(cardRes_, "partner_avatar") then
				-- Nothing
			elseif cardRes_ and cardRes_ ~= "" and cardRes_ ~= nil and self.last_partner_img:getPicSrc() and self.last_partner_img:getPicSrc() == cardRes_ then
				isNotDesTroy = true
			end
		end

		if oldCard and not isNotDesTroy then
			if self.last_partner_img and not tolua.isnull(self.last_partner_img:getGameObject()) then
				NGUITools.Destroy(self.last_partner_img:getGameObject())

				self.last_partner_img = nil
			end

			if oldCard and not tolua.isnull(oldCard.gameObject) then
				NGUITools.Destroy(oldCard.gameObject)
			end
		end

		self:playAction(self.storyID_)
	end

	local exit_type = self.storyTable_:getDisappearType(id)
	local action = self:getTimeLineLite()
	local x = self:getEndX(id)
	local nxt = xyd.checkCondition(nextID == -2, self.storyTable_:getNext(id), nextID)
	local timeScale = self.storyTable_:getDisappearTime(id)
	self.isPlayEixt = true

	if nxt < 0 then
		local temp = self:getTimeLineLite()

		self.groupBtns_:SetActive(false)

		local w = self.textGroup:GetComponent(typeof(UIWidget))

		local function getter()
			return w.color
		end

		local function setter(value)
			w.color = value
		end

		temp:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0.01, 0.3)):AppendCallback(function ()
			self:disappearStory()
		end)

		return
	end

	self.storyID_ = nxt

	if not self:judgeSameBg(nxt) then
		local newCallback = nil

		function newCallback()
			local swapIndex = self.storyTable_:getMapSwap(nxt)
			local swap_info = MapSwapColor[swapIndex]

			if type(swap_info) ~= "string" then
				local bgAction = self:getTimeLineLite()
				self.bgMask.color = Color.New2(MapSwapColor[swapIndex])
				self.isPlayBg = true

				self.bgMask:SetActive(true)

				local w = self.bgMask:GetComponent(typeof(UIWidget))

				local function getter()
					return w.color
				end

				local function setter(value)
					w.color = value
				end

				bgAction:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 1)):AppendCallback(function ()
					self:setBigPicSource(self.bg_, self.storyTable_:getImagePath(nxt))
					self:initPlayTextEffect(nxt)
					self:checkMemory(nxt)
				end):Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0.01, 1)):AppendCallback(function ()
					self.isPlayBg = false

					self.bgMask:SetActive(false)
					callback()
				end)

				return
			end

			local layer = xyd.WindowManager.get():getTopEffectNode()
			local dragonbones = xyd.Spine.new(layer)

			dragonbones:setInfo(swap_info, function ()
				xyd.setTouchEnable(self.imgTouch_, false)
				xyd.SoundManager.get():playSound(xyd.SoundID.BATTLE_BLACK_IN, function ()
					xyd.SoundManager.get():playSound(xyd.SoundID.BATTLE_BLACK_OUT)
				end)
				dragonbones:SetLocalPosition(10, 0, 0)
				dragonbones:SetLocalScale(1, 1, 1)
				dragonbones:play("texiao01", 1, 1, function ()
					dragonbones:destroy()
					self:playAction(self.storyID_)
					xyd.setTouchEnable(self.imgTouch_, true)
					callback()
				end)
				self:waitForTime(1, function ()
					self:setBigPicSource(self.bg_, self.storyTable_:getImagePath(nxt))
					self:initPlayTextEffect(nxt)
					self:checkMemory(nxt)
				end, "")
			end)
		end

		if not oldCard then
			newCallback()
		else
			self.effectPlayer:play(exit_type, oldCard.gameObject, action, {
				x = x,
				callback = newCallback
			}, timeScale)
		end
	else
		local contentAction = self:getTimeLineLite()
		self.isPlayContent = true

		self.groupBtns_:SetActive(false)

		local delay = 0

		if exit_type == 20 then
			delay = timeScale
		end

		local w = self.textGroup:GetComponent(typeof(UIWidget))

		local function getter()
			return w.color
		end

		local function setter(value)
			w.color = value
		end

		contentAction:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0.01, 0.35)):AppendCallback(function ()
			self:initPlayTextEffect(nxt)
		end):AppendInterval(delay):Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.35)):AppendCallback(function ()
			if self.storyType_ ~= xyd.StoryType.OLD_PLAYER_BACK then
				self.groupBtns_:SetActive(true)
			end

			self.isPlayContent = false

			self:playDialogAction(nxt)

			if not oldCard then
				callback()
			end
		end)

		if oldCard then
			self.effectPlayer:play(exit_type, oldCard.gameObject, action, {
				x = x,
				callback = callback
			}, timeScale)
		end
	end
end

function StoryWindow:nextStory(nextID)
	if nextID == nil then
		nextID = -2
	end

	local storyID = self.storyID_
	nextID = xyd.checkCondition(nextID == -2, self.storyTable_:getNext(storyID), nextID)

	if #self.curEffects_ > 0 then
		for i = 1, #self.curEffects_ do
			local effect = self.curEffects_[i]

			NGUITools.Destroy(effect)
		end

		self.curEffects_ = {}
	end

	if nextID == -1 then
		self.endId = self.storyID_

		self:disappearStory()

		return
	end

	local no_click_time = self.storyTable_:getNoClickTime(nextID)

	if no_click_time then
		xyd.setTouchEnable(self.imgTouch_, false)
		self:waitForTime(no_click_time, function ()
			xyd.setTouchEnable(self.imgTouch_, true)
		end, "")
	end

	self:playMusic(nextID)
	self:playCgExitAction(storyID)
	self:checkEditName(nextID)
	self:checkPlayEffectEnd()
	self:playAmbientSound(nextID)

	local jitter_status = self.storyTable_:jitter(nextID)

	if jitter_status == 1 then
		self:playShake()
	end

	if storyID == nextID then
		self.storyID_ = nextID

		self:playAction(nextID)

		return true
	end

	if self:judgeSame(storyID, nextID) and self:judgeSameBg(nextID) and self:judgeSameFace(storyID, nextID) and self:judgeSameScale(storyID, nextID) then
		self.storyID_ = nextID

		self:playAction(nextID, true)

		return true
	end

	if self.storyTable_:getSwapOverlap(nextID) == 1 then
		self:playAtSameTime(storyID, nextID)

		return true
	end

	self:playExitEffect(nextID)
end

function StoryWindow:checkMemory(storyID)
	local isMemory = self.storyTable_:isMemory(storyID)

	if isMemory == 0 and self.lastMemoryType < 0 then
		return
	end

	if isMemory == 0 then
		for _, id in ipairs(self.memory[self.lastMemoryType]) do
			if self.lastMemoryType == 1 then
				if string.find(id, "storyCG") then
					xyd.applyChildrenOrigin(self[id]:getGameObject())
				else
					xyd.applyChildrenOrigin(self[id].gameObject)
				end
			else
				xyd.models.selfShader:clearSaturation(self[id])
			end
		end

		self.lastMemoryType = -1

		return
	end

	for _, id in ipairs(self.memory[isMemory]) do
		if isMemory == 1 then
			if string.find(id, "storyCG") then
				xyd.applyChildrenGrey(self[id]:getGameObject())
			else
				xyd.applyChildrenGrey(self[id].gameObject)
			end
		elseif isMemory == 2 then
			xyd.models.selfShader:changeSaturation(self[id])
		end
	end

	self.lastMemoryType = isMemory
end

function StoryWindow:showEditName(storyID)
	if self:checkEditName(storyID) then
		xyd.WindowManager.get():openWindow("person_edit_name_window", {
			no_close = true,
			isStory = true,
			callback = function ()
				if self.stage then
					self.btnSkip_:SetActive(true)
					self:nextStory()
				end
			end
		})
	end
end

function StoryWindow:checkEditName(storyID)
	if storyID == xyd.STORY_CHANGE_NAME_ID and xyd.models.selfPlayer:isChangeNameFree() then
		return true
	end

	return false
end

function StoryWindow:playAtSameTime(id, nxt)
	local curImg = self.groupMain_:NodeByName("partner_card").gameObject
	local curAction = self:getTimeLineLite()
	local nxtImg = self:initCard(nxt)
	local nxtAction = self:getTimeLineLite()
	self.storyID_ = nxt
	local exit_type = self.storyTable_:getDisappearType(id)
	local show_type = self.storyTable_:getShowType(nxt)
	local curTimeScale = self.storyTable_:getDisappearTime(id)
	local nxtTimeScale = self.storyTable_:getShowTime(id)
	self.isPlayEnter = true
	self.isPlayEixt = true

	self.effectPlayer:play(exit_type, curImg, curAction, {
		x = self:getEndX(id),
		callback = function ()
			NGUITools.Destroy(curImg)

			self.isPlayEixt = false

			self:playDialogAction(nxt)
			self:showExpression(nxt)
			self:checkMemory(nxt)
		end
	}, curTimeScale)

	local groupMainW = self.groupMain_:GetComponent(typeof(UIWidget))
	local curImgW = curImg:GetComponent(typeof(UIWidget))

	self.effectPlayer:play(show_type, nxtImg, nxtAction, {
		x = self:getFinalX(nxt) + (groupMainW.width - curImgW.width) / 2,
		callback = function ()
			self.isPlayEnter = false
		end
	}, nxtTimeScale)
	self:playCgAction(nxt)
end

function StoryWindow:playAction(storyID, isSameCard)
	if isSameCard == nil then
		isSameCard = false
	end

	self:setBg(storyID)

	local card = nil

	if not isSameCard then
		card = self:initCard(storyID)
	else
		card = self.groupMain_:NodeByName("partner_card")
	end

	if card then
		self:playCardAction(card.gameObject, storyID)
	end

	self:playStoryEffect(storyID)
	self:playDialogAction(storyID)
	self:playCgAction(storyID)
	self:showExpression(storyID)
	self:checkMemory(storyID)
	self:initPicture(storyID)
	self:playEffectSound(storyID)
	self:playAmbientSound(storyID)
end

function StoryWindow:initPicture(storyID)
	local src = self.storyTable_:getPicture(storyID)

	if not src or src == "" then
		self.smallPicShowBg_:SetActive(false)

		return
	end

	self.smallPicShowBg_:SetActive(true)

	local xy = self.storyTable_:getPictureXY(storyID) or {
		0,
		0
	}
	local scale = self.storyTable_:getPictureScale(storyID) or {
		1,
		1
	}
	local group_pos = self.groupMain_.transform.localPosition

	if #xy == 0 then
		xy = {
			-group_pos.x,
			-group_pos.y
		}
	end

	xy[1] = -group_pos.x
	xy[2] = -group_pos.y

	if #scale == 0 then
		scale = {
			1,
			1
		}
	end

	xyd.setUITextureByNameAsync(self.smallPicShowBg_, src, true)
	self.smallPicShowBg_:SetLocalPosition(xy[1], xy[2], 0)
	self.smallPicShowBg_:SetLocalScale(scale[1], scale[2], 1)
end

function StoryWindow:setBg(storyID)
	local bg_ = self.storyTable_:getImagePath(storyID)

	if bg_ and bg_ ~= "" and bg_ ~= "-1" and bg_ ~= nil then
		self:setBigPicSource(self.bg_, bg_)
		self.bg_:SetActive(true)
		self.bg2_:SetActive(false)
	else
		self.bg_:SetActive(false)
		self.bg2_:SetActive(true)
	end

	self:checkImagePathType(bg_)
end

function StoryWindow:initCard(storyID)
	local cardRes_ = self.storyTable_:getResPath(storyID)

	if cardRes_ and string.find(cardRes_, "partner_avatar") then
		return self:initAvatar(storyID, cardRes_)
	end

	local card_ = nil

	if cardRes_ and cardRes_ ~= "" and cardRes_ ~= nil then
		local image = self:getImage(xyd.StoryImageType.PARTNER_IMG)
		self.nowImg = image
		local picFace = self.storyTable_:getFace(storyID)
		local facePos = self.storyTable_:getFacePos(storyID)
		local faceScale = self.storyTable_:getFaceScale(storyID)
		local params = {
			noAddQueen = true,
			picBody = cardRes_,
			picFace = picFace,
			facePos = facePos,
			faceScale = faceScale
		}
		local modelName = nil

		if self.storyTable_.getSpinePath then
			modelName = self.storyTable_:getSpinePath(storyID)
		end

		if modelName and modelName ~= 0 then
			params.modelName = modelName
		end

		image:setImg(params)

		local flipX = self.storyTable_:getFlipX(storyID)

		if flipX == -1 then
			image:SetLocalScale(-1, 1, 1)
		end

		local w = nil

		if self.last_partner_img == nil then
			card_ = NGUITools.AddChild(self.groupMain_, "partner_card")
			w = card_:AddComponent(typeof(UIWidget))

			ResCache.AddChild(card_, image:getGameObject())
		else
			card_ = self.last_partner_img:getGameObject()
			card_.name = "partner_card"
			w = card_:AddComponent(typeof(UIWidget))
		end

		if modelName and modelName ~= 0 then
			params.modelName = modelName

			image:SetLocalPositionFun(0, -680, 0)
		else
			image:SetLocalPositionFun(0, 0, 0)
		end

		local scale = self.storyTable_:getScale(storyID)

		card_:SetLocalScale(scale, scale, 1)

		local imgW = image:getGameObject():GetComponent(typeof(UIWidget))
		local groupMianW = self.groupMain_:GetComponent(typeof(UIWidget))
		local name = self.storyTable_:getResPath(storyID)
		local size = xyd.getTextureRealSize(name)
		size.width = math.max(1000, size.width)
		size.height = math.max(1457, size.height)
		local x = self:getStartX(storyID) + groupMianW.width / 2 - size.width * (1 - scale) / 2
		local y = self:getFinalY(storyID) + groupMianW.height / 2 - size.height * (1 - scale) / 2

		card_:SetLocalPosition(x, -y, 0)

		w.width = imgW.width
		w.height = imgW.height
		w.alpha = 0.01
	end

	return card_
end

function StoryWindow:initAvatar(storyID, res_path)
	local card_ = nil

	if res_path and res_path ~= "" and res_path ~= nil then
		card_ = NGUITools.AddChild(self.groupMain_, "partner_card")
		local w = card_:AddComponent(typeof(UIWidget))
		local image = self:getImage(xyd.StoryImageType.TEXTURE)
		local frame_img = self:getImage(xyd.StoryImageType.SPRITE)

		xyd.setUITextureAsync(image, "Textures/partner_avatar_web/" + res_path)
		xyd.setUISpriteAsync(image, xyd.Atlas.MAIN_WINDOW, "avator_bg")

		local flipX = self.storyTable_:getFlipX(storyID)

		if flipX == -1 then
			image:SetLocalScale(-1, 1, 1)
		end

		ResCache.AddChild(card_, image)
		ResCache.AddChild(card_, frame_img)

		local scale = self.storyTable_:getScale(storyID)

		card_:SetLocalScale(scale, scale, 1)

		w.alpha = 0.01
		local x = self:getStartX(storyID)
		local y = self:getFinalY(storyID)

		card_:SetLocalPosition(x, y, 0)
	end

	return card_
end

function StoryWindow:playCardAction(card, storyID)
	self:playCardEnterAction(card, storyID)
end

function StoryWindow:playCardEnterAction(card, storyID)
	local showType = self.storyTable_:getShowType(storyID)

	if showType <= 0 then
		return
	end

	self.isPlayEnter = true
	local scale = self.storyTable_:getScale(storyID)
	local name = self.storyTable_:getResPath(storyID)
	local size = xyd.getTextureRealSize(name)
	size.width = math.max(1000, size.width)
	size.height = math.max(1457, size.height)
	local action = self:getTimeLineLite()
	local x = self:getFinalX(storyID) + self.groupMain_:GetComponent(typeof(UIWidget)).width / 2 - size.width * (1 - scale) / 2
	local callback = nil

	function callback()
		self.isPlayEnter = false
	end

	self.effectPlayer:play(showType, card, action, {
		x = x,
		callback = callback
	}, self.storyTable_:getShowTime(storyID))
end

function StoryWindow:getTimeLineLite()
	local action = nil

	local function completeCallback()
		for i = 1, #self.timesLines_ do
			if self.timesLines_[i] == action then
				table.remove(self.timesLines_, i)

				break
			end
		end
	end

	action = DG.Tweening.DOTween.Sequence():OnComplete(completeCallback)

	action:SetAutoKill(true)
	table.insert(self.timesLines_, action)

	return action
end

function StoryWindow:playDialogAction(storyID)
	local jitter_status = self.storyTable_:jitter(storyID)

	if jitter_status == 2 then
		self:playShake()
	end

	if self.isPlayEixt or self.isPlayContent then
		return
	end

	self.isPlayText = true
	local type = self.storyTable_:getType(storyID)

	self:initPlayTextEffect(storyID)

	local name_ = self.storyTable_:getName(storyID)
	name_ = string.gsub(name_, "*", xyd.Global.playerName)
	local utf8len = xyd.utf8len(name_)
	local minUtf8len = 14

	if utf8len < minUtf8len then
		local addNum = math.ceil((minUtf8len - utf8len) / 2)

		for i = 1, addNum do
			name_ = " " .. name_ .. " "
		end
	end

	self.labelName_.text = name_

	self:adaptLabelImg()
	table.insert(self.records_, {
		name = name_,
		dialog = self.curStr
	})
	self:textEffect()
	self:playSound(storyID)
end

function StoryWindow:adaptLabelImg()
end

function StoryWindow:getDialog(storyID)
	local str = self.storyTable_:getDialog(storyID)

	if storyID == xyd.STORY_CHANGE_NAME_ID then
		local strArr = xyd.split(str, "|")

		if self:checkEditName(storyID) then
			str = strArr[1]
		else
			str = strArr[2]
			str = string.gsub(str, "*", xyd.Global.playerName)
		end
	else
		str = string.gsub(str, "*", xyd.Global.playerName)
	end

	return str
end

function StoryWindow:initPlayTextEffect(storyID)
	local type = self.storyTable_:getType(storyID)
	self.curStr = self:getDialog(storyID)
	self.curStrPos = 1
	self.labelDialog_.text = ""

	self:changeTextType(type)
end

function StoryWindow:changeTextType(type)
	if type == nil then
		return
	end

	for i = 0, 2 do
		local flag = type == i

		self["textBgGroup" .. tostring(i)]:SetActive(flag)
	end

	if type == 2 then
		self.labelName_ = self.labelName2
		self.labelDialog_.color = Color.New2(981385983)
	else
		self.labelName_ = self.labelName0
		self.labelDialog_.color = Color.New2(1179277055)
	end
end

function StoryWindow:textEffect()
	self.textEffectTimeoutId = "textEffect"

	self:waitForTime(self.delayTime, function ()
		local count = 1
		local c = string.sub(self.curStr, self.curStrPos, self.curStrPos)

		if c then
			if string.byte(c) > 128 then
				count = 3
				c = string.sub(self.curStr, self.curStrPos, self.curStrPos + 2)
			end

			self.labelDialog_.text = self.labelDialog_.text .. c
		end

		self.curStrPos = self.curStrPos + count

		if self.curStrPos <= #self.curStr then
			self:textEffect()
		else
			self.isPlayText = false
			self.textEffectTimeoutId = nil

			self:checkAutoNext()
		end
	end, self.textEffectTimeoutId)
end

function StoryWindow:getAutoTimeName()
	return "story_window_" .. self.autoTimeKey_
end

function StoryWindow:checkAutoNext()
	if (self.isAuto_ or self.tmpAuto_) and not self.storyTable_:isSelect(self.storyID_) and self.curSingleEffectNum_ <= 0 and not self:checkEditName(self.storyID_) then
		if self.tmpAuto_ then
			self.autoTimeKey_ = -2
		else
			if self.autoTimeKey_ > -1 then
				XYDCo.StopWait(self:getAutoTimeName())

				self.autoTimeKey_ = -1
			end

			self.autoTimeKey_ = 1

			self:waitForTime(1, function ()
				self.autoTimeKey_ = -1

				self:nextStory()
			end, self:getAutoTimeName())
		end
	end
end

function StoryWindow:stopAuto()
	self.tmpAuto_ = self.isAuto_

	if self.isAuto_ then
		self.isAuto_ = false

		if self.autoTimeKey_ > -1 then
			XYDCo.StopWait(self:getAutoTimeName())
		end
	end
end

function StoryWindow:resumeAuto()
	self.isAuto_ = self.tmpAuto_
	self.tmpAuto_ = false

	if self.isAuto_ and (self.autoTimeKey_ > -1 or self.autoTimeKey_ == -2) then
		self:checkAutoNext()
	end
end

function StoryWindow:judgeSameBg(id)
	local type = self.storyTable_:getMapSwap(id)

	return type == 0
end

function StoryWindow:getStartX(id)
	local data = self.storyTable_:getPositionMove(id)

	if #data < 2 then
		return self.deltaX
	end

	return self.deltaX + data[1]
end

function StoryWindow:getEndX(id)
	local data = self.storyTable_:getPositionMove(id)

	if #data < 2 then
		return self.deltaX
	end

	return self.deltaX + data[2]
end

function StoryWindow:getFinalX(id)
	local data = self.storyTable_:getPartnerPicXYDelta(id)
	local partner_table_id = PartnerPictureTable:getIdByPartnerPicture(self.storyTable_:getResPath(id))
	local delta = 0

	if partner_table_id then
		delta = PartnerPictureTable:getPartnerPicXY(partner_table_id).x
	end

	if #data < 2 then
		return self.deltaX + delta
	end

	return self.deltaX + data[1] + delta
end

function StoryWindow:getFinalXFake(x)
	local partner_table_id = PartnerPictureTable:getIdByPartnerPicture(self.storyTable_:getResPath(self.storyID_))
	local delta = 0

	if partner_table_id then
		delta = PartnerPictureTable:getPartnerPicXY(partner_table_id).x
	end

	return self.deltaX + x + delta
end

function StoryWindow:getFinalY(id)
	local data = self.storyTable_:getPartnerPicXYDelta(id)
	local partner_table_id = PartnerPictureTable:getIdByPartnerPicture(self.storyTable_:getResPath(id))
	local delta = 0

	if partner_table_id then
		delta = PartnerPictureTable:getPartnerPicXY(partner_table_id).y
	end

	if #data < 2 then
		return self.deltaY + delta
	end

	return self.deltaY + data[2] + delta
end

function StoryWindow:getFinalYFake(y)
	local partner_table_id = PartnerPictureTable:getIdByPartnerPicture(self.storyTable_:getResPath(self.storyID_))
	local delta = 0

	if partner_table_id then
		delta = PartnerPictureTable:getPartnerPicXY(partner_table_id).y
	end

	return self.deltaY + y + delta
end

function StoryWindow:disappearStory(skip)
	if skip == nil then
		skip = false
	end

	if self.isDisappear then
		return
	end

	self.isDisappear = true

	self.bgMask:SetActive(true)

	self.bgMask.alpha = 0.01
	local nextCompare = false

	if self.storyTable_:getNext(self.storyID_) then
		nextCompare = self.storyTable_:getNext(self.storyID_) < 0
	end

	if (self.storyID_ < 0 or nextCompare) and self.storyType_ == xyd.StoryType.PARTNER and self.params_.achievement_id then
		xyd.models.slot:recordPartnerStory(self.params_.achievement_id)
	end

	self.pre_story_id_ = self.storyID_
	self.storyID_ = table.remove(self.story_id_pool_, 1)

	if self.storyID_ and not skip then
		self.bgMask:SetActive(false)

		local layer = xyd.WindowManager.get():getTopEffectNode()
		local dragonbones = xyd.Spine.new(layer)

		xyd.setTouchEnable(self.imgTouch_, false)
		dragonbones:setInfo(xyd.Battle.effect_switch, function ()
			dragonbones:SetLocalScale(1.2, 1.2, 1)
			dragonbones:SetLocalPosition(10, 0, 0)
			xyd.SoundManager.get():playSound(xyd.SoundID.BATTLE_BLACK_IN, function ()
				xyd.SoundManager.get():playSound(xyd.SoundID.BATTLE_BLACK_OUT)
			end)
			dragonbones:play("texiao01", 1, 1, function ()
				dragonbones:destroy()
				self:nextStory(self.storyID_)
				xyd.setTouchEnable(self.imgTouch_, true)
			end)
			dragonbones:startAtFrame(0)
			self:waitForTime(1, function ()
				local oldCard = self.groupMain_:NodeByName("partner_card")

				if oldCard then
					NGUITools.Destroy(oldCard.gameObject)
				end

				self:setBigPicSource(self.bg_, self.storyTable_:getImagePath(self.storyID_))
				self:initPlayTextEffect(self.storyID_)

				self.isDisappear = false
			end)
		end)

		return
	end

	xyd.setTouchEnable(self.imgTouch_, false)

	if self.storyType_ == xyd.StoryType.OTHER or self.storyType_ == xyd.StoryType.ACTIVITY or self.storyType_ == xyd.StoryType.MAIN or self.storyType_ == xyd.StoryType.PARTNER and self.isShowSwitch then
		if self.isShowSwitch then
			local layer = xyd.WindowManager.get():getTopEffectNode()

			if layer then
				local dragonbones = xyd.Spine.new(layer)

				dragonbones:setInfo(xyd.Battle.effect_switch, function ()
					dragonbones:SetLocalScale(1.2, 1.2, 1)
					dragonbones:SetLocalPosition(10, 0, 0)
					xyd.SoundManager.get():playSound(xyd.SoundID.BATTLE_BLACK_IN, function ()
						xyd.SoundManager.get():playSound(xyd.SoundID.BATTLE_BLACK_OUT)
					end)
					dragonbones:play("texiao01", 1, 1, function ()
						dragonbones:destroy()

						local wnd = xyd.WindowManager.get():getWindow("battle_window")

						if wnd then
							wnd:playStartAction()
						end
					end)
					dragonbones:startAtFrame(0)
					self:waitForTime(1, function ()
						xyd.WindowManager.get():closeWindow("story_window")
					end)
				end)
			else
				xyd.WindowManager.get():closeWindow("story_window")

				local wnd = xyd.WindowManager.get():getWindow("battle_window")

				if wnd then
					wnd:playStartAction()
				end
			end
		else
			self:closeSwitch()
		end
	elseif self.storyType_ == xyd.StoryType.ACTIVITY_4BIRTHDAY_PARTY then
		if not skip then
			local msg = messages_pb.record_activity_req()
			msg.activity_id = xyd.ActivityID.ACTIVITY_4BIRTHDAY_PARTY * 1000 + self.endId

			xyd.Backend.get():request(xyd.mid.RECORD_ACTIVITY, msg)
		end

		self:closeSwitch()
	elseif self.storyType_ == xyd.StoryType.ACTIVITY_VALENTINE then
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_VALENTINE)

		if activityData then
			local plot_ids = activityData.detail.plot_ids
			local endType = self.storyTable_:getEndType(self.endId)
			local begineID = self.storyTable_:getBeginID(self.endId)

			if endType > 0 and xyd.arrayIndexOf(plot_ids, self.endId) == -1 then
				if endType == 6 then
					xyd.db.misc:setValue({
						value = 1,
						key = "activity_valentine_round_flag"
					})
				else
					local msg = messages_pb.activity_valentine_plot_req()
					msg.activity_id = xyd.ActivityID.ACTIVITY_VALENTINE
					msg.id = self.endId

					xyd.Backend.get():request(xyd.mid.ACTIVITY_VALENTINE_PLOT, msg)
					xyd.db.misc:setValue({
						key = "activity_valentine_first_end",
						value = begineID
					})

					local msg = messages_pb.record_activity_req()
					msg.activity_id = xyd.ActivityID.ACTIVITY_VALENTINE * 1000 + endType

					xyd.Backend.get():request(xyd.mid.RECORD_ACTIVITY, msg)
				end
			elseif endType == 0 then
				local flag = true

				for i = 1, #plot_ids do
					if begineID == self.storyTable_:getBeginID(plot_ids[i]) then
						flag = false

						break
					end
				end

				if flag then
					xyd.db.misc:setValue({
						key = "activity_valentine_last_id",
						value = begineID
					})
				end
			end
		end

		self:closeSwitch()
	elseif self.storyType_ == xyd.StoryType.CRYSTAL_BALL then
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.CRYSTAL_BALL)

		if not activityData:checkUnlock(self.endId) and tonumber(self.endId) then
			local msg = messages_pb.crystal_ball_read_plot_req()
			msg.activity_id = xyd.ActivityID.CRYSTAL_BALL
			msg.id = self.endId

			xyd.Backend.get():request(xyd.mid.CRYSTAL_BALL_READ_PLOT, msg)
		end

		self:closeSwitch()
	else
		self:closeSwitch()
	end

	if self.endId and not self.isSkip_ then
		local msg = messages_pb:log_partner_data_touch_req()
		msg.touch_id = xyd.DaDian.STORY_READ_OVER
		msg.desc = self.endId .. "," .. self.storyType_

		xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
	end
end

function StoryWindow:closeSwitch()
	local blackScreen = self.window_:ComponentByName("e:Image", typeof(UISprite))
	local w = blackScreen:GetComponent(typeof(UIWidget))
	local getter, setter = xyd.getTweenAlphaGeterSeter(w)
	local sequence = self:getSequence()
	blackScreen.depth = 40

	sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.66))
	sequence:AppendCallback(function ()
		self.window_:NodeByName("center").gameObject:SetActive(false)
		self.window_:NodeByName("bottom").gameObject:SetActive(false)
		self.window_:NodeByName("btnSkipGroup_").gameObject:SetActive(false)
		self.window_:NodeByName("rectSelectBg_").gameObject:SetActive(false)
		self.window_:NodeByName("groupSelect_").gameObject:SetActive(false)
		self.window_:NodeByName("bgMask").gameObject:SetActive(false)
		self.winBg_:SetActive(false)
	end)
	sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0.01, 0.66))
	sequence:AppendCallback(function ()
		sequence:Kill(false)

		sequence = nil

		xyd.WindowManager.get():closeWindow("story_window")
	end)
end

function StoryWindow:judgeSame(curID, nextID)
	local curImg = self.storyTable_:getResPath(curID)
	local nextImg = self.storyTable_:getResPath(nextID)

	return curImg == nextImg
end

function StoryWindow:judgeSameScale(curID, nextID)
	local curScale = self.storyTable_:getScale(curID)
	local nextScale = self.storyTable_:getScale(nextID)

	return curScale == nextScale
end

function StoryWindow:judgeSameFace(curID, nextID)
	local curFace = self.storyTable_:getFace(curID)
	local nextFace = self.storyTable_:getFace(nextID)

	return curFace == nextFace
end

function StoryWindow:willClose(params, skipAnimation, force)
	StoryWindow.super.willClose(self, params, skipAnimation, force)

	for i = 1, #self.timesLines_ do
		local action = self.timesLines_[i]

		action:Pause()
		action:Kill()
	end

	self.timesLines_ = {}

	if self.autoTimeKey_ > -1 then
		XYDCo.StopWait(self:getAutoTimeName())

		self.autoTimeKey_ = -1
	end

	if #self.curEffects_ > 0 then
		for i = 1, #self.curEffects_ do
			local effect = self.curEffects_[i]

			NGUITools.Destroy(effect)
		end

		self.curEffects_ = {}
	end

	self:stopAmbientSound()
	self.storyCG0_:clean()
	self.storyCG1_:clean()
	self:stopMusic(true)
	self:stopSound()
	self:cleanBigPicQueen()
	self:playExpressionTimer(false)

	if self.shakeTimer_ then
		self.shakeTimer_:Stop()

		self.shakeTimer_ = nil
	end

	if self.callback then
		self:callback(self.isSkip_)
	end

	if self.saveCallback then
		if not self.isSkip_ then
			self.pre_story_id_ = self.storyTable_:getNext(self.pre_story_id_)
		end

		self.saveCallback(self.pre_story_id_)
	end
end

function StoryWindow:didClose(params)
	StoryWindow.super.didClose(self, params)

	if #self.effectNames_ > 0 then
		for i = 1, #self.effectNames_ do
			local name_ = self.effectNames_[i]
		end
	end

	self.effectNames_ = {}
end

function StoryWindow:showSelects(storyID)
	if not self.storyTable_:isSelect(storyID) or self.isShowSelect then
		return
	end

	self.isShowSelect = true

	self.imgTouch_:SetActive(false)
	self.rectSelectBg_:SetActive(true)

	self.rectSelectBg_.alpha = 0.5

	self.groupSelect_:SetActive(true)

	local selects = self.storyTable_:getSelects(storyID)
	local nextIDs = self.storyTable_:getSelectNextIDs(storyID)

	if not self.allSelects then
		self.allSelects = {}
	end

	for i = 1, #selects do
		local go = NGUITools.AddChild(self.groupSelect_, self.btnSelect)
		local item = StorySelectItem.new(go)

		item:setInfo({
			index = i,
			text = selects[i],
			nextID = nextIDs[i],
			records = self.records_,
			type = self.storyType_,
			storyID = storyID
		})
		go:SetActive(true)
		table.insert(self.allSelects, go)
	end

	self.groupSelect_:GetComponent(typeof(UIGrid)):Reposition()
end

function StoryWindow:onSelectTouch(nextID, callback)
	self.isShowSelect = false

	self.imgTouch_:SetActive(true)
	self.rectSelectBg_:SetActive(false)
	self.groupSelect_:SetActive(false)

	for i = 1, #self.allSelects do
		NGUITools.Destroy(self.allSelects[i])
	end

	if self.saveCallback then
		self.saveCallback(nextID)
	end

	self:nextStory(nextID)
end

function StoryWindow:playCgAction(storyID)
	if not self.storyTable_:isCgShow(storyID) then
		return
	end

	self.isPlayCgEnter = true

	self.storyCG0_:playCgAction(storyID)
	self.storyCG1_:playCgAction(storyID)
end

function StoryWindow:playCgExitAction(storyID)
	if not self.storyTable_:isCgShow(storyID) then
		return
	end

	self.isPlayCgExit = true

	self.storyCG0_:playCgExitAction(storyID)
	self.storyCG1_:playCgExitAction(storyID)
end

function StoryWindow:setCgActionFlag(flag)
	self.isPlayCgEnter = flag
	self.isPlayCgExit = flag
end

function StoryWindow:playMusic(storyID, isFirst)
	if isFirst == nil then
		isFirst = false
	end

	local newMusicID = self.storyTable_:music(storyID)

	if not newMusicID or newMusicID == 0 then
		return
	end

	if newMusicID == self.musicID_ then
		return
	end

	if isFirst then
		local curBgId = xyd.SoundManager.get():getCurBgID()

		if tonumber(curBgId) == newMusicID then
			return
		end
	end

	self:stopMusic()

	if newMusicID == -1 then
		xyd.SoundManager.get():stopBg2()

		return
	end

	xyd.SoundManager.get():playSound(newMusicID)

	self.musicID_ = newMusicID
end

function StoryWindow:stopMusic(isClose)
	if not self.musicID_ or self.musicID_ == 0 or self.musicID_ == -1 then
		if isClose then
			xyd.SoundManager.get():playAudioBg()
			xyd.SoundManager.get():playSound(xyd.Global.bgMusic)
		end

		return
	end

	xyd.SoundManager.get():stopSound(self.musicID_)

	self.musicID_ = 0
end

function StoryWindow:playSound(storyID)
end

function StoryWindow:stopSound()
	self.soundID_ = 0
end

function StoryWindow:setBigPicSource(img, pic)
	if pic and pic ~= "" and pic ~= "-1" then
		local pngIndex = string.find(pic, "_png")

		if pngIndex then
			pic = string.sub(pic, 1, pngIndex - 1)
		end

		xyd.setUITextureByNameAsync(img, pic, false)
		img:SetActive(true)
	else
		img:SetActive(false)
	end

	self:checkImagePathType(pic)
end

function StoryWindow:add2BigPicQueen(name)
	if xyd.arrayIndexOf(self.bigPics_, name) < 0 then
		table.insert(self.bigPics_, name)
	end
end

function StoryWindow:cleanBigPicQueen()
end

function StoryWindow:playExpressionTimer(flag, callback, delay, count)
	if self.expressionTimer_ then
		self.expressionTimer_:Stop()

		self.expressionTimer_ = nil
	end

	if flag then
		self.expressionTimer_ = FrameTimer.New(callback, delay, count)

		self.expressionTimer_:Start()
	end
end

function StoryWindow:showExpression(storyID)
end

function StoryWindow:playExpression()
	local partnerCard = self.groupMain_:NodeByName("partner_card").gameObject

	if not partnerCard then
		return
	end

	local expressionImg = partnerCard:NodeByName("img_expression").gameObject

	if not expressionImg then
		return
	end

	self.curExpressionCount = self.curExpressionCount > 0 and 0 or 1
	local expressionName = "story_expr_" .. tostring(self.curExpressionID) .. "_" .. tostring(self.curExpressionCount)

	xyd.setUITextureAsync(expressionImg, "Textures/story_web/expression/" + expressionName)
end

function StoryWindow:playShake()
	if self.shakeTimer_ then
		self.shakeTimer_:Stop()

		self.shakeTimer_ = nil
	end

	local data = {
		{
			x = 0,
			y = 0
		},
		{
			x = 10,
			y = 0
		},
		{
			x = 17,
			y = 5
		},
		{
			x = -10,
			y = 0
		},
		{
			x = 0,
			y = 5
		},
		{
			x = 15,
			y = 0
		},
		{
			x = 5,
			y = 2
		},
		{
			x = -5,
			y = 4
		},
		{
			x = 0,
			y = 0
		}
	}
	local count = 0
	local bg_ = self.bg_
	local groupMain = self.groupMain_

	local function callback()
		if count >= #data then
			bg_:SetLocalPosition(0, 0, 0)
			groupMain:SetLocalPosition(-512, 512, 0)

			self.isShake_ = false
			self.shakeTimer_ = nil

			return
		end

		bg_:SetLocalPosition(data[count + 1].x, data[count + 1].y, 0)
		groupMain:SetLocalPosition(data[count + 1].x - 512, data[count + 1].y + 512, 0)

		count = count + 1
	end

	self.shakeTimer_ = FrameTimer.New(callback, 1, #data)

	self.shakeTimer_:Start()

	self.isShake_ = true
end

function StoryWindow:checkPlayEffectEnd(delCount)
	if delCount == nil then
		delCount = 1
	end

	local effectGroupInUse = self.effectGroupInUse_

	for i = #effectGroupInUse, 1, -1 do
		local leftCount = effectGroupInUse[i].left_count - delCount
		effectGroupInUse[i].left_count = leftCount

		if leftCount <= 0 then
			self:removeStoryEffect(effectGroupInUse[i])
		end
	end
end

function StoryWindow:buildWaitToPlayEffect(storyID)
	local wait_to_play = {}
	local effects = self.storyTable_:effect(storyID)
	local effects_pos = self.storyTable_:effectPos(storyID)
	local count_list = self.storyTable_:getEffectCount(storyID)
	local layer_list = self.storyTable_:getEffectLayer(storyID)
	local effect_scale = self.storyTable_:getEffectScale(storyID)

	for i = 1, #effects do
		local tmpStrs = xyd.split(effects[i], "*")
		local tmpCountList = xyd.split(count_list[i], "*", true)
		local tmpLayerList = xyd.split(layer_list[i], "*", true)
		local tmpEffectsPos = xyd.split(effects_pos[i], "*")
		local tmpEffectScale = xyd.split(effect_scale[i], "*", true)
		local info = nil
		local texiao = xyd.split(tmpStrs[1], "#")
		local pos = xyd.split(tmpEffectsPos[1], "#", true)
		info = {
			id = i,
			name = texiao[1],
			count = tmpCountList[1],
			animation = texiao[2],
			layer = tmpLayerList[1],
			left_count = tonumber(texiao[3]) or 1,
			pos = pos,
			scale = tmpEffectScale[1] or 1,
			next_count_list = {},
			next_layer_list = {},
			next_effects = {},
			next_effects_pos = {},
			next_effects_scale = {}
		}

		if #tmpStrs > 1 then
			table.remove(tmpStrs, 1)
			table.remove(tmpCountList, 1)
			table.remove(tmpLayerList, 1)
			table.remove(tmpEffectsPos, 1)
			table.remove(tmpEffectScale, 1)

			info.next_count_list = tmpCountList
			info.next_layer_list = tmpLayerList
			info.next_effects = tmpStrs
			info.next_effects_pos = tmpEffectsPos
			info.next_effects_scale = tmpEffectScale
		end

		table.insert(wait_to_play, info)
	end

	return wait_to_play
end

function StoryWindow:playStoryEffect(storyID)
	local wait_to_play = self:buildWaitToPlayEffect(storyID)

	for i = 1, #wait_to_play do
		self:playSingleEffect(wait_to_play[i])
	end
end

function StoryWindow:playSingleEffect(info)
	local parentGo = self:getStoryEffectGroup(info)
	local effect = xyd.Spine.new(parentGo)

	effect:setInfo(info.name, function ()
		effect:SetLocalScale(info.scale, info.scale, 1)

		if info.name == "plot_hit" then
			effect:SetLocalScale(1.2, 1.2, 1)
		end

		effect:SetLocalPosition(info.pos[1], info.pos[2], 0)
		effect:setRenderTarget(parentGo:GetComponent(typeof(UIWidget)), 1)
		effect:play(info.animation, info.count, 1, function ()
			self:removeStoryEffect(info)
		end)
	end)

	info.effect = effect

	if info.count == 1 then
		self.rectSelectBg_:SetActive(true)

		self.rectSelectBg_.alpha = 0.01
		self.curSingleEffectNum_ = self.curSingleEffectNum_ + 1
	end
end

function StoryWindow:getStoryEffectGroup(info)
	local layer = info.layer
	local group = self["groupLayer" .. tostring(layer) .. "_"]

	table.insert(self.effectGroupInUse_, info)

	return group
end

function StoryWindow:removeStoryEffect(info)
	dump(info)

	local layer = info.layer

	info.effect:destroy()
	self:gcSingleEffectGroup(info)

	if info.count == 1 then
		self.curSingleEffectNum_ = self.curSingleEffectNum_ - 1
	end

	self:checkNextEffect(info)

	if self.curSingleEffectNum_ <= 0 then
		self.rectSelectBg_:SetActive(false)

		if info.count == 1 and self.isPlayText == false then
			self:checkAutoNext()
		end
	end
end

function StoryWindow:checkNextEffect(info)
	if #info.next_effects > 0 then
		local texiao = xyd.split(info.next_effects[1], "#")
		local pos = xyd.split(info.next_effects_pos[1], "#", true)
		info.name = texiao[1]
		info.effect = nil
		info.count = info.next_count_list[1]
		info.animation = texiao[2]
		info.layer = info.next_layer_list[1]
		info.left_count = tonumber(texiao[3]) or 1
		info.pos = pos

		table.remove(info.next_effects, 1)
		table.remove(info.next_count_list, 1)
		table.remove(info.next_layer_list, 1)
		table.remove(info.next_effects_pos, 1)
		self:playSingleEffect(info)
	end
end

function StoryWindow:gcSingleEffectGroup(info)
	if not info then
		return
	end

	local ind = xyd.arrayIndexOf(self.effectGroupInUse_, info)

	if ind == -1 then
		return
	end

	table.remove(self.effectGroupInUse_, ind)
end

function StoryWindow:getPictureInfo()
	local scale = self.storyTable_:getScale(self.storyID_)

	return {
		x = self.storyTable_:getPartnerPicXYDelta(self.storyID_)[1] or 0,
		y = self.storyTable_:getPartnerPicXYDelta(self.storyID_)[2] or 0
	}, self.storyTable_:getImagePath(self.storyID_), self.storyID_, scale
end

function StoryWindow:getPictureFaceInfo()
	if self.nowImg then
		local pos, scale = self.nowImg:getFacePos()

		return pos.x, pos.y, scale
	else
		return 0, 0, 0
	end
end

function StoryWindow:setPicturePos(x, y, s)
	local card = self.groupMain_:NodeByName("partner_card")
	card = card.gameObject
	local w = card:GetComponent(typeof(UIWidget))
	w.alpha = 1
	local scale = self.storyTable_:getScale(self.storyID_)

	if s and tonumber(s) then
		scale = s
	end

	card.transform.localScale = Vector3(scale, scale, 1)
	local name = self.storyTable_:getResPath(self.storyID_)
	local size = xyd.getTextureRealSize(name)
	size.width = math.max(1000, size.width)
	size.height = math.max(1457, size.height)
	local groupMainW = self.groupMain_:GetComponent(typeof(UIWidget))
	local x = groupMainW.width / 2 + self:getFinalXFake(x) - size.width * (1 - scale) / 2
	local y = groupMainW.height / 2 + self:getFinalYFake(y) - size.height * (1 - scale) / 2
	card.transform.localPosition = Vector3(x, -y, 0)
end

function StoryWindow:setPictureFacePos(x, y, s)
	if self.nowImg then
		self.nowImg:setFacePos(x, y, s)
	end
end

function StoryWindow:playEffectSound(storyID)
	if self.storyTable_.getEffectSound then
		local soundID = self.storyTable_:getEffectSound(storyID)

		if soundID and soundID > 0 then
			xyd.SoundManager.get():playSound(soundID)
		end
	end
end

function StoryWindow:playAmbientSound(storyID)
	if self.storyTable_.getAmbientSound then
		local soundIDs = self.storyTable_:getAmbientSound(storyID)

		if soundIDs and #soundIDs > 0 and soundIDs[1] ~= -1 then
			for i in pairs(soundIDs) do
				if xyd.arrayIndexOf(self.ambientSounds, soundIDs[i]) <= -1 then
					xyd.SoundManager.get():playSound(soundIDs[i])
					table.insert(self.ambientSounds, soundIDs[i])
				end
			end
		elseif soundIDs and #soundIDs > 0 and soundIDs[1] == -1 then
			self:stopAmbientSound()
		end
	end
end

function StoryWindow:stopAmbientSound()
	for i in pairs(self.ambientSounds) do
		xyd.SoundManager.get():stopSound(self.ambientSounds[i])
	end

	self.ambientSounds = {}
end

function StoryWindow:checkImagePathType(imgStr)
	if not self.winBgUISprite then
		self.winBgUISprite = self.winBg_:GetComponent(typeof(UISprite))
		self.oldWinBgAlpha = self.winBgUISprite.alpha
	end

	if imgStr and imgStr == "-1" then
		self.bg_:SetActive(false)
		self.bg2_:SetActive(false)

		self.winBgUISprite.alpha = 0.01
	else
		self.winBgUISprite.alpha = self.oldWinBgAlpha
	end

	if self.btnSkipGroup_ and not tolua.isnull(self.btnSkipGroup_) and self.btnSkip_ and not tolua.isnull(self.btnSkip_) and self.btnSkipGroup_.gameObject.activeSelf and self.btnSkip_.gameObject.activeSelf then
		if imgStr and imgStr == "-1" then
			self.btnSkip_.gameObject:GetComponent(typeof(UITexture)).alpha = 0.01
			self.btnSkip_.gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

			self.btnBottomSkipNew_.gameObject:SetActive(true)
		else
			self.btnSkip_.gameObject:GetComponent(typeof(UITexture)).alpha = 1
			self.btnSkip_.gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

			self.btnBottomSkipNew_.gameObject:SetActive(false)
		end
	end
end

return StoryWindow
