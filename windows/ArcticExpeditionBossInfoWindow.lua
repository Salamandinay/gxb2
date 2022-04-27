local ArcticExpeditionBossInfoWindow = class("ArcticExpeditionBossInfoWindow", import(".BaseWindow"))
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local Monster = import("app.models.Monster")
local SkillIcon = import("app.components.SkillIcon")
local ResItem = import("app.components.ResItem")
local CellFunctionIds = {
	NORMAL = 1,
	CENTER = 5
}
local GroupColor = {
	Color.New2(2464115199.0),
	Color.New2(4016532991.0),
	Color.New2(3903474175.0),
	Color.New2(1390213375)
}

function ArcticExpeditionBossInfoWindow:ctor(name, params)
	ArcticExpeditionBossInfoWindow.super.ctor(self, name, params)

	self.cellId_ = tonumber(params.cell_id)
	self.cellType_ = xyd.tables.arcticExpeditionCellsTable:getCellType(self.cellId_)
	self.cellFunctionId_ = xyd.tables.arcticExpeditionCellsTypeTable:getFunctionID(self.cellType_)
	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.ARCTIC_EXPEDITION)
	self.cellInfo_ = self.activityData_:getCellInfo(params.cell_id)
end

function ArcticExpeditionBossInfoWindow:initWindow()
	self:getComponent()
	self:updateResEnergyNum()
	self:initLayout()
	self:regisetr()
end

function ArcticExpeditionBossInfoWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.bgImg_ = winTrans:ComponentByName("e:image", typeof(UIWidget))
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.fightBtn_ = winTrans:NodeByName("fightBtn").gameObject
	self.fightBtnLabel_ = self.fightBtn_:ComponentByName("label", typeof(UILabel))
	self.fightCostNum_ = self.fightBtn_:ComponentByName("labelNum", typeof(UILabel))
	self.canFightBtn_ = winTrans:NodeByName("canFightBtn").gameObject
	self.canFightBtnlabel_ = self.canFightBtn_:ComponentByName("label1", typeof(UILabel))
	self.canFightBtnTime_ = self.canFightBtn_:ComponentByName("labelTime", typeof(UILabel))
	self.btnRecord_ = winTrans:NodeByName("btnRecord").gameObject
	self.btnRecordLabel_ = winTrans:ComponentByName("btnRecord/label", typeof(UILabel))
	self.helpBtn_ = winTrans:NodeByName("helpBtn").gameObject
	self.enemyGroup_ = winTrans:NodeByName("enemyGroup").gameObject
	self.labelFormation_ = self.enemyGroup_:ComponentByName("labelFormation", typeof(UILabel))
	self.powerLabel_ = self.enemyGroup_:ComponentByName("powerGroup/power", typeof(UILabel))
	self.groupImg_ = self.enemyGroup_:ComponentByName("groupImg", typeof(UISprite))

	for i = 1, 6 do
		self["heroContainer" .. i] = self.enemyGroup_:NodeByName("icon" .. i).gameObject
		self["hero" .. i] = HeroIcon.new(self["heroContainer" .. i]:NodeByName("hero" .. i).gameObject)
		self["partnerHp" .. i] = self.enemyGroup_:ComponentByName("icon" .. i .. "/hpProgress", typeof(UIProgressBar))
	end

	self.cellInfoGroup_ = winTrans:NodeByName("cellInfoGroup").gameObject
	self.cellHpProgress_ = self.cellInfoGroup_:ComponentByName("cellHpProgress", typeof(UIProgressBar))
	self.cellHpLabel_ = self.cellInfoGroup_:ComponentByName("cellHpProgress/label", typeof(UILabel))
	self.cellHpText_ = self.cellInfoGroup_:ComponentByName("cellHpText", typeof(UILabel))
	self.labelMass_ = self.cellInfoGroup_:ComponentByName("labelMass", typeof(UILabel))
	self.cellPosLabel_ = self.cellInfoGroup_:ComponentByName("cellPos", typeof(UILabel))
	self.cellInfoBtn_ = self.cellInfoGroup_:NodeByName("cellInfoPos/cellInfoBtn").gameObject
	self.cellNameLabel_ = self.cellInfoGroup_:ComponentByName("cellName", typeof(UILabel))
	self.cellImg_ = self.cellInfoGroup_:ComponentByName("cellImg", typeof(UISprite))
	self.labelTips_ = self.cellInfoGroup_:ComponentByName("labelTips", typeof(UILabel))
	self.skillGroup_ = self.cellInfoGroup_:ComponentByName("skillGroup", typeof(UILayout))
	self.gSkillDesc = self.cellInfoGroup_:NodeByName("gSkillDesc").gameObject
	self.buffGroup_ = winTrans:NodeByName("buffGroup").gameObject
	self.buffIcon_ = self.buffGroup_:NodeByName("buffIcon").gameObject
	self.clickBox_ = self.buffGroup_:NodeByName("buffDetailGroup/clickBox").gameObject
	self.buffText_ = self.buffGroup_:ComponentByName("buffText", typeof(UILabel))
	self.buffText2_ = self.buffGroup_:ComponentByName("buffText2", typeof(UILabel))
	self.buffText3_ = self.buffGroup_:ComponentByName("buffDetailGroup/buffText3", typeof(UILabel))
	self.buffText4_ = self.buffGroup_:ComponentByName("buffDetailGroup/buffText4", typeof(UILabel))
	self.buffDetailGroup_ = self.buffGroup_:NodeByName("buffDetailGroup").gameObject
	self.detailBg_ = self.buffDetailGroup_:ComponentByName("bgImg", typeof(UIWidget))
	self.showIcon_ = self.buffDetailGroup_:ComponentByName("showIcon", typeof(UISprite))
	self.groupBuffList_ = self.buffDetailGroup_:ComponentByName("groupBuffList", typeof(UILayout))
	self.buffDescItemRoot_ = self.buffDetailGroup_:NodeByName("buffDescItem").gameObject
	self.buffDetailHideBox_ = self.buffDetailGroup_:NodeByName("clickBox").gameObject
	self.groupResItem_ = self.window_:NodeByName("groupResItem").gameObject
	self.resItemList_ = self.groupResItem_:GetComponent(typeof(UILayout))
	self.resEnergyNum = self.groupResItem_:ComponentByName("res_item/res_num_label", typeof(UILabel))
	self.resEnergyPlus = self.groupResItem_:NodeByName("res_item/plus_btn").gameObject

	self.fightBtn_:SetActive(true)

	if not self:checkCanFight() or self.activityData_:getEra() == 1 or self.cellInfo_.num <= 0 or self.activityData_:getEndTime() - xyd.getServerTime() <= xyd.DAY_TIME or -self.activityData_:startTime() + xyd.getServerTime() < xyd.DAY_TIME then
		xyd.applyChildrenGrey(self.fightBtn_)
	end

	self.labelMass_.gameObject:SetActive(false)
end

