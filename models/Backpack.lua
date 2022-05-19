local Backpack = class("Backpack", import(".BaseModel"))
local ItemTable = xyd.tables.itemTable

function Backpack:ctor()
	Backpack.super.ctor(self)

	self.items_ = {}
	self.avatars_ = {}
	self.newAvatars_ = {}
	self.pictures_ = {}
	self.pictures_explore = {}
	self.newPictures_ = {}
	self.isVipChange_ = false
	self.isLevChange_ = false
	self.isDebrisChange_ = false
	self.redPoint_ = false
	self.playerLev_ = -1
	self.playerVip_ = -1
	self.isHasSkin_ = false
	self.backpackShowTypeArr = {}

	for i in pairs(xyd.BackpackShowType) do
		self.backpackShowTypeArr[xyd.BackpackShowType[i]] = {}
	end
end

function Backpack:onRegister()
	Backpack.super.onRegister(self)
	self:registerEvent(xyd.event.GET_BACKPACK_INFO, handler(self, self.onBackpackInfo))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
	self:registerEvent(xyd.event.ITEM_LIMIT, handler(self, self.onItemLimit))
end

function Backpack:onItemLimit(event)
	local item_id = event.data.item_id

	xyd.alertTips(__("BAG_NUM_LIMIT_TEXT1", xyd.tables.itemTable:getName(item_id)))
end

function Backpack:reqBackpackInfo()
	xyd.Backend.get():request(xyd.mid.GET_BACKPACK_INFO, {}, "GET_BACKPACK_INFO")
end

function Backpack:composeItem(itemID, itemNum)
	local msg = messages_pb:compose_item_req()
	msg.item.item_id = tonumber(itemID)
	msg.item.item_num = itemNum

	xyd.Backend.get():request(xyd.mid.COMPOSE_ITEM, msg)
end

function Backpack:composeDatesGifts(itemID, itemNum)
	local msg = messages_pb.dates_gifts_compose_req()
	msg.item_id = tonumber(itemID)
	msg.item_num = itemNum

	xyd.Backend.get():request(xyd.mid.DATES_GIFTS_COMPOSE, msg, "DATES_GIFTS_COMPOSE")
end

function Backpack:onBackpackInfo(event)
	if event.data then
		dump(xyd.decodeProtoBuf(event.data))
		self:resetInfo()

		self.items_ = event.data.items
		self.playerLev_ = -1
		self.playerVip_ = -1

		self:initItems_withBagType()
		self:updateRedMark()
		self:updateSkinType()
		self:checkFuncOpenAward()
	end
end

function Backpack:updateRedMark()
	local flag = self:checkCanCompose()

	if flag ~= self.redPoint_ then
		self.redPoint_ = flag

		xyd.models.redMark:setMark(xyd.RedMarkType.BACKPACK, flag)
	end

	local flag2 = self:checkOverItem()
	local alertTime = xyd.db.misc:getValue("backpack_over_item_alert")

	if flag2 and (not alertTime or not xyd.isSameDay(alertTime, xyd.getServerTime())) then
		xyd.models.redMark:setMark(xyd.RedMarkType.BACKPACK_OVER_ITEM, true)
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.BACKPACK_OVER_ITEM, false)
	end
end

function Backpack:resetInfo()
	self.items_ = {}
	self.avatars_ = {}
	self.newAvatars_ = {}
	self.pictures_ = {}
	self.pictures_explore = {}
	self.newPictures_ = {}
	self.isVipChange_ = false
	self.isLevChange_ = false
	self.isDebrisChange_ = false
	self.redPoint_ = false
	self.playerLev_ = -1
	self.playerVip_ = -1
	self.isHasSkin_ = false
	self.skinCollect = {}
end

