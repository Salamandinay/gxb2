local Slot = class("Slot", import("app.models.BaseModel"))
local Partner = import("app.models.Partner")
local json = require("cjson")
local Map = xyd.models.map
local PartnerTable = xyd.tables.partnerTable
local Backpack = xyd.models.backpack
local jobIds = {
	xyd.PartnerJob.WARRIOR,
	xyd.PartnerJob.MAGE,
	xyd.PartnerJob.RANGER,
	xyd.PartnerJob.ASSASSIN,
	xyd.PartnerJob.PRIEST
}

function Slot:ctor(...)
	Slot.super.ctor(self, ...)

	self.partners_ = {}
	self.sortedPartners_ = {}
	self.partnersByStar_ = {}
	self.isloaded = false
	self.collection_ = {}
	self.maxLovePoints = {}
	self.decomposeTimes = 0
	self.forgeList = {}
	self.forgeStatus = {}
	self.awakeMatStatusList = {}
	self.hasRefreshShenxue = false
	self.equipsOfPartner = {}
	self.isCollected = {}
	self.sortFuncList = {
		[xyd.partnerSortType.LEV] = handler(self, self.levSort),
		[xyd.partnerSortType.STAR] = handler(self, self.starSort),
		[xyd.partnerSortType.LOVE_POINT] = handler(self, self.lovePointSort),
		[xyd.partnerSortType.ATK] = handler(self, self.atkSort),
		[xyd.partnerSortType.HP] = handler(self, self.hpSort),
		[xyd.partnerSortType.ARM] = handler(self, self.armSort),
		[xyd.partnerSortType.SPD] = handler(self, self.spdSort),
		[xyd.partnerSortType.POWER] = handler(self, self.powerSort),
		[xyd.partnerSortType.isCollected] = handler(self, self.isCollectSort),
		[xyd.partnerSortType.SHENXUE] = handler(self, self.shenxueSort)
	}
end

function Slot:getData()
	if not self.isloaded then
		local msg = messages_pb.get_slot_info_req()

		xyd.Backend.get():request(xyd.mid.GET_SLOT_INFO, msg)
	end
end

function Slot:checkFiveStarPos()
	local partners = self.sortedPartners_[xyd.partnerSortType.SHENXUE .. "_0"]

	for pos in ipairs(partners) do
		local partnerId = partners[pos]
		local partner = self:getPartner(partnerId)

		if xyd.tables.partnerTable:getShenxueTableId(partner:getTableID()) and (partner:getStar() == 5 or partner:getStar() == 4) then
			return tonumber(pos)
		end
	end

	return -1
end

function Slot:checkDecomposeInvalid()
	if self:checkRefreshDecompose() then
		self.decomposeTimes = 0
		self.decomposeTimesTime = xyd.getServerTime()
	end
end

function Slot:checkRefreshDecompose()
	local hour = math.floor(self.decomposeTimesTime % xyd.DAY / xyd.HOUR)
	local nowHour = math.floor(xyd.getServerTime() % xyd.DAY / xyd.HOUR)
	local isSameDay = xyd.isSameDay(self.decomposeTimesTime, xyd.getServerTime(), true)
	local refreshHour = 8

	if hour < refreshHour then
		if refreshHour <= nowHour or not isSameDay then
			return true
		end
	elseif not isSameDay and refreshHour <= nowHour then
		return true
	end

	return false
end

function Slot:onGetData(event)
	local partners = event.data.partners or {}
	local details = event.data.details
	local collection = event.data.gallery

	if tonumber(details.decompose) then
		self.decomposeTimes = details.decompose
	end

	self.decomposeTimesTime = xyd.getServerTime()

	self:initCollection(collection)

	self.sortedPartners_[tostring(xyd.partnerSortType.LEV) .. "_0"] = {}
	self.sortedPartners_[tostring(xyd.partnerSortType.STAR) .. "_0"] = {}
	self.sortedPartners_[xyd.partnerSortType.PARTNER_ID] = {}
	self.sortedPartners_[tostring(xyd.partnerSortType.LOVE_POINT) .. "_0"] = {}
	self.sortedPartners_[tostring(xyd.partnerSortType.ATK) .. "_0"] = {}
	self.sortedPartners_[tostring(xyd.partnerSortType.HP) .. "_0"] = {}
	self.sortedPartners_[tostring(xyd.partnerSortType.ARM) .. "_0"] = {}
	self.sortedPartners_[tostring(xyd.partnerSortType.SPD) .. "_0"] = {}
	self.sortedPartners_[tostring(xyd.partnerSortType.SHENXUE) .. "_0"] = {}
	self.sortedPartners_[tostring(xyd.partnerSortType.POWER) .. "_0"] = {}
	self.sortedPartners_[tostring(xyd.partnerSortType.isCollected) .. "_0"] = {}
	local groupIds = xyd.tables.groupTable:getGroupIds()

	for i = 1, #groupIds do
		self.sortedPartners_[tostring(xyd.partnerSortType.LEV) .. "_" .. tostring(groupIds[i])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.STAR) .. "_" .. tostring(groupIds[i])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.LOVE_POINT) .. "_" .. tostring(groupIds[i])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.ATK) .. "_" .. tostring(groupIds[i])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.HP) .. "_" .. tostring(groupIds[i])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.ARM) .. "_" .. tostring(groupIds[i])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.SPD) .. "_" .. tostring(groupIds[i])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.SHENXUE) .. "_" .. tostring(groupIds[i])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.POWER) .. "_" .. tostring(groupIds[i])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.isCollected) .. "_" .. tostring(groupIds[i])] = {}

		for j = 1, #jobIds do
			self.sortedPartners_[tostring(xyd.partnerSortType.LEV) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])] = {}
			self.sortedPartners_[tostring(xyd.partnerSortType.STAR) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])] = {}
			self.sortedPartners_[tostring(xyd.partnerSortType.LOVE_POINT) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])] = {}
			self.sortedPartners_[tostring(xyd.partnerSortType.ATK) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])] = {}
			self.sortedPartners_[tostring(xyd.partnerSortType.HP) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])] = {}
			self.sortedPartners_[tostring(xyd.partnerSortType.ARM) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])] = {}
			self.sortedPartners_[tostring(xyd.partnerSortType.SPD) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])] = {}
			self.sortedPartners_[tostring(xyd.partnerSortType.SHENXUE) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])] = {}
			self.sortedPartners_[tostring(xyd.partnerSortType.POWER) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])] = {}
			self.sortedPartners_[tostring(xyd.partnerSortType.isCollected) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])] = {}
		end
	end

	for j = 1, #jobIds do
		self.sortedPartners_[tostring(xyd.partnerSortType.LEV) .. "_0_" .. tostring(jobIds[j])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.STAR) .. "_0_" .. tostring(jobIds[j])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.LOVE_POINT) .. "_0_" .. tostring(jobIds[j])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.ATK) .. "_0_" .. tostring(jobIds[j])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.HP) .. "_0_" .. tostring(jobIds[j])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.ARM) .. "_0_" .. tostring(jobIds[j])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.SPD) .. "_0_" .. tostring(jobIds[j])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.SHENXUE) .. "_0_" .. tostring(jobIds[j])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.POWER) .. "_0_" .. tostring(jobIds[j])] = {}
		self.sortedPartners_[tostring(xyd.partnerSortType.isCollected) .. "_0_" .. tostring(jobIds[j])] = {}
	end

	local mapInfo = Map:getMapInfo(xyd.MapType.CAMPAIGN)
	local maxStage = nil

	if mapInfo then
		maxStage = mapInfo.max_stage
	else
		maxStage = 0
	end

	for i = 1, #partners do
		if PartnerTable:hasId(partners[i].table_id) then
			local np = Partner.new()

			np:populate(partners[i])

			self.partners_[partners[i].partner_id] = np

			if maxStage <= 3 then
				table.insert(self.sortedPartners_[xyd.partnerSortType.PARTNER_ID], partners[i].partner_id)
			end

			local group = xyd.checkCondition(tonumber(np:getGroup()) == 0, 1, np:getGroup())
			local job = xyd.checkCondition(tonumber(np:getJob()) == 0, 1, np:getJob())

			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.LEV) .. "_0"], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.STAR) .. "_0"], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.LOVE_POINT) .. "_0"], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.ATK) .. "_0"], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.HP) .. "_0"], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.ARM) .. "_0"], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.SPD) .. "_0"], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.SHENXUE) .. "_0"], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.POWER) .. "_0"], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.isCollected) .. "_0"], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.LEV) .. "_" .. tostring(group)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.STAR) .. "_" .. tostring(group)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.LOVE_POINT) .. "_" .. tostring(group)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.ATK) .. "_" .. tostring(group)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.HP) .. "_" .. tostring(group)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.ARM) .. "_" .. tostring(group)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.SPD) .. "_" .. tostring(group)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.SHENXUE) .. "_" .. tostring(group)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.POWER) .. "_" .. tostring(group)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.isCollected) .. "_" .. tostring(group)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.LEV) .. "_0_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.STAR) .. "_0_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.LOVE_POINT) .. "_0_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.ATK) .. "_0_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.HP) .. "_0_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.ARM) .. "_0_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.SPD) .. "_0_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.SHENXUE) .. "_0_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.POWER) .. "_0_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.isCollected) .. "_0_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.LEV) .. "_" .. tostring(group) .. "_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.STAR) .. "_" .. tostring(group) .. "_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.LOVE_POINT) .. "_" .. tostring(group) .. "_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.ATK) .. "_" .. tostring(group) .. "_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.HP) .. "_" .. tostring(group) .. "_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.ARM) .. "_" .. tostring(group) .. "_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.SPD) .. "_" .. tostring(group) .. "_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.SHENXUE) .. "_" .. tostring(group) .. "_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.POWER) .. "_" .. tostring(group) .. "_" .. tostring(job)], partners[i].partner_id)
			table.insert(self.sortedPartners_[tostring(xyd.partnerSortType.isCollected) .. "_" .. tostring(group) .. "_" .. tostring(job)], partners[i].partner_id)
		end
	end

	self:refreshEquip()
	self:sortPartners()
	self:initAwakMatStatus()

	self.isloaded = true
	self.slotNum_ = details.max_num
	self.buySlotTimes_ = details.buy_times
	self.replaceTableID_ = details.replace_table_id
	self.replacePartner_ = details.replace_partner_id
