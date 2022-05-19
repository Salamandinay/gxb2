local BaseWindow = import(".BaseWindow")
local BattleTestWindow = class("BattleTestWindow", BaseWindow)
local ReportHero = import("lib.battle.ReportHero")
local ReportPet = import("lib.battle.ReportPet")
local BattleCreateReport = import("lib.battle.BattleCreateReport")
local battleReportDes = import("lib.battle.BattleReportDes")
local cjson = require("cjson")
local BattleTest = import("app.common.BattleTest")

function BattleTestWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.jsonArr = {}
	self.battle_ids = {}
	self.team_ids = {}
	self.times = 0

	if params then
		self.battle_ids = params.battle_ids
		self.team_ids = params.team_ids
		self.times = params.times
	end
end

function BattleTestWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function BattleTestWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	local battleIdGroup = content:NodeByName("battleIdGroup").gameObject
	local teamIdGroup = content:NodeByName("teamIdGroup").gameObject
	local timesGroup = content:NodeByName("timesGroup").gameObject
	local godGroup = content:NodeByName("godGroup").gameObject
	self.closeBtn = content:NodeByName("closeBtn").gameObject
	self.battleIdInput = battleIdGroup:ComponentByName("input", typeof(UIInput))
	self.teamIdInput = teamIdGroup:ComponentByName("input", typeof(UIInput))
	self.timesInput = timesGroup:ComponentByName("input", typeof(UIInput))
	self.godInput = godGroup:ComponentByName("input", typeof(UIInput))
	self.msgNode = trans:NodeByName("msgNode").gameObject
	self.msgText = self.msgNode:ComponentByName("msgText", typeof(UILabel))
	self.select99Btn = content:ComponentByName("select99Btn", typeof(UIToggle))
	self.localBtn = content:ComponentByName("localBtn", typeof(UIToggle))
	self.teamABtn = content:NodeByName("teamABtn").gameObject
	self.teamBBtn = content:NodeByName("teamBBtn").gameObject
	self.fightSelfBtn = content:NodeByName("fightSelfBtn").gameObject
	self.sureBtn = content:NodeByName("sureBtn").gameObject
	self.jsonBtn = content:NodeByName("jsonBtn").gameObject
	self.realJsonBtn = content:NodeByName("realJsonBtn").gameObject
	self.testBtn = content:NodeByName("testBtn").gameObject
	self.jsonListBtn = content:NodeByName("jsonListBtn").gameObject
end

function BattleTestWindow:layout()
	self.battleIdInput.value = ""
	self.battleIdInput.defaultText = "battle_id / teamB_id"
	self.teamIdInput.value = ""
	self.teamIdInput.defaultText = "team id (attacker)"
	self.timesInput.value = ""
	self.timesInput.defaultText = "times"
	self.godInput.value = ""
	self.godInput.defaultText = "god skills"

	if xyd.db.misc:getValue("test_table_fight", -1) then
		local values = xyd.split(xyd.db.misc:getValue("test_table_fight", -1), ";")

		if #values == 3 then
			self.battleIdInput.value = values[1]
			self.teamIdInput.value = values[2]
			self.timesInput.value = values[3]
		end
	end

	if xyd.db.misc:getValue("god_skills", -1) then
		local godStr = xyd.db.misc:getValue("god_skills", -1) or ""
		self.godInput.value = godStr
	end

	if tonumber(xyd.db.misc:getValue("test_battle_round", -1)) == 15 then
		self.select99Btn.startsActive = false
	end

	self.localBtn.startsActive = false

	if xyd.db.misc:getValue("test_index", -1) == "1" then
		self.localBtn.startsActive = true
	end

	self.msgNode:SetActive(false)
end

function BattleTestWindow:setSelfFightTeam(isTeamA)
	local battleType = xyd.BattleType.TEST_B

	if isTeamA then
		battleType = xyd.BattleType.TEST_A
	end

	local fightParams = {
		showSkip = false,
		battleType = battleType,
		callback = function ()
			xyd.WindowManager.get():openWindow("battle_test_window")
		end
	}

	xyd.WindowManager.get():closeWindow(self.name_)
	xyd.WindowManager.get():openWindow("battle_formation_window", fightParams)
end

