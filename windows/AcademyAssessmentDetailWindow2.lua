local PngNum = import("app.components.PngNum")
local AcademyAssessmentDetailItem = class("AcademyAssessmentDetailItem", import("app.components.CopyComponent"))
local BigContent = class("BigContent", import("app.components.CopyComponent"))
local BaseWindow = import(".BaseWindow")
local AcademyAssessmentDetailWindow2 = class("AcademyAssessmentDetailWindow2", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local WindowTop = import("app.components.WindowTop")
local BubleTextNow = class("BubleTextNow", import("app.components.BubbleText"))
local SPINE_TYPE = {
	86,
	87,
	88,
	89,
	90,
	91
}
local spinePos = {
	{
		1,
		48,
		391
	},
	{
		1,
		-15,
		631
	},
	{
		1,
		19,
		583
	},
	{
		1,
		44,
		487
	},
	{
		-1,
		32,
		626
	},
	{
		-1,
		32,
		510
	}
}

function BubleTextNow:playDialogAction(text)
	self.text_ = text
	self.label_.text = __(self.text_)
end

function BubleTextNow:setLabel(label)
	self.label_ = label
end

function BubleTextNow:setBgVisible(visible)
	self.bgImg_:SetActive(visible)
end

function BubleTextNow:playDisappear()
end

function BubleTextNow:setSize(w, h, fontSize)
end

function BubleTextNow:setBgVector(isRight)
end

function BubleTextNow:setBubbleFlipX(ifFlip)
end

function BubleTextNow:setPositionY(posY)
end

function AcademyAssessmentDetailItem:ctor(go, parent)
	AcademyAssessmentDetailItem.super.ctor(self, go, parent)

	self.parent = parent

	xyd.setDragScrollView(go, parent.scroller_)

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

function AcademyAssessmentDetailItem:getUIComponent()
	local go = self.go
	self.itemsGroup_ = self.go:NodeByName("itemsGroup_").gameObject
	self.itemsGroup_layout = self.go:ComponentByName("itemsGroup_", typeof(UILayout))
	self.btnFight_ = self.go:ComponentByName("btnFight_", typeof(UISprite))
	self.btnFightLabel = self.btnFight_:ComponentByName("btnFightLabel", typeof(UILabel))
	self.groupLock_ = self.go:NodeByName("groupLock_").gameObject
	self.itemBgImg_ = self.go:ComponentByName("itemBgImg", typeof(UISprite))
	self.btnFightIcon = self.btnFight_:ComponentByName("btnFightIcon", typeof(UISprite))

	xyd.setDragScrollView(self.groupLock_, self.parent.scroller_)

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

function AcademyAssessmentDetailItem:registerEvent()
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

function AcademyAssessmentDetailItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.id_ = info.id
	self.fortId_ = info.fort_id
	self.index_ = info.index

	self:initItem()

	if index == 1 and self.parent.parent.AcademyAssessmentDetailItem1 == nil then
		self.parent.parent.AcademyAssessmentDetailItem1 = self.go
	end

	if index == 1 and self.parent.parent.fightBtn == nil then
		self.parent.parent.fightBtn = self.btnFight_
	end

	if index == 1 and self.parent.parent.enemyInfoBtn == nil then
		self.parent.parent.enemyInfoBtn = self.enemyInfoBtn
	end

	if index == 1 and self.parent.parent.scroller_guide == nil then
		self.parent.parent.scroller_guide = self.parent.scroller_
	end
end

function AcademyAssessmentDetailItem:initItem()
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
			scale = Vector3(0.7, 0.7, 1)
		})
	end

	self.itemsGroup_layout:Reposition()
end

function AcademyAssessmentDetailItem:onFight()
	if self.parent.parent.isCanMove == false then
		return
	end

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

function AcademyAssessmentDetailItem:onSweep()
	if self.parent.parent.isCanMove == false then
		return
	end

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

function AcademyAssessmentDetailItem:lock()
	self.groupLock_:SetActive(true)
end

function AcademyAssessmentDetailItem:unLock()
	self.groupLock_:SetActive(false)
end

function AcademyAssessmentDetailItem:checkFirstTextShow()
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

