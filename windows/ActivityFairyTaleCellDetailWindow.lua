local ActivityFairyTaleCellDetailWindow = class("ActivityFairyTaleCellDetailWindow", import(".BaseWindow"))
local SkillIcon = import("app.components.SkillIcon")
local cjson = require("cjson")
local cellType = {
	BATTLE = 2,
	CHOOSE = 4,
	START = 1,
	HELP = 3,
	BOSS = 5,
	NONE = 0
}

function ActivityFairyTaleCellDetailWindow:ctor(name, params)
	ActivityFairyTaleCellDetailWindow.super.ctor(self, name, params)

	self.cellType_ = params.cellType
	self.cellId_ = params.cell_id
	self.mapId_ = params.map_id
	self.typeContent_ = xyd.tables.activityFairyTaleCellTable:getCellContent(self.cellId_)
	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE)

	if self.activityData_:checkRefreshCell(self.cellId_) then
		xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE):reqCellInfo(self.cellId_)
	else
		self.getCellInfo_ = true
	end
end

function ActivityFairyTaleCellDetailWindow:initWindow()
	ActivityFairyTaleCellDetailWindow.super.initWindow(self)
	self:getComponent()

	self.goBtnLabel_.text = __("FIGHT")

	self:initCell()
	self:regisetr()
end

function ActivityFairyTaleCellDetailWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.winTitle_ = winTrans:ComponentByName("winTitle", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.goBtn_ = winTrans:NodeByName("goBtn").gameObject
	self.costLabel_ = winTrans:ComponentByName("goBtn/e:image/label", typeof(UILabel))
	self.goBtnLabel_ = winTrans:ComponentByName("goBtn/label", typeof(UILabel))
	self.cellName_ = winTrans:ComponentByName("bossInfoGroup/cellName", typeof(UILabel))
	self.recordBtn_ = winTrans:NodeByName("bossInfoGroup/recordBtn").gameObject
	self.cellIcon_ = winTrans:ComponentByName("bossInfoGroup/bossIconRoot", typeof(UISprite))
	self.progressBar_ = winTrans:ComponentByName("bossInfoGroup/progressBar", typeof(UIProgressBar))
	self.progressLabel_ = winTrans:ComponentByName("bossInfoGroup/progressBar/labelNum", typeof(UILabel))
	self.cellDesc_ = winTrans:ComponentByName("cellInfoGroup/infoScrollView/desc", typeof(UILabel))
	self.awardsGroup_ = winTrans:ComponentByName("awardGroup", typeof(UIGrid))
	self.costLabel_.text = xyd.split(xyd.tables.miscTable:getVal("activity_fairytale_energy_cost"), "#", true)[2]
	self.bossSkillGroup_ = winTrans:ComponentByName("cellInfoGroup/bossSkillGrid", typeof(UIGrid))
	self.bossSkillInfo_ = winTrans:NodeByName("cellInfoGroup/bossSkillInfoGroup").gameObject
	self.bossSkillBox_ = winTrans:NodeByName("cellInfoGroup/box").gameObject
end

function ActivityFairyTaleCellDetailWindow:regisetr()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.goBtn_).onClick = function ()
		self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE)
		local sta = xyd.models.backpack:getItemNumByID(xyd.ItemID.FAIRY_TALE_ENERGY)
		local staCost = xyd.split(xyd.tables.miscTable:getVal("activity_fairytale_energy_cost"), "#", true)[2]

		if sta < staCost then
			xyd.showToast(__("ENTRANCE_TEST_FIGHT_TIP"))

			return
		end

		if self.cellType_ == cellType.BOSS or self.cellType_ == cellType.BATTLE then
			local npcList = self:getNpcList()

			xyd.WindowManager.get():openWindow("activity_fairy_tale_formation_window", {
				battleType = xyd.BattleType.FAIRY_TALE,
				cell_id = self.cellId_,
				npc_list = npcList
			})
		elseif self.cellType_ == cellType.HELP and self.getCellInfo_ then
			local partners = nil
			local detail = self.activityData_:getCellInfoByTableId(self.cellId_).detail
			local partners = nil

			if detail then
				partners = xyd.split(detail, "|", true)
			end

			xyd.WindowManager.get():openWindow("friend_boss_my_assistant_setting_window", {
				type = "fairy_tale",
				cell_id = self.cellId_,
				selected_partners = partners
			})
		end

		if self.cellType_ == cellType.CHOOSE then
			local detail = self.activityData_:getCellInfoByTableId(self.cellId_).detail

			if detail and detail.index then
				xyd.openWindow("activity_fairy_tale_selection_window", {
					id = self.typeContent_,
					eventId = detail.index,
					cell_id = self.cellId_
				})
			elseif self.chooseId then
				xyd.openWindow("activity_fairy_tale_selection_window", {
					id = self.typeContent_,
					eventId = self.chooseId,
					cell_id = self.cellId_
				})
			else
				local msg = messages_pb.fairy_start_option_req()
				msg.activity_id = xyd.ActivityID.FAIRY_TALE
				msg.cell_id = self.cellId_

				xyd.Backend.get():request(xyd.mid.FAIRY_START_OPTION, msg)
			end
		end
	end

	UIEventListener.Get(self.recordBtn_).onClick = function ()
		if self.getCellInfo_ then
			local battle_results = self.activityData_:getCellInfoByTableId(self.cellId_).battle_results
			local records = {}
			local reports = {}

			for i = 1, 3 do
				local battle_result = battle_results[i]

				if battle_result and battle_result ~= "" then
					local data = cjson.decode(battle_result)
					records[i] = {
						lev = data.lev,
						avatar_frame_id = data.avatar_frame_id,
						player_name = data.player_name,
						avatar_id = data.avatar_id
					}
					reports[i] = data
				end
			end

			xyd.WindowManager.get():openWindow("activity_fairy_tale_view_window", {
				records = records,
				reports = reports
			})
		end
	end

	UIEventListener.Get(self.bossSkillBox_).onClick = handler(self, self.clearSkillTips)

	self.eventProxy_:addEventListener(xyd.event.FAIRY_CHALLENGE, handler(self, self.onCellChallenge))
	self.eventProxy_:addEventListener(xyd.event.ERROR_MESSAGE, handler(self, self.onError))
	self.eventProxy_:addEventListener(xyd.event.FAIRY_START_OPTION, handler(self, self.onFirstChoose))
	self.eventProxy_:addEventListener(xyd.event.GET_CELL_INFO, handler(self, self.onCellInfo))
