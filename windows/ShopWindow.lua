local BaseShop = import(".BaseShop")
local ShopWindow = class("ShopWindow", BaseShop)
local MAXSLOT = 8
local CountDown = import("app.components.CountDown")
local backpackModel = xyd.models.backpack
local MarketItem = class("MarketItem")
local ShopTopBar = class("ShopTopBar", import("app.common.ui.CommonTabBar"))
local WindowTop = import("app.components.WindowTop")
local PlayerIcon = import("app.components.PlayerIcon")
local Destroy = UnityEngine.Object.Destroy
local OldSize = {
	w = 720,
	h = 1280
}
local cjson = require("cjson")
local girlImgConf = {
	54008,
	752009,
	34004,
	12001
}

function ShopTopBar:ctor(parentGo, selectInfos, parent)
	self.parent = parentGo
	self.father_ = parent
	self.infos_ = selectInfos
	self.nums = #self.infos_
	self.currentIndex = 1

	self:setCallback()
	self:initTabs()
end

function ShopTopBar:setCallback()
	function self.callback(index)
		local window = xyd.WindowManager.get():getWindow("shop_window")

		if window then
			window:updateByShopType(self.infos_[index])
		end
	end
end

function ShopTopBar:onValueChange(index)
	xyd.SoundManager.get():playSound(xyd.SoundID.TAB)

	local functionId = xyd.tables.shopConfigTable:getFunctionID(self.infos_[index])

	if not xyd.checkFunctionOpen(functionId) then
		return
	end

	if self.currentIndex ~= 0 then
		self.tabs[self.currentIndex].chosen:SetActive(false)

		self.tabs[self.currentIndex].box.enabled = true
	end

	self.tabs[index].chosen:SetActive(true)

	self.tabs[index].box.enabled = false

	ShopTopBar.super.onValueChange(self, index)

	if xyd.Global.lang == "fr_fr" then
		self.father_:checkFrFrBtnRefreshLabel()
	end
end

function ShopTopBar:initTabs()
	self.tabs = {}

	for i = 1, self.nums do
		local tab = self.parent:NodeByName("tab_" .. i).gameObject
		local label = tab:ComponentByName("label", typeof(UILabel))
		local chosen = tab:ComponentByName("chosen", typeof(UISprite)).gameObject
		local shopRed = tab:NodeByName("shopRed").gameObject

		shopRed:SetActive(false)

		local redMarkId = xyd.tables.shopConfigTable:getRedMarkId(self.infos_[i])

		if redMarkId > 0 then
			xyd.models.redMark:setJointMarkImg({
				redMarkId
			}, shopRed)
		end

		local box = tab:GetComponent(typeof(UnityEngine.BoxCollider))

		chosen:SetActive(self.infos_[i] == self.father_.shopType_)

		box.enabled = self.infos_[i] ~= self.father_.shopType_
		local costImg = tab:ComponentByName("image", typeof(UISprite))
		label.text = xyd.tables.shopConfigTable:getName(self.infos_[i])
		label.pivot = UIWidget.Pivot.Center

		if self.infos_[i] == self.father_.shopType_ then
			self.currentIndex = i
			label.color = self.labelStates.chosen.color
			label.effectColor = self.labelStates.chosen.effectColor
		else
			label.color = self.labelStates.unchosen.color
			label.effectColor = self.labelStates.unchosen.effectColor
		end

		if xyd.Global.lang ~= "zh_tw" then
			label.height = 34

			if xyd.Global.lang == "fr_fr" then
				label.fontSize = 14
			elseif xyd.Global.lang == "en_en" then
				label.fontSize = 16
			elseif xyd.Global.lang == "de_de" then
				label.fontSize = 15

				if i == 5 then
					label:X(16)
				end
			end
		end

		local imgName = xyd.tables.shopConfigTable:getIcon(self.infos_[i])

		xyd.setUISpriteAsync(costImg, nil, imgName)

		if xyd.Global.lang == "ja_jp" and i == 5 then
			costImg.transform.localPosition = Vector3(-42, 2, 0)
			label.transform.localPosition = Vector3(14, 2, 0)
		end

		self.tabs[i] = {
			tab = tab,
			label = label,
			img = costImg,
			chosen = chosen,
			box = box
		}

		UIEventListener.Get(tab).onClick = function ()
			self:onValueChange(i)
		end
	end
end

function MarketItem:ctor(go, parent)
	self.go_ = go
	self.parent_ = parent
	self.btnIcon_ = self.go_.transform:ComponentByName("buyBtn/costIcon", typeof(UISprite))
	self.uiBtn_ = self.go_.transform:ComponentByName("buyBtn", typeof(UISprite))
	self.btnBox = self.uiBtn_:GetComponent(typeof(UnityEngine.BoxCollider))
	self.icon_ = self.go_.transform:Find("item").gameObject
	self.frameBg_ = self.go_:NodeByName("item/frameImg").gameObject
	self.itemMask_ = self.go_.transform:ComponentByName("item/mask", typeof(UISprite))
	self.btnMask_ = self.go_.transform:ComponentByName("buyBtn/mask", typeof(UISprite))
	self.labelHasBuy_ = self.go_.transform:ComponentByName("buyBtn/labelHasBuy", typeof(UILabel))
	self.buyLabel_ = self.go_.transform:ComponentByName("buyBtn/iconLabel", typeof(UILabel))
	self.timeLabel = self.go_.transform:ComponentByName("timeLabel", typeof(UILabel))
end

