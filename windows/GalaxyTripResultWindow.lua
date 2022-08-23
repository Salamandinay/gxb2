local GalaxyTripResultWindow = class("GalaxyTripResultWindow", import(".BaseWindow"))
local AwardSelectItem = class("AwardSelectItem", import("app.common.ui.FixedMultiWrapContentItem"))

function GalaxyTripResultWindow:ctor(name, params)
	GalaxyTripResultWindow.super.ctor(self, name, params)

	self.ballId = params.ballId
	self.selectIndex = 0
	self.resultType = params.resultType
end

function GalaxyTripResultWindow:initWindow()
	self:getUIComponent()
	GalaxyTripResultWindow.super.initWindow(self)

	if self.resultType == xyd.GalaxyTripResultType.MIDDLE then
		self.bg.height = 510

		self.centerCon.gameObject:SetActive(false)
	end

	self:registerEvent()
	self:layout()
end

function GalaxyTripResultWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.titleGroup = self.groupAction:NodeByName("titleGroup").gameObject
	self.labelTitle = self.titleGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.titleGroup:NodeByName("closeBtn").gameObject

	self.closeBtn:SetActive(false)

	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.upGalaxyIcon = self.upCon:ComponentByName("upGalaxyIcon", typeof(UISprite))
	self.scrollerPosPanel = self.upCon:NodeByName("scrollerPosPanel").gameObject
	self.scrollerPosPanelUIScrollView = self.upCon:ComponentByName("scrollerPosPanel", typeof(UIScrollView))
	self.scrollerPosCon = self.upCon:NodeByName("scrollerPosCon").gameObject
	self.scrollerPosConUIWidget = self.upCon:ComponentByName("scrollerPosCon", typeof(UIWidget))
	self.posLine = self.scrollerPosCon:ComponentByName("posLine", typeof(UISprite))
	self.scrollerPosItem = self.upCon:NodeByName("scrollerPosItem").gameObject
	self.descCon = self.upCon:NodeByName("descCon").gameObject
	self.label1 = self.descCon:ComponentByName("label1", typeof(UILabel))
	self.label2 = self.descCon:ComponentByName("label2", typeof(UILabel))
	self.label3 = self.descCon:ComponentByName("label3", typeof(UILabel))
	self.posDrag = self.upCon:NodeByName("posDrag").gameObject
	self.centerCon = self.groupAction:NodeByName("centerCon").gameObject
	self.centerConBg = self.centerCon:ComponentByName("centerConBg", typeof(UISprite))
	self.scrollerItemItem = self.centerCon:NodeByName("scrollerItemItem").gameObject
	self.scrollerItemPanel = self.centerCon:NodeByName("scrollerItemPanel").gameObject
	self.scrollerItemPanelUIPanel = self.centerCon:ComponentByName("scrollerItemPanel", typeof(UIPanel))
	self.scrollerItemPanelUIScrollView = self.centerCon:ComponentByName("scrollerItemPanel", typeof(UIScrollView))
	self.scrollerItemCon = self.scrollerItemPanel:NodeByName("scrollerItemCon").gameObject
	self.scrollerItemConMultiRowWrapContent = self.scrollerItemPanel:ComponentByName("scrollerItemCon", typeof(MultiRowWrapContent))
	self.noneCon = self.centerCon:NodeByName("noneCon").gameObject
	self.labelNoneTips = self.noneCon:ComponentByName("labelNoneTips", typeof(UILabel))
	self.itemDrag = self.centerCon:NodeByName("itemDrag").gameObject
	self.wrapContent = import("app.common.ui.FixedMultiWrapContent").new(self.scrollerItemPanelUIScrollView, self.scrollerItemConMultiRowWrapContent, self.scrollerItemItem, AwardSelectItem, self)
	self.btnCon = self.groupAction:NodeByName("btnCon").gameObject
	self.challengeBtn = self.btnCon:NodeByName("challengeBtn").gameObject
	self.challengeBtnLabel = self.challengeBtn:ComponentByName("challengeBtnLabel", typeof(UILabel))
end

function GalaxyTripResultWindow:registerEvent()
	UIEventListener.Get(self.challengeBtn.gameObject).onClick = handler(self, function ()
		if self.resultType == xyd.GalaxyTripResultType.MIDDLE then
			self:close()

			return
		end

		local ids = xyd.models.galaxyTrip:getGalaxyTripGetMainIds()
		local isCanGet = false

		for i in pairs(ids) do
			if self.defaultStates[i] == xyd.GalaxyTripGridStateType.CAN_GET then
				isCanGet = true

				break
			end
		end

		if not isCanGet then
			self:close()

			return
		end

		local msg = messages_pb:galaxy_trip_get_map_awards_req()

		for i in pairs(ids) do
			if self.defaultStates[i] == xyd.GalaxyTripGridStateType.CAN_GET then
				table.insert(msg.ids, ids[i])
			end
		end

		xyd.Backend.get():request(xyd.mid.GALAXY_TRIP_GET_MAP_AWARDS, msg)
	end)
