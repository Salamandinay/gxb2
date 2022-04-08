local BaseModel = import(".BaseModel")
local Background = class("Background", BaseModel)
local cjson = require("cjson")

function Background:ctor()
	BaseModel.ctor(self)

	self.CHOOSE_LIST_KEY = "background_choose_list_key"
	self.struct_data_ = {}
	self.red_list_ = {}
	self.callback_list_ = {}
	self.data_ = {}
end

function Background:isOpen()
	return xyd.checkFunctionOpen(xyd.FunctionID.BACKGROUND, true)
end

function Background:updateData(data)
	if data.background_list then
		self.data_.background_list = {}

		for k, v in ipairs(data.background_list) do
			local params = {
				count = v.count,
				is_complete = v.is_complete,
				is_reward = v.is_reward,
				table_id = v.table_id
			}

			if xyd.tables.customBackgroundTable:getLockType(k) == xyd.BackgroundUnLockType.DEFAULT then
				params.is_complete = 1
			end

			table.insert(self.data_.background_list, params)
		end
	end

	if not data.manager_info then
		return
	end

	if data.manager_info.background then
		if not self.data_.manager_info then
			self.data_.manager_info = {}
		end

		self.data_.manager_info.background = data.manager_info.background
	end

	if data.manager_info.loading_pictures then
		if not self.data_.manager_info then
			self.data_.manager_info = {}
		end

		self.data_.manager_info.loading_pictures = {}

		for k, v in ipairs(data.manager_info.loading_pictures) do
			table.insert(self.data_.manager_info.loading_pictures, v)
		end
	end

	if data.manager_info.loading_pictures_type then
		if not self.data_.manager_info then
			self.data_.manager_info = {}
		end

		self.data_.manager_info.loading_pictures_type = {}

		for k, v in ipairs(data.manager_info.loading_pictures_type) do
			table.insert(self.data_.manager_info.loading_pictures_type, v)
		end
	end
end

function Background:onGetBackgroundInfo(event)
	self:updateData(event.data)
	self:buildDataStructure()
	self:updateLoadingPic()
	self:initRedMark()
end

function Background:initRedMark()
	local ids = xyd.tables.customBackgroundTable:getIds()
	local needRedMark = false

	for i = 1, #ids do
		local id = ids[i]

		if not needRedMark then
			local bgType = xyd.tables.customBackgroundTable:getType(id)

			if self:checkNew(id, bgType) then
				needRedMark = true

				break
			end
		end
	end

	if xyd.models.backpack:getLev() < 30 then
		needRedMark = false
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.BACKGROUND, needRedMark)
end

function Background:onSetBackground(event)
	xyd.db.misc:setValue({
		value = 1,
		key = "is_background_set"
	})

	local tmps = {}

	if self.data_.manager_info.background ~= event.data.manager_info.background then
		self:updateData(event.data)
		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.UPDATE_NEW_BACKGROUND
		})
	else
		self:updateData(event.data)
		self:updateLoadingPic()
	end
end

function Background:updateLoadingPic()
	local tmps = xyd.getRandoms(self.data_.manager_info.loading_pictures, 2)
	xyd.Global.battleLoadingIds = tmps

	self:loadLoadingPics(tmps)
end

function Background:onBuyBackground(event)
	local data = event.data
	local list = self.data_.background_list

	for i = 1, #list do
		if list[i].table_id == data.table_id then
			list[i] = data
			self.struct_data_[tonumber(list[i].table_id)] = {
				count = data.count,
				is_reward = data.is_reward,
				is_complete = data.is_complete
			}
		end
	end
end

function Background:onRedPoint(event)
	if event.data.function_id ~= xyd.FunctionID.BACKGROUND then
		return
	end

	local table_id = event.data.value
	self.red_list_[table_id] = 1
	local list = self.data_.background_list
	local needRedMark = false

	for i = 1, #list do
		if list[i].table_id == table_id then
			list[i].table_id = 1
			self.struct_data_[tonumber(table_id)].is_complete = 1
		end

		if not needRedMark then
			local bgType = xyd.tables.customBackgroundTable:getType(list[i].table_id)

			if self:checkNew(list[i].table_id, bgType) then
				needRedMark = true
			end
		end
	end

	if xyd.models.backpack:getLev() < 30 then
		needRedMark = false
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.BACKGROUND, needRedMark)
end

