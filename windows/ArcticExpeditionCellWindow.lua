local ArcticExpeditionCellWindow = class("ArcticExpeditionCellWindow", import(".BaseWindow"))
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local Monster = import("app.models.Monster")
local ResItem = import("app.components.ResItem")
local CountDown = import("app.components.CountDown")
local CellFunctionIds = {
	NORMAL = 1,
	CENTER = 5
}
local GroupColor = {
	Color.New2(3903474175.0),
	Color.New2(4016532991.0),
	Color.New2(2464115199.0),
	Color.New2(1390213375)
}

function ArcticExpeditionCellWindow:ctor(name, params)
	ArcticExpeditionCellWindow.super.ctor(self, name, params)

	self.cellId_ = tonumber(params.cell_id)
	self.cellType_ = xyd.tables.arcticExpeditionCellsTable:getCellType(self.cellId_)
	self.cellFunctionId_ = xyd.tables.arcticExpeditionCellsTypeTable:getFunctionID(self.cellType_)
	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.ARCTIC_EXPEDITION)
	self.cellInfo_ = self.activityData_:getCellInfo(params.cell_id)
end

function ArcticExpeditionCellWindow:initWindow()
	self:getComponent()
	self:updateResEnergyNum()
	self:initLayout()
	self:regisetr()
end

function ArcticExpeditionCellWindow:updateResEnergyNum()
	self.resEnergyNum.text = self.activityData_:getStaNum()
end

function ArcticExpeditionCellWindow:getComponent()
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
	self.guidePos = winTrans.gameObject
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
	self.effectRoot_ = self.cellInfoGroup_:NodeByName("cellHpProgress/effectRoot").gameObject
	self.cellHpText_ = self.cellInfoGroup_:ComponentByName("cellHpText", typeof(UILabel))
	self.labelMass_ = self.cellInfoGroup_:ComponentByName("labelMass", typeof(UILabel))
	self.pointTotalText_ = self.cellInfoGroup_:ComponentByName("pointTotalText", typeof(UILabel))
	self.pointTotalLabel_ = self.cellInfoGroup_:ComponentByName("pointTotalLabel", typeof(UILabel))
	self.pointYesterdayText_ = self.cellInfoGroup_:ComponentByName("pointYesterdayText", typeof(UILabel))
	self.pointYesterdayLabel_ = self.cellInfoGroup_:ComponentByName("pointYesterdayLabel", typeof(UILabel))
	self.groupIcon_ = self.cellInfoGroup_:ComponentByName("cellGroupBg/groupIcon", typeof(UISprite))
	self.groupNameLabel_ = self.cellInfoGroup_:ComponentByName("cellGroupBg/groupNameLabel", typeof(UILabel))
	self.cellPosLabel_ = self.cellInfoGroup_:ComponentByName("cellPos", typeof(UILabel))
	self.cellInfoBtn_ = self.cellInfoGroup_:NodeByName("cellInfoPos/cellInfoBtn").gameObject
	self.cellNameLabel_ = self.cellInfoGroup_:ComponentByName("cellName", typeof(UILabel))
	self.cellImg_ = self.cellInfoGroup_:ComponentByName("cellImg", typeof(UISprite))
	self.campInfoGroup_ = winTrans:NodeByName("campInfoGroup").gameObject
	self.tipsLabel1 = self.campInfoGroup_:ComponentByName("tipsLabel1", typeof(UILabel))
	self.tipsLabel2 = self.campInfoGroup_:ComponentByName("tipsLabel2", typeof(UILabel))
	self.tipsLabel3 = self.campInfoGroup_:ComponentByName("tipsLabel3", typeof(UILabel))
	self.cellInfomeItemRoot_ = self.campInfoGroup_:NodeByName("cellInfomeItem").gameObject
	self.cellInfoScrollView_ = self.campInfoGroup_:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = self.campInfoGroup_:ComponentByName("scrollView/grid", typeof(UIGrid))
	self.buffGroup_ = winTrans:NodeByName("buffGroup").gameObject
	self.buffIcon_ = self.buffGroup_:NodeByName("buffIcon").gameObject
	self.clickBox_ = self.buffGroup_:NodeByName("buffDetailGroup/clickBox").gameObject
	self.buffText = self.buffGroup_:ComponentByName("buffText", typeof(UILabel))
	self.buffText2 = self.buffGroup_:ComponentByName("buffText2", typeof(UILabel))
	self.buffText3 = self.buffGroup_:ComponentByName("buffDetailGroup/buffText3", typeof(UILabel))
	self.buffText4 = self.buffGroup_:ComponentByName("buffDetailGroup/buffText4", typeof(UILabel))
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
end

