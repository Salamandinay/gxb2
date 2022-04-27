local HouseItemInfo = class("HouseItemInfo")
local HouseFurnitureTable = xyd.tables.houseFurnitureTable

function HouseItemInfo:ctor()
	self.item_id = 0
	self.is_flip = 0
	self.c_width = 0
	self.c_length = 0
	self.c_height = 1
	self.coord_x = 0
	self.coord_y = 0
	self.floor = 0
	self.grid_type = {}
	self.cur_grid_type = 0
	self.can_flip = true
	self.can_pile = false
	self.can_be_pile = false
	self.type = 0
	self.special_type = 0
	self.childs = {}
	self.hashCode = 0
	self.place_floor = {}
	self.cur_place_floor = 0
	self.pile_limit_start = {}
	self.pile_area = {}
	self.grid_type_index = 1
	self.interact = 0
	self.interactHeros = {}
	self.point_xy = {}
	self.free_point = {}
	self.isHero_ = false
	self.offset_pos = {}
	self.pile_offset = {}
	self.low_floor_list = {}
	self.high_floor_list = {}
	self.recordInfo_ = nil
end

function HouseItemInfo:finalFlip()
	local tmpFlip = self.is_flip

	return tmpFlip
end

function HouseItemInfo:getPileOffsetX()
	local posX = self.pile_offset[1]

	if self:finalFlip() == 0 then
		return posX
	elseif not posX then
		return nil
	else
		return -posX
	end
end

function HouseItemInfo:getPileOffsetY()
	return self.pile_offset[2]
end

function HouseItemInfo:width()
	return xyd.checkCondition(self:finalFlip() == 0, self.c_width, self.c_length)
end

function HouseItemInfo:length()
	return xyd.checkCondition(self:finalFlip() == 0, self.c_length, self.c_width)
end

function HouseItemInfo:pileWidth()
	return xyd.checkCondition(self:finalFlip() == 0, self.pile_area[2], self.pile_area[1])
end

function HouseItemInfo:pileLength()
	return xyd.checkCondition(self:finalFlip() == 0, self.pile_area[1], self.pile_area[2])
end

function HouseItemInfo:stageX()
	local stageX_ = self.coord_x

	if self.parent then
		local parentInfo = self.parent:getInfo()
		stageX_ = self.coord_x + parentInfo.coord_x
	end

	return stageX_
end

function HouseItemInfo:stageY()
	local stageY_ = self.coord_y

	if self.parent then
		local parentInfo = self.parent:getInfo()
		stageY_ = self.coord_y + parentInfo.coord_y
	end

	return stageY_
end

function HouseItemInfo:stagePos()
	return {
		x = self:stageX(),
		y = self:stageY()
	}
end

function HouseItemInfo:maxX()
	return self:stageX() + self:length()
end

function HouseItemInfo:maxY()
	return self:stageY() + self:width()
end

function HouseItemInfo:init(itemID, params)
	params = params or {}
	self.item_id = itemID or 0
	self.is_flip = params.is_flip or 0
	self.coord_x = params.coord_x or 0
	self.coord_y = params.coord_y or 0
	self.floor = params.floor or HouseFurnitureTable:floor(itemID)
	local area = HouseFurnitureTable:area(itemID)
	self.c_length = params.c_length or area[1]
	self.c_width = params.c_width or area[2]
	self.c_height = params.c_height or HouseFurnitureTable:height(itemID) or 0
	self.can_flip = params.can_flip or HouseFurnitureTable:canFlip(itemID)
	self.grid_type = params.grid_type or HouseFurnitureTable:gridType(itemID)
	self.can_pile = params.can_pile or HouseFurnitureTable:canPile(itemID)
	self.can_be_pile = params.can_be_pile or HouseFurnitureTable:canBePile(itemID)
	self.type = params.type or HouseFurnitureTable:type(itemID)
	self.special_type = params.special_type or HouseFurnitureTable:specialType(itemID)
	self.place_floor = params.place_floor or HouseFurnitureTable:placeFloor(itemID)
	self.pile_limit_start = params.pile_limit_start or HouseFurnitureTable:pileLimitStart(itemID)
	self.pile_area = params.pile_area or HouseFurnitureTable:pileArea(itemID)
	self.interact = params.interact or HouseFurnitureTable:interact(itemID)
	self.point_xy = params.point_xy or HouseFurnitureTable:pointXy(itemID)
	self.offset_pos = params.offset_pos or HouseFurnitureTable:posOffset(itemID)
	self.pile_offset = params.pile_offset or HouseFurnitureTable:pileOffset(itemID)
	self.cur_grid_type = params.cur_grid_type or self.grid_type[1]
	self.cur_place_floor = params.cur_place_floor or self.place_floor[1]

	if params.gridTypeIndex then
		self:updateGridType(params.gridTypeIndex)
	end

	self.free_point = {}

	for i = 1, #self.point_xy do
		self.free_point[i] = -1
	end
end

function HouseItemInfo:initHero(params)
	self.is_flip = params.is_flip or 0
	self.coord_x = params.coord_x or 0
	self.coord_y = params.coord_y or 0
	self.c_length = 1
	self.c_width = 1
	self.can_flip = true
	self.can_pile = false
	self.can_be_pile = false
	self.floor = 4
	self.place_floor = {
		xyd.HouseItemPlaceFloor.DECORATION
	}
	self.grid_type = {
		xyd.HouseGridType.FLOOR
	}
	self.cur_place_floor = xyd.HouseItemPlaceFloor.DECORATION
	self.cur_grid_type = xyd.HouseGridType.FLOOR
	self.special_type = xyd.HouseItemSpecialType.NORMAL
	self.isHero_ = true
end

function HouseItemInfo:initDress(params)
	self.is_flip = params.is_flip or 0
	self.coord_x = params.coord_x or 0
	self.coord_y = params.coord_y or 0
	self.c_length = 1
	self.c_width = 1
	self.can_flip = true
	self.can_pile = false
	self.can_be_pile = false
	self.floor = 4
	self.place_floor = {
		xyd.HouseItemPlaceFloor.DECORATION
	}
	self.grid_type = {
		xyd.HouseGridType.FLOOR
	}
	self.cur_place_floor = xyd.HouseItemPlaceFloor.DECORATION
	self.cur_grid_type = xyd.HouseGridType.FLOOR
	self.special_type = xyd.HouseItemSpecialType.NORMAL
	self.isHero_ = false
	self.isDress_ = true
end

function HouseItemInfo:isDress()
	return self.isDress_
end

function HouseItemInfo:isHero()
	return self.isHero_
end

function HouseItemInfo:setHashCode(num)
	self.hashCode = num
end

function HouseItemInfo:updateCoord(coord_x, coord_y)
	self.coord_x = coord_x
	self.coord_y = coord_y
end

function HouseItemInfo:updateGridType(index)
	self.cur_grid_type = self.grid_type[index]
	self.cur_place_floor = self.place_floor[index]
	self.grid_type_index = index
end

function HouseItemInfo:moveBy(move_x, move_y)
	self.coord_x = self.coord_x + move_x
	self.coord_y = self.coord_y + move_y
end

function HouseItemInfo:removeInParent()
	if self.parent then
		local parentInfo = self.parent:getInfo()

		parentInfo:removeChild(self.item)

		self.parent = nil

		self:resetRelativePos(parentInfo)
	end
end

function HouseItemInfo:removeChild(item)
	local index = xyd.arrayIndexOf(self.childs, item)

	if index > -1 then
		table.remove(self.childs, index)
	end
end

function HouseItemInfo:updateRelativePos(parentInfo)
	self.coord_x = self.coord_x - parentInfo.coord_x
	self.coord_y = self.coord_y - parentInfo.coord_y
end

function HouseItemInfo:resetRelativePos(parentInfo)
	self.coord_x = self.coord_x + parentInfo.coord_x
	self.coord_y = self.coord_y + parentInfo.coord_y
end

function HouseItemInfo:setRecordInfo(coordX, coordY, isFlip, gridTypeIndex)
	self.recordInfo_ = {
		coord_x = coordX,
		coord_y = coordY,
		is_flip = isFlip,
		grid_type_index = gridTypeIndex
	}
end

function HouseItemInfo:canInteract()
	if self.interact <= 0 then
		return false
	end

	if self:isHero() == false then
		local tmpItem = self.item

		if not tmpItem:checkCanInteract() then
			return false
		end
	end

	return #self.interactHeros < #self.point_xy
end

function HouseItemInfo:isInteract()
	if self.interact <= 0 then
		return false
	end

	return #self.interactHeros ~= 0
end

function HouseItemInfo:getInteractIndex(item)
	return xyd.arrayIndexOf(self.interactHeros, item)
end

function HouseItemInfo:addInteractHero(item)
	if xyd.arrayIndexOf(self.interactHeros, item) < 0 then
		table.insert(self.interactHeros, item)

		for i = 1, #self.free_point do
			if self.free_point[i] == -1 then
				self.free_point[i] = item

				break
			end
		end
	end
