local ActivityMonthlyHike = class("ActivityMonthlyHike", import(".ActivityContent"))
local StageItem = class("StageItem", import("app.components.CopyComponent"))
local ItemIcon = import("app.components.ItemIcon")
local HeroIcon = import("app.components.HeroIcon")
local CountDown = import("app.components.CountDown")
local BattleCreateReport = import("lib.battle.BattleCreateReport")
local ReportHero = import("lib.battle.ReportHero")
local ReportPet = import("lib.battle.ReportPet")

function StageItem:ctor(go, parent)
	self.parent_ = parent

	StageItem.super.ctor(self, go)
	self:getUIComponent()
end

function StageItem:getUIComponent()
	self.bgImg = self.go:ComponentByName("bgImg", typeof(UISprite))
	self.nameLabel = self.go:ComponentByName("nameLabel", typeof(UILabel))
	self.finishImg = self.go:NodeByName("finishImg").gameObject
	self.nowStageImg = self.go:NodeByName("nowStageImg").gameObject
	UIEventListener.Get(self.bgImg.gameObject).onClick = handler(self, self.onClick)
end

function StageItem:setInfo(stageID)
	self.stageID = stageID
	self.stageNow = self.parent_:getStageNow()
	self.stageShow = self.parent_:getStageNow()
	local chapterID = xyd.tables.activityMonthlyStageTable:getChapter(self.stageID)
	local stageIndex = xyd.arrayIndexOf(xyd.tables.activityMonthlyChapterTable:getStageIDs(chapterID), self.stageID)
	self.nameLabel.text = chapterID .. "-" .. stageIndex

	if self.stageNow > 0 or self.stageNow <= 0 and chapterID <= 5 then
		if self.stageID == self.stageNow then
			xyd.setUISpriteAsync(self.bgImg, nil, "monthly_stage_btn1")
			self.nowStageImg:SetActive(true)
			self.finishImg:SetActive(false)
		elseif self.stageNow < self.stageID then
			xyd.setUISpriteAsync(self.bgImg, nil, "monthly_stage_btn2")
			self.nowStageImg:SetActive(false)
			self.finishImg:SetActive(false)
		else
			xyd.setUISpriteAsync(self.bgImg, nil, "monthly_stage_btn3")
			self.nowStageImg:SetActive(false)
			self.finishImg:SetActive(true)
		end
	elseif self.stageID == self.stageShow then
		xyd.setUISpriteAsync(self.bgImg, nil, "monthly_stage_btn1")
		self.nowStageImg:SetActive(true)
		self.finishImg:SetActive(false)
	else
		xyd.setUISpriteAsync(self.bgImg, nil, "monthly_stage_btn2")
		self.nowStageImg:SetActive(false)
		self.finishImg:SetActive(false)
	end
end

function StageItem:changeStageShow(showID)
	self.stageShow = showID
	self.stageNow = self.parent_:getStageNow()
	local chapterID = xyd.tables.activityMonthlyStageTable:getChapter(self.stageID)

	if self.stageNow > 0 or self.stageNow <= 0 and chapterID <= 5 then
		if self.stageID == self.stageNow then
			xyd.setUISpriteAsync(self.bgImg, nil, "monthly_stage_btn1")
			self.nowStageImg:SetActive(true)
			self.finishImg:SetActive(false)
		elseif self.stageNow < self.stageID then
			xyd.setUISpriteAsync(self.bgImg, nil, "monthly_stage_btn2")
			self.nowStageImg:SetActive(false)
			self.finishImg:SetActive(false)
		else
			xyd.setUISpriteAsync(self.bgImg, nil, "monthly_stage_btn3")
			self.nowStageImg:SetActive(false)
			self.finishImg:SetActive(true)
		end
	elseif self.stageID == self.stageShow then
		xyd.setUISpriteAsync(self.bgImg, nil, "monthly_stage_btn1")
		self.nowStageImg:SetActive(true)
		self.finishImg:SetActive(false)
	else
		xyd.setUISpriteAsync(self.bgImg, nil, "monthly_stage_btn2")
		self.nowStageImg:SetActive(false)
		self.finishImg:SetActive(false)
	end
