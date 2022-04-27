local BaseWindow = import(".BaseWindow")
local CollectionFurnitureWindow = class("CollectionFurnitureWindow", BaseWindow)
local CollectionFurnitureItem = class("CollectionFurnitureItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local HouseShopTapItem = import("app.components.HouseShopTapItem")

function CollectionFurnitureWindow:ctor(name, params)
	CollectionFurnitureWindow.super.ctor(self, name, params)

	self.curSelectGroup = -1
	self.sortType = 1
	self.curPage_ = 1
	self.maxPage_ = 10
	self.collections_ = {}
end

function CollectionFurnitureWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainGroup = winTrans:NodeByName("mainGroup").gameObject
	self.title = mainGroup:NodeByName("title").gameObject
	self.bg_ = mainGroup:ComponentByName("bg_", typeof(UISprite))
	self.topBtns_ = mainGroup:NodeByName("topBtns_").gameObject
	self.content = mainGroup:NodeByName("content").gameObject
	self.filter = mainGroup:NodeByName("filter").gameObject
	self.titleLabel = mainGroup:ComponentByName("title/titleLabel", typeof(UILabel))
	self.btnLeft_ = mainGroup:NodeByName("topBtns_/btnLeft_").gameObject
	self.btnRight_ = mainGroup:NodeByName("topBtns_/btnRight_").gameObject
	self.topTap_ = mainGroup:NodeByName("topBtns_/topTap_").gameObject
	self.boxScroller_ = mainGroup:ComponentByName("content/boxScroller_", typeof(UIScrollView))
	self.furnitureItem = mainGroup:NodeByName("content/boxScroller_/furnitureItem").gameObject
	self.boxItemList_ = mainGroup:NodeByName("content/boxScroller_/boxItemList_").gameObject
	local sortGroup = mainGroup:NodeByName("filter/sortGroup").gameObject
	self.btnTheme_ = sortGroup:NodeByName("btnTheme_").gameObject
	self.btnSort_ = sortGroup:NodeByName("btnSort_").gameObject
	self.chooseGroup = sortGroup:NodeByName("chooseGroup").gameObject

	for i = 1, 3 do
		self["sort" .. tostring(i)] = sortGroup:NodeByName("chooseGroup/sort" .. tostring(i)).gameObject
	end
end

function CollectionFurnitureWindow:initWindow()
	CollectionFurnitureWindow.super.initWindow(self)
	self:getUIComponent()
	self:initTopGroup()
	self:resizeSize()
	self:layout()
	self:initData()
	self:updateItemList()
	self:registerEvent()
end

function CollectionFurnitureWindow:resizeSize()
	local win_top = self.window_:NodeByName("window_top").gameObject
	local PositionY = win_top.transform.localPosition.y

	if PositionY < 650 then
		self.title:SetLocalPosition(0, 480, 0)
		self.topBtns_:SetLocalPosition(0, 380, 0)
		self.bg_:SetLocalPosition(0, -95, 0)

		self.bg_.height = 920

		self.content:Y(-54)

		self.content:GetComponent(typeof(UIWidget)).height = 830

		self.filter:Y(-516)
		self.boxScroller_:SetActive(false)
		self.boxScroller_:SetActive(true)
	end
end

function CollectionFurnitureWindow:layout()
	self.titleLabel.text = __("COLLECTION_FURNITURE_WINDOW")
	self.btnTheme_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_1")
	self.btnSort_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_7")
	self.sort1:ComponentByName("label", typeof(UILabel)).text = __("HOUSE_TEXT_3")
	self.sort2:ComponentByName("label", typeof(UILabel)).text = __("HOUSE_TEXT_4")
	self.sort3:ComponentByName("label", typeof(UILabel)).text = __("HOUSE_TEXT_5")
	local wrapContent = self.boxItemList_:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.boxScroller_, wrapContent, self.furnitureItem, CollectionFurnitureItem, self)

	self:updateSortChosen()
	self:initTopTap()
	self:updateBtn()
end

function CollectionFurnitureWindow:initTopGroup()
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
end

