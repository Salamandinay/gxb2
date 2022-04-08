local BaseModel = import(".BaseModel")
local PartnerDataStation = class("PartnerDataStation", BaseModel)
local Monster = import("app.models.Monster")

function PartnerDataStation:ctor()
	PartnerDataStation.super.ctor(self)

	self.monsters_ = {}
	self.ranks_ = {}
	self.formation_records_ = {}
end

function PartnerDataStation:onRegister()
	PartnerDataStation.super.onRegister(self)
	self:registerEvent(xyd.event.GET_PARTNER_DATA_INFO, handler(self, self.updateInfo))
	self:registerEvent(xyd.event.GET_PARTNER_COMMENTS, handler(self, self.updateTags))
	self:registerEvent(xyd.event.UPDATE_PARTNER_TAGS, handler(self, self.updateTags))
end

function PartnerDataStation:updateInfo(event)
	local ranks = event.data.attendance_ranks
	self.ranks_ = {}

	for _, rank in pairs(ranks) do
		table.insert(self.ranks_, rank)
	end

	local formation_records = event.data.formation_records
	self.formation_records_ = {}

	for _, formation_record in pairs(formation_records) do
		table.insert(self.formation_records_, formation_record)
	end
end

function PartnerDataStation:updateTags(event)
	self.tags = {}
	self.tagsMap = {}
	local tags = event.data.tags
	local selfTags = event.data.self_tags

	for i = 1, #tags do
		self.tags[i] = {}

		table.insert(self.tags[i], i)
		table.insert(self.tags[i], tags[i])

		self.tagsMap[i] = tags[i]
	end

	self.selfTags = {}

	for i = 1, #selfTags do
		if selfTags[i] then
			table.insert(self.selfTags, selfTags[i])
		end
	end
end

function PartnerDataStation:getSelfLabels(id)
	local result = {}

	table.insertto(result, self.selfTags)

	if #result < 3 then
		local len = #result

		for i = 1, 3 - len do
			table.insert(result, xyd.tables.partnerDirectTable:getLabelId(id, i))
		end
	end

	return result
end

function PartnerDataStation:getThreeLabel(id)
	table.sort(self.tags, function (a, b)
		return b[2] < a[2]
	end)

	local result = {}

	for i = 1, 3 do
		table.insert(result, tonumber(xyd.tables.partnerDirectTable:getLabelId(id, i)))
	end

	local cnt = 1

	for i = 1, #self.tags do
		if self.tags[i][2] >= 100 and cnt <= 3 then
			result[cnt] = self.tags[i][1]
			cnt = cnt + 1
		else
			break
		end
	end

	return result
end

function PartnerDataStation:checkIfEnough(id)
	return self.tagsMap[tonumber(id)] >= 100
end

function PartnerDataStation:getLabelNum(id)
	return self.tagsMap[tonumber(id)]
end

function PartnerDataStation:getRank(id)
	return self.ranks_[id]
end

function PartnerDataStation:getRecord(id)
	return self.formation_records_[id]
end

function PartnerDataStation:getRecords()
	return self.formation_records_
end

function PartnerDataStation:reqLabel(params)
	local msg = messages_pb.update_partner_tags_req()
	msg.table_id = params.table_id

	for _, id in pairs(params.tags) do
		table.insert(msg.tags, id)
	end

	xyd.Backend.get():request(xyd.mid.UPDATE_PARTNER_TAGS, msg)
end

function PartnerDataStation:getPartner(id)
	for i = 1, 4 do
		local heros = self:getHeros(i)

		for _, p in pairs(heros) do
			if p:getPartnerID() == id then
				return p
			end
		end
	end

	return nil
end

function PartnerDataStation:getHeros(type)
	if #self.monsters_ <= 0 then
		self:initEnemy()
	end

	return self.monsters_[type]
end

function PartnerDataStation:initEnemy()
	local ids = xyd.tables.directMonsterTable:getIds()

	for i = 1, 4 do
		table.insert(self.monsters_, {})
	end

	for _, id in pairs(ids) do
		local type = xyd.tables.directMonsterTable:getType(id)
		local np = Monster.new()

		np:populateWithTableID(xyd.tables.directMonsterTable:getMonsterId(id), {
			partnerID = id
		})
		table.insert(self.monsters_[type], np)
	end
end

function PartnerDataStation:reqBattle(params)
	local msg = messages_pb.partner_data_fight_req()
	msg.table_id = params.table_id
	msg.type_id = params.type_id
	msg.index = params.index

	dump(msg)
	xyd.Backend.get():request(xyd.mid.PARTNER_DATA_FIGHT, msg)
end

function PartnerDataStation:reqFormation(params)
	local msg = messages_pb.get_partner_data_info_req()
	msg.table_id = params.table_id

	dump(msg)
	xyd.Backend.get():request(xyd.mid.GET_PARTNER_DATA_INFO, msg)
end

function PartnerDataStation:reqTouchId(id)
	if xyd.models.selfPlayer:getPlayerID() % 50 == 1 then
		local msg = messages_pb.log_partner_data_touch_req()
		msg.touch_id = id

		xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
	end
end

return PartnerDataStation