end

function StageItem:onClick()
	self.parent_:jumpToStage(self.stageID)
end

function ActivityMonthlyHike:ctor(parentGO, params, parent)
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.MONTHLY_HIKE)
	self.stageID = self:getStageNow()

	if self.stageID < 0 then
		self.stageID = 51
	end

	self.chapterID = xyd.tables.activityMonthlyStageTable:getChapter(self.stageID)
	self.stageList = {}
	self.heroList = {}
	self.chapterLineList = {}

	ActivityMonthlyHike.super.ctor(self, parentGO, params, parent)
end

function ActivityMonthlyHike:getPrefabPath()
	return "Prefabs/Windows/activity/activity_monthly_hike"
end

function ActivityMonthlyHike:initUI()
	ActivityMonthlyHike.super.initUI(self)
	self:getUIComponent()
	self:updatePos()
	self:layout()
end

function ActivityMonthlyHike:updatePos()
	local realHeight = xyd.Global.getRealHeight()

	self.enemyGroup.transform:Y(-362 - 0.9606741573033708 * (realHeight - 1280))
	self.pageBtnLeft.transform:Y(-220 - 0.6179775280898876 * (realHeight - 1280))
	self.pageBtnRight.transform:Y(-220 - 0.6179775280898876 * (realHeight - 1280))
	self.stageGroup.transform:Y(-140 - 0.6741573033707865 * (realHeight - 1280))
	self.pointGroup.transform:Y(-350 - 0.7865168539325843 * (realHeight - 1280))
end

function ActivityMonthlyHike:getUIComponent()
	local goTrans = self.go.transform
	self.helpBtn = goTrans:NodeByName("topGroup/btnGroup/helpBtn").gameObject
	self.skillBtn = goTrans:NodeByName("topGroup/btnGroup/skillBtn").gameObject
	self.timeLabel_ = goTrans:ComponentByName("topGroup/btnGroup/timeLabel", typeof(UILabel))
	self.costNumberLabel = goTrans:ComponentByName("topGroup/btnGroup/leftUpCon/numberLabel", typeof(UILabel))
	self.addBtn = goTrans:NodeByName("topGroup/btnGroup/leftUpCon/addBtn").gameObject
	self.mapBg = goTrans:ComponentByName("topGroup/mapBg", typeof(UITexture))
	self.pointGroup = goTrans:ComponentByName("topGroup/pointGroup", typeof(UILayout))
	self.dotIcon = goTrans:NodeByName("topGroup/dotIcon").gameObject
	self.stageItem = goTrans:NodeByName("stageItem").gameObject
	self.stageGroup = goTrans:NodeByName("stageGroup")

	for i = 1, 4 do
		self["stagePosList" .. i] = self.stageGroup:NodeByName("stageGroup" .. i).gameObject
	end

	self.lineImg = self.stageGroup:ComponentByName("lineImg", typeof(UISprite))
	self.enemyGroup = goTrans:NodeByName("enemyGroup")
	self.titleLabel = self.enemyGroup:ComponentByName("titleLabel", typeof(UILabel))
	self.enemyList = self.enemyGroup:ComponentByName("enemyList", typeof(UILayout))
	self.progress = self.enemyGroup:ComponentByName("progress", typeof(UIProgressBar))
	self.progressLabel = self.enemyGroup:ComponentByName("progress/labelHp", typeof(UILabel))
	self.awardLabel = self.enemyGroup:ComponentByName("groupReward/labelText", typeof(UILabel))
	self.rewardItem = self.enemyGroup:ComponentByName("rewardItem", typeof(UILayout))
	self.awardScrollView = self.enemyGroup:ComponentByName("awardScrollView", typeof(UIScrollView))
	self.rewardItem2 = self.enemyGroup:ComponentByName("awardScrollView/rewardItem", typeof(UILayout))
	self.btnFight = self.enemyGroup:NodeByName("btnFight").gameObject
	self.btnFightLabel = self.enemyGroup:ComponentByName("btnFight/label", typeof(UILabel))
	self.btnSweeep = self.enemyGroup:NodeByName("btnClear").gameObject
	self.btnClearLabel = self.enemyGroup:ComponentByName("btnClear/label", typeof(UILabel))
	self.pageBtnLeft = goTrans:ComponentByName("pageBtnLeft", typeof(UISprite))
	self.pageBtnRight = goTrans:ComponentByName("pageBtnRight", typeof(UISprite))
