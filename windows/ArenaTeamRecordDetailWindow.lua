local BaseWindow = import(".BaseWindow")
local ArenaTeamRecordDetailWindow = class("ArenaTeamRecordDetailWindow", BaseWindow)
local ArenaTeamRecordDetailItem = class("ArenaTeamRecordDetailItem", import("app.components.BaseComponent"))
local PlayerIcon = import("app.components.PlayerIcon")
local Partner = import("app.models.Partner")
local HeroIcon = import("app.components.HeroIcon")

function ArenaTeamRecordDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.model_ = xyd.models.arenaTeam
	self.params = params
end

function ArenaTeamRecordDetailWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:registerEvent()
	self.model_:reqReport(self.params.report_ids)

	self.labelTitle.text = __("BATTLE_RECORD")
end

function ArenaTeamRecordDetailWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainGroup = winTrans:NodeByName("mainGroup").gameObject
	self.labelTitle = mainGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.scrollView = mainGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.gContainer = mainGroup:NodeByName("scroller/gContainer").gameObject
	self.closeBtn = mainGroup:NodeByName("closeBtn").gameObject
end

function ArenaTeamRecordDetailWindow:registerEvent()
	ArenaTeamRecordDetailWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ARENA_TEAM_REPORTS, self.onGetReport, self)
end

function ArenaTeamRecordDetailWindow:onGetReport(event)
	local data = event.data
	self.reportsInfo = data.reports

	NGUITools.DestroyChildren(self.gContainer.transform)

	for i = 1, #self.reportsInfo do
		local item = ArenaTeamRecordDetailItem.new(self.gContainer, self)

		item:setInfo(self.reportsInfo[i], i)
	end

	self.gContainer:GetComponent(typeof(UILayout)):Reposition()
end

function ArenaTeamRecordDetailItem:ctor(parentGO, parent)
	ArenaTeamRecordDetailItem.super.ctor(self, parentGO)
	self:setDragScrollView(parent.scrollView)
	self:getUIComponent()
	self:registerEvent()
end

function ArenaTeamRecordDetailItem:getPrefabPath()
	return "Prefabs/Components/arena_3v3_record_item"
end

function ArenaTeamRecordDetailItem:getUIComponent()
	local go = self.go
	local topGroup = go:NodeByName("topGroup").gameObject
	self.matchNum = topGroup:ComponentByName("matchNum", typeof(UILabel))
	self.video = topGroup:NodeByName("video").gameObject
	self.detail = topGroup:NodeByName("detail").gameObject
	local mainGroup = go:NodeByName("mainGroup").gameObject
	self.bg = mainGroup:ComponentByName("bg", typeof(UITexture))
	self.resultIcon = mainGroup:ComponentByName("resultIcon", typeof(UITexture))

	for i = 1, 2 do
		self["pIconGroup" .. tostring(i)] = mainGroup:NodeByName("pIconGroup" .. tostring(i)).gameObject
		self["pIcon" .. tostring(i)] = PlayerIcon.new(self["pIconGroup" .. tostring(i)])
		self["pName" .. tostring(i)] = mainGroup:ComponentByName("pName" .. tostring(i), typeof(UILabel))
		self["serverInfo" .. tostring(i)] = mainGroup:NodeByName("serverInfo" .. tostring(i)).gameObject
		self["serverId" .. tostring(i)] = self["serverInfo" .. tostring(i)]:ComponentByName("serverId" .. tostring(i), typeof(UILabel))

		self["serverInfo" .. tostring(i)]:SetActive(false)
	end

	local heros1 = mainGroup:NodeByName("heros1").gameObject

	for i = 1, 2 do
		local iconGroup = heros1:NodeByName("iconGroup" .. tostring(i)).gameObject
		local heroGroup = iconGroup:NodeByName("heroGroup" .. tostring(i)).gameObject
		self["heroGroup" .. tostring(i)] = heroGroup
		self["hero" .. tostring(i)] = HeroIcon.new(heroGroup)
	end

	local heros2 = mainGroup:NodeByName("heros2").gameObject

	for i = 3, 6 do
		local iconGroup = heros2:NodeByName("iconGroup" .. tostring(i)).gameObject
		local heroGroup = iconGroup:NodeByName("heroGroup" .. tostring(i)).gameObject
		self["heroGroup" .. tostring(i)] = heroGroup
		self["hero" .. tostring(i)] = HeroIcon.new(heroGroup)
	end

	local heros3 = mainGroup:NodeByName("heros3").gameObject

	for i = 9, 12 do
		local iconGroup = heros3:NodeByName("iconGroup" .. tostring(i)).gameObject
		local heroGroup = iconGroup:NodeByName("heroGroup" .. tostring(i)).gameObject
		self["heroGroup" .. tostring(i)] = heroGroup
		self["hero" .. tostring(i)] = HeroIcon.new(heroGroup)
	end

	local heros4 = mainGroup:NodeByName("heros4").gameObject

	for i = 7, 8 do
		local iconGroup = heros4:NodeByName("iconGroup" .. tostring(i)).gameObject
		local heroGroup = iconGroup:NodeByName("heroGroup" .. tostring(i)).gameObject
		self["heroGroup" .. tostring(i)] = heroGroup
		self["hero" .. tostring(i)] = HeroIcon.new(heroGroup)
	end

	self.tipsLabel1_ = mainGroup:ComponentByName("tipsLabel1_", typeof(UILabel))
	self.tipsLabel2_ = mainGroup:ComponentByName("tipsLabel2_", typeof(UILabel))
