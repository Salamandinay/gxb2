local HouseShopItem = class("HouseShopItem")
local HouseFurnitureTable = xyd.tables.houseFurnitureTable
local ItemTable = xyd.tables.itemTable

function HouseShopItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	xyd.setDragScrollView(go, parent.scrollView)
	self:initUI()
end

function HouseShopItem:initUI()
	self.labelName_ = self.go:ComponentByName("labelName_", typeof(UILabel))
	self.labelComfort_ = self.go:ComponentByName("labelComfort_", typeof(UILabel))
	self.labelItemNum_ = self.go:ComponentByName("labelItemNum_", typeof(UILabel))
	self.labelCostNum_ = self.go:ComponentByName("labelCostNum_", typeof(UILabel))
	self.groupMask_ = self.go:NodeByName("groupMask_").gameObject
	self.labelHasBuy_ = self.groupMask_:ComponentByName("labelHasBuy_", typeof(UILabel))
	self.imgCoin_ = self.go:ComponentByName("imgCoin_", typeof(UISprite))
	self.img_ = self.go:ComponentByName("img_", typeof(UISprite))

	self:layout()
	self:registerEvent()
end

function HouseShopItem:getGameObject()
	return self.go
end

function HouseShopItem:layout()
	self.labelHasBuy_.text = __("ALREADY_BUY")

	if xyd.Global.lang == "de_de" then
		self.labelName_.fontSize = 20
	end
end

function HouseShopItem:registerEvent()
	UIEventListener.Get(self.go).onClick = handler(self, self.onClick)
end

