local cjson = require("cjson")
local BaseWindow = import(".BaseWindow")
local CountDown = import("app.components.CountDown")
local ActivitySimulationGachaGiftbagWindow = class("ActivitySimulationGachaGiftbagWindow", BaseWindow)
local ActivitySimulationGachaGiftbagWindowItem = class("ActivitySimulationGachaGiftbagWindowItem", import("app.components.CopyComponent"))

function ActivitySimulationGachaGiftbagWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SIMULATION_GACHA)
	self.infos = {}
	self.items = {}
end

function ActivitySimulationGachaGiftbagWindow:initWindow()
	self:getUIComponent()
	ActivitySimulationGachaGiftbagWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivitySimulationGachaGiftbagWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.imgText = winTrans:ComponentByName("imgText", typeof(UISprite))
	self.groupTime = winTrans:NodeByName("groupTime").gameObject
	self.labelTime = self.groupTime:ComponentByName("labelTime", typeof(UILabel))
	self.labelEnd = self.groupTime:ComponentByName("labelEnd", typeof(UILabel))
	self.scroller = winTrans:ComponentByName("scroller", typeof(UIScrollView))
	self.groupItem = self.scroller:NodeByName("groupItem").gameObject
	self.itemCell = winTrans:NodeByName("itemCell").gameObject
end

function ActivitySimulationGachaGiftbagWindow:initUIComponent()
	xyd.setUISpriteAsync(self.imgText, nil, "activity_simulation_gacha_giftbag_text_" .. xyd.Global.lang, nil, , true)
	CountDown.new(self.labelTime, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.labelEnd.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.labelEnd.transform:SetSiblingIndex(0)
	end

	table.insert(self.infos, {
		index = 0,
		isFree = true,
		limit = 1 - self.activityData.detail.awards[1]
	})

	for i, charge in ipairs(self.activityData.detail.charges) do
		table.insert(self.infos, {
			isFree = false,
			limit = charge.limit_times - charge.buy_times,
			tableID = charge.table_id,
			index = i
		})
	end

	table.sort(self.infos, function (a, b)
		if a.limit == 0 and b.limit == 0 or a.limit ~= 0 and b.limit ~= 0 then
			return a.index < b.index
		elseif a.limit == 0 then
			return false
		else
			return true
		end
	end)

	for i, info in ipairs(self.infos) do
		local tmpItem = NGUITools.AddChild(self.groupItem.gameObject, self.itemCell)
		self.items[i] = ActivitySimulationGachaGiftbagWindowItem.new(tmpItem, self)

		self.items[i]:setInfo(info)
		xyd.setDragScrollView(self.items[i].go, self.scroller)
	end

	self.groupItem:GetComponent(typeof(UILayout)):Reposition()
	self.scroller:ResetPosition()
end

function ActivitySimulationGachaGiftbagWindow:update()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SIMULATION_GACHA)

	for i, info in ipairs(self.infos) do
		local limit = nil

		if info.isFree then
			limit = 1 - self.activityData.detail.awards[1]
		else
			local charge = self.activityData.detail.charges[info.index]
			limit = charge.limit_times - charge.buy_times
		end

		self.items[i]:updateState(limit)
	end
end

function ActivitySimulationGachaGiftbagWindow:register()
	ActivitySimulationGachaGiftbagWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, self.update))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.update))
end

function ActivitySimulationGachaGiftbagWindowItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.groupIcon = self.go:NodeByName("groupIcon").gameObject
	self.labelLimit = self.go:ComponentByName("labelLimit", typeof(UILabel))
	self.labelVipExp = self.go:ComponentByName("labelVipExp", typeof(UILabel))
	self.labelExpValue = self.go:ComponentByName("labelExpValue", typeof(UILabel))
	self.btnFree = self.go:NodeByName("btnFree").gameObject
	self.labelFree = self.btnFree:ComponentByName("labelFree", typeof(UILabel))
	self.btnBuy = self.go:NodeByName("btnBuy").gameObject
	self.labelBuy = self.btnBuy:ComponentByName("labelBuy", typeof(UILabel))

	UIEventListener.Get(self.btnFree).onClick = function ()
		if xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL) < self.cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.CRYSTAL)))

			return
		end

		xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
			if yes then
				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SIMULATION_GACHA, cjson.encode({
					type = 5
				}))
			end
		end)
	end

	UIEventListener.Get(self.btnBuy).onClick = function ()
		xyd.SdkManager.get():showPayment(self.tableID)
	end
end

function ActivitySimulationGachaGiftbagWindowItem:setInfo(params)
	if params.limit == 0 then
		xyd.setEnabled(self.btnFree.gameObject, false)
		xyd.setEnabled(self.btnBuy.gameObject, false)
	end

	if params.isFree then
		self.btnFree:SetActive(true)
		self.btnBuy:SetActive(false)
		self.labelVipExp:SetActive(false)
		self.labelExpValue:SetActive(false)

		self.awards = xyd.tables.miscTable:split2Cost("activity_simulation_gacha_10_giftbag_diamonds", "value", "|#") or {}
		self.cost = xyd.tables.miscTable:split2Cost("activity_simulation_gacha_10_giftbag_diamonds_cost", "value", "#") or {
			0,
			0
		}
		self.labelFree.text = self.cost[2]
	else
		self.btnFree:SetActive(false)
		self.btnBuy:SetActive(true)
		self.labelVipExp:SetActive(true)
		self.labelExpValue:SetActive(true)

		self.tableID = params.tableID
		self.giftID = xyd.tables.giftBagTable:getGiftID(self.tableID) or 0
		self.labelExpValue.text = "+" .. (xyd.tables.giftBagTable:getVipExp(self.tableID) or 0)
		self.labelBuy.text = (xyd.tables.giftBagTextTable:getCurrency(self.tableID) or 0) .. " " .. (xyd.tables.giftBagTextTable:getCharge(self.tableID) or 0)
		self.awards = xyd.tables.giftTable:getAwards(self.giftID) or {}
	end

	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", params.limit)

	NGUITools.DestroyChildren(self.groupIcon.transform)

	for _, award in ipairs(self.awards) do
		if award[1] ~= xyd.ItemID.VIP_EXP then
			xyd.getItemIcon({
				showGetWays = false,
				notShowGetWayBtn = true,
				show_has_num = true,
				scale = 0.7037037037037037,
				isShowSelected = false,
				itemID = award[1],
				num = award[2],
				uiRoot = self.groupIcon,
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scroller
			})
		end
	end

	self.groupIcon:GetComponent(typeof(UILayout)):Reposition()
end

function ActivitySimulationGachaGiftbagWindowItem:updateState(limit)
	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", limit)

	if limit == 0 then
		xyd.setEnabled(self.btnFree.gameObject, false)
		xyd.setEnabled(self.btnBuy.gameObject, false)
	end
end

return ActivitySimulationGachaGiftbagWindow
