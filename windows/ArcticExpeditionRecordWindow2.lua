local ArcticExpeditionRecordWindow2 = class("ArcticExpeditionRecordWindow2", import(".BaseWindow"))
local PlayerIcon = import("app.components.PlayerIcon")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local Monster = import("app.models.Monster")
local ReportHero = import("lib.battle.ReportHero")
local ArcticExpeditionRecordItem = class("ArcticExpeditionRecordItem", import("app.components.CopyComponent"))

function ArcticExpeditionRecordItem:ctor(go, parent)
	self.parent_ = parent

	ArcticExpeditionRecordItem.super.ctor(self, go, parent)
end

function ArcticExpeditionRecordItem:initUI()
	ArcticExpeditionRecordItem.super.initUI(self)
	self:getUIComponent()
end

function ArcticExpeditionRecordItem:getUIComponent()
	local trans = self.go.transform
	self.main = trans:NodeByName("animationPos/main").gameObject
	self.bgImg = self.main:ComponentByName("bg", typeof(UITexture))
	self.matchNum = trans:ComponentByName("animationPos/title/matchNum", typeof(UILabel))
	self.video = trans:NodeByName("animationPos/title/video").gameObject
	self.detail = trans:NodeByName("animationPos/title/detail").gameObject
	self.bg = self.main:ComponentByName("bg", typeof(UITexture))
	self.resultIcon = self.main:ComponentByName("resultIcon", typeof(UISprite))
	self.resultLabel = self.main:ComponentByName("resultLabel", typeof(UILabel))
	self.resHp = self.main:ComponentByName("resHp", typeof(UIProgressBar))
	self.resHpValueImg = self.main:ComponentByName("resHp/e:image", typeof(UISprite))
	self.resHpLabel = self.main:ComponentByName("resHp/resLabel", typeof(UILabel))
	local cnt = 1
	self.groupInfo1 = self.main:NodeByName("groupInfo1").gameObject
	self.serverId = self.groupInfo1:ComponentByName("serverId1", typeof(UILabel))
	self.groupImg = self.groupInfo1:ComponentByName("groupImg", typeof(UISprite))
	self.groupInfo2 = self.main:NodeByName("groupInfo2").gameObject

	self.groupInfo2:SetActive(false)

	self.enemyName2 = self.main:ComponentByName("groupInfo2/serverId2", typeof(UILabel))
	local pIcon = self.main:NodeByName("pIcon1").gameObject
	self.pIcon1 = PlayerIcon.new(pIcon)
	self.cellImg = self.main:ComponentByName("cellImg", typeof(UISprite))
	self.pName1 = self.main:ComponentByName("pName1", typeof(UILabel))
	self.pName2 = self.main:ComponentByName("pName2", typeof(UILabel))
	self.pName2Text = self.main:ComponentByName("pName2Text", typeof(UILabel))

	for i = 1, 2 do
		local grid1 = self.main:NodeByName("grid" .. i .. "_1").gameObject
		local grid2 = self.main:NodeByName("grid" .. i .. "_2").gameObject

		for j = 1, 2 do
			local root = grid1:NodeByName("e:Group/hero" .. cnt).gameObject
			self["hero" .. cnt] = HeroIcon.new(root)

			self["hero" .. cnt]:SetActive(false)

			cnt = cnt + 1
		end

		for j = 3, 6 do
			local root = grid2:NodeByName("e:Group/hero" .. cnt).gameObject
			self["hero" .. cnt] = HeroIcon.new(root)

			self["hero" .. cnt]:SetActive(false)

			cnt = cnt + 1
		end
	end

	self.pName2Text.text = __("ARCTIC_EXPEDITION_TEXT_16")
	UIEventListener.Get(self.video).onClick = handler(self, self.onClickVideo)
	UIEventListener.Get(self.detail).onClick = handler(self, self.onClickDetail)
end

function ArcticExpeditionRecordItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)
	self:setInfo(info.report, self.parent_.cellId_, info.self_info, info.time, info.group)
end

