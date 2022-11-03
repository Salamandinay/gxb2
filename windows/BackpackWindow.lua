local ItemIcon = import("app.components.ItemIcon")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local BackpackItem = class("BackpackItem")
local SoulEquip1 = import("app.models.SoulEquip1")
local SoulEquip2 = import("app.models.SoulEquip2")
local ItemTable = xyd.tables.itemTable
local EquipTable = xyd.tables.equipTable
local PartnerTable = xyd.tables.partnerTable
local SummonTable = xyd.tables.summonTable
local Slot = xyd.models.slot

function BackpackItem:ctor(go, backpackWindow)
	self.go = go
	self.selfNum = 0
	self.curID = 0
	self.backpackWindow = backpackWindow
	self.progress = go:ComponentByName("progress", typeof(UIProgressBar))
	self.progressSp = self.progress:ComponentByName("thumb", typeof(UISprite))
	self.progressLabel = self.progress:ComponentByName("label", typeof(UILabel))
end

function BackpackItem:iconNew(state)
	if state == "item" then
		self.itemIcon = ItemIcon.new(self.go:NodeByName("item").gameObject)

		self.itemIcon:setDragScrollView(self.backpackWindow.scrollView)
	elseif state == "hero" then
		self.heroIcon = HeroIcon.new(self.go:NodeByName("item").gameObject)

		self.heroIcon:setDragScrollView(self.backpackWindow.scrollView)
	end
end

function BackpackItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	if self.curID == info.itemID and self.selfNum == info.itemNum and not info.soulEquipID then
		return
	end

	self.data = info
	self.itemIndex = index
	local itemID = self.data.itemID
	local itemNum = self.data.itemNum
	self.selfNum = itemNum
	self.curID = itemID
	local type_ = ItemTable:getType(itemID)

	if type_ == xyd.ItemType.ARTIFACT_DEBRIS or type_ == xyd.ItemType.DRESS_DEBRIS then
		self.progress:SetActive(true)

		local partnerCost = ItemTable:partnerCost(itemID)

		if type_ == xyd.ItemType.ARTIFACT_DEBRIS or type_ == xyd.ItemType.DRESS_DEBRIS then
			if self.itemIcon == nil then
				self:iconNew("item")
			end

			self.itemIcon:SetActive(true)

			if self.heroIcon ~= nil then
				self.heroIcon:SetActive(false)
			end

			if type_ == xyd.ItemType.ARTIFACT_DEBRIS then
				partnerCost = ItemTable:treasureCost(itemID)
			elseif type_ == xyd.ItemType.DRESS_DEBRIS then
				local dress_summon_id = xyd.tables.itemTable:getSummonID(itemID)
				partnerCost = xyd.tables.summonDressTable:getCost(dress_summon_id)
			end

			self.itemIcon:setInfo({
				itemID = itemID,
				num = itemNum,
				itemNum = itemNum,
				wndType = xyd.ItemTipsWndType.BACKPACK
			})
			self.itemIcon:setNum()
		else
			if self.heroIcon == nil then
				self:iconNew("hero")
			end

			if self.itemIcon ~= nil then
				self.itemIcon:SetActive(false)
			end

			self.heroIcon:SetActive(true)
			self.heroIcon:setInfo({
				show_has_num = true,
				itemID = itemID,
				itemNum = itemNum,
				wndType = xyd.ItemTipsWndType.BACKPACK
			})
		end

		local str = itemNum .. "/" .. partnerCost[2]
		self.progressLabel.text = str
		self.progress.value = math.min(itemNum / partnerCost[2], 1)

		if partnerCost[2] <= itemNum then
			xyd.setUISprite(self.progressSp, xyd.Atlas.COMMON_UI, "bp_bar_green")
		else
			xyd.setUISprite(self.progressSp, xyd.Atlas.COMMON_UI, "bp_bar_blue_png")
		end

		if xyd.isIosTest() then
			xyd.setUISprite(self.progressSp, nil, self.progressSp.spriteName .. "_ios_test")
			xyd.setUISprite(self.progress:ComponentByName("bg", typeof(UISprite)), nil, "bp_bar_bg_ios_test")
		end
	else
		if self.itemIcon == nil then
			self:iconNew("item")
		end

		self.progress:SetActive(false)
		self.itemIcon:SetActive(true)

		if self.heroIcon ~= nil then
			self.heroIcon:SetActive(false)
		end

		local notShowGetWayBtn = nil

		if itemID == xyd.ItemID.LUCKYBOXES_COIN then
			notShowGetWayBtn = true
		end

		local param = {
			itemID = itemID,
			num = itemNum,
			wndType = xyd.ItemTipsWndType.BACKPACK,
			notShowGetWayBtn = notShowGetWayBtn
		}

		if type_ == xyd.ItemType.SOUL_EQUIP1 or type_ == xyd.ItemType.SOUL_EQUIP2_POS1 or type_ == xyd.ItemType.SOUL_EQUIP2_POS2 or type_ == xyd.ItemType.SOUL_EQUIP2_POS3 or type_ == xyd.ItemType.SOUL_EQUIP2_POS4 then
			param.soulEquipInfo = self.data:getSoulEquipInfo()
			local equipID1 = param.soulEquipInfo.soulEquipID
			local equip1 = xyd.models.slot:getSoulEquip(equipID1)

			if equip1 then
				local partnerID1 = equip1:getOwnerPartnerID()

				if partnerID1 and partnerID1 > 0 and xyd.models.slot:getPartner(partnerID1) then
					param.partner_id = partnerID1
				end
			end

			function param.callback()
				local params1 = {
					itemNum = 1,
					hideText = true,
					show_has_num = false,
					itemID = itemID,
					soulEquipInfo = param.soulEquipInfo,
					wndType = xyd.ItemTipsWndType.BACKPACK,
					notShowGetWayBtn = notShowGetWayBtn,
					upArrowCallback = function ()
						local equipID = param.soulEquipInfo.soulEquipID
						local itemType = xyd.tables.itemTable:getType(itemID)

						if itemType == xyd.ItemType.SOUL_EQUIP1 then
							xyd.openWindow("soul_equip1_strengthen_window", {
								equipID = equipID
							})
						else
							xyd.openWindow("soul_equip2_strengthen_window", {
								equipID = equipID
							})
						end

						xyd.WindowManager:get():closeWindow("item_tips_window")
					end
				}

				function params1.lockClickCallBack()
					local equipID = param.soulEquipInfo.soulEquipID
					local equip = xyd.models.slot:getSoulEquip(equipID)

					if equip then
						local lockFlag = equip:getIsLock()
						local lock = 1

						if lockFlag then
							lock = 0
						end

						xyd.models.slot:reqLockSoulEquip(equip:getSoulEquipID(), lock, function ()
							equip:setLock(lock)

							local win = xyd.getWindow("item_tips_window")

							if win and win.diffItemTips then
								win.diffItemTips:setBtnLockState(equip:getIsLock())
							elseif win and win.itemTips_ then
								win.itemTips_:setBtnLockState(equip:getIsLock())
							end
						end)
					end
				end

				function params1.lockStateCallBack()
					local equipID = param.soulEquipInfo.soulEquipID
					local equip = xyd.models.slot:getSoulEquip(equipID)

					if equip then
						return equip:getIsLock()
					else
						return false
					end
				end

				local equipID = param.soulEquipInfo.soulEquipID
				local equip = xyd.models.slot:getSoulEquip(equipID)

				if equip then
					local partnerID = equip:getOwnerPartnerID()

					if partnerID and partnerID > 0 and xyd.models.slot:getPartner(partnerID) then
						params1.equipedOn = xyd.models.slot:getPartner(partnerID)
					end
				end

				xyd.WindowManager.get():openWindow("item_tips_window", params1)
			end
		end

		self.itemIcon:setInfo(param)
	end

	self.name = "backpack_item_" .. self.itemIndex