function ArcticExpeditionCellWindow:regisetr()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.resEnergyPlus).onClick = function ()
		xyd.WindowManager.get():openWindow("arctic_expedition_buy_window")
	end

	UIEventListener.Get(self.fightBtn_).onClick = function ()
		self:onClickFightBtn()
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ARCTIC_EXPEDITION_HELP_CELL"
		})
	end

	UIEventListener.Get(self.btnRecord_).onClick = function ()
		local msg = messages_pb.arctic_expedition_get_records_req()
		msg.cell_id = self.cellId_
		msg.activity_id = xyd.ActivityID.ARCTIC_EXPEDITION

		xyd.Backend.get():request(xyd.mid.ARCTIC_EXPEDITION_GET_RECORDS, msg)

		self.btnRecord_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
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

	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.updateResItemNum))
	self.eventProxy_:addEventListener(xyd.event.ARCTIC_EXPEDITION_BATTLE, handler(self, self.onBattleResult))
	self.eventProxy_:addEventListener(xyd.event.ARCTIC_EXPEDITION_GET_RECORDS, handler(self, self.onGetRecordList))
	self.eventProxy_:addEventListener(xyd.event.ARCTIC_EXPEDITION_RECORDS, handler(self, self.openRecordsWindow))
	self.eventProxy_:addEventListener(xyd.event.BOSS_BUY, handler(self, self.updateResEnergyNum))
	self.eventProxy_:addEventListener(xyd.event.SYS_BROADCAST, function (event)
		local data = xyd.decodeProtoBuf(event.data)
		local cell_id = data.table_id
		local playerName = data.player_name
		local win = xyd.WindowManager.get():getWindow("exskill_guide_window")

		if win then
			return
		end

		if playerName ~= xyd.Global.playerName and tonumber(cell_id) == self.cellId_ and xyd.SysBroadcast.ACTIVITY_EXPEDITION == data.broadcast_type then
			xyd.alertConfirm(__("ARCTIC_EXPEDITION_TEXT_61"), function ()
				self:close()
			end)
		end
	end)
end

function ArcticExpeditionCellWindow:onClickFightBtn()
	local function fightFunction()
		local fightParams = {
			showSkip = false,
			battleType = xyd.BattleType.ARCTIC_EXPEDITION,
			cell_id = self.cellId_
		}

		xyd.WindowManager:get():openWindow("battle_formation_trial_window", fightParams)
	end

	if self.isSafe_ and self.isSafe_ == 1 and self.cellInfo_.group ~= self.activityData_:getSelfGroup() then
		xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_46"))

		return
	end

	if not self.activityData_:checkCanFightTime() then
		xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_36"))

		return
	end

	if self.activityData_.detail.sta <= 0 then
		xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_39"))

		return
	end

	if -self.activityData_:startTime() + xyd.getServerTime() < xyd.DAY_TIME or self.activityData_:getEndTime() - xyd.getServerTime() <= xyd.DAY_TIME then
		xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_65"))

		return
	end

	if self.cellInfo_.group == self.activityData_:getSelfGroup() and xyd.tables.arcticExpeditionCellsTypeTable:getBattleCount2(self.cellType_) <= self.cellInfo_.num then
		xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_37"))

		return
	end

	if self:checkCanFight() then
		fightFunction()
	else
		local guideValue = xyd.db.misc:getValue("arctic_expedition_guide_fight")

		if not guideValue or tonumber(guideValue) <= 0 then
			xyd.WindowManager:get():openWindow("exskill_guide_window", {
				wnd = self,
				table = xyd.tables.timeCloisterGuideTable,
				guide_type = xyd.GuideType.ARCTIC_EXPEDITION_2
			})

			local win = xyd.WindowManager.get():getWindow("arctic_expedition_main_window")

			if win then
				win:jumpToOtherCell()
			end

			xyd.db.misc:setValue({
				value = "1",
				key = "arctic_expedition_guide_fight"
			})
		end

		xyd.alertTips(__("ARCTIC_EXPEDITION_TEXT_38"))
	end
