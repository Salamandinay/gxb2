local ActivityContent = import(".ActivityContent")
local ActivitySandShop = class("ActivitySandShop", ActivityContent)
local ActivitySandShopSkinItem = class("ActivitySandShopSkinItem", import("app.common.ui.FixedMultiWrapContentItem"))
local LuaFlexibleWrapContent = import("app.common.ui.FlexibleWrapContent")
local ActivitySandShopLayerItem = class("ActivitySandShopLayerItem", import("app.common.ui.FlexibleWrapContentItem"))
local PartnerCard = import("app.components.PartnerCard")
local json = require("cjson")

local function getSkinNum(skinID)
	local tableIDs = xyd.tables.partnerTable:getPartnerIdBySkinId(skinID)
	local num = xyd.models.backpack:getItemNumByID(skinID)

	for _, tableID in pairs(tableIDs) do
		local group = xyd.models.slot:getListByTableID(tonumber(tableID))

		for _, partner in pairs(group) do
			local dressSkinID = partner:getSkinId()

			if dressSkinID == skinID then
				num = num + 1
			end
		end
	end

	return num
end

function ActivitySandShop:ctor(parentGO, params, parent)
	ActivitySandShop.super.ctor(self, parentGO, params, parent)
end

function ActivitySandShop:getPrefabPath()
	return "Prefabs/Windows/activity/activity_sand_shop"
end

function ActivitySandShop:resizeToParent()
	ActivitySandShop.super.resizeToParent(self)
end

function ActivitySandShop:initUI()
	self.view_state_ = 1

	self:getUIComponent()
	ActivitySandShop.super.initUI(self)
	self:layout()
	self:register()
end

function ActivitySandShop:getUIComponent()
	local go = self.go
	self.bg = go:NodeByName("bg").gameObject
	self.partnerNode = go:NodeByName("partnerNode").gameObject
	self.groupTopLeft = go:NodeByName("groupTopLeft").gameObject
	self.partnerGroup = self.groupTopLeft:ComponentByName("partnerGroup", typeof(UISprite))
	self.partnerName = self.groupTopLeft:ComponentByName("partnerName", typeof(UILabel))
	self.labelSkinName = self.groupTopLeft:ComponentByName("labelSkinName", typeof(UILabel))
	self.groupBottom = go:NodeByName("groupBottom").gameObject
	self.btnSmall = self.groupBottom:NodeByName("btnSmall").gameObject
	self.btnShow = self.groupBottom:NodeByName("btnShow").gameObject
	self.content = self.groupBottom:NodeByName("content").gameObject
	self.numGroup = self.content:NodeByName("numGroup").gameObject
	self.labelNum = self.content:ComponentByName("numGroup/labelNum", typeof(UILabel))
	self.numIcon = self.content:ComponentByName("numGroup/icon", typeof(UISprite))
	self.navGroup = self.content:NodeByName("navGroup").gameObject
	self.tabMask = self.navGroup:NodeByName("tabMask").gameObject
	self.btnExplore = self.content:NodeByName("btnExplore").gameObject
	self.arrowIcon = self.btnExplore:ComponentByName("arrowIcon", typeof(UISprite))
	self.labelExplore = self.btnExplore:ComponentByName("labelExplore", typeof(UILabel))
	self.skinCardItem = self.groupBottom:NodeByName("skinCardItem").gameObject
	self.layerItem = self.groupBottom:NodeByName("layerItem").gameObject
	self.skinPart = self.content:NodeByName("skinPart").gameObject
	self.scrollerSkin = self.skinPart:NodeByName("scrollerSkin").gameObject
	self.scrollViewSkin = self.skinPart:ComponentByName("scrollerSkin", typeof(UIScrollView))
	self.skinContent = self.scrollerSkin:NodeByName("skinContent").gameObject
	local wrapContent = self.scrollerSkin:ComponentByName("skinContent", typeof(MultiRowWrapContent))
	self.skinWrapContent = import("app.common.ui.FixedMultiWrapContent").new(self.scrollViewSkin, wrapContent, self.skinCardItem, ActivitySandShopSkinItem, self)
	self.itemPart = self.content:NodeByName("itemPart").gameObject
	self.scrollerItem = self.itemPart:NodeByName("scrollerItem").gameObject
	self.scrollViewItem = self.itemPart:ComponentByName("scrollerItem", typeof(UIScrollView))
	self.itemContent = self.scrollerItem:NodeByName("itemContent").gameObject
	self.skinEffectGroup = self.groupBottom:NodeByName("skinEffectGroup").gameObject
	self.cancelEffectGroup = self.skinEffectGroup:NodeByName("cancelEffectGroup").gameObject
	self.labelSkinDesc = self.skinEffectGroup:ComponentByName("labelSkinDesc", typeof(UILabel))
	self.groupEffect1 = self.skinEffectGroup:NodeByName("groupEffect1").gameObject
	self.groupEffect2 = self.skinEffectGroup:NodeByName("groupEffect2").gameObject
	self.groupTouch = self.skinEffectGroup:NodeByName("groupTouch").gameObject
	self.groupModel = self.skinEffectGroup:NodeByName("groupModel").gameObject