function MarketItem:setInfo(params)
	self:forceSetState(true)

	if not params then
		self.go_:SetActive(false)

		return
	end

	self.go_:SetActive(true)

	self.item_ = params.item

	if not self.item_[1] or self.item_[1] == 0 then
		self.go_:SetActive(false)

		return
	end

	self.cost_ = params.cost
	self.buyTimes_ = params.buy_times or 0
	self.notSelling_ = tonumber(params.not_selling) or 0
	self.index_ = params.index
	local itemParams = {
		show_has_num = true,
		showSellLable = false,
		num = self.item_[2],
		itemID = self.item_[1],
		uiRoot = self.icon_,
		dragCallback = {
			startCallback = function ()
				self.parent_.hasMove_ = false
				self.parent_.delta_ = 0
			end,
			endCallback = function ()
				self.parent_.hasMove_ = false
				self.parent_.delta_ = 0
			end,
			dragCallback = function (go, delta)
				self.parent_:onDrag(go, delta)
			end
		},
		isNew = params.isNew
	}

	if self.parent_.shopType_ == xyd.ShopType.ARTIFACT then
		itemParams.group = xyd.tables.equipTable:getGroup(itemParams.itemID)
	end

	local type_ = xyd.tables.itemTable:getType(self.item_[1])

	self.frameBg_:SetActive(false)

	if type_ == xyd.ItemType.HERO_DEBRIS or type_ == xyd.ItemType.HERO or type_ == xyd.ItemType.HERO_RANDOM_DEBRIS or type_ == xyd.ItemType.SKIN then
		if not self.heroIcon_ then
			self.heroIcon_ = xyd.getItemIcon(itemParams)
		else
			self.heroIcon_:getGameObject():SetActive(true)
			self.heroIcon_:setInfo(itemParams)
		end

		if self.itemIcon_ then
			self.itemIcon_:getGameObject():SetActive(false)
		end

		if self.playerIcon_ then
			self.playerIcon_:getGameObject():SetActive(false)
		end

		self.showIcon_ = self.heroIcon_
	elseif type_ == xyd.ItemType.AVATAR_FRAME then
		self.frameBg_:SetActive(true)

		itemParams.avatar_frame_id = itemParams.itemID

		if not self.playerIcon_ then
			self.playerIcon_ = PlayerIcon.new(itemParams.uiRoot, itemParams.renderPanel)
		else
			self.playerIcon_:getGameObject():SetActive(true)
		end

		itemParams.noClick = false

		self.playerIcon_:setInfo(itemParams)

		if self.heroIcon_ then
			self.heroIcon_:getGameObject():SetActive(false)
		end

		if self.itemIcon_ then
			self.itemIcon_:getGameObject():SetActive(false)
		end

		self.showIcon_ = self.playerIcon_
	else
		if not self.itemIcon_ then
			self.itemIcon_ = xyd.getItemIcon(itemParams)
		else
			self.itemIcon_:showEffect(false)
			self.itemIcon_:getGameObject():SetActive(true)
			self.itemIcon_:setInfo(itemParams)
		end

		if self.heroIcon_ then
			self.heroIcon_:getGameObject():SetActive(false)
		end

		if self.playerIcon_ then
			self.playerIcon_:getGameObject():SetActive(false)
		end

		self.showIcon_ = self.itemIcon_
	end

	local costIcon = xyd.tables.itemTable:getIcon(self.cost_[1])

	xyd.setUISpriteAsync(self.btnIcon_, nil, costIcon, nil, )

	self.labelHasBuy_.text = __("ALREADY_BUY")
	self.buyLabel_.text = tostring(xyd.getRoughDisplayNumber(self.cost_[2]))
	local limit = xyd.tables.shopConfigTable:getSlotBuyTimes(self.parent_.shopType_, self.index_)

	if self.notSelling_ == 1 or limit and limit > 0 and self.buyTimes_ and limit <= self.buyTimes_ then
		self.showIcon_:setNoClick(true)
		xyd.applyChildrenGrey(self.showIcon_.go)
		xyd.applyChildrenGrey(self.uiBtn_.gameObject)
		XYDCo.WaitForFrame(1, function ()
			xyd.applyChildrenOrigin(self.buyLabel_.gameObject)
			self.showIcon_:setLabelNumColor(Color.New(1, 1, 1, 1))
		end, nil)
		self.itemMask_.gameObject:SetActive(true)

		self.btnBox.enabled = false
	else
		self.showIcon_:setNoClick(false)

		self.btnBox.enabled = true

		xyd.applyChildrenOrigin(self.icon_)
		xyd.applyChildrenOrigin(self.uiBtn_.gameObject)
		self.itemMask_.gameObject:SetActive(false)
	end

	self.btnIcon_.gameObject:SetActive(true)
	self.buyLabel_.gameObject:SetActive(true)
	self.labelHasBuy_.gameObject:SetActive(false)

	UIEventListener.Get(self.uiBtn_.gameObject).onClick = handler(self, self.onClickBtnBuy)
	self.shopType = params.shopType
	self.unchange = params.unchange
	self.end_time = params.end_time or 0

	if self.shopType == xyd.ShopType.SHOP_HERO and self.unchange then
		if xyd.getServerTime() < self.end_time then
			self.timeLabel:SetActive(true)

			local timeCount = import("app.components.CountDown").new(self.timeLabel)

			timeCount:setInfo({
				duration = self.end_time - xyd:getServerTime()
			})
		else
			self.timeLabel:SetActive(false)
		end
	else
		self.timeLabel:SetActive(false)
	end
end

function MarketItem:refreshInfo(params)
	self.item_ = params.item

	if not self.item_[1] or self.item_[1] == 0 then
		self.go_:SetActive(false)

		return
	end

	self.cost_ = params.cost
	self.buyTimes_ = params.buyTimes or params.buy_times or 0
	self.notSelling_ = tonumber(params.not_selling) or 0
	self.buyLabel_.text = tostring(xyd.getRoughDisplayNumber(self.cost_[2]))
	local limit = xyd.tables.shopConfigTable:getSlotBuyTimes(self.parent_.shopType_, self.index_)

	if self.notSelling_ == 1 or limit and limit > 0 and self.buyTimes_ and limit <= self.buyTimes_ then
		self.showIcon_:setNoClick(true)
		xyd.applyChildrenGrey(self.icon_)
		xyd.applyChildrenGrey(self.uiBtn_.gameObject)
		XYDCo.WaitForFrame(1, function ()
			xyd.applyChildrenOrigin(self.buyLabel_.gameObject)
			self.showIcon_:setLabelNumColor(Color.New(1, 1, 1, 1))
		end, nil)

		self.btnBox.enabled = false

		self.itemMask_.gameObject:SetActive(true)
	else
		self.showIcon_:setNoClick(false)

		self.btnBox.enabled = true

		xyd.applyChildrenOrigin(self.icon_)
		xyd.applyChildrenOrigin(self.uiBtn_.gameObject)
		self.itemMask_.gameObject:SetActive(false)
	end
end

function MarketItem:forceSetState(flag)
	if not flag then
		self.btnIcon_.gameObject:SetActive(false)
		self.itemMask_.gameObject:SetActive(true)
		self.btnMask_.gameObject:SetActive(true)
		self.labelHasBuy_.gameObject:SetActive(true)
		self.buyLabel_.gameObject:SetActive(false)
	else
		self.btnIcon_.gameObject:SetActive(true)
		self.itemMask_.gameObject:SetActive(false)
		self.btnMask_.gameObject:SetActive(false)
		self.labelHasBuy_.gameObject:SetActive(false)
		self.buyLabel_.gameObject:SetActive(true)
	end
end

function MarketItem:onClickIcon()
	xyd.WindowManager.get():openWindow("item_tips_window", {
		itemID = self.item_[1]
	})
end