function CollectionFurnitureWindow:updateSortChosen()
	for i = 1, 3 do
		local sort = self["sort" .. tostring(i)]
		local btn = sort:GetComponent(typeof(UIButton))
		local label = sort:ComponentByName("label", typeof(UILabel))

		if i == self.sortType then
			btn:SetEnabled(false)

			label.color = Color.New2(4294967295.0)
			label.effectStyle = UILabel.Effect.Outline
			label.effectColor = Color.New2(1012112383)
		else
			btn:SetEnabled(true)

			label.color = Color.New2(960513791)
			label.effectStyle = UILabel.Effect.None
		end
	end
end

function CollectionFurnitureWindow:initTopTap()
	self.topTapBtns_ = {}
	local tapBtn = self.topTap_:NodeByName("tapBtn").gameObject

	for i = 1, 4 do
		local go = NGUITools.AddChild(self.topTap_, tapBtn)
		local item = HouseShopTapItem.new(go)

		item:setIndex(i)
		item:setInfo({
			page = i,
			type = self:getTypeByPage(i),
			wnd = self
		})

		self.topTapBtns_[i] = item
	end

	self.curTopTapBtnIndex_ = 1
end

function CollectionFurnitureWindow:updateTopTapBtnInfo()
	local num = 0

	if self.curTopTapBtnIndex_ < 1 then
		num = -1
		self.curTopTapBtnIndex_ = 1
	elseif self.curTopTapBtnIndex_ > #self.topTapBtns_ then
		num = 1
		self.curTopTapBtnIndex_ = #self.topTapBtns_
	end

	if num ~= 0 then
		for i = 1, #self.topTapBtns_ do
			local btn = self.topTapBtns_[i]
			local newPage = btn:getPage() + num

			btn:setInfo({
				page = newPage,
				type = self:getTypeByPage(newPage),
				wnd = self
			})
		end
	end
end

function CollectionFurnitureWindow:updateBtn()
	local curPage = self.curPage_

	for _, item in pairs(self.topTapBtns_) do
		if item:getPage() == curPage then
			item:setBtn(true)
		else
			item:setBtn(false)
		end
	end

	self.btnLeft_:GetComponent(typeof(UIButton)):SetEnabled(true)
	self.btnRight_:GetComponent(typeof(UIButton)):SetEnabled(true)

	if curPage == 1 then
		self.btnLeft_:GetComponent(typeof(UIButton)):SetEnabled(false)
	elseif curPage == self.maxPage_ then
		self.btnRight_:GetComponent(typeof(UIButton)):SetEnabled(false)
	end
end

function CollectionFurnitureWindow:initData()
	self.collections_ = {}
	local datas = {}
	local HouseFurnitureTable = xyd.tables.houseFurnitureTable
	local CollectionTable = xyd.tables.collectionTable
	local ids_ = CollectionTable:getIdsListByType(xyd.CollectionTableType.FURNITURE)
	local ids = {}

	for __, id in ipairs(ids_) do
		table.insert(ids, CollectionTable:getItemId(id))
	end

	datas[0] = {}

	for __, id in ipairs(ids) do
		local type_ = HouseFurnitureTable:type(id)
		local group_ = HouseFurnitureTable:groupId(id)

		if self.curSelectGroup == -1 or group_ == self.curSelectGroup then
			if not datas[type_] then
				datas[type_] = {}
			end

			table.insert(datas[0], id)
			table.insert(datas[type_], id)
		end
	end

	local types = xyd.tables.miscTable:split2num("dorm_show_furniture_type", "value", "|")

	table.insert(types, 1, 0)

	for sortType = 1, 3 do
		for __, type_ in ipairs(types) do
			local data = xyd.getCopyData(datas[type_] or {})

			self:sortByType(data, sortType)

			local key = tostring(sortType) .. "|" .. tostring(type_)
			self.collections_[key] = data
		end
	end
end

function CollectionFurnitureWindow:updateItemList()
	local type_ = self:getTypeByPage(self.curPage_)
	local key = tostring(self.sortType) .. "|" .. tostring(type_)
	local collection = self.collections_[key] or nil

	self.wrapContent:setInfos(collection, {})