end

function ActivitySandShop:layout()
	self.labelExplore.text = __("UNFOLD_SKIN")
	self.selectItem = {
		skinID = 0
	}
	self.tab = require("app.common.ui.CommonTabBar").new(self.navGroup, 3, function (index)
		self:changeToggle(index)
	end, nil, {
		chosen = {
			color = Color.New2(4294967295.0),
			effectColor = Color.New2(1030530815)
		},
		unchosen = {
			color = Color.New2(1348707327)
		}
	})

	self.tab:setTexts({
		__("ACTIVITY_SAND_SHOP_TAB01"),
		__("ACTIVITY_SAND_SHOP_TAB02"),
		__("ACTIVITY_SAND_SHOP_TAB03")
	})

	self.labelNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.STAR_COIN)

	xyd.setUISpriteAsync(self.numIcon, nil, xyd.tables.itemTable:getIcon(xyd.ItemID.STAR_COIN))
	self:initSkinEffect()
	self:playEnterAnimation()
end

function ActivitySandShop:playEnterAnimation()
	local ids = xyd.tables.activitySandShopTable:getIDsByType(1)
	local buyTimes = self.activityData.detail_.buy_times
	local num = 0

	for i = 1, #ids do
		local limit = xyd.tables.activitySandShopTable:getLimit(ids[i])

		if buyTimes[ids[i]] < limit then
			num = num + 1
		end
	end

	if num > 1 then
		local count = 0
		local items = self.skinWrapContent:getItems()
		self.animationTime = self:getTimer(function ()
			count = (count + 1) % num

			self:changeItem(items[count + 1])
		end, 5, -1)

		self.animationTime:Start()
	end
end

function ActivitySandShop:initSkinEffect()
	if self.skinEffect1 then
		return
	end

	self.skinEffect1 = xyd.Spine.new(self.groupEffect1)
	self.skinEffect2 = xyd.Spine.new(self.groupEffect2)

	self.skinEffect1:setInfo("fx_ui_fazhen", function ()
		self.skinEffect1:SetLocalPosition(0, 0, -10)
		self.skinEffect1:SetLocalScale(1, 1, 1)
	end)
	self.skinEffect2:setInfo("fx_ui_fazhen", function ()
		self.skinEffect2:SetLocalPosition(0, 0, 0)
		self.skinEffect2:SetLocalScale(1, 1, 1)
	end)
	self.groupEffect1:SetActive(false)
	self.groupEffect2:SetActive(false)
end

function ActivitySandShop:playSkinEffect()
	local skinID = self.selectItem.skinID
	local modelID = xyd.tables.equipTable:getSkinModel(skinID)
	self.labelSkinDesc.text = xyd.tables.equipTextTable:getSkinDesc(skinID)
	local name = xyd.tables.modelTable:getModelName(modelID)

	if not modelID or not name then
		return
	end

	if self.skinModel and self.skinModel:getName() == name then
		self.skinModel:play("idle", 0, 1, nil, true)
	end

	NGUITools.DestroyChildren(self.groupModel.transform)

	self.skinModel = xyd.Spine.new(self.groupModel)
	local scale = xyd.tables.modelTable:getScale(modelID)

	self.skinModel:setInfo(name, function ()
		self.skinModel:SetLocalPosition(0, 0, 0)
		self.skinModel:SetLocalScale(scale, scale, 0.7)
		self.skinModel:play("idle", 0)
	end)

	if not self.skinEffect1 then
		return
	end

	if not self.skinEffect2 then
		return
	end

	self.skinEffect1:play("texiao01", 0, 1, nil, true)
	self.skinEffect2:play("texiao02", 0, 1, nil, true)
	self.groupEffect1:SetActive(true)
	self.groupEffect2:SetActive(true)
