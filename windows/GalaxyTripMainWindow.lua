local GalaxyTripMainWindow = class("GalaxyTripMainWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local GalaxyItemClass = class("GalaxyItemClass")

function GalaxyTripMainWindow:ctor(name, params)
	GalaxyTripMainWindow.super.ctor(self, name, params)
end

function GalaxyTripMainWindow:initWindow()
	self:getUIComponent()
	GalaxyTripMainWindow.super.initWindow(self)
	self:reSize()
	self:registerEvent()
	self:layout()

	local curMapId = xyd.models.galaxyTrip:getGalaxyTripGetCurMap()

	if curMapId ~= 0 then
		local curMapInfo = xyd.models.galaxyTrip:getBallInfo(curMapId)
		local isFiveSend = false
		local lastSendTime = xyd.db.misc:getValue("galaxy_last_send_check_time")

		if not lastSendTime then
			isFiveSend = true
		else
			lastSendTime = tonumber(lastSendTime)

			if xyd.getServerTime() - lastSendTime > 300 then
				isFiveSend = true
			end
		end

		if not curMapInfo or isFiveSend then
			local msg = messages_pb:galaxy_trip_get_map_info_req()
			msg.id = curMapId

			xyd.Backend.get():request(xyd.mid.GALAXY_TRIP_GET_MAP_INFO, msg)
			xyd.db.misc:setValue({
				key = "galaxy_last_send_check_time",
				value = xyd.getServerTime()
			})
		end
	end
end

function GalaxyTripMainWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.bg = self.groupAction:ComponentByName("bg", typeof(UITexture))
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.nameImg = self.upCon:ComponentByName("nameImg", typeof(UISprite))
	self.timeCon = self.upCon:NodeByName("timeCon").gameObject
	self.timeConUILayout = self.upCon:ComponentByName("timeCon", typeof(UILayout))
	self.timeLabel = self.timeCon:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeCon:ComponentByName("endLabel", typeof(UILabel))
	self.tipsBtn = self.upCon:NodeByName("tipsBtn").gameObject
	self.rankBtn = self.upCon:NodeByName("rankBtn").gameObject
	self.passBtn = self.upCon:NodeByName("passBtn").gameObject
	self.passBtnRedPoint = self.passBtn:NodeByName("passBtnRedPoint").gameObject

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.GALAXY_TRIP
	}, self.passBtnRedPoint)

	self.shopBtn = self.upCon:NodeByName("shopBtn").gameObject
	self.downCon = self.groupAction:NodeByName("downCon").gameObject
	self.progressBtnCon = self.downCon:NodeByName("progressBtnCon").gameObject
	self.progressBtn = self.progressBtnCon:NodeByName("progressBtn").gameObject
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
	self.content = self.scrollerPanel:NodeByName("content").gameObject
	self.contentUIWrapContent = self.scrollerPanel:ComponentByName("content", typeof(UIWrapContent))
	self.drag = self.centerCon:NodeByName("drag").gameObject
	self.galaxyItem = self.centerCon:NodeByName("galaxyItem").gameObject
	self.ballMultiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollerPanelUIScrollView, self.contentUIWrapContent, self.galaxyItem, GalaxyItemClass, self)
end

function GalaxyTripMainWindow:reSize()
	self:resizePosY(self.upCon, 500, 558)
	self:resizePosY(self.downCon, -510, -576)
	self:resizePosY(self.bg, -136, -73)
end

function GalaxyTripMainWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GALAXY_TRIP_GET_MAP_INFO, handler(self, self.onGetGalaxyTripMapInfoBack))
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

	UIEventListener.Get(self.backBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.rankBtn.gameObject).onClick = handler(self, function ()
		if not xyd.models.galaxyTrip:needReqRankInfo() then
			local data = xyd.models.galaxyTrip:getRankData()

			xyd.openWindow("common_rank_with_award_window", data)
		end
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
	UIEventListener.Get(self.tipsBtn.gameObject).onClick = handler(self, function ()
		xyd.openWindow("help_window", {
			key = "GALAXY_TRIP_HELP01"
		})
	end)
	UIEventListener.Get(self.teamBtn.gameObject).onClick = handler(self, function ()
		dump(xyd.models.galaxyTrip:getGalaxyTripGetMainTeamsInfo())
		xyd.openWindow("galaxy_trip_formation_window", {
			formation = xyd.models.galaxyTrip:getGalaxyTripGetMainTeamsInfo()
		})
	end)
end

function GalaxyTripMainWindow:layout()
	self.endLabel.transform:SetSiblingIndex(0)
	self.timeLabel.transform:SetSiblingIndex(1)

	self.endLabel.text = __("GALAXY_TRIP_TEXT75")
	self.teamBtnLabel.text = __("GALAXY_TRIP_TEXT22")
	self.timeCount = import("app.components.CountDown").new(self.timeLabel)
	local disTime = xyd.models.galaxyTrip:getLeftTime()

	if xyd.DAY_TIME < disTime then
		disTime = disTime - xyd.DAY_TIME
	else
		self.endLabel.text = __("GALAXY_TRIP_TEXT76")
	end

	self.timeCount:setInfo({
		duration = disTime,
		callback = function ()
			self:waitForTime(2, function ()
				self.timeLabel.text = "00:00:00"
			end)
		end
	})

	local wnd = xyd.getWindow("galaxy_trip_map_window")

	if wnd then
		xyd.closeWindow("galaxy_trip_map_window")
	end

	self.backBtnLabel.text = __("GALAXY_TRIP_TEXT21")

	xyd.setUISpriteAsync(self.nameImg, nil, "galaxy_trip_text_logo_" .. xyd.Global.lang)
	self:initTop()
	self:updateProgress()
	self:updateBallShow()
end

function GalaxyTripMainWindow:initTop()
	self.windowTop = WindowTop.new(self.window_, self.name_, 50)
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

function GalaxyTripMainWindow:updateProgress()
	local value = 25
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

function GalaxyTripMainWindow:updateBallShow()
	local ids = xyd.tables.galaxyTripMapTable:getIDs()
	local arr = {}

	for i in pairs(ids) do
		table.insert(arr, {
			ballId = ids[i]
		})
	end

	self.ballMultiWrap_:setInfos(arr, {})

	if not self.isFirstInitBallShow then
		self.scrollerPanelUIScrollView:ResetPosition()

		self.isFirstInitBallShow = true
	end
end

function GalaxyTripMainWindow:onGetGalaxyTripMapInfoBack()
	self:updateBallShow()
end

function GalaxyItemClass:ctor(go, parent)
	self.go = go
	self.selfNum = 0
	self.curID = 0
	self.parent = parent

	self:initUI()
end

function GalaxyItemClass:getUIComponent()
	self.allCon = self.go:NodeByName("allCon").gameObject
	self.galaxyImg = self.allCon:ComponentByName("galaxyImg", typeof(UISprite))
	self.downCon = self.allCon:NodeByName("downCon").gameObject
	self.progress = self.downCon:ComponentByName("progress", typeof(UISprite))
	self.progressUIProgressBar = self.downCon:ComponentByName("progress", typeof(UIProgressBar))
	self.labelDesc = self.progress:ComponentByName("labelDesc", typeof(UILabel))
	self.progressValue = self.progress:ComponentByName("progressValue", typeof(UISprite))
	self.galaxyName = self.downCon:ComponentByName("galaxyName", typeof(UILabel))
	self.galaxyStateCon = self.downCon:NodeByName("galaxyStateCon").gameObject
	self.galaxyStateIcon = self.galaxyStateCon:ComponentByName("galaxyStateIcon", typeof(UISprite))
	self.galaxyStateLabel = self.galaxyStateCon:ComponentByName("galaxyStateLabel", typeof(UILabel))
	self.redPoint = self.allCon:ComponentByName("redPoint", typeof(UISprite))
end

function GalaxyItemClass:initUI()
	self:getUIComponent()
	self:registerEvent()
end

function GalaxyItemClass:registerEvent()
	UIEventListener.Get(self.allCon.gameObject).onClick = handler(self, self.onTouch)
end

function GalaxyItemClass:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.ballId = info.ballId

	if self.ballId == 1 then
		self.parent.firstBallObj = self.allCon
	end

	if self.ballId % 3 == 2 then
		self.allCon:Y(-51)
	end

	local galaxyNameId = xyd.tables.galaxyTripMapTable:getNameTextId(self.ballId)
	self.galaxyName.text = xyd.tables.galaxyTripMapTextTable:getDesc(galaxyNameId)
	self.progressUIProgressBar.value = 0
	self.labelDesc.text = "0%"
	local allMaxId = xyd.models.galaxyTrip:getGalaxyTripGetMaxMap()
	local mapSeason = xyd.tables.galaxyTripMapTable:getBeginSeason(self.ballId)

	if self.ballId ~= xyd.models.galaxyTrip:getBossMapId() and (allMaxId < self.ballId or xyd.models.galaxyTrip:getGalaxyTripGetMainCount() < mapSeason) then
		xyd.setUISpriteAsync(self.galaxyImg, nil, "galaxy_trip_ball_lock", nil, , true)
	else
		local imgIcon = xyd.tables.galaxyTripMapTable:getIconText(self.ballId)

		xyd.setUISpriteAsync(self.galaxyImg, nil, imgIcon, nil, , true)
	end

	if self.ballId == xyd.models.galaxyTrip:getBossMapId() then
		local numArr = xyd.tables.miscTable:split2num("galaxy_trip_black_hole_open", "value", "|")

		if numArr[1] < allMaxId then
			local imgIcon = xyd.tables.galaxyTripMapTable:getIconText(self.ballId)

			xyd.setUISpriteAsync(self.galaxyImg, nil, imgIcon, nil, , true)
		else
			xyd.setUISpriteAsync(self.galaxyImg, nil, "galaxy_trip_ball_lock", nil, , true)
		end
	end

	self.redPoint.gameObject:SetActive(false)

	if self.ballId == xyd.models.galaxyTrip:getGalaxyTripGetCurMap() then
		self.galaxyStateCon.gameObject:SetActive(true)

		self.galaxyStateLabel.text = __("GALAXY_TRIP_TEXT05")

		if xyd.Global.lang == "fr_fr" then
			self.galaxyStateLabel.height = 29

			self.galaxyStateCon:Y(-24)
		end

		local value = xyd.models.galaxyTrip:getGalaxyProgress(self.ballId)
		self.labelDesc.text = tostring(value) .. "%"
		self.progressUIProgressBar.value = value / 100

		self.redPoint.gameObject:SetActive(xyd.models.galaxyTrip:getIsHasCanGetPoint())
	else
		self.galaxyStateCon.gameObject:SetActive(false)
	end

	if self.ballId == xyd.models.galaxyTrip:getBossMapId() then
		self.progress.gameObject:SetActive(false)

		self.galaxyName.alignment = NGUIText.Alignment.Center

		self.galaxyName:X(-72)
	end
end

function GalaxyItemClass:getGameObject()
	return self.go
end

function GalaxyItemClass:onTouch()
	local allMaxId = xyd.models.galaxyTrip:getGalaxyTripGetMaxMap()

	if self.ballId == xyd.models.galaxyTrip:getBossMapId() then
		local numArr = xyd.tables.miscTable:split2num("galaxy_trip_black_hole_open", "value", "|")

		if numArr[1] < allMaxId then
			if xyd.getServerTime() < xyd.tables.miscTable:getNumber("galaxy_trip_black_hole_open_time", "value") then
				xyd.alertTips(__("GALAXY_TRIP_TIPS_19"))

				return
			end

			xyd.WindowManager.get():openWindow("galaxy_trip_enter_window", {
				ballId = self.ballId
			})
		else
			xyd.alertTips(__("GALAXY_TRIP_TIPS_18", numArr[1]))

			return
		end

		return
	end

	local mapSeason = xyd.tables.galaxyTripMapTable:getBeginSeason(self.ballId)

	if xyd.models.galaxyTrip:getGalaxyTripGetMainCount() < mapSeason then
		xyd.alertTips(__("GALAXY_TRIP_TIPS_05"))

		return
	end

	if allMaxId and allMaxId < self.ballId then
		xyd.alertTips(__("GALAXY_TRIP_TIPS_04"))

		return
	end

	xyd.WindowManager.get():openWindow("galaxy_trip_enter_window", {
		ballId = self.ballId
	})
end

return GalaxyTripMainWindow
