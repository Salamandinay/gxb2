local ActivitySecretTreasureHunt = class("ActivitySecretTreasureHunt", import(".ActivityContent"))
local json = require("cjson")

function ActivitySecretTreasureHunt:ctor(parentGO, params)
	ActivitySecretTreasureHunt.super.ctor(self, parentGO, params)
end

function ActivitySecretTreasureHunt:getPrefabPath()
	return "Prefabs/Windows/activity/activity_secret_treasure_hunt"
end

function ActivitySecretTreasureHunt:resizeToParent()
	ActivitySecretTreasureHunt.super.resizeToParent(self)
end

function ActivitySecretTreasureHunt:initUI()
	self.SpecialEventType = {
		Nothing = 6,
		DoubleChange = 2,
		Adventrue = 5,
		Nothing2 = 7,
		MeetBattle = 4,
		DoubleAward = 1,
		GetTreasure = 3
	}
	self.resID = xyd.tables.miscTable:split2Cost("find_treasure_item", "value", "|#")[1][1]
	self.resCost = xyd.tables.miscTable:split2Cost("find_treasure_item", "value", "|#")[1][2]
	self.skipDice = false
	self.AutoExplore = false
	self.SkipAnimation = false
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SECRET_TREASURE_HUNT)
	self.RadarRate = self.activityData.detail.rate

	if self.activityData.detail.rps > 0 then
		self.isInDice = true
	else
		self.isInDice = false
	end

	self:getUIComponent()
	ActivitySecretTreasureHunt.super.initUI(self)
	self:initUIComponent()
	self:register()
	self:ifInDice()
end

function ActivitySecretTreasureHunt:getUIComponent()
	local go = self.go
	self.ExploreGroup = self.go:NodeByName("ExploreGroup").gameObject
	self.exploreResGroup = self.ExploreGroup:ComponentByName("exploreResGroup", typeof(UISprite))
	self.icon = self.exploreResGroup:ComponentByName("icon", typeof(UISprite))
	self.num = self.exploreResGroup:ComponentByName("num", typeof(UILabel))
	self.plus = self.exploreResGroup:ComponentByName("plus", typeof(UISprite))
	self.btnExplore = self.ExploreGroup:NodeByName("btnExplore").gameObject
	self.labelBtnExplore = self.btnExplore:ComponentByName("label", typeof(UILabel))
	self.redPoint = self.btnExplore:ComponentByName("redPoint", typeof(UISprite))
	self.btnHelp = self.go:NodeByName("btnHelp").gameObject
	self.btnDetail = self.go:NodeByName("btnDetail").gameObject
	self.specialEventGroup = self.go:NodeByName("specialEventGroup").gameObject
	self.mask = self.specialEventGroup:ComponentByName("mask", typeof(UISprite))
	self.diceGroup = self.specialEventGroup:NodeByName("diceGroup").gameObject

	for i = 1, 3 do
		self["diceGroup" .. i] = self.diceGroup:NodeByName("group" .. i).gameObject
		self["btnDice" .. i] = self["diceGroup" .. i]:NodeByName("btnDice").gameObject
	end

	self.btnGiveupDice = self.diceGroup:NodeByName("btnGiveupDice").gameObject
	self.labelGiveupDice = self.btnGiveupDice:ComponentByName("label", typeof(UILabel))
	self.eventGroup = self.specialEventGroup:NodeByName("eventGroup").gameObject
	self.labelEventTitle = self.eventGroup:ComponentByName("labelEventTitle", typeof(UILabel))
	self.eventIcon = self.eventGroup:ComponentByName("eventIcon", typeof(UISprite))
	self.labelEventDesc = self.eventGroup:ComponentByName("labelEventDesc", typeof(UILabel))
	self.btnAward = self.go:NodeByName("btnAward").gameObject
	self.labelAward = self.btnAward:ComponentByName("labelAward", typeof(UILabel))
	self.radarGroup = self.go:NodeByName("radarGroup").gameObject
	self.radarIcon = self.radarGroup:ComponentByName("icon", typeof(UISprite))
	self.labelRaderTitle = self.radarGroup:ComponentByName("labelRaderTitle", typeof(UILabel))
	self.progressBar = self.radarGroup:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressImg = self.progressBar:ComponentByName("progressImg", typeof(UISprite))
	self.progressLabel = self.progressBar:ComponentByName("progressLabel", typeof(UILabel))
	self.treasureGroup = self.go:ComponentByName("treasureGroup", typeof(UISprite))
	self.labelTreasureTitle = self.treasureGroup:ComponentByName("labelTreasureTitle", typeof(UILabel))
	self.itemGroup_treasure = self.treasureGroup:ComponentByName("itemGroup", typeof(UILayout))

	for i = 1, 6 do
		self["treasure" .. i] = self.itemGroup_treasure:NodeByName("treasure" .. i).gameObject
	end

	self.curTreasure = self.itemGroup_treasure:NodeByName("curTreasure").gameObject
	self.labelTreasureTurn = self.treasureGroup:ComponentByName("labelTreasureTurn", typeof(UILabel))
	self.titleImg = self.go:ComponentByName("titleImg", typeof(UISprite))
	self.mapGroup = self.go:NodeByName("mapGroup").gameObject
	self.roleModelGroup = self.mapGroup:NodeByName("roleModelGroup").gameObject
	self.directionBtnGroup = self.mapGroup:NodeByName("directionBtnGroup").gameObject
	self.btnRight = self.directionBtnGroup:NodeByName("btnRight").gameObject
	self.btnRightTop = self.directionBtnGroup:NodeByName("btnRightTop").gameObject
	self.btnRightDown = self.directionBtnGroup:NodeByName("btnRightDown").gameObject
	self.labelDirectionHelp = self.directionBtnGroup:ComponentByName("labelDirectionHelp", typeof(UILabel))
	self.awardGoup = self.mapGroup:NodeByName("awardGoup").gameObject
	self.enemyDiceIcon = self.awardGoup:ComponentByName("diceIconGroup/enemyDiceIcon", typeof(UISprite))
	self.roleDiceIcon = self.awardGoup:ComponentByName("diceIconGroup/roleDiceIcon", typeof(UISprite))
	self.enemyPos = self.awardGoup:ComponentByName("enemyPos", typeof(UITexture))
	self.treasureAwardIcon = self.awardGoup:ComponentByName("awardIcon", typeof(UISprite))
	self.mapNode = self.mapGroup:NodeByName("mapNode").gameObject

	for i = 1, 6 do
		self["map" .. i] = self.mapNode:ComponentByName("map" .. i, typeof(UITexture))
	end

	self.buffGroup = self.mapGroup:NodeByName("buffGroup").gameObject
	self.buffIcon = self.buffGroup:ComponentByName("buffIcon", typeof(UISprite))
	self.labelBuff = self.buffGroup:ComponentByName("labelBuff", typeof(UILabel))
	self.labelBuffTurn = self.buffGroup:ComponentByName("labelBuffTurn", typeof(UILabel))
	self.btnAutoExplore = self.mapGroup:NodeByName("btnAutoExplore").gameObject
	self.btnSkipAnimation = self.mapGroup:NodeByName("btnSkipAnimation").gameObject
	self.labelSkipAnimation = self.btnSkipAnimation:ComponentByName("labelSkipAnimation", typeof(UILabel))
