local House = class("House", import("app.models.BaseModel"))
local HouseFurnitureGroupTable = xyd.tables.houseFurnitureGroupTable
local Slot = xyd.models.slot
local Backpack = xyd.models.backpack
local MiscTable = xyd.tables.miscTable
local ItemTable = xyd.tables.itemTable
local HouseAwardTable = xyd.tables.houseAwardTable
local JSON = require("cjson")

function House:ctor()
	House.super.ctor(self)

	self.buyItemInfo_ = nil
	self.comfortNum_ = -1
	self.redPoint_ = false
	self.recommendData_ = nil
	self.likeRecords_ = nil
	self.otherPlayerDormInfos = {}
	self.dormPartnerIds_ = {}
	self.furnitureInfos_ = {}
	self.dormSet_ = {}
	self.hangItems_ = {}
	self.totalFloorNum_ = 1
	self.hangRed = false
	self.shopRed = false
	self.houseCombineId = {}
	self.senpaiFloor = 0
end

function House:onRegister()
	House.super.onRegister(self)
	self:registerEvent(xyd.event.HOUSE_GET_INFO, handler(self, self.onGetInfo))
	self:registerEvent(xyd.event.HOUSE_SAVE_INFO, handler(self, self.onSaveInfo))
	self:registerEvent(xyd.event.HOUSE_GET_AWARDS, handler(self, self.onGetAwards))
	self:registerEvent(xyd.event.HOUSE_ADD_COMBINE, handler(self, self.onAddCombine))
	self:registerEvent(xyd.event.HOUSE_DEL_COMBINE, handler(self, self.onDelCombine))
	self:registerEvent(xyd.event.HOUSE_SET_PARTNER, handler(self, self.onSetPartner))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
	self:registerEvent(xyd.event.HOUSE_EDIT_NAME, handler(self, self.onEditName))
	self:registerEvent(xyd.event.HOUSE_GET_RECOMMEND_DORMS, handler(self, self.onGetRecommendDorms))
	self:registerEvent(xyd.event.HOUSE_LIKE_DORM, handler(self, self.onLikeDorm))
	self:registerEvent(xyd.event.HOUSE_GET_LIKE_RECORDS, handler(self, self.onLikeRecords))
	self:registerEvent(xyd.event.HOUSE_GET_OTHER_DORM_INFO, handler(self, self.onGetOtherDormInfo))
	self:registerEvent(xyd.event.FRIEND_ACCEPT, handler(self, self.clearRecommend))
	self:registerEvent(xyd.event.HOUSE_OPEN_DORM_FLOOR, handler(self, self.onOpenDormFloor))
end

function House:reqHouseInfo()
	if self.data_ then
		return false
	end

	local msg = messages_pb.house_get_info_req()

	xyd.Backend.get():request(xyd.mid.HOUSE_GET_INFO, msg)

	return true
end

function House:reqSaveHouseInfo(data)
	xyd.Backend.get():request(xyd.mid.HOUSE_SAVE_INFO, data)
end

function House:onGetInfo(event)
	local list = {}

	for i = 1, #event.data.dorm_partner_ids do
		local partnerid = event.data.dorm_partner_ids[i]
		local partner = Slot:getPartner(partnerid)

		if partner then
			table.insert(list, partnerid)
		else
			table.insert(list, 0)
		end
	end

	self:updateFurnitureInfo(event.data.furniture_infos, 1)

	local oldHeroIDs = self:getHeroIDs()
	self.data_ = event.data
	self.dormPartnerIds_ = list
	self.dormSet_ = event.data.dorm_set
	self.hangItems_ = event.data.hang_items
	self.totalFloorNum_ = event.data.floor_num or 1

	if tostring(event.data.ex_floor_infos) ~= "" then
		for i = 2, self.totalFloorNum_ do
			self:updateFurnitureInfo(event.data.ex_floor_infos[i].furniture_infos, i)
		end
	end

	self:updateLock(oldHeroIDs)
	self:updateComfortNum()

	if self:isHangMaxTime() then
		self:setHangRedPoint(true)
	end

	self.shopRed = self:checkHasShopRed()

	self:updateRedPoint()

	self.senpaiFloor = event.data.use_senpai

	self:setSenpaiRed()
	self:setNewFloorRed()
