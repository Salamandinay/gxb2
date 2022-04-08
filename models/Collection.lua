local BaseModel = import(".BaseModel")
local Collection = class("Collection", BaseModel)

function Collection:ctor()
	BaseModel.ctor(self)

	self.ids = {}
	self.idsByType = {}
end

function Collection:onRegister()
	BaseModel.onRegister(self)
	self:registerEvent(xyd.event.GET_COLLECTION_INFO, handler(self, self.get_collection_info))
end

function Collection:get_collection_info(event)
	local data = event.data

	self:updateData(data.ids)
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

function Collection:isGot(id)
	for key, id_ in pairs(self.ids) do
		if id == id_ then
			return true
		end
	end

	return false
end

function Collection:getGetCollectionTime()
	return self.getCollectionTime_ or 0
end

function Collection:updateData(data)
	self.ids = data
	self.getCollectionTime_ = xyd.getServerTime()

	for i = 1, 7 do
		self.idsByType[i] = {}
	end

	for key, id in pairs(self.ids) do
		local tableType = xyd.tables.collectionTable:getType(self.ids[key])
		local collectionType = 1

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

		if type(self.ids[key]) == "number" then
			table.insert(self.idsByType[collectionType], self.ids[key])
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

return Collection