end

function CollectionFurnitureWindow:registerEvent()
	UIEventListener.Get(self.btnLeft_).onClick = function ()
		self:onBtnTouch(-1)
	end

	UIEventListener.Get(self.btnRight_).onClick = function ()
		self:onBtnTouch(1)
	end

	xyd.setDarkenBtnBehavior(self.btnTheme_, self, function ()
		self:onThemeTouch()
	end)
	xyd.setDarkenBtnBehavior(self.btnSort_, self, function ()
		self:onSortTouch()
	end)

	for i = 1, 3 do
		UIEventListener.Get(self["sort" .. tostring(i)]).onClick = function ()
			self:onSortSelectTouch(i)
		end
	end
end

function CollectionFurnitureWindow:onThemeTouch()
	xyd.openWindow("house_theme_window", {
		callback = function (id)
			if self.curSelectGroup ~= id then
				self.curSelectGroup = id

				self:initData()
				self:updateItemList()
			end
		end
	})
end

function CollectionFurnitureWindow:onSortTouch()
	local img = self.btnSort_:NodeByName("arrow").gameObject
	local scale = img.transform.localScale

	img.transform:SetLocalScale(scale.x, -1 * scale.y, scale.z)

	img.transform.localEulerAngles = -img.transform.localEulerAngles

	self:moveGroupSort()
end

function CollectionFurnitureWindow:onSortSelectTouch(index)
	if self.sortType ~= index then
		self.sortType = index

		self:updateSortChosen()
		self:updateItemList()
		self:onSortTouch()
	end
end

function CollectionFurnitureWindow:onBtnTouch(num)
	if self.curPage_ + num < 1 or self.maxPage_ < self.curPage_ + num then
		return
	end

	self.curPage_ = self.curPage_ + num
	self.curTopTapBtnIndex_ = self.curTopTapBtnIndex_ + num

	self:updateTopTapBtnInfo()
	self:updateBtn()
	self:updateItemList()
end

function CollectionFurnitureWindow:onBtnTouch2(num, index)
	if self.curPage_ == num then
		return
	end

	self.curPage_ = num
	self.curTopTapBtnIndex_ = index

	self:updateBtn()
	self:updateItemList()
end

function CollectionFurnitureWindow:getTypeByPage(page)
	local types = xyd.tables.miscTable:split2num("dorm_show_furniture_type", "value", "|")

	return types[page]
end

function CollectionFurnitureWindow:moveGroupSort()
	local w = self.chooseGroup:GetComponent(typeof(UIWidget))
	local height = w.height
	local transform = self.chooseGroup.transform
	local action = DG.Tweening.DOTween.Sequence()
	local arrow = self.btnSort_:NodeByName("arrow").gameObject
	local scaleY = arrow.transform.localScale.y

	if scaleY == 1 then
		action:Append(transform:DOLocalMove(Vector3(65, height + 17, 0), 0.067)):Append(transform:DOLocalMove(Vector3(65, height - 58, 0), 0.1)):Join(xyd.getTweenAlpha(w, 0.01, 0.1)):AppendCallback(function ()
			self.chooseGroup:SetActive(false)
			transform:SetLocalPosition(65, 0, 0)
		end)
	else
		self.chooseGroup:SetActive(true)

		w.alpha = 0.01

		transform:SetLocalPosition(65, height - 58, 0)
		action:Append(transform:DOLocalMove(Vector3(65, height + 17, 0), 0.1)):Join(xyd.getTweenAlpha(w, 1, 0.1)):Append(transform:DOLocalMove(Vector3(65, height, 0), 0.2))
	end
end

function CollectionFurnitureWindow:updateByBuyFuniture()
	self:initData()
	self:updateItemList()
end

function CollectionFurnitureWindow:updateBySetFuniture(itemIndex)
	local type_ = self:getTypeByPage(self.curPage_)
	local key = tostring(self.sortType) .. "|" .. tostring(type_)
	local collection = self.collections_[key] or nil

	if collection and itemIndex ~= "nil" and itemIndex ~= "nil" then
		-- Nothing
	elseif collection then
		collection:refresh()
	end