end

function House:setSenpaiRed()
	local flag = self.senpaiFloor == 0 and not xyd.db.misc:getValue("senpai_first_in_house")

	xyd.models.redMark:setMark(xyd.RedMarkType.SENPAI_FIRST_IN_HOUSE, flag)
end

function House:setNewFloorRed()
	local flag = self:getOpenDormNum() >= 2 and not xyd.db.misc:getValue("house_new_floor_2")

	xyd.models.redMark:setMark(xyd.RedMarkType.HOUSE_NEW_FLOOR_2, flag)
end

function House:setHangRedPoint(flag)
	self.hangRed = flag

	self:updateRedPoint()
end

function House:setShopRedPoint(id)
	local dbData = xyd.db.misc:getValue("house_shop_red_group")
	local groups = dbData ~= nil and JSON.decode(dbData) or {}

	for i = 1, #groups do
		if id == groups[i] then
			return
		end
	end

	table.insert(groups, id)
	xyd.db.misc:setValue({
		key = "house_shop_red_group",
		value = JSON.encode(groups)
	})

	self.shopRed = self:checkHasShopRed()

	self:updateRedPoint()
end

function House:checkHasShopRed()
	local dbData = xyd.db.misc:getValue("house_shop_red_group")
	local groups = dbData ~= nil and JSON.decode(dbData) or {}
	local hasRed = false
	local ids = HouseFurnitureGroupTable:getIDs()

	for id = 1, #ids do
		local time = HouseFurnitureGroupTable:getNewTime(ids[id])

		if time and xyd.getServerTime() < time then
			hasRed = true

			for dataId = 1, #groups do
				if groups[dataId] == ids[id] then
					hasRed = false

					break
				end
			end
		end

		if hasRed then
			break
		end
	end

	return hasRed
end

function House:isHangMaxTime()
	local hangTime = self:getHangTime()
	local hangUpdateTime = self:getHangUpdateTime() or hangTime
	local maxHangTime = MiscTable:getNumber("hang_up_time_max", "value")
	local flag = false

	if hangTime > 0 then
		local serverTime = xyd.getServerTime()
		local trueMaxHangTime = hangTime + maxHangTime

		if serverTime > trueMaxHangTime then
			flag = true
		end
	end

	return flag
end

function House:getHangRedPoint()
	return self.hangRed
end

function House:getShopRedPoint()
	return self.shopRed
end

function House:getRedPoint()
	return self.hangRed
end

function House:updateRedPoint()
	xyd.models.redMark:setMark(xyd.RedMarkType.HOUSE, self.hangRed)
	xyd.models.redMark:setMark(xyd.RedMarkType.HOUSE_SHOP, self.shopRed)
end

function House:getFurnitureItem(info)
	local item = {
		table_id = info.table_id,
		x = info.x,
		y = info.y,
		flip = info.flip,
		children = {}
	}

	if #info.children then
		for i = 1, #info.children do
			local childItem = self:getFurnitureItem(info.children[i])

			table.insert(item.children, childItem)
		end
	end

	return item
end

function House:updateFurnitureInfo(infos, floor)
	local arry = {}

	for i = 1, #infos do
		local info = infos[i]
		local item = self:getFurnitureItem(info)

		table.insert(arry, item)
	end

	self.furnitureInfos_[floor] = arry
end

function House:updateLock(oldHeroIDs)
	local partners = Slot:getPartners()

	for i = 1, #oldHeroIDs do
		local partnerID = oldHeroIDs[i]

		if partners[partnerID] then
			partners[partnerID]:setLock(0, xyd.PartnerFlag.HOUSE)
		end
	end

	local curHeroIDs = self:getHeroIDs()

	for i = 1, #curHeroIDs do
		local partnerID = curHeroIDs[i]

		if partners[partnerID] then
			partners[partnerID]:setLock(1, xyd.PartnerFlag.HOUSE)
		end
	end
