local ActivityChristmasExchange = class("ActivityChristmasExchange", import(".ActivityContent"))
local ActivityChristmasExchangeItem = class("ActivityChristmasExchangeItem", import("app.components.CopyComponent"))
local json = require("cjson")
local PartnerCard = import("app.components.PartnerCard")
local Partner = import("app.models.Partner")
local CommonTabBar = import("app.common.ui.CommonTabBar")

function ActivityChristmasExchange:ctor(parentGO, params)
	ActivityChristmasExchange.super.ctor(self, parentGO, params)
end

function ActivityChristmasExchange:getPrefabPath()
	return "Prefabs/Windows/activity/activity_christmas_exchange"
end

function ActivityChristmasExchange:resizeToParent()
	ActivityChristmasExchange.super.resizeToParent(self)

	local allHeight = self.go:GetComponent(typeof(UIWidget)).height
	local heightDis = allHeight - 874

	self:resizePosY(self.midGroup, -519, -688)
	self:resizePosY(self.resourcesGroup, -27, -104)
	self:resizePosY(self.titleImg_, -161, -217)
	self:resizePosY(self.partnerEffectPos, -440, -469)
	self:resizePosY(self.bg3, -454, -593)
end

function ActivityChristmasExchange:initUI()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_CHRISTMAS_EXCHANGE)
	self.activityData.perLogin = false

	self:getUIComponent()
	ActivityChristmasExchange.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityChristmasExchange:getUIComponent()
	local go = self.go
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.titleImg_ = self.groupAction:ComponentByName("titleImg_", typeof(UITexture))
	self.bg3 = self.groupAction:ComponentByName("Bg3_", typeof(UISprite))
	self.partnerEffectPos = self.groupAction:ComponentByName("partnerEffectPos", typeof(UITexture))
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.btnHelp = self.topGroup:NodeByName("btnHelp").gameObject
	self.resourcesGroup = self.topGroup:NodeByName("resourcesGroup").gameObject
	self.resource1Group = self.resourcesGroup:NodeByName("resource1Group").gameObject
	self.imgResource = self.resource1Group:ComponentByName("img_", typeof(UISprite))
	self.labelResource = self.resource1Group:ComponentByName("label_", typeof(UILabel))
	self.addBtn = self.resource1Group:NodeByName("addBtn").gameObject
	self.midGroup = self.groupAction:NodeByName("midGroup").gameObject
	self.nav = self.midGroup:NodeByName("nav").gameObject
	self.tab_1 = self.nav:NodeByName("tab_1").gameObject
	self.tab_2 = self.nav:NodeByName("tab_2").gameObject
	self.tab_3 = self.nav:NodeByName("tab_3").gameObject
	self.content = self.midGroup:NodeByName("content").gameObject
	self.btnExchange = self.content:NodeByName("btnExchange").gameObject
	self.labelBtnExchange = self.btnExchange:ComponentByName("label", typeof(UILabel))
	self.imgBtnExchange = self.btnExchange:ComponentByName("img", typeof(UISprite))
	self.labelLimit = self.content:ComponentByName("labelLimit", typeof(UILabel))
	self.content1Group = self.content:NodeByName("content1Group").gameObject
	self.oldCardPos1 = self.content1Group:ComponentByName("oldCardPos", typeof(UITexture))
	self.newCardPos1 = self.content1Group:ComponentByName("newCardPos", typeof(UITexture))
	self.content2Group = self.content:NodeByName("content2Group").gameObject
	self.oldCardPos2 = self.content2Group:ComponentByName("oldCardPos", typeof(UITexture))
	self.newCardPos2 = self.content2Group:ComponentByName("newCardPos", typeof(UITexture))
	self.content3Group = self.content:NodeByName("content3Group").gameObject
	self.oldCardPos3 = self.content3Group:ComponentByName("oldCardPos", typeof(UITexture))
	self.newCardPos3 = self.content3Group:ComponentByName("newCardPos", typeof(UITexture))
	self.clickMaskOldCard = self.content:NodeByName("oldCardClickMask").gameObject
	self.clickMaskNewCard = self.content:NodeByName("newCardClickMask").gameObject
	self.tabBar = CommonTabBar.new(self.nav, 3, function (index)
		self.tabIndex = index

		if index == 1 then
			self.content1Group:SetActive(true)
			self.content2Group:SetActive(false)
			self.content3Group:SetActive(false)
			self:updateCardGroup()
			self:updateBtnExchangeGroup()
			self:updateResGroup()
			self:updateRedPoint()
		elseif index == 2 then
			self.content1Group:SetActive(false)
			self.content2Group:SetActive(true)
			self.content3Group:SetActive(false)
			self:updateCardGroup()
			self:updateBtnExchangeGroup()
			self:updateResGroup()
			self:updateRedPoint()
		elseif index == 3 then
			self.content1Group:SetActive(false)
			self.content2Group:SetActive(false)
			self.content3Group:SetActive(true)
			self:updateCardGroup()
			self:updateBtnExchangeGroup()
			self:updateResGroup()
			self:updateRedPoint()
		end
	end, nil, , 15)
	self.partnerCardOld = PartnerCard.new(self.oldCardPos1.gameObject)
	self.partnerCardNew = PartnerCard.new(self.newCardPos1.gameObject)
	self.skinCardOld = PartnerCard.new(self.oldCardPos2.gameObject)
	self.skinCardNew = PartnerCard.new(self.newCardPos2.gameObject)
	self.equipCardOld = xyd.getItemIcon({
		hideText = true,
		scale = 1,
		uiRoot = self.oldCardPos3.gameObject
	})
	self.equipCardNew = xyd.getItemIcon({
		hideText = true,
		scale = 1,
		uiRoot = self.newCardPos3.gameObject
	})
