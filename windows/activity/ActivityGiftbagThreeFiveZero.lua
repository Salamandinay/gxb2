local ActivityGiftbagThreeFiveZero = class("ActivityGiftbagThreeFiveZero", import(".ActivityContent"))
local ActivityGiftbagThreeFiveZeroItem = class("ActivityGiftbagThreeFiveZeroItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")

function ActivityGiftbagThreeFiveZero:ctor(parentGO, params)
	ActivityGiftbagThreeFiveZero.super.ctor(self, parentGO, params)
end

function ActivityGiftbagThreeFiveZero:getPrefabPath()
	return "Prefabs/Windows/activity/activity_giftbag_three_five_zero"
end

function ActivityGiftbagThreeFiveZero:initUI()
	self:getUIComponent()
	ActivityGiftbagThreeFiveZero.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityGiftbagThreeFiveZero:resizeToParent()
	ActivityGiftbagThreeFiveZero.super.resizeToParent(self)
	self:resizePosY(self.arrowDown, -844, -1020)
end

function ActivityGiftbagThreeFiveZero:updateArrow()
	local itemSize = 316
	local isShowArrowUp = false
	local isShowArrowDown = false
	local panelSizeY = self.scrollPanel:GetViewSize().y

	if panelSizeY < #self.items * itemSize then
		local disY = self.scrollView.gameObject.transform.localPosition.y - self.initScrollViewY

		if disY > 10 then
			isShowArrowUp = true
		end

		local downDisY = #self.items * itemSize - (disY + panelSizeY)

		if downDisY > 10 then
			isShowArrowDown = true
		end
	end

	self.arrowUp:SetActive(isShowArrowUp)
	self.arrowDown:SetActive(isShowArrowDown)
end

function ActivityGiftbagThreeFiveZero:getUIComponent()
	local go = self.go
	self.textImg = go:ComponentByName("textImg", typeof(UISprite))
	self.groupModel = go:NodeByName("groupModel").gameObject
	self.scrollView = go:ComponentByName("scrollView", typeof(UIScrollView))
	self.scrollPanel = go:ComponentByName("scrollView", typeof(UIPanel))
	self.groupItems = self.scrollView:NodeByName("groupItems").gameObject
	self.groupArrow = go:NodeByName("groupArrow").gameObject
	self.arrowUp = self.groupArrow:ComponentByName("arrowUp", typeof(UISprite))
	self.arrowDown = self.groupArrow:ComponentByName("arrowDown", typeof(UISprite))
	self.giftbagItem = go:NodeByName("halloween_giftbag_item").gameObject

	self.giftbagItem:SetActive(false)
end

function ActivityGiftbagThreeFiveZero:initUIComponent()
	xyd.setUISpriteAsync(self.textImg, nil, "activity_giftbag_350_logo_" .. xyd.Global.lang, nil, , true)

	self.items = {}
	self.infos = {}

	for i = 1, #self.activityData.detail.charges do
		table.insert(self.infos, {
			table_id = self.activityData.detail.charges[i].table_id,
			buy_times = self.activityData.detail.charges[i].buy_times,
			index = i
		})
	end

	table.sort(self.infos, function (a, b)
		local pointa = a.buy_times < xyd.tables.giftBagTable:getBuyLimit(a.table_id)
		local pointb = b.buy_times < xyd.tables.giftBagTable:getBuyLimit(b.table_id)

		if pointa ~= pointb then
			if pointa == true then
				return true
			else
				return false
			end
		end

		return b.index < a.index
	end)
	NGUITools.DestroyChildren(self.groupItems.transform)

	for i = 1, #self.activityData.detail.charges do
		local go = NGUITools.AddChild(self.groupItems.gameObject, self.giftbagItem.gameObject)
		local item = ActivityGiftbagThreeFiveZeroItem.new(go, self)

		xyd.setDragScrollView(item.go, self.scrollView)
		item:setInfo(self.infos[i])
		table.insert(self.items, item)
	end

	self.groupItems:GetComponent(typeof(UILayout)):Reposition()
	self.scrollView:ResetPosition()

	self.initScrollViewY = self.scrollView.gameObject.transform.localPosition.y

	self:waitForTime(0.3, function ()
		self:updateArrow()
	end)