end

function House:onSaveInfo(event)
	self:updateFurnitureInfo(event.data.furniture_infos, 1)

	if tostring(event.data.ex_floor_infos) ~= "" then
		for i = 2, self.totalFloorNum_ do
			self:updateFurnitureInfo(event.data.ex_floor_infos[i].furniture_infos, i)
		end
	end
end

function House:reqSaveHeros(partners, senpaiFloor)
	local num = self:getOpenDormNum() * 5
	local msg = messages_pb.house_set_partner_req()

	for i = 1, num do
		table.insert(msg.partner_ids, partners[i])
	end

	msg.use_senpai = senpaiFloor or 0

	xyd.Backend.get():request(xyd.mid.HOUSE_SET_PARTNER, msg)
end

function House:getFurnitures(floor)
	return self.furnitureInfos_[floor] or {}
end

function House:getCombines()
	local info = {}

	if self.data_ then
		info = self.dormSet_ or {}
	end

	return info
end

function House:reqGetAwards()
	local msg = messages_pb.house_get_awards_req()

	xyd.Backend.get():request(xyd.mid.HOUSE_GET_AWARDS, msg)
end

function House:onGetAwards(event)
	local time = event.data.time

	if self.data_ then
		self.data_.hang_time = time
		self.data_.hang_update_time = time
		self.hangItems_ = {}
	end
end

function House:getAwards()
	local info = {}

	if self.data_ then
		info = self.hangItems_ or {}
	end

	return info
end

function House:getAwardItem(itemID)
	local items = self:getAwards()

	for i = 1, #items do
		local item = items[i]

		if item.item_id == itemID then
			return item
		end
	end

	return nil
end

function House:getHangTime()
	if self.data_ then
		return self.data_.hang_time or 0
	end

	return 0
end

function House:getHangUpdateTime()
	if self.data_ then
		return self.data_.hang_update_time or 0
	end

	return 0
end

function House:reqAddCombine(msg, name, id, uploadImg)
	msg.name = name

	if id then
		msg.id = id

		if uploadImg then
			table.insert(self.houseCombineId, 1, {
				id,
				uploadImg
			})
		end
	end

	xyd.Backend.get():request(xyd.mid.HOUSE_ADD_COMBINE, msg)
end

function House:onAddCombine(event)
	self.dormSet_ = event.data.dorm_set
	local combineItem = table.remove(self.houseCombineId, 1)

	if combineItem then
		local combineId = combineItem[1]
		local uploadImg = combineItem[2]
		local bytes = XYDUtils.EncodeToPNG(uploadImg)
		local uploadNames = {
			"house_combine_img_" .. xyd.Global.playerID .. "_" .. combineId
		}
		local uploadBytes = {
			bytes
		}

		NGUITools.Save(xyd.HOUSE_IMG_SAVE_PATH .. uploadNames[1], uploadBytes[1])
		xyd.WebPictureManager.get():addDataByUrl(xyd.downloadGMImgURL() .. uploadNames[1], xyd.HOUSE_IMG_SAVE_PATH .. uploadNames[1])
		self:setHouseCombineUrlIds(combineId, true)

		local wnd = xyd.WindowManager.get():getWindow("house_combine_window")

		if wnd then
			wnd:updateItemList(true)
		end

		xyd.uploadBinaryData(xyd.uploadGMImgURL(), uploadNames, uploadBytes, function (success)
			if not success then
				xyd.alert(xyd.AlertType.TIPS, __("UPLOAD_FAIL"))
			end
		end)
	end
end

function House:getHouseCombineImgName(id)
	return "house_combine_img_" .. xyd.Global.playerID .. "_" .. id
end

function House:getHouseCombineImgUrl(id)
	if self:checkApkCanGetShot() then
		local ids = self:getHouseCombineUrlIds()

		if ids and xyd.arrayIndexOf(ids, id) > 0 then
			return xyd.downloadGMImgURL() .. self:getHouseCombineImgName(id)
		end
	end

	return nil
end