end

function ActivitySandShop:stopSkinEffect()
	if self.skinModel then
		self.skinModel:stop()
	end

	if self.skinEffect1 then
		self.skinEffect1:stop()
	end

	if self.skinEffect1 then
		self.skinEffect2:stop()
	end

	self.groupEffect1:SetActive(false)
	self.groupEffect2:SetActive(false)
end

function ActivitySandShop:changeToggle(index)
	if self.animationTime and index ~= 1 then
		self.animationTime:Stop()

		self.animationTime = nil
	end

	self.curTabIndex = index

	self:updateWrapContent()
end

function ActivitySandShop:updateWrapContent()
	self.skinPart:SetActive(self.curTabIndex ~= 3)
	self.itemPart:SetActive(self.curTabIndex == 3)

	if self.curTabIndex == 1 or self.curTabIndex == 2 then
		local ids = xyd.tables.activitySandShopTable:getIDsByType(self.curTabIndex)
		local buyTimes = self.activityData.detail_.buy_times

		dump(buyTimes)
		table.sort(ids, function (a, b)
			local canBuyA = xyd.tables.activitySandShopTable:getLimit(a) - buyTimes[a] > 0
			local canBuyB = xyd.tables.activitySandShopTable:getLimit(b) - buyTimes[b] > 0

			if canBuyA ~= canBuyB then
				return canBuyA
			else
				return a < b
			end
		end)
		dump(ids)
		self.skinWrapContent:setInfos(ids, {})

		local items = self.skinWrapContent:getItems()

		for _, item in pairs(items) do
			if item.data == ids[1] then
				self:changeItem(item)

				break
			end
		end

		self.scrollViewSkin:ResetPosition()

		return
	end

	if self.curTabIndex == 3 then
		local ids = xyd.tables.activitySandShopTable:getIDsByType(self.curTabIndex)
		local nowConditionValue = self.activityData:getNowConditionValue()
		local buyTimes = self.activityData.detail_.buy_times

		table.sort(ids, function (a, b)
			local conditionA = xyd.tables.activitySandShopTable:getCondition(a)
			local conditionB = xyd.tables.activitySandShopTable:getCondition(b)
			local canBuyA = xyd.tables.activitySandShopTable:getLimit(a) - buyTimes[a] > 0
			local canBuyB = xyd.tables.activitySandShopTable:getLimit(b) - buyTimes[b] > 0

			if conditionA ~= conditionB then
				return conditionA < conditionB
			elseif canBuyA ~= canBuyB then
				return canBuyA
			else
				return a < b
			end
		end)

		self.realDatas = {}
		local rowData = {}
		local maxCol = 4

		local function getCondition(id)
			return xyd.tables.activitySandShopTable:getCondition(id)
		end

		for index, id in ipairs(ids) do
			if #rowData == maxCol then
				table.insert(self.realDatas, rowData)

				rowData = {}
			end

			local conditionLastLayer = nil

			if #self.realDatas > 0 then
				conditionLastLayer = getCondition(self.realDatas[#self.realDatas][1])
			end

			local conditionNowLayer = getCondition(id)

			if index == 1 then
				table.insert(self.realDatas, {
					title = __("ACTIVITY_SAND_SHOP_TEXT01", getCondition(id))
				})
			end

			if conditionLastLayer and conditionNowLayer ~= conditionLastLayer then
				if #rowData > 0 then
					table.insert(self.realDatas, rowData)

					rowData = {}
				end

				table.insert(self.realDatas, {
					title = __("ACTIVITY_SAND_SHOP_TEXT01", getCondition(id))
				})
				table.insert(rowData, id)
			elseif maxCol > #rowData then
				table.insert(rowData, id)
			else
				table.insert(self.realDatas, rowData)

				rowData = {}

				table.insert(rowData, id)
			end
		end

		if #rowData > 0 then
			table.insert(self.realDatas, rowData)

			rowData = {}
		end

		if not self.itemWrapContent then
			self.itemWrapContent = LuaFlexibleWrapContent.new(self.scrollViewItem.gameObject, ActivitySandShopLayerItem, self.layerItem, self.itemContent, self.scrollViewItem, nil, self)
		end

		self.itemWrapContent:update()
		self.itemWrapContent:setDataNum(#self.realDatas)
	end
end

function ActivitySandShop:changeItem(item)
	if self.selectItem.skinID ~= item.skinID then
		if self.selectItem.item then
			self.selectItem.item:setSelectBg(false)
		end

		item:setSelectBg(true)

		self.selectItem.item = item
		self.selectItem.skinID = item.skinID

		self:changeModel()
	end
end

function ActivitySandShop:changeModel()
	xyd.setUISpriteAsync(self.partnerGroup, nil, "img_group" .. self.selectItem.item.group)

	self.labelSkinName.text = xyd.tables.itemTextTable:getName(self.selectItem.item.skinID)
	self.partnerName.text = xyd.tables.partnerTextTable:getName(self.selectItem.item.partnerTableID)
	local xy = xyd.tables.partnerPictureTable:getPartnerPicXY(self.selectItem.skinID)
	local scale = xyd.tables.partnerPictureTable:getPartnerPicScale(self.selectItem.skinID) * 0.75
	local dragonBoneID = xyd.tables.partnerPictureTable:getDragonBone(self.selectItem.skinID)

	if dragonBoneID and dragonBoneID ~= 0 then
		local res = xyd.tables.girlsModelTable:getResource(dragonBoneID)
		local texiaoName = xyd.tables.girlsModelTable:getTexiaoName(dragonBoneID)

		if self.partnerModel then
			self.partnerModel:destroy()
		end

		self.partnerModel = xyd.Spine.new(self.partnerNode)

		self.partnerModel:setInfo(res, function ()
			self.partnerModel:play(texiaoName, 0)
			self.partnerModel:SetLocalPosition(xy.x * 0.75, (-xy.y - 200) * 0.75, 0)
			self.partnerModel:SetLocalScale(scale, scale, scale)
		end)
	end

	if self.skinEffectGroup.activeSelf then
		self:playSkinEffect()
	end
end

function ActivitySandShop:register()
	UIEventListener.Get(self.btnShow).onClick = function ()
		if self.animationTime then
			self.animationTime:Stop()

			self.animationTime = nil
		end

		self.groupTopLeft:SetActive(false)
		self.groupBottom:SetActive(false)
	end

	UIEventListener.Get(self.btnSmall).onClick = function ()
		if self.animationTime then
			self.animationTime:Stop()

			self.animationTime = nil
		end

		self.skinEffectGroup:SetActive(true)
		self:playSkinEffect()
	end

	UIEventListener.Get(self.cancelEffectGroup).onClick = function ()
		self.skinEffectGroup:SetActive(false)
		self:stopSkinEffect()
	end

	UIEventListener.Get(self.bg).onClick = function ()
		if self.groupBottom.activeSelf == false then
			self.groupTopLeft:SetActive(true)
			self.groupBottom:SetActive(true)
		end
	end

	UIEventListener.Get(self.groupTouch).onClick = handler(self, self.onModelTouch)

	UIEventListener.Get(self.numGroup).onClick = function ()
		if self.animationTime then
			self.animationTime:Stop()

			self.animationTime = nil
		end

		xyd.WindowManager.get():openWindow("item_tips_window", {
			show_has_num = true,
			itemID = xyd.ItemID.STAR_COIN,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	UIEventListener.Get(self.btnExplore).onClick = function ()
		self:onClickBtnExplore()
	end

	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		self:onAward(event)
	end)
end

function ActivitySandShop:onClickBtnExplore()
	if self.isMoveList then
		return
	end

	self.tabMask:SetActive(true)

	self.isMoveList = true
	local content_height_ = {
		457,
		729
	}
	local state = xyd.checkCondition(self.view_state_ == 1, 2, 1)
	local action = self:getSequence(function ()
		local state = xyd.checkCondition(self.view_state_ == 1, 2, 1)
		self.view_state_ = state

		if self.view_state_ == 2 then
			self.labelExplore.text = __("FOLD_SKIN")

			self.arrowIcon:SetLocalScale(1, 1, 1)
		else
			self.labelExplore.text = __("UNFOLD_SKIN")

			self.arrowIcon:SetLocalScale(1, -1, 1)
		end

		self.isMoveList = false

		self.tabMask:SetActive(false)
	end)
	local contentWidget = self.content:GetComponent(typeof(UIWidget))
	local movebeginValue = content_height_[self.view_state_]
	local scrollerSkinBeginPos = self.scrollerSkin:Y()
	local scrollerItemBeginPos = self.scrollerItem:Y()
	local upFlag = content_height_[self.view_state_] < content_height_[state]
	local preholdValue = {}

	local function setter(value)
		contentWidget.height = value
		local moveOffset = value - movebeginValue

		self.scrollerSkin:Y(scrollerSkinBeginPos + moveOffset)
		self.scrollerItem:Y(scrollerItemBeginPos + moveOffset)
	end

	action:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), content_height_[self.view_state_], content_height_[state], 0.25))
	action:AppendCallback(function ()
		local sp = self.scrollerSkin:ComponentByName("", typeof(SpringPanel))

		if not tolua.isnull(sp) then
			sp.enabled = false
		end

		sp = self.scrollerItem:ComponentByName("", typeof(SpringPanel))

		if not tolua.isnull(sp) then
			sp.enabled = false
		end
	end)

	if self.view_state_ == 2 then
		self.btnShow:SetActive(true)
		self.btnSmall:SetActive(true)
	else
		self.btnShow:SetActive(false)
		self.btnSmall:SetActive(false)
	end
end

function ActivitySandShop:onModelTouch()
	if not self.skinModel or not self.skinModel:isValid() then
		return
	end

	local tableID = self.selectItem.item.partnerTableID
	local mp = xyd.tables.partnerTable:getEnergyID(tableID)
	local ack = xyd.tables.partnerTable:getPugongID(tableID)
	local skillID = 0

	if xyd.getServerTime() % 2 > 0 then
		skillID = mp

		self.skinModel:play("skill", 1, 1, function ()
			self.skinModel:play("idle", -1, 1)
		end)
	else
		skillID = ack

		self.skinModel:play("attack", 1, 1, function ()
			self.skinModel:play("idle", -1, 1)
		end)
	end

	if self.skill_sound_ then
		xyd.SoundManager.get():stopSound(self.skill_sound_)
	end

	self.skill_sound_ = tostring(xyd.tables.skillTable:getSound(skillID))

	xyd.SoundManager.get():playSound(self.skill_sound_)
end

function ActivitySandShop:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_SAND_SHOP then
		return
	end

	local buyId = self.activityData.buyId
	local type = xyd.tables.activitySandShopTable:getType(buyId)

	if type ~= 3 then
		local skinID = xyd.tables.activitySandShopTable:getAwards(buyId)[1]

		xyd.WindowManager.get():openWindow("summon_effect_res_window", {
			skins = {
				skinID
			},
			callback = function ()
				xyd.models.backpack:updateSkinCollect()
			end,
			notShowCamera = getSkinNum(skinID) > 1
		})
	else
		local award = xyd.tables.activitySandShopTable:getAwards(buyId)

		xyd.itemFloat({
			{
				item_id = award[1],
				item_num = award[2]
			}
		})
		__TRACE("222")
	end

	self:updateWrapContent()
end

function ActivitySandShop:onItemChange()
	self.labelNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.STAR_COIN)