function ArcticExpeditionBossInfoWindow:regisetr()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.resEnergyPlus).onClick = function ()
		xyd.WindowManager.get():openWindow("arctic_expedition_buy_window")
	end

	UIEventListener.Get(self.fightBtn_).onClick = function ()
		if self.activityData_.detail.sta <= 0 then
			xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_39"))

			return
		end

		if self.activityData_:getEra() == 1 then
			xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_43"))
		elseif self.cellInfo_.num <= 0 then
			xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_62"))
		elseif -self.activityData_:startTime() + xyd.getServerTime() < xyd.DAY_TIME or self.activityData_:getEndTime() - xyd.getServerTime() <= xyd.DAY_TIME then
			xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_65"))
		elseif self:checkCanFight() then
			local fightParams = {
				showSkip = false,
				battleType = xyd.BattleType.ARCTIC_EXPEDITION,
				cell_id = self.cellId_
			}

			xyd.WindowManager:get():openWindow("battle_formation_trial_window", fightParams)
		else
			xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_38"))
		end
	end

	UIEventListener.Get(self.btnRecord_).onClick = function ()
		local msg = messages_pb.arctic_expedition_get_records_req()
		msg.cell_id = self.cellId_
		msg.activity_id = xyd.ActivityID.ARCTIC_EXPEDITION

		xyd.Backend.get():request(xyd.mid.ARCTIC_EXPEDITION_GET_RECORDS, msg)
	end

	UIEventListener.Get(self.cellInfoBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("arctic_expedition_cell_detail_window", {
			cell_id = self.cellId_
		})
	end

	UIEventListener.Get(self.buffIcon_).onClick = function ()
		if self.cellFunctionId_ ~= CellFunctionIds.CENTER then
			if not self.showBuffDetail_ then
				self.showBuffDetail_ = true
			else
				self.showBuffDetail_ = false
			end

			self.buffDetailGroup_:SetActive(self.showBuffDetail_)
		end
	end

	UIEventListener.Get(self.buffDetailHideBox_).onClick = function ()
		self.showBuffDetail_ = false

		self.buffDetailGroup_:SetActive(false)
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ARCTIC_EXPEDITION_HELP_CELL"
		})
	end

	self.eventProxy_:addEventListener(xyd.event.ARCTIC_EXPEDITION_BATTLE, handler(self, self.onBattleResult))
	self.eventProxy_:addEventListener(xyd.event.ARCTIC_EXPEDITION_GET_RECORDS, handler(self, self.onGetRecordList))
	self.eventProxy_:addEventListener(xyd.event.ARCTIC_EXPEDITION_RECORDS, handler(self, self.openRecordsWindow))
	self.eventProxy_:addEventListener(xyd.event.BOSS_BUY, handler(self, self.updateResEnergyNum))
end

function ArcticExpeditionBossInfoWindow:checkCanFight()
	local cellList = {}
	local cellPos = xyd.tables.arcticExpeditionCellsTable:getCellPos(self.cellId_)

	if self.cellInfo_.group == self.activityData_:getSelfGroup() then
		return true
	else
		xyd.tables.arcticExpeditionCellsTable:getCellAroud1(cellPos, cellList)

		for key, value in pairs(cellList) do
			if value == 1 then
				local info = self.activityData_:getCellInfo(tonumber(key))

				if info and info.group == self.activityData_:getSelfGroup() then
					return true
				end
			end
		end

		return false
	end
end

function ArcticExpeditionBossInfoWindow:updateResEnergyNum()
	self.resEnergyNum.text = self.activityData_:getStaNum()
end

function ArcticExpeditionBossInfoWindow:onGetRecordList(event)
	local records = xyd.decodeProtoBuf(event.data).records or {}
	self.tmpRecords_ = records
	self.tmpRecordIndex_ = 1
	self.tmpReport_ = {}
	self.sortList_ = {}

	for index, record in ipairs(records) do
		self.activityData_:reqBattleDetail(record.record_ids)
	end

	for n = #records, 1, -1 do
		local record = records[n]

		for i = 1, #record.record_ids do
			local id = record.record_ids[i]

			table.insert(self.sortList_, 1, id)
		end
	end

	if not records or #records <= 0 then
		xyd.WindowManager.get():openWindow("arctic_expedition_record_window2", {
			battle_info = {},
			cell_id = self.cellId_
		})
	end
end

