local Dress = class("Dress", import(".BaseModel"))
local JSON = require("cjson")

function Dress:ctor()
	Dress.super.ctor(self)

	self.dress_id_style_arr = {}
	self.group_items = {}
	self.dress_id_pos_arr = {
		[0] = {},
		{},
		{},
		{},
		{},
		{}
	}
	self.all_has_dress_id = {}
	self.local_sava_chose_style_by_dress_id = {}
	self.dress_items = {
		[0] = {},
		{},
		{},
		{},
		{},
		{}
	}
	self.dress_get_items = {
		[0] = {},
		{},
		{},
		{},
		{},
		{}
	}
	self.dress_item_fragment_arr = {}

	for i = 0, 6 do
		if not self.dress_item_fragment_arr[i] then
			self.dress_item_fragment_arr[i] = {}
		end
	end

	self.buff_type_attr = {}

	self:initBuffTypeAttr()

	self.tipsFifhgtMid = {
		xyd.mid.QUIZ_FIGHT,
		xyd.mid.NEW_TRIAL_FIGHT,
		xyd.mid.FRIEND_BOSS_FIGHT
	}
end

function Dress:initBuffTypeAttr()
	for i in pairs(xyd.DressBuffAttrType) do
		self.buff_type_attr[xyd.DressBuffAttrType[i]] = 0
	end
end

function Dress:isfunctionOpen()
	if UNITY_EDITOR then
		return true
	else
		return true
	end
end

function Dress:isNewClipShaderOpen()
	if UNITY_ANDROID and XYDUtils.CompVersion(UnityEngine.Application.version, xyd.ANDROID_1_5_49) <= 0 or UNITY_IOS and XYDUtils.CompVersion(UnityEngine.Application.version, xyd.IOS_71_3_110) <= 0 then
		return false
	else
		return true
	end
end

function Dress:onRegister()
	Dress.super.onRegister(self)
	self:registerEvent(xyd.event.GET_DRESS_INFO, handler(self, self.onGetData))
	self:registerEvent(xyd.event.DRESS_EQUIP_STYLES, handler(self, self.equipBack))
	self:registerEvent(xyd.event.DRESS_SUIT_SAVE, handler(self, self.dressSuitSave))
	self:registerEvent(xyd.event.DRESS_SUIT_REMOVE, handler(self, self.dressSuitRemove))
	self:registerEvent(xyd.event.DRESS_UPGRADE_DRESS, handler(self, self.dressUpgradeDressBack))
	self:registerEvent(xyd.event.DRESS_UNLOCK_STYLE, handler(self, self.dressUnlockStyleBack))
	self:registerEvent(xyd.event.SERVER_BROADCAST, self.onServerBroadMessageBack, self)
	self:registerEvent(xyd.event.DRESS_SPECIAL_BUFF_BACK, self.dressSpecialBuffBack, self)
end

function Dress:initItems(itemID, itemNum)
	if not self.dress_items[0][itemID] then
		local dress_id = xyd.tables.senpaiDressItemTable:getDressId(itemID)
		local pos_id = xyd.tables.senpaiDressTable:getPos(dress_id)
		self.dress_items[0][itemID] = {
			itemID = itemID,
			itemNum = itemNum
		}
		self.dress_items[pos_id][itemID] = {
			itemID = itemID,
			itemNum = itemNum
		}

		table.insert(self.dress_get_items[0], self.dress_items[0][itemID])
		table.insert(self.dress_get_items[pos_id], self.dress_items[pos_id][itemID])
		self:updateGroupItems(itemID, dress_id)
	end
end

function Dress:initItemsSort()
	for i = 0, 5 do
		table.sort(self.dress_get_items[i], function (a, b)
			local a_qlt = xyd.tables.itemTable:getQuality(a.itemID)
			local b_qlt = xyd.tables.itemTable:getQuality(b.itemID)

			if a_qlt ~= b_qlt then
				return b_qlt < a_qlt
			else
				return a.itemID < b.itemID
			end
		end)
	end
end

function Dress:updateItems(item)
	local dress_id = xyd.tables.senpaiDressItemTable:getDressId(item.item_id)
	local pos_id = xyd.tables.senpaiDressTable:getPos(dress_id)
	local all_items = xyd.tables.senpaiDressTable:getItems(dress_id)
	local is_have = false

	for i in pairs(all_items) do
		if self.dress_items[0][all_items[i]] then
			is_have = true

			break
		end
	end

	if is_have then
		self:updateDressGetItems(pos_id, item.item_id, tonumber(item.item_num))
	else
		self:updateDressGetItems(pos_id, item.item_id, tonumber(item.item_num), true)
		self:updateGroupItems(item.item_id, dress_id, true)
		self:updateAttr(item.item_id)
	end
end

function Dress:getDressGetItems()
	return self.dress_get_items
end

