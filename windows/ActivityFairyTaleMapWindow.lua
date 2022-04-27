local ActivityFairyTaleMapWindow = class("ActivityFairyTaleMapWindow", import(".BaseWindow"))
local BaseComponent = import("app.components.BaseComponent")
local ActivityFairyTaleMapWeatherTips = class("ActivityFairyTaleMapWeatherTips", BaseComponent)
local CellItem = class("CellItem", import("app.components.CopyComponent"))
local WindowTop = import("app.components.WindowTop")
local cjson = require("cjson")
local CellType = {
	BATTLE = 2,
	CHOOSE = 4,
	START = 1,
	HELP = 3,
	BOSS = 5,
	NONE = 0
}

function ActivityFairyTaleMapWeatherTips:ctor(parentGo)
	ActivityFairyTaleMapWeatherTips.super.ctor(self, parentGo)
	self:getUIComponent()
end

function ActivityFairyTaleMapWeatherTips:getPrefabPath()
	return "Prefabs/Components/friend_team_boss_weather_tips"
end

function ActivityFairyTaleMapWeatherTips:getUIComponent()
	local content = self.go:NodeByName("content").gameObject
	self.skillName = content:ComponentByName("skillName", typeof(UILabel))
	self.desc = content:ComponentByName("desc", typeof(UILabel))
end

function ActivityFairyTaleMapWeatherTips:setInfo(info, mapId)
	local mapInfo = info
	local index = mapInfo.event_index
	local startTime = xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE):startTime()
	local day = math.floor((xyd.getServerTime() - startTime) / 86400) + 1
	local eventId = xyd.tables.activityFairyTaleEventTable:getEventId(mapId, day)

	if eventId and eventId > 0 then
		local st = xyd.tables.activityFairyTaleEventTextTable
		local name = st:getName(tostring(eventId))
		name = xyd.split(name, "|")
		self.skillName.text = __(name[index])
		local desc = st:getDesc(tostring(eventId))
		desc = xyd.split(desc, "|")
		self.desc.text = desc[index]
	end
end

function ActivityFairyTaleMapWindow:ctor(name, params)
	ActivityFairyTaleMapWindow.super.ctor(self, name, params)

	self.mapId_ = params.index
	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE)
	self.cellItemList_ = {}
	self.cellGroupList_ = {}
	self.unlockCellList_ = {}
	self.curScale_ = 75
	self.maxScale_ = 120
	self.minScale_ = 50
	self.is_first = true
	self.showCellName_ = false

	xyd.CameraManager.get():setEnabled(true)
end

function ActivityFairyTaleMapWindow:initWindow()
	ActivityFairyTaleMapWindow.super.initWindow(self)
	self:getComponent()
	self:layoutUI()
	self:regisetr()
	self:checkMapInfo()
end

