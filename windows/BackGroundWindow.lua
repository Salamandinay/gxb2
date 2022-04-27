local BaseWindow = import(".BaseWindow")
local BackGroundWindow = class("BackGroundWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local BackGroundContent = class("BackGroundContent", import("app.components.BaseComponent"))
local GalleryContent = class("GalleryContent", import("app.components.BaseComponent"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local PictureCard = class("PictureCard", import("app.components.CopyComponent"))
local GalleryCard = class("GalleryCard", PictureCard)
local GalleryGroupCard = class("GalleryGroupCard", import("app.components.CopyComponent"))
local GalleryGroupItem = class("GalleryGroupItem", import("app.components.BaseComponent"))
local BackGroundGroupItem = class("BackGroundGroupItem", import("app.components.BaseComponent"))

function BackGroundWindow:ctor(name, params)
	self.isCollection = false

	if params and params.isCollection then
		self.isCollection = params.isCollection
	end

	BaseWindow.ctor(self, name, params)

	self.select_id_ = -1
	self.item_pool_ = {}
end

function BackGroundWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupList = winTrans:NodeByName("groupList").gameObject
	self.itemGroup = self.groupList:NodeByName("pictureGroup/itemGroup").gameObject
	self.backImg = self.groupList:ComponentByName("pictureGroup/backImg", typeof(UISprite))
	self.topBtns = self.groupList:NodeByName("topBtns").gameObject
	self.topBtnsTab = CommonTabBar.new(self.topBtns, 2, handler(self, self.onSelect))

	for i = 1, 2 do
		local tabLabel = self.topBtns:ComponentByName("tab_" .. tostring(i) .. "/label", typeof(UILabel))
		tabLabel.text = __("BACKGROUND_NAV_TEXT" .. tostring(i))
	end

	self.tagGroup = self.groupList:NodeByName("tagGroup").gameObject

	for i = 1, 2 do
		self["newImg" .. tostring(i)] = self.tagGroup:ComponentByName("newImg" .. tostring(i), typeof(UISprite))
		self["redImg" .. tostring(i)] = self.tagGroup:ComponentByName("redImg" .. tostring(i), typeof(UISprite))
	end

	self.groupNone = winTrans:NodeByName("groupNone").gameObject
	self.labelNoneTips = self.groupNone:ComponentByName("labelNoneTips", typeof(UILabel))
end

function BackGroundWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	local data = xyd.models.background:getInfo()

	if data and data.background_list and #data.background_list ~= 0 then
		self:onSelect(xyd.BackgroundType.BACKGROUND)
		self:setTag()
	end

	self:layout()
	self:registerEvent()
end

function BackGroundWindow:playOpenAnimations(preWinName, callback)
	if callback then
		callback()
	end

	local group_pos = self.groupList.transform.localPosition

	self.groupList:setLocalPosition(-1000, group_pos.y, group_pos.z)
	XYDCo.WaitForTime(0.2, function ()
		local seq1 = DG.Tweening.DOTween.Sequence():OnComplete(function ()
			self:setWndComplete()
		end)

		seq1:Append(self.groupList.transform:DOLocalMove(Vector3(50, 0, 0), 0.3))
		seq1:Append(self.groupList.transform:DOLocalMove(Vector3(0, 0, 0), 0.27))
	end, nil)
end

function BackGroundWindow:setTag()
	self:setNew()
	self:setRed()
end

function BackGroundWindow:setNew()
	local background_count = 0
	local gallery_count = 0
	local list = xyd.models.background:getInfo().background_list

	for i = 1, #list do
		local type = xyd.tables.customBackgroundTable:getType(list[i].table_id)

		if xyd.models.background:checkNew(list[i].table_id, type) and list[i].is_complete > 0 then
			if type == 1 then
				background_count = background_count + 1
			else
				gallery_count = gallery_count + 1
			end
		end
	end

	self.newImg1:SetActive(background_count ~= 0)
	self.newImg2:SetActive(gallery_count ~= 0)

	if self.isCollection then
		self.newImg1:SetActive(false)
		self.newImg2:SetActive(false)
		self.redImg1:SetActive(false)
		self.redImg2:SetActive(false)
	end
end

function BackGroundWindow:setRed()
	local background_count = 0
	local gallery_count = 0
	local list = xyd.models.background:redList()
	local table = xyd.tables.customBackgroundTable

	for i = 1, #list do
		local id = list[i]
		local type = table:getType(id)

		if type == xyd.BackgroundType.BACKGROUND then
			background_count = background_count + 1
		else
			gallery_count = gallery_count + 1
		end
	end

	self.redImg1:SetActive(background_count ~= 0)
	self.redImg2:SetActive(gallery_count ~= 0)

	if not self.redImg1.isVisible and not self.redImg2.isVisible then
		xyd.models.redMark:setMark(xyd.RedMarkType.BACKGROUND, false)
	end
end

function BackGroundWindow:layout()
	self.windowTop = WindowTop.new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
	self.windowTop:setTitle(__("BIG_MAP"))

	local PositionY = self.windowTop.go.transform.localPosition.y

	if PositionY < 660 then
		self.backImg.height = 1000

		self.backImg:Y(-80)
		self.topBtns:Y(445)
		self.tagGroup:Y(446)
		self.itemGroup:Y(-105)
	end
end

function BackGroundWindow:registerEvent()
	self:register()
	self.eventProxy_:addEventListener(xyd.event.SET_BACKGROUND, function (event)
		for i = 1, 2 do
			local item = self.item_pool_[i]

			if item then
				item:updateData()
			end
		end

		self:setTag()
	end)
	self.eventProxy_:addEventListener(xyd.event.BUY_BACKGROUND, function (event)
		for i = 1, 2 do
			local item = self.item_pool_[i]

			if item then
				item:updateData()
			end
		end

		self:setTag()
	end)

	local data = xyd.models.background:getInfo()

	if not data.background_list or #data.background_list == 0 then
		print("register" .. tostring(xyd.event.GET_BACKGROUND_LIST))
		self.eventProxy_:addEventListener(xyd.event.GET_BACKGROUND_LIST, function ()
			self:onSelect(xyd.BackgroundType.BACKGROUND)
			self:setTag()
		end)
		xyd.models.background:reqInfo()
	end
end

function BackGroundWindow:onSelect(id)
	local data = xyd.models.background:getInfo()

	if not data or not data.background_list or #data.background_list == 0 then
		return
	end

	if self.select_id_ == id then
		return
	end

	self.select_id_ = id

	self:hideContent(id)

	if self.item_pool_[id] then
		self.item_pool_[id]:SetActive(true)
		self.item_pool_[id]:updateData()

		return
	end

	local item = self:newContent(id)
end

function BackGroundWindow:newContent(id)
	local clz = nil

	if id == 1 then
		clz = BackGroundContent
	else
		clz = GalleryContent
	end

	local item_pool = self.item_pool_

	if not item_pool[id] then
		item_pool[id] = clz.new(self.itemGroup, self.isCollection)
	end

	item_pool[id]:updatePanelDepth(self.window_:GetComponent(typeof(UIPanel)).depth)

	return item_pool[id]
end

function BackGroundWindow:hideContent(id)
	local item_pool = self.item_pool_

	for k, v in pairs(item_pool) do
		if tonumber(k) ~= id and v then
			v:SetActive(false)
		end
	end
end

function BackGroundWindow:refreshState(id, params)
	local type = xyd.tables.customBackgroundTable:getType(id)
	local item = nil

	if type == xyd.BackgroundType.BACKGROUND then
		item = self.item_pool_[type]
	else
		item = self.item_pool_[2]
	end

	if item then
		item:updateData()
		self:setTag()
	end
end

function BackGroundContent:ctor(parentGO, isC_)
	self.backgroundGroupItems = {}
	self.group_ids = {}
	self.isCollection = isC_

	BackGroundContent.super.ctor(self, parentGO)
	self:fixAnchor()
	self:buildCollection()
	self:layout()
end

function BackGroundContent:fixAnchor()
	local widget = self.go:GetComponent(typeof(UIWidget))

	if not widget then
		return
	end

	widget.enabled = false
	widget.leftAnchor.target = widget.transform.parent
	widget.leftAnchor.relative = 0
	widget.leftAnchor.absolute = 0
	widget.rightAnchor.target = widget.transform.parent
	widget.rightAnchor.relative = 1
	widget.rightAnchor.absolute = 0
	widget.topAnchor.target = widget.transform.parent
	widget.topAnchor.relative = 1
	widget.topAnchor.absolute = 0
	widget.bottomAnchor.target = widget.transform.parent
	widget.bottomAnchor.relative = 0
	widget.bottomAnchor.absolute = 0
	widget.enabled = true
	local PositionY = self.parentGo.transform.localPosition.y

	if PositionY < -100 then
		self.scrollerPanel.baseClipRegion = Vector4(0, 0, 710, 905)

		self.scrollerPanel:Y(-488)
		self.itemGroup_2:Y(460)
	end
end

function BackGroundContent:initUI()
	BackGroundContent.super.initUI(self)

	local go = self.go
	self.item = go:NodeByName("picture_card").gameObject
	self.scrollerPanel = go:ComponentByName("scroller", typeof(UIPanel))
	self.itemScroller = go:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup_2 = go:NodeByName("scroller/itemGroup_2").gameObject
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.titleLabel = go:ComponentByName("titleLabel", typeof(UILabel))
end

function BackGroundContent:layout()
	self.titleLabel.text = __("BACKGROUND_NAV_TEXT1")

	xyd.setDarkenBtnBehavior(self.helpBtn, self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "BACKGROUND_HELP"
		})
	end)
end

function BackGroundContent:updatePanelDepth(depth)
	self.scrollerPanel.depth = self.scrollerPanel.depth + depth
end

function BackGroundContent:updateData()
	self:buildCollection()
end

function BackGroundContent:buildCollection()
	self:buildCollection_2()
end

function BackGroundContent:buildCollection_2()
	local group_ids = xyd.tables.customBackgroundGroupTable:getIDs()
	local model = xyd.models.background
	local group_list = {}
	local index = 1

	for i = 1, #group_ids do
		local list = xyd.tables.customBackgroundTable:getListByGroup(xyd.BackgroundType.BACKGROUND, group_ids[i])

		if list then
			group_list[i] = {}
			local itemList = {}

			for j = 1, #list do
				local id = list[j]
				local params = {
					is_new = model:checkNew(id, xyd.BackgroundType.BACKGROUND),
					need_red = model:checkRedIcon(id),
					state = model:getCardState(id, self.isCollection),
					id = tonumber(id),
					in_use = model:checkInUse(id),
					isCollection = self.isCollection
				}

				table.insert(itemList, params)
			end

			table.sort(itemList, function (a, b)
				return a.id < b.id
			end)

			group_list[i].items = itemList
			group_list[i].group_id = group_ids[i]

			table.insert(self.group_ids, i)

			if #self.backgroundGroupItems < xyd.BackgroundTypeNum.BACKGROUND then
				local BackGroundGroupItem = BackGroundGroupItem.new(self.itemGroup_2, group_list[i])

				table.insert(self.backgroundGroupItems, BackGroundGroupItem)
			else
				self.backgroundGroupItems[index]:update(group_list[i])

				index = index + 1
			end
		end

		self.itemGroup_2:GetComponent(typeof(UILayout)):Reposition()
	end
end

function BackGroundContent:buildCollection_1()
	local list = xyd.tables.customBackgroundTable:getBackGroundList()
	local model = xyd.models.background
	local collection_list = {}

	for i = 1, #list do
		local id = list[i]
		local params = {
			is_new = model:checkNew(id, xyd.BackgroundType.BACKGROUND),
			need_red = model:checkRedIcon(id),
			state = model:getCardState(id, self.isCollection),
			id = tonumber(id),
			in_use = model:checkInUse(id),
			isCollection = self.isCollection
		}

		table.insert(collection_list, params)
	end

	self.wrapContent:setInfos(collection_list, {})
end

function BackGroundContent:getScrollView()
	return self.itemScroller
end

function BackGroundContent:getPrefabPath()
	return "Prefabs/Components/background_content"
end

function GalleryContent:ctor(go, isC_)
	self.galleryGroupItems = {}
	self.isCollection = isC_

	GalleryContent.super.ctor(self, go)
	self:layout()
	self:fixAnchor()
end

function GalleryContent:getPrefabPath()
	return "Prefabs/Components/gallery_content"
end

function GalleryContent:layout()
	self:buildCollection()

	self.nameLabel.text = __("BACKGROUND_NAV_TEXT2")

	xyd.setDarkenBtnBehavior(self.helpBtn, self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "BACKGROUND_HELP"
		})
	end)