end

function ActivitySandShopSkinItem:ctor(go, parent)
	ActivitySandShopSkinItem.super.ctor(self, go, parent)
end

function ActivitySandShopSkinItem:initUI()
	self.selectBg = self.go:ComponentByName("selectBg", typeof(UISprite))
	self.partner_card = self.go:NodeByName("partner_card").gameObject
	self.labelLimit = self.go:ComponentByName("labelLimit", typeof(UILabel))
	self.buyBtn = self.go:NodeByName("buyBtn").gameObject
	self.icon = self.buyBtn:ComponentByName("icon", typeof(UISprite))
	self.labelBuy = self.buyBtn:ComponentByName("labelBuy", typeof(UILabel))

	UIEventListener.Get(self.go).onClick = function ()
		if self.canChange then
			if self.parent.animationTime then
				self.parent.animationTime:Stop()

				self.parent.animationTime = nil
			end

			if self.selectItem and self.selectItem.skinID == self.skinID then
				self:showTips()
			else
				self.parent:changeItem(self)
			end
		end
	end

	UIEventListener.Get(self.buyBtn).onClick = function ()
		if self.parent.animationTime then
			self.parent.animationTime:Stop()

			self.parent.animationTime = nil
		end

		if xyd.models.backpack:getItemNumByID(self.buyCost[1]) < self.buyCost[2] then
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(self.buyCost[1])))
		else
			xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_BEACH_SHOP_TEXT03", self.buyCost[2], xyd.tables.itemTextTable:getName(self.buyCost[1])), function (yes)
				if yes then
					self.parent.activityData:recordBuyId(self.data)

					local params = json.encode({
						num = 1,
						award_id = tonumber(self.data)
					})

					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SAND_SHOP, params)
				end
			end)
		end
	end
