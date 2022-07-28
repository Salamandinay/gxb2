local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityEntranceTestData = class("ActivityEntranceTestData", ActivityData, true)
local Pet = import("app.models.Pet")

function ActivityEntranceTestData:ctor(params)
	self.canUsePartners = {}
	self.sortedPartners_ = {}
	self.settedHeros = {}
	self.rankDataList_ = {}
	self.recordRankSelfScoreArr = {}
	self.recordGamblePartners = {}
	self.dataHasChange = false
	self.matchEnemyList = {}
	self.matchIndex = 1
	self.hasDefence = true
	self.SORTS = {
		xyd.partnerSortType.LEV,
		xyd.partnerSortType.STAR,
		xyd.partnerSortType.ATK,
		xyd.partnerSortType.HP,
		xyd.partnerSortType.ARM,
		xyd.partnerSortType.SPD,
		xyd.partnerSortType.SHENXUE,
		xyd.partnerSortType.POWER,
		xyd.partnerSortType.isCollected,
		xyd.partnerSortEntranceTestType.FINISH
	}
	self.isCanUpdatePveArr = {}

	for i = 1, self:getPveMaxStage() do
		self.isCanUpdatePveArr[i] = true
	end

	ActivityData.ctor(self, params)

	self.firstTime = true

	xyd.models.collection:reqCollectionInfo()
	self:registerEvent(xyd.event.WARMUP_BET, self.onSportsBet, self)
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, self.onActivityIfon, self)
	self:registerEvent(xyd.event.WARMUP_GET_REPORT, self.onGetGambleInfo, self)
	self:registerEvent(xyd.event.WARMUP_GET_RANK_LIST, self.onGetRankInfo, self)
	self:registerEvent(xyd.event.WARMUP_UPDATE_PARTNER_LIST, self.onWarmupUpdatePartnerListBack, self)
	self:registerEvent(xyd.event.BOSS_BUY, self.onBossBuyBack, self)
	self:registerEvent(xyd.event.GET_COLLECTION_INFO, function ()
	end)
end

function ActivityEntranceTestData:onWarmupUpdatePartnerListBack(event)
	for key, p in pairs(self.canUsePartners) do
		for k, info in pairs(self.detail.partner_list) do
			if p:getTableID() == info.table_id then
				for i in pairs(p:getPotential()) do
					if info.potentials[i] ~= p:getPotential()[i] then
						info.potentials = xyd.cloneTable(p:getPotential())
					end
				end

				if info.skill_index ~= p:getSkillIndex() then
					info.skill_index = p:getSkillIndex()
				end

				for i in pairs(p:getEquipment()) do
					if info.equips[i] ~= p:getEquipment()[i] then
						info.equips = xyd.cloneTable(p:getEquipment())
					end
				end

				for i in pairs(info.equips) do
					if info.equips[i] ~= p:getEquipment()[i] then
						info.equips = xyd.cloneTable(p:getEquipment())
					end
				end
			end
		end
	end

	self.canUsePartners = {}

	self:makeHeros()
end

function ActivityEntranceTestData:onSportsBet(event)
	self.detail.bet_records = event.data.bet_records
end

function ActivityEntranceTestData:onActivityIfon(event)
	local activity_id = event.data.activity_id

	if activity_id ~= xyd.ActivityID.ENTRANCE_TEST then
		return
	end

	self.fakeComplete = nil

	self:updateCharterData()
end

function ActivityEntranceTestData:updateCharterData()
	local starNum = 0
	local starinfo = {
		starNum = 0,
		timeStamp = 0
	}
	local ids = xyd.tables.activityWarmupArenaTaskAwardTable:getIDs()

	for i = 1, #ids do
		local id = tonumber(ids[i])

		if xyd.tables.activityWarmupArenaTaskAwardTable:getPlotID(id) ~= 0 and xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id) <= self:getTotalEnergy() then
			starNum = starNum + 1
			starinfo.starNum = starNum
			starinfo.timeStamp = xyd.getServerTime()

			if starNum ~= self:getCharterStar() then
				xyd.db.misc:setValue({
					key = "entrance_test_charter_star",
					value = json.encode(starinfo)
				})
			end
		end
	end

	local win = xyd.WindowManager.get():getWindow("activity_entrance_test_window")

	if win then
		win:updateMissionRed()
	else
		self:checkRedMaskOfTask()
	end
end

function ActivityEntranceTestData:getCurrentPlotID()
	local ids = xyd.tables.activityWarmupArenaTaskAwardTable:getIDs()
	local index = 1

	for i = 1, #ids do
		local id = tonumber(ids[i])

		if xyd.tables.activityWarmupArenaTaskAwardTable:getPlotID(id) ~= 0 and xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id) <= self:getTotalEnergy() then
			if self:getCharterState() == 0 then
				return xyd.tables.activityWarmupArenaTaskAwardTable:getPlotID(id)
			end

			if self:getCharterState() < self:getCharterStar() then
				if index == self:getCharterState() + 1 then
					return xyd.tables.activityWarmupArenaTaskAwardTable:getPlotID(id)
				else
					index = index + 1
				end
			elseif index == self:getCharterState() then
				return xyd.tables.activityWarmupArenaTaskAwardTable:getPlotID(id)
			else
				index = index + 1
			end
		end
	end

	return nil
end

