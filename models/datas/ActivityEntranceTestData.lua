local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityEntranceTestData = class("ActivityEntranceTestData", ActivityData, true)
local Pet = import("app.models.Pet")

function ActivityEntranceTestData:ctor(params)
	self.canUsePartners = {}
	self.sortedPartners_ = {}
	self.settedHeros = {}
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

	ActivityData.ctor(self, params)

	self.firstTime = true

	xyd.models.collection:reqCollectionInfo()
	self:registerEvent(xyd.event.WARMUP_BET, self.onSportsBet, self)
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, self.onActivityIfon, self)
	self:registerEvent(xyd.event.GET_COLLECTION_INFO, function ()
		local partnerSettingsBefore = xyd.db.misc:getValue("activity_entrance_test_partner_list")

		if partnerSettingsBefore and self.firstTime then
			self.firstTime = false
			partnerSettingsBefore = json.decode(partnerSettingsBefore)

			for keyBefore, valueBefore in pairs(partnerSettingsBefore) do
				for key, value in pairs(self.detail.partner_list) do
					if value.table_id == valueBefore.table_id then
						self.detail.partner_list[key] = partnerSettingsBefore[keyBefore]
						local artifactID = self.detail.partner_list[key].equips[6]

						if artifactID and artifactID ~= 0 then
							local artifactLev = xyd.tables.activityEntranceTestRankTable:getArtifactLev(self:getLevel())
							local collectionID = xyd.tables.itemTable:getCollectionId(artifactID)
							local collectionItemID = xyd.tables.collectionTable:getItemId(collectionID)
							local lev1 = xyd.tables.equipTable:getItemLev(collectionItemID)

							if lev1 == 36 then
								local pinkItemID = xyd.tables.equipTable:getSoulByIdAndLev(collectionItemID, 39)
								local hasGotPink = xyd.models.collection:isGot(xyd.tables.itemTable:getCollectionId(pinkItemID))

								if hasGotPink and xyd.tables.equipTable:getItemLev(pinkItemID) == 39 then
									lev1 = 39
								end
							end

							if artifactLev ~= lev1 then
								self.dataHasChange = true
							end

							artifactLev = math.min(artifactLev, lev1)
							self.detail.partner_list[key].equips[6] = xyd.tables.equipTable:getSoulByIdAndLev(artifactID, artifactLev)
						end
					end
				end
			end

			self:sendSettedPartnerReq()
		end
	end)
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

function ActivityEntranceTestData:addNewPartner(partner)
	local partnerId = 1

	for i in pairs(self.canUsePartners) do
		if self.canUsePartners[i].partnerID then
			partnerId = partnerId + 1
		end
	end

	partner.partnerID = partnerId
	partner.equipments = self.getInitEquip()
	partner.potentials = {
		0,
		0,
		0
	}

	if not self.detail.partner_list then
		self.detail.partner_list = {}
	end

	local params = {
		table_id = partner.tableID,
		equips = partner.equipments,
		potentials = partner.potentials,
		tableIndex = partner.tableIndex
	}

	table.insert(self.detail.partner_list, params)

	self.dataHasChange = true
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

function ActivityEntranceTestData:deletePartner(partner)
	for i in pairs(self.detail.partner_list) do
		if partner.tableIndex == self.detail.partner_list[i].tableIndex then
			table.remove(self.detail.partner_list, i)

			break
		end
	end

	partner.equipments = self.getInitEquip()
	partner.potentials = {
		0,
		0,
		0
	}

	for key, p in pairs(self.canUsePartners) do
		if partner.partnerID < p.partnerID then
			p.partnerID = p.partnerID - 1
		end
	end

	partner.partnerID = 0
	self.dataHasChange = true
end

function ActivityEntranceTestData:setSkillIndex(partner_id, index)
	for key, p in pairs(self.detail.partner_list) do
		if tonumber(p.table_id) == tonumber(partner_id) and index and tonumber(index) > 0 then
			p.skill_index = index
		end
	end
end