function ArcticExpeditionBossInfoWindow:openRecordsWindow(event)
	local reports = xyd.decodeProtoBuf(event.data).reports

	if self.isAfterBattle_ then
		xyd.WindowManager.get():openWindow("arctic_expedition_record_window", {
			battle_info = reports,
			cell_id = self.cellId_,
			score = self.tmpScore
		})

		self.tmpSelfInfo = nil
		self.isAfterBattle_ = false
	else
		if not self.tmpReport_ then
			self.tmpReport_ = {}
		end

		local record_id = reports[1].record_id

		for _, record in ipairs(self.tmpRecords_) do
			if xyd.arrayIndexOf(record.record_ids, record_id) > 0 then
				for _, report in ipairs(reports) do
					table.insert(self.tmpReport_, 1, {
						report = report,
						self_info = record.info_detail,
						time = record.time,
						group = record.group
					})
				end

				break
			end
		end

		if self.tmpRecordIndex_ >= #self.tmpRecords_ then
			local copyList = {}

			for _, data in ipairs(self.tmpReport_) do
				for index, record_id in ipairs(self.sortList_) do
					if record_id == data.report.record_id then
						copyList[index] = data

						break
					end
				end
			end

			xyd.WindowManager.get():openWindow("arctic_expedition_record_window2", {
				battle_info = copyList,
				cell_id = self.cellId_
			})
		end

		self.tmpRecordIndex_ = self.tmpRecordIndex_ + 1
	end
end

function ArcticExpeditionBossInfoWindow:onBattleResult(event)
	self:updateCellInfo()

	local battle_info = event.data
	self.tmpSelfInfo = battle_info.info
	self.tmpScore = battle_info.score
	self.isAfterBattle_ = true

	self.activityData_:reqBattleDetail(battle_info.record_ids)
	self:updateResEnergyNum()
end

function ArcticExpeditionBossInfoWindow:updateCellInfo()
	self:onGetCellDetailInfo()
end

function ArcticExpeditionBossInfoWindow:initLayout()
	self.btnRecordLabel_.text = __("REOCRD")
	self.fightBtnLabel_.text = __("FIGHT")
	self.canFightBtnlabel_.text = __("ARCTIC_EXPEDITION_TEXT_12")
	self.titleLabel_.text = __("ARCTIC_EXPEDITION_TEXT_6")
	self.fightCostNum_.text = 1
	self.labelFormation_.text = __("ARCTIC_EXPEDITION_TEXT_11")
	self.cellHpText_.text = __("ARCTIC_EXPEDITION_TEXT_9")
	self.labelTips_.text = xyd.split(__("ARCTIC_EXPEDITION_TEXT_22"), "|")[self.activityData_:getEra()]

	self:initResItem()
	self:initSkillGroup()

	local cellImg = xyd.tables.arcticExpeditionCellsTypeTable:getIconImg(self.cellType_)

	xyd.setUISpriteAsync(self.cellImg_, nil, cellImg)

	local cellPos = xyd.tables.arcticExpeditionCellsTable:getCellPos(self.cellId_)
	self.cellPosLabel_.text = "(" .. cellPos[1] .. "," .. cellPos[2] .. ")"
	self.cellNameLabel_.text = xyd.tables.arcticExpeditionCellsTypeTextTable:getName(self.cellType_)

	self:onGetCellDetailInfo()
end

function ArcticExpeditionBossInfoWindow:initSkillGroup()
	local partner_id = xyd.tables.miscTable:getVal("expedition_boss_partner")
	local skill1 = xyd.tables.partnerTable:getEnergyID(partner_id)
	local skill2 = xyd.tables.partnerTable:getPasSkill(partner_id, 1)
	local skill3 = xyd.tables.partnerTable:getPasSkill(partner_id, 2)
	local skill4 = xyd.tables.partnerTable:getPasSkill(partner_id, 3)
	local skillList = {
		skill1,
		skill2,
		skill3,
		skill4
	}

	for i = 1, #skillList do
		local item = SkillIcon.new(self.skillGroup_.gameObject)

		item:SetLocalScale(0.8, 0.8, 1)
		item:setInfo(skillList[i], {
			showGroup = self.gSkillDesc,
			callback = function ()
				self:handleSkillTips(item)
			end
		})

		UIEventListener.Get(item.go).onSelect = function (go, onSelect)
			if onSelect == false then
				self:clearSkillTips(item)
			end
		end
	end

	self.skillGroup_:Reposition()
end

