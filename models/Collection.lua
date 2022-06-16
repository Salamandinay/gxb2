local BaseModel = import(".BaseModel")
local Collection = class("Collection", BaseModel)

function Collection:ctor()
	BaseModel.ctor(self)

	self.ids = {}
	self.idsByType = {}
	self.skinCollectionLevel = 0

	self:reqCollectionInfo()

	self.gotArr = {}
end

function Collection:onRegister()
	BaseModel.onRegister(self)
	self:registerEvent(xyd.event.GET_COLLECTION_INFO, handler(self, self.get_collection_info))
	self:registerEvent(xyd.event.UPDATE_SKIN_BONUS, handler(self, self.getUpdateSkinBonus))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
end

function Collection:get_collection_info(event)
	local data = event.data

	self:updateData(data.ids)

	self.oldCollectionPoint = data.old_collect_point or 0
	self.skinCollectionLevel = data.skin_bonus_id

	self:checkLevelUpRedPoint()
	xyd.models.slot:updateAllPartnersAttrs()
end

function Collection:getUpdateSkinBonus(event)
	local point = xyd.models.backpack:getItemNumByID(377)
	local ids = xyd.tables.collectionSkinEffectTable:getIDs()
	local maxLev = #ids

	for i = 1, maxLev do
		if xyd.tables.collectionSkinEffectTable:getPoint(i) <= point then
			self.skinCollectionLevel = i
		end
	end

	self.skinCollectionLevel = math.min(self.skinCollectionLevel, maxLev)

	xyd.models.redMark:setMark(xyd.RedMarkType.SKIN_LEVEL_CAN_UP, false)
	xyd.models.slot:updateAllPartnersAttrs()
end

function Collection:getOldCollectionPoint()
	return self.oldCollectionPoint
end

function Collection:reqUpdateSkinBonus()
	local msg = messages_pb:update_skin_bonus_req()

	xyd.Backend.get():request(xyd.mid.UPDATE_SKIN_BONUS, msg)
end

function Collection:reqCollectionInfo()
	local msg = messages_pb:get_collection_info_req()

	xyd.Backend.get():request(xyd.mid.GET_COLLECTION_INFO, msg)
end

function Collection:getIdsByType(collectionType)
	return self.idsByType[collectionType]
end

function Collection:getPercentByType(collectionType)
	local totalNum = 0
	totalNum = #xyd.tables.collectionTable:getIdsListByType(collectionType)

	if collectionType == xyd.CollectionType.SKIN then
		totalNum = #xyd.tables.collectionTable:getIdsListByType(xyd.CollectionTableType.SKIN)
	elseif collectionType == xyd.CollectionType.FRAME then
		totalNum = #xyd.tables.collectionTable:getIdsListByType(xyd.CollectionTableType.FRAME) + #xyd.tables.collectionTable:getIdsListByType(xyd.CollectionTableType.AVATAR)
	elseif collectionType == xyd.CollectionType.FURNITURE then
		totalNum = #xyd.tables.collectionTable:getIdsListByType(xyd.CollectionTableType.FURNITURE)
	elseif collectionType == xyd.CollectionType.BG then
		totalNum = #xyd.tables.collectionTable:getIdsListByType(xyd.CollectionTableType.BG)
	elseif collectionType == xyd.CollectionType.FACE then
		totalNum = #xyd.tables.collectionTable:getIdsListByType(xyd.CollectionTableType.EMO)
	elseif collectionType == xyd.CollectionType.SOUL then
		totalNum = #xyd.tables.collectionTable:getIdsListByType(xyd.CollectionTableType.SOUL)
	elseif collectionType == xyd.CollectionType.STORY then
		totalNum = #xyd.tables.collectionTable:getIdsListByType(xyd.CollectionTableType.STORY)
	end

	local floatNum = #self:getIdsByType(collectionType) / totalNum

	return math.floor(floatNum * 100)
end

function Collection:getData()
	return self.ids
end

function Collection:addID(collectionID)
	if self:isGot(collectionID) then
		return
	end

	table.insert(self.ids, collectionID)

	local tableType = xyd.tables.collectionTable:getType(collectionID)

	if not self.idsByType[tableType] then
		self.idsByType[tableType] = {}
	end

	table.insert(self.idsByType[tableType], collectionID)

	self.gotArr[collectionID] = 1
end

function Collection:isGot(id)
	if self.gotArr[id] then
		return true
	end

	return false
end

function Collection:getGetCollectionTime()
	return self.getCollectionTime_ or 0
end