end

function HouseItemInfo:removeInteractItem(item)
	local index = xyd.arrayIndexOf(self.interactHeros, item)

	if index > -1 then
		table.remove(self.interactHeros, index)
	end

	for i = 1, #self.free_point do
		if self.free_point[i] == item then
			self.free_point[i] = -1

			break
		end
	end
end

function HouseItemInfo:getPointXyIndex(item)
	local index = 0

	for i = 1, #self.free_point do
		if self.free_point[i] == item then
			index = i

			break
		end
	end

	return index
end

function HouseItemInfo:getFreePointXy(item)
	local index = self:getPointXyIndex(item)
	local pointStrings = self.point_xy
	local data = {
		x = 0,
		y = 0
	}

	if pointStrings[index] then
		local tmpXy = xyd.split(pointStrings[index], "|", true)
		data.x = tmpXy[1]
		data.y = tmpXy[2]
	end

	return data
end

function HouseItemInfo:getInteractDiretion(index)
	local num = HouseFurnitureTable:interactFlip(self.item_id)[index]

	return num
end

local HouseMap = class("HouseMap")
local HouseItem = import("app.windows.HouseItem")
local HouseHero = import("app.windows.HouseHero")
local HouseSelectBox = import("app.windows.HouseSelectBox")
local MiscTable = xyd.tables.miscTable

function HouseMap:ctor()
	self.parentNode_ = nil
	self.mapRow = 24
	self.mapCol = 24
	self.mapSize = 50
	self.wallHeight = 200
	self.maps_ = {}
	self.heroMap_ = {}
	self.tmpMaps_ = {}
	self.items_ = {}
	self.placeFloors_ = {}
	self.saveJson_ = nil
	self.itemFloor_ = nil
	self.itemWallPaper_ = nil
	self.heroItems_ = {}
	self.herosInfo_ = {}
	self.canSetFurniture_ = false
	self.furnitureNumByType = {}
	self.furnitureNumByID = {}
	self.needToSave_ = false
	self.isVisit_ = false
	self.itemBackGroundInfo = nil
	self.otherFloorFurnitureNum_ = {}
	self.reserver_level = 6
	self.eventProxyInner_ = xyd.EventProxy.new(xyd.EventDispatcher.inner(), self)

	self.eventProxyInner_:addEventListener(xyd.event.CLICK_HOUSE_HERO, handler(self, self.onClickHero))
end

function HouseMap:get()
	if HouseMap.INSTANCE == nil then
		HouseMap.INSTANCE = HouseMap.new()
	end

	return HouseMap.INSTANCE
end

function HouseMap:init(node, wnd)
	self.parentNode_ = node
	self.houseGrid_ = xyd.HouseGrid.get()
	self.houseDialog_ = xyd.HouseDialog.get()
	self.curSelectItem_ = nil
	self.maps_ = {}
	self.tmpMaps_ = {}
	self.heroMap_ = {}
	self.items_ = {}
	self.placeFloors_ = {}
	self.itemFloor_ = nil
	self.itemWallPaper_ = nil
	self.furnitureNumByType = {}
	self.furnitureNumByID = {}
	self.timeAction_ = {}
	self.needToSave_ = false
	self.isVisit_ = false
	self.hashCodeCount = 10000
	self.curWnd_ = wnd
	self.itemBackGroundInfo = nil
	self.otherFloorFurnitureNum_ = {}

	self:initFloors()
end

function HouseMap:setHerosInfo(params)
	self.herosInfo_ = params
end

function HouseMap:initOtherFloorFurniture(params)
	self.otherFloorFurnitureNum_ = params
end

function HouseMap:getHerosInfo()
	return self.herosInfo_
end

function HouseMap:setManage(flag)
	self.canSetFurniture_ = flag

	self:setItemsTouch(flag)
end

function HouseMap:setItemsTouch(flag)
	for _, houseItem in pairs(self.items_) do
		local info = houseItem:getInfo()

		if not info:isHero() and not info:isDress() then
			houseItem:setTouchEnable(flag)
		end
	end
end

function HouseMap:onClickHero(event)
	local data = event.data
	local dialog = xyd.tables.partnerTable:getSayHelloDialog(data.tableID, data.skinID)

	if not self.playCommonDialog and dialog.sound ~= 0 then
		self.playCommonDialog = true

		if self.curDialog_ then
			self:clearDialog()
		end

		dialog.itemList = {}
		self.curDialog_ = dialog
		local key = xyd.getTimeKey()

		xyd.SoundManager.get():playSound(dialog.sound)
		XYDCo.WaitForTime(dialog.time, function ()
			local win = xyd.getWindow("house_window")

			if not win then
				return
			end

			self.playCommonDialog = false
		end, key)

		dialog.timeOutId = key
	end
end

function HouseMap:canSetHeros()
	return self.canSetFurniture_ == false
end

function HouseMap:setNeedSave(flag)
	self.needToSave_ = flag
end

function HouseMap:checkNeedSave()
	return self.needToSave_
end

function HouseMap:checkHeroCanTouch()
	return not self.isVisit_
end

function HouseMap:setIsVisit(flag)
	self.isVisit_ = flag
end

function HouseMap:initFloors()
	local parentDepth = self.parentNode_:GetComponent(typeof(UIWidget)).depth

	for i = 1, xyd.HouseItemPlaceFloor.TOTAL_NUM do
		local node = NGUITools.AddChild(self.parentNode_, "floor_" .. i)
		local w = node:AddComponent(typeof(UIWidget))
		local depth = xyd.HouseItemPlaceFloorDepth[i] or 0
		w.depth = depth + parentDepth
		self.placeFloors_[i] = node
	end
end

function HouseMap:getPlaceNode(placeFloor)
	return self.placeFloors_[placeFloor]
end

function HouseMap:getMaps(info)
	if not self.maps_[info.cur_grid_type] then
		self.maps_[info.cur_grid_type] = {}
	end

	if not self.maps_[info.cur_grid_type][info.special_type] then
		self.maps_[info.cur_grid_type][info.special_type] = {}
	end

	return self.maps_[info.cur_grid_type][info.special_type]
end

function HouseMap:getTmpMaps(info)
	if not self.tmpMaps_[info.cur_grid_type] then
		self.tmpMaps_[info.cur_grid_type] = {}
	end

	if not self.tmpMaps_[info.cur_grid_type][info.special_type] then
		self.tmpMaps_[info.cur_grid_type][info.special_type] = {}
	end

	return self.tmpMaps_[info.cur_grid_type][info.special_type]
end

function HouseMap:getChildInfo(parentData, childs)
	if not childs then
		return nil
	end

	for i = 1, #childs do
		local child = childs[i]
		local info = child:getInfo()
		local tmpData = messages_pb.house_item_info()
		tmpData.table_id = tonumber(info.item_id)
		tmpData.x = info.coord_x
		tmpData.y = info.coord_y
		tmpData.flip = info.is_flip

		self:getChildInfo(tmpData, info.childs)
		table.insert(parentData.children, tmpData)
	end
end

function HouseMap:getSaveData(msg)
	local data = msg.furnitures
	local floorInfo = self.itemFloor_:getInfo()
	local floorSaveData = messages_pb.house_item_info()
	floorSaveData.table_id = tonumber(floorInfo.item_id)
	floorSaveData.x = floorInfo.coord_x
	floorSaveData.y = floorInfo.coord_y
	floorSaveData.flip = floorInfo.is_flip

	table.insert(data, floorSaveData)

	local wallPaperInfo = self.itemWallPaper_:getInfo()
	local wallPaperSaveData = messages_pb.house_item_info()
	wallPaperSaveData.table_id = tonumber(wallPaperInfo.item_id)
	wallPaperSaveData.x = wallPaperInfo.coord_x
	wallPaperSaveData.y = wallPaperInfo.coord_y
	wallPaperSaveData.flip = wallPaperInfo.is_flip

	table.insert(data, wallPaperSaveData)

	local bgInfo = self.itemBackGroundInfo

	if bgInfo then
		local bgSaveData = messages_pb.house_item_info()
		bgSaveData.table_id = tonumber(bgInfo.item_id)
		bgSaveData.x = 0
		bgSaveData.y = 0
		bgSaveData.flip = 1

		table.insert(data, bgSaveData)
	end

	for key in pairs(self.items_) do
		local item = self.items_[key]
		local info = item:getInfo()

		if not info:isHero() and info.special_type ~= xyd.HouseItemSpecialType.FLOOR_OR_WALL_PAPER and not info.parent then
			local tmpData = messages_pb.house_item_info()
			tmpData.table_id = tonumber(info.item_id)
			tmpData.x = info.coord_x
			tmpData.y = info.coord_y
			tmpData.flip = info.is_flip

			self:getChildInfo(tmpData, info.childs)

			if info.cur_grid_type == xyd.HouseGridType.FLOOR then
				table.insert(floorSaveData.children, tmpData)
			elseif info.cur_grid_type == xyd.HouseGridType.LEFT_WALL then
				table.insert(wallPaperSaveData.children, tmpData)
			elseif info.cur_grid_type == xyd.HouseGridType.RIGHT_WALL then
				tmpData.x = tmpData.x + self.mapCol

				table.insert(wallPaperSaveData.children, tmpData)
			end
		end
	end