end

function ArcticExpeditionCellWindow:checkCanFight()
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

function ArcticExpeditionCellWindow:onGetRecordList(event)
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

		self.btnRecord_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end
end

function ArcticExpeditionCellWindow:openRecordsWindow(event)
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

			self.btnRecord_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		end

		self.tmpRecordIndex_ = self.tmpRecordIndex_ + 1
	end
end

function ArcticExpeditionCellWindow:onBattleResult(event)
	local battle_info = event.data
	self.tmpSelfInfo = battle_info.info
	self.tmpScore = battle_info.score
	self.isAfterBattle_ = true

	self.activityData_:reqBattleDetail(battle_info.record_ids)
	self:updateCellInfo()
	self:updateResEnergyNum()
end

function ArcticExpeditionCellWindow:updateCellInfo()
	self:onGetCellDetailInfo()
end

function ArcticExpeditionCellWindow:initLayout()
	local guideWin = xyd.WindowManager.get():getWindow("exskill_guide_window")

	if guideWin then
		function self.onClickEscBack()
		end
	end

	self.btnRecordLabel_.text = __("REOCRD")
	self.fightBtnLabel_.text = __("FIGHT")
	self.canFightBtnlabel_.text = __("ARCTIC_EXPEDITION_TEXT_12")
	self.titleLabel_.text = __("ARCTIC_EXPEDITION_TEXT_6")
	self.buffText.text = __("ARCTIC_EXPEDITION_TEXT_68")
	self.buffText3.text = __("ARCTIC_EXPEDITION_TEXT_68")
	self.buffText2.text = __("ARCTIC_EXPEDITION_TEXT_8")
	self.buffText4.text = __("ARCTIC_EXPEDITION_TEXT_69")
	self.fightCostNum_.text = 1
	self.labelFormation_.text = __("ARCTIC_EXPEDITION_TEXT_11")

	if self.cellInfo_.group == self.activityData_:getSelfGroup() then
		self.fightBtnLabel_.text = __("ARCTIC_EXPEDITION_TEXT_41")
	end

	if self.cellFunctionId_ == CellFunctionIds.CENTER then
		self:showCenterCell()
		self.groupResItem_:SetActive(false)
	else
		self:showNormalCell()
		self.groupResItem_:SetActive(true)
		self:initResItem()
	end

	local cellImg = xyd.tables.arcticExpeditionCellsTypeTable:getIconImg(self.cellType_)

	xyd.setUISpriteAsync(self.cellImg_, nil, cellImg)

	local cellPos = xyd.tables.arcticExpeditionCellsTable:getCellPos(self.cellId_)
	self.cellPosLabel_.text = "(" .. cellPos[1] .. "," .. cellPos[2] .. ")"
	self.cellNameLabel_.text = xyd.tables.arcticExpeditionCellsTypeTextTable:getName(self.cellType_)

	self:onGetCellDetailInfo()
end

function ArcticExpeditionCellWindow:initResItem()
	self.resItem = ResItem.new(self.groupResItem_.gameObject)

	self.resItem.go.transform:SetSiblingIndex(0)
	self.resItem:setInfo({
		hideBg = false,
		tableId = 2
	})
	self.resItem:showPlus()
	self.resItemList_:Reposition()
end

function ArcticExpeditionCellWindow:updateResItemNum()
	self.resItem:updateNum()
end

