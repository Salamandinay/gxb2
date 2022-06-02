local BaseWindow = import(".BaseWindow")
local ActivityExploreCampusFightWindow = class("ActivityExploreCampusFightWindow", BaseWindow)
local BuffsItem = class("BuffsItem", import("app.components.CopyComponent"))
local explainItem = class("BuffsItem", import("app.components.CopyComponent"))
local skillIconSmall = import("app.components.SkillIconSmall")
local HeroIcon = import("app.components.HeroIcon")
local BUFFS_TYPE = {
	SECOND_POINT = 3,
	FIRST_POINT = 2,
	DEFAULT = 1
}
local TYPE_LENGTH = 3
local FIRST_SET_LOCAL_BUFFS = 1
local LOCAL_BUFFS = nil

function ActivityExploreCampusFightWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function ActivityExploreCampusFightWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)

	self.itemArr = {}
	self.choiceBuffArr = {}
	self.choiceBuffItemArr = {}
	self.baseScore = xyd.tables.oldBuildingStageTable:getPoint(self.params_.levelId)
	self.curScore = self.baseScore
	self.curChoiceState = nil
	local cjson = require("cjson")
	local detail = xyd.db.misc:getValue("old_building_buffs_choice_local_all")
	detail = detail and cjson.decode(detail)
	local curLevelDetail = {}
	local seasonIdsLength = #xyd.tables.oldBuildingStageTable:getIdsByType(xyd.models.oldSchool:seasonType())

	if detail and type(detail[(self.params_.levelId - 1) % seasonIdsLength + 1]) == "userdata" then
		detail[(self.params_.levelId - 1) % seasonIdsLength + 1] = {}
	end

	if xyd.models.oldSchool:getAllInfo().season_info.count ~= xyd.models.oldSchool:getSaveLocalBuffsCount() and detail then
		if not detail[(self.params_.levelId - 1) % seasonIdsLength + 1] then
			detail[(self.params_.levelId - 1) % seasonIdsLength + 1] = {}
		end

		for i, id in pairs(xyd.tables.oldBuildingStageTable:getIdsByType(xyd.models.oldSchool:seasonType())) do
			if (id - 1) % seasonIdsLength + 1 ~= (self.params_.levelId - 1) % seasonIdsLength + 1 then
				detail[(id - 1) % seasonIdsLength + 1] = {}
			end
		end

		local curSeasonBuffs = xyd.tables.oldBuildingBuffTable:getBuffBelongArr(xyd.models.oldSchool:seasonType())

		for i in pairs(detail[(self.params_.levelId - 1) % seasonIdsLength + 1]) do
			for k in pairs(curSeasonBuffs) do
				if detail[(self.params_.levelId - 1) % seasonIdsLength + 1][i] == curSeasonBuffs[k] then
					local buffTable = xyd.tables.oldBuildingBuffTable
					local isLock = false
					local lockState = buffTable:needUnlock(tonumber(detail[(self.params_.levelId - 1) % seasonIdsLength + 1][i]))
					local needPoint = buffTable:getUnlockCost(tonumber(detail[(self.params_.levelId - 1) % seasonIdsLength + 1][i]))[1]

					if lockState and lockState == 1 and xyd.models.oldSchool:getAllInfo().max_score < needPoint then
						isLock = true
					end

					if not isLock then
						table.insert(curLevelDetail, detail[(self.params_.levelId - 1) % seasonIdsLength + 1][i])
					end
				end
			end
		end

		detail[(self.params_.levelId - 1) % seasonIdsLength + 1] = curLevelDetail

		xyd.models.oldSchool:setSaveLocalBuffsCount(xyd.models.oldSchool:getAllInfo().season_info.count)

		local detailAll = cjson.encode(detail)
		local detailCur = cjson.encode(detail[(self.params_.levelId - 1) % seasonIdsLength + 1])

		xyd.db.misc:setValue({
			key = "old_building_buffs_choice_local_all",
			value = detailAll
		})
		xyd.db.misc:setValue({
			key = "old_building_buffs_choice_common",
			value = detailCur
		})
	end

	LOCAL_BUFFS = nil
	FIRST_SET_LOCAL_BUFFS = 1

	if detail ~= nil then
		if detail[(self.params_.levelId - 1) % seasonIdsLength + 1] and #detail[(self.params_.levelId - 1) % seasonIdsLength + 1] ~= 0 then
			LOCAL_BUFFS = detail[(self.params_.levelId - 1) % seasonIdsLength + 1]
		else
			local detailCommon = xyd.db.misc:getValue("old_building_buffs_choice_common")

			if detailCommon then
				LOCAL_BUFFS = cjson.decode(detailCommon)
			end
		end
	else
		local detailCommon = xyd.db.misc:getValue("old_building_buffs_choice_common")

		if detailCommon then
			LOCAL_BUFFS = cjson.decode(detailCommon)
		end
	end

	self:initUIComponent()
	self:register()