end

function HouseMap:saveJson(floor)
	local msg = messages_pb.house_save_info_req()
	msg.floor = floor

	self:getSaveData(msg)
	xyd.models.house:reqSaveHouseInfo(msg)
end

function HouseMap:getGridNum(info, row, col)
	local canBePile = info.can_be_pile

	if canBePile and (row < info.pile_limit_start[2] or row >= info.pile_limit_start[2] + info:pileWidth() or col < info.pile_limit_start[1] or col >= info.pile_limit_start[1] + info:pileLength()) then
		canBePile = false
	end

	local val = xyd.checkCondition(canBePile, info.floor, -info.floor)

	return tostring(val) .. "|" .. tostring(info.hashCode)
end

function HouseMap:parseGridNum(str)
	if str == nil then
		str = ""
	end

	local tmpStrs = xyd.split(str, "|")

	return {
		val = tonumber(tmpStrs[1]) or 0,
		hashCode = tonumber(tmpStrs[2]) or 0
	}
end

function HouseMap:updateGridNum(info)
	local maps_ = self:getMaps(info)
	local tmpMaps_ = self:getTmpMaps(info)
	local endy = info:maxY() - 1
	local endx = info:maxX() - 1

	for row = info:stageY(), endy do
		for col = info:stageX(), endx do
			local val = self:getGridNum(info, row - info:stageY(), col - info:stageX())
			local index = row * self.mapCol + col
			maps_[index] = val
			tmpMaps_[index] = val

			self.houseGrid_:updateOneGridNum(row, col, info.floor, info)
		end
	end
end

function HouseMap:updateTmpGridNum(info)
	local tmpMaps_ = self:getTmpMaps(info)
	local endy = info:maxY() - 1
	local endx = info:maxX() - 1

	for row = info:stageY(), endy do
		for col = info:stageX(), endx do
			local val = self:getGridNum(info, row - info:stageY(), col - info:stageX())
			local index = row * self.mapCol + col
			tmpMaps_[index] = val

			self.houseGrid_:updateOneGridNum(row, col, info.floor, info)
		end
	end
end

function HouseMap:resetTmpGridNum(info)
	local maps_ = self:getMaps(info)
	local tmpMaps_ = self:getTmpMaps(info)
	local endy = info:maxY() - 1
	local endx = info:maxX() - 1

	for row = info:stageY(), endy do
		for col = info:stageX(), endx do
			local index = row * self.mapCol + col
			local val = maps_[index]
			tmpMaps_[index] = val
			local tmpData = self:parseGridNum(val)

			self.houseGrid_:updateOneGridNum(row, col, tmpData.val, info)
		end
	end
end

function HouseMap:removeItemInMap(info)
	local maps_ = self:getMaps(info)
	local parent = info.parent
	local val = nil
	local endy = info:maxY() - 1
	local endx = info:maxX() - 1

	for row = info:stageY(), endy do
		for col = info:stageX(), endx do
			if parent then
				local parentInfo = parent:getInfo()
				val = self:getGridNum(parentInfo, info.coord_y + row - info:stageY(), info.coord_x + col - info:stageX())
			end

			local index = row * self.mapCol + col
			maps_[index] = val
		end
	end
end

function HouseMap:syncMap(info)
	local maps_ = self:getMaps(info)
	local tmpMaps_ = self:getTmpMaps(info)
	local endy = info:maxY() - 1
	local endx = info:maxX() - 1

	for row = info:stageY(), endy do
		for col = info:stageX(), endx do
			local index = row * self.mapCol + col
			local val = tmpMaps_[index]
			maps_[index] = val
		end
	end
end

function HouseMap:syncHeroMap()
	local info = HouseItemInfo.new()

	info:initHero({})

	local maps_ = self:getMaps(info)
	self.heroMap_ = {}

	for key, val in pairs(maps_) do
		self.heroMap_[key] = val
	end
end

function HouseMap:updateHeroMapGridNum(info)
	local index = info.coord_y * self.mapCol + info.coord_x
	local val = self:getGridNum(info, info.coord_x, info.coord_y)
	self.heroMap_[index] = val
end

function HouseMap:resetHeroMapGridNum(info)
	local index = info.coord_y * self.mapCol + info.coord_x
	self.heroMap_[index] = nil
end

function HouseMap:removeAllFurniture()
	local clearArry = {
		xyd.HouseItemPlaceFloor.LEFT_WALL_DECORATION,
		xyd.HouseItemPlaceFloor.RIGHT_WALL_DECORATION,
		xyd.HouseItemPlaceFloor.CARPET,
		xyd.HouseItemPlaceFloor.DECORATION
	}

	for i = 1, #clearArry do
		local floorId = clearArry[i]
		local node = self.placeFloors_[floorId]

		if node then
			NGUITools.DestroyChildren(node.transform)
		end
	end
end

function HouseMap:clearAll(isCloseWnd)
	if isCloseWnd == nil then
		isCloseWnd = false
	end

	if self.curSelectItem_ then
		self:resetSelectItem()
		self:hideSelectBox()
	end

	self:removeAllFurniture()

	self.maps_ = {}
	self.tmpMaps_ = {}
	self.items_ = {}
	self.timeAction_ = {}
	self.furnitureNumByType = {}
	self.furnitureNumByID = {}

	if not isCloseWnd then
		if self.itemFloor_ then
			self.items_[self.itemFloor_.hashCode] = self.itemFloor_

			self:updateFunitureNum(self.itemFloor_:getInfo(), 1)
		end

		if self.itemWallPaper_ then
			self.items_[self.itemWallPaper_.hashCode] = self.itemWallPaper_

			self:updateFunitureNum(self.itemWallPaper_:getInfo(), 1)
		end

		if self.itemBackGroundInfo then
			self:updateFunitureNum(self.itemBackGroundInfo, 1)
		end
	else
		self.itemFloor_ = nil
		self.itemWallPaper_ = nil

		self:setManage(false)
		self:setHerosInfo(nil)

		self.selectBox_ = nil
	end

	self.houseGrid_:clear()
	self:clearHero()
	self:hideHeros()
	self:clearDialog()
end

function HouseMap:spliceBackgroundType(items)
	local itemList = {}
	local hasBg = false

	for i = 1, #items do
		local item = items[i]
		local type = HouseFurnitureTable:type(item.table_id)

		if type == xyd.HouseItemType.BACKGROUND then
			self:setHouseBackground(item.table_id)

			hasBg = true
		else
			table.insert(itemList, item)
		end
	end

	if not hasBg then
		local defaultId = MiscTable:getNumber("house_wallpaper", "value")

		self:setHouseBackground(defaultId, true)
	end

	return itemList
end

function HouseMap:setHouseBackground(tableID, isFake)
	if self.curWnd_ then
		self.curWnd_:setHouseBackground(tableID)
	end

	self:addNewBackGround(tableID)
end

function HouseMap:addNewBackGround(itemId)
	local info = HouseItemInfo.new()

	info:init(itemId)

	if self.itemBackGroundInfo then
		self:updateFunitureNum(self.itemBackGroundInfo, -1)
	end

	self.itemBackGroundInfo = info

	self:updateFunitureNum(self.itemBackGroundInfo, 1)
end

function HouseMap:initItems(items)
	if not self.parentNode_ then
		return
	end

	local childrenItems = {}
	local newItems = self:spliceBackgroundType(items)

	for _, info in ipairs(newItems) do
		local item = self:addNewItem(info.table_id, {
			coord_x = info.x,
			coord_y = info.y,
			is_flip = info.flip
		})
		childrenItems = xyd.arrayMerge(childrenItems, info.children)
	end

	for i = 1, #childrenItems do
		local info = childrenItems[i]
		local index = 1
		local x_ = info.x

		if self.mapCol <= info.x then
			index = 2
			x_ = info.x - self.mapCol
		end

		local item = self:addNewItem(info.table_id, {
			coord_x = x_,
			coord_y = info.y,
			is_flip = info.flip,
			gridTypeIndex = index
		})

		self:addNewChildItem(info.children, item)
	end

	self:updateZOrderAll()
	self:checkSpecialFurniture()
end

function HouseMap:addNewChildItem(childs, parentItem)
	if not childs then
		return
	end

	local parentInfo = parentItem:getInfo()

	for i = 1, #childs do
		local child = childs[i]
		local info = HouseItemInfo.new()

		info:init(child.table_id, {
			coord_x = child.x,
			coord_y = child.y,
			is_flip = child.flip
		})

		info.parent = parentItem
		local item = self:getOneItem(info, parentItem:getGameObject())
		self.items_[item.hashCode] = item

		info:setHashCode(item.hashCode)

		info.item = item

		table.insert(parentInfo.childs, item)
		self:updateGridNum(info)
		item:updatePos()
		self:updateFunitureNum(info, 1)
		self:addNewChildItem(child.child, item)
	end
