local ActivityContent = import(".ActivityContent")
local ActivityGamblePlus = class("ActivityGamblePlus", ActivityContent)
local CountDown = import("app.components.CountDown")
local ActivityGamblePlusItem = class("ActivityGamblePlusItem", import("app.components.CopyComponent"))

function ActivityGamblePlus:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.items = {}
	self.icons = {}

	self:getUIComponent()
	self:layout()
	self:register()
	self:initItem()
	self.e_Scroller_scrollerView:ResetPosition()
end

function ActivityGamblePlus:getPrefabPath()
	return "Prefabs/Windows/activity/activity_gamble_plus"
end

function ActivityGamblePlus:getUIComponent()
	local go = self.go
	self.textImg = go:ComponentByName("textImg", typeof(UITexture))
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
	self.limitLabel = go:ComponentByName("limitLabel", typeof(UILabel))
	self.expLabel = go:ComponentByName("expLabel", typeof(UILabel))
	self.numGroup = go:NodeByName("numGroup").gameObject
	self.numLabel = self.numGroup:ComponentByName("label", typeof(UILabel))
	self.numBtn = self.numGroup:NodeByName("btn").gameObject
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.itemLabel = self.itemGroup:ComponentByName("label", typeof(UILabel))
	self.itemIconGroup = self.itemGroup:NodeByName("iconGroup").gameObject
	self.purchaseBtn = go:NodeByName("purchaseBtn").gameObject
	self.purchaseLabel = self.purchaseBtn:ComponentByName("button_label", typeof(UILabel))
	self.e_Scroller = go:NodeByName("e:Scroller").gameObject
	self.e_Scroller_scrollerView = self.e_Scroller:GetComponent(typeof(UIScrollView))
	self.scrollerItemGroup = self.e_Scroller:NodeByName("itemGroup").gameObject
	self.itemCell = go:NodeByName("itemCell").gameObject
end

function ActivityGamblePlus:layout()
	xyd.setUITextureByNameAsync(self.textImg, "activity_gamble_plus_" .. xyd.Global.lang, true)

	self.expLabel.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.activityData.detail.charges[1].table_id) .. " VIP EXP"
	self.itemLabel.text = __("GAMBLE_PLUS_TEXT_1")
	self.purchaseLabel.text = xyd.tables.giftBagTextTable:getCurrency(self.activityData.detail.charges[1].table_id) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.activityData.detail.charges[1].table_id)

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
		self.endLabel.text = __("END_TEXT")
	else
		self.endLabel:SetActive(false)
		self.timeLabel:SetActive(false)
	end

	local awards = xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(self.activityData.detail.charges[1].table_id))

	for i = 1, #awards do
		if awards[i][1] ~= xyd.ItemID.VIP_EXP then
			local icon = xyd.getItemIcon({
				show_has_num = true,
				itemID = awards[i][1],
				num = awards[i][2],
				scale = Vector3(0.667, 0.667, 1),
				uiRoot = self.itemIconGroup,
				dragScrollView = self.e_Scroller_scrollerView,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})

			table.insert(self.icons, icon)
		end
	end

	self.itemIconGroup:GetComponent(typeof(UILayout)):Reposition()
	self:refresh()
end

function ActivityGamblePlus:refresh()
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", xyd.tables.giftBagTable:getBuyLimit(self.activityData.detail.charges[1].table_id) - self.activityData.detail.charges[1].buy_times)
	self.numLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.HEART_POKER)

	if xyd.tables.giftBagTable:getBuyLimit(self.activityData.detail.charges[1].table_id) - self.activityData.detail.charges[1].buy_times <= 0 then
		xyd.applyChildrenGrey(self.purchaseBtn)

		self.purchaseBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		for i = 1, #self.icons do
			self.icons[i]:setChoose(true)
		end
	end

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.GAMBLE_PLUS, function ()
		self.activityData:initRedMarkState()
	end)
end

function ActivityGamblePlus:register()
	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_GAMBLE_PLUS_HELP"
		})
	end)
	UIEventListener.Get(self.purchaseBtn).onClick = handler(self, function ()
		local giftbag_id = self.activityData.detail.charges[1].table_id

		xyd.SdkManager.get():showPayment(giftbag_id)
	end)
	UIEventListener.Get(self.numBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_common_getway_window", {
			itemID = xyd.ItemID.HEART_POKER,
			values = self.activityData.detail_.is_completeds,
			tTable = xyd.tables.activityGamblePlusMissionTable
		})
	end)

	self.eventProxyInner_:addEventListener(xyd.event.RECHARGE, self.onRecharge, self)
	self.eventProxyInner_:addEventListener(xyd.event.ITEM_CHANGE, self.onItemChange, self)
	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, self.onAward, self)
end

