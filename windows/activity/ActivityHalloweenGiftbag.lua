local ActivityHalloweenGiftbag = class("ActivityHalloweenGiftbag", import(".ActivityContent"))
local ActivityHalloweenGiftbagItem = class("ActivityHalloweenGiftbagItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")

function ActivityHalloweenGiftbag:ctor(parentGO, params)
	ActivityHalloweenGiftbag.super.ctor(self, parentGO, params)
end

function ActivityHalloweenGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/activity_halloween_giftbag"
end

function ActivityHalloweenGiftbag:initUI()
	self:getUIComponent()
	ActivityHalloweenGiftbag.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityHalloweenGiftbag:resizeToParent()
	ActivityHalloweenGiftbag.super.resizeToParent(self)
	self:resizePosY(self.arrowDown, -844, -1020)
end

function ActivityHalloweenGiftbag:updateArrow()
	local topDelta = 92 - self.scrollPanel.clipOffset.y
	local topNum = math.floor(topDelta / 316 + 0.6)
	local arrowUp = false

	for i = 1, topNum do
		arrowUp = arrowUp or true
	end

	self.arrowUp:SetActive(arrowUp)

	local nums = #self.items
	local botDelta = nums * 306 + 10 - self.scrollPanel.height - topDelta
	local botNum = math.floor(botDelta / 316 + 0.6)
	local arrowDown = false

	if botNum >= 1 then
		arrowDown = true
	end

	self.arrowDown:SetActive(arrowDown)
end

function ActivityHalloweenGiftbag:getUIComponent()
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

function ActivityHalloweenGiftbag:initUIComponent()
	xyd.setUISpriteAsync(self.textImg, nil, "activity_halloween_giftbag_text_" .. xyd.Global.lang, nil, , true)

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
		local item = ActivityHalloweenGiftbagItem.new(go, self)

		xyd.setDragScrollView(item.go, self.scrollView)
		item:setInfo(self.infos[i])
		table.insert(self.items, item)
	end

	self.groupItems:GetComponent(typeof(UILayout)):Reposition()
	self.scrollView:ResetPosition()
	self:waitForTime(0.3, function ()
		self:updateArrow()
	end)

	self.modelEffect = xyd.Spine.new(self.groupModel)

	self.modelEffect:setInfo("keruisi_pifu01_lihui01", function ()
		self.modelEffect:play("animation", 0)
		self.modelEffect:SetLocalScale(-0.75, 0.75, 1)
		self.modelEffect:SetLocalPosition(-230, -790, 0)
	end)
end

function ActivityHalloweenGiftbag:register()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))

	self.scrollView.onDragMoving = handler(self, self.updateArrow)

	UIEventListener.Get(self.arrowUp.gameObject).onClick = function ()
		local sp = self.scrollView.gameObject:GetComponent(typeof(SpringPanel))

		sp.Begin(sp.gameObject, Vector3(169, -588, 0), 16)
		self:waitForTime(0.3, function ()
			self:updateArrow()
		end)
	end

	UIEventListener.Get(self.arrowDown.gameObject).onClick = function ()
		local sp = self.scrollView.gameObject:GetComponent(typeof(SpringPanel))

		sp.Begin(sp.gameObject, Vector3(169, -401, 0), 16)
		self:waitForTime(0.3, function ()
			self:updateArrow()
		end)
	end
end

function ActivityHalloweenGiftbag:onRecharge()
	for i = 1, #self.items do
		self.items[i]:setInfo({
			buy_times = self.activityData.detail.charges[self.infos[i].index].buy_times
		})
	end
end

function ActivityHalloweenGiftbagItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	self:initUIComponent()
	self:register()
end

function ActivityHalloweenGiftbagItem:initUIComponent()
	self.itemGroup1 = self.go:NodeByName("itemGroup1").gameObject
	self.itemGroup2 = self.go:NodeByName("itemGroup2").gameObject
	self.itemGroup3 = self.go:NodeByName("itemGroup3").gameObject
	self.limitLabel = self.go:ComponentByName("limitLabel", typeof(UILabel))
	self.vipLabel = self.go:ComponentByName("vipLabel", typeof(UILabel))
	self.purchaseBtn = self.go:NodeByName("purchaseBtn").gameObject
	self.purchaseBtnLabel = self.purchaseBtn:ComponentByName("button_label", typeof(UILabel))
end

function ActivityHalloweenGiftbagItem:setInfo(params)
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

function ActivityHalloweenGiftbagItem:register()
	UIEventListener.Get(self.purchaseBtn.gameObject).onClick = handler(self, function ()
		xyd.SdkManager.get():showPayment(self.giftBagId)
	end)
end

function ActivityHalloweenGiftbagItem:initAward()
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

function ActivityHalloweenGiftbagItem:updateState()
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(self.buyLimit - self.buyTimes))

	if self.buyLimit <= self.buyTimes then
		self.purchaseBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		xyd.applyChildrenGrey(self.purchaseBtn.gameObject)
	end
end

return ActivityHalloweenGiftbag