end

function HouseMap:updateFunitureNum(info, val)
	if val == nil then
		val = 1
	end

	self.furnitureNumByType[info.type] = (self.furnitureNumByType[info.type] or 0) + val
	self.furnitureNumByID[info.item_id] = (self.furnitureNumByID[info.item_id] or 0) + val
end

function HouseMap:getFurnitureNumByType(type)
	return self.furnitureNumByType[type] or 0
end

function HouseMap:getInHouseNum(itemID)
	return (self.otherFloorFurnitureNum_[itemID] or 0) + (self.furnitureNumByID[itemID] or 0)
end

function HouseMap:checkOneUnitFree(index, info)
	local maps_ = self:getMaps(info)

	if info:isHero() then
		maps_ = self.heroMap_
	end

	local data = self:parseGridNum(maps_[index])

	if data.val == 0 then
		return true
	end

	return false
end

function HouseMap:checkSpecialFurniture()
	local needHideHouseBoard = false
	local noJambs = MiscTable:split2num("house_no_jamb", "value", "|")

	if self.itemFloor_ and xyd.arrayIndexOf(noJambs, self.itemFloor_:getInfo().item_id) > -1 then
		needHideHouseBoard = true
	end

	if self.itemWallPaper_ then
		if needHideHouseBoard or xyd.arrayIndexOf(noJambs, self.itemWallPaper_:getInfo().item_id) > -1 then
			self.itemWallPaper_:hideHouseBoard()
		else
			self.itemWallPaper_:showHouseBoard()
		end
	end
end

function HouseMap:isCanAdd(coordX, coordY, info)
	local flag = true
	local endx = coordX + info:length() - 1
	local endy = coordY + info:width() - 1

	for x = coordX, endx do
		for y = coordY, endy do
			if not self:checkOneUnitFree(x + y * self.mapCol, info) then
				flag = false

				break
			end
		end

		if not flag then
			break
		end
	end

	return flag
end

function HouseMap:getFreeGrid(size, col, row, info, errorNode, centerPos)
	local maxRow = size.c_with - info:width() + 1
	local maxCol = size.c_length - info:length() + 1
	local centerRow = centerPos.coord_y
	local centerCol = centerPos.coord_x
	local tmpGrids = {}

	table.insert(tmpGrids, {
		row = centerRow + row,
		col = centerCol + col
	})
	table.insert(tmpGrids, {
		row = centerRow + row,
		col = centerCol - col
	})
	table.insert(tmpGrids, {
		row = centerRow - row,
		col = centerCol + col
	})
	table.insert(tmpGrids, {
		row = centerRow - row,
		col = centerCol - col
	})

	if col ~= row then
		table.insert(tmpGrids, {
			row = centerRow + col,
			col = centerCol + row
		})
		table.insert(tmpGrids, {
			row = centerRow - col,
			col = centerCol + row
		})
		table.insert(tmpGrids, {
			row = centerRow - col,
			col = centerCol - row
		})
		table.insert(tmpGrids, {
			row = centerRow + col,
			col = centerCol - row
		})
	end

	local flag = false
	local coordX = -1
	local coordY = -1

	for i = 1, #tmpGrids do
		local tmpGrid = tmpGrids[i]

		if not errorNode[tostring(tmpGrid.row) .. "|" .. tostring(tmpGrid.col)] and tmpGrid.row >= 0 and maxRow > tmpGrid.row and tmpGrid.col >= 0 then
			if maxCol <= tmpGrid.col then
				-- Nothing
			elseif self:isCanAdd(tmpGrid.col, tmpGrid.row, info) then
				coordX = tmpGrid.col
				coordY = tmpGrid.row
				flag = true

				break
			else
				errorNode[tostring(tmpGrid.row) .. "|" .. tostring(tmpGrid.col)] = true
			end
		end
	end

	return {
		flag = flag,
		coord_x = coordX,
		coord_y = coordY
	}
end

function HouseMap:getFreeGridByCenterPos(info, centerPos)
	local coordX = -1
	local coordY = -1
	local flag = false
	local index = centerPos.grid_type_index

	info:updateGridType(index)

	local type = info.grid_type[index]
	local size = self.houseGrid_:getMaxSizeByGridType(type)
	local maxRow = size.c_with - info:width() + 1
	local maxCol = size.c_length - info:length() + 1
	local errorNode = {}

	for col = 0, maxCol do
		for row = 0, maxRow do
			local result = self:getFreeGrid(size, col, row, info, errorNode, centerPos)

			if result.flag then
				coordX = result.coord_x
				coordY = result.coord_y
				flag = true

				break
			end
		end

		if flag then
			break
		end
	end

	return {
		flag = flag,
		coord_x = coordX,
		coord_y = coordY
	}
end

function HouseMap:getFreeGridByItem(item)
	local stagePos = item:getGameObject().transform.position
	local info = item:getInfo()
	local centerPos = self.houseGrid_:changeStagePosToGrid(stagePos.x, stagePos.y, info)

	if centerPos.grid_type_index == -1 then
		centerPos.grid_type_index = info.grid_type_index
	end

	local result = self:getFreeGridByCenterPos(info, centerPos)

	if result.flag then
		return result
	end

	result = self:getFreeGridByCenterPos(info, {
		coord_y = 0,
		coord_x = 0,
		grid_type_index = info.grid_type_index
	})

	return result
end

function HouseMap:getFreeGrids(info)
	if info.type == xyd.HouseItemType.FLOOR or info.type == xyd.HouseItemType.WALL_PAPER then
		info:updateGridType(1)

		return {
			coord_y = 0,
			coord_x = 0
		}
	end

	local centerPos = self:getCenterPos(info)
	local coordX = -1
	local coordY = -1
	local flag = false
	local result = self:getFreeGridByCenterPos(info, centerPos)

	dump(result)

	if result.flag then
		return {
			coord_x = result.coord_x,
			coord_y = result.coord_y
		}
	end

	for i = 1, #info.grid_type do
		if centerPos.grid_type_index ~= i then
			local result = self:getFreeGridByCenterPos(info, {
				coord_y = 0,
				coord_x = 0,
				grid_type_index = i
			})

			if result.flag then
				coordX = result.coord_x
				coordY = result.coord_y

				break
			end
		end
	end

	return {
		coord_x = coordX,
		coord_y = coordY
	}
end

function HouseMap:getCenterPos(info)
	local wnd = xyd.WindowManager.get():getWindow("house_window")

	if not wnd then
		return {
			coord_y = 0,
			coord_x = 0,
			grid_type_index = info.grid_type_index
		}
	end

	local point = wnd:getCenterStagePoint()
	local result = self.houseGrid_:changeStagePosToGrid(point.x, point.y, info)

	if result.grid_type_index == -1 then
		result.grid_type_index = info.grid_type_index
	end

	return result
end

function HouseMap:getHeroAllFreeGrids()
	local grids = {}
	local info = HouseItemInfo.new()

	info:initHero({})

	for i = 1, #info.grid_type do
		info:updateGridType(i)

		local type = info.grid_type[i]
		local size = self.houseGrid_:getMaxSizeByGridType(type)
		local maxRow = size.c_with - info:width()
		local maxCol = size.c_length - info:length()

		for row = 0, maxRow do
			for col = 0, maxCol do
				if self:isCanAdd(col, row, info) then
					table.insert(grids, {
						coord_x = col,
						coord_y = row
					})
				end
			end
		end
	end

	return grids
end

function HouseMap:checkCanAddNewItem(itemID, isShowToast)
	if isShowToast == nil then
		isShowToast = true
	end

	if self.curSelectItem_ then
		if isShowToast then
			xyd.alert(xyd.AlertType.TIPS, __("HOUSE_TEXT_31"))
		end

		return
	end

	local info = HouseItemInfo.new()

	info:init(itemID)

	local typeLimit = MiscTable:split2num("dorm_top_num_by_type", "value", "|")
	local maxTypeNum = typeLimit[info.type] or 0
	local curNum = self:getFurnitureNumByType(info.type)

	if maxTypeNum <= curNum and info.type ~= xyd.HouseItemType.FLOOR and info.type ~= xyd.HouseItemType.WALL_PAPER and info.type ~= xyd.HouseItemType.BACKGROUND then
		if isShowToast then
			xyd.alert(xyd.AlertType.TIPS, __("HOUSE_TEXT_29"))
		end

		return false
	end

	local hasNum = xyd.models.backpack:getItemNumByID(itemID)
	local setNum = self:getInHouseNum(itemID)

	if hasNum - setNum < 1 then
		if isShowToast then
			xyd.alert(xyd.AlertType.TIPS, __("HOUSE_TEXT_30"))
		end

		return false
	end

	local pos = self:getFreeGrids(info)

	if pos.coord_x < 0 or pos.coord_y < 0 then
		if isShowToast then
			xyd.alert(xyd.AlertType.TIPS, __("HOUSE_TEXT_28"))
		end

		return false
	end

	return true
