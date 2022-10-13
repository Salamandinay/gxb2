local ActivityContent = import(".ActivityContent")
local ActivityLegendarySkinGiftbag = class("ActivityLegendarySkinGiftbag", ActivityContent)
local ActivityLegendarySkinGiftbagItem = class("ActivityLegendarySkinGiftbagItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")
local ParnterImg = import("app.components.PartnerImg")

function ActivityLegendarySkinGiftbag:ctor(parentGO, params)
	self.lengarySkinID_ = 1

	ActivityContent.ctor(self, parentGO, params)
end

function ActivityLegendarySkinGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/activity_legendary_skin_giftbag"
end

function ActivityLegendarySkinGiftbag:initUI()
	self:getUIComponent()
	ActivityLegendarySkinGiftbag.super.initUI(self)
	self:initUIComponent()
	self:layout()
	self:updateRedMark()
	self:register()
end

function ActivityLegendarySkinGiftbag:getUIComponent()
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
	self.jumpBtn_ = go:NodeByName("jumpBtn").gameObject
	self.jumpBtnLabel_ = go:ComponentByName("jumpBtn/label", typeof(UILabel))
	self.contentBg = go:ComponentByName("contentGroup/Bg2_", typeof(UISprite))
	self.effectRoot_ = go:NodeByName("effectRoot").gameObject
	self.partnerImg = ParnterImg.new(self.effectRoot_)
end

function ActivityLegendarySkinGiftbag:resizeToParent()
	ActivityLegendarySkinGiftbag.super.resizeToParent(self)

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.contentGroup:Y(874 - p_height)
	self:resizePosY(self.contentBg.gameObject, -612, -446)
end

function ActivityLegendarySkinGiftbag:initUIComponent()
	self:setText()
	self:setItems()

	if xyd.Global.lang == "fr_fr" then
		self.timeLabel.transform:SetSiblingIndex(2)
	end

	self.timeGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityLegendarySkinGiftbag:layout()
	local skin_id = xyd.tables.activityLengarySkinTable:getShowSkin(self.lengarySkinID_)

	self.partnerImg:setImg({
		girl_model_height = 2000,
		showResLoading = true,
		windowName = self.name_,
		itemID = skin_id
	})

	local offset = xyd.tables.activityLengarySkinTable:getSkinOffest2(self.lengarySkinID_)
	local scale = xyd.tables.activityLengarySkinTable:getSkinScale(self.lengarySkinID_)
	self.effectRoot_.transform.localPosition = Vector3(offset[1], offset[2], 0)
	self.effectRoot_.transform.localScale = Vector3(scale, scale, scale)
end

function ActivityLegendarySkinGiftbag:register()
	UIEventListener.Get(self.jumpBtn_).onClick = function ()
		xyd.goToActivityWindowAgain({
			activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_LEGENDARY_SKIN),
			select = xyd.ActivityID.ACTIVITY_LEGENDARY_SKIN
		})
	end
end

function ActivityLegendarySkinGiftbag:setText()
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
	self.jumpBtnLabel_.text = __("ACTIVITY_LEGENDARY_SKIN_GIFTBAG_TEXT01")

	xyd.setUISpriteAsync(self.titleImg, nil, "activity_legendary_skin_gift_" .. xyd.Global.lang)
end

function ActivityLegendarySkinGiftbag:setItems()
	local collection_ = {}
	local awards = self.activityData.detail.award
	local limit = tonumber(xyd.tables.miscTable:getVal("legendary_skin_giftbag_limit", "value"))
	local params = {
		id = 1,
		isCrystal = true,
		data = {
			id = 1,
			buy_times = awards
		},
		hasBuy = limit <= awards
	}

	table.insert(collection_, params)

	local datas = self.activityData.detail.charges

	for i = 1, #datas do
		local limit = xyd.tables.giftBagTable:getBuyLimit(datas[i].table_id)
		local params = {
			isCrystal = false,
			id = i,
			data = datas[i],
			hasBuy = limit <= datas[i].buy_times
		}

		table.insert(collection_, params)
	end

	table.sort(collection_, function (a, b)
		if a.hasBuy == b.hasBuy then
			if a.isCrystal == b.isCrystal then
				return a.id < b.id
			else
				return xyd.bool2Num(b.isCrystal) < xyd.bool2Num(a.isCrystal)
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

		local item = ActivityLegendarySkinGiftbagItem.new(goItem, self, params)
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityLegendarySkinGiftbag:updateRedMark()
	self:waitForTime(0.5, function ()
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_LEGENDARY_SKIN_GIFTBAG, function ()
			xyd.db.misc:setValue({
				key = "activity_legendary_skin_giftbag",
				value = xyd.getServerTime()
			})
		end)
	end)
end

function ActivityLegendarySkinGiftbagItem:ctor(go, parent, params)
	ActivityLegendarySkinGiftbagItem.super.ctor(self, go)

	self.parent_ = parent
	self.isCrystal = params.isCrystal
	self.data = params.data

	self:getUIComponent()
	self:initUIComponent()
end

