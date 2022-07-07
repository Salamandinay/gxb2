local BaseWindow = import(".BaseWindow")
local VipWindow = class("VipWindow", BaseWindow)
local VipBenefitContent = class("VipBenefitContent", import("app.components.BaseComponent"))
local RechargeItem = class("RechargeItem", import("app.components.BaseComponent"), true)
local PngNum = require("app.components.PngNum")

function VipWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	params = params or {}
	self.items = {}
	self.benefitContents = {}
	self.currentBenefitVip = 1
	local vipLev = xyd.models.backpack:getVipLev()

	if vipLev ~= 0 then
		self.currentBenefitVip = vipLev
	end

	self.showBenefit = params.show_benefit

	if params.type and params.type == 2 then
		self.showBenefit = true
	end

	self.dadian_id_ = params.dadian_id
	self.giftbag_push_list_ = params.giftbag_push_list

	xyd.models.advertiseComplete:vipWindowOpen()
end

function VipWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function VipWindow:getUIComponent()
	local go = self.window_
	self.closeBtn = go:NodeByName("main/closeBtn").gameObject
	self.vipGroup = go:NodeByName("main/vipGroup").gameObject
	self.imgTitle = go:ComponentByName("main/imgTitle", typeof(UISprite))
	self.labelText01 = go:ComponentByName("main/titleGroup/labelText01", typeof(UILabel))
	self.labelText02 = go:ComponentByName("main/titleGroup/labelText02", typeof(UILabel))
	self.labelText03 = go:ComponentByName("main/titleGroup/labelText03", typeof(UILabel))
	self.imgCrystal = go:ComponentByName("main/titleGroup/imgCrystal", typeof(UISprite))
	self.vipGroup1 = go:NodeByName("main/titleGroup/vipGroup1").gameObject
	self.benefitBtn = go:ComponentByName("main/benefitBtn", typeof(UISprite))
	self.benefitBtn_redIcon = go:ComponentByName("main/benefitBtn/redIcon", typeof(UISprite))
	self.purchaseBtn = go:ComponentByName("main/purchaseBtn", typeof(UISprite))
	self.benefitBtn_label = go:ComponentByName("main/benefitBtn/button_label", typeof(UILabel))
	self.purchaseBtn_label = go:ComponentByName("main/purchaseBtn/button_label", typeof(UILabel))
	self.scrollPurchase = go:ComponentByName("main/scrollPurchase", typeof(UIScrollView))
	self.itemsGroup = go:NodeByName("main/scrollPurchase/itemsGroup").gameObject
	self.groupBenefit = go:NodeByName("main/groupBenefit").gameObject
	self.groupBenefitContent = go:ComponentByName("main/groupBenefit/groupBenefitContent", typeof(UIPanel))
	self.groupPosition = go:NodeByName("main/groupBenefit/groupBenefitContent/groupPosition").gameObject
	self.leftArrow = go:NodeByName("main/groupBenefit/Panel1/leftArrow").gameObject
	self.rightArrow = go:NodeByName("main/groupBenefit/Panel1/rightArrow").gameObject
	self.progressVip = go:ComponentByName("main/progressVip", typeof(UIProgressBar))
	self.progressVip_label = go:ComponentByName("main/progressVip/label", typeof(UILabel))
	local vipNum1 = go:NodeByName("main/titleGroup/vipGroup1/vipNum1").gameObject
	local vipNum0 = go:NodeByName("main/vipGroup0/vipNum0").gameObject
	self.itemFloatRoot_ = go:NodeByName("main/itemFloat").gameObject
	self.vipNum0 = PngNum.new(vipNum0)
	self.vipNum1 = PngNum.new(vipNum1)
	self.spinePanel = go:NodeByName("spinePanel").gameObject
	self.spineTex = self.spinePanel:NodeByName("spineTex").gameObject
end

function VipWindow:initUIComponent()
	self:setText()
	self:setVIPValue()
	xyd.models.activity:reqActivityByID(xyd.ActivityID.RECHARGE)
	self.purchaseBtn:SetActive(false)
	self.groupBenefit:SetActive(false)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.VIP_AWARD
	}, self.benefitBtn_redIcon)

	if self.showBenefit then
		self:setBenefitPanel()
	end
end

function VipWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, self.onRechargeInfo, self)
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, self.onRecharge, self)
	self.eventProxy_:addEventListener(xyd.event.BUY_VIP_AWARD, self.onBuyVipAward, self)
	self.eventProxy_:addEventListener(xyd.event.GET_VIP_AWARD, self.onGetVipAward, self)
	xyd.setDarkenBtnBehavior(self.benefitBtn.gameObject, self, self.setBenefitPanel)
	xyd.setDarkenBtnBehavior(self.leftArrow, self, function ()
		self.currentBenefitVip = self.currentBenefitVip - 1

		self:setBenefitItem(-1)
	end)
	xyd.setDarkenBtnBehavior(self.rightArrow, self, function ()
		self.currentBenefitVip = self.currentBenefitVip + 1

		self:setBenefitItem(1)
	end)
	xyd.setDarkenBtnBehavior(self.purchaseBtn.gameObject, self, function ()
		self.purchaseBtn:SetActive(false)
		self.benefitBtn:SetActive(true)
		self.groupBenefit:SetActive(false)
		self.scrollPurchase:SetActive(true)
		xyd.setUISpriteAsync(self.imgTitle, nil, "vip_text02_" .. tostring(xyd.Global.lang), function ()
			self.imgTitle:MakePixelPerfect()
		end)
	end)
	self:setCloseBtn(self.closeBtn)
