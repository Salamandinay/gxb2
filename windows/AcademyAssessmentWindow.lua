local AcademyAssessmentExtraItem = class("AcademyAssessmentExtraItem")
local PngNum = import("app.components.PngNum")

function AcademyAssessmentExtraItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.fortTable_ = xyd.tables.academyAssessmentNewTable
	local time = xyd.tables.miscTable:getVal("school_practise_switch_time")

	if tonumber(time) <= xyd.getServerTime() then
		self.fortTable_ = xyd.tables.academyAssessmentNewTable2
	end

	self.numColorMap = {
		"friend_team_boss_brown",
		"friend_team_boss_grey",
		"friend_team_boss_yellow",
		"friend_team_boss_blue",
		"friend_team_boss_yellow",
		"friend_team_boss_yellow",
		"friend_team_boss_yellow",
		"friend_team_boss_yellow"
	}

	self:getUIComponent()
	self:registerEvent()
end

function AcademyAssessmentExtraItem:SetActive(visible)
	self.go:SetActive(visible)
end

function AcademyAssessmentExtraItem:getUIComponent()
	local go = self.go
	self.itemsGroup_ = self.go:NodeByName("itemsGroup_").gameObject
	self.itemsGroup_layout = self.go:ComponentByName("itemsGroup_", typeof(UILayout))
	self.btnFight_ = self.go:ComponentByName("btnFight_", typeof(UISprite))
	self.btnFightLabel = self.btnFight_:ComponentByName("btnFightLabel", typeof(UILabel))
	self.groupLock_ = self.go:NodeByName("groupLock_").gameObject
	self.itemBgImg_ = self.go:ComponentByName("itemBgImg", typeof(UISprite))
	self.btnFightIcon = self.btnFight_:ComponentByName("btnFightIcon", typeof(UISprite))
	self.enemyInfoBtn = self.go:NodeByName("enemyInfoBtn").gameObject
	self.firstTipsText_ = self.go:ComponentByName("firstTipsText", typeof(UILabel))
	self.firstTipsText_.text = __("ACADEMY_ASSESSMENT_FIRST_PASS_AWARD")
	local group1 = self.go:NodeByName("group1").gameObject
	local numLabel = group1:NodeByName("numLabel").gameObject
	self.numLabel = PngNum.new(numLabel)
	self.numBg = group1:ComponentByName("numBg", typeof(UISprite))
	local group2 = self.go:NodeByName("group2").gameObject
	self.labelPower_ = group2:ComponentByName("labelPower_", typeof(UILabel))
end

function AcademyAssessmentExtraItem:registerEvent()
	UIEventListener.Get(self.btnFight_.gameObject).onClick = function ()
		local currentStageID = xyd.models.academyAssessment:getCurrentStage(self.fortId_)
		local allIds = self.fortTable_:getIdsByFort(self.fortId_)
		local checkNum = 1

		for i in pairs(allIds) do
			if currentStageID == -1 then
				checkNum = -1

				break
			end

			if currentStageID == allIds[i] then
				break
			else
				checkNum = checkNum + 1
			end
		end

		local currentStage = checkNum
		local skipStage = xyd.tables.miscTable:getNumber("school_practise_quick1", "value")
		local skipStage2 = xyd.tables.miscTable:getNumber("school_practise_quick2", "value")
		local historyMaxStageID = xyd.models.academyAssessment:getMaxStage(self.fortId_)
		local allIds = self.fortTable_:getIdsByFort(self.fortId_)
		local checkNum = 0

		for i in pairs(allIds) do
			if historyMaxStageID == 0 then
				break
			end

			if historyMaxStageID == allIds[i] then
				checkNum = checkNum + 1

				break
			else
				checkNum = checkNum + 1
			end
		end

		local historyMaxStage = checkNum
		local n = historyMaxStage - skipStage2

		if currentStageID ~= -1 and currentStageID == self.id_ and skipStage <= historyMaxStage and currentStage < n then
			local params = {
				fortId = self.fortId_,
				currentStage = currentStage,
				noCallback = function ()
					if currentStageID == -1 or self.id_ < currentStageID then
						self:onSweep()
					elseif currentStageID == self.id_ then
						self:onFight()
					else
						xyd.showToast(__("LOCK_STORY_LIST"))
					end
				end
			}

			xyd.WindowManager.get():openWindow("one_click_clearance_window", params)

			return nil
		end

		if currentStageID == -1 or self.id_ < currentStageID then
			self:onSweep()
		elseif currentStageID == self.id_ then
			self:onFight()
		else
			xyd.showToast(__("LOCK_STORY_LIST"))
		end
	end

	UIEventListener.Get(self.enemyInfoBtn.gameObject).onClick = function ()
		local battleId = self.fortTable_:getBattleId(self.id_, (xyd.models.academyAssessment.seasonId - 1) % 3 + 1)

		xyd.WindowManager.get():openWindow("academy_assessment_enemy_detail_window", {
			id = battleId,
			lev = self.index_
		})
	end
