local ActivityContent = import("app.windows.activity.ValueGiftBag")
local ActivityIceSecretGiftBag = class("ActivityIceSecretGiftBag", ActivityContent)
local ActivityIceSecretGiftBagItem = class("ActivityIceSecretGiftBagItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")

function ActivityIceSecretGiftBag:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)
	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_ICE_SECRET_GIFTBAG, false)
end

function ActivityIceSecretGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/value_giftbag_ice"
end

function ActivityIceSecretGiftBag:initWrapContent()
	self.wrapContent = FixedWrapContent.new(self.scroller, self.wrapContentCon, self.common_giftbag_item, ActivityIceSecretGiftBagItem, self)
end

function ActivityIceSecretGiftBag:onRegisterEvent()
	ActivityIceSecretGiftBag.super.onRegisterEvent(self)
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityByID))
end

function ActivityIceSecretGiftBag:onActivityByID(event)
	local id = event.data.act_info.activity_id

	if id ~= self.id then
		return
	end

	local data = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_ICE_SECRET_GIFTBAG)

	data:setData(event.data.act_info)
	self:setItems()
end

function ActivityIceSecretGiftBag:getUIComponent()
	local go = self.go
	self.floatCon = go:NodeByName("floatCon").gameObject
	self.imgBg = go:ComponentByName("imgBg", typeof(UITexture))
	self.imgText01 = go:ComponentByName("imgText01", typeof(UITexture))
	self.imgText02 = go:ComponentByName("imgText02", typeof(UITexture))
	self.e_Image = go:ComponentByName("e:Image", typeof(UISprite))
	self.labelTime = go:ComponentByName("timeGroup/labelTime", typeof(UILabel))
	self.labelText01 = go:ComponentByName("timeGroup/labelText01", typeof(UILabel))
	self.scroller = go:ComponentByName("scroller", typeof(UIScrollView))
	self.scroller_Panel = go:ComponentByName("scroller", typeof(UIPanel))
	self.groupPackage = go:NodeByName("scroller/groupPackage").gameObject
	self.common_giftbag_item = go:NodeByName("common_giftbag_item").gameObject
	self.wrapContentCon = go:ComponentByName("scroller/groupPackage", typeof(UIWrapContent))

	self:initWrapContent()
end

function ActivityIceSecretGiftBag:initUIComponent()
	self.ownNumLabel = self.go:ComponentByName("numGroup/ownNumLabel", typeof(UILabel))
	self.effectCon = self.go:ComponentByName("effectCon", typeof(UITexture))

	if xyd.Global.lang == "fr_fr" then
		self.labelTime.fontSize = 18
		self.labelText01.fontSize = 18
	end

	self:setText()
	self:setItems()
	self:setTextures()
	self:initCountDown()
end

function ActivityIceSecretGiftBag:initEffect()
	self.summonEffect_ = xyd.Spine.new(self.effectCon.gameObject)

	self.summonEffect_:setInfo("luxun_pifu02_lihui01", function ()
		self.summonEffect_:setRenderTarget(self.effectCon, 1)
		self.summonEffect_:play("animation", 0)
	end)
end

function ActivityIceSecretGiftBag:initCountDown()
	if xyd.getServerTime() < self.activityData:getEndTime() then
		local startTime = self.activityData:getStartTime()
		local passedTotalTime = xyd.getServerTime() - startTime
		local cd = xyd.tables.giftBagTable:getCD(self.activityData.detail.charges[1].table_id)
		local round = math.ceil(passedTotalTime / cd)

		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_ICE_SECRET_GIFTBAG, function ()
			xyd.db.misc:setValue({
				key = "activity_ice_secret_giftbag",
				value = round
			})
		end)

		local countdownTime = round * cd - passedTotalTime
		local countdown = CountDown.new(self.labelTime, {
			duration = countdownTime,
			callback = handler(self, self.timeOver)
		})
	else
		self.labelTime:SetActive(false)
		self.labelText01:SetActive(false)
	end

	self.labelTime:SetLocalPosition(205, -235, 0)
	self.labelText01:SetLocalPosition(185, -235, 0)