function ArcticExpeditionCellWindow:onGetCellDetailInfo()
	self.cellInfo_ = self.activityData_:getCellInfo(self.cellId_) or {}

	self:checkShowBuffGroup()
	self:updateGroupShow()

	if self.cellFunctionId_ == CellFunctionIds.CENTER then
		self:inCointInfo()
	else
		self:showPartners()
		self:updateBtnInfo()

		local totalEnemy = nil

		if self.cellInfo_.group == 4 then
			totalEnemy = xyd.tables.arcticExpeditionCellsTypeTable:getBattleCount(self.cellType_)
		else
			totalEnemy = xyd.tables.arcticExpeditionCellsTypeTable:getBattleCount2(self.cellType_)
		end

		local spineName = nil

		if self.cellInfo_.group == 4 and xyd.tables.arcticExpeditionCellsTypeTable:getNeutralChange(self.cellType_) < 0 then
			spineName = "fx_ept_battle_shrink"
		elseif self.activityData_:getEra() >= 3 and xyd.tables.arcticExpeditionCellsTypeTable:getThirdShrink(self.cellType_) < 0 then
			spineName = "fx_ept_battle_shrink"
		end

		self.cellHpLabel_.text = self.cellInfo_.num .. "/" .. totalEnemy
		self.cellHpProgress_.value = self.cellInfo_.num / totalEnemy

		if spineName then
			self.effectRoot_:SetActive(true)

			if not self.effectShrink_ then
				self.effectShrink_ = xyd.Spine.new(self.effectRoot_)

				self.effectShrink_:setInfo(spineName, function ()
					self.effectShrink_:play("texiao01", 0, 1)
					self.effectShrink_:SetLocalPosition(-235 + self.cellInfo_.num / totalEnemy * 460, 12, 0)
				end)
			else
				self.effectShrink_:play("texiao01", 0, 1)
				self.effectShrink_:SetLocalPosition(-235 + self.cellInfo_.num / totalEnemy * 460, 12, 0)
			end
		else
			self.effectRoot_:SetActive(false)
		end
	end

	local selfGroup = self.activityData_:getSelfGroup()

	if self.cellInfo_["rally" .. selfGroup] and self.cellInfo_["rally" .. selfGroup].end_time and xyd.getServerTime() < self.cellInfo_["rally" .. selfGroup].end_time then
		self.labelMass_.gameObject:SetActive(true)

		self.labelMass_.text = __("ARCTIC_EXPEDITION_TEXT_10", self.cellInfo_["rally" .. selfGroup].fight_times)

		self:waitForTime(self.cellInfo_["rally" .. selfGroup].end_time - xyd.getServerTime(), function ()
			self.labelMass_.gameObject:SetActive(false)
		end)
	end
end

function ArcticExpeditionCellWindow:updateBtnInfo()
	local isSafe = self.cellInfo_.safe
	local safe_time = self.cellInfo_.safe_time

	if isSafe and isSafe >= 1 and xyd.getServerTime() < safe_time + xyd.tables.arcticExpeditionCellsTypeTable:getTruceTime(self.cellType_) and self.cellInfo_.group ~= self.activityData_:getSelfGroup() then
		self.fightBtn_:SetActive(false)
		self.canFightBtn_:SetActive(true)
		xyd.applyChildrenGrey(self.fightBtn_)

		local timeCount = CountDown.new(self.canFightBtnTime_)

		timeCount:setInfo({
			duration = safe_time + xyd.tables.arcticExpeditionCellsTypeTable:getTruceTime(self.cellType_) - xyd.getServerTime()
		})
		self:waitForTime(safe_time + xyd.tables.arcticExpeditionCellsTypeTable:getTruceTime(self.cellType_) - xyd.getServerTime(), function ()
			self.fightBtn_:SetActive(true)
			self.canFightBtn_:SetActive(false)
		end)
	end
end

function ArcticExpeditionCellWindow:playOpenAnimation(callback)
	function self.onClickCloseButton()
	end

	ArcticExpeditionCellWindow.super.playOpenAnimation(self, function ()
		function self.onClickCloseButton()
			if self.params_ and self.params_.lastWindow and self.name_ ~= "smithy_window" and self.name_ ~= "enhance_window" then
				xyd.WindowManager.get():openWindow(self.params_.lastWindow)
			end

			self:close()
		end

		callback()
	end)
end

function ArcticExpeditionCellWindow:updateGroupShow()
	self.groupID_ = self.cellInfo_.group
	self.groupNameLabel_.text = __("ARCTIC_EXPEDITION_GROUP_" .. self.groupID_)

	xyd.setUISpriteAsync(self.groupIcon_, nil, "arctic_expedition_cell_group_icon_" .. self.groupID_)

	self.groupNameLabel_.color = GroupColor[self.groupID_]
	self.groupImg_.color = GroupColor[self.groupID_]
end