function Backpack:updateItems(items)
	local hasSkin = false
	local isNewDress = false

	for i = 1, #items do
		local item = items[i]

		self:updateItemNumByID(item.item_id, tonumber(item.item_num))

		if ItemTable:getQuality(item.item_id) == xyd.QualityColor.GREEN and xyd.ItemType.WEAPON <= ItemTable:getType(item.item_id) and ItemTable:getType(item.item_id) <= xyd.ItemType.SHOES then
			xyd.models.advertiseComplete:achieve(xyd.ACHIEVEMENT_TYPE.GET_GREEN_EQUIP, tonumber(item.item_num))
		end

		if ItemTable:getType(item.item_id) == xyd.ItemType.SKIN then
			hasSkin = true
		end

		if ItemTable:getType(item.item_id) == xyd.ItemType.DRESS then
			isNewDress = true

			xyd.models.dress:updateItems(item)
		end

		if ItemTable:getType(item.item_id) == xyd.ItemType.DRESS_FRAGMENT then
			xyd.models.dress:updateDressFragment(item)
		end
	end

	if hasSkin then
		self:setSkinType(true)
	end

	if isNewDress then
		xyd.models.dress:initItemsSort()
	end

	if #self.newAvatars_ > 0 then
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.NEW_AVATARS
		})
	end

	if #self.newPictures_ > 0 then
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.NEW_PICTURES
		})
	end

	if self.isVipChange_ and self.playerVip_ > -1 then
		self.isVipChange_ = false
		local oldVip = self.playerVip_
		self.playerVip_ = -1
		local newVip = self:getVipLev()

		if oldVip ~= newVip then
			local eventObj = {
				name = xyd.event.VIP_CHANGE,
				data = {
					oldVip = oldVip,
					newVip = newVip
				}
			}

			xyd.EventDispatcher.outer():dispatchEvent(eventObj)
			xyd.EventDispatcher.inner():dispatchEvent(eventObj)
		end
	end

	if self.isLevChange_ and self.playerLev_ > -1 then
		self.isLevChange_ = false
		local oldLev = self.playerLev_
		self.playerLev_ = -1
		local newLev = self:getLev()

		if oldLev ~= newLev then
			local eventObj = {
				name = xyd.event.LEV_CHANGE,
				data = {
					oldLev = oldLev,
					newLev = newLev
				}
			}

			xyd.EventDispatcher.outer():dispatchEvent(eventObj)
			xyd.EventDispatcher.inner():dispatchEvent(eventObj)
			self:checkFuncOpenAward()

			if tonumber(newLev) == 20 or tonumber(newLev) == 50 or tonumber(newLev) == 70 or tonumber(newLev) == 80 or tonumber(newLev) == 90 or tonumber(newLev) == 100 then
				xyd.SdkManager.get():eventTracking("lv" .. newLev)
			end

			xyd.models.activity:updateNeedOpenActivityAloneEnter(xyd.AcitvityLimt.LV, newLev)
		end
	end

	if self.isDebrisChange_ then
		self.isDebrisChange_ = false

		self:updateRedMark()

		self.canComposeDebrisDatas = nil

		self:getCanComposeDebris()
	end
end

function Backpack:setSkinType(flag)
	self.isHasSkin_ = flag

	if flag then
		self:checkFuncOpenAward()
	end
end

function Backpack:isHasSkin()
	return self.isHasSkin_
end

function Backpack:updateItemNumByID(itemID, num)
	self:checkAvatar(itemID)

	if itemID == xyd.ItemID.FIRE_MATCH then
		local fireworkData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FIREWORK)

		if fireworkData then
			fireworkData:updateFireMatchGet(num - self:getItemNumByID(xyd.ItemID.FIRE_MATCH))
		end
	end

	local flag = false

	for i = #self.items_, 1, -1 do
		local item = self.items_[i]

		if item.item_id == itemID then
			local type_ = ItemTable:showInBagType(itemID)
			item.item_num = num
			local stackLimit = ItemTable:stackLimit(itemID)

			if type_ ~= nil and self.backpackShowTypeArr[type_][itemID] ~= nil then
				self.backpackShowTypeArr[type_][itemID].itemNum = item.item_num
			end

			if item.item_num <= 0 and itemID ~= xyd.ItemID.CRYSTAL then
				table.remove(self.items_, i)

				if type_ ~= nil and self.backpackShowTypeArr[type_][itemID] ~= nil then
					self.backpackShowTypeArr[type_][itemID] = nil
				end
			elseif stackLimit and stackLimit > 0 and stackLimit < item.item_num then
				item.item_num = ItemTable:stackLimit(itemID)

				if type_ ~= nil and self.backpackShowTypeArr[type_][itemID] ~= nil then
					self.backpackShowTypeArr[type_][itemID].itemID = item.item_num
				end
			end

			flag = true

			break
		end
	end

	if not flag and num > 0 then
		local type_ = ItemTable:showInBagType(itemID)

		if not type_ then
			return
		end

		table.insert(self.items_, {
			item_id = itemID,
			item_num = num
		})

		if self.backpackShowTypeArr[type_][itemID] == nil then
			self.backpackShowTypeArr[type_][itemID] = {
				itemID = itemID,
				itemNum = num
			}
		end
	end

	local isHide = self:checkIsHide(itemID)

	if isHide then
		local type_ = ItemTable:showInBagType(itemID)
		self.backpackShowTypeArr[type_][itemID] = nil
	end

	if itemID == xyd.ItemID.VIP_EXP then
		self.isVipChange_ = true
	elseif itemID == xyd.ItemID.EXP then
		self.isLevChange_ = true
	end

	if not self.isDebrisChange_ and ItemTable:isShowInBag(itemID) and ItemTable:showInBagType(itemID) == xyd.BackpackShowType.DEBRIS then
		self.isDebrisChange_ = true
	end