end

function AcademyAssessmentExtraItem:setInfo(info)
	self.id_ = info.id
	self.fortId_ = info.fort_id
	self.index_ = info.index

	self:initItem()
end

function AcademyAssessmentExtraItem:initItem()
	self.labelPower_.text = self.fortTable_:getPower(self.id_)
	local iconName = self.numColorMap[math.floor((self.index_ - 1) / 10) + 1]

	if self.index_ > 80 then
		iconName = self.numColorMap[math.floor(7.9) + 1]
	end

	self.numLabel:setInfo({
		iconName = iconName,
		num = self.index_
	})

	local bgName = "boss_award_bg_" .. tostring(math.ceil(self.index_ / 10))

	if self.index_ > 80 then
		bgName = "boss_award_bg_8"
	end

	xyd.setUISpriteAsync(self.numBg, nil, bgName)
	NGUITools.DestroyChildren(self.itemsGroup_.transform)

	local rewards = self.fortTable_:getReward(self.id_)
	local currentStage = xyd.models.academyAssessment:getCurrentStage(self.fortId_)

	if currentStage == -1 or self.id_ < currentStage then
		self:unLock()

		self.btnFightLabel.text = __("FRIEND_SWEEP")
		rewards = self.fortTable_:getSweepReward(self.id_)

		xyd.setUISpriteAsync(self.itemBgImg_, nil, "academy_assessment_award_bg", nil, )
		xyd.setUISpriteAsync(self.btnFightIcon, nil, "icon_63_small", nil, )
		self.firstTipsText_:SetActive(false)
	elseif currentStage == self.id_ then
		self:unLock()

		self.btnFightLabel.text = __("FIGHT")

		xyd.setUISpriteAsync(self.itemBgImg_, nil, "academy_assessment_award_bg_first", nil, )
		xyd.setUISpriteAsync(self.btnFightIcon, nil, "icon_64_small", nil, )

		local isFirst = self:checkFirstTextShow()

		if isFirst == false then
			rewards = self.fortTable_:getNotFirstPassReward(self.id_)

			xyd.setUISpriteAsync(self.itemBgImg_, nil, "academy_assessment_award_bg", nil, )
		end
	else
		self:lock()

		self.btnFightLabel.text = __("FIGHT")

		xyd.setUISpriteAsync(self.itemBgImg_, nil, "academy_assessment_award_bg_lock", nil, )
		xyd.setUISpriteAsync(self.btnFightIcon, nil, "icon_64_small", nil, )

		local isFirst = self:checkFirstTextShow()

		if isFirst == false then
			rewards = self.fortTable_:getNotFirstPassReward(self.id_)
		end
	end

	for _, reward in pairs(rewards) do
		local icon = xyd.getItemIcon({
			itemID = reward[1],
			num = reward[2],
			uiRoot = self.itemsGroup_,
			scale = Vector3(0.7, 0.7, 1),
			dragScrollView = self.parent.parent.scroller_
		})
	end

	self.itemsGroup_layout:Reposition()
end