function ArcticExpeditionRecordItem:setInfo(params, cell_id, self_info, time, group)
	self.params_ = params
	self.cellId_ = cell_id
	self.self_info = self_info
	self.cellType_ = xyd.tables.arcticExpeditionCellsTable:getCellType(self.cellId_)
	self.cellFunctionId_ = xyd.tables.arcticExpeditionCellsTypeTable:getFunctionID(self.cellType_)
	local cellImg = xyd.tables.arcticExpeditionCellsTypeTable:getIconImg(self.cellType_)
	local cellName = xyd.tables.arcticExpeditionCellsTypeTable:getCellName(self.cellType_)
	self.pName2.text = cellName

	xyd.setUISpriteAsync(self.cellImg, nil, cellImg)

	local resTime = xyd.getServerTime() - time
	local min = resTime / 60
	local hour = min / 60
	local day = hour / 24

	if day >= 1 then
		self.matchNum.text = __("DAY_BEFORE", math.floor(day))
	elseif hour >= 1 then
		self.matchNum.text = __("HOUR_BEFORE", math.floor(hour))
	elseif min >= 1 then
		self.matchNum.text = __("MIN_BEFORE", math.floor(min))
	else
		self.matchNum.text = __("SECOND_BEFORE")
	end

	local isWin = params.battle_report.isWin

	if isWin == 1 then
		self:setState(1)
		self.resHp.gameObject:SetActive(false)
		self.resultLabel.gameObject:SetActive(true)
	else
		self:setState(0)
		self.resHp.gameObject:SetActive(true)
		self.resultLabel.gameObject:SetActive(false)
	end

	self.pIcon1:setInfo(self_info)
	self.pIcon1:setScale(0.8)

	self.serverId.text = xyd.getServerNumber(self_info.server_id)
	self.pName1.text = self_info.player_name
	local teamA = params.battle_report.teamA
	local teamB = params.battle_report.teamB
	local petA = params.battle_report.petA
	local petB = params.battle_report.petB
	local petIDA = 0
	local petIDB = 0

	if petA then
		petIDA = petA.pet_id
	end

	if petB then
		petIDB = petB.pet_id
	end

	local cellGroup = params.battle_report.group

	xyd.setUISpriteAsync(self.groupImg, nil, "arctic_expedition_cell_group_icon_" .. group)

	local posA = {
		1,
		1,
		1,
		1,
		1,
		1
	}

	for i = 1, #teamA do
		local index = teamA[i].pos
		posA[teamA[i].pos] = 0
		local partner = Partner.new()

		partner:populate(teamA[i])

		local info = partner:getInfo()
		info.dragScrollView = self.parent_.scrollview_
		info.scale = 0.6

		self["hero" .. index]:setInfo(info, petIDA)
		self["hero" .. index]:setNoClick(true)
		self["hero" .. index]:SetActive(true)
	end

	for k, v in ipairs(posA) do
		if v == 1 then
			self["hero" .. k]:SetActive(false)
		end
	end

	local totalHp = 0
	local resHp = 0
	local beforeHp = 0
	xyd.Battle.godPosSkill = {}
	local posB = {
		1,
		1,
		1,
		1,
		1,
		1
	}

	for i = 1, #teamB do
		if teamB[i] then
			local index = teamB[i].pos + 6
			posB[teamB[i].pos] = 0
			local partner = Partner.new()

			if teamB[i].isMonster then
				partner = Monster.new()

				partner:populateWithTableID(teamB[i].table_id, teamB[i])
			else
				partner:populate(teamB[i])
			end

			local hero = ReportHero.new()

			hero:populateWithTableID(teamB[i].table_id)

			local class = hero:className()
			local fighter = xyd.Battle.requireFighter(class).new()

			fighter:populateWithHero(hero)
			fighter:setTeamType(xyd.TeamType.B)
			fighter:setPos(index)

			if teamB[i].status then
				fighter.status = teamB[i].status
			end

			if teamB[i].change_attr then
				fighter.change_attr = teamB[i].change_attr
			end

			fighter:initHp()

			local hp = fighter:getHpLimit()
			totalHp = totalHp + hp
			beforeHp = beforeHp + hp * teamB[i].status.hp / 100
			local info = partner:getInfo()
			info.scale = 0.6
			info.dragScrollView = self.parent_.scrollview_

			self["hero" .. index]:setInfo(info, petIDB)
			self["hero" .. index]:setNoClick(true)
			self["hero" .. index]:SetActive(true)
		end
	end

	for k, v in ipairs(posB) do
		if v == 1 then
			self["hero" .. k + 6]:SetActive(false)
		end
	end

	if params.battle_report.total_harm then
		resHp = beforeHp - params.battle_report.total_harm
	end

	local dieInfo = params.battle_report.die_info or {}

	if isWin == 1 then
		if group == cellGroup then
			self.resultLabel.text = __("ARCTIC_EXPEDITION_TEXT_17")
		else
			self.resultLabel.text = __("ARCTIC_EXPEDITION_TEXT_24")
		end

		for i = 1, #teamB do
			local index = teamB[i].pos + 6

			self["hero" .. index]:setGrey()
		end

		for i = 1, #teamA do
			local index = teamA[i].pos

			if xyd.arrayIndexOf(dieInfo, index) > 0 then
				self["hero" .. index]:setGrey()
			else
				self["hero" .. index]:setOrigin()
			end
		end
	else
		local showNum = math.floor((1 - resHp / totalHp) * 100)
		self.resHp.value = showNum / 100
		self.resHpLabel.text = tostring(showNum) .. "%"

		for i = 1, #teamA do
			local index = teamA[i].pos

			self["hero" .. index]:setGrey()
		end

		for i = 1, #teamB do
			local index = teamB[i].pos + 6

			if xyd.arrayIndexOf(dieInfo, index) > 0 then
				self["hero" .. index]:setGrey()
			else
				self["hero" .. index]:setOrigin()
			end
		end
	end

	local battleReport = params.battle_report

	if battleReport and battleReport.random_seed and battleReport.random_seed > 0 then
		self.isSimple = true

		self.detail:SetActive(true)
	end
