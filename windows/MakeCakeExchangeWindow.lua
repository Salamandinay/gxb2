local cjson = require("cjson")
local MakeCakeExchangeWindow = class("MakeCakeExchangeWindow", import(".BaseWindow"))
local MakeCakeExchangeWindowItem = class("MakeCakeExchangeWindowItem", import("app.components.BaseComponent"))
local GiftbagIcon = import("app.components.GiftbagIcon")
local Backpack = xyd.models.backpack

function MakeCakeExchangeWindow:ctor(name, params)
	MakeCakeExchangeWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.MAKE_CAKE)
	self.lock_ = params.lock
	self.times_ = params.times
	self.id_ = params.id
	self.items_ = {}
end

function MakeCakeExchangeWindow:initWindow()
	MakeCakeExchangeWindow.super:initWindow()

	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.title = self.groupAction:ComponentByName("title", typeof(UILabel))
	self.exchangeLabel = self.groupAction:ComponentByName("exchangeLabel", typeof(UILabel))
	self.itemGroup = self.groupAction:NodeByName("itemGroup").gameObject
	self.numGroup = self.groupAction:NodeByName("numGroup").gameObject
	self.numLabel = self.numGroup:ComponentByName("label", typeof(UILabel))
	self.extraGroup = self.groupAction:NodeByName("extraGroup").gameObject
	self.extraLabel = self.extraGroup:ComponentByName("exchangeExtraAwardLabel", typeof(UILabel))
	self.extraNumLabel = self.extraGroup:ComponentByName("exchangeExtraAwardNumLabel", typeof(UILabel))
	self.awardImg = self.extraGroup:ComponentByName("awardImg", typeof(UISprite))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject

	self:layout()
	self:registerEvent()
end

function MakeCakeExchangeWindow:layout()
	self:initItems()
	self:updateLock()

	self.title.text = __("MAKE_CAKE_ITEM_TEXT" .. self.id_)
	local extra = xyd.tables.activityMakeCakeTable:getExtraAward(self.id_)
	self.numLabel.text = Backpack:getItemNumByID(xyd.ItemID.MAKE_CAKE_THREE_COIN)
	self.extraLabel.text = __("MAKE_CAKE_TEXT05")
	self.extraNumLabel.text = tostring(xyd.tables.activityMakeCakeTable:getExtraAward(self.id_)[2])

	xyd.setUISpriteAsync(self.awardImg, nil, xyd.tables.itemTable:getIcon(extra[1]))
end

function MakeCakeExchangeWindow:updateLock()
	if self.lock_ then
		self.exchangeLabel.text = __("MAKE_CAKE_TEXT04_LOCK")
		self.exchangeLabel.color = Color.New2(3422556671.0)
	else
		self.exchangeLabel.text = __("MAKE_CAKE_TEXT04_UNLOCK")
		self.exchangeLabel.color = Color.New2(6933759)
	end
end

function MakeCakeExchangeWindow:initItems()
	for i = 1, 3 do
		local info = xyd.tables.activityMakeCakeTable:getAwardInfo(self.id_, i)

		if info ~= nil then
			local item = MakeCakeExchangeWindowItem.new(self.itemGroup)

			item:setInfo({
				cake_id = self.id_,
				item_id = i,
				times = self.times_[i],
				lock = self.lock_
			})
			table.insert(self.items_, item)
		else
			break
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

function MakeCakeExchangeWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.window_.name)
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function MakeCakeExchangeWindow:onAward(event)
	local detail = cjson.decode(event.data.detail)
	local items = self.items_
	local times = detail["times_" .. self.id_]

	for i = 1, #items do
		if items[i] ~= nil then
			items[i]:updateData(times[i])
		end
	end

	self.numLabel.text = Backpack:getItemNumByID(xyd.ItemID.MAKE_CAKE_THREE_COIN)
end

function MakeCakeExchangeWindowItem:ctor(parentGO)
	MakeCakeExchangeWindowItem.super.ctor(self, parentGO)
end

function MakeCakeExchangeWindowItem:getPrefabPath()
	return "Prefabs/Components/make_cake_exchange_window_item"
end

function MakeCakeExchangeWindowItem:initUI()
	MakeCakeExchangeWindowItem.super.initUI(self)
	self:getComponent()
end

function MakeCakeExchangeWindowItem:setInfo(params)
	self.cake_id_ = params.cake_id
	self.item_id_ = params.item_id
	self.times_ = params.times
	self.info_ = xyd.tables.activityMakeCakeTable:getAwardInfo(params.cake_id, params.item_id)
	self.lock_ = params.lock

	self:layout()
	self:updateBtn()
end

function MakeCakeExchangeWindowItem:getComponent()
	local go = self.go
	self.iconGroup = go:NodeByName("iconGroup").gameObject
	self.purchaseBtn = go:NodeByName("purchaseBtn").gameObject
	self.purchaseLabel = self.purchaseBtn:ComponentByName("button_label", typeof(UILabel))
	self.priceGroup = self.purchaseBtn:NodeByName("priceGroup").gameObject
	self.priceNum = self.priceGroup:ComponentByName("num", typeof(UILabel))
	self.priceIcon = self.priceGroup:ComponentByName("icon", typeof(UISprite))
	self.limitLabel = go:ComponentByName("limitLabel", typeof(UILabel))
end

function MakeCakeExchangeWindowItem:layout()
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", self.info_.limit - self.times_)
	self.purchaseLabel.text = __("GET3")
	self.priceNum.text = tostring(self.info_.cost[2])
	local award = self.info_.awards

	if #award > 1 then
		local src = "icon_mage"
		local str = __("MAGICIAN_SUIT")
		local item = GiftbagIcon.new(self.iconGroup, {
			icon_src = src,
			awards = award,
			title = str
		})
	else
		local item = xyd.getItemIcon({
			show_has_num = true,
			itemID = self.info_.awards[1][1],
			num = self.info_.awards[1][2],
			uiRoot = self.iconGroup,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end
end

function MakeCakeExchangeWindowItem:onRegister()
	UIEventListener.Get(self.purchaseBtn).onClick = handler(self, self.purchaseClick)
end

function MakeCakeExchangeWindowItem:purchaseClick()
	if self.lock_ then
		return
	end

	if self.info_.limit - self.times_ <= 0 then
		return
	end

	local has = Backpack:getItemNumByID(xyd.ItemID.MAKE_CAKE_THREE_COIN)

	if has < self.info_.cost[2] then
		xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(self.info_.cost[1])))

		return
	end

	xyd.alertYesNo(__("CONFIRM_CHANGE"), function (yes_no)
		if yes_no then
			local data = cjson.encode({
				cake_id = tonumber(self.cake_id_),
				cake_index = tonumber(self.item_id_)
			})
			local msg = messages_pb.get_activity_award_req()
			msg.activity_id = xyd.ActivityID.MAKE_CAKE
			msg.params = data

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
		end
	end)
end

function MakeCakeExchangeWindowItem:updateBtn()
	local limit = self.info_.limit - self.times_

	if limit <= 0 or self.lock_ then
		xyd.setTouchEnable(self.purchaseBtn, false)
		xyd.applyChildrenGrey(self.purchaseBtn)
	else
		xyd.setTouchEnable(self.purchaseBtn, true)
		xyd.applyChildrenOrigin(self.purchaseBtn)
	end
end

function MakeCakeExchangeWindowItem:updateData(times)
	self.times_ = times
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", self.info_.limit - self.times_)

	self:updateBtn()
end

return MakeCakeExchangeWindow
