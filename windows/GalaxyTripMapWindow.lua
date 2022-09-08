local GalaxyTripMapWindow = class("GalaxyTripMapWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local GridClass = class("GridClass", import("app.components.CopyComponent"))
local SIZE_NUM = 76

function GalaxyTripMapWindow:ctor(name, params)
	GalaxyTripMapWindow.super.ctor(self, name, params)

	self.ballId = params.ballId
end

function GalaxyTripMapWindow:initWindow()
	self:getUIComponent()
	GalaxyTripMapWindow.super.initWindow(self)
	self:reSize()
	self:registerEvent()
	self:layout()
end

function GalaxyTripMapWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.bgBottom = self.groupAction:ComponentByName("bgBottom", typeof(UITexture))
	self.bg = self.groupAction:ComponentByName("bg", typeof(UITexture))
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.tipsBtn = self.upCon:NodeByName("tipsBtn").gameObject
	self.nameText = self.upCon:ComponentByName("nameText", typeof(UILabel))
	self.rankBtn = self.upCon:NodeByName("rankBtn").gameObject
	self.buffBtn = self.upCon:NodeByName("buffBtn").gameObject
	self.passBtn = self.upCon:NodeByName("passBtn").gameObject
	self.passBtnRedPoint = self.passBtn:NodeByName("passBtnRedPoint").gameObject

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.GALAXY_TRIP
	}, self.passBtnRedPoint)

	self.shopBtn = self.upCon:NodeByName("shopBtn").gameObject
	self.downCon = self.groupAction:NodeByName("downCon").gameObject
	self.progressBtnCon = self.downCon:NodeByName("progressBtnCon").gameObject
	self.progressBtn = self.progressBtnCon:NodeByName("progressBtn").gameObject
	self.progressBtnLabel = self.progressBtnCon:ComponentByName("progressBtnLabel", typeof(UILabel))
	self.progressShow = self.progressBtn:ComponentByName("progressShow", typeof(UISprite))
	self.progressShowUIProgressBar = self.progressBtn:ComponentByName("progressShow", typeof(UIProgressBar))
	self.labelDesc = self.progressShow:ComponentByName("labelDesc", typeof(UILabel))
	self.progressValue = self.progressShow:ComponentByName("progressValue", typeof(UISprite))
	self.bottomImg = self.progressBtnCon:ComponentByName("bottomImg", typeof(UISprite))
	self.numCon = self.progressBtn:NodeByName("numCon").gameObject
	self.numImg1 = self.numCon:ComponentByName("numImg1", typeof(UISprite))
	self.numImg2 = self.numCon:ComponentByName("numImg2", typeof(UISprite))
	self.numImg3 = self.numCon:ComponentByName("numImg3", typeof(UISprite))
	self.numImgMark = self.numCon:ComponentByName("numImgMark", typeof(UISprite))
	self.backBtnCon = self.downCon:NodeByName("backBtnCon").gameObject
	self.backBtn = self.backBtnCon:NodeByName("backBtn").gameObject
	self.backBtnLabel = self.backBtnCon:ComponentByName("backBtnLabel", typeof(UILabel))
	self.teamBtnCon = self.downCon:NodeByName("teamBtnCon").gameObject
	self.teamBtn = self.teamBtnCon:NodeByName("teamBtn").gameObject
	self.teamBtnRedPoint = self.teamBtn:NodeByName("teamBtnRedPoint").gameObject

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.GALAXY_TRIP_TEAM
	}, self.teamBtnRedPoint)

	self.teamBtnLabel = self.teamBtnCon:ComponentByName("teamBtnLabel", typeof(UILabel))
	self.returnBtnCon = self.downCon:NodeByName("returnBtnCon").gameObject
	self.returnBtn = self.returnBtnCon:NodeByName("returnBtn").gameObject
	self.returnBtnLabel = self.returnBtnCon:ComponentByName("returnBtnLabel", typeof(UILabel))
	self.lineBtnCon = self.downCon:NodeByName("lineBtnCon").gameObject
	self.lineBtn = self.lineBtnCon:NodeByName("lineBtn").gameObject
	self.lineBtnLabel = self.lineBtnCon:ComponentByName("lineBtnLabel", typeof(UILabel))
	self.centerCon = self.groupAction:NodeByName("centerCon").gameObject
	self.scrollerPanel = self.centerCon:NodeByName("scrollerPanel").gameObject
	self.scrollerPanelUIScrollView = self.centerCon:ComponentByName("scrollerPanel", typeof(UIScrollView))
	self.girdContent = self.scrollerPanel:NodeByName("content").gameObject
	self.girdContentUIWidget = self.scrollerPanel:ComponentByName("content", typeof(UIWidget))
	self.gridItem = self.centerCon:NodeByName("gridItem").gameObject
	self.canGetCon = self.centerCon:NodeByName("canGetCon").gameObject
	self.planGridCon = self.centerCon:NodeByName("planGridCon").gameObject
	self.gridHpCon = self.centerCon:NodeByName("gridHpCon").gameObject
	self.startEndCon = self.centerCon:NodeByName("startEndCon").gameObject
	self.planMaskPanel = self.centerCon:NodeByName("planMaskPanel").gameObject
	self.maskUISprite = self.planMaskPanel:ComponentByName("mask", typeof(UISprite))
	self.maskBoxCollider = self.planMaskPanel:ComponentByName("mask", typeof(UnityEngine.BoxCollider))
	self.planingCon = self.groupAction:NodeByName("planingCon").gameObject
	self.planingCenterCon = self.planingCon:NodeByName("planingCenterCon").gameObject
	self.planingCenterConBg = self.planingCenterCon:ComponentByName("planingCenterConBg", typeof(UITexture))
	self.planingCenterLabel = self.planingCenterCon:ComponentByName("planingCenterLabel", typeof(UILabel))
	self.planingTimeCon = self.planingCon:NodeByName("planingTimeCon").gameObject
	self.planingTimeConUILayout = self.planingCon:ComponentByName("planingTimeCon", typeof(UILayout))
	self.planingTimeDesc = self.planingTimeCon:ComponentByName("planingTimeDesc", typeof(UILabel))
	self.planingTimeText = self.planingTimeCon:ComponentByName("planingTimeText", typeof(UILabel))
	self.planingTipsBtn = self.planingCon:NodeByName("planingTipsBtn").gameObject
end

function GalaxyTripMapWindow:reSize()
	self:resizePosY(self.upCon, 500, 558)
	self:resizePosY(self.downCon, -510, -576)
	self:resizePosY(self.bgBottom, -136, -73)
end

function GalaxyTripMapWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GALAXY_TRIP_GRID_IDS, handler(self, self.onGetGalaxyTripGridBack))
	self.eventProxy_:addEventListener(xyd.event.GALAXY_TRIP_GET_MAIN_INFO, handler(self, self.onGetGalaxyTripGetMainBack))
	self.eventProxy_:addEventListener(xyd.event.GALAXY_TRIP_STOP_BACK_GRID, handler(self, self.onGalaxyTripStopBackGrid))
	self.eventProxy_:addEventListener(xyd.event.GALAXY_TRIP_GET_MAP_AWARDS, handler(self, self.onGetGalaxyTripMapAwardsBack))
	self.eventProxy_:addEventListener(xyd.event.GALAXY_TRIP_GET_RANK_LIST, function ()
		local data = xyd.models.galaxyTrip:getRankData()

		xyd.openWindow("common_rank_with_award_window", data)
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, function (event)
		local activity_id = event.data.activity_id

		if activity_id ~= xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION and activity_id ~= xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION2 then
			return
		end

		xyd.openWindow("galaxy_battle_pass_window", {
			activityID = activity_id
		})

		self.isReqingActivity = false
	end)
	self.eventProxy_:addEventListener(xyd.event.GALAXY_TRIP_GET_MAP_INFO, function (event)
		self:onClickProgressBtn()
	end)

	UIEventListener.Get(self.backBtn.gameObject).onClick = handler(self, function ()
		if self.isPlanReady then
			self:setIsOpenPlanReady(false)
		else
			xyd.openWindow("galaxy_trip_main_window", {}, function ()
				self:close()
			end)
		end
	end)
	UIEventListener.Get(self.lineBtn.gameObject).onClick = handler(self, function ()
		local isBatch = xyd.models.galaxyTrip:getGalaxyTripGetMainIsBatch()

		if isBatch and isBatch == 1 then
			xyd.alertTips(__("GALAXY_TRIP_TIPS_14"))

			return
		end

		if self.isPlanReady then
			local arr = self:getReadyPlanGridArr()

			if arr and #arr <= 0 then
				xyd.alertTips(__("GALAXY_TRIP_TIPS_06"))

				return
			end

			local msg = messages_pb:galaxy_trip_grid_ids_req()

			for i in pairs(arr) do
				table.insert(msg.ids, arr[i])
			end

			msg.is_batch = 1

			xyd.Backend.get():request(xyd.mid.GALAXY_TRIP_GRID_IDS, msg)
		else
			self:setIsOpenPlanReady(true)
		end
	end)
	UIEventListener.Get(self.rankBtn.gameObject).onClick = handler(self, function ()
		if not xyd.models.galaxyTrip:needReqRankInfo() then
			local data = xyd.models.galaxyTrip:getRankData()

			xyd.openWindow("common_rank_with_award_window", data)
		end
	end)
	UIEventListener.Get(self.buffBtn.gameObject).onClick = handler(self, function ()
		local mapID = self.ballId

		xyd.openWindow("galaxy_battle_buff_window", {
			mapID = self.ballId,
			skillIDs = xyd.models.galaxyTrip:getBallInfo(self.ballId).god_skills or {}
		})
	end)
	UIEventListener.Get(self.passBtn.gameObject).onClick = handler(self, function ()
		if not self.isReqingActivity then
			xyd.models.galaxyTrip:sendGalaxyTripGetMainBack()

			local activityData1 = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION)
			local activityData2 = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION2)
			local activityID = xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION

			if activityData1 then
				local endTime = activityData1:getEndTime()

				if tonumber(endTime) <= tonumber(xyd.getServerTime()) then
					activityID = xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION2
				else
					activityID = xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION
				end
			elseif activityData2 then
				local endTime = activityData2:getEndTime()

				if tonumber(endTime) <= tonumber(xyd.getServerTime()) then
					activityID = xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION
				else
					activityID = xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION2
				end
			end

			xyd.models.activity:reqActivityByID(activityID)

			self.isReqingActivity = true
		end
	end)
	UIEventListener.Get(self.shopBtn.gameObject).onClick = handler(self, function ()
		local params = xyd.models.galaxyTrip:getShopData()

		xyd.openWindow("common_shop_window", params)
	end)
	UIEventListener.Get(self.teamBtn.gameObject).onClick = handler(self, function ()
		xyd.openWindow("galaxy_trip_formation_window", {
			formation = xyd.models.galaxyTrip:getGalaxyTripGetMainTeamsInfo()
		})
	end)
	UIEventListener.Get(self.progressBtn.gameObject).onClick = handler(self, function ()
		self:onClickProgressBtn()
	end)
	UIEventListener.Get(self.tipsBtn.gameObject).onClick = handler(self, function ()
		xyd.openWindow("help_window", {
			key = "GALAXY_TRIP_HELP02"
		})
	end)
	UIEventListener.Get(self.planingTipsBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("galaxy_trip_result_middle_window", {
			ballId = self.ballId,
			resultType = xyd.GalaxyTripResultType.MIDDLE
		})
	end)
	UIEventListener.Get(self.returnBtn.gameObject).onClick = handler(self, function ()
		local isHasSearching = false
		local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.ballId)
		local ballMap = ballMapInfo.map

		for i in pairs(ballMap) do
			local gridState = xyd.models.galaxyTrip:getGridState(ballMap[i].gridId, self.ballId)

			if gridState == xyd.GalaxyTripGridStateType.SEARCH_ING then
				isHasSearching = true
			end
		end

		if not isHasSearching then
			xyd.alertTips(__("GALAXY_TRIP_TIPS_01"))

			return
		end

		xyd.alertYesNo(__("GALAXY_TRIP_TIPS_07"), function (yes_no)
			if yes_no then
				local nextTime = xyd.models.galaxyTrip:getGalaxyTripGetMainNextTime()
				local checkMaskTime = xyd.tables.miscTable:getNumber("galaxy_trip_stop_time_limit", "value")

				if xyd.getServerTime() < nextTime and checkMaskTime >= nextTime - xyd.getServerTime() then
					xyd.alertTips(__("GALAXY_TRIP_TEXT70"))

					return
				end

				self:waitForTime(0.5, function ()
					local msg = messages_pb:galaxy_trip_stop_back_grid_req()

					xyd.Backend.get():request(xyd.mid.GALAXY_TRIP_STOP_BACK_GRID, msg)
				end)
			end
		end)
	end)
end