end

function GalaxyTripResultWindow:layout()
	self.labelTitle.text = __("GALAXY_TRIP_TEXT53")

	if self.resultType == xyd.GalaxyTripResultType.MIDDLE then
		self.labelTitle.text = __("GALAXY_TRIP_TEXT53")
	end

	self.defaultStates = {}
	local ids = xyd.models.galaxyTrip:getGalaxyTripGetMainIds()

	dump(ids, "test-1-1-1-")

	for i in pairs(ids) do
		local gridState = xyd.models.galaxyTrip:getGridState(ids[i], self.ballId)
		self.defaultStates[i] = gridState
	end

	dump(self.defaultStates, "test000")

	self.labelNoneTips.text = __("GALAXY_TRIP_TEXT67")

	if self.resultType == xyd.GalaxyTripResultType.MIDDLE then
		self.challengeBtnLabel.text = __("SURE")
	elseif self.resultType == xyd.GalaxyTripResultType.OVER then
		self.challengeBtnLabel.text = __("SURE")

		for i in pairs(ids) do
			if self.defaultStates[i] == xyd.GalaxyTripGridStateType.CAN_GET then
				self.challengeBtnLabel.text = __("GET2")

				break
			end
		end
	end

	local ids = xyd.models.galaxyTrip:getGalaxyTripGetMainIds()
	self.timeArr = {
		[0] = 0
	}
	self.itemsArr = {
		[0] = {}
	}
	self.awards = {
		[0] = {}
	}

	for i in pairs(ids) do
		self.itemsArr[i] = {}
		local gridId = ids[i]
		local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.ballId)
		local ballMap = ballMapInfo.map
		local posId = xyd.models.galaxyTrip:getPosIdFromGridId(self.ballId, gridId)
		local eventArr = xyd.split(ballMap[posId].info, "#", true)
		local eventId = eventArr[1]
		local eventType = xyd.tables.galaxyTripEventTable:getType(eventId)
		local time = xyd.tables.galaxyTripEventTypeTable:getTime(eventType)
		self.timeArr[0] = self.timeArr[0] + time
		self.timeArr[i] = time

		if self.defaultStates[i] == xyd.GalaxyTripGridStateType.CAN_GET then
			local award1 = xyd.tables.galaxyTripEventTable:getAward1(eventId)

			if award1 and #award1 > 0 then
				for k in pairs(award1) do
					award1[k][2] = xyd.models.galaxyTrip:getAwardNumWithBuff(award1[k][2], 1)

					if self.itemsArr[0][tostring(award1[k][1])] then
						self.itemsArr[0][tostring(award1[k][1])] = self.itemsArr[0][tostring(award1[k][1])] + award1[k][2]
					else
						self.itemsArr[0][tostring(award1[k][1])] = award1[k][2]
					end

					if self.itemsArr[i][tostring(award1[k][1])] then
						self.itemsArr[i][tostring(award1[k][1])] = self.itemsArr[i][tostring(award1[k][1])] + award1[k][2]
					else
						self.itemsArr[i][tostring(award1[k][1])] = award1[k][2]
					end
				end
			end

			local award2 = xyd.tables.galaxyTripEventTable:getAward2(eventId)

			if award2 and #award2 > 0 then
				for k in pairs(award2) do
					award2[k][2] = xyd.models.galaxyTrip:getAwardNumWithBuff(award2[k][2], 2)

					if self.itemsArr[0][tostring(award2[k][1])] then
						self.itemsArr[0][tostring(award2[k][1])] = self.itemsArr[0][tostring(award2[k][1])] + award2[k][2]
					else
						self.itemsArr[0][tostring(award2[k][1])] = award2[k][2]
					end

					if self.itemsArr[i][tostring(award2[k][1])] then
						self.itemsArr[i][tostring(award2[k][1])] = self.itemsArr[i][tostring(award2[k][1])] + award2[k][2]
					else
						self.itemsArr[i][tostring(award2[k][1])] = award2[k][2]
					end
				end
			end

			local award3 = xyd.tables.galaxyTripEventTable:getAward3(eventId)

			if award3 and #award3 > 0 then
				for k in pairs(award3) do
					if self.itemsArr[0][tostring(award3[k][1])] then
						self.itemsArr[0][tostring(award3[k][1])] = self.itemsArr[0][tostring(award3[k][1])] + award3[k][2]
					else
						self.itemsArr[0][tostring(award3[k][1])] = award3[k][2]
					end

					if self.itemsArr[i][tostring(award3[k][1])] then
						self.itemsArr[i][tostring(award3[k][1])] = self.itemsArr[i][tostring(award3[k][1])] + award3[k][2]
					else
						self.itemsArr[i][tostring(award3[k][1])] = award3[k][2]
					end
				end
			end
		end
	end

	for i = 0, #self.itemsArr do
		local infoArr = self.itemsArr[i]

		for key, value in pairs(infoArr) do
			if not self.awards[i] then
				self.awards[i] = {}
			end

			table.insert(self.awards[i], {
				award = {
					tonumber(key),
					value
				}
			})
		end
	end

	dump(self.itemsArr, "test1")
	dump(self.awards, "test2")
	self:initUpItem()
	self:updateShow(self.selectIndex)