function HouseShopItem:update(wrapIndex, index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data = info
	local itemId = self.data.item[1]
	self.labelName_.text = ItemTable:getName(itemId)
	local itemIcon = ItemTable:getIcon(itemId)

	xyd.setUISpriteAsync(self.img_, nil, itemIcon)

	self.labelComfort_.text = tostring(HouseFurnitureTable:comfort(itemId))
	local buyNum = self.data.buy_times or 0
	local limit = HouseFurnitureTable:limit(itemId)

	if limit > 1 then
		self.labelItemNum_:SetActive(true)
	else
		self.labelItemNum_:SetActive(false)
	end

	self.labelItemNum_.text = tostring(buyNum) .. "/" .. tostring(limit)

	if limit <= buyNum then
		self.groupMask_:SetActive(true)
	else
		self.groupMask_:SetActive(false)
	end

	local cost = HouseFurnitureTable:price(itemId)
	self.labelCostNum_.text = cost[2]
	local icon = ItemTable:getSmallIconNew(cost[1])

	xyd.setUISpriteAsync(self.imgCoin_, nil, icon)
end

function HouseShopItem:onClick()
	local itemId = self.data.item[1]
	local buyNum = self.data.buy_times or 0
	local limit = HouseFurnitureTable:limit(itemId)
	local type_ = xyd.HouseItemDetailWndType.SHOP

	if limit <= buyNum then
		type_ = xyd.HouseItemDetailWndType.NOAMAL
	end

	xyd.WindowManager.get():openWindow("house_item_detail_window", {
		wnd_type = type_,
		max_can_buy = limit - buyNum,
		item_id = itemId,
		itemIndex = self.itemIndex
	})
end

local HouseShopWindow = class("HouseShopWindow", import(".BaseShop"))
local HouseShopTapItem = import("app.components.HouseShopTapItem")
local MiscTable = xyd.tables.miscTable
local ResItem = import("app.components.ResItem")

function HouseShopWindow:ctor(name, params)
	HouseShopWindow.super.ctor(self, name, params)

	self.sortType = 1
	self.curSelectGroup = -1
	self.curPage_ = 1
	local types = MiscTable:split2num("dorm_show_furniture_type", "value", "|")
	self.maxPage_ = #types
	self.collections_ = {}
end

function HouseShopWindow:initWindow()
	HouseShopWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function HouseShopWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle_ = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.groupBtn = groupAction:NodeByName("groupBtn").gameObject
	self.btnTheme_ = self.groupBtn:NodeByName("btnTheme_").gameObject
	self.btnThemeRedMark = self.btnTheme_:ComponentByName("redMark", typeof(UISprite))
	self.btnSort_ = self.groupBtn:NodeByName("btnSort_").gameObject
	self.groupSort_ = self.groupBtn:NodeByName("groupSort_").gameObject
	self.sort1 = self.groupSort_:NodeByName("sort1").gameObject
	self.sort2 = self.groupSort_:NodeByName("sort2").gameObject
	self.sort3 = self.groupSort_:NodeByName("sort3").gameObject
	self.sort4 = self.groupSort_:NodeByName("sort4").gameObject
	self.resItem1 = groupAction:NodeByName("resItem1").gameObject
	self.resItem2 = groupAction:NodeByName("resItem2").gameObject
	self.btnLeft_ = groupAction:NodeByName("topBtns_/btnLeft_").gameObject
	self.btnRight_ = groupAction:NodeByName("topBtns_/btnRight_").gameObject
	self.topTap_ = groupAction:NodeByName("topBtns_/topTap_").gameObject
	local scrollView = groupAction:ComponentByName("scroller_", typeof(UIScrollView))
	local wrapContent = scrollView:ComponentByName("itemList_", typeof(MultiRowWrapContent))
	local houseShopItem = scrollView:NodeByName("house_shop_item").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(scrollView, wrapContent, houseShopItem, HouseShopItem, self)
end

function HouseShopWindow:onShopInfo()
	self.shopInfo_ = self.shopModel_:getShopInfo(self.shopType_)

	if not self.shopInfo_ then
		return
	end

	if xyd.Global.lang == "fr_fr" then
		-- Nothing
	end

	self:initData()
	self:updateItemList()
	self:updateShopRed()
end

function HouseShopWindow:updateShopRed()
	self.btnThemeRedMark:SetActive(xyd.models.house:getShopRedPoint())

	local win = xyd.WindowManager.get():getWindow("house_window")

	if win then
		win:updateShopRed()
	end
end

function HouseShopWindow:layout()
	self.btnSort_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_7")

	if xyd.Global.lang == "de_de" then
		self.btnSort_:ComponentByName("button_label", typeof(UILabel)).fontSize = 18

		self.btnSort_:ComponentByName("button_label", typeof(UILabel)):X(-10)
		self.btnSort_:NodeByName("buttom_img").gameObject:X(43)
	end

	self.btnTheme_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_1")
	self.labelTitle_.text = __("HOUSE_TEXT_14")
	self.sort1:ComponentByName("labelTips", typeof(UILabel)).text = __("HOUSE_TEXT_3")
	self.sort2:ComponentByName("labelTips", typeof(UILabel)).text = __("HOUSE_TEXT_4")
	self.sort3:ComponentByName("labelTips", typeof(UILabel)).text = __("HOUSE_TEXT_5")
	self.sort4:ComponentByName("labelTips", typeof(UILabel)).text = __("HOUSE_TEXT_64")

	self:updateSortChosen()
	self:initResItem()
	self:initTopTap()
	self:updateBtn()
	self:onShopInfo()
end

function HouseShopWindow:initResItem()
	local item = ResItem.new(self.resItem1, xyd.ItemID.HOUSE_COIN)

	item:setInfo({
		tableId = xyd.ItemID.HOUSE_COIN,
		bgSize = {
			w = 180,
			h = 36
		}
	})
	item:hidePlus()
	item:setResNumLabelPosx(70)

	local item2 = ResItem.new(self.resItem2, xyd.ItemID.CRYSTAL)

	item2:setInfo({
		tableId = xyd.ItemID.CRYSTAL,
		bgSize = {
			w = 180,
			h = 36
		}
	})
	table.insert(self.resItemList, item)
	table.insert(self.resItemList, item2)
end

function HouseShopWindow:registerEvent()
	self:register()

	for i = 1, 4 do
		UIEventListener.Get(self["sort" .. i]).onClick = function ()
			self:onSortSelectTouch(i)
		end
	end

	UIEventListener.Get(self.btnLeft_).onClick = function ()
		self:onBtnTouch(-1)
	end

	UIEventListener.Get(self.btnRight_).onClick = function ()
		self:onBtnTouch(1)
	end

	UIEventListener.Get(self.btnSort_).onClick = handler(self, self.onSortTouch)
	UIEventListener.Get(self.btnTheme_).onClick = handler(self, self.onThemeTouch)

	xyd.models.redMark:setMarkImg(xyd.RedMarkType.HOUSE_SHOP, self.btnThemeRedMark)
end

function HouseShopWindow:buyItemRes(event)
	self:initData()
	self:updateItemList({
		keepPosition = true
	})

	local item = xyd.models.house:getBuyItemInfo()

	xyd.alertItems({
		item
	})
end

function HouseShopWindow:onThemeTouch()
	xyd.WindowManager.get():openWindow("house_theme_window", {
		enterType = "shop",
		callback = function (id)
			if self.curSelectGroup ~= id then
				self.curSelectGroup = id

				self:initData()
				self:updateItemList()
			end
		end
	})
end

function HouseShopWindow:onSortTouch()
	local img = self.btnSort_:NodeByName("buttom_img").gameObject
	local scale = img.transform.localScale

	img.transform:SetLocalScale(scale.x, -1 * scale.y, scale.z)
	self:moveGroupSort()
end

function HouseShopWindow:onSortSelectTouch(index)
	if self.sortType ~= index then
		self.sortType = index

		self:updateSortChosen()
		self:updateItemList()
		self:onSortTouch()
	end
end

function HouseShopWindow:updateSortChosen()
	for i = 1, 4 do
		local sort = self["sort" .. tostring(i)]
		local btn = sort:GetComponent(typeof(UIButton))
		local label = sort:ComponentByName("labelTips", typeof(UILabel))

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

function HouseShopWindow:onBtnTouch(num)
	if self.curPage_ + num < 1 or self.maxPage_ < self.curPage_ + num then
		return
	end

	self.curTopTapBtnIndex_ = self.curTopTapBtnIndex_ + num
	self.curPage_ = self.curPage_ + num

	self:updateTopTapBtnInfo()
	self:updateBtn()
	self:updateItemList()
end

function HouseShopWindow:onBtnTouch2(num, index)
	if self.curPage_ == num then
		return
	end

	self.curPage_ = num
	self.curTopTapBtnIndex_ = index

	self:updateBtn()
	self:updateItemList()
end

function HouseShopWindow:getTypeByPage(page)
	local types = MiscTable:split2num("dorm_show_furniture_type", "value", "|")

	return types[page]
end

function HouseShopWindow:initTopTap()
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

function HouseShopWindow:updateTopTapBtnInfo()
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

function HouseShopWindow:updateBtn()
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

function HouseShopWindow:moveGroupSort()
	local w = self.groupSort_:GetComponent(typeof(UIWidget))
	local height = w.height
	local transform = self.groupSort_.transform
	local action = DG.Tweening.DOTween.Sequence()
	local img = self.btnSort_:NodeByName("buttom_img").gameObject
	local scaleY = img.transform.localScale.y

	if scaleY == 1 then
		action:Append(transform:DOLocalMove(Vector3(131, height + 17, 0), 0.067)):Append(transform:DOLocalMove(Vector3(131, height - 58, 0), 0.1)):Join(xyd.getTweenAlpha(w, 0.01, 0.1)):AppendCallback(function ()
			self.groupSort_:SetActive(false)
			transform:SetLocalPosition(131, 0, 0)
		end)
	else
		self.groupSort_:SetActive(true)

		w.alpha = 0.01

		transform:SetLocalPosition(131, height - 58, 0)
		action:Append(transform:DOLocalMove(Vector3(131, height + 17, 0), 0.1)):Join(xyd.getTweenAlpha(w, 1, 0.1)):Append(transform:DOLocalMove(Vector3(131, height, 0), 0.2))
	end
end

function HouseShopWindow:initData()
	self.collections_ = {}
	local datas = {
		[0] = {}
	}
	local items = self.shopInfo_.items or {}

	for _, item in ipairs(items) do
		local id = item.item[1]
		local type_ = HouseFurnitureTable:type(id)
		local group_ = HouseFurnitureTable:groupId(id)

		if type_ and type_ >= 0 and self.curSelectGroup == -1 or group_ == self.curSelectGroup then
			if not datas[type_] then
				datas[type_] = {}
			end

			table.insert(datas[type_], item)
			table.insert(datas[0], item)
		end
	end

	local types = MiscTable:split2num("dorm_show_furniture_type", "value", "|")

	for sortType = 1, 4 do
		for _, type_ in ipairs(types) do
			local data = xyd.getCopyData(datas[type_] or {})

			self:sortByType(data, sortType)

			local key = tostring(sortType) .. "|" .. tostring(type_)
			self.collections_[key] = data
		end
	end
end

function HouseShopWindow:sortByLimit(data)
end

function HouseShopWindow:sortByType(data, type_)
	if type_ == 1 then
		table.sort(data, function (a, b)
			local idA = a.item[1]
			local idB = b.item[1]
			local numA = a.buy_times or 0
			local limitA = HouseFurnitureTable:limit(idA)
			local valA = limitA <= numA and 0 or 10
			local numB = b.buy_times or 0
			local limitB = HouseFurnitureTable:limit(idB)
			local valB = limitB <= numB and 0 or 10

			if valA ~= valB then
				return valB < valA
			end

			return idB < idA
		end)
	elseif type_ == 2 then
		table.sort(data, function (a, b)
			local idA = a.item[1]
			local idB = b.item[1]
			local numA = a.buy_times or 0
			local limitA = HouseFurnitureTable:limit(idA)
			local valA = limitA <= numA and 0 or 10
			local numB = b.buy_times or 0
			local limitB = HouseFurnitureTable:limit(idB)
			local valB = limitB <= numB and 0 or 10
			local areaA = HouseFurnitureTable:area(idA)
			local areaB = HouseFurnitureTable:area(idB)
			local areaANum = areaA[1] * areaA[2]
			local areaBNum = areaB[1] * areaB[2]

			if areaANum ~= areaBNum then
				return areaANum < areaBNum
			end

			if valA ~= valB then
				return valB < valA
			end

			return idB < idA
		end)
	elseif type_ == 3 then
		table.sort(data, function (a, b)
			local idA = a.item[1]
			local idB = b.item[1]
			local numA = a.buy_times or 0
			local limitA = HouseFurnitureTable:limit(idA)
			local valA = limitA <= numA and 0 or 10
			local numB = b.buy_times or 0
			local limitB = HouseFurnitureTable:limit(idB)
			local valB = limitB <= numB and 0 or 10
			local priceA = HouseFurnitureTable:price(idA)
			local priceB = HouseFurnitureTable:price(idB)
			local priceANum = priceA[2] or 0
			local priceBNum = priceB[2] or 0

			if priceANum ~= priceBNum then
				return priceANum < priceBNum
			end

			if valA ~= valB then
				return valB < valA
			end

			return idB < idA
		end)
	elseif type_ == 4 then
		table.sort(data, function (a, b)
			local idA = a.item[1]
			local idB = b.item[1]
			local numA = a.buy_times or 0
			local limitA = HouseFurnitureTable:limit(idA)
			local valA = limitA <= numA and 0 or 10
			local numB = b.buy_times or 0
			local limitB = HouseFurnitureTable:limit(idB)
			local valB = limitB <= numB and 0 or 10

			if numA == 0 and numB ~= 0 or numA ~= 0 and numB == 0 then
				return numA < numB
			else
				if valA ~= valB then
					return valB < valA
				end

				return idB < idA
			end
		end)
	end
end

function HouseShopWindow:updateItemList(params)
	local type_ = self:getTypeByPage(self.curPage_)
	local key = tostring(self.sortType) .. "|" .. tostring(type_)
	local collection = self.collections_[key] or {}

	self.multiWrap_:setInfos(collection, params or {})
end

return HouseShopWindow
