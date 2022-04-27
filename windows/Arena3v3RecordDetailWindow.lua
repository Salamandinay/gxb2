local BaseWindow = import(".BaseWindow")
local Arena3v3RecordDetailWindow = class("Arena3v3RecordDetailWindow", BaseWindow)
local Arena3v3RecordDetailItem = class("Arena3v3RecordDetailItem")
local PlayerIcon = import("app.components.PlayerIcon")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local Monster = import("app.models.Monster")

function Arena3v3RecordDetailItem:ctor(go, params)
	self.go = go
	self.info = params.info
	self.recordId = params.recordId
	self.isHideDie = params.isHideDie
	self.matchNumText = params.matchNum
	self.if3v3 = params.if3v3
	self.isAllServer = params.isAllServer
	self.isAsAfter = params.isAsAfter

	self:getUIComponents()
	self:registerEvent()
	self:initLayout()
end

function Arena3v3RecordDetailItem:getUIComponents()
	local trans = self.go.transform
	self.title = trans:NodeByName("title").gameObject
	self.matchNum = self.title:ComponentByName("matchNum", typeof(UILabel))
	self.video = self.title:NodeByName("video").gameObject
	self.detail = self.title:NodeByName("detail").gameObject
	self.main = trans:NodeByName("main").gameObject
	self.bg = self.main:ComponentByName("bg", typeof(UITexture))
	self.resultIcon = self.main:ComponentByName("resultIcon", typeof(UITexture))
	local cnt = 1

	for i = 1, 2 do
		local pIcon = self.main:NodeByName("pIcon" .. i).gameObject
		self["pIcon" .. i] = PlayerIcon.new(pIcon)
		self["pName" .. i] = self.main:ComponentByName("pName" .. i, typeof(UILabel))
		self["serverInfo" .. i] = self.main:NodeByName("serverInfo" .. i).gameObject
		self["serverId" .. i] = self["serverInfo" .. i]:ComponentByName("serverId" .. i, typeof(UILabel))
		local grid1 = self.main:NodeByName("grid" .. i .. "_1").gameObject
		local grid2 = self.main:NodeByName("grid" .. i .. "_2").gameObject

		for j = 1, 2 do
			local root = grid1:NodeByName("hero" .. cnt).gameObject
			self["hero" .. cnt] = HeroIcon.new(root)

			self["hero" .. cnt]:SetActive(false)

			cnt = cnt + 1
		end

		for j = 3, 6 do
			local root = grid2:NodeByName("hero" .. cnt).gameObject
			self["hero" .. cnt] = HeroIcon.new(root)

			self["hero" .. cnt]:SetActive(false)

			cnt = cnt + 1
		end
	end
end

function Arena3v3RecordDetailItem:setState(state)
end

function Arena3v3RecordDetailItem:initLayout()
	local params = self.info
	local isWin = params.is_win
	local res = ""
	local lang = "en_en"

	if xyd.Global.lang == "zh_tw" then
		lang = "zh_tw"
	end

	if isWin == 1 then
		self:setState("win")

		res = "arena_3v3_win_" .. lang

		xyd.setUITextureByNameAsync(self.bg, "arena_3v3_win_bg", true)
	else
		self:setState("lose")

		res = "arena_3v3_lost_" .. lang

		xyd.setUITextureByNameAsync(self.bg, "arena_3v3_lose_bg", true)
	end

	xyd.setUITextureByNameAsync(self.resultIcon, res, true)

	self.matchNum.text = __("MATCH_NUM", self.matchNumText)

	self.pIcon1:setInfo(params.self_info)

	if params.enemy_info.player_id > 10000 then
		self.pIcon2:setInfo(params.enemy_info)

		self.serverId2.text = xyd.getServerNumber(params.enemy_info.server_id)
		self.pName2.text = params.enemy_info.player_name
	else
		self.pIcon2:setInfo({
			lev = xyd.tables.arenaAllServerRobotTable:getLev(params.enemy_info.player_id),
			avatar_id = xyd.tables.arenaAllServerRobotTable:getAvatar(params.enemy_info.player_id)
		})

		self.serverId2.text = xyd.getServerNumber(xyd.tables.arenaAllServerRobotTable:getServerID(params.enemy_info.player_id))
		self.pName2.text = xyd.tables.arenaAllServerRobotTable:getName(params.enemy_info.player_id)
	end

	self.pIcon1:setScale(0.8)
	self.pIcon2:setScale(0.8)

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

	for i = 1, #teamA do
		local index = teamA[i].pos
		local partner = Partner.new()

		partner:populate(teamA[i])

		local info = partner:getInfo()
		info.scale = 0.6

		self["hero" .. index]:setInfo(info, petIDA)
		self["hero" .. index]:SetActive(true)
	end

	for i = 1, #teamB do
		if teamB[i] then
			local index = teamB[i].pos + 6
			local partner = Partner.new()

			if teamB[i].isMonster then
				partner = Monster.new()

				partner:populateWithTableID(teamB[i].table_id)
			else
				partner:populate(teamB[i])
			end

			local info = partner:getInfo()
			info.scale = 0.6

			self["hero" .. index]:setInfo(info, petIDB)
			self["hero" .. index]:SetActive(true)
		end
	end

	self.serverId1.text = xyd.getServerNumber(params.self_info.server_id)
	self.pName1.text = params.self_info.player_name

	if self.isHideDie then
		local dieInfo = params.battle_report.die_info or {}

		if isWin == 1 then
			for i = 1, #teamB do
				local index = teamB[i].pos + 6

				self["hero" .. index]:setGrey()
			end

			for i = 1, #teamA do
				local index = teamA[i].pos

				if xyd.arrayIndexOf(dieInfo, index) > 0 then
					self["hero" .. index]:setGrey()
				end
			end
		else
			for i = 1, #teamA do
				local index = teamA[i].pos

				self["hero" .. index]:setGrey()
			end

			for i = 1, #teamB do
				local index = teamB[i].pos + 6

				if xyd.arrayIndexOf(dieInfo, index) > 0 then
					self["hero" .. index]:setGrey()
				end
			end
		end
	end

	local battleReport = params.battle_report

	if battleReport and battleReport.random_seed and battleReport.random_seed > 0 then
		self.isSimple = true

		self.detail:SetActive(true)

		UIEventListener.Get(self.detail).onClick = handler(self, self.onClickDetail)
	end
