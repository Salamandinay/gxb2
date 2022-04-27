local BaseWindow = import(".BaseWindow")
local BuySeniorScrollWindow = class("BuySeniorScrollWindow", BaseWindow)
local ResItem = import("app.components.ResItem")

function BuySeniorScrollWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.curOne_ = 1
	self.curTen_ = 1
	self.skinName = "BuySeniorScrollWindowSkin"
end

function BuySeniorScrollWindow:initWindow()
	self:getComponentUI()
	BaseWindow.initWindow(self)
	self:setText()
	self:setResItem()
	self:setSelectNum()
	self:setItemIcon()
	self:register()
end

function BuySeniorScrollWindow:getComponentUI()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle_ = self.groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.groupOne_ = self.groupAction:NodeByName("groupOne_").gameObject
	self.btnBuyOne_ = self.groupOne_:NodeByName("btnBuyOne_").gameObject
	self.btnBuyOne_button_label = self.groupOne_:ComponentByName("btnBuyOne_/button_label", typeof(UILabel))
	self.itemOne_ = self.groupOne_:NodeByName("itemOne_").gameObject
	self.egroupOne = self.groupOne_:NodeByName("e:Group").gameObject
	self.eImageOne = self.groupOne_:ComponentByName("e:Group/e:Image", typeof(UISprite))
	self.labelOneCost_ = self.groupOne_:ComponentByName("e:Group/labelOneCost_", typeof(UILabel))
	self.groupTen_ = self.groupAction:NodeByName("groupTen_").gameObject
	self.btnBuyTen_ = self.groupTen_:NodeByName("btnBuyTen_").gameObject
	self.btnBuyTen__button_label = self.groupTen_:ComponentByName("btnBuyTen_/button_label", typeof(UILabel))
	self.itemTen_ = self.groupTen_:NodeByName("itemTen_").gameObject
	self.egroupTen = self.groupTen_:NodeByName("e:Group").gameObject
	self.eImageTen = self.groupTen_:ComponentByName("e:Group/e:Image", typeof(UISprite))
	self.labelTenCost_ = self.groupTen_:ComponentByName("e:Group/labelTenCost_", typeof(UILabel))
	self.selectNumBuyOne_ = self.groupAction:NodeByName("selectNumBuyOne_").gameObject
	self.selectNumBuyTen_ = self.groupAction:NodeByName("selectNumBuyTen_").gameObject
	self.resItem01_ = self.groupAction:NodeByName("resGroup/resItem01_").gameObject
	self.resItem02_ = self.groupAction:NodeByName("resGroup/resItem02_").gameObject
end

function BuySeniorScrollWindow:setText()
	self.labelTitle_.text = __("BUY_SENIOR_SCROLL_TEXT01")
	self.btnBuyOne_button_label.text = __("BUY")
	self.btnBuyTen__button_label.text = __("BUY")
end

function BuySeniorScrollWindow:setResItem()
	if not self.resItem1 and not self.resItem2 then
		self.resItem1 = ResItem.new(self.resItem01_)
		self.resItem2 = ResItem.new(self.resItem02_)

		self.resItem2:hidePlus()
	end

	self.resItem1:setInfo({
		tableId = xyd.ItemID.CRYSTAL
	})
	self.resItem2:setInfo({
		tableId = xyd.ItemID.SENIOR_SUMMON_SCROLL
	})

	if not self.isFirstUpdateSelect then
		self.isFirstUpdateSelect = true
	else
		self:updateSelectNum()
	end
end

function BuySeniorScrollWindow:setSelectNum()
	local onePrice = xyd.tables.summonTable:getCost(xyd.SummonType.SENIOR_CRYSTAL)[2]
	local tenPrice = xyd.tables.summonTable:getCost(xyd.SummonType.SENIOR_CRYSTAL_TEN)[2]
	local crystal = xyd.models.backpack:getCrystal()
	self.limit = xyd.tables.itemTable:stackLimit(xyd.ItemID.SENIOR_SUMMON_SCROLL) - xyd.models.backpack:getItemNumByID(xyd.ItemID.SENIOR_SUMMON_SCROLL)
	local maxOneNum = math.min(math.floor(crystal / onePrice), self.limit)
	local maxTenNum = math.min(math.floor(crystal / tenPrice), math.ceil(self.limit / 10))
	local SelectNum = import("app.components.SelectNum")
	self.selectNumBuyOne = SelectNum.new(self.selectNumBuyOne_, "default")
	self.selectNumBuyTen = SelectNum.new(self.selectNumBuyTen_, "default")

	self.selectNumBuyOne:setSelectBGSize(136)
	self.selectNumBuyOne:setKeyboardPos(105, -235)
	self.selectNumBuyTen:setSelectBGSize(136)
	self.selectNumBuyTen:setKeyboardPos(-105, -235)
	self:updateSelectNum()
end

