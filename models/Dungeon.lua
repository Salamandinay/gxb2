local Dungeon = class("Dungeon", import("app.models.BaseModel"))

function Dungeon:ctor()
	Dungeon.super.ctor(self)

	self.redPoint_ = false
	self.timeKey_ = -1
	self.selectIndex_ = 1
end

function Dungeon:onRegister()
	Dungeon.super.onRegister(self)
	self:registerEvent(xyd.event.DUNGEON_GET_MAP_INFO, handler(self, self.onDungeonInfo))
	self:registerEvent(xyd.event.DUNGEON_START, handler(self, self.onStart))
	self:registerEvent(xyd.event.DUNGEON_FIGHT, handler(self, self.onFight))
	self:registerEvent(xyd.event.DUNGEON_BUY_CUR_ITEM, handler(self, self.onBuyCurItem))
	self:registerEvent(xyd.event.DUNGEON_BUY_ITEM, handler(self, self.onBuyItem))
	self:registerEvent(xyd.event.DUNGEON_SKIP_REPORT, handler(self, self.onSkipReport))
	self:registerEvent(xyd.event.DUNGEON_USE_DRUG, handler(self, self.onUseDrug))
	self:registerEvent(xyd.event.SYSTEM_REFRESH, handler(self, self.startTimeCount))
	self:registerEvent(xyd.event.LEV_CHANGE, handler(self, self.onLevChange))
	self:registerEvent(xyd.event.FUNCTION_OPEN_MODEL, handler(self, self.onFunctionOpen))
end

function Dungeon:reqDungeonInfo()
	if self.data_ then
		return
	end

	local msg = messages_pb.dungeon_get_map_info_req()

	xyd.Backend:get():request(xyd.mid.DUNGEON_GET_MAP_INFO, msg)
end

function Dungeon:reqStart(ids)
	local msg = messages_pb.dungeon_start_req()

	for i = 1, #ids do
		table.insert(msg.partner_ids, ids[i])
	end

	xyd.Backend:get():request(xyd.mid.DUNGEON_START, msg)
end

function Dungeon:reqFight(index)
	local msg = messages_pb.dungeon_fight_req()
	msg.partner_index = index

	xyd.Backend:get():request(xyd.mid.DUNGEON_FIGHT, msg)
end

function Dungeon:reqBuyItem(index, indexs)
	local msg = messages_pb.dungeon_buy_item_req()
	msg.item_index = index

	if indexs and #indexs > 1 then
		for i = 1, #indexs do
			table.insert(msg.item_indexs, indexs[i])
		end
	end

	xyd.Backend:get():request(xyd.mid.DUNGEON_BUY_ITEM, msg)
end

function Dungeon:reqBuyCurItem(isSkip)
	local msg = messages_pb.dungeon_buy_cur_item_req()
	msg.is_skip = isSkip

	xyd.Backend:get():request(xyd.mid.DUNGEON_BUY_CUR_ITEM, msg)
end

function Dungeon:reqUseDrug(partnerIndex, drugID)
	local msg = messages_pb.dungeon_use_drug_req()
	msg.partner_index = partnerIndex
	msg.drug_id = drugID

	xyd.Backend:get():request(xyd.mid.DUNGEON_USE_DRUG, msg)
end

function Dungeon:reqSkipReport()
	local skipReport = self:isSkipReport() and 0 or 1
	local msg = messages_pb.dungeon_skip_report_req()
	msg.skip_report = skipReport

	xyd.Backend:get():request(xyd.mid.DUNGEON_SKIP_REPORT, msg)
end

function Dungeon:getNewPartners(partners)
	local newPartners = {}

	for i = 1, #partners do
		local partner = partners[i]
		local item = {
			table_id = partner.table_id,
			lv = partner.lv,
			awake = partner.awake,
			grade = partner.grade,
			status = {
				hp = partner.status.hp,
				mp = partner.status.mp or 50,
				pos = partner.status.pos or 1,
				true_hp = partner.status.true_hp or 1
			},
			show_skin = partner.show_skin,
			equips = partner.equips,
			star_origin = partner.star_origin,
			is_vowed = partner.is_vowed
		}

		table.insert(newPartners, item)
	end

	return newPartners
