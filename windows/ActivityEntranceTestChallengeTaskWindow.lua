local BaseWindow = import(".BaseWindow")
local ActivityEntranceTestChallengeTaskWindow = class("ActivityEntranceTestChallengeTaskWindow", BaseWindow)
local ActivityEntranceTestChallengeTaskItem1 = class("ActivityEntranceTestChallengeTaskItem1", import("app.common.ui.FixedWrapContentItem"))
local ActivityEntranceTestChallengeTaskItem2 = class("ActivityEntranceTestChallengeTaskItem2", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local ItemTable = xyd.tables.itemTable
local json = require("cjson")

function ActivityEntranceTestChallengeTaskWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	self.showGiftBag = params.showGiftBag
	self.showJumpBtn = params.showJumpBtn
end

function ActivityEntranceTestChallengeTaskWindow:getPrefabPath()
	return "Prefabs/Windows/activity_entrance_test_challenge_task_window"
end

function ActivityEntranceTestChallengeTaskWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:Register()
	self:initUIComponent()
	xyd.models.activity:reqActivityByID(xyd.ActivityID.ENTRANCE_TEST)
end

function ActivityEntranceTestChallengeTaskWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.titleLabel = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.helpBtn = self.groupAction:NodeByName("helpBtn").gameObject
	self.navGroup = self.groupAction:NodeByName("nav").gameObject
	self.content_1 = self.groupAction:NodeByName("content/content1Group").gameObject
	self.content_2 = self.groupAction:NodeByName("content/content2Group").gameObject
	self.charterGroup = self.groupAction:NodeByName("charterGroup").gameObject
	self.charterImg_ = self.charterGroup:ComponentByName("charterImg_", typeof(UISprite))
	self.charterLabel_ = self.charterGroup:ComponentByName("charterLabel_", typeof(UILabel))
	self.charterLine = self.charterGroup:ComponentByName("charterLine", typeof(UISprite))

	for i = 1, 3 do
		self["charterBtn" .. i] = self.charterGroup:NodeByName("charterBtn" .. i).gameObject
		self["charterBtnLabel" .. i] = self["charterBtn" .. i]:ComponentByName("charterBtnLabel_", typeof(UILabel))
	end

	self.taskContentGroup = self.content_1:NodeByName("taskContentGroup").gameObject
	self.scroller_task = self.taskContentGroup:NodeByName("scroller").gameObject
	self.scrollView_task = self.taskContentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup_task = self.scroller_task:NodeByName("itemGroup").gameObject
	self.challenge_task_item1 = self.scroller_task:NodeByName("challenge_task_item1").gameObject
	self.awardContentGroup = self.content_2:NodeByName("awardContentGroup").gameObject
	self.scroller_award = self.awardContentGroup:NodeByName("scroller").gameObject
	self.scrollView_award = self.awardContentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup_award = self.scroller_award:NodeByName("itemGroup").gameObject
	self.resNumLabel = self.awardContentGroup:ComponentByName("energyGroup/energyNum", typeof(UILabel))
	self.progressBar_award = self.scroller_award:NodeByName("progressBar").gameObject
	self.giftbagAwardLabel = self.awardContentGroup:ComponentByName("giftbagAwardLabel", typeof(UILabel))
	self.challenge_task_item2 = self.scroller_award:NodeByName("challenge_task_item2").gameObject
	self.giftBagBtnGroup = self.groupAction:NodeByName("giftBagBtnGroup").gameObject
	self.giftBagBtn = self.giftBagBtnGroup:NodeByName("giftBagBtn").gameObject
	self.giftBagLabel = self.giftBagBtnGroup:NodeByName("giftBagLabel").gameObject
	self.jumpGroup = self.groupAction:NodeByName("jumpGroup").gameObject
	self.goBtn = self.jumpGroup:NodeByName("goBtn").gameObject
	self.goBtnLabel = self.goBtn:ComponentByName("button_label", typeof(UILabel))
	self.arrowImg = self.jumpGroup:NodeByName("arrowImg").gameObject
	self.tabBar = CommonTabBar.new(self.navGroup, 2, function (index)
		self.tabIndex = index

		if index == 1 then
			self.content_1:SetActive(true)
			self.content_2:SetActive(false)
			self:initData()
		else
			self.content_1:SetActive(false)
			self.content_2:SetActive(true)
			self:initData()
		end
	end, nil, , 15)
end

function ActivityEntranceTestChallengeTaskWindow:initUIComponent()
	self.titleLabel.text = __("WARMUP_ARENA_TASK_INFO_1")
	self.charterLabel_.text = __("WARMUP_ARENA_TASK_INFO_2")
	self.tabBar.tabs[1].label.text = __("WARMUP_ARENA_TASK_INFO_3")
	self.tabBar.tabs[2].label.text = __("WARMUP_ARENA_TASK_INFO_7")
	self.giftbagAwardLabel.text = __("WARMUP_ARENA_TASK_INFO_4")

	if xyd.Global.lang == "de_de" then
		self.giftBagLabel:ComponentByName("", typeof(UILabel)).fontSize = 20
	end

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
		local descLabel = self.challenge_task_item1:ComponentByName("taskDesclabel", typeof(UILabel))
		local progress = self.challenge_task_item1:NodeByName("progressBar").gameObject
		descLabel.height = 60

		descLabel:Y(17)
		progress:Y(-28)
	end

	if xyd.Global.lang == "fr_fr" then
		self.charterLine:Y(23)
	end

	if self.showGiftBag == true and self.activityData:IfBuyGiftBag() == false then
		self.giftBagLabel:ComponentByName("", typeof(UILabel)).text = __("WARMUP_ARENA_TASK_INFO_6")

		self.giftBagBtnGroup:SetActive(false)
		self:waitForFrame(5, function ()
			self.giftBagBtnGroup:SetActive(true)

			self.giftBagEffect = xyd.Spine.new(self.giftBagBtnGroup)

			self.giftBagEffect:setInfo("fx_warmup_goto_gift", function ()
				self.giftBagEffect:play("entrance", 1, 1, function ()
					if self.giftBagLabel == nil then
						return
					end

					self.giftBagEffect:play("idle", 0, 1, nil, true)
					self.giftBagLabel:SetActive(true)
					xyd.getTweenAlpha(self.giftBagLabel:ComponentByName("", typeof(UILabel)), 1, 2)
				end, true)
			end)
		end)
	else
		self.giftBagBtnGroup:SetActive(false)
	end

	if self.showJumpBtn then
		self.jumpGroup:SetActive(true)

		self.goBtnLabel.text = __("ACTIVITY_WARMUP_PACK_TEXT07")

		self:playArrow()
	else
		self.jumpGroup:SetActive(false)
	end
end

function ActivityEntranceTestChallengeTaskWindow:playArrow()
	local action = self:getSequence()
	local transform = self.arrowImg.transform
	local position = transform.localPosition
	local x = position.x
	local y = position.y

	action:Append(transform:DOLocalMove(Vector3(x + 5, y, 0), 0.2))
	action:Append(transform:DOLocalMove(Vector3(x - 10, y, 0), 0.4))
	action:Append(transform:DOLocalMove(Vector3(x, y, 0), 0.2))
	action:SetLoops(-1)
end

function ActivityEntranceTestChallengeTaskWindow:initData()
	local mission_info = self.activityData.detail.mission_info
	local awarded = mission_info.awards
	local packAwarded = mission_info.ex_awards
	self.data1 = {}
	local ids = xyd.tables.activityWarmupArenaTaskTable:getIDs()

	for i = 1, #ids do
		local id = tonumber(ids[i])
		local type = xyd.tables.activityWarmupArenaTaskTable:getType(id)

		table.insert(self.data1, {
			id = tonumber(id),
			rank = xyd.tables.activityWarmupArenaTaskTable:getRank(id),
			type = type,
			needCompleteValue = xyd.tables.activityWarmupArenaTaskTable:getComplete(id),
			completeValue = mission_info.mission_values[id],
			desc = xyd.tables.activityWarmupArenaTaskTypeTextTable:getText(type),
			isCompleted = mission_info.mission_completes[id],
			energyValue = xyd.tables.activityWarmupArenaTaskTable:getEnergy(id)
		})
	end

	local function sort_func(a, b)
		return a.id < b.id
	end

	table.sort(self.data1, sort_func)

	if self.wrapContent1 == nil then
		local wrapContent = self.itemGroup_task:GetComponent(typeof(UIWrapContent))
		self.wrapContent1 = FixedWrapContent.new(self.scrollView_task, wrapContent, self.challenge_task_item1, ActivityEntranceTestChallengeTaskItem1, self)
	end

	self.wrapContent1:setInfos(self.data1, {})

	self.data2 = {}
	local ids = xyd.tables.activityWarmupArenaTaskAwardTable:getIDs()
	local maxEnergy = 0

	for i = 1, #ids do
		local id = tonumber(ids[i])
		local hasStar = xyd.tables.activityWarmupArenaTaskAwardTable:getPlotID(id) ~= 0

		if maxEnergy < xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id) then
			maxEnergy = xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id)
		end

		table.insert(self.data2, {
			id = tonumber(id),
			awards = xyd.tables.activityWarmupArenaTaskAwardTable:getAwards(id),
			packAwards = xyd.tables.activityWarmupArenaTaskAwardTable:getPackAwards(id),
			awarded = awarded[id],
			packAwarded = packAwarded[id],
			isCompleted = xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id) <= self.activityData:getTotalEnergy(),
			hasStar = hasStar,
			needEnergy = xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id)
		})
	end

	local function sort_func(a, b)
		return a.id < b.id
	end

	table.sort(self.data2, sort_func)

	if self.wrapContent2 == nil then
		local wrapContent = self.itemGroup_award:GetComponent(typeof(UIWrapContent))
		self.wrapContent2 = FixedWrapContent.new(self.scrollView_award, wrapContent, self.challenge_task_item2, ActivityEntranceTestChallengeTaskItem2, self)
	end

	self.wrapContent2:setInfos(self.data2, {})

	self.resNumLabel.text = self.activityData:getTotalEnergy() .. "/" .. maxEnergy
	local ids = xyd.tables.activityWarmupArenaTaskAwardTable:getIDs()
	local totalEnergy = self.activityData:getTotalEnergy()
	local baseProgrssValue = 0.03
	local value = 0

	for i = 1, #ids do
		local id = i
		local needEnergy = xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id)

		if i == 1 then
			if totalEnergy < needEnergy then
				value = baseProgrssValue * totalEnergy / needEnergy
			elseif needEnergy <= totalEnergy then
				value = baseProgrssValue
			end
		elseif totalEnergy < needEnergy then
			if xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id - 1) < totalEnergy then
				value = value + (totalEnergy - xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id - 1)) / (needEnergy - xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id - 1)) * (1 - baseProgrssValue) / (#ids - 1)
			end
		elseif needEnergy <= totalEnergy then
			value = value + (1 - baseProgrssValue) / (#ids - 1)
		end
	end

	self.progressBar_award:ComponentByName("", typeof(UIProgressBar)).value = math.min(value, 1)

	self:initListPositon()

	if self.activityData:checkRedMaskOfTaskAward() == true then
		self.navGroup:NodeByName("tab_2/redPoint").gameObject:SetActive(true)
	else
		self.navGroup:NodeByName("tab_2/redPoint").gameObject:SetActive(false)
	end

	self.activityData:updateCharterData()
	self:updateCharterBtns()
end

function ActivityEntranceTestChallengeTaskWindow:charterStarEffectBegin()
	if self.StarSequence then
		self.StarSequence:Pause()
		self.StarSequence:Kill(true)

		self.StarSequence = nil
		self.charterStar1:ComponentByName("star", typeof(UISprite)).color = Color.New(1, 1, 1, 1)
		self.charterStar2:ComponentByName("star", typeof(UISprite)).color = Color.New(1, 1, 1, 1)
		self.charterStar3:ComponentByName("star", typeof(UISprite)).color = Color.New(1, 1, 1, 1)
	end

	if self.StarSequence == nil then
		local state = self.activityData:getCharterState()

		if state == 0 then
			self.StarSequence = self:getSequence()

			self.StarSequence:Append(xyd.getTweenAlpha(self.charterStar1:ComponentByName("star", typeof(UISprite)), 0, 0.4166666666666667)):Join(xyd.getTweenAlpha(self.charterStar2:ComponentByName("star", typeof(UISprite)), 0, 0.4166666666666667)):Join(xyd.getTweenAlpha(self.charterStar3:ComponentByName("star", typeof(UISprite)), 0, 0.4166666666666667)):Append(xyd.getTweenAlpha(self.charterStar1:ComponentByName("star", typeof(UISprite)), 1, 0.4166666666666667)):Join(xyd.getTweenAlpha(self.charterStar2:ComponentByName("star", typeof(UISprite)), 1, 0.4166666666666667)):Join(xyd.getTweenAlpha(self.charterStar3:ComponentByName("star", typeof(UISprite)), 1, 0.4166666666666667))
			self.StarSequence:SetLoops(-1)
		end

		if state == 1 then
			self.StarSequence = self:getSequence()

			self.StarSequence:Append(xyd.getTweenAlpha(self.charterStar2:ComponentByName("star", typeof(UISprite)), 0, 0.4166666666666667)):Join(xyd.getTweenAlpha(self.charterStar3:ComponentByName("star", typeof(UISprite)), 0, 0.4166666666666667)):Append(xyd.getTweenAlpha(self.charterStar2:ComponentByName("star", typeof(UISprite)), 1, 0.4166666666666667)):Join(xyd.getTweenAlpha(self.charterStar3:ComponentByName("star", typeof(UISprite)), 1, 0.4166666666666667))
			self.StarSequence:SetLoops(-1)
		end

		if state == 2 or state == 3 then
			self.StarSequence = self:getSequence()

			self.StarSequence:Append(xyd.getTweenAlpha(self.charterStar3:ComponentByName("star", typeof(UISprite)), 0, 0.4166666666666667)):Append(xyd.getTweenAlpha(self.charterStar3:ComponentByName("star", typeof(UISprite)), 1, 0.4166666666666667))
			self.StarSequence:SetLoops(-1)
		end
	end
end

function ActivityEntranceTestChallengeTaskWindow:charterStarEffect()
end

function ActivityEntranceTestChallengeTaskWindow:charterStarEffectEnd()
	if self.StarSequence then
		self.StarSequence:Pause()
		self.StarSequence:Kill(true)

		self.charterStar1:ComponentByName("star", typeof(UISprite)).color = Color.New(1, 1, 1, 1)
		self.charterStar2:ComponentByName("star", typeof(UISprite)).color = Color.New(1, 1, 1, 1)
		self.charterStar3:ComponentByName("star", typeof(UISprite)).color = Color.New(1, 1, 1, 1)
	end
end

function ActivityEntranceTestChallengeTaskWindow:initListPositon()
	self:waitForFrame(5, function ()
		local moveIndex = 1
		local index = 1
		local flag = false
		local ids = xyd.tables.activityWarmupArenaTaskAwardTable:getIDs()

		for i = #ids, 1, -1 do
			local id = i

			if xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id) <= self.activityData:getTotalEnergy() and (self.activityData.detail.mission_info.awards[id] == 0 or self.activityData.detail.mission_info.ex_awards[id] == 0 and self.activityData:IfBuyGiftBag() == true) then
				moveIndex = id
				flag = true
			end
		end

		if flag == false then
			for i = #ids, 1, -1 do
				local id = i

				if self.activityData:getTotalEnergy() < xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id) then
					moveIndex = id
				end
			end
		end

		local sp = self.scrollView_award.gameObject:GetComponent(typeof(SpringPanel))
		local initPos = self.scrollView_award.transform.localPosition.y
		local dis = initPos + (moveIndex - 1) * 128

		sp.Begin(sp.gameObject, Vector3(0, dis, 0), 8)
	end)