end

function ActivityChristmasExchange:register()
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self:updateResGroup()
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data
		local detail = json.decode(data.detail)

		if data.activity_id == xyd.ActivityID.ACTIVITY_CHRISTMAS_EXCHANGE then
			self:onGetMsg(event)
		end
	end)

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_SOCKS_CHANGE_HELP"
		})
	end

	UIEventListener.Get(self.addBtn).onClick = function ()
		local data = self.activityData:getResource()

		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = data[1],
			activityData = self.activityData,
			openItemBuyWnd = handler(self, self.getAddCallback)
		})
	end

	UIEventListener.Get(self.btnExchange).onClick = function ()
		local leftTime = self.activityData:getLeftTime(self.tabIndex)

		if self.tabIndex == 3 and leftTime <= 0 then
			xyd.alertTips(__("ACTIVITY_SOCKS_CHANGE_TEXT06"))

			return
		end

		self:clickbtnExchange()
	end

	UIEventListener.Get(self.clickMaskOldCard).onClick = function ()
		local leftTime = self.activityData:getLeftTime(self.tabIndex)

		if self.tabIndex == 3 and leftTime <= 0 then
			xyd.alertTips(__("ACTIVITY_SOCKS_CHANGE_TEXT06"))

			return
		end

		self:clickOldCard()
	end

	UIEventListener.Get(self.clickMaskNewCard).onClick = function ()
		local leftTime = self.activityData:getLeftTime(self.tabIndex)

		if self.tabIndex == 3 and leftTime <= 0 then
			xyd.alertTips(__("ACTIVITY_SOCKS_CHANGE_TEXT06"))

			return
		end

		if not self.activityData:getOldCardData(self.tabIndex) then
			xyd.alertTips(__("ACTIVITY_SOCKS_CHANGE_TIPS"))

			return
		end

		self:clickNewCard()
	end
end

function ActivityChristmasExchange:initUIComponent()
	self.tabBar.tabs[1].label.text = __("ACTIVITY_SOCKS_CHANGE_TEXT01")
	self.tabBar.tabs[2].label.text = __("ACTIVITY_SOCKS_CHANGE_TEXT02")
	self.tabBar.tabs[3].label.text = __("ACTIVITY_SOCKS_CHANGE_TEXT03")

	xyd.setUITextureByNameAsync(self.titleImg_, "activity_exchange_logo_" .. xyd.Global.lang)

	self.effect = xyd.Spine.new(self.partnerEffectPos.gameObject)

	self.effect:setInfo("xunyu_pifu02_lihui01", function ()
		self.effect:play("animation", 0, 1, function ()
		end, true)
	end)
	self:updateCardGroup()
	self:updateBtnExchangeGroup()
	self:updateResGroup()
	self:updateRedPoint()
end