function GalaxyTripMapWindow:layout()
	self.lineBtnLabel.text = __("GALAXY_TRIP_TEXT23")
	self.planingCenterLabel.text = __("GALAXY_TRIP_TEXT05")
	self.backBtnLabel.text = __("GALAXY_TRIP_TEXT21")
	self.progressBtnLabel.text = __("GALAXY_TRIP_TEXT08")
	self.returnBtnLabel.text = __("GALAXY_TRIP_TEXT24")
	self.teamBtnLabel.text = __("GALAXY_TRIP_TEXT22")
	self.planingTimeDesc.text = __("GALAXY_TRIP_TEXT43")
	local galaxyNameId = xyd.tables.galaxyTripMapTable:getNameTextId(self.ballId)
	self.nameText.text = xyd.tables.galaxyTripMapTextTable:getDesc(galaxyNameId)
	local mapIcon = xyd.tables.galaxyTripMapTable:getMapText(self.ballId)

	xyd.setUITextureByNameAsync(self.bg, mapIcon)

	local wnd = xyd.getWindow("galaxy_trip_main_window")

	if wnd then
		self:waitForFrame(5, function ()
			xyd.closeWindow("galaxy_trip_main_window")
		end)
	end

	self:initTop()
	self:updateProgress()
	self:updateGridShow()
	self:updatePlaningCon()

	if self.ballId == xyd.models.galaxyTrip:getBossMapId() then
		self.lineBtnCon.gameObject:SetActive(false)
		self.progressBtnCon.gameObject:SetActive(false)
		self.returnBtnCon.gameObject:SetActive(false)
		self.buffBtn.gameObject:SetActive(false)
	end

	self:waitForTime(1, function ()
		if xyd.models.galaxyTrip:isShowTime() then
			xyd.models.galaxyTrip:mustReturn()
		end
	end)
end

function GalaxyTripMapWindow:initTop()
	self.windowTop = WindowTop.new(self.window_, self.name_, 50, nil, function ()
		xyd.openWindow("galaxy_trip_main_window", {}, function ()
			self:close()
		end)
	end)
	local items = {
		{
			id = xyd.ItemID.MANA
		},
		{
			id = xyd.ItemID.CRYSTAL
		}
	}

	self.windowTop:setItem(items)
end

function GalaxyTripMapWindow:getBallId()
	return self.ballId
end

function GalaxyTripMapWindow:updateProgress()
	local value = xyd.models.galaxyTrip:getGalaxyProgress(self.ballId)
	self.progressValue.fillAmount = value / 100

	self:waitForFrame(1, function ()
		self.progressValue.fillAmount = value / 100
	end)
	self:waitForFrame(2, function ()
		self.progressValue.fillAmount = value / 100
	end)

	local img1 = "galaxy_trip_num_" .. value % 10

	xyd.setUISpriteAsync(self.numImg1, nil, img1)

	local img2 = "galaxy_trip_num_0"

	if value < 100 then
		img2 = "galaxy_trip_num_" .. math.floor(value / 10)

		self.numImg3.gameObject:SetActive(false)
	else
		self.numImg3.gameObject:SetActive(true)

		local img3 = "galaxy_trip_num_1"

		xyd.setUISpriteAsync(self.numImg3, nil, img3)
	end

	xyd.setUISpriteAsync(self.numImg2, nil, img2)
end

function GalaxyTripMapWindow:updateGridShow()
	if not self.gridPosArr then
		self.gridPosArr = {}
		local mapSize = xyd.tables.galaxyTripMapTable:getSize(self.ballId)

		for i = 1, mapSize[1] * mapSize[2] do
			table.insert(self.gridPosArr, i)
		end

		self.gridArr = {}
		local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self:getBallId())
		local ballMap = ballMapInfo.map
		local searchFistGetYetPos = 0

		for i in pairs(self.gridPosArr) do
			local tmp = NGUITools.AddChild(self.girdContent.gameObject, self.gridItem.gameObject)
			local pos = self.gridPosArr[i]
			local xPos = pos % mapSize[1]

			if xPos == 0 then
				xPos = 9
			end

			local yPos = math.floor((pos - 1) / mapSize[1])
			yPos = yPos + 1

			tmp:SetLocalPosition(xPos * SIZE_NUM - SIZE_NUM, -yPos * SIZE_NUM + SIZE_NUM, 1)

			local item = GridClass.new(tmp, self.gridPosArr[i], self)
			self.gridArr[self.gridPosArr[i]] = item
			local gridState = xyd.models.galaxyTrip:getGridState(ballMap[i].gridId, self:getBallId())

			if searchFistGetYetPos == 0 and gridState == xyd.GalaxyTripGridStateType.GET_YET then
				searchFistGetYetPos = i
			end
		end

		local jumpRow = mapSize[2]

		if searchFistGetYetPos > 0 then
			local countRow = math.floor((searchFistGetYetPos - 1) / mapSize[1]) + 1

			if jumpRow > countRow then
				jumpRow = countRow
			end
		end

		self.girdContentUIWidget.width = mapSize[1] * SIZE_NUM
		self.girdContentUIWidget.height = mapSize[2] * SIZE_NUM

		self.scrollerPanelUIScrollView:ResetPosition()
		self:waitForFrame(2, function ()
			self:jumpToScroller(jumpRow)
		end)

		for i in pairs(self.gridArr) do
			self.gridArr[i]:checkCurGridIsCanSearch()
		end
	else
		for i in pairs(self.gridArr) do
			self.gridArr[i]:updateGridState()
		end

		for i in pairs(self.gridArr) do
			self.gridArr[i]:checkCurGridIsCanSearch()
		end
	end

	self:updateProgress()
end

function GalaxyTripMapWindow:jumpToScroller(rowNum)
	local currIndex = rowNum
	local panel = self.scrollerPanel:GetComponent(typeof(UIPanel))
	local height = panel.baseClipRegion.w
	local mapSize = xyd.tables.galaxyTripMapTable:getSize(self.ballId)
	local allHeight = mapSize[2] * SIZE_NUM
	local height2 = allHeight

	if height2 <= height then
		return
	end

	local displayNum = math.ceil(height / SIZE_NUM)
	local half = math.floor(displayNum / 2)

	if currIndex <= half then
		return
	end

	local maxDeltaY = height2 - height
	local deltaY = currIndex * SIZE_NUM - height / 2 - SIZE_NUM / 2
	deltaY = math.min(deltaY, maxDeltaY)
	deltaY = deltaY + self.scrollerPanelUIScrollView.padding.y * 2

	self.scrollerPanelUIScrollView:MoveRelative(Vector3(0, deltaY, 0))
end

function GalaxyTripMapWindow:onGetGalaxyTripMapAwardsBack(event)
	local data = xyd.decodeProtoBuf(event.data)

	for i, id in pairs(self.gridArr) do
		self.gridArr[i]:updateGridState()
	end

	for i in pairs(self.gridArr) do
		self.gridArr[i]:checkCurGridIsCanSearch()
	end

	self:updatePlaningCon()
	self:updateProgress()
end

