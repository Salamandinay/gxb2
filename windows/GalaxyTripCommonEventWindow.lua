local GalaxyTripCommonEventWindow = class("GalaxyTripCommonEventWindow", import(".BaseWindow"))

function GalaxyTripCommonEventWindow:ctor(name, params)
	GalaxyTripCommonEventWindow.super.ctor(self, name, params)

	self.eventId = params.eventId
	self.ballId = params.ballId
	self.posId = params.posId
	self.isLock = params.isLock
end

function GalaxyTripCommonEventWindow:initWindow()
	self:getUIComponent()
	GalaxyTripCommonEventWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
	self:updateStateLabel()
end

function GalaxyTripCommonEventWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.titleGroup = self.groupAction:NodeByName("titleGroup").gameObject
	self.labelTitle = self.titleGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.titleGroup:NodeByName("closeBtn").gameObject
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.upConBg = self.upCon:ComponentByName("upConBg", typeof(UITexture))
	self.upGalaxyIcon = self.upCon:ComponentByName("upGalaxyIcon", typeof(UISprite))
	self.panelCon = self.upCon:NodeByName("panelCon").gameObject
	self.descPanel = self.panelCon:NodeByName("descPanel").gameObject
	self.descPanelUIPanel = self.panelCon:ComponentByName("descPanel", typeof(UIPanel))
	self.descPanelUIScrollView = self.panelCon:ComponentByName("descPanel", typeof(UIScrollView))
	self.descCon = self.descPanel:NodeByName("descCon").gameObject
	self.descLabel = self.descCon:ComponentByName("descLabel", typeof(UILabel))
	self.bookCon = self.descCon:NodeByName("bookCon").gameObject
	self.bookLabel = self.bookCon:ComponentByName("bookLabel", typeof(UILabel))
	self.timeLabel = self.upCon:ComponentByName("timeLabel", typeof(UILabel))
	self.descStaticCon = self.upCon:NodeByName("descStaticCon").gameObject
	self.descStaticLabel = self.descStaticCon:ComponentByName("descStaticLabel", typeof(UILabel))
	self.bookStaticCon = self.descStaticCon:NodeByName("bookStaticCon").gameObject
	self.bookStaticLabel = self.bookStaticCon:ComponentByName("bookStaticLabel", typeof(UILabel))
	self.btnCon = self.groupAction:NodeByName("btnCon").gameObject
	self.challengeBtn = self.btnCon:NodeByName("challengeBtn").gameObject
	self.challengeBtnBoxCollider = self.btnCon:ComponentByName("challengeBtn", typeof(UnityEngine.BoxCollider))
	self.challengeBtnLabel = self.challengeBtn:ComponentByName("challengeBtnLabel", typeof(UILabel))
	self.centerCon = self.groupAction:NodeByName("centerCon").gameObject
	self.centerNameCon2 = self.centerCon:NodeByName("centerNameCon2").gameObject
	self.centerConName2 = self.centerNameCon2:ComponentByName("centerConName2", typeof(UILabel))
	self.centerConLayout2 = self.centerNameCon2:NodeByName("centerConLayout2").gameObject
	self.centerConLayout2UILayout = self.centerNameCon2:ComponentByName("centerConLayout2", typeof(UILayout))
	self.stateLabel = self.groupAction:ComponentByName("stateLabel", typeof(UILabel))
end

function GalaxyTripCommonEventWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.challengeBtn.gameObject).onClick = handler(self, function ()
		if self.gridState == xyd.GalaxyTripGridStateType.NO_OPEN then
			local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.ballId)
			local ballMap = ballMapInfo.map

			for i in pairs(ballMap) do
				local gridState = xyd.models.galaxyTrip:getGridState(ballMap[i].gridId, self.ballId)

				if gridState == xyd.GalaxyTripGridStateType.CAN_GET then
					xyd.alertTips(__("GALAXY_TRIP_TIPS_17"))

					return
				end

				if gridState == xyd.GalaxyTripGridStateType.SEARCH_ING then
					xyd.alertTips(__("GALAXY_TRIP_TIPS_16"))

					return
				end
			end

			local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.ballId)
			local ballMap = ballMapInfo.map
			local msg = messages_pb:galaxy_trip_grid_ids_req()

			table.insert(msg.ids, ballMap[self.posId].gridId)

			msg.is_batch = 0

			xyd.Backend.get():request(xyd.mid.GALAXY_TRIP_GRID_IDS, msg)
		end

		if self.gridState == xyd.GalaxyTripGridStateType.CAN_GET then
			local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.ballId)
			local ballMap = ballMapInfo.map
			local msg = messages_pb:galaxy_trip_get_map_awards_req()

			table.insert(msg.ids, ballMap[self.posId].gridId)
			xyd.Backend.get():request(xyd.mid.GALAXY_TRIP_GET_MAP_AWARDS, msg)
		end
	end)
end

function GalaxyTripCommonEventWindow:layout()
	self.centerConName2.text = __("GALAXY_TRIP_TEXT30")

	self:needUpdateShowInfo()
	xyd.setUISpriteAsync(self.res_icon, nil, xyd.tables.itemTable:getIcon(xyd.ItemID.GALAXY_TRIP_TICKET), nil, true)
	self:initUp()
end