end

function VipWindow:setBenefitLayout()
	if self.isBenefitInit then
		return
	end

	self.isBenefitInit = true

	self:setBenefitItem(0)

	for i = 0, xyd.models.backpack:getMaxVipLev() do
		self:waitForFrame(i * 2, function ()
			self:setContent(i)
		end, nil)
	end
end

function VipWindow:onRechargeInfo(event)
	local data = event.data.act_info

	if data.activity_id ~= xyd.ActivityID.RECHARGE then
		return
	end

	self:setPurchaseItem()
end

function VipWindow:onRecharge(event)
	local id = event.data.giftbag_id

	for i = 1, #self.items do
		local item = self.items[i]

		if item.ID == id then
			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.RECHARGE)
			local data = activityData:getGiftBagData(id)

			item:setData(data)
		end
	end

	self:waitForTime(1, handler(self, self.setVIPValue), nil)
	self:showEffect(event)
	self:setPurchaseItem()
end

function VipWindow:onBuyVipAward(event)
	local data_ = event.data
	local id = data_.id

	if id > 0 then
		local items = {}
		local awards = xyd.tables.vipTable:split2Cost(id, "vip_giftbox", "|#")

		for i = 1, #awards do
			local data = awards[i]
			local item = {
				hideText = true,
				item_id = data[1],
				item_num = data[2]
			}

			table.insert(items, item)
		end

		xyd.itemFloat(items, nil, self.itemFloatRoot_)
	end
end

function VipWindow:onGetVipAward(event)
	local data_ = event.data
	local id = data_.id

	if id > 0 then
		local items = {}
		local awards = xyd.tables.vipTable:split2Cost(id, "vip_awards", "|#")

		for i = 1, #awards do
			local data = awards[i]
			local item = {
				hideText = true,
				item_id = data[1],
				item_num = data[2]
			}

			table.insert(items, item)
		end

		xyd.itemFloat(items, nil, self.itemFloatRoot_)
	end
end

function VipWindow:showEffect(event)
	local flag = false
	local giftBagID = event.data.giftBagID

	for i = 1, #event.data.items do
		local item = event.data.items[i]

		if item.item_id ~= xyd.ItemID.VIP_EXP then
			flag = true

			break
		end
	end

	self.spinePanel:SetActive(true)

	local effect = xyd.Spine.new(self.spineTex)

	effect:setInfo("fx_ui_zuanshihq", function ()
		effect:play("texiao01", 1, 1, function ()
			self.spinePanel:SetActive(false)
			effect:destroy()

			if flag then
				xyd.showRechargeAward(event.data.giftbag_id, event.data.items)
			end
		end)
	end)
end

function VipWindow:setText()
	self.labelText01.text = __("VIP_TEXT01")
	self.labelText03.text = __("VIP_TEXT02")

	if xyd.Global.lang == "fr_fr" then
		self.labelText03.width = 88

		self.vipGroup1:SetLocalPosition(40, 0, 0)
	elseif xyd.Global.lang == "de_de" then
		self.vipGroup:X(50)
	end

	local img = (self.showBenefit and "vip_text03_" or "vip_text02_") .. xyd.Global.lang

	xyd.setUISpriteAsync(self.imgTitle, nil, img, function ()
		self.imgTitle:MakePixelPerfect()
	end)

	self.purchaseBtn_label.text = __("VIP_TEXT03")
	self.benefitBtn_label.text = __("VIP_TEXT04")
end

function VipWindow:setVIPValue()
	local vip = xyd.models.backpack:getVipLev()

	if xyd.models.backpack:getMaxVipLev() <= vip then
		self.labelText01:SetActive(false)
		self.labelText02:SetActive(false)
		self.labelText03:SetActive(false)
		self.imgCrystal:SetActive(false)
		self.vipGroup1:SetActive(false)

		self.progressVip.value = 1
		self.progressVip_label.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.VIP_EXP) .. "/" .. xyd.models.backpack:getMaxVipExp()

		self.vipNum0:setInfo({
			iconName = "player_vip",
			num = xyd.models.backpack:getMaxVipLev()
		})

		return
	end

	self.labelText02.text = tostring(xyd.models.backpack:getNextLevNeedVipExp())

	if xyd.Global.lang == "fr_fr" then
		self.window_:NodeByName("main/vipGroup"):X(self.labelText02.width - 10)
	end

	self.vipNum0:setInfo({
		iconName = "player_vip",
		num = vip
	})
	self.vipNum1:setInfo({
		iconName = "player_vip",
		num = vip + 1
	})

	self.progressVip.value = xyd.models.backpack:getItemNumByID(xyd.ItemID.VIP_EXP) / xyd.tables.vipTable:needExp(vip + 1)
	self.progressVip_label.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.VIP_EXP) .. "/" .. xyd.tables.vipTable:needExp(vip + 1)
end

