local ActivityModel = xyd.models.activity
local StoryMemoryItem = class("StoryMemoryItem", import("app.components.BaseComponent"))

function StoryMemoryItem:ctor(go, parent)
	self.uiRoot_ = go
	self.parent_ = parent
	local itemTrans = self.uiRoot_.transform
	self.bg_ = itemTrans:ComponentByName("bgImg", typeof(UISprite))
	self.iconImg_ = itemTrans:ComponentByName("iconImg", typeof(UISprite))
	self.imgLock_ = itemTrans:ComponentByName("lockImg", typeof(UISprite))
	self.titleLable_ = itemTrans:ComponentByName("titleLable", typeof(UILabel))

	self:registerEvent()
end

function StoryMemoryItem:registerEvent()
	UIEventListener.Get(self.bg_.gameObject).onClick = handler(self, self.onClick)
end

function StoryMemoryItem:onClick()
	if self.lock_ then
		xyd.showToast(__("LOCK_MEMORY"))

		return
	end

	self:logMemory()
	xyd.WindowManager.get():openWindow("story_window", {
		story_type = xyd.StoryType.MAIN,
		story_list = xyd.tables.mainPlotListTable:getMemoryPlotId(self.id_)
	})
end

function StoryMemoryItem:logMemory()
	local msg = messages_pb.log_memory_stage_req()
	msg.stage_id = self.id_

	xyd.Backend.get():request(xyd.mid.LOG_MEMORY_STAGE, msg)
end

function StoryMemoryItem:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)

	self.id_ = info.id
	self.lock_ = info.lock

	if not self.lock_ then
		self.imgLock_.gameObject:SetActive(false)
		self.titleLable_.gameObject:SetActive(true)
		self.iconImg_.gameObject:SetActive(true)
		self:updateLayout()
	else
		self.imgLock_.gameObject:SetActive(true)
		self.titleLable_.gameObject:SetActive(false)
		self.iconImg_.gameObject:SetActive(false)
	end
end

function StoryMemoryItem:updateLayout()
	local id = self.id_
	self.titleLable_.text = __("CHAPTER_TITLE", xyd.tables.stageTable:getFortID(id), xyd.tables.stageTable:getName(id), xyd.tables.stageTextTable:getName(id))
	local source = tostring(xyd.tables.mainPlotListTable:getChapterIcon(id))

	if not self.source_ or self.source_ ~= source then
		xyd.setUISpriteAsync(self.iconImg_, nil, source, function ()
			self.source_ = source
		end)
	end
end

function StoryMemoryItem:getGameObject(...)
	return self.uiRoot_
end

local StoryMemoryWindow = class("StoryMemoryWindow", import(".BaseWindow"))

function StoryMemoryWindow:ctor(name, params)
	StoryMemoryWindow.super.ctor(self, name, params)

	self.total_page_ = 1
	self.source_list_ = {}
	self.page_num_ = {
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0
	}
	self.cur_page_ = params.cur_page
	self.max_stage_ = params.max_stage
end

function StoryMemoryWindow:initWindow()
	StoryMemoryWindow.super.initWindow(self)

	self.windowTop = import("app.components.WindowTop").new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)

	local winTrans = self.window_.transform
	local main = winTrans:NodeByName("main").gameObject
	self.navList_ = {}
	self.groupBottom_ = main:NodeByName("groupBottom").gameObject
	self.scrollView_ = main:ComponentByName("mid/scrollview", typeof(UIScrollView))
	self.wrapContent_ = main:ComponentByName("mid/scrollview/grid", typeof(MultiRowWrapContent))
	local storyMemoryItemRoot = main:ComponentByName("mid/storyMemoryWindowItem", typeof(UIWidget)).gameObject
	self.multiWrapStory_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.wrapContent_, storyMemoryItemRoot, StoryMemoryItem, self)

	for i = 1, 7 do
		local tableBtn = main:NodeByName("groupBottom/nav/tab_" .. i).gameObject
		local uiButton = tableBtn:GetComponent(typeof(UIButton))
		local tableLabel = tableBtn:ComponentByName("label", typeof(UILabel))
		local tableImg = tableBtn:ComponentByName("img", typeof(UISprite)).gameObject
		local bgChosen = tableBtn:ComponentByName("chosen", typeof(UISprite)).gameObject
		local bgUnChosen = tableBtn:ComponentByName("unchosen", typeof(UISprite)).gameObject
		local mask = nil

		if i == 3 or i == 4 or i == 5 then
			mask = tableBtn:ComponentByName("mask", typeof(UISprite))
		else
			mask = tableBtn:ComponentByName("mask", typeof(UIWidget))
		end

		UIEventListener.Get(tableBtn).onClick = function ()
			self:onBtnTouch(i)
		end

		self.navList_[i] = {
			btn = uiButton,
			label = tableLabel,
			img = tableImg,
			bgChosen = bgChosen,
			bgUnChosen = bgUnChosen,
			mask = mask
		}
	end

	self:initSource()
	XYDCo.WaitForFrame(1, function ()
		self:updateList()
		self:updateBtn()
	end, nil)