end

function ActivityExploreCampusFightWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupAction = trans:NodeByName("groupAction").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.explainGroup = self.groupAction:NodeByName("explainGroup").gameObject
	self.explainBg = self.explainGroup:ComponentByName("explainBg", typeof(UISprite))
	self.explainAllScoreText = self.explainGroup:ComponentByName("explainAllScoreText", typeof(UILabel))
	self.explainBaseText = self.explainGroup:ComponentByName("explainBaseText", typeof(UILabel))
	self.explainScroller = self.explainGroup:NodeByName("explainScroller").gameObject
	self.explainScroller_uiScrollView = self.explainGroup:ComponentByName("explainScroller", typeof(UIScrollView))
	self.explainScroller_uiPanel = self.explainGroup:ComponentByName("explainScroller", typeof(UIPanel))
	self.explainContainer = self.explainScroller:NodeByName("explainContainer").gameObject
	self.explainContainer_uiLayout = self.explainScroller:ComponentByName("explainContainer", typeof(UILayout))
	self.drag = self.explainGroup:NodeByName("drag").gameObject
	self.explainItem = self.explainGroup:NodeByName("explainItem").gameObject

	self.explainItem:SetActive(false)

	self.buffsGroup = self.groupAction:NodeByName("buffsGroup").gameObject
	self.buffsBg = self.buffsGroup:ComponentByName("buffsBg", typeof(UISprite))
	self.buffsNameText = self.buffsGroup:ComponentByName("buffsNameText", typeof(UILabel))
	self.buffsScroller = self.buffsGroup:NodeByName("buffsScroller").gameObject
	self.buffsScroller_scrollView = self.buffsGroup:ComponentByName("buffsScroller", typeof(UIScrollView))
	self.buffsContainer = self.buffsScroller:NodeByName("buffsContainer").gameObject
	self.buffsContainer_uiGrid = self.buffsScroller:ComponentByName("buffsContainer", typeof(UIGrid))
	self.drag = self.buffsGroup:NodeByName("drag").gameObject
	self.awardItem = self.buffsGroup:NodeByName("awardItem").gameObject
	self.resetBtn = self.buffsGroup:NodeByName("resetBtn").gameObject
	self.partnerGroup = self.groupAction:NodeByName("partnerGroup").gameObject
	self.partnerBg1 = self.partnerGroup:ComponentByName("partnerBg1", typeof(UISprite))
	self.partnerBg2 = self.partnerGroup:ComponentByName("partnerBg2", typeof(UISprite))
	self.partnerTeamIndex = self.partnerGroup:ComponentByName("partnerTeamIndex", typeof(UISprite))
	self.battle_btn = self.partnerGroup:NodeByName("battle_btn").gameObject
	self.battle_btn_label = self.battle_btn:ComponentByName("button_label", typeof(UILabel))
	self.skip_btn = self.partnerGroup:NodeByName("skip_btn").gameObject
	self.skip_btn_label = self.skip_btn:ComponentByName("button_label", typeof(UILabel))
	self.selected_icon = self.skip_btn:ComponentByName("selected_icon", typeof(UISprite))
	self.selected_icon_bg = self.skip_btn:ComponentByName("selected_icon_bg", typeof(UISprite))
	self.setting_btn = self.partnerGroup:NodeByName("setting_btn").gameObject
	self.setting_btn_label = self.setting_btn:ComponentByName("button_label", typeof(UILabel))
	self.leftGroup = self.partnerGroup:NodeByName("leftGroup").gameObject

	for i = 1, 6 do
		self["leftCon" .. i] = self.leftGroup:NodeByName("leftCon_" .. i).gameObject
		self["leftMaskImg" .. i] = self["leftCon" .. i]:ComponentByName("maskImg3", typeof(UISprite))
	end

	self.rightGroup = self.partnerGroup:NodeByName("rightGroup").gameObject

	for i = 1, 6 do
		self["rightCon" .. i] = self.rightGroup:NodeByName("rightCon_" .. i).gameObject
		self["rightMaskImg" .. i] = self["rightCon" .. i]:ComponentByName("maskImg3", typeof(UISprite))
	end

	self.battleIcon = self.partnerGroup:ComponentByName("battleIcon", typeof(UISprite))