function House:getHouseCombineUrlIds()
	local ids = xyd.db.misc:getValue("house_combine_img_url_ids")

	if ids then
		return JSON.decode(ids)
	else
		return nil
	end
end

function House:setHouseCombineUrlIds(id, flag)
	local ids = self:getHouseCombineUrlIds() or {}

	if flag then
		table.insert(ids, id)
	else
		local index = xyd.arrayIndexOf(ids, id)

		if index > 0 then
			table.remove(ids, index)
		end
	end

	xyd.db.misc:setValue({
		key = "house_combine_img_url_ids",
		value = JSON.encode(ids)
	})
end

function House:reqDelCombine(id)
	local msg = messages_pb.house_del_combine_req()
	msg.id = id

	xyd.Backend.get():request(xyd.mid.HOUSE_DEL_COMBINE, msg)

	self.deleteCombineId = id
end

function House:onDelCombine(event)
	self.dormSet_ = event.data.dorm_set

	if self.deleteCombineId then
		self:setHouseCombineUrlIds(self.deleteCombineId, false)

		self.deleteCombineId = nil
	end
end

function House:onSetPartner(event)
	local oldHeroIDs = self:getHeroIDs()
	local partnerIDs = event.data.dorm_partner_ids
	self.dormPartnerIds_ = partnerIDs
	self.senpaiFloor = event.data.use_senpai

	self:updateLock(oldHeroIDs)
	self:setSenpaiRed()

	local wnd = xyd.WindowManager.get():getWindow("house_window")

	if wnd then
		local floor = wnd:getCurFloor()

		xyd.HouseMap.get():setHerosInfo(self:getHeroInfos(floor))
		xyd.HouseMap.get():hideHeros()
		xyd.HouseMap.get():updateHeros(2)
	end
end

function House:getHeroIDs()
	if not self.data_ then
		return {}
	end

	return self.dormPartnerIds_ or {}
end

function House:getHeroInfos(floor)
	local ids = self:getHeroIDs()
	local info = {}
	local start = 1
	local end_ = #ids

	if floor then
		start = (floor - 1) * 5 + 1
		end_ = floor * 5
	end

	for i = start, end_ do
		local id = ids[i]

		if id and id > 0 then
			local partner = Slot:getPartner(id)

			if partner then
				local partnerInfo = partner:getInfo()
				partnerInfo.table_id = partnerInfo.tableID

				table.insert(info, partnerInfo)
			end
		end
	end

	return info
end

function House:saveBuyItemInfo(buyInfo)
	self.buyItemInfo_ = buyInfo
end

function House:getBuyItemInfo()
	return self.buyItemInfo_
end

function House:getComfortNum()
	return self.comfortNum_
end

function House:sortComfortItems(items)
	table.sort(items, function (a, b)
		if a.comfort ~= b.comfort then
			return b.comfort < a.comfort
		end

		return false
	end)
end

function House:updateComfortNum()
	local houseTable = xyd.tables.houseFurnitureTable
	local ids = houseTable:getIDs()
	local items = {}
	local countMax = MiscTable:split2num("dorm_comfort_top_num_by_type", "value", "|")

	for _, id in ipairs(ids) do
		local itemNum = Backpack:getItemNumByID(id)

		if itemNum > 0 then
			local type = houseTable:type(id)

			if not items[type] then
				items[type] = {}
			end

			table.insert(items[type], {
				id = id,
				num = itemNum,
				comfort = houseTable:comfort(id)
			})
		end
	end

	local totalComfortNum_ = 0

	for type = 1, #countMax do
		local tmpArry = items[type]

		if tmpArry then
			self:sortComfortItems(tmpArry)

			local leftLimit = countMax[type]

			for _, item in ipairs(tmpArry) do
				local num = math.min(item.num, leftLimit)
				leftLimit = leftLimit - num
				totalComfortNum_ = totalComfortNum_ + item.comfort * num

				if leftLimit <= 0 then
					break
				end
			end
		end
	end

	self.comfortNum_ = totalComfortNum_

	if self:getOpenDormNum() == 1 and self:checkCanOpenFloor() then
		self:reqOpenDormFloor(2)
	end