end

function ArenaTeamRecordDetailItem:setCurrentState(value)
	local lang = "en_en"

	if xyd.Global.lang == "zh_tw" then
		lang = "zh_tw"
	end

	if value == "win" then
		xyd.setUITextureAsync(self.resultIcon, "Textures/arena_web/arena_text/arena_3v3_win_" .. lang, function ()
		end)
		xyd.setUITextureAsync(self.bg, "Textures/arena_web/arena_3v3_win_bg", function ()
		end)
	elseif value == "lose" then
		xyd.setUITextureAsync(self.resultIcon, "Textures/arena_web/arena_text/arena_3v3_lost_" .. lang, function ()
		end)
		xyd.setUITextureAsync(self.bg, "Textures/arena_web/arena_3v3_lose_bg", function ()
		end)
	end

	self.currentState = value
end

function ArenaTeamRecordDetailItem:setInfo(params, matchNum, isAttack)
	self.params = params
	self.is_win = params.is_win

	if self.is_win and self.is_win ~= 0 then
		self:setCurrentState("win")
	else
		self:setCurrentState("lose")
	end

	self.matchNum.text = __("MATCH_NUM" .. tostring(matchNum))
	self.matchNum_ = matchNum

	self.pIcon1:setInfo(params.self_info.players[matchNum])
	self.pIcon2:setInfo(params.enemy_info.players[matchNum])

	if self:checkEnemy() then
		self:setTipsLabel(self.tipsLabel1_, 1)
		self:setTipsLabel(self.tipsLabel2_, 2)
	else
		self:setTipsLabel(self.tipsLabel1_, 2)
		self:setTipsLabel(self.tipsLabel2_, 1)
	end

	local teamA = params.battle_report.teamA
	local teamB = params.battle_report.teamB
	local petA = params.battle_report.petA
	local petB = params.battle_report.petB
	local petIDA, petIDB = nil

	if not petA or not petA.pet_id then
		petIDA = 0
	else
		petIDA = petA.pet_id
	end

	if not petB or not petB.pet_id then
		petIDB = 0
	else
		petIDB = petB.pet_id
	end

	for i = 1, #teamA do
		local index = teamA[i].pos
		local partner = Partner.new()

		partner:populate(teamA[i])
		partner:setEquip({
			0,
			0,
			0,
			0,
			0,
			0,
			teamA[i].skin_id
		})
		self["hero" .. tostring(index)]:setInfo(partner:getInfo(), petIDA)
		self["heroGroup" .. tostring(index)]:SetActive(true)
	end

	for i = 1, #teamB do
		local index = teamB[i].pos + 6
		local partner = Partner.new()

		partner:populate(teamB[i])
		partner:setEquip({
			0,
			0,
			0,
			0,
			0,
			0,
			teamB[i].skin_id
		})
		self["hero" .. tostring(index)]:setInfo(partner:getInfo(), petIDB)
		self["heroGroup" .. tostring(index)]:SetActive(true)
	end

	self.serverId1.text = xyd.getServerNumber(params.self_info.server_id)
	self.serverId2.text = xyd.getServerNumber(params.enemy_info.server_id)
	self.pName1.text = params.self_info.players[matchNum].player_name
	self.pName2.text = params.enemy_info.players[matchNum].player_name
	local battleReport = params.battle_report

	if battleReport and battleReport.random_seed and battleReport.random_seed > 0 then
		self.isSimple = true
	end
end

function ArenaTeamRecordDetailItem:registerEvent()
	xyd.setDarkenBtnBehavior(self.video, self, self.onClickVideo)
	xyd.setDarkenBtnBehavior(self.detail, self, self.onClickDetail)
end

function ArenaTeamRecordDetailItem:onClickVideo()
	if self.isSimple and not xyd.checkReportVer(self.params.battle_report) then
		return
	end

	xyd.BattleController.get():onArenaTeamBattle({
		data = self.params
	}, true, self.matchNum_)
end

function ArenaTeamRecordDetailItem:onClickDetail()
	local die_info = nil
	local battleReport = self.params.battle_report

	if battleReport and battleReport.random_seed and battleReport.random_seed > 0 then
		local report = xyd.BattleController.get():createReport(battleReport)
		die_info = report.die_info
	end

	die_info = {}

	xyd.WindowManager.get():openWindow("battle_detail_data_window", {
		alpha = 0.7,
		battle_params = self.params.battle_report,
		real_battle_report = self.params.battle_report,
		die_info = die_info
	})
end

function ArenaTeamRecordDetailItem:setTipsLabel(label, type)
	label:SetActive(true)

	if type == 1 then
		label.text = "(" .. __("SELF") .. ")"
		label.color = Color.New2(915996927)
	else
		label.text = "(" .. __("ENEMY") .. ")"
		label.color = Color.New2(3422556671.0)
	end
end

function ArenaTeamRecordDetailItem:checkEnemy()
	local self_infos = self.params.self_info.players
	local isAttack = false

	for i = 1, #self_infos do
		if self_infos[i].player_id == xyd.Global.playerID then
			isAttack = true

			break
		end
	end

	return isAttack
end

return ArenaTeamRecordDetailWindow