function Background:onRegister()
	Background.super.onRegister()
	self:registerEvent(xyd.event.GET_BACKGROUND_LIST, handler(self, self.onGetBackgroundInfo))
	self:registerEvent(xyd.event.SET_BACKGROUND, handler(self, self.onSetBackground))
	self:registerEvent(xyd.event.BUY_BACKGROUND, handler(self, self.onBuyBackground))
	self:registerEvent(xyd.event.RED_POINT, handler(self, self.onRedPoint))
end

function Background:reset()
	if Background.INSTANCE then
		Background.INSTANCE:removeEvents()
	end

	Background.INSTANCE = nil
end

function Background:getInfo()
	if not self.data_ then
		local params = {
			manager_info = {
				background = 1,
				loading_pictures = {
					10
				},
				loading_pictures_type = {
					0
				}
			}
		}

		return params
	end

	return self.data_
end

function Background:getBgID()
	local id = self:getInfo().manager_info.background
	id = self:checkInitBackground(id)

	return id
end

function Background:checkInitBackground(id)
	if xyd.isH5() then
		return id
	end

	local hasSet = xyd.db.misc:getValue("is_background_set")

	if not self:isOpen() or not hasSet or hasSet == "" then
		return xyd.tables.miscTable:getNumber("is_unity_background_default", "value")
	end

	return id
end

function Background:checkInUse(id)
	id = tonumber(id)
	local type = xyd.tables.customBackgroundTable:getType(id)

	if type == xyd.BackgroundType.BACKGROUND then
		return tonumber(id) == tonumber(self.data_.manager_info.background)
	else
		return xyd.arrayIndexOf(self.data_.manager_info.loading_pictures, id) ~= -1
	end
end

function Background:reqInfo()
	local msg = messages_pb:get_background_list_req()

	xyd.Backend.get():request(xyd.mid.GET_BACKGROUND_LIST, msg)
end

function Background:buildDataStructure()
	local list = self.data_.background_list

	for i = 1, #list do
		local table_id = list[i].table_id
		self.struct_data_[tonumber(table_id)] = {
			count = list[i].count,
			is_reward = list[i].is_reward,
			is_complete = list[i].is_complete
		}
	end
end

function Background:getItemState(id)
	local d = self.struct_data_[tonumber(id)]

	if not d then
		return 0
	end

	local flag = 0

	if d.is_complete and d.is_complete ~= 0 then
		flag = flag + 1
		local lock_type = xyd.tables.customBackgroundTable:getLockType(id)

		if lock_type == 12 then
			return 2
		end
	end

	if d.is_reward and d.is_reward ~= 0 then
		flag = flag + 1
	end

	return flag
end

function Background:getItemData(id)
	local d = self.struct_data_[id]

	if not d then
		return nil
	end

	return d
end

function Background:addBackgroundCount(id)
	local data = self:getItemData(id)

	if data and data.is_complete == 0 then
		data.count = data.count + 1
		local unlockTimes = tonumber(xyd.tables.customBackgroundTable:getUnclockValue(id))

		if unlockTimes <= data.count then
			data.count = unlockTimes
			data.is_complete = 1
		end

		self.struct_data_[id] = data
	end
end

function Background:getCardState(id, isCollection)
	if isCollection then
		local itemId = xyd.tables.customBackgroundTable:getItemId(id)
		local collectionId = xyd.tables.itemTable:getCollectionId(itemId)

		if xyd.models.collection:isGot(collectionId) then
			return 2
		else
			return 1
		end
	else
		return self:getItemState(id)
	end
end

function Background:checkLock(id)
	local d = self.struct_data_[tonumber(id)]

	if not d then
		return true
	end

	if d.is_complete and d.is_complete ~= 0 then
		return false
	end

	return true
end

function Background:checkOwn(id)
	if self:checkLock(id) then
		return false
	end

	local d = self.struct_data_[tonumber(id)]

	if not d then
		return false
	end

	if d.is_complete and d.is_complete ~= 0 then
		local lock_type = xyd.tables.customBackgroundTable:getLockType(id)

		if lock_type == 12 then
			return true
		end
	end

	if d.is_reward and d.is_reward ~= 0 then
		return true
	end

	return false
end