function GalaxyTripMapWindow:setIsOpenPlanReady(state)
	if self:getBallId() == xyd.models.galaxyTrip:getBossMapId() then
		return
	end

	if state then
		local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self:getBallId())
		local ballMap = ballMapInfo.map

		for i in pairs(ballMap) do
			local gridState = xyd.models.galaxyTrip:getGridState(ballMap[i].gridId, self:getBallId())
			local isReturn = false

			if gridState == xyd.GalaxyTripGridStateType.SEARCH_ING then
				xyd.alertTips(__("GALAXY_TRIP_TIPS_02"))

				isReturn = true
			end

			if gridState == xyd.GalaxyTripGridStateType.CAN_GET then
				xyd.alertYesNo(__("GALAXY_TRIP_TIPS_11"), function (yes_no)
					if yes_no then
						for k in pairs(self.gridArr) do
							if self.gridArr[k]:getGridId() == ballMap[i].gridId then
								self.gridArr[k]:openEventWindow()

								break
							end
						end
					end
				end)

				isReturn = true
			end

			if isReturn then
				return
			end
		end
	end

	self.isPlanReady = state
	self.readyPlanGridArr = {}

	if self.isPlanReady then
		self.progressBtnCon.gameObject:SetActive(false)
		self.teamBtnCon.gameObject:SetActive(false)
		self.returnBtnCon.gameObject:SetActive(false)

		self.lineBtnLabel.text = __("SURE")
	else
		self.progressBtnCon.gameObject:SetActive(true)
		self.teamBtnCon.gameObject:SetActive(true)
		self.returnBtnCon.gameObject:SetActive(true)

		self.lineBtnLabel.text = __("GALAXY_TRIP_TEXT23")
	end

	for i in pairs(self.gridArr) do
		self.gridArr[i]:checkCurGridIsCanPlanReady()
	end
end

function GalaxyTripMapWindow:getIsPlanReady()
	return self.isPlanReady
end

function GalaxyTripMapWindow:getReadyPlanGridArr()
	return self.readyPlanGridArr
end

function GalaxyTripMapWindow:setReadyPlanGridArr(gridId, isRemove)
	if isRemove then
		local newArr = {}

		for i in pairs(self.readyPlanGridArr) do
			if self.readyPlanGridArr[i] ~= gridId then
				table.insert(newArr, self.readyPlanGridArr[i])
			else
				break
			end
		end

		self.readyPlanGridArr = newArr
	else
		if xyd.models.galaxyTrip:getPalningNum() <= #self.readyPlanGridArr then
			xyd.alertTips(__("GALAXY_TRIP_TEXT57"))

			return
		end

		table.insert(self.readyPlanGridArr, gridId)
	end

	for i in pairs(self.gridArr) do
		self.gridArr[i]:checkCurGridIsCanPlanReady()
	end
end

function GalaxyTripMapWindow:onGetGalaxyTripGridBack(event)
	local data = xyd.decodeProtoBuf(event.data)

	if data.is_batch and data.is_batch == 1 then
		self:setIsOpenPlanReady(false)
		self:updatePlaningCon()
	end

	self:updateGridShow()
end

function GalaxyTripMapWindow:onGetGalaxyTripGetMainBack(event)
	self:setIsOpenPlanReady(false)
	self:updatePlaningCon()
	self:updateGridShow()
end

function GalaxyTripMapWindow:willClose()
	GalaxyTripMapWindow.super.willClose(self)
end

function GalaxyTripMapWindow:updatePlaningCon()
	if self.ballId == xyd.models.galaxyTrip:getBossMapId() then
		return
	end

	local isBatch = xyd.models.galaxyTrip:getGalaxyTripGetMainIsBatch()

	if isBatch and isBatch == 1 then
		self.planingCon.gameObject:SetActive(true)
		self.planMaskPanel.gameObject:SetActive(true)

		local function setMaskBoxFun()
			self.maskBoxCollider.size = Vector3(self.maskUISprite.width, self.maskUISprite.height, 0)
		end

		setMaskBoxFun()
		self:waitForFrame(1, function ()
			setMaskBoxFun()
		end)
		self:waitForFrame(2, function ()
			setMaskBoxFun()
		end)

		local idsArr = xyd.models.galaxyTrip:getGalaxyTripGetMainIds()
		local awardsArr = xyd.models.galaxyTrip:getGalaxyTripGetMainAwards()
		local searchIndex = -1

		for i in pairs(idsArr) do
			if awardsArr[i] == nil and i == 1 or awardsArr[i] == nil and awardsArr[i - 1] == 1 then
				searchIndex = i
			end
		end

		if searchIndex == -1 then
			self:openResultWindowFun()
		else
			local curEndTime = xyd.models.galaxyTrip:getGalaxyTripGetMainNextTime()
			local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.ballId)
			local ballMap = ballMapInfo.map

			for i = searchIndex + 1, #idsArr do
				local posId = xyd.models.galaxyTrip:getPosIdFromGridId(self.ballId, idsArr[i])
				local eventArr = xyd.split(ballMap[posId].info, "#", true)
				local eventId = eventArr[1]
				local eventType = xyd.tables.galaxyTripEventTable:getType(eventId)
				local time = xyd.tables.galaxyTripEventTypeTable:getTime(eventType)
				curEndTime = curEndTime + math.floor(time * (1 - xyd.models.galaxyTrip:getBuffExploreTimeCut()))
			end

			local disTime = curEndTime - xyd.getServerTime()

			if disTime <= 0 then
				self:openResultWindowFun()
			else
				if self.planingTimeCount then
					self.planingTimeCount:dispose()

					self.planingTimeCount = nil
				end

				self.planingTimeCount = import("app.components.CountDown").new(self.planingTimeText)

				self.planingTimeCount:setInfo({
					duration = disTime,
					callback = function ()
						self:openResultWindowFun()
					end
				})
			end
		end

		self.planingTimeConUILayout:Reposition()

		return
	end

	self.planingCon.gameObject:SetActive(false)
	self.planMaskPanel.gameObject:SetActive(false)
end

function GalaxyTripMapWindow:openResultWindowFun()
	self.planingTimeText.text = "00:00:00"
	local galaxyTripResultWd = xyd.WindowManager.get():getWindow("galaxy_trip_result_window")

	if not galaxyTripResultWd then
		self:waitForTime(1, function ()
			xyd.WindowManager.get():closeWindow("galaxy_trip_result_middle_window")
			xyd.WindowManager.get():openWindow("galaxy_trip_result_window", {
				ballId = self.ballId,
				resultType = xyd.GalaxyTripResultType.OVER
			})
		end)
	end
end

function GalaxyTripMapWindow:onGalaxyTripStopBackGrid(event)
	self:updateGridShow()

	local isBatch = xyd.models.galaxyTrip:getGalaxyTripGetMainIsBatch()

	if self.planingTimeCount then
		self.planingTimeCount:dispose()

		self.planingTimeCount = nil
	end

	self:openResultWindowFun()

	if isBatch and isBatch == 0 then
		self:waitForTime(1, function ()
			self:updatePlaningCon()
		end)
	end
