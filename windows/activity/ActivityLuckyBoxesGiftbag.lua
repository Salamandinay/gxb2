local ActivityLuckyBoxesGiftbag = class("ActivityLuckyBoxesGiftbag", import(".ActivityContent"))
local ActivityLuckyboxesAwardItem = class("ActivityLuckyboxesAwardItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local AdvanceIcon = import("app.components.AdvanceIcon")
local json = require("cjson")

function ActivityLuckyBoxesGiftbag:ctor(parentGO, params)
	ActivityLuckyBoxesGiftbag.super.ctor(self, parentGO, params)
end

function ActivityLuckyBoxesGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/activity_luckyboxes_giftbag"
end

function ActivityLuckyBoxesGiftbag:resizeToParent()
	ActivityLuckyBoxesGiftbag.super.resizeToParent(self)

	local allHeight = self.go:GetComponent(typeof(UIWidget)).height
	local heightDis = allHeight - 874
end

function ActivityLuckyBoxesGiftbag:initUI()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LUCKYBOXES_GIFTBAG)
	self.id = xyd.ActivityID.ACTIVITY_LUCKYBOXES_GIFTBAG
	self.giftBagID = xyd.tables.activityTable:getGiftBag(self.id)[1]
	self.specialGiftbagID = 394
	self.specialIcons = {}

	self:getUIComponent()
	ActivityLuckyBoxesGiftbag.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityLuckyBoxesGiftbag:getUIComponent()
	self.trans = self.go
	self.common_item = self.trans:NodeByName("common_item").gameObject
	self.bg = self.trans:ComponentByName("bg", typeof(UITexture))
	self.imgLogo = self.trans:ComponentByName("imgLogo", typeof(UITexture))
	self.scroller = self.trans:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scroller:NodeByName("groupPackage").gameObject
	self.drag = self.trans:NodeByName("drag").gameObject
	self.special_item = self.trans:NodeByName("special_item").gameObject
	self.itemBg = self.special_item:ComponentByName("itemBg", typeof(UISprite))
	self.itemGroup_special = self.special_item:ComponentByName("itemGroup", typeof(UIGrid))
	self.labelItemText01 = self.special_item:ComponentByName("labelItemText01", typeof(UILabel))
	self.labelItemText02 = self.special_item:ComponentByName("labelItemText02", typeof(UILabel))
	self.labelItemLimit = self.special_item:ComponentByName("labelItemLimit", typeof(UILabel))
	self.btnPurchase = self.special_item:NodeByName("btnPurchase").gameObject
	self.labelPurchasBtn = self.btnPurchase:ComponentByName("label", typeof(UILabel))
	self.iconPurchasBtn = self.btnPurchase:ComponentByName("icon", typeof(UISprite))
	self.labelPurchasBtn2 = self.iconPurchasBtn:ComponentByName("label", typeof(UILabel))
	self.labelSpecialTitle = self.trans:ComponentByName("labelSpecialTitle", typeof(UILabel))
	self.labelTip = self.trans:ComponentByName("tipGroup/tipLabel_", typeof(UILabel))
end

function ActivityLuckyBoxesGiftbag:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data
		local detail = json.decode(data.detail)

		if data.activity_id == xyd.ActivityID.ACTIVITY_LUCKYBOXES_GIFTBAG then
			local awards = xyd.tables.activityLuckyboxesExchangTable:getAwards(detail.award_id)
			local items = {}

			for _, info in ipairs(awards) do
				local item = {
					item_id = info[1],
					item_num = info[2]
				}

				table.insert(items, item)
			end

			xyd.models.itemFloatModel:pushNewItems(items)
			self:initData()
		end
	end)
	self:registerEvent(xyd.event.RECHARGE, function (event)
		self:initData()
		self:updateSpecialGroup()
	end)

	UIEventListener.Get(self.btnPurchase).onClick = handler(self, function ()
		xyd.SdkManager.get():showPayment(self.specialGiftbagID)
	end)
end

function ActivityLuckyBoxesGiftbag:initUIComponent()
	xyd.setUITextureByNameAsync(self.imgLogo, "activity_luckyboxes_giftbag_logo_" .. xyd.Global.lang)

	self.labelSpecialTitle.text = __("ACTIVITY_JACKPOT_GIFTBAG_TEXT01")
	self.labelTip.text = __("SPACE_EXPLORE_SUPPLY_TEXT02")

	self:initData()
	self:initSpecialGroup()
end

