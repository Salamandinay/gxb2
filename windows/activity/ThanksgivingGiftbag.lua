local ThanksgivingGiftbag = class("ThanksgivingGiftbag", import(".ActivityContent"))
local ThanksgivingGiftbagItem = class("ThanksgivingGiftbagItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local json = require("cjson")

function ThanksgivingGiftbag:ctor(parentGO, params)
	ThanksgivingGiftbag.super.ctor(self, parentGO, params)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_SECRET_TREASURE_HUNT_GIFTBAG, function ()
		xyd.db.misc:setValue({
			key = "thanksgiving_giftbag_view_time",
			value = xyd.getServerTime()
		})
	end)
end

function ThanksgivingGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/thanksgiving_giftbag"
end

function ThanksgivingGiftbag:resizeToParent()
	ThanksgivingGiftbag.super.resizeToParent(self)
	self:resizePosY(self.arrowDown, -846.5, -1022.5)
	self:resizePosY(self.groupModel, -160, -200)
end

function ThanksgivingGiftbag:initUI()
	self:getUIComponent()
	ThanksgivingGiftbag.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ThanksgivingGiftbag:getUIComponent()
	local go = self.go
	self.textImg = go:ComponentByName("panelLogo/textImg", typeof(UISprite))
	self.groupModel = go:NodeByName("groupModel").gameObject
	self.timeGroup = go:NodeByName("panelLogo/timeGroup").gameObject
	self.timeLayout = self.timeGroup:ComponentByName("", typeof(UILayout))
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
	self.scrollView = go:ComponentByName("scrollView", typeof(UIScrollView))
	self.scrollPanel = go:ComponentByName("scrollView", typeof(UIPanel))
	self.groupItems = self.scrollView:NodeByName("groupItems").gameObject
	self.groupArrow = go:NodeByName("groupArrow").gameObject
	self.arrowUp = self.groupArrow:ComponentByName("arrowUp", typeof(UISprite))
	self.arrowDown = self.groupArrow:ComponentByName("arrowDown", typeof(UISprite))
	self.giftbagItem = go:NodeByName("thanksgiving_giftbag_item").gameObject

	self.giftbagItem:SetActive(false)
	self.arrowUp:SetActive(false)
	self.arrowDown:SetActive(false)
end

function ThanksgivingGiftbag:initUIComponent()
	xyd.setUISpriteAsync(self.textImg, nil, "thanksgiving_giftbag_text_" .. xyd.Global.lang, nil, , true)

	if xyd.Global.lang == "fr_fr" then
		self.endLabel.transform:SetSiblingIndex(0)
	end

	CountDown.new(self.timeLabel, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel.text = __("END")

	self.timeLayout:Reposition()

	local infos = {}

	table.insert(infos, {
		is_free = true,
		limit_times = 1,
		table_id = 99999,
		buy_times = self.activityData.detail.buy_times
	})

	for i = 1, #self.activityData.detail.charges do
		table.insert(infos, {
			is_free = false,
			table_id = self.activityData.detail.charges[i].table_id,
			buy_times = self.activityData.detail.charges[i].buy_times,
			limit_times = self.activityData.detail.charges[i].limit_times
		})
	end

	table.sort(infos, function (a, b)
		local pointa = a.buy_times < a.limit_times
		local pointb = b.buy_times < b.limit_times

		if pointa ~= pointb then
			if pointa == true then
				return true
			else
				return false
			end
		end

		return b.table_id < a.table_id
	end)

	self.items = {}

	NGUITools.DestroyChildren(self.groupItems.transform)

	for i = 1, #infos do
		local go = NGUITools.AddChild(self.groupItems.gameObject, self.giftbagItem.gameObject)
		local item = ThanksgivingGiftbagItem.new(go, self)

		item:setInfo(infos[i])
		xyd.setDragScrollView(item.go, self.scrollView)
		table.insert(self.items, item)
	end

	self.groupItems:GetComponent(typeof(UILayout)):Reposition()
	self.scrollView:ResetPosition()
	self:waitForTime(0.3, function ()
		self:updateArrow()
	end)

	self.modelEffect = xyd.Spine.new(self.groupModel)

	self.modelEffect:setInfo("zhurong_pifu02_lihui01", function ()
		self.modelEffect:play("animation", 0)
		self.modelEffect:SetLocalScale(0.68, 0.68, 1)
		self.modelEffect:SetLocalPosition(-175, -860, 0)
	end)
end

function ThanksgivingGiftbag:updateArrow()
	local topDelta = 166 - self.scrollPanel.clipOffset.y
	local topNum = math.floor(topDelta / 293 + 0.6)
	local arrowUp = false

	for i = 1, topNum do
		arrowUp = arrowUp or true
	end

	self.arrowUp:SetActive(arrowUp)

	local nums = #self.items
	local botDelta = nums * 293 + 11 - self.scrollPanel.height - topDelta
	local botNum = math.floor(botDelta / 293 + 0.6)
	local arrowDown = false

	if botNum >= 1 then
		arrowDown = true
	end

	self.arrowDown:SetActive(arrowDown)
end

function ThanksgivingGiftbag:register()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))

	self.scrollView.onDragMoving = handler(self, self.updateArrow)

	UIEventListener.Get(self.arrowUp.gameObject).onClick = function ()
		local sp = self.scrollView.gameObject:GetComponent(typeof(SpringPanel))

		sp.Begin(sp.gameObject, Vector3(152, -786, 0), 16)
		self:waitForTime(0.3, function ()
			self:updateArrow()
		end)
	end

	UIEventListener.Get(self.arrowDown.gameObject).onClick = function ()
		local sp = self.scrollView.gameObject:GetComponent(typeof(SpringPanel))

		sp.Begin(sp.gameObject, Vector3(152, -283 - 177 * self.scale_num_contrary, 0), 16)
		self:waitForTime(0.3, function ()
			self:updateArrow()
		end)
	end