function Dress:updateDressGetItems(pos_id, item_id, item_num, isAddNew)
	local flag = false

	if isAddNew == nil then
		isAddNew = false
	end

	if isAddNew == false then
		for i in pairs(self.dress_get_items[0]) do
			if self.dress_get_items[0][i].itemID == item_id then
				if item_num > 0 then
					self.dress_get_items[0][i].itemNum = item_num
					self.dress_items[0][item_id].itemNum = item_num
					self.dress_items[pos_id][item_id].itemNum = item_num
				else
					table.remove(self.dress_get_items[0], i)

					self.dress_items[0][item_id] = nil
					self.dress_items[pos_id][item_id] = nil
				end

				flag = true

				break
			end
		end

		for i in pairs(self.dress_get_items[pos_id]) do
			if self.dress_get_items[pos_id][i].itemID == item_id then
				if item_num > 0 then
					self.dress_get_items[pos_id][i].itemNum = item_num

					break
				end

				table.remove(self.dress_get_items[pos_id], i)

				break
			end
		end
	end

	if not flag and item_num > 0 then
		self.dress_items[0][item_id] = {
			itemID = item_id,
			itemNum = item_num
		}
		self.dress_items[pos_id][item_id] = {
			itemID = item_id,
			itemNum = item_num
		}

		table.insert(self.dress_get_items[0], self.dress_items[0][item_id])
		table.insert(self.dress_get_items[pos_id], self.dress_items[pos_id][item_id])

		local function sort_fun(a, b)
			return a.itemID < b.itemID
		end

		table.sort(self.dress_get_items[0], sort_fun)
		table.sort(self.dress_get_items[pos_id], sort_fun)

		for i = 0, 5 do
			table.sort(self.dress_get_items[i], function (a, b)
				return a.itemID < b.itemID
			end)
		end

		local skills = xyd.tables.senpaiDressItemTable:getSkillIds(item_id)

		if skills and #skills > 0 then
			for i in pairs(skills) do
				if xyd.arrayIndexOf(self:getBaseInfo().skills, tonumber(skills[i])) == -1 then
					table.insert(self:getBaseInfo().skills, tonumber(skills[i]))
					self:updateBuff2Attr(true, skills[i])
					self:updateSkillsActiveVlue(true, skills[i])
				end
			end
		end
	end
end

function Dress:updateDressFragment(item)
	local num = tonumber(item.item_num)
	local qlt = xyd.tables.itemTable:getQuality(item.item_id)

	if self.dress_item_fragment_arr[0][item.item_id] then
		if num > 0 then
			self.dress_item_fragment_arr[0][item.item_id].itemNum = num
			self.dress_item_fragment_arr[qlt][item.item_id].itemNum = num
		else
			self.dress_item_fragment_arr[0][item.item_id] = nil
			self.dress_item_fragment_arr[qlt][item.item_id] = nil
		end
	elseif num > 0 then
		self.dress_item_fragment_arr[0][item.item_id] = {
			itemID = item.item_id,
			itemNum = num
		}
		self.dress_item_fragment_arr[qlt][item.item_id] = {
			itemID = item.item_id,
			itemNum = num
		}
	end
end

function Dress:getFragmentArr(qlt)
	return self.dress_item_fragment_arr[qlt]
end

function Dress:updateGroupItems(item_id, dress_id, is_extra)
	local group = xyd.tables.senpaiDressItemTable:getGroup(item_id)
	local pos = xyd.tables.senpaiDressTable:getPos(dress_id)

	if not self.group_items[group] then
		self.group_items[group] = {
			0,
			0,
			0,
			0,
			0
		}
	end

	if self.group_items[group][pos] == 0 then
		self.group_items[group][pos] = item_id
	else
		local old_item_id = self.group_items[group][pos]
		local old_star = xyd.tables.senpaiDressItemTable:getStar(old_item_id)
		local new_star = xyd.tables.senpaiDressItemTable:getStar(item_id)

		if old_star < new_star then
			self.group_items[group][pos] = item_id
		end
	end

	if not is_extra then
		return
	end

	local all_num = #xyd.tables.senpaiDressGroupTable:getUnit(group)
	local has_num = 0
	local star_num = 0

	for i, arr_item_id in pairs(self.group_items[group]) do
		if arr_item_id > 0 then
			has_num = has_num + 1
			star_num = star_num + xyd.tables.senpaiDressItemTable:getStar(arr_item_id)
		end
	end

	if has_num == all_num then
		local stars = xyd.tables.senpaiDressGroupTable:getUnlockStars(group)
		local skills = xyd.tables.senpaiDressGroupTable:getSkills(group)

		if stars and skills then
			for i in pairs(stars) do
				if stars[i] <= star_num then
					if skills[i] and skills[i] > 0 and xyd.arrayIndexOf(self:getBaseInfo().skills, tonumber(skills[i])) == -1 then
						table.insert(self:getBaseInfo().skills, tonumber(skills[i]))
						self:updateBuff2Attr(true, skills[i])
						self:updateSkillsActiveVlue(true, skills[i])
					end
				else
					break
				end
			end
		end
	end
end

function Dress:getGroupItems(group)
	if not self.group_items[group] then
		self.group_items[group] = {
			0,
			0,
			0,
			0,
			0
		}
	end

	return self.group_items[group]