end

function ActivitySecretTreasureHunt:initUIComponent()
	self.labelBtnExplore.text = __("ACTIVITY_SECTRETTREASURE_TEXT01")
	self.labelSkipAnimation.text = __("ACTIVITY_SECTRETTREASURE_TEXT31")
	self.labelEventTitle.text = __("ACTIVITY_SECTRETTREASURE_TEXT05")
	self.labelAward.text = __("AWARD3")
	self.labelTreasureTitle.text = __("ACTIVITY_SECTRETTREASURE_TEXT04")
	self.labelBuff.text = __("ACTIVITY_SECTRETTREASURE_TEXT14")
	self.labelRaderTitle.text = __("ACTIVITY_SECTRETTREASURE_TEXT03")
	self.labelDirectionHelp.text = __("ACTIVITY_SECTRETTREASURE_TEXT29")

	for i = 1, 3 do
		self["btnDice" .. i]:ComponentByName("label", typeof(UILabel)).text = __("ACTIVITY_SECTRETTREASURE_TEXT35")
	end

	self.labelGiveupDice.text = __("ACTIVITY_SECTRETTREASURE_TEXT09")

	xyd.setUISpriteAsync(self.titleImg, nil, "activity_secret_treasure_hunt_logo_" .. xyd.Global.lang)

	for i = 1, 3 do
		local icon = self["diceGroup" .. i]:ComponentByName("diceIcon", typeof(UISprite))

		xyd.setUISpriteAsync(icon, nil, "activity_secret_treasure_hunt_dice_icon" .. i)
	end

	self:updateRadarGroup()
	self:updateExploreResGroup()
	self:updateTreasureGroup()
	self:initAnimationGoup()

	if self.activityData.detail.sp_count > 0 then
		self.buffGroup:SetActive(true)

		self.labelBuffTurn.text = __("ACTIVITY_SECTRETTREASURE_TEXT06", self.activityData.detail.sp_count)
	else
		self.buffGroup:SetActive(false)
	end
end

function ActivitySecretTreasureHunt:register()
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data
		local detail = json.decode(data.detail)

		if detail.is_win or self.nextIsDiceFlag == true then
			self:onGetDiceMsg(event)
		else
			self:onGetMsg(event)
		end
	end)

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_SECTRETTREASURE_TEXT28"
		})
	end

	UIEventListener.Get(self.btnExplore).onClick = function ()
		self:clickBtnExplore()
	end

	UIEventListener.Get(self.btnAutoExplore).onClick = function ()
		local autoValue = xyd.tables.miscTable:getNumber("find_treasure_autostep", "value") or 1

		if autoValue <= self.activityData.detail.total_count then
			if not self.AutoExplore or self.AutoExplore == false then
				if xyd.models.backpack:getItemNumByID(self.resID) <= 0 then
					xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.resID)))

					return
				end

				self.AutoExplore = true
				self.skipDice = true

				xyd.setUISpriteAsync(self.btnAutoExplore:ComponentByName("", typeof(UISprite)), nil, "battle_img_skip")
				self:beginAutoExplore()
			elseif self.AutoExplore == true then
				self.AutoExplore = false
				self.skipDice = false

				xyd.setUISpriteAsync(self.btnAutoExplore:ComponentByName("", typeof(UISprite)), nil, "btn_max")
			end
		else
			xyd.alertTips(__("ACTIVITY_SECTRETTREASURE_TEXT19", autoValue - self.activityData.detail.total_count))
		end
	end

	UIEventListener.Get(self.btnSkipAnimation).onClick = function ()
		local skipValue = xyd.tables.miscTable:getNumber("find_treasure_skipstep", "value") or 1

		if skipValue <= self.activityData.detail.total_count then
			if not self.SkipAnimation or self.SkipAnimation == false then
				self.SkipAnimation = true

				xyd.setUISpriteAsync(self.btnSkipAnimation:ComponentByName("", typeof(UISprite)), nil, "setting_up_pick")
			elseif self.SkipAnimation == true then
				self.SkipAnimation = false

				xyd.setUISpriteAsync(self.btnSkipAnimation:ComponentByName("", typeof(UISprite)), nil, "setting_up_unpick")
			end
		else
			xyd.alertTips(__("ACTIVITY_SECTRETTREASURE_TEXT20", skipValue - self.activityData.detail.total_count))
		end
	end

	UIEventListener.Get(self.btnAward).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_secret_treasure_hunt_award_window")
	end

	UIEventListener.Get(self.btnDetail).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_secret_treasure_hunt_event_window")
	end

	UIEventListener.Get(self.btnRight).onClick = function ()
		self.direction = 2

		self:clickBtndirection(self.direction)
	end

	UIEventListener.Get(self.btnRightTop).onClick = function ()
		self.direction = 1

		self:clickBtndirection(self.direction)
	end

	UIEventListener.Get(self.btnRightDown).onClick = function ()
		self.direction = 3

		self:clickBtndirection(self.direction)
	end

	for i = 1, 3 do
		UIEventListener.Get(self["btnDice" .. i]).onClick = function ()
			self.chooseDice = i

			self:clickBtnDice(self.chooseDice)
		end
	end

	UIEventListener.Get(self.btnGiveupDice).onClick = function ()
		self:clickBtnGiveUpDice()
	end

	UIEventListener.Get(self.plus.gameObject).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = self.resID,
			activityData = self.activityData
		})
	end)
