local HouseDialogAction = class("HouseDialogAction")
local HouseDialogListTable = xyd.tables.houseDialogListTable
local HouseDialogTable = xyd.tables.houseDialogTable

function HouseDialogAction:ctor(params)
	self.id_ = 0
	self.items_ = {}
	self.timeCount_ = 0
	self.actions_ = {}
	self.actionCount_ = 1
	self.curAction_ = nil
	self.moveAction_ = nil
	self.isEnd_ = false
	self.isMoveEnd_ = false
	self.totalPath_ = {}
	self.id_ = params.id
	self.items_ = params.info
	self.totalPath_ = params.path

	self:init()
end

function HouseDialogAction:init()
	self.actions_ = HouseDialogListTable:getDialog(self.id_)
	self.actionCount_ = 1
end

function HouseDialogAction:getItems()
	return self.items_
end

function HouseDialogAction:getItem(pos)
	return self.items_[pos]
end

function HouseDialogAction:isEnd()
	return self.isEnd_
end

function HouseDialogAction:update()
	if self.actionCount_ == 1 and self:checkMoveAction() then
		return
	end

	local curAction_ = self:getCurAction()

	if not curAction_ or #curAction_ == 0 then
		self.isEnd_ = true

		return
	end

	self:playAction()
	self:countAction()
	self:checkOneActionEnd()
end

function HouseDialogAction:getPathKey(item1, item2)
	return tostring(item1.hashCode) .. "|" .. tostring(item2.hashCode)
end

function HouseDialogAction:checkMoveAction()
	local isMove = HouseDialogListTable:needMove(self.id_)

	if not isMove or self.isMoveEnd_ then
		return false
	end

	if not self.moveAction_ then
		self:initMoveAction()
	end

	if not self.moveAction_ then
		self.isMoveEnd_ = true

		return
	end

	local isTotalEnd = true

	for _, action in ipairs(self.moveAction_) do
		if not action.is_end then
			action.moveItem:playDialogMove(action)
		end

		if not action.is_end then
			isTotalEnd = false
		end
	end

	if isTotalEnd then
		self.isMoveEnd_ = true

		self:updateItemsFlip()
		self:playMoveEndAction()
	end

	return not self.isMoveEnd_
end

function HouseDialogAction:playMoveEndAction()
	for _, action in ipairs(self.moveAction_) do
		if action.move_end_action then
			local data = xyd.split(action.move_end_action, "#")

			action.moveItem:playActionByName(data[1], tonumber(data[2]))
		end
	end
end

function HouseDialogAction:updateItemsFlip()
	local flip = HouseDialogListTable:getFlip(self.id_)

	if flip == 0 then
		return
	end

	local items = self.items_

	if #items ~= 2 then
		return
	end

	if items[2]:getInfo():isHero() then
		self:updateHerosFlip()
	else
		self:updateHeroAndItemFlip()
	end
end

function HouseDialogAction:updateHeroAndItemFlip()
	local items = self.items_
	local itemFlip = items[2]:getInfo().is_flip
	local heroInfo = items[1]:getInfo()
	local flip = HouseDialogListTable:getFlip(self.id_)

	if flip == 1 then
		heroInfo.is_flip = itemFlip
	elseif flip == 2 then
		heroInfo.is_flip = 1 - itemFlip
	end

	items[1]:updateScaleX()
end

function HouseDialogAction:updateHerosFlip()
	local data = {}

	for i = 1, #self.items_ do
		local item = self.items_[i]

		table.insert(data, item)
	end

	table.sort(data, function (a, b)
		local info0 = a:getInfo()
		local info1 = b:getInfo()

		if info0.coord_y ~= info1.coord_y then
			return info1.coord_y < info0.coord_y and true or false
		else
			if info1.coord_x < info0.coord_x then
				-- Nothing
			end

			return true
		end
	end)

	local flip = HouseDialogListTable:getFlip(self.id_)
	local info0 = data[1]:getInfo()

	if info0:isHero() then
		info0.is_flip = 0

		data[1]:updateScaleX()
	end

	local info1 = data[2]:getInfo()

	if info1:isHero() then
		if flip == 1 then
			info1.is_flip = 0
		elseif flip == 2 then
			info1.is_flip = 1
		end

		data[2]:updateScaleX()
	end