function MarketItem:onClickBtnBuy()
	local limit = xyd.tables.shopConfigTable:getSlotBuyTimes(self.parent_.shopType_, self.index_)

	if self.notSelling_ == 1 or limit and limit > 0 and self.buyTimes_ and limit <= self.buyTimes_ then
		return
	end

	local cost = self.cost_
	local hasNum = xyd.models.backpack:getItemNumByID(cost[1])

	if xyd.isItemAbsence(cost[1], cost[2]) then
		return
	end

	if self.parent_.shopType_ == xyd.ShopType.SHOP_ARENA or self.parent_.shopType_ == xyd.ShopType.SHOP_TRIAL then
		local maxNum = -1

		if limit and limit > 0 and self.buyTimes_ then
			maxNum = tonumber(limit) - self.bu33yTimes_
		end

		if self.notSelling_ == -1 then
			maxNum = 1
		end

		local itemData = self.item_
		local itemParams = {
			showSellLable = false,
			num = itemData[2],
			itemID = itemData[1]
		}

		xyd.WindowManager.get():openWindow("item_buy_window", {
			cost = cost,
			max_num = maxNum,
			itemParams = itemParams,
			buyCallback = function (num)
				self.parent_.shopModel_:buyShopItem(self.parent_.shopType_, self.index_, num)
			end
		})
	elseif self.parent_.shopType_ == xyd.ShopType.SHOP_ASSESSMENT_ACADEMY then
		local maxNum = -1

		if limit and limit > 0 and self.buyTimes_ then
			maxNum = tonumber(limit) - self.buyTimes_
		end

		local itemData = self.item_

		if xyd.tables.shopSchoolPracticeTable:checkShowChoose(self.index_) then
			local itemParams = {
				showSellLable = false,
				num = itemData[2],
				itemID = itemData[1]
			}

			xyd.WindowManager.get():openWindow("item_buy_window", {
				cost = cost,
				max_num = maxNum,
				itemParams = itemParams,
				buyCallback = function (num)
					self.parent_.shopModel_:buyShopItem(self.parent_.shopType_, self.index_, num)
				end
			})
		else
			local params = {
				message = __("CONFIRM_BUY"),
				alertType = xyd.AlertType.YES_NO,
				callback = function (confirmBuy)
					if confirmBuy then
						self.parent_.shopModel_:buyShopItem(self.parent_.shopType_, self.index_)
					end
				end
			}

			xyd.WindowManager.get():openWindow("alert_window", params)
		end
	else
		local params = {
			message = __("CONFIRM_BUY"),
			alertType = xyd.AlertType.YES_NO,
			callback = function (confirmBuy)
				if confirmBuy then
					self.parent_.shopModel_:buyShopItem(self.parent_.shopType_, self.index_)
				end
			end
		}

		xyd.WindowManager.get():openWindow("alert_window", params)
	end
end

function MarketItem:showItem(canShow)
	self.uiBtn_:SetActive(canShow)
	self.icon_:SetActive(canShow)
end

function MarketItem:getIndex()
	return self.index_
end

function ShopWindow:ctor(name, params)
	ShopWindow.super.ctor(self, name, params)

	self.needCrystal_ = 20
	self.initTimes = 1
	self.isFree_ = false
	self.firstIn_ = true
	self.pageIcons_ = {}
	self.page_ = 1
	self.pageNum_ = 0
	self.startX_ = 0
	self.pageList_ = {}
	self.itemList_ = {}
	self.dotIconList_ = {}
	self.chooseGroup = 0
end

function ShopWindow:initWindow()
	self:getComponent()
	self:refreshBanner()
	ShopWindow.super.initWindow(self)
	self:registerEvent()
end

function ShopWindow:getComponent()
	local winTrans = self.window_.transform
	self.marketBg = winTrans:ComponentByName("bg", typeof(UITexture))
	self.dragContentBg_ = winTrans:ComponentByName("dragScroll", typeof(UIWidget)).gameObject
	self.marketContent_ = self.window_.transform:ComponentByName("transPos/content", typeof(UITexture))
	self.contentSmall_ = self.window_.transform:NodeByName("transPos/contentBgSmall").gameObject
	local contentTrans = self.marketContent_.transform
	local leftArrIcon = contentTrans:ComponentByName("leftArr", typeof(UISprite))
	local rightArrIcon = contentTrans:ComponentByName("rightArr", typeof(UISprite))
	self.leftArr_ = contentTrans:Find("leftArr").gameObject
	self.rightArr_ = contentTrans:Find("rightArr").gameObject
	self.rightArrRed = self.rightArr_:NodeByName("shopRed").gameObject

	self.rightArrRed:SetActive(false)

	self.groupChoose = self.marketContent_:NodeByName("groupChoose").gameObject

	for i = 1, 6 do
		self["group" .. i] = self.groupChoose:NodeByName("group" .. i).gameObject

		for j = 1, 2 do
			self["group" .. i .. "_" .. j] = self["group" .. i]:ComponentByName("group" .. i .. "_" .. j, typeof(UISprite))
		end

		self["groupRedMark" .. i] = self["group" .. i]:NodeByName("redMark").gameObject
	end

	self.uiParent_ = contentTrans:Find("gridOfItem").gameObject
	self.pictureContainer_ = contentTrans:NodeByName("girlPos").gameObject
	local bubbleText = contentTrans:NodeByName("girlPos/bubbleText").gameObject
	self.partnerImg = import("app.components.PartnerImg").new(self.pictureContainer_)
	self.partnerModel = import("app.components.GirlsModel").new(self.pictureContainer_)
	self.bubbleText_ = import("app.components.BubbleText").new(bubbleText)

	UIEventListener.Get(self.dragContentBg_).onDragStart = function ()
		self.hasMove_ = false
		self.delta_ = 0
	end

	UIEventListener.Get(self.dragContentBg_).onDrag = function (go, delta)
		self:onDrag(go, delta)
	end

	UIEventListener.Get(self.dragContentBg_).onDragEnd = function ()
		self.delta_ = 0
		self.hasMove_ = false
	end

	self.partnerImg:setTouchListener(function ()
		self:onTouchImg()
	end)

	UIEventListener.Get(leftArrIcon.gameObject).onClick = function ()
		self:goNextPage(-1)
	end

	UIEventListener.Get(rightArrIcon.gameObject).onClick = function ()
		self:goNextPage(1)
	end
end

function ShopWindow:onDrag(go, delta)
	self.delta_ = self.delta_ + delta.x

	if self.delta_ > 50 and not self.hasMove_ then
		self.hasMove_ = true

		self:goNextPage(-1, true)
	end

	if self.delta_ < -50 and not self.hasMove_ then
		self.hasMove_ = true

		self:goNextPage(1, true)
	end
end

function ShopWindow:initTopGroup()
	local costType = xyd.tables.shopConfigTable:getEconomyShow(self.shopType_)
	local items = {}

	if tonumber(costType) then
		items = {
			{
				hidePlus = true,
				id = costType
			}
		}
	else
		for _, item in ipairs(costType) do
			table.insert(items, {
				hidePlus = true,
				id = item
			})
		end
	end

	if not self.windowTop_ then
		self.windowTop_ = WindowTop.new(self.window_, self.name_)
	end

	self.windowTop_:setItem(items)
end

function ShopWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_SHOP_INFO, handler(self, self.refreshWindow))
	self.eventProxy_:addEventListener(xyd.event.REFRESH_SHOP, handler(self, self.refreshWindow))
	self.eventProxy_:addEventListener(xyd.event.BUY_SHOP_ITEM, handler(self, self.buyItemRes))

	for i = 1, 6 do
		UIEventListener.Get(self["group" .. i]).onClick = function ()
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

			if self.chooseGroup == i then
				self.chooseGroup = 0
			else
				self.chooseGroup = i
			end

			self:refreshContentGroup()
		end
	end
end

function ShopWindow:sortItems()
	table.sort(self.items_, function (a, b)
		return xyd.tables.shopHeroNewTable:getRank(a.index) < xyd.tables.shopHeroNewTable:getRank(b.index)
	end)
end

function ShopWindow:checkAddItem(item)
	if self.shopType_ ~= xyd.ShopType.SHOP_HERO then
		return true
	end

	local itemId = tonumber(item[1])
	local itemNum = tonumber(item[2])
	local filters = {
		{
			930121,
			25
		},
		{
			930119,
			25
		},
		{
			930080,
			10
		}
	}

	for i = 1, 3 do
		local filter = filters[i]

		if filter[1] == itemId and filter[2] == itemNum then
			local num = xyd.models.backpack:getItemNumByID(filter[1])
			local _, charge = math.modf(num / 50)

			if charge ~= 0 then
				return true
			else
				return false
			end
		end
	end

	return true
end

function ShopWindow:refreshBanner()
	local shopBanner = xyd.tables.shopConfigTable:getBg(self.shopType_)
	local shopContent = xyd.tables.shopConfigTable:getBannerImg(self.shopType_)

	if shopBanner then
		xyd.setUITextureAsync(self.marketBg, "Textures/scenes_web/" .. shopBanner)
	end

	if shopContent then
		xyd.setUITextureAsync(self.marketContent_, "Textures/shop_web/" .. shopContent, function ()
			self.contentSmall_:SetActive(false)
		end)
	end
end

function ShopWindow:refreshWindow()
	self:refreshBanner()
	self:layOutUI()
	self:updateShopRedMark()
end

function ShopWindow:layOutUI()
	local redMarkId = xyd.tables.shopConfigTable:getRedMarkId(self.shopType_)
	self.isShowNew = xyd.models.redMark:getRedState(redMarkId)
	local slotCount = self:initItems()
	self.pageNum_ = math.ceil(slotCount / MAXSLOT)

	if self.pageNum_ < 1 then
		self.pageNum_ = 1
	end

	self.page_ = 1

	self:initTopGroup()
	self:initTimePart()
	self:initDotState()
	self:setArrowState()

	if self.pageNum_ >= 2 then
		self:arrowMove()
	else
		if self.sequence1_ then
			self.sequence1_:Kill(false)

			self.sequence1_ = nil
		end

		if self.sequence2_ then
			self.sequence2_:Kill(false)

			self.sequence2_ = nil
		end
	end

	if self.firstIn_ then
		self.firstIn_ = false

		self:initItemsOnpage(self.page_)
		self:initTopLayout()
		self:initChooseGroup()
	else
		self:refreshItemList()
	end

	self:refreshGirlImg()

	if self.shopType_ == xyd.ShopType.SHOP_ARENA then
		local redMarkState = xyd.models.redMark:getRedState(xyd.RedMarkType.ARENA_SHOP)

		if redMarkState then
			self.rightArrRed:SetActive(true)
		end
	else
		self.rightArrRed:SetActive(false)
	end
end