end

function ActivitySecretTreasureHunt:ifInDice()
	if self.isInDice == false then
		return
	end

	self.isInDice = false

	xyd.models.activity:reqActivityByID(xyd.ActivityID.ENTRANCE_TEST)
	xyd.setEnabled(self.btnExplore, false)
	self:waitForTime(1, function ()
		self.curSpecialEvent = 4
		self.direction = 1

		self:eventMeetBattle()
	end)
end

function ActivitySecretTreasureHunt:resizeToParent()
	ActivitySecretTreasureHunt.super.resizeToParent(self)

	local allHeight = self.go:GetComponent(typeof(UIWidget)).height
	local heightDis = allHeight - 874

	self:resizePosY(self.mapGroup, -347, -406)
	self:resizePosY(self.ExploreGroup, 11, -77)
	self:resizePosY(self.titleImg, -109, -159)

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "ko_kr" or xyd.Global.lang == "ja_jp" or xyd.Global.lang == "zh_tw" then
		self.labelBuffTurn.width = 130
	end

	if xyd.Global.lang == "ja_jp" or xyd.Global.lang == "de_de" then
		self.labelAward.width = 92

		self.labelAward:X(10)
	elseif xyd.Global.lang == "fr_fr" then
		self.labelAward.width = 120

		self.labelAward:X(22)
		self.labelAward:Y(-47)
	end

	if xyd.Global.lang == "ko_kr" then
		self.labelRaderTitle.height = 92

		self.labelAward:X(10)
	end
end

function ActivitySecretTreasureHunt:initAnimationGoup()
	self.curMaps = {
		1,
		2,
		3,
		4,
		5,
		6
	}

	for i = 1, 6 do
		xyd.setUITextureByNameAsync(self["map" .. i], "activity_secret_treasure_hunt_map_" .. i)
	end

	self.mapWidth = self.map1.width
	self.mapHeight = self.map1.height

	self:resetMapPosition()

	self.playerModel = import("app.components.SenpaiModel").new(self.roleModelGroup.gameObject)

	self.playerModel:setModelInfo({
		ids = xyd.models.dress:getEffectEquipedStyles()
	})

	if self.isInDice == true then
		self.playerModel:walk()
	else
		self.playerModel:play("idle", 0)
	end
end

function ActivitySecretTreasureHunt:updateRadarGroup()
	if not self.RadarRate then
		self.RadarRate = 0.05
	end

	if self.RadarRate < 0.25 then
		xyd.setUISpriteAsync(self.progressBar:ComponentByName("progressImg", typeof(UISprite)), nil, "activity_secret_treasure_hunt_jindu_1")
	elseif self.RadarRate < 0.5 then
		xyd.setUISpriteAsync(self.progressBar:ComponentByName("progressImg", typeof(UISprite)), nil, "activity_secret_treasure_hunt_jindu_2")
	elseif self.RadarRate <= 1 then
		xyd.setUISpriteAsync(self.progressBar:ComponentByName("progressImg", typeof(UISprite)), nil, "activity_secret_treasure_hunt_jindu_3")
	end

	self.progressBar.value = self.RadarRate
	self.progressLabel.text = self.RadarRate * 100 .. "%"
end

function ActivitySecretTreasureHunt:updateExploreResGroup()
	self.exploreResGroup:ComponentByName("num", typeof(UILabel)).text = xyd.models.backpack:getItemNumByID(self.resID)

	if xyd.models.backpack:getItemNumByID(self.resID) > 0 then
		self.btnExplore:ComponentByName("redPoint", typeof(UISprite)):SetActive(true)
	else
		self.btnExplore:ComponentByName("redPoint", typeof(UISprite)):SetActive(false)
	end
end