end

function Dress:onGetData(event)
	dump(xyd.decodeProtoBuf(event.data), "test get data==========")

	self.base_info = xyd.decodeProtoBuf(event.data)

	if not self.base_info.equiped_styles then
		self.base_info.equiped_styles = {}
	end

	if not self.base_info.styles then
		self.base_info.styles = {}
	end

	if not self.base_info.skills then
		self.base_info.skills = {}
	end

	self:updateSkillsActiveVlue()

	if not self.base_info.saved_styles then
		self.base_info.saved_styles = {}
	end

	self:updateBuff2Attr()

	self.dress_id_style_arr = {}
	self.dress_id_pos_arr = {
		[0] = {},
		{},
		{},
		{},
		{},
		{}
	}
	self.all_has_dress_id = {}

	for i, has_style_id in pairs(self.base_info.styles) do
		self:updateCheckStyleId(has_style_id)
	end

	if not self.base_info.dynamics then
		self.base_info.dynamics = {}
	else
		self.base_info.dynamics = JSON.decode(self.base_info.dynamics)
	end

	if not self.base_info.attrs then
		self.base_info.attrs = {
			0,
			0,
			0
		}
	end

	self.summon_attrs = {
		0,
		0,
		0
	}
	self.summon_count_skill_id = 1000101

	self:countAttrs(self.base_info.dynamics[tostring(self.summon_count_skill_id)])

	for i in pairs(self.base_info.attrs) do
		self.base_info.attrs[i] = self.base_info.attrs[i] - self.summon_attrs[i]
	end

	local local_sava_chose_style_by_dress_id = xyd.db.misc:getValue("local_sava_chose_style_by_dress_id")

	if not local_sava_chose_style_by_dress_id then
		self.local_sava_chose_style_by_dress_id = {}
	else
		self.local_sava_chose_style_by_dress_id = JSON.decode(local_sava_chose_style_by_dress_id)
	end

	for i, style_id in pairs(self.base_info.equiped_styles) do
		if style_id ~= 0 then
			local dress_id = xyd.tables.senpaiDressStyleTable:getDressId(style_id)
			self.local_sava_chose_style_by_dress_id[tostring(dress_id)] = style_id
		end
	end
end

function Dress:countAttrs(summon_num)
	summon_num = tonumber(summon_num)
	self.summon_attrs = {
		0,
		0,
		0
	}
	self.summon_count_skill_id = 1000101

	if summon_num then
		local summon_nums = xyd.tables.senpaiDressSkillTable:getNums(self.summon_count_skill_id)
		local max_num = 0

		for i, skill_id in pairs(self:getBaseInfo().skills) do
			local buff = xyd.tables.senpaiDressSkillTable:getBuff(skill_id)

			if buff == xyd.DressBuffAttrType.SUMMON then
				summon_nums = xyd.tables.senpaiDressSkillTable:getNums(skill_id)
				max_num = max_num + summon_nums[1]
			end
		end

		local sumonn_add_count = tonumber(summon_num)
		local times = math.floor(sumonn_add_count / summon_nums[2])

		if max_num < times then
			times = max_num
		end

		local sumoon_attrs_add_yet_num = times * summon_nums[3]
		self.summon_attrs = {
			sumoon_attrs_add_yet_num,
			sumoon_attrs_add_yet_num,
			sumoon_attrs_add_yet_num
		}
	end
end

function Dress:getBaseInfo()
	if not self.base_info then
		self.base_info = {}

		if not self.base_info.equiped_styles then
			self.base_info.equiped_styles = {}
		end

		if not self.base_info.styles then
			self.base_info.styles = {}
		end

		if not self.base_info.skills then
			self.base_info.skills = {}
		end

		if not self.base_info.saved_styles then
			self.base_info.saved_styles = {}
		end

		if not self.base_info.attrs then
			self.base_info.attrs = {
				0,
				0,
				0
			}
		end

		local ids = xyd.tables.senpaiDressSlotTable:getIDs()

		for i in pairs(ids) do
			local default_style = xyd.tables.senpaiDressSlotTable:getDefaultStyle(ids[i])

			if default_style then
				table.insert(self.base_info.equiped_styles, default_style)
			else
				table.insert(self.base_info.equiped_styles, 0)
			end
		end
	end

	return self.base_info
end

function Dress:getEquipedStyles()
	return self:getBaseInfo().equiped_styles
end

function Dress:getAttrs()
	if self:getBaseInfo().dynamics[tostring(self.summon_count_skill_id)] then
		self:countAttrs(self:getBaseInfo().dynamics[tostring(self.summon_count_skill_id)])
	end

	local return_arr = {}

	for i in pairs(self:getBaseInfo().attrs) do
		table.insert(return_arr, self:getBaseInfo().attrs[i] + self.summon_attrs[i])
	end

	return return_arr
end

function Dress:getSavedStyles()
	return self:getBaseInfo().saved_styles
end

function Dress:getStyles()
	return self:getBaseInfo().styles
end

function Dress:getActiveSkills()
	return self:getBaseInfo().skills