end

function HouseDialogAction:initMoveAction()
	local items = self.items_
	local moveItem = items[1]

	if not moveItem:getInfo():isHero() then
		return false
	end

	local data = {}
	local moveEndAction = HouseDialogListTable:moveEndAction(self.id_)

	for i = 2, #items do
		local item = items[i]
		local isHero_ = item:getInfo():isHero()

		if isHero_ then
			item:stopMoveWaitDialog()
		end

		local key = self:getPathKey(moveItem, item)
		local path_ = self.totalPath_[key]

		if path_ then
			local moveData = {
				is_end = false,
				index = 1,
				path = path_,
				endIndex = #path_,
				moveItem = moveItem,
				targetItem = item,
				move_end_action = moveEndAction[1]
			}

			if isHero_ then
				moveData.endIndex = moveData.endIndex - 2
			end

			table.insert(data, moveData)

			if moveItem:isInteract() then
				moveItem:resumeFree(path_[1])
			end
		end

		if isHero_ then
			local moveData = {
				is_end = false,
				index = 1,
				endIndex = 0,
				path = {},
				moveItem = item,
				targetItem = item,
				move_end_action = moveEndAction[i]
			}

			table.insert(data, moveData)
		end
	end

	moveItem:stopMoveWaitDialog()

	self.moveAction_ = data
end

function HouseDialogAction:getCurAction()
	if not self.curAction_ then
		local dialogs = self.actions_[self.actionCount_] or {}
		local data = {}

		for i = 1, #dialogs do
			local str = dialogs[i]
			local dialog = xyd.split(str, "#", true)

			table.insert(data, {
				is_play = false,
				item = self:getItem(dialog[1]),
				text = HouseDialogTable:getDialog(dialog[2]),
				count = HouseDialogTable:getTime(dialog[2]) * xyd.FRAME_RATE_30
			})
		end

		self.curAction_ = data
		self.actionCount_ = self.actionCount_ + 1
	end

	return self.curAction_
end

function HouseDialogAction:showDialog(action, isShow)
	local item = action.item
	local info = item:getInfo()
	local flag = true

	if info:isHero() then
		if isShow then
			flag = item:playDialog(action.text)
		else
			item:hideDialog()
		end
	end

	action.is_play = flag
end

function HouseDialogAction:playAction()
	for _, action in ipairs(self.curAction_) do
		if not action.is_play then
			self:showDialog(action, true)
		end
	end
end

function HouseDialogAction:countAction()
	for _, action in ipairs(self.curAction_) do
		action.count = action.count - 1

		if action.count <= 0 then
			self:showDialog(action, false)
		end
	end
end

function HouseDialogAction:checkOneActionEnd()
	local flag = true

	for _, action in ipairs(self.curAction_) do
		if action.count > 0 then
			flag = false

			break
		end
	end

	if flag then
		self.curAction_ = nil
	end
end

local HouseDialog = class("HouseDialog")
local MiscTable = xyd.tables.miscTable

function HouseDialog:ctor()
	self.parentNodes = {}
	self.mapRow = 24
	self.mapCol = 24
	self.validActions_ = {}
	self.fixedConditions = {
		2,
		3,
		8,
		9,
		10
	}
	self.itemList_ = {}
	self.themeList_ = {}
	self.itemTypeList_ = {}
	self.interactFurnitureList_ = {}
	self.allGroups_ = {}
	self.map_ = nil
	self.actionCd_ = {}
	self.nextJudgeCd_ = 0
	self.nextCleanCd_ = MiscTable:getNumber("house_dialog_cd3", "value") * xyd.FRAME_RATE_30
	self.detalRate_ = 0
	self.curActions_ = {}
	self.oldAction_ = {}
	self.minPathList_ = {}
	self.playingList_ = {}
	self.totalComfort_ = 0