end

function ActivityMonthlyHike:initPointGroup()
	self.pointList = {}

	self.dotIcon:SetActive(false)

	for i = 1, 6 do
		local dotItemNew = NGUITools.AddChild(self.pointGroup.gameObject, self.dotIcon)

		UIEventListener.Get(dotItemNew).onClick = function ()
			local chapterID = i
			local stageIDs = xyd.tables.activityMonthlyChapterTable:getStageIDs(chapterID)

			self:jumpToStage(stageIDs[1])
			self:initStageList()

			if self.stageList[self.chapterID] and self.stageList[self.chapterID][self.stageID] then
				self.stageList[self.chapterID][self.stageID]:changeStageShow(self.stageID)
			end

			self:updateMap()
		end

		local dotImg = dotItemNew:GetComponent(typeof(UISprite))
		self.pointList[i] = dotImg
	end
end

function ActivityMonthlyHike:updateDotList()
	for i = 1, 6 do
		local dotImg = self.pointList[i]

		if i ~= self.chapterID then
			xyd.setUISpriteAsync(dotImg, nil, "market_dot_bg1", nil, )
		else
			xyd.setUISpriteAsync(dotImg, nil, "market_dot_bg2", nil, )
		end

		dotImg.width = 20
		dotImg.height = 20
	end
end

function ActivityMonthlyHike:updateItemNum()
	self.costNumberLabel.text = xyd.models.backpack:getItemNumByID(28)
end

function ActivityMonthlyHike:layout()
	self.btnFightLabel.text = __("FRIEND_FIGHT")
	self.btnClearLabel.text = __("FRIEND_SWEEP")

	self:initPointGroup()
	self:updateMap()
	self:initStageList()
	self:updateStageInfo()
	self:updateItemNum()

	local endTime = self.activityData:getUpdateTime()
	self.countdownEnd_ = CountDown.new(self.timeLabel_, {
		key = "ACTIVITY_END_COUNT",
		duration = endTime - xyd.getServerTime()
	})
end

function ActivityMonthlyHike:getBuyTime()
	return tonumber(xyd.tables.miscTable:getVal("activity_boss_buy_limit")) - self.activityData.detail.buy_times
end