end

function Dress:getActiveBuffDynamics()
	return self:getBaseInfo().dynamics
end

function Dress:getEffectEquipedStyles()
	local all_equips = self:getEquipedStyles()
	local effect_equips = {}

	for i in pairs(all_equips) do
		if all_equips[i] ~= 0 then
			table.insert(effect_equips, all_equips[i])
		end
	end

	return effect_equips
end

function Dress:getDressItems()
	return self:getDressGetItems()
end

function Dress:getHasStyles(dress_id)
	if self.dress_id_style_arr[tostring(dress_id)] then
		return self.dress_id_style_arr[tostring(dress_id)]
	else
		return {}
	end
end

function Dress:getHasDressIds(pos)
	return self.dress_id_pos_arr[pos]
end

function Dress:setEquip(style, pos)
	if style and style > 0 and (pos == xyd.DressPosState.HEAD_ORNAMENTS or pos == xyd.DressPosState.OTHER_ORNAMENTS) and (UNITY_ANDROID and XYDUtils.CompVersion(UnityEngine.Application.version, xyd.ANDROID_1_4_88) < 0 or UNITY_IOS and XYDUtils.CompVersion(UnityEngine.Application.version, xyd.IOS_71_3_51) < 0) then
		xyd.alertTips(__("PERSON_DRESS_TIPS_1"))

		return
	end

	local self_equips = {}

	for i, style_id in pairs(self:getEquipedStyles()) do
		table.insert(self_equips, style_id)
	end

	self_equips[pos] = style
	local msg = messages_pb:dress_equip_styles_req()

	for i in pairs(self_equips) do
		table.insert(msg.style_ids, self_equips[i])
	end

	xyd.Backend.get():request(xyd.mid.DRESS_EQUIP_STYLES, msg)
	self:setLocalChoice(style)
end

function Dress:setAllEquip(styles)
	local is_old_version = false

	if UNITY_ANDROID and XYDUtils.CompVersion(UnityEngine.Application.version, xyd.ANDROID_1_4_88) < 0 or UNITY_IOS and XYDUtils.CompVersion(UnityEngine.Application.version, xyd.IOS_71_3_51) < 0 then
		is_old_version = true
	end

	local msg = messages_pb:dress_equip_styles_req()

	for i in pairs(styles) do
		local pos = xyd.tables.senpaiDressStyleTable:getPos(styles[i])

		if is_old_version and pos and pos > 0 and (pos == xyd.DressPosState.HEAD_ORNAMENTS or pos == xyd.DressPosState.OTHER_ORNAMENTS) then
			table.insert(msg.style_ids, 0)
		else
			table.insert(msg.style_ids, styles[i])
		end
	end

	xyd.Backend.get():request(xyd.mid.DRESS_EQUIP_STYLES, msg)

	for i in pairs(styles) do
		self:setLocalChoice(styles[i])
	end
end

function Dress:equipBack(event)
	local data = xyd.decodeProtoBuf(event.data)
	self:getBaseInfo().equiped_styles = data.style_ids

	dump(self:getBaseInfo().equiped_styles, "test equip back========")

	local dress_main_wn = xyd.WindowManager.get():getWindow("dress_main_window")

	if dress_main_wn then
		dress_main_wn:updateEuqip()
	end
end

function Dress:setLocalChoice(style_id)
	if style_id == 0 then
		return
	end

	local dress_id = xyd.tables.senpaiDressStyleTable:getDressId(style_id)
	local flag = false

	if self.local_sava_chose_style_by_dress_id[tostring(dress_id)] then
		if self.local_sava_chose_style_by_dress_id[tostring(dress_id)] ~= style_id then
			flag = true
		end
	else
		flag = true
	end

	if flag then
		self.local_sava_chose_style_by_dress_id[tostring(dress_id)] = style_id

		dump(self.local_sava_chose_style_by_dress_id, "test value choice")
		xyd.db.misc:setValue({
			key = "local_sava_chose_style_by_dress_id",
			value = JSON.encode(self.local_sava_chose_style_by_dress_id)
		})
	end
end

function Dress:getLocalChoice(dress_id)
	return self.local_sava_chose_style_by_dress_id[tostring(dress_id)]
end

function Dress:dressSuitSave(event)
	local data = xyd.decodeProtoBuf(event.data)
	self:getBaseInfo().saved_styles = data.saved_styles
end

function Dress:dressSuitRemove(event)
	local data = xyd.decodeProtoBuf(event.data)

	if data.saved_styles then
		self:getBaseInfo().saved_styles = data.saved_styles
	else
		self:getBaseInfo().saved_styles = {}
	end
end

