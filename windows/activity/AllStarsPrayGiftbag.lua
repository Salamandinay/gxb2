local AllStarsPrayGiftbag = class("AllStarsPrayGiftbag", import(".ActivityContent"))
local AllStarsPrayGiftbagItem = class("AllStarsPrayGiftbagItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")

function AllStarsPrayGiftbag:ctor(parentGO, params)
	AllStarsPrayGiftbag.super.ctor(self, parentGO, params)
end

function AllStarsPrayGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/all_stars_pray_giftbag"
end

function AllStarsPrayGiftbag:initUI()
	self:getUIComponent()
	AllStarsPrayGiftbag.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function AllStarsPrayGiftbag:resizeToParent()
	AllStarsPrayGiftbag.super.resizeToParent(self)
	self:resizePosY(self.textImg, -2, -42)
	self:resizePosY(self.timeImg, -238, -298)
	self:resizePosY(self.timeGroup, -261, -321)
	self:resizePosY(self.arrowUp, -317, -377)
	self:resizePosY(self.arrowDown, -837, -1014)
	self:resizePosY(self.imgMb, -767, -944)
	self.scrollPanel:SetTopAnchor(self.go.gameObject, 1, -294 + -67 * self.scale_num_contrary)
end

function AllStarsPrayGiftbag:getUIComponent()
	local go = self.go
	self.textImg = go:ComponentByName("textImg", typeof(UISprite))
	self.timeImg = go:NodeByName("timeImg").gameObject
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
	self.scrollView = go:ComponentByName("scrollView", typeof(UIScrollView))
	self.scrollPanel = go:ComponentByName("scrollView", typeof(UIPanel))
	self.groupItems = self.scrollView:NodeByName("groupItems").gameObject
	self.groupArrow = go:NodeByName("groupArrow").gameObject
	self.imgMb = self.groupArrow:ComponentByName("imgMb", typeof(UISprite))
	self.arrowUp = self.groupArrow:ComponentByName("arrowUp", typeof(UISprite))
	self.arrowDown = self.groupArrow:ComponentByName("arrowDown", typeof(UISprite))
	self.giftbagItem = go:NodeByName("all_stars_pray_giftbag_item").gameObject

	self.giftbagItem:SetActive(false)
	self.arrowUp:SetActive(false)
	self.arrowDown:SetActive(false)
end

function AllStarsPrayGiftbag:initUIComponent()
	xyd.setUISpriteAsync(self.textImg, nil, "all_stars_pray_giftbag_text_" .. xyd.Global.lang, nil, , true)
	CountDown.new(self.timeLabel, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel.text = __("END")

	if xyd.Global.lang == "de_de" then
		self.timeLabel.fontSize = 22
		self.endLabel.fontSize = 22

		self.timeGroup:X(-152)
	end

	if xyd.Global.lang == "fr_fr" then
		self.endLabel.text = __("REST_TIME")
	end

	self.items = {}
	self.infos = {}
	local freeIDs = xyd.tables.activityPrayGiftTable:getIDs()

	for i = 1, #freeIDs do
		table.insert(self.infos, {
			is_free = true,
			table_id = freeIDs[i],
			buy_times = self.activityData.detail.buy_times[i],
			limit_times = xyd.tables.activityPrayGiftTable:getLimit(freeIDs[i]),
			index = i
		})
	end

	for i = 1, #self.activityData.detail.charges do
		table.insert(self.infos, {
			is_free = false,
			table_id = self.activityData.detail.charges[i].table_id,
			buy_times = self.activityData.detail.charges[i].buy_times,
			limit_times = self.activityData.detail.charges[i].limit_times,
			index = i
		})
	end

	table.sort(self.infos, function (a, b)
		local pointa = a.buy_times < a.limit_times
		local pointb = b.buy_times < b.limit_times

		if pointa ~= pointb then
			return pointa
		end

		if a.is_free ~= b.is_free then
			return a.is_free
		end

		return b.index < a.index
	end)
	NGUITools.DestroyChildren(self.groupItems.transform)

	for i = 1, #self.infos do
		local go = NGUITools.AddChild(self.groupItems.gameObject, self.giftbagItem.gameObject)
		local item = AllStarsPrayGiftbagItem.new(go, self)

		xyd.setDragScrollView(item.go, self.scrollView)
		item:setInfo(self.infos[i])
		table.insert(self.items, item)
	end

	self.groupItems:GetComponent(typeof(UILayout)):Reposition()
	self.scrollView:ResetPosition()
	self:waitForTime(0.3, function ()
		self:updateArrow()
	end)
end

function AllStarsPrayGiftbag:updateArrow()
	local topDelta = 95 + 68 * self.scale_num_contrary - self.scrollPanel.clipOffset.y
	local topNum = math.floor(topDelta / 247 + 0.75)
	local arrowUp = false

	for i = 1, topNum do
		arrowUp = arrowUp or true
	end

	self.arrowUp:SetActive(arrowUp)

	local nums = #self.items
	local botDelta = nums * 259 - 12 - self.scrollPanel.height - topDelta
	local botNum = math.floor(botDelta / 247 + 0.75)
	local arrowDown = false

	if botNum >= 1 then
		arrowDown = true
	end

	self.arrowDown:SetActive(arrowDown)
end

function AllStarsPrayGiftbag:onClickUpArrow()
	local sp = self.scrollView.gameObject:GetComponent(typeof(SpringPanel))

	sp.Begin(sp.gameObject, Vector3(-153, -681 - 67 * self.scale_num_contrary, 0), 16)
	self:waitForTime(0.3, function ()
		self:updateArrow()
	end)
end

function AllStarsPrayGiftbag:onClickDownArrow()
	local sp = self.scrollView.gameObject:GetComponent(typeof(SpringPanel))

	sp.Begin(sp.gameObject, Vector3(-153, -488 - 178 * self.scale_num_contrary, 0), 16)
	self:waitForTime(0.3, function ()
		self:updateArrow()
	end)
end

function AllStarsPrayGiftbag:register()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.updateItems))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.updateItems))

	self.scrollView.onDragMoving = handler(self, self.updateArrow)
	UIEventListener.Get(self.arrowUp.gameObject).onClick = handler(self, self.onClickUpArrow)
	UIEventListener.Get(self.arrowDown.gameObject).onClick = handler(self, self.onClickDownArrow)
