local BaseWindow = import(".BaseWindow")
local TowerFundGiftbagWindow = class("TowerFundGiftbagWindow", BaseWindow)
local LevelFundItem = class("LevelFundItem")

function LevelFundItem:ctor(goItem, id, maxId, awarded)
	self.goItem_ = goItem
	local transGo = goItem.transform
	self.id_ = tonumber(id)
	self.maxId_ = maxId or 0
	self.hasBuy_ = awarded
	self.iconList_ = {}
	self.progressBar_ = transGo:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressImg = transGo:ComponentByName("progressBar_/progressImg", typeof(UISprite))
	self.progressDesc = transGo:ComponentByName("progressBar_/progressLabel", typeof(UILabel))
	self.labelTitle_ = transGo:ComponentByName("labelTitle", typeof(UILabel))
	self.itemsGroup_ = transGo:ComponentByName("itemsGroup", typeof(UIGrid))

	self:initItem()
end

function LevelFundItem:initItem()
	local tower_id = xyd.tables.activityTowerFundGiftBagTable:getTowerId(self.id_)
	local rewards = xyd.tables.activityTowerFundGiftBagTable:getRewards(self.id_)
	local currentLevel = self.maxId_

	if tower_id <= currentLevel and self.hasBuy_ then
		self.ifGet_ = true
	end

	self.labelTitle_.text = __("TOWER_FUND_GIFT_BAG_CONDITION", tower_id)
	self.progressBar_.value = math.min(tower_id, currentLevel) / tower_id
	self.progressDesc.text = math.min(tower_id, currentLevel) .. "/" .. tower_id

	for _, reward in ipairs(rewards) do
		local icon = xyd.getItemIcon({
			itemID = reward[1],
			num = reward[2],
			uiRoot = self.itemsGroup_.gameObject,
			scale = Vector3(0.7, 0.7, 0.7)
		})

		table.insert(self.iconList_, icon)
		icon:AddUIDragScrollView()
	end

	self:updateIconState()
	self.itemsGroup_:Reposition()
end

function LevelFundItem:setInfo(id, maxId, awarded)
	self.id_ = tonumber(id)
	self.maxId_ = maxId or 0
	self.ifGet_ = awarded == 1
	local tower_id = xyd.tables.activityTowerFundGiftBagTable:getTowerId(self.id_)
	local rewards = xyd.tables.activityTowerFundGiftBagTable:getRewards(self.id_)
	local currentLevel = self.maxId_

	if tower_id <= currentLevel and self.hasBuy_ then
		self.ifGet_ = true
	end

	self:updateIconState()
end

function LevelFundItem:updateIconState()
	for _, icon in ipairs(self.iconList_) do
		if self.ifGet_ then
			icon:setChoose(true)
		else
			icon:setChoose(false)
		end
	end
end

function TowerFundGiftbagWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.dotList_ = {}
	self.topItemList_ = {}
	self.itemsList_ = {}
	self.id = xyd.ActivityID.TOWER_FUND_GIFTBAG
	self.giftBagId_ = xyd.tables.activityTowerFundGiftBagTable:getGiftBagID(1)
	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.TOWER_FUND_GIFTBAG)
	self.stage = self.activityData_.detail.awards_info.stage or 0
	self.activityData = self.activityData_

	xyd.db.misc:setValue({
		key = "tower_fund_giftbag_view_towerid",
		value = xyd.models.towerMap.stage
	})
	xyd.db.misc:setValue({
		value = "1",
		key = "ActivityFirstRedMark_" .. xyd.ActivityID.TOWER_FUND_GIFTBAG .. "_" .. self.activityData.end_time
	})
	self.activityData:updateRedMarkState()
	self:updateLevel()
end

function TowerFundGiftbagWindow:initWindow()
	self:getUIComponent()
	TowerFundGiftbagWindow.super.initWindow(self)
	self:onRegisterEvent()
	self:layout()
end

function TowerFundGiftbagWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.imgTitle_ = winTrans:ComponentByName("imgTitle_", typeof(UISprite))
	self.imgBg_ = winTrans:ComponentByName("imgBg_", typeof(UITexture))
	self.imgPageNum_ = winTrans:ComponentByName("imgPageNum_", typeof(UISprite))
	local group1 = winTrans:NodeByName("group1").gameObject
	local scroller = group1:NodeByName("scroller").gameObject
	local itemNode = scroller:NodeByName("itemsGroup").gameObject

	for i = 1, self.levelMax_ do
		self["itemsGroup" .. i] = NGUITools.AddChild(scroller, itemNode)
		self["itemsGroup_uiLayout" .. i] = self["itemsGroup" .. i]:GetComponent(typeof(UILayout))
	end

	self.scroller_ = scroller:GetComponent(typeof(UIScrollView))
	local itemsGroup_uipanel = scroller:GetComponent(typeof(UIPanel))
	itemsGroup_uipanel.depth = itemsGroup_uipanel.depth + 2
	local group2 = winTrans:NodeByName("group2").gameObject
	self.btnBuy_ = group2:NodeByName("btnBuy_").gameObject
	self.btnBuyLabel_ = self.btnBuy_:ComponentByName("button_label", typeof(UILabel))
	self.labelLimit_ = group2:ComponentByName("labelLimit_", typeof(UILabel))
	self.labelVip_ = group2:ComponentByName("labelVip_", typeof(UILabel))
	self.labelText_ = group2:ComponentByName("dumpIcon/labelText", typeof(UILabel))
	self.labelNum_ = group2:ComponentByName("dumpIcon/labelNum", typeof(UILabel))
	self.pageDotGroup_ = winTrans:ComponentByName("pageDotGroup", typeof(UIGrid))
	self.pageDot_ = winTrans:NodeByName("pageDotGroup/dotIcon")

	self.pageDot_:SetActive(false)

	self.labelDesc_ = winTrans:ComponentByName("descLabel", typeof(UILabel))
	self.arrowLeft_ = winTrans:ComponentByName("arrowLeft", typeof(UISprite))
	self.arrowRight_ = winTrans:ComponentByName("arrowRight", typeof(UISprite))
	self.awardScroll_ = winTrans:ComponentByName("scroll", typeof(UIScrollView))
	self.awardGroup_ = winTrans:ComponentByName("scroll/awardGroup", typeof(UILayout))
	self.littleItem = winTrans.transform:Find("fund_item")
end

function TowerFundGiftbagWindow:layout()
	self.chargeData_ = self.activityData_.detail.charges
	local startLevel = self.levelMax_

	for i = 1, self.levelMax_ do
		local charge = self.chargeData_[i]

		if charge.limit_times <= charge.buy_times then
			-- Nothing
		elseif i < startLevel then
			startLevel = i
		end
	end

	self.level_ = startLevel

	xyd.setUISpriteAsync(self.arrowLeft_, nil, "tower_fund_giftbag_arrow_2")
	xyd.setUISpriteAsync(self.arrowRight_, nil, "tower_fund_giftbag_arrow_2")
	self:initPage()
	self:updateTexture()
	self:updateBtnState()
	self:updateAwardItems()
	self:updateItemList()
	self:playPage()

	self.labelDesc_.text = __("TOWER_FUND_GIFT_BAG_DESC")

	if xyd.Global.lang == "ja_jp" then
		self.labelDesc_.width = 260
		self.labelDesc_.height = 120

		self.labelDesc_:X(50)
	end

	self.labelText_.text = __("ACTIVITY_WARMUP_PACK_TEXT05")
end

function TowerFundGiftbagWindow:updateTexture()
	if self.level_ == 1 then
		self.imgPageNum_.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.imgTitle_, nil, "tower_fund_giftbag_logo_" .. xyd.Global.lang, nil, , true)
	else
		self.imgPageNum_.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.imgTitle_, nil, "tower_fund_giftbag_logo_" .. xyd.Global.lang .. "2", nil, , true)
		xyd.setUISpriteAsync(self.imgPageNum_, nil, "activity_sports_num_" .. self.level_)
	end
end

function TowerFundGiftbagWindow:updateLevel()
	self.levelMax_, self.maxId_, self.stage_ = self.activityData_:getMaxLevel()

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.TOWER_FUND_GIFTBAG, function ()
		self.activityData_:setRedState(self.levelMax_)
	end)
end