function Background:resetNew(id, type)
	local choose_list = xyd.db.misc:getValue(tostring(self.CHOOSE_LIST_KEY) .. tostring(type))
	local list = nil

	if not choose_list then
		list = {}
	else
		list = cjson.decode(choose_list)
	end

	table.insert(list, id)
	xyd.db.misc:setValue({
		key = tostring(self.CHOOSE_LIST_KEY) .. tostring(type),
		value = cjson.encode(list)
	})
end

function Background:checkNew(id, type)
	if not self:checkNewInTable(id, type) then
		return false
	end

	local choose_list = xyd.db.misc:getValue(tostring(self.CHOOSE_LIST_KEY) .. tostring(type))

	if not choose_list then
		return true
	end

	local list = cjson.decode(choose_list)

	if xyd.arrayIndexOf(list, tonumber(id)) == -1 then
		return true
	else
		return false
	end
end

function Background:checkNewInTable(id, type)
	local endTime = xyd.tables.customBackgroundTable:getRedMarkTime(id)
	local nowTime = xyd.getServerTime()

	if nowTime < endTime then
		return true
	else
		return false
	end
end

function Background:checkRedIcon(id)
	if self.red_list_[tonumber(id)] then
		return true
	end

	return false
end

function Background:resetRed(id)
	self.red_list_[tonumber(id)] = nil
end

function Background:redList()
	local keys = {}

	for k, v in pairs(self.red_list_) do
		table.insert(keys, k)
	end

	return keys
end

function Background:reqAddSelect(id, type)
	if type == nil then
		type = 0
	end

	local options = {}
	local options_type = {}
	local loading_pictures = self.data_.manager_info.loading_pictures
	local loading_pictures_type = self.data_.manager_info.loading_pictures_type

	for item in pairs(loading_pictures) do
		table.insert(options, tonumber(loading_pictures[item]))
		table.insert(options_type, tonumber(loading_pictures_type[item]))
	end

	local ind = xyd.arrayIndexOf(loading_pictures, id)

	if ind == -1 then
		table.insert(options, id)
		table.insert(options_type, type)
	else
		if #loading_pictures == 1 then
			xyd.showToast(__("BACKGROUND_REMOVE_ALL"))

			return
		end

		table.remove(options, ind)
		table.remove(options_type, ind)
	end

	local msg = messages_pb:set_background_req()
	msg.background = self.data_.manager_info.background
	local loading_pictures = msg.loading_pictures
	local loading_pictures_type = msg.loading_pictures_type

	for i = 1, #options do
		table.insert(loading_pictures, options[i])
		table.insert(loading_pictures_type, options_type[i])
	end

	xyd.Backend.get():request(xyd.mid.SET_BACKGROUND, msg)
end

function Background:reqChooseBg(id)
	if id == self.data_.manager_info.background then
		return
	end

	local msg = messages_pb:set_background_req()
	msg.background = tonumber(id)
	local loading_pictures = msg.loading_pictures
	local loading_pictures_type = msg.loading_pictures_type

	for i = 1, #self.data_.manager_info.loading_pictures do
		table.insert(loading_pictures, self.data_.manager_info.loading_pictures[i])
		table.insert(loading_pictures_type, self.data_.manager_info.loading_pictures_type[i])
	end

	xyd.Backend.get():request(xyd.mid.SET_BACKGROUND, msg)
end

function Background:getNext(id, delta)
	return self:getNextWithGroup(id, delta)
end