end

function ActivityEntranceTestChallengeTaskWindow:Register()
	self.eventProxy_:addEventListener(xyd.event.WARMUP_GET_AWARD, handler(self, self.onGetAward))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, function (self, event)
		local activity_id = event.data.activity_id

		if activity_id ~= xyd.ActivityID.ENTRANCE_TEST then
			return
		end

		self:initData()
	end))

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "WARMUP_ARENA_TASK_HELP"
		})
	end

	UIEventListener.Get(self.goBtn).onClick = function ()
		self:close()

		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)

		xyd.WindowManager.get():openWindow("activity_entrance_test_window")
	end

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow("activity_entrance_test_challenge_task_window")
	end

	UIEventListener.Get(self.giftBagBtn).onClick = function ()
		local win = xyd.getWindow("activity_window")

		if win then
			win:close()
		end

		xyd.openWindow("activity_window", {
			activity_type = xyd.EventType.LIMIT,
			select = xyd.ActivityID.WARMUP_GIFT
		})
		self:close()
	end

	for i = 1, 3 do
		UIEventListener.Get(self["charterBtn" .. i]).onClick = function ()
			if self.activityData:getCharterState() < i and self.activityData:getCharterStar() < i then
				xyd.alert(xyd.AlertType.TIPS, __("WARMUP_ARENA_TASK_INFO_5"))
			elseif i <= self.activityData:getCharterStar() and self.activityData:getCharterState() < i and self.activityData:getCurrentPlotID() ~= nil then
				xyd.WindowManager.get():openWindow("story_window", {
					is_back = true,
					story_type = xyd.StoryType.OTHER,
					story_id = tonumber(self.activityData:getPlotID(i))
				})

				local stateinfo = {
					timeStamp = 0,
					stateNum = 0,
					stateNum = self.activityData:getCharterState() + 1,
					timeStamp = xyd.getServerTime()
				}

				xyd.db.misc:setValue({
					key = "entrance_test_charter_state",
					value = json.encode(stateinfo)
				})

				local win = xyd.WindowManager.get():getWindow("activity_entrance_test_window")

				if win then
					win:updateMissionRed()
				else
					self.activityData:checkRedMaskOfTask()
				end

				self:updateCharterBtns()

				if self.activityData:checkRedMaskOfTaskAward() == true then
					self.navGroup:NodeByName("tab_2/redPoint").gameObject:SetActive(true)
				else
					self.navGroup:NodeByName("tab_2/redPoint").gameObject:SetActive(false)
				end
			elseif i <= self.activityData:getCharterStar() and i <= self.activityData:getCharterState() and self.activityData:getCurrentPlotID() ~= nil then
				self:updateCharterBtns()
				xyd.WindowManager.get():openWindow("story_window", {
					is_back = true,
					story_type = xyd.StoryType.OTHER,
					story_id = tonumber(self.activityData:getPlotID(i))
				})
			end
		end
	end