end

function ActivityExploreCampusFightWindow:initUIComponent()
	local floorId = xyd.tables.oldBuildingStageTable:getFloor(self.params_.levelId)
	self.labelTitle.text = __("OLD_SCHOOL_FIGHT_NAME", floorId, self.params_.levelIndex)
	self.explainAllScoreText.text = __("ACTIVITY_EXPLORE_CAMPUS_7", self.curScore)
	self.explainBaseText.text = __("ACTIVITY_EXPLORE_CAMPUS_8", self.baseScore)
	self.buffsNameText.text = __("ACTIVITY_EXPLORE_CAMPUS_6")

	self.awardItem:SetActive(true)

	for i = 1, TYPE_LENGTH do
		local tmp = NGUITools.AddChild(self.buffsContainer.gameObject, self.awardItem.gameObject)
		local item = BuffsItem.new(tmp, i, self)

		table.insert(self.itemArr, item)

		if i ~= TYPE_LENGTH then
			item:setLineShow(true)
		else
			item:setLineShow(false)
		end
	end

	self.awardItem:SetActive(false)
	self.buffsScroller_scrollView:ResetPosition()
	self:updateBuffs()

	local isSkip = xyd.db.misc:getValue("explore_old_campus_skip_fight")

	if not isSkip or isSkip and isSkip == "0" then
		self.selected_icon:SetActive(false)
	else
		self.selected_icon:SetActive(true)
	end

	self.setting_btn_label.text = __("SET_DEF_FORMATION")
	self.skip_btn_label.text = __("SKIP_BATTLE2")
	self.battle_btn_label.text = __("FIGHT3")

	xyd.setUISpriteAsync(self.partnerTeamIndex, nil, "arena_3v3_t" .. self.params_.levelIndex, nil, )

	local battleId = xyd.tables.oldBuildingStageTable:getBattleId(self.params_.levelId)
	local monsters = xyd.tables.battleTable:getMonsters(battleId)
	local stands = xyd.tables.battleTable:getStands(battleId)

	for i = 1, #monsters do
		local tableID = monsters[i]
		local id = xyd.tables.monsterTable:getPartnerLink(tableID)
		local lev = xyd.tables.monsterTable:getShowLev(tableID)
		local icon = HeroIcon.new(self["rightCon" .. stands[i]])

		icon:setInfo({
			noClick = true,
			tableID = id,
			lev = lev
		})

		local scale = 0.49

		icon:setScale(scale)
	end

	for i = 1, 6 do
		self["myPartner" .. i] = HeroIcon.new(self["leftCon" .. i])
		local scale = 0.49

		self["myPartner" .. i]:setScale(scale)
		self["myPartner" .. i]:SetActive(false)
	end

	self:updateHeroIcons(self.params_.formation)
end

function ActivityExploreCampusFightWindow:getLevelId()
	return self.params_.levelId
end