end

function Arena3v3RecordDetailItem:registerEvent()
	UIEventListener.Get(self.video).onClick = handler(self, self.onClickVideo)
end

function Arena3v3RecordDetailItem:onClickVideo()
	if self.isSimple and not xyd.checkReportVer(self.info.battle_report) then
		return
	end

	if self.isAllServer or self.isAsAfter then
		xyd.BattleController:onArenaScoreBattle({
			data = self.info,
			record_id = self.recordId
		}, true)
	else
		xyd.BattleController:onArena3v3Battle({
			data = self.info,
			record_id = self.recordId
		}, true)
	end
end

function Arena3v3RecordDetailItem:onClickDetail()
	local die_info = nil
	local battleReport = self.info.battle_report

	if battleReport and battleReport.random_seed and battleReport.random_seed > 0 then
		local report = xyd.BattleController.get():createReport(battleReport)
		die_info = report.die_info
	end

	die_info = {}

	xyd.WindowManager.get():openWindow("battle_detail_data_window", {
		alpha = 0.7,
		battle_params = self.info.battle_report,
		real_battle_report = self.info.battle_report,
		die_info = die_info
	})
end

function Arena3v3RecordDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.model_ = params.model or xyd.models.arena3v3

	if params.model or params.isAsAfter then
		self.if3v3 = false
	else
		self.if3v3 = true
	end

	if params.isAllServer then
		self.isAllServer = true
		self.model_ = xyd.models.arenaAllServerScore
	end

	if params.isAsAfter then
		self.isAsAfter = true
		self.model_ = xyd.models.arenaAllServerNew
	end
end

function Arena3v3RecordDetailWindow:initWindow()
	Arena3v3RecordDetailWindow.super.initWindow(self)
	self:getUIComponents()
	self:registerEvent()

	self.labelTitle.text = __("BATTLE_RECORD")

	dump(self.params_.report_ids)
	self.model_:reqReport(self.params_.report_ids)
end

function Arena3v3RecordDetailWindow:getUIComponents()
	local trans = self.window_.transform
	local groupAction = trans:NodeByName("groupAction")
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	local scrollView = groupAction:NodeByName("scrollView").gameObject
	self.scrollView = groupAction:ComponentByName("scrollView", typeof(UIScrollView))
	self.item = scrollView:NodeByName("arena_3v3_record_item").gameObject
	self.gContainer = scrollView:NodeByName("gContainer").gameObject
end

function Arena3v3RecordDetailWindow:registerEvent()
	self:register()
	self.eventProxy_:addEventListener(xyd.event.ARENA_3v3_GET_REPORT, handler(self, self.onGetReport))
	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_GET_RECORD, handler(self, self.onGetReport))
	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_GET_RECORD_NEW, handler(self, self.onGetAllServerReport))
	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_GET_REPORT, handler(self, self.onGetAllServerReport))
end

function Arena3v3RecordDetailWindow:onGetReport(event)
	local data = event.data
	self.reportsInfo = data.reports

	NGUITools.DestroyChildren(self.gContainer.transform)

	local isHideDie = false

	if not self.if3v3 then
		isHideDie = true
	end

	for i = 1, #self.reportsInfo do
		local tmp = NGUITools.AddChild(self.gContainer, self.item)
		local reportInfo = self.reportsInfo[i]

		Arena3v3RecordDetailItem.new(tmp, {
			info = self.reportsInfo[i],
			isHideDie = isHideDie,
			matchNum = i,
			if3v3 = self.if3v3,
			recordId = self.params_.report_ids[i]
		})
	end

	self.gContainer:GetComponent(typeof(UILayout)):Reposition()
end

function Arena3v3RecordDetailWindow:onGetAllServerReport(event)
	local data = event.data
	self.reportsInfo = data.reports

	NGUITools.DestroyChildren(self.gContainer.transform)

	local isHideDie = false

	if not self.if3v3 then
		isHideDie = true
	end

	for i = 1, #self.reportsInfo do
		local tmp = NGUITools.AddChild(self.gContainer, self.item)
		local reportInfo = self.reportsInfo[i]

		Arena3v3RecordDetailItem.new(tmp, {
			info = self.reportsInfo[i],
			isHideDie = isHideDie,
			matchNum = i,
			isAllServer = self.isAllServer,
			isAsAfter = self.isAsAfter,
			recordId = self.params_.report_ids[i]
		})
	end

	self.gContainer:GetComponent(typeof(UILayout)):Reposition()
end

return Arena3v3RecordDetailWindow