function ActivityGamblePlus:onRecharge(event)
	local giftbagID = event.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftbagID) ~= self.id then
		return
	end

	self.activityData.detail.charges[1].buy_times = 1

	self:refresh()
	self:initItem()
end

function ActivityGamblePlus:onItemChange(event)
	local items = event.data.items

	for _, itemInfo in ipairs(items) do
		if itemInfo.item_id == xyd.ItemID.HEART_POKER then
			self:refresh()
			self:refreshItems()
		end
	end
end

function ActivityGamblePlus:onAward(event)
	local cjson = require("cjson")
	local detail = cjson.decode(event.data.detail)

	for i = 1, #detail do
		xyd.models.itemFloatModel:pushNewItems(detail[i].items)

		if detail[i].index and detail[i].index == 1 then
			self.activityData.detail.awarded[detail[i].id] = 1
		elseif detail[i].index and detail[i].index == 2 then
			self.activityData.detail.paid_awarded[detail[i].id] = 1
		end
	end

	self:refresh()
	self:refreshItems()
end

function ActivityGamblePlus:initItem()
	local ids = xyd.tables.activityGamblePlusTable:getIDs()
	local itemParams = {}
	self.items = {}

	NGUITools.DestroyChildren(self.scrollerItemGroup.transform)

	for i, _ in pairs(ids) do
		local id = ids[i]
		local params = {
			id = id,
			point = xyd.tables.activityGamblePlusTable:getPoint(id),
			awards = xyd.tables.activityGamblePlusTable:getAwards(id),
			exAwards = xyd.tables.activityGamblePlusTable:getExtraAwards(id),
			giftBought = self.activityData.detail.charges[1].buy_times,
			awarded = self.activityData.detail.awarded[id],
			exAwarded = self.activityData.detail.paid_awarded[id],
			scroll = self.e_Scroller_scrollerView,
			parent = self
		}

		table.insert(itemParams, params)
	end

	table.sort(itemParams, function (a, b)
		local itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.HEART_POKER)

		if a.point <= itemNum and (a.giftBought == 1 and a.awarded == 1 and a.exAwarded == 1 or a.giftBought == 0 and a.awarded == 1) and (itemNum < b.point or b.giftBought == 1 and (b.awarded == 0 or b.exAwarded == 0) or b.giftBought == 0 and b.awarded == 0) then
			return false
		elseif b.point <= itemNum and (b.giftBought == 1 and b.awarded == 1 and b.exAwarded == 1 or b.giftBought == 0 and b.awarded == 1) and (itemNum < a.point or a.giftBought == 1 and (a.awarded == 0 or a.exAwarded == 0) or a.giftBought == 0 and a.awarded == 0) then
			return true
		else
			return a.id < b.id
		end
	end)
	NGUITools.DestroyChildren(self.scrollerItemGroup.transform)

	for i in ipairs(itemParams) do
		local tmp = NGUITools.AddChild(self.scrollerItemGroup, self.itemCell.gameObject)
		local item = ActivityGamblePlusItem.new(tmp, itemParams[i])

		table.insert(self.items, item)
	end

	self.itemCell:SetActive(false)
	self.scrollerItemGroup:GetComponent(typeof(UIGrid)):Reposition()
end

function ActivityGamblePlus:refreshItems()
	for i = 1, #self.items do
		local id = self.items[i].params.id
		local params = {
			id = id,
			point = xyd.tables.activityGamblePlusTable:getPoint(id),
			awards = xyd.tables.activityGamblePlusTable:getAwards(id),
			exAwards = xyd.tables.activityGamblePlusTable:getExtraAwards(id),
			giftBought = self.activityData.detail.charges[1].buy_times,
			awarded = self.activityData.detail.awarded[id],
			exAwarded = self.activityData.detail.paid_awarded[id],
			scroll = self.e_Scroller_scrollerView,
			parent = self
		}

		self.items[i]:setInfos(params)
	end
end

function ActivityGamblePlus:reqAward()
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.GAMBLE_PLUS
	local batches = {}
	local ids = xyd.tables.activityGamblePlusTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]

		if xyd.tables.activityGamblePlusTable:getPoint(id) <= xyd.models.backpack:getItemNumByID(xyd.ItemID.HEART_POKER) then
			if self.activityData.detail.awarded[id] and self.activityData.detail.awarded[id] == 0 then
				table.insert(batches, {
					index = 1,
					id = id
				})
			end

			if self.activityData.detail.paid_awarded[id] and self.activityData.detail.paid_awarded[id] == 0 and self.activityData.detail.charges[1].buy_times and self.activityData.detail.charges[1].buy_times > 0 then
				table.insert(batches, {
					index = 2,
					id = id
				})
			end
		end
	end

	local data = {
		batches = batches
	}
	local cjson = require("cjson")
	msg.params = cjson.encode(data)

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function ActivityGamblePlusItem:ctor(goItem, params)
	self.goItem_ = goItem
	self.transGo = goItem.transform
	self.params = params

	self:getUIComponent()
	self:layout()