function BattleTestWindow:register()
	BattleTestWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GM_COMMOND, handler(self, self.onGmResponse))

	UIEventListener.Get(self.sureBtn).onClick = function ()
		self:startBattle()
	end

	UIEventListener.Get(self.testBtn).onClick = function ()
		local params = {
			inputA = self.teamIdInput.value,
			inputB = self.battleIdInput.value,
			times = self.timesInput.value,
			gmStr = self:getJsonReport()
		}

		BattleTest.get():setParams(params)
		xyd.db.misc:setValue({
			key = "test_table_fight",
			playerId = -1,
			value = self.battleIdInput.value .. ";" .. self.teamIdInput.value .. ";" .. self.timesInput.value
		})
	end

	UIEventListener.Get(self.jsonListBtn).onClick = function ()
		xyd.openWindow("battle_test_json_window")
	end

	UIEventListener.Get(self.teamABtn).onClick = function ()
		self:setSelfFightTeam(true)
	end

	UIEventListener.Get(self.teamBBtn).onClick = function ()
		self:setSelfFightTeam(false)
	end

	UIEventListener.Get(self.jsonBtn).onClick = function ()
		self:createJsonBattle()
	end

	UIEventListener.Get(self.realJsonBtn).onClick = function ()
		self:createJsonBattle(true)
	end

	UIEventListener.Get(self.fightSelfBtn).onClick = function ()
		self:selfFight()
	end

	XYDUtils.AddEventDelegate(self.select99Btn.onChange, function ()
		local round = 15

		if self.select99Btn.value == true then
			round = 99
		end

		xyd.db.misc:setValue({
			key = "test_battle_round",
			playerId = -1,
			value = round
		})
	end)
	XYDUtils.AddEventDelegate(self.localBtn.onChange, function ()
		local value = "0"

		if self.localBtn.value == true then
			value = "1"
		end

		xyd.db.misc:setValue({
			key = "test_index",
			playerId = -1,
			value = value
		})
	end)
end

function BattleTestWindow:getReportHeroByPartnerId(partnerId, pos)
	local partner = xyd.models.slot:getPartner(partnerId)
	local info = partner:getInfo()
	local hero = ReportHero.new()
	info.table_id = partner.tableID
	info.level = partner.lev
	info.show_skin = partner:isShowSkin()
	info.equips = partner.equipments
	info.love_point = partner.lovePoint
	info.is_vowed = partner.isVowed
	info.pos = pos
	info.potentials = {}

	for i = 1, #partner:getPotential() do
		info.potentials[i] = partner:getPotential()[i]
	end

	hero:populate(info)

	return hero
end

function BattleTestWindow:getReportPetById(id)
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

function BattleTestWindow:selfFight()
	local dbValA = xyd.db.formation:getValue(xyd.BattleType.TEST_A)

	if not dbValA then
		reportLog2("no set teamA")

		return
	end

	local dbValB = xyd.db.formation:getValue(xyd.BattleType.TEST_B)

	if not dbValB then
		reportLog2("no set teamB")

		return
	end

	local dataA = cjson.decode(dbValA)
	local dataB = cjson.decode(dbValB)
	local herosA = {}
	local herosB = {}

	for k, v in ipairs(dataA.partners) do
		local partnerId = tonumber(v)

		if partnerId and partnerId ~= 0 then
			local hero = self:getReportHeroByPartnerId(partnerId, k)

			table.insert(herosA, hero)
		end
	end

	for k, v in ipairs(dataB.partners) do
		local partnerId = tonumber(v)

		if partnerId and partnerId ~= 0 then
			local hero = self:getReportHeroByPartnerId(partnerId, k)

			table.insert(herosB, hero)
		end
	end

	local petA = self:getReportPetById(dataA.pet_id)
	local petB = self:getReportPetById(dataB.pet_id)
	local params = {
		battleID = 1,
		battle_type = xyd.BattleType.TEST,
		herosA = herosA,
		herosB = herosB,
		petA = petA,
		petB = petB,
		guildSkillsA = xyd.models.guild:getGuildSkills(),
		guildSkillsB = xyd.models.guild:getGuildSkills(),
		god_skills = {},
		random_seed = math.random(1, 10000),
		maxRound = tonumber(xyd.db.misc:getValue("test_battle_round", -1)) or 99
	}

	if self.godInput.value ~= "" then
		params.god_skills = xyd.splitToNumber(self.godInput.value, ";")
	end

	local reporter = BattleCreateReport.new(params)

	reporter:run()

	local params2 = {
		event_data = {},
		battle_type = xyd.BattleType.TEST
	}
	params2.event_data.battle_report = reporter:getReport()

	xyd.BattleController.get():startBattle(params2)
	xyd.db.misc:setValue({
		key = "god_skills",
		playerId = -1,
		value = self.godInput.value
	})
	self:close()
end