end

function Slot:calSelfPower()
	local power = {
		0,
		0,
		0,
		0,
		0,
		0
	}

	for id in pairs(self.partners_) do
		local p = self.partners_[id]:getPower()

		if power[1] < p then
			power[1] = p

			table.sort(power, function (a, b)
				return a < b
			end)
		end
	end

	local result = 0

	for _, p in ipairs(power) do
		result = result + p
	end

	return result
end

function Slot:cal3v3Power()
	local power = {
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0
	}

	for id in pairs(self.partners_) do
		local p = self.partners_[id]:getPower()

		if power[1] < p then
			power[1] = p

			table.sort(power, function (a, b)
				return a < b
			end)
		end
	end

	local result = 0

	for _, p in ipairs(power) do
		result = result + p
	end

	return result
end

function Slot:initCollection(collections)
	local heroConf = xyd.tables.partnerTable
	local ids = heroConf:getIds()
	local idx = 1
	local heroIds = {}
	local collection = {}
	local puppetCollect = {}

	table.sort(collections, function (a, b)
		return a < b
	end)

	for i = 1, #ids do
		if not xyd.tables.partnerTable:checkPuppetPartner(ids[i]) then
			table.insert(heroIds, ids[i])
		end
	end

	for i = 1, #collections do
		if not xyd.tables.partnerTable:checkPuppetPartner(collections[i]) then
			table.insert(collection, collections[i])
		else
			puppetCollect[tostring(collections[i])] = true
		end
	end

	for _, id in pairs(heroIds) do
		local showInGuide = heroConf:getShowInGuide(id)

		if xyd.Global.isReview ~= 1 and showInGuide >= 1 and showInGuide < xyd:getServerTime() then
			if tonumber(id) == collection[idx] then
				self.collection_[id] = true
				idx = idx + 1
			else
				self.collection_[id] = false
			end
		elseif xyd.Global.isReview == 1 and heroConf:getShowInReviewGuide(id) == 1 then
			if tonumber(id) == collection[idx] then
				self.collection_[id] = true
				idx = idx + 1
			else
				self.collection_[id] = false
			end
		end
	end

	self.puppetCollect_ = puppetCollect
end

function Slot:sortPartners()
	local groupIds = xyd.tables.groupTable:getGroupIds()

	local function levSort(a, b)
		local weight_a = self.partners_[a].lev * 100 + self.partners_[a].star * 10 + self.partners_[a]:getGroup()
		local weight_b = self.partners_[b].lev * 100 + self.partners_[b].star * 10 + self.partners_[b]:getGroup()

		if weight_a - weight_b ~= 0 then
			return weight_b < weight_a
		elseif self.partners_[a]:getTableID() == self.partners_[b]:getTableID() then
			return b < a
		else
			return self.partners_[a]:getTableID() < self.partners_[b]:getTableID()
		end
	end

	local function starSort(a, b)
		local weight_a = self.partners_[a].star * 10000 + self.partners_[a].lev * 10 + self.partners_[a]:getGroup()
		local weight_b = self.partners_[b].star * 10000 + self.partners_[b].lev * 10 + self.partners_[b]:getGroup()

		if weight_a - weight_b ~= 0 then
			return weight_b < weight_a
		elseif self.partners_[a]:getTableID() == self.partners_[b]:getTableID() then
			return b < a
		else
			return self.partners_[a]:getTableID() < self.partners_[b]:getTableID()
		end
	end

	local function lovePointSort(a, b)
		local weight_a = self.partners_[a].love_point * 1000 + self.partners_[a].lev * 100 + self.partners_[a].star * 10 + self.partners_[a]:getGroup()
		local weight_b = self.partners_[b].love_point * 1000 + self.partners_[b].lev * 100 + self.partners_[b].star * 10 + self.partners_[b]:getGroup()

		if weight_a - weight_b ~= 0 then
			return weight_b < weight_a
		elseif self.partners_[a]:getTableID() == self.partners_[b]:getTableID() then
			return b < a
		else
			return self.partners_[a]:getTableID() < self.partners_[b]:getTableID()
		end
	end

	local function getKeyAttr(type, partner_id)
		local attr = 0

		if type == 0 then
			attr = self:getPartner(partner_id):getBattleAttrs().atk
		elseif type == 1 then
			attr = self:getPartner(partner_id):getBattleAttrs().hp
		elseif type == 2 then
			attr = self:getPartner(partner_id):getBattleAttrs().arm
		elseif type == 3 then
			attr = self:getPartner(partner_id):getBattleAttrs().spd
		end

		return attr
	end

	local function atkSort(a, b)
		local key_a = getKeyAttr(0, a)
		local key_b = getKeyAttr(0, b)

		if key_a ~= key_b then
			return key_b < key_a
		else
			local partner_a = self:getPartner(a)
			local partner_b = self:getPartner(b)

			if partner_a:getStar() ~= partner_b:getStar() then
				return partner_b:getStar() < partner_a:getStar()
			elseif partner_a:getLevel() ~= partner_b:getLevel() then
				return partner_b:getLevel() < partner_a:getLevel()
			elseif self.partners_[a]:getTableID() == self.partners_[b]:getTableID() then
				return b < a
			else
				return self.partners_[a]:getTableID() < self.partners_[b]:getTableID()
			end
		end
	end

	local function hpSort(a, b)
		local key_a = getKeyAttr(1, a)
		local key_b = getKeyAttr(1, b)

		if key_a ~= key_b then
			return key_b < key_a
		else
			local partner_a = self:getPartner(a)
			local partner_b = self:getPartner(b)

			if partner_a:getStar() ~= partner_b:getStar() then
				return partner_b:getStar() < partner_a:getStar()
			elseif partner_a:getLevel() ~= partner_b:getLevel() then
				return partner_b:getLevel() < partner_a:getLevel()
			elseif self.partners_[a]:getTableID() == self.partners_[b]:getTableID() then
				return b < a
			else
				return self.partners_[a]:getTableID() < self.partners_[b]:getTableID()
			end
		end
	end

	local function armSort(a, b)
		local key_a = getKeyAttr(2, a)
		local key_b = getKeyAttr(2, b)

		if key_a ~= key_b then
			return key_b < key_a
		else
			local partner_a = self:getPartner(a)
			local partner_b = self:getPartner(b)

			if partner_a:getStar() ~= partner_b:getStar() then
				return partner_b:getStar() < partner_a:getStar()
			elseif partner_a:getLevel() ~= partner_b:getLevel() then
				return partner_b:getLevel() < partner_a:getLevel()
			elseif self.partners_[a]:getTableID() == self.partners_[b]:getTableID() then
				return b < a
			else
				return self.partners_[a]:getTableID() < self.partners_[b]:getTableID()
			end
		end
	end

	local function spdSort(a, b)
		local key_a = getKeyAttr(3, a)
		local key_b = getKeyAttr(3, b)

		if key_a ~= key_b then
			return key_b < key_a
		else
			local partner_a = self:getPartner(a)
			local partner_b = self:getPartner(b)

			if partner_a:getStar() ~= partner_b:getStar() then
				return partner_b:getStar() < partner_a:getStar()
			elseif partner_a:getLevel() ~= partner_b:getLevel() then
				return partner_b:getLevel() < partner_a:getLevel()
			elseif self.partners_[a]:getTableID() == self.partners_[b]:getTableID() then
				return b < a
			else
				return self.partners_[a]:getTableID() < self.partners_[b]:getTableID()
			end
		end
	end

	local function isCollectSort(a, b)
		local partner_a = self:getPartner(a)
		local partner_b = self:getPartner(b)
		local key_a = partner_a:isCollected() and 1 or 0
		local key_b = partner_b:isCollected() and 1 or 0

		if key_a == key_b then
			return levSort(a, b)
		end

		return key_b < key_a
	end

	local function powerSort(a, b)
		return self.partners_[b]:getPower() < self.partners_[a]:getPower()
	end

	if self.firstInitInsetArr == nil then
		self.insertFunArr = {
			[xyd.partnerSortType.LEV] = levSort,
			[xyd.partnerSortType.STAR] = starSort,
			[xyd.partnerSortType.LOVE_POINT] = lovePointSort,
			[xyd.partnerSortType.ATK] = atkSort,
			[xyd.partnerSortType.HP] = hpSort,
			[xyd.partnerSortType.ARM] = armSort,
			[xyd.partnerSortType.SPD] = spdSort,
			[xyd.partnerSortType.SHENXUE] = handler(self, self.shenxueSort),
			[xyd.partnerSortType.POWER] = powerSort,
			[xyd.partnerSortType.isCollected] = isCollectSort
		}
	end

	table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.LEV) .. "_0"], levSort)
	table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.STAR) .. "_0"], starSort)
	table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.LOVE_POINT) .. "_0"], lovePointSort)
	table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.ATK) .. "_0"], atkSort)
	table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.HP) .. "_0"], hpSort)
	table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.ARM) .. "_0"], armSort)
	table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.SPD) .. "_0"], spdSort)
	table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.POWER) .. "_0"], powerSort)
	table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.isCollected) .. "_0"], isCollectSort)

	for i = 1, #groupIds do
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.LEV) .. "_" .. tostring(groupIds[i])], levSort)
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.STAR) .. "_" .. tostring(groupIds[i])], starSort)
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.LOVE_POINT) .. "_" .. tostring(groupIds[i])], lovePointSort)
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.ATK) .. "_" .. tostring(groupIds[i])], atkSort)
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.HP) .. "_" .. tostring(groupIds[i])], hpSort)
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.ARM) .. "_" .. tostring(groupIds[i])], armSort)
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.SPD) .. "_" .. tostring(groupIds[i])], spdSort)
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.POWER) .. "_" .. tostring(groupIds[i])], powerSort)
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.isCollected) .. "_" .. tostring(groupIds[i])], isCollectSort)

		for j = 1, #jobIds do
			table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.LEV) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])], levSort)
			table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.STAR) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])], starSort)
			table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.LOVE_POINT) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])], lovePointSort)
			table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.ATK) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])], atkSort)
			table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.HP) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])], hpSort)
			table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.ARM) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])], armSort)
			table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.SPD) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])], spdSort)
			table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.POWER) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])], powerSort)
			table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.isCollected) .. "_" .. tostring(groupIds[i]) .. "_" .. tostring(jobIds[j])], isCollectSort)
		end
	end

	for j = 1, #jobIds do
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.LEV) .. "_0_" .. tostring(jobIds[j])], levSort)
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.STAR) .. "_0_" .. tostring(jobIds[j])], starSort)
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.LOVE_POINT) .. "_0_" .. tostring(jobIds[j])], lovePointSort)
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.ATK) .. "_0_" .. tostring(jobIds[j])], atkSort)
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.HP) .. "_0_" .. tostring(jobIds[j])], hpSort)
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.ARM) .. "_0_" .. tostring(jobIds[j])], armSort)
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.SPD) .. "_0_" .. tostring(jobIds[j])], spdSort)
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.POWER) .. "_0_" .. tostring(jobIds[j])], powerSort)
		table.sort(self.sortedPartners_[tostring(xyd.partnerSortType.isCollected) .. "_0_" .. tostring(jobIds[j])], isCollectSort)
	end

	local function sortForAltar(a, b)
		local weight_a = self.partners_[a].star * 10000 + self.partners_[a].lev * 1000 + self.partners_[a]:getGroup()
		local weight_b = self.partners_[b].star * 10000 + self.partners_[b].lev * 1000 + self.partners_[b]:getGroup()

		if self.partners_[a]:isLockFlag() and not self.partners_[b]:isLockFlag() then
			return true
		elseif not self.partners_[a]:isLockFlag() and self.partners_[b]:isLockFlag() then
			return false
		end

		if weight_a - weight_b ~= 0 then
			return weight_b < weight_a
		else
			return self.partners_[b]:getTableID() < self.partners_[a]:getTableID()
		end
	end

	self.sortForAltar = sortForAltar

	for k = 0, xyd.MAX_PARTNER_STAR_NUM do
		self.partnersByStar_[tostring(k) .. "_0"] = {}

		for i = 1, #groupIds do
			self.partnersByStar_[tostring(k) .. "_" .. tostring(groupIds[i])] = {}
		end
	end

	local partners = {}

	for i = 1, #self.sortedPartners_[tostring(xyd.partnerSortType.STAR) .. "_0"] do
		local p = self.sortedPartners_[tostring(xyd.partnerSortType.STAR) .. "_0"][i]

		table.insert(partners, p)
	end

	table.sort(partners, sortForAltar)

	local lockPartners = {}

	for i = #partners, 1, -1 do
		local id = partners[i]
		local p = self.partners_[id]

		if p:isLockFlag() then
			table.insert(lockPartners, p)
		else
			table.insert(self.partnersByStar_["0_0"], id)
			table.insert(self.partnersByStar_["0_" .. tostring(p:getGroup())], id)

			if p.star <= xyd.MAX_PARTNER_STAR_NUM then
				table.insert(self.partnersByStar_[tostring(p.star) .. "_0"], id)
				table.insert(self.partnersByStar_[tostring(p.star) .. "_" .. tostring(p:getGroup())], id)
			end
		end
	end

	for _, p in pairs(lockPartners) do
		local id = p:getPartnerID()

		table.insert(self.partnersByStar_["0_0"], id)
		table.insert(self.partnersByStar_["0_" .. tostring(p:getGroup())], id)

		if p.star <= 5 then
			table.insert(self.partnersByStar_[tostring(p.star) .. "_0"], id)
			table.insert(self.partnersByStar_[tostring(p.star) .. "_" .. tostring(p:getGroup())], id)
		end
	end

	self:initShenxueSort()
