local ActivityContent = import(".ActivityContent")
local ActivityRepairGiftBag = class("LevelUpGiftBag", ActivityContent)
local FundItem = class("FundItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")

function FundItem:ctor(go, parent)
	self.go = go

	self:getUIComponent()
	self:setDragScrollView(parent:getScrollView())

	self.parent = parent
	self.eventProxy_ = xyd.EventProxy.new(xyd.EventDispatcher.inner(), self)
	self.isFirstInit = true
end

function FundItem:getGiftBagID()
	return self.giftBagID
end

function FundItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.info = info
	self.data = info.data

	if self.giftBagID ~= info.giftBagID then
		self.isFirstInit = true
	end

	self.giftBagID = info.giftBagID
	self.parentScroller = info.parentScroller

	self.go:SetActive(true)
	self:initUIComponent()
end

function FundItem:getUIComponent()
	local go = self.go
	self.itemBg = go:ComponentByName("itemBg", typeof(UITexture))
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.groupIcon_UIGrid = go:ComponentByName("groupIcon", typeof(UIGrid))
	self.groupIcon_uigrid = self.groupIcon:GetComponent(typeof(UIGrid))
	self.groupIcon2 = go:NodeByName("groupIcon2").gameObject
	self.groupIcon2_UIGrid = go:ComponentByName("groupIcon2", typeof(UIGrid))
	self.labelItemText01 = go:ComponentByName("labelItemText01", typeof(UILabel))
	self.labelItemText02 = go:ComponentByName("labelItemText02", typeof(UILabel))
	self.labelItemLimit = go:ComponentByName("labelItemLimit", typeof(UILabel))
	self.btnPurchase = go:NodeByName("btnPurchase").gameObject
	self.btnPurchaseImg = go:ComponentByName("btnPurchase", typeof(UISprite))
	self.btnPurchase_label = go:ComponentByName("btnPurchase/button_label", typeof(UILabel))
	self.redMark = self.btnPurchase:ComponentByName("redMark", typeof(UISprite))
	self.prop_buy_con = self.btnPurchase:NodeByName("prop_buy_con").gameObject
	self.prop_buy_con_layout = self.btnPurchase:ComponentByName("prop_buy_con", typeof(UILayout))
	self.prop_icon = self.prop_buy_con:ComponentByName("prop_icon", typeof(UISprite))
	self.prop_text = self.prop_buy_con:ComponentByName("prop_text", typeof(UILabel))

	self.btnPurchase:GetComponent(typeof(UIWidget)).onDispose = function ()
		self.eventProxy_:removeAllEventListeners()
	end
end

function FundItem:initUIComponent()
	if self.isFirstInit then
		self:setIcon()
		self:setTextures()

		self.isFirstInit = false
	end

	self:setText()
	self:setBtn()

	self.groupIcon_uigrid.enabled = true
end

function FundItem:setTextures()
end

function FundItem:setText()
	if self.info.isFree ~= nil and self.info.isFree == true then
		self.labelItemLimit.text = __("BUY_GIFTBAG_LIMIT", 1)
		self.labelItemText02.text = "+" .. 0
	elseif self.info.isCrystal ~= nil and self.info.isCrystal == true then
		self.labelItemLimit.text = __("BUY_GIFTBAG_LIMIT", tonumber(self.info.limit) - tonumber(self.info.data))
		self.labelItemText02.text = "+" .. 0
	else
		self.labelItemLimit.text = __("BUY_GIFTBAG_LIMIT", xyd.tables.giftBagTable:getBuyLimit(self.giftBagID) - self.data.buy_times)
		self.labelItemText02.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(self.giftBagID))
	end

	self.labelItemText01.text = "VIP EXP"

	if self.info.isShowVipExp ~= nil and self.info.isShowVipExp == false then
		self.labelItemText01.text = ""
		self.labelItemText02.text = ""
	end
end

function FundItem:setIcon()
	local giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID)
	local awards = xyd.tables.giftTable:getAwards(giftID)

	if self.info.isFree ~= nil then
		awards = xyd.tables.giftTable:getAwards(self.giftBagID)
	end

	if self.info.isCrystal ~= nil then
		awards = self.info.award
	end

	NGUITools.DestroyChildren(self.groupIcon.transform)
	NGUITools.DestroyChildren(self.groupIcon2.transform)

	if not awards then
		return
	end

	if #awards > 1 then
		self.groupIcon2:SetActive(true)
	else
		self.groupIcon2:SetActive(false)
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
			local scale = 0.6759259259259259
			local icaonGroup = self.groupIcon

			if #awardNewArr > 1 and i > 1 then
				scale = 0.6018518518518519
				icaonGroup = self.groupIcon2
			end

			local item = {
				show_has_num = true,
				labelNumScale = 1.2,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = icaonGroup,
				scale = Vector3(scale, scale, scale),
				dragScrollView = self.parentScroller
			}
			local icon = xyd.getItemIcon(item)
		end
	end

	self.groupIcon_UIGrid:Reposition()
	self.groupIcon2_UIGrid:Reposition()