function ActivityEntranceTestData:getPlotID(star)
	local ids = xyd.tables.activityWarmupArenaTaskAwardTable:getIDs()
	local index = 1

	for i = 1, #ids do
		local id = tonumber(ids[i])

		if xyd.tables.activityWarmupArenaTaskAwardTable:getPlotID(id) ~= 0 and xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id) <= self:getTotalEnergy() then
			if index == star then
				return xyd.tables.activityWarmupArenaTaskAwardTable:getPlotID(id)
			else
				index = index + 1
			end
		end
	end

	return nil
end

function ActivityEntranceTestData:getCharterStar()
	if xyd.db.misc:getValue("entrance_test_charter_star") == nil or type(json.decode(xyd.db.misc:getValue("entrance_test_charter_star"))) == "number" then
		local starinfo = {
			starNum = 0,
			timeStamp = 0
		}

		xyd.db.misc:setValue({
			key = "entrance_test_charter_star",
			value = json.encode(starinfo)
		})
	else
		local timeinfo = json.decode(xyd.db.misc:getValue("entrance_test_charter_star"))
		local starNum = timeinfo.starNum
		local timeStamp = timeinfo.timeStamp

		if timeStamp == nil or timeStamp < self.start_time or self.end_time < timeStamp then
			local starinfo = {
				starNum = 0,
				timeStamp = 0
			}

			xyd.db.misc:setValue({
				key = "entrance_test_charter_star",
				value = json.encode(starinfo)
			})
		end
	end

	local timeinfo = json.decode(xyd.db.misc:getValue("entrance_test_charter_star"))
	local starNum = timeinfo.starNum
	local timeStamp = timeinfo.timeStamp

	return tonumber(starNum)
end

function ActivityEntranceTestData:getCharterState()
	if xyd.db.misc:getValue("entrance_test_charter_state") == nil or type(json.decode(xyd.db.misc:getValue("entrance_test_charter_state"))) == "number" then
		local stateinfo = {
			timeStamp = 0,
			stateNum = 0
		}

		xyd.db.misc:setValue({
			key = "entrance_test_charter_state",
			value = json.encode(stateinfo)
		})
	else
		local timeinfo = json.decode(xyd.db.misc:getValue("entrance_test_charter_state"))
		local stateNum = timeinfo.stateNum
		local timeStamp = timeinfo.timeStamp

		if timeStamp == nil or timeStamp < self.start_time or self.end_time < timeStamp then
			local stateinfo = {
				timeStamp = 0,
				stateNum = 0
			}

			xyd.db.misc:setValue({
				key = "entrance_test_charter_state",
				value = json.encode(stateinfo)
			})
		end
	end

	local timeinfo = json.decode(xyd.db.misc:getValue("entrance_test_charter_state"))
	local stateNum = timeinfo.stateNum
	local timeStamp = timeinfo.timeStamp

	return tonumber(stateNum)
end

function ActivityEntranceTestData:IfBuyGiftBag()
	local activitydata = xyd.models.activity:getActivity(xyd.ActivityID.WARMUP_GIFT)

	if not activitydata then
		return false
	end

	return activitydata:ifBack()
end

function ActivityEntranceTestData:getTotalEnergy()
	local totalEnergy = 0
	local taskIDs = xyd.tables.activityWarmupArenaTaskAwardTable:getIDs()

	for i = 1, #self.detail.mission_info.mission_completes do
		if self.detail.mission_info.mission_completes[i] == 1 then
			totalEnergy = totalEnergy + xyd.tables.activityWarmupArenaTaskTable:getEnergy(i)
		end
	end

	return totalEnergy
end

function ActivityEntranceTestData:battleFinish(isWin)
	local rank = self:getLevel()

	if self.fakeComplete == nil then
		self.fakeComplete = {}
		local ids = xyd.tables.activityWarmupArenaTaskTable:getIDs()

		for i = 1, #ids do
			local id = tonumber(ids[i])
			self.fakeComplete[id] = 0
		end
	end

	local ids = xyd.tables.activityWarmupArenaTaskTable:getIDs()

	for i = 1, #ids do
		local id = tonumber(ids[i])

		if xyd.tables.activityWarmupArenaTaskTable:getRank(id) <= rank then
			if tonumber(xyd.tables.activityWarmupArenaTaskTable:getType(id)) == 2 and isWin then
				self.fakeComplete[id] = self.fakeComplete[id] + 1
			end

			if tonumber(xyd.tables.activityWarmupArenaTaskTable:getType(id)) == 1 then
				self.fakeComplete[id] = self.fakeComplete[id] + 1
			end
		end
	end

	local win = xyd.WindowManager.get():getWindow("activity_entrance_test_window")

	if win then
		win:updateMissionRed()
	end
end

function ActivityEntranceTestData:checkRedMaskOfTaskAward()
	local red = false
	local ids = xyd.tables.activityWarmupArenaTaskAwardTable:getIDs()

	for i = 1, #ids do
		local id = tonumber(ids[i])

		if xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id) <= self:getTotalEnergy() and (self.detail.mission_info.awards[id] == 0 or self.detail.mission_info.ex_awards[id] == 0 and self:IfBuyGiftBag() == true) then
			red = true
		end
	end

	return red
end

