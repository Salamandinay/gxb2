local GalaxyTripEnterWindow = class("GalaxyTripEnterWindow", import(".BaseWindow"))

function GalaxyTripEnterWindow:ctor(name, params)
	GalaxyTripEnterWindow.super.ctor(self, name, params)

	self.ballId = params.ballId
end

function GalaxyTripEnterWindow:initWindow()
	self:getUIComponent()
	GalaxyTripEnterWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
	self:updateStateLabel()
end

function GalaxyTripEnterWindow:getUIComponent()
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
	self.descStaticCon = self.upCon:NodeByName("descStaticCon").gameObject
	self.descStaticLabel = self.descStaticCon:ComponentByName("descStaticLabel", typeof(UILabel))
	self.bookStaticCon = self.descStaticCon:NodeByName("bookStaticCon").gameObject
	self.bookStaticLabel = self.bookStaticCon:ComponentByName("bookStaticLabel", typeof(UILabel))
	self.stateLabel = self.groupAction:ComponentByName("stateLabel", typeof(UILabel))
	self.btnCon = self.groupAction:NodeByName("btnCon").gameObject
	self.enterBtn = self.btnCon:NodeByName("enterBtn").gameObject
	self.enterBtnLabel = self.enterBtn:ComponentByName("enterBtnLabel", typeof(UILabel))
	self.centerCon = self.groupAction:NodeByName("centerCon").gameObject
	self.centerConBg = self.centerCon:ComponentByName("centerConBg", typeof(UISprite))
	self.centerNameCon = self.centerCon:NodeByName("centerNameCon").gameObject
	self.centerConName = self.centerNameCon:ComponentByName("centerConName", typeof(UILabel))
	self.centerNameLine1 = self.centerNameCon:ComponentByName("centerNameLine1", typeof(UISprite))
	self.centerNameLine2 = self.centerNameCon:ComponentByName("centerNameLine2", typeof(UISprite))
	self.textCon1 = self.centerCon:NodeByName("textCon1").gameObject
	self.textName1 = self.textCon1:ComponentByName("textName1", typeof(UILabel))
	self.textNameBg1 = self.textCon1:ComponentByName("textNameBg1", typeof(UISprite))
	self.textNameLine1 = self.textCon1:ComponentByName("textNameLine1", typeof(UISprite))
	self.textNameNum1 = self.textCon1:ComponentByName("textNameNum1", typeof(UILabel))
	self.textCon2 = self.centerCon:NodeByName("textCon2").gameObject
	self.textName2 = self.textCon2:ComponentByName("textName2", typeof(UILabel))
	self.textNameBg2 = self.textCon2:ComponentByName("textNameBg2", typeof(UISprite))
	self.textNameLine2 = self.textCon2:ComponentByName("textNameLine2", typeof(UISprite))
	self.textNameNum2 = self.textCon2:ComponentByName("textNameNum2", typeof(UILabel))
end

function GalaxyTripEnterWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.enterBtn.gameObject).onClick = handler(self, function ()
		local curIngBallId = xyd.models.galaxyTrip:getGalaxyTripGetCurMap()

		if curIngBallId == self.ballId or curIngBallId == 0 then
			xyd.models.galaxyTrip:openBallMapWindow(self.ballId)
			self:close()
		else
			local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(curIngBallId)
			local ballMap = ballMapInfo.map

			for i in pairs(ballMap) do
				local gridState = xyd.models.galaxyTrip:getGridState(ballMap[i].gridId, curIngBallId)

				if gridState == xyd.GalaxyTripGridStateType.CAN_GET then
					xyd.alertYesNo(__("GALAXY_TRIP_TIPS_11"), function (yes_no)
						if yes_no then
							xyd.models.galaxyTrip:openBallMapWindow(curIngBallId)
							self:close()

							return
						end
					end)

					return
				end

				if gridState == xyd.GalaxyTripGridStateType.SEARCH_ING then
					xyd.alertTips(__("GALAXY_TRIP_TIPS_13"))

					return
				end
			end

			xyd.alertYesNo(__("GALAXY_TRIP_TIPS_12"), function (yes_no)
				if yes_no then
					xyd.models.galaxyTrip:openBallMapWindow(self.ballId)
					self:close()
				end
			end)
		end
	end)
end

function GalaxyTripEnterWindow:layout()
	self.enterBtnLabel.text = __("GALAXY_TRIP_TEXT11")
	self.centerConName.text = __("GALAXY_TRIP_TEXT53")
	self.textName1.text = __("GALAXY_TRIP_TEXT54")
	self.textName2.text = __("GALAXY_TRIP_TEXT55")

	self:initUp()
end

function GalaxyTripEnterWindow:initUp()
	local galaxyNameId = xyd.tables.galaxyTripMapTable:getNameTextId(self.ballId)
	self.labelTitle.text = xyd.tables.galaxyTripMapTextTable:getDesc(galaxyNameId)
	local galaxyIntroId = xyd.tables.galaxyTripMapTable:getIntroTextId(self.ballId)
	self.descStaticLabel.text = xyd.tables.galaxyTripMapTextTable:getDesc(galaxyIntroId)
	self.bookStaticLabel.text = __("GALAXY_TRIP_TEXT52")
	local allTextHeight = self.descStaticLabel.height + self.bookStaticLabel.height

	if allTextHeight <= self.descPanelUIPanel:GetViewSize().y - self.descPanelUIScrollView.padding.y then
		self.panelCon:SetActive(false)
		self.descStaticCon:SetActive(true)
		self.descStaticCon:Y(130 + allTextHeight / 2)
	else
		self.descLabel.text = xyd.tables.galaxyTripMapTextTable:getDesc(galaxyIntroId)
		self.bookLabel.text = __("GALAXY_TRIP_TEXT52")

		self.panelCon:SetActive(true)
		self.descStaticCon:SetActive(false)
		self:waitForFrame(2, function ()
			self.descPanelUIScrollView:ResetPosition()
		end)
	end

	local imgIcon = xyd.tables.galaxyTripMapTable:getIconBigText(self.ballId)

	xyd.setUISpriteAsync(self.upGalaxyIcon, nil, imgIcon, nil, , true)
end

function GalaxyTripEnterWindow:updateStateLabel()
	if self.ballId == xyd.models.galaxyTrip:getGalaxyTripGetCurMap() then
		self.stateLabel.color = Color.New2(45677311)
		self.stateLabel.text = __("GALAXY_TRIP_TEXT05")
		local value = xyd.models.galaxyTrip:getGalaxyProgress(self.ballId)
		local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.ballId)
		self.textNameNum1.text = value .. "%"
		self.textNameNum2.text = tostring(ballMapInfo.score)
	else
		self.stateLabel.text = " "
		self.textNameNum1.text = "0%"
		self.textNameNum2.text = tostring(0)
	end
end

return GalaxyTripEnterWindow
