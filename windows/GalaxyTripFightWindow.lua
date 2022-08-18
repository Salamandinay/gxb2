local GalaxyTripFightWindow = class("GalaxyTripFightWindow", import(".BaseWindow"))
local EnemyClass = class("EnemyClass", import("app.components.CopyComponent"))

function GalaxyTripFightWindow:ctor(name, params)
	GalaxyTripFightWindow.super.ctor(self, name, params)

	self.eventId = params.eventId
	self.ballId = params.ballId
	self.posId = params.posId
	self.isLock = params.isLock
end

function GalaxyTripFightWindow:initWindow()
	self:getUIComponent()
	GalaxyTripFightWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
	self:updateStateLabel()
end

function GalaxyTripFightWindow:getUIComponent()
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
	self.buffGroup = self.upCon:NodeByName("buffGroup").gameObject
	self.buff1 = self.buffGroup:NodeByName("buff1").gameObject
	self.buff2 = self.buffGroup:NodeByName("buff2").gameObject
	self.btnBuff1 = self.buffGroup:ComponentByName("btnBuff1", typeof(UISprite))
	self.btnBuff2 = self.buffGroup:ComponentByName("btnBuff2", typeof(UISprite))
	self.btnCon = self.groupAction:NodeByName("btnCon").gameObject
	self.challengeBtn = self.btnCon:NodeByName("challengeBtn").gameObject
	self.challengeBtnBoxCollider = self.btnCon:ComponentByName("challengeBtn", typeof(UnityEngine.BoxCollider))
	self.challengeBtnLabel = self.challengeBtn:ComponentByName("challengeBtnLabel", typeof(UILabel))
	self.ticketCon = self.groupAction:NodeByName("ticketCon").gameObject
	self.res_item = self.ticketCon:NodeByName("res_item").gameObject
	self.resBgImg = self.res_item:ComponentByName("bg_img", typeof(UISprite))
	self.res_icon = self.res_item:ComponentByName("res_icon", typeof(UISprite))
	self.res_num_label = self.res_item:ComponentByName("res_num_label", typeof(UILabel))
	self.plus_btn = self.res_item:NodeByName("plus_btn").gameObject
	self.selectCon = self.groupAction:NodeByName("selectCon").gameObject
	self.selectLabel = self.selectCon:ComponentByName("selectLabel", typeof(UILabel))
	self.selectGroup = self.selectCon:NodeByName("selectGroup").gameObject
	self.centerCon = self.groupAction:NodeByName("centerCon").gameObject
	self.centerNameCon1 = self.centerCon:NodeByName("centerNameCon1").gameObject
	self.centerConName1 = self.centerNameCon1:ComponentByName("centerConName1", typeof(UILabel))
	self.centerConLayout1 = self.centerNameCon1:NodeByName("centerConLayout1").gameObject
	self.centerConLayout1UILayout = self.centerNameCon1:ComponentByName("centerConLayout1", typeof(UILayout))
	self.centerConEnemyItem = self.centerNameCon1:NodeByName("centerConEnemyItem").gameObject
	self.centerNameCon2 = self.centerCon:NodeByName("centerNameCon2").gameObject
	self.centerConName2 = self.centerNameCon2:ComponentByName("centerConName2", typeof(UILabel))
	self.centerConLayout2 = self.centerNameCon2:NodeByName("centerConLayout2").gameObject
	self.centerConLayout2UILayout = self.centerNameCon2:ComponentByName("centerConLayout2", typeof(UILayout))
end

function GalaxyTripFightWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.challengeBtn.gameObject).onClick = handler(self, function ()
		local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.ballId)
		local ballMap = ballMapInfo.map
		local gridId = ballMap[self.posId].gridId
		self.gridState = xyd.models.galaxyTrip:getGridState(gridId, self.ballId)

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

			xyd.WindowManager.get():openWindow("battle_formation_window", {
				showSkip = true,
				battleType = xyd.BattleType.GALAXY_TRIP_BATTLE,
				gridId = ballMap[self.posId].gridId,
				skipState = xyd.checkCondition(tonumber(xyd.db.misc:getValue("galaxy_trip_fight_skip_report")) == 1, true, false),
				btnSkipCallback = function (flag)
					local valuedata = xyd.checkCondition(flag, 1, 0)

					xyd.db.misc:setValue({
						key = "galaxy_trip_fight_skip_report",
						value = valuedata
					})
				end
			})
		end

		if self.gridState == xyd.GalaxyTripGridStateType.CAN_GET then
			local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.ballId)
			local ballMap = ballMapInfo.map
			local msg = messages_pb:galaxy_trip_get_map_awards_req()

			table.insert(msg.ids, ballMap[self.posId].gridId)
			xyd.Backend.get():request(xyd.mid.GALAXY_TRIP_GET_MAP_AWARDS, msg)
		end
	end)
	UIEventListener.Get(self.res_item.gameObject).onClick = handler(self, function ()
		local params = {
			itemID = xyd.ItemID.GALAXY_TRIP_TICKET
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end)

	for i = 1, 2 do
		UIEventListener.Get(self["btnBuff" .. i].gameObject).onClick = handler(self, function ()
			if self.selectBuffIndex and self.selectBuffIndex ~= i then
				self["buff" .. self.selectBuffIndex]:SetActive(false)
			elseif self.selectBuffIndex and self.selectBuffIndex == i then
				self["buff" .. self.selectBuffIndex]:SetActive(false)

				self.selectBuffIndex = nil

				return
			end

			self.selectBuffIndex = i

			self["buff" .. self.selectBuffIndex]:SetActive(true)
		end)
	end
end

function GalaxyTripFightWindow:layout()
	self.challengeBtnLabel.text = __("GALAXY_TRIP_TEXT34")
	self.centerConName1.text = __("GALAXY_TRIP_TEXT32")
	self.centerConName2.text = __("GALAXY_TRIP_TEXT30")
	local ticketArr = xyd.tables.miscTable:split2num("galaxy_trip_challenge", "value", "|")
	self.res_num_label.text = tostring(xyd.models.galaxyTrip:getGalaxyTripGetMainTicket()) .. "/" .. ticketArr[3]
	local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.ballId)
	local ballMap = ballMapInfo.map
	local gridId = ballMap[self.posId].gridId
	local gridState = xyd.models.galaxyTrip:getGridState(gridId, self.ballId)

	if gridState == xyd.GalaxyTripGridStateType.CAN_GET then
		self.challengeBtnLabel.text = __("GET2")
	end

	self.gridState = xyd.models.galaxyTrip:getGridState(gridId, self.ballId)

	xyd.applyChildrenOrigin(self.challengeBtn)

	self.challengeBtnBoxCollider.enabled = true

	if self.gridState == xyd.GalaxyTripGridStateType.NO_OPEN then
		if self.isLock then
			xyd.applyChildrenGrey(self.challengeBtn)

			self.challengeBtnBoxCollider.enabled = false
		end
	elseif self.isLock then
		xyd.applyChildrenGrey(self.challengeBtn)

		self.challengeBtnBoxCollider.enabled = false
	end

	if xyd.models.galaxyTrip:getGalaxyTripGetMainTicket() <= 0 then
		xyd.applyChildrenGrey(self.challengeBtn)

		self.challengeBtnBoxCollider.enabled = false
	end

	xyd.setUISpriteAsync(self.res_icon, nil, xyd.tables.itemTable:getIcon(xyd.ItemID.GALAXY_TRIP_TICKET), function ()
		self.res_icon:SetLocalScale(0.5, 0.5, 1)
	end, true)
	self:initUp()
end

function GalaxyTripFightWindow:initUp()
	local eventTypeId = xyd.tables.galaxyTripEventTable:getType(self.eventId)
	local galaxyNameId = xyd.tables.galaxyTripEventTypeTable:getNameTextId(eventTypeId)
	self.labelTitle.text = xyd.tables.galaxyTripEventTypeTextTable:getDesc(galaxyNameId)
	local galaxyIntroId = xyd.tables.galaxyTripEventTypeTable:getIntroTextId(eventTypeId)
	self.descStaticLabel.text = xyd.tables.galaxyTripEventTypeTextTable:getDesc(galaxyIntroId)

	if xyd.Global.lang == "de_de" then
		self.descStaticLabel.spacingY = 6
	end

	self.bookStaticLabel.text = __("GALAXY_TRIP_TEXT52")
	local allTextHeight = self.descStaticLabel.height + self.bookStaticLabel.height

	if allTextHeight <= self.descPanelUIPanel:GetViewSize().y - self.descPanelUIScrollView.padding.y then
		self.panelCon:SetActive(false)
		self.descStaticCon:SetActive(true)
		self.descStaticCon:Y(130 + allTextHeight / 2)
	else
		self.descLabel.text = xyd.tables.galaxyTripEventTypeTextTable:getDesc(galaxyIntroId)

		if xyd.Global.lang == "de_de" then
			self.descLabel.spacingY = 6
		end

		self.bookLabel.text = __("GALAXY_TRIP_TEXT52")

		self.panelCon:SetActive(true)
		self.descStaticCon:SetActive(false)
		self:waitForFrame(2, function ()
			self.descPanelUIScrollView:ResetPosition()
		end)
	end

	local imgIcon = xyd.tables.galaxyTripEventTypeTable:getIconBigText(eventTypeId)

	xyd.setUISpriteAsync(self.upGalaxyIcon, nil, imgIcon, nil, , true)

	local eventType = xyd.tables.galaxyTripEventTable:getType(self.eventId)

	if eventType == xyd.GalaxyTripGridEventType.COMMON_BOSS then
		local arr = xyd.tables.miscTable:split2num("galaxy_trip_enemy_weaken", "value", "|")
		local allNum = xyd.models.galaxyTrip:getGalaxyGridAllNum(self.ballId)
		local allGetNum = xyd.models.galaxyTrip:getGalaxyGridAllGetNum(self.ballId)
		local progressValue = xyd.models.galaxyTrip:getCurBallProress(self.ballId)

		if arr[1] < progressValue then
			local buffValue = math.min((allGetNum - math.floor(arr[1] * allNum)) * arr[2], arr[3]) * 100 .. "%"

			dump(buffValue)
			self.buffGroup:SetActive(true)

			for i = 1, 2 do
				local buffImg = self["buff" .. i]:ComponentByName("topBg/buffImg", typeof(UISprite))
				local buffNameText = self["buff" .. i]:ComponentByName("topBg/buffNameText", typeof(UILabel))
				local desText = self["buff" .. i]:ComponentByName("desText", typeof(UILabel))

				xyd.setUISpriteAsync(self["btnBuff" .. i], nil, xyd.tables.galaxyTripBuffShowTable:getIcon(i))
				xyd.setUISpriteAsync(buffImg, nil, xyd.tables.galaxyTripBuffShowTable:getIcon(i))

				local text = ""
				text = xyd.tables.galaxyTripBuffShowTextTable:getDesc(xyd.tables.galaxyTripBuffShowTable:getText1(i))
				buffNameText.text = text
				text = xyd.tables.galaxyTripBuffShowTextTable:getDesc(xyd.tables.galaxyTripBuffShowTable:getText2(i))

				dump(text)

				desText.text = xyd.stringFormat(text, buffValue)
			end
		end
	end