end

function HouseDialog:get()
	if HouseDialog.INSTANCE == nil then
		HouseDialog.INSTANCE = HouseDialog.new()
	end

	return HouseDialog.INSTANCE
end

function HouseDialog:init(params)
	self.listTable_ = xyd.tables.houseDialogListTable
	self.heros_ = params.heroItems
	self.map_ = params.map
	self.curActions_ = {}
	self.minPathList_ = {}
	self.playingList_ = {}

	self:initItemList(params.items)
	self:initInteractList(params.items)
	self:initAllAction()
	self:initAllGroups()
end

function HouseDialog:initAllGroups()
	local data = {}

	for i = 1, #self.validActions_ do
		local id = self.validActions_[i]
		local groups = self.listTable_:getGroup(id)
		local list = self:initSingleGroup(groups)

		if list then
			data[id] = list
		end
	end

	self.allGroups_ = data
end

function HouseDialog:initSingleGroup(groups)
	local count = 1
	local flag = true
	local list = {}

	while count <= #groups do
		local selectItems = self:getItemsById(groups[count])

		if #selectItems == 0 then
			flag = false

			break
		end

		local flag2 = false
		local newList = {}

		for i = 1, #selectItems do
			local item = selectItems[i]

			if count == 1 then
				table.insert(newList, {
					item
				})

				flag2 = true
			else
				for j = 1, #list do
					local listItem = list[j]

					if xyd.arrayIndexOf(listItem, item) < 0 then
						local newListItem = xyd.getCopyData(listItem)

						table.insert(newListItem, item)
						table.insert(newList, newListItem)

						flag2 = true
					end
				end
			end
		end

		if flag2 == false then
			flag = false

			break
		end

		list = newList
		count = count + 1
	end

	if not flag then
		return nil
	end

	return list
end

function HouseDialog:getGroupListById(id)
	return self.allGroups_[id] or {}
end

function HouseDialog:initAllAction()
	self.validActions_ = {}
	local listTable = self.listTable_
	local ids = listTable:getIDs()

	for _, id in ipairs(ids) do
		if self:checkGroupValid(id) and self:checkFixedCondition(id) then
			table.insert(self.validActions_, id)
		end
	end
end

function HouseDialog:initItemList(items)
	self.itemList_ = {}
	local totalComfort = 0
	local HouseFurnitureTable = xyd.tables.houseFurnitureTable

	for hashCode in pairs(items) do
		local houseItem = items[hashCode]
		local info = houseItem:getInfo()
		local itemID = info.item_id

		if info:isHero() then
			local partnerInfo = houseItem:getPartnerInfo()
			local list = xyd.tables.partnerTable:getHeroList(partnerInfo.tableID)
			itemID = list[1]
		elseif not info:isDress() then
			totalComfort = totalComfort + HouseFurnitureTable:comfort(itemID)
		end

		if not self.itemList_[itemID] then
			self.itemList_[itemID] = {}
		end

		table.insert(self.itemList_[itemID], houseItem)
	end

	self.totalComfort_ = totalComfort
end

function HouseDialog:initInteractList(items)
	self.interactFurnitureList_ = {}
	self.themeList_ = {}
	self.itemTypeList_ = {}

	for hashCode in pairs(items) do
		local houseItem = items[hashCode]
		local info = houseItem:getInfo()

		if info.interact > 0 then
			table.insert(self.interactFurnitureList_, houseItem)
		end

		if not info:isHero() and not info:isDress() then
			local group = xyd.tables.houseFurnitureTable:groupId(info.item_id)

			if xyd.arrayIndexOf(self.themeList_, group) < 0 then
				table.insert(self.themeList_, group)
			end

			local type_ = info.type

			if xyd.arrayIndexOf(self.itemTypeList_, type_) < 0 then
				table.insert(self.itemTypeList_, type_)
			end
		end
	end