function ActivityExploreCampusFightWindow:updateHeroIcons(partnerteams)
	self.params_.formation = partnerteams
	local team = {}

	for i = (self.params_.levelIndex - 1) * 6 + 1, (self.params_.levelIndex - 1) * 6 + 6 do
		if partnerteams[i] then
			table.insert(team, partnerteams[i])
		end
	end

	local petteams = xyd.models.oldSchool:getDefTeams()
	local pets = {
		0,
		0,
		0,
		0
	}

	for k, v in ipairs(petteams) do
		local petId = v.pet_id

		if petId and petId > 0 then
			pets[k + 1] = petId
		end
	end

	self.pets = pets

	for i = 1, 6 do
		self["myPartner" .. i]:getIconRoot():SetActive(false)
		self["myPartner" .. i]:setScale(0.49)
	end

	for i, p in pairs(team) do
		local paramsData = xyd.models.slot:getPartner(p.partner_id)
		paramsData.noClick = true

		self["myPartner" .. p.pos]:setInfo(paramsData, self.pets[self.params_.levelIndex + 1])
		self["myPartner" .. p.pos]:getIconRoot():SetActive(true)
		self["myPartner" .. p.pos]:setScale(0.49)
	end
end

function ActivityExploreCampusFightWindow:register()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.skip_btn.gameObject).onClick = handler(self, function ()
		if self.selected_icon.gameObject.activeSelf == true then
			self.selected_icon:SetActive(false)
			xyd.db.misc:setValue({
				value = "0",
				key = "explore_old_campus_skip_fight"
			})
		else
			self.selected_icon.gameObject:SetActive(true)
			xyd.db.misc:setValue({
				value = "1",
				key = "explore_old_campus_skip_fight"
			})
		end
	end)
	UIEventListener.Get(self.resetBtn.gameObject).onClick = handler(self, function ()
		if #self.choiceBuffArr > 0 then
			xyd.alertYesNo(__("OLD_SCHOOL_DELETE_ALL_BUFFS"), function (yes_no)
				if not yes_no then
					return
				end

				for i in pairs(self.itemArr) do
					self.itemArr[i]:removeAllClick()
				end
			end)
		else
			xyd.alertYesNo(__("OLD_SCHOOL_TIPS01"), function (yes_no)
				if not yes_no then
					return
				end

				for i in pairs(self.itemArr) do
					self.itemArr[i]:selectAllClick()
				end
			end)
		end
	end)
	UIEventListener.Get(self.setting_btn.gameObject).onClick = handler(self, function ()
		local floorId = xyd.tables.oldBuildingStageTable:getFloor(self.params_.levelId)

		xyd.WindowManager.get():openWindow("arena_3v3_battle_formation_window", {
			battleType = xyd.BattleType.EXPLORE_OLD_CAMPUS,
			formation = self.params_.formation,
			floor_id = floorId,
			levelNum = #xyd.models.oldSchool:getOldBuildingTableTable():getStage(floorId),
			isCurFloorZero = self.params_.isCurFloorZero
		})
	end)
	UIEventListener.Get(self.battle_btn.gameObject).onClick = handler(self, function ()
		if xyd.models.oldSchool:getChallengeEndTime() <= xyd.getServerTime() then
			xyd.alertTips(__("ACTIVITY_END_YET"))

			return
		end

		if xyd.models.activity:getExploreOldCampusIsFight() == false then
			xyd.alertTips(__("ACTIVITY_EXPLORE_CAMPUS_LIMIT_TIME", 3))

			return
		end

		local msg = messages_pb:old_building_fight_req()
		msg.stage_id = self.params_.levelId

		for i in pairs(self.choiceBuffArr) do
			table.insert(msg.buff_ids, self.choiceBuffArr[i])
		end

		xyd.Backend.get():request(xyd.mid.OLD_BUILDING_FIGHT, msg)
		xyd.WindowManager.get():closeWindow(self.name_)

		local cjson = require("cjson")
		local detail = xyd.db.misc:getValue("old_building_buffs_choice_local_all")

		if detail then
			detail = cjson.decode(detail)
		else
			detail = {}

			for i, id in pairs(xyd.tables.oldBuildingStageTable:getIdsByType(xyd.models.oldSchool:seasonType())) do
				if id ~= self.params_.levelId then
					detail[id] = {}
				end
			end
		end

		local seasonIdsLength = #xyd.tables.oldBuildingStageTable:getIdsByType(xyd.models.oldSchool:seasonType())

		if #self.choiceBuffArr ~= 0 then
			detail[(self.params_.levelId - 1) % seasonIdsLength + 1] = self.choiceBuffArr
			local detailCur = cjson.encode(self.choiceBuffArr)
			local detailAll = cjson.encode(detail)

			xyd.db.misc:setValue({
				key = "old_building_buffs_choice_local_all",
				value = detailAll
			})
			xyd.db.misc:setValue({
				key = "old_building_buffs_choice_common",
				value = detailCur
			})
		else
			local tempArr = {}

			table.insert(tempArr, -1)

			detail[(self.params_.levelId - 1) % seasonIdsLength + 1] = tempArr
			local detailCur = cjson.encode(tempArr)
			local detailAll = cjson.encode(detail)

			xyd.db.misc:setValue({
				key = "old_building_buffs_choice_local_all",
				value = detailAll
			})
			xyd.db.misc:setValue({
				key = "old_building_buffs_choice_common",
				value = detailCur
			})
		end
	end)