end

function HouseMap:addNewItem(itemID, params)
	local info = HouseItemInfo.new()

	info:init(itemID, params)

	if not params then
		local pos = self:getFreeGrids(info)

		if pos.coord_x < 0 or pos.coord_y < 0 then
			xyd.alert(xyd.AlertType.TIPS, __("HOUSE_TEXT_28"))

			return
		end

		info:updateCoord(pos.coord_x, pos.coord_y)
	end

	local item = nil

	if info.type == xyd.HouseItemType.FLOOR and self.itemFloor_ then
		item = self.itemFloor_

		self:updateFunitureNum(item:getInfo(), -1)

		info.item = item

		item:updateByInfo(info)
		self:updateFunitureNum(info, 1)
	elseif info.type == xyd.HouseItemType.WALL_PAPER and self.itemWallPaper_ then
		item = self.itemWallPaper_

		self:updateFunitureNum(item:getInfo(), -1)

		info.item = item

		item:updateByInfo(info)
		self:updateFunitureNum(info, 1)
	else
		local parentNode = self:getPlaceNode(info.cur_place_floor)
		item = self:getOneItem(info, parentNode)
		self.items_[item.hashCode] = item

		info:setHashCode(item.hashCode)
		self:updateGridNum(info)

		info.item = item

		self:updateFunitureNum(info, 1)
	end

	if info.type == xyd.HouseItemType.FLOOR then
		self.itemFloor_ = item
	elseif info.type == xyd.HouseItemType.WALL_PAPER then
		self.itemWallPaper_ = item
	end

	return item
end

function HouseMap:getNewCode()
	self.hashCodeCount = self.hashCodeCount + 1

	return self.hashCodeCount
end

function HouseMap:getOneItem(info, parentNode)
	local item = HouseItem.new(parentNode, self)

	item:init(info)

	local depth = self:getItemDepth(info)

	self:setItemDepth(item, depth)

	item.hashCode = self:getNewCode()

	return item
end

function HouseMap:getItemDepth(info)
	local depth = 0

	if info.parent then
		local length = info.parent:getInfo():length()
		depth = info.coord_x + info.coord_y * length
	else
		depth = info.coord_x + info.coord_y * self.mapCol
	end

	if info.cur_place_floor == xyd.HouseItemPlaceFloor.DECORATION then
		return depth * self.reserver_level
	else
		return depth
	end
end

function HouseMap:setItemDepth(item, newDepth)
	local parentDepth = item:getParentDepth()

	item:updateDepthObj(newDepth + parentDepth)
	item:setSpineLevel()
end

function HouseMap:getItemByCode(hashCode)
	return self.items_[hashCode]
end

function HouseMap:moveChildItemAndChangeGridType(info, gridTypeIndex)
	if #info.childs > 0 then
		local ____TS_array = info.childs

		for ____TS_index = 1, #____TS_array do
			local child = ____TS_array[____TS_index]
			local childInfo = child:getInfo()

			childInfo:updateGridType(gridTypeIndex)
			self:updateTmpGridNum(childInfo)
			childInfo.item:updatePos()
			childInfo.item:initGrid()

			if #childInfo.childs > 0 then
				self:moveChildItemAndChangeGridType(childInfo, gridTypeIndex)
			end
		end
	end
end

function HouseMap:moveChildItem(info)
	if #info.childs > 0 then
		for i = 1, #info.childs do
			local child = info.childs[i]
			local childInfo = child:getInfo()

			self:updateTmpGridNum(childInfo)

			if #childInfo.childs > 0 then
				self:moveChildItem(childInfo)
			end
		end
	end
end

function HouseMap:moveItemByPos(info, pos)
	self:resetTmpGridNum(info)

	if pos.grid_type_index > -1 then
		info:updateGridType(pos.grid_type_index)

		local parentNode = self:getPlaceNode(info.cur_place_floor)

		info.item:changeParent(parentNode)

		local oldPos = {
			coord_x = info.coord_x,
			coord_y = info.coord_y
		}

		info:updateCoord(pos.coord_x, pos.coord_y)
		info.item:updatePos()
		info.item:initGrid()
		self:updateTmpGridNum(info)
		self:moveChildItemAndChangeGridType(info, pos.grid_type_index)
	else
		info:updateCoord(pos.coord_x, pos.coord_y)
		self:updateTmpGridNum(info)
		self:moveChildItem(info)
		info.item:updatePos()
	end
end

function HouseMap:moveItem(stageX, stageY, info)
	local mousePos = xyd.mouseWorldPos()
	local pos = self.houseGrid_:changeStagePosToGrid(mousePos.x, mousePos.y, info)

	self:moveItemByPos(info, pos)
	self:setNeedSave(true)
end

function HouseMap:moveHeroItem(stageX, stageY, item)
	local mousePos = xyd.mouseWorldPos()
	local info = item:getInfo()
	local pos = self.houseGrid_:changeStagePosToGrid(mousePos.x, mousePos.y, info, 70)

	info:updateCoord(pos.coord_x, pos.coord_y)
	item:updatePos()
end

function HouseMap:getMapPosByInfo(info)
	if info.special_type == xyd.HouseItemSpecialType.FLOOR_OR_WALL_PAPER then
		return {
			x = 0,
			y = 0
		}
	end

	local anchor = 1

	if info.cur_grid_type ~= xyd.HouseGridType.FLOOR then
		anchor = 2
	end

	local x_ = info:stageX() + info:length() / anchor
	local y_ = info:stageY() + info:width() / anchor
	local pos = self.houseGrid_:getPiexlPosition(x_, y_, info.cur_grid_type)

	if info.parent then
		local parentPos = info.parent:getGameObject().transform.localPosition
		pos.x = pos.x - parentPos.x
		pos.y = pos.y - parentPos.y
	end

	return pos
end

function HouseMap:getHeroPosByCoord(coordX, coordY)
	local x_ = coordX + 1
	local y_ = coordY + 1
	local pos = self.houseGrid_:getPiexlPosition(x_, y_, xyd.HouseGridType.FLOOR)

	return pos
end

function HouseMap:getSelectBox()
	if not self.selectBox_ then
		self.selectBox_ = HouseSelectBox.new(self.parentNode_)

		self.selectBox_:setDepth(9500)
	end

	self.selectBox_:SetActive(true)

	return self.selectBox_
end

function HouseMap:resetSelectItemPos()
	if not self.curSelectItem_ then
		return
	end

	local info = self.curSelectItem_:getInfo()
	local maps_ = self:getMaps(info)
	local index = info.coord_y * self.mapCol + info.coord_x
	local data = self:parseGridNum(maps_[index])

	if data.val ~= 0 and data.hashCode > 0 then
		local item = self:getItemByCode(data.hashCode)

		if item ~= self.curSelectItem_ then
			info.parent = item

			table.insert(item:getInfo().childs, self.curSelectItem_)
			self.curSelectItem_:changeParent(item:getGameObject())
			info:updateRelativePos(item:getInfo())
		end
	end

	self.curSelectItem_:updatePos()
end

function HouseMap:resetSelectItem()
	if not self.curSelectItem_ then
		return
	end

	self:resetSelectItemPos()

	local info = self.curSelectItem_:getInfo()

	self:syncMap(info)
	self:hideGrid(info)
	self.curSelectItem_:changeStaus(false)

	self.curSelectItem_.touchEnabled = true
	self.curSelectItem_ = nil

	self:updateZOrder(info)
end

function HouseMap:touchChildItem(info)
	if #info.childs > 0 then
		for i = 1, #info.childs do
			local child = info.childs[i]
			local childInfo = child:getInfo()

			if #childInfo.childs > 0 then
				self:touchChildItem(childInfo)
			end

			self:removeItemInMap(childInfo)
		end
	end
end

function HouseMap:touchItem(item)
	if not self.canSetFurniture_ or item:checkCanTouch() == false then
		return
	end

	if self.curSelectItem_ and self.curSelectItem_ == item then
		return false
	elseif self.curSelectItem_ then
		if self.curSelectItem_:checkNoAction() then
			self:resetSelectItem()
		else
			xyd.alert(xyd.AlertType.TIPS, __("HOUSE_TEXT_31"))

			return false
		end
	end

	self.curSelectItem_ = item
	local info = item:getInfo()

	self:touchChildItem(info)
	self:removeItemInMap(info)

	if info.parent then
		info:removeInParent()

		info.parent = nil

		if item.parent then
			item:getGameObject().transform.parent = nil
		end
	end

	local parentNode = self:getPlaceNode(info.cur_place_floor)

	item:changeParent(parentNode)
	self:setItemDepth(item, 8000)
	self:updateChildZOrder(item)
	item:updatePos()
	item:initGrid()
	info:setRecordInfo(info.coord_x, info.coord_y, info.is_flip, info.grid_type_index)
	self:showGrid(info)

	local selectBox = self:getSelectBox()

	selectBox:setInfo(item)
	selectBox:playShowAction()

	return true