function BattleTestWindow:onGmResponse(event)
	local data = event.data

	if tostring(data.battle_result) ~= "" and data.battle_result.stage_id and data.battle_result.stage_id == 1 then
		if xyd.db.misc:getValue("test_index", -1) ~= "1" then
			data = xyd.decodeProtoBuf(data)

			self:jsonFight(data.battle_result.battle_report)
		end

		battleReportDes:randomRecord(nil, tostring(data.battle_result.battle_report.random_log))
		self:close()
	end
end

function BattleTestWindow:jsonFight(report)
	local params2 = {
		event_data = {},
		battle_type = xyd.BattleType.TEST
	}
	params2.event_data.battle_report = report

	xyd.BattleController.get():startBattle(params2)
end

function BattleTestWindow:getJsonReport()
	local path = "Assets/report_.json"
	local jsonData = io.readfile(path)
	local rp = cjson.decode(jsonData).battle_report
	rp.frames = {}
	rp.battle_type = xyd.BattleType.TEST
	rp.maxRound = tonumber(xyd.db.misc:getValue("test_battle_round", -1)) or 99
	rp.random_log = nil

	return cjson.encode(rp)
end

function BattleTestWindow:createJsonBattle(isReal, noBattle)
	local path = "Assets/report_.json"
	local jsonData = io.readfile(path)
	self.jsonArr = cjson.decode(jsonData)
	local reportData = self.jsonArr.battle_report

	if not reportData then
		reportLog2("no battle_report")
	end

	local herosA = {}

	for i = 1, #reportData.teamA do
		local hero = ReportHero.new()

		if reportData.teamA[i].isMonster then
			hero:populateWithTableID(reportData.teamA[i].table_id, reportData.teamA[i])
		else
			hero:populate(reportData.teamA[i])
		end

		table.insert(herosA, hero)
	end

	local herosB = {}

	for i = 1, #reportData.teamB do
		local hero = ReportHero.new()

		if reportData.teamB[i].isMonster then
			hero:populateWithTableID(reportData.teamB[i].table_id, reportData.teamB[i])
		else
			hero:populate(reportData.teamB[i])
		end

		table.insert(herosB, hero)
	end

	local petA, petB = nil

	if reportData.petA then
		local pet = ReportPet.new()

		pet:populate(reportData.petA)

		petA = pet
	end

	if reportData.petB then
		local pet = ReportPet.new()

		pet:populate(reportData.petB)

		petB = pet
	end

	reportData.battleID = 1
	reportData.herosA = herosA
	reportData.herosB = herosB
	reportData.petA = petA
	reportData.petB = petB
	reportData.battle_type = xyd.BattleType.TEST
	reportData.has_random = 1
	reportData.maxRound = tonumber(xyd.db.misc:getValue("test_battle_round", -1)) or 99
	local rp = cjson.decode(jsonData).battle_report

	if isReal then
		rp = cjson.decode(jsonData).battle_report.tmp_report
	else
		rp.frames = {}
	end

	rp.battle_type = xyd.BattleType.TEST
	rp.maxRound = tonumber(xyd.db.misc:getValue("test_battle_round", -1)) or 99
	rp.random_log = nil
	local gmStr = cjson.encode(rp)

	if isReal then
		reportLog2("test_local")
		self:jsonFight(rp)

		return
	end

	if not noBattle then
		xyd.models.gMcommand:request("json_fight " .. gmStr)
	end

	if not reportData.random_seed then
		reportData.random_seed = reportData.random_seed_2
	end

	local reporter = BattleCreateReport.new(reportData)

	reporter:run()

	if noBattle then
		return
	end

	battleReportDes:randomRecord(reporter:getReport().random_log)

	if xyd.db.misc:getValue("test_index", -1) == "1" then
		reportLog2("test_local")
		self:jsonFight(reporter:getReport())
	end
end

function BattleTestWindow:startBattle()
	local result = "\n"
	local battle_ids = xyd.split(self.battleIdInput.value, "|", true)
	local team_ids = xyd.split(self.teamIdInput.value, "|", true)
	local times = self.timesInput.value
	self.times = times

	if times == "0" then
		times = 1
	end

	for k1, team_id in pairs(team_ids) do
		for k2, battle_id in pairs(battle_ids) do
			local winTimes = 0

			for i = 1, times do
				local report = self:createTestReport(battle_id, team_id)
				winTimes = winTimes + report.is_win
			end

			local str = winTimes .. "\n"
			result = result .. team_id .. "    " .. battle_id .. "    " .. str
		end
	end

	reportLog2(result)
	xyd.db.misc:setValue({
		key = "test_table_fight",
		playerId = -1,
		value = self.battleIdInput.value .. ";" .. self.teamIdInput.value .. ";" .. self.timesInput.value
	})

	self.msgText.text = result

	self.msgNode:SetActive(true)