end

function FundItem:setBtn()
	self.redMark:SetActive(false)

	if self.info.isCrystal ~= nil then
		self.btnPurchase_label.text = ""
		UIEventListener.Get(self.btnPurchase.gameObject).onClick = handler(self, function ()
			if xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL) < tonumber(self.info.cost[2]) then
				xyd.alertConfirm(__("CRYSTAL_NOT_ENOUGH"), function (yes)
					if yes then
						xyd.WindowManager.get():closeWindow("item_buy_window")
						xyd.WindowManager.get():openWindow("vip_window")
					end
				end, __("BUY"))

				return
			end

			xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
				if yes then
					local msg = messages_pb:get_activity_award_req()
					msg.activity_id = tonumber(self.info.activityid)
					local data = {
						num = 1
					}
					local cjson = require("cjson")
					msg.params = cjson.encode(data)

					xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
				end
			end)
		end)

		self.prop_buy_con:SetActive(true)
		xyd.setUISpriteAsync(self.prop_icon, nil, "icon_" .. self.info.cost[1], nil, )

		self.prop_text.text = self.info.cost[2]

		self.prop_buy_con_layout:Reposition()
		xyd.setUISpriteAsync(self.btnPurchaseImg, nil, "activity_repair_giftbag_btn_l", nil, )

		if self.info.isCrystalCan == true then
			self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

			xyd.applyChildrenOrigin(self.btnPurchase.gameObject)
			self.labelItemLimit:SetActive(true)

			local lastViewTime = xyd.db.misc:getValue("activity_repair_giftbag_view_time")

			if lastViewTime and xyd.isSameDay(tonumber(lastViewTime), xyd.getServerTime()) then
				self.redMark:SetActive(false)
			else
				self.redMark:SetActive(true)
			end
		else
			self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

			xyd.applyChildrenGrey(self.btnPurchase.gameObject)
			self.labelItemLimit:SetActive(false)
			self.redMark:SetActive(false)
		end
	else
		self.prop_buy_con:SetActive(false)
	end

	if self.info.isFree == nil and self.info.isCrystal == nil then
		xyd.setUISpriteAsync(self.btnPurchaseImg, nil, "activity_repair_giftbag_btn_h", nil, )

		self.btnPurchase_label.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftBagID))

		self.redMark:SetActive(false)
		xyd.setDarkenBtnBehavior(self.btnPurchase, self, function ()
			xyd.SdkManager.get():showPayment(self.giftBagID)
		end)

		if xyd.tables.giftBagTable:getBuyLimit(self.giftBagID) <= self.data.buy_times then
			self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

			xyd.applyChildrenGrey(self.btnPurchase.gameObject)
			self.labelItemLimit:SetActive(false)
		else
			self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

			xyd.applyChildrenOrigin(self.btnPurchase.gameObject)
			self.labelItemLimit:SetActive(true)
		end
	end
end

function FundItem:updateFreeBtn()
	if self ~= nil and self.info ~= nil and self.info.isFree ~= nil and self.btnPurchase then
		self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		xyd.applyChildrenGrey(self.btnPurchase.gameObject)
		self.labelItemLimit:SetActive(false)
		self.redMark:SetActive(false)
		self.parent:updateFreeList({
			giftbag_id = self.info.giftBagID
		})
	end
end

function FundItem:updateCrystalBtn()
	if self ~= nil and self.info ~= nil and self.info.isCrystal ~= nil and self.btnPurchase then
		self.info.data = tonumber(self.info.data) + 1
		self.labelItemLimit.text = __("BUY_GIFTBAG_LIMIT", tonumber(self.info.limit) - tonumber(self.info.data))
		local items = {}

		for i in pairs(self.info.award) do
			local dataArward = {
				item_id = self.info.award[i][1],
				item_num = self.info.award[i][2]
			}

			table.insert(items, dataArward)
		end

		xyd.itemFloat(items, nil, , self.info.parentScroller:GetComponent(typeof(UIPanel)).depth + 1)

		if tonumber(self.info.limit) <= tonumber(self.info.data) then
			self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

			xyd.applyChildrenGrey(self.btnPurchase.gameObject)
			self.labelItemLimit:SetActive(false)
			self.redMark:SetActive(false)
			self.parent:updateCrystalList({
				giftbag_id = self.info.giftBagID
			})
		end
	end
end

function FundItem:initItem()
	self:setText()
	self:setBtn()
	self.setIcon()
end

function ActivityRepairGiftBag:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)
end

function ActivityRepairGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/repair_giftbag"
end

function ActivityRepairGiftBag:initUI()
	self:getUIComponent()
	ActivityRepairGiftBag.super.initUI(self)

	self.items = {}

	self:initUIComponent()
	self:onRegisterEvent()
