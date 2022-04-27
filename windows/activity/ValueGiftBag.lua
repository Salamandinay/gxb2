local ActivityContent = import(".ActivityContent")
local ValueGiftBag = class("ValueGiftBag", ActivityContent)
local ValueGiftBagItem = class("ValueGiftBagItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")

function ValueGiftBag:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)
end

function ValueGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/value_giftbag"
end

function ValueGiftBag:initUI()
	self:getUIComponent()
	ValueGiftBag.super.initUI(self)

	self.items = {}

	self:initUIComponent()
	self:onRegisterEvent()
end

function ValueGiftBag:getUIComponent()
	local go = self.go
	self.floatCon = go:NodeByName("floatCon").gameObject
	self.imgBg = go:ComponentByName("imgBg", typeof(UISprite))
	self.imgText01 = go:ComponentByName("imgText01", typeof(UISprite))
	self.imgText02 = go:ComponentByName("imgText02", typeof(UISprite))
	self.e_Image = go:ComponentByName("e:Image", typeof(UISprite))
	self.labelTime = go:ComponentByName("labelTime", typeof(UILabel))
	self.labelText01 = go:ComponentByName("labelText01", typeof(UILabel))
	self.scroller = go:ComponentByName("scroller", typeof(UIScrollView))
	self.scroller_Panel = go:ComponentByName("scroller", typeof(UIPanel))
	self.groupPackage = go:NodeByName("scroller/groupPackage").gameObject
	self.common_giftbag_item = go:NodeByName("common_giftbag_item").gameObject
	self.wrapContentCon = go:ComponentByName("scroller/groupPackage", typeof(UIWrapContent))

	self:initWrapContent()
end

function ValueGiftBag:initWrapContent()
	self.wrapContent = FixedWrapContent.new(self.scroller, self.wrapContentCon, self.common_giftbag_item, ValueGiftBagItem, self)
end

function ValueGiftBag:initUIComponent()
	self:setText()
	self:setItems()
	self:setTextures()
	self:initTime()
end

function ValueGiftBag:initTime()
	if self.activityData:getUpdateTime() - xyd.getServerTime() > 0 then
		local countdown = CountDown.new(self.labelTime, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime(),
			callback = handler(self, self.timeOver)
		})
	else
		self.labelTime.text = "00:00:00"

		self.labelTime:SetActive(false)
		self.labelText01:SetActive(false)
	end
end

function ValueGiftBag:timeOver()
	self.labelTime.text = "00:00:00"
end

function ValueGiftBag:onRegisterEvent()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function ValueGiftBag:setTextures()
	if xyd.Global.lang ~= "en_en" then
		xyd.setUISpriteAsync(self.imgText01, nil, "value_giftbag_text01_" .. xyd.Global.lang, nil, , true)
	end

	xyd.setUISpriteAsync(self.imgText02, nil, "value_giftbag_text02_" .. xyd.Global.lang, nil, , true)
	xyd.setUISpriteAsync(self.imgBg, nil, "value_giftbag_bg01", nil, , true)

	if xyd.Global.lang == "en_en" then
		self.imgText02:Y(-135)
	elseif xyd.Global.lang == "de_de" then
		self.imgText01:Y(-175)
		self.imgText02:Y(-110)
	elseif xyd.Global.lang == "fr_fr" then
		self.imgText01:X(167)
		self.imgText02:X(167)
	end
end

function ValueGiftBag:setText()
	self.labelText01.text = __("TEXT_END")
end

function ValueGiftBag:getItemInfos()
	local cantBuy = {}
	local t = {}
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
			table.insert(t, params)
		end
	end

	for i = 1, #cantBuy do
		local params = cantBuy[i]

		table.insert(t, params)
	end

	return t
end

function ValueGiftBag:setItems()
	local t = self:getItemInfos()
	self.firstItemArr = t

	self.wrapContent:setInfos(t, {})

	local datas = self.activityData.detail.charges
end

function ValueGiftBag:onRecharge(event)
	local giftBagID = event.data.giftbag_id
	local t = self:getItemInfos()
	local isGoOn = false

	for i in pairs(t) do
		for j in pairs(self.firstItemArr) do
			if giftBagID == t[i].giftBagID and giftBagID == self.firstItemArr[j].giftBagID then
				self.firstItemArr[j] = t[i]
				isGoOn = true

				break
			end
		end

		if isGoOn then
			break
		end
	end

	self.wrapContent:setInfos(self.firstItemArr, {})
end

function ValueGiftBag:updateFreeList(data)
	local giftBagID = data.giftbag_id
	local t = self:getItemInfos()
	local isGoOn = false

	for i in pairs(t) do
		for j in pairs(self.firstItemArr) do
			if giftBagID == t[i].giftBagID and giftBagID == self.firstItemArr[j].giftBagID then
				self.firstItemArr[j] = t[i]
				isGoOn = true

				break
			end
		end

		if isGoOn then
			break
		end
	end
end

function ValueGiftBag:updateCrystalList(data)
	local giftBagID = data.giftbag_id
	local t = self:getItemInfos()
	local isGoOn = false

	for i in pairs(t) do
		for j in pairs(self.firstItemArr) do
			if giftBagID == t[i].giftBagID and giftBagID == self.firstItemArr[j].giftBagID then
				self.firstItemArr[j] = t[i]
				isGoOn = true

				break
			end
		end

		if isGoOn then
			break
		end
	end
end