end

function ActivitySandShopSkinItem:updateInfo()
	self.skinID = xyd.tables.activitySandShopTable:getAwards(self.data)[1]

	if not self.card then
		self.card = PartnerCard.new(self.partner_card, self.parent.scrollViewSkin.gameObject:GetComponent(typeof(UIPanel)))
	end

	self.partner_card.transform.localScale = Vector3(0.8833333333333333, 0.8833333333333333, 1)
	self.collectionID = xyd.tables.itemTable:getCollectionId(self.skinID)
	local tableList = xyd.tables.partnerPictureTable:getSkinPartner(self.skinID)
	self.group = xyd.tables.partnerTable:getGroup(tableList[1])
	self.partnerTableID = xyd.checkCondition(tableList and #tableList > 0, tableList[1], 0)

	self.card:resetData()
	self.card:setSkinCard({
		collectionID = self.collectionID,
		skin_id = self.skinID,
		tableID = self.partnerTableID,
		group = self.group,
		qlt = xyd.tables.collectionTable:getQlt(self.collectionID)
	})
	self.card:setSkinCollect(self.skinID == self.parent.selectItem.skinID)
	self.card:setDisplay()
	self.card:showRealSkinNum()
	self.card:setQltLowerThanPartnerName()

	self.buyCost = xyd.tables.activitySandShopTable:getCost(self.data)
	self.labelBuy.text = self.buyCost[2]

	xyd.setUISpriteAsync(self.icon, nil, xyd.tables.itemTable:getIcon(self.buyCost[1]))
	self:setBuyInfos()
end

function ActivitySandShopSkinItem:setSelectBg(flag)
	self.card:setSkinCollect(flag)
end

function ActivitySandShopSkinItem:showTips()
	xyd.WindowManager.get():openWindow("item_tips_window", {
		show_has_num = true,
		itemID = self.skinID,
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})
end

function ActivitySandShopSkinItem:setBuyInfos()
	local buyTimes = self.parent.activityData.detail_.buy_times[self.data]
	local limit = xyd.tables.activitySandShopTable:getLimit(self.data) - buyTimes
	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", limit)

	if limit == 0 then
		self.canChange = true

		xyd.setTouchEnable(self.buyBtn, false)
		xyd.applyChildrenGrey(self.buyBtn)
		self.selectBg:SetActive(true)
	else
		self.canChange = true

		self.selectBg:SetActive(false)
		xyd.applyChildrenOrigin(self.buyBtn)
		xyd.setTouchEnable(self.buyBtn, true)
	end
end

function ActivitySandShopLayerItem:ctor(go, parent, realIndex)
	ActivitySandShopLayerItem.super.ctor(self, go, parent)

	self.realIndex = realIndex
end

function ActivitySandShopLayerItem:initUI()
	local go = self.go

	for i = 1, 4 do
		self["item" .. i] = self.go:NodeByName("item" .. i).gameObject
		self["mainNode" .. i] = self["item" .. i]:NodeByName("mainNode").gameObject
		self["iconNode" .. i] = self["mainNode" .. i]:NodeByName("iconNode").gameObject
		self["labelLimit" .. i] = self["mainNode" .. i]:ComponentByName("labelLimit", typeof(UILabel))
		self["btnBuy" .. i] = self["mainNode" .. i]:NodeByName("btnBuy").gameObject
		self["costIcon" .. i] = self["btnBuy" .. i]:ComponentByName("costIcon", typeof(UISprite))
		self["labelCost" .. i] = self["btnBuy" .. i]:ComponentByName("labelCost", typeof(UILabel))
		self["shadow" .. i] = self["item" .. i]:ComponentByName("shadow", typeof(UISprite))
		self["buyNode" .. i] = self["item" .. i]:ComponentByName("buyNode", typeof(UISprite))
		self["has_buy_words" .. i] = self["buyNode" .. i]:ComponentByName("has_buy_words", typeof(UILabel))
	end

	self.titleItem = self.go:NodeByName("titleItem").gameObject
	self.labelTitle = self.titleItem:ComponentByName("labelTitle", typeof(UILabel))
	self.bg = self.titleItem:ComponentByName("bg", typeof(UISprite))

	for i = 1, 4 do
		UIEventListener.Get(self["btnBuy" .. i]).onClick = function ()
			if self.parent.animationTime then
				self.parent.animationTime:Stop()

				self.parent.animationTime = nil
			end

			local cost = xyd.tables.activitySandShopTable:getCost(self.data[i])

			if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(cost[1])))
			else
				local buyTimes = self.parent.activityData.detail_.buy_times[self.data[i]]
				local limit = xyd.tables.activitySandShopTable:getLimit(self.data[i]) - buyTimes

				xyd.WindowManager.get():openWindow("item_buy_window", {
					hide_min_max = false,
					item_no_click = false,
					cost = cost,
					max_num = limit,
					itemParams = {
						itemID = xyd.tables.activitySandShopTable:getAwards(self.data[i])[1],
						num = xyd.tables.activitySandShopTable:getAwards(self.data[i])[2]
					},
					buyCallback = function (num)
						if num <= 0 then
							return
						end

						self.parent.activityData:recordBuyId(self.data[i], num)

						local params = json.encode({
							award_id = tonumber(self.data[i]),
							num = num
						})

						xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SAND_SHOP, params)
					end
				})
			end
		end
	end

	self.icons = {}
	self.panel = self.parent.scrollViewItem.gameObject:GetComponent(typeof(UIPanel))
