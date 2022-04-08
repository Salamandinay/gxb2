local ActivityPointTips = class("ActivityPointTips", import("app.models.BaseModel"))
local TipsTable = xyd.tables.tipsActivityPointTable
local ActivityIDs = {
	xyd.ActivityID.PROPHET_SUMMON_GIFTBAG,
	xyd.ActivityID.WISHING_POOL_GIFTBAG,
	xyd.ActivityID.NEW_SUMMON_GIFTBAG,
	xyd.ActivityID.ACTIVITY_TREE_GROUP,
	xyd.ActivityID.PUB_MISSION_GIFTBAG,
	xyd.ActivityID.BATTLE_ARENA_GIFTBAG,
	xyd.ActivityID.SHENXUE_GIFTBAG,
	xyd.ActivityID.ACTIVITY_DRESS_OPENING_CEREMONY
}

function ActivityPointTips:ctor()
	ActivityPointTips.super.ctor(self)

	self.tips = {}
	self.ids_ = TipsTable:getIds()
end

function ActivityPointTips:onRegister()
	self:registerEvent(xyd.event.SUMMON, handler(self, self.updateData1))
	self:registerEvent(xyd.event.GAMBLE_GET_AWARD, handler(self, self.updateData2))
	self:registerEvent(xyd.event.ARENA_FIGHT, handler(self, self.updateData4))
	self:registerEvent(xyd.event.ARENA_3v3_FIGHT, handler(self, self.updateData5))
	self:registerEvent(xyd.event.COMPOSE_PARTNER, handler(self, self.updateData6))
	self:registerEvent(xyd.event.AWAKE_PARTNER, handler(self, self.updateData7))
	self:registerEvent(xyd.event.RED_POINT, self.updateData8, self)
end

function ActivityPointTips:initData()
	self.data_1 = {}
	self.data_2 = {}

	for i = 1, #self.ids_ do
		local activityId = TipsTable:getActivityID(i)
		local activityData = xyd.models.activity:getActivity(activityId)

		if activityData then
			local limit_circle = xyd.tables.activityTable:getRound(activityId) or {}
			local condition = TipsTable:getCondition(i)
			local tableName = self:Json2Table(condition[1])

			if not tableName then
				break
			end

			local limits = {}
			local ids = tableName:getIDs()

			for i = 1, #ids do
				table.insert(limits, tableName:getPoint(i))
			end

			local point = activityData.detail.point or activityData.detail.points

			if point then
				self.data_1[activityId] = {
					table_id = i,
					activityId = activityId,
					point = point,
					limits = limits,
					circle = activityData.detail.circle_times or -2,
					limit_circle = limit_circle[2] or -1,
					basePoint = activityData.detail.point or 0,
					round_point = limit_circle[1] or 0
				}
			else
				local points = activityData.detail.values or activityData.detail.times

				if not points and activityId == xyd.ActivityID.BATTLE_ARENA_GIFTBAG then
					local point2 = activityData.detail.point_2
					local point3 = activityData.detail.point_3
					points = {
						point2,
						point2,
						point2,
						point2,
						point3,
						point3,
						point3,
						point3
					}
				end

				local awarded = activityData.detail.awarded

				if not awarded then
					awarded = {}

					for i = 1, #points do
						if points[i] == limits[i] then
							awarded[i] = 1
						else
							awarded[i] = 0
						end
					end
				end

				self.data_2[activityId] = {
					table_id = i,
					activityId = activityId,
					points = points,
					limits = limits,
					awarded = awarded,
					tableName = tableName
				}
			end
		end
	end

	if self.data_1[ActivityIDs[4]] then
		for i = 1, #self.data_1[ActivityIDs[4]].point do
			self.data_1[ActivityIDs[4]].point[i] = self.data_1[ActivityIDs[4]].point[i] % self.data_1[ActivityIDs[4]].limits[i]
		end
	end
end

function ActivityPointTips:updateData1(event)
	local summon_id = event.data.summon_id

	if not summon_id then
		return
	end

	if summon_id == 4 or summon_id == 6 or summon_id == 8 then
		if self.data_1[ActivityIDs[3]] then
			self.data_1[ActivityIDs[3]].point = self.data_1[ActivityIDs[3]].point + 1
		end
	elseif summon_id == 5 or summon_id == 7 or summon_id == 29 then
		if self.data_1[ActivityIDs[3]] then
			self.data_1[ActivityIDs[3]].point = self.data_1[ActivityIDs[3]].point + 10
		end
	elseif summon_id >= 10 and summon_id <= 14 then
		if self.data_1[ActivityIDs[1]] then
			self.data_1[ActivityIDs[1]].point = self.data_1[ActivityIDs[1]].point + 1
		end

		if self.data_1[ActivityIDs[4]] then
			self.data_1[ActivityIDs[4]].point[summon_id - 9] = self.data_1[ActivityIDs[4]].point[summon_id - 9] + 1
		end
	elseif summon_id >= 17 and summon_id <= 21 then
		if self.data_1[ActivityIDs[1]] then
			self.data_1[ActivityIDs[1]].point = self.data_1[ActivityIDs[1]].point + 10
		end

		if self.data_1[ActivityIDs[4]] then
			self.data_1[ActivityIDs[4]].point[summon_id - 16] = self.data_1[ActivityIDs[4]].point[summon_id - 16] + 10
		end
	else
		return
	end

	self:checkTips()