end

function GalaxyTripResultWindow:initUpItem()
	local ids = xyd.models.galaxyTrip:getGalaxyTripGetMainIds()
	local firstX = 38

	for i in pairs(ids) do
		self.itemsArr[i] = {}
		local gridId = ids[i]
		local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.ballId)
		local ballMap = ballMapInfo.map
		local posId = xyd.models.galaxyTrip:getPosIdFromGridId(self.ballId, gridId)
		local eventArr = xyd.split(ballMap[posId].info, "#", true)
		local eventId = eventArr[1]
		local eventType = xyd.tables.galaxyTripEventTable:getType(eventId)
		self["item" .. i] = NGUITools.AddChild(self.scrollerPosCon.gameObject, self.scrollerPosItem.gameObject)
		self["itemIcon" .. i] = self["item" .. i]:ComponentByName("icon", typeof(UISprite))
		self["itemLabel" .. i] = self["item" .. i]:ComponentByName("label", typeof(UILabel))
		self["itemLabel" .. i].text = tostring(i)

		self:updateItemIconShow(i, false)
		self["item" .. i].gameObject:X(38 + (i - 1) * 128)

		UIEventListener.Get(self["item" .. i].gameObject).onClick = handler(self, function ()
			if self.selectIndex == i then
				self.selectIndex = 0
			else
				self.selectIndex = i
			end

			for k in pairs(ids) do
				if k == self.selectIndex then
					self:updateItemIconShow(k, true)
				else
					self:updateItemIconShow(k, false)
				end
			end

			self:updateShow(self.selectIndex)
		end)
	end

	self.posLine.gameObject:X(firstX)

	self.posLine.width = (#ids - 1) * 128
	self.scrollerPosConUIWidget.width = self.posLine.width + 76

	if #ids >= 6 then
		self.scrollerPosPanel.gameObject:SetActive(true)
		self.posDrag.gameObject:SetActive(true)
		self.scrollerPosCon.transform:SetParent(self.scrollerPosPanel.gameObject.transform)
	else
		self.scrollerPosPanel.gameObject:SetActive(false)
		self.posDrag.gameObject:SetActive(false)
		self.scrollerPosCon:X(-self.scrollerPosConUIWidget.width / 2)
	end

	self.scrollerPosPanelUIScrollView:ResetPosition()
end

function GalaxyTripResultWindow:updateShow(index)
	local ids = xyd.models.galaxyTrip:getGalaxyTripGetMainIds()

	if index == 0 then
		local imgIcon = xyd.tables.galaxyTripMapTable:getIconBigText(self.ballId)

		xyd.setUISpriteAsync(self.upGalaxyIcon, nil, imgIcon, nil, , true)

		local galaxyNameId = xyd.tables.galaxyTripMapTable:getNameTextId(self.ballId)
		self.label1.text = __("GALAXY_TRIP_TEXT13", xyd.tables.galaxyTripMapTextTable:getDesc(galaxyNameId))
		local getYetNum = 0

		for i in pairs(ids) do
			if self.defaultStates[i] == xyd.GalaxyTripGridStateType.CAN_GET then
				getYetNum = getYetNum + 1
			end
		end

		self.label2.text = __("GALAXY_TRIP_TEXT14", getYetNum)
		self.label3.text = " "
	else
		local gridId = ids[index]
		local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.ballId)
		local ballMap = ballMapInfo.map
		local posId = xyd.models.galaxyTrip:getPosIdFromGridId(self.ballId, gridId)
		local eventArr = xyd.split(ballMap[posId].info, "#", true)
		local eventId = eventArr[1]
		local eventType = xyd.tables.galaxyTripEventTable:getType(eventId)
		local imgIcon = xyd.tables.galaxyTripEventTypeTable:getIconBigText(eventType)

		xyd.setUISpriteAsync(self.upGalaxyIcon, nil, imgIcon, nil, , true)

		self.label1.text = __("GALAXY_TRIP_TEXT16", index)

		if self.defaultStates[index] == xyd.GalaxyTripGridStateType.CAN_GET then
			self.label2.text = __("GALAXY_TRIP_TEXT17", xyd.secondsToString(math.floor(self.timeArr[index] * (1 - xyd.models.galaxyTrip:getBuffExploreTimeCut())), xyd.SecondsStrType.NORMAL))
		else
			self.label2.text = " "
		end

		if self.defaultStates[index] == xyd.GalaxyTripGridStateType.CAN_GET then
			self.label3.text = __("GALAXY_TRIP_TEXT18", __("GALAXY_TRIP_TEXT19"))
		elseif self.defaultStates[index] == xyd.GalaxyTripGridStateType.SEARCH_ING then
			self.label3.text = __("GALAXY_TRIP_TEXT18", __("GALAXY_TRIP_TEXT29"))
		elseif self.defaultStates[index] == xyd.GalaxyTripGridStateType.NOT_YET_SEARCH then
			self.label3.text = __("GALAXY_TRIP_TEXT18", __("GALAXY_TRIP_TEXT59"))
		elseif self.defaultStates[index] == xyd.GalaxyTripGridStateType.FAIL or self.defaultStates[index] == xyd.GalaxyTripGridStateType.NO_OPEN then
			self.label3.text = __("GALAXY_TRIP_TEXT18", __("GALAXY_TRIP_TEXT66"))
		end

		if self.label2.text == " " then
			self.label3:Y(1.2)
		else
			self.label3:Y(-26)
		end
	end

	local maxLabelWidth = 0

	for i = 1, 3 do
		if maxLabelWidth < self["label" .. i].width then
			maxLabelWidth = self["label" .. i].width
		end
	end

	self.descCon.gameObject:X(-maxLabelWidth / 2)

	if self.awards[index] and #self.awards[index] > 0 then
		self.wrapContent:setInfos(self.awards[index], {})

		self.scrollerItemPanelUIPanel.alpha = 1
	else
		self.scrollerItemPanelUIPanel.alpha = 0.01
	end

	if self.awards[index] and #self.awards[index] > 0 then
		self.noneCon.gameObject:SetActive(false)
	else
		self.noneCon.gameObject:SetActive(true)
	end