end

function ActivityExploreCampusFightWindow:choiceBuff(buff_id)
	local buffType = xyd.tables.oldBuildingBuffTable:getType(buff_id)

	if #self.choiceBuffArr == 0 then
		self.curChoiceState = buffType
	elseif self.curChoiceState ~= buffType then
		-- Nothing
	end

	if xyd.arrayIndexOf(self.choiceBuffArr, buff_id) <= -1 then
		table.insert(self.choiceBuffArr, buff_id)
	end

	local tempArr = {}
	local buffTable = xyd.tables.oldBuildingBuffTable

	for i in pairs(self.choiceBuffArr) do
		table.insert(tempArr, {
			buff_id = self.choiceBuffArr[i],
			point = buffTable:getPoint(self.choiceBuffArr[i])
		})
	end

	table.sort(tempArr, function (a, b)
		if a.point == b.point then
			return a.buff_id < b.buff_id
		end

		return math.abs(a.point) < math.abs(b.point)
	end)

	self.choiceBuffArr = {}

	for i in pairs(tempArr) do
		table.insert(self.choiceBuffArr, tempArr[i].buff_id)
	end

	for i in pairs(self.choiceBuffArr) do
		if self.choiceBuffItemArr[i] then
			if self.choiceBuffItemArr[i]:getBuffId() ~= self.choiceBuffArr[i] then
				self.choiceBuffItemArr[i]:updateBuffInfo(self.choiceBuffArr[i])
			end
		else
			self.explainItem:SetActive(true)

			local tmp = NGUITools.AddChild(self.explainContainer.gameObject, self.explainItem.gameObject)
			local item = explainItem.new(tmp, self.choiceBuffArr[i], self)

			table.insert(self.choiceBuffItemArr, item)
			self.explainItem:SetActive(false)
		end
	end

	local allHeight = 0
	local curHeight = 0
	local isCountCurHeight = true

	for i in ipairs(self.choiceBuffItemArr) do
		allHeight = allHeight + self.choiceBuffItemArr[i]:getHeight() + self.explainContainer_uiLayout.gap.y

		if isCountCurHeight == true and self.choiceBuffItemArr[i]:getBuffId() ~= buff_id then
			curHeight = curHeight + self.choiceBuffItemArr[i]:getHeight() + self.explainContainer_uiLayout.gap.y
		end

		if self.choiceBuffItemArr[i]:getBuffId() == buff_id then
			isCountCurHeight = false
		end
	end

	allHeight = allHeight - self.explainContainer_uiLayout.gap.y

	self.explainContainer_uiLayout:Reposition()
	self.explainScroller_uiScrollView:ResetPosition()

	if self.explainScroller_uiPanel.height < allHeight then
		self:waitForFrame(1, function ()
			self.explainScroller_uiScrollView:SetDragAmount(0, math.min(1, curHeight / (allHeight - self.explainScroller_uiPanel.height)), false)
		end, nil)
	end

	self:updateCurScore(buff_id, 1)