function ActivitySecretTreasureHunt:updateTreasureGroup()
	local ids = xyd.tables.activitySecretTreasureAwardTable:getIDs()
	local times = self.activityData.detail.round + 1
	local maxTimes = #ids

	if not self.treasureIconList then
		self.treasureItemIconList = {}

		for i = 1, 6 do
			local icon = xyd.getItemIcon({
				scale = 0.5277777777777778,
				uiRoot = self["treasure" .. i]
			})

			table.insert(self.treasureItemIconList, icon)
			self.treasureItemIconList[i]:getIconRoot():SetActive(false)
		end

		self.treasureHeroIconList = {}

		for i = 1, 6 do
			local icon = xyd.getItemIcon({
				scale = 0.5277777777777778,
				uiRoot = self["treasure" .. i]
			}, xyd.ItemIconType.HERO_ICON)

			table.insert(self.treasureHeroIconList, icon)
			self.treasureHeroIconList[i]:getIconRoot():SetActive(false)
		end

		self.treasureIconList = {}

		for i = 1, 6 do
			self.treasureIconList[i] = self.treasureItemIconList[i]
		end

		self.curTreasureItemIcon = xyd.getItemIcon({
			scale = 0.6481481481481481,
			uiRoot = self.curTreasure
		})

		self.curTreasureItemIcon:getIconRoot():SetActive(false)

		self.curTreasureHeroIcon = xyd.getItemIcon({
			scale = 0.6481481481481481,
			uiRoot = self.curTreasure
		}, xyd.ItemIconType.HERO_ICON)

		self.curTreasureHeroIcon:getIconRoot():SetActive(false)

		self.curTreasureIcon = self.curTreasureItemIcon
	end

	for i = 1, 3 do
		local index = times - 4 + i
		local award = nil

		if index < 1 then
			award = xyd.tables.activitySecretTreasureAwardTable:getAward(index + maxTimes)
			local type = xyd.tables.itemTable:getType(award[1])

			self.treasureIconList[i]:getIconRoot():SetActive(false)

			if type == xyd.ItemType.HERO or type == xyd.ItemType.HERO_DEBRIS or type == xyd.ItemType.HERO_RANDOM_DEBRIS then
				self.treasureIconList[i] = self.treasureHeroIconList[i]
			else
				self.treasureIconList[i] = self.treasureItemIconList[i]
			end

			self.treasureIconList[i]:getIconRoot():SetActive(true)
			self.treasureIconList[i]:setChoose(false)
			self.treasureIconList[i]:setLock(true)
		else
			award = xyd.tables.activitySecretTreasureAwardTable:getAward(index)
			local type = xyd.tables.itemTable:getType(award[1])

			self.treasureIconList[i]:getIconRoot():SetActive(false)

			if type == xyd.ItemType.HERO or type == xyd.ItemType.HERO_DEBRIS or type == xyd.ItemType.HERO_RANDOM_DEBRIS then
				self.treasureIconList[i] = self.treasureHeroIconList[i]
			else
				self.treasureIconList[i] = self.treasureItemIconList[i]
			end

			self.treasureIconList[i]:getIconRoot():SetActive(true)
			self.treasureIconList[i]:setChoose(true)
			self.treasureIconList[i]:setLock(false)
		end

		self.treasureIconList[i]:setInfo({
			scale = 0.5277777777777778,
			itemID = award[1],
			num = award[2]
		})

		local showBroder = false
		local type = xyd.tables.itemTable:getType(award[1])

		if type == xyd.ItemType.HERO or type == xyd.ItemType.HERO_DEBRIS or type == xyd.ItemType.HERO_RANDOM_DEBRIS then
			showBroder = true
		end

		self.treasureIconList[i]:getBorder():SetActive(showBroder)
	end

	local award = xyd.tables.activitySecretTreasureAwardTable:getAward(times)

	if maxTimes < times then
		award = xyd.tables.activitySecretTreasureAwardTable:getAward(maxTimes)
	end

	local type = xyd.tables.itemTable:getType(award[1])

	self.curTreasureIcon:getIconRoot():SetActive(false)

	if type == xyd.ItemType.HERO or type == xyd.ItemType.HERO_DEBRIS or type == xyd.ItemType.HERO_RANDOM_DEBRIS then
		self.curTreasureIcon = self.curTreasureHeroIcon
	else
		self.curTreasureIcon = self.curTreasureItemIcon
	end

	self.curTreasureIcon:getIconRoot():SetActive(true)
	self.curTreasureIcon:setInfo({
		scale = 0.6481481481481481,
		itemID = award[1],
		num = award[2]
	})

	local showBroder = false
	local type = xyd.tables.itemTable:getType(award[1])

	if type == xyd.ItemType.HERO or type == xyd.ItemType.HERO_DEBRIS or type == xyd.ItemType.HERO_RANDOM_DEBRIS then
		showBroder = true
	end

	self.curTreasureIcon:getBorder():SetActive(showBroder)

	for i = 4, 6 do
		local index = times - 3 + i
		local award = nil

		if maxTimes < index then
			award = xyd.tables.activitySecretTreasureAwardTable:getAward(maxTimes)
		else
			award = xyd.tables.activitySecretTreasureAwardTable:getAward(index)
		end

		local type = xyd.tables.itemTable:getType(award[1])

		self.treasureIconList[i]:getIconRoot():SetActive(false)

		if type == xyd.ItemType.HERO or type == xyd.ItemType.HERO_DEBRIS or type == xyd.ItemType.HERO_RANDOM_DEBRIS then
			self.treasureIconList[i] = self.treasureHeroIconList[i]
		else
			self.treasureIconList[i] = self.treasureItemIconList[i]
		end

		self.treasureIconList[i]:getIconRoot():SetActive(true)
		self.treasureIconList[i]:setChoose(false)
		self.treasureIconList[i]:setLock(true)
		self.treasureIconList[i]:setInfo({
			scale = 0.5277777777777778,
			itemID = award[1],
			num = award[2]
		})

		local showBroder = false
		local type = xyd.tables.itemTable:getType(award[1])

		if type == xyd.ItemType.HERO or type == xyd.ItemType.HERO_DEBRIS or type == xyd.ItemType.HERO_RANDOM_DEBRIS then
			showBroder = true
		end

		self.treasureIconList[i]:getBorder():SetActive(showBroder)
	end

	local value = xyd.tables.miscTable:getNumber("find_treasure_treasurestep", "value")
	local lastAdventureTurn = xyd.db.misc:getValue("ActivitySecretTreasureHuntTreasure") or 0

	if tonumber(self.activityData.detail.total_count) < tonumber(lastAdventureTurn) then
		xyd.db.misc:setValue({
			value = 0,
			key = "ActivitySecretTreasureHuntTreasure"
		})

		lastAdventureTurn = 0
	end

	local turn = value + tonumber(lastAdventureTurn) + 1 - self.activityData.detail.total_count

	if lastAdventureTurn == nil or tonumber(lastAdventureTurn) == 0 then
		turn = value + tonumber(lastAdventureTurn) - self.activityData.detail.total_count
	end

	if turn < 1 then
		turn = 1
	end

	self.labelTreasureTurn.text = __("ACTIVITY_SECTRETTREASURE_TEXT30", turn)
end

function ActivitySecretTreasureHunt:updateRedPoint()
end

function ActivitySecretTreasureHunt:findNextMap(curMap, direction)
	local map = {
		{
			6,
			4,
			5
		},
		{
			4,
			5,
			6
		},
		{
			5,
			6,
			4
		},
		{
			3,
			1,
			2
		},
		{
			1,
			2,
			3
		},
		{
			2,
			3,
			1
		}
	}

	return map[curMap][direction]
end