end

function Backpack:getItemNumByID(itemID)
	local num = 0

	for i = 1, #self.items_ do
		local item = self.items_[i]

		if item.item_id == itemID then
			num = item.item_num

			break
		end
	end

	return tonumber(num)
end

function Backpack:getItems()
	return self.items_
end

function Backpack:sellItem(itemID, itemNum)
	local msg = messages_pb.sell_item_req()
	msg.item.item_id = itemID
	msg.item.item_num = itemNum

	xyd.Backend.get():request(xyd.mid.SELL_ITEM, msg)
end

function Backpack:useItem(itemID, itemNum)
	local msg = messages_pb.use_item_req()
	msg.item.item_id = itemID
	msg.item.item_num = itemNum

	xyd.Backend.get():request(xyd.mid.USE_ITEM, msg)
end

function Backpack:sendDatesGifts(itemID, itemNum, partnerID)
	local msg = messages_pb.send_gift_req()
	msg.item_id = itemID
	msg.item_num = itemNum
	msg.partner_id = partnerID

	xyd.Backend.get():request(xyd.mid.SEND_GIFT, msg)
end

function Backpack:onItemChange(event)
	if not xyd.Global.isLoadingFinish then
		return
	end

	local data = event.data.items
	local tempStr_color = "\n"
	tempStr_color = self:editorPrintStr(event, tempStr_color, true)
	local tempStr = "\n"

	if UNITY_EDITOR then
		tempStr = self:editorPrintStr(event, tempStr)
	end

	self:updateItems(data)
	self:checkAvailableEquipment()
	self:checkCollectionShopRed()
	xyd.models.activity:itemChangeBcackUpateRed(event.data.items)

	if UNITY_EDITOR then
		self:giftBuyTest(event)
		LuaManager.Instance:TestItemChange(tempStr)
	end

	print("↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓  itemChange  ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓")
	print(tempStr_color)
	print("↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑  itemChange  ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑")
end

function Backpack:checkCollectionShopRed(isSetting)
	local collectShopNum = tonumber(xyd.db.misc:getValue("collection_shop_red")) or 0
	local hasRed = false
	local pointTab = xyd.tables.miscTable:split2num("collection_point_level", "value", "|")
	local hasLev = false

	for _, point in pairs(pointTab) do
		if point <= self:getItemNumByID(xyd.ItemID.COLLECT_COIN) then
			hasLev = true

			if collectShopNum < point then
				if isSetting then
					xyd.db.misc:setValue({
						key = "collection_shop_red",
						value = point
					})
				else
					hasRed = true
				end
			end
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.COLLECTION_SHOP, hasRed)

	local timeRed = false
	local mondayTime = xyd.db.misc:getValue("collection_point_shop_monday") or 0

	if hasLev and tonumber(mondayTime) < xyd.getServerTime() then
		timeRed = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.COLLECTION_SHOP_2, timeRed)
end

function Backpack:getMaxExp()
	return xyd.tables.expPlayerTable:allExp(self:getMaxLev())
end

function Backpack:getMaxLev()
	return #xyd.tables.expPlayerTable:getIDs()
end

function Backpack:getMaxVipLev()
	local ids = xyd.tables.vipTable:getIDs()

	return #ids - 1
end

function Backpack:getMaxVipExp()
	return xyd.tables.vipTable:needExp(self:getMaxVipLev())
