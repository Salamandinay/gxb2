local BaseWindow = import(".BaseWindow")
local StoryListWindow = class("StoryListWindow", BaseWindow)
local StoryListWindowBigItem = class("StoryListWindow", import("app.components.CopyComponent"))
local StoryListWindowItem = class("StoryListWindowItem", import("app.common.ui.FixedWrapContentItem"))
local HeroListWindowItem = class("HeroListWindowItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ResItem = import("app.components.ResItem")
local WindowTop = import("app.components.WindowTop")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local MainPlotEpisodeTable = xyd.tables.mainPlotEpisodeTable
local MainPlotFortTable = xyd.tables.mainPlotFortTable
local MainPlotFortTextTable = xyd.tables.mainPlotFortTextTable
local MainPlotListTable = xyd.tables.mainPlotListTable
local MainPlotListTextTable = xyd.tables.mainPlotListTextTable
local ActivityPlotFortTable = xyd.tables.activityPlotFortTable
local ActivityPlotFortTextTable = xyd.tables.activityPlotFortTextTable
local ActivityPlotListTable = xyd.tables.activityPlotListTable
local ActivityPlotListTextTable = xyd.tables.activityPlotListTextTable
local StoryListModel = xyd.models.storyListModel
local TYPE1 = {
	HERO = 3,
	ACTIVITY = 2,
	STORY = 1
}
local TYPE2 = {
	LIST = 3,
	EPISODE = 1,
	FORT = 2
}

function StoryListWindow:ctor(name, params)
	StoryListWindow.super.ctor(self, name, params)

	self.episodeItems = {}
	self.main_fort = {}
	self.main_list = {}
	self.activity_fort = {}
	self.activity_list = {}
	self.cur_id = 0
end

function StoryListWindow:initWindow()
	StoryListWindow.super.initWindow(self)
	self:getUIComponent()
	self:initTopGroup()
	self:initNav()
	self:register()
	self:initHeroList()
	StoryListModel:reqPlotInfo()
end

function StoryListWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainTrans = winTrans:NodeByName("main")
	self.topGroup = mainTrans:NodeByName("topGroup").gameObject
	local ticketResItemNode = mainTrans:NodeByName("ticketResItem").gameObject
	self.ticketResItem = ResItem.new(ticketResItemNode)
	local midTrans = mainTrans:NodeByName("mid")
	self.scrollviewMain_ = midTrans:ComponentByName("scrollviewMain", typeof(UIScrollView))
	self.wrapContentMain_ = midTrans:ComponentByName("scrollviewMain/grid", typeof(UIWrapContent))
	self.layoutMain_ = midTrans:ComponentByName("scrollviewMain/layout", typeof(UILayout))
	self.scrollviewHero_ = midTrans:ComponentByName("scrollviewHero", typeof(UIScrollView))
	self.wrapContentHero_ = midTrans:ComponentByName("scrollviewHero/grid", typeof(UIWrapContent))
	self.BigListItemRoot_ = midTrans:NodeByName("stroyListBigItem").gameObject
	self.ListItemRoot_ = midTrans:NodeByName("stroyListItem").gameObject
	self.HeroItemRoot_ = midTrans:NodeByName("heroListItem").gameObject
	self.groupNone_ = mainTrans:NodeByName("groupNone").gameObject
	self.nav_ = mainTrans:NodeByName("top/nav").gameObject
	self.mask_ = winTrans:NodeByName("mask_").gameObject
end

function StoryListWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.topGroup, self.name_, nil, , function ()
		local sequence = self:getSequence()

		if self.cur_id == 1 and self.layer_type == TYPE2.FORT then
			self.layoutMain_:X(-720)
			sequence:Append(self.wrapContentMain_.transform:DOLocalMoveX(-900, 0.25))
			sequence:AppendCallback(function ()
				self.wrapContentMain_:SetActive(false)
				self.layoutMain_:SetActive(true)
				self.scrollviewMain_:ResetPosition()
				sequence:Append(self.layoutMain_.transform:DOLocalMoveX(0, 0.25))

				self.layer_type = TYPE2.EPISODE

				self:waitForTime(0.25, function ()
					xyd.setTouchEnable(self.windowTop.closeBtn.gameObject, true)
				end)
			end)
		else
			if self.layer_type == TYPE2.LIST then
				local list = self.main_fort[self.lastEpisodeId]

				if self.cur_id == 2 then
					list = self.activity_fort
				end

				local sequence = self:getSequence()

				sequence:Append(self.wrapContentMain_.transform:DOLocalMoveX(-900, 0.25))
				sequence:AppendCallback(function ()
					self.wrapContentMain_:X(-720)
					self.wrapMain_:setInfos(list, {})
					self.wrapMain_:resetPosition()
					sequence:Append(self.wrapContentMain_.transform:DOLocalMoveX(0, 0.25))

					self.layer_type = TYPE2.FORT
					self.lastEpisodeId = nil
					self.nowFortId = nil

					self:waitForTime(0.25, function ()
						xyd.setTouchEnable(self.windowTop.closeBtn.gameObject, true)
					end)
				end)

				return
			end

			xyd.WindowManager:get():closeWindow(self.name_)
		end
	end)
	self.labelTime = self.ticketResItem:getTimeLabel()

	self.ticketResItem:setInfo({
		tableId = xyd.ItemID.STORY_UNLOCK_ICON
	})
	self.ticketResItem:hidePlus()