end

function GalleryContent:fixAnchor()
	local widget = self.go:GetComponent(typeof(UIWidget))

	if not widget then
		return
	end

	widget.enabled = false
	widget.leftAnchor.target = widget.transform.parent
	widget.leftAnchor.relative = 0
	widget.leftAnchor.absolute = 0
	widget.rightAnchor.target = widget.transform.parent
	widget.rightAnchor.relative = 1
	widget.rightAnchor.absolute = 0
	widget.topAnchor.target = widget.transform.parent
	widget.topAnchor.relative = 1
	widget.topAnchor.absolute = 0
	widget.bottomAnchor.target = widget.transform.parent
	widget.bottomAnchor.relative = 0
	widget.bottomAnchor.absolute = 0
	widget.enabled = true
	local PositionY = self.parentGo.transform.localPosition.y

	if PositionY < -100 then
		self.pictureScrollerPanel.baseClipRegion = Vector4(0, 0, 710, 905)

		self.pictureScrollerPanel:Y(-488)
		self.itemGroup:Y(460)
	end
end

function GalleryContent:initUI()
	GalleryContent.super.initUI(self)

	local go = self.go
	self.nameLabel = go:ComponentByName("nameLabel", typeof(UILabel))
	self.picture_item = go:NodeByName("picture_item").gameObject
	self.itemScroller = go:ComponentByName("pictureScroller", typeof(UIScrollView))
	self.pictureScrollerPanel = go:ComponentByName("pictureScroller", typeof(UIPanel))
	self.itemGroup = go:NodeByName("pictureScroller/itemGroup").gameObject
	self.helpBtn = go:NodeByName("btnGroup/helpBtn").gameObject
	self.picture_item_lockImg = go:ComponentByName("picture_item/lockImg", typeof(UISprite))

	xyd.setUISpriteAsync(self.picture_item_lockImg, nil, "background_lock")

	self.picture_item_frameImg = go:ComponentByName("picture_item/frameImg", typeof(UISprite))

	xyd.setUISpriteAsync(self.picture_item_frameImg, nil, "background_card_bg_small")
