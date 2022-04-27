local ShrineHurdleStoryWindow = class("ShrineHurdleStoryWindow", import(".BaseWindow"))
local LeftItem = class("LeftItem", import("app.Components.CopyComponent"))

function LeftItem:ctor(go, parent)
	self.parent_ = parent

	LeftItem.super.ctor(self, go)

	self.selectItemList_ = {}
end

function LeftItem:initUI()
	LeftItem.super.initUI(self)
	self:getUIComponent()
end

function LeftItem:getUIComponent()
	local goTrans = self.go.transform
	self.itemImg_ = self.go:GetComponent(typeof(UISprite))
	self.tab1Label_ = goTrans:ComponentByName("label", typeof(UILabel))
	self.contentGroup_ = goTrans:ComponentByName("contentGroup", typeof(UILayout))
	self.chapterItem_ = goTrans:NodeByName("chapterItem").gameObject
	UIEventListener.Get(self.go).onClick = handler(self, self.onClickItem)
end

function LeftItem:setInfo(id, idList)
	self.id_ = id
	self.tab1Label_.text = xyd.tables.ShrineHurdlePlotTextTable:getTitle(self.id_)

	table.sort(idList)

	for _, tab2id in ipairs(idList) do
		local newItem = NGUITools.AddChild(self.contentGroup_, self.chapterItem_)

		newItem:SetActive(true)

		local label = newItem:ComponentByName("label", typeof(UILabel))
		local selectImg = newItem:NodeByName("selectImg").gameObject
		label.text = xyd.tables.ShrineHurdlePlotTextTable:getTitle(tab2id)

		UIEventListener.Get(newItem).onClick = function ()
			self:onClickTab2(tab2id)
		end

		self.selectItemList_[tab2id] = {
			selectImg = selectImg,
			label = label
		}
	end
end

function LeftItem:onClickItem()
	self.isShow_ = true

	self.parent_:selectTab1(self.id_)
end

function LeftItem:clearTab2Select()
	self.selectTab2_ = 0
end

function LeftItem:checkShowSelf(showID)
	if showID ~= self.id_ then
		self.isShow_ = false
	else
		self.isShow_ = true
	end

	if self.isShow_ then
		self.tab1Label_.color = Color.New2(4294967295.0)
		self.tab1Label_.effectColor = Color.New2(1012112383)

		xyd.setUISpriteAsync(self.itemImg_, nil, "shrine_hurdle_story_bg2")
	else
		self.tab1Label_.color = Color.New2(960513791)
		self.tab1Label_.effectColor = Color.New2(4294967295.0)

		xyd.setUISpriteAsync(self.itemImg_, nil, "shrine_hurdle_story_bg4")
	end
end

function LeftItem:onClickTab2(id)
	self.selectTab2_ = id

	self:updateSelectState()
	self.parent_:selectTab2(id)
end

function LeftItem:updateSelectState()
	if self.selectTab2_ and self.selectTab2_ > 0 then
		self.contentGroup_.transform:SetLocalScale(1, 1, 1)
	else
		self.contentGroup_.transform:SetLocalScale(1, 0, 1)
	end

	if self.isShow_ then
		self.tab1Label_.color = Color.New2(4294967295.0)
		self.tab1Label_.effectColor = Color.New2(1012112383)

		xyd.setUISpriteAsync(self.itemImg_, nil, "shrine_hurdle_story_bg2")
	else
		self.tab1Label_.color = Color.New2(960513791)
		self.tab1Label_.effectColor = Color.New2(4294967295.0)

		xyd.setUISpriteAsync(self.itemImg_, nil, "shrine_hurdle_story_bg4")
	end

	for tab2id, item in pairs(self.selectItemList_) do
		if tab2id == self.selectTab2_ then
			item.selectImg:SetActive(true)

			item.text.color = Color.New2(4294967295.0)
		else
			item.selectImg:SetActive(false)

			item.text.color = Color.New2(1583978239)
		end
	end
end

function ShrineHurdleStoryWindow:ctor(name, params)
	ShrineHurdleStoryWindow.super.ctor(self, name, params)

	self.selectID_ = 1000
	self.showTable1ID_ = 1
	self.tabItemList_ = {}
end

function ShrineHurdleStoryWindow:initWindow()
	self:getUIComponent()
	self:initList()
	self:updateSelect()
end

function ShrineHurdleStoryWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.leftItem_ = winTrans:NodeByName("leftItem").gameObject
	self.selectGroup_ = winTrans:ComponentByName("selectGroup", typeof(UIScrollView))
	self.selectGroupGrid_ = winTrans:ComponentByName("selectGroup/grid", typeof(UIGrid))
	local infoGroup = winTrans:NodeByName("infoGroup")
	self.storyTitle_ = infoGroup:ComponentByName("storyTitle", typeof(UILabel))
	self.infoItem_ = infoGroup:NodeByName("infoItem").gameObject
	self.scrollView_ = infoGroup:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = infoGroup:ComponentByName("scrollView/grid", typeof(UIGrid))
end

function ShrineHurdleStoryWindow:initList()
	local list1 = xyd.tables.ShrineHurdleStoryTable:getShowList1()

	for tab1, tab2list in ipairs(list1) do
		local newItem = NGUITools.AddChild(self.selectGroupGrid_.gameObject, self.leftItem_)
		local leftItem = LeftItem.new(newItem, self)

		leftItem:setInfo(tab1, tab2list)
		table.insert(self.tabItemList_, leftItem)
		self.selectGroupGrid_:Reposition()
	end

	self.selectGroup_:ResetPosition()
end

function ShrineHurdleStoryWindow:updateSelect()
	for _, leftItem in ipairs(self.tabItemList_) do
		leftItem:checkShowSelf(self.showTable1ID_)
	end
end

function ShrineHurdleStoryWindow:selectTab1(tab1id)
	self.showTable1ID_ = tab1id

	self:updateSelect()
end

return ShrineHurdleStoryWindow