end

function BattleTestWindow:getTeamInfoById(testTeamID)
	local herosA = {}
	local testPartnerIDs = xyd.tables.fightTestTeamTable:getPartnerIDs(testTeamID)
	local stands = xyd.tables.fightTestTeamTable:getStands(testTeamID)

	for i = 1, #testPartnerIDs do
		local hero = ReportHero.new()
		local info = xyd.tables.fightTestPartnerTable:getInfo(testPartnerIDs[i])

		hero:populate({
			show_skin = false,
			table_id = info.table_id,
			grade = info.grade,
			level = info.level,
			awake = info.awake,
			equips = info.equips,
			love_point = info.love_point,
			is_vowed = info.is_vowed,
			pos = stands[i],
			potentials = info.potentials,
			skin_id = info.skin_id,
			ex_skills = info.ex_skills,
			star_origin = info.star_origin,
			travel = info.travel,
			skill_index = info.skill_index
		})
		table.insert(herosA, hero)
	end

	local petA = xyd.tables.fightTestTeamTable:getPetInfo(testTeamID)
	local realPetA = nil

	if petA then
		local pet = ReportPet.new()

		pet:populate(petA)

		realPetA = pet
	end

	local godSkill = xyd.tables.fightTestTeamTable:getGodSkill(testTeamID)
	local result = {
		godSkill = godSkill,
		pet = realPetA,
		heros = herosA
	}

	return result
end

function BattleTestWindow:createTestReport(battleID, testTeamID)
	local herosB = {}
	local petB = nil

	if battleID < 1000 then
		local infoB = self:getTeamInfoById(battleID)
		herosB = infoB.heros
		petB = infoB.pet
		battleID = 1
	else
		local str = xyd.tables.battleTable:getMonsters(battleID)

		if not str or #str <= 0 then
			return
		end

		local poss = xyd.tables.battleTable:getStands(battleID)

		for i = 1, #str do
			local hero = ReportHero.new()

			hero:populateWithTableID(str[i], {
				pos = poss[i]
			})
			table.insert(herosB, hero)
		end
	end

	local herosA = {}
	local petA = nil
	local godSkill = {}

	xyd.db.misc:setValue({
		key = "god_skills",
		playerId = -1,
		value = self.godInput.value
	})

	if testTeamID == -1 then
		local dbValA = xyd.db.formation:getValue(xyd.BattleType.TEST_A)

		if not dbValA then
			reportLog2("no set teamA")

			return
		end

		local dataA = cjson.decode(dbValA)

		for k, v in ipairs(dataA.partners) do
			local partnerId = tonumber(v)

			if partnerId and partnerId ~= 0 then
				local hero = self:getReportHeroByPartnerId(partnerId, k)

				table.insert(herosA, hero)
			end
		end

		local petA = self:getReportPetById(dataA.pet_id)
	elseif testTeamID < 1000 then
		local infoA = self:getTeamInfoById(testTeamID)
		herosA = infoA.heros
		petA = infoA.pet
		godSkill = infoA.godSkill
	else
		local str = xyd.tables.battleTable:getMonsters(testTeamID)

		if not str or #str <= 0 then
			return
		end

		local poss = xyd.tables.battleTable:getStands(testTeamID)

		for i = 1, #str do
			local hero = ReportHero.new()

			hero:populateWithTableID(str[i], {
				pos = poss[i]
			})
			table.insert(herosA, hero)
		end
	end

	local params = {
		battle_type = xyd.BattleType.TEST,
		herosA = herosA,
		herosB = herosB,
		petA = petA,
		petB = petB,
		guildSkillsA = {},
		guildSkillsB = {},
		battleID = battleID,
		god_skills = godSkill,
		random_seed = math.random(1, 10000),
		maxRound = tonumber(xyd.db.misc:getValue("test_battle_round", -1)) or 99
	}

	if self.godInput.value ~= "" then
		local addGodSkills = xyd.splitToNumber(self.godInput.value, ";")

		for k, v in ipairs(addGodSkills) do
			table.insert(params.god_skills, v)
		end
	end

	local reporter = BattleCreateReport.new(params)

	reporter:run()

	local params2 = {
		event_data = {},
		battle_type = xyd.BattleType.TEST
	}
	params2.event_data.battle_report = reporter:getReport()

	if self.times == "0" then
		xyd.BattleController.get():startBattle(params2)
		self:close()
	end

	return {
		is_win = reporter.isWin_
	}
end

return BattleTestWindow