end

function AllStarsPrayGiftbag:updateItems()
	for i = 1, #self.items do
		if self.infos[i].is_free then
			self.items[i]:setInfo({
				buy_times = self.activityData.detail.buy_times[self.infos[i].index]
			})
		else
			self.items[i]:setInfo({
				buy_times = self.activityData.detail.charges[self.infos[i].index].buy_times
			})
		end
	end
end

function AllStarsPrayGiftbagItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	self:initUIComponent()
	self:register()
end

function AllStarsPrayGiftbagItem:initUIComponent()
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject
	self.limitLabel = self.go:ComponentByName("limitLabel", typeof(UILabel))
	self.vipLabel = self.go:ComponentByName("vipLabel", typeof(UILabel))
	self.purchaseBtn = self.go:NodeByName("purchaseBtn").gameObject
	self.purchaseBtnBg = self.purchaseBtn:GetComponent(typeof(UISprite))
	self.purchaseBtnLabel = self.purchaseBtn:ComponentByName("button_label", typeof(UILabel))
	self.purchaseBtnIcon = self.purchaseBtn:NodeByName("icon").gameObject
end

function AllStarsPrayGiftbagItem:setInfo(params)
	if params.table_id then
		self.isFree = params.is_free
		self.giftBagId = params.table_id
		self.buyLimit = params.limit_times

		self:initItem()
	end

	if params.buy_times then
		self.buyTimes = params.buy_times

		self:updateState()
	end
end

function AllStarsPrayGiftbagItem:register()
	UIEventListener.Get(self.purchaseBtn.gameObject).onClick = handler(self, function ()
		if self.isFree then
			if xyd.models.backpack:getItemNumByID(self.cost[1]) < self.cost[2] then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.cost[1])))

				return
			end

			xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
				if yes then
					local msg = messages_pb.get_activity_award_req()
					msg.activity_id = xyd.ActivityID.ALL_STARS_PRAY_GIFTBAG
					msg.params = cjson.encode({
						num = 1,
						id = tonumber(self.giftBagId)
					})

					xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
					self.parent.activityData:setBuyIndex(self.giftBagId)
				end
			end)
		else
			xyd.SdkManager.get():showPayment(self.giftBagId)
		end
	end)
end

function AllStarsPrayGiftbagItem:initItem()
	if self.isFree then
		self.cost = xyd.tables.activityPrayGiftTable:getCost(self.giftBagId)
		self.awards = xyd.tables.activityPrayGiftTable:getAwards(self.giftBagId)

		xyd.setUISpriteAsync(self.purchaseBtnBg, nil, "blue_btn_65_65")

		self.purchaseBtnLabel.color = Color.New2(4294967295.0)
		self.purchaseBtnLabel.effectColor = Color.New2(1012112383)

		self.purchaseBtnLabel:X(16)
		self.purchaseBtnLabel:Y(-1)
		self.vipLabel:SetActive(false)
		self.limitLabel:Y(-2)

		self.purchaseBtnLabel.text = tostring(self.cost[2])
	else
		self.awards = xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(self.giftBagId))

		xyd.setUISpriteAsync(self.purchaseBtnBg, nil, "mana_week_card_btn01")
		self.purchaseBtnIcon:SetActive(false)

		self.vipLabel.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftBagId) .. " VIP EXP"
		self.purchaseBtnLabel.text = xyd.tables.giftBagTextTable:getCurrency(self.giftBagId) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.giftBagId)
	end

	NGUITools.DestroyChildren(self.itemGroup.transform)

	for i in ipairs(self.awards) do
		local data = self.awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			xyd.getItemIcon({
				show_has_num = true,
				notShowGetWayBtn = true,
				scale = 0.6574074074074074,
				uiRoot = self.itemGroup.gameObject,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scrollView
			})
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

function AllStarsPrayGiftbagItem:updateState()
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(self.buyLimit - self.buyTimes))

	if self.buyLimit <= self.buyTimes then
		self.purchaseBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		xyd.applyChildrenGrey(self.purchaseBtn.gameObject)
	end
end

return AllStarsPrayGiftbag