end

function HouseDialog:getInteractFurnitures(num)
	local data = {}

	for i = 1, #self.interactFurnitureList_ do
		local item = self.interactFurnitureList_[i]
		local info = item:getInfo()

		if num <= info.interactHeros.length then
			table.insert(data, item)
		end
	end

	return data
end

function HouseDialog:getItemsById(itemID)
	return self.itemList_[itemID] or {}
end

function HouseDialog:getFurnitureItem(itemID)
	local item = self:getItemsById(itemID)[1]

	return item
end

function HouseDialog:getHeroItem(itemID)
	local item = self:getItemsById(itemID)[1]

	return item
end

function HouseDialog:getHeroItemBySkin(itemID, skinID)
	local item = nil

	for i = 1, #self.heros_ do
		local heroItem = self.heros_[i]
		local info = heroItem:getPartnerInfo()

		if info.skin_id == tonumber(skinID) then
			item = heroItem

			break
		end
	end

	return item
end

function HouseDialog:checkGroupValid(id)
	local flag = true
	local groups = self.listTable_:getGroup(id)
	local data = {}

	for _, itemID in ipairs(groups) do
		data[itemID] = (data[itemID] or 0) + 1
	end

	for itemID in pairs(data) do
		local num = data[itemID]
		local items = self:getItemsById(itemID)

		if not items or num > #items then
			flag = false

			break
		end
	end

	return flag
end

function HouseDialog:checkFixedCondition(id)
	local types = self.listTable_:getType(id)
	local values = self.listTable_:getValue(id)
	local flag = true

	for i = 1, #types do
		local type = types[i]

		if xyd.arrayIndexOf(self.fixedConditions, type) > 0 then
			flag = self:checkCondition(id, type, values[i])

			if not flag then
				break
			end
		end
	end

	return flag
end

function HouseDialog:checkConditionByGroup(id, items)
	local types = self.listTable_:getType(id)
	local values = self.listTable_:getValue(id)
	local flag = true

	for i = 1, #types do
		local type = types[i]
		flag = self:checkCondition(id, type, values[i], items)

		if not flag then
			break
		end
	end

	return flag
end

function HouseDialog:checkCondition(id, type, values, items)
	local flag = false

	if type == 1 then
		flag = self:checkCondition1(id, values, items)
	elseif type == 2 then
		flag = self:checkCondition2(id, values, items)
	elseif type == 3 then
		flag = self:checkCondition3(id, values, items)
	elseif type == 4 then
		flag = self:checkCondition4(id, values, items)
	elseif type == 5 then
		flag = self:checkCondition5(id, values, items)
	elseif type == 6 then
		flag = self:checkCondition6(id, values, items)
	elseif type == 7 then
		flag = self:checkCondition7(id, values, items)
	elseif type == 8 then
		flag = self:checkCondition8(id, values, items)
	elseif type == 9 then
		flag = self:checkCondition9(id, values, items)
	elseif type == 10 then
		flag = self:checkCondition10(id, values, items)
	elseif type == 11 then
		flag = self:checkCondition11(id, values, items)
	elseif type == 12 then
		flag = self:checkCondition12(id, values, items)
	elseif type == 13 then
		flag = self:checkCondition13(id, values, items)
	elseif type == 14 then
		flag = self:checkCondition14(id, values, items)
	elseif type == 15 then
		flag = self:checkCondition15(id, values, items)
	end

	return flag
end