end

function ActivityPointTips:updateData2(event)
	local gamble_type = event.data.gamble_type

	if gamble_type == 1 and self.data_1[ActivityIDs[2]] then
		local awards = event.data.awards
		self.data_1[ActivityIDs[2]].point = self.data_1[ActivityIDs[2]].point + #awards

		self:checkTips()
	end
end

function ActivityPointTips:updateData3(table_id)
	local star = xyd.tables.pubMissionTable:getStar(table_id) - 3

	if star > 0 and self.data_2[xyd.ActivityID.PUB_MISSION_GIFTBAG] then
		self.data_2[xyd.ActivityID.PUB_MISSION_GIFTBAG].points[star] = self.data_2[xyd.ActivityID.PUB_MISSION_GIFTBAG].points[star] + 1

		self:checkTips2()
	end
end

function ActivityPointTips:updateData4(event)
	local data = event.data

	if self.data_2[xyd.ActivityID.BATTLE_ARENA_GIFTBAG] then
		local point = 1

		if data.is_win == 1 then
			point = 2
		end

		for i = 1, 4 do
			self.data_2[xyd.ActivityID.BATTLE_ARENA_GIFTBAG].points[i] = self.data_2[xyd.ActivityID.BATTLE_ARENA_GIFTBAG].points[i] + point
		end

		self:checkTips2()
	end
end

function ActivityPointTips:updateData5(event)
	local data = event.data

	if self.data_2[xyd.ActivityID.BATTLE_ARENA_GIFTBAG] then
		local point = 1

		if data.is_win == 1 then
			point = 2
		end

		for i = 5, 8 do
			self.data_2[xyd.ActivityID.BATTLE_ARENA_GIFTBAG].points[i] = self.data_2[xyd.ActivityID.BATTLE_ARENA_GIFTBAG].points[i] + point
		end

		self:checkTips2()
	end
end

function ActivityPointTips:updateData6(event)
	local table_id = event.data.partner_info.table_id
	local star = xyd.tables.partnerTable:getStar(table_id) - 4

	if self.data_2[xyd.ActivityID.SHENXUE_GIFTBAG] then
		self.data_2[xyd.ActivityID.SHENXUE_GIFTBAG].points[star] = self.data_2[xyd.ActivityID.SHENXUE_GIFTBAG].points[star] + 1

		self:checkTips2()
	end
end

function ActivityPointTips:updateData7(event)
	local index = 0
	local awake = event.data.partner_info.awake
	local star = xyd.tables.partnerTable:getStar(event.data.partner_info.table_id)

	if awake == 3 then
		index = 3
	elseif awake == 0 and star == 10 then
		index = 4
	end

	if index > 0 and self.data_2[xyd.ActivityID.SHENXUE_GIFTBAG] then
		self.data_2[xyd.ActivityID.SHENXUE_GIFTBAG].points[index] = self.data_2[xyd.ActivityID.SHENXUE_GIFTBAG].points[index] + 1

		self:checkTips2()
	end
end

function ActivityPointTips:updateData8(event)
	if event.data.function_id ~= xyd.FunctionID.ACTIVITY and event.data.function_id ~= xyd.FunctionID.ACHIEVEMENT then
		return
	end

	if event.data.function_id == xyd.FunctionID.ACTIVITY then
		local id = tostring(event.data.value)

		if #id == 5 then
			local activity_id = tonumber(string.sub(id, 1, 3))

			if activity_id == xyd.ActivityID.ACTIVITY_DRESS_OPENING_CEREMONY then
				local table_id = tonumber(string.sub(id, 4, 5))

				table.insert(self.tips, {
					table_id = xyd.TipsActivityPoint.ACTIVITY_DRESS_OPENING_CEREMONY,
					activityId = xyd.ActivityID.ACTIVITY_DRESS_OPENING_CEREMONY,
					des = xyd.tables.activityDressGachaAwardTextTable:getTaskDesc(table_id)
				})
				self:nextTip()
			end
		end
	else
		local id = tonumber(event.data.value)
		local textType = 1
		local ids = xyd.tables.achievementTypeTable:getIDs()

		for i = 1, #ids do
			if id <= xyd.tables.achievementTypeTable:getEndAchievement(tonumber(ids[i])) and xyd.tables.achievementTypeTable:getStartAchievement(tonumber(ids[i])) <= id then
				textType = tonumber(ids[i])
			end
		end

		local des = xyd.tables.achievementTextTable:getDesc(textType, xyd.tables.achievementTable:getCompleteValue(id))

		if tonumber(textType) == 44 then
			des = xyd.tables.achievementTextTable:getDesc(textType, xyd.tables.arenaAllServerRankText:getDesc(xyd.tables.achievementTable:getCompleteValue(id)))
		end

		des = string.gsub(des, "\n", " ")

		table.insert(self.tips, {
			table_id = id,
			activityId = xyd.ActivityID.BATTLE_PASS,
			des = des
		})
		self:nextTip()
	end
