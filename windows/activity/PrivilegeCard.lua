local CountDown = import("app.components.CountDown")
local ActivityContent = import(".ActivityContent")
local PrivilegeCard = class("PrivilegeCard", ActivityContent)
local PrivilegeCardItem = class("PrivilegeCardItem", import("app.components.CopyComponent"))

function PrivilegeCard:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.currentState = xyd.Global.lang
	self.discountGiftBagIDs = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.LIMIT_DISCOUNT_PRIVILEGE_CARD)
	self.giftbagIDs = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.PRIVILEGE_CARD)
	self.itemDataArr = {}

	self:getUIComponent()
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityData))
	self:setItem()

	local pivilegeCardTemp_red = tonumber(xyd.db.misc:getValue("pivilegeCardTemp_red"))

	if pivilegeCardTemp_red == nil then
		xyd.db.misc:setValue({
			value = 1,
			key = "pivilegeCardTemp_red"
		})

		local activityWinDow = xyd.WindowManager.get():getWindow("activity_window")

		activityWinDow:setTitleRedMark(self.id, false)
		activityWinDow:updateRedMark(self.id, -1)
	end
end

function PrivilegeCard:getPrefabPath()
	return "Prefabs/Windows/activity/privilege_card_activity"
end

function PrivilegeCard:getUIComponent()
	local go = self.go
	self.scroller = go:NodeByName("allGroup/scroller").gameObject
	self.scroller_scrollView = self.scroller:GetComponent(typeof(UIScrollView))
	self.scroller_uiPanel = self.scroller:GetComponent(typeof(UIPanel))
	self.groupItem = self.scroller:NodeByName("groupItem").gameObject
	self.groupItem_uiLayout = self.groupItem:GetComponent(typeof(UILayout))
	self.eg_item = go:NodeByName("eg_item").gameObject
	self.empty_item = go:NodeByName("empty_item").gameObject
	self.emptyText = go:ComponentByName("empty_item/emptyText", typeof(UILabel))
	self.emptyText.text = __("ACTIVITY_PRIVILEGE_CARD_NOT_COMING_SOON")
end

function PrivilegeCard:setItem()
	local datas = self.activityData.detail.charges

	NGUITools.DestroyChildren(self.groupItem.transform)

	local serverTime = xyd.getServerTime()
	local openStateIdArr = xyd.tables.miscTable:split2Cost("activity_privileged_card_function_open", "value", "|")

	for i in pairs(datas) do
		local timeDis = (datas[i].end_time or 0) - serverTime
		local countDays = 0

		if timeDis > 0 then
			countDays = math.ceil(timeDis / 86400)
		end

		local isDiscount = false

		for j = 1, #self.discountGiftBagIDs do
			if datas[i].table_id == self.discountGiftBagIDs[j] then
				isDiscount = true

				break
			end
		end

		local param = {
			table_id = datas[i].table_id,
			buy_times = datas[i].buy_times,
			days = datas[i].days,
			end_time = datas[i].end_time,
			left_days = datas[i].left_days,
			countDays = countDays,
			openStateId = openStateIdArr[i],
			isDiscount = isDiscount,
			url_id = self.giftbagIDs[i]
		}

		if self["timedealy" .. i] ~= nil and self["timedealy" .. i] ~= -1 then
			xyd.removeGlobalTimer(self["timedealy" .. i])
		end

		self["timedealy" .. i] = -1

		if countDays > 0 then
			local delayDays_time = (countDays - 1) * 3600
			local delayTime = serverTime + delayDays_time
			local delayDisTime = (datas[i].end_time or 0) - delayTime
			self["timedealy" .. i] = xyd.addGlobalTimer(handler(self, self.setItem), delayDisTime + 5, 1)
		end

		local posData = xyd.tables.miscTable:split2Cost("activity_privileged_card_ui_type", "value", "|#")[i]
		local tmp = NGUITools.AddChild(self.groupItem.gameObject, self.eg_item.gameObject)
		local item = PrivilegeCardItem.new(tmp, param, posData, self)

		table.insert(self.itemDataArr, item)
	end

	local tmp = NGUITools.AddChild(self.groupItem.gameObject, self.empty_item.gameObject)

	self:waitForFrame(1, function ()
		self.groupItem_uiLayout:Reposition()
	end, nil)
end