function ActivityLegendarySkinGiftbagItem:getUIComponent()
	local go = self:getGameObject()
	self.itemBg = go:ComponentByName("itemBg", typeof(UITexture))
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.groupIcon_uigrid = self.groupIcon:GetComponent(typeof(UIGrid))
	self.groupIcon2 = go:NodeByName("groupIcon2").gameObject
	self.groupIcon2_uigrid = self.groupIcon2:GetComponent(typeof(UIGrid))
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

function ActivityLegendarySkinGiftbagItem:initUIComponent()
	self:setIcon()
	self:setText()
	self:setBtn()
	self.groupIcon_uigrid:Reposition()
	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxyInner_:addEventListener(xyd.event.RECHARGE, handler(self, self.onRecharge))
	xyd.setDarkenBtnBehavior(self.btnPurchase, self, function ()
		if self.isCrystal then
			local cost = xyd.tables.miscTable:split2Cost("legendary_skin_giftbag_cost", "value", "@|#")[1][1]

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
					msg.activity_id = xyd.ActivityID.ACTIVITY_LEGENDARY_SKIN_GIFTBAG
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

function ActivityLegendarySkinGiftbagItem:onAward(event)
	if not self.isCrystal then
		return
	end

	self.data.buy_times = require("cjson").decode(event.data.detail).info.award

	xyd.models.itemFloatModel:pushNewItems(require("cjson").decode(event.data.detail).items)
	self:setText()
	self:setBtn()
end

function ActivityLegendarySkinGiftbagItem:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if giftBagID ~= self.data.table_id then
		return
	end

	self:setText()
	self:setBtn()
end

function ActivityLegendarySkinGiftbagItem:setText()
	if self.isCrystal then
		self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", tonumber(xyd.tables.miscTable:getVal("legendary_skin_giftbag_limit")) - self.data.buy_times)

		self.numLabel:SetActive(false)
		self.vipLabel:SetActive(false)
		xyd.setUISpriteAsync(self.btnPurchase:GetComponent(typeof(UISprite)), nil, "blue_btn_65_65")
	else
		self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", xyd.tables.giftBagTable:getBuyLimit(self.data.table_id) - self.data.buy_times)
		self.numLabel.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(self.data.table_id))
		self.vipLabel.text = "VIP EXP"

		xyd.setUISpriteAsync(self.btnPurchase:GetComponent(typeof(UISprite)), nil, "benefit_giftbag_btn3")
	end
end

function ActivityLegendarySkinGiftbagItem:setIcon()
	NGUITools.DestroyChildren(self.groupIcon.transform)
	NGUITools.DestroyChildren(self.groupIcon2.transform)

	local awards = nil

	if self.isCrystal then
		awards = xyd.tables.miscTable:split2Cost("legendary_skin_giftbag_cost", "value", "@|#")[2]
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
		local scales = {
			76,
			76,
			76,
			76,
			62,
			50
		}
		local gaps = {
			7,
			7,
			7,
			7,
			6,
			3
		}
		local scale = 0.7037037037037037

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local item = {}

			if i >= 3 then
				scale = scales[#awardNewArr] / 108
				item = {
					show_has_num = true,
					labelNumScale = 1.2,
					itemID = data[1],
					num = data[2],
					wndType = xyd.ItemTipsWndType.ACTIVITY,
					uiRoot = self.groupIcon2,
					scale = Vector3(scale, scale, scale),
					dragScrollView = self.parent_.scroller_
				}
				self.groupIcon2_uigrid.cellWidth = scales[#awardNewArr] + gaps[#awardNewArr]

				self.groupIcon2.transform:X(-106 - (76 - scales[#awardNewArr]) / 2)
				self:waitForFrame(2, function ()
					self.groupIcon2.transform:Y(0 - (76 - scales[#awardNewArr]) / 2)
				end)
				self.groupIcon2_uigrid:Reposition()
			else
				if data[1] >= 8000 and data[1] <= 9000 then
					scale = scale * 0.9
				end

				item = {
					show_has_num = true,
					labelNumScale = 1.2,
					itemID = data[1],
					num = data[2],
					wndType = xyd.ItemTipsWndType.ACTIVITY,
					uiRoot = self.groupIcon,
					scale = Vector3(scale, scale, scale),
					dragScrollView = self.parent_.scroller_
				}

				self:waitForFrame(2, function ()
					self.groupIcon.transform:Y(0)
				end)
				self.groupIcon_uigrid:Reposition()
			end

			local icon = xyd.getItemIcon(item)
		end
	end
end

function ActivityLegendarySkinGiftbagItem:setBtn()
	if self.isCrystal then
		local cryCost = xyd.tables.miscTable:split2Cost("legendary_skin_giftbag_cost", "value", "@|#")[1][1][2]
		self.crystal_label.text = tostring(cryCost)

		self.btnPurchase_label:SetActive(false)
		self.crystalGroup:SetActive(true)
	else
		self.btnPurchase_label.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.data.table_id)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.data.table_id))

		self.btnPurchase_label:SetActive(true)
		self.crystalGroup:SetActive(false)
	end

	local limit = 0

	if self.isCrystal then
		limit = tonumber(xyd.tables.miscTable:getVal("legendary_skin_giftbag_limit", "value"))
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

return ActivityLegendarySkinGiftbag