end

function Backpack:getLev()
	if self.playerLev_ > -1 then
		return self.playerLev_
	end

	local exp = self:getItemNumByID(xyd.ItemID.EXP)
	exp = exp or 0

	if self:getMaxExp() < exp then
		self.playerLev_ = self:getMaxLev()
		xyd.Global.playerLev = self.playerLev_

		return self.playerLev_
	end

	for i = 1, self:getMaxLev() do
		if exp < xyd.tables.expPlayerTable:allExp(i) then
			self.playerLev_ = i - 1
			xyd.Global.playerLev = self.playerLev_

			return self.playerLev_
		end
	end

	self.playerLev_ = self:getMaxLev()
	xyd.Global.playerLev = self.playerLev_

	return self.playerLev_
end

function Backpack:getVipLev()
	if self.playerVip_ > -1 then
		return self.playerVip_
	end

	local vipExp = self:getItemNumByID(xyd.ItemID.VIP_EXP)
	vipExp = vipExp or 0

	if self:getMaxVipExp() < vipExp then
		self.playerVip_ = self:getMaxVipLev()

		return self.playerVip_
	end

	for i = 0, self:getMaxVipLev() do
		if vipExp < xyd.tables.vipTable:needExp(i) then
			self.playerVip_ = i - 1

			return self.playerVip_
		end
	end

	self.playerVip_ = self:getMaxVipLev()

	return self.playerVip_
end

function Backpack:getNextLevNeedVipExp()
	local vipExp = self:getItemNumByID(xyd.ItemID.VIP_EXP) or 0

	if self:getMaxVipExp() <= vipExp then
		return 0
	end

	local lev = self:getVipLev()

	return xyd.tables.vipTable:needExp(lev + 1) - vipExp
end

function Backpack:getMana()
	return self:getItemNumByID(xyd.ItemID.MANA)
end

function Backpack:getCrystal()
	return self:getItemNumByID(xyd.ItemID.CRYSTAL)
end

function Backpack:getAvatars()
	if #self.avatars_ > 0 then
		return self.avatars_
	end

	local items = self:getItems()
	local ids = {}

	for _, item in ipairs(items) do
		local type_ = ItemTable:getType(item.item_id)

		if type_ == xyd.ItemType.AVATAR or type_ == xyd.ItemType.HERO or type_ == xyd.ItemType.FAKE_PARTNER_SKIN then
			table.insert(ids, item.item_id)
		elseif type_ == xyd.ItemType.SKIN_PICTURE then
			local id = ItemTable:getSkinID(item.item_id)

			table.insert(ids, id)
		end
	end

	self.avatars_ = ids

	return ids
end

function Backpack:getPictures()
	if #self.pictures_ > 0 then
		return self.pictures_
	end

	local items = self:getItems()
	local ids = {}

	for _, item in ipairs(items) do
		local type_ = ItemTable:getType(item.item_id)

		if type_ == xyd.ItemType.HERO or type_ == xyd.ItemType.KANBAN or type_ == xyd.ItemType.FAKE_PARTNER_SKIN then
			table.insert(ids, item.item_id)
		elseif type_ == xyd.ItemType.SKIN_PICTURE then
			local id = ItemTable:getSkinID(item.item_id)

			table.insert(ids, id)
		end
	end

	self.pictures_ = ids

	return ids
end

function Backpack:getExplorePictures()
	if #self.pictures_explore > 0 then
		return self.pictures_explore
	end

	local items = self:getItems()
	local ids = {}

	for _, item in ipairs(items) do
		local type_ = ItemTable:getType(item.item_id)

		if type_ == xyd.ItemType.HERO then
			table.insert(ids, item.item_id)
		elseif type_ == xyd.ItemType.SKIN_PICTURE then
			local id = ItemTable:getSkinID(item.item_id)

			table.insert(ids, id)
		end
	end

	self.pictures_explore = ids

	return ids
end