function ActivitySecretTreasureHunt:resetMap(direction)
	local newRoleCurMap = self:findNextMap(self.curMaps[2], direction)
	local markMap = 0

	for i = 1, 6 do
		if self.curMaps[i] ~= newRoleCurMap then
			self.curMaps[i] = self:findNextMap(self.curMaps[i], direction)

			xyd.setUITextureByNameAsync(self["map" .. i], "activity_secret_treasure_hunt_map_" .. self.curMaps[i])
		else
			markMap = i
		end
	end

	self.map2:X(0)
	self.map2:Y(0)
	self:resetMapPosition()

	self.curMaps[markMap] = self:findNextMap(self.curMaps[markMap], direction)

	xyd.setUITextureByNameAsync(self["map" .. markMap], "activity_secret_treasure_hunt_map_" .. self.curMaps[markMap])
end

function ActivitySecretTreasureHunt:resetMapPosition()
	self.map1:X(0)
	self.map1:Y(self.mapHeight)
	self.map2:X(0)
	self.map2:Y(0)
	self.map3:X(0)
	self.map3:Y(-self.mapHeight)
	self.map4:X(self.mapWidth)
	self.map4:Y(self.mapHeight)
	self.map5:X(self.mapWidth)
	self.map5:Y(0)
	self.map6:X(self.mapWidth)
	self.map6:Y(-self.mapHeight)
end

function ActivitySecretTreasureHunt:explore(direction)
	local newRoleCurMap = self:findNextMap(self.curMaps[2], direction)

	self.awardGoup:SetActive(true)

	self.awardGoup.gameObject:GetComponent(typeof(UIWidget)).alpha = 1

	self.playerModel:walk()

	if self.mapMoveSequence then
		self.mapMoveSequence:Kill(false)

		self.mapMoveSequence = nil
	end

	local yoffset = 0
	local xoffset = -self.mapWidth
	local mapMoveTime = 2

	if self.SkipAnimation == true then
		mapMoveTime = 0.1
	end

	if direction == 1 then
		yoffset = -self.mapHeight
	elseif direction == 3 then
		yoffset = self.mapHeight
	end

	self.mapMoveSequence = DG.Tweening.DOTween.Sequence()

	self.mapMoveSequence:Insert(0, self.map1.gameObject.transform:DOLocalMove(Vector3(xoffset, self.mapHeight + yoffset, 0), mapMoveTime, false))
	self.mapMoveSequence:Insert(0, self.map2.gameObject.transform:DOLocalMove(Vector3(xoffset, yoffset, 0), mapMoveTime, false))
	self.mapMoveSequence:Insert(0, self.map3.gameObject.transform:DOLocalMove(Vector3(xoffset, -self.mapHeight + yoffset, 0), mapMoveTime, false))
	self.mapMoveSequence:Insert(0, self.map4.gameObject.transform:DOLocalMove(Vector3(self.mapWidth + xoffset, self.mapHeight + yoffset, 0), mapMoveTime, false))
	self.mapMoveSequence:Insert(0, self.map5.gameObject.transform:DOLocalMove(Vector3(self.mapWidth + xoffset, yoffset, 0), mapMoveTime, false))
	self.mapMoveSequence:Insert(0, self.map6.gameObject.transform:DOLocalMove(Vector3(self.mapWidth + xoffset, -self.mapHeight + yoffset, 0), mapMoveTime, false))
	self.mapMoveSequence:Insert(0, self.awardGoup.gameObject.transform:DOLocalMove(Vector3(self.awardGoup.transform.localPosition.x + xoffset, self.awardGoup.transform.localPosition.y + yoffset, 0), mapMoveTime, false))
	self.mapMoveSequence:AppendCallback(function ()
		self.playerModel:idle()
		self:resetMap(direction)
	end)
end

function ActivitySecretTreasureHunt:onGetMsg(event)
	local data = event.data
	local detail = json.decode(data.detail)
	self.curSpecialEvent = detail.event_id
	self.awards = detail.items
	self.RadarRate = detail.info.rate
	self.sp_count_fake = 1
	self.activityData.detail.sp_count = detail.info.sp_count
	self.flagClosedMask = false

	if self.curSpecialEvent == self.SpecialEventType.DoubleAward then
		self:eventDoubleAward()
	elseif self.curSpecialEvent == self.SpecialEventType.DoubleChange then
		self:eventDoublChange()
	elseif self.curSpecialEvent == self.SpecialEventType.GetTreasure then
		self:eventGetTreasure()
	elseif self.curSpecialEvent == self.SpecialEventType.MeetBattle then
		self:eventMeetBattle()
	elseif self.curSpecialEvent == self.SpecialEventType.Adventrue then
		self:eventAdventrue()
	elseif self.curSpecialEvent == self.SpecialEventType.Nothing or self.curSpecialEvent == self.SpecialEventType.Nothing2 then
		self:eventNothing()
	end

	if self.curSpecialEvent ~= self.SpecialEventType.MeetBattle then
		self.activityData.detail.total_count = self.activityData.detail.total_count + 1
	end
end

function ActivitySecretTreasureHunt:onGetDiceMsg(event)
	local data = event.data
	local detail = json.decode(data.detail)
	self.result = detail.is_win
	self.items = detail.items
	local text = __("ACTIVITY_SECTRETTREASURE_TEXT13")
	local callback = nil
	self.nextIsDiceFlag = false
	self.activityData.detail.total_count = self.activityData.detail.total_count + 1
	self.activityData.detail.rps = 0

	if self.result == 1 then
		text = __("ACTIVITY_SECTRETTREASURE_TEXT22")

		function callback()
			self:playBattleAnimation(self.result)
		end
	elseif self.result == -1 then
		text = __("ACTIVITY_SECTRETTREASURE_TEXT23")

		function callback()
			self:playBattleAnimation(self.result)
		end
	elseif self.result == 0 then
		text = __("ACTIVITY_SECTRETTREASURE_TEXT24")

		function callback()
			self:playBattleAnimation(self.result)
		end
	elseif self.result == nil then
		text = __("ACTIVITY_SECTRETTREASURE_TEXT25")

		function callback()
			self:playBattleAnimation(self.result)
		end
	end

	if self.result ~= nil then
		self:getEnemyDice()
		self.enemyDiceIcon.gameObject:SetActive(true)
		self.roleDiceIcon.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.enemyDiceIcon, nil, "activity_secret_treasure_hunt_dice_icon" .. self.enemyDice)
		xyd.setUISpriteAsync(self.roleDiceIcon, nil, "activity_secret_treasure_hunt_dice_icon" .. self.chooseDice)
	end

	if self.skipDice == true or self.AutoExplore == true or self.SkipAnimation == true then
		callback()
	else
		self:waitForTime(0.5, function ()
			xyd.alert(xyd.AlertType.CONFIRM, text, callback, nil, , , , , callback, nil, 28)
		end)
	end

	self.specialEventGroup:SetActive(false)
	self:setBtnDiceEnable(true)