end

function StoryListWindow:initNav()
	self.tab = CommonTabBar.new(self.nav_, 3, function (index)
		self:updateLayout(index)
	end)

	self.tab:setTexts({
		__("STORY_LIST_BTN_TEXT_1"),
		__("STORY_LIST_BTN_TEXT_2"),
		__("STORY_LIST_BTN_TEXT_3")
	})
end

function StoryListWindow:register()
	self.eventProxy_:addEventListener(xyd.event.PARTNER_CHALLENGE_GET_INFO, handler(self, self.onGetHeroInfo))
	self.eventProxy_:addEventListener(xyd.event.GET_PLOT_INFO, handler(self, self.onGetPlotInfo))
	self.eventProxy_:addEventListener(xyd.event.UNLOCK_MAIN_PLOT, self.onUnlockMain, self)
	self.eventProxy_:addEventListener(xyd.event.UNLOCK_ACTIVITY_PLOT, self.onUnlockActivity, self)
end

function StoryListWindow:onGetPlotInfo(event)
	self:updateResItem()
	self:buildStory()
	self:buildActivity()
	self:updateRedMarkState()
end

function StoryListWindow:onUnlockMain()
	self:updateResItem()
	self:buildStory()
	self:updateRedMarkState()

	self.layer_type = TYPE2.LIST
	local list = self.main_list[self.nowFortId]

	self.wrapMain_:setInfos(list, {})
end

function StoryListWindow:onUnlockActivity()
	self:updateResItem()
	self:buildActivity()
	self:updateRedMarkState()

	self.layer_type = TYPE2.LIST
	local list = self.activity_list[self.nowFortId]

	self.wrapMain_:setInfos(list, {})
end

function StoryListWindow:updateResItem()
	local limit = xyd.tables.miscTable:getNumber("plot_unlock_item_limit", "value")
	local recover = xyd.tables.miscTable:split2num("plot_unlock_item_recover", "value", "#")
	local keys = StoryListModel:getKeys()
	local last_update_time = StoryListModel:getLastUpdateTime()

	self.ticketResItem:setItemNum(keys, limit)

	if keys < limit then
		self.labelTime:setCountDownTime(recover[1] - (xyd.getServerTime() - last_update_time) % recover[1])
		self.ticketResItem:setTimeLabel(true)
	else
		self.ticketResItem:setTimeLabel(false)
	end
end