end

function House:onItemChange(event)
	local items = event.data.items
	local flag = false

	for i = 1, #items do
		local item = items[i]
		local item_id = item.item_id
		local type = ItemTable:getType(item_id)

		if type == xyd.ItemType.HOUSE_FURNITURE then
			flag = true

			break
		end
	end

	if flag then
		self:updateAwards()
		self:updateComfortNum()
	end
end

function House:updateAwards()
	local comfortNum = self:getComfortNum()

	if comfortNum <= 0 then
		return
	end

	local id = HouseAwardTable:getIdByComfort(comfortNum)
	local pAwardItems = HouseAwardTable:award(id)
	local hangTime = self:getHangTime()
	local hangUpdateTime = self:getHangUpdateTime() or hangTime
	local addRate = 0
	local maxHangTime = MiscTable:getNumber("hang_up_time_max", "value")

	if hangTime > 0 then
		local serverTime = xyd.getServerTime()
		local trueMaxHangTime = hangTime + maxHangTime

		if serverTime < trueMaxHangTime then
			trueMaxHangTime = serverTime
		end

		local trueHangTime = trueMaxHangTime - hangUpdateTime

		if maxHangTime < trueHangTime then
			trueHangTime = maxHangTime
		elseif trueHangTime < 0 then
			trueHangTime = 0
		end

		addRate = math.floor(trueHangTime / xyd.HANG_AWARD_TIME)

		if addRate > 0 then
			addRate = addRate - 1
		end
	end

	for i = 1, #pAwardItems do
		local item = pAwardItems[i]
		local recordItem = self:getAwardItem(item[1])
		local recordNum = 0
		local awardNum = item[2] * addRate

		if recordItem then
			recordItem.item_num = tonumber(recordItem.item_num) + awardNum
		end
	end

	if self.data_ then
		self.data_.hang_update_time = xyd.getServerTime()
	end
end

function House:getHouseName()
	local dormName = ""

	if self.data_ then
		dormName = self.data_.dorm_name or ""
	end

	if dormName == "" then
		dormName = __("HOUSE_TEXT_50")
	end

	return dormName
end

function House:reqSaveHouseName(nameStr)
	if nameStr == self:getHouseName() then
		return
	end

	local msg = messages_pb.house_edit_name_req()
	msg.name = nameStr

	xyd.Backend.get():request(xyd.mid.HOUSE_EDIT_NAME, msg)
end

function House:onEditName(event)
	if self.data_ then
		self.data_.dorm_name = event.data.name
	end
end

function House:reqGetRecommendDorms()
	if self.recommendData_ then
		return
	end

	local msg = messages_pb.house_get_recommend_dorms_req()

	xyd.Backend.get():request(xyd.mid.HOUSE_GET_RECOMMEND_DORMS, msg)
end

function House:onGetRecommendDorms(event)
	self.recommendData_ = event.data
end

function House:clearRecommend()
	self.recommendData_ = nil
end

function House:getRecommendDorms()
	return self.recommendData_
end

function House:reqLikeDorm(otherPlayerID)
	local msg = messages_pb.house_like_dorm_req()
	msg.other_player_id = otherPlayerID

	xyd.Backend.get():request(xyd.mid.HOUSE_LIKE_DORM, msg)
end

function House:onLikeDorm(event)
	local list = self.data_.self_like_records or {}

	if self.data_ and self.data_.self_like_records then
		table.insert(self.data_.self_like_records, event.data.other_player_id)
	end

	self:clearRecommend()
end

function House:reqLikeRecords()
	if self.likeRecords_ then
		return
	end

	local msg = messages_pb.house_get_like_records_req()

	xyd.Backend.get():request(xyd.mid.HOUSE_GET_LIKE_RECORDS, msg)
end

function House:onLikeRecords(event)
	self.likeRecords_ = event.data
end

function House:getLikeRecords()
	return self.likeRecords_
end