function Backpack:checkAvatar(id)
	local itemID = id
	local type_ = ItemTable:getType(itemID)

	if type_ == xyd.ItemType.SKIN_PICTURE then
		itemID = ItemTable:getSkinID(id)
		type_ = xyd.ItemType.SKIN
	end

	if type_ == xyd.ItemType.FAKE_PARTNER_SKIN then
		type_ = xyd.ItemType.HERO
	end

	if type_ == xyd.ItemType.AVATAR or type_ == xyd.ItemType.HERO or type_ == xyd.ItemType.SKIN or type_ == xyd.ItemType.KANBAN then
		if #self.avatars_ <= 0 or #self.pictures_ <= 0 then
			self:getAvatars()
			self:getPictures()
		end

		if table.indexof(self.avatars_, itemID) == false and type_ ~= xyd.ItemType.KANBAN then
			local isInsetNewAvatars = true

			if ItemTable:getType(itemID) == xyd.ItemType.FAKE_PARTNER_SKIN then
				local tianyiIndex = xyd.models.slot:getCheckTianYiFakePartnerSkin(itemID)

				if tianyiIndex == 3 then
					isInsetNewAvatars = false
				end
			end

			if isInsetNewAvatars then
				table.insert(self.newAvatars_, itemID)
			end

			table.insert(self.avatars_, itemID)
		end

		if (type_ == xyd.ItemType.HERO or type_ == xyd.ItemType.SKIN or type_ == xyd.ItemType.KANBAN) and table.indexof(self.pictures_, itemID) == false then
			table.insert(self.newPictures_, itemID)
			table.insert(self.pictures_, itemID)
		end

		if #self.pictures_explore <= 0 then
			self:getExplorePictures()
		end

		if (type_ == xyd.ItemType.HERO or type_ == xyd.ItemType.SKIN) and table.indexof(self.pictures_, itemID) == false then
			table.insert(self.pictures_explore, itemID)
		end
	end
end

function Backpack:getNewAvatars()
	return self.newAvatars_
end

function Backpack:clearNewAvatars()
	self.newAvatars_ = {}
end

function Backpack:getNewPictures()
	return self.newPictures_
end

function Backpack:clearNewPictures()
	self.newPictures_ = {}
end

function Backpack:checkCanCompose()
	local datas = self:getItems_withBagType(xyd.BackpackShowType.DEBRIS)
	local canCompose = false

	for i in pairs(datas) do
		local itemID = datas[i].itemID
		local itemNum = tonumber(datas[i].itemNum)

		if not canCompose then
			local itemType = ItemTable:getType(itemID)
			local cost = nil

			if itemType == xyd.ItemType.HERO_DEBRIS or itemType == xyd.ItemType.HERO_RANDOM_DEBRIS then
				cost = ItemTable:partnerCost(itemID)
			elseif itemType == xyd.ItemType.DRESS_DEBRIS then
				local dress_summon_id = xyd.tables.itemTable:getSummonID(itemID)
				cost = xyd.tables.summonDressTable:getCost(dress_summon_id)
			else
				cost = ItemTable:treasureCost(itemID)
			end

			if cost[2] <= itemNum then
				canCompose = true

				break
			end
		end
	end

	return canCompose
end

function Backpack:checkOverItem()
	local datas = self:getItems_withBagType(xyd.BackpackShowType.ITEM)
	local isOver = false

	for i in pairs(datas) do
		local itemID = datas[i].itemID
		local itemNum = tonumber(datas[i].itemNum)

		if not isOver then
			local limitNum = xyd.tables.itemTable:stackLimit(itemID)

			if limitNum and limitNum > 0 and itemNum / limitNum > 0.9 then
				isOver = true

				break
			end
		end
	end

	return isOver
end

function Backpack:getOverItems()
	local datas = self:getItems_withBagType(xyd.BackpackShowType.ITEM)
	local list = {}

	for i in pairs(datas) do
		local itemID = datas[i].itemID
		local itemNum = tonumber(datas[i].itemNum)
		local limitNum = xyd.tables.itemTable:stackLimit(itemID)

		if limitNum and limitNum > 0 and itemNum / limitNum > 0.9 then
			table.insert(list, itemID)
		end
	end

	return list
end