function PrivilegeCard:onActivityData()
	local datas = self.activityData.detail.charges
	local serverTime = xyd.getServerTime()
	local openStateIdArr = xyd.tables.miscTable:split2Cost("activity_privileged_card_function_open", "value", "|")

	for i in pairs(datas) do
		local timeDis = (datas[i].end_time or 0) - serverTime
		local countDays = 0

		if timeDis > 0 then
			countDays = math.ceil(timeDis / 86400)
		end

		local isDiscount = false

		for j = 1, #self.discountGiftBagIDs do
			if datas[i].table_id == self.discountGiftBagIDs[j] then
				isDiscount = true

				break
			end
		end

		local param = {
			table_id = datas[i].table_id,
			buy_times = datas[i].buy_times,
			days = datas[i].days,
			end_time = datas[i].end_time,
			left_days = datas[i].left_days,
			countDays = countDays,
			openStateId = openStateIdArr[i],
			isDiscount = isDiscount,
			url_id = self.giftbagIDs[i]
		}

		self.itemDataArr[i]:updateInfo(param)
	end
end

function PrivilegeCard:dispose()
	local datas = self.activityData.detail.charges

	for i in pairs(datas) do
		if self["timedealy" .. i] ~= nil and self["timedealy" .. i] ~= -1 and xyd.models.selfPlayer then
			xyd.removeGlobalTimer(self["timedealy" .. i])
		end
	end

	PrivilegeCard.super.dispose(self)
end

function PrivilegeCardItem:ctor(goItem, itemdata, posData, parent)
	self.goItem_ = goItem
	local transGo = goItem.transform
	self.posData = posData
	self.id_ = tonumber(itemdata.table_id)
	self.itemdata = itemdata
	self.bgImg = transGo:ComponentByName("bgImg", typeof(UISprite))
	self.nameImg = transGo:ComponentByName("nameImg", typeof(UISprite))
	self.explainImg = transGo:ComponentByName("explainImg", typeof(UISprite))
	self.valueGroup = transGo:NodeByName("valueGroup").gameObject
	self.itemGroup = transGo:NodeByName("valueGroup/itemGroup").gameObject
	self.explainText = transGo:ComponentByName("valueGroup/explainText", typeof(UILabel))
	self.buyBtn = transGo:NodeByName("valueGroup/buyBtn").gameObject
	self.buyBtn_button_label = transGo:ComponentByName("valueGroup/buyBtn/button_label", typeof(UILabel))
	self.originLabel = self.buyBtn:ComponentByName("originLabel", typeof(UILabel))
	self.tipsGroup = transGo:NodeByName("tipsGroup").gameObject
	self.textGroup1 = self.tipsGroup:NodeByName("textGroup1").gameObject
	self.tipsText1 = self.textGroup1:ComponentByName("tipsText1", typeof(UILabel))
	self.tipsText2 = self.textGroup1:ComponentByName("tipsText2", typeof(UILabel))
	self.tipsText3 = self.tipsGroup:ComponentByName("tipsText3", typeof(UILabel))
	self.dumpIcon = self.valueGroup:ComponentByName("dumpIcon", typeof(UISprite))
	self.dumpNum = self.dumpIcon:ComponentByName("dumpNum", typeof(UILabel))
	self.dumpText = self.dumpIcon:ComponentByName("dumpText", typeof(UILabel))

	self:initBaseInfo(itemdata)
	self:initItem(itemdata)
end

function PrivilegeCardItem:updateInfo(itemdata)
	self.id_ = tonumber(itemdata.table_id)
	self.itemdata = itemdata

	self:initBaseInfo(itemdata)
	self:initItem(itemdata)
end

