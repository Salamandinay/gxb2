local ActivityContent = import(".ActivityContent")
local ActivityCrystalGift = class("ActivityCrystalGift", ActivityContent)
local ActivityCrystalGiftItem = class("ActivityCrystalGiftItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")

function ActivityCrystalGift:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)
end

function ActivityCrystalGift:getPrefabPath()
	return "Prefabs/Windows/activity/activity_crystal"
end

function ActivityCrystalGift:initUI()
	self:getUIComponent()
	ActivityCrystalGift.super.initUI(self)
	self:initUIComponent()
	self:updateRedMark()
end

function ActivityCrystalGift:getUIComponent()
	local go = self.go
	self.titleImg = go:ComponentByName("titleImg", typeof(UISprite))
	self.textLabel = go:ComponentByName("textLabel", typeof(UILabel))
	self.timeBg = go:ComponentByName("timeBg_", typeof(UISprite))
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.timeLabel = go:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.endLabel = go:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.scroller_ = self.contentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.contentGroup:NodeByName("scroller/itemGroup").gameObject
	self.itemCell = self.contentGroup:NodeByName("itemCell").gameObject
end

function ActivityCrystalGift:resizeToParent()
	ActivityCrystalGift.super.resizeToParent(self)

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.contentGroup:Y(874 - p_height)
	self:resizePosY(self.titleImg.gameObject, -162, -197)
	self:resizePosY(self.timeGroup.gameObject, -307, -382)
	self:resizePosY(self.contentGroup.gameObject, 0, -115)
end

function ActivityCrystalGift:initUIComponent()
	self:setText()
	self:setItems()

	if xyd.Global.lang == "fr_fr" then
		self.timeLabel.transform:SetSiblingIndex(2)
	end

	self.timeGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityCrystalGift:setText()
	if self.activityData:getUpdateTime() - xyd.getServerTime() > 0 then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	self.endLabel.text = __("TEXT_END")
	self.textLabel.text = __("ACTIVITY_CRYSTAL_GIFT_TEXT")

	xyd.setUISpriteAsync(self.titleImg, nil, "activity_crystal_gift_" .. xyd.Global.lang, nil, , true)
end

function ActivityCrystalGift:setItems()
	local collection_ = {}
	local awards = self.activityData.detail.awards

	for i = 1, #awards do
		local limit = xyd.tables.activityCrystalGiftTable:getLimit(i)
		local params = {
			isCrtstal = true,
			id = i,
			data = {
				buy_times = awards[i],
				id = i
			},
			hasBuy = limit <= awards[i]
		}

		table.insert(collection_, params)
	end

	local datas = self.activityData.detail.charges

	dump(self.activityData.detail)

	for i = 1, #datas do
		local limit = xyd.tables.giftBagTable:getBuyLimit(datas[i].table_id)
		local params = {
			isCrtstal = false,
			id = i,
			data = datas[i],
			hasBuy = limit <= datas[i].buy_times
		}

		table.insert(collection_, params)
	end

	table.sort(collection_, function (a, b)
		if a.hasBuy == b.hasBuy then
			if a.isCrtstal == b.isCrtstal then
				return a.id < b.id
			else
				return xyd.bool2Num(b.isCrtstal) < xyd.bool2Num(a.isCrtstal)
			end
		else
			return xyd.bool2Num(a.hasBuy) < xyd.bool2Num(b.hasBuy)
		end
	end)

	for i = 1, #collection_ do
		local params = collection_[i]
		local goItem = NGUITools.AddChild(self.itemGroup, self.itemCell)

		goItem:SetActive(true)
		xyd.setDragScrollView(goItem, self.scroller_)

		local item = ActivityCrystalGiftItem.new(goItem, self, params)
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityCrystalGift:updateRedMark()
	self:waitForTime(0.5, function ()
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_CRYSTAL_GIFT, function ()
			xyd.db.misc:setValue({
				key = "activity_crystal_gift",
				value = xyd.getServerTime()
			})
		end)
	end)
end

function ActivityCrystalGiftItem:ctor(go, parent, params)
	ActivityCrystalGiftItem.super.ctor(self, go)

	self.parent_ = parent
	self.isCrtstal = params.isCrtstal
	self.data = params.data

	self:getUIComponent()
	self:initUIComponent()
end