function StoryListWindow:buildStory()
	self.main_fort = {}
	self.main_list = {}
	local episodeIDs = MainPlotEpisodeTable:getIDs()

	for i = 1, #episodeIDs do
		local episodeId = episodeIDs[i]

		if not self.episodeItems[i] then
			local tempGo = NGUITools.AddChild(self.layoutMain_.gameObject, self.BigListItemRoot_)
			local item = StoryListWindowBigItem.new(tempGo, episodeId, self)

			table.insert(self.episodeItems, item)
		end

		if not StoryListModel:getUnlockStateByEpisodeID(i) then
			self.episodeItems[i]:SetActive(false)
		end

		if StoryListModel:checkEpisodeIsClear(i) then
			self.episodeItems[i].clearIcon:SetActive(true)
		end

		self.main_fort[episodeId] = {}
		local fortIDs = MainPlotFortTable:getIDsByEpisodeID(episodeId)

		for j = 1, #fortIDs do
			local fortId = fortIDs[j]

			table.insert(self.main_fort[episodeId], {
				type1 = TYPE1.STORY,
				type2 = TYPE2.FORT,
				fortId = fortId,
				imgSrc = MainPlotFortTable:getImg(fortId),
				title = MainPlotFortTextTable:getName(fortId),
				desc = MainPlotFortTextTable:getDesc(fortId),
				unlockInfos = self.unlockInfos
			})

			self.main_list[fortId] = {}
			local listIDs = MainPlotListTable:getIDsByFortID(fortId)

			for k = 1, #listIDs do
				local listId = listIDs[k]

				table.insert(self.main_list[fortId], {
					type1 = TYPE1.STORY,
					type2 = TYPE2.LIST,
					listId = listId,
					imgSrc = MainPlotListTable:getChapterIcon(listId),
					title = MainPlotListTextTable:getName(listId),
					desc = MainPlotListTextTable:getDesc(listId),
					unlockInfos = self.unlockInfos
				})
			end

			table.sort(self.main_list[fortId], function (a, b)
				return a.listId < b.listId
			end)
		end

		table.sort(self.main_fort[episodeId], function (a, b)
			return a.fortId < b.fortId
		end)
	end

	self.layer_type = TYPE2.EPISODE

	self.layoutMain_:Reposition()
	self.scrollviewMain_:ResetPosition()

	if not self.wrapMain_ then
		self.wrapMain_ = FixedWrapContent.new(self.scrollviewMain_, self.wrapContentMain_, self.ListItemRoot_, StoryListWindowItem, self)
	end
end

function StoryListWindow:buildActivity()
	self.activity_fort = {}
	self.activity_list = {}
	local fortIDs = ActivityPlotFortTable:getIds()

	for i = 1, #fortIDs do
		local fortId = fortIDs[i]
		local listIDs = ActivityPlotListTable:getIdsByFort(fortId)

		if listIDs and listIDs[1] and ActivityPlotListTable:checkIsShow(listIDs[1]) then
			table.insert(self.activity_fort, {
				type1 = TYPE1.ACTIVITY,
				type2 = TYPE2.FORT,
				fortId = fortId,
				imgSrc = ActivityPlotFortTable:getFortImg(fortId),
				title = ActivityPlotFortTextTable:getName(fortId),
				desc = ActivityPlotFortTextTable:getDesc(fortId),
				unlockInfos = self.unlockInfos
			})

			self.activity_list[fortId] = {}

			for j = 1, #listIDs do
				local listId = listIDs[j]

				table.insert(self.activity_list[fortId], {
					type1 = TYPE1.ACTIVITY,
					type2 = TYPE2.LIST,
					listId = listId,
					imgSrc = ActivityPlotListTable:getChapterIcon(listId),
					title = ActivityPlotListTextTable:getName(listId),
					desc = ActivityPlotListTextTable:getDesc(listId),
					unlockInfos = self.unlockInfos
				})
			end

			table.sort(self.activity_list[fortId], function (a, b)
				return a.listId < b.listId
			end)
		end
	end

	table.sort(self.activity_fort, function (a, b)
		return a.fortId < b.fortId
	end)