function ArcticExpeditionBossInfoWindow:clearSkillTips(icon)
	icon:showTips(false, self.gSkillDesc)
end

function ArcticExpeditionBossInfoWindow:handleSkillTips(icon)
	icon:showTips(true, self.gSkillDesc, true)
end

function ArcticExpeditionBossInfoWindow:initResItem()
	self.resItem = ResItem.new(self.groupResItem_.gameObject)

	self.resItem.go.transform:SetSiblingIndex(0)
	self.resItem:setInfo({
		hideBg = false,
		tableId = 2
	})
	self.resItem:showPlus()
	self.resItemList_:Reposition()
end

function ArcticExpeditionBossInfoWindow:updateResItemNum()
	self.resItem:updateNum()
end

function ArcticExpeditionBossInfoWindow:onGetCellDetailInfo()
	self.cellInfo_ = self.activityData_:getCellInfo(self.cellId_) or {}

	self:checkShowBuffGroup()
	self:showPartners()
	self:updateBtnInfo()

	local totalEnemy = xyd.tables.arcticExpeditionCellsTypeTable:getBattleCount(self.cellType_)
	self.cellHpLabel_.text = self.cellInfo_.num .. "/" .. totalEnemy
	self.cellHpProgress_.value = self.cellInfo_.num / totalEnemy
end

function ArcticExpeditionBossInfoWindow:updateBtnInfo()
end

function ArcticExpeditionBossInfoWindow:checkShowBuffGroup()
	local buffList = self.activityData_:getCellBuffAround(self.cellId_)

	if self.cellFunctionId_ == CellFunctionIds.CENTER then
		return
	end

	if not self.cellInfo_ or not buffList or #buffList <= 0 then
		self.buffGroup_:SetActive(false)
	else
		self.buffGroup_:SetActive(true)

		local hasCenterBuff = false
		local centerBuffList = xyd.tables.arcticExpeditionCellsTypeTable:getMapBuffs(6)
		local addHeight = 0

		for i = 1, #buffList do
			local buffId = buffList[i]

			if not hasCenterBuff and xyd.arrayIndexOf(centerBuffList, buffId) > 0 then
				hasCenterBuff = true
			end

			local buffDesc = xyd.tables.skillTable:getDesc(buffId)
			local newItem = NGUITools.AddChild(self.groupBuffList_.gameObject, self.buffDescItemRoot_)

			newItem:SetActive(true)

			local numLabel = newItem:ComponentByName("numLabel", typeof(UILabel))
			local descLabel = newItem:ComponentByName("descLabel", typeof(UILabel))
			numLabel.text = i
			descLabel.text = buffDesc

			if descLabel.height + 14 > 44 then
				addHeight = addHeight + descLabel.height + 14
			else
				addHeight = addHeight + 44
			end
		end

		self.groupBuffList_:Reposition()

		self.detailBg_.height = addHeight + 115

		if hasCenterBuff then
			xyd.setUISpriteAsync(self.showIcon_, nil, "arctic_expedition_cell_icon3")
		else
			xyd.setUISpriteAsync(self.showIcon_, nil, "arctic_expedition_cell_icon4")
		end
	end
end

function ArcticExpeditionBossInfoWindow:showPartners()
	local enemy_status = self.cellInfo_.enemy_status or {}
	local fight_times = self.cellInfo_.fight_times or 0
	local totalFightList = xyd.tables.arcticExpeditionCellsTypeTable:getBattleIDs(self.cellType_)
	local index = fight_times % #totalFightList + 1
	local battle_id = totalFightList[index]
	local monsters = xyd.tables.battleTable:getMonsters(battle_id)
	local stands = xyd.tables.battleTable:getStands(battle_id)
	local totalPower = 0
	local monsterList = {}

	for i = 1, 6 do
		local tableID = monsters[i]

		if tableID and tableID ~= 0 then
			local icon = self["hero" .. stands[i]]
			monsterList[stands[i]] = 1

			icon:SetActive(true)

			local monster = Monster.new()

			monster:populateWithTableID(tableID)

			totalPower = totalPower + monster:getPower()

			icon:setInfo(monster)

			if tableID == 22040501 then
				icon:setNoClick(true)
			end

			local statehp = 1

			for j = 1, #enemy_status do
				if enemy_status[j].pos == i then
					statehp = enemy_status[j].hp / 100

					break
				end
			end

			self["partnerHp" .. stands[i]].value = statehp
		end
	end

	for i = 1, 6 do
		if not monsterList[i] or monsterList[i] == 0 then
			self["hero" .. i]:SetActive(false)
			self["partnerHp" .. i].gameObject:SetActive(false)
		end
	end

	self.powerLabel_.text = totalPower