function ActivityCrystalGiftItem:getUIComponent()
	local go = self:getGameObject()
	self.itemBg = go:ComponentByName("itemBg", typeof(UITexture))
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.groupIcon_uigrid = self.groupIcon:GetComponent(typeof(UIGrid))
	self.vipLabel = go:ComponentByName("vipLabel", typeof(UILabel))
	self.numLabel = go:ComponentByName("numLabel", typeof(UILabel))
	self.limitLabel = go:ComponentByName("limitLabel", typeof(UILabel))
	self.btnPurchase = go:NodeByName("btnPurchase").gameObject
	self.btnPurchase_label = go:ComponentByName("btnPurchase/label", typeof(UILabel))
	self.crystalGroup = go:NodeByName("btnPurchase/crystalGroup").gameObject
	self.crystal_label = go:ComponentByName("btnPurchase/crystalGroup/label", typeof(UILabel))

	self.btnPurchase_label:SetActive(false)
	self.crystalGroup:SetActive(false)

	self.redMark = go:ComponentByName("redMark", typeof(UISprite))
end

function ActivityCrystalGiftItem:initUIComponent()
	self:setIcon()
	self:setText()
	self:setBtn()
	self.groupIcon_uigrid:Reposition()
	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxyInner_:addEventListener(xyd.event.RECHARGE, handler(self, self.onRecharge))
	xyd.setDarkenBtnBehavior(self.btnPurchase, self, function ()
		if self.isCrtstal then
			local cost = xyd.tables.activityCrystalGiftTable:getCost(self.data.id)

			if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
				xyd.alert(xyd.AlertType.YES_NO, __("CRYSTAL_NOT_ENOUGH"), function (flag)
					if flag then
						xyd.openWindow("vip_window")
					end
				end)

				return
			end

			xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (flag)
				if flag then
					local msg = messages_pb.get_activity_award_req()
					msg.activity_id = xyd.ActivityID.ACTIVITY_CRYSTAL_GIFT
					msg.params = require("cjson").encode({
						table_id = self.data.id
					})

					xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
				end
			end)
		else
			xyd.SdkManager.get():showPayment(self.data.table_id)
		end
	end)
end

function ActivityCrystalGiftItem:onAward(event)
	if not self.isCrtstal then
		return
	end

	self.data.buy_times = require("cjson").decode(event.data.detail).info.awards[self.data.id]

	xyd.models.itemFloatModel:pushNewItems(require("cjson").decode(event.data.detail).items)
	self:setText()
	self:setBtn()
end

function ActivityCrystalGiftItem:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if giftBagID ~= self.data.table_id then
		return
	end

	self:setText()
	self:setBtn()
end

function ActivityCrystalGiftItem:setText()
	if self.isCrtstal then
		self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", xyd.tables.activityCrystalGiftTable:getLimit(self.data.id) - self.data.buy_times)

		self.numLabel:SetActive(false)
		self.vipLabel:SetActive(false)
	else
		self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", xyd.tables.giftBagTable:getBuyLimit(self.data.table_id) - self.data.buy_times)
		self.numLabel.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(self.data.table_id))
		self.vipLabel.text = "VIP EXP"
	end
end

function ActivityCrystalGiftItem:setIcon()
	NGUITools.DestroyChildren(self.groupIcon.transform)

	local awards = nil

	if self.isCrtstal then
		awards = xyd.tables.activityCrystalGiftTable:getAwards(self.data.id)
	else
		awards = xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(self.data.table_id))
	end

	if not awards then
		return
	end

	local awardNewArr = {}

	for i = 1, #awards do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			table.insert(awardNewArr, data)
		end
	end

	for i = 1, #awardNewArr do
		local data = awardNewArr[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local scale = 0.6481481481481481
			local item = {
				show_has_num = true,
				labelNumScale = 1.2,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = self.groupIcon,
				scale = Vector3(scale, scale, scale),
				dragScrollView = self.parent_.scroller_
			}
			local icon = xyd.getItemIcon(item)
		end
	end
end

function ActivityCrystalGiftItem:setBtn()
	if self.isCrtstal then
		self.crystal_label.text = tostring(xyd.tables.activityCrystalGiftTable:getCost(self.data.id)[2])

		self.btnPurchase_label:SetActive(false)
		self.crystalGroup:SetActive(true)
	else
		self.btnPurchase_label.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.data.table_id)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.data.table_id))

		self.btnPurchase_label:SetActive(true)
		self.crystalGroup:SetActive(false)
	end

	local limit = 0

	if self.isCrtstal then
		limit = xyd.tables.activityCrystalGiftTable:getLimit(self.data.id)
	else
		limit = xyd.tables.giftBagTable:getBuyLimit(self.data.table_id)
	end

	if limit <= self.data.buy_times then
		self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		xyd.applyChildrenGrey(self.btnPurchase)
	else
		self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

		xyd.applyChildrenOrigin(self.btnPurchase)
	end
end

return ActivityCrystalGift