function PrivilegeCardItem:initBaseInfo(itemdata)
	self.tipsText1.text = __("ACTIVITY_PRIVILEGE_CARD_PRIVILEGE_TIME")
	self.tipsText2.text = __("DAY", tostring(itemdata.countDays))
	self.tipsText3.text = __("ACTIVITY_PRIVILEGE_CARD_NOT_ACTIVE")
	self.explainText.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(self.id_)) .. " VIP EXP"

	if self.id_ == xyd.GIFTBAG_ID.PRIVILEGE_CARD_TRIAL or xyd.tables.giftBagTable:getParams(self.id_) and xyd.tables.giftBagTable:getParams(self.id_)[1] == xyd.GIFTBAG_ID.PRIVILEGE_CARD_TRIAL then
		self.explainText.color = Color.New2(3895406591.0)
	elseif self.id_ == xyd.GIFTBAG_ID.PRIVILEGE_CARD_DUNGEON or xyd.tables.giftBagTable:getParams(self.id_) and xyd.tables.giftBagTable:getParams(self.id_)[1] == xyd.GIFTBAG_ID.PRIVILEGE_CARD_DUNGEON then
		self.explainText.color = Color.New2(797370623)
	end

	self.buyBtn_button_label.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.id_) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.id_))

	xyd.setUISpriteAsync(self.bgImg, nil, "bg_" .. tostring(itemdata.url_id) .. "_privilege_card")
	xyd.setUISpriteAsync(self.nameImg, nil, "logo_privilege_card_" .. tostring(itemdata.url_id) .. "_" .. tostring(xyd.Global.lang), function ()
		self.nameImg:MakePixelPerfect()
	end, nil)
	xyd.setUISpriteAsync(self.explainImg, nil, "ms_privilege_card_" .. tostring(itemdata.url_id) .. "_" .. tostring(xyd.Global.lang), function ()
		self.explainImg:MakePixelPerfect()
	end, nil)

	if tonumber(itemdata.countDays) > 0 then
		self.textGroup1:SetActive(true)
		self.tipsText3:SetActive(false)
	else
		self.textGroup1:SetActive(false)
		self.tipsText3:SetActive(true)
	end

	xyd.setDarkenBtnBehavior(self.buyBtn, self, function ()
		if xyd.checkFunctionOpen(itemdata.openStateId) then
			xyd.SdkManager.get():showPayment(self.id_)
		end
	end)

	if tonumber(self.posData[1]) == 0 then
		self.valueGroup:SetLocalPosition(-128, -1, 0)
		self.tipsGroup:SetLocalPosition(76.5, 94.6, 0)
		self.tipsGroup:SetLocalScale(1, 1, 1)
		self.tipsText1:SetLocalScale(1, 1, 1)
		self.tipsText2:SetLocalScale(1, 1, 1)
		self.tipsText3:SetLocalScale(1, 1, 1)

		self.nameImg.gameObject:GetComponent(typeof(UIWidget)).pivot = UIWidget.Pivot.Left

		self.nameImg:SetLocalPosition(-352, 167, 0)
	elseif tonumber(self.posData[1]) == 1 then
		self.valueGroup:SetLocalPosition(128, -1, 0)
		self.tipsGroup:SetLocalPosition(-80, 94.6, 0)
		self.tipsGroup:SetLocalScale(-1, 1, 1)
		self.tipsText1:SetLocalScale(-1, 1, 1)
		self.tipsText2:SetLocalScale(-1, 1, 1)
		self.tipsText3:SetLocalScale(-1, 1, 1)

		self.nameImg.gameObject:GetComponent(typeof(UIWidget)).pivot = UIWidget.Pivot.Right

		self.nameImg:SetLocalPosition(352, 167, 0)
	end

	if tonumber(self.posData[2]) == 0 then
		self.bgImg:SetLocalScale(1, 1, 1)
	else
		self.bgImg:SetLocalScale(-1, 1, 1)
	end

	if itemdata.isDiscount then
		self.dumpIcon:SetActive(true)

		self.dumpNum.text = "60%"
		self.dumpText.text = "OFF"

		self.buyBtn_button_label:Y(10)
		self.originLabel:SetActive(true)

		local originTableID = xyd.tables.giftBagTable:getParams(self.id_)[1]
		self.originLabel.text = "[s]" .. __("SALE_MONTH_GIFTBAG1") .. tostring(xyd.tables.giftBagTextTable:getCurrency(originTableID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(originTableID)) .. "[/s]"
	else
		self.dumpIcon:SetActive(false)
		self.buyBtn_button_label:Y(0)
		self.originLabel:SetActive(false)
	end
end

function PrivilegeCardItem:initItem(itemdata)
	NGUITools.DestroyChildren(self.itemGroup.transform)

	local scaleNum = 0.7962962962962963
	local giftId = xyd.tables.giftBagTable:getGiftID(self.id_)
	local awardArr = xyd.tables.giftTable:getAwards(giftId)

	for i, reward in pairs(awardArr) do
		if reward[1] ~= xyd.ItemID.EXP and reward[1] ~= xyd.ItemID.VIP_EXP then
			local icon = xyd.getItemIcon({
				isAddUIDragScrollView = true,
				isShowSelected = false,
				itemID = reward[1],
				num = reward[2],
				uiRoot = self.itemGroup.gameObject,
				scale = Vector3(scaleNum, scaleNum, 1)
			})

			icon:setItemIconDepth(25)
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

function PrivilegeCardItem:updateTime(countDays)
	if tonumber(countDays) > 0 then
		self.textGroup1:SetActive(true)
		self.tipsText3:SetActive(false)
	else
		self.textGroup1:SetActive(false)
		self.tipsText3:SetActive(true)
	end

	self.tipsText2.text = __("DAY", tostring(countDays))
end

function PrivilegeCardItem:getID()
	return self.id_
end

return PrivilegeCard