end

function ActivityExploreCampusFightWindow:choiceRemoveBuff(buff_id)
	if #self.choiceBuffArr == 0 then
		return
	end

	local buffType = xyd.tables.oldBuildingBuffTable:getType(buff_id)

	if self.curChoiceState ~= buffType then
		-- Nothing
	end

	if xyd.arrayIndexOf(self.choiceBuffArr, buff_id) <= -1 then
		return
	end

	local first_y = self.explainGroup.transform:InverseTransformPoint(self.choiceBuffItemArr[1]:getItemObj().transform.position).y
	local last_y = self.explainGroup.transform:InverseTransformPoint(self.choiceBuffItemArr[#self.choiceBuffItemArr]:getItemObj().transform.position).y
	local isShowFirst = false
	local isShowLast = false

	if first_y - self.choiceBuffItemArr[1]:getHeight() - self.explainContainer_uiLayout.gap.y < self.explainScroller.transform.localPosition.y + self.explainScroller_uiPanel.clipOffset.y then
		isShowFirst = true
	end

	if last_y > self.explainScroller.transform.localPosition.y - self.explainScroller_uiPanel.height + self.explainScroller_uiPanel.clipOffset.y then
		isShowLast = true
	end

	local tempItem = self.choiceBuffItemArr[#self.choiceBuffItemArr]

	table.remove(self.choiceBuffItemArr, #self.choiceBuffItemArr)
	NGUITools.Destroy(tempItem:getItemObj().transform)

	for i in pairs(self.choiceBuffArr) do
		if self.choiceBuffArr[i] == buff_id then
			table.remove(self.choiceBuffArr, i)
		end
	end

	for i in pairs(self.choiceBuffArr) do
		if self.choiceBuffItemArr[i] and self.choiceBuffItemArr[i]:getBuffId() ~= self.choiceBuffArr[i] then
			self.choiceBuffItemArr[i]:updateBuffInfo(self.choiceBuffArr[i])
		end
	end

	self.explainContainer_uiLayout:Reposition()

	if isShowLast == true then
		self.explainScroller_uiScrollView:ResetPosition()
	end

	self:waitForFrame(1, function ()
		if isShowFirst == true and isShowLast == true then
			self.explainScroller_uiScrollView:SetDragAmount(0, math.min(1, 0), false)
		end

		if isShowFirst == false and isShowLast == true then
			self.explainScroller_uiScrollView:SetDragAmount(0, math.min(1, 1), false)
		end
	end, nil)
	self:updateCurScore(buff_id, -1)
end

function ActivityExploreCampusFightWindow:updateCurScore(buff_id, mark)
	self.curScore = self.curScore + mark * xyd.tables.oldBuildingBuffTable:getPoint(buff_id)
	self.explainAllScoreText.text = __("ACTIVITY_EXPLORE_CAMPUS_7", self.curScore)
end

function ActivityExploreCampusFightWindow:getIsCanChoice(buff_id)
	local buffType = xyd.tables.oldBuildingBuffTable:getType(buff_id)

	if #self.choiceBuffArr == 0 then
		return true
	elseif self.curChoiceState ~= buffType then
		return true
	end

	return true
end

function ActivityExploreCampusFightWindow:updateBuffs()
	for i in pairs(self.itemArr) do
		self.itemArr[i]:updateItemBuffs()
	end
end

function explainItem:ctor(goItem, buff_id, parent)
	self.goItem_ = goItem
	self.buff_id = buff_id
	self.parent = parent
	self.explainItemArr = {}
	self.iconCon = self.goItem_:NodeByName("iconCon").gameObject
	self.labelText = self.goItem_:ComponentByName("labelText", typeof(UILabel))
	self.labelText_widget = self.labelText.gameObject:GetComponent(typeof(UIWidget))
	self.goItem_widget = self.goItem_:GetComponent(typeof(UIWidget))

	self:initItem()
	self:initEvent()
	self:updateBuffInfo(buff_id)
end

function explainItem:initEvent()
end

function explainItem:getItemObj()
	return self.goItem_
end

function explainItem:initItem()
	self.paramsData = {
		scale = 1,
		isLock = false,
		dragScrollView = self.parent.explainScroller_uiScrollView,
		score = xyd.tables.oldBuildingBuffTable:getPoint(self.buff_id)
	}
	self.skillIcon = skillIconSmall.new(self.iconCon.gameObject)

	self.skillIcon:setInfo(self.buff_id, self.paramsData)
end

function explainItem:getBuffId()
	return self.buff_id
end

function explainItem:updateBuffInfo(buff_id)
	self.labelText.text = xyd.tables.oldBuildingBuffTextTable:getBuffDesc(buff_id)
	self.buff_id = buff_id
	self.paramsData = {
		scale = 1,
		isLock = false,
		dragScrollView = self.parent.explainScroller_uiScrollView,
		score = xyd.tables.oldBuildingBuffTable:getPoint(self.buff_id)
	}

	self.skillIcon:setInfo(self.buff_id, self.paramsData)

	if self.labelText_widget.height + 20 < 67 then
		self.goItem_widget.height = 67
	else
		self.goItem_widget.height = self.labelText_widget.height + 20
	end

	self.skillIcon:setLocalPosition(0, -40, 0)
end

function explainItem:getHeight()
	return self.goItem_widget.height
end

function BuffsItem:ctor(goItem, index, parent)
	self.goItem_ = goItem
	self.index = index
	self.parent = parent
	self.buffsItemArr = {}
	self.goItem_widget = self.goItem_:GetComponent(typeof(UIWidget))
	self.levelLabel = self.goItem_:ComponentByName("levelLabel", typeof(UILabel))
	self.iconGroup = self.goItem_:ComponentByName("iconGroup", typeof(UIGrid))
	self.blue_line = self.goItem_:ComponentByName("blue_line", typeof(UISprite))

	self:initItem()
	self:initEvent()
end

function BuffsItem:initEvent()
end

function BuffsItem:getItemObj()
	return self.goItem_
end

function BuffsItem:initItem()
	local finalBuffArr = {}
	local buffsArr = xyd.tables.oldBuildingBuffTable:getBuffBelongArr(xyd.models.oldSchool:seasonType())
	local buffTable = xyd.tables.oldBuildingBuffTable

	for i in pairs(buffsArr) do
		if buffTable:getType(buffsArr[i]) == self.index then
			table.insert(finalBuffArr, {
				buff_id = buffsArr[i],
				point = buffTable:getPoint(buffsArr[i])
			})
		end
	end

	if self.index == BUFFS_TYPE.DEFAULT then
		self.levelLabel.text = __("OLD_SCHOLL_BUFF_NAME1")
	elseif self.index == BUFFS_TYPE.FIRST_POINT then
		self.levelLabel.text = __("OLD_SCHOLL_BUFF_NAME2")
	elseif self.index == BUFFS_TYPE.SECOND_POINT then
		self.levelLabel.text = __("OLD_SCHOLL_BUFF_NAME3")
	end

	table.sort(finalBuffArr, function (a, b)
		if a.point == b.point then
			return a.buff_id < b.buff_id
		end

		return math.abs(a.point) < math.abs(b.point)
	end)

	self.goItem_widget.height = 30 + math.ceil(#finalBuffArr / 7) * self.iconGroup.cellHeight

	self.blue_line:Y(-self.goItem_widget.height + 6)

	for i in pairs(finalBuffArr) do
		local isLock = false
		local lockState = buffTable:needUnlock(tonumber(finalBuffArr[i].buff_id))
		local needPoint = buffTable:getUnlockCost(tonumber(finalBuffArr[i].buff_id))[1]

		if lockState and lockState == 1 and xyd.models.oldSchool:getAllInfo().max_score < needPoint then
			isLock = true
		end

		local params = {
			isTipsCallBackChoose = true,
			scale = 0.825,
			dragScrollView = self.parent.buffsScroller_scrollView,
			callBack = function (buff_id)
				xyd.WindowManager.get():openWindow("activity_explore_old_campus_way_buy_window", {
					id = finalBuffArr[i].buff_id,
					area_id = self.parent.params_.area_id
				})
			end,
			score = finalBuffArr[i].point,
			isLock = isLock,
			tipsCallBack = function (buff_id, posy, isChoose)
				local isLock = false
				local buffTable = xyd.tables.oldBuildingBuffTable
				local lockState = buffTable:needUnlock(tonumber(buff_id))
				local needPoint = buffTable:getUnlockCost(tonumber(buff_id))[1]

				if lockState and lockState == 1 and xyd.models.oldSchool:getAllInfo().max_score < needPoint then
					isLock = true
				end

				if isLock == false then
					if isChoose == true then
						self.parent:choiceBuff(buff_id)
					else
						self.parent:choiceRemoveBuff(buff_id)
					end
				else
					xyd.WindowManager.get():openWindow("activity_explore_old_campus_ways_alert_window", {
						buff_id = buff_id,
						posy = posy
					})
				end
			end,
			posTransform = self.parent.window_.transform,
			win = xyd.WindowManager.get():getWindow("activity_explore_campus_fight_window")
		}
		local skillIcon = skillIconSmall.new(self.iconGroup.gameObject)

		skillIcon:setInfo(finalBuffArr[i].buff_id, params)

		local arrInfo = {
			icon = skillIcon,
			id = finalBuffArr[i].buff_id
		}

		table.insert(self.buffsItemArr, arrInfo)
	end

	self.iconGroup:Reposition()
end

function BuffsItem:updateItemBuffs()
	for i, value in pairs(self.buffsItemArr) do
		local isLock = false
		local buffTable = xyd.tables.oldBuildingBuffTable
		local lockState = buffTable:needUnlock(tonumber(self.buffsItemArr[i].id))
		local needPoint = buffTable:getUnlockCost(tonumber(self.buffsItemArr[i].id))[1]

		if lockState and lockState == 1 and xyd.models.oldSchool:getAllInfo().max_score < needPoint then
			isLock = true
		end

		if isLock == true then
			value.icon:setLock(true)
		else
			value.icon:setLock(false)
		end

		value.icon:setTipsClickOpen(true)
	end

	if FIRST_SET_LOCAL_BUFFS <= #xyd.tables.oldBuildingBuffTable:getAllTypeBuffs() then
		if LOCAL_BUFFS then
			for i, value in pairs(self.buffsItemArr) do
				if xyd.arrayIndexOf(LOCAL_BUFFS, self.buffsItemArr[i].id) > 0 then
					self.buffsItemArr[i].icon:tipsOnClick()
				end
			end
		end

		FIRST_SET_LOCAL_BUFFS = FIRST_SET_LOCAL_BUFFS + 1
	end
end

function BuffsItem:setLineShow(visible)
	self.blue_line:SetActive(visible)
end

function BuffsItem:removeAllClick()
	for i, value in pairs(self.buffsItemArr) do
		if xyd.arrayIndexOf(self.parent.choiceBuffArr, self.buffsItemArr[i].id) > 0 then
			self.buffsItemArr[i].icon:tipsOnClick()
		end
	end
end

function BuffsItem:selectAllClick()
	for i, value in pairs(self.buffsItemArr) do
		if xyd.arrayIndexOf(self.parent.choiceBuffArr, self.buffsItemArr[i].id) <= 0 and not self.buffsItemArr[i].icon.isLock then
			self.buffsItemArr[i].icon:tipsOnClick()
		end
	end
end

return ActivityExploreCampusFightWindow