end

function GalaxyTripMapWindow:onClickProgressBtn()
	local isBatch = xyd.models.galaxyTrip:getGalaxyTripGetMainIsBatch()

	if isBatch and isBatch == 1 then
		xyd.alertTips(__("GALAXY_TRIP_TIPS_14"))

		return
	end

	local ballID = self.ballId
	local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(ballID)

	if not ballMapInfo then
		xyd.models.galaxyTrip:reqMapInfo(ballID)
	else
		xyd.models.galaxyTrip:getBallIsUnLock(ballID)

		local ballOpened = ballMapInfo.opened
		local task2 = 0

		if ballMapInfo.chests and ballMapInfo.chests[1] then
			for key, value in pairs(ballMapInfo.chests) do
				if value and value > 0 then
					task2 = task2 + 1
				end
			end
		end

		local task3 = 0

		if ballMapInfo.is_end == 1 then
			task3 = 1
		end

		xyd.openWindow("galaxy_explore_progress_window", {
			totalProgreeValue = xyd.models.galaxyTrip:getCurBallProress(self.ballId),
			missionProgreeValues = {
				ballMapInfo.is_boss,
				task2,
				task3
			},
			mapID = self.ballId
		})
	end
end

function GalaxyTripMapWindow:onClickEscBack(event)
	xyd.openWindow("galaxy_trip_main_window", {}, function ()
		self:close()
	end)
end

function GridClass:ctor(goItem, posId, parent)
	self.goItem_ = goItem
	self.parent = parent
	self.posId = posId
	local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.parent:getBallId())
	local ballMap = ballMapInfo.map
	self.gridId = ballMap[self.posId].gridId

	GridClass.super.ctor(self, goItem)
end

function GridClass:initUI()
	self:getUIComponent()
	GridClass.super.initUI(self)

	UIEventListener.Get(self.gridBorder.gameObject).onClick = handler(self, self.onTouch)

	self:updateGridState()
end

function GridClass:getUIComponent()
	self.gridBorder = self.go:ComponentByName("gridBorder", typeof(UISprite))
	self.gridMask = self.go:ComponentByName("gridMask", typeof(UISprite))
	self.gridEventImg = self.go:ComponentByName("gridEventImg", typeof(UISprite))
end

function GridClass:getGridId()
	return self.gridId
end

