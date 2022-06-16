local SkinThemeBuffWindow = class("SkinThemeBuffWindow", import(".BaseWindow"))
local TaskItem = class("TaskItem", import("app.components.CopyComponent"))

function SkinThemeBuffWindow:ctor(name, params)
	SkinThemeBuffWindow.super.ctor(self, name, params)

	self.theme_id = params.theme_id
end

function SkinThemeBuffWindow:initWindow()
	self:getUIComponent()
	SkinThemeBuffWindow.super.initWindow(self)
	self:registerEvent()
	self:initData()
	self:layout()
end

function SkinThemeBuffWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelWinTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.content = self.groupAction:NodeByName("content").gameObject
	self.taskContent = self.content:NodeByName("taskContent").gameObject
	self.bg_ = self.taskContent:ComponentByName("bg_", typeof(UISprite))
	self.taskTitleGroup = self.taskContent:NodeByName("titleGroup").gameObject
	self.labelTaskTitle = self.taskTitleGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.labelTaskHasNum = self.taskTitleGroup:ComponentByName("labelHasNum", typeof(UILabel))
	self.taskScroller = self.taskContent:NodeByName("scroller").gameObject
	self.taskScrollView = self.taskContent:ComponentByName("scroller", typeof(UIScrollView))
	self.task_item = self.taskScroller:NodeByName("task_item").gameObject
	self.taskGroup = self.taskScroller:NodeByName("taskGroup").gameObject
	self.taskItemGroup = self.taskGroup:NodeByName("itemGroup").gameObject
	self.taskItemGroup = self.taskGroup:NodeByName("itemGroup").gameObject
	self.taskItemGroup_layout = self.taskGroup:ComponentByName("itemGroup", typeof(UILayout))
	self.dressContent = self.content:NodeByName("dressContent").gameObject
	self.dressTitleGroup = self.dressContent:NodeByName("titleGroup").gameObject
	self.labelDressTitle = self.dressTitleGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.labelDressHasNum = self.dressTitleGroup:ComponentByName("labelHasNum", typeof(UILabel))
	self.dressScroller = self.dressContent:NodeByName("scroller").gameObject
	self.dressScrollView = self.dressContent:ComponentByName("scroller", typeof(UIScrollView))
	self.dressGroup = self.dressScroller:NodeByName("dressGroup").gameObject
	self.dressItemGroup = self.dressGroup:NodeByName("itemGroup").gameObject
	self.dressItemGroup_Grid = self.dressGroup:ComponentByName("itemGroup", typeof(UIGrid))
end

function SkinThemeBuffWindow:initData()
	self.taskDatas = {}
	self.skinIDs = {}
	self.skinHasNum = 0
	self.nowPoint = xyd.models.collection:getPointsByThemeID(self.theme_id)
	self.skinIDs = xyd.tables.collectionSkinGroupTable:getSkins(self.theme_id)

	for i = 1, #self.skinIDs do
		local skin_id = self.skinIDs[i]
		local collectionID = xyd.tables.itemTable:getCollectionId(skin_id)

		if xyd.models.collection:isGot(collectionID) then
			self.skinHasNum = self.skinHasNum + 1
		end
	end

	local datas = xyd.tables.collectionSkinGroupTable:getAwards(self.theme_id)

	for i = 1, #datas do
		if datas[i][1] <= #self.skinIDs then
			table.insert(self.taskDatas, datas[i])
		end
	end
end

function SkinThemeBuffWindow:addTitle()
	self.labelWinTitle.text = __("COLLECTION_SKIN_TEXT24")
end

function SkinThemeBuffWindow:layout()
	self.labelTaskTitle.text = __("COLLECTION_SKIN_TEXT25")
	self.labelTaskHasNum.text = self.nowPoint
	self.labelDressTitle.text = __("COLLECTION_SKIN_TEXT27")
	self.labelDressHasNum.text = self.skinHasNum .. "/" .. #self.skinIDs

	if self.taskItems == nil then
		self.taskItems = {}

		for i = 1, #self.taskDatas do
			local itemObj = NGUITools.AddChild(self.taskItemGroup, self.task_item)
			local item = TaskItem.new(itemObj)

			item:setInfo({
				info = self.taskDatas[i],
				skinHasNum = self.skinHasNum
			})
			table.insert(self.taskItems, item)
		end
	else
		for i = 1, #self.normalAwardDatas do
			self.taskItems[i]:setInfo({
				info = self.taskDatas[i],
				skinHasNum = self.skinHasNum
			})
		end
	end

	self.taskItemGroup_layout:Reposition()

	if self.skinItems == nil then
		self.skinItems = {}

		for i = 1, #self.skinIDs do
			local item = xyd.getItemIcon({
				hideText = true,
				scale = 1,
				uiRoot = self.dressItemGroup,
				itemID = self.skinIDs[i],
				dragScrollView = self.dressScrollView
			})

			table.insert(self.skinItems, item)
		end
	else
		for i = 1, #self.skinIDs do
			self.skinItems[i]:setInfo({
				hideText = true,
				scale = 1,
				uiRoot = self.dressItemGroup,
				itemID = self.skinIDs[i],
				dragScrollView = self.dressScrollView
			})
		end
	end

	for i = 1, #self.skinIDs do
		local collectionID = xyd.tables.itemTable:getCollectionId(self.skinIDs[i])
		local flag = not xyd.models.collection:isGot(collectionID)

		self.skinItems[i]:setMask(flag)
	end

	self.dressItemGroup_Grid:Reposition()
	self.dressScrollView:ResetPosition()
	self.taskScrollView:ResetPosition()
end

function SkinThemeBuffWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function TaskItem:ctor(go)
	self.go = go

	self:getUIComponent()
end

function TaskItem:getUIComponent()
	self.labelDesc = self.go:ComponentByName("labelDesc", typeof(UILabel))
	self.labelHasNum = self.go:ComponentByName("labelHasNum", typeof(UILabel))
	self.icon = self.labelHasNum:ComponentByName("icon", typeof(UISprite))
end

function TaskItem:setInfo(params)
	if not params then
		self.go:SetActive(false)
	else
		self.go:SetActive(true)
	end

	self.info = params.info
	self.skinHasNum = params.skinHasNum
	self.num = self.info[1]
	self.point = self.info[3]
	self.haveFinish = self.num <= self.skinHasNum
	self.labelDesc.text = __("COLLECTION_SKIN_TEXT26", self.num)
	self.labelHasNum.text = self.point

	if self.haveFinish then
		self.labelDesc.color = Color.New2(960513791)
		self.labelHasNum.color = Color.New2(960513791)
	else
		self.labelDesc.color = Color.New2(2155905279.0)
		self.labelHasNum.color = Color.New2(2155905279.0)
	end
end

return SkinThemeBuffWindow