end

function ActivitySandShopLayerItem:refresh()
	self.data = self.parent.realDatas[-self.realIndex]

	if not self.data then
		self.go.gameObject:SetActive(false)

		return
	else
		self.go.gameObject:SetActive(true)
	end

	self.title = self.data.title

	for i = 1, 4 do
		self["item" .. i]:SetActive(not self.title and self.data[i] ~= nil)
	end

	self.titleItem:SetActive(self.title ~= nil)

	if self.title then
		self.labelTitle.text = self.title
	else
		for i = 1, #self.data do
			local award = xyd.tables.activitySandShopTable:getAwards(self.data[i])
			local params = {
				notShowGetWayBtn = true,
				show_has_num = false,
				scale = 0.7037037037037037,
				uiRoot = self["iconNode" .. i],
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}

			if self.icons[i] == nil then
				self.icons[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
			else
				self.icons[i]:setInfo(params)
			end

			local buyTimes = self.parent.activityData.detail_.buy_times[self.data[i]]
			local limit = xyd.tables.activitySandShopTable:getLimit(self.data[i]) - buyTimes
			self["labelLimit" .. i].text = __("BUY_GIFTBAG_LIMIT", limit)

			if limit <= 0 then
				xyd.setTouchEnable(self["btnBuy" .. i], false)
				xyd.applyChildrenGrey(self["btnBuy" .. i])

				self["has_buy_words" .. i].text = __("ALREADY_BUY")

				self["shadow" .. i]:SetActive(true)
				self["buyNode" .. i]:SetActive(true)
			else
				xyd.applyChildrenOrigin(self["btnBuy" .. i])
				xyd.setTouchEnable(self["btnBuy" .. i], true)
				self["shadow" .. i]:SetActive(false)
				self["buyNode" .. i]:SetActive(false)
			end

			local cost = xyd.tables.activitySandShopTable:getCost(self.data[i])
			self["labelCost" .. i].text = cost[2]

			xyd.setUISpriteAsync(self["costIcon" .. i], nil, xyd.tables.itemTable:getIcon(cost[1]))

			if xyd.tables.activitySandShopTable:getCondition(self.data[i]) < self.parent.activityData:getNowConditionValue() then
				self["shadow" .. i]:SetActive(false)
			else
				self["shadow" .. i]:SetActive(true)
			end
		end
	end

	self.go:ComponentByName("", typeof(UIWidget)).height = self:getHeight()
end

function ActivitySandShopLayerItem:getHeight()
	local data = self.parent.realDatas[-self.realIndex]

	if data and data.title then
		return 52
	else
		return 193
	end
end

return ActivitySandShop