function ActivityFairyTaleMapWindow:getComponent()
	local uiTrans = self.window_:NodeByName("content/panelUI")
	self.uiGameObject_ = uiTrans.gameObject
	self.shopBtn_ = uiTrans:NodeByName("btnGroup/shopBtn").gameObject
	self.shopBtnLabel_ = uiTrans:ComponentByName("btnGroup/shopBtn/label", typeof(UILabel))
	self.helpBtn_ = uiTrans:NodeByName("btnGroup/helpBtn").gameObject
	self.awardBtn_ = uiTrans:NodeByName("btnGroup/awardBtn").gameObject
	self.rankBtn_ = uiTrans:NodeByName("btnGroup/rankBtn").gameObject
	self.cellNameBtn_ = uiTrans:ComponentByName("btnGroup/cellNameBtn", typeof(UISprite))
	self.recordsBtn_ = uiTrans:NodeByName("btnGroup/recordsBtn").gameObject
	self.reposBtn_ = uiTrans:ComponentByName("btnGroup/reposBtn", typeof(UISprite))
	self.reposBtn_redPoint = uiTrans:NodeByName("btnGroup/reposBtn/redPoint").gameObject
	self.reposBtnLabel_ = uiTrans:ComponentByName("btnGroup/reposBtn/label", typeof(UILabel))
	self.buffBtn_ = uiTrans:NodeByName("btnGroup/buffBtn").gameObject
	self.buffIcon_ = uiTrans:ComponentByName("btnGroup/buffBtn/e:image", typeof(UISprite))
	self.scoreTips_ = uiTrans:ComponentByName("scoreImg/scoreTips", typeof(UILabel))
	self.scoreLabel_ = uiTrans:ComponentByName("scoreImg/scoreLabel", typeof(UILabel))
	self.levLabel_ = uiTrans:ComponentByName("levGroup/levImg/levLabel", typeof(UILabel))
	self.levTips_ = uiTrans:ComponentByName("levGroup/levTips", typeof(UILabel))
	self.progressLabel_ = uiTrans:ComponentByName("levGroup/progressLabel", typeof(UILabel))
	self.levProgress_ = uiTrans:ComponentByName("levGroup/progressBar", typeof(UIProgressBar))
	self.missionBtn_ = uiTrans:NodeByName("levGroup/missionBtn").gameObject
	self.missionBtn_redPoint = uiTrans:NodeByName("levGroup/missionBtn/redPoint").gameObject
	self.missionBtnLabel_ = uiTrans:ComponentByName("levGroup/missionBtn/label", typeof(UILabel))
	self.buffDetailRoot_ = uiTrans:NodeByName("buffDetailRoot").gameObject
	self.energyNum_ = uiTrans:ComponentByName("energyGroup/res_item/res_num_label", typeof(UILabel))
	self.energyShowBtn_ = uiTrans:NodeByName("energyGroup/res_item/bg_img").gameObject
	self.energyTips_ = uiTrans:NodeByName("energyGroup/energyTips").gameObject
	self.labelNextEnergy_ = uiTrans:ComponentByName("energyGroup/energyTips/labelNextEnergy", typeof(UILabel))
	self.energyCountDown_ = uiTrans:ComponentByName("energyGroup/energyTips/energyCountDown", typeof(UILabel))
	self.scrollViewMap_ = self.window_:ComponentByName("content/scrollViewMap", typeof(UIScrollView))
	self.cellItem_ = self.scrollViewMap_:NodeByName("cellItem").gameObject

	self.cellItem_:SetActive(false)

	self.cellList_ = self.scrollViewMap_:ComponentByName("itemList", typeof(UIGrid))
	self.cellGroup_ = self.scrollViewMap_:NodeByName("itemGroup").gameObject
end