function ActivityChristmasExchange:updateCardGroup()
	local oldCardData = self.activityData:getOldCardData(self.tabIndex)
	local newCardData = self.activityData:getNewCardData(self.tabIndex)

	self.oldCardPos1:SetActive(false)
	self.oldCardPos2:SetActive(false)
	self.oldCardPos3:SetActive(false)
	self.newCardPos1:SetActive(false)
	self.newCardPos2:SetActive(false)
	self.newCardPos3:SetActive(false)

	if self.tabIndex == 1 then
		print("@2222222222")

		if oldCardData then
			self.oldCardPos1:SetActive(true)

			local partnerID = oldCardData
			local partner = xyd.models.slot:getPartner(partnerID)
			local info = {
				tableID = partner:getTableID(),
				star = partner:getStar(),
				lev = partner:getLevel(),
				grade = partner:getGrade()
			}

			self.partnerCardOld:setInfo(info)
		end

		if oldCardData and newCardData then
			self.newCardPos1:SetActive(true)

			local InAwardIndex = newCardData
			local awards = xyd.tables.activityChristmasSocksExchangeTable:getAwards(self.activityData.exchangeData[self.tabIndex].tableID)
			local tableID = awards[InAwardIndex][1]
			local info = {
				lev = 1,
				tableID = tableID,
				star = xyd.tables.partnerTable:getStar(tableID)
			}

			self.partnerCardNew:setInfo(info)
		end
	elseif self.tabIndex == 2 then
		if oldCardData then
			self.oldCardPos2:SetActive(true)

			local partnerTableID = xyd.tables.partnerPictureTable:getSkinPartner(oldCardData)[1]
			local info = {
				tableID = partnerTableID,
				group = xyd.tables.partnerTable:getGroup(partnerTableID),
				skin_id = oldCardData
			}

			self.skinCardOld:resetData()
			self.skinCardOld:setSkinCard(info)
			self.skinCardOld:setDisplay()
		end

		if oldCardData and newCardData then
			self.newCardPos2:SetActive(true)

			local InAwardIndex = newCardData
			local awards = xyd.tables.activityChristmasSocksExchangeTable:getAwards(self.activityData.exchangeData[self.tabIndex].tableID)
			local skinID = awards[InAwardIndex][1]
			local partnerTableID = xyd.tables.partnerPictureTable:getSkinPartner(skinID)[1]
			local info = {
				tableID = partnerTableID,
				group = xyd.tables.partnerTable:getGroup(partnerTableID),
				skin_id = skinID
			}

			self.skinCardNew:resetData()
			self.skinCardNew:setSkinCard(info)
			self.skinCardNew:setDisplay()
		end
	elseif self.tabIndex == 3 then
		local leftTime = self.activityData:getLeftTime(self.tabIndex)
		local lockImg1 = self.content3Group:NodeByName("oldCardBgGroup/lock_img").gameObject
		local plusImg1 = self.content3Group:NodeByName("oldCardBgGroup/plusEquip6").gameObject

		lockImg1:SetActive(leftTime <= 0)
		plusImg1:SetActive(leftTime > 0)

		local lockImg2 = self.content3Group:NodeByName("newCardBgGroup/lock_img").gameObject
		local plusImg2 = self.content3Group:NodeByName("newCardBgGroup/plusEquip6").gameObject

		lockImg2:SetActive(leftTime <= 0)
		plusImg2:SetActive(leftTime > 0)

		if oldCardData then
			self.oldCardPos3:SetActive(true)
			self.equipCardOld:setInfo({
				hideText = true,
				scale = 1,
				itemID = oldCardData
			})
		end

		if oldCardData and newCardData then
			local InAwardIndex = newCardData
			local awards = xyd.tables.activityChristmasSocksExchangeTable:getAwards(self.activityData.exchangeData[self.tabIndex].tableID)
			local itemID = awards[InAwardIndex][1]

			self.newCardPos3:SetActive(true)
			self.equipCardNew:setInfo({
				hideText = true,
				scale = 1,
				itemID = itemID
			})
		end
	end

	if self.tabIndex == 3 then
		self.btnExchange:Y(-270)
		self.labelLimit:Y(-210)
		self.content3Group:Y(0)
		self.clickMaskOldCard:X(-134)
		self.clickMaskNewCard:X(134)
	else
		self.btnExchange:Y(-290)
		self.labelLimit:Y(-234)
		self.content3Group:Y(0)
		self.clickMaskOldCard:X(-153)
		self.clickMaskNewCard:X(153)
	end
end