function Dress:dressUpgradeDressBack(event)
	local data = xyd.decodeProtoBuf(event.data)
	local old_skills = {}

	for i in pairs(self:getBaseInfo().skills) do
		table.insert(old_skills, self:getBaseInfo().skills[i])
	end

	self:getBaseInfo().skills = data.dress_info.skills

	if not self:getBaseInfo().skills then
		self:getBaseInfo().skills = {}
	end

	for i, skill_id in pairs(self:getBaseInfo().skills) do
		if xyd.arrayIndexOf(old_skills, skill_id) == -1 then
			self:updateSkillsActiveVlue(true, skill_id)
		end
	end

	self:getBaseInfo().attrs = data.dress_info.attrs

	if not self:getBaseInfo().attrs then
		self:getBaseInfo().attrs = {
			0,
			0,
			0
		}
	end

	for i in pairs(self:getBaseInfo().attrs) do
		self:getBaseInfo().attrs[i] = self:getBaseInfo().attrs[i] - self.summon_attrs[i]
	end

	self:updateBuff2Attr()
end

function Dress:getThreeMaxValue()
	local self_max_num = 0

	for i, point in pairs(self:getAttrs()) do
		if self_max_num < point then
			self_max_num = point
		end
	end

	local show_point_arr = xyd.tables.miscTable:split2num("max_dress_point", "value", "|")

	for i in pairs(show_point_arr) do
		if self_max_num < show_point_arr[i] then
			self_max_num = show_point_arr[i]

			break
		end
	end

	return self_max_num
end

function Dress:sendUnlockStyle(style_id)
	local msg = messages_pb:dress_unlock_style_req()
	msg.style_id = style_id

	xyd.Backend.get():request(xyd.mid.DRESS_UNLOCK_STYLE, msg)
end

function Dress:dressUnlockStyleBack(event)
	local data = xyd.decodeProtoBuf(event.data)

	if data.style_id then
		local style_id = data.style_id

		if xyd.arrayIndexOf(self:getBaseInfo().styles, style_id) == -1 then
			table.insert(self:getBaseInfo().styles, style_id)
			self:updateCheckStyleId(style_id)
		end
	end

	local dress_main_wn = xyd.WindowManager.get():getWindow("dress_main_window")

	if dress_main_wn then
		dress_main_wn:updateDressIconShowNum(data.style_id)
	end
end

function Dress:updateCheckStyleId(has_style_id)
	local dress_id = xyd.tables.senpaiDressStyleTable:getDressId(has_style_id)

	if dress_id == nil then
		return
	end

	if not self.dress_id_style_arr[tostring(dress_id)] then
		self.dress_id_style_arr[tostring(dress_id)] = {}
	end

	if self.dress_id_style_arr[tostring(dress_id)] and xyd.arrayIndexOf(self.dress_id_style_arr[tostring(dress_id)], has_style_id) == -1 then
		table.insert(self.dress_id_style_arr[tostring(dress_id)], has_style_id)
	end

	if not self.all_has_dress_id[dress_id] then
		local pos = xyd.tables.senpaiDressStyleTable:getPos(has_style_id)

		table.insert(self.dress_id_pos_arr[0], dress_id)
		table.insert(self.dress_id_pos_arr[pos], dress_id)

		self.all_has_dress_id[dress_id] = 1
	end
end

function Dress:onServerBroadMessageBack(event)
	local data = event.data
	local mid = data.mid

	if data.payload == nil then
		return
	end

	if mid == xyd.mid.GET_DRESS_INFO then
		data = event.data
		local payload = JSON.decode(data.payload)
		local style_ids = payload.style_ids

		for i in pairs(style_ids) do
			local style_id = style_ids[i]

			if xyd.arrayIndexOf(self:getBaseInfo().styles, style_id) == -1 then
				table.insert(self:getBaseInfo().styles, style_id)
				self:updateCheckStyleId(style_id)
			end
		end
	end
end

function Dress:checkIsCollide(styleId, checkStyles)
	local pos = xyd.tables.senpaiDressStyleTable:getPos(styleId)

	if pos == xyd.DressPosState.JACKET then
		local jacket_collide = xyd.tables.senpaiDressStyleTable:getCollide(styleId)

		if jacket_collide and jacket_collide ~= 0 then
			local pants_style_id = checkStyles[xyd.DressPosState.PANTS]

			if pants_style_id and pants_style_id ~= 0 then
				local pants_collide = xyd.tables.senpaiDressStyleTable:getCollide(pants_style_id)

				if pants_collide and pants_collide ~= 0 then
					local all_pants_collides = xyd.tables.senpaiDressCollideTable:getCollide(jacket_collide)

					if all_pants_collides and xyd.arrayIndexOf(all_pants_collides, pants_collide) ~= -1 then
						return true
					end
				end
			end
		end
	elseif pos == xyd.DressPosState.PANTS then
		local pants_collide = xyd.tables.senpaiDressStyleTable:getCollide(styleId)

		if pants_collide and pants_collide ~= 0 then
			local jacket_style_id = checkStyles[xyd.DressPosState.JACKET]

			if jacket_style_id and jacket_style_id ~= 0 then
				local jacket_collide = xyd.tables.senpaiDressStyleTable:getCollide(jacket_style_id)

				if jacket_collide and jacket_collide ~= 0 then
					local all_jacket_collides = xyd.tables.senpaiDressCollideTable:getCollide(pants_collide)

					dump(all_jacket_collides, "test value")

					if all_jacket_collides and xyd.arrayIndexOf(all_jacket_collides, jacket_collide) ~= -1 then
						return true
					end
				end
			end
		end
	end

	return false