end

function Slot:onRegister()
	Slot.super.onRegister(self)
	self:registerEvent(xyd.event.ROLLBACK_PARTNER, handler(self, self.onRollBackPartner))
	self:registerEvent(xyd.event.SUMMON, handler(self, self.onUpdateSummonPartners))
	self:registerEvent(xyd.event.SUMMON_WISH, handler(self, self.onUpdateSummonPartners))
	self:registerEvent(xyd.event.NEWBEE_SUMMON, handler(self, self.onUpdateSummonPartners))
	self:registerEvent(xyd.event.BUY_SLOT, handler(self, self.onUpdateSlot))
	self:registerEvent(xyd.event.VIP_CHANGE, handler(self, self.onUpdateSlot))
	self:registerEvent(xyd.event.GET_SLOT_INFO, handler(self, self.onGetData))
	self:registerEvent(xyd.event.DECOMPOSE_PARTNERS, handler(self, self.onDecomposePartners))
	self:registerEvent(xyd.event.PROPHET_REPLACE, handler(self, self.onReplacePartner))
	self:registerEvent(xyd.event.PROPHET_REPLACE_SAVE, handler(self, self.onReplacePartnerSave))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onChristmasExchange))
	self:registerEvent(xyd.event.REPLACE_10_STAR, handler(self, self.onTenStarReplace))
	self:registerEvent(xyd.event.SUIT_SKILL, handler(self, self.onChangeSuitSkill))
	self:registerEvent(xyd.event.PARTNER_LEVUP, function (self, event)
		self:onPartnerUpdate(event)
		self:checkPromotablePartner()
	end, self)
	self:registerEvent(xyd.event.PARTNER_GRADEUP, function (self, event)
		self:onPartnerUpdate(event)
		self:checkPromotablePartner()
	end, self)
	self:registerEvent(xyd.event.PARTNER_ONE_CLICK_UP, function (self, event)
		self:onPartnerUpdate(event)
		self:checkPromotablePartner()
	end, self)
	self:registerEvent(xyd.event.AWAKE_PARTNER, handler(self, function (self, event)
		self:onPartnerUpdate(event)
		self:onAwakePartner(event)
		self:checkPromotablePartner()
	end))
	self:registerEvent(xyd.event.ROB_PARTNER_EQUIP, handler(self, function (self, event)
		local function callback(table_id, changed_attr_show, partner_id)
			local flag = false

			for key, _ in pairs(changed_attr_show) do
				if changed_attr_show[key] > 0 then
					flag = true

					break
				end
			end

			if not flag then
				return
			end

			local ind = math.floor(math.random() * 2) + 1
			local partnerInfo = self:getPartner(partner_id)
			local dialog = xyd.tables.partnerTable:getEquipDialogInfo(table_id, ind, partnerInfo:getSkinID())
			local win = xyd.WindowManager.get():getWindow("partner_detail_window")

			if win then
				win:playSound(dialog)
			end
		end

		self:onRobPartnerUpdate(event, callback)
	end))
	self:registerEvent(xyd.event.EQUIP, handler(self, function (self, event)
		local function callback(table_id, changed_attr_show, partner_id)
			local flag = false

			for key, _ in pairs(changed_attr_show) do
				if changed_attr_show[key] > 0 then
					flag = true

					break
				end
			end

			if not flag then
				return
			end

			local ind = math.floor(math.random() * 2) + 1
			local partnerInfo = self:getPartner(partner_id)
			local dialog = xyd.tables.partnerTable:getEquipDialogInfo(table_id, ind, partnerInfo:getSkinID())
			local win = xyd.WindowManager.get():getWindow("partner_detail_window")

			if win then
				win:playSound(dialog)
			end
		end

		self:onPartnerUpdate(event, callback)
		self:onEquip(event)
		xyd.models.backpack:checkAvailableEquipment()
	end))
	self:registerEvent(xyd.event.TREASURE_ON, handler(self, function (self, event)
		self:onPartnerUpdate(event)
	end))
	self:registerEvent(xyd.event.TREASURE_REFRESH, handler(self, function (self, event)
		local partner_id = event.data.partner_id
		self.partners_[partner_id].tmp_treasure_ = event.data.tmp_treasure
	end))
	self:registerEvent(xyd.event.TREASURE_SAVE, handler(self, function (self, event)
		local partner_id = event.data.partner_info.partner_id

		self.partners_[partner_id]:updateTreasures(event.data.partner_info.treasures)
		self:onPartnerUpdate(event)
		self:clearSaveTmpTreasure(self.partners_[event.data.partner_info.partner_id])
	end))
	self:registerEvent(xyd.event.TREASURE_UPGRADE, handler(self, function (self, event)
		self.partners_[event.data.partner_info.partner_id]:updateTreasures(event.data.partner_info.treasures)
		self:onPartnerUpdate(event)
		self:clearSaveTmpTreasure(self.partners_[event.data.partner_info.partner_id])
	end))
	self:registerEvent(xyd.event.TREASURE_UNLOCK, handler(self, function (self, event)
		local partner_id = event.data.partner_id

		self.partners_[partner_id]:updateTreasures(event.data.treasures)
	end))
	self:registerEvent(xyd.event.TREASURE_SELECT, handler(self, function (self, event)
		local index = event.data.index
		local partner_id = event.data.partner_id
		self.partners_[partner_id].select_treasure = index
		self.partners_[partner_id].equipments[xyd.EquipPos.TREASURE] = self.partners_[partner_id].treasures[index]
	end))
	self:registerEvent(xyd.event.TREASURE_DEL, handler(self, function (self, event)
		local partner_id = event.data.partner_info.partner_id

		self.partners_[partner_id]:updateTreasures(event.data.partner_info.treasures)
	end))
	self:registerEvent(xyd.event.TREASURE_RETURN, handler(self, function (self, event)
		local partner_id = event.data.partner_info.partner_id

		self.partners_[partner_id]:updateTreasures(event.data.partner_info.treasures)
		self:onPartnerUpdate(event)
		self:clearSaveTmpTreasure(self.partners_[event.data.partner_info.partner_id])
	end))
	self:registerEvent(xyd.event.EDIT_POTENTIALS_BAK, handler(self, function (self, event)
		local partner_id = event.data.partner_info.partner_id
		self.partners_[partner_id].potentials_bak = event.data.partner_info.potentials_bak
	end))
	self:registerEvent(xyd.event.SET_POTENTIALS_BAK, handler(self, self.onSwitchPotentialBak))
	self:registerEvent(xyd.event.ARTIFACT_UPGRADE, handler(self, function (self, event)
		self:onPartnerUpdate(event)
	end))
	self:registerEvent(xyd.event.LOCK_PARTNER, handler(self, function (self, event)
		self:onPartnerUpdate(event)
	end))
	self:registerEvent(xyd.event.SET_SHOW_ID, handler(self, function (self, event)
		local partner_info = event.data.partner_info
		local partner_id = partner_info.partner_id

		self.partners_[partner_id]:setShowID(partner_info.show_id)
	end))
	self:registerEvent(xyd.event.COMPOSE_PARTNER, handler(self, self.onComposePartner))
	self:registerEvent(xyd.event.SHOW_SKIN, handler(self, self.onShowSkin))
	self:registerEvent(xyd.event.SEND_GIFT, handler(self, self.onSendGifts))
	self:registerEvent(xyd.event.GET_MAX_LOVE_POINT, handler(self, self.onMaxLovePoint))
	self:registerEvent(xyd.event.EDIT_PLAYER_PICTURE, handler(self, function (self, event)
		self:onEditPartnerUpdate(event.data.partners_info)
	end))
	self:registerEvent(xyd.event.LOAD_PARTNER_LOVE_POINT, handler(self, function (self, event)
		self:onEditPartnerUpdate(event.data.love_point_info)
	end))
	self:registerEvent(xyd.event.VOW, handler(self, self.onPartnerVow))
	self:registerEvent(xyd.event.CHOOSE_PARTNER_POTENTIAL, handler(self, self.onChoosePotential))