end

function StoryListWindow:initHeroList()
	local HeroChallenge = xyd.models.heroChallenge
	local list = HeroChallenge:getMapList()
	local list2 = HeroChallenge:getChessMapList()

	if not list or #list <= 0 or not list2 or not next(list2) then
		if not xyd.checkFunctionOpen(xyd.FunctionID.HERO_CHALLENGE, true) then
			self:fakeBuildHeroList()
		else
			HeroChallenge:reqHeroChallengeInfo()
			HeroChallenge:reqHeroChallengeChessInfo()
		end
	else
		self:buildHeroList(list)
	end
end

function StoryListWindow:onGetHeroInfo(event)
	local list = event.data.map_list

	self:buildHeroList(list)
end

function StoryListWindow:fakeBuildHeroList()
	self.other_source = {}
	local PartnerChallengeTable = xyd.tables.partnerChallengeTable
	local PartnerChallengeChessTable = xyd.tables.partnerChallengeChessTable
	local PartnerChallengeChessTextTable = xyd.tables.partnerChallengeChessTextTable
	local fortIdsList = PartnerChallengeTable:getFortIds()
	local fortIdsChess = PartnerChallengeChessTable:getFortIds()
	local chessNum = 0

	for fortId, ids in pairs(fortIdsChess) do
		chessNum = chessNum + 1
	end

	for fortId, ids in pairs(fortIdsChess) do
		local first_stage_id = ids[1]
		local params = {
			maxStage = 0,
			fortId = fortId,
			maxFortId = #fortIdsList - 1 + chessNum,
			fortImgSrc = PartnerChallengeChessTable:getFortImg(fortId),
			localFortNameText = PartnerChallengeChessTable:fortName(first_stage_id)
		}

		table.insert(self.other_source, params)
	end

	for id = 1, #fortIdsList do
		local first_stage_id = fortIdsList[id][1]
		local params = {
			maxStage = 0,
			fortId = id,
			maxFortId = #fortIdsList - 1 + chessNum,
			fortImgSrc = PartnerChallengeTable:getFortImg(id)
		}

		table.insert(self.other_source, params)
	end
end

function StoryListWindow:buildHeroList(list)
	self.other_source = {}
	local PartnerChallengeTable = xyd.tables.partnerChallengeTable
	local PartnerChallengeChessTable = xyd.tables.partnerChallengeChessTable
	local PartnerChallengeChessTextTable = xyd.tables.partnerChallengeChessTextTable
	local fortIdsList = xyd.tables.partnerChallengeTable:getFortIds()
	local fortIdsChess = PartnerChallengeChessTable:getFortIds()
	local chessNum = 0

	for fortId, ids in pairs(fortIdsChess) do
		chessNum = chessNum + 1
	end

	for fortId, ids in pairs(fortIdsChess) do
		local first_stage_id = ids[1]
		local fortInfo = xyd.models.heroChallenge:getFortInfoByFortID(fortId)
		local params = {
			fortId = fortId,
			maxFortId = #fortIdsList - 1 + chessNum,
			maxStage = fortInfo.base_info.fight_max_stage,
			fortImgSrc = PartnerChallengeChessTable:getFortImg(fortId),
			localFortNameText = PartnerChallengeChessTable:fortName(first_stage_id)
		}

		table.insert(self.other_source, params)
	end

	for idx = 1, #fortIdsList do
		local first_stage_id = list[idx][1]
		local params = {
			fortId = idx,
			maxFortId = #fortIdsList - 1 + chessNum,
			maxStage = list[idx].base_info.fight_max_stage,
			fortImgSrc = PartnerChallengeTable:getFortImg(idx)
		}

		table.insert(self.other_source, params)
	end
end