function VipWindow:setPurchaseItem()
	NGUITools.DestroyChildren(self.itemsGroup.transform)

	self.items = {}
	local ids = xyd.tables.giftBagTable:getIDs()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.RECHARGE)
	local tail = {}
	local sortList = {}

	for i = 1, #ids do
		local id = ids[i]
		local rank = xyd.tables.giftBagTable:getRank(id)
		local data = activityData:getGiftBagData(id)
		local isNotSubscrition = xyd.tables.giftBagTable:getGiftType(id) ~= xyd.GIFTBAG_TYPE.SUBSCRIPTION
		local isNeedReview = xyd.tables.giftBagTable:isNeedReview(id) and xyd.Global.isReview == 0

		if rank and data and isNotSubscrition and not isNeedReview then
			local params = {
				id = id,
				buyTimes = data.buy_times,
				days = data.days or 0,
				endTime = data.end_time,
				dadian_id = self.dadian_id_,
				scrollView = self.scrollPurchase
			}
			local isDayilyGift = xyd.tables.giftBagTable:getGiftType(id) == xyd.GIFTBAG_TYPE.CARD

			if isDayilyGift and xyd.getServerTime() <= (data.end_time or 0) then
				table.insert(tail, params)
			else
				table.insert(sortList, params)
			end
		end
	end

	table.sort(sortList, function (a, b)
		return xyd.tables.giftBagTable:getRank(a.id) < xyd.tables.giftBagTable:getRank(b.id)
	end)
	table.sort(tail, function (a, b)
		return xyd.tables.giftBagTable:getRank(a.id) < xyd.tables.giftBagTable:getRank(b.id)
	end)
	self:checkMonthCardDiscount(sortList, tail)

	for i = 1, #sortList do
		local item = RechargeItem.new(self.itemsGroup, sortList[i])

		table.insert(self.items, sortList[i])
	end

	for i = 1, #tail do
		local item = RechargeItem.new(self.itemsGroup, tail[i])

		table.insert(self.items, tail[i])
	end

	local layout = self.itemsGroup:GetComponent(typeof(UILayout))
	layout.enabled = true

	layout:Reposition()
end

function VipWindow:checkMonthCardDiscount(sortList, tail)
	local monthcard_discount = false
	local monthcard_discount_over = false
	local minicard_discount = false
	local minicard_discount_over = false
	local return_discount = false
	local return_descount_over = false
	local monthcard_limit_discount = false
	local monthcard_limit_discount_over = false
	local minicard_limit_discount = false
	local minicard_limit_discount_over = false

	for index, data in ipairs(sortList) do
		if tonumber(data.id) == 282 then
			local limit = xyd.tables.giftBagTable:getBuyLimit(tonumber(data.id))

			if limit <= tonumber(data.buyTimes) then
				monthcard_discount_over = true
			end

			monthcard_discount = true
		elseif data.id == 283 then
			local limit = xyd.tables.giftBagTable:getBuyLimit(tonumber(data.id))

			if limit <= tonumber(data.buyTimes) then
				minicard_discount_over = true
			end

			minicard_discount = true
		elseif data.id == 302 then
			local limit = xyd.tables.giftBagTable:getBuyLimit(tonumber(data.id))

			if limit <= tonumber(data.buyTimes) then
				return_descount_over = true
			end

			return_discount = true
		elseif data.id == 360 then
			local limit = xyd.tables.giftBagTable:getBuyLimit(tonumber(data.id))

			if limit <= tonumber(data.buyTimes) then
				monthcard_limit_discount_over = true
			end

			monthcard_limit_discount = true
		elseif data.id == 361 then
			local limit = xyd.tables.giftBagTable:getBuyLimit(tonumber(data.id))

			if limit <= tonumber(data.buyTimes) then
				minicard_limit_discount_over = true
			end

			minicard_limit_discount = true
		end
	end

	for index, data in ipairs(tail) do
		if tonumber(data.id) == 282 then
			local limit = xyd.tables.giftBagTable:getBuyLimit(tonumber(data.id))

			if limit <= tonumber(data.buyTimes) then
				monthcard_discount_over = true
			end

			monthcard_discount = true
		elseif data.id == 283 then
			local limit = xyd.tables.giftBagTable:getBuyLimit(tonumber(data.id))

			if limit <= tonumber(data.buyTimes) then
				minicard_discount_over = true
			end

			minicard_discount = true
		elseif data.id == 302 then
			local limit = xyd.tables.giftBagTable:getBuyLimit(tonumber(data.id))

			if limit <= tonumber(data.buyTimes) then
				return_descount_over = true
			end

			return_discount = true
		elseif data.id == 360 then
			local limit = xyd.tables.giftBagTable:getBuyLimit(tonumber(data.id))

			if limit <= tonumber(data.buyTimes) then
				monthcard_limit_discount_over = true
			end

			monthcard_limit_discount = true
		elseif data.id == 361 then
			local limit = xyd.tables.giftBagTable:getBuyLimit(tonumber(data.id))

			if limit <= tonumber(data.buyTimes) then
				minicard_limit_discount_over = true
			end

			minicard_limit_discount = true
		end
	end

	for index = #sortList, 1, -1 do
		local data = sortList[index]

		if tonumber(data.id) == 1 then
			if not return_descount_over and return_discount or not monthcard_discount_over and monthcard_discount or not monthcard_limit_discount_over and monthcard_limit_discount then
				table.remove(sortList, index)
			end
		elseif data.id == 2 then
			if not minicard_discount_over and minicard_discount or not minicard_limit_discount_over and minicard_limit_discount then
				table.remove(sortList, index)
			end
		elseif tonumber(data.id) == 282 then
			if not return_descount_over and return_discount or monthcard_discount_over then
				table.remove(sortList, index)
			end
		elseif data.id == 283 then
			if minicard_discount_over then
				table.remove(sortList, index)
			end
		elseif data.id == 302 then
			if return_descount_over then
				table.remove(sortList, index)
			end
		elseif data.id == 360 then
			if not return_descount_over and return_discount or not monthcard_discount_over and monthcard_discount or monthcard_limit_discount_over then
				table.remove(sortList, index)
			end
		elseif data.id == 361 and (not minicard_discount_over and minicard_discount or minicard_limit_discount_over) then
			table.remove(sortList, index)
		end
	end

	for index = #tail, 1, -1 do
		local data = tail[index]

		if tonumber(data.id) == 1 then
			if not return_descount_over and return_discount or not monthcard_discount_over and monthcard_discount or not monthcard_limit_discount_over and monthcard_limit_discount then
				table.remove(sortList, index)
			end
		elseif data.id == 2 then
			if not minicard_discount_over and minicard_discount or not minicard_limit_discount_over and minicard_limit_discount then
				table.remove(sortList, index)
			end
		elseif tonumber(data.id) == 282 then
			if not return_descount_over and return_discount or monthcard_discount_over then
				table.remove(sortList, index)
			end
		elseif data.id == 283 then
			if minicard_discount_over then
				table.remove(sortList, index)
			end
		elseif data.id == 302 then
			if return_descount_over then
				table.remove(sortList, index)
			end
		elseif data.id == 360 then
			if not return_descount_over and return_discount or not monthcard_discount_over and monthcard_discount or monthcard_limit_discount_over then
				table.remove(sortList, index)
			end
		elseif data.id == 361 and (not minicard_discount_over and minicard_discount or minicard_limit_discount_over) then
			table.remove(sortList, index)
		end
	end
