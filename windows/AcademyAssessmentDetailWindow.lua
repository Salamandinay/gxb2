local PngNum = import("app.components.PngNum")
local AcademyAssessmentDetailItem = class("AcademyAssessmentDetailItem", import("app.components.CopyComponent"))

function AcademyAssessmentDetailItem:ctor(go, parent)
	AcademyAssessmentDetailItem.super.ctor(self, go, parent)

	self.parent = parent

	xyd.setDragScrollView(go, parent.scroller_)

	self.fortTable_ = xyd.tables.academyAssessmentTable
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
	self.btnFight_ = self.go:ComponentByName("btnFight_", typeof(UISprite))
	self.btnFightLabel = self.btnFight_:ComponentByName("btnFightLabel", typeof(UILabel))
	self.groupLock_ = self.go:NodeByName("groupLock_").gameObject

	xyd.setDragScrollView(self.groupLock_, self.parent.scroller_)

	local group1 = self.go:NodeByName("group1").gameObject
	local numLabel = group1:NodeByName("numLabel").gameObject
	self.numLabel = PngNum.new(numLabel)
	self.numBg = group1:ComponentByName("numBg", typeof(UISprite))
	local group2 = self.go:NodeByName("group2").gameObject
	self.labelPower_ = group2:ComponentByName("labelPower_", typeof(UILabel))
end

function AcademyAssessmentDetailItem:registerEvent()
	UIEventListener.Get(self.btnFight_.gameObject).onClick = function ()
		local currentStage = xyd.models.academyAssessment:getCurrentStage(self.fortId_)

		if currentStage == -1 or self.id_ < currentStage then
			self:onSweep()
		elseif currentStage == self.id_ then
			self:onFight()
		else
			xyd.showToast(__("LOCK_STORY_LIST"))
		end
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

	if index == 1 and self.parent.AcademyAssessmentDetailItem1 == nil then
		self.parent.AcademyAssessmentDetailItem1 = self.go
	end

	if index == 1 and self.parent.fightBtn == nil then
		self.parent.fightBtn = self.btnFight_
	end

	if index == 1 and self.parent.scroller_guide == nil then
		self.parent.scroller_guide = self.parent.scroller_
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
	elseif currentStage == self.id_ then
		self:unLock()

		self.btnFightLabel.text = __("FIGHT")
	else
		self:lock()

		self.btnFightLabel.text = __("FIGHT")
	end

	for _, reward in pairs(rewards) do
		local icon = xyd.getItemIcon({
			itemID = reward[1],
			num = reward[2],
			uiRoot = self.itemsGroup_,
			scale = Vector3(0.7, 0.7, 1)
		})
	end
end

function AcademyAssessmentDetailItem:onFight()
	local times = xyd.models.academyAssessment:getChallengeTimes()

	if times <= 0 then
		xyd.showToast(__("SCHOOL_PRACTICE_CHALLENGE_TICKETS_NOT_ENOUGH"))

		return
	end

	local fightParams = {
		mapType = xyd.MapType.ACADEMY_ASSESSMENT,
		battleID = self.id_,
		fortID = self.fortId_,
		battleType = xyd.BattleType.ACADEMY_ASSESSMENT,
		current_group = self.fortId_,
		stageId = self.id_
	}

	xyd.WindowManager:get():openWindow("battle_formation_window", fightParams)
end

function AcademyAssessmentDetailItem:onSweep()
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