function ActivityEntranceTestData:checkRedMaskOfTask()
	local timeStamp = tonumber(xyd.db.misc:getValue("entrance_test_task_btn_red_mask"))

	if timeStamp == nil or timeStamp < self.start_time or self.end_time < timeStamp then
		xyd.db.misc:setValue({
			key = "entrance_test_task_btn_red_mask",
			value = xyd.getServerTime()
		})

		return true
	end

	local red = false
	local ids = xyd.tables.activityWarmupArenaTaskAwardTable:getIDs()

	for i = 1, #ids do
		local id = tonumber(ids[i])

		if xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id) <= self:getTotalEnergy() and (self.detail.mission_info.awards[id] == 0 or self.detail.mission_info.ex_awards[id] == 0 and self:IfBuyGiftBag() == true) then
			red = true
		end
	end

	if self:getCharterState() < self:getCharterStar() then
		red = true
	end

	if self.fakeComplete == nil then
		self.fakeComplete = {}

		for i = 1, #ids do
			local id = tonumber(ids[i])
			self.fakeComplete[id] = 0
		end
	end

	for i = 1, #ids do
		local id = tonumber(ids[i])

		if tonumber(xyd.tables.activityWarmupArenaTaskTable:getComplete(id)) <= self.detail.mission_info.mission_values[id] + self.fakeComplete[id] and self.detail.mission_info.awards[id] == 0 then
			self.detail.mission_info.mission_completes[id] = 1
			local ids1 = xyd.tables.activityWarmupArenaTaskAwardTable:getIDs()

			for j = 1, #ids1 do
				local id1 = tonumber(ids1[j])

				if xyd.tables.activityWarmupArenaTaskAwardTable:getEnergy(id1) <= self:getTotalEnergy() and (self.detail.mission_info.awards[id1] == 0 or self.detail.mission_info.ex_awards[id1] == 0 and self:IfBuyGiftBag() == true) then
					red = true
				end
			end
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ENTRANCE_TEST_TASK, red)

	return red
end

function ActivityEntranceTestData:onSportsBet(event)
	self.detail.bet_records = event.data.bet_records
end

function ActivityEntranceTestData:getPartnerByIndex(tableIndex)
	for key, p in pairs(self.canUsePartners) do
		if tableIndex == p.tableIndex then
			return p
		end
	end
end

function ActivityEntranceTestData:getPartnerByPartnerId(partner_id)
	for key, p in pairs(self.canUsePartners) do
		if partner_id == p.partnerID then
			return p
		end
	end
end

function ActivityEntranceTestData:setSkillIndex(partner_id, index)
	for key, p in pairs(self.canUsePartners) do
		if tonumber(p:getTableID()) == tonumber(partner_id) and index and tonumber(index) > 0 then
			p:setSkillIndex(index)
		end
	end
end

function ActivityEntranceTestData:sendSettedPartnerReq()
	if not self.dataHasChange then
		return
	end

	local partnerList = {}
	local isSend = false

	for key, p in pairs(self.canUsePartners) do
		local isSame = true

		for k, info in pairs(self.detail.partner_list) do
			if p:getTableID() == info.table_id then
				for i in pairs(p:getPotential()) do
					if info.potentials[i] ~= p:getPotential()[i] then
						isSame = false

						break
					end
				end

				if isSame == false then
					break
				end

				if info.skill_index ~= p:getSkillIndex() then
					isSame = false
				end

				if isSame == false then
					break
				end

				for i in pairs(p:getEquipment()) do
					if info.equips[i] ~= p:getEquipment()[i] then
						isSame = false

						break
					end
				end

				if isSame == false then
					break
				end

				for i in pairs(info.equips) do
					if info.equips[i] ~= p:getEquipment()[i] then
						isSame = false

						break
					end
				end

				if isSame == false then
					break
				end
			end
		end

		if isSame == false then
			isSend = true
			local param = messages_pb:warmup_partner_info()
			param.table_id = p:getTableID()

			for i in pairs(p:getPotential()) do
				table.insert(param.potentials, p:getPotential()[i])
			end

			for i in pairs(p:getEquipment()) do
				table.insert(param.equips, p:getEquipment()[i])
			end

			if p.time ~= nil then
				param.time = p.time
			end

			if p:getSkillIndex() and tonumber(p:getSkillIndex()) > 0 then
				param.skill_index = p:getSkillIndex()
			end

			param.id = p.tableIndex

			table.insert(partnerList, param)
		end
	end

	if isSend == false then
		return
	end

	local msg = messages_pb:warmup_update_partner_list_req()
	msg.activity_id = self.id

	for i in pairs(partnerList) do
		table.insert(msg.partner_list, partnerList[i])
	end

	xyd.Backend.get():request(xyd.mid.WARMUP_UPDATE_PARTNER_LIST, msg)
	self:makeHeros()

	self.dataHasChange = false

	xyd.db.misc:setValue({
		key = "activity_entrance_test_partner_list",
		value = json.encode(self.detail.partner_list)
	})
end

function ActivityEntranceTestData:setPartnerTime(partner)
	for key, p in pairs(self.canUsePartners) do
		if p.tableIndex == partner.tableIndex then
			p.time = xyd.getServerTime()
			partner.last_love_point_time = xyd.getServerTime()

			break
		end
	end
end

function ActivityEntranceTestData:getInitEquip()
	local equips = xyd.tables.miscTable:split2num("max_partner_equip", "value", "|")

	return equips
end

function ActivityEntranceTestData:checkHasNew()
	for i, p in pairs(self.canUsePartners) do
		if xyd.tables.activityWarmupArenaPartnerTable:getIsNewPartner(p.tableIndex) == 1 then
			return true
		end
	end

	return false
