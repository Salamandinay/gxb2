local ShrineStoryReviewWindow = class("ShrineStoryReviewWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local ShrinePlotItem = class("ShrinePlotItem", import("app.components.CopyComponent"))
local ShrineTab1Item = class("ShrineTab1Item", import("app.components.CopyComponent"))
local ShrineTab2Item = class("ShrineTab2Item", import("app.components.CopyComponent"))

function ShrineStoryReviewWindow:ctor(name, params)
	ShrineStoryReviewWindow.super.ctor(self, name, params)

	self.selectedChapter = nil
	self.plotItemList = {}
end

function ShrineStoryReviewWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:register()
end

function ShrineStoryReviewWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel = winTrans:ComponentByName("title_label", typeof(UILabel))
	self.listScroller = winTrans:ComponentByName("left_list_scroller", typeof(UIScrollView))
	self.listContainer = winTrans:NodeByName("left_list_scroller/list_container").gameObject
	self.listTable = winTrans:ComponentByName("left_list_scroller/list_container", typeof(UITable))
	self.tab1Item = winTrans:NodeByName("tab1_item").gameObject
	self.tab2Item = winTrans:NodeByName("tab2_item").gameObject

	self.tab1Item:SetActive(false)
	self.tab2Item:SetActive(false)

	self.rightListScroller = winTrans:ComponentByName("right_list_scroller", typeof(UIScrollView))
	self.rightListGrid = winTrans:ComponentByName("right_list_scroller/list_container", typeof(UIGrid))
	self.rightItem = winTrans:NodeByName("right_item").gameObject
	self.rightTitleLabel = winTrans:ComponentByName("right_title_label", typeof(UILabel))

	self.rightItem:SetActive(false)
end

function ShrineStoryReviewWindow:layout()
	self.titleLabel.text = __("")

	self.rightTitleLabel:SetActive(false)

	local chapterList = xyd.tables.shrinePlotListTable:getChapterTap1List()
	local chapterOneItem = nil

	self:waitForFrame(3, function ()
		for _, chapterId in ipairs(chapterList) do
			local chapterNode = NGUITools.AddChild(self.listContainer, self.tab1Item)
			local tab1Item = ShrineTab1Item.new(chapterNode, self)
			local params = {
				id = chapterId
			}

			tab1Item:setInfo(params)

			if not chapterOneItem then
				chapterOneItem = tab1Item
			end
		end

		self.listTable:Reposition()
		self.listScroller:ResetPosition()
		chapterOneItem:onClickTab1(true)

		if self.selectedChapter then
			self.selectedChapter:onClickTab1(false)
		end
	end)
end

function ShrineStoryReviewWindow:updateChapterList(tab1Item)
	if not tab1Item then
		return
	end

	if not self.selectedChapter then
		self.selectedChapter = tab1Item

		return
	end

	if self.selectedChapter.chapterId == tab1Item.chapterId then
		return
	end

	local function callback()
		self.selectedChapter = tab1Item
	end

	self.selectedChapter:onClickTab1(false, callback)
end

function ShrineStoryReviewWindow:updatePlotList(params)
	local chapter2Id = params.chapter2Id
	local plotList = params.plotList
	local chapterTitle = xyd.tables.shrinePlotListTable:getChapterTitle(chapter2Id)
	self.rightTitleLabel.text = chapterTitle

	self.rightTitleLabel:SetActive(true)
	table.sort(plotList)

	for i, plotId in ipairs(plotList) do
		local plotItem = nil

		if not self.plotItemList[i] then
			local plotNode = NGUITools.AddChild(self.rightListGrid.gameObject, self.rightItem)
			plotItem = ShrinePlotItem.new(plotNode, self)
			self.plotItemList[i] = plotItem
		else
			plotItem = self.plotItemList[i]
		end

		local params = {
			id = plotId
		}

		plotItem:SetActive(true)
		plotItem:setInfo(params)
	end

	if #plotList < #self.plotItemList then
		for i = #plotList + 1, #self.plotItemList do
			self.plotItemList[i]:SetActive(false)
		end
	end

	self.rightListGrid:Reposition()
	self.rightListScroller:ResetPosition()
end

function ShrineStoryReviewWindow:register()
	ShrineStoryReviewWindow.super.register(self)
end

function ShrineTab1Item:ctor(go, parentWin)
	self.parentWin = parentWin
	self.isSelected = false
	self.tab2ItemOne = nil
	self.tab2ItemSelected = nil

	ShrineTab1Item.super.ctor(self, go)
end

function ShrineTab1Item:initUI()
	self:getUIComponent()
	ShrineTab1Item.super.initUI(self)
	self:register()
end

function ShrineTab1Item:getUIComponent()
	self.tabBg = self.go:ComponentByName("tab1_bg", typeof(UISprite))
	self.tabLabel = self.go:ComponentByName("tab1_label", typeof(UILabel))
	self.tab2List = self.go:NodeByName("tab2_list").gameObject
	self.itemGrid = self.go:ComponentByName("tab2_list/item_grid", typeof(UIGrid))

	self:setDragScrollView(self.parentWin.listScroller)
end

function ShrineTab1Item:register()
	UIEventListener.Get(self.go).onClick = function ()
		self:onClickTab1(not self.isSelected)
	end
end

function ShrineTab1Item:setInfo(info)
	self.chapterId = info.id
	self.chapterData = xyd.tables.shrinePlotListTable:getChapterTap2List(self.chapterId)

	table.sort(self.chapterData)

	local chapterTitle = xyd.tables.shrinePlotListTable:getChapterTitle(self.chapterId)
	self.tabLabel.text = chapterTitle

	self:setSelected()

	for _, chapter2Id in ipairs(self.chapterData) do
		local chapter2Node = NGUITools.AddChild(self.itemGrid.gameObject, self.parentWin.tab2Item)
		local tab2Item = ShrineTab2Item.new(chapter2Node, self.parentWin, self)
		local params = {
			id = chapter2Id
		}

		tab2Item:setInfo(params)

		if not self.tab2ItemOne then
			self.tab2ItemOne = tab2Item
		end
	end

	self.itemGrid:Reposition()

	self.tab2List.transform.localScale = Vector3(1, 0, 1)
end

function ShrineTab1Item:onClickTab1(status, callback)
	if status == self.isSelected then
		return
	end

	self:setSelected(status)
	self:showTab2(status, callback)
end

function ShrineTab1Item:showTab2(status, callback)
	local seq = self:getSequence(function ()
		if status then
			if self.tab2ItemSelected then
				self.tab2ItemSelected:onClickTab2(status)
			elseif self.tab2ItemOne then
				self.tab2ItemOne:onClickTab2(status)
			end
		elseif self.tab2ItemSelected then
			self.tab2ItemSelected:onClickTab2(status)

			self.tab2ItemSelected = nil
		end

		XYDCo.WaitForFrame(1, function ()
			self.parentWin.listTable:Reposition()
			self.parentWin.listScroller:ResetPosition()
			self.parentWin:updateChapterList(self)

			if callback then
				callback()
			end
		end, nil)
	end, true)

	if status then
		for i = 0, 5 do
			seq:Insert(0.033 * i, self.tab2List.transform:DOScale(Vector3(1, 0.16666666666666666 * (i + 1), 1), 0.033))
			seq:InsertCallback(0.033 * (i + 1), function ()
				self.parentWin.listTable:Reposition()
			end)
		end
	else
		for i = 0, 5 do
			seq:Insert(0.033 * i, self.tab2List.transform:DOScale(Vector3(1, 1 - 0.16666666666666666 * (i + 1), 1), 0.033))
			seq:InsertCallback(0.033 * (i + 1), function ()
				self.parentWin.listTable:Reposition()
			end)
		end
	end
end

function ShrineTab1Item:setSelected(status)
	if status ~= nil then
		self.isSelected = status
	end

	local bgImg, fontColor, outlineColor = nil

	if self.isSelected then
		bgImg = "btn_bq_1_xz"
		fontColor = 4193710847.0
		outlineColor = 2906151679.0
	else
		bgImg = "btn_bq_1_mr"
		fontColor = 1328429311
		outlineColor = 4294967295.0
	end

	self.tabLabel.color = Color.New2(fontColor)
	self.tabLabel.effectColor = Color.New2(outlineColor)

	xyd.setUISpriteAsync(self.tabBg, nil, bgImg, nil, )
end

function ShrineTab2Item:ctor(go, parentWin, parentTab1)
	self.parentWin = parentWin
	self.isSelected = false
	self.parentTab1 = parentTab1

	ShrineTab2Item.super.ctor(self, go)
end

function ShrineTab2Item:initUI()
	self:getUIComponent()
	ShrineTab2Item.super.initUI(self)
	self:register()
end

function ShrineTab2Item:getUIComponent()
	self.tabBg = self.go:ComponentByName("tab2_bg", typeof(UISprite))
	self.tabLabel = self.go:ComponentByName("tab2_label", typeof(UILabel))

	self:setDragScrollView(self.parentWin.listScroller)
end

function ShrineTab2Item:register()
	UIEventListener.Get(self.go).onClick = function ()
		if self.isSelected then
			return
		end

		self:onClickTab2(not self.isSelected)
	end
end

function ShrineTab2Item:setInfo(info)
	self.chapter2Id = info.id
	self.plotList = xyd.tables.shrinePlotListTable:getChapterPlotList(self.chapter2Id)
	local chapterTitle = xyd.tables.shrinePlotListTable:getChapterTitle(self.chapter2Id)
	self.tabLabel.text = chapterTitle

	self:setSelected()
end

function ShrineTab2Item:setSelected(status)
	if status ~= nil then
		self.isSelected = status
	end

	local bgImgVisible = nil

	if self.isSelected then
		bgImgVisible = true
	else
		bgImgVisible = false
	end

	self.tabBg:SetActive(bgImgVisible)
end

function ShrineTab2Item:onClickTab2(status)
	if status == self.isSelected then
		return
	end

	self:setSelected(status)

	if status then
		local params = {
			chapter2Id = self.chapter2Id,
			plotList = self.plotList
		}

		if self.parentTab1.tab2ItemSelected then
			self.parentTab1.tab2ItemSelected:onClickTab2(false)
		end

		self.parentTab1.tab2ItemSelected = self

		self.parentWin:updatePlotList(params)
	end
end

function ShrinePlotItem:ctor(go, parentWin)
	self.parentWin = parentWin
	self.isUnlock = false

	ShrinePlotItem.super.ctor(self, go)
end

function ShrinePlotItem:initUI()
	self:getUIComponent()
	ShrinePlotItem.super.initUI(self)
	self:register()
end

function ShrinePlotItem:getUIComponent()
	self:setDragScrollView(self.parentWin.rightListScroller)

	self.bgImg = self.go:ComponentByName("bg_img", typeof(UISprite))
	self.desLabel = self.go:ComponentByName("des_label", typeof(UILabel))
	self.desImg = self.go:ComponentByName("des_img", typeof(UISprite))
end

function ShrinePlotItem:register()
	UIEventListener.Get(self.go).onClick = function ()
		if not self.isUnlock then
			return
		end

		local plotId = tonumber(xyd.tables.shrinePlotListTable:getPlotId(self.id)) or 0
		local plotType = xyd.tables.shrinePlotListTable:getType(self.id)

		if plotId == 0 then
			return
		end

		xyd.WindowManager.get():openWindow("story_window", {
			story_type = xyd.StoryType.SHRINE_HURDLE,
			story_id = plotId
		})
	end
end

function ShrinePlotItem:setInfo(info)
	self.id = info.id
	local unlockPlotList = xyd.models.shrineHurdleModel.plot or {}
	self.isUnlock = unlockPlotList[tostring(self.id)] or false
	local iconImg, desText, bgImg = nil
	local plotType = xyd.tables.shrinePlotListTable:getType(self.id)

	if self.isUnlock then
		desText = xyd.tables.shrinePlotListTable:getPlotTitle(self.id)

		if plotType == 1 then
			iconImg = "icon_bf"
		elseif plotType == 2 then
			iconImg = "icon_wb"
		end

		bgImg = "bg_xinxi"
	else
		desText = "? ? ?"
		iconImg = "awake_lock"
		bgImg = "bg_wjs"

		if plotType == 3 then
			desText = xyd.tables.shrinePlotListTable:getPlotTitle(self.id)
		end
	end

	self.desLabel.text = desText

	if iconImg then
		xyd.setUISpriteAsync(self.desImg, nil, iconImg, nil, , true)
		self.desImg:SetActive(true)
	else
		self.desImg:SetActive(false)
	end

	xyd.setUISpriteAsync(self.bgImg, nil, bgImg, nil, )
end

return ShrineStoryReviewWindow