function AcademyAssessmentExtraItem:onFight()
	local times = xyd.models.academyAssessment:getChallengeTimes()

	if times <= 0 then
		xyd.showToast(__("SCHOOL_PRACTICE_CHALLENGE_TICKETS_NOT_ENOUGH"))

		return
	end

	local fightParams = {
		showSkip = true,
		mapType = xyd.MapType.ACADEMY_ASSESSMENT,
		battleID = self.id_,
		fortID = self.fortId_,
		battleType = xyd.BattleType.ACADEMY_ASSESSMENT,
		current_group = self.fortId_,
		stageId = self.id_,
		skipState = xyd.checkCondition(tonumber(xyd.db.misc:getValue("academy_assessment_skip_report")) == 1, true, false),
		btnSkipCallback = function (flag)
			local valuedata = xyd.checkCondition(flag, 1, 0)

			xyd.db.misc:setValue({
				key = "academy_assessment_skip_report",
				value = valuedata
			})
		end
	}

	xyd.WindowManager:get():openWindow("battle_formation_window", fightParams)
end

function AcademyAssessmentExtraItem:onSweep()
	local times = xyd.models.academyAssessment:getSweepTimes()

	if times <= 0 then
		xyd.showToast(__("SCHOOL_PRACTICE_SWEEP_TICKETS_NOT_ENOUGH"))

		return
	end

	local params = {
		id = self.id_,
		fort_id = self.fortId_
	}

	xyd.WindowManager:get():openWindow("academy_assessment_sweep_window", params)
end

function AcademyAssessmentExtraItem:lock()
	self.groupLock_:SetActive(true)
end

function AcademyAssessmentExtraItem:unLock()
	self.groupLock_:SetActive(false)
end

function AcademyAssessmentExtraItem:checkFirstTextShow()
	local maxStage = xyd.models.academyAssessment:getMaxStage(self.fortId_)
	local isFirst = false

	if maxStage < self.id_ then
		self.firstTipsText_:SetActive(true)

		isFirst = true
	else
		self.firstTipsText_:SetActive(false)

		isFirst = false
	end

	return isFirst
end

local AcademyAssessmentItem = class("AcademyAssessmentItem")
local CountDown = import("app.components.CountDown")

function AcademyAssessmentItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.fortTable = xyd.models.academyAssessment:getAcademyAssessMentTable()

	xyd.setDragScrollView(go, parent.scroller_)
	self:getUIComponent()
	self:registerEvent()

	self.items = {}
end

function AcademyAssessmentItem:getUIComponent()
	local go = self.go
	self.imgBg_ = go:ComponentByName("imgBg_", typeof(UISprite))
	self.imgBg_right = go:ComponentByName("imgBg_right", typeof(UISprite))
	self.labelTitle_ = go:ComponentByName("labelTitle_", typeof(UILabel))
	self.labelDesc_ = go:ComponentByName("labelDesc_", typeof(UILabel))
	self.progressText_ = go:ComponentByName("progressText_", typeof(UILabel))
	self.imgDone = go:ComponentByName("imgDone", typeof(UISprite))
	self.groupArrows = go:NodeByName("groupArrows").gameObject
	self.imgUp = self.groupArrows:ComponentByName("imgUp", typeof(UISprite))
	self.imgDown = self.groupArrows:ComponentByName("imgDown", typeof(UISprite))
	self.groupExtra = go:NodeByName("groupExtra").gameObject
	self.groupExtraGrid = self.groupExtra:NodeByName("grid").gameObject
	self.groupExtraWidget = self.groupExtra:GetComponent(typeof(UIWidget))
	self.extraItem = go:NodeByName("academy_assessment_extra_item").gameObject
end

function AcademyAssessmentItem:registerEvent()
	UIEventListener.Get(self.go).onClick = handler(self, self.onClickFortItem)
	UIEventListener.Get(self.groupArrows.gameObject).onClick = handler(self, self.onClickArrow)
end

function AcademyAssessmentItem:onClickArrow()
	if self.isMoving then
		return
	end

	self.extraGroupActive = not self.extraGroupActive
	self.parent.extraGroupActive[self.data.index] = self.extraGroupActive
	self.isMoving = true

	self:updateExtraGroup()
end