end

function ActivityEntranceTestChallengeTaskWindow:updateCharterBtns()
	for i = 1, 3 do
		if self.activityData:getCharterState() < i and self.activityData:getCharterStar() < i then
			xyd.setUISpriteAsync(self["charterBtn" .. i]:ComponentByName("", typeof(UISprite)), nil, "entrance_test_icon_jq2")
			self["charterBtn" .. i]:ComponentByName("charterBtnLabel_", typeof(UILabel)):SetActive(false)
		elseif i <= self.activityData:getCharterStar() and self.activityData:getCharterState() < i and self.activityData:getCurrentPlotID() ~= nil then
			xyd.setUISpriteAsync(self["charterBtn" .. i]:ComponentByName("", typeof(UISprite)), nil, "entrance_test_icon_jq1")
			self["charterBtn" .. i]:ComponentByName("charterBtnLabel_", typeof(UILabel)):SetActive(true)
			self["charterBtn" .. i]:NodeByName("redPoint").gameObject:SetActive(true)
		else
			xyd.setUISpriteAsync(self["charterBtn" .. i]:ComponentByName("", typeof(UISprite)), nil, "entrance_test_icon_jq1")
			self["charterBtn" .. i]:ComponentByName("charterBtnLabel_", typeof(UILabel)):SetActive(true)
			self["charterBtn" .. i]:NodeByName("redPoint").gameObject:SetActive(false)
		end
	end
