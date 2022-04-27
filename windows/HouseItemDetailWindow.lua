local HouseItemDetailWindow = class("HouseItemDetailWindow", import(".BaseWindow"))
local HouseFurnitureTable = xyd.tables.houseFurnitureTable
local ItemTable = xyd.tables.itemTable
local Backpack = xyd.models.backpack
local SelectNum = import("app.components.SelectNum")

function HouseItemDetailWindow:ctor(name, params)
	HouseItemDetailWindow.super.ctor(self, name, params)

	self.itemID_ = 0
	self.purchaseNum = 0
	self.maxCanBuy = 0
	self.curWndType_ = params.wnd_type or xyd.HouseItemDetailWndType.NOAMAL
	self.itemID_ = params.item_id
	self.maxCanBuy = params.max_can_buy or 0
end

function HouseItemDetailWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.bg_ = winTrans:ComponentByName("groupAction/bg_", typeof(UISprite))
	self.contentGroup = winTrans:NodeByName("groupAction/contentGroup").gameObject
	self.btnSet_ = winTrans:NodeByName("groupAction/btnSet_").gameObject
	self.groupShop = winTrans:NodeByName("groupAction/groupShop").gameObject
	self.collection = winTrans:NodeByName("groupAction/collection").gameObject
	self.labelName_ = self.contentGroup:ComponentByName("labelName_", typeof(UILabel))
	self.iconComfort = self.contentGroup:NodeByName("iconComfort").gameObject
	self.labelComfortNum_ = self.contentGroup:ComponentByName("labelComfortNum_", typeof(UILabel))
	self.imgItem_ = self.contentGroup:ComponentByName("imgItem_", typeof(UISprite))
	self.bottom = self.contentGroup:NodeByName("e:Group").gameObject
	self.bottomBg_ = self.contentGroup:ComponentByName("e:Group/bottomBg_", typeof(UISprite))
	self.labelTips1_ = self.contentGroup:ComponentByName("e:Group/groupTips1/labelTips1_", typeof(UILabel))
	self.labelType_ = self.contentGroup:ComponentByName("e:Group/groupTips1/labelType_", typeof(UILabel))
	self.labelTips2_ = self.contentGroup:ComponentByName("e:Group/groupTips2/labelTips2_", typeof(UILabel))
	self.labelArea_ = self.contentGroup:ComponentByName("e:Group/groupTips2/labelArea_", typeof(UILabel))
	self.labelTips3_ = self.contentGroup:ComponentByName("e:Group/groupTips3/labelTips3_", typeof(UILabel))
	self.labelDesc_ = self.contentGroup:ComponentByName("e:Group/groupTips3/labelDesc_", typeof(UILabel))
	self.selectNumPos = self.groupShop:NodeByName("selectNumPos").gameObject
	self.labelTotal_ = self.groupShop:ComponentByName("labelTotal_", typeof(UILabel))
	self.btnBuy_ = self.groupShop:NodeByName("btnBuy_").gameObject
	self.imgExchang_ = self.groupShop:ComponentByName("imgExchang_", typeof(UISprite))
	self.gotImg = self.collection:ComponentByName("gotImg", typeof(UISprite))
	self.resItem = self.collection:NodeByName("resItem").gameObject
	self.getWaysDesLabel = self.collection:ComponentByName("getWaysDesLabel", typeof(UILabel))
	self.btnZoom = self.collection:NodeByName("btnZoom").gameObject
end

function HouseItemDetailWindow:initWindow()
	HouseItemDetailWindow.super.initWindow(self)
	self:getUIComponent()
	self:resizeSize()
	self:layout()
	self:registerEvent()
	self:updateByLang()
end