end

function GalaxyTripResultWindow:updateItemIconShow(i, isChoice)
	local iconStr = ""

	if self.defaultStates[i] == xyd.GalaxyTripGridStateType.CAN_GET then
		if isChoice then
			iconStr = "galaxy_trip_ts_dui1"
		else
			iconStr = "galaxy_trip_ts_dui2"
		end
	elseif self.defaultStates[i] == xyd.GalaxyTripGridStateType.SEARCH_ING then
		if isChoice then
			iconStr = "galaxy_trip_ts_ing1"
		else
			iconStr = "galaxy_trip_ts_ing2"
		end
	elseif self.defaultStates[i] == xyd.GalaxyTripGridStateType.FAIL or self.defaultStates[i] == xyd.GalaxyTripGridStateType.NO_OPEN then
		if isChoice then
			iconStr = "galaxy_trip_ts_cuo1"
		else
			iconStr = "galaxy_trip_ts_cuo2"
		end
	elseif self.defaultStates[i] == xyd.GalaxyTripGridStateType.NOT_YET_SEARCH then
		if isChoice then
			iconStr = "galaxy_trip_ts_ing1"
		else
			iconStr = "galaxy_trip_ts_ing2"
		end
	end

	xyd.setUISpriteAsync(self["itemIcon" .. i], nil, iconStr, nil, , true)
end

function AwardSelectItem:ctor(go, parent)
	AwardSelectItem.super.ctor(self, go, parent)

	self.itemCon = self.go:NodeByName("itemCon").gameObject
end

function AwardSelectItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.data = info
	local award = info.award
	local params = {
		isAddUIDragScrollView = true,
		scale = 0.7962962962962963,
		isShowSelected = false,
		uiRoot = self.itemCon.gameObject,
		itemID = tonumber(award[1]),
		num = award[2]
	}

	if not self.icon then
		self.icon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	else
		self.icon:SetActive(true)
		self.icon:setInfo(params)
	end
end

return GalaxyTripResultWindow
