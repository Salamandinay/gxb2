local BaseWindow = import(".BaseWindow")
local SchoolGiftbagExchangeWindow = class("SchoolGiftbagExchangeWindow", BaseWindow)
local SchoolGiftbagExchangeWindowItem = class("SchoolGiftbagExchangeWindowItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local ActivitySchoolGiftExchangeTable = xyd.tables.activitySchoolGiftExchangeTable
local json = require("cjson")
local Backpack = xyd.models.backpack

function SchoolGiftbagExchangeWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.collection = {}
end

function SchoolGiftbagExchangeWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.titleLabel = groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.scroller = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.item = self.scroller:NodeByName("school_giftbag_exchange_window_item").gameObject
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scroller, wrapContent, self.item, SchoolGiftbagExchangeWindowItem, self)
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.numLabel = groupAction:ComponentByName("numLabel", typeof(UILabel))
end

function SchoolGiftbagExchangeWindow:initUIComponent()
	self.titleLabel.text = __("SCHOOL_GIFTBAG_EXCHANGE_TEXT01")
	self.numLabel.text = Backpack:getItemNumByID(xyd.ItemID.SUMMER_COIN)
end

function SchoolGiftbagExchangeWindow:register()
	BaseWindow.register(self)
	self.eventProxy_:addEventListener(xyd.event.EXCHANGE_SCHOOL_GIFT, function (event)
		local detail = json.decode(event.data.detail)
		local items = detail.items

		self:updateDataWithoutSort(detail.exchange_status)

		for i = 1, #items do
			if xyd.tables.itemTable:getType(items[i].item_id) == xyd.ItemType.SKIN then
				xyd.onGetNewPartnersOrSkins({
					destory_res = false,
					skins = {
						tonumber(items[i].item_id)
					}
				})
			end
		end
	end)
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function ()
		self.numLabel.text = tostring(Backpack:getItemNumByID(xyd.ItemID.SUMMER_COIN))
	end)
end

function SchoolGiftbagExchangeWindow:initWindow()
	SchoolGiftbagExchangeWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
	self:updateData(self.params_.exchange_status)
end

function SchoolGiftbagExchangeWindow:updateData(exchange_status)
	local item_status = {}
	local got_item = {}

	for i = 1, #exchange_status do
		local condition_id = ActivitySchoolGiftExchangeTable:getConditionID(i) - 1
		local lock_status = nil

		if exchange_status[i] == 0 then
			if condition_id == -1 or exchange_status[condition_id + 1] ~= 0 then
				lock_status = 1
			else
				lock_status = 0
			end
		else
			lock_status = 2
		end

		local params = {
			id = i,
			status = lock_status
		}

		if lock_status ~= 2 then
			table.insert(item_status, params)
		else
			table.insert(got_item, params)
		end
	end

	for i = 1, #got_item do
		table.insert(item_status, got_item[i])
	end

	self.collection = item_status

	self.wrapContent:setInfos(self.collection, {})
end

function SchoolGiftbagExchangeWindow:updateDataWithoutSort(exchange_status)
	local item_status = self.collection

	for i = 1, #item_status do
		local id = item_status[i].id
		local condition_id = ActivitySchoolGiftExchangeTable:getConditionID(id) - 1
		local lock_status = nil

		if exchange_status[id] == 0 then
			if condition_id == -1 or exchange_status[condition_id + 1] ~= 0 then
				lock_status = 1
			else
				lock_status = 0
			end
		else
			lock_status = 2
		end

		item_status[i].status = lock_status
	end

	self.collection = item_status

	self.wrapContent:setInfos(self.collection, {})
end

function SchoolGiftbagExchangeWindow:updateStatus(id)
	local list = self.collection

	for i = 1, #list do
		if list[i].id == id then
			list[i].lock_status = 2

			return
		end
	end
end

function SchoolGiftbagExchangeWindowItem:ctor(go, parent)
	SchoolGiftbagExchangeWindowItem.super.ctor(self, go, parent)
end