end

function ActivitySecretTreasureHunt:getEnemyDice()
	local result = {
		{
			1,
			2,
			3
		},
		{
			2,
			3,
			1
		},
		{
			3,
			1,
			2
		}
	}
	self.enemyDice = result[self.chooseDice][self.result + 2]
end

function ActivitySecretTreasureHunt:preGenerateTreasure(direction, isTreasure)
	if isTreasure == true then
		if not self.treasureEffect then
			self.treasureEffect = self.awardGoup:ComponentByName("treasurePos", typeof(UISprite))
		end

		xyd.setUISpriteAsync(self.treasureEffect, nil, "activity_secret_treasure_hunt_icon_baoxiang_3")

		if self.boxEffect then
			self.boxEffect.gameObject:SetActive(false)
		end
	else
		if not self.boxEffect then
			self.boxEffect = self.awardGoup:ComponentByName("boxPos", typeof(UISprite))
		end

		xyd.setUISpriteAsync(self.boxEffect, nil, "activity_secret_treasure_hunt_icon_baoxiang_1")

		if self.treasureEffect then
			self.treasureEffect.gameObject:SetActive(false)
		end
	end

	if self.enemyEffect then
		self.enemyEffect:SetActive(false)
	end

	self.treasureAwardIcon:Y(0)
	self.treasureAwardIcon.gameObject:SetActive(false)
	self.awardGoup:X(self.awardGoup.transform.localPosition.x + self.mapWidth)
	self.awardGoup:Y(-(direction - 2) * self.mapHeight)
	self.awardGoup:SetActive(true)

	if isTreasure == true then
		self.treasureEffect.gameObject:SetActive(true)
	else
		self.boxEffect.gameObject:SetActive(true)
	end

	self.awardGoup.gameObject:GetComponent(typeof(UIWidget)).alpha = 1
end