end

function GalleryContent:updatePanelDepth(depth)
	self.pictureScrollerPanel.depth = depth + self.pictureScrollerPanel.depth
end

function GalleryContent:updateData()
	self:buildCollection()
end

function GalleryContent:buildCollection()
	self:buildCollection_2()
end

function GalleryContent:buildCollection_2()
	local group_ids = xyd.tables.customBackgroundGroupTable:getIDs()
	local model = xyd.models.background
	local group_list = {}

	for i = 1, #group_ids do
		local red_count = 0
		local new_count = 0
		local list = xyd.tables.customBackgroundTable:getListByGroup(xyd.BackgroundType.GALLERY, group_ids[i])
		group_list[i] = {}
		local itemList = {}

		for j = 1, #list do
			local id = list[j]
			local is_new = model:checkNew(id, xyd.tables.customBackgroundTable:getType(id))
			local need_red = model:checkRedIcon(id)

			if self.isCollection then
				is_new = false
				need_red = false
			end

			if is_new and is_new ~= 0 then
				new_count = new_count + 1
			end

			if need_red and need_red ~= 0 then
				red_count = red_count + 1
			end

			local params = {
				is_new = is_new,
				need_red = need_red,
				state = model:getCardState(id, self.isCollection),
				id = tonumber(id),
				in_use = model:checkInUse(id),
				isCollection = self.isCollection
			}

			table.insert(itemList, params)
		end

		table.sort(itemList, function (a, b)
			return a.id < b.id
		end)

		if #itemList > 0 then
			group_list[i].items = itemList
			group_list[i].group_id = group_ids[i]

			if not self.galleryGroupItems[i] then
				local galleryGroupItem = GalleryGroupItem.new(self.itemGroup, group_list[i])
				self.galleryGroupItems[i] = galleryGroupItem
			else
				self.galleryGroupItems[i]:update(group_list[i])
			end

			self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
		end
	end