end

function VipWindow:setBenefitItem(delta)
	self.leftArrow:SetActive(self.currentBenefitVip > 1)
	self.rightArrow:SetActive(self.currentBenefitVip < xyd.models.backpack:getMaxVipLev())
	self:setContent(self.currentBenefitVip)

	if self.sequence then
		self.sequence:Kill(false)

		self.sequence = nil
	end

	if delta ~= 0 then
		local sequence = DG.Tweening.DOTween.Sequence()
		local x = (self.currentBenefitVip - 1) * self.groupBenefitContent.width

		sequence:Append(self.groupPosition.transform:DOLocalMoveX(-x, 0.6))
		sequence:AppendCallback(function ()
			sequence:Kill(false)

			self.sequence = nil

			NGUITools.Destroy(self.benefitContents[self.currentBenefitVip - delta]:getGameObject())

			self.benefitContents[self.currentBenefitVip - delta] = nil
			self.action = nil
		end)

		self.sequence = sequence

		return
	end

	if delta == 0 then
		self.groupPosition:X(-(self.currentBenefitVip - 1) * self.groupBenefitContent.width)
	end
end

function VipWindow:setContent(vip)
	if vip <= 0 or xyd.models.backpack:getMaxVipLev() < vip then
		return
	end

	if self.benefitContents[vip] then
		return
	end

	local vipContent = VipBenefitContent.new(self.groupPosition, vip, self.groupBenefitContent.depth)
	self.benefitContents[vip] = vipContent

	vipContent:getGameObject():X(self.groupBenefitContent.width * (vip - 1))
end

function VipWindow:setBenefitPanel()
	self.purchaseBtn:SetActive(true)
	self.benefitBtn:SetActive(false)
	self.groupBenefit:SetActive(true)
	self.scrollPurchase:SetActive(false)
	xyd.setUISpriteAsync(self.imgTitle, nil, "vip_text03_" .. tostring(xyd.Global.lang))

	if not self.isBenefitInit then
		self:setBenefitLayout()
	end
end

function VipWindow:onScrollBegin(event)
	self.scrollX = event.localX
end

function VipWindow:onScrollEnd(event)
	if self.action then
		return
	end

	if event.localX - self.scrollX < -20 then
		if xyd.models.backpack:getMaxVipLev() <= self.currentBenefitVip then
			return
		end

		self.currentBenefitVip = self.currentBenefitVip + 1

		self:setBenefitItem(1)
	elseif event.localX - self.scrollX > 20 then
		if self.currentBenefitVip <= 1 then
			return
		end

		self.currentBenefitVip = self.currentBenefitVip - 1

		self:setBenefitItem(-1)
	end
end

function VipWindow:willClose(params, skipAnimation, force)
	self.groupPosition:SetActive(false)
	BaseWindow.willClose(self, params, skipAnimation, force)
end

function VipWindow:excuteCallBack()
	if self.giftbag_push_list_ then
		xyd.WindowManager.get():openWindow("month_card_push_window", {
			not_log = true,
			list = self.giftbag_push_list_
		})
	end
end

function RechargeItem:ctor(parentGO, params)
	self.id = params.id
	self.buyTimes = params.buyTimes
	self.days = params.days
	self.endTime = params.endTime
	self.dadian_id_ = params.dadian_id
	self.scrollView = params.scrollView

	RechargeItem.super.ctor(self, parentGO)
	self:getUIComponent()
	self:initUIComponent()
end

function RechargeItem:getPrefabPath()
	if xyd.tables.giftBagTable:getGiftType(self.id) ~= xyd.GIFTBAG_TYPE.CARD and xyd.tables.giftBagTable:getGiftType(self.id) ~= xyd.GIFTBAG_TYPE.LIMIT_TIME_CARD and xyd.tables.giftBagTable:getGiftType(self.id) ~= xyd.GIFTBAG_TYPE.LIMIT_TIME_MINICARD then
		return "Prefabs/Windows/vip_recharge_item_crystal"
	else
		return "Prefabs/Windows/vip_recharge_item_month_card"
	end
end