function Background:getNextWithGroup(id, delta)
	local delta = delta or 1
	local CustomBackgroundTable = xyd.tables.customBackgroundTable
	local type = CustomBackgroundTable:getType(id)
	local group_id = CustomBackgroundTable:getGroup(id)
	local group_list = CustomBackgroundTable:getListByGroup(type, group_id)
	local ind = xyd.arrayIndexOf(group_list, id)
	local re_index = ind + delta

	if re_index > #group_list then
		local group_num = #xyd.tables.customBackgroundGroupTable:getIDs()

		while group_id <= group_num do
			group_id = group_id + 1
			group_list = CustomBackgroundTable:getListByGroup(type, group_id)

			if group_list and #group_list > 0 then
				return group_list[1]
			end
		end
	elseif re_index < 1 then
		while group_id > 0 do
			group_id = group_id - 1
			group_list = CustomBackgroundTable:getListByGroup(type, group_id)

			if group_list and #group_list > 0 then
				return group_list[#group_list + re_index]
			end
		end
	else
		return group_list[re_index]
	end

	return nil
end

function Background:getNextWithId(id, delta)
	local type = xyd.tables.customBackgroundTable:getType(id)
	id = tonumber(id)
	local ind = nil
	local list = {}

	local function sort_func(a, b)
		return tonumber(a) < tonumber(b)
	end

	if type == xyd.BackgroundType.BACKGROUND then
		type = 0
	end

	if type == 0 then
		list = xyd.tables.customBackgroundTable:getListByGroup(type)
	else
		list = xyd.tables.customBackgroundTable:getGalleryList()
	end

	table.sort(list, sort_func)

	ind = xyd.arrayIndexOf(list, tostring(id))

	if delta < 0 then
		if ind <= 0 then
			return nil
		end

		return list[ind - 1]
	elseif delta > 0 then
		if ind >= #list then
			return nil
		end

		return list[ind + 1]
	end
end

function Background:reqBuyBackground(id)
	local msg = messages_pb:buy_background_req()
	msg.table_id = tonumber(id)

	xyd.Backend.get():request(xyd.mid.BUY_BACKGROUND, msg)
end

function Background:loadLoadingPics(ids)
	local urls = {}

	for i = 1, #ids do
		local id = ids[i]
		local paths = self:getResByTableId(id)

		if #paths > 0 then
			for _, path in ipairs(paths) do
				if not xyd.isResLoad(path) then
					table.insert(urls, path)
				end
			end
		end
	end

	if #urls > 0 then
		ResCache.DownloadAssets("loading_battle_pic" .. xyd.getTimeKey(), urls, nil, , 0.1)
	end
end

function Background:isIdResLoad(id)
	local flag = true
	local paths = self:getResByTableId(id)

	if #paths > 0 then
		for _, path in ipairs(paths) do
			if not xyd.isResLoad(path) then
				flag = false

				break
			end
		end
	end

	return flag
end

function Background:getResByTableId(id)
	local type = xyd.tables.customBackgroundTable:getType(id)
	local res = {}

	if type == 1 then
		local path = xyd.getTexturePath(xyd.tables.customBackgroundTable:getPicture(id))

		table.insert(res, path)
	else
		local is_effect = self:getIsEffectType(id) or 0

		if is_effect == 0 then
			local path = xyd.getTexturePath(xyd.tables.customBackgroundTable:getPicture(id))

			table.insert(res, path)
		else
			local effect_bg = xyd.getTexturePath(xyd.tables.customBackgroundTable:getEffectBackground(id))

			table.insert(res, effect_bg)

			local effect_res = xyd.getEffectFilesByNames({
				xyd.tables.customBackgroundTable:getEffect(id)
			})
			res = xyd.arrayMerge(res, effect_res)
		end
	end

	return res
end

function Background:getIsEffectType(id)
	if not self.data_ or not self.data_.manager_info or not self.data_.manager_info.loading_pictures or not self.data_.manager_info.loading_pictures_type then
		return 0
	end

	for i = 1, #self.data_.manager_info.loading_pictures do
		local table_id = self.data_.manager_info.loading_pictures[i]

		if table_id == id then
			return self.data_.manager_info.loading_pictures_type[i]
		end
	end

	return 0
end

function Background:getLoadingPicNum()
	local canUse = xyd.Global.battleLoadingIds
	local selectBgs = xyd.getRandoms(canUse, 1)
	local num = selectBgs[1]
	local isLoad = self:isIdResLoad(num)

	if isLoad then
		return num
	end

	return 5
end

function Background:updateLoadingPicNum()
	if not self.data_ or not self.data_.manager_info then
		return
	end

	local list = self.data_.manager_info.loading_pictures or {}

	if #list <= 2 then
		return
	end

	local index = math.random(1, #list)
	local newNum = list[index]

	if xyd.arrayIndexOf(xyd.Global.battleLoadingIds, newNum) > 0 then
		return
	end

	local isLoad = self:isIdResLoad(newNum)

	if not isLoad then
		self:loadLoadingPics({
			newNum
		})
	end

	table.remove(xyd.Global.battleLoadingIds, 1)
	table.insert(xyd.Global.battleLoadingIds, newNum)
end

return Background