end

function BackpackItem:setOrder(order)
	self.order_ = order
end

function BackpackItem:getOrder(order)
	return self.order_
end

function BackpackItem:onClickIcon()
	self:setSelected(true)

	local function callback(self)
		self:setSelected(false)
	end

	local params = {
		itemID = self.data.itemID,
		itemNum = self.data.itemNum,
		callback = handler(self, callback)
	}

	xyd.WindowManager.get().openWindow("item_tips_window", params)
end

function BackpackItem:getGameObject()
	return self.go
end

local BackpackWindow = class("BackpackWindow", import(".BaseWindow"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local WindowTop = import("app.components.WindowTop")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local TabName = {
	"EQUIP",
	"ITEM",
	"CONSUMABLES",
	"ARTIFACT"
}
local TabName2 = {
	"NO_EQUIP",
	"NO_ITEM",
	"NO_CONSUMABLES",
	"NO_ARTIFACT",
	nil,
	"NO_CONSUMABLES",
	"NO_SOULEQUIP"
}

function BackpackWindow:ctor(name, params)
	BackpackWindow.super.ctor(self, name, params)

	self.showBagType = xyd.BackpackShowType.EQUIP
	self.showQuality = xyd.QualityColor.ALL

	if params.type then
		self.showBagType = params.type
	end

	self.items_ = {}
	self.collectionBefore = Slot:getCollectionCopy()
	self.is_EQUIP_first_data = true
	self.is_ITEM_first_data = true
	self.is_ARTIFACT_first_data = true
	self.is_DEBRIS_first_data = true
	self.is_CONSUMABLES_first_data = true
	self.is_soulequip_first_data = true
	self.sortType = 0
	self.sortType2 = 0
end

function BackpackWindow:initWindow()
	BackpackWindow.super.initWindow(self)
	self:getUIComponent()
	self:initData()
	self:initUIComponent()
	self:initTopGroup()
	self:registerEvent()
	self.tab:setTabActive(self.showBagType, true)
end

function BackpackWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function BackpackWindow:registerEvent()
	local tabNums = 5
	self.tab = CommonTabBar.new(self.nav, tabNums, function (index)
		local helpArr = {
			xyd.BackpackShowType.EQUIP,
			xyd.BackpackShowType.ITEM,
			xyd.BackpackShowType.CONSUMABLES,
			xyd.BackpackShowType.ARTIFACT,
			xyd.BackpackShowType.SOUL_EUQIP
		}

		self:onTabTouch(helpArr[index])
	end)

	for i = 1, tabNums do
		local label = self.nav:ComponentByName("tab_" .. i .. "/label", typeof(UILabel))

		if xyd.Global.lang == "de_de" then
			label.fontSize = 18
		elseif xyd.Global.lang == "en_en" then
			label.fontSize = 20
		end
	end

	self.tab:setTexts({
		__("EQUIP"),
		__("ITEM"),
		__("CONSUMABLES"),
		__("ARTIFACT"),
		__("SOULEQUIP")
	})

	for k = 1, 7 do
		UIEventListener.Get(self["btnCircle" .. k]).onClick = function ()
			self:onQualityBtn(k)
		end
	end

	xyd.setDarkenBtnBehavior(self.btnSmith_, self, self.onSmithyTouch)
	xyd.setDarkenBtnBehavior(self.btnArtifactList_, self, self.onArtifactListTouch)
	xyd.setDarkenBtnBehavior(self.btnSort_, self, self.onSortTouch)
	xyd.setDarkenBtnBehavior(self.btnSort2_, self, function ()
		self:onSortTouch(xyd.BackpackShowType.CONSUMABLES)
	end)
	self.eventProxy_:addEventListener(xyd.event.SUMMON, handler(self, self.summonCallback))
	self.eventProxy_:addEventListener(xyd.event.SUMMON_WISH, handler(self, self.summonCallback))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
	self.eventProxy_:addEventListener(xyd.event.SELL_ITEM, handler(self, self.sellCallback))
	self.eventProxy_:addEventListener(xyd.event.USE_OPTIONAL_GIFTBOX, handler(self, self.onUseOptionalGiftBox))
	self.eventProxy_:addEventListener(xyd.event.GET_NEW_SOUL_EQUIP_PUSH_BACK, handler(self, self.oGetNewSoulEquipPushBack))
end

function BackpackWindow:getUIComponent()
	local go = self.window_
	self.groupMain = go:NodeByName("groupMain").gameObject
	self.bottomBtns_ = go:NodeByName("groupMain/bottomBtns_").gameObject
	self.groupNone_ = go:NodeByName("groupMain/groupNone_").gameObject
	self.labelNoneTips_ = go:ComponentByName("groupMain/groupNone_/labelNoneTips_", typeof(UILabel))
	self.imgTab3Red_ = go:ComponentByName("groupMain/top/imgTab3Red_", typeof(UISprite))
	self.imgTab3Red2_ = go:ComponentByName("groupMain/top/imgTab3Red2_", typeof(UISprite))
	local btnCircles = self.bottomBtns_:NodeByName("btnCircles").gameObject

	for i = 1, 7 do
		self["btnCircle" .. i] = btnCircles:NodeByName("btnCircle" .. i).gameObject
	end

	self.btnSmith_ = self.bottomBtns_:NodeByName("btnSmith_").gameObject
	self.btnArtifactList_ = self.bottomBtns_:NodeByName("btnArtifactList_").gameObject
	self.labelSmith_ = self.bottomBtns_:ComponentByName("btnSmith_/button_label", typeof(UILabel))
	self.numLimitShow = self.bottomBtns_:ComponentByName("numLimitShow", typeof(UILabel))
	self.labelArtifactList_ = self.bottomBtns_:ComponentByName("btnArtifactList_/button_label", typeof(UILabel))
	self.btnSortGroup_ = self.bottomBtns_:NodeByName("btnSortGroup_").gameObject
	self.btnSort_ = self.btnSortGroup_:NodeByName("btnSort_").gameObject
	self.btnSortLabel_ = self.btnSort_:ComponentByName("button_label", typeof(UILabel))
	self.chooseGroup = self.btnSortGroup_:NodeByName("chooseGroup").gameObject

	for i = 0, 3 do
		self["sort" .. tostring(i)] = self.chooseGroup:NodeByName("sort" .. i).gameObject
	end

	self.btnSortGroup2_ = self.bottomBtns_:NodeByName("btnSortGroup2_").gameObject
	self.btnSort2_ = self.btnSortGroup2_:NodeByName("btnSort_").gameObject
	self.btnSortLabel2_ = self.btnSort2_:ComponentByName("button_label", typeof(UILabel))
	self.chooseGroup2 = self.btnSortGroup2_:NodeByName("chooseGroup").gameObject

	for i = 0, 6 do
		self["sortConsumables" .. tostring(i)] = self.chooseGroup2:NodeByName("sort" .. i).gameObject
	end

	self.btnQualityChosen = btnCircles:NodeByName("btnQualityChosen").gameObject
	self.nav = go:NodeByName("groupMain/top/nav").gameObject
	self.scrollView = go:ComponentByName("groupMain/scroll_view", typeof(UIScrollView))
	self.scrollPanel = go:ComponentByName("groupMain/scroll_view", typeof(UIPanel))
	self.wrapContent = go:ComponentByName("groupMain/scroll_view/wrap_content", typeof(UIWrapContent))
	local itemCell = go:NodeByName("item").gameObject
	self.wrapContent_ = FixedMultiWrapContent.new(self.scrollView, self.wrapContent, itemCell, BackpackItem, self)
end

function BackpackWindow:initUIComponent()
	self.labelNoneTips_.text = __(TabName2[self.showBagType])
	self.labelSmith_.text = __("COMPOSE_EQUIP")
	self.labelArtifactList_.text = __("ARTIFACT_LIST")
	self.btnSortLabel_.text = __("ALTAR_FILTER_TEXT")

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" then
		self.btnSortLabel_.transform:X(-10)
	end

	self.btnSortLabel2_.text = __("ALTAR_FILTER_TEXT")

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" then
		self.btnSortLabel2_.transform:X(-10)
	end

	self:initQuality()
	self:initSortBtn()
end

function BackpackWindow:onTabTouch(i, isUpdate)
	self:dataCheck(i)

	self.showBagType = i

	self.wrapContent_:setItemSize(132)
	xyd.SoundManager.get():playSound(xyd.SoundID.TAB)

	local showBgTabNum = self.showQuality
	local infos = self:getInfos()

	self.wrapContent_:setInfos(infos, {
		keepPosition = isUpdate
	})
	self.numLimitShow.gameObject:SetActive(false)

	if self.showBagType == xyd.BackpackShowType.EQUIP then
		self.btnSmith_:SetActive(true)
		self.btnArtifactList_:SetActive(false)
		self.btnSortGroup_:SetActive(false)
		self.btnSortGroup2_:SetActive(false)
		self.bottomBtns_:SetActive(true)
		self.scrollPanel:SetBottomAnchor(self.window_, 0, 223)
	elseif self.showBagType == xyd.BackpackShowType.ARTIFACT then
		self.btnSmith_:SetActive(false)
		self.btnArtifactList_:SetActive(true)
		self.btnSortGroup_:SetActive(false)
		self.btnSortGroup2_:SetActive(false)
		self.bottomBtns_:SetActive(true)
		self.scrollPanel:SetBottomAnchor(self.window_, 0, 223)
	elseif self.showBagType == xyd.BackpackShowType.ITEM then
		self.btnSmith_:SetActive(false)
		self.btnArtifactList_:SetActive(false)
		self.bottomBtns_:SetActive(true)
		self.btnSortGroup_:SetActive(true)
		self.btnSortGroup2_:SetActive(false)
		self.scrollPanel:SetBottomAnchor(self.window_, 0, 223)

		local alertTime = xyd.db.misc:getValue("backpack_over_item_alert")
		local overItem = xyd.models.backpack:checkOverItem()

		if overItem and (not alertTime or not xyd.isSameDay(alertTime, xyd.getServerTime())) then
			self.imgTab3Red2_:SetActive(false)

			local itemList = xyd.models.backpack:getOverItems()

			for i = 1, #itemList do
				self:waitForTime(0.1 + 2 * (i - 1), function ()
					xyd.alertTips(__("BAG_NUM_LIMIT_TEXT2", xyd.tables.itemTable:getName(itemList[i])), nil, , , , , , , , , 2)
				end)
			end

			xyd.db.misc:setValue({
				key = "backpack_over_item_alert",
				value = xyd.getServerTime()
			})
		end
	elseif self.showBagType == xyd.BackpackShowType.CONSUMABLES then
		self.btnSmith_:SetActive(false)
		self.btnArtifactList_:SetActive(false)
		self.bottomBtns_:SetActive(true)
		self.btnSortGroup_:SetActive(false)
		self.btnSortGroup2_:SetActive(true)
		self.scrollPanel:SetBottomAnchor(self.window_, 0, 223)
	elseif self.showBagType == xyd.BackpackShowType.SOUL_EUQIP then
		self.btnSmith_:SetActive(false)
		self.btnArtifactList_:SetActive(false)
		self.btnSortGroup_:SetActive(false)
		self.btnSortGroup2_:SetActive(false)
		self.bottomBtns_:SetActive(true)
		self.scrollPanel:SetBottomAnchor(self.window_, 0, 223)
		self.numLimitShow.gameObject:SetActive(true)

		self.numLimitShow.text = xyd.models.slot:getSoulEquipLength() .. "/" .. xyd.tables.miscTable:getNumber("soul_equip_limit", "value")
	else
		self.btnSmith_:SetActive(false)
		self.btnArtifactList_:SetActive(false)
		self.btnSortGroup_:SetActive(false)
		self.btnSortGroup2_:SetActive(false)
		self.bottomBtns_:SetActive(false)
		self.scrollPanel:SetBottomAnchor(self.window_, 0, 126)

		showBgTabNum = 0
	end

	self.labelNoneTips_.text = __(TabName2[self.showBagType])

	if self.showBagType == xyd.BackpackShowType.SOUL_EQUIP then
		self.groupNone_:SetActive(xyd.models.slot:getSoulEquipLength() == 0)
	else
		self.groupNone_:SetActive(#self.items_[self.showBagType][showBgTabNum] == 0)
	end
end

function BackpackWindow:onQualityBtn(i)
	if self.showQuality == 0 then
		self.btnQualityChosen:SetActive(true)

		local pos = self["btnCircle" .. i].transform.localPosition

		self.btnQualityChosen:SetLocalPosition(pos.x, pos.y, pos.z)

		self.showQuality = i
	elseif self.showQuality ~= i then
		local pos = self["btnCircle" .. i].transform.localPosition

		self.btnQualityChosen:SetLocalPosition(pos.x, pos.y, pos.z)

		self.showQuality = i
	elseif self.showQuality == i then
		self.btnQualityChosen:SetActive(false)

		self.showQuality = 0
	end

	self.labelNoneTips_.text = __(TabName2[self.showBagType])

	self.groupNone_:SetActive(#self.items_[self.showBagType][self.showQuality] == 0)

	local infos = self:getInfos()

	self.wrapContent_:setInfos(infos, {})
end

function BackpackWindow:initQuality()
	if self.showQuality == 0 then
		self.btnQualityChosen:SetActive(false)
	else
		local pos = self["btnCircle" .. self.showQuality].transform.localPosition

		self.btnQualityChosen:SetLocalPosition(pos.x, pos.y, pos.z)
		self.btnQualityChosen:SetActive(true)
	end
end

function BackpackWindow:playOpenAnimation(callback)
	callback()
	self.groupMain:X(-1000)
	self.groupMain:SetActive(true)

	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:AppendInterval(0.2)
	sequence:Append(self.groupMain.transform:DOLocalMoveX(50, 0.3))
	sequence:Append(self.groupMain.transform:DOLocalMoveX(0, 0.27))
	sequence:AppendCallback(function ()
		sequence:Kill(true)
		self:setWndComplete()
	end)

	self.windowTween_ = sequence
end

function BackpackWindow:initData(index)
	if index == nil then
		for i = 0, 7 do
			self.items_[i] = {}

			for j = 0, 7 do
				self.items_[i][j] = {}
			end
		end
	else
		self.items_[index] = {}

		for j = 0, 7 do
			self.items_[index][j] = {}
		end
	end

	if not xyd.checkRedMarkSetting(xyd.RedMarkType.BACKPACK) then
		self.imgTab3Red_:SetActive(false)
	else
		local canCompose = xyd.models.backpack:checkCanCompose(xyd.BackpackShowType.CONSUMABLES)

		self.imgTab3Red_:SetActive(canCompose)
	end

	local alertTime = xyd.db.misc:getValue("backpack_over_item_alert")
	local overItem = xyd.models.backpack:checkOverItem()

	if overItem and (not alertTime or not xyd.isSameDay(alertTime, xyd.getServerTime())) then
		self.imgTab3Red2_:SetActive(true)
	end

	if index == nil then
		self:dataCheck(xyd.BackpackShowType.EQUIP)
	else
		self:dataCheck(index)
	end
end

function BackpackWindow:dataCheck(index)
	local isretun = true
	local tmpDatas = xyd.models.backpack:getItems_withBagType(index)

	if self.is_EQUIP_first_data == true and index == xyd.BackpackShowType.EQUIP then
		self:sortEquip(tmpDatas or {})

		isretun = false
		self.is_EQUIP_first_data = false
	elseif self.is_ITEM_first_data == true and index == xyd.BackpackShowType.ITEM then
		self:sortItem(tmpDatas or {})

		isretun = false
		self.is_ITEM_first_data = false
	elseif self.is_ARTIFACT_first_data == true and index == xyd.BackpackShowType.ARTIFACT then
		self:sortArtifact(tmpDatas or {})

		isretun = false
		self.is_ARTIFACT_first_data = false
	elseif self.is_CONSUMABLES_first_data == true and index == xyd.BackpackShowType.CONSUMABLES then
		self:sortConsumables(tmpDatas or {})

		isretun = false
		self.is_CONSUMABLES_first_data = false
	elseif self.is_soulequip_first_data == true and index == xyd.BackpackShowType.SOUL_EUQIP then
		tmpDatas = {}
		local data = xyd.models.slot:getAllSoulEquip()

		for key, value in pairs(data) do
			tmpDatas[key] = value
		end

		self:sortSoulEquip(tmpDatas or {})

		isretun = false
		self.is_soulequip_first_data = false
	end

	if isretun then
		return
	end

	if index == xyd.BackpackShowType.SOUL_EUQIP then
		self.items_[index] = {}

		for j = 0, 7 do
			self.items_[index][j] = {}
		end

		for j, _ in pairs(tmpDatas) do
			local item = tmpDatas[j]

			if item then
				local quality = item.qlt
				item.itemID = item.tableID

				if quality == nil then
					quality = ItemTable:getQuality(item.tableID)
				end

				table.insert(self.items_[index][quality], item)
				table.insert(self.items_[index][0], item)
			end
		end
	else
		for j, _ in pairs(tmpDatas) do
			local item = tmpDatas[j]

			if item then
				local quality = ItemTable:getQuality(item.itemID)

				table.insert(self.items_[index][quality], item)
				table.insert(self.items_[index][0], item)
			end
		end
	end
end

function BackpackWindow:getInfos()
	local quality = xyd.QualityColor.ALL

	if self.showBagType == xyd.BackpackShowType.EQUIP or self.showBagType == xyd.BackpackShowType.ARTIFACT or self.showBagType == xyd.BackpackShowType.ITEM or self.showBagType == xyd.BackpackShowType.CONSUMABLES or self.showBagType == xyd.BackpackShowType.SOUL_EUQIP then
		quality = self.showQuality
	end

	local items = self.items_[self.showBagType]

	if self.showBagType == xyd.BackpackShowType.ITEM and self.sortType and self.sortType > 0 then
		local filterItems = {}

		for _, item in ipairs(items[quality]) do
			if xyd.tables.itemTable:getFilterType(item.itemID) == self.sortType then
				table.insert(filterItems, item)
			end
		end

		return filterItems
	elseif self.showBagType == xyd.BackpackShowType.CONSUMABLES and self.sortType2 and self.sortType2 > 0 then
		local filterItems = {}

		for _, item in ipairs(items[quality]) do
			if xyd.tables.itemTable:getFilterType(item.itemID) == self.sortType2 then
				table.insert(filterItems, item)
			end
		end

		return filterItems
	end

	return items[quality]
end

function BackpackWindow:summonCallback(event)
	local items = event.data.summon_result.items
	local partners = event.data.summon_result.partners
	local prophet_window = xyd.WindowManager.get():getWindow("prophet_window")

	if tonumber(event.data.summon_id) == 10 or tonumber(event.data.summon_id) == 17 then
		return
	elseif prophet_window then
		return
	end

	local params = {}
	local flag = false
	local itemID_ = 0
	local callback = nil
	local hasFive = false

	local function checkMore(itemID)
		if itemID_ ~= 0 and itemID_ ~= itemID then
			flag = true
		else
			itemID_ = itemID
		end
	end

	if #items > 0 then
		for i in ipairs(items) do
			table.insert(params, items[i])
			checkMore(items[i].item_id)
		end
	end

	local new5stars = {}

	if #partners > 0 then
		new5stars = self:isHasNew(event)

		for i in ipairs(partners) do
			local star = xyd.tables.partnerTable:getStar(partners[i].table_id) + partners[i].awake

			table.insert(params, {
				item_num = 1,
				item_id = partners[i].table_id,
				star = star
			})
			checkMore(partners[i].table_id)

			if not hasFive then
				local star = PartnerTable:getStar(partners[i].table_id)

				if star >= 5 then
					hasFive = true
				end
			end
		end
	end

	local effectCallBack = nil

	function effectCallBack()
		xyd.WindowManager:get():closeWindow("summon_res_window")

		self.collectionBefore = Slot:getCollectionCopy()

		if flag then
			xyd.WindowManager.get():openWindow("alert_heros_window", {
				data = params,
				callback = callback
			})
		else
			xyd.alertItems(params, callback, __("SUMMON"))
		end

		if hasFive then
			print("评分引导监听")

			local evaluate_have_closed = xyd.db.misc:getValue("evaluate_have_closed") or false
			local lastTime = xyd.db.misc:getValue("evaluate_last_time") or 0

			print(evaluate_have_closed)
			print(not evaluate_have_closed and lastTime)
			print(not evaluate_have_closed and lastTime and xyd.getServerTime() - lastTime > 3 * xyd.DAY_TIME)

			if not evaluate_have_closed and lastTime and xyd.getServerTime() - lastTime > 3 * xyd.DAY_TIME then
				local win = xyd.getWindow("main_window")

				print("评分引导监听成功")
				win:setHasEvaluateWindow(true, xyd.EvaluateFromType.COMPOSE)
			end
		end
	end

	if #new5stars > 0 then
		xyd.onGetNewPartnersOrSkins({
			partners = new5stars,
			callback = effectCallBack
		})
	else
		effectCallBack()
	end
end

function BackpackWindow:sellCallback(event)
	local items = event.data.items

	if #items > 0 then
		xyd.alertItems(items)
	end
end

function BackpackWindow:onUseOptionalGiftBox(event)
	if event.data ~= nil then
		local item = {
			event.data
		}
		local itemData = xyd.decodeProtoBuf(event.data)

		if itemData.item_id and xyd.tables.itemTable:getType(itemData.item_id) == xyd.ItemType.SKIN then
			xyd.onGetNewPartnersOrSkins({
				destory_res = false,
				skins = {
					tonumber(itemData.item_id)
				},
				callback = function ()
					xyd.alertItems(item)
				end
			})
		elseif itemData.item_id then
			if xyd.tables.itemTable:getType(itemData.item_id) ~= xyd.ItemType.SOUL_EQUIP1 and xyd.tables.itemTable:getType(itemData.item_id) ~= xyd.ItemType.SOUL_EQUIP2_POS1 and xyd.tables.itemTable:getType(itemData.item_id) ~= xyd.ItemType.SOUL_EQUIP2_POS2 and xyd.tables.itemTable:getType(itemData.item_id) ~= xyd.ItemType.SOUL_EQUIP2_POS3 then
				if xyd.tables.itemTable:getType(itemData.item_id) == xyd.ItemType.SOUL_EQUIP2_POS4 then
					-- Nothing
				end
			end
		else
			xyd.alertItems(item)
		end
	end
end

function BackpackWindow:oGetNewSoulEquipPushBack(event)
	self.is_soulequip_first_data = true

	if not self.haveReqOpen then
		return
	end

	self.haveReqOpen = false
	local data = xyd.decodeProtoBuf(event.data)
	local items = {}

	for key, info in pairs(data.items) do
		if info and info.equip_id then
			local itemType = xyd.tables.itemTable:getType(info.table_id)
			local equip = nil

			if itemType == xyd.ItemType.SOUL_EQUIP1 then
				equip = SoulEquip1.new()
			else
				equip = SoulEquip2.new()
			end

			info.ownerID = info.pos

			equip:populate(info)
			table.insert(items, {
				item_num = 1,
				item_id = equip:getTableID(),
				soulEquipInfo = equip:getSoulEquipInfo()
			})
		end
	end

	if #items > 0 then
		local params = {
			items = items
		}

		xyd.WindowManager.get():openWindow("alert_item_window", params)
	end
end

function BackpackWindow:onItemChange(event)
	local items = event.data.items
	local flags = {
		[xyd.BackpackShowType.EQUIP] = false,
		[xyd.BackpackShowType.ITEM] = false,
		[xyd.BackpackShowType.ARTIFACT] = false,
		[xyd.BackpackShowType.CONSUMABLES] = false
	}

	for i = 1, #items do
		local item = items[i]
		local item_id = item.item_id
		local type = ItemTable:showInBagType(item_id)
		flags[type] = true
	end

	flags[self.showBagType] = true

	for type, flagValue in pairs(flags) do
		if flagValue then
			if type == xyd.BackpackShowType.EQUIP then
				self.is_EQUIP_first_data = true
			elseif type == xyd.BackpackShowType.ITEM then
				self.is_ITEM_first_data = true
			elseif type == xyd.BackpackShowType.ARTIFACT then
				self.is_ARTIFACT_first_data = true
			elseif type == xyd.BackpackShowType.CONSUMABLES then
				self.is_CONSUMABLES_first_data = true
			end

			self:initData(type)
		end
	end

	self:updateShow()
end

function BackpackWindow:sortEquip(data)
	table.sort(data, function (a, b)
		local aLev = EquipTable:getItemLev(a.itemID)
		local bLev = EquipTable:getItemLev(b.itemID)

		if bLev < aLev then
			return true
		elseif aLev == bLev then
			local aPos = EquipTable:getPos(a.itemID)
			local bPos = EquipTable:getPos(b.itemID)

			return aPos < bPos
		else
			return false
		end
	end)
end

function BackpackWindow:sortItem(data)
	table.sort(data, function (a, b)
		if a == nil or b == nil then
			return false
		end

		local aQlt = ItemTable:getQuality(a.itemID)
		local bQlt = ItemTable:getQuality(b.itemID)

		if bQlt < aQlt then
			return true
		elseif aQlt == bQlt and b.itemID < a.itemID then
			return true
		else
			return false
		end
	end)
end

function BackpackWindow:sortArtifact(data)
	table.sort(data, function (a, b)
		local aLev = EquipTable:getItemLev(a.itemID)
		local bLev = EquipTable:getItemLev(b.itemID)

		if bLev < aLev then
			return true
		elseif aLev == bLev and b.itemID < a.itemID then
			return true
		else
			return false
		end
	end)
end

function BackpackWindow:sortConsumables(data)
	table.sort(data, function (a, b)
		if a == nil or b == nil then
			return false
		end

		local aSortForward = ItemTable:getSortForward(a.itemID)
		local bSortForward = ItemTable:getSortForward(b.itemID)

		if aSortForward == 0 then
			aSortForward = 99999
		end

		if bSortForward == 0 then
			bSortForward = 99999
		end

		if aSortForward ~= bSortForward then
			return aSortForward < bSortForward
		else
			local aQlt = ItemTable:getQuality(a.itemID)
			local bQlt = ItemTable:getQuality(b.itemID)

			if bQlt < aQlt then
				return true
			elseif aQlt == bQlt and b.itemID < a.itemID then
				return true
			else
				return false
			end
		end
	end)
end

function BackpackWindow:sortSoulEquip(data)
	table.sort(data, function (a, b)
		if a == nil or b == nil then
			return false
		end

		return a.tableID < b.tableID
	end)
end

function BackpackWindow:willCloseAnimation(callback)
	if self.windowTween_ then
		self.windowTween_:Kill(true)

		self.windowTween_ = nil
	end

	local sequence = self:getSequence()

	sequence:Append(self.groupMain.transform:DOLocalMoveX(50, 0.14))
	sequence:Append(self.groupMain.transform:DOLocalMoveX(-1000, 0.15))
	sequence:AppendCallback(function ()
		sequence:Kill(true)

		if callback then
			callback()
		end
	end)
end

function BackpackWindow:excuteCallBack(isCloseAll)
end

function BackpackWindow:onSmithyTouch()
	xyd.WindowManager.get():openWindow("smithy_window")
end

function BackpackWindow:onArtifactListTouch()
	local wnd = xyd.WindowManager.get():getWindow("main_window")

	wnd:onBottomBtnValueChange(6, true, true)
	xyd.models.collection:reqCollectionInfo()
	xyd.WindowManager.get():openWindow("collection_soul_window")
end

function BackpackWindow:initSortBtn()
	local ItemFilterTypeTextTable = xyd.tables.itemFilterTypeTextTable

	for i = 0, 3 do
		local sortBtn = self["sort" .. i]
		sortBtn:ComponentByName("label", typeof(UILabel)).text = ItemFilterTypeTextTable:getDesc(i) or __("HOUSE_TEXT_13")

		UIEventListener.Get(sortBtn).onClick = function ()
			self:onSortSelectTouch(i)
		end
	end

	local consomablesFilterTypeTextTable = xyd.tables.itemFilterTypeTextTable

	for i = 0, 6 do
		local sortBtn = self["sortConsumables" .. i]

		if i > 0 then
			sortBtn:ComponentByName("label", typeof(UILabel)).text = ItemFilterTypeTextTable:getDesc(i + 4) or __("HOUSE_TEXT_13")
		else
			sortBtn:ComponentByName("label", typeof(UILabel)).text = __("HOUSE_TEXT_13")
		end

		UIEventListener.Get(sortBtn).onClick = function ()
			self:onSortSelectTouch(i, xyd.BackpackShowType.CONSUMABLES)
		end
	end
end

function BackpackWindow:onSortSelectTouch(index, type)
	if type and type == xyd.BackpackShowType.CONSUMABLES then
		if self.sortType2 ~= index then
			self.sortType2 = index

			self:updateSortChosen(type)
			self:onSortTouch(type)

			local infos = self:getInfos()

			self.wrapContent_:setInfos(infos, {})
		end
	elseif self.sortType ~= index then
		self.sortType = index

		self:updateSortChosen()
		self:onSortTouch()

		local infos = self:getInfos()

		self.wrapContent_:setInfos(infos, {})
	end
end

function BackpackWindow:onSortTouch(type)
	if type and type == xyd.BackpackShowType.CONSUMABLES then
		self:updateSortChosen(type)

		local arrow = self.btnSort2_:NodeByName("arrow").gameObject
		local scale = arrow.transform.localScale

		arrow.transform:SetLocalScale(scale.x, -1 * scale.y, scale.z)

		arrow.transform.localEulerAngles = -arrow.transform.localEulerAngles

		self:moveGroupSort(type)
	else
		self:updateSortChosen()

		local arrow = self.btnSort_:NodeByName("arrow").gameObject
		local scale = arrow.transform.localScale

		arrow.transform:SetLocalScale(scale.x, -1 * scale.y, scale.z)

		arrow.transform.localEulerAngles = -arrow.transform.localEulerAngles

		self:moveGroupSort()
	end
end

function BackpackWindow:updateSortChosen(type)
	if type and type == xyd.BackpackShowType.CONSUMABLES then
		for i = 0, 6 do
			local sort = self["sortConsumables" .. tostring(i)]
			local btn = sort:GetComponent(typeof(UIButton))
			local label = sort:ComponentByName("label", typeof(UILabel))

			if i == self.sortType2 then
				btn:SetEnabled(false)

				label.color = Color.New2(4294967295.0)
				label.effectStyle = UILabel.Effect.Outline
				label.effectColor = Color.New2(1012112383)
			else
				btn:SetEnabled(true)

				label.color = Color.New2(960513791)
				label.effectStyle = UILabel.Effect.None
			end
		end
	else
		for i = 0, 3 do
			local sort = self["sort" .. tostring(i)]
			local btn = sort:GetComponent(typeof(UIButton))
			local label = sort:ComponentByName("label", typeof(UILabel))

			if i == self.sortType then
				btn:SetEnabled(false)

				label.color = Color.New2(4294967295.0)
				label.effectStyle = UILabel.Effect.Outline
				label.effectColor = Color.New2(1012112383)
			else
				btn:SetEnabled(true)

				label.color = Color.New2(960513791)
				label.effectStyle = UILabel.Effect.None
			end
		end
	end
end

function BackpackWindow:moveGroupSort(type)
	local w, transform = nil
	local action = DG.Tweening.DOTween.Sequence()
	local arrow, chooseGroup = nil

	if type and type == xyd.BackpackShowType.CONSUMABLES then
		w = self.chooseGroup2:GetComponent(typeof(UIWidget))
		transform = self.chooseGroup2.transform
		arrow = self.btnSort2_:NodeByName("arrow").gameObject
		chooseGroup = self.chooseGroup2
	else
		w = self.chooseGroup:GetComponent(typeof(UIWidget))
		transform = self.chooseGroup.transform
		arrow = self.btnSort_:NodeByName("arrow").gameObject
		chooseGroup = self.chooseGroup
	end

	local height = w.height
	local scaleY = arrow.transform.localScale.y

	if scaleY == 1 then
		action:Append(transform:DOLocalMove(Vector3(0, height + 17, 0), 0.067)):Append(transform:DOLocalMove(Vector3(0, height - 58, 0), 0.1)):Join(xyd.getTweenAlpha(w, 0.01, 0.1)):AppendCallback(function ()
			chooseGroup:SetActive(false)
			transform:SetLocalPosition(0, 0, 0)
		end)
	else
		chooseGroup:SetActive(true)

		w.alpha = 0.01

		transform:SetLocalPosition(0, height - 58, 0)
		action:Append(transform:DOLocalMove(Vector3(0, height + 17, 0), 0.1)):Join(xyd.getTweenAlpha(w, 1, 0.1)):Append(transform:DOLocalMove(Vector3(0, height, 0), 0.2))
	end
end

function BackpackWindow:updateShow()
	self:onTabTouch(self.showBagType, true)
	self:initQuality()
end

function BackpackWindow:isHasNew(event)
	local partners = event.data.summon_result.partners
	local new5stars = {}

	for i = 1, #partners do
		local np = Partner.new()

		np:populate(partners[i])

		if not self.collectionBefore[np:getTableID()] then
			table.insert(new5stars, np:getTableID())
		end
	end

	return new5stars
end

function BackpackWindow:getBackpackItemClass()
	return BackpackItem
end

function BackpackWindow:iosTestChangeUI()
	local winTrans = self.window_
	local iosBG = NGUITools.AddChild(winTrans, "iosBG"):AddComponent(typeof(UITexture))

	winTrans:NodeByName("bg1"):SetActive(false)
	winTrans:NodeByName("bg2"):SetActive(false)

	iosBG.height = winTrans:GetComponent(typeof(UIPanel)).height
	iosBG.width = winTrans:GetComponent(typeof(UIPanel)).width

	xyd.setUITexture(iosBG, "Textures/texture_ios/bg_ios_test")
	xyd.setUISprite(self.groupMain:ComponentByName("bg", typeof(UISprite)), nil, "9gongge19_ios_test")
	xyd.setUISprite(self.btnSmith_:GetComponent(typeof(UISprite)), nil, "blue_btn_65_65_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("groupMain/top/nav/tab_1/chosen", typeof(UISprite)), "nav_btn_blue_left_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("groupMain/top/nav/tab_1/unchosen", typeof(UISprite)), "nav_btn_white_left_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("groupMain/top/nav/tab_2/chosen", typeof(UISprite)), "nav_btn_blue_mid_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("groupMain/top/nav/tab_2/unchosen", typeof(UISprite)), "nav_btn_white_mid_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("groupMain/top/nav/tab_3/chosen", typeof(UISprite)), "nav_btn_blue_mid_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("groupMain/top/nav/tab_3/unchosen", typeof(UISprite)), "nav_btn_white_mid_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("groupMain/top/nav/tab_4/chosen", typeof(UISprite)), "nav_btn_blue_right_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("groupMain/top/nav/tab_4/unchosen", typeof(UISprite)), "nav_btn_white_right_ios_test")
end

return BackpackWindow