function ShopWindow:initItems()
	self.shopInfo_ = self.shopModel_:getShopInfo(self.shopType_)
	local shopTable = xyd.tables.shopConfigTable:getShopTable(self.shopType_)
	self.items_ = self.shopInfo_.items
	local nowTime = xyd.getServerTime()

	if self.shopType_ == xyd.ShopType.SHOP_HERO_NEW or self.shopType_ == xyd.ShopType.ARTIFACT then
		local tempItems = {}
		local ids = xyd.tables.shopHeroNewTable:getIds()

		if self.shopType_ == xyd.ShopType.ARTIFACT then
			ids = xyd.tables.shopArtifactTable:getIds()
		end

		for i = 1, #self.items_ do
			local tempItem = self.items_[i]
			local group = xyd.tables.itemTable:getGroup(tempItem.item[1])

			if self.shopType_ == xyd.ShopType.ARTIFACT then
				group = xyd.tables.equipTable:getGroup(tempItem.item[1])
			end

			if (self.chooseGroup == 0 or group == self.chooseGroup) and ids[i] and tempItem.item[1] and tempItem.item[1] > 0 then
				table.insert(tempItems, {
					item = tempItem.item,
					cost = tempItem.cost,
					buy_times = tempItem.buy_times,
					index = i,
					not_selling = tempItem.not_selling,
					group = group
				})
			end
		end

		self.items_ = tempItems

		if self.shopType_ == xyd.ShopType.SHOP_HERO_NEW then
			self:sortItems()
		else
			table.sort(self.items_, function (a, b)
				return xyd.tables.shopArtifactTable:getRank(a.index) < xyd.tables.shopArtifactTable:getRank(b.index)
			end)
		end
	end

	self.itemsByPage = {}
	local items = self.items_
	local slotCount = 0
	local unchange_num = self.shopModel_:getUnchangeNum(self.shopType_)
	local tempTable1 = {}
	local tempTable2 = {}

	for i = 1, #items do
		local itemData = items[i]
		local item = itemData.item
		local cost = itemData.cost
		local buyTimes = itemData.buy_times
		local itemParams = {
			shopType = self.shopType_,
			index = itemData.index or tonumber(i),
			item = item,
			cost = cost,
			buy_index = itemData.index,
			buy_times = buyTimes,
			unchange = xyd.tables.shopHeroTable:getIsRefresh(tonumber(i)) == 0,
			end_time = self.shopInfo_.end_time,
			not_selling = itemData.not_selling
		}

		if shopTable and shopTable ~= "" then
			local endTime = xyd.tables[shopTable]:getShopNew(itemParams.index)

			if self.isShowNew and nowTime < endTime then
				itemParams.isNew = 1
			end
		end

		if cost[1] and cost[1] == 0 then
			table.insert(tempTable2, itemParams)
		elseif self.shopType_ == xyd.ShopType.SHOP_HERO and xyd.tables.shopHeroTable:getIsRefresh(tonumber(i)) == 0 then
			table.insert(tempTable2, itemParams)
		else
			table.insert(tempTable1, itemParams)
		end
	end

	local itemsNew = xyd.arrayMerge(tempTable2, tempTable1)

	for i = 1, #itemsNew do
		local itemParams = itemsNew[i]
		local item = itemParams.item
		local cost = itemParams.cost

		if cost[1] and cost[1] ~= 0 and item[1] and self:checkAddItem(item) then
			slotCount = slotCount + 1

			if slotCount > MAXSLOT * #self.itemsByPage then
				table.insert(self.itemsByPage, {})
			end

			if self.shopType_ == xyd.ShopType.SHOP_HERO_NEW or self.shopType_ == xyd.ShopType.ARTIFACT then
				itemParams.index = itemParams.buy_index
			end

			table.insert(self.itemsByPage[#self.itemsByPage], itemParams)
		end
	end

	return slotCount
end

function ShopWindow:startCountDown(leftTime)
	local reFreshTimeLabel = self.window_.transform:ComponentByName("transPos/content/timeRefresh/labelRefreshTime", typeof(UILabel))
	local params = {
		callback = function ()
			self.shopModel_:refreshShop(self.shopType_)
		end,
		duration = leftTime
	}

	if not self.labelRefreshTime_ then
		self.labelRefreshTime_ = CountDown.new(reFreshTimeLabel, params)
	else
		self.labelRefreshTime_:setInfo(params)
	end

	reFreshTimeLabel.gameObject:SetActive(true)
end

function ShopWindow:initTimePart()
	local winTrans = self.window_.transform
	local refreshTimer = winTrans:NodeByName("transPos/content/timeRefresh")

	if self.shopType_ == xyd.ShopType.SHOP_HERO_NEW then
		refreshTimer.gameObject:SetActive(false)
	else
		local imgTimeBg = refreshTimer:ComponentByName("imgTimeBg_", typeof(UISprite))
		local imgRefreshBtnBg = refreshTimer:ComponentByName("imgRefreshBtnBg_", typeof(UISprite))
		local btnRefresh = refreshTimer:ComponentByName("btnRefresh", typeof(UISprite))
		local labelText02 = refreshTimer:ComponentByName("labelText02", typeof(UILabel))
		local labelText01 = refreshTimer:ComponentByName("labelText01", typeof(UILabel))
		labelText01.text = __("SHOP_TEXT01")
		labelText02.text = __("SHOP_TEXT02")
		local labelRefreshTime = refreshTimer:ComponentByName("labelRefreshTime", typeof(UILabel))

		imgTimeBg.gameObject:SetActive(false)
		imgRefreshBtnBg.gameObject:SetActive(false)
		btnRefresh.gameObject:SetActive(false)
		labelRefreshTime.gameObject:SetActive(false)

		if xyd.tables.shopConfigTable:isRefresh(self.shopType_) == 0 then
			refreshTimer.gameObject:SetActive(false)

			return
		end

		if xyd.tables.shopConfigTable:getRefreshFreeTime(self.shopType_) == 0 then
			refreshTimer.gameObject:SetActive(true)
			self:setFreshBtn(false)
			imgRefreshBtnBg.gameObject:SetActive(true)
			labelText01.gameObject:SetActive(false)
			labelText02.gameObject:SetActive(false)
			imgTimeBg.gameObject:SetActive(false)

			btnRefresh.transform.localPosition = Vector3(30, -47, 0)

			return
		end

		local leftTime = self.shopInfo_.refreshTime + xyd.tables.shopConfigTable:getRefreshFreeTime(self.shopType_) - xyd.getServerTime()

		if leftTime > 0 then
			refreshTimer.gameObject:SetActive(true)
			self:setFreshBtn(false)
			imgRefreshBtnBg.gameObject:SetActive(false)
			labelText01.gameObject:SetActive(true)
			labelText02.gameObject:SetActive(false)
			imgTimeBg.gameObject:SetActive(true)
			self:startCountDown(leftTime)

			btnRefresh.transform.localPosition = Vector3(10, -65, 0)
		else
			refreshTimer.gameObject:SetActive(true)

			if self.labelRefreshTime_ then
				self.labelRefreshTime_:stopTimeCount()
			end

			self:setFreshBtn(true)
			imgRefreshBtnBg.gameObject:SetActive(false)
			labelText01.gameObject:SetActive(false)
			labelText02.gameObject:SetActive(true)
			imgTimeBg.gameObject:SetActive(true)

			btnRefresh.transform.localPosition = Vector3(10, -65, 0)
		end
	end
end

function ShopWindow:refreshGirlImg()
	self.girlImg_ = xyd.tables.shopConfigTable:getGirlsImg(self.shopType_)
	local ifImg = false

	if self.girlImg_ > 0 then
		self.partnerModel:SetActive(false)

		ifImg = true

		self.bubbleText_:SetActive(true)

		self.pictureContainer_.transform.localPosition = Vector3(-115, 250, 0)
		local scale = xyd.tables.shopConfigTable:getScale(self.shopType_)
		local offset = xyd.tables.shopConfigTable:getOffest(self.shopType_)

		self.partnerImg:setImg({
			showResLoading = true,
			windowName = self.name,
			girlImg = self.girlImg_
		})
		self.partnerImg.go.transform:SetLocalScale(scale, scale, scale)
		self.partnerImg.go.transform:SetLocalPosition(offset[1], offset[2], 0)
		self.partnerImg.go.gameObject:SetActive(true)
	else
		local id = xyd.tables.shopConfigTable:getGirlsModel(self.shopType_)
		local scale = xyd.tables.shopConfigTable:getScale(self.shopType_)
		local offset = xyd.tables.shopConfigTable:getOffest(self.shopType_)

		self.bubbleText_:SetActive(false)
		self.partnerModel:SetActive(true)
		self.partnerImg.go.gameObject:SetActive(false)
		self.partnerModel:setModelInfo({
			id = id
		}, function ()
			self.partnerModel:setModelPosition(offset[1], offset[2], 0)
			self.partnerModel:setModelScale(scale)
			self.partnerModel:setBubble()
		end)
	end

	if ifImg then
		self.bubbleText_:setPositionY(self.partnerImg.go.transform.localPosition.y - 200)
	end

	self.bubbleText_:setBubbleFlipX(true)
	self:playEnterBubble()
end

function ShopWindow:onTouchImg()
	if self.isGroupShake then
		return
	end

	self.isGroupShake = true
	local pos = self.partnerImg.go.transform.localPosition
	local sequene = DG.Tweening.DOTween.Sequence()
	local transform = self.partnerImg.go.transform

	sequene:Append(transform:DOLocalMoveY(pos.y + 10, 0.1))
	sequene:Append(transform:DOLocalMoveY(pos.y - 10, 0.1))
	sequene:Append(transform:DOLocalMoveY(pos.y, 0.1))
	sequene:AppendCallback(function ()
		if not self then
			return
		end

		self.isGroupShake = false
		sequene = nil
	end)
	sequene:SetAutoKill(false)
	self:playDialog()
end

function ShopWindow:playDialog()
	if self.isInDialog then
		return
	end

	local girlImg = self.girlImg_
	self.isInDialog = true

	self.bubbleText_:SetActive(false)

	local rand = math.floor(math.random() * 5 + 0.5) + 1
	local index = rand > 5 and rand - 5 or rand
	local wh = xyd.tables.girlsImgTable:getTouchScale(self.girlImg_, index) or 0
	local text = xyd.tables.girlsImgTable:getTouchDialog(self.girlImg_, index)

	if #wh == 2 then
		self.bubbleText_:setSize(wh[1], wh[2])
	end

	self.bubbleText_:playDialogAction(text)
	self:setTimeout(function ()
		if not self.bubbleText_ or girlImg ~= self.girlImg_ then
			return
		end

		self.isInDialog = false

		self.bubbleText_:SetActive(false)
	end, self, xyd.tables.girlsImgTable:getTouchTime(girlImg, index))
end

function ShopWindow:playEnterBubble()
	self:stopSound()

	if self.girlImg_ > 0 then
		local girlImg = self.girlImg_
		self.isInDialog = true
		local wh = xyd.tables.girlsImgTable:getEnterScale(self.girlImg_)
		local text = xyd.tables.girlsImgTable:getEnterDialog(self.girlImg_)

		if #wh == 2 then
			self.bubbleText_:setSize(wh[1], wh[2])
		end

		self.bubbleText_:playDialogAction(text)
		self:setTimeout(function ()
			if not self.bubbleText_ or girlImg ~= self.girlImg_ then
				return
			end

			self.isInDialog = false

			self.bubbleText_:SetActive(false)
		end, self, xyd.tables.girlsImgTable:getEnterTime(girlImg))
	end
end

function ShopWindow:stopSound()
	if self.bubbleText_ then
		self.bubbleText_:SetActive(false)

		self.isInDialog = false
	end
end

function ShopWindow:setFreshBtn(isFree)
	local cost = xyd.tables.shopConfigTable:getRefreshCost(self.shopType_)
	local refreshTimer = self.window_.transform:NodeByName("transPos/content/timeRefresh")
	local btnRefresh = refreshTimer:ComponentByName("btnRefresh", typeof(UIButton))
	local groupBuy = refreshTimer:Find("btnRefresh/groupBuy").gameObject
	local groupFree = refreshTimer:Find("btnRefresh/groupFree").gameObject
	local costIcon = refreshTimer:ComponentByName("btnRefresh/groupBuy/iconCost", typeof(UISprite))
	local labelDesc = refreshTimer:ComponentByName("btnRefresh/groupBuy/labelDesc", typeof(UILabel))
	self.btnRefreshLabel = refreshTimer:ComponentByName("btnRefresh/groupBuy/labelDesc", typeof(UILabel))
	local labelCost = refreshTimer:ComponentByName("btnRefresh/groupBuy/labelCost", typeof(UILabel))
	local labelFree = refreshTimer:ComponentByName("btnRefresh/groupFree/labelFree", typeof(UILabel))
	labelCost.text = __("REFRESH")
	labelDesc.text = __("REFRESH")

	if xyd.Global.lang == "fr_fr" then
		self:checkFrFrBtnRefreshLabel()
	end

	labelCost.text = cost[2]
	labelFree.text = __("REFRESH")

	btnRefresh.gameObject:SetActive(true)
	xyd.setUISpriteAsync(costIcon, nil, xyd.tables.itemTable:getIcon(cost[1]), nil, )

	if isFree then
		groupBuy.gameObject:SetActive(false)
		labelFree.gameObject:SetActive(true)
		groupFree.gameObject:SetActive(true)
	else
		groupBuy.gameObject:SetActive(true)
		labelFree.gameObject:SetActive(false)
		groupFree.gameObject:SetActive(false)
	end

	UIEventListener.Get(btnRefresh.gameObject).onClick = function ()
		if not self.shopInfo_ or not xyd.tables.shopConfigTable:isRefresh(self.shopType_) then
			return
		else
			local hasNum = backpackModel:getItemNumByID(cost[1])

			if isFree then
				self.shopModel_:refreshShop(self.shopType_)

				return
			end

			if hasNum < cost[2] then
				local params = {
					message = __("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])),
					alertType = xyd.AlertType.TIPS
				}

				xyd.WindowManager.get():openWindow("alert_window", params)

				return
			end

			local str = nil
			local ItemTextTable = xyd.tables.itemTextTable

			if self.shopType_ == xyd.ShopType.SHOP_GUILD then
				str = __("CONFIRM_REGRESH_GUILD", ItemTextTable:getName(cost[1]), cost[2])
			elseif self.shopType_ == xyd.ShopType.SHOP_HERO then
				str = __("CONFIRM_REGRESH_GUILD", ItemTextTable:getName(cost[1]), cost[2])
			else
				str = __("CONFIRM_REFRESH", ItemTextTable:getName(cost[1]), cost[2])
			end

			local params = {
				message = str,
				alertType = xyd.AlertType.YES_NO,
				callback = function (yes_no)
					if yes_no then
						self.shopModel_:refreshShop(self.shopType_)
					end
				end
			}

			xyd.WindowManager.get():openWindow("alert_window", params)
		end
	end
end

function ShopWindow:checkFrFrBtnRefreshLabel()
	if xyd.Global.lang == "fr_fr" then
		if self.shopType_ == xyd.ShopType.SHOP_HERO or self.shopType_ == xyd.ShopType.SHOP_GUILD then
			self:setBtnRefreshLabel(__("REFRESH_SHOP_TIMES"))
		else
			self:setBtnRefreshLabel(__("REFRESH"))
		end
	else
		self:setBtnRefreshLabel(__("REFRESH"))
	end
end

function ShopWindow:setBtnRefreshLabel(str)
	if not self.btnRefreshLabel then
		local refreshTimer = self.window_.transform:NodeByName("transPos/content/timeRefresh")
		self.btnRefreshLabel = refreshTimer:ComponentByName("btnRefresh/groupBuy/labelDesc", typeof(UILabel))
	end

	self.btnRefreshLabel.text = str
end

function ShopWindow:initItemsOnpage(pageNum)
	local winTran = self.window_.transform
	local itemPrefab = winTran:Find("transPos/content/tempItem").gameObject

	self.uiParent_.gameObject:SetActive(false)
	itemPrefab:SetActive(false)

	local tempItem = self.uiParent_.gameObject
	local tempGrid = tempItem.transform:ComponentByName("grid", typeof(UIGrid))

	for idx = 1, MAXSLOT do
		local realIndex = MAXSLOT * (pageNum - 1) + idx

		if not self.itemList_[idx] then
			local itemTemp = NGUITools.AddChild(tempGrid.gameObject, itemPrefab)

			itemTemp:SetActive(true)

			local marketItem = MarketItem.new(itemTemp, self)

			if self.itemsByPage[pageNum][idx] then
				marketItem:setInfo(self.itemsByPage[pageNum][idx])
				marketItem:showItem(true)
			else
				marketItem:showItem(false)
			end

			table.insert(self.itemList_, marketItem)
		elseif self.itemsByPage[pageNum][idx] then
			self.itemList_[idx]:setInfo(self.itemsByPage[pageNum][idx])
			self.itemList_[idx]:showItem(true)
		else
			self.itemList_[idx]:showItem(false)
		end
	end

	self.uiParent_.gameObject:SetActive(true)
	tempGrid:Reposition()
	table.insert(self.pageList_, tempItem)
end

function ShopWindow:arrowMove()
	local positionLeft = -340
	local positionRight = 340

	if self.sequence1_ then
		self.sequence1_:Kill(false)

		self.sequence1_ = nil
	end

	if self.sequence2_ then
		self.sequence2_:Kill(false)

		self.sequence2_ = nil
	end

	self.leftArr_.transform.localPosition = Vector3(-340, -48, 0)
	self.rightArr_.transform.localPosition = Vector3(340, -48, 0)

	function self.playAni2_()
		self.sequence2_ = DG.Tweening.DOTween.Sequence()

		self.sequence2_:Insert(0, self.leftArr_.transform:DOLocalMove(Vector3(positionLeft - 5, -48, 0), 1, false))
		self.sequence2_:Insert(1, self.leftArr_.transform:DOLocalMove(Vector3(positionLeft + 5, -48, 0), 1, false))
		self.sequence2_:Insert(0, self.rightArr_.transform:DOLocalMove(Vector3(positionRight + 5, -48, 0), 1, false))
		self.sequence2_:Insert(1, self.rightArr_.transform:DOLocalMove(Vector3(positionRight - 5, -48, 0), 1, false))
		self.sequence2_:AppendCallback(function ()
			self.playAni1_()
		end)
	end

	function self.playAni1_()
		self.sequence1_ = DG.Tweening.DOTween.Sequence()

		self.sequence1_:Insert(0, self.leftArr_.transform:DOLocalMove(Vector3(positionLeft - 5, -48, 0), 1, false))
		self.sequence1_:Insert(1, self.leftArr_.transform:DOLocalMove(Vector3(positionLeft + 5, -48, 0), 1, false))
		self.sequence1_:Insert(0, self.rightArr_.transform:DOLocalMove(Vector3(positionRight + 5, -48, 0), 1, false))
		self.sequence1_:Insert(1, self.rightArr_.transform:DOLocalMove(Vector3(positionRight - 5, -48, 0), 1, false))
		self.sequence1_:AppendCallback(function ()
			self.playAni2_()
		end)
	end

	self.playAni1_()
end

function ShopWindow:buyItemRes(event)
	self.shopInfo_ = self.shopModel_:getShopInfo(self.shopType_)
	self.items_ = self.shopInfo_.items
	local params = event.data
	local index = params.index
	local items = params.items
	local num = params.num

	if index <= self.shopModel_:getUnchangeNum(self.shopType_) then
		self.shopModel_:buyUnchangeItem(self.shopType_, index)
	end

	local buyItem = items[index]
	local itemData = buyItem.item

	for _, marketItem in ipairs(self.itemList_) do
		if marketItem:getIndex() == index then
			marketItem:refreshInfo(buyItem)

			if self.shopType_ == xyd.ShopType.SHOP_HERO and index == 26 then
				local _, charge = math.modf(xyd.models.backpack:getItemNumByID(930080))

				if charge == 0 then
					marketItem:forceSetState(false)
				end
			end
		end
	end

	xyd.alertItems({
		{
			item_id = itemData[1],
			item_num = itemData[2] * num
		}
	})
	self:initItems()

	if self.partnerModel and xyd.GuideController.get():isGuideComplete() then
		self.partnerModel:playChooseAction()
	end
end

function ShopWindow:setArrowState()
	if self.pageNum_ >= 2 then
		self.leftArr_:SetActive(self.page_ ~= 1)
		self.rightArr_:SetActive(self.page_ ~= self.pageNum_)
	else
		self.leftArr_:SetActive(false)
		self.rightArr_:SetActive(false)
	end
end

function ShopWindow:refreshItemList(pageNum)
	self.shopInfo_ = self.shopModel_:getShopInfo(self.shopType_)

	if self.shopInfo_ then
		for idx = 1, MAXSLOT do
			local page = pageNum or self.page_
			local itemInfo = self.itemsByPage[page][idx]
			local shopItem = self.itemList_[idx]

			if not itemInfo and shopItem then
				shopItem:showItem(false)
			elseif shopItem then
				shopItem:showItem(true)
				shopItem:setInfo(itemInfo)
			end
		end
	end
end

function ShopWindow:goNextPage(changePageNum, buyDrag)
	if buyDrag and (changePageNum + self.page_ <= 0 or self.pageNum_ < self.page_ + changePageNum) then
		return
	end

	xyd.SoundManager.get():playSound(xyd.SoundID.SWITCH_PAGE)

	self.page_ = self.page_ + changePageNum

	if self.page_ <= 0 then
		self.page_ = self.pageNum_
	elseif self.pageNum_ < self.page_ then
		self.page_ = 1
	end

	self:setArrowState()
	self:setPageIcon()
	self:refreshItemList()
end

function ShopWindow:initDotState()
	local dotListTrans = self.window_.transform:Find("transPos/content/dotIcon").transform
	local dotRoot = dotListTrans:ComponentByName("dotIcon_", typeof(UISprite)).gameObject
	local gridDot = dotListTrans:ComponentByName("grid", typeof(UIGrid))

	dotRoot:SetActive(false)

	if #self.dotIconList_ ~= self.pageNum_ then
		for i = 0, self.pageNum_ - 1 do
			local dotIcon = self.dotIconList_[i + 1]

			if not dotIcon then
				local dotItem = NGUITools.AddChild(gridDot.gameObject, dotRoot)
				dotIcon = dotItem.transform:GetComponent(typeof(UISprite))
			end

			UIEventListener.Get(dotIcon.gameObject).onClick = function ()
				if self.page_ ~= i + 1 then
					self.page_ = i + 1

					if self.page_ <= 0 then
						self.page_ = self.pageNum_
					elseif self.pageNum_ < self.page_ then
						self.page_ = 1
					end

					self:setArrowState()
					self:setPageIcon()
					self:refreshItemList()
				end
			end

			self.dotIconList_[i + 1] = dotIcon
		end

		if self.pageNum_ < #self.dotIconList_ then
			for i = self.pageNum_ + 1, #self.dotIconList_ do
				local dotIconNotNeed = self.dotIconList_[i]

				Destroy(dotIconNotNeed.gameObject)

				self.dotIconList_[i] = nil
			end
		end

		XYDCo.WaitForFrame(1, function ()
			gridDot:Reposition()
		end, nil)

		if self.pageNum_ <= 1 then
			dotListTrans.gameObject:SetActive(false)
		else
			dotListTrans.gameObject:SetActive(true)
		end
	end

	self:setArrowState()
	self:setPageIcon()
end

function ShopWindow:setPageIcon()
	for idx, dotIcon in ipairs(self.dotIconList_) do
		if idx ~= self.page_ then
			xyd.setUISpriteAsync(dotIcon, nil, "emotbtn1", nil, , true)

			dotIcon.width = 16
			dotIcon.height = 16
		else
			xyd.setUISpriteAsync(dotIcon, nil, "market_dot_bg2", nil, , true)

			dotIcon.width = 20
			dotIcon.height = 20
		end
	end
end

function ShopWindow:initChooseGroup()
	if self.shopType_ == xyd.ShopType.SHOP_HERO_NEW or self.shopType_ == xyd.ShopType.ARTIFACT then
		self.groupChoose:SetActive(true)
	end

	local preName = "shop_group"

	if self.shopType_ == xyd.ShopType.ARTIFACT then
		preName = "artifact_group"
		local layout = self.groupChoose:GetComponent(typeof(UILayout))
		layout.gap = Vector2(0, 0)
		layout.transform.localPosition = Vector3(-90, 250, 0)
	end

	for i = 1, 6 do
		for j = 1, 2 do
			local lastName = i .. "_" .. j

			xyd.setUISpriteAsync(self["group" .. lastName], nil, preName .. lastName, function ()
				self["group" .. lastName]:MakePixelPerfect()
			end)

			if j == 2 and self.shopType_ == xyd.ShopType.ARTIFACT then
				self["group" .. lastName].transform.localPosition = Vector3(2, 5.7, 0)
			end
		end
	end

	self:refreshChooseGroup()
end

function ShopWindow:refreshChooseGroup()
	for i = 1, 6 do
		if i == self.chooseGroup then
			self["group" .. i .. "_2"]:SetActive(true)
			self["group" .. i .. "_1"]:SetActive(false)
		else
			self["group" .. i .. "_2"]:SetActive(false)
			self["group" .. i .. "_1"]:SetActive(true)
		end
	end

	if self.shopType_ == xyd.ShopType.SHOP_HERO_NEW then
		self:refreshShopHeroNewRedMark()
	end
end

function ShopWindow:refreshContentGroup()
	self:refreshChooseGroup()

	local grid = self.uiParent_:NodeByName("grid").gameObject

	NGUITools.DestroyChildren(grid.transform)

	local dotListTrans = self.window_.transform:Find("transPos/content/dotIcon").transform
	local dotRoot = dotListTrans:ComponentByName("dotIcon_", typeof(UISprite)).gameObject
	local gridDot = dotListTrans:ComponentByName("grid", typeof(UIGrid)).gameObject

	NGUITools.DestroyChildren(gridDot.transform)

	local slotCount = self:initItems()
	self.pageNum_ = math.ceil(slotCount / MAXSLOT)

	if self.pageNum_ < 1 then
		self.pageNum_ = 1
	end

	self.page_ = 1
	self.itemList_ = {}
	self.dotIconList_ = {}

	self:initDotState()
	self:setArrowState()
	self:initItemsOnpage(self.page_)
end

function ShopWindow:initTopLayout()
	self.topItemGrid_ = self.window_.transform:NodeByName("transPos/content/topIconGrid").gameObject

	if self.shopType_ == xyd.ShopType.SHOP_HERO_NEW or self.shopType_ == xyd.ShopType.ARTIFACT then
		self.topItemGrid_.gameObject:SetActive(false)

		return
	end

	self.topItemGrid_.gameObject:SetActive(true)

	local shopConf = xyd.tables.shopConfigTable
	local ids = shopConf:getIDs()
	local selectIDs = {}

	for _, id in ipairs(ids) do
		local rank = shopConf:rank(id)

		if rank and rank > 0 then
			table.insert(selectIDs, id)
		end
	end

	table.sort(selectIDs, function (type1, type2)
		local rank1 = shopConf:rank(type1)
		local rank2 = shopConf:rank(type2)

		if rank1 ~= rank2 then
			return rank1 < rank2
		else
			return false
		end
	end)
	self.topItemGrid_.gameObject:SetActive(true)

	self.tab_ = ShopTopBar.new(self.topItemGrid_, selectIDs, self)
end

function ShopWindow:updateByShopType(shopType)
	if shopType ~= self.shopType_ then
		self.partnerModel:stopSound()

		self.shopType_ = shopType
		self.shopInfo_ = self.shopModel_:getShopInfo(self.shopType_)

		if not self.shopInfo_ then
			self.shopModel_:refreshShopInfo(self.shopType_)
		else
			self:refreshWindow()
		end

		self.isInDialog = false

		self:stopSound()
	end
end

function ShopWindow:refreshShopHeroNewRedMark()
	self.redMarkState = {
		false,
		false,
		false,
		false,
		false,
		false
	}
	local nowTime = xyd.getServerTime()
	local ids = xyd.tables.shopHeroNewTable:getIds()

	for i = 1, #ids do
		local endTime = xyd.tables.shopHeroNewTable:getShopNew(i)
		local group = xyd.tables.shopHeroNewTable:getGroup(i)
		local itemId = xyd.tables.shopHeroNewTable:getItemId(i)

		if group == self.chooseGroup then
			xyd.db.misc:setValue({
				key = "shop_hero_new_timestamp" .. itemId,
				value = endTime or 0
			})
		end

		local lastTime = tonumber(xyd.db.misc:getValue("shop_hero_new_timestamp" .. itemId)) or 0

		if endTime > lastTime and nowTime < endTime then
			self.redMarkState[group] = true
		end
	end

	for i = 1, 6 do
		self["groupRedMark" .. i]:SetActive(self.redMarkState[i])
	end
end

function ShopWindow:updateShopRedMark()
	local shopDBKey = xyd.tables.shopConfigTable:getRedMarkKey(self.shopType_)
	local shopTable = xyd.tables.shopConfigTable:getShopTable(self.shopType_)
	local ans = {}
	local redMarkId = xyd.tables.shopConfigTable:getRedMarkId(self.shopType_)

	if shopTable and shopTable ~= "" and redMarkId > 0 then
		local redStatus = xyd.models.redMark:getRedState(redMarkId)

		if redStatus then
			local nowTime = xyd.getServerTime()
			local ids = xyd.tables[shopTable]:getIds()

			for _, id in ipairs(ids) do
				local endTime = xyd.tables[shopTable]:getShopNew(id)

				if endTime > 0 and nowTime < endTime then
					table.insert(ans, id)
				end
			end

			xyd.db.misc:setValue({
				key = shopDBKey,
				value = cjson.encode(ans)
			})
			xyd.models.redMark:setMark(redMarkId, false)
		end
	end
end

function ShopWindow:willClose()
	ShopWindow.super.willClose(self)

	if self.partnerModel then
		self.partnerModel:stopSound()
	end

	if self.sequence1_ then
		self.sequence1_:Pause()
		self.sequence1_:Kill(false)

		self.sequence1_ = nil
	end

	if self.sequence2_ then
		self.sequence2_:Pause()
		self.sequence2_:Kill(false)

		self.sequence2_ = nil
	end

	if self.tlabelRefreshTime_ then
		self.tlabelRefreshTime_:stopTimeCount()

		self.tlabelRefreshTime_ = nil
	end

	xyd.Spine:cleanUp()
end

return ShopWindow