end

function ActivityEntranceTestData:checkHasNextNew()
	for i, p in pairs(self.canUsePartners) do
		if xyd.tables.activityWarmupArenaPartnerTable:getIsNewPartner(p.tableIndex) == 2 then
			return true
		end
	end

	return false
end

function ActivityEntranceTestData:makeHeros()
	if not self.detail.partners or self.detail.partners and #self.detail.partners == 0 then
		self.detail.partners = {}
		self.dataHasChange = true
		self.hasDefence = false
	end

	if not self.isNewArr then
		self.isNewArr = {}
		local allIds = xyd.tables.activityWarmupArenaPartnerTable:getIds()

		for i in pairs(allIds) do
			self.isNewArr[xyd.tables.activityWarmupArenaPartnerTable:getPartnerId(allIds[i])] = xyd.tables.activityWarmupArenaPartnerTable:getIsNewPartner(allIds[i])
		end
	end

	local settedHeros = self.detail.partner_list
	settedHeros = settedHeros or {}

	for i, id in pairs(xyd.tables.activityWarmupArenaPartnerTable:getIds()) do
		local isSearch = false
		local tableId = xyd.tables.activityWarmupArenaPartnerTable:getPartnerId(id)

		for k in pairs(settedHeros) do
			if settedHeros[k].table_id == tableId then
				isSearch = true

				break
			end
		end

		if isSearch == false then
			local param = {
				table_id = tableId,
				equips = xyd.tables.activityWarmupArenaPartnerTable:getEquips(id),
				potentials = xyd.tables.activityEntranceTestRankTable:getPotential(self:getLevel()),
				skill_index = xyd.tables.activityWarmupArenaPartnerTable:getEquipSkill(id)
			}
			settedHeros[i] = param
		end
	end

	self.detail.partner_list = settedHeros

	if not self.canUsePartners or #self.canUsePartners == 0 then
		self.canUsePartners = {}

		for key, id in pairs(xyd.tables.activityWarmupArenaPartnerTable:getIds()) do
			local tableId = xyd.tables.activityWarmupArenaPartnerTable:getPartnerId(id)
			local PartnerNew = import("app.models.Partner")
			local partner = PartnerNew.new()

			partner:populate({
				isUpdateAttrs = false,
				table_id = tableId,
				star = xyd.tables.activityEntranceTestRankTable:getPartnerStar(self:getLevel()),
				lev = xyd.tables.activityEntranceTestRankTable:getPartnerLev(self:getLevel()),
				grade = xyd.tables.partnerTable:getMaxGrade(tableId),
				awake = xyd.tables.activityEntranceTestRankTable:getPartnerAwake(self:getLevel()),
				equips = xyd.tables.activityWarmupArenaPartnerTable:getEquips(id),
				partner_id = key,
				potentials = xyd.tables.activityEntranceTestRankTable:getPotential(self:getLevel()),
				ex_skills = xyd.tables.activityEntranceTestRankTable:getPartnerExSkill(self:getLevel()),
				skill_index = xyd.tables.activityWarmupArenaPartnerTable:getEquipSkill(id)
			})

			partner.tableIndex = id
			partner.lev = partner:getMaxLev(partner:getGrade(), partner:getAwake())

			partner:updateAttrs({
				isEntrance = true
			})
			table.insert(self.canUsePartners, partner)
		end

		local tableIndexs = {}

		for i in pairs(xyd.tables.activityWarmupArenaPartnerTable:getIds()) do
			for key, p in pairs(self.canUsePartners) do
				if tableIndexs[p.tableIndex] then
					-- Nothing
				elseif settedHeros[i] and p.tableID == settedHeros[i].table_id then
					p.partnerID = i
					p.equipments = xyd.cloneTable(settedHeros[i].equips)

					if settedHeros[i].potentials == nil or #settedHeros[i].potentials == 0 then
						settedHeros[i].potentials = xyd.cloneTable(xyd.tables.activityEntranceTestRankTable:getPotential(self:getLevel()))
					end

					p.potentials = xyd.cloneTable(settedHeros[i].potentials)
					p.last_love_point_time = settedHeros[i].time or 0
					settedHeros[i].tableIndex = p.tableIndex
					p.skill_index = settedHeros[i].skill_index
					tableIndexs[p.tableIndex] = true

					self.canUsePartners[key]:updateAttrs({
						isEntrance = true
					})

					break
				end
			end
		end
	end

	for i = 1, #self.SORTS do
		self.sortedPartners_[self.SORTS[i] .. "_0"] = {}
	end

	local groupIds = xyd.tables.groupTable:getGroupIds()

	table.insert(groupIds, 0)

	for i in pairs(groupIds) do
		for j = 1, #self.SORTS do
			self.sortedPartners_[self.SORTS[j] .. "_" .. groupIds[i]] = {}
		end
	end

	for i in pairs(self.canUsePartners) do
		local group = self.canUsePartners[i]:getGroup()

		if group then
			for j = 1, #self.SORTS do
				table.insert(self.sortedPartners_[self.SORTS[j] .. "_0"], self.canUsePartners[i])
				table.insert(self.sortedPartners_[self.SORTS[j] .. "_" .. group], self.canUsePartners[i])
			end
		end
	end

	table.sort(self.sortedPartners_[xyd.partnerSortType.STAR .. "_0"], handler(self, self.starSort))
	table.sort(self.sortedPartners_[xyd.partnerSortType.SHENXUE .. "_0"], handler(self, self.settingSort))
	table.sort(self.sortedPartners_[xyd.partnerSortEntranceTestType.FINISH .. "_0"], handler(self, self.finishSort))

	for i in pairs(groupIds) do
		for j = 1, #self.SORTS do
			if self.SORTS[j] ~= xyd.partnerSortType.SHENXUE and self.SORTS[j] ~= xyd.partnerSortEntranceTestType.FINISH then
				table.sort(self.sortedPartners_[self.SORTS[j] .. "_" .. groupIds[i]], xyd.models.slot.sortFuncList[self.SORTS[j]])
			end
		end

		table.sort(self.sortedPartners_[xyd.partnerSortType.STAR .. "_" .. groupIds[i]], handler(self, self.starSort))
		table.sort(self.sortedPartners_[xyd.partnerSortType.SHENXUE .. "_" .. groupIds[i]], handler(self, self.settingSort))
		table.sort(self.sortedPartners_[xyd.partnerSortEntranceTestType.FINISH .. "_" .. groupIds[i]], handler(self, self.finishSort))
	end