end

function Slot:onUpdateSummonPartners(event)
	local partners = {}

	if event.data.summon_result then
		partners = event.data.summon_result.partners or {}
	elseif event.data.partners then
		partners = event.data.partners
	end

	local star4 = 0
	local star5 = 0

	self:addPartners(partners)
	self:initAwakMatStatus()
	self:checkPromotablePartner()

	self.puppetPartner_ = nil
end

function Slot:addPartners(partners)
	local star4 = 0
	local star5 = 0
	local groupList = {}

	for i = 1, #partners do
		self:addPartner(partners[i])

		local star = PartnerTable:getStar(partners[i].table_id)

		if star and star == 4 then
			star4 = star4 + 1
		elseif star and star == 5 then
			star5 = star5 + 1
		end

		local np = Partner.new()

		np:populate(partners[i])

		local groupId = np:getGroup()

		if not groupList[groupId] then
			groupList[groupId] = 1
		end

		self:checkDaDian(partners[i])

		if xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_TIME_PARTNER) then
			local id = xyd.tables.miscTable:getVal("activity_time_partner_id")

			if partners[i].table_id == tonumber(id) then
				xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_TIME_PARTNER)
			end
		end
	end

	for k in pairs(groupList) do
		if tonumber(groupList[k]) == 1 then
			local groupId = tonumber(k)

			self:refreshShenxueGroup(groupId)
		end
	end

	if star4 > 0 then
		xyd.models.advertiseComplete:achieve(xyd.ACHIEVEMENT_TYPE.GET_STAR4_HERO, star4)
	end

	if star5 > 0 then
		xyd.models.advertiseComplete:achieve(xyd.ACHIEVEMENT_TYPE.GET_STAR5_HERO, star5)
	end
end

function Slot:checkDaDian(partnerInfo)
	local np = Partner.new()

	np:populate(partnerInfo)
	xyd.models.achievement:checkDaDian(np)
end

function Slot:addPartner(partnerInfo)
	local np = Partner.new()

	np:populate(partnerInfo)

	local mapInfo = Map:getMapInfo(xyd.MapType.CAMPAIGN)
	local maxStage = mapInfo.max_stage

	if maxStage <= 3 then
		table.insert(self.sortedPartners_[xyd.partnerSortType.PARTNER_ID], np:getPartnerID())
	end

	self.partners_[np:getPartnerID()] = np
	local addSortTypeArr = {
		xyd.partnerSortType.LEV,
		xyd.partnerSortType.STAR,
		xyd.partnerSortType.LOVE_POINT,
		xyd.partnerSortType.ATK,
		xyd.partnerSortType.HP,
		xyd.partnerSortType.ARM,
		xyd.partnerSortType.SPD,
		xyd.partnerSortType.SHENXUE,
		xyd.partnerSortType.POWER,
		xyd.partnerSortType.isCollected
	}
	local keyNameArr = {
		"_0",
		"_" .. tostring(np:getGroup()),
		"_" .. tostring(np:getGroup()) .. "_" .. tostring(np:getJob()),
		"_0_" .. tostring(np:getJob())
	}

	for k in pairs(keyNameArr) do
		for j, typeName in pairs(addSortTypeArr) do
			if typeName ~= xyd.partnerSortType.PARTNER_ID and typeName ~= xyd.partnerSortType.SHENXUE then
				local typeNameStr = tostring(typeName)
				local insertFun = self.insertFunArr[typeName]

				if #self.sortedPartners_[typeNameStr .. keyNameArr[k]] == 0 or insertFun(np:getPartnerID(), self.sortedPartners_[typeNameStr .. keyNameArr[k]][1]) then
					table.insert(self.sortedPartners_[typeNameStr .. keyNameArr[k]], 1, np:getPartnerID())
				else
					local isInsert = false

					for i, v in pairs(self.sortedPartners_[typeNameStr .. keyNameArr[k]]) do
						if insertFun(np:getPartnerID(), self.sortedPartners_[typeNameStr .. keyNameArr[k]][i]) then
							table.insert(self.sortedPartners_[typeNameStr .. keyNameArr[k]], i, np:getPartnerID())

							isInsert = true

							break
						end
					end

					if isInsert == false then
						table.insert(self.sortedPartners_[typeNameStr .. keyNameArr[k]], np:getPartnerID())
					end
				end
			end

			if typeName == xyd.partnerSortType.SHENXUE then
				local typeNameStr = tostring(typeName)

				table.insert(self.sortedPartners_[typeNameStr .. keyNameArr[k]], np:getPartnerID())
			end
		end
	end

	self:addAltarPartner(np)

	if not self.collection_[np:getTableID()] then
		self.collection_[np:getTableID()] = true

		if np:getStar() == 5 then
			local redParams = xyd.models.redMark:getRedMarkParams(xyd.RedMarkType.NEW_FIVE_STAR) or {}

			if not redParams.npList then
				redParams.npList = {}
			end

			table.insert(redParams.npList, tonumber(np:getPartnerID()))
			xyd.models.redMark:setMark(xyd.RedMarkType.NEW_FIVE_STAR, true, redParams)
		end
	end

	local eventObj = {
		name = xyd.event.PARTNER_ADD,
		data = {
			partnerID = np:getPartnerID(),
			tableID = np:getTableID()
		}
	}

	xyd.EventDispatcher:outer():dispatchEvent(eventObj)
	self:refreshEquip()
	self:initShenxueSort()
end

function Slot:onRobPartnerUpdate(event, callback)
	local params = event.data.target_partner_info

	if params then
		params = params.partner_info
		local partner_info = {
			tableID = params.table_id,
			equipments = params.equips,
			partnerID = params.partner_id
		}

		if not partner_info.partnerID then
			return
		end

		local changed_attr = self.partners_[partner_info.partnerID]:updateAttrs(partner_info)

		if params.skill_index then
			self.partners_[partner_info.partnerID].skill_index = params.skill_index
		end

		local changed_attr_show = {}

		for key in pairs(changed_attr) do
			if xyd.tables.dBuffTable:isAttr(key) and xyd.tables.dBuffTable:isAttr(key) > 0 then
				changed_attr_show[key] = changed_attr[key]
			end
		end

		local eventObj = {
			name = xyd.event.PARTNER_ATTR_CHANGE,
			data = {
				partnerID = partner_info.partnerID,
				changed_attr = changed_attr_show
			}
		}

		xyd.EventDispatcher:inner():dispatchEvent(eventObj)

		if callback then
			callback(partner_info.tableID, changed_attr_show, partner_info.partnerID)
		end
	end

	params = event.data.from_partner_info.partner_info
	local partner_info_1 = {
		tableID = params.table_id,
		equipments = params.equips,
		partnerID = params.partner_id
	}

	if not partner_info_1.partnerID then
		return
	end

	self.partners_[partner_info_1.partnerID]:updateAttrs(partner_info_1)

	if params.skill_index then
		self.partners_[partner_info_1.partnerID].skill_index = params.skill_index
	end
end

function Slot:onPartnerUpdate(event, callback)
	local params = event.data.partner_info
	local partner_info = {
		isLevingUp = false,
		tableID = params.table_id,
		star = params.star,
		lev = params.lv,
		partnerID = params.partner_id,
		grade = params.grade,
		awake = params.awake,
		showID = params.show_id
	}

	if params.skill_index and tonumber(params.skill_index) then
		partner_info.skill_index = params.skill_index
	end

	partner_info.lockFlags = {}

	for _, flag in ipairs(params.flags or {}) do
		table.insert(partner_info.lockFlags, flag)
	end

	if params.equips then
		partner_info.equipments = {}

		for k, v in ipairs(params.equips) do
			partner_info.equipments[k] = v
		end
	end

	if not partner_info.partnerID then
		return
	end

	local changed_attr = self.partners_[partner_info.partnerID]:updateAttrs(partner_info)
	local changed_attr_show = {}

	for key in pairs(changed_attr) do
		if xyd.tables.dBuffTable:isAttr(key) and xyd.tables.dBuffTable:isAttr(key) > 0 then
			changed_attr_show[key] = changed_attr[key]
		end
	end

	local eventObj = {
		name = xyd.event.PARTNER_ATTR_CHANGE,
		data = {
			partnerID = partner_info.partnerID,
			changed_attr = changed_attr_show
		}
	}

	xyd.EventDispatcher:inner():dispatchEvent(eventObj)

	if params.equips then
		self:refreshEquip()
	end

	if callback then
		callback(partner_info.tableID, changed_attr_show, partner_info.partnerID)
	end
