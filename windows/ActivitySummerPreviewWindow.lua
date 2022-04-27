local BaseWindow = import(".BaseWindow")
local ActivitySummerPreviewWindow = class("ActivitySummerPreviewWindow", BaseWindow)
local shopTable = xyd.tables.activityBeachShopTable

function ActivitySummerPreviewWindow:ctor(name, params)
	ActivitySummerPreviewWindow.super.ctor(self, name, params)

	self.pageNum_ = 6
	self.itemWidth = 950
	self.intervals = 5
	self.direction = -1
	self.now_index = 1
	self.threshold = 30
	self.cItemList_ = {}
	self.scrollBarItemWidth = 32
	self.latticePos = {
		{
			-60,
			-60
		},
		{
			-60,
			-30
		},
		{
			-27.5,
			-61
		},
		{
			-37,
			-44
		},
		{
			-58,
			1
		},
		{
			-37,
			-12
		},
		{
			-16,
			-34
		},
		{
			2,
			-60
		},
		{
			-60,
			28
		},
		{
			-44,
			14
		},
		{
			-21,
			-11
		},
		{
			0,
			-37
		},
		{
			19,
			-60
		},
		{
			-36,
			35.5
		},
		{
			-19,
			12
		},
		{
			2,
			-16
		},
		{
			24,
			-39
		},
		{
			45,
			-53
		},
		{
			-6,
			39
		},
		{
			9,
			9
		},
		{
			32,
			-12
		},
		{
			17,
			40.5
		},
		{
			48,
			35
		}
	}
end

function ActivitySummerPreviewWindow:initWindow()
	self:getUIComponent()
	ActivitySummerPreviewWindow.super.initWindow(self)
	self:checkRoleNumber()
	self:initLayout()
	self:registerEvent()
	self:waitForFrame(1, handler(self, self.playLatticeAnimation))
end

function ActivitySummerPreviewWindow:registerEvent()
	ActivitySummerPreviewWindow.super.register(self)

	UIEventListener.Get(self.gotoBtn_).onClick = function ()
		xyd.WindowManager.get():clearStackWindow()
		xyd.WindowManager.get():closeThenOpenWindow("activity_summer_preview_window", "activity_window", {
			activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_BEACH_PUZZLE),
			select = xyd.ActivityID.ACTIVITY_BEACH_PUZZLE
		})
	end

	UIEventListener.Get(self.content_).onDragStart = function ()
		self:onDragStart()
	end

	UIEventListener.Get(self.content_).onDrag = function (go, delta)
		self:onDrag(delta)
	end

	UIEventListener.Get(self.content_).onDragEnd = function (go)
		self:onDragEnd()
	end

	UIEventListener.Get(self.content_).onClick = handler(self, self.onClick)
end

function ActivitySummerPreviewWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.bg_ = winTrans:ComponentByName("groupAction/main_group/bg", typeof(UISprite))
	self.titleImg_ = winTrans:ComponentByName("groupAction/main_group/title_img", typeof(UISprite))
	self.tipLabel1_ = winTrans:ComponentByName("groupAction/main_group/tip_label1", typeof(UILabel))
	self.gotoBtn_ = winTrans:NodeByName("groupAction/main_group/mid_group/goto_btn").gameObject
	local puzzles_group = winTrans:NodeByName("groupAction/main_group/mid_group/puzzles_group").gameObject
	self.BaseImg_ = puzzles_group:ComponentByName("base_img", typeof(UITexture))
	self.frame_img_ = puzzles_group:ComponentByName("frame_img", typeof(UITexture))
	self.lattice1 = puzzles_group:NodeByName("lattice_group/A4 (1)").gameObject
	self.lattice2 = puzzles_group:NodeByName("lattice_group/A2 (3)").gameObject
	self.lattice3 = puzzles_group:NodeByName("lattice_group/A4 (3)").gameObject
	self.cItem_ = puzzles_group:NodeByName("cItem").gameObject
	self.mask_group = puzzles_group:NodeByName("mask_group").gameObject
	local scroll_group = winTrans:NodeByName("groupAction/main_group/mid_group/scroll_group").gameObject
	self.scroll_img_group_ = scroll_group:NodeByName("scroll_img_group").gameObject
	self.content_ = scroll_group:NodeByName("scroll_img_group/content").gameObject
	self.indexPoint_ = scroll_group:NodeByName("scroll_bar/index_point").gameObject
	self.scrollBar_ = scroll_group:NodeByName("scroll_bar").gameObject

	for i = 1, 6 do
		self["item" .. i] = scroll_group:NodeByName("scroll_img_group/content/item" .. i).gameObject
	end

	for i = 1, 6 do
		self["scrollBarPoint" .. i] = scroll_group:NodeByName("scroll_bar/scroll_bar_point" .. i).gameObject
	end

	self.indexPointBeginPosition_ = self.indexPoint_.transform.localPosition
	self.contentPosition = self.content_.transform.localPosition
	self.beginPos = self.content_.transform.localPosition
	self.endPos = self.content_.transform.localPosition
	self.endPos.x = self.endPos.x - (self.pageNum_ - 1) * self.itemWidth
	self.dragDelta = 0
end

function ActivitySummerPreviewWindow:initLayout()
	self.sequence = self:getSequence()
	self.sequence1 = self:getSequence()
	self.timer_ = self:getTimer(handler(self, self.autoMove), self.intervals, -1)

	xyd.setUISpriteAsync(self.titleImg_, nil, "logo_" .. xyd.Global.lang)

	self.tipLabel1_.text = __("ACTIVITY_BEACH_MAIN_WINDOW_TEXT01")
	self.gotoBtn_:ComponentByName("goto_btn_lable", typeof(UILabel)).text = __("ACTIVITY_BEACH_MAIN_WINDOW_TEXT02")
end

function ActivitySummerPreviewWindow:playOpenAnimation(callback)
	ActivitySummerPreviewWindow.super.playOpenAnimation(self, callback)
	self:resetLatticeAnimation()
	self.timer_:Reset(handler(self, self.autoMove), self.intervals, -1, false)
	self.timer_:Start()
	self:resetRoleImgPos()
	self:waitForFrame(1, handler(self, self.playLatticeAnimation))
end

function ActivitySummerPreviewWindow:checkRoleNumber()
	local nowTime = xyd.getServerTime()
	local timeStamp1 = shopTable:getTime(3)
	local timeStamp2 = shopTable:getTime(5)

	if nowTime < timeStamp1 then
		for i = 3, 6 do
			self["item" .. i]:SetActive(false)
			self["scrollBarPoint" .. i]:SetActive(false)

			self.pageNum_ = 2
		end

		local newPos = Vector3(self.scrollBar_.transform.localPosition.x + 2 * self.scrollBarItemWidth, self.scrollBar_.transform.localPosition.y, self.scrollBar_.transform.localPosition.z)
		self.scrollBar_.transform.localPosition = newPos

		return
	end

	if nowTime < timeStamp2 then
		for i = 5, 6 do
			self["item" .. i]:SetActive(false)
			self["scrollBarPoint" .. i]:SetActive(false)

			self.pageNum_ = 4
		end

		local newPos = Vector3(self.scrollBar_.transform.localPosition.x + self.scrollBarItemWidth, self.scrollBar_.transform.localPosition.y, self.scrollBar_.transform.localPosition.z)
		self.scrollBar_.transform.localPosition = newPos

		return
	end
end

function ActivitySummerPreviewWindow:resetLatticeAnimation()
	for i = 1, #self.cItemList_ do
		self.cItemList_[i].transform.parent = self.mask_group.transform

		self.cItemList_[i]:SetActive(false)
	end

	self.lattice1:SetActive(true)
	self.lattice2:SetActive(true)
	self.lattice3:SetActive(true)