function GridClass:updateGridState()
	local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.parent:getBallId())
	local ballMap = ballMapInfo.map
	local eventArr = xyd.split(ballMap[self.posId].info, "#", true)
	local eventId = eventArr[1]
	self.eventId = eventId
	local eventType = xyd.tables.galaxyTripEventTable:getType(eventId)

	self.gridEventImg:SetActive(true)
	self.gridMask:SetActive(true)
	self:setAnotherConVisible(false)
	self:setPlanConVisible(false)
	self:setHpConVisible(false)

	if self.timeCount then
		self.timeCount:dispose()

		self.timeCount = nil
	end

	if eventId == xyd.GalaxyTripGridEventType.NOTHING then
		self.go:SetActive(false)

		self.eventType = eventId
	else
		self.eventType = eventType
		local gridState = xyd.models.galaxyTrip:getGridState(self.gridId, self.parent:getBallId())

		local function updateMoreLinkEventGrid()
			local evetNeedGrid = xyd.tables.galaxyTripEventTypeTable:getSize(self.eventType)

			if self:checkIsMoreLinkEventFirst(self.eventType) then
				local borderChangeToWidth = 76 * evetNeedGrid[1] + 2
				local borderChangeToHeight = 76 * evetNeedGrid[2] + 2
				self.gridBorder.width = borderChangeToWidth
				self.gridBorder.height = borderChangeToHeight
				local maskChangeToWidth = 76 * evetNeedGrid[1]
				local maskChangeToHeight = 76 * evetNeedGrid[2]
				self.gridMask.width = maskChangeToWidth
				self.gridMask.height = maskChangeToHeight
			else
				self.go:SetActive(false)
			end
		end

		if self:checkAssignGirdisComplete(self.posId) then
			self.gridEventImg:SetActive(false)
			self.gridMask:SetActive(false)

			local evetNeedGrid = xyd.tables.galaxyTripEventTypeTable:getSize(eventType)

			if evetNeedGrid[1] ~= 1 or evetNeedGrid[2] ~= 1 then
				updateMoreLinkEventGrid()
			end

			if xyd.models.galaxyTrip:getIsBuff(self.eventType) then
				local iconStr = xyd.tables.galaxyTripEventTypeTable:getIconText(eventType)

				xyd.setUISpriteAsync(self.gridEventImg, nil, iconStr, nil, , true)

				if gridState == xyd.GalaxyTripGridStateType.GET_YET then
					self.gridEventImg:SetActive(true)
				end
			end
		else
			local iconStr = xyd.tables.galaxyTripEventTypeTable:getIconText(eventType)

			xyd.setUISpriteAsync(self.gridEventImg, nil, iconStr, nil, , true)

			local evetNeedGrid = xyd.tables.galaxyTripEventTypeTable:getSize(eventType)

			if evetNeedGrid[1] == 1 and evetNeedGrid[2] == 1 then
				if eventType == xyd.GalaxyTripGridEventType.EMPTY then
					self.gridEventImg:SetActive(false)
				end
			else
				updateMoreLinkEventGrid()
			end

			if self.parent:getBallId() ~= xyd.models.galaxyTrip:getBossMapId() then
				local isBatch = xyd.models.galaxyTrip:getGalaxyTripGetMainIsBatch()

				if isBatch and isBatch == 1 then
					local ids = xyd.models.galaxyTrip:getGalaxyTripGetMainIds()

					for i in pairs(ids) do
						if ids[i] == self.gridId then
							self:setPlanConVisible(true)
							self.planCon:X(self.gridBorder.width / 2)
							self.planCon:Y(-self.gridBorder.width / 2)

							local scale = self.gridBorder.width / self.planConUIWidget.width

							self.planCon:SetLocalScale(scale, scale, scale)
							self.planGridMark.gameObject:SetActive(true)

							self.planGridLabel.text = tostring(i)

							self.gridEventImg:SetActive(false)

							return
						end
					end
				end
			end

			if xyd.models.galaxyTrip:getIsMonster(self.eventType) and (gridState == xyd.GalaxyTripGridStateType.NO_OPEN or gridState == xyd.GalaxyTripGridStateType.CAN_GET) then
				local enemies = xyd.models.galaxyTrip:getGalaxyTripEnemiesHpInfo(self.gridId)

				if enemies then
					local status = enemies.status
					local allCount = #status * 100
					local curCount = 0

					for i in pairs(status) do
						curCount = curCount + tonumber(status[i].hp)
					end

					if allCount < curCount then
						curCount = allCount
					end

					if curCount > 0 then
						if self.eventType == xyd.GalaxyTripGridEventType.COMMON_ENEMY or self.eventType == xyd.GalaxyTripGridEventType.ELITE_ENEMY then
							self:setHpConVisible(true)

							self.hpBarUIProgressBar.value = curCount / allCount
						else
							self:setHpConVisible(false)
						end
					else
						self:setHpConVisible(true)

						self.hpBarUIProgressBar.value = 0
					end

					if gridState == xyd.GalaxyTripGridStateType.CAN_GET then
						self:setHpConVisible(true)

						self.hpBarUIProgressBar.value = 0
					end
				end

				if gridState == xyd.GalaxyTripGridStateType.CAN_GET then
					self:setHpConVisible(true)

					self.hpBarUIProgressBar.value = 0
				end
			end

			if gridState == xyd.GalaxyTripGridStateType.CAN_GET or gridState == xyd.GalaxyTripGridStateType.SEARCH_ING then
				self:setAnotherConVisible(true)
				self.getEffectCon.gameObject:SetActive(false)
				self.anotherCon:X(self.gridBorder.width / 2)
				self.anotherCon:Y(-self.gridBorder.height / 2)

				if gridState == xyd.GalaxyTripGridStateType.CAN_GET then
					if self.timeCount then
						self.timeCount:dispose()

						self.timeCount = nil
					end

					self.getEffectCon.gameObject:SetActive(true)

					if not self.getEffect then
						self.getEffect = xyd.Spine.new(self.getEffectCon.gameObject)

						self.getEffect:setInfo("fx_lost_space_camera", function ()
							self.getEffect:play("texiao01", 0)
						end)
					end

					self.timeShow.text = ""

					if self.eventType == xyd.GalaxyTripGridEventType.BOX or self.eventType == xyd.GalaxyTripGridEventType.EMPTY or self.eventType == xyd.GalaxyTripGridEventType.BUFF_4 or self.eventType == xyd.GalaxyTripGridEventType.BUFF_5 or self.eventType == xyd.GalaxyTripGridEventType.BUFF_6 or self.eventType == xyd.GalaxyTripGridEventType.BUFF_7 or self.eventType == xyd.GalaxyTripGridEventType.BUFF_8 then
						self.timeShow.text = "00:00:00"
					end
				elseif gridState == xyd.GalaxyTripGridStateType.SEARCH_ING then
					local next_time = xyd.models.galaxyTrip:getGalaxyTripGetMainNextTime()

					if self.timeCount then
						self.timeCount:dispose()

						self.timeCount = nil
					end

					local disTime = next_time - xyd.getServerTime()

					if disTime > 0 then
						self.timeCount = import("app.components.CountDown").new(self.timeShow)
						local secondStrType = xyd.SecondsStrType.NORMAL

						self.timeCount:setInfo({
							duration = disTime,
							callback = function ()
								self.timeShow.text = "00:00:00"
							end,
							secondStrType = secondStrType
						})
					else
						self.timeShow.text = "00:00:00"
					end
				end

				if xyd.models.galaxyTrip:getIsMonster(self.eventType) then
					self.timeShow.text = " "
				end
			end

			if self.eventType == xyd.GalaxyTripGridEventType.ROBBER_ENEMY then
				self:setAnotherConVisible(false)

				local expire_time = ballMap[self.posId].expire_time
				local disTime = expire_time - xyd.getServerTime()

				if self.timeCount then
					self.timeCount:dispose()

					self.timeCount = nil
				end

				if disTime > 0 then
					self.gridEventImg:SetActive(true)
					self:setAnotherConVisible(true)
					self.getEffectCon.gameObject:SetActive(false)

					local secondStrType = xyd.SecondsStrType.NORMAL
					self.timeCount = import("app.components.CountDown").new(self.timeShow)

					self.timeCount:setInfo({
						duration = disTime,
						callback = function ()
							self.timeShow.text = " "

							self.gridEventImg:SetActive(false)
						end,
						secondStrType = secondStrType
					})
				else
					self.gridEventImg:SetActive(false)
				end
			end

			self:setStartEndConVisible(false)

			if self.parent:getBallId() ~= xyd.models.galaxyTrip:getBossMapId() then
				local mapSize = xyd.tables.galaxyTripMapTable:getSize(self.parent:getBallId())
				local imgStr = "galaxy_trip_text_qd_" .. xyd.Global.lang
				local isShowStartEnd = false
				local posChangeY = 10

				if math.floor((self.posId - 1) / mapSize[1]) == mapSize[2] - 1 then
					isShowStartEnd = true
				elseif math.floor((self.posId - 1) / mapSize[1]) == 0 then
					isShowStartEnd = true
					imgStr = "galaxy_trip_text_zd_" .. xyd.Global.lang
					posChangeY = 6
				end

				if isShowStartEnd then
					self:setStartEndConVisible(true)
					self.startEndCon:Y(-self.gridBorder.height / 2 + posChangeY)
					xyd.setUISpriteAsync(self.startEndImg, nil, imgStr, nil, , true)
				end
			end
		end
	end

	self:resetImgPos()
end

function GridClass:resetImgPos()
	local gridMaskX = (self.gridBorder.width - self.gridMask.width) / 2
	local gridMaskY = (self.gridBorder.height - self.gridMask.height) / 2

	self.gridEventImg:SetLocalPosition(gridMaskX, gridMaskY, 0)

	local gridEventX = (self.gridBorder.width - self.gridEventImg.width) / 2
	local gridEventY = (self.gridBorder.height - self.gridEventImg.height) / 2

	self.gridEventImg:SetLocalPosition(gridEventX, gridEventY, 0)
end

function GridClass:checkIsMoreLinkEventFirst(eventType, posId)
	if not posId then
		posId = self.posId
	end

	local mapSize = xyd.tables.galaxyTripMapTable:getSize(self.parent:getBallId())
	local isFirstLeft = false

	if posId % mapSize[1] == 1 then
		isFirstLeft = true
	elseif self:getAssignGridEventType(posId - 1) ~= eventType then
		isFirstLeft = true
	end

	local isFirstTop = false

	if math.floor((posId - 1) / mapSize[1]) == 0 then
		isFirstTop = true
	elseif self:getAssignGridEventType(posId - mapSize[1]) ~= eventType then
		isFirstTop = true
	end

	if isFirstLeft and isFirstTop then
		return true
	end

	return false
end