local BaseWindow = import(".BaseWindow")
local AcademyAssessmentDetailWindow = class("AcademyAssessmentDetailWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local WindowTop = import("app.components.WindowTop")

function AcademyAssessmentDetailWindow:ctor(name, params)
	AcademyAssessmentDetailWindow.super.ctor(self, name, params)

	self.fortId_ = params.fort_id
end

function AcademyAssessmentDetailWindow:initWindow()
	AcademyAssessmentDetailWindow.super.initWindow(self)
	self:getUIComponents()

	local data = xyd.tables.academyAssessmentTable:getIdsByFort(self.fortId_)

	xyd.setUISpriteAsync(self.imgTitle_, nil, "academy_assessment_text_" .. tostring(self.fortId_) .. "_" .. tostring(xyd.Global.lang), function ()
		self.imgTitle_:MakePixelPerfect()
	end)
	xyd.setUITextureAsync(self.imgBg_, "Textures/academy_assessment_web/academy_assessment_" .. tostring(self.fortId_))
	xyd.setUISpriteAsync(self.imgTextBg_, nil, "academy_assessment_text_bg_" .. tostring(self.fortId_), function ()
	end)

	self.labelDesc_.text = __("ACADEMY_ASSESSMENT_TEXT0" .. tostring(self.fortId_))

	self:updateTickets()
	self:onTicketChange()
	self:initData()
	self:registerEvent()
	self:checkIsPlayGuide()
end

function AcademyAssessmentDetailWindow:getUIComponents()
	local winTrans = self.window_.transform
	local group1 = winTrans:NodeByName("group1").gameObject
	self.imgBg_ = group1:ComponentByName("imgBg_", typeof(UITexture))
	self.imgTitle_ = group1:ComponentByName("imgTitle_", typeof(UISprite))
	self.imgTextBg_ = group1:ComponentByName("imgTextBg_", typeof(UISprite))
	self.labelDesc_ = group1:ComponentByName("labelDesc_", typeof(UILabel))
	self.helpBtn = group1:ComponentByName("helpBtn", typeof(UISprite)).gameObject
	self.rankBtn = group1:ComponentByName("rankBtn", typeof(UISprite))
	local group2 = winTrans:NodeByName("group2").gameObject
	self.scroller_ = group2:ComponentByName("scroller_", typeof(UIScrollView))
	local wrapContent = group2:ComponentByName("scroller_/itemsGroup_", typeof(UIWrapContent))
	local item = group2:NodeByName("scroller_/academy_assessment_detail_item").gameObject
	self.wrapContent = FixedWrapContent.new(self.scroller_, wrapContent, item, AcademyAssessmentDetailItem, self)
end

function AcademyAssessmentDetailWindow:checkIsPlayGuide()
	local wnd = xyd.WindowManager:get():getWindow("academy_assessment_guide_window")

	if wnd then
		self:enableScroller(false)
	else
		self:enableScroller(true)
	end
end

function AcademyAssessmentDetailWindow:enableScroller(flag)
	if flag then
		self.scroller_.enabled = true
	else
		self.scroller_.enabled = false
	end
end

function AcademyAssessmentDetailWindow:updateTickets()
	if not self.windowTop then
		self.windowTop = WindowTop.new(self.window_, self.name_)
	end

	local items = {
		{
			ifItemChange = false,
			id = xyd.ItemID.ASSESSMENT_TICKET,
			callback = function ()
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
		},
		{
			ifItemChange = false,
			id = xyd.ItemID.ACCOMPLISH_TICKET,
			callback = function ()
				xyd.WindowManager:get():openWindow("academy_assessment_buy_window", {
					itemParams = {
						num = 1,
						itemID = xyd.ItemID.ACCOMPLISH_TICKET
					}
				})
			end
		}
	}

	self.windowTop:setItem(items)
end

function AcademyAssessmentDetailWindow:initData()
	local ids = xyd.tables.academyAssessmentTable:getIdsByFort(self.fortId_)
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
				print(i)
				print(ids[i])

				cnt = cnt + 1
			end
		end
	end

	self.collect = data

	self.wrapContent:setInfos(data)
end

function AcademyAssessmentDetailWindow:registerEvent()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACADEMY_ASSESSMENT_WINDOW_HELP"
		})
	end

	UIEventListener.Get(self.rankBtn.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("academy_assessment_rank_window", {
			fort_id = self.fortId_
		})
	end

	self.eventProxy_:addEventListener(xyd.event.SCHOOL_PRACTICE_FIGHT, handler(self, self.onFight))
	self.eventProxy_:addEventListener(xyd.event.SCHOOL_PRACTICE_BUY_TICKETS, handler(self, self.onTicketChange))
	self.eventProxy_:addEventListener(xyd.event.SCHOOL_PRACTICE_SWEEP, handler(self, self.onSweep))
end

function AcademyAssessmentDetailWindow:onTicketChange(event)
	if not event then
		local items = self.windowTop:getResItems()

		items[2]:setItemNum(xyd.models.academyAssessment:getSweepTimes())
		items[1]:setItemNum(xyd.models.academyAssessment:getChallengeTimes())

		return
	end

	local data = event.data
	local items = self.windowTop:getResItems()

	items[2]:setItemNum(data.map_info.sweep_times)
	items[1]:setItemNum(data.map_info.challenge_times)
end

function AcademyAssessmentDetailWindow:onFight(event)
	self:onTicketChange()

	if not event.data.is_win or event.data.is_win == 0 then
		return
	end

	local currentStage = xyd.models.academyAssessment:getCurrentStage(self.fortId_)
	local numTwoId = xyd.tables.academyAssessmentTable:getIdsByFort(self.fortId_)[2]

	if currentStage ~= numTwoId then
		table.remove(self.collect, 1)
	end

	local lastItem = self.collect[#self.collect]
	local lastID = lastItem.id
	local lastIndex = lastItem.index
	local ids = xyd.tables.academyAssessmentTable:getIdsByFort(self.fortId_)

	if lastID < ids[#ids] then
		table.insert(self.collect, {
			id = lastID + 1,
			index = lastIndex + 1,
			fort_id = self.fortId_
		})
	end

	self.wrapContent:setInfos(self.collect)
end

function AcademyAssessmentDetailWindow:onSweep(event)
	local data = event.data

	self:onTicketChange()
	xyd.alertItems(data.items)
end

function AcademyAssessmentDetailWindow:didClose(params, force)
	AcademyAssessmentDetailWindow.super.didClose(self)

	local wnd = xyd.WindowManager:get():getWindow("academy_assessment_window")

	if wnd then
		wnd:initData()
	end
end

return AcademyAssessmentDetailWindow