function BigContent:ctor(go, params, parent)
	self.fortTable_ = xyd.tables.academyAssessmentNewTable
	local time = xyd.tables.miscTable:getVal("school_practise_switch_time")

	if tonumber(time) <= xyd.getServerTime() then
		self.fortTable_ = xyd.tables.academyAssessmentNewTable2
	end

	BigContent.super.ctor(self, go)

	self.window_ = go
	self.fortId_ = params.fort_id
	self.parent = parent
	self.labelDescColorArr = {
		345219839,
		627810815,
		3375318527.0,
		427302399,
		3259873023.0,
		3530695935.0
	}

	self:initWindow()
end

function BigContent:getGo()
	return self.window_.gameObject
end

function BigContent:initWindow()
	self:getUIComponents()

	local data = self.fortTable_:getIdsByFort(self.fortId_)

	xyd.setUITextureByNameAsync(self.imgTitle_, "academy_assassment_group_" .. self.fortId_ .. "_title_" .. xyd.Global.lang, true)
	xyd.setUITextureAsync(self.imgBg_, "Textures/academy_assessment_web/banner/group_" .. self.fortId_ .. "/academy_assessment_group_" .. self.fortId_ .. "_bg")
	xyd.setUITextureAsync(self.imgTextBg_, "Textures/academy_assessment_web/banner/group_" .. self.fortId_ .. "/academy_assassment_dialog_" .. self.fortId_ .. "_bg")

	self.labelDesc_.text = __("ACADEMY_ASSESSMENT_TEXT0" .. tostring(self.fortId_))
	self.labelDesc_.effectColor = Color.New2(self.labelDescColorArr[self.fortId_])

	self:onTicketChange()
	self:initData()
	self:registerEvent()
	self:initPartner()
end

function BigContent:initPartner()
	self.partnerModel = import("app.components.GirlsModel").new(self.modelCon.gameObject)

	self.partnerModel:setModelInfo({
		id = SPINE_TYPE[self.fortId_]
	}, function ()
		local bubble = BubleTextNow.new(self.modelCon.gameObject)

		bubble:setLabel(self.labelDesc_)
		bubble:setBgVisible(false)
		self.partnerModel:setBubble(bubble)
	end)

	local posArr = spinePos[self.fortId_]

	self.partnerModel:setModelPosition(posArr[2], posArr[3] * -1, 0)
	self.partnerModel:setModelScaleXYZ(posArr[1] * 0.5, 0.5, 0.5)
	self.partnerModel:setModelBgPosition(0, 0, 0)
end

function BigContent:getUIComponents()
	local winTrans = self.window_.transform
	local group1 = winTrans:NodeByName("group1").gameObject
	self.imgBg_ = group1:ComponentByName("imgBg_", typeof(UITexture))
	self.imgTitle_ = group1:ComponentByName("groupPanel/imgTitle_", typeof(UITexture))
	self.imgTextBg_ = group1:ComponentByName("groupPanel/imgTextBg_", typeof(UITexture))
	self.labelDesc_ = group1:ComponentByName("groupPanel/imgTextBg_/labelDesc_", typeof(UILabel))
	self.helpBtn = group1:ComponentByName("groupPanel/helpBtn", typeof(UISprite)).gameObject
	self.rankBtn = group1:ComponentByName("groupPanel/rankBtn", typeof(UISprite))
	self.modelCon = group1:NodeByName("groupPanel/modelCon").gameObject
	local group2 = winTrans:NodeByName("group2").gameObject
	self.scroller_ = group2:ComponentByName("scroller_", typeof(UIScrollView))
	local wrapContent = group2:ComponentByName("scroller_/itemsGroup_", typeof(UIWrapContent))
	local item = group2:NodeByName("scroller_/academy_assessment_detail_item").gameObject
	self.wrapContent = FixedWrapContent.new(self.scroller_, wrapContent, item, AcademyAssessmentDetailItem, self)
end

function BigContent:checkIsPlayGuide()
	local wnd = xyd.WindowManager:get():getWindow("academy_assessment_guide_window")

	if wnd then
		self:enableScroller(false)
	else
		self:enableScroller(true)
	end
end

function BigContent:enableScroller(flag)
	if flag then
		self.scroller_.enabled = true
	else
		self.scroller_.enabled = false
	end
end