end

function ActivityEntranceTestChallengeTaskWindow:onGetAward(event)
	local data = xyd.decodeProtoBuf(event.data)
	local allItem = {}

	if data then
		local items = data.items
		local ids = xyd.tables.activityWarmupArenaTaskAwardTable:getIDs()

		for i = 1, #items do
			local item = items[i]
			local item_new = {
				item_id = item.item_id,
				item_num = item.item_num
			}

			table.insert(allItem, item_new)
		end

		xyd.models.itemFloatModel:pushNewItems(allItem)
		xyd.models.activity:reqActivityByID(xyd.ActivityID.ENTRANCE_TEST)
	end

	self.activityData.awarded = self.activityData.detail.mission_info.awards
	self.activityData.ex_awarded = self.activityData.detail.mission_info.ex_awards
end

function ActivityEntranceTestChallengeTaskWindow:GetAward()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	self.activityData.awarded = self.activityData.detail.mission_info.awards
	self.activityData.ex_awarded = self.activityData.detail.mission_info.ex_awards
	local msg = messages_pb:warmup_get_award_req()
	local ids = xyd.tables.activityWarmupArenaTaskAwardTable:getIDs()

	for i = 1, #ids do
		local id = tonumber(ids[i])

		if xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id) <= self.activityData:getTotalEnergy() and (self.activityData.detail.mission_info.awards[id] == 0 or self.activityData.detail.mission_info.ex_awards[id] == 0 and self.activityData:IfBuyGiftBag() == true) then
			table.insert(msg.table_ids, id)
		end
	end

	msg.activity_id = xyd.ActivityID.ENTRANCE_TEST

	xyd.Backend.get():request(xyd.mid.WARMUP_GET_AWARD, msg)