end

function ActivityRepairGiftBag:getUIComponent()
	local go = self.go
	self.fundItem = go:NodeByName("fundItem").gameObject
	self.imgBg = go:NodeByName("imgBg").gameObject
	self.imgBg_ = go:ComponentByName("imgBg", typeof(UISprite))
	self.logo_ = go:ComponentByName("logo", typeof(UISprite))
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.labelTime = self.timeGroup:ComponentByName("endtime", typeof(UILabel))
	self.endText_ = self.timeGroup:ComponentByName("endText", typeof(UILabel))
	self.imageDown_ = go:ComponentByName("e:ImageDown", typeof(UISprite))
	self.imageUp_ = go:ComponentByName("e:ImageUp", typeof(UISprite))
	self.scroller_ = go:ComponentByName("scroller", typeof(UIScrollView))
	self.wrapContentCon = go:ComponentByName("scroller/fundGroup", typeof(UIWrapContent))

	self:initWrapContent()
end

function ActivityRepairGiftBag:initWrapContent()
	self.wrapContent = FixedWrapContent.new(self.scroller_, self.wrapContentCon, self.fundItem, FundItem, self)
end

function ActivityRepairGiftBag:initUIComponent()
	xyd.db.misc:setValue({
		key = "activity_repair_giftbag_view_time",
		value = xyd.getServerTime()
	})
	self:setText()
	self:setItems()
	self:setTextures()
	self:initTime()
end

function ActivityRepairGiftBag:initTime()
	if self.activityData:getUpdateTime() - xyd.getServerTime() > 0 then
		local countdown = CountDown.new(self.labelTime, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime(),
			callback = handler(self, self.timeOver)
		})
	else
		self.labelTime.text = "00:00:00"

		self.labelTime:SetActive(false)
		self.endText_:SetActive(false)
	end
end

function ActivityRepairGiftBag:timeOver()
	self.labelTime.text = "00:00:00"
end

function ActivityRepairGiftBag:onRegisterEvent()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function ActivityRepairGiftBag:setTextures()
	xyd.setUISpriteAsync(self.logo_, nil, "activity_repair_giftbag_logo_" .. xyd.Global.lang, nil, , true)
	self:resizePosY(self.imgBg, -490, -530)
end

function ActivityRepairGiftBag:setText()
	self.endText_.text = __("TEXT_END")

	if xyd.Global.lang == "fr_fr" then
		self.endText_.transform:SetSiblingIndex(0)
		self.labelTime.transform:SetSiblingIndex(1)
	end

	if xyd.Global.lang == "de_de" then
		self.timeGroup:X(128)
	end
end

function ActivityRepairGiftBag:getItemInfos()
	local cantBuy = {}
	local result = {}
	local diamondGiftBagInfo = xyd.tables.miscTable:split2Cost("activity_repair_console_diamonds_giftbag", "value", "@|#")
	local diamondGIftBagByLitmit = xyd.tables.miscTable:getVal("activity_repair_console_diamonds_giftbag_limit")
	local limit = tonumber(diamondGIftBagByLitmit)
	local data = self.activityData.detail.award
	local isCrystalCan = tonumber(data) < limit
	local item1 = {
		isShowVipExp = false,
		isCrystal = true,
		cost = diamondGiftBagInfo[1][1],
		limit = limit,
		data = data,
		isCrystalCan = isCrystalCan,
		award = diamondGiftBagInfo[2],
		activityid = self.activityData.activity_id
	}
	local datas = self.activityData.detail.charges

	for i = 1, #datas do
		local data = datas[i]
		local id = data.table_id
		local params = {
			giftBagID = id,
			data = data,
			parentScroller = self.scroller
		}

		if xyd.tables.giftBagTable:getBuyLimit(id) <= data.buy_times then
			table.insert(cantBuy, params)
		else
			table.insert(result, params)
		end
	end

	if item1.isCrystalCan then
		table.insert(result, 1, item1)
	else
		table.insert(result, item1)
	end

	for i = 1, #cantBuy do
		local params = cantBuy[i]

		table.insert(result, params)
	end

	return result
end

function ActivityRepairGiftBag:setItems()
	local t = self:getItemInfos()
	self.firstItemArr = t

	self.wrapContent:setInfos(t, {})
end

function ActivityRepairGiftBag:onRecharge(event)
	local t = self:getItemInfos()

	self.wrapContent:setInfos(t, {})
end

function ActivityRepairGiftBag:onAward(event)
	local data = event.data

	if data.activity_id == xyd.ActivityID.ACTIVITY_REPAIR_GIFTBAG then
		local t = self:getItemInfos()

		self.wrapContent:setInfos(t, {})
	end
end

function ActivityRepairGiftBag:getScrollView()
	return self.scroller
end

return ActivityRepairGiftBag