function RechargeItem:getUIComponent()
	local go = self.go
	self.groupContainer = go:NodeByName("groupContainer").gameObject
	self.imgIcon = self.groupContainer:ComponentByName("imgIcon", typeof(UISprite))
	self.groupNum = self.groupContainer:NodeByName("groupNum").gameObject
	self.labelBaseNum = self.groupNum:ComponentByName("labelBaseNum", typeof(UILabel))
	self.imgCrystal = self.groupNum:ComponentByName("imgCrystal", typeof(UISprite))
	self.labelPrice = self.groupContainer:ComponentByName("labelPrice", typeof(UILabel))
	self.labelExp = self.groupContainer:ComponentByName("labelExp", typeof(UILabel))

	if xyd.tables.giftBagTable:getGiftType(self.id) ~= xyd.GIFTBAG_TYPE.CARD and xyd.tables.giftBagTable:getGiftType(self.id) ~= xyd.GIFTBAG_TYPE.LIMIT_TIME_CARD and xyd.tables.giftBagTable:getGiftType(self.id) ~= xyd.GIFTBAG_TYPE.LIMIT_TIME_MINICARD then
		self.groupBonusNum = self.groupContainer:NodeByName("groupBonusNum").gameObject
		self.labelText03 = self.groupBonusNum:ComponentByName("labelText03", typeof(UILabel))
		self.labelExtraNum = self.groupBonusNum:ComponentByName("labelExtraNum", typeof(UILabel))
		self.imgCrystal0 = self.groupBonusNum:ComponentByName("imgCrystal0", typeof(UISprite))
		self.imgDoubleBonus = self.groupContainer:ComponentByName("imgDoubleBonus", typeof(UISprite))

		self:setCrystal()
	else
		self.detailBtn = self.groupContainer:NodeByName("detailBtn").gameObject
		self.labelText01 = self.groupContainer:ComponentByName("labelText01", typeof(UILabel))
		self.labelCardName = self.groupContainer:ComponentByName("e:Group/labelCardName", typeof(UILabel))
		self.groupLeft = self.groupContainer:NodeByName("e:Group/groupLeft").gameObject
		self.labelText02 = self.groupContainer:ComponentByName("e:Group/groupLeft/labelText02", typeof(UILabel))
		self.labelLeftDays = self.groupContainer:ComponentByName("e:Group/groupLeft/labelLeftDays", typeof(UILabel))
		self.discountPart = self.groupContainer:NodeByName("discountPart").gameObject
		self.discountLabel = self.groupContainer:ComponentByName("discountPart/label", typeof(UILabel))
		self.discountPart2 = self.groupContainer:NodeByName("discountPart2").gameObject
		self.labelDiscount = self.discountPart2:ComponentByName("labelDiscount", typeof(UILabel))
		self.labelOff = self.discountPart2:ComponentByName("labelOff", typeof(UILabel))
		self.originPrice = self.groupContainer:ComponentByName("labelBefore", typeof(UILabel))

		self:setMonthCard()
	end

	xyd.setUISprite(self.imgIcon, nil, xyd.tables.giftBagTable:getIcon(self.id))
end

function RechargeItem:initUIComponent()
	xyd.setDarkenBtnBehavior(self.go, self, self.requreGiftBag)
	self:setDragScrollView(self.scrollView)
end

function RechargeItem:setCrystal()
	local firstCharge = xyd.tables.giftBagTable:getFirstChargeDiamond(self.id)

	if self.buyTimes > 0 or #firstCharge == 0 then
		self.imgDoubleBonus:SetActive(false)
	elseif xyd.models.activity:isOpen(xyd.ActivityID.TRIPLE_FIRST_CHARGE) then
		xyd.setUISprite(self.imgDoubleBonus, nil, "vip_text01_3_" .. tostring(xyd.Global.lang))
	else
		xyd.setUISprite(self.imgDoubleBonus, nil, "vip_text01_" .. tostring(xyd.Global.lang))
	end

	self.labelPrice.text = xyd.tables.giftBagTextTable:getCurrency(self.id) .. xyd.tables.giftBagTextTable:getCharge(self.id)
	self.labelBaseNum.text = tostring(xyd.tables.giftBagTable:getDiamond(self.id))
	self.labelExp.text = "VIP EXP +" .. tostring(xyd.tables.giftBagTable:getVipExp(self.id))

	if xyd.tables.giftBagTable:getExtraDiamond(self.id) ~= 0 then
		self.labelExtraNum.text = tostring(xyd.tables.giftBagTable:getExtraDiamond(self.id))
		self.labelText03.text = __("VIP_TEXT05")
	else
		self.groupBonusNum:SetActive(false)
		self.labelText03:SetActive(false)
		self.labelExtraNum:SetActive(false)
		self.imgCrystal0:SetActive(false)
		self.groupNum:X(40)
	end

	self.groupBonusNum:GetComponent(typeof(UILayout)):Reposition()
end