end

function Dungeon:onDungeonInfo(event)
	local newDta = xyd.decodeProtoBuf(event.data)
	self.data_ = {
		max_stage = newDta.max_stage,
		current_stage = newDta.current_stage,
		skip_report = newDta.skip_report,
		battle_id = newDta.battle_id,
		map_type = newDta.map_type,
		partners = self:getNewPartners(newDta.partners or {}),
		enemies = newDta.enemies,
		drugs = newDta.drugs,
		shop_items = newDta.shop_items,
		curr_shop_item = newDta.curr_shop_item,
		start_time = newDta.start_time,
		end_time = newDta.end_time,
		is_open = newDta.is_open
	}

	self:updateRedPoint()
end

function Dungeon:getHistoryStage()
	return self.data_.max_stage or 0
end

function Dungeon:startTimeCount()
	if self.timeKey_ > -1 then
		XYDCo.StopWait("dungeon_red_point_" .. self.timeKey_)

		self.timeKey_ = -1
	end

	local delay = math.floor(math.random() * 30 + 30)
	self.timeKey_ = 1

	XYDCo.WaitForTime(delay, function ()
		self:updateRedPoint()
	end, "dungeon_red_point_" .. self.timeKey_)
end

function Dungeon:onStart(event)
	local data = event.data
	local oldData = self:getData()
	oldData.battle_id = data.battle_id
	oldData.current_stage = data.current_stage
	oldData.enemies = data.enemies
	oldData.partners = self:getNewPartners(data.partners)
	oldData.sweep_awards = data.sweep_awards

	if data.sweep_awards then
		oldData.shop_items = data.sweep_awards.shop_items
		oldData.drugs = data.sweep_awards.drugs
	end

	self:updateRedPoint()
end

function Dungeon:onFight(event)
	local data = event.data
	local oldData = self:getData()
	oldData.battle_id = data.battle_id or oldData.battle_id
	oldData.current_stage = data.current_stage or oldData.current_stage

	if not oldData.max_stage or data.current_stage and oldData.max_stage < data.current_stage then
		oldData.max_stage = data.current_stage
	end

	oldData.enemies = data.enemies
	oldData.partners = self:getNewPartners(data.partners)

	if data.award then
		oldData.curr_shop_item = data.award.shop_items[1]

		self:addDrugs(data.award.drugs)
	end

	oldData.is_win = data.is_win
	oldData.battle_report = data.battle_report

	self:updateRedPoint()
end

function Dungeon:addDrugs(newDrugs)
	local drugs = self:getDrugs()

	for _, drug in ipairs(newDrugs) do
		local flag = false

		for _, oldDrug in ipairs(drugs) do
			if oldDrug.item_id == drug.item_id then
				oldDrug.item_num = tonumber(oldDrug.item_num) + tonumber(drug.item_num)
				flag = true

				break
			end
		end

		if not flag then
			table.insert(drugs, drug)
		end
	end
end

function Dungeon:onBuyCurItem(event)
	if event.data.is_skip == 1 then
		if not self:getData().shop_items then
			self:getData().shop_items = {}
		end

		table.insert(self:getData().shop_items, self:getData().curr_shop_item)
	end

	self:getData().curr_shop_item = 0
end

function Dungeon:onBuyItem(event)
	local newShopItems = event.data.shop_items
	self:getData().shop_items = newShopItems
end

function Dungeon:onSkipReport(event)
	self:getData().skip_report = event.data.skip_report
end

function Dungeon:onUseDrug(event)
	local data = event.data
	local drugs = self:getDrugs()

	for _, item in ipairs(drugs) do
		if item.item_id == data.drug_id then
			item.item_num = tonumber(item.item_num) - 1

			break
		end
	end

	self:updateOneStatus(data)