end

function Slot:onEditPartnerUpdate(datas)
	if not datas then
		return
	end

	for i = 1, #datas do
		local params = datas[i]
		local partner_info = {
			partnerID = params.partner_id,
			lockFlags = #params.flags > 0 and params.flags or nil,
			love_point = params.love_point,
			last_love_point_time = params.last_love_point_time,
			guaji_love_point = params.guaji_love_point,
			is_vowed = params.is_vowed
		}

		if not partner_info.partnerID then
			return
		end

		local changed_attr = self.partners_[partner_info.partnerID]:updateAttrs(partner_info)
	end
end

function Slot:onDecomposePartners(event)
	local partners = event.data.partner_ids

	self:delPartners(partners)
	self:initAwakMatStatus()
end

function Slot:onReplacePartner(event)
	self.replacePartner_ = event.data.partner_id
	self.replaceTableID_ = event.data.replace_id
end

function Slot:onChristmasExchange(event)
	local data = event.data

	if data.activity_id == xyd.ActivityID.ACTIVITY_CHRISTMAS_EXCHANGE then
		local detail = json.decode(data.detail)

		if detail.partner_id and detail.partner_id ~= 0 then
			local partnerID = detail.partner_id
			local newPartnerTableID = detail.award_id
			local partner = self.partners_[partnerID]
			local oldPinfo = partner:getInfo()

			self:delPartners({
				partnerID
			})

			oldPinfo.tableID = newPartnerTableID
			oldPinfo.is_vowed = 0
			oldPinfo.love_point = 0
			oldPinfo.wedding_date = 0
			oldPinfo.equipments[7] = 0

			self:addPartners({
				oldPinfo
			})
		end
	end
end

function Slot:deletePartner(partnerID)
	self:delPartners({
		partnerID
	})
end

function Slot:onTenStarReplace(event)
	local data = event.data
	local oldPartner = self:getPartner(data.partner_id)
	local oldPinfo = oldPartner:getInfo()

	for i = 1, #data.material_ids do
		self:deletePartner(data.material_ids[i])
	end

	self:deletePartner(data.partner_id)

	local newTableId = data.replace_table_id
	oldPinfo.tableID = newTableId
	oldPinfo.is_vowed = data.is_vowed
	oldPinfo.love_point = data.love_point
	oldPinfo.wedding_date = data.wedding_date
	oldPinfo.equipments[7] = 0
	oldPinfo.potentials = {
		0,
		0,
		0,
		0,
		0
	}

	self:addPartners({
		oldPinfo
	})
	self:initAwakMatStatus()
end

function Slot:onReplacePartnerSave(event)
	local data = event.data
	local replace_id = data.replace_id
	local partner_id = data.partner_id
	local is_save = data.is_save
	self.replacePartner_ = nil
	self.replaceTableID_ = nil

	if is_save and is_save == 1 then
		local oldPartner = self.partners_[partner_id]
		local oldPinfo = oldPartner:getInfo()

		self:delPartners({
			partner_id
		})

		oldPinfo.tableID = replace_id
		oldPinfo.is_vowed = data.is_vowed
		oldPinfo.love_point = data.love_point
		oldPinfo.wedding_date = data.wedding_date
		oldPinfo.equipments[7] = 0

		self:addPartners({
			oldPinfo
		})
	end
end

function Slot:onAwakePartner(event)
	local partners = event.data.material_ids

	self:delPartners(partners)
	xyd.EventDispatcher:inner():dispatchEvent({
		name = xyd.event.AWAKE_PARTNER_FINISH,
		data = event.data
	})

	if not self.collection_[event.data.partner_info.table_id] then
		self.collection_[event.data.partner_info.table_id] = true
	end

	local partnerID = event.data.partner_info.partner_id

	if not partnerID then
		return
	end

	local p = self:getPartner(partnerID)

	p:displayChange()
	self:initAwakMatStatus()
end

function Slot:onEquip(event)
	local partnerID = event.data.partner_info.partner_id

	if not partnerID then
		return
	end

	local p = self:getPartner(partnerID)

	p:displayChange()
end

function Slot:delPartners(partnerIDs)
	local groupList = {}

	for i = 1, #partnerIDs do
		local partnerID = partnerIDs[i]
		local np = self.partners_[partnerID]
		local groupId = np:getGroup()

		if not groupList[groupId] then
			groupList[groupId] = 1
		end

		self:delPartner(partnerID)
	end

	for k in pairs(groupList) do
		if tonumber(groupList[k]) == 1 then
			local groupId = tonumber(k)

			self:refreshShenxueGroup(groupId)
		end
	end
end