function RechargeItem:setMonthCard()
	local priceId = self.id

	if self.id == xyd.GIFTBAG_ID.MONTH_CARD then
		local activityID = xyd.tables.giftBagTable:getActivityID(self.id)

		if xyd.models.activity:getActivity(activityID) then
			local tempId = xyd.models.activity:getActivity(activityID):getCheckData().activity_id
			priceId = xyd.tables.activityTable:getGiftBag(tempId)[1]
			priceId = priceId or self.id
		end
	end

	local dragScrollView = self.detailBtn:GetComponent(typeof(UIDragScrollView))
	dragScrollView = dragScrollView or self.detailBtn:AddComponent(typeof(UIDragScrollView))
	dragScrollView.scrollView = self.scrollView

	if self.endTime and xyd.getServerTime() < self.endTime then
		self.days = math.floor((self.endTime - xyd:getServerTime() + xyd:getServerTime() % 86400) / 86400)
	end

	self.groupLeft:SetActive(self.days >= 1)

	local dayilyGift = xyd.tables.giftBagTable:getDailyDiamond(self.id)
	local days = xyd.tables.giftBagTable:getDays(self.id)
	self.labelBaseNum.text = tostring(dayilyGift[2] * days + xyd.tables.giftBagTable:getDiamond(self.id))

	if xyd.tables.giftBagTable:getDiamond(self.id) == 0 then
		self.labelText01:SetActive(false)
		self.groupNum:SetActive(false)
	end

	self.labelExp.text = "VIP EXP +" .. tostring(xyd.tables.giftBagTable:getVipExp(self.id))
	self.labelPrice.text = xyd.tables.giftBagTextTable:getCurrency(priceId) .. xyd.tables.giftBagTextTable:getCharge(priceId)
	self.labelLeftDays.text = __("DAY", self.days)
	self.labelText01.text = __("VIP_TEXT06")
	local content = xyd.tables.giftBagTextTable:getName(priceId)
	self.labelCardName.text = content
	self.labelText02.text = __("RETAIN")

	xyd.setDarkenBtnBehavior(self.detailBtn, self, function ()
		if self.id == 282 or self.id == 1 or self.id == 302 or self.id == 360 then
			xyd.WindowManager.get():openWindow("help_window", {
				key = "MONTH_CARD_HELP1"
			})
		else
			xyd.WindowManager.get():openWindow("help_window", {
				key = "MONTH_CARD_HELP2"
			})
		end
	end)

	if self.id == 282 or self.id == 302 or self.id == 360 then
		if self.id == 282 then
			self.discountPart:SetActive(true)

			self.discountLabel.text = __("MONTHLY_CARD_OFFER_FIRST")
		else
			self.discountPart2:SetActive(true)

			self.labelDiscount.text = self.id == 302 and "66%" or "33%"
			self.labelOff.text = "OFF"
		end

		self.originPrice.gameObject:SetActive(true)

		self.originPrice.text = tostring(xyd.tables.giftBagTextTable:getCurrency(1)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(1))

		if xyd.Global.lang == "en_en" then
			self.originPrice.transform:X(60)

			self.discountLabel.fontSize = 16

			self.discountLabel.transform:Y(3)
			self.detailBtn.transform:X(-80)
		elseif xyd.Global.lang == "fr_fr" then
			self.originPrice.transform:X(70)
			self.labelPrice.transform:X(-10)

			self.discountLabel.fontSize = 15

			self.detailBtn.transform:X(-80)
		elseif xyd.Global.lang == "de_de" then
			self.originPrice.transform:X(70)
			self.labelPrice.transform:X(-10)

			self.discountLabel.fontSize = 16

			self.detailBtn.transform:X(-95)
			self.groupNum.transform:X(18)
			self.labelText01.transform:X(20)
		elseif xyd.Global.lang == "ko_kr" then
			self.originPrice.transform:X(65)
			self.labelPrice.transform:X(-30)
			self.groupNum.transform:X(-17)
			self.labelText01.transform:X(-15)
		elseif xyd.Global.lang == "ja_jp" then
			self.originPrice.transform:X(70)

			self.discountLabel.width = 60
		elseif xyd.Global.lang == "zh_tw" then
			self.discountLabel.width = 60
		end
	elseif self.id == 283 or self.id == 361 then
		if self.id == 283 then
			self.discountPart:SetActive(true)

			self.discountLabel.text = __("MONTHLY_CARD_OFFER_FIRST")
		else
			self.discountPart2:SetActive(true)

			self.labelDiscount.text = "60%"
			self.labelOff.text = "OFF"
		end

		self.originPrice.gameObject:SetActive(true)

		self.originPrice.text = tostring(xyd.tables.giftBagTextTable:getCurrency(2)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(2))

		self.originPrice.transform:X(70)

		if xyd.Global.lang == "en_en" then
			self.originPrice.transform:X(60)

			self.discountLabel.fontSize = 16

			self.discountLabel.transform:Y(3)
			self.groupNum.transform:X(-2)
			self.labelText01.transform:X(0)
		elseif xyd.Global.lang == "fr_fr" then
			self.originPrice.transform:X(60)
			self.labelPrice.transform:X(-10)

			self.discountLabel.fontSize = 15

			self.groupNum.transform:X(-2)
			self.labelText01.transform:X(0)
		elseif xyd.Global.lang == "de_de" then
			self.originPrice.transform:X(60)
			self.labelPrice.transform:X(-10)

			self.discountLabel.fontSize = 16

			self.detailBtn.transform:X(-100)
			self.groupNum.transform:X(13)
			self.labelText01.transform:X(15)
		elseif xyd.Global.lang == "ko_kr" then
			self.originPrice.transform:X(65)
			self.labelPrice.transform:X(-30)
			self.groupNum.transform:X(-17)
			self.labelText01.transform:X(-15)
		elseif xyd.Global.lang == "ja_jp" then
			self.originPrice.transform:X(55)

			self.discountLabel.width = 60
		elseif xyd.Global.lang == "zh_tw" then
			self.discountLabel.width = 60
		end
	else
		self.originPrice.gameObject:SetActive(false)
		self.discountPart:SetActive(false)
		self.discountPart2:SetActive(false)
		self.labelPrice.transform:X(0)
	end

	if xyd.Global.lang == "en_en" then
		self.detailBtn.transform:X(-80)
	elseif xyd.Global.lang == "fr_fr" then
		self.labelCardName.overflowMethod = UILabel.Overflow.ShrinkContent
		self.labelCardName.width = 120
		self.labelCardName.height = 48

		self.detailBtn.transform:X(-80)
	elseif xyd.Global.lang == "de_de" then
		self.detailBtn.transform:X(-95)
	end