end

function StoryMemoryWindow:initSource()
	local max_fort = xyd.tables.miscTable:getNumber("activity_delegated_test_complete", "value")
	local i = 3

	local function chickFortId(id)
		local fortId = xyd.tables.stageTable:getFortID(id)

		if max_fort < fortId or not fortId then
			return false
		end

		return true
	end

	while chickFortId(i) do
		local fortId = xyd.tables.stageTable:getFortID(i)

		if max_fort < fortId or not fortId then
			break
		end

		self.total_page_ = math.max(fortId, self.total_page_)
		local lock_type = xyd.tables.fortTable:getLockType(fortId)
		local lock_status = true

		if lock_type == 1 then
			local value = xyd.tables.mainPlotListTable:getActivityPlotId(i)
			lock_status = not ActivityModel:checkPlot(value)
		end

		local timestamp = xyd.tables.miscTable:getNumber("new_story_lock_time", "value")

		if fortId > 10 then
			if i <= self.max_stage_ and timestamp <= xyd.getServerTime() then
				lock_status = lock_status and false
			end
		else
			lock_status = i > self.max_stage_
		end

		if not lock_status and not self.source_list_[fortId] then
			self.source_list_[fortId] = {}
		end

		if self.source_list_[fortId] then
			table.insert(self.source_list_[fortId], {
				id = i,
				lock = lock_status
			})
		end

		i = i + 1
	end
end

function StoryMemoryWindow:updateBtn()
	self:initAll()

	if self.cur_page_ == 1 then
		self.navList_[3].label.text = __("CHAPTER_COUNT", 3)
		self.navList_[4].label.text = __("CHAPTER_COUNT", 2)
		self.navList_[5].label.text = __("CHAPTER_COUNT", 1)
		self.page_num_[3] = 3
		self.page_num_[4] = 2
		self.page_num_[5] = 1

		self:setBtnState(5)
		self:setDark({
			1,
			2,
			3,
			4,
			6,
			7
		})

		if self:checkReach(2) then
			self:setEnable({
				2,
				4
			})
		end

		if self:checkReach(self.total_page_) then
			self:setEnable({
				1
			})
		end

		if self:checkReach(3) then
			self:setEnable({
				3
			})
		end
	elseif self.cur_page_ == self.total_page_ then
		self.navList_[3].label.text = __("CHAPTER_COUNT", self.cur_page_)
		self.navList_[4].label.text = __("CHAPTER_COUNT", self.cur_page_ - 1)
		self.navList_[5].label.text = __("CHAPTER_COUNT", self.cur_page_ - 2)
		self.page_num_[3] = self.cur_page_
		self.page_num_[4] = self.cur_page_ - 1
		self.page_num_[5] = self.cur_page_ - 2

		self:setBtnState(3)
		self:setDark({
			1,
			2,
			3,
			4,
			6,
			7
		})

		if self:checkReach(self.cur_page_ - 1) then
			self:setEnable({
				4,
				6
			})
		end

		if self:checkReach(1) then
			self:setEnable({
				7
			})
		end

		if self:checkReach(self.cur_page_ - 2) then
			self:setEnable({
				5
			})
		end
	else
		self.navList_[3].label.text = __("CHAPTER_COUNT", self.cur_page_ + 1)
		self.navList_[4].label.text = __("CHAPTER_COUNT", self.cur_page_)
		self.navList_[5].label.text = __("CHAPTER_COUNT", self.cur_page_ - 1)
		self.page_num_[3] = self.cur_page_ + 1
		self.page_num_[4] = self.cur_page_
		self.page_num_[5] = self.cur_page_ - 1

		self:setBtnState(4)
		self:setDark({
			1,
			2,
			3,
			5,
			6,
			7
		})

		if self:checkReach(self.cur_page_ + 1) then
			self:setEnable({
				2,
				3
			})
		end

		if self:checkReach(self.cur_page_ - 1) then
			self:setEnable({
				5,
				6
			})
		end

		if self:checkReach(1) then
			self:setEnable({
				7
			})
		end

		if self:checkReach(self.total_page_) then
			self:setEnable({
				1
			})
		end
	end