end

function ActivityEntranceTestData:getSortedPartnersBySort(sortType, groupId, jobId)
	if jobId == nil then
		jobId = 0
	end

	local partnersArr = self:getSortedPartners()
	local sortKey = sortType .. "_" .. groupId .. "_" .. jobId

	if not partnersArr[sortKey] then
		partnersArr[sortKey] = {}
		local allPartners = partnersArr["0_0"]

		if not allPartners then
			return partnersArr
		end

		for i in pairs(allPartners) do
			if allPartners[i].partnerID and (allPartners[i]:getGroup() == groupId or groupId == 0) and (allPartners[i]:getJob() == jobId or jobId == 0) then
				table.insert(partnersArr[sortKey], allPartners[i])
			end
		end

		local sortFunc = xyd.models.slot.sortFuncList[sortType]

		table.sort(partnersArr[sortKey], sortFunc)
	end

	return partnersArr
end

function ActivityEntranceTestData:checkIsFinish(p)
	local partner_id = p.partnerID
	partner_id = partner_id or p:getPartnerID()

	if not partner_id or partner_id == 0 then
		return false
	end

	local pInfo = self:getPartner(partner_id)

	if pInfo.equipments[5] == 0 or pInfo.equipments[6] == 0 then
		return false
	end

	if #pInfo.potentials >= 3 then
		for key, id in pairs(pInfo.potentials) do
			if id == 0 then
				return false
			end
		end
	else
		return false
	end

	return true
end

function ActivityEntranceTestData:getCanUsePartners()
	return self.canUsePartners
end

function ActivityEntranceTestData:getSortedPartners()
	local list = {}
	local sortPartnersList = self.sortedPartners_

	for key in pairs(sortPartnersList) do
		for jobId = 0, xyd.PartnerJob.LENGTH do
			local newKey = key .. "_" .. jobId
			list[newKey] = {}
		end
	end

	for key in pairs(sortPartnersList) do
		local partnerIdList = sortPartnersList[key]

		for i, partner in pairs(partnerIdList) do
			if partner.partnerID ~= nil and partner.partnerID ~= 0 then
				local job = partner:getJob()

				if list[key .. "_" .. job] then
					table.insert(list[key .. "_" .. job], partner)
				end

				if list[key .. "_" .. "0"] then
					table.insert(list[key .. "_" .. "0"], partner)
				end
			end
		end
	end

	return list
end

function ActivityEntranceTestData:getPartner(partnerId)
	for key, p in pairs(self.canUsePartners) do
		if p.partnerID == partnerId then
			return p
		end
	end
end

function ActivityEntranceTestData:getPartnerIdByPartner(partner, partnerIds)
	local partners = {}

	for key, p in pairs(self.canUsePartners) do
		if p.tableID == partner.table_id then
			table.insert(partners, p)
		end
	end

	for key, pid in pairs(partnerIds) do
		if pid ~= 0 then
			if #partners == 1 then
				return partners[1].partnerID
			end

			if pid == partners[1].partnerID then
				return partners[2].partnerID
			elseif pid == partners[2].partnerID then
				return partners[1].partnerID
			end
		end
	end

	for key, p in pairs(partners) do
		local isSame = true

		for i in pairs(p.equipments) do
			if p.equipments[i] ~= partner.equips[i] then
				isSame = false
			end
		end

		if partner.potentials then
			for i in pairs(p.potentials) do
				if p.potentials[i] ~= partner.potentials[i] then
					isSame = false
				end
			end
		end

		if isSame and p.partnerID then
			return p.partnerID
		end
	end

	for key, p in pairs(partners) do
		if p.partnerID then
			return p.partnerID
		end
	end

	return partners[1].partnerID
end

function ActivityEntranceTestData:getSettedPartnerIds()
	local list = {}

	for key in pairs(self.sortedPartners_) do
		list[key] = {}

		for i in pairs(self.sortedPartners_[key]) do
			if self.sortedPartners_[key][i].partnerID and self.sortedPartners_[key][i].partnerID ~= 0 then
				table.insert(list[key], self.sortedPartners_[key][i].partnerID)
			end
		end
	end

	return list
end

function ActivityEntranceTestData:getDayIndex()
	local alreadTime = xyd.getServerTime() - self.start_time

	return math.ceil(alreadTime / 86400)