function ValueGiftBag:getScrollView()
	return self.scroller
end

function ValueGiftBagItem:ctor(go, parent)
	self.go = go

	self:getUIComponent()
	self:setDragScrollView(parent:getScrollView())

	self.parent = parent
	self.eventProxy_ = xyd.EventProxy.new(xyd.EventDispatcher.inner(), self)

	self.eventProxy_:addEventListener("updateBt", handler(self, self.updateFreeBtn))
	self.eventProxy_:addEventListener("updateBtCrystal", handler(self, self.updateCrystalBtn))

	self.isFirstInit = true
end

function ValueGiftBagItem:getGiftBagID()
	return self.giftBagID
end

function ValueGiftBagItem:update(index, info)
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

function ValueGiftBagItem:getUIComponent()
	local go = self.go
	self.itemBg = go:ComponentByName("itemBg", typeof(UITexture))
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.groupIcon_UIGrid = go:ComponentByName("groupIcon", typeof(UIGrid))
	self.groupIcon2 = go:NodeByName("groupIcon2").gameObject
	self.groupIcon2_UIGrid = go:ComponentByName("groupIcon2", typeof(UIGrid))
	self.groupIcon_uigrid = self.groupIcon:GetComponent(typeof(UIGrid))
	self.labelItemText01 = go:ComponentByName("labelItemText01", typeof(UILabel))
	self.labelItemText02 = go:ComponentByName("labelItemText02", typeof(UILabel))
	self.labelItemLimit = go:ComponentByName("labelItemLimit", typeof(UILabel))
	self.btnPurchase = go:NodeByName("btnPurchase").gameObject
	self.btnPurchase_label = go:ComponentByName("btnPurchase/button_label", typeof(UILabel))
	self.redMark = self.btnPurchase:ComponentByName("redMark", typeof(UISprite))
	self.prop_buy_con = self.btnPurchase:NodeByName("prop_buy_con").gameObject
	self.prop_buy_con_layout = self.btnPurchase:ComponentByName("prop_buy_con", typeof(UILayout))
	self.prop_icon = self.prop_buy_con:ComponentByName("prop_icon", typeof(UISprite))
	self.prop_text = self.prop_buy_con:ComponentByName("prop_text", typeof(UILabel))

	self.btnPurchase:GetComponent(typeof(UIWidget)).onDispose = function ()
		self.eventProxy_:removeAllEventListeners()
	end

	local labelOriginTrans = go.transform:Find("labelOrigin")

	if labelOriginTrans then
		self.labelOrigin = labelOriginTrans:GetComponent(typeof(UILabel))
	end
end

function ValueGiftBagItem:initUIComponent()
	if self.isFirstInit then
		self:setIcon()
		self:setTextures()

		self.isFirstInit = false
	end

	self:setText()
	self:setBtn()

	self.groupIcon_uigrid.enabled = true
end

function ValueGiftBagItem:setTextures()
	xyd.setUITextureAsync(self.itemBg, "Textures/activity_web/weekly_monthly_giftbag/weekly_monthly_giftbag_bg01", function ()
	end)
end

function ValueGiftBagItem:setText()
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

	if self.labelOrigin then
		if self.info.data.isDiscount then
			self.labelOrigin:SetActive(true)

			self.labelOrigin.text = "[s]" .. self.info.data.originPrice .. "[/s]"

			self.btnPurchase:Y(0)
			self.labelItemLimit:Y(41)
		else
			self.labelOrigin:SetActive(false)
			self.btnPurchase:Y(-10)
			self.labelItemLimit:Y(31)
		end
	end
end

function ValueGiftBagItem:setIcon()
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

	if #awards >= 5 then
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
			local scale = 0.7129629629629629
			local icaonGroup = self.groupIcon

			if #awardNewArr >= 5 and i >= 4 then
				scale = 0.6388888888888888
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

function ValueGiftBagItem:setBtn()
	self.redMark:SetActive(false)

	if self.info.isFree ~= nil then
		UIEventListener.Get(self.btnPurchase.gameObject).onClick = handler(self, function ()
			local msg = messages_pb:daily_giftbag_free_req()
			msg.activity_id = self.info.activityid

			xyd.Backend.get():request(xyd.mid.DAILY_GIFTBAG_FREE, msg)
		end)
		self.btnPurchase_label.text = __("FREE2")

		if self.info.isFreeCan == 0 then
			self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

			xyd.applyChildrenOrigin(self.btnPurchase.gameObject)
			self.labelItemLimit:SetActive(true)
			self.redMark:SetActive(true)
		else
			self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

			xyd.applyChildrenGrey(self.btnPurchase.gameObject)
			self.labelItemLimit:SetActive(false)
			self.redMark:SetActive(false)
		end
	end

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
						award_id = tonumber(self.info.giftBagID)
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

		if self.info.isCrystalCan == true then
			self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

			xyd.applyChildrenOrigin(self.btnPurchase.gameObject)
			self.labelItemLimit:SetActive(true)
		else
			self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

			xyd.applyChildrenGrey(self.btnPurchase.gameObject)
			self.labelItemLimit:SetActive(false)
		end
	else
		self.prop_buy_con:SetActive(false)
	end

	if self.info.isFree == nil and self.info.isCrystal == nil then
		self.btnPurchase_label.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftBagID))

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

function ValueGiftBagItem:updateFreeBtn()
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

function ValueGiftBagItem:updateCrystalBtn()
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

return ValueGiftBag