end

function StoryMemoryWindow:checkReach(page)
	if page < 1 then
		return false
	end

	local ids = xyd.tables.activityNewStoryTable:getIdsByFort(page)
	local flag = false

	if ids and ActivityModel:checkPlot(xyd.tables.activityNewStoryTable:getActivityPlotListId(tonumber(ids[1]))) then
		flag = true
	end

	if self.source_list_[page] and (page <= 10 or flag or xyd.tables.miscTable:getNumber("new_story_lock_time", "value") <= xyd.getServerTime()) then
		return true
	end

	return false
end

function StoryMemoryWindow:setBtnState(index)
	for i = 3, 5 do
		self.navList_[i].bgChosen:SetActive(index == i)
		self.navList_[i].bgUnChosen:SetActive(index ~= i)
	end
end

function StoryMemoryWindow:initAll()
	for _, nav in ipairs(self.navList_) do
		if nav.btn then
			nav.btn:SetEnabled(false)
		else
			nav.mask.gameObject:SetActive(true)
		end
	end
end

function StoryMemoryWindow:setEnable(params)
	for _, idx in ipairs(params) do
		local nav = self.navList_[idx]

		if nav.btn then
			nav.btn:SetEnabled(true)
		end

		nav.mask.gameObject:SetActive(false)
	end
end

function StoryMemoryWindow:setDark(params)
	self.navList_[1].btn:SetEnabled(true)
	self.navList_[2].btn:SetEnabled(true)
	self.navList_[7].btn:SetEnabled(true)
	self.navList_[6].btn:SetEnabled(true)

	for _, idx in ipairs(params) do
		local nav = self.navList_[idx]

		if nav.btn then
			nav.btn:SetEnabled(false)
		end

		nav.mask.gameObject:SetActive(true)
	end
end

function StoryMemoryWindow:onBtnTouch(idx)
	local total = self.total_page_
	local curPage = self.cure_page_
	local switch = {
		function ()
			curPage = total
		end,
		function ()
			curPage = self.cur_page_ + 1
		end,
		function ()
			curPage = tonumber(self.page_num_[3])
		end,
		function ()
			curPage = tonumber(self.page_num_[4])
		end,
		function ()
			curPage = tonumber(self.page_num_[5])
		end,
		function ()
			curPage = self.cur_page_ - 1
		end,
		function ()
			curPage = 1
		end
	}

	switch[idx]()

	self.cur_page_ = curPage

	if total < self.cur_page_ then
		xyd.alertTips(__("LOCK_STORY_LIST"))

		self.cur_page_ = total

		return
	end

	self:updateList()
	self:updateBtn()
end

function StoryMemoryWindow:updateList()
	local test = self.source_list_[self.cur_page_]
	test = test or {}

	self.multiWrapStory_:setInfos(test, {})
	self.multiWrapStory_:resetScrollView()
end

function StoryMemoryWindow.getWindowItem()
	return StoryMemoryItem
end

return StoryMemoryWindow