end

function ActivityEntranceTestData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local red = tonumber(self:getFreeTimes()) > 0

	if self:getEndTime() < xyd.getServerTime() then
		red = false
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ENTRANCE_TEST, red)

	return red
end

function ActivityEntranceTestData:getBetRed()
	if not self:isCanGuess() then
		return false
	end

	local betTime = xyd.db.misc:getValue("warmup_bet_time_new")

	if not betTime then
		return true
	else
		betTime = tonumber(betTime)

		if self:startTime() <= betTime and betTime < self:getEndTime() then
			return false
		else
			return true
		end
	end

	return false
end

function ActivityEntranceTestData:getLevel()
	return 1
end

function ActivityEntranceTestData:getPetIDs()
	return xyd.models.petSlot:getPetIDs()
end

function ActivityEntranceTestData:getPetByID(id)
	local rankTable = xyd.tables.activityEntranceTestRankTable
	local trueData = xyd.models.petSlot:getPetByID(id)
	local rank = self:getLevel()
	local petLev = rankTable:getPetLev(rank)
	local petGrade = rankTable:getPetGrade(rank)
	local skill_inherit = rankTable:getPetSkillInherit(rank)
	local exSkill_inherit = rankTable:getPetExSkillInherit(rank)
	local skill = rankTable:getPetSkill(rank)

	if skill_inherit and skill_inherit == 1 then
		skill = trueData:getSkills()

		for index, skilllev in ipairs(skill) do
			if skilllev and skilllev < 30 then
				skill[index] = 30
			end
		end
	end

	local exSkill = 0

	if exSkill_inherit and exSkill_inherit == 1 then
		exSkill = trueData:getExLv()
	end

	local petInfo = Pet.new()

	petInfo:populate({
		petID = id,
		lev = petLev,
		grade = petGrade,
		skills = skill,
		ex_lv = exSkill
	})

	return petInfo
end

function ActivityEntranceTestData:getPveMaxStage()
	return 3
end

function ActivityEntranceTestData:getPvePartnerIsLock(type)
	if type > 0 and not self.detail.total_harms[type] then
		return true
	end

	if type > 0 and self.detail.total_harms[type] and self.detail.total_harms[type] < xyd.tables.activityWarmupArenaBossTable:getBossScore(type) then
		return true
	end

	return false
end

function ActivityEntranceTestData:getPvePartnerIsLockByTableId(tableId)
	local period = xyd.tables.activityWarmupArenaPartnerTable:getPeriodByPartnerId(tableId)

	return self:getPvePartnerIsLock(period)
end

function ActivityEntranceTestData:getFreeTimes()
	return self.detail.free_times
end

function ActivityEntranceTestData:subFreeTimes()
	self.detail.free_times = self.detail.free_times - 1

	if self.detail.free_times < 0 then
		self.detail.free_times = 0
	end

	self:updateFreeTimesShow()
end

function ActivityEntranceTestData:getBossHarm(bossId)
	for i = 1, self:getPveMaxStage() do
		if not self.detail.total_harms[i] then
			self.detail.total_harms[i] = 0
		end
	end

	return self.detail.total_harms[bossId]
end

function ActivityEntranceTestData:addBossHarm(bossId, harm)
	for i = 1, self:getPveMaxStage() do
		if not self.detail.total_harms[i] then
			self.detail.total_harms[i] = 0
		end
	end

	for i = 1, self:getPveMaxStage() do
		if not self.detail.harms[i] then
			self.detail.harms[i] = 0
		end
	end

	if self.detail.harms[bossId] < harm then
		self.detail.harms[bossId] = harm
	end

	local isFirstPass = false

	if self.detail.total_harms[bossId] then
		local bossTotalScore = xyd.tables.activityWarmupArenaBossTable:getBossScore(bossId)

		if self.detail.total_harms[bossId] < bossTotalScore and bossTotalScore <= self.detail.total_harms[bossId] + harm then
			isFirstPass = true
		end

		if self.detail.total_harms[bossId] < bossTotalScore then
			self.detail.total_harms[bossId] = self.detail.total_harms[bossId] + harm
		end
	end

	if isFirstPass then
		self:makeHeros()
	end

	return isFirstPass
end

function ActivityEntranceTestData:getMyHightHarm(bossId)
	for i = 1, self:getPveMaxStage() do
		if not self.detail.harms[i] then
			self.detail.harms[i] = 0
		end
	end

	return self.detail.harms[bossId]
end

function ActivityEntranceTestData:updateFreeTimesShow()
	local activity_entrance_test_wd = xyd.WindowManager.get():getWindow("activity_entrance_test_window")

	if activity_entrance_test_wd then
		activity_entrance_test_wd:updateFreeTimesShow()
	end

	local activity_entrance_test_wd = xyd.WindowManager.get():getWindow("activity_entrance_test_pve_window")

	if activity_entrance_test_wd then
		activity_entrance_test_wd:updateFreeTimesShow()
	end

	self:getRedMarkState()
end

function ActivityEntranceTestData:onBossBuyBack(event)
	local data = event.data

	if data.activity_id and data.activity_id == xyd.ActivityID.ENTRANCE_TEST then
		local num = data.free_times - self.detail.free_times
		self.detail.free_times = data.free_times
		self.detail.buy_times = data.buy_times

		xyd.showToast(__("ENTRANCE_TEST_TILI_OK_TIPS", num))
		self:updateFreeTimesShow()
	end