function ActivityMonthlyHike:onRegister()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_MONTHLY_HIKE_HELP"
		})
	end

	UIEventListener.Get(self.btnFight.gameObject).onClick = handler(self, self.onFightTouch)
	UIEventListener.Get(self.btnSweeep.gameObject).onClick = handler(self, self.onSweepTouch)

	UIEventListener.Get(self.addBtn).onClick = function ()
		if self:getBuyTime() <= 0 then
			xyd.showToast(__("ACTIVITY_WORLD_BOSS_LIMIT"))

			return
		end

		local data = xyd.tables.miscTable:split2Cost("activity_boss_buy_cost", "value", "#")

		xyd.WindowManager.get():openWindow("limit_purchase_item_window", {
			limitKey = "ACTIVITY_WORLD_BOSS_LIMIT",
			notEnoughKey = "PERSON_NO_CRYSTAL",
			needTips = true,
			buyNum = 1,
			buyType = 28,
			titleKey = "WORLD_BOSS_BUY_TITLE",
			costType = data[1],
			costNum = data[2],
			purchaseCallback = function (evt, num)
				xyd.alertYesNo(__("ACTIVITY_MONTHLY_TEXT009", data[2] * num), function (yes)
					if yes then
						local msg = messages_pb:boss_buy_req()
						msg.activity_id = self.id
						msg.num = num

						xyd.Backend.get():request(xyd.mid.BOSS_BUY, msg)
					end
				end)
			end,
			limitNum = self:getBuyTime(),
			eventType = xyd.event.BOSS_BUY,
			showWindowCallback = function ()
				xyd.WindowManager.get():openWindow("vip_window")
			end
		})
	end

	UIEventListener.Get(self.pageBtnLeft.gameObject).onClick = function ()
		self:changeChapter(-1)
	end

	UIEventListener.Get(self.pageBtnRight.gameObject).onClick = function ()
		self:changeChapter(1)
	end

	self.eventProxyInner_:addEventListener(xyd.event.BOSS_BUY, function (evt)
		self.activityData.detail.buy_times = evt.data.buy_times

		self:updateItemNum()
	end)

	UIEventListener.Get(self.skillBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_monthly_hike_skill_window", {})
	end

	self.eventProxyInner_:addEventListener(xyd.event.BOSS_NEW_FIGHT, handler(self, self.onBossFight))
	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function ActivityMonthlyHike:setTempSweepInfo(params)
	self.tempBattleData_ = params
end

function ActivityMonthlyHike:getTempBattleData()
	return self.tempBattleData_
end

function ActivityMonthlyHike:clearTempBattleData()
	self.tempBattleData_ = nil
end

function ActivityMonthlyHike:onBossFight()
	self:updateItemNum()

	local hasFinish = self:getHasFinish()

	self:updateHpProgress(hasFinish)
end

function ActivityMonthlyHike:onAward(event)
	local detail = require("cjson").decode(event.data.detail)

	if self.activityData.detail.needFakeBattle then
		self:playFakeBattleReport(self.stageID, detail.items)

		self.activityData.detail.needFakeBattle = false
	else
		xyd.alertItems(detail.items)
	end

	self:updateItemNum()
end

function ActivityMonthlyHike:playFakeBattleReport(stage_id, items)
	local dbValA = xyd.db.formation:getValue(xyd.BattleType.WORLD_BOSS)
	local dataA = require("cjson").decode(dbValA)
	local herosA = {}
	local herosB = {}

	for k, v in ipairs(dataA.partners) do
		local partnerId = tonumber(v)

		if partnerId and partnerId ~= 0 then
			local hero = self:getReportHeroByPartnerId(partnerId, k)

			table.insert(herosA, hero)
		end
	end

	local petA = self:getReportPetById(dataA.pet_id)
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.MONTHLY_HIKE)
	local skillLevs = activityData:getActivityInfo()
	local god_skills = {}

	for i = 1, #skillLevs do
		if skillLevs[i] and skillLevs[i] > 0 then
			local skillID = xyd.tables.activityMonthlySkillTable:getSkillList(i)[skillLevs[i]]

			table.insert(god_skills, skillID)
		end
	end

	local battle_id = xyd.tables.activityMonthlyStageTable:getBattleID(stage_id)
	local str = xyd.tables.battleTable:getMonsters(battle_id)

	if not str or #str <= 0 then
		return
	end

	local poss = xyd.tables.battleTable:getStands(battle_id)

	for i = 1, #str do
		local hero = ReportHero.new()

		hero:populateWithTableID(str[i], {
			pos = poss[i]
		})
		table.insert(herosB, hero)
	end

	local params = {
		battleID = 1,
		maxRound = 15,
		herosA = herosA,
		herosB = herosB,
		petA = petA,
		guildSkillsA = xyd.models.guild:getGuildSkills(),
		guildSkillsB = {},
		god_skills = god_skills,
		random_seed = math.random(1, 10000)
	}
	local reporter = BattleCreateReport.new(params)

	reporter:run()

	local params2 = {
		event_data = {},
		battle_type = xyd.BattleType.WORLD_BOSS
	}
	params2.event_data.battle_report = reporter:getReport()
	params2.event_data.items = items
	params2.event_data.is_fake = true
	params2.event_data.is_win = 1
	local hurts = params2.event_data.battle_report.hurts
	local total_harm = 0

	for _, hurt_info in pairs(hurts) do
		if hurt_info.pos <= 6 then
			total_harm = total_harm + hurt_info.hurt
		end
	end

	params2.event_data.total_harm = total_harm

	xyd.BattleController.get():startBattle(params2)