end

function RechargeItem:requreGiftBag(event)
	local checkId = self.id

	if self.id == xyd.GIFTBAG_ID.MONTH_CARD then
		local activityID = xyd.tables.giftBagTable:getActivityID(self.id)

		if xyd.models.activity:getActivity(activityID) then
			local tempId = xyd.models.activity:getActivity(activityID):getCheckData().activity_id
			checkId = xyd.tables.activityTable:getGiftBag(tempId)[1]
			checkId = checkId or self.id
		end
	end

	if self.dadian_id_ then
		local msg = messages_pb.log_partner_data_touch_req()
		msg.touch_id = self.dadian_id_
		msg.desc = tostring(checkId)

		xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
	end

	xyd.SdkManager.get():showPayment(checkId)
end

function RechargeItem:setData(data)
	self.days = data.days
	self.buyTimes = data.buy_times
	self.endTime = data.end_time

	self:getUIComponent()
end

function RechargeItem.____getters:ID()
	return self.id
end

function RechargeItem.____getters:Days()
	return self.days
end

local VipBenefitItem = class("VipBenefitItem", import("app.components.BaseComponent"))

function VipBenefitItem:ctor(parentGO, params)
	VipBenefitItem.super.ctor(self, parentGO)

	self.text = params.text
	self.suffix = params.suffix
	self.awards = params.awards or {}
	self.state = params.state or ""
	self.isCanPick = params.isCanPick
	self.price = params.price
	self.id = params.id

	self:getUIComponent()
	self:initUIComponent()
end

function VipBenefitItem:getPrefabPath()
	return "Prefabs/Windows/vip_benefit_item"
end

function VipBenefitItem:getUIComponent()
	local go = self.go
	self.imgIcon = go:ComponentByName("imgIcon", typeof(UISprite))
	self.labelText01 = go:ComponentByName("imgIcon/labelText01", typeof(UILabel))
	self.labelText02 = go:ComponentByName("imgIcon/labelText02", typeof(UILabel))
	self.groupAwards = go:NodeByName("groupAwards").gameObject
	self.pickBtn = go:NodeByName("pickBtn").gameObject
	self.pickBtn_boxCollider = go:ComponentByName("pickBtn", typeof(UnityEngine.BoxCollider))
	self.pickBtn_label = go:ComponentByName("pickBtn/button_label", typeof(UILabel))
	self.rect = go:NodeByName("rect").gameObject
end

function VipBenefitItem:initUIComponent()
	if self.state == "text" then
		NGUITools.Destroy(self.groupAwards)
		NGUITools.Destroy(self.pickBtn.gameObject)
		NGUITools.Destroy(self.rect)

		self.go:GetComponent(typeof(UIWidget)).height = 21
	elseif self.state == "award" then
		self.pickBtn:SetActive(false)
		NGUITools.Destroy(self.rect)

		self.go:GetComponent(typeof(UIWidget)).height = 102
	elseif self.state == "pick_awards" then
		xyd.setUISprite(self.imgIcon, nil, "vip_icon11")

		self.labelText01.color = Color.New2(3113938)

		if self.price then
			self.pickBtn:ComponentByName("Sprite", typeof(UISprite)):SetActive(true)

			self.pickBtn_label.text = self.price[2]
			self.pickBtn_label.fontSize = 20

			self.pickBtn_label:X(15)
		else
			self.pickBtn:ComponentByName("Sprite", typeof(UISprite)):SetActive(false)

			self.pickBtn_label.text = __("GET2")
			self.pickBtn_label.fontSize = 24

			self.pickBtn_label:X(0)
		end

		self:setPickBtnEnabled(self.isCanPick)
		xyd.setTouchEnable(self.pickBtn.gameObject, self.isCanPick)
		xyd.setDarkenBtnBehavior(self.pickBtn.gameObject, self, self.onClickpickBtn)

		self.go:GetComponent(typeof(UIWidget)).height = 122
	end

	self.labelText01.text = self.text

	if self.state == "text" then
		local textHeight = self.labelText01.height
		local goHeight = self.go:GetComponent(typeof(UIWidget)).height

		if goHeight < textHeight then
			self.go:GetComponent(typeof(UIWidget)).height = textHeight
		end
	end

	if self.suffix then
		self.labelText02.text = self.suffix
	else
		self.labelText02:SetActive(false)
	end

	for i = 1, #self.awards do
		local data = self.awards[i]
		local item = xyd.getItemIcon({
			hideText = true,
			uiRoot = self.groupAwards,
			itemID = data[1],
			num = data[2]
		})
		local h = self.groupAwards:GetComponent(typeof(UIWidget)).height

		item:SetLocalScale(h / 108, h / 108, 1)
		item:labelNumScale(1.2)
	end

	self.groupAwards:GetComponent(typeof(UILayout)):Reposition()
end