end

function ActivityEntranceTestData:buyTicket()
	local canBuyDay = xyd.tables.miscTable:getNumber("activity_warmup_arena_ticket_day", "value")
	local nowDisDay = math.ceil((xyd.getServerTime() - self:startTime()) / xyd.DAY_TIME)

	if canBuyDay <= nowDisDay then
		local cost = xyd.tables.miscTable:split2Cost("activity_warmup_arena_buy_costs", "value", "#")
		local maxNumCanBuy = xyd.tables.miscTable:getNumber("activity_warmup_arena_ticket_limit", "value")
		local myCanBuy = math.floor(xyd.models.backpack:getItemNumByID(cost[1]) / cost[2])

		if myCanBuy < maxNumCanBuy then
			maxNumCanBuy = myCanBuy
		end

		xyd.WindowManager.get():openWindow("item_buy_window", {
			hide_min_max = false,
			item_no_click = false,
			cost = cost,
			max_num = xyd.checkCondition(maxNumCanBuy == 0, 1, maxNumCanBuy),
			itemParams = {
				num = 1,
				itemID = xyd.ItemID.ENTRANCE_PVE_TICKET
			},
			buyCallback = function (num)
				if maxNumCanBuy <= 0 then
					xyd.showToast(__("FULL_BUY_SLOT_TIME"))

					xyd.WindowManager.get():getWindow("item_buy_window").skipClose = true

					return
				end

				local msg = messages_pb:boss_buy_req()
				msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
				msg.num = num

				xyd.Backend.get():request(xyd.mid.BOSS_BUY, msg)
			end
		})

		return
	end

	xyd.alertTips(__("ACTIVITY_NEW_WARMUP_TEXT30", canBuyDay))
end

function ActivityEntranceTestData:getIsCanFake()
	if self.isCanFake == nil then
		self.isCanFake = true
	end

	return self.isCanFake
end

function ActivityEntranceTestData:fakeToFight()
	if self.isCanFake == nil then
		self.isCanFake = true
	end

	if self.isCanFake then
		self.isCanFake = false

		xyd.addGlobalTimer(function ()
			self.isCanFake = true
		end, 1.5, 1)
	end
end

function ActivityEntranceTestData:isCanGuess()
	if math.floor((xyd.getServerTime() - self:startTime()) / xyd.DAY_TIME) < 3 then
		return false
	end

	return true
end

function ActivityEntranceTestData:getIsUpdateRankState(boss_id)
	return self.isCanUpdatePveArr[boss_id]
end

function ActivityEntranceTestData:setUpdateRankState(boss_id, state)
	self.isCanUpdatePveArr[boss_id] = state

	if state == false then
		self["rankTimeKeyId" .. boss_id] = xyd.addGlobalTimer(function ()
			self.isCanUpdatePveArr[boss_id] = true
			self["rankTimeKeyId" .. boss_id] = nil
		end, 60, 1)
	elseif state == true and self["rankTimeKeyId" .. boss_id] then
		xyd.removeGlobalTimer(self["rankTimeKeyId" .. boss_id])

		self["rankTimeKeyId" .. boss_id] = nil
	end
end

function ActivityEntranceTestData:reqRankInfo(index)
	if self:getIsUpdateRankState(index) then
		local msg = messages_pb:warmup_get_rank_list_req()
		msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
		msg.boss_id = index

		xyd.Backend.get():request(xyd.mid.WARMUP_GET_RANK_LIST, msg)

		self.RecordRankBossID = index

		self:setUpdateRankState(index, false)

		return true
	else
		return false
	end
end

function ActivityEntranceTestData:getRankData(index)
	for i = 1, #self.rankDataList_[index] do
		self.rankDataList_[index][i].rank = i
	end

	local socre = 0

	if self.recordRankSelfScoreArr[index] and self.recordRankSelfScoreArr[index][1] then
		socre = self.recordRankSelfScoreArr[index][1]
	end

	local rank = -1

	if self.recordRankSelfScoreArr[index] and self.recordRankSelfScoreArr[index][2] then
		rank = self.recordRankSelfScoreArr[index][2]
	end

	local data = {
		list = self.rankDataList_[index],
		score = socre,
		rank = rank + 1
	}

	return data
end

function ActivityEntranceTestData:onGetRankInfo(event)
	local data = event.data
	local list = {}

	for index, value in ipairs(data.list) do
		table.insert(list, {
			player_id = value.player_id,
			player_name = value.player_name,
			avatar_frame = value.avatar_frame_id,
			avatar_id = value.avatar_id,
			server_id = value.server_id,
			dress_style = value.dress_style or {},
			lev = value.lev,
			score = value.score,
			rank = tonumber(index),
			avatarID = value.avatar_id,
			avatar_frame_id = value.avatar_frame_id
		})
	end

	self.rankDataList_[self.RecordRankBossID] = list
	self.recordRankSelfScoreArr[self.RecordRankBossID] = {
		data.score,
		data.rank
	}
end

function ActivityEntranceTestData:reqGambleInfo()
	for i = 4, math.min(self:getDayIndex(), 6) do
		if not self.recordGamblePartners[i] then
			local msg = messages_pb.warmup_get_report_req()
			self.recordGambleDay = i
			msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
			msg.id = i

			xyd.Backend.get():request(xyd.mid.WARMUP_GET_REPORT, msg)

			return true
		end
	end

	return false