end

function ActivityGiftbagThreeFiveZero:register()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))

	self.scrollView.onDragMoving = handler(self, self.updateArrow)

	UIEventListener.Get(self.arrowUp.gameObject).onClick = function ()
		local sp = self.scrollView.gameObject:GetComponent(typeof(SpringPanel))

		sp.Begin(sp.gameObject, Vector3(169, self.initScrollViewY, 0), 16)
		self:waitForTime(0.3, function ()
			self:updateArrow()
		end)
	end

	UIEventListener.Get(self.arrowDown.gameObject).onClick = function ()
		local sp = self.scrollView.gameObject:GetComponent(typeof(SpringPanel))
		local dis = 316 * #self.items - (self.scrollPanel:GetViewSize().y - self.scrollView.padding.y * 2) + self.scrollView.padding.y

		sp.Begin(sp.gameObject, Vector3(169, self.initScrollViewY + dis, 0), 16)
		self:waitForTime(0.3, function ()
			self:updateArrow()
		end)
	end
end

function ActivityGiftbagThreeFiveZero:onRecharge()
	for i = 1, #self.items do
		self.items[i]:setInfo({
			buy_times = self.activityData.detail.charges[self.infos[i].index].buy_times
		})
	end
end

function ActivityGiftbagThreeFiveZeroItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	self:initUIComponent()
	self:register()
end

function ActivityGiftbagThreeFiveZeroItem:initUIComponent()
	self.itemGroup1 = self.go:NodeByName("itemGroup1").gameObject
	self.itemGroup2 = self.go:NodeByName("itemGroup2").gameObject
	self.itemGroup3 = self.go:NodeByName("itemGroup3").gameObject
	self.limitLabel = self.go:ComponentByName("limitLabel", typeof(UILabel))
	self.vipLabel = self.go:ComponentByName("vipLabel", typeof(UILabel))
	self.purchaseBtn = self.go:NodeByName("purchaseBtn").gameObject
	self.purchaseBtnLabel = self.purchaseBtn:ComponentByName("button_label", typeof(UILabel))
end

function ActivityGiftbagThreeFiveZeroItem:setInfo(params)
	if params.table_id then
		self.giftBagId = params.table_id
		self.buyLimit = xyd.tables.giftBagTable:getBuyLimit(self.giftBagId)
		self.vipLabel.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftBagId) .. " VIP EXP"
		self.purchaseBtnLabel.text = xyd.tables.giftBagTextTable:getCurrency(self.giftBagId) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.giftBagId)

		self:initAward()
	end

	if params.buy_times then
		self.buyTimes = params.buy_times

		self:updateState()
	end
end

function ActivityGiftbagThreeFiveZeroItem:register()
	UIEventListener.Get(self.purchaseBtn.gameObject).onClick = handler(self, function ()
		xyd.SdkManager.get():showPayment(self.giftBagId)
	end)
end

function ActivityGiftbagThreeFiveZeroItem:initAward()
	local awards = xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(self.giftBagId))
	local awardNum = 1

	for i in ipairs(awards) do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			xyd.getItemIcon({
				show_has_num = true,
				notShowGetWayBtn = true,
				uiRoot = awardNum == 2 and self.itemGroup3.gameObject or awardNum <= 3 and self.itemGroup1.gameObject or self.itemGroup2.gameObject,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				scale = awardNum == 2 and 0.7962962962962963 or 0.6111111111111112,
				dragScrollView = self.parent.scrollView
			})

			awardNum = awardNum + 1
		end
	end

	self.itemGroup1:GetComponent(typeof(UILayout)):Reposition()
	self.itemGroup2:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityGiftbagThreeFiveZeroItem:updateState()
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(self.buyLimit - self.buyTimes))

	if self.buyLimit <= self.buyTimes then
		self.purchaseBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		xyd.applyChildrenGrey(self.purchaseBtn.gameObject)
	end
end

return ActivityGiftbagThreeFiveZero