function GalaxyTripCommonEventWindow:initUp()
	local eventTypeId = xyd.tables.galaxyTripEventTable:getType(self.eventId)
	local galaxyNameId = xyd.tables.galaxyTripEventTypeTable:getNameTextId(eventTypeId)
	self.labelTitle.text = xyd.tables.galaxyTripEventTypeTextTable:getDesc(galaxyNameId)
	local galaxyIntroId = xyd.tables.galaxyTripEventTypeTable:getIntroTextId(eventTypeId)
	self.descStaticLabel.text = xyd.tables.galaxyTripEventTypeTextTable:getDesc(galaxyIntroId)
	self.bookStaticLabel.text = __("GALAXY_TRIP_TEXT52")
	local allTextHeight = self.descStaticLabel.height + self.bookStaticLabel.height

	if allTextHeight <= self.descPanelUIPanel:GetViewSize().y - self.descPanelUIScrollView.padding.y then
		self.panelCon:SetActive(false)
		self.descStaticCon:SetActive(true)
		self.descStaticCon:Y(130 + allTextHeight / 2)
	else
		self.descLabel.text = xyd.tables.galaxyTripEventTypeTextTable:getDesc(galaxyIntroId)
		self.bookLabel.text = __("GALAXY_TRIP_TEXT52")

		self.panelCon:SetActive(true)
		self.descStaticCon:SetActive(false)
		self:waitForFrame(2, function ()
			self.descPanelUIScrollView:ResetPosition()
		end)
	end

	local imgIcon = xyd.tables.galaxyTripEventTypeTable:getIconBigText(eventTypeId)

	xyd.setUISpriteAsync(self.upGalaxyIcon, nil, imgIcon, nil, , true)

	local time = xyd.tables.galaxyTripEventTypeTable:getTime(eventTypeId)
	self.timeLabel.text = __("GALAXY_TRIP_TEXT27", math.floor(time / xyd.HOUR))
end

function GalaxyTripCommonEventWindow:updateStateLabel()
	local eventType = xyd.tables.galaxyTripEventTable:getType(self.eventId)
	local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.ballId)
	local ballMap = ballMapInfo.map
	local award1 = xyd.tables.galaxyTripEventTable:getAward1(self.eventId)

	for i in pairs(award1) do
		local item = {
			scale = 0.7037037037037037,
			uiRoot = self.centerConLayout2.gameObject,
			itemID = award1[i][1],
			num = xyd.models.galaxyTrip:getAwardNumWithBuff(award1[i][2], 1)
		}
		local icon = xyd.getItemIcon(item, xyd.ItemIconType.ADVANCE_ICON)
	end

	local award2 = xyd.tables.galaxyTripEventTable:getAward2(self.eventId)

	for i in pairs(award2) do
		local item = {
			scale = 0.7037037037037037,
			uiRoot = self.centerConLayout2.gameObject,
			itemID = award2[i][1],
			num = xyd.models.galaxyTrip:getAwardNumWithBuff(award2[i][2], 2)
		}
		local icon = xyd.getItemIcon(item, xyd.ItemIconType.ADVANCE_ICON)
	end

	local award3 = xyd.tables.galaxyTripEventTable:getAward3(self.eventId)

	for i in pairs(award3) do
		local item = {
			scale = 0.7037037037037037,
			uiRoot = self.centerConLayout2.gameObject,
			itemID = award3[i][1],
			num = award3[i][2]
		}
		local icon = xyd.getItemIcon(item, xyd.ItemIconType.ADVANCE_ICON)
	end

	self.centerConLayout2UILayout:Reposition()
end

function GalaxyTripCommonEventWindow:needUpdateShowInfo()
	local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.ballId)
	local ballMap = ballMapInfo.map
	local gridId = ballMap[self.posId].gridId
	self.gridState = xyd.models.galaxyTrip:getGridState(gridId, self.ballId)

	xyd.applyChildrenOrigin(self.challengeBtn)

	self.challengeBtnBoxCollider.enabled = true

	self.stateLabel.gameObject:SetActive(false)

	self.challengeBtnLabel.text = __("GALAXY_TRIP_TEXT28")

	if self.gridState == xyd.GalaxyTripGridStateType.NO_OPEN then
		self.challengeBtnLabel.text = __("GALAXY_TRIP_TEXT28")

		if self.isLock then
			xyd.applyChildrenGrey(self.challengeBtn)

			self.challengeBtnBoxCollider.enabled = false
		end
	else
		if self.isLock then
			xyd.applyChildrenGrey(self.challengeBtn)

			self.challengeBtnBoxCollider.enabled = false

			return
		end

		self.challengeBtnLabel.text = __("GET2")

		if self.gridState == xyd.GalaxyTripGridStateType.SEARCH_ING then
			xyd.applyChildrenGrey(self.challengeBtn)

			self.challengeBtnBoxCollider.enabled = false
			local nextTime = xyd.models.galaxyTrip:getGalaxyTripGetMainNextTime()
			local disTime = nextTime - xyd:getServerTime()

			if disTime > 0 then
				self.stateLabel.gameObject:SetActive(true)

				if self.timeCount then
					self.timeCount:dispose()

					self.timeCount = nil
				end

				self.timeCount = import("app.components.CountDown").new(self.stateLabel)

				self.timeCount:setInfo({
					duration = disTime + 1,
					callback = function ()
						self:needUpdateShowInfo()
						self:waitForTime(2, function ()
							self:needUpdateShowInfo()
						end)
					end
				})
			end

			self:waitForTime(1, function ()
				self:needUpdateShowInfo()
			end)
			self:waitForTime(2, function ()
				self:needUpdateShowInfo()
			end)
		elseif self.gridState == xyd.GalaxyTripGridStateType.CAN_GET then
			xyd.applyChildrenOrigin(self.challengeBtn)

			self.challengeBtnBoxCollider.enabled = true

			self.stateLabel.gameObject:SetActive(false)
		end
	end
end

return GalaxyTripCommonEventWindow