function ActivityEntranceTestData:sendSettedPartnerReq()
	if not self.dataHasChange then
		return
	end

	local partnerList = {}

	for key, p in pairs(self.detail.partner_list) do
		local param = messages_pb:warmup_partner_info()
		param.table_id = p.table_id

		if self:getLevel() ~= xyd.EntranceTestLevelType.R1 then
			for i in pairs(p.potentials) do
				table.insert(param.potentials, p.potentials[i])
			end
		end

		for i in pairs(p.equips) do
			table.insert(param.equips, p.equips[i])
		end

		if p.time ~= nil then
			param.time = p.time
		end

		if p.skill_index and tonumber(p.skill_index) > 0 then
			param.skill_index = p.skill_index
		end

		table.insert(partnerList, param)
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
	for key, p in pairs(self.detail.partner_list) do
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
	print("========makeHeros======")

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

	if not #settedHeros then
		settedHeros = {}
	end

	self.canUsePartners = {}

	for key, id in pairs(xyd.tables.activityWarmupArenaPartnerTable:getIds()) do
		local tableId = xyd.tables.activityWarmupArenaPartnerTable:getPartnerId(id)
		local PartnerNew = import("app.models.Partner")
		local partner = PartnerNew.new()

		partner:populate({
			partner_id = 0,
			isUpdateAttrs = false,
			table_id = tableId,
			star = xyd.tables.activityEntranceTestRankTable:getPartnerStar(self:getLevel()),
			lev = xyd.tables.activityEntranceTestRankTable:getPartnerLev(self:getLevel()),
			grade = xyd.tables.partnerTable:getMaxGrade(tableId),
			awake = xyd.tables.activityEntranceTestRankTable:getPartnerAwake(self:getLevel()),
			equips = xyd.tables.activityWarmupArenaPartnerTable:getEquips(id),
			potentials = xyd.tables.activityEntranceTestRankTable:getPotential(self:getLevel()),
			ex_skills = xyd.tables.activityEntranceTestRankTable:getPartnerExSkill(self:getLevel())
		})

		partner.tableIndex = id
		partner.lev = partner:getMaxLev(partner:getGrade(), partner:getAwake())

		partner:updateAttrs({
			isEntrance = true
		})
		table.insert(self.canUsePartners, partner)
	end

	local tableIndexs = {}

	for i in pairs(settedHeros) do
		for key, p in pairs(self.canUsePartners) do
			if tableIndexs[p.tableIndex] then
				-- Nothing
			elseif p.tableID == settedHeros[i].table_id then
				p.partnerID = i
				p.equipments = settedHeros[i].equips

				if settedHeros[i].potentials == nil or #settedHeros[i].potentials == 0 then
					settedHeros[i].potentials = xyd.tables.activityEntranceTestRankTable:getPotential(self:getLevel())
				end

				p.potentials = settedHeros[i].potentials
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

	for i in ipairs(self.canUsePartners) do
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
		end

		if self.isNewArr[b.tableID] == 1 then
			key_b = key_b * 2
		end
	end

	if key_a == 0 and key_b == 0 then
		key_a = -a.tableID
		key_b = -b.tableID

		if self.isNewArr[a.tableID] == 1 then
			key_a = key_a * 2
		end

		if self.isNewArr[b.tableID] == 1 then
			key_b = key_b * 2
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
		end

		if self.isNewArr[b.tableID] == 1 then
			key_b = -key_b * 2
		end
	end

	if key_a == 0 and key_b == 0 then
		key_a = -a.tableID
		key_b = -b.tableID

		if self.isNewArr[a.tableID] == 1 then
			key_a = -key_a * 2
		end

		if self.isNewArr[b.tableID] == 1 then
			key_b = -key_b * 2
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

	if self:getLevel() ~= xyd.EntranceTestLevelType.R1 then
		if #pInfo.potentials >= 3 then
			for key, id in pairs(pInfo.potentials) do
				if id == 0 then
					return false
				end
			end
		else
			return false
		end
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

	local red = tonumber(self.detail_.free_times) > 0

	if xyd.getServerTime() > self:getEndTime() - xyd.DAY_TIME then
		red = false
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ENTRANCE_TEST, red)

	return red
end

function ActivityEntranceTestData:getBetRed()
	if self:getDayIndex() >= 8 then
		return false
	end

	local betTime = tonumber(xyd.db.misc:getValue("warmup_bet_time"))

	if betTime and xyd.isSameDay(betTime, xyd.getServerTime()) then
		return false
	elseif not betTime or betTime < xyd.getServerTime() then
		return true
	else
		return false
	end
end

function ActivityEntranceTestData:getLevel()
	return self.detail.level
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

return ActivityEntranceTestData