function HouseDialog:checkArea(item, list, area)
	if #list == 0 then
		return true
	end

	local info = item:getInfo()
	local flag = false

	for _, tmpItem in ipairs(list) do
		local tmpInfo = tmpItem:getInfo()
		local dx1 = math.abs(tmpInfo.coord_x - info.coord_x) < area[1]
		local dx2 = math.abs(tmpInfo.coord_x + tmpInfo:length() - info.coord_x) < area[1]
		local dx3 = math.abs(tmpInfo.coord_x - info.coord_x - info:length()) < area[1]
		local dy1 = math.abs(tmpInfo.coord_y - info.coord_y) < area[2]
		local dy2 = math.abs(tmpInfo.coord_y + tmpInfo:width() - info.coord_y) < area[2]
		local dy3 = math.abs(tmpInfo.coord_y - info.coord_y - info:width()) < area[2]

		if (dx1 or dx2 or dx3) and (dy1 or dy2 or dy3) then
			flag = true

			break
		end
	end

	return flag
end

function HouseDialog:getValidItemByArea(groups, count, area, list)
	if count == #groups then
		return true
	end

	local selectItems = self:getItemsById(groups[count])

	if #selectItems == 0 then
		return false
	end

	local flag = false

	for i = 1, #selectItems do
		local item = selectItems[i]

		if xyd.arrayIndexOf(list, item) < 0 and self:checkArea(item, list, area) then
			table.insert(list, item)

			if not self:getValidItemByArea(groups, count + 1, area, list) then
				table.remove(list, #list)
			else
				flag = true

				break
			end
		end
	end

	return flag
end

function HouseDialog:checkCondition1(id, values, items)
	local area = MiscTable:split2num("house_dialog_area", "value", "|")
	local flag = true
	local list = {}

	for _, item in ipairs(items) do
		if self:checkArea(item, list, area) then
			table.insert(list, item)
		else
			flag = false

			break
		end
	end

	return flag
end

function HouseDialog:checkCondition2(id, values, items)
	local groups = self.listTable_:getGroup(id)
	local flag = true
	local heros = items
	heros = heros or self.heros_

	for _, heroItem in ipairs(heros) do
		local partnerInfo = heroItem:getPartnerInfo()
		local list = xyd.tables.partnerTable:getHeroList(partnerInfo.tableID)

		for _, itemID in ipairs(groups) do
			if xyd.arrayIndexOf(list, itemID) < 0 then
				flag = false

				break
			end
		end
	end

	return flag
end

function HouseDialog:checkCondition3(id, values, items)
	local flag = true

	for _, itemID in ipairs(values) do
		if self:getHeroItem(itemID) then
			flag = false

			break
		end
	end

	return flag
end

function HouseDialog:getPathKey(item1, item2)
	return tostring(item1.hashCode) .. "|" .. tostring(item2.hashCode)
end

function HouseDialog:checkCondition4(id, values, items)
	local moveItem = items[1]
	local info = moveItem:getInfo()
	local startPs = {
		{
			x = info.coord_x,
			y = info.coord_y
		}
	}

	if moveItem:isInteract() then
		if info and info.parent and info.parent.class and info.parent.class.__cname and info.parent.class.__cname == "HouseItem" and info.parent.itemID_ then
			local interact = xyd.tables.houseFurnitureTable:interact(info.parent.itemID_)

			if interact == xyd.HouseItemInteractType.INTERACT or interact == xyd.HouseItemInteractType.IDLE then
				return false
			end
		end

		local freeGrids = moveItem:checkRoundHasFreeGrid()

		if #freeGrids <= 0 then
			return false
		end

		startPs = freeGrids
	end

	local flag = false

	for ____TS_index = 1, #startPs do
		local startP = startPs[____TS_index]
		local flag2 = true

		for i = 2, #items do
			local tmpInfo = items[i]:getInfo()
			local key = self:getPathKey(moveItem, items[i])

			if not self.minPathList_[key] then
				local endP = {
					x = tmpInfo.coord_x,
					y = tmpInfo.coord_y,
					length = tmpInfo:length(),
					width = tmpInfo:width()
				}
				local result = self:getMinPath(startP, endP)

				if not result then
					flag2 = false

					break
				end

				self.minPathList_[key] = result
			end
		end

		if flag2 then
			flag = true

			break
		end
	end

	return flag
end

function HouseDialog:checkCondition5(id, values, items)
	local num = values[0] or 1
	local count = 0
	local recordFuniture = {}

	for _, item in ipairs(items) do
		local info = item:getInfo()

		if info:isHero() and item:isInteract() then
			local parentItem = info.parent
			recordFuniture[parentItem.hashCode] = (recordFuniture[parentItem.hashCode] or 0) + 1
		end
	end

	local flag = false

	for key in pairs(recordFuniture) do
		if num <= recordFuniture[key] then
			flag = true

			break
		end
	end

	return flag
end

function HouseDialog:checkCondition6(id, values, items)
	local flag = true

	for i = 1, #items do
		local val = values[i]
		local item = items[i]

		if val and val ~= "" then
			local effName = item:getAnimation()

			if effName ~= val then
				flag = false

				break
			end
		end
	end

	return flag
end

function HouseDialog:checkCondition7(id, values, items)
	local flag = true

	for i = 1, #items do
		local item = items[i]

		if values[i] == "1" then
			local effName = item:getAnimation()

			if effName == "sit" then
				flag = false

				break
			end
		end
	end

	return flag
end

function HouseDialog:checkCondition8(id, values, items)
	local flag = true

	for _, itemID in ipairs(values) do
		if self:getFurnitureItem(itemID) then
			flag = false

			break
		end
	end

	return flag
end

function HouseDialog:checkCondition9(id, values, items)
	local flag = true
	local tmpValues = {}

	for _, val in ipairs(values) do
		table.insert(tmpValues, tonumber(val))
	end

	for i = 1, #self.themeList_ do
		local themeId = self.themeList_[i]

		if xyd.arrayIndexOf(tmpValues, themeId) < 0 then
			flag = false

			break
		end
	end

	return flag
end

function HouseDialog:checkCondition10(id, values, items)
	local flag = true
	local groups = self.listTable_:getGroup(id)

	if not items then
		for i = 1, #groups do
			local itemID = groups[i]
			local value = values[i]

			if value and value ~= "" and not self:getHeroItemBySkin(itemID, value) then
				flag = false

				break
			end
		end
	else
		for i = 1, #groups do
			local itemID = groups[i]
			local skinID = values[i]
			local heroItem = items[i]

			if skinID and skinID ~= "" then
				local info = heroItem:getPartnerInfo()

				if info.skin_id ~= tonumber(skinID) then
					flag = false

					break
				end
			end
		end
	end

	return flag
end

function HouseDialog:checkCondition11(id, values, items)
	local flag = true

	for i = 1, #self.itemTypeList_ do
		local itemType = self.itemTypeList_[i]

		if xyd.arrayIndexOf(values, itemType) < 0 then
			flag = false

			break
		end
	end

	return flag
end

function HouseDialog:checkCondition12(id, values, items)
	local flag = true

	for _, themeId in ipairs(values) do
		if xyd.arrayIndexOf(self.themeList_, themeId) < 0 then
			flag = false

			break
		end
	end

	return flag
end

function HouseDialog:checkCondition13(id, values, items)
	local flag = true

	for i = 1, #items do
		local item = items[i]

		if values[i] == "1" then
			local effName = item:getAnimation()

			if effName == "lie" then
				flag = false

				break
			end
		end
	end

	return flag
end

function HouseDialog:checkCondition14(id, values, items)
	local moveItem = items[1]
	local info = moveItem:getInfo()
	local startPs = {
		{
			x = info.coord_x,
			y = info.coord_y
		}
	}

	if moveItem:isInteract() then
		local freeGrids = moveItem:checkRoundHasFreeGrid()

		if #freeGrids <= 0 then
			return false
		end

		startPs = freeGrids
	end

	local flag = false

	for ____TS_index = 1, #startPs do
		local startP = startPs[____TS_index]
		local flag2 = true

		for i = 2, #items do
			local tmpInfo = items[i]:getInfo()
			local key = self:getPathKey(moveItem, items[i])

			if not self.minPathList_[key] then
				local offX = values[1]
				local offY = values[2]

				if tmpInfo.is_flip then
					offX = values[2]
					offY = values[1]
				end

				local endP = {
					length = 1,
					width = 1,
					x = tmpInfo.coord_x + tonumber(offX),
					y = tmpInfo.coord_y + tonumber(offY)
				}
				local result = self:getMinPath(startP, endP)

				if not result then
					flag2 = false

					break
				end

				self.minPathList_[key] = result
			end
		end

		if flag2 then
			flag = true

			break
		end
	end

	return flag
end

function HouseDialog:checkCondition15(id, values, items)
	local type_ = tonumber(values[1])
	local num_ = tonumber(values[2])
	local totalComfort = self.totalComfort_

	if type_ == 1 then
		return num_ < totalComfort
	elseif type_ == 0 then
		return num_ == totalComfort
	else
		return totalComfort < num_
	end
end

function HouseDialog:getMinPath(startP, endP)
	local que = {}
	local dx = {
		1,
		0,
		-1,
		0
	}
	local dy = {
		0,
		1,
		0,
		-1
	}

	table.insert(que, startP)

	local data = {
		[startP.y * self.mapCol + startP.x] = 1
	}
	local map_ = self.map_
	local flag = false
	local finalPoint = nil

	while #que > 0 do
		local p = table.remove(que, 1)

		if endP.x <= p.x and p.x < endP.x + endP.length and endP.y <= p.y and p.y < endP.y + endP.width then
			flag = true
			finalPoint = p

			break
		end

		for i = 1, 4 do
			local nx = p.x + dx[i]
			local ny = p.y + dy[i]
			local index = ny * self.mapCol + nx

			if nx >= 0 and ny >= 0 and nx < self.mapCol and ny < self.mapRow and not map_[index] and not data[index] then
				table.insert(que, {
					x = nx,
					y = ny
				})

				data[index] = data[p.y * self.mapCol + p.x] + 1
			end
		end
	end

	if flag then
		local index = finalPoint.y * self.mapCol + finalPoint.x
		local count = data[index]
		local list = {
			finalPoint
		}

		while count > 0 do
			local p = list[1]

			for i = 1, 4 do
				local nx = p.x + dx[i]
				local ny = p.y + dy[i]
				local index = ny * self.mapCol + nx

				if data[index] == count - 1 then
					table.insert(list, 1, {
						x = nx,
						y = ny
					})

					break
				end
			end

			count = count - 1
		end

		return list
	end

	return nil
end

function HouseDialog:update()
	if #self.curActions_ > 0 then
		self:playCurActions()
		self:checkCurActionsEnd()
	end

	self.nextCleanCd_ = self.nextCleanCd_ - 1

	if self.nextCleanCd_ <= 0 then
		self.nextCleanCd_ = MiscTable:getNumber("house_dialog_cd3", "value") * xyd.FRAME_RATE_30

		self:cleanCD()
	end

	if self.nextJudgeCd_ > 0 then
		self.nextJudgeCd_ = self.nextJudgeCd_ - 1

		return
	end

	self.minPathList_ = {}
	local freeAction = self:getFreeAction()

	if #freeAction <= 0 then
		return
	end

	local successInfos = self:getSuccessInfos(freeAction)

	if #successInfos == 0 then
		self.nextJudgeCd_ = xyd.FRAME_RATE_60

		return
	end

	local rate_ = self:getActionRate()
	local isSuccess = math.random() < rate_

	if xyd.HouseMap.get():isPlayCommonDialog() then
		isSuccess = false
	end

	if isSuccess then
		local index = math.ceil(math.random() * #successInfos)
		local successInfo = successInfos[index]

		self:newAction(successInfo)
		self:clearOldActionCd()
	end

	self:changeRate(isSuccess)

	self.nextJudgeCd_ = MiscTable:getNumber("house_dialog_count_cd", "value") * xyd.FRAME_RATE_60
end

function HouseDialog:playCurActions()
	for i = 1, #self.curActions_ do
		local action = self.curActions_[i]

		action:update()
	end
end

function HouseDialog:checkCurActionsEnd()
	for i = #self.curActions_, 1, -1 do
		local action = self.curActions_[i]

		if action:isEnd() then
			table.remove(self.curActions_, i)
			self:endOneAction(action)
		end
	end
end

function HouseDialog:getActionRate()
	local initRate_ = MiscTable:getNumber("house_dialog_init_count", "value")

	return initRate_ + self.detalRate_
end

function HouseDialog:changeRate(isSuccess)
	local rates = MiscTable:split2num("house_dialog_count", "value", "|")
	self.detalRate_ = self.detalRate_ + xyd.checkCondition(isSuccess, rates[1], rates[2])
end

function HouseDialog:cleanCD()
	self.actionCd_ = {}
	local serverTime = xyd.getServerTime()
	local cd3 = MiscTable:getNumber("house_dialog_cd3", "value")

	for id in pairs(self.actionCd_) do
		if self.actionCd_[id] and cd3 < serverTime - self.actionCd_[id] then
			self.actionCd_[id] = nil
		end
	end
end

function HouseDialog:getFreeAction()
	local actions = self.validActions_
	local data = {}
	local cd_ = MiscTable:getNumber("house_dialog_cd2", "value")
	local curTime = xyd.getServerTime()

	for i = 1, #actions do
		local id = actions[i]

		if not self.actionCd_[id] then
			table.insert(data, id)
		elseif cd_ < curTime - self.actionCd_[id] then
			self.actionCd_[id] = nil

			table.insert(data, id)
		end
	end

	return data
end

function HouseDialog:getSuccessInfos(ids)
	local data = {}

	for _, id in ipairs(ids) do
		local info = self:checkOneAction(id)

		if info then
			table.insert(data, {
				id = id,
				info = info
			})
		end
	end

	return data
end

function HouseDialog:checkItemsIsPlaying(items)
	local flag = false

	for _, item in ipairs(items) do
		if self.playingList_[item.hashCode] or item:getInfo():isHero() and item:canPlayDialog() == false then
			flag = true

			break
		end
	end

	return flag
end

function HouseDialog:checkOneAction(id)
	local meetGroups = self:getGroupListById(id)

	if #meetGroups <= 0 then
		return nil
	end

	local validGroup = nil

	for _, oneGroup in ipairs(meetGroups) do
		if not self:checkItemsIsPlaying(oneGroup) and self:checkConditionByGroup(id, oneGroup) then
			validGroup = oneGroup

			break
		end
	end

	return validGroup
end

function HouseDialog:getPathList(items)
	local list = {}
	local item = items[1]

	for i = 2, #items do
		local key = self:getPathKey(item, items[i])
		list[key] = self.minPathList_[key]
	end

	return list
end

function HouseDialog:newAction(info)
	info.path = self:getPathList(info.info)
	local action = HouseDialogAction.new(info)

	table.insert(self.curActions_, action)

	self.actionCd_[info.id] = xyd.getServerTime()

	for _, item in ipairs(info.info) do
		self.playingList_[item.hashCode] = true

		if item:getInfo():isHero() then
			item:setPlayDialog(true)
		end
	end

	local index = xyd.arrayIndexOf(self.oldAction_, info.id)

	if index > -1 then
		table.remove(self.oldAction_, index)
	end

	table.insert(self.oldAction_, info.id)
end

function HouseDialog:endOneAction(action)
	local items = action:getItems()

	for i = 1, #items do
		local item = items[i]
		self.playingList_[item.hashCode] = false

		if item:getInfo():isHero() then
			item:setPlayDialog(false)
		end
	end
end

function HouseDialog:clearOldActionCd()
	if #self.oldAction_ > 3 then
		local oldID = table.remove(self.oldAction_, 1)
		self.actionCd_[oldID] = nil
	end
end

return HouseDialog