function GridClass:checkAssignGirdisComplete(posId, isCheckPlanGrid)
	local checkEventType = self:getAssignGridEventType(posId)

	if not checkEventType or checkEventType < 0 then
		return false
	end

	local is14 = false

	if posId == 72 then
		is14 = true
	end

	local evetNeedGrid = xyd.tables.galaxyTripEventTypeTable:getSize(checkEventType)

	if evetNeedGrid[1] == 1 and evetNeedGrid[2] == 1 then
		-- Nothing
	else
		local evetNeedGrid = xyd.tables.galaxyTripEventTypeTable:getSize(checkEventType)

		if not self:checkIsMoreLinkEventFirst(checkEventType, posId) then
			local mapSize = xyd.tables.galaxyTripMapTable:getSize(self.parent:getBallId())

			for i = 1, evetNeedGrid[1] do
				if posId % mapSize[1] == 1 then
					break
				elseif self:getAssignGridEventType(posId - 1) == checkEventType then
					posId = posId - 1
				end
			end

			for i = 1, evetNeedGrid[2] do
				if math.floor((posId - 1) / mapSize[1]) == 0 then
					break
				elseif self:getAssignGridEventType(posId - mapSize[1]) == checkEventType then
					posId = posId - mapSize[1]
				end
			end
		end
	end

	local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.parent:getBallId())
	local ballMap = ballMapInfo.map
	local gridId = ballMap[posId].gridId
	local ballOpened = ballMapInfo.opened

	if xyd.models.galaxyTrip:getGridState(gridId, self.parent:getBallId()) == xyd.GalaxyTripGridStateType.GET_YET then
		return true
	end

	if isCheckPlanGrid then
		local readyPlanGridArr = self.parent:getReadyPlanGridArr()

		for i in pairs(readyPlanGridArr) do
			if readyPlanGridArr[i] == gridId then
				return true
			end
		end
	end

	return false
end

function GridClass:getAssignGridEventType(posId)
	local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.parent:getBallId())
	local ballMap = ballMapInfo.map
	local eventArr = xyd.split(ballMap[posId].info, "#", true)
	local eventId = eventArr[1]

	if eventId == xyd.GalaxyTripGridEventType.NOTHING then
		return xyd.GalaxyTripGridEventType.NOTHING
	end

	local eventType = xyd.tables.galaxyTripEventTable:getType(eventId)

	return eventType
end

function GridClass:checkCurGridIsCanSearch()
	if self.parent:getBallId() == xyd.models.galaxyTrip:getBossMapId() then
		self.isCanSearch = true

		return
	end

	self.isCanSearch = false
	self.isLock = false

	if self.go.gameObject.activeSelf and self.gridMask.gameObject.activeSelf then
		if not self:checkAssignGirdisComplete(self.posId) then
			local mapSize = xyd.tables.galaxyTripMapTable:getSize(self.parent:getBallId())

			if math.floor((self.posId - 1) / mapSize[1]) == mapSize[2] - 1 then
				self.isCanSearch = true

				xyd.setUISpriteAsync(self.gridMask, nil, xyd.tables.galaxyTripMapTable:getIconMaskText(self.parent:getBallId()))

				self.gridMask.alpha = 1

				return
			end

			local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.parent:getBallId())
			local ballMap = ballMapInfo.map
			local borderArr = self:getBoderArr()

			for i in pairs(borderArr) do
				if self:checkAssignGirdisComplete(borderArr[i]) then
					self.isCanSearch = true

					xyd.setUISpriteAsync(self.gridMask, nil, xyd.tables.galaxyTripMapTable:getIconMaskText(self.parent:getBallId()))

					self.gridMask.alpha = 1

					return
				end
			end

			self.gridMask.alpha = 0.64
			self.isLock = true

			xyd.setUISpriteAsync(self.gridMask, nil, "galaxy_trip_mask_default")
		end
	end
end

function GridClass:checkCurGridIsCanPlanReady()
	self.isCanReady = false

	if self.parent:getBallId() == xyd.models.galaxyTrip:getBossMapId() then
		return
	end

	self:setPlanConVisible(false)

	if not self.parent:getIsPlanReady() then
		return
	end

	if self.go.gameObject.activeSelf and self.gridMask.gameObject.activeSelf then
		if not self:checkAssignGirdisComplete(self.posId) then
			local function isCanReadyFun()
				if xyd.models.galaxyTrip:getIsMonster(self.eventType) then
					return
				end

				self:setPlanConVisible(true)
				self.planCon:X(self.gridBorder.width / 2)
				self.planCon:Y(-self.gridBorder.width / 2)

				local scale = self.gridBorder.width / self.planConUIWidget.width

				self.planCon:SetLocalScale(scale, scale, scale)

				self.isCanReady = true

				self.planGridMark.gameObject:SetActive(false)

				local readyPlanGridArr = self.parent:getReadyPlanGridArr()

				for k in pairs(readyPlanGridArr) do
					if readyPlanGridArr[k] == self.gridId then
						self.planGridMark.gameObject:SetActive(true)

						self.planGridLabel.text = tostring(k)
					end
				end
			end

			local mapSize = xyd.tables.galaxyTripMapTable:getSize(self.parent:getBallId())

			if math.floor((self.posId - 1) / mapSize[1]) == mapSize[2] - 1 then
				isCanReadyFun()

				return
			end

			local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.parent:getBallId())
			local ballMap = ballMapInfo.map
			local borderArr = self:getBoderArr()

			for i in pairs(borderArr) do
				if self:checkAssignGirdisComplete(borderArr[i], true) then
					isCanReadyFun()

					return
				end
			end
		end
	end
end

function GridClass:getBoderArr()
	local borderArr = {}
	local mapSize = xyd.tables.galaxyTripMapTable:getSize(self.parent:getBallId())
	local evetNeedGrid = xyd.tables.galaxyTripEventTypeTable:getSize(self.eventType)

	if self.posId % mapSize[1] ~= 1 then
		for i = 1, evetNeedGrid[2] do
			table.insert(borderArr, self.posId - 1 + mapSize[1] * (i - 1))
		end
	end

	if self.posId % mapSize[1] ~= 0 then
		if (self.posId + evetNeedGrid[1] - 1) % mapSize[1] ~= 0 then
			for i = 1, evetNeedGrid[2] do
				table.insert(borderArr, self.posId + evetNeedGrid[1] + mapSize[1] * (i - 1))
			end
		end
	end

	if math.floor((self.posId - 1) / mapSize[1]) ~= 0 then
		for i = 1, evetNeedGrid[1] do
			table.insert(borderArr, self.posId - mapSize[1] + i - 1)
		end
	end

	if math.floor((self.posId - 1) / mapSize[1]) ~= mapSize[2] - 1 then
		for i = 1, evetNeedGrid[1] do
			table.insert(borderArr, self.posId + mapSize[1] * evetNeedGrid[2] + i - 1)
		end
	end

	return borderArr
end