end

function ActivityMonthlyHike:getReportHeroByPartnerId(partnerId, pos)
	local partner = xyd.models.slot:getPartner(partnerId)
	local info = partner:getInfo()
	local hero = ReportHero.new()
	info.table_id = partner.tableID
	info.level = partner.lev
	info.show_skin = partner:isShowSkin()
	info.equips = partner.equipments
	info.love_point = partner.lovePoint
	info.is_vowed = partner:getIsVoewed()
	info.pos = pos
	info.potentials = {}

	for i = 1, #partner:getPotential() do
		info.potentials[i] = partner:getPotential()[i]
	end

	hero:populate(info)

	return hero
end

function ActivityMonthlyHike:getReportPetById(id)
	if id == 0 then
		return
	end

	local petInfo = xyd.models.petSlot:getPetByID(id)
	local pet = ReportPet.new()
	local skills = {}

	for i = 1, 4 do
		skills[i] = petInfo.skills[i]
	end

	pet:populate({
		pet_id = id,
		grade = petInfo.grade,
		lv = petInfo.lev,
		skills = skills,
		ex_lv = petInfo.ex_lv
	})

	return pet
end

function ActivityMonthlyHike:updateMap()
	local mapID = xyd.tables.activityMonthlyChapterTable:getMapID(self.chapterID)
	local lineID = xyd.tables.activityMonthlyChapterTable:getLineID(self.chapterID)
	local linePos = {
		{
			10,
			10
		},
		{
			10,
			-10
		},
		{
			-5,
			18
		}
	}

	xyd.setUITextureByNameAsync(self.mapBg, "monthly_stage_map_" .. mapID, true)

	if lineID ~= 4 then
		self.lineImg.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.lineImg, nil, "monthly_stage_line_bg" .. lineID, nil, , true)
		self.lineImg.transform:X(linePos[lineID][1])
		self.lineImg.transform:Y(linePos[lineID][2])
	else
		self.lineImg.gameObject:SetActive(false)
	end

	self:updateDotList()
end

function ActivityMonthlyHike:onFightTouch()
	if not self:checkCanFight() then
		xyd.alertTips(__("ACTIVITY_MONTHLY_TEXT002"))

		return
	end

	if xyd.models.backpack:getItemNumByID(28) <= 0 then
		xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(28)))

		return
	end

	local fightParams = {
		activity_id = xyd.ActivityID.MONTHLY_HIKE,
		battleType = xyd.BattleType.WORLD_BOSS
	}

	if self.chapterID > 5 then
		fightParams.stage_id = self.stageID
	end

	xyd.WindowManager.get():openWindow("battle_formation_window", fightParams)
end

function ActivityMonthlyHike:onSweepTouch()
	if not self:checkCanFight() then
		xyd.alertTips(__("ACTIVITY_MONTHLY_TEXT002"))

		return
	end

	if xyd.models.backpack:getItemNumByID(28) <= 0 then
		xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(28)))

		return
	end

	local fightParams = {
		activity_id = xyd.ActivityID.MONTHLY_HIKE,
		battleType = xyd.BattleType.WORLD_BOSS
	}

	if self.chapterID > 5 then
		fightParams.stage_id = self.stageID
	end

	xyd.WindowManager.get():openWindow("activity_world_boss_sweep_window", fightParams)