function ActivityLuckyBoxesGiftbag:initData()
	self.data = {}
	local charges = self.activityData.detail.charges

	for i = 1, #charges do
		local giftBagID = tonumber(charges[i].table_id)
		local awarded = 0

		if charges[i].limit_times <= charges[i].buy_times then
			awarded = 1
		end

		if giftBagID ~= self.specialGiftbagID then
			table.insert(self.data, {
				giftBagID = giftBagID,
				left_time = charges[i].limit_times - charges[i].buy_times,
				awarded = awarded
			})
		else
			self.specialData = {
				giftBagID = giftBagID,
				left_time = charges[i].limit_times - charges[i].buy_times,
				awarded = awarded
			}
		end
	end

	local ids = xyd.tables.activityLuckyboxesExchangTable:getIDs()
	local freecharges = self.activityData.detail.free_charge

	for i = 1, #ids do
		local awarded = 0

		if xyd.tables.activityLuckyboxesExchangTable:getLimit(i) - self.activityData.detail.exchange_times[i] < 1 then
			awarded = 1
		end

		dump(self.activityData)
		dump(self.activityData.detail)
		dump(self.activityData.detail.exchange_times)
		dump(i)
		table.insert(self.data, {
			isFreeGiftbag = true,
			left_time = xyd.tables.activityLuckyboxesExchangTable:getLimit(i) - self.activityData.detail.exchange_times[i],
			awarded = awarded,
			freeGiftbagID = i
		})
	end

	dump(freecharges)

	local function sort_func(a, b)
		if a.awarded ~= b.awarded then
			return a.awarded < b.awarded
		elseif a.isFreeGiftbag == true then
			return true
		elseif b.isFreeGiftbag == true then
			return false
		else
			return a.giftBagID < b.giftBagID
		end
	end

	table.sort(self.data, sort_func)

	if self.wrapContent == nil then
		local wrapContent = self.scroller:ComponentByName("groupPackage", typeof(UIWrapContent))
		self.wrapContent = FixedWrapContent.new(self.scroller, wrapContent, self.common_item, ActivityLuckyboxesAwardItem, self)
	end

	self.wrapContent:setInfos(self.data, {})
end

function ActivityLuckyBoxesGiftbag:initSpecialGroup()
	self.labelItemText01.text = __("VIP EXP")
	self.labelItemText02.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.specialGiftbagID)
	self.labelPurchasBtn.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.specialGiftbagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.specialGiftbagID))
	self.labelItemLimit.text = __("BUY_GIFTBAG_LIMIT", self.specialData.left_time)
	self.specialGiftID = xyd.tables.giftBagTable:getGiftID(self.specialGiftbagID)
	local awards = xyd.tables.giftTable:getAwards(self.specialGiftID)
	self.count = 1

	for i = 1, #awards do
		local award = awards[i]

		if award[i] ~= 8 and xyd.tables.itemTable:getType(award[i]) ~= 12 then
			local params = {
				notShowGetWayBtn = true,
				show_has_num = false,
				scale = 0.7037037037037037,
				uiRoot = self.itemGroup_special.gameObject,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}

			if self.specialIcons[self.count] == nil then
				self.specialIcons[self.count] = AdvanceIcon.new(params)
			else
				self.specialIcons[self.count]:setInfo(params)
			end

			self.specialIcons[self.count]:SetActive(true)
			self.specialIcons[self.count]:setChoose(self.specialData.left_time <= 0)

			self.count = self.count + 1
		end
	end

	if self.specialData.left_time <= 0 then
		xyd.applyGrey(self.btnPurchase:GetComponent(typeof(UISprite)))
		self.labelPurchasBtn:ApplyGrey()
		xyd.setTouchEnable(self.btnPurchase, false)
	else
		xyd.applyOrigin(self.btnPurchase:GetComponent(typeof(UISprite)))
		self.labelPurchasBtn:ApplyOrigin()
		xyd.setTouchEnable(self.btnPurchase, true)
	end

	self.itemGroup_special:Reposition()
end

function ActivityLuckyBoxesGiftbag:updateSpecialGroup()
	self.labelItemLimit.text = __("BUY_GIFTBAG_LIMIT", self.specialData.left_time)
	local awards = xyd.tables.giftTable:getAwards(self.specialGiftID)

	for i = 1, #awards do
		local award = awards[i]

		if self.specialIcons[i] then
			self.specialIcons[i]:SetActive(true)
			self.specialIcons[i]:setChoose(self.specialData.left_time <= 0)
		end
	end

	if self.specialData.left_time <= 0 then
		xyd.applyGrey(self.btnPurchase:GetComponent(typeof(UISprite)))
		self.labelPurchasBtn:ApplyGrey()
		xyd.setTouchEnable(self.btnPurchase, false)
	else
		xyd.applyOrigin(self.btnPurchase:GetComponent(typeof(UISprite)))
		self.labelPurchasBtn:ApplyOrigin()
		xyd.setTouchEnable(self.btnPurchase, true)
	end

	self.itemGroup_special:Reposition()
end