function TowerFundGiftbagWindow:initPage()
	if self.levelMax_ <= 1 then
		self.pageDotGroup_.gameObject:SetActive(false)
		self.arrowLeft_.gameObject:SetActive(false)
		self.arrowRight_.gameObject:SetActive(false)
	else
		self.pageDotGroup_.gameObject:SetActive(true)
		self.arrowLeft_.gameObject:SetActive(true)
		self.arrowRight_.gameObject:SetActive(true)

		for i = 1, self.levelMax_ do
			local dotItem = NGUITools.AddChild(self.pageDotGroup_.gameObject, self.pageDot_.gameObject)

			dotItem:SetActive(true)
			table.insert(self.dotList_, dotItem)
		end

		self.pageDotGroup_:Reposition()
		self:updatePage()
	end
end

function TowerFundGiftbagWindow:updatePage()
	if self.levelMax_ <= 1 then
		return
	end

	for i = 1, self.levelMax_ do
		local dotItem = self.dotList_[i]
		local icon_ = dotItem:GetComponent(typeof(UISprite))

		if self.level_ == i then
			xyd.setUISpriteAsync(icon_, nil, "tower_fund_giftbag_mark_2")
		else
			xyd.setUISpriteAsync(icon_, nil, "tower_fund_giftbag_mark_1")
		end
	end
end

function TowerFundGiftbagWindow:updateItemList()
	local itemsGroup = self["itemsGroup" .. self.level_]

	for i = 1, self.levelMax_ do
		self["itemsGroup" .. i]:SetActive(self.level_ == i)
	end

	local itemsGroup_uiLayout = self["itemsGroup_uiLayout" .. self.level_]
	local ids = xyd.tables.activityTowerFundGiftBagTable:getIdsByLevel(self.level_)
	local charges = self.activityData.detail.charges[self.level_]
	local awards_info = self.activityData.detail.awards_info
	local data = {}
	local backData = {}
	local buyTimes = charges.buy_times

	for i in ipairs(ids) do
		local id = ids[i]

		if awards_info.awarded[id] == 1 then
			table.insert(backData, {
				id = id,
				maxId = self.stage_,
				awarded = buyTimes == 1
			})
		else
			table.insert(data, {
				id = id,
				maxId = self.stage_,
				awarded = buyTimes == 1
			})
		end
	end

	table.insertto(data, backData)

	for i in ipairs(data) do
		if not self.itemsList_[data[i].id] then
			local tmp = NGUITools.AddChild(itemsGroup, self.littleItem.gameObject)
			local item = LevelFundItem.new(tmp, data[i].id, data[i].maxId, data[i].awarded)
			self.itemsList_[data[i].id] = item
		else
			self.itemsList_[data[i].id]:setInfo(data[i].id, data[i].maxId, data[i].awarded)
		end
	end

	itemsGroup_uiLayout:Reposition()
	self.scroller_:ResetPosition()
end

function TowerFundGiftbagWindow:pageChange(changeNum)
	if self.level_ + changeNum < 1 then
		self.level_ = self.levelMax_
	elseif self.levelMax_ < self.level_ + changeNum then
		self.level_ = 1
	else
		self.level_ = self.level_ + changeNum
	end

	self:updatePage()
	self:updateTexture()
	self:updateBtnState()
	self:updateAwardItems()
	self:updateItemList()
	self.awardScroll_:ResetPosition()
end

function TowerFundGiftbagWindow:updateAwardItems()
	local totalAwards = xyd.tables.activityTowerFundGiftBagTable:getTotalAwards(self.level_)
	local datas = {}

	for k, v in pairs(totalAwards) do
		table.insert(datas, {
			item_id = tonumber(k),
			item_num = v
		})
	end

	table.sort(datas, function (a, b)
		return a.item_id < b.item_id
	end)

	for idx, info in ipairs(datas) do
		local params = {
			uiRoot = self.awardGroup_.gameObject,
			itemID = info.item_id,
			num = info.item_num,
			scale = Vector3(0.7, 0.7, 0.7)
		}

		if not self.topItemList_[idx] then
			self.topItemList_[idx] = xyd.getItemIcon(params)
		else
			NGUITools.Destroy(self.topItemList_[idx]:getGameObject())

			self.topItemList_[idx] = xyd.getItemIcon(params)
		end

		xyd.setDragScrollView(self.topItemList_[idx].go, self.awardScroll_)
	end

	for idx, itemIcon in ipairs(self.topItemList_) do
		if idx > #datas then
			itemIcon:SetActive(false)
		else
			itemIcon:SetActive(true)
		end
	end

	self.awardGroup_:Reposition()
	self.awardGroup_.transform:X(-98)