function ActivityChristmasExchange:updateBtnExchangeGroup()
	local oldData = self.activityData:getOldCardData(self.tabIndex)
	local newData = self.activityData:getNewCardData(self.tabIndex)

	if self.tabIndex then
		self.labelLimit.text = __("ACTIVITY_SOCKS_CHANGE_TEXT09") .. self.activityData:getLeftTime(self.tabIndex)

		self.labelLimit:SetActive(true)

		local leftTime = self.activityData:getLeftTime(self.tabIndex)
		self.labelLimit.text = __("ACTIVITY_SOCKS_CHANGE_TEXT09") .. leftTime
	end

	if not oldData or not newData then
		self.labelBtnExchange.text = "???"

		return
	end

	local cost = self.activityData:getSingleCost(self.tabIndex)
	self.labelBtnExchange.text = cost[2]

	xyd.setUISpriteAsync(self.imgBtnExchange, nil, xyd.tables.itemTable:getIcon(cost[1]))
	self.btnExchange:SetActive(true)
end

function ActivityChristmasExchange:updateResGroup()
	local res1Data = self.activityData:getResource()

	xyd.setUISpriteAsync(self.imgResource, nil, xyd.tables.itemTable:getIcon(res1Data[1]))

	self.labelResource.text = xyd.models.backpack:getItemNumByID(res1Data[1])
end

function ActivityChristmasExchange:clickOldCard()
	local itemsInfo = self.activityData:getCanChooseOldData(self.tabIndex)
	local oldIndex = self.activityData:getOldCardData(self.tabIndex)
	local hideFilter = true

	if self.tabIndex == 2 then
		hideFilter = nil
	end

	xyd.openWindow("activity_christmas_exchange_award_select_window", {
		type = self.tabIndex,
		titleLabel = __("ACTIVITY_SOCKS_CHANGE_TEXT11"),
		selectedIndexId = oldIndex,
		itemsInfo = itemsInfo,
		sureCallback = function (selectedIndexId)
			self.activityData:ChooseOldCard(self.tabIndex, selectedIndexId)
			self:updateCardGroup()
			self:updateBtnExchangeGroup()
		end
	})
end

function ActivityChristmasExchange:clickNewCard()
	local itemsInfo = self.activityData:getCanChooseNewData(self.tabIndex)
	local newIndex = self.activityData:getNewCardData(self.tabIndex)
	local selectedIndexId = self.activityData.newCardData[self.tabIndex]
	local hideFilter = true

	if self.tabIndex == 2 then
		hideFilter = nil
	end

	xyd.openWindow("activity_christmas_exchange_award_select_window", {
		type = self.tabIndex,
		selectedIndexId = selectedIndexId,
		itemsInfo = itemsInfo,
		hideFilter = hideFilter,
		sureCallback = function (selectedIndexId)
			self.activityData:ChooseNewCard(self.tabIndex, selectedIndexId)
			self:updateCardGroup()
			self:updateBtnExchangeGroup()
		end
	})
end

function ActivityChristmasExchange:updateRedPoint()
end

function ActivityChristmasExchange:getAddCallback()
	if self.activityData:getBuyLeftTime() <= 0 then
		xyd.showToast(__("ACTIVITY_WORLD_BOSS_LIMIT"))

		return
	end

	local leftTime = self.activityData:getBuyLeftTime()
	local cost = self.activityData:getBuySingleCost()
	local getItems = self.activityData:getBuySingleGet()
	local canBuyTime = xyd.models.backpack:getItemNumByID(cost[1]) / cost[2]
	local single = 1

	if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTextTable:getName(cost[1])))

		return
	end

	xyd.WindowManager.get():openWindow("limit_purchase_item_window", {
		imgExchangeHeight = 38,
		imgExchangeWidth = 38,
		needTips = true,
		limitKey = "限制",
		hasMaxMin = true,
		notEnoughKey = "PERSON_NO_CRYSTAL",
		buyType = getItems[1],
		buyNum = getItems[2],
		costType = tonumber(cost[1]),
		costNum = tonumber(cost[2]),
		descLabel = __("ACTIVITY_SOCKS_CHANGE_BUY_TEXT", leftTime, xyd.tables.miscTable:getNumber("activity_christmas_socks_buy_limit", "value")),
		purchaseCallback = function (evt, num)
			if xyd.models.backpack:getItemNumByID(tonumber(cost[1])) < tonumber(cost[2]) * num then
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(cost[1])))

				return
			end

			self.activityData.sendMsg = {
				type = 2,
				num = num
			}

			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_CHRISTMAS_EXCHANGE, json.encode({
				type = 2,
				num = num
			}))
		end,
		titleKey = __("ACTIVITY_SOCKS_CHANGE_BUY"),
		limitNum = math.min(leftTime, canBuyTime),
		eventType = xyd.event.GET_ACTIVITY_AWARD
	})
