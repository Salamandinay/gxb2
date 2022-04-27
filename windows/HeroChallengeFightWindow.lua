local BaseWindow = import(".BaseWindow")
local HeroChallengeFightWindow = class("HeroChallengeFightWindow", BaseWindow)
local HeroChallengeFightBossItem = import("app.components.HeroChallengeFightBossItem")

function HeroChallengeFightWindow:ctor(name, params)
	HeroChallengeFightWindow.super.ctor(self, name, params)

	self.skinName = "HeroChallengeFightWindowSkin"
	self.id = params.id
	self.fortId = params.fortId

	if xyd.tables.partnerChallengeChessTable:getFortType(self.fortId) == xyd.HeroChallengeFort.CHESS then
		self.FortTable = xyd.tables.partnerChallengeChessTable
	else
		self.FortTable = xyd.tables.partnerChallengeTable
	end
end

function HeroChallengeFightWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function HeroChallengeFightWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("content").gameObject
	self.content = content
	self.bg = content:ComponentByName("bg", typeof(UISprite))

	xyd.setUISpriteAsync(self.bg, nil, "h_challenge_fight_bg")

	self.closeBtn = content:NodeByName("closeBtn").gameObject
	self.labelTitle_ = content:ComponentByName("labelTitle_", typeof(UILabel))
	self.btnVideo = content:NodeByName("btnVideo").gameObject
	self.btnCheck = content:NodeByName("btnCheck").gameObject
	self.labelAward_ = content:ComponentByName("awardTitle/labelAward_", typeof(UILabel))
	self.groupItems = content:NodeByName("groupItems").gameObject
	self.btnBattle = content:NodeByName("btnBattle").gameObject
	self.btnBattleLabel = self.btnBattle:ComponentByName("button_label", typeof(UILabel))
	self.labelDesc_ = content:ComponentByName("container/scroller/labelDesc_", typeof(UILabel))
	self.midContainer = content:NodeByName("midContainer").gameObject
	self.midTitle = self.midContainer:NodeByName("midTitle").gameObject
	self.bossEffectNode = self.midContainer:NodeByName("bossEffectNode").gameObject
	self.midTitleWords = self.midTitle:ComponentByName("midTitleWords", typeof(UILabel))
	self.midFuTile = self.midContainer:NodeByName("midFuTile").gameObject
	self.titleIcon = self.midFuTile:ComponentByName("titleIcon", typeof(UISprite))
	self.midFuTitleWords = self.midFuTile:ComponentByName("midFuTitleWords", typeof(UILabel))
	self.midDesc = self.midContainer:ComponentByName("midScroller/midDesc", typeof(UILabel))
	self.finishImg = self.midContainer:ComponentByName("finishImg", typeof(UISprite))
	self.topDesWords = content:ComponentByName("topDesWords", typeof(UILabel))
	self.container = content:NodeByName("container").gameObject
	self.awardTitle = content:NodeByName("awardTitle").gameObject
end

function HeroChallengeFightWindow:layout()
	self.labelTitle_.text = self.FortTable:name(self.id)
	self.labelDesc_.text = self.FortTable:description(self.id)
	self.labelAward_.text = __("TOWER_TEXT02")
	self.btnBattleLabel.text = __("FIGHT3")
	self.midFuTitleWords.text = __("PARTNER_CHALLENGE_CHESS_TEXT02")
	local fortId = self.FortTable:getFortID(self.id)
	local info = xyd.models.heroChallenge:getFortInfoByFortID(fortId)
	local isGet = false

	if info and info.base_info and self.id <= info.base_info.fight_max_stage then
		isGet = true
	end

	local items = self.FortTable:getReward1(self.id)

	for _, item in pairs(items) do
		local icon = xyd.getItemIcon({
			itemID = item[1],
			num = item[2],
			uiRoot = self.groupItems
		})

		icon:setScale(96 / xyd.DEFAULT_ITEM_SIZE)
		icon:setChoose(isGet)
	end

	local isChess = xyd.tables.partnerChallengeChessTable:getFortType(fortId) == xyd.HeroChallengeFort.CHESS
	local isPuzzle = self.FortTable:isPuzzle(self.id)

	if isChess or isPuzzle then
		self.btnCheck:SetActive(true)
		self.btnVideo:SetActive(false)
	else
		self.btnCheck:SetActive(false)
		self.btnVideo:SetActive(true)
	end

	self:setMidContentPos()
end