function ArcticExpeditionCellWindow:checkShowBuffGroup()
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

		if not self.buffItemList_ then
			self.buffItemList_ = {}
		end

		for i = 1, #buffList do
			local buffId = buffList[i]

			if not hasCenterBuff and xyd.arrayIndexOf(centerBuffList, buffId) > 0 then
				hasCenterBuff = true
			end

			local buffDesc = xyd.tables.skillTable:getDesc(buffId)
			local newItem = nil

			if not self.buffItemList_[i] then
				newItem = NGUITools.AddChild(self.groupBuffList_.gameObject, self.buffDescItemRoot_)
				self.buffItemList_[i] = newItem
			else
				newItem = self.buffItemList_[i]
			end

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

		for i = 1, #self.buffItemList_ do
			if i > #buffList then
				self.buffItemList_[i]:SetActive(false)
			else
				self.buffItemList_[i]:SetActive(true)
			end
		end

		self.groupBuffList_:Reposition()

		self.detailBg_.height = addHeight + 125

		if hasCenterBuff then
			xyd.setUISpriteAsync(self.showIcon_, nil, "arctic_expedition_cell_icon3")
		else
			xyd.setUISpriteAsync(self.showIcon_, nil, "arctic_expedition_cell_icon4")
		end
	end
end

function ArcticExpeditionCellWindow:showNormalCell()
	self.cellHpText_.gameObject:SetActive(true)
	self.cellHpProgress_.gameObject:SetActive(true)
	self.pointTotalText_.gameObject:SetActive(false)
	self.pointTotalLabel_.gameObject:SetActive(false)
	self.pointYesterdayText_.gameObject:SetActive(false)
	self.pointYesterdayLabel_.gameObject:SetActive(false)
	self.labelMass_.gameObject:SetActive(false)

	self.cellHpText_.text = __("ARCTIC_EXPEDITION_TEXT_9")

	self.enemyGroup_:SetActive(true)
	self.btnRecord_:SetActive(true)

	if not self:checkCanFight() or self.cellInfo_.group == self.activityData_:getSelfGroup() and xyd.tables.arcticExpeditionCellsTypeTable:getBattleCount2(self.cellType_) <= self.cellInfo_.num or -self.activityData_:startTime() + xyd.getServerTime() < xyd.DAY_TIME or self.activityData_:getEndTime() - xyd.getServerTime() <= xyd.DAY_TIME then
		xyd.applyChildrenGrey(self.fightBtn_)
	end
end

function ArcticExpeditionCellWindow:showPartners()
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

			local statehp = 1

			for j = 1, #enemy_status do
				if enemy_status[j].pos == i then
					statehp = enemy_status[j].hp / 100

					break
				end
			end

			if statehp <= 0 then
				icon:setGrey()
			else
				icon:setOrigin()
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

function ArcticExpeditionCellWindow:showCenterCell()
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
	local score, last_score = self.activityData_:getGroupScoreData(self.cellInfo_.group)
	self.pointTotalLabel_.text = score or 0
	self.pointYesterdayLabel_.text = last_score or 0
end

function ArcticExpeditionCellWindow:inCointInfo()
	local cellTypeList = self:getCellTypeList()

	self.campInfoGroup_:SetActive(true)
	self.cellInfoBtn_:SetActive(false)

	self.tipsLabel1.text = __("ARCTIC_EXPEDITION_TEXT_3")
	self.tipsLabel2.text = __("ARCTIC_EXPEDITION_TEXT_4")
	self.tipsLabel3.text = __("ARCTIC_EXPEDITION_TEXT_5")

	for cell_type_id, num in pairs(cellTypeList) do
		local newItem = NGUITools.AddChild(self.grid_.gameObject, self.cellInfomeItemRoot_)
		local lineImg = newItem:ComponentByName("groupLine", typeof(UISprite))
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
			pointLabel.text = "+" .. math.floor(num * xyd.DAY_TIME / period) .. __("ARCTIC_EXPEDITION_TEXT_59")
		else
			pointLabel.text = " "
		end

		lineImg.color = GroupColor[self.groupID_]
	end

	self.grid_:Reposition()
	self.cellInfoScrollView_:ResetPosition()
end

function ArcticExpeditionCellWindow:getCellTypeList()
	local activityData = self.activityData_
	local mapInfo = activityData:getMapInfo()
	local typeList = {}

	for cell_id, cell_info in pairs(mapInfo) do
		if cell_info.group == self.cellInfo_.group then
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

return ArcticExpeditionCellWindow