function ActivitySecretTreasureHunt:preGenerateEnemy(direction)
	if self.enemyEffect then
		self.enemyEffect:destroy()

		self.enemyEffect = nil
	end

	if not self.enemyEffect then
		self.enemyEffect = xyd.Spine.new(self.enemyPos.gameObject)
	end

	self.awardGoup:SetActive(true)

	local modelIDs = xyd.tables.miscTable:split2Cost("find_treasure_modle", "value", "|")
	local name = xyd.tables.modelTable:getModelName(modelIDs[self.activityData.detail.round % #modelIDs + 1])

	self.enemyEffect:setInfo(name, function ()
		self.enemyEffect:SetLocalPosition(0, -80, 0)
		self.enemyEffect:SetLocalScale(0.6, 0.6, 1)
		self.enemyEffect:setLocalEulerAngles(0, 180, 0)
		self.enemyEffect:setRenderTarget(self.enemyPos, 2)
		self.enemyEffect:play("idle", 0)
	end)
	self.enemyEffect:SetActive(true)

	if self.treasureEffect then
		self.treasureEffect.gameObject:SetActive(false)
	end

	if self.boxEffect then
		self.boxEffect.gameObject:SetActive(false)
	end

	self.treasureAwardIcon:Y(0)
	self.treasureAwardIcon.gameObject:SetActive(false)

	self.awardGoup.gameObject:GetComponent(typeof(UIWidget)).alpha = 1
end

function ActivitySecretTreasureHunt:playAwardAnimation(isTreasure)
	local time1 = 0.7
	local time2 = 0.5

	if self.awards == nil or self.awards[1] == nil then
		self.awards = self.items
	end

	if self.SkipAnimation == true and isTreasure ~= true then
		time1 = 0.5
		time2 = 0.25
	end

	if self.awards ~= nil and self.awards[1] ~= nil then
		local type = xyd.tables.itemTable:getType(self.awards[1].item_id)
		local name = "icon_" .. self.awards[1].item_id

		if type == xyd.ItemType.HERO then
			name = xyd.tables.partnerTable:getAvatar(self.awards[1].item_id)
		elseif type == xyd.ItemType.HERO_DEBRIS then
			local partnerCost = xyd.tables.itemTable:partnerCost(heroID)
			local heroID = partnerCost[1]
			name = xyd.tables.itemTable:getIcon(heroID)
		else
			name = xyd.tables.itemTable:getIcon(self.awards[1].item_id)
		end

		xyd.setUISpriteAsync(self.treasureAwardIcon, nil, name)
	end

	local function callback()
		self.awardSequence = DG.Tweening.DOTween.Sequence()

		self.awardSequence:Insert(0, self.treasureAwardIcon.gameObject.transform:DOLocalMove(Vector3(0, 80, 0), time1, false))
		self.awardSequence:AppendCallback(function ()
			xyd.models.itemFloatModel:pushNewItems(self.awards)
			print("self:onFinishExplore()")
		end)
		self.awardSequence:Append(xyd.getTweenAlpha(self.awardGoup.gameObject:GetComponent(typeof(UIWidget)), 0.01, time2))
		self.awardSequence:AppendCallback(function ()
			if self.awardSequence then
				self.awardSequence:Kill(false)

				self.awardSequence = nil
			end

			self:onFinishExplore()
		end)
	end

	if isTreasure == true then
		xyd.setUISpriteAsync(self.treasureEffect, nil, "activity_secret_treasure_hunt_icon_baoxiang_4")
	else
		xyd.setUISpriteAsync(self.boxEffect, nil, "activity_secret_treasure_hunt_icon_baoxiang_2")
	end

	self.treasureAwardIcon.gameObject:SetActive(true)
	callback()
end

function ActivitySecretTreasureHunt:playBattleAnimation(result)
	local time1 = 0.5
	local time2 = 1

	if self.enemySequence then
		self.enemySequence:Kill(false)

		self.enemySequence = nil
	end

	if self.SkipAnimation == true then
		time2 = 0.5
	end

	self.enemySequence = DG.Tweening.DOTween.Sequence()

	self.enemySequence:Append(xyd.getTweenAlpha(self.awardGoup.gameObject:GetComponent(typeof(UIWidget)), 0.01, time1))
	self.enemySequence:AppendCallback(function ()
		self.enemySequence:Kill(false)

		self.enemySequence = nil

		self.enemyDiceIcon.gameObject:SetActive(false)
		self.roleDiceIcon.gameObject:SetActive(false)

		if result == 0 then
			self.enemyEffect:SetActive(false)
			self.enemyDiceIcon.gameObject:SetActive(false)
			self.roleDiceIcon.gameObject:SetActive(false)
			self:onFinishExplore()
		else
			self.enemyEffect:SetActive(false)
			self.enemyDiceIcon.gameObject:SetActive(false)
			self.roleDiceIcon.gameObject:SetActive(false)
			self.boxEffect.gameObject:SetActive(true)
			xyd.getTweenAlpha(self.awardGoup.gameObject:GetComponent(typeof(UIWidget)), 1, time2)
			self:playAwardAnimation(false)
		end
	end)
end

function ActivitySecretTreasureHunt:closeEventMask()
	if self.flagClosedMask == false then
		self.specialEventGroup:SetActive(false)
		self.eventGroup:SetActive(false)

		self.flagClosedMask = true
	end
end

function ActivitySecretTreasureHunt:onFinishExplore()
	if self.sp_count_fake == 1 then
		self.sp_count_fake = self.sp_count_fake - 1
	else
		self.activityData.detail.sp_count = self.activityData.detail.sp_count - 1
	end

	if self.activityData.detail.sp_count > 0 then
		self.buffGroup:SetActive(true)

		self.labelBuffTurn.text = __("ACTIVITY_SECTRETTREASURE_TEXT06", self.activityData.detail.sp_count)
	else
		self.buffGroup:SetActive(false)
	end

	self.awardGoup:Y(0)
	self.awardGoup:X(130)
	self:updateRadarGroup()
	self:updateTreasureGroup()
	self:updateExploreResGroup()
	xyd.setEnabled(self.btnExplore, true)

	self.lockExplore = false

	if self.AutoExplore == true then
		self:beginAutoExplore()
	end
end

function ActivitySecretTreasureHunt:eventDoubleAward()
	self:preGenerateTreasure(self.direction)
	self:explore(self.direction)

	local iconName = xyd.tables.activitySecretTreasureEventTable:getIcon(self.SpecialEventType.DoubleAward)
	local desc = xyd.tables.activitySecretTreasureHuntEventTextTable:getName(self.SpecialEventType.DoubleAward)
	self.labelEventDesc.text = desc
	self.eventIcon.width = 150
	self.eventIcon.height = 139

	xyd.setUISpriteAsync(self.eventIcon, nil, iconName)

	if self.SkipAnimation == true then
		self:playAwardAnimation(false)
	else
		self:waitForTime(2.5, function ()
			self.specialEventGroup:SetActive(true)
			self.eventGroup:SetActive(true)
			self.diceGroup:SetActive(false)
		end)
		self:waitForTime(4, function ()
			if self.flagClosedMask == false then
				self:closeEventMask()
				self:playAwardAnimation(false)
			end
		end)
	end
end

function ActivitySecretTreasureHunt:eventDoublChange()
	self:preGenerateTreasure(self.direction)
	self:explore(self.direction)

	local iconName = xyd.tables.activitySecretTreasureEventTable:getIcon(self.SpecialEventType.DoubleChange)
	local desc = xyd.tables.activitySecretTreasureHuntEventTextTable:getName(self.SpecialEventType.DoubleChange)
	self.labelEventDesc.text = desc

	xyd.setUISpriteAsync(self.eventIcon, nil, iconName)

	if self.SkipAnimation == true then
		self:playAwardAnimation(false)
	else
		self:waitForTime(2.5, function ()
			self.specialEventGroup:SetActive(true)
			self.eventGroup:SetActive(true)
			self.diceGroup:SetActive(false)
		end)
		self:waitForTime(4, function ()
			if self.flagClosedMask == false then
				self:closeEventMask()
				self:playAwardAnimation(false)
			end
		end)
	end
end

function ActivitySecretTreasureHunt:eventGetTreasure()
	xyd.db.misc:setValue({
		key = "ActivitySecretTreasureHuntTreasure",
		value = self.activityData.detail.total_count
	})
	self:preGenerateTreasure(self.direction, true)
	print("===================1")
	self:explore(self.direction)
	print("===================2")

	local iconName = xyd.tables.activitySecretTreasureEventTable:getIcon(self.SpecialEventType.GetTreasure)
	local desc = xyd.tables.activitySecretTreasureHuntEventTextTable:getName(self.SpecialEventType.GetTreasure)
	self.labelEventDesc.text = desc

	xyd.setUISpriteAsync(self.eventIcon, nil, iconName)

	if self.SkipAnimation == true then
		self.specialEventGroup:SetActive(true)
		self.eventGroup:SetActive(true)
		self.diceGroup:SetActive(false)
		print("===================3")
		self:waitForTime(2, function ()
			if self.flagClosedMask == false then
				self:closeEventMask()
				print("===================4")
				self:playAwardAnimation(true)
			end
		end)
	else
		self:waitForTime(2.5, function ()
			self.specialEventGroup:SetActive(true)
			self.eventGroup:SetActive(true)
			self.diceGroup:SetActive(false)
		end)
		self:waitForTime(4, function ()
			if self.flagClosedMask == false then
				self:closeEventMask()
				self:playAwardAnimation(true)
			end
		end)
	end

	self.activityData.detail.round = self.activityData.detail.round + 1
end

function ActivitySecretTreasureHunt:eventAdventrue()
	self:preGenerateTreasure(self.direction)
	self:explore(self.direction)

	local iconName = xyd.tables.activitySecretTreasureEventTable:getIcon(self.SpecialEventType.Adventrue)
	local desc = xyd.tables.activitySecretTreasureHuntEventTextTable:getName(self.SpecialEventType.Adventrue)
	self.labelEventDesc.text = desc

	xyd.setUISpriteAsync(self.eventIcon, nil, iconName)

	if self.SkipAnimation == true then
		self:playAwardAnimation(false)
	else
		self:waitForTime(2.5, function ()
			self.specialEventGroup:SetActive(true)
			self.eventGroup:SetActive(true)
			self.diceGroup:SetActive(false)
		end)
		self:waitForTime(4, function ()
			if self.flagClosedMask == false then
				self:closeEventMask()
				self:playAwardAnimation(false)
			end
		end)
	end
end

function ActivitySecretTreasureHunt:eventMeetBattle()
	self.activityData.detail.rps = 1

	self:preGenerateTreasure(self.direction)
	self:preGenerateEnemy(self.direction)
	self:explore(self.direction)

	if self.SkipAnimation == true then
		self:clickBtnGiveUpDice()
	elseif self.AutoExplore == true then
		self:waitForTime(2.5, function ()
			self:clickBtnGiveUpDice()
		end)
	else
		self:waitForTime(2.5, function ()
			local recordChoose = xyd.db.misc:getValue("secretTreasureHunt_dice_tip_timeStamp")

			if recordChoose == nil or tonumber(recordChoose) < self.activityData:getEndTime() then
				local function callback()
					self.specialEventGroup:SetActive(true)
					self.eventGroup:SetActive(false)
					self.diceGroup:SetActive(true)
					xyd.db.misc:setValue({
						key = "secretTreasureHunt_dice_tip_timeStamp",
						value = self.activityData:getEndTime()
					})
				end

				xyd.alert(xyd.AlertType.CONFIRM, __("ACTIVITY_SECTRETTREASURE_TEXT10"), callback, __("ACTIVITY_SECTRETTREASURE_TEXT36"), nil, , , , callback, 120)
			else
				self.specialEventGroup:SetActive(true)
				self.eventGroup:SetActive(false)
				self.diceGroup:SetActive(true)
			end
		end)
	end
end

function ActivitySecretTreasureHunt:eventNothing()
	self:preGenerateTreasure(self.direction)
	self:explore(self.direction)

	if self.SkipAnimation == true then
		self:playAwardAnimation(false)
	else
		self:waitForTime(2.5, function ()
			if self.flagClosedMask == false then
				self:playAwardAnimation(false)
			end
		end)
	end
end

function ActivitySecretTreasureHunt:clickBtnExplore()
	self.btnExplore:ComponentByName("redPoint", typeof(UISprite)):SetActive(false)

	if xyd.models.backpack:getItemNumByID(self.resID) <= 0 then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.resID)))

		self.AutoExplore = false
		self.skipDice = false

		xyd.setUISpriteAsync(self.btnAutoExplore:ComponentByName("", typeof(UISprite)), nil, "btn_max")

		return
	end

	xyd.setEnabled(self.btnExplore, false)

	if self.AutoExplore == true then
		if self.SkipAnimation ~= true then
			self.directionBtnGroup:SetActive(true)
			self:waitForTime(0.8, function ()
				local direction = xyd.random(1, 3, {
					int = true
				})
				self.direction = direction

				self:clickBtndirection(self.direction)
			end)
		else
			local direction = xyd.random(1, 3, {
				int = true
			})
			self.direction = direction

			self:clickBtndirection(self.direction)
		end
	elseif self.SkipAnimation ~= true then
		self.directionBtnGroup:SetActive(true)
	else
		local direction = xyd.random(1, 3, {
			int = true
		})
		self.direction = direction

		self:clickBtndirection(self.direction)
	end