function SchoolGiftbagExchangeWindowItem:initUI()
	local go = self.go
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.itemGroupLayout = self.itemGroup:GetComponent(typeof(UILayout))
	self.acquireImg = go:ComponentByName("acquireImg", typeof(UISprite))
	self.acquireBtn = go:NodeByName("acquireBtn").gameObject
	self.newImg = go:ComponentByName("newImg", typeof(UISprite))

	xyd.setUISpriteAsync(self.acquireImg, nil, "mission_awarded_" .. xyd.Global.lang)
	self:setDragScrollView()
	xyd.setDragScrollView(self.acquireImg, self.scroller)
	xyd.setDragScrollView(self.acquireBtn, self.scroller)
end

function SchoolGiftbagExchangeWindowItem:registerEvent()
	UIEventListener.Get(self.acquireBtn).onClick = function ()
		local status = self.status_

		if status == 0 then
			xyd.showToast(__("SCHOOL_GIFTBAG_EXCHANGE_TEXT04"))

			return
		elseif status == 1 then
			local cost = ActivitySchoolGiftExchangeTable:getCost(self.id_)

			if Backpack:getItemNumByID(cost[1]) < cost[2] then
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(cost[1])))

				return
			end

			local win = xyd.getWindow("school_giftbag_exchange_window")

			win:updateStatus(self.id_)

			local msg = messages_pb.exchange_school_gift_req()
			msg.activity_id = xyd.ActivityID.ACTIVITY_SCHOOL_GIFTBAG
			msg.id = self.id_

			xyd.Backend.get():request(xyd.mid.EXCHANGE_SCHOOL_GIFT, msg)
		end
	end
end

function SchoolGiftbagExchangeWindowItem:updateInfo()
	self.id_ = self.data.id
	self.status_ = self.data.status

	self:updateLayout()
	self:updateButton()
end

function SchoolGiftbagExchangeWindowItem:updateLayout()
	local items = ActivitySchoolGiftExchangeTable:getAwards(self.id_)

	NGUITools.DestroyChildren(self.itemGroup.transform)

	for i = 1, #items do
		local item = xyd.getItemIcon({
			show_has_num = true,
			notShowGetWayBtn = true,
			scale = 0.7962962962962963,
			uiRoot = self.itemGroup,
			itemID = items[i][1],
			num = items[i][2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		item:setDragScrollView(self.scroller)

		if i == 1 then
			if xyd.tables.itemTable:getType(items[i][1]) == xyd.ItemType.SKIN then
				self.newImg:SetActive(true)
			else
				self.newImg:SetActive(false)
			end
		end
	end

	self.itemGroupLayout:Reposition()
end

function SchoolGiftbagExchangeWindowItem:updateButton()
	local status = self.status_
	local acquireBtn_label = self.acquireBtn:ComponentByName("button_label", typeof(UILabel))
	local lockImg = self.acquireBtn:ComponentByName("lock", typeof(UISprite))
	local cost = ActivitySchoolGiftExchangeTable:getCost(self.id_)
	self.acquireBtn:ComponentByName("numLabel", typeof(UILabel)).text = tostring(cost[2])
	acquireBtn_label.text = __("EXCHANGE")

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" or xyd.Global.lang == "en_en" then
		acquireBtn_label.fontSize = 20

		self.acquireBtn:ComponentByName("numLabel", typeof(UILabel)):X(-52)
		self.acquireBtn:ComponentByName("icon", typeof(UISprite)):X(-52)
	end

	if status == 0 then
		self.acquireBtn:SetActive(true)
		lockImg:SetActive(true)
		self.acquireImg:SetActive(false)
		acquireBtn_label:SetActive(false)
	elseif status == 1 then
		self.acquireBtn:SetActive(true)
		self.acquireImg:SetActive(false)
		acquireBtn_label:SetActive(true)
		lockImg:SetActive(false)
	else
		self.acquireImg:SetActive(true)
		self.acquireBtn:SetActive(false)
	end
end

return SchoolGiftbagExchangeWindow