end

function ActivityEntranceTestChallengeTaskItem1:ctor(go, parent)
	ActivityEntranceTestChallengeTaskItem1.super.ctor(self, go, parent)

	self.parent = parent
end

function ActivityEntranceTestChallengeTaskItem1:initUI()
	local go = self.go
	self.challenge_task_item1 = self.go
	self.bg_ = self.challenge_task_item1:ComponentByName("bg_", typeof(UISprite))
	self.taskDesclabel = self.challenge_task_item1:ComponentByName("taskDesclabel", typeof(UILabel))
	self.energyGroup = self.challenge_task_item1:ComponentByName("energyGroup", typeof(UISprite))
	self.energyNum = self.energyGroup:ComponentByName("energyNum", typeof(UILabel))
	self.symbol = self.energyGroup:ComponentByName("symbol", typeof(UISprite))
	self.line = self.challenge_task_item1:ComponentByName("line", typeof(UISprite))
	self.gotoBtn = self.challenge_task_item1:NodeByName("gotoBtn").gameObject
	self.BtnLabel_ = self.gotoBtn:ComponentByName("charterBtnLabel_", typeof(UILabel))
	self.redPoint = self.gotoBtn:ComponentByName("redPoint", typeof(UISprite))
	self.progressBar = self.challenge_task_item1:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progress = self.progressBar:ComponentByName("progress", typeof(UISprite))
	self.progressLabel = self.progressBar:ComponentByName("progressLabel", typeof(UILabel))
	self.finishSymbol = self.challenge_task_item1:ComponentByName("finishSymbol", typeof(UISprite))

	self.go:SetActive(true)

	UIEventListener.Get(self.gotoBtn).onClick = function ()
		local rankString = ""

		if self.data.rank == 1 then
			rankString = "B"
		end

		if self.data.rank == 2 then
			rankString = "A"
		end

		if self.data.rank == 3 then
			rankString = "S"
		end

		if self.data.type == 4 or self.data.type == 5 then
			if not xyd.checkFunctionOpen(xyd.FunctionID.ENTRANCE_TEST, true) then
				xyd.alertYesNo(__("ENTRANCE_TEST_CANNOT_FIGHT"), function (yes_no)
					if yes_no then
						local wnd = xyd.WindowManager.get():getWindow("activity_entrance_test_window")

						if wnd then
							xyd.WindowManager.get():closeThenOpenWindow("activity_entrance_test_challenge_task_window", "activity_entrance_test_slot_window", {})
						else
							xyd.WindowManager.get():closeThenOpenWindow("activity_entrance_test_challenge_task_window", "activity_entrance_test_window", {}, function ()
								xyd.openWindow("activity_entrance_test_slot_window", {})
							end)
						end
					end
				end)
			else
				local wnd = xyd.WindowManager.get():getWindow("activity_entrance_test_window")

				if wnd then
					xyd.WindowManager.get():closeThenOpenWindow("activity_entrance_test_challenge_task_window", "activity_entrance_test_slot_window", {})
				else
					xyd.WindowManager.get():closeThenOpenWindow("activity_entrance_test_challenge_task_window", "activity_entrance_test_window", {}, function ()
						xyd.openWindow("activity_entrance_test_slot_window", {})
					end)
				end
			end
		elseif self.data.type == 1 or self.data.type == 2 then
			local wnd = xyd.WindowManager.get():getWindow("activity_entrance_test_window")

			if wnd then
				wnd:updateEffect()
				xyd.WindowManager.get():closeWindow("activity_entrance_test_challenge_task_window")
			else
				xyd.WindowManager.get():closeThenOpenWindow("activity_entrance_test_challenge_task_window", "activity_entrance_test_window", {
					fromTask = true
				})
			end
		elseif self.data.type == 3 then
			if not xyd.checkFunctionOpen(xyd.FunctionID.ENTRANCE_TEST, true) then
				xyd.alertYesNo(__("ENTRANCE_TEST_CANNOT_FIGHT"), function (yes_no)
					if yes_no then
						local wnd = xyd.WindowManager.get():getWindow("activity_entrance_test_window")

						if wnd then
							xyd.WindowManager.get():closeThenOpenWindow("activity_entrance_test_challenge_task_window", "activity_entrance_test_slot_window", {
								fromTask = true
							})
						else
							xyd.WindowManager.get():closeThenOpenWindow("activity_entrance_test_challenge_task_window", "activity_entrance_test_window", {}, function ()
								xyd.openWindow("activity_entrance_test_slot_window", {
									fromTask = true
								})
							end)
						end
					end
				end)
			else
				local wnd = xyd.WindowManager.get():getWindow("activity_entrance_test_window")

				if wnd then
					xyd.WindowManager.get():closeThenOpenWindow("activity_entrance_test_challenge_task_window", "activity_entrance_test_slot_window", {
						fromTask = true
					})
				else
					xyd.WindowManager.get():closeThenOpenWindow("activity_entrance_test_challenge_task_window", "activity_entrance_test_window", {}, function ()
						xyd.openWindow("activity_entrance_test_slot_window", {
							fromTask = true
						})
					end)
				end
			end
		else
			if self.data.type == 6 or self.data.type == 7 then
				local bossID = 1

				for i = 1, 3 do
					bossID = i
					local nowHarm = self.parent.activityData:getBossHarm(bossID)
					local totalHarm = xyd.tables.activityWarmupArenaBossTable:getBossScore(bossID)

					if nowHarm < totalHarm then
						break
					end
				end

				local wnd = xyd.WindowManager.get():getWindow("activity_entrance_test_window")

				if wnd then
					xyd.WindowManager.get():closeThenOpenWindow("activity_entrance_test_challenge_task_window", "activity_entrance_test_pve_window", {
						testType = bossID
					})
				else
					xyd.WindowManager.get():closeThenOpenWindow("activity_entrance_test_challenge_task_window", "activity_entrance_test_window", {}, function ()
						xyd.openWindow("activity_entrance_test_pve_window", {
							testType = bossID
						})
					end)
				end

				return
			end

			if self.data.type == 8 or self.data.type == 9 then
				if self.parent.activityData:isCanGuess() then
					local wnd = xyd.WindowManager.get():getWindow("activity_entrance_test_window")

					if wnd then
						xyd.WindowManager.get():closeThenOpenWindow("activity_entrance_test_challenge_task_window", "activity_entrance_test_show_window", {})
					else
						xyd.WindowManager.get():closeThenOpenWindow("activity_entrance_test_challenge_task_window", "activity_entrance_test_window", {}, function ()
							xyd.openWindow("activity_entrance_test_show_window", {})
						end)
					end
				else
					xyd.alertTips(__("ACTIVITY_NEW_WARMUP_TEXT33"))
				end
			end
		end
	end