end

function ActivityMonthlyHike:checkCanFight()
	if self:getStageNow() < 0 then
		return true
	elseif self:getStageNow() ~= self.stageID then
		return false
	end

	return true
end

function ActivityMonthlyHike:updatePageBtn()
	local ids = xyd.tables.activityMonthlyChapterTable:getIDs()
	local len = #ids

	if len <= self.chapterID then
		xyd.setUISpriteAsync(self.pageBtnLeft, nil, "partner_detail_arrow")
		xyd.setUISpriteAsync(self.pageBtnRight, nil, "partner_detail_arrow_grey")

		self.pageBtnRight.transform:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		self.pageBtnLeft.transform:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	elseif self.chapterID <= 1 then
		xyd.setUISpriteAsync(self.pageBtnRight, nil, "partner_detail_arrow")
		xyd.setUISpriteAsync(self.pageBtnLeft, nil, "partner_detail_arrow_grey")

		self.pageBtnRight.transform:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		self.pageBtnLeft.transform:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	else
		xyd.setUISpriteAsync(self.pageBtnRight, nil, "partner_detail_arrow")
		xyd.setUISpriteAsync(self.pageBtnLeft, nil, "partner_detail_arrow")

		self.pageBtnRight.transform:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		self.pageBtnLeft.transform:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end
end

function ActivityMonthlyHike:getStageNow()
	return self.activityData.detail.cur_stage_id
end

function ActivityMonthlyHike:initStageList()
	if not self.stageList[self.chapterID] then
		local stageIDs = xyd.tables.activityMonthlyChapterTable:getStageIDs(self.chapterID)
		local lineID = xyd.tables.activityMonthlyChapterTable:getLineID(self.chapterID)
		self.stageList[self.chapterID] = {}
		local uiRoot = NGUITools.AddChild(self.stageGroup.gameObject, self["stagePosList" .. lineID].gameObject)
		self.chapterLineList[self.chapterID] = uiRoot

		if lineID == 4 then
			uiRoot.transform:X(-350)
		end

		for index, id in ipairs(stageIDs) do
			local posItem = uiRoot:NodeByName("pos" .. index).gameObject
			local newStagePos = NGUITools.AddChild(posItem, self.stageItem)

			newStagePos:SetActive(true)

			local newStageItem = StageItem.new(newStagePos, self)

			newStageItem:setInfo(id)

			self.stageList[self.chapterID][id] = newStageItem
		end
	end

	for i = 1, 6 do
		if self.chapterLineList[i] then
			if i == self.chapterID then
				self.chapterLineList[i]:SetActive(true)
			else
				self.chapterLineList[i]:SetActive(false)
			end
		end
	end
end