function StoryListWindow:updateLayout(id)
	if self.cur_id == id then
		return
	end

	xyd.SoundManager.get():playSound(xyd.SoundID.TAB)

	if id == 1 then
		self.layoutMain_:X(0)
		self.scrollviewMain_:SetActive(true)
		self.wrapContentMain_:SetActive(false)
		self.layoutMain_:SetActive(true)
		self.scrollviewHero_:SetActive(false)
		self.layoutMain_:Reposition()
		self.scrollviewMain_:ResetPosition()

		self.layer_type = TYPE2.EPISODE
	elseif id == 2 then
		self.wrapContentMain_:X(0)
		self.scrollviewMain_:SetActive(true)
		self.wrapContentMain_:SetActive(true)
		self.layoutMain_:SetActive(false)
		self.scrollviewHero_:SetActive(false)
		self.wrapMain_:setInfos(self.activity_fort, {})
		self.wrapMain_:resetPosition()

		self.layer_type = TYPE2.FORT
	elseif id == 3 then
		self.scrollviewMain_:SetActive(false)
		self.scrollviewHero_:SetActive(true)

		if not self.wrapHero_ then
			self.wrapHero_ = FixedWrapContent.new(self.scrollviewHero_, self.wrapContentHero_, self.HeroItemRoot_, HeroListWindowItem, self)
		end

		self.wrapHero_:setInfos(self.other_source, {})
		self.wrapHero_:resetPosition()

		self.layer_type = TYPE2.FORT
	end

	self.cur_id = id
end

function StoryListWindow:onEpisodeClick(id)
	local sequence = self:getSequence()

	self.wrapContentMain_:X(-720)
	sequence:Append(self.layoutMain_.transform:DOLocalMoveX(-900, 0.25))
	sequence:AppendCallback(function ()
		self.layoutMain_:SetActive(false)
		self.wrapContentMain_:SetActive(true)
		self.wrapMain_:setInfos(self.main_fort[id], {})
		self.wrapMain_:resetPosition()
		sequence:Append(self.wrapContentMain_.transform:DOLocalMoveX(0, 0.25))

		self.layer_type = TYPE2.FORT
	end)
end

function StoryListWindow:onClickFortItem(fortId, type1)
	local list = self.main_list[fortId]

	if type1 == TYPE1.ACTIVITY then
		list = self.activity_list[fortId]
	end

	local sequence = self:getSequence()

	sequence:Append(self.wrapContentMain_.transform:DOLocalMoveX(-900, 0.25))
	sequence:AppendCallback(function ()
		self.wrapContentMain_:X(-720)
		self.wrapMain_:setInfos(list, {})
		self.wrapMain_:resetPosition()
		sequence:Append(self.wrapContentMain_.transform:DOLocalMoveX(0, 0.25))

		self.layer_type = TYPE2.LIST

		if type1 == TYPE1.STORY then
			self.lastEpisodeId = MainPlotFortTable:getEpisodeID(fortId)
		end

		self.nowFortId = fortId
	end)
end

function StoryListWindow:onClickListItem(listId, type1, lock_state)
	if lock_state == "will_unlock" then
		xyd.WindowManager.get():openWindow("story_list_unlock_window", {
			isActivity = type1 == TYPE1.ACTIVITY,
			listId = listId
		})

		return
	end

	local story_type = xyd.tables.mainPlotListTable:getStroyType(listId)
	local story_list = xyd.tables.mainPlotListTable:getMemoryPlotId(listId)

	if type1 == TYPE1.ACTIVITY then
		story_type = xyd.tables.activityPlotListTable:getStroyType(listId)
		story_list = xyd.tables.activityPlotListTable:getMemoryPlotId(listId)
	end

	local i = 1

	while i < #story_list do
		if story_list[i] == 0 then
			table.remove(story_list, i)
		else
			i = i + 1
		end
	end

	xyd.WindowManager.get():openWindow("story_window", {
		story_type = story_type,
		story_list = story_list
	})
end