end

function ActivityFairyTaleCellDetailWindow:onCellInfo()
	self.getCellInfo_ = true
end

function ActivityFairyTaleCellDetailWindow:onError(event)
	local errorCode = event.data.error_code
	local errorMid = event.data.error_mid

	if tonumber(errorCode) == 6047 then
		xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE):reqMapInfo(self.mapId_)
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ActivityFairyTaleCellDetailWindow:onCellChallenge(event)
	local data = event.data

	if data.is_video then
		return
	end

	self:updateHp()

	local cellInfo = self.activityData_:getCellInfoByTableId(self.cellId_)

	if cellInfo.is_completed and cellInfo.is_completed == 1 then
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	self.chooseId = nil
end

function ActivityFairyTaleCellDetailWindow:getNpcList()
	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE)
	local mapId = self.activityData_.detail.map_id
	local unLockMaps = self.activityData_.detail.map_infos[mapId].unlock_ids
	unLockMaps = xyd.split(unLockMaps, "|")
	local npcList = {}

	for i = 1, #unLockMaps do
		local mapId = unLockMaps[i]

		if mapId and mapId ~= "" then
			local npcId = xyd.tables.activityFairyTaleTable:getNpc(unLockMaps[i])

			table.insert(npcList, npcId)
		end
	end

	return npcList
end