end

function CollectionFurnitureWindow:sortByType(data, type_)
	local HouseFurnitureTable = xyd.tables.houseFurnitureTable

	if type_ == 2 then
		table.sort(data, function (a, b)
			local areaA = HouseFurnitureTable:area(a)
			local areaB = HouseFurnitureTable:area(b)
			local areaANum = areaA[1] * areaA[2]
			local areaBNum = areaB[1] * areaB[2]

			if areaANum ~= areaBNum then
				return areaANum < areaBNum
			end

			return a < b
		end)
	elseif type_ == 3 then
		table.sort(data, function (a, b)
			local priceA = HouseFurnitureTable:price(a)
			local priceB = HouseFurnitureTable:price(b)
			local priceANum = priceA[1]
			local priceBNum = priceB[1]

			if priceANum and priceBNum and priceANum ~= priceBNum then
				return priceANum < priceBNum
			end

			return a < b
		end)
	else
		table.sort(data)
	end
end

function CollectionFurnitureWindow:playOpenAnimation(callback)
	callback()

	local bg_ = self.window_.transform:ComponentByName("bg_", typeof(UISprite))
	local bg2_ = self.window_.transform:ComponentByName("bg2_", typeof(UISprite))
	local mainGroup = self.window_.transform:NodeByName("mainGroup").gameObject
	local sequence = self:getSequence()

	mainGroup:X(-self.window_:GetComponent(typeof(UIPanel)).width)
	sequence:Append(mainGroup.transform:DOLocalMoveX(50, 0.3))

	local function setter1(val)
		bg_.alpha = val
		bg2_.alpha = val
	end

	sequence:Join(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.2))
	sequence:Append(mainGroup.transform:DOLocalMoveX(0, 0.27))
	sequence:AppendCallback(function ()
		self:setWndComplete()

		self.isAnimationCompleted = true
	end)
end

function CollectionFurnitureItem:ctor(go, parent)
	CollectionFurnitureItem.super.ctor(self, go, parent)
end

function CollectionFurnitureItem:initUI()
	CollectionFurnitureItem.super:initUI()

	local go = self.go
	self.bg_ = go:ComponentByName("group/bg_", typeof(UISprite))
	self.img_ = go:ComponentByName("group/img_", typeof(UISprite))
	self.labelName_ = go:ComponentByName("group/labelName_", typeof(UILabel))

	xyd.setDragScrollView(self.bg_, self.boxScroller_)
	xyd.setDragScrollView(self.img_, self.boxScroller_)
	xyd.setDragScrollView(self.labelName_, self.boxScroller_)
	self:layout()
	self:registerEvent()
end

function CollectionFurnitureItem:layout()
	if xyd.Global.lang == "de_de" then
		self.labelName_.fontSize = 15
		self.labelName_.width = 120

		self.labelName_:Y(-75)
	end

	if xyd.Global.lang == "en_en" then
		self.labelName_.fontSize = 17

		self.labelName_:Y(-75)

		self.labelName_.width = 130
	end
end

function CollectionFurnitureItem:registerEvent()
	UIEventListener.Get(self.go).onClick = function ()
		self:onClick()
	end
end

function CollectionFurnitureItem:onClick()
	xyd.openWindow("house_item_detail_window", {
		wnd_type = xyd.HouseItemDetailWndType.COLLECTION,
		item_id = self.data,
		itemIndex = self.itemIndex
	})
end

function CollectionFurnitureItem:updateInfo()
	local ItemTable = xyd.tables.itemTable
	local name = ItemTable:getName(self.data)
	self.labelName_.text = name

	xyd.setUISpriteAsync(self.img_, nil, ItemTable:getIcon(self.data), function ()
		self.img_:MakePixelPerfect()
	end)

	if xyd.models.collection:isGot(ItemTable:getCollectionId(self.data)) then
		xyd.applyOrigin(self.img_)
		xyd.applyOrigin(self.bg_)
	else
		xyd.applyGrey(self.img_)
		xyd.applyGrey(self.bg_)
	end
end

return CollectionFurnitureWindow