end

function Dress:updateBuff2Attr(isAdd, skillId)
	if not isAdd then
		self:initBuffTypeAttr()

		for i, skill_id in pairs(self:getBaseInfo().skills) do
			local buff = xyd.tables.senpaiDressSkillTable:getBuff(skill_id)

			if self.buff_type_attr[buff] then
				self.buff_type_attr[buff] = self.buff_type_attr[buff] + xyd.tables.senpaiDressSkillTable:getNums(skill_id)[1]
			end
		end
	else
		local buff = xyd.tables.senpaiDressSkillTable:getBuff(skillId)

		if self.buff_type_attr[buff] then
			self.buff_type_attr[buff] = self.buff_type_attr[buff] + xyd.tables.senpaiDressSkillTable:getNums(skillId)[1]
		end
	end

	dump(self.buff_type_attr, "test complete attrs============")
end

function Dress:getBuffTypeAttr(type)
	if self.buff_type_attr[type] then
		return self.buff_type_attr[type]
	else
		return 0
	end
end

function Dress:updateDynamics(count, state)
	if state == xyd.DressBuffAttrType.SUMMON then
		for i, skill_id in pairs(self:getBaseInfo().skills) do
			local skill_style = xyd.tables.senpaiDressSkillTable:getStyle(skill_id)

			if skill_style == xyd.DressBuffAttrType.SUMMON then
				local first_id = xyd.tables.senpaiDressSkillTable:getFirstId(skill_id)

				if first_id and first_id > 0 then
					self:getBaseInfo().dynamics[tostring(first_id)] = count
				end

				break
			end
		end
	end
end

function Dress:updateAttr(item_id)
	if not self:getBaseInfo().attrs then
		self:getBaseInfo().attrs = {
			0,
			0,
			0
		}
	end

	for i = 1, 3 do
		local base = xyd.tables.senpaiDressItemTable["getBase" .. i](xyd.tables.senpaiDressItemTable, item_id)
		self:getBaseInfo().attrs[i] = self:getBaseInfo().attrs[i] + base
	end
end

function Dress:dressSpecialBuffBack(event)
	local data = xyd.decodeProtoBuf(event.data)

	dump(data, "Special buff back==============")

	if data.buff_id == xyd.DressBuffAttrType.HANG_UP_COIN or data.buff_id == xyd.DressBuffAttrType.HANG_UP_EXP or data.buff_id == xyd.DressBuffAttrType.GUILD_CHECK_IN_GET then
		return
	end

	local mid = data.mid

	if mid and xyd.arrayIndexOf(self.tipsFifhgtMid, mid) > -1 and data.buff_id then
		self.showNextFightTipsId = data.buff_id
	elseif data.buff_id then
		local time = xyd.tables.senpaiDressSkillBuffTable:getShowTime(data.buff_id)

		if not time or time and time < 0.5 then
			time = nil
		end

		if data.buff_id == xyd.DressBuffAttrType.TIME_CLOISTR_TEC or data.buff_id == xyd.DressBuffAttrType.TIME_CLOISTR_TEC_2 then
			if not self.waitStrTime then
				self.waitStrTime = 0
			end

			if time then
				self.waitStrTime = self.waitStrTime + time
			end

			if not self.waitStr then
				self.waitStr = xyd.tables.senpaiDressSkillBuffTextTable:getTips(data.buff_id)
			else
				self.waitStr = self.waitStr .. "\n" .. xyd.tables.senpaiDressSkillBuffTextTable:getTips(data.buff_id)
			end

			XYDCo.WaitForTime(0.5, function ()
				if self.waitStr then
					self:showBuffTips(data.buff_id, self.waitStr, self.waitStrTime)

					self.waitStr = nil
					self.waitStrTime = nil
				end
			end, nil)

			if data.buff_id == xyd.DressBuffAttrType.TIME_CLOISTR_TEC_2 then
				local time_cloister_award_wd = xyd.WindowManager.get():getWindow("time_cloister_award_window")

				if time_cloister_award_wd then
					time_cloister_award_wd:updateDress()
				end
			end
		elseif data.buff_id == xyd.DressBuffAttrType.BUFF_STUDENTS_TEN or data.buff_id == xyd.DressBuffAttrType.BUFF_STUDENTS_EVERY_TIMES then
			if not self.waitStrBuffStudentsTime then
				self.waitStrBuffStudentsTime = 0
			end

			if time then
				self.waitStrBuffStudentsTime = self.waitStrBuffStudentsTime + time
			end

			if not self.waitStrBuffStudents then
				self.waitStrBuffStudents = xyd.tables.senpaiDressSkillBuffTextTable:getTips(data.buff_id)
			elseif data.buff_id == xyd.DressBuffAttrType.BUFF_STUDENTS_TEN then
				self.waitStrBuffStudents = xyd.tables.senpaiDressSkillBuffTextTable:getTips(data.buff_id) .. "\n" .. self.waitStrBuffStudents
			else
				self.waitStrBuffStudents = self.waitStrBuffStudents .. "\n" .. xyd.tables.senpaiDressSkillBuffTextTable:getTips(data.buff_id)
			end

			XYDCo.WaitForTime(0.5, function ()
				if self.waitStrBuffStudents then
					self:showBuffTips(data.buff_id, self.waitStrBuffStudents, self.waitStrBuffStudentsTime)

					self.waitStrBuffStudents = nil
					self.waitStrBuffStudentsTime = nil
				end
			end, nil)
		elseif data.buff_id == xyd.DressBuffAttrType.BUFF_SUMMON_TEN or data.buff_id == xyd.DressBuffAttrType.BUFF_SUMMON_EVERY_TIMES then
			if not self.waitStrBuffSummonTime then
				self.waitStrBuffSummonTime = 0
			end

			if time then
				self.waitStrBuffSummonTime = self.waitStrBuffSummonTime + time
			end

			if not self.waitStrBuffSummon then
				self.waitStrBuffSummon = xyd.tables.senpaiDressSkillBuffTextTable:getTips(data.buff_id)
			elseif data.buff_id == xyd.DressBuffAttrType.BUFF_SUMMON_TEN then
				self.waitStrBuffSummon = xyd.tables.senpaiDressSkillBuffTextTable:getTips(data.buff_id) .. "\n" .. self.waitStrBuffSummon
			else
				self.waitStrBuffSummon = self.waitStrBuffSummon .. "\n" .. xyd.tables.senpaiDressSkillBuffTextTable:getTips(data.buff_id)
			end

			XYDCo.WaitForTime(0.5, function ()
				if self.waitStrBuffSummon then
					self:showBuffTips(data.buff_id, self.waitStrBuffSummon, self.waitStrBuffSummonTime)

					self.waitStrBuffSummon = nil
					self.waitStrBuffSummonTime = nil
				end
			end, nil)
		else
			local delayTime = xyd.tables.senpaiDressSkillBuffTable:getDelay(data.buff_id)

			if delayTime and delayTime > 0 then
				XYDCo.WaitForTime(delayTime, function ()
					self:showBuffTips(data.buff_id)
				end, nil)
			else
				self:showBuffTips(data.buff_id)
			end
		end
	end