function HouseItemDetailWindow:resizeSize()
	if self.curWndType_ == xyd.HouseItemDetailWndType.SET then
		self.bg_.height = 562

		self.contentGroup:SetLocalPosition(0, 36, 0)
		self.btnSet_:SetActive(true)
	elseif self.curWndType_ == xyd.HouseItemDetailWndType.SHOP then
		self.bg_.height = 682

		self.contentGroup:SetLocalPosition(0, 100, 0)
		self.groupShop:SetActive(true)
	elseif self.curWndType_ == xyd.HouseItemDetailWndType.COLLECTION then
		self.bg_.height = 562

		self.contentGroup:SetLocalPosition(0, 36, 0)
		self.labelComfortNum_:SetActive(false)
		self:initCollection()
	else
		self.bg_.height = 482

		self.contentGroup:SetLocalPosition(0, 0, 0)
	end
end

function HouseItemDetailWindow:updateByLang()
	if xyd.Global.lang == "fr_fr" then
		-- Nothing
	end
end

function HouseItemDetailWindow:layout()
	local table = HouseFurnitureTable
	self.labelName_.text = ItemTable:getName(self.itemID_)
	self.labelComfortNum_.text = "" .. tostring(table:comfort(self.itemID_))
	self.labelType_.text = __("HOUSE_ITEM_TYPE_" .. tostring(table:type(self.itemID_)))
	local area = table:area(self.itemID_)
	local areaStr = ""
	areaStr = table:type(self.itemID_) == xyd.HouseItemType.BACKGROUND and "-" or tostring(area[1]) .. "*" .. tostring(area[2])
	self.labelArea_.text = areaStr
	self.labelDesc_.text = ItemTable:getDesc(self.itemID_)
	self.labelTips1_.text = __("HOUSE_ITEM_TIPS_1")
	self.labelTips2_.text = __("HOUSE_ITEM_TIPS_2")
	self.labelTips3_.text = __("HOUSE_ITEM_TIPS_3")

	xyd.setUISpriteAsync(self.imgItem_, xyd.Atlas.HOUSE_FURNITURE, ItemTable:getIcon(self.itemID_))

	local price = HouseFurnitureTable:price(self.itemID_)
	local icon = ItemTable:getIcon(price[1])

	xyd.setUISpriteAsync(self.imgExchang_, xyd.Atlas.ICON, icon)

	self.btnBuy_:ComponentByName("button_label", typeof(UILabel)).text = __("BUY2")
	self.btnSet_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_SETTING")

	if self.curWndType_ == xyd.HouseItemDetailWndType.SHOP then
		self:initSelectNum()
	end
end

function HouseItemDetailWindow:initSelectNum()
	self.selectNum_ = SelectNum.new(self.selectNumPos, "default")
	local price = HouseFurnitureTable:price(self.itemID_)
	local maxCanBuy = self.maxCanBuy

	local function addCallback()
		if maxCanBuy < self.purchaseNum then
			self.purchaseNum = maxCanBuy

			self.selectNum_:setCurNum(maxCanBuy)

			self.purchaseNum = maxCanBuy

			self:updateCost()
		end
	end

	local function callback(input)
		self.purchaseNum = input

		self:updateCost()
	end

	local params = {
		curNum = 1,
		callback = callback,
		addCallback = addCallback
	}
	self.purchaseNum = 1

	self:updateCost()
	self.selectNum_:setInfo(params)
	self.selectNum_:setPrompt(self.purchaseNum)
	self.selectNum_:setKeyboardPos(0, -350)
end

function HouseItemDetailWindow:updateCost()
	local price = HouseFurnitureTable:price(self.itemID_)
	local costItemID = price[1]
	local costNum = price[2]
	self.labelTotal_.text = xyd.getRoughDisplayNumber(costNum * self.purchaseNum)
	local total = Backpack:getItemNumByID(costItemID)

	if total < costNum * self.purchaseNum then
		self.labelTotal_.color = Color.New2(3422556671.0)
	else
		self.labelTotal_.color = Color.New2(1583978239)
	end
end

function HouseItemDetailWindow:registerEvent()
	UIEventListener.Get(self.btnBuy_).onClick = handler(self, self.onBuyTouch)
	UIEventListener.Get(self.btnSet_).onClick = handler(self, self.onSetTouch)
end