function Backpack:checkfiveStarCompose()
	local datas = self:getItems_withBagType(xyd.BackpackShowType.DEBRIS)
	local canCompose = false
	local beforeNum = 1

	for i in pairs(datas) do
		local itemID = datas[i].itemID
		local itemNum = tonumber(datas[i].itemNum)

		if ItemTable:isShowInBag(itemID) then
			local itemType = ItemTable:getType(itemID)
			local cost = nil

			if itemType == xyd.ItemType.HERO_RANDOM_DEBRIS or itemType == xyd.ItemType.ARTIFACT_DEBRIS then
				beforeNum = beforeNum + 1
			elseif itemType == xyd.ItemType.HERO_DEBRIS then
				cost = ItemTable:partnerCost(itemID)
				local qlt = ItemTable:getQuality(itemID)

				if qlt >= 5 and cost[2] <= itemNum then
					canCompose = true
				end
			end
		end
	end

	if canCompose then
		return beforeNum
	end

	return -1
end

function Backpack:getItemByType(type)
	local totalItems = {}

	for i, v in ipairs(self.items_) do
		local item = self.items_[i]

		if ItemTable:getType(item.item_id) == type then
			table.insert(totalItems, item)
		end
	end

	return totalItems
end

function Backpack:checkFuncOpenAward()
	local funcIDs = xyd.tables.functionTable:getGuideFuncIDs(self:getLev())

	for _, id in ipairs(funcIDs) do
		local awardItemID = xyd.tables.funcGuideTable:getAwardItem(id)

		if awardItemID > 0 and self:getItemNumByID(awardItemID) <= 0 then
			self:addFuncOpenID(id)
		end
	end
end

function Backpack:addFuncOpenID(funcID)
	xyd.GuideController.get().isLevChange_ = true
	local msg = messages_pb:add_func_id_req()
	msg.func_id = funcID

	xyd.Backend.get():request(xyd.mid.ADD_FUNC_ID, msg)
end

function Backpack:getSkinCollect()
	return self.skinCollect
end

function Backpack:updateSkinType()
	local hasSkin = false

	for i = 1, #self.items_ do
		local item = self.items_[i]

		if xyd.tables.itemTable:getType(item.item_id) == xyd.ItemType.SKIN then
			hasSkin = true
			self.skinCollect[item.item_id] = true
		end
	end

	self:setSkinType(hasSkin)
end

function Backpack:setSkinType(flag)
	self.isHasSkin_ = flag

	if flag then
		self:checkFuncOpenAward()
	end
end

function Backpack:isHasSkin()
	return self.isHasSkin_
end

function Backpack:updateSkinCollect()
	for i = 1, #self.items_ do
		local item = self.items_[i]

		if xyd.tables.itemTable:getType(item.item_id) == xyd.ItemType.SKIN then
			self.skinCollect[item.item_id] = true
		end
	end
end