function StoryListWindow:playOpenAnimation(callback)
	StoryListWindow.super.playOpenAnimation(self, function ()
		local mainGroup = self.window_.transform:NodeByName("main").gameObject
		local sequence = self:getSequence()

		mainGroup:X(-self.window_:GetComponent(typeof(UIPanel)).width)
		sequence:Append(mainGroup.transform:DOLocalMoveX(50, 0.3))
		sequence:Append(mainGroup.transform:DOLocalMoveX(0, 0.27))
		sequence:AppendCallback(function ()
			self:setWndComplete()

			self.isAnimationCompleted = true
		end)

		if callback then
			callback()
		end
	end)
end

function StoryListWindow:updateRedMarkState()
	local flag = false
	local fortIDs = ActivityPlotFortTable:getIds()

	for i = 1, #fortIDs do
		local fortId = fortIDs[i]

		if StoryListModel:getRedMarkStateByFortID(fortId, true) then
			flag = true

			break
		end
	end

	self.tab.tabs[2].redMark:SetActive(flag)
end

function StoryListWindowBigItem:ctor(go, id, parent)
	self.id = id
	self.parent = parent

	StoryListWindowBigItem.super.ctor(self, go)
end

function StoryListWindowBigItem:initUI()
	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UISprite))
	self.clearIcon = go:NodeByName("clearIcon").gameObject
	self.episodeLabel_ = go:ComponentByName("textBg_/episodeLabel_", typeof(UILabel))
	self.redIcon = go:NodeByName("redIcon").gameObject

	xyd.setUISpriteAsync(self.imgBg, nil, MainPlotEpisodeTable:getImg(self.id) .. "_" .. xyd.Global.lang)

	self.episodeLabel_.text = MainPlotEpisodeTable:getDesc(self.id)

	UIEventListener.Get(self.imgBg.gameObject).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self.parent:onEpisodeClick(self.id)
	end
end

function StoryListWindowItem:ctor(go, parent)
	StoryListWindowItem.super.ctor(self, go, parent)
end

function StoryListWindowItem:initUI()
	local go = self.go
	self.bg_ = go:ComponentByName("bg_", typeof(UISprite))
	self.bg2_ = go:ComponentByName("bg2_", typeof(UISprite))
	self.titleLabel1_ = go:ComponentByName("titleLabel1_", typeof(UILabel))
	self.titleLabel2_ = go:ComponentByName("titleLabel2_", typeof(UILabel))
	self.fortDot = go:NodeByName("fortDot").gameObject
	self.maskGroup = go:NodeByName("maskGroup").gameObject
	self.maskGroupWidget = self.maskGroup:GetComponent(typeof(UIWidget))
	self.imgAsk = self.maskGroup:NodeByName("imgAsk").gameObject
	self.imgLock = self.maskGroup:NodeByName("imgLock").gameObject
	self.progressGroup = go:NodeByName("progressGroup").gameObject
	self.progressGroupWidget = self.progressGroup:GetComponent(typeof(UIWidget))
	self.lockLabel_ = self.progressGroup:ComponentByName("label_", typeof(UILabel))
	self.progressLabel_ = self.progressGroup:ComponentByName("progressLabel_", typeof(UILabel))
	self.lockIcon = go:ComponentByName("lockIcon", typeof(UISprite))
	self.redIcon = go:NodeByName("redIcon").gameObject
	self.unlockEffect = go:NodeByName("unlockEffect").gameObject

	xyd.setDragScrollView(self.bg_.gameObject, self.parent.scrollviewMain_)
	xyd.setUISpriteAsync(self.lockIcon, nil, "story_list_unlock_" .. xyd.Global.lang)
end

function StoryListWindowItem:registerEvent()
	UIEventListener.Get(self.bg_.gameObject).onClick = handler(self, self.onClickItem)
end

function StoryListWindowItem:updateInfo()
	self.type1 = self.data.type1
	self.type2 = self.data.type2
	self.imgSrc = self.data.imgSrc
	self.title = self.data.title
	self.desc = self.data.desc

	self:updateLayout()

	if self:checkUnlock() then
		self:unlock()
	elseif self.type2 == TYPE2.LIST and self:checkCanUnlock() then
		self:willUnlock()
	else
		self:lock()
	end