end

function Dress:showBuffTips(buffId, str, time)
	if not str then
		local time = xyd.tables.senpaiDressSkillBuffTable:getShowTime(buffId)

		if not time or time and time < 0.5 then
			time = nil
		end

		local str = xyd.tables.senpaiDressSkillBuffTextTable:getTips(buffId)

		if str and str ~= "" then
			xyd.alertTips(str, nil, , , , , , , , , time)
		end
	elseif time and time >= 0.5 then
		xyd.alertTips(str, nil, , , , , , , , , time)
	else
		xyd.alertTips(str)
	end
end

function Dress:showDelayBuffTips(type)
	if type == xyd.DressBuffTipsType.FIGHT_WIN and self.showNextFightTipsId then
		self:showBuffTips(self.showNextFightTipsId)

		self.showNextFightTipsId = nil
	end
end

function Dress:dressSpecialBuffTips(buffId)
	if buffId == xyd.DressBuffAttrType.HANG_UP_COIN or buffId == xyd.DressBuffAttrType.HANG_UP_EXP then
		return
	end

	if buffId then
		self:showBuffTips(buffId)
	end
end

function Dress:getActiveSkillsNum(state)
	if state == xyd.DressBuffAttrType.HANG_UP then
		return self.skills_active_arr[xyd.DressBuffAttrType.HANG_UP] * 60
	elseif state == xyd.DressBuffAttrType.PARTNER_UP_NUM then
		return self.skills_active_arr[xyd.DressBuffAttrType.PARTNER_UP_NUM]
	elseif state == xyd.DressBuffAttrType.GUILD_CHECK_IN_GET then
		return self.skills_active_arr[xyd.DressBuffAttrType.GUILD_CHECK_IN_GET]
	end

	return 0
end