end

function ActivityEntranceTestData:getGambleInfo(dayIndex)
	return self.recordGamblePartners[dayIndex] or {}
end

function ActivityEntranceTestData:onGetGambleInfo(event)
	local data = event.data
	local report = data.battle_report
	local result = {
		{},
		{}
	}

	if self.recordGambleDay then
		for i, p in ipairs(report.teamA) do
			local PartnerNew = import("app.models.Partner")
			local partner = PartnerNew.new()

			partner:populate({
				isUpdateAttrs = false,
				tableID = tonumber(p.table_id),
				star = tonumber(p.star),
				lev = tonumber(p.level),
				grade = tonumber(p.grade),
				awake = tonumber(p.awake),
				equips = tonumber(p.equips),
				partner_id = tonumber(p.partner_id),
				potentials = tonumber(p.potentials),
				ex_skills = p.ex_skills,
				skill_index = tonumber(p.skill_index),
				pos = tonumber(p.pos)
			})

			result[1][tonumber(p.pos)] = partner
		end

		for i, p in ipairs(report.teamB) do
			local PartnerNew = import("app.models.Partner")
			local partner = PartnerNew.new()

			partner:populate({
				isUpdateAttrs = false,
				tableID = tonumber(p.table_id),
				star = tonumber(p.star),
				lev = tonumber(p.level),
				grade = tonumber(p.grade),
				awake = tonumber(p.awake),
				equips = tonumber(p.equips),
				partner_id = tonumber(p.partner_id),
				potentials = tonumber(p.potentials),
				ex_skills = p.ex_skills,
				skill_index = tonumber(p.skill_index),
				pos = tonumber(p.pos)
			})

			result[2][tonumber(p.pos)] = partner
		end

		self.recordGamblePartners[self.recordGambleDay] = result
		self.recordGambleDay = nil

		self:reqGambleInfo()
	end
end

function ActivityEntranceTestData:settingSort(a, b)
	local finishNumA = 10000
	local finishNumB = 10000

	if not self:checkIsFinish(a) then
		finishNumA = 0
	end

	if not self:checkIsFinish(b) then
		finishNumB = 0
	end

	local key_a = finishNumA
	local key_b = finishNumB

	if key_a ~= 0 and key_b ~= 0 then
		key_a = -a.tableID
		key_b = -b.tableID

		if self.isNewArr[a.tableID] == 1 then
			key_a = key_a * 2
		elseif self:getPvePartnerIsLockByTableId(a.tableID) then
			key_a = key_a * 1.5
		end

		if self.isNewArr[b.tableID] == 1 then
			key_b = key_b * 2
		elseif self:getPvePartnerIsLockByTableId(b.tableID) then
			key_b = key_b * 1.5
		end
	end

	if key_a == 0 and key_b == 0 then
		key_a = -a.tableID
		key_b = -b.tableID

		if self.isNewArr[a.tableID] == 1 then
			key_a = key_a * 2
		elseif self:getPvePartnerIsLockByTableId(a.tableID) then
			key_a = key_a * 1.5
		end

		if self.isNewArr[b.tableID] == 1 then
			key_b = key_b * 2
		elseif self:getPvePartnerIsLockByTableId(b.tableID) then
			key_b = key_b * 1.5
		end
	end

	return key_a < key_b
end

function ActivityEntranceTestData:finishSort(a, b)
	local finishNumA = 10000
	local finishNumB = 10000

	if not self:checkIsFinish(a) then
		finishNumA = 0
	end

	if not self:checkIsFinish(b) then
		finishNumB = 0
	end

	local key_a = finishNumA
	local key_b = finishNumB

	if key_a ~= 0 and key_b ~= 0 then
		key_a = -a.tableID
		key_b = -b.tableID

		if self.isNewArr[a.tableID] == 1 then
			key_a = -key_a * 2
		elseif self:getPvePartnerIsLockByTableId(a.tableID) then
			key_a = key_a * 2
		end

		if self.isNewArr[b.tableID] == 1 then
			key_b = -key_b * 2
		elseif self:getPvePartnerIsLockByTableId(b.tableID) then
			key_b = key_b * 2
		end
	end

	if key_a == 0 and key_b == 0 then
		key_a = -a.tableID
		key_b = -b.tableID

		if self.isNewArr[a.tableID] == 1 then
			key_a = -key_a * 2
		elseif self:getPvePartnerIsLockByTableId(a.tableID) then
			key_a = key_a * 2
		end

		if self.isNewArr[b.tableID] == 1 then
			key_b = -key_b * 2
		elseif self:getPvePartnerIsLockByTableId(b.tableID) then
			key_b = key_b * 2
		end
	end

	return key_a > key_b
end

function ActivityEntranceTestData:starSort(a, b)
	local finishNumA = -100000
	local finishNumB = -100000
	local check_A = self:checkIsFinish(a)

	if not check_A then
		finishNumA = 0
	end

	local check_B = self:checkIsFinish(b)

	if not check_B then
		finishNumB = 0
	end

	local weight_a = a:getStar() * 10000 + a.lev * 10 + a:getGroup() + finishNumA
	local weight_b = b:getStar() * 10000 + b.lev * 10 + b:getGroup() + finishNumB

	if weight_a - weight_b ~= 0 then
		return weight_b < weight_a
	else
		return b:getTableID() < a:getTableID()
	end
end

return ActivityEntranceTestData