end

function ActivityEntranceTestChallengeTaskItem1:updateInfo()
	self.id = self.data.id
	self.rank = self.data.rank
	self.type = self.data.type
	self.needCompleteValue = self.data.needCompleteValue
	self.completeValue = self.data.completeValue
	self.desc = self.data.desc
	self.energyValue = self.data.energyValue
	self.isCompleted = self.data.isCompleted
	local parters = xyd.tables.miscTable:split2num("activity_warmup_arena_partners", "value", "|")
	local text1 = ""
	local rankString = ""

	if #parters == 1 then
		text1 = xyd.tables.partnerTable:getName(parters[1])
	end

	if #parters == 2 then
		text1 = __("A_OR_B", xyd.tables.partnerTable:getName(parters[1]), xyd.tables.partnerTable:getName(parters[2]))
	end

	if self.rank == 1 then
		rankString = "B"
	end

	if self.rank == 2 then
		rankString = "A"
	end

	if self.rank == 3 then
		rankString = "S"
	end

	if self.type == 1 or self.type == 2 then
		self.taskDesclabel.text = xyd.stringFormat(self.desc, rankString, text1, self.needCompleteValue, self.completeValue)
	elseif self.type == 3 then
		self.taskDesclabel.text = xyd.stringFormat(self.desc, text1)
	else
		self.taskDesclabel.text = xyd.stringFormat(self.desc, self.needCompleteValue)
	end

	self.progressBar.value = math.min(self.completeValue, self.needCompleteValue) / self.needCompleteValue
	self.progressLabel.text = math.min(self.completeValue, self.needCompleteValue) .. "/" .. self.needCompleteValue
	self.energyNum.text = self.energyValue
	self.BtnLabel_.text = __("ACTIVITY_RETURN_RESIDENT_POP_GO")

	xyd.setUISpriteAsync(self.finishSymbol, nil, "mission_awarded_" .. tostring(xyd.Global.lang))

	if self.isCompleted == 1 then
		self.energyNum.gameObject:SetActive(false)
		self.symbol.gameObject:SetActive(true)
		self.gotoBtn:SetActive(false)
		self.finishSymbol.gameObject:SetActive(true)
	else
		self.energyNum.gameObject:SetActive(true)
		self.symbol.gameObject:SetActive(false)
		self.gotoBtn:SetActive(true)
		self.finishSymbol.gameObject:SetActive(false)
	end