function BigContent:registerEvent()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		if tonumber(xyd.tables.miscTable:getNumber("school_practise_new_help_tips", "value")) <= xyd.models.academyAssessment.seasonId then
			xyd.WindowManager:get():openWindow("help_window", {
				key = "ACADEMY_ASSESSMENT_WINDOW_HELP_NEW_2"
			})
		else
			xyd.WindowManager:get():openWindow("help_window", {
				key = "ACADEMY_ASSESSMENT_WINDOW_HELP_NEW"
			})
		end
	end

	UIEventListener.Get(self.rankBtn.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("academy_assessment_rank_window2", {
			fort_id = self.fortId_
		})
	end

	self.eventProxyInner_:addEventListener(xyd.event.SCHOOL_PRACTICE_FIGHT, handler(self, self.onFight))
	self.eventProxyInner_:addEventListener(xyd.event.SCHOOL_PRACTICE_BUY_TICKETS, handler(self, self.onTicketChange))
	self.eventProxyInner_:addEventListener(xyd.event.SCHOOL_PRACTICE_SWEEP, handler(self, self.onSweep))
	self.eventProxyInner_:addEventListener(xyd.event.SCHOOL_BATCH_FAKE_FIGHT, handler(self, self.onGetFakeFightMsg))
end

function BigContent:onGetFakeFightMsg(event)
	self:onTicketChange()

	if not event.data.fort_info or event.data.fort_info and event.data.fort_info.fort_id ~= self.fortId_ then
		return
	end

	self:initData()
end

function BigContent:onTicketChange(event)
	if not event then
		local items = self.parent.windowTop:getResItems()

		items[1]:setItemNum(xyd.models.academyAssessment:getSweepTimes())
		items[2]:setItemNum(xyd.models.academyAssessment:getChallengeTimes())

		return
	end

	local data = event.data
	local items = self.parent.windowTop:getResItems()

	items[1]:setItemNum(data.map_info.sweep_times)
	items[2]:setItemNum(data.map_info.challenge_times)
end

function BigContent:onFight(event)
	self:onTicketChange()

	if not event.data.is_win or event.data.is_win == 0 then
		return
	end

	if not event.data.fort_info or event.data.fort_info and event.data.fort_info.fort_id ~= self.fortId_ then
		return
	end

	local currentStage = xyd.models.academyAssessment:getCurrentStage(self.fortId_)
	local numTwoId = self.fortTable_:getIdsByFort(self.fortId_)[2]

	if currentStage ~= numTwoId then
		table.remove(self.collect, 1)
	end

	local lastItem = self.collect[#self.collect]
	local lastID = lastItem.id
	local lastIndex = lastItem.index
	local ids = self.fortTable_:getIdsByFort(self.fortId_)

	if lastID < ids[#ids] then
		table.insert(self.collect, {
			id = lastID + 1,
			index = lastIndex + 1,
			fort_id = self.fortId_
		})
	end

	self.wrapContent:setInfos(self.collect)
end

function BigContent:onSweep(event)
	local data = event.data

	self:onTicketChange()
	xyd.alertItems(data.items)
end

function BigContent:initData()
	local ids = self.fortTable_:getIdsByFort(self.fortId_)
	local curId = xyd.models.academyAssessment:getCurrentStage(self.fortId_)
	local data = {}
	local maxLen = 7

	if curId == -1 then
		table.insert(data, {
			cnt = 1,
			id = ids[#ids],
			index = #ids,
			fort_id = self.fortId_
		})
	else
		local cnt = 0

		for i = 1, #ids do
			if maxLen <= cnt then
				break
			end

			if ids[i] >= curId - 1 then
				table.insert(data, {
					id = ids[i],
					index = i,
					fort_id = self.fortId_,
					cnt = cnt + 1
				})

				cnt = cnt + 1
			end
		end
	end

	self.collect = data

	self.wrapContent:setInfos(data)
end

function AcademyAssessmentDetailWindow2:ctor(name, params)
	self.fortId_ = params.fort_id
	self.curPageNum_ = self.fortId_
	self.pageArr = {}
	self.isCanMove = true

	AcademyAssessmentDetailWindow2.super.ctor(self, name, params)
end

function AcademyAssessmentDetailWindow2:initWindow()
	AcademyAssessmentDetailWindow2.super.initWindow(self)

	local winTrans = self.window_.transform
	self.content = winTrans:NodeByName("groupAction/content").gameObject
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.arrowCon = self.groupAction:NodeByName("arrowPosCon/arrowCon").gameObject
	self.arrowRightBtn = self.arrowCon:NodeByName("arrowRightBtn").gameObject
	self.arrowLeftBtn = self.arrowCon:NodeByName("arrowLeftBtn").gameObject

	self:updateTickets()

	local tmp = NGUITools.AddChild(self.groupAction.gameObject, self.content.gameObject)
	local item = BigContent.new(tmp, {
		fort_id = self.fortId_
	}, self)
	self.pageArr[self.fortId_] = item

	self.content:SetActive(false)
	self:registerEvent()
end

function AcademyAssessmentDetailWindow2:registerEvent()
	UIEventListener.Get(self.arrowRightBtn.gameObject).onClick = handler(self, function ()
		self:turnPage(1)
	end)
	UIEventListener.Get(self.arrowLeftBtn.gameObject).onClick = handler(self, function ()
		self:turnPage(-1)
	end)
end

function AcademyAssessmentDetailWindow2:turnPage(num)
	if self.isCanMove == false then
		return
	end

	self.isCanMove = false
	local page = self.curPageNum_ + num

	if page > 6 then
		page = 1
	end

	if page <= 0 then
		page = 6
	end

	if self.pageArr[page] then
		self.pageArr[page]:getGo():SetActive(true)
		self.pageArr[page]:getGo():SetLocalPosition(1000 * num * -1, 0, 0)
	else
		local tmp = NGUITools.AddChild(self.groupAction.gameObject, self.content.gameObject)
		local item = BigContent.new(tmp, {
			fort_id = page
		}, self)
		self.pageArr[page] = item

		tmp:SetLocalPosition(1000 * num * -1, 0, 0)
	end

	local numContrary = num * -1
	self.action1 = DG.Tweening.DOTween.Sequence()

	self.action1:Append(self.pageArr[page]:getGo().transform:DOLocalMoveX(720 * numContrary, 0.07))
	self.action1:AppendCallback(function ()
		self.action2 = DG.Tweening.DOTween.Sequence()

		self.action2:Append(self.pageArr[self.curPageNum_]:getGo().transform:DOLocalMoveX(-1066 * numContrary, 0.3861))
		self.action2:AppendCallback(function ()
			self.pageArr[self.curPageNum_]:getGo():SetActive(false)
			self.action2:Kill(true)
		end)
		self.action1:Kill(true)

		self.action1 = DG.Tweening.DOTween.Sequence()

		self.action1:Append(self.pageArr[page]:getGo().transform:DOLocalMoveX(-100 * numContrary, 0.297))
		self.action1:Append(self.pageArr[page]:getGo().transform:DOLocalMoveX(0, 0.2))
		self.action1:AppendCallback(function ()
			self.action1:Kill(true)

			self.curPageNum_ = page
			self.isCanMove = true
		end)
	end)
end

function AcademyAssessmentDetailWindow2:playOpenAnimation(callback)
	callback()

	local wnd = xyd.WindowManager:get():getWindow("academy_assessment_guide_window")

	if wnd then
		return
	end

	self.groupAction:X(-1000)
	self.groupAction:SetActive(true)

	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:AppendInterval(0.2)
	sequence:Append(self.groupAction.transform:DOLocalMoveX(50, 0.3))
	sequence:Append(self.groupAction.transform:DOLocalMoveX(0, 0.27))
	sequence:AppendCallback(function ()
		sequence:Kill(true)
		self:setWndComplete()
	end)

	self.windowTween_ = sequence
end

function AcademyAssessmentDetailWindow2:willCloseAnimation(callback)
	if self.windowTween_ then
		self.windowTween_:Kill(true)

		self.windowTween_ = nil
	end

	local sequence = self:getSequence()

	sequence:Append(self.groupMagroupActionin.transform:DOLocalMoveX(50, 0.14))
	sequence:Append(self.groupAction.transform:DOLocalMoveX(-1000, 0.15))
	sequence:AppendCallback(function ()
		sequence:Kill(true)

		if callback then
			callback()
		end
	end)
end

function AcademyAssessmentDetailWindow2:updateTickets()
	if not self.windowTop then
		self.windowTop = WindowTop.new(self.window_, self.name_)
	end

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

				xyd.WindowManager:get():openWindow("item_buy_window", {
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

function AcademyAssessmentDetailWindow2:didClose(params, force)
	AcademyAssessmentDetailWindow2.super.didClose(self)

	for i = 1, 6 do
		if self.pageArr[i] then
			self.pageArr[i]:dispose()
		end
	end

	local wnd = xyd.WindowManager:get():getWindow("academy_assessment_window")

	if wnd then
		wnd:initData()
	end
end

return AcademyAssessmentDetailWindow2