end

function ActivityChristmasExchange:clickbtnExchange()
	local oldData = self.activityData:getOldCardData(self.tabIndex)
	local newData = self.activityData:getNewCardData(self.tabIndex)
	local partnerID = nil

	if not oldData then
		xyd.alertTips(__("ACTIVITY_SOCKS_CHANGE_TEXT11"))

		return
	end

	if not newData then
		xyd.alertTips(__("ACTIVITY_SOCKS_CHANGE_TEXT12"))

		return
	end

	local exchangeData = self.activityData.exchangeData[self.tabIndex]
	local limitTime = xyd.tables.activityChristmasSocksExchangeTable:getLimit(exchangeData.tableID)

	if limitTime <= self.activityData.detail.times[exchangeData.tableID] then
		xyd.alertTips(__("ACTIVITY_SOCKS_CHANGE_TEXT06"))

		return
	end

	local cost = self.activityData:getSingleCost(self.tabIndex)

	if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

		return
	end

	local function callback(flag)
		if flag == true then
			local awards = xyd.tables.activityChristmasSocksExchangeTable:getAwards(self.activityData.exchangeData[self.tabIndex].tableID)
			local cost_id = nil

			if self.tabIndex == 1 then
				partnerID = oldData
				local partner = xyd.models.slot:getPartner(partnerID)
				cost_id = partner:getTableID()
			elseif self.tabIndex == 2 or self.tabIndex == 3 then
				cost_id = oldData
			end

			local costIndex = nil
			local costCards = xyd.tables.activityChristmasSocksExchangeTable:getCostCard(self.activityData.exchangeData[self.tabIndex].tableID)

			for i = 1, #costCards do
				if cost_id == costCards[i][1] then
					costIndex = i
				end
			end

			self.activityData.sendMsg = {
				type = 1,
				num = 1,
				partner_id = partnerID,
				table_id = exchangeData.tableID,
				award_index = newData,
				award_id = awards[newData][1],
				cost_index = costIndex,
				cost_id = cost_id,
				tabIndex = self.tabIndex
			}

			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_CHRISTMAS_EXCHANGE, json.encode({
				type = 1,
				num = 1,
				partner_id = partnerID,
				table_id = exchangeData.tableID,
				award_index = newData,
				award_id = awards[newData][1],
				cost_index = costIndex,
				cost_id = cost_id
			}))
		end
	end

	local awards = xyd.tables.activityChristmasSocksExchangeTable:getAwards(self.activityData.exchangeData[self.tabIndex].tableID)
	local name1, name2 = nil

	if self.tabIndex == 1 then
		local partnerID = oldData
		local partner = xyd.models.slot:getPartner(partnerID)
		name1 = partner:getName()
		local tableID = awards[newData][1]
		name2 = xyd.tables.partnerTable:getName(tableID)
	elseif self.tabIndex == 2 or self.tabIndex == 3 then
		name1 = xyd.tables.itemTable:getName(oldData)
		name2 = xyd.tables.itemTable:getName(awards[newData][1])
	end

	xyd.alertYesNo(__("ACTIVITY_SOCKS_CHANGE_TEXT05", self.labelBtnExchange.text, name1, name2), callback, __("YES"), false, nil, , , , , )
end

function ActivityChristmasExchange:onGetMsg(event)
	if not event then
		self:showDrawResult()

		return
	end

	local data = event.data
	local detail = json.decode(data.detail)

	if detail.num and detail.items then
		self:updateResGroup()
		self:updateRedPoint()
		self:updateBtnExchangeGroup()

		return
	end

	self:updateCardGroup()
	self:updateBtnExchangeGroup()
	self:updateResGroup()
	self:updateRedPoint()
end

function ActivityChristmasExchange:dispose()
	self.activityData:clearData()
	ActivityChristmasExchange.super.dispose(self)
end

return ActivityChristmasExchange