end

function StoryListWindowItem:updateLayout()
	if self.type2 == TYPE2.FORT then
		self.fortId = self.data.fortId

		if self.type1 == TYPE1.STORY and not StoryListModel:checkCanShowByFortID(self.fortId) then
			self.go:SetActive(false)

			return
		elseif self.type1 == TYPE1.ACTIVITY and not ActivityPlotFortTable:checkIsShow(self.fortId) then
			self.go:SetActive(false)

			return
		end

		xyd.setUISpriteAsync(self.bg_, nil, "main_fort_plot_bg")
		self.redIcon:SetActive(StoryListModel:getRedMarkStateByFortID(self.fortId, self.type1 == TYPE1.ACTIVITY))
		self.fortDot:SetActive(false)
		self.progressGroup:SetActive(true)
		self.titleLabel2_:Y(0)

		self.lockLabel_.text = __("PLOT_UNLOCK_PROGRESS")
		local value, limit = StoryListModel:getProgressByFortID(self.fortId, self.type1 == TYPE1.ACTIVITY)
		self.value = value
		self.progressLabel_.text = value .. "/" .. limit
	elseif self.type2 == TYPE2.LIST then
		self.listId = self.data.listId

		xyd.setUISpriteAsync(self.bg_, nil, "window_bg07")
		self.redIcon:SetActive(StoryListModel:getRedMarkStateByListID(self.listId, self.type1 == TYPE1.ACTIVITY))
		self.fortDot:SetActive(true)
		self.progressGroup:SetActive(false)
		self.titleLabel2_:Y(-25)
	end

	self.titleLabel1_.text = self.title
	self.titleLabel2_.text = self.desc

	xyd.setUISpriteAsync(self.bg2_, nil, self.imgSrc)
	self.bg2_:SetActive(true)
	self.lockIcon:SetActive(false)
end

function StoryListWindowItem:checkUnlock()
	if self.type2 == TYPE2.FORT then
		return StoryListModel:getUnlockStateByFortID(self.fortId, self.type1 == TYPE1.ACTIVITY)
	elseif self.type2 == TYPE2.LIST then
		return StoryListModel:getUnlockStateByListID(self.listId, self.type1 == TYPE1.ACTIVITY)
	end
end

function StoryListWindowItem:checkCanUnlock()
	return StoryListModel:checkCanUnlockByListID(self.listId, self.type1 == TYPE1.ACTIVITY)
end

function StoryListWindowItem:unlock()
	self.lock_state = "unlock"

	if self.type1 == TYPE2.STORY and self.type2 == TYPE2.FORT and self.value == 0 then
		self:playUnlock(true)

		return
	end

	self.maskGroup:SetActive(false)
end

function StoryListWindowItem:willUnlock()
	self.lock_state = "will_unlock"

	self.maskGroup:SetActive(true)
	self.imgAsk:SetActive(false)
	self.imgLock:SetActive(false)
	self.lockIcon:SetActive(true)
	self:playUnlock()
end

function StoryListWindowItem:lock()
	self.lock_state = "lock"

	self.maskGroup:SetActive(true)
	self.imgAsk:SetActive(true)
	self.imgLock:SetActive(true)
	self.bg2_:SetActive(false)
	self.titleLabel2_:SetActive(false)
	self.progressGroup:SetActive(false)

	self.titleLabel1_.text = "？？？"
end

function StoryListWindowItem:onClickItem()
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	if self.lock_state == "lock" then
		if self.type2 == TYPE2.FORT then
			xyd.alertTips(__("PLOT_UNLOCK_TIPS1"))
		else
			xyd.alertTips(__("PLOT_UNLOCK_TIPS2"))
		end
	elseif self.type2 == TYPE2.FORT then
		self.parent:onClickFortItem(self.fortId, self.type1)
	elseif self.type2 == TYPE2.LIST then
		self.parent:onClickListItem(self.listId, self.type1, self.lock_state)
	end