end

function ArcticExpeditionRecordItem:onClickVideo()
	xyd.BattleController:arcticExpeditionSingleBattle(self.params_, self.parent_.cellId_, self.self_info)
end

function ArcticExpeditionRecordItem:onClickDetail()
	local die_info = nil
	local battleReport = self.params_.battle_report

	if battleReport and battleReport.random_seed and battleReport.random_seed > 0 then
		local report = xyd.BattleController.get():createReport(battleReport)
		die_info = report.die_info
	end

	die_info = {}

	xyd.WindowManager.get():openWindow("battle_detail_data_window", {
		alpha = 0.7,
		battle_params = self.params_.battle_report,
		real_battle_report = self.params_.battle_report,
		die_info = die_info
	})
end

function ArcticExpeditionRecordItem:setState(state)
	if state == 1 then
		xyd.setUITextureByNameAsync(self.bgImg, "arctic_expedition_record_bg_win")
		xyd.setUISpriteAsync(self.resultIcon, nil, "arctic_win")

		self.matchNum.effectColor = Color.New2(2742695167.0)
	else
		xyd.setUITextureByNameAsync(self.bgImg, "arctic_expedition_record_bg_lose")
		xyd.setUISpriteAsync(self.resultIcon, nil, "arctic_lose")

		self.matchNum.effectColor = Color.New2(1047573503)
	end
end

function ArcticExpeditionRecordWindow2:ctor(name, params)
	ArcticExpeditionRecordWindow2.super.ctor(self, name, params)

	self.cellId_ = params.cell_id
	self.battleData_ = params.battle_info or {}
	self.stepNum_ = 1
	self.recordItemList_ = {}
	self.heroIconList_ = {}
end

function ArcticExpeditionRecordWindow2:initWindow()
	self:getComponent()
	self:regisetr()
	self:initLayout()
end

function ArcticExpeditionRecordWindow2:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.bgImg_ = winTrans:ComponentByName("bg", typeof(UIWidget))
	self.labelTitle_ = winTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.scrollView_ = winTrans:ComponentByName("scrollview", typeof(UIScrollView))
	self.gContainer_ = winTrans:ComponentByName("scrollview/gContainer", typeof(MultiRowWrapContent))
	self.ArcticRecordItemRoot_ = winTrans:NodeByName("scrollview/ArcticRecordItem").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.gContainer_, self.ArcticRecordItemRoot_, ArcticExpeditionRecordItem, self)
	self.groupNone_ = winTrans:NodeByName("groupNone").gameObject
	self.groupNoneTips_ = winTrans:ComponentByName("groupNone/labelNoneTips", typeof(UILabel))
end

function ArcticExpeditionRecordWindow2:regisetr()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end
end

function ArcticExpeditionRecordWindow2:initLayout()
	self.labelTitle_.text = __("ARCTIC_EXPEDITION_TEXT_13")
	self.groupNoneTips_.text = __("ARCTIC_EXPEDITION_TEXT_47")

	self:updateContent()
end

function ArcticExpeditionRecordWindow2:updateContent()
	self.multiWrap_:setInfos(self.battleData_, {})

	if #self.battleData_ <= 0 then
		self.groupNone_:SetActive(true)
	end
end

return ArcticExpeditionRecordWindow2