function AcademyAssessmentItem:updateExtraGroup()
	local isGuide = xyd.db.misc:getValue("school_practise_guide")

	if isGuide == nil then
		self.groupArrows:SetActive(false)
	else
		self.groupArrows:SetActive(true)
	end

	if self.extraGroupActive then
		self.groupExtra:SetActive(true)
		self.imgUp:SetActive(true)
		self.imgDown:SetActive(false)
	else
		self.groupExtra:SetActive(false)
		self.imgUp:SetActive(false)
		self.imgDown:SetActive(true)
	end

	local curStage = xyd.models.academyAssessment:getCurrentStage(self.fortId)
	local ids = self.fortTable:getIdsByFort(self.fortId)

	if curStage == -1 then
		self.imgDone:SetActive(true)
		self.items[1]:setInfo({
			id = ids[#ids],
			index = #ids,
			fort_id = self.fortId
		})
		self.items[2]:SetActive(false)

		self.groupExtraWidget.height = 143
	else
		local stageIndex = self.fortTable:getSchoolSort(curStage)

		self.imgDone:SetActive(false)

		if stageIndex ~= 1 then
			self.items[1]:setInfo({
				id = curStage - 1,
				index = stageIndex - 1,
				fort_id = self.fortId
			})
			self.items[2]:SetActive(true)
			self.items[2]:setInfo({
				id = curStage,
				index = stageIndex,
				fort_id = self.fortId
			})

			self.groupExtraWidget.height = 268
		else
			self.items[1]:setInfo({
				id = curStage,
				index = stageIndex,
				fort_id = self.fortId
			})
			self.items[2]:SetActive(false)

			self.groupExtraWidget.height = 143
		end
	end

	XYDCo.WaitForFrame(1, function ()
		local win = xyd.WindowManager:get():getWindow("academy_assessment_window")

		if not win or not self.parent or not self.parent.itemLayout then
			return
		end

		self.parent.itemLayout:Reposition()

		if self.isMoving then
			local pos = 0
			local sp = self.parent.scroller_.gameObject:GetComponent(typeof(SpringPanel))
			local panel = self.parent.scroller_.gameObject:GetComponent(typeof(UIPanel))
			local initPos = self.parent.scroller_.transform.localPosition.y
			local dis = initPos

			if self.extraGroupActive then
				pos = self.go.transform.localPosition.y + self.groupExtra.transform.localPosition.y - self.groupExtraWidget.height

				if -pos > initPos + panel.height / 2 then
					dis = -pos - panel.height / 2
				end
			else
				local lastItem = self.parent.items[#self.parent.items]
				pos = lastItem.go.transform.localPosition.y + lastItem.groupExtra.transform.localPosition.y

				if self.parent.extraGroupActive[#self.parent.items] then
					pos = pos - lastItem.groupExtraWidget.height
				end

				if -pos < initPos + panel.height / 2 then
					dis = -pos - panel.height / 2
				end
			end

			sp.Begin(sp.gameObject, Vector3(0, dis, 0), 16)

			self.isMoving = false
		end
	end, nil)
end

function AcademyAssessmentItem:setInfo(info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)

	self.fortId = info.fort_id
	self.current_stage = info.current_stage
	self.extraGroupActive = info.extraGroupActive

	self:initItem()

	if self.fortId == 1 and self.parent.AcademyAssessmentItem1 == nil then
		self.parent.AcademyAssessmentItem1 = self.go
	end
end

function AcademyAssessmentItem:initItem()
	self.labelTitle_.text = __("SCHOOL_PRACTICE_TITLE_0" .. tostring(self.fortId))
	self.labelDesc_.text = __("SCHOOL_PRACTICE_TEXT_0" .. tostring(self.fortId))

	xyd.setUISpriteAsync(self.imgDone, nil, "academy_assessment_done_" .. xyd.Global.lang, nil, , true)

	if xyd.models.academyAssessment:getIsNewSeason() == false then
		xyd.setUISpriteAsync(self.imgBg_, nil, "btn_academy_assessment_" .. tostring(self.fortId))
		xyd.setUISpriteAsync(self.imgBg_right, nil, "academy_assessment_right_bg")
	else
		xyd.setUISpriteAsync(self.imgBg_, nil, "btn_academy_assessment_" .. tostring(self.fortId) .. "_new")
		xyd.setUISpriteAsync(self.imgBg_right, nil, "academy_assessment_right_bg_new")
	end

	if xyd.models.academyAssessment:getIsNewSeason() then
		local checkNum = 0
		local allIds = self.fortTable:getIdsByFort(self.fortId)

		for i in pairs(allIds) do
			if self.current_stage == -1 then
				checkNum = -1

				break
			end

			if self.current_stage == allIds[i] then
				break
			else
				checkNum = checkNum + 1
			end
		end

		if checkNum == -1 then
			self.progressText_.text = __("ACADEMY_ASSESSMENT_CURRENT_TEXT", #allIds, #allIds)
		else
			self.progressText_.text = __("ACADEMY_ASSESSMENT_CURRENT_TEXT", checkNum, #allIds)
		end

		self.progressText_.gameObject:SetActive(xyd.models.academyAssessment:getIsNewSeason())
	end

	for i = 1, 2 do
		if not self.items[i] then
			local tmp = NGUITools.AddChild(self.groupExtraGrid.gameObject, self.extraItem.gameObject)
			local item = AcademyAssessmentExtraItem.new(tmp, self)
			self.items[i] = item
		end
	end

	self:updateExtraGroup()
end

function AcademyAssessmentItem:onClickFortItem()
	if xyd.models.academyAssessment:getIsNewSeason() then
		xyd.WindowManager.get():openWindow("academy_assessment_detail_window2", {
			fort_id = self.fortId
		})
	else
		xyd.WindowManager.get():openWindow("academy_assessment_detail_window", {
			fort_id = self.fortId
		})
	end
end

local BaseWindow = import(".BaseWindow")
local AcademyAssessmentWindow = class("AcademyAssessmentWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local WindowTop = import("app.components.WindowTop")

function AcademyAssessmentWindow:ctor(name, params)
	AcademyAssessmentWindow.super.ctor(self, name, params)

	self.extraGroupActive = {}
end

function AcademyAssessmentWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupBg = winTrans:NodeByName("groupBg").gameObject
	self.bg = self.groupBg:ComponentByName("bg", typeof(UITexture))
	self.groupMain = winTrans:NodeByName("groupMain").gameObject
	local group1 = self.groupMain:NodeByName("group1").gameObject
	self.helpBtn_ = group1:ComponentByName("helpBtn", typeof(UISprite)).gameObject
	self.shopBtn_ = group1:ComponentByName("shopBtn_", typeof(UISprite))
	self.btnDressShow = group1:NodeByName("btnDressShow").gameObject
	self.rankBtn = group1:ComponentByName("rankBtn", typeof(UISprite))
	self.awardBtn = group1:ComponentByName("awardBtn", typeof(UISprite))
	self.group2 = group1:NodeByName("group2").gameObject
	self.titleBgLeft = self.group2:ComponentByName("imageLeft", typeof(UISprite))
	self.titleBgRight = self.group2:ComponentByName("imageRight", typeof(UISprite))
	self.imgTitle_ = self.group2:ComponentByName("imgTitle_", typeof(UISprite))
	self.tipsTextCon = self.group2:NodeByName("tipsTextCon").gameObject
	self.tipsTextCon_layout = self.group2:ComponentByName("tipsTextCon", typeof(UILayout))
	self.tipsText = self.tipsTextCon:ComponentByName("tipsText", typeof(UILabel))
	self.tipsNumText = self.tipsTextCon:ComponentByName("tipsNumText", typeof(UILabel))
	local group3 = self.groupMain:NodeByName("group3").gameObject
	self.scroller_ = group3:ComponentByName("scroller_", typeof(UIScrollView))
	self.scroller_guide = group3:ComponentByName("scroller_", typeof(UIScrollView))
	self.itemGroup_ = group3:NodeByName("scroller_/itemGroup_").gameObject
	self.item = group3:NodeByName("scroller_/academy_assessment_item").gameObject
	self.itemLayout = self.itemGroup_:GetComponent(typeof(UILayout))
end

function AcademyAssessmentWindow:playOpenAnimations(preWinName, callback)
	callback()

	local action1 = DG.Tweening.DOTween.Sequence():OnComplete(function ()
		self:setWndComplete()
	end)
	local pos = self.groupMain.transform.localPosition

	self.groupMain:setLocalPosition(-1000, pos.y, pos.z)
	action1:Append(self.groupMain.transform:DOLocalMove(Vector3(50, pos.y, pos.z), 0.3))
	action1:Append(self.groupMain.transform:DOLocalMove(Vector3(pos.x, pos.y, pos.z), 0.27))
end

function AcademyAssessmentWindow:initWindow()
	AcademyAssessmentWindow.super.initWindow(self)

	if xyd.models.academyAssessment:getIsNewSeason() and not xyd.db.misc:getValue("academy_assessment_pop_up_window_pop_state" .. xyd.models.academyAssessment.seasonId) then
		xyd.db.misc:setValue({
			value = 1,
			key = "academy_assessment_pop_up_window_pop_state" .. xyd.models.academyAssessment.seasonId
		})
	end

	xyd.db.misc:setValue({
		key = "academy_assessment_daily_redpoint",
		value = xyd.getServerTime()
	})
	self:getUIComponent()
	self:registerEvent()
	print("LOAD ===========")

	local src = "academy_assessment_title_" .. tostring(xyd.Global.lang)

	print(src)
	xyd.setUITextureAsync(self.bg, "Textures/scenes_web/academy_assessment_bg")

	if xyd.models.academyAssessment:getIsNewSeason() == false then
		xyd.setUISpriteAsync(self.titleBgLeft, nil, "academy_assessment_title_bg", nil, )
		xyd.setUISpriteAsync(self.titleBgRight, nil, "academy_assessment_title_bg", nil, )
		xyd.setUISprite(self.imgTitle_, nil, src)
		self.imgTitle_:MakePixelPerfect()
	else
		xyd.setUISpriteAsync(self.titleBgLeft, nil, "academy_assessment_title_bg_new", function ()
			self.titleBgLeft:MakePixelPerfect()
		end, nil)
		xyd.setUISpriteAsync(self.titleBgRight, nil, "academy_assessment_title_bg_new", function ()
			self.titleBgRight:MakePixelPerfect()
		end, nil)

		src = "academy_assessment_logo_" .. tostring(xyd.Global.lang)

		xyd.setUISpriteAsync(self.imgTitle_, nil, src, function ()
			self.imgTitle_:MakePixelPerfect()
		end, nil)
		self.group2:SetLocalPosition(0, -21, 0)

		self.tipsText.text = __("ACADEMY_ASSESSMENT_END_TIME")
		self.tipsNumText.text = "00:00:00"

		self:initTime()
		self.tipsTextCon:SetActive(true)
		self.tipsTextCon_layout:Reposition()
	end

	if not xyd.models.academyAssessment:getData() or xyd.models.academyAssessment:getHasData() == false then
		xyd.models.academyAssessment:reqInfo()
	else
		self:layout()
	end

	xyd.models.academyAssessment:setRedMark()

	local switchTimeFlag = xyd.db.misc:getValue("school_practise_switch_time_flag")
	switchTimeFlag = switchTimeFlag ~= nil and tonumber(switchTimeFlag) == 1 or false
	local switchTime = xyd.tables.miscTable:getNumber("school_practise_switch_time", "value")

	if switchTime and switchTime < xyd.getServerTime() and not switchTimeFlag then
		local function callback()
			xyd.db.misc:setValue({
				value = 1,
				key = "school_practise_switch_time_flag"
			})
			xyd.db.misc:setValue({
				value = 0,
				key = "academy_assessment_battle_set_ticket_end"
			})
			xyd.db.misc:setValue({
				value = 0,
				key = "academy_assessment_battle_set_fail_end"
			})
		end

		xyd.alert(xyd.AlertType.CONFIRM, __("SCHOOL_PRACTISE_100STAGE_TIP"), callback, __("CONFIRM"), nil, , , , callback)
	end
end

function AcademyAssessmentWindow:initTime()
	local startTime = xyd.models.academyAssessment.startTime
	local allTime = xyd.tables.miscTable:getNumber("school_practise_season_duration", "value")
	local showTime = xyd.tables.miscTable:getNumber("school_practise_display_duration", "value")
	local durationTime = startTime + allTime - showTime - xyd.getServerTime()

	if durationTime > 0 then
		self.setCountDownTime = CountDown.new(self.tipsNumText, {
			duration = durationTime,
			callback = handler(self, self.timeOver)
		})
	else
		self.tipsNumText.text = "00:00"
	end
end

function AcademyAssessmentWindow:timeOver()
	self.tipsNumText.text = "00:00"
end

function AcademyAssessmentWindow:layout()
	self:initResItem()
	self:initData()
	self:onTicketChange()

	if xyd.models.academyAssessment:getIsNewSeason() then
		self.helpBtn_.gameObject:Y(49)
	else
		self.helpBtn_.gameObject:Y(44)
	end

	self.rankBtn:SetActive(xyd.models.academyAssessment:getIsNewSeason())
	self.awardBtn:SetActive(xyd.models.academyAssessment:getIsNewSeason())
	self:checkGuide()
end

function AcademyAssessmentWindow:checkGuide(self)
	local res = xyd.db.misc:getValue("school_practise_guide")

	if res ~= nil then
		print("NO GUIDE")

		return
	else
		if xyd.models.academyAssessment:getIsNewSeason() then
			xyd.WindowManager.get():openWindow("academy_assessment_guide_window", {
				wnd = self,
				guideIds = {
					5,
					6,
					7,
					8
				}
			})
		else
			xyd.WindowManager.get():openWindow("academy_assessment_guide_window", {
				wnd = self,
				guideIds = {
					1,
					2,
					3,
					4
				}
			})
		end

		xyd.db.misc:setValue({
			value = 1,
			key = "school_practise_guide"
		})
	end
end

function AcademyAssessmentWindow:enableScroller(flag)
	if flag then
		self.scroller_.enabled = true
	else
		self.scroller_.enabled = false
	end
end

function AcademyAssessmentWindow:registerEvent()
	AcademyAssessmentWindow.super.register(self)

	UIEventListener.Get(self.shopBtn_.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("shop_window", {
			shopType = xyd.ShopType.SHOP_ASSESSMENT_ACADEMY
		})
	end

	self.eventProxy_:addEventListener(xyd.event.SCHOOL_PRACTICE_FIGHT, handler(self, self.onFight))
	self.eventProxy_:addEventListener(xyd.event.SCHOOL_PRACTICE_BUY_TICKETS, handler(self, self.onTicketChange))
	self.eventProxy_:addEventListener(xyd.event.SCHOOL_PRACTICE_SWEEP, handler(self, self.onSweep))
	self.eventProxy_:addEventListener(xyd.event.SCHOOL_PRACTICE_GET_INFO, function ()
		self:layout()
	end)

	UIEventListener.Get(self.rankBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("academy_assessment_rank_window2")
	end

	UIEventListener.Get(self.awardBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("academy_assessment_award_window")
	end

	UIEventListener.Get(self.helpBtn_.gameObject).onClick = function ()
		if xyd.models.academyAssessment:getIsNewSeason() == false then
			xyd.WindowManager:get():openWindow("help_window", {
				key = "ACADEMY_ASSESSMENT_WINDOW_HELP"
			})
		elseif tonumber(xyd.tables.miscTable:getNumber("school_practise_new_help_tips", "value")) <= xyd.models.academyAssessment.seasonId then
			xyd.WindowManager:get():openWindow("help_window", {
				key = "ACADEMY_ASSESSMENT_WINDOW_HELP_NEW_2"
			})
		else
			xyd.WindowManager:get():openWindow("help_window", {
				key = "ACADEMY_ASSESSMENT_WINDOW_HELP_NEW"
			})
		end
	end

	UIEventListener.Get(self.btnDressShow).onClick = function ()
		xyd.WindowManager.get():openWindow("dress_show_buffs_detail_window", {
			function_id = xyd.FunctionID.ACADEMY_ASSESSMENT
		})
	end

	self.eventProxy_:addEventListener(xyd.event.SCHOOL_BATCH_FAKE_FIGHT, self.onGetFakeFightMsg, self)
end

function AcademyAssessmentWindow:onGetFakeFightMsg(event)
	local data = event.data

	dump(data)

	local map_info = data.map_info
	local items = data.items
	local fort_info = data.fort_info

	xyd.models.itemFloatModel:pushNewItems(items)
	self:onTicketChange()

	local data = {}
	local infos = xyd.models.academyAssessment:getData().map_list

	for _, info in pairs(infos) do
		if info.fort_id then
			table.insert(data, {
				index = 0,
				fort_id = info.fort_id,
				current_stage = info.current_stage
			})
		end
	end

	for i = 1, #data do
		data[i].index = i

		if not self.extraGroupActive[i] then
			self.extraGroupActive[i] = false
		end

		data[i].extraGroupActive = self.extraGroupActive[i]
	end

	for i = 1, #data do
		self.items[i]:setInfo(data[i])
	end
end

function AcademyAssessmentWindow:initResItem()
	self.windowTop = WindowTop.new(self.window_, self.name_, 50)
	local items = {
		{
			ifItemChange = false,
			id = xyd.ItemID.ACCOMPLISH_TICKET,
			callback = function ()
				if xyd.models.academyAssessment:checkTimeEnd() == false then
					xyd.showToast(__("ACADEMY_ASSESSMENT_END_TIPS"))

					return
				end

				local haveBought = xyd.models.academyAssessment:getBuySweepTimes()
				local canBuy = xyd.tables.academyAssessmentCostTable:getIDs() - haveBought

				if canBuy > 0 then
					xyd.WindowManager.get():openWindow("academy_assessment_buy_window", {
						itemParams = {
							num = 1,
							itemID = xyd.ItemID.ACCOMPLISH_TICKET
						}
					})
				else
					xyd.showToast(__("FULL_BUY_SLOT_TIME"))
				end
			end
		},
		{
			ifItemChange = false,
			id = xyd.ItemID.ASSESSMENT_TICKET,
			callback = function ()
				if xyd.models.academyAssessment:checkTimeEnd() == false then
					xyd.showToast(__("ACADEMY_ASSESSMENT_END_TIPS"))

					return
				end

				xyd.WindowManager.get():openWindow("item_buy_window", {
					hide_min_max = true,
					maxNum = -1,
					cost = xyd.tables.miscTable:split2num("school_practise_ticket02_buy", "value", "#"),
					itemParams = {
						num = 1,
						itemID = xyd.ItemID.ASSESSMENT_TICKET
					},
					buyCallback = function (num)
						xyd.models.academyAssessment:reqBuyTickets(xyd.SchoolTicketType.CHALLENGE, num)
					end
				})
			end
		}
	}

	self.windowTop:setItem(items)
end

function AcademyAssessmentWindow:onFight()
	self:onTicketChange()

	local data = {}
	local infos = xyd.models.academyAssessment:getData().map_list

	for _, info in pairs(infos) do
		if info.fort_id then
			table.insert(data, {
				index = 0,
				fort_id = info.fort_id,
				current_stage = info.current_stage
			})
		end
	end

	for i = 1, #data do
		data[i].index = i

		if not self.extraGroupActive[i] then
			self.extraGroupActive[i] = false
		end

		data[i].extraGroupActive = self.extraGroupActive[i]
	end

	for i = 1, #data do
		self.items[i]:setInfo(data[i])
	end
end

function AcademyAssessmentWindow:onSweep(event)
	local data = event.data

	self:onTicketChange()
	xyd.alertItems(data.items)
end

function AcademyAssessmentWindow:onTicketChange()
	local items = self.windowTop:getResItems()

	items[1]:setItemNum(xyd.models.academyAssessment:getSweepTimes())
	items[2]:setItemNum(xyd.models.academyAssessment:getChallengeTimes())
end

function AcademyAssessmentWindow:initData()
	local data = {}
	local infos = xyd.models.academyAssessment:getData().map_list

	for _, info in pairs(infos) do
		if info.fort_id then
			table.insert(data, {
				index = 0,
				fort_id = info.fort_id,
				current_stage = info.current_stage
			})
		end
	end

	for i = 1, #data do
		data[i].index = i

		if not self.extraGroupActive[i] then
			self.extraGroupActive[i] = false
		end

		data[i].extraGroupActive = self.extraGroupActive[i]
	end

	NGUITools.DestroyChildren(self.itemGroup_.transform)

	self.items = {}

	for i = 1, #data do
		local tmp = NGUITools.AddChild(self.itemGroup_.gameObject, self.item.gameObject)
		local item = AcademyAssessmentItem.new(tmp, self)
		self.items[i] = item

		item:setInfo(data[i])
	end

	self.itemLayout:Reposition()
	self:waitForFrame(1, function ()
		self.scroller_:ResetPosition()
	end)
end

return AcademyAssessmentWindow