function ActivityFairyTaleMapWindow:regisetr()
	ActivityFairyTaleMapWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_FAIRY_MAP_INFO, handler(self, self.refreshMap))
	self.eventProxy_:addEventListener(xyd.event.GET_CELL_INFO, handler(self, self.refreshCell))
	self.eventProxy_:addEventListener(xyd.event.HANDLE_MAP_ZOOM, handler(self, self.updateScale))
	self.eventProxy_:addEventListener(xyd.event.GET_LOG_LIST, handler(self, self.onGetLog))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onUpdateData))
	self.eventProxy_:addEventListener(xyd.event.FAIRY_CHALLENGE, handler(self, self.onCellChallenge))
	self.eventProxy_:addEventListener(xyd.event.FAIRY_SELECT_BUFF, handler(self, self.updateMissionRed))

	UIEventListener.Get(self.shopBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_fairy_tale_shop_window", {})
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_FAIRY_TALE_MAP_HELP"
		})
	end

	UIEventListener.Get(self.rankBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("rank_window", {
			mapType = xyd.MapType.ACTIVITY_FAIRT_TALE
		})
	end

	UIEventListener.Get(self.missionBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_fairy_tale_challenge_window", {})
	end

	UIEventListener.Get(self.recordsBtn_).onClick = function ()
		self.activityData_:reqGetRecords(self.mapId_)
	end

	UIEventListener.Get(self.cellNameBtn_.gameObject).onClick = handler(self, self.onChangeShowCellName)

	UIEventListener.Get(self.awardBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_fairy_tale_gift_preview_window", {})
	end

	UIEventListener.Get(self.reposBtn_.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_fairy_tale_story_window", {
			map_id = self.mapId_,
			value = self.compValue_
		})
	end

	UIEventListener.Get(self.buffBtn_).onPress = function (go, is_press)
		if is_press then
			if not self.mapBuffDetail_ then
				self.mapBuffDetail_ = ActivityFairyTaleMapWeatherTips.new(self.buffDetailRoot_)
			end

			self.mapBuffDetail_:SetActive(true)
			self.mapBuffDetail_:setInfo(self.activityData_.detail.map_infos[self.mapId_], self.mapId_)
		else
			self.mapBuffDetail_:SetActive(false)
		end
	end

	UIEventListener.Get(self.energyShowBtn_).onPress = function (go, is_press)
		self.energyTips_:SetActive(is_press)
	end
end

function ActivityFairyTaleMapWindow:refreshCell(event)
	local cellId = event.data.table_id
	self.cellInfoList_ = self.activityData_:getCellInfo()

	if self.cellItemList_ and self.cellItemList_[cellId] then
		self.cellItemList_[cellId]:setInfo(self.cellInfoList_[cellId], cellId)
	end
end

function ActivityFairyTaleMapWindow:onGetLog(event)
	local logs = event.data.logs
	local strList = {}

	for _, record in ipairs(logs) do
		record = cjson.decode(record)
		local cellName = xyd.tables.activityFairyTaleCellTable:getName(record.table_id)
		local mapId = xyd.tables.activityFairyTaleCellTable:getMapId(record.table_id)
		local playerName = record.player_name
		local item = record.items[1]
		local mapName = __("ACTIVITY_FAIRY_TALE_MAP_" .. mapId)
		local str = __("FAIRY_TALE_LOG", playerName, mapName, cellName, item.item_num)

		table.insert(strList, str)
	end

	local params = {
		isYahei = true,
		isFlow = true,
		title = __("FAIRY_TALE_RECORD_TITLE"),
		str_list = strList
	}

	xyd.WindowManager.get():openWindow("help_window", params)
end

function ActivityFairyTaleMapWindow:updateScale(event)
	local win1 = xyd.WindowManager.get():getWindow("activity_fairy_tale_cell_detail_window")
	local win2 = xyd.WindowManager.get():getWindow("activity_fairy_tale_story_window")
	local win3 = xyd.WindowManager.get():getWindow("activity_fairy_tale_shop_window")
	local win4 = xyd.WindowManager.get():getWindow("help_window")
	local win5 = xyd.WindowManager.get():getWindow("activity_fairy_tale_gift_preview_window")

	if win1 or win2 or win3 or win4 or win5 then
		return
	end

	local params = event.params
	local delta = params.delta
	local centerPos = params.centerPos

	if not params.double_touch then
		self.centerPoint = nil

		return
	end

	if not self.centerPoint then
		self.centerPoint = {
			worldPos = centerPos,
			oldX = self.cellGroup_.transform:X(),
			oldY = self.cellGroup_.transform:Y(),
			scale = self.curScale_
		}
	end

	local rate = math.floor((delta - 1) * 100)

	if math.abs(rate) < 1 then
		return
	end

	local newScale = Mathf.Clamp(self.curScale_ + rate, self.minScale_, self.maxScale_)
	self.curScale_ = newScale
	local addScale = self.centerPoint.scale - self.curScale_
	local localPos = self.scrollViewMap_.transform:InverseTransformPoint(self.centerPoint.worldPos)
	local changeX = localPos.x * addScale / 100
	local changeY = localPos.y * addScale / 100
	local scale = self.curScale_ / xyd.PERCENT_BASE

	self.cellGroup_.transform:SetLocalScale(scale, scale, 1)

	if delta == 1 and self.centerPoint then
		self.cellGroup_.transform:X(self.centerPoint.oldX + changeX)
		self.cellGroup_.transform:Y(self.centerPoint.oldY - changeY)
	end
end

function ActivityFairyTaleMapWindow:refreshCountDownEnergy()
	local interval = tonumber(xyd.tables.miscTable:getVal("activity_fairytale_energy_cd"))
	local nextTime = interval - (xyd.getServerTime() - self.activityData_.detail.update_time) % interval
	local params = {
		duration = nextTime,
		callback = function ()
			self:updateNextTime()
			self:refreshCountDownEnergy()
		end
	}
	local sta = xyd.models.backpack:getItemNumByID(xyd.ItemID.FAIRY_TALE_ENERGY)
	local maxEnergy = tonumber(xyd.tables.miscTable:getVal("activity_fairytale_energy_max"))

	if sta < maxEnergy then
		if not self.energyTimeCount_ then
			self.energyTimeCount_ = import("app.components.CountDown").new(self.energyCountDown_, params)
		else
			self.energyTimeCount_:setInfo(params)
		end
	else
		if self.energyTimeCount_ then
			self.energyTimeCount_:stopTimeCount()
		end

		self.energyCountDown_.text = "00:00:00"
	end
end

function ActivityFairyTaleMapWindow:updateNextTime()
	local fixEnergy = self.activityData_:getEnergy() + 1
	local maxEnergy = tonumber(xyd.tables.miscTable:getVal("activity_fairytale_energy_max"))

	if maxEnergy < fixEnergy then
		fixEnergy = maxEnergy
	end

	self.activityData_:setEnergy(fixEnergy)
	self:updateEnergy()
end

function ActivityFairyTaleMapWindow:updateEnergy()
	self.energyNum_.text = self.activityData_:getEnergy() .. "/" .. xyd.tables.miscTable:getVal("activity_fairytale_energy_max")
end

function ActivityFairyTaleMapWindow:layoutUI()
	self.shopBtnLabel_.text = __("EXCHANGE")
	self.reposBtnLabel_.text = __("ACTIVITY_MUSIC_JIGSAW_TEXT08")
	self.scoreTips_.text = __("FAIRY_TALE_SCORE")
	self.levTips_.text = __("FAIRY_TALE_WAR_LEVEL")
	self.missionBtnLabel_.text = __("CHECK_TEAM")
	self.labelNextEnergy_.text = __("NEXT_ENERGY")

	xyd.setUISprite(self.reposBtn_, nil, "activity_fairy_tale_card_icon_" .. self.mapId_)
	self:initWindowTop()
	self:updateEnergy()
	self:updateMissionRed()
	self:refreshShowInfo()
end

function ActivityFairyTaleMapWindow:refreshShowInfo()
	self.scoreLabel_.text = self.activityData_.detail.score
	self.levLabel_.text = self.activityData_.detail.lv

	self:refreshMissionProgress()
end

function ActivityFairyTaleMapWindow:initWindowTop()
	if not self.windowTop_ then
		self.windowTop_ = WindowTop.new(self.uiGameObject_, self.name_)
	end

	self:refreshCountDownEnergy()
end

function ActivityFairyTaleMapWindow:checkMapInfo()
	if self.activityData_:checkRefreshMap(self.mapId_) then
		self.activityData_:reqMapInfo(self.mapId_)
	else
		self:refreshMap()
	end
end

function ActivityFairyTaleMapWindow:refreshMissionProgress()
	if self:isCompleteMission() then
		self.levProgress_.value = 1
		self.progressLabel_.text = __("FAIRY_TALE_EXP", "--", "--")
	else
		self.nowMissionList_ = xyd.tables.activityFairyTaleLevelTable:getMissionIds(self.activityData_.detail.lv)
		local progressValue = self:getMissionProgress() or 0
		self.levProgress_.value = progressValue / #self.nowMissionList_
		self.progressLabel_.text = __("FAIRY_TALE_EXP", progressValue, #self.nowMissionList_)
	end
end

function ActivityFairyTaleMapWindow:getMissionProgress()
	local value = 0
	local missions = self.activityData_.detail.mission_infos

	for _, missionData in ipairs(missions) do
		if missionData and missionData.is_completed == 1 then
			value = value + 1
		end
	end

	return value
end

function ActivityFairyTaleMapWindow:refreshWindow()
	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE)

	self:refreshShowInfo()
end

function ActivityFairyTaleMapWindow:refreshMap(data)
	local isFirst = self.is_first
	self.cellInfoList_ = self.activityData_:getCellInfo()
	local tb = xyd.tables.activityFairyTaleCellTable
	self.cellIds_ = tb:getIdsByMap(self.mapId_)

	self:updateUnlockValue()

	local mainPos, startPos = nil

	for index, cellId in ipairs(self.cellIds_) do
		local pos = tb:getCellPos(cellId)

		if pos and pos[1] then
			if not self.cellGroupList_[pos[1]] then
				local cellGrid = NGUITools.AddChild(self.cellGroup_, self.cellList_.gameObject)

				if pos[1] % 2 == 0 then
					cellGrid.transform:X(-82)
				else
					cellGrid.transform:X(0)
				end

				cellGrid.transform:Y((pos[1] - 1) * -117)

				self.cellGroupList_[pos[1]] = cellGrid:GetComponent(typeof(UIGrid))

				if pos[1] >= 2 then
					self.cellGroupList_[pos[1] - 1]:Reposition()
				elseif pos[1] == 10 then
					self.cellGroupList_[pos[1]]:Reposition()
				end
			end

			if not self.cellItemList_[cellId] then
				local newRoot = NGUITools.AddChild(self.cellGroupList_[pos[1]].gameObject, self.cellItem_)
				local newItem = CellItem.new(newRoot, self)
				self.cellItemList_[cellId] = newItem
			end

			self.cellItemList_[cellId]:setInfo(self.cellInfoList_[cellId], cellId)

			if isFirst then
				local isCellType = xyd.tables.activityFairyTaleCellTable:getCellType(cellId)
				local isMain = xyd.tables.activityFairyTaleCellTable:getIsMain(cellId)
				local is_completed = self.cellInfoList_[cellId].is_completed
				local is_unlock = self.cellInfoList_[cellId].is_unlock

				if isMain == 1 and is_completed == 0 and is_unlock == 1 then
					mainPos = pos
				end

				if isCellType == CellType.START then
					startPos = pos
				end
			end

			local index = xyd.arrayIndexOf(self.unlockCellList_, cellId)

			if self.cellInfoList_[cellId].is_unlock == 1 and (not index or index < 0) then
				table.insert(self.unlockCellList_, cellId)
			end
		end
	end

	self.cellGroupList_[#self.cellGroupList_]:Reposition()

	if isFirst then
		self:moveMap(mainPos, startPos)
	end

	self:updatePlotRedPoint()
end

function ActivityFairyTaleMapWindow:updateUnlockValue()
	self.compValue_ = 0

	for index, cellId in ipairs(self.cellIds_) do
		if self.cellInfoList_[cellId] then
			local cellType = xyd.tables.activityFairyTaleCellTable:getCellType(self.cellInfoList_[cellId].table_id)

			if self.cellInfoList_[cellId].is_completed == 1 and cellType ~= CellType.NONE then
				self.compValue_ = self.compValue_ + 1
			end
		end
	end

	self.activityData_.detail.map_infos[self.mapId_].complete_num = self.compValue_
	local win = xyd.WindowManager.get():getWindow("activity_fairy_tale_main")

	if win then
		win:onGetActivityInfo()
	end
end

function ActivityFairyTaleMapWindow:moveMap(mainPos, startPos)
	local target = nil

	if not mainPos then
		target = {
			5,
			5
		}
	else
		target = mainPos
	end

	self.cellGroup_.transform:X(-target[2] * 75.5 - 85)
	self.cellGroup_.transform:Y(target[1] * 10 + 380)

	self.is_first = false
end

function ActivityFairyTaleMapWindow:isCompleteMission()
	self.nowMissionList_ = xyd.tables.activityFairyTaleLevelTable:getMissionIds(self.activityData_.detail.lv)

	if self.nowMissionList_ == nil or #self.nowMissionList_ == 0 then
		return true
	end

	return false
end

function ActivityFairyTaleMapWindow:onUpdateData(event)
	local id = event.data.act_info.activity_id

	if id == xyd.ActivityID.FAIRY_TALE then
		self:updateMissionRed()
		self:refreshMap()
		self:refreshWindow()
	end
end

function ActivityFairyTaleMapWindow:updateMissionRed()
	local lev = self.activityData_.detail.lv
	local buff_ids = self.activityData_.detail.buff_ids
	local isRed = false

	if lev >= 3 then
		for i = 3, lev do
			if #buff_ids[i] <= 0 then
				isRed = true
			end
		end
	end

	self.missionBtn_redPoint:SetActive(isRed)
end

function ActivityFairyTaleMapWindow:onCellChallenge(event)
	if event.data.is_video then
		return
	end

	local items = event.data.items
	local cellInfo = event.data.info

	for _, cellItem in ipairs(self.cellItemList_) do
		if cellInfo.table_id == cellItem.cellId_ then
			cellItem:setInfo(cellInfo, cellInfo.table_id)
		end
	end

	local cellType = xyd.tables.activityFairyTaleCellTable:getCellType(cellInfo.table_id)

	if cellType ~= CellType.BOSS and cellInfo.is_completed == 1 then
		self.activityData_:reqMapInfo(self.mapId_)
	elseif cellType == CellType.BOSS and cellInfo.is_completed == 1 then
		xyd.models.activity:reqActivityByID(xyd.ActivityID.FAIRY_TALE)
	end

	if cellInfo.is_completed == 1 then
		local mapId = xyd.tables.activityFairyTaleCellTable:getMapId(cellInfo.table_id)

		if not self.activityData_.detail.map_infos[mapId].complete_num then
			self.activityData_.detail.map_infos[mapId].complete_num = 1
		else
			self.activityData_.detail.map_infos[mapId].complete_num = self.activityData_.detail.map_infos[mapId].complete_num + 1
		end

		local win = xyd.WindowManager.get():getWindow("activity_fairy_tale_main")

		if win then
			win:onGetActivityInfo()
		end
	end

	if cellType ~= CellType.BOSS then
		if cellType == CellType.BATTLE then
			-- Nothing
		elseif cellType == CellType.HELP then
			xyd.itemFloat(items, nil, , 5000)
		elseif cellType == CellType.CHOOSE then
			-- Nothing
		end
	end

	self:updateEnergy()
	self:updateUnlockValue()
	self:refreshCountDownEnergy()
end

function ActivityFairyTaleMapWindow:updatePlotRedPoint()
	local hasRed = false
	local val = xyd.db.misc:getValue("fairy_tale_polt_red_point_" .. self.mapId_)
	local mapPlotIds = xyd.tables.activityFairyTalePlotListTable:getIdsByMapId(self.mapId_)
	local checkId = -1
	checkId = self.activityData_.detail.plot_ids[self.mapId_]

	if checkId ~= -1 then
		local unLockValue_ = xyd.tables.activityFairyTalePlotListTable:getUnlockById(checkId)

		if unLockValue_ <= self.compValue_ then
			hasRed = true
		end
	end

	self.reposBtn_redPoint:SetActive(hasRed)
end

function ActivityFairyTaleMapWindow:onChangeShowCellName()
	self.showCellName_ = not self.showCellName_

	if self.showCellName_ then
		xyd.setUISprite(self.cellNameBtn_, nil, "skin_btn01")
	else
		xyd.setUISprite(self.cellNameBtn_, nil, "skin_btn02")
	end

	for _, cellItem in pairs(self.cellItemList_) do
		cellItem:setShowName(self.showCellName_)
	end
end

function ActivityFairyTaleMapWindow:getTargetCell(type)
	local cellType = 0
	local isMain = nil

	if type == 2 then
		cellType = CellType.BATTLE
	elseif type == 3 then
		cellType = CellType.HELP
	elseif type == 4 then
		cellType = CellType.CHOOSE
	elseif type == 1 then
		isMain = true
	end

	local progress = 1
	local cellId = 0

	for _, cellInfo in pairs(self.cellInfoList_) do
		local cell_id = cellInfo.table_id
		local cell_type = xyd.tables.activityFairyTaleCellTable:getCellType(cell_id)

		if (cellType == 0 or cell_type == cellType) and cellInfo.is_completed == 0 and cellInfo.is_unlock == 1 then
			local totalHp = 100
			local typeContent = xyd.tables.activityFairyTaleCellTable:getCellContent(cell_id)

			if cell_type == CellType.BATTLE or self.cellType_ == CellType.BOSS then
				totalHp = xyd.tables.activityFairyTaleBattleTable:getTotalHp(typeContent)
			elseif cell_type == CellType.CHOOSE then
				totalHp = xyd.tables.activityFairyTaleOptionTable:getHp(typeContent)
			elseif cell_type == CellType.HELP then
				totalHp = xyd.tables.activityFairyTaleSupportTable:getTotalHp(typeContent)
			end

			local progress_new = (totalHp - cellInfo.value) / totalHp

			if progress >= progress_new then
				progress = progress_new
				cellId = cell_id
			end
		end
	end

	if cellId > 0 then
		return cellId
	else
		return nil
	end
end

function ActivityFairyTaleMapWindow:openStoryWindow()
	xyd.WindowManager.get():openWindow("activity_fairy_tale_story_window", {
		map_id = self.mapId_,
		value = self.compValue_
	})
end

function CellItem:ctor(go, parent)
	self.parent_ = parent

	CellItem.super.ctor(self, go)
end

function CellItem:initUI()
	CellItem.super.initUI(self)
	self:getComponent()

	UIEventListener.Get(self.go).onClick = function ()
		if self.cellType_ == CellType.START then
			return
		end

		if self.isUnlock_ ~= 1 then
			xyd.showToast(__("FAIRY_TALE_CELL_LOCK"))

			return
		end

		if self.isComplete_ == 1 then
			xyd.showToast(__("FAIRY_TALE_CELL_COMPLETED"))

			return
		end

		xyd.WindowManager.get():openWindow("activity_fairy_tale_cell_detail_window", {
			map_id = self.mapId_,
			cellType = self.cellType_,
			cell_id = self.cellId_
		})
	end
end

function CellItem:getComponent()
	self.bgImg_ = self.go:GetComponent(typeof(UISprite))
	self.cellImg_ = self.go:ComponentByName("cellImg", typeof(UISprite))
	self.effectRoot_ = self.go:NodeByName("effectImg").gameObject
	self.lockImg_ = self.go:NodeByName("lockImg").gameObject
	self.nameText_ = self.go:ComponentByName("nameText", typeof(UILabel))
end

function CellItem:setInfo(info, cellId)
	self.cellId_ = cellId
	self.mapId_ = self.parent_.mapId_
	self.cellType_ = xyd.tables.activityFairyTaleCellTable:getCellType(self.cellId_)
	self.isMain_ = xyd.tables.activityFairyTaleCellTable:getIsMain(self.cellId_)
	self.isPoint_ = xyd.tables.activityFairyTaleCellTable:getIsPoint(self.cellId_)
	self.contentId_ = xyd.tables.activityFairyTaleCellTable:getCellContent(self.cellId_)
	self.value_ = info.value
	self.isUnlock_ = info.is_unlock
	self.isComplete_ = info.is_completed
	self.nameText_.text = xyd.tables.activityFairyTaleCellTable:getCellNum(self.cellId_)

	self:refreshState()
end

function CellItem:refreshState()
	if self.isUnlock_ == 1 then
		self.lockImg_:SetActive(false)
		self.cellImg_:SetActive(true)

		self.go:GetComponent(typeof(UISprite)).color = Color.New2(4294967295.0)
	else
		self.lockImg_:SetActive(true)
		self.cellImg_:SetActive(false)

		self.go:GetComponent(typeof(UISprite)).color = Color.New2(3452816895.0)
	end

	if self.isUnlock_ == 1 and self.isMain_ == 1 and self.isComplete_ ~= 1 then
		if self.effect_ then
			self.effect_:destroy()
		end

		self.effect_ = xyd.Spine.new(self.effectRoot_)

		self.effect_:setInfo("fairytale_cell", function ()
			if self.mapId_ == 1 then
				self.effect_:play("texiao04", -1, 1)
			else
				self.effect_:play("texiao03", -1, 1)
			end
		end, true)
	elseif self.effect_ then
		self.effect_:SetActive(false)
	end

	local labelColor = {
		{
			effectColor = Color.New2(392704511)
		},
		{
			effectColor = Color.New2(3245424127.0)
		},
		{
			effectColor = Color.New2(2154779135.0)
		},
		{
			effectColor = Color.New2(746892543)
		},
		{
			effectColor = Color.New2(2406439423.0)
		},
		{
			effectColor = Color.New2(1715763711)
		}
	}
	local effectColor = labelColor[self.mapId_]
	self.nameText_.effectColor = effectColor

	xyd.setUISpriteAsync(self.bgImg_, nil, "activity_fairy_tale_card_bg" .. self.mapId_)

	if self.isComplete_ == 1 then
		self.cellImg_.gameObject:SetActive(false)
	end

	if self.cellType_ == CellType.NONE then
		self.go:SetActive(false)
	elseif self.cellType_ == CellType.START then
		self.lockImg_:SetActive(false)
		self.cellImg_:SetActive(false)
	elseif self.cellType_ == CellType.BATTLE then
		xyd.setUISpriteAsync(self.cellImg_, nil, "activity_fairy_tale_card_fight" .. self.mapId_)
	elseif self.cellType_ == CellType.BOSS then
		xyd.setUISpriteAsync(self.cellImg_, nil, "activity_fairy_tale_card_boss" .. self.mapId_)
	elseif self.cellType_ == CellType.HELP then
		xyd.setUISpriteAsync(self.cellImg_, nil, "activity_fairy_tale_card_help" .. self.mapId_)
	elseif self.cellType_ == CellType.CHOOSE then
		xyd.setUISpriteAsync(self.cellImg_, nil, "activity_fairy_tale_card_select" .. self.mapId_)
	end
end

function CellItem:setShowName(state)
	self.nameText_.gameObject:SetActive(state)
end

return ActivityFairyTaleMapWindow