function ActivityMonthlyHike:updateStageInfo()
	self.awardLabel.text = __("ACTIVITY_BEACH_ISLAND_TEXT06")

	if self.chapterID > 5 then
		self.awardLabel.text = __("ACTIVITY_MONTHLY_TEXT001")
	end

	local stageIndex = xyd.arrayIndexOf(xyd.tables.activityMonthlyChapterTable:getStageIDs(self.chapterID), self.stageID)
	self.titleLabel.text = __("STAGE_NAME", self.chapterID, stageIndex)
	local battle_id = xyd.tables.activityMonthlyStageTable:getBattleID(self.stageID)
	local monsters = xyd.tables.battleTable:getMonsters(battle_id)

	for i = 1, #monsters do
		local tableID = monsters[i]
		local id = xyd.tables.monsterTable:getPartnerLink(tableID)
		local itemID = xyd.tables.monsterTable:getSkin(tableID)
		local lev = xyd.tables.monsterTable:getShowLev(tableID)

		if not self.heroList[i] then
			local icon = HeroIcon.new(self.enemyList.gameObject)

			icon:setInfo({
				is_monster = true,
				noClick = true,
				tableID = id,
				lev = lev,
				skin_id = itemID
			})

			local scale = 0.9074074074074074

			icon.go:SetLocalScale(scale, scale, scale)

			self.heroList[i] = icon
		else
			self.heroList[i]:setInfo({
				is_monster = true,
				noClick = true,
				tableID = id,
				lev = lev,
				skin_id = itemID
			})
		end
	end

	for i = 1, #self.heroList do
		if self.heroList[i] then
			self.heroList[i]:SetActive(i <= #monsters)
		end
	end

	self.enemyList:Reposition()

	local hasFinish = self:getHasFinish()
	local rewards = xyd.tables.activityMonthlyStageTable:getBattleAwards(self.stageID)
	local skillPoint = xyd.tables.activityMonthlyStageTable:getSkillPoint(self.stageID)

	table.insert(rewards, {
		290,
		skillPoint
	})
	NGUITools.DestroyChildren(self.rewardItem.transform)
	NGUITools.DestroyChildren(self.rewardItem2.transform)

	if self.chapterID < 6 then
		self:waitForFrame(1, function ()
			if #rewards < 6 then
				self.awardScrollView.gameObject:SetActive(false)

				for i = 1, #rewards do
					local tableID = rewards[i][1]
					local num = rewards[i][2]
					local params = {
						notShowGetWayBtn = true,
						scale = 0.9074074074074074,
						itemID = tableID,
						num = num,
						uiRoot = self.rewardItem.gameObject
					}
					local icon = xyd.getItemIcon(params)

					icon:setChoose(hasFinish > 0)
				end

				self.rewardItem:Reposition()
			else
				self.awardScrollView.gameObject:SetActive(true)
				self:waitForFrame(1, function ()
					for i = 1, #rewards do
						local tableID = rewards[i][1]
						local num = rewards[i][2]
						local params = {
							notShowGetWayBtn = true,
							scale = 0.9074074074074074,
							itemID = tableID,
							num = num,
							uiRoot = self.rewardItem2.gameObject,
							dragScrollView = self.awardScrollView
						}
						local icon = xyd.getItemIcon(params)

						icon:setChoose(hasFinish > 0)
					end

					self.rewardItem2:Reposition()
					self.awardScrollView:ResetPosition()
				end)
			end
		end)
	else
		local rewards = xyd.tables.miscTable:split2Cost("activity_monthly_stage6", "value", "|#")[stageIndex]

		self:waitForFrame(1, function ()
			for i = 1, #rewards do
				local tableID = rewards[i]
				local params = {
					scale = 0.9074074074074074,
					notShowGetWayBtn = true,
					itemID = tableID,
					uiRoot = self.rewardItem.gameObject
				}
				local icon = xyd.getItemIcon(params)

				icon:setChoose(hasFinish > 0)
			end

			self.rewardItem:Reposition()
		end)
	end

	self.btnFight:SetActive(hasFinish <= 0)
	self.btnSweeep:SetActive(hasFinish <= 0)
	self:updateHpProgress(hasFinish)
	self:updatePageBtn()

	if self.stageList[self.chapterID] and self.stageList[self.chapterID][self.stageID] then
		self.stageList[self.chapterID][self.stageID]:changeStageShow(self.stageID)
	end
end

function ActivityMonthlyHike:onNextStage()
	local changeStageID = self:getStageNow()

	if changeStageID == -1 then
		changeStageID = 51
	end

	self.stageList[self.chapterID][self.stageID]:changeStageShow(changeStageID)

	self.stageID = changeStageID
	self.chapterID = xyd.tables.activityMonthlyStageTable:getChapter(self.stageID)

	self:updateStageInfo()
	self:initStageList()
	self:updateMap()
end

function ActivityMonthlyHike:updateStageItem()
	for i = 1, 6 do
		if self.chapterLineList[i] then
			local stageIDs = xyd.tables.activityMonthlyChapterTable:getStageIDs(i)

			if i == self.chapterID then
				self.chapterLineList[i]:SetActive(true)
			else
				self.chapterLineList[i]:SetActive(false)
			end

			for index, id in ipairs(stageIDs) do
				self.stageList[i][id]:setInfo(id)
			end
		end
	end
end

function ActivityMonthlyHike:getHasFinish()
	local isFinish = 0

	if self:getStageNow() > 0 then
		if self.stageID < self:getStageNow() then
			isFinish = 1
		elseif self:getStageNow() < self.stageID then
			isFinish = -1
		end
	elseif self.chapterID <= 5 then
		isFinish = 1
	else
		isFinish = -2
	end

	return isFinish
end

function ActivityMonthlyHike:updateHpProgress(hasFinish)
	local hp = self.activityData:getBossHp()

	if hasFinish > 0 then
		hp = 0
	elseif hasFinish < 0 then
		hp = 1
	end

	self.progress.value = hp
	self.progressLabel.text = math.ceil(hp * 100) .. "%"

	if hasFinish <= -2 then
		self.progressLabel.text = "∞"
		self.progressLabel.fontSize = 30
	else
		self.progressLabel.fontSize = 20
	end
end

function ActivityMonthlyHike:jumpToStage(stage_id)
	self.stageList[self.chapterID][self.stageID]:changeStageShow(stage_id)

	self.stageID = stage_id
	self.chapterID = xyd.tables.activityMonthlyStageTable:getChapter(self.stageID)

	self:updateStageInfo()
end

function ActivityMonthlyHike:changeChapter(change_num)
	local ids = xyd.tables.activityMonthlyChapterTable:getIDs()
	local len = #ids

	if len < self.chapterID + change_num then
		return
	elseif self.chapterID + change_num < 1 then
		return
	end

	local chapterID = self.chapterID + change_num
	local stageIDs = xyd.tables.activityMonthlyChapterTable:getStageIDs(chapterID)

	self:jumpToStage(stageIDs[1])
	self:initStageList()
	self.stageList[self.chapterID][self.stageID]:changeStageShow(self.stageID)
	self:updateMap()
end

function ActivityMonthlyHike:onSweepBoss(data)
	if data.is_win == 1 then
		local curID = self.activityData.detail.cur_stage_id

		if self.activityData.detail.cur_stage_id > 0 then
			xyd.showToast(__("WORLD_BOSS_KILL"))

			self.activityData.detail.cur_stage_id = xyd.tables.activityMonthlyStageTable:getNextID(curID)
			self.activityData.detail.skill_point = self.activityData.detail.skill_point + xyd.tables.activityMonthlyStageTable:getSkillPoint(curID)
		end
	end

	self.selectState_ = tonumber(xyd.db.misc:getValue("activity_monthly_hike_sweep_next"))

	if data.items then
		local params = {
			items = data.items,
			harm = data.total_harm,
			stageID = self.stageID,
			useNum = data.times_count
		}
		local win = xyd.WindowManager.get():getWindow("activity_monthly_hike_award_window2")

		if self.selectState_ == 1 and (data.is_win == 1 or win) then
			if not win then
				xyd.WindowManager.get():openWindow("activity_monthly_hike_award_window2", params)
			else
				win:addNewItem(params)
			end
		else
			xyd.WindowManager.get():openWindow("activity_monthly_hike_award_window", params)
		end
	end

	self.stageID = self:getStageNow()

	if self.stageID < 0 then
		self.stageID = 51
	end

	self.chapterID = xyd.tables.activityMonthlyStageTable:getChapter(self.stageID)

	self:initStageList()
	self:updateStageItem()
	self:updateStageInfo()
	self:updateMap()
end

return ActivityMonthlyHike