end

function HouseMap:hideSelectBox()
	local selectBox = self:getSelectBox()

	if selectBox then
		selectBox:SetActive(false)
	end
end

function HouseMap:longTouchHeroItem(heroItem)
	local info = heroItem:getInfo()

	if info.parent then
		info.parent:removeHeroNode(heroItem)

		info.parent = nil
	else
		self:resetHeroMapGridNum(info)
	end

	local parentNode = self:getPlaceNode(info.cur_place_floor)

	heroItem:changeParent(parentNode)
	heroItem.go:GetComponent(typeof(UIRect)):ParentHasChanged()
	heroItem:updatePos()
	self:setItemDepth(heroItem, 8000)
end

function HouseMap:flipSelectChildItem(info)
	if #info.childs > 0 then
		for i = 1, #info.childs do
			local child = info.childs[i]
			local childInfo = child:getInfo()
			childInfo.is_flip = 1 - childInfo.is_flip
			local tmpx = childInfo.coord_x
			childInfo.coord_x = childInfo.coord_y
			childInfo.coord_y = tmpx

			self:updateTmpGridNum(childInfo)
			childInfo.item:updatePos()

			if #childInfo.childs > 0 then
				self:flipSelectChildItem(childInfo)
			end
		end
	end
end

function HouseMap:flipItem(item)
	local info = item:getInfo()

	self:resetTmpGridNum(info)

	info.is_flip = 1 - info.is_flip

	self:updateTmpGridNum(info)
	item:updateFilp()
	self:flipSelectChildItem(info)
end

function HouseMap:flipSelectItem()
	if not self.curSelectItem_ then
		return
	end

	self:flipItem(self.curSelectItem_)
	self:setNeedSave(true)
end

function HouseMap:confirmSelectItem()
	local item = self.curSelectItem_

	self:resetSelectItem()

	local selectBox = self:getSelectBox()

	selectBox:playHideAction()
end

function HouseMap:delectChildInItems(item)
	local info = item:getInfo()

	if #info.childs > 0 then
		for _, child in ipairs(info.childs) do
			self.items_[child.hashCode] = nil

			self:removeTimeAction(child.hashCode)
			self:updateFunitureNum(child:getInfo(), -1)
			self:delectChildInItems(child)
		end
	end
end

function HouseMap:delectSelectItem()
	if not self.curSelectItem_ then
		return
	end

	local item = self.curSelectItem_

	self:hideSelectBox()

	local info = item:getInfo()
	self.items_[item.hashCode] = nil

	NGUITools.Destroy(item:getGameObject())

	if info.childs then
		self:delectChildInItems(item)
	end

	self:removeTimeAction(item.hashCode)
	self:resetTmpGridNum(info)
	self:updateFunitureNum(info, -1)
	self:hideGrid(info)
	self:setNeedSave(true)

	self.curSelectItem_ = nil
end

function HouseMap:cancelSelectItem()
	if not self.curSelectItem_ then
		return
	end

	local info = self.curSelectItem_:getInfo()
	local recordInfo_ = info.recordInfo_

	if recordInfo_ == nil then
		return
	end

	if recordInfo_.is_flip ~= info.is_flip then
		self:flipItem(self.curSelectItem_)
	end

	local pos = {
		grid_type_index = -1,
		coord_x = recordInfo_.coord_x,
		coord_y = recordInfo_.coord_y
	}

	if recordInfo_.grid_type_index ~= info.grid_type_index then
		pos.grid_type_index = recordInfo_.grid_type_index
	end

	self:moveItemByPos(info, pos)
	self:confirmSelectItem()
end

function HouseMap:checkHeroPosValid(info, offX, offY)
	if offX == nil then
		offX = 0
	end

	if offY == nil then
		offY = 0
	end

	local coordX = info.coord_x + offX
	local coordY = info.coord_y + offY
	local result = {
		flag = false,
		interact = false
	}

	if coordX < 0 or self.mapCol <= coordX or coordY < 0 or self.mapRow <= coordY then
		return result
	elseif info.item then
		local isRide = info.item:isRide()

		if isRide and (coordX == 0 or coordY == 0) then
			return result
		end
	end

	local index = coordY * self.mapCol + coordX
	local maps_ = self.heroMap_
	local data = self:parseGridNum(maps_[index])
	local gridNum = data.val
	result.hashCode = data.hashCode

	if gridNum == nil or gridNum == 0 then
		result.flag = true
	else
		local item = self:getItemByCode(data.hashCode)

		if item then
			item = self:getRootItem(item)
			local itemInfo = item:getInfo()

			if itemInfo:canInteract() then
				result.flag = true
				result.interact = true
			end
		end
	end

	return result
end

function HouseMap:checkHeroPosInteract(info)
	local index = info.coord_y * self.mapCol + info.coord_x
	local maps_ = self.heroMap_
	local data = self:parseGridNum(maps_[index])
	local gridNum = data.val
	local result = {
		flag = false
	}
	local parentItem = self:getItemByCode(data.hashCode)

	if parentItem then
		local parentInfo = parentItem:getInfo()
		local heroItem = info.item

		if parentInfo:canInteract() or parentInfo:getInteractIndex(heroItem) > -1 then
			result.flag = true
			result.item = parentItem

			parentInfo:addInteractHero(heroItem)

			info.parent = parentItem
		end
	end

	return result
end

function HouseMap:checkValid(index, info)
	local maps_ = self:getMaps(info)
	local data = self:parseGridNum(maps_[index])
	local gridNum = data.val
	local result = {
		flag = false,
		num = gridNum,
		hashCode = data.hashCode
	}

	if gridNum == nil or gridNum == 0 or gridNum > 0 and gridNum < info.floor then
		result.flag = true
	end

	return result
end

function HouseMap:getInvalidGrids(info)
	local invalidGrids = {}
	local gridNum, hashCode, parentItem = nil
	local colorGrids = {}
	local isValid = true
	local endy = info.coord_y + info:width() - 1
	local endx = info.coord_x + info:length() - 1

	for row = info.coord_y, endy do
		for col = info.coord_x, endx do
			local index = row * self.mapCol + col
			local result = nil

			if col < 0 or self.mapCol <= col or row < 0 or self.mapRow <= row then
				result = {
					flag = false
				}
			else
				result = self:checkValid(index, info)
			end

			if gridNum == nil then
				gridNum = result.num
			end

			if hashCode == nil then
				hashCode = result.hashCode
			end

			local key = tostring(col - info.coord_x) .. "#" .. tostring(row - info.coord_y)

			if not result.flag then
				isValid = false
				invalidGrids[key] = xyd.HouseGridColorType.RED
			elseif result.num ~= gridNum or result.hashCode ~= hashCode then
				isValid = false
			end

			if result.num and result.num > 0 then
				colorGrids[key] = xyd.HouseGridColorType.BLUE
			end

			if not parentItem and hashCode then
				parentItem = self:getItemByCode(hashCode)
			end
		end
	end

	return {
		invalidGrids = invalidGrids,
		colorGrids = colorGrids,
		isValid = isValid,
		parentItem = parentItem
	}
end

function HouseMap:checkItemPosIsValid(item)
	return item:isPosValid()
end

function HouseMap:getItemByObj(go)
	local selectItem = nil

	for _, item in pairs(self.items_) do
		if item and item:getGameObject() == go then
			selectItem = item

			break
		end
	end

	return selectItem
end

function HouseMap:getEffectItems(info, placeFloor)
	local items = {}
	local curPlaceFloor = placeFloor or info.cur_place_floor
	local parentNode = self:getPlaceNode(curPlaceFloor)

	for i = 1, parentNode.transform.childCount do
		local child = parentNode.transform:GetChild(i - 1).gameObject
		local item = self:getItemByObj(child)

		table.insert(items, item:getInfo())
	end

	return items
end

function HouseMap:sortFuc(arry)
end

function HouseMap:updateZOrder(info)
	if info.cur_place_floor ~= xyd.HouseItemPlaceFloor.DECORATION then
		local depth = self:getItemDepth(info)

		self:setItemDepth(info.item, depth)

		return
	end

	self:initTopMask()
	self:resetZOrder()
end

function HouseMap:updateChildZOrder(parentItem)
	local parentInfo = parentItem:getInfo()
	local childs = parentInfo.childs
	local itemInfos = {}

	for _, child in ipairs(childs) do
		table.insert(itemInfos, child:getInfo())
	end

	for i = 1, #itemInfos do
		local itemInfo = itemInfos[i]
		local item = itemInfo.item

		if item then
			local depth = self:getItemDepth(itemInfo)

			self:setItemDepth(item, depth)
		end
	end
end

function HouseMap:updateZOrderAll()
	local needZOrder = {
		xyd.HouseItemPlaceFloor.DECORATION
	}

	self:initTopMask()
	self:resetZOrder()
end

function HouseMap:getAttrkKey(id, code, x, y, l, w, h)
	return id .. "#" .. code .. "#" .. x .. "#" .. y .. "#" .. l .. "#" .. w .. "#" .. h