function Slot:delPartner(partnerID)
	local hero = self.partners_[partnerID]

	local function removePartner(tb, id)
		for k, v in pairs(tb) do
			if tonumber(v) == tonumber(id) then
				table.remove(tb, k)

				break
			end
		end
	end

	if hero ~= nil and hero ~= nil then
		self.partners_[partnerID] = nil

		for _, type in pairs(xyd.partnerSortType) do
			if type == xyd.partnerSortType.PARTNER_ID then
				removePartner(self.sortedPartners_[xyd.partnerSortType.PARTNER_ID], partnerID)
			end

			if self.sortedPartners_[type .. "_0"] then
				removePartner(self.sortedPartners_[type .. "_0"], partnerID)
			end

			if self.sortedPartners_[type .. "_" .. hero:getGroup()] then
				removePartner(self.sortedPartners_[type .. "_" .. hero:getGroup()], partnerID)
			end

			if self.sortedPartners_[type .. "_0_" .. hero:getJob()] then
				removePartner(self.sortedPartners_[type .. "_0_" .. hero:getJob()], partnerID)
			end

			if self.sortedPartners_[type .. "_" .. hero:getGroup() .. "_" .. hero:getJob()] then
				removePartner(self.sortedPartners_[type .. "_" .. hero:getGroup() .. "_" .. hero:getJob()], partnerID)
			end
		end

		removePartner(self.partnersByStar_["0_0"], partnerID)
		removePartner(self.partnersByStar_["0_" .. tostring(hero:getGroup())], partnerID)

		if hero:getStar() <= xyd.MAX_PARTNER_STAR_NUM then
			removePartner(self.partnersByStar_[tostring(hero:getStar()) .. "_" .. tostring(hero:getGroup())], partnerID)
			removePartner(self.partnersByStar_[tostring(hero:getStar()) .. "_0"], partnerID)
		end

		if hero:getStar() == 5 then
			local redParams = xyd.models.redMark:getRedMarkParams(xyd.RedMarkType.NEW_FIVE_STAR) or {}
			local npList = redParams.npList or {}
			local pIndex = xyd.arrayIndexOf(npList, tonumber(hero:getPartnerID()))

			if pIndex > -1 then
				table.remove(npList, pIndex)
			end

			redParams.npList = npList
			local hasNew = xyd.checkCondition(#npList > 0, true, false)

			xyd.models.redMark:setMark(xyd.RedMarkType.NEW_FIVE_STAR, hasNew, redParams)
		end

		xyd.EventDispatcher:outer():dispatchEvent({
			name = xyd.event.PARTNER_DEL,
			data = {
				partnerID = partnerID,
				tableID = hero:getTableID()
			}
		})
	end

	self:refreshEquip()
end

function Slot:onComposePartner(event)
	local params = event.data

	self:delPartners(params.material_ids)
	self:addPartners({
		params.partner_info
	})
	self:initAwakMatStatus()

	if params.partner_info.star == 5 then
		xyd.models.advertiseComplete:achieve(xyd.ACHIEVEMENT_TYPE.GET_STAR5_HERO, 1)
	end
end

function Slot:onUpdateSlot(event)
	local eventName = string.lower(event.name)

	if eventName == xyd.event.BUY_SLOT then
		self.slotNum_ = self.slotNum_ + tonumber(xyd.tables.miscTable:getVal("herobag_buy_num"))
		self.buySlotTimes_ = self.buySlotTimes_ + 1
	end

	if eventName == xyd.event.VIP_CHANGE then
		local vip = Backpack:getVipLev()
		self.slotNum_ = xyd.tables.vipTable:getSlotBase(vip) + self.buySlotTimes_ * tonumber(xyd.tables.miscTable:getVal("herobag_buy_num"))
	end
end

function Slot:dressAddSlotNum(num)
	self.slotNum_ = self.slotNum_ + num
end

function Slot:changeSuitSkill(partner_id, index)
	local msg = messages_pb.suit_skill_req()
	msg.partner_id = partner_id
	msg.index = index

	xyd.Backend.get():request(xyd.mid.SUIT_SKILL, msg)
end

function Slot:onChangeSuitSkill(event)
	local newIndex = event.data.index
	local partner_info = event.data.partner_info
	local partner_id = partner_info.partner_id
	local partnerInfo = self:getPartner(partner_id)

	if newIndex and newIndex > 0 then
		partnerInfo.skill_index = newIndex
	end
end

function Slot:getBuySlotTimes()
	return self.buySlotTimes_
end

function Slot:getSlotNum()
	return self.slotNum_
end

function Slot:getCollection()
	return self.collection_
end

function Slot:getCollectionCopy()
	local tmpData = {}

	for key in pairs(self.collection_) do
		tmpData[key] = self.collection_[key]
	end

	for key in pairs(self.puppetCollect_) do
		tmpData[tonumber(key)] = self.puppetCollect_[key]
	end

	return tmpData
end

function Slot:getReplacePartner()
	if not self:getPartner(self.replacePartner_) then
		self.replacePartner_ = nil
		self.replaceTableID_ = nil
	end

	return self.replacePartner_
end

function Slot:getReplaceTableID()
	return self.replaceTableID_
end

function Slot:getSortedPartners()
	return self.sortedPartners_
end

function Slot:getPartners()
	return self.partners_
end

function Slot:getPuppetPartner()
	if not self.puppetPartner_ then
		self.puppetPartner_ = {}
		local partnerList = self:getSortedPartners()["0_0"]

		for _, partnerId in ipairs(partnerList or {}) do
			local partnerInfo = self.partners_[partnerId]

			if xyd.tables.partnerTable:checkPuppetPartner(partnerInfo.tableID) then
				table.insert(self.puppetPartner_, partnerId)
			end
		end

		return self.puppetPartner_
	else
		for idx, partnerId in ipairs(self.puppetPartner_) do
			local partnerInfo = self.partners_[partnerId]

			if not partnerInfo then
				table.remove(self.puppetPartner_, idx)
			end
		end

		return self.puppetPartner_
	end
end

function Slot:getPartnerNum()
	return #self.sortedPartners_[tostring(xyd.partnerSortType.LEV) .. "_0"]
end

function Slot:getPartnersByStar()
	return self.partnersByStar_
end

function Slot:getGuide()
end

function Slot:buySlot()
	local msg = messages_pb.buy_slot_req()

	xyd.Backend.get():request(xyd.mid.BUY_SLOT, msg)
end

function Slot:getPartner(partnerId)
	return self.partners_[partnerId]
end

function Slot:getPartnerData(partnerId)
	if self.partners_[partnerId] == nil then
		return nil
	else
		return self.partners_[partnerId]:getInfo()
	end
end

function Slot:getListByTableID(tableID, exceptPartnerId)
	local group = xyd.tables.partnerTable:getGroup(tableID)
	local groupPartnerList = self.sortedPartners_[tostring(xyd.partnerSortType.STAR) .. "_" .. tostring(group)]
	local res = {}
	exceptPartnerId = tonumber(exceptPartnerId) or -1

	for _, partnerId in pairs(groupPartnerList or {}) do
		local partnerInfo = self.partners_[partnerId]

		if partnerInfo.tableID == tableID and exceptPartnerId ~= partnerId then
			table.insert(res, partnerInfo)
		end
	end

	return res
end

function Slot:getListByGroupAndStar(group, star, exceptPartnerId)
	local groupPartnerList = self.sortedPartners_[tostring(xyd.partnerSortType.STAR) .. "_" .. tostring(group)]
	local res = {}
	exceptPartnerId = tonumber(exceptPartnerId) or -1

	for _, partnerId in pairs(groupPartnerList) do
		local partnerInfo = self.partners_[partnerId]

		if partnerInfo.star == star and partnerId ~= exceptPartnerId then
			table.insert(res, partnerInfo)
		end
	end

	return res
end

function Slot:getCanSummonNum()
	local slotNum = self:getSlotNum()
	local sortedPartners = self:getSortedPartners()

	return slotNum - #sortedPartners[tostring(xyd.partnerSortType.LEV) .. "_0"]
end

function Slot:gmAddPartner(partnerInfo, sort)
	self:addPartners({
		partnerInfo
	})

	if not self.collection_[partnerInfo.table_id] then
		self.collection_[partnerInfo.table_id] = true
	end

	if sort then
		self:checkPromotablePartner()
	end
end

function Slot:replacePartner(id, tableID)
	local partner = self:getPartner(id)

	if not partner then
		return
	end

	partner:replace(tableID)
end

function Slot:updateJobsAttr(jobs)
	local partners = self:getPartners()

	for id in pairs(partners) do
		local partner = partners[id]

		if xyd.tableContains(jobs, partner:getJob()) then
			partner:updateAttrs()
		end
	end
end

function Slot:updateAllPartnersAttrs()
	local partners = self:getPartners()

	for id in pairs(partners) do
		local partner = partners[id]

		partner:updateAttrs()
	end
end

function Slot:onShowSkin(event)
	local data = event.data
	local p = self.partners_[data.partner_id]

	p:setShowSkin(tonumber(data.show_skin))
	p:displayChange()
end

function Slot:setShowSkin(partner_id, show_skin)
	local msg = messages_pb:show_skin_req()
	msg.partner_id = partner_id
	msg.is_show = show_skin

	xyd.Backend.get():request(xyd.mid.SHOW_SKIN, msg)
end

function Slot:clearSaveTmpTreasure(partner)
	partner.tmp_treasure_ = nil
end

function Slot:onSendGifts(event)
	local data = event.data
	local partner = self.partners_[data.partner_id]
	partner.lastLovePointTime = data.last_love_point_time
	partner.love_point = data.love_point
	local tableID = partner:getTableID()
	local keys = xyd.tables.partnerTable:getShowIds(tableID)
	local key = keys[1]

	if not self.maxLovePoints[key] or self.maxLovePoints[key] < data.love_point then
		self.maxLovePoints[key] = data.love_point
	end
end

function Slot:setNeedSort(flag)
	self.needSort_ = flag
end

function Slot:getNeedSort()
	return self.needSort_
end

function Slot:onPartnerVow(event)
	local data = event.data
	local params = data.partner_info
	local partner_info = {
		partnerID = params.partner_id,
		showID = params.show_id,
		wedding_date = params.wedding_date,
		showSkin = params.show_skin,
		is_vowed = params.is_vowed
	}

	if params.equips then
		partner_info.equipments = {}

		for k, v in ipairs(params.equips) do
			partner_info.equipments[k] = v
		end
	end

	if not partner_info.partnerID then
		return
	end

	local changed_attr = self.partners_[partner_info.partnerID]:updateAttrs(partner_info)
	local changed_attr_show = {}

	for key in pairs(changed_attr) do
		if xyd.tables.dBuffTable:isAttr(key) then
			changed_attr_show[key] = changed_attr[key]
		end
	end

	xyd.EventDispatcher:inner():dispatchEvent({
		name = xyd.event.PARTNER_ATTR_CHANGE,
		data = {
			partnerID = partner_info.partnerID,
			changed_attr = changed_attr_show
		}
	})
end

function Slot:isRequireMaxLovePoint(tableID, partner)
	local keys = xyd.tables.partnerTable:getShowIds(tableID)
	local key = keys[1]

	if self.maxLovePoints[key] or self.maxLovePoints[key] == 0 then
		if self.maxLovePoints[key] < partner.love_point then
			return true
		end

		return false
	end

	return true
end

function Slot:getMaxLovePoint(tableID)
	local keys = xyd.tables.partnerTable:getShowIds(tableID)
	local key = keys[1]

	return self.maxLovePoints[key]
end

function Slot:getMaxLovePointSuper(tableID)
	local point = self:getMaxLovePoint(tableID)

	if not point then
		local list = self:getListByTableID(tableID)
		local maxPoint = 0

		for k, v in ipairs(list) do
			if maxPoint < v:getLovePoint() then
				maxPoint = v:getLovePoint()
			end
		end

		local keys = xyd.tables.partnerTable:getShowIds(tableID)
		local key = keys[1]
		self.maxLovePoints[key] = maxPoint

		return self.maxLovePoints[key]
	end

	return point
end

function Slot:onMaxLovePoint(event)
	local tableID = event.data.table_id
	local keys = xyd.tables.partnerTable:getShowIds(tableID)
	local key = keys[1]
	self.maxLovePoints[key] = event.data.max_love_point
end

function Slot:recordPartnerStory(tableID)
	local msg = messages_pb.complete_partner_story_req()
	msg.table_id = tableID

	xyd.Backend.get():request(xyd.mid.COMPLETE_PARTNER_STORY, msg)
end

function Slot:reqMaxLovePoint(tableID)
	local msg = messages_pb.get_max_love_point_req()
	msg.table_id = tableID

	xyd.Backend:get():request(xyd.mid.GET_MAX_LOVE_POINT, msg)
end

function Slot:hasSkinPartner(skinID)
	local tableIDs = xyd.tables.partnerPictureTable:getSkinPartner(skinID)
	local flag = false

	for k, tableID in pairs(tableIDs) do
		local list = self:getListByTableID(tableID)

		if #list > 0 then
			flag = true

			break
		end
	end

	return flag
end

function Slot:getSkinTotalNum(skinId)
	local partners = self:getPartners()
	local totalNum = 0

	for _, partner in pairs(partners) do
		local skinID = partner:getSkinID()

		if skinID == skinId then
			totalNum = totalNum + 1
		end
	end

	local skinInBackpack = xyd.models.backpack:getItemNumByID(skinId)
	totalNum = totalNum + skinInBackpack

	return totalNum
end

function Slot:checkPromotablePartner()
	local partnerNum = xyd.tables.miscTable:getNumber("player_red_point_partner_num", "value")
	local partners = self.sortedPartners_[tostring(xyd.partnerSortType.POWER) .. "_0"]

	if partners == nil then
		return
	end

	local levelUpHeroList = {}
	partnerNum = xyd.checkCondition(partnerNum < #partners, partnerNum, #partners)

	for i = 1, partnerNum do
		local partnerId = partners[i]
		local np = self:getPartner(partnerId)
		local grade = np:getGrade()
		local max_lev = np:getMaxLev(grade, np:getAwake())
		local lev = np:getLevel()
		local cost = xyd.tables.expPartnerTable:getCost(lev + 1)
		local mana = xyd.models.backpack:getItemNumByID(xyd.ItemID.MANA)
		local exp = xyd.models.backpack:getItemNumByID(xyd.ItemID.PARTNER_EXP)

		if lev < max_lev and cost[xyd.ItemID.MANA] < mana and cost[xyd.ItemID.PARTNER_EXP] < exp then
			table.insert(levelUpHeroList, partnerId)
		end
	end

	local levUpRedParams = xyd.models.redMark:getRedMarkParams(xyd.RedMarkType.PROMOTABLE_PARTNER) or {}
	local lShowRed = xyd.checkCondition(#levelUpHeroList > 0, true, false)
	levUpRedParams.npList = levelUpHeroList

	xyd.models.redMark:setMark(xyd.RedMarkType.PROMOTABLE_PARTNER, lShowRed, levUpRedParams)
end

function Slot:onChoosePotential(event)
	if event.data and tostring(event.data.partner_info) ~= "" then
		self:onChoosePartnerPotential(event.data.partner_info)
	end
end

function Slot:onChoosePartnerPotential(partner_info)
	local partnerInfo = xyd.getPartnerInfo(partner_info)

	self.partners_[partner_info.partner_id]:updateAttrs(partnerInfo)
end

function Slot:onSwitchPotentialBak(event)
	if event.data and tostring(event.data.partner_info) ~= "" then
		local partnerInfo = xyd.getPartnerInfo(event.data.partner_info)
		local partner_id = partnerInfo.partner_id
		self.partners_[partner_id].potentials = partnerInfo.potentials

		self:onPartnerUpdate(event)
	end
end

function Slot:refreshShenxueForgeStatus()
	if self.hasRefreshShenxue then
		return
	end

	self.forgeList = xyd.tables.partnerTable:getForgeList()

	if xyd.Global.isReview == 1 then
		for group in pairs(self.forgeList) do
			local tableIDs = self.forgeList[group]

			for i = #tableIDs, 1, -1 do
				if xyd.tables.partnerTable:getShowInForgeAuditing(tableIDs[i]) == 0 then
					table.remove(self.forgeList[group], i)
				end
			end
		end
	end

	for group in pairs(self.forgeList) do
		local tableIDs = self.forgeList[group]

		for i = #tableIDs, 1, -1 do
			if xyd.getServerTime() < xyd.tables.partnerTable:getShowInForge(tableIDs[i]) then
				table.remove(self.forgeList[group], i)
			end
		end
	end

	self:refreshAllShenxueGroup()
end

function Slot:refreshAllShenxueGroup()
	local groupIds = xyd.tables.groupTable:getGroupIds()

	for key, groupId in pairs(groupIds) do
		if not self.forgeStatus[tostring(groupId)] then
			self.forgeStatus[tostring(groupId)] = {}
		end

		self:refreshShenxueGroup(groupId)
	end
end

function Slot:refreshShenxueGroup(groupId)
	for key, id in pairs(self.forgeList[tostring(groupId)]) do
		local tableID = id
		local hostID_ = xyd.tables.partnerTable:getHost(tableID)
		local material = xyd.split(xyd.tables.partnerTable:getMaterial(tableID), "|")
		local hPList = self:getListByTableID(hostID_)
		local isCanForge = true

		if #hPList == 0 then
			isCanForge = false
			self.forgeStatus[tostring(groupId)][tostring(tableID)] = isCanForge
		else
			local lastTableID = 0
			local materialIds_ = {}

			for keyid, mTableID in pairs(material) do
				if not materialIds_[tostring(mTableID)] then
					materialIds_[tostring(mTableID)] = 0
				end

				materialIds_[tostring(mTableID)] = materialIds_[tostring(mTableID)] + 1

				if tonumber(mTableID) ~= lastTableID then
					lastTableID = tonumber(mTableID)
				end
			end

			for mTableID in pairs(materialIds_) do
				local needNum = materialIds_[mTableID]
				local pList = nil

				if tonumber(mTableID) % 1000 == 999 then
					local group = math.floor(tonumber(mTableID) % 10000 / 1000)
					local star = math.floor(tonumber(mTableID) / 10000)
					pList = self:getListByGroupAndStar(group, star)

					if star == 4 then
						needNum = needNum + 2
					elseif star == 5 then
						needNum = needNum + 2
					end
				else
					pList = self:getListByTableID(tonumber(mTableID))
				end

				if tonumber(mTableID) == tonumber(hostID_) then
					needNum = needNum + 1
				end

				if needNum > #pList then
					isCanForge = false

					break
				end
			end

			self.forgeStatus[tostring(groupId)][tostring(tableID)] = isCanForge
		end
	end

	self.hasRefreshShenxue = true
end

function Slot:initShenxueSort()
	local function starSort(a, b)
		local weight_a = self.partners_[a].star * 10000 + self.partners_[a].lev * 10 + self.partners_[a]:getGroup()
		local weight_b = self.partners_[b].star * 10000 + self.partners_[b].lev * 10 + self.partners_[b]:getGroup()

		if weight_a - weight_b ~= 0 then
			return weight_b < weight_a
		else
			return self.partners_[a]:getTableID() < self.partners_[b]:getTableID()
		end
	end

	self:refreshShenxueForgeStatus()

	local partnerTable = xyd.tables.partnerTable
	local pShenxueList = {}
	local pNormalList = {}

	for i = 0, 6 do
		pShenxueList[xyd.partnerSortType.SHENXUE .. "_" .. i] = {}
		pNormalList[xyd.partnerSortType.SHENXUE .. "_" .. i] = {}
	end

	for i in pairs(self.sortedPartners_[xyd.partnerSortType.SHENXUE .. "_0"]) do
		local partnerId = self.sortedPartners_[xyd.partnerSortType.SHENXUE .. "_0"][i]
		local np = self:getPartner(partnerId)
		local tableId = np:getTableID()
		local grouId = np:getGroup()
		local shenxueTableId = partnerTable:getShenxueTableId(tableId)
		local shenxueGroupId = partnerTable:getGroup(shenxueTableId)

		if shenxueTableId > 0 and self.forgeStatus[tostring(shenxueGroupId)][tostring(shenxueTableId)] then
			table.insert(pShenxueList[xyd.partnerSortType.SHENXUE .. "_0"], partnerId)
			table.insert(pShenxueList[xyd.partnerSortType.SHENXUE .. "_" .. grouId], partnerId)
		else
			table.insert(pNormalList[xyd.partnerSortType.SHENXUE .. "_0"], partnerId)
			table.insert(pNormalList[xyd.partnerSortType.SHENXUE .. "_" .. grouId], partnerId)
		end
	end

	for i = 0, 6 do
		table.sort(pShenxueList[xyd.partnerSortType.SHENXUE .. "_" .. i], starSort)
		table.sort(pNormalList[xyd.partnerSortType.SHENXUE .. "_" .. i], starSort)

		self.sortedPartners_[xyd.partnerSortType.SHENXUE .. "_" .. i] = {}

		for k in pairs(pShenxueList[xyd.partnerSortType.SHENXUE .. "_" .. i]) do
			table.insert(self.sortedPartners_[xyd.partnerSortType.SHENXUE .. "_" .. i], pShenxueList[xyd.partnerSortType.SHENXUE .. "_" .. i][k])
		end

		for k in pairs(pNormalList[xyd.partnerSortType.SHENXUE .. "_" .. i]) do
			table.insert(self.sortedPartners_[xyd.partnerSortType.SHENXUE .. "_" .. i], pNormalList[xyd.partnerSortType.SHENXUE .. "_" .. i][k])
		end
	end
end

function Slot:getShenxueStatusByTableID(tableID)
	local group = xyd.tables.partnerTable:getGroup(tableID)
	local status = self.forgeStatus[tostring(group)][tostring(tableID)]

	return status
end

function Slot:checkShenxueOrAwake(partnerId)
	local res1 = self:checkShenxue(partnerId)
	local res2 = self:checkAwake(partnerId)

	if res1 or res2 then
		return true
	else
		return false
	end
end

function Slot:checkShenxue(partnerId)
	if not xyd.checkRedMarkSetting(xyd.RedMarkType.CAN_SHENXUE) then
		return false
	end

	local partner = self:getPartner(partnerId)
	local shenxueTableId = xyd.tables.partnerTable:getShenxueTableId(partner:getTableID())

	if shenxueTableId > 0 and self:getShenxueStatusByTableID(shenxueTableId) then
		return true
	else
		return false
	end
end

function Slot:checkAwake(partnerId)
	if not xyd.checkRedMarkSetting(xyd.RedMarkType.CAN_AWAKE) then
		return false
	end

	local np = self:getPartner(partnerId)

	if not np:isCanAwake() then
		return false
	end

	local cost = np:getAwakeItemCost()
	cost = xyd.checkCondition(cost ~= nil and #cost > 0, cost, {
		10,
		0
	})
	local resNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.GRADE_STONE)

	if resNum < cost[2] then
		return false
	end

	local star = np:getStar()
	local key = tostring(np:getTableID()) .. "_" .. star
	local statusData = self.awakeMatStatusList[key]

	if not statusData then
		return false
	end

	return statusData.hasMat
end

function Slot:onRollBackPartner(event)
	local partners = event.data.partners

	self:delPartners({
		event.data.partner_id
	})
	self:addPartners(partners)
	self:initAwakMatStatus()
end

function Slot:initAwakMatStatus()
	for _, partnerId in ipairs(self.sortedPartners_[tostring(xyd.partnerSortType.LEV) .. "_0"]) do
		local np = self:getPartner(partnerId)
		local star = np:getStar()

		if np:isCanAwake() then
			local awakeMaterials = np:getAwakeMaterial()
			local key = tostring(np:getTableID()) .. "_" .. star

			if awakeMaterials then
				if not self.awakeMatStatusList[key] then
					self.awakeMatStatusList[key] = {
						hasMat = false,
						awakeMaterials = awakeMaterials
					}
				end

				self.awakeMatStatusList[key].hasMat = self:checkHasAwakeMaterials(partnerId, awakeMaterials)
			end
		end
	end

	local a = 2
end

function Slot:checkHasAwakeMaterials(partnerId, awakeMaterials)
	local tempPartnerList = {}

	for i, value in pairs(self.sortedPartners_[xyd.partnerSortType.LEV .. "_" .. "0"]) do
		table.insert(tempPartnerList, value)
	end

	local matNeedNumList = {}

	for _, mTableID in pairs(awakeMaterials) do
		if not matNeedNumList[tostring(mTableID)] then
			matNeedNumList[tostring(mTableID)] = 1
		else
			matNeedNumList[tostring(mTableID)] = matNeedNumList[tostring(mTableID)] + 1
		end
	end

	local isHasMat = true

	for mTableID, _ in pairs(matNeedNumList) do
		local needNum = matNeedNumList[mTableID]
		local pList = nil

		if tonumber(mTableID) % 1000 == 999 then
			local star = xyd.tables.partnerIDRuleTable:getStar(tostring(mTableID))
			local group = xyd.tables.partnerIDRuleTable:getGroup(tostring(mTableID))

			if not self:splicePartnerFromListByGroupAndStar(partnerId, group, star, needNum, tempPartnerList) then
				isHasMat = false

				break
			end
		elseif not self:splicePartnerFromListByTableID(tonumber(mTableID), needNum, tempPartnerList) then
			isHasMat = false

			break
		end
	end

	return isHasMat
end

function Slot:splicePartnerFromListByGroupAndStar(selfPartnerId, group, star, needNum, partnerList)
	local groupPartnerList = partnerList
	local res = {}
	local count = 0
	local index = 1

	while groupPartnerList[index] and count < needNum do
		local partner = self.partners_[groupPartnerList[index]]

		if groupPartnerList[index] ~= selfPartnerId and partner:getStar() == star and (group == 0 or partner:getGroup() == group) then
			count = count + 1

			table.remove(partnerList, index)
		else
			index = index + 1
		end
	end

	if needNum <= count then
		return true
	else
		return false
	end
end

function Slot:splicePartnerFromListByTableID(tableID, num, partnerList)
	local group = xyd.tables.partnerTable:getGroup(tableID)
	local leftNum = num
	local groupPartnerList = {}

	for i in pairs(partnerList) do
		table.insert(groupPartnerList, partnerList[i])
	end

	local res = {}

	for index = 1, #groupPartnerList do
		local partner = self.partners_[groupPartnerList[index]]
		local isAddNum = true

		if partner:getTableID() == tableID then
			table.remove(partnerList, index)

			leftNum = leftNum - 1

			if leftNum <= 0 then
				return true
			else
				isAddNum = false
			end
		end

		if isAddNum then
			index = index + 1
		end
	end

	return false
end

function Slot:levSort(a, b)
	if tonumber(a) ~= nil then
		a = self:getPartner(tonumber(a))
	end

	if tonumber(b) ~= nil then
		b = self:getPartner(tonumber(b))
	end

	local weight_a = a.lev * 100 + a:getStar() * 10 + a:getGroup()
	local weight_b = b.lev * 100 + b:getStar() * 10 + b:getGroup()

	if weight_a - weight_b ~= 0 then
		return weight_b < weight_a
	else
		return a:getTableID() < b:getTableID()
	end
end

function Slot:starSort(a, b)
	if tonumber(a) ~= nil then
		a = self:getPartner(tonumber(a))
	end

	if tonumber(b) ~= nil then
		b = self:getPartner(tonumber(b))
	end

	local weight_a = a:getStar() * 10000 + a.lev * 10 + a:getGroup()
	local weight_b = b:getStar() * 10000 + b.lev * 10 + b:getGroup()

	if weight_a - weight_b ~= 0 then
		return weight_b < weight_a
	else
		return a:getTableID() < b:getTableID()
	end
end

function Slot:atkSort(a, b)
	if tonumber(a) ~= nil then
		a = self:getPartner(tonumber(a))
	end

	if tonumber(b) ~= nil then
		b = self:getPartner(tonumber(b))
	end

	local key_a = a:getBattleAttrs().atk
	local key_b = b:getBattleAttrs().atk

	return key_b < key_a
end

function Slot:hpSort(a, b)
	if tonumber(a) ~= nil then
		a = self:getPartner(tonumber(a))
	end

	if tonumber(b) ~= nil then
		b = self:getPartner(tonumber(b))
	end

	local key_a = a:getBattleAttrs().hp
	local key_b = b:getBattleAttrs().hp

	return key_b < key_a
end

function Slot:armSort(a, b)
	if tonumber(a) ~= nil then
		a = self:getPartner(tonumber(a))
	end

	if tonumber(b) ~= nil then
		b = self:getPartner(tonumber(b))
	end

	local key_a = a:getBattleAttrs().arm
	local key_b = b:getBattleAttrs().arm

	return key_b < key_a
end

function Slot:spdSort(a, b)
	if tonumber(a) ~= nil then
		a = self:getPartner(tonumber(a))
	end

	if tonumber(b) ~= nil then
		b = self:getPartner(tonumber(b))
	end

	local key_a = a:getBattleAttrs().spd
	local key_b = b:getBattleAttrs().spd

	return key_b < key_a
end

function Slot:powerSort(a, b)
	if tonumber(a) ~= nil then
		a = self:getPartner(tonumber(a))
	end

	if tonumber(b) ~= nil then
		b = self:getPartner(tonumber(b))
	end

	return b:getPower() < a:getPower()
end

function Slot:isCollectSort(a, b)
	if tonumber(a) ~= nil then
		a = self:getPartner(tonumber(a))
	end

	if tonumber(b) ~= nil then
		b = self:getPartner(tonumber(b))
	end

	local key_a = xyd.checkCondition(a:isCollected(), 1, 0)
	local key_b = xyd.checkCondition(b:isCollected(), 1, 0)

	if key_a == key_b then
		return self:levSort(a, b)
	end

	return key_b < key_a
end

function Slot:lovePointSort(a, b)
	if tonumber(a) ~= nil then
		a = self:getPartner(tonumber(a))
	end

	if tonumber(b) ~= nil then
		b = self:getPartner(tonumber(b))
	end

	local weight_a = a:getLovePoint() * 1000 + a.lev * 100 + a:getStar() * 10 + a:getGroup()
	local weight_b = b:getLovePoint() * 1000 + b.lev * 100 + b:getStar() * 10 + b:getGroup()

	if weight_a - weight_b ~= 0 then
		return weight_b < weight_a
	else
		return a:getTableID() < b:getTableID()
	end
end

function Slot:shenxueSort(a, b)
	if tonumber(a) ~= nil then
		a = self:getPartner(tonumber(a))
	end

	if tonumber(b) ~= nil then
		b = self:getPartner(tonumber(b))
	end

	local function checkPre(aNp, bNp)
		local weight_a = a.star * 10000 + a.lev * 10 + a:getGroup()
		local weight_b = b.star * 10000 + b.lev * 10 + b:getGroup()

		if weight_a - weight_b ~= 0 then
			return weight_b < weight_a
		else
			return a:getTableID() < b:getTableID()
		end
	end

	local partnerTable = xyd.tables.partnerTable
	local canShenxueA = false
	local canShenxueB = false
	local tableIdA = a:getTableID()
	local grouIdA = a:getGroup()
	local shenxueTableIdA = partnerTable:getShenxueTableId(tableIdA)
	local shenxueGroupIdA = partnerTable:getGroup(shenxueTableIdA)

	if shenxueTableIdA > 0 and self.forgeStatus[tostring(shenxueGroupIdA)][tostring(shenxueTableIdA)] then
		canShenxueA = true
	end

	local tableIdB = b:getTableID()
	local grouIdB = a:getGroup()
	local shenxueTableIdB = partnerTable:getShenxueTableId(tableIdB)
	local shenxueGroupIdB = partnerTable:getGroup(shenxueTableIdB)

	if shenxueTableIdB > 0 and self.forgeStatus[tostring(shenxueGroupIdB)][tostring(shenxueTableIdB)] then
		canShenxueB = true
	end

	if canShenxueA and canShenxueB then
		return checkPre(a, b)
	elseif canShenxueA and not canShenxueB then
		return false
	elseif not canShenxueA and canShenxueB then
		return true
	else
		return checkPre(a, b)
	end
end

function Slot:refreshEquip()
	self.equipsOfPartner = {}

	for id in pairs(self.partners_) do
		for key, equip in pairs(self.partners_[id].equipments) do
			if equip then
				if not self.equipsOfPartner[equip] then
					self.equipsOfPartner[equip] = {}
				end

				table.insert(self.equipsOfPartner[equip], self.partners_[id].partnerID)
			end
		end
	end
end

function Slot:addEquip(itemId, partnerId)
	if not self.equipsOfPartner[itemId] then
		self.equipsOfPartner[itemId] = {}
	end

	local index = xyd.arrayIndexOf(self.equipsOfPartner[itemId], partnerId)

	if index < 0 then
		table.insert(self.equipsOfPartner[itemId], partnerId)
	end
end

function Slot:deleteEquip(itemId, partnerId)
	if self.equipsOfPartner[itemId] then
		local index = xyd.arrayIndexOf(self.equipsOfPartner[itemId], partnerId)

		if index > -1 then
			table.remove(self.equipsOfPartner[itemId], index)
		end
	end
end

function Slot:getEquipsOfPartners()
	return self.equipsOfPartner
end

function Slot:setIsCollected(partnerId, isCollected)
	self.isCollected[partnerId] = isCollected

	xyd.db.misc:setValue({
		key = "marked_partner_" .. partnerId,
		value = isCollected
	})
end

function Slot:getIsCollected(partnerId)
	if self.isCollected[partnerId] then
		return self.isCollected[partnerId] == 1
	end

	local val = tonumber(xyd.db.misc:getValue("marked_partner_" .. partnerId) or 0)
	self.isCollected[partnerId] = val

	return val == 1
end

function Slot:needExskillGuide()
	return not xyd.db.misc:getValue("partner_exskill_guide")
end

function Slot:setExskillGuide()
	xyd.db.misc:setValue({
		value = "1",
		key = "partner_exskill_guide"
	})
end

function Slot:getNumByStar(starNum)
	return #self.partnersByStar_[starNum .. "_0"]
end

function Slot:addAltarPartner(partner)
	local keyList = {
		"0_0",
		"0_" .. partner:getGroup()
	}

	if partner:getStar() <= 5 then
		table.insert(keyList, partner:getStar() .. "_" .. partner:getGroup())
		table.insert(keyList, partner:getStar() .. "_0")
	end

	for i = 1, #keyList do
		local key = keyList[i]
		local sortList = self.partnersByStar_[key]

		if #sortList == 0 then
			table.insert(sortList, partner:getPartnerID())
		else
			local isInsert = false

			for j in pairs(sortList) do
				if not self.sortForAltar(partner:getPartnerID(), sortList[j]) then
					table.insert(sortList, j, partner:getPartnerID())

					isInsert = true

					break
				end
			end

			if isInsert == false then
				table.insert(sortList, 1, partner:getPartnerID())
			end
		end
	end
end

return Slot