end

function ActivityGamblePlusItem:getUIComponent()
	self.textLabel = self.transGo:ComponentByName("textLabel", typeof(UILabel))
	self.icon1 = self.transGo:NodeByName("icon1").gameObject
	self.icon2 = self.transGo:NodeByName("icon2").gameObject
	self.icon3 = self.transGo:NodeByName("icon3").gameObject
	self.progressBar_ = self.transGo:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressDesc_ = self.transGo:ComponentByName("progressBar_/progressLabel", typeof(UILabel))
end

function ActivityGamblePlusItem:setInfos(params)
	self.params = params

	NGUITools.DestroyChildren(self.icon1.transform)
	NGUITools.DestroyChildren(self.icon2.transform)
	NGUITools.DestroyChildren(self.icon3.transform)
	self:layout()
end

function ActivityGamblePlusItem:layout()
	self.textLabel.text = __("GAMBLE_PLUS_TEXT_2", self.params.point)

	if xyd.Global.lang == "ja_jp" then
		self.textLabel:X(-330)
	end

	local itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.HEART_POKER)
	self.progressDesc_.text = math.min(itemNum, self.params.point) .. "/" .. self.params.point
	self.progressBar_.value = math.min(itemNum / self.params.point, 1)

	if self.params.awards[1] then
		local callback = nil

		if self.params.point <= xyd.models.backpack:getItemNumByID(xyd.ItemID.HEART_POKER) and self.params.awarded and self.params.awarded == 0 then
			function callback()
				self.params.parent:reqAward()
			end
		end

		local icon = xyd.getItemIcon({
			show_has_num = true,
			itemID = self.params.awards[1][1],
			num = self.params.awards[1][2],
			scale = Vector3(0.7, 0.7, 1),
			uiRoot = self.icon1.gameObject,
			dragScrollView = self.params.scroll,
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			callback = callback
		})

		if self.params.point <= xyd.models.backpack:getItemNumByID(xyd.ItemID.HEART_POKER) then
			if self.params.awarded and self.params.awarded > 0 then
				icon:setChoose(true)
			else
				icon:setEffect(true, "fx_ui_bp_available")
			end
		end
	end

	if self.params.exAwards[1] then
		local callback = nil

		if self.params.point <= xyd.models.backpack:getItemNumByID(xyd.ItemID.HEART_POKER) and self.params.exAwarded and self.params.exAwarded == 0 and self.params.giftBought > 0 then
			function callback()
				self.params.parent:reqAward()
			end
		end

		local icon = xyd.getItemIcon({
			show_has_num = true,
			itemID = self.params.exAwards[1][1],
			num = self.params.exAwards[1][2],
			scale = Vector3(0.7, 0.7, 1),
			uiRoot = self.icon2.gameObject,
			dragScrollView = self.params.scroll,
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			callback = callback
		})

		if self.params.giftBought == 0 then
			icon:setLock(true)
		elseif self.params.point <= xyd.models.backpack:getItemNumByID(xyd.ItemID.HEART_POKER) then
			if self.params.exAwarded and self.params.exAwarded > 0 then
				icon:setChoose(true)
			else
				icon:setEffect(true, "fx_ui_bp_available")
			end
		end
	end

	if self.params.exAwards[2] then
		local callback = nil

		if self.params.point <= xyd.models.backpack:getItemNumByID(xyd.ItemID.HEART_POKER) and self.params.exAwarded and self.params.exAwarded == 0 and self.params.giftBought > 0 then
			function callback()
				self.params.parent:reqAward()
			end
		end

		local icon = xyd.getItemIcon({
			show_has_num = true,
			itemID = self.params.exAwards[2][1],
			num = self.params.exAwards[2][2],
			scale = Vector3(0.7, 0.7, 1),
			uiRoot = self.icon3.gameObject,
			dragScrollView = self.params.scroll,
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			callback = callback
		})

		if self.params.giftBought == 0 then
			icon:setLock(true)
		elseif self.params.point <= xyd.models.backpack:getItemNumByID(xyd.ItemID.HEART_POKER) then
			if self.params.exAwarded and self.params.exAwarded > 0 then
				icon:setChoose(true)
			else
				icon:setEffect(true, "fx_ui_bp_available")
			end
		end

		self.icon3.gameObject:SetActive(true)
		self.icon2.gameObject:X(180)
	else
		self.icon3.gameObject:SetActive(false)
		self.icon2.gameObject:X(230)
	end
end

return ActivityGamblePlus