end

function HouseMap:parseAttrKey(key)
	local arry = xyd.split(key, "#", true)
	local attr = {
		id = arry[1],
		hashCode = arry[2],
		coord_x = arry[3],
		coord_y = arry[4],
		length = arry[5],
		width = arry[6],
		height = arry[7]
	}

	return attr
end

function HouseMap:initTopMask()
	local maps_ = self:getMaps({
		cur_grid_type = xyd.HouseGridType.FLOOR,
		special_type = xyd.HouseItemSpecialType.NORMAL
	})
	self.topMask_ = {}
	self.topologyKeys = {}
	local keys = {}

	for row = 0, self.mapRow - 1 do
		for col = 0, self.mapCol - 1 do
			local key = ""
			local index = row * self.mapCol + col

			if maps_[index] then
				local data = self:parseGridNum(maps_[index])
				local item = self:getItemByCode(data.hashCode)

				if item and not keys[data.hashCode] then
					if not item:getInfo().parent then
						local info = item:getInfo()
						keys[data.hashCode] = true

						self:updateTopMask(info.item_id, data.hashCode, info.coord_x, info.coord_y, info:length(), info:width(), info.c_height)
					else
						local parentItem = item:getInfo().parent

						if not keys[parentItem.hashCode] then
							local info = parentItem:getInfo()
							keys[parentItem.hashCode] = true

							self:updateTopMask(info.item_id, parentItem.hashCode, info.coord_x, info.coord_y, info:length(), info:width(), info.c_height)
						end
					end
				end
			else
				self:updateTopMask(0, -1, col, row, 1, 1, 1)
			end
		end
	end
end

function HouseMap:updateTopMask(id, hashCode, coord_x, coord_y, length, width, height)
	local key = self:getAttrkKey(id, hashCode, coord_x, coord_y, length, width, height)

	table.insert(self.topologyKeys, key)

	if height < 1 then
		height = 1
	end

	for deltaX = -height, length - 1 do
		local coordX = coord_x + deltaX

		for deltaY = -height, width - 1 do
			local coordY = coord_y + deltaY

			if coordX >= 0 and coordY >= 0 and (coordX < coord_x or coordY < coord_y) and deltaY >= deltaX - height - length and deltaX >= deltaY - height - width then
				local index = coordY * self.mapCol + coordX
				self.topMask_[index] = self.topMask_[index] or {}

				table.insert(self.topMask_[index], key)
			end
		end
	end
end

function HouseMap:getItemTopologyParent(key)
	local topologyParent = {}
	local attrs = self:parseAttrKey(key)

	for deltaX = 0, attrs.length - 1 do
		for deltaY = 0, attrs.width - 1 do
			local coordX = attrs.coord_x + deltaX
			local coordY = attrs.coord_y + deltaY
			local index = coordY * self.mapCol + coordX
			local mask = self.topMask_[index]

			if mask and next(mask) then
				for i = 1, #mask do
					if xyd.arrayIndexOf(topologyParent, mask[i]) < 0 and mask[i] ~= key then
						table.insert(topologyParent, mask[i])
					end
				end
			end
		end
	end

	return topologyParent
end

function HouseMap:resetZOrder()
	local rootKeys = self.topologyKeys
	local topology = {}

	for i = 1, #rootKeys do
		topology[rootKeys[i]] = {
			parent = {},
			child = {}
		}
	end

	local maxD = 0
	local maxItem = nil

	for i = 1, #rootKeys do
		local parentKeys = self:getItemTopologyParent(rootKeys[i])
		topology[rootKeys[i]].parent = parentKeys
		topology[rootKeys[i]].inDegree = #parentKeys

		for _, key in pairs(parentKeys) do
			table.insert(topology[key].child, rootKeys[i])
		end

		if maxD < #parentKeys then
			maxD = #parentKeys
			maxItem = topology[rootKeys[i]]
		end
	end

	local result = {}
	local count = 0

	while #result < #rootKeys do
		count = count + 1

		if count > #rootKeys then
			dump("errrrrrrrrrrrrrrrrrrrrrrrrrrrrrr")

			break
		end

		for key, value in pairs(topology) do
			if value.inDegree <= 0 and xyd.arrayIndexOf(result, key) < 0 then
				table.insert(result, key)

				for i = 1, #value.child do
					local childKey = value.child[i]
					topology[childKey].inDegree = topology[childKey].inDegree - 1
				end

				topology[key] = nil
			end
		end
	end

	self.keyToZOrder = {}
	local depthNum = 1

	for i = #result, 1, -1 do
		local key = result[i]
		self.keyToZOrder[key] = depthNum
		local attrs = self:parseAttrKey(key)
		local item = self:getItemByCode(attrs.hashCode)
		depthNum = depthNum + 2

		if item then
			local num = #item:getInfo().childs
			depthNum = depthNum + num * 5
		end
	end

	for i = 1, #result do
		local key = result[i]
		local attrs = self:parseAttrKey(key)

		if attrs.hashCode > -1 then
			local item = self:getItemByCode(attrs.hashCode)

			if item then
				self:setItemDepth(item, self.keyToZOrder[key] * self.reserver_level)
				self:updateChildZOrder(item)
			end
		end
	end
end

function HouseMap:getItemIndex(item)
	local tmpItem = item
	local itemInfo = tmpItem:getInfo()

	while itemInfo.parent do
		tmpItem = itemInfo.parent
		itemInfo = tmpItem:getInfo()
	end

	local childIndex = 0

	if tmpItem.parent then
		childIndex = tmpItem.parent:getChildIndex(tmpItem)
	end

	return childIndex
end

function HouseMap:getRootItem(item)
	local tmpItem = item
	local itemInfo = tmpItem:getInfo()

	while itemInfo.parent do
		tmpItem = itemInfo.parent
		itemInfo = tmpItem:getInfo()
	end

	return tmpItem
end

function HouseMap:updateAllHeroZOrder()
	local heroItems = self.heroItems_
	local selects = {}
	local zorders = self.keyToZOrder

	for i = 1, #heroItems do
		local item = heroItems[i]

		if item:canResetZorder() then
			local info = item:getInfo()
			local key = self:getAttrkKey(0, -1, info.coord_x, info.coord_y, info:length(), info:width(), info.c_height)

			if zorders[key] then
				self:setItemDepth(item, zorders[key] * self.reserver_level)
			end
		end
	end
end

function HouseMap:hideGrid(info)
	self.houseGrid_:hideGridLayout(info)
end

function HouseMap:showGrid(info)
	self.houseGrid_:showGridLayout(info)
end