function Backpack:checkAvailableEquipment()
	local partnerNum = xyd.tables.miscTable:getNumber("player_red_point_partner_num", "value")
	local sortedPartners = xyd.models.slot:getSortedPartners()

	if not sortedPartners then
		return
	end

	local partners = sortedPartners[xyd.partnerSortType.POWER .. "_0"]

	if not partners then
		return
	end

	local levelUpHeroList = {}
	local equipHeroList = {}
	local MAP_TYPE_2_POS = {
		["6"] = 0,
		["7"] = 1,
		["8"] = 2,
		["9"] = 3,
		["11"] = 5
	}
	local itemTable = xyd.tables.itemTable
	local bp_equips = {}
	local datas = self:getItems()

	for j in pairs(datas) do
		local itemID = datas[j].item_id
		local itemNum = datas[j].item_num
		local item = {
			itemID = itemID,
			itemNum = itemNum
		}
		local pos = MAP_TYPE_2_POS[tostring(itemTable:getType(itemID))]

		if pos ~= nil then
			bp_equips[pos] = bp_equips[pos] or {}

			table.insert(bp_equips[pos], item)
		end
	end

	partnerNum = xyd.checkCondition(partnerNum < #partners, partnerNum, #partners)

	for i = 1, partnerNum do
		local partnerId = partners[i]
		local np = xyd.models.slot:getPartner(partnerId)
		local equips = np:getEquipment()
		local canChangeEquip = false

		for index, value in pairs(bp_equips) do
			local old_i_lv = xyd.tables.equipTable:getItemLev(tonumber(equips[index + 1])) or 0
			local max_lv = -1
			local bestItemID = nil

			for j, jvalue in pairs(bp_equips[index]) do
				local equip_job = xyd.tables.equipTable:getJob(bp_equips[index][j].itemID)

				if not equip_job or equip_job == 0 or np:getJob() == equip_job then
					local i_lv = xyd.tables.equipTable:getItemLev(bp_equips[index][j].itemID)

					if max_lv < i_lv then
						bestItemID = bp_equips[index][j].itemID
						max_lv = i_lv
					elseif i_lv == max_lv and tonumber(index) < 4 then
						local i_job = xyd.tables.equipTable:getJob(bp_equips[index][j].itemID)
						local bestItemID_job = xyd.tables.equipTable:getJob(bestItemID)

						if np:getJob() == i_job and np:getJob() ~= bestItemID_job then
							bestItemID = bp_equips[index][j].itemID
						end
					end
				end
			end

			if old_i_lv < max_lv then
				canChangeEquip = true

				break
			elseif max_lv == old_i_lv and np:getJob() == xyd.tables.equipTable:getJob(bestItemID) and np:getJob() ~= xyd.tables.equipTable:getJob(equips[index + 1]) then
				canChangeEquip = true

				break
			end
		end

		if canChangeEquip then
			table.insert(equipHeroList, partnerId)
		end
	end

	local equipRedParams = xyd.models.redMark:getRedMarkParams(xyd.RedMarkType.AVAILABLE_EQUIPMENT) or {}
	local eShowRed = xyd.checkCondition(#equipHeroList > 0, true, false)
	equipRedParams.npList = equipHeroList

	xyd.models.redMark:setMark(xyd.RedMarkType.AVAILABLE_EQUIPMENT, eShowRed, equipRedParams)
end

function Backpack:checkIsHide(itemID)
	local res = false
	local itemType = xyd.tables.itemTable:getType(itemID)

	if itemType == xyd.ItemType.ACT_LIMIT_TEN then
		local costData = xyd.tables.summonTable:getCost(xyd.SummonType.ACT_LIMIT_TEN)

		if costData[1] ~= itemID then
			res = true
		else
			local end_time = xyd.tables.miscTable:getNumber("gacha_10drawcard_endtime", "value")
			local nowTime = xyd.getServerTime()

			if end_time < nowTime then
				res = true
			end
		end
	end

	if itemType == xyd.ItemType.LIMIT_STARRY then
		local costData = xyd.tables.starryAltarTable:getCost(2)

		if costData[1] ~= itemID then
			res = true
		else
			local end_time = xyd.tables.miscTable:getNumber("star_origin_drawcard_endtime", "value")
			local nowTime = xyd.getServerTime()

			if end_time < nowTime then
				res = true
			end
		end
	end

	return res
end

function Backpack:initItems_withBagType()
	local datas = self:getItems()

	for i = 1, #datas do
		local itemID = datas[i].item_id
		local itemNum = tonumber(datas[i].item_num)

		if ItemTable:isShowInBag(itemID) then
			local type_ = ItemTable:showInBagType(itemID)
			local isHide = self:checkIsHide(itemID)

			if self.backpackShowTypeArr[type_][itemID] == nil and not isHide then
				self.backpackShowTypeArr[type_][itemID] = {
					itemID = itemID,
					itemNum = itemNum
				}
			end
		end

		if ItemTable:getType(itemID) == xyd.ItemType.DRESS then
			xyd.models.dress:initItems(itemID, itemNum)
		end

		if ItemTable:getType(itemID) == xyd.ItemType.DRESS_FRAGMENT then
			xyd.models.dress:updateDressFragment(datas[i])
		end
	end

	xyd.models.dress:initItemsSort()
end

function Backpack:getItems_withBagType(type_)
	local indexArr = {}

	for i, v in pairs(self.backpackShowTypeArr[type_]) do
		if v ~= nil then
			table.insert(indexArr, v)
		end
	end

	return indexArr
end

function Backpack:useOptionalGiftBox(itemId, itemNum, chosenIndex, chosenId)
	local msg = messages_pb.use_optional_giftbox_req()
	msg.item.item_id = itemId
	msg.item.item_num = itemNum
	msg.chosen_index = chosenIndex
	msg.chosen_id = chosenId

	xyd.Backend.get():request(xyd.mid.USE_OPTIONAL_GIFTBOX, msg)
end

function Backpack:getCanComposeDebris()
	if not self.canComposeDebrisDatas then
		local debrisDatas = {}
		local datas = self:getItems()
		local canCompose = false

		for i = 1, #datas do
			local itemID = datas[i].item_id
			local itemNum = tonumber(datas[i].item_num)
			local item = {
				itemID = itemID,
				itemNum = itemNum
			}

			if ItemTable:isShowInBag(itemID) then
				local itemType = ItemTable:getType(itemID)
				local quality = ItemTable:getQuality(itemID)

				if itemType == xyd.ItemType.HERO_DEBRIS or itemType == xyd.ItemType.HERO_RANDOM_DEBRIS then
					local group = ItemTable:getGroup(itemID)

					if not debrisDatas[group] then
						debrisDatas[group] = {}
					end

					if not debrisDatas[group][quality] then
						debrisDatas[group][quality] = {}
					end

					local cost = ItemTable:partnerCost(itemID)

					if cost[2] <= itemNum then
						table.insert(debrisDatas[group][quality], item)
					end
				end
			end
		end

		self.canComposeDebrisDatas = debrisDatas
	end

	return self.canComposeDebrisDatas
end

function Backpack:giftBuyTest(event)
	local activity_gfit_bag_id = xyd.db.misc:getValue("gm_gift_buy_state_id")

	if activity_gfit_bag_id and tonumber(activity_gfit_bag_id) ~= -1 then
		local excelItems = {}
		local giftId = xyd.tables.giftBagTable:getGiftID(tonumber(activity_gfit_bag_id))
		local excelDatas = xyd.tables.giftTable:getAwards(giftId)
		local defData = xyd.decodeProtoBuf(event.data)
		local isReturn = false

		for i in pairs(excelDatas) do
			local isGoOn = true
			local isHasId = false

			for j in pairs(defData.items) do
				if tonumber(defData.items[j].item_id) == excelDatas[i][1] then
					isHasId = true

					if tonumber(defData.items[j].item_num) < excelDatas[i][2] then
						isGoOn = false

						break
					end
				end
			end

			if isHasId == false or isGoOn == false then
				print("The data may be wrong")

				isReturn = true

				break
			end

			local item = {
				item_id = excelDatas[i][1],
				item_num = excelDatas[i][2]
			}

			table.insert(excelItems, item)
		end

		if isReturn == true then
			return
		end

		xyd.EventDispatcher.outer():dispatchEvent({
			name = xyd.event.RECHARGE,
			data = {
				items = excelItems,
				giftbag_id = tonumber(activity_gfit_bag_id)
			}
		})
		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.RECHARGE,
			data = {
				items = excelItems,
				giftbag_id = tonumber(activity_gfit_bag_id)
			}
		})
		xyd.db.misc:setValue({
			value = -1,
			key = "gm_gift_buy_state_id"
		})
	end