end

function GalleryContent:buildCollection_1()
	local group_ids = xyd.tables.customBackgroundGroupTable:getIDs()
	local model = xyd.models.background
	local collection_list = {}
	local group_list = {}

	for i = 1, #group_ids do
		local red_count = 0
		local new_count = 0
		local list = xyd.tables.customBackgroundTable:getListByGroup(xyd.BackgroundType.GALLERY, group_ids[i])

		for i = 1, #list do
			local id = list[i]
			local is_new = model:checkNew(id, xyd.tables.customBackgroundTable:getType(id))
			local need_red = model:checkRedIcon(id)

			if self.isCollection then
				is_new = false
				need_red = false
			end

			if is_new and is_new ~= 0 then
				new_count = new_count + 1
			end

			if need_red and need_red ~= 0 then
				red_count = red_count + 1
			end

			local params = {
				is_new = is_new,
				need_red = need_red,
				state = model:getCardState(id, self.isCollection),
				id = tonumber(id),
				in_use = model:checkInUse(id),
				isCollection = self.isCollection
			}

			table.insert(collection_list, params)
		end
	end

	table.sort(collection_list, function (a, b)
		return a.id < b.id
	end)
	self.pictureWrapContent:setInfos(collection_list, {})
end

function GalleryContent:getContainScrollView()
	return self.containScroller