function HeroChallengeFightWindow:setMidContentPos()
	local isShowMid = false

	self.finishImg:SetActive(false)

	if xyd.tables.partnerChallengeChessTable:getFortType(self.fortId) == xyd.HeroChallengeFort.CHESS then
		if self.FortTable:getBattleTarget(self.id) ~= 0 then
			self:updateFinishImg()

			self.midTitleWords.text = __("PARTNER_CHALLENGE_CHESS_TEXT01")
			self.topDesWords.text = __("PARTNER_CHALLENGE_CHESS_TEXT05")
			local paramsNum = xyd.tables.battleChallengeTable:getParams(self.FortTable:getBattleTarget(self.id))
			self.midDesc.text = xyd.tables.partnerChallangeTargetTextTable:getDescByName(self.id, paramsNum)
			isShowMid = true
		elseif #self.FortTable:getBattleBuff(self.id) > 0 then
			self.midTitleWords.text = __("PARTNER_CHALLENGE_CHESS_TEXT03")
			self.topDesWords.text = __("PARTNER_CHALLENGE_CHESS_TEXT04")

			self:initBossItems()
			self.midFuTile:SetActive(false)
			self.midContainer:SetActive(true)
			self.midDesc:SetActive(false)

			isShowMid = true
		else
			self.midContainer:SetActive(false)
		end
	else
		self.midContainer:SetActive(false)
	end

	if isShowMid then
		self.topDesWords:SetActive(true)
		self.btnBattle:Y(-297)
		self.groupItems:Y(-187)
		self.awardTitle:Y(-94)

		self.container:GetComponent(typeof(UIWidget)).height = 110

		xyd.setUISpriteAsync(self.finishImg, nil, "academy_assessment_done_" .. xyd.Global.lang, nil, , false)
	else
		self.topDesWords:SetActive(false)
	end
end

function HeroChallengeFightWindow:updateFinishImg()
	self.finishImg:SetActive(false)

	local conditions = xyd.models.heroChallenge:getConditions(self.fortId)

	if conditions then
		for k, v in ipairs(conditions) do
			if v == self.id then
				self.finishImg:SetActive(true)

				break
			end
		end
	end
end

function HeroChallengeFightWindow:initBossItems()
	local buffs = self.FortTable:getBattleBuff(self.id)

	for k, v in ipairs(buffs) do
		local conditions = xyd.models.heroChallenge:getConditions(self.fortId)
		local conditionsNum = 0

		if conditions then
			conditionsNum = #conditions
		end

		local isOpen = k <= conditionsNum
		local paramsData = {
			score = k,
			isOpen = isOpen,
			posTransform = self.bossEffectNode.transform,
			tipsCallBack = function (v, posy)
				xyd.WindowManager.get():openWindow("activity_explore_old_campus_ways_alert_window", {
					buff_id = v,
					posy = posy,
					index = k,
					isOpen = isOpen
				})
			end
		}
		local skillIcon = HeroChallengeFightBossItem.new(self.bossEffectNode)

		skillIcon:setInfo(v, paramsData)
	end
end

function HeroChallengeFightWindow:register()
	HeroChallengeFightWindow.super.register(self)

	UIEventListener.Get(self.btnVideo).onClick = function ()
		self:onVideoTouch()
	end

	UIEventListener.Get(self.btnCheck).onClick = function ()
		self:onCheckTouch()
	end

	UIEventListener.Get(self.btnBattle).onClick = function ()
		self:onBattleTouch()
	end
end

function HeroChallengeFightWindow:onCheckTouch()
	local battleID = self.FortTable:getBattleId(self.id)

	xyd.WindowManager.get():openWindow("enemy_team_info_window", {
		battle_id = battleID
	})
end

function HeroChallengeFightWindow:onBattleTouch()
	local isChess = xyd.tables.partnerChallengeChessTable:getFortType(self.fortId) == xyd.HeroChallengeFort.CHESS
	local ticket = xyd.models.heroChallenge:getTicket()

	if ticket <= 0 then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.HERO_CHALLENGE)))

		return
	end

	local isShowSkip = false
	local fortId = self.FortTable:getFortID(self.id)
	local isPuzzle = self.FortTable:isPuzzle(self.id)

	if isPuzzle then
		xyd.models.heroChallenge:initHeros(fortId, self.id)
	end

	local info = xyd.models.heroChallenge:getFortInfoByFortID(fortId)

	if info and info.base_info and self.id <= info.base_info.fight_max_stage then
		isShowSkip = true
	end

	local petId = 0
	local petIDs = xyd.models.heroChallenge:getPetIDs(fortId)

	if petIDs and petIDs[1] then
		petId = petIDs[1]
	end

	local fightParams = {
		mapType = xyd.MapType.HERO_CHALLENGE,
		battleID = self.id,
		fortID = fortId,
		battleType = xyd.BattleType.HERO_CHALLENGE,
		pet = petId,
		btnSkipCallback = function (flag)
			xyd.models.heroChallenge:setSkipReport(flag)
		end
	}

	if isChess then
		fightParams.battleType = xyd.BattleType.HERO_CHALLENGE_CHESS

		if xyd.models.heroChallenge:getHp(self.fortId) > 0 then
			xyd.WindowManager.get():openWindow("battle_formation_window", fightParams)
		else
			xyd.alertTips(__("CHESS_HP_NOT_ENOUGH"))
		end

		return
	end

	xyd.WindowManager.get():openWindow("battle_formation_window", fightParams)
end

function HeroChallengeFightWindow:onVideoTouch()
	xyd.WindowManager.get():openWindow("hero_challenge_video_window", {
		id = self.id
	})
end

return HeroChallengeFightWindow