end

function Backpack:editorPrintStr(event, tempStr, hasColor)
	for i, value in pairs(xyd.decodeProtoBuf(event.data).items) do
		local hasNum = self:getItemNumByID(tonumber(value.item_id))
		local numDis = tonumber(value.item_num) - hasNum
		local nameStr = ""

		if UNITY_EDITOR then
			nameStr = xyd.tables.itemTable:getNameByZhTw(tonumber(value.item_id))
		end

		local item_id_str = tostring(value.item_id)

		if #item_id_str < 10 then
			for i = #item_id_str, 10 do
				item_id_str = item_id_str .. " "
			end
		end

		local numDis_str = tostring(numDis)

		if numDis > 0 then
			numDis_str = "+" .. numDis_str
		end

		if #numDis_str < 15 then
			for i = #numDis_str, 15 do
				numDis_str = numDis_str .. " "
			end
		end

		if hasColor and hasColor == true then
			if numDis > 0 then
				numDis_str = "<color=#ff6a6a>" .. numDis_str .. "</color>"
			end

			if numDis < 0 then
				numDis_str = "<color=#9400d3>" .. numDis_str .. "</color>"
			end
		end

		local item_num_str = tostring(value.item_num)

		if #item_num_str < 10 then
			for i = #item_num_str, 15 do
				item_num_str = item_num_str .. " "
			end
		end

		tempStr = tempStr .. "item_id=" .. item_id_str .. ",addNum : " .. numDis_str .. ",new_num=" .. item_num_str .. ",name=" .. nameStr .. ",\n"
	end

	return tempStr
end

return Backpack