end

function StoryListWindowItem:playUnlock(isFort)
	if not self.suoxEffect then
		self.suoxEffect = xyd.Spine.new(self.unlockEffect)
	end

	if not isFort then
		self.suoxEffect:setInfo("suox", function ()
			self.suoxEffect:play("texiao1", 1, 1)
		end)
	elseif self.type1 ~= TYPE1.ACTIVITY then
		self.bg2_.alpha = 0
		self.titleLabel1_.alpha = 0
		self.titleLabel2_.alpha = 0
		self.progressGroupWidget.alpha = 0

		self.maskGroup:SetActive(true)
		self.imgAsk:SetActive(true)
		self.imgLock:SetActive(false)

		local sequence = self:getSequence()

		local function setter1(value)
			self.bg2_.alpha = value
		end

		local function setter2(value)
			self.titleLabel1_.alpha = value
		end

		local function setter3(value)
			self.titleLabel2_.alpha = value
		end

		local function setter4(value)
			self.progressGroupWidget.alpha = value
		end

		self.suoxEffect:setInfo("suox", function ()
			self.suoxEffect:play("texiao1", 1, 1, function ()
				sequence:Append(xyd.getTweenAlpha(self.maskGroupWidget, 0.01, 0.2))
				sequence:Insert(0.15, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.2))
				sequence:Insert(0.15, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0, 1, 0.2))
				sequence:Insert(0.15, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), 0, 1, 0.2))
				sequence:Insert(0.15, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter4), 0, 1, 0.2))
				self:waitForTime(0.2, function ()
					self.maskGroup:SetActive(false)

					self.maskGroupWidget.alpha = 1
				end)
			end)
		end)
	end
end

function HeroListWindowItem:ctor(go, parent)
	HeroListWindowItem.super.ctor(self, go, parent)
end

function HeroListWindowItem:initUI()
	local go = self.go
	self.labelFortName_ = go:ComponentByName("fortName", typeof(UILabel))
	self.fortGroup_ = go:NodeByName("fGroup").gameObject
	self.fortImg_ = go:ComponentByName("fGroup/fortimg", typeof(UISprite))

	xyd.setDragScrollView(self.fortImg_.gameObject, self.parent.scrollviewHero_)
end

function HeroListWindowItem:registerEvent()
	UIEventListener.Get(self.fortImg_.gameObject).onClick = handler(self, self.onClickFortItem)
end

function HeroListWindowItem:updateInfo()
	self.fortId = self.data.fortId
	self.maxFortId = self.data.maxFortId
	self.maxStage = self.data.maxStage
	self.fortImgSrc = self.data.fortImgSrc
	self.localFortNameText = self.data.localFortNameText

	xyd.setUISpriteAsync(self.fortImg_, nil, self.fortImgSrc)

	if self.localFortNameText then
		self.labelFortName_.text = self.localFortNameText
	else
		self.labelFortName_.text = xyd.tables.partnerChallengeTextTable:fortName(xyd.tables.partnerChallengeTable:getIdsByFort(self.fortId)[1])
	end
end

function HeroListWindowItem:onClickFortItem()
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	if not xyd.checkFunctionOpen(xyd.FunctionID.HERO_CHALLENGE, false) then
		return
	end

	if self.maxStage == 0 then
		local params = {
			alertType = xyd.AlertType.YES_NO,
			message = __("HERO_CHALLENGE_TIPS40"),
			callback = function (yes)
				if yes then
					xyd.WindowManager.get():openWindow("hero_challenge_detail_window", {
						fort_id = self.fortId
					})
				end
			end
		}

		xyd.WindowManager.get():openWindow("alert_window", params)

		return
	end

	xyd.WindowManager.get():openWindow("hero_challenge_memory_window", {
		fort_id = self.fortId,
		max_stage = self.maxStage
	})
end

return StoryListWindow