function HouseItemDetailWindow:onBuyTouch()
	local price = HouseFurnitureTable:price(self.itemID_)
	local costItemID = price[1]
	local costNum = price[2]
	self.labelTotal_.text = xyd.getRoughDisplayNumber(costNum * self.purchaseNum)
	local total = Backpack:getItemNumByID(costItemID)

	if xyd.isItemAbsence(costItemID, costNum * self.purchaseNum) then
		return false
	end

	local num = self.purchaseNum
	local id = xyd.tables.shopHouseFurnitureTable:idByItemID(self.itemID_)

	xyd.models.house:saveBuyItemInfo({
		item_id = self.itemID_,
		item_num = num
	})
	xyd.models.shop:buyShopItem(xyd.ShopType.SHOP_HOUSE_FURNITURE, id, num)
	xyd.WindowManager.get():closeWindow(self.name_)
end

function HouseItemDetailWindow:onSetTouch()
	local houseMap = xyd.HouseMap.get()

	if houseMap:checkCanAddNewItem(self.itemID_) then
		local wnd = xyd.WindowManager.get():getWindow("house_window")

		houseMap:setNeedSave(true)

		if HouseFurnitureTable:type(self.itemID_) == xyd.HouseItemType.BACKGROUND then
			houseMap:setHouseBackground(self.itemID_)

			if wnd then
				wnd:updateHouseBox()
			end

			xyd.WindowManager.get():closeWindow(self.name_)

			return
		end

		local item = houseMap:addNewItem(self.itemID_)
		local flag = houseMap:touchItem(item)

		if flag then
			item:showEffect(false)
			item:changeStaus(true)
		end

		houseMap:checkSpecialFurniture()

		if wnd then
			wnd:updateHouseBox()
			wnd:moveToSelectItem(item)
		end

		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function HouseItemDetailWindow:initCollection()
	self.bottomBg_.height = 240

	self.labelName_:Y(175)
	self.bottom:Y(-180)
	self.collection:SetActive(true)
	self.iconComfort:SetActive(false)

	local collectionId = xyd.tables.itemTable:getCollectionId(self.itemID_)
	local gotStr = "collection_got_" .. xyd.Global.lang
	local noGotStr = "collection_no_get_" .. xyd.Global.lang
	local getWayStr = xyd.tables.collectionTextTable:getDesc(collectionId)
	local group1 = self.contentGroup:NodeByName("e:Group/groupTips1").gameObject
	local group2 = self.contentGroup:NodeByName("e:Group/groupTips2").gameObject
	local group3 = self.contentGroup:NodeByName("e:Group/groupTips3").gameObject
	local group4 = self.contentGroup:NodeByName("e:Group/groupTips4").gameObject
	local labelTips4_ = self.contentGroup:ComponentByName("e:Group/groupTips4/labelTips4_", typeof(UILabel))
	local labelComfortNum_2 = self.contentGroup:ComponentByName("e:Group/groupTips4/labelComfortNum_2", typeof(UILabel))
	local labelRes = self.resItem:ComponentByName("labelRes", typeof(UILabel))

	group1:SetLocalPosition(8.9, 93, 0)
	group2:SetLocalPosition(-253, 50, 0)
	group3:SetLocalPosition(-189, 7, 0)
	group4:SetActive(true)

	labelTips4_.text = __("HOUSE_ITEM_TIPS_4")
	labelComfortNum_2.text = xyd.tables.houseFurnitureTable:comfort(self.itemID_)
	labelRes.text = xyd.tables.collectionTable:getCoin(collectionId)
	self.getWaysDesLabel.text = __("GET_WAYS_TOP_WORDS", getWayStr)

	if xyd.models.collection:isGot(collectionId) then
		xyd.setUISpriteAsync(self.gotImg, nil, gotStr)
	else
		xyd.setUISpriteAsync(self.gotImg, nil, noGotStr)
	end

	UIEventListener.Get(self.btnZoom).onClick = function ()
		xyd.openWindow("furniture_zoom_window", {
			itemId = self.itemID_
		})
	end
end

return HouseItemDetailWindow