function ActivityLuckyboxesAwardItem:ctor(go, parent)
	ActivityLuckyboxesAwardItem.super.ctor(self, go, parent)
end

function ActivityLuckyboxesAwardItem:initUI()
	local go = self.go
	self.itemGroup = self.go:ComponentByName("itemGroup", typeof(UIGrid))
	self.labelItemText01 = self.go:ComponentByName("labelItemText01", typeof(UILabel))
	self.labelItemText02 = self.go:ComponentByName("labelItemText02", typeof(UILabel))
	self.labelItemLimit = self.go:ComponentByName("labelItemLimit", typeof(UILabel))
	self.btnPurchase = self.go:NodeByName("btnPurchase").gameObject
	self.labelBtnPurchase1 = self.btnPurchase:ComponentByName("label", typeof(UILabel))
	self.redMark = self.btnPurchase:ComponentByName("redMark", typeof(UISprite))
	self.icon = self.btnPurchase:ComponentByName("icon", typeof(UISprite))
	self.labelBtnPurchase2 = self.icon:ComponentByName("label", typeof(UILabel))
	self.icons = {}
	UIEventListener.Get(self.btnPurchase).onClick = handler(self, function ()
		if self.isFreeGiftbag == true then
			self:buyFreeGiftbag()
		else
			xyd.SdkManager.get():showPayment(self.giftBagID)
		end
	end)
end

function ActivityLuckyboxesAwardItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)

	self.giftBagID = self.data.giftBagID
	self.left_time = self.data.left_time
	self.isFreeGiftbag = self.data.isFreeGiftbag
	self.freeGiftbagID = self.data.freeGiftbagID

	self.labelItemText01:SetActive(self.isFreeGiftbag ~= true)
	self.labelItemText02:SetActive(self.isFreeGiftbag ~= true)
	self.labelBtnPurchase1:SetActive(self.isFreeGiftbag ~= true)
	self.icon:SetActive(self.isFreeGiftbag == true)
	self.labelBtnPurchase2:SetActive(self.isFreeGiftbag == true)

	local awards = nil
	self.labelItemLimit.text = __("BUY_GIFTBAG_LIMIT", self.left_time)

	if self.isFreeGiftbag == true then
		local cost = xyd.tables.activityLuckyboxesExchangTable:getCost(self.freeGiftbagID)

		dump("icon" .. cost[1])
		xyd.setUISpriteAsync(self.icon, nil, "icon_" .. cost[1])

		self.labelBtnPurchase2.text = cost[2]
		awards = xyd.tables.activityLuckyboxesExchangTable:getAwards(self.freeGiftbagID)
	else
		self.labelItemText01.text = __("VIP EXP")
		self.labelItemText02.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftBagID)
		self.labelBtnPurchase1.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftBagID))
		self.giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID)
		awards = xyd.tables.giftTable:getAwards(self.giftID)
	end

	for i = 1, #self.icons do
		self.icons[i]:SetActive(false)
	end

	self.count = 1

	for i = 1, #awards do
		local award = awards[i]

		if award[i] ~= 8 and xyd.tables.itemTable:getType(award[i]) ~= 12 then
			local params = {
				show_has_num = false,
				scale = 0.7037037037037037,
				notShowGetWayBtn = true,
				uiRoot = self.itemGroup.gameObject,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scroller
			}

			if self.icons[self.count] == nil then
				params.preGenarate = true
				self.icons[self.count] = AdvanceIcon.new(params)
			else
				self.icons[self.count]:setInfo(params)
			end

			self.icons[self.count]:SetActive(true)
			self.icons[self.count]:setChoose(self.left_time <= 0)

			self.count = self.count + 1
		end
	end

	if self.left_time <= 0 then
		xyd.applyGrey(self.btnPurchase:GetComponent(typeof(UISprite)))
		xyd.applyGrey(self.icon)
		self.labelBtnPurchase1:ApplyGrey()
		xyd.setTouchEnable(self.btnPurchase, false)
	else
		xyd.applyOrigin(self.btnPurchase:GetComponent(typeof(UISprite)))
		xyd.applyOrigin(self.icon)
		self.labelBtnPurchase1:ApplyOrigin()
		xyd.setTouchEnable(self.btnPurchase, true)
	end

	self.itemGroup:Reposition()
end

function ActivityLuckyboxesAwardItem:buyFreeGiftbag()
	if self.left_time <= 0 then
		return
	end

	local cost = xyd.tables.activityLuckyboxesExchangTable:getCost(self.freeGiftbagID)

	if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

		return
	end

	xyd.alertYesNo(__("CONFIRM_BUY"), function (yes)
		if yes then
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LUCKYBOXES_GIFTBAG, json.encode({
				award_type = 1,
				award_id = self.freeGiftbagID
			}))
		end
	end)
end

return ActivityLuckyBoxesGiftbag