function HouseMap:getRandomFreeGrid(allFreeGrids, info, isRide)
	local trueFreeGrids = {}

	if isRide then
		for i = 1, #allFreeGrids do
			local grid = allFreeGrids[i]

			if grid.coord_x > 0 and grid.coord_y > 0 then
				table.insert(trueFreeGrids, grid)
			end
		end
	else
		trueFreeGrids = allFreeGrids
	end

	if #trueFreeGrids <= 0 then
		return {
			coord_y = -1,
			coord_x = -1
		}
	end

	local randNum = math.ceil(xyd.random() * #trueFreeGrids)
	local selectGrid = table.remove(trueFreeGrids, randNum)

	return selectGrid
end

function HouseMap:updateHeros(play_sound)
	self:syncHeroMap()

	local params = self:getHerosInfo()

	if not params then
		return
	end

	local allFreeGrids = self:getHeroAllFreeGrids()
	local node = self:getPlaceNode(xyd.HouseItemPlaceFloor.DECORATION)
	local table_id = 0
	local partner_id = 0

	if #params > 0 then
		local ind = math.floor(math.random() * #params) + 1
		table_id = params[ind].tableID
		partner_id = params[ind].partnerID
	end

	local all = 1
	local dialog = {}

	if play_sound and table_id > 0 then
		if play_sound == 1 then
			dialog = xyd.tables.partnerTable:getHouseDialog(table_id, xyd.models.slot:getPartner(partner_id):getSkinID())
		elseif play_sound == 2 then
			dialog = xyd.tables.partnerTable:getHouseSetDialog(table_id, xyd.models.slot:getPartner(partner_id):getSkinID())
		end

		if self.curDialog_ then
			self:clearDialog()
		end

		dialog.itemList = {}
		self.curDialog_ = dialog
	else
		if self.curDialog_ then
			self:clearDialog()
		end

		self.curDialog_ = {
			itemList = {}
		}
	end

	local function callback()
		if play_sound then
			if all < #self.curDialog_.itemList then
				return
			end

			xyd.SoundManager.get():playSound(dialog.sound)

			self.playCommonDialog = true

			for i = 1, #self.curDialog_.itemList do
				local item = self.curDialog_.itemList[i]

				item:playDialog("...")
			end

			local key = xyd.getTimeKey()

			XYDCo.WaitForTime(dialog.time, function ()
				local win = xyd.getWindow("house_window")

				if not win then
					return
				end

				if self.curDialog_ and self.curDialog_.itemList then
					for i = 1, #self.curDialog_.itemList do
						local item = self.curDialog_.itemList[i]

						if item and not tolua.isnull(item.go) then
							item:hideDialog()
						end
					end
				end

				self.playCommonDialog = false
			end, key)

			dialog.timeOutId = key
		end
	end

	local dialogItems = {}

	for i = 1, #params do
		local partnerInfo = params[i]
		local modelID = xyd.getModelID(partnerInfo.table_id, false, partnerInfo.skin_id, 1)
		local houseModelIDs = xyd.tables.modelTable:getHouseModel(modelID)

		if not houseModelIDs or #houseModelIDs == 0 or houseModelIDs[1] == 0 then
			houseModelIDs = {
				modelID
			}
		end

		for _, curModelID in ipairs(houseModelIDs) do
			local info = HouseItemInfo.new()

			info:initHero({
				coord_y = 0,
				is_flip = 0,
				coord_x = 0
			})

			local isRide = xyd.tables.housePartnerTable:isRide(curModelID)
			local pos = self:getRandomFreeGrid(allFreeGrids, info, isRide)

			if pos.coord_x >= 0 and pos.coord_y >= 0 then
				info:updateCoord(pos.coord_x, pos.coord_y)

				local fx_callback = nil

				if partnerInfo.partnerID == partner_id then
					fx_callback = callback
				end

				local item = HouseHero.new(node)

				if partnerInfo.partnerID == partner_id then
					table.insert(self.curDialog_.itemList, item)
				end

				item:init(info, partnerInfo, curModelID, fx_callback)

				item.hashCode = self:getNewCode()

				table.insert(self.heroItems_, item)
				table.insert(dialogItems, item)

				info.item = item

				info:setHashCode(item.hashCode)

				self.items_[item.hashCode] = item

				self:updateHeroMapGridNum(info)
			end
		end
	end

	local senpaiFloor = xyd.models.house:getSenpaiFloor()
	local wnd = xyd.WindowManager.get():getWindow("house_window")

	if wnd and wnd:getCurFloor() == senpaiFloor then
		local infoD = HouseItemInfo.new()

		infoD:initDress({
			coord_y = 0,
			is_flip = 0,
			coord_x = 0
		})

		local pos = self:getRandomFreeGrid(allFreeGrids, infoD, false)

		if pos.coord_x >= 0 and pos.coord_y >= 0 then
			infoD:updateCoord(pos.coord_x, pos.coord_y)

			local item = HouseHero.new(node)

			item:initDress(infoD, {}, xyd.models.selfPlayer.playerID_, nil)

			item.hashCode = self:getNewCode()

			table.insert(self.heroItems_, item)

			infoD.item = item

			infoD:setHashCode(item.hashCode)

			self.items_[item.hashCode] = item

			self:updateHeroMapGridNum(infoD)
		end
	end

	self:updateAllHeroZOrder()
	self:endHeroAction()
	self:startHeroAction()

	local info = HouseItemInfo:new()

	info:initHero({})

	local map_ = self:getMaps(info)

	self.houseDialog_:init({
		heroItems = dialogItems,
		items = self.items_,
		map = map_
	})

	self.isNewUpdateZorder = true

	self:updateZOrderAll()
end

function HouseMap:startHeroAction()
	self.heroTimer_ = FrameTimer.New(handler(self, self.playHeroAction), 1, -1)

	self.heroTimer_:Start()
end

function HouseMap:endHeroAction()
	if self.heroTimer_ then
		self.heroTimer_:Stop()

		self.heroTimer_ = nil
	end
end

function HouseMap:playHeroAction()
	self.houseDialog_:update()
	self:updateTimeAction()

	for i = 1, #self.heroItems_ do
		local item = self.heroItems_[i]

		item:playAction(self.isNewUpdateZorder)
	end

	if self.isNewUpdateZorder then
		self.isNewUpdateZorder = false
	end
end

function HouseMap:initMoveAction(item, directIndex)
	local info = item:getInfo()
	local moveNum = 1
	local moveData = nil
	local direct = {
		{
			x = 0,
			y = 1
		},
		{
			x = 0,
			y = -1
		},
		{
			x = 1,
			y = 0
		},
		{
			x = -1,
			y = 0
		}
	}
	local tmpInfo = HouseItemInfo:new()

	tmpInfo:initHero({
		coord_x = info.coord_x,
		coord_y = info.coord_y,
		is_flip = info.is_flip
	})

	local index = nil

	if directIndex ~= nil then
		index = directIndex
	else
		index = xyd.getRandomByExceptArry({
			1,
			2,
			3,
			4
		}, {})
	end

	local isRide = item:isRide()
	local exceptArry = {}
	local heroCanInteract = item:checkHeroCanInteract()

	while moveNum > 0 do
		local curDirect = direct[index]
		local result = self:checkHeroPosValid(tmpInfo, curDirect.x, curDirect.y)
		local coordX = tmpInfo.coord_x + curDirect.x
		local coordY = tmpInfo.coord_y + curDirect.y

		if not result.flag or result.interact and not heroCanInteract or isRide and (coordX == 0 or coordY == 0) then
			table.insert(exceptArry, index)

			index = xyd.getRandomByExceptArry({
				1,
				2,
				3,
				4
			}, exceptArry)

			if index == -1 then
				break
			end
		else
			tmpInfo:updateCoord(coordX, coordY)

			local pos = self:getMapPosByInfo(tmpInfo)
			moveData = {
				x = pos.x,
				y = pos.y,
				direct_x = curDirect.x,
				direct_y = curDirect.y,
				interact = result.interact,
				index = index
			}

			if result.interact then
				local parentItem = self:getItemByCode(result.hashCode)
				local parentInfo = parentItem:getInfo()

				parentInfo:addInteractHero(item)

				info.parent = parentItem

				break
			end

			moveNum = moveNum - 1
		end
	end

	return moveData
end

function HouseMap:hideHeros()
	if #self.heroItems_ > 0 then
		for i = 1, #self.heroItems_ do
			local item = self.heroItems_[i]
			local info = item:getInfo()

			if info.parent then
				info.parent:removeHeroNode(item)

				info.parent = nil
			end

			item:clearAll()

			self.items_[item.hashCode] = nil

			NGUITools.Destroy(item:getGameObject())
		end
	end

	self.heroItems_ = {}

	self:endHeroAction()
end

function HouseMap:checkCanSave()
	if self.curSelectItem_ and self.curSelectItem_:checkNoAction() == false then
		xyd.alert(xyd.AlertType.TIPS, __("HOUSE_TEXT_31"))

		return false
	end

	return true
end

function HouseMap:hideSetView()
	if self.curSelectItem_ and self.curSelectItem_:checkNoAction() then
		self:resetSelectItem()
	end

	self:hideSelectBox()
end

function HouseMap:getRoundFreeGrids(item)
	local info = item:getInfo()
	local tmpInfo = info

	if info.parent then
		tmpInfo = info.parent:getInfo()
	end

	local freeList = {}

	for row = tmpInfo.coord_y - 1, tmpInfo.coord_y + tmpInfo:width() do
		for col = tmpInfo.coord_x - 1, tmpInfo.coord_x + tmpInfo:length() do
			if row >= 0 and col >= 0 and row < self.mapRow and col < self.mapCol and self:isCanAdd(col, row, info) then
				table.insert(freeList, {
					x = col,
					y = row
				})
			end
		end
	end

	return freeList
end

function HouseMap:addTimeAction(item, delay)
	table.insert(self.timeAction_, {
		count = 0,
		item = item,
		delay_frame = delay * 30
	})
end

function HouseMap:removeTimeAction(hashCode)
	for i = 1, #self.timeAction_ do
		local action = self.timeAction_[i]
		local item = action.item

		if item.hashCode == hashCode then
			table.remove(self.timeAction_, i)

			break
		end
	end
end

function HouseMap:updateTimeAction()
	for i = 1, #self.timeAction_ do
		local action = self.timeAction_[i]
		action.count = action.count + 1

		if action.delay_frame < action.count then
			local flag = action.item:playTimeAction()

			if flag then
				action.count = 0
			end
		end
	end
end

function HouseMap:clearDialog()
	if self.curDialog_ then
		if self.curDialog_.sound then
			xyd.SoundManager.get():stopSound(self.curDialog_.sound)
		end

		if self.curDialog_.timeoutId then
			XYDCo.StopWait(self.curDialog_.timeOutId)
		end

		if self.curDialog_.itemList then
			for i = 1, #self.curDialog_.itemList do
				local item = self.curDialog_.itemList[i]

				if item and not tolua.isnull(item.go) then
					item:hideDialog()
				end
			end
		end

		self.curDialog_ = {}
	end
end

function HouseMap:isPlayCommonDialog()
	return self.playCommonDialog
end

function HouseMap:clearHero()
	for i in pairs(self.heroItems_) do
		if self.heroItems_[i] then
			self.heroItems_[i]:clearcClip()
		end
	end
end

return HouseMap