end

function ActivityEntranceTestChallengeTaskItem2:ctor(go, parent)
	ActivityEntranceTestChallengeTaskItem2.super.ctor(self, go, parent)

	self.baseIcons = nil
	self.extraIcons = nil
	self.starIcon = nil
end

function ActivityEntranceTestChallengeTaskItem2:initUI()
	local go = self.go
	self.baseAwardItemGroup = self.go:NodeByName("baseAwardItemGroup").gameObject
	self.baseAwardItemGroup_layout = self.go:ComponentByName("baseAwardItemGroup", typeof(UILayout))
	self.baseAwardClickArea = self.go:NodeByName("baseAwardClickArea").gameObject
	self.star = self.go:NodeByName("star").gameObject
	self.line = self.go:ComponentByName("line", typeof(UISprite))
	self.luckyBagAwardItemGroup = self.go:NodeByName("luckyBagAwardItemGroup").gameObject
	self.luckyBagAwardItemGroup_layout = self.go:ComponentByName("luckyBagAwardItemGroup", typeof(UILayout))
	self.luckyBagAwardClickArea = self.go:NodeByName("luckyBagAwardClickArea").gameObject
	self.energyGroup = self.go:NodeByName("energyGroup").gameObject
	self.energyNum = self.energyGroup:ComponentByName("energyNum", typeof(UILabel))
	self.symbol = self.energyGroup:ComponentByName("symbol", typeof(UISprite))

	self.go:SetActive(true)
	self.star:SetActive(true)
end