function ActivityFairyTaleCellDetailWindow:initCell()
	self.cellName_.text = xyd.tables.activityFairyTaleCellTable:getName(self.cellId_)

	if self.mapId_ == 6 and self.cellType_ == cellType.BOSS then
		self.cellDesc_.text = " "
		self.bossSkillItem_ = {}

		self:initBossSkill()
	else
		self.cellDesc_.text = xyd.tables.activityFairyTaleCellTable:getDesc(self.cellId_)
	end

	if self.cellType_ == cellType.BATTLE or self.cellType_ == cellType.BOSS then
		self.recordBtn_:SetActive(true)
	else
		self.recordBtn_:SetActive(false)
	end

	local avaterId = nil

	if self.cellType_ == cellType.BATTLE then
		self.winTitle_.text = __("FAIRY_TALE_BATTLE_TITLE")
		avaterId = xyd.tables.activityFairyTaleBattleTable:getAvatarId(self.typeContent_)
	elseif self.cellType_ == cellType.BOSS then
		self.winTitle_.text = __("FAIRY_TALE_BOSS_CHALLENGE")
		avaterId = xyd.tables.activityFairyTaleBattleTable:getAvatarId(self.typeContent_)
	elseif self.cellType_ == cellType.CHOOSE then
		self.winTitle_.text = __("FAIRY_TALE_SELECT_TITLE")
		avaterId = xyd.tables.activityFairyTaleOptionTable:getAvatarId(self.typeContent_)
	elseif self.cellType_ == cellType.HELP then
		self.winTitle_.text = __("FAIRY_TALE_HELP_TITLE")
		avaterId = xyd.tables.activityFairyTaleSupportTable:getAvatarId(self.typeContent_)
	end

	if avaterId and avaterId > 0 then
		xyd.setUISpriteAsync(self.cellIcon_, nil, "partner_avatar_" .. avaterId)
	end

	xyd.getItemIcon({
		itemID = 167,
		uiRoot = self.awardsGroup_.gameObject
	})
	self:updateHp()
end

function ActivityFairyTaleCellDetailWindow:initBossSkill()
	local skillIds = xyd.tables.miscTable:getVal("activity_fairytale_boss_skill")
	skillIds = xyd.split(skillIds, "|")

	for i = 1, #skillIds do
		local item = SkillIcon.new(self.bossSkillGroup_.gameObject)

		item:setScale(0.8, 0.8, 0.8)
		item:setInfo(skillIds[i], {
			showGroup = self.bossSkillInfo_,
			callback = function ()
				self:clearSkillTips()
				item:showTips(true, item.showGroup, true)
				self.bossSkillBox_:SetActive(true)
			end
		})
		table.insert(self.bossSkillItem_, item)
	end

	self.bossSkillGroup_:Reposition()
end

function ActivityFairyTaleCellDetailWindow:clearSkillTips()
	for _, item in ipairs(self.bossSkillItem_) do
		item:showTips(false, item.showGroup)
	end

	self.bossSkillBox_:SetActive(false)
end

function ActivityFairyTaleCellDetailWindow:updateHp()
	local totalHp = nil
	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE)
	local cellInfo = self.activityData_:getCellInfoByTableId(self.cellId_)

	if self.cellType_ == cellType.BATTLE or self.cellType_ == cellType.BOSS then
		totalHp = xyd.tables.activityFairyTaleBattleTable:getTotalHp(self.typeContent_) or 1
		local value = tonumber(cellInfo.value) or 0

		if value < 0 then
			value = 0
		end

		local cellInfo = self.activityData_:getCellInfoByTableId(self.cellId_)

		if cellInfo.is_completed and cellInfo.is_completed == 1 then
			self.progressLabel_.text = math.ceil(0 / totalHp * 100) .. "%"
			self.progressBar_.value = 0
		elseif value == 0 then
			self.progressLabel_.text = "100%"
			self.progressBar_.value = 1
		else
			local progressValue = value / totalHp
			progressValue = xyd.checkCondition(progressValue > 0.99, 0.99, progressValue)
			self.progressLabel_.text = math.ceil(progressValue * 100) .. "%"
			self.progressBar_.value = progressValue
		end

		return
	elseif self.cellType_ == cellType.CHOOSE then
		totalHp = xyd.tables.activityFairyTaleOptionTable:getHp(self.typeContent_)
	elseif self.cellType_ == cellType.HELP then
		totalHp = xyd.tables.activityFairyTaleSupportTable:getTotalHp(self.typeContent_)
	end

	totalHp = totalHp or 1
	local value = tonumber(cellInfo.value) or 0

	if totalHp < value then
		value = totalHp
	end

	local progressValue = (totalHp - value) / totalHp
	progressValue = xyd.checkCondition(progressValue > 0.99, 0.99, progressValue)

	if value == 0 then
		progressValue = 1
	end

	self.progressLabel_.text = math.ceil(progressValue * 100) .. "%"
	self.progressBar_.value = progressValue
end

function ActivityFairyTaleCellDetailWindow:onFirstChoose(event)
	self.chooseId = event.data.index

	xyd.openWindow("activity_fairy_tale_selection_window", {
		id = self.typeContent_,
		eventId = self.chooseId,
		cell_id = self.cellId_
	})
end

return ActivityFairyTaleCellDetailWindow