function House:reqOtherDormInfo(otherPlayerID)
	if self.otherPlayerDormInfos[otherPlayerID] then
		return
	end

	local msg = messages_pb.house_get_other_dorm_info_req()
	msg.other_player_id = otherPlayerID

	xyd.Backend.get():request(xyd.mid.HOUSE_GET_OTHER_DORM_INFO, msg)
end

function House:onGetOtherDormInfo(event)
	self.otherPlayerDormInfos[event.data.player_id] = xyd.decodeProtoBuf(event.data)
end

function House:getOtherDormInfo(otherPlayerID)
	return self.otherPlayerDormInfos[otherPlayerID]
end

function House:getSelfPraiseNum()
	if self.data_ then
		return self.data_.like_num or 0
	end

	return 0
end

function House:isHasPraise(otherPlayerID)
	if self.data_ then
		local list = self.data_.self_like_records or {}

		return xyd.arrayIndexOf(list, otherPlayerID) > -1
	end

	return false
end

function House:checkCanShare()
	local lastTime = xyd.db.misc:getValue("house_share_time_key")

	if lastTime then
		local day = math.floor(tonumber(lastTime) / 86400)
		local curDay = math.floor(xyd.getServerTime() / 86400)

		if curDay == day then
			return false
		end
	end

	return true
end

function House:setShareTimeKey()
	local lastTime = xyd.db.misc:setValue({
		key = "house_share_time_key",
		value = xyd.getServerTime()
	})
end

function House:checkApkCanShare()
	if UNITY_ANDROID and XYDUtils.CompVersion(UnityEngine.Application.version, xyd.ANDROID_1_1_91) <= 0 then
		return false
	elseif UNITY_IOS and XYDUtils.CompVersion(UnityEngine.Application.version, xyd.IOS_1_1_21) <= 0 then
		return false
	end

	return true
end

function House:checkApkCanGetShot()
	return self:checkApkCanShare()
end

function House:onOpenDormFloor(event)
	self.totalFloorNum_ = event.data.floor

	self:setNewFloorRed()
	self:updateFurnitureInfo(event.data.furniture_infos, event.data.floor)
end

function House:reqOpenDormFloor(floor)
	local msg = messages_pb.house_open_dorm_floor_req()
	msg.floor = floor

	xyd.Backend.get():request(xyd.mid.HOUSE_OPEN_DORM_FLOOR, msg)
end

function House:getOpenDormNum()
	return self.totalFloorNum_ or 1
end

function House:getChildFurnitureNum(items, data)
	if items then
		for j = 1, #items do
			local item = items[j]
			data[item.table_id] = (data[item.table_id] or 0) + 1

			self:getChildFurnitureNum(item.children, data)
		end
	end
end

function House:getOtherFurnitureNum(ExFloor)
	local params = {}

	for i = 1, self.totalFloorNum_ do
		if self.furnitureInfos_[i] and i ~= ExFloor then
			self:getChildFurnitureNum(self.furnitureInfos_[i], params)
		end
	end

	return params
end

function House:checkFurnitureNum(infos, floor)
	local otherNums = self:getOtherFurnitureNum(floor)
	local curNums = {}

	self:getChildFurnitureNum(infos, curNums)

	local flag = true
	local backpack = xyd.models.backpack

	for id, num in pairs(curNums) do
		local totalNum = backpack:getItemNumByID(id)
		local useNum = (otherNums[id] or 0) + num

		if totalNum < useNum then
			flag = false

			break
		end
	end

	return flag
end

function House:checkCanOpenFloor()
	local values = MiscTable:split2num("up_dorm_limit", "value", "|")
	local nextFloor = self:getOpenDormNum() + 1
	local comfortNum = self:getComfortNum()

	if not values[nextFloor] or values[nextFloor] <= comfortNum then
		return true
	end

	return false
end

function House:getOpenComfortNum()
	local values = MiscTable:split2num("up_dorm_limit", "value", "|")
	local nextFloor = self:getOpenDormNum() + 1

	return values[nextFloor]
end

function House:getSenpaiFloor()
	return self.senpaiFloor
end

return House