function ActivityEntranceTestChallengeTaskItem2:updateInfo()
	self.id = self.data.id
	self.awards = self.data.awards
	self.packAwards = self.data.packAwards
	self.isCompleted = self.data.isCompleted
	self.awarded = self.data.awarded
	self.packAwarded = self.data.packAwarded
	self.hasStar = self.data.hasStar
	self.needEnergy = self.data.needEnergy
	self.energyNum.text = self.needEnergy

	if self.needEnergy <= self.parent.activityData:getTotalEnergy() then
		self.symbol.gameObject:SetActive(true)
		self.energyNum.gameObject:SetActive(false)
	else
		self.symbol.gameObject:SetActive(false)
		self.energyNum.gameObject:SetActive(true)
	end

	if self.baseIcons == nil then
		self.baseIcons = {}

		for i = 1, 4 do
			local type = xyd.ItemIconType.ITEM_ICON

			if i > 2 then
				type = xyd.ItemIconType.HERO_ICON
			end

			local icon = xyd.getItemIcon({
				scale = 0.7037037037037037,
				uiRoot = self.baseAwardItemGroup,
				dragScrollView = self.parent.scrollView_award
			}, type)

			table.insert(self.baseIcons, icon)
		end
	end

	for i = 1, #self.baseIcons do
		self.baseIcons[i].go:SetActive(false)
	end

	for i = 1, #self.awards do
		local type = xyd.tables.itemTable:getType(self.awards[i][1])
		local icon = self.baseIcons[i]

		if type == xyd.ItemType.HERO_DEBRIS or type == xyd.ItemType.HERO or type == xyd.ItemType.HERO_RANDOM_DEBRIS or type == xyd.ItemType.SKIN then
			icon = self.baseIcons[i + 2]
		end

		icon.go:SetActive(true)

		local data = self.awards[i]
		local params = {
			show_has_num = true,
			hideText = false,
			scale = 0.7037037037037037,
			itemID = data[1],
			num = data[2],
			dragScrollView = self.parent.scrollView_award
		}

		icon:setEffectState(false)

		if data[1] == 264 or self.isCompleted == true and self.awarded == 0 then
			params.effect = "bp_available"
		end

		icon:setInfo(params)

		if self.awarded == 1 then
			icon:setMask(false)
			icon:setLock(false)
			icon:setChoose(true)
		else
			if self.isCompleted == false then
				icon:setLock(false)
				icon:setChoose(false)
				icon:setMask(true)

				if data[1] == 264 then
					-- Nothing
				end
			end

			if self.isCompleted == true then
				icon:setMask(false)
				icon:setLock(false)
				icon:setChoose(false)
			end
		end
	end

	self.baseAwardItemGroup:GetComponent(typeof(UILayout)):Reposition()

	if self.hasStar == false then
		self.star:SetActive(false)
	else
		self.star:SetActive(true)

		if self.isCompleted == true then
			self.star:NodeByName("unlock").gameObject:SetActive(true)
			self.star:NodeByName("lock").gameObject:SetActive(false)
		else
			self.star:NodeByName("unlock").gameObject:SetActive(false)
			self.star:NodeByName("lock").gameObject:SetActive(true)
		end
	end

	if self.extraIcons == nil then
		self.extraIcons = {}

		for i = 1, 4 do
			local type = xyd.ItemIconType.ITEM_ICON

			if i > 2 then
				type = xyd.ItemIconType.HERO_ICON
			end

			local icon = xyd.getItemIcon({
				scale = 0.7037037037037037,
				uiRoot = self.luckyBagAwardItemGroup,
				dragScrollView = self.parent.scrollView_award
			}, type)

			table.insert(self.extraIcons, icon)
		end
	end

	for i = 1, #self.extraIcons do
		self.extraIcons[i].go:SetActive(false)
	end

	for i = 1, #self.packAwards do
		local type = xyd.tables.itemTable:getType(self.packAwards[i][1])
		local icon = self.extraIcons[i]

		if type == xyd.ItemType.HERO_DEBRIS or type == xyd.ItemType.HERO or type == xyd.ItemType.HERO_RANDOM_DEBRIS or type == xyd.ItemType.SKIN then
			icon = self.extraIcons[i + 2]
		end

		icon.go:SetActive(true)

		local data = self.packAwards[i]
		local params = {
			show_has_num = true,
			hideText = false,
			scale = 0.7037037037037037,
			itemID = data[1],
			num = data[2],
			dragScrollView = self.parent.scrollView_award
		}

		icon:setEffectState(false)

		if data[1] == 264 or self.isCompleted == true and self.packAwarded == 0 and self.parent.activityData:IfBuyGiftBag() == true then
			params.effect = "bp_available"
		end

		icon:setInfo(params)

		if self.parent.activityData:IfBuyGiftBag() == false then
			icon:setMask(false)
			icon:setChoose(false)
			icon:setLock(true)
		elseif self.packAwarded == 1 then
			icon:setMask(false)
			icon:setLock(false)
			icon:setChoose(true)
		else
			if self.isCompleted == false then
				if data[1] == 264 then
					-- Nothing
				end

				icon:setLock(false)
				icon:setChoose(false)
				icon:setMask(true)
			end

			if self.isCompleted == true then
				icon:setMask(false)
				icon:setLock(false)
				icon:setChoose(false)
			end
		end
	end

	self.luckyBagAwardItemGroup:GetComponent(typeof(UILayout)):Reposition()

	if self.awarded == 0 and self.isCompleted == true then
		self.baseAwardClickArea:SetActive(true)

		UIEventListener.Get(self.baseAwardClickArea).onClick = function ()
			if self.awarded == 0 and self.isCompleted == true then
				self:onTouchAward()
			end
		end
	else
		self.baseAwardClickArea:SetActive(false)
	end

	if self.packAwarded == 0 and self.parent.activityData:IfBuyGiftBag() == true and self.isCompleted == true then
		self.luckyBagAwardClickArea:SetActive(true)

		UIEventListener.Get(self.luckyBagAwardClickArea).onClick = function ()
			if self.packAwarded == 0 and self.parent.activityData:IfBuyGiftBag() == true and self.isCompleted == true then
				self:onTouchAward()
			end
		end
	else
		self.luckyBagAwardClickArea:SetActive(false)
	end
end

function ActivityEntranceTestChallengeTaskItem2:onTouchAward(indexValue)
	self.parent:GetAward()
end

return ActivityEntranceTestChallengeTaskWindow