end

function ThanksgivingGiftbag:onRecharge(event)
	local giftbagID = event.data.giftbag_id

	for i = 1, #self.items do
		if self.items[i].table_id == giftbagID then
			self.items[i]:setInfo({
				buy_times = self.items[i].buy_times + 1
			})
		end
	end

	local awards = xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(giftbagID))

	for i = 1, #awards do
		local itemid = awards[i][1]
		local type = xyd.tables.itemTable:getType(itemid)

		if type == xyd.ItemType.SKIN then
			xyd.onGetNewPartnersOrSkins({
				destory_res = false,
				skins = {
					tonumber(itemid)
				}
			})
		end
	end
end

function ThanksgivingGiftbag:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.THANKSGIVING_GIFTBAG then
		return
	end

	for i = 1, #self.items do
		if self.items[i].is_free then
			self.items[i]:setInfo({
				buy_times = self.items[i].buy_times + 1
			})
		end
	end

	self.activityData.detail.buy_times = self.activityData.detail.buy_times + 1
	local itemInfos = {}
	local awards = xyd.tables.miscTable:split2Cost("thanksgiving_giftawards", "value", "|#")

	for i = 1, #awards do
		local award = awards[i]

		table.insert(itemInfos, {
			item_id = award[1],
			item_num = award[2]
		})
	end

	xyd.itemFloat(itemInfos)

	for i, item in pairs(itemInfos) do
		local type = xyd.tables.itemTable:getType(item.item_id)

		if type == xyd.ItemType.SKIN then
			xyd.onGetNewPartnersOrSkins({
				destory_res = false,
				skins = {
					tonumber(item.item_id)
				}
			})
		end
	end
end

function ThanksgivingGiftbagItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	self:initUIComponent()
	self:register()
end

function ThanksgivingGiftbagItem:initUIComponent()
	self.itemGroup1 = self.go:NodeByName("itemGroup1").gameObject
	self.itemGroup2 = self.go:NodeByName("itemGroup2").gameObject
	self.itemGroup3 = self.go:NodeByName("itemGroup3").gameObject
	self.limitLabel = self.go:ComponentByName("limitLabel", typeof(UILabel))
	self.vipLabel = self.go:ComponentByName("vipLabel", typeof(UILabel))
	self.purchaseBtn = self.go:NodeByName("purchaseBtn").gameObject
	self.purchaseBtnBg = self.purchaseBtn:GetComponent(typeof(UISprite))
	self.purchaseBtnLabel = self.purchaseBtn:ComponentByName("button_label", typeof(UILabel))
	self.purchaseBtnIcon = self.purchaseBtn:NodeByName("icon").gameObject
end