function Collection:updateData(data)
	self.ids = data
	self.getCollectionTime_ = xyd.getServerTime()
	self.idsByType = {}
	self.gotArr = {}

	for i = 1, 9 do
		self.idsByType[i] = {}
	end

	for key, id in pairs(self.ids) do
		if type(self.ids[key]) == "number" then
			local tableType = xyd.tables.collectionTable:getType(self.ids[key])

			if tableType and tableType > 0 then
				local collectionType = tableType

				if tableType == xyd.CollectionTableType.SKIN then
					collectionType = xyd.CollectionType.SKIN
				elseif tableType == xyd.CollectionTableType.AVATAR then
					collectionType = xyd.CollectionType.FRAME
				elseif tableType == xyd.CollectionTableType.FRAME then
					collectionType = xyd.CollectionType.FRAME
				elseif tableType == xyd.CollectionTableType.FURNITURE then
					collectionType = xyd.CollectionType.FURNITURE
				elseif tableType == xyd.CollectionTableType.BG then
					collectionType = xyd.CollectionType.BG
				elseif tableType == xyd.CollectionTableType.EMO then
					collectionType = xyd.CollectionType.FACE
				elseif tableType == xyd.CollectionTableType.SOUL then
					collectionType = xyd.CollectionType.SOUL
				elseif tableType == xyd.CollectionTableType.STORY then
					collectionType = xyd.CollectionType.STORY
				end

				if not self.idsByType[collectionType] then
					self.idsByType[collectionType] = {}
				end

				table.insert(self.idsByType[collectionType], self.ids[key])

				self.gotArr[self.ids[key]] = 1
			else
				dump("------------")
				dump(tableType)
			end
		end
	end

	for i = 1, 7 do
		table.sort(self.idsByType[i], function (a, b)
			return a < b
		end)
	end
end

function Collection:getBgCollectionId(id)
	local itemId = 2000000 + id

	return xyd.tables.itemTable:getCollectionId(itemId)
end

function Collection:setRedMark()
end

function Collection:setDefaultRedMark()
end

function Collection:getPointsByThemeID(themeID)
	local allPoint = 0
	self.currentSortedPartners_ = {}
	local skinIDs = xyd.tables.collectionSkinGroupTable:getSkins(themeID)
	local hasNum = 0
	local limitNum = #skinIDs

	for j = 1, limitNum do
		local skin_id = skinIDs[j]
		local collectionID = xyd.tables.itemTable:getCollectionId(skin_id)

		if xyd.models.collection:isGot(collectionID) then
			hasNum = hasNum + 1
		end
	end

	local taskDatas = xyd.tables.collectionSkinGroupTable:getAwards(themeID)

	for i = 1, #taskDatas do
		local info = taskDatas[i]
		local num = info[1]
		local point = info[3]

		if num <= hasNum then
			allPoint = allPoint + point
		end
	end

	return allPoint
end

function Collection:getAllSkinPoints()
	local allPoint = 0
	local haveGotIDs = self.idsByType[xyd.CollectionType.SKIN]

	for i = 1, #haveGotIDs do
		local collectionID = haveGotIDs[i]
		local award = xyd.tables.collectionTable:getAwards(collectionID)
		allPoint = allPoint + award[2]
	end

	local themeIDs = xyd.tables.collectionSkinGroupTable:getIDs()

	for _, themeID in ipairs(themeIDs) do
		local point = self:getPointsByThemeID(themeID)
		allPoint = allPoint + point
	end

	return allPoint
end

function Collection:getSkinCollectionLevel()
	return self.skinCollectionLevel
end

function Collection:getPointsByQlt()
	local result = {
		0,
		0,
		0,
		0
	}
	local haveNums = {
		0,
		0,
		0,
		0
	}
	local haveGotIDs = self.idsByType[xyd.CollectionType.SKIN]

	for i = 1, #haveGotIDs do
		local collectionID = haveGotIDs[i]
		local qlt = xyd.tables.collectionTable:getQlt(collectionID)
		local award = xyd.tables.collectionTable:getAwards(collectionID)
		result[qlt] = result[qlt] + award[2]
		haveNums[qlt] = haveNums[qlt] + 1
	end

	return result, haveNums
end

function Collection:getNowCollectionPoint()
	return math.max(xyd.models.backpack:getItemNumByID(xyd.ItemID.COLLECT_COIN), xyd.models.collection:getOldCollectionPoint())
end

function Collection:checkLevelUpRedPoint()
	local flag = false
	local point = xyd.models.backpack:getItemNumByID(377)
	local maxLev = #xyd.tables.collectionSkinEffectTable:getIDs()
	local nextLevPoint = xyd.tables.collectionSkinEffectTable:getPoint(math.min(self.skinCollectionLevel + 1, maxLev))
	flag = nextLevPoint <= point

	xyd.models.redMark:setMark(xyd.RedMarkType.SKIN_LEVEL_CAN_UP, flag)
end

function Collection:onItemChange(event)
	local items = event.data.items

	for i = 1, #items do
		local item = items[i]
		local item_id = item.item_id
		local type = xyd.tables.itemTable:getType(item_id)
		local collection_id = xyd.tables.itemTable:getCollectionId(item_id)

		if type == xyd.ItemType.SKIN and collection_id and collection_id > 0 then
			self:addID(collection_id)
		end
	end
end

return Collection