end

function Dungeon:updateOneStatus(data)
	local effects = xyd.tables.dungeonDrugTable:getEffect(data.drug_id)
	local partner = self:getPartners()[data.partner_index]

	for _, str in ipairs(effects) do
		local effect = xyd.split(str, "#")

		if effect[1] == xyd.BUFF_HEAL_P then
			partner.status.hp = math.min(100, partner.status.hp + 100 * tonumber(effect[2]))
		elseif effect[1] == xyd.BUFF_ENERGY then
			partner.status.mp = partner.status.mp + tonumber(effect[2])
		end
	end
end

function Dungeon:getData()
	return self.data_ or {}
end

function Dungeon:getPartners()
	return self:getData().partners or {}
end

function Dungeon:getEnemies()
	return self:getData().enemies or {}
end

function Dungeon:getCurStage()
	local curStage = self:getData().current_stage

	if not curStage or curStage == 0 then
		curStage = 1
	end

	return curStage
end

function Dungeon:getDrugs()
	return self:getData().drugs or {}
end

function Dungeon:isAllPass()
	return self:getMaxStage() < self:getCurStage()
end

function Dungeon:getMaxStage()
	local maxStage = xyd.tables.miscTable:getVal("dungeon_top")

	return tonumber(maxStage)
end

function Dungeon:getDrugByID(id)
	local num = 0
	local drugs = self:getDrugs()

	for _, item in ipairs(drugs) do
		if item.item_id == id then
			num = tonumber(item.item_num)

			break
		end
	end

	return num
end

function Dungeon:getShopItems()
	return self:getData().shop_items or {}
end

function Dungeon:getCurShopItem()
	return self:getData().curr_shop_item or 0
end

function Dungeon:isSkipReport()
	return self:getData().skip_report == 1
end

function Dungeon:isOpen()
	if self:getData().is_open == 1 and xyd:getServerTime() - self:getData().end_time < 0 then
		return true
	elseif self:getData().is_open == 0 and xyd:getServerTime() - self:getData().start_time > 0 then
		self.data_ = nil

		self:reqDungeonInfo()

		return true
	end

	return false
end

function Dungeon:checkHasAlive()
	local partners = self:getPartners()
	local isAlive = false

	for _, data in ipairs(partners) do
		if data.status.hp > 0 then
			isAlive = true

			break
		end
	end

	return isAlive
end

function Dungeon:checkPartnerAlive(partner_id)
	local partners = self:getPartners()
	local isAlive = false

	for _, data in ipairs(partners) do
		if data.status.hp > 0 and data.table_id == partner_id then
			isAlive = true

			break
		end
	end

	return isAlive
end

function Dungeon:showRedPoint()
	return self.redPoint_
end

function Dungeon:updateRedPoint()
	local flag = self:checkRedMark()

	if flag ~= self.redPoint_ then
		local redMark = self:checkFunctionOpen() and flag

		xyd.models.redMark:setMark(xyd.RedMarkType.DUNGEON, redMark)
	end

	self.redPoint_ = flag
end

function Dungeon:checkRedMark()
	if self:isOpen() then
		local partners = self:getPartners()

		if #partners <= 0 then
			return true
		end
	end

	return false
end

function Dungeon:getSelectIndex()
	return self.selectIndex_
end

function Dungeon:recordSelectIndex(index)
	self.selectIndex_ = index
end

function Dungeon:onLevChange()
	if self:checkFunctionOpen() then
		self:reqDungeonInfo()
	end
end

function Dungeon:onFunctionOpen(event)
	local funID = event.data.functionID

	if funID == xyd.FunctionID.DUNGEON then
		self:reqDungeonInfo()
	end
end

function Dungeon:checkFunctionOpen()
	return xyd.checkFunctionOpen(xyd.FunctionID.DUNGEON, true)
end

return Dungeon