end

function ArcticExpeditionBossInfoWindow:showCenterCell()
	self.bgImg_.height = 660

	self.labelMass_.gameObject:SetActive(false)
	self.cellHpText_.gameObject:SetActive(false)
	self.cellHpProgress_.gameObject:SetActive(false)
	self.pointTotalText_.gameObject:SetActive(true)
	self.pointTotalLabel_.gameObject:SetActive(true)
	self.pointYesterdayText_.gameObject:SetActive(true)
	self.pointYesterdayLabel_.gameObject:SetActive(true)

	self.pointTotalText_.text = __("ARCTIC_EXPEDITION_TEXT_1")
	self.pointYesterdayText_.text = __("ARCTIC_EXPEDITION_TEXT_2")
	self.cellHpText_.text = __("ARCTIC_EXPEDITION_TEXT_9")
	local score, last_score = self.activityData_:getGroupScoreData()
	self.pointTotalLabel_.text = score or 0
	self.pointYesterdayLabel_.text = last_score or 0
end

function ArcticExpeditionBossInfoWindow:inCointInfo()
	local cellTypeList = self:getCellTypeList()

	self.campInfoGroup_:SetActive(true)

	self.tipsLabel1.text = __("ARCTIC_EXPEDITION_TEXT_3")
	self.tipsLabel2.text = __("ARCTIC_EXPEDITION_TEXT_4")
	self.tipsLabel3.text = __("ARCTIC_EXPEDITION_TEXT_5")

	for cell_type_id, num in pairs(cellTypeList) do
		local newItem = NGUITools.AddChild(self.grid_.gameObject, self.cellInfomeItemRoot_)
		local itemImg = newItem:ComponentByName("cellImg", typeof(UISprite))
		local nameLabel = newItem:ComponentByName("nameLabel", typeof(UILabel))
		local numLabel = newItem:ComponentByName("numLabel", typeof(UILabel))
		local pointLabel = newItem:ComponentByName("pointLabel", typeof(UILabel))
		local cellImgName = xyd.tables.arcticExpeditionCellsTypeTable:getIconImg(cell_type_id)

		xyd.setUISpriteAsync(itemImg, nil, cellImgName)

		nameLabel.text = xyd.tables.arcticExpeditionCellsTypeTable:getCellName(cell_type_id)
		numLabel.text = num
		local period = xyd.tables.arcticExpeditionCellsTypeTable:getScorePeriod(cell_type_id)

		if period and period > 0 then
			pointLabel.text = "+" .. math.floor(num * xyd.DAY_TIME / period)
		else
			pointLabel.text = " "
		end
	end

	self.grid_:Reposition()
	self.cellInfoScrollView_:ResetPosition()
end

function ArcticExpeditionBossInfoWindow:getCellTypeList()
	local activityData = self.activityData_
	local mapInfo = activityData:getMapInfo()
	local typeList = {}

	for cell_id, cell_info in pairs(mapInfo) do
		if cell_info.group == activityData:getSelfGroup() then
			local type = xyd.tables.arcticExpeditionCellsTable:getCellType(tonumber(cell_id))

			if not typeList[type] then
				typeList[type] = 1
			else
				typeList[type] = typeList[type] + 1
			end
		end
	end

	return typeList
end

return ArcticExpeditionBossInfoWindow