end

function ActivityPointTips:checkTips()
	for aid, _ in pairs(self.data_1) do
		if aid == xyd.ActivityID.ACTIVITY_TREE_GROUP then
			for i = 1, #self.data_1[aid].point do
				if self.data_1[aid].limits[i] <= self.data_1[aid].point[i] then
					self.data_1[aid].point[i] = self.data_1[aid].point[i] % self.data_1[aid].limits[i]
					local groupText = __("GROUP_" .. i)

					if i == 5 then
						groupText = __("GROUP_5_6")
					end

					self:addTips(self.data_1[aid].table_id, aid, {
						groupText,
						self.data_1[aid].limits[i]
					}, 1)
				end
			end
		elseif self.data_1[aid].circle < self.data_1[aid].limit_circle then
			for i = 1, #self.data_1[aid].limits do
				local limit = self.data_1[aid].limits[i]

				if self.data_1[aid].basePoint < limit and limit <= self.data_1[aid].point then
					self:addTips(self.data_1[aid].table_id, aid, {
						limit,
						self.data_1[aid].circle + 1
					}, 1)

					if self.data_1[aid].round_point <= self.data_1[aid].point then
						self.data_1[aid].circle = self.data_1[aid].circle + 1
					end

					self.data_1[aid].point = self.data_1[aid].point % self.data_1[aid].round_point
					self.data_1[aid].basePoint = self.data_1[aid].point

					break
				end
			end
		end
	end
end

function ActivityPointTips:checkTips2()
	for aid, _ in pairs(self.data_2) do
		local points = self.data_2[aid].points
		local limits = self.data_2[aid].limits
		local awarded = self.data_2[aid].awarded

		for i = 1, #points do
			if limits[i] <= points[i] and awarded[i] == 0 then
				local limit = limits[i]
				local type = 1

				if aid == xyd.ActivityID.PUB_MISSION_GIFTBAG or aid == xyd.ActivityID.SHENXUE_GIFTBAG then
					limit = self.data_2[aid].tableName:getStar(i)
				end

				if aid == xyd.ActivityID.BATTLE_ARENA_GIFTBAG or aid == xyd.ActivityID.SHENXUE_GIFTBAG then
					type = self.data_2[aid].tableName:getType(i)
				end

				self.data_2[aid].awarded[i] = 1

				self:addTips(self.data_2[aid].table_id, aid, {
					limit
				}, type)
			end
		end
	end
end

function ActivityPointTips:addTips(table_id, activityId, params, index)
	local content = TipsTable:getContent(table_id)
	content = content or {
		"",
		""
	}
	content = content[index]
	local ordinals = {}

	for num in content:gmatch("{(%d+)}") do
		table.insert(ordinals, tonumber(num))
	end

	for _, num in ipairs(ordinals) do
		content = string.gsub(content, "{" .. num .. "}", params[num])
	end

	table.insert(self.tips, {
		table_id = table_id,
		activityId = activityId,
		des = content
	})
	self:nextTip()
end

function ActivityPointTips:nextTip()
	if self.showTips or #self.tips == 0 then
		return
	end

	local params = table.remove(self.tips)

	self:showTip(params)
end

function ActivityPointTips:showTip(params)
	local function callback()
		self:setFlag(true)

		local win = xyd.getWindow("activity_point_tips_window")

		if not win then
			xyd.alertTips("11111111111111")

			return
		end

		win:setInfo(params)
	end

	local win = xyd.getWindow("activity_point_tips_window")

	if not win then
		win = xyd.openWindow("activity_point_tips_window", {}, callback)
	else
		callback()
	end
end

function ActivityPointTips:setFlag(flag)
	self.showTips = flag
end

function ActivityPointTips:Json2Table(jsonName)
	local table = nil
	local switch = {
		activity_tree = function ()
			table = xyd.tables.activityTreeTable
		end,
		activity_gamble = function ()
			table = xyd.tables.activityGambleTable
		end,
		activity_gacha = function ()
			table = xyd.tables.activityGachaTable
		end,
		activity_tree_group_award = function ()
			table = xyd.tables.activityTreeGroupAwardTable
		end,
		activity_pub_mission = function ()
			table = xyd.tables.activityPubMissionTable
		end,
		activity_arena = function ()
			table = xyd.tables.activityArenaTable
		end,
		activity_compose = function ()
			table = xyd.tables.activityComposeTable
		end
	}

	if switch[jsonName] then
		switch[jsonName]()
	end

	return table
end

function ActivityPointTips:Json2Point(jsonName, table, id)
	local point = nil
	local switch = {
		point = function ()
			point = table:getPoint(id)
		end,
		star = function ()
			point = table:getStar(id)
		end
	}

	if switch[jsonName] then
		switch[jsonName]()
	end

	return point
end

function ActivityPointTips:disposeAll()
	ActivityPointTips.super.disposeAll(self)

	local win = xyd.getWindow("activity_point_tips_window")

	if win then
		xyd.closeWindow("activity_point_tips_window")
	end
end

return ActivityPointTips