function Dress:updateSkillsActiveVlue(isOnlyAdd, skill_id)
	if not self.skills_active_arr then
		self.skills_active_arr = {
			[xyd.DressBuffAttrType.HANG_UP] = 0,
			[xyd.DressBuffAttrType.PARTNER_UP_NUM] = 0,
			[xyd.DressBuffAttrType.GUILD_CHECK_IN_GET] = 0
		}
	else
		if not self.skills_active_arr[xyd.DressBuffAttrType.HANG_UP] then
			self.skills_active_arr[xyd.DressBuffAttrType.HANG_UP] = 0
		end

		if not self.skills_active_arr[xyd.DressBuffAttrType.PARTNER_UP_NUM] then
			self.skills_active_arr[xyd.DressBuffAttrType.PARTNER_UP_NUM] = 0
		end

		if not self.skills_active_arr[xyd.DressBuffAttrType.GUILD_CHECK_IN_GET] then
			self.skills_active_arr[xyd.DressBuffAttrType.GUILD_CHECK_IN_GET] = 0
		end
	end

	if not isOnlyAdd then
		self.skills_active_arr[xyd.DressBuffAttrType.HANG_UP] = 0
		self.skills_active_arr[xyd.DressBuffAttrType.PARTNER_UP_NUM] = 0
		self.skills_active_arr[xyd.DressBuffAttrType.GUILD_CHECK_IN_GET] = 0

		for i, skill_id in pairs(self:getBaseInfo().skills) do
			local buff_id = xyd.tables.senpaiDressSkillTable:getBuff(skill_id)
			local nums = xyd.tables.senpaiDressSkillTable:getNums(skill_id)

			if nums then
				if buff_id == xyd.DressBuffAttrType.HANG_UP then
					self.skills_active_arr[xyd.DressBuffAttrType.HANG_UP] = self.skills_active_arr[xyd.DressBuffAttrType.HANG_UP] + nums[1]
				elseif buff_id == xyd.DressBuffAttrType.PARTNER_UP_NUM then
					self.skills_active_arr[xyd.DressBuffAttrType.PARTNER_UP_NUM] = self.skills_active_arr[xyd.DressBuffAttrType.PARTNER_UP_NUM] + nums[1]
				elseif buff_id == xyd.DressBuffAttrType.GUILD_CHECK_IN_GET then
					self.skills_active_arr[xyd.DressBuffAttrType.GUILD_CHECK_IN_GET] = self.skills_active_arr[xyd.DressBuffAttrType.GUILD_CHECK_IN_GET] + nums[1]
				end
			end
		end
	else
		local buff_id = xyd.tables.senpaiDressSkillTable:getBuff(skill_id)
		local nums = xyd.tables.senpaiDressSkillTable:getNums(skill_id)

		if nums then
			if buff_id == xyd.DressBuffAttrType.HANG_UP then
				self.skills_active_arr[xyd.DressBuffAttrType.HANG_UP] = self.skills_active_arr[xyd.DressBuffAttrType.HANG_UP] + nums[1]
			elseif buff_id == xyd.DressBuffAttrType.PARTNER_UP_NUM then
				self.skills_active_arr[xyd.DressBuffAttrType.PARTNER_UP_NUM] = self.skills_active_arr[xyd.DressBuffAttrType.PARTNER_UP_NUM] + nums[1]

				xyd.models.slot:dressAddSlotNum(nums[1])
			elseif buff_id == xyd.DressBuffAttrType.GUILD_CHECK_IN_GET then
				self.skills_active_arr[xyd.DressBuffAttrType.GUILD_CHECK_IN_GET] = self.skills_active_arr[xyd.DressBuffAttrType.GUILD_CHECK_IN_GET] + nums[1]
			end
		end
	end
end

function Dress:getCommonQltFragmentArr(qlt, isNeedRemoveID)
	local all_fragment = xyd.models.dress:getFragmentArr(tonumber(qlt))
	local arr = {}

	for i in pairs(all_fragment) do
		if not isNeedRemoveID or isNeedRemoveID ~= all_fragment[i].itemID then
			local params = {
				is_can_use = 0,
				is_common = true,
				item_id = all_fragment[i].itemID,
				item_num = all_fragment[i].itemNum
			}
			local dressId = xyd.tables.itemTable:getDressId(params.item_id)

			if dressId and dressId ~= 0 then
				local all_dress_items = xyd.tables.senpaiDressTable:getItems(dressId)
				local max_item_id = all_dress_items[#all_dress_items]
				local backpack_num = xyd.models.backpack:getItemNumByID(max_item_id)

				if backpack_num > 0 then
					params.is_can_use = 1
				else
					params.is_can_use = 0
				end
			end

			table.insert(arr, params)
		end
	end

	table.sort(arr, function (a, b)
		if a.is_can_use ~= b.is_can_use then
			return b.is_can_use < a.is_can_use
		else
			return a.item_id < b.item_id
		end
	end)

	return arr
end

function Dress:getImgByDressItemId(dress_item_id)
	local dress_id = xyd.tables.senpaiDressItemTable:getDressId(dress_item_id)
	local local_choice = xyd.models.dress:getLocalChoice(dress_id)
	local image = xyd.tables.senpaiDressItemTable:getIcon(dress_item_id)[1]

	if local_choice then
		local all_styles = xyd.tables.senpaiDressTable:getStyles(dress_id)

		for i in pairs(all_styles) do
			if all_styles[i] == local_choice then
				image = xyd.tables.senpaiDressItemTable:getIcon(dress_item_id)[i]

				break
			end
		end
	end

	return image
end

function Dress:showCollideTips(callFun)
	local timeStamp = xyd.db.misc:getValue("dress_collide_time_stamp")

	if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
		xyd.openWindow("gamble_tips_window", {
			type = "dress_collide",
			wndType = self.curWindowType_,
			text = __("SENPAI_DRESS_COLLIDE_TIPS"),
			callback = function ()
				callFun()
			end
		})
	else
		callFun()
	end
end

return Dress