end

function GalaxyTripFightWindow:updateStateLabel()
	local eventType = xyd.tables.galaxyTripEventTable:getType(self.eventId)

	if eventType == xyd.GalaxyTripGridEventType.BLACK_HOLE_BOSS then
		self.selectCon:SetActive(true)
		self.ticketCon:SetActive(false)

		if not self.selectItem then
			local lastChoiceNum = xyd.db.misc:getValue("galaxy_trip_fight_last_choice_num")
			lastChoiceNum = not lastChoiceNum and 1 or tonumber(lastChoiceNum)
			self.selectNum = lastChoiceNum
			self.pointerSelectNum = import("app.components.SelectNum").new(self.selectGroup, "default")

			self.pointerSelectNum:setInfo({
				minNum = 1,
				maxNum = 20,
				curNum = lastChoiceNum,
				callback = function (num)
					self.selectNum = num
				end
			})
		end
	else
		self.selectCon:SetActive(false)
		self.ticketCon:SetActive(true)

		local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.ballId)
		local ballMap = ballMapInfo.map
		local eventArr = xyd.split(ballMap[self.posId].info, "#", true)
		local battleId = eventArr[2]
		local enemies = xyd.tables.battleTable:getMonsters(battleId)

		if #enemies > 0 then
			for i in pairs(enemies) do
				local tmp = NGUITools.AddChild(self.centerConLayout1.gameObject, self.centerConEnemyItem.gameObject)
				local item = EnemyClass.new(tmp, enemies[i], self, i)
			end
		end

		self.centerConLayout1UILayout:Reposition()

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
end

function EnemyClass:ctor(goItem, enemyId, parent, index)
	self.goItem_ = goItem
	self.parent = parent
	self.enemyId = enemyId
	self.index = index

	EnemyClass.super.ctor(self, goItem)
end

function EnemyClass:initUI()
	self:getUIComponent()
	EnemyClass.super.initUI(self)
	self:initShow()
end

function EnemyClass:getUIComponent()
	self.heroCon = self.go:NodeByName("heroCon").gameObject
	self.hpCon = self.go:NodeByName("hpCon").gameObject
	self.hpBar = self.hpCon:ComponentByName("hpBar", typeof(UISprite))
	self.hpBarUISlider = self.hpCon:ComponentByName("hpBar", typeof(UISlider))
end

function EnemyClass:initShow()
	local id = xyd.tables.monsterTable:getPartnerLink(self.enemyId)
	local lev = xyd.tables.monsterTable:getShowLev(self.enemyId)
	local item = {
		scale = 0.7037037037037037,
		noClick = true,
		uiRoot = self.heroCon.gameObject,
		itemID = id,
		lev = lev
	}
	local icon = xyd.getItemIcon(item, xyd.ItemIconType.ADVANCE_ICON)
	self.hpBarUISlider.value = 1
	local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self.parent.ballId)
	local ballMap = ballMapInfo.map
	local gridId = ballMap[self.parent.posId].gridId
	local enemies = xyd.models.galaxyTrip:getGalaxyTripEnemiesHpInfo(gridId)
	local eventType = xyd.tables.galaxyTripEventTable:getType(self.eventId)
	local gridState = xyd.models.galaxyTrip:getGridState(gridId, self.parent.ballId)

	if gridState == xyd.GalaxyTripGridStateType.CAN_GET then
		self.hpBarUISlider.value = 0

		return
	end

	if enemies then
		local status = enemies.status

		for i in pairs(status) do
			if tonumber(status[i].pos) == self.index then
				self.hpBarUISlider.value = tonumber(status[i].hp) / 100
			end
		end
	else
		self.hpBarUISlider.value = 1
	end
end

return GalaxyTripFightWindow