function ThanksgivingGiftbagItem:setInfo(params)
	if params.table_id then
		self.table_id = params.table_id
		self.is_free = params.is_free
		self.limit_times = params.limit_times

		if self.is_free then
			xyd.setUISpriteAsync(self.purchaseBtnBg, nil, "blue_btn_65_65")

			self.purchaseBtnLabel.color = Color.New2(4294967295.0)
			self.purchaseBtnLabel.effectColor = Color.New2(1012112383)

			self.purchaseBtnLabel:X(16)
			self.purchaseBtnLabel:Y(-1)
			self.itemGroup1:Y(75)
			self.itemGroup2:Y(12)
			self.itemGroup3:Y(81)
			self.purchaseBtn:Y(-60)
			self.limitLabel:Y(-107.5)
			self.vipLabel:SetActive(false)

			local cost = xyd.tables.miscTable:split2Cost("thanksgiving_giftcost", "value", "#")
			local awards = xyd.tables.miscTable:split2Cost("thanksgiving_giftawards", "value", "|#")
			self.purchaseBtnLabel.text = tostring(cost[2])
			local awardNum = 1

			for i in ipairs(awards) do
				local data = awards[i]

				if data[1] ~= xyd.ItemID.VIP_EXP then
					xyd.getItemIcon({
						notShowGetWayBtn = true,
						show_has_num = true,
						uiRoot = awardNum == 2 and self.itemGroup3.gameObject or awardNum <= 3 and self.itemGroup1.gameObject or self.itemGroup2.gameObject,
						itemID = data[1],
						num = data[2],
						wndType = xyd.ItemTipsWndType.ACTIVITY,
						scale = awardNum == 2 and 0.6666666666666666 or 0.5555555555555556,
						dragScrollView = self.parent.scrollView,
						isNew = xyd.tables.itemTable:getType(data[1]) == xyd.ItemType.SKIN
					})

					awardNum = awardNum + 1
				end
			end

			self.itemGroup1:GetComponent(typeof(UILayout)):Reposition()
			self.itemGroup2:GetComponent(typeof(UILayout)):Reposition()
		else
			xyd.setUISpriteAsync(self.purchaseBtnBg, nil, "mana_week_card_btn01")
			self.purchaseBtnIcon:SetActive(false)

			self.vipLabel.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.table_id) .. " VIP EXP"
			self.purchaseBtnLabel.text = xyd.tables.giftBagTextTable:getCurrency(self.table_id) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.table_id)
			local awards = xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(self.table_id))
			local awardNum = 1

			for i in ipairs(awards) do
				local data = awards[i]

				if data[1] ~= xyd.ItemID.VIP_EXP then
					xyd.getItemIcon({
						notShowGetWayBtn = true,
						show_has_num = true,
						uiRoot = awardNum == 2 and self.itemGroup3.gameObject or awardNum <= 3 and self.itemGroup1.gameObject or self.itemGroup2.gameObject,
						itemID = data[1],
						num = data[2],
						wndType = xyd.ItemTipsWndType.ACTIVITY,
						scale = awardNum == 2 and 0.6666666666666666 or 0.5555555555555556,
						dragScrollView = self.parent.scrollView,
						isNew = xyd.tables.itemTable:getType(data[1]) == xyd.ItemType.SKIN
					})

					awardNum = awardNum + 1
				end
			end

			self.itemGroup1:GetComponent(typeof(UILayout)):Reposition()
			self.itemGroup2:GetComponent(typeof(UILayout)):Reposition()
		end
	end

	if params.buy_times then
		self.buy_times = params.buy_times
		self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(self.limit_times - self.buy_times))

		if self.limit_times <= self.buy_times then
			self.purchaseBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

			xyd.applyChildrenGrey(self.purchaseBtn.gameObject)
		end
	end
end

function ThanksgivingGiftbagItem:register()
	UIEventListener.Get(self.purchaseBtn.gameObject).onClick = handler(self, function ()
		if self.is_free then
			local data = {
				award_id = 1
			}
			local cost = xyd.tables.miscTable:split2Cost("thanksgiving_giftcost", "value", "#")

			if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

				return
			end

			xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
				if yes then
					local msg = messages_pb.get_activity_award_req()
					msg.activity_id = xyd.ActivityID.THANKSGIVING_GIFTBAG
					msg.params = json.encode(data)

					xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
				end
			end)

			return
		end

		xyd.SdkManager.get():showPayment(self.table_id)
	end)
end

return ThanksgivingGiftbag