function GridClass:onTouch()
	local gridState = xyd.models.galaxyTrip:getGridState(self.gridId, self.parent:getBallId())

	if self.parent:getBallId() == xyd.models.galaxyTrip:getBossMapId() then
		if self.eventType == xyd.GalaxyTripGridEventType.ROBBER_ENEMY then
			local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.parent:getBallId())
			local ballMap = ballMapInfo.map
			local expire_time = ballMap[self.posId].expire_time

			if expire_time and xyd.getServerTime() < expire_time then
				self:openEventWindow()
			end
		elseif self.eventType == xyd.GalaxyTripGridEventType.BLACK_HOLE_BOSS then
			self:openEventWindow()
		end

		return
	end

	if gridState == xyd.GalaxyTripGridStateType.GET_YET and not xyd.models.galaxyTrip:getIsBuff(self.eventType) then
		return
	end

	if self.isCanReady then
		local readyPlanGridArr = self.parent:getReadyPlanGridArr()
		local isHas = false

		for k in pairs(readyPlanGridArr) do
			if readyPlanGridArr[k] == self.gridId then
				isHas = true

				self.parent:setReadyPlanGridArr(self.gridId, true)

				break
			end
		end

		if not isHas then
			self.parent:setReadyPlanGridArr(self.gridId)
		end

		return
	end

	if self.parent:getIsPlanReady() then
		xyd.alertTips(__("GALAXY_TRIP_TIPS_09"))

		return
	end

	local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.parent:getBallId())
	local ballMap = ballMapInfo.map

	self:openEventWindow()
end

function GridClass:openEventWindow()
	if xyd.models.galaxyTrip:getIsMonster(self.eventType) or self.eventType == xyd.GalaxyTripGridEventType.ROBBER_ENEMY or self.eventType == xyd.GalaxyTripGridEventType.BLACK_HOLE_BOSS then
		xyd.WindowManager.get():openWindow("galaxy_trip_fight_window", {
			posId = self.posId,
			eventId = self.eventId,
			ballId = self.parent:getBallId(),
			isLock = self.isLock
		})
	elseif self.eventType == xyd.GalaxyTripGridEventType.BOX or self.eventType == xyd.GalaxyTripGridEventType.EMPTY then
		if self.parent:getBallId() == xyd.models.galaxyTrip:getBossMapId() then
			return
		end

		xyd.WindowManager.get():openWindow("galaxy_trip_common_event_window", {
			posId = self.posId,
			eventId = self.eventId,
			ballId = self.parent:getBallId(),
			isLock = self.isLock
		})
	elseif xyd.models.galaxyTrip:getIsBuff(self.eventType) then
		if self.parent:getBallId() == xyd.models.galaxyTrip:getBossMapId() then
			return
		end

		xyd.WindowManager.get():openWindow("galaxy_trip_buff_window", {
			posId = self.posId,
			eventId = self.eventId,
			ballId = self.parent:getBallId(),
			isLock = self.isLock
		})
	end
end

function GridClass:getAnotherCon()
	if not self.anotherCon then
		self.anotherCon = NGUITools.AddChild(self.go.gameObject, self.parent.canGetCon.gameObject)
		self.anotherConUIWidget = self.anotherCon:GetComponent(typeof(UIWidget))
		self.timeShow = self.anotherCon:ComponentByName("timeShow", typeof(UILabel))
		self.getEffectCon = self.anotherCon:ComponentByName("getEffectCon", typeof(UITexture))
		local evetNeedGrid = xyd.tables.galaxyTripEventTypeTable:getSize(self.eventType)
		local xScale = 1 * evetNeedGrid[1]
		local yScale = 1.1 * evetNeedGrid[2]
		local yPos = -4.5 * evetNeedGrid[2]

		self.anotherCon:X(self.gridBorder.width / 2)
		self.anotherCon:Y(-self.gridBorder.height / 2)
		self.getEffectCon.gameObject:SetLocalScale(0.9 * xScale, 0.9 * yScale, 1)
		self.getEffectCon.gameObject:Y(yPos)
	end

	return self.anotherCon
end

function GridClass:setAnotherConVisible(visible)
	if visible and not self.anotherCon then
		self:getAnotherCon()
	end

	if self.anotherCon then
		self.anotherCon:SetActive(visible)
	end
end

function GridClass:getPlanCon()
	if not self.planCon then
		self.planCon = NGUITools.AddChild(self.go.gameObject, self.parent.planGridCon.gameObject)
		self.planConUIWidget = self.planCon:GetComponent(typeof(UIWidget))
		self.planGridBg = self.planCon:ComponentByName("planGridBg", typeof(UISprite))
		self.planGridMark = self.planCon:ComponentByName("planGridMark", typeof(UISprite))
		self.planGridLabel = self.planGridMark:ComponentByName("planGridLabel", typeof(UILabel))
	end

	return self.planCon
end

function GridClass:setPlanConVisible(visible)
	if visible and not self.planCon then
		self:getPlanCon()
	end

	if self.planCon then
		self.planCon:SetActive(visible)
	end
end

function GridClass:getHpCon()
	if not self.hpCon then
		self.hpCon = NGUITools.AddChild(self.go.gameObject, self.parent.gridHpCon.gameObject)
		self.hpConUIWidget = self.hpCon:GetComponent(typeof(UIWidget))
		self.hpBar = self.hpCon:ComponentByName("hpBar", typeof(UISprite))
		self.hpBarUIProgressBar = self.hpCon:ComponentByName("hpBar", typeof(UIProgressBar))
		self.hpThumb2 = self.hpBar:ComponentByName("hpThumb2", typeof(UISprite))
		self.hpBar.width = self.gridBorder.width - 2
		self.hpThumb2.width = self.hpBar.width
		self.hpConUIWidget.width = self.gridBorder.width
		self.hpConUIWidget.height = self.gridBorder.height

		self.hpCon:X(self.gridBorder.width / 2)
		self.hpCon:Y(-self.gridBorder.height / 2)
	end

	return self.hpCon
end

function GridClass:setHpConVisible(visible)
	if visible and not self.hpCon then
		self:getHpCon()
	end

	if self.hpCon then
		self.hpCon:SetActive(visible)
	end
end

function GridClass:getStartEndCon()
	if not self.startEndCon then
		self.startEndCon = NGUITools.AddChild(self.go.gameObject, self.parent.startEndCon.gameObject)
		self.startEndImg = self.startEndCon:ComponentByName("startEndImg", typeof(UISprite))

		self.startEndCon:X(self.gridBorder.width / 2)
	end

	return self.startEndCon
end

function GridClass:setStartEndConVisible(visible)
	if visible and not self.startEndCon then
		self:getStartEndCon()
	end

	if self.startEndCon then
		self.startEndCon:SetActive(visible)
	end
end

return GalaxyTripMapWindow