end

function TowerFundGiftbagWindow:updateBtnState()
	self.giftBagId_ = xyd.tables.activityTowerFundGiftBagTable:getGiftBagIDByLevel(self.level_)
	local tmpLable1 = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftBagId_)) or ""
	local tmpLable2 = tostring(xyd.tables.giftBagTextTable:getCharge(self.giftBagId_)) or ""
	self.btnBuyLabel_.text = tmpLable1 .. tmpLable2
	self.labelVip_.text = "+" .. tostring(tostring(xyd.tables.giftBagTable:getVipExp(self.giftBagId_))) .. " VIP EXP"
	local pointList = xyd.tables.miscTable:split("activity_tower_fund_bonus", "value", "|")
	self.labelNum_.text = (tostring(pointList[self.level_]) or "") .. "%"
	local activityData = self.activityData
	local buyTimes = activityData.detail.charges[self.level_].buy_times
	local limit = activityData.detail.charges[self.level_].limit_times
	self.labelLimit_.text = __("BUY_GIFTBAG_LIMIT", tostring(limit - buyTimes))

	if limit <= buyTimes then
		xyd.applyChildrenGrey(self.btnBuy_.gameObject)

		self.btnBuy_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	else
		xyd.applyChildrenOrigin(self.btnBuy_.gameObject)

		self.btnBuy_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end
end

function TowerFundGiftbagWindow:onRegisterEvent()
	UIEventListener.Get(self.btnBuy_).onClick = function ()
		if self.level_ > 1 and self.activityData_.detail.charges[self.level_ - 1].buy_times <= 0 then
			xyd.showToast(__("TOWER_FUND_GIFT_BAG_LIMIT_TIPS"))

			return
		end

		xyd.SdkManager:get():showPayment(self.giftBagId_)
	end

	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, function (self, evt)
		local gift_bag_id = evt.data.giftbag_id

		if xyd.tables.giftBagTable:getActivityID(gift_bag_id) ~= self.id then
			return
		end

		self:updateBtnState()
		self:updateItemList()
	end))

	UIEventListener.Get(self.arrowLeft_.gameObject).onClick = function ()
		self:pageChange(-1)
	end

	UIEventListener.Get(self.arrowRight_.gameObject).onClick = function ()
		self:pageChange(1)
	end

	UIEventListener.Get(self.arrowLeft_.gameObject).onLongPress = function ()
		self:pageChange(-1)
	end

	UIEventListener.Get(self.arrowRight_.gameObject).onLongPress = function ()
		self:pageChange(1)
	end
end

function TowerFundGiftbagWindow:playPage()
	local positionLeft = -324
	local positionRight = 324

	if self.sequence1_ then
		self.sequence1_:Kill(false)

		self.sequence1_ = nil
	end

	if self.sequence2_ then
		self.sequence2_:Kill(false)

		self.sequence2_ = nil
	end

	function self.playAni2_()
		self.sequence2_ = self:getSequence()

		self.sequence2_:Insert(0, self.arrowLeft_.transform:DOLocalMoveX(positionLeft - 6, 1))
		self.sequence2_:Insert(1, self.arrowLeft_.transform:DOLocalMoveX(positionLeft + 6, 1))
		self.sequence2_:Insert(0, self.arrowRight_.transform:DOLocalMoveX(positionRight + 6, 1))
		self.sequence2_:Insert(1, self.arrowRight_.transform:DOLocalMoveX(positionRight - 6, 1))
		self.sequence2_:AppendCallback(function ()
			self.playAni1_()
		end)
	end

	function self.playAni1_()
		self.sequence1_ = self:getSequence()

		self.sequence1_:Insert(0, self.arrowLeft_.transform:DOLocalMoveX(positionLeft - 6, 1))
		self.sequence1_:Insert(1, self.arrowLeft_.transform:DOLocalMoveX(positionLeft + 6, 1))
		self.sequence1_:Insert(0, self.arrowRight_.transform:DOLocalMoveX(positionRight + 6, 1))
		self.sequence1_:Insert(1, self.arrowRight_.transform:DOLocalMoveX(positionRight - 6, 1))
		self.sequence1_:AppendCallback(function ()
			self.playAni2_()
		end)
	end

	self.playAni1_()
end

return TowerFundGiftbagWindow