end

function ActivitySummerPreviewWindow:resetRoleImgPos()
	self.now_index = 1

	self:recenter(0.1)
	self:UpdateIndexPosition()
end

function ActivitySummerPreviewWindow:onClick()
end

function ActivitySummerPreviewWindow:onDragStart()
	self.timer_:Stop()

	self.dragDelta = 0
end

function ActivitySummerPreviewWindow:onDrag(delta)
	self.dragDelta = self.dragDelta + delta.x
end

function ActivitySummerPreviewWindow:onDragEnd()
	if self.dragDelta > 0 and self.now_index > 1 then
		self.now_index = self.now_index - 1
	end

	if self.dragDelta < 0 and self.now_index < self.pageNum_ then
		self.now_index = self.now_index + 1
	end

	self.timer_:Reset(handler(self, self.autoMove), self.intervals, -1, false)
	self.timer_:Start()
	self:recenter(nil)
	self:UpdateIndexPosition()
end

function ActivitySummerPreviewWindow:recenter(moveTime)
	if moveTime == nil then
		moveTime = 0.5
	end

	if self.sequence then
		self.sequence:Pause()
		self.sequence:Kill(true)
	end

	self.sequence = self:getSequence()
	local des_x = self.beginPos.x - (self.now_index - 1) * self.itemWidth

	self.sequence:Append(self.content_.transform:DOLocalMoveX(des_x, moveTime))
end

function ActivitySummerPreviewWindow:autoMove()
	if self.now_index == self.pageNum_ and self.direction == -1 then
		self.direction = 1
	end

	if self.now_index == 1 and self.direction == 1 then
		self.direction = -1
	end

	self.now_index = self.now_index - self.direction

	self:UpdateIndexPosition()

	local endX = self.beginPos.x - (self.now_index - 1) * self.itemWidth

	self.sequence:Append(self.content_.transform:DOLocalMoveX(endX, 0.5))
end

function ActivitySummerPreviewWindow:UpdateIndexPosition()
	local endX = self.indexPointBeginPosition_.x + (self.now_index - 1) * self.scrollBarItemWidth
	local newPos = Vector3(endX, self.indexPoint_.transform.localPosition.y, self.indexPoint_.transform.localPosition.z)
	self.indexPoint_.transform.localPosition = newPos
end

function ActivitySummerPreviewWindow:playLatticeAnimation()
	self:generateCItem()
	self:eraseLattice(1)
	self:waitForFrame(60, function ()
		self:eraseLattice(2)
	end)
	self:waitForFrame(120, function ()
		self:eraseLattice(3)
	end)
end

function ActivitySummerPreviewWindow:eraseLattice(lattice_index)
	local lattice = self["lattice" .. lattice_index]
	local i = 1
	local sum = #self.latticePos

	while i <= sum do
		local index = i

		self:waitForFrame(index + 1, function ()
			self:addCitem(index, lattice)

			if sum <= index then
				lattice:SetActive(false)
			end
		end)

		i = i + 1
	end
end

function ActivitySummerPreviewWindow:generateCItem()
	for i = 1, #self.latticePos do
		local itemNew = NGUITools.AddChild(self.mask_group, self.cItem_)
		self.cItemList_[i] = itemNew

		itemNew:SetActive(false)
	end
end

function ActivitySummerPreviewWindow:addCitem(index, lattice)
	local pos = self.latticePos[index]

	if not pos or not pos[1] or not pos[2] then
		return
	end

	local itemNew = self.cItemList_[index]
	itemNew.transform.parent = lattice.transform

	itemNew:X(pos[1])
	itemNew:Y(pos[2])
	itemNew:SetActive(true)
end

function ActivitySummerPreviewWindow:didClose()
	ActivitySummerPreviewWindow.super.didClose(self)

	xyd.MainController.get().openPopWindowNum = xyd.MainController.get().openPopWindowNum - 1
end

return ActivitySummerPreviewWindow