end

function ActivitySecretTreasureHunt:clickBtnDice(chooseDice)
	self:setBtnDiceEnable(false)

	local data = require("cjson").encode({
		rps = 1
	})
	local msg = messages_pb:get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_SECRET_TREASURE_HUNT
	msg.params = data

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

	self.nextIsDiceFlag = true
end

function ActivitySecretTreasureHunt:clickBtnGiveUpDice()
	self:setBtnDiceEnable(false)

	local data = require("cjson").encode({
		rps = 0
	})
	local msg = messages_pb:get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_SECRET_TREASURE_HUNT
	msg.params = data

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

	self.nextIsDiceFlag = true
end

function ActivitySecretTreasureHunt:clickBtndirection(direction)
	self.directionBtnGroup:SetActive(false)

	self.lockExplore = true
	local msg = messages_pb:get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_SECRET_TREASURE_HUNT
	msg.params = require("cjson").encode({})

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function ActivitySecretTreasureHunt:setBtnDiceEnable(flag)
	for i = 1, 3 do
		xyd.setEnabled(self["btnDice" .. i], flag)
	end

	xyd.setEnabled(self.btnGiveupDice, flag)
end

function ActivitySecretTreasureHunt:beginAutoExplore()
	if self.lockExplore == true then
		return
	end

	self:clickBtnExplore()
end

function ActivitySecretTreasureHunt:dispose()
	ActivitySecretTreasureHunt.super.dispose(self)

	if self.enemySequence then
		self.enemySequence:Kill(false)

		self.enemySequence = nil
	end

	if self.awardSequence then
		self.awardSequence:Kill(false)

		self.awardSequence = nil
	end

	if self.mapMoveSequence then
		self.mapMoveSequence:Kill(false)

		self.mapMoveSequence = nil
	end
end

return ActivitySecretTreasureHunt