function BuySeniorScrollWindow:updateSelectNum()
	self.tableOnePrice = xyd.tables.summonTable:getCost(xyd.SummonType.SENIOR_CRYSTAL)[2]
	self.tableTenPrice = xyd.tables.summonTable:getCost(xyd.SummonType.SENIOR_CRYSTAL_TEN)[2]
	local crystal = xyd.models.backpack:getCrystal()
	self.limit = xyd.tables.itemTable:stackLimit(xyd.ItemID.SENIOR_SUMMON_SCROLL) - xyd.models.backpack:getItemNumByID(xyd.ItemID.SENIOR_SUMMON_SCROLL)
	self.maxOneNum = math.min(math.floor(crystal / self.tableOnePrice), self.limit)
	self.maxTenNum = math.min(math.floor(crystal / self.tableTenPrice), math.ceil(self.limit / 10))

	self.selectNumBuyOne:setInfo({
		minNum = 1,
		curNum = 1,
		maxNum = self.maxOneNum,
		callback = function (num)
			self:callbackOne(num)
		end
	})
	self.selectNumBuyTen:setInfo({
		minNum = 1,
		curNum = 1,
		maxNum = self.maxTenNum,
		callback = function (num)
			self:callbackTen(num)
		end
	})
end

function BuySeniorScrollWindow:callbackOne(num)
	if num == 0 then
		num = 1
	end

	self.selectNumBuyTen:onSure()

	self.curOne_ = num
	self.onePrice = num * self.tableOnePrice

	if num == 0 then
		self.onePrice = self.tableOnePrice
	end

	self.labelOneCost_.text = self.onePrice

	if num == 0 or self.maxOneNum < num and self.limit ~= 0 then
		self.labelOneCost_.color = Color.New2(4278190335.0)
	else
		self.labelOneCost_.color = Color.New2(1432789759)
	end
end

function BuySeniorScrollWindow:callbackTen(num)
	if num == 0 then
		num = 1
	end

	self.selectNumBuyOne:onSure()

	self.curTen_ = num
	self.tenPrice = self.tableTenPrice * num

	if num == 0 then
		self.tenPrice = self.tableTenPrice
	end

	self.labelTenCost_.text = self.tenPrice

	if num == 0 or self.maxTenNum < num and self.limit ~= 0 then
		self.labelTenCost_.color = Color.New2(4278190335.0)
	else
		self.labelTenCost_.color = Color.New2(1432789759)
	end
end

function BuySeniorScrollWindow:setItemIcon()
	xyd.getItemIcon({
		uiRoot = self.itemOne_,
		itemID = xyd.ItemID.SENIOR_SUMMON_SCROLL
	})
	xyd.getItemIcon({
		num = 10,
		uiRoot = self.itemTen_,
		itemID = xyd.ItemID.SENIOR_SUMMON_SCROLL
	})
end

function BuySeniorScrollWindow:register()
	BaseWindow.register(self)

	UIEventListener.Get(self.btnBuyOne_).onClick = function ()
		self:buySeniorScroll(1)
	end

	UIEventListener.Get(self.btnBuyTen_).onClick = function ()
		self:buySeniorScroll(10)
	end

	self.eventProxy_:addEventListener(xyd.event.ITEM_EXCHANGE, handler(self, self.setResItem))
end

function BuySeniorScrollWindow:buySeniorScroll(rate)
	local num, price, allNum = nil
	local crystal = xyd.models.backpack:getCrystal()

	if rate == 1 then
		num = self.curOne_
		allNum = num
		price = self.onePrice
	else
		num = self.curTen_
		allNum = num * 10
		price = self.tenPrice
	end

	if self.limit == 0 or xyd.tables.itemTable:stackLimit(xyd.ItemID.SENIOR_SUMMON_SCROLL) <= xyd.models.backpack:getItemNumByID(xyd.ItemID.SENIOR_SUMMON_SCROLL) then
		xyd.alertTips(__("BAG_NUM_LIMIT_TEXT1", xyd.tables.itemTable:getName(xyd.ItemID.SENIOR_SUMMON_SCROLL)))

		return
	end

	if crystal < price then
		xyd.alert(xyd.AlertType.CONFIRM, __("CRYSTAL_NOT_ENOUGH"), function ()
			xyd.openWindow("vip_window")
		end, __("BUY"))

		return
	end

	xyd.alert(xyd.AlertType.YES_NO, __("BUY_SENIOR_SCROLL_CONFIRM", price, allNum), function (yes_no)
		if yes_no then
			local msg = messages_pb.item_exchange_req()
			msg.id = xyd.ExchangeItem["_" .. tostring(xyd.ItemID.CRYSTAL) .. "TO" .. tostring(xyd.ItemID.SENIOR_SUMMON_SCROLL) .. "_" .. tostring(rate) .. "_"]
			msg.num = num

			xyd.Backend.get():request(xyd.mid.ITEM_EXCHANGE, msg)
		end
	end)
end

return BuySeniorScrollWindow