end

function ActivityIceSecretGiftBag:timeOver()
	self:waitForFrame(10, function ()
		self:initCountDown()
		xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_ICE_SECRET_GIFTBAG)
	end, nil)
end

function ActivityIceSecretGiftBag:setTextures()
	xyd.setUITextureByNameAsync(self.imgText01, "activity_ice_secret_giftbag_logo_text_" .. xyd.Global.lang, false, function ()
		self.imgText01:SetLocalPosition(154, -105, 0)
	end)
	self.imgText02:SetActive(false)
	xyd.setUITextureAsync(self.imgBg, "Textures/activity_web/ice_secret_giftbag/activity_ice_secret_giftbag_banner", function ()
		self.imgBg:SetRect(-348, -337, 696, 337)
	end, false)
end

function ActivityIceSecretGiftBag:setText()
	self.labelText01.text = __("ACTIVITY_ICE_SECRET_AWARDS_CD")
	self.ownNumLabel.text = tostring(xyd.models.backpack:getItemNumByID(xyd.ItemID.ICE_SECRET_BREAK_ITEM_2))

	if self.ownNumLabel.text == "" then
		self.ownNumLabel.text = "0"
	end
end

function ActivityIceSecretGiftBag:getItemInfos()
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

function ActivityIceSecretGiftBag:onRecharge(event)
	ActivityIceSecretGiftBag.super.onRecharge(self, event)

	for i = 1, #event.data.items do
		local item = event.data.items[i]

		if item.item_id == xyd.ItemID.ICE_SECRET_BREAK_ITEM_2 then
			self.ownNumLabel.text = tostring(tonumber(self.ownNumLabel.text) + tonumber(item.item_num))
		end
	end
end

function ActivityIceSecretGiftBagItem:ctor(go, parent)
	self.go = go

	self:getUIComponent()
	self:setDragScrollView(parent:getScrollView())

	self.parent = parent
	self.eventProxy_ = xyd.EventProxy.new(xyd.EventDispatcher.inner(), self)

	self.eventProxy_:addEventListener("updateBt", handler(self, self.updateFreeBtn))
	self.eventProxy_:addEventListener("updateBtCrystal", handler(self, self.updateCrystalBtn))

	self.isFirstInit = true
end

function ActivityIceSecretGiftBagItem:getGiftBagID()
	return self.giftBagID
end

function ActivityIceSecretGiftBagItem:update(index, info)
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

function ActivityIceSecretGiftBagItem:getUIComponent()
	local go = self.go
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.groupIcon2 = go:NodeByName("groupIcon2").gameObject
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
end

function ActivityIceSecretGiftBagItem:initUIComponent()
	if self.isFirstInit then
		self:setIcon()

		self.isFirstInit = false
	end

	self:setText()
	self:setBtn()

	self.groupIcon_uigrid.enabled = true
end

function ActivityIceSecretGiftBagItem:setText()
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

function ActivityIceSecretGiftBagItem:setIcon()
	local giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID)
	local awards = xyd.tables.giftTable:getAwards(giftID)

	if self.info.isFree ~= nil then
		awards = xyd.tables.giftTable:getAwards(self.giftBagID)
	end

	if self.info.isCrystal ~= nil then
		dump(self.info.award, "aaaaaaaaaaasdadasd")

		awards = self.info.award
	end

	NGUITools.DestroyChildren(self.groupIcon.transform)

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
end

function ActivityIceSecretGiftBagItem:setBtn()
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

function ActivityIceSecretGiftBagItem:updateFreeBtn()
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

function ActivityIceSecretGiftBagItem:updateCrystalBtn()
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

return ActivityIceSecretGiftBag