end

function GalleryContent:getScrollView()
	return self.pictureScroller
end

function PictureCard:ctor(go, parent)
	PictureCard.super.ctor(self, go)

	self.parent = parent

	self:setDragScrollView(parent:getScrollView())
	self:getUIComponent()
	self:registerEvent()
end

function PictureCard:setInfo(info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	local data = info
	self.is_new_ = data.is_new
	self.need_red_ = data.need_red
	self.state_ = data.state
	self.id_ = data.id
	self.in_use_ = data.in_use
	self.isCollection = data.isCollection

	if self.isCollection then
		self.is_new_ = false
	end

	self:updateLayout()
end

function PictureCard:getUIComponent()
	local go = self.go
	self.bgImg = go:ComponentByName("bgImg", typeof(UISprite))
	self.frameImg = go:ComponentByName("frameImg", typeof(UISprite))
	self.lockImg = go:ComponentByName("lockImg", typeof(UISprite))
	self.newImg = go:ComponentByName("newImg", typeof(UISprite))
	self.redIcon = go:ComponentByName("redIcon", typeof(UISprite))

	xyd.setUISpriteAsync(self.lockImg, nil, "background_lock")
	xyd.setUISpriteAsync(self.newImg, nil, "background_new")
end

function PictureCard:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	local data = info
	self.is_new_ = data.is_new
	self.need_red_ = data.need_red
	self.state_ = data.state
	self.id_ = data.id
	self.in_use_ = data.in_use
	self.isCollection = data.isCollection

	if self.isCollection then
		self.is_new_ = false
	end

	self:updateLayout()
end

function PictureCard:updateLayout()
	xyd.setUISpriteAsync(self.bgImg, nil, self:getImgSource(), function ()
	end)
	self.newImg:SetActive(self.is_new_)
	self.redIcon:SetActive(self.need_red_)
	self.lockImg:SetActive(false)

	self.bgImg.alpha = 1

	if self.state_ ~= 2 then
		self.bgImg.alpha = 0.5

		if self.state_ == 0 then
			self.lockImg:SetActive(true)
		end
	end

	self:updateUseState()
end

function PictureCard:updateUseState()
	if self.in_use_ then
		xyd.setUISpriteAsync(self.frameImg, nil, "background_card_bg_small_light", function ()
		end)
	else
		xyd.setUISpriteAsync(self.frameImg, nil, "background_card_bg_small", function ()
		end)
	end
end

function PictureCard:getImgSource()
	return tostring(xyd.tables.customBackgroundTable:getSmallPicture(self.id_))
end

function PictureCard:registerEvent()
	UIEventListener.Get(self.go).onClick = function (go)
		local type = xyd.tables.customBackgroundTable:getType(self.id_)

		xyd.models.background:resetNew(self.id_, type)
		xyd.models.background:resetRed(self.id_)

		local win = xyd.WindowManager.get():getWindow("background_window")

		win:refreshState(self.id_, {})

		local group_win = xyd.WindowManager.get():getWindow("background_group_window")

		if group_win then
			group_win:buildCollection()
		end

		xyd.WindowManager.get():openWindow("background_preview_window", {
			id = self.id_,
			isCollection = self.isCollection
		})
	end
end

function GalleryCard:ctor(go, parent)
	PictureCard.ctor(self, go, parent)
end

function GalleryCard:getUIComponent()
	GalleryCard.super.getUIComponent(self)

	local go = self.go
	self.selectImg = go:ComponentByName("selectImg", typeof(UISprite))
	self.selectTouchGroup = go:NodeByName("selectTouchGroup").gameObject

	xyd.setDragScrollView(self.selectTouchGroup, self.parent:getScrollView())
end

function GalleryCard:setInfo(info)
	PictureCard.setInfo(self, info)

	if self.isCollection then
		self.selectTouchGroup:SetActive(false)
	end
end

function GalleryCard:update(index, realIndex, info)
	PictureCard.update(self, index, realIndex, info)

	if self.isCollection then
		self.selectTouchGroup:SetActive(false)
	end
end

function GalleryCard:updateLayout()
	PictureCard.updateLayout(self)
end

function GalleryCard:updateUseState()
	if self.in_use_ then
		xyd.setUISpriteAsync(self.frameImg, nil, "background_card_bg_small_light", function ()
		end)
		xyd.setUISpriteAsync(self.selectImg, nil, "btn_circle_select", function ()
		end)
	else
		xyd.setUISpriteAsync(self.frameImg, nil, "background_card_bg_small", function ()
		end)
		xyd.setUISpriteAsync(self.selectImg, nil, "btn_circle_unselect", function ()
		end)
	end

	if self.isCollection then
		self.selectImg:SetActive(false)
	end
end

function GalleryCard:registerEvent()
	UIEventListener.Get(self.go).onClick = function (go)
		xyd.models.background:resetNew(self.id_, xyd.BackgroundType.GALLERY)
		xyd.models.background:resetRed(self.id_)

		local win = xyd.WindowManager.get():getWindow("background_window")

		win:refreshState(self.id_, {})

		local group_win = xyd.WindowManager.get():getWindow("background_group_window")

		if group_win then
			group_win:buildCollection()
		end

		xyd.WindowManager.get():openWindow("background_preview_window", {
			id = self.id_,
			isCollection = self.isCollection
		})
	end

	UIEventListener.Get(self.selectTouchGroup).onClick = function (go, isPressed)
		xyd.models.background:reqAddSelect(self.id_)
	end
end

function GalleryGroupCard:ctor(go, parent)
	GalleryGroupCard.super.ctor(self, go)

	self.parent = parent

	self:setDragScrollView(parent:getContainScrollView())
	self:getUIComponent()
	self:registerEvent()
end

function GalleryGroupCard:getUIComponent()
	local go = self.go
	self.bgImg = go:ComponentByName("bgImg", typeof(UISprite))
	self.frameImg = go:ComponentByName("frameImg", typeof(UISprite))
	self.newImg = go:ComponentByName("newImg", typeof(UISprite))
	self.redIcon = go:ComponentByName("redIcon", typeof(UISprite))
	self.nameLabel = go:ComponentByName("nameLabel", typeof(UILabel))

	xyd.setUISpriteAsync(self.frameImg, nil, "background_card_bg_small")
end

function GalleryGroupCard:registerEvent()
	UIEventListener.Get(self.go).onClick = function (go)
		xyd.WindowManager.get():openWindow("background_group_window", {
			group_id = self.group_id_,
			isCollection = self.isCollection
		})
	end
end

function GalleryGroupCard:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.group_id_ = info.group_id
	self.is_new_ = info.is_new
	self.need_red_ = info.need_red
	self.isCollection = info.isCollection

	self:setLayout()
end

function GalleryGroupCard:setLayout()
	xyd.setUISpriteAsync(self.bgImg, nil, self:getBgSrc(), function ()
	end)

	self.nameLabel.text = self:getName()

	self.newImg:SetActive(self.is_new_)
	self.redIcon:SetActive(self.need_red_)
end

function GalleryGroupCard:getBgSrc()
	return tostring(xyd.tables.customBackgroundGroupTable:getCover(self.group_id_))
end

function GalleryGroupCard:getName()
	return xyd.tables.customBackgroundTypeTextTable:getName(self.group_id_)
end

function GalleryGroupItem:ctor(parentGo, params)
	GalleryGroupItem.super.ctor(self, parentGo)

	self.params = params
	self.items = {}

	self:getUIComponent()
	self:setInfos()
end

function GalleryGroupItem:getPrefabPath()
	return "Prefabs/Components/gallery_group_item"
end

function GalleryGroupItem:getUIComponent()
	local go = self.go
	self.groupLabel = go:ComponentByName("groupLabel", typeof(UILabel))
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.item = go:NodeByName("picture_item").gameObject
end

function GalleryGroupItem:setInfos()
	self.groupLabel.text = xyd.tables.customBackgroundTypeTextTable:getName(self.params.group_id)
	local items = self.params.items

	for i = 1, #items do
		local tempGo = NGUITools.AddChild(self.contentGroup, self.item)
		local item = GalleryCard.new(tempGo, self)

		item:setInfo(items[i])
		table.insert(self.items, item)
	end

	self.contentGroup:GetComponent(typeof(UILayout)):Reposition()

	local height = math.ceil(#items / 4) * 260 + 50
	self.go:GetComponent(typeof(UIWidget)).height = height
end

function GalleryGroupItem:update(params)
	self.params = params
	local items = self.params.items

	for i = 1, #items do
		self.items[i]:setInfo(items[i])
	end
end

function GalleryGroupItem:getScrollView()
	return self.parentGo.transform.parent:GetComponent(typeof(UIScrollView))
end

function BackGroundGroupItem:ctor(parentGo, params)
	GalleryGroupItem.super.ctor(self, parentGo)

	self.params = params
	self.items = {}

	self:getUIComponent()
	self:setInfos()
end

function BackGroundGroupItem:getPrefabPath()
	return "Prefabs/Components/background_group_item"
end

function BackGroundGroupItem:getUIComponent()
	local go = self.go
	self.groupLabel = go:ComponentByName("groupLabel", typeof(UILabel))
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.item = go:NodeByName("picture_card").gameObject
end

function BackGroundGroupItem:setInfos()
	self.groupLabel.text = xyd.tables.customBackgroundTypeTextTable:getName(self.params.group_id)
	local items = self.params.items

	for i = 1, #items do
		local tempGo = NGUITools.AddChild(self.contentGroup, self.item)
		local item = PictureCard.new(tempGo, self)

		item:setInfo(items[i])
		table.insert(self.items, item)
	end

	self.contentGroup:GetComponent(typeof(UILayout)):Reposition()

	local height = math.ceil(#items / 4) * 260 + 50
	self.go:GetComponent(typeof(UIWidget)).height = height
end

function BackGroundGroupItem:update(params)
	self.params = params
	local items = self.params.items

	for i = 1, #items do
		self.items[i]:setInfo(items[i])
	end
end

function BackGroundGroupItem:getScrollView()
	return self.parentGo.transform.parent:GetComponent(typeof(UIScrollView))
end

return BackGroundWindow