function VipBenefitItem:onClickpickBtn()
	if self.price then
		local isAbsence = xyd.isItemAbsence(self.price[1], self.price[2], true)

		if not isAbsence then
			xyd.alertYesNo(__("CONFIRM_BUY"), function (yes_no)
				if yes_no then
					xyd.models.vip:buyVipAward(self.id)
					self:setPickBtnEnabled(false)
				end
			end)
		end
	else
		__TRACE(self.id)
		xyd.models.vip:getVipAward(self.id)
		self:setPickBtnEnabled(false)
	end
end

function VipBenefitItem:setPickBtnEnabled(state)
	if state == true then
		xyd.applyChildrenOrigin(self.pickBtn.gameObject)
	end

	if state == false then
		xyd.applyChildrenGrey(self.pickBtn.gameObject)

		self.pickBtn_boxCollider.enabled = state

		if self.id <= xyd.models.backpack:getVipLev() then
			if self.price then
				self.pickBtn:ComponentByName("Sprite", typeof(UISprite)):SetActive(false)

				self.pickBtn_label.fontSize = 24

				self.pickBtn_label:X(0)

				self.pickBtn_label.text = __("ALREADY_BUY")
			else
				self.pickBtn_label.text = __("ALREADY_GET_PRIZE")
			end
		end
	end
end

function VipBenefitContent:ctor(parentGO, vip, parentPanelDepth)
	VipBenefitContent.super.ctor(self, parentGO)

	self.vip = vip
	self.parentPanelDepth = parentPanelDepth

	self:getUIComponent()
	self:initUIComponent()
end

function VipBenefitContent:getPrefabPath()
	return "Prefabs/Windows/vip_benefit_content"
end

function VipBenefitContent:getUIComponent()
	local go = self.go
	local vipNum = go:NodeByName("vipGroup/vipGroup1").gameObject
	self.vipNum = PngNum.new(vipNum)
	self.scrollerPanel = go:ComponentByName("scroller_", typeof(UIPanel))
	self.groupContent = go:NodeByName("scroller_/groupContent").gameObject
	self.rect = go:NodeByName("rect").gameObject
	self.scrollerPanel.depth = self.parentPanelDepth + 1
end

function VipBenefitContent:initUIComponent()
	local ids = xyd.tables.vipTextTable:getIds()

	for i = 1, #ids do
		local id = ids[i]

		self:setContnent(id)
	end

	self.vipNum:setInfo({
		iconName = "player_vip",
		num = self.vip
	})
end

function VipBenefitContent:setContnent(id)
	local vip = self.vip
	local title = xyd.tables.vipTextTable:getTitle(id)
	local text = xyd.tables.vipTextTable:getText(id)
	local value, content = nil

	if title == "month_card_awards_show" then
		value = xyd.tables.vipTable:split2Cost(vip, title, "|#")

		if #value > 0 then
			content = VipBenefitItem.new(self.groupContent, {
				state = "award",
				text = text,
				awards = value,
				id = self.vip
			})
		end
	elseif title == "vip_awards" then
		value = xyd.tables.vipTable:split2Cost(vip, title, "|#")

		if #value > 0 then
			local isCanPick = xyd.models.vip:isCanPickAward(self.vip)
			content = VipBenefitItem.new(self.groupContent, {
				state = "pick_awards",
				text = text,
				awards = value,
				isCanPick = isCanPick,
				id = self.vip
			})
		end
	elseif title == "vip_giftbox" then
		value = xyd.tables.vipTable:split2Cost(vip, title, "|#")

		if #value > 0 then
			local price = xyd.tables.vipTable:split2Cost(vip, "vip_giftbox_cost", "#")
			local isCanPick = xyd.models.vip:isCanBuyGift(self.vip)
			content = VipBenefitItem.new(self.groupContent, {
				state = "pick_awards",
				text = text,
				awards = value,
				price = price,
				isCanPick = isCanPick,
				id = self.vip
			})
		end
	elseif title == "gacha_box" or title == "gamble" or title == "battle_speed" or title == "gamble_up" or title == "gacha_50times" or title == "auto_transfer" or title == "login_double" then
		value = xyd.tables.vipTable:getNumber(vip, title)

		if value and value ~= 0 then
			content = VipBenefitItem.new(self.groupContent, {
				state = "text",
				text = text
			})
		end
	elseif title == "extra_midas" or title == "extra_output" then
		value = xyd.tables.vipTable:getNumber(vip, title)

		if value then
			content = VipBenefitItem.new(self.groupContent, {
				state = "text",
				text = text,
				suffix = tostring(math.floor(value * 100)) .. "%"
			})
		end
	elseif title == "midas_buy_times" or title == "pub_mission_num" or title == "quiz_buy_times" then
		value = xyd.tables.vipTable:getNumber(vip, title)

		if value then
			content = VipBenefitItem.new(self.groupContent, {
				state = "text",
				text = text,
				suffix = math.floor(value)
			})
		end
	elseif title == "partners_limit" then
		value = xyd.tables.vipTable:getNumber(vip, title)

		if value then
			local old = xyd.tables.vipTable:getNumber(vip - 1, title)
			content = VipBenefitItem.new(self.groupContent, {
				state = "text",
				text = text,
				suffix = math.floor(value - old)
			})
		end
	elseif title == "travel_buy_time_limit" then
		value = xyd.split(xyd.tables.miscTable:getVal("travel_buy_time_limit"), "|", true)[vip + 1]

		if value then
			content = VipBenefitItem.new(self.groupContent, {
				state = "text",
				text = text,
				suffix = math.floor(value)
			})
		end
	end

	self.groupContent:GetComponent(typeof(UILayout)):Reposition()
end

return VipWindow
